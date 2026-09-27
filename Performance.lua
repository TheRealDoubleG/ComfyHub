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

function CH:GetAddOnCPUUsageCompat(addon)
    local getter = GetAddOnCPUUsage
    if C_AddOns and type(C_AddOns.GetAddOnCPUUsage) == "function" then
        getter = C_AddOns.GetAddOnCPUUsage
    end
    if type(getter) ~= "function" then return nil end

    local candidates = {addon and addon.name, addon and addon.index}
    for _, candidate in ipairs(candidates) do
        if candidate ~= nil then
            local ok, value = pcall(getter, candidate)
            value = ok and tonumber(value) or nil
            if value ~= nil then return value end
        end
    end
    return nil
end

function CH:RefreshCPU()
    if not self:IsCPUProfilingEnabled() then
        self.cpuPercent = {}
        self._cpuPrev = nil
        self._cpuPrevTime = nil
        self.cpuSampleState = "disabled"
        return false
    end

    local updater = UpdateAddOnCPUUsage
    if C_AddOns and type(C_AddOns.UpdateAddOnCPUUsage) == "function" then
        updater = C_AddOns.UpdateAddOnCPUUsage
    end

    local getterAvailable = type(GetAddOnCPUUsage) == "function"
        or (C_AddOns and type(C_AddOns.GetAddOnCPUUsage) == "function")

    if not getterAvailable then
        self.cpuPercent = {}
        self.cpuSampleState = "unavailable"
        return false
    end

    if type(updater) == "function" then pcall(updater) end

    local now
    if type(GetTimePreciseSec) == "function" then
        local ok, value = pcall(GetTimePreciseSec)
        now = ok and tonumber(value) or nil
    end
    if not now and type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        now = ok and tonumber(value) or nil
    end
    now = now or 0

    local current = {}
    local anyValue = false

    if self.addonList then
        for _, addon in ipairs(self.addonList) do
            local value = self:GetAddOnCPUUsageCompat(addon)
            if value ~= nil then
                current[addon.name] = value
                anyValue = true
            end
        end
    end

    if not anyValue then
        self.cpuPercent = {}
        self.cpuSampleState = "unavailable"
        return false
    end

    self.cpuPercent = self.cpuPercent or {}

    if self._cpuPrev and self._cpuPrevTime and now > self._cpuPrevTime then
        local elapsedMs = (now - self._cpuPrevTime) * 1000
        for name, value in pairs(current) do
            local previous = self._cpuPrev[name]
            if previous ~= nil then
                local delta = math.max(0, value - previous)
                self.cpuPercent[name] = elapsedMs > 0 and (delta / elapsedMs) * 100 or 0
            end
        end
        self.cpuSampleState = "ready"
    else
        self.cpuSampleState = "sampling"
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
