--[[
	BANZAI - Split.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	1.3.0 BANZAI SPLIT: the optional second unit-frame family (BANZAI > UNIT
	FRAMES > FRAME STYLE). BANZAI CLASSIC stays the default and is untouched;
	this file does nothing unless the character chose SPLIT and its ElvUI
	profile carries the split layer (BushidoPrivateRestore writes it at login,
	a reload applies a change), so a session is either fully classic or fully
	split - nothing is built twice, nothing is mixed.

	The frames are ElvUI's own (clickable, secure, fed by the game): ElvUI
	sizes and places them from the Banzai profile - the health bar is the
	frame, the resource bar is ElvUI's detached power bar on the other side,
	the class bar above it, ElvUI's player / target / focus cast bars off. Banzai
	Art adds what makes the composition:

	  hub        the central identity / cast circle (Identity.Hub) joining the
	             two bars; idle: the class art chain (players) or the unit's
	             portrait (NPCs) in a class / reaction ring with the thin green ->
	             purple accent
	  cast       the hub transforms while the unit casts: the spell icon fills
	             the circle, the ring becomes the radial progress (the game's
	             Cooldown swipe fed with the game's own duration object -
	             UnitCastingDuration / UnitChannelDuration /
	             UnitEmpoweredChannelDuration - never computed), the spell name
	             above the hub with the remaining time the widget formats; a cast
	             and an empower fill, a channel drains, each in its colour; a
	             non-interruptible steel border through SetAlphaFromBoolean (never
	             tested); INTERRUPTED / FAILED for a moment when the cast ends
	             that way (also a channel / empower whose stop event names an
	             interrupter); then the class art again. Without a duration object
	             and without readable times the ring shows the active cast
	             without any progress (nothing is invented). Each unit's events
	             are registered for that unit only; the current cast is read again
	             on every event, and the cast bar ID decides which cast an ending
	             belongs to only when the game gives it plainly.
	  surfaces   a smooth class / reaction gradient over ElvUI's health fill, the
	             canonical resource colour over its power fill, a dark track
	             under both
	  NPCs       a target / focus whose resource is plainly none (the game
	             reports a maximum of 0) loses its resource side; a secret
	             maximum keeps it (the bar is the game's)

	Health / resource texts inside the bars: Health.lua (split definitions).
	Name lines: ElvUI custom texts written by BushidoPrivateRestore. Party
	circles: Identity.lua. The enhanced targeted nameplate: TargetPlate.lua.
	The unit-frame preview (Preview.lua) draws the split samples here.

	1.3.1 runtime correction (Darren's 1.3.0 screenshots):
	  root cause  the white bars and the empty Player hub: the first paint of
	             the split frames stopped at an idle hub (Split.Idle clears the
	             cast texts, and the game refuses SetText on a font string that
	             has no font yet - "Font not set"); the Target was painted later
	             by its own event, the Player never. The hub's texts now have a
	             font from the start (Identity.Hub), and each frame is painted on
	             its own (one fault can no longer stop the others).
	  colour     health AND resource in the unit's CLASS colour family (an NPC:
	             its reaction colour) - never the resource type's colour; one
	             continuous gradient through the hub: lighter at the outer end of
	             the health bar, the canonical colour at both inner ends, deeper
	             at the outer end of the resource bar (Theme.Ramp), on each bar's fill;
	             opaque, hidden until painted (never the raw white texture again);
	             recoloured only when the unit / style changes.
	  thickness  Player 24, Target 21 (whole pixels at Darren's scale), on top of
	             the frame scale the character's bar thickness
	  texts      Player / Target values ABOVE the bars (Health.lua), the NAME
	             under the health bar from its outer end and the SPEC under the
	             resource bar to its outer end (only when the game reliably knows
	             it; never for NPCs) - Banzai Art's own font strings on ElvUI's tag
	             system, in the Banzai display font: the name in the
	             BANZAI green -> purple gradient, the spec in the class family
	  cast       structure unchanged; the spell name in the display font, the
	             timer in the small information font (its numbers stay crisp)

	1.3.2: the idle hub shows Darren's original BANZAI class identity (Identity.Art,
	asked with the hub, so its size and the nameplate rule are decided there);
	the cast presentation, the bars and every text are unchanged.

	1.3.3 (Player and Target; Focus, ToT, party and the targeted nameplate as
	they were):
	  identity   the hub 25 % larger (Split.UNITS identity: Player 62.5, Target
	             57.5 units; the icon, the spell icon, the portrait, the ring
	             with it, round and centred); the bars keep their size and sit
	             as far from its edge as before (tuck, BushidoPrivateRestore's
	             T.SPLIT the same numbers)
	  cast       idle: the BANZAI class art (full size, its own bamboo ring as the
	             hub's ring - Identity.FitArt); casting / channelling: the game's
	             spell icon ALONE in the centre (the identity veiled, never
	             under or beside it); success, failure, cancel: the class art at
	             once; interrupted: the class art at once, the bar says
	             INTERRUPTED for a moment. The radial progress, its dark track,
	             the lock ring and the spell name over the hub are gone from
	             these two hubs: the progress, the spell name, the timer and the
	             non-interruptible steel are the bamboo cast bar's (CastBar.lua),
	             full composition width, directly above the values
	  NPCs       the live Target keeps the game's portrait; the TARGET NPC
	             preview is a synthetic sample built from Banzai media only (see
	             the preview section)
]]
local _, ns = ...
local Theme = ns.Theme

local Split = {}
ns.Split = Split
if ns.Compat then
	ns.Compat.Split = Split -- the options page reaches it through BanzaiCompat
	-- Darren's own Details sheet was built (BushidoPrivateRestore chooses the BANZAI COMPACT icon set with it)
	function ns.Compat:IdentityDetailsSheet()
		local manifest = ns.IdentityManifest
		return type(manifest) == 'table' and manifest.details == true
	end
end

-- geometry in UIParent units: the same numbers as BushidoPrivateRestore's T.SPLIT
-- (bar: length, height: bar height, hub: circle diameter, tuck: how far each bar runs under the hub;
-- 1.3.1 lines: the name / spec lines and the values above the bars are Banzai Art's, thick: the
-- character's bar thickness applies; 24 and 21 units are 32 and 28 whole pixels at Darren's scale)
-- 1.3.3 Player / Target: identity - the hub 25 % larger than its 1.3.2 size; the bamboo cast bar: castInterior (the
-- fill; 1.3.4: 22.5 / 19.5 units = 30 / 26 px, the vertical padding round the spell name gone - 1.3.3: 37.5 / 33), castStalk
-- (1.3.4: 4.5 / 3.75 = 6 / 5 px, the bamboo hugging the thinner interior at its own proportions; the whole bar 40 / 38 %
-- lower than 1.3.3's), castValues (the room the values above the bars take, at the largest display size), castName /
-- castTime (the spell name and timer sizes: unchanged)
Split.UNITS = {
	player = { frame = 'ElvUF_Player', unit = 'player', bar = 180, height = 24, hub = 50, name = 14, cast = 13, value = 15, percent = 11, power = true, lines = true, thick = true,
		identity = 1.25, castInterior = 22.5, castStalk = 4.5, castValues = 20, castName = 16, castTime = 12 },
	target = { frame = 'ElvUF_Target', unit = 'target', bar = 170, height = 21, hub = 46, name = 13, cast = 12, value = 14, percent = 10, power = true, npc = true, lines = true, thick = true,
		identity = 1.25, castInterior = 19.5, castStalk = 3.75, castValues = 18, castName = 15, castTime = 11 },
	focus = { frame = 'ElvUF_Focus', unit = 'focus', bar = 110, height = 12, powerHeight = 7, hub = 30, name = 9, cast = 10, value = 10, percent = 8, power = true, npc = true },
}
Split.CAST_BAR = { inner = 1.1, gap = 3 } -- 1.3.3: the interior from 1.1 stalks inside the bar's outline; the bar this far above the values / the hub
Split.LINE_GAP = 2 -- 1.3.1: the name / spec lines this far under the bars
Split.ORDER = { 'player', 'target', 'focus' }
Split.TUCK = 0.16               -- of the hub's diameter
Split.TOT = { frame = 'ElvUF_TargetTarget', unit = 'targettarget', bar = 90, height = 10, gap = 14 }
Split.PARTY = { circle = 32, prefix = 'ElvUF_PartyGroup1UnitButton', count = 5 }
Split.PLATE = { hub = 26, gap = 3, outline = 2 }
Split.CAST = {
	cast = { 1.00, 0.70, 0.00 },     -- the Banzai attention amber (the live cast colour BushidoPrivateRestore writes)
	channel = { 0.00, 0.90, 0.42 },  -- Banzai emerald
	empower = { 0.56, 0.22, 1.00 },  -- Banzai violet
	lock = { 0.46, 0.44, 0.56 },     -- restrained steel: cannot be interrupted
	fail = { 0.95, 0.20, 0.18 },
}
Split.FAIL_HOLD = 0.8          -- seconds INTERRUPTED / FAILED stay on the hub
Split.STOP_GRACE = 0.3         -- an INTERRUPTED / FAILED this soon after the stop still belongs to that cast
Split.CLOCK = 0.05             -- the remaining-time text, while a timed cast shows
Split.REACTION = {
	hostile = { 0.94, 0.16, 0.14 }, neutral = { 1.00, 0.72, 0.12 }, friendly = { 0.20, 0.82, 0.30 }, tapped = { 0.55, 0.56, 0.58 },
}
Split.CLASSIFICATION = { elite = { 1.00, 0.78, 0.22 }, worldboss = { 1.00, 0.78, 0.22 }, rareelite = { 1.00, 0.78, 0.22 }, rare = { 0.82, 0.86, 0.92 } }
Split.CAST_EVENTS = { 'UNIT_SPELLCAST_START', 'UNIT_SPELLCAST_STOP', 'UNIT_SPELLCAST_FAILED', 'UNIT_SPELLCAST_INTERRUPTED', 'UNIT_SPELLCAST_DELAYED',
	'UNIT_SPELLCAST_CHANNEL_START', 'UNIT_SPELLCAST_CHANNEL_UPDATE', 'UNIT_SPELLCAST_CHANNEL_STOP', 'UNIT_SPELLCAST_EMPOWER_START',
	'UNIT_SPELLCAST_EMPOWER_UPDATE', 'UNIT_SPELLCAST_EMPOWER_STOP', 'UNIT_SPELLCAST_NOT_INTERRUPTIBLE', 'UNIT_SPELLCAST_INTERRUPTIBLE' }
Split.CAST_UNITS = { 'player', 'target', 'focus' }

local BAR = Theme.MEDIA .. 'BanzaiBar'
local built = {}      -- [unit frame] = entry (hub, surfaces)
local hubs = {}       -- [unit] = { [hub] = entry }: everything a unit's cast is shown on
local casts = {}      -- [unit] = { active, failing, token, stoppedAt }
local watchers = {}   -- [unit] = event frame (one per unit, registered for that unit only)
local plateHub        -- the enhanced targeted nameplate's hub (TargetPlate.lua), when one is shown

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
	local ok, a, b = pcall(fn, ...)
	if not ok then return nil end
	return Plain(a), Plain(b)
end

local function Active()
	return ns.Compat and ns.Compat.Active and ns.Compat.Active() or false
end

---------------------------------------------------------------------------
-- The session: classic or split, decided once ElvUI has built its frames
---------------------------------------------------------------------------
-- the Player's split marker in the Banzai profile (BushidoPrivateRestore's b-SplitName entry)
local function Marker()
	local E = Engine()
	local units = E and E.db and E.db.unitframe and E.db.unitframe.units
	local texts = units and units.player and units.player.customTexts
	local line = texts and texts['b-SplitName']
	return type(line) == 'table' and line or nil
end

-- the Banzai profile carries the split layer (1.3.0: ElvUI's own name line; 1.3.1: the marker of the layer
-- whose Player / Target lines are Banzai Art's)
function Split.ProfileSplit()
	local line = Marker()
	return line and (line.enable == true or line.banzaiSplit == true) or false
end

-- 1.3.1: the profile's split layer leaves the Player / Target name and spec lines to Banzai Art (and
-- whether the spec is shown: BANZAI > APPEARANCE "Specialization in names", as the classic layer had it)
function Split.ProfileLines()
	local line = Marker()
	if not (line and line.banzaiSplit == true) then return false, false end
	return true, line.banzaiSpec == true
end

-- true when this session runs BANZAI SPLIT (the choice and the profile agree)
function Split:Session()
	if self.session ~= nil then return self.session end
	local E = Engine()
	if not (E and E.db) then return false end
	self.session = (Active() and Theme:DB().frameStyle == 'SPLIT' and Split.ProfileSplit()) and true or false
	return self.session
end

-- the style chosen (it becomes the session's at the next reload)
function Split:Chosen()
	return Theme:DB().frameStyle == 'SPLIT' and 'SPLIT' or 'CLASSIC'
end

-- party / arena allies in the split construction this session
function Split:PartySplit()
	return self:Session() and Theme:DB().splitParty ~= false
end

-- sizes for the current scales (the same rounding as T.SplitGeometry; 1.3.1: the Player / Target
-- bars' thickness on top of the frame scale)
function Split.Geometry(key, db)
	db = db or Theme:DB()
	local def = Split.UNITS[key]
	local s = tonumber(db.splitScale) or 1
	local t = def.thick and (tonumber(db.splitThickness) or 1) or 1
	local hub = math.floor(def.hub * s * (tonumber(db.splitHubScale) or 1) + 0.5) * (def.identity or 1) -- 1.3.3: Player / Target 125 %
	local tuck = math.floor(hub * Split.TUCK + 0.5)
	local g = {
		bar = math.floor(def.bar * s + 0.5), height = math.floor(def.height * s * t + 0.5), hub = hub, tuck = tuck,
		inner = math.floor(hub / 2 - tuck + 0.5), -- the hub's centre to each bar's inner end (whole units, as the movers)
		powerHeight = math.floor((def.powerHeight or def.height) * s * t + 0.5),
	}
	if def.castInterior then -- 1.3.3 the bamboo cast bar (T.SplitGeometry: the same numbers)
		local C = Split.CAST_BAR
		g.castInterior = def.castInterior * s * t
		g.castStalk = def.castStalk * s
		g.castHeight = g.castInterior + 2 * C.inner * g.castStalk
		g.castWidth = 2 * (g.inner + g.bar) -- the whole composition: health end to resource end
		g.castLift = math.max(math.floor(g.height / 2 + 0.5) + def.castValues, hub / 2) + C.gap -- its bottom above the hub's centre
	end
	return g
end

---------------------------------------------------------------------------
-- Pieces
---------------------------------------------------------------------------
-- under ElvUI's raised texts (level 100), above the bars (the bamboo ends' rule)
local function RaiseLevel(frame)
	local level = 0
	for _, key in ipairs({ 'Health', 'Power' }) do
		local element = frame and frame[key]
		local value = element and element.GetFrameLevel and element:GetFrameLevel()
		if type(value) == 'number' and not IsSecret(value) and value > level then level = value end
	end
	return math.min(level + 2, 95)
end

-- a smooth gradient over a bar's own fill (it follows the value exactly) and a dark track under it
-- (noTrack: the party bars keep Banzai Art's classic trough under them, Compat.lua). 1.3.1: the
-- overlay stays on the fill - the way the live client already showed an empty resource bar empty in
-- Darren's 1.3.0 screenshot (a whole-bar gradient revealed by a mask was tried and dropped: how a mask
-- on an empty bar's fill behaves cannot be checked offline, and a full-looking empty bar would
-- mislead); it is hidden until a paint has coloured it, so an unpainted bar shows ElvUI's own colour,
-- never the raw white texture
local function Surface(bar, noTrack)
	if not (bar and bar.GetStatusBarTexture) then return nil end
	local fill = bar:GetStatusBarTexture()
	if not fill then return nil end
	local track
	if not noTrack then
		track = bar:CreateTexture(nil, 'BORDER', nil, 7)
		track:SetAllPoints(bar)
		Theme:Trough(track)
	end
	local overlay = bar:CreateTexture(nil, 'ARTWORK', nil, 7)
	overlay:SetTexture(BAR)
	overlay:SetAllPoints(fill)
	overlay:Hide()
	return { track = track, overlay = overlay }
end
Split.Surface = Surface

function Split.PaintSurface(surface, color, alpha)
	if not surface then return end
	if not color then
		surface.overlay:Hide() -- nothing plain to colour it with: ElvUI's own colour stays
		return
	end
	local from, to = color, color
	if color[1] and type(color[1]) == 'table' then from, to = color[1], color[2] end
	if from == to then from, to = { to[1] * 0.55, to[2] * 0.55, to[3] * 0.55 }, Theme.Mix(to, { 1, 1, 1 }, 0.22) end
	Theme:Gradient(surface.overlay, 'HORIZONTAL', from, to, alpha or 0.94, alpha or 0.94)
	surface.overlay:Show()
end

-- 1.3.1 a split frame's two bars as one colour family: health lighter at its outer (left) end, the
-- canonical colour where each fill meets the hub side, resource deeper toward its outer (right) end;
-- opaque, crisp (at full the two bars meet in the canonical colour under the hub)
Split.SURFACE_ALPHA = 1
function Split.HealthColors(ramp) return ramp and { ramp.bright, ramp.base } or nil end
function Split.PowerColors(ramp) return ramp and { ramp.base, ramp.deep } or nil end

-- the colour of a unit: its class (players), else its reaction; nil when the game keeps it to itself
function Split.UnitColor(unit)
	if Call(UnitIsPlayer, unit) == true then
		if Call(UnitIsConnected, unit) == false then return nil end -- ElvUI's own offline grey stays
		local _, token = Call(UnitClass, unit)
		return token and Theme:ClassColor(token) or nil
	end
	if Call(UnitIsTapDenied, unit) == true then return Split.REACTION.tapped end
	local reaction = Call(UnitReaction, unit, 'player')
	if type(reaction) ~= 'number' then return nil end
	if reaction >= 5 then return Split.REACTION.friendly end
	if reaction == 4 then return Split.REACTION.neutral end
	return Split.REACTION.hostile
end

-- 1.3.1 the colour family of a whole split frame: the unit's class (an NPC: its reaction), never the
-- resource type's; nil when the game keeps the colour to itself (ElvUI's own colour stays)
function Split.UnitRamp(unit)
	local color = Split.UnitColor(unit)
	return color and Theme.Ramp(color) or nil
end

-- an NPC whose resource the game plainly reports as none
function Split.NoPower(unit)
	if Call(UnitIsPlayer, unit) == true then return false end
	local max = Call(UnitPowerMax, unit)
	return type(max) == 'number' and max <= 0
end

---------------------------------------------------------------------------
-- The hub's identity (idle)
---------------------------------------------------------------------------
local function PaintArt(hub, token)
	local identity = ns.Identity
	return identity.PaintArt(hub, identity.Art(token, nil, hub)) -- 1.3.2: the hub decides (its size; a nameplate hub)
end

local function Unknown()
	return (ns.Identity and ns.Identity.UNKNOWN) or { 0.42, 0.45, 0.50 }
end

-- players: the class art chain; NPCs: their portrait (the game draws it), the ring
-- in their reaction colour, the accent gold / silver for elite / rare
function Split.PaintIdentity(hub, unit, def)
	local isPlayer = Call(UnitIsPlayer, unit) == true
	local _, token = Call(UnitClass, unit)
	hub.accentColor = nil
	if isPlayer or not (def and def.npc) then
		PaintArt(hub, token)
	else
		hub.icon:Hide()
		if hub.glyph then hub.glyph:Hide() hub.glyphDisc:Hide() end
		if SetPortraitTexture then pcall(SetPortraitTexture, hub.portrait, unit) end
		hub.portrait:Show()
		local color = Split.UnitColor(unit) or Split.REACTION.hostile
		Theme:Gradient(hub.ring, 'VERTICAL', { color[1] * 0.62, color[2] * 0.62, color[3] * 0.62 }, Theme.Mix(color, { 1, 1, 1 }, 0.3), 1, 1)
		hub.ringColor, hub.artKind = color, 'PORTRAIT'
		if hub.barHub then -- 1.3.3: the portrait in the masked disc, in its reaction ring
			ns.Identity.FitArt(hub, false)
			ns.Identity.BarRing(hub)
		end
		local class = Call(UnitClassification, unit)
		hub.accentColor = class and Split.CLASSIFICATION[class] or nil
	end
	local accent = hub.accentColor
	if accent then
		Theme:Gradient(hub.accent, 'VERTICAL', { accent[1] * 0.6, accent[2] * 0.6, accent[3] * 0.6 }, accent, 1, 1)
	else
		Theme:Gradient(hub.accent, 'VERTICAL', Theme.COLORS.violet, Theme.COLORS.lime, 0.9, 0.9)
	end
	if Split.StateRing then Split.StateRing(hub) end -- a repaint during a cast / failure keeps that ring
	return hub.artKind
end

---------------------------------------------------------------------------
-- The cast presentation
---------------------------------------------------------------------------
-- the unit's current cast as the game reports it: name / icon passed on unread,
-- the duration object when the client has one, the times only when plain
function Split.ReadCast(unit)
	if not UnitCastingInfo then return nil end
	local kind = 'cast'
	local ok, name, _, texture, startMS, endMS, _, _, notInterruptible, _, barID = pcall(UnitCastingInfo, unit)
	if not ok then name = nil end
	if not (IsSecret(name) or name ~= nil) then
		if not UnitChannelInfo then return nil end
		local okc, cname, _, ctexture, cstart, cend, _, cnot, _, empowering, _, cbar = pcall(UnitChannelInfo, unit)
		if not (okc and (IsSecret(cname) or cname ~= nil)) then return nil end
		name, texture, startMS, endMS, notInterruptible, barID = cname, ctexture, cstart, cend, cnot, cbar
		kind = (not IsSecret(empowering) and empowering == true) and 'empower' or 'channel'
	end
	local api = (kind == 'empower' and UnitEmpoweredChannelDuration) or (kind == 'channel' and UnitChannelDuration) or UnitCastingDuration
	local duration
	if api then
		local okd, d = pcall(api, unit)
		local t = okd and type(d)
		if t == 'table' or t == 'userdata' then duration = d end
	end
	return { name = name, texture = texture, startMS = startMS, endMS = endMS, kind = kind, notInterruptible = notInterruptible, duration = duration, barID = Plain(barID) }
end

local function PlainNumber(v)
	return type(v) == 'number' and not IsSecret(v)
end

-- the remaining seconds, formatted by the font string (a secret stays inside it)
local function Tick(hub)
	local info = hub.info
	if not info then return end
	if hub.bar and hub.bar.plain then ns.CastBar.Step(hub.bar) end -- 1.3.3: plain times only (no duration object)
	local d = info.duration
	if d and d.GetRemainingDuration then
		local ok, remaining = pcall(d.GetRemainingDuration, d)
		if ok and (IsSecret(remaining) or type(remaining) == 'number') then
			hub.castTime:SetFormattedText('%.1f', remaining)
			return
		end
	elseif PlainNumber(hub.endTime) and GetTime then
		hub.castTime:SetFormattedText('%.1f', math.max(0, hub.endTime - GetTime()))
		return
	end
	hub.castTime:SetText('')
end
Split.Tick = Tick

local function Clock(hub)
	if hub.clock then return hub.clock end
	local clock = CreateFrame('Frame', nil, hub.over)
	clock:Hide()
	local elapsed = 0
	clock:SetScript('OnUpdate', function(_, delta) -- only while a timed cast is on the hub (the frame is hidden otherwise)
		elapsed = elapsed + (delta or 0)
		if elapsed >= Split.CLOCK then
			elapsed = 0
			Tick(hub)
		end
	end)
	hub.clock = clock
	return clock
end

-- 1.3.1: the spell name in the Banzai display font (the targeted nameplate's hub keeps its small font:
-- nameplates are frozen), the timer in the small information font (its numbers stay crisp)
local function CastFonts(hub, text)
	local size = hub.castSize or 11
	if hub.plate then
		hub.castName:SetFont(Theme:SmallFont(), size, 'OUTLINE')
	else
		Theme:SetDisplayFont(hub.castName, Theme:DisplaySize(size), 'OUTLINE', text) -- an accented spell name: the previous display font
	end
	hub.castName:SetShadowOffset(1, -1)
	if hub.bar then hub.castName:SetShadowColor(0, 0, 0, 1) end -- 1.3.3: the off-white name's dark outline on the bar
	hub.castTime:SetFont(Theme:SmallFont(), hub.timeSize or math.max(8, size - 2), 'OUTLINE')
	hub.castTime:SetShadowOffset(1, -1)
	local lime = Theme.COLORS.lime
	hub.castTime:SetTextColor(lime[1], lime[2], lime[3])
end

-- the non-interruptible marking off
local function Unlock(hub)
	for _, t in ipairs(hub.lockParts) do t:Hide() end
end

-- 1.3.3 a bar hub's identity (class art, glyph, portrait) veiled while the spell icon shows: one icon in the
-- centre, never the class art under or beside it (alpha only: a repaint of the identity keeps the veil)
function Split.Veil(hub, veiled)
	local a = veiled and 0 or 1
	for _, r in ipairs({ hub.icon, hub.portrait, hub.glyph, hub.glyphDisc }) do
		if r then r:SetAlpha(a) end
	end
	hub.veiled = veiled and true or false
	if ns.Identity.BarRing then ns.Identity.BarRing(hub) end -- the class ring round the spell icon; at idle the BANZAI art's own ring
end

-- the ring back to the identity, nothing of the cast left
function Split.Idle(hub)
	hub.info, hub.state, hub.endTime = nil, 'idle', nil
	hub.spell:Hide()
	hub.spell:SetDesaturated(false)
	if hub.barHub then -- 1.3.3: the class art back, the bar gone
		Split.Veil(hub, false)
		if hub.bar then ns.CastBar.Clear(hub.bar) end
	else
		if hub.progress.Clear then hub.progress:Clear() end
		hub.progress:Hide()
		hub.track:Hide()
	end
	Unlock(hub)
	hub.castName:SetText('')
	hub.castTime:SetText('')
	if hub.clock then hub.clock:Hide() end
	local c = hub.ringColor or Unknown()
	Theme:Gradient(hub.ring, 'VERTICAL', { c[1] * 0.62, c[2] * 0.62, c[3] * 0.62 }, Theme.Mix(c, { 1, 1, 1 }, 0.3), 1, 1)
	hub.ring:SetAlpha(1)
end

-- the non-interruptible marking (a steel border round the hub, a small shield): the game's boolean handed
-- to each part (never tested here); the radial progress stays visible inside the border
local function Lock(hub, notInterruptible)
	local steel = Split.CAST.lock
	for _, t in ipairs(hub.lockParts) do
		if t ~= hub.shield then Theme:Gradient(t, 'VERTICAL', { steel[1] * 0.75, steel[2] * 0.75, steel[3] * 0.75 }, Theme.Mix(steel, { 1, 1, 1 }, 0.35), 1, 1) end
		if t.SetAlphaFromBoolean then
			t:Show()
			t:SetAlphaFromBoolean(notInterruptible, 1, 0)
		elseif not IsSecret(notInterruptible) then
			t:SetShown(notInterruptible == true)
		else
			t:Hide() -- not supported: nothing claimed
		end
	end
end
Split.Lock = Lock

-- the radial progress of a hub that has one (Focus, the targeted nameplate): the game's Cooldown swipe on the ring
local function Radial(hub, info)
	local color = Split.CAST[info.kind] or Split.CAST.cast
	local cd = hub.progress
	if cd.SetSwipeColor then cd:SetSwipeColor(color[1], color[2], color[3], 1) end
	if cd.SetReverse then cd:SetReverse(info.kind ~= 'channel') end -- a cast / empower fills the ring (charging up), a channel drains it
	local timed = false
	if info.duration and cd.SetCooldownFromDurationObject then
		cd:SetCooldownFromDurationObject(info.duration)
		timed = true
	elseif PlainNumber(info.startMS) and PlainNumber(info.endMS) and info.endMS > info.startMS and cd.SetCooldown then
		cd:SetCooldown(info.startMS / 1000, (info.endMS - info.startMS) / 1000)
		hub.endTime = info.endMS / 1000
		timed = true
	elseif cd.Clear then
		cd:Clear()
	end
	cd:SetShown(timed)
	hub.track:SetShown(timed)
	if timed then
		hub.ring:SetAlpha(0.35) -- the class ring steps back under the progress
	else
		-- protected timing: the ring says "casting" in the cast colour, no progress is drawn
		Theme:Gradient(hub.ring, 'VERTICAL', { color[1] * 0.7, color[2] * 0.7, color[3] * 0.7 }, color, 1, 1)
		hub.ring:SetAlpha(1)
	end
	Lock(hub, info.notInterruptible)
	return timed
end

-- a cast (start, update, delay) on the hub. 1.3.3: a bar hub (Player / Target) shows the spell icon alone in its
-- centre and hands the progress, the lock and the texts to its bamboo cast bar; its ring stays the identity's
function Split.Begin(hub, info)
	hub.info, hub.state = info, info.kind
	hub.spell:SetTexture(info.texture) -- the game's icon, unread
	hub.spell:SetDesaturated(false)
	hub.spell:Show()
	hub.endTime = nil
	local timed
	if hub.barHub then
		Split.Veil(hub, true)
		timed = false
		if hub.bar then timed, hub.endTime = ns.CastBar.Begin(hub.bar, info, hub.castRamp) end
	else
		timed = Radial(hub, info)
	end
	hub.timed = timed
	CastFonts(hub, info.name)
	local name = info.name
	if IsSecret(name) then
		hub.castName:SetText(name)
	else
		hub.castName:SetText(string.upper(tostring(name or '')))
	end
	local white = hub.bar and ns.CastBar.COLORS.text or { 1, 1, 1 }
	hub.castName:SetTextColor(white[1], white[2], white[3])
	local clock = Clock(hub)
	clock:SetShown(timed)
	Tick(hub)
	return timed
end

-- the ring of the state the hub shows (after an identity repaint): failed red, an untimed cast in
-- the cast colour; a timed cast keeps the identity ring dimmed under its progress
function Split.StateRing(hub)
	if hub.barHub then return end -- 1.3.3: a bar hub's ring is always the identity's (the bar shows the state)
	local state = hub.state
	if state == 'failed' then
		local red = Split.CAST.fail
		Theme:Gradient(hub.ring, 'VERTICAL', { red[1] * 0.6, red[2] * 0.6, red[3] * 0.6 }, red, 1, 1)
		hub.ring:SetAlpha(1)
	elseif state == 'cast' or state == 'channel' or state == 'empower' then
		if hub.timed then
			hub.ring:SetAlpha(0.35)
		else
			local color = Split.CAST[state] or Split.CAST.cast
			Theme:Gradient(hub.ring, 'VERTICAL', { color[1] * 0.7, color[2] * 0.7, color[3] * 0.7 }, color, 1, 1)
			hub.ring:SetAlpha(1)
		end
	end
end

-- INTERRUPTED / FAILED for a moment. 1.3.3 a bar hub: FAILED (or cancelled) clears at once; INTERRUPTED brings
-- the class art back at once and leaves the moment to the bar (crimson, INTERRUPTED in cyan)
function Split.Fail(hub, label)
	if hub.barHub then
		if label ~= 'INTERRUPTED' then return Split.Idle(hub) end
		hub.info, hub.state, hub.endTime = nil, 'failed', nil
		hub.spell:Hide()
		hub.spell:SetDesaturated(false)
		Split.Veil(hub, false)
		if hub.clock then hub.clock:Hide() end
		if hub.bar then ns.CastBar.Interrupt(hub.bar) end
		CastFonts(hub)
		hub.castName:SetText(label)
		local cyan = ns.CastBar.COLORS.cyan
		hub.castName:SetTextColor(cyan[1], cyan[2], cyan[3])
		hub.castTime:SetText('')
		return
	end
	hub.info, hub.state, hub.endTime = nil, 'failed', nil
	if hub.progress.Clear then hub.progress:Clear() end
	hub.progress:Hide()
	hub.track:Hide()
	Unlock(hub)
	if hub.clock then hub.clock:Hide() end
	hub.spell:SetDesaturated(true)
	local red = Split.CAST.fail
	Theme:Gradient(hub.ring, 'VERTICAL', { red[1] * 0.6, red[2] * 0.6, red[3] * 0.6 }, red, 1, 1)
	hub.ring:SetAlpha(1)
	CastFonts(hub)
	hub.castName:SetText(label)
	hub.castName:SetTextColor(red[1], red[2], red[3])
	hub.castTime:SetText('')
end

local function State(unit)
	casts[unit] = casts[unit] or { active = false, failing = false, token = 0 }
	return casts[unit]
end

local function EachHub(unit, fn)
	for hub in pairs(hubs[unit] or {}) do fn(hub) end
	if unit == 'target' and plateHub then fn(plateHub) end
end

-- How an event ends the cast on the hub: 'INTERRUPTED' / 'FAILED', 'other' (an
-- event of another cast - a failed attempt while casting), or nil. 12.x payloads
-- after the unit: INTERRUPTED (castGUID, spellID, interruptedBy, castBarID),
-- FAILED (castGUID, spellID, castBarID), CHANNEL_STOP (castGUID, spellID,
-- interruptedBy, castBarID), EMPOWER_STOP (castGUID, spellID, complete,
-- interruptedBy, castBarID). The cast bar ID is compared only when it and the
-- one recorded at the start are plain; interruptedBy is only asked whether it
-- is there (a hidden one is there), never read.
function Split.Ending(event, state, a1, a2, a3, a4, a5)
	local by, barID
	if event == 'UNIT_SPELLCAST_INTERRUPTED' then by, barID = a3, a4
	elseif event == 'UNIT_SPELLCAST_FAILED' then barID = a3
	elseif event == 'UNIT_SPELLCAST_CHANNEL_STOP' then by, barID = a3, a4
	elseif event == 'UNIT_SPELLCAST_EMPOWER_STOP' then by, barID = a4, a5
	else return nil end
	local plainID = not IsSecret(barID) and barID ~= nil and state.barID ~= nil
	if plainID and barID ~= state.barID then return 'other' end
	local stop = event == 'UNIT_SPELLCAST_CHANNEL_STOP' or event == 'UNIT_SPELLCAST_EMPOWER_STOP'
	if stop then
		if (IsSecret(by) or by ~= nil) and (plainID or state.active) then return 'INTERRUPTED' end
		return nil
	end
	return (event == 'UNIT_SPELLCAST_INTERRUPTED') and 'INTERRUPTED' or 'FAILED', plainID
end

-- every cast event of a unit: what the game says now decides, with the cast bar ID when it is plain
function Split:CastEvent(unit, event, ...)
	local state = State(unit)
	local ending, sure = Split.Ending(event, state, ...)
	if ending == 'other' then return state.active and 'cast' or (state.failing and 'failed' or 'idle') end
	local info = Split.ReadCast(unit)
	local now = GetTime and GetTime() or 0
	-- this cast ended that way: the same cast bar, or nothing cast any more (a FAILED only while a cast showed;
	-- an INTERRUPTED a moment after the stop still belongs to that cast)
	local failed = ending and (sure or not info) and (sure or state.active or ending == 'INTERRUPTED' and state.stoppedAt and now - state.stoppedAt < Split.STOP_GRACE)
	if info and not failed then
		state.active, state.failing, state.token = true, false, state.token + 1
		state.barID = info.barID
		EachHub(unit, function(hub) Split.Begin(hub, info) end)
		return 'cast'
	end
	if failed then
		state.active, state.failing, state.token, state.barID = false, true, state.token + 1, nil
		local label = ending
		EachHub(unit, function(hub) Split.Fail(hub, label) end)
		local token = state.token
		if C_Timer and C_Timer.After then
			C_Timer.After(Split.FAIL_HOLD, function()
				if state.token ~= token then return end -- a newer cast or target owns the hub
				state.failing = false
				EachHub(unit, Split.Idle)
			end)
		end
		return 'failed'
	end
	if state.failing then return 'failed' end -- the failure stays for its moment
	if state.active then state.stoppedAt = now end
	state.active, state.barID = false, nil
	EachHub(unit, Split.Idle)
	return 'idle'
end

-- a new target / focus: its cast state from scratch
function Split:Reset(unit)
	local state = State(unit)
	state.active, state.failing, state.stoppedAt, state.token, state.barID = false, false, nil, state.token + 1, nil
	return self:CastEvent(unit, 'RESET')
end

function Split:CastState(unit)
	return State(unit)
end

local function Watch(unit)
	if watchers[unit] then return watchers[unit] end
	local w = CreateFrame('Frame')
	for _, event in ipairs(Split.CAST_EVENTS) do
		if w.RegisterUnitEvent then pcall(w.RegisterUnitEvent, w, event, unit) end -- this unit only: the unit argument is never compared
	end
	w:SetScript('OnEvent', function(_, event, _, ...) Split:CastEvent(unit, event, ...) end) -- the unit argument is never read
	watchers[unit] = w
	return w
end

function Split:AddHub(unit, hub, entry)
	hubs[unit] = hubs[unit] or {}
	hubs[unit][hub] = entry or true
	Watch(unit)
end

-- the enhanced targeted nameplate's hub follows the current target's plate (TargetPlate.lua)
function Split:SetPlateHub(hub)
	if plateHub == hub then return end
	if plateHub then Split.Idle(plateHub) end
	plateHub = hub
	Watch('target')
	if hub then
		local state = State('target')
		local info = Split.ReadCast('target')
		if info then Split.Begin(hub, info) elseif not state.failing then Split.Idle(hub) end
	end
end

---------------------------------------------------------------------------
-- Live frames
---------------------------------------------------------------------------
-- 1.3.1 how far the spell name sits above the hub's top: 3 as approved, more only when the
-- percentages above the bars (bar top + 2, their font's height) would reach it
function Split.CastLift(g, def)
	local percentTop = g.height / 2 + 2 + (def.percent or 11) + 2
	return math.max(3, math.ceil(percentTop - g.hub / 2))
end

local function BuildUnit(key)
	local def = Split.UNITS[key]
	local frame = _G[def.frame]
	if not (frame and frame.Health) or built[frame] then return built[frame] end
	local g = Split.Geometry(key)
	local withBar = def.castInterior ~= nil and ns.CastBar ~= nil -- 1.3.3: Player / Target
	local hub = ns.Identity.Hub(frame, g.hub, withBar)
	hub:SetFrameLevel(RaiseLevel(frame))
	hub:ClearAllPoints()
	hub:SetPoint('CENTER', frame.Health, 'RIGHT', g.inner, 0)
	hub.castSize = def.cast
	if withBar then -- 1.3.3: the bamboo cast bar above the values, the full width of the composition
		local bar = ns.CastBar.Build(hub, g, def, hub:GetFrameLevel() + 1) -- on the hub: it goes when the hub goes
		ns.CastBar.Attach(hub, bar, g)
	elseif def.lines then -- 1.3.1: the spell name above the hub stays clear of the percentages above the bars (thicker bars, a smaller hub)
		hub.castName:ClearAllPoints()
		hub.castName:SetPoint('BOTTOM', hub, 'TOP', 0, Split.CastLift(g, def))
	end
	local entry = { frame = frame, def = def, key = key, unit = def.unit, hub = hub, geometry = g }
	entry.health = Surface(frame.Health)
	if def.power and frame.Power then entry.power = Surface(frame.Power) end
	built[frame] = entry
	Split:AddHub(def.unit, hub, entry)
	if def.lines then Split.BuildLines(entry) end
	return entry
end

-- 1.3.1 the name under the health bar from its outer end, the spec under the resource bar to its outer
-- end: Banzai Art's font strings on ElvUI's tag system ([banzai:split:name] / [banzai:split:spec], Tags.lua),
-- each kept clear of the hub (width), only when the profile's split layer leaves the lines to Banzai Art
function Split.BuildLines(entry)
	local mine = Split.ProfileLines()
	if not mine or entry.lines then return entry.lines end
	local frame, g = entry.frame, entry.geometry
	local layer = CreateFrame('Frame', nil, frame)
	layer:SetAllPoints(frame)
	layer:SetFrameLevel(RaiseLevel(frame))
	local width = g.bar - g.tuck - Split.LINE_GAP * 2 -- never under the hub
	local function line(bar, point, relative, justify)
		local fs = layer:CreateFontString(nil, 'OVERLAY')
		Theme:SetDisplayFont(fs, Theme:DisplaySize(entry.def.name), 'OUTLINE') -- a font before any text
		fs:SetPoint(point, bar, relative, 0, -Split.LINE_GAP)
		fs:SetWidth(width)
		fs:SetJustifyH(justify)
		fs:SetWordWrap(false)
		return fs
	end
	local lines = { layer = layer }
	lines.name = line(frame.Health, 'TOPLEFT', 'BOTTOMLEFT', 'LEFT')
	if frame.Tag then frame:Tag(lines.name, '[banzai:split:name]') end
	if frame.Power then -- shown while the profile's marker says the spec line is on (Split.LineFonts)
		lines.specText = line(frame.Power, 'TOPRIGHT', 'BOTTOMRIGHT', 'RIGHT')
		if frame.Tag then frame:Tag(lines.specText, '[banzai:split:spec]') end
	end
	entry.lines = lines
	Split.LineFonts(entry)
	if frame.UpdateTags then pcall(frame.UpdateTags, frame) end
	return lines
end

-- the lines' display font and size (BANZAI > APPEARANCE > FONTS applies at once) and whether the spec
-- line shows (BANZAI > APPEARANCE "Specialization in names", carried by the profile's marker)
function Split.LineFonts(entry)
	local lines = entry.lines
	if not lines then return end
	-- Pass the actual text so unsupported codepoints keep the previous display font.
	local name = Call(UnitName, entry.unit)
	local spec = ns.Tags and ns.Tags.Spec and ns.Tags.Spec(entry.unit)
	for _, pair in ipairs({ { lines.name, name }, { lines.specText, spec } }) do
		local fs = pair[1]
		if fs then
			Theme:SetDisplayFont(fs, Theme:DisplaySize(entry.def.name), 'OUTLINE', pair[2])
			fs:SetShadowOffset(1, -1)
			fs:SetShadowColor(0, 0, 0, 1)
		end
	end
	if lines.specText then
		local _, on = Split.ProfileLines()
		lines.spec = on
		lines.specText:SetShown(on)
	end
end

local function BuildPlain(frameName, unit, kind)
	local frame = _G[frameName]
	if not (frame and frame.Health) or built[frame] then return built[frame] end
	local entry = { frame = frame, unit = unit, kind = kind, health = Surface(frame.Health, kind == 'party') }
	built[frame] = entry
	return entry
end

-- the split frames that exist get their hub and surfaces (out of combat: their parents are secure)
function Split:Build()
	if not self:Session() or InCombatLockdown() then return false end
	for _, key in ipairs(Split.ORDER) do BuildUnit(key) end
	BuildPlain(Split.TOT.frame, Split.TOT.unit, 'tot')
	if self:PartySplit() then
		for i = 1, Split.PARTY.count do BuildPlain(Split.PARTY.prefix .. i, nil, 'party') end
	end
	return true
end

local function UnitOf(entry)
	if entry.unit then return entry.unit end
	local frame = entry.frame
	local unit = Plain(frame.unit)
	if type(unit) ~= 'string' and frame.GetAttribute then unit = Plain(frame:GetAttribute('unit')) end
	return type(unit) == 'string' and unit or nil
end

-- one entry painted for its unit now (1.3.1: the hub, health and resource of a split frame in one colour
-- family - the class, else the reaction; ToT / party bars as in 1.3.0)
function Split:Paint(entry)
	local unit = UnitOf(entry)
	local exists = unit and Call(UnitExists, unit) == true
	local ramp = exists and entry.def and Split.UnitRamp(unit) or nil
	if entry.health then
		if entry.def then
			Split.PaintSurface(entry.health, Split.HealthColors(ramp), Split.SURFACE_ALPHA)
		else
			Split.PaintSurface(entry.health, exists and Split.UnitColor(unit) or nil)
		end
	end
	if entry.hub then
		entry.hub.castRamp = ramp -- 1.3.3: the cast bar's fill in the unit's family (nil: the attention amber's)
		if exists then Split.PaintIdentity(entry.hub, unit, entry.def) end
		if casts[unit] == nil or not (casts[unit].active or casts[unit].failing) then Split.Idle(entry.hub) end
	end
	if entry.power then
		local none = exists and entry.def.npc and Split.NoPower(unit)
		Split.PaintSurface(entry.power, (not none) and Split.PowerColors(ramp) or nil, Split.SURFACE_ALPHA)
		local power = entry.frame.Power
		if power and power.SetAlpha then power:SetAlpha(none and 0 or 1) end -- the resource side goes for an NPC without one
		entry.noPower = none and true or false
		local texts = ns.Health and ns.Health.GetPower and ns.Health:GetPower(entry.frame.GetName and entry.frame:GetName())
		if texts then texts.holder:SetShown(not none and Theme:DB().splitPowerText ~= false and Active()) end
	end
	if entry.lines then Split.LineFonts(entry) end
end

-- 1.3.1: a frame whose paint failed shows ElvUI's own colours (never an uncoloured overlay); the fault is kept for /banzai status
function Split.Unpainted(entry, err)
	Split.lastError = tostring(err)
	for _, s in ipairs({ entry.health, entry.power }) do if s then s.overlay:Hide() end end
end

-- 1.3.1: every entry painted on its own - a fault in one (1.3.0: an idle hub's "Font not set") never
-- leaves the others unpainted
function Split:Refresh()
	if not self:Session() then return false end
	self:Build()
	local on = Active()
	for _, entry in pairs(built) do
		if entry.hub then entry.hub:SetShown(on) end
		local bar = entry.hub and entry.hub.bar
		if bar then -- 1.3.3: the panel style's colours, the texts chosen; shown only while a cast is on it
			ns.CastBar.Paint(bar)
			ns.CastBar.Texts(bar)
			bar:SetShown(on and bar.state ~= nil and ns.CastBar.Enabled())
		end
		if entry.lines then entry.lines.layer:SetShown(on) end
		for _, s in ipairs({ entry.health, entry.power }) do
			if s then
				if s.track then s.track:SetShown(on) end
				if not on then s.overlay:Hide() end -- shown only by a paint that coloured it
			end
		end
		if on then
			local ok, err = pcall(self.Paint, self, entry)
			if not ok then Split.Unpainted(entry, err) end
		elseif entry.frame.Power and entry.frame.Power.SetAlpha then
			entry.frame.Power:SetAlpha(1)
		end
	end
	return true
end

function Split:Get(frameName)
	return built[_G[frameName]]
end

function Split:Counts()
	local n, h = 0, 0
	for _, entry in pairs(built) do
		n = n + 1
		if entry.hub then h = h + 1 end
	end
	local w = 0
	for _ in pairs(watchers) do w = w + 1 end
	return { entries = n, hubs = h, watchers = w }
end

local function PaintUnit(unit)
	for _, entry in pairs(built) do
		if UnitOf(entry) == unit then
			local ok, err = pcall(Split.Paint, Split, entry)
			if not ok then Split.Unpainted(entry, err) end
		end
	end
end

local events = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'PLAYER_TARGET_CHANGED', 'PLAYER_FOCUS_CHANGED', 'GROUP_ROSTER_UPDATE', 'PLAYER_REGEN_ENABLED',
	'UNIT_FACTION', 'UNIT_PORTRAIT_UPDATE', 'UNIT_DISPLAYPOWER', 'UNIT_MAXPOWER', 'UNIT_CONNECTION', 'UNIT_TARGET', 'PLAYER_SPECIALIZATION_CHANGED' }) do
	pcall(events.RegisterEvent, events, event)
end
events:SetScript('OnEvent', function(_, event, arg1)
	if not Split:Session() then return end
	local unit = (type(arg1) == 'string' and not IsSecret(arg1)) and arg1 or nil -- a hidden unit token is never compared
	if event == 'PLAYER_TARGET_CHANGED' then
		PaintUnit('target')
		PaintUnit('targettarget')
		Split:Reset('target')
	elseif event == 'PLAYER_FOCUS_CHANGED' then
		PaintUnit('focus')
		Split:Reset('focus')
	elseif event == 'UNIT_TARGET' then
		if unit == 'target' then PaintUnit('targettarget') end
	elseif event == 'UNIT_FACTION' or event == 'UNIT_PORTRAIT_UPDATE' or event == 'UNIT_DISPLAYPOWER' or event == 'UNIT_MAXPOWER' or event == 'UNIT_CONNECTION' then
		if unit then PaintUnit(unit) end
	else
		if Split.scheduled then return end
		Split.scheduled = true
		C_Timer.After(0.2, function()
			Split.scheduled = false
			Split:Refresh()
		end)
	end
end)

---------------------------------------------------------------------------
-- The unit-frame preview in BANZAI SPLIT (Preview.lua: style selector)
---------------------------------------------------------------------------
-- Plain, non-interactive sample frames in the split construction at the places
-- the split frames use (the Banzai positions; party / arena allies where the
-- shown role layout puts them). SAMPLE DATA throughout: sample names, classes,
-- numbers and spells; the radial progress is a synthetic Cooldown at a fixed
-- point of its run, not a live cast.
--
-- 1.3.3 TARGET NPC (Darren's native crash, 2026-11-05 20:49:17, ERROR #132 in
-- the Disk Queue thread while it read FileData ID 134153 - the game icon
-- INV_Misc_Head_Dragon_01 this sample showed until 1.3.2, requested the moment
-- Target NPC was selected; the 1.3.1 crash at 07:39:44 read the same file at
-- the same place): the sample is synthetic and Banzai's own from end to end -
-- plain frames made by Banzai Art, static sample numbers, no unit token, no
-- live ElvUI frame, no secure attribute, no portrait, model or model scene,
-- no game icon and no FileData number - Banzai media and the plain white
-- texture every Banzai bar uses: its hub shows Banzai's NPC crest (media/
-- BanzaiHubCrest; all of them requested once when Banzai Art loads), its hub
-- has no radial progress and no game shield, it never casts, and it calls
-- nothing of the PvP frames. Player /
-- Target show the 1.3.3 bar hub: idle, casting (the spell icon in the centre,
-- the bamboo cast bar at a fixed point), channelling, interrupted.
Split.PREVIEW = { player = true, target = true, targetNPC = true, targettarget = true, focus = true, party = true, arenaAllies = true, nameplate = true }
Split.SAMPLE = {
	player = { label = 'PLAYER PREVIEW', health = 0.96, max = 502000, power = 1.00, powerMax = 104690, powerToken = 'MANA', own = true },
	target = { label = 'TARGET PREVIEW', class = 'MAGE', spec = 'FROST', health = 0.64, max = 426000, power = 0.72, powerMax = 98000, powerToken = 'MANA' },
	targetNPC = { label = 'NPC PREVIEW', npc = true, health = 0.52, max = 1840000, elite = true },
	focus = { label = 'FOCUS PREVIEW', class = 'ROGUE', spec = 'SUBTLETY', health = 0.42, max = 812000, power = 0.80, powerMax = 100, powerToken = 'ENERGY' },
	targettarget = { label = 'TARGET OF TARGET', class = 'PRIEST', health = 0.18, max = 643000 },
	nameplate = { label = 'NAMEPLATE PREVIEW', class = 'WARLOCK', health = 0.62, max = 688000 },
	casts = { cast = { 'Chaos Bolt', 'Interface\\Icons\\Ability_Warlock_ChaosBolt', 0.62 }, channel = { 'Drain Life', 'Interface\\Icons\\Spell_Shadow_LifeDrain02', 0.40 } },
	npcCrest = Theme.MEDIA .. 'BanzaiHubCrest', -- 1.3.3: Banzai's own (1.3.2: the game icon INV_Misc_Head_Dragon_01, FileData 134153)
	party = { 'PALADIN', 'SHAMAN', 'WARLOCK', 'DRUID', 'HUNTER' },
	partyHealth = { 0.88, 1.00, 0.46, 0.14, 0.71 },
	partyRole = { 'TANK', 'HEALER', 'DAMAGER', 'DAMAGER', 'DAMAGER' },
}
local ROLE_ICONS = 'Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES'
local ROLE_COORDS = { TANK = { 0, 19 / 64, 22 / 64, 41 / 64 }, HEALER = { 20 / 64, 39 / 64, 1 / 64, 20 / 64 }, DAMAGER = { 20 / 64, 39 / 64, 22 / 64, 41 / 64 } }
local PREVIEW_ALPHA = 0.45 -- out of range, as ElvUI's range fader

-- 1.3.3 every texture the TARGET NPC sample shows, requested once now (a hidden holder of Banzai Art's own), so
-- selecting the sample later asks the disk for nothing new: Banzai media only - the crest, the hub, the bar
Split.NPC_MEDIA = { Split.SAMPLE.npcCrest, Theme.MEDIA .. 'BanzaiHubDisc', Theme.MEDIA .. 'BanzaiHubRing', Theme.MEDIA .. 'BanzaiHubAccent',
	Theme.MEDIA .. 'BanzaiHubMask', BAR, Theme.WHITE }
do
	local keeper = CreateFrame('Frame', nil, UIParent)
	keeper:SetSize(1, 1)
	keeper:Hide()
	keeper.textures = {}
	for i, path in ipairs(Split.NPC_MEDIA) do
		local t = keeper:CreateTexture(nil, 'BACKGROUND')
		t:SetTexture(path, 'CLAMP', 'CLAMP', 'TRILINEAR')
		keeper.textures[i] = t
	end
	Split.mediaKeeper = keeper
end

local function Short(n)
	if n >= 1e6 then return (string.format('%.1fM', n / 1e6):gsub('%.0M', 'M')) end
	if n >= 1e3 then return string.format('%dK', math.floor(n / 1e3 + 0.5)) end
	return tostring(math.floor(n))
end
Split.Short = Short

local function PBar(parent, w, h, level)
	local bar = CreateFrame('StatusBar', nil, parent)
	bar:SetStatusBarTexture(BAR)
	bar:SetMinMaxValues(0, 1)
	bar:SetSize(w, h)
	bar:SetFrameLevel(level)
	local track = bar:CreateTexture(nil, 'BACKGROUND')
	track:SetAllPoints(bar)
	Theme:Trough(track)
	bar.track = track
	return bar
end

local function PPaint(bar, color, value)
	bar:SetValue(value)
	local fill = bar:GetStatusBarTexture()
	if not fill then return end
	local from, to = color, color
	if type(color[1]) == 'table' then from, to = color[1], color[2] else from, to = { color[1] * 0.55, color[2] * 0.55, color[3] * 0.55 }, Theme.Mix(color, { 1, 1, 1 }, 0.22) end
	Theme:Gradient(fill, 'HORIZONTAL', from, to, 1, 1)
end

local function PText(parent, size, font)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFont(font or Theme:SmallFont(), size, 'OUTLINE')
	fs:SetShadowOffset(1, -1)
	return fs
end

local function SetTexts(set, value, percent)
	if not set then return end
	for _, s in ipairs(set.sets) do
		s.value:SetText(value)
		s.percent:SetText(percent)
	end
end

-- 1.3.1 a sample bar the way the live split bars are painted: the family's gradient on the fill (the bar's
-- own fill texture itself stays invisible under it)
local function PFull(bar)
	local fill = bar:GetStatusBarTexture()
	if fill then fill:SetAlpha(0) end
	return Surface(bar, true)
end

local function NewContainer(key)
	local c = CreateFrame('Frame', 'BanzaiPreviewSplit_' .. key, UIParent)
	c:SetFrameStrata('DIALOG')
	c:SetFrameLevel(20)
	c:EnableMouse(false)
	c:SetSize(10, 10)
	c.key, c.units, c.split = key, {}, true
	return c
end

-- the sample's identity line: NAME - SPEC (player) / SPEC - NAME (targets), in the class colour and the spec gradient
-- (1.3.1: the Focus sample; Player / Target show their two lines, SampleLines)
local function Line(sample, color, after)
	local name = Theme:GradientText(sample.label, Theme.Mix(color, { 1, 1, 1 }, 0.25), color)
	if not sample.spec then return name end
	local spec = Theme:GradientText(sample.spec, Theme.COLORS.lime, Theme.COLORS.emerald)
	if after then return name .. '|cff8c919a - |r' .. spec end
	return spec .. '|cff8c919a - |r' .. name
end

-- 1.3.1 the live lines' text: the name in the BANZAI green -> purple gradient, the spec in the class family
function Split.NameText(name) return Theme:RampText(string.upper(name), Theme.NAME_STOPS) end
function Split.SpecText(spec, color)
	return Theme:RampText(string.upper(spec), Theme.RampLetters(Theme.Ramp(color)))
end

-- one split sample: health <- hub -> resource (resource optional), its name line and texts
-- (1.3.1 Player / Target: one colour family over both bars, the values above, the name / spec lines under them)
local function SampleUnit(c, key, sample)
	local def = Split.UNITS[key] or Split.UNITS.target
	local g = Split.Geometry(Split.UNITS[key] and key or 'target')
	local u = CreateFrame('Frame', nil, c)
	u:SetSize(10, 10)
	u:SetFrameLevel(c:GetFrameLevel() + 1)
	u.sample, u.key, u.g = sample, key, g
	local level = u:GetFrameLevel()
	local color = sample.npc and Split.REACTION.hostile or Theme:ClassColor(sample.class)
	u.color = color
	u.ramp = Theme.Ramp(color)
	local withBar = def.castInterior ~= nil and ns.CastBar ~= nil -- 1.3.3: Player / Target as live (the NPC sample too: no radial parts)
	u.hub = ns.Identity.Hub(u, g.hub, withBar)
	u.hub:SetPoint('CENTER', u, 'CENTER', 0, 0)
	u.hub:SetFrameLevel(level + 4)
	u.hub.castSize = def.cast
	u.hub.castRamp = u.ramp
	if withBar and not sample.npc then -- the NPC sample never casts: no bar at all
		u.castBar = ns.CastBar.Build(u.hub, g, def, level + 5)
		ns.CastBar.Attach(u.hub, u.castBar, g)
	end
	local gap = g.tuck + (ns.Health and ns.Health.SPLIT_GAP or 4)
	u.Health = PBar(u, g.bar, g.height, level + 2)
	u.Health:SetPoint('RIGHT', u.hub, 'CENTER', -g.inner, 0)
	if def.lines then
		u.healthSurface = PFull(u.Health)
		u.healthText = ns.Health and ns.Health.Attach and ns.Health:Attach(u.Health, { side = 'LEFT', x = 0, y = 2, split = true, above = true, display = true, percentX = gap, value = def.value, percent = def.percent }) or nil
	else
		u.healthText = ns.Health and ns.Health.Attach and ns.Health:Attach(u.Health, { side = 'LEFT', x = 6, y = 0, split = true, percentX = gap, value = def.value, percent = def.percent }) or nil
	end
	if sample.powerToken then
		u.Power = PBar(u, g.bar, g.powerHeight, level + 2)
		u.Power:SetPoint('LEFT', u.hub, 'CENTER', g.inner, 0)
		if def.lines then
			u.powerSurface = PFull(u.Power)
			u.powerText = ns.Health and ns.Health.Attach and ns.Health:Attach(u.Power, { side = 'RIGHT', x = 0, y = 2, split = true, above = true, display = true, percentX = gap, value = def.value, percent = def.percent }) or nil
		else
			u.powerText = ns.Health and ns.Health.Attach and ns.Health:Attach(u.Power, { side = 'RIGHT', x = -6, y = 0, split = true, percentX = gap, value = def.value, percent = def.percent }) or nil
		end
	end
	for _, t in ipairs({ u.healthText, u.powerText }) do if t and ns.Health.SplitGhost then ns.Health.SplitGhost(t) end end -- as live
	u.textLayer = CreateFrame('Frame', nil, u)
	u.textLayer:SetAllPoints(u)
	u.textLayer:SetFrameLevel(level + 9)
	if def.lines then
		local width = g.bar - g.tuck - Split.LINE_GAP * 2
		u.name = PText(u.textLayer, Theme:DisplaySize(def.name), Theme:DisplayFont())
		u.name:SetPoint('TOPLEFT', u.Health, 'BOTTOMLEFT', 0, -Split.LINE_GAP)
		u.name:SetWidth(width)
		u.name:SetJustifyH('LEFT')
		u.name:SetText(Split.NameText(sample.label))
		if sample.spec and u.Power then
			u.spec = PText(u.textLayer, Theme:DisplaySize(def.name), Theme:DisplayFont())
			u.spec:SetPoint('TOPRIGHT', u.Power, 'BOTTOMRIGHT', 0, -Split.LINE_GAP)
			u.spec:SetWidth(width)
			u.spec:SetJustifyH('RIGHT')
			u.spec:SetText(Split.SpecText(sample.spec, color))
		end
	else
		u.name = PText(u.textLayer, def.name)
		u.name:SetPoint('CENTER', u.hub, 'CENTER', 0, -math.floor(g.hub / 2 - 5 + 0.5))
		u.name:SetText(Line(sample, color, key == 'player' or key == 'focus'))
	end
	if sample.npc then -- 1.3.3: Banzai's NPC crest (synthetic; never the live portrait or a game icon)
		ns.Identity.PaintArt(u.hub, { kind = 'CREST', path = Split.SAMPLE.npcCrest, coords = { 0, 1, 0, 1 }, color = color })
		local gold = Split.CLASSIFICATION.elite
		Theme:Gradient(u.hub.accent, 'VERTICAL', { gold[1] * 0.6, gold[2] * 0.6, gold[3] * 0.6 }, gold, 1, 1)
	else
		ns.Identity.PaintArt(u.hub, ns.Identity.Art(sample.class, sample.specID, u.hub))
	end
	return u
end

-- the ToT: one compact bar, the name above, the percent inside
local function SampleToT(c, sample)
	local T0, s = Split.TOT, tonumber(Theme:DB().splitScale) or 1
	local u = CreateFrame('Frame', nil, c)
	u:SetSize(10, 10)
	u.sample, u.key = sample, 'targettarget'
	u.color = Theme:ClassColor(sample.class)
	u.Health = PBar(u, math.floor(T0.bar * s + 0.5), math.floor(T0.height * s + 0.5), c:GetFrameLevel() + 2)
	u.Health:SetPoint('LEFT', u, 'LEFT', 0, 0)
	u.textLayer = CreateFrame('Frame', nil, u)
	u.textLayer:SetAllPoints(u)
	u.textLayer:SetFrameLevel(c:GetFrameLevel() + 9)
	u.name = PText(u.textLayer, 9)
	u.name:SetPoint('BOTTOMLEFT', u.Health, 'TOPLEFT', 0, 2)
	u.name:SetText(Theme:GradientText(sample.label, Theme.Mix(u.color, { 1, 1, 1 }, 0.25), u.color))
	u.percent = PText(u.textLayer, 9)
	u.percent:SetPoint('RIGHT', u.Health, 'RIGHT', -3, 0)
	return u
end

-- party / arena allies: the role layout's frames, the circle in the middle, the name across its lower part
local function SampleParty(c, i, w, h)
	local class = Split.SAMPLE.party[((i - 1) % #Split.SAMPLE.party) + 1]
	local sample = { label = string.format((c.key == 'arenaAllies') and 'ALLY %d' or 'PARTY %d', i), class = class, health = Split.SAMPLE.partyHealth[i] or 0.8, max = 520000,
		role = Split.SAMPLE.partyRole[i] or 'DAMAGER', specID = ns.Preview and ns.Preview.SAMPLE_SPEC_IDS and ns.Preview.SAMPLE_SPEC_IDS[class] }
	local u = CreateFrame('Frame', nil, c)
	u:SetSize(w, h)
	u:SetFrameLevel(c:GetFrameLevel() + 1)
	u.sample, u.key, u.index = sample, c.key, i
	u.color = Theme:ClassColor(class)
	u.Health = PBar(u, w, h, u:GetFrameLevel() + 2)
	u.Health:SetAllPoints(u)
	local P = Split.PARTY
	u.circle = ns.Identity.Circle(u, P.circle)
	u.circle.iconSize = P.circle * ns.Identity.ICON
	u.circle:SetPoint('CENTER', u.Health, 'CENTER', 0, 0)
	u.circle:SetFrameLevel(u:GetFrameLevel() + 6)
	ns.Identity.PaintArt(u.circle, ns.Identity.Art(class, sample.specID, u.circle))
	u.healthText = ns.Health and ns.Health.Attach and ns.Health:Attach(u.Health, { side = 'LEFT', x = 4, y = 0, split = true, percentX = 4, value = 9, percent = 8 }) or nil
	if u.healthText and ns.Health.SplitGhost then ns.Health.SplitGhost(u.healthText) end -- as live
	u.textLayer = CreateFrame('Frame', nil, u)
	u.textLayer:SetAllPoints(u)
	u.textLayer:SetFrameLevel(u:GetFrameLevel() + 9)
	u.name = PText(u.textLayer, 9)
	u.name:SetPoint('CENTER', u.Health, 'CENTER', 0, -(P.circle / 2 - 4))
	u.name:SetText(Theme:GradientText(sample.label, Theme.Mix(u.color, { 1, 1, 1 }, 0.25), u.color))
	u.status = PText(u.textLayer, 9)
	u.status:SetPoint('CENTER', u.Health, 'CENTER', 0, P.circle / 2 + 2)
	u.role = u.textLayer:CreateTexture(nil, 'OVERLAY')
	u.role:SetTexture(ROLE_ICONS)
	local rc = ROLE_COORDS[sample.role] or ROLE_COORDS.DAMAGER
	u.role:SetTexCoord(rc[1], rc[2], rc[3], rc[4])
	u.role:SetSize(11, 11)
	u.role:SetPoint('CENTER', u.Health, 'CENTER', -(P.circle / 2 - 1), P.circle / 2 - 6) -- a badge on the circle's upper left (as live)
	u.role:SetShown(Theme:DB().roleIcons ~= false)
	-- the PvP furniture of the classic party (the same parts): trinket right of the bar, CC / dispel
	local PvP = ns.PvPFrames
	if PvP and PvP.Trinket then
		u.trinket = PvP.Trinket(u, ns.Identity.SIZE)
		u.trinket:SetPoint('LEFT', u.Health, 'RIGHT', ns.Identity.GAP, 0)
		u.trinket:SetFrameLevel(u:GetFrameLevel() + 6)
	end
	u.cc = CreateFrame('Frame', nil, u)
	u.cc:SetSize(math.min(30, h - 4), math.min(30, h - 4))
	u.cc:SetPoint('RIGHT', u.Health, 'RIGHT', -3, 0)
	u.cc:SetFrameLevel(u:GetFrameLevel() + 8)
	u.cc.icon = u.cc:CreateTexture(nil, 'ARTWORK')
	u.cc.icon:SetAllPoints(u.cc)
	u.cc.icon:SetTexture('Interface\\Icons\\Spell_Nature_Polymorph')
	u.cc.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	u.cc.label = PText(u.textLayer, 11, Theme:PreviousDisplayFont()) -- 1.3.1: as the live PvP label
	u.cc.label:SetPoint('BOTTOM', u.cc, 'TOP', 0, 1)
	u.cc.label:SetText('CC')
	local cc = (PvP and PvP.COLORS and PvP.COLORS.cc) or { 1, 0.18, 0.62 }
	u.cc.label:SetTextColor(cc[1], cc[2], cc[3])
	u.cc:Hide()
	u.cc.label:Hide()
	u.border = CreateFrame('Frame', nil, u)
	u.border:SetPoint('TOPLEFT', u.Health, 'TOPLEFT', -3, 3)
	u.border:SetPoint('BOTTOMRIGHT', u.Health, 'BOTTOMRIGHT', 3, -3)
	u.border:SetFrameLevel(u:GetFrameLevel() + 7)
	u.border.edges = {}
	for e, side in ipairs({ { 'TOPLEFT', 'TOPRIGHT', true }, { 'BOTTOMLEFT', 'BOTTOMRIGHT', true }, { 'TOPLEFT', 'BOTTOMLEFT', false }, { 'TOPRIGHT', 'BOTTOMRIGHT', false } }) do
		local t = u.border:CreateTexture(nil, 'OVERLAY')
		t:SetTexture(Theme.WHITE)
		t:SetPoint(side[1], u.border, side[1], 0, 0)
		t:SetPoint(side[2], u.border, side[2], 0, 0)
		if side[3] then t:SetHeight(2) else t:SetWidth(2) end
		u.border.edges[e] = t
	end
	u.border:Hide()
	return u
end

-- the enhanced targeted nameplate sample: the plate bar, the name above, HP left / % right, the hub, the outline, a cast bar under it
local function SamplePlate(c, sample)
	local u = CreateFrame('Frame', nil, c)
	u:SetSize(10, 10)
	u.sample, u.key = sample, 'nameplate'
	u.color = Theme:ClassColor(sample.class)
	local level = c:GetFrameLevel() + 1
	u.Health = PBar(u, 140, 12, level + 2)
	u.Health:SetPoint('CENTER', u, 'CENTER', 0, 0)
	u.healthText = ns.Health and ns.Health.Attach and ns.Health:Attach(u.Health, { side = 'LEFT', x = 4, y = 0, value = 10, percent = 9, split = true }) or nil
	local P = Split.PLATE
	u.hub = ns.Identity.Hub(u.Health, P.hub)
	u.hub:SetPoint('RIGHT', u.Health, 'LEFT', -P.gap, 0)
	u.hub:SetFrameLevel(level + 6)
	u.hub.castSize = 9
	u.hub.plate = true -- as live (1.3.1: nameplates frozen)
	u.hub.castName:ClearAllPoints()
	u.hub.castName:SetPoint('TOPLEFT', u.Health, 'BOTTOMLEFT', 0, -10)
	ns.Identity.PaintArt(u.hub, ns.Identity.Art(sample.class, nil, u.hub))
	u.textLayer = CreateFrame('Frame', nil, u)
	u.textLayer:SetAllPoints(u)
	u.textLayer:SetFrameLevel(level + 9)
	u.name = PText(u.textLayer, 11)
	u.name:SetPoint('BOTTOM', u.Health, 'TOP', 0, 3)
	u.name:SetText(Theme:GradientText(sample.label, Theme.Mix(u.color, { 1, 1, 1 }, 0.25), u.color))
	u.outline = CreateFrame('Frame', nil, u)
	u.outline:SetPoint('TOPLEFT', u.Health, 'TOPLEFT', -P.outline, P.outline)
	u.outline:SetPoint('BOTTOMRIGHT', u.Health, 'BOTTOMRIGHT', P.outline, -P.outline)
	u.outline:SetFrameLevel(level + 5)
	for _, side in ipairs({ { 'TOPLEFT', 'TOPRIGHT', true }, { 'BOTTOMLEFT', 'BOTTOMRIGHT', true }, { 'TOPLEFT', 'BOTTOMLEFT', false }, { 'TOPRIGHT', 'BOTTOMRIGHT', false } }) do
		local t = u.outline:CreateTexture(nil, 'OVERLAY')
		t:SetTexture(Theme.WHITE)
		t:SetPoint(side[1], u.outline, side[1], 0, 0)
		t:SetPoint(side[2], u.outline, side[2], 0, 0)
		if side[3] then t:SetHeight(1) Theme:Gradient(t, 'HORIZONTAL', Theme.COLORS.lime, Theme.COLORS.violet, 1, 1) else t:SetWidth(1) end
	end
	u.cast = PBar(u, 140, 6, level + 2)
	u.cast:SetPoint('TOP', u.Health, 'BOTTOM', 0, -2)
	u.cast:Hide()
	return u
end

-- where the samples sit: the Banzai positions (as the live split frames)
local function Place(c, key)
	local db = Theme:DB()
	local p, t = Split.Geometry('player', db), Split.Geometry('target', db)
	c:ClearAllPoints()
	if key == 'player' then
		c:SetPoint('CENTER', UIParent, 'BOTTOM', db.splitPlayerX, db.splitPlayerY)
	elseif key == 'target' then
		c:SetPoint('CENTER', UIParent, 'TOP', db.splitTargetX, -db.splitTargetY)
	elseif key == 'targetNPC' then -- just below the Target, so both samples can show
		c:SetPoint('CENTER', UIParent, 'TOP', db.splitTargetX, -(db.splitTargetY + t.hub + 40))
	elseif key == 'focus' then
		c:SetPoint('CENTER', UIParent, 'BOTTOM', db.splitPlayerX + (Split.FOCUS_OFFSET[1]), db.splitPlayerY + Split.FOCUS_OFFSET[2])
	elseif key == 'targettarget' then
		c:SetPoint('LEFT', UIParent, 'TOP', db.splitTargetX + t.inner + t.bar + Split.TOT.gap, -db.splitTargetY)
	elseif key == 'nameplate' then
		c:SetPoint('CENTER', UIParent, 'CENTER', 0, 150)
	end
	return p
end
Split.FOCUS_OFFSET = { -330, 70 } -- the Focus hub from the Player hub (T.SPLIT.focus dx / dy)

local function Title(c, text, below)
	c.title = c.title or PText(c, 9)
	c.title:ClearAllPoints()
	if below then c.title:SetPoint('TOP', c, 'BOTTOM', 0, -4) else c.title:SetPoint('BOTTOM', c, 'TOP', 0, 4) end
	c.titleText = text
end

-- a split preview container (Preview:Show in the SPLIT style)
function Split:BuildPreview(key, preview)
	if not Split.PREVIEW[key] then return nil end
	local c = NewContainer(key)
	local S = Split.SAMPLE
	if key == 'party' or key == 'arenaAllies' then
		local def = preview and preview.GROUPS and preview.GROUPS[key]
		local db = def and preview.GroupDB(def) or {}
		local count = (def and def.count) or 5
		local pos, totalW, totalH, w, h = preview.GroupLayout(db, count, def and def.perGroup)
		c:SetSize(totalW, totalH)
		if preview.Anchor then preview.Anchor(c, def.mover, def.fallbackMover) end
		c.role = preview:Role()
		for i = 1, count do
			local u = SampleParty(c, i, w, h)
			u:SetPoint('TOPLEFT', c, 'TOPLEFT', pos[i][1], -pos[i][2])
			c.units[i] = u
		end
		Title(c, (key == 'party' and 'PARTY' or 'ARENA ALLIES') .. ' - BANZAI SPLIT - ' .. c.role .. ' LAYOUT')
	elseif key == 'targettarget' then
		c.units[1] = SampleToT(c, S.targettarget)
		c.units[1]:SetPoint('LEFT', c, 'LEFT', 0, 0)
		Place(c, key)
		Title(c, 'TARGET OF TARGET - BANZAI SPLIT', true)
	elseif key == 'nameplate' then
		c.units[1] = SamplePlate(c, S.nameplate)
		c.units[1]:SetPoint('CENTER', c, 'CENTER', 0, 0)
		Place(c, key)
		Title(c, 'ENHANCED TARGETED NAMEPLATE - BANZAI SPLIT', true)
	else
		local sample = S[key]
		if sample.own then
			local _, token = UnitClass('player')
			sample = { label = sample.label, health = sample.health, max = sample.max, power = sample.power, powerMax = sample.powerMax, own = true }
			sample.class = (type(token) == 'string' and not IsSecret(token)) and token or 'DRUID'
			local spec = ns.Tags and ns.Tags.PlayerSpec and ns.Tags.PlayerSpec()
			sample.spec = spec and string.upper(spec) or nil
			local _, ptoken = Call(UnitPowerType, 'player')
			sample.powerToken = (type(ptoken) == 'string') and ptoken or 'MANA' -- 1.3.1: only that there is one (the colour is the class's)
		end
		local u = SampleUnit(c, (key == 'targetNPC') and 'target' or key, sample)
		u.key = key
		u:SetPoint('CENTER', c, 'CENTER', 0, 0)
		c.units[1] = u
		Place(c, key)
		local below = (key == 'target' or key == 'targetNPC')
		Title(c, (sample.label or key) .. ' - BANZAI SPLIT', below)
	end
	return c
end

-- the sample's cast on its hub at a fixed point of a synthetic run (no live data)
local function SampleCast(hub, kind, locked)
	local cast = Split.SAMPLE.casts[(kind == 'channel') and 'channel' or 'cast']
	local total = 1000
	local info = { name = cast[1], texture = cast[2], kind = kind, notInterruptible = locked and true or false }
	Split.Begin(hub, info)
	local done = (kind == 'channel') and (1 - cast[3]) or cast[3]
	if hub.barHub then -- 1.3.3: the bamboo cast bar at the same fixed point (a channel shows what remains)
		if hub.bar then
			ns.CastBar.Sample(hub.bar, (kind == 'channel') and (1 - done) or done)
			ns.CastBar.Lock(hub.bar, locked and true or false)
		end
		hub.castTime:SetText(string.format('%.1f', (1 - done) * 2.5))
		if hub.clock then hub.clock:Hide() end
		return
	end
	-- the preview's progress: a synthetic Cooldown (Begin draws none without a duration)
	local cd = hub.progress
	local now = GetTime and GetTime() or 0
	if cd.SetCooldown then cd:SetCooldown(now - done * total, total) end
	cd:Show()
	hub.track:Show()
	hub.ring:SetAlpha(0.35)
	hub.castTime:SetText(string.format('%.1f', (1 - done) * 2.5))
	if hub.clock then hub.clock:Hide() end
	for _, t in ipairs(hub.lockParts) do t:SetShown(locked and true or false) t:SetAlpha(1) end
end
Split.SampleCast = SampleCast

-- a preview state on one container (the same states as the classic preview)
function Split:ApplyPreviewState(c, state, preview)
	for i, u in ipairs(c.units) do
		local s = u.sample
		local health = s.health or 1
		if state == 'LOW_HEALTH' then health = 0.14 + 0.03 * ((i - 1) % 3) end
		local dead = state == 'DEAD' and (c.key == 'party' or c.key == 'arenaAllies') and i == 2
		if dead then health = 0 end
		u:SetAlpha((state == 'OUT_OF_RANGE' and c.key ~= 'player') and PREVIEW_ALPHA or 1)
		if c.key == 'party' and state == 'NORMAL' and i == 5 then u:SetAlpha(PREVIEW_ALPHA) end -- one member out of range
		if u.healthSurface then -- 1.3.1: the live split bars' colour family
			u.Health:SetValue(health)
			Split.PaintSurface(u.healthSurface, Split.HealthColors(u.ramp), Split.SURFACE_ALPHA)
		else
			PPaint(u.Health, u.color, health)
		end
		local value = (health > 0) and Short((s.max or 500000) * health) or ''
		local percent = (health > 0) and string.format('%d%%', math.floor(health * 100 + 0.5)) or ''
		SetTexts(u.healthText, value, percent)
		if u.percent then u.percent:SetText(percent) end
		if u.Power then
			if u.powerSurface then
				u.Power:SetValue(s.power or 1)
				Split.PaintSurface(u.powerSurface, Split.PowerColors(u.ramp), Split.SURFACE_ALPHA)
			else
				local ramp = Theme.Ramp(u.color) -- 1.3.1: the class family, never the resource type's colour
				PPaint(u.Power, { ramp.base, ramp.deep }, s.power or 1)
			end
			SetTexts(u.powerText, Short((s.powerMax or 100) * (s.power or 1)), string.format('%d%%', math.floor((s.power or 1) * 100 + 0.5)))
		end
		if u.status then u.status:SetText(dead and '|cffb8bcc4Dead|r' or '') end
		if u.circle then u.circle.icon:SetDesaturated(dead and true or false) end
		if u.cc then
			local cc = state == 'CC_ALLY' and i <= 3
			u.cc:SetShown(cc)
			u.cc.label:SetShown(cc and Theme:DB().ccEmphasis ~= 'MINIMAL')
			local dispel = state == 'DISPELLABLE' and (i == 2 or i == 4)
			local color = cc and ((ns.PvPFrames and ns.PvPFrames.COLORS.cc) or { 1, 0.18, 0.62 }) or ((ns.PvPFrames and ns.PvPFrames.COLORS.dispel) or { 0.2, 0.85, 1 })
			for _, e in ipairs(u.border.edges) do e:SetVertexColor(color[1], color[2], color[3], 1) end
			u.border:SetShown(cc or dispel)
		end
		if u.trinket and ns.PvPFrames then
			u.trinket:SetShown(Theme:DB().trinketCircles ~= false)
			local used = state == 'TRINKET_USED' and (i == 1 or i == 3)
			ns.PvPFrames.PaintTrinket(u.trinket, (state == 'TRINKET_UNKNOWN' and 'UNKNOWN') or (used and 'USED') or 'READY')
		end
		if u.hub then
			if s.npc then -- 1.3.3: the TARGET NPC sample stays idle in every state (synthetic: no spell, no game texture)
				Split.Idle(u.hub)
			elseif state == 'CASTING' or state == 'CAST_LOCKED' or state == 'CHANNELING' then
				SampleCast(u.hub, (state == 'CHANNELING') and 'channel' or 'cast', state == 'CAST_LOCKED' and c.key ~= 'player')
				if u.cast then u.cast:Show() PPaint(u.cast, Split.CAST[state == 'CHANNELING' and 'channel' or 'cast'], 0.62) end
			elseif state == 'INTERRUPTED' then -- 1.3.3: the moment after an interrupt (the class art back)
				SampleCast(u.hub, 'cast', false)
				Split.Fail(u.hub, 'INTERRUPTED')
				if u.cast then u.cast:Hide() end
			else
				Split.Idle(u.hub)
				if u.cast then u.cast:Hide() end
			end
		end
	end
	if c.title then
		local label = preview and preview.STATE_LABELS and preview.STATE_LABELS[state] or state
		c.title:SetText(Theme:GradientText(c.titleText or '', Theme.COLORS.lime, Theme.COLORS.emerald) .. '|cff8c919a  -  PREVIEW: ' .. tostring(label) .. '  -  SAMPLE DATA|r')
	end
end
