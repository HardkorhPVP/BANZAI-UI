-- BushidoPrivateRestore (Banzai 1.2.1) against mocked ElvUI / Details / tracker state.
HK_LOADED.BushidoPrivateCompat = true -- Banzai Art (stubbed below) is loaded: Character Sync requires it
local ns = HK_NS
local T = ns.Transform
local P = ns.Payloads
local E = ElvUI[1]
local NAME = 'JiberishUI - Bushido Private'
local KEY = 'Darrensdrood - Stormrage'

for key in pairs(P.detailsProfile) do Details.default_profile[key] = true end
local payloadSnapshot = T.DeepCopy(P.elvuiProfile)
local MBB_X, MBB_Y = MinimapButtonButtonOptions.position[4], MinimapButtonButtonOptions.position[5]
local KT_CONTEXTS = { 'world', 'city', 'house', 'dungeon', 'mythicplus', 'raid', 'arena', 'battleground', 'petbattle', 'rare' }

-- the Banzai art addon's settings (BushidoPrivateCompat is tested on its own);
-- kept per character like the real ones (0.6.0, Character Sync)
local COMPAT_DEFAULTS = { tracker = true, healthInside = true, healthPercent = true, totScale = 0.72, barHeight = 32, smoothBars = true, cooldownBars = false, actionStyle = 'SQUARE', buffsPanel = true, buffsRows = 2, buffsX = 30, buffsY = 30, glassOpacity = 0.72, barTextSize = 11, displayFace = 'BANZAI_DEFAULT' }
local compatChars = {}
local function compatDB()
	local key = E.mynameRealm
	compatChars[key] = compatChars[key] or T.DeepCopy(COMPAT_DEFAULTS)
	return compatChars[key]
end
local compat = setmetatable({}, { __index = function(_, k) return compatDB()[k] end, __newindex = function(_, k, v) compatDB()[k] = v end })
local themed
local CompatStub = {
	Get = function(_, key) return compatDB()[key] end,
	Set = function(_, key, value) compatDB()[key] = value return true end,
	GetTheme = function() return themed or 'VIBRANT' end,
	SetTheme = function(_, v) themed = v return true end,
	Export = function() local out = T.DeepCopy(compatDB()) out.roleState = nil return out end,
	Import = function(_, values) local db = compatDB() for k, v in pairs(values) do db[k] = T.DeepCopy(v) end db.roles = T.DeepCopy(values.roles) return true end,
	Roles = function() local db = compatDB() db.roles = db.roles or {} return db.roles end,
	RoleState = function() local db = compatDB() db.roleState = db.roleState or {} return db.roleState end,
	PanelStyle = function() local db = compatDB() return db.panelBorder or 'BANZAI', db.panelBackground or 'GLASS', db.borderScale or 1 end,
}
local displayFacePath = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\fonts\\Shojumaru-Regular.ttf'
local previousFacePath = 'Interface\\AddOns\\JiberishMedia\\font\\GasoekOne.ttf'
local TestFontTheme = {
	DISPLAY_FACE_SET = { AUTO = true, BANZAI_DEFAULT = true, SHOJUMARU = true, RYUJIN_ATTACK = true, GANG_OF_THREE = true, OSAKA_SANS = true, SEKAIWO = true, XANGDA_SHINY = true, NINJA_NARUTO = true, INFORMATION = true, PREVIOUS = true },
	BANZAI_DEFAULT_SCALE = 1.05,
	DB = function() return compatDB() end,
	DisplayFont = function()
		if compatDB().displayFace == 'PREVIOUS' then return previousFacePath end
		return (compatDB().displayFace == 'BANZAI_DEFAULT' or compatDB().displayFace == 'SHOJUMARU') and displayFacePath or 'Interface\\AddOns\\JiberishMedia\\font\\Rubik-Bold.ttf'
	end,
	DisplayFontInfo = function()
		local selected = compatDB().displayFace
		local isShojumaru = selected == 'BANZAI_DEFAULT' or selected == 'SHOJUMARU'
		return {
			name = isShojumaru and 'Shojumaru' or 'Information Font',
			license = isShojumaru and 'SIL Open Font License 1.1' or 'Information Font provider',
			metadata = isShojumaru and { file = 'Shojumaru-Regular.ttf' } or { information = true },
		}
	end,
}
BanzaiCompat = CompatStub

local function record() return BushidoPrivateRestoreDB.characters[KEY] end
local function profile() return ElvDB.profiles[NAME] end
local function texts(unit) return profile().unitframe.units[unit].customTexts end
local function kt() return KalielsTrackerDB.profiles.breezy end
local function ktHidden()
	for _, ctx in ipairs(KT_CONTEXTS) do if kt()['visibility' .. ctx] ~= 'hide' then return false end end
	return true
end
local function ktDefault()
	for _, ctx in ipairs(KT_CONTEXTS) do if kt()['visibility' .. ctx] ~= nil then return false end end
	return true
end
local function round(n) return math.floor(n + 0.5) end
-- 1.0.0: an option anywhere under a BANZAI page (sections and tabs are nested groups)
local function Find(group, key)
	if type(group) ~= 'table' or type(group.args) ~= 'table' then return nil end
	if group.args[key] then return group.args[key] end
	for _, child in pairs(group.args) do
		local hit = Find(child, key)
		if hit then return hit end
	end
end
local function Opts(name) return E.Options.args.banzai.args[name] end
-- 1.0.1: the CHARACTER SYNC cards live in its STATUS / WHAT SYNCS / DIAGNOSTICS tabs
local function SyncCards()
	local s = E.Options.args.banzai.args.sync.args
	return setmetatable({}, { __index = function(_, k) return s[k] or s.status.args[k] or s.what.args[k] or s.diagnostics.args[k] end })
end

test('payloads are the decoded historical Bushido data', function()
	expectEq(P.source, '624839aa2d632d97868249d77360d603c7cac3f7', 'source commit')
	expectEq(P.uiScale, 0.71, 'historical UI scale')
	expectEq(P.elvuiProfile.unitframe.units.player.width, 302, 'player width')
	expectEq(P.elvuiProfile.movers.MinimapMover, 'TOPLEFT,UIParent,TOPLEFT,21,-36', 'historical minimap position')
	expect(type(P.elvuiGlobal.unitframe.AuraBarColors[2825]) == 'table', 'number keys kept as numbers')
	expect(type(P.detailsProfile.instances[1]) == 'table', 'Details window 1')
end)

test('mover mirroring is exact', function()
	expectEq(T.MirrorMover('TOPLEFT,UIParent,TOPLEFT,21,-36'), 'TOPRIGHT,UIParent,TOPRIGHT,-21,-36', 'minimap')
	expectEq(T.MirrorMover('BOTTOMLEFT,UIParent,BOTTOMLEFT,0,10'), 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,0,10', 'zero stays 0')
	expectEq(T.MirrorMover('garbage'), 'garbage', 'unknown format unchanged')
end)

test('first login applies nothing by itself (public release: AUTO_APPLY is empty); APPLY BANZAI applies once', function()
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	expectEq(E.data:GetCurrentProfile() ~= NAME, true, 'ElvUI profile untouched at login')
	expectEq(record(), nil, 'nothing recorded at login')
	ns.Restore:Apply('first login')
	HK_RunTimers()
	expectEq(E.data:GetCurrentProfile(), NAME, 'ElvUI profile switched')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload prompt')
	expectEq(record().layer, T.LAYER, "Banzai layer " .. T.LAYER .. " recorded")
	expectEq(record().applied.version, '1.5.0', 'version recorded')
end)

test('existing ElvUI profiles are untouched; previous state recorded', function()
	expectEq(ElvDB.profiles.HARDKORHUI.marker, 'darren-hardkorhui', 'HARDKORHUI profile untouched')
	expectEq(ElvDB.profiles.breezy.marker, 'darren-breezy', 'breezy untouched')
	local previous = record().previous
	expectEq(previous.elvProfile, 'HARDKORHUI', 'previous ElvUI profile')
	expectEq(previous.privateProfile, 'breezy', 'previous private profile')
	expectEq(previous.details, 'DarrenUI', 'previous Details profile')
	expectEq(previous.detailsException, false, 'previous Details exception (none)')
	expectEq(previous.tracker.yOffset, -230, 'previous tracker offset')
	expectEq(previous.minimapButton.x, MBB_X, 'previous minimap button x')
	expectEq(previous.minimapButton.y, MBB_Y, 'previous minimap button y')
	expectEq(previous.trackerVisibility.profile, 'breezy', 'previous Kaliel visibility recorded')
	expectEq(previous.trackerVisibility.values.world, false, 'Kaliel default (show) recorded')
end)

test('ElvUI profile keeps the historical Bushido geometry', function()
	local p = profile()
	-- 1.0.0: half Bushido's width, the inner ends where they were (Player 411 + 302 = 713, Target mirrored)
	expectEq(p.unitframe.units.player.width, 151, 'player width: half of Bushido\'s 302')
	expectEq(p.unitframe.units.player.height, P.elvuiProfile.unitframe.units.player.height, 'height kept')
	expectEq(p.movers.ElvUF_PlayerMover, T.ShiftMover(P.elvuiProfile.movers.ElvUF_PlayerMover, 151, 0), 'player: its inner (right) end kept')
	expectEq(p.movers.ElvUF_TargetMover, T.ShiftMover(P.elvuiProfile.movers.ElvUF_TargetMover, -151, 0), 'target: its inner (left) end kept')
	expectEq(p.movers.ClassBarMover, T.ShiftMover(P.elvuiProfile.movers.ClassBarMover, 151, 0), 'class bar with it')
	expectEq(P.elvuiProfile.ElvUI_EltreumUI.unitframes.ufcustomtexture.targettexture, 'OverwatchJiberish4', 'Bushido target texture (slotted)')
	expectEq(p.unitframe.colors.healthclass, true, 'class-coloured health')
	expectEq(texts('player')['m-Name'].xOffset, 12, 'name position (Bushido)')
	expectEq(texts('player')['m-Name'].yOffset, -32, 'name line (Bushido)')
end)

test('top-right: minimap lower for the zone name, queue eye and durability with it; mana bar; portraits', function()
	local m = profile().movers
	expectEq(m.MinimapMover, 'TOPRIGHT,UIParent,TOPRIGHT,-21,-48', 'minimap')
	expectEq(m.QueueStatusMover, 'TOPRIGHT,UIParent,TOPRIGHT,-60,-201', 'queue eye')
	expectEq(m.DurabilityFrameMover, 'TOPRIGHT,ElvUIParent,TOPRIGHT,-240,-60', 'durability')
	expectEq(m.AdditionalPowerMover, 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,550,348', 'mana bar on the chassis (1.0.0: with the half-width Player)')
	expectNear(profile().mMediaTag.portraits.player.point.x, 0.75, 'portrait re-centred')
end)

test('large circular class anchor: Jiberish Fabled Class through mMediaTag, spec stays text', function()
	local portraits = profile().mMediaTag.portraits
	expectEq(P.elvuiProfile.mMT.portraits.general.classiconstyle, 'fableddimension', 'Bushido used Fabled Dimension')
	expectEq(portraits.misc.class_icon, 'fabledclass', 'Fabled Class (JiberishIcons style key)')
	expectEq(portraits.misc.spec_icon, 'none', 'no spec icon on the anchor')
	for _, unit in ipairs({ 'player', 'target' }) do
		expectEq(portraits[unit].enable, true, unit .. ' portrait on')
		expectEq(portraits[unit].texture, 'circle', unit .. ' circular mask kept')
		expectEq(portraits[unit].ring.mode, 'cast', unit .. ' cast ring kept')
	end
	expectEq(portraits.player.size, P.elvuiProfile.mMT.portraits.player.size, 'size kept')
	-- 0.7.0: the secondary frames show Banzai's small identity circles instead
	for _, unit in ipairs({ 'focus', 'party', 'arena', 'boss' }) do
		expectEq(portraits[unit].enable, false, unit .. ': large mMediaTag portrait off (Banzai identity circle)')
	end
	-- 0.8.0: Target of Target and Pet are subordinate: no portrait
	for _, unit in ipairs({ 'targettarget', 'pet' }) do
		expectEq(portraits[unit].enable, false, unit .. ': no portrait (0.8.0, subordinate)')
	end
	expectEq(texts('player')['b-Spec'].text_format, T.SPEC_TAG, 'spec as text (1.0.0: its own line on the narrow frame)')
	expectEq(HK_FindString(JiberishIconsDB or {}, 'fabled'), nil, 'no Jiberish settings written')
end)

test('identity line: NAME - SPEC on the player, SPEC - NAME on the target', function()
	local player, target = texts('player')['m-Name'], texts('target')['m-Name']
	-- 1.0.0: on the half-width frames the spec has its own line under the name
	expectEq(player.text_format, '[name:eltruism:gradientshortcaps]', 'player name line')
	expectEq(target.text_format, '[name:eltruism:gradientshortcaps{10}]', 'target name line (NPCs: the name alone)')
	local pspec, tspec = texts('player')['b-Spec'], texts('target')['b-Spec']
	expectEq(pspec.text_format, '[banzai:spec]', 'player spec line')
	expectEq(pspec.justifyH .. pspec.xOffset .. ',' .. pspec.yOffset, 'LEFT12,-45', 'under the name, the same left edge')
	expectEq(tspec.justifyH .. tspec.xOffset .. ',' .. tspec.yOffset, 'RIGHT-16,-45', 'target mirrored')
	expectEq(pspec.enable and tspec.enable, true, 'both on')
	-- full width: one line again (NAME - SPEC / SPEC - NAME)
	local copy = T.DeepCopy(profile())
	T.ApplyIdentityLines(copy, false)
	expectEq(copy.unitframe.units.player.customTexts['m-Name'].text_format, '[name:eltruism:gradientshortcaps][banzai:spec:after]', 'full width: the player\'s one line')
	expectEq(copy.unitframe.units.target.customTexts['m-Name'].text_format, '[banzai:spec:before][name:eltruism:gradientshortcaps{10}]', 'full width: the target\'s one line')
	expectEq(copy.unitframe.units.player.customTexts['b-Spec'].enable, false, 'no second line')
	expectEq(player.font, 'Rubik-Bold', 'readable font')
	expectEq(player.size, 11, 'size')
	expectEq(player.justifyH, 'LEFT', 'player left aligned (Bushido)')
	expectEq(target.justifyH, 'RIGHT', 'target mirrored (Bushido)')
end)

test('health: inside the bars on Player / Target / Focus and (0.7.0) Party / Arena / Boss; raid percent only', function()
	for _, unit in ipairs({ 'player', 'target', 'focus', 'party', 'arena' }) do
		expectEq(texts(unit)['m-Health'].enable, false, unit .. ' ElvUI value off (drawn inside the bar)')
		expectEq(texts(unit)['b-HealthPct'].enable, false, unit .. ' ElvUI percent off (drawn inside the bar)')
		expectEq(texts(unit)['m-Health'].text_format, '[mMT-health:current:short]', unit .. ' value kept for when it is outside')
	end
	expectEq(texts('boss')['m-Health'].enable, false, 'boss ElvUI value off (drawn inside the bar)')
	for _, unit in ipairs({ 'party', 'arena' }) do
		expectEq(texts(unit)['m-Health'].xOffset, T.HEALTH[unit].value[2], unit .. ' outside position kept for when inside is off')
	end
	for _, unit in ipairs(T.RAID_UNITS) do
		local pct = texts(unit)['m-Health']
		expectEq(pct.enable, true, unit .. ': compact percent on')
		expect(string.find(pct.text_format, '[perhp<%]', 1, true) and not string.find(pct.text_format, 'health:current', 1, true), unit .. ': percent only, no value')
		expectEq(pct.justifyH, 'RIGHT', unit .. ': at the right end')
		expectEq(texts(unit)['m-Name'].enable, true, unit .. ': short name kept')
	end
	expectEq(texts('targettarget')['b-HealthPct'], nil, 'tiny frames not overloaded')
	expectEq(texts('pet')['b-HealthPct'], nil, 'pet not overloaded')
end)

test('nameplates: compact solid bars, Banzai texture, readable text, distinct cast bar, clear target', function()
	local np = profile().nameplates
	expectEq(np.statusbar, 'Banzai', 'Banzai bar texture')
	for _, unit in ipairs(T.NAMEPLATE_UNITS) do
		local u = np.units[unit]
		expectEq(u.health.height, 12, unit .. ' taller bar')
		expectEq(u.name.fontSize, 11, unit .. ' readable name')
		expectEq(u.name.font, 'Rubik-Bold', unit .. ' small font')
		expectEq(u.castbar.height, 8, unit .. ' cast bar thinner than health')
		expectEq(u.castbar.yOffset, -13, unit .. ' cast bar below the health bar')
	end
	expectEq(np.units.TARGET.glowStyle, 'style7', 'current target obvious: green arrows on both sides')
	for _, unit in ipairs({ 'ENEMY_PLAYER', 'ENEMY_NPC' }) do
		local name = np.units[unit].name
		expectEq(name.parent, 'Health', unit .. ' name on the health bar ...')
		expectEq(name.position, 'TOP', '... directly above it, centred')
		expectEq(name.xOffset, 0, 'centred')
		expect(name.yOffset > 0, 'just above the bar')
	end
	local eltruism = profile().ElvUI_EltreumUI.nameplates
	expectEq(eltruism.nameplateOptions.outofcombatHeight, 11, 'no more 2-pixel lines out of combat')
	expectEq(eltruism.nameplateOptions.incombatHeight, 13, 'in combat')
	expectEq(eltruism.backdrop.backdroptexture, 'Banzai', 'Eltruism backdrop texture')
end)

test('buffs top-left at 70 %, debuffs below them at full size (1.2.0: inside the BUFFS panel, debuffs below the panel)', function()
	local p = profile()
	local B = T.BUFFS_PANEL
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,30,-30', '1.2.0: the buff icons inside the BUFFS panel at the top-left')
	expectEq(p.auras.buffs.size, round(P.elvuiProfile.auras.buffs.size * 0.7), 'buffs 30 % smaller')
	expectEq(p.auras.buffs.height, round(P.elvuiProfile.auras.buffs.height * 0.7), 'height too')
	expectEq(p.auras.debuffs.size, P.elvuiProfile.auras.debuffs.size, 'debuffs stay distinguishable')
	expectEq(p.auras.buffs.growthDirection, 'RIGHT_DOWN', 'grow away from the corner (left to right, then the next row)')
	expectEq(p.auras.buffs.wrapAfter .. ' x ' .. p.auras.buffs.maxWraps, '10 x 2', 'Bushido\'s 10 per row, 2 rows by default')
	expectEq(p.auras.buffs.verticalSpacing, P.elvuiProfile.auras.buffs.verticalSpacing, 'Bushido\'s row gap (the durations sit under the icons)')
	-- 2 rows of 21 + 10 apart = 52, a weapon-enchant row kept free (+31), the bottom band 18, the stalk 10.5, its ends 10, a gap 8
	expectEq(p.movers.DebuffsMover, 'TOPLEFT,UIParent,TOPLEFT,30,-160', 'debuffs below the panel (and its possible enchant row), its bottom stalk and its bamboo ends')
	-- 3 rows: the debuffs move down with the panel
	ns.Restore:SetBuffsPanel('buffsRows', 3)
	expectEq(p.auras.buffs.maxWraps, 3, '3 rows')
	expectEq(p.movers.DebuffsMover, 'TOPLEFT,UIParent,TOPLEFT,30,-191', 'debuffs below 3 rows (+ the enchant row)')
	expectEq(ns.Restore:SetBuffsPanel('buffsRows', 7), 2, 'only 2 or 3 rows')
	-- panel off: the 1.0 places and Bushido's rows exactly
	ns.Restore:SetBuffsPanel('buffsPanel', false)
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,14,-14', 'panel off: buffs top-left as before')
	expectEq(p.movers.DebuffsMover, 'TOPLEFT,UIParent,TOPLEFT,14,-104', 'debuffs below as before')
	expectEq(p.auras.buffs.maxWraps, P.elvuiProfile.auras.buffs.maxWraps, 'Bushido\'s rows')
	local rows = p.auras.buffs.maxWraps * (p.auras.buffs.height + p.auras.buffs.verticalSpacing)
	expect(14 + rows < 104, 'buff rows end above the debuffs')
	ns.Restore:SetBuffsPanel('buffsPanel', true)
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,30,-30', 'panel on again')
end)

test('Target-of-Target smaller, under the Target frame', function()
	local p = profile()
	local old = P.elvuiProfile.unitframe.units.targettarget
	expectEq(p.unitframe.units.targettarget.width, round(old.width * 0.72 * 0.5), '1.0.0: half width')
	expectEq(p.unitframe.units.targettarget.height, round(old.height * 0.72), 'height kept')
	local cut = round(old.width * 0.72) - round(old.width * 0.72 * 0.5)
	expectEq(p.movers.ElvUF_TargetTargetMover, T.ShiftMover(T.TOT.mover, -cut, -T.TOT_DROP), 'under the Target\'s inner end, below its spec line')
	expectEq(texts('targettarget')['m-Health'].size, 11, 'smaller health number')
	expect(p.mMediaTag.portraits.targettarget.size < 58, 'smaller portrait')
end)

test('fonts: heavy font only for big numbers and headings, readable font elsewhere (chat too)', function()
	local p = profile()
	local priv = ElvPrivateDB.profiles[NAME]
	expectEq(HK_FindString(p, 'Lixdu'), nil, 'no Lixdu in the profile')
	expectEq(HK_FindString(priv, 'Lixdu'), nil, 'no Lixdu in the private profile')
	expectEq(p.unitframe.font, 'Rubik-Bold', 'unit-frame default font')
	expectEq(p.nameplates.units.ENEMY_NPC.name.font, 'Rubik-Bold', 'nameplate names')
	expectEq(p.nameplates.units.FRIENDLY_PLAYER.health.text.font, 'Rubik-Bold', 'nameplate health')
	expectEq(texts('player')['m-power'].font, 'Rubik-Bold', 'power value')
	expectEq(p.datatexts.font, 'Rubik-Bold', 'datatexts')
	expectEq(p.chat.font, 'Rubik-Bold', 'chat')
	expectEq(p.chat.tabFont, 'Rubik-Bold', 'chat tabs')
	expectEq(p.general.fonts.worldzone.font, 'GasoekOne', 'zone heading stays heavy')
	expectEq(p.general.fonts.questtext.enable, nil, 'quest / story font replacement stays off')
	expectEq(priv.general.namefont, 'Rubik-Bold', 'world unit names')
	expectEq(priv.general.nameplateFont, 'Rubik-Bold', 'nameplate font')
	expectEq(priv.general.dmgfont, 'GasoekOne', 'combat numbers stay heavy')
	expectEq(texts('targettarget')['m-Health'].font, 'GasoekOne', 'health numbers stay heavy')
	expectEq(p.tooltip.healthBar.font, 'Montserrat-Bold', 'Montserrat alias kept')
end)

test('chat panels: no black box; chat clear of the taller bottom bar', function()
	local p = profile()
	expectEq(p.chat.panelBackdrop, 'HIDEBOTH', 'chat backdrops off')
	expectEq(p.chat.hideChatToggles, true, 'chat toggle buttons off')
	expectEq(p.movers.LeftChatMover, 'BOTTOMLEFT,UIParent,BOTTOMLEFT,31,42', '1.2.0: chat in the middle of its frame, the frame flush with the left screen edge, above the 32-unit bar')
	expectEq(p.chat.panelWidth, 430, 'chat panel = frame width - insets')
	expectEq(p.chat.panelHeight, 140, 'chat panel = frame height - insets')
	expectEq(p.datatexts.panels.Bushido.enable, false, 'Bushido datatext panel off')
end)

test('tags: mMediaTag 3.x tags remapped to current names', function()
	for _, old in ipairs({ '[mHealth', '[mPower', '[mClass', '[mColor', '[mTarget', 'mTargetingPlayers', '>mLevel', '[mLevel' }) do
		expectEq(HK_FindString(profile(), old), nil, 'old tag ' .. old)
	end
end)

test('Details: Bushido profile, readable rows, side by side DAMAGE | HEALING', function()
	expectEq(Details.current, NAME, 'Details profile applied')
	local d = Details.profiles[NAME]
	expectEq(HK_FindString(d, 'Lixdu'), nil, 'no Lixdu')
	expect(HK_FindString(d, 'Rubik-Bold'), 'rows in the readable font')
	expectEq(Details.always_use_profile_exception.Darrensdrood, true, 'kept across logins')
	local left, right = HK_DetailsWindow, HK_DetailsWindow2
	expectEq(right.libwindow.point, 'BOTTOMRIGHT', 'right window in the corner')
	expectEq(right.libwindow.x, -47.15, 'right window x (in the middle of the parallelogram frame)')
	expectEq(right.libwindow.y, 42, 'frame sits on the 32-unit bottom panel')
	expectEq(left.libwindow.x, -47.15 - 207.5 - 15, 'left window beside it (1.3.6: across the 15-unit centre gutter)')
	expectEq(left.libwindow.y, 42, 'same baseline')
	-- 0.6.0: big titles in the display font (damage red, healing green), sleek bars, larger row text centred over them
	local S = T.DETAILS_STYLE
	expectEq(d.instances[1].attribute_text.text_size, 22, 'damage title much larger (0.5.1: 16)')
	expectEq(d.instances[2].attribute_text.text_size, 22, 'healing title much larger')
	expectEq(d.instances[1].attribute_text.text_face, 'GasoekOne', 'Banzai display font')
	local red, grn = d.instances[1].attribute_text.text_color, d.instances[2].attribute_text.text_color
	expect(red[1] > 0.9 and red[2] < 0.4, 'damage title red family')
	expect(grn[2] > 0.9 and grn[1] < 0.4, 'healing title green family')
	for _, window in pairs(d.instances) do
		if type(window) == 'table' and window.row_info then
			expectEq(window.row_info.height, 5, 'bar 60 % thinner than 0.5.1 (12)')
			expectEq(window.row_info.font_size, 13, 'row text 15 % larger than 0.5.1 (11.5)')
			expectEq(window.row_info.text_yoffset, 0, 'text centred over the bar')
			expect(window.row_info.space.between + window.row_info.height >= window.row_info.font_size + 2, 'rows far enough apart for the taller text')
			expectEq(window.row_info.textL_outline_mode, 'OUTLINE', 'names outlined: readable on any class colour')
			expectEq(window.row_info.textR_outline_mode, 'OUTLINE', 'values too')
			expectEq(window.row_info.overlay_texture, 'Banzai', 'no slotted overlay')
			expectEq(window.row_info.texture, 'Banzai', 'smooth meter rows')
			expect(string.find(window.row_info.texture_file, 'BanzaiBar', 1, true), 'smooth meter row file')
			-- 0.7.0: Banzai titles on the frame border, rows lower, no percentage, class colours, texts centred
			expectEq(window.attribute_text.enabled, false, 'Details title text off (Banzai draws DAMAGE / HEALING on the frame border)')
			expectEq(window.row_info.row_offsets.top, S.rowOffset, 'rows start lower')
			expect(S.rowOffset <= -6, 'several units lower than 0.6.0')
			expectEq(window.row_info.texture_class_colors, true, 'class-coloured bars')
			expectEq(window.row_info.texture_background_class_color, false, 'dark track, not a second class colour')
			expectEq(window.row_info.textR_show_data[3], false, 'no percent column')
			expectEq(window.row_info.texts.__version, 1, 'Details row text settings (current format)')
			for i = 1, 4 do expectEq(window.row_info.texts[i].justifyV, 'middle', 'text ' .. i .. ' vertically centred on the bar') end
			expectEq(window.row_info.texts[1].anchor.relativeTo, 'statusbar', 'name from the bar itself')
			expectEq(window.row_info.texts[4].anchor.point, 'right', 'value to the bar end')
		end
	end
	-- the meter values Details formats on this profile: no percentage
	local values = d.righttext_simple_formatting
	expectEq(values.enabled, true, 'Details value formats on')
	expectEq(string.format(values.format_tsp, '245K', '6.1K', '100%'), '245K (6.1K)', 'total (per second), percentage left out')
	expectEq(string.format(values.format_ts, '245K', '6.1K'), '245K (6.1K)', 'total (per second)')
	expectEq(string.format(values.format_tp, '6.1K', '100%'), '6.1K', 'DPS / HPS display: the value alone')
	expectEq(values.use_alignment, false, 'one string per row')
	expectNear(left.posicao.normal.w, 207.5 / 0.75, 'width in window scale (1.3.6: 207.5, was 212)')
	expectNear(left.posicao.normal.h, 124 / 0.75, 'height in window scale (five rows)')
	expectEq(left.display[2], 1, 'left: damage')
	expectEq(right.display[2], 2, 'right: healing')
	expectEq(left.ungrouped and right.ungrouped, true, 'not snapped into a stack')
	expect(left.saved and right.saved, 'positions saved by Details')
	expectEq(Details.mythic_plus_log[1], 'darren-history', 'Details history untouched')
end)

test('top-right column: Kaliel hidden through its own setting, M button in the corner', function()
	expectEq(kt().yOffset, -292, 'Kaliel placed below the minimap (for when the Banzai tracker is off)')
	expect(ktHidden(), 'Kaliel\'s Tracker hidden in every context (Banzai tracker on)')
	expectNear(MinimapButtonButtonOptions.position[4], -2 / 0.8, 'button at the right edge')
	expectNear(MinimapButtonButtonOptions.position[5], -2 / 0.8, 'button at the top edge')
	expectEq(MinimapButtonButtonOptions.position[1], 'TOPRIGHT', 'own setting, same anchor')
end)

test('payload tables are not mutated by applying', function()
	expectEq(HK_FindString(P.elvuiProfile, 'Lixdu') ~= nil, true, 'payload still historical')
	expectEq(payloadSnapshot.unitframe.units.player.width, P.elvuiProfile.unitframe.units.player.width, 'unchanged')
end)

test('BANZAI options 1.0.0: one settings app - logo, UI BY HARDKORH and the version above twelve pages', function()
	HK_Fire('PLAYER_LOGIN')
	expect(HK_PLUGINS.TestAddon, 'registered through LibElvUIPlugin')
	HK_PLUGINS.TestAddon()
	local page = E.Options.args.banzai
	expect(page, 'E.Options.args.banzai')
	expect(string.find(HK_Plain(page.name), 'BANZAI', 1, true), 'left navigation entry BANZAI')
	expectEq(page.order, 6, 'plugin section')
	expectEq(page.childGroups, 'tree', 'the pages listed on the left, the page on the right (Eltruism\'s arrangement)')
	local keys = { 'home', 'appearance', 'unitframes', 'pvp', 'actionbars', 'layout', 'sync', 'components', 'tooltips', 'afk', 'backup', 'about' }
	local names = { 'HOME', 'APPEARANCE', 'UNIT FRAMES', 'PVP', 'ACTION BARS', 'LAYOUT', 'CHARACTER SYNC', 'COMPONENTS', 'TOOLTIPS', 'AFK SCREEN', 'BACKUP & RESTORE', 'ABOUT' }
	local last = 0
	for i, key in ipairs(keys) do
		local g = page.args[key]
		expectEq(g.type, 'group', 'page ' .. key)
		expectEq(HK_Plain(g.name), names[i], key .. ' named ' .. names[i])
		expect(g.order > last, key .. ' in its place in the list')
		expect(not g.inline, key .. ' is a page of the list')
		last = g.order
	end
	local groups = 0
	for _, v in pairs(page.args) do if v.type == 'group' then groups = groups + 1 end end
	expectEq(groups, 12, 'twelve pages, nothing else in the list')
	expect(string.find(page.args.brand.image(), 'BanzaiLogo', 1, true), 'Banzai logo above the list')
	local brand = HK_Plain(page.args.brand.name())
	expect(string.find(brand, 'UI BY HARDKORH', 1, true), 'UI BY HARDKORH')
	expect(string.find(brand, 'BANZAI 1.5.0', 1, true), 'version in the GUI')
	expect(string.find(brand, 'release', 1, true) and not string.find(brand, 'PROOF', 1, true), 'the channel: a release, no proof label')
	expect(string.find(HK_Plain(page.args.home.args.header.name), 'BANZAI 1.5.0', 1, true), 'version on HOME')
	local home = HK_Plain(page.args.home.args.status.name())
	for _, needle in ipairs({ 'BANZAI 1.5.0', 'Darrensdrood - Stormrage', 'Druid', 'Feral', 'SPEC ROLE   DPS', NAME, 'ACTIVE', 'CHARACTER SYNC', 'BANZAI MASTER', 'COMPONENTS' }) do
		expect(string.find(home, needle, 1, true), 'HOME shows ' .. needle)
	end
	expectEq(Find(page.args.home, 'apply').type, 'execute', 'Apply / repair')
	expectEq(Find(page.args.home, 'reload').type, 'execute', 'Reload UI')
	expect(string.find(HK_Plain(Find(page.args.about, 'version').name), 'Release for Retail and WoW Forever; this client: Retail 12.1.5 (build 69848, Interface 120105).', 1, true), 'ABOUT: the release and its client')
	local credits = HK_Plain(Find(page.args.about, 'list').name())
	for _, name in ipairs({ 'JiberishUI Bushido', 'ElvUI', 'Eltruism', 'mMediaTag', 'Jiberish Icons', 'Details', 'Kaliel', 'Syndicator', 'MinimapButtonButton', 'GasoekOne' }) do
		expect(string.find(credits, name, 1, true), 'credits ' .. name)
	end
	-- one scroll per page: no tab group inside a section (AceConfig scrolls each page once)
	local function nested(g)
		for _, v in pairs(g.args or {}) do
			if type(v) == 'table' and v.type == 'group' then
				if v.inline and v.childGroups then return true end
				for _, w in pairs(v.args or {}) do
					if type(w) == 'table' and w.type == 'group' and v.inline and not w.inline then return true end
				end
				if nested(v) then return true end
			end
		end
		return false
	end
	for _, key in ipairs(keys) do expect(not nested(page.args[key]), key .. ': no scroll inside a scroll') end
	-- every page has its own content, the expected sections in place
	for key, wanted in pairs({
		appearance = { 'theme', 'gradient', 'intensity', 'bambooArt', 'panelBorder', 'panelBackground', 'borderScale', 'glassOpacity', 'parchmentBrightness', 'smoothBars', 'logo', 'combatLogo', 'targetPlate', 'displayFont', 'smallFont', 'applyFonts', 'healthInside', 'percent', 'specNames', 'healthSize' },
		unitframes = { 'frameWidth', 'widthReset', 'unitHeight', 'unitSpread', 'unitReset', 'cooldownBars', 'totScale', 'totReset', 'identityCircles', 'previewRole', 'previewState', 'previewAll', 'previewNone', 'previewPlayer', 'previewBoss' },
		actionbars = { 'actionStyle', 'abSize', 'abSpacing', 'ringIntensity', 'abKeybind', 'abCount' },
		layout = { 'chatFrame', 'detailsFrame', 'detailsLayout', 'minimapFrame', 'zoneLabel', 'tracker', 'trackerCollapsed', 'castHistory', 'castEntries', 'castOpacity', 'castScale', 'bar', 'barHeight', 'barCenter', 'barText', 'barOpacity', 'buffsPanel', 'buffsRows', 'buffScale', 'buffsX', 'buffsY', 'buffsReset', 'roleResetDPS', 'roleResetHealer' },
		tooltips = { 'tooltipTheme', 'tooltipOpacity', 'tooltipScale', 'panelTips', 'panelTipsCombat', 'panelTipAnchor', 'trackerTips' },
		afk = { 'afk', 'afkModel', 'afkRotate', 'afkTurn', 'afkOpacity', 'afkBrand', 'afkName', 'afkSpec', 'afkLevel', 'afkZone', 'afkPreview' },
		backup = { 'restore', 'restoreCharacter' },
		components = { 'detected', 'replacement', 'ownership' },
	}) do
		for _, opt in ipairs(wanted) do expect(Find(page.args[key], opt), key .. ' has ' .. opt) end
	end
	local preview = Find(page.args.unitframes, 'previewRole')
	expectEq(preview.values.DPS .. preview.values.HEALER, 'DPSHEALER', 'two layouts')
	local previews = 0
	for k, v in pairs(Find(page.args.unitframes, 'preview').args.preview.args) do
		if string.find(k, '^preview') and v.type == 'toggle' and not v.hidden then previews = previews + 1 end
	end
	expectEq(previews, 10, 'Player, Target, ToT, Focus, Pet, Party, Raid, Arena Allies, Arena Enemies, Boss')
	-- 1.3.0: two more, shown only while the preview draws BANZAI SPLIT
	local splitOnly = Find(page.args.unitframes, 'preview').args.preview.args
	expect(splitOnly.previewTargetNPC and splitOnly.previewTargetNPC.hidden and splitOnly.previewPlate and splitOnly.previewPlate.hidden, 'Target NPC / nameplate samples: BANZAI SPLIT only')
	expectEq(Find(page.args.layout, 'castEntries').max, 6, 'cast history bounded')
	-- one control size (toggles, sliders, selects, buttons; the preview switches excepted)
	local widths = {}
	local function sizes(g)
		for k, v in pairs(g.args or {}) do
			if type(v) == 'table' then
				if (v.type == 'toggle' or v.type == 'range' or v.type == 'select' or v.type == 'execute') and v.style ~= 'radio' and not string.find(k, '^preview') then widths[tostring(v.width)] = true end
				sizes(v)
			end
		end
	end
	sizes(page)
	local n = 0
	for _ in pairs(widths) do n = n + 1 end
	expectEq(n, 1, 'every control the same width')
	-- COMPONENTS: detected list, ADDON REPLACEMENT STATUS, feature ownership
	local components = HK_Plain((page.args.components.args.detected.args.list.name()))
	expect(string.find(components, 'ElvUI   ACTIVE', 1, true), 'ElvUI active')
	expect(string.find(components, 'Kaliel\'s Tracker   DETECTED', 1, true), 'tracker detected (not enabled in the mock)')
	local status = page.args.components.args.replacement
	expectEq(status.type, 'group', 'ADDON REPLACEMENT STATUS page')
	expectEq(HK_Plain(status.name), 'ADDON REPLACEMENT STATUS', 'its name')
	for key, title in pairs({ replaced = 'BANZAI REPLACEMENT COMPLETE', keep = 'BANZAI STILL USES', other = 'NOT REPLACED' }) do
		expectEq(HK_Plain(status.args[key].name), title, title)
	end
	local listed = HK_Plain(status.args.replaced.args.list.name()) .. HK_Plain(status.args.keep.args.list.name()) .. HK_Plain(status.args.other.args.list.name())
	for _, name in ipairs({ 'SexyMap', 'Chattynator', 'MiniMeter', 'Masque', 'Kaliel\'s Tracker', 'MinimapButtonButton', 'Details', 'ElvUI', 'Eltruism', 'mMediaTag', 'mMT Media Pack', 'Jiberish Fabled Icons', 'JiberishMedia', 'sArena Reloaded' }) do
		expect(string.find(listed, name, 1, true), 'inventory lists ' .. name)
	end
	expect(string.find(HK_Plain(status.args.keep.args.list.name()), 'ElvUI (+ ElvUI Libraries, ElvUI Options)   LOADED', 1, true), 'live state shown')
	expect(string.find(HK_Plain(status.args.replaced.args.list.name()), 'SexyMap   NOT INSTALLED', 1, true), 'not installed in the mock')
	local function buttons(t)
		local count = 0
		for _, v in pairs(t) do if type(v) == 'table' then count = count + ((v.type == 'execute') and 1 or 0) + buttons(v) end end
		return count
	end
	expectEq(buttons(status), 0, 'no uninstall (or any other) button on the page')
	local ownership = HK_Plain(page.args.components.args.ownership.args.list.name())
	for _, needle in ipairs({ 'AFK screen', 'Tooltips', 'Syndicator, read only', 'Arena enemy frames' }) do expect(string.find(ownership, needle, 1, true), 'ownership: ' .. needle) end
	-- CHARACTER SYNC: status cards and buttons, no console dump
	local sync = SyncCards()
	expectEq(page.args.sync.childGroups, 'tab', '1.0.1: STATUS / WHAT SYNCS / DIAGNOSTICS')
	expect(string.find(HK_Plain(page.args.sync.args.header.name()), 'BANZAI 1.5.0', 1, true), 'the version on CHARACTER SYNC')
	for _, card in ipairs({ 'this', 'master', 'version', 'synced', 'owned', 'never', 'components', 'characters' }) do
		expectEq(sync[card].type, 'group', 'card ' .. card)
		expectEq(sync[card].inline, true, card .. ' drawn as a card')
	end
	for _, button in ipairs({ 'apply', 'update', 'restore' }) do expectEq(sync.this.args[button].type, 'execute', 'button ' .. button) end
	expectEq(HK_Plain(sync.this.args.apply.name), 'APPLY BANZAI', 'APPLY BANZAI')
	expectEq(HK_Plain(sync.this.args.update.name), 'UPDATE CHARACTER', 'UPDATE CHARACTER')
	expectEq(HK_Plain(sync.this.args.restore.name), 'RESTORE PRE-BANZAI', 'RESTORE PRE-BANZAI')
	expect(string.find(HK_Plain(sync.this.args.identity.name()), 'Darrensdrood - Stormrage', 1, true), 'class / spec identity')
	expect(string.find(sync.this.args.identity.image(), 'CHARACTERCREATE', 1, true), 'class icon')
	expectEq(page.args.sync.args.run, nil, 'the old placeholder button is gone')
	expect(string.find(HK_Plain(sync.version.args.text.name()), 'No master setup captured yet', 1, true), 'version card before any master')
	local plan = HK_Plain(sync.owned.args.list.name())
	for _, needle in ipairs({ 'Target-of-Target width', 'AFK screen', 'tooltips', 'Cast History appearance', 'every choice made in the BANZAI settings', 'own place', 'cast ring', 'Details' }) do
		expect(string.find(plan, needle, 1, true), 'synced: ' .. needle)
	end
	expectEq(Find(page.args.backup, 'restore').disabled(), false, 'restore available')
	expect(string.find(HK_Plain(page.args.backup.args.snapshot.args.status.name()), 'Banzai 1.5.0 applied', 1, true), 'current snapshot')
end)

test('BANZAI options: 0.4.0 settings write the Banzai profile and the art settings', function()
	local a, l = setmetatable({}, { __index = function(_, k) return Find(Opts('appearance'), k) end }), setmetatable({}, { __index = function(_, k) return Find(Opts('layout'), k) or Find(Opts('unitframes'), k) end })
	-- health inside / percent
	expectEq(a.healthInside.get(), true, 'health inside on')
	expectEq(a.healthSize.hidden(), true, 'health size slider hidden while inside')
	a.healthInside.set(nil, false)
	expectEq(compat.healthInside, false, 'art setting')
	expectEq(texts('player')['m-Health'].enable, true, 'ElvUI value back')
	expectEq(texts('target')['b-HealthPct'].enable, true, 'ElvUI percent back')
	a.percent.set(nil, false)
	for _, unit in ipairs({ 'player', 'target', 'focus', 'party', 'arena' }) do expectEq(texts(unit)['b-HealthPct'].enable, false, unit .. ' percent off') end
	a.healthInside.set(nil, true)
	expectEq(texts('player')['m-Health'].enable, false, 'inside again')
	expectEq(a.percent.get(), false, 'percent choice read from the art setting')
	a.percent.set(nil, true)
	expectEq(compat.healthPercent, true, 'percent back on')
	expectEq(texts('player')['b-HealthPct'].enable, false, 'inside units keep their ElvUI percent off')
	expectEq(texts('party')['b-HealthPct'].enable, false, '0.7.0: party health inside its bar too, ElvUI percent stays off')
	-- tracker toggle: Kaliel restored / hidden again through its own setting
	HK_POPUPS = {}
	l.tracker.set(nil, false)
	expectEq(compat.tracker, false, 'Banzai tracker off')
	expect(ktDefault(), 'Kaliel\'s Tracker visible again (its previous setting)')
	expectEq(HK_POPUPS[1], 'BANZAI_RELOAD', 'reload to finish')
	l.tracker.set(nil, true)
	expect(ktHidden(), 'hidden again')
	-- buffs and ToT
	l.buffScale.set(nil, 0.8)
	expectEq(profile().auras.buffs.size, round(P.elvuiProfile.auras.buffs.size * 0.8), 'buff size')
	expectEq(l.buffScale.get(), 0.8, 'reads back')
	l.buffScale.set(nil, 0.7)
	l.totScale.set(nil, 0.6)
	expectEq(compat.totScale, 0.6, 'ToT art scale')
	expectEq(profile().unitframe.units.targettarget.width, round(P.elvuiProfile.unitframe.units.targettarget.width * 0.6 * 0.5), 'ToT frame (1.0.0: half width at that size)')
	l.totReset.func()
	expectEq(compat.totScale, 0.72, 'ToT reset')
	-- theme forwarded, fonts
	a.theme.set(nil, 'CLASS')
	expectEq(themed, 'CLASS', 'theme forwarded to the art addon')
	themed = nil
	a.displayFont.set(nil, 'Expressway')
	a.smallFont.set(nil, 'Rubik-Regular')
	HK_POPUPS = {}
	a.applyFonts.func()
	expectEq(texts('player')['m-Health'].font, 'Expressway', 'display font applied to big numbers')
	expectEq(texts('player')['m-Name'].font, 'Rubik-Regular', 'small font applied to names')
	expectEq(ElvPrivateDB.profiles[NAME].general.namefont, 'Rubik-Regular', 'and world names')
	expectEq(HK_POPUPS[1], 'BANZAI_RELOAD', 'reload to finish')
	ns.Restore:ApplyFonts('GasoekOne', 'Rubik-Bold')
	expectEq(texts('player')['m-Health'].font, 'GasoekOne', 'back to default')
	-- unit layout
	l.unitHeight.set(nil, 10)
	l.unitSpread.set(nil, 5)
	expectEq(profile().movers.ElvUF_PlayerMover, 'BOTTOMLEFT,ElvUIParent,BOTTOMLEFT,567,318', 'player moved up and inward (on top of its 1.0.0 width)')
	expectEq(profile().movers.ElvUF_TargetMover, 'BOTTOMRIGHT,ElvUIParent,BOTTOMRIGHT,-567,318', 'target mirrored')
	expectEq(profile().movers.ElvUF_FocusMover, T.ShiftMover(P.elvuiProfile.movers.ElvUF_FocusMover, 151 + 5, 10), 'focus moves with the Player (left-aligned with it)')
	local tot = P.elvuiProfile.unitframe.units.targettarget
	local cut = round(tot.width * 0.72) - round(tot.width * 0.72 * 0.5)
	expectEq(profile().movers.ElvUF_TargetTargetMover, T.ShiftMover(T.TOT.mover, -(cut + 5), 10 - T.TOT_DROP), 'the Target-of-Target with the Target (still under its inner end)')
	l.unitReset.func()
	expectEq(profile().movers.ElvUF_PlayerMover, T.ShiftMover(P.elvuiProfile.movers.ElvUF_PlayerMover, 151, 0), 'reset: the Banzai place')
end)

test('BANZAI options: 0.5.0 settings (smooth bars, cooldown bars, bottom panel height)', function()
	local a, l = setmetatable({}, { __index = function(_, k) return Find(Opts('appearance'), k) end }), setmetatable({}, { __index = function(_, k) return Find(Opts('layout'), k) or Find(Opts('unitframes'), k) end })
	local p = profile()
	expectEq(p.ElvUI_EltreumUI.unitframes.ufcustomtexture.partytexture, 'Banzai', 'smooth by default')
	HK_POPUPS = {}
	a.smoothBars.set(nil, false)
	expectEq(compat.smoothBars, false, 'art setting')
	expectEq(p.ElvUI_EltreumUI.unitframes.ufcustomtexture.partytexture, 'OverwatchJiberish1', 'Bushido texture back when switched off')
	expectEq(p.nameplates.statusbar, P.elvuiProfile.nameplates.statusbar, 'nameplates too')
	expectEq(HK_POPUPS[1], 'BANZAI_RELOAD', 'reload to finish')
	a.smoothBars.set(nil, true)
	expectEq(p.ElvUI_EltreumUI.unitframes.ufcustomtexture.partytexture, 'Banzai', 'smooth again')
	expectEq(p.unitframe.statusbar, 'Banzai', 'unit-frame texture')
	l.cooldownBars.set(nil, true)
	expectEq(p.actionbar.bar2.enabled, true, 'cooldown bars can be shown again')
	l.cooldownBars.set(nil, false)
	expectEq(p.actionbar.bar4.enabled, false, 'and hidden')
	l.barHeight.set(nil, 36)
	expectEq(compat.barHeight, 36, 'panel height')
	expectEq(p.movers.LeftChatMover, 'BOTTOMLEFT,UIParent,BOTTOMLEFT,31,46', 'chat follows the panel')
	expectEq(p.movers.ElvAB_6, 'BOTTOM,ElvUIParent,BOTTOM,0,46', 'action bars keep their breathing room above the panel')
	expectEq(HK_DetailsWindow2.libwindow.y, 46, 'Details follows the panel')
	l.barHeight.set(nil, 32)
	expectEq(HK_DetailsWindow2.libwindow.y, 42, 'back')
end)

test('1.2.0 BANZAI SQUARE buttons (the default): same size and place, compact keybind top-right, count bottom-centre, cooldown numbers in the middle, Banzai proc glow', function()
	local p = profile()
	local old = P.elvuiProfile.actionbar
	expectEq(compat.actionStyle, 'SQUARE', 'Banzai Square by default')
	for _, bar in ipairs({ 'bar1', 'bar6' }) do
		local db = p.actionbar[bar]
		expectEq(tostring(db.keepSizeRatio) .. ' ' .. db.buttonSize .. 'x' .. db.buttonHeight .. ' / ' .. db.buttonSpacing, 'true 30x30 / 6', bar .. ': the Banzai cluster\'s size and spacing')
		expectEq(db.hotkeyTextPosition .. ' ' .. db.hotkeyTextXOffset .. ' ' .. db.hotkeyTextYOffset, 'TOPRIGHT -3 -3', bar .. ': keybind top-right, inside the border and its chamfer')
		expectEq(db.hotkeyFontSize, math.floor((old[bar].hotkeyFontSize or 10) + 0.5), bar .. ': compact keybind (Bushido\'s size, not the circles\' large one)')
		expectEq(db.hotkeyFont .. ' ' .. db.hotkeyFontOutline, 'Rubik-Bold SHADOWOUTLINE', bar .. ': the small font, outline + shadow')
		expectEq(db.countTextPosition .. ' ' .. db.countTextXOffset .. ' ' .. db.countTextYOffset, 'BOTTOM 0 2', bar .. ': count bottom-centre, clear of the border')
		expectEq(db.countFontSize, math.floor(old[bar].countFontSize * 0.8 + 0.5), bar .. ': the reduced count size')
	end
	expectEq(p.cooldown.actionbar.position .. ' ' .. p.cooldown.actionbar.offsetY .. ' ' .. p.cooldown.actionbar.fontSize, 'CENTER -0.5 11', 'cooldown numbers in the middle, room above and below')
	expectEq(p.actionbar.handleOverlay, false, 'ElvUI\'s proc glow off (Banzai draws a square one)')
	expectEq(p.ElvUI_EltreumUI.glow.procglow, false, 'Eltruism proc glow off')
	expectEq(p.ElvUI_EltreumUI.skins.shadow.actionbars, false, 'Eltruism\'s square black shadows stay off')
	local bottomRow = tonumber((string.match(p.movers.ElvAB_6, ',([^,]+)$')))
	expectEq(tonumber((string.match(p.movers.ElvAB_1, ',([^,]+)$'))), bottomRow + 36, 'the cluster where the circles were')
	expectEq(T.ButtonStyle('BANZAI') .. T.ButtonStyle(true) .. T.ButtonStyle(false) .. T.ButtonStyle(nil), 'SQUARECIRCLEELVUISQUARE', 'style names: 1.1.x BANZAI is the default now')
	local style = Find(Opts('actionbars'), 'actionStyle')
	expectEq(table.concat(style.sorting, ','), 'SQUARE,CIRCLE,ELVUI', 'BUTTON STYLE: Banzai Square, Banzai Circles, ElvUI Square')
	expectEq(style.values.SQUARE .. ' / ' .. style.values.CIRCLE .. ' / ' .. style.values.ELVUI, 'Banzai Square / Banzai Circles / ElvUI Square', 'labels')
	expectEq(Find(Opts('actionbars'), 'abKeybind').disabled(), true, 'the circles\' keybind size is greyed for the square')
	style.set(nil, 'CIRCLE')
	expectEq(compat.actionStyle, 'CIRCLE', 'circles chosen')
end)

test('circular action buttons: square size, centred keybind, bottom-centre smaller count, round proc glow, room above the panel', function()
	local p = profile()
	local old = P.elvuiProfile.actionbar
	expectEq(compat.actionStyle, 'CIRCLE', '1.2.0: Banzai Circles (an option now)')
	for _, bar in ipairs({ 'bar1', 'bar6' }) do
		local db = p.actionbar[bar]
		expectEq(db.keepSizeRatio, true, bar .. ': one size both ways')
		expectEq(db.buttonSize, 30, bar .. ' size')
		expectEq(db.buttonHeight, 30, bar .. ' height = width')
		expectEq(db.buttonSpacing, 6, bar .. ': rims never touch')
		expectEq(db.hotkeyTextPosition, 'CENTER', bar .. ': keybind in the centre')
		expectEq(db.hotkeyTextXOffset, 0, 'x 0')
		expectEq(db.hotkeyTextYOffset, 0, 'y 0')
		expectEq(db.hotkeyFontSize, math.floor((old[bar].hotkeyFontSize or 10) * 1.3 + 0.5), bar .. ': keybind 35 % smaller than 0.5.1 (2x)')
		expect(db.hotkeyFontSize <= 0.65 * 2 * (old[bar].hotkeyFontSize or 10) + 0.5, bar .. ': about 35 % smaller')
		expectEq(db.hotkeyFont, 'Rubik-Bold', 'small readable font')
		expectEq(db.hotkeyFontOutline, 'SHADOWOUTLINE', 'outline + shadow for contrast')
		expectEq(db.countTextPosition, 'BOTTOM', bar .. ': count bottom-centre')
		expectEq(db.countTextXOffset, 0, 'centred')
		expectEq(db.countFontSize, math.floor(old[bar].countFontSize * 0.8 + 0.5), bar .. ': count 20% smaller')
	end
	expectEq(p.actionbar.bar3.keepSizeRatio, false, 'other bars keep their ElvUI shape')
	expectEq(p.actionbar.handleOverlay, false, 'ElvUI square proc glow off (Banzai draws a round one)')
	expectEq(p.ElvUI_EltreumUI.glow.procglow, false, 'Eltruism proc glow off')
	expectEq(p.ElvUI_EltreumUI.skins.shadow.actionbars, false, 'Eltruism action-bar shadows off (the dark squares behind the buttons)')
	expectEq(p.cooldown.actionbar.position, 'TOP', 'cooldown numbers above the centred keybind')
	-- 0.6.0: the lowest row ACTION_GAP above the bottom panel, the rows above with it
	local bottomRow = tonumber((string.match(p.movers.ElvAB_6, ',([^,]+)$')))
	expectEq(bottomRow, compat.barHeight + T.ACTION_GAP, 'clear breathing room between the circles and the panel edge')
	expectEq(tonumber((string.match(p.movers.ElvAB_1, ',([^,]+)$'))), bottomRow + 36, 'top row 30 + 6 above it')
	-- ElvUI square fallback: Bushido's values back
	local style = Find(Opts('actionbars'), 'actionStyle')
	HK_POPUPS = {}
	style.set(nil, 'ELVUI')
	expectEq(compat.actionStyle, 'ELVUI', 'art setting')
	expectEq(p.actionbar.bar1.keepSizeRatio, false, 'ElvUI square: Bushido shape')
	expectEq(p.actionbar.bar1.buttonSize, old.bar1.buttonSize, 'Bushido size')
	expectEq(p.actionbar.bar1.hotkeyTextPosition, old.bar1.hotkeyTextPosition, 'Bushido keybind place')
	expectEq(p.actionbar.handleOverlay, true, 'ElvUI proc glow back')
	expectEq(p.ElvUI_EltreumUI.glow.procglow, true, 'Eltruism proc glow back')
	expectEq(p.ElvUI_EltreumUI.skins.shadow.actionbars, P.elvuiProfile.ElvUI_EltreumUI.skins.shadow.actionbars, 'Eltruism shadows as Bushido had them')
	expectEq(HK_POPUPS[1], 'BANZAI_RELOAD', 'reload to finish')
	local values = style.values
	local n = 0 for _ in pairs(values) do n = n + 1 end
	expectEq(n, 3, '1.2.0: three styles - Banzai Square, Banzai Circles, ElvUI Square (no clipped circle)')
	style.set(nil, 'SQUARE')
	expectEq(p.actionbar.bar1.buttonSize .. ' ' .. p.actionbar.bar1.hotkeyTextPosition, '30 TOPRIGHT', 'Banzai Square again')
	expectEq(p.actionbar.handleOverlay, false, 'ElvUI proc glow off again')
end)

test('restore puts the previous state back', function()
	ns.Restore:Revert()
	expectEq(E.data:GetCurrentProfile(), 'HARDKORHUI', 'ElvUI profile back')
	expectEq(ElvPrivateDB.profileKeys[KEY], 'breezy', 'private profile back')
	expectEq(ElvDB.global.general.UIScale, 0.5333333333333333, 'UI scale back')
	expectEq(Details.current, 'DarrenUI', 'Details profile back')
	expectEq(Details.always_use_profile_exception.Darrensdrood, nil, 'Details exception removed')
	expectEq(kt().yOffset, -230, 'tracker position back')
	expect(ktDefault(), 'Kaliel\'s Tracker visibility back')
	expectEq(MinimapButtonButtonOptions.position[4], MBB_X, 'minimap button x back')
	expectEq(MinimapButtonButtonOptions.position[5], MBB_Y, 'minimap button y back')
	expect(ElvDB.profiles[NAME] ~= nil, 'Banzai profile kept for later')
	expectEq(Find(Opts('backup'), 'restore').disabled(), true, 'nothing left to restore')
end)

test('no automatic re-apply after a restore; manual apply works again', function()
	HK_POPUPS = {}
	expectEq(ns.Restore:OnLogin(), nil, 'nothing happens at login')
	ns.Restore:Apply('manual')
	expectEq(E.data:GetCurrentProfile(), NAME, 'manual apply')
	ns.Restore:Apply('manual')
	expectEq(record().previous.elvProfile, 'HARDKORHUI', 're-apply keeps the original previous profile')
	expectEq(record().previous.trackerVisibility.values.world, false, 're-apply keeps the original Kaliel setting')
	expectEq(record().previous.minimapButton.y, MBB_Y, 're-apply keeps the original button position')
	expectEq(Details.applied[#Details.applied][2], true, 're-apply does not let Details save over the fresh layout')
end)

-- the state an older install left behind (0.1.0: no layer, 0.2.0: 2, 0.3.0: 3, 0.4.0: 4)
-- (the roles are left on DPS by the tests that run before)
local function OldState(layer)
	local r = record()
	r.layer, r.layerSettings = layer, nil
	r.applied.version = ({ [2] = '0.2.0', [3] = '0.3.0', [4] = '0.4.0' })[layer] or '0.1.0'
	r.previous.detailsException, r.previous.tracker, r.previous.trackerVisibility = nil, nil, nil
	r.previous.minimapButton = (layer == 3) and { y = MBB_Y } or (layer == 4) and { x = MBB_X, y = MBB_Y } or nil -- 0.3.0 recorded only y
	local p = profile()
	if not layer then
		p.movers.MinimapMover = P.elvuiProfile.movers.MinimapMover
		p.auras.buffs.growthDirection = 'RIGHT_DOWN'
		p.movers.AdditionalPowerMover = nil
	end
	p.unitframe.units.player.customTexts['m-Name'].text_format = '[name:eltruism:gradientshortcaps]'
	p.unitframe.units.player.customTexts['m-Health'] = { text_format = '[mMT-health:short]', font = 'GasoekOne', justifyH = 'LEFT', xOffset = 24, yOffset = -62, size = 20, enable = true }
	p.unitframe.units.player.customTexts['b-HealthPct'] = nil
	p.unitframe.font = 'GasoekOne'
	p.chat.panelBackdrop = 'RIGHT'
	p.chat.font = 'GasoekOne'
	p.nameplates.statusbar = 'OverwatchJiberish3'
	p.ElvUI_EltreumUI.nameplates.nameplateOptions.outofcombatHeight = 2
	p.mMediaTag.portraits.misc.class_icon = 'fableddimension'
	p.ElvUI_EltreumUI.unitframes.ufcustomtexture.playertexture = 'OverwatchJiberish2'
	p.actionbar.bar2, p.actionbar.bar4 = { enabled = true }, {}
	p.movers.ElvAB_1 = P.elvuiProfile.movers.ElvAB_1
	p.chat.panelWidth = 360
	p.movers.MinimapMover = (layer == 3 or layer == 2) and 'TOPRIGHT,UIParent,TOPRIGHT,-21,-36' or p.movers.MinimapMover
	p.unitframe.units.pet.width = 333 -- a change made in game after the older build (1.0.0: the layer owns the Player width)
	p.darrenTweak = 'kept'
	ElvPrivateDB.profiles[NAME].general.namefont = 'GasoekOne'
	Details.always_use_profile_exception.Darrensdrood = nil
	Details.current = 'DarrenUI'
	HK_DetailsWindow.libwindow = { point = 'BOTTOM', x = 498, y = 0, scale = 0.75 }
	kt().yOffset, kt().maxHeight = (layer == 3) and -292 or -230, 862
	for _, ctx in ipairs(KT_CONTEXTS) do kt()['visibility' .. ctx] = nil end
	MinimapButtonButtonOptions.position[4] = MBB_X
	MinimapButtonButtonOptions.position[5] = (layer == 3) and (-252 / 0.8) or MBB_Y
	if layer == 3 then r.previous.tracker = { profile = 'breezy', yOffset = -230, maxHeight = 862 } end
	HK_POPUPS = {}
	return r, p
end

test('upgrade from 0.3.0 at addon load: used on this login, no reload prompt', function()
	local r, p = OldState(3)
	HK_Fire('ADDON_LOADED', 'TestAddon') -- before ElvUI, Kaliel and the button collector build at PLAYER_LOGIN
	expectEq(p.nameplates.statusbar, 'Banzai', 'nameplates')
	expectEq(p.ElvUI_EltreumUI.nameplates.nameplateOptions.outofcombatHeight, 11, 'no thin nameplates')
	expectEq(p.mMediaTag.portraits.misc.class_icon, 'fabledclass', 'Fabled Class anchor')
	expectEq(p.movers.MinimapMover, 'TOPRIGHT,UIParent,TOPRIGHT,-21,-48', 'minimap')
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,30,-30', 'buffs top-left (1.2.0: in the BUFFS panel)')
	expectEq(texts('player')['m-Health'].enable, false, 'health inside the bar')
	expectEq(p.chat.font, 'Rubik-Bold', 'chat font')
	expect(ktHidden(), 'Kaliel hidden before it builds')
	expectNear(MinimapButtonButtonOptions.position[5], -2 / 0.8, 'button in the corner before it builds')
	expectEq(r.previous.minimapButton.y, MBB_Y, 'original button y kept (0.3.0 record)')
	expectEq(r.previous.minimapButton.x, MBB_X, 'button x recorded now')
	expectEq(p.unitframe.units.pet.width, 333, 'in-game change kept')
	expectEq(p.darrenTweak, 'kept', 'unrelated keys kept')
	expectEq(ElvDB.profiles[NAME], p, 'same profile table (not rewritten)')
	expectEq(r.layer, 3, 'not finished until Details is laid out')
	expectEq(ns.Restore:OnLogin(), true, 'completed after login')
	expectEq(HK_DetailsWindow2.libwindow.x, -47.15, 'Details composition')
	expectEq(r.layer, T.LAYER, 'layer recorded')
	expectEq(r.applied.version, '1.5.0', 'version recorded')
	expectEq(r.previous.elvProfile, 'HARDKORHUI', 'original previous profile kept for rollback')
	expectEq(#HK_POPUPS, 0, 'no reload needed')
	expect(string.find(table.concat(HK_PRINTS, '\n'), 'updated to BANZAI 1.5.0', 1, true), 'update reported in chat')
	expectEq(ns.Restore:OnLogin(), nil, 'runs once')
end)

test('rollback after the 0.3.0 upgrade returns the pre-Banzai state', function()
	ns.Restore:Revert()
	expectEq(E.data:GetCurrentProfile(), 'HARDKORHUI', 'ElvUI profile back')
	expectEq(kt().yOffset, -230, 'tracker back')
	expect(ktDefault(), 'Kaliel visible again')
	expectEq(MinimapButtonButtonOptions.position[4], MBB_X, 'button x back')
	expectEq(MinimapButtonButtonOptions.position[5], MBB_Y, 'button y back (pre-0.3.0 value)')
	ns.Restore:Apply('manual')
end)

test('upgrade from 0.2.0 at addon load', function()
	local r, p = OldState(2)
	ns.Restore:OnAddonLoaded() -- (the event fires once per session; the handler is what runs)
	expectEq(p.unitframe.units.player.customTexts['m-Name'].text_format, T.IDENTITY_SPLIT.player.name, 'identity line (1.0.0: name, the spec under it)')
	expectEq(p.unitframe.units.player.customTexts['b-Spec'].enable, true, 'the spec line')
	expectEq(p.unitframe.font, 'Rubik-Bold', 'small text font')
	expectEq(p.chat.panelBackdrop, 'HIDEBOTH', 'no black chat box')
	expectEq(ns.Restore:OnLogin(), true, 'completed after login')
	expectEq(r.layer, T.LAYER, 'layer recorded')
	expectEq(#HK_POPUPS, 0, 'no reload needed')
end)

test('upgrade from 0.4.0 at addon load: smooth bars, cooldown bars off, action bars up, chat frame', function()
	ns.Restore:Revert()
	ns.Restore:Apply('manual')
	local r, p = OldState(4)
	ns.Restore:OnAddonLoaded()
	expectEq(p.ElvUI_EltreumUI.unitframes.ufcustomtexture.playertexture, 'Banzai', 'smooth health before ElvUI builds the bars')
	expectEq(p.actionbar.bar2.enabled, false, 'target cooldown bar 2 off')
	expectEq(p.actionbar.bar4.enabled, false, 'target cooldown bar 4 off')
	expectEq(p.movers.ElvAB_1, 'BOTTOM,ElvUIParent,BOTTOM,0,78', 'bottom bars up (bar 6 at panel + 10, bar 1 a circle row above)')
	expectEq(p.movers.ElvAB_6, 'BOTTOM,ElvUIParent,BOTTOM,0,42', 'bar 6: 10 above the 32-unit panel')
	expectEq(p.actionbar.bar1.buttonSize, 30, 'circular buttons')
	expectEq(p.chat.panelWidth, 430, 'chat panel inside its frame')
	expectEq(p.unitframe.units.pet.width, 333, 'in-game change kept')
	expectEq(p.darrenTweak, 'kept', 'unrelated keys kept')
	expectEq(ns.Restore:OnLogin(), true, 'completed after login')
	expectEq(r.layer, T.LAYER, 'current layer')
	expectEq(r.applied.version, '1.5.0', 'version')
	expectEq(#HK_POPUPS, 0, 'no reload needed')
	expectEq(r.previous.minimapButton.y, MBB_Y, 'rollback record kept')
end)

test('first 0.5.0 (layer 5) also gets the corrected circular buttons at addon load', function()
	local r, p = OldState(4)
	r.layer, r.applied.version = 5, '0.5.0'
	p.actionbar.bar1 = { keepSizeRatio = false, buttonSize = 35, buttonHeight = 25 }
	ns.Restore:OnAddonLoaded()
	expectEq(p.actionbar.bar1.keepSizeRatio, true, 'square buttons before ElvUI builds the bars')
	expectEq(p.actionbar.bar1.buttonSize, 30, 'circle size')
	expectEq(p.actionbar.bar1.hotkeyTextPosition, 'TOPRIGHT', '1.2.0: Banzai Square (the default): keybind top-right')
	expectEq(ns.Restore:OnLogin(), true, 'completed after login')
	expectEq(r.layer, T.LAYER, 'current layer')
	expectEq(#HK_POPUPS, 0, 'no reload needed')
end)

test('upgrade from 0.1.0 also lands on the full 0.5.0 layer', function()
	local r, p = OldState(nil)
	expectEq(ns.Restore:OnLogin(), true, 'upgrade runs at login')
	expectEq(p.movers.MinimapMover, 'TOPRIGHT,UIParent,TOPRIGHT,-21,-48', 'minimap moved')
	expectEq(p.movers.AdditionalPowerMover, T.ShiftMover(T.ADDITIONAL_POWER.mover, 151, 0), 'mana bar placed (with the half-width Player)')
	expectEq(p.unitframe.units.player.customTexts['m-Name'].text_format, T.IDENTITY_SPLIT.player.name, 'identity line')
	expectEq(kt().yOffset, -292, 'tracker moved')
	expect(ktHidden(), 'Kaliel hidden')
	expectEq(p.ElvUI_EltreumUI.unitframes.ufcustomtexture.playertexture, 'Banzai', 'smooth bars')
	expectEq(r.layer, T.LAYER, 'layer recorded')
	expectEq(HK_POPUPS[1], 'BANZAI_RELOAD', 'reload prompt (settings written after load)')
end)

test('upgrade from 0.5.1: group frames moved by hand stay where they are (as the DPS positions)', function()
	local r, p = OldState(4)
	r.layer, r.applied.version = 7, '0.5.1'
	local state = CompatStub.RoleState()
	state.active, state.written = nil, nil
	local moved = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,150,380'
	p.movers.ElvUF_PartyMover = moved
	ns.Restore:OnAddonLoaded()
	expectEq(p.movers.ElvUF_PartyMover, moved, 'not moved back to Bushido\'s place')
	expectEq(compat.roles.DPS.ElvUF_PartyMover, moved, 'kept as this character\'s DPS position')
	expectEq(compat.roles.DPS.ElvUF_Raid1Mover, nil, 'frames at Bushido\'s places need nothing')
	expectEq(ns.Restore:OnLogin(), true, 'completed after login')
	expectEq(r.layer, T.LAYER, 'current layer')
	compat.roles.DPS = nil
	ns.Roles:Apply('DPS', 'test')
	expectEq(p.movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.DPS.ElvUF_PartyMover, 'clean again for the next tests')
end)

test('without the Banzai tracker Kaliel\'s Tracker is left visible', function()
	ns.Restore:Revert()
	compat.tracker = false
	ns.Restore:Apply('manual')
	expect(ktDefault(), 'Kaliel untouched when the Banzai tracker is off')
	expectEq(record().previous.trackerVisibility, nil, 'nothing recorded')
	compat.tracker = true
	BanzaiCompat = nil
	ns.Restore:Revert()
	ns.Restore:Apply('manual')
	expect(ktDefault(), 'Kaliel untouched without the Banzai art addon')
	BanzaiCompat = CompatStub
end)

test('combat: apply refuses and changes nothing', function()
	HK_IN_COMBAT = true
	local before = E.data:GetCurrentProfile()
	expectEq(ns.Restore:Apply('manual'), false, 'refused')
	expectEq(ns.Restore:Upgrade(), false, 'upgrade waits too')
	expectEq(ns.Restore:LayoutDetails(), 'waiting (combat)', 'Details layout waits')
	expectEq(E.data:GetCurrentProfile(), before, 'unchanged')
	HK_IN_COMBAT = false
end)

test('/banzai opens the BANZAI options on HOME; status shows BANZAI 1.2.1; /bushido kept', function()
	expectEq(SLASH_BANZAI1, '/banzai', 'new command')
	expectEq(SLASH_BANZAI2, '/bushido', 'old command kept')
	HK_OPENED = nil
	SlashCmdList.BANZAI('')
	expectEq(HK_OPENED, 'banzai', 'opens ElvUI options at BANZAI')
	expectEq(HK_ACD:GetStatusTable('ElvUI', { 'banzai' }).groups.selected, 'home', 'on HOME')
	HK_PRINTS = {}
	SlashCmdList.BANZAI('status')
	local text = table.concat(HK_PRINTS, '\n')
	expect(string.find(text, 'BANZAI 1.5.0', 1, true), 'status reports BANZAI 1.5.0')
	expect(string.find(text, 'Player / Target / Focus / Target-of-Target 50% of Bushido\'s width, AFK screen: Banzai, tooltip theme: BANZAI', 1, true), '1.0.0 state reported')
	expect(string.find(text, 'spec role: DPS (Feral), frame layout in use: DPS', 1, true), 'role reported')
	expect(string.find(text, 'character sync: ', 1, true), 'sync state reported')
	expect(string.find(text, 'panel style (chat / Details / minimap / buffs): BANZAI bamboo border, GLASS background, border scale 100%', 1, true), '1.1.1 panel style reported')
	expect(string.find(text, 'health bars: smooth', 1, true), 'smooth bars reported')
	expect(string.find(text, 'target cooldown bars (ElvUI 2 + 4): off', 1, true), 'cooldown bars reported')
	expect(string.find(text, 'Banzai tracker: on', 1, true), 'tracker state reported')
	expect(string.find(text, 'all present', 1, true), 'status-bar textures reported present')
	expectEq(StaticPopupDialogs.BANZAI_RELOAD.text:find('1.5.0', 1, true) ~= nil, true, 'reload dialog names 1.5.0')
end)

---------------------------------------------------------------------------
-- 0.6.0: role layouts, the per-character layer at login, Character Sync
---------------------------------------------------------------------------
local HEALER_PARTY = T.ROLE_LAYOUTS.HEALER.ElvUF_PartyMover
local DPS_PARTY = T.ROLE_LAYOUTS.DPS.ElvUF_PartyMover -- 0.9.0: on the left edge, in line with the raid frames
local OWN_HEALER_PARTY = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,700,420'

test('role layouts: DPS / HEALER from the spec, switched safely, own positions kept per role', function()
	local p = profile()
	HK_SPEC_INDEX = 2
	expectEq(ns.Roles.Current(), 'DPS', 'feral: DPS')
	ns.Roles:Check('test')
	expectEq(p.movers.ElvUF_PartyMover, DPS_PARTY, 'DPS: party on the left side')
	expectEq(p.movers.ArenaHeaderMover, T.ROLE_LAYOUTS.DPS.ArenaHeaderMover, 'arena enemies on the right')
	HK_MOVER_POINTS = {}
	HK_SPEC_INDEX = 4
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(ns.Roles.Current(), 'HEALER', 'restoration: HEALER')
	expectEq(p.movers.ElvUF_PartyMover, HEALER_PARTY, 'party moved to the central healing place')
	expectEq(p.movers.ElvUF_Raid1Mover, T.ROLE_LAYOUTS.HEALER.ElvUF_Raid1Mover, 'raid too')
	expectEq(#HK_MOVER_POINTS, #T.ROLE_MOVERS, 'ElvUI moves the frames to their new mover positions')
	expectEq(ns.Roles:Active(), 'HEALER', 'HEALER in use')
	-- Darren moves the healer party with ElvUI's mover
	p.movers.ElvUF_PartyMover = OWN_HEALER_PARTY
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(p.movers.ElvUF_PartyMover, DPS_PARTY, 'back to DPS: the DPS party is not changed by the healer move')
	expectEq(compat.roles.HEALER.ElvUF_PartyMover, OWN_HEALER_PARTY, 'the healer position kept for HEALER only')
	expectEq(compat.roles.DPS, nil, 'nothing written into the DPS layout')
	HK_SPEC_INDEX = 4
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(p.movers.ElvUF_PartyMover, OWN_HEALER_PARTY, 'HEALER again: its own position')
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'party1')
	expectEq(ns.Roles:Active(), 'HEALER', 'other units\' spec changes ignored')
	-- combat: secure group frames do not move until it ends
	HK_IN_COMBAT = true
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(p.movers.ElvUF_PartyMover, OWN_HEALER_PARTY, 'in combat nothing moves')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(p.movers.ElvUF_PartyMover, DPS_PARTY, 'switched right after combat')
	-- reset the healer positions to Banzai's
	expectEq(ns.Roles:Reset('HEALER'), true, 'reset')
	expectEq(compat.roles.HEALER, nil, 'own healer positions dropped')
	expectEq(ns.Roles:Layout('HEALER').ElvUF_PartyMover, HEALER_PARTY, 'Banzai healer place again')
	expectEq(ns.Roles:Active(), 'DPS', 'still DPS')
end)

-- 0.7.0: the HEALER row in the centre, arena allies with their own place
local SCREEN_W = 2560 / (0.71 * 1440 / 768) -- UIParent width at Darren's 2560 x 1440, UI scale 0.71
local function MoverRect(value, w, h)
	local point, _, relative, x, y = string.match(value, '^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$')
	x, y = tonumber(x), tonumber(y)
	expectEq(point .. relative, 'BOTTOMBOTTOM', 'row anchored at the screen\'s bottom centre')
	local left = SCREEN_W / 2 + x - w / 2
	return left, y, w, h
end

test('role layouts 0.7.0: HEALER party and arena allies in one horizontal central row, DPS column unchanged', function()
	local p = profile()
	local party = p.unitframe.units.party
	local H = T.ROLE_LAYOUTS.HEALER
	-- DPS: Bushido's column on the left, exactly as before
	HK_SPEC_INDEX = 2
	ns.Roles:Check('test')
	expectEq(p.movers.ElvUF_PartyMover, DPS_PARTY, 'DPS party on the left edge')
	expectEq(party.growthDirection, P.elvuiProfile.unitframe.units.party.growthDirection, 'DPS: Bushido\'s column (' .. tostring(party.growthDirection) .. ')')
	expectEq(party.width, T.ROLE_LAYOUTS.DPS.party.width, '0.9.0: DPS width halved')
	expectEq(party.horizontalSpacing, P.elvuiProfile.unitframe.units.party.horizontalSpacing, 'DPS spacing unchanged')
	-- HEALER: one horizontal row
	HK_UF.headerUpdates = {}
	HK_SPEC_INDEX = 4
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(string.match(party.growthDirection, '^(%u+)'), 'RIGHT', 'HEALER party grows sideways: one horizontal row')
	expectEq(party.width, H.party.width, 'compact frames for the row')
	expectEq(HK_UF.headerUpdates[#HK_UF.headerUpdates], 'party', 'ElvUI rebuilds the party header in the new arrangement')
	-- the row in the centre, clear of everything in the lower centre
	local w = 5 * party.width + 4 * party.horizontalSpacing
	local h = P.elvuiProfile.unitframe.units.party.height
	local left, bottom = MoverRect(p.movers.ElvUF_PartyMover, w, h)
	expect(left > 0 and left + w < SCREEN_W, 'on screen')
	expect(math.abs((left + w / 2) - SCREEN_W / 2) < 40, 'centred')
	local movers = P.elvuiProfile.movers
	local playerTop = tonumber(string.match(movers.ElvUF_PlayerMover, ',([%d.-]+)$')) + P.elvuiProfile.unitframe.units.player.height
	expect(bottom > playerTop + 41, 'above Player / Target and their bamboo (' .. bottom .. ')')
	-- 1.0.0: just above the region - the dispel icons under the frames (2 + 14) clear the Focus frame's top (397 + 35) with a gap
	local focusTop = tonumber(string.match(movers.ElvUF_FocusMover, ',([%d.-]+)$')) + P.elvuiProfile.unitframe.units.focus.height
	expect(bottom - 16 - focusTop >= 6, 'its dispel icons clear the Focus frame (' .. (bottom - 16 - focusTop) .. ')')
	expect(bottom - 16 - focusTop <= 10, 'and no more than a clean gap: right above the region')
	expect(bottom > 422 + 16, 'above the combat tree (422), dispel icons included')
	expect(bottom + h < 1081.7 / 2 + 40, 'within easy peripheral reach of the character')
	expect(party.horizontalSpacing >= 27 + 2 * 4, 'room for each frame\'s identity circle between the frames')
	-- arena allies: their own position, the same row philosophy
	HK_INSTANCE = 'arena'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	expectEq(ns.Roles:ActiveContext(), 'arena', 'arena context')
	expectEq(p.movers.ElvUF_PartyMover, H.ArenaAlliesMover, 'arena allies in their own (central) place')
	expectEq(string.match(party.growthDirection, '^(%u+)'), 'RIGHT', 'arena allies horizontal too')
	local OWN_ALLIES = 'BOTTOM,UIParent,BOTTOM,16,480'
	p.movers.ElvUF_PartyMover = OWN_ALLIES -- Darren moves them in the arena
	HK_INSTANCE = 'none'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	expectEq(compat.roles.HEALER.ArenaAlliesMover, OWN_ALLIES, 'kept as the HEALER arena allies position')
	expectEq(compat.roles.HEALER.ElvUF_PartyMover, nil, 'the party position is not changed by it')
	expectEq(p.movers.ElvUF_PartyMover, HEALER_PARTY, 'out of the arena: the party row again')
	HK_INSTANCE = 'arena'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	expectEq(p.movers.ElvUF_PartyMover, OWN_ALLIES, 'next arena: the allies where Darren put them')
	HK_INSTANCE = 'none'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	-- a party arrangement changed in ElvUI's options is kept for that role
	party.width = 150
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(compat.roles.HEALER['party.width'], 150, 'HEALER keeps its own width')
	expectEq(party.width, T.ROLE_LAYOUTS.DPS.party.width, 'DPS width untouched')
	-- DPS arena allies follow the DPS party Darren moved (until they get a place of their own)
	compat.roles.DPS = { ElvUF_PartyMover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,150,380' }
	expectEq(ns.Roles:Layout('DPS').ArenaAlliesMover, 'BOTTOMLEFT,UIParent,BOTTOMLEFT,150,380', 'DPS arena allies where his DPS party is')
	compat.roles.DPS = nil
	-- changes are read back when leaving the world, before ElvUI's logout save drops default values
	HK_SPEC_INDEX = 4
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	party.horizontalSpacing = 40
	HK_Fire('PLAYER_LEAVING_WORLD')
	expectEq(compat.roles.HEALER['party.horizontalSpacing'], 40, 'captured at PLAYER_LEAVING_WORLD')
	compat.roles.HEALER['party.horizontalSpacing'] = nil
	party.horizontalSpacing = H.party.horizontalSpacing
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	-- the preview reads every piece of a layout
	local layout = ns.Roles:Layout('HEALER')
	expectEq(layout.ArenaAlliesMover, OWN_ALLIES, 'preview: arena allies position')
	expectEq(layout['party.growthDirection'], H.party.growthDirection, 'preview: arrangement')
	ns.Roles:Reset('HEALER')
	expectEq(compat.roles.HEALER, nil, 'reset')
end)

test('character layer at login: this character\'s settings written before ElvUI builds, only when needed', function()
	local p = profile()
	local db = BushidoPrivateRestoreDB
	ns.Restore:OnAddonLoaded()
	expectEq(db.layerOwner.key, KEY, 'the profile carries this character\'s settings')
	p.movers.LeftChatMover = 'unchanged-marker'
	ns.Restore:OnAddonLoaded()
	expectEq(p.movers.LeftChatMover, 'unchanged-marker', 'same character, same settings: nothing rewritten')
	compat.barHeight = 36
	ns.Restore:OnAddonLoaded()
	expectEq(p.movers.LeftChatMover, T.ChatMover(36), 'its settings changed: written again')
	expectEq(p.movers.ElvAB_6, 'BOTTOM,ElvUIParent,BOTTOM,0,46', 'action bars follow')
	compat.barHeight = 32
	ns.Restore:OnAddonLoaded()
	expectEq(p.movers.LeftChatMover, T.ChatMover(32), 'back')
end)

-- log in as another character (the mocks hold one character at a time)
local current = { [KEY] = NAME }
local function LogIn(key, name, class, spec)
	current[E.mynameRealm] = E.data:GetCurrentProfile()
	E.mynameRealm, HK_PLAYER_NAME, HK_UNITS.player, HK_SPEC_INDEX = key, name, class, spec
	HK_ElvData.current = current[key] or 'Default'
	HK_ElvData.keys.profile = HK_ElvData.current
end
local ALT = 'Darrenshammy - Stormrage'

test('character sync: BANZAI MASTER captured, alt applied with its backup, visual settings only, gameplay data untouched', function()
	local S = ns.Sync
	local page = SyncCards()
	expectEq(S:State(), 'NO_MASTER', 'Banzai runs here, no master yet')
	expect(not page.master.args.setMaster.hidden(), 'SET AS BANZAI MASTER offered')
	compat.glassOpacity, compat.barTextSize = 0.58, 14 -- Darren's approved look
	page.master.args.setMaster.func()
	expectEq(S:State(), 'MASTER', 'BANZAI MASTER')
	local m = S:Master()
	expectEq(m.key, KEY, 'master character')
	expectEq(m.class, 'Druid', 'class')
	expectEq(m.spec, 'Feral', 'spec')
	expectEq(m.role, 'DPS', 'role')
	expectEq(m.version, '1.5.0', 'Banzai version')
	expectEq(m.schema, ns.Sync.SCHEMA, 'configuration schema')
	expectEq(m.specID, 103, 'spec id')
	expectEq(m.revision, 1, 'configuration #1')
	expect(m.captured, 'captured time')
	expectEq(m.config.settings.glassOpacity, 0.58, 'Banzai settings captured')
	expectEq(type(m.config.fonts), 'table', 'fonts captured')
	expectEq(type(m.config.layout), 'table', 'buff / unit layout captured')
	S:Capture()
	expectEq(m.revision, 1, 'nothing changed: same revision')
	local card = HK_Plain(page.master.args.info.name())
	for _, needle in ipairs({ KEY, 'Druid', 'FERAL', 'DPS', '1.5.0', 'SCHEMA 3', '#1' }) do expect(string.find(card, needle, 1, true), 'master card shows ' .. needle) end
	expect(string.find(HK_Plain(page.version.args.text.name()), 'In step', 1, true), 'version drift: none')
	expectEq(page.master.args.capture.hidden(), false, 'CAPTURE MASTER NOW on the master')

	-- an alt that never ran Banzai
	local shared = profile()
	shared.darrenMasterTweak = 'kept'
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	expectEq(S:State(), 'NOT_SYNCED', 'THIS CHARACTER IS NOT SYNCED')
	expect(string.find(HK_Plain(page.this.args.state.name()), 'THIS CHARACTER IS NOT SYNCED', 1, true), 'shown on the card')
	expectEq(page.this.args.apply.hidden(), false, 'APPLY BANZAI offered')
	expectEq(page.this.args.update.hidden(), true, 'no UPDATE yet')
	local plan = HK_Plain(page.this.args.apply.confirm())
	for _, needle in ipairs({ 'BANZAI WILL APPLY:', '- visual theme', '- role layout (HEALER for Restoration)', '- Chat / Details / Minimap', '- AFK screen', '- PvP visual configuration',
		'BANZAI WILL NOT CHANGE:', '- abilities', '- action assignments', '- keybinds', '- macros', '- talents', '- gear', '- gameplay history' }) do
		expect(string.find(plan, needle, 1, true), 'the confirmation lists: ' .. needle)
	end
	expectEq(compat.glassOpacity, 0.72, 'the alt still has its own settings')
	HK_POPUPS, HK_GAMEPLAY_CALLS = {}, {}
	local history = Details.mythic_plus_log[1]
	page.this.args.apply.func()
	expectEq(S:State(), 'SYNCED', 'BANZAI SYNCED')
	expectEq(E.data:GetCurrentProfile(), NAME, 'on the Banzai ElvUI profile')
	expectEq(profile(), shared, 'the master\'s profile reused, not rebuilt')
	expectEq(shared.darrenMasterTweak, 'kept', 'the approved profile kept as it is')
	local r = BushidoPrivateRestoreDB.characters[ALT]
	expectEq(r.previous.elvProfile, 'Default', 'backup: the alt\'s own ElvUI profile')
	expect(r.syncBackup and r.syncBackup.settings and r.syncBackup.settings.glassOpacity == 0.72, 'backup: its own BANZAI settings')
	expectEq(compat.glassOpacity, 0.58, 'the master\'s visual settings')
	expectEq(compat.barTextSize, 14, 'bottom panel text too')
	expectEq(shared.movers.ElvUF_PartyMover, HEALER_PARTY, 'healer spec: the HEALER layout')
	expectEq(ElvPrivateDB.profileKeys[ALT], NAME, 'Banzai private profile for the alt')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload requested (the ElvUI profile switched)')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no keybind, macro, action-slot, talent or equipment call')
	expectEq(Details.mythic_plus_log[1], history, 'Details combat history untouched')
	expect(string.find(HK_Plain(page.characters.args.list.name()), ALT, 1, true), 'listed with the Banzai characters')

	-- applying again changes nothing
	local before = T.Serialize(r.previous)
	local backupTime = r.syncBackup.time
	HK_POPUPS = {}
	expectEq(S:Apply(), true, 'repeat apply')
	expectEq(T.Serialize(r.previous), before, 'backup not replaced by Banzai\'s own state')
	expectEq(r.syncBackup.time, backupTime, 'snapshot taken once')
	expectEq(#HK_POPUPS, 0, 'nothing changed: no reload')
	expectEq(S:State(), 'SYNCED', 'still synced')
end)

test('character sync: master changes -> UPDATE AVAILABLE on the alt, nothing overwritten until UPDATE CHARACTER', function()
	local S = ns.Sync
	local page = SyncCards()
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	ns.Restore:OnAddonLoaded()
	expectEq(profile().movers.ElvUF_PartyMover, DPS_PARTY, 'the master logs in: its own DPS layout written back')
	expectEq(profile().movers.LeftChatMover, T.ChatMover(32), 'and its own settings')
	compat.barHeight = 36
	page.master.args.capture.func()
	expectEq(S:Master().revision, 2, 'new configuration #2')

	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	expectEq(S:State(), 'UPDATE', 'BANZAI UPDATE AVAILABLE')
	expect(string.find(HK_Plain(page.this.args.state.name()), 'BANZAI UPDATE AVAILABLE', 1, true), 'shown on the card')
	expectEq(page.this.args.update.hidden(), false, 'UPDATE CHARACTER offered')
	expectEq(compat.barHeight, 32, 'nothing overwritten without UPDATE CHARACTER')
	ns.Restore:OnAddonLoaded()
	expectEq(profile().movers.LeftChatMover, T.ChatMover(32), 'its login writes its own settings')
	expectEq(profile().movers.ElvUF_PartyMover, HEALER_PARTY, 'and its own role layout')
	HK_POPUPS = {}
	page.this.args.update.func()
	expectEq(S:State(), 'SYNCED', 'synced again')
	expectEq(compat.barHeight, 36, 'the master\'s new setting')
	expectEq(profile().movers.LeftChatMover, T.ChatMover(36), 'written for ElvUI')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload: ElvUI positions changed')
	HK_POPUPS = {}
	compat.glassOpacity = 0.6
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	compat.glassOpacity = 0.5
	S:Capture()
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	expectEq(S:State(), 'UPDATE', 'a glass change on the master')
	expect(S:Update(), 'update')
	expectEq(compat.glassOpacity, 0.5, 'taken over')
	expectEq(#HK_POPUPS, 0, 'Banzai-only change: no reload needed')
	-- the tracker choice: Kaliel's Tracker follows it on the alt
	local function altKT() return KalielsTrackerDB.profiles.Default.visibilityworld end
	expectEq(altKT(), 'hide', 'alt: Banzai tracker on, Kaliel hidden')
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	compat.tracker = false
	S:Capture()
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	expect(S:Update(), 'update')
	expectEq(compat.tracker, false, 'tracker setting taken over')
	expectEq(altKT(), nil, 'Kaliel\'s Tracker shown again (not left with no tracker at all)')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload: Kaliel reads its visibility at load')
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	compat.tracker = true
	S:Capture()
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	S:Update()
	expectEq(altKT(), 'hide', 'and hidden again with the Banzai tracker')
	-- CAPTURE MASTER NOW includes frames moved this session
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	ns.Restore:OnAddonLoaded()
	local revision = S:Master().revision
	profile().movers.ElvUF_PartyMover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,120,370'
	S:Capture()
	expectEq(S:Master().config.settings.roles.DPS.ElvUF_PartyMover, 'BOTTOMLEFT,UIParent,BOTTOMLEFT,120,370', 'the moved party frame is in the captured setup')
	expectEq(S:Master().revision, revision + 1, 'as a new revision')
	ns.Roles:Reset('DPS')
	S:Capture()
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	S:Update()
	expectEq(S:State(), 'SYNCED', 'alt in step again')
	-- 0.7.0: the role-layout settings travel with the setup (arena allies, party arrangement), and the identity circle choice
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	ns.Restore:OnAddonLoaded()
	compat.roles.HEALER = { ArenaAlliesMover = 'BOTTOM,UIParent,BOTTOM,16,470', ['party.width'] = 150 }
	compat.identityCircles = false
	S:Capture()
	local settings = S:Master().config.settings
	expectEq(settings.roles.HEALER.ArenaAlliesMover, 'BOTTOM,UIParent,BOTTOM,16,470', 'arena allies position in the synced setup')
	expectEq(settings.roles.HEALER['party.width'], 150, 'party arrangement in the synced setup')
	expectEq(settings.identityCircles, false, 'identity circle choice synced')
	expectEq(settings.roleState, nil, 'which layout a character has written is not synced')
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	expectEq(S:State(), 'UPDATE', 'update offered')
	expect(S:Update(), 'update')
	expectEq(compat.roles.HEALER['party.width'], 150, 'the alt takes the master\'s HEALER arrangement')
	expectEq(ns.Roles:Active(), 'HEALER', 'restoration alt: HEALER layout')
	expectEq(profile().unitframe.units.party.width, 150, 'its party row uses it')
	expectEq(string.match(profile().unitframe.units.party.growthDirection, '^(%u+)'), 'RIGHT', 'one horizontal row')
	expectEq(profile().mMediaTag.portraits.party.enable, true, 'circles off on the alt too: mMediaTag portraits back')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no spells, bars, macros, talents or keybinds touched')
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	compat.roles.HEALER, compat.identityCircles = nil, true
	S:Capture()
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	S:Update()
	expectEq(profile().unitframe.units.party.width, T.ROLE_LAYOUTS.HEALER.party.width, 'back to the Banzai HEALER row')
	expectEq(profile().mMediaTag.portraits.party.enable, false, 'circles on again')
end)

test('identity circles option: mMediaTag portraits off on the secondary frames while on, back when off', function()
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	ns.Restore:OnAddonLoaded()
	local a = setmetatable({}, { __index = function(_, k) return Find(Opts('unitframes'), k) end })
	expectEq(a.identityCircles.get(), true, 'on by default')
	HK_POPUPS = {}
	a.identityCircles.set(nil, false)
	local portraits = profile().mMediaTag.portraits
	for _, unit in ipairs(T.IDENTITY_UNITS) do expectEq(portraits[unit].enable, true, unit .. ': mMediaTag portrait back') end
	expectEq(portraits.player.enable, true, 'player anchor untouched')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload: mMediaTag builds its portraits at load')
	a.identityCircles.set(nil, true)
	for _, unit in ipairs(T.IDENTITY_UNITS) do expectEq(portraits[unit].enable, false, unit .. ': Banzai circle instead') end
	expectEq(portraits.target.enable, true, 'target anchor untouched')
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4) -- the next tests continue on the alt
end)

test('character sync: RESTORE PRE-BANZAI on the alt; the master keeps Banzai', function()
	local S = ns.Sync
	local page = SyncCards()
	expectEq(page.this.args.restore.hidden(), false, 'RESTORE PRE-BANZAI offered')
	page.this.args.restore.func()
	expectEq(S:State(), 'NOT_SYNCED', 'not synced any more')
	expectEq(E.data:GetCurrentProfile(), 'Default', 'its own ElvUI profile back')
	expectEq(ElvPrivateDB.profileKeys[ALT], nil, 'its own private profile again')
	expectEq(compat.glassOpacity, 0.72, 'its own BANZAI settings back')
	expectEq(BushidoPrivateRestoreDB.characters[ALT].syncBackup, nil, 'snapshot used up')
	expect(ElvDB.profiles[NAME] ~= nil, 'the Banzai profile stays for the others')
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	expectEq(S:State(), 'MASTER', 'the master is untouched')
	expectEq(E.data:GetCurrentProfile(), NAME, 'still on Banzai')
end)

test('character sync: a new master continues the revisions; a restored master stops publishing', function()
	local S = ns.Sync
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	expectEq(S:State(), 'NOT_SYNCED', 'alt restored earlier')
	expect(S:Apply(), 'synced again')
	expectEq(S:State(), 'SYNCED', 'synced to Darrensdrood')
	local before = S:Master().revision
	expect(S:SetMaster(), 'the alt becomes the master')
	expectEq(S:Master().key, ALT, 'new master')
	expect(S:Master().revision >= before, 'revision count continues')
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	expectEq(S:State(), 'UPDATE', 'the previous master now has an update from the new one')
	LogIn(ALT, 'Darrenshammy', 'SHAMAN', 4)
	expect(S:RestoreCharacter(), 'the master restores its pre-Banzai setup')
	expectEq(S:Master(), nil, 'and is no master any more')
	expectEq(S:Capture(), false, 'nothing published at its logout')
	expectEq(ns.Roles:Capture(), 0, 'its leftover role data never reads the shared profile')
	expectEq((compat.roles or {}).DPS, nil, 'no other character\'s positions saved as its own')
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	expectEq(S:State(), 'NO_MASTER', 'Banzai still runs here; a master can be set again')
	expect(S:SetMaster(), 'master again')
	expectEq(S:State(), 'MASTER', 'MASTER')
end)

---------------------------------------------------------------------------
-- 0.8.0: PvP-first unit frames
---------------------------------------------------------------------------
test('0.8.0 PvP layer: cast colours, dispel glow, friendly CC / defensives, raid, focus / boss, ToT / pet', function()
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	ns.Restore:CharacterLayer(KEY, true)
	local p = profile()
	local uf, units = p.unitframe, p.unitframe.units
	local open = uf.colors.castColor
	expect(open.r == 1 and math.abs(open.g - 0.70) < 1e-6 and open.b == 0, 'interruptible: attention amber')
	local locked = uf.colors.castNoInterrupt
	expect(locked.b > locked.r and locked.r < 0.6, 'not interruptible: restrained steel violet')
	expectEq(uf.debuffHighlighting, 'GLOW', 'dispellable: ElvUI border glow, not a filled bar')
	-- friendly crowd control: the game's own category, one large icon inside the bar's right end
	local cc = units.party.auras
	expectEq(cc.enable, true, 'party CC element on')
	expectEq(cc.filter, 'HARMFUL', 'harmful auras')
	expectEq(cc.filterLists.group1.filter, 'HARMFUL||CROWD_CONTROL', 'only the game\'s CROWD_CONTROL category')
	expectEq(cc.filterLists.group1.enable, true, 'its list on')
	expectEq(cc.attachTo .. cc.anchorPoint, 'HEALTHRIGHT', 'at the right end of the bar')
	expect(cc.xOffset < -cc.sizeOverride, 'inside the bar')
	expectEq(cc.perrow * cc.numrows, 1, 'one icon')
	expect(cc.sizeOverride > units.party.debuffs.sizeOverride, 'larger than the dispel icon: hard to miss')
	for i = 2, 8 do expectEq(cc.filterLists['group' .. i].enable, false, 'CC element: group' .. i .. ' off') end
	-- 0.9.0: no ordinary buffs or debuff rows on party frames; the one debuff is a dispellable one
	expectEq(units.party.buffs.enable, false, 'no ordinary buffs')
	local dispel = units.party.debuffs
	expectEq(dispel.enable, true, 'the dispellable icon')
	expectEq(dispel.filterLists.group1.filter, 'HARMFUL||RAID_PLAYER_DISPELLABLE', 'only effects this character can dispel')
	for i = 2, 8 do expectEq(dispel.filterLists['group' .. i].enable, false, 'dispel element: group' .. i .. ' (ElvUI\'s other debuff lists) off') end
	expectEq(dispel.perrow * dispel.numrows, 1, 'one compact icon, no row')
	expectEq(dispel.anchorPoint .. dispel.growthY, 'BOTTOMRIGHTDOWN', 'below the frame\'s right end')
	expect(dispel.sizeOverride <= 16, 'compact')
	local role = units.party.customTexts['b-Role']
	expectEq(role.text_format, '[mMT-role:icon]', 'mMediaTag\'s role icon tag')
	expectEq(role.justifyH .. tostring(role.enable), 'RIGHTtrue', 'inside the bar\'s right end')
	-- raid: compact, role, one raid-relevant debuff before the percent, status in the middle
	-- (only tags Retail ElvUI registers: health:* is Classic-only there, the raid-debuff element too)
	for _, unit in ipairs(T.RAID_UNITS) do
		expectEq(units[unit].roleIcon.enable, true, unit .. ': role icon')
		expectEq(units[unit].roleIcon.size, 10, unit .. ': small')
		local d = units[unit].debuffs
		expectEq(d.enable, true, unit .. ': a raid debuff')
		expectEq(d.attachTo .. d.anchorPoint, 'HEALTHRIGHT', unit .. ': in the bar')
		expect(d.xOffset + d.sizeOverride < -25, unit .. ': clear of the percent')
		expectEq(d.perrow * d.numrows, 1, unit .. ': one')
		expectEq(units[unit].rdebuffs and units[unit].rdebuffs.enable, P.elvuiProfile.unitframe.units[unit].rdebuffs and P.elvuiProfile.unitframe.units[unit].rdebuffs.enable, unit .. ': raid-debuff element left alone (not on Retail)')
		expect(string.find(units[unit].customTexts['m-Health'].text_format, '[perhp<%]', 1, true), unit .. ': percent')
	end
	for _, unit in ipairs({ 'party', 'raid1', 'raid2', 'raid3' }) do
		local st = units[unit].customTexts['b-Status']
		expectEq(st.text_format, '|cffb8bcc4[status]|r', unit .. ': Dead / Ghost / Offline (oUF\'s [status])')
		expectEq(st.justifyH .. tostring(st.enable), 'CENTERtrue', unit .. ': centred')
	end
	for _, text in ipairs({ T.RAID_PERCENT.format, T.PVP.totText, T.PVP.status.format }) do
		expect(not string.find(text, '[health:', 1, true), 'no Classic-only ElvUI health tag: ' .. text)
	end
	-- focus / boss
	expectEq(units.focus.castbar.enable, true, 'focus cast bar')
	expectEq(units.focus.debuffs.enable, true, 'focus crowd control / debuffs')
	expectEq(units.focus.debuffs.anchorPoint, 'RIGHT', 'clear of the identity circle on the left')
	for _, unit in ipairs({ 'boss', 'arena' }) do
		local cb = units[unit].castbar
		expectEq(cb.enable, true, unit .. ' cast bar')
		expectEq(cb.overlayOnFrame, 'None', unit .. ': its own bar (Bushido overlaid a power bar these frames do not show)')
		expectEq(units[unit].power.enable, false, unit .. ': (power bar off, as in Bushido)')
		expectEq(cb.positionsGroup.anchorPoint, 'TOP', unit .. ': above each frame')
		expect(units[unit].spacing >= cb.height + cb.positionsGroup.yOffset, unit .. ': frames spaced for it')
		expectEq(cb.width, units[unit].width, unit .. ': as wide as the frame')
	end
	expectEq(units.arena.castbar.width, units.arena.width, 'the arena cast bar is as wide as the (narrow) arena frame')
	expectEq(units.boss.debuffs.anchorPoint, 'LEFT', 'boss debuffs left (the boss frames sit at the right screen edge)')
	expect(units.boss.debuffs.xOffset <= -(27 + 4), 'clear of the identity circle')
	-- ToT / pet subordinate
	expectEq(units.targettarget.customTexts['m-Health'].text_format, T.PVP.totText, 'ToT: percent')
	expectEq(p.mMediaTag.portraits.targettarget.enable, false, 'ToT: no portrait')
	expectEq(p.mMediaTag.portraits.pet.enable, false, 'pet: no portrait')
	-- Player / Target untouched
	for _, unit in ipairs({ 'player', 'target' }) do
		local now, old = units[unit].castbar, P.elvuiProfile.unitframe.units[unit].castbar
		expectEq(T.Serialize({ now.enable, now.width, now.height, now.customColor }), T.Serialize({ old.enable, old.width, old.height, old.customColor }), unit .. ' cast bar untouched (its own colours)')
		expectEq(p.mMediaTag.portraits[unit].enable, true, unit .. ' anchor untouched')
	end
	expectEq(HK_FindString(T.PVP, 'UnitAura'), nil, 'no aura reading of its own')
end)

test('1.0.1 arena enemies: Banzai\'s mirrored frames only - no sArena integration, choice or state handling; DR not a Banzai feature', function()
	local p = profile()
	local arena = p.unitframe.units.arena
	-- whatever is installed or loaded, Banzai's arena enemy frames are on (one system)
	for _, loaded in ipairs({ true, false }) do
		HK_LOADED.sArena_Reloaded = loaded or nil
		ns.Restore:CharacterLayer(KEY, true)
		expectEq(arena.enable, true, 'Banzai arena enemy frames on (sArena loaded: ' .. tostring(loaded) .. ')')
	end
	HK_LOADED.sArena_Reloaded = nil
	expectEq(arena.castbar.enable, true, 'cast bar above each frame')
	expectEq(arena.pvpTrinket.enable, false, 'ElvUI\'s trinket off - Banzai Art\'s trinket circle (the same game data)')
	expectEq(arena.debuffs.filterLists.group1.filter, 'HARMFUL||CROWD_CONTROL', 'their crowd control')
	for _, key in ipairs(T.AURA_CANDIDATES) do
		expectEq(arena.debuffs.filterLists.group1.candidates[key], false, 'no ElvUI candidate restriction left on it: ' .. key)
	end
	expectEq(arena.debuffs.filterLists.group1.useAllowlist, false, 'no allow list either')
	for i = 2, 8 do expectEq(arena.debuffs.filterLists['group' .. i].enable, false, 'no other debuff list ' .. i) end
	expectEq(arena.debuffs.anchorPoint .. arena.debuffs.attachTo, 'RIGHTHEALTH', 'over the (mirrored) identity circle on the right')
	expectEq(arena.buffs.enable, true, 'their offensive / defensive buffs')
	expectEq(arena.buffs.anchorPoint, 'LEFT', 'left of the trinket circle')
	expectEq(arena.buffs.filterLists.group3.filter, 'HELPFUL||IMPORTANT||!BIG_DEFENSIVE||!EXTERNAL_DEFENSIVE', 'the game\'s IMPORTANT category')
	-- no sArena code left: no owner, no choice, no switching, nothing restored
	expectEq(ns.Restore.ArenaOwner, nil, 'no arena owner detection')
	expectEq(ns.Restore.ArenaSystem, nil, 'no arena system choice')
	expectEq(ns.Restore.SetArenaSystem, nil, 'nothing switches addons')
	expectEq(T.PVP.arenaAddons, nil, 'no sArena list')
	expect(string.find(HK_Plain(ns.Restore:PvPText()), 'arena enemies: Banzai mirrored frames', 1, true), '/banzai status: Banzai\'s frames')
	local frames = Find(Opts('pvp'), 'size').args
	expectEq(frames.system, nil, 'PVP page: no SARENA / BANZAI selector')
	expect(string.find(HK_Plain(frames.owner.name()), 'only arena enemy system', 1, true), 'PVP page: Banzai\'s frames, the only system')
	expect(not string.find(HK_Plain(frames.owner.name()), 'sArena', 1, true), 'no sArena wording on the PVP page')
	expectEq(Find(Opts('pvp'), 'dr'), nil, 'no DR section (DR is not a Banzai feature)')
	-- the 0.9.0 choice left in the saved data is forgotten; Backup & Restore leaves sArena alone
	local r = record()
	r.arenaSystem, r.previous.arenaAddonState = 'BANZAI', 2
	HK_ADDON_ENABLED, HK_ADDON_CALLS = { sArena_Reloaded = 0 }, {}
	ns.Restore:OnLogin()
	expectEq(r.arenaSystem, nil, 'the old choice forgotten')
	expectEq(r.previous.arenaAddonState, nil, 'no sArena state kept')
	r.arenaSystem, r.previous.arenaAddonState = 'BANZAI', 2
	ns.Restore:Revert()
	expectEq(#HK_ADDON_CALLS, 0, 'restore: sArena never switched on or off')
	expectEq(HK_ADDON_ENABLED.sArena_Reloaded, 0, '(left as Darren has it)')
	ns.Restore:Apply('manual')
	expectEq(#HK_ADDON_CALLS, 0, 'apply: nothing switched either')
end)

test('0.9.0 role layouts: party / arena allies 50 % narrower (HEALER 30 % lower), DPS aligned with the raid, enemies mirrored on the right', function()
	local p = profile()
	local party, arena = p.unitframe.units.party, p.unitframe.units.arena
	local bushido = P.elvuiProfile.unitframe.units.party
	HK_SPEC_INDEX = 2
	ns.Roles:Check('test')
	expectEq(party.width, bushido.width / 2, 'DPS: half of Bushido\'s width')
	expectEq(party.height, bushido.height, 'DPS: Bushido\'s height kept')
	expectEq(party.auras.sizeOverride, 30, 'DPS: the CC icon')
	local px = tonumber(string.match(p.movers.ElvUF_PartyMover, '^BOTTOMLEFT,UIParent,BOTTOMLEFT,([%d.-]+),'))
	local rx = tonumber(string.match(p.movers.ElvUF_Raid1Mover, '^BOTTOMLEFT,UIParent,BOTTOMLEFT,([%d.-]+),'))
	expectEq(px - 27 - 4, rx, 'DPS: the party\'s identity circles start where the raid frames start')
	expectEq(T.RoleLayout('DPS', P.elvuiProfile).ArenaAlliesMover, p.movers.ElvUF_PartyMover, 'DPS arena allies: the same place system')
	expectEq(arena.width .. 'x' .. arena.height, party.width .. 'x' .. party.height, 'arena enemies: the allies\' size')
	expect(string.find(p.movers.ArenaHeaderMover, '^BOTTOMRIGHT,UIParent,BOTTOMRIGHT,%-54,'), 'arena enemies on the right edge (mirrored margin)')
	expectEq(string.match(p.movers.ArenaHeaderMover, ',([%d.-]+)$'), string.match(p.movers.ElvUF_PartyMover, ',([%d.-]+)$'), 'at the allies\' level')
	HK_UF.headerUpdates, HK_UF.groupUpdates = {}, {}
	HK_SPEC_INDEX = 4
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(party.width, bushido.width / 2, 'HEALER: the DPS width')
	expectEq(party.height, math.floor(bushido.height * 0.7), 'HEALER: 30 % lower')
	expect(party.auras.sizeOverride <= party.height - 4, 'HEALER: the CC icon fits the lower bar')
	expectEq(string.match(party.growthDirection, '^(%u+)'), 'RIGHT', 'HEALER: one horizontal row')
	expect(party.horizontalSpacing >= 2 * (27 + 4), 'room for the identity circle and the trinket circle between frames')
	expectEq(p.movers.ElvUF_PartyMover, 'BOTTOM,UIParent,BOTTOM,0,454', 'centred (circle left, trinket right); 1.0.0: lower, just above Player / Target / Focus')
	expectEq(arena.height, party.height, 'arena enemies match the HEALER frames')
	expectEq(string.match(p.movers.ArenaHeaderMover, ',([%d.-]+)$'), '454', 'enemies at the row\'s level')
	expectEq(HK_UF.headerUpdates[#HK_UF.headerUpdates], 'party', 'ElvUI rebuilds the party header')
	expectEq(HK_UF.groupUpdates[#HK_UF.groupUpdates], 'arena', 'and the arena frames')
	-- Darren changes the HEALER height in ElvUI: kept for HEALER only
	party.height = 30
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(compat.roles.HEALER['party.height'], 30, 'kept as HEALER\'s own')
	expectEq(party.height, bushido.height, 'DPS keeps its height')
	ns.Roles:Reset('HEALER')
	expectEq(compat.roles.HEALER, nil, 'reset')
	-- the preview reads the same layout
	expectEq(ns.Roles:Layout('HEALER')['party.height'], 27, 'preview: HEALER height')
	expectEq(ns.Roles:Layout('DPS')['arena.width'], 100, 'preview: arena width')
end)

test('0.9.0 BANZAI -> PVP page: concise sections, sensible controls, preview with the state selector', function()
	local page = E.Options.args.banzai
	local pvp = page.args.pvp
	expectEq(pvp.type, 'group', 'PVP page')
	expectEq(pvp.name, 'PVP', 'named PVP')
	expect(pvp.order > page.args.unitframes.order and pvp.order < page.args.actionbars.order, '1.0.0: after UNIT FRAMES')
	expectEq(pvp.childGroups, 'tab', 'FRAMES / COOLDOWN BARS / PREVIEW tabs')
	local titles = {}
	for _, tab in pairs(pvp.args) do
		for key, section in pairs(tab.args or {}) do if section.type == 'group' then titles[key] = HK_Plain(section.name) end end
	end
	for key, title in pairs({ size = 'PARTY / ARENA FRAME SIZE', role = 'ROLE ICON', trinket = 'TRINKET', cc = 'CC', dispel = 'DISPELLABLE STATE',
		offensive = 'OFFENSIVE COOLDOWN BARS', defensive = 'DEFENSIVE COOLDOWN BARS', preview = 'PREVIEW' }) do
		expectEq(titles[key], title, title)
	end
	local controls = 0
	local function count(t) for _, v in pairs(t) do if type(v) == 'table' then if v.type == 'toggle' or v.type == 'select' or v.type == 'range' or v.type == 'multiselect' then controls = controls + 1 end count(v) end end end
	count(pvp)
	expect(controls <= 20, 'no wall of controls (' .. controls .. ')')
	local args = setmetatable({}, { __index = function(_, k) return Find(pvp, k) end })
	-- cast colours still write the layer and ask for a reload
	expectEq(args.casts.args.colors.get(), true, 'cast colours on by default')
	HK_POPUPS = {}
	args.casts.args.colors.set(nil, false)
	expectEq(compat.pvpCastColors, false, 'saved with the BANZAI settings (synced)')
	local colors = profile().unitframe.colors
	expectEq(T.Serialize(colors.castColor), T.Serialize(P.elvuiProfile.unitframe.colors.castColor), 'off: Bushido\'s colours')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload')
	args.casts.args.colors.set(nil, true)
	-- the role icon writes the layer
	args.role.args.toggle.set(nil, false)
	expectEq(profile().unitframe.units.party.customTexts['b-Role'].enable, false, 'role icon off')
	args.role.args.toggle.set(nil, true)
	expectEq(profile().unitframe.units.party.customTexts['b-Role'].enable, true, 'role icon on')
	-- enemy offensive / defensive icons
	args.size.args.defensives.set(nil, false)
	expectEq(profile().unitframe.units.arena.buffs.enable, false, 'enemy buff icons off')
	args.size.args.defensives.set(nil, true)
	-- Banzai Art settings (drawn live): CC / dispel emphasis, trinket circles, cooldown bars
	for _, key in ipairs({ 'cc', 'dispel' }) do
		local level = args[key].args.level
		expectEq(level.type, 'select', key .. ' emphasis level')
		local values = level.values
		expect(values.STRONG and values.CLEAR and values.MINIMAL, key .. ': STRONG / CLEAR / MINIMAL')
		level.set(nil, 'CLEAR')
		expectEq(compat[key == 'cc' and 'ccEmphasis' or 'dispelEmphasis'], 'CLEAR', key .. ' saved')
		level.set(nil, 'STRONG')
	end
	args.trinket.args.toggle.set(nil, false)
	expectEq(compat.trinketCircles, false, 'trinket circles off')
	args.trinket.args.toggle.set(nil, true)
	expectEq(args.bars.args.scale.min .. '-' .. args.bars.args.scale.max, '0.7-1.2', 'bounded scale')
	expectEq(args.offensive.args.count.max, 5, 'at most 5 bars')
	expectEq(args.offensive.args.tracked.type, 'multiselect', 'tracked offensive cooldowns')
	expectEq(args.defensive.args.tracked.type, 'multiselect', 'tracked defensive cooldowns')
	-- honest texts
	local trinket = HK_Plain(args.trinket.args.text.name)
	expect(string.find(trinket, 'No timer is invented', 1, true) and string.find(trinket, 'UNKNOWN', 1, true), 'trinket: honest states')
	expect(string.find(HK_Plain(args.bars.args.text.name), 'never guessed', 1, true), 'cooldowns: honest')
	-- the preview
	local pv = args.preview.args
	expectEq(pv.state.type, 'select', 'state selector')
	expectEq(pv.next.type, 'execute', 'NEXT STATE')
	for _, key in ipairs({ 'arena', 'raid', 'bars', 'hide' }) do expectEq(pv[key].type, 'execute', key) end
	expectEq(HK_Plain(pv.arena.name), 'PARTY + ARENA', 'party, arena allies and arena enemies together')
	expectEq(HK_Plain(pv.bars.name), 'COOLDOWN BARS', 'cooldown bar preview')
	expectEq(HK_Plain(pv.hide.name), 'HIDE ALL', 'HIDE ALL')
	expect(Find(page.args.unitframes, 'previewState') and Find(page.args.unitframes, 'previewState').type == 'select', 'the selector on UNIT FRAMES too')
	-- ADDON REPLACEMENT STATUS (1.0.1): sArena Reloaded no longer required by Banzai
	local replaced = HK_Plain(page.args.components.args.replacement.args.replaced.args.list.name())
	expect(string.find(replaced, 'sArena Reloaded', 1, true) and string.find(replaced, 'no longer required by Banzai', 1, true), 'sArena: no longer required')
	expect(not string.find(HK_Plain(page.args.components.args.replacement.args.keep.args.list.name()), 'sArena', 1, true), 'not under BANZAI STILL USES')
end)

---------------------------------------------------------------------------
-- 1.0.0
---------------------------------------------------------------------------
test('1.0.0 Player / Target / Focus / ToT width: half by default, every piece reflowed, 100 % gives Bushido back', function()
	local p = profile()
	local units, m, old = p.unitframe.units, p.movers, P.elvuiProfile
	-- the default (BANZAI 1.0): half width, heights kept
	for unit, full in pairs({ player = 302, target = 302, focus = 210 }) do
		expectEq(units[unit].width, full / 2, unit .. ': half width')
		expectEq(units[unit].height, old.unitframe.units[unit].height, unit .. ': height kept')
	end
	expectEq(units.player.power.detachedWidth, 151, 'player power bar with it')
	expectEq(units.target.power.detachedWidth, 151, 'target power bar with it')
	expectEq(units.focus.power.detachedWidth, 205 - 105, 'focus power bar with it')
	expectEq(units.player.classbar.detachedWidth, 305 - 151, 'class bar: the same inset at both ends')
	expectEq(units.player.classAdditional.width, T.ADDITIONAL_POWER.width - 151, 'extra mana bar too')
	expectEq(units.player.buffs.perrow, math.floor(old.unitframe.units.player.buffs.perrow * 0.5), 'its own buffs: fewer per row')
	expectEq(m.PlayerPowerBarMover, T.ShiftMover(old.movers.PlayerPowerBarMover, 151, 0), 'power bar on the frame')
	expectEq(m.TargetPowerBarMover, T.ShiftMover(old.movers.TargetPowerBarMover, -151, 0), 'target power bar mirrored')
	expectEq(m.ElvUF_FocusMover, T.ShiftMover(old.movers.ElvUF_FocusMover, 151, 0), 'Focus: its left end on the Player\'s')
	expectEq(m.FocusPowerBarMover, T.ShiftMover(old.movers.FocusPowerBarMover, 151, 0), 'focus power with it')
	-- inner ends where they were (UIParent units: Player right 713, Target left mirrored)
	local px = tonumber(string.match(m.ElvUF_PlayerMover, ',([%d.-]+),[%d.-]+$'))
	expectEq(px + units.player.width, 411 + 302, 'the Player\'s inner end unchanged (bamboo, combat tree, cast history)')
	local tx = tonumber(string.match(m.ElvUF_TargetMover, ',([%d.-]+),[%d.-]+$'))
	expectEq(tx - units.target.width, -411 - 302, 'the Target\'s inner end unchanged')
	-- the option (per character, a reload applies it)
	local width = Find(Opts('unitframes'), 'frameWidth')
	expectEq(width.get(), 0.5, 'shown as 50 %')
	expectEq(width.min .. '-' .. width.max, '0.5-1', 'between half and Bushido\'s width')
	HK_POPUPS = {}
	width.set(nil, 1)
	expectEq(compat.frameWidth, 1, 'saved with the BANZAI settings (Character Sync carries it)')
	expectEq(units.player.width, 302, '100 %: Bushido\'s width')
	expectEq(m.ElvUF_PlayerMover, old.movers.ElvUF_PlayerMover, 'and its place')
	expectEq(m.ClassBarMover, old.movers.ClassBarMover, 'class bar too')
	expectEq(units.targettarget.width, round(210 * 0.72), 'ToT back to its 0.9.0 size')
	expectEq(m.ElvUF_TargetTargetMover, T.TOT.mover, 'and place')
	expectEq(texts('player')['m-Name'].text_format, T.IDENTITY.player, 'one identity line again')
	expectEq(texts('player')['b-Spec'].enable, false, 'no spec line')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'a reload applies it')
	Find(Opts('unitframes'), 'widthReset').func()
	expectEq(units.player.width, 151, 'BANZAI 1.0 width again')
	expectEq(texts('player')['b-Spec'].enable, true, 'two lines again')
	-- the spec names switch works on both arrangements
	local specNames = Find(Opts('appearance'), 'specNames')
	specNames.set(nil, false)
	expectEq(texts('player')['b-Spec'].enable, false, 'spec off: no spec line')
	expectEq(texts('player')['m-Name'].text_format, T.IDENTITY_SPLIT.player.name, 'the name alone')
	expectEq(specNames.get(), false, 'reads back')
	ns.Restore:CharacterLayer(KEY, true)
	expectEq(texts('player')['b-Spec'].enable, false, 'the choice survives the character layer')
	specNames.set(nil, true)
	expectEq(texts('player')['b-Spec'].enable, true, 'spec back on its line')
	expectEq(texts('target')['b-Spec'].enable, true, 'target too')
end)

test('1.0.0 HEALER row: just above Player / Target / Focus, arena allies and party keep separate saved positions, raid on the same baseline', function()
	local p = profile()
	local H = T.ROLE_LAYOUTS.HEALER
	expectEq(T.HEALER_ROW, 454, 'the row\'s bottom')
	for _, name in ipairs({ 'ElvUF_PartyMover', 'ArenaAlliesMover' }) do expectEq(H[name], 'BOTTOM,UIParent,BOTTOM,0,454', name .. ': centred, lower') end
	expectEq(H.ArenaHeaderMover, 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-54,454', 'arena enemies at the row\'s level')
	expectEq(H.ElvUF_Raid1Mover, 'BOTTOMLEFT,UIParent,BOTTOMLEFT,560,454', 'HEALER raid on the row\'s baseline (clear of the Focus frame)')
	expectEq(T.ROLE_LAYOUTS.DPS.ElvUF_PartyMover, 'BOTTOMLEFT,UIParent,BOTTOMLEFT,54,362', 'DPS column unchanged')
	-- the row against the half-width frames (UIParent units at Darren's setup)
	local fx = tonumber(string.match(p.movers.ElvUF_FocusMover, ',([%d.-]+),[%d.-]+$'))
	local rowLeft = SCREEN_W / 2 - (5 * 100 + 4 * 70) / 2
	expect(rowLeft < fx + 105 and rowLeft + 100 > fx, '(the first frame sits over the Focus frame)')
	expectEq(454 - 16 - (397 + 35), 6, 'its dispel icons clear the Focus frame by a clean gap')
	-- separate saved positions: the HEALER party and the HEALER arena allies
	HK_SPEC_INDEX = 4
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(p.movers.ElvUF_PartyMover, H.ElvUF_PartyMover, 'HEALER party in its row')
	p.movers.ElvUF_PartyMover = 'BOTTOM,UIParent,BOTTOM,0,430'
	HK_INSTANCE = 'arena'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	expectEq(compat.roles.HEALER.ElvUF_PartyMover, 'BOTTOM,UIParent,BOTTOM,0,430', 'the party\'s own place kept')
	expectEq(p.movers.ElvUF_PartyMover, 'BOTTOM,UIParent,BOTTOM,0,430', 'arena allies without a place of their own: where this role\'s party is (one placement system)')
	p.movers.ElvUF_PartyMover = 'BOTTOM,UIParent,BOTTOM,30,470'
	HK_INSTANCE = 'none'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	expectEq(compat.roles.HEALER.ArenaAlliesMover, 'BOTTOM,UIParent,BOTTOM,30,470', 'the allies\' own place kept')
	expectEq(compat.roles.HEALER.ElvUF_PartyMover, 'BOTTOM,UIParent,BOTTOM,0,430', 'the party\'s place not changed by the allies\' move')
	expectEq(p.movers.ElvUF_PartyMover, 'BOTTOM,UIParent,BOTTOM,0,430', 'the party back where Darren put it')
	HK_INSTANCE = 'arena'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	expectEq(p.movers.ElvUF_PartyMover, 'BOTTOM,UIParent,BOTTOM,30,470', 'next arena: the allies at their own place')
	HK_INSTANCE = 'none'
	HK_Fire('ZONE_CHANGED_NEW_AREA')
	ns.Roles:Reset('HEALER')
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
end)

test('1.0.0 settings app: Options.Open selects HOME in the BANZAI tree, reuses an open window, never in combat', function()
	HK_OPENED, HK_ACD.selected = nil, {}
	HK_ACD.OpenFrames.ElvUI = nil
	HK_ACD:GetStatusTable('ElvUI', { 'banzai' }).groups = { selected = 'afk' }
	expectEq(ns.Options.Open('home'), true, 'opened')
	expectEq(HK_OPENED, 'banzai', 'closed window: ElvUI\'s own ToggleOptions at BANZAI')
	expectEq(HK_ACD:GetStatusTable('ElvUI', { 'banzai' }).groups.selected, 'home', 'the BANZAI tree on HOME')
	HK_OPENED = nil
	HK_ACD.OpenFrames.ElvUI = { frame = {} }
	expectEq(ns.Options.Open('home'), true, 'again')
	expectEq(HK_OPENED, nil, 'open window: no second window, no toggle (it would close)')
	expectEq(HK_ACD.selected[1], 'ElvUI:banzai', 'BANZAI selected in the open window')
	expectEq(BanzaiOpenSettings, ns.Options.Open, 'the wordmark (Banzai Art) reaches it')
	HK_IN_COMBAT, HK_PRINTS, HK_ACD.selected = true, {}, {}
	expectEq(ns.Options.Open('home'), false, 'combat: nothing opens')
	expectEq(#HK_ACD.selected, 0, 'nothing selected')
	expect(string.find(HK_PRINTS[1] or '', 'cannot open in combat', 1, true), 'a one-line message, nothing queued')
	HK_IN_COMBAT = false
	expectEq(ns.Options.Open('nonsense'), true, 'an unknown page: HOME')
	expectEq(HK_ACD:GetStatusTable('ElvUI', { 'banzai' }).groups.selected, 'home', 'HOME')
	HK_ACD.OpenFrames.ElvUI = nil
end)

test('1.0.0 tooltip theme, AFK screen and action-button look write their ElvUI settings (per character)', function()
	local p = profile()
	-- tooltip fonts: the small crisp font; ELVUI: Bushido's tooltip back
	expectEq(p.tooltip.font, 'Rubik-Bold', 'small text font')
	expectEq(p.tooltip.fontOutline, 'SHADOW', 'crisp: shadow, no outline')
	expectEq(p.tooltip.headerFontSize .. ',' .. p.tooltip.textFontSize .. ',' .. p.tooltip.smallTextFontSize, '12,11,10', 'small sizes')
	local theme = Find(Opts('tooltips'), 'tooltipTheme')
	theme.set(nil, 'ELVUI')
	expectEq(compat.tooltipTheme, 'ELVUI', 'saved')
	for _, key in ipairs(T.TOOLTIP_KEYS) do expectEq(p.tooltip[key], P.elvuiProfile.tooltip and P.elvuiProfile.tooltip[key], 'ELVUI: Bushido\'s ' .. key) end
	theme.set(nil, 'BANZAI')
	expectEq(p.tooltip.font, 'Rubik-Bold', 'BANZAI again')
	-- AFK: ElvUI's own screen off while Banzai's is on, back as Bushido had it when off
	expectEq(p.general.afk, false, 'Banzai AFK on: ElvUI\'s AFK screen off')
	local afk = Find(Opts('afk'), 'afk')
	afk.set(nil, false)
	expectEq(compat.afk, false, 'saved')
	expectEq(p.general.afk, P.elvuiProfile.general and P.elvuiProfile.general.afk, 'ElvUI\'s AFK screen as Bushido had it')
	expectEq(Find(Opts('afk'), 'afkModel').disabled(), true, 'its options greyed while off')
	afk.set(nil, true)
	expectEq(p.general.afk, false, 'one AFK screen at a time')
	-- action-button look: size and spacing within the composition's range, the upper row keeps its gap
	local size, spacing = Find(Opts('actionbars'), 'abSize'), Find(Opts('actionbars'), 'abSpacing')
	expectEq(size.min .. '-' .. size.max, '26-32', 'size range')
	HK_POPUPS = {}
	size.set(nil, 32)
	spacing.set(nil, 7)
	expectEq(p.actionbar.bar1.buttonSize .. 'x' .. p.actionbar.bar1.buttonHeight .. ' / ' .. p.actionbar.bar1.buttonSpacing, '32x32 / 7', 'circles larger, still round')
	local function y(name) return tonumber(string.match(p.movers[name], ',([%d.-]+)$')) end
	expectEq(y('ElvAB_1') - y('ElvAB_6'), 32 + 7, 'the upper row one circle + one gap above')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'a reload applies it')
	size.set(nil, 99)
	expectEq(p.actionbar.bar1.buttonSize, 32, 'never past the range')
	size.set(nil, 30)
	spacing.set(nil, 6)
	expectEq(y('ElvAB_1') - y('ElvAB_6'), 36, 'BANZAI look again')
	local keybind = Find(Opts('actionbars'), 'abKeybind')
	Find(Opts('actionbars'), 'actionStyle').set(nil, 'CIRCLE') -- 1.2.0: the keybind size is the circles' centred keybind
	keybind.set(nil, 1.5)
	expectEq(p.actionbar.bar1.hotkeyFontSize, math.floor((P.elvuiProfile.actionbar.bar1.hotkeyFontSize or 10) * 1.5 + 0.5), 'keybind size')
	keybind.set(nil, 1.3)
	expectEq(size.disabled(), false, 'circle options while circles are on')
	Find(Opts('actionbars'), 'actionStyle').set(nil, 'SQUARE')
	expectEq(size.disabled(), false, 'size and spacing also for the square')
	expectEq(p.actionbar.bar1.hotkeyFontSize, math.floor((P.elvuiProfile.actionbar.bar1.hotkeyFontSize or 10) + 0.5), 'the square keeps its compact keybind')
	-- the Character Sync plan names the 1.0.0 settings
	local owned = ''
	for _, row in ipairs(ns.Sync.OWNERSHIP) do owned = owned .. row[2] end
	expect(string.find(owned, 'Target-of-Target width', 1, true) and string.find(owned, 'AFK screen', 1, true) and string.find(owned, 'tooltips', 1, true), 'synced')
end)

test('1.0.0 review: the upgrade from 0.9.0 keeps "Specialization in names" off and Darren\'s health number size', function()
	LogIn(KEY, 'Darrensdrood', 'DRUID', 2)
	local p = profile()
	local r = record()
	-- a 0.9.0 profile (one identity line) with spec off and a larger health number
	for unit, line in pairs(T.IDENTITY_SPLIT) do
		local t = p.unitframe.units[unit].customTexts
		t['m-Name'].text_format = line.name
		t['b-Spec'] = nil
		t['m-Health'].size = 24
	end
	r.layer, r.layerSettings = 11, nil
	ns.Restore:OnAddonLoaded()
	expectEq(r.layerSettings and r.layerSettings.layer, T.LAYER, '(upgraded at addon load)')
	for unit, line in pairs(T.IDENTITY_SPLIT) do
		local t = p.unitframe.units[unit].customTexts
		expectEq(t['m-Name'].text_format, line.name, unit .. ': the name alone (spec stays off)')
		expectEq(t['b-Spec'] and t['b-Spec'].enable or false, false, unit .. ': no spec line switched on')
		expectEq(t['m-Health'].size, 24, unit .. ': his health number size kept')
	end
	expectEq(ns.Restore:OnLogin(), true, 'completed after login')
	expectEq(r.layer, T.LAYER, 'layer recorded')
	-- the choices back for the next tests
	Find(Opts('appearance'), 'specNames').set(nil, true)
	for unit in pairs(T.IDENTITY_SPLIT) do p.unitframe.units[unit].customTexts['m-Health'].size = 20 end
end)

test('1.0.0 review: health under the narrow bars (inside off) stays together and clear of the spec line and the Target-of-Target', function()
	local p = profile()
	local units = p.unitframe.units
	local health = Find(Opts('appearance'), 'healthInside')
	health.set(nil, false)
	-- the value is measured from the inner end, the percent from the outer end: the pair stays on the bar
	local pv, pp = units.player.customTexts['m-Health'], units.player.customTexts['b-HealthPct']
	expectEq(pv.justifyH .. pv.xOffset, 'RIGHT' .. (-212 + 151), 'player value: as far from the outer end as before (inner-end offset + the cut)')
	expectEq(pp.justifyH .. pp.xOffset, 'LEFT92', 'player percent unchanged (outer end)')
	local tv = units.target.customTexts['m-Health']
	expectEq(tv.justifyH .. tv.xOffset, 'LEFT' .. (212 - 151), 'target mirrored')
	local fv = units.focus.customTexts['m-Health']
	expectEq(fv.xOffset, -148 + 105, 'focus value on its narrow bar')
	expectEq(fv.yOffset, T.HEALTH.focus.value[3], 'focus has no spec line: same height')
	expectEq(pv.yOffset, T.HEALTH.player.value[3] - T.SPEC_LINE, 'under the spec line')
	expect(pv.yOffset + pv.size / 2 < units.player.customTexts['b-Spec'].yOffset - 5, 'value clear of the spec line')
	local cut = round(210 * 0.72) - round(210 * 0.72 * 0.5)
	expectEq(p.movers.ElvUF_TargetTargetMover, T.ShiftMover(T.TOT.mover, -cut, -(T.TOT_DROP + T.TOT_OUTSIDE_DROP)), 'the Target-of-Target lower, clear of the Target\'s health under its bar')
	health.set(nil, true)
	expectEq(p.movers.ElvUF_TargetTargetMover, T.ShiftMover(T.TOT.mover, -cut, -T.TOT_DROP), 'inside again: its usual place')
	expectEq(units.player.customTexts['m-Health'].enable, false, 'ElvUI value off again')
end)

test('1.0.0 review: without Banzai Art loaded, ElvUI\'s own AFK screen stays on', function()
	local p = profile()
	BanzaiCompat = nil
	expectEq(ns.Restore:LayerOptions().afk, false, 'no Banzai AFK screen without Banzai Art')
	ns.Restore:CharacterLayer(KEY, true)
	expectEq(p.general.afk, P.elvuiProfile.general and P.elvuiProfile.general.afk, 'ElvUI\'s AFK screen as Bushido had it')
	BanzaiCompat = CompatStub
	ns.Restore:CharacterLayer(KEY, true)
	expectEq(p.general.afk, false, 'Banzai Art back: one AFK screen (Banzai\'s)')
end)

---------------------------------------------------------------------------
-- 1.0.1: Character Sync live-validation preparation
---------------------------------------------------------------------------
local ROGUE, PRIEST = 'Darrensrogue - Stormrage', 'Darrenspriest - Stormrage'
local DRUID_SPECS = HK_SPECINFO
local ROGUE_SPECS = { [1] = { 259, 'Assassination', 'A deadly master of poisons.', 236270, 'DAMAGER' }, [2] = { 260, 'Outlaw', '', 236286, 'DAMAGER' } }
local PRIEST_SPECS = { [1] = { 256, 'Discipline', '', 135940, 'HEALER' }, [2] = { 257, 'Holy', '', 237542, 'HEALER' }, [3] = { 258, 'Shadow', '', 136207, 'DAMAGER' } }
-- a key anywhere in a table, by name (case-insensitive)
local function HasKey(tbl, names, seen)
	seen = seen or {}
	if type(tbl) ~= 'table' or seen[tbl] then return nil end
	seen[tbl] = true
	for k, v in pairs(tbl) do
		local key = string.lower(tostring(k))
		for _, name in ipairs(names) do if key == name then return key end end
		local hit = HasKey(v, names, seen)
		if hit then return hit end
	end
end
local function DetailsWindows()
	local n = 0
	for _, prof in pairs(Details.profiles) do for _ in pairs(type(prof.instances) == 'table' and prof.instances or {}) do n = n + 1 end end
	return n, #Details.applied
end
local GAMEPLAY_KEYS = { 'bindings', 'keybinds', 'macros', 'talents', 'loadout', 'loadouts', 'equipment', 'equipmentsets', 'actions', 'actionslots', 'spells', 'currencies', 'reputation', 'quests' }

test('1.0.1 sync: no master until Darren sets one; SET AS BANZAI MASTER captures the approved visual setup with identity, version and schema - no gameplay data', function()
	LogIn(KEY, 'Darrensdrood', 'DRUID', 1) -- Balance
	HK_SPECINFO = DRUID_SPECS
	local S = ns.Sync
	BushidoPrivateRestoreDB.sync.master = nil
	local cards = SyncCards()
	expectEq(S:State(), 'NO_MASTER', 'Banzai runs here, no master')
	expect(string.find(HK_Plain(cards.master.args.info.name()), 'NO BANZAI MASTER SET', 1, true), 'the master card: NO BANZAI MASTER SET')
	expect(string.find(HK_Plain(cards.this.args.state.name()), 'NO BANZAI MASTER SET', 1, true), 'this character\'s card too')
	expect(string.find(HK_Plain(cards.synced.args.list.name()), 'MASTER   NO BANZAI MASTER SET', 1, true), 'sync status too')
	expectEq(cards.master.args.setMaster.hidden(), false, 'SET AS BANZAI MASTER offered')
	-- loading, logging in and out never set a master
	ns.Restore:OnAddonLoaded()
	ns.Restore:OnLogin()
	HK_Fire('PLAYER_LOGOUT')
	expectEq(S:Master(), nil, 'never set automatically')
	compat.cdTracked = { DRUID = { [22812] = false } } -- Darren's Barkskin choice on the cooldown bars
	cards.master.args.setMaster.func()
	local m = S:Master()
	expectEq(m.key .. '|' .. m.classToken .. '|' .. m.spec .. '|' .. m.role, KEY .. '|DRUID|Balance|DPS', 'identity: character, class, spec, role')
	expectEq(m.version .. '|' .. m.schema, '1.5.0|' .. S.SCHEMA, 'BANZAI version and configuration schema')
	local keys = {}
	for k in pairs(m.config) do keys[#keys + 1] = k end
	table.sort(keys)
	expectEq(table.concat(keys, ','), 'flavor,fonts,layout,settings', 'only Banzai-owned parts: client flavor, settings, fonts, unit layout')
	expectEq(HasKey(m.config, GAMEPLAY_KEYS), nil, 'no gameplay data in the master setup')
	expectEq(m.config.settings.cdTracked, nil, 'the tracked cooldowns (class abilities) stay with the Druid')
	expect(not string.find(T.Serialize(m.config), 'DRUID', 1, true) and not string.find(T.Serialize(m.config), '22812', 1, true), 'no Druid class key or spell in the setup')
	local text = T.Serialize(m.config)
	for _, word in ipairs({ 'Balance', 'Feral', 'Druid', 'Restoration' }) do expect(not string.find(text, word, 1, true), 'no Druid identity in the setup (' .. word .. ')') end
	local card = HK_Plain(cards.master.args.info.name())
	for _, needle in ipairs({ KEY, 'Druid', 'BALANCE', 'DPS', 'BANZAI 1.5.0', 'SCHEMA ' .. S.SCHEMA, '#' }) do expect(string.find(card, needle, 1, true), 'master card: ' .. needle) end
	expectEq(cards.master.args.setMaster.hidden(), true, 'set')
	expectEq(cards.master.args.capture.hidden(), false, 'CAPTURE MASTER NOW on the master')
end)

test('1.0.1 sync: an unsynced alt stays untouched until Darren clicks - no automatic rollout; the backup and component state are shown', function()
	local S = ns.Sync
	LogIn(ROGUE, 'Darrensrogue', 'ROGUE', 1)
	HK_SPECINFO = ROGUE_SPECS
	HK_SETPROFILE, HK_POPUPS, HK_GAMEPLAY_CALLS = {}, {}, {}
	local before = T.Serialize(CompatStub.Export()) -- its settings (the role bookkeeping table may be created empty by a read)
	ns.Restore:OnAddonLoaded()
	ns.Restore:OnLogin()
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	HK_Fire('PLAYER_LOGOUT')
	expectEq(S:State(), 'NOT_SYNCED', 'THIS CHARACTER IS NOT SYNCED')
	expectEq(#HK_SETPROFILE, 0, 'no ElvUI profile switched by itself')
	expectEq(E.data:GetCurrentProfile(), 'Default', 'its own ElvUI profile')
	expectEq(BushidoPrivateRestoreDB.characters[ROGUE], nil, 'nothing recorded for it')
	expectEq(T.Serialize(CompatStub.Export()), before, 'its BANZAI settings untouched')
	local cards = SyncCards()
	expect(string.find(HK_Plain(cards.this.args.state.name()), 'THIS CHARACTER IS NOT SYNCED', 1, true), 'shown')
	expect(string.find(HK_Plain(cards.this.args.backup.name()), 'PRE-BANZAI BACKUP: not taken yet', 1, true), 'no backup yet, said so')
	expectEq(cards.this.args.apply.hidden(), false, 'APPLY BANZAI offered')
	expectEq(cards.this.args.restore.hidden(), true, 'nothing to restore')
	local status = HK_Plain(cards.synced.args.list.name())
	for _, needle in ipairs({ 'MASTER   ' .. KEY, 'MASTER BANZAI VERSION   1.5.0', 'THIS CHARACTER   ' .. ROGUE, 'CLASS   ROGUE', 'SPEC   ASSASSINATION', 'ROLE   DPS', 'APPLIED CONFIGURATION   none', 'SYNC STATE   THIS CHARACTER IS NOT SYNCED' }) do
		expect(string.find(status, needle, 1, true), 'sync status: ' .. needle)
	end
	local diag = HK_Plain(cards.components.args.list.name())
	for _, needle in ipairs({ 'ElvUI   READY', 'Banzai Art   READY', 'Eltruism   READY', 'mMediaTag   READY', 'Jiberish Icons   READY', 'JiberishMedia   READY', 'Details   READY', 'Kaliel\'s Tracker   SKIPPED', 'MinimapButtonButton   SKIPPED' }) do
		expect(string.find(diag, needle, 1, true), 'diagnostics: ' .. needle)
	end
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no gameplay call')
end)

test('1.0.1 sync: a failed pre-Banzai backup stops APPLY BANZAI - nothing applied, nothing half-made, a clear error', function()
	local S = ns.Sync
	local export = CompatStub.Export
	CompatStub.Export = function() return nil end -- the alt's BANZAI settings cannot be read
	HK_SETPROFILE, HK_POPUPS = {}, {}
	local ok, message = S:Apply()
	CompatStub.Export = export
	expectEq(ok, false, 'not applied')
	expect(string.find(message, 'PRE-BANZAI BACKUP FAILED', 1, true) and string.find(message, 'Banzai was NOT applied', 1, true), 'clear error: ' .. tostring(message))
	expectEq(S:State(), 'NOT_SYNCED', 'still not synced')
	expectEq(#HK_SETPROFILE, 0, 'no profile switched')
	expectEq(#HK_POPUPS, 0, 'no reload asked')
	local r = BushidoPrivateRestoreDB.characters[ROGUE]
	expect(not (r and (r.previous or r.syncBackup or r.applied)), 'no half-made backup or record left')
	expect(string.find(HK_Plain(SyncCards().this.args.backup.name()), 'PRE-BANZAI BACKUP FAILED', 1, true), 'the error on the card')
	-- a required component missing blocks it the same way
	HK_LOADED.BushidoPrivateCompat = nil
	ok, message = S:Apply()
	HK_LOADED.BushidoPrivateCompat = true
	expectEq(ok, false, 'Banzai Art missing: not applied')
	expect(string.find(message, 'Banzai Art MISSING', 1, true), 'says which component: ' .. tostring(message))
	expectEq(S:State(), 'NOT_SYNCED', 'still not synced')
end)

test('1.0.1 sync: APPLY BANZAI on a DPS alt - backup first, its own class / spec / DPS layout, gameplay untouched, then BANZAI SYNCED', function()
	local S = ns.Sync
	local cards = SyncCards()
	local plan = HK_Plain(cards.this.args.apply.confirm())
	for _, needle in ipairs({ 'BANZAI WILL APPLY:', '- role layout (DPS for Assassination)', 'BANZAI WILL NOT CHANGE:', '- action assignments', '- keybinds', '- talents' }) do expect(string.find(plan, needle, 1, true), 'summary: ' .. needle) end
	local seen = {}
	local apply = ns.Restore.Apply
	ns.Restore.Apply = function(self, reason, options)
		local r = BushidoPrivateRestoreDB.characters[ROGUE]
		seen.backup = r and r.previous and r.previous.time and r.syncBackup and r.syncBackup.settings and true or false
		seen.profile = E.data:GetCurrentProfile()
		return apply(self, reason, options)
	end
	HK_GAMEPLAY_CALLS, HK_POPUPS = {}, {}
	compat.cdTracked = { ROGUE = { [5277] = false } } -- the rogue's own cooldown-bar choice
	local history = Details.mythic_plus_log[1]
	cards.this.args.apply.func()
	ns.Restore.Apply = apply
	expectEq(seen.backup, true, 'the backup was complete before Banzai applied anything')
	expectEq(seen.profile, 'Default', '(and nothing had changed yet)')
	expectEq(S:State(), 'SYNCED', 'BANZAI SYNCED')
	expectEq(E.data:GetCurrentProfile(), NAME, 'on the Banzai profile')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload asked (the ElvUI profile switched)')
	expect(string.find(HK_Plain(cards.this.args.backup.name()), 'PRE-BANZAI BACKUP: READY', 1, true), 'PRE-BANZAI BACKUP: READY')
	expectEq(ns.Roles:Active(), 'DPS', 'DPS alt: the DPS layout')
	expectEq(profile().movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.DPS.ElvUF_PartyMover, 'DPS party place')
	-- its own identity: nothing of the Druid
	local who = S:Identity()
	expectEq(who.classToken .. '|' .. who.spec .. '|' .. who.role, 'ROGUE|Assassination|DPS', 'its own class, spec and role')
	expectEq(texts('player')['b-Spec'].text_format, T.SPEC_TAG, 'spec shown by the live tag (the rogue\'s own), not a copied name')
	expectEq(profile().mMediaTag.portraits.misc.class_icon, 'fabledclass', 'Fabled Class style: the art follows the unit\'s own class')
	expectEq(HasKey(compatDB(), { 'classtoken', 'spec', 'specid' }), nil, 'no class / spec identity in its BANZAI settings')
	expect(compat.cdTracked.ROGUE[5277] == false and compat.cdTracked.DRUID == nil, 'its own tracked cooldowns kept, none of the Druid\'s')
	local status = HK_Plain(cards.synced.args.list.name())
	for _, needle in ipairs({ 'MASTER   ' .. KEY, 'CLASS   ROGUE', 'SPEC   ASSASSINATION', 'ROLE   DPS', 'APPLIED CONFIGURATION   BANZAI 1.5.0, schema ' .. S.SCHEMA, 'SYNC STATE   BANZAI SYNCED' }) do
		expect(string.find(status, needle, 1, true), 'sync status: ' .. needle)
	end
	-- gameplay
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no action, keybind, macro, talent, loadout, spell or equipment call')
	expectEq(Details.mythic_plus_log[1], history, 'Details history untouched')
	-- idempotent: the same setup again changes nothing
	local r = BushidoPrivateRestoreDB.characters[ROGUE]
	local backupTime, previous, party, shared = r.syncBackup.time, T.Serialize(r.previous), profile().movers.ElvUF_PartyMover, profile()
	local windows = DetailsWindows()
	HK_POPUPS = {}
	expect(S:Apply(), 'apply again')
	expect(S:Apply(), 'and again')
	expectEq((DetailsWindows()), windows, 'no Details window added')
	expectEq(r.syncBackup.time, backupTime, 'no second snapshot')
	expectEq(T.Serialize(r.previous), previous, 'the pre-Banzai record kept')
	expectEq(profile().movers.ElvUF_PartyMover, party, 'role layout not moved')
	expectEq(profile(), shared, 'the same profile, not rebuilt')
	expectEq(#HK_POPUPS, 0, 'nothing changed: no reload')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'still no gameplay call')
end)

test('1.0.1 sync: a HEALER alt gets the HEALER layout; a spec change switches layouts by itself, after combat when it happens in combat', function()
	local S = ns.Sync
	LogIn(PRIEST, 'Darrenspriest', 'PRIEST', 2) -- Holy
	HK_SPECINFO = PRIEST_SPECS
	HK_GAMEPLAY_CALLS = {}
	expect(S:Apply(), 'applied')
	expectEq(S:State(), 'SYNCED', 'synced')
	expectEq(ns.Roles:Active(), 'HEALER', 'Holy: HEALER layout')
	expectEq(profile().movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.HEALER.ElvUF_PartyMover, 'the HEALER row')
	-- spec change: Shadow (DPS) and back
	HK_SPEC_INDEX = 3
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(ns.Roles:Active(), 'DPS', 'Shadow: DPS layout, no frame moved by hand')
	expectEq(profile().movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.DPS.ElvUF_PartyMover, 'DPS party place')
	HK_IN_COMBAT = true
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(profile().movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.DPS.ElvUF_PartyMover, 'in combat nothing moves')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(ns.Roles:Active(), 'HEALER', 'after combat: HEALER again')
	expectEq(profile().movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.HEALER.ElvUF_PartyMover, 'the HEALER row')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'a spec change never touches gameplay data (Banzai never changes the spec)')
end)

test('1.0.1 sync: master changes -> UPDATE AVAILABLE (nothing rewritten); a version mismatch is shown; optional components skipped, a required one blocks', function()
	local S = ns.Sync
	LogIn(KEY, 'Darrensdrood', 'DRUID', 1)
	HK_SPECINFO = DRUID_SPECS
	ns.Restore:OnAddonLoaded()
	compat.glassOpacity = 0.44
	S:Capture()
	local revision = S:Master().revision
	LogIn(PRIEST, 'Darrenspriest', 'PRIEST', 2)
	HK_SPECINFO = PRIEST_SPECS
	ns.Restore:OnAddonLoaded()
	ns.Restore:OnLogin()
	expectEq(S:State(), 'UPDATE', 'BANZAI UPDATE AVAILABLE')
	expect(compat.glassOpacity ~= 0.44, 'nothing rewritten by itself')
	local cards = SyncCards()
	expectEq(cards.this.args.update.hidden(), false, 'UPDATE CHARACTER offered')
	-- the master was captured with another BANZAI version: shown, the update still works
	S:Master().version = '1.0.0'
	expect(string.find(HK_Plain(cards.version.args.text.name()), 'Version drift', 1, true), 'version drift shown')
	-- optional Details missing: skipped honestly
	local details = Details
	Details, HK_LOADED.Details = nil, nil
	expect(string.find(HK_Plain(cards.components.args.list.name()), 'Details   SKIPPED', 1, true), 'Details SKIPPED')
	HK_GAMEPLAY_CALLS = {}
	expect(S:Update(), 'update without Details')
	expectEq(S:State(), 'SYNCED', 'synced again')
	expectEq(compat.glassOpacity, 0.44, 'the master\'s change taken over')
	expectEq(BushidoPrivateRestoreDB.characters[PRIEST].sync.revision, revision, 'the master\'s configuration')
	Details, HK_LOADED.Details = details, true
	-- a required component missing: nothing updated
	LogIn(KEY, 'Darrensdrood', 'DRUID', 1)
	HK_SPECINFO = DRUID_SPECS
	compat.glassOpacity = 0.5
	S:Capture()
	LogIn(PRIEST, 'Darrenspriest', 'PRIEST', 2)
	HK_SPECINFO = PRIEST_SPECS
	HK_LOADED.ElvUI = nil
	local ok, message = S:Update()
	HK_LOADED.ElvUI = true
	expectEq(ok, false, 'ElvUI missing: no update')
	expect(string.find(message, 'ElvUI MISSING', 1, true), 'says so: ' .. tostring(message))
	expectEq(compat.glassOpacity, 0.44, 'nothing changed')
	expectEq(S:State(), 'UPDATE', 'the update still waits')
	expect(S:Update(), 'then the update')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no gameplay call')
end)

test('1.0.1 sync: RESTORE PRE-BANZAI on the alt - its own setup back, NOT SYNCED again, the master untouched', function()
	local S = ns.Sync
	local cards = SyncCards()
	expectEq(cards.this.args.restore.hidden(), false, 'RESTORE PRE-BANZAI offered')
	HK_GAMEPLAY_CALLS = {}
	cards.this.args.restore.func()
	expectEq(S:State(), 'NOT_SYNCED', 'THIS CHARACTER IS NOT SYNCED')
	expectEq(E.data:GetCurrentProfile(), 'Default', 'its own ElvUI profile back')
	expect(string.find(HK_Plain(cards.this.args.backup.name()), 'PRE-BANZAI BACKUP: not taken yet', 1, true), 'its backup used up')
	expectEq(S:Master().key, KEY, 'the master is untouched')
	expect(S:Master().config, 'its setup too')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no gameplay call on restore')
	-- the rogue alt stays synced
	LogIn(ROGUE, 'Darrensrogue', 'ROGUE', 1)
	HK_SPECINFO = ROGUE_SPECS
	expect(S:State() == 'SYNCED' or S:State() == 'UPDATE', 'the other alt still on Banzai')
	LogIn(KEY, 'Darrensdrood', 'DRUID', 1)
	HK_SPECINFO = DRUID_SPECS
	HK_SPEC_INDEX = 2
	expectEq(S:State(), 'MASTER', 'Darrensdrood: still the master')
end)

---------------------------------------------------------------------------
-- 1.0.1 review fixes
---------------------------------------------------------------------------
local MAGE, PALA, LOCK = 'Darrensmage - Stormrage', 'Darrenspala - Stormrage', 'Darrenslock - Stormrage'
local MAGE_SPECS = { [1] = { 62, 'Arcane', '', 135932, 'DAMAGER' }, [2] = { 63, 'Fire', '', 135810, 'DAMAGER' }, [3] = { 64, 'Frost', '', 135846, 'DAMAGER' } }
local PALA_SPECS = { [1] = { 65, 'Holy', '', 135920, 'HEALER' }, [2] = { 66, 'Protection', '', 236264, 'TANK' }, [3] = { 70, 'Retribution', '', 135873, 'DAMAGER' } }
local function AsDruid() LogIn(KEY, 'Darrensdrood', 'DRUID', 1) HK_SPECINFO = DRUID_SPECS end
local function AsRogue() LogIn(ROGUE, 'Darrensrogue', 'ROGUE', 1) HK_SPECINFO = ROGUE_SPECS end

test('1.0.1 review: fonts and the unit layout are each character\'s own - a master change reaches a synced alt only with UPDATE CHARACTER, and an alt\'s change never reaches the master', function()
	local S, R = ns.Sync, ns.Restore
	AsRogue()
	expect(S:Update(), 'the rogue on the master\'s current setup')
	expectEq(S:State(), 'SYNCED', 'synced')
	local rogueHeight = R:Own().layout.unitHeight or 0
	ns.Restore:OnAddonLoaded()
	local rogueMover = profile().movers.ElvUF_PlayerMover
	-- the master moves its Player / Target and takes another font
	AsDruid()
	ns.Restore:OnAddonLoaded()
	R:SetUnitLayout(60, 40)
	local font = R:Own().fonts.small
	expect(S:Capture(), 'captured')
	expectEq(R:Own().layout.unitHeight, 60, 'the master\'s own height')
	-- the rogue logs in: nothing of it moved by itself
	AsRogue()
	HK_POPUPS = {}
	ns.Restore:OnAddonLoaded()
	expectEq(R:Own().layout.unitHeight or 0, rogueHeight, 'the rogue keeps its own height')
	expectEq(R:LayerOptions().unitHeight, rogueHeight, 'its layer is written with its own height')
	expectEq(profile().movers.ElvUF_PlayerMover, rogueMover, 'its Player frame did not move')
	expectEq(S:State(), 'UPDATE', 'BANZAI UPDATE AVAILABLE instead')
	-- UPDATE CHARACTER takes it over
	expect(S:Update(), 'update')
	expectEq(R:Own().layout.unitHeight, 60, 'now the master\'s height')
	expectEq(R:Own().layout.unitSpread, 40, 'and spread')
	expectEq(R:Own().fonts.small, font, 'and fonts')
	expect(profile().movers.ElvUF_PlayerMover ~= rogueMover, 'its Player frame moves with it')
	-- the rogue's own change stays with the rogue
	R:SetUnitLayout(-10, nil)
	AsDruid()
	expectEq(R:Own().layout.unitHeight, 60, 'the master is unchanged')
	R:SetUnitLayout(0, 0)
	S:Capture()
end)

test('1.0.1 review: a master restored and set again keeps counting - characters synced to it see BANZAI UPDATE AVAILABLE', function()
	local S = ns.Sync
	AsRogue()
	expect(S:Update(), 'rogue synced')
	local synced = BushidoPrivateRestoreDB.characters[ROGUE].sync.revision
	AsDruid()
	expectEq(S:State(), 'MASTER', 'the master')
	expect(string.find(HK_Plain(SyncCards().this.args.restore.confirm()), 'it stops being the master', 1, true), 'the restore says what happens to the master')
	expect(S:RestoreCharacter(), 'master restored')
	expectEq(S:Master(), nil, 'no master any more')
	expectEq(S:State(), 'NOT_SYNCED', 'THIS CHARACTER IS NOT SYNCED')
	expect(S:Apply(), 'Banzai again')
	expect(SyncCards().master.args.setMaster.hidden() == false, 'SET AS BANZAI MASTER offered')
	expect(S:SetMaster(), 'set as master again')
	expect(S:Master().revision > synced, 'the new configuration counts on from #' .. synced .. ': #' .. S:Master().revision)
	AsRogue()
	expectEq(S:State(), 'UPDATE', 'the rogue sees the update')
	expect(S:Update(), 'update')
	expectEq(S:State(), 'SYNCED', 'synced')
end)

test('1.0.1 review: the master never publishes a setup when Banzai Art is not running or its settings are empty', function()
	local S = ns.Sync
	AsDruid()
	local revision = S:Master().revision
	compat.glassOpacity = 0.61
	HK_LOADED.BushidoPrivateCompat = nil
	expectEq(S:Capture(), false, 'Banzai Art missing: nothing captured')
	HK_LOADED.BushidoPrivateCompat = true
	local export = CompatStub.Export
	CompatStub.Export = function() return {} end
	expectEq(S:Capture(), false, 'empty settings: nothing captured')
	CompatStub.Export = export
	expectEq(S:Master().revision, revision, 'the revision stays')
	expect(S:Capture(), 'then it captures')
	expectEq(S:Master().revision, revision + 1, 'one new revision')
end)

test('1.0.1 review: UPDATE CHARACTER without Kaliel\'s Tracker asks for no reload; an unusable old backup is taken again; HOME / slash restore end the sync state', function()
	local S, R = ns.Sync, ns.Restore
	-- Kaliel's Tracker not installed
	local kt = KalielsTrackerDB
	KalielsTrackerDB, HK_LOADED['!KalielsTracker'] = nil, nil
	AsRogue()
	local previous = BushidoPrivateRestoreDB.characters[ROGUE].previous
	local visibility = previous.trackerVisibility
	previous.trackerVisibility = nil -- (as on a character that had no Kaliel's Tracker when Banzai came)
	ns.Restore:OnAddonLoaded()
	S:Update()
	HK_POPUPS = {}
	expect(S:Update(), 'update')
	expect(S:Update(), 'again')
	expectEq(#HK_POPUPS, 0, 'nothing changed: no reload asked')
	expectEq(previous.trackerVisibility, nil, '(nothing recorded for a tracker that is not there)')
	KalielsTrackerDB, HK_LOADED['!KalielsTracker'] = kt, true
	previous.trackerVisibility = visibility
	-- a backup record without settings (left by an older build) is taken again
	BushidoPrivateRestoreDB.characters[MAGE] = { syncBackup = { time = '2026-10-27 00:00:00' } }
	LogIn(MAGE, 'Darrensmage', 'MAGE', 3)
	HK_SPECINFO = MAGE_SPECS
	local ok, why = S:Apply()
	expect(ok, 'applied: ' .. tostring(why))
	expectEq(type(BushidoPrivateRestoreDB.characters[MAGE].syncBackup.settings), 'table', 'a real backup now')
	-- /banzai restore: the sync state goes with it
	SlashCmdList.BANZAI('restore')
	expectEq(S:State(), 'NOT_SYNCED', 'not synced')
	expectEq(BushidoPrivateRestoreDB.characters[MAGE].sync, nil, 'no sync record left')
	expect(string.find(HK_Plain(SyncCards().synced.args.list.name()), 'APPLIED CONFIGURATION   none', 1, true), 'SYNC STATUS: none applied')
	local backup = E.Options.args.banzai.args.backup.args
	expectEq(backup.preBanzai.args.restore.disabled(), true, 'BACKUP & RESTORE buttons off for a character not on Banzai')
	expectEq(backup.character.args.restoreCharacter.disabled(), true, '(both)')
	-- HOME > Apply / repair on a character not on Banzai: the summary first, a failure said in chat
	local home = E.Options.args.banzai.args.home.args.actions.args.apply
	expect(string.find(HK_Plain(home.confirm()), 'BANZAI WILL NOT CHANGE:', 1, true), 'HOME shows the APPLY BANZAI summary')
	BushidoPrivateRestoreDB.characters[MAGE].syncBackup = nil
	local export = CompatStub.Export
	CompatStub.Export = function() return nil end
	HK_PRINTS = {}
	home.func()
	CompatStub.Export = export
	expect(string.find(table.concat(HK_PRINTS, '\n'), 'PRE-BANZAI BACKUP FAILED', 1, true), 'the failure in chat')
	expectEq(S:State(), 'NOT_SYNCED', 'nothing applied')
end)

test('1.0.1 review: a character on Banzai from before Character Sync keeps its own setup for RESTORE PRE-BANZAI; a Lua error during APPLY leaves nothing half-made', function()
	local S, R = ns.Sync, ns.Restore
	-- a 1.0.0-era alt: on Banzai, no sync backup
	LogIn(PALA, 'Darrenspala', 'PALADIN', 3)
	HK_SPECINFO = PALA_SPECS
	compat.glassOpacity = 0.33
	expect(R:Apply('manual', { reuse = true }), 'applied the 1.0.0 way')
	expectEq(BushidoPrivateRestoreDB.characters[PALA].syncBackup, nil, '(no sync backup)')
	expectEq(S:State(), 'UPDATE', 'the master\'s setup is offered')
	expect(S:Update(), 'update')
	expectEq(BushidoPrivateRestoreDB.characters[PALA].syncBackup.settings.glassOpacity, 0.33, 'its own settings saved first')
	expectEq(compat.glassOpacity, S:Master().config.settings.glassOpacity, 'the master\'s now')
	expect(S:RestoreCharacter(), 'restore')
	expectEq(compat.glassOpacity, 0.33, 'its own settings back')
	-- an error inside the apply
	LogIn(LOCK, 'Darrenslock', 'WARLOCK', 1)
	compat.glassOpacity = 0.27
	local apply = R.Apply
	R.Apply = function() error('boom') end
	local ok, message = S:Apply()
	R.Apply = apply
	expectEq(ok, false, 'not applied')
	expect(string.find(message, 'nothing was marked as synced', 1, true), 'said: ' .. tostring(message))
	expectEq(compat.glassOpacity, 0.27, 'its own settings back (the master\'s were taken in first)')
	expectEq(S:State(), 'NOT_SYNCED', 'not synced')
	expectEq(BushidoPrivateRestoreDB.characters[LOCK].sync, nil, 'no sync record')
	expect(string.find(HK_Plain(SyncCards().this.args.backup.name()), 'Banzai could not be applied', 1, true), 'the error on the card')
	AsDruid()
end)

---------------------------------------------------------------------------
-- 1.0.2: one objective tracker on screen (Blizzard's parked while the Banzai tracker shows)
---------------------------------------------------------------------------
local MONK, VOKER = 'Darrensmonky - Stormrage', 'Darrensvoker - Stormrage'
local MONK_SPECS = { [1] = { 268, 'Brewmaster', '', 608951, 'TANK' }, [2] = { 270, 'Mistweaver', '', 608952, 'HEALER' }, [3] = { 269, 'Windwalker', '', 608953, 'DAMAGER' } }
local OTF = ObjectiveTrackerFrame
local function Parked() return OTF:GetParent() == ns.Restore.TRACKER_PARK end
local function AsMonk(spec) LogIn(MONK, 'Darrensmonky', 'MONK', spec or 3) HK_SPECINFO = MONK_SPECS end
local function Changes() return OTF.parentChanges or 0 end

test('1.0.2 tracker: an unsynced character keeps Blizzard\'s objective tracker exactly as it is - nothing parked, nothing moved', function()
	AsMonk()
	ns.Restore:TrackerOwnership('test') -- (whatever an earlier test left: this character is not on Banzai)
	expectEq(OTF:GetParent(), UIParent, 'Blizzard\'s tracker on its own parent')
	OTF.collapsed = true -- the Monk's own choice before Banzai
	local changes = Changes()
	HK_GAMEPLAY_CALLS = {}
	ns.Restore:OnAddonLoaded()
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_Fire('EDIT_MODE_LAYOUTS_UPDATED')
	HK_Fire('ADDON_LOADED', 'Blizzard_ObjectiveTracker')
	ns.Restore:OnLogin()
	expectEq(ns.Sync:State(), 'NOT_SYNCED', 'not synced')
	expectEq(OTF:GetParent(), UIParent, 'still Blizzard\'s')
	expectEq(Changes(), changes, 'never touched')
	expectEq(OTF:IsCollapsed(), true, 'its collapsed state untouched')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no gameplay call')
end)

test('1.0.2 tracker: APPLY BANZAI with the Banzai tracker on parks Blizzard\'s tracker once - its state from before Banzai in the pre-Banzai record; DPS / HEALER layouts as before', function()
	local S = ns.Sync
	AsMonk(3) -- Windwalker
	HK_GAMEPLAY_CALLS = {}
	local seen
	local apply = ns.Restore.Apply
	ns.Restore.Apply = function(self, ...)
		local r = BushidoPrivateRestoreDB.characters[MONK]
		seen = r and r.previous and T.DeepCopy(r.previous.blizzardTracker)
		return apply(self, ...)
	end
	local ok, why = S:Apply()
	ns.Restore.Apply = apply
	expect(ok, 'applied: ' .. tostring(why))
	expectEq(seen and (seen.parent .. '|' .. tostring(seen.shown) .. '|' .. tostring(seen.collapsed)), 'UIParent|true|true', 'the backup had Blizzard\'s tracker (parent, shown, collapsed) before Banzai changed anything')
	expectEq(S:State(), 'SYNCED', 'BANZAI SYNCED')
	expect(Parked(), 'Blizzard\'s tracker parked: only the Banzai tracker on screen')
	expectEq(OTF:IsShown(), true, '(not hidden, hooked or unregistered: it keeps working unseen)')
	expectEq(OTF:IsCollapsed(), true, 'its collapsed state untouched')
	expectEq(ns.Roles:Active(), 'DPS', 'Windwalker: DPS layout as before')
	expectEq(profile().movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.DPS.ElvUF_PartyMover, 'DPS party place')
	-- idempotent
	local changes, record = Changes(), T.Serialize(BushidoPrivateRestoreDB.characters[MONK].previous.blizzardTracker)
	expect(S:Apply(), 'apply again')
	expect(S:Apply(), 'and again')
	HK_Fire('PLAYER_ENTERING_WORLD', false, false)
	expectEq(Changes(), changes, 'nothing moved again')
	expectEq(T.Serialize(BushidoPrivateRestoreDB.characters[MONK].previous.blizzardTracker), record, 'the original record kept')
	-- a healer spec: HEALER layout, the tracker stays parked
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	expectEq(ns.Roles:Active(), 'HEALER', 'Mistweaver: HEALER layout as before')
	expectEq(profile().movers.ElvUF_PartyMover, T.ROLE_LAYOUTS.HEALER.ElvUF_PartyMover, 'the HEALER row')
	expect(Parked() and Changes() == changes, 'the tracker untouched by the spec change')
	HK_SPEC_INDEX = 3
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	HK_PRINTS = {}
	ns.Restore:Status()
	expect(string.find(table.concat(HK_PRINTS, '\n'), 'Blizzard\'s tracker: parked while the Banzai tracker shows', 1, true), '/banzai status says so')
	expect(string.find(table.concat(HK_PRINTS, '\n'), 'BANZAI 1.5.0', 1, true), '/banzai status: 1.5.0')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no gameplay call')
end)

test('1.0.2 tracker: a synced character keeps Banzai-only ownership - at every login, after UPDATE CHARACTER, after Edit Mode or ElvUI put it back, after combat', function()
	local S = ns.Sync
	-- a login: the game builds Blizzard's tracker on its own parent again
	OTF:SetParent(UIParent)
	HK_Fire('PLAYER_ENTERING_WORLD', false, true)
	HK_RunTimers() -- (1.0.3: one frame later)
	expect(Parked(), 'parked at login')
	-- a character synced before 1.0.2 (no record of the tracker): recorded at its first login, then parked
	local previous = BushidoPrivateRestoreDB.characters[MONK].previous
	local original = previous.blizzardTracker
	previous.blizzardTracker = nil
	OTF:SetParent(UIParent)
	ns.Restore:OnLogin()
	expect(Parked(), 'parked')
	expectEq(previous.blizzardTracker and previous.blizzardTracker.parent, 'UIParent', 'its state from before Banzai recorded first')
	previous.blizzardTracker = original
	-- UPDATE CHARACTER
	AsDruid()
	compat.glassOpacity = 0.47
	expect(S:Capture(), 'the master changed')
	AsMonk(3)
	OTF:SetParent(UIParent)
	HK_Fire('PLAYER_ENTERING_WORLD', false, true)
	HK_RunTimers()
	expectEq(S:State(), 'UPDATE', 'BANZAI UPDATE AVAILABLE')
	expect(Parked(), 'parked before the update')
	local changes = Changes()
	expect(S:Update(), 'UPDATE CHARACTER')
	expect(Parked() and Changes() == changes, 'still parked, not moved again')
	expectEq(S:State(), 'SYNCED', 'synced')
	-- Edit Mode (or ElvUI's own auto-hide) puts it back on screen
	OTF:SetParent(UIParent)
	HK_Fire('EDIT_MODE_LAYOUTS_UPDATED')
	HK_RunTimers()
	expect(Parked(), 'parked again after Edit Mode')
	-- in combat: waits for the end of combat
	OTF:SetParent(UIParent)
	HK_IN_COMBAT = true
	HK_Fire('PLAYER_ENTERING_WORLD', false, false)
	HK_RunTimers()
	expectEq(OTF:GetParent(), UIParent, 'nothing done in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	HK_RunTimers()
	expect(Parked(), 'parked after combat')
	changes = Changes()
	HK_Fire('PLAYER_REGEN_ENABLED')
	HK_RunTimers()
	expectEq(Changes(), changes, 'nothing more after later combats')
	-- Blizzard's tracker loading late
	OTF:SetParent(UIParent)
	HK_Fire('ADDON_LOADED', 'Blizzard_ObjectiveTracker')
	HK_RunTimers()
	expect(Parked(), 'parked once Blizzard\'s tracker loads')
end)

test('1.0.2 tracker: the Banzai tracker switched off gives Blizzard\'s tracker back (never no tracker); switched on parks it again', function()
	AsMonk(3)
	expect(Parked(), 'parked while the Banzai tracker is on')
	ns.Restore:SetTracker(false)
	expectEq(compat.tracker, false, 'Banzai tracker off')
	expectEq(OTF:GetParent(), UIParent, 'Blizzard\'s tracker back on its parent: one tracker on screen')
	local changes = Changes()
	ns.Restore:TrackerOwnership('again')
	HK_Fire('PLAYER_ENTERING_WORLD', false, true)
	HK_RunTimers()
	expectEq(Changes(), changes, 'left alone while the Banzai tracker is off')
	ns.Restore:SetTracker(true)
	expect(Parked(), 'Banzai tracker on: Blizzard\'s parked again')
end)

test('1.0.2 tracker: RESTORE PRE-BANZAI puts Blizzard\'s tracker back exactly as it was before Banzai; a failed sync never leaves it parked', function()
	local S = ns.Sync
	AsMonk(3)
	-- Darren expands Blizzard's tracker while the Banzai tracker is off, then turns it on again
	ns.Restore:SetTracker(false)
	OTF:SetCollapsed(false)
	ns.Restore:SetTracker(true)
	expect(Parked(), 'parked')
	HK_GAMEPLAY_CALLS = {}
	expect(S:RestoreCharacter(), 'RESTORE PRE-BANZAI')
	expectEq(S:State(), 'NOT_SYNCED', 'THIS CHARACTER IS NOT SYNCED')
	expectEq(OTF:GetParent(), UIParent, 'Blizzard\'s tracker on its own parent again')
	expectEq(OTF:IsCollapsed(), true, 'collapsed again, as it was before Banzai')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no gameplay call')
	local changes = Changes()
	HK_Fire('PLAYER_ENTERING_WORLD', false, true)
	HK_RunTimers()
	ns.Restore:OnLogin()
	expectEq(Changes(), changes, 'not touched again after the restore')
	-- a sync that fails (with a parked tracker left from earlier in the session)
	LogIn(VOKER, 'Darrensvoker', 'EVOKER', 1)
	OTF.parent = ns.Restore.TRACKER_PARK
	local apply = ns.Restore.Apply
	ns.Restore.Apply = function() error('boom') end
	local ok = S:Apply()
	ns.Restore.Apply = apply
	expectEq(ok, false, 'not applied')
	expectEq(OTF:GetParent(), UIParent, 'Blizzard\'s tracker not left parked (no Banzai tracker on this character)')
	expectEq(S:State(), 'NOT_SYNCED', 'not synced')
	AsDruid()
end)

---------------------------------------------------------------------------
-- 1.0.3: the parking holds (ownership reasserted one frame after the events
-- that put Blizzard's tracker back: Edit Mode layout applies, Eltruism's
-- re-anchoring at loading screens, a spec change, the tracker built late)
---------------------------------------------------------------------------
HK_RunTimers() -- (what earlier tests left queued)
-- Eltruism (and Edit Mode) as they run in the game: handlers registered after Banzai's, so they run
-- after Banzai's for the same event, and they put Blizzard's tracker back on a visible parent
local RIGHT_CONTAINER = CreateFrame('Frame', 'RightManagedFrameContainer', UIParent)
local eltruism = CreateFrame('Frame')
eltruism.reparents = 0
for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'FIRST_FRAME_RENDERED', 'EDIT_MODE_LAYOUTS_UPDATED' }) do eltruism:RegisterEvent(event) end
eltruism:SetScript('OnEvent', function(self, event)
	if event == 'EDIT_MODE_LAYOUTS_UPDATED' then OTF:SetParent(RIGHT_CONTAINER) end -- Edit Mode: ApplySystemAnchor -> its managed container
	OTF:SetParent(UIParent) -- Eltruism: ObjectiveTrackerFrame:BreakFromFrameManager() -> UIParent
	self.reparents = self.reparents + 1
end)
local function Counting(fn)
	local calls, own = 0, ns.Restore.TrackerOwnership
	ns.Restore.TrackerOwnership = function(self, ...) calls = calls + 1 return own(self, ...) end
	fn()
	ns.Restore.TrackerOwnership = own
	return calls
end

test('1.0.3 tracker: login - Eltruism re-anchors Blizzard\'s tracker after Banzai parked it at PLAYER_ENTERING_WORLD (what 1.0.2 lost); the check queued for the next frame wins, on a synced character and on the master', function()
	local S = ns.Sync
	AsMonk(3)
	expect(S:Apply(), 'the Monk synced again')
	expect(Parked(), 'parked at APPLY BANZAI')
	OTF:SetParent(UIParent) -- the game built it on its own parent at login
	local reparents = eltruism.reparents
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	expectEq(eltruism.reparents, reparents + 1, 'Eltruism ran after Banzai')
	expectEq(OTF:GetParent(), UIParent, 'and won the event itself (1.0.2 stopped here: Blizzard\'s tracker on screen)')
	expectEq(ns.Restore.trackerQueued, 'PLAYER_ENTERING_WORLD', 'one check queued for the next frame')
	HK_RunTimers()
	expect(Parked(), 'parked one frame later: only the Banzai tracker on screen')
	expectEq(ns.Restore.trackerQueued, nil, 'nothing left queued')
	expectEq(#HK_HOOKS, 0, 'no secure hook anywhere')
	-- the master
	AsDruid()
	expectEq(S:State(), 'MASTER', 'the master')
	OTF:SetParent(UIParent)
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	expectEq(OTF:GetParent(), UIParent, 'Eltruism won the event')
	HK_RunTimers()
	expect(Parked(), 'parked on the master one frame later')
end)

test('1.0.3 tracker: a loading screen and FIRST_FRAME_RENDERED (Eltruism re-anchors at both) - one queued check for the whole burst, nothing when already parked', function()
	AsMonk(3)
	expect(Parked(), 'parked')
	OTF:SetParent(UIParent)
	local calls = Counting(function()
		HK_Fire('PLAYER_ENTERING_WORLD', false, false)
		HK_Fire('FIRST_FRAME_RENDERED')
		HK_Fire('EDIT_MODE_LAYOUTS_UPDATED')
		expectEq(OTF:GetParent(), UIParent, 'back on screen after the burst')
		HK_RunTimers()
	end)
	expectEq(calls, 1, 'one ownership check for the three events')
	expect(Parked(), 'parked again')
	-- a zone change without a loading screen and the tracker's own updates: not events Banzai listens to (nothing queued, nothing polled)
	local changes = Changes()
	calls = Counting(function()
		HK_Fire('ZONE_CHANGED')
		HK_Fire('ZONE_CHANGED_NEW_AREA')
		HK_Fire('QUEST_LOG_UPDATE')
		HK_Fire('PLAYER_REGEN_ENABLED') -- (nothing waited)
		HK_RunTimers()
	end)
	expectEq(calls, 0, 'nothing checked')
	expectEq(ns.Restore.trackerQueued, nil, 'nothing queued')
	expectEq(Changes(), changes, 'nothing moved')
	-- already parked: the events cost one comparison each, no frame change
	calls = Counting(function()
		HK_Fire('PLAYER_ENTERING_WORLD', false, false)
		HK_RunTimers()
	end)
	expect(Parked() and Changes() == changes + 2, 'Eltruism moved it (twice), Banzai parked it once more, nothing else')
	calls = Counting(function()
		for _ = 1, 5 do ns.Restore:QueueTrackerOwnership('again') end
		HK_RunTimers()
		for _ = 1, 5 do expectEq(ns.Restore:TrackerOwnership('again'), 'kept', 'idempotent') end
	end)
	expectEq(calls, 6, 'five queued checks collapsed into one, five direct checks')
	expectEq(Changes(), changes + 2, 'the tracker not moved by any of them')
end)

test('1.0.3 tracker: Edit Mode - a layout applied (the managed container), leaving Edit Mode (EventRegistry EditMode.Exit, registered once) and a spec change all park it again one frame later', function()
	AsMonk(3)
	expect(Parked(), 'parked')
	OTF:SetParent(RIGHT_CONTAINER)
	HK_Fire('EDIT_MODE_LAYOUTS_UPDATED')
	HK_RunTimers()
	expect(Parked(), 'parked after the layout was applied')
	expectEq(#(HK_REGISTRY['EditMode.Exit'] or {}), 1, 'EditMode.Exit subscribed exactly once')
	OTF:SetParent(RIGHT_CONTAINER)
	EventRegistry:TriggerEvent('EditMode.Exit')
	expectEq(ns.Restore.trackerQueued, 'EditMode.Exit', 'queued on leaving Edit Mode')
	HK_RunTimers()
	expect(Parked(), 'parked after Edit Mode')
	OTF:SetParent(RIGHT_CONTAINER)
	HK_SPEC_INDEX = 2
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	HK_RunTimers()
	expect(Parked(), 'parked after the spec change')
	expectEq(ns.Roles:Active(), 'HEALER', 'the HEALER layout as before')
	HK_SPEC_INDEX = 3
	HK_Fire('PLAYER_SPECIALIZATION_CHANGED', 'player')
	HK_RunTimers()
	expect(Parked(), 'still parked')
	-- Eltruism re-anchors it on ACTIVE_TALENT_GROUP_CHANGED too
	OTF:SetParent(UIParent)
	HK_Fire('ACTIVE_TALENT_GROUP_CHANGED')
	HK_RunTimers()
	expect(Parked(), 'parked after the talent group change')
	-- the tracker built late
	OTF:SetParent(UIParent)
	HK_Fire('ADDON_LOADED', 'Blizzard_ObjectiveTracker')
	HK_RunTimers()
	expect(Parked(), 'parked once Blizzard\'s tracker loads')
end)

test('1.0.3 tracker: the Banzai tracker switched off leaves Blizzard\'s tracker to the game through every event; switched on it is parked again and held', function()
	AsMonk(3)
	ns.Restore:SetTracker(false)
	expectEq(compat.tracker, false, 'Banzai tracker off')
	expectEq(OTF:GetParent(), UIParent, 'Blizzard\'s tracker back')
	local changes = Changes()
	HK_Fire('PLAYER_ENTERING_WORLD', false, false)
	HK_Fire('EDIT_MODE_LAYOUTS_UPDATED')
	EventRegistry:TriggerEvent('EditMode.Exit')
	HK_RunTimers()
	expectEq(OTF:GetParent(), UIParent, 'the game\'s (Eltruism moved it, Banzai did not)')
	expectEq(Changes(), changes + 3, 'Banzai never touched it')
	ns.Restore:SetTracker(true)
	expect(Parked(), 'parked again')
	OTF:SetParent(UIParent)
	HK_Fire('PLAYER_ENTERING_WORLD', false, false)
	HK_RunTimers()
	expect(Parked(), 'and held')
end)

test('1.0.3 tracker: APPLY BANZAI, a synced character\'s login and UPDATE CHARACTER each end with Blizzard\'s tracker parked, and it stays parked through the next loading screen', function()
	local S = ns.Sync
	LogIn(VOKER, 'Darrensvoker', 'EVOKER', 1)
	expectEq(S:State(), 'NOT_SYNCED', 'not synced')
	expect(S:Apply(), 'APPLY BANZAI')
	expect(Parked(), 'parked at APPLY BANZAI')
	OTF:SetParent(UIParent)
	HK_Fire('PLAYER_ENTERING_WORLD', true, false) -- its next login
	HK_RunTimers()
	expect(Parked(), 'parked at the synced character\'s login')
	AsDruid()
	compat.glassOpacity = 0.51
	expect(S:Capture(), 'the master changed')
	LogIn(VOKER, 'Darrensvoker', 'EVOKER', 1)
	OTF:SetParent(UIParent)
	HK_Fire('PLAYER_ENTERING_WORLD', false, true)
	HK_RunTimers()
	expectEq(S:State(), 'UPDATE', 'BANZAI UPDATE AVAILABLE')
	expect(Parked(), 'parked before the update')
	expect(S:Update(), 'UPDATE CHARACTER')
	expect(Parked(), 'parked after UPDATE CHARACTER')
	OTF:SetParent(UIParent)
	HK_Fire('PLAYER_ENTERING_WORLD', false, false)
	HK_RunTimers()
	expect(Parked(), 'parked after the next loading screen')
	expectEq(S:State(), 'SYNCED', 'synced')
end)

test('1.0.3 tracker: in combat the change waits - one pending flag, no queue growth, no chat - and happens once combat ends; later combats do nothing', function()
	AsMonk(3)
	expect(Parked(), 'parked')
	OTF:SetParent(UIParent)
	HK_IN_COMBAT = true
	local prints = #HK_PRINTS
	local calls = Counting(function()
		HK_Fire('PLAYER_ENTERING_WORLD', false, false)
		HK_Fire('FIRST_FRAME_RENDERED')
		HK_Fire('EDIT_MODE_LAYOUTS_UPDATED')
		HK_RunTimers()
		HK_Fire('PLAYER_ENTERING_WORLD', false, false)
		HK_RunTimers()
	end)
	expectEq(calls, 2, 'one check per burst (each found combat)')
	expectEq(OTF:GetParent(), UIParent, 'no frame change in combat')
	expectEq(ns.Restore.trackerPending, true, 'waiting for the end of combat')
	expectEq(ns.Restore.trackerQueued, nil, 'nothing queued twice')
	expectEq(#HK_PRINTS, prints, 'nothing said in chat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	HK_RunTimers()
	expect(Parked(), 'parked once combat ended')
	expectEq(ns.Restore.trackerPending, nil, 'nothing pending')
	local changes = Changes()
	calls = Counting(function()
		HK_Fire('PLAYER_REGEN_ENABLED')
		HK_Fire('PLAYER_REGEN_ENABLED')
		HK_RunTimers()
	end)
	expectEq(calls, 0, 'later combats: nothing to do, nothing checked')
	expectEq(Changes(), changes, 'nothing moved')
	expectEq(#HK_PRINTS, prints, 'still nothing in chat')
end)

test('1.0.3 tracker: RESTORE PRE-BANZAI puts Blizzard\'s tracker back exactly as recorded (parent, shown, collapsed) and the events leave it to the game afterwards', function()
	local S = ns.Sync
	AsMonk(3)
	expect(Parked(), 'parked')
	local saved = BushidoPrivateRestoreDB.characters[MONK].previous.blizzardTracker
	expectEq(saved.parent .. '|' .. tostring(saved.shown) .. '|' .. tostring(saved.collapsed), 'UIParent|true|true', 'the pre-Banzai record (taken before anything was parked, never overwritten)')
	OTF:SetCollapsed(false) -- (left expanded by something in the session)
	expect(S:RestoreCharacter(), 'RESTORE PRE-BANZAI')
	expectEq(OTF:GetParent(), UIParent, 'its original parent')
	expectEq(OTF:IsShown(), true, 'its original shown state (never changed by Banzai: parking changes the parent only)')
	expectEq(OTF:IsCollapsed(), true, 'its original collapsed state')
	expectEq(BushidoPrivateRestoreDB.characters[MONK].previous, nil, 'the record consumed')
	local changes = Changes()
	HK_Fire('PLAYER_ENTERING_WORLD', false, true)
	HK_Fire('EDIT_MODE_LAYOUTS_UPDATED')
	EventRegistry:TriggerEvent('EditMode.Exit')
	HK_RunTimers()
	ns.Restore:OnLogin()
	expectEq(OTF:GetParent(), UIParent, 'the game\'s again')
	expectEq(Changes(), changes + 3, 'moved only by Eltruism; Banzai never touched it after the restore')
	AsDruid()
end)

test('1.0.3 tracker: no hook, no OnUpdate loop, no ticker, one event frame', function()
	expectEq(#HK_HOOKS, 0, 'no secure hook')
	expectEq(#HK_TICKERS, 0, 'no ticker')
	local listeners = 0
	for _, f in ipairs(HK_Frames()) do
		expect(f.scripts.OnUpdate == nil, 'no OnUpdate script on any Banzai frame')
		if f.events.FIRST_FRAME_RENDERED and f ~= eltruism then listeners = listeners + 1 end
	end
	expectEq(listeners, 1, 'one tracker event frame')
	for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'FIRST_FRAME_RENDERED', 'EDIT_MODE_LAYOUTS_UPDATED' }) do eltruism:UnregisterEvent(event) end
end)

test('1.1.0 / 1.1.1 panel background: PARCHMENT sets the Details row text bright off-white through Details\' own row settings (live windows and the profile), GLASS / SOLID back to white; the options page has PANEL STYLE', function()
	local R = ns.Restore
	local details = Details:GetProfile(NAME, true)
	expectEq(R:SetPanelBackground('PARCHMENT'), 'PARCHMENT', 'set')
	expectEq(compat.panelBackground, 'PARCHMENT', 'the BANZAI setting (synced)')
	expectEq(HK_DetailsWindow.row_info.fixed_text_color[1], 0.96, 'window 1: bright off-white (1.1.1: never charcoal)')
	expectEq(HK_DetailsWindow2.row_info.fixed_text_color[1], 0.96, 'window 2: bright off-white')
	expect(HK_DetailsWindow.row_info.fixed_text_color[1] > 0.9 and HK_DetailsWindow.row_info.fixed_text_color[3] > 0.85, 'light neutral, readable over parchment and the coloured bars')
	expectEq(HK_DetailsWindow.row_info.textL_outline_mode, nil, 'the row outline (OUTLINE, written by the profile style) is not touched here')
	expectEq(HK_DetailsWindow.rowsRefreshed, 1, 'rows refreshed through Details\' instance API')
	for _, window in pairs(details.instances or {}) do expectEq(window.row_info and window.row_info.fixed_text_color[1], 0.96, 'profile instance: off-white for the next login') end
	expectEq(R:SetPanelBackground('GLASS'), 'GLASS', 'back')
	expectEq(HK_DetailsWindow.row_info.fixed_text_color[1], 1, 'white again')
	expectEq(HK_DetailsWindow.rowsRefreshed, 2, 'refreshed again')
	expectEq(R:SetPanelBackground('NEON'), 'GLASS', 'unknown: glass')
	-- the apply writes the ink for the chosen background
	compat.panelBackground = 'PARCHMENT'
	T.StyleDetailsWindows(details, true, R:Fonts())
	T.DetailsRowInk(details, compat.panelBackground == 'PARCHMENT')
	for _, window in pairs(details.instances or {}) do
		expectEq(window.row_info and window.row_info.fixed_text_color[2], 0.95, 'apply: off-white')
		expectEq(window.row_info.textL_outline_mode .. '/' .. window.row_info.textR_outline_mode, 'OUTLINE/OUTLINE', 'apply: the dark outline stays on parchment')
		expectEq(window.row_info.texture_class_colors, true, 'apply: class-coloured bars kept')
	end
	-- Parchment -> Glass -> Parchment: the same values every time, nothing accumulates
	for _, mode in ipairs({ 'PARCHMENT', 'GLASS', 'PARCHMENT', 'SOLID', 'PARCHMENT' }) do
		R:SetPanelBackground(mode)
		local c = HK_DetailsWindow.row_info.fixed_text_color
		expectEq(table.concat(c, ','), mode == 'PARCHMENT' and '0.96,0.95,0.92,1' or '1,1,1,1', mode .. ': exact row text colour')
		expectEq(#HK_DetailsWindow.row_info, 0, mode .. ': no extra row keys')
	end
	R:SetPanelBackground('GLASS')
	compat.panelBackground = 'GLASS'
	expectEq(T.DetailsRowInk(details, false) > 0, true, 'apply: white')
	local page = ns.Options:Build()
	local section = page.args.appearance.args.panelStyle
	expect(section and section.args.panelBorder and section.args.panelBackground, 'PANEL STYLE with both selectors')
	expectEq(table.concat(section.args.panelBorder.sorting, ','), 'CLASS,BANZAI,HARDKORH', 'three borders')
	expectEq(table.concat(section.args.panelBackground.sorting, ','), 'SOLID,GLASS,PARCHMENT', 'three backgrounds')
	expectEq(section.args.borderScale.max, 1, 'border scale bounded at the content inset')
	expectEq(section.args.parchmentBrightness.min, 0.7, 'parchment brightness bounded')
	expectEq(page.args.appearance.args.frameTheme.args.glassOpacity, nil, 'glass opacity moved into PANEL STYLE (no duplicate control)')
	section.args.panelBackground.set(nil, 'SOLID')
	expectEq(compat.panelBackground, 'SOLID', 'the control sets it')
	expectEq(HK_DetailsWindow.row_info.fixed_text_color[1], 1, 'white text on solid')
	section.args.panelBackground.set(nil, 'GLASS')
end)

---------------------------------------------------------------------------
-- 1.2.0
---------------------------------------------------------------------------
test('1.2.0 BUFFS panel settings: on / rows / position written into the Banzai profile at once, ElvUI moves its own buffs (out of combat, after combat otherwise), the options page, Character Sync', function()
	local p = profile()
	local R = ns.Restore
	local section = Find(Opts('layout'), 'auras')
	expectEq(HK_Plain(section.name), 'BUFFS PANEL', 'LAYOUT > BUFFS PANEL')
	expectEq(table.concat(Find(Opts('layout'), 'buffsRows').sorting, ','), '2,3', 'maximum rows: 2 or 3')
	HK_MOVERS_SET = 0
	HK_AURA_HEADER_UPDATES = 0
	Find(Opts('layout'), 'buffsX').set(nil, 60)
	Find(Opts('layout'), 'buffsY').set(nil, 44)
	expectEq(compat.buffsX .. ',' .. compat.buffsY, '60,44', 'Banzai settings (Character Sync carries them)')
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,60,-44', 'written into the profile')
	expect(HK_MOVERS_SET >= 2, 'ElvUI moved its movers at once (' .. HK_MOVERS_SET .. ')')
	expect(HK_AURA_HEADER_UPDATES >= 2, 'ElvUI updated its buff header at once')
	Find(Opts('layout'), 'buffsX').set(nil, -50)
	expectEq(compat.buffsX, T.BUFFS_PANEL.min, 'never so far left that the bamboo ends leave the screen')
	-- in combat: written, ElvUI's movers wait for the end of combat
	HK_IN_COMBAT = true
	HK_MOVERS_SET = 0
	expectEq(R:SetBuffsPanel('buffsY', 80), 80, 'set')
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,26,-80', 'profile written')
	expectEq(HK_MOVERS_SET, 0, 'nothing moved in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(HK_MOVERS_SET, 1, 'moved once after combat')
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(HK_MOVERS_SET, 1, 'and only once')
	Find(Opts('layout'), 'buffsReset').func()
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,30,-30', 'reset position')
	-- off greys the panel controls, the buff size stays usable
	Find(Opts('layout'), 'buffsPanel').set(nil, false)
	expectEq(Find(Opts('layout'), 'buffsRows').disabled(), true, 'rows greyed while off')
	expectEq(Find(Opts('layout'), 'buffScale').disabled, nil, 'buff size always available')
	Find(Opts('layout'), 'buffsPanel').set(nil, true)
	-- without Banzai Art there is no panel: the buffs keep their 1.0 places
	BanzaiCompat = nil
	expectEq(R:BuffsPanel().on, false, 'Banzai Art not loaded: no panel')
	T.ApplyAuras(p, 0.7, P.elvuiProfile, R:BuffsPanel())
	expectEq(p.movers.BuffsMover, T.AURAS.buffs, 'buffs at their 1.0 place')
	BanzaiCompat = CompatStub
	R:ApplyBuffsLayout()
	expectEq(p.movers.BuffsMover, 'TOPLEFT,UIParent,TOPLEFT,30,-30', 'back in the panel')
	-- a change in combat while on another profile leaves nothing pending
	local profileNow = E.data.current
	E.data.current = 'HARDKORHUI'
	HK_IN_COMBAT = true
	R:SetBuffsPanel('buffsY', 31)
	HK_IN_COMBAT = false
	expectEq(R.buffsPending, nil, 'not on the Banzai profile: nothing waits for the end of combat')
	E.data.current = profileNow
	R:SetBuffsPanel('buffsY', 30)
	-- the character layer carries the panel (a change rewrites this character's part at the next login)
	local opts = R:LayerOptions()
	expectEq(opts.buffsPanel.on and opts.buffsPanel.rows .. ',' .. opts.buffsPanel.x .. ',' .. opts.buffsPanel.y, '2,30,30', 'layer options')
	expectEq(opts.chatX, T.CHAT.x, 'the chat place is part of the layer signature')
	expectEq(opts.actionStyle, 'SQUARE', 'button style')
	-- Character Sync: the master's export carries style and panel, never buffs
	local owned = ''
	for _, row in ipairs(ns.Sync.OWNERSHIP) do owned = owned .. row[2] end
	expect(string.find(owned, 'button style: Banzai Square / Banzai Circles / ElvUI Square', 1, true) and string.find(owned, 'BUFFS panel (on, rows, position; never the buffs themselves)', 1, true), 'WHAT SYNCS names them')
	local status = ''
	HK_PRINTS = {}
	R:Status()
	status = table.concat(HK_PRINTS, '\n')
	expect(string.find(status, 'buffs panel: on, 2 rows of 10, buffs at 30, 30 (top-left); chat flush with the left screen edge', 1, true), '/banzai status')
	expect(string.find(status, 'action buttons: SQUARE', 1, true), 'status names the button style')
end)

test('1.2.0 chat flush with the left screen edge: ElvUI\'s chat panel at x 31 (same size, same bottom), Banzai Art\'s frame in step', function()
	local p = profile()
	expectEq(T.CHAT.x, 31, 'the chat panel')
	expectEq(p.movers.LeftChatMover, 'BOTTOMLEFT,UIParent,BOTTOMLEFT,31,' .. (compat.barHeight + 10), 'mover (x 31, 10 above the information panel)')
	expectEq(p.chat.panelWidth .. 'x' .. p.chat.panelHeight, '430x140', 'same size')
	expectEq(T.ChatMover(32), 'BOTTOMLEFT,UIParent,BOTTOMLEFT,31,42', 'same bottom on the information panel')
end)

test('1.2.1 BUFFS settings: written from the configuration only - the same movers whatever the auras do; on / off, 2 / 3 rows, combat, Character Sync', function()
	local p = profile()
	local R = ns.Restore
	local function movers() return p.movers.BuffsMover .. ' | ' .. p.movers.DebuffsMover .. ' | ' .. p.auras.buffs.maxWraps end
	R:SetBuffsPanel('buffsRows', 2)
	expectEq(movers(), 'TOPLEFT,UIParent,TOPLEFT,30,-30 | TOPLEFT,UIParent,TOPLEFT,30,-160 | 2', '2 rows')
	HK_Fire('UNIT_AURA', 'player')
	HK_Fire('UNIT_INVENTORY_CHANGED', 'player')
	HK_RunTimers()
	expectEq(movers(), 'TOPLEFT,UIParent,TOPLEFT,30,-30 | TOPLEFT,UIParent,TOPLEFT,30,-160 | 2', 'aura / equipment events change nothing')
	R:SetBuffsPanel('buffsRows', 3)
	expectEq(movers(), 'TOPLEFT,UIParent,TOPLEFT,30,-30 | TOPLEFT,UIParent,TOPLEFT,30,-191 | 3', '3 rows')
	HK_IN_COMBAT = true
	R:SetBuffsPanel('buffsRows', 2)
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(movers(), 'TOPLEFT,UIParent,TOPLEFT,30,-30 | TOPLEFT,UIParent,TOPLEFT,30,-160 | 2', 'in combat: written, applied after it')
	R:SetBuffsPanel('buffsPanel', false)
	expectEq(movers(), T.AURAS.buffs .. ' | ' .. T.AURAS.debuffs .. ' | ' .. P.elvuiProfile.auras.buffs.maxWraps, 'off: the 1.0 places')
	R:SetBuffsPanel('buffsPanel', true)
	-- Character Sync: the configuration travels, nothing about buffs
	local opts = R:LayerOptions()
	expectEq(opts.buffsPanel.on and (opts.buffsPanel.rows .. ',' .. opts.buffsPanel.x .. ',' .. opts.buffsPanel.y), '2,30,30', 'layer options from the settings')
end)

test('1.2.1 Banzai Square text places unchanged: keybind TOPRIGHT -3 / -3 (Bushido size), count BOTTOM 0 / 2, cooldown numbers CENTER -0.5 at 11', function()
	local p = profile()
	ns.Restore:SetActionStyle('SQUARE')
	for _, bar in ipairs({ 'bar1', 'bar6' }) do
		local db = p.actionbar[bar]
		expectEq(db.hotkeyTextPosition .. ' ' .. db.hotkeyTextXOffset .. ' ' .. db.hotkeyTextYOffset, 'TOPRIGHT -3 -3', bar .. ': keybind')
		expectEq(db.countTextPosition .. ' ' .. db.countTextXOffset .. ' ' .. db.countTextYOffset, 'BOTTOM 0 2', bar .. ': count')
		expectEq(tostring(db.keepSizeRatio) .. ' ' .. db.buttonSize .. ' ' .. db.buttonHeight, 'true 30 30', bar .. ': square buttons (width = height)')
	end
	expectEq(p.cooldown.actionbar.position .. ' ' .. p.cooldown.actionbar.offsetY .. ' ' .. p.cooldown.actionbar.fontSize, 'CENTER -0.5 11', 'cooldown numbers')
end)

---------------------------------------------------------------------------
-- 1.3.0 optional BANZAI SPLIT + BANZAI COMPACT
---------------------------------------------------------------------------
test('1.3.0 BANZAI CLASSIC stays: a CLASSIC layer\'s options carry no split key (the 1.2.1 layer exactly), nothing rewritten by the upgrade, no split record used', function()
	local R = ns.Restore
	compat.frameStyle, compat.detailsStyle = nil, nil
	local opts = R:LayerOptions()
	expectEq(opts.frameStyle, nil, 'CLASSIC: no frame-style key in the layer')
	for _, k in ipairs(R.SPLIT_LAYER) do expectEq(opts[k], nil, 'CLASSIC: no ' .. k) end
	expectEq(type(opts.splitState), 'table', 'the split record is handed over (never part of the signature)')
	local a = R.Signature(opts, R:Fonts())
	opts.splitState.snapshot = { { path = { 'x' }, value = 1 } }
	expectEq(R.Signature(opts, R:Fonts()), a, 'the record never changes the signature')
	opts.splitState.snapshot = nil
	-- the classic layer on the profile is the same as 1.2.1's (also proven in the Lua VM by the validator)
	local p = profile()
	R:CharacterLayer(KEY, true)
	local before = T.Serialize(p)
	R:CharacterLayer(KEY, true)
	expectEq(T.Serialize(p), before, 'idempotent: the same profile every time')
	expectEq(texts('player')['b-SplitName'], nil, 'no split name line in a classic profile')
	expectEq(p.unitframe.units.player.castbar.enable, nil, 'ElvUI\'s player cast bar as Bushido had it')
end)

test('1.3.0 BANZAI SPLIT written over the classic layer: Player / Target / Focus / ToT / party in the split construction, Banzai\'s positions, a reload asked; back to CLASSIC gives the classic profile exactly; idempotent', function()
	local R = ns.Restore
	local p = profile()
	R:CharacterLayer(KEY, true)
	local classic = T.Serialize(p)
	HK_POPUPS = {}
	expectEq(R:SetFrameStyle('SPLIT'), 'SPLIT', 'SPLIT chosen')
	expectEq(compat.frameStyle, 'SPLIT', 'the BANZAI setting (per character, synced)')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'a reload builds the frames with it')
	local u = p.unitframe.units
	expectEq(u.player.width .. 'x' .. u.player.height, '180x24', 'Player: the health bar is the frame (1.3.1: 24 high)')
	expectEq(u.player.power.detachFromFrame and u.player.power.detachedWidth .. 'x' .. u.player.power.height, '180x24', 'the resource bar the same size, detached')
	expectEq(p.movers.ElvUF_PlayerMover, 'RIGHT,ElvUIParent,BOTTOM,-21,290', 'health LEFT of the hub (lower centre, 290 up; 1.3.3: the hub 125 %, the bar 4 further out)')
	expectEq(p.movers.PlayerPowerBarMover, 'LEFT,ElvUIParent,BOTTOM,21,290', 'resource RIGHT of it')
	expectEq(p.movers.ElvUF_TargetMover, 'RIGHT,ElvUIParent,TOP,-20,-112', 'Target: upper centre, health left (1.3.3: the hub 125 %)')
	expectEq(p.movers.TargetPowerBarMover, 'LEFT,ElvUIParent,TOP,20,-112', 'its resource right')
	expectEq(p.movers.ElvUF_FocusMover, 'RIGHT,ElvUIParent,BOTTOM,-340,360', 'Focus: up and left of the Player')
	expectEq(p.movers.ElvUF_TargetTargetMover, 'LEFT,ElvUIParent,TOP,204,-112', 'ToT: right of the Target (1.3.3: with its resource bar\'s end)')
	expectEq(p.movers.ClassBarMover, 'BOTTOMLEFT,ElvUIParent,BOTTOM,69,360', '1.3.1: class bar above the resource values, clear of the spell name over the hub (1.3.3: above the bamboo cast bar; 1.3.4: the lower bar, 35 + 32.4 + 3 over the hub\'s centre)')
	expectEq(u.player.classbar.detachedWidth, 124, '1.3.1: from there to 8 short of the bar\'s outer end')
	for _, unit in ipairs({ 'player', 'target', 'focus' }) do
		expectEq(u[unit].castbar.enable, false, unit .. ': ElvUI\'s cast bar off (the hub shows the cast)')
		expectEq(u[unit].portrait.enable, false, unit .. ': no ElvUI portrait')
		expectEq(u[unit].infoPanel.enable, false, unit .. ': no info panel')
		expectEq(u[unit].customTexts['m-Name'].enable, false, unit .. ': the classic name line off')
		if p.mMediaTag.portraits[unit] then expectEq(p.mMediaTag.portraits[unit].enable, false, unit .. ': mMediaTag\'s large circle off') end
	end
	-- 1.3.1: Player / Target - Banzai Art draws the name / spec lines; b-SplitName only marks the layer (ElvUI shows nothing for it)
	for _, unit in ipairs({ 'player', 'target' }) do
		local mark = u[unit].customTexts['b-SplitName']
		expectEq(tostring(mark.enable) .. ' ' .. tostring(mark.banzaiSplit), 'false true', unit .. ': the layer\'s marker, no ElvUI text')
		expectEq(mark.banzaiSpec, true, unit .. ': the spec line on (as the classic layer has it)')
	end
	local focusLine = u.focus.customTexts['b-SplitName']
	expectEq(focusLine.enable and focusLine.justifyH, 'CENTER', 'focus: one centred name line (unchanged)')
	expectEq(focusLine.attachTextTo, 'Health', 'focus: on the health bar')
	expectEq(u.targettarget.width .. 'x' .. u.targettarget.height, '90x10', 'ToT: one compact bar')
	expectEq(u.targettarget.power.enable, false, 'no ToT resource')
	expectEq(u.party.customTexts['m-Name'].justifyH .. ' ' .. u.party.customTexts['m-Name'].yOffset, 'CENTER -12', 'party name across the lower part of the circle')
	expectEq(u.party.customTexts['b-Role'].justifyH .. ' ' .. u.party.customTexts['b-Role'].xOffset .. ' ' .. u.party.customTexts['b-Role'].yOffset, 'CENTER -15 10', 'party role icon: a badge on the circle upper left')
	expectEq(u.party.width, 100, 'party size: the role layout\'s')
	expectEq(u.arena.width, 100, 'arena enemy frames untouched')
	-- idempotent
	local split = T.Serialize(p)
	R:CharacterLayer(KEY, true)
	R:CharacterLayer(KEY, true)
	expectEq(T.Serialize(p), split, 'written again: the same split profile')
	-- back
	R:SetFrameStyle('CLASSIC')
	expectEq(T.Serialize(p), classic, 'CLASSIC again: exactly the classic profile')
	R:SetFrameStyle('SPLIT')
	expectEq(T.Serialize(p), split, 'SPLIT again: the same split profile')
	R:SetFrameStyle('CLASSIC')
	expectEq(T.Serialize(p), classic, 'and back, any number of times')
end)

test('1.3.0 BANZAI SPLIT positions (Banzai\'s own, not ElvUI\'s movers): set at once through ElvUI\'s mover update; sizes take a reload; stored for later while CLASSIC is the style', function()
	local R = ns.Restore
	local p = profile()
	R:SetFrameStyle('CLASSIC')
	local classic = T.Serialize(p)
	R:SetSplit('splitPlayerY', 320)
	expectEq(compat.splitPlayerY, 320, 'stored')
	expectEq(T.Serialize(p), classic, 'CLASSIC: the profile untouched')
	R:SetFrameStyle('SPLIT')
	expectEq(p.movers.ElvUF_PlayerMover, 'RIGHT,ElvUIParent,BOTTOM,-21,320', 'used once SPLIT is chosen')
	HK_MOVERS_SET, HK_POPUPS = 0, {}
	R:SetSplit('splitPlayerX', -40)
	expectEq(p.movers.ElvUF_PlayerMover, 'RIGHT,ElvUIParent,BOTTOM,-61,320', 'moved')
	expectEq(p.movers.ElvUF_FocusMover, 'RIGHT,ElvUIParent,BOTTOM,-380,390', 'the Focus follows the Player')
	expectEq(HK_MOVERS_SET, 1, 'ElvUI moves the frames at once')
	expectEq(#HK_POPUPS, 0, 'no reload for a position')
	R:SetSplit('splitScale', 1.2)
	expectEq(p.unitframe.units.player.width, 216, 'frame scale')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'a size takes a reload')
	R:SetSplit('splitHubScale', 1.2)
	expectEq(p.movers.PlayerPowerBarMover, 'LEFT,ElvUIParent,BOTTOM,-9,320', 'a larger hub moves the bars apart (hub 72, tuck 12: 24 from its centre; 1.3.3: hub 90, tuck 14: 31)')
	expectEq(R:SetSplit('notASetting', 1), nil, 'only the split settings')
	R:ResetSplitPositions()
	R:SetSplit('splitScale', 1) R:SetSplit('splitHubScale', 1)
	expectEq(p.movers.ElvUF_PlayerMover, 'RIGHT,ElvUIParent,BOTTOM,-21,290', 'reset positions')
	R:SetFrameStyle('CLASSIC')
	expectEq(T.Serialize(p), classic, 'CLASSIC again: exactly as before')
end)

test('1.3.0 a classic option changed while BANZAI SPLIT is the style: written over the classic values, the split layer written again after it - no mixed profile, and CLASSIC later shows the change', function()
	local R = ns.Restore
	local p = profile()
	R:SetFrameStyle('SPLIT')
	R:SetHealthInside(false)
	expectEq(texts('player')['m-Health'].enable, false, 'split: ElvUI\'s health text stays off on the split Player')
	expectEq(texts('player')['b-SplitName'].banzaiSplit, true, 'the split layer is still there (1.3.1: its marker)')
	R:SetFrameStyle('CLASSIC')
	expectEq(texts('player')['m-Health'].enable, true, 'classic: the health-under-the-bar choice made in SPLIT applies')
	R:SetHealthInside(true)
	-- the spec choice follows into the split line
	R:SetFrameStyle('SPLIT')
	local page = ns.Options:Build()
	local specNames = Find(page.args.appearance, 'specNames')
	expectEq(specNames.get(), true, 'spec in names: read from the split line')
	specNames.set(nil, false)
	expectEq(texts('player')['b-SplitName'].banzaiSpec, false, 'spec off: the split marker says so (1.3.1: Banzai Art leaves the spec line out)')
	expectEq(string.find(texts('focus')['b-SplitName'].text_format, 'banzai:spec', 1, true), nil, 'spec off: the Focus split line without it')
	expectEq(specNames.get(), false, 'shown off')
	specNames.set(nil, true)
	expectEq(texts('player')['b-SplitName'].banzaiSpec, true, 'spec on again')
	R:SetFrameStyle('CLASSIC')
	expect(string.find(texts('player')['b-Spec'] and tostring(texts('player')['b-Spec'].enable) or '', 'true', 1, true), 'classic spec line back on')
end)

test('1.3.0 another character on the shared profile: its own style at its login - a CLASSIC character takes the split layer back, a SPLIT one writes it again', function()
	local R = ns.Restore
	local p = profile()
	R:SetFrameStyle('CLASSIC')
	local classic = T.Serialize(p)
	R:SetFrameStyle('SPLIT')
	local split = T.Serialize(p)
	-- an alt with BANZAI CLASSIC logs in on the shared profile
	local main = E.mynameRealm
	E.mynameRealm = 'Classicalt - Stormrage'
	BushidoPrivateRestoreDB.characters[E.mynameRealm] = BushidoPrivateRestoreDB.characters[E.mynameRealm] or { applied = { version = '1.3.0' }, previous = {} }
	compatChars[E.mynameRealm] = T.DeepCopy(compatChars[main])
	compatChars[E.mynameRealm].frameStyle = 'CLASSIC'
	R:CharacterLayer(E.mynameRealm)
	expectEq(texts('player')['b-SplitName'], nil, 'the alt: classic frames (the split record taken back)')
	expectEq(p.unitframe.units.player.castbar.enable, nil, 'its cast bar as before')
	E.mynameRealm = main
	R:CharacterLayer(main)
	expectEq(T.Serialize(p), split, 'Darren\'s SPLIT character: the split profile again at its login')
	R:SetFrameStyle('CLASSIC')
	expectEq(T.Serialize(p), classic, 'classic exactly')
	BushidoPrivateRestoreDB.characters['Classicalt - Stormrage'] = nil
	compatChars['Classicalt - Stormrage'] = nil
end)

test('1.3.0 BANZAI COMPACT Details: thin class-coloured bars, a round identity icon per row (Fabled set today; Darren\'s sheet once built; Banzai\'s class discs without Jiberish Icons), names in the class colour above the bars, values large; through Details\' row settings and SetBarSettings; CURRENT gives Bushido\'s icon settings back', function()
	local R = ns.Restore
	Details.current = NAME
	local w1, w2 = HK_DetailsWindow, HK_DetailsWindow2
	local profile0 = Details:GetProfile(NAME, true)
	profile0.instances = profile0.instances or T.DeepCopy(P.detailsProfile.instances)
	compat.panelBackground = 'PARCHMENT'
	R:ApplyDetailsInk()
	local ink = table.concat(w1.row_info.fixed_text_color, ',')
	expect(string.find(R:SetDetailsStyle('COMPACT'), 'COMPACT meter rows on 2 windows', 1, true), 'applied to both windows')
	expectEq(compat.detailsStyle, 'COMPACT', 'the BANZAI setting (synced)')
	for _, w in ipairs({ w1, w2 }) do
		local row = w.row_info
		expectEq(row.height, 4, 'thin bars')
		expectEq(row.no_icon, false, 'icons on')
		expectEq(row.icon_file, T.DETAILS_ICONS.fabled, 'today: the Fabled class set Jiberish Icons registers (referenced in place)')
		expectEq(row.start_after_icon, false, 'the bar runs under the icon')
		expectEq(row.texts[1].color.byClass, true, 'the name in its class colour')
		expectEq(row.texts[1].anchor.point .. '/' .. row.texts[1].anchor.relativePoint, 'bottomleft/topleft', 'the name above its bar')
		expect(row.texts[4].font.size > row.texts[1].font.size, 'the value larger than the name')
		expectEq(table.concat(row.fixed_text_color, ','), ink, 'the 1.1.1 parchment ink untouched')
		expectEq(w.barSettings.height .. '/' .. w.barSettings.icon .. '/' .. tostring(w.barSettings.start), '4/' .. T.DETAILS_ICONS.fabled .. '/false', 'refreshed through Details\' SetBarSettings')
	end
	for _, window in pairs(profile0.instances) do
		if type(window) == 'table' and window.row_info then expectEq(window.row_info.height, 4, 'the profile for the next login') expectEq(window.row_info.texture_class_colors, true, 'class-coloured bars') end
	end
	expectEq(BushidoPrivateRestoreDB.detailsStyleApplied, 'COMPACT', 'recorded')
	-- Darren's own sheet once the build made it; Banzai's discs without Jiberish Icons
	CompatStub.IdentityDetailsSheet = function() return true end
	R:SetDetailsStyle('COMPACT')
	expectEq(w1.row_info.icon_file, T.DETAILS_ICONS.banzai, 'Darren\'s sheet first')
	CompatStub.IdentityDetailsSheet = nil
	HK_LOADED.JiberishIcons = false
	R:SetDetailsStyle('COMPACT')
	expectEq(w1.row_info.icon_file, T.DETAILS_ICONS.discs, 'no Jiberish Icons: Banzai\'s class-colour discs')
	HK_LOADED.JiberishIcons = true
	-- back to CURRENT: the approved rows, no icons (Bushido's)
	R:SetDetailsStyle('CURRENT')
	local hist = P.detailsProfile.instances[1].row_info
	expectEq(w1.row_info.height, T.DETAILS_STYLE.rowHeight, 'CURRENT bar height')
	expectEq(w1.row_info.no_icon, hist.no_icon, 'Bushido\'s icon setting back')
	expectEq(w1.row_info.icon_file, hist.icon_file, 'Bushido\'s icon file back')
	expectEq(w1.row_info.texts[1].color.byClass, false, 'CURRENT name colour')
	expectEq(T.Serialize(w1.row_info.texts), T.Serialize(T.DetailsRowTexts()), 'the CURRENT texts exactly')
	-- combat: waits
	HK_IN_COMBAT = true
	expectEq(R:SetDetailsStyle('COMPACT'), 'waiting (combat)', 'not in combat')
	expectEq(w1.row_info.height, T.DETAILS_STYLE.rowHeight, 'unchanged in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(w1.row_info.height, 4, 'applied after combat')
	R:SetDetailsStyle('CURRENT')
	compat.panelBackground = 'GLASS'
	R:ApplyDetailsInk()
	-- a full apply styles the profile in the chosen style
	compat.detailsStyle = 'COMPACT'
	local d = T.DeepCopy(P.detailsProfile)
	T.StyleDetailsWindows(d, true, R:Fonts(), 'COMPACT', T.DETAILS_ICONS.discs)
	expectEq(d.instances[1].row_info.height .. '/' .. d.instances[2].row_info.icon_file, '4/' .. T.DETAILS_ICONS.discs, 'the full apply knows COMPACT')
	compat.detailsStyle = nil
end)

test('1.3.0 GUI: UNIT FRAMES > FRAME STYLE (Banzai Classic / Banzai Split, this session) and BANZAI SPLIT (positions, reset, scales, texts, enhanced nameplate, party style, preview); LAYOUT > DETAILS > Meter style; the preview style selector', function()
	local page = ns.Options:Build()
	local style = Find(page.args.unitframes, 'frameStyle')
	local select = style.args and style.args.frameStyle or style
	expectEq(table.concat(select.sorting, ','), 'CLASSIC,SPLIT', 'two styles, Classic first')
	expectEq(select.get(), 'CLASSIC', 'Classic shown')
	expect(string.find(HK_Plain(select.values.CLASSIC), 'default', 1, true), 'Classic is the default')
	local split = Find(page.args.unitframes, 'split')
	for _, key in ipairs({ 'playerX', 'playerY', 'targetX', 'targetY', 'resetPositions', 'scale', 'hubScale', 'hpText', 'powerText', 'plate', 'party', 'preview' }) do
		expect(split.args[key], 'BANZAI SPLIT: ' .. key)
	end
	local n = 0 for _ in pairs(split.args) do n = n + 1 end
	expect(n <= 14, 'concise: no wall of controls')
	expectEq(split.args.playerY.min .. '..' .. split.args.playerY.max, '150..520', 'bounded')
	local meter = Find(page.args.layout, 'detailsStyle')
	expectEq(table.concat(meter.sorting, ','), 'CURRENT,COMPACT', 'Meter style: Current / Compact')
	expectEq(meter.get(), 'CURRENT', 'Current shown')
	expect(Find(page.args.unitframes, 'previewStyle'), 'the preview style selector')
	select.set(nil, 'SPLIT')
	expectEq(compat.frameStyle, 'SPLIT', 'the control chooses SPLIT')
	select.set(nil, 'CLASSIC')
	expectEq(compat.frameStyle, 'CLASSIC', 'and back')
end)

test('1.3.0 /banzai status names the frame style (chosen and this session\'s) and the meter style; the version everywhere', function()
	HK_PRINTS = {}
	ns.Restore:Status()
	local text = table.concat(HK_PRINTS, '\n')
	expect(string.find(text, 'frame style: BANZAI CLASSIC (this session: BANZAI CLASSIC), Details meter style: BANZAI CURRENT', 1, true), 'status line')
	expect(string.find(text, 'BANZAI 1.5.0', 1, true), 'version')
end)

test('1.3.0 review: the health-percentage switch keeps working while the profile carries the split layer (health under the bars)', function()
	local R = ns.Restore
	R:SetFrameStyle('SPLIT')
	R:SetHealthInside(false)
	local page = ns.Options:Build()
	local percent = Find(page.args.appearance, 'percent')
	percent.set(nil, false)
	expectEq(percent.get(), false, 'off shows off')
	percent.set(nil, true)
	expectEq(percent.get(), true, 'on shows on (not stuck on the hidden classic text)')
	expectEq(texts('player')['b-HealthPct'].enable, false, 'the split Player keeps ElvUI\'s percent text off')
	R:SetFrameStyle('CLASSIC')
	expectEq(texts('player')['b-HealthPct'].enable, true, 'classic: the percent under the bar, as chosen')
	R:SetHealthInside(true)
end)
---------------------------------------------------------------------------
-- 1.3.1 tracker ownership that holds, the split layer's new leaves, Want Coffee in Details COMPACT
---------------------------------------------------------------------------
-- a re-parent as the game runs it: the tracker moves; when its new parent is on screen the tracker (and Banzai's
-- sentinel inside it) becomes visible, and the game fires the sentinel's own OnShow
local function Reparent(parent)
	OTF:SetParent(parent)
	local sentinel = ns.Restore.trackerSentinel
	if sentinel and parent ~= ns.Restore.TRACKER_PARK and parent.shown ~= false and sentinel.scripts.OnShow then sentinel.scripts.OnShow(sentinel) end
end

test('1.3.1 tracker: whatever re-parents Blizzard\'s tracker while the Banzai tracker shows - ElvUI\'s auto-hider after a boss, Eltruism on an indoor / outdoor zone change or after combat, Edit Mode - it is parked again one frame later, one check queued at a time; Banzai\'s own parking never queues one', function()
	HK_RunTimers()
	AsDruid()
	ns.Restore:TrackerOwnership('test')
	expect(Parked(), 'parked while the Banzai tracker shows')
	local sentinel = ns.Restore.trackerSentinel
	expect(sentinel and sentinel.parent == OTF and sentinel.scripts.OnShow, 'Banzai\'s sentinel inside Blizzard\'s tracker (its own frame and script: nothing hooked)')
	expectEq(sentinel.w .. 'x' .. sentinel.h .. ' ' .. tostring(sentinel.mouse), '1x1 false', 'tiny, empty, never in the way of the mouse')
	expectEq(#HK_HOOKS, 0, 'no hook')
	expectEq(ns.Restore.trackerQueued, nil, 'parking itself queued nothing')
	-- ElvUI's auto-hider: hidden frame while a boss exists, UIParent when it goes (BL:ObjectiveTracker_AutoHide)
	local hidden = CreateFrame('Frame') hidden:Hide()
	Reparent(hidden)
	expectEq(ns.Restore.trackerQueued, nil, 'a boss appears: ElvUI moves it to its hidden frame - still off screen, nothing to do')
	Reparent(UIParent)
	expectEq(OTF:GetParent(), UIParent, 'the boss gone: ElvUI brings it back on screen ...')
	expectEq(ns.Restore.trackerQueued, 'shown again', '... the sentinel sees it: one check queued')
	HK_RunTimers()
	expect(Parked(), '... and Banzai parks it again a frame later - never two trackers')
	-- several in one frame: one check
	Reparent(UIParent) Reparent(RIGHT_CONTAINER) Reparent(UIParent)
	local queued = 0
	for _, fn in ipairs(HK_TIMERS) do queued = queued + 1 end
	expectEq(queued, 1, 'one queued check, however many re-parents')
	HK_RunTimers()
	expect(Parked(), 'parked')
	-- the original parent is kept from the first park (a re-park never records a hidden frame)
	expectEq(ns.Restore.trackerParent ~= hidden, true, 'the parent to give it back to is the original one')
end)

test('1.3.1 tracker in combat: a re-parent waits for the end of combat once, then the tracker is parked; no duplicate corrections', function()
	HK_RunTimers()
	AsDruid()
	ns.Restore:TrackerOwnership('test')
	HK_IN_COMBAT = true
	Reparent(UIParent)
	HK_RunTimers()
	expectEq(OTF:GetParent(), UIParent, 'in combat: not touched')
	expectEq(ns.Restore.trackerPending, true, 'one correction waiting')
	Reparent(RIGHT_CONTAINER)
	HK_RunTimers()
	expectEq(ns.Restore.trackerPending, true, 'still one')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(ns.Restore.trackerQueued, 'PLAYER_REGEN_ENABLED', 'queued after combat')
	HK_RunTimers()
	expect(Parked(), 'parked after combat')
	expectEq(ns.Restore.trackerPending, nil, 'nothing left waiting')
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(ns.Restore.trackerQueued, nil, 'a later combat end does nothing')
end)

test('1.3.1 BANZAI Objectives OFF: Blizzard\'s tracker comes back and is left alone (the hook does nothing while the Banzai tracker is off); ON: parked again', function()
	HK_RunTimers()
	AsDruid()
	local R = ns.Restore
	R:SetTracker(false)
	expect(not Parked(), 'off: Blizzard\'s tracker back')
	Reparent(UIParent)
	expectEq(R.trackerQueued, nil, 'off: re-parents are the game\'s business')
	HK_RunTimers()
	expect(not Parked(), 'never parked while off')
	R:SetTracker(true)
	expect(Parked(), 'on: parked again')
	Reparent(UIParent)
	HK_RunTimers()
	expect(Parked(), 'and it holds')
end)

test('1.3.1 migration: a CLASSIC character\'s layer options are exactly as before (nothing rewritten at the upgrade); a SPLIT character\'s layer is rewritten once at its next login (the new split leaves, the bar thickness), its positions kept', function()
	AsDruid()
	local R = ns.Restore
	compat.frameStyle = 'CLASSIC'
	local o = R:LayerOptions()
	expectEq(o.splitLayout, nil, 'CLASSIC: no split key')
	expectEq(o.splitThickness, nil, 'CLASSIC: no thickness key')
	compat.frameStyle, compat.splitPlayerY = 'SPLIT', 333
	o = R:LayerOptions()
	expectEq(o.splitLayout, T.SPLIT.version, 'SPLIT: the layout of the split leaves is part of the signature')
	expectEq(T.SPLIT.version, 4, '1.3.1 layout (1.3.3: version 3; 1.3.4: 4)')
	expectEq(o.splitThickness, 1, 'SPLIT: the bar thickness')
	expectEq(o.splitPlayerY, 333, 'the character\'s own position kept')
	local s1 = R.Signature(o, R:Fonts())
	local o130 = T.DeepCopy(o) o130.splitLayout, o130.splitThickness, o130.splitState = nil, nil, o.splitState
	expect(R.Signature(o130, R:Fonts()) ~= s1, 'a 1.3.0 split layer signature differs: rewritten at the next login (before ElvUI builds its frames)')
	R:SetFrameStyle('SPLIT')
	local p = profile()
	expectEq(p.movers.ElvUF_PlayerMover, 'RIGHT,ElvUIParent,BOTTOM,-21,333', 'rewritten at the character\'s position')
	expectEq(p.unitframe.units.player.height, 24, 'with the thicker bars')
	compat.splitThickness = 1.25
	R:SetSplit('splitThickness', 1.25)
	expectEq(p.unitframe.units.player.height .. '/' .. p.unitframe.units.player.power.height, '30/30', 'bar thickness: both bars')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'a reload applies it')
	compat.splitThickness, compat.splitPlayerY = 1, 290
	R:SetSplit('splitThickness', 1)
	R:SetFrameStyle('CLASSIC')
end)

test('1.3.1 rollback: SPLIT -> CLASSIC still gives back exactly the classic profile with the 1.3.1 leaves (the marker, the class bar above the values), any number of times', function()
	AsDruid()
	local R = ns.Restore
	R:SetFrameStyle('CLASSIC')
	local classic = T.Serialize(profile())
	R:SetFrameStyle('SPLIT')
	expectEq(texts('player')['b-SplitName'].banzaiSplit, true, 'the 1.3.1 marker written')
	R:SetFrameStyle('CLASSIC')
	expectEq(T.Serialize(profile()), classic, 'CLASSIC: exactly the classic profile')
	expectEq(texts('player')['b-SplitName'], nil, 'no marker left')
	R:SetFrameStyle('SPLIT') R:SetFrameStyle('CLASSIC')
	expectEq(T.Serialize(profile()), classic, 'again')
end)

test('licensed BANZAI COMPACT Details: names in Shojumaru (Details\' own per-text font face, 14), values in the row font; PREVIOUS gives exactly 1.3.0\'s rows; BANZAI CURRENT untouched', function()
	local R = ns.Restore
	local face = displayFacePath
	local t131, t130 = T.DetailsCompactTexts(face), T.DetailsCompactTexts()
	expectEq(t131[1].font.face .. ' ' .. t131[1].font.size, face .. ' 14', 'the name: Shojumaru, 14')
	expectEq(tostring(t131[2].font.face) .. tostring(t131[3].font.face) .. tostring(t131[4].font.face), 'nilnilnil', 'the values: the row font')
	expectEq(t131[2].font.size, T.DETAILS_COMPACT.valueSize, 'the values: their size')
	expectEq(t130[1].font.face, nil, 'without the face: 1.3.0\'s names')
	expectEq(t130[1].font.size, T.DETAILS_COMPACT.nameSize, 'and their size')
	-- the selected display face is also used by COMPACT names; PREVIOUS remains available
	compat.displayFace = 'BANZAI_DEFAULT'
	CompatStub.Theme = TestFontTheme
	expectEq(R:CompactNameFace(), face, 'BANZAI Default resolves to Shojumaru')
	compat.displayFace = 'PREVIOUS'
	expectEq(R:CompactNameFace(), previousFacePath, 'PREVIOUS: the previous display face')
	compat.displayFace = 'BANZAI_DEFAULT'
	R:SetDetailsStyle('COMPACT')
	expectEq(HK_DetailsWindow.row_info.texts[1].font.face, face, 'live window: the names in Shojumaru')
	expectEq(BushidoPrivateRestoreDB.detailsFaceApplied, face, 'recorded')
	expectEq(R:SetDisplayFace('PREVIOUS'), 'PREVIOUS', 'the previous display font chosen')
	expectEq(compat.displayFace, 'PREVIOUS', 'a BANZAI setting (Character Sync carries it)')
	expectEq(HK_DetailsWindow.row_info.texts[1].font.face, previousFacePath, 'COMPACT follows at once')
	R:SetDisplayFace('BANZAI_DEFAULT')
	R:SetDetailsStyle('CURRENT')
	expectEq(HK_DetailsWindow.row_info.texts[1].font.face, nil, 'CURRENT: the row font as before')
	CompatStub.Theme = nil
	compat.displayFace = 'BANZAI_DEFAULT'
end)

test('licensed display-font status and texts: /banzai status identifies Shojumaru; FONTS, FRAME STYLE and ABOUT stay concise', function()
	AsDruid()
	CompatStub.Theme = TestFontTheme
	HK_PRINTS = {}
	ns.Restore:Status()
	local text = table.concat(HK_PRINTS, '\n')
	expect(string.find(text, 'BANZAI 1.5.0', 1, true), 'status: BANZAI 1.5.0')
	expect(string.find(text, 'Display font: Shojumaru at 105%, license: SIL Open Font License 1.1, registered:', 1, true), 'status: licensed Shojumaru default at 105%')
	CompatStub.Theme = nil
	local page = ns.Options:Build()
	expect(Find(page.args.appearance, 'displayFace') and Find(page.args.appearance, 'displayScale'), 'APPEARANCE > FONTS: the Banzai display font and its size')
	expect(Find(page.args.unitframes, 'thickness'), 'FRAME STYLE > BANZAI SPLIT: bar thickness')
	local credits = HK_Plain(ns.Options.CreditsText())
	expect(string.find(credits, 'Shojumaru as BANZAI Default at 105%', 1, true) and string.find(credits, 'GasoekOne as the previous display face', 1, true), 'ABOUT: selected face, fallback and previous face')
end)

-- 1.3.2 Darren's original BANZAI class identities: one concise setting, the status line, Character Sync
test('1.3.2 IDENTITY ART: one setting on UNIT FRAMES > FRAME STYLE (BANZAI default / BANZAI everywhere / FABLED / CLASS COLOUR), at once through Banzai Art; /banzai status names it and how many classes have their art; Character Sync lists it; the update message names the new art', function()
	AsDruid()
	local page = ns.Options:Build()
	local opt = Find(page.args.unitframes, 'identityArt')
	expect(opt and opt.args and opt.args.identityArt, 'UNIT FRAMES > FRAME STYLE > IDENTITY ART')
	local select = opt.args.identityArt
	expectEq(table.concat(select.sorting, ','), 'AUTO,BANZAI,FABLED,CLASS', 'four choices')
	expect(string.find(select.values.AUTO, 'default', 1, true) and select.values.CLASS == 'CLASS COLOUR', 'labelled')
	expectEq(select.get(), 'AUTO', 'AUTO until chosen')
	HK_POPUPS = {}
	select.set(nil, 'FABLED')
	expectEq(compat.identityArt, 'FABLED', 'written to Banzai Art (it repaints at once)')
	expectEq(#HK_POPUPS, 0, 'no reload asked')
	expectEq(ns.Restore:SetIdentityArt('SPARKLY'), 'AUTO', 'an unknown choice: AUTO')
	local text = HK_Plain(ns.Options.TEXT.identityArt)
	expect(string.find(text, 'nameplate', 1, true) and string.find(text, 'Details', 1, true) and string.find(text, 'never the art files', 1, true), 'says where the art is not used and what Sync carries')
	CompatStub.IdentityArtCount = function() return 13 end
	HK_PRINTS = {}
	ns.Restore:Status()
	local status = table.concat(HK_PRINTS, '\n')
	expect(string.find(status, 'identity art: AUTO, BANZAI class art for 13 of 13 classes', 1, true), '/banzai status: the choice and the 13 classes')
	CompatStub.IdentityArtCount = nil
	expect(string.find(HK_Plain(ns.Sync.OWNERSHIP[1][2]), 'identity art', 1, true), 'Character Sync: the choice is a BANZAI setting')
	ns.Restore:SetIdentityArt('AUTO')
end)

-- 1.3.3 the bamboo cast bar of the split Player / Target: three choices, the class bar above it, the 125 % hubs
test('1.3.3 SPLIT CAST BAR: one section on UNIT FRAMES > FRAME STYLE (bar, spell name, timer); the texts at once, the bar a reload key (the class bar sits above it, back above the values when it is off); the split layer with the 125 % hubs (the bars 4 further out); T.SPLIT version 3 rewrites a split character once, a CLASSIC layer is exactly as before; /banzai status and Character Sync name it', function()
	AsDruid()
	local R = ns.Restore
	local page = ns.Options:Build()
	local section = Find(page.args.unitframes, 'castBar')
	expect(section and section.args and section.args.bar and section.args.name and section.args.timer, 'UNIT FRAMES > FRAME STYLE > SPLIT CAST BAR: bar, spell name, timer')
	local text = HK_Plain(ns.Options.TEXT.castBar)
	for _, needle in ipairs({ 'replaces the class art', 'as wide as the whole frame', 'fills left to right', 'drains right to left', 'cannot be interrupted', 'INTERRUPTED', 'class art returns', 'a reload applies that part', 'Character Sync' }) do
		expect(string.find(text, needle, 1, true), 'the section says: ' .. needle)
	end
	expect(string.find(HK_Plain(ns.Options.TEXT.targetNPC), 'synthetic', 1, true), 'the TARGET NPC preview says it is synthetic')
	R:SetFrameStyle('SPLIT')
	local p = profile()
	expectEq(p.movers.ElvUF_PlayerMover .. ' | ' .. p.movers.PlayerPowerBarMover, 'RIGHT,ElvUIParent,BOTTOM,-21,290 | LEFT,ElvUIParent,BOTTOM,21,290', 'the Player bars 4 further out for the 125 % hub')
	expectEq(p.unitframe.units.player.width .. 'x' .. p.unitframe.units.player.height, '180x24', 'the bars themselves unchanged')
	expectEq(p.movers.ClassBarMover, 'BOTTOMLEFT,ElvUIParent,BOTTOM,69,360', 'the class bar above the bamboo cast bar')
	local g = T.SplitGeometry('player', R:LayerOptions())
	expectEq(g.hub .. '/' .. g.inner .. '/' .. g.castLift .. '/' .. g.castWidth, '62.5/21/35/402', 'T.SplitGeometry: Banzai Art\'s numbers')
	-- the texts: Banzai Art's alone, at once
	HK_POPUPS = {}
	section.args.name.set(nil, false)
	section.args.timer.set(nil, false)
	expectEq(tostring(compat.splitCastName) .. tostring(compat.splitCastTimer), 'falsefalse', 'spell name and timer off')
	expectEq(#HK_POPUPS, 0, 'at once: no reload')
	expectEq(section.args.name.get(), false, 'shown as chosen')
	-- the bar: a reload key (the class bar's place)
	section.args.bar.set(nil, false)
	expectEq(compat.splitCastBar, false, 'the bar off')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'a reload moves the class bar')
	expectEq(p.movers.ClassBarMover, 'BOTTOMLEFT,ElvUIParent,BOTTOM,69,323', 'the bar off: the class bar above the values again')
	section.args.bar.set(nil, true)
	expectEq(p.movers.ClassBarMover, 'BOTTOMLEFT,ElvUIParent,BOTTOM,69,360', 'on again: above the cast bar')
	expectEq(R:SetSplit('splitCastSomething', true), nil, 'only the known keys')
	-- /banzai status
	HK_PRINTS = {}
	R:Status()
	expect(string.find(table.concat(HK_PRINTS, '\n'), 'split cast bar (Player / Target): on, spell name: off, timer: off', 1, true), '/banzai status names the choices')
	section.args.name.set(nil, true)
	section.args.timer.set(nil, true)
	-- the signature: the layout version and the bar choice only in SPLIT
	local o = R:LayerOptions()
	expectEq(o.splitLayout .. '/' .. tostring(o.splitCastBar), '4/true', 'SPLIT: layout 3 and the bar choice (1.3.4: 4)')
	local o132 = T.DeepCopy(o) o132.splitLayout, o132.splitCastBar, o132.splitState = 2, nil, o.splitState
	expect(R.Signature(o132, R:Fonts()) ~= R.Signature(o, R:Fonts()), 'a 1.3.2 split layer: rewritten once at the next login')
	R:SetFrameStyle('CLASSIC')
	o = R:LayerOptions()
	expectEq(tostring(o.splitLayout) .. '/' .. tostring(o.splitCastBar), 'nil/nil', 'CLASSIC: no split key - its signature is the one it had')
	-- Character Sync
	expect(string.find(HK_Plain(ns.Sync.OWNERSHIP[1][2]), 'split cast bar (1.3.3: on / off, spell name, timer - the choices only, never a live cast)', 1, true), 'Character Sync: the choices, never a live cast')
end)

-- 1.3.4 hotfix: the PvP texts tell the truth, the lower cast bar reaches the split layer
test('1.3.4 hotfix: the PvP CC / dispel texts say the Banzai border is retired on the live frames (ElvUI\'s icon and glow stay, the level shapes the preview samples); the split layer version 4 rewrites a split character once - the class bar follows the lower cast bar down; a CLASSIC layer carries no split key', function()
	AsDruid()
	local R = ns.Restore
	for _, key in ipairs({ 'cc', 'dispel' }) do
		local text = HK_Plain(ns.Options.PVP_TEXT[key])
		expect(string.find(text, '1.3.4: Banzai no longer draws', 1, true) and string.find(text, 'preview samples only', 1, true), key .. ': says what is retired and what the setting still does')
	end
	expectEq(T.SPLIT.version, 4, 'the split layout 4')
	compat.frameStyle = 'CLASSIC'
	local o = R:LayerOptions()
	expectEq(tostring(o.splitLayout) .. '/' .. tostring(o.splitCastBar), 'nil/nil', 'CLASSIC: no split key')
	R:SetFrameStyle('SPLIT')
	local g = T.SplitGeometry('player', R:LayerOptions())
	expectEq(g.castInterior .. '/' .. g.castStalk .. '/' .. g.castLift, '22.5/4.5/35', 'the lower bar in the split layer\'s numbers')
	expectEq(profile().movers.ClassBarMover, 'BOTTOMLEFT,ElvUIParent,BOTTOM,69,360', 'the class bar just above the lower cast bar')
	R:SetFrameStyle('CLASSIC')
end)

-- 1.3.5
test('licensed selection-lock version-only update (no layer key, no setting, no reload): approved layouts and features remain unchanged', function()
	local r = record()
	expectEq(r.layer, T.LAYER, 'the current layer (nothing to rewrite)')
	r.applied.version = '1.3.4'
	HK_PRINTS, HK_POPUPS = {}, {}
	expectEq(ns.Restore:OnLogin(), true, 'the update runs at login')
	expectEq(r.applied.version, '1.5.0', 'version recorded')
	local said = table.concat(HK_PRINTS, '\n')
	expect(string.find(said, 'updated to BANZAI 1.5.0 (Retail 12.1.5 (build 69848, Interface 120105)): WoW Forever support and optional window skins there; the approved Retail layouts and features are unchanged. /banzai forever shows the client report.', 1, true), 'the update names the release and the client')
	expect(string.find(said, '/banzai forever shows the client report', 1, true), 'and where the client report is')
	expectEq(#HK_POPUPS, 0, 'no reload needed')
	expectEq(r.layer, T.LAYER, 'the layer as it was')
	expectEq(T.SPLIT.version, 4, 'the split layer unchanged (no rewrite at login)')
	expectEq(table.concat(T.DETAILS_STYLE.text, ','), '1,1,1,1', 'Details\' row text white on glass / solid, as before')
	expectEq(table.concat(T.DETAILS_STYLE.ink, ','), '0.96,0.95,0.92,1', 'the parchment ink as before')
	expectEq(ns.Restore:OnLogin(), nil, 'once')
end)

-- 1.3.6
test('1.3.6 the Details centre gutter: the two windows equally narrower (207.5, was 212) across a 15-unit gutter (was 6; 20 screen pixels at 2560 x 1440, UI scale 0.71) - their outer edges and the composition\'s width as in 1.3.5; every row (track, bar, name, values, the COMPACT icon) inside its own window; a version-only update from 1.3.5 places the windows again on Banzai\'s Details profile only - geometry only (what each shows, its segment, open or closed stay) - and after combat when it is on', function()
	local L = T.DETAILS_LAYOUT
	local left, right = HK_DetailsWindow, HK_DetailsWindow2
	local PX = 0.71 * 1440 / 768
	local R = ns.Restore
	expectEq(L.width .. '/' .. L.gap .. '/' .. L.right, '207.5/15/-47.15', 'narrower windows, a real gutter, the right edge kept')
	expectEq(2 * L.width + L.gap, 2 * 212 + 6, 'as wide as the 1.3.5 composition (430)')
	expect(math.abs(L.gap * PX - 20) < 0.05, 'the gutter about 20 screen pixels at Darren\'s scale')
	R:LayoutDetails()
	expectEq(right.libwindow.x, -47.15, 'the right window\'s right edge where it was')
	expectEq(left.libwindow.x - L.width, -47.15 - 212 - 6 - 212, 'the left window\'s left edge where it was')
	expectNear(left.posicao.normal.w, right.posicao.normal.w, 'the two meters equally wide')
	expectNear(left.posicao.normal.w * left.window_scale, 207.5, '207.5 on screen (window scale 0.75)')
	local gutter = (right.libwindow.x - L.width) - left.libwindow.x
	expectNear(gutter, 15, 'the gutter between the left window\'s right edge and the right window\'s left edge')
	-- every row inside its own window: Details anchors a row at the window's left edge + space.left + row_offsets.left and
	-- makes it the window's width + space.right + row_offsets.right; the texts sit on the bar (names in from its left end, values in from its right end)
	local d = Details.profiles[NAME]
	local function inside(row, label)
		expect(row.space.left >= 0 and row.space.right <= 0, label .. ': the row starts and ends inside the window (space ' .. tostring(row.space.left) .. ' / ' .. tostring(row.space.right) .. ')')
		expect(row.row_offsets.left >= 0 and row.row_offsets.right <= 0, label .. ': no row offset past the window edges')
		for k = 1, 4 do
			local a = row.texts[k].anchor
			expectEq(a.relativeTo, 'statusbar', label .. ': text ' .. k .. ' on the bar')
			if k == 1 then expect(a.x >= 0, label .. ': the name in from the bar\'s left end') else expect(a.x <= 0, label .. ': value ' .. k .. ' in from the bar\'s right end') end
		end
	end
	for i = 1, 2 do
		local window = d.instances[i]
		expectEq(window.show_sidebars, false, 'window ' .. i .. ': no side bars reaching out of it')
		inside(window.row_info, 'window ' .. i .. ' CURRENT')
		local compact = T.DetailsCompactRow(T.DeepCopy(window.row_info), T.DETAILS_ICONS.discs)
		inside(compact, 'window ' .. i .. ' COMPACT')
		expect(compact.icon_offset[1] >= 0 and compact.start_after_icon == false, 'window ' .. i .. ' COMPACT: the icon at the row\'s own start')
		inside(T.DetailsCurrentRow(T.DeepCopy(window.row_info), {}), 'window ' .. i .. ' back to CURRENT')
	end
	-- what the profile writer itself makes of Bushido's own profile, CURRENT and COMPACT
	for _, style in ipairs({ 'CURRENT', 'COMPACT' }) do
		local fresh = T.DeepCopy(P.detailsProfile)
		T.StyleDetailsWindows(fresh, true, nil, style, T.DETAILS_ICONS.discs)
		for i = 1, 2 do inside(fresh.instances[i].row_info, 'the profile writer, window ' .. i .. ' ' .. style) end
	end
	-- a version-only update from 1.3.5 (1.3.5's windows): placed again, geometry only
	local r = record()
	local function old()
		for _, w in ipairs({ left, right }) do w.posicao.normal.w = 212 / 0.75 end
		left.libwindow.x = -47.15 - 212 - 6
	end
	old()
	right.display = { 7, 3, 1 } -- Darren switched the right window to another display and segment
	left.ativa = false -- and closed the left one
	r.applied.version = '1.3.5'
	HK_PRINTS, HK_POPUPS = {}, {}
	local n0 = #HK_TIMERS
	expectEq(R:OnLogin(), true, 'the update runs at login')
	expectEq(r.applied.version, '1.5.0', 'version recorded')
	expect(string.find(table.concat(HK_PRINTS, '\n'), 'updated to BANZAI 1.5.0 (Retail 12.1.5', 1, true), 'the chat names the release and the client')
	expectEq(#HK_POPUPS, 0, 'no reload needed')
	expectNear(left.posicao.normal.w, 207.5 / 0.75, 'left window narrower')
	expectNear(right.posicao.normal.w, 207.5 / 0.75, 'right window narrower')
	expectEq(left.libwindow.x, -47.15 - 207.5 - 15, 'left window across the gutter')
	expectEq(right.libwindow.x, -47.15, 'right window where it was')
	expectEq(table.concat(right.display, ','), '7,3,1', 'what the right window shows and its segment untouched')
	expectEq(left.ativa, false, 'a closed window stays closed')
	expect(#HK_TIMERS > n0, 'placed once more after Details has settled')
	for i = n0 + 1, #HK_TIMERS do HK_TIMERS[i]() end
	expectEq(table.concat(right.display, ',') .. '/' .. tostring(left.ativa), '7,3,1/false', 'the later pass geometry only too')
	expectEq(R:OnLogin(), nil, 'once')
	-- another Details profile: its windows are not Banzai's to move
	old()
	r.applied.version = '1.3.5'
	Details.current = 'DarrenUI'
	R:OnLogin()
	expectEq(left.libwindow.x, -47.15 - 212 - 6, 'another Details profile: nothing moved')
	Details.current = NAME
	-- in combat: after combat ends
	old()
	r.applied.version = '1.3.5'
	HK_IN_COMBAT = true
	R:OnLogin()
	expectEq(left.libwindow.x, -47.15 - 212 - 6, 'in combat: nothing moved yet')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(left.libwindow.x, -47.15 - 207.5 - 15, 'placed when combat ends')
	expectEq(table.concat(right.display, ',') .. '/' .. tostring(left.ativa), '7,3,1/false', 'still geometry only')
	expectEq(R.detailsGeometryPending, nil, 'once')
	-- the full arrangement (APPLY, Arrange side by side) still opens both and shows DAMAGE | HEALING
	local oldLeftDisplay, oldRightDisplay = left.SetDisplay, right.SetDisplay
	left.SetDisplay = function(self, ...)
		oldLeftDisplay(self, ...)
		self.posicao.normal.w, self.libwindow.x = 1, 999
	end
	right.SetDisplay = function(self, ...)
		oldRightDisplay(self, ...)
		self.posicao.normal.w, self.libwindow.x = 1, 999
	end
	local oldIsForever = ns.Flavor.IsForever
	ns.Flavor.IsForever = function() return true end
	R:LayoutDetails()
	ns.Flavor.IsForever = oldIsForever
	expectNear(left.posicao.normal.w, 207.5 / 0.75, 'left geometry is reapplied after Details reflows its display')
	expectNear(right.posicao.normal.w, 207.5 / 0.75, 'right geometry is reapplied after Details reflows its display')
	expectEq(left.libwindow.x, -47.15 - 207.5 - 15, 'left anchor survives display reflow')
	expectEq(right.libwindow.x, -47.15, 'right anchor survives display reflow')
	left.SetDisplay, right.SetDisplay = oldLeftDisplay, oldRightDisplay
	expectEq(left.ativa, true, 'opened')
	expectEq(left.display[2] .. '|' .. right.display[2], '1|2', 'DAMAGE | HEALING')
end)
