local ADDON_NAME = ...

ComfyHub = ComfyHub or {}
local CH = ComfyHub

CH.name = ADDON_NAME or "ComfyHub"
CH.version = "0.13"
CH.buildDate = "27.09.2026"
CH.status = "Beta"
CH.gameVersion = "WoW Forever 1.60.1"
CH.targetBuild = "70009"
CH.interface = 16001
CH.author = "TheRealDoubleG"
CH.discord = "the.real.double.g"
CH.github = "https://github.com/TheRealDoubleG/ComfyHub"

CH.pendingChanges = CH.pendingChanges or {}
CH.flyoutShown = false

CH.family = {
    {name = "ComfyOnPoint",  icon = "Interface\\Icons\\INV_Misc_Spyglass_03", flyout = true},
    {name = "ComfyBar",      icon = "Interface\\Icons\\INV_Misc_Bag_10", flyout = true},
    {name = "ComfyCC",       icon = "Interface\\Icons\\Spell_Holy_BorrowedTime", flyout = true},
    {name = "ComfyMacro",    icon = "Interface\\Icons\\INV_Misc_Note_01", flyout = true},
    {name = "ComfyProfiles", icon = "Interface\\Icons\\INV_Misc_Note_03", flyout = true},
    {name = "ComfyKey",      icon = "Interface\\Icons\\INV_Misc_Key_03", flyout = true},
    {name = "ComfyEnemyBar", icon = "Interface\\Icons\\Ability_Hunter_SniperShot", flyout = false},
    {name = "ComfyPanel",    icon = "Interface\\Icons\\INV_Misc_Gear_01", flyout = false},
    {name = "ComfyBag",      icon = "Interface\\Icons\\INV_Misc_Bag_10", flyout = false},
    {name = "ComfyMog",      icon = "Interface\\Icons\\INV_Misc_Cape_18", flyout = false},
    {name = "ComfyXP",       icon = "Interface\\Icons\\INV_Misc_Book_09", flyout = false},
}

local defaults = {
    minimap = {
        show = true,
        locked = false,
        angle = 220,
        bundleSuiteIcons = true,
    },
    performance = {
        cpuProfilingRequested = false,
        memoryUpdateInterval = 10,
    },
    addons = {
        filter = "all",
        sort = "suite",
    },
    debug = {
        maxLuaErrors = 50,
    },
    optionsWindow = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 20,
    },
    ui = {
        windowLocked = false,
        windowOpacity = 100,
        showWindowBorder = true,
        backgroundAlpha = 92,
        addonManagerPreviewStyle = false,
    },
}

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do
        dst[k] = CopyTable(v)
    end
    return dst
end

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function CH:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyHub:|r " .. tostring(msg))
    end
end

function CH:GetClientBuildInfo()
    if type(GetBuildInfo) ~= "function" then
        return "?", "?", "?", nil
    end
    local version, build, buildDate, interface = GetBuildInfo()
    return tostring(version or "?"), tostring(build or "?"), tostring(buildDate or "?"), tonumber(interface)
end

function CH:GetCompatibilityStatus()
    local _, _, _, clientInterface = self:GetClientBuildInfo()
    if clientInterface and tonumber(clientInterface) == tonumber(self.interface) then
        return true, self:T("COMPAT_MATCH")
    end
    return false, self:T("COMPAT_UPDATE_REQUIRED")
end

function CH:InitializeDB()
    if self.InitializeProfileStorage then
        self:InitializeProfileStorage(defaults, "ComfyHubDB")
    else
        if type(ComfyHubDB) ~= "table" then
            ComfyHubDB = CopyTable(defaults)
        else
            ApplyDefaults(ComfyHubDB, defaults)
        end
        self.db = ComfyHubDB
    end
end

function CH:GetPendingCount()
    local count = 0
    for _ in pairs(self.pendingChanges or {}) do
        count = count + 1
    end
    return count
end

function CH:MarkAddonPending(name)
    if not name then return end
    self.pendingChanges[name] = true
end

function CH:ClearPending()
    wipe(self.pendingChanges)
end

function CH:OpenOptions()
    if self.ShowOptions then self:ShowOptions() end
end

SLASH_COMFYHUB1 = "/comfyhub"
SLASH_COMFYHUB2 = "/ch"
SlashCmdList.COMFYHUB = function(msg)
    msg = tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "flyout" then
        if CH.ToggleFlyout then CH:ToggleFlyout() end
    elseif msg == "refresh" then
        if CH.RefreshData then CH:RefreshData(true) end
    else
        CH:OpenOptions()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == CH.name then
            CH:InitializeDB()
            if CH.InitializeAddonManager then CH:InitializeAddonManager() end
            if CH.InitializePerformance then CH:InitializePerformance() end
            if CH.InitializeDebug then CH:InitializeDebug() end
            if CH.InstallLuaErrorCapture then CH:InstallLuaErrorCapture() end
            if CH.InitializeMinimap then CH:InitializeMinimap() end
            if CH.InitializeOptions then CH:InitializeOptions() end
            if CH.ApplyMinimapBundling then CH:ApplyMinimapBundling() end
            return
        end

        if CH.db and CH.family then
            for _, entry in ipairs(CH.family) do
                if entry.name == arg1 then
                    if CH.ApplyMinimapBundling then CH:ApplyMinimapBundling() end
                    if CH.RefreshFlyout then CH:RefreshFlyout() end
                    break
                end
            end
        end
    elseif event == "PLAYER_LOGIN" then
        if CH.InstallLuaErrorCapture then CH:InstallLuaErrorCapture() end
        if CH.RefreshData then CH:RefreshData(true) end
        if CH.ApplyMinimapBundling then CH:ApplyMinimapBundling() end
        if CH.RefreshFlyout then CH:RefreshFlyout() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if CH.RefreshData then CH:RefreshData(true) end
        if CH.ApplyMinimapBundling then CH:ApplyMinimapBundling() end
    end
end)
