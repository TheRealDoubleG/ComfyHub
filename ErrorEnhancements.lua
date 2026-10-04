ComfyHub = ComfyHub or {}
local CH = ComfyHub

CH.version = "0.21"
CH.buildDate = "04.10.2026"
CH.luaErrors = CH.luaErrors or {}

local function Now()
    if type(GetTime)=="function" then local ok,v=pcall(GetTime); if ok and tonumber(v) then return tonumber(v) end end
    return 0
end

local function EnsureDefaults()
    if not CH.db then return end
    CH.db.debug=CH.db.debug or {}
    if CH.db.debug.maxLuaErrors==nil then CH.db.debug.maxLuaErrors=50 end
    if CH.db.debug.errorMode==nil then CH.db.debug.errorMode="comfy" end
end

local originalInitializeDB=CH.InitializeDB
function CH:InitializeDB(...)
    local result
    if originalInitializeDB then result=originalInitializeDB(self,...) end
    EnsureDefaults(); return result
end

local function ParseError(message)
    message=tostring(message or "")
    local addon,file,line,summary=message:match("Interface[/\\]AddOns[/\\]([^/\\]+)[/\\]([^:\n]+):(%d+):%s*([^\n]+)")
    if not addon then addon,file,line,summary=message:match("AddOns[/\\]([^/\\]+)[/\\]([^:\n]+):(%d+):%s*([^\n]+)") end
    summary=summary or message:match("([^\n]+)") or message
    return addon,file,tonumber(line),summary
end

local function Fingerprint(message)
    local addon,file,line,summary=ParseError(message)
    if addon then return table.concat({addon,file or "?",tostring(line or 0),summary or ""},"|") end
    return tostring(message or "")
end

function CH:IsComfyError(message)
    local addon=ParseError(message)
    return type(addon)=="string" and addon:find("^Comfy")~=nil
end

function CH:GetUnreadLuaErrorCount()
    local n=0
    for _,entry in ipairs(self.luaErrors or {}) do if entry.unread then n=n+1 end end
    return n
end

function CH:CaptureLuaError(message)
    EnsureDefaults(); message=tostring(message or ""); if message=="" then return end
    local key=Fingerprint(message); local now=Now(); local found
    for _,entry in ipairs(self.luaErrors) do if entry.key==key then found=entry break end end
    if found then
        found.count=(tonumber(found.count) or 1)+1; found.lastAt=now; found.message=message; found.unread=true
    else
        local addon,file,line,summary=ParseError(message)
        self._luaErrorSerial=(self._luaErrorSerial or 0)+1
        found={index=self._luaErrorSerial,key=key,message=message,count=1,firstAt=now,lastAt=now,addon=addon,file=file,line=line,summary=summary,unread=true}
        self.luaErrors[#self.luaErrors+1]=found
    end
    local maxErrors=math.max(1,math.min(200,math.floor(tonumber(self.db.debug.maxLuaErrors) or 50)))
    while #self.luaErrors>maxErrors do table.remove(self.luaErrors,1) end
    if self.RefreshErrorIndicator then self:RefreshErrorIndicator() end
    if self.RefreshLuaErrorUI then self:RefreshLuaErrorUI(false) end
end

function CH:GetLuaErrorLogText()
    if not self.luaErrors or #self.luaErrors==0 then return self:T("LUA_NO_ERRORS") end
    local blocks={}
    table.sort(self.luaErrors,function(a,b) return (tonumber(a.lastAt) or 0)>(tonumber(b.lastAt) or 0) end)
    for _,entry in ipairs(self.luaErrors) do
        local head
        if entry.addon then head=string.format("===== %s · %s:%s · %dx =====",entry.addon,tostring(entry.file or "?"),tostring(entry.line or "?"),tonumber(entry.count) or 1)
        else head=string.format("===== Lua Error #%d · %dx =====",tonumber(entry.index) or 0,tonumber(entry.count) or 1) end
        blocks[#blocks+1]=head.."\n"..tostring(entry.message or "")
    end
    return table.concat(blocks,"\n\n")
end

function CH:MarkLuaErrorsRead()
    for _,entry in ipairs(self.luaErrors or {}) do entry.unread=false end
    self:RefreshErrorIndicator()
end

function CH:ClearLuaErrors()
    wipe(self.luaErrors); self._lastCapturedLuaError=nil; self._lastCapturedLuaErrorTime=nil
    if self.RefreshLuaErrorUI then self:RefreshLuaErrorUI(true) end
    if self.RefreshErrorIndicator then self:RefreshErrorIndicator() end
end

function CH:SetErrorMode(mode)
    EnsureDefaults(); if mode~="blizzard" and mode~="comfy" and mode~="silent" then return false end
    self.db.debug.errorMode=mode; self:InstallLuaErrorCapture(); if self.RefreshErrorModeUI then self:RefreshErrorModeUI() end; return true
end

function CH:InstallLuaErrorCapture()
    EnsureDefaults()
    if type(geterrorhandler)~="function" or type(seterrorhandler)~="function" then self.luaErrorCaptureAvailable=false; return false end
    local current=geterrorhandler()
    if current==self._luaErrorHandler then self.luaErrorCaptureAvailable=true; return true end
    local previous=current
    local wrapper
    wrapper=function(message)
        pcall(CH.CaptureLuaError,CH,message)
        local mode=CH.db and CH.db.debug and CH.db.debug.errorMode or "blizzard"
        local suppress=(mode=="silent") or (mode=="comfy" and CH:IsComfyError(message))
        if not suppress and type(previous)=="function" and previous~=wrapper then return previous(message) end
    end
    self._previousLuaErrorHandler=previous; self._luaErrorHandler=wrapper; seterrorhandler(wrapper); self.luaErrorCaptureAvailable=true; return true
end

local function CreateErrorButton()
    if CH.errorButton or not CH.flyoutBackdrop then return end
    local b=CreateFrame("Button","ComfyHubErrorButton",CH.flyoutBackdrop)
    b:SetSize(30,30); b:SetFrameStrata("DIALOG"); b:SetFrameLevel(21)
    b.bg=b:CreateTexture(nil,"BACKGROUND"); b.bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background"); b.bg:SetSize(23,23); b.bg:SetPoint("CENTER"); b.bg:SetAlpha(.75)
    b.icon=b:CreateTexture(nil,"ARTWORK"); b.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01"); b.icon:SetSize(22,22); b.icon:SetPoint("CENTER"); b.icon:SetTexCoord(.08,.92,.08,.92)
    b.border=b:CreateTexture(nil,"OVERLAY"); b.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder"); b.border:SetSize(48,48); b.border:SetPoint("TOPLEFT",0,0)
    b.badge=b:CreateFontString(nil,"OVERLAY","NumberFontNormalSmall"); b.badge:SetPoint("TOPRIGHT",2,3)
    b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight","ADD")
    b:RegisterForClicks("LeftButtonUp","RightButtonUp")
    b:SetScript("OnClick",function(_,button)
        if button=="RightButton" then CH:ClearLuaErrors() else CH:OpenOptions(); if CH.SelectOptionsTab then CH:SelectOptionsTab(4) end; CH:MarkLuaErrorsRead() end
    end)
    b:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_LEFT"); GameTooltip:AddLine("ComfyHub Fehler",1,.82,0)
        GameTooltip:AddDoubleLine("Fehlergruppen",tostring(#(CH.luaErrors or {})),1,1,1,1,1,1)
        GameTooltip:AddDoubleLine("Neu",tostring(CH:GetUnreadLuaErrorCount()),1,1,1,1,.25,.2)
        GameTooltip:AddLine("Linksklick: Fehlerliste",.7,.7,.7); GameTooltip:AddLine("Rechtsklick: leeren",.7,.7,.7); GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    CH.errorButton=b; CH:RefreshErrorIndicator()
end

function CH:RefreshErrorIndicator()
    if not self.errorButton then return end
    local unread=self:GetUnreadLuaErrorCount(); local total=#(self.luaErrors or {})
    if unread>0 then self.errorButton.icon:SetVertexColor(1,.22,.18); self.errorButton.border:SetVertexColor(1,.15,.1,1)
    elseif total>0 then self.errorButton.icon:SetVertexColor(1,.82,.2); self.errorButton.border:SetVertexColor(.75,.55,.2,1)
    else self.errorButton.icon:SetVertexColor(.55,.55,.55); self.errorButton.border:SetVertexColor(.45,.45,.45,1) end
    self.errorButton.badge:SetText(unread>0 and tostring(unread) or "")
end

local originalCreateFlyout=CH.CreateFlyout
function CH:CreateFlyout(...)
    if originalCreateFlyout then originalCreateFlyout(self,...) end
    CreateErrorButton()
end

function CH:PositionFlyoutBackdrop()
    local backdrop=self.flyoutBackdrop
    if not backdrop or not Minimap then return end
    backdrop:ClearAllPoints()
    -- Fixed top-right anchor: panel grows from the minimap toward the left.
    backdrop:SetPoint("TOPRIGHT",Minimap,"TOPLEFT",-8,0)
end

local originalRefreshFlyout=CH.RefreshFlyout
function CH:RefreshFlyout(...)
    if originalRefreshFlyout then originalRefreshFlyout(self,...) end
    CreateErrorButton()
    if not self.errorButton or not self.flyoutBackdrop then return end
    if not self:IsMinimapBundlingActive() or not self.flyoutShown then self.errorButton:Hide(); return end
    local slot=0
    for _,button in ipairs(self.flyoutButtons or {}) do if button:IsShown() then slot=slot+1 end end
    slot=slot+1; local columns=4; local size=30; local gap=4; local pad=6
    local col=(slot-1)%columns; local row=math.floor((slot-1)/columns)
    self.errorButton:ClearAllPoints(); self.errorButton:SetPoint("TOPLEFT",self.flyoutBackdrop,"TOPLEFT",pad+col*(size+gap),-(pad+row*(size+gap))); self.errorButton:Show()
    local cols=math.min(columns,slot); local rows=math.ceil(slot/columns)
    self.flyoutBackdrop:SetSize(pad*2+cols*size+math.max(0,cols-1)*gap,pad*2+rows*size+math.max(0,rows-1)*gap)
    self:PositionFlyoutBackdrop(); self.flyoutBackdrop:Show(); self:RefreshErrorIndicator()
end

function CH:RefreshErrorModeUI()
    if not self.errorModeButtons then return end
    local mode=self.db and self.db.debug and self.db.debug.errorMode or "blizzard"
    for key,b in pairs(self.errorModeButtons) do
        if b.LockHighlight then if key==mode then b:LockHighlight() else b:UnlockHighlight() end end
    end
    if self.errorModeText then
        local text=mode=="blizzard" and "Blizzard: normales Fehlerverhalten" or mode=="comfy" and "Comfy Silent: Comfy-Fehler nur im Hub" or "Alles Silent: Fehler nur im Hub"
        self.errorModeText:SetText(text)
    end
end

local originalInitializeOptions=CH.InitializeOptions
function CH:InitializeOptions(...)
    if originalInitializeOptions then originalInitializeOptions(self,...) end
    if not self.optionsFrame or self.__errorModeOptionsBuilt then return end
    self.__errorModeOptionsBuilt=true
    local page=self.optionsFrame.pages and self.optionsFrame.pages[4]; if not page then return end
    local title=page:CreateFontString(nil,"ARTWORK","GameFontNormal"); title:SetPoint("TOPLEFT",390,-50); title:SetText("Fehlerbehandlung")
    self.errorModeButtons={}
    local defs={{"Blizzard","blizzard"},{"Comfy Silent","comfy"},{"Alles Silent","silent"}}
    for i,d in ipairs(defs) do
        local b=CreateFrame("Button",nil,page,"UIPanelButtonTemplate"); b:SetSize(105,24); b:SetPoint("TOPLEFT",390+(i-1)*110,-76); b:SetText(d[1]); b:SetScript("OnClick",function() CH:SetErrorMode(d[2]) end); self.errorModeButtons[d[2]]=b
    end
    local info=page:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); info:SetPoint("TOPLEFT",390,-110); info:SetWidth(335); info:SetJustifyH("LEFT"); info:SetText("Comfy Silent unterdrückt die normale Blizzard-Anzeige nur für Fehler aus Comfy*-Addons. Die Fehler bleiben im Hub sichtbar.")
    self.errorModeText=page:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); self.errorModeText:SetPoint("TOPLEFT",390,-157); self.errorModeText:SetWidth(335); self.errorModeText:SetJustifyH("LEFT")
    self:RefreshErrorModeUI()
end
