--[[
	BANZAI - Health.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	Current health + percentage inside the Player / Target / Focus health bars;
	0.7.0: inside the secondary frames too (party / arena allies, arena enemies,
	boss: value + percent from the bar's left end, under the name). Raid frames
	keep ElvUI's own compact percent (BushidoPrivateRestore).

	Two copies of the text sit on top of each other:
	  ghost   always visible, translucent: what you read over the empty part
	  bright  inside a frame that clips to the health bar's own fill texture
	          (StatusBar:GetStatusBarTexture()), so it shows exactly where the
	          bar is filled
	As health drops the fill shrinks under the text: the part over the fill stays
	bright, the part over the empty bar turns ghosted; the value never vanishes.
	No health value is read by this code (12.x secret values): the text comes
	from ElvUI's tag system ([mMT-health:current:short], [perhp<%]) and the
	clipping from the bar's own geometry.

	Player: value on the portrait side (left), percent after it; Target mirrored.
	The name / spec line stays under the bar.

	1.0.0: on the half-width Player / Target bars the pair starts closer to the
	class circle (narrowX), so it ends well before the bamboo at the inner end.

	1.3.0 BANZAI SPLIT (a split session only, Split.lua; BANZAI CLASSIC as
	above): the current value at the bar's outer end and the percent at its
	inner end beside the hub, clear of the part of the bar the hub covers -
	health on the left bars (Player / Target / Focus) and, the same way
	mirrored, the resource on the right bars: ElvUI's own power tags
	([power:current:shortvalue], [perpp]) - nothing is read here either, and a
	tag the installed ElvUI does not have is simply left out. Party: the value
	at the left end, the percent at the right end (the role icon sits on the circle).

	1.3.1 (Darren's runtime correction): the split Player and Target texts sit
	ABOVE their bars, one copy each - health: the current value over the outer
	(left) end, the percent over the inner end beside the hub; resource
	mirrored: the percent over the inner end, the current value over the outer
	(right) end. Focus and party keep theirs inside. The big Player / Target
	numbers are in the Banzai display font, the percentages in the
	small information font; every other frame's numbers (party, arena, boss,
	focus, the targeted nameplate) keep the previous display font.
]]
local _, ns = ...
local Theme = ns.Theme

local Health = {}
ns.Health = Health

Health.UNITS = {
	{ frame = 'ElvUF_Player', side = 'LEFT', x = 34, narrowX = 14, value = 17, percent = 11, display = true }, -- 1.3.1 display: the Banzai display font
	{ frame = 'ElvUF_Target', side = 'RIGHT', x = -34, narrowX = -14, value = 17, percent = 11, display = true },
	{ frame = 'ElvUF_Focus', side = 'LEFT', x = 16, value = 13, percent = 9 },
}
-- 0.7.0 secondary frames (their ElvUI health texts are off while this is on)
Health.GROUPS = {
	{ prefix = 'ElvUF_PartyGroup1UnitButton', count = 5, side = 'LEFT', x = 4, y = -5, value = 12, percent = 9 }, -- 0.9.0: the role icon sits at the right end
	{ prefix = 'ElvUF_Arena', count = 5, side = 'LEFT', x = 6, y = -3, value = 12, percent = 9 },
	{ prefix = 'ElvUF_Boss', count = 8, side = 'LEFT', x = 6, y = -3, value = 12, percent = 9 },
}
-- 1.3.0 BANZAI SPLIT definitions (x / percentX from the bar ends; the percent clears the hub's tuck)
-- 1.3.1: Player / Target above their bars (above: the gap between the bar's top and the texts), Focus inside
Health.SPLIT_UNITS = {
	{ frame = 'ElvUF_Player', key = 'player', side = 'LEFT', x = 0, y = 2, split = true, splitStyle = true, above = true, display = true },
	{ frame = 'ElvUF_Target', key = 'target', side = 'LEFT', x = 0, y = 2, split = true, splitStyle = true, above = true, display = true },
	{ frame = 'ElvUF_Focus', key = 'focus', side = 'LEFT', x = 4, y = 0, split = true, splitStyle = true },
}
Health.SPLIT_POWER = {
	{ frame = 'ElvUF_Player', key = 'player', side = 'RIGHT', x = 0, y = 2, split = true, splitStyle = true, above = true, display = true },
	{ frame = 'ElvUF_Target', key = 'target', side = 'RIGHT', x = 0, y = 2, split = true, splitStyle = true, above = true, display = true },
	{ frame = 'ElvUF_Focus', key = 'focus', side = 'RIGHT', x = -4, y = 0, split = true, splitStyle = true },
}
Health.SPLIT_PARTY = { prefix = 'ElvUF_PartyGroup1UnitButton', count = 5, side = 'LEFT', x = 4, y = 0, percentX = 4, value = 9, percent = 8, split = true, splitStyle = true } -- the role icon is a badge on the circle; the value clear of the circle
Health.SPLIT_GAP = 4 -- the percent this far from the hub's edge
Health.SPLIT_GHOST_ALPHA = 0.62 -- the split bars' percent sits beside the hub, over the empty part as soon as health drops: ghosted but readable
Health.POWER_VALUE_TAGS = { '[power:current:shortvalue]', '[curpp]' } -- the first one the installed ElvUI has
Health.POWER_PERCENT_TAG = '[perpp<%]'
Health.VALUE_TAG = '[mMT-health:current:short]'
Health.PERCENT_TAG = '[perhp<%]'
Health.GHOST_ALPHA = 0.45
Health.GAP = 5 -- value | percent

local built = {}
local powerBuilt = {} -- 1.3.0 [unit frame] = the resource texts of a split frame

local function Texts(parent, def, ghost)
	local value = parent:CreateFontString(nil, 'OVERLAY')
	local percent = parent:CreateFontString(nil, 'OVERLAY')
	return { value = value, percent = percent, ghost = ghost }
end

-- the value's offset from the bar end: closer on the narrow (1.0.0) frames
function Health.X(def)
	if def.narrowX and (tonumber(Theme:DB().frameWidth) or 1) < 1 then return def.narrowX end
	return def.x
end

local function Place(set, bar, def)
	set.value:ClearAllPoints()
	set.percent:ClearAllPoints()
	if def.above then -- 1.3.1: over the bar - the value at its outer end, the percent at its inner end (clear of the hub)
		local opposite = (def.side == 'LEFT') and 'RIGHT' or 'LEFT'
		local px = def.percentX or 0
		set.value:SetPoint('BOTTOM' .. def.side, bar, 'TOP' .. def.side, def.x or 0, def.y or 2)
		set.percent:SetPoint('BOTTOM' .. opposite, bar, 'TOP' .. opposite, (opposite == 'RIGHT') and -px or px, def.y or 2)
		return
	end
	set.value:SetPoint(def.side, bar, def.side, Health.X(def), def.y or 1)
	if def.split then -- 0.6.0 target nameplate: value at the left end, percent at the right end (1.3.0: and the split bars, either way round)
		local opposite = (def.side == 'LEFT') and 'RIGHT' or 'LEFT'
		local px = def.percentX or math.abs(def.x)
		set.percent:SetPoint(opposite, bar, opposite, (opposite == 'RIGHT') and -px or px, def.y or 1)
	elseif def.side == 'LEFT' then
		set.percent:SetPoint('BOTTOMLEFT', set.value, 'BOTTOMRIGHT', Health.GAP, 1)
	else
		set.percent:SetPoint('BOTTOMRIGHT', set.value, 'BOTTOMLEFT', -Health.GAP, 1)
	end
end

local function Style(set, def)
	-- 1.3.1: the Player / Target numbers in the Banzai display font, every other frame's as before
	if def.display then
		Theme:SetDisplayFont(set.value, Theme:DisplaySize(def.value), 'OUTLINE')
	else
		set.value:SetFont(Theme:PreviousDisplayFont(), def.value, 'OUTLINE')
	end
	set.percent:SetFont(Theme:SmallFont(), def.percent, 'OUTLINE')
	local a = set.ghost and Health.GHOST_ALPHA or 1
	local accent = Theme:Accents()
	set.value:SetTextColor(1, 1, 1, a)
	set.percent:SetTextColor(accent[1], accent[2], accent[3], a)
	set.value:SetShadowOffset(1, -1)
	set.percent:SetShadowOffset(1, -1)
end

-- Both copies of the text on a status bar: the ghost underneath, the bright
-- copy inside a frame clipped to the bar's fill texture. Used by the unit
-- frames (ElvUI tags) and by the unit-frame preview (fixed sample text).
function Health:Attach(bar, def)
	if not (bar and bar.GetStatusBarTexture) then return end
	local fill = bar:GetStatusBarTexture()
	if not fill then return end
	local holder = CreateFrame('Frame', nil, bar)
	holder:SetAllPoints(bar)
	-- 0.8.0: always under ElvUI's raised texts (names / spec at level 100)
	holder:SetFrameLevel(math.min((bar:GetFrameLevel() or 10) + 3, 90))
	if def.above then -- 1.3.1: over the bar, nothing to clip: one bright copy
		local bright = Texts(holder, def, false)
		Place(bright, bar, def)
		Style(bright, def)
		return { holder = holder, bright = bright, def = def, sets = { bright } }
	end
	local ghost = Texts(holder, def, true)

	local clip = CreateFrame('Frame', nil, holder)
	clip:SetAllPoints(fill)
	if clip.SetClipsChildren then clip:SetClipsChildren(true) end
	clip:SetFrameLevel(holder:GetFrameLevel() + 1)
	local bright = Texts(clip, def, false)
	for _, set in ipairs({ ghost, bright }) do
		Place(set, bar, def)
		Style(set, def)
	end
	return { holder = holder, clip = clip, ghost = ghost, bright = bright, def = def, sets = { ghost, bright } }
end

function Health.Restyle(entry)
	for _, set in ipairs(entry.sets) do Style(set, entry.def) end
end

function Health:BuildFor(def)
	local frame = _G[def.frame]
	if not frame or built[frame] then return built[frame] end
	if not frame.Tag then return end
	local entry = self:Attach(frame.Health, def)
	if not entry then return end
	for _, set in ipairs(entry.sets) do
		frame:Tag(set.value, Health.VALUE_TAG)
		frame:Tag(set.percent, Health.PERCENT_TAG)
	end
	if frame.UpdateTags then pcall(frame.UpdateTags, frame) end
	built[frame] = entry
	return entry
end

-- 1.3.0 a split frame's definition at the current scales: the unit's font sizes,
-- the percent clear of the part of the bar the hub covers
function Health.SplitDef(def)
	local split = ns.Split
	local unit = split.UNITS[def.key]
	local g = split.Geometry(def.key)
	local out = {}
	for k, v in pairs(def) do out[k] = v end
	out.value, out.percent = unit.value, unit.percent
	out.percentX = g.tuck + Health.SPLIT_GAP
	return out
end

-- the first resource-value tag the installed ElvUI registered (nil: none, the value is left out)
function Health.PowerValueTag()
	local E = _G.ElvUI and _G.ElvUI[1]
	local methods = E and E.oUF and E.oUF.Tags and E.oUF.Tags.Methods
	for _, tag in ipairs(Health.POWER_VALUE_TAGS) do
		if methods and methods[string.sub(tag, 2, -2)] then return tag end
	end
	return nil
end

-- 1.3.0: the resource texts inside a split frame's power bar
function Health:BuildPower(def)
	local frame = _G[def.frame]
	if not frame or powerBuilt[frame] then return powerBuilt[frame] end
	if not (frame.Tag and frame.Power) then return end
	local entry = self:Attach(frame.Power, def)
	if not entry then return end
	local valueTag = Health.PowerValueTag()
	for _, set in ipairs(entry.sets) do
		if valueTag then frame:Tag(set.value, valueTag) end
		frame:Tag(set.percent, Health.POWER_PERCENT_TAG)
	end
	if frame.UpdateTags then pcall(frame.UpdateTags, frame) end
	powerBuilt[frame] = entry
	return entry
end

function Health:Build()
	local split = ns.Split and ns.Split.Session and ns.Split:Session() -- 1.3.0: the session's frame style
	if split then
		for _, def in ipairs(self.SPLIT_UNITS) do self:BuildFor(Health.SplitDef(def)) end
		for _, def in ipairs(self.SPLIT_POWER) do self:BuildPower(Health.SplitDef(def)) end
	else
		for _, def in ipairs(self.UNITS) do self:BuildFor(def) end
	end
	for _, group in ipairs(self.GROUPS) do
		local g = group
		if split and group.prefix == Health.SPLIT_PARTY.prefix and ns.Split:PartySplit() then g = Health.SPLIT_PARTY end
		for i = 1, g.count do
			self:BuildFor({ frame = g.prefix .. i, side = g.side, x = g.x, y = g.y, value = g.value, percent = g.percent, split = g.split, percentX = g.percentX, splitStyle = g.splitStyle })
		end
	end
	self:Refresh()
end

-- 1.3.0 the ghost copy of a split bar's text a little stronger (Style sets the classic 0.45 first)
-- (1.3.1: the texts above the Player / Target bars have no ghost copy)
local function SplitGhost(entry)
	if not entry.ghost then return end
	local accent = Theme:Accents()
	local a = Health.SPLIT_GHOST_ALPHA
	entry.ghost.value:SetTextColor(1, 1, 1, a)
	entry.ghost.percent:SetTextColor(accent[1], accent[2], accent[3], a)
end
Health.SplitGhost = SplitGhost

function Health:Refresh()
	local db = Theme:DB()
	local active = ns.Compat and ns.Compat.Active and ns.Compat.Active()
	for _, entry in pairs(built) do
		-- 1.3.0: the split bars follow BANZAI SPLIT's HP text choice, the classic ones "health inside"
		local on = entry.def.splitStyle and db.splitHpText ~= false or (not entry.def.splitStyle and db.healthInside)
		entry.holder:SetShown(active and on and true or false)
		for _, set in ipairs(entry.sets) do
			Style(set, entry.def)
			set.percent:SetShown(entry.def.splitStyle or db.healthPercent ~= false)
		end
		if entry.def.splitStyle then SplitGhost(entry) end
	end
	for frame, entry in pairs(powerBuilt) do
		local split = ns.Split and ns.Split:Get(frame.GetName and frame:GetName() or '')
		entry.holder:SetShown(active and db.splitPowerText ~= false and not (split and split.noPower) and true or false)
		for _, set in ipairs(entry.sets) do Style(set, entry.def) end
		SplitGhost(entry)
	end
end

function Health:Get(frameName)
	return built[_G[frameName]]
end

function Health:GetPower(frameName)
	return powerBuilt[_G[frameName]]
end
