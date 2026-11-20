-- BushidoPrivateCompat (Banzai Art, 1.5.1): the BAR TEXTURE (BANZAI Smooth | BANZAI Weave) against mocked ElvUI
-- frames. Its own suite, so the targeted mutants of the bar texture run in seconds (node tests/run.js barweave).
-- The frames and the profile below are the ones tests/test_compat.lua builds on.
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

test('Banzai Art builds on the Banzai profile with the BANZAI default, BANZAI Weave: the dressed Player bars get the material (two regions and the sizer, nothing else), the frame itself nothing new; BANZAI Smooth puts them back exactly as before 1.5.1', function()
	player.Health.w, player.Health.h, player.Power.w, player.Power.h = 300, 22, 302, 7
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	expectEq(ns.Compat.lastError, nil, 'no error while building')
	expectEq(Theme:DB().barTexture, 'WEAVE', 'BANZAI Weave is the default')
	expectEq(Theme:BarTextureKey(), 'WEAVE', 'and in use')
	expectEq(#HK_Children(player), 3, 'player: backdrop + trough + end bundle, as before 1.5.1 - nothing new on the frame')
	local hp, pp = Theme:BarWeaveOf(player.Health), Theme:BarWeaveOf(player.Power)
	expect(hp and pp, 'the Player health and resource bars are known to the bar texture')
	expect(hp.sheet.shown and hp.base.shown, 'the Player health bar shows the weave by default: slashes and the textured empty part')
	expect(pp.sheet.shown and pp.base.shown, 'the Player resource bar too')
	expectEq(#(player.Health.textures or {}), 2, 'two regions on the health bar')
	expectEq(#HK_Children(player.Health), 3, 'its ElvUI backdrop, the health texts\' holder and the sizer')
	expect(Theme:RefreshBarWeave() >= 2, 'bars show the weave')
	expectEq(BanzaiCompat:Set('barTexture', 'SMOOTH'), true, 'BANZAI Smooth can be chosen')
	expectEq(Theme:RefreshBarWeave(), 0, 'BANZAI Smooth: no bar shows the weave')
	expectEq(hp.sheet.shown or hp.base.shown or pp.sheet.shown or pp.base.shown, false, 'the Player bars are plain again')
	expectEq(player.Health.statusTexture, nil, 'ElvUI\'s own bar texture was never set by BANZAI')
end)

---------------------------------------------------------------------------
-- 1.5.1 BAR TEXTURE: BANZAI Smooth | BANZAI Weave (1.5.1: the slashed surface, filled and empty part alike)
---------------------------------------------------------------------------
local STRANDS = Theme.MEDIA .. 'BanzaiWeaveStrands'
local SMOOTH_FILE = Theme.MEDIA .. 'BanzaiBar'
-- a status bar of w x h units (200 x 24 unless given) at an effective scale
local function WeaveBar(level, scale, w, h)
	local bar = HK_NewFrame('StatusBar', nil, UIParent)
	bar.level, bar.effectiveScale = level or 10, scale
	bar.w, bar.h = w or 200, h or 24
	bar:SetMinMaxValues(0, 1)
	bar:SetStatusBarTexture(SMOOTH_FILE)
	return bar
end
local function ChooseBars(key) expectEq(BanzaiCompat:Set('barTexture', key), true, 'the setting is accepted') end
local function Brightness(c) return (c.r + c.g + c.b) / 3 end
local function Regions(bar) return #(bar.textures or {}) end

test('1.5.1 bar texture setting: BANZAI Weave is the BANZAI default and BANZAI Smooth the selectable alternative; the choice is kept per character in the saved variables, an unknown value is the default, Character Sync carries it', function()
	expectEq(Theme.DEFAULTS.barTexture, 'WEAVE', 'the default is BANZAI Weave')
	expectEq(Theme.BAR_TEXTURE_DEFAULT, 'WEAVE', 'named as the default')
	expectEq(Theme.BAR_TEXTURE_FALLBACK, 'SMOOTH', 'BANZAI Smooth is what is drawn when the weave cannot be')
	expectEq(table.concat(Theme.BAR_TEXTURE_ORDER, ','), 'WEAVE,SMOOTH', 'both choices, the default first')
	expectEq(Theme.BAR_TEXTURES.SMOOTH.label .. '|' .. Theme.BAR_TEXTURES.WEAVE.label, 'BANZAI Smooth|BANZAI Weave', 'their names')
	expectEq(Theme.BAR_TEXTURES.SMOOTH.strands, nil, 'BANZAI Smooth adds nothing')
	local db = Theme:DB()
	db.barTexture = nil
	expectEq(Theme:DB().barTexture, 'WEAVE', 'a character without the setting gets BANZAI Weave')
	ChooseBars('SMOOTH')
	expectEq(BanzaiCompat:Get('barTexture'), 'SMOOTH', 'BANZAI Smooth chosen: read back')
	expectEq(Theme:BarTextureKey(), 'SMOOTH', 'in use')
	-- what a reload keeps: the character's table inside the saved variable
	expectEq(BanzaiCompatDB.chars[Theme.CharKey()].barTexture, 'SMOOTH', 'written to BanzaiCompatDB (kept across /reload)')
	expectEq(Theme:DB().barTexture, 'SMOOTH', 'a new read (as after a reload) keeps the choice: the default never overrides it')
	expectEq(Theme:Export().barTexture, 'SMOOTH', 'Character Sync exports it')
	Theme:Import({ barTexture = 'WEAVE' })
	expectEq(Theme:DB().barTexture, 'WEAVE', 'Character Sync imports it')
	db.barTexture = 'CARBON'
	expectEq(Theme:DB().barTexture, 'WEAVE', 'an unknown value is brought back to the BANZAI default')
	expectEq(Theme:BarTextureKey(), 'WEAVE', '... which is drawn')
	ChooseBars('SMOOTH')
end)

test('1.5.1 upgrade: a character from 1.5.0 (no stored bar texture) and a character of the private 1.5.1 proofs (their default, Smooth, written without a choice) both follow the BANZAI default once; a choice made from then on is kept through every later load', function()
	local root = BanzaiCompatDB
	-- 1.5.0: schema 9, the setting did not exist
	root.chars['Released - Realm'] = { schema = 9, theme = 'VIBRANT' }
	local released = Theme:DB('Released - Realm')
	expectEq(released.schema, 10, 'migrated to schema 10')
	expectEq(released.barTexture, 'WEAVE', 'a 1.5.0 character gets BANZAI Weave')
	expectEq(released.theme, 'VIBRANT', 'its other settings are untouched')
	-- a private proof build: schema 9, Smooth filled in as that build's default
	root.chars['Proof - Realm'] = { schema = 9, barTexture = 'SMOOTH', theme = 'CLASS', frameStyle = 'SPLIT' }
	local proof = Theme:DB('Proof - Realm')
	expectEq(proof.barTexture, 'WEAVE', 'the proof\'s written default is not a choice: BANZAI Weave')
	expectEq(proof.theme .. proof.frameStyle, 'CLASSSPLIT', 'nothing else is changed by the step')
	-- from here on a stored value is the character's own
	proof.barTexture = 'SMOOTH'
	expectEq(Theme:DB('Proof - Realm').barTexture, 'SMOOTH', 'BANZAI Smooth chosen on 1.5.1 is kept')
	expectEq(Theme:DB('Proof - Realm').barTexture, 'SMOOTH', 'and kept again (the step runs once)')
	expectEq(Theme:DB('Proof - Realm').schema, 10, 'schema 10')
	root.chars['Released - Realm'], root.chars['Proof - Realm'] = nil, nil
end)

test('1.5.1 LibSharedMedia: BANZAI Smooth and BANZAI Weave registered as statusbar textures once, at load - "Banzai" stays for the profiles that name it; choosing and refreshing never register again', function()
	local media = LibStub('LibSharedMedia-3.0')
	expectEq(media:Fetch('statusbar', 'BANZAI Weave'), Theme.MEDIA .. 'BanzaiWeave.tga', 'BANZAI Weave: the tintable sheet')
	expectEq(media:Fetch('statusbar', 'BANZAI Smooth'), Theme.MEDIA .. 'BanzaiBar.tga', 'BANZAI Smooth: the bar as it was')
	expectEq(media:Fetch('statusbar', 'Banzai'), Theme.MEDIA .. 'BanzaiBar.tga', 'the name the written profiles use')
	expect(media:IsValid('statusbar', 'BANZAI Weave') and media:IsValid('statusbar', 'BANZAI Smooth'), 'valid media')
	ChooseBars('WEAVE')
	BanzaiCompat:Refresh()
	BanzaiCompat.RefreshAll(BanzaiCompat)
	Theme:RefreshBarWeave()
	ChooseBars('SMOOTH')
	for _, name in ipairs({ 'Banzai', 'BANZAI Smooth', 'BANZAI Weave' }) do
		expectEq(HK_LSM_REGISTERED['statusbar:' .. name], 1, name .. ' registered exactly once')
	end
	expectEq(Theme.statusbarRegistered, true, 'registered by the media block of Theme.lua')
end)

test('1.5.1 BANZAI Smooth is the bar as it was (nothing is made on it); BANZAI Weave is one material over the whole bar - a dark neutral empty surface under the fill and the slash sheet over it, both regions of the bar itself, one texel per screen pixel; back to Smooth hides both', function()
	ChooseBars('SMOOTH')
	local bar = WeaveBar(10, 0.71)
	local before = Theme:BarWeaveCount()
	local entry = Theme:BarWeave(bar)
	expect(entry and entry.bar == bar, 'the bar is known')
	expectEq(Theme:BarWeaveCount(), before + 1, 'counted once')
	expectEq(entry.sheet, nil, 'BANZAI Smooth: nothing is made on the bar')
	expectEq(Regions(bar), 0, 'no texture')
	expectEq(#HK_Children(bar), 0, 'no child frame')
	expectEq(bar.statusTexture, SMOOTH_FILE, 'the bar keeps its own texture')
	expectEq(Theme:BarWeave(bar), entry, 'asking again returns the same entry')
	expectEq(Theme:BarWeaveCount(), before + 1, 'never twice')
	expectEq(Theme:BarWeaveOf(bar), entry, 'looked up by the bar')
	ChooseBars('WEAVE')
	local base, sheet, sizer = entry.base, entry.sheet, entry.sizer
	expect(base and sheet and sizer, 'BANZAI Weave: the two regions and the sizer are made')
	-- the empty surface: under the fill, the whole bar, dark and neutral - not black, not bright, not the bar's colour
	expectEq(base.parent, bar, 'the empty surface is a region of the bar')
	expectEq(base.kind, 'Texture', 'a texture')
	expectEq(base.layer .. '|' .. tostring(base.sublevel), 'BORDER|7', 'under the fill (the bar\'s BORDER layer)')
	expectEq(base.allPoints, bar, 'the whole bar: the fill covers it where the bar is filled')
	expectEq(base.path, Theme.WHITE, 'a plain surface')
	expectEq(base.shown, true, 'shown')
	local g = base.gradient
	expectEq(g[1], 'VERTICAL', 'shaded top to bottom like the trough')
	local E = Theme.WEAVE.empty
	expectNear(g[3].r, E.top[1], 'top colour') expectNear(g[2].b, E.bottom[3], 'bottom colour')
	for _, c in ipairs({ g[2], g[3] }) do
		expect(Brightness(c) >= 0.07 and Brightness(c) <= 0.22, 'dark, but not black: ' .. Brightness(c))
		expect(math.max(c.r, c.g, c.b) - math.min(c.r, c.g, c.b) <= 0.04, 'neutral: no health colour in the empty part')
		expectEq(c.a, 1, 'opaque: the slashes do not fade out with what is behind the bar')
	end
	expect(Brightness(g[3]) > 2 * ((0.045 + 0.080 + 0.064) / 3), 'clearly lighter than the plain trough, so the slashes read on it')
	expect(Brightness(g[3]) < 0.25, 'far darker than any fill: subordinate to it')
	-- the slash sheet: over the fill, the whole bar, pixel-locked
	expectEq(sheet.parent, bar, 'the sheet is a region of the bar (every frame on the bar is above it)')
	expectEq(sheet.kind, 'Texture', 'a texture')
	expectEq(sheet.layer .. '|' .. tostring(sheet.sublevel), 'OVERLAY|-8', 'over the fill and the colour painted on it')
	expectEq(sheet.allPoints, bar, 'the whole bar - filled and empty part alike')
	expectEq(sheet.path, STRANDS, 'the slash layer')
	expectEq(sheet.wrapH .. '|' .. sheet.wrapV, 'REPEAT|REPEAT', 'repeating both ways')
	expectEq(sheet.filter, 'NEAREST', 'the texels themselves, not a blend of them')
	local px = Theme.PixelScale(bar)
	expectNear(px, 0.71 * 1440 / 768, 'Darren\'s scale: 1.33 screen pixels per unit')
	expectEq(sheet.coords[1] + sheet.coords[3], 0, 'from the sheet\'s corner at the bar\'s top-left')
	expectNear(sheet.coords[2] * 256, 200 * px, 'across: as many texels as the bar has screen pixels')
	expectNear(sheet.coords[4] * 64, 24 * px, 'down: as many texels as the bar has screen pixels')
	expectEq(sheet.shown, true, 'shown')
	-- the sizer: BANZAI's own empty frame of the bar's size
	expectEq(sizer.parent, bar, 'the sizer') expectEq(sizer.allPoints, bar, 'the bar\'s size')
	expectEq(Regions(sizer), 0, 'it draws nothing')
	expectEq(sizer.mouse, false, 'never in the way of the mouse')
	expectEq(#HK_Children(bar), 1, 'the only frame made on the bar')
	expectEq(Regions(bar), 2, 'two regions, no more')
	-- the bar itself is not changed
	expectEq(bar.statusTexture, SMOOTH_FILE, 'the bar\'s own texture is still BANZAI Smooth')
	expectEq(bar.fill.alpha, nil, 'its fill is not faded') expectEq(bar.fill.shown, true, 'nor hidden')
	ChooseBars('SMOOTH')
	expectEq(sheet.shown, false, 'BANZAI Smooth: the sheet is hidden')
	expectEq(base.shown, false, 'and the empty surface with it')
	ChooseBars('WEAVE')
	expectEq(entry.sheet, sheet, 'the same regions again (made once)')
	expectEq(Regions(bar), 2, 'nothing made twice')
	expect(sheet.shown and base.shown, 'shown again')
	expectEq(Theme:BarWeave(nil), nil, 'nothing for nothing')
	expectEq(Theme:BarWeave({}), nil, 'nothing for something that is not a status bar')
	ChooseBars('SMOOTH')
end)

test('1.5.1 the moving fill: at 100 %, 70 %, 25 % and 0 % the material is the same sheet over the same whole bar - the slashes continue from the fill into the empty part, nothing follows the value and no value is read', function()
	ChooseBars('WEAVE')
	local bar = WeaveBar(10, 0.71)
	local reads = 0
	bar.GetValue = function() reads = reads + 1 return 1 end
	local entry = Theme:BarWeave(bar)
	local seen
	for _, value in ipairs({ 1, 0.7, 0.25, 0 }) do
		bar:SetValue(value)
		Theme:RefreshBarWeave()
		local now = table.concat({ entry.sheet.path, table.concat(entry.sheet.coords, ','), tostring(entry.sheet.allPoints == bar), tostring(entry.base.allPoints == bar), tostring(entry.sheet.shown), tostring(entry.base.shown) }, '|')
		seen = seen or now
		expectEq(now, seen, value .. ': the same material as at 100 %')
		expectEq(#entry.sheet.points + #entry.base.points, 0, value .. ': neither region is tied to the fill')
	end
	expect(entry.sheet.allPoints ~= bar.fill and entry.base.allPoints ~= bar.fill, 'the fill only uncovers the empty surface; it carries nothing')
	expectEq(reads, 0, 'the bar\'s value is never read')
	ChooseBars('SMOOTH')
end)

test('1.5.1 a bar with BANZAI\'s own dark track: the track itself becomes the textured empty surface under BANZAI Weave and the plain trough again under BANZAI Smooth - no second surface is made', function()
	ChooseBars('SMOOTH')
	local holder = HK_NewFrame('Frame', nil, UIParent)
	local track = holder:CreateTexture(nil, 'BACKGROUND')
	Theme:Trough(track)
	local trough = Brightness(track.gradient[3])
	local bar = WeaveBar(10)
	local entry = Theme:BarWeave(bar, track)
	expectNear(Brightness(track.gradient[3]), trough, 'BANZAI Smooth: the trough is not touched')
	ChooseBars('WEAVE')
	expectEq(entry.base, track, 'the track is the empty surface')
	expectEq(entry.ownBase, false, 'none of its own')
	expectEq(Regions(bar), 1, 'the bar gets the sheet only')
	expectNear(track.gradient[3].g, Theme.WEAVE.empty.top[2], 'the track in the empty surface\'s colour')
	expectEq(track.shown, true, 'shown')
	ChooseBars('SMOOTH')
	expectNear(Brightness(track.gradient[3]), trough, 'BANZAI Smooth: the plain dark trough again')
	expectEq(track.shown, true, 'the track itself is never hidden')
	expectEq(entry.sheet.shown, false, 'the sheet is hidden')
end)

test('1.5.1 UI scale and size: at 100 %, 125 % and 150 % one texel is one screen pixel - the slashes never grow with the scale; a new scale, resolution or bar size lays the sheet out again by event, nothing polls; a bar without a size yet shows nothing until it has one', function()
	ChooseBars('WEAVE')
	local tickers = #HK_TICKERS
	for _, pxPerUnit in ipairs({ 1, 1.25, 1.5 }) do
		local bar = WeaveBar(10, pxPerUnit * 768 / 1440, 230, 24)
		local entry = Theme:BarWeave(bar)
		expectNear(Theme.PixelScale(bar), pxPerUnit, 'pixels per unit')
		expectNear(entry.sheet.coords[2] * 256 / (230 * pxPerUnit), 1, pxPerUnit .. ': texels per screen pixel across')
		expectNear(entry.sheet.coords[4] * 64 / (24 * pxPerUnit), 1, pxPerUnit .. ': texels per screen pixel down')
	end
	local bar = WeaveBar(10, 768 / 1440, 230, 24)
	local entry = Theme:BarWeave(bar)
	expectNear(entry.sheet.coords[2] * 256, 230, '100 %')
	bar.effectiveScale = 1.5 * 768 / 1440
	HK_Fire('UI_SCALE_CHANGED')
	expectNear(entry.sheet.coords[2] * 256, 345, 'counted again for the new scale')
	bar.effectiveScale = 1.25 * 768 / 1440
	HK_Fire('DISPLAY_SIZE_CHANGED')
	expectNear(entry.sheet.coords[2] * 256, 287.5, 'and for a new resolution')
	bar.w, bar.h = 120, 12
	entry.sizer.scripts.OnSizeChanged(entry.sizer, 120, 12)
	expectNear(entry.sheet.coords[2] * 256, 150, 'a new bar width: counted again by the sizer')
	expectNear(entry.sheet.coords[4] * 64, 15, 'and height')
	-- no size yet (not laid out): nothing shown, then shown when the size arrives
	local unsized = WeaveBar(10, 0.71, 0, 0)
	local waiting = Theme:BarWeave(unsized)
	expect(waiting.sheet and not waiting.sheet.shown and not waiting.base.shown, 'no size yet: BANZAI Smooth is seen')
	unsized.w, unsized.h = 180, 14
	waiting.sizer.scripts.OnSizeChanged(waiting.sizer, 180, 14)
	expect(waiting.sheet.shown and waiting.base.shown, 'laid out: the weave shows')
	-- a size the client keeps from addons: nothing, no error
	local secret = WeaveBar(10)
	secret.GetWidth = function() return HK_SECRET or 'secret' end
	expectEq(Theme:BarWeave(secret).sheet.shown, false, 'a size that is not a plain number: nothing is drawn')
	expectEq(entry.sizer.scripts.OnUpdate, nil, 'no OnUpdate')
	expectEq(#HK_TICKERS, tickers, 'no ticker')
	ChooseBars('SMOOTH')
end)

test('1.5.1 absorb / shield / heal-prediction overlays and texts: they are frames on the bar and the material is two regions of the bar itself, so they stay above it - none is touched, moved, re-levelled, hidden or textured', function()
	ChooseBars('SMOOTH')
	local bar = WeaveBar(10)
	local function Overlay(file, level)
		local o = HK_NewFrame('StatusBar', nil, bar)
		o.level = level
		o:SetStatusBarTexture(file)
		o:SetAllPoints(bar:GetStatusBarTexture())
		return o
	end
	local absorb, incoming, shield = Overlay('absorb', 10), Overlay('incoming-heal', 10), Overlay('shield', 11)
	local texts = HK_NewFrame('Frame', nil, bar)
	texts.level = 13
	local function State() local t = {} for _, o in ipairs({ absorb, incoming, shield, texts }) do t[#t + 1] = table.concat({ tostring(o.statusTexture), tostring(o.level), tostring(o.shown), tostring(o.parent == bar), tostring(o.allPoints), tostring(Regions(o)), tostring(o.alpha) }, ',') end return table.concat(t, ' / ') end
	local before = State()
	local entry = Theme:BarWeave(bar)
	ChooseBars('WEAVE')
	expectEq(State(), before, 'the overlays and the text frame are exactly as they were')
	expectEq(entry.sheet.parent, bar, 'the sheet belongs to the bar, not to a frame above it')
	expectEq(entry.base.parent, bar, 'the empty surface too')
	expectEq(entry.sheet.kind .. entry.base.kind, 'TextureTexture', 'regions, not frames: every frame on the bar is drawn after them')
	expectEq(Regions(entry.sizer), 0, 'the one frame BANZAI adds draws nothing over them')
	expectEq(entry.sizer.level, nil, 'and takes no level of its own')
	for _, o in ipairs({ absorb, incoming, shield }) do expect(not string.find(tostring(o.fill.path), 'BanzaiWeave', 1, true), 'an overlay keeps its own texture') end
	ChooseBars('SMOOTH')
	expectEq(State(), before, 'and after BANZAI Smooth again')
end)

test('1.5.1 owned surfaces: the split bars\' surfaces, the bamboo cast bar, the cooldown bars, the samples and the dressed Player / party / boss bars take the bar texture; raid and arena frames never; the cast bar\'s levels are 1.5.0\'s', function()
	ChooseBars('WEAVE')
	-- BANZAI SPLIT surface (an ElvUI bar BANZAI paints): its dark track is the empty surface
	local elv = WeaveBar(10)
	local surface = ns.Split.Surface(elv)
	expect(surface.weave and surface.weave == Theme:BarWeaveOf(elv), 'Split.Surface: the bar texture')
	expectEq(surface.weave.base, surface.track, 'its track is the empty surface')
	expectNear(surface.track.gradient[3].r, Theme.WEAVE.empty.top[1], 'in the empty surface\'s colour')
	expectEq(surface.weave.sheet.shown, true, 'the sheet over the fill')
	expectEq(surface.overlay.layer, 'ARTWORK', 'the colour BANZAI paints on the fill is under the sheet (OVERLAY)')
	local bare = ns.Split.Surface(WeaveBar(10), true) -- a party bar: no track of its own
	expectEq(bare.weave.ownBase, true, 'a bar without a track gets its own empty surface')
	-- the bamboo cast bar
	local cast = ns.CastBar.Build(UIParent, ns.Split.Geometry('player'), ns.Split.UNITS.player, 20)
	cast.status.w, cast.status.h = 300, 12
	Theme:RefreshBarWeave()
	expect(cast.weave and cast.weave.bar == cast.status, 'the cast bar\'s status bar')
	expectEq(cast.weave.sheet.parent, cast.status, 'a region of the status bar')
	expectEq(cast.weave.sheet.shown, true, 'shown')
	expectEq(cast.over.level, 22, 'the interrupted / locked layers at their 1.5.0 level')
	expectEq(cast.text.level, 24, 'the texts at theirs')
	expectEq(cast.status.level, 21, 'the status bar at its own')
	expectEq(cast.flash.path, SMOOTH_FILE, 'the completion flash stays one smooth surface')
	-- the cooldown bars: their track is the empty surface
	local group = ns.CooldownBars:Group('offensive')
	expect(#group.bars > 0, 'cooldown bars')
	for i, bar in ipairs(group.bars) do
		expect(bar.weave and bar.weave.bar == bar.status, 'cooldown bar ' .. i)
		expectEq(bar.weave.track, bar.track, 'its own track')
	end
	-- the samples
	ns.Preview:Show('player', true)
	Theme:RefreshBarWeave()
	local u = ns.Preview:Get('player').units[1]
	expect(u.Health and u.Health.weave and u.Health.weave.sheet.shown, 'the Player sample\'s health bar')
	ns.Preview:HideAll()
	-- dressed unit frames (BANZAI CLASSIC): Player, party, boss - never raid, never arena
	player.Health.w, player.Health.h, player.Power.w, player.Power.h = 300, 22, 302, 7
	expectEq(BanzaiCompat.WeaveUnitBars(player), true, 'Player')
	Theme:RefreshBarWeave()
	local hp, pp = Theme:BarWeaveOf(player.Health), Theme:BarWeaveOf(player.Power)
	expect(hp and pp, 'Player health and resource')
	expect(hp.sheet.shown and hp.base.shown, 'the Player health bar: slashes and the textured empty part')
	expect(pp.sheet.shown and pp.base.shown, 'the Player resource bar too')
	expectEq(hp.sheet.parent, player.Health, 'on ElvUI\'s own bar')
	expectEq(BanzaiCompat.WeaveUnitBars(party2), true, 'party')
	expectEq(BanzaiCompat.WeaveUnitBars(boss1), true, 'boss')
	expectEq(BanzaiCompat.WeaveUnitBars(arena1), false, 'arena frames: nothing more is made on a PvP frame')
	expectEq(Theme:BarWeaveOf(arena1.Health), nil, 'nothing on the arena bar')
	local raid = HK_NewFrame('Button', 'ElvUF_Raid1Group1UnitButton1', UIParent)
	raid.Health = HK_NewFrame('StatusBar', nil, raid)
	expectEq(BanzaiCompat.WeaveUnitBars(raid), false, 'raid frames stay as they are')
	expectEq(Theme:BarWeaveOf(raid.Health), nil, 'nothing on the raid bar')
	expectEq(BanzaiCompat.WeaveUnitBars(HK_NewFrame('Frame', nil, UIParent)), false, 'a frame without a name: nothing')
	-- BANZAI Smooth: every one of them plain again
	ChooseBars('SMOOTH')
	expectEq(Theme:RefreshBarWeave(), 0, 'BANZAI Smooth: no bar shows the weave')
	expectEq(cast.weave.sheet.shown or surface.weave.sheet.shown or hp.sheet.shown or hp.base.shown, false, 'all hidden')
	expectNear(surface.track.gradient[3].r, 0.045, 'the split track is the plain trough again')
	expectNear(group.bars[1].track.gradient[3].r, 0.045, 'the cooldown track too')
end)

test('1.5.1 the targeted nameplate: the material is laid on the target\'s plate with BANZAI\'s treatment - shown on the current target\'s plate only, hidden when the target changes or the treatment is switched off', function()
	ChooseBars('WEAVE')
	local TP = ns.TargetPlate
	local function Plate()
		local uf = HK_NewFrame('Frame', nil, UIParent)
		uf.frameType = 'ENEMY_PLAYER'
		uf.Health = HK_NewFrame('StatusBar', nil, uf)
		uf.Health.level, uf.Health.w, uf.Health.h = 10, 150, 12
		uf.Health.Text = uf.Health:CreateFontString()
		return { unitFrame = uf }, uf
	end
	local plateA, a = Plate()
	local plateB, b = Plate()
	local wasPlate, wasUnit, wasSetting = HK_PLATES.target, HK_UNITS.target, BanzaiCompat:Get('targetPlate')
	BanzaiCompat:Set('targetPlate', true)
	HK_PLATES.target, HK_UNITS.target = plateA, 'MAGE'
	HK_Fire('PLAYER_TARGET_CHANGED')
	HK_RunTimers()
	local decoA = TP:Get(a)
	expect(decoA and decoA.weave, 'the target plate has the bar texture')
	expectEq(decoA.weave, Theme:BarWeaveOf(a.Health), 'on its health bar')
	expect(decoA.weave.sheet.shown and decoA.weave.base.shown, 'slashes and the textured empty part on the target plate')
	-- another target: the first plate is plain again
	HK_PLATES.target = plateB
	HK_Fire('PLAYER_TARGET_CHANGED')
	HK_RunTimers()
	expectEq(decoA.weave.sheet.shown or decoA.weave.base.shown, false, 'the plate that is no longer the target shows no weave')
	expectEq(TP:Get(b).weave.sheet.shown, true, 'the new target plate does')
	Theme:RefreshBarWeave()
	expectEq(decoA.weave.sheet.shown, false, 'a refresh does not bring it back on the old plate')
	-- the targeted-plate treatment off: no weave on the plate either
	BanzaiCompat:Set('targetPlate', false)
	expectEq(TP:Get(b).weave.sheet.shown, false, 'treatment off: the plate is ElvUI\'s own')
	BanzaiCompat:Set('targetPlate', true)
	expectEq(TP:Get(b).weave.sheet.shown, true, 'on again')
	ChooseBars('SMOOTH')
	expectEq(TP:Get(b).weave.sheet.shown, false, 'BANZAI Smooth: no weave on the plate')
	Theme:ShowBarWeave(nil, true) -- a plate without the entry: nothing happens
	HK_PLATES.target, HK_UNITS.target = wasPlate, wasUnit
	BanzaiCompat:Set('targetPlate', wasSetting)
	HK_Fire('PLAYER_TARGET_CHANGED')
	HK_RunTimers()
end)

test('1.5.1 materials: the bar texture is the same on Banzai Glass, Solid and HARDKORH Parchment - the panel material never changes it, and the bar texture never reaches a panel', function()
	ChooseBars('WEAVE')
	local bar = WeaveBar(10, 0.71)
	local entry = Theme:BarWeave(bar)
	local was = BanzaiCompat:Get('panelBackground')
	local seen = {}
	for _, material in ipairs({ 'GLASS', 'SOLID', 'PARCHMENT' }) do
		BanzaiCompat:Set('panelBackground', material)
		expectEq(Theme:BarTextureKey(), 'WEAVE', material .. ': still BANZAI Weave')
		local g = entry.base.gradient
		seen[#seen + 1] = table.concat({ entry.sheet.path, entry.sheet.wrapH, entry.sheet.filter, table.concat(entry.sheet.coords, ','), tostring(entry.sheet.shown), string.format('%.3f %.3f %.3f', g[3].r, g[3].g, g[3].b), tostring(entry.base.shown) }, '|')
	end
	expectEq(seen[1], seen[2], 'Glass = Solid')
	expectEq(seen[2], seen[3], 'Solid = Parchment')
	-- the panels' own textures: none of them is a BANZAI bar texture
	local C = BanzaiCompat
	for _, frame in ipairs({ C.detailsFrame, C.chatFrame, C.minimapFrame }) do
		for _, t in ipairs(frame and frame.textures or {}) do
			expect(not (type(t.path) == 'string' and string.find(t.path, 'BanzaiWeave', 1, true)), 'no weave on a panel')
		end
	end
	BanzaiCompat:Set('panelBackground', was)
	ChooseBars('SMOOTH')
end)

test('1.5.1 Banzai Art switched off (another profile): the weave goes with it, and comes back with it', function()
	ChooseBars('WEAVE')
	local entry = Theme:BarWeave(WeaveBar(10))
	expect(entry.sheet.shown and entry.base.shown, 'on the Banzai profile')
	local was = HK_ElvData.current
	HK_ElvData.current = 'Some other profile'
	BanzaiCompat:Refresh()
	expectEq(entry.sheet.shown or entry.base.shown, false, 'another profile: hidden')
	HK_ElvData.current = was
	BanzaiCompat:Refresh()
	expect(entry.sheet.shown and entry.base.shown, 'the Banzai profile again: shown')
	ChooseBars('SMOOTH')
end)

test('1.5.1 a bar the client does not let BANZAI build on (a restricted frame): no error, nothing on it, asked once and never again; a bar that has no fill texture yet is asked again at the next refresh', function()
	ChooseBars('WEAVE')
	local bar = WeaveBar(10)
	local calls = 0
	bar.GetStatusBarTexture = function() calls = calls + 1 error('blocked by a secret aspect') end
	local entry = Theme:BarWeave(bar)
	expect(entry and not entry.sheet, 'nothing made, and no error reached the caller')
	expectEq(entry.refused, true, 'the refusal is noted')
	expectEq(#HK_Children(bar) + Regions(bar), 0, 'nothing was left on the bar')
	Theme:RefreshBarWeave()
	BanzaiCompat:Refresh()
	expectEq(calls, 1, 'asked once, never again')
	local late = WeaveBar(10)
	local fill = late:GetStatusBarTexture()
	late.GetStatusBarTexture = function() return nil end
	local waiting = Theme:BarWeave(late)
	expect(not waiting.sheet and not waiting.refused, 'no fill texture yet: nothing, and not counted as a refusal')
	late.GetStatusBarTexture = function() return fill end
	Theme:RefreshBarWeave()
	expect(waiting.sheet and waiting.sheet.shown, 'made at the next refresh')
	ChooseBars('SMOOTH')
end)

-- (last: a refused file is remembered for the session, as the client would refuse it again)
test('1.5.1 missing asset: a client that refuses the weave\'s file draws BANZAI Smooth - no sheet, no empty surface, the plain trough, no error - and the character\'s choice is kept', function()
	ChooseBars('WEAVE')
	local bar = WeaveBar(10)
	local entry = Theme:BarWeave(bar)
	local holder = HK_NewFrame('Frame', nil, UIParent)
	local track = holder:CreateTexture(nil, 'BACKGROUND')
	Theme:Trough(track)
	local tracked = Theme:BarWeave(WeaveBar(10), track)
	expect(entry.sheet.shown and tracked.sheet.shown, 'the weave while its file loads')
	-- the probe, for a file the client does not have
	HK_REFUSED_TEXTURES = { [Theme.MEDIA .. 'BanzaiNoSuchBar'] = true }
	expectEq(Theme:BarMediaOK('BanzaiNoSuchBar'), false, 'a refused file is reported')
	expectEq(Theme:BarMediaOK('BanzaiBar'), true, 'a present one is fine')
	-- the weave's own file refused from now on
	HK_REFUSED_TEXTURES = { [STRANDS] = true }
	local shown = Theme:RefreshBarWeave()
	expectEq(shown, 0, 'no bar shows a sheet whose file is refused')
	expectEq(entry.sheet.shown or entry.base.shown, false, 'sheet and empty surface hidden')
	expectNear(track.gradient[3].r, 0.045, 'a bar\'s own track is the plain trough again')
	expectEq(Theme:BarTextureKey(), 'SMOOTH', 'BANZAI Smooth is drawn')
	expectEq(Theme:BarTexture().label, 'BANZAI Smooth', 'by name')
	expectEq(Theme:DB().barTexture, 'WEAVE', 'the choice itself is kept (the files may come back with a repair)')
	local fresh = Theme:BarWeave(WeaveBar(10))
	expectEq(fresh.sheet, nil, 'a new bar gets nothing at all')
	expectEq(bar.statusTexture, SMOOTH_FILE, 'the bar is BANZAI Smooth')
	HK_REFUSED_TEXTURES = nil
	ChooseBars('SMOOTH')
end)
