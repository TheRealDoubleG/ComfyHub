ComfyHub = ComfyHub or {}
local CH = ComfyHub

local controls = {}
local currentPage = 1
local previewPage = 1
local ROWS_PER_PAGE = 15
local PREVIEW_ROWS_PER_PAGE = 15

local STATUS_COLORS = {
    green = {0.20, 1.00, 0.20},
    yellow = {1.00, 0.82, 0.00},
    red = {1.00, 0.25, 0.20},
    unknown = {0.65, 0.65, 0.65},
}

local function SetLabel(check, text)
    local label = check.Text or check.text
    if not label then
        label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 3, 1)
        check.Text = label
    end
    label:SetText(text)
end

local function CreateButton(parent, text, x, y, width, func)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 140, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", func)
    return button
end

local function CreateCheck(parent, text, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    SetLabel(cb, text)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        CH:RefreshOptions()
    end)
    cb._getter = getter
    table.insert(controls, cb)
    return cb
end

local function DropdownSetText(dropdown, text)
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(dropdown, text or "") end
end

local function CreateDropdown(parent, x, y, width, getItems, getCurrent, onSelect)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(dd, width or 180) end

    UIDropDownMenu_Initialize(dd, function(_, level)
        local current = getCurrent()
        for _, entry in ipairs(getItems() or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = entry.text
            info.value = entry.value
            info.checked = entry.value == current
            info.func = function()
                onSelect(entry.value)
                CloseDropDownMenus()
                if dd._refresh then dd._refresh() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    dd._refresh = function()
        local current = getCurrent()
        local label = tostring(current or "")
        for _, entry in ipairs(getItems() or {}) do
            if entry.value == current then
                label = entry.text
                break
            end
        end
        DropdownSetText(dd, label)
    end

    dd._refresh()
    return dd
end

local function FormatMemory(kb)
    kb = tonumber(kb) or 0
    if kb >= 1024 then
        return string.format("%.1f MB", kb / 1024)
    end
    return string.format("%d KB", math.floor(kb + 0.5))
end

local function FormatCPU(value)
    value = tonumber(value)
    if value == nil then return "—" end
    if value > 0 and value < 0.01 then return "<0.01 ms" end
    return string.format("%.2f ms", value)
end

local function SelectTab(index)
    local frame = CH.optionsFrame
    if not frame then return end
    for i, tab in ipairs(frame.tabs) do
        tab:SetEnabled(true)
        tab:SetButtonState(i == index and "PUSHED" or "NORMAL", i == index)
        if tab:GetFontString() then
            if i == index then
                tab:GetFontString():SetTextColor(1.00, 0.82, 0.00)
            else
                tab:GetFontString():SetTextColor(1.00, 0.82, 0.00)
            end
        end
        frame.pages[i]:SetShown(i == index)
    end
end

function CH:SelectOptionsTab(index)
    SelectTab(index)
end

function CH:IsAddonManagerPreviewEnabled()
    return self.db
        and self.db.ui
        and self.db.ui.addonManagerPreviewStyle
        and true
        or false
end

function CH:GetAddonPreviewStats()
    local enabled = 0
    local problems = 0
    local cpuTotal = 0
    local cpuValues = 0

    for _, addon in ipairs(self.addonList or {}) do
        if addon.enabled then enabled = enabled + 1 end
        if addon.statusKey == "red" or addon.statusKey == "yellow" then
            problems = problems + 1
        end

        local cpu = tonumber(self:GetCPUPercent(addon.name))
        if cpu then
            cpuTotal = cpuTotal + cpu
            cpuValues = cpuValues + 1
        end
    end

    return {
        enabled = enabled,
        problems = problems,
        cpu = cpuValues > 0 and cpuTotal or nil,
        memory = self.totalMemoryKB or 0,
    }
end

function CH:RefreshAddonPreviewRows(resetPage)
    if not self.addonPreviewRows then return end
    if resetPage then previewPage = 1 end

    local list = self:GetVisibleAddonList()
    local pages = math.max(1, math.ceil(#list / PREVIEW_ROWS_PER_PAGE))
    if previewPage > pages then previewPage = pages end
    if previewPage < 1 then previewPage = 1 end

    for rowIndex, row in ipairs(self.addonPreviewRows) do
        local dataIndex = (previewPage - 1) * PREVIEW_ROWS_PER_PAGE + rowIndex
        local addon = list[dataIndex]
        row._addon = addon

        if addon then
            row:Show()
            row.check:SetChecked(addon.enabled and true or false)
            row.icon:SetTexture(addon.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.icon:SetDesaturated(not addon.enabled)
            row.name:SetText(addon.title or addon.name)
            row.name:SetTextColor(addon.enabled and 1.00 or 0.52, addon.enabled and 0.82 or 0.52, addon.enabled and 0.00 or 0.52)

            local color = STATUS_COLORS[addon.statusKey] or STATUS_COLORS.unknown
            row.status:SetText(tostring(addon.statusText or ""))
            row.status:SetTextColor(color[1], color[2], color[3])

            if addon.enabled then
                row.metric:SetText(FormatCPU(self:GetCPUPercent(addon.name)))
            else
                row.metric:SetText(self:T("INACTIVE"))
            end
        else
            row:Hide()
        end
    end

    local stats = self:GetAddonPreviewStats()
    if self.previewCpuValue then self.previewCpuValue:SetText(FormatCPU(stats.cpu)) end
    if self.previewMemoryValue then self.previewMemoryValue:SetText(FormatMemory(stats.memory)) end
    if self.previewEnabledValue then self.previewEnabledValue:SetText(tostring(stats.enabled)) end
    if self.previewProblemsValue then self.previewProblemsValue:SetText(tostring(stats.problems)) end

    if self.previewResultText then
        self.previewResultText:SetText(string.format(self:T("ADDON_RESULTS"), #list, #(self.addonList or {})))
    end
    if self.previewPageText then
        self.previewPageText:SetText(string.format("%s %d / %d", self:T("PAGE"), previewPage, pages))
    end
    if self.previewPendingText then
        self.previewPendingText:SetText(self:GetPendingText())
    end

    if self.previewSearchBox and not self.previewSearchBox:HasFocus() then
        local wanted = tostring(self.addonSearchText or "")
        if self.previewSearchBox:GetText() ~= wanted then self.previewSearchBox:SetText(wanted) end
    end
    if self.previewFilterDropdown and self.previewFilterDropdown._refresh then self.previewFilterDropdown._refresh() end
    if self.previewSortDropdown and self.previewSortDropdown._refresh then self.previewSortDropdown._refresh() end
end

function CH:ApplyAddonManagerViewMode()
    if not self.addonPreviewFrame or not self.addonPage then return end
    local preview = self:IsAddonManagerPreviewEnabled()

    -- The preview is an alternate layout, not an overlay. Hide every standard
    -- Addons-page child/region while it is active so the old view cannot bleed
    -- through behind transparent controls.
    for _, child in ipairs({self.addonPage:GetChildren()}) do
        if child ~= self.addonPreviewFrame then
            child:SetShown(not preview)
        end
    end
    for _, region in ipairs({self.addonPage:GetRegions()}) do
        region:SetShown(not preview)
    end

    self.addonPreviewFrame:SetShown(preview)
    if preview then self:RefreshAddonPreviewRows(false) end
end

function CH:GetPendingText()
    local count = self:GetPendingCount()
    if count == 0 then return self:T("PENDING_NONE") end
    if count == 1 then return self:T("PENDING_ONE") end
    return string.format(self:T("PENDING_MANY"), count)
end

function CH:RefreshAddonRows(resetPage)
    if not self.addonRows then return end
    if resetPage then currentPage = 1 end

    local list = self:GetVisibleAddonList()
    self.visibleAddonList = list
    local pages = math.max(1, math.ceil(#list / ROWS_PER_PAGE))
    if currentPage > pages then currentPage = pages end
    if currentPage < 1 then currentPage = 1 end

    for rowIndex, row in ipairs(self.addonRows) do
        local dataIndex = (currentPage - 1) * ROWS_PER_PAGE + rowIndex
        local addon = list[dataIndex]

        row._addon = addon

        if addon then
            row:Show()
            row.check:SetChecked(addon.enabled and true or false)
            row.icon:SetTexture(addon.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.icon:SetDesaturated(not addon.enabled)
            row.name:SetText(addon.title)
            row.version:SetText(addon.version or "-")
            row.status:SetText(tostring(addon.statusText or ""))
            local color = STATUS_COLORS[addon.statusKey] or STATUS_COLORS.unknown
            row.status:SetTextColor(color[1], color[2], color[3])
            row.memory:SetText(FormatMemory(addon.memoryKB))

            local cpu = self:GetCPUPercent(addon.name)
            row.cpu:SetText(FormatCPU(cpu))
        else
            row:Hide()
        end
    end

    if self.pageText then
        self.pageText:SetText(string.format("%s %d / %d", self:T("PAGE"), currentPage, pages))
    end

    if self.addonResultText then
        self.addonResultText:SetText(string.format(self:T("ADDON_RESULTS"), #list, #(self.addonList or {})))
    end

    if self.pendingText then
        self.pendingText:SetText(self:GetPendingText())
    end

    if self:IsAddonManagerPreviewEnabled() then
        self:RefreshAddonPreviewRows(resetPage)
    end
end

function CH:RefreshProfilerRows()
    if not self.profilerRows then return end
    local list={}
    for _,addon in ipairs(self.addonList or {}) do if addon.loaded then list[#list+1]=addon end end
    table.sort(list,function(a,b)
        local ap=tonumber(self:GetCPUMetric(a.name,"peak")) or -1
        local bp=tonumber(self:GetCPUMetric(b.name,"peak")) or -1
        if ap~=bp then return ap>bp end
        return tostring(a.title):lower()<tostring(b.title):lower()
    end)
    for i,row in ipairs(self.profilerRows) do
        local addon=list[i]
        if addon then
            row.frame:Show()
            row.name:SetText(addon.title or addon.name)
            row.current:SetText(FormatCPU(self:GetCPUMetric(addon.name,"current")))
            row.recent:SetText(FormatCPU(self:GetCPUMetric(addon.name,"recent")))
            row.peak:SetText(FormatCPU(self:GetCPUMetric(addon.name,"peak")))
            row.encounter:SetText(FormatCPU(self:GetCPUMetric(addon.name,"encounter")))
        else row.frame:Hide() end
    end
end

function CH:RefreshSuiteRows()
    if not self.suiteRows then return end

    for _, row in ipairs(self.suiteRows) do
        local name = row.addonName
        local installed = self:IsAddonInstalled(name)
        local loaded = installed and self:IsAddOnLoadedCompat(name)

        row.version:SetText(installed and self:GetAddOnVersion(name) or "-")
        if not installed then
            row.state:SetText(self:T("NOT_INSTALLED"))
            row.state:SetTextColor(1.00, 0.25, 0.20)
            row.open:SetEnabled(false)
        elseif loaded then
            row.state:SetText(self:T("LOADED"))
            row.state:SetTextColor(0.20, 1.00, 0.20)
            row.open:SetEnabled(true)
        else
            row.state:SetText(self:T("NOT_LOADED"))
            row.state:SetTextColor(1.00, 0.82, 0.00)
            row.open:SetEnabled(false)
        end
    end
end

function CH:RefreshLuaErrorUI(force)
    if not self.optionsFrame then return end

    if self.luaErrorStateText then
        if type(SetCVar) ~= "function" and type(GetCVar) ~= "function" and type(GetCVarBool) ~= "function" then
            self.luaErrorStateText:SetText(self:T("LUA_ERRORS_UNAVAILABLE"))
            self.luaErrorStateText:SetTextColor(1.00, 0.25, 0.20)
        elseif self:IsLuaErrorsEnabled() then
            self.luaErrorStateText:SetText(self:T("LUA_ERRORS_ENABLED"))
            self.luaErrorStateText:SetTextColor(0.20, 1.00, 0.20)
        else
            self.luaErrorStateText:SetText(self:T("LUA_ERRORS_DISABLED"))
            self.luaErrorStateText:SetTextColor(1.00, 0.82, 0.00)
        end
    end

    if self.luaErrorCountText then
        self.luaErrorCountText:SetText(string.format(self:T("LUA_COUNT"), #(self.luaErrors or {})))
    end

    if self.luaErrorEditBox then
        local text = self:GetLuaErrorLogText()
        if force or self.luaErrorEditBox:GetText() ~= text then
            local hadFocus = self.luaErrorEditBox:HasFocus()
            if force or not hadFocus then
                self.luaErrorEditBox:SetText(text)
                self.luaErrorEditBox:SetCursorPosition(0)
                self.luaErrorEditBox:SetHeight(math.max(300, 80 + (#(self.luaErrors or {}) * 240)))
            end
        end
    end
end

function CH:RefreshOptions()
    if not self.optionsFrame or not self.db then return end

    for _, control in ipairs(controls) do
        if control._getter then
            control:SetChecked(control._getter() and true or false)
        end
    end

    if self.totalMemoryText then
        self.totalMemoryText:SetText(self:T("TOTAL_MEMORY") .. ": " .. FormatMemory(self.totalMemoryKB or 0))
    end

    if self.cpuStateText then
        if self:HasNativeProfiler() and self.cpuSampleState ~= "unavailable" then
            self.cpuStateText:SetText(self:T("CPU_NATIVE_ACTIVE"))
            self.cpuStateText:SetTextColor(0.20, 1.00, 0.20)
        else
            self.cpuStateText:SetText(self:T("CPU_UNAVAILABLE"))
            self.cpuStateText:SetTextColor(1.00, 0.35, 0.20)
        end
    end

    self:RefreshAddonRows()
    self:RefreshProfilerRows()
    self:RefreshSuiteRows()
    self:RefreshLuaErrorUI(false)
    if self.addonFilterDropdown and self.addonFilterDropdown._refresh then self.addonFilterDropdown._refresh() end
    if self.addonSortDropdown and self.addonSortDropdown._refresh then self.addonSortDropdown._refresh() end
    if self.memoryIntervalDropdown and self.memoryIntervalDropdown._refresh then self.memoryIntervalDropdown._refresh() end
    if self.addonSearchBox and not self.addonSearchBox:HasFocus() then
        local wanted = tostring(self.addonSearchText or "")
        if self.addonSearchBox:GetText() ~= wanted then self.addonSearchBox:SetText(wanted) end
    end
    self:ApplyAddonManagerViewMode()
    self:RefreshAddonPreviewRows(false)
    if self.RefreshSharedSettingsPage then self:RefreshSharedSettingsPage() end
end

function CH:InitializeOptions()
    if self.optionsFrame then return end

    local frame = CreateFrame("Frame", "ComfyHubOptions", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(920, 660)

    local saved = self.db and self.db.optionsWindow or nil
    local point = saved and saved.point or "CENTER"
    local relativePoint = saved and saved.relativePoint or point
    frame:SetPoint(point, UIParent, relativePoint, saved and saved.x or 0, saved and saved.y or 20)

    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(20)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:Hide()
    frame.TitleText:SetText("ComfyHub")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnMouseDown", function(self) self:Raise() end)
    frame:SetScript("OnDragStart", function(self)
        if CH:IsOptionsWindowLocked() then return end
        self:Raise()
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        if CH.db and p then
            CH.db.optionsWindow = CH.db.optionsWindow or {}
            CH.db.optionsWindow.point = p
            CH.db.optionsWindow.relativePoint = rp or p
            CH.db.optionsWindow.x = x or 0
            CH.db.optionsWindow.y = y or 0
        end
    end)

    table.insert(UISpecialFrames, frame:GetName())
    self.optionsFrame = frame
    frame.tabs = {}
    frame.pages = {}

    local tabNames = {
        self:T("TAB_ADDONS"),
        self:T("TAB_PERFORMANCE"),
        self:T("TAB_SUITE"),
        self:T("TAB_DEBUG"),
        self:GetSharedSettingsTabLabel(),
        self:T("TAB_INFO"),
    }

    for i, label in ipairs(tabNames) do
        local tab = CreateButton(frame, label, 18 + (i - 1) * 120, -35, 110, function() SelectTab(i) end)
        frame.tabs[i] = tab

        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 12, -70)
        page:SetPoint("BOTTOMRIGHT", -12, 12)
        frame.pages[i] = page
    end

    -- Addons
    local addons = frame.pages[1]
    self.addonPage = addons

    local searchLabel = addons:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    searchLabel:SetPoint("TOPLEFT", 20, -8)
    searchLabel:SetText(self:T("SEARCH"))

    self.addonSearchBox = CreateFrame("EditBox", nil, addons, "InputBoxTemplate")
    self.addonSearchBox:SetPoint("TOPLEFT", 75, -2)
    self.addonSearchBox:SetSize(245, 28)
    self.addonSearchBox:SetAutoFocus(false)
    self.addonSearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.addonSearchBox:SetScript("OnTextChanged", function(self)
        CH.addonSearchText = self:GetText() or ""
        CH:RefreshAddonRows(true)
    end)

    local filterLabel = addons:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    filterLabel:SetPoint("TOPLEFT", 345, -8)
    filterLabel:SetText(self:T("FILTER"))

    self.addonFilterDropdown = CreateDropdown(addons, 380, -21, 150,
        function()
            return {
                {value="all", text=CH:T("FILTER_ALL")},
                {value="enabled", text=CH:T("FILTER_ENABLED")},
                {value="disabled", text=CH:T("FILTER_DISABLED")},
                {value="loaded", text=CH:T("FILTER_LOADED")},
                {value="problems", text=CH:T("FILTER_PROBLEMS")},
            }
        end,
        function() return CH:GetAddonListFilter() end,
        function(value) CH:SetAddonListFilter(value) end)

    local sortLabel = addons:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sortLabel:SetPoint("TOPLEFT", 585, -8)
    sortLabel:SetText(self:T("SORT"))

    self.addonSortDropdown = CreateDropdown(addons, 615, -21, 180,
        function()
            return {
                {value="suite", text=CH:T("SORT_SUITE")},
                {value="name", text=CH:T("SORT_NAME")},
                {value="memory", text=CH:T("SORT_MEMORY")},
                {value="status", text=CH:T("SORT_STATUS")},
            }
        end,
        function() return CH:GetAddonListSort() end,
        function(value) CH:SetAddonListSort(value) end)

    self.addonResultText = addons:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.addonResultText:SetPoint("TOPRIGHT", -20, -8)
    self.addonResultText:SetJustifyH("RIGHT")

    local headers = {
        {text = "", x = 20},
        {text = self:T("COL_ADDON"), x = 78},
        {text = self:T("COL_VERSION"), x = 410},
        {text = self:T("COL_STATUS"), x = 505},
        {text = self:T("COL_MEMORY"), x = 690},
        {text = self:T("COL_CPU"), x = 785},
    }

    for _, header in ipairs(headers) do
        local fs = addons:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fs:SetPoint("TOPLEFT", header.x, -52)
        fs:SetText(header.text)
    end

    self.addonRows = {}

    for i = 1, ROWS_PER_PAGE do
        local y = -77 - (i - 1) * 29
        local row = CreateFrame("Frame", nil, addons)
        row:SetPoint("TOPLEFT", 10, y)
        row:SetSize(860, 27)

        local separator = row:CreateTexture(nil, "BACKGROUND")
        separator:SetPoint("BOTTOMLEFT", 4, 0)
        separator:SetPoint("BOTTOMRIGHT", -4, 0)
        separator:SetHeight(1)
        separator:SetColorTexture(1, 1, 1, 0.05)

        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetSize(26, 26)
        check:SetPoint("LEFT", 6, 0)
        check:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            local addon = parent and parent._addon
            if not addon then return end
            CH:SetAddOnEnabledCompat(addon.name, self:GetChecked() and true or false)
            addon.enabled = self:GetChecked() and true or false
            CH:RefreshOptions()
        end)
        row.check = check

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("LEFT", 38, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.icon = icon

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("LEFT", 68, 0)
        name:SetWidth(320)
        name:SetJustifyH("LEFT")
        row.name = name

        local version = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        version:SetPoint("LEFT", 400, 0)
        version:SetWidth(85)
        version:SetJustifyH("LEFT")
        row.version = version

        local status = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("LEFT", 495, 0)
        status:SetWidth(175)
        status:SetJustifyH("LEFT")
        row.status = status

        local memory = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        memory:SetPoint("LEFT", 680, 0)
        memory:SetWidth(85)
        memory:SetJustifyH("LEFT")
        row.memory = memory

        local cpu = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        cpu:SetPoint("LEFT", 775, 0)
        cpu:SetWidth(70)
        cpu:SetJustifyH("LEFT")
        row.cpu = cpu

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            local addon = self._addon
            if not addon then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(addon.title or addon.name or "Addon", 1.00, 0.82, 0.00)
            GameTooltip:AddLine((CH:T("ADDON_FOLDER") .. ": ") .. tostring(addon.name or "-"), 0.75, 0.75, 0.75)
            if addon.description and addon.description ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(addon.description, 1, 1, 1, true)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(CH:T("LOADED"), addon.loaded and CH:T("YES") or CH:T("NO"), 0.8,0.8,0.8, 1,1,1)
            GameTooltip:AddDoubleLine(CH:T("ACTIVE"), addon.enabled and CH:T("YES") or CH:T("NO"), 0.8,0.8,0.8, 1,1,1)
            if addon.reason and tostring(addon.reason) ~= "" then
                GameTooltip:AddDoubleLine(CH:T("ADDON_REASON"), tostring(addon.reason), 0.8,0.8,0.8, 1,0.82,0)
            end
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)

        self.addonRows[i] = row
    end

    CreateButton(addons, self:T("PREVIOUS"), 20, -530, 100, function()
        currentPage = math.max(1, currentPage - 1)
        CH:RefreshAddonRows()
    end)

    self.pageText = addons:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.pageText:SetPoint("TOPLEFT", 135, -536)
    self.pageText:SetWidth(130)
    self.pageText:SetJustifyH("CENTER")

    CreateButton(addons, self:T("NEXT"), 275, -530, 100, function()
        local list = CH.visibleAddonList or CH:GetVisibleAddonList()
        local pages = math.max(1, math.ceil(#list / ROWS_PER_PAGE))
        currentPage = math.min(pages, currentPage + 1)
        CH:RefreshAddonRows()
    end)

    CreateButton(addons, self:T("REFRESH"), 575, -530, 120, function()
        CH:RefreshData(true)
    end)

    CreateButton(addons, self:T("APPLY_RELOAD"), 705, -530, 160, function()
        if type(ReloadUI) == "function" then ReloadUI() end
    end)

    self.pendingText = addons:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.pendingText:SetPoint("TOPLEFT", 20, -575)
    self.pendingText:SetWidth(500)
    self.pendingText:SetJustifyH("LEFT")

    -- Experimental compact manager preview.
    -- This is original ComfyHub code using Blizzard/Comfy assets only; it intentionally
    -- borrows only broad information-density ideas from the user's reference screenshot.
    local preview = CreateFrame("Frame", nil, addons, "BackdropTemplate")
    preview:SetAllPoints(addons)
    preview:SetFrameLevel(addons:GetFrameLevel() + 20)
    preview:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    preview:SetBackdropColor(0.025, 0.025, 0.025, 1.00)
    preview:SetBackdropBorderColor(0.48, 0.38, 0.18, 1)
    preview:Hide()
    self.addonPreviewFrame = preview

    local previewTitle = preview:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    previewTitle:SetPoint("TOP", 0, -8)
    previewTitle:SetText("ComfyHub  ·  " .. self:T("TAB_ADDONS"))
    previewTitle:SetTextColor(1.00, 0.82, 0.00)

    self.previewFilterDropdown = CreateDropdown(preview, 10, -35, 120,
        function()
            return {
                {value="all", text=CH:T("FILTER_ALL")},
                {value="enabled", text=CH:T("FILTER_ENABLED")},
                {value="disabled", text=CH:T("FILTER_DISABLED")},
                {value="loaded", text=CH:T("FILTER_LOADED")},
                {value="problems", text=CH:T("FILTER_PROBLEMS")},
            }
        end,
        function() return CH:GetAddonListFilter() end,
        function(value)
            CH:SetAddonListFilter(value)
            previewPage = 1
            CH:RefreshAddonPreviewRows(true)
        end)

    self.previewSearchBox = CreateFrame("EditBox", nil, preview, "InputBoxTemplate")
    self.previewSearchBox:SetPoint("TOPLEFT", 175, -31)
    self.previewSearchBox:SetSize(300, 26)
    self.previewSearchBox:SetAutoFocus(false)
    if self.previewSearchBox.SetTextInsets then
        self.previewSearchBox:SetTextInsets(24, 8, 0, 0)
    end
    self.previewSearchBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    self.previewSearchBox:SetScript("OnTextChanged", function(self)
        CH.addonSearchText = self:GetText() or ""
        previewPage = 1
        CH:RefreshAddonPreviewRows(true)
    end)

    local searchIcon = self.previewSearchBox:CreateTexture(nil, "ARTWORK")
    searchIcon:SetSize(14, 14)
    searchIcon:SetPoint("LEFT", 6, 0)
    searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")

    self.previewSortDropdown = CreateDropdown(preview, 490, -35, 165,
        function()
            return {
                {value="suite", text=CH:T("SORT_SUITE")},
                {value="name", text=CH:T("SORT_NAME")},
                {value="memory", text=CH:T("SORT_MEMORY")},
                {value="status", text=CH:T("SORT_STATUS")},
            }
        end,
        function() return CH:GetAddonListSort() end,
        function(value)
            CH:SetAddonListSort(value)
            previewPage = 1
            CH:RefreshAddonPreviewRows(true)
        end)

    CreateButton(preview, self:T("PREVIEW_PROFILES"), 745, -30, 125, function()
        CH:SelectOptionsTab(5)
    end)

    local function PreviewStat(x, title, accent)
        local titleText = preview:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        titleText:SetPoint("TOPLEFT", x, -82)
        titleText:SetWidth(185)
        titleText:SetJustifyH("CENTER")
        titleText:SetText(title)
        titleText:SetTextColor(accent[1], accent[2], accent[3])

        local valueText = preview:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        valueText:SetPoint("TOPLEFT", x, -101)
        valueText:SetWidth(185)
        valueText:SetJustifyH("CENTER")
        return valueText
    end

    self.previewCpuValue = PreviewStat(25, self:T("PREVIEW_CURRENT_CPU"), {0.45, 1.00, 0.45})
    self.previewMemoryValue = PreviewStat(235, self:T("PREVIEW_MEMORY"), {1.00, 0.82, 0.20})
    self.previewEnabledValue = PreviewStat(445, self:T("PREVIEW_ENABLED"), {0.45, 0.80, 1.00})
    self.previewProblemsValue = PreviewStat(655, self:T("PREVIEW_PROBLEMS"), {1.00, 0.40, 0.35})

    local listBox = CreateFrame("Frame", nil, preview, "BackdropTemplate")
    listBox:SetPoint("TOPLEFT", 12, -132)
    listBox:SetPoint("BOTTOMRIGHT", -12, 54)
    listBox:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true, tileSize = 16, edgeSize = 1,
        insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    listBox:SetBackdropColor(0.01, 0.01, 0.01, 0.72)
    listBox:SetBackdropBorderColor(0.22, 0.22, 0.22, 0.85)

    self.addonPreviewRows = {}
    for i = 1, PREVIEW_ROWS_PER_PAGE do
        local y = -5 - (i - 1) * 26
        local row = CreateFrame("Frame", nil, listBox)
        row:SetPoint("TOPLEFT", 5, y)
        row:SetPoint("TOPRIGHT", -5, y)
        row:SetHeight(25)

        local shade = row:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetColorTexture(1, 1, 1, 0)
        row.shade = shade

        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetSize(24, 24)
        check:SetPoint("LEFT", 3, 0)
        check:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            local addon = parent and parent._addon
            if not addon then return end
            local enabled = self:GetChecked() and true or false
            CH:SetAddOnEnabledCompat(addon.name, enabled)
            addon.enabled = enabled
            CH:RefreshOptions()
        end)
        row.check = check

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(18, 18)
        icon:SetPoint("LEFT", 32, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.icon = icon

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("LEFT", 57, 0)
        name:SetWidth(455)
        name:SetJustifyH("LEFT")
        row.name = name

        local status = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("LEFT", 530, 0)
        status:SetWidth(170)
        status:SetJustifyH("LEFT")
        row.status = status

        local metric = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        metric:SetPoint("RIGHT", -12, 0)
        metric:SetWidth(120)
        metric:SetJustifyH("RIGHT")
        row.metric = metric

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            self.shade:SetColorTexture(1, 0.82, 0, 0.06)
            local addon = self._addon
            if not addon then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(addon.title or addon.name or "Addon", 1.00, 0.82, 0.00)
            GameTooltip:AddLine((CH:T("ADDON_FOLDER") .. ": ") .. tostring(addon.name or "-"), 0.70, 0.70, 0.70)
            if addon.description and addon.description ~= "" then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(addon.description, 1, 1, 1, true)
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(CH:T("COL_MEMORY"), FormatMemory(addon.memoryKB), 0.8,0.8,0.8, 1,1,1)
            GameTooltip:AddDoubleLine(CH:T("COL_CPU"), FormatCPU(CH:GetCPUPercent(addon.name)), 0.8,0.8,0.8, 1,1,1)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function(self)
            self.shade:SetColorTexture(1, 1, 1, 0)
            GameTooltip:Hide()
        end)

        self.addonPreviewRows[i] = row
    end

    CreateButton(preview, self:T("PREVIOUS"), 14, -544, 92, function()
        previewPage = math.max(1, previewPage - 1)
        CH:RefreshAddonPreviewRows(false)
    end)

    self.previewPageText = preview:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.previewPageText:SetPoint("TOPLEFT", 112, -550)
    self.previewPageText:SetWidth(115)
    self.previewPageText:SetJustifyH("CENTER")

    CreateButton(preview, self:T("NEXT"), 232, -544, 92, function()
        local list = CH:GetVisibleAddonList()
        local pages = math.max(1, math.ceil(#list / PREVIEW_ROWS_PER_PAGE))
        previewPage = math.min(pages, previewPage + 1)
        CH:RefreshAddonPreviewRows(false)
    end)

    self.previewResultText = preview:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.previewResultText:SetPoint("TOPLEFT", 342, -550)
    self.previewResultText:SetWidth(165)
    self.previewResultText:SetJustifyH("LEFT")

    self.previewPendingText = preview:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.previewPendingText:SetPoint("TOPLEFT", 500, -550)
    self.previewPendingText:SetWidth(170)
    self.previewPendingText:SetJustifyH("LEFT")

    CreateButton(preview, self:T("REFRESH"), 674, -544, 92, function()
        CH:RefreshData(true)
    end)

    CreateButton(preview, self:T("APPLY_RELOAD"), 772, -544, 105, function()
        if type(ReloadUI) == "function" then ReloadUI() end
    end)

    -- Performance
    local perf = frame.pages[2]

    local ptitle = perf:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ptitle:SetPoint("TOPLEFT", 20, -10)
    ptitle:SetText(self:T("TAB_PERFORMANCE"))

    self.totalMemoryText = perf:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    self.totalMemoryText:SetPoint("TOPLEFT", 20, -55)

    self.cpuStateText = perf:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.cpuStateText:SetPoint("TOPLEFT", 20, -92)

    local hint=perf:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT",20,-120); hint:SetWidth(820); hint:SetJustifyH("LEFT"); hint:SetText(self:T("CPU_NATIVE_HINT"))

    local headers={{self:T("COL_ADDON"),20},{self:T("CPU_CURRENT"),390},{self:T("CPU_RECENT"),500},{self:T("CPU_PEAK"),610},{self:T("CPU_ENCOUNTER"),720}}
    for _,h in ipairs(headers) do local x=perf:CreateFontString(nil,"ARTWORK","GameFontNormal"); x:SetPoint("TOPLEFT",h[2],-165); x:SetText(h[1]) end

    self.profilerRows={}
    for i=1,11 do
        local y=-190-(i-1)*27
        local r=CreateFrame("Frame",nil,perf); r:SetPoint("TOPLEFT",15,y); r:SetSize(840,25)
        local sep=r:CreateTexture(nil,"BACKGROUND"); sep:SetPoint("BOTTOMLEFT",0,0); sep:SetPoint("BOTTOMRIGHT",0,0); sep:SetHeight(1); sep:SetColorTexture(1,1,1,0.04)
        local n=r:CreateFontString(nil,"ARTWORK","GameFontHighlight"); n:SetPoint("LEFT",5,0); n:SetWidth(350); n:SetJustifyH("LEFT")
        local c=r:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); c:SetPoint("LEFT",375,0); c:SetWidth(100); c:SetJustifyH("LEFT")
        local a=r:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); a:SetPoint("LEFT",485,0); a:SetWidth(100); a:SetJustifyH("LEFT")
        local p=r:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); p:SetPoint("LEFT",595,0); p:SetWidth(100); p:SetJustifyH("LEFT")
        local e=r:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); e:SetPoint("LEFT",705,0); e:SetWidth(105); e:SetJustifyH("LEFT")
        self.profilerRows[i]={frame=r,name=n,current=c,recent=a,peak=p,encounter=e}
    end

    local memoryIntervalLabel = perf:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    memoryIntervalLabel:SetPoint("TOPLEFT", 20, -505)
    memoryIntervalLabel:SetText(self:T("MEMORY_UPDATE"))

    self.memoryIntervalDropdown = CreateDropdown(perf, 180, -518, 170,
        function()
            return {
                {value=0, text=CH:T("UPDATE_MANUAL")},
                {value=5, text=string.format(CH:T("SECONDS"), 5)},
                {value=10, text=string.format(CH:T("SECONDS"), 10)},
                {value=30, text=string.format(CH:T("SECONDS"), 30)},
            }
        end,
        function() return CH:GetMemoryUpdateInterval() end,
        function(value) CH:SetMemoryUpdateInterval(value) end)

    CreateButton(perf, self:T("REFRESH"), 590, -515, 130, function() CH:RefreshData(true) end)

    -- Suite
    local suite = frame.pages[3]

    local stitle = suite:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    stitle:SetPoint("TOPLEFT", 20, -10)
    stitle:SetText(self:T("TAB_SUITE"))

    local suiteHint = suite:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    suiteHint:SetPoint("TOPLEFT", 20, -48)
    suiteHint:SetWidth(800)
    suiteHint:SetJustifyH("LEFT")
    suiteHint:SetText(self:T("SUITE_HINT"))

    self.suiteRows = {}

    for i, entry in ipairs(self.family or {}) do
        local name = entry.name
        local y = -82 - (i - 1) * 40

        local icon = suite:CreateTexture(nil,"ARTWORK")
        icon:SetSize(20,20); icon:SetPoint("TOPLEFT",25,y+4); icon:SetTexture(entry.icon); icon:SetTexCoord(0.07,0.93,0.07,0.93)

        local addonName = suite:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        addonName:SetPoint("TOPLEFT", 55, y)
        addonName:SetWidth(245)
        addonName:SetText(name)

        local version = suite:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        version:SetPoint("TOPLEFT", 320, y + 1)
        version:SetWidth(100)
        version:SetJustifyH("LEFT")

        local state = suite:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        state:SetPoint("TOPLEFT", 440, y + 1)
        state:SetWidth(150)
        state:SetJustifyH("LEFT")

        local openButton = CreateButton(suite, self:T("OPEN"), 620, y + 6, 110, function()
            CH:OpenSuiteAddon(name)
        end)

        self.suiteRows[i] = {addonName=name,version=version,state=state,open=openButton,icon=icon}
    end

    local suiteNote = suite:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    suiteNote:SetPoint("TOPLEFT", 20, -535)
    suiteNote:SetWidth(760)
    suiteNote:SetJustifyH("LEFT")
    suiteNote:SetText((GetLocale and GetLocale() == "deDE")
        and ("Minimap- und Fensteroptionen befinden sich einheitlich im Reiter " .. self:GetSharedSettingsTabLabel() .. ".")
        or ("Minimap and window options are now grouped in the " .. self:GetSharedSettingsTabLabel() .. " tab."))

    -- Debug / Lua errors
    local debugPage = frame.pages[4]

    local dtitle = debugPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    dtitle:SetPoint("TOPLEFT", 20, -10)
    dtitle:SetText(self:T("TAB_DEBUG"))

    self.luaErrorToggle = CreateCheck(debugPage, self:T("LUA_ERRORS_SHOW"), 20, -52,
        function() return CH:IsLuaErrorsEnabled() end,
        function(v) CH:SetLuaErrorsEnabled(v) end)

    self.luaErrorStateText = debugPage:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.luaErrorStateText:SetPoint("TOPLEFT", 45, -90)
    self.luaErrorStateText:SetWidth(780)
    self.luaErrorStateText:SetJustifyH("LEFT")

    local logTitle = debugPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    logTitle:SetPoint("TOPLEFT", 20, -130)
    logTitle:SetText(self:T("LUA_LOG_TITLE"))

    self.luaErrorCountText = debugPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    self.luaErrorCountText:SetPoint("TOPRIGHT", -35, -137)
    self.luaErrorCountText:SetJustifyH("RIGHT")

    local logHint = debugPage:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    logHint:SetPoint("TOPLEFT", 20, -165)
    logHint:SetWidth(810)
    logHint:SetJustifyH("LEFT")
    logHint:SetText(self:T("LUA_LOG_HINT"))

    local logBackdrop = CreateFrame("Frame", nil, debugPage, "BackdropTemplate")
    logBackdrop:SetPoint("TOPLEFT", 20, -205)
    logBackdrop:SetSize(820, 305)
    logBackdrop:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4},
    })
    logBackdrop:SetBackdropColor(0.03, 0.03, 0.03, 0.95)

    local scroll = CreateFrame("ScrollFrame", "ComfyHubLuaErrorScrollFrame", logBackdrop, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -10)
    scroll:SetPoint("BOTTOMRIGHT", -30, 10)

    local edit = CreateFrame("EditBox", nil, scroll)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(ChatFontNormal)
    edit:SetWidth(765)
    edit:SetHeight(3000)
    edit:SetJustifyH("LEFT")
    edit:SetJustifyV("TOP")
    if edit.SetTextInsets then edit:SetTextInsets(4, 4, 4, 4) end
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local expected = CH:GetLuaErrorLogText()
            if self:GetText() ~= expected then
                self:SetText(expected)
                self:HighlightText()
            end
        end
    end)
    scroll:SetScrollChild(edit)

    self.luaErrorEditBox = edit
    self.luaErrorScrollFrame = scroll

    CreateButton(debugPage, self:T("LUA_SELECT_ALL"), 20, -530, 150, function()
        if CH.luaErrorEditBox then
            CH.luaErrorEditBox:SetFocus()
            CH.luaErrorEditBox:HighlightText()
        end
    end)

    CreateButton(debugPage, self:T("LUA_CLEAR"), 185, -530, 150, function()
        CH:ClearLuaErrors()
    end)

    -- Shared Settings
    local settingsPage = frame.pages[5]
    self:BuildSharedSettingsPage(settingsPage)

    -- Info
    local infoPage = frame.pages[6]

    local ititle = infoPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ititle:SetPoint("TOPLEFT", 20, -10)
    ititle:SetText(self:T("INFO_TITLE"))

    local infoBox = CreateFrame("Frame", nil, infoPage, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT", 20, -52)
    infoBox:SetSize(680, 455)
    infoBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8},
    })

    local addonName = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    addonName:SetPoint("TOPLEFT", 28, -26)
    addonName:SetText("ComfyHub")

    local familyBadge = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    familyBadge:SetPoint("TOPRIGHT", -28, -30)
    familyBadge:SetText("Comfy Suite")
    familyBadge:SetTextColor(1.00, 0.82, 0.00)

    local tagline = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tagline:SetPoint("TOPLEFT", addonName, "BOTTOMLEFT", 0, -7)
    tagline:SetWidth(620)
    tagline:SetJustifyH("LEFT")
    tagline:SetText("Central addon manager, performance monitor and minimap hub for the Comfy Suite.")

    local function InfoRow(label, value, y)
        local l = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        l:SetPoint("TOPLEFT", 28, y)
        l:SetText(label)

        local v = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        v:SetPoint("TOPLEFT", 185, y)
        v:SetWidth(455)
        v:SetJustifyH("LEFT")
        v:SetText(value or "-")
        return l, v
    end

    local clientVersion, clientBuild, _, clientInterface = CH:GetClientBuildInfo()
    local compatible, compatibilityText = CH:GetCompatibilityStatus()

    InfoRow(self:T("INFO_VERSION"), CH.version, -100)
    InfoRow(self:T("INFO_BUILD_DATE"), CH.buildDate, -122)
    InfoRow(self:T("INFO_STATUS"), CH.status, -144)
    InfoRow(self:T("INFO_CLIENT"), "WoW Forever " .. tostring(clientVersion) .. " / Build " .. tostring(clientBuild) .. " / Interface " .. tostring(clientInterface or "?"), -166)
    InfoRow(self:T("INFO_TESTED_TARGET"), CH.gameVersion .. " / Build " .. CH.targetBuild .. " / Interface " .. tostring(CH.interface), -188)

    local _, compatValue = InfoRow(self:T("INFO_COMPAT_STATUS"), compatibilityText, -210)
    if compatible then
        compatValue:SetTextColor(0.20, 1.00, 0.20)
    else
        compatValue:SetTextColor(1.00, 0.35, 0.20)
    end

    InfoRow(self:T("INFO_AUTHOR"), CH.author, -232)

    local discordLabel = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    discordLabel:SetPoint("TOPLEFT", 28, -257)
    discordLabel:SetText(self:T("INFO_DISCORD"))

    local discordBox = CreateFrame("EditBox", nil, infoBox, "InputBoxTemplate")
    discordBox:SetSize(275, 30)
    discordBox:SetPoint("TOPLEFT", 180, -248)
    discordBox:SetAutoFocus(false)
    discordBox:SetText(CH.discord)
    discordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discordBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    discordBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local copyHint = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHint:SetPoint("TOPLEFT", 470, -255)
    copyHint:SetText(self:T("INFO_COPY"))

    local githubLabel = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    githubLabel:SetPoint("TOPLEFT", 28, -292)
    githubLabel:SetText(self:T("INFO_GITHUB"))

    local githubBox = CreateFrame("EditBox", nil, infoBox, "InputBoxTemplate")
    githubBox:SetSize(395, 30)
    githubBox:SetPoint("TOPLEFT", 180, -283)
    githubBox:SetAutoFocus(false)
    githubBox:SetText(CH.github)
    githubBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    githubBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    githubBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    InfoRow(self:T("INFO_COMMANDS"), "/comfyhub  ·  /ch", -328)

    local notice = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    notice:SetPoint("TOPLEFT", 28, -345)
    notice:SetWidth(620)
    notice:SetHeight(42)
    notice:SetJustifyH("LEFT")
    notice:SetJustifyV("TOP")
    notice:SetText(self:T("INFO_NOTICE"))

    local copyright = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyright:SetPoint("BOTTOMLEFT", 28, 48)
    copyright:SetText("© 2026 TheRealDoubleG")

    local thanks = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    thanks:SetPoint("BOTTOMLEFT", 28, 16)
    thanks:SetWidth(620)
    thanks:SetJustifyH("LEFT")
    thanks:SetText(self:T("INFO_THANKS"))

    frame:SetScript("OnShow", function()
        CH:ApplySharedWindowSettings()
        CH:RefreshData(true)
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        self._comfyElapsed = (self._comfyElapsed or 0) + elapsed
        if self._comfyElapsed >= 1.0 then
            self._comfyElapsed = 0
            if self:IsShown() then
                CH:RefreshMemory(false)
                CH:RefreshCPU()
                CH:RefreshOptions()
            end
        end
    end)

    self:ApplySharedWindowSettings()
    SelectTab(1)
    self:RefreshOptions()
end

function CH:ShowOptions()
    if not self.optionsFrame then self:InitializeOptions() end
    self.optionsFrame:Show()
    self.optionsFrame:Raise()
    self:RefreshData(true)
end
