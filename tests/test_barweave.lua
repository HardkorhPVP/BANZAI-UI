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

test('1.5.1 owned surfaces: the split bars\' surfaces, the bamboo cast bar, the cooldown bars, the samples and the dressed Player / party / boss bars take the bar texture (1.5.2: raid and arena enemy frames too); the cast bar\'s levels are 1.5.0\'s', function()
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
	-- dressed unit frames (BANZAI CLASSIC): Player, party, boss; 1.5.2: raid and the arena enemy frames too
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
	expectEq(BanzaiCompat.WeaveUnitBars(arena1), true, '1.5.2: the arena enemy frames')
	expect(Theme:BarWeaveOf(arena1.Health), 'the arena health bar is given the bar texture')
	local raid = HK_NewFrame('Button', 'ElvUF_Raid1Group1UnitButton1', UIParent)
	raid.Health = HK_NewFrame('StatusBar', nil, raid)
	expectEq(BanzaiCompat.WeaveUnitBars(raid), true, '1.5.2: the raid frames')
	expect(Theme:BarWeaveOf(raid.Health), 'the raid health bar is given the bar texture')
	expectEq(#BanzaiCompat.WEAVE_SKIP, 0, 'no dressed unit frame is left out')
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

---------------------------------------------------------------------------
-- 1.5.2 Party / Raid / Boss / Arena enemy frames
---------------------------------------------------------------------------
-- an ElvUI group unit frame as the header / ElvUI makes it: the secure button, its health and power bars and one of
-- ElvUI's own prediction bars as a child frame of the health bar (heal prediction / absorbs are frames on the bar)
local function GroupFrame(name, unit, w, h)
	local f = HK_NewFrame('Button', name, UIParent)
	f.unit = unit
	f.attributes = { unit = unit }
	f.w, f.h = w, h
	f.Health = HK_NewFrame('StatusBar', nil, f)
	f.Health.level, f.Health.w, f.Health.h = 10, w, h
	f.Health:SetStatusBarTexture(SMOOTH_FILE)
	f.Health.absorb = HK_NewFrame('StatusBar', nil, f.Health)
	f.Health.absorb.level, f.Health.absorb.shown = 12, true
	f.Power = HK_NewFrame('StatusBar', nil, f)
	f.Power.level, f.Power.w, f.Power.h = 8, w, 4
	f.Power:SetStatusBarTexture(SMOOTH_FILE)
	return f
end
local function Snapshot(f)
	return table.concat({ tostring(f.w), tostring(f.h), tostring(#f.points), tostring(f.allPoints), tostring(f.parent == UIParent), tostring(f.attributes.unit), tostring(f.strata), tostring(f.level),
		tostring(next(f.scripts or {}) == nil), tostring(f.shown) }, '|')
end
local KINDS -- { label, frame } of one frame of each kind, built by the first 1.5.2 test

test('1.5.2 Party, Raid, Boss and Arena enemy frames take BANZAI Weave through the ordinary build: the filled part keeps the bar\'s own colour under the slashes, the empty part is the dark neutral textured surface, the same sheet runs across both, and the secure frame itself is left exactly as it was', function()
	ChooseBars('WEAVE')
	KINDS = {
		{ 'Party', GroupFrame('ElvUF_PartyGroup1UnitButton4', 'party3', 100, 27) },
		{ 'Raid', GroupFrame('ElvUF_Raid1Group2UnitButton3', 'raid8', 150, 20) },
		{ 'Raid (40)', GroupFrame('ElvUF_Raid3Group8UnitButton5', 'raid40', 80, 20) },
		{ 'Boss', GroupFrame('ElvUF_Boss2', 'boss2', 200, 35) },
		{ 'Arena', GroupFrame('ElvUF_Arena2', 'arena2', 100, 27) },
	}
	local before, regions = {}, {}
	for i, kind in ipairs(KINDS) do before[i], regions[i] = Snapshot(kind[2]), Regions(kind[2].Health) end
	HK_IN_COMBAT = false
	HK_Fire('GROUP_ROSTER_UPDATE')
	HK_RunTimers()
	expectEq(ns.Compat.lastError, nil, 'no error while building')
	local px = Theme.PixelScale(KINDS[1][2].Health)
	for i, kind in ipairs(KINDS) do
		local label, f = kind[1], kind[2]
		local entry = Theme:BarWeaveOf(f.Health)
		expect(entry and entry.sheet and entry.base, label .. ': the health bar has the material')
		expectEq(Theme:BarWeaveState(f.Health), 'WEAVE', label .. ': BANZAI Weave')
		-- the active part: the bar's own fill (ElvUI colours it: class / reaction), the slash sheet over it
		expectEq(entry.sheet.shown, true, label .. ': the slashes show')
		expectEq(entry.sheet.path, STRANDS, label .. ': the approved strand sheet')
		expectEq(entry.sheet.layer .. '|' .. tostring(entry.sheet.sublevel), 'OVERLAY|-8', label .. ': over the fill')
		expectEq(entry.sheet.allPoints, f.Health, label .. ': across the WHOLE bar - the same slashes on the filled and the empty part')
		expectEq(entry.sheet.wrapH .. '|' .. entry.sheet.wrapV, 'REPEAT|REPEAT', label .. ': repeated, never stretched')
		expectNear(entry.sheet.coords[2] * 256, f.Health.w * px, label .. ': one texel per screen pixel across (the Player bar\'s rule)')
		expectNear(entry.sheet.coords[4] * 64, f.Health.h * px, label .. ': and down')
		expectEq(f.Health.statusTexture, SMOOTH_FILE, label .. ': the fill itself is ElvUI\'s, untouched (its colour is the bar\'s own)')
		-- the depleted part: dark, neutral, not flat black, under the fill
		expectEq(entry.base.shown, true, label .. ': the empty surface shows')
		expectEq(entry.base.layer .. '|' .. tostring(entry.base.sublevel), 'BORDER|7', label .. ': under the fill')
		local g = entry.base.gradient
		expect(g, label .. ': the empty surface is a gradient, not a flat fill')
		expectNear(g[3].r, Theme.WEAVE.empty.top[1], label .. ': the approved dark neutral (top)')
		expectNear(g[2].r, Theme.WEAVE.empty.bottom[1], label .. ': the approved dark neutral (bottom)')
		expect(g[3].r > 0.05 and g[3].r < 0.3, label .. ': dark, but not black')
		expect(math.abs(g[3].r - g[3].g) < 0.05 and math.abs(g[3].g - g[3].b) < 0.05, label .. ': neutral - never a class colour')
		-- the resource bar too, when the frame has one
		expectEq(Theme:BarWeaveState(f.Power), 'WEAVE', label .. ': the resource bar')
		-- overlays: ElvUI's prediction / absorb bar is a frame on the bar - above both regions, not touched
		expectEq(entry.sheet.parent, f.Health, label .. ': a region of the bar itself (every frame on the bar draws above it)')
		expectEq(entry.base.parent, f.Health, label .. ': so is the empty surface')
		local absorb = f.Health.absorb
		expectEq(tostring(absorb.shown) .. '|' .. tostring(absorb.level) .. '|' .. #absorb.points .. '|' .. tostring(absorb.parent == f.Health), 'true|12|0|true', label .. ': the absorb / prediction bar is as ElvUI made it')
		expectEq(#(absorb.textures or {}), 0, label .. ': nothing is drawn on it')
		expectEq(Regions(f.Health), regions[i] + 2, label .. ': BANZAI\'s two regions on the health bar, nothing else')
		-- the secure frame itself: no size, anchor, parent, unit attribute, strata, level, script or shown state changed
		expectEq(Snapshot(f), before[i], label .. ': the unit frame is exactly as it was')
	end
end)

test('1.5.2 the global BAR TEXTURE stays the one switch: BANZAI Smooth puts Party, Raid, Boss and Arena bars back exactly as ElvUI draws them, BANZAI Weave brings the material back, and a reload-like refresh keeps the choice', function()
	ChooseBars('SMOOTH')
	for _, kind in ipairs(KINDS) do
		local entry = Theme:BarWeaveOf(kind[2].Health)
		expectEq(entry.sheet.shown or entry.base.shown, false, kind[1] .. ': BANZAI Smooth - no sheet, no empty surface')
		expectEq(Theme:BarWeaveState(kind[2].Health), 'SMOOTH', kind[1] .. ': reported as Smooth')
		expectEq(Theme:BarWeaveState(kind[2].Power), 'SMOOTH', kind[1] .. ': the resource bar too')
	end
	expectEq(Theme:RefreshBarWeave(), 0, 'no bar shows the weave')
	expectEq(Theme:DB().barTexture, 'SMOOTH', 'the choice is in the saved settings')
	ChooseBars('WEAVE')
	BanzaiCompat:Refresh() -- what a reload ends with
	for _, kind in ipairs(KINDS) do
		expectEq(Theme:BarWeaveState(kind[2].Health), 'WEAVE', kind[1] .. ': BANZAI Weave again')
	end
	expectEq(Theme:DB().barTexture, 'WEAVE', 'kept')
	expectEq(Theme.BAR_TEXTURE_DEFAULT, 'WEAVE', 'BANZAI Weave is still the BANZAI default')
	-- no per-frame-kind texture setting was added
	for key in pairs(Theme.DEFAULTS) do
		expect(not (string.find(key, 'Texture', 1, true) and key ~= 'barTexture'), 'one bar texture setting only (found ' .. key .. ')')
	end
end)

test('1.5.2 combat: nothing is built on a group or arena frame in combat - the frame waits and gets the material when combat ends; a build asked for in combat is deferred as a whole', function()
	ChooseBars('WEAVE')
	local f = GroupFrame('ElvUF_Arena3', 'arena3', 100, 27)
	local raid = GroupFrame('ElvUF_Raid1Group3UnitButton1', 'raid11', 150, 20)
	local onBar, onFrame, onRaid = Regions(f.Health) + #HK_Children(f.Health), #HK_Children(f), #HK_Children(raid)
	-- two frames no build will find again (dressed earlier, as a frame that waited for combat to end is): only the waiting list can hand them over
	local waitedA, waitedB = GroupFrame('ElvUF_Raid2Group1UnitButton1', 'raid21', 150, 20), GroupFrame('ElvUF_Raid2Group1UnitButton2', 'raid22', 150, 20)
	_G.ElvUF_Raid2Group1UnitButton1, _G.ElvUF_Raid2Group1UnitButton2 = nil, nil
	HK_IN_COMBAT = true
	expectEq(BanzaiCompat.WeaveUnitBars(waitedA), false, 'a dressed frame asked in combat waits')
	local function ArenaWaiting()
		for _, r in ipairs(BanzaiCompat:FrameCoverage().rows) do if r.label == 'Arena enemies' then return r.WAITING end end
	end
	local waitingBefore = ArenaWaiting()
	expectEq(BanzaiCompat.WeaveUnitBars(f), false, 'in combat: not handed over')
	expectEq(ArenaWaiting(), waitingBefore + 1, 'the diagnostic counts exactly this frame as waiting (nothing is built on it, so only the waiting list knows)')
	expectEq(Theme:BarWeaveOf(f.Health), nil, 'the bar texture knows nothing of the bar yet')
	expectEq(Regions(f.Health) + #HK_Children(f.Health), onBar, 'nothing was made on the health bar')
	expectEq(#HK_Children(f), onFrame, 'nothing was made on the arena frame')
	-- a roster change in combat: the whole build waits (no frame is dressed)
	HK_Fire('ARENA_OPPONENT_UPDATE')
	HK_Fire('GROUP_ROSTER_UPDATE')
	HK_RunTimers()
	expectEq(Theme:BarWeaveOf(raid.Health), nil, 'a raid frame that appeared in combat: nothing yet')
	expectEq(#HK_Children(raid), onRaid, 'and nothing on the frame')
	local row
	for _, r in ipairs(BanzaiCompat:FrameCoverage().rows) do if r.label == 'Arena enemies' then row = r end end
	expect(row and row.WAITING >= 1, 'the diagnostic says it is waiting')
	expectEq(BanzaiCompat.WeavePending(), 2, 'asked again in combat: both still wait, still nothing built')
	expectEq(Theme:BarWeaveOf(f.Health), nil, 'nothing')
	-- combat ends
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	HK_RunTimers()
	expectEq(Theme:BarWeaveState(f.Health), 'WEAVE', 'after combat: the arena frame has the material')
	expectEq(Theme:BarWeaveState(raid.Health), 'WEAVE', 'and the raid frame that appeared in combat')
	expectEq(Theme:BarWeaveState(waitedA.Health), 'WEAVE', 'the deferred build hands over the frames that waited')
	expectEq(BanzaiCompat.WeavePending(), 0, 'nothing waits any more')
	expectEq(f.attributes.unit, 'arena3', 'the unit attribute was never written')
	-- a second combat without any roster change (no build is pending): the end of combat alone hands the frame over
	HK_IN_COMBAT = true
	expectEq(BanzaiCompat.WeaveUnitBars(waitedB), false, 'waits')
	expectEq(Theme:BarWeaveOf(waitedB.Health), nil, 'nothing in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(Theme:BarWeaveState(waitedB.Health), 'WEAVE', 'handed over when combat ends')
end)

test('1.5.2 a frame or bar the client has made forbidden is asked nothing: no call reaches it, nothing is built, and it is tried again later - never forced', function()
	ChooseBars('WEAVE')
	local f = GroupFrame('ElvUF_Arena4', 'arena4', 100, 27)
	HK_FORBIDDEN_CALLS = {}
	local health = f.Health
	HK_Forbid(health)
	expectEq(BanzaiCompat.WeaveUnitBars(f), false, 'a forbidden health bar: not handed over')
	expectEq(#HK_FORBIDDEN_CALLS, 0, 'no method of the forbidden bar was called')
	expectEq(Theme:BarWeaveOf(health), nil, 'nothing recorded for it')
	expectEq(BanzaiCompat.WeavePending() >= 1, true, 'it waits')
	expectEq(#HK_FORBIDDEN_CALLS, 0, 'asking again calls nothing on it either')
	local whole = GroupFrame('ElvUF_Arena5', 'arena5', 100, 27)
	HK_Forbid(whole)
	expectEq(BanzaiCompat.WeaveUnitBars(whole), false, 'a forbidden frame: nothing, not even its name is asked')
	expectEq(#HK_FORBIDDEN_CALLS, 0, 'no call')
	local rows = BanzaiCompat:FrameCoverage().rows
	expectEq(#HK_FORBIDDEN_CALLS, 0, 'the diagnostic asks a forbidden frame nothing')
	expect(#rows >= 9, 'and still reports')
	_G.ElvUF_Arena4, _G.ElvUF_Arena5 = nil, nil -- (the two forbidden samples leave the stage: the other modules' own tests cover forbidden arena frames)
	-- a bar the client refused while building (an error inside the build): asked again after the next loading screen
	local late = GroupFrame('ElvUF_Boss3', 'boss3', 200, 35)
	local real = late.Health.GetStatusBarTexture
	local calls = 0
	late.Health.GetStatusBarTexture = function() calls = calls + 1 error('blocked by a secret aspect') end
	expectEq(BanzaiCompat.WeaveUnitBars(late), true, 'handed over')
	expectEq(Theme:BarWeaveState(late.Health), 'REFUSED', 'the client refused: reported, no error raised')
	Theme:RefreshBarWeave()
	expectEq(calls, 1, 'not asked again on a refresh')
	late.Health.GetStatusBarTexture = real
	HK_Fire('PLAYER_ENTERING_WORLD', false, false) -- a loading screen
	HK_RunTimers()
	expectEq(Theme:BarWeaveState(late.Health), 'WEAVE', 'after the loading screen it is asked once more, and has the material')
end)

test('1.5.2 /banzai frames: the coverage of every kind of unit frame BANZAI dresses, the frames it does not, and no setting or frame changed by asking', function()
	ChooseBars('WEAVE')
	Theme:RefreshBarWeave()
	local c = BanzaiCompat:FrameCoverage()
	expectEq(c.texture, 'BANZAI Weave', 'the texture in use')
	local labels, by = {}, {}
	for _, row in ipairs(c.rows) do labels[#labels + 1] = row.label by[row.label] = row end
	expectEq(table.concat(labels, ','), 'Player,Target,Focus,Target of Target,Pet,Party,Raid,Boss,Arena enemies', 'every kind, in order')
	for _, label in ipairs({ 'Player', 'Party', 'Raid', 'Boss', 'Arena enemies' }) do
		expect(by[label].frames >= 1 and by[label].WEAVE >= 1, label .. ': frames with BANZAI Weave')
		expectEq(by[label].frames, by[label].WEAVE + by[label].SMOOTH + by[label].WAITING + by[label].REFUSED + by[label].NONE, label .. ': every frame counted once')
	end
	expectEq(#BanzaiCompat.CoverageNames(BanzaiCompat.COVERAGE[7]), 3 * 8 * 5, 'raid: every ElvUI raid header, group and button')
	expect(#c.excluded >= 3, 'the frames BANZAI does not dress are named')
	ChooseBars('SMOOTH')
	local s = BanzaiCompat:FrameCoverage()
	expectEq(s.texture, 'BANZAI Smooth', 'BANZAI Smooth is reported')
	for _, row in ipairs(s.rows) do expectEq(row.WEAVE, 0, row.label .. ': no weave under BANZAI Smooth') end
	ChooseBars('WEAVE')
end)

test('1.5.2 arena enemy chassis: a thin lime-to-purple BANZAI outline around each enemy health bar - Banzai\'s own frame on the PvP layer (never a child of the arena frame), built once out of combat, shown only while the frame plainly shows; allies get none', function()
	local PV = ns.PvPFrames
	arena1.shown, arena1.Health.shown = true, true
	arena1.Health.w, arena1.Health.h = 100, 27
	HK_IN_COMBAT = false
	PV:Refresh()
	local ae, pe = PV:Get('ElvUF_Arena1'), PV:Get('ElvUF_PartyGroup1UnitButton2')
	expect(ae and ae.chassis, 'the arena enemy entry has a chassis')
	expectEq(pe and pe.chassis, nil, 'party / arena allies: none')
	local m = ae.chassis
	expectEq(m.parent, ae.root, 'on the entry\'s root (the Banzai PvP layer)')
	for _, d in ipairs(HK_Descendants(arena1)) do expect(d ~= m and d.parent ~= m, 'nothing of the chassis is inside the arena frame') end
	expectEq(#m.edges, 4, 'four edges')
	expectEq(#m.points, 2, 'two corners')
	for _, point in ipairs(m.points) do expectEq(point[2], arena1.Health, 'both on the same health bar (it can never reach across the screen)') end
	expectEq(m.points[1][4] .. '|' .. m.points[1][5] .. '|' .. m.points[2][4] .. '|' .. m.points[2][5], '-1|1|1|-1', 'one unit outside the bar')
	expectEq(m.mouse, false, 'clicks pass through to the secure frame')
	local top, bottom, left, right = m.edges[1], m.edges[2], m.edges[3], m.edges[4]
	expectEq(top.h .. '|' .. bottom.h .. '|' .. left.w .. '|' .. right.w, '1|1|1|1', 'screen-thin lines')
	expect(top.gradient and bottom.gradient, 'the top and bottom edges are gradients')
	expect(green(top.gradient[2]) and purple(top.gradient[3]), 'lime into purple')
	expect(green({ r = left.color[1], g = left.color[2], b = left.color[3] }) and purple({ r = right.color[1], g = right.color[2], b = right.color[3] }), 'the left edge lime, the right edge purple')
	expectEq(m.shown, true, 'shown with the visible enemy frame')
	expect(m.level > (arena1.level or 1) and m.level < ae.target.level, 'above the frame, under the TARGET / FOCUS outlines')
	-- the frame hides: the chassis goes
	arena1.shown = false
	PV:Refresh()
	expectEq(m.shown, false, 'hidden with the frame')
	arena1.shown = true
	PV:Refresh()
	expectEq(m.shown, true, 'back with it')
	-- built once: a refresh makes no second chassis, and nothing is built in combat
	local count = #HK_Children(ae.root)
	PV:Refresh()
	expectEq(#HK_Children(ae.root), count, 'a refresh builds nothing new')
	HK_IN_COMBAT = true
	expectEq(PV:Build(), false, 'in combat nothing is built')
	HK_IN_COMBAT = false
	-- Banzai Art off (another profile): put away
	local was = HK_ElvData.current
	HK_ElvData.current = 'Some other profile'
	BanzaiCompat:Refresh()
	PV:Refresh()
	expectEq(m.shown and ae.root.shown, false, 'another profile: not shown')
	HK_ElvData.current = was
	BanzaiCompat:Refresh()
	PV:Refresh()
	expectEq(m.shown, true, 'the Banzai profile again')
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
