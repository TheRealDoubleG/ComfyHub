ComfyHub = ComfyHub or {}
local CH = ComfyHub

local FLYOUT_ANGLE_STEP = 22
local FLYOUT_PADDING = 5

local function GetButtonRadius(button)
    if not Minimap then return 95 end
    local width = Minimap:GetWidth() or 140
    local height = Minimap:GetHeight() or width
    local mapRadius = math.min(width, height) / 2
    local buttonRadius = ((button and button:GetWidth()) or 30) / 2
    return mapRadius + buttonRadius + 2
end

local function PositionFromAngle(button, angle)
    if not Minimap then return end
    local radians = math.rad(angle or 220)
    local radius = GetButtonRadius(button)
    local x = math.cos(radians) * radius
    local y = math.sin(radians) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function CreateRoundButton(name, parent, iconPath)
    local button = CreateFrame("Button", name, parent)
    button:SetSize(30, 30)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(10)
    button:SetClampedToScreen(true)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(23, 23)
    background:SetPoint("CENTER")
    background:SetAlpha(0.75)
    button.background = background

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(iconPath)
    icon:SetSize(22, 22)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(48, 48)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    border:SetVertexColor(0.82, 0.58, 0.30, 1)
    button.border = border

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    return button
end

function CH:IsMinimapBundlingActive()
    return self.db
        and self.db.minimap
        and self.db.minimap.show
        and self.db.minimap.bundleSuiteIcons ~= false
end

function CH:ApplyMinimapBundling()
    if not self.db or not self.db.minimap then return end
    local bundled = self:IsMinimapBundlingActive()

    for _, entry in ipairs(self.family or {}) do
        local addon = rawget(_G, entry.name)
        if type(addon) == "table" and type(addon.SetMinimapBundled) == "function" then
            addon:SetMinimapBundled(bundled)
        else
            local button = rawget(_G, entry.name .. "MinimapButton")
            if button then
                if bundled then
                    button:Hide()
                else
                    button:Show()
                end
            end
        end
    end
end

function CH:SetMinimapBundling(enabled)
    if not self.db or not self.db.minimap then return end
    self.db.minimap.bundleSuiteIcons = enabled and true or false
    if not enabled then
        self.flyoutShown = false
    end
    self:ApplyMinimapBundling()
    self:RefreshFlyout()
end

function CH:UpdateMinimapPosition()
    if not self.minimapButton or not self.db then return end
    PositionFromAngle(self.minimapButton, self.db.minimap.angle)
    self.minimapButton:SetShown(self.db.minimap.show)
    self:ApplyMinimapBundling()
end

function CH:OpenSuiteAddon(name)
    if not self:IsAddonInstalled(name) then
        self:Print(string.format(self:T("SUITE_NOT_INSTALLED"), name))
        return
    end

    local addon = _G[name]
    if not addon then
        self:Print(string.format(self:T("SUITE_NOT_LOADED"), name))
        return
    end

    if type(addon.OpenOptions) == "function" then
        addon:OpenOptions()
        return
    end

    if type(addon.ShowOptions) == "function" then
        addon:ShowOptions()
        return
    end

    self:Print(string.format(self:T("SUITE_NOT_LOADED"), name))
end

function CH:CreateFlyout()
    if self.flyoutButtons then return end
    self.flyoutButtons = {}

    local backdrop = CreateFrame("Frame", "ComfyHubFlyoutBackdrop", UIParent, "BackdropTemplate")
    backdrop:SetFrameStrata("DIALOG")
    backdrop:SetFrameLevel(18)
    backdrop:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 7,
        insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    backdrop:SetBackdropColor(0, 0, 0, 0.75)
    backdrop:SetBackdropBorderColor(0.54, 0.36, 0.18, 0.95)
    backdrop:Hide()
    self.flyoutBackdrop = backdrop

    local flyoutIndex = 0
    for _, entry in ipairs(self.family) do
        if entry.flyout ~= false then
            flyoutIndex = flyoutIndex + 1
        local button = CreateRoundButton("ComfyHubFlyout" .. entry.name, UIParent, entry.icon)
        button:SetFrameStrata("DIALOG")
        button:SetFrameLevel(20)
        button:Hide()
        button.entry = entry

        button:SetScript("OnClick", function(self)
            CH:OpenSuiteAddon(self.entry.name)
        end)

        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(self.entry.name, 1, 0.82, 0)
            if CH:IsAddonInstalled(self.entry.name) then
                GameTooltip:AddLine(CH:IsAddOnLoadedCompat(self.entry.name) and CH:T("LOADED") or CH:T("NOT_LOADED"), 1, 1, 1)
            else
                GameTooltip:AddLine(CH:T("NOT_INSTALLED"), 1, 0.35, 0.2)
            end
            GameTooltip:Show()
        end)

        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        self.flyoutButtons[flyoutIndex] = button
        end
    end
end

function CH:UpdateFlyoutBackdrop()
    local backdrop = self.flyoutBackdrop
    if not backdrop then return end

    if not self.flyoutShown or not self:IsMinimapBundlingActive() then
        backdrop:Hide()
        return
    end

    local left, right, top, bottom
    local visibleCount = 0

    for _, button in ipairs(self.flyoutButtons or {}) do
        if button:IsShown() then
            local l, r, t, b = button:GetLeft(), button:GetRight(), button:GetTop(), button:GetBottom()
            if l and r and t and b then
                left = left and math.min(left, l) or l
                right = right and math.max(right, r) or r
                top = top and math.max(top, t) or t
                bottom = bottom and math.min(bottom, b) or b
                visibleCount = visibleCount + 1
            end
        end
    end

    if visibleCount == 0 or not left or not right or not top or not bottom then
        backdrop:Hide()
        return
    end

    backdrop:ClearAllPoints()
    backdrop:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left - FLYOUT_PADDING, bottom - FLYOUT_PADDING)
    backdrop:SetSize((right - left) + FLYOUT_PADDING * 2, (top - bottom) + FLYOUT_PADDING * 2)
    backdrop:Show()
end

function CH:RefreshFlyout()
    if not self.flyoutButtons or not self.minimapButton or not self.db then return end

    if not self:IsMinimapBundlingActive() then
        self.flyoutShown = false
        for _, button in ipairs(self.flyoutButtons) do
            button:Hide()
        end
        if self.flyoutBackdrop then self.flyoutBackdrop:Hide() end
        return
    end

    local baseAngle = tonumber(self.db.minimap.angle) or 220
    local direction = math.sin(math.rad(baseAngle)) < 0 and -1 or 1
    local slot = 0

    for _, button in ipairs(self.flyoutButtons) do
        local installed = self:IsAddonInstalled(button.entry.name)
        if installed then
            slot = slot + 1
            local angle = baseAngle + direction * FLYOUT_ANGLE_STEP * slot
            PositionFromAngle(button, angle)
            local loaded = self:IsAddOnLoadedCompat(button.entry.name)
            button.icon:SetDesaturated(not loaded)
            button.icon:SetVertexColor(loaded and 1 or 0.55, loaded and 1 or 0.55, loaded and 1 or 0.55)
            button:SetShown(self.flyoutShown and self.db.minimap.show)
        else
            button:Hide()
        end
    end

    self:UpdateFlyoutBackdrop()
end

function CH:ToggleFlyout()
    if not self:IsMinimapBundlingActive() then
        self.flyoutShown = false
        self:RefreshFlyout()
        return
    end
    self.flyoutShown = not self.flyoutShown
    self:RefreshFlyout()
end

function CH:InitializeMinimap()
    if self.minimapButton or not Minimap then return end

    local button = CreateRoundButton("ComfyHubMinimapButton", Minimap, "Interface\\Icons\\INV_Misc_Gear_01")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            CH:ToggleFlyout()
        elseif mouseButton == "RightButton" then
            CH:OpenOptions()
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ComfyHub", 1, 0.82, 0)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(CH:T("MINIMAP_LEFT"), 1, 1, 1)
        GameTooltip:AddLine(CH:T("MINIMAP_RIGHT"), 1, 1, 1)
        GameTooltip:AddLine(CH.db.minimap.locked and CH:T("MINIMAP_LOCKED") or CH:T("MINIMAP_DRAG"), 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function(self)
        if CH.db.minimap.locked then return end
        CH.flyoutShown = false
        CH:RefreshFlyout()

        self:SetScript("OnUpdate", function(btn)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            if scale and scale > 0 then
                cx, cy = cx / scale, cy / scale
                local angle = math.deg(math.atan2(cy - my, cx - mx))
                CH.db.minimap.angle = angle
                PositionFromAngle(btn, angle)
                CH:RefreshFlyout()
            end
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        CH:RefreshFlyout()
    end)

    self.minimapButton = button
    self:CreateFlyout()
    self:UpdateMinimapPosition()
    self:ApplyMinimapBundling()
    self:RefreshFlyout()
end
