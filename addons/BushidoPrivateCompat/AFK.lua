--[[
	BANZAI - AFK.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	1.0.0: the Banzai AFK screen. When the game flags the character AFK (out of
	combat, not in a pet battle, no cinematic), the HUD is hidden (UIParent,
	the same way ElvUI's own AFK screen and the game's Alt+Z do it) and a
	screen of its own shows:

	  background  dark translucent green-black glass, a soft green light from
	              the left and a purple one from the right
	  centre      the character itself (a PlayerModel of 'player': current gear),
	              turning slowly through a full circle (OnUpdate only while the
	              screen shows); without the model, the Fabled class art
	  bottom band the Fabled class art, name, class / spec, level and zone on the
	              left; BANZAI, UI BY HARDKORH and the version in the middle; the
	              Banzai tree on the right; a thin green -> purple edge on top

	It ends - the HUD back exactly as it was (shown again only if this screen
	hid it; no alpha is ever changed) - on any key or click, when the AFK flag
	clears (moving, acting), and at once on combat (before the lockdown starts),
	a loading screen, leaving the world, a queue pop, a ready check, an
	invite, a summon, a duel, a trade, a pet battle or a cinematic. If anything
	else shows the HUD (Escape), the screen goes. A key press while still AFK:
	the screen comes back after a minute if the character is still AFK.
	Reloads and disconnects rebuild the UI with the HUD shown. ElvUI's AFK
	screen is off while this one is on (BushidoPrivateRestore writes it).

	PREVIEW (BANZAI > AFK SCREEN): the same screen, labelled PREVIEW, without
	being AFK; any key or click ends it, combat too. No camera is moved, no
	game setting is changed.

	1.3.1: the name and the class / spec line in the Banzai display font (Want
	Coffee); behaviour unchanged.
]]
local _, ns = ...
local Theme = ns.Theme

local AFK = {}
ns.AFK = AFK
if ns.Compat then ns.Compat.AFK = AFK end -- the options page reaches it through BanzaiCompat

AFK.MODEL = { w = 620, h = 760, y = 40, camera = 1.12 } -- the model frame, centred (UIParent units)
AFK.BAND = 150       -- bottom band
AFK.CIRCLE = 84      -- Fabled class art in the band
AFK.BIG_CIRCLE = 230 -- in the model's place when the model is off
AFK.SPEC_SIZE = 18   -- 1.3.1: the class / spec line in the display font (1.0.0 - 1.3.0: the small font, 15)
AFK.RECHECK = 60     -- seconds: back after a key press if still AFK
AFK.STRATA = 'FULLSCREEN_DIALOG'
-- what ends the screen at once
AFK.EXIT_EVENTS = { 'PLAYER_REGEN_DISABLED', 'LOADING_SCREEN_ENABLED', 'PLAYER_LEAVING_WORLD', 'LFG_PROPOSAL_SHOW', 'UPDATE_BATTLEFIELD_STATUS',
	'READY_CHECK', 'LFG_ROLE_CHECK_SHOW', 'PVP_ROLE_CHECK_UPDATED', 'RESURRECT_REQUEST', 'PARTY_INVITE_REQUEST', 'CONFIRM_SUMMON', 'DUEL_REQUESTED',
	'TRADE_SHOW', 'PET_BATTLE_OPENING_START', 'CINEMATIC_START', 'PLAY_MOVIE' }
-- keys that never end it on their own (alt-tab back into the game, modifiers)
AFK.IGNORED_KEYS = { LALT = true, RALT = true, LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true, LMETA = true, RMETA = true }

local LOGO = Theme.MEDIA .. 'BanzaiLogo'
local BONSAI = Theme.MEDIA .. 'BanzaiBonsai'

local state = { shown = false, preview = false, hidUI = false, facing = 0, token = 0 }
AFK.state = state

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Safe(value)
	if IsSecret(value) then return nil end
	return value
end

local function Call(fn, ...)
	if type(fn) ~= 'function' then return nil end
	local ok, a, b, c, d = pcall(fn, ...)
	if not ok then return nil end
	return Safe(a), Safe(b), Safe(c), Safe(d)
end

local function Active()
	return ns.Compat and ns.Compat.Active and ns.Compat.Active() or false
end

local function Text(parent, size, font, layer)
	local fs = parent:CreateFontString(nil, layer or 'OVERLAY')
	fs:SetFont(font or Theme:SmallFont(), size, 'OUTLINE')
	fs:SetShadowOffset(1, -1)
	return fs
end

local function Solid(parent, layer, sublevel)
	local t = parent:CreateTexture(nil, layer or 'BACKGROUND', nil, sublevel)
	t:SetTexture(Theme.WHITE)
	return t
end

---------------------------------------------------------------------------
-- The screen (built once, on first use)
---------------------------------------------------------------------------
function AFK:Build()
	if self.frame then return self.frame end
	local f = CreateFrame('Frame', 'BanzaiAFKScreen') -- no parent: it stays up while the HUD (UIParent) is hidden
	f:SetFrameStrata(self.STRATA)
	f:SetAllPoints(UIParent)
	f:EnableMouse(true)
	f:Hide()

	f.glass = Solid(f, 'BACKGROUND', -8)
	f.glass:SetAllPoints()
	f.left = Solid(f, 'BACKGROUND', -6)
	f.left:SetPoint('TOPLEFT')
	f.left:SetPoint('BOTTOMRIGHT', f, 'BOTTOM', 0, 0)
	f.right = Solid(f, 'BACKGROUND', -6)
	f.right:SetPoint('TOPRIGHT')
	f.right:SetPoint('BOTTOMLEFT', f, 'BOTTOM', 0, 0)

	local model = CreateFrame('PlayerModel', nil, f)
	model:SetSize(self.MODEL.w, self.MODEL.h)
	model:SetPoint('CENTER', f, 'CENTER', 0, self.MODEL.y)
	f.model = model
	if ns.Identity and ns.Identity.Circle then
		f.bigArt = ns.Identity.Circle(f, self.BIG_CIRCLE)
		f.bigArt:SetPoint('CENTER', f, 'CENTER', 0, self.MODEL.y)
	end

	-- bottom band
	local band = CreateFrame('Frame', nil, f)
	band:SetPoint('BOTTOMLEFT')
	band:SetPoint('BOTTOMRIGHT')
	band:SetHeight(self.BAND)
	band.glass = Solid(band, 'BACKGROUND', -4)
	band.glass:SetAllPoints()
	band.edges = {}
	for i = 1, 8 do
		local e = Solid(band, 'BORDER')
		e:SetHeight(2)
		band.edges[i] = e
	end
	f.band = band

	if ns.Identity and ns.Identity.Circle then
		f.art = ns.Identity.Circle(band, self.CIRCLE)
		f.art:SetPoint('LEFT', band, 'LEFT', 56, 0)
	end
	f.name = Text(band, 26, Theme:DisplayFont())
	f.name:SetPoint('BOTTOMLEFT', band, 'LEFT', 56 + self.CIRCLE + 18, 8)
	f.spec = Text(band, 15)
	f.spec:SetPoint('TOPLEFT', f.name, 'BOTTOMLEFT', 0, -6)
	f.where = Text(band, 13)
	f.where:SetPoint('TOPLEFT', f.spec, 'BOTTOMLEFT', 0, -5)

	f.logo = band:CreateTexture(nil, 'ARTWORK')
	f.logo:SetTexture(LOGO)
	f.logo:SetSize(320, 80)
	f.logo:SetPoint('CENTER', band, 'CENTER', 0, 16)
	f.brand = Text(band, 12)
	f.brand:SetPoint('TOP', f.logo, 'BOTTOM', 0, -2)
	f.version = Text(band, 10)
	f.version:SetPoint('TOP', f.brand, 'BOTTOM', 0, -4)

	f.tree = band:CreateTexture(nil, 'ARTWORK')
	f.tree:SetTexture(BONSAI)
	f.tree:SetSize(124, 124)
	f.tree:SetPoint('RIGHT', band, 'RIGHT', -56, 8)

	f.label = Text(f, 13)
	f.label:SetPoint('TOP', f, 'TOP', 0, -28)

	f:SetScript('OnUpdate', function(_, elapsed) AFK:OnUpdate(elapsed) end)
	f:SetScript('OnKeyDown', function(_, key) AFK:OnKey(key) end)
	f:SetScript('OnMouseDown', function() AFK:Close('click') end)
	self.frame = f
	return f
end

-- texts, art and colours for this character and the current settings
function AFK:Fill(preview)
	local f = self:Build()
	local db = Theme:DB()
	local brand = math.max(0.3, math.min(1, tonumber(db.afkBrand) or 1))
	local alpha = math.max(0.4, math.min(0.95, tonumber(db.afkOpacity) or 0.8))
	Theme:Glass(f.glass, alpha)
	local green, purple = Theme.COLORS.emerald, Theme.COLORS.purple
	Theme:Gradient(f.left, 'HORIZONTAL', green, green, 0.16 * brand, 0)
	Theme:Gradient(f.right, 'HORIZONTAL', purple, purple, 0, 0.16 * brand)
	Theme:Glass(f.band.glass, math.min(1, alpha + 0.1))
	local width = (UIParent.GetWidth and UIParent:GetWidth()) or 1920
	local stops = Theme:Stops('h')
	local strips = #f.band.edges
	for i, e in ipairs(f.band.edges) do
		e:ClearAllPoints()
		e:SetPoint('TOPLEFT', f.band, 'TOPLEFT', (i - 1) * width / strips, 0)
		e:SetWidth(width / strips + 0.5)
		Theme:Gradient(e, 'HORIZONTAL', Theme:ColorAt(stops, (i - 1) / strips), Theme:ColorAt(stops, i / strips), 0.9 * brand, 0.9 * brand)
	end

	local name = Call(UnitName, 'player')
	local className, token = Call(UnitClass, 'player')
	local index = Call(GetSpecialization)
	local specID, specName
	if index then specID, specName = Call(GetSpecializationInfo, index) end
	local level = Call(UnitLevel, 'player')
	local zone = Call(GetZoneText)
	local classColor = (token and Theme:ClassColor(token)) or { 1, 1, 1 }

	-- 1.3.1: name and class / spec in the Banzai display font, the level / zone line in the small font
	Theme:SetDisplayFont(f.name, Theme:DisplaySize(26), 'OUTLINE', name)
	Theme:SetDisplayFont(f.spec, Theme:DisplaySize(AFK.SPEC_SIZE), 'OUTLINE', (className or '') .. (specName or ''))
	f.name:SetText(name or '')
	f.name:SetTextColor(classColor[1], classColor[2], classColor[3])
	f.name:SetShown(db.afkName ~= false)
	local spec = {}
	if className then spec[#spec + 1] = '|cff' .. Theme:Hex(classColor) .. string.upper(className) .. '|r' end
	if specName then spec[#spec + 1] = Theme:GradientText(string.upper(specName), Theme.COLORS.lime, Theme.COLORS.emerald) end
	f.spec:SetText(table.concat(spec, '|cff8c919a  -  |r'))
	f.spec:SetShown(db.afkSpec ~= false)
	local where = {}
	if db.afkLevel ~= false and level then where[#where + 1] = 'LEVEL ' .. level end
	if db.afkZone ~= false and zone and zone ~= '' then where[#where + 1] = string.upper(zone) end
	f.where:SetText('|cff9aa0aa' .. table.concat(where, '   ') .. '|r')
	f.where:SetShown(#where > 0)

	f.brand:SetText(Theme:GradientText('UI BY HARDKORH', Theme.COLORS.lime, Theme.COLORS.violet))
	f.version:SetText('|cff8c919aBANZAI ' .. tostring(Theme.VERSION) .. '|r')
	f.logo:SetAlpha(brand)
	f.tree:SetAlpha(0.9 * brand)
	f.brand:SetAlpha(math.max(0.6, brand))

	local identity = ns.Identity
	if f.art and identity and identity.Paint then identity.Paint(f.art, token, nil) end
	local useModel = db.afkModel ~= false
	f.model:SetShown(useModel)
	if f.bigArt then
		f.bigArt:SetShown(not useModel)
		if not useModel and identity and identity.Paint then identity.Paint(f.bigArt, token, nil) end
	end
	if preview then
		f.label:SetText(Theme:GradientText('PREVIEW', Theme.COLORS.lime, Theme.COLORS.violet) .. '|cff9aa0aa  -  AFK SCREEN  -  ANY KEY OR CLICK CLOSES IT|r')
	else
		f.label:SetText('|cff9aa0aa' .. string.upper(_G.AFK or 'AFK') .. '|r')
	end
	return f
end

-- the model: the player as they look now, facing the camera, then turning
function AFK:StartModel()
	local m = self.frame and self.frame.model
	if not (m and m:IsShown()) then return end
	pcall(m.SetUnit, m, 'player')
	if m.SetPortraitZoom then pcall(m.SetPortraitZoom, m, 0) end
	if m.SetCamDistanceScale then pcall(m.SetCamDistanceScale, m, self.MODEL.camera) end
	if m.SetPosition then pcall(m.SetPosition, m, 0, 0, 0) end
	state.facing = 0
	if m.SetFacing then pcall(m.SetFacing, m, 0) end
end

function AFK:OnUpdate(elapsed)
	if not state.shown then return end
	-- the HUD came back from somewhere else (Escape, Alt+Z): this screen goes
	if state.hidUI and UIParent:IsShown() then
		state.hidUI = false
		return self:Close('ui shown')
	end
	local db = Theme:DB()
	local m = self.frame.model
	if db.afkRotate ~= false and m:IsShown() and m.SetFacing then
		local turn = math.max(8, math.min(60, tonumber(db.afkTurn) or 24))
		state.facing = (state.facing + (elapsed or 0) * 2 * math.pi / turn) % (2 * math.pi)
		m:SetFacing(state.facing)
	end
end

function AFK:OnKey(key)
	if self.IGNORED_KEYS[key] then return end
	if key == 'PRINTSCREEN' then
		if _G.Screenshot then pcall(_G.Screenshot) end
		return
	end
	self:Close('key')
end

---------------------------------------------------------------------------
-- Show / close
---------------------------------------------------------------------------
-- can the screen show now?
function AFK:Allowed()
	if InCombatLockdown() then return false end
	if C_PetBattles and C_PetBattles.IsInBattle and Call(C_PetBattles.IsInBattle) then return false end
	local cinematic, movie = _G.CinematicFrame, _G.MovieFrame
	if (cinematic and cinematic.IsShown and cinematic:IsShown()) or (movie and movie.IsShown and movie:IsShown()) then return false end
	return true
end

function AFK:Open(preview)
	if state.shown or not self:Allowed() then return false end
	local f = self:Fill(preview)
	state.shown, state.preview = true, preview and true or false
	-- the BANZAI settings window goes with the HUD (ElvUI closes it when it hides): the preview reopens it after
	state.reopen = preview and self.SettingsOpen() or false
	f:SetScale((UIParent.GetScale and UIParent:GetScale()) or 1)
	f:Show()
	f:EnableKeyboard(true)
	if UIParent:IsShown() then
		UIParent:Hide()
		state.hidUI = true
	end
	self:StartModel()
	return true
end

-- the HUD back exactly as it was: shown again only if this screen hid it
function AFK:Close(reason)
	if not state.shown then return false end
	state.shown, state.preview = false, false
	local f = self.frame
	if f then
		f:EnableKeyboard(false)
		f:Hide()
		if f.model and f.model.ClearModel then pcall(f.model.ClearModel, f.model) end
	end
	if state.hidUI then
		state.hidUI = false
		if not UIParent:IsShown() then UIParent:Show() end
	end
	self.lastReason = reason
	local reopen = state.reopen
	state.reopen = false
	if reopen and (reason == 'key' or reason == 'click') and not InCombatLockdown() and type(_G.BanzaiOpenSettings) == 'function' then
		pcall(_G.BanzaiOpenSettings, 'afk')
		return true
	end
	-- a key or a click while still AFK: back after a minute if still AFK
	if reason == 'key' or reason == 'click' then
		state.token = state.token + 1
		local token = state.token
		if C_Timer and C_Timer.After then C_Timer.After(self.RECHECK, function() if token == state.token then AFK:Check() end end) end
	end
	return true
end

-- the ElvUI options window is open (the preview was started from it)
function AFK.SettingsOpen()
	local E = _G.ElvUI and _G.ElvUI[1]
	local ACD = E and E.Libs and E.Libs.AceConfigDialog
	return (ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI) and true or false
end

function AFK:Preview()
	if InCombatLockdown() then
		print('|cff00ccffBanzai|r: the AFK screen preview is not available in combat.')
		return false
	end
	return self:Open(true)
end

function AFK:IsShown() return state.shown end

-- the game's AFK flag decides (Banzai AFK on, the Banzai profile in use)
function AFK:Check()
	if state.preview then return false end
	local afk = Call(UnitIsAFK, 'player') == true
	if afk and Theme:DB().afk ~= false and Active() then return self:Open(false) end
	if not afk then return self:Close('back') end
	return false
end

-- switched off in the settings: a screen that is up goes
function AFK:Refresh()
	if state.shown and not state.preview and (Theme:DB().afk == false or not Active()) then self:Close('off') end
end

local EXIT = {}
for _, event in ipairs(AFK.EXIT_EVENTS) do EXIT[event] = true end

function AFK:OnEvent(event, arg1)
	if event == 'PLAYER_FLAGS_CHANGED' then
		if arg1 == 'player' then state.token = state.token + 1 self:Check() end
	elseif event == 'PLAYER_REGEN_ENABLED' then
		self:Check() -- went AFK during combat: the screen shows now
	elseif event == 'UPDATE_BATTLEFIELD_STATUS' then
		local status = arg1 and GetBattlefieldStatus and Call(GetBattlefieldStatus, arg1)
		if status == 'confirm' then self:Close(event) end
	elseif EXIT[event] then
		self:Close(event)
	end
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_FLAGS_CHANGED')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
for _, event in ipairs(AFK.EXIT_EVENTS) do pcall(events.RegisterEvent, events, event) end
events:SetScript('OnEvent', function(_, event, arg1) AFK:OnEvent(event, arg1) end)
AFK.events = events
