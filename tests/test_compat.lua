-- BushidoPrivateCompat (Banzai Art, 1.2.1) against mocked ElvUI frames.
local ns = HK_NS
local G = ns.Geometry
local Theme = ns.Theme
local NAME = 'JiberishUI - Bushido Private'
local SHOJUMARU_PATH = Theme.MEDIA .. 'fonts\\Shojumaru-Regular.ttf'

local function Frame(name, unit)
	local f = HK_NewFrame('Button', name, UIParent)
	f.unit = unit
	-- ElvUI health bar (level 10) with its templated backdrop, detached power (level 8)
	f.Health = HK_NewFrame('StatusBar', nil, f)
	f.Health.level = 10
	f.Health.backdrop = HK_NewFrame('Frame', nil, f.Health)
	f.Health.backdrop.borderColor = { 0, 0, 0, 1 }
	f.Power = HK_NewFrame('StatusBar', nil, f)
	f.Power.level = 8
	return f
end
local player = Frame('ElvUF_Player', 'player')
local target = Frame('ElvUF_Target', 'target')
local tot = Frame('ElvUF_TargetTarget', 'targettarget')
Frame('ElvUF_Focus', 'focus')
Frame('ElvUF_Pet', 'pet')
local party2 = Frame('ElvUF_PartyGroup1UnitButton2', 'party1')
local boss1 = Frame('ElvUF_Boss1', 'boss1')
local arena1 = Frame('ElvUF_Arena1', 'arena1')
HK_UNITS.party1 = 'SHAMAN'
HK_ElvData.current = NAME
-- the real player frame has a layout (the preview copies it)
player.rect, player.Health.rect, player.Power.rect = { 411, 308, 302, 45 }, { 412, 330, 300, 22 }, { 412, 312, 302, 7 }
target.Health.rect = { 1211, 330, 300, 22 }
player.UpdateTags = function(self) self.tagUpdates = (self.tagUpdates or 0) + 1 end

-- ElvUI action buttons (bar 1: 12 square buttons in a row, as ElvUI sizes them with
-- the Banzai profile) and one button of a square bar (bar 3), as LibActionButton builds them
local function ActionButton(name, w, h)
	local b = HK_NewFrame('CheckButton', name, UIParent)
	b.w, b.h = w, h
	b.icon = b:CreateTexture()
	b.highlightTexture, b.pushedTexture, b.checkedTexture = b:CreateTexture(), b:CreateTexture(), b:CreateTexture()
	b.cooldown = HK_NewFrame('Cooldown', nil, b)
	b.Center, b.TopEdge, b.LeftEdge = b:CreateTexture(), b:CreateTexture(), b:CreateTexture()
	b.HotKey = b:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal') -- ElvUI's (it has a font)
	b.HasAction = function(self) return self.spell ~= nil end
	b.GetSpellId = function(self) return self.spell end
	b.effectiveScale = 0.71 -- Darren's UI scale: 30 units = 39.9 screen pixels at 1440 lines
	return b
end
local square = ActionButton('ElvUI_Bar3Button1', 35, 25)
square.spell = 1822
local buttons = {}
for i = 1, 12 do
	local b = ActionButton('ElvUI_Bar1Button' .. i, 30, 30)
	if i <= 10 then b.spell = 5000 + i end
	b.HotKey:SetText(tostring(i))
	buttons[i] = b
end
-- the ElvUI profile the preview reads (sizes, growth, movers)
ElvUI[1].db = {
	unitframe = { units = {
		player = { customTexts = { ['m-Name'] = { justifyH = 'LEFT', xOffset = 12, yOffset = -32, size = 11 } } },
		party = { width = 200, height = 39, growthDirection = 'DOWN_RIGHT', verticalSpacing = 19, horizontalSpacing = 2, power = { enable = false } },
		raid1 = { width = 150, height = 20, growthDirection = 'DOWN_RIGHT', verticalSpacing = 5, horizontalSpacing = 5, numGroups = 4, groupsPerRowCol = 2 },
		arena = { width = 200, height = 35, growthDirection = 'UP', spacing = 16, power = { enable = false } },
		boss = { width = 200, height = 35, growthDirection = 'UP', spacing = 0 },
	} },
	movers = {
		ElvUF_PartyMover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,110,362', ElvUF_Raid1Mover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,23,361',
		ArenaHeaderMover = 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-390,451', BossHeaderMover = 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-38,285',
		ElvUF_TargetMover = 'BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-411,308',
	},
	actionbar = { bar1 = { buttonsPerRow = 12 } },
	general = { minimap = { circle = false } },
	-- 1.2.0: the buff settings the Banzai profile writes (70 % of Bushido's 35 x 30, Bushido's spacing / rows)
	auras = { buffs = { size = 25, height = 21, horizontalSpacing = 6, verticalSpacing = 10, wrapAfter = 10, maxWraps = 2, keepSizeRatio = false } },
}
-- 1.2.0: ElvUI's buff header and its mover (the BUFFS panel frames them)
local buffHeader = HK_NewFrame('AuraContainer', 'ElvUIPlayerBuffs', UIParent)
local buffMover = HK_NewFrame('Button', 'BuffsMover', UIParent)
-- the role layouts BushidoPrivateRestore (Roles.lua) hands the preview (0.9.0: party / arena sizes,
-- DPS on the left edge in line with the raid frames, arena enemies on the right edge)
local HEALER_PARTY = 'BOTTOM,UIParent,BOTTOM,0,472'
local DPS_PARTY = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,54,362'
BanzaiRoles = {
	Current = function() return 'DPS' end,
	Layout = function(_, role)
		if role ~= 'HEALER' then
			return { ElvUF_PartyMover = DPS_PARTY, ArenaAlliesMover = DPS_PARTY, ArenaHeaderMover = 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-54,362',
				['party.width'] = 100, ['arena.width'] = 100, ['arena.height'] = 39 }
		end
		return { ElvUF_PartyMover = HEALER_PARTY, ArenaAlliesMover = HEALER_PARTY, ArenaHeaderMover = 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-54,472',
			ElvUF_Raid1Mover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,560,400',
			['party.growthDirection'] = 'RIGHT_DOWN', ['party.horizontalSpacing'] = 70, ['party.width'] = 100, ['party.height'] = 27,
			['arena.width'] = 100, ['arena.height'] = 27 }
	end,
}
-- Jiberish Icons (its API: GetIdentityIcon by class / spec style, GetUnitSpecialization)
HK_JI_SPECS = {}
local JI_SPEC = 'Interface\\AddOns\\JiberishIcons\\Media\\Spec\\fabledspecializations'
local JI_CLASS = 'Interface\\AddOns\\JiberishIcons\\Media\\Class\\fabledclass'
JiberishIcons = { {
	GetIdentityIcon = function(_, class, _, style, specID)
		if style == 'fabledspecializations' then
			if type(specID) ~= 'number' then return nil, JI_SPEC end
			return { texCoords = { 0, 0, 0, 0.125, 0.125, 0, 0.125, 0.125 }, spec = specID, class = class }, JI_SPEC
		end
		return { texCoords = { 0.5, 0, 0.5, 0.125, 0.625, 0, 0.625, 0.125 }, class = class }, JI_CLASS
	end,
	GetUnitSpecialization = function(_, unit) return HK_JI_SPECS[unit] end,
} }
-- what 0.3.0 saved on Darren's PC (BanzaiCompatDB), plus one value changed on purpose
BanzaiCompatDB = { intensity = 1, barHeight = 22, barOpacity = 0.86, detailsFrame = true, bambooEnds = true, detail = 0.18, barCenterSize = 15, barTextSize = 12, bar = true, gradient = 'FORWARD', theme = 'VIBRANT', minimapFrame = true, castEntries = 8 }

local function byPart(parent, name)
	for _, h in ipairs(HK_Children(parent)) do
		if h.part and (h.part.texture == name or h.part.atlas == name) then return h end
	end
end
local function green(c) return c.g > c.r and c.g > c.b end
local function purple(c) return c.b > c.g and c.r > c.g end
local function orange(c) return c.r > c.g and c.g > c.b end
local function near(a, b) return math.abs(a - b) < 1e-6 end
local C = Theme.COLORS
local LIME, PURPLE = C.lime, C.purple
local function is(c, ref) return near(c.r, ref[1]) and near(c.g, ref[2]) and near(c.b, ref[3]) end
local function plain(fs) return HK_Plain(fs.text) end
-- 1.1.0: the piece of a stalk ('top' / 'bottom' / 'left' / 'right') whose middle is nearest to p (0..1 along it)
local function piece(holder, stalk, p)
	local best, dist
	for i = 1, holder.pieceCount do
		local s = holder.pieces[i]
		if s.stalk == stalk then
			local d = math.abs((s.pa + s.pb) / 2 - p)
			if not dist or d < dist then best, dist = s, d end
		end
	end
	return best
end
local function stalkPieces(holder, stalk)
	local list = {}
	for i = 1, holder.pieceCount do if holder.pieces[i].stalk == stalk then list[#list + 1] = holder.pieces[i] end end
	return list
end
local function tie(holder, corner)
	for _, t in ipairs(holder.ties) do if t.corner == corner then return t end end
end
local function allTextures(root, out, seen)
	out, seen = out or {}, seen or {}
	if seen[root] then return out end
	seen[root] = true
	for _, t in ipairs(root.textures or {}) do out[#out + 1] = t end
	for _, child in ipairs(HK_Children(root)) do allTextures(child, out, seen) end
	return out
end

test('0.3.0 / 0.4.0 settings: changed defaults move to 0.5.0, own choices kept, retired keys removed', function()
	local db = Theme:DB()
	-- 0.6.0: the old account-wide settings become this character's own (Character Sync)
	expectEq(BanzaiCompatDB.chars['Darrensdrood - Stormrage'], db, 'kept per character ("Name - Realm")')
	expectEq(BanzaiCompatDB.legacy.barHeight, 22, 'the 0.5.x account-wide set kept as the starting point')
	expectEq(BanzaiCompatDB.barHeight, nil, 'no settings left at the top level')
	expectEq(db.barHeight, 32, 'bar height (22 -> 28 -> 32)')
	expectEq(db.barOpacity, 0.72, 'glass opacity (0.3.0 default 0.86)')
	expectEq(db.barTextSize, 12, 'own choice kept')
	expectEq(db.castEntries, 6, 'cast history capped at 6 rows')
	expectEq(db.detail, nil, 'retired: bamboo detail')
	expectEq(db.bambooEnds, nil, 'retired: bamboo ends')
	expectEq(db.smoothBars and db.chatFrame and db.logo, true, 'new pieces on by default')
	expectEq(db.actionStyle, 'SQUARE', '1.2.0: Banzai Square action buttons by default')
	expectEq(db.cooldownBars, false, 'target cooldown bars off by default')
	expectEq(db.schema, 9, 'migrated once (1.3.9: schema 9)')
	expectEq(db.displayFace, 'BANZAI_DEFAULT', 'new characters use the undecided BANZAI default')
	ns.Compat:Set('displayFace', 'WANTBANZAI')
	Theme:DB()
	expectEq(db.displayFace, 'BANZAI_DEFAULT', 'a retired saved face migrates to the semantic default')
	Theme:RefreshDisplayFonts()
	ns.Compat:RefreshAll()
	expectEq(db.combatLogo and db.targetPlate, true, '0.6.0 pieces on by default')
	db.barHeight = 28
	expectEq(Theme:DB().barHeight, 28, 'a later choice of 28 is kept')
	db.barHeight, db.castEntries = 32, 4
end)

test('geometry covers every historical static element', function()
	expectEq(#G.units, 5, 'five single-unit frames')
	local count = 0
	for _, u in ipairs(G.units) do count = count + #u.parts end
	expectEq(count, 13, 'thirteen unit parts (backdrops, slots, end points)')
	expectEq(#G.party, 2, 'party plate + end point')
	expectEq(G.mascots, nil, '0.6.0: the combat mascots are not part of Banzai')
end)

test('art is built after login on the historical geometry', function()
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	expectEq(ns.Compat.lastError, nil, 'no error while building')
	expectEq(#HK_Children(player), 3, 'player: backdrop + trough + end bundle')
	expectEq(#HK_Children(target), 3, 'target: backdrop + trough + end bundle')
	expectEq(byPart(player, 'WHITE').strata, 'BACKGROUND', 'dark backdrop at the back')
	local spike = byPart(player, 'BushidoEndPoint')
	expectEq(spike.strata, 'MEDIUM', 'end art layer')
	-- 1.0.0: anchored to the frame's right (inner) end, as far outside it as Bushido had it (156.01 - 302 / 2)
	expectEq(spike.points[1][1] .. spike.points[1][3], 'CENTERRIGHT', 'end art on the inner end')
	expectNear(spike.points[1][4], 156.01 - 151, 'end art at the Bushido end point')
	expectEq(spike.w, 140, 'end art size (Bushido box)')
	-- 0.7.0: bamboo only on Player / Target; the secondary frames are clean
	expectEq(byPart(party2, 'BushidoEndPoint'), nil, 'party: no bamboo')
	for _, name in ipairs({ 'ElvUF_Focus', 'ElvUF_Pet', 'ElvUF_TargetTarget' }) do
		expectEq(byPart(_G[name], 'BushidoEndPoint'), nil, name .. ': no bamboo')
	end
	expectEq(ns.Compat:Counts().ends, 2, 'two end bundles in all: Player and Target')
	for _, f in ipairs({ party2, arena1, boss1 }) do
		local kinds = {}
		for _, h in ipairs(HK_Children(f)) do if h.artKind then kinds[h.artKind] = (kinds[h.artKind] or 0) + 1 end end
		expectEq(kinds['end'], nil, (f.name or '?') .. ': no end art')
		expectEq(kinds.trough, 1, (f.name or '?') .. ': the smooth trough')
	end
end)

-- 1.3.5 (here: the state right after login, before any test opens a preview)
test('1.3.5 nothing developer-like on screen by default (the OFF / CD / DEF / INT / CC / DISP / GUI strip Darren saw is not Banzai\'s): right after login no unit-frame preview or BANZAI SPLIT sample exists - they are built only when asked for, out of combat, and hidden when combat starts; the diagnostics are a settings-page text; no setting shows such a surface by default; no Banzai text reads like that strip; no Banzai TARGET / FOCUS marker without a target / focus', function()
	local Preview = ns.Preview
	expectEq(Preview:AnyShown(), false, 'no preview shown after login')
	for _, key in ipairs(Preview.TYPES) do expectEq(Preview:Get(key), nil, key .. ': no preview sample built until asked for') end
	for _, key in ipairs(Preview.SPLIT_TYPES) do expectEq(Preview:Get(key), nil, key .. ': no split sample built until asked for') end
	for key, value in pairs(Theme.DEFAULTS) do
		local k = string.lower(key)
		for _, word in ipairs({ 'preview', 'debug', 'diagnos', 'dev', 'sample', 'test', 'strip' }) do
			if string.find(k, word, 1, true) then expectEq(key .. '=' .. tostring(value), 'previewState=NORMAL', 'the only such setting names the samples\' state (' .. key .. ')') end
		end
	end
	local STRIP = { OFF = true, CD = true, DEF = true, INT = true, CC = true, DISP = true, GUI = true }
	for _, f in ipairs(HK_Frames()) do
		if f.kind == 'FontString' and type(f.text) == 'string' then expect(not STRIP[HK_Plain(f.text)], 'no Banzai text reads "' .. HK_Plain(f.text) .. '"') end
	end
	local entry = ns.PvPFrames:Get('ElvUF_Arena1')
	expectEq(entry.target.shown or entry.focus.shown, false, 'no TARGET / FOCUS marker without a target / focus')
	-- (asked for out of combat only and hidden when combat starts: the unit-frame preview tests)
end)

test('smooth health: no Bushido slot art, one dark trough under each bar', function()
	for _, f in ipairs({ player, target, tot, party2, boss1, arena1 }) do
		local trough
		for _, h in ipairs(HK_Children(f)) do if h.artKind == 'trough' then trough = h end end
		expect(trough, (f.name or '?') .. ' has a trough')
		expectEq(trough.points[1][2], f.Health, (f.name or '?') .. ' trough follows the health bar')
		expectEq(trough.points[2][2], f.Health, 'both corners')
		expect(trough.level < f.Health.level, 'behind the fill')
		local g = trough.texture.gradient
		expect(g[2].r < 0.06 and g[3].g < 0.1 and g[2].a > 0.9, 'smooth dark empty state')
		expectEq(trough.texture.path, Theme.WHITE, 'plain surface')
	end
	for _, root in ipairs({ player, target, tot, party2, boss1 }) do
		for _, t in ipairs(allTextures(root)) do
			expect(not (t.path and (string.find(t.path, 'NewBushidoHealth', 1, true) or string.find(t.path, '20Bushido', 1, true))), 'no slotted health art')
		end
	end
end)

test('end art: three tied bamboo stalks, no masks, target a full-colour mirror', function()
	local bundle = byPart(player, 'BushidoEndPoint')
	expect(bundle.isBundle, 'bundle art')
	expectEq(#bundle.stalks, 6, 'stalk texture painted in six height bands')
	for i, s in ipairs(bundle.stalks) do
		expect(string.find(s.texture.path, 'BanzaiBundle', 1, true), 'stalk texture ' .. i)
		expectEq(s.texture.masks, nil, 'no mask on stalk band ' .. i)
	end
	local mirrored = byPart(target, 'BushidoEndPoint')
	expectEq(mirrored.stalks[1].texture.coords[1], 1, 'target stalks mirrored')
	for _, s in ipairs(mirrored.stalks) do
		expectEq(s.texture.gradient[2].a, 1, 'target art opaque (not grey / translucent)')
		expect(green(s.texture.gradient[2]), 'target stalks green')
	end
	expectEq(mirrored.parent, target, 'child of the unit frame: out-of-range fading applies')
	expectEq(byPart(player, 'BushidoEndPoint').level, 12, 'above health (10) and power (8)')
end)

test('black frame outline: health backdrop border transparent on Bushido chassis frames only', function()
	for _, f in ipairs({ player, target, party2 }) do
		expectEq(f.Health.backdrop.borderColor[4], 0, (f.name or '?') .. ' border alpha 0')
	end
	expectEq(boss1.Health.backdrop.forcedBorderColors, nil, 'boss frames keep their border')
end)

-- 1.1.0: one bamboo construction around a holder: a straight stalk along each
-- side (body segments one node period each, a tip piece on both ends: one cut,
-- one plain), running a little past the corners, lashed with a rope tie at
-- every crossing; nothing leaning, rotated or warped
local function bambooFrame(holder)
	local P = ns.Compat.PANEL
	local d = holder.stalkDiameter
	expectEq(d, P.stalk * (Theme:DB().borderScale or 1), 'stalk diameter = 10 x border scale')
	expectEq(holder.lean, nil, 'no lean')
	local strip = P.texH / P.texD * d
	for _, name in ipairs({ 'top', 'bottom', 'left', 'right' }) do
		local list = stalkPieces(holder, name)
		local horizontal = name == 'top' or name == 'bottom'
		local along = horizontal and holder.bw or holder.bh
		local short = (horizontal and holder.bw or holder.bh) < 150 -- 1.2.0: the compact BUFFS panel's side stalks
		expect(#list >= (short and 4 or 5), name .. ': several node sections (' .. #list .. ')')
		local bodies, ends, cuts, plains = 0, 0, 0, 0
		local first, last
		for _, s in ipairs(list) do
			local t = s.texture
			expectEq(t.vertex, nil, name .. ': no vertex offsets (nothing warped)')
			expectEq(t.rotation, nil, name .. ': nothing rotated')
			expectEq(t.filter, 'TRILINEAR', name .. ': mip-filtered (sharp when shrunk)')
			expectEq(#t.coords, 8, name .. ': eight tex coords (a vertical stalk reads the texture turned)')
			if horizontal then
				expectNear(-t.points[1][5] + t.h / 2, holder.axis[name], name .. ': on its axis')
				expectNear(t.h, strip, name .. ': the strip height follows the stalk')
				expectEq(t.coords[2] == t.coords[4] - 1 and t.coords[1] == t.coords[3], true, name .. ': horizontal piece reads U along x')
			else
				expectNear(t.points[1][4] + t.w / 2, holder.axis[name], name .. ': on its axis')
				expectNear(t.w, strip, name .. ': the strip width follows the stalk')
				expectEq(t.coords[1] == t.coords[5] and t.coords[2] == 0 and t.coords[6] == 1, true, name .. ': vertical piece reads U along y')
			end
			local from = horizontal and t.points[1][4] or -t.points[1][5]
			local to = from + (horizontal and t.w or t.h)
			if not first or from < first then first = from end
			if not last or to > last then last = to end
			if string.find(t.path, 'BanzaiStalk$') then
				bodies = bodies + 1
				local uEnd = horizontal and t.coords[5] or t.coords[3] -- U runs along x (horizontal) or y (vertical)
				local u0, u1 = math.min(t.coords[1], uEnd), math.max(t.coords[1], uEnd)
				expectNear(u1 - u0, 1 / P.periods, name .. ': one node period per body segment')
			else
				expect(string.find(t.path, 'BanzaiStalkEnd$'), name .. ': the other pieces are ends')
				ends = ends + 1
				local uEnd = horizontal and t.coords[5] or t.coords[3] -- U runs along x (horizontal) or y (vertical)
				local u0, u1 = math.min(t.coords[1], uEnd), math.max(t.coords[1], uEnd)
				if u1 <= 0.5 then cuts = cuts + 1 else plains = plains + 1 end
				expectNear(horizontal and t.w or t.h, P.tipPx / P.texD * d, name .. ': a tip piece is one tip long')
			end
		end
		expectEq(ends, 2, name .. ': two ends')
		expectEq(cuts .. '/' .. plains, '1/1', name .. ': one cut tip, one plain node end')
		expect(bodies >= (short and 2 or 3), name .. ': body segments between them')
		local start = (type(holder.flushLeft) == 'number' and horizontal) and math.max(0, -holder.flushLeft) or -P.ext * d -- 1.2.0: flush-left: from the screen edge
		expectNear(first, start, name .. ': starts at ' .. start)
		local extEnd = (holder.shortBottom and not horizontal) and P.extBottom or P.ext
		expectNear(last, along + extEnd * d, name .. ': and ' .. extEnd * d .. ' past the last' .. (extEnd == 0 and ' (on the bottom panel\'s top line)' or ''))
		-- the segments fill the stalk without a hole: each starts where the one before ends
		table.sort(list, function(a, b) return (horizontal and a.texture.points[1][4] or -a.texture.points[1][5]) < (horizontal and b.texture.points[1][4] or -b.texture.points[1][5]) end)
		for i = 2, #list do
			local a, b = list[i - 1].texture, list[i].texture
			local aEnd = (horizontal and a.points[1][4] or -a.points[1][5]) + (horizontal and a.w or a.h)
			local bStart = horizontal and b.points[1][4] or -b.points[1][5]
			expect(aEnd >= bStart - 1e-6, name .. ': no gap between pieces ' .. i)
		end
	end
	-- the draw order: the bottom stalk under the sides, the top stalk over them, the rope over everything
	expectEq(piece(holder, 'bottom', 0.5).texture.sublevel < piece(holder, 'left', 0.5).texture.sublevel and piece(holder, 'left', 0.5).texture.sublevel < piece(holder, 'top', 0.5).texture.sublevel, true, 'stalks overlap in a fixed order')
	expectEq(#holder.ties, 4, 'four rope ties')
	for _, corner in ipairs({ 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }) do
		local t = tie(holder, corner)
		expect(t, corner .. ' tie')
		expectEq(t.path, Theme.MEDIA .. 'BanzaiRopeTie', corner .. ': the rope texture')
		expectNear(t.w, P.tie * d, corner .. ': restrained size (2.6 x the stalk)')
		local x, y = t.points[1][4] + t.w / 2, -t.points[1][5] + t.w / 2
		local leftX = (type(holder.flushLeft) == 'number') and math.max(holder.axis.left, t.w / 2 - holder.flushLeft) or holder.axis.left -- 1.2.0: kept on the screen
		expectNear(x, string.find(corner, 'LEFT', 1, true) and leftX or holder.axis.right, corner .. ': on the crossing (x)')
		expectNear(y, string.find(corner, 'TOP', 1, true) and holder.axis.top or holder.axis.bottom, corner .. ': on the crossing (y)')
		expectEq(t.coords[1], string.find(corner, 'RIGHT', 1, true) and 1 or 0, corner .. ': right-hand ties mirrored')
		if holder.shortBottom and string.find(corner, 'BOTTOM', 1, true) then
			expectNear(-t.points[1][5] + t.h, holder.bh, corner .. ': the rope stops on the bottom panel\'s top line')
			expectNear(t.coords[4], t.h / t.w, corner .. ': cut, not squashed')
		else
			expectEq(t.h, t.w, corner .. ': the whole tie')
		end
		expect(t.sublevel > piece(holder, 'top', 0.5).texture.sublevel, corner .. ': the rope lies over the stalks')
	end
	expectEq(holder.bundles, nil, 'no corner bundles')
	expectNear(holder.axis.top, P.outer + d / 2, 'top stalk axis: outer margin + half the stalk')
	expectNear(holder.axis.left, P.outer + d / 2, 'left stalk axis')
	expectNear(holder.axis.bottom, holder.bh - P.outer - d / 2, 'bottom stalk axis')
	expectNear(holder.axis.right, holder.bw - P.outer - d / 2, 'right stalk axis')
end

test('1.1.0 minimap: a square bamboo frame hugging the map, the map square and unclipped, zone name above', function()
	local map = ns.Compat.minimapFrame
	local P = ns.Compat.PANEL
	expectEq(map.parent, Minimap, 'parented to the minimap')
	expectEq(map.w, 185 + 2 * (P.outer + P.stalk), 'the frame hugs the map: outer margin + stalk each side (206)')
	expectEq(map.w, map.h, 'square')
	expectEq(Minimap.mask, 130937, 'ElvUI\'s own square mask: the map fills the frame, nothing clipped away')
	expectEq(Minimap.rotation, nil, 'the map itself is not rotated')
	expectEq(Minimap.w, 185, 'nor resized')
	expectEq(map.glass, nil, 'no background of its own: the map is the interior')
	expectEq(map.parchment, nil, 'no parchment either')
	bambooFrame(map)
	-- the content: the stalk's inner edge is the map's edge
	expectNear(map.w / 2 - (P.outer + P.stalk), 185 / 2, 'stalks end exactly at the map edge')
	local label = map.zone
	expectEq(label.points[1][1] .. label.points[1][3], 'BOTTOMTOP', 'zone name above the frame')
	expectEq(label.points[1][4], 0, 'centred over the top stalk')
	expect(label.points[1][5] >= 3, 'clear of the top stalk')
	expect(label.text.w <= map.w - 2 * P.tie * P.stalk / 2 - 2, 'between the two top ties')
	expectEq(plain(label.text), 'DORNOGAL', 'zone name')
end)

test('1.1.0 Details: bamboo frame around both meters, flush with the bottom panel, titles on the top stalk, background inside', function()
	local frame = ns.Compat.detailsFrame
	local D, B, P = ns.Compat.DETAILS, ns.Compat.BAND, ns.Compat.PANEL
	expectEq(frame.w, D.frameWidth, 'frame width kept (493.31)')
	expectEq(frame.h, 161, 'frame height kept')
	expectEq(frame.strata, 'BACKGROUND', 'behind the Details windows (LOW)')
	expectEq(frame.points[1][2], HK_DetailsWindow2.baseframe, 'follows the right Details window')
	bambooFrame(frame)
	expectEq(frame.shortBottom, true, 'the side stalks\' bottom ends are the short ones (clear of the bottom panel text)')
	-- the square content (both windows) sits in the middle, clear of the stalks
	local content = 2 * D.width + D.gap
	local left = (frame.bw - content) / 2
	expect(left >= B.outer + frame.stalkDiameter, 'left stalk clear of the content')
	expect(math.abs(D.right + (D.edge - B.outer + left)) < 0.01, 'content in the middle; lower outer corner 16 from the edge')
	expectEq(D.bottom - B.inset + B.outer, Theme:DB().barHeight, 'flush with the bottom panel (no gap)')
	expectEq(B.inset, B.outer + P.stalk, 'the content inset is exactly the stalk at scale 1')
	expectEq(D.centerY, B.inset * -1 + D.frameHeight / 2, 'frame centre from the window corner')
	-- nothing of the frame reaches below the bottom panel's top line (the panel's glass would ghost it)
	expectEq(P.extBottom, 0, 'side stalks end on the bottom panel\'s top line')
	-- background: the glass reaches under the stalk to its axis; the parchment pieces exist but hide while GLASS is on
	local g = frame.glass
	expectNear(g.points[1][4], P.outer + P.stalk / 2, 'glass up to the stalk axis')
	expect(g.gradient[2].g > g.gradient[2].r and g.gradient[2].g < 0.15 and g.gradient[2].a < 1, 'very dark green translucent glass (GLASS default)')
	expectEq(#frame.parchment, 13, 'parchment (1.3.7: one material): the body, 4 corners, 8 edge halves')
	expectEq(frame.parchment[6].coords[1] .. ',' .. frame.parchment[6].coords[2], '0,0', 'an edge strip starts where it meets its corner (1.3.7: repeated along the edge, never stretched)')
	expectEq(frame.parchment[1].shown, false, 'parchment hidden under GLASS')
	expect(string.find(frame.parchment[1].path, 'BanzaiParchment', 1, true), 'the parchment texture')
	-- 0.7.0 titles: DAMAGE left in the damage half, HEALING right in the healing half (clear of the
	-- top-right tie), centred on the top stalk, dark backing, accent line under each
	local titles = ns.Compat.detailsTitles
	local TT = ns.Compat.DETAILS_TITLE
	expectEq(#titles, 2, 'one per window')
	local dmg, heal = titles[1], titles[2]
	expectEq(HK_Plain(dmg.text.text), 'DAMAGE', 'exactly DAMAGE')
	expectEq(HK_Plain(heal.text.text), 'HEALING', 'exactly HEALING')
	expectEq(dmg.shown and heal.shown, true, 'shown with the frame')
	expectEq(dmg.text.fontSize, 23, 'prominent with the 105% BANZAI Default base')
	local line = P.outer + frame.stalkDiameter / 2 -- the top stalk's axis
	for _, t in ipairs(titles) do
		expectEq(t.points[1][2], frame, 'placed on the Details frame')
		expectEq(t.points[1][3], 'TOPLEFT', 'from its top edge')
		expectNear(t.points[1][5], -line, 'vertically centred on the top stalk')
		expectEq(t.strata, 'MEDIUM', 'above the stalk, so it runs behind the letters')
	end
	expectEq(dmg.points[1][1], 'LEFT', 'DAMAGE left-aligned')
	expectEq(heal.points[1][1], 'RIGHT', 'HEALING right-aligned')
	local center = frame.bw / 2
	expectNear(dmg.points[1][4] + TT.pad, center + D.centerX + TT.inset, 'DAMAGE starts at the damage window\'s left edge')
	local healRight = heal.points[1][4] - TT.pad
	expect(healRight > center + D.gap / 2 + 100, 'HEALING in the healing half')
	expect(healRight <= center - D.centerX - TT.inset + 1e-6, 'inside the healing window')
	local tieLeft = frame.axis.right - P.tie * frame.stalkDiameter / 2
	expect(healRight <= tieLeft - TT.bamboo + 1e-6, 'clear of the top-right rope tie')
	-- strong red / green per-letter gradients
	local function first(text)
		local hex = string.match(text, '|cff(%x%x%x%x%x%x)')
		return { r = tonumber(string.sub(hex, 1, 2), 16) / 255, g = tonumber(string.sub(hex, 3, 4), 16) / 255, b = tonumber(string.sub(hex, 5, 6), 16) / 255 }
	end
	local red, grn = first(dmg.text.text), first(heal.text.text)
	expect(red.r > 0.9 and red.g < 0.5, 'DAMAGE: red gradient')
	expect(grn.g > 0.9 and grn.r < 0.6, 'HEALING: green gradient')
	local mid = dmg.backing[2].gradient
	expect(mid[2].r < 0.05 and mid[2].a > 0.8, 'dark solid backing in the middle')
	expectEq(dmg.backing[1].gradient[2].a, 0, 'soft left end')
	expectEq(dmg.backing[3].gradient[3].a, 0, 'soft right end')
	expectEq(dmg.accent.points[1][2], dmg, 'accent under DAMAGE')
	expectEq(dmg.accent.points[1][3], 'BOTTOMLEFT', 'from its left')
	expectEq(heal.accent.points[1][3], 'BOTTOMRIGHT', 'from HEALING\'s right')
	expect(dmg.accent.gradient[2].r > 0.9 and dmg.accent.gradient[3].a == 0, 'red line fading out to the right')
	expect(heal.accent.gradient[3].g > 0.9 and heal.accent.gradient[2].a == 0, 'green line fading out to the left')
	HK_DetailsWindow.GetDisplay = function() return 2, 1 end
	ns.Compat:UpdateDetailsTitles()
	expectEq(HK_Plain(dmg.text.text), 'HEALING', 'window 1 showing healing: HEALING')
	expect(dmg.accent.gradient[2].g > 0.9, 'with the green accent')
	HK_DetailsWindow.GetDisplay = nil
	ns.Compat:UpdateDetailsTitles()
	expectEq(HK_Plain(dmg.text.text), 'DAMAGE', 'back to DAMAGE')
	expect(dmg.accent.gradient[2].r > 0.9, 'red accent again')
	local h = TT.size * 0.78
	local accentBottom = (D.frameHeight / 2 + D.centerY - D.height) - line - h / 2 - TT.gap - TT.accent
	expect(accentBottom > 6, 'accent line well above the windows\' top edge (' .. accentBottom .. ')')
end)

test('1.1.0 chat: the same frame as Details in the lower left, flush, the chat panel upright in the middle, bamboo all round', function()
	local chat = ns.Compat.chatFrame
	local D, B, P = ns.Compat.DETAILS, ns.Compat.BAND, ns.Compat.PANEL
	expectEq(chat.w, D.frameWidth, 'same width as Details')
	expectEq(chat.h, D.frameHeight, 'same height as Details')
	expectEq(chat.strata, 'BACKGROUND', 'behind the chat text')
	expectEq(chat.points[1][1], 'BOTTOMLEFT', 'lower left')
	expectEq(chat.points[1][5] + B.outer, Theme:DB().barHeight, 'visible edge on the bottom panel top edge')
	local leftEdge = chat.points[1][4] + B.outer -- the left stalk's outer edge on the screen
	expect(leftEdge <= 0 and leftEdge > -0.25, '1.2.0: flush with the left screen edge (' .. leftEdge .. ')')
	expect(math.abs(chat.points[1][4] + (chat.bw - 430) / 2 - ns.Compat.CHAT.contentX) < 1e-3, 'the ElvUI chat panel (430 wide, x 31) in the middle of it')
	expect((chat.bw - 430) / 2 >= B.outer + chat.stalkDiameter, 'side stalks clear of the chat panel')
	expectEq(chat.stalkDiameter, ns.Compat.detailsFrame.stalkDiameter, 'same stalk thickness as Details')
	bambooFrame(chat)
	expect(chat.glass.gradient[2].a < 1, 'translucent glass')
	expectEq(chat.shown, true, 'shown')
	ns.Compat:Set('chatFrame', false)
	expectEq(chat.shown, false, 'the chat frame can be switched off')
	ns.Compat:Set('chatFrame', true)
end)

test('chat title 0.8.0 / 0.9.0: CHAT centred on the top border, the DAMAGE / HEALING treatment, a darker green -> red', function()
	local t, dmg = ns.Compat.chatTitle, ns.Compat.detailsTitles[1]
	local chat = ns.Compat.chatFrame
	expect(t, 'built with the chat frame')
	expectEq(HK_Plain(t.text.text), 'CHAT', 'exactly CHAT')
	expectEq(t.shown, true, 'shown with the chat frame')
	expectEq(t.text.font, dmg.text.font, 'same font as DAMAGE / HEALING')
	expectEq(t.text.fontSize, dmg.text.fontSize, 'same size')
	expectEq(t.text.fontFlags, dmg.text.fontFlags, 'same weight / outline')
	expectEq(t.points[1][1], 'CENTER', 'centred')
	expectEq(t.points[1][2], chat, 'on the chat frame')
	expectEq(t.points[1][5], dmg.points[1][5], 'on the top border line, like the Details titles')
	local first = string.match(t.text.text, '^|cff(%x%x%x%x%x%x)')
	local r0, g0 = tonumber(string.sub(first or '', 1, 2), 16), tonumber(string.sub(first or '', 3, 4), 16)
	expect(first and g0 > 2 * r0 and g0 < 200, 'letters start in a dark green (0.9.0: quieter than HEALING)')
	local CT, heal, dmgStyle = ns.Compat.CHAT_TITLE, ns.Compat.DETAILS_TITLES[2], ns.Compat.DETAILS_TITLES[1]
	local function sum(c) return c[1] + c[2] + c[3] end
	expect(sum(CT.bright) < sum(heal.bright) and sum(CT.deep) < sum(dmgStyle.bright), 'not as bright as HEALING / DAMAGE')
	expect(CT.bright[2] > CT.bright[1] and CT.deep[1] > CT.deep[2], 'still green -> red')
	expect(is(t.accent.gradient[2], CT.bright) and is(t.accent.gradient[3], CT.deep), 'accent green -> red')
	expectEq(t.accent.points[1][1], 'TOP', 'accent centred under the letters')
	expect(t.backing[2].gradient[2].a > 0.5, 'dark backing behind the letters')
	ns.Compat:Set('chatFrame', false)
	expectEq(t.shown, false, 'hidden with the chat glass')
	ns.Compat:Set('chatFrame', true)
	expectEq(t.shown, true, 'back')
end)

test('0.8.0 settings: PvP choices and the preview state are BANZAI settings (Character Sync carries them)', function()
	local D = Theme.DEFAULTS
	expectEq(D.pvpCastColors and D.pvpDispelGlow and D.pvpDefensives, true, 'PvP switches on by default')
	expectEq(D.previewState, 'NORMAL', 'preview NORMAL by default')
	expectEq(Theme.VERSION, '1.5.0', 'version')
	Theme:DB().pvpDefensives = false
	Theme:DB().previewState = 'CC'
	local out = Theme:Export()
	expectEq(out.pvpDefensives, false, 'exported')
	expectEq(out.previewState, 'CC', 'preview preference exported')
	Theme:DB().pvpDefensives, Theme:DB().previewState = true, 'NORMAL'
	Theme:Import(out)
	expectEq(Theme:DB().pvpDefensives, false, 'imported on another character')
	Theme:DB().pvpDefensives, Theme:DB().previewState = true, 'NORMAL'
end)

test('HUD logo: one BANZAI wordmark, transparent, small, top centre of the screen', function()
	local logo = BanzaiLogo
	expectEq(logo.shown, true, 'shown')
	expectEq(#logo.textures, 2, 'wordmark only (no panel): the letters and their hover copy')
	expect(string.find(logo.texture.path, 'BanzaiWordmark', 1, true), 'wordmark texture (transparent background)')
	expect(string.find(logo.glow.path, 'BanzaiWordmark', 1, true) and logo.glow.shown == false, '1.0.0: the hover copy hidden until hovered')
	expectEq(logo.h, 24, 'about the height of the buff icons')
	expectEq(logo.points[1][1], 'TOP', 'top ...')
	expectEq(logo.points[1][2], UIParent, '... of the screen')
	expectEq(logo.points[1][3], 'TOP', 'top edge')
	expectEq(logo.points[1][4], 0, 'horizontally centred')
	expect(logo.points[1][5] < 0 and logo.points[1][5] > -20, 'near the top edge with padding')
	local logos = 0
	for _, f in ipairs(HK_Children(UIParent)) do
		local has = false
		for _, t in ipairs(f.textures or {}) do if t.path and string.find(t.path, 'BanzaiWordmark', 1, true) and f.shown then has = true end end
		if has then logos = logos + 1 end
	end
	expectEq(logos, 1, 'only one wordmark on screen out of combat')
	expectEq(BanzaiCombatLogo.shown, false, 'combat logo hidden out of combat')
	ns.Compat:Set('logo', false)
	expectEq(logo.shown, false, 'can be switched off')
	ns.Compat:Set('logo', true)
end)

test('combat branding: wordmark between Player and Target at 1.75x with the tree, small logo back after combat', function()
	local C2 = ns.Compat.COMBAT
	local combat = BanzaiCombatLogo
	expect(string.find(combat.tree.path, 'BanzaiBonsai', 1, true), 'original miniature tree')
	expect(string.find(combat.wordmark.path, 'BanzaiWordmark', 1, true), 'the same wordmark')
	expectEq(combat.wordmark.w, BanzaiLogo.w * 1.75, '1.75 x the HUD wordmark (width)')
	expectEq(combat.wordmark.h, BanzaiLogo.h * 1.75, '1.75 x (height)')
	expect(combat.wordmark.sublevel > combat.tree.sublevel, 'letters drawn above the tree')
	expect(combat.tree.w <= 140, 'compact')
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(combat.shown, true, 'combat: shown')
	expectEq(BanzaiLogo.shown, false, 'combat: the small top logo hidden')
	expect(combat.fade.playing, 'quick fade in')
	expectEq(combat.fade.anims[1].duration <= 0.2, true, 'not a slow animation')
	local p = combat.points[1]
	expectEq(p[2], UIParent, 'placed on the screen ...')
	expectNear(p[4], (412 + 300 + 1211) / 2, '... dead centre between the Player and Target health bars')
	expectNear(p[5] - C2.lift, 341, 'letters level with the middle of the health bars')
	expect(p[5] - C2.lift - C2.tree / 2 + C2.lift > 250, 'clear above the cast history (top 250)')
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(combat.shown, false, 'after combat: hidden')
	expectEq(BanzaiLogo.shown, true, 'small logo back at the top')
	ns.Compat:Set('combatLogo', false)
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(combat.shown, false, 'combat logo can be switched off ...')
	expectEq(BanzaiLogo.shown, true, '... then the small logo just stays')
	HK_Fire('PLAYER_REGEN_ENABLED')
	ns.Compat:Set('combatLogo', true)
	-- the two Bushido combat mascots are gone
	for _, f in ipairs(HK_Children(UIParent)) do
		for _, t in ipairs(f.textures or {}) do expect(not (t.path and string.find(t.path, 'BushidoCombat', 1, true)), 'no combat mascot art') end
	end
end)

test('1.1.0 border scale reaches the minimap, Details and chat stalks together; the minimap frame follows it; bounded at the content inset', function()
	local P = ns.Compat.PANEL
	local chat = ns.Compat.chatFrame
	local pieces = chat.pieceCount
	ns.Compat:Set('borderScale', 0.8)
	expectEq(ns.Compat.detailsFrame.stalkDiameter, 8, 'Details')
	expectEq(chat.stalkDiameter, 8, 'chat')
	expectEq(ns.Compat.minimapFrame.stalkDiameter, 8, 'minimap')
	expectEq(ns.Compat.minimapFrame.w, 185 + 2 * (P.outer + 8), 'the minimap frame still hugs the map')
	expectNear(tie(chat, 'TOPLEFT').w, P.tie * 8, 'ties scale with it')
	expectNear(ns.Compat.detailsTitles[1].points[1][5], -(P.outer + 4), 'titles stay on the thinner stalk\'s axis')
	expect(chat.pieceCount > pieces, 'a thinner stalk has more node sections')
	for i = 1, chat.pieceCount do expectEq(chat.pieces[i].texture.sublevel, chat.pieces[i].sub, 'piece ' .. i .. ' drawn on its stalk\'s layer after the re-layout') end
	ns.Compat:Set('borderScale', 1.8)
	local _, _, scale = ns.Compat:PanelStyle()
	expectEq(scale, 1, 'bounded at 100 %: thicker would cover the chat lines and the outer meter bars')
	expectEq(Theme:DB().borderScale, 1, 'the saved value itself is clamped')
	ns.Compat:Set('borderScale', 1)
	expectEq(ns.Compat.detailsFrame.stalkDiameter, 10, 'back')
	expectEq(ns.Compat.minimapFrame.w, 206, 'minimap frame back')
	for i = chat.pieceCount + 1, #chat.pieces do expectEq(chat.pieces[i].texture.shown, false, 'spare piece ' .. i .. ' hidden') end
	local key = chat.layoutKey
	ns.Compat:Refresh()
	expectEq(chat.layoutKey, key, 'an unchanged frame is not laid out again')
end)

test('health inside Player / Target / Focus and (0.7.0) Party / Arena / Boss: bright over the fill, ghosted over the empty bar', function()
	local H = ns.Health
	-- 1.0.0: closer to the class circle on the half-width bars (clear of the bamboo at the inner end)
	for _, def in ipairs({ { 'ElvUF_Player', player, 'LEFT', 14 }, { 'ElvUF_Target', target, 'RIGHT', -14 } }) do
		local entry = H:Get(def[1])
		expect(entry, def[1] .. ' built')
		local f = def[2]
		expectEq(entry.holder.parent, f.Health, 'inside the health bar')
		expectEq(entry.clip.clips, true, 'clips its children')
		expectEq(entry.clip.allPoints, f.Health.fill, 'clip = the bar fill texture')
		expectEq(entry.ghost.value.textColor[4], H.GHOST_ALPHA, 'ghost translucent')
		expectEq(entry.bright.value.points[1][1], def[3], 'side')
		expectEq(entry.bright.value.points[1][4], def[4], 'offset')
		expect(entry.bright.value.fontSize > entry.bright.percent.fontSize, 'value dominant, percent smaller')
		local tags = {}
		for _, t in ipairs(f.tags) do tags[t[2]] = (tags[t[2]] or 0) + 1 end
		expectEq(tags[H.VALUE_TAG], 2, 'value tag on both copies')
		expectEq(tags[H.PERCENT_TAG], 2, 'percent tag on both copies')
	end
	-- 0.7.0: the secondary frames: value + percent inside, from the bar's left end, compact
	for _, f in ipairs({ party2, arena1, boss1 }) do
		local entry = H:Get(f.name)
		expect(entry, f.name .. ': health text inside')
		expectEq(entry.holder.parent, f.Health, f.name .. ': inside the health bar')
		expectEq(entry.clip.allPoints, f.Health.fill, f.name .. ': bright over the fill')
		expectEq(entry.ghost.value.textColor[4], H.GHOST_ALPHA, f.name .. ': ghosted over the empty part')
		expectEq(entry.bright.value.points[1][1], 'LEFT', f.name .. ': from the left end')
		if f == party2 then expectEq(entry.bright.value.points[1][4], 4, '0.9.0 party: the value at the left end (the role icon sits at the right end)') end
		expect(entry.bright.value.fontSize <= 12 and entry.bright.percent.fontSize < entry.bright.value.fontSize, f.name .. ': compact, value dominant')
		local tags = {}
		for _, t in ipairs(f.tags) do tags[t[2]] = (tags[t[2]] or 0) + 1 end
		expectEq(tags[H.VALUE_TAG], 2, f.name .. ': current health (ElvUI tag)')
		expectEq(tags[H.PERCENT_TAG], 2, f.name .. ': percentage (ElvUI tag)')
	end
end)

test('identity: player spec from the client, target spec from ElvUI, NPC name only, complementary colour', function()
	local after, before = HK_TAGS['banzai:spec:after'], HK_TAGS['banzai:spec:before']
	expect(after and before, 'tags registered with ElvUI')
	HK_SPEC.player = nil -- ElvUI's spec value not ready yet (0.4.0 in game)
	expectEq(HK_Plain(after.fn('player')), ' - FERAL', 'player spec straight from GetSpecialization')
	expectEq(HK_Plain(before.fn('target')), 'FROST - ', 'target prefix')
	-- 0.5.1: another player's spec comes from the game's inspect data; until it arrives, the name alone
	HK_SPEC.target = nil
	HK_TOOLTIP.target = { 'Kaelyth', 'Level 90 Blood Elf Frost Mage (Player)' }
	expectEq(before.fn('target'), nil, 'no inspect data yet: name only (tooltip text is not parsed)')
	HK_TOOLTIP.target = nil
	HK_INSPECT_REQUESTS = {}
	HK_Fire('PLAYER_TARGET_CHANGED')
	expectEq(HK_INSPECT_REQUESTS[1], 'target', 'inspect data requested for the targeted player')
	HK_INSPECT['Player-2'] = 64
	local updates0 = player.tagUpdates or 0
	HK_Fire('INSPECT_READY', 'Player-3')
	expectEq(before.fn('target'), nil, 'data for another GUID is ignored')
	HK_Fire('INSPECT_READY', 'Player-2')
	expectEq(HK_Plain(before.fn('target')), 'FROST - ', 'SPEC - NAME once the game reports the spec')
	expect((player.tagUpdates or 0) > updates0, 'line redrawn when the data arrives')
	HK_INSPECT_REQUESTS = {}
	HK_NOW = HK_NOW + 5
	HK_Fire('PLAYER_TARGET_CHANGED')
	expectEq(#HK_INSPECT_REQUESTS, 0, 'known GUID: no new request')
	HK_IN_COMBAT = true
	HK_GUIDS.target = 'Player-9'
	HK_NOW = HK_NOW + 5
	HK_Fire('PLAYER_TARGET_CHANGED')
	expectEq(#HK_INSPECT_REQUESTS, 0, 'never in combat')
	HK_IN_COMBAT = false
	HK_GUIDS.target = 'Player-2'
	HK_NPC.target = true
	expectEq(before.fn('target'), nil, 'NPC: nothing (name only)')
	HK_NPC.target = nil
	HK_SPEC.target = 'Frost'
	HK_INSPECT['Player-2'] = nil
	local from = ns.Tags.SpecColors('player')
	expect(is({ r = from[1], g = from[2], b = from[3] }, LIME), 'druid (orange name): lime -> emerald spec')
	HK_UNITS.focus = 'HUNTER'
	local hunter = ns.Tags.SpecColors('focus')
	expect(is({ r = hunter[1], g = hunter[2], b = hunter[3] }, C.violet), 'hunter (green name): violet -> purple spec')
	HK_UNITS.focus = nil
	local updates = player.tagUpdates or 0
	HK_Fire('PLAYER_TARGET_CHANGED')
	HK_RunTimers()
	expect((player.tagUpdates or 0) > updates, 'identity lines redrawn after a change (frame:UpdateTags)')
end)

test('bottom bar: locked order, pairs centred in their segments, one baseline, centred vertically', function()
	local bar = BanzaiInfoBar
	expectEq(bar.shown, true, 'shown on the Banzai profile')
	local order = { left = { 'honor', 'conquest', 'mastery', 'haste', 'versatility', 'durability' }, center = { 'fps', 'ms', 'time' }, right = { 'spec', 'ilvl', 'professions', 'friends', 'guild', 'gold' } }
	for group, list in pairs(order) do
		for i, key in ipairs(list) do expectEq(ns.Bar.ITEMS[group][i].key, key, group .. ' ' .. i) end
	end
	local byKey = {}
	for _, item in ipairs(bar.items) do byKey[item.def.key] = item end
	for key, item in pairs(byKey) do
		local x = item.points[1][4]
		local centre = x + item.w / 2
		local seg = item.segment
		expect(math.abs(centre - (seg[1] + seg[2]) / 2) < 0.01, key .. ' centred in its segment')
		expect(x >= seg[1] - 1 and x + item.w <= seg[2] + 1, key .. ' inside its segment')
		expectEq(item.points[1][5], -1, key .. ' centred below the top edge')
		if item.label then
			expectEq(item.label.points[1][1], 'BOTTOMRIGHT', key .. ' label on the value baseline')
			expectEq(item.label.points[1][2], item.value, key .. ' label right before the value')
		end
	end
	local function room(item) return (item.segment[2] - item.segment[1]) - item.w end
	expect(math.abs(room(byKey.honor) - room(byKey.durability)) < 0.01, 'same room around every pair (left)')
	expect(math.abs(room(byKey.spec) - room(byKey.gold)) < 0.01, 'same room around every pair (right)')
	expectEq(byKey.honor.segment[2], byKey.conquest.segment[1], 'segments follow each other')
	expect(byKey.gold.segment[2] > 1923 - 12, 'gold in the right-most segment')
	local centre = (byKey.fps.segment[1] + byKey.time.segment[2]) / 2
	expect(math.abs(centre - 1923 / 2) < 1, 'FPS / MS / TIME centred')
	expectEq(bar.h, 32, 'taller panel (vertical padding)')
	expectEq(byKey.honor.h, 30, 'text area below the 2-unit edge')
	-- FPS: one green for label and value, not yellow, used nowhere else
	local fps = ns.Bar.FPS_COLOR
	expect(string.find(byKey.fps.value.text, Theme:Hex(fps), 1, true), 'FPS value in the FPS green')
	expect(string.find(byKey.fps.label.text, Theme:Hex(fps), 1, true), 'FPS label in the same green')
	expect(fps[2] > 0.9 and fps[1] < 0.3, 'a green, not yellow')
	for key, item in pairs(byKey) do
		if key ~= 'fps' then expect(not string.find(item.value.text, Theme:Hex(fps), 1, true), key .. ' does not use the FPS green') end
	end
	expect(not string.find(byKey.ms.value.text, 'ffcc33', 1, true), 'latency neutral unless high')
	expectEq(HK_Plain(byKey.fps.value.text), '144', 'fps')
	expectEq(HK_Plain(byKey.ms.value.text), '45', 'latency')
	expect(string.find(HK_Plain(byKey.ilvl.value.text), 'PVE 712', 1, true), 'item level')
	expect(string.find(HK_Plain(byKey.gold.value.text), '123,456', 1, true), 'gold')
	local g = bar.glass.gradient
	expect(g[2].a < 0.85 and g[3].a < 0.85, 'translucent glass (alpha in the colours)')
	for _, e in ipairs(bar.edges) do
		expectEq(e.points[1][5], 0, 'gradient edge on top')
		expectEq(e.h, 2, 'thin')
	end
	expectEq(bar.glows, nil, 'no second (glow) line under the edge')
	expectEq(#bar.textures, 1 + #bar.edges, 'only the glass and the thin edge')
end)

test('objective tracker: exactly the minimap composition width, under it, HIDE / SHOW', function()
	local f = BanzaiTracker
	local map = ns.Compat.minimapFrame
	expectEq(f.shown, true, 'shown')
	expectEq(f.points[1][2], map, 'anchored to the minimap composition')
	expectEq(f.points[1][1], 'TOPLEFT', 'left edges aligned ...')
	expectEq(f.points[1][3], 'BOTTOMLEFT', '... under it')
	expectNear(f.points[1][4], ns.Compat.BAND.outer, 'starts on the visible edge of the bottom stalk')
	expectNear(f.w, map.bw - 2 * ns.Compat.BAND.outer, 'as wide as the bamboo frame')
	expect(ns.Tracker.GAP >= ns.Compat.PANEL.ext * ns.Compat.PANEL.stalk + 2, 'under the side stalks\' bottom ends')
	expectNear(f.edges[4].points[1][4] + f.edges[4].w - 0.5, f.w, 'top accent spans the width')
	expect(f.points[1][5] <= -12, 'clear of the corner bundle')
	expectEq(plain(f.toggle.text), 'HIDE -', 'obvious hide control')
	f.toggle.scripts.OnClick()
	expectEq(plain(f.toggle.text), 'SHOW +', 'obvious show control')
	f.toggle.scripts.OnClick()
end)

test('objective tracker 0.7.0: separated quest groups, clear hierarchy, bounded height, mouse-wheel scrolling', function()
	local TR = ns.Tracker
	local f = BanzaiTracker
	TR:Update()
	expectEq(#f.groups, 3, 'one group per quest')
	local g1 = f.groups[1]
	expectEq(plain(g1.title.text), 'The Bamboo Path', 'quest title first')
	expectEq(g1.title.text.fontSize, TR.SIZES.title, 'title size')
	expect(TR.SIZES.title > TR.SIZES.objective, 'titles larger than objectives')
	local tc = g1.title.text.textColor
	expect(math.max(tc[1], tc[2], tc[3]) > 0.9, 'title bright (the focused quest in the Banzai accent)')
	expectEq(f.groups[3].title.text.textColor[1], ns.Tracker.COLORS.title[1], 'other titles warm bright')
	expect(g1.separator.shown and g1.separator.h == 1, 'a thin separator line under the title')
	expectEq(g1.separator.gradient[3].a, 0, 'gradient line fading out (the Details accent language)')
	local titleY, sepY, objY = -g1.title.points[1][5], -g1.separator.points[1][5], -g1.objectives[1].points[1][5]
	expect(titleY < sepY and sepY < objY, 'title, then the line, then the objectives')
	expectEq(#g1.objectives, 2, 'its objectives')
	expect(f.groups[2].top >= g1.bottom + TR.SPACING.group, 'clear space before the next quest')
	expectEq(plain(f.groups[2].objectives[1].text), 'Ready to turn in', 'a finished quest says so')
	-- hierarchy inside an objective
	local function state(text, finished) return select(2, TR.ObjectiveText({ text = text, finished = finished })) end
	expectEq(state('Bamboo gathered: 3/5'), 'progress', 'under way')
	expectEq(state('0/20 Armor Scraps'), 'idle', 'not started')
	expectEq(state('5/5 Use Cyclone, Mighty Bash, or Entangling Roots'), 'done', 'complete')
	expectEq(state('Meet Astalor Bloodsworn near the harbor', true), 'done', 'finished objective')
	expectEq(state('Area explored 45%'), 'progress', 'percent progress')
	local text = TR.ObjectiveText({ text = '3/5 Ember of Power' })
	expectEq(HK_Plain(text), '3/5 Ember of Power', 'text kept as written')
	local hexOf = function(t, part) return string.match(t, '|cff(%x%x%x%x%x%x)' .. part) end
	expectEq(hexOf(text, '3/5'), Theme:Hex(TR.COLORS.progress), 'progress in light green')
	expectEq(hexOf(text, 'Ember'), Theme:Hex(TR.COLORS.text), 'description light neutral')
	local optional = TR.ObjectiveText({ text = '0/1 Journey to Gate of the Serpent\'s Eye (Optional)' })
	expectEq(hexOf(optional, '%(Optional%)'), Theme:Hex(TR.COLORS.muted), '(Optional) subdued')
	expectEq(hexOf(TR.ObjectiveText({ text = '5/5 Done thing' }), '5/5'), Theme:Hex(TR.COLORS.done), 'complete in clear green')
	expectEq(plain(g1.objectives[1].text), '- Bamboo gathered: 3/5', 'drawn in the tracker')
	-- bounded: from its top down to the Details frame, then it scrolls
	local watches = {}
	for i, id in ipairs(HK_WATCHES) do watches[i] = id end
	for id = 400, 430 do
		HK_QUESTS[id] = { title = 'Quest ' .. id, objectives = { { text = '0/3 Things to do', finished = false }, { text = 'A long description of what to do next', finished = false } } }
		HK_WATCHES[#HK_WATCHES + 1] = id
	end
	local details = ns.Compat.detailsFrame
	f.rect = { 1720, 500, f.w, 300 }        -- top edge at 800
	details.rect = { 1430, 40, 493, 161 }   -- Details frame top at 201
	TR:Update()
	expect(f.h <= 800 - 201 - TR.CLEARANCE + 1e-6, 'never reaches the Details frame (' .. f.h .. ')')
	expect(f.h <= TR.MAX_HEIGHT, 'within its maximum')
	expect(f.overflow > 0, 'more content than room')
	expectEq(f.scroll.clips, true, 'clipped: nothing bleeds below the panel')
	expectEq(f.scroll.scrollChild, f.body, 'the objectives scroll')
	expectEq(f.wheel, true, 'mouse wheel on while it overflows')
	expect(f.thumb.shown and f.track.shown, 'slim position bar')
	expectEq(f.track.w, 2, 'subtle (2 wide), no giant scrollbar')
	local thumbStart = f.thumb.points[1][5]
	f.scripts.OnMouseWheel(f, -1)
	expectEq(f.offset, TR.STEP, 'wheel down: scrolls one step')
	expectEq(f.scroll.verticalScroll, TR.STEP, 'the scroll frame moves')
	expect(f.thumb.points[1][5] < thumbStart, 'the position bar follows')
	for _ = 1, 300 do f.scripts.OnMouseWheel(f, -1) end
	expectEq(f.offset, f.overflow, 'stops at the end')
	f.scripts.OnMouseWheel(f, 1)
	expectEq(f.offset, f.overflow - TR.STEP, 'wheel up')
	for _ = 1, 300 do f.scripts.OnMouseWheel(f, 1) end
	expectEq(f.offset, 0, 'stops at the top')
	-- HIDE / SHOW kept
	TR:SetCollapsed(true)
	expectEq(f.h, 26, 'collapsed: the title row only')
	expectEq(f.wheel, false, 'no scrolling while collapsed')
	expectEq(f.thumb.shown, false, 'no position bar')
	TR:SetCollapsed(false)
	-- little content: no scrolling, no bar, height follows the content
	for i = #HK_WATCHES, 1, -1 do HK_WATCHES[i] = nil end
	for i, id in ipairs(watches) do HK_WATCHES[i] = id end
	TR:Update()
	expectEq(f.overflow, 0, 'fits')
	expectEq(f.wheel, false, 'wheel left to the camera')
	expectEq(f.thumb.shown, false, 'no position bar')
	expectNear(f.h, TR.HEADER + f.content + TR.PADDING, 'as tall as its content')
	f.rect, details.rect = nil, nil
end)

test('identity circles: Fabled spec icon when the spec is known, class icon otherwise, nothing for NPCs, never a guessed spec', function()
	local I = ns.Identity
	local focus = ElvUF_Focus
	HK_UNITS.focus, HK_UNITS.arena1, HK_UNITS.boss1 = 'MAGE', 'PRIEST', 'WARRIOR'
	HK_NPC.boss1 = true
	HK_JI_SPECS.party1 = 264      -- known (the game's inspect data through Jiberish Icons)
	HK_ARENA_SPECS[1] = 257       -- the game's arena data
	I:Refresh()
	local cf, cp, ca, cb = I:Get('ElvUF_Focus'), I:Get('ElvUF_PartyGroup1UnitButton2'), I:Get('ElvUF_Arena1'), I:Get('ElvUF_Boss1')
	expect(cp.shown and cp.isSpec, 'party: spec known -> Fabled spec icon')
	expectEq(cp.icon.path, JI_SPEC, 'Jiberish Fabled Specializations')
	expectEq(cp.spec, 264, 'its own spec')
	expect(ca.shown and ca.isSpec and ca.spec == 257, 'arena enemy: spec from the arena data')
	expect(cf.shown and not cf.isSpec, 'focus: spec not known -> class icon')
	expectEq(cf.icon.path, JI_CLASS, 'Jiberish Fabled Class')
	expectEq(cf.spec, nil, 'no spec invented')
	expectEq(cb.shown, false, 'NPC boss: no circle')
	-- look and place: small, crisp, left of the frame on the health bar (0.9.0: right of arena enemies, mirrored)
	for _, pair in ipairs({ { cf, focus }, { cp, party2 }, { ca, arena1 } }) do
		local c, frame = pair[1], pair[2]
		local mirrored = (frame == arena1)
		expectEq(c.points[1][1] .. c.points[1][3], mirrored and 'LEFTRIGHT' or 'RIGHTLEFT', frame.name .. (mirrored and ': outside the frame\'s right end' or ': outside the frame\'s left end'))
		expectEq(c.points[1][2], frame.Health, frame.name .. ': centred on the health bar')
		expectEq(c.w, I.SIZE, 'small')
		expect(I.SIZE * 3 < 105, 'far smaller than the Player / Target anchors')
		expectNear(c.ring.w, I.SIZE * 64 / 36, 'ring drawn for its pixels (36 px circle, 64 px canvas)')
		expectEq(c.ring.snap, true, 'on the pixel grid')
		expectEq(c.icon.filter, 'TRILINEAR', 'icon sheet filtered smoothly')
		expectEq(c.icon.masks[1], c.mask, 'icon inside the circular mask')
	end
	local shaman = Theme:ClassColor('SHAMAN')
	expect(math.abs(cp.ring.gradient[3].b - (shaman[3] + (1 - shaman[3]) * 0.3)) < 1e-6, 'ring in the unit\'s class colour')
	-- the player itself: the client's own spec
	HK_UNITS.party1, party2.unit = 'DRUID', 'player'
	I:Refresh()
	expectEq(cp.spec, 103, 'player: its own spec from the client (Feral)')
	party2.unit = 'party1'
	HK_UNITS.party1 = 'SHAMAN'
	-- without Jiberish Icons: the game's class icon
	local JI = JiberishIcons
	JiberishIcons = nil
	I:Refresh()
	expect(string.find(cp.icon.path, 'UI-CHARACTERCREATE-CLASSES', 1, true), 'class fallback without Jiberish Icons')
	expectEq(cp.icon.coords[1], CLASS_ICON_TCOORDS.SHAMAN[1], 'the right class')
	expectEq(cp.isSpec, false, 'no spec art without Jiberish Icons')
	JiberishIcons = JI
	-- arena frames only hold players (UnitIsPlayer may be secret there)
	HK_NPC.arena1 = true
	I:Refresh()
	expect(ca.shown, 'arena enemy shown although UnitIsPlayer says no')
	HK_NPC.arena1 = nil
	-- arena preparation: no unit yet, the game names the spec (when it is not secret)
	HK_UNITS.arena1 = nil
	HK_ARENA_SPECS[1] = 254
	I:Refresh()
	expect(ca.shown and ca.class == 'HUNTER' and ca.spec == 254, 'prep frame: class and spec from the arena data')
	HK_ARENA_SPECS[1] = nil
	I:Refresh()
	expectEq(ca.shown, false, 'prep frame without spec data: nothing guessed')
	HK_UNITS.arena1, HK_ARENA_SPECS[1] = 'PRIEST', 257
	-- an unknown spec stays unknown
	HK_JI_SPECS.party1 = nil
	I:Refresh()
	expectEq(cp.isSpec, false, 'spec gone: class icon')
	-- off in the options
	ns.Compat:Set('identityCircles', false)
	expectEq(cp.shown or cf.shown or ca.shown, false, 'all hidden when off')
	ns.Compat:Set('identityCircles', true)
	expectEq(cp.shown, true, 'back')
	HK_UNITS.focus, HK_UNITS.arena1, HK_UNITS.boss1, HK_NPC.boss1, HK_ARENA_SPECS[1] = nil, nil, nil, nil, nil
end)

test('cast history: centred, lower, gradient lines, own casts, hidden IDs listed unread, bounded', function()
	local CH = ns.CastHistory
	local f = BanzaiCastHistory
	expectEq(f.shown, true, 'on by default')
	expectEq(f.points[1][1], 'TOP', 'centred ...')
	expectEq(f.points[1][3], 'BOTTOM', '... horizontally')
	expectEq(f.points[1][4], 0, 'between Player and Target')
	expect(f.points[1][5] < 253 and f.points[1][5] > 200, 'below the player cast bar / frames')
	expect(f.points[1][5] - CH.HEADER - CH.ROW * CH.SHOWN_MAX >= 78 + 30, 'above the circular action bars (0.6.0 at the default panel: bar 1 top 108) even with 6 rows')
	expectEq(#f.lines, 2, 'a line on each side')
	expectEq(f.lines[1].points[1][2], f.header, 'left line beside the heading')
	expectEq(f.lines[1].h, 1, 'thin')
	expectEq(f.lines[1].gradient[2].a, 0, 'fades out at the outer end')
	expectEq(f.lines[2].gradient[3].a, 0, 'both sides')
	expectEq(f.header.shown, false, 'nothing listed yet: no heading')
	HK_Fire('UNIT_SPELLCAST_START', 'player', 'g1', 5221)
	expectEq(plain(f.rows[1].text), 'Shred', 'cast start listed')
	expectEq(f.rows[1].state.text, '...', 'casting marker')
	expectEq(f.header.shown, true, 'heading with its lines')
	expectEq(plain(f.header), 'CAST HISTORY', 'heading')
	HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'g1', 5221)
	expectEq(#CH:Entries(), 1, 'same cast, not doubled')
	expectEq(f.rows[1].state.text, '', 'completed')
	HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'g2', 1822)
	expectEq(plain(f.rows[1].text), 'Rake', 'instant: newest on top')
	HK_Fire('UNIT_SPELLCAST_FAILED', 'player', 'g3', 106830)
	expectEq(#CH:Entries(), 2, 'failed attempts are not added')
	local secret = issecretvalue
	issecretvalue = function(v) return v == 'SECRET' end
	HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'SECRET', 'SECRET')
	HK_Fire('UNIT_SPELLCAST_FAILED', 'player', 'SECRET', 'SECRET')
	issecretvalue = secret
	expectEq(#CH:Entries(), 3, 'a completed cast with a hidden ID is listed')
	expectEq(CH:Entries()[1].hidden, true, 'marked hidden (never compared or read)')
	expectEq(f.rows[1].text.text, 'Hidden Spell', 'name passed straight to the text')
	expectEq(f.rows[1].icon.path, 4242, 'icon passed straight to the texture')
	HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'target', 'g5', 5221)
	issecretvalue = function(v) return v == 'HIDDENUNIT' end
	CH:OnEvent('UNIT_SPELLCAST_SUCCEEDED', 'HIDDENUNIT', 'g8', 1822) -- hidden unit argument: no error, still the player's cast
	issecretvalue = secret
	expectEq(plain(f.rows[1].text), 'Rake', 'listed with a hidden unit argument')
	table.remove(CH:Entries(), 1)
	HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'g6', 99999)
	expectEq(#CH:Entries(), 3, 'other units and unknown spells ignored')
	for i = 1, 12 do HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'h' .. i, 5221) end
	expectEq(#CH:Entries(), CH.MAX, 'bounded')
	local shown = 0
	for _, row in ipairs(f.rows) do if row.shown then shown = shown + 1 end end
	expectEq(shown, 4, 'default four entries')
	expectEq(#f.rows, 6, 'at most six rows')
	expectEq(f.rows[1].text.fontSize, 12, 'newest most prominent')
	expect(f.rows[1].alpha > f.rows[2].alpha and f.rows[2].alpha > f.rows[4].alpha, 'older entries fade')
	ns.Compat:Set('castHistory', false)
	expectEq(f.shown, false, 'can be switched off')
	ns.Compat:Set('castHistory', true)
end)

test('action buttons: perfect circles, thick ring, no background, round proc halo', function()
	local AB = ns.ActionButtons
	ns.Compat:Set('actionStyle', 'CIRCLE') -- 1.2.0: Banzai Circles, an option now
	expectEq(AB.count, 12, 'the main cluster (bar 1) is circular')
	local b1, b10, b11, b12 = buttons[1], buttons[10], buttons[11], buttons[12]
	local parts = AB:Get(b1)
	expectEq(b1.w, b1.h, 'square button: the circle is never squashed (ElvUI size from the profile)')
	-- 0.7.0: ring and mask drawn for the screen pixels they cover (64 px canvas, 40 px circle)
	expectNear(parts.pixels, 30 * 0.71 * 1440 / 768, 'the button covers 39.9 screen pixels at Darren\'s setup')
	expect(string.find(parts.mask.path, 'BanzaiButtonMask', 1, true) and not string.find(parts.mask.path, '128', 1, true), 'true circular mask, the 40 px set')
	expectEq(parts.mask.points[1][1], 'CENTER', 'canvas centred on the button')
	expectEq(parts.mask.points[1][2], b1, 'on the button')
	expectNear(parts.mask.w, 30 * 64 / 40, 'canvas sized so one texel lands on one screen pixel')
	expectNear(parts.mask.w * 0.71 * 1440 / 768, 63.9, 'about 64 screen pixels for the 64 px canvas')
	expectEq(parts.mask.wrapH, 'CLAMPTOBLACKADDITIVE', 'nothing outside the canvas')
	for _, t in ipairs({ parts.mask, parts.ring }) do
		expectEq(t.filter, 'TRILINEAR', 'mip levels at any other scale')
		expectEq(t.snap, true, 'on the pixel grid')
		expectEq(t.texelBias, 0, 'no texel snapping')
	end
	expectEq(b1.icon.masks[1], parts.mask, 'icon masked')
	expectEq(b1.icon.coords, nil, 'icon texcoords left to ElvUI (picture not cropped further)')
	for _, overlay in ipairs({ b1.highlightTexture, b1.pushedTexture, b1.checkedTexture }) do
		expectEq(overlay.masks[1], parts.mask, 'square overlays follow the circle')
	end
	expect(string.find(b1.cooldown.swipe, 'BanzaiButtonCircle', 1, true), 'cooldown swipe clipped to the circle')
	expect(string.find(parts.ring.path, 'BanzaiButtonRing', 1, true), 'thick ring')
	expectEq(parts.ring.points[1][2], b1, 'ring centred on the button')
	expectEq(parts.ring.w, parts.mask.w, 'same canvas as the mask')
	-- buttons drawn larger (another scale / 4K) take the 128 px set
	buttons[2].effectiveScale = 1.4
	AB:Refresh()
	local big = AB:Get(buttons[2])
	expect(string.find(big.ring.path, 'BanzaiButtonRing128', 1, true), 'large button: 128 px set (' .. big.pixels .. ' px)')
	expectNear(big.ring.w, 30 * 128 / 80, '128 px canvas for an 80 px circle')
	buttons[2].effectiveScale = 0.71
	AB:Refresh()
	expect(not string.find(AB:Get(buttons[2]).ring.path, '128', 1, true), 'back to the 64 px set')
	-- ElvUI resizes the buttons (its options): the circle follows on the next action-bar update
	b1.w, b1.h = 36, 36
	HK_Fire('ACTIONBAR_UPDATE_COOLDOWN')
	HK_RunTimers()
	expectNear(parts.mask.w, 36 * 64 / 40, 'mask refitted to the new button size')
	expectNear(parts.ring.w, 36 * 64 / 40, 'ring too')
	b1.w, b1.h = 30, 30
	HK_Fire('UI_SCALE_CHANGED')
	HK_RunTimers()
	expectNear(parts.ring.w, 30 * 64 / 40, 'and back (also on a UI scale change)')
	expectEq(parts.glass, nil, 'no background layer behind the icon')
	expectEq(parts.notch, nil, 'no clipped-circle notch')
	expectEq(b1.Center.alpha, 0, 'no square backdrop')
	expectEq(b1.TopEdge.alpha, 0, 'no square border')
	-- 0.6.0: the black square came from ElvUI's transparent template (opaque black); cleared through ElvUI's own overrides
	expectEq(b1.customBackdropAlpha, 0, 'ElvUI keeps the backdrop transparent when it re-colours its templates')
	expectEq(b1.backdropColor[4], 0, 'backdrop colour alpha 0')
	expectEq(b1.forcedBorderColors[4], 0, 'border forced transparent')
	b1.Center:SetAlpha(1) -- ElvUI restyles a button ...
	HK_Fire('ACTIONBAR_SLOT_CHANGED')
	HK_RunTimers()
	expectEq(b1.Center.alpha, 0, '... the next action-bar update clears it again')
	expect(green(parts.ring.gradient[2]), 'first ring starts green')
	expect(purple(AB:Get(b12).ring.gradient[3]), 'last ring ends purple: green -> purple across the cluster')
	expect(not is(parts.ring.gradient[2], { parts.ring.gradient[3].r, parts.ring.gradient[3].g, parts.ring.gradient[3].b }), 'each ring is a gradient')
	expectEq(parts.ring.alpha, 1, 'ring full on a used slot')
	expectEq(AB:Get(b11).ring.alpha, AB.EMPTY_ALPHA, 'empty slot: only a faint ring')
	expectEq(AB:Get(square), nil, 'square bars (bar 3) keep ElvUI square buttons')
	-- proc: round halo on the circle, rounded-square halo on a square button, pulsing
	HK_Fire('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW', 5003)
	HK_OVERLAYED[1822] = true
	HK_RunTimers()
	local glow = AB:GetGlow(buttons[3])
	expect(glow and glow.shown, 'proc halo shown')
	expect(string.find(glow.path, 'BanzaiButtonGlow', 1, true) and not string.find(glow.path, 'Square', 1, true), 'round halo on a circle')
	expectEq(glow.w, glow.h, 'round')
	expectNear(glow.w, 30 * AB.GLOW_SCALE, 'around the circle')
	expectEq(glow.blend, 'ADD', 'bright')
	expect(glow.animationGroup.playing, 'pulsing')
	expectEq(AB:GetGlow(buttons[4]) and AB:GetGlow(buttons[4]).shown or false, false, 'only the highlighted spell')
	local sq = AB:GetGlow(square)
	expect(sq and sq.shown and string.find(sq.path, 'BanzaiButtonGlowSquare', 1, true), 'square button: rounded-square halo')
	HK_Fire('SPELL_ACTIVATION_OVERLAY_GLOW_HIDE', 5003)
	HK_OVERLAYED[1822] = nil
	HK_RunTimers()
	expectEq(glow.shown, false, 'halo off with the proc')
	expectEq(glow.animationGroup.playing, false, 'pulse stopped')
	expectEq(b10.HotKey.text, '10', 'keybind text untouched (ElvUI places it)')
	-- ELVUI style, combat, back
	ns.Compat:Set('actionStyle', 'ELVUI')
	expectEq(#b1.icon.masks, 0, 'ELVUI: circle removed')
	expectEq(b1.Center.alpha, 1, 'ELVUI: ElvUI backdrop back')
	expectEq(b1.customBackdropAlpha, nil, 'ELVUI: ElvUI colours its backdrop again')
	expectEq(b1.forcedBorderColors, nil, 'ELVUI: ElvUI border colour again')
	expectEq(parts.ring.shown, false, 'ring hidden')
	HK_IN_COMBAT = true
	ns.Compat:Set('actionStyle', 'CIRCLE')
	expectEq(#b1.icon.masks, 0, 'nothing changes in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(b1.icon.masks[1], parts.mask, 'applied after combat')
	expectEq(#b1.icon.masks, 1, 'mask added once')
	ns.Compat:Set('actionStyle', 'SQUARE')
end)

test('unit-frame preview: every type, labelled samples, current styling, no secure units', function()
	local P = ns.Preview
	expectEq(ns.Compat.Preview, P, 'reachable from the options page')
	expectEq(#P.TYPES, 10, 'player, target, ToT, focus, pet, party, raid, arena allies / enemies, boss')
	expectEq(P:ShowAll(), true, 'SHOW ALL')
	expectEq(P:IsShown('cooldowns'), true, '0.9.0: SHOW ALL includes the cooldown bars')
	local expected = { player = 1, target = 1, targettarget = 1, focus = 1, pet = 1, party = 5, raid = 20, arenaAllies = 3, arenaEnemies = 3, boss = 4 }
	for _, key in ipairs(P.TYPES) do
		local c = P:Get(key)
		expect(c and c.shown, key .. ' shown')
		expectEq(#c.units, expected[key], key .. ' frames')
		expectEq(c.strata, 'DIALOG', key .. ' above the real frames')
		expectEq(c.kind, 'Frame', key .. ' plain frame (not a secure unit button)')
		for _, u in ipairs(c.units) do
			expectEq(u.kind, 'Frame', 'plain frame')
			expect(string.find(u.Health.statusTexture, 'BanzaiBar', 1, true), 'smooth Banzai health texture')
			expect(u.trough and u.trough.gradient, 'dark trough')
			expect(u.healthText, 'health number + percent inside the bar')
			expect(u.healthText.ghost.value.text ~= nil and u.healthText.bright.percent.text ~= nil, 'texts set')
		end
	end
	-- 0.9.0: party and arena allies (the same frames in the game) both shown: the allies just above the party
	local party, allies = P:Get('party'), P:Get('arenaAllies')
	expectEq(allies.stacked, true, 'arena allies stacked')
	expectEq(allies.points[1][2], party, 'above the party')
	expectEq(allies.points[1][1] .. allies.points[1][3], 'BOTTOMLEFTTOPLEFT', 'left edges in line')
	expect(allies.points[1][5] >= 40, 'clear of the party title and icons')
	expect(string.find(plain(allies.title), 'SHOWN ABOVE PARTY (SAME PLACE IN THE GAME)', 1, true), 'and says so')
	local function names(key) local out = {} for _, u in ipairs(P:Get(key).units) do out[#out + 1] = u.sample.label end return table.concat(out, ',') end
	expectEq(names('party'), 'PARTY 1,PARTY 2,PARTY 3,PARTY 4,PARTY 5', 'party labels')
	expectEq(names('arenaEnemies'), 'ENEMY 1,ENEMY 2,ENEMY 3', 'enemy labels')
	expectEq(names('arenaAllies'), 'ALLY 1,ALLY 2,ALLY 3', 'ally labels')
	expectEq(names('boss'), 'BOSS 1,BOSS 2,BOSS 3,BOSS 4', 'boss labels')
	expectEq(P:Get('player').units[1].sample.label, 'PLAYER PREVIEW', 'player label')
	-- identity order and spec text
	local p1 = party.units[1]
	expect(string.find(HK_Plain(p1.name.text), '^PARTY 1 %- '), 'party: NAME - SPEC')
	local e1 = P:Get('arenaEnemies').units[1]
	expect(string.find(HK_Plain(e1.name.text), ' %- ENEMY 1$'), 'enemies: SPEC - NAME')
	expectEq(HK_Plain(P:Get('boss').units[1].name.text), 'BOSS 1', 'boss: name only')
	expectEq(HK_Plain(P:Get('player').units[1].name.text), 'PLAYER PREVIEW - FERAL', "player: the player's own spec")
	-- states: full, partial, low; class colours; no party resource bar (as live: Bushido's party has none)
	local levels = {}
	for _, u in ipairs(party.units) do levels[#levels + 1] = u.Health.value end
	expectEq(levels[1], 1, 'full')
	expect(levels[3] < 0.6 and levels[3] > 0.4, 'partial')
	expect(levels[5] < 0.1, 'low')
	expectEq(plain(p1.healthText.bright.percent), '100%', 'percentage')
	expectEq(plain(p1.healthText.bright.value), '520K', 'health number')
	expectEq(p1.Power, nil, 'party: no resource bar (live has none)')
	expect(P:Get('player').units[1].Power, 'player: resource bar')
	expect(party.units[1].sample.color ~= party.units[2].sample.color, 'different class colours')
	-- geometry: player on the real frame; DPS party 100 wide at full height on the left edge, aligned with the raid
	expectEq(player.alpha, 0, 'real Player frame faded out under its preview (alpha only)')
	local pc = P:Get('player')
	expectEq(pc.points[1][4], 411, 'player preview on the real frame (x)')
	expectEq(pc.w, 302, 'real frame width')
	expectEq(P:Get('player').units[1].Health.w, 300, 'real health bar width')
	expectEq(party.points[1][1], 'BOTTOMLEFT', 'party mover point')
	expectEq(party.points[1][4], 54, 'party mover x (left edge)')
	local raid = P:Get('raid')
	expectEq(party.points[1][4] - 27 - 4, raid.points[1][4], 'DPS party: the identity circles start where the raid frames start')
	expectEq(p1.w, 100, 'DPS: half of Bushido\'s width')
	expectEq(p1.h, 39, 'DPS: full height')
	expectEq(party.units[2].points[1][5], -(39 + 19), 'party growth down with the profile spacing')
	-- bamboo only on Player / Target
	expect(P:Get('player').units[1].bundle and P:Get('player').units[1].bundle.isBundle, 'player end bundle')
	expect(P:Get('target').units[1].bundle and P:Get('target').units[1].bundle.isBundle, 'target end bundle')
	for _, key in ipairs({ 'targettarget', 'focus', 'pet', 'party', 'raid', 'arenaAllies', 'arenaEnemies', 'boss' }) do
		for i, u in ipairs(P:Get(key).units) do expectEq(u.bundle, nil, key .. ' ' .. i .. ': no bamboo') end
	end
	-- CLASS / SPEC CIRCLE | HEALTH BAR (role icon in its right end) | TRINKET CIRCLE; enemies mirrored
	for _, key in ipairs({ 'focus', 'party', 'arenaAllies', 'arenaEnemies' }) do
		local mirrored = (key == 'arenaEnemies')
		for i, u in ipairs(P:Get(key).units) do
			local c = u.circle
			expect(c and c.shown, key .. ' ' .. i .. ': identity circle')
			expectEq(c.icon.path, JI_SPEC, key .. ' ' .. i .. ': Fabled spec icon of the sample spec')
			expectEq(c.points[1][1] .. c.points[1][3], mirrored and 'LEFTRIGHT' or 'RIGHTLEFT', key .. ' ' .. i .. (mirrored and ': right of the frame' or ': left of the frame'))
			expectEq(c.points[1][2], u.Health, 'centred on the health bar')
			expect(c.w < 105 / 3, 'much smaller than the Player / Target anchors (' .. c.w .. ')')
			if key ~= 'focus' then
				local t = u.trinket
				expect(t and t.shown, key .. ' ' .. i .. ': trinket circle')
				expectEq(t.w, c.w, 'the trinket circle matches the identity circle')
				expectEq(t.points[1][1] .. t.points[1][3], mirrored and 'RIGHTLEFT' or 'LEFTRIGHT', key .. ' ' .. i .. (mirrored and ': trinket left' or ': trinket right'))
				expectEq(t.points[1][4], mirrored and -4 or 4, 'the same gap as the identity circle')
				expect(string.find(tostring(t.icon.path), 'Trinket', 1, true) or type(t.icon.path) == 'number', 'the PvP medallion')
			end
		end
	end
	for _, key in ipairs({ 'targettarget', 'pet', 'boss', 'raid' }) do expectEq(P:Get(key).units[1].circle, nil, key .. ': no circle') end
	expectEq(party.units[1].circle.spec, P.SAMPLE_SPEC_IDS.PALADIN, 'holy paladin sample: its spec')
	-- inside the bar: HP + % from the left end, the role icon at the right end
	for _, key in ipairs({ 'focus', 'party', 'arenaAllies', 'arenaEnemies', 'boss' }) do
		local u = P:Get(key).units[1]
		expectEq(u.healthText.bright.value.points[1][1], 'LEFT', key .. ': value from the bar\'s left end')
		expect(plain(u.healthText.bright.value) ~= '' and plain(u.healthText.bright.percent) ~= '', key .. ': value + percent')
	end
	for i, u in ipairs(party.units) do
		expect(u.roleIcon and string.find(u.roleIcon.path, 'PORTRAITROLES', 1, true), 'party ' .. i .. ': role icon')
		expectEq(u.roleIcon.points[1][1] .. u.roleIcon.points[1][3], 'RIGHTRIGHT', 'party ' .. i .. ': inside the bar\'s right end')
		expectEq(u.roleIcon.points[1][2], u.Health, 'in the bar')
		for _, gone in ipairs({ 'offensive', 'defensive', 'friendlyDefensive', 'dr' }) do expectEq(u[gone], nil, 'party ' .. i .. ': no ' .. gone .. ' (no ordinary aura clutter, no DR)') end
	end
	expectEq(party.units[1].sample.role, 'HEALER', 'a holy paladin shows the healer icon')
	-- NORMAL: one dispellable effect, a member out of range
	local d = party.units[2]
	expectEq(d.dispelType, 'Magic', 'dispellable debuff sample')
	expect(d.dispel.shown and d.debuff.shown, 'dispel border and compact icon')
	expectEq(d.debuff.points[1][1] .. d.debuff.points[1][3], 'TOPRIGHTBOTTOMRIGHT', 'the icon below the frame\'s right end (clear of HP and name)')
	expectEq(plain(d.dispel.label), 'DISPEL', 'DISPEL label')
	expectEq(party.units[5].alpha, P.RANGE_ALPHA, 'out-of-range member faded')
	for _, u in ipairs(raid.units) do expectEq(u.bundle, nil, 'no bamboo on raid frames') end
	expectEq(raid.units[1].healthText.bright.value.text, '', 'raid compact: percent only')
	expectEq(raid.units[1].name.points[1][2], raid.units[1].Health, 'raid: name inside the bar')
	expectEq(raid.units[7].alpha, P.RANGE_ALPHA, 'raid range state')
	local enemies = P:Get('arenaEnemies')
	expectEq(enemies.points[1][1] .. enemies.points[1][4] .. ',' .. enemies.points[1][5], 'BOTTOMRIGHT-54,362', 'enemies on the right edge at the allies\' level')
	expectEq(enemies.units[1].w .. 'x' .. enemies.units[1].h, '100x39', 'enemies: the allies\' size')
	for i, u in ipairs(enemies.units) do
		expectEq(u.dr, nil, 'enemy ' .. i .. ': no DR slots any more')
		expectEq(u.cast.points[1][1] .. u.cast.points[1][3], 'BOTTOMLEFTTOPLEFT', 'enemy ' .. i .. ': cast bar above the frame, as live')
	end
	expect(enemies.units[1].cast.shown, 'cast bar readable')
	expectEq(plain(enemies.units[1].targetMark.label), 'TARGET', 'current target marked')
	expectEq(plain(enemies.units[2].focusMark.label), 'FOCUS', 'focus marked')
	expectEq(enemies.units[1].targetMark.label.points[1][2], enemies.units[1].Health, 'marker label inside the bar (the cast bar is above)')
	expect(P:Get('boss').units[1].cast.shown, 'boss cast bar')
	expect(string.find(plain(party.title), 'DPS LAYOUT', 1, true), 'labelled with the layout shown')
	-- HEALER layout without a spec change: the central row, the DPS width, 30 % lower; enemies on the right at its level
	expectEq(P:SetRole('HEALER'), 'HEALER', 'HEALER layout chosen')
	party = P:Get('party')
	expect(party.shown, 'party rebuilt in the HEALER arrangement and shown')
	expectEq(party.points[1][1] .. party.points[1][3], 'BOTTOMBOTTOM', 'bottom centre of the screen')
	expectEq(party.points[1][4], 0, 'centred (circle left, trinket right)')
	expectEq(party.points[1][5], 472, 'above the lower centre')
	for i = 2, #party.units do
		expectEq(party.units[i].points[1][5], 0, 'HEALER ' .. i .. ': same row')
		expectEq(party.units[i].points[1][4], (i - 1) * (100 + 70), 'HEALER ' .. i .. ': side by side, room for both circles between')
	end
	expectEq(party.units[1].w .. 'x' .. party.units[1].h, '100x27', 'HEALER: DPS width, 30 % lower')
	expect(party.units[2].circle.shown and party.units[2].trinket.shown, 'circles kept in the row')
	allies = P:Get('arenaAllies')
	expect(allies.shown and allies.stacked, 'the HEALER arena allies row above the party row')
	expectEq(allies.points[1][1] .. allies.points[1][3], 'BOTTOMTOP', 'centred above it')
	expectEq(allies.units[1].h, 27, 'matching the party')
	enemies = P:Get('arenaEnemies')
	expectEq(enemies.points[1][5], 472, 'enemies at the row\'s level')
	expectEq(enemies.units[1].h, 27, 'enemies: the HEALER size')
	expect(string.find(plain(party.title), 'HEALER LAYOUT', 1, true), 'title follows')
	expectEq(raid.points[1][4], 560, 'raid moved too')
	local healerParty = party
	expectEq(P:SetRole('DPS'), 'DPS', 'DPS again')
	expectEq(P:Get('party').points[1][4], 54, 'party back at the DPS position')
	P:SetRole('HEALER')
	expectEq(P:Get('party'), healerParty, 'switching again reuses the HEALER container (nothing piles up)')
	P:SetRole('DPS')
	expect(P:Get('party').units[2].points[1][5] < 0, 'and a column again')
	-- the arena allies go back to their own place when the party preview is hidden
	P:Show('party', false)
	expectEq(P:Get('arenaAllies').stacked, nil, 'allies alone: their own place')
	expectEq(P:Get('arenaAllies').points[1][4], 54, 'the DPS arena allies place')
	-- combat hides everything; nothing can be shown in combat
	HK_IN_COMBAT = true
	HK_Fire('PLAYER_REGEN_DISABLED')
	for _, key in ipairs(P.TYPES) do expectEq(P:IsShown(key), false, key .. ' hidden in combat') end
	expectEq(P:IsShown('cooldowns'), false, 'cooldown bar preview hidden in combat')
	expectEq(P:Show('party', true), false, 'refused in combat')
	expectEq(P:IsShown('party'), false, 'still hidden')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(P:Show('raid', true), true, 'single type on')
	expectEq(P:IsShown('raid'), true, 'raid shown')
	P:HideAll()
	expectEq(P:AnyShown(), false, 'HIDE ALL')
	expectEq(player.alpha, 1, 'real Player frame back')
end)

test('unit-frame preview 0.9.0: names above the bars, every PvP state synthetic and labelled, CC / dispel / trinket design', function()
	local P = ns.Preview
	P:SetRole('DPS')
	P:SetState('NORMAL')
	P:ShowAll()
	local party, enemies, raid = P:Get('party'), P:Get('arenaEnemies'), P:Get('raid')
	local focus, boss, tot = P:Get('focus'), P:Get('boss'), P:Get('targettarget')
	-- layering: names and spec text on a layer above fill, track, gradients and the inside health text
	for _, key in ipairs({ 'player', 'focus', 'party', 'raid', 'arenaEnemies', 'boss' }) do
		local u = P:Get(key).units[1]
		expectEq(u.name.parent, u.textLayer, key .. ': name on the text layer')
		expect(u.textLayer.level > u.Health.level, key .. ': above the health fill')
		if u.healthText then expect(u.textLayer.level > u.healthText.clip.level, key .. ': above the inside health text') end
	end
	-- the selector: 14 synthetic states (1.3.0: + CHANNELING; 1.3.3: + INTERRUPTED), kept with the Banzai settings, named in every title
	expectEq(#P.STATES, 16, 'NORMAL ... TRINKET UNKNOWN')
	for _, label in ipairs({ 'ALLY CC\'D', 'ENEMY CC\'D', 'DISPELLABLE', 'OFFENSIVE ACTIVE', 'DEFENSIVE ACTIVE', 'TRINKET AVAILABLE', 'TRINKET USED', 'TRINKET UNKNOWN' }) do
		local found = false
		for _, state in ipairs(P.STATES) do if P.STATE_LABELS[state] == label then found = true end end
		expect(found, 'state ' .. label)
	end
	expectEq(P.STATE_LABELS.DR, nil, 'no DR state any more')
	local function title(c) return plain(c.title) end
	for _, state in ipairs(P.STATES) do
		expectEq(P:SetState(state), state, state .. ' chosen')
		expectEq(Theme:DB().previewState, state, state .. ' kept')
		for _, key in ipairs({ 'party', 'raid', 'arenaEnemies', 'boss' }) do
			expect(string.find(title(P:Get(key)), 'PREVIEW: ' .. P.STATE_LABELS[state] .. '  -  SAMPLE DATA', 1, true), key .. ' titled ' .. state)
		end
		expectEq(enemies.units[1].targetMark.shown and not enemies.units[1].focusMark.shown, true, state .. ': enemy 1 TARGETED')
		expectEq(enemies.units[2].focusMark.shown and not enemies.units[2].targetMark.shown, true, state .. ': enemy 2 FOCUSED')
		expectEq(enemies.units[3].targetMark.shown and enemies.units[3].focusMark.shown, true, state .. ': enemy 3 TARGETED + FOCUSED')
	end
	expectEq(P:NextState(), 'NORMAL', 'NEXT STATE wraps around')
	expectEq(P:NextState(), 'LOW_HEALTH', 'NEXT STATE')
	P:SetState('DEAD')
	expectEq(plain(party.units[2].dead), 'Dead', 'dead (oUF\'s [status] word)')
	expectEq(plain(raid.units[11].dead), 'Offline', 'raid offline')
	-- ALLY CC'D: unmistakable - a large icon in the bar, a magenta border, a bold CC label; long, short and no duration
	P:SetState('CC_ALLY')
	for i = 1, 3 do
		local u = party.units[i]
		expect(u.cc.shown and u.ccBorder.shown and u.ccBorder.label.shown, 'ally ' .. i .. ': CC icon, border and label')
		expectEq(plain(u.ccBorder.label), 'CC', 'the CC label')
		expectEq(u.cc.points[1][2], u.Health, 'the icon inside the bar')
	end
	expectEq(plain(party.units[1].cc.text), '8.0', 'a long CC')
	expectEq(plain(party.units[2].cc.text), '1.4', 'a short CC')
	expectEq(plain(party.units[3].cc.text), '', 'no duration from the game: none shown')
	expect(party.units[1].ccBorder.pulse.playing, 'STRONG: a restrained pulse')
	local magenta = party.units[1].ccBorder.edges[1].color
	expect(magenta[1] > 0.9 and magenta[2] < 0.3, 'magenta: never a health colour')
	expectEq(party.units[1].Health.value, 1, 'health untouched: CC is not low health')
	expect(not enemies.units[1].cc.shown, 'enemies not in ALLY CC\'D')
	-- emphasis levels
	Theme:DB().ccEmphasis = 'CLEAR'
	P:SetState('CC_ALLY')
	expect(party.units[1].ccBorder.label.shown and not party.units[1].ccBorder.pulse.playing, 'CLEAR: border and label, no pulse')
	expectEq(party.units[1].ccBorder.edges[1].h, 2, 'CLEAR: thinner border')
	Theme:DB().ccEmphasis = 'MINIMAL'
	P:SetState('CC_ALLY')
	expect(party.units[1].cc.shown and not party.units[1].ccBorder.label.shown and not party.units[1].ccBorder.edges[1].shown, 'MINIMAL: the icon alone')
	Theme:DB().ccEmphasis = 'STRONG'
	-- ENEMY CC'D: over the identity circle, visible, smaller than the allies' CC, the cast bar left free
	P:SetState('CC_ENEMY')
	local ecc = enemies.units[2].cc
	expect(ecc.shown and enemies.units[2].ccBorder.shown, 'enemy CC icon and border')
	expectEq(ecc.points[1][2], enemies.units[2].circle, 'in place of the identity circle')
	expect(ecc.w < party.units[1].cc.w, 'smaller than the friendly CC')
	expectEq(plain(enemies.units[3].cc.text), '', 'enemy CC without duration')
	expect(focus.units[1].cc.shown, 'focus CC')
	expect(not party.units[1].cc.shown, 'allies not in ENEMY CC\'D')
	-- DISPELLABLE
	P:SetState('DISPELLABLE')
	expect(party.units[2].dispel.shown and party.units[2].debuff.shown and party.units[2].dispel.label.shown, 'dispel border, icon and label')
	local cyan = party.units[2].dispel.edges[1].color
	expect(cyan[3] > 0.9 and cyan[1] < 0.3, 'cyan border')
	expectEq(raid.units[3].dispel.edges[1].h, 1, 'raid: thinnest')
	Theme:DB().dispelEmphasis = 'MINIMAL'
	P:SetState('DISPELLABLE')
	expect(party.units[2].debuff.shown and not party.units[2].dispel.label.shown, 'MINIMAL: the icon alone')
	Theme:DB().dispelEmphasis = 'STRONG'
	-- OFFENSIVE / DEFENSIVE ACTIVE: enemy buffs left of the trinket, and the cooldown bars
	P:SetState('OFFENSIVE')
	expect(enemies.units[1].offensive.shown, 'enemy burst')
	expectEq(enemies.units[1].offensive.points[1][2], enemies.units[1].trinket, 'left of the trinket circle')
	local bars = ns.CooldownBars
	expect(bars:IsPreview(), 'cooldown bar preview on (SHOW ALL)')
	expect(string.find(plain(bars:Get('offensive').title), 'ACTIVE  -  SAMPLE DATA', 1, true), 'offensive bars: ACTIVE, SAMPLE DATA')
	P:SetState('DEFENSIVE')
	expect(enemies.units[2].defensive.shown, 'enemy defensive')
	expect(string.find(plain(bars:Get('defensive').title), 'ACTIVE', 1, true), 'defensive bars: ACTIVE')
	-- trinkets: AVAILABLE / USED / UNKNOWN, never a timer
	P:SetState('TRINKET_READY')
	for _, u in ipairs(enemies.units) do expectEq(u.trinket.state, 'READY', 'available') end
	expect(not party.units[1].trinket.icon.desaturated, 'available: full colour')
	P:SetState('TRINKET_USED')
	expectEq(party.units[1].trinket.state, 'USED', 'used')
	expectEq(party.units[2].trinket.state, 'READY', 'another member still has it')
	expect(party.units[1].trinket.icon.desaturated, 'used: greyed')
	P:SetState('TRINKET_UNKNOWN')
	expectEq(enemies.units[1].trinket.state, 'UNKNOWN', 'unknown')
	expect(enemies.units[1].trinket.icon.alpha < 1, 'unknown: dimmed')
	for _, u in ipairs(party.units) do expect(not string.find(plain(u.trinket.cd.text or ''), '%d'), 'no timer') end
	P:SetState('NORMAL')
	-- boss: health, name, cast; no PvP slots
	for _, key in ipairs({ 'trinket', 'targetMark', 'offensive', 'cc' }) do expectEq(boss.units[1][key], nil, 'boss: no ' .. key) end
	expectEq(plain(tot.units[1].healthText.bright.value), '', 'ToT: percent only')
	for _, u in ipairs(raid.units) do expectEq(u.circle, nil, 'raid: no circle') end
	expectEq(raid.units[1].roleIcon.w, 10, 'raid: small role icon')
	-- settings follow: role icons, trinket circles
	Theme:DB().roleIcons, Theme:DB().trinketCircles = false, false
	P:SetState('NORMAL')
	expect(not party.units[1].roleIcon.shown and not party.units[1].trinket.shown, 'role icon and trinket circle off')
	Theme:DB().roleIcons, Theme:DB().trinketCircles = true, true
	P:SetState('NORMAL')
	expect(party.units[1].roleIcon.shown and party.units[1].trinket.shown, 'and on again')
	-- HEALER: the CC icon fits the lower bar
	P:SetRole('HEALER')
	P:SetState('CC_ALLY')
	local hp = P:Get('party')
	expect(hp.units[1].cc.w <= hp.units[1].h - 4, 'HEALER: CC icon fits (' .. hp.units[1].cc.w .. ')')
	P:SetRole('DPS')
	-- the PvP sets: PARTY + ARENA (party, allies above it, enemies)
	P:HideAll()
	expectEq(P:ShowArenaSet(), true, 'PARTY + ARENA')
	expectEq(P:IsShown('party') and P:IsShown('arenaAllies') and P:IsShown('arenaEnemies'), true, 'party, arena allies and arena enemies')
	expectEq(P:Get('arenaAllies').stacked, true, 'allies above the party, not on top of it')
	expect(P:Get('arenaAllies').units[1].arenaAccent, 'arena allies: violet arena accent')
	expectEq(P:Show('cooldowns', true), true, 'COOLDOWN BARS')
	expect(bars:Get('offensive').shown and bars:Get('defensive').shown, 'both bar groups')
	P:SetState('NORMAL')
	P:HideAll()
	expectEq(bars:IsPreview(), false, 'HIDE ALL ends the bar preview')
end)

test('PvP frames 0.9.0: trinket circles from the game\'s arena data (never a timer), mirrored for enemies, target / focus, CC / dispel parts on ElvUI\'s own aura icons', function()
	local PV = ns.PvPFrames
	party2.unitframeType, arena1.unitframeType = 'party', 'arena'
	HK_UNITS.party1, HK_UNITS.arena1 = 'SHAMAN', 'PRIEST'
	HK_INSTANCE = 'none'
	PV:Refresh()
	local pe, ae = PV:Get('ElvUF_PartyGroup1UnitButton2'), PV:Get('ElvUF_Arena1')
	expect(pe and ae, 'built for party and arena frames')
	expectEq(pe.trinket.points[1][1] .. pe.trinket.points[1][3], 'LEFTRIGHT', 'party: right of the bar')
	expectEq(pe.trinket.points[1][2], party2.Health, 'on the health bar')
	expectEq(ae.trinket.points[1][1] .. ae.trinket.points[1][3], 'RIGHTLEFT', 'arena enemy: left of the bar (mirrored)')
	expectEq(pe.trinket.w, ns.Identity.SIZE, 'the identity circle\'s diameter')
	expectEq(pe.trinket.cd.swipe, PV.SWIPE, 'a round cooldown swipe')
	expectEq(pe.trinket.state, 'UNKNOWN', 'outside an arena: unknown')
	HK_INSTANCE = 'arena'
	HK_TRINKETS.party1, HK_TRINKETS.arena1 = 0, 95
	PV:Refresh()
	expectEq(pe.trinket.state, 'READY', 'the game: no cooldown -> AVAILABLE')
	expect(not pe.trinket.icon.desaturated, 'full colour')
	expectEq(ae.trinket.state, 'USED', 'the game: cooling down -> USED')
	expect(ae.trinket.cd.shown and ae.trinket.cd.durationObject, 'the game\'s own duration on the swipe')
	expect(ae.trinket.icon.desaturated, 'greyed')
	expectEq(pe.trinket.cd.hideNumbers, true, 'no countdown text drawn')
	HK_TRINKETS.party1 = nil
	PV:Refresh()
	expectEq(pe.trinket.state, 'UNKNOWN', 'nothing from the game: unknown, nothing guessed')
	Theme:DB().trinketCircles = false
	PV:Refresh()
	expectEq(pe.trinket.shown, false, 'trinket circles off')
	Theme:DB().trinketCircles = true
	-- target / focus on the enemy frames, only when the game answers plainly
	local unitIsUnit = UnitIsUnit
	UnitIsUnit = function(a, b) return (a == 'target' and b == 'arena1') end
	HK_Fire('PLAYER_TARGET_CHANGED')
	expect(ae.target.shown and not ae.focus.shown, 'arena1 targeted')
	UnitIsUnit = function(a, b) if a == 'focus' and b == 'arena1' then return 'SECRET' end return false end
	local isSecret = issecretvalue
	issecretvalue = function(v) return v == 'SECRET' end
	HK_Fire('PLAYER_FOCUS_CHANGED')
	expect(not ae.target.shown and not ae.focus.shown, 'a secret answer: no marker')
	issecretvalue, UnitIsUnit = isSecret, unitIsUnit
	HK_TRINKETS.arena1, HK_INSTANCE = nil, 'none'
	-- CC / dispel parts rode on ElvUI's own aura icons (0.9.0 - 1.3.3); 1.3.4: retired - nothing is made on them
	local function Element(frame, which)
		local container = { parent = frame, auraType = which, buttons = {} }
		local key = (which == 'auras') and 'Auras' or (which == 'debuffs') and 'Debuffs' or 'Buffs'
		frame[key] = container
		local b = HK_NewFrame('Button', nil, UIParent)
		b.container = container
		container.buttons[b] = container
		return b
	end
	local ccIcon, dispelIcon, enemyCC = Element(party2, 'auras'), Element(party2, 'debuffs'), Element(arena1, 'debuffs')
	local buffIcon = HK_NewFrame('Button', nil, UIParent)
	buffIcon.container = { parent = party2, auraType = 'buffs', buttons = {} }
	HK_Fire('UNIT_AURA', 'party1')
	HK_RunTimers()
	PV:Refresh()
	for _, icon in ipairs({ ccIcon, dispelIcon, enemyCC, buffIcon }) do
		expectEq(PV.Decorate(icon), nil, '1.3.4: Decorate is a no-op')
		expectEq(#HK_Descendants(icon), 0, '1.3.4: nothing made on ElvUI\'s aura icons (the CC / dispel parts are retired)')
	end
end)

test('cooldown bars 0.9.0: the player\'s own major cooldowns, shown only while cooling down, bounded, honest, configurable', function()
	local CB = ns.CooldownBars
	CB:SetPreview(false)
	HK_KNOWN = { [102560] = true, [194223] = true, [391528] = true, [205636] = true, [202770] = true, [5217] = true, [22812] = true, [108238] = true }
	HK_COOLDOWNS = {}
	Theme:DB().cdTracked = false
	CB:Refresh()
	local off, def = CB:Get('offensive'), CB:Get('defensive')
	expectEq(off.shown or def.shown, false, 'nothing cooling down: no empty groups on screen')
	local candidates = CB:Candidates('offensive')
	expectEq(candidates[1], 102560, 'a talent variant counts once (Incarnation for Celestial Alignment)')
	for _, id in ipairs(candidates) do expect(id ~= 194223, 'not both variants') end
	expectEq(#CB:Tracked('offensive'), 5, 'Banzai\'s selection: the first five known')
	-- one cooling down
	HK_COOLDOWNS[391528] = { active = true, remaining = 42 }
	CB:Refresh()
	expect(off.shown, 'the offensive group appears')
	local bar = off.bars[1]
	expect(bar.shown and bar.spellID == 391528, 'its bar')
	expectEq(bar.time.text, '42', 'the game\'s remaining time, formatted only')
	expectEq(bar.status.timer[3], Enum.StatusBarTimerDirection.RemainingTime, 'the bar runs down with the game\'s duration')
	expect(not off.bars[2].shown, 'one bar only')
	expectEq(def.shown, false, 'defensive group still empty')
	-- the global cooldown and secret states never make a bar
	HK_COOLDOWNS[205636] = { active = true, gcd = true, remaining = 1 }
	local isSecret = issecretvalue
	issecretvalue = function(v) return v == 'SECRET' end
	HK_COOLDOWNS[202770] = { active = 'SECRET', remaining = 30 }
	CB:Refresh()
	expectEq(off.count, 1, 'GCD and secret states: no bar')
	-- in combat the remaining time itself can be secret: the font string formats it, Lua never compares it
	HK_COOLDOWNS[391528].remaining = 'SECRET'
	CB:Refresh()
	expectEq(off.bars[1].time.text, 'SECRET', 'a secret remaining time handed to the widget as it is')
	expectEq(off.bars[1].time.formatArgs[1], 'SECRET', 'formatted by the font string')
	HK_COOLDOWNS[391528].remaining = 42
	issecretvalue = isSecret
	-- bounded
	for _, id in ipairs({ 102560, 205636, 202770, 5217 }) do HK_COOLDOWNS[id] = { active = true, remaining = 60 } end
	CB:Refresh()
	expectEq(off.count, 5, 'five at once at most')
	Theme:DB().cdOffensiveCount = 2
	CB:Refresh()
	expectEq(off.count, 2, 'the count setting')
	Theme:DB().cdOffensiveCount = 5
	-- the tracked selection (per class, synced with the Banzai settings)
	CB:SetTracked(391528, false)
	expect(type(Theme:DB().cdTracked.DRUID) == 'table' and Theme:DB().cdTracked.DRUID[391528] == false, 'saved per class')
	for _, b in ipairs(off.bars) do expect(b.spellID ~= 391528, 'untracked: never a bar') end
	expectEq(Theme:Export().cdTracked.DRUID[391528], false, 'Character Sync carries the selection')
	CB:SetTracked(391528, true)
	-- defensive group on the other side
	HK_COOLDOWNS[22812] = { active = true, remaining = 20 }
	CB:Refresh()
	expect(def.shown and def.bars[1].spellID == 22812, 'defensive bar')
	expectEq(off.points[1][1] .. off.points[1][3], 'BOTTOMBOTTOM', 'anchored to the screen bottom')
	expect(off.points[1][4] < -250 and def.points[1][4] > 250, 'offensive left of the action bars, defensive right of them')
	expectEq(off.points[1][4], -def.points[1][4], 'mirrored around the centre')
	expect(off.points[1][5] > (Theme:DB().barHeight or 32), 'above the bottom panel')
	expect(off.h <= CB.MAX * (CB.BAR.h + CB.BAR.gap), 'bounded height')
	Theme:DB().cdScale, Theme:DB().cdOpacity = 2, 0.1
	CB:Refresh()
	expectEq(off.scale, 1.2, 'scale bounded')
	expectEq(off.alpha, 0.4, 'opacity bounded')
	Theme:DB().cdScale, Theme:DB().cdOpacity = 1, 1
	-- switched off
	Theme:DB().cdBars = false
	CB:Refresh()
	expectEq(off.shown or def.shown, false, 'cooldown bars off')
	Theme:DB().cdBars = true
	-- the preview: labelled sample bars, never in combat
	CB:SetPreview(true)
	expect(off.shown and string.find(plain(off.title), 'SAMPLE DATA', 1, true), 'sample bars, labelled')
	expect(off.bars[2].alpha < 1, '(the preview dims its second bar)')
	CB:SetPreview(false)
	for _, id in ipairs({ 391528, 102560 }) do HK_COOLDOWNS[id] = { active = true, remaining = 30 } end
	CB:Refresh()
	expectEq(off.bars[2].alpha, 1, 'real bars at full opacity after a preview')
	CB:SetPreview(true)
	HK_IN_COMBAT = true
	HK_Fire('PLAYER_REGEN_DISABLED')
	HK_RunTimers()
	expectEq(CB:IsPreview(), false, 'combat ends the preview')
	HK_IN_COMBAT = false
	HK_COOLDOWNS = {}
	CB:Refresh()
	expectEq(off.shown, false, 'empty again')
	expectEq(HK_FindString(CB, 'COMBAT_LOG'), nil, 'no combat log')
end)

test('targeted enemy nameplate: class / reaction gradient over the fill, health + percent inside, others untouched', function()
	local TP = ns.TargetPlate
	local function Plate(kind)
		local uf = HK_NewFrame('Frame', nil, UIParent)
		uf.frameType = kind
		uf.Health = HK_NewFrame('StatusBar', nil, uf)
		uf.Health.level = 10
		uf.Health.Text = uf.Health:CreateFontString() -- ElvUI's own health text
		return { unitFrame = uf }, uf
	end
	local enemyPlate, enemy = Plate('ENEMY_PLAYER')
	HK_PLATES.target = enemyPlate
	HK_UNITS.target = 'MAGE'
	HK_Fire('PLAYER_TARGET_CHANGED')
	HK_RunTimers()
	local deco = TP:Get(enemy)
	expect(deco, 'targeted enemy player decorated')
	expectEq(deco.overlay.allPoints, enemy.Health.fill, 'gradient follows the health fill exactly')
	local g = deco.overlay.gradient
	expectEq(g[1], 'HORIZONTAL', 'smooth horizontal gradient')
	expect(g[3].b > g[3].r and g[3].g > g[3].r, 'mage: class colour (blue family)')
	expect(g[2].b < g[3].b, 'deep -> bright')
	expectEq(deco.overlay.shown, true, 'shown')
	local tags = {}
	for _, t in ipairs(enemy.tags) do tags[t[2]] = (tags[t[2]] or 0) + 1 end
	expectEq(tags[ns.Health.VALUE_TAG], 2, 'current health through ElvUI tags (no value read here)')
	expectEq(tags[ns.Health.PERCENT_TAG], 2, 'percentage too')
	expectEq(deco.health.holder.parent, enemy.Health, 'inside the bar')
	expectEq(deco.health.bright.value.points[1][1], 'LEFT', 'value at the left end')
	expectEq(deco.health.bright.percent.points[1][1], 'RIGHT', 'percent at the right end')
	expectEq(deco.health.clip.allPoints, enemy.Health.fill, 'bright over the fill, ghosted over the empty bar')
	expectEq(enemy.Health.Text.alpha, 0, 'ElvUI health text steps aside on the target plate')
	-- an NPC: reaction colours
	local npcPlate, npc = Plate('ENEMY_NPC')
	HK_PLATES.target = npcPlate
	HK_REACTION.target = 2
	HK_Fire('PLAYER_TARGET_CHANGED')
	HK_RunTimers()
	expectEq(deco.overlay.shown, false, 'the previous target plate goes back to plain ElvUI')
	expectEq(deco.health.holder.shown, false, 'with its texts')
	expectEq(enemy.Health.Text.alpha, 1, 'ElvUI health text back')
	local npcDeco = TP:Get(npc)
	local ng = npcDeco.overlay.gradient[3]
	expect(ng.r > 0.9 and ng.g < 0.4, 'hostile NPC: red reaction gradient')
	HK_REACTION.target = 4
	TP:Update()
	expect(npcDeco.overlay.gradient[3].g > 0.7 and npcDeco.overlay.gradient[3].b < 0.4, 'neutral NPC: amber')
	-- friendly plates and the setting
	local friendPlate, friend = Plate('FRIENDLY_PLAYER')
	HK_PLATES.target = friendPlate
	TP:Update()
	expectEq(TP:Get(friend), nil, 'friendly target: nothing added')
	expectEq(npcDeco.overlay.shown, false, 'previous one cleared')
	HK_PLATES.target = enemyPlate
	ns.Compat:Set('targetPlate', false)
	expectEq(deco.overlay.shown, false, 'switched off in the options')
	ns.Compat:Set('targetPlate', true)
	expectEq(deco.overlay.shown, true, 'and on again')
	HK_PLATES.target, HK_REACTION.target = nil, nil
	TP:Update()
end)

test('CLASS mode and gradient direction; bamboo toggle', function()
	expectEq(ns.Compat:SetTheme('class'), true, 'switch')
	local bundle = byPart(player, 'BushidoEndPoint')
	for _, s in ipairs(bundle.stalks) do expect(orange(s.texture.gradient[2]), 'orange family') end
	expectEq(ns.Compat:SetTheme('VIBRANT'), true, 'back to vibrant')
	-- 1.1.0: the frame theme and gradient direction belong to the unit frames, the bar and the tracker; the panels follow PANEL STYLE
	ns.Compat:Set('gradient', 'REVERSE')
	expect(green(piece(ns.Compat.minimapFrame, 'top', 0.1).texture.gradient[2]), 'the panel bamboo keeps its own style (BANZAI greens)')
	ns.Compat:Set('gradient', 'FORWARD')
	ns.Compat:Set('bambooArt', false)
	expectEq(byPart(player, 'BushidoEndPoint').shown, false, 'end bundles off')
	expectEq(ns.Compat.chatFrame.pieceCount > 0 and ns.Compat.chatFrame.pieces[1].texture.shown, true, 'the panel frames are not bundles: they stay')
	ns.Compat:Set('bambooArt', true)
	expectEq(ns.Compat:Set('nonsense', 1), false, 'unknown setting refused')
end)

test('art only shows on the Banzai profile', function()
	HK_ElvData.current = 'HARDKORHUI'
	ns.Compat.RefreshAll(ns.Compat)
	expectEq(byPart(player, 'BushidoEndPoint').shown, false, 'end art hidden')
	expectEq(ns.Compat.chatFrame.shown, false, 'chat glass hidden')
	expectEq(BanzaiLogo.shown, false, 'logo hidden')
	expectEq(ns.Compat.detailsFrame.shown, false, 'Details frame hidden')
	expectEq(#buttons[1].icon.masks, 0, 'ElvUI action buttons as they were')
	expectEq(buttons[1].Center.alpha, 1, 'ElvUI backdrop back')
	expectEq(Minimap.mask, 130937, 'ElvUI\'s square minimap mask back')
	expectEq(BanzaiCombatLogo.shown, false, 'no combat logo')
	HK_ElvData.current = NAME
	ns.Compat.RefreshAll(ns.Compat)
	expectEq(byPart(player, 'BushidoEndPoint').shown, true, 'shown again')
	expectEq(#buttons[1].icon.masks, 1, 'Banzai buttons again')
end)

test('combat queue: frames that appear in combat are decorated after it', function()
	expectEq(ns.Compat.mascots, nil, 'no mascots')
	local late = Frame('ElvUF_PartyGroup1UnitButton3', 'party2')
	HK_IN_COMBAT = true
	HK_Fire('GROUP_ROSTER_UPDATE')
	expectEq(#HK_Children(late), 0, 'not built in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	local kinds = {}
	for _, h in ipairs(HK_Children(late)) do kinds[h.artKind or 'other'] = (kinds[h.artKind or 'other'] or 0) + 1 end
	expectEq(kinds.trough, 1, 'built after combat: the smooth trough')
	expectEq(kinds['end'], nil, 'no bamboo on party frames (0.7.0)')
	HK_RunTimers()
	expect(ns.Identity:Get('ElvUF_PartyGroup1UnitButton3'), 'and its identity circle')
end)

test('no duplicate frames after repeated builds and theme switches', function()
	local before = ns.Compat:Counts()
	local screen = #HK_Children(UIParent)
	ns.Compat:Build()
	ns.Compat:Build()
	ns.Compat:SetTheme('CLASS')
	ns.Compat:SetTheme('VIBRANT')
	ns.ActionButtons:Refresh()
	local after = ns.Compat:Counts()
	expectEq(after.holders, before.holders, 'same art frames')
	expectEq(after.bands, before.bands, 'same bands')
	expectEq(#HK_Children(player), 3, 'still three on the player frame')
	expectEq(#HK_Children(UIParent), screen, 'Details, chat, logos, bundles, accents, bar, tracker, cast history built once')
	expectEq(#buttons[1].icon.masks, 1, 'one mask per icon')
end)

---------------------------------------------------------------------------
-- 1.0.0
---------------------------------------------------------------------------
test('1.0.0 narrow frames: plates and bamboo keep their place against their own frame end', function()
	local spike = byPart(player, 'BushidoEndPoint')
	expectEq(spike.points[1][2], player, 'on the Player frame')
	local tspike = byPart(target, 'BushidoEndPoint')
	expectEq(tspike.points[1][1] .. tspike.points[1][3], 'CENTERLEFT', 'target: on its inner (left) end')
	expectNear(tspike.points[1][4], -156.01 + 151, 'mirrored')
	local plate = byPart(player, 'WHITE')
	expectEq(#plate.points, 2, 'the plate spans the frame between its two insets')
	expectEq(plate.points[1][1] .. plate.points[1][3] .. plate.points[2][1] .. plate.points[2][3], 'LEFTLEFTRIGHTRIGHT', 'anchored to both ends')
	expectNear(plate.points[1][4], (-9.01 - 305 / 2) + 151, 'left inset as in Bushido (10.5 outside the end)')
	expectNear(plate.points[2][4], (-9.01 + 305 / 2) - 151, 'right inset as in Bushido (7.5 short of the end)')
	local totPlate = byPart(tot, 'WHITE')
	expectEq(#totPlate.points, 2, 'Target-of-Target plate spans its (narrow) frame too')
	-- a frame without a design width (raid, boss): on its centre as before
	local region = HK_NewFrame('Frame', nil, UIParent)
	expectEq(ns.Compat.PlacePart(region, UIParent, { texture = 'WHITE', w = 100, h = 20, x = 5, y = 1 }, 1, nil), 'CENTER', 'no design width: centred')
	expectEq(ns.Compat.DESIGN_WIDTH.ElvUF_Player .. ',' .. ns.Compat.DESIGN_WIDTH.ElvUF_Focus, '302,210', 'Bushido\'s own widths')
	-- the preview draws them the same way
	ns.Preview:Show('player', true)
	local u = ns.Preview:Get('player').units[1]
	expectEq(u.bundle.points[1][3], 'RIGHT', 'preview: the bamboo at the inner end too')
	ns.Preview:HideAll()
end)

test('1.0.0 spec on its own line: [banzai:spec]; health text closer to the class circle on the narrow bars', function()
	expect(HK_TAGS['banzai:spec'], '[banzai:spec] registered with ElvUI')
	expectEq(HK_Plain(HK_TAGS['banzai:spec'].fn('player')), 'FERAL', 'the spec alone, Banzai gradient')
	expectEq(HK_TAGS['banzai:spec'].fn('boss1'), nil, 'NPC: nothing')
	local def = ns.Health.UNITS[1]
	expectEq(ns.Health.X(def), 14, 'half width (BANZAI 1.0): 14 from the left end')
	Theme:DB().frameWidth = 1
	expectEq(ns.Health.X(def), 34, 'full width: Bushido\'s 34')
	Theme:DB().frameWidth = 0.5
end)

test('1.0.0 BANZAI wordmark: a left click opens the settings on HOME; invisible padded click area, hover glow and tooltip, never in combat', function()
	local logo, button = BanzaiLogo, BanzaiLogoButton
	expectEq(button.parent, logo, 'part of the wordmark')
	expectEq(#(button.textures or {}), 0, 'no visible button background')
	expectEq(logo.mouse, false, 'the wordmark itself unchanged')
	local pad = ns.Compat.LOGO_CLICK.pad
	expectEq(button.points[1][1] .. button.points[1][4] .. ',' .. button.points[1][5], 'TOPLEFT' .. -pad .. ',' .. pad, 'a little larger than the letters')
	expectEq(button.points[2][1] .. button.points[2][4] .. ',' .. button.points[2][5], 'BOTTOMRIGHT' .. pad .. ',' .. -pad, 'on every side')
	expectEq(logo.h .. ',' .. logo.points[1][4], '24,0', 'size and place unchanged')
	local opened = {}
	BanzaiOpenSettings = function(page) opened[#opened + 1] = page return true end
	button.scripts.OnClick(button, 'LeftButton')
	expectEq(opened[1], 'home', 'left click: BANZAI > HOME')
	button.scripts.OnClick(button, 'LeftButton')
	expectEq(#opened, 2, 'every click asks for the same window (an open one is reused)')
	button.scripts.OnClick(button, 'RightButton')
	expectEq(#opened, 2, 'right click: nothing')
	HK_IN_COMBAT, HK_PRINTS = true, {}
	button.scripts.OnClick(button, 'LeftButton')
	expectEq(#opened, 2, 'in combat nothing opens (and nothing is queued)')
	expect(string.find(HK_PRINTS[1] or '', 'cannot open in combat', 1, true), 'a one-line message instead')
	HK_IN_COMBAT = false
	BanzaiOpenSettings = nil
	HK_PRINTS = {}
	button.scripts.OnClick(button, 'LeftButton')
	expect(string.find(HK_PRINTS[1] or '', 'not loaded', 1, true), 'without the Banzai addon: says so')
	-- hover
	button.scripts.OnEnter(button)
	expectEq(logo.glow.shown, true, 'a touch brighter')
	expectEq(logo.glow.blend, 'ADD', '(the same letters added on top)')
	expect(GameTooltip.shown and GameTooltip:IsOwned(button), 'tooltip')
	expect(string.find(HK_TipText(GameTooltip), 'Open Banzai Settings', 1, true), '"Open Banzai Settings"')
	expectEq(GameTooltip.points[1][1] .. GameTooltip.points[1][3], 'TOPBOTTOM', 'below the wordmark')
	button.scripts.OnLeave(button)
	expectEq(logo.glow.shown, false, 'back')
	expectEq(GameTooltip.shown, false, 'tooltip gone')
	button.scripts.OnEnter(button)
	button.scripts.OnHide(button) -- combat hides the wordmark under the mouse
	expectEq(GameTooltip.shown, false, 'no stuck tooltip')
	expectEq(logo.glow.shown, false, 'no stuck glow')
	-- in combat the wordmark is hidden (the small one), the large one is never clickable
	ns.Compat.inCombat = true
	ns.Compat:UpdateBranding()
	expectEq(logo.shown, false, 'small wordmark hidden in combat')
	expectEq(BanzaiCombatLogo.mouse, false, 'the combat wordmark and tree take no clicks')
	ns.Compat.inCombat = false
	ns.Compat:UpdateBranding()
	expectEq(logo.shown, true, 'back after combat')
end)

test('1.3.8 launcher host: the small wordmark steps aside while BanzaiSland hosts the BANZAI SLAND launcher; the saved logo preference is never written; both load orders; release', function()
	local logo = BanzaiLogo
	local db = Theme:DB()
	expectEq(type(BanzaiCompat.SetLauncherHost), 'function', 'public: BanzaiCompat.SetLauncherHost')
	expectEq(ns.Compat.launcherHost, nil, 'no host to begin with')
	-- A. BANZAI only, logo ON
	ns.Compat:Set('logo', true)
	expectEq(logo.shown, true, 'A: BANZAI only, saved logo ON -> standalone visible')
	-- B. BANZAI only, logo OFF
	ns.Compat:Set('logo', false)
	expectEq(logo.shown, false, 'B: BANZAI only, saved logo OFF -> standalone hidden')
	ns.Compat:Set('logo', true)
	-- C. both, logo ON: push (BanzaiSland calls SetLauncherHost when its wordmark appears)
	BanzaiCompat.SetLauncherHost('BanzaiSland')
	expectEq(logo.shown, false, 'C: hosted -> standalone hidden at once')
	expectEq(db.logo, true, 'C: the saved preference is still ON (never written)')
	expectEq(ns.Compat.launcherHost, 'BanzaiSland', 'the host is named')
	expectEq(BanzaiCombatLogo.shown, false, 'the combat wordmark is not involved out of combat')
	-- D. both, logo OFF: hidden either way, preference untouched
	ns.Compat:Set('logo', false)
	expectEq(logo.shown, false, 'D: hosted + saved OFF -> hidden')
	expectEq(db.logo, false, 'D: preference still OFF')
	-- E. host released, logo ON -> the standalone returns
	ns.Compat:Set('logo', true)
	BanzaiCompat.SetLauncherHost(nil)
	expectEq(ns.Compat.launcherHost, nil, 'released')
	expectEq(logo.shown, true, 'E: host gone, saved ON -> standalone back immediately')
	-- F. host released, logo OFF -> stays hidden
	ns.Compat:Set('logo', false)
	BanzaiCompat.SetLauncherHost('BanzaiSland')
	BanzaiCompat.SetLauncherHost(nil)
	expectEq(logo.shown, false, 'F: host gone, saved OFF -> stays hidden')
	ns.Compat:Set('logo', true)
	-- the (name, on) form BanzaiSland 0.2.0 used
	BanzaiCompat.SetLauncherHost('BanzaiSland', true)
	expectEq(logo.shown, false, '(name, true) hosts')
	BanzaiCompat.SetLauncherHost('BanzaiSland', false)
	expectEq(logo.shown, true, '(name, false) releases')
	BanzaiCompat.SetLauncherHost(42)
	expectEq(ns.Compat.launcherHost, nil, 'a non-string host is a release')
	-- pull: BanzaiSland loaded first and published its API; BANZAI UI asks at every branding pass
	BanzaiSlandAPI = { HostsBanzaiLauncher = function() return true end }
	ns.Compat:UpdateBranding()
	expectEq(logo.shown, false, 'J: BanzaiSland first - the API says hosted -> standalone hidden at Build / UpdateBranding')
	BanzaiSlandAPI.HostsBanzaiLauncher = function() return false end
	ns.Compat:UpdateBranding()
	expectEq(logo.shown, true, 'the API says not hosting (blocked, failed, hidden) -> standalone back')
	BanzaiSlandAPI.HostsBanzaiLauncher = function() error('boom') end
	ns.Compat:UpdateBranding()
	expectEq(logo.shown, true, 'an erroring host answer counts as not hosting (pcall)')
	BanzaiSlandAPI = nil
	ns.Compat:UpdateBranding()
	expectEq(logo.shown, true, 'G / H: no BanzaiSland API -> the preference alone decides')
	-- I. BANZAI first: the wordmark exists, then the host claims -> hidden at once (the push above); combat passes keep it hidden
	BanzaiCompat.SetLauncherHost('BanzaiSland')
	ns.Compat.inCombat = true
	ns.Compat:UpdateBranding()
	ns.Compat.inCombat = false
	ns.Compat:UpdateBranding()
	expectEq(logo.shown, false, 'I: still hidden after a combat round trip')
	BanzaiCompat.SetLauncherHost(nil)
	expectEq(logo.shown, true, 'clean')
	-- no polling: SetLauncherHost / UpdateBranding create no timers
	local timers = #HK_TIMERS
	BanzaiCompat.SetLauncherHost('BanzaiSland')
	BanzaiCompat.SetLauncherHost(nil)
	expectEq(#HK_TIMERS, timers, 'no timers from the host handshake')
	expectEq(db.logo, true, 'the saved preference ends as it began')
end)

test('1.0.0 tooltip theme: glass, thin green -> purple edge and soft shadow on the game\'s tooltips (textures only), ELVUI hides them, scale only when changed', function()
	local Tip = ns.Tooltip
	GameTooltip.lines = { { left = 'game content' } }
	ns.Compat.RefreshAll(ns.Compat)
	local s = Tip.skins[GameTooltip]
	expect(s, 'GameTooltip skinned')
	expectEq(s.glass.layer, 'BACKGROUND', 'glass behind the text')
	expectEq(s.glass.points[1][4] .. ',' .. s.glass.points[1][5], '1,-1', 'inside ElvUI\'s 1-unit border (its quality / class colour kept)')
	expectEq(s.glass.shown, true, 'shown')
	local top = s.edges[1]
	expectEq(top.gradient[1], 'HORIZONTAL', 'top edge: one gradient')
	expect(green(top.gradient[2]) and purple(top.gradient[3]), 'green -> purple')
	expect(s.shadow[1].sublevel < s.glass.sublevel, 'the shadow under the glass')
	expect(s.shadow[1].gradient[2].a > s.shadow[1].gradient[3].a, 'the shadow fades away from the frame')
	expectEq(GameTooltip.scale, nil, 'scale untouched at 100 %')
	ns.Compat:Set('tooltipScale', 1.1)
	expectEq(GameTooltip.scale, 1.1, 'scale set once changed')
	ns.Compat:Set('tooltipScale', 1)
	expectEq(GameTooltip.scale, 1, 'and back')
	ns.Compat:Set('tooltipTheme', 'ELVUI')
	expectEq(s.glass.shown, false, 'ELVUI: no glass')
	expectEq(s.edges[1].shown, false, 'no edge')
	ns.Compat:Set('tooltipTheme', 'BANZAI')
	expectEq(s.glass.shown, true, 'BANZAI again')
	local count = #GameTooltip.textures
	ns.Compat.RefreshAll(ns.Compat)
	expectEq(#GameTooltip.textures, count, 'never built twice')
	for _, name in ipairs({ 'ItemRefTooltip', 'ShoppingTooltip1', 'ShoppingTooltip2' }) do expect(Tip.skins[_G[name]], name .. ' skinned') end
	expectEq(#GameTooltip.lines .. GameTooltip.lines[1].left, '1game content', 'the content is not touched')
end)

local function PanelItems()
	local byKey = {}
	for _, item in ipairs(BanzaiInfoBar.items) do byKey[item.def.key] = item end
	return byKey
end

local function Hover(item)
	item.scripts.OnEnter(item)
	local text = HK_TipText(GameTooltip)
	local shown = GameTooltip.shown and GameTooltip:IsOwned(item)
	item.scripts.OnLeave(item)
	return text, shown
end

test('1.0.0 bottom panel: every entry explains itself on hover (the game\'s own data, nothing invented)', function()
	local byKey = PanelItems()
	for _, key in ipairs({ 'honor', 'conquest', 'mastery', 'haste', 'versatility', 'durability', 'fps', 'ms', 'time', 'spec', 'ilvl', 'professions', 'friends', 'guild', 'gold' }) do
		local item = byKey[key]
		item.scripts.OnEnter(item)
		expect(GameTooltip.shown and GameTooltip:IsOwned(item), key .. ': tooltip shown')
		expectEq(GameTooltip.points[1][1] .. GameTooltip.points[1][3], 'BOTTOMTOP', key .. ': above the entry')
		expectEq(GameTooltip.clamped, true, key .. ': kept on screen')
		expect(not string.find(HK_TipText(GameTooltip), 'Not available right now', 1, true), key .. ': built without an error')
		item.scripts.OnLeave(item)
		expectEq(GameTooltip.shown, false, key .. ': gone again')
	end
	local honor = Hover(byKey.honor)
	for _, needle in ipairs({ 'Honor  12,345 / 15,000', 'Honor level  120', 'Toward the next level  4,200 / 5,500', 'Earned in PvP.', 'Click: open the PvP window' }) do
		expect(string.find(honor, needle, 1, true), 'honor: ' .. needle)
	end
	local conquest = Hover(byKey.conquest)
	expect(string.find(conquest, 'Earned this season  2,200', 1, true), 'season earned')
	expect(string.find(conquest, 'Seasonal cap  not reported by the game', 1, true), 'no cap invented when the game gives none')
	HK_CURRENCY[1602].maxQuantity = 2800
	conquest = Hover(byKey.conquest)
	expect(string.find(conquest, 'Seasonal cap  2,800', 1, true) and string.find(conquest, 'Still to earn  600', 1, true), 'the game\'s own cap when it has one')
	HK_CURRENCY[1602].maxQuantity = 0
	local mastery = Hover(byKey.mastery)
	expect(string.find(mastery, 'SPELL 77493', 1, true), 'the spec\'s mastery spell, explained by the game')
	expect(string.find(mastery, 'Mastery rating of 1234 adds', 1, true), 'rating explained (Blizzard\'s text)')
	local haste = Hover(byKey.haste)
	expect(string.find(haste, 'Increases attack and casting speed.', 1, true) and string.find(haste, 'Haste rating of 2345 adds', 1, true), 'haste: explanation and rating')
	local vers = Hover(byKey.versatility)
	for _, needle in ipairs({ 'Damage and healing done  +10.00%', 'Damage taken  -10.00%', 'Rating  3456', 'decreases damage taken' }) do
		expect(string.find(vers, needle, 1, true), 'versatility: ' .. needle)
	end
	local dur = Hover(byKey.durability)
	for _, needle in ipairs({ 'Head  40%', 'Chest  90%', 'Overall  65%', 'Lowest  Head  40%', 'Wearing down.' }) do expect(string.find(dur, needle, 1, true), 'durability: ' .. needle) end
	local fps = Hover(byKey.fps)
	expect(string.find(fps, 'FPS  144', 1, true) and string.find(fps, 'State  smooth', 1, true) and string.find(fps, 'no average', 1, true), 'FPS now, its meaning, no invented average')
	local ms = Hover(byKey.ms)
	for _, needle in ipairs({ 'Home  38 ms', 'World  45 ms', 'State  healthy', 'Home: your connection to the realm' }) do expect(string.find(ms, needle, 1, true), 'latency: ' .. needle) end
	local time = Hover(byKey.time)
	for _, needle in ipairs({ 'Local time', 'Realm time  9:05 PM', 'Local date', 'Realm date  27 ', 'Daily reset in  3h 20m', 'Weekly reset in  2d 1h', 'realm time is the server' }) do
		expect(string.find(time, needle, 1, true), 'time: ' .. needle)
	end
	local spec = Hover(byKey.spec)
	for _, needle in ipairs({ 'FERAL', 'Role  DAMAGER', 'Loot specialization  current (Feral)', 'Banzai frame layout  DPS', 'never changes your spec' }) do expect(string.find(spec, needle, 1, true), 'spec: ' .. needle) end
	local ilvl = Hover(byKey.ilvl)
	for _, needle in ipairs({ 'Equipped  712.6', 'Overall (best you own)  714.2', 'PvP (the game\'s PvP item level)  718.1' }) do expect(string.find(ilvl, needle, 1, true), 'item level: ' .. needle) end
	local profs = Hover(byKey.professions)
	for _, needle in ipairs({ 'Herbalism  100 / 100', 'Alchemy  100 / 100', 'Fishing  100 / 100', 'Cooking  100 / 100' }) do expect(string.find(profs, needle, 1, true), 'professions: ' .. needle) end
	expect(not string.find(profs, 'Archaeology', 1, true), 'a profession not learned is not listed')
end)

test('1.0.0 bottom panel: friends, guild and gold lists - real entries, bounded, Syndicator read only, KNOWN totals', function()
	local byKey = PanelItems()
	-- friends: Battle.net (in WoW / in the app) and character friends, at most 12 lines
	HK_BN = {
		{ accountName = 'Kenji', gameAccountInfo = { isOnline = true, clientProgram = 'WoW', characterName = 'Kenjiro', className = 'Mage', characterLevel = 80, areaName = 'Dornogal' } },
		{ accountName = 'Aiko', isAFK = true, gameAccountInfo = { isOnline = true, clientProgram = 'App' } },
		{ accountName = 'Offline', gameAccountInfo = { isOnline = false } },
	}
	HK_WOW_FRIENDS = {}
	for i = 1, 11 do HK_WOW_FRIENDS[i] = { name = 'Friend' .. i, className = 'Druid', level = 80, area = 'Azj-Kahet', connected = true } end
	HK_WOW_FRIENDS[12] = { name = 'Asleep', connected = false }
	local friends = Hover(byKey.friends)
	for _, needle in ipairs({ 'Online  13 of 15', 'Kenji  Kenjiro 80  Dornogal', 'Aiko (AFK)  Battle.net', 'Friend1  Level 80  Azj-Kahet', '+1 more', 'Click: open the friends list' }) do
		expect(string.find(friends, needle, 1, true), 'friends: ' .. needle)
	end
	expect(not string.find(friends, 'Offline', 1, true) and not string.find(friends, 'Asleep', 1, true), 'offline friends not listed')
	-- guild: online members (not mobile), capped, MOTD; the roster asked for at most every 15 s
	HK_GUILD = {
		{ 'Takeshi-Stormrage', 80, 'Dornogal', true, 0, 'WARRIOR', false },
		{ 'Yumi-Stormrage', 79, 'Hallowfall', true, 1, 'PRIEST', false },
		{ 'Gone-Stormrage', 70, 'Orgrimmar', false, 0, 'ROGUE', false },
		{ 'Phone-Stormrage', 80, '', true, 0, 'MAGE', true },
	}
	HK_ROSTER_REQUESTS, ns.Info.rosterAsked = 0, nil
	local guild = Hover(byKey.guild)
	for _, needle in ipairs({ 'Bamboo Grove', 'Your rank  Officer', 'Takeshi  Level 80  Dornogal', 'Yumi (AFK)  Level 79  Hallowfall', 'MOTD: Raid at eight.', 'Click: open the guild window' }) do
		expect(string.find(guild, needle, 1, true), 'guild: ' .. needle)
	end
	expect(not string.find(guild, 'Gone', 1, true) and not string.find(guild, 'Phone', 1, true), 'offline and mobile-only members not listed')
	Hover(byKey.guild)
	expectEq(HK_ROSTER_REQUESTS, 1, 'the roster asked for once, not on every hover')
	local saved = IsInGuild
	IsInGuild = function() return false end
	expect(string.find(Hover(byKey.guild), 'You are not in a guild.', 1, true), 'a clear unguilded state')
	IsInGuild = saved
	-- gold: this character, the session, other characters and the Warband bank from Syndicator (read only)
	ns.Info.sessionStart = 1234567890 - 250000
	Syndicator = nil
	local gold = Hover(byKey.gold)
	expect(string.find(gold, 'Darrensdrood  (this character)  123,456', 1, true), 'this character')
	expect(string.find(gold, 'This session  +25', 1, true), 'session gain')
	expect(string.find(gold, 'shown when Syndicator is installed', 1, true), 'without Syndicator: says what is missing')
	expect(string.find(gold, 'Total KNOWN  123,456', 1, true), 'total of what is known')
	local data = {
		Characters = {
			['Darrensdrood-Stormrage'] = { money = 1234567890, details = { character = 'Darrensdrood', realm = 'Stormrage', className = 'DRUID', show = { gold = true } } },
			['Alt-Stormrage'] = { money = 50000000, details = { character = 'Alt', realm = 'Stormrage', className = 'MAGE', show = { gold = true } } },
			['Hidden-Stormrage'] = { money = 999, details = { character = 'Hidden', realm = 'Stormrage', show = { gold = false } } },
		},
		Warband = { { money = 7000000 } },
	}
	Syndicator = { API = {
		IsReady = function() return true end,
		GetAllCharacters = function() local out = {} for k in pairs(data.Characters) do out[#out + 1] = k end table.sort(out) return out end,
		GetByCharacterFullName = function(name) return data.Characters[name] end,
		GetCurrentCharacter = function() return 'Darrensdrood-Stormrage' end,
		GetWarband = function(i) return data.Warband[i] end,
	} }
	gold = Hover(byKey.gold)
	expect(string.find(gold, 'OTHER CHARACTERS  (Syndicator, last seen)', 1, true), 'other characters, labelled as last seen')
	expect(string.find(gold, 'Alt  Stormrage  5,000', 1, true), 'an alt\'s gold')
	expect(not string.find(gold, 'Hidden', 1, true), 'a character hidden in Syndicator stays hidden')
	expect(not string.find(gold, 'Darrensdrood  Stormrage', 1, true), 'this character not counted twice')
	expect(string.find(gold, 'Warband bank  (Syndicator, last seen)  700', 1, true), 'Warband bank: Syndicator\'s last-seen value')
	expect(string.find(gold, 'Total KNOWN  129,156', 1, true), 'KNOWN: this character + alts + Warband bank')
	expect(string.find(gold, 'never saw', 1, true), 'never called complete')
	HK_WARBAND = 8000000
	gold = Hover(byKey.gold)
	expect(string.find(gold, 'Warband bank  (the game)  800', 1, true), 'the game\'s own Warband value when it gives one')
	HK_WARBAND = nil
	local after = 0
	for _ in pairs(data.Characters) do after = after + 1 end
	expectEq(after, 3, 'Syndicator\'s data untouched (read only)')
	expectEq(data.Characters['Alt-Stormrage'].money, 50000000, 'nothing written into it')
	Syndicator = nil
end)

test('1.0.0 bottom panel: clicks open the right window, in combat one line instead (bags excepted), settings respected', function()
	local byKey = PanelItems()
	for key, expected in pairs({ honor = 'TogglePVPUI', conquest = 'TogglePVPUI', mastery = 'ToggleCharacter(PaperDollFrame)', versatility = 'ToggleCharacter(PaperDollFrame)',
		durability = 'ToggleCharacter(PaperDollFrame)', ilvl = 'ToggleCharacter(PaperDollFrame)', time = 'ToggleCalendar', spec = 'TogglePlayerSpellsFrame(1)',
		professions = 'ToggleProfessionsBook', friends = 'ToggleFriendsFrame(1)', guild = 'ToggleGuildFrame', gold = 'ToggleAllBags' }) do
		HK_PANELS = {}
		byKey[key].scripts.OnClick(byKey[key])
		expectEq(HK_PANELS[1], expected, key .. ' opens ' .. expected)
	end
	HK_PANELS = {}
	byKey.fps.scripts.OnClick(byKey.fps)
	expectEq(#HK_PANELS, 0, 'FPS: nothing to open')
	HK_IN_COMBAT, HK_PANELS, HK_PRINTS = true, {}, {}
	byKey.honor.scripts.OnClick(byKey.honor)
	expectEq(#HK_PANELS, 0, 'in combat: the PvP window does not open')
	expect(string.find(HK_PRINTS[1] or '', 'The PvP window cannot open in combat', 1, true), 'one line says so')
	byKey.spec.scripts.OnClick(byKey.spec)
	expectEq(#HK_PANELS, 0, 'nor the specialization window')
	byKey.gold.scripts.OnClick(byKey.gold)
	expectEq(HK_PANELS[1], 'ToggleAllBags', 'bags open in combat, as usual')
	-- tooltips in combat: off unless allowed
	local _, shown = Hover(byKey.honor)
	expectEq(shown, false, 'no panel tooltip in combat by default')
	ns.Compat:Set('panelTipsCombat', true)
	_, shown = Hover(byKey.honor)
	expectEq(shown, true, 'shown in combat when chosen')
	ns.Compat:Set('panelTipsCombat', false)
	HK_IN_COMBAT = false
	-- a secret value is said to be unavailable, never shown as a number
	issecretvalue = function(v) return v == 'SECRET' end
	local savedHaste = GetHaste
	GetHaste = function() return 'SECRET' end
	local haste = Hover(byKey.haste)
	expect(string.find(haste, 'Haste  not available from the game', 1, true), 'secret: said so')
	GetHaste = savedHaste
	issecretvalue = function() return false end
	-- off, or at the cursor
	ns.Compat:Set('panelTips', false)
	_, shown = Hover(byKey.fps)
	expectEq(shown, false, 'panel tooltips can be switched off')
	ns.Compat:Set('panelTips', true)
	ns.Compat:Set('panelTipAnchor', 'CURSOR')
	byKey.fps.scripts.OnEnter(byKey.fps)
	expectEq(GameTooltip.anchorType, 'ANCHOR_CURSOR', 'at the cursor when chosen')
	byKey.fps.scripts.OnLeave(byKey.fps)
	ns.Compat:Set('panelTipAnchor', 'ITEM')
	-- FPS / MS / TIME follow once a second while hovered; combat starting hides a panel tooltip
	byKey.fps.scripts.OnEnter(byKey.fps)
	local savedFps = GetFramerate
	GetFramerate = function() return 25 end
	ns.Bar:UpdateFast()
	expect(string.find(HK_TipText(GameTooltip), 'FPS  25', 1, true) and string.find(HK_TipText(GameTooltip), 'low', 1, true), 'the FPS tooltip follows (and warns)')
	GetFramerate = savedFps
	HK_IN_COMBAT = true
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(GameTooltip.shown, false, 'combat: the panel tooltip goes')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	byKey.fps.scripts.OnLeave(byKey.fps)
end)

test('1.0.0 objectives: quest and objective tooltips beside the tracker (quest log data only), clicks unchanged', function()
	HK_SUPERTRACK = 101
	HK_QUESTS[101].objectives[1].numFulfilled, HK_QUESTS[101].objectives[1].numRequired = 3, 5
	ns.Compat:Set('trackerCollapsed', false)
	ns.Tracker:Update()
	local f = BanzaiTracker
	local title, objective, world
	for _, line in ipairs(f.lines) do
		if line.shown and line.tip then
			if line.tip.quest.id == 101 and line.tip.objective and not objective then objective = line end
			if line.tip.quest.id == 101 and not line.tip.objective then title = line end
			if line.tip.quest.id == 303 and not line.tip.objective then world = line end
		end
	end
	expect(title and objective and world, 'quest titles and objective lines carry their tooltip')
	expectEq(objective.mouse, true, 'objective lines answer the mouse (hover)')
	expectEq(objective.questID, nil, 'and still have no click action')
	title.scripts.OnEnter(title)
	local text = HK_TipText(GameTooltip)
	expectEq(GameTooltip.points[1][1] .. GameTooltip.points[1][3], 'TOPRIGHTTOPLEFT', 'left of the tracker (clear of the minimap)')
	for _, needle in ipairs({ 'The Bamboo Path', 'Level 80  -  Daily', 'Quest log  Isle of Dorn', 'Tracking  Tracked, focused', 'Objectives  1 / 2 complete', 'Left-click: focus' }) do
		expect(string.find(text, needle, 1, true), 'quest tooltip: ' .. needle)
	end
	expect(not string.find(text, 'Time left', 1, true), 'no timer when the game has none')
	title.scripts.OnLeave(title)
	expectEq(GameTooltip.shown, false, 'gone')
	objective.scripts.OnEnter(objective)
	text = HK_TipText(GameTooltip)
	for _, needle in ipairs({ 'Bamboo gathered: 3/5', 'Progress  3 / 5', 'Objective  In progress' }) do expect(string.find(text, needle, 1, true), 'objective tooltip: ' .. needle) end
	objective.scripts.OnLeave(objective)
	world.scripts.OnEnter(world)
	text = HK_TipText(GameTooltip)
	for _, needle in ipairs({ 'World Quest', 'Zone  Isle of Dorn', 'Tracking  Tracked (world quest)', 'Time left  1h 30m' }) do expect(string.find(text, needle, 1, true), 'world quest: ' .. needle) end
	world.scripts.OnLeave(world)
	-- the tracker hides (HIDE): no tooltip left behind
	title.scripts.OnEnter(title)
	title.scripts.OnHide(title)
	expectEq(GameTooltip.shown, false, 'never stuck')
	-- off in the settings
	ns.Compat:Set('trackerTips', false)
	title.scripts.OnEnter(title)
	expectEq(GameTooltip.shown, false, 'objective tooltips can be switched off')
	ns.Compat:Set('trackerTips', true)
	-- clicks unchanged
	HK_SUPERTRACK = nil
	title.scripts.OnClick(title, 'LeftButton')
	expectEq(HK_SUPERTRACK, 101, 'left click still focuses the quest')
	HK_QUESTS[101].objectives[1].numFulfilled, HK_QUESTS[101].objectives[1].numRequired = nil, nil
end)

test('1.0.0 AFK screen: the character turning in the middle, HUD hidden while it shows and back exactly as it was', function()
	local A = ns.AFK
	expectEq(ns.Compat.AFK, A, 'the options page reaches it')
	HK_AFK = true
	HK_Fire('PLAYER_FLAGS_CHANGED', 'player')
	local f = BanzaiAFKScreen
	expect(f and f.shown, 'shown when the game flags the character AFK')
	expectEq(UIParent.shown, false, 'HUD hidden (UIParent, as ElvUI and Alt+Z do)')
	expectEq(f.parent, nil, 'the screen is not part of the HUD')
	expectEq(f.keyboard, true, 'any key ends it')
	expectEq(f.model.modelUnit, 'player', 'the character itself (current gear)')
	expectEq(f.model.points[1][1] .. f.model.points[1][3], 'CENTERCENTER', 'centred')
	expect(f.model.camDistance >= 1 and f.model.portraitZoom == 0, 'the whole model in view')
	expect(string.find(HK_Plain(f.name.text), 'Darrensdrood', 1, true), 'name')
	expect(string.find(HK_Plain(f.spec.text), 'DRUID', 1, true) and string.find(HK_Plain(f.spec.text), 'FERAL', 1, true), 'class and spec')
	expect(string.find(HK_Plain(f.where.text), 'LEVEL 80', 1, true) and string.find(HK_Plain(f.where.text), 'DORNOGAL', 1, true), 'level and zone')
	expect(string.find(f.logo.path, 'BanzaiLogo', 1, true), 'BANZAI')
	expect(string.find(HK_Plain(f.brand.text), 'UI BY HARDKORH', 1, true), 'UI BY HARDKORH')
	expect(string.find(HK_Plain(f.version.text), 'BANZAI 1.5.0', 1, true), 'version')
	expect(string.find(f.tree.path, 'BanzaiBonsai', 1, true), 'the bamboo tree')
	expect(f.art and f.art.icon, 'the Fabled class art')
	expect(f.glass.gradient and f.glass.gradient[2].a < 0.95, 'dark translucent glass')
	f.scripts.OnUpdate(f, 6)
	expectNear(f.model.facing, 6 * 2 * math.pi / 24, 'turning smoothly: a full turn in 24 s')
	-- back: the flag clears
	HK_AFK = false
	HK_Fire('PLAYER_FLAGS_CHANGED', 'player')
	expectEq(f.shown, false, 'gone when the character is back')
	expectEq(UIParent.shown, true, 'HUD back')
	expectEq(UIParent.alpha, nil, 'no alpha changed anywhere')
	expectEq(f.keyboard, false, 'keyboard released')
	expect((f.model.cleared or 0) >= 1, 'model released')
	-- combat ends it at once (before the lockdown starts)
	HK_AFK = true
	HK_Fire('PLAYER_FLAGS_CHANGED', 'player')
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(UIParent.shown, true, 'combat: HUD back at once')
	expectEq(f.shown, false, 'screen gone')
	HK_IN_COMBAT = true
	HK_Fire('PLAYER_FLAGS_CHANGED', 'player')
	expectEq(f.shown, false, 'never during combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(f.shown, true, 'after combat, still AFK: it shows')
	-- a key: gone, back after a minute if still AFK
	HK_TIMERS = {}
	f.scripts.OnKeyDown(f, 'W')
	expectEq(f.shown, false, 'a key ends it')
	expectEq(UIParent.shown, true, 'HUD back')
	HK_RunTimers()
	expectEq(f.shown, true, 'still AFK a minute later: back')
	-- loading screen, queue pop, ready check, leaving the world
	for _, event in ipairs({ 'LOADING_SCREEN_ENABLED', 'LFG_PROPOSAL_SHOW', 'READY_CHECK', 'PLAYER_LEAVING_WORLD', 'CINEMATIC_START' }) do
		A:Close('test')
		A:Check()
		expectEq(f.shown, true, '(shown before ' .. event .. ')')
		HK_Fire(event)
		expectEq(f.shown, false, event .. ' ends it')
		expectEq(UIParent.shown, true, event .. ': HUD back')
	end
	A:Check()
	HK_BATTLEFIELD = 'queued'
	HK_Fire('UPDATE_BATTLEFIELD_STATUS', 1)
	expectEq(f.shown, true, 'a queue update that is not a pop: stays')
	HK_BATTLEFIELD = 'confirm'
	HK_Fire('UPDATE_BATTLEFIELD_STATUS', 1)
	expectEq(f.shown, false, 'a queue pop ends it')
	HK_BATTLEFIELD = nil
	-- something else shows the HUD (Escape): the screen goes, nothing is hidden again
	A:Check()
	UIParent:Show()
	f.scripts.OnUpdate(f, 0.1)
	expectEq(f.shown, false, 'HUD shown elsewhere: the screen goes')
	expectEq(UIParent.shown, true, 'the HUD stays')
	-- a HUD Darren had hidden himself (Alt+Z) stays hidden afterwards
	UIParent:Hide()
	A:Check()
	A:Close('test')
	expectEq(UIParent.shown, false, 'not shown by Banzai: it did not hide it')
	UIParent:Show()
	-- switched off: no Banzai screen
	ns.Compat:Set('afk', false)
	A:Check()
	expectEq(f.shown, false, 'off: nothing (ElvUI\'s own screen takes over, BushidoPrivateRestore)')
	ns.Compat:Set('afk', true)
	HK_AFK = false
	A:Check()
	-- preview: labelled, without being AFK, ended by a click, never in combat
	expectEq(A:Preview(), true, 'preview')
	expect(f.shown and string.find(HK_Plain(f.label.text), 'PREVIEW', 1, true), 'labelled PREVIEW')
	expectEq(UIParent.shown, false, 'shown as it really is')
	HK_Fire('PLAYER_FLAGS_CHANGED', 'player')
	expectEq(f.shown, true, 'not ended because Darren is not AFK')
	f.scripts.OnMouseDown(f)
	expectEq(f.shown, false, 'a click ends it')
	expectEq(UIParent.shown, true, 'HUD back')
	HK_IN_COMBAT = true
	expectEq(A:Preview(), false, 'no preview in combat')
	HK_IN_COMBAT = false
	-- model off: the Fabled class art in its place
	ns.Compat:Set('afkModel', false)
	A:Preview()
	expectEq(f.model.shown, false, 'no model')
	expectEq(f.bigArt.shown, true, 'class art instead')
	A:Close('test')
	ns.Compat:Set('afkModel', true)
	HK_RunTimers()
	expectEq(f.shown, false, 'nothing left showing')
	expectEq(UIParent.shown, true, 'HUD shown at the end')
end)

test('1.0.0 settings carried by Character Sync: widths, action-button look, tooltips, AFK screen', function()
	local D = Theme.DEFAULTS
	for key, value in pairs({ frameWidth = 0.5, abSize = 30, abSpacing = 6, abKeybind = 1.3, abCount = 0.8, ringIntensity = 1, tooltipTheme = 'BANZAI', tooltipScale = 1,
		panelTips = true, panelTipsCombat = false, panelTipAnchor = 'ITEM', trackerTips = true, afk = true, afkModel = true, afkRotate = true, afkTurn = 24, afkName = true, afkSpec = true, afkLevel = true, afkZone = true }) do
		expectEq(D[key], value, 'default ' .. key)
	end
	Theme:DB().afkTurn, Theme:DB().frameWidth = 40, 0.75
	local out = Theme:Export()
	expectEq(out.afkTurn .. ',' .. out.frameWidth, '40,0.75', 'exported with the BANZAI settings')
	Theme:DB().afkTurn, Theme:DB().frameWidth = 24, 0.5
	Theme:Import(out)
	expectEq(Theme:DB().afkTurn, 40, 'imported on another character')
	Theme:DB().afkTurn, Theme:DB().frameWidth = 24, 0.5
	-- the ring intensity is drawn live on the circles
	ns.Compat:Set('ringIntensity', 0.6)
	local parts = ns.ActionButtons:Get(buttons[1])
	expectNear(parts.ring.gradient[2].a, 0.6, 'ring at 60 %')
	ns.Compat:Set('ringIntensity', 1)
	-- wider circles push the cooldown bars out, never over the action bars
	local db = { cdSpread = 335, abSize = 32, abSpacing = 7 }
	expectEq(ns.CooldownBars.Spread({ cdSpread = 335 }, 1), 335, 'default: as set')
	local half = (12 * 32 + 11 * 7) / 2
	expect(ns.CooldownBars.Spread(db, 1.2) >= half + ns.CooldownBars.BAR.w * 1.2 / 2, 'never over the widest circles')
	expectEq(ns.CooldownBars.Spread({ cdSpread = 300, actionStyle = 'ELVUI', abSize = 32 }, 1), 300, 'ElvUI squares: as set')
end)

test('1.0.0 review: AFK screen - modifier keys and alt-tab do not end it, role checks / resurrection do, the preview gives the settings window back', function()
	local A = ns.AFK
	local f = BanzaiAFKScreen
	HK_AFK = true
	A:Check()
	expectEq(f.shown, true, '(shown)')
	for _, key in ipairs({ 'LALT', 'RALT', 'LSHIFT', 'RSHIFT', 'LCTRL', 'RCTRL' }) do
		f.scripts.OnKeyDown(f, key)
		expectEq(f.shown, true, key .. ' alone does not end it')
	end
	for _, event in ipairs({ 'LFG_ROLE_CHECK_SHOW', 'PVP_ROLE_CHECK_UPDATED', 'RESURRECT_REQUEST' }) do
		A:Check()
		HK_Fire(event)
		expectEq(f.shown, false, event .. ' ends it (its popup lives in the HUD)')
		expectEq(UIParent.shown, true, event .. ': HUD back')
	end
	HK_AFK = false
	A:Check()
	-- preview from the open settings window: ElvUI closes that window with the HUD, the preview reopens it
	local opened = {}
	BanzaiOpenSettings = function(page) opened[#opened + 1] = page return true end
	ElvUI[1].Libs.AceConfigDialog.OpenFrames.ElvUI = { frame = {} }
	A:Preview()
	ElvUI[1].Libs.AceConfigDialog.OpenFrames.ElvUI = nil -- (ElvUI released it when the HUD went)
	f.scripts.OnMouseDown(f)
	expectEq(opened[1], 'afk', 'the settings come back on AFK SCREEN')
	expectEq(UIParent.shown, true, 'HUD back')
	-- ended by combat: never reopened (combat)
	ElvUI[1].Libs.AceConfigDialog.OpenFrames.ElvUI = { frame = {} }
	A:Preview()
	ElvUI[1].Libs.AceConfigDialog.OpenFrames.ElvUI = nil
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(#opened, 1, 'combat: no settings window opened')
	HK_Fire('PLAYER_REGEN_ENABLED')
	-- a preview started without the settings open: nothing opened afterwards
	A:Preview()
	f.scripts.OnMouseDown(f)
	expectEq(#opened, 1, 'nothing to give back')
	BanzaiOpenSettings = nil
	HK_RunTimers()
	expectEq(f.shown, false, 'nothing left showing')
end)

test('1.0.0 review: the bottom panel shows "-" for what the game does not give (never a zero), its tooltip goes when combat starts', function()
	local byKey = PanelItems()
	local savedHonor, savedNet, savedDur = HK_CURRENCY[1792], GetNetStats, HK_DURABILITY
	HK_CURRENCY[1792] = nil
	GetNetStats = function() return 0, 0, nil, nil end
	HK_DURABILITY = {}
	ns.Bar:Update()
	expectEq(HK_Plain(byKey.honor.value.text), '-', 'no honor data: "-"')
	expectEq(HK_Plain(byKey.ms.value.text), '-', 'no latency: "-"')
	expectEq(HK_Plain(byKey.durability.value.text), '-', 'nothing that wears down: "-"')
	HK_CURRENCY[1792], GetNetStats, HK_DURABILITY = savedHonor, savedNet, savedDur
	ns.Bar:Update()
	expectEq(HK_Plain(byKey.honor.value.text), '12,345', 'back')
	-- the tooltip of a hovered entry goes the moment combat starts (the lockdown begins only after the event)
	byKey.gold.scripts.OnEnter(byKey.gold)
	expectEq(GameTooltip.shown, true, '(gold tooltip up)')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(GameTooltip.shown, false, 'gone at combat start')
	HK_Fire('PLAYER_REGEN_ENABLED')
	byKey.gold.scripts.OnLeave(byKey.gold)
end)

---------------------------------------------------------------------------
-- 1.1.0 panel material
---------------------------------------------------------------------------
local function stalkColor(holder, stalk, p) return piece(holder, stalk, p).texture.gradient[2] end
local function ropeColor(holder) return tie(holder, 'TOPLEFT').gradient end

test('1.1.0 border styles: CLASS (the class colour family, hemp rope), BANZAI (natural greens, purple rope), HARDKORH (green -> purple, purple rope); every panel at once', function()
	local chat, details, map = ns.Compat.chatFrame, ns.Compat.detailsFrame, ns.Compat.minimapFrame
	local D = Theme.DEFAULTS
	expectEq(D.panelBorder .. '/' .. D.panelBackground, 'BANZAI/GLASS', 'default: BANZAI border + BANZAI GLASS')
	expectEq(ns.Compat:Set('panelBorder', 'CLASS'), true, 'CLASS')
	for _, holder in ipairs({ chat, details, map }) do
		for _, stalk in ipairs({ 'top', 'bottom', 'left', 'right' }) do
			expect(orange(stalkColor(holder, stalk, 0.5)), holder.artKind .. ' ' .. stalk .. ': Druid orange family')
		end
		local rope = ropeColor(holder)
		expect(rope[2].r > rope[2].g and rope[2].g > rope[2].b and rope[2].r < 0.7, holder.artKind .. ': hemp rope, not the stalk colour')
	end
	-- lighter class tone -> class colour -> deeper along the chat's field (top-left bright, bottom-right deep)
	local bright, deep = stalkColor(chat, 'top', 0.05), piece(chat, 'bottom', 0.95).texture.gradient[3]
	expect(bright.r + bright.g + bright.b > deep.r + deep.g + deep.b + 0.6, 'lighter at the top-left, deeper at the bottom-right')
	expect(bright.g > 0.55 and bright.r > 0.95, 'the light tone is still orange')
	expect(deep.r > 0.45 and deep.g < 0.3 and deep.b < 0.1, 'the deep tone is a deep orange')
	expectEq(ns.Compat:Set('panelBorder', 'BANZAI'), true, 'BANZAI')
	local greens = {}
	for _, stalk in ipairs({ 'top', 'bottom', 'left', 'right' }) do
		local c = stalkColor(chat, stalk, 0.5)
		expect(c.g > 0.7 and c.g > c.r and c.r > c.b, stalk .. ': bright bamboo green')
		greens[stalk] = c
	end
	expect(math.abs(greens.top.r - greens.left.r) > 0.1, 'subtle natural variation between stalks')
	local a, b = piece(chat, 'top', 0.3).texture.gradient[2], piece(chat, 'top', 0.7).texture.gradient[2]
	expect(not is(a, { b.r, b.g, b.b }), 'segments differ a touch along a stalk')
	local rope = ropeColor(chat)
	expect(is(rope[2], PURPLE) and is(rope[3], C.violet), 'purple / violet rope')
	expectEq(ns.Compat:Set('panelBorder', 'HARDKORH'), true, 'HARDKORH')
	expect(green(stalkColor(chat, 'top', 0.05)), 'chat: green at the top-left')
	expect(purple(piece(chat, 'bottom', 0.95).texture.gradient[3]), 'chat: purple at the bottom-right')
	expect(purple(stalkColor(details, 'top', 0.05)), 'Details: purple at the top-left (its own direction)')
	expect(green(piece(details, 'bottom', 0.95).texture.gradient[3]), 'Details: green at the bottom-right')
	expect(green(stalkColor(map, 'top', 0.05)), 'minimap: green on the left')
	expect(purple(stalkColor(map, 'right', 0.5)), 'minimap: purple on the right')
	-- a vertical gradient's first colour lands at the bottom: the chat's left stalk runs green (top) -> purpler (bottom)
	local left = piece(chat, 'left', 0.5).texture.gradient
	expectEq(left[1], 'VERTICAL', 'vertical piece: vertical gradient')
	expect(left[2].b > left[3].b and left[3].g > left[2].g, 'bottom colour (first) purpler than the top colour (second)')
	local top = piece(chat, 'top', 0.5).texture.gradient
	expectEq(top[1], 'HORIZONTAL', 'horizontal piece: horizontal gradient')
	expect(top[3].b >= top[2].b, 'left -> right toward purple')
	local rope = tie(chat, 'TOPLEFT').gradient
	expect(is(rope[2], PURPLE) and is(rope[3], C.violet), 'rope: purple at the bottom (first), violet at the top')
	expect(is(ropeColor(chat)[2], PURPLE), 'rope still violet / purple')
	expectEq(ns.Compat:Set('panelBorder', 'BANZAI'), true, 'back to the default')
end)

test('1.1.0 rope colour preserved: never the stalk gradient, never dimmed by the frame intensity', function()
	local chat = ns.Compat.chatFrame
	ns.Compat:Set('intensity', 0.5)
	local top = stalkColor(chat, 'top', 0.5)
	expect(top.g < 0.5, 'stalks dimmed by the intensity')
	expect(is(ropeColor(chat)[2], PURPLE), 'rope at full colour')
	ns.Compat:Set('intensity', 1)
	ns.Compat:Set('panelBorder', 'HARDKORH')
	local rope = ropeColor(chat)
	expect(rope[2].b > rope[2].g + 0.5, 'HARDKORH rope purple, independent of the green end of the frame')
	ns.Compat:Set('panelBorder', 'CLASS')
	rope = ropeColor(chat)
	expect(rope[2].r > rope[2].b + 0.2 and rope[2].r < 0.7, 'CLASS: hemp, not Druid orange')
	ns.Compat:Set('panelBorder', 'BANZAI')
end)

test('1.1.0 backgrounds: SOLID, BANZAI GLASS (the glass opacity), HARDKORH PARCHMENT (brightness); independent of the border', function()
	local chat, details = ns.Compat.chatFrame, ns.Compat.detailsFrame
	expectEq(ns.Compat:Set('panelBackground', 'SOLID'), true, 'SOLID')
	expectEq(chat.glass.shown, true, 'glass texture shown')
	expectNear(chat.glass.gradient[3].a, 0.97, 'nearly opaque')
	expect(chat.glass.gradient[3].g > chat.glass.gradient[3].r, 'still the dark green tint')
	expectEq(chat.parchment[1].shown, false, 'no parchment')
	expectEq(ns.Compat:Set('panelBackground', 'GLASS'), true, 'GLASS')
	ns.Compat:Set('glassOpacity', 0.5)
	expectNear(chat.glass.gradient[3].a, 0.5, 'the glass opacity setting')
	expectNear(details.glass.gradient[3].a, 0.5, 'on Details too')
	ns.Compat:Set('glassOpacity', 0.72)
	expectNear(chat.glass.gradient[3].a, 0.72, 'back')
	expectEq(ns.Compat:Set('panelBackground', 'PARCHMENT'), true, 'PARCHMENT')
	expectEq(chat.glass.shown, false, 'glass hidden')
	for _, t in ipairs(chat.parchment) do
		expectEq(t.shown, true, 'parchment piece shown')
		expectNear(t.color[1], 0.91, 'at brightness 100 % (the texture is drawn 10 % brighter)')
	end
	ns.Compat:Set('parchmentBrightness', 0.8)
	expectNear(chat.parchment[1].color[1], 0.91 * 0.8, 'parchment brightness')
	ns.Compat:Set('parchmentBrightness', 1)
	local P = ns.Compat.PANEL
	local d = chat.stalkDiameter
	expectNear(chat.parchment[1].points[1][4], P.outer + P.parchment * d, 'the parchment starts under the stalk (its torn edge wanders out past it)')
	expectNear(chat.parchment[2].points[2][4] - chat.parchment[2].points[1][4], P.parchmentCorner * d, 'corner piece 2.4 x the stalk (1.3.7: both its corners anchored, no overlap)')
	-- any border with any background
	for _, combo in ipairs({ { 'CLASS', 'PARCHMENT' }, { 'HARDKORH', 'GLASS' }, { 'BANZAI', 'SOLID' }, { 'HARDKORH', 'PARCHMENT' }, { 'CLASS', 'GLASS' } }) do
		ns.Compat:Set('panelBorder', combo[1])
		ns.Compat:Set('panelBackground', combo[2])
		local border, background = ns.Compat:PanelStyle()
		expectEq(border .. '+' .. background, combo[1] .. '+' .. combo[2], 'combination kept')
		expectEq(chat.parchment[1].shown, combo[2] == 'PARCHMENT', combo[1] .. ' + ' .. combo[2] .. ': parchment only when chosen')
		expectEq(chat.glass.shown, combo[2] ~= 'PARCHMENT', combo[1] .. ' + ' .. combo[2] .. ': glass otherwise')
		local c = stalkColor(chat, 'top', 0.5)
		expectEq(orange(c), combo[1] == 'CLASS', combo[1] .. ' + ' .. combo[2] .. ': the border keeps its own colour')
	end
	ns.Compat:Set('panelBorder', 'BANZAI')
	ns.Compat:Set('panelBackground', 'GLASS')
end)

test('1.1.0 settings: unknown styles fall back, the old band thickness is clamped once (schema 7), Character Sync carries the panel style', function()
	local db = Theme:DB()
	db.panelBorder, db.panelBackground = 'NEON', 'WOOD'
	db = Theme:DB()
	expectEq(db.panelBorder .. '/' .. db.panelBackground, 'BANZAI/GLASS', 'unknown values fall back to the defaults')
	BanzaiCompatDB.chars['Old - Realm'] = { schema = 6, borderScale = 1.8, glassOpacity = 0.6 }
	local old = Theme:DB('Old - Realm')
	expectEq(old.schema, 9, 'migrated through 9 (1.3.9)')
	expectEq(old.borderScale, 1, 'a 1.0.3 band thickness of 180 % becomes the thickest stalk')
	expectEq(old.glassOpacity, 0.6, 'own choices kept')
	expectEq(old.panelBorder .. '/' .. old.panelBackground .. '/' .. old.parchmentBrightness, 'BANZAI/GLASS/1', 'new keys at their defaults')
	BanzaiCompatDB.chars['Old - Realm'] = nil
	db.panelBorder, db.panelBackground, db.parchmentBrightness, db.borderScale = 'HARDKORH', 'PARCHMENT', 0.9, 0.9
	local out = Theme:Export()
	expectEq(out.panelBorder .. '/' .. out.panelBackground .. '/' .. out.parchmentBrightness .. '/' .. out.borderScale .. '/' .. out.glassOpacity, 'HARDKORH/PARCHMENT/0.9/0.9/0.72', 'exported with the BANZAI settings')
	db.panelBorder, db.panelBackground, db.parchmentBrightness, db.borderScale = 'BANZAI', 'GLASS', 1, 1
	ns.Compat:Import(out)
	local border, background, scale = ns.Compat:PanelStyle()
	expectEq(border .. '/' .. background .. '/' .. scale, 'HARDKORH/PARCHMENT/0.9', 'imported and shown at once')
	ns.Compat:Import({ borderScale = 1.8 })
	expectEq(Theme:DB().borderScale, 1, 'a master captured before 1.1.0 with the old range: clamped on import')
	expectEq(ns.Compat.chatFrame.parchment[1].shown, true, 'parchment on after the import')
	ns.Compat:Import({ panelBorder = 'BANZAI', panelBackground = 'GLASS', parchmentBrightness = 1, borderScale = 1 })
	expectEq(ns.Compat.chatFrame.stalkDiameter, 10, 'back')
end)

test('1.1.0 ownership and performance: one frame per panel, built once, no OnUpdate, painted only on changes; CLASS follows a spec change', function()
	local before = ns.Compat:Counts()
	local screen = #HK_Children(UIParent)
	local chat = ns.Compat.chatFrame
	local tickers = #HK_TICKERS
	local function cycle()
		for _, combo in ipairs({ { 'CLASS', 'SOLID' }, { 'HARDKORH', 'PARCHMENT' }, { 'BANZAI', 'GLASS' } }) do
			ns.Compat:Set('panelBorder', combo[1])
			ns.Compat:Set('panelBackground', combo[2])
		end
		ns.Compat:Set('borderScale', 0.7) -- a thinner stalk needs more node sections: made once, kept
		ns.Compat:Set('borderScale', 1)
	end
	cycle()
	local textures = #chat.textures
	cycle()
	ns.Compat:Build()
	local after = ns.Compat:Counts()
	expectEq(after.holders, before.holders, 'same art frames')
	expectEq(after.bands, before.bands, 'same bamboo frames (three)')
	expectEq(after.bands, 4, 'exactly the minimap, Details, chat and (1.2.0) BUFFS')
	expectEq(#HK_Children(UIParent), screen, 'nothing added to the screen')
	expectEq(#chat.textures, textures, 'textures reused across style and scale changes')
	expectEq(#HK_TICKERS, tickers, 'no new tickers')
	for _, holder in ipairs({ chat, ns.Compat.detailsFrame, ns.Compat.minimapFrame }) do
		expectEq(holder.scripts.OnUpdate, nil, holder.artKind .. ': no OnUpdate')
		expectEq(holder.mouse, false, holder.artKind .. ': takes no clicks (the map, chat and meters keep theirs)')
	end
	-- a CLASS border is repainted after a spec change (the class colour may differ); BANZAI is not
	ns.Compat:Set('panelBorder', 'CLASS')
	tie(chat, 'TOPLEFT').gradient = nil
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED')
	expect(tie(chat, 'TOPLEFT').gradient, 'repainted on the spec change')
	ns.Compat:Set('panelBorder', 'BANZAI')
	tie(chat, 'TOPLEFT').gradient = nil
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED')
	expectEq(tie(chat, 'TOPLEFT').gradient, nil, 'nothing repainted when no class colour is in use')
	ns.Compat:ApplyTheme()
	expect(tie(chat, 'TOPLEFT').gradient, 'painted again with the theme')
end)

test('1.1.0 media: the panel textures are the original Banzai stalk, ends, rope tie and parchment', function()
	local chat = ns.Compat.chatFrame
	local paths = {}
	for i = 1, chat.pieceCount do paths[chat.pieces[i].texture.path] = true end
	expectEq(paths[Theme.MEDIA .. 'BanzaiStalk'] and paths[Theme.MEDIA .. 'BanzaiStalkEnd'], true, 'stalk + ends')
	expectEq(tie(chat, 'TOPLEFT').path, Theme.MEDIA .. 'BanzaiRopeTie', 'rope tie')
	expectEq(chat.parchment[1].path, Theme.MEDIA .. 'BanzaiParchmentTile', 'parchment (1.3.7: the tile, with the worn edge strips and the corners)')
	for _, t in ipairs(allTextures(chat)) do
		expect(not (t.path and (string.find(t.path, 'FrameBand', 1, true) or string.find(t.path, 'MinimapMask', 1, true) or string.find(t.path, 'Bundle', 1, true))), 'no band, mask or bundle on the chat frame')
	end
end)

---------------------------------------------------------------------------
-- 1.2.0
---------------------------------------------------------------------------
test('1.2.0 BANZAI SQUARE buttons: the whole spell picture (square, small chamfers), a thin crisp border half outside, square swipe and proc halo, transparent backdrop', function()
	local AB = ns.ActionButtons
	expectEq(Theme:DB().actionStyle, 'SQUARE', 'the default')
	-- ElvUI sizes the buttons in whole pixels (E:Scale): Darren's 30 units at UI scale 0.71 on 1440 lines = 39 px = 29.296 units
	local mult = 768 / 1440 / 0.71
	local w39 = 30 - (30 % mult)
	for i = 1, 12 do buttons[i].w, buttons[i].h = w39, w39 end
	AB:Refresh()
	expectEq(AB.count, 12, 'the main cluster')
	local b1 = buttons[1]
	local parts = AB:Get(b1)
	expectEq(parts.shape, 'SQUARE', 'square shape')
	expectNear(parts.pixels, 39, 'the button covers exactly 39 screen pixels')
	expectEq(parts.ring.path, Theme.MEDIA .. 'BanzaiSquareBorder39', 'the border drawn for a 39 px button')
	local px = 1 / (0.71 * 1440 / 768) -- one screen pixel in units
	expectNear(parts.ring.w, 64 * px, 'its 64 px canvas laid 64 screen pixels wide: one texel per pixel')
	expectEq(parts.ring.points[1][1] .. ' ' .. tostring(parts.ring.points[1][2] == b1) .. ' ' .. parts.ring.points[1][3], 'TOPLEFT true TOPLEFT', 'from the button\'s top-left')
	expectNear(parts.ring.points[1][4], -12 * px, '12 px left of it (where the drawing has the button)')
	expectNear(parts.ring.points[1][5], 12 * px, 'and above it')
	expectEq(parts.mask.path, Theme.MEDIA .. 'BanzaiSquareMask', 'square mask')
	expectEq(parts.mask.allPoints, b1, 'stretched over the button (its edge lies under the border)')
	for _, t in ipairs({ parts.mask, parts.ring }) do
		expectEq(t.filter .. ' ' .. tostring(t.snap) .. ' ' .. t.texelBias, 'TRILINEAR true 0', 'trilinear, on the pixel grid, no texel snapping')
	end
	-- other whole-pixel widths: their own drawing; beyond them the 80 px drawing, scaled
	for _, s in ipairs({ 26, 28, 32 }) do
		buttons[2].w, buttons[2].h = s - (s % mult), s - (s % mult)
		AB:Refresh()
		local want = math.floor(buttons[2].w / mult + 0.5)
		expectEq(AB:Get(buttons[2]).ring.path, Theme.MEDIA .. 'BanzaiSquareBorder' .. want, 'size ' .. s .. ': the ' .. want .. ' px drawing')
	end
	buttons[2].w, buttons[2].h = w39, w39
	expectEq(b1.icon.masks[1], parts.mask, 'icon masked (chamfered corners only)')
	expectEq(b1.icon.coords, nil, 'icon texcoords left to ElvUI: the picture is not cropped further')
	for _, overlay in ipairs({ b1.highlightTexture, b1.pushedTexture, b1.checkedTexture }) do expectEq(overlay.masks[1], parts.mask, 'overlays follow the square') end
	expect(string.find(b1.cooldown.swipe, 'BanzaiSquareSwipe', 1, true), 'cooldown swipe in the same shape')
	expectEq(b1.Center.alpha .. ' ' .. b1.customBackdropAlpha .. ' ' .. b1.backdropColor[4], '0 0 0', 'no black ActionBar backdrop')
	expectEq(parts.glass, nil, 'no glass over the icon')
	expect(green(parts.ring.gradient[2]), 'border starts green')
	expect(purple(AB:Get(buttons[12]).ring.gradient[3]), 'the cluster ends purple: green -> emerald -> violet -> purple')
	expectEq(AB:Get(buttons[11]).ring.alpha, AB.EMPTY_ALPHA, 'empty slot: a faint outline only')
	expectEq(AB:Get(square), nil, 'other bars keep ElvUI\'s buttons')
	-- buttons drawn larger (another scale / 4K): the 80 px drawing on its 128 px canvas, scaled
	buttons[2].effectiveScale = 1.4
	AB:Refresh()
	expect(string.find(AB:Get(buttons[2]).ring.path, 'BanzaiSquareBorder128', 1, true), 'large button: the 128 px canvas')
	expectNear(AB:Get(buttons[2]).ring.w, w39 * 128 / 80, 'scaled around the button')
	buttons[2].effectiveScale = 0.71
	AB:Refresh()
	expectEq(AB:Get(buttons[2]).ring.path, Theme.MEDIA .. 'BanzaiSquareBorder39', 'back to the 39 px drawing')
	-- proc: a chamfered halo around the square, pulsing
	HK_Fire('SPELL_ACTIVATION_OVERLAY_GLOW_SHOW', 5003)
	HK_RunTimers()
	local glow = AB:GetGlow(buttons[3])
	expect(glow and glow.shown and string.find(glow.path, 'BanzaiSquareGlow', 1, true), 'square proc halo')
	expectNear(glow.w, w39 * AB.SHAPES.SQUARE.glowScale, 'around the button')
	expect(glow.animationGroup.playing, 'pulsing')
	HK_Fire('SPELL_ACTIVATION_OVERLAY_GLOW_HIDE', 5003)
	HK_RunTimers()
	expectEq(glow.shown, false, 'off with the proc')
	expectEq(buttons[10].HotKey.text, '10', 'keybind text, cooldowns, clicks, bindings left to ElvUI')
	-- switching: circles <-> square on the same parts, ElvUI square takes everything off
	ns.Compat:Set('actionStyle', 'CIRCLE')
	expect(string.find(parts.ring.path, 'BanzaiButtonRing', 1, true) and string.find(b1.cooldown.swipe, 'BanzaiButtonCircle', 1, true), 'circles')
	expectEq(#b1.icon.masks, 1, 'still one mask')
	ns.Compat:Set('actionStyle', 'ELVUI')
	expectEq(#b1.icon.masks .. ' ' .. b1.Center.alpha .. ' ' .. tostring(parts.ring.shown), '0 1 false', 'ElvUI square: ElvUI\'s own button back')
	expectEq(b1.cooldown.swipe, Theme.WHITE, 'ElvUI\'s square swipe')
	ns.Compat:Set('actionStyle', 'SQUARE')
	expectEq(#b1.icon.masks .. ' ' .. tostring(parts.ring.shown), '1 true', 'square again, one mask')
	local before = #(b1.textures or {})
	for _ = 1, 3 do ns.Compat:Set('actionStyle', 'CIRCLE') ns.Compat:Set('actionStyle', 'SQUARE') end
	expectEq(#(b1.textures or {}), before, 'no textures added by switching')
	for i = 1, 12 do buttons[i].w, buttons[i].h = 30, 30 end
	AB:Refresh()
end)

test('1.2.0 chat flush with the left screen edge: the whole composition moved, nothing left behind or off the screen', function()
	local chat, P = ns.Compat.chatFrame, ns.Compat.PANEL
	local x = chat.points[1][4]
	expectNear(x, -0.655, 'frame at -0.655: its left stalk on the edge')
	expectEq(chat.flushLeft, x, 'flush geometry')
	expectEq(chat.w .. 'x' .. chat.h, '493.31x161', 'same size')
	expectEq(chat.points[1][5] + P.outer, Theme:DB().barHeight, 'same bottom (on the information panel)')
	for i = 1, chat.pieceCount do
		local t = chat.pieces[i].texture
		if chat.pieces[i].horizontal then expect(x + t.points[1][4] >= -1e-6, 'no stalk piece starts off the left of the screen') end
	end
	expectNear(x + tie(chat, 'TOPLEFT').points[1][4], 0, 'the top-left rope on the screen edge (holder x 0.655)')
	for _, corner in ipairs({ 'TOPLEFT', 'BOTTOMLEFT' }) do
		local t = tie(chat, corner)
		expect(x + t.points[1][4] >= -1e-6, corner .. ' tie fully on the screen')
		expect(t.points[1][4] <= chat.axis.left and t.points[1][4] + t.w >= P.outer + chat.stalkDiameter, corner .. ' tie still over the crossing (its centre line and the inner edge of the stalk)')
	end
	-- the horizontal stalks end at the left stalk with plain node ends, cut tips on the open side
	local cuts = {}
	for i = 1, chat.pieceCount do
		local s = chat.pieces[i]
		if s.horizontal and string.find(s.texture.path, 'BanzaiStalkEnd$') then
			local uEnd = s.texture.coords[5]
			cuts[#cuts + 1] = (math.max(s.texture.coords[1], uEnd) <= 0.5) and ((s.texture.points[1][4] > chat.bw / 2) and 'R' or 'L') or nil
		end
	end
	expectEq(table.concat(cuts, ''), 'RR', 'cut tips on the right ends of the top and bottom stalks only')
	-- title and content moved with it
	local title = ns.Compat.chatTitle
	expectEq(title.points[1][2], chat, 'CHAT title on the frame')
	expectNear(title.points[1][4], chat.bw / 2, 'centred')
	-- Details did not move
	expectEq(ns.Compat.detailsFrame.points[1][2], HK_DetailsWindow2.baseframe, 'Details still on its window')
	expect(ns.Compat.detailsFrame.flushLeft == nil and ns.Compat.minimapFrame.flushLeft == nil, 'only the chat is flush')
end)

test('1.2.0 BUFFS panel: around ElvUI\'s buff icons, 2 / 3 rows of 10, the panel material, BUFFS on the bottom stalk, nothing in front of the buffs', function()
	local f, P, B = ns.Compat.buffsFrame, ns.Compat.PANEL, ns.Compat.BUFFS
	expect(f, 'built')
	expectEq(f.artKind, 'buffs', 'its own panel')
	expectEq(f.shown, true, 'shown on the Banzai profile')
	expectEq(f.points[1][1] .. ' ' .. tostring(f.points[1][2] == buffMover) .. ' ' .. f.points[1][3], 'TOPLEFT true TOPLEFT', 'on the buffs\' mover (ElvUI puts its buff header there)')
	local inset = P.outer + P.stalk + B.pad
	expectNear(f.points[1][4], -inset, 'the stalks and padding left of the first icon')
	expectNear(f.points[1][5], inset, 'and above it')
	local w = 10 * 25 + 9 * 6
	expectNear(f.w, w + 2 * inset, 'exactly 10 icons wide + stalks + padding (compact)')
	expectNear(f.h, (2 * 21 + 10) + inset + P.outer + P.stalk + B.padBottom, '2 rows + room for their durations and the title')
	bambooFrame(f)
	expectEq(f.strata .. ' ' .. f.level .. ' ' .. tostring(f.mouse), 'BACKGROUND 0 false', 'behind the buffs, never taking their clicks / tooltips / cancelling')
	expectEq(f.scripts.OnUpdate, nil, 'no OnUpdate')
	-- the BUFFS title on the bottom stalk
	local t = ns.Compat.buffsTitle
	expectEq(HK_Plain(t.text.text), 'BUFFS', 'exactly BUFFS')
	expectEq(t.shown, true, 'shown')
	expectEq(t.points[1][1] .. ' ' .. tostring(t.points[1][2] == f) .. ' ' .. t.points[1][3], 'CENTER true TOPLEFT', 'centred on the panel')
	expectNear(t.points[1][4], f.bw / 2, 'horizontally centred')
	expectNear(-t.points[1][5], f.bh - (P.outer + f.stalkDiameter / 2), 'on the BOTTOM stalk\'s axis (not the top)')
	expectEq(t.text.font, ns.Compat.chatTitle.text.font, 'the CHAT / DAMAGE / HEALING title design')
	expectEq(t.text.fontSize, ns.Compat.chatTitle.text.fontSize, 'same size')
	expect(t.backing[2].gradient[2].a > 0.5, 'dark backing behind the letters')
	local first = string.match(t.text.text, '^|cff(%x%x%x%x%x%x)')
	expect(first and tonumber(string.sub(first, 3, 4), 16) > 200, 'green -> violet Banzai letters')
	expectEq(t.mouse, false, 'the title takes no clicks')
	-- the icons clear the title: the last row's durations (16 high, 3 under the icon) end above the title's top
	local iconsBottom = inset + 2 * 21 + 10
	local durations = iconsBottom + 3 + 8
	local titleTop = f.bh - (P.outer + f.stalkDiameter / 2) - ns.Compat.DETAILS_TITLE.size * 0.78 / 2
	expect(durations < titleTop, 'durations of the last row clear of the BUFFS title (' .. durations .. ' < ' .. titleTop .. ')')
	-- 3 rows
	ns.Compat:Set('buffsRows', 3)
	expectNear(f.h, (3 * 21 + 2 * 10) + inset + P.outer + P.stalk + B.padBottom, '3 rows')
	expectNear(-t.points[1][5], f.bh - (P.outer + f.stalkDiameter / 2), 'the title follows the bottom stalk')
	ns.Compat:Set('buffsRows', 2)
	-- panel material: the same border / background / scale / opacity / brightness as chat, Details and minimap
	ns.Compat:Set('panelBorder', 'HARDKORH')
	expect(green(piece(f, 'top', 0.05).texture.gradient[2]) and purple(piece(f, 'bottom', 0.95).texture.gradient[3]), 'HARDKORH: green -> purple over the panel')
	ns.Compat:Set('panelBorder', 'CLASS')
	expect(orange(piece(f, 'top', 0.5).texture.gradient[2]), 'CLASS: the class colour')
	ns.Compat:Set('panelBorder', 'BANZAI')
	expect(is(tie(f, 'TOPLEFT').gradient[2], PURPLE), 'BANZAI: purple rope')
	ns.Compat:Set('panelBackground', 'PARCHMENT')
	expectEq(f.parchment[1].shown and not f.glass.shown, true, 'parchment')
	expect(t.backing[2].gradient[2].a > 0.5, 'the title keeps its dark backing on parchment (no dark-text mistake)')
	ns.Compat:Set('parchmentBrightness', 0.8)
	expectNear(f.parchment[1].color[1], 0.91 * 0.8, 'parchment brightness')
	ns.Compat:Set('parchmentBrightness', 1)
	ns.Compat:Set('panelBackground', 'GLASS')
	ns.Compat:Set('glassOpacity', 0.5)
	expectNear(f.glass.gradient[3].a, 0.5, 'glass opacity')
	ns.Compat:Set('glassOpacity', 0.72)
	ns.Compat:Set('borderScale', 0.8)
	expectEq(f.stalkDiameter, 8, 'border scale')
	expectNear(f.points[1][4], -(P.outer + 8 + B.pad), 'the icons stay put, the panel hugs them')
	ns.Compat:Set('borderScale', 1)
	-- off / another profile / no ElvUI buff header
	ns.Compat:Set('buffsPanel', false)
	expectEq(tostring(f.shown) .. ' ' .. tostring(t.shown), 'false false', 'switched off')
	ns.Compat:Set('buffsPanel', true)
	HK_ElvData.current = 'HARDKORHUI'
	ns.Compat.RefreshAll(ns.Compat)
	expectEq(f.shown, false, 'only on the Banzai profile')
	HK_ElvData.current = NAME
	ns.Compat.RefreshAll(ns.Compat)
	_G.ElvUIPlayerBuffs = nil
	ns.Compat:Refresh()
	expectEq(f.shown, false, 'no ElvUI buff header (ElvUI auras off): no empty panel')
	_G.ElvUIPlayerBuffs = buffHeader
	ns.Compat:Refresh()
	expectEq(f.shown, true, 'back')
	-- 1.2.1: no dynamic overflow row - aura and equipment events change nothing (the 1.2.0 overflow check read
	-- the icons' secret shown state); the regression test below traps every read of ElvUI's buff icons
	local h2 = f.h
	HK_Fire('UNIT_AURA', 'player')
	HK_Fire('UNIT_INVENTORY_CHANGED', 'player')
	HK_RunTimers()
	expectEq(f.h, h2, 'the panel keeps its configured size')
	expectEq(ns.Compat.CheckBuffsOverflow, nil, 'no overflow check any more')
	-- built once
	local count = ns.Compat:Counts()
	ns.Compat:Build()
	ns.Compat:Set('buffsRows', 3)
	ns.Compat:Set('buffsRows', 2)
	expectEq(ns.Compat:Counts().holders, count.holders, 'no duplicate panel frames')
end)

test('1.2.0 settings: BANZAI (1.1.x circles) becomes SQUARE once, ELVUI kept; buffs settings bounded; Character Sync carries style and panel, no buffs', function()
	BanzaiCompatDB.chars['Circle - Realm'] = { schema = 7, actionStyle = 'BANZAI' }
	BanzaiCompatDB.chars['Elv - Realm'] = { schema = 7, actionStyle = 'ELVUI' }
	expectEq(Theme:DB('Circle - Realm').actionStyle, 'SQUARE', '1.1.x default (circles) -> the new default square')
	expectEq(Theme:DB('Elv - Realm').actionStyle, 'ELVUI', 'an ElvUI choice is kept')
	expectEq(Theme:DB('Circle - Realm').schema, 9, 'schema 9')
	local db = Theme:DB('Circle - Realm')
	db.actionStyle = 'CIRCLE'
	expectEq(Theme:DB('Circle - Realm').actionStyle, 'CIRCLE', 'circles chosen after the upgrade are kept')
	db.buffsRows, db.buffsX, db.buffsY = 9, -40, 5000
	db = Theme:DB('Circle - Realm')
	expectEq(db.buffsRows .. ',' .. db.buffsX .. ',' .. db.buffsY, '2,26,600', 'rows 2 / 3, position on the screen')
	BanzaiCompatDB.chars['Circle - Realm'], BanzaiCompatDB.chars['Elv - Realm'] = nil, nil
	-- sync: an import from a 1.1.x master (BANZAI) lands on the square
	local mine = Theme:DB()
	mine.buffsRows, mine.buffsX = 3, 80
	local out = Theme:Export()
	expectEq(out.actionStyle .. ',' .. tostring(out.buffsPanel) .. ',' .. out.buffsRows .. ',' .. out.buffsX .. ',' .. out.buffsY, 'SQUARE,true,3,80,30', 'exported')
	for k in pairs(out) do expect(Theme.DEFAULTS[k] ~= nil or k == 'roles', 'only BANZAI settings exported (' .. k .. ')') end
	ns.Compat:Import({ actionStyle = 'BANZAI', buffsRows = 2, buffsX = 30 })
	expectEq(Theme:DB().actionStyle, 'SQUARE', 'a 1.1.x master\'s BANZAI imports as the square')
	expectEq(Theme:DB().buffsRows .. ',' .. Theme:DB().buffsX, '2,30', 'panel settings imported')
end)

---------------------------------------------------------------------------
-- 1.2.1 Midnight secret-value hotfix
---------------------------------------------------------------------------
-- ElvUI's buff icons (the children of its AuraContainer) carry secret state on Midnight: their IsShown() and the
-- like return secret values the game will not let addon code test, compare or count. The trap below makes every
-- such read fail loudly (the offline Lua cannot reproduce a secret boolean's own error, so any read at all counts),
-- then drives the BUFFS panel through every situation: it must never touch the icons, the header's children,
-- the auras or the weapon enchants, and its geometry must follow only the configured rows.
test('1.2.1 BUFFS panel never reads ElvUI\'s buff icons or aura state - 2 / 3 rows, on / off, combat, login / reload, spec change, Character Sync, every border and background', function()
	local f, P, B = ns.Compat.buffsFrame, ns.Compat.PANEL, ns.Compat.BUFFS
	local trapped = {}
	local function trap(name) return function() trapped[#trapped + 1] = name error('secret value read: ' .. name) end end
	local SECRET = setmetatable({}, { __tostring = function() return 'SECRET' end })
	local secretTest = issecretvalue
	issecretvalue = function(v) return v == SECRET or (secretTest and secretTest(v)) or false end
	local icons = {}
	for i = 1, 22 do -- 20 buffs + 2 weapon enchants: more than 2 rows hold
		local icon = HK_NewFrame('Button', nil, buffHeader)
		for _, getter in ipairs({ 'IsShown', 'IsVisible', 'GetAlpha', 'GetWidth', 'GetHeight', 'GetRect', 'GetPoint', 'GetNumPoints', 'GetChildren', 'GetRegions' }) do icon[getter] = trap('icon:' .. getter) end
		icon.duration, icon.count, icon.auraInstanceID = SECRET, SECRET, SECRET
		icons[i] = icon
	end
	local headerGetters = {}
	for _, getter in ipairs({ 'GetChildren', 'GetNumChildren', 'GetRegions', 'IsShown', 'IsVisible', 'GetRect', 'GetWidth', 'GetHeight', 'GetAttribute' }) do
		headerGetters[getter] = buffHeader[getter]
		buffHeader[getter] = trap('header:' .. getter)
	end
	local auraAPI = { C_UnitAuras = C_UnitAuras, UnitAura = UnitAura, UnitBuff = UnitBuff, GetWeaponEnchantInfo = GetWeaponEnchantInfo }
	C_UnitAuras = setmetatable({}, { __index = function(_, k) return trap('C_UnitAuras.' .. k) end })
	UnitAura, UnitBuff, GetWeaponEnchantInfo = trap('UnitAura'), trap('UnitBuff'), trap('GetWeaponEnchantInfo')
	local function restore()
		for getter, fn in pairs(headerGetters) do buffHeader[getter] = fn end
		C_UnitAuras, UnitAura, UnitBuff, GetWeaponEnchantInfo = auraAPI.C_UnitAuras, auraAPI.UnitAura, auraAPI.UnitBuff, auraAPI.GetWeaponEnchantInfo
		issecretvalue = secretTest
		for _, icon in ipairs(icons) do icon.parent = nil end
		HK_IN_COMBAT = false
	end
	local errors = {}
	local function run(label, fn)
		local ok, err = pcall(fn)
		if not ok then errors[#errors + 1] = label .. ': ' .. tostring(err) end
	end
	local function height(rows) return (rows * 21 + (rows - 1) * 10) + (P.outer + f.stalkDiameter + B.pad) + (P.outer + f.stalkDiameter + B.padBottom) end
	local function aurasHappen()
		HK_Fire('UNIT_AURA', 'player')
		HK_Fire('UNIT_INVENTORY_CHANGED', 'player')
		HK_Fire('PLAYER_EQUIPMENT_CHANGED', 16, false)
		HK_RunTimers()
	end
	local frames0 = 0
	for _, frame in ipairs(HK_Frames()) do if frame.events and frame.events.UNIT_AURA then frames0 = frames0 + 1 end end
	local body = function()
	for _, rows in ipairs({ 2, 3 }) do
		run(rows .. ' rows', function() ns.Compat:Set('buffsRows', rows) end)
		aurasHappen()
		expectNear(f.h, height(rows), rows .. ' rows: the configured geometry (22 icons shown changes nothing)')
		run('combat', function()
			HK_IN_COMBAT = true
			HK_Fire('PLAYER_REGEN_DISABLED')
			aurasHappen()
			HK_IN_COMBAT = false
			HK_Fire('PLAYER_REGEN_ENABLED')
			HK_RunTimers()
		end)
		expectNear(f.h, height(rows), rows .. ' rows: the same through combat')
		run('login / reload', function()
			HK_Fire('PLAYER_ENTERING_WORLD', true, false)
			HK_RunTimers()
			HK_Fire('PLAYER_ENTERING_WORLD', false, true)
			HK_RunTimers()
		end)
		run('spec change / zones', function()
			HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
			HK_Fire('ZONE_CHANGED_NEW_AREA')
			HK_RunTimers()
		end)
		expectNear(f.h, height(rows), rows .. ' rows: the same after login, reload and a spec change')
		for _, border in ipairs({ 'CLASS', 'BANZAI', 'HARDKORH' }) do
			for _, background in ipairs({ 'SOLID', 'GLASS', 'PARCHMENT' }) do
				run(border .. ' + ' .. background, function()
					ns.Compat:Set('panelBorder', border)
					ns.Compat:Set('panelBackground', background)
					aurasHappen()
				end)
				expectEq(f.shown, true, border .. ' + ' .. background .. ': shown')
				expectNear(f.h, height(rows), border .. ' + ' .. background .. ': the configured geometry')
			end
		end
	end
	run('off / on', function()
		ns.Compat:Set('buffsPanel', false)
		aurasHappen()
		ns.Compat:Set('buffsPanel', true)
	end)
	expectEq(f.shown, true, 'on again')
	run('Character Sync import', function()
		ns.Compat:Import({ buffsRows = 3, panelBorder = 'HARDKORH', panelBackground = 'PARCHMENT' })
		aurasHappen()
	end)
	expectNear(f.h, height(3), 'Character Sync: the imported rows decide the geometry')
	run('back', function() ns.Compat:Import({ buffsRows = 2, panelBorder = 'BANZAI', panelBackground = 'GLASS' }) end)
	expectNear(f.h, height(2), 'back to 2 rows')
	end
	local ok, err = pcall(body)
	restore() -- always: the mocks back even when an expectation failed
	ns.Compat:Refresh()
	if not ok then error(err, 0) end
	-- nothing touched, nothing raised, nothing polling, no new aura watcher
	expectEq(table.concat(errors, ' | '), '', 'no error anywhere')
	expectEq(table.concat(trapped, ', '), '', 'no buff icon, header child, aura or weapon-enchant read')
	expectEq(f.scripts.OnUpdate, nil, 'no OnUpdate on the panel')
	local frames1 = 0
	for _, frame in ipairs(HK_Frames()) do if frame.events and frame.events.UNIT_AURA then frames1 = frames1 + 1 end end
	expectEq(frames1, frames0, 'no frame started listening to UNIT_AURA')
	expectEq(ns.Compat.CheckBuffsOverflow, nil, 'no overflow check')
end)


---------------------------------------------------------------------------
-- 1.3.0 optional BANZAI SPLIT unit frames + COMPACT Details
---------------------------------------------------------------------------
local Split = ns.Split
local Identity = ns.Identity
issecretvalue = HK_IsSecret -- (an earlier test left a plain stand-in behind)
-- 1.3.2: the built manifest lists Darren's 13 class identities; the 1.3.0 / 1.3.1 tests below check the
-- chain's fallbacks as they were written (no original art yet), so they run on an empty list - the 1.3.2
-- tests put the built one back
local BUILT_ART = ns.IdentityManifest.classes
ns.IdentityManifest.classes = {}

test('1.3.0 BANZAI CLASSIC stays the default: every character on CLASSIC / CURRENT, nothing split in a classic session, unknown styles fall back; Character Sync carries the new choices', function()
	local db = Theme:DB()
	expectEq(db.frameStyle, 'CLASSIC', 'existing characters: BANZAI CLASSIC')
	expectEq(db.detailsStyle, 'CURRENT', 'existing characters: BANZAI CURRENT')
	expectEq(Split:Session(), false, 'a classic session')
	expectEq(Split:Counts().hubs, 0, 'no hub built')
	expectEq(Split:Counts().watchers, 0, 'no cast watcher registered')
	expectEq(Split:Get('ElvUF_Player'), nil, 'nothing on the Player frame')
	-- the classic decoration stays: bamboo on Player / Target, the classic health texts
	local counts = ns.Compat:Counts()
	ns.Compat:RefreshAll()
	expectEq(ns.Compat:Counts().holders, counts.holders, 'no new art from a refresh')
	expect(ns.Health:Get('ElvUF_Player') and not ns.Health:Get('ElvUF_Player').def.split, 'classic health text on the Player')
	expectEq(ns.Health:GetPower('ElvUF_Player'), nil, 'no split resource text')
	-- unknown values never become SPLIT / COMPACT
	db.frameStyle, db.detailsStyle = 'FANCY', 'TINY'
	db = Theme:DB()
	expectEq(db.frameStyle .. '/' .. db.detailsStyle, 'CLASSIC/CURRENT', 'unknown: the approved styles')
	db.splitPlayerY, db.splitScale, db.splitHubScale = 9999, 0.1, 'x'
	db = Theme:DB()
	expectEq(db.splitPlayerY .. '/' .. db.splitScale .. '/' .. db.splitHubScale, '520/0.8/1', 'split values brought into range')
	db.splitPlayerY, db.splitScale, db.splitHubScale = 290, 1, 1
	-- Character Sync: every new choice is a BANZAI setting
	local exported = Theme:Export()
	for _, key in ipairs({ 'frameStyle', 'splitPlayerX', 'splitPlayerY', 'splitTargetX', 'splitTargetY', 'splitScale', 'splitHubScale', 'splitHpText', 'splitPowerText', 'splitTargetPlate', 'splitParty', 'detailsStyle' }) do
		expect(exported[key] ~= nil, 'synced: ' .. key)
	end
	expectEq(exported.cdTracked == false or type(exported.cdTracked) == 'table', true, 'the tracked cooldowns travel only as before (Sync strips them)')
end)

test('1.3.0 the identity-art chain: Darren\'s original icon (manifest), then Fabled spec / class (Jiberish Icons), then a class-colour glyph, then unknown; a bad manifest entry is never used', function()
	expectEq(table.concat(Identity.ART_ORDER, ','), 'BANZAI,FABLED,GLYPH,UNKNOWN', 'loading priority')
	expectEq(type(ns.IdentityManifest), 'table', 'the generated manifest is loaded')
	expectEq(next(ns.IdentityManifest.classes), nil, 'no original icons (as in 1.3.0; 1.3.2 lists 13 - emptied for these tests): nothing listed, no placeholder')
	local art = Identity.Art('MAGE')
	expectEq(art.kind, 'FABLED', 'today: the Fabled class art')
	expectEq(art.path, JI_CLASS, 'through Jiberish Icons\' own API (referenced in place)')
	expectEq(Identity.Art('MAGE', 64).kind .. ':' .. tostring(Identity.Art('MAGE', 64).spec), 'FABLED:true', 'a reliably known spec: the Fabled spec art')
	ns.IdentityManifest.classes.MAGE = 'mage'
	art = Identity.Art('MAGE')
	expectEq(art.kind, 'BANZAI', 'an original icon wins once it is there')
	expectEq(art.path, Theme.MEDIA .. 'BanzaiIdentity\\mage', 'from media/BanzaiIdentity')
	ns.IdentityManifest.classes.MAGE = '..\\Fabled'
	expectEq(Identity.Art('MAGE').kind, 'FABLED', 'a manifest entry that is not a plain class name is ignored')
	ns.IdentityManifest.classes.MAGE = nil
	local saved = JiberishIcons
	JiberishIcons = nil
	art = Identity.Art('DEATHKNIGHT')
	expectEq(art.kind .. ':' .. art.glyph, 'GLYPH:DK', 'without Jiberish Icons: the class-colour glyph')
	expect(art.color[1] > 0.7 and art.color[2] < 0.2, 'in the class colour')
	JiberishIcons = saved
	expectEq(Identity.Art(nil).kind .. ':' .. Identity.Art(nil).glyph, 'UNKNOWN:?', 'no class: unknown')
	expectEq(Identity.Art(HK_Secret('class')).kind, 'UNKNOWN', 'a hidden class: unknown (never read)')
	expectEq(Identity.Art('NOTACLASS').kind, 'UNKNOWN', 'an unknown token: unknown')
	-- painting: a glyph on a hub builds its parts once and needs no file
	local hub = Identity.Hub(UIParent, 50)
	JiberishIcons = nil
	expectEq(Identity.PaintArt(hub, Identity.Art('SHAMAN')), 'GLYPH', 'glyph')
	expectEq(hub.glyph.text, 'SH', 'the class\'s two letters')
	expectEq(hub.icon.shown, false, 'no icon texture shown')
	local disc = hub.glyphDisc
	Identity.PaintArt(hub, Identity.Art('PRIEST'))
	expectEq(hub.glyphDisc, disc, 'the glyph parts are reused')
	JiberishIcons = saved
	expectEq(Identity.PaintArt(hub, Identity.Art('SHAMAN')), 'FABLED', 'art again')
	expectEq(hub.glyph.shown, false, 'glyph hidden under real art')
	expectEq(hub.icon.path, JI_CLASS, 'the Fabled sheet')
end)

-- a BANZAI SPLIT session on fresh ElvUI frames (the game builds them anew after the reload that applies the style)
local splitFrames = {}
local function SplitSession()
	if splitFrames.player then return splitFrames end
	local function F(name, unit, healthLevel)
		local f = HK_NewFrame('Button', name, UIParent)
		f.unit = unit
		f.Health = HK_NewFrame('StatusBar', name .. 'Health', f)
		f.Health.level = healthLevel or 10
		f.Power = HK_NewFrame('StatusBar', name .. 'Power', f)
		f.Power.level = 8
		f.UpdateTags = function(self) self.tagUpdates = (self.tagUpdates or 0) + 1 end
		return f
	end
	splitFrames.player = F('ElvUF_Player', 'player')
	splitFrames.target = F('ElvUF_Target', 'target')
	splitFrames.focus = F('ElvUF_Focus', 'focus')
	splitFrames.tot = F('ElvUF_TargetTarget', 'targettarget')
	splitFrames.party1 = F('ElvUF_PartyGroup1UnitButton1', 'party1')
	splitFrames.party2 = F('ElvUF_PartyGroup1UnitButton2', 'party2')
	HK_UNITS.party1, HK_UNITS.party2 = 'PALADIN', 'SHAMAN'
	ElvUI[1].db.unitframe.units.player.customTexts['b-SplitName'] = { enable = true } -- the profile carries the split layer
	ElvUI[1].oUF.Tags.Methods['power:current:shortvalue'] = function() end
	Theme:DB().frameStyle = 'SPLIT'
	Split.session = nil
	ns.Compat:Build()
	ns.Compat:RefreshAll()
	return splitFrames
end

test('1.3.0 BANZAI SPLIT session: Player / Target / Focus as HEALTH <- HUB -> RESOURCE on ElvUI\'s own frames, the hub between the bars, smooth surfaces, no classic plates or bamboo, the small wordmark in combat', function()
	local f = SplitSession()
	expectEq(Split:Session(), true, 'the character chose SPLIT and its profile carries the layer')
	for _, key in ipairs({ 'player', 'target', 'focus', 'tot' }) do
		local art = 0
		for _, h in ipairs(HK_Children(f[key])) do if h.part then art = art + 1 end end
		expectEq(art, 0, key .. ': no Bushido plates / bamboo on the split frame')
	end
	for _, key in ipairs({ 'player', 'target', 'focus' }) do
		local entry = Split:Get(f[key]:GetName())
		local g = Split.Geometry(key)
		expect(entry and entry.hub, key .. ': a hub')
		expectEq(entry.hub.w, g.hub, key .. ': hub size')
		local p = entry.hub.points[1]
		expectEq(p[1] .. ' ' .. p[3] .. ' ' .. p[4], 'CENTER RIGHT ' .. g.inner, key .. ': centred where the health bar\'s right end meets it (the resource bar starts as far on the other side)')
		expectEq(p[2], f[key].Health, key .. ': on the ElvUI health bar')
		expect(entry.hub.level <= 95 and entry.hub.level > f[key].Health.level, key .. ': above the bars, under ElvUI\'s raised texts (100)')
		expectEq(entry.health.overlay.allPoints, f[key].Health.fill, key .. ': the gradient follows the health fill')
		expectEq(entry.health.overlay.masks, nil, key .. ': no mask (1.3.1 review: an empty bar\'s behaviour under a mask cannot be checked offline)')
		expectEq(entry.health.track.allPoints, f[key].Health, key .. ': a dark track under it')
		expect(entry.power and entry.power.overlay.allPoints == f[key].Power.fill, key .. ': the resource surface')
	end
	expectEq(Split.Geometry('player').hub, 62.5, 'Player hub 50 (1.3.3: 125 %, 62.5)')
	expectEq(Split.Geometry('player').inner, 21, 'bars meet the hub 8 under its edge (1.3.3: 10, the hub 125 %)')
	expect(Split.Geometry('focus').hub < Split.Geometry('target').hub and Split.Geometry('target').hub < Split.Geometry('player').hub, 'Focus < Target < Player')
	expect(Split.PARTY.circle < Split.Geometry('focus').hub + 5 and Split.PARTY.circle < Split.Geometry('player').hub * 0.7, 'party circles substantially smaller')
	-- the Player's identity: the class art (the druid's Fabled class icon), the class ring, the green -> purple accent
	local hub = Split:Get('ElvUF_Player').hub
	expectEq(hub.artKind, 'FABLED', 'idle: the class art')
	expectEq(hub.spell.shown, false, 'no spell while idle')
	local ring = hub.ring.gradient[3]
	expect(ring.r > ring.b, 'druid ring (orange family)')
	expectEq(hub.accent.gradient[1], 'VERTICAL', 'accent gradient')
	-- combat: the small wordmark stays (no combat logo between side-by-side frames that the split style has not)
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(_G.BanzaiCombatLogo.shown, false, 'no combat logo in a split session')
	HK_Fire('PLAYER_REGEN_ENABLED')
end)

test('1.3.0 HP inside the split bars (value at the outer end, percent beside the hub, clear of it), the resource the same way mirrored with ElvUI\'s power tags, ghosted over the empty part; both switchable', function()
	local f = SplitSession()
	local h = ns.Health:Get('ElvUF_Player')
	expect(h and h.def.split and h.def.splitStyle, 'split health definition')
	local g = Split.Geometry('player')
	-- 1.3.1 (Darren's runtime correction): the Player / Target texts above the bars, one copy; Focus keeps them inside
	expectEq(h.bright.value.points[1][1] .. ' ' .. h.bright.value.points[1][3] .. ' ' .. h.bright.value.points[1][4], 'BOTTOMLEFT TOPLEFT 0', '1.3.1: current HP above the outer (left) end')
	expectEq(h.bright.percent.points[1][1] .. ' ' .. h.bright.percent.points[1][3] .. ' ' .. h.bright.percent.points[1][4], 'BOTTOMRIGHT TOPRIGHT ' .. -(g.tuck + 4), '1.3.1: percent above the inner end, clear of the hub')
	expectEq(h.clip, nil, '1.3.1: above the bar nothing is clipped (one copy)')
	local focus = ns.Health:Get('ElvUF_Focus')
	expectEq(focus.clip.allPoints, f.focus.Health.fill, 'Focus: inside its bar, bright over the fill, ghosted over the empty part')
	local tags = {}
	for _, t in ipairs(f.player.tags) do tags[t[2]] = (tags[t[2]] or 0) + 1 end
	expectEq(tags[ns.Health.VALUE_TAG], 1, 'HP through ElvUI tags (nothing read)')
	expectEq(tags[ns.Health.PERCENT_TAG], 1, 'percent through ElvUI tags')
	expectEq(tags['[power:current:shortvalue]'], 1, 'resource value: ElvUI\'s power tag')
	expectEq(tags['[perpp<%]'], 1, 'resource percent: ElvUI\'s')
	local p = ns.Health:GetPower('ElvUF_Player')
	expectEq(p.holder.parent, f.player.Power, 'on the resource bar')
	expectEq(p.bright.value.points[1][1] .. ' ' .. p.bright.value.points[1][3] .. ' ' .. p.bright.value.points[1][4], 'BOTTOMRIGHT TOPRIGHT 0', '1.3.1: resource value above the outer (right) end')
	expectEq(p.bright.percent.points[1][1] .. ' ' .. p.bright.percent.points[1][3] .. ' ' .. p.bright.percent.points[1][4], 'BOTTOMLEFT TOPLEFT ' .. (g.tuck + 4), '1.3.1: resource percent above the end beside the hub')
	expectEq(h.holder.shown and p.holder.shown, true, 'both shown')
	ns.Compat:Set('splitHpText', false)
	expectEq(h.holder.shown, false, 'HP text off')
	ns.Compat:Set('splitHpText', true)
	ns.Compat:Set('splitPowerText', false)
	expectEq(p.holder.shown, false, 'resource text off')
	ns.Compat:Set('splitPowerText', true)
	expectEq(p.holder.shown, true, 'back')
	-- party: the value after the role icon, the percent at the right end
	local party = ns.Health:Get('ElvUF_PartyGroup1UnitButton1')
	expectEq(party.bright.value.points[1][1] .. ' ' .. party.bright.value.points[1][4], 'LEFT 4', 'party HP at the left end (the role icon is a badge on the circle)')
	expectEq(party.bright.percent.points[1][1] .. ' ' .. party.bright.percent.points[1][4], 'RIGHT -4', 'party percent at the right end')
	-- a power tag the installed ElvUI lacks is left out (never a made-up value)
	ElvUI[1].oUF.Tags.Methods['power:current:shortvalue'] = nil
	expectEq(ns.Health.PowerValueTag(), nil, 'neither power tag: no value text')
	ElvUI[1].oUF.Tags.Methods['power:current:shortvalue'] = function() end
end)

test('1.3.0 resources: the canonical colour family of each power type; an NPC with plainly no resource loses its resource side (a hidden maximum keeps it); NPC targets show their portrait, reaction ring, elite accent', function()
	local f = SplitSession()
	local target = Split:Get('ElvUF_Target')
	local function top(s) return s.overlay.gradient and s.overlay.gradient[3] end
	local function low(s) return s.overlay.gradient and s.overlay.gradient[2] end
	-- 1.3.1 (Darren's correction): the resource bar is in the unit's CLASS family whatever the resource type -
	-- the canonical class colour at its inner end, a deeper tone of it at its outer end
	HK_UNITS.target, HK_NPC.target = 'ROGUE', nil
	local rogue = Theme:ClassColor('ROGUE')
	for _, token in ipairs({ 'ENERGY', 'RAGE', 'FOCUS', 'MANA', 'SOMETHING_NEW' }) do
		HK_POWER.target = { token = token, max = 100 }
		Split:Paint(target)
		local a, b = low(target.power), top(target.power)
		expect(target.power.overlay.shown and math.abs(a.r - rogue[1]) < 0.01 and math.abs(a.g - rogue[2]) < 0.01, token .. ': the rogue\'s class colour at the inner end')
		expect(b.r < a.r and b.g < a.g and b.r > 0.25 and b.r > b.b, token .. ': deeper gold toward the outer end (never black)')
	end
	HK_POWER.target = { token = HK_Secret('token'), max = 100 } Split:Paint(target)
	expect(target.power.overlay.shown and math.abs(low(target.power).r - rogue[1]) < 0.01, 'a hidden type: still the class family (the type is never read)')
	-- an NPC without a resource
	HK_NPC.target, HK_UNITS.target, HK_REACTION.target = true, 'WARRIOR', 2
	HK_POWER.target = { token = 'MANA', max = 0 }
	HK_CLASSIFICATION.target = 'elite'
	HK_PORTRAITS = {}
	Split:Paint(target)
	expectEq(f.target.Power.alpha, 0, 'no resource: the resource side goes (no fake 100 %)')
	expectEq(ns.Health:GetPower('ElvUF_Target').holder.shown, false, 'and its texts')
	expectEq(target.hub.artKind, 'PORTRAIT', 'NPC: its portrait in the hub')
	expectEq(HK_PORTRAITS[#HK_PORTRAITS], 'target', 'drawn by the game for the unit')
	expect(target.hub.ring.gradient[3].r > 0.9 and target.hub.ring.gradient[3].g < 0.5 and target.hub.ring.gradient[3].b < 0.5, 'hostile: red ring')
	expect(target.hub.accent.gradient[3].r > 0.9 and target.hub.accent.gradient[3].b < 0.4, 'elite: gold accent')
	local hg = target.health.overlay.gradient[3]
	expect(hg.r > 0.9 and hg.g < 0.4, 'hostile reaction gradient on the health')
	HK_POWER.target = { token = 'MANA', max = HK_Secret('max') }
	Split:Paint(target)
	expectEq(f.target.Power.alpha, 1, 'a hidden maximum: the game\'s bar stays')
	HK_POWER.target = { token = 'MANA', max = 1200 }
	Split:Paint(target)
	expectEq(f.target.Power.alpha, 1, 'an NPC with mana keeps its resource side')
	HK_TAPPED.target = true Split:Paint(target)
	expect(math.abs(target.health.overlay.gradient[3].r - target.health.overlay.gradient[3].b) < 0.1, 'tapped: grey')
	HK_TAPPED.target, HK_NPC.target, HK_REACTION.target, HK_CLASSIFICATION.target, HK_POWER.target = nil, nil, nil, nil, nil
	HK_UNITS.target = 'MAGE'
	-- an offline party member keeps ElvUI's offline colour
	HK_OFFLINE.party1 = true
	Split:Refresh()
	expectEq(Split:Get('ElvUF_PartyGroup1UnitButton1').health.overlay.shown, false, 'offline: no class gradient over ElvUI\'s offline bar')
	HK_OFFLINE.party1 = nil
	Split:Refresh()
	expectEq(Split:Get('ElvUF_PartyGroup1UnitButton1').health.overlay.shown, true, 'online: the class gradient')
end)

test('1.3.0 cast transformation: the spell icon in the hub, the radial progress from the game\'s duration object, the spell name above, cast fills / channel and empower drain, INTERRUPTED / FAILED for a moment, then the class art', function()
	SplitSession()
	local hub = Split:Get('ElvUF_Focus').hub -- 1.3.3: the radial hub is Focus's (Player / Target: the bamboo cast bar)
	local cd = hub.progress
	expectEq(cd.kind, 'Cooldown', 'the game\'s Cooldown widget draws the ring')
	expectEq(cd.swipe, Identity.HUB_SWIPE, 'its swipe is the ring-shaped texture (the portrait stays visible)')
	HK_CASTS.focus = { kind = 'cast', name = 'Lava Burst', texture = 136048, start = 1000, finish = 3000, notInterruptible = false, duration = HK_Duration(1.4) }
	HK_Fire('UNIT_SPELLCAST_START', 'focus')
	expectEq(hub.spell.shown, true, 'casting: the spell icon fills the hub')
	expectEq(hub.spell.path, 136048, 'the game\'s icon, passed on')
	expectEq(cd.durationObject, HK_CASTS.focus.duration, 'radial progress: the game\'s duration object')
	expectEq(cd.reverse, true, 'a cast fills the ring')
	expectEq(cd.shown and hub.track.shown, true, 'progress on its dark track')
	local c = cd.swipeColor
	expect(c[1] > 0.9 and c[2] > 0.6 and c[3] < 0.1, 'cast colour: Banzai attention amber')
	expectEq(hub.castName.text, 'LAVA BURST', 'the spell name above the hub')
	expectEq(hub.castName.points[1][1] .. ' ' .. hub.castName.points[1][3], 'BOTTOM TOP', 'directly above')
	expectEq(hub.castTime.text, '1.4', 'the remaining time (the widget formats it)')
	expectEq(hub.clock.shown, true, 'the clock runs while a timed cast shows')
	expectEq(hub.lock.alpha, 0, 'interruptible: no lock ring')
	-- the cast ends: the class art again
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus')
	expectEq(hub.spell.shown, false, 'done: the spell goes')
	expectEq(cd.shown, false, 'the progress goes')
	expectEq(hub.castName.text, '', 'the name goes')
	expectEq(hub.clock.shown, false, 'the clock stops')
	expectEq(hub.ring.alpha, 1, 'the class ring back')
	-- a channel drains, an empower too, each in its colour
	HK_CASTS.focus = { kind = 'channel', name = 'Drain Life', texture = 1, duration = HK_Duration(2) }
	HK_Fire('UNIT_SPELLCAST_CHANNEL_START', 'focus')
	expectEq(cd.reverse, false, 'a channel drains')
	expect(cd.swipeColor[2] > 0.8 and cd.swipeColor[1] < 0.2, 'channel: Banzai emerald')
	HK_CASTS.focus = { kind = 'empower', name = 'Fire Breath', texture = 2, duration = HK_Duration(3) }
	HK_EMPOWER_CALLS = 0
	HK_Fire('UNIT_SPELLCAST_EMPOWER_START', 'focus')
	expectEq(HK_EMPOWER_CALLS, 1, 'empower: the empowered duration')
	expect(cd.swipeColor[3] > 0.9 and cd.swipeColor[1] < 0.7, 'empower: Banzai violet')
	-- interrupted: shown for a moment, then idle
	HK_CASTS.focus = { kind = 'cast', name = 'Lava Burst', texture = 3, duration = HK_Duration(1) }
	HK_Fire('UNIT_SPELLCAST_START', 'focus')
	HK_CASTS.focus = nil
	HK_TIMERS = {}
	HK_Fire('UNIT_SPELLCAST_INTERRUPTED', 'focus')
	expectEq(hub.castName.text, 'INTERRUPTED', 'INTERRUPTED')
	expectEq(hub.spell.desaturated, true, 'the spell greyed')
	expect(hub.ring.gradient[3].r > 0.9 and hub.ring.gradient[3].g < 0.3, 'a red ring')
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus')
	expectEq(hub.castName.text, 'INTERRUPTED', 'the stop after it does not cut the moment short')
	HK_RunTimers()
	expectEq(hub.castName.text, '', 'then idle')
	expectEq(hub.spell.shown, false, 'class art again')
	-- a stop first and the interrupt right after: still that cast's interrupt
	HK_CASTS.focus = { kind = 'cast', name = 'Lava Burst', texture = 3, duration = HK_Duration(1) }
	HK_Fire('UNIT_SPELLCAST_START', 'focus')
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus')
	HK_NOW = HK_NOW + 0.1
	HK_Fire('UNIT_SPELLCAST_INTERRUPTED', 'focus')
	expectEq(hub.castName.text, 'INTERRUPTED', 'within the grace: the cast\'s interrupt')
	-- a newer cast owns the hub before the moment ends
	HK_CASTS.focus = { kind = 'cast', name = 'Healing Surge', texture = 4, duration = HK_Duration(1.5) }
	HK_Fire('UNIT_SPELLCAST_START', 'focus')
	HK_RunTimers()
	expectEq(hub.castName.text, 'HEALING SURGE', 'the late timer leaves the new cast alone')
	-- a failed attempt while casting (another action in progress): the cast goes on
	HK_Fire('UNIT_SPELLCAST_FAILED', 'focus')
	expectEq(hub.castName.text, 'HEALING SURGE', 'still casting: the failed attempt changes nothing')
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus')
	HK_NOW = HK_NOW + 5
	HK_Fire('UNIT_SPELLCAST_FAILED', 'focus')
	expectEq(hub.castName.text, '', 'a failed attempt while idle: nothing claimed')
	HK_RunTimers()
end)

test('1.3.0 secret values: hidden cast name / icon / times / flag are handed to the widgets unread - no progress invented without the game\'s duration, the lock ring through SetAlphaFromBoolean, a hidden remaining time formatted by the font string; hidden unit tokens never compared', function()
	SplitSession()
	local hub = Split:Get('ElvUF_Focus').hub -- 1.3.3: the radial hub is Focus's
	local name, icon, ni = HK_Secret('name'), HK_Secret('icon'), HK_Secret('notInterruptible')
	HK_CASTS.focus = { kind = 'cast', name = name, texture = icon, start = HK_Secret('start'), finish = HK_Secret('finish'), notInterruptible = ni }
	HK_Fire('UNIT_SPELLCAST_START', 'focus')
	expectEq(hub.spell.path, icon, 'the hidden icon on the hub, unread')
	expectEq(hub.castName.text, name, 'the hidden name on the font string, unread (no case change)')
	expectEq(hub.progress.shown, false, 'no duration object and hidden times: no progress drawn (nothing invented)')
	expectEq(hub.timed, false, 'an honest active cast')
	expect(hub.ring.gradient[3].r > 0.9 and hub.ring.gradient[3].g > 0.6, 'the ring says "casting" in the cast colour')
	expectEq(hub.lock.alphaBoolean, ni, 'the hidden flag handed to SetAlphaFromBoolean')
	expectEq(hub.lock.alpha, 'from-secret', 'never tested')
	-- a duration object whose remaining time is hidden
	local remaining = HK_Secret('remaining')
	HK_CASTS.focus = { kind = 'cast', name = 'Pyroblast', texture = 5, duration = HK_Duration(remaining), notInterruptible = true }
	HK_Fire('UNIT_SPELLCAST_DELAYED', 'focus')
	expectEq(hub.progress.shown, true, 'the game\'s duration object: progress drawn')
	expectEq(hub.castTime.text, remaining, 'the hidden remaining time formatted by the font string')
	expectEq(hub.lock.alpha, 1, 'a plain non-interruptible cast: the lock ring')
	-- an event whose unit token is hidden is never compared (per-unit registration)
	HK_Fire('UNIT_FACTION', HK_Secret('unit'))
	HK_Fire('UNIT_TARGET', HK_Secret('unit'))
	-- the readers never look inside hidden values
	expectEq(Split.ReadCast('focus').name, 'Pyroblast', 'plain values read as usual')
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus')
	expectEq(hub.spell.shown, false, 'idle again')
	-- a new target resets the hub at once
	HK_CASTS.focus = { kind = 'channel', name = 'Mind Flay', texture = 6, duration = HK_Duration(2) }
	HK_Fire('PLAYER_FOCUS_CHANGED')
	expectEq(hub.castName.text, 'MIND FLAY', 'the new focus\'s cast')
	HK_CASTS.focus = nil
	HK_Fire('PLAYER_FOCUS_CHANGED')
	expectEq(hub.spell.shown, false, 'a focus that is not casting: idle')
end)

test('1.3.0 party / arena allies in BANZAI SPLIT: the identity circle (32) in the middle of the bar with the art chain, no classic outside circle, the trinket circle kept; Focus has a hub instead of a circle', function()
	local f = SplitSession()
	local c = Identity:Get('ElvUF_PartyGroup1UnitButton1')
	expect(c and c.split, 'party: a split circle')
	expectEq(c.w, Split.PARTY.circle, 'size 32')
	expectEq(c.points[1][1] .. ' ' .. c.points[1][3], 'CENTER CENTER', 'in the middle of the bar')
	expectEq(c.points[1][2], f.party1.Health, 'on the health bar')
	Identity:Refresh()
	expectEq(c.shown, true, 'shown')
	expectEq(c.artKind, 'FABLED', 'the art chain (Fabled today)')
	ns.Compat:Set('identityCircles', false)
	expectEq(c.shown, true, 'part of the split construction: the classic circle option does not hide it')
	ns.Compat:Set('identityCircles', true)
	expectEq(Identity:Get('ElvUF_Focus'), nil, 'Focus: no classic circle (its hub)')
	expect(ns.PvPFrames:Get('ElvUF_PartyGroup1UnitButton1') and ns.PvPFrames:Get('ElvUF_PartyGroup1UnitButton1').trinket, 'the trinket circle stays')
	-- arena enemies: untouched classic circles
	expect(Identity:Get('ElvUF_Arena1') and not Identity:Get('ElvUF_Arena1').split, 'arena enemy circle: classic')
end)

test('1.3.0 enhanced targeted nameplate: only the current target\'s plate, only in a split session with its switch, a hub at the bar\'s left that takes the target\'s casts, a green -> purple outline; other plates unchanged', function()
	SplitSession()
	local TP = ns.TargetPlate
	local function Plate(kind)
		local uf = HK_NewFrame('Frame', nil, UIParent)
		uf.frameType = kind
		uf.Health = HK_NewFrame('StatusBar', nil, uf)
		uf.Health.level = 10
		uf.Health.Text = uf.Health:CreateFontString()
		return { unitFrame = uf }, uf
	end
	local plateA, a = Plate('ENEMY_PLAYER')
	local plateB, b = Plate('ENEMY_NPC')
	HK_PLATES.target = plateA
	HK_UNITS.target = 'WARLOCK'
	TP:Update()
	local deco = TP:Get(a)
	expect(deco and deco.hub, 'the target\'s plate: a hub')
	expectEq(deco.hub.shown and deco.outline.shown, true, 'hub and outline shown')
	expectEq(deco.hub.points[1][1] .. ' ' .. deco.hub.points[1][3], 'RIGHT LEFT', 'at the bar\'s left end')
	expectEq(deco.hub.artKind, 'FABLED', 'enemy player: the class art')
	expect(deco.overlay.shown and deco.health.holder.shown, 'the targeted-plate treatment (gradient, HP, percent) under it')
	-- the target casts: frame hub and plate hub together
	HK_CASTS.target = { kind = 'cast', name = 'Chaos Bolt', texture = 7, duration = HK_Duration(2) }
	HK_Fire('UNIT_SPELLCAST_START', 'target')
	expectEq(deco.hub.spell.shown, true, 'the plate hub shows the cast')
	expectEq(Split:Get('ElvUF_Target').hub.spell.shown, true, 'so does the Target frame')
	HK_CASTS.target = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'target')
	expectEq(deco.hub.spell.shown, false, 'both idle again')
	-- another plate becomes the target: the first loses everything
	HK_PLATES.target = plateB
	HK_NPC.target, HK_REACTION.target = true, 2
	TP:Update()
	expectEq(deco.hub.shown, false, 'the old plate: no hub')
	expectEq(deco.outline.shown, false, 'no outline')
	local deco2 = TP:Get(b)
	expectEq(deco2.hub.artKind, 'PORTRAIT', 'NPC target plate: its portrait')
	-- a plate that never was the target has nothing
	local _, c = Plate('ENEMY_NPC')
	expectEq(TP:Get(c), nil, 'other plates untouched')
	-- the switch
	ns.Compat:Set('splitTargetPlate', false)
	expectEq(deco2.hub.shown, false, 'enhanced plate off: no hub')
	expect(deco2.overlay.shown, 'the approved targeted-plate treatment stays')
	ns.Compat:Set('splitTargetPlate', true)
	expectEq(deco2.hub.shown, true, 'on again')
	HK_PLATES.target, HK_NPC.target, HK_REACTION.target = nil, nil, nil
	HK_UNITS.target = 'MAGE'
	TP:Update()
end)

test('1.3.0 no duplicates: repeated builds, refreshes, theme and setting changes keep one hub per frame, one watcher per unit, one set of texts', function()
	SplitSession()
	local before = Split:Counts()
	expectEq(before.watchers, 3, 'player, target, focus')
	for _ = 1, 3 do
		ns.Compat:Build()
		ns.Compat:RefreshAll()
		Split:Build()
		ns.Compat:SetTheme('class') ns.Compat:SetTheme('vibrant')
		Identity:Refresh()
	end
	local after = Split:Counts()
	expectEq(after.entries .. '/' .. after.hubs .. '/' .. after.watchers, before.entries .. '/' .. before.hubs .. '/' .. before.watchers, 'nothing duplicated')
	expectEq(before.hubs, 3, 'three hubs (Player, Target, Focus)')
	local tags = 0
	for _, t in ipairs(splitFrames.player.tags) do if t[2] == '[perpp<%]' then tags = tags + 1 end end
	expectEq(tags, 1, 'the resource percent tagged once (1.3.1: one copy above the bar)')
	expectEq(#HK_HOOKS, 0, 'no hook')
end)

test('1.3.0 preview: a style selector; BANZAI SPLIT samples (Player idle / casting / channeling, Target player and NPC, Focus, ToT, DPS / HEALER party, the enhanced nameplate) labelled SAMPLE DATA, non-secure, hidden in combat; CLASSIC samples as before', function()
	SplitSession()
	local P = ns.Preview
	expectEq(P:Style(), 'SPLIT', 'by default the session\'s style')
	P:HideAll()
	expect(P:Show('player', true), 'player sample')
	local c = P:Get('player')
	expect(c and c.split, 'a split container')
	local u = c.units[1]
	expect(u.hub and u.Health and u.Power, 'health <- hub -> resource')
	expectEq(u.Health.points[1][1] .. ' ' .. u.Health.points[1][3], 'RIGHT CENTER', 'health left of the hub')
	expectEq(u.Power.points[1][1] .. ' ' .. u.Power.points[1][3], 'LEFT CENTER', 'resource right of it')
	P:SetState('CASTING')
	expectEq(u.hub.spell.shown, true, 'CASTING: the spell in the hub')
	expect(u.castBar.shown and u.castBar.status.value == 0.62 and u.castBar.status.timer == nil, 'a synthetic progress at a fixed point (not a live cast) - 1.3.3: on the bamboo cast bar')
	expectEq(u.hub.progress, nil, '1.3.3: no radial progress on the Player hub')
	expect(string.find(HK_Plain(c.title.text), 'SAMPLE DATA', 1, true), 'labelled SAMPLE DATA')
	P:SetState('CHANNELING')
	expectEq(u.castBar.status.value, 0.40, 'CHANNELING: drains (1.3.3: what remains, on the bar)')
	P:SetState('NORMAL')
	expectEq(u.hub.spell.shown, false, 'NORMAL: idle')
	for _, key in ipairs({ 'target', 'targetNPC', 'focus', 'targettarget', 'party', 'nameplate' }) do
		expect(P:Show(key, true), key .. ' sample')
		expect(P:Get(key) and P:Get(key).split, key .. ': split container')
	end
	expectEq(P:Get('targetNPC').units[1].hub.artKind, 'CREST', 'the NPC sample: a creature stand-in in the hub (1.3.3: Banzai\'s own NPC crest)')
	expectEq(P:Get('targetNPC').units[1].Power, nil, 'NPC sample: no resource side')
	expect(P:Get('nameplate').units[1].hub and P:Get('nameplate').units[1].outline, 'nameplate sample: hub and outline')
	local party = P:Get('party')
	expectEq(party.role, 'DPS', 'DPS layout')
	expectEq(#party.units, 5, 'five members')
	expectEq(party.units[1].circle.points[1][1], 'CENTER', 'circle in the middle of the bar')
	P:SetRole('HEALER')
	expectEq(P:Get('party').role, 'HEALER', 'HEALER row rebuilt')
	P:SetRole('DPS')
	P:SetState('DEAD')
	expectEq(HK_Plain(P:Get('party').units[2].status.text), 'Dead', 'dead above the circle, the name kept')
	P:SetState('NORMAL')
	-- nothing secure, nothing clickable
	for _, f in ipairs(HK_Frames()) do
		if type(f.name) == 'string' and string.find(f.name, '^BanzaiPreviewSplit_') then expect(not f.mouse, f.name .. ': not clickable') end
	end
	-- combat hides every sample
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(P:AnyShown(), false, 'hidden in combat')
	HK_Fire('PLAYER_REGEN_ENABLED')
	-- the classic samples on demand, as before
	P:Show('player', true)
	P:SetStyle('CLASSIC')
	expectEq(P:Get('player').split, nil, 'CLASSIC: the classic sample')
	expectEq(P:IsShown('player'), true, 'moved over')
	expectEq(P:Show('nameplate', true), false, 'no split-only sample in CLASSIC')
	P:HideAll()
	P.style = nil
end)

test('1.3.0 the split session ends cleanly: off the Banzai profile nothing shows, the resource sides are back', function()
	local f = SplitSession()
	HK_ElvData.current = 'HARDKORHUI'
	ns.Compat:RefreshAll()
	expectEq(Split:Get('ElvUF_Player').hub.shown, false, 'no hub off the Banzai profile')
	expectEq(f.target.Power.alpha, 1, 'resource bars back to ElvUI')
	HK_ElvData.current = NAME
	ns.Compat:RefreshAll()
	expectEq(Split:Get('ElvUF_Player').hub.shown, true, 'back on the Banzai profile')
end)

test('1.3.0 review: interrupted channels / empowers (the stop event says who interrupted), the cast bar ID when the game gives it plainly, no false FAILED after a finished cast, empowers fill, a repaint keeps the cast / failure ring', function()
	SplitSession()
	local hub = Split:Get('ElvUF_Focus').hub -- 1.3.3: the radial hub is Focus's
	-- a channel kicked: CHANNEL_STOP carries interruptedBy (plain or hidden) - INTERRUPTED
	for _, by in ipairs({ 'Player-99', HK_Secret('interruptedBy') }) do
		HK_CASTS.focus = { kind = 'channel', name = 'Penance', texture = 8, duration = HK_Duration(2), barID = 21 }
		HK_Fire('UNIT_SPELLCAST_CHANNEL_START', 'focus', 'guid', 47540, 21)
		HK_CASTS.focus = nil
		HK_Fire('UNIT_SPELLCAST_CHANNEL_STOP', 'focus', 'guid', 47540, by, 21)
		expectEq(hub.castName.text, 'INTERRUPTED', 'a kicked channel: INTERRUPTED')
		HK_RunTimers()
		expectEq(hub.castName.text, '', 'then idle')
	end
	-- a channel that ends by itself
	HK_CASTS.focus = { kind = 'channel', name = 'Penance', texture = 8, duration = HK_Duration(2), barID = 22 }
	HK_Fire('UNIT_SPELLCAST_CHANNEL_START', 'focus', 'guid', 47540, 22)
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_CHANNEL_STOP', 'focus', 'guid', 47540, nil, 22)
	expectEq(hub.castName.text, '', 'a channel that ran out: idle, nothing claimed')
	-- an empower kicked (EMPOWER_STOP: complete, interruptedBy)
	HK_CASTS.focus = { kind = 'empower', name = 'Fire Breath', texture = 9, duration = HK_Duration(3), barID = 23 }
	HK_Fire('UNIT_SPELLCAST_EMPOWER_START', 'focus', 'guid', 357208, 23)
	expectEq(hub.progress.reverse, true, 'an empower fills its ring while it charges (as ElvUI\'s own cast bar)')
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_EMPOWER_STOP', 'focus', 'guid', 357208, false, 'Player-98', 23)
	expectEq(hub.castName.text, 'INTERRUPTED', 'a kicked empower: INTERRUPTED')
	HK_RunTimers()
	-- the client still reports the cast while INTERRUPTED arrives: the matching cast bar ID decides
	HK_CASTS.focus = { kind = 'cast', name = 'Frostbolt', texture = 10, duration = HK_Duration(1.5), barID = 31 }
	HK_Fire('UNIT_SPELLCAST_START', 'focus', 'guid', 116, 31)
	HK_Fire('UNIT_SPELLCAST_INTERRUPTED', 'focus', 'guid', 116, 'Player-97', 31)
	expectEq(hub.castName.text, 'INTERRUPTED', 'the same cast bar: INTERRUPTED even before the cast is gone')
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus', 'guid', 116, 31)
	expectEq(hub.castName.text, 'INTERRUPTED', 'the stop after it keeps the moment')
	-- a repaint (faction / portrait / plate update) during the moment keeps the red ring
	Split:Paint(Split:Get('ElvUF_Focus'))
	expect(hub.ring.gradient[3].r > 0.9 and hub.ring.gradient[3].g < 0.3, 'repainted: still the red ring')
	HK_RunTimers()
	-- another cast's FAILED (a different, plain cast bar) never touches the running cast
	HK_CASTS.focus = { kind = 'cast', name = 'Frostbolt', texture = 10, duration = HK_Duration(1.5), barID = 41 }
	HK_Fire('UNIT_SPELLCAST_START', 'focus', 'guid', 116, 41)
	HK_CASTS.focus = nil -- (even if the client briefly says nothing)
	HK_Fire('UNIT_SPELLCAST_FAILED', 'focus', 'guid', 2139, 42)
	expectEq(hub.castName.text, 'FROSTBOLT', 'a failed attempt of another cast bar: the cast stays')
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus', 'guid', 116, 41)
	-- a finished cast, then within a moment a failed attempt (cooldown, resource, moving): no FAILED
	HK_CASTS.player = { kind = 'cast', name = 'Lava Burst', texture = 3, duration = HK_Duration(1), barID = 51 }
	HK_Fire('UNIT_SPELLCAST_START', 'player', 'guid', 51505, 51)
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'player', 'guid', 51505, 51)
	HK_Fire('UNIT_SPELLCAST_STOP', 'player', 'guid', 51505, 51)
	HK_NOW = HK_NOW + 0.1
	HK_Fire('UNIT_SPELLCAST_FAILED', 'player', 'guid', 8042, 52)
	expectEq(Split:Get('ElvUF_Player').hub.castName.text, '', 'no false FAILED over a spell that succeeded')
	HK_Fire('UNIT_SPELLCAST_FAILED', 'player', 'guid', 8042, HK_Secret('bar'))
	expectEq(Split:Get('ElvUF_Player').hub.castName.text, '', 'nor with a hidden cast bar ID (never compared)')
	-- an untimed cast keeps its cast-colour ring through a repaint
	HK_CASTS.focus = { kind = 'cast', name = HK_Secret('n'), texture = 11, start = HK_Secret('s'), finish = HK_Secret('f') }
	HK_Fire('UNIT_SPELLCAST_START', 'focus', 'guid', 1, HK_Secret('bar'))
	Split:Paint(Split:Get('ElvUF_Focus'))
	expect(hub.ring.gradient[3].r > 0.9 and hub.ring.gradient[3].g > 0.6 and hub.ring.gradient[3].b < 0.1, 'repainted: still the cast colour')
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus', 'guid', 1, HK_Secret('bar'))
	HK_RunTimers()
end)

test('1.3.0 review: with the targeted-plate treatment switched off, a split session\'s enhanced plate adds only its hub and outline (ElvUI\'s own plate text and colour stay)', function()
	SplitSession()
	local TP = ns.TargetPlate
	local uf = HK_NewFrame('Frame', nil, UIParent)
	uf.frameType = 'ENEMY_PLAYER'
	uf.Health = HK_NewFrame('StatusBar', nil, uf)
	uf.Health.level = 10
	uf.Health.Text = uf.Health:CreateFontString()
	HK_PLATES.target = { unitFrame = uf }
	HK_UNITS.target = 'WARLOCK'
	ns.Compat:Set('targetPlate', false)
	TP:Update()
	local deco = TP:Get(uf)
	expectEq(deco.hub.shown and deco.outline.shown, true, 'the enhanced hub and outline')
	expectEq(deco.overlay.shown, false, 'no Banzai gradient (the treatment is off)')
	expectEq(deco.health.holder.shown, false, 'no Banzai texts')
	expectEq(uf.Health.Text.alpha, 1, 'ElvUI\'s own health text stays')
	ns.Compat:Set('targetPlate', true)
	expectEq(deco.overlay.shown and deco.health.holder.shown, true, 'on again: the whole composition')
	HK_PLATES.target = nil
	HK_UNITS.target = 'MAGE'
	TP:Update()
end)
---------------------------------------------------------------------------
-- 1.3.1 BANZAI SPLIT runtime correction, Want Coffee typography
---------------------------------------------------------------------------
-- the 1.3.1 split layer: Banzai Art draws the Player / Target name and spec lines (the profile's b-SplitName is its marker)
local function SplitLines()
	local f = SplitSession()
	ElvUI[1].db.unitframe.units.player.customTexts['b-SplitName'] = { enable = false, banzaiSplit = true, banzaiSpec = true }
	for _, key in ipairs({ 'player', 'target' }) do Split.BuildLines(Split:Get(f[key]:GetName())) end
	return f
end

local function near(a, b, eps) return math.abs(a - b) < (eps or 0.01) end
local function rgb(c) return c.r and { c.r, c.g, c.b } or c end

test('1.3.1 root cause of the 1.3.0 white bars: a hub\'s cast texts have a font from the start (the game refuses SetText without one); an idle hub that never cast repaints; one faulty frame no longer leaves the others unpainted', function()
	SplitSession()
	-- the 1.3.0 fault as the game shows it (the mock is as strict as the client)
	local bare = UIParent:CreateFontString(nil, 'OVERLAY')
	local ok, err = pcall(bare.SetText, bare, '')
	expect(not ok and string.find(tostring(err), 'Font not set', 1, true), 'a font string without a font: "Font not set" (what stopped the 1.3.0 first paint)')
	local hub = Identity.Hub(UIParent, 50)
	expect(hub.castName.font and hub.castTime.font, 'a new hub: both cast texts have a font')
	expect(pcall(Split.Idle, hub), 'idle on a hub that never cast: no error')
	-- fault isolation: one entry that cannot be painted, the others still are
	local target = Split:Get('ElvUF_Target')
	local saved = target.hub.castName.font
	target.hub.castName.font = nil -- the 1.3.0 hub
	HK_UNITS.player = 'MONK'
	Split.lastError = nil
	Split:Refresh()
	local player = Split:Get('ElvUF_Player')
	expectEq(player.health.overlay.shown, true, 'the Player is painted whatever happens to another frame')
	expectEq(player.hub.artKind, 'FABLED', 'the Player hub shows its class art (1.3.0: an empty disc)')
	expect(Split.lastError and string.find(Split.lastError, 'Font not set', 1, true), 'the fault is kept for /banzai status')
	target.hub.castName.font = saved
	Split.lastError = nil
	Split:Refresh()
	expectEq(Split.lastError, nil, 'no fault left')
	HK_UNITS.player = 'DRUID'
	Split:Refresh()
end)

test('1.3.1 Mistweaver: Health AND Mana in the Monk class family (jade -> turquoise), one continuous composition through the hub - lighter at the health bar\'s outer end, the canonical colour at both inner ends, deeper at the resource bar\'s outer end; opaque, over the whole bar', function()
	local f = SplitSession()
	HK_UNITS.player = 'MONK'
	HK_POWER.player = { token = 'MANA', max = 250000 }
	local player = Split:Get('ElvUF_Player')
	Split:Paint(player)
	local monk = Theme:ClassColor('MONK')
	local h, p = player.health.overlay.gradient, player.power.overlay.gradient
	expectEq(h[1] .. ' ' .. p[1], 'HORIZONTAL HORIZONTAL', 'horizontal gradients')
	local hFrom, hTo, pFrom, pTo = rgb(h[2]), rgb(h[3]), rgb(p[2]), rgb(p[3])
	expect(near(hTo[1], monk[1]) and near(hTo[2], monk[2]) and near(hTo[3], monk[3]), 'health: the canonical Monk colour at its inner end')
	expect(near(pFrom[1], monk[1]) and near(pFrom[2], monk[2]) and near(pFrom[3], monk[3]), 'resource: the canonical Monk colour at its inner end (the composition is continuous through the hub)')
	expect(hFrom[2] > 0.95 and hFrom[1] > hTo[1] and hFrom[3] < hFrom[2], 'health outer end: a lighter jade (never white)')
	expect(pTo[2] < 0.7 and pTo[2] > 0.35 and pTo[3] > pTo[2] * 0.6 and pTo[1] < 0.1, 'resource outer end: a deeper turquoise (never black)')
	expect(not (pFrom[3] > 0.9 and pFrom[1] < 0.4 and pFrom[2] < 0.6), 'never mana blue')
	expectEq(h[2].a .. ' ' .. p[3].a, '1 1', 'opaque: crisp, ElvUI\'s own fill never shows through')
	expectEq(player.health.overlay.allPoints, f.player.Health.fill, 'on the game\'s own fill (it follows the value; nothing read)')
	-- the hub: the strongest class identity, the thin BANZAI accent kept
	local ring = rgb(player.hub.ring.gradient[3])
	expect(ring[2] > ring[1] and ring[2] > 0.9, 'the hub ring in the Monk colour')
	expectEq(player.hub.accent.gradient[1], 'VERTICAL', 'the green -> purple accent stays')
	-- a Druid, a Paladin, a Rogue, a Death Knight, a Mage: their own family on both bars
	for _, class in ipairs({ 'DRUID', 'PALADIN', 'ROGUE', 'DEATHKNIGHT', 'MAGE' }) do
		HK_UNITS.player = class
		Split:Paint(player)
		local c = Theme:ClassColor(class)
		local a, b = rgb(player.health.overlay.gradient[3]), rgb(player.power.overlay.gradient[2])
		expect(near(a[1], c[1]) and near(a[2], c[2]) and near(b[1], c[1]) and near(b[3], c[3]), class .. ': both bars meet in the class colour')
	end
	HK_UNITS.player, HK_POWER.player = 'DRUID', nil
	Split:Paint(player)
end)

test('1.3.1 class families for every class: the canonical colour in the middle, a lighter end and a deeper end of the same hue, saturation kept, no white for a known class, no black end', function()
	for _, class in ipairs({ 'DEATHKNIGHT', 'DEMONHUNTER', 'DRUID', 'EVOKER', 'HUNTER', 'MAGE', 'MONK', 'PALADIN', 'PRIEST', 'ROGUE', 'SHAMAN', 'WARLOCK', 'WARRIOR' }) do
		local c = Theme:ClassColor(class)
		local r = Theme.Ramp(c)
		if class == 'PRIEST' then -- 1.3.1 review: white -> silver -> deeper silver, never one flat white
			expect(r.bright[1] > 0.95 and r.base[1] < 0.9 and r.base[3] > r.base[1] and r.deep[1] < r.base[1], 'PRIEST: white -> silver -> deeper silver')
		else
			expect(near(r.base[1], c[1], 0.001) and near(r.base[2], c[2], 0.001) and near(r.base[3], c[3], 0.001), class .. ': the canonical colour in the middle')
		end
		local lb, lc, ld = r.bright[1] + r.bright[2] + r.bright[3], c[1] + c[2] + c[3], r.deep[1] + r.deep[2] + r.deep[3]
		expect(lb >= lc - 0.01 and ld < lc, class .. ': lighter -> canonical -> deeper')
		expect(math.max(r.deep[1], r.deep[2], r.deep[3]) > 0.3, class .. ': the deep end is not black')
		if class ~= 'PRIEST' then
			expect(not (r.bright[1] > 0.97 and r.bright[2] > 0.97 and r.bright[3] > 0.97), class .. ': the light end is not white')
			local maxc, minc = math.max(unpack(c)), math.min(unpack(c))
			local maxb, minb = math.max(unpack(r.bright)), math.min(unpack(r.bright))
			expect((maxb - minb) > 0.55 * (maxc - minc), class .. ': saturation kept (no pastel wash-out)')
		end
	end
	-- the hue leans: Druid amber -> orange, Rogue yellow -> gold, Mage cyan -> blue, Death Knight red -> burgundy
	local druid = Theme.Ramp(Theme:ClassColor('DRUID'))
	expect(druid.bright[2] / druid.bright[1] > 0.55 and druid.deep[2] / druid.deep[1] < 0.45, 'Druid: amber light end, deep orange')
	local mage = Theme.Ramp(Theme:ClassColor('MAGE'))
	expect(mage.bright[2] / mage.bright[3] > mage.deep[2] / mage.deep[3], 'Mage: cyan light end, blue deep end')
	local dk = Theme.Ramp(Theme:ClassColor('DEATHKNIGHT'))
	expect(dk.deep[3] > dk.deep[2] and dk.deep[1] > dk.deep[3], 'Death Knight: a burgundy deep end')
	-- no white fallback for a known class (1.3.0's white bars): the class decides, never the default
	expect(not (Theme:ClassColor('MONK')[1] > 0.9 and Theme:ClassColor('MONK')[3] > 0.9), 'Monk: not white')
end)

test('1.3.1 Player / Target texts: HP and percentage ABOVE the health bar, resource percentage and value ABOVE the resource bar (mirrored), NAME under the health bar from its outer end, SPEC under the resource bar to its outer end - Banzai Art\'s own lines, clear of the hub', function()
	local f = SplitLines()
	local function pt(fs) local p = fs.points[1] return p[1] .. ' ' .. p[3] .. ' ' .. p[4] .. ' ' .. p[5] end
	local h, p = ns.Health:Get('ElvUF_Player'), ns.Health:GetPower('ElvUF_Player')
	local g = Split.Geometry('player')
	expectEq(pt(h.bright.value), 'BOTTOMLEFT TOPLEFT 0 2', 'current HP over the outer (left) end')
	expectEq(pt(h.bright.percent), 'BOTTOMRIGHT TOPRIGHT ' .. -(g.tuck + 4) .. ' 2', 'HP % over the inner end, clear of the hub')
	expectEq(pt(p.bright.percent), 'BOTTOMLEFT TOPLEFT ' .. (g.tuck + 4) .. ' 2', 'resource % over its inner end')
	expectEq(pt(p.bright.value), 'BOTTOMRIGHT TOPRIGHT 0 2', 'resource value over its outer (right) end')
	expectEq(h.bright.value.font, SHOJUMARU_PATH, 'the HP number in Shojumaru')
	expectEq(h.bright.percent.font, Theme:SmallFont(), 'the compact percentage in the small font')
	for _, key in ipairs({ 'player', 'target' }) do
		local entry = Split:Get(f[key]:GetName())
		local lines = entry.lines
		local gk = Split.Geometry(key)
		expect(lines and lines.name and lines.specText, key .. ': name and spec lines')
		local n, s = lines.name.points[1], lines.specText.points[1]
		expectEq(n[1] .. ' ' .. tostring(n[2] == f[key].Health) .. ' ' .. n[3], 'TOPLEFT true BOTTOMLEFT', key .. ': NAME under the health bar from its outer (left) end')
		expectEq(s[1] .. ' ' .. tostring(s[2] == f[key].Power) .. ' ' .. s[3], 'TOPRIGHT true BOTTOMRIGHT', key .. ': SPEC under the resource bar to its outer (right) end')
		expectEq(lines.name.justify .. ' ' .. lines.specText.justify, 'LEFT RIGHT', key .. ': left- / right-justified')
		expect(lines.name.w <= gk.bar - gk.tuck, key .. ': never under the hub (width)')
		expectEq(lines.name.wordWrap, false, key .. ': one line')
		expectEq(lines.name.font, SHOJUMARU_PATH, key .. ': Shojumaru')
		expectEq(lines.name.fontFlags, 'OUTLINE', key .. ': outlined')
		expect(lines.name.shadow and lines.name.shadow[1] == 1, key .. ': with a shadow')
		local tags = {}
		for _, t in ipairs(f[key].tags) do tags[t[2]] = t[1] end
		expectEq(tags['[banzai:split:name]'], lines.name, key .. ': the name through ElvUI\'s tag system')
		expectEq(tags['[banzai:split:spec]'], lines.specText, key .. ': the spec through it')
	end
	expectEq(Split.BuildLines(Split:Get('ElvUF_Player')), Split:Get('ElvUF_Player').lines, 'built once')
	-- a 1.3.0 layer (ElvUI's own centred line still in the profile) gets no second line
	ElvUI[1].db.unitframe.units.player.customTexts['b-SplitName'] = { enable = true }
	expectEq(Split.ProfileLines(), false, 'the old layer: ElvUI\'s line, no Banzai line on top')
	expectEq(Split.ProfileSplit(), true, 'still a split profile')
	ElvUI[1].db.unitframe.units.player.customTexts['b-SplitName'] = { enable = false, banzaiSplit = true, banzaiSpec = true }
	expectEq(select(2, Split.ProfileLines()), true, 'the spec line on, as the marker says')
end)

test('1.3.1 the identity tags: [banzai:split:name] the BANZAI green -> purple gradient over the name in capitals (a hidden name passes through unread); [banzai:split:spec] the reliably known spec in the class family - nothing for an NPC, an unknown spec or a hidden class', function()
	SplitLines()
	local nameTag, specTag = HK_TAGS['banzai:split:name'], HK_TAGS['banzai:split:spec']
	expect(nameTag and specTag, 'both registered through ElvUI\'s E:AddTag')
	HK_PLAYER_NAME = 'Darrensmonky'
	local text = nameTag.fn('player')
	expectEq(HK_Plain(text), 'DARRENSMONKY', 'the name in capitals')
	local first, last = string.match(text, '^|cff(%x%x%x%x%x%x)'), string.match(text, '|cff(%x%x%x%x%x%x)Y|r$')
	expectEq(first, Theme:Hex(Theme.COLORS.lime), 'starts green')
	expectEq(last, Theme:Hex(Theme.COLORS.purple), 'ends purple')
	local savedName = UnitName
	local secret = HK_Secret('name')
	UnitName = function() return secret end
	expectEq(nameTag.fn('target'), secret, 'a hidden name: handed on as it is (never read)')
	UnitName = savedName
	HK_PLAYER_NAME = 'Darrensdrood'
	HK_UNITS.player = 'MONK'
	local spec = specTag.fn('player')
	expectEq(HK_Plain(spec), 'FERAL', 'the player\'s own spec')
	local ramp = Theme.Ramp(Theme:ClassColor('MONK'))
	expectEq(string.match(spec, '^|cff(%x%x%x%x%x%x)'), Theme:Hex(ramp.bright), 'in the class family (its light end first)')
	HK_UNITS.player = 'DRUID'
	HK_NPC.target = true
	expectEq(specTag.fn('target'), nil, 'an NPC: no spec, no placeholder')
	HK_NPC.target = nil
	local savedClass = UnitClass
	UnitClass = function(unit) if unit == 'target' then return 'Mage', HK_Secret('class') end return savedClass(unit) end
	expectEq(specTag.fn('target'), nil, 'a hidden class: no spec line (nothing read)')
	UnitClass = savedClass
	expectEq(HK_Plain(specTag.fn('target')), 'FROST', 'a player target with a reliably known spec')
end)

test('1.3.1 thickness: Player 24 / Target 21 (32 / 28 whole pixels at Darren\'s scale), the bar thickness setting scales only their bars; Focus, ToT and party unchanged; the hub stays larger than the bars', function()
	SplitSession()
	expectEq(Split.Geometry('player').height .. '/' .. Split.Geometry('target').height, '24/21', 'thicker than 1.3.0 (18 / 16)')
	local PX = 0.71 * 1440 / 768
	for _, key in ipairs({ 'player', 'target' }) do
		local px = Split.Geometry(key).height * PX
		expect(math.abs(px - math.floor(px + 0.5)) < 0.06, key .. ': close to whole pixels (' .. px .. ')')
		expect(Split.Geometry(key).hub > Split.Geometry(key).height * 1.6, key .. ': the hub larger than the bars')
	end
	Theme:DB().splitThickness = 1.25
	expectEq(Split.Geometry('player').height .. '/' .. Split.Geometry('player').powerHeight, '30/30', 'thicker: both bars')
	expectEq(Split.Geometry('focus').height, 12, 'Focus unchanged')
	expectEq(Split.Geometry('player').bar, 180, 'the length unchanged')
	Theme:DB().splitThickness = 5
	expectEq(Theme:DB().splitThickness, 1.3, 'kept in range')
	Theme:DB().splitThickness = 1
end)

test('licensed display typography: BANZAI Default is Shojumaru at 105%; Automatic falls back for whole unsupported strings; Information Font and PREVIOUS remain selectable', function()
	SplitLines()
	local media = LibStub('LibSharedMedia-3.0')
	expectEq(media:Fetch('font', 'BANZAI Shojumaru'), SHOJUMARU_PATH, 'registered with LibSharedMedia (ElvUI / Details font lists)')
	expectEq(Theme.FONT_REGISTRY.SHOJUMARU.license, 'SIL Open Font License 1.1', 'the registered face carries its license metadata')
	Theme:DB().displayFace = 'BANZAI_DEFAULT'
	expectEq(Theme:SelectedDisplayFace(), 'SHOJUMARU', 'BANZAI Default resolves semantically')
	expectEq(Theme:DisplayFont(), SHOJUMARU_PATH, 'BANZAI Default uses Shojumaru')
	expectEq(Theme:DisplaySize(20), 21, 'BANZAI Default uses the 105% base')
	local info = Theme:DisplayFontInfo('BANZAI SLAND')
	expectEq(info.name, 'Shojumaru', 'preview identifies the selected face')
	expectEq(info.license, 'SIL Open Font License 1.1', 'preview exposes the redistribution license')
	expectEq(info.metadata.sourceSha256, '8607110ef45da664861c72d95fb804c3609169ebfd2a380cb47b353a7b241c75', 'licensed source hash is available')
	expectEq(info.metadata.minimumPracticalSize, 10, 'minimum practical size is available')
	expectEq(info.metadata.outline, 'OUTLINE', 'outline metadata is available')
	expectEq(info.fallback, false, 'supported preview text stays on Shojumaru')
	Theme:DB().displayFace = 'SHOJUMARU'
	expectEq(Theme:DisplaySize(20), 20, 'explicit Shojumaru does not inherit the 105% default base')
	Theme:DB().displayFace = 'INFORMATION'
	expectEq(Theme:DisplayFont(), Theme:SmallFont(), 'Information Font remains an explicit choice')
	expectEq(Theme:DisplaySize(20), 20, 'Information Font keeps its existing size')
	Theme:DB().displayFace = 'BANZAI_DEFAULT'
	ns.Compat:Set('displayScale', 1.2)
	expectEq(Theme:DisplaySize(20), 25, 'the independent display-size multiplier applies to the 105% base')
	ns.Compat:Set('displayScale', 1)
	ns.Compat:RefreshAll()
	local zone = ns.Compat.minimapFrame and ns.Compat.minimapFrame.zone.text
	expectEq(zone and zone.font, SHOJUMARU_PATH, 'the zone name above the minimap')
	for _, t in ipairs(ns.Compat.detailsTitles or {}) do if t.text.font then expectEq(t.text.font, SHOJUMARU_PATH, 'the DAMAGE / HEALING titles') end end
	if ns.Compat.chatTitle and ns.Compat.chatTitle.text.font then expectEq(ns.Compat.chatTitle.text.font, SHOJUMARU_PATH, 'the CHAT title') end
	if ns.Compat.buffsTitle and ns.Compat.buffsTitle.text.font then expectEq(ns.Compat.buffsTitle.text.font, SHOJUMARU_PATH, 'the BUFFS title') end
	local afk = ns.AFK:Fill(true)
	expectEq(afk.name.font .. '|' .. afk.spec.font, SHOJUMARU_PATH .. '|' .. SHOJUMARU_PATH, 'the AFK name and class / spec line')
	expectEq(afk.where.font, Theme:SmallFont(), 'the AFK level / zone line keeps the small font')
	-- frozen: the targeted nameplate's numbers, the PvP labels, the glyphs, the secondary frames' numbers
	local party = ns.Health:Get('ElvUF_PartyGroup1UnitButton1')
	expectEq(party.bright.value.font, Theme:PreviousDisplayFont(), 'party numbers: the previous display font')
	expectEq(ns.Health:Get('ElvUF_Focus').bright.value.font, Theme:PreviousDisplayFont(), 'Focus numbers too')
	local plateText = ns.Health:Attach(HK_NewFrame('StatusBar', nil, UIParent), ns.TargetPlate.TEXT)
	expectEq(plateText.bright.value.font, Theme:PreviousDisplayFont(), 'the targeted nameplate\'s HP: unchanged')
	expectEq(Theme:PreviousDisplayFont(), 'Interface\\AddOns\\JiberishMedia\\font\\GasoekOne.ttf', 'the previous display font: GasoekOne')
	-- PREVIOUS: everything back on the old font, at once
	ns.Restore = ns.Restore
	ns.Compat:Set('displayFace', 'PREVIOUS')
	expectEq(Theme:DisplayFont(), Theme:PreviousDisplayFont(), 'PREVIOUS: the previous display font')
	expectEq(zone and zone.font, Theme:PreviousDisplayFont(), 'the zone name follows at once')
	expectEq(Split:Get('ElvUF_Player').lines.name.font, Theme:PreviousDisplayFont(), 'the split lines follow at once')
	expectEq(ns.Health:Get('ElvUF_Player').bright.value.font, Theme:PreviousDisplayFont(), 'the Player HP follows')
	ns.Compat:Set('displayFace', 'BANZAI_DEFAULT')
	ns.Compat:Set('displayScale', 1.2)
	expectEq(Split:Get('ElvUF_Player').lines.name.fontSize, math.floor(Split.UNITS.player.name * 1.2 * 1.05 + 0.5), 'the display-size multiplier is separate from the default base')
	ns.Compat:Set('displayScale', 1)
	Theme:DB().displayFace = 'SOMETHING'
	expectEq(Theme:DB().displayFace, 'BANZAI_DEFAULT', 'an unknown face falls back to the stable default')
	for _, retired in ipairs({ 'WANTBANZAI', 'WANTCOFFEE', 'CHANG_CHANG_WOODCUT', 'ROOTS_OF_CHINA', 'ODISHI' }) do
		Theme:DB().displayFace = retired
		expectEq(Theme:DB().displayFace, 'BANZAI_DEFAULT', retired .. ' migrates to the semantic default')
	end
	-- the six approved alternates: registered, selectable, at their own size (no 105% base), falling back per string
	local FONT_ROOT = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\fonts\\'
	local alternates = {
		{ 'RYUJIN_ATTACK', 'Ryujin Attack', 'RyujinAttack.otf' }, { 'GANG_OF_THREE', 'Gang of Three', 'go3v2.ttf' }, { 'OSAKA_SANS', 'Osaka Sans', 'osaka-re.ttf' },
		{ 'SEKAIWO', 'Sekaiwo', 'Sekaiwo-Regular.otf' }, { 'XANGDA_SHINY', 'Xangda Shiny', 'Xangda Shiny.ttf' }, { 'NINJA_NARUTO', 'Ninja Naruto', 'njnaruto.ttf' },
	}
	expectEq(table.concat(Theme.DISPLAY_FACES, ','), 'AUTO,BANZAI_DEFAULT,SHOJUMARU,RYUJIN_ATTACK,GANG_OF_THREE,OSAKA_SANS,SEKAIWO,XANGDA_SHINY,NINJA_NARUTO,INFORMATION', 'the selector order: Automatic, BANZAI Default, Shojumaru, the six alternates, Information Font')
	for _, alt in ipairs(alternates) do
		expectEq(media:Fetch('font', 'BANZAI ' .. alt[2]), FONT_ROOT .. alt[3], alt[2] .. ' registered with LibSharedMedia')
		Theme:DB().displayFace = alt[1]
		expectEq(Theme:DB().displayFace, alt[1], alt[2] .. ' persists as a selection')
		expectEq(Theme:SelectedDisplayFace(), alt[1], alt[2] .. ' resolves to itself')
		expectEq(Theme:DisplayFont(), FONT_ROOT .. alt[3], alt[2] .. ' uses its own file')
		expectEq(Theme:DisplaySize(20), 20, alt[2] .. ' does not inherit the 105% default base')
		local altInfo = Theme:DisplayFontInfo('BANZAI SLAND')
		expectEq(altInfo.name, alt[2], alt[2] .. ': the preview names it')
		expect(type(altInfo.metadata.sourceSha256) == 'string' and #altInfo.metadata.sourceSha256 == 64, alt[2] .. ': its recorded hash is available')
		expect(type(altInfo.license) == 'string' and altInfo.licenseFile ~= nil, alt[2] .. ': licence and notice file recorded')
		expectEq(altInfo.fallback, false, alt[2] .. ' supports the identity sample')
	end
	Theme:DB().displayFace = 'XANGDA_SHINY'
	expectEq(Theme:DisplayFontFor('LEVEL 90'), Theme:SmallFont(), 'Xangda Shiny has no digits: a numeric string uses the Information Font as a whole')
	expectEq(Theme:DisplayFontFor('BANZAI'), FONT_ROOT .. 'Xangda Shiny.ttf', 'Xangda Shiny draws a letters-only string')
	Theme:DB().displayFace = 'RYUJIN_ATTACK'
	expectEq(Theme:DisplayFontFor('Příliš'), Theme:SmallFont(), 'Ryujin Attack lacks Czech accents: the whole string falls back')
	local altString = UIParent:CreateFontString(nil, 'OVERLAY')
	Theme:SetDisplayFont(altString, Theme:DisplaySize(14), 'OUTLINE', 'BANZAI SLAND')
	expectEq(altString.font .. '|' .. altString.fontSize, FONT_ROOT .. 'RyujinAttack.otf|14', 'an alternate is drawn at the unscaled size')
	HK_FONT_FAILS = FONT_ROOT .. 'RyujinAttack.otf'
	Theme:SetDisplayFont(altString, Theme:DisplaySize(14), 'OUTLINE', 'BANZAI SLAND')
	expectEq(altString.font .. '|' .. altString.fontSize, Theme:SmallFont() .. '|14', 'a failed alternate load falls back at the same size')
	HK_FONT_FAILS = nil
	Theme:DB().displayFace = 'AUTO'
	expectEq(Theme:SelectedDisplayFace(), 'SHOJUMARU', 'Automatic selects the default for supported locale text')
	local fontString = UIParent:CreateFontString(nil, 'OVERLAY')
	Theme:SetDisplayFont(fontString, Theme:DisplaySize(14), 'OUTLINE', 'BANZAI SLAND')
	expectEq(fontString.font, SHOJUMARU_PATH, 'Automatic uses Shojumaru for a fully supported string')
	expectEq(fontString.fontSize, 15, 'Automatic applies the default base to supported text')
	Theme:SetDisplayFont(fontString, Theme:DisplaySize(14), 'OUTLINE', 'BANZAI 漢')
	expectEq(fontString.font, Theme:SmallFont(), 'Automatic falls back for the whole unsupported string')
	expectEq(fontString.fontSize, 14, 'the Information Font fallback does not retain the 105% base')
	expectEq(Theme:DisplayFontInfo('BANZAI 漢').fallback, true, 'preview reports whole-string fallback')
	Theme:DB().displayFace = 'BANZAI_DEFAULT'
	HK_FONT_FAILS = SHOJUMARU_PATH
	Theme:SetDisplayFont(fontString, Theme:DisplaySize(14), 'OUTLINE', 'BANZAI SLAND')
	expectEq(fontString.font, Theme:SmallFont(), 'a failed Shojumaru load falls back')
	expectEq(fontString.fontSize, 14, 'a failed font load uses unscaled fallback size')
	HK_FONT_FAILS = nil
	-- the small information font stays where it is
	ns.Tracker:Refresh()
	if ns.Tracker.frame then expectEq(ns.Tracker.frame.title.font, Theme:SmallFont(), 'the tracker keeps the small font') end
end)

test('cast presentation: unchanged structure (spell icon, radial progress, Shojumaru spell name, small-font timer); the targeted nameplate hub keeps its small font', function()
	SplitLines()
	local hub = Split:Get('ElvUF_Focus').hub -- 1.3.3: the radial hub is Focus's (Player / Target: the bamboo cast bar)
	HK_CASTS.focus = { kind = 'cast', name = 'Enveloping Mist', texture = 775461, start = 1000, finish = 3000, notInterruptible = false, duration = HK_Duration(1.2) }
	HK_Fire('UNIT_SPELLCAST_START', 'focus')
	expectEq(hub.spell.shown, true, 'the spell icon in the hub')
	expectEq(hub.progress.shown, true, 'the radial progress')
	expectEq(HK_Plain(hub.castName.text), 'ENVELOPING MIST', 'the spell name above')
	expectEq(hub.castName.points[1][1] .. ' ' .. hub.castName.points[1][3], 'BOTTOM TOP', 'above the hub, as approved')
	expectEq(hub.castName.font, SHOJUMARU_PATH, 'the spell name in Shojumaru')
	expectEq(hub.castTime.font, Theme:SmallFont(), 'the timer in the small font (its numbers stay crisp)')
	HK_CASTS.focus = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'focus')
	expectEq(hub.spell.shown, false, 'back to the class art')
	expectEq(hub.state, 'idle', 'the identity again')
	local plateHub = Identity.Hub(UIParent, 26)
	plateHub.plate, plateHub.castSize = true, 9
	Split.Begin(plateHub, { name = 'Chaos Bolt', texture = 1, kind = 'cast' })
	expectEq(plateHub.castName.font, Theme:SmallFont(), 'nameplate hub: unchanged font')
end)

test('1.3.1 an NPC target: the reaction family on its health, no resource side when it has none (no fake percentage), no spec line', function()
	local f = SplitLines()
	local target = Split:Get('ElvUF_Target')
	HK_NPC.target, HK_UNITS.target, HK_REACTION.target = true, 'WARRIOR', 2
	HK_POWER.target = { token = 'MANA', max = 0 }
	Split:Paint(target)
	local hg = rgb(target.health.overlay.gradient[3])
	expect(hg[1] > 0.9 and hg[2] < 0.3, 'hostile: the red reaction family')
	expectEq(f.target.Power.alpha, 0, 'no resource side')
	expectEq(ns.Health:GetPower('ElvUF_Target').holder.shown, false, 'no resource texts')
	expectEq(HK_TAGS['banzai:split:spec'].fn('target'), nil, 'no spec')
	HK_NPC.target, HK_REACTION.target, HK_POWER.target = nil, nil, nil
	HK_UNITS.target = 'MAGE'
	Split:Paint(target)
end)

test('1.3.1 preview: the BANZAI SPLIT Player / Target samples as live - one class family over both bars, values above, name / spec lines under them (SAMPLE DATA)', function()
	SplitLines()
	local P = ns.Preview
	P:HideAll()
	P:SetStyle('SPLIT')
	expect(P:Show('player', true), 'player sample')
	local u = P:Get('player').units[1]
	expect(u.healthSurface and u.powerSurface, 'the live surfaces')
	P:SetState('NORMAL')
	local c = Theme:ClassColor(u.sample.class)
	local a, b = rgb(u.healthSurface.overlay.gradient[3]), rgb(u.powerSurface.overlay.gradient[2])
	expect(near(a[1], c[1]) and near(b[2], c[2]), 'both bars meet in the class colour')
	expectEq(u.name.points[1][1] .. ' ' .. u.name.points[1][3], 'TOPLEFT BOTTOMLEFT', 'the name under the health bar')
	expectEq(u.spec and (u.spec.points[1][1] .. ' ' .. u.spec.points[1][3]), 'TOPRIGHT BOTTOMRIGHT', 'the spec under the resource bar')
	expectEq(u.healthText.bright.value.points[1][1], 'BOTTOMLEFT', 'values above')
	P:HideAll()
end)

test('1.3.1 Character Sync carries the display font, its size and the bar thickness (BANZAI settings, exported with every other)', function()
	local out = Theme:Export()
	expectEq(tostring(out.displayFace) .. ' ' .. tostring(out.displayScale) .. ' ' .. tostring(out.splitThickness), 'BANZAI_DEFAULT 1 1', 'exported')
	local key = 'Darrenshammy - Stormrage'
	Theme:Import({ displayFace = 'PREVIOUS', displayScale = 1.1, splitThickness = 1.2 }, key)
	local db = Theme:DB(key)
	expectEq(db.displayFace .. ' ' .. db.displayScale .. ' ' .. db.splitThickness, 'PREVIOUS 1.1 1.2', 'imported on another character')
end)

test('1.3.1 the spec line follows "Specialization in names" (the profile marker) at the next repaint, without a reload', function()
	local f = SplitLines()
	local player = Split:Get('ElvUF_Player')
	ElvUI[1].db.unitframe.units.player.customTexts['b-SplitName'].banzaiSpec = false
	Split:Paint(player)
	expectEq(player.lines.specText.shown, false, 'spec off: no spec line')
	ElvUI[1].db.unitframe.units.player.customTexts['b-SplitName'].banzaiSpec = true
	Split:Paint(player)
	expectEq(player.lines.specText.shown, true, 'spec on again')
	expectEq(player.lines.name.shown, true, 'the name line always')
	expect(f.player, 'frames')
end)

test('1.3.1 review: an unpainted or failed split bar shows ElvUI\'s own colour - never the raw white Banzai texture (the 1.3.0 symptom); a failed frame keeps the fault for /banzai status', function()
	SplitSession()
	local bar = HK_NewFrame('StatusBar', nil, UIParent)
	local surface = Split.Surface(bar)
	expectEq(surface.overlay.shown, false, 'a new surface is hidden until a paint colours it')
	local target = Split:Get('ElvUF_Target')
	local saved = target.hub.castName.font
	target.hub.castName.font = nil -- a frame whose paint fails (as 1.3.0's did)
	HK_UNITS.target = 'MAGE'
	Split:Refresh()
	expectEq(target.health.overlay.shown, false, 'the failed frame: no uncoloured overlay, ElvUI\'s own colour shows')
	expect(Split.lastError ~= nil, 'the fault kept')
	target.hub.castName.font = saved
	Split.lastError = nil
	Split:Refresh()
	expectEq(target.health.overlay.shown, true, 'painted again once nothing fails')
end)

test('whole-string coverage: supported accented Latin uses Shojumaru; unsupported scripts and malformed UTF-8 use the Information Font; failed loads remain readable', function()
	local f = SplitLines()
	local savedName = UnitName
	UnitName = function(unit) if unit == 'target' then return 'Léon' end return savedName(unit) end
	local target = Split:Get('ElvUF_Target')
	Split:Paint(target)
	expectEq(target.lines.name.font, SHOJUMARU_PATH, 'an accented Latin name: Shojumaru')
	UnitName = function(unit) if unit == 'target' then return 'Iceborn' end return savedName(unit) end
	Split:Paint(target)
	expectEq(target.lines.name.font, SHOJUMARU_PATH, 'a plain name: Shojumaru')
	local secret = HK_Secret('name')
	UnitName = function(unit) if unit == 'target' then return secret end return savedName(unit) end
	Split:Paint(target)
	expectEq(target.lines.name.font, SHOJUMARU_PATH, 'a hidden name: never read, Shojumaru')
	UnitName = savedName
	expectEq(Theme:DisplayFontFor('Zoë'), SHOJUMARU_PATH, 'Latin-1 accented text')
	expectEq(Theme:DisplayFontFor('François Łukasz Dvořák'), SHOJUMARU_PATH, 'Latin-1 and Extended-A text')
	expectEq(Theme:DisplayFontFor('€ − ≈ ≤ ≥ • … ™'), SHOJUMARU_PATH, 'approved symbols')
	expectEq(Theme:DisplayFontFor('Иван'), Theme:SmallFont(), 'Cyrillic text')
	expectEq(Theme:DisplayFontFor(string.char(0xC0, 0xAF)), Theme:SmallFont(), 'malformed UTF-8')
	expectEq(Theme:DisplayFontFor('FALCONWING SQUARE'), SHOJUMARU_PATH, 'an English zone')
	local savedZone = HK_ZONE
	HK_ZONE = 'Dornogal Café'
	ns.Compat:UpdateZone()
	expectEq(ns.Compat.minimapFrame.zone.text.font, SHOJUMARU_PATH, 'an accented Latin zone name')
	HK_ZONE = savedZone
	ns.Compat:UpdateZone()
	-- the client cannot load the font file: the Information Font instead
	HK_FONT_FAILS = SHOJUMARU_PATH
	local fs = UIParent:CreateFontString(nil, 'OVERLAY')
	Theme:SetDisplayFont(fs, 14, 'OUTLINE')
	expectEq(fs.font, Theme:SmallFont(), 'fallback font')
	expect(pcall(fs.SetText, fs, 'X'), 'and the text can be set')
	HK_FONT_FAILS = nil
	expect(f.player, 'frames')
end)

test('1.3.1 review: the spell name above the hub stays clear of the percentages above the bars at any bar thickness; 3 above the hub as approved at the default', function()
	local g = Split.Geometry('player')
	expectEq(Split.CastLift(g, Split.UNITS.player), 3, 'default: 3 above the hub (unchanged)')
	Theme:DB().splitThickness = 1.3
	local g2 = Split.Geometry('player')
	local lift = Split.CastLift(g2, Split.UNITS.player)
	expect(g2.hub / 2 + lift >= g2.height / 2 + 2 + Split.UNITS.player.percent + 2, 'thick bars: lifted above the percentages')
	Theme:DB().splitHubScale = 0.8
	local g3 = Split.Geometry('player')
	expect(g3.hub / 2 + Split.CastLift(g3, Split.UNITS.player) >= g3.height / 2 + 2 + Split.UNITS.player.percent + 2, 'a smaller hub too')
	Theme:DB().splitThickness, Theme:DB().splitHubScale = 1, 1
	SplitSession()
	local hub = Split:Get('ElvUF_Player').hub
	local p = hub.castName.points[1]
	expectEq(p[1] .. ' ' .. p[3] .. ' ' .. p[5], 'CENTER CENTER 0', 'the live hub: above it (1.3.3: the spell name is centred on the bamboo cast bar)')
	expectEq(p[2], hub.bar, '1.3.3: on the bar')
end)

---------------------------------------------------------------------------
-- 1.3.2 Darren's original BANZAI class identities
---------------------------------------------------------------------------
ns.IdentityManifest.classes = BUILT_ART -- the 13 the build validated

test('1.3.2 the built manifest: all 13 BANZAI class identities, plain lowercase names in media/BanzaiIdentity; no Details sheet (the full art is muddy at a meter row)', function()
	local n = 0
	for token, file in pairs(ns.IdentityManifest.classes) do
		n = n + 1
		expectEq(file, string.lower(token), token .. ': its file')
		expect(Identity.GLYPHS[token], token .. ': a class')
	end
	expectEq(n, 13, 'thirteen classes')
	expectEq(ns.IdentityManifest.details, false, 'no Details sheet')
	expectEq(ns.Compat:IdentityDetailsSheet(), false, 'BANZAI COMPACT keeps its icon set')
	expectEq(ns.Compat:IdentityArtCount(), 13, 'counted for /banzai status')
end)

test('1.3.2 loading priority: BANZAI first, then Fabled, then the class-colour disc, then unknown - a missing, bad or refused file falls back for that class only, never an error', function()
	local hub = Identity.Hub(UIParent, 50)
	local art = Identity.Art('MONK', nil, hub)
	expectEq(art.kind, 'BANZAI', 'the original art first')
	expectEq(art.path, Theme.MEDIA .. 'BanzaiIdentity\\monk', 'from Banzai Art\'s own media')
	expectEq(Identity.PaintArt(hub, art), 'BANZAI', 'painted')
	expectEq(hub.icon.path, Theme.MEDIA .. 'BanzaiIdentity\\monk', 'on the hub\'s icon')
	expectEq(hub.icon.filter, 'TRILINEAR', 'mip-filtered')
	local saved = ns.IdentityManifest.classes.MONK
	ns.IdentityManifest.classes.MONK = nil
	expectEq(Identity.Art('MONK', nil, hub).kind, 'FABLED', 'Monk missing: Fabled for Monk')
	expectEq(Identity.Art('MAGE', nil, hub).kind, 'BANZAI', 'Mage still BANZAI')
	ns.IdentityManifest.classes.MONK = '..\\monk'
	expectEq(Identity.Art('MONK', nil, hub).kind, 'FABLED', 'a bad entry: Fabled for Monk')
	local savedJI = JiberishIcons
	JiberishIcons = nil
	expectEq(Identity.Art('MONK', nil, hub).kind, 'GLYPH', 'and without Jiberish Icons: the class-colour disc')
	expectEq(Identity.Art('MAGE', nil, hub).kind, 'BANZAI', 'Mage untouched')
	JiberishIcons = savedJI
	ns.IdentityManifest.classes.MONK = saved
	expectEq(Identity.Art(nil, nil, hub).kind, 'UNKNOWN', 'no class: unknown')
	expectEq(Identity.Art(HK_Secret('class'), nil, hub).kind, 'UNKNOWN', 'a hidden class: unknown (never read, never inferred)')
	-- the client refusing one file: that class falls back at once, the others keep theirs
	local set = hub.icon.SetTexture
	hub.icon.SetTexture = function(self, path, ...) if path == Theme.MEDIA .. 'BanzaiIdentity\\warrior' then return false end return set(self, path, ...) end
	expectEq(Identity.PaintArt(hub, Identity.Art('WARRIOR', nil, hub)), 'FABLED', 'a refused file: Fabled for Warrior')
	expectEq(Identity.PaintArt(hub, Identity.Art('MAGE', nil, hub)), 'BANZAI', 'Mage keeps BANZAI')
	hub.icon.SetTexture = set
	for _, a in ipairs({ Identity.Art('MONK', nil, hub), Identity.Art('MONK', nil, { noBanzai = true }), Identity.Art('MONK', nil, { iconSize = 10 }), Identity.Art(nil) }) do
		expect(pcall(Identity.PaintArt, hub, a), 'paints without an error: ' .. a.kind)
	end
end)

test('1.3.2 where the full art is used: the Player / Target / Focus hubs and the split party circles (icons of 22 units and more); the enhanced nameplate hub (frozen) and anything smaller keep the Fabled art', function()
	expectEq(Identity.BANZAI_MIN, 22, 'about 30 px at Darren\'s scale (QA: readable at 32, muddy at 24)')
	expectEq(Identity.Art('MAGE', nil, Identity.Hub(UIParent, 50)).kind, 'BANZAI', 'Player hub (icon 40)')
	expectEq(Identity.Art('MAGE', nil, Identity.Hub(UIParent, 46)).kind, 'BANZAI', 'Target hub (icon 37)')
	expectEq(Identity.Art('MAGE', nil, Identity.Hub(UIParent, 30)).kind, 'BANZAI', 'Focus hub (icon 24)')
	local plate = Identity.Hub(UIParent, Split.PLATE.hub)
	plate.plate = true
	expectEq(Identity.Art('MAGE', nil, plate).kind, 'FABLED', 'the enhanced nameplate hub: as in 1.3.1')
	local bigPlate = Identity.Hub(UIParent, 40)
	bigPlate.plate = true
	expectEq(Identity.Art('MAGE', nil, bigPlate).kind, 'FABLED', 'a nameplate hub of any size (frozen, not only too small)')
	expectEq(Identity.Art('MAGE', nil, Identity.Hub(UIParent, 24)).kind, 'FABLED', 'a hub too small for the art (icon 19)')
	expectEq(Identity.Art('MAGE', nil, Identity.Circle(UIParent, Split.PARTY.circle)).kind, 'BANZAI', 'the split party circle (icon 27.5)')
	expectEq(Identity.Art('MAGE').kind, 'BANZAI', 'asked without a size (a full-size sample)')
end)

test('1.3.2 BANZAI SPLIT: the Player hub idles on the BANZAI class art, shows the spell while casting and goes back after; a player Target gets its class\'s art, an NPC its portrait, a hidden class the unknown disc; the nameplate hub keeps its art', function()
	SplitLines()
	local player, target = Split:Get('ElvUF_Player'), Split:Get('ElvUF_Target')
	HK_UNITS.player = 'MONK'
	Split:Paint(player)
	local hub = player.hub
	expectEq(hub.artKind, 'BANZAI', 'idle: the BANZAI Monk art')
	expectEq(hub.icon.path, Theme.MEDIA .. 'BanzaiIdentity\\monk', 'the Monk file')
	local ring = hub.ring.gradient[3]
	expect(ring.g > ring.r, 'the jade class ring around it (hub unchanged)')
	HK_CASTS.player = { kind = 'cast', name = 'Vivify', texture = 1360980, start = 1000, finish = 2500, notInterruptible = false, duration = HK_Duration(1.5) }
	HK_Fire('UNIT_SPELLCAST_START', 'player')
	expectEq(hub.spell.shown, true, 'casting: the spell icon over it')
	expectEq(hub.bar.shown and hub.bar.status.shown, true, 'the radial progress (1.3.3: the bamboo cast bar)')
	expectEq(hub.castName.font, SHOJUMARU_PATH, 'the spell name in Shojumaru')
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'player')
	expectEq(hub.spell.shown, false, 'after the cast: no spell')
	expectEq(hub.artKind, 'BANZAI', 'the BANZAI class art again')
	for _, class in ipairs({ 'WARRIOR', 'PRIEST', 'DEMONHUNTER', 'EVOKER' }) do
		HK_UNITS.target = class
		Split:Paint(target)
		expectEq(target.hub.icon.path, Theme.MEDIA .. 'BanzaiIdentity\\' .. string.lower(class), 'target ' .. class)
	end
	HK_NPC.target = true
	Split:Paint(target)
	expectEq(target.hub.artKind, 'PORTRAIT', 'an NPC: its portrait (no class inferred)')
	HK_NPC.target = nil
	local savedClass = UnitClass
	UnitClass = function(unit) if unit == 'target' then return HK_Secret('n'), HK_Secret('c') end return savedClass(unit) end
	Split:Paint(target)
	expectEq(target.hub.artKind, 'UNKNOWN', 'a class the game keeps hidden: the unknown disc')
	UnitClass = savedClass
	HK_UNITS.player, HK_UNITS.target = 'DRUID', 'MAGE'
	local plate = Identity.Hub(UIParent, Split.PLATE.hub)
	plate.plate = true
	expectEq(Split.PaintIdentity(plate, 'target', { npc = true }), 'FABLED', 'the enhanced nameplate hub: its 1.3.1 art')
end)

test('1.3.2 IDENTITY ART: AUTO (default) - BANZAI in the split hubs / party circles, the classic circles as before; BANZAI - the classic Focus / Party / Boss circles too (arena enemies never); FABLED; CLASS COLOUR; a bad value is AUTO; Character Sync carries the choice', function()
	local db = Theme:DB()
	expectEq(db.identityArt, 'AUTO', 'default')
	local hub = Identity.Hub(UIParent, 50)
	local circle = Identity.Circle(UIParent)
	circle.unitFrame, circle.def, circle.index = HK_NewFrame('Button', nil, UIParent), { frame = 'X', unit = 'party1' }, 1
	HK_UNITS.party1 = 'PALADIN'
	local function classic() Identity:Update(circle) return circle.artKind, circle.icon.path end
	expectEq(Identity.Art('PALADIN', nil, hub).kind, 'BANZAI', 'AUTO: split hub BANZAI')
	local kind, path = classic()
	expect(kind == nil and path == JI_CLASS, 'AUTO: the classic circle keeps the Fabled art (Identity.Paint)')
	for _, case in ipairs({ { 'BANZAI', 'BANZAI', 'BANZAI' }, { 'FABLED', 'FABLED', nil }, { 'CLASS', 'GLYPH', 'GLYPH' } }) do
		ns.Compat:Set('identityArt', case[1])
		expectEq(Identity.Art('PALADIN', nil, hub).kind, case[2], case[1] .. ': split hub')
		circle.artKind = nil
		expectEq((classic()), case[3], case[1] .. ': classic circle')
	end
	ns.Compat:Set('identityArt', 'BANZAI')
	local arena = Identity.Circle(UIParent)
	arena.unitFrame, arena.def, arena.index = HK_NewFrame('Button', nil, UIParent), { prefix = 'ElvUF_Arena', unit = 'arena', count = 5, arena = true }, 1
	HK_UNITS.arena1 = 'ROGUE'
	Identity:Update(arena)
	expectEq(arena.artKind, nil, 'arena enemy circles never change (PvP frames frozen)')
	HK_UNITS.arena1, HK_UNITS.party1 = nil, nil
	db.identityArt = 'SHINY'
	expectEq(Theme:DB().identityArt, 'AUTO', 'an unknown value: AUTO')
	ns.Compat:Set('identityArt', 'FABLED')
	expectEq(Theme:Export().identityArt, 'FABLED', 'Character Sync carries it')
	ns.Compat:Set('identityArt', 'AUTO')
end)

---------------------------------------------------------------------------
-- 1.3.3 PvP frame safety, the synthetic TARGET NPC preview, the 125 % identity, the bamboo cast bar
---------------------------------------------------------------------------
local CastBar = ns.CastBar
local PX = 0.71 * 1440 / 768 -- Darren's screen pixels per UI unit

-- an ElvUI aura icon of a party / arena frame (as the 0.9.0 test: found in ElvUI's own lists)
local function AuraIcon(frame, which)
	local key = (which == 'auras') and 'Auras' or 'Debuffs'
	local container = frame[key]
	if type(container) ~= 'table' or container.auraType ~= which then
		container = { parent = frame, auraType = which, buttons = {} }
		frame[key] = container
	end
	local b = HK_NewFrame('Button', nil, UIParent)
	b.container = container
	container.buttons[b] = container
	return b
end

test('1.3.3 TARGET NPC preview (Darren\'s native crash: Disk Queue 0 reading FileData 134153, the game icon the 1.3.2 sample asked for): synthetic and Banzai\'s own - no unit token, no portrait, no model or model scene, no secure template, no game icon or FileData number (Banzai media and the plain white texture, requested at load), no PvP refresh or emphasis; built once, toggled any number of times, idle in every state, hidden in combat', function()
	SplitSession()
	local P = ns.Preview
	P:HideAll()
	P.style = 'SPLIT'
	-- everything a live, protected or asynchronous path would touch, watched while the sample is built, shown and stepped
	local asked, saved = {}, {}
	for _, n in ipairs({ 'UnitClass', 'UnitExists', 'UnitIsPlayer', 'UnitName', 'UnitGUID', 'UnitReaction', 'UnitClassification', 'UnitPowerMax', 'UnitPowerType',
		'UnitIsUnit', 'UnitIsConnected', 'UnitIsTapDenied', 'SetPortraitTexture', 'UnitCastingInfo', 'UnitChannelInfo', 'GetArenaOpponentSpec' }) do
		saved[n] = _G[n]
		_G[n] = function(...) asked[#asked + 1] = n return saved[n](...) end
	end
	local savedCreate, kinds = CreateFrame, {}
	CreateFrame = function(kind, name, parent, template) kinds[#kinds + 1] = tostring(kind) .. ':' .. tostring(template) return savedCreate(kind, name, parent, template) end
	local PV, pvp, pvpSaved = ns.PvPFrames, {}, {}
	for _, fn in ipairs({ 'Refresh', 'ApplyEmphasis', 'Scan', 'Build', 'Emphasize', 'Decorate' }) do
		pvpSaved[fn] = PV[fn]
		PV[fn] = function(...) pvp[#pvp + 1] = fn return pvpSaved[fn](...) end
	end
	local fresh = Split:BuildPreview('targetNPC', P) -- a new sample, built under the watch
	local casts = 0
	for _, state in ipairs(P.STATES) do
		Split:ApplyPreviewState(fresh, state, P)
		if fresh.units[1].hub.spell.shown then casts = casts + 1 end
	end
	for _ = 1, 6 do P:Show('targetNPC', true) P:Show('targetNPC', false) end -- repeated selection
	P:Show('targetNPC', true)
	for n, fn in pairs(saved) do _G[n] = fn end
	CreateFrame = savedCreate
	for _, fn in ipairs({ 'Refresh', 'ApplyEmphasis', 'Scan', 'Build', 'Emphasize', 'Decorate' }) do PV[fn] = pvpSaved[fn] end -- (1.3.4: nil ones too)
	expectEq(#asked, 0, 'no unit token asked (' .. table.concat(asked, ',') .. ')')
	for _, k in ipairs(kinds) do
		expect(not string.find(k, 'Model', 1, true), 'no PlayerModel / ModelScene (' .. k .. ')')
		expect(not string.find(k, 'Secure', 1, true) and not string.find(k, 'Cooldown', 1, true), 'no secure template, no cooldown widget (' .. k .. ')')
	end
	expectEq(#pvp, 0, 'no PvP refresh or emphasis from the preview (' .. table.concat(pvp, ',') .. ')')
	expectEq(casts, 0, 'idle in every preview state (no spell, no game spell icon)')
	-- every texture it shows: Banzai media requested once when Banzai Art loaded
	local loaded = {}
	for _, path in ipairs(Split.NPC_MEDIA) do loaded[path] = true end
	expectEq(#Split.mediaKeeper.textures, #Split.NPC_MEDIA, 'every texture of the sample requested once at load')
	for i, t in ipairs(Split.mediaKeeper.textures) do expectEq(t.path, Split.NPC_MEDIA[i], 'requested at load: ' .. tostring(Split.NPC_MEDIA[i])) end
	expectEq(Split.mediaKeeper.shown, false, 'the holder is hidden')
	for _, c in ipairs({ fresh, P:Get('targetNPC') }) do
		for _, r in ipairs(HK_Descendants(c)) do
			if r.path ~= nil then
				expect(type(r.path) == 'string' and loaded[r.path], 'Banzai media (and the plain white texture every Banzai bar uses) requested at load - never a game icon, a portrait or a FileData number: ' .. tostring(r.path))
			end
			expectEq(r.portraitUnit, nil, 'no portrait')
			expect(not r.attributes, 'no secure attribute')
		end
		local u = c.units[1]
		expectEq(u.hub.artKind, 'CREST', 'Banzai\'s NPC crest in the hub')
		expectEq(u.hub.icon.path, Split.SAMPLE.npcCrest, 'the crest file (media/BanzaiHubCrest)')
		expect(u.hub.progress == nil and u.hub.shield == nil and u.hub.track == nil, 'no radial progress, no game shield, no swipe track')
		expectEq(u.castBar, nil, 'no cast bar on a sample that never casts')
		expectEq(u.hub.spell.shown, false, 'idle in every state (no spell, no game icon)')
		expectEq(u.Power, nil, 'no resource side')
	end
	expectEq(P:Get('targetNPC').units[1].hub.ring.shown ~= false, true, 'its reaction ring round the crest')
	expect(string.find(HK_Plain(P:Get('targetNPC').title.text), 'SAMPLE DATA', 1, true), 'labelled SAMPLE DATA')
	expectEq(Split.SAMPLE.npcIcon, nil, 'the 1.3.2 game icon (INV_Misc_Head_Dragon_01) is gone')
	expectEq(HK_FindString(Split.SAMPLE, 'Head_Dragon'), nil, 'nowhere in the samples')
	-- combat hides it, and it cannot be shown in combat
	HK_Fire('PLAYER_REGEN_DISABLED')
	expectEq(P:IsShown('targetNPC'), false, 'hidden when combat starts')
	HK_IN_COMBAT = true
	expectEq(P:Show('targetNPC', true), false, 'not in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	P:HideAll()
	P.style = nil
end)

test('1.3.3 identity 125 %: the Player and Target hubs, their icon, spell icon and portrait 125 % of 1.3.2 (round, centred); the bars keep their size and their tuck; Focus, ToT, party, the nameplate hub unchanged', function()
	SplitSession()
	local was = { player = 50, target = 46 }
	for key, hub in pairs(was) do
		local g = Split.Geometry(key)
		expectEq(g.hub, hub * 1.25, key .. ': hub 125 % of 1.3.2')
		local h = Split:Get(Split.UNITS[key].frame).hub
		expectEq(h.w .. 'x' .. h.h, g.hub .. 'x' .. g.hub, key .. ': round')
		expect(math.abs(h.iconSize - hub * 0.80 * 1.25) < 1e-9, key .. ': the icon disc 125 %')
		for _, t in ipairs({ h.spell, h.portrait }) do
			expectEq(t.w .. 'x' .. t.h, h.iconSize .. 'x' .. h.iconSize, key .. ': spell icon / portrait 125 %, square in the round mask')
			expectEq(t.points[1][1] .. ' ' .. t.points[1][3] .. ' ' .. t.points[1][4] .. ' ' .. t.points[1][5], 'CENTER CENTER 0 0', key .. ': centred')
		end
		expectEq(g.tuck, math.floor(g.hub * Split.TUCK + 0.5), key .. ': the bars run as far under its edge as before (16 %)')
		expectEq(g.bar .. '/' .. g.height, Split.UNITS[key].bar .. '/' .. Split.UNITS[key].height, key .. ': bars unchanged')
	end
	expectEq(Split.Geometry('focus').hub, 30, 'Focus hub unchanged')
	expectEq(Split.UNITS.focus.identity, nil, 'Focus: no identity factor')
	expectEq(Split.PARTY.circle, 32, 'party circles unchanged')
	expectEq(Split.PLATE.hub, 26, 'the nameplate hub unchanged')
	expectEq(Split:Get('ElvUF_TargetTarget').hub, nil, 'ToT: no hub')
	expectEq(Split:Get('ElvUF_Focus').hub.w, 30, 'the live Focus hub 30')
	-- at Darren's scale the Player hub is 83 px (1.3.2: 67)
	expect(math.abs(Split.Geometry('player').hub * PX - 83.2) < 0.1, 'Player hub 83 px at 2560 x 1440, UI scale 0.71')
end)

test('1.3.3 Player cast: idle - the BANZAI class art at full size with its own bamboo ring (no class ring over it, no radial circle); casting / channelling - the game\'s spell icon ALONE in the centre (the art veiled, the ring round the icon), the bamboo cast bar with the game\'s timer; success, failure, cancel - the class art at once, the bar gone; interrupted - the class art at once, crimson INTERRUPTED on the bar for a moment', function()
	SplitLines()
	HK_UNITS.player = 'MONK'
	local player = Split:Get('ElvUF_Player')
	Split:Paint(player)
	local hub, bar = player.hub, player.hub.bar
	expect(bar ~= nil, 'the Player hub has its bamboo cast bar')
	expectEq(hub.progress, nil, 'no radial progress widget')
	expectEq(hub.track, nil, 'no radial track')
	expectEq(hub.shield, nil, 'no game shield texture')
	expectEq(#hub.lockParts, 0, 'no lock ring on the hub')
	expectEq(hub.artKind, 'BANZAI', 'idle: the BANZAI Monk art')
	expectEq(hub.icon.w, hub.size * Identity.HUB.art, 'at full size (its ring where the class ring was)')
	expectEq(hub.icon.masks == nil or #hub.icon.masks == 0, true, 'its own transparency (no round mask)')
	expectEq(hub.ring.shown, false, 'the class ring steps aside: the artwork\'s bamboo ring is the hub\'s')
	expectEq(bar.shown, false, 'idle: no cast bar')
	local function iconsShown() local n = 0 for _, t in ipairs({ hub.icon, hub.portrait, hub.spell, hub.glyph, hub.glyphDisc }) do if t and t.shown and t.alpha ~= 0 then n = n + 1 end end return n end
	expectEq(iconsShown(), 1, 'one icon in the centre')
	-- a cast
	local duration = HK_Duration(1.5)
	HK_CASTS.player = { kind = 'cast', name = 'Enveloping Mist', texture = 775461, start = 1000, finish = 3000, notInterruptible = false, duration = duration }
	HK_Fire('UNIT_SPELLCAST_START', 'player')
	expectEq(hub.spell.shown and hub.spell.path, 775461, 'casting: the game\'s spell icon in the centre')
	expectEq(hub.icon.alpha, 0, 'the class art veiled (never under or beside the spell)')
	expectEq(iconsShown(), 1, 'one icon in the centre while casting')
	expectEq(hub.ring.shown, true, 'the ring round the spell icon')
	expectEq(hub.ring.alpha, 1, 'not dimmed (no progress on it)')
	expectEq(bar.shown, true, 'the bamboo cast bar shows')
	expectEq(bar.status.timer[1], duration, 'its fill: the game\'s duration object, unread')
	expectEq(bar.status.timer[3], Enum.StatusBarTimerDirection.ElapsedTime, 'a cast fills left to right')
	expectEq(HK_Plain(bar.name.text), 'ENVELOPING MIST', 'the spell name on the bar')
	expectEq(bar.time.text, '1.5', 'the timer on the bar (the widget formats the game\'s remaining time)')
	expectEq(hub.castName, bar.name, 'the hub\'s spell name is the bar\'s (no second name over the hub)')
	expectEq(hub.clock.shown, true, 'the clock runs while a timed cast shows')
	-- success: the class art at once
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_SUCCEEDED', 'player')
	HK_Fire('UNIT_SPELLCAST_STOP', 'player')
	expectEq(hub.spell.shown, false, 'done: no spell icon')
	expectEq(hub.icon.alpha, 1, 'the class art back')
	expectEq(hub.ring.shown, false, 'its own ring again')
	expectEq(bar.shown, false, 'the bar gone')
	expectEq(bar.name.text .. bar.time.text, '', 'no stale name or timer')
	expectEq(hub.clock.shown, false, 'the clock stops')
	-- a channel drains (right to left)
	HK_CASTS.player = { kind = 'channel', name = 'Crackling Jade Lightning', texture = 606542, duration = HK_Duration(4) }
	HK_Fire('UNIT_SPELLCAST_CHANNEL_START', 'player')
	expectEq(bar.status.timer[3], Enum.StatusBarTimerDirection.RemainingTime, 'a channel drains: what remains')
	expectEq(hub.icon.alpha, 0, 'channelling: the spell icon alone')
	expectEq(HK_Plain(bar.name.text), 'CRACKLING JADE LIGHTNING', 'its name')
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_CHANNEL_STOP', 'player')
	expectEq(bar.shown or hub.spell.shown, false, 'a channel that ran out: idle')
	-- an empower fills
	HK_CASTS.player = { kind = 'empower', name = 'Fire Breath', texture = 4622458, duration = HK_Duration(3) }
	HK_Fire('UNIT_SPELLCAST_EMPOWER_START', 'player')
	expectEq(bar.status.timer[3], Enum.StatusBarTimerDirection.ElapsedTime, 'an empower charges up: fills')
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_EMPOWER_STOP', 'player', 'guid', 357208, true, nil, 8)
	-- interrupted: the class art at once, the bar's moment, then nothing
	HK_CASTS.player = { kind = 'cast', name = 'Vivify', texture = 1360980, duration = HK_Duration(1.2) }
	HK_Fire('UNIT_SPELLCAST_START', 'player')
	HK_CASTS.player = nil
	HK_TIMERS = {}
	HK_Fire('UNIT_SPELLCAST_INTERRUPTED', 'player')
	expectEq(hub.spell.shown, false, 'interrupted: no stale spell icon')
	expectEq(hub.icon.alpha, 1, 'the class art back at once')
	expectEq(bar.shown and bar.flash.shown, true, 'the bar: crimson for a moment')
	expectEq(bar.status.shown, false, 'no fill left')
	expectEq(HK_Plain(bar.name.text), 'INTERRUPTED', 'INTERRUPTED on the bar')
	local cyan = CastBar.COLORS.cyan
	expectEq(bar.name.textColor[1] .. ',' .. bar.name.textColor[3], cyan[1] .. ',' .. cyan[3], 'in cyan')
	expect(bar.flash.gradient[3].r > 0.7 and bar.flash.gradient[3].g < 0.2, 'crimson')
	expectEq(bar.time.text, '', 'no timer')
	HK_Fire('UNIT_SPELLCAST_STOP', 'player')
	expectEq(bar.shown, true, 'the stop after it does not cut the moment short')
	HK_RunTimers()
	expectEq(bar.shown or bar.flash.shown, false, 'then the bar goes')
	expectEq(bar.name.text, '', 'no stale name')
	-- failed / cancelled: cleared at once
	HK_CASTS.player = { kind = 'cast', name = 'Vivify', texture = 1360980, duration = HK_Duration(1.2), barID = 61 }
	HK_Fire('UNIT_SPELLCAST_START', 'player', 'guid', 116670, 61)
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_FAILED', 'player', 'guid', 116670, 61)
	expectEq(bar.shown or hub.spell.shown, false, 'failed: the bar and the spell icon gone at once')
	expectEq(hub.icon.alpha, 1, 'the class art back')
	expectEq(bar.name.text .. bar.time.text, '', 'no stale name or timer')
	HK_RunTimers()
	-- the bar never carries a spell icon
	for _, r in ipairs(HK_Descendants(bar)) do
		if r.path ~= nil then expect(type(r.path) == 'string' and (string.find(r.path, Theme.MEDIA, 1, true) == 1 or r.path == Theme.WHITE), 'the bar: Banzai media only, no spell icon (' .. tostring(r.path) .. ')') end
	end
	HK_UNITS.player = 'DRUID'
	Split:Paint(player)
end)

test('1.3.3 bamboo cast bar geometry: exactly the whole split composition\'s width (health end to resource end), the interior 155 % of the split bar (whole pixels at Darren\'s scale), the bamboo a frame round it, directly above the values and clear of the hub; the spell name centred, the timer at the right end clear of the bamboo; Player and Target', function()
	SplitSession()
	for _, key in ipairs({ 'player', 'target' }) do
		local def, g = Split.UNITS[key], Split.Geometry(key)
		local entry = Split:Get(def.frame)
		local bar = entry.hub.bar
		expectEq(bar.w, 2 * (g.inner + g.bar), key .. ': the width of the whole composition')
		expectEq(g.castWidth, bar.w, key .. ': Split.Geometry\'s width')
		local p = bar.points[1]
		expectEq(p[1] .. ' ' .. p[3] .. ' ' .. p[4], 'BOTTOM CENTER 0', key .. ': centred on the hub (the composition is symmetric about it)')
		expectEq(p[2], entry.hub, key .. ': on the hub')
		-- outer edges: hub centre +- width / 2 = the health bar's outer end and the resource bar's
		expectEq(bar.w / 2, g.inner + g.bar, key .. ': the outer edges on the bars\' outer ends')
		local ratio = g.castInterior / g.height
		expect(ratio > 0.9 and ratio < 1, key .. ': the interior 155 % of the bar (1.3.4: about the bar\'s own height round the spell name - ' .. ratio .. ')')
		expect(math.abs(g.castInterior * PX - math.floor(g.castInterior * PX + 0.5)) < 0.1, key .. ': the interior whole pixels (' .. g.castInterior * PX .. ')')
		expect(math.abs(g.castStalk * PX - math.floor(g.castStalk * PX + 0.5)) < 0.1, key .. ': each stalk whole pixels')
		expect(g.castInterior / g.castHeight > 0.65, key .. ': the bamboo never most of the bar (interior ' .. math.floor(g.castInterior / g.castHeight * 100) .. ' %)')
		local inset = (g.castHeight - g.castInterior) / 2
		expectEq(bar.status.points[1][4] .. ',' .. bar.status.points[1][5], inset .. ',' .. -inset, key .. ': the fill inside the bamboo')
		expectEq(bar.h, g.castHeight, key .. ': interior + two stalks')
		-- above the values (their largest display size) and the hub's top
		local valuesTop = math.floor(g.height / 2 + 0.5) + 2 + def.value * 1.2
		expect(g.castLift >= valuesTop and g.castLift >= g.hub / 2 + 3, key .. ': above the values and the hub, with a gap')
		expect(g.castLift - math.max(valuesTop, g.hub / 2) <= 8, key .. ': and directly above them (compact)')
		expectEq(bar.name.points[1][1] .. ' ' .. bar.name.points[1][3], 'CENTER CENTER', key .. ': the spell name centred')
		expectEq(bar.name.font, SHOJUMARU_PATH, key .. ': in Shojumaru')
		expectEq(bar.name.justify, 'CENTER', key .. ': centred')
		expectEq(bar.time.points[1][1] .. ' ' .. bar.time.points[1][3], 'RIGHT RIGHT', key .. ': the timer at the right end')
		expect(-bar.time.points[1][4] > CastBar.SHAPE.tie * g.castStalk * 0.6, key .. ': clear of the rope tie')
		expectEq(bar.time.font, Theme:SmallFont(), key .. ': in the small information font')
		expect(bar.name.w + 2 * (-bar.time.points[1][4] + def.castTime * 3) <= bar.w, key .. ': the name\'s room never reaches the timer')
		-- the bamboo: the panel textures, every piece inside the outline
		local pieces = 0
		for _, piece in ipairs(bar.pieces) do
			pieces = pieces + 1
			local t = piece.texture
			expect(t.path == Theme.MEDIA .. 'BanzaiStalk' or t.path == Theme.MEDIA .. 'BanzaiStalkEnd', key .. ': the panel stalk textures')
		end
		expect(pieces >= 8, key .. ': two stalks of node segments and two end pieces')
		expectEq(#bar.ties, 4, key .. ': a rope tie on each crossing')
		for _, t in ipairs(bar.ties) do
			expectEq(t.path, Theme.MEDIA .. 'BanzaiRopeTie', key .. ': the panel rope')
			local x, y = t.points[1][4], -t.points[1][5]
			expect(x + t.w * 0.2 >= -0.01 and x + t.w * 0.8 <= bar.w + 0.01 and y + t.h * 0.2 >= -0.01 and y + t.h * 0.8 <= bar.h + 0.01, key .. ': the drawn rope inside the outline')
		end
	end
	-- vertical order: cast bar / values / bars, the name / spec under them, Cast History below (Player)
	local g = Split.Geometry('player')
	local top = Theme:DB().splitPlayerY
	expect(top - g.hub / 2 > ns.CastHistory.TOP, 'the Player hub\'s bottom clear of Cast History')
	expect(top + g.castLift + g.castHeight < 454, 'the Player cast bar under the HEALER party row')
	-- the Target bar's top under the BANZAI wordmark at the top centre (Compat.LOGO: 24 high, 10 from the screen top)
	local tg = Split.Geometry('target')
	local below = Theme:DB().splitTargetY - tg.castLift - tg.castHeight
	local logo = -ns.Compat.LOGO.top + ns.Compat.LOGO.height
	expect(below >= logo + 1, 'the Target cast bar clear of the BANZAI wordmark (' .. below .. ' from the top, the wordmark ends at ' .. logo .. ')')
	-- whole pixels at Darren's scale: Player 50 / Target 44 px interiors over 32 / 28 px bars
	expectEq(math.floor(Split.Geometry('player').castInterior * PX + 0.5) .. '/' .. math.floor(Split.Geometry('target').castInterior * PX + 0.5), '30/26', 'interiors 50 / 44 px (1.3.4: 30 / 26)')
end)

test('1.3.3 cast bar states: non-interruptible through SetAlphaFromBoolean (a hidden flag unread, a plain one shown); no timing invented (hidden times, no duration object: no fill); plain times stepped by the clock; the Target bar for player and NPC casts in their family; Focus and the targeted nameplate keep their radial hub', function()
	SplitSession()
	local target = Split:Get('ElvUF_Target')
	local hub, bar = target.hub, target.hub.bar
	-- a hidden flag and hidden times, no duration object
	local name, ni = HK_Secret('name'), HK_Secret('notInterruptible')
	HK_CASTS.target = { kind = 'cast', name = name, texture = HK_Secret('icon'), start = HK_Secret('s'), finish = HK_Secret('f'), notInterruptible = ni }
	HK_Fire('UNIT_SPELLCAST_START', 'target')
	expectEq(bar.shown, true, 'the bar says a cast is under way')
	expectEq(bar.status.shown, false, 'no duration object, hidden times: no fill (nothing invented)')
	expectEq(bar.name.text, name, 'the hidden name handed over unread')
	expectEq(bar.lockVeil.alphaBoolean, ni, 'the hidden flag handed to SetAlphaFromBoolean')
	expectEq(bar.lockVeil.alpha, 'from-secret', 'never tested')
	expectEq(bar.time.text, '', 'no timer made up')
	-- a plain non-interruptible cast with the game's duration
	HK_CASTS.target = { kind = 'cast', name = 'Chaos Bolt', texture = 7, duration = HK_Duration(2.1), notInterruptible = true }
	HK_Fire('UNIT_SPELLCAST_DELAYED', 'target')
	expectEq(bar.lockVeil.alpha .. '/' .. bar.lockLine.alpha, CastBar.LOCK_VEIL .. '/1', 'not interruptible: the steel veil and line')
	expectEq(bar.lockVeil.color[1], CastBar.COLORS.lock[1], 'restrained steel')
	HK_CASTS.target = { kind = 'cast', name = 'Frostbolt', texture = 7, duration = HK_Duration(1.8), notInterruptible = false }
	HK_Fire('UNIT_SPELLCAST_INTERRUPTIBLE', 'target')
	expectEq(bar.lockVeil.alpha, 0, 'interruptible: no steel')
	-- plain times only (no duration object): the clock steps the fill
	HK_CASTS.target = { kind = 'cast', name = 'Hearthstone', texture = 8, start = HK_NOW * 1000, finish = (HK_NOW + 10) * 1000 }
	HK_Fire('UNIT_SPELLCAST_START', 'target')
	expectEq(bar.status.shown and bar.status.min .. '/' .. bar.status.max, HK_NOW .. '/' .. (HK_NOW + 10), 'plain times: the fill from start to end')
	HK_NOW = HK_NOW + 4
	hub.clock.scripts.OnUpdate(hub.clock, 1)
	expectEq(bar.status.value, HK_NOW, 'the clock steps it (a cast grows)')
	HK_CASTS.target = { kind = 'channel', name = 'Mind Flay', texture = 9, start = HK_NOW * 1000, finish = (HK_NOW + 3) * 1000 }
	HK_Fire('UNIT_SPELLCAST_CHANNEL_START', 'target')
	HK_NOW = HK_NOW + 1
	hub.clock.scripts.OnUpdate(hub.clock, 1)
	expectEq(bar.status.value, HK_NOW + 1, 'a channel drains (start + end - now)')
	HK_CASTS.target = nil
	HK_Fire('UNIT_SPELLCAST_CHANNEL_STOP', 'target')
	-- an NPC's cast: its reaction family on the fill, its portrait back after
	HK_NPC.target, HK_REACTION.target, HK_UNITS.target = true, 2, 'WARRIOR'
	Split:Paint(target)
	expectEq(hub.artKind, 'PORTRAIT', 'NPC: its portrait (the game draws it)')
	expectEq(hub.ring.shown, true, 'in its reaction ring')
	HK_CASTS.target = { kind = 'cast', name = 'Shadow Bolt', texture = 10, duration = HK_Duration(2) }
	HK_Fire('UNIT_SPELLCAST_START', 'target')
	expect(bar.fill.gradient[3].r > 0.8 and bar.fill.gradient[3].r > bar.fill.gradient[3].g + 0.3, 'the hostile family on the fill')
	expectEq(hub.portrait.alpha, 0, 'the spell icon alone in the centre')
	HK_CASTS.target = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'target')
	expectEq(hub.portrait.alpha, 1, 'the portrait back')
	HK_NPC.target, HK_REACTION.target, HK_UNITS.target = nil, nil, 'MAGE'
	Split:Paint(target)
	-- Focus and the targeted nameplate: the radial hub as approved
	local focus = Split:Get('ElvUF_Focus').hub
	expect(focus.progress and focus.track and focus.bar == nil, 'Focus keeps its radial hub, no cast bar')
	local plate = Identity.Hub(UIParent, Split.PLATE.hub)
	plate.plate = true
	expect(plate.progress and plate.bar == nil, 'the nameplate hub keeps its radial progress (nameplates frozen)')
	expectEq(Split.TOT.castInterior, nil, 'no cast bar for the ToT')
	expectEq(Split.PARTY.castInterior, nil, 'nor for party / arena frames')
end)

test('1.3.3 SPLIT CAST BAR settings: on by default (bar, spell name, timer), at once, per character - Character Sync carries them, never a live cast; a bad value is on; a CLASSIC session builds no hub or cast bar', function()
	SplitSession()
	local db = Theme:DB()
	expectEq(tostring(db.splitCastBar) .. tostring(db.splitCastName) .. tostring(db.splitCastTimer), 'truetruetrue', 'all on by default')
	local bar = Split:Get('ElvUF_Player').hub.bar
	HK_CASTS.player = { kind = 'cast', name = 'Vivify', texture = 1, duration = HK_Duration(1.5) }
	HK_Fire('UNIT_SPELLCAST_START', 'player')
	ns.Compat:Set('splitCastName', false)
	expectEq(bar.name.shown, false, 'spell name off at once')
	ns.Compat:Set('splitCastTimer', false)
	expectEq(bar.time.shown, false, 'timer off at once')
	ns.Compat:Set('splitCastBar', false)
	expectEq(bar.shown, false, 'the bar off at once')
	expectEq(Split:Get('ElvUF_Player').hub.spell.shown, true, 'the spell icon stays in the centre')
	local exported = Theme:Export()
	expectEq(tostring(exported.splitCastBar) .. tostring(exported.splitCastName) .. tostring(exported.splitCastTimer), 'falsefalsefalse', 'Character Sync carries the choices')
	expectEq(HK_FindString(exported, 'Vivify'), nil, 'never the live cast')
	for _, k in ipairs({ 'splitCastBar', 'splitCastName', 'splitCastTimer' }) do ns.Compat:Set(k, true) end
	expectEq(bar.shown and bar.name.shown and bar.time.shown, true, 'back on: the running cast shows again')
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_STOP', 'player')
	db.splitCastBar = 'yes'
	expectEq(Theme:DB().splitCastBar, true, 'a bad value: on')
	-- CLASSIC: nothing of this is built
	Split.session = nil
	db.frameStyle = 'CLASSIC'
	expectEq(Split:Session(), false, 'a CLASSIC session')
	expectEq(Split:Build(), false, 'builds nothing (no hub, no cast bar)')
	db.frameStyle = 'SPLIT'
	Split.session = nil
	expectEq(Split:Session(), true, 'split again')
end)

---------------------------------------------------------------------------
-- 1.3.4 hotfix: the PvP frames hands-off, the lower bamboo cast bar
---------------------------------------------------------------------------
local MUTATING = { 'SetHeight', 'SetWidth', 'SetSize', 'SetScale', 'SetPoint', 'ClearAllPoints', 'SetAllPoints', 'SetParent', 'SetFrameLevel', 'SetFrameStrata',
	'SetAlpha', 'SetShown', 'Show', 'Hide', 'SetAttribute', 'SetScript', 'HookScript', 'CreateTexture', 'CreateFontString', 'CreateAnimationGroup' }

-- record every mutating call on objects Banzai did not make (reads stay allowed)
local function WatchTheirs(objects)
	local calls, saved = {}, {}
	for _, o in ipairs(objects) do
		saved[o] = {}
		for _, m in ipairs(MUTATING) do
			saved[o][m] = rawget(o, m)
			local orig = o[m]
			o[m] = function(self, ...) calls[#calls + 1] = m return orig and orig(self, ...) end
		end
	end
	local function restore() for o, list in pairs(saved) do for _, m in ipairs(MUTATING) do o[m] = list[m] end end end
	return calls, restore
end

test('1.3.4 PvP frames hands-off (Darren\'s 22:46:33 "CreateFrame: Attempt to access forbidden object" and 22:49:31 "SetScript: Cannot assign script handler for \'onshow\' (blocked by secret aspects)", both in Decorate <- Scan): Banzai never decorates inside a party / arena frame\'s tree - nothing made on ElvUI\'s aura icons, no UNIT_AURA watcher, nothing created with a unit frame as its parent, nothing mutating called on a frame Banzai did not make; the trinket circles and target / focus markers are Banzai\'s own frames on the Banzai PvP layer, anchored to the health bar', function()
	local PV = ns.PvPFrames
	PV:Refresh()
	local pe, ae = PV:Get('ElvUF_PartyGroup1UnitButton2'), PV:Get('ElvUF_Arena1')
	local party2, arena1 = pe.frame, ae.frame -- the frames the PvP code uses (a later session made newer ones under these names)
	party2.unitframeType, arena1.unitframeType = 'party', 'arena'
	local layer = PV.Layer()
	expectEq(layer.name .. ':' .. tostring(layer.parent == UIParent), 'BanzaiPvPLayer:true', 'the Banzai PvP layer: a frame of Banzai\'s own on UIParent')
	-- every frame Banzai did not make, watched while the PvP code runs on its events
	local theirs = { party2, party2.Health, arena1, arena1.Health }
	AuraIcon(party2, 'auras') AuraIcon(party2, 'debuffs') AuraIcon(arena1, 'debuffs') -- ElvUI's icons on them
	for _, fr in ipairs({ party2, arena1 }) do
		for _, key in ipairs({ 'Auras', 'Debuffs' }) do
			local el = fr[key]
			if type(el) == 'table' then for b in pairs(el.buttons or {}) do theirs[#theirs + 1] = b end end
		end
	end
	local calls, restore = WatchTheirs(theirs)
	for _, event in ipairs({ 'UNIT_AURA', 'GROUP_ROSTER_UPDATE', 'ARENA_OPPONENT_UPDATE', 'PLAYER_REGEN_ENABLED' }) do
		PV:Refresh()
		PV.scheduled = false
	end
	for _, entry in ipairs({ PV:Get('ElvUF_PartyGroup1UnitButton2'), PV:Get('ElvUF_Arena1') }) do PV:UpdateMarkers(entry) PV:UpdateTrinket(entry.trinket) end
	restore()
	expectEq(#calls, 0, 'nothing mutating called on any frame Banzai did not make (' .. table.concat(calls, ',') .. ')')
	-- nothing on ElvUI's aura icons; nothing listens to aura changes
	for i = 5, #theirs do expectEq(#HK_Descendants(theirs[i]), 0, 'nothing made on an aura icon') end
	for _, f in ipairs(HK_Frames()) do expect(not (f.events and f.events.UNIT_AURA), 'no UNIT_AURA watcher in Banzai Art') end
	expectEq(PV.Decorate(theirs[#theirs]), nil, 'Decorate: a retired no-op')
	expectEq(PV.Emphasize, nil, 'no emphasis on live parts')
	expectEq(PV.Scan, nil, 'no scan of ElvUI\'s aura lists')
	-- the trinket circles and markers: Banzai's own frames on the layer, only anchored to the health bar
	for _, o in ipairs({ pe.trinket, ae.trinket, ae.target, ae.focus }) do
		local entry = o == pe.trinket and pe or ae
		expectEq(o.parent == entry.root and entry.root.parent == layer, true, 'on the Banzai PvP layer (1.3.5: through its entry\'s root), never a child of the unit frame')
		local inside = false
		for _, d in ipairs(HK_Descendants(party2)) do if d == o then inside = true end end
		for _, d in ipairs(HK_Descendants(arena1)) do if d == o then inside = true end end
		expectEq(inside, false, 'not inside a unit frame\'s tree')
	end
	expectEq(pe.trinket.points[1][1] .. ' ' .. pe.trinket.points[1][3] .. ' ' .. tostring(pe.trinket.points[1][2] == party2.Health), 'LEFT RIGHT true', 'anchored beside the party health bar (as approved)')
	expectEq(ae.trinket.points[1][1] .. ' ' .. ae.trinket.points[1][3], 'RIGHT LEFT', 'arena enemies mirrored (as approved)')
	expectEq(ae.target.points[1][2], arena1.Health, 'the TARGET outline round the enemy\'s health bar')
	-- a fresh frame: everything Banzai creates has a Banzai-owned parent
	local f4 = HK_NewFrame('Button', 'ElvUF_PartyGroup1UnitButton4', UIParent)
	f4.unit = 'party3'
	f4.Health = HK_NewFrame('StatusBar', 'ElvUF_PartyGroup1UnitButton4Health', f4)
	local savedCreate, made, parents = CreateFrame, {}, {}
	made[layer] = true
	CreateFrame = function(kind, name, parent, template)
		local o = savedCreate(kind, name, parent, template)
		parents[#parents + 1] = parent or false
		made[o] = true
		return o
	end
	local calls4, restore4 = WatchTheirs({ f4, f4.Health })
	PV:Build()
	CreateFrame = savedCreate
	restore4()
	expect(PV:Get('ElvUF_PartyGroup1UnitButton4'), 'the new party frame gets its trinket circle')
	expect(#parents > 0, 'frames were made')
	for _, p in ipairs(parents) do expect(p == false or made[p] or p == UIParent, 'every new frame\'s parent is Banzai\'s own (never a unit frame or its bars)') end
	expectEq(#calls4, 0, 'nothing mutating called on the new unit frame (' .. table.concat(calls4, ',') .. ')')
	expectEq(#HK_HOOKS, 0, 'nothing hooked')
end)

test('1.3.4 the access gate (PvP.Accessible: IsForbidden, HasAnySecretAspect, IsAnchoringSecret, issecrettable - one central check): a frame the client restricts is refused at once, nothing read from it or made for it, and it is not asked again on any refresh - only after a loading screen; a built frame the client restricts later, or Banzai\'s own frame that follows one, is left alone (no call, no pcall); the unit frame not visible: no trinket; a hidden swipe state: UNKNOWN', function()
	local PV = ns.PvPFrames
	local savedSecret = issecretvalue
	issecretvalue = HK_IsSecret
	expectEq(table.concat(PV.ACCESS, ','), 'IsForbidden,HasAnySecretAspect,IsAnchoringSecret', 'the questions the 12.x client answers')
	-- refused at once, remembered, never polled
	local f5 = HK_NewFrame('Button', 'ElvUF_PartyGroup1UnitButton5', UIParent)
	f5.unit = 'party4'
	f5.Health = HK_NewFrame('StatusBar', 'ElvUF_PartyGroup1UnitButton5Health', f5)
	local asked = 0
	f5.HasAnySecretAspect = function() asked = asked + 1 return true end
	local calls, restore = WatchTheirs({ f5, f5.Health })
	PV:Build()
	expectEq(PV:Get('ElvUF_PartyGroup1UnitButton5'), nil, 'a frame with a secret aspect: no trinket made for it')
	expectEq(PV:Refused('ElvUF_PartyGroup1UnitButton5'), true, 'its refusal remembered')
	local once = asked
	for _ = 1, 6 do PV:Refresh() end
	expectEq(asked, once, 'not asked again on the 0.2 s refreshes (no forbidden-object polling)')
	expectEq(#calls, 0, 'nothing called on it')
	PV:Reconsider()
	PV:Build()
	expectEq(asked, once + 1, 'a loading screen: asked once again')
	f5.HasAnySecretAspect = nil
	PV:Reconsider()
	PV:Build()
	restore()
	expect(PV:Get('ElvUF_PartyGroup1UnitButton5'), 'accessible again after a loading screen: its trinket circle')
	-- a built frame the client makes forbidden later: left alone
	local entry = PV:Get('ElvUF_Arena1')
	local arena1 = entry.frame
	local mt = getmetatable(arena1)
	HK_FORBIDDEN_CALLS = {}
	HK_Forbid(arena1)
	HK_Forbid(arena1.Health)
	expect(pcall(PV.Refresh, PV), 'the refresh runs')
	PV:UpdateMarkers(entry)
	expectEq(#HK_FORBIDDEN_CALLS, 0, 'nothing called on the forbidden frame (' .. table.concat(HK_FORBIDDEN_CALLS, ',') .. ')')
	expectEq(PV:Refused('ElvUF_Arena1'), true, 'remembered')
	local questions = 0
	rawset(arena1, 'IsForbidden', function() questions = questions + 1 return true end)
	for _ = 1, 4 do PV:Refresh() PV:UpdateMarkers(entry) end
	expectEq(questions, 0, 'a refused entry is not asked again on the refreshes')
	PV.events.scripts.OnEvent(PV.events, 'PLAYER_ENTERING_WORLD')
	PV.scheduled = false
	PV:Refresh()
	expect(questions >= 1, 'a loading screen asks it again')
	expectEq(PV:Refused('ElvUF_Arena1'), true, 'still refused while the client says so')
	rawset(arena1, 'IsForbidden', nil)
	setmetatable(arena1, mt)
	setmetatable(arena1.Health, mt)
	PV.events.scripts.OnEvent(PV.events, 'PLAYER_ENTERING_WORLD')
	PV.scheduled = false
	PV:Refresh()
	expectEq(PV:Refused('ElvUF_Arena1'), false, 'accessible again after the next loading screen')
	-- Banzai's own marker following a frame whose anchoring became secret: left alone too
	local secretAnchor = function() return true end
	entry.target.IsAnchoringSecret = secretAnchor
	local shows = 0
	local show = entry.target.SetShown
	entry.target.SetShown = function(self, v) shows = shows + 1 return show(self, v) end
	PV:UpdateMarkers(entry)
	expectEq(shows, 0, 'its own marker with a secret aspect: not touched')
	entry.target.IsAnchoringSecret, entry.target.SetShown = nil, nil
	PV:Reconsider()
	-- the unit frame not shown (the game hides it): no trinket; visible again: shown
	local pe = PV:Get('ElvUF_PartyGroup1UnitButton2')
	local party2 = pe.frame
	party2:Hide()
	PV:UpdateTrinket(pe.trinket)
	expectEq(pe.trinket.shown, false, 'the unit frame hidden: no trinket circle')
	party2:Show()
	PV:UpdateTrinket(pe.trinket)
	expectEq(pe.trinket.shown, true, 'visible again: the circle')
	-- the swipe's shown state hidden from Banzai: UNKNOWN, nothing guessed
	HK_INSTANCE, HK_TRINKETS[party2.unit] = 'arena', 95
	pe.trinket.cd.IsShown = function() return HK_Secret('shown') end
	PV:UpdateTrinket(pe.trinket)
	expectEq(pe.trinket.state, 'UNKNOWN', 'a hidden swipe state: UNKNOWN (never tested)')
	pe.trinket.cd.IsShown = nil
	PV:UpdateTrinket(pe.trinket)
	expectEq(pe.trinket.state, 'USED', 'a plain one: USED')
	HK_INSTANCE, HK_TRINKETS[party2.unit] = 'none', nil
	PV:UpdateTrinket(pe.trinket)
	issecretvalue = savedSecret
end)

test('1.3.4 bamboo cast bar about 40 % lower: Player 30 px / Target 26 px interiors (whole pixels at 2560 x 1440, UI scale 0.71; 1.3.3: 50 / 44), the bamboo hugging them at its own proportions (pieces placed again, never a squashed texture), the whole bar 40 / 38 % lower; the spell name and timer sizes, the full width, the place above the values and the central spell-icon states unchanged', function()
	SplitSession()
	local was = { player = { height = 37.5 + 2 * 1.1 * 7.5, name = 16, time = 12, px = 30 }, target = { height = 33 + 2 * 1.1 * 5.25, name = 15, time = 11, px = 26 } }
	for key, w in pairs(was) do
		local def, g = Split.UNITS[key], Split.Geometry(key)
		local bar = Split:Get(def.frame).hub.bar
		expectEq(math.floor(g.castInterior * PX + 0.5), w.px, key .. ': the interior ' .. w.px .. ' px')
		expect(math.abs(g.castInterior * PX - w.px) < 0.1, key .. ': whole pixels')
		expect(math.abs(g.castStalk * PX - math.floor(g.castStalk * PX + 0.5)) < 0.1, key .. ': each stalk whole pixels')
		local cut = 1 - g.castHeight / w.height
		expect(cut > 0.36 and cut < 0.44, key .. ': about 40 % lower than 1.3.3 (' .. math.floor(cut * 100 + 0.5) .. ' %)')
		expectEq(bar.h, g.castHeight, key .. ': the bar is that height')
		for _, p in ipairs(bar.pieces) do
			local across = p.horizontal and p.texture.h or p.texture.w
			expect(math.abs(across - 128 / 88 * g.castStalk) < 1e-6, key .. ': every bamboo piece at the panel\'s own proportions (not squashed)')
		end
		expectEq(bar.name.fontSize, Theme:DisplaySize(w.name), key .. ': the spell name\'s size unchanged')
		expectEq(bar.time.fontSize, w.time, key .. ': the timer\'s size unchanged')
		expect(g.castInterior >= bar.name.fontSize and g.castInterior - bar.name.fontSize <= 7.5, key .. ': snug round the spell name')
		expectEq(bar.w, 2 * (g.inner + g.bar), key .. ': the full width')
		expectEq(bar.points[1][5], g.castLift, key .. ': the same place, directly above the values')
	end
	-- the central icon: unchanged behaviour
	HK_UNITS.player = 'MONK'
	local player = Split:Get('ElvUF_Player')
	Split:Paint(player)
	local hub, bar = player.hub, player.hub.bar
	expectEq(hub.artKind .. '/' .. tostring(hub.progress), 'BANZAI/nil', 'idle: the BANZAI class icon, no radial ring')
	HK_CASTS.player = { kind = 'channel', name = 'Crackling Jade Lightning', texture = 606542, duration = HK_Duration(4) }
	HK_Fire('UNIT_SPELLCAST_CHANNEL_START', 'player')
	expectEq(hub.spell.shown and hub.icon.alpha == 0 and bar.shown, true, 'channelling: the spell icon alone in the centre, the bar above')
	expectEq(HK_Plain(bar.name.text), 'CRACKLING JADE LIGHTNING', 'its name on the lower bar')
	for _, r in ipairs(HK_Descendants(bar)) do expect(r.path == nil or string.find(tostring(r.path), Theme.MEDIA, 1, true) == 1 or r.path == Theme.WHITE, 'no icon on the bar') end
	HK_CASTS.player = nil
	HK_Fire('UNIT_SPELLCAST_CHANNEL_STOP', 'player')
	expectEq(hub.spell.shown or bar.shown, false, 'after: the class icon, no bar')
	expectEq(hub.icon.alpha, 1, 'the class icon back')
	HK_UNITS.player = 'DRUID'
	Split:Paint(player)
end)

---------------------------------------------------------------------------
-- 1.3.5
---------------------------------------------------------------------------
test('1.3.5 line ownership (the thin gold lines Darren saw across the world are not Banzai\'s): through every session so far Banzai has made no Line object and no rotated or warped texture; the only Banzai visuals that follow a unit relation are the arena TARGET / FOCUS outlines - rectangles with both corners on the same health bar, every edge inside the outline - so none can reach across the screen', function()
	for _, f in ipairs(HK_Frames()) do
		expect(f.kind ~= 'Line', 'no Line object')
		expectEq(f.rotation, nil, 'nothing rotated')
		expectEq(f.vertex, nil, 'nothing warped')
	end
	local PV = ns.PvPFrames
	PV:Refresh()
	local checked = 0
	for _, name in ipairs({ 'ElvUF_Arena1', 'ElvUF_Arena2' }) do
		local entry = PV:Get(name)
		if entry then
			for _, m in ipairs({ entry.target, entry.focus }) do
				checked = checked + 1
				expectEq(#m.points, 2, name .. ': two corners')
				expectEq(m.points[1][2] == entry.health and m.points[2][2] == entry.health, true, name .. ': both corners on the same health bar')
				expectEq(m.points[1][1] .. ' ' .. m.points[2][1], 'TOPLEFT BOTTOMRIGHT', name .. ': its own rectangle round it')
				for _, e in ipairs(m.edges) do expectEq(e.points[1][2] == m and e.points[2][2] == m, true, name .. ': every edge inside the outline') end
				expectEq(m.tab.points[1][2] == m and m.tab.points[2][2] == m and m.label.points[1][2] == m, true, name .. ': the tab and label inside it')
			end
		end
	end
	expect(checked >= 2, 'the arena outlines checked')
end)

test('1.3.5 deterministic cleanup of Banzai\'s own unit-relation visuals (events only, no polling): target / focus changed or cleared, the end of combat, the arena frame hidden by the game - each settles the TARGET / FOCUS outlines; a loading screen, a zone or spec change and Banzai Art switched off (a profile / style switch) put every Banzai PvP visual away at once at the entry\'s root (Banzai\'s own, on the layer, anchored to nothing else) before the next refresh shows what the plain answers allow; a refused entry is hidden there without a call on the unit frame; the 1.3.4 hands-off rules kept', function()
	local PV = ns.PvPFrames
	local savedUnitIsUnit = UnitIsUnit
	local function aims(target, focus) UnitIsUnit = function(a, b) return (target ~= nil and a == 'target' and b == target) or (focus ~= nil and a == 'focus' and b == focus) end end
	PV.scheduled = false
	PV:Reconsider()
	PV:Refresh()
	local ae = PV:Get('ElvUF_Arena1')
	local arena1 = ae.frame
	local layer = PV.Layer()
	expectEq(ae.root.parent == layer and ae.root.allPoints == layer and #ae.root.points == 0, true, 'the root: on the layer, all its points on the layer (anchored to nothing of a unit frame)')
	expectEq(ae.trinket.parent == ae.root and ae.target.parent == ae.root and ae.focus.parent == ae.root, true, 'the trinket circle and both outlines in the root')
	-- every frame Banzai did not make watched through the run
	local calls, restore = WatchTheirs({ arena1, arena1.Health })
	-- target / focus set, changed, cleared
	aims('arena1', 'arena1')
	HK_Fire('PLAYER_TARGET_CHANGED')
	expectEq(ae.root.shown and ae.target.shown and ae.focus.shown, true, 'targeted and focused: TARGET and FOCUS')
	aims(nil, 'arena1')
	HK_Fire('PLAYER_TARGET_CHANGED')
	expectEq(ae.target.shown, false, 'target cleared: TARGET gone at once')
	expectEq(ae.focus.shown, true, 'the focus kept')
	aims(nil, nil)
	HK_Fire('PLAYER_FOCUS_CHANGED')
	expectEq(ae.focus.shown, false, 'focus cleared: FOCUS gone at once')
	-- the arena frame hidden by the game: gone with the next refresh (its event), back with the frame
	aims('arena1')
	HK_Fire('PLAYER_TARGET_CHANGED')
	expectEq(ae.target.shown, true, 'targeted again')
	arena1.shown = false -- (the game hides it)
	HK_Fire('ARENA_OPPONENT_UPDATE')
	HK_RunTimers()
	expectEq(ae.target.shown or ae.trinket.shown, false, 'the frame hidden: its TARGET outline and trinket circle gone')
	arena1.shown = true
	HK_Fire('ARENA_OPPONENT_UPDATE')
	HK_RunTimers()
	expectEq(ae.target.shown, true, 'back with the frame')
	-- leaving combat: settled from the plain answers
	aims(nil)
	HK_Fire('PLAYER_REGEN_ENABLED')
	HK_RunTimers()
	expectEq(ae.target.shown, false, 'the end of combat: settled again')
	-- a loading screen, a zone or spec change: everything put away at once, then shown again only as allowed
	aims('arena1')
	HK_Fire('PLAYER_TARGET_CHANGED')
	for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'ZONE_CHANGED_NEW_AREA', 'PLAYER_SPECIALIZATION_CHANGED' }) do
		expectEq(PV.events.events[event], true, event .. ': watched')
		expectEq(ae.root.shown, true, event .. ': shown before')
		PV.events.scripts.OnEvent(PV.events, event)
		expectEq(ae.root.shown, false, event .. ': every Banzai PvP visual put away at once')
		HK_RunTimers()
		expectEq(ae.root.shown and ae.target.shown, true, event .. ': the next refresh shows what the plain answers allow')
	end
	-- Banzai Art switched off (a profile / style switch): put away at once, kept away; back with it
	HK_ElvData.current = 'HARDKORHUI'
	ns.Compat:Refresh()
	expectEq(ae.root.shown, false, 'away from the Banzai profile: gone at once')
	PV:Refresh()
	expectEq(ae.root.shown, false, 'and kept away while Banzai Art is off')
	HK_ElvData.current = NAME
	ns.Compat:Refresh()
	PV:Refresh()
	expectEq(ae.root.shown and ae.target.shown, true, 'back with the Banzai profile')
	restore()
	expectEq(#calls, 0, 'nothing mutating called on a frame Banzai did not make (' .. table.concat(calls, ',') .. ')')
	-- a refused entry: hidden at its root, nothing called on the unit frame; back after the next loading screen
	local mt = getmetatable(arena1)
	HK_FORBIDDEN_CALLS = {}
	HK_Forbid(arena1)
	HK_Forbid(arena1.Health)
	PV:Refresh()
	PV:UpdateMarkers(ae)
	expectEq(ae.root.shown, false, 'refused: hidden at its root')
	expectEq(#HK_FORBIDDEN_CALLS, 0, 'nothing called on the refused frame (' .. table.concat(HK_FORBIDDEN_CALLS, ',') .. ')')
	setmetatable(arena1, mt)
	setmetatable(arena1.Health, mt)
	PV.events.scripts.OnEvent(PV.events, 'PLAYER_ENTERING_WORLD')
	HK_RunTimers()
	expectEq(ae.root.shown and ae.target.shown, true, 'the next loading screen: back')
	-- events only
	expectEq(PV.events.scripts.OnUpdate, nil, 'no OnUpdate on the event frame')
	expectEq(ae.root.scripts.OnUpdate or layer.scripts.OnUpdate, nil, 'none on the layer or a root')
	expectEq(PV.events.events.UNIT_AURA, nil, 'no UNIT_AURA (1.3.4)')
	aims(nil, nil)
	HK_Fire('PLAYER_TARGET_CHANGED')
	UnitIsUnit = savedUnitIsUnit
end)

test('1.3.5 the DAMAGE | HEALING divider: one thin vertical line (2 screen pixels at Darren\'s 2560 x 1440, UI scale 0.71; snapped, crisp) on the Banzai Details frame\'s centre - the middle of the gap between the two meters - in the interior only (clear of the top and bottom stalks, the DAMAGE / HEALING titles and their accents, the rope ties); top to bottom the BANZAI gradient lime -> green -> emerald -> violet -> purple at a restrained alpha, both ends fading out; shown over GLASS, SOLID and HARDKORH PARCHMENT, only while both meters are open; the outer bamboo frame and Details\' own text untouched', function()
	local C = ns.Compat
	local frame = C.detailsFrame
	local V, P, S, D, TT = C.DETAILS_DIVIDER, C.PANEL, C.DIVIDER_STOPS, C.DETAILS, C.DETAILS_TITLE
	HK_DetailsWindow.ativa, HK_DetailsWindow2.ativa = true, true
	C:Refresh()
	local parts = frame.divider
	expectEq(#parts, 6, 'a fading end, four gradient sections, a fading end')
	local d = frame.stalkDiameter
	local scale = Theme.PixelScale(frame)
	for _, t in ipairs(parts) do
		expectEq(t.parent, frame, 'a texture of the Banzai Details frame itself (nothing on Details\' windows)')
		expectEq(t.layer, 'BORDER', 'over the glass / parchment, under every stalk')
		expectEq(t.path, Theme.WHITE, 'a plain line')
		expectEq(t.shown, true, 'shown with both meters open')
		expectEq(t.snap, true, 'snapped to whole screen pixels')
		expectNear(t.w * scale, 2, '2 screen pixels wide')
		expectEq(t.points[1][1] .. ' ' .. t.points[1][3], 'TOPLEFT TOPLEFT', 'placed in the frame')
		expectEq(t.points[1][2], frame, 'on the frame')
		expectNear(t.points[1][4] + t.w / 2, frame.bw / 2, 'on the frame\'s centre')
		expectEq(t.rotation == nil and t.vertex == nil, true, 'vertical: nothing rotated or warped')
	end
	-- the middle of the gap: window 2's right edge is centerX right of the frame's centre, window 1 width + gap left of it
	local w2Right = frame.bw / 2 - D.centerX
	local w2Left, w1Right = w2Right - D.width, w2Right - D.width - D.gap
	expectNear(frame.bw / 2, (w1Right + w2Left) / 2, 'halfway between window 1\'s right edge and window 2\'s left edge')
	expect(parts[1].points[1][4] > w1Right and parts[1].points[1][4] + parts[1].w < w2Left, 'inside the gap: over neither meter')
	-- one contiguous line, in the interior only
	for i = 2, #parts do expectNear(-parts[i].points[1][5], -parts[i - 1].points[1][5] + parts[i - 1].h, 'contiguous (' .. i .. ')') end
	local top = -parts[1].points[1][5]
	local bottom = top
	for _, t in ipairs(parts) do bottom = bottom + t.h end
	expectNear(top, P.outer + d + V.pad * d, 'from pad x d below the top stalk')
	expectNear(bottom, frame.bh - (P.outer + d + V.pad * d), 'to pad x d above the bottom stalk')
	expect(top >= P.outer + d + 0.5 * d and bottom <= frame.bh - (P.outer + d) - 0.5 * d, 'clear of both stalks')
	expect(bottom - top > 0.7 * (frame.bh - 2 * (P.outer + d)), 'most of the interior\'s height')
	local line = P.outer + d / 2
	local accentBottom = line + (0.78 * TT.size / 2 + TT.gap) + TT.accent
	expect(top >= accentBottom, 'below the titles\' accent lines (' .. top .. ' / ' .. accentBottom .. ')')
	for _, t in ipairs(C.detailsTitles) do
		local x = t.points[1][4]
		local l, r = x, x + t.w
		if t.side ~= 'LEFT' then l, r = x - t.w, x end
		expect(frame.bw / 2 < l or frame.bw / 2 > r, 'clear of the ' .. HK_Plain(t.text.text) .. ' title')
	end
	for _, tie in ipairs(frame.ties) do
		local x = tie.points[1][4]
		expect(frame.bw / 2 < x or frame.bw / 2 > x + tie.w, 'clear of the ' .. tie.corner .. ' rope tie')
	end
	-- the BANZAI gradient, top to bottom, fading ends (a vertical gradient's first colour is the bottom one)
	local function rgb(c) return string.format('%.3f,%.3f,%.3f', c.r, c.g, c.b) end
	local function ref(c) return string.format('%.3f,%.3f,%.3f', c[1], c[2], c[3]) end
	expectEq(#S, 5, 'five stops')
	expectEq(ref(S[1]) .. '|' .. ref(S[3]) .. '|' .. ref(S[4]) .. '|' .. ref(S[5]), ref(Theme.COLORS.lime) .. '|' .. ref(Theme.COLORS.emerald) .. '|' .. ref(Theme.COLORS.violet) .. '|' .. ref(Theme.COLORS.purple), 'lime, emerald, violet, purple')
	expect(S[2][2] > S[2][1] and S[2][2] > S[2][3] and S[2][1] < S[1][1] and S[2][1] > S[3][1], 'a green between lime and emerald')
	expectEq(parts[1].gradient[3].a .. '/' .. rgb(parts[1].gradient[3]), '0/' .. ref(S[1]), 'the top end fades out (lime)')
	expectEq(parts[6].gradient[2].a .. '/' .. rgb(parts[6].gradient[2]), '0/' .. ref(S[5]), 'the bottom end fades out (purple)')
	for i = 2, 5 do
		expectEq(rgb(parts[i].gradient[3]) .. ' -> ' .. rgb(parts[i].gradient[2]), ref(S[i - 1]) .. ' -> ' .. ref(S[i]), 'section ' .. (i - 1) .. ' top to bottom')
		expectEq(parts[i].gradient[1], 'VERTICAL', 'along the line')
	end
	-- the materials: shown over each, a restrained alpha (a little more on the light parchment); nothing added
	local count = #frame.textures
	local stalks = {}
	for i = 1, frame.pieceCount do stalks[i] = frame.pieces[i].texture.shown end
	for _, mode in ipairs({ 'GLASS', 'SOLID', 'PARCHMENT' }) do
		C:Set('panelBackground', mode)
		for _, t in ipairs(parts) do expectEq(t.shown, true, mode .. ': shown') end
		local a = parts[3].gradient[2].a
		expectEq(a, mode == 'PARCHMENT' and V.parchment or V.alpha, mode .. ': the alpha for the material')
		expect(a >= 0.35 and a <= 0.75, mode .. ': restrained, not a beam')
		expectEq(frame.glass.shown, mode ~= 'PARCHMENT', mode .. ': the background as before')
		expectEq(#frame.textures, count, mode .. ': no texture added')
	end
	C:Set('panelBackground', 'GLASS')
	for i = 1, frame.pieceCount do expectEq(frame.pieces[i].texture.shown, stalks[i], 'the outer bamboo frame unchanged') end
	-- Details' own windows and text untouched
	expectEq(#(HK_DetailsWindow.baseframe.textures or {}) + #(HK_DetailsWindow2.baseframe.textures or {}), 0, 'nothing drawn on Details\' windows')
	-- Darren's scale: 2 screen pixels are 1.5 units
	frame.effectiveScale = 0.71
	C:Refresh()
	expectNear(parts[1].w * 0.71 * 1440 / 768, 2, 'at UI scale 0.71: still 2 screen pixels (' .. parts[1].w .. ' units)')
	frame.effectiveScale = nil
	-- a thinner stalk: the divider follows, still clear
	C:Set('borderScale', 0.7)
	expectNear(-parts[1].points[1][5], P.outer + 7 + V.pad * 7, 'border scale 0.7: from pad x d below the thinner stalk')
	C:Set('borderScale', 1)
	-- only while both meters are open; hidden with the frame
	HK_DetailsWindow.ativa = false
	C:Refresh()
	for _, t in ipairs(parts) do expectEq(t.shown, false, 'one meter closed: no divider') end
	HK_DetailsWindow.ativa = true
	C:Set('detailsFrame', false)
	for _, t in ipairs(parts) do expectEq(t.shown, false, 'the Details frame off: no divider') end
	C:Set('detailsFrame', true)
	for _, t in ipairs(parts) do expectEq(t.shown, true, 'back') end
end)

-- 1.3.6
test('1.3.6 the Details centre gutter: genuine empty space between the DAMAGE and HEALING meters - each window 4.5 narrower (207.5, was 212), the gap between them 15 (was 6): 20 screen pixels at Darren\'s 2560 x 1440, UI scale 0.71 - 9 empty, the 2 px divider, 9 empty, both inner edges on whole pixels; the bamboo frame, its place, the windows\' outer edges and the titles exactly as in 1.3.5; the divider centred in the gutter; GLASS, SOLID and HARDKORH PARCHMENT; nothing of Banzai\'s takes the mouse or draws on Details\' windows', function()
	local C = ns.Compat
	local frame = C.detailsFrame
	local D, V, TT, P = C.DETAILS, C.DETAILS_DIVIDER, C.DETAILS_TITLE, C.PANEL
	local PX = 0.71 * 1440 / 768 -- screen pixels per unit at Darren's setup
	HK_DetailsWindow.ativa, HK_DetailsWindow2.ativa = true, true
	C:Set('panelBackground', 'GLASS')
	C:Refresh()
	-- the outer panel and the composition as in 1.3.5
	expectEq(frame.w .. 'x' .. frame.h, '493.31x161', 'the bamboo frame the same size (not widened)')
	expectEq(D.frameWidth .. '/' .. D.centerX .. '/' .. D.right, '493.31/-215/-47.15', 'its size and place beside the windows as before')
	expectEq(frame.points[1][2], HK_DetailsWindow2.baseframe, 'still following the right window')
	expectEq(D.width .. '/' .. D.gap, '207.5/15', 'both meters equally narrower, a real gutter between them')
	expectEq(2 * D.width + D.gap, 2 * 212 + 6, 'the meters and the gutter exactly as wide as the meters and the gap were (430): the outer edges stay')
	-- the gutter: window 2's right edge is centerX right of the frame's centre, window 1's left edge centerX left of it
	local center = frame.bw / 2
	local w2Right, w1Left = center - D.centerX, center + D.centerX
	local w2Left, w1Right = w2Right - D.width, w1Left + D.width
	expectNear(w2Left - w1Right, D.gap, 'the gutter between the meters\' inner edges')
	expectNear((w1Right + w2Left) / 2, center, 'symmetric: the gutter on the frame\'s centre')
	expectNear(w1Right - w1Left, w2Right - w2Left, 'the two meters equally wide')
	expect(math.abs(D.gap * PX - 20) < 0.05, 'about 20 screen pixels at Darren\'s scale (' .. D.gap * PX .. ')')
	-- both inner edges on whole pixels at Darren's scale (counted from the screen's right edge, where the windows are anchored)
	for _, u in ipairs({ -D.right + D.width, -D.right + D.width + D.gap }) do
		expect(math.abs(u * PX - math.floor(u * PX + 0.5)) < 0.05, 'an inner edge on a whole screen pixel (' .. u * PX .. ')')
	end
	-- the divider in the middle of the gutter, empty space either side
	frame.effectiveScale = 0.71
	C:Refresh()
	local parts = frame.divider
	local x0 = parts[1].points[1][4]
	local x1 = x0 + parts[1].w
	expectNear(parts[1].w * PX, 2, 'the divider 2 screen pixels')
	expectNear((x0 + x1) / 2, center, 'centred in the gutter')
	local leftEmpty, rightEmpty = (x0 - w1Right) * PX, (w2Left - x1) * PX
	expect(math.abs(leftEmpty - 9) < 0.05 and math.abs(rightEmpty - 9) < 0.05, 'about 9 empty pixels either side (' .. leftEmpty .. ' / ' .. rightEmpty .. ')')
	expect(leftEmpty >= 8 and rightEmpty >= 8 and (D.gap * PX) <= 20.05 and (D.gap * PX) >= 18, 'within 18 - 20 px, 8 - 9 px a side')
	for _, t in ipairs(parts) do
		expectEq(t.points[1][4], x0, 'one straight line')
		expect(t.points[1][4] > w1Right and t.points[1][4] + t.w < w2Left, 'over neither meter')
		expectEq(t.shown, true, 'shown with both meters open')
	end
	local d = frame.stalkDiameter
	expectNear(-parts[1].points[1][5], P.outer + d + V.pad * d, 'the 1.3.5 bounds: below the top stalk and the titles')
	frame.effectiveScale = nil
	C:Refresh()
	-- the titles exactly where they were in 1.3.5, each over its own meter, clear of the gutter
	local dmg, heal = C.detailsTitles[1], C.detailsTitles[2]
	expectNear(dmg.points[1][4], center - 215 + TT.inset - TT.pad, 'DAMAGE where it was (window 1\'s left edge)')
	local tieX = frame.bw - P.outer - d / 2 - P.tie * d / 2 - TT.bamboo + TT.pad
	expectNear(heal.points[1][4], math.min(center + 215 - TT.inset + TT.pad, tieX), 'HEALING where it was (window 2\'s right edge, clear of the rope tie)')
	expect(dmg.points[1][4] + dmg.w < w1Right and dmg.points[1][4] + TT.pad + dmg.accent.w < w1Right, 'DAMAGE and its accent over the damage meter')
	expect(heal.points[1][4] - heal.w > w2Left and heal.points[1][4] - TT.pad - heal.accent.w > w2Left, 'HEALING and its accent over the healing meter')
	expectEq(HK_Plain(dmg.text.text) .. '/' .. HK_Plain(heal.text.text), 'DAMAGE/HEALING', 'the titles')
	expect(dmg.style.bright[1] > dmg.style.bright[2] and heal.style.bright[2] > heal.style.bright[1], 'DAMAGE red, HEALING green')
	-- the materials: the gutter and the divider over each, the frame unchanged
	local count = #frame.textures
	for _, mode in ipairs({ 'GLASS', 'SOLID', 'PARCHMENT' }) do
		C:Set('panelBackground', mode)
		expectEq(frame.w .. 'x' .. frame.h, '493.31x161', mode .. ': the frame the same size')
		for _, t in ipairs(parts) do expectEq(t.shown, true, mode .. ': the divider shown') end
		expectEq(parts[3].gradient[2].a, mode == 'PARCHMENT' and V.parchment or V.alpha, mode .. ': its alpha for the material (0.5 / 0.72)')
		expectEq(#frame.textures, count, mode .. ': nothing added in the gutter')
	end
	C:Set('panelBackground', 'GLASS')
	-- Details' interaction untouched: Banzai's frame and titles take no mouse, nothing is drawn on Details' windows
	expectEq(frame.mouse, false, 'the Banzai Details frame takes no mouse (behind the windows, BACKGROUND)')
	expectEq(dmg.mouse == false and heal.mouse == false, true, 'the titles take no mouse')
	expectEq(#(HK_DetailsWindow.baseframe.textures or {}) + #(HK_DetailsWindow2.baseframe.textures or {}), 0, 'nothing drawn on Details\' windows')
end)

---------------------------------------------------------------------------
-- 1.3.7
---------------------------------------------------------------------------
-- a parchment piece as placed: { x0, y0, x1, y1 } from the parchment rectangle's top-left (both corners anchored)
local function parchmentRect(holder, t)
	local P = ns.Compat.PANEL
	local inset = P.outer + P.parchment * holder.stalkDiameter
	local a, b = t.points[1], t.points[2]
	return a[4] - inset, -a[5] - inset, b[4] - inset, -b[5] - inset, a, b
end

test('1.3.7 HARDKORH PARCHMENT is one material that never stretches: on BUFFS (2 and 3 rows), chat and Details - and at narrow, square, medium-wide and very wide synthetic sizes - the body is one tile repeating at 2 texels per unit on both axes from the panel\'s own fixed phase, the corners keep their shape, the worn strips repeat along their edge (mirrored halves, phase 0 at every corner), one corner size thick everywhere; the pieces share their sides exactly - nothing overlaps, nothing is left open', function()
	local C = ns.Compat
	local M, P = C.PARCHMENT, C.PANEL
	expectEq(M.tileW .. 'x' .. M.tileH .. '/' .. M.density .. '/' .. M.edgeW .. 'x' .. M.edgeH .. '/' .. M.corners .. '/' .. M.period, '1024x512/2/512x256/128/8', 'the material\'s numbers (tools/lib/panel.js PARCHMENT)')
	-- every layout, real and synthetic: texels per unit the same on both axes of every piece kind, whatever the size
	local function check(pw, ph, d, kind, label)
		local pieces, c, period = C.ParchmentLayout(pw, ph, d, kind)
		expectEq(#pieces, 13, label .. ': the body, 4 corners, 8 edge halves')
		expectNear(c, math.min(P.parchmentCorner * d, pw / 2, ph / 2), label .. ': the corner size / band')
		expectNear(period, M.period * c, label .. ': one strip period = 8 corner sizes (512 texels)')
		local byName = {}
		for _, q in ipairs(pieces) do byName[q.name] = q end
		local body = byName.body
		expectEq(body.x0 .. ',' .. body.y0 .. ',' .. body.x1 .. ',' .. body.y1, '0,0,' .. pw .. ',' .. ph, label .. ': the body covers the whole paper')
		local k = body.coords
		expectEq(k[1] .. ',' .. k[2], (M.phase[kind] or M.phase.chat)[1] .. ',' .. (M.phase[kind] or M.phase.chat)[2], label .. ': from the panel\'s own phase')
		expectNear((k[5] - k[1]) * M.tileW / pw, M.density, label .. ': 2 texels per unit across')
		expectNear((k[4] - k[2]) * M.tileH / ph, M.density, label .. ': 2 texels per unit down (the same: nothing stretched)')
		expectEq(k[3] .. ',' .. k[6] .. ',' .. k[7] .. ',' .. k[8], k[1] .. ',' .. k[2] .. ',' .. k[5] .. ',' .. k[4], label .. ': an upright rectangle of the tile (no turn, no shear)')
		local texelsPerUnit = (M.corners / 2) / c -- the corner atlas and the strips: one corner size = 64 texels
		local quadrant = { TOPLEFT = '0,0,0,0.5,0.5,0,0.5,0.5', TOPRIGHT = '0.5,0,0.5,0.5,1,0,1,0.5', BOTTOMLEFT = '0,0.5,0,1,0.5,0.5,0.5,1', BOTTOMRIGHT = '0.5,0.5,0.5,1,1,0.5,1,1' }
		for _, name in ipairs({ 'TOPLEFT', 'TOPRIGHT', 'BOTTOMLEFT', 'BOTTOMRIGHT' }) do
			local q = byName[name]
			expectEq(table.concat(q.coords, ','), quadrant[name], label .. ' ' .. name .. ': its own quadrant of the atlas, upright')
			expectNear(q.x1 - q.x0, c, label .. ' ' .. name .. ': a corner size wide')
			expectNear(q.y1 - q.y0, c, label .. ' ' .. name .. ': as tall (square: never stretched)')
			expectNear(math.abs(q.coords[5] - q.coords[1]) * M.corners / (q.x1 - q.x0), texelsPerUnit, label .. ' ' .. name .. ': 64 texels across the corner')
			expectNear(math.abs(q.coords[4] - q.coords[2]) * M.corners / (q.y1 - q.y0), texelsPerUnit, label .. ' ' .. name .. ': and 64 down')
		end
		for _, name in ipairs({ 'top1', 'top2', 'bottom1', 'bottom2', 'left1', 'left2', 'right1', 'right2' }) do
			local q = byName[name]
			local horizontal = name:find('top') or name:find('bottom')
			local length, thick = horizontal and (q.x1 - q.x0) or (q.y1 - q.y0), horizontal and (q.y1 - q.y0) or (q.x1 - q.x0)
			expectNear(thick, c, label .. ' ' .. name .. ': one corner size thick (the same edge on every panel)')
			-- along: u runs over the strip's length (UL -> UR for a top / bottom strip, UL -> LL for a side strip)
			local du = horizontal and math.abs(q.coords[5] - q.coords[1]) or math.abs(q.coords[3] - q.coords[1])
			local dv = horizontal and math.abs(q.coords[4] - q.coords[2]) or math.abs(q.coords[6] - q.coords[2])
			if length > 0 then expectNear(du * M.edgeW / length, texelsPerUnit, label .. ' ' .. name .. ': repeated along at the corners\' density (never stretched)') end
			expectNear(dv * M.edgeH / thick, texelsPerUnit, label .. ' ' .. name .. ': and across')
			expectNear(dv, 0.25, label .. ' ' .. name .. ': one strip of the four')
		end
		-- phase 0 where each strip meets its corner, the two halves on the same texel in the middle
		expectEq(byName.top1.coords[1] .. '/' .. byName.top2.coords[5] .. '/' .. byName.bottom1.coords[1] .. '/' .. byName.bottom2.coords[5], '0/0/0/0', label .. ': top / bottom strips start at their corners')
		expectEq(byName.left1.coords[1] .. '/' .. byName.left2.coords[3] .. '/' .. byName.right1.coords[1] .. '/' .. byName.right2.coords[3], '0/0/0/0', label .. ': side strips start at their corners')
		expectEq(byName.top1.coords[5], byName.top2.coords[1], label .. ': the top halves meet on the same texel')
		expectEq(byName.left1.coords[3], byName.left2.coords[1], label .. ': the side halves meet on the same texel')
		-- the rows of the strip texture: top 0, right 1, bottom 2, left 3 (outer side first on even rows)
		expectEq(byName.top1.coords[2] .. '>' .. byName.top1.coords[4], '0>0.25', label .. ': top: row 0, outer side up')
		expectEq(byName.right1.coords[2] .. '>' .. byName.right1.coords[6], '0.25>0.5', label .. ': right: row 1, outer side right')
		expectEq(byName.bottom1.coords[4] .. '>' .. byName.bottom1.coords[2], '0.5>0.75', label .. ': bottom: row 2, outer side down')
		expectEq(byName.left1.coords[2] .. '>' .. byName.left1.coords[6], '1>0.75', label .. ': left: row 3, outer side left')
		-- shared sides (the same numbers) and no overlap between worn pieces; together exactly the band around the middle
		expectEq(byName.TOPLEFT.x1 .. ',' .. byName.top1.x1 .. ',' .. byName.top2.x1, byName.top1.x0 .. ',' .. byName.top2.x0 .. ',' .. byName.TOPRIGHT.x0, label .. ': top row shares its sides')
		expectEq(byName.TOPLEFT.y1 .. ',' .. byName.left1.y1 .. ',' .. byName.left2.y1, byName.left1.y0 .. ',' .. byName.left2.y0 .. ',' .. byName.BOTTOMLEFT.y0, label .. ': left column shares its sides')
		expectEq(byName.TOPRIGHT.y1 .. ',' .. byName.right1.y1 .. ',' .. byName.right2.y1, byName.right1.y0 .. ',' .. byName.right2.y0 .. ',' .. byName.BOTTOMRIGHT.y0, label .. ': right column shares its sides')
		expectEq(byName.BOTTOMLEFT.x1 .. ',' .. byName.bottom1.x1 .. ',' .. byName.bottom2.x1, byName.bottom1.x0 .. ',' .. byName.bottom2.x0 .. ',' .. byName.BOTTOMRIGHT.x0, label .. ': bottom row shares its sides')
		local area, worn = 0, {}
		for _, q in ipairs(pieces) do if q.texture ~= 'tile' then worn[#worn + 1] = q area = area + (q.x1 - q.x0) * (q.y1 - q.y0) end end
		for i = 1, #worn do for j = i + 1, #worn do
			local a, b = worn[i], worn[j]
			local w = math.min(a.x1, b.x1) - math.max(a.x0, b.x0)
			local h = math.min(a.y1, b.y1) - math.max(a.y0, b.y0)
			expect(w <= 1e-9 or h <= 1e-9, label .. ': ' .. a.name .. ' and ' .. b.name .. ' do not overlap (no doubled darkening)')
		end end
		expectNear(area, pw * ph - (pw - 2 * c) * (ph - 2 * c), label .. ': the worn pieces cover exactly the band')
		return c
	end
	local d = C.PANEL.stalk
	local bands = {}
	for _, holder in ipairs({ C.chatFrame, C.detailsFrame, C.buffsFrame }) do
		local inset = P.outer + P.parchment * holder.stalkDiameter
		bands[#bands + 1] = check(holder.bw - 2 * inset, holder.bh - 2 * inset, holder.stalkDiameter, holder.artKind, holder.artKind)
	end
	C:Set('buffsRows', 3)
	local inset = P.outer + P.parchment * d
	bands[#bands + 1] = check(C.buffsFrame.bw - 2 * inset, C.buffsFrame.bh - 2 * inset, d, 'buffs', 'buffs (3 rows)')
	C:Set('buffsRows', 2)
	for _, size in ipairs({ { 120, 330, 'narrow' }, { 260, 260, 'square' }, { 560, 200, 'medium-wide' }, { 1400, 150, 'very wide' } }) do
		bands[#bands + 1] = check(size[1] - 2 * inset, size[2] - 2 * inset, d, 'details', size[3])
	end
	for _, c in ipairs(bands) do expectNear(c, P.parchmentCorner * d, 'the same corner size and edge thickness on every panel and size (24)') end
	-- the phases: fixed, and chat / Details (the same size) different pieces of the paper
	expect(M.phase.chat[1] ~= M.phase.details[1] and M.phase.chat[2] ~= M.phase.details[2], 'chat and Details show different paper')
	-- a thinner stalk: the edge follows the stalk, the grain does not
	local thin = C.ParchmentLayout(400, 140, 7, 'chat')
	expectNear(thin[2].x1, P.parchmentCorner * 7, 'border scale 70 %: the corner / edge 2.4 x the thinner stalk')
	expectNear((thin[1].coords[5] - thin[1].coords[1]) * M.tileW / 400, M.density, 'the grain the same size at any border scale')
end)

test('1.3.7 the parchment on the panels: 13 textures per panel made once (the body under the worn pieces, the three Banzai textures with their wrap modes), each piece anchored at both corners exactly where the layout puts it; re-laid out only when the size or the stalk changes; brightness 70 - 110 % on every piece alike; GLASS and SOLID exactly as before; no OnUpdate, no ticker', function()
	local C = ns.Compat
	local P = C.PANEL
	local tickers = #HK_TICKERS
	local paths = { tile = Theme.MEDIA .. 'BanzaiParchmentTile', corners = Theme.MEDIA .. 'BanzaiParchmentCorners', edge = Theme.MEDIA .. 'BanzaiParchmentEdge' }
	local wraps = { tile = 'REPEAT/REPEAT', corners = 'CLAMP/CLAMP', edge = 'REPEAT/CLAMP' }
	local frames = { C.chatFrame, C.detailsFrame, C.buffsFrame }
	for _, holder in ipairs(frames) do
		local label = holder.artKind
		local d = holder.stalkDiameter
		local inset = P.outer + P.parchment * d
		local pieces = C.ParchmentLayout(holder.bw - 2 * inset, holder.bh - 2 * inset, d, holder.artKind)
		expectEq(#holder.parchment, 13, label .. ': 13 parchment textures')
		for i, q in ipairs(pieces) do
			local t = holder.parchment[i]
			expectEq(t.path, paths[q.texture], label .. ' ' .. q.name .. ': the Banzai texture')
			expectEq(t.wrapH .. '/' .. t.wrapV .. '/' .. t.filter, wraps[q.texture] .. '/TRILINEAR', label .. ' ' .. q.name .. ': its wrap modes (the tile repeats both ways, the strips along)')
			expectEq(t.layer .. ' ' .. t.sublevel, 'BACKGROUND ' .. (q.texture == 'tile' and 0 or 1), label .. ' ' .. q.name .. ': the body under the worn pieces, all under the divider and the stalks')
			expectEq(t.piece, q.name, label .. ': piece ' .. i)
			local x0, y0, x1, y1, a, b = parchmentRect(holder, t)
			expectEq(a[1] .. '/' .. a[3] .. '/' .. b[1] .. '/' .. b[3], 'TOPLEFT/TOPLEFT/BOTTOMRIGHT/TOPLEFT', label .. ' ' .. q.name .. ': both corners on the holder')
			expectNear(x0, q.x0, label .. ' ' .. q.name .. ' left') expectNear(y0, q.y0, label .. ' ' .. q.name .. ' top')
			expectNear(x1, q.x1, label .. ' ' .. q.name .. ' right') expectNear(y1, q.y1, label .. ' ' .. q.name .. ' bottom')
			expectEq(table.concat(t.coords, ','), table.concat(q.coords, ','), label .. ' ' .. q.name .. ': its texture coordinates')
			expectEq(t.w, nil, label .. ' ' .. q.name .. ': no size of its own (no overlap allowance)')
		end
	end
	-- brightness: every piece of every panel the same vertex colour
	C:Set('panelBackground', 'PARCHMENT')
	for _, b in ipairs({ 0.7, 1, 1.1 }) do
		C:Set('parchmentBrightness', b)
		for _, holder in ipairs(frames) do
			for _, t in ipairs(holder.parchment) do
				expectNear(t.color[1], 0.91 * b, holder.artKind .. ' ' .. t.piece .. ': brightness ' .. b)
				expectEq(t.color[1] == t.color[2] and t.color[2] == t.color[3] and t.color[4] == 1, true, holder.artKind .. ' ' .. t.piece .. ': neutral, opaque')
				expectEq(t.shown, true, holder.artKind .. ' ' .. t.piece .. ': shown on PARCHMENT')
			end
			expectEq(holder.glass.shown, false, holder.artKind .. ': no glass under the parchment')
		end
	end
	C:Set('parchmentBrightness', 1)
	-- a size change lays it out again with the same textures; the same size does nothing
	local buffs = C.buffsFrame
	local textures, before = #buffs.textures, buffs.parchment[1].coords
	C:Refresh()
	expectEq(buffs.parchment[1].coords, before, 'the same size: not laid out again')
	C:Set('buffsRows', 3)
	expectEq(#buffs.textures, textures, '3 rows: the same textures')
	local k = buffs.parchment[1].coords
	expectNear((k[4] - k[2]) * C.PARCHMENT.tileH, (buffs.bh - 2 * (P.outer + P.parchment * buffs.stalkDiameter)) * C.PARCHMENT.density, '3 rows: more paper, the same grain')
	C:Set('buffsRows', 2)
	-- GLASS and SOLID exactly as before, the frame the same whatever the material
	local function frameState(holder)
		local out = {}
		for i = 1, holder.pieceCount do local t = holder.pieces[i].texture out[#out + 1] = table.concat(t.coords, ',') .. '@' .. t.points[1][4] .. ',' .. t.points[1][5] .. ':' .. t.w .. 'x' .. t.h end
		for _, t in ipairs(holder.ties) do out[#out + 1] = t.points[1][4] .. ',' .. t.points[1][5] .. ':' .. t.w end
		local g = holder.glass
		out[#out + 1] = g.points[1][4] .. ',' .. g.points[1][5] .. ':' .. g.w .. 'x' .. g.h .. ':' .. tostring(g.path)
		return table.concat(out, '|')
	end
	for _, holder in ipairs(frames) do
		C:Set('panelBackground', 'GLASS')
		local glass = frameState(holder)
		expectNear(holder.glass.points[1][4], P.outer + holder.stalkDiameter / 2, holder.artKind .. ': GLASS up to the stalk axis, as before')
		expectNear(holder.glass.gradient[3].a, Theme:DB().glassOpacity, holder.artKind .. ': GLASS at the glass opacity')
		for _, t in ipairs(holder.parchment) do expectEq(t.shown, false, holder.artKind .. ': no parchment on GLASS') end
		C:Set('panelBackground', 'SOLID')
		expectNear(holder.glass.gradient[3].a, 0.97, holder.artKind .. ': SOLID nearly opaque, as before')
		expectEq(frameState(holder), glass, holder.artKind .. ': SOLID - the frame, stalks, ties and glass where they were')
		C:Set('panelBackground', 'PARCHMENT')
		expectEq(frameState(holder), glass, holder.artKind .. ': PARCHMENT - the frame, stalks, ties and glass where they were')
	end
	C:Set('panelBackground', 'GLASS')
	-- the 1.3.6 Details gutter and the divider untouched by the material
	local D = C.DETAILS
	expectEq(D.width .. '/' .. D.gap .. '/' .. D.frameWidth .. 'x' .. D.frameHeight, '207.5/15/493.31x161', 'the 1.3.6 gutter and the Details frame')
	expectEq(C.detailsFrame.divider[1].layer, 'BORDER', 'the divider over the parchment (BORDER over BACKGROUND)')
	-- static: nothing runs per frame
	for _, holder in ipairs(frames) do expectEq(holder.scripts.OnUpdate, nil, holder.artKind .. ': no OnUpdate') end
	expectEq(#HK_TICKERS, tickers, 'no ticker')
end)
