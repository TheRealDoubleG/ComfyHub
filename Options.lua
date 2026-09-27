ComfyHub = ComfyHub or {}
local CH = ComfyHub

local controls = {}
local currentPage = 1
local ROWS_PER_PAGE = 16

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
    if value > 0 and value < 0.01 then return "<0.01%" end
    return string.format("%.2f%%", value)
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

function CH:GetPendingText()
    local count = self:GetPendingCount()
    if count == 0 then return self:T("PENDING_NONE") end
    if count == 1 then return self:T("PENDING_ONE") end
    return string.format(self:T("PENDING_MANY"), count)
end

function CH:RefreshAddonRows()
    if not self.addonRows then return end

    local list = self.addonList or self:BuildAddonList()
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

    if self.pendingText then
        self.pendingText:SetText(self:GetPendingText())
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
        if not self:IsCPUProfilingEnabled() then
            self.cpuStateText:SetText(self:T("CPU_UNAVAILABLE"))
            self.cpuStateText:SetTextColor(1.00, 0.82, 0.00)
        elseif self.cpuSampleState == "unavailable" then
            self.cpuStateText:SetText((GetLocale and GetLocale() == "deDE") and "CPU: API nicht verfügbar" or "CPU: API unavailable")
            self.cpuStateText:SetTextColor(1.00, 0.35, 0.20)
        elseif self.cpuSampleState == "sampling" or self.cpuSampleState == nil then
            self.cpuStateText:SetText((GetLocale and GetLocale() == "deDE") and "CPU: AN – Messwert wird gesammelt…" or "CPU: ON – collecting sample…")
            self.cpuStateText:SetTextColor(1.00, 0.82, 0.00)
        else
            self.cpuStateText:SetText("CPU: ON")
            self.cpuStateText:SetTextColor(0.20, 1.00, 0.20)
        end
    end

    self:RefreshAddonRows()
    self:RefreshSuiteRows()
    self:RefreshLuaErrorUI(false)
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
        fs:SetPoint("TOPLEFT", header.x, -18)
        fs:SetText(header.text)
    end

    self.addonRows = {}

    for i = 1, ROWS_PER_PAGE do
        local y = -43 - (i - 1) * 29
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
        local list = CH.addonList or {}
        local pages = math.max(1, math.ceil(#list / ROWS_PER_PAGE))
        currentPage = math.min(pages, currentPage + 1)
        CH:RefreshAddonRows()
    end)

    CreateButton(addons, self:T("REFRESH"), 575, -530, 120, function()
        CH:RefreshData()
    end)

    CreateButton(addons, self:T("APPLY_RELOAD"), 705, -530, 160, function()
        if type(ReloadUI) == "function" then ReloadUI() end
    end)

    self.pendingText = addons:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.pendingText:SetPoint("TOPLEFT", 20, -575)
    self.pendingText:SetWidth(500)
    self.pendingText:SetJustifyH("LEFT")

    -- Performance
    local perf = frame.pages[2]

    local ptitle = perf:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ptitle:SetPoint("TOPLEFT", 20, -10)
    ptitle:SetText(self:T("TAB_PERFORMANCE"))

    self.totalMemoryText = perf:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    self.totalMemoryText:SetPoint("TOPLEFT", 20, -60)

    self.cpuStateText = perf:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.cpuStateText:SetPoint("TOPLEFT", 20, -100)

    CreateCheck(perf, self:T("CPU_PROFILING"), 20, -145,
        function() return CH:IsCPUProfilingEnabled() end,
        function(v) CH:SetCPUProfilingRequested(v) end)

    local cpuHint = perf:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    cpuHint:SetPoint("TOPLEFT", 45, -180)
    cpuHint:SetWidth(780)
    cpuHint:SetJustifyH("LEFT")
    cpuHint:SetText(self:T("CPU_RELOAD_HINT"))

    local performanceHint = perf:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    performanceHint:SetPoint("TOPLEFT", 20, -250)
    performanceHint:SetWidth(800)
    performanceHint:SetJustifyH("LEFT")
    performanceHint:SetText(self:T("PERFORMANCE_HINT"))

    CreateButton(perf, self:T("REFRESH"), 20, -330, 140, function()
        CH:RefreshData()
    end)

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
    local suiteNames = {"ComfyOnPoint", "ComfyBar", "ComfyCC", "ComfyMacro"}

    for i, name in ipairs(suiteNames) do
        local y = -115 - (i - 1) * 70

        local addonName = suite:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        addonName:SetPoint("TOPLEFT", 30, y)
        addonName:SetText(name)

        local version = suite:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        version:SetPoint("TOPLEFT", 250, y + 2)
        version:SetWidth(100)
        version:SetJustifyH("LEFT")

        local state = suite:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        state:SetPoint("TOPLEFT", 380, y + 2)
        state:SetWidth(160)
        state:SetJustifyH("LEFT")

        local openButton = CreateButton(suite, self:T("OPEN"), 590, y + 8, 120, function()
            CH:OpenSuiteAddon(name)
        end)

        self.suiteRows[i] = {
            addonName = name,
            version = version,
            state = state,
            open = openButton,
        }
    end

    local suiteNote = suite:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    suiteNote:SetPoint("TOPLEFT", 20, -405)
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
        CH:RefreshData()
    end)

    frame:SetScript("OnUpdate", function(self, elapsed)
        self._comfyElapsed = (self._comfyElapsed or 0) + elapsed
        if self._comfyElapsed >= 1.0 then
            self._comfyElapsed = 0
            if self:IsShown() then
                CH:RefreshMemory()
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
    self:RefreshData()
end
