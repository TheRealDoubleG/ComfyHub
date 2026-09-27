ComfyHub = ComfyHub or {}
local CH = ComfyHub

local METRIC_KEYS = {
    session = {"SessionAverageTime", 0},
    recent = {"RecentAverageTime", 1},
    encounter = {"EncounterAverageTime", 2},
    current = {"LastTime", 3},
    peak = {"PeakTime", 4},
}

local function Now()
    if type(GetTimePreciseSec) == "function" then local ok,v=pcall(GetTimePreciseSec); if ok and tonumber(v) then return tonumber(v) end end
    if type(GetTime) == "function" then local ok,v=pcall(GetTime); if ok and tonumber(v) then return tonumber(v) end end
    return 0
end

local function MetricEnum(key)
    local spec=METRIC_KEYS[key]
    if not spec then return nil end
    if Enum and Enum.AddOnProfilerMetric and Enum.AddOnProfilerMetric[spec[1]] ~= nil then
        return Enum.AddOnProfilerMetric[spec[1]]
    end
    return spec[2]
end

function CH:HasNativeProfiler()
    if not C_AddOnProfiler or type(C_AddOnProfiler.GetAddOnMetric) ~= "function" then return false end
    if type(C_AddOnProfiler.IsEnabled) == "function" then
        local ok,enabled=pcall(C_AddOnProfiler.IsEnabled)
        if ok and enabled == false then return false end
    end
    return true
end

function CH:IsCPUProfilingEnabled()
    return self:HasNativeProfiler()
end

function CH:SetCPUProfilingRequested()
    self:Print(self:T("CPU_NATIVE_NO_TOGGLE"))
    return false
end

function CH:GetMemoryUpdateInterval()
    local value = self.db and self.db.performance and tonumber(self.db.performance.memoryUpdateInterval)
    if value == nil then return 10 end
    if value < 0 then return 0 end
    return value
end

function CH:SetMemoryUpdateInterval(value)
    if not self.db then return end
    self.db.performance = self.db.performance or {}
    self.db.performance.memoryUpdateInterval = math.max(0, tonumber(value) or 0)
    self._lastMemoryUpdate = nil
    self:RefreshMemory(true)
    if self.RefreshOptions then self:RefreshOptions() end
end

function CH:RefreshMemory(force)
    local interval=self:GetMemoryUpdateInterval()
    local now=Now()
    if not force then
        if interval<=0 then return self.totalMemoryKB or 0 end
        if self._lastMemoryUpdate and now < self._lastMemoryUpdate + interval then return self.totalMemoryKB or 0 end
    end
    self._lastMemoryUpdate=now
    if type(UpdateAddOnMemoryUsage)=="function" then pcall(UpdateAddOnMemoryUsage) end
    local total=0
    for _,addon in ipairs(self.addonList or {}) do
        addon.memoryKB=self:GetAddOnMemoryKB(addon.index)
        total=total+(addon.memoryKB or 0)
    end
    self.totalMemoryKB=total
    return total
end

function CH:GetNativeMetric(addonName,key)
    if not self:HasNativeProfiler() or not addonName then return nil end
    local metric=MetricEnum(key)
    if metric==nil then return nil end
    local ok,value=pcall(C_AddOnProfiler.GetAddOnMetric,addonName,metric)
    value=ok and tonumber(value) or nil
    return value
end

function CH:RefreshCPU()
    self.cpuMetrics={}
    if not self:HasNativeProfiler() then
        self.cpuSampleState="unavailable"
        return false
    end
    local any=false
    for _,addon in ipairs(self.addonList or {}) do
        if addon.loaded then
            local m={
                current=self:GetNativeMetric(addon.name,"current"),
                recent=self:GetNativeMetric(addon.name,"recent"),
                session=self:GetNativeMetric(addon.name,"session"),
                peak=self:GetNativeMetric(addon.name,"peak"),
                encounter=self:GetNativeMetric(addon.name,"encounter"),
            }
            self.cpuMetrics[addon.name]=m
            if m.current~=nil or m.recent~=nil or m.peak~=nil then any=true end
        end
    end
    self.cpuSampleState=any and "native" or "unavailable"
    return any
end

function CH:GetCPUMetric(name,key)
    local m=self.cpuMetrics and self.cpuMetrics[name]
    return m and m[key] or nil
end

-- Compatibility helper used by the compact Addons/preview UI. The value is
-- native profiler time in milliseconds for the most recent tick, not percent.
function CH:GetCPUPercent(name)
    return self:GetCPUMetric(name,"current")
end

function CH:RefreshData(forceMemory)
    self:BuildAddonList()
    self:RefreshMemory(forceMemory and true or false)
    self:RefreshCPU()
    if self.RefreshOptions then self:RefreshOptions() end
    if self.RefreshFlyout then self:RefreshFlyout() end
end

function CH:InitializePerformance()
    self.cpuMetrics={}
    self._lastMemoryUpdate=nil
    self:RefreshMemory(true)
    self:RefreshCPU()
end
