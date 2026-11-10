--[[
	BANZAI - CastBar.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	1.3.3 the BANZAI SPLIT bamboo cast bar - Player and Target only (Focus and
	the enhanced targeted nameplate keep their radial hub, BANZAI CLASSIC its
	own cast bars, the party / arena / ToT frames none). Split.lua decides when
	a cast shows (the same cast events and reads as since 1.3.0) and keeps the
	spell icon in the centre of the hub; this file is the bar:

	  construction  the approved panel bamboo of the chat / Details / minimap /
	                BUFFS frames at the cast bar's scale - the same stalk,
	                stalk-end and rope-tie textures, their colours (BANZAI >
	                APPEARANCE > PANEL STYLE border) and node period: a top and
	                a bottom stalk, a short end piece at each end (a cut tip
	                one way, a node end the other), a rope tie on each crossing,
	                all inside the bar's outline, round a dark translucent
	                interior
	  size          as wide as the whole split composition (health bar's outer
	                end to resource bar's outer end); 1.3.4: the interior - the
	                fill - snug round the spell name: Player 22.5 units (30 px at
	                Darren's 2560 x 1440, UI scale 0.71; 1.3.3: 37.5 = 50 px),
	                Target 19.5 (26 px; 1.3.3: 33 = 44 px); each stalk 4.5 / 3.75
	                units (6 / 5 px) at the panel bamboo's own proportions (the
	                pieces placed again, never a squashed texture) - the whole
	                bar 40 / 38 % lower; the spell name and timer sizes unchanged
	  place         directly above the values over the bars and clear of the
	                hub's top (Split.Geometry castLift)
	  progress      the game's own timer on a StatusBar (SetTimerDuration with
	                the duration object Split.ReadCast hands over): a cast and an
	                empower fill left to right, a channel drains right to left;
	                plain start / end times only when the game has no duration
	                object; when it keeps both to itself no fill is drawn
	  colour        the unit's class family (an NPC: its reaction), a thin
	                Banzai green -> purple line along the top, a bright edge on
	                the moving end of the fill
	  texts         the spell name centred in the Banzai display font
	                (off-white, dark outline), the remaining time right-aligned
	                in the small information font (Split.lua writes both)
	  locked        the game's non-interruptible flag handed to
	                SetAlphaFromBoolean (a steel veil over the fill, a steel line
	                along its top; never tested)
	  interrupted   a crimson interior, INTERRUPTED in cyan, for a moment
	  settings      BANZAI > UNIT FRAMES > FRAME STYLE > SPLIT CAST BAR: the bar,
	                the spell name, the timer (Character Sync carries them)

	No spell icon on the bar (the hub shows it), no game texture (Banzai media
	only), nothing secure, nothing hooked.
]]
local _, ns = ...
local Theme = ns.Theme

local CastBar = {}
ns.CastBar = CastBar
if ns.Compat then ns.Compat.CastBar = CastBar end -- the tests and the status line reach it through BanzaiCompat

local STALK, STALK_END, ROPE = Theme.MEDIA .. 'BanzaiStalk', Theme.MEDIA .. 'BanzaiStalkEnd', Theme.MEDIA .. 'BanzaiRopeTie'
local BAR = Theme.MEDIA .. 'BanzaiBar'

-- the construction against the stalk diameter d: the stalk's axis this far inside the outline (its drawn
-- band, 1.2 d with its shading, ends on the outline; the interior starts Split.CAST_BAR.inner d in), the rope
-- tie `tie` d (its drawn cord, 61 % of the texture, stays inside the outline); the timer `pad` units clear of the tie
CastBar.SHAPE = { axis = 0.6, tie = 2.4, spark = 1.5, accent = 0.75, lock = 1.5, pad = 4 }
CastBar.COLORS = {
	text = { 0.96, 0.95, 0.90 },        -- the spell name: off-white
	interrupted = { 0.82, 0.06, 0.22 }, -- crimson
	cyan = { 0.30, 0.90, 1.00 },        -- the INTERRUPTED text
	lock = { 0.46, 0.44, 0.56 },        -- the restrained steel of a cast that cannot be interrupted (as 1.3.0)
	fallback = { 1.00, 0.70, 0.00 },    -- the Banzai attention amber, when the game keeps the unit's colour
}
CastBar.LOCK_VEIL = 0.55 -- the steel veil's alpha over a locked fill

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function PlainNumber(v)
	return type(v) == 'number' and not IsSecret(v)
end

local function Snap(texture)
	if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(true) end
	if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
end

-- the eight tex coords of a panel piece, as Compat.lua's panel: a horizontal piece reads the texture as it is,
-- a vertical one turns it (U along y); `flip` runs U the other way (a tip pointing left / up)
local function Coords(horizontal, u0, u1, flip)
	local a, b = u0, u1
	if flip then a, b = u1, u0 end
	if horizontal then return a, 0, a, 1, b, 0, b, 1 end
	return a, 0, b, 0, a, 1, b, 1
end

function CastBar.Enabled() return Theme:DB().splitCastBar ~= false end

---------------------------------------------------------------------------
-- Construction
---------------------------------------------------------------------------
-- the bamboo: two horizontal stalks (body segments of one node period each, their ends under the end pieces),
-- two vertical end pieces (cut tip + body + node end), four rope ties; every piece placed once
local function Bamboo(bar, W, H, d)
	local P = ns.Compat and ns.Compat.PANEL or { texD = 88, texH = 128, tipPx = 256, period = 3.6, periods = 4, tipGap = 6 }
	local S = CastBar.SHAPE
	local strip = (P.texH / P.texD) * d
	local tip = (P.tipPx / P.texD) * d
	local axis = S.axis * d
	local layer = CreateFrame('Frame', nil, bar)
	layer:SetAllPoints(bar)
	layer:SetFrameLevel(bar:GetFrameLevel() + 3)
	bar.bamboo, bar.pieces = layer, {}
	-- a piece from a to b along its stalk; the colour field (0..1 across the bar, the panels' HARDKORH
	-- direction: left -> right) and the position along the stalk at both ends, as the panels paint them
	local function piece(stalk, horizontal, sub, path, a, b, at, u0, u1, flip, length)
		local t = layer:CreateTexture(nil, 'ARTWORK', nil, sub)
		t:SetTexture(path, 'CLAMP', 'CLAMP', 'TRILINEAR')
		t:SetTexCoord(Coords(horizontal, u0, u1, flip))
		if horizontal then
			t:SetPoint('TOPLEFT', layer, 'TOPLEFT', a, -(at - strip / 2))
			t:SetSize(b - a, strip)
		else
			t:SetPoint('TOPLEFT', layer, 'TOPLEFT', at - strip / 2, -a)
			t:SetSize(strip, b - a)
		end
		local p = { texture = t, stalk = stalk, horizontal = horizontal, pa = a / length, pb = math.min(1, b / length), vary = ((#bar.pieces * 7919) % 97) / 97 }
		if horizontal then p.fa, p.fb = a / W, math.min(1, b / W) else p.fa, p.fb = at / W, at / W end
		bar.pieces[#bar.pieces + 1] = p
	end
	-- the top and bottom stalks: body segments across the whole width (their ends lie under the end pieces)
	for _, st in ipairs({ { 'top', axis, 1 }, { 'bottom', H - axis, 0 } }) do
		local n = math.max(1, math.floor(W / (P.period * d) + 0.5))
		local seg = W / n
		for i = 0, n - 1 do
			local k = i % P.periods
			piece(st[1], true, st[3], STALK, i * seg, (i + 1) * seg + ((i < n - 1) and 0.25 or 0), st[2], k / P.periods, (k + 1) / P.periods, false, W)
		end
	end
	-- the end pieces: the left one cut at its top, the right one at its bottom (as the panels' side stalks)
	local gap = P.tipGap / (2 * P.tipPx)
	local cutU, plainU = { 0, 0.5 - gap }, { 0.5 + gap, 1 }
	for _, st in ipairs({ { 'left', axis, true }, { 'right', W - axis, false } }) do
		local bodyFrom, bodyTo = tip, math.max(tip, H - tip)
		local first, last = st[3] and cutU or plainU, st[3] and plainU or cutU
		piece(st[1], false, 2, STALK_END, 0, bodyFrom, st[2], first[1], first[2], true, H)
		if bodyTo > bodyFrom then piece(st[1], false, 2, STALK, bodyFrom, bodyTo + 0.25, st[2], 0, (bodyTo - bodyFrom) / (P.period * d * P.periods), false, H) end
		piece(st[1], false, 2, STALK_END, bodyTo, H, st[2], last[1], last[2], false, H)
	end
	-- the rope ties on the four crossings, their drawn cord inside the outline (the right-hand ones mirrored)
	local size = S.tie * d
	local c = math.max(axis, size * 0.30)
	bar.ties = {}
	for i, corner in ipairs({ { c, c, false }, { W - c, c, true }, { c, H - c, false }, { W - c, H - c, true } }) do
		local t = layer:CreateTexture(nil, 'ARTWORK', nil, 3)
		t:SetTexture(ROPE, 'CLAMP', 'CLAMP', 'TRILINEAR')
		if corner[3] then t:SetTexCoord(1, 0, 1, 1, 0, 0, 0, 1) else t:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1) end
		t:SetPoint('TOPLEFT', layer, 'TOPLEFT', corner[1] - size / 2, -(corner[2] - size / 2))
		t:SetSize(size, size)
		bar.ties[i] = t
	end
end

-- a cast bar for a split frame (g: Split.Geometry of its unit; def: Split.UNITS entry; level: its frame level, set
-- before its layers are made on it), hidden until a cast shows
function CastBar.Build(parent, g, def, level)
	local W, H, d, I = g.castWidth, g.castHeight, g.castStalk, g.castInterior
	local S = CastBar.SHAPE
	local bar = CreateFrame('Frame', nil, parent)
	if level then bar:SetFrameLevel(level) end
	bar:SetSize(W, H)
	bar:EnableMouse(false)
	bar.w, bar.h, bar.d, bar.interior = W, H, d, I
	local inset = (H - I) / 2 -- Split.Geometry: the interior between the two stalks
	bar.inset = inset
	-- the dark translucent interior
	bar.glass = bar:CreateTexture(nil, 'BACKGROUND')
	bar.glass:SetTexture(Theme.WHITE)
	bar.glass:SetPoint('TOPLEFT', bar, 'TOPLEFT', inset, -inset)
	bar.glass:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', -inset, inset)
	-- the fill: a status bar the game's timer drives
	local status = CreateFrame('StatusBar', nil, bar)
	status:SetPoint('TOPLEFT', bar, 'TOPLEFT', inset, -inset)
	status:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', -inset, inset)
	status:SetStatusBarTexture(BAR)
	status:SetMinMaxValues(0, 1)
	status:SetValue(0)
	status:SetFrameLevel(bar:GetFrameLevel() + 1)
	bar.status = status
	bar.fill = status:GetStatusBarTexture()
	-- the bright edge on the moving end of the fill
	bar.spark = status:CreateTexture(nil, 'OVERLAY')
	bar.spark:SetTexture(Theme.WHITE)
	bar.spark:SetWidth(S.spark)
	bar.spark:SetPoint('TOP', bar.fill, 'TOPRIGHT', 0, 0)
	bar.spark:SetPoint('BOTTOM', bar.fill, 'BOTTOMRIGHT', 0, 0)
	-- above the fill: the interrupted interior, the steel lock, the accent line
	local over = CreateFrame('Frame', nil, bar)
	over:SetAllPoints(status)
	over:SetFrameLevel(bar:GetFrameLevel() + 2)
	bar.over = over
	bar.flash = over:CreateTexture(nil, 'ARTWORK', nil, 0)
	bar.flash:SetTexture(BAR)
	bar.flash:SetAllPoints(over)
	bar.flash:Hide()
	bar.lockVeil = over:CreateTexture(nil, 'ARTWORK', nil, 1)
	bar.lockVeil:SetTexture(Theme.WHITE)
	bar.lockVeil:SetAllPoints(over)
	bar.lockLine = over:CreateTexture(nil, 'ARTWORK', nil, 2)
	bar.lockLine:SetTexture(Theme.WHITE)
	bar.lockLine:SetPoint('TOPLEFT', over, 'TOPLEFT', 0, 0)
	bar.lockLine:SetPoint('TOPRIGHT', over, 'TOPRIGHT', 0, 0)
	bar.lockLine:SetHeight(S.lock)
	bar.lockParts = { bar.lockVeil, bar.lockLine }
	for _, t in ipairs(bar.lockParts) do t:Hide() end
	bar.accent = over:CreateTexture(nil, 'OVERLAY')
	bar.accent:SetTexture(Theme.WHITE)
	bar.accent:SetPoint('BOTTOMLEFT', over, 'BOTTOMLEFT', 0, 0)
	bar.accent:SetPoint('BOTTOMRIGHT', over, 'BOTTOMRIGHT', 0, 0)
	bar.accent:SetHeight(S.accent)
	for _, t in ipairs({ bar.glass, bar.spark, bar.flash, bar.lockVeil, bar.lockLine, bar.accent }) do Snap(t) end
	Bamboo(bar, W, H, d)
	-- the texts, above the bamboo: the spell name centred, the timer at the right end clear of the rope tie
	local text = CreateFrame('Frame', nil, bar)
	text:SetAllPoints(bar)
	text:SetFrameLevel(bar:GetFrameLevel() + 4)
	bar.text = text
	local timeRoom = (def.castTime or 12) * 3 -- room for "12.3"
	local right = S.tie * d * 0.65 + S.pad
	bar.name = text:CreateFontString(nil, 'OVERLAY')
	Theme:SetDisplayFont(bar.name, Theme:DisplaySize(def.castName or 15), 'OUTLINE') -- a font before any text ("Font not set")
	bar.name:SetPoint('CENTER', bar, 'CENTER', 0, 0)
	bar.name:SetWidth(W - 2 * (right + timeRoom + S.pad))
	bar.name:SetJustifyH('CENTER')
	bar.name:SetWordWrap(false)
	bar.time = text:CreateFontString(nil, 'OVERLAY')
	bar.time:SetFont(Theme:SmallFont(), def.castTime or 12, 'OUTLINE')
	bar.time:SetPoint('RIGHT', bar, 'RIGHT', -right, 0)
	bar.time:SetJustifyH('RIGHT')
	bar.timeRight = right
	bar.nameSize, bar.timeSize = def.castName or 15, def.castTime or 12
	bar:Hide()
	CastBar.Paint(bar)
	return bar
end

-- the bar over a hub: centred on it (the split composition is symmetric about its hub), `castLift` above its
-- centre; the hub's cast texts and lock parts become the bar's
function CastBar.Attach(hub, bar, g)
	bar:ClearAllPoints()
	bar:SetPoint('BOTTOM', hub, 'CENTER', 0, g.castLift)
	hub.bar = bar
	if hub.castName and hub.castName ~= bar.name then hub.castName:Hide() end
	if hub.castTime and hub.castTime ~= bar.time then hub.castTime:Hide() end
	hub.castName, hub.castTime, hub.lockParts = bar.name, bar.time, {}
	hub.timeSize = bar.timeSize
	hub.castSize = bar.nameSize
	return bar
end

---------------------------------------------------------------------------
-- Painting
---------------------------------------------------------------------------
-- the bamboo in the panel style's colours (Theme:PanelStalk / PanelRope), the interior, the accent
function CastBar.Paint(bar)
	for _, p in ipairs(bar.pieces or {}) do
		local from = Theme:PanelStalk(p.stalk, p.fa, p.pa, p.vary)
		local to = Theme:PanelStalk(p.stalk, p.fb, p.pb, p.vary)
		-- a vertical gradient takes its first colour at the bottom: a vertical piece's `from` is its upper end
		if p.horizontal then Theme:Gradient(p.texture, 'HORIZONTAL', from, to, 1, 1) else Theme:Gradient(p.texture, 'VERTICAL', to, from, 1, 1) end
	end
	for _, t in ipairs(bar.ties or {}) do Theme:Gradient(t, 'VERTICAL', Theme:PanelRope(1), Theme:PanelRope(0), 1, 1) end
	Theme:Gradient(bar.glass, 'VERTICAL', { 0.010, 0.030, 0.022 }, { 0.040, 0.075, 0.058 }, 0.84, 0.80)
	Theme:Gradient(bar.accent, 'HORIZONTAL', Theme.COLORS.lime, Theme.COLORS.violet, 0.9, 0.9)
	local red = CastBar.COLORS.interrupted
	Theme:Gradient(bar.flash, 'HORIZONTAL', { red[1] * 0.55, red[2] * 0.55, red[3] * 0.55 }, red, 1, 1)
end

-- the fill in the unit's family: a cast / empower deep -> bright toward its leading (right) end, a channel
-- the other way round (it drains toward the left); `ramp` nil: the attention amber's family
function CastBar.PaintFill(bar, kind, ramp)
	ramp = ramp or Theme.Ramp(CastBar.COLORS.fallback)
	local from, to = ramp.deep, ramp.bright
	if kind == 'channel' then from, to = ramp.bright, ramp.base end
	Theme:Gradient(bar.fill, 'HORIZONTAL', from, to, 1, 1)
	local edge = Theme.Mix(ramp.bright, { 1, 1, 1 }, 0.55)
	bar.spark:SetVertexColor(edge[1], edge[2], edge[3], 0.9)
end

---------------------------------------------------------------------------
-- States (Split.lua: Begin / Fail / Idle)
---------------------------------------------------------------------------
-- the non-interruptible marking: the game's boolean handed to each part (never tested here)
function CastBar.Lock(bar, notInterruptible)
	local steel = CastBar.COLORS.lock
	for _, t in ipairs(bar.lockParts) do
		t:SetVertexColor(steel[1], steel[2], steel[3], 1) -- a flat colour: the alpha below is the part's own
		local on = (t == bar.lockVeil) and CastBar.LOCK_VEIL or 1
		if t.SetAlphaFromBoolean then
			t:Show()
			t:SetAlphaFromBoolean(notInterruptible, on, 0)
		elseif not IsSecret(notInterruptible) then
			t:SetShown(notInterruptible == true)
			t:SetAlpha(on)
		else
			t:Hide() -- not supported: nothing claimed
		end
	end
end

local function Unlock(bar)
	for _, t in ipairs(bar.lockParts) do t:Hide() end
end

-- what the user shows of the bar (BANZAI > UNIT FRAMES > SPLIT CAST BAR)
function CastBar.Texts(bar)
	local db = Theme:DB()
	bar.name:SetShown(db.splitCastName ~= false)
	bar.time:SetShown(db.splitCastTimer ~= false)
end

-- a cast on the bar: the game's timer when it hands one over, else plain times, else no fill at all;
-- returns whether it is timed and, for plain times, when it ends
function CastBar.Begin(bar, info, ramp)
	bar.state, bar.plain = info.kind, nil
	bar.flash:Hide()
	local status = bar.status
	local timed, endTime = false, nil
	if info.duration and status.SetTimerDuration and Enum and Enum.StatusBarTimerDirection then
		local direction = (info.kind == 'channel') and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime
		status:SetMinMaxValues(0, 1)
		status:SetTimerDuration(info.duration, Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or 0, direction)
		timed = true
	elseif PlainNumber(info.startMS) and PlainNumber(info.endMS) and info.endMS > info.startMS then
		bar.plain = { start = info.startMS / 1000, finish = info.endMS / 1000, channel = info.kind == 'channel' }
		status:SetMinMaxValues(bar.plain.start, bar.plain.finish)
		CastBar.Step(bar)
		timed, endTime = true, bar.plain.finish
	end
	status:SetShown(timed) -- the game keeps the timing: the name alone says a cast is under way (no fill invented)
	CastBar.PaintFill(bar, info.kind, ramp)
	CastBar.Lock(bar, info.notInterruptible)
	CastBar.Texts(bar)
	bar:SetShown(CastBar.Enabled())
	return timed, endTime
end

-- plain times only (no duration object): the fill from the clock - a cast grows, a channel drains
function CastBar.Step(bar)
	local p = bar.plain
	if not (p and GetTime) then return end
	local now = math.max(p.start, math.min(p.finish, GetTime()))
	bar.status:SetValue(p.channel and (p.start + p.finish - now) or now)
end

-- INTERRUPTED for a moment: a crimson interior, the name and timer written by Split.Fail
function CastBar.Interrupt(bar)
	bar.state, bar.plain = 'interrupted', nil
	bar.status:Hide()
	Unlock(bar)
	bar.flash:Show()
	CastBar.Texts(bar)
	bar:SetShown(CastBar.Enabled())
end

-- nothing of the cast left
function CastBar.Clear(bar)
	bar.state, bar.plain = nil, nil
	bar.status:Hide()
	bar.flash:Hide()
	Unlock(bar)
	bar:Hide()
end

-- a synthetic run at a fixed point (the unit-frame preview: no live data, no timer)
function CastBar.Sample(bar, value)
	bar.plain = nil
	bar.status:SetMinMaxValues(0, 1)
	bar.status:SetValue(value)
	bar.status:Show()
end
