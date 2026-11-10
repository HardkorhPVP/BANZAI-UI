--[[
	BANZAI - PvPFrames.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	0.9.0: the PvP furniture around ElvUI's party / arena ally frames and its
	arena enemy frames (the frames themselves, their auras and cast bars stay
	ElvUI's, configured by BushidoPrivateRestore):

	  trinket  a circle the size of the identity circle (Identity.lua): right of
	           each party / arena ally frame, left of each arena enemy frame
	           (mirrored). The PvP medallion; its state comes from the game's own
	           arena trinket data (C_PvP.GetArenaCrowdControlDuration, which the
	           game answers inside arenas only), handed unread to a Cooldown
	           widget:
	             AVAILABLE  bright ring, full-colour medallion
	             USED       desaturated, the game's own cooldown swipe
	             UNKNOWN    outside arenas or when the game says nothing:
	                        dimmed, neutral ring
	           No timer is built and nothing is guessed.
	  markers  arena enemies: a lime TARGET / violet FOCUS outline with an edge
	           tab, from UnitIsUnit when the game answers it plainly (the same
	           test as ElvUI's own target glow); nothing when it is secret
	  CC       parts of ElvUI's crowd-control aura icon itself (party: its
	           'auras' element, arena enemies: their debuffs - both limited by
	           BushidoPrivateRestore to the game's CROWD_CONTROL category): a
	           bold CC label and a magenta border around the health bar (never
	           a health colour), with a restrained pulse at STRONG. They appear
	           and vanish with the icon: no aura is read and nothing inferred.
	           The icons ElvUI has created are found in its own lists
	           (container.buttons) when auras change; nothing is hooked.
	  dispel   the same on the party frames' dispellable-debuff icon (the
	           game's RAID_PLAYER_DISPELLABLE: effects this character can
	           dispel): a DISPEL label and a cyan border

	Emphasis (BANZAI > PVP): STRONG border 3 + label + pulse, CLEAR border 2 +
	label, MINIMAL the icon alone. Frames are only created out of combat (their
	parents are secure unit frames); the aura icon parts are added as soon as
	ElvUI has created the icon.

	1.3.3 (Darren's live error, 20:46:04: PvPFrames.lua:226 "calling 'SetHeight'
	on bad self (Attempt to access forbidden object from code tainted by an
	AddOn)", Emphasize <- Refresh <- the 0.2 s event refresh): Emphasize set the
	border thickness again on every refresh - SetHeight / SetWidth on Banzai's
	edge textures inside ElvUI's aura icon, a tree on the secure party / arena
	unit frame that the client had made forbidden by then (the game decides
	when; the log does not say why at that moment). Banzai's fault was the
	design: geometry rewritten, over and over, on objects living in a foreign
	secure tree. Now:
	  built once  each part gets its final geometry when it is created (a
	              thick and a thin border, each drawn at its own thickness);
	              nothing is resized, moved, re-anchored or re-parented later
	  shown only  an emphasis level only shows one border set, the label and
	              the pulse - when the level changes (not on every event), out
	              of combat (a change in combat waits for its end)
	  asked first every later call is made only on what the game still lets
	              Banzai touch (IsForbidden: the one question it answers for a
	              forbidden object); a forbidden part is left as it is (the
	              icon alone) - no pcall hides a forbidden call
	The look is the approved one (borders, labels, pulse, colours, places).

	1.3.4 (Darren's live errors under 1.3.3, 22:46:33 PvPFrames.lua:298
	"Attempt to access forbidden object" in CreateFrame <- Decorate <- Scan, and
	22:49:31 "Frame:SetScript(): Cannot assign script handler for 'onshow'
	(blocked by secret aspects)" <- Decorate): the whole idea of decorating
	inside a PvP frame's tree was unsafe, not one call. ElvUI's party / arena
	aura icons follow secret aura data in 12.x - their secret aspects pass to
	every child - and the client refuses addon code there (IsForbidden said no
	right before CreateFrame refused the icon as a parent). So the rule is now:
	Banzai never decorates inside a PvP frame's tree.
	  retired     the CC / DISPEL border, label and pulse on ElvUI's aura icons
	              (PvP.Decorate is a no-op; no scan of ElvUI's aura lists, no
	              UNIT_AURA watcher). ElvUI's own CC icon and dispel glow stay.
	  moved       the trinket circles and the arena target / focus markers are
	              Banzai's own frames on Banzai's PvP layer (a UIParent child),
	              never children of a unit frame; given its strata / level and
	              anchored to its health bar once, out of combat; shown only
	              while the client says plainly that the unit frame is visible
	  gated       one access check (PvP.Accessible: IsForbidden,
	              HasAnySecretAspect, IsAnchoringSecret, issecrettable) before
	              anything is read from a unit frame or done with Banzai's own
	              frames that follow it; a refused frame is remembered and left
	              alone until the next loading screen - never probed, scripted or
	              rebuilt on the 0.2 s refresh; no pcall hides a refused call

	1.3.5 (Darren: thin gold lines stayed drawn across the world): traced - they
	are not Banzai's (Banzai makes no line, no rotated or warped texture; the
	evidence is in docs/BANZAI-1.3.5-LINES-NOTE.md). What Banzai does own that
	follows a unit relation is here: the arena TARGET / FOCUS outlines, each a
	rectangle with both corners on the same health bar (it can never reach
	across the screen). They now have one deterministic way out:
	  root        each entry's trinket and markers are children of one Banzai
	              frame (the entry's root: on the layer, anchored to nothing
	              else); a refused entry or Banzai Art switched off is hidden
	              there, so nothing that follows a unit frame is touched
	  sweep       PvP:Sweep() hides every root at once - on a loading screen,
	              a zone or spec change and when Banzai Art is switched off (a
	              profile or style switch; a reload starts hidden) - and the
	              next refresh shows only what the plain answers allow. Target /
	              focus changes and clears, the end of combat, a frame the game
	              hides and the features' own switches keep their 1.3.4 paths.
	              Events only: nothing polls.
]]
local _, ns = ...
local Theme = ns.Theme

local PvP = {}
ns.PvPFrames = PvP
if ns.Compat then ns.Compat.PvPFrames = PvP end -- the options page reaches it through BanzaiCompat

PvP.MEDALLION = 336126 -- Gladiator's Medallion
PvP.FALLBACK_ICON = 'Interface\\Icons\\INV_Jewelry_TrinketPVP_01'
PvP.SWIPE = 'Interface\\CHARACTERFRAME\\TempPortraitAlphaMask' -- a full circle: the swipe stays round
PvP.FRAMES = {
	{ prefix = 'ElvUF_PartyGroup1UnitButton', count = 5, side = 'RIGHT', kind = 'friendly' },
	{ prefix = 'ElvUF_Arena', count = 5, unit = 'arena', side = 'LEFT', kind = 'enemy' },
}
PvP.COLORS = {
	ready = { 0.62, 1.00, 0.12 }, used = { 0.38, 0.38, 0.42 }, unknown = { 0.26, 0.28, 0.30 },
	cc = { 1.00, 0.18, 0.62 }, dispel = { 0.20, 0.85, 1.00 },
	target = { 0.62, 1.00, 0.12 }, focus = { 0.56, 0.22, 1.00 },
}
PvP.EMPHASIS = {
	STRONG = { border = 3, label = true, pulse = true },
	CLEAR = { border = 2, label = true },
	MINIMAL = {},
}
PvP.LEVELS = { 'STRONG', 'CLEAR', 'MINIMAL' }

local built = {}   -- [unit frame] = { root = frame, trinket = circle, target = marker, focus = marker, health = bar } - Banzai's own frames on the Banzai PvP layer
local refused = {} -- [unit frame] = true: the client refused access - skipped until the next loading screen (never probed on a refresh)

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Plain(value)
	if IsSecret(value) then return nil end
	return value
end

local function Active()
	return ns.Compat and ns.Compat.Active and ns.Compat.Active() or false
end

-- 1.3.4 the one access gate, for every object Banzai did not make (and for Banzai's own frames that follow one):
-- the client must say it is neither forbidden nor carrying a secret aspect - the questions the 12.x client
-- answers for any object (IsForbidden first: the one a forbidden object answers). Anything refused is skipped:
-- nothing is read from it, parented to it, scripted, decorated or tried again on a refresh.
PvP.ACCESS = { 'IsForbidden', 'HasAnySecretAspect', 'IsAnchoringSecret' }
local function Accessible(object)
	if type(object) ~= 'table' then return false end
	if issecrettable and issecrettable(object) then return false end
	for _, question in ipairs(PvP.ACCESS) do
		local ask = object[question]
		if ask and ask(object) then return false end
	end
	return true
end
PvP.Accessible = Accessible

-- 1.3.4 the Banzai PvP layer: every live PvP visual of Banzai is in this frame of Banzai's own (1.3.5: through its entry's root; on
-- UIParent) - never of a party / arena frame or anything inside one
local layer
function PvP.Layer()
	if not layer then
		layer = CreateFrame('Frame', 'BanzaiPvPLayer', UIParent)
		layer:SetAllPoints(UIParent)
		layer:EnableMouse(false)
	end
	return layer
end

-- whether the game shows a unit frame, only as a plain answer from an accessible frame (else: not shown)
local function Visible(frame)
	if not (Accessible(frame) and frame.IsVisible) then return false end
	local shown = frame:IsVisible()
	return not IsSecret(shown) and shown == true
end

-- an entry may be refreshed: its unit frame and Banzai's own frames that follow it all accessible; a refusal is
-- remembered (refused / entry.refused) until the next loading screen
local function Usable(entry)
	if entry.refused or refused[entry.frame] then return false end
	for _, object in ipairs({ entry.frame, entry.health, entry.trinket, entry.target, entry.focus }) do
		if object and not Accessible(object) then
			entry.refused = true
			return false
		end
	end
	return true
end

-- 1.3.5 an entry's parts show through its root (Banzai's own, on the layer): a refused entry or Banzai Art
-- switched off - the root hidden at once; nothing that follows the unit frame is touched
local function Settle(entry)
	local usable = Usable(entry)
	local root = entry.root
	if root and Accessible(root) then root:SetShown(usable and Active()) end
	return usable
end

local function InArena()
	if not IsInInstance then return false end
	local ok, inInstance, kind = pcall(IsInInstance)
	return ok and Plain(inInstance) == true and Plain(kind) == 'arena'
end

local function UnitOf(frame, def, index)
	local unit = Plain(frame.unit)
	if type(unit) ~= 'string' and frame.GetAttribute then unit = Plain(frame:GetAttribute('unit')) end
	if type(unit) ~= 'string' and def.unit then unit = def.unit .. index end
	return type(unit) == 'string' and unit or nil
end

local function Gradient(texture, color)
	Theme:Gradient(texture, 'VERTICAL', { color[1] * 0.7, color[2] * 0.7, color[3] * 0.7 }, Theme.Mix(color, { 1, 1, 1 }, 0.3), 1, 1)
end

---------------------------------------------------------------------------
-- Trinket circle
---------------------------------------------------------------------------
function PvP.Medallion()
	local texture = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(PvP.MEDALLION)
	texture = Plain(texture)
	if type(texture) == 'number' or type(texture) == 'string' then return texture end
	return PvP.FALLBACK_ICON
end

-- a trinket circle on `parent` (also used by the unit-frame preview)
function PvP.Trinket(parent, size)
	local c = ns.Identity.Circle(parent, size)
	c.icon:SetTexture(PvP.Medallion())
	c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	local cd = CreateFrame('Cooldown', nil, c, 'CooldownFrameTemplate')
	cd:SetAllPoints(c.icon)
	if cd.SetSwipeTexture then cd:SetSwipeTexture(PvP.SWIPE) end
	if cd.SetUseCircularEdge then cd:SetUseCircularEdge(true) end
	if cd.SetDrawEdge then cd:SetDrawEdge(false) end
	if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
	if cd.SetSwipeColor then cd:SetSwipeColor(0, 0, 0, 0.7) end
	c.cd = cd
	PvP.PaintTrinket(c, 'UNKNOWN')
	return c
end

function PvP.PaintTrinket(c, state)
	c.state = state
	c.icon:SetDesaturated(state ~= 'READY')
	c.icon:SetAlpha(state == 'UNKNOWN' and 0.45 or 1)
	Gradient(c.ring, PvP.COLORS[(state == 'READY' and 'ready') or (state == 'USED' and 'used') or 'unknown'])
end

function PvP:UpdateTrinket(c)
	local entry = c.entry
	if not (entry and Settle(entry)) then return nil end -- 1.3.4: a refused frame is left alone (1.3.5: hidden at its root)
	local unit = UnitOf(entry.frame, entry.def, entry.index)
	if not (Active() and Theme:DB().trinketCircles ~= false and unit and Visible(entry.frame)) then
		c:Hide()
		return nil
	end
	c:Show()
	local data
	if InArena() and C_PvP and C_PvP.GetArenaCrowdControlDuration then
		local ok, value = pcall(C_PvP.GetArenaCrowdControlDuration, unit)
		if ok then data = value end
	end
	if data and c.cd.SetCooldownFromDurationObject then
		c.cd:SetCooldownFromDurationObject(data) -- the game's own trinket time, handed over unread
		-- 1.3.4: the swipe's shown state is asked only while the client answers it plainly (else: UNKNOWN, nothing guessed)
		local running = Accessible(c.cd) and c.cd:IsShown()
		if IsSecret(running) or not Accessible(c.cd) then PvP.PaintTrinket(c, 'UNKNOWN') else PvP.PaintTrinket(c, running and 'USED' or 'READY') end
	else
		c.cd:Clear()
		PvP.PaintTrinket(c, 'UNKNOWN')
	end
	return c.state
end

---------------------------------------------------------------------------
-- Target / focus markers on the arena enemy frames
---------------------------------------------------------------------------
-- labelX: the label sits inside the bar's bottom-right corner (clear of the cast bar above and the name).
-- 1.3.4: `parent` is Banzai's own (1.3.5: an entry's root on the PvP layer, a preview sample); `region` is only anchored to
function PvP.Marker(parent, region, color, label, inset, labelX)
	local m = CreateFrame('Frame', nil, parent)
	m:SetPoint('TOPLEFT', region, 'TOPLEFT', -inset, inset)
	m:SetPoint('BOTTOMRIGHT', region, 'BOTTOMRIGHT', inset, -inset)
	m.edges = {}
	for i, side in ipairs({ { 'TOPLEFT', 'TOPRIGHT', true }, { 'BOTTOMLEFT', 'BOTTOMRIGHT', true }, { 'TOPLEFT', 'BOTTOMLEFT', false }, { 'TOPRIGHT', 'BOTTOMRIGHT', false } }) do
		local t = m:CreateTexture(nil, 'OVERLAY')
		t:SetTexture(Theme.WHITE)
		t:SetPoint(side[1], m, side[1], 0, 0)
		t:SetPoint(side[2], m, side[2], 0, 0)
		if side[3] then t:SetHeight(2) else t:SetWidth(2) end
		t:SetVertexColor(color[1], color[2], color[3], 1)
		m.edges[i] = t
	end
	m.tab = m:CreateTexture(nil, 'OVERLAY')
	m.tab:SetTexture(Theme.WHITE)
	m.tab:SetPoint('TOPLEFT', m, 'TOPLEFT', inset, -inset)
	m.tab:SetPoint('BOTTOMLEFT', m, 'BOTTOMLEFT', inset, inset)
	m.tab:SetWidth(4)
	m.tab:SetVertexColor(color[1], color[2], color[3], 1)
	m.label = m:CreateFontString(nil, 'OVERLAY')
	m.label:SetFont(Theme:SmallFont(), 8, 'OUTLINE')
	m.label:SetPoint('BOTTOMRIGHT', m, 'BOTTOMRIGHT', (labelX or -6) - inset, 2 + inset)
	m.label:SetText(label)
	m.label:SetTextColor(color[1], color[2], color[3])
	m:Hide()
	return m
end

local function UnitIs(a, b)
	if not UnitIsUnit then return false end
	local ok, value = pcall(UnitIsUnit, a, b)
	return ok and Plain(value) == true
end

function PvP:UpdateMarkers(entry)
	if not entry.target then return end
	if not Settle(entry) then return end -- 1.3.4 (1.3.5: hidden at its root)
	local unit = UnitOf(entry.frame, entry.def, entry.index)
	local on = Active() and unit ~= nil and Visible(entry.frame)
	entry.target:SetShown(on and UnitIs('target', unit))
	entry.focus:SetShown(on and UnitIs('focus', unit))
end

---------------------------------------------------------------------------
-- 1.3.4 the CC / dispel parts on ElvUI's aura icons: retired
---------------------------------------------------------------------------
-- In Retail 12.x ElvUI's party / arena aura icons are a tree the client restricts: their visibility follows
-- secret aura data (a secret aspect every child inherits) and the client refuses addon code there - 1.3.2
-- re-sizing a Banzai edge failed (SetHeight on a forbidden object), 1.3.3 failed creating its frame on the icon
-- (CreateFrame: forbidden object - although IsForbidden had just said no) and assigning its OnShow (blocked by
-- secret aspects). No check makes decorating inside that tree safe, so Banzai no longer does it: no Banzai
-- part on any aura icon, no scan of ElvUI's aura lists, no UNIT_AURA watcher. ElvUI's own CC icon and dispel
-- glow (BushidoPrivateRestore's PvP layout) stay; the Banzai CC / DISPEL border, label and pulse are gone from
-- the live frames (the emphasis settings now shape the preview samples only).
function PvP.Decorate() return nil end -- retired (1.3.4): nothing is ever made on a PvP frame's aura icon

---------------------------------------------------------------------------
-- Build / refresh
---------------------------------------------------------------------------
-- the trinket circle and (arena enemies) the target / focus markers of each frame the client lets Banzai
-- access: Banzai's own frames on the Banzai PvP layer, given the unit frame's strata / level and anchored to
-- its health bar once, out of combat (anchoring changes nothing on the unit frame); a refused frame is noted
-- and skipped until the next loading screen
function PvP:Build()
	if InCombatLockdown() then return false end
	local size = (ns.Identity and ns.Identity.SIZE) or 27
	local gap = (ns.Identity and ns.Identity.GAP) or 4
	for _, def in ipairs(self.FRAMES) do
		for i = 1, def.count do
			local frame = _G[def.prefix .. i]
			if frame and not built[frame] and not refused[frame] then
				local health = Accessible(frame) and (frame.Health or frame)
				if not (health and Accessible(health)) then
					refused[frame] = true
				else
					local strata = frame.GetFrameStrata and Plain(frame:GetFrameStrata())
					local level = frame.GetFrameLevel and Plain(frame:GetFrameLevel())
					local function Raise(f, extra)
						if type(strata) == 'string' then f:SetFrameStrata(strata) end
						f:SetFrameLevel((type(level) == 'number' and level or 1) + extra)
					end
					local entry = { frame = frame, health = health, def = def, index = i }
					-- 1.3.5 the entry's root: Banzai's own, on the layer and anchored to nothing else; its parts are its children
					local root = CreateFrame('Frame', nil, PvP.Layer())
					root:SetAllPoints(PvP.Layer())
					root:EnableMouse(false)
					root:Hide() -- shown by the first refresh that finds the entry usable
					entry.root = root
					local c = PvP.Trinket(root, size)
					Raise(c, 6)
					c:ClearAllPoints()
					if def.side == 'RIGHT' then
						c:SetPoint('LEFT', health, 'RIGHT', gap, 0)
					else
						c:SetPoint('RIGHT', health, 'LEFT', -gap, 0)
					end
					c.entry = entry
					c.cd:SetScript('OnCooldownDone', function() PvP:UpdateTrinket(c) end) -- Banzai's own cooldown widget
					c:Hide()
					entry.trinket = c
					if def.kind == 'enemy' then
						entry.target = PvP.Marker(root, health, PvP.COLORS.target, 'TARGET', 2, -6)
						entry.focus = PvP.Marker(root, health, PvP.COLORS.focus, 'FOCUS', 5, -42)
						Raise(entry.target, 7)
						Raise(entry.focus, 7)
					end
					built[frame] = entry
				end
			end
		end
	end
	return true
end

function PvP:Get(frameName)
	return built[_G[frameName]]
end

function PvP:Refused(frameName)
	local frame = _G[frameName]
	local entry = built[frame]
	return refused[frame] == true or (entry and entry.refused) == true
end

function PvP:Refresh()
	self:Build()
	for _, entry in pairs(built) do
		self:UpdateTrinket(entry.trinket)
		self:UpdateMarkers(entry)
	end
end

-- 1.3.4 a loading screen is the one moment refused frames are asked again (an arena's restrictions end with it)
function PvP:Reconsider()
	for frame in pairs(refused) do refused[frame] = nil end
	for _, entry in pairs(built) do entry.refused = nil end
end

-- 1.3.5 every Banzai PvP visual put away at once (each entry's root hidden, nothing that follows a unit frame
-- touched); the next refresh shows again only what the client plainly allows
PvP.SWEEP_EVENTS = { PLAYER_ENTERING_WORLD = true, ZONE_CHANGED_NEW_AREA = true, PLAYER_SPECIALIZATION_CHANGED = true }
function PvP:Sweep()
	for _, entry in pairs(built) do
		if entry.root and Accessible(entry.root) then entry.root:Hide() end
	end
end

local events = CreateFrame('Frame')
PvP.events = events -- (the tests reach its events through it)
for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'GROUP_ROSTER_UPDATE', 'ARENA_OPPONENT_UPDATE', 'ARENA_COOLDOWNS_UPDATE', 'UNIT_ARENA_COOLDOWNS_UPDATE',
	'PVP_MATCH_STATE_CHANGED', 'ZONE_CHANGED_NEW_AREA', 'PLAYER_TARGET_CHANGED', 'PLAYER_FOCUS_CHANGED', 'PLAYER_REGEN_ENABLED', 'PLAYER_SPECIALIZATION_CHANGED' }) do -- 1.3.4: no UNIT_AURA
	pcall(events.RegisterEvent, events, event)
end
events:SetScript('OnEvent', function(_, event)
	if event == 'PLAYER_TARGET_CHANGED' or event == 'PLAYER_FOCUS_CHANGED' then
		for _, entry in pairs(built) do PvP:UpdateMarkers(entry) end
		return
	end
	if PvP.SWEEP_EVENTS[event] then PvP:Sweep() end -- 1.3.5: a loading screen, a zone or spec change
	if event == 'PLAYER_ENTERING_WORLD' then PvP:Reconsider() end
	if PvP.scheduled then return end
	PvP.scheduled = true
	C_Timer.After(0.2, function()
		PvP.scheduled = false
		PvP:Refresh()
	end)
end)
