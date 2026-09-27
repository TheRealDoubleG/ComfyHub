ComfyHub = ComfyHub or {}
local CH = ComfyHub

function CH:IsCPUProfilingEnabled()
    if type(GetCVarBool) == "function" then
        local ok, value = pcall(GetCVarBool, "scriptProfile")
        if ok then return value and true or false end
    end

    if type(GetCVar) == "function" then
        local ok, value = pcall(GetCVar, "scriptProfile")
        if ok then
            return tostring(value) == "1"
        end
    end

    return false
end

function CH:SetCPUProfilingRequested(enabled)
    if type(SetCVar) ~= "function" then return false end

    local ok = pcall(SetCVar, "scriptProfile", enabled and "1" or "0")
    if not ok then return false end

    self.db.performance.cpuProfilingRequested = enabled and true or false
    self:Print(self:T("CPU_RELOAD_REQUIRED"))
    return true
end

function CH:RefreshMemory()
    if type(UpdateAddOnMemoryUsage) == "function" then
        pcall(UpdateAddOnMemoryUsage)
    end

    local total = 0
    if self.addonList then
        for _, addon in ipairs(self.addonList) do
            addon.memoryKB = self:GetAddOnMemoryKB(addon.index)
            total = total + (addon.memoryKB or 0)
        end
    end

    self.totalMemoryKB = total
    return total
end

function CH:RefreshCPU()
    if not self:IsCPUProfilingEnabled() then
        self.cpuPercent = {}
        self._cpuPrev = nil
        self._cpuPrevTime = nil
        return false
    end

    if type(UpdateAddOnCPUUsage) ~= "function" or type(GetAddOnCPUUsage) ~= "function" then
        self.cpuPercent = {}
        return false
    end

    pcall(UpdateAddOnCPUUsage)

    local now = GetTime and GetTime() or 0
    local current = {}

    if self.addonList then
        for _, addon in ipairs(self.addonList) do
            local ok, value = pcall(GetAddOnCPUUsage, addon.index)
            current[addon.name] = ok and tonumber(value) or 0
        end
    end

    self.cpuPercent = self.cpuPercent or {}

    if self._cpuPrev and self._cpuPrevTime and now > self._cpuPrevTime then
        local elapsedMs = (now - self._cpuPrevTime) * 1000
        for name, value in pairs(current) do
            local previous = self._cpuPrev[name] or value
            local delta = math.max(0, value - previous)
            self.cpuPercent[name] = elapsedMs > 0 and (delta / elapsedMs) * 100 or 0
        end
    end

    self._cpuPrev = current
    self._cpuPrevTime = now
    return true
end

function CH:GetCPUPercent(name)
    return self.cpuPercent and self.cpuPercent[name] or nil
end

function CH:RefreshData()
    self:BuildAddonList()
    self:RefreshMemory()
    self:RefreshCPU()
    if self.RefreshOptions then self:RefreshOptions() end
    if self.RefreshFlyout then self:RefreshFlyout() end
end

function CH:InitializePerformance()
    self.cpuPercent = {}
    self:RefreshMemory()
end
