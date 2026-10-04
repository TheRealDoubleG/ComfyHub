ComfyHub = ComfyHub or {}
local CH = ComfyHub

CH.version = "0.22"
CH.buildDate = "04.10.2026"

local FLYOUT_OFFSET = 6

-- Keep the flyout's top-right corner fixed to the left side of the Hub button.
-- The panel therefore always grows to the left instead of jumping above/below
-- the minimap depending on screen position.
function CH:PositionFlyoutBackdrop()
    local backdrop = self.flyoutBackdrop
    local button = self.minimapButton
    if not backdrop or not button then return end

    backdrop:ClearAllPoints()
    backdrop:SetPoint("TOPRIGHT", button, "TOPLEFT", -FLYOUT_OFFSET, 0)
end

local originalRefreshFlyout = CH.RefreshFlyout
function CH:RefreshFlyout(...)
    local result
    if originalRefreshFlyout then result = originalRefreshFlyout(self, ...) end
    if self.flyoutBackdrop and self.flyoutBackdrop:IsShown() then
        self:PositionFlyoutBackdrop()
    end
    return result
end
