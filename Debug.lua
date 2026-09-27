ComfyHub = ComfyHub or {}
local CH = ComfyHub

CH.luaErrors = CH.luaErrors or {}

local function SafeGetTime()
    if type(GetTime) == "function" then
        local ok, value = pcall(GetTime)
        if ok and type(value) == "number" then return value end
    end
    return 0
end

function CH:IsLuaErrorsEnabled()
    if type(GetCVarBool) == "function" then
        local ok, value = pcall(GetCVarBool, "scriptErrors")
        if ok then return value and true or false end
    end

    if type(GetCVar) == "function" then
        local ok, value = pcall(GetCVar, "scriptErrors")
        if ok then return tostring(value) == "1" end
    end

    return false
end

function CH:SetLuaErrorsEnabled(enabled)
    if type(SetCVar) ~= "function" then
        self:Print(self:T("LUA_ERRORS_UNAVAILABLE"))
        return false
    end

    local ok = pcall(SetCVar, "scriptErrors", enabled and "1" or "0")
    if not ok then
        self:Print(self:T("LUA_ERRORS_UNAVAILABLE"))
        return false
    end

    if self.RefreshLuaErrorUI then self:RefreshLuaErrorUI(true) end
    return true
end

function CH:CaptureLuaError(message)
    message = tostring(message or "")
    if message == "" then return end

    local now = SafeGetTime()
    if self._lastCapturedLuaError == message and self._lastCapturedLuaErrorTime and (now - self._lastCapturedLuaErrorTime) < 0.05 then
        return
    end

    self._lastCapturedLuaError = message
    self._lastCapturedLuaErrorTime = now

    local maxErrors = tonumber(self.db and self.db.debug and self.db.debug.maxLuaErrors) or 50
    maxErrors = math.max(1, math.min(200, math.floor(maxErrors)))

    table.insert(self.luaErrors, {
        index = (self._luaErrorSerial or 0) + 1,
        message = message,
    })
    self._luaErrorSerial = (self._luaErrorSerial or 0) + 1

    while #self.luaErrors > maxErrors do
        table.remove(self.luaErrors, 1)
    end
end

function CH:GetLuaErrorLogText()
    if not self.luaErrors or #self.luaErrors == 0 then
        return self:T("LUA_NO_ERRORS")
    end

    local blocks = {}
    for _, entry in ipairs(self.luaErrors) do
        blocks[#blocks + 1] = string.format("===== Lua Error #%d =====\n%s", tonumber(entry.index) or 0, tostring(entry.message or ""))
    end

    return table.concat(blocks, "\n\n")
end

function CH:ClearLuaErrors()
    wipe(self.luaErrors)
    self._lastCapturedLuaError = nil
    self._lastCapturedLuaErrorTime = nil
    if self.RefreshLuaErrorUI then self:RefreshLuaErrorUI(true) end
end

function CH:InstallLuaErrorCapture()
    if type(geterrorhandler) ~= "function" or type(seterrorhandler) ~= "function" then
        self.luaErrorCaptureAvailable = false
        return false
    end

    local current = geterrorhandler()
    if current == self._luaErrorHandler then
        self.luaErrorCaptureAvailable = true
        return true
    end

    local previous = current
    local wrapper
    wrapper = function(message)
        -- Never allow the logger itself to create a recursive error-handler loop.
        pcall(CH.CaptureLuaError, CH, message)
        if type(previous) == "function" and previous ~= wrapper then
            return previous(message)
        end
    end

    self._previousLuaErrorHandler = previous
    self._luaErrorHandler = wrapper
    seterrorhandler(wrapper)
    self.luaErrorCaptureAvailable = true
    return true
end

function CH:InitializeDebug()
    self.luaErrors = self.luaErrors or {}
    self.luaErrorCaptureAvailable = type(geterrorhandler) == "function" and type(seterrorhandler) == "function"
end
