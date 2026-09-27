ComfyHub = ComfyHub or {}
local CH = ComfyHub

local controls = {}
local currentPage = 1
local ROWS_PER_PAGE = 12

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

local function SelectTab(index)
    local frame = CH.optionsFrame
    if not frame then return end
    for i, tab in ipairs(frame.tabs) do
        tab:SetEnabled(i ~= index)
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
            row.name:SetText(addon.title)
            row.version:SetText(addon.version or "-")
            row.status:SetText("● " .. tostring(addon.statusText or ""))
            local color = STATUS_COLORS[addon.statusKey] or STATUS_COLORS.unknown
            row.status:SetTextColor(color[1], color[2], color[3])
            row.memory:SetText(FormatMemory(addon.memoryKB))

            local cpu = self:GetCPUPercent(addon.name)
            row.cpu:SetText(cpu and string.format("%.2f%%", cpu) or "—")
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
        if self:IsCPUProfilingEnabled() then
            self.cpuStateText:SetText("CPU: ON")
            self.cpuStateText:SetTextColor(0.20, 1.00, 0.20)
        else
            self.cpuStateText:SetText(self:T("CPU_UNAVAILABLE"))
            self.cpuStateText:SetTextColor(1.00, 0.82, 0.00)
        end
    end

    self:RefreshAddonRows()
    self:RefreshSuiteRows()
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
        self:T("TAB_INFO"),
    }

    for i, label in ipairs(tabNames) do
        local tab = CreateButton(frame, label, 18 + (i - 1) * 150, -35, 140, function() SelectTab(i) end)
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
        {text = self:T("COL_ADDON"), x = 58},
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
        local y = -48 - (i - 1) * 39
        local row = CreateFrame("Frame", nil, addons)
        row:SetPoint("TOPLEFT", 10, y)
        row:SetSize(860, 34)

        local check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        check:SetPoint("LEFT", 8, 0)
        check:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            local addon = parent and parent._addon
            if not addon then return end
            CH:SetAddOnEnabledCompat(addon.name, self:GetChecked() and true or false)
            addon.enabled = self:GetChecked() and true or false
            CH:RefreshOptions()
        end)
        row.check = check

        local name = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        name:SetPoint("LEFT", 48, 0)
        name:SetWidth(340)
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
    local suiteNames = {"OnPoint", "ComfyBar", "ComfyCC"}

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

    CreateCheck(suite, self:T("MINIMAP_SHOW"), 20, -365,
        function() return CH.db.minimap.show end,
        function(v)
            CH.db.minimap.show = v
            CH:UpdateMinimapPosition()
            CH:RefreshFlyout()
        end)

    CreateCheck(suite, self:T("MINIMAP_LOCK"), 20, -405,
        function() return CH.db.minimap.locked end,
        function(v) CH.db.minimap.locked = v end)

    -- Info
    local infoPage = frame.pages[4]

    local ititle = infoPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ititle:SetPoint("TOPLEFT", 20, -10)
    ititle:SetText("ComfyHub")

    local infoBox = CreateFrame("Frame", nil, infoPage, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT", 20, -52)
    infoBox:SetSize(820, 485)
    infoBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8},
    })

    local addonName = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    addonName:SetPoint("TOPLEFT", 28, -26)
    addonName:SetText("ComfyHub")

    local tagline = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tagline:SetPoint("TOPLEFT", addonName, "BOTTOMLEFT", 0, -7)
    tagline:SetWidth(730)
    tagline:SetJustifyH("LEFT")
    tagline:SetText("Central addon manager, performance monitor and minimap hub for the Comfy Suite.")

    local function InfoRow(label, value, y)
        local l = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        l:SetPoint("TOPLEFT", 28, y)
        l:SetText(label)

        local v = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        v:SetPoint("TOPLEFT", 190, y)
        v:SetWidth(570)
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
    discordBox:SetSize(290, 30)
    discordBox:SetPoint("TOPLEFT", 185, -248)
    discordBox:SetAutoFocus(false)
    discordBox:SetText(CH.discord)
    discordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discordBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    discordBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local copyHint = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHint:SetPoint("TOPLEFT", 490, -255)
    copyHint:SetText(self:T("INFO_COPY"))

    InfoRow(self:T("INFO_GITHUB"), CH.github, -292)
    InfoRow(self:T("INFO_COMMANDS"), "/comfyhub  ·  /ch", -318)

    local notice = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    notice:SetPoint("TOPLEFT", 28, -352)
    notice:SetWidth(730)
    notice:SetJustifyH("LEFT")
    notice:SetText(self:T("INFO_NOTICE"))

    local copyright = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyright:SetPoint("BOTTOMLEFT", 28, 68)
    copyright:SetText("© 2026 TheRealDoubleG")

    local thanks = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    thanks:SetPoint("BOTTOMLEFT", 28, 28)
    thanks:SetWidth(730)
    thanks:SetJustifyH("LEFT")
    thanks:SetText(self:T("INFO_THANKS"))

    frame:SetScript("OnShow", function()
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

    SelectTab(1)
    self:RefreshOptions()
end

function CH:ShowOptions()
    if not self.optionsFrame then self:InitializeOptions() end
    self.optionsFrame:Show()
    self.optionsFrame:Raise()
    self:RefreshData()
end
