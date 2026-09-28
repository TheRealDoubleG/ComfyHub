ComfyHub = ComfyHub or {}
local CH = ComfyHub

CH.layoutTargets = CH.layoutTargets or {}

function CH:IsSuiteEditMode()
    return self.db and self.db.layout and self.db.layout.editMode and true or false
end

function CH:RegisterLayoutTarget(owner, key, frame, callbacks)
    if not owner or not key or not frame then return false end
    self.layoutTargets[owner] = self.layoutTargets[owner] or {}
    self.layoutTargets[owner][key] = {
        frame = frame,
        callbacks = callbacks or {},
    }
    local cb = self.layoutTargets[owner][key].callbacks
    if type(cb.setEditMode) == "function" then
        pcall(cb.setEditMode, self:IsSuiteEditMode())
    end
    return true
end

function CH:UnregisterLayoutTarget(owner, key)
    if self.layoutTargets[owner] then self.layoutTargets[owner][key] = nil end
end

function CH:SetSuiteEditMode(enabled)
    if not self.db then return false end
    self.db.layout = self.db.layout or {}
    self.db.layout.editMode = enabled and true or false

    for _, targets in pairs(self.layoutTargets or {}) do
        for _, entry in pairs(targets) do
            if entry and entry.frame then
                local cb = entry.callbacks or {}
                if type(cb.setEditMode) == "function" then
                    pcall(cb.setEditMode, self.db.layout.editMode)
                elseif entry.frame.EnableMouse then
                    entry.frame:EnableMouse(self.db.layout.editMode)
                end
            end
        end
    end

    self:Print(self.db.layout.editMode and self:T("LAYOUT_EDIT_ON") or self:T("LAYOUT_EDIT_OFF"))
    if self.RefreshSharedSettingsPage then self:RefreshSharedSettingsPage() end
    return true
end
