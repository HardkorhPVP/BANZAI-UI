-- 1.5.0-dev1: the client adapter (shared/Flavor.lua, Transform T.AdaptConditions / T.AdaptProfile) on RETAIL:
-- the pure functions, and the proof that Retail's own behaviour is the 1.4.0 one (nothing is adapted there).
HK_LOADED.BushidoPrivateCompat = true
local ns = HK_NS
local T = ns.Transform
local P = ns.Payloads
local Flavor = ns.Flavor
local E = ElvUI[1]
local NAME = 'JiberishUI - Bushido Private'

BanzaiCompat = {
	Get = function() return nil end, Set = function() return true end, GetTheme = function() return 'VIBRANT' end,
	Export = function() return { marker = 1 } end, Import = function() return true end,
	Roles = function() return {} end, RoleState = function() return {} end, PanelStyle = function() return 'BANZAI', 'GLASS', 1 end,
}
for key in pairs(P.detailsProfile) do Details.default_profile[key] = true end

test('the client: Retail is detected, and nothing of WoW Forever applies', function()
	expectEq(Flavor.Id(), 'RETAIL', 'client')
	expectEq(Flavor.IsForever(), false, 'not Forever')
	expectEq(Flavor.IsRetail(), true, 'Retail')
	expectEq(Flavor.ClientText(), 'Retail 12.1.5 (build 69848, Interface 120105)', 'client text')
	for _, feature in ipairs({ 'specialization', 'specRole', 'inspectSpecialization', 'lootSpecialization', 'conquest', 'mastery', 'versatility', 'petBattles' }) do
		expectEq(Flavor.Has(feature), true, feature .. ' exists on Retail')
	end
	expectEq(T.CLIENTS.RETAIL, nil, 'Retail has no adapter rules')
end)

test('the client is decided explicitly: the project constant, else ElvUI\'s own flag, else the interface number', function()
	local id, camelot = WOW_PROJECT_ID, WOW_PROJECT_CAMELOT
	WOW_PROJECT_ID = 18
	expectEq(Flavor.Id(), 'FOREVER', 'camelot project')
	WOW_PROJECT_ID = 2
	expectEq(Flavor.Id(), 'RETAIL', 'another project is not Forever')
	WOW_PROJECT_ID, WOW_PROJECT_CAMELOT = nil, nil
	expectEq(Flavor.Id(), 'RETAIL', 'no constants: never Forever by accident')
	-- should the project constant be renamed: ElvUI's own flag, then the interface the client reports
	E.Forever = true
	expectEq(Flavor.Id(), 'FOREVER', 'ElvUI says Forever')
	E.Forever = false
	expectEq(Flavor.Id(), 'RETAIL', 'ElvUI says not Forever')
	E.Forever = nil
	local build = GetBuildInfo
	GetBuildInfo = function() return '1.60.1', '70862', 'Nov 3 2026', 16001 end
	expectEq(Flavor.Id(), 'FOREVER', 'Interface 16001')
	GetBuildInfo = function() return '1.15.9', '1', 'x', 11509 end
	expectEq(Flavor.Id(), 'RETAIL', 'Classic Era is not Forever')
	GetBuildInfo = function() return '1.70.0', '1', 'x', 17000 end
	expectEq(Flavor.Id(), 'RETAIL', 'only 160xx')
	GetBuildInfo = function() error('refused') end
	expectEq(Flavor.Id(), 'RETAIL', 'a refused call is not Forever')
	GetBuildInfo = build
	WOW_PROJECT_ID, WOW_PROJECT_CAMELOT = id, camelot
	expectEq(Flavor.Id(), 'RETAIL', 'put back')
end)

test('Retail: the player\'s specialization is the client\'s own (the 1.4.0 source), never the talent reading', function()
	local spec = Flavor.PlayerSpec()
	expectEq(spec.name, 'Feral', 'name')
	expectEq(spec.id, 103, 'id')
	expectEq(spec.role, 'DAMAGER', 'role')
	expectEq(spec.source, 'specialization', 'source')
	expectEq(spec.points, nil, 'no talent points on Retail')
	local roles = ns.Roles.Spec()
	expectEq(roles.name, 'Feral', 'Roles.Spec unchanged')
	expectEq(roles.id, 103, 'Roles.Spec id')
	expectEq(roles.layout, 'DPS', 'layout')
	HK_SPEC_INDEX = 4
	expectEq(ns.Roles.Spec().layout, 'HEALER', 'a healing spec still gets the HEALER layout on Retail')
	expectEq(Flavor.PlayerSpec().role, 'HEALER', 'role follows the spec')
	HK_SPEC_INDEX = 2
end)

-- every default the installed ElvUI 16.01 gives Retail and WoW Forever differently for a macro condition
-- (its Defaults/Profile.lua evaluated under both clients): the adapter must turn the first into the second
local ELVUI_DEFAULTS = {
	{ 'actionbar.bar1.visibility', '[petbattle] hide; show', 'show' },
	{ 'actionbar.bar2.visibility', '[vehicleui][petbattle][overridebar] hide; show', '[vehicleui][overridebar] hide; show' },
	{ 'actionbar.barPet.visibility', '[petbattle] hide; [novehicleui,pet,nooverridebar,nopossessbar] show; hide', '[novehicleui,pet,nooverridebar,nopossessbar] show; hide' },
	{ 'actionbar.microbar.visibility', '[petbattle] hide; show', 'show' },
	{ 'actionbar.stanceBar.visibility', '[vehicleui][petbattle] hide; show', '[vehicleui] hide; show' },
	{ 'bags.bagBar.visibility', '[petbattle] hide; show', 'show' },
}

test('macro conditions: every Retail default of the installed ElvUI becomes its WoW Forever default', function()
	for _, row in ipairs(ELVUI_DEFAULTS) do
		local adapted, removed = T.AdaptConditions(row[2], 'FOREVER')
		expectEq(adapted, row[3], row[1])
		expectEq(table.concat(removed, ','), 'petbattle', row[1] .. ' removed')
	end
end)

test('macro conditions: the Banzai profile\'s own bar visibilities (Bushido\'s spacing and separate clauses)', function()
	expectEq(T.AdaptConditions('[petbattle]  hide; show', 'FOREVER'), 'show', 'bar 1')
	expectEq(T.AdaptConditions('[vehicleui] hide; [petbattle] hide; [overridebar] hide; show;', 'FOREVER'), '[vehicleui] hide; [overridebar] hide; show;', 'bars 3 / 5 / 6')
end)

test('macro conditions: a bracket that can never be true goes, a condition that is always true goes alone', function()
	expectEq(T.AdaptConditions('[vehicleui,petbattle] hide; show', 'FOREVER'), 'show', 'AND with petbattle is never true')
	expectEq(T.AdaptConditions('[petbattle][vehicleui]hide;show', 'FOREVER'), '[vehicleui]hide;show', 'the other bracket and its spacing kept')
	expectEq(T.AdaptConditions('[nopetbattle] show; hide', 'FOREVER'), '[] show; hide', 'always true: an unconditional bracket')
	expectEq(T.AdaptConditions('[combat, nopetbattle] show; hide', 'FOREVER'), '[combat] show; hide', 'the other condition kept')
	expectEq(T.AdaptConditions('[PetBattle] hide; show', 'FOREVER'), 'show', 'case does not matter')
	expectEq(T.AdaptConditions('[petbattle:1] hide; show', 'FOREVER'), 'show', 'an argument does not hide it')
end)

test('macro conditions: what the client cannot answer leaves the setting out; an emptied setting is left out too', function()
	local adapted, removed = T.AdaptConditions('[form:1, spec:3] 7;', 'FOREVER')
	expectEq(adapted, nil, 'spec paging cannot be carried over')
	expectEq(removed[1], 'spec', 'why')
	expectEq(T.AdaptConditions('[bonusbar:1] 7; [nospec:2] 8;', 'FOREVER'), nil, 'nospec too')
	expectEq(T.AdaptConditions('[petbattle] hide', 'FOREVER'), nil, 'nothing left to say')
	expectEq(T.AdaptConditions('[petbattle] hide;', 'FOREVER'), nil, 'nothing but a separator left')
end)

test('macro conditions: a string that needs nothing of the client comes back untouched (the same string)', function()
	for _, text in ipairs({ 'show', '[@raid6,noexists][@raid21,exists] hide;show', '[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8; [bonusbar:2] 10;',
		'[vehicleui][overridebar] hide; show', '[novehicleui,pet,nooverridebar,nopossessbar] show; hide', '', '[form:1] 7;' }) do
		local adapted, removed = T.AdaptConditions(text, 'FOREVER')
		expectEq(adapted, text, 'unchanged: ' .. text)
		expectEq(#removed, 0, 'nothing removed: ' .. text)
	end
	expectEq(T.AdaptConditions(nil, 'FOREVER'), nil, 'not a string')
	expectEq(T.AdaptConditions(42, 'FOREVER'), 42, 'a number is handed back')
end)

test('macro conditions: Retail (and any client without rules) is never adapted', function()
	for _, row in ipairs(ELVUI_DEFAULTS) do
		expectEq(T.AdaptConditions(row[2], 'RETAIL'), row[2], 'Retail keeps ' .. row[1])
		expectEq(T.AdaptConditions(row[2], nil), row[2], 'no client keeps ' .. row[1])
	end
	expectEq(T.AdaptConditions('[form:1, spec:3] 7;', 'RETAIL'), '[form:1, spec:3] 7;', 'Retail keeps its spec paging')
end)

test('tag names are read as ElvUI\'s tag parser reads them', function()
	expectEq(T.TagName('[perhp<%]'), 'perhp', 'suffix')
	expectEq(T.TagName('[ - >mMT-level]'), 'mMT-level', 'prefix')
	expectEq(T.TagName('[mMT-level<||r]'), 'mMT-level', 'suffix with an escape')
	expectEq(T.TagName('[name:eltruism:gradientshortcaps{10}]'), 'name:eltruism:gradientshortcaps', 'arguments')
	expectEq(T.TagName('[mMT-health:current:short]'), 'mMT-health:current:short', 'plain')
	expectEq(T.TagName('[]'), nil, 'empty')
	expectEq(T.TagName(nil), nil, 'not a string')
end)

local function Sample()
	return {
		actionbar = {
			bar1 = { visibility = '[petbattle]  hide; show', paging = { DRUID = '[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8;', PRIEST = '[form:1, spec:3] 7;' }, enabled = true },
			bar3 = { visibility = '[vehicleui] hide; [petbattle] hide; [overridebar] hide; show;' },
			bar4 = { visibility = '[vehicleui][overridebar] hide; show' },
		},
		chat = { note = 'a text that says [petbattle] is no setting' },
		datatexts = { panels = { LeftChatDataPanel = { 'mTeleports', 'Durability', '' }, Bushido = { enable = false } } },
		unitframe = { units = {
			player = { customTexts = { ['m-Health'] = { text_format = '[mMT-health:current:short]' }, ['b-Pct'] = { text_format = '|cffdde3e8[perhp<%]|r' } } },
			raid1 = { visibility = '[@raid6,noexists][@raid21,exists] hide;show' },
		} },
		nameplates = { units = { ENEMY_NPC = { name = { format = '[mMT-color][name:abbrev]' } } } },
	}
end

test('profile names: the datatexts and tags a profile uses, each once, sorted', function()
	local names = T.ProfileNames(Sample())
	expectEq(table.concat(names.datatexts, '|'), 'Durability|mTeleports', 'datatexts (an empty slot is none)')
	expectEq(table.concat(names.tags, '|'), 'mMT-color|mMT-health:current:short|name:abbrev|perhp', 'tags')
	expectEq(#T.ProfileNames(nil).tags, 0, 'no profile')
end)

test('profile adapter: Retail is left exactly as it is, with an empty report', function()
	local sample = Sample()
	local before = T.Serialize(sample)
	local report = T.AdaptProfile(sample, 'RETAIL', { datatexts = { mTeleports = false }, tags = { perhp = false } })
	expectEq(T.Serialize(sample), before, 'untouched')
	expectEq(#report.changes, 0, 'no changes')
	expectEq(#report.notes, 0, 'no notes')
	expectEq(report.flavor, 'RETAIL', 'flavor')
	expectEq(#T.AdaptProfile(sample, nil).changes, 0, 'no client')
	expectEq(#T.AdaptProfile(nil, 'FOREVER').changes, 0, 'no profile')
end)

test('profile adapter (WoW Forever): only the macro conditions change; the report says what and why', function()
	local sample = Sample()
	local report = T.AdaptProfile(sample, 'FOREVER')
	expectEq(sample.actionbar.bar1.visibility, 'show', 'bar 1')
	expectEq(sample.actionbar.bar3.visibility, '[vehicleui] hide; [overridebar] hide; show;', 'bar 3')
	expectEq(sample.actionbar.bar4.visibility, '[vehicleui][overridebar] hide; show', 'bar 4 untouched')
	expectEq(sample.actionbar.bar1.paging.DRUID, '[bonusbar:1,nostealth] 7; [bonusbar:1,stealth] 8;', 'druid paging untouched')
	expectEq(sample.actionbar.bar1.paging.PRIEST, nil, 'spec paging left out (ElvUI\'s default stands)')
	expectEq(sample.actionbar.bar1.enabled, true, 'other settings untouched')
	expectEq(sample.chat.note, 'a text that says [petbattle] is no setting', 'only visibility / paging settings are read')
	expectEq(sample.unitframe.units.raid1.visibility, '[@raid6,noexists][@raid21,exists] hide;show', 'raid visibility untouched')
	expectEq(sample.datatexts.panels.LeftChatDataPanel[1], 'mTeleports', 'datatexts are never rewritten')
	expectEq(sample.unitframe.units.player.customTexts['m-Health'].text_format, '[mMT-health:current:short]', 'text formats are never rewritten')
	expectEq(#report.changes, 3, 'three changes')
	expectEq(report.changes[1].path, 'actionbar.bar1.paging.PRIEST', 'sorted by path: first')
	expectEq(report.changes[1].to, nil, 'left out')
	expectEq(report.changes[1].from, '[form:1, spec:3] 7;', 'what it was')
	expect(string.find(report.changes[1].reason, 'talent trees', 1, true), 'why (spec)')
	expectEq(report.changes[2].path, 'actionbar.bar1.visibility', 'second')
	expectEq(report.changes[2].from, '[petbattle]  hide; show', 'from')
	expectEq(report.changes[2].to, 'show', 'to')
	expect(string.find(report.changes[2].reason, 'pet battles', 1, true), 'why (petbattle)')
	expectEq(report.changes[3].path, 'actionbar.bar3.visibility', 'third')
	expectEq(#report.notes, 0, 'nothing asked of the client: no notes')
end)

test('profile adapter: idempotent and deterministic', function()
	local a, b = Sample(), Sample()
	local first, again = T.AdaptProfile(a, 'FOREVER'), T.AdaptProfile(b, 'FOREVER')
	expectEq(T.Serialize(a), T.Serialize(b), 'the same profile from the same input')
	expectEq(T.Serialize(first), T.Serialize(again), 'the same report from the same input')
	local after = T.Serialize(a)
	local second = T.AdaptProfile(a, 'FOREVER')
	expectEq(#second.changes, 0, 'a second run changes nothing')
	expectEq(T.Serialize(a), after, 'and leaves the profile as it is')
end)

test('profile adapter: a name the installed client does not register is reported, never rewritten', function()
	local sample = Sample()
	local report = T.AdaptProfile(sample, 'FOREVER', { datatexts = { mTeleports = false, Durability = true }, tags = { ['mMT-health:current:short'] = false, perhp = true, ['mMT-color'] = true } })
	expectEq(#report.notes, 2, 'two notes')
	expectEq(report.notes[1].path, 'datatexts.panels.LeftChatDataPanel.1', 'datatext path')
	expectEq(report.notes[1].value, 'mTeleports', 'datatext name')
	expectEq(report.notes[2].path, 'unitframe.units.player.customTexts.m-Health.text_format', 'tag path')
	expectEq(report.notes[2].value, 'mMT-health:current:short', 'tag name')
	expectEq(sample.datatexts.panels.LeftChatDataPanel[1], 'mTeleports', 'the datatext stays')
	expectEq(sample.unitframe.units.player.customTexts['m-Health'].text_format, '[mMT-health:current:short]', 'the format stays')
	-- a name the client was not asked about (nil) is not reported
	expectEq(#T.AdaptProfile(Sample(), 'FOREVER', { datatexts = {}, tags = {} }).notes, 0, 'unknown is not "missing"')
end)

test('the Banzai profile as built from the payloads: exactly four settings differ for WoW Forever', function()
	local profile = T.TransformProfile(P.elvuiProfile, T.FONT, function() return true end, T.SMALL_FONT, {})
	local before = T.DeepCopy(profile)
	local report = T.AdaptProfile(profile, 'FOREVER')
	local paths = {}
	for _, change in ipairs(report.changes) do paths[#paths + 1] = change.path .. '=' .. tostring(change.to) end
	expectEq(table.concat(paths, ' | '), 'actionbar.bar1.visibility=show\n | actionbar.bar3.visibility=[vehicleui] hide; [overridebar] hide; show; | actionbar.bar5.visibility=[vehicleui] hide; [overridebar] hide; show; | actionbar.bar6.visibility=[vehicleui] hide; [overridebar] hide; show;', 'the four bar visibilities')
	-- everything else is the Retail profile, leaf for leaf
	for _, change in ipairs(report.changes) do
		local bar = string.match(change.path, '^actionbar%.(bar%d)%.visibility$')
		before.actionbar[bar].visibility = profile.actionbar[bar].visibility
	end
	expectEq(T.Serialize(profile), T.Serialize(before), 'nothing else differs from the Retail profile')
	expectEq(HK_FindString(profile, 'petbattle'), nil, 'no pet battle condition is left anywhere')
end)

test('Retail: APPLY BANZAI writes the profile as 1.4.0 did - nothing is adapted, nothing is recorded', function()
	expectEq(ns.Restore:AdaptClient('test', true), nil, 'no adapter runs on Retail')
	ns.Restore:Apply('first login')
	HK_RunTimers()
	local profile = ElvDB.profiles[NAME]
	expectEq(E.data:GetCurrentProfile(), NAME, 'applied')
	expectEq(profile.actionbar.bar1.visibility, '[petbattle]  hide; show\n', 'bar 1 keeps Retail\'s pet battle condition (and the historical line break)')
	expectEq(profile.actionbar.bar3.visibility, '[vehicleui] hide; [petbattle] hide; [overridebar] hide; show;', 'bar 3 too')
	expectEq(BushidoPrivateRestoreDB.client, nil, 'no client record on Retail')
end)

test('version: BANZAI 1.5.0, a release, named with the client everywhere it is shown', function()
	expectEq(ns.VERSION, '1.5.0', 'version')
	expectEq(ns.CHANNEL, 'release', 'channel')
	HK_PRINTS = {}
	ns.Restore:Status()
	expect(string.find(HK_PRINTS[1], 'BANZAI 1.5.0 (release; Retail 12.1.5 (build 69848, Interface 120105); profile source 624839aa)', 1, true), 'status line: ' .. tostring(HK_PRINTS[1]))
	expect(string.find(StaticPopupDialogs.BANZAI_RELOAD.text, 'BANZAI 1.5.0', 1, true), 'reload dialog')
	local home = HK_Plain(ns.Options.HomeText())
	expect(string.find(home, 'VERSION   BANZAI 1.5.0   release', 1, true), 'HOME version')
	expect(string.find(home, 'CLIENT   Retail 12.1.5', 1, true), 'HOME client')
	expect(string.find(home, 'SPECIALIZATION   Feral', 1, true), 'HOME keeps SPECIALIZATION on Retail')
	expect(string.find(home, 'SPEC ROLE   DPS', 1, true), 'HOME keeps SPEC ROLE on Retail')
	expectEq(ElvDB.profiles[NAME] ~= nil and BushidoPrivateRestoreDB.characters[E.mynameRealm].applied.version, '1.5.0', 'the applied record carries it')
	HK_PRINTS = {}
	SlashCmdList.BANZAI('')
	expect(string.find(HK_PRINTS[1], 'BANZAI 1.5.0 (release, Retail 12.1.5', 1, true), '/banzai: ' .. tostring(HK_PRINTS[1]))
end)

test('prerequisites: each is checked against what Banzai uses; Retail is never blocked by the list', function()
	local pre = ns.Restore:Preflight()
	expectEq(pre.flavor, 'RETAIL', 'flavor')
	expectEq(pre.version, '1.5.0', 'version')
	local byName = {}
	for _, item in ipairs(pre.items) do byName[item.name] = item end
	expectEq(byName.ElvUI.state, 'READY', 'ElvUI')
	expectEq(byName.ElvUI.required, true, 'ElvUI is required')
	expectEq(byName['Banzai Art'].state, 'READY', 'Banzai Art')
	expectEq(byName.JiberishMedia.state, 'READY', 'JiberishMedia (its fonts are registered)')
	expectEq(byName.Details.state, 'READY', 'Details')
	expectEq(byName.Details.required, false, 'Details is optional')
	-- the mocks register no mMediaTag tag: loaded, but what Banzai uses is not there
	expectEq(byName['mMediaTag & Tools'].state, 'NOT READY', 'mMediaTag without its tag')
	expect(string.find(byName['mMediaTag & Tools'].detail, 'mMT-health:current:short', 1, true), 'what is missing')
	expectEq(byName['mMT Media Pack'].state, 'NOT INSTALLED', 'an optional addon that is not installed')
	HK_PRINTS = {}
	SlashCmdList.BANZAI('forever')
	local text = table.concat(HK_PRINTS, '\n')
	expect(string.find(text, 'BANZAI 1.5.0 (release) on Retail 12.1.5', 1, true), '/banzai forever names the build and the client')
	expect(string.find(text, 'client adapter: none needed on this client', 1, true), 'no adapter on Retail')
	expect(string.find(text, 'Details 1.0: READY', 1, true), 'a component line with its version')
end)

-- 1.5.0: the window skins and the Forever chat adapter are a WoW Forever proof - on Retail the Restore side
-- writes nothing for them, shows no page for them, and the minimap-button placement is 1.4.0's
test('Retail (1.5.0): no WINDOW SKINS page, no ElvUI panel colour written, the minimap button placed as 1.4.0 did', function()
	local released = 0
	BanzaiCompat.Skins = { Supported = function() return false end, PanelColor = function() return { r = 0, g = 1, b = 0, a = 1 } end,
		Report = function() return { 'window skins: WoW Forever only in this build - nothing is skinned on this client.' } end }
	BanzaiCompat.ChatLayout = { Release = function() released = released + 1 return 0 end, StatusText = function() return 'not used on this client' end }
	local profile = ElvDB.profiles[NAME]
	expectEq(type(profile), 'table', 'the Banzai profile from the earlier apply')
	local before = T.Serialize(profile.general or false)
	local getter = BanzaiCompat.Get
	BanzaiCompat.Get = function(_, key) if key == 'skinElvUI' then return true end return getter(_, key) end
	expectEq(ns.Restore:ApplyElvUIPanels(), 'not on this client', 'ELVUI PANELS does nothing on Retail')
	expectEq(ns.Restore:SetWindowSkin('skinElvUI', true), true, 'the switch itself is only a setting')
	expectEq(T.Serialize(profile.general or false), before, 'the profile\'s panel colour is untouched')
	expectEq(BushidoPrivateRestoreDB.elvuiPanels, nil, 'nothing recorded')
	BanzaiCompat.Get = getter
	ns.Options.Insert()
	local section = E.Options.args.banzai.args.appearance.args.windowSkins
	expectEq(type(section), 'table', 'the section is defined once for both clients')
	expectEq(section.hidden(), true, 'and hidden on Retail')
	expectEq(E.Options.args.banzai.args.appearance.args.panelStyle.hidden, nil, 'the approved sections are not hidden')
	-- the minimap button collector: Retail keeps 1.4.0's placement (top-right corner, recorded for the restore)
	MinimapButtonButtonOptions = { scale = 8, position = { 'TOPRIGHT', nil, 'TOPRIGHT', 0, -237.5 } }
	local record = { previous = {} }
	expectEq(ns.Restore:PlaceMinimapButton(record), 'in the top-right corner', 'placed as before')
	expectNear(MinimapButtonButtonOptions.position[5], -2.5, 'the corner')
	expectEq(record.previous.minimapButton.y, -237.5, 'what it was is recorded')
	expectEq(released, 0, 'the chat adapter was not asked for anything')
	BanzaiCompat.Skins, BanzaiCompat.ChatLayout = nil, nil
end)
