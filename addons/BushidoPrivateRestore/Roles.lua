--[[
	BANZAI - Roles.lua
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	0.6.0: role-aware group frames. The current specialization's role comes from
	the game (GetSpecialization / GetSpecializationInfo): HEALER uses the HEALER
	arrangement, every other role (DPS, and tanks for now) the DPS one. The
	party, raid, arena and boss positions of that arrangement (Transform.lua
	T.ROLE_LAYOUTS, plus whatever Darren set himself for that role) are written
	into the Banzai profile's ElvUI movers and ElvUI moves the frames there.

	0.7.0: an arrangement is more than positions: the party header's growth,
	spacing and width come with it (HEALER: one horizontal row in the centre,
	DPS: Bushido's column), and the arena allies keep a position of their own.
	In an arena ElvUI shows the allies with the party header, so while the
	character is in an arena the party mover takes the arena allies position
	(the "context"); leaving the arena switches back.

	  spec change   detected (PLAYER_SPECIALIZATION_CHANGED, login), the layout
	                switches by itself; in combat it waits until combat ends
	                (ElvUI's group headers are secure)
	  own changes   a position or party arrangement Darren changes with ElvUI's
	                movers / options while a layout is active is kept for that
	                role (and, for the party mover, for party or arena allies)
	                only: before the next switch (and at logout) it is read back
	                and saved where it was made, so the HEALER party never
	                overwrites the DPS party
	  preview       BANZAI > LAYOUT > UNIT FRAME PREVIEW shows either layout
	                without a spec change (Layout(role))

	Nothing is hooked; ElvUI's own mover positions and unit settings are read
	and written, and ElvUI rebuilds its party header through its own update.
]]
local _, ns = ...
local T = ns.Transform

local Roles = {}
ns.Roles = Roles
_G.BanzaiRoles = Roles -- the unit-frame preview (BushidoPrivateCompat) reads the layouts through this

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function Art()
	return _G.BanzaiCompat
end

local function Profile()
	local profile = _G.ElvDB and _G.ElvDB.profiles and _G.ElvDB.profiles[T.PROFILE]
	return type(profile) == 'table' and profile or nil
end

local FOREVER_TREE_ROLES = {
	DRUID = { [1] = 'DPS', [2] = 'AMBIGUOUS', [3] = 'HEALER' },
}

function Roles.ClassifyForever(spec, classToken)
	if type(spec) ~= 'table' or type(spec.index) ~= 'number' then return nil, 'no verified leading talent tree' end
	local role = FOREVER_TREE_ROLES[classToken] and FOREVER_TREE_ROLES[classToken][spec.index]
	if role == 'AMBIGUOUS' then return nil, 'ambiguous tree; keep the prior layout or set an override' end
	if role == 'HEALER' or role == 'DPS' then return role, 'verified class/tree position' end
	return nil, 'unmapped class/tree; keep the prior layout or set an override'
end

local function LastLayout()
	local art = Art()
	local state = art and art.RoleState and art:RoleState()
	local active = type(state) == 'table' and state.active
	return (active == 'DPS' or active == 'HEALER') and active or 'DPS'
end

function Roles:Override()
	local art = Art()
	return art and art.ForeverRoleOverride and art:ForeverRoleOverride() or 'AUTO'
end

function Roles:SetOverride(value)
	if not (ns.Flavor and ns.Flavor.IsForever()) then return false, 'Role overrides are only available on WoW Forever.' end
	value = type(value) == 'string' and string.upper(value) or ''
	if value ~= 'AUTO' and value ~= 'DPS' and value ~= 'HEALER' then
		return false, 'Use /banzai role auto, dps, or healer.'
	end
	local art = Art()
	if not (art and art.ForeverRoleOverride) then return false, 'Banzai Art is not ready.' end
	art:ForeverRoleOverride(value)
	local role = self.Current() or 'DPS'
	self:Apply(role, 'manual role override')
	return true, 'Forever role override: ' .. value .. ' (layout ' .. role .. ').'
end

function Roles:Detection()
	local spec = ns.Flavor and ns.Flavor.IsForever() and ns.Flavor.PlayerSpec() or nil
	if not (ns.Flavor and ns.Flavor.IsForever()) then return nil end
	local _, classToken = UnitClass('player')
	local detected, reason = self.ClassifyForever(spec, classToken)
	local override = self:Override()
	local layout
	if override == 'DPS' or override == 'HEALER' then
		layout, reason = override, 'explicit local override'
	else
		layout = detected or LastLayout()
	end
	return { tree = spec and spec.name, index = spec and spec.index, class = classToken, role = detected, layout = layout, reason = reason, override = override }
end

local function Applied()
	local E = Engine()
	local key = E and E.mynameRealm
	local db = _G.BushidoPrivateRestoreDB
	local record = key and db and db.characters and db.characters[key]
	return record and record.applied and E.data and E.data:GetCurrentProfile() == T.PROFILE and true or false
end

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

-- this character's specialization and the layout its role uses (nil before the game knows it)
function Roles.Spec()
	-- Forever exposes talent trees rather than specialization roles. Use only
	-- the supported class/tree-position map; ambiguous or unmapped trees retain
	-- the character's last layout until Darren chooses a local override.
	local Flavor = ns.Flavor
	if Flavor and Flavor.IsForever() then
		local spec = Flavor.PlayerSpec()
		if not spec then return nil end
		local detection = Roles:Detection()
		return { id = nil, name = spec.name, icon = spec.icon, role = detection and detection.layout, layout = T.LayoutRole(detection and detection.layout),
			source = spec.source, points = spec.points, treeIndex = spec.index, roleReason = detection and detection.reason }
	end
	local index = GetSpecialization and GetSpecialization()
	if type(index) ~= 'number' or IsSecret(index) or index < 1 then return nil end
	local id, name, _, icon, role = GetSpecializationInfo(index)
	if IsSecret(role) then role = nil end
	return { id = id, name = name, icon = icon, role = role, layout = T.LayoutRole(role) }
end

function Roles.Current()
	local spec = Roles.Spec()
	return spec and spec.layout or nil
end

-- 'arena' inside an arena (the party header shows the arena allies), else 'world'
function Roles.Context()
	if not IsInInstance then return 'world' end
	local _, kind = IsInInstance()
	if IsSecret(kind) then return 'world' end
	return (kind == 'arena') and 'arena' or 'world'
end

local function State()
	local art = Art()
	return art and art.RoleState and art:RoleState() or nil
end

local function Overrides()
	local art = Art()
	return art and art.Roles and art:Roles() or {}
end

-- the layout written last for this character (else the spec's, else DPS)
function Roles:Active()
	local state = State()
	return (state and state.active) or self.Current() or 'DPS'
end

-- the context of what was written last (the character layer at load uses it)
function Roles:ActiveContext()
	local state = State()
	return (state and state.context) or 'world'
end

-- mover positions, the arena allies position and the party arrangement of a role for this character
function Roles:Layout(role)
	local P = ns.Payloads
	return T.RoleLayout(role, P and P.elvuiProfile, Overrides())
end

-- what was written for `role` in `context` (the character layer at login calls this too)
function Roles:Written(role, written, context)
	local state = State()
	if not state then return end
	state.active = role
	state.context = context or 'world'
	state.written = T.DeepCopy(written)
end

-- where a change to a written key is kept: the party mover in an arena is the arena allies position
local function OverrideKey(key, context)
	if key == 'ElvUF_PartyMover' and context == 'arena' then return T.ARENA_ALLIES end
	return key
end

-- positions / party arrangement changed by hand since Banzai wrote them are
-- saved for the role (and frame kind) they were made in; returns how many.
-- Only while this character is on Banzai: the shared profile may carry
-- another character's positions otherwise.
function Roles:Capture()
	if not Applied() then return 0 end
	-- the shared profile must carry this character's positions (written at its login)
	local E = Engine()
	local owner = _G.BushidoPrivateRestoreDB and _G.BushidoPrivateRestoreDB.layerOwner
	if not (owner and E and owner.key == E.mynameRealm) then return 0 end
	local state, profile = State(), Profile()
	if not (state and state.active and type(state.written) == 'table' and profile and type(profile.movers) == 'table') then return 0 end
	local overrides = Overrides()
	local units = profile.unitframe and profile.unitframe.units
	local n = 0
	local function keep(key, now)
		local written = state.written[key]
		if now ~= nil and written ~= nil and now ~= written then
			overrides[state.active] = overrides[state.active] or {}
			overrides[state.active][OverrideKey(key, state.context)] = now
			state.written[key] = now
			n = n + 1
		end
	end
	for _, name in ipairs(T.ROLE_MOVERS) do
		local now = profile.movers[name]
		if type(now) == 'string' then keep(name, now) end
	end
	-- the party arrangement and (0.9.0) the arena enemy size
	for _, group in ipairs(T.ROLE_UNITS) do
		local unit = type(units) == 'table' and type(units[group.unit]) == 'table' and units[group.unit] or {}
		for _, key in ipairs(group.keys) do keep(group.unit .. '.' .. key, T.GetPath(unit, key)) end
	end
	return n
end

-- first role layout for a character that ran an older Banzai (one layout
-- only): group frames it had moved away from Bushido's places become its own
-- DPS positions, so the upgrade does not move them back
function Roles:Seed(profile)
	local state = State()
	if not (state and state.written == nil and type(profile) == 'table' and type(profile.movers) == 'table') then return 0 end
	local P = ns.Payloads
	local old = (P and P.elvuiProfile and P.elvuiProfile.movers) or {}
	local banzai = T.ROLE_LAYOUTS.DPS or {} -- a newer build may already have written its own DPS places (shared profile)
	local overrides = Overrides()
	local n = 0
	for _, name in ipairs(T.ROLE_MOVERS) do
		local now = profile.movers[name]
		if type(now) == 'string' and old[name] and now ~= old[name] and now ~= banzai[name] then
			overrides.DPS = overrides.DPS or {}
			if overrides.DPS[name] == nil then
				overrides.DPS[name] = now
				n = n + 1
			end
		end
	end
	return n
end

-- the character left Banzai: nothing recorded as written for it any more
function Roles:Forget()
	local state = State()
	if state then state.active, state.written, state.context = nil, nil, nil end
end

-- ElvUI rebuilds the party header with the arrangement now in its settings (0.9.0: and the arena frames)
local function UpdatePartyHeader(E)
	local UF = E and E.GetModule and E:GetModule('UnitFrames', true)
	if UF and UF.CreateAndUpdateHeaderGroup then pcall(UF.CreateAndUpdateHeaderGroup, UF, 'party') end
	-- 0.9.0: the arena enemy frames take the role's size too
	if UF and UF.CreateAndUpdateUFGroup then pcall(UF.CreateAndUpdateUFGroup, UF, 'arena', 5) end
end

-- writes a role's layout for the current context and lets ElvUI move / rebuild the frames (out of combat)
function Roles:Apply(role, reason)
	role = role or self.Current() or 'DPS'
	if InCombatLockdown() then
		self.pending = role
		return false
	end
	local profile = Profile()
	if not (profile and Applied()) then return false end
	self:Capture()
	local P = ns.Payloads
	local context = self.Context()
	local _, written = T.ApplyRoleLayout(profile, role, P and P.elvuiProfile, Overrides(), context)
	self:Written(role, written, context)
	self.pending = nil
	self.lastReason = reason
	local E = Engine()
	if E and E.SetMoverPoints then
		for _, name in ipairs(T.ROLE_MOVERS) do pcall(E.SetMoverPoints, E, name) end
	end
	UpdatePartyHeader(E)
	return true
end

-- login / spec change / entering or leaving an arena: switch when the spec's
-- role or the context uses another layout
function Roles:Check(reason)
	local role = self.Current()
	if not role then return false end
	local state = State()
	if state and state.active == role and (state.context or 'world') == self.Context() and not self.pending then return false end
	return self:Apply(role, reason)
end

-- back to the Banzai positions for a role (its own saved positions dropped)
function Roles:Reset(role)
	local overrides = Overrides()
	if self:Active() == role then self:Capture() end
	overrides[role] = nil
	if self:Active() == role then return self:Apply(role, 'reset') end
	return true
end

local events = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED_NEW_AREA', 'PLAYER_SPECIALIZATION_CHANGED', 'ACTIVE_TALENT_GROUP_CHANGED', 'PLAYER_REGEN_ENABLED', 'PLAYER_LEAVING_WORLD', 'PLAYER_LOGOUT' }) do
	pcall(events.RegisterEvent, events, event)
end
events:SetScript('OnEvent', function(_, event, unit)
	if event == 'PLAYER_LOGOUT' or event == 'PLAYER_LEAVING_WORLD' then
		-- PLAYER_LEAVING_WORLD comes first: ElvUI's saved profile drops values equal to its defaults at logout
		Roles:Capture()
	elseif event == 'PLAYER_REGEN_ENABLED' then
		if Roles.pending then Roles:Apply(Roles.pending, 'after combat') end
	elseif event == 'PLAYER_SPECIALIZATION_CHANGED' and unit and unit ~= 'player' then
		return
	elseif event == 'PLAYER_ENTERING_WORLD' then
		C_Timer.After(2, function() Roles:Check('login') end) -- the spec is known shortly after login
	elseif event == 'ZONE_CHANGED_NEW_AREA' then
		Roles:Check('zone')
	else
		Roles:Check('spec change')
	end
end)
