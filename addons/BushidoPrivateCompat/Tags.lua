--[[
	BANZAI - Tags.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	ElvUI tags for the Banzai identity line (registered through ElvUI's own
	E:AddTag, so they appear in ElvUI's tag list and work in custom texts):

	  [banzai:spec:after]   " - BALANCE"   for the player line   NAME - SPEC
	  [banzai:spec:before]  "FROST - "     for the target line   SPEC - NAME
	  [banzai:spec]         "BALANCE"      1.0.0: the spec on its own line under the
	                                       name (the half-width Player / Target)

	Where the spec comes from (no spec is ever guessed):
	  the player   GetSpecialization / GetSpecializationInfo (the client's own data)
	  other players (0.5.1)  the game's inspect data: when a player is targeted or
	               focused, Banzai asks for it (NotifyInspect, only when the game
	               allows it: CanInspect, in range, out of combat, not while the
	               inspect window is open, at most once every 1.5 s), and on
	               INSPECT_READY reads GetInspectSpecialization for that GUID,
	               remembers it and redraws the line. Until then the line shows the
	               name alone. Second source: ElvUI's [spec] tag (it reads the spec
	               from the unit tooltip and checks it against the game's spec list).
	  NPCs         nothing: the line is the name alone

	The lines are redrawn (frame:UpdateTags, oUF's own call) a moment after the
	spec, the target or the focus changes and when inspect data arrives.

	The spec gets its own Banzai gradient, complementary to the class-coloured
	name: lime -> emerald, or violet -> purple for green classes.

	1.3.1 BANZAI SPLIT's own lines (Split.lua draws them under the Player /
	Target bars):
	  [banzai:split:name]   the name in the BANZAI green -> emerald -> violet ->
	                        purple gradient (a name the game keeps secret is
	                        handed on as it is, unread)
	  [banzai:split:spec]   the spec in the unit's class colour family, only when
	                        it is reliably known (the sources above); NPCs nothing
]]
local _, ns = ...
local Theme = ns.Theme

local Tags = {}
ns.Tags = Tags

local SEPARATOR = '|cff8c919a - |r'
local IDENTITY_FRAMES = { 'ElvUF_Player', 'ElvUF_Target', 'ElvUF_Focus' }
local INSPECT_UNITS = { 'target', 'focus' }
Tags.INSPECT_INTERVAL = 1.5

local inspected = {} -- [GUID] = spec name from the game's inspect data
local pending, lastRequest = nil, -math.huge

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Plain(value)
	if IsSecret(value) then return nil end
	return value
end

local function Call(fn, ...)
	if not fn then return nil end
	local ok, value = pcall(fn, ...)
	return ok and Plain(value) or nil
end

function Tags.PlayerSpec()
	-- 1.5.0-dev1 (WoW Forever): the leading talent tree's name (Flavor.lua); Retail: the chosen specialization
	local Flavor = ns.Flavor
	if Flavor and Flavor.IsForever() then
		local spec = Flavor.PlayerSpec()
		return spec and spec.name or nil
	end
	local index = GetSpecialization and Plain(GetSpecialization())
	if not index or not GetSpecializationInfo then return nil end
	local _, name = GetSpecializationInfo(index)
	return Plain(name)
end

local function IsPlayerUnit(unit)
	if unit == 'player' then return true end
	return Call(UnitIsUnit, unit, 'player') == true
end

local function IsOtherPlayer(unit)
	return Call(UnitIsPlayer, unit) == true and not IsPlayerUnit(unit)
end

-- the spec the game reported for this unit's GUID (inspect data)
function Tags.InspectedSpec(unit)
	local guid = Call(UnitGUID, unit)
	return guid and inspected[guid] or nil
end

-- ask the game for a targeted / focused player's inspect data (supported API,
-- throttled, never in combat or over the open inspect window)
function Tags.RequestInspect(unit)
	-- 1.5.0-dev1 (WoW Forever): the inspect "specialization" there is a starter ID, not the player's talent
	-- tree - nothing is asked for and nothing is shown for other players
	if ns.Flavor and not ns.Flavor.Has('inspectSpecialization') then return false end
	if not (NotifyInspect and CanInspect) or InCombatLockdown() then return false end
	if _G.InspectFrame and _G.InspectFrame.IsShown and _G.InspectFrame:IsShown() then return false end
	if not IsOtherPlayer(unit) then return false end
	local guid = Call(UnitGUID, unit)
	if not guid or inspected[guid] then return false end
	if Call(CanInspect, unit) ~= true then return false end
	local now = GetTime and GetTime() or 0
	if now - lastRequest < Tags.INSPECT_INTERVAL then return false end
	lastRequest, pending = now, guid
	pcall(NotifyInspect, unit)
	return true
end

function Tags.OnInspectReady(guid)
	guid = Plain(guid)
	if not guid or guid ~= pending then return false end
	pending = nil
	for _, unit in ipairs(INSPECT_UNITS) do
		if Call(UnitGUID, unit) == guid then
			local specID = Call(GetInspectSpecialization, unit)
			if type(specID) == 'number' and specID > 0 and GetSpecializationInfoByID then
				local _, name = GetSpecializationInfoByID(specID)
				name = Plain(name)
				if type(name) == 'string' and name ~= '' then inspected[guid] = name end
			end
			break
		end
	end
	if ClearInspectPlayer and not (_G.InspectFrame and _G.InspectFrame.IsShown and _G.InspectFrame:IsShown()) then pcall(ClearInspectPlayer) end
	Tags.UpdateFrames()
	return inspected[guid] ~= nil
end

function Tags.Spec(unit)
	if type(unit) ~= 'string' or IsSecret(unit) then return nil end
	local spec
	if IsPlayerUnit(unit) then
		spec = Tags.PlayerSpec()
	elseif IsOtherPlayer(unit) and not (ns.Flavor and not ns.Flavor.Has('inspectSpecialization')) then -- 1.5.0-dev1: not on WoW Forever (see RequestInspect)
		spec = Tags.InspectedSpec(unit)
		if not spec then
			local E = Engine()
			local methods = E and E.oUF and E.oUF.Tags and E.oUF.Tags.Methods
			spec = Call(methods and methods.spec, unit)
		end
	end
	if type(spec) ~= 'string' or spec == '' then return nil end
	return string.upper(spec)
end

-- lime -> emerald next to most class colours; violet -> purple next to green ones
function Tags.SpecColors(unit)
	local token
	if type(unit) == 'string' and not IsSecret(unit) and UnitClass then
		local ok, _, classToken = pcall(UnitClass, unit)
		if ok then token = Plain(classToken) end
	end
	local c = token and Theme:ClassColor(token)
	if c and c[2] > c[1] + 0.1 and c[2] > c[3] then
		return Theme.COLORS.violet, Theme.COLORS.purple
	end
	return Theme.COLORS.lime, Theme.COLORS.emerald
end

function Tags.SpecText(spec, unit)
	local from, to = Tags.SpecColors(unit)
	return Theme:GradientText(spec, from, to)
end

function Tags.After(unit)
	local spec = Tags.Spec(unit)
	if spec then return SEPARATOR .. Tags.SpecText(spec, unit) end
end

function Tags.Before(unit)
	local spec = Tags.Spec(unit)
	if spec then return Tags.SpecText(spec, unit) .. SEPARATOR end
end

-- 1.0.0: the spec alone (its own line under the name on the narrow frames)
function Tags.Alone(unit)
	local spec = Tags.Spec(unit)
	if spec then return Tags.SpecText(spec, unit) end
end

-- 1.3.1 BANZAI SPLIT's name line: the BANZAI gradient over the plain name; a hidden name passes through unread
function Tags.SplitName(unit)
	if type(unit) ~= 'string' or IsSecret(unit) or not UnitName then return nil end
	local ok, name = pcall(UnitName, unit)
	if not ok then return nil end
	if IsSecret(name) then return name end
	if type(name) ~= 'string' or name == '' then return nil end
	return Theme:RampText(string.upper(name), Theme.NAME_STOPS)
end

-- 1.3.1 BANZAI SPLIT's spec line: the reliably known spec in the unit's class family (nothing otherwise)
function Tags.SplitSpec(unit)
	local spec = Tags.Spec(unit)
	if not spec then return nil end
	local ok, _, token = pcall(UnitClass, unit)
	token = ok and Plain(token) or nil
	if type(token) ~= 'string' then return nil end
	return Theme:RampText(spec, Theme.RampLetters(Theme.Ramp(Theme:ClassColor(token))))
end

-- redraw the identity lines once the data is there
function Tags.UpdateFrames()
	for _, name in ipairs(IDENTITY_FRAMES) do
		local frame = _G[name]
		if frame and frame.UpdateTags then pcall(frame.UpdateTags, frame) end
	end
end

function Tags.Schedule()
	if not (C_Timer and C_Timer.After) then return Tags.UpdateFrames() end
	C_Timer.After(0.3, Tags.UpdateFrames)
	C_Timer.After(2, Tags.UpdateFrames)
end

function Tags.OnEvent(event, arg1)
	if event == 'INSPECT_READY' then
		Tags.OnInspectReady(arg1)
		return
	end
	if event == 'PLAYER_TARGET_CHANGED' then Tags.RequestInspect('target') end
	if event == 'PLAYER_FOCUS_CHANGED' then Tags.RequestInspect('focus') end
	Tags.Schedule()
end

local E = Engine()
if E and E.AddTag then
	local events = 'PLAYER_TALENT_UPDATE UNIT_NAME_UPDATE PLAYER_SPECIALIZATION_CHANGED'
	E:AddTag('banzai:spec:after', events, function(unit) return Tags.After(unit) end)
	E:AddTag('banzai:spec:before', events, function(unit) return Tags.Before(unit) end)
	E:AddTag('banzai:spec', events, function(unit) return Tags.Alone(unit) end)
	E:AddTag('banzai:split:name', 'UNIT_NAME_UPDATE', function(unit) return Tags.SplitName(unit) end) -- 1.3.1
	E:AddTag('banzai:split:spec', events, function(unit) return Tags.SplitSpec(unit) end)
	if E.AddTagInfo then
		E:AddTagInfo('banzai:spec:after', 'BANZAI', 'Player identity: " - SPEC" after the name, Banzai gradient. Nothing for units without a known specialization.')
		E:AddTagInfo('banzai:spec:before', 'BANZAI', 'Target identity: "SPEC - " before the name, Banzai gradient. Nothing for NPCs.')
		E:AddTagInfo('banzai:spec', 'BANZAI', 'The specialization alone, Banzai gradient (its own line under the name). Nothing for NPCs.')
		E:AddTagInfo('banzai:split:name', 'BANZAI', 'BANZAI SPLIT: the name in capitals, green -> emerald -> violet -> purple.')
		E:AddTagInfo('banzai:split:spec', 'BANZAI', 'BANZAI SPLIT: the specialization in the unit\'s class colour family. Nothing for NPCs or an unknown spec.')
	end
	Tags.registered = true
end

local updater = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'PLAYER_SPECIALIZATION_CHANGED', 'PLAYER_TALENT_UPDATE', 'PLAYER_TARGET_CHANGED', 'PLAYER_FOCUS_CHANGED', 'INSPECT_READY' }) do
	pcall(updater.RegisterEvent, updater, event)
end
updater:SetScript('OnEvent', function(_, event, arg1) Tags.OnEvent(event, arg1) end)
-- 1.5.0-dev1 (WoW Forever): the identity line names the leading talent tree - it follows the talents
if ns.Flavor and ns.Flavor.IsForever() then pcall(updater.RegisterEvent, updater, 'TRAIT_CONFIG_UPDATED') end
Tags.updater = updater
