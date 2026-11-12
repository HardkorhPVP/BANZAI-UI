--[[
	BANZAI (private Bushido restoration) - Transform.lua
	Part of BANZAI UI.

	Pure table transforms that carry the historical Bushido configuration
	(ElvUI 14.x / mMediaTag 3.73 era) onto the addon versions installed today
	(ElvUI 16, Eltruism 5.1.6, mMediaTag 4.18), plus the Banzai layer:
	  0.2.0  minimap cluster on the top right, extra mana bar on the player chassis
	  0.3.0  identity line (NAME - SPEC / SPEC - NAME), health value + percent,
	         readable small-text font (heavy font kept for big numbers and
	         headings), chat panel backdrops off, Bushido datatext panel replaced
	         by the Banzai bottom bar
	  0.4.0 / 0.5.x  nameplates, auras, ToT, smooth bars, circular action buttons
	  0.6.0  action bars clear of the bottom panel, smaller keybinds, Details
	         titles / sleek rows, enemy names above their bar, party role icons,
	         role-aware (DPS / HEALER) group frame positions, and the
	         per-character part of the layer (Character Sync)
	  0.7.0  HEALER party / arena allies in one horizontal row in the centre;
	         secondary frames: health inside the bars, identity circles in
	         place of mMediaTag portraits, raid percent; Details titles drawn
	         by Banzai, rows lower, no percentage in the meter values
	  0.8.0  PvP-first unit frames through ElvUI's own elements: cast colours,
	         dispel glow, party CC / debuffs / defensives placed per role, raid
	         role icons and a raid debuff, focus / boss cast bars, one arena enemy
	         system, subordinate ToT / pet (1.0.1: Banzai's arena frames only)
	  0.9.0  party / arena frames 100 wide (HEALER 30 % lower) with the role
	         icon in the bar, only crowd control and a dispellable effect as
	         auras; DPS party / arena allies on the left edge aligned with the
	         raid frames, arena enemies mirrored on the right edge (Banzai's
	         design on ElvUI's arena frames, trinket circle by Banzai Art)
	  1.0.0  Player / Target / Focus / Target-of-Target at half Bushido's width
	         (height unchanged, nothing scaled): every frame keeps its inner
	         end, the outer half goes; their bars, texts and the identity line
	         (name and spec on two lines) reflow; the HEALER row lower, just
	         above the Player / Target / Focus region; ElvUI's AFK screen off
	         while Banzai's own is on; tooltip fonts for the Banzai tooltip theme
	  1.3.0  the optional BANZAI SPLIT frame style (T.ApplyFrameStyle: Player /
	         Target / Focus / Target-of-Target / party in the split construction,
	         written over the classic layer and taken back exactly) and the
	         BANZAI COMPACT Details rows; BANZAI CLASSIC / CURRENT are unchanged
	  1.3.3  BANZAI SPLIT Player / Target: the central hub 25 % larger (the bars
	         keep their size and sit as far from its edge as before: T.SPLIT
	         identity, Banzai Art's Split.UNITS the same numbers) and, while the
	         bamboo cast bar is on, the class bar above it (T.SPLIT.castbar);
	         T.SPLIT.version 3 rewrites a split character's layer once; BANZAI
	         CLASSIC is unchanged
	  1.3.4  the bamboo cast bar about 40 % lower (Banzai Art's numbers): the
	         class bar follows it down; T.SPLIT version 4
	No WoW API is used here, so the whole file runs in the offline tests.
]]
local _, ns = ...
ns = ns or {}

local T = {}
ns.Transform = T

T.PROFILE = 'JiberishUI - Bushido Private'
T.FONT = 'GasoekOne'          -- display font: closest licensed stand-in for Lixdu (see README)
T.FALLBACK_FONT = 'Expressway' -- ElvUI's own font, always registered
T.SMALL_FONT = 'Rubik-Bold'   -- readable small text (JiberishMedia, SIL OFL)

-- Fonts that no longer exist. Lixdu was removed from JiberishMedia 1.1.0
-- (redistribution permission not established); Meow Pepsi was never public.
T.MISSING_FONTS = { ['Lixdu'] = true, ['Meow Pepsi'] = true }
-- Fonts that exist under a neighbouring name.
T.FONT_ALIASES = { ['Montserrat-Black'] = 'Montserrat-Bold' }

-- mMediaTag 3.x tags -> mMediaTag 4.17 / ElvUI tags. Plain-text replacements.
T.TAG_MAP = {
	{ '[mHealth:current-percent:short]', '[mMT-health:current:short]' },
	{ '[mHealth:short]', '[mMT-health:short]' },
	{ '[mPower:percent:combat]', '[perpp]' },
	{ '[mClass:icon:noelite]', '[mMT-classification:icon]' },
	{ '[mClass:short]', '[mMT-classification:short]' },
	{ '[ >mTargetingPlayers:icons:Role]', '' }, -- no 4.x equivalent
	{ '[ >mTargetingPlayers:icons:SQ]', '' },   -- no 4.x equivalent
	{ '[mColor:rare]', '[mMT-color]' },
	{ '[mColor:target]', '[mMT-color:target]' },
	{ '[mTarget:abbrev:veryshort]', '[target:veryshort]' },
	{ '[ - >mLevel]', '[ - >mMT-level]' },
	{ '[mLevel<||r]', '[mMT-level<||r]' },
}

-- mMediaTag 3.x portrait texture keys -> 4.17 keys
T.PORTRAIT_TEXTURES = { thincircle = 'circle', CI = 'circle', RA = 'circle' }

-- default anchor of each 4.17 portrait (used when 3.x stored only x/y)
T.PORTRAIT_POINTS = {
	player = { 'RIGHT', 'LEFT' },
	target = { 'LEFT', 'RIGHT' },
	focus = { 'LEFT', 'RIGHT' },
	targettarget = { 'LEFT', 'RIGHT' },
	pet = { 'RIGHT', 'LEFT' },
	party = { 'RIGHT', 'LEFT' },
	boss = { 'LEFT', 'RIGHT' },
	arena = { 'LEFT', 'RIGHT' },
}

-- the current radial cast ring replaces Bushido's cast-ring WeakAuras
T.CAST_RING_UNITS = { player = true, target = true, focus = true }

---------------------------------------------------------------------------
-- Banzai layer (0.2.0 + 0.3.0 + 0.4.0 + 0.5.0)
---------------------------------------------------------------------------
T.LAYER = 12 -- 1.0.0: characters already on 0.9.0 get the new layer at their next login

-- 0.3.0 identity line. Spec comes from the Banzai tags (BushidoPrivateCompat);
-- units without a known spec (NPCs) show the name alone.
T.IDENTITY = {
	player = '[name:eltruism:gradientshortcaps][banzai:spec:after]',
	target = '[banzai:spec:before][name:eltruism:gradientshortcaps{10}]',
}
T.IDENTITY_SIZE = 11

-- 0.3.0 health block: value (display font, dominant) and percent (small font,
-- Banzai green) meet at a fixed seam, so the pair stays together at any value
-- width; mirrored on the target side. Offsets are ElvUI custom-text offsets
-- from the health bar edge named by justifyH (health width = frame width - 2).
T.PERCENT_FORMAT = '|cff9cff4d[perhp<%]|r'
T.HEALTH = {
	player = { value = { 'RIGHT', -212, -54, 20 }, percent = { 'LEFT', 92, -57, 13 } },
	target = { value = { 'LEFT', 212, -54, 20 }, percent = { 'RIGHT', -92, -57, 13 } },
	focus = { value = { 'RIGHT', -148, -41, 14 }, percent = { 'LEFT', 64, -42.5, 10 } },
	party = { value = { 'RIGHT', -76, 15, 12 }, percent = { 'LEFT', 126, 14, 9 } },
	arena = { value = { 'RIGHT', -158, 9, 12 }, percent = { 'LEFT', 44, 8, 9 } },
}

-- 0.3.0 font split: the heavy display font stays on big health numbers and
-- large zone headings; every other font setting Bushido gave it becomes the
-- readable small-text font (names, nameplates, power values, auras, datatexts,
-- cooldown numbers...). Blizzard quest / story font replacements Bushido left
-- disabled stay disabled.
function T.IsDisplayFontPath(path)
	return string.find(path, 'customTexts%.m%-Health%.font$') ~= nil
		or string.find(path, '^general%.fonts%.worldzone%.') ~= nil
		or string.find(path, '^general%.fonts%.worldsubzone%.') ~= nil
		or string.find(path, '^general%.fonts%.pvpzone%.') ~= nil
		or string.find(path, '^general%.fonts%.pvpsubzone%.') ~= nil
		or path == 'general.dmgfont' -- floating combat numbers (private)
end

-- The minimap moves from the top-left to the top-right corner. The pieces
-- Bushido grouped around it move with it, mirrored: buffs / debuffs beside it,
-- the queue eye on it, the durability figure above it.
T.MIRRORED_MOVERS = { 'MinimapMover', 'BuffsMover', 'DebuffsMover', 'QueueStatusMover', 'DurabilityFrameMover' }
T.MIRROR_GROWTH = {
	RIGHT_DOWN = 'LEFT_DOWN', RIGHT_UP = 'LEFT_UP', LEFT_DOWN = 'RIGHT_DOWN', LEFT_UP = 'RIGHT_UP',
	DOWN_RIGHT = 'DOWN_LEFT', DOWN_LEFT = 'DOWN_RIGHT', UP_RIGHT = 'UP_LEFT', UP_LEFT = 'UP_RIGHT',
}

-- ElvUI 16 draws druid / priest / shaman mana as a separate "Additional Class
-- Power" bar. The Bushido profile predates it, so ElvUI used its built-in spot
-- (BOTTOM 0,150, 260 x 12): the lone blue bar between the action bars. Banzai
-- stacks it on the player chassis as a thin bar directly above the class bar
-- (ClassBarMover 399,342, 305 x 5).
T.ADDITIONAL_POWER = { mover = 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,399,348', width = 305, height = 6 }

local function SwapSides(text)
	return (string.gsub(string.gsub(string.gsub(text, 'LEFT', '#'), 'RIGHT', 'LEFT'), '#', 'RIGHT'))
end

-- 'TOPLEFT,UIParent,TOPLEFT,21,-36' -> 'TOPRIGHT,UIParent,TOPRIGHT,-21,-36'
function T.MirrorMover(value)
	local point, anchor, relative, x, y = string.match(value or '', '^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$')
	local n = tonumber(x)
	if not (point and n) then return value end
	local mirrored = (n == 0) and '0' or tostring(-n)
	return table.concat({ SwapSides(point), anchor, SwapSides(relative), mirrored, y }, ',')
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
function T.DeepCopy(value)
	if type(value) ~= 'table' then return value end
	local copy = {}
	for k, v in pairs(value) do copy[k] = T.DeepCopy(v) end
	return copy
end

-- Deterministic text form of a settings value (sorted keys): compares two
-- configurations (Character Sync revisions, the character layer owner).
function T.Serialize(value)
	if type(value) ~= 'table' then
		if type(value) == 'number' then return string.format('%.4f', value) end
		return type(value) .. ':' .. tostring(value)
	end
	local keys = {}
	for k in pairs(value) do keys[#keys + 1] = k end
	table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
	local out = {}
	for _, k in ipairs(keys) do out[#out + 1] = tostring(k) .. '=' .. T.Serialize(value[k]) end
	return '{' .. table.concat(out, ',') .. '}'
end

-- 'debuffs.anchorPoint' style paths into nested settings (role layouts of the party header)
function T.GetPath(tbl, path)
	local node = tbl
	for part in string.gmatch(path, '[^%.]+') do
		if type(node) ~= 'table' then return nil end
		node = node[part]
	end
	return node
end

function T.SetPath(tbl, path, value)
	local parts = {}
	for part in string.gmatch(path, '[^%.]+') do parts[#parts + 1] = part end
	local node = tbl
	for i = 1, #parts - 1 do
		if type(node[parts[i]]) ~= 'table' then
			if value == nil then return end
			node[parts[i]] = {}
		end
		node = node[parts[i]]
	end
	node[parts[#parts]] = value
end

-- Writes every leaf of `source` into `target`.
function T.Overlay(target, source)
	for k, v in pairs(source) do
		if type(v) == 'table' then
			if type(target[k]) ~= 'table' then target[k] = {} end
			T.Overlay(target[k], v)
		else
			target[k] = v
		end
	end
	return target
end

local function ReplacePlain(text, old, new)
	local out, start = {}, 1
	while true do
		local i, j = string.find(text, old, start, true)
		if not i then break end
		out[#out + 1] = string.sub(text, start, i - 1)
		out[#out + 1] = new
		start = j + 1
	end
	out[#out + 1] = string.sub(text, start)
	return table.concat(out)
end
T.ReplacePlain = ReplacePlain

-- Replaces font names anywhere in a settings table. `isValid(name)` (optional)
-- decides whether an alias exists; otherwise the stand-in font is used.
function T.ReplaceFonts(tbl, font, isValid, counter)
	counter = counter or { replaced = 0 }
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			T.ReplaceFonts(v, font, isValid, counter)
		elseif type(v) == 'string' then
			if T.MISSING_FONTS[v] then
				tbl[k] = font
				counter.replaced = counter.replaced + 1
			elseif T.FONT_ALIASES[v] then
				local alias = T.FONT_ALIASES[v]
				tbl[k] = (not isValid or isValid(alias)) and alias or font
				counter.replaced = counter.replaced + 1
			end
		end
	end
	return counter.replaced
end

-- Sets every font setting the historical table gave Lixdu / Meow Pepsi to the
-- display or the small font (see T.IsDisplayFontPath). `target` is the table in
-- use; missing sub-tables are created. Returns the number of settings written.
function T.SplitFonts(target, historical, display, small, path, counter)
	counter = counter or { n = 0 }
	for k, v in pairs(historical or {}) do
		local key = path and (path .. '.' .. tostring(k)) or tostring(k)
		if type(v) == 'table' then
			if type(target[k]) ~= 'table' then target[k] = {} end
			T.SplitFonts(target[k], v, display, small, key, counter)
			if next(target[k]) == nil then target[k] = nil end
		elseif type(v) == 'string' and T.MISSING_FONTS[v] then
			target[k] = T.IsDisplayFontPath(key) and display or small
			counter.n = counter.n + 1
		end
	end
	return counter.n
end

function T.RemapTags(tbl, counter)
	counter = counter or { replaced = 0 }
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			T.RemapTags(v, counter)
		elseif type(v) == 'string' and string.find(v, '[', 1, true) then
			local text = v
			for _, pair in ipairs(T.TAG_MAP) do
				local updated = ReplacePlain(text, pair[1], pair[2])
				if updated ~= text then counter.replaced = counter.replaced + 1 end
				text = updated
			end
			tbl[k] = text
		end
	end
	return counter.replaced
end

-- Lists every leaf of a table as { path = { k1, k2, ... }, value = v }.
function T.Leaves(tbl, prefix, out)
	out = out or {}
	prefix = prefix or {}
	for k, v in pairs(tbl) do
		local path = {}
		for i, p in ipairs(prefix) do path[i] = p end
		path[#path + 1] = k
		if type(v) == 'table' then
			T.Leaves(v, path, out)
		else
			out[#out + 1] = { path = path, value = v }
		end
	end
	return out
end

-- Reads a leaf without triggering defaults metatables.
function T.RawGetPath(tbl, path)
	local node = tbl
	for i = 1, #path do
		if type(node) ~= 'table' then return nil end
		node = rawget(node, path[i])
	end
	return node
end

function T.RawSetPath(tbl, path, value)
	local node = tbl
	for i = 1, #path - 1 do
		local nextNode = rawget(node, path[i])
		if type(nextNode) ~= 'table' then
			if value == nil then return end
			nextNode = {}
			rawset(node, path[i], nextNode)
		end
		node = nextNode
	end
	rawset(node, path[#path], value)
end

-- Records the current value of every path a payload is about to write, and
-- how much of the path already existed (so a revert can drop what apply created).
function T.Snapshot(tbl, leaves)
	local snapshot = {}
	for i, leaf in ipairs(leaves) do
		local current = T.RawGetPath(tbl, leaf.path)
		local existing, node = 0, tbl
		for d = 1, #leaf.path - 1 do
			node = type(node) == 'table' and rawget(node, leaf.path[d]) or nil
			if type(node) ~= 'table' then break end
			existing = d
		end
		snapshot[i] = { path = leaf.path, value = current, wasNil = current == nil, existingDepth = existing }
	end
	return snapshot
end

-- Removes now-empty tables below `keepDepth` along a path.
local function PruneEmpty(tbl, path, keepDepth)
	for depth = #path - 1, keepDepth + 1, -1 do
		local parent = tbl
		for d = 1, depth - 1 do
			parent = rawget(parent, path[d])
			if type(parent) ~= 'table' then return end
		end
		local node = rawget(parent, path[depth])
		if type(node) == 'table' and next(node) == nil then
			rawset(parent, path[depth], nil)
		else
			return
		end
	end
end

function T.ApplyLeaves(tbl, leaves)
	for _, leaf in ipairs(leaves) do T.RawSetPath(tbl, leaf.path, leaf.value) end
end

function T.RevertSnapshot(tbl, snapshot)
	for _, entry in ipairs(snapshot) do
		if entry.wasNil then
			T.RawSetPath(tbl, entry.path, nil)
			PruneEmpty(tbl, entry.path, entry.existingDepth or #entry.path - 1)
		else
			T.RawSetPath(tbl, entry.path, entry.value)
		end
	end
end

---------------------------------------------------------------------------
-- mMediaTag 3.73 (E.db.mMT) -> mMediaTag 4.17 (E.db.mMediaTag)
---------------------------------------------------------------------------
-- 3.73 anchored a portrait frame of `size`; 4.17 anchors a frame of size / 2
-- with the portrait texture centred on it (modules/portraits/functions.lua,
-- UpdateSize). The same offsets therefore put the 4.17 portrait size / 4
-- further inside the unit frame, over the name and health numeral (seen on
-- Player and Target in 0.1.0). Shift by size / 4 to restore the old centre.
function T.PortraitOffset(point, size, x, y)
	local q = (tonumber(size) or 0) / 4
	x, y = x or 0, y or 0
	if string.find(point, 'RIGHT', 1, true) then x = x - q elseif string.find(point, 'LEFT', 1, true) then x = x + q end
	if string.find(point, 'TOP', 1, true) then y = y - q elseif string.find(point, 'BOTTOM', 1, true) then y = y + q end
	return x, y
end

function T.BuildMediaTag(old, font)
	old = old or {}
	local oldPortraits = old.portraits or {}
	local general = oldPortraits.general or {}
	local shadowColor = oldPortraits.shadow and oldPortraits.shadow.color

	local portraits = {
		enable = general.enable ~= false,
		misc = { class_icon = general.classiconstyle or 'none' },
		shadow = { enable = true, alpha = (shadowColor and shadowColor.a) or 0.6 },
	}

	for unit, points in pairs(T.PORTRAIT_POINTS) do
		local o = oldPortraits[unit] or {}
		local point = o.point or points[1]
		local x, y = o.x or 0, o.y or 0
		if o.size then x, y = T.PortraitOffset(point, o.size, x, y) end
		local u = {
			enable = o.enable ~= false,
			size = o.size,
			texture = T.PORTRAIT_TEXTURES[o.texture] or (o.texture and 'circle') or nil,
			point = { point = point, relativePoint = o.relativePoint or points[2], x = x, y = y },
			strata = o.strata,
			level = o.level,
			mirror = o.mirror,
			cast = o.cast or nil,
		}
		if T.CAST_RING_UNITS[unit] then
			u.cast = true
			u.ring = { mode = 'cast' }
		end
		portraits[unit] = u
	end

	return {
		db_version = 3,
		portraits = portraits,
		difficulty_info = { enable = (old.instancedifficulty and old.instancedifficulty.enable) or false, text = { font = font } },
		important_casts = { enable = (old.importantspells and old.importantspells.enable) or false },
		interrupt_on_cd = { enable = (old.interruptoncd and old.interruptoncd.enable) or false },
	}
end

---------------------------------------------------------------------------
-- Whole payloads
---------------------------------------------------------------------------
-- ElvUI profile: keep every historical value, move mMediaTag to its current
-- namespace, swap unavailable fonts, remap renamed tags.
function T.TransformProfile(profile, font, isValid, smallFont, opts)
	local fonts = { display = font, small = smallFont or T.SMALL_FONT }
	local p = T.DeepCopy(profile)
	local oldMediaTag = p.mMT
	p.mMT = nil
	p.mMediaTag = T.BuildMediaTag(oldMediaTag, fonts.small)
	local report = {
		fonts = T.ReplaceFonts(p, font, isValid),
		tags = T.RemapTags(p),
		mediaTagMigrated = oldMediaTag ~= nil,
	}
	T.ApplyBanzaiProfile(p, profile, fonts, opts)
	return p, report
end

local function Ensure(tbl, ...)
	local node = tbl
	for i = 1, select('#', ...) do
		local key = select(i, ...)
		if type(node[key]) ~= 'table' then node[key] = {} end
		node = node[key]
	end
	return node
end
T.Ensure = Ensure

local function CustomText(texts, name, spec, format, font, keep)
	local db = texts[name] or {}
	texts[name] = db
	db.text_format = format
	db.attachTextTo = 'Health'
	db.justifyH, db.xOffset, db.yOffset, db.size = spec[1], spec[2], spec[3], spec[4]
	db.font = font
	if not keep then db.fontOutline = db.fontOutline or 'OUTLINE' end
	db.enable = true
	return db
end

-- 0.3.0 part of the layer: identity line, health block, fonts, chat, bottom panel.
function T.ApplyBanzaiTexts(p, historical, fonts)
	fonts = fonts or { display = T.FONT, small = T.SMALL_FONT }
	local fontCount = T.SplitFonts(p, historical, fonts.display, fonts.small)
	local units = Ensure(p, 'unitframe', 'units')
	for unit, format in pairs(T.IDENTITY) do
		local texts = Ensure(units, unit, 'customTexts')
		local name = texts['m-Name'] or {}
		texts['m-Name'] = name
		name.text_format = format
		name.size = T.IDENTITY_SIZE
		name.font = fonts.small
		name.enable = true
	end
	for unit, spec in pairs(T.HEALTH) do
		local texts = Ensure(units, unit, 'customTexts')
		CustomText(texts, 'm-Health', spec.value, '[mMT-health:current:short]', fonts.display, true)
		CustomText(texts, 'b-HealthPct', spec.percent, T.PERCENT_FORMAT, fonts.small)
	end
	local difficulty = type(p.mMediaTag) == 'table' and p.mMediaTag.difficulty_info
	if type(difficulty) == 'table' then Ensure(difficulty, 'text').font = fonts.small end -- small label on the minimap
	local chat = Ensure(p, 'chat')
	chat.panelBackdrop = 'HIDEBOTH' -- no black box behind the (empty) right chat panel or the Details meters
	chat.hideChatToggles = true
	Ensure(p, 'movers').LeftChatMover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,0,26' -- clear of the bottom bar
	Ensure(p, 'datatexts', 'panels', 'Bushido').enable = false -- replaced by the Banzai bottom bar
	return fontCount
end

-- Fonts only (options page): the split plus the Banzai texts, leaving their
-- other settings (percent on/off, spec on/off, number size) as they are.
function T.ApplyBanzaiFonts(p, historical, fonts)
	local n = T.SplitFonts(p, historical, fonts.display, fonts.small)
	local units = Ensure(p, 'unitframe', 'units')
	for unit in pairs(T.IDENTITY) do
		local name = units[unit] and units[unit].customTexts and units[unit].customTexts['m-Name']
		if name then name.font = fonts.small end
	end
	for unit in pairs(T.HEALTH) do
		local texts = units[unit] and units[unit].customTexts
		if texts and texts['m-Health'] then texts['m-Health'].font = fonts.display end
		if texts and texts['b-HealthPct'] then texts['b-HealthPct'].font = fonts.small end
	end
	local difficulty = type(p.mMediaTag) == 'table' and p.mMediaTag.difficulty_info
	if type(difficulty) == 'table' then Ensure(difficulty, 'text').font = fonts.small end
	return n
end

-- Banzai layer on an ElvUI profile table (fresh or already in use). Only these
-- keys are written, so an upgrade keeps everything else the profile holds.
-- `historical` is the decoded Bushido profile (the source of the mirrored values).
function T.ApplyBanzaiProfile(p, historical, fonts, opts)
	historical = historical or {}
	T.RevertFrameStyle(p, opts and opts.splitState) -- 1.3.0: a split layer goes before the full rewrite
	T.ApplyBanzaiTexts(p, historical, fonts)
	local movers = historical.movers or {}
	p.movers = p.movers or {}
	for _, name in ipairs(T.MIRRORED_MOVERS) do
		local value = movers[name]
		if type(value) == 'string' and string.find(value, 'LEFT', 1, true) then
			p.movers[name] = T.MirrorMover(value)
		end
	end
	for _, kind in ipairs({ 'buffs', 'debuffs' }) do
		local old = historical.auras and historical.auras[kind]
		local mirrored = old and T.MIRROR_GROWTH[old.growthDirection]
		if mirrored then
			p.auras = p.auras or {}
			p.auras[kind] = p.auras[kind] or {}
			p.auras[kind].growthDirection = mirrored
		end
	end

	p.movers.AdditionalPowerMover = T.ADDITIONAL_POWER.mover
	p.unitframe = p.unitframe or {}
	p.unitframe.units = p.unitframe.units or {}
	p.unitframe.units.player = p.unitframe.units.player or {}
	local additional = p.unitframe.units.player.classAdditional or {}
	additional.width = T.ADDITIONAL_POWER.width
	additional.height = T.ADDITIONAL_POWER.height
	p.unitframe.units.player.classAdditional = additional

	local portraits = type(p.mMediaTag) == 'table' and p.mMediaTag.portraits
	if type(portraits) == 'table' then
		local fresh = T.BuildMediaTag(historical.mMT).portraits
		for unit in pairs(T.PORTRAIT_POINTS) do
			if type(portraits[unit]) == 'table' and fresh[unit] then
				portraits[unit].point = T.DeepCopy(fresh[unit].point)
			end
		end
	end
	T.ApplyBanzai040(p, fonts)
	T.ApplyBanzai050(p)
	T.ApplyUnitFrames060(p)
	T.ApplyCharacterLayer(p, historical, fonts, opts)
	return p
end

---------------------------------------------------------------------------
-- 0.4.0 part of the layer
---------------------------------------------------------------------------
-- Nameplates: Bushido's nameplate texture keeps its visible band in a thin
-- strip and Eltruism's "health height" option shrank bars to 2 out of combat:
-- the bars read as lines. Compact solid bars now, through the same settings.
T.NAMEPLATE_UNITS = { 'PLAYER', 'FRIENDLY_PLAYER', 'ENEMY_PLAYER', 'FRIENDLY_NPC', 'ENEMY_NPC' }
T.NAMEPLATES = {
	statusbar = 'Banzai', height = 12, nameSize = 11, healthTextSize = 10, nameYOffset = 3,
	castHeight = 8, castYOffset = -13, castIcon = 18, castWidth = 150,
	outOfCombat = 11, inCombat = 13, targetGlow = 'style7', glowColor = { r = 0.62, g = 1, b = 0.12, a = 1 },
}
T.ENEMY_NAMEPLATES = { 'ENEMY_PLAYER', 'ENEMY_NPC' }
-- Health inside the bars (BushidoPrivateCompat Health.lua) for these units:
-- their ElvUI health custom texts are switched off while it is on.
-- 0.7.0: the secondary frames too (party / arena allies, arena enemies, boss).
T.HEALTH_INSIDE_UNITS = { 'player', 'target', 'focus', 'party', 'arena', 'boss' }
-- Raid frames keep it compact: the percentage alone at the right end of the
-- bar (ElvUI's own raid health text, light grey), the short name stays left.
T.RAID_UNITS = { 'raid1', 'raid2', 'raid3' }
T.RAID_PERCENT = { format = '|cffdde3e8[perhp<%]|r', justifyH = 'RIGHT', xOffset = -3, yOffset = 0, size = 9 }
-- Buffs top-left at 70 % of Bushido's 35 x 30, debuffs below them at full size.
T.AURAS = { buffs = 'TOPLEFT,UIParent,TOPLEFT,14,-14', debuffs = 'TOPLEFT,UIParent,TOPLEFT,14,-104', scale = 0.7 }
-- Minimap a little lower so the zone name fits above its frame; the queue eye
-- moves with it, the durability figure goes to its left (the label is above it).
T.MINIMAP_040 = {
	MinimapMover = 'TOPRIGHT,UIParent,TOPRIGHT,-21,-48',
	QueueStatusMover = 'TOPRIGHT,UIParent,TOPRIGHT,-60,-201', -- clear of the corner bundle
	DurabilityFrameMover = 'TOPRIGHT,ElvUIParent,TOPRIGHT,-240,-60',
}
-- Target-of-Target: smaller and under the left part of the Target frame, clear of
-- the target name, the action cluster and the Details frame.
T.TOT = { scale = 0.72, mover = 'BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-563,256', power = 'BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-563,251' }
-- Large circular class anchor (mMediaTag portraits): Jiberish "Fabled Class"
-- in place of Bushido's "Fabled Dimension". mMediaTag registers the Jiberish
-- Icons class styles itself (its JiberishIcons integration) and uses the style
-- for player units only; NPCs keep their portrait, and a missing style or class
-- falls back to the portrait as well. Spec icons stay off (spec is text).
T.CLASS_ICON = 'fabledclass'

local function Round(n) return math.floor(n + 0.5) end

---------------------------------------------------------------------------
-- 1.0.0 part of the layer: Player / Target / Focus / Target-of-Target width
---------------------------------------------------------------------------
-- Their width as a share of Bushido's (0.5 .. 1; 1.0.0: 0.5). Heights stay and
-- nothing is scaled: every frame keeps its INNER end where it was and loses
-- the outer part - Player / Target their ends at the centre composition
-- (bamboo, combat tree, cast history), Focus its left end on the Player's,
-- Target-of-Target its left end under the Target's. Their power, class and
-- extra mana bars lose the same length at the same end; the Player / Target
-- movers also take Darren's own height / spread (BANZAI > UNIT FRAMES).
T.FRAME_WIDTH = 0.5
T.TOT_DROP = 14 -- Target-of-Target this much lower while the Target's spec has its own line
T.SPEC_LINE = 16 -- health under the bar (health inside off): this much lower, clear of the spec line
T.TOT_OUTSIDE_DROP = 30 -- ... and the Target-of-Target lower again, clear of the Target's health under its bar
function T.FrameWidth(value)
	value = tonumber(value) or T.FRAME_WIDTH
	return math.max(0.5, math.min(1, value))
end

-- side 1: the outer end is the left one (it moves right), -1 mirrored;
-- layout: moved by BANZAI > UNIT FRAMES height / spread too
T.WIDTH_MOVERS = {
	{ name = 'ElvUF_PlayerMover', unit = 'player', side = 1, layout = true },
	{ name = 'PlayerPowerBarMover', unit = 'player', side = 1, layout = true },
	{ name = 'ClassBarMover', unit = 'player', side = 1, layout = true },
	{ name = 'AdditionalPowerMover', unit = 'player', side = 1, layout = true },
	{ name = 'ElvUF_TargetMover', unit = 'target', side = -1, layout = true },
	{ name = 'TargetPowerBarMover', unit = 'target', side = -1, layout = true },
	{ name = 'ElvUF_FocusMover', unit = 'player', side = 1, layout = true }, -- Focus: its left end on the Player's left end
	{ name = 'FocusPowerBarMover', unit = 'player', side = 1, layout = true },
	{ name = 'ElvUF_FocusCastbarMover', unit = 'player', side = 1, layout = true },
}
-- the identity line on narrow frames: the name where it was, the spec on its own line under it
T.IDENTITY_SPLIT = {
	player = { name = '[name:eltruism:gradientshortcaps]', spec = { 'LEFT', 12, -45, 10 } },
	target = { name = '[name:eltruism:gradientshortcaps{10}]', spec = { 'RIGHT', -16, -45, 10 } },
}
T.SPEC_TAG = '[banzai:spec]'

-- one line (full width) or two (narrow); whether the spec shows at all is
-- read from the profile (BANZAI > APPEARANCE "Specialization in names")
function T.ApplyIdentityLines(p, split, font)
	local units = Ensure(p, 'unitframe', 'units')
	for unit, line in pairs(T.IDENTITY_SPLIT) do
		local texts = units[unit] and units[unit].customTexts
		local name = texts and texts['m-Name']
		if name then
			local spec = texts['b-Spec']
			local on = (spec and spec.enable == true) or string.find(name.text_format or '', 'banzai:spec', 1, true) ~= nil
			if split then
				name.text_format = line.name
				spec = CustomText(texts, 'b-Spec', line.spec, T.SPEC_TAG, name.font or font or T.SMALL_FONT)
				spec.size = line.spec[4]
				spec.enable = on
			else
				name.text_format = on and T.IDENTITY[unit] or line.name
				if spec then spec.enable = false end
			end
		end
	end
end

-- Darren's own text choices that live only in the profile (BANZAI > APPEARANCE:
-- spec in the names, the health number size): read before an upgrade rewrites
-- the texts, put back after it
function T.TextChoices(p)
	local units = p and p.unitframe and p.unitframe.units
	if type(units) ~= 'table' then return nil end
	local out = {}
	for unit in pairs(T.IDENTITY_SPLIT) do
		local texts = units[unit] and units[unit].customTexts
		local name = texts and texts['m-Name']
		if name then
			local spec = texts['b-Spec']
			out[unit] = {
				spec = (spec and spec.enable == true) or string.find(name.text_format or '', 'banzai:spec', 1, true) ~= nil,
				size = texts['m-Health'] and texts['m-Health'].size,
			}
		end
	end
	return out
end

function T.RestoreTextChoices(p, choices)
	if type(choices) ~= 'table' then return end
	local units = Ensure(p, 'unitframe', 'units')
	for unit, keep in pairs(choices) do
		local texts = units[unit] and units[unit].customTexts
		if texts and texts['m-Name'] then
			if not keep.spec then
				texts['m-Name'].text_format = T.IDENTITY_SPLIT[unit].name
				if texts['b-Spec'] then texts['b-Spec'].enable = false end
			end
			if keep.size and texts['m-Health'] then texts['m-Health'].size = keep.size end
		end
	end
end

function T.ApplyFrameWidths(p, historical, opts, font)
	opts = opts or {}
	historical = historical or {}
	local width = T.FrameWidth(opts.frameWidth)
	local old = (historical.unitframe and historical.unitframe.units) or {}
	local units = Ensure(p, 'unitframe', 'units')
	local cuts = {}
	for _, unit in ipairs({ 'player', 'target', 'focus' }) do
		local was = old[unit] or {}
		local full = was.width or ((unit == 'focus') and 210 or 302)
		local db = Ensure(units, unit)
		db.width = Round(full * width)
		cuts[unit] = full - db.width
		Ensure(db, 'power').detachedWidth = ((was.power and was.power.detachedWidth) or full) - cuts[unit]
	end
	local player, oldPlayer = units.player, old.player or {}
	Ensure(player, 'classbar').detachedWidth = ((oldPlayer.classbar and oldPlayer.classbar.detachedWidth) or 305) - cuts.player
	Ensure(player, 'classAdditional').width = T.ADDITIONAL_POWER.width - cuts.player
	local perrow = oldPlayer.buffs and oldPlayer.buffs.perrow
	if perrow then Ensure(player, 'buffs').perrow = math.max(1, math.floor(perrow * width)) end
	local focusCast = old.focus and old.focus.castbar and old.focus.castbar.width
	if focusCast then Ensure(units.focus, 'castbar').width = focusCast - cuts.focus end
	local movers = Ensure(p, 'movers')
	local oldMovers = historical.movers or {}
	local spread, height = tonumber(opts.unitSpread) or 0, tonumber(opts.unitHeight) or 0
	for _, m in ipairs(T.WIDTH_MOVERS) do
		local base = (m.name == 'AdditionalPowerMover') and T.ADDITIONAL_POWER.mover or oldMovers[m.name]
		if type(base) == 'string' then
			movers[m.name] = T.ShiftMover(base, m.side * (cuts[m.unit] + (m.layout and spread or 0)), m.layout and height or 0)
		end
	end
	-- health under the bar (when it is not inside): the value is measured from the
	-- frame's inner end, the percent from its outer end - the pair stays together
	-- on the narrow bar, under the spec line
	for unit, spec in pairs(T.HEALTH) do
		local cut = cuts[unit]
		local texts = cut and units[unit].customTexts
		if texts then
			local value, percent = texts['m-Health'], texts['b-HealthPct']
			local drop = (width < 1 and T.IDENTITY_SPLIT[unit]) and T.SPEC_LINE or 0
			if value then value.xOffset, value.yOffset = spec.value[2] + ((spec.value[1] == 'RIGHT') and cut or -cut), spec.value[3] - drop end
			if percent then percent.xOffset, percent.yOffset = spec.percent[2], spec.percent[3] - drop end
		end
	end
	T.ApplyIdentityLines(p, width < 1, font)
	return width, cuts
end

-- 1.0.0 tooltip theme (BushidoPrivateCompat Tooltip.lua draws the glass): ElvUI's
-- tooltip fonts in the readable small-text font, crisp (shadow, no outline);
-- the ELVUI theme puts Bushido's tooltip fonts back
T.TOOLTIP_FONTS = { outline = 'SHADOW', header = 12, text = 11, small = 10 }
T.TOOLTIP_KEYS = { 'font', 'fontOutline', 'headerFont', 'headerFontOutline', 'headerFontSize', 'textFontSize', 'smallTextFontSize' }
function T.ApplyTooltipFonts(p, historical, fonts, theme)
	local tt = Ensure(p, 'tooltip')
	if theme == 'ELVUI' then
		local old = (historical and historical.tooltip) or {}
		for _, key in ipairs(T.TOOLTIP_KEYS) do tt[key] = old[key] end
		return tt
	end
	local F = T.TOOLTIP_FONTS
	local small = (fonts and fonts.small) or T.SMALL_FONT
	tt.font, tt.headerFont = small, small
	tt.fontOutline, tt.headerFontOutline = F.outline, F.outline
	tt.headerFontSize, tt.textFontSize, tt.smallTextFontSize = F.header, F.text, F.small
	return tt
end

-- 1.0.0: one AFK screen at a time. While Banzai's own (BushidoPrivateCompat
-- AFK.lua) is on, ElvUI's is off; without it ElvUI's is back as Bushido had it.
function T.ApplyAFK(p, historical, banzai)
	local general = Ensure(p, 'general')
	if banzai then
		general.afk = false
	else
		general.afk = historical and historical.general and historical.general.afk
	end
	return general.afk
end

function T.ApplyNameplates(p)
	local N = T.NAMEPLATES
	local np = Ensure(p, 'nameplates')
	np.statusbar = N.statusbar
	for _, unit in ipairs(T.NAMEPLATE_UNITS) do
		local u = Ensure(np, 'units', unit)
		local health = Ensure(u, 'health')
		health.height = N.height
		Ensure(health, 'text').fontSize = N.healthTextSize
		Ensure(u, 'name').fontSize = N.nameSize
		local cast = Ensure(u, 'castbar')
		cast.height, cast.yOffset, cast.iconSize, cast.width = N.castHeight, N.castYOffset, N.castIcon, N.castWidth
	end
	-- 0.6.0: enemy names centred directly above the health bar (the targeted
	-- enemy's health and percent go inside its bar: BushidoPrivateCompat TargetPlate.lua)
	for _, unit in ipairs(T.ENEMY_NAMEPLATES) do
		local name = Ensure(np, 'units', unit, 'name')
		name.parent, name.position, name.xOffset, name.yOffset = 'Health', 'TOP', 0, N.nameYOffset
	end
	Ensure(np, 'units', 'TARGET').glowStyle = N.targetGlow
	Ensure(np, 'colors').glowColor = T.DeepCopy(N.glowColor)
	local eltruism = Ensure(p, 'ElvUI_EltreumUI', 'nameplates', 'nameplateOptions')
	eltruism.incombatHeight, eltruism.outofcombatHeight = N.inCombat, N.outOfCombat
	Ensure(p, 'ElvUI_EltreumUI', 'nameplates', 'backdrop').backdroptexture = N.statusbar
end

function T.SetHealthInside(p, inside, percent, historical)
	local units = Ensure(p, 'unitframe', 'units')
	for _, unit in ipairs(T.HEALTH_INSIDE_UNITS) do
		local texts = Ensure(units, unit, 'customTexts')
		if texts['m-Health'] then texts['m-Health'].enable = not inside end
		if texts['b-HealthPct'] then texts['b-HealthPct'].enable = not inside and percent ~= false end
	end
	-- raid: the percentage alone (inside on), else Bushido's raid text as it was
	local old = historical and historical.unitframe and historical.unitframe.units or {}
	for _, unit in ipairs(T.RAID_UNITS) do
		local text = Ensure(units, unit, 'customTexts', 'm-Health')
		local was = old[unit] and old[unit].customTexts and old[unit].customTexts['m-Health'] or {}
		if inside then
			local R = T.RAID_PERCENT
			text.attachTextTo, text.text_format, text.justifyH = 'Health', R.format, R.justifyH
			text.xOffset, text.yOffset, text.size, text.enable = R.xOffset, R.yOffset, R.size, true
		else
			for _, k in ipairs({ 'attachTextTo', 'text_format', 'justifyH', 'xOffset', 'yOffset', 'size', 'enable' }) do text[k] = was[k] end
		end
	end
end

-- 0.7.0: secondary frames get Banzai's small identity circle (BushidoPrivateCompat
-- Identity.lua: Fabled spec icon, class fallback) in place of mMediaTag's large
-- portraits; Player, Target, Target-of-Target and Pet keep theirs.
T.IDENTITY_UNITS = { 'focus', 'party', 'arena', 'boss' }

function T.SetIdentityCircles(p, on, historical)
	local portraits = type(p.mMediaTag) == 'table' and p.mMediaTag.portraits
	if type(portraits) ~= 'table' then return end
	local old = historical and historical.mMT and historical.mMT.portraits or {}
	for _, unit in ipairs(T.IDENTITY_UNITS) do
		if type(portraits[unit]) == 'table' then
			portraits[unit].enable = (not on) and (not old[unit] or old[unit].enable ~= false) or false
		end
	end
end

-- 1.2.0 BUFFS panel (Banzai Art draws the bamboo panel around ElvUI's own buff
-- icons): the icons' top-left corner at (x, y) units from the screen's top-left,
-- Bushido's 10 per row and row gap, 2 or 3 rows; the debuffs below the panel's
-- bottom stalk, its bamboo ends and a gap (`frame` = outer margin + the thickest
-- stalk, `padBottom` = Banzai Art's Compat.BUFFS.padBottom), and one more row:
-- ElvUI shows weapon enchants as up to two icons before the buffs, outside its
-- rows x 10, so the debuffs keep a row free for them (1.2.1: the panel itself is
-- sized from the configured rows only; nothing reads the icons). Off: the 1.0
-- places and Bushido's rows exactly.
T.BUFFS_PANEL = { x = 30, y = 30, rows = 2, perRow = 10, padBottom = 18, frame = 10.5, ends = 10, gap = 8, min = 26, maxX = 900, maxY = 600 }
function T.BuffsPanel(panel)
	panel = type(panel) == 'table' and panel or {}
	local B = T.BUFFS_PANEL
	local function clamp(v, hi, default) v = tonumber(v) or default return Round(math.max(B.min, math.min(hi, v))) end
	return { on = panel.on ~= false, rows = (tonumber(panel.rows) == 3) and 3 or 2, x = clamp(panel.x, B.maxX, B.x), y = clamp(panel.y, B.maxY, B.y) }
end

function T.ApplyAuras(p, scale, historical, panel)
	scale = scale or T.AURAS.scale
	local movers = Ensure(p, 'movers')
	movers.BuffsMover, movers.DebuffsMover = T.AURAS.buffs, T.AURAS.debuffs
	local old = historical and historical.auras or {}
	local buffs = Ensure(p, 'auras', 'buffs')
	buffs.size = Round((old.buffs and old.buffs.size or 35) * scale)
	buffs.height = Round((old.buffs and old.buffs.height or 30) * scale)
	buffs.horizontalSpacing = Round(8 * math.max(0.75, scale))
	buffs.countYOffset = Round((old.buffs and old.buffs.countYOffset or 18) * scale) -- stack count stays on the icon
	for _, kind in ipairs({ 'buffs', 'debuffs' }) do
		Ensure(p, 'auras', kind).growthDirection = (old[kind] and old[kind].growthDirection) or 'RIGHT_DOWN'
	end
	local oldBuffs = old.buffs or {}
	buffs.wrapAfter, buffs.verticalSpacing = oldBuffs.wrapAfter or T.BUFFS_PANEL.perRow, oldBuffs.verticalSpacing or 10
	buffs.maxWraps = oldBuffs.maxWraps or 2
	panel = T.BuffsPanel(panel)
	if panel.on then
		local B = T.BUFFS_PANEL
		buffs.wrapAfter, buffs.maxWraps = B.perRow, panel.rows
		local keep = buffs.keepSizeRatio
		if keep == nil then keep = true end -- the saved profile leaves out ElvUI's default (true)
		local height = keep and buffs.size or buffs.height
		local block = (panel.rows + 1) * height + panel.rows * buffs.verticalSpacing -- + the weapon-enchant row

		local debuffY = math.ceil(panel.y + block + B.padBottom + B.frame + B.ends + B.gap)
		movers.BuffsMover = string.format('TOPLEFT,UIParent,TOPLEFT,%d,%d', panel.x, -panel.y)
		movers.DebuffsMover = string.format('TOPLEFT,UIParent,TOPLEFT,%d,%d', panel.x, -debuffY)
	end
end

-- 1.0.0: `width` (T.FRAME_WIDTH) narrows the frame at the size `scale` gives it,
-- its height stays; it keeps its inner end under the Target's inner end and
-- sits T.TOT_DROP lower while the Target's identity takes two lines
-- layout: the Player / Target height / spread and whether health sits inside the bars (LayerOptions)
function T.ApplyToT(p, scale, historical, width, layout)
	scale = scale or T.TOT.scale
	width = T.FrameWidth(width)
	layout = layout or {}
	local old = historical and historical.unitframe and historical.unitframe.units and historical.unitframe.units.targettarget or {}
	local tot = Ensure(p, 'unitframe', 'units', 'targettarget')
	local full = Round((old.width or 210) * scale)
	tot.width = Round((old.width or 210) * scale * width)
	tot.height = Round((old.height or 35) * scale)
	local power = Ensure(tot, 'power')
	power.detachedWidth = Round(((old.power and old.power.detachedWidth) or 205) * scale * width)
	power.height = 4
	local texts = Ensure(tot, 'customTexts')
	if texts['m-Name'] then texts['m-Name'].yOffset, texts['m-Name'].size = -18, 9 end
	if texts['m-Health'] then texts['m-Health'].yOffset, texts['m-Health'].size = -30, 11 end
	local movers = Ensure(p, 'movers')
	local cut, drop = full - tot.width, 0
	if width < 1 then drop = T.TOT_DROP + ((layout.healthInside == false) and T.TOT_OUTSIDE_DROP or 0) end
	local dx, dy = -(cut + (tonumber(layout.unitSpread) or 0)), (tonumber(layout.unitHeight) or 0) - drop
	movers.ElvUF_TargetTargetMover = T.ShiftMover(T.TOT.mover, dx, dy)
	movers.TargetTargetPowerBarMover = T.ShiftMover(T.TOT.power, dx, dy)
	local portrait = type(p.mMediaTag) == 'table' and type(p.mMediaTag.portraits) == 'table' and p.mMediaTag.portraits.targettarget
	if type(portrait) == 'table' then
		local fresh = T.BuildMediaTag(historical and historical.mMT).portraits.targettarget
		portrait.size = Round((fresh.size or 58) * scale)
		portrait.point = T.DeepCopy(fresh.point)
		portrait.point.x, portrait.point.y = fresh.point.x * scale, fresh.point.y * scale
	end
end

function T.ApplyBanzai040(p, fonts)
	fonts = fonts or { display = T.FONT, small = T.SMALL_FONT }
	T.ApplyNameplates(p)
	local movers = Ensure(p, 'movers')
	for name, value in pairs(T.MINIMAP_040) do movers[name] = value end
	local portraits = type(p.mMediaTag) == 'table' and p.mMediaTag.portraits
	if type(portraits) == 'table' then
		local misc = Ensure(portraits, 'misc')
		misc.class_icon, misc.spec_icon = T.CLASS_ICON, 'none'
	end
	local chat = Ensure(p, 'chat')
	chat.font, chat.tabFont = fonts.small, fonts.small -- readable chat, same family as the rest of the small text
end

---------------------------------------------------------------------------
-- 0.5.0 part of the layer
---------------------------------------------------------------------------
-- Smooth health: Bushido's health textures are slotted (diagonal cuts); the
-- Banzai texture (BushidoPrivateCompat media, LibSharedMedia "Banzai") is one
-- continuous surface. Eltruism's per-unit texture settings, ElvUI's unit-frame
-- and nameplate textures. Off: Bushido's textures again.
T.SMOOTH_TEXTURE = 'Banzai'
T.SMOOTH_TEXTURE_FILE = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\BanzaiBar'
T.UF_TEXTURE_KEYS = { 'playertexture', 'targettexture', 'targettargettexture', 'targettargettargettexture', 'focustexture',
	'pettexture', 'partytexture', 'raidtexture', 'arenatexture', 'bosstexture', 'backdroptexture' }
-- Bushido's "target cooldown" display: ElvUI action bars 2 and 4 between the
-- unit frames (8 + 6 buttons, no keybind text), shown by ElvUI's global fade
-- when there is a target. Off in Banzai (Darren uses his own cooldown tool);
-- the spells stay in their action slots, LAYOUT can show the bars again.
T.COOLDOWN_BARS = { 'bar2', 'bar4' }
-- The bottom bars sit on the bottom panel with clear breathing room: 0.6.0:
-- the lowest row starts ACTION_GAP above the panel's top edge, whatever its
-- height (the rows above keep Bushido's spacing). ACTION_BASE is the
-- historical bottom row (ElvAB_6) every bar is measured from.
T.BAR_HEIGHT = 32
T.ACTION_GAP = 10
T.ACTION_BASE = 'ElvAB_6'
T.ACTION_MOVERS = { 'ElvAB_1', 'ElvAB_3', 'ElvAB_5', 'ElvAB_6' }
-- Chat inside the lower-left Banzai frame (same outer size as the Details
-- frame, content inset 10.5): panel 430 x 140, bottom = bar + 10. 0.6.0: the
-- frame is a parallelogram, the panel sits in its middle at x 47.
-- 1.2.0: the whole composition flush with the left screen edge, the panel at x 31
-- (Banzai Art Compat.CHAT: the frame at -0.655, its left stalk on the edge).
T.CHAT = { x = 31, inset = 10, width = 430, height = 140 }

function T.ShiftMover(value, dx, dy)
	local point, anchor, relative, x, y = string.match(value or '', '^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$')
	if not point then return value end
	return table.concat({ point, anchor, relative, tostring(tonumber(x) + dx), tostring(tonumber(y) + dy) }, ',')
end

function T.SetSmoothBars(p, on, historical)
	historical = historical or {}
	local old = historical.ElvUI_EltreumUI and historical.ElvUI_EltreumUI.unitframes and historical.ElvUI_EltreumUI.unitframes.ufcustomtexture or {}
	local textures = Ensure(p, 'ElvUI_EltreumUI', 'unitframes', 'ufcustomtexture')
	for _, key in ipairs(T.UF_TEXTURE_KEYS) do
		if on then textures[key] = T.SMOOTH_TEXTURE elseif old[key] then textures[key] = old[key] end
	end
	local oldUF = historical.unitframe and historical.unitframe.statusbar
	local oldNP = historical.nameplates and historical.nameplates.statusbar
	Ensure(p, 'unitframe').statusbar = on and T.SMOOTH_TEXTURE or oldUF or T.SMOOTH_TEXTURE
	Ensure(p, 'nameplates').statusbar = on and T.SMOOTH_TEXTURE or oldNP or T.SMOOTH_TEXTURE
end

-- Details meter rows (profile instances): the same smooth texture, class colours kept
function T.SmoothDetailsRows(profile, on)
	if not on then return 0 end
	local n = 0
	for _, window in pairs(type(profile.instances) == 'table' and profile.instances or {}) do
		local row = type(window) == 'table' and window.row_info
		if type(row) == 'table' then
			row.texture, row.texture_file = T.SMOOTH_TEXTURE, T.SMOOTH_TEXTURE_FILE
			row.texture_background = T.SMOOTH_TEXTURE
			n = n + 1
		end
	end
	return n
end

function T.SetCooldownBars(p, show)
	for _, bar in ipairs(T.COOLDOWN_BARS) do
		Ensure(p, 'actionbar', bar).enabled = show and true or false
	end
end

function T.ChatMover(barHeight)
	return string.format('BOTTOMLEFT,UIParent,BOTTOMLEFT,%d,%d', T.CHAT.x, (barHeight or T.BAR_HEIGHT) + T.CHAT.inset)
end

-- 1.2.0 action-button style: SQUARE (Banzai square, default) | CIRCLE (Banzai
-- circles) | ELVUI; true / false (older callers) mean CIRCLE / ELVUI, BANZAI
-- (1.1.x) the new default
function T.ButtonStyle(style)
	if style == true then return 'CIRCLE' end
	if style == false or style == 'ELVUI' then return 'ELVUI' end
	if style == 'CIRCLE' then return 'CIRCLE' end
	return 'SQUARE'
end

-- Perfect circular action buttons (BushidoPrivateCompat ActionButtons.lua) on
-- the main cluster, ElvUI bars 1 and 6: square buttons (one size both ways,
-- so the circle is never squashed), keybind in the exact centre, count /
-- charges bottom-centre 20 % smaller, cooldown numbers at the top so they
-- never cover the keybind, ElvUI's (square) proc glow off - Banzai draws a
-- round one - and Eltruism's proc glow off. Bar 1 moves up 3 more so the two
-- rows of circles keep a 6-unit gap. ELVUI style: Bushido's values.
-- 0.6.0: keybind 35 % smaller than 0.5.1's double size (2 x 0.65 = 1.3 x Bushido's).
T.CIRCLE = { bars = { 'bar1', 'bar6' }, size = 30, spacing = 6, hotkeyScale = 1.3, countScale = 0.8, extraShift = { ElvAB_1 = 3 } }
T.CIRCLE_KEYS = { 'keepSizeRatio', 'buttonSize', 'buttonHeight', 'buttonSpacing', 'hotkeytext', 'hotkeyFont', 'hotkeyFontSize', 'hotkeyFontOutline',
	'hotkeyTextPosition', 'hotkeyTextXOffset', 'hotkeyTextYOffset', 'countFontSize', 'countFontOutline', 'countTextPosition', 'countTextXOffset', 'countTextYOffset' }
-- 1.0.0 BANZAI > ACTION BARS: size, spacing and keybind / count size of the
-- circles within a range that keeps the panel composition (the two rows of
-- 12 stay clear of the cooldown bars beside them, CooldownBars.lua)
T.CIRCLE_LOOK = { size = { 26, 32 }, spacing = { 4, 7 }, keybind = { 1, 1.6 }, count = { 0.6, 1.2 } }
-- 1.2.0 BANZAI SQUARE: the same buttons (size, spacing, the cluster's place),
-- the keybind small at the top-right inside the border (Bushido's size, the
-- small font, not the circles' large centred keybind), the count bottom-centre
-- (the reduced count size), the cooldown numbers in the middle (11, half a unit low:
-- about a pixel clear of the keybind above and the count below on a 39 px button),
-- each clear of the border and its chamfer (2 px = 1.5 units inside the edge)
T.SQUARE = { hotkeyScale = 1, hotkey = { 'TOPRIGHT', -3, -3 }, count = { 'BOTTOM', 0, 2 }, cooldown = { 'CENTER', 0, -0.5, 11 } }
function T.CircleLook(look)
	look = look or {}
	local function pick(key, default)
		local range = T.CIRCLE_LOOK[key]
		return math.max(range[1], math.min(range[2], tonumber(look[key]) or default))
	end
	return { size = pick('size', T.CIRCLE.size), spacing = pick('spacing', T.CIRCLE.spacing), keybind = pick('keybind', T.CIRCLE.hotkeyScale), count = pick('count', T.CIRCLE.countScale) }
end

-- style: SQUARE | CIRCLE | ELVUI (T.ButtonStyle; true / false still mean circles / ElvUI)
function T.SetCircleButtons(p, style, historical, smallFont, look)
	historical = historical or {}
	style = T.ButtonStyle(style)
	local on, square = style ~= 'ELVUI', style == 'SQUARE'
	local L = T.CircleLook(look)
	local oldBars = historical.actionbar or {}
	for _, bar in ipairs(T.CIRCLE.bars) do
		local db = Ensure(p, 'actionbar', bar)
		local old = oldBars[bar] or {}
		if on then
			db.keepSizeRatio, db.buttonSize, db.buttonHeight, db.buttonSpacing = true, L.size, L.size, L.spacing
			db.hotkeytext = true
			db.hotkeyFont, db.hotkeyFontOutline = smallFont or T.SMALL_FONT, 'SHADOWOUTLINE'
			db.countFontSize = math.floor((old.countFontSize or 10) * L.count + 0.5)
			db.countFontOutline = 'SHADOWOUTLINE'
			if square then
				local S = T.SQUARE
				db.hotkeyFontSize = math.floor((old.hotkeyFontSize or 10) * S.hotkeyScale + 0.5)
				db.hotkeyTextPosition, db.hotkeyTextXOffset, db.hotkeyTextYOffset = S.hotkey[1], S.hotkey[2], S.hotkey[3]
				db.countTextPosition, db.countTextXOffset, db.countTextYOffset = S.count[1], S.count[2], S.count[3]
			else
				db.hotkeyFontSize = math.floor((old.hotkeyFontSize or 10) * L.keybind + 0.5)
				db.hotkeyTextPosition, db.hotkeyTextXOffset, db.hotkeyTextYOffset = 'CENTER', 0, 0
				db.countTextPosition, db.countTextXOffset, db.countTextYOffset = 'BOTTOM', 0, 1
			end
		else
			for _, key in ipairs(T.CIRCLE_KEYS) do db[key] = T.DeepCopy(old[key]) end
		end
	end
	-- proc glow: Banzai's round halo instead of ElvUI's / Eltruism's square one
	local hist = historical.actionbar and historical.actionbar.handleOverlay
	Ensure(p, 'actionbar').handleOverlay = (not on) and (hist ~= false) or false
	local glow = Ensure(p, 'ElvUI_EltreumUI', 'glow')
	local oldGlow = historical.ElvUI_EltreumUI and historical.ElvUI_EltreumUI.glow
	glow.procglow = (not on) and (oldGlow and oldGlow.procglow) or false
	-- 0.5.1: Eltruism's action-bar shadows drew a dark square around every button
	local shadow = Ensure(p, 'ElvUI_EltreumUI', 'skins', 'shadow')
	local oldSkins = historical.ElvUI_EltreumUI and historical.ElvUI_EltreumUI.skins
	local oldShadow = oldSkins and oldSkins.shadow
	shadow.actionbars = (not on) and (oldShadow and oldShadow.actionbars) or false
	-- action-bar cooldown numbers: at the top of the circle (keybind keeps the centre); 1.2.0 in the middle of the square
	local cd = Ensure(p, 'cooldown', 'actionbar')
	local oldCD = historical.cooldown and historical.cooldown.actionbar or {}
	if square then
		cd.position, cd.offsetX, cd.offsetY, cd.fontSize = T.SQUARE.cooldown[1], T.SQUARE.cooldown[2], T.SQUARE.cooldown[3], T.SQUARE.cooldown[4]
	elseif on then
		cd.position, cd.offsetX, cd.offsetY, cd.fontSize = 'TOP', 0, -1, 11
	else
		cd.position, cd.offsetX, cd.offsetY, cd.fontSize = oldCD.position, oldCD.offsetX, oldCD.offsetY, oldCD.fontSize
	end
end

local function MoverY(value)
	return tonumber((string.match(value or '', '^[^,]+,[^,]+,[^,]+,[^,]+,([^,]+)$')))
end

-- the bottom action bars: lowest row ACTION_GAP above the bottom panel
-- (1.0.0: the upper row of circles keeps its gap at any circle size)
function T.ApplyActionMovers(p, historical, barHeight, circles, look)
	local old = (historical and historical.movers) or {}
	local base = MoverY(old[T.ACTION_BASE])
	if not base then return end
	local dy = (barHeight or T.BAR_HEIGHT) + T.ACTION_GAP - base
	local movers = Ensure(p, 'movers')
	local L = T.CircleLook(look)
	local grow = (L.size + L.spacing) - (T.CIRCLE.size + T.CIRCLE.spacing)
	for _, name in ipairs(T.ACTION_MOVERS) do
		local extra = circles and T.CIRCLE.extraShift[name] and (T.CIRCLE.extraShift[name] + grow) or 0
		if type(old[name]) == 'string' then movers[name] = T.ShiftMover(old[name], 0, dy + extra) end
	end
end

function T.ApplyBanzai050(p)
	local chat = Ensure(p, 'chat')
	chat.panelWidth, chat.panelHeight = T.CHAT.width, T.CHAT.height
end

---------------------------------------------------------------------------
-- 0.6.0 part of the layer
---------------------------------------------------------------------------
-- Party / raid / arena / boss in the Banzai family (ElvUI's own settings):
-- party PvP-first with role icons and its debuffs shown (ElvUI's default
-- aura lists, dispellable highlight and range fading stay on).
T.PARTY_060 = { roleIcon = { enable = true, position = 'LEFT', attachTo = 'Health', xOffset = 3, yOffset = 0, size = 14 }, debuffs = true }

function T.ApplyUnitFrames060(p)
	local party = Ensure(p, 'unitframe', 'units', 'party')
	local role = Ensure(party, 'roleIcon')
	for k, v in pairs(T.PARTY_060.roleIcon) do role[k] = v end
	Ensure(party, 'debuffs').enable = T.PARTY_060.debuffs
end

-- Role-aware frame positions (ElvUI movers) and party arrangement. DPS keeps
-- Bushido's places: party / arena allies in a column on the left, raid on the
-- left side. HEALER (0.7.0) brings the friendly frames to the centre: party in
-- ONE HORIZONTAL ROW centred under the character and above everything of the
-- lower centre (UIParent units at UI scale 0.71 / 1440p: Player and Target end
-- at 353, their bamboo at 394, the combat tree at 422, the focus cast bar at
-- 451, cast history and action bars lower still), so the row starts at 455;
-- its five frames are 140 wide with room for their identity circles between
-- them. In an arena ElvUI shows the allies with the same party header: the
-- arena allies keep a position of their own (ArenaAlliesMover, the party
-- mover while in an arena), same row by default. A position Darren sets
-- himself is kept for that role and that kind of frame only (Roles.lua).
T.ROLE_MOVERS = { 'ElvUF_PartyMover', 'ElvUF_Raid1Mover', 'ElvUF_Raid2Mover', 'ElvUF_Raid3Mover', 'ArenaHeaderMover', 'BossHeaderMover' }
T.ARENA_ALLIES = 'ArenaAlliesMover'
-- party header arrangement; 0.9.0: its height and the size of its crowd-control
-- icon (the 0.8.0 debuff / buff placement keys are gone with those auras)
T.ROLE_UNIT_KEYS = { 'growthDirection', 'horizontalSpacing', 'verticalSpacing', 'width', 'height', 'auras.sizeOverride', 'auras.xOffset' }
-- 0.9.0: the arena enemy frames' size per role (mirrors the allies)
T.ROLE_ARENA_KEYS = { 'width', 'height' }
T.ROLE_UNITS = { { unit = 'party', keys = T.ROLE_UNIT_KEYS }, { unit = 'arena', keys = T.ROLE_ARENA_KEYS } }
T.ROLES = { 'DPS', 'HEALER' }
-- 0.9.0 (one frame system, the same construction for both roles):
--   CLASS / SPEC CIRCLE (27) | HEALTH BAR 100 (role icon inside its right end) | TRINKET CIRCLE (27)
-- DPS: party and arena allies 50 % narrower (200 -> 100) at Bushido's height,
-- on the left edge: the identity circles' left edge on the raid frames' left
-- edge (raid 23 + circle 27 + gap 4 = 54), Bushido's height (362). Arena
-- enemies mirrored on the right edge at the same level. HEALER: the central
-- row, 100 wide (the DPS width) and 30 % lower (39 -> 27), circle and trinket
-- on both sides of every frame (70 apart, centred); arena enemies mirrored on
-- the right edge at the row's level. The crowd-control icon fits the height.
-- 1.0.0: the HEALER row lower, just above the Player / Target region: its
-- dispel icons (16 under the frames) clear the top of the Focus frame (432,
-- left-aligned with the Player under the row's first frame) by 6, the frames
-- themselves clear the bamboo (394) and the combat tree (422); HEALER raid
-- frames on the same baseline (they reached down over the Focus frame).
T.HEALER_ROW = 454
T.ROLE_LAYOUTS = {
	DPS = {
		ElvUF_PartyMover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,54,362',
		ArenaAlliesMover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,54,362',
		ArenaHeaderMover = 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-54,362',
		party = { width = 100, ['auras.sizeOverride'] = 30, ['auras.xOffset'] = -33 },
		arena = { width = 100, height = 39 },
	},
	HEALER = {
		ElvUF_PartyMover = 'BOTTOM,UIParent,BOTTOM,0,454',
		ArenaAlliesMover = 'BOTTOM,UIParent,BOTTOM,0,454',
		ArenaHeaderMover = 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-54,454',
		ElvUF_Raid1Mover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,560,454',
		ElvUF_Raid2Mover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,560,454',
		party = { growthDirection = 'RIGHT_DOWN', horizontalSpacing = 70, width = 100, height = 27, ['auras.sizeOverride'] = 22, ['auras.xOffset'] = -25 },
		arena = { width = 100, height = 27 },
	},
}

-- the layout a spec role uses (tanks share the DPS arrangement)
function T.LayoutRole(specRole)
	return (specRole == 'HEALER') and 'HEALER' or 'DPS'
end

-- everything of a role: mover strings, the arena allies position, the party
-- arrangement ('party.<key>') and the arena enemy size ('arena.<key>');
-- what was saved for that role, then the role's defaults, then Bushido's
function T.RoleLayout(role, historical, overrides)
	local out = {}
	local old = (historical and historical.movers) or {}
	local units = historical and historical.unitframe and historical.unitframe.units or {}
	local defaults = T.ROLE_LAYOUTS[role] or {}
	local own = (type(overrides) == 'table' and type(overrides[role]) == 'table') and overrides[role] or {}
	for _, name in ipairs(T.ROLE_MOVERS) do
		out[name] = own[name] or defaults[name] or old[name]
	end
	-- arena allies: their own position, else where this role's party was put
	-- (0.9.0: one placement system), else the role's, else Bushido's party place
	out[T.ARENA_ALLIES] = own[T.ARENA_ALLIES] or own.ElvUF_PartyMover or defaults[T.ARENA_ALLIES] or old.ElvUF_PartyMover
	for _, group in ipairs(T.ROLE_UNITS) do
		local oldUnit = units[group.unit] or {}
		local roleUnit = defaults[group.unit]
		for _, key in ipairs(group.keys) do
			local path = group.unit .. '.' .. key
			local value = own[path]
			if value == nil and roleUnit then value = roleUnit[key] end
			if value == nil then value = T.GetPath(oldUnit, key) end
			out[path] = value
		end
	end
	return out
end

-- what a layout writes into the profile where the frames are now: in an arena
-- the party mover takes the arena allies position
function T.RoleWritten(layout, context)
	local out = {}
	for _, name in ipairs(T.ROLE_MOVERS) do out[name] = layout[name] end
	if context == 'arena' then out.ElvUF_PartyMover = layout[T.ARENA_ALLIES] or layout.ElvUF_PartyMover end
	for _, group in ipairs(T.ROLE_UNITS) do
		for _, key in ipairs(group.keys) do out[group.unit .. '.' .. key] = layout[group.unit .. '.' .. key] end
	end
	return out
end

function T.ApplyRoleLayout(p, role, historical, overrides, context)
	local layout = T.RoleLayout(role, historical, overrides)
	local written = T.RoleWritten(layout, context)
	local movers = Ensure(p, 'movers')
	for _, name in ipairs(T.ROLE_MOVERS) do movers[name] = written[name] end
	for _, group in ipairs(T.ROLE_UNITS) do
		local unit = Ensure(p, 'unitframe', 'units', group.unit)
		for _, key in ipairs(group.keys) do T.SetPath(unit, key, written[group.unit .. '.' .. key]) end
	end
	-- the arena cast bar is as wide as the arena frame
	local arena = Ensure(p, 'unitframe', 'units', 'arena')
	if type(arena.width) == 'number' then Ensure(arena, 'castbar').width = arena.width end
	return layout, written
end

---------------------------------------------------------------------------
-- 0.8.0 part of the layer: PvP-first unit frames
---------------------------------------------------------------------------
-- Everything goes through ElvUI's own elements. Under Midnight their aura
-- lists use the game's own categories (CROWD_CONTROL, BIG_DEFENSIVE,
-- EXTERNAL_DEFENSIVE, IMPORTANT, RAID_PLAYER_DISPELLABLE): Banzai itself reads
-- no aura, spell, cooldown or health data and shows nothing the game hides.
--   arena enemies  one system: ElvUI's arena frames in the Banzai design (cast
--                  bar, trinket, crowd control and defensive icons). 1.0.1:
--                  the only one - no sArena integration; DR is not a Banzai
--                  feature
--   casts          interruptible: attention amber (Bushido's colour), not
--                  interruptible: restrained steel violet (Bushido's red)
--   friendly       crowd control (the game's CROWD_CONTROL category) as one
--                  large icon over the right end of the bar (ElvUI's third
--                  aura element), hard to miss; dispellable effects as ElvUI's
--                  border glow, not a filled bar; ElvUI's range fading stays on.
--                  0.9.0: no ordinary buffs or debuff rows: the one debuff
--                  shown is a harmful effect this character can dispel (the
--                  game's RAID_PLAYER_DISPELLABLE), compact below the frame's
--                  right end; mMediaTag's role icon inside the bar's right end
--                  (BushidoPrivateCompat PvPFrames.lua adds the CC / DISPEL
--                  borders and labels and the trinket circle)
--   arena enemies  0.9.0 (when Banzai owns them): mirrored - trinket circle
--                  (Banzai Art) left, identity circle right; their crowd
--                  control over the identity circle, their defensive /
--                  important buffs left of the trinket; ElvUI's own trinket
--                  element off (Banzai's circle uses the same game data)
--   raid           compact: small role icon, one raid-relevant debuff before
--                  the percent (ElvUI's raid debuff lists; its raid-debuff
--                  element does not run on Retail), Dead / Ghost / Offline
--                  (oUF's [status]) in the middle; party the same status
--   focus / boss   cast bars on (focus: Bushido's, over its power bar; boss and
--                  ElvUI arena: their own bar above each frame - Bushido laid
--                  them over a power bar those frames do not show); focus
--                  debuffs right, boss debuffs left of the identity circle
--                  (the boss frames sit at the right screen edge)
--   ToT / pet      subordinate: no portrait; ToT shows its health percent
T.PVP = {
	castColor = { r = 1.00, g = 0.70, b = 0.00 },
	castNoInterrupt = { r = 0.46, g = 0.44, b = 0.56 },
	raidRole = { enable = true, attachTo = 'Health', position = 'LEFT', xOffset = 2, yOffset = 0, size = 10 },
	raidDebuffs = { enable = true, attachTo = 'HEALTH', anchorPoint = 'RIGHT', xOffset = -44, yOffset = 0, sizeOverride = 14, perrow = 1, numrows = 1, keepSizeRatio = true },
	status = { format = '|cffb8bcc4[status]|r', spec = { 'CENTER', 0, 0, 9 } },
	statusUnits = { 'party', 'raid1', 'raid2', 'raid3' },
	focusDebuffs = { enable = true, anchorPoint = 'RIGHT', growthX = 'RIGHT', xOffset = 4, yOffset = 0, sizeOverride = 24, perrow = 3, numrows = 1, keepSizeRatio = true },
	bossDebuffs = { enable = true, anchorPoint = 'LEFT', growthX = 'LEFT', xOffset = -35, yOffset = 0, sizeOverride = 22, perrow = 3, numrows = 1, keepSizeRatio = true },
	-- boss / ElvUI arena cast bar: its own bar above each frame, the frames spaced for it
	castAbove = { enable = true, overlayOnFrame = 'None', insideInfoPanel = false, width = 200, height = 12, icon = true, iconAttached = true,
		hidetext = false, xOffsetText = 0, yOffsetText = 0, xOffsetTime = 0, yOffsetTime = 0, positionsGroup = { anchorPoint = 'TOP', xOffset = 0, yOffset = 2 } },
	castSpacing = 16,
	-- party crowd control: ElvUI's 'auras' element, inside the bar's right end (size / offset per role: T.ROLE_LAYOUTS)
	partyCC = { enable = true, filter = 'HARMFUL', attachTo = 'HEALTH', anchorPoint = 'RIGHT', growthX = 'LEFT', yOffset = 0,
		perrow = 1, numrows = 1, keepSizeRatio = true, desaturate = false },
	partyCCList = { 'HARMFUL||CROWD_CONTROL' },
	-- 0.9.0 party: the dispellable debuff only, one compact icon below the frame's right end
	partyDispel = { enable = true, attachTo = 'FRAME', anchorPoint = 'BOTTOMRIGHT', growthX = 'LEFT', growthY = 'DOWN', xOffset = 0, yOffset = -2,
		sizeOverride = 14, perrow = 1, numrows = 1, keepSizeRatio = true, desaturate = false },
	partyDispelList = { 'HARMFUL||RAID_PLAYER_DISPELLABLE' },
	-- 0.9.0 the role icon: mMediaTag's tag inside the bar's right end
	roleText = { format = '[mMT-role:icon]', spec = { 'RIGHT', -2, 0, 10 } },
	-- 0.9.0 ElvUI arena frames (when Banzai owns them), mirrored: [offensive / defensive][trinket][frame][circle / CC]
	arenaDebuffs = { enable = true, attachTo = 'HEALTH', anchorPoint = 'RIGHT', growthX = 'RIGHT', xOffset = 5, yOffset = 0, sizeOverride = 25, perrow = 1, numrows = 1, keepSizeRatio = true, desaturate = false },
	arenaDebuffList = { 'HARMFUL||CROWD_CONTROL' },
	arenaBuffs = { attachTo = 'HEALTH', anchorPoint = 'LEFT', growthX = 'LEFT', xOffset = -35, yOffset = 0, sizeOverride = 20, perrow = 2, numrows = 1, keepSizeRatio = true },
	arenaBuffList = { 'HELPFUL||BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE', 'HELPFUL||EXTERNAL_DEFENSIVE', 'HELPFUL||IMPORTANT||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE' },
	filterGroups = 8, -- ElvUI's E.filterMax (Midnight filter groups)
	totText = '|cffdde3e8[perhp<%]|r',
	minorPortraits = { 'targettarget', 'pet' },
}

local function Fill(target, values)
	for k, v in pairs(values) do target[k] = T.DeepCopy(v) end
end

-- an aura element's Midnight filter groups: exactly these (group1, group2, ...), the rest off.
-- A group Banzai writes is the game's category alone: ElvUI's own defaults for
-- that group (e.g. arena debuffs group1: nameplateShowPersonal required, an
-- allow list) are switched off explicitly - nil would fall back to them.
T.AURA_CANDIDATES = { 'canApplyAura', 'isBossAura', 'isBossOrRoleAura', 'isFromPlayerOrPlayerPet', 'isPriorityAura', 'isRoleAura', 'isStealable', 'nameplateShowAll', 'nameplateShowPersonal' }
function T.SetFilterGroups(element, filters)
	local lists = Ensure(element, 'filterLists')
	for i = 1, T.PVP.filterGroups do
		local group = Ensure(lists, 'group' .. i)
		if filters[i] then
			group.enable, group.filter = true, filters[i]
			group.useAllowlist, group.maxDuration = false, 0
			local candidates = Ensure(group, 'candidates')
			for _, key in ipairs(T.AURA_CANDIDATES) do candidates[key] = false end
		else
			group.enable = false
		end
	end
	return lists
end

function T.ApplyPvP(p, opts, historical)
	opts = opts or {}
	local P = T.PVP
	local uf = Ensure(p, 'unitframe')
	local old = (historical and historical.unitframe) or {}
	local colors = Ensure(uf, 'colors')
	local oldColors = old.colors or {}
	if opts.pvpCastColors ~= false then
		colors.castColor, colors.castNoInterrupt = T.DeepCopy(P.castColor), T.DeepCopy(P.castNoInterrupt)
	else
		colors.castColor, colors.castNoInterrupt = T.DeepCopy(oldColors.castColor), T.DeepCopy(oldColors.castNoInterrupt)
	end
	uf.debuffHighlighting = (opts.pvpDispelGlow ~= false) and 'GLOW' or old.debuffHighlighting
	local units = Ensure(uf, 'units')
	-- 0.9.0 party / arena allies: no ordinary buffs or debuff rows
	Ensure(units, 'party', 'buffs').enable = false
	local partyDispel = Ensure(units, 'party', 'debuffs')
	Fill(partyDispel, P.partyDispel)
	T.SetFilterGroups(partyDispel, P.partyDispelList)
	local partyCC = Ensure(units, 'party', 'auras')
	Fill(partyCC, P.partyCC)
	T.SetFilterGroups(partyCC, P.partyCCList)
	local partyTexts = Ensure(units, 'party', 'customTexts')
	local font = (partyTexts['m-Name'] and partyTexts['m-Name'].font) or T.SMALL_FONT
	CustomText(partyTexts, 'b-Role', P.roleText.spec, P.roleText.format, font)
	partyTexts['b-Role'].enable = opts.roleIcons ~= false
	for _, unit in ipairs(T.RAID_UNITS) do
		Fill(Ensure(units, unit, 'roleIcon'), P.raidRole)
		Fill(Ensure(units, unit, 'debuffs'), P.raidDebuffs)
	end
	for _, unit in ipairs(P.statusUnits) do
		local texts = Ensure(units, unit, 'customTexts')
		local font = (texts['m-Name'] and texts['m-Name'].font) or T.SMALL_FONT
		CustomText(texts, 'b-Status', P.status.spec, P.status.format, font)
	end
	Ensure(units, 'focus', 'castbar').enable = true
	Fill(Ensure(units, 'focus', 'debuffs'), P.focusDebuffs)
	local boss = Ensure(units, 'boss')
	Fill(Ensure(boss, 'castbar'), P.castAbove)
	boss.spacing = P.castSpacing
	Fill(Ensure(boss, 'debuffs'), P.bossDebuffs)
	-- arena enemies: one system on screen
	local arena = Ensure(units, 'arena')
	arena.enable = true -- 1.0.1: Banzai's arena enemy frames, always
	local arenaCast = Ensure(arena, 'castbar')
	Fill(arenaCast, P.castAbove)
	if type(arena.width) == 'number' then arenaCast.width = arena.width end
	arena.spacing = P.castSpacing
	Ensure(arena, 'pvpTrinket').enable = false -- Banzai Art's trinket circle (the same game data)
	local arenaCC = Ensure(arena, 'debuffs')
	Fill(arenaCC, P.arenaDebuffs)
	T.SetFilterGroups(arenaCC, P.arenaDebuffList)
	local buffs = Ensure(arena, 'buffs')
	Fill(buffs, P.arenaBuffs)
	T.SetFilterGroups(buffs, P.arenaBuffList)
	buffs.enable = opts.pvpDefensives ~= false
	-- Target of Target / pet: subordinate
	local tot = Ensure(units, 'targettarget', 'customTexts')
	if tot['m-Health'] then tot['m-Health'].text_format = P.totText end
	local portraits = type(p.mMediaTag) == 'table' and p.mMediaTag.portraits
	if type(portraits) == 'table' then
		for _, unit in ipairs(P.minorPortraits) do
			if type(portraits[unit]) == 'table' then portraits[unit].enable = false end
		end
	end
end

-- The part of the layer that follows this character's own BANZAI settings
-- (Character Sync: written for whichever character logs in, before ElvUI
-- builds its frames): fonts, health text, buffs, ToT, bar textures, action
-- buttons and their place on the panel, the chat panel and the role layout;
-- 1.0.0: the Player / Target / Focus / ToT width (with the Player / Target
-- height / spread), the tooltip fonts and which AFK screen is on.
function T.ApplyCharacterLayer(p, historical, fonts, opts)
	historical = historical or {}
	opts = opts or {}
	fonts = fonts or { display = T.FONT, small = T.SMALL_FONT }
	T.RevertFrameStyle(p, opts.splitState) -- 1.3.0: a split layer written before goes first; the classic steps then rewrite their keys
	T.ApplyBanzaiFonts(p, historical, fonts)
	T.SetHealthInside(p, opts.healthInside ~= false, opts.healthPercent, historical)
	T.SetIdentityCircles(p, opts.identityCircles ~= false, historical)
	T.ApplyPvP(p, opts, historical)
	T.ApplyAuras(p, opts.buffScale, historical, opts.buffsPanel)
	T.ApplyToT(p, opts.totScale, historical, opts.frameWidth, opts)
	T.ApplyFrameWidths(p, historical, opts, fonts.small)
	T.ApplyTooltipFonts(p, historical, fonts, opts.tooltipTheme)
	T.ApplyAFK(p, historical, opts.afk ~= false)
	T.SetSmoothBars(p, opts.smoothBars ~= false, historical)
	T.SetCooldownBars(p, opts.cooldownBars == true)
	local style = T.ButtonStyle(opts.actionStyle) -- 1.2.0: SQUARE | CIRCLE | ELVUI
	T.SetCircleButtons(p, style, historical, fonts.small, opts.actionLook)
	T.ApplyActionMovers(p, historical, opts.barHeight, style ~= 'ELVUI', opts.actionLook)
	Ensure(p, 'movers').LeftChatMover = T.ChatMover(opts.barHeight)
	T.ApplyRoleLayout(p, opts.role or 'DPS', historical, opts.roles, opts.roleContext)
	T.ApplyFrameStyle(p, historical, fonts, opts) -- 1.3.0: BANZAI SPLIT over the classic layer (nothing for BANZAI CLASSIC)
	return p
end

---------------------------------------------------------------------------
-- 1.3.0 BANZAI SPLIT: the optional second unit-frame family
---------------------------------------------------------------------------
-- Player (lower centre) and Target (upper centre) as HEALTH <- HUB -> RESOURCE:
-- the ElvUI frame is the health bar, its detached power bar sits on the other
-- side of the hub (Banzai Art draws the hub between them), the class bar and
-- the extra mana bar above the resource bar; ElvUI's player / target / focus
-- cast bars off (the hub shows the cast), ElvUI's portraits and mMediaTag's
-- large circles off on these frames, the name line one centred custom text
-- across the lower part of the hub. Focus: a smaller split frame up and left of
-- the Player, its crowd control above its health bar. Target-of-Target: one
-- compact bar right of the Target. Party / arena allies (their places, sizes
-- and arrangement stay the role layouts'): the identity circle in the middle
-- of the bar (Banzai Art), the name across its lower part, the role icon a
-- badge on the circle's upper left, Dead / Offline above the circle - the bar's
-- ends stay free for the health value (left) and percent (right).
--
-- Reversible and idempotent: every value is written over the classic layer and
-- its classic value recorded first (opts.splitState, kept by
-- BushidoPrivateRestore with the shared profile); the next layer takes the
-- record back before anything else, so the classic steps always start from
-- their own values and BANZAI CLASSIC comes back exactly.
T.FRAME_STYLES = { 'CLASSIC', 'SPLIT' }
function T.FrameStyle(style) return (style == 'SPLIT') and 'SPLIT' or 'CLASSIC' end
-- the same numbers as Banzai Art's Split.UNITS / TOT / PARTY
-- 1.3.1 (Darren's runtime correction): Player 24 / Target 21 high (32 / 28 whole pixels at his scale,
-- the bar thickness on top: thick), the values above the bars and the name / spec lines under them are
-- Banzai Art's own (the Player / Target b-SplitName entry is the layer's marker, not a text); the class
-- bar sits above the resource values, starting clear of the spell name over the hub (start); version:
-- the layout of the split leaves (a change rewrites a split character's layer at its next login)
-- 1.3.3: identity (the Player / Target hub 125 % of its 1.3.2 size) and the bamboo cast bar's interior / stalk / the
-- room of the values under it (Banzai Art's Split.UNITS castInterior / castStalk / castValues); castbar: its interior
-- from inner x the stalk inside its outline, gap above the values / the hub and under the class bar; version 3 (1.3.4: 4,
-- the lower cast bar)
T.SPLIT = {
	version = 4,
	player = { bar = 180, height = 24, hub = 50, name = 11, thick = true, identity = 1.25, castInterior = 22.5, castStalk = 4.5, castValues = 20 },
	target = { bar = 170, height = 21, hub = 46, name = 11, thick = true, identity = 1.25, castInterior = 19.5, castStalk = 3.75, castValues = 18 },
	focus = { bar = 110, height = 12, powerHeight = 7, hub = 30, name = 9, dx = -330, dy = 70 },
	tot = { bar = 90, height = 10, gap = 14, name = 9 },
	party = { circle = 32, name = 9 },
	tuck = 0.16,
	classbar = { inset = 8, height = 5, gap = 3, additional = 7, values = 18, start = 48 },
	castbar = { inner = 1.1, gap = 3 }, -- 1.3.3 (Banzai Art's Split.CAST_BAR)
	defaults = { splitPlayerX = 0, splitPlayerY = 290, splitTargetX = 0, splitTargetY = 112, splitScale = 1, splitHubScale = 1, splitThickness = 1 },
}
T.SPLIT_NAME = { player = '[name:eltruism:gradientshortcaps]', target = '[name:eltruism:gradientshortcaps{12}]', focus = '[name:eltruism:gradientshortcaps{10}]' }
T.SPLIT_UNITS = { 'player', 'target', 'focus' }

-- sizes at the chosen scales (Banzai Art's Split.Geometry rounds the same way)
function T.SplitGeometry(key, opts)
	opts = opts or {}
	local d = T.SPLIT[key]
	local s = tonumber(opts.splitScale) or 1
	local t = d.thick and (tonumber(opts.splitThickness) or 1) or 1 -- 1.3.1
	local hub = Round(d.hub * s * (tonumber(opts.splitHubScale) or 1)) * (d.identity or 1) -- 1.3.3: Player / Target 125 %
	local tuck = Round(hub * T.SPLIT.tuck)
	local g = { bar = Round(d.bar * s), height = Round(d.height * s * t), hub = hub, tuck = tuck, inner = Round(hub / 2 - tuck), powerHeight = Round((d.powerHeight or d.height) * s * t) }
	if d.castInterior then -- 1.3.3 the bamboo cast bar (Banzai Art's Split.Geometry)
		local C = T.SPLIT.castbar
		g.castInterior = d.castInterior * s * t
		g.castStalk = d.castStalk * s
		g.castHeight = g.castInterior + 2 * C.inner * g.castStalk
		g.castWidth = 2 * (g.inner + g.bar)
		g.castLift = math.max(Round(g.height / 2) + d.castValues, hub / 2) + C.gap
	end
	return g
end

local function Num(v) return (math.floor(v) == v) and string.format('%d', v) or string.format('%.1f', v) end
local function Mover(point, rel, x, y) return string.format('%s,ElvUIParent,%s,%s,%s', point, rel, Num(x), Num(y)) end

-- whether the identity lines show the spec (BANZAI > APPEARANCE "Specialization in names", as the classic layer left it)
local function SpecOn(texts)
	local name, spec = texts and texts['m-Name'], texts and texts['b-Spec']
	return (spec and spec.enable == true) or (name and string.find(name.text_format or '', 'banzai:spec', 1, true) ~= nil) or false
end

-- every value the split style writes, as leaves (T.Snapshot / T.ApplyLeaves)
function T.SplitLeaves(p, historical, fonts, opts)
	opts = opts or {}
	local D = T.SPLIT.defaults
	local function opt(k) return tonumber(opts[k]) or D[k] end
	local small = (fonts and fonts.small) or T.SMALL_FONT
	local units = (p.unitframe and p.unitframe.units) or {}
	local out = {}
	local function leaf(value, ...) out[#out + 1] = { path = { ... }, value = value } end
	local function unit(u, value, ...) leaf(value, 'unitframe', 'units', u, ...) end
	local function text(u, name, fields)
		for _, k in ipairs({ 'attachTextTo', 'justifyH', 'xOffset', 'yOffset', 'size', 'font', 'fontOutline', 'text_format', 'enable' }) do
			if fields[k] ~= nil then unit(u, fields[k], 'customTexts', name, k) end
		end
	end
	local function off(u, ...)
		for _, name in ipairs({ ... }) do
			local texts = units[u] and units[u].customTexts
			if texts and texts[name] then unit(u, false, 'customTexts', name, 'enable') end
		end
	end
	local portraits = type(p.mMediaTag) == 'table' and type(p.mMediaTag.portraits) == 'table' and p.mMediaTag.portraits or {}
	local function noPortrait(u) if type(portraits[u]) == 'table' then leaf(false, 'mMediaTag', 'portraits', u, 'enable') end end
	local px, py, tx, ty = opt('splitPlayerX'), opt('splitPlayerY'), opt('splitTargetX'), opt('splitTargetY')
	local anchors = {
		player = { rel = 'BOTTOM', x = px, y = py, mover = 'ElvUF_PlayerMover', power = 'PlayerPowerBarMover' },
		target = { rel = 'TOP', x = tx, y = -ty, mover = 'ElvUF_TargetMover', power = 'TargetPowerBarMover' },
		focus = { rel = 'BOTTOM', x = px + T.SPLIT.focus.dx, y = py + T.SPLIT.focus.dy, mover = 'ElvUF_FocusMover', power = 'FocusPowerBarMover' },
	}
	for _, key in ipairs(T.SPLIT_UNITS) do
		local g, a = T.SplitGeometry(key, opts), anchors[key]
		local specOn = SpecOn(units[key] and units[key].customTexts)
		unit(key, g.bar, 'width')
		unit(key, g.height, 'height')
		unit(key, false, 'infoPanel', 'enable')
		unit(key, false, 'portrait', 'enable')
		unit(key, false, 'castbar', 'enable')
		unit(key, true, 'power', 'detachFromFrame')
		unit(key, g.bar, 'power', 'detachedWidth')
		unit(key, g.powerHeight, 'power', 'height')
		unit(key, '', 'power', 'text_format')
		off(key, 'm-Name', 'b-Spec', 'm-Health', 'b-HealthPct', 'm-power')
		if T.SPLIT[key].thick then
			-- 1.3.1: Banzai Art draws the Player / Target name and spec lines; this entry only marks the layer
			-- (ElvUI shows nothing for it) and says whether the spec line is on
			unit(key, false, 'customTexts', 'b-SplitName', 'enable')
			unit(key, true, 'customTexts', 'b-SplitName', 'banzaiSplit')
			unit(key, specOn, 'customTexts', 'b-SplitName', 'banzaiSpec')
		else
			local format = T.SPLIT_NAME[key]
			if specOn and T.IDENTITY[key] then format = T.IDENTITY[key] end
			text(key, 'b-SplitName', { attachTextTo = 'Health', justifyH = 'CENTER', xOffset = Round(g.bar / 2 + g.inner), yOffset = -Round(g.hub / 2 - 5),
				size = T.SPLIT[key].name, font = small, fontOutline = 'OUTLINE', text_format = format, enable = true })
		end
		leaf(Mover('RIGHT', a.rel, a.x - g.inner, a.y), 'movers', a.mover)
		leaf(Mover('LEFT', a.rel, a.x + g.inner, a.y), 'movers', a.power)
		noPortrait(key)
	end
	-- the class bar and the extra mana bar above the Player's resource bar (1.3.1: above its values, from
	-- clear of the spell name over the hub to the bar's outer end; 1.3.3: while the bamboo cast bar is on, above it)
	local g, C = T.SplitGeometry('player', opts), T.SPLIT.classbar
	local width = g.bar - C.start - C.inset
	local bottom = Round(g.height / 2) + C.values + C.gap
	if opts.splitCastBar ~= false then bottom = Round(g.castLift + g.castHeight + C.gap) end
	unit('player', true, 'classbar', 'detachFromFrame')
	unit('player', width, 'classbar', 'detachedWidth')
	unit('player', C.height, 'classbar', 'height')
	unit('player', width, 'classAdditional', 'width')
	unit('player', C.height, 'classAdditional', 'height')
	leaf(Mover('BOTTOMLEFT', 'BOTTOM', px + g.inner + C.start, py + bottom), 'movers', 'ClassBarMover')
	leaf(Mover('BOTTOMLEFT', 'BOTTOM', px + g.inner + C.start, py + bottom + C.additional), 'movers', 'AdditionalPowerMover')
	-- Focus: its crowd control (the debuffs Banzai lists) above its health bar, clear of the hub
	for k, v in pairs({ anchorPoint = 'TOPLEFT', growthX = 'RIGHT', xOffset = 0, yOffset = 2, sizeOverride = 18 }) do unit('focus', v, 'debuffs', k) end
	-- Target-of-Target: one compact bar right of the Target, its name above it, the percent inside
	local t, S = T.SplitGeometry('target', opts), T.SPLIT.tot
	local s = tonumber(opts.splitScale) or 1
	local totW, totH = Round(S.bar * s), Round(S.height * s)
	unit('targettarget', totW, 'width')
	unit('targettarget', totH, 'height')
	unit('targettarget', false, 'power', 'enable')
	unit('targettarget', false, 'infoPanel', 'enable')
	text('targettarget', 'm-Name', { justifyH = 'LEFT', xOffset = 0, yOffset = Round(totH / 2 + 6), size = S.name })
	text('targettarget', 'm-Health', { justifyH = 'RIGHT', xOffset = -3, yOffset = 0, size = S.name, enable = true })
	leaf(Mover('LEFT', 'TOP', tx + t.inner + t.bar + S.gap, -ty), 'movers', 'ElvUF_TargetTargetMover')
	-- party / arena allies: the split construction on the role layouts' frames
	if opts.splitParty ~= false then
		local P = T.SPLIT.party
		text('party', 'm-Name', { justifyH = 'CENTER', xOffset = 0, yOffset = -Round(P.circle / 2 - 4), size = P.name })
		text('party', 'b-Role', { justifyH = 'CENTER', xOffset = -Round(P.circle / 2 - 1), yOffset = Round(P.circle / 2 - 6) }) -- a badge on the circle's upper left
		text('party', 'b-Status', { justifyH = 'CENTER', xOffset = 0, yOffset = Round(P.circle / 2 + 2) })
		off('party', 'm-Health', 'b-HealthPct')
		noPortrait('party')
	end
	return out
end

-- the split layer recorded last goes (its classic values back), whatever style comes next
function T.RevertFrameStyle(p, state)
	if type(state) ~= 'table' or type(state.snapshot) ~= 'table' then return false end
	T.RevertSnapshot(p, state.snapshot)
	state.snapshot = nil
	return true
end

function T.ApplyFrameStyle(p, historical, fonts, opts)
	opts = opts or {}
	if T.FrameStyle(opts.frameStyle) ~= 'SPLIT' then return false end
	local leaves = T.SplitLeaves(p, historical, fonts, opts)
	local state = type(opts.splitState) == 'table' and opts.splitState or {}
	state.snapshot = T.Snapshot(p, leaves)
	T.ApplyLeaves(p, leaves)
	return true, #leaves
end

-- ElvUI private profile: start from the character's current private profile
-- (keeps install markers, bag / module choices), lay Bushido's private values
-- over it, then enable what the Bushido layout needs.
-- Private profile fonts: world unit names and nameplates readable, combat numbers heavy.
function T.ApplyBanzaiPrivate(p, historical, fonts)
	fonts = fonts or { display = T.FONT, small = T.SMALL_FONT }
	return T.SplitFonts(p, historical, fonts.display, fonts.small)
end

function T.TransformPrivate(bushido, current, font, isValid, smallFont)
	local p = T.DeepCopy(current or {})
	T.Overlay(p, T.DeepCopy(bushido or {}))
	p.unitframe = p.unitframe or {}
	p.unitframe.enable = true
	p.actionbar = p.actionbar or {}
	p.actionbar.enable = true
	p.general = p.general or {}
	p.general.minimap = p.general.minimap or {}
	p.general.minimap.enable = true
	p.chat = p.chat or {}
	p.chat.enable = true        -- Bushido presents ElvUI chat
	p.nameplates = p.nameplates or {}
	p.nameplates.enable = true  -- Bushido used Plater; its scripts are not restored, ElvUI nameplates are used
	T.ReplaceFonts(p, font, isValid)
	T.ApplyBanzaiPrivate(p, bushido, { display = font, small = smallFont or T.SMALL_FONT })
	return p
end

-- Details profile table: swap Lixdu (name and file path) for the stand-in
-- (0.3.0: the readable small-text font: meter rows and titles are small text).
function T.ReplaceDetailsFonts(tbl, font, fontPath, counter)
	counter = counter or { replaced = 0 }
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			T.ReplaceDetailsFonts(v, font, fontPath, counter)
		elseif type(v) == 'string' then
			if T.MISSING_FONTS[v] then
				tbl[k] = font
				counter.replaced = counter.replaced + 1
			elseif fontPath and string.find(string.lower(v), 'lixdu.ttf', 1, true) then
				tbl[k] = fontPath
				counter.replaced = counter.replaced + 1
			end
		end
	end
	return counter.replaced
end

-- Details side-by-side composition (UIParent units): DAMAGE | HEALING in the
-- lower right; the Banzai frame around them sits on the bottom panel (windows
-- 10 above the bar). Same numbers as BanzaiCompat.DETAILS; bottom follows the
-- panel height (bar + 10). 0.6.0: the windows sit in the middle of the wider
-- parallelogram frame, 47.15 from the right edge. 1.3.6: a real centre gutter -
-- each window 207.5 wide (was 212), 15 between them (was 6), the outer edges kept.
T.DETAILS_LAYOUT = { width = 207.5, height = 124, gap = 15, right = -47.15, bottom = 42 }
T.DETAILS_TEXT_SIZE = 10 -- meter rows and titles (Bushido used 8 at window scale 0.75)

-- Details windows: big titles in the Banzai display font (DAMAGE red family,
-- HEALING green family), sleek meter bars with larger text centred over them,
-- outlined so it reads on any class colour, and room between the rows for that text.
-- 0.6.0: title 22 (0.5.1: 16), bar 5 (0.5.1: 12, -60 %), text 13 (0.5.1: 11.5, +15 %).
-- 0.7.0: the titles are Banzai's own (BushidoPrivateCompat: DAMAGE / HEALING on
-- the chassis' top border), so Details' title text is off; the rows start
-- rowOffset lower (clear of the titles' accent lines); the values read
-- "245K (6.1K)" (no percentage; Details' own value formats on this profile);
-- class-coloured bars on a dark track; name and value vertically centred on
-- the bar and level with each other, the name from the bar's left end, the
-- value to its right end.
T.DETAILS_STYLE = {
	titleSize = 22,
	titleColors = { { 1.00, 0.30, 0.26, 1 }, { 0.32, 0.96, 0.40, 1 } }, -- window 1 damage, window 2 healing
	rowHeight = 5,
	rowFontSize = 13,
	rowGap = 12,      -- the text is taller than the bar: rows keep it apart
	rowOffset = -8,   -- 0.7.0: first row 8 lower
	outline = 'OUTLINE',
	track = { 0.02, 0.04, 0.03, 0.55 },
	-- Details' value formats (total, per second, percent): the percentage left out
	values = { enabled = true, format_tsp = '%s (%s)', format_ts = '%s (%s)', format_tp = '%s', use_alignment = false, alignment_space = 60, first_run = false },
	-- 1.1.0 / 1.1.1: the row text (name and values) is Banzai's: white on glass / solid; on parchment
	-- a bright off-white (1.1.0's charcoal was hard to read over the textured paper and the dark
	-- tracks: the live screenshot settled it) with the same dark outline and shadow as always
	ink = { 0.96, 0.95, 0.92, 1 },
	text = { 1, 1, 1, 1 },
}

-- 1.1.0: the row text colour for the panel background (Details' own
-- row_info.fixed_text_color, which every row text without a colour of its own inherits)
function T.DetailsRowInk(profile, parchment)
	local c = parchment and T.DETAILS_STYLE.ink or T.DETAILS_STYLE.text
	local n = 0
	for _, window in pairs(type(profile.instances) == 'table' and profile.instances or {}) do
		local row = type(window) == 'table' and window.row_info
		if type(row) == 'table' then
			row.fixed_text_color = { c[1], c[2], c[3], c[4] }
			n = n + 1
		end
	end
	return n
end

-- Details' four row texts (row_info.texts: 1 name, 2-4 values), the same
-- fields Details itself stores, every one vertically centred
local function DetailsText(point, x, justifyH, gap)
	return {
		anchor = { point = point, relativeTo = 'statusbar', relativePoint = point, x = x, y = 0, gap = gap },
		justifyH = justifyH, justifyV = 'middle',
		font = { outline = T.DETAILS_STYLE.outline },
		shadow = { color = { 0, 0, 0, 1 }, offset = { 1, -1 } },
		color = { byClass = false },
	}
end

function T.DetailsRowTexts()
	return {
		[1] = DetailsText('left', 2, 'left'),
		[2] = DetailsText('right', -73, 'right', -4),
		[3] = DetailsText('right', -38, 'right', -4),
		[4] = DetailsText('right', 0, 'right'),
		__version = 1,
	}
end

-- 1.3.0 BANZAI COMPACT (BANZAI > LAYOUT > DETAILS > METER STYLE; CURRENT is the
-- default and stays exactly as above): thin class-coloured bars (4), the name
-- above each bar in its class colour from just after a small round identity
-- icon at the row's start, the value large and bright at the right on the same
-- line, rows tight together. Details' own row settings and its window API;
-- the icon set (BushidoPrivateRestore chooses): Darren's original sheet when
-- the build made one, else the Fabled class set Jiberish Icons registers with
-- Details (referenced in place), else Banzai's own class-colour discs.
T.DETAILS_STYLES = { 'CURRENT', 'COMPACT' }
function T.DetailsStyle(style) return (style == 'COMPACT') and 'COMPACT' or 'CURRENT' end
T.DETAILS_COMPACT = { rowHeight = 4, rowGap = 14, rowOffset = -15, iconOffset = 14, iconX = 0, iconY = 5, nameX = 21, nameSize = 12, valueSize = 13, textY = 1 }
T.DETAILS_ICONS = {
	banzai = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\BanzaiIdentity\\details-classes',
	fabled = 'Interface\\AddOns\\JiberishIcons\\Media\\Class\\fabledclass',
	discs = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\BanzaiClassDiscs',
}
-- the icon keys BANZAI COMPACT writes (CURRENT puts Bushido's values back)
T.DETAILS_ICON_KEYS = { 'icon_file', 'no_icon', 'start_after_icon', 'icon_size_offset' }

local function CompactText(point, relativePoint, x, justifyH, size, byClass, gap, face)
	local C = T.DETAILS_COMPACT
	return {
		anchor = { point = point, relativeTo = 'statusbar', relativePoint = relativePoint, x = x, y = C.textY, gap = gap },
		justifyH = justifyH, justifyV = 'middle',
		font = { size = size, outline = T.DETAILS_STYLE.outline, face = face },
		shadow = { color = { 0, 0, 0, 1 }, offset = { 1, -1 } },
		color = { byClass = byClass },
	}
end

-- 1.3.1: nameFace - the Banzai display font file for the names (Details' own per-text font face); the
-- values stay in the row font, readable at their size. Without it the names are exactly 1.3.0's.
T.DETAILS_COMPACT_FACE_SIZE = 14 -- the condensed display face: names a little larger in it
function T.DetailsCompactTexts(nameFace)
	local C = T.DETAILS_COMPACT
	return {
		[1] = CompactText('bottomleft', 'topleft', C.nameX, 'left', nameFace and T.DETAILS_COMPACT_FACE_SIZE or C.nameSize, true, nil, nameFace),
		[2] = CompactText('bottomright', 'topright', -73, 'right', C.valueSize, false, -4),
		[3] = CompactText('bottomright', 'topright', -38, 'right', C.valueSize, false, -4),
		[4] = CompactText('bottomright', 'topright', 0, 'right', C.valueSize, false),
		__version = 1,
	}
end

-- one window's rows in BANZAI COMPACT (over the CURRENT styling)
function T.DetailsCompactRow(row, iconFile, nameFace)
	local C = T.DETAILS_COMPACT
	row.height = C.rowHeight
	row.space = type(row.space) == 'table' and row.space or {}
	row.space.between = C.rowGap
	row.row_offsets = { left = 0, right = 0, top = C.rowOffset, bottom = 0 }
	row.icon_file = iconFile or T.DETAILS_ICONS.discs
	row.no_icon = false
	row.start_after_icon = false -- the bar runs under the icon; the name starts after it
	row.icon_size_offset = C.iconOffset
	row.icon_offset = { C.iconX, C.iconY }
	row.icon_mask = ''
	row.use_spec_icons = false
	row.texts = T.DetailsCompactTexts(nameFace)
	return row
end

-- back to CURRENT on a live window: the CURRENT rows and Bushido's icon settings (no icons)
function T.DetailsCurrentRow(row, historicalRow)
	local S = T.DETAILS_STYLE
	historicalRow = historicalRow or {}
	row.height = S.rowHeight
	row.space = type(row.space) == 'table' and row.space or {}
	row.space.between = S.rowGap
	row.row_offsets = { left = 0, right = 0, top = S.rowOffset, bottom = 0 }
	for _, key in ipairs(T.DETAILS_ICON_KEYS) do row[key] = T.DeepCopy(historicalRow[key]) end
	if row.no_icon == nil then row.no_icon = true end
	row.icon_offset = T.DeepCopy(historicalRow.icon_offset) or { 0, 0 }
	row.texts = T.DetailsRowTexts()
	return row
end

function T.StyleDetailsWindows(profile, smooth, fonts, style, iconFile, nameFace)
	local S = T.DETAILS_STYLE
	local n = 0
	profile.righttext_simple_formatting = T.DeepCopy(S.values)
	for index, window in pairs(type(profile.instances) == 'table' and profile.instances or {}) do
		if type(window) == 'table' then
			local title = window.attribute_text
			if type(title) == 'table' then
				title.enabled = false -- Banzai's DAMAGE / HEALING titles sit on the frame border instead
				title.text_size = S.titleSize
				if fonts and fonts.display then title.text_face = fonts.display end
				title.shadow = true
				local color = S.titleColors[index]
				if color then title.text_color = { color[1], color[2], color[3], color[4] } end
			end
			local row = window.row_info
			if type(row) == 'table' then
				row.height = S.rowHeight
				row.font_size = S.rowFontSize
				row.text_yoffset = 0
				row.space = type(row.space) == 'table' and row.space or {}
				row.space.between = S.rowGap
				row.row_offsets = { left = 0, right = 0, top = S.rowOffset, bottom = 0 }
				row.textL_offset = 0
				row.texture_class_colors = true
				row.texture_background_class_color = false
				row.fixed_texture_background_color = { S.track[1], S.track[2], S.track[3], S.track[4] }
				row.textR_show_data = { true, true, false }
				-- outline: Details' per-text settings, and the flat keys it folds into them
				row.textL_outline_mode, row.textR_outline_mode = S.outline, S.outline
				row.texts = T.DetailsRowTexts()
				if smooth ~= false then row.overlay_texture = T.SMOOTH_TEXTURE end
				if T.DetailsStyle(style) == 'COMPACT' then T.DetailsCompactRow(row, iconFile, nameFace) end -- 1.3.0 (1.3.1: the names' face)
			end
			n = n + 1
		end
	end
	return n
end

---------------------------------------------------------------------------
-- 1.5.0-dev1: the client adapter (WoW Forever)
---------------------------------------------------------------------------
-- The Banzai profile is built from Retail data. ElvUI 16.01 is one code base for both clients and its
-- settings have the same shape on WoW Forever: its default profile was compared leaf by leaf under both
-- clients (27,690 leaves) - no key is Retail-only, Forever adds seven bag keys, and 22 default VALUES
-- differ. Of those only two kinds can reach a profile Banzai writes, and they are what this adapter handles:
--   [petbattle]   a macro condition Forever does not have; every Forever default visibility drops it
--                 (bar1 '[petbattle] hide; show' -> 'show'). A bracket holding it can never be true there:
--                 the bracket goes, and a clause left with no bracket goes with it.
--   [spec:N]      Forever has talent trees, no numbered specialization, and its default drops the condition
--                 instead of the bracket ('[form:1, spec:3] 7;' -> '[form:1] 7;'). What a Retail profile meant
--                 by it cannot be known, so the whole setting is left out and ElvUI's own default stands.
-- Everything else is written as on Retail. A datatext or a tag the installed client does not register is
-- not rewritten either (ElvUI shows nothing for it on both clients): it is only listed, so the difference
-- is visible in /banzai forever. Retail has no rules: the profile is never touched there.
T.CLIENTS = {
	FOREVER = {
		neverTrue = { petbattle = true },    -- the bracket goes
		alwaysTrue = { nopetbattle = true }, -- only the condition goes
		unknown = { spec = true, nospec = true }, -- the setting is left out
		reasons = {
			petbattle = 'pet battles do not exist on WoW Forever (ElvUI\'s Forever defaults drop the condition)',
			nopetbattle = 'pet battles do not exist on WoW Forever (ElvUI\'s Forever defaults drop the condition)',
			spec = 'WoW Forever has talent trees, not numbered specializations: ElvUI\'s default stands',
			nospec = 'WoW Forever has talent trees, not numbered specializations: ElvUI\'s default stands',
		},
	},
}

-- the name of one macro condition: 'bonusbar:1' -> 'bonusbar', ' NoPetBattle ' -> 'nopetbattle', '@raid6' -> '@raid6'
local function ConditionName(condition)
	local name = string.match(condition, '^%s*([^:%s]*)')
	return string.lower(name or '')
end

-- one clause ('[a][b,c] result'): its text for this client; nil when no bracket of it can be true any more;
-- false when it holds a condition the client cannot answer
local function AdaptClause(clause, rules, note)
	local lead = string.match(clause, '^%s*')
	local rest = string.sub(clause, #lead + 1)
	local kept, touched, finalGap = {}, false, ''
	while true do
		local bracket = string.match(rest, '^%b[]')
		if not bracket then break end
		local gap = string.match(string.sub(rest, #bracket + 1), '^%s*')
		rest = string.sub(rest, #bracket + #gap + 1)
		finalGap = gap
		local conditions, never = {}, false
		for condition in string.gmatch(string.sub(bracket, 2, -2) .. ',', '([^,]*),') do
			local name = ConditionName(condition)
			if rules.unknown[name] then
				note(name)
				return false
			elseif rules.neverTrue[name] then
				never, touched = true, true
				note(name)
			elseif rules.alwaysTrue[name] then
				touched = true
				note(name)
			else
				conditions[#conditions + 1] = condition
			end
		end
		if not never then kept[#kept + 1] = { text = '[' .. table.concat(conditions, ','):gsub('^%s+', '') .. ']', gap = gap } end
	end
	if not touched then return clause end
	if #kept == 0 then return nil end
	-- the space between the brackets and the result is the clause's own, whichever bracket carried it
	local text = lead
	for i, bracket in ipairs(kept) do text = text .. bracket.text .. (i == #kept and finalGap or bracket.gap) end
	return text .. rest
end

-- A macro condition string ('[vehicleui][petbattle] hide; show') for a client. Returns the text (the same
-- string when nothing in it needs the client), or nil when the setting cannot be carried over, and the
-- names of the conditions taken out, in the order met.
function T.AdaptConditions(text, flavor)
	local rules = T.CLIENTS[flavor]
	local removed, seen = {}, {}
	if type(text) ~= 'string' or not rules then return text, removed end
	local function note(name)
		if not seen[name] then seen[name] = true removed[#removed + 1] = name end
	end
	local clauses, changed = {}, false
	for clause in string.gmatch(text .. ';', '([^;]*);') do
		local adapted = AdaptClause(clause, rules, note)
		if adapted == false then return nil, removed end
		if adapted ~= clause then changed = true end
		if adapted then clauses[#clauses + 1] = adapted end
	end
	if not changed then return text, removed end
	local out = string.gsub(table.concat(clauses, ';'), '^%s+', '')
	if string.gsub(out, '[%s;]', '') == '' then return nil, removed end -- nothing left to say
	return out, removed
end

-- the tag of one bracket of a text format, as ElvUI's tag parser names it: '[ - >mMT-level]' -> 'mMT-level',
-- '[perhp<%]' -> 'perhp', '[name:eltruism:gradientshortcaps{10}]' -> 'name:eltruism:gradientshortcaps'
function T.TagName(bracket)
	if type(bracket) ~= 'string' then return nil end
	local first = string.match(bracket, '^.*>()') or 2
	local last = (string.match(bracket, '^.-()<') or -1) - 1
	local name = string.gsub(string.sub(bracket, first, last), '%b{}', '')
	name = string.gsub(name, '^%[', '')
	name = string.gsub(name, '%]$', '')
	if name == '' then return nil end
	return name
end

local function SortedKeys(tbl)
	local keys = {}
	for k in pairs(tbl) do keys[#keys + 1] = k end
	table.sort(keys, function(a, b)
		if type(a) == type(b) and (type(a) == 'number' or type(a) == 'string') then return a < b end
		return tostring(a) < tostring(b)
	end)
	return keys
end

local function WalkSettings(tbl, path, visit)
	for _, key in ipairs(SortedKeys(tbl)) do
		local value = tbl[key]
		local here = path == '' and tostring(key) or (path .. '.' .. tostring(key))
		if type(value) == 'table' then
			WalkSettings(value, here, visit)
		else
			visit(tbl, key, value, here, path)
		end
	end
end

-- What a profile names that only the installed client can vouch for: the datatexts in its panels and the
-- tags in its text formats (each list sorted, each name once).
function T.ProfileNames(profile)
	local datatexts, tags, seenD, seenT = {}, {}, {}, {}
	if type(profile) ~= 'table' then return { datatexts = datatexts, tags = tags } end
	WalkSettings(profile, '', function(_, key, value, here)
		if type(value) ~= 'string' or value == '' then return end
		if string.find(here, '^datatexts%.panels%.') and type(key) == 'number' then
			if not seenD[value] then seenD[value] = true datatexts[#datatexts + 1] = value end
		elseif (key == 'text_format' or key == 'format') and string.find(value, '[', 1, true) then
			for bracket in string.gmatch(value, '%[..-%]+') do
				local name = T.TagName(bracket)
				if name and not seenT[name] then seenT[name] = true tags[#tags + 1] = name end
			end
		end
	end)
	table.sort(datatexts)
	table.sort(tags)
	return { datatexts = datatexts, tags = tags }
end

-- Adapts a Banzai profile table to a client, in place, and reports what it did:
--   { flavor, changes = { { path, from, to, reason } ... }, notes = { { path, value, reason } ... } }
-- changes: settings rewritten (to = nil: left out, ElvUI's default stands). notes: nothing was changed,
-- the installed client simply has nothing registered under that name (`known`, optional:
-- { datatexts = { [name] = true|false }, tags = { [name] = true|false } }, false = asked and not there).
-- Deterministic (keys in sorted order) and idempotent; a client without rules is left exactly as it is.
function T.AdaptProfile(profile, flavor, known)
	local report = { flavor = flavor, changes = {}, notes = {} }
	local rules = T.CLIENTS[flavor]
	if type(profile) ~= 'table' or not rules then return report end
	known = type(known) == 'table' and known or {}
	local datatexts, tags = known.datatexts or {}, known.tags or {}
	local removals = {}
	WalkSettings(profile, '', function(owner, key, value, here, parent)
		if type(value) ~= 'string' then return end
		if key == 'visibility' or string.find(parent, '%.paging$') then
			local adapted, removed = T.AdaptConditions(value, flavor)
			if adapted ~= value then
				local reason = rules.reasons[removed[#removed] or ''] or 'not available on this client'
				report.changes[#report.changes + 1] = { path = here, from = value, to = adapted, reason = reason }
				if adapted == nil then removals[#removals + 1] = { owner, key } else owner[key] = adapted end
			end
		elseif string.find(here, '^datatexts%.panels%.') and type(key) == 'number' then
			if value ~= '' and datatexts[value] == false then
				report.notes[#report.notes + 1] = { path = here, value = value, reason = 'no datatext of this name is registered on this client (the slot stays empty, as ElvUI leaves it)' }
			end
		elseif (key == 'text_format' or key == 'format') and string.find(value, '[', 1, true) then
			for bracket in string.gmatch(value, '%[..-%]+') do
				local name = T.TagName(bracket)
				if name and tags[name] == false then
					report.notes[#report.notes + 1] = { path = here, value = name, reason = 'no tag of this name is registered on this client (ElvUI shows nothing for it)' }
				end
			end
		end
	end)
	for _, removal in ipairs(removals) do removal[1][removal[2]] = nil end -- (after the walk: nothing is removed under it)
	return report
end

return T
