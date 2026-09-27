ComfyHub = ComfyHub or {}
local CH = ComfyHub

local function GetButtonRadius(button)
    if not Minimap then return 95 end
    local width = Minimap:GetWidth() or 140
    local height = Minimap:GetHeight() or width
    local mapRadius = math.min(width, height) / 2
    local buttonRadius = ((button and button:GetWidth()) or 32) / 2
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
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(10)
    button:SetClampedToScreen(true)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(iconPath)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    return button
end

function CH:UpdateMinimapPosition()
    if not self.minimapButton or not self.db then return end
    PositionFromAngle(self.minimapButton, self.db.minimap.angle)
    self.minimapButton:SetShown(self.db.minimap.show)
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

    for index, entry in ipairs(self.family) do
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

        self.flyoutButtons[index] = button
    end
end

function CH:RefreshFlyout()
    if not self.flyoutButtons or not self.minimapButton then return end

    local mainX, mainY = self.minimapButton:GetCenter()
    local miniX, miniY = Minimap and Minimap:GetCenter()
    local dx, dy = 0, -1

    if mainX and mainY and miniX and miniY then
        dx = mainX - miniX
        dy = mainY - miniY
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 0 then
            dx = dx / length
            dy = dy / length
        end

        -- Expand toward the screen rather than further beyond the minimap edge.
        if mainX > (UIParent:GetWidth() or 0) * 0.75 then dx = -math.abs(dx) end
        if mainY > (UIParent:GetHeight() or 0) * 0.75 then dy = -math.abs(dy) end
    end

    for index, button in ipairs(self.flyoutButtons) do
        local distance = 42 * index
        button:ClearAllPoints()
        button:SetPoint("CENTER", self.minimapButton, "CENTER", dx * distance, dy * distance)

        local installed = self:IsAddonInstalled(button.entry.name)
        button.icon:SetDesaturated(not installed)
        button.icon:SetVertexColor(installed and 1 or 0.55, installed and 1 or 0.55, installed and 1 or 0.55)
        button:SetShown(self.flyoutShown and self.db.minimap.show)
    end
end

function CH:ToggleFlyout()
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
    self:RefreshFlyout()
end
