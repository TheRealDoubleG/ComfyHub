ComfyHub = ComfyHub or {}
local CH = ComfyHub

local RED_REASONS = {
    INCOMPATIBLE = true,
    DEP_MISSING = true,
    DEP_CORRUPT = true,
    CORRUPT = true,
    WRONG_GAME_TYPE = true,
    MISSING = true,
}

local function TryCall(func, ...)
    if type(func) ~= "function" then return nil end
    local ok, a, b, c, d, e, f, g, h = pcall(func, ...)
    if not ok then return nil end
    return a, b, c, d, e, f, g, h
end

function CH:GetNumAddOnsCompat()
    if C_AddOns and type(C_AddOns.GetNumAddOns) == "function" then
        return tonumber(TryCall(C_AddOns.GetNumAddOns)) or 0
    end
    if type(GetNumAddOns) == "function" then
        return tonumber(TryCall(GetNumAddOns)) or 0
    end
    return 0
end

function CH:GetAddOnInfoCompat(indexOrName)
    local a, b, c, d, e, f, g

    if C_AddOns and type(C_AddOns.GetAddOnInfo) == "function" then
        a, b, c, d, e, f, g = TryCall(C_AddOns.GetAddOnInfo, indexOrName)
    elseif type(GetAddOnInfo) == "function" then
        a, b, c, d, e, f, g = TryCall(GetAddOnInfo, indexOrName)
    end

    if type(a) == "table" then
        local info = a
        return {
            name = info.name or info.addonName or tostring(indexOrName),
            title = info.title or info.name or tostring(indexOrName),
            notes = info.notes,
            loadable = info.loadable,
            reason = info.reason,
            security = info.security,
            updateAvailable = info.updateAvailable,
        }
    end

    if a == nil then return nil end

    return {
        name = a,
        title = b or a,
        notes = c,
        loadable = d,
        reason = e,
        security = f,
        updateAvailable = g,
    }
end

function CH:GetAddOnMetadataCompat(name, field)
    if C_AddOns and type(C_AddOns.GetAddOnMetadata) == "function" then
        return TryCall(C_AddOns.GetAddOnMetadata, name, field)
    end
    if type(GetAddOnMetadata) == "function" then
        return TryCall(GetAddOnMetadata, name, field)
    end
    return nil
end

function CH:IsAddOnLoadedCompat(name)
    if C_AddOns and type(C_AddOns.IsAddOnLoaded) == "function" then
        local value = TryCall(C_AddOns.IsAddOnLoaded, name)
        return value and true or false
    end
    if type(IsAddOnLoaded) == "function" then
        local value = TryCall(IsAddOnLoaded, name)
        return value and true or false
    end
    return false
end

function CH:GetAddOnEnableStateCompat(name)
    local character = UnitName and UnitName("player") or nil
    local state

    if C_AddOns and type(C_AddOns.GetAddOnEnableState) == "function" then
        state = TryCall(C_AddOns.GetAddOnEnableState, name, character)
        if state == nil then state = TryCall(C_AddOns.GetAddOnEnableState, name) end
    elseif type(GetAddOnEnableState) == "function" then
        state = TryCall(GetAddOnEnableState, character, name)
        if state == nil then state = TryCall(GetAddOnEnableState, name) end
    end

    state = tonumber(state)
    if state == nil then
        return self:IsAddOnLoadedCompat(name)
    end
    return state > 0
end

function CH:SetAddOnEnabledCompat(name, enabled)
    if not name then return false end
    local character = UnitName and UnitName("player") or nil
    local func

    if enabled then
        func = C_AddOns and C_AddOns.EnableAddOn or EnableAddOn
    else
        func = C_AddOns and C_AddOns.DisableAddOn or DisableAddOn
    end

    if type(func) ~= "function" then return false end

    local ok = pcall(func, name, character)
    if not ok then
        ok = pcall(func, name)
    end

    if ok then
        self:MarkAddonPending(name)
        self:Print(self:T("ADDON_CHANGE_QUEUED"))
        return true
    end

    return false
end

function CH:GetInterfaceMetadata(name)
    local raw = self:GetAddOnMetadataCompat(name, "Interface")
    if raw == nil then return nil end
    local first = tostring(raw):match("(%d+)")
    return tonumber(first)
end

function CH:GetAddOnVersion(name)
    local version = self:GetAddOnMetadataCompat(name, "Version")
    if version == nil or tostring(version) == "" then return "-" end
    return tostring(version)
end

function CH:GetAddOnIcon(name)
    local icon = self:GetAddOnMetadataCompat(name, "IconTexture")
    if icon == nil or tostring(icon) == "" then
        return "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    local numeric = tonumber(icon)
    return numeric or tostring(icon)
end

function CH:GetAddonCompatibility(info)
    if not info then
        return "unknown", self:T("STATUS_UNKNOWN")
    end

    local reason = tostring(info.reason or "")
    local interface = self:GetInterfaceMetadata(info.name)
    local _, _, _, currentInterface = self:GetClientBuildInfo()

    if RED_REASONS[reason] then
        return "red", self:T("STATUS_INCOMPATIBLE")
    end

    if reason == "INTERFACE_VERSION" then
        return "yellow", self:T("STATUS_OUTDATED")
    end

    if interface and currentInterface and interface ~= currentInterface then
        return "yellow", self:T("STATUS_OUTDATED")
    end

    if info.loadable == false and reason ~= "" and reason ~= "DISABLED" then
        return "red", self:T("STATUS_INCOMPATIBLE")
    end

    return "green", self:T("STATUS_OK")
end

function CH:GetAddOnMemoryKB(indexOrName)
    if type(GetAddOnMemoryUsage) ~= "function" then return 0 end
    local value = TryCall(GetAddOnMemoryUsage, indexOrName)
    return tonumber(value) or 0
end

function CH:IsSuiteAddonName(name)
    if name == self.name then return true end
    for _, entry in ipairs(self.family or {}) do
        if entry.name == name then return true end
    end
    return false
end

function CH:GetAddonListFilter()
    local value = self.db and self.db.addons and self.db.addons.filter or "all"
    local allowed = {all=true, enabled=true, disabled=true, loaded=true, problems=true}
    return allowed[value] and value or "all"
end

function CH:SetAddonListFilter(value)
    if not self.db then return end
    self.db.addons = self.db.addons or {}
    self.db.addons.filter = value or "all"
    if self.RefreshAddonRows then self:RefreshAddonRows(true) end
end

function CH:GetAddonListSort()
    local value = self.db and self.db.addons and self.db.addons.sort or "suite"
    local allowed = {suite=true, name=true, memory=true, status=true}
    return allowed[value] and value or "suite"
end

function CH:SetAddonListSort(value)
    if not self.db then return end
    self.db.addons = self.db.addons or {}
    self.db.addons.sort = value or "suite"
    if self.RefreshAddonRows then self:RefreshAddonRows(true) end
end

function CH:GetVisibleAddonList()
    local source = self.addonList or {}
    local filter = self:GetAddonListFilter()
    local needle = tostring(self.addonSearchText or ""):lower():match("^%s*(.-)%s*$")
    local list = {}

    for _, addon in ipairs(source) do
        local matchesFilter = filter == "all"
            or (filter == "enabled" and addon.enabled)
            or (filter == "disabled" and not addon.enabled)
            or (filter == "loaded" and addon.loaded)
            or (filter == "problems" and (addon.statusKey == "red" or addon.statusKey == "yellow"))

        local haystack = table.concat({
            tostring(addon.title or ""),
            tostring(addon.name or ""),
            tostring(addon.version or ""),
            tostring(addon.description or ""),
        }, " "):lower()

        if matchesFilter and (needle == "" or haystack:find(needle, 1, true)) then
            list[#list + 1] = addon
        end
    end

    local sortMode = self:GetAddonListSort()
    table.sort(list, function(a, b)
        if sortMode == "memory" then
            local am = tonumber(a.memoryKB) or 0
            local bm = tonumber(b.memoryKB) or 0
            if am ~= bm then return am > bm end
        elseif sortMode == "status" then
            local rank = {red = 1, yellow = 2, unknown = 3, green = 4}
            local ar = rank[a.statusKey] or 9
            local br = rank[b.statusKey] or 9
            if ar ~= br then return ar < br end
        elseif sortMode == "suite" then
            local as = self:IsSuiteAddonName(a.name) and 0 or 1
            local bs = self:IsSuiteAddonName(b.name) and 0 or 1
            if as ~= bs then return as < bs end
        end
        return tostring(a.title):lower() < tostring(b.title):lower()
    end)

    return list
end

function CH:BuildAddonList()
    local list = {}
    local count = self:GetNumAddOnsCompat()

    for index = 1, count do
        local info = self:GetAddOnInfoCompat(index)
        if info and info.name then
            local colorKey, statusText = self:GetAddonCompatibility(info)
            table.insert(list, {
                index = index,
                name = info.name,
                title = info.title or info.name,
                version = self:GetAddOnVersion(info.name),
                icon = self:GetAddOnIcon(info.name),
                enabled = self:GetAddOnEnableStateCompat(info.name),
                loaded = self:IsAddOnLoadedCompat(info.name),
                statusKey = colorKey,
                statusText = statusText,
                reason = info.reason,
                description = info.notes,
                memoryKB = self:GetAddOnMemoryKB(index),
            })
        end
    end

    table.sort(list, function(a, b)
        return tostring(a.title):lower() < tostring(b.title):lower()
    end)

    self.addonList = list
    return list
end

function CH:IsAddonInstalled(name)
    local info = self:GetAddOnInfoCompat(name)
    return info ~= nil and info.name ~= nil
end

function CH:InitializeAddonManager()
    self:BuildAddonList()
end
