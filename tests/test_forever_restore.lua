-- 1.5.0-dev1: Banzai (BushidoPrivateRestore) on WoW Forever 1.60.1 - the mocks stand in for the Forever client
-- (HK_FLAVOR = 'forever': no GetSpecialization globals, talents as a trait configuration, no pet battles).
HK_LOADED.BushidoPrivateCompat = true
HK_LOADED.ElvUI_Libraries = true
HK_INSTALLED.ElvUI_Options = 'DEMAND_LOADED' -- installed, loads when the settings open
-- Darren's Forever install has neither Kaliel's Tracker nor the minimap button collector
KalielsTrackerDB, MinimapButtonButtonOptions = nil, nil
HK_INSTALLED['!KalielsTracker'] = nil

local ns = HK_NS
local T = ns.Transform
local P = ns.Payloads
local Flavor = ns.Flavor
local E = ElvUI[1]
local NAME = 'JiberishUI - Bushido Private'
local KEY = 'Darrensdrood - Stormrage'
local FOREVER_BARS = '[vehicleui] hide; [overridebar] hide; show;'

for key in pairs(P.detailsProfile) do Details.default_profile[key] = true end
local settings = { tracker = true }
BanzaiCompat = {
	Get = function(_, key) return settings[key] end, Set = function(_, key, value) settings[key] = value return true end,
	GetTheme = function() return 'VIBRANT' end, SetTheme = function() return true end,
	Export = function()
		local out = T.DeepCopy(settings)
		out.roleState, out.foreverRoleOverride = nil, nil
		return out
	end,
	Import = function(_, values) for k, v in pairs(values) do settings[k] = v end return true end,
	Roles = function() settings.roles = settings.roles or {} return settings.roles end,
	RoleState = function() settings.roleState = settings.roleState or {} return settings.roleState end,
	ForeverRoleOverride = function(_, value)
		if value == 'AUTO' then settings.foreverRoleOverride = nil
		elseif value then settings.foreverRoleOverride = value end
		return settings.foreverRoleOverride or 'AUTO'
	end,
	PanelStyle = function() return 'BANZAI', 'GLASS', 1 end,
}

local function record() return BushidoPrivateRestoreDB and BushidoPrivateRestoreDB.characters and BushidoPrivateRestoreDB.characters[KEY] end
local function profile() return ElvDB.profiles[NAME] end
local function prints() return table.concat(HK_PRINTS, '\n') end
-- the pre-Banzai state of this character, as text
local function Baseline()
	return T.Serialize({
		elvProfile = E.data:GetCurrentProfile(), hardkorhui = ElvDB.profiles.HARDKORHUI, breezy = ElvDB.profiles.breezy,
		privateKey = ElvPrivateDB.profileKeys[KEY], privateBreezy = ElvPrivateDB.profiles.breezy, global = ElvDB.global,
		details = Details.current, detailsProfiles = { DarrenUI = Details.profiles.DarrenUI }, detailsException = Details.always_use_profile_exception.Darrensdrood or false,
		history = Details.mythic_plus_log, trackerParent = ObjectiveTrackerFrame:GetParent() == UIParent, trackerCollapsed = ObjectiveTrackerFrame:IsCollapsed(),
	})
end
local BASELINE = Baseline()

test('the client: WoW Forever is detected explicitly', function()
	expectEq(Flavor.Id(), 'FOREVER', 'client')
	expectEq(Flavor.IsForever(), true, 'Forever')
	expectEq(Flavor.ClientText(), 'WoW Forever 1.60.1 (build 70862, Interface 16001)', 'client text')
	expectEq(GetSpecialization, nil, 'the deprecated specialization globals are not there (as in the client)')
	expectEq(GetSpecializationInfo, nil, 'nor this one')
	for _, feature in ipairs({ 'specialization', 'specRole', 'inspectSpecialization', 'lootSpecialization', 'conquest', 'mastery', 'versatility', 'pvpItemLevel', 'petBattles' }) do
		expectEq(Flavor.Has(feature), false, feature .. ' is not on WoW Forever')
	end
	expectEq(Flavor.Has('honor'), true, 'what is not listed exists')
end)

test('talent trees: the game\'s own order, names, icons and committed points', function()
	local trees = Flavor.TalentTrees()
	expectEq(#trees, 3, 'three trees')
	expectEq(trees[1].name .. '|' .. trees[2].name .. '|' .. trees[3].name, 'Balance|Feral Combat|Restoration', 'ordered by the game\'s order index, not the list order')
	expectEq(trees[2].points, 31, 'points')
	expectEq(trees[2].icon, 132115, 'icon')
	expectEq(trees[2].index, 2, 'index')
	expectEq(Flavor.PointsText(trees), '0 / 31 / 20', 'points text')
	local tree = Flavor.TalentTree()
	expectEq(tree.name, 'Feral Combat', 'the leading tree')
end)

test('talent trees: nothing is guessed - a tie, no points, pending edits or a missing answer give no spec', function()
	local trees = HK_TALENTS.trees
	local restoration, feral = trees[1], trees[3]
	restoration.spent = 31
	expectEq(Flavor.TalentTree(), nil, 'a tie has no leading tree')
	expectEq(Flavor.PlayerSpec(), nil, 'so no spec')
	restoration.spent, feral.spent = 0, 0
	expectEq(Flavor.TalentTree(), nil, 'no points spent')
	restoration.spent, feral.spent = 20, 31
	expectEq(Flavor.TalentTree().name, 'Feral Combat', 'back')
	-- a single tree is only named once a point is in it (no points is not "a spec")
	local all = HK_TALENTS.trees
	HK_TALENTS.trees = { { groupID = 21, displayName = 'Only Tree', icon = 1, orderIndex = 1, spent = 0 } }
	expectEq(Flavor.TalentTree(), nil, 'one tree, no points: nothing is named')
	HK_TALENTS.trees[1].spent = 1
	expectEq(Flavor.TalentTree().name, 'Only Tree', 'one tree with a point is the leading tree')
	HK_TALENTS.trees = all
	expectEq(Flavor.TalentTree().name, 'Feral Combat', 'the druid again')
	-- points being edited in the talent window are not counted: the last committed answer stands
	HK_TALENTS.staged = true
	feral.spent = 0
	expectEq(Flavor.TalentTree().name, 'Feral Combat', 'pending edits keep the committed tree')
	HK_TALENTS.staged = false
	feral.spent = 31
	-- a secret or malformed answer is no answer
	local display = C_Traits.GetGroupDisplayInfoByTreeID
	C_Traits.GetGroupDisplayInfoByTreeID = function() return HK_Secret('displays') end
	expectEq(Flavor.TalentTrees(), nil, 'secret display data')
	C_Traits.GetGroupDisplayInfoByTreeID = function() return { { groupID = 11, displayName = '' } } end
	expectEq(Flavor.TalentTrees(), nil, 'a tree without a name')
	C_Traits.GetGroupDisplayInfoByTreeID = function() error('refused') end
	expectEq(Flavor.TalentTrees(), nil, 'a refused call')
	C_Traits.GetGroupDisplayInfoByTreeID = display
	local currency = C_Traits.GetGroupCurrencyInfo
	C_Traits.GetGroupCurrencyInfo = function() return { { traitNodeGroupID = 11, currencyInfos = { { spent = HK_Secret('spent') } } } } end
	expectEq(Flavor.TalentTrees(), nil, 'secret points')
	-- a tree answered twice is no answer; a tree with no points row has none spent (as Jiberish Icons reads this client)
	C_Traits.GetGroupCurrencyInfo = function() return { { traitNodeGroupID = 12, currencyInfos = { { spent = 31 } } }, { traitNodeGroupID = 12, currencyInfos = { { spent = 5 } } } } end
	expectEq(Flavor.TalentTrees(), nil, 'a tree answered twice')
	C_Traits.GetGroupCurrencyInfo = function() return { { traitNodeGroupID = 12, currencyInfos = { { spent = 31 } } } } end
	expectEq(Flavor.PointsText(Flavor.TalentTrees()), '0 / 31 / 0', 'a tree without a points row has none spent')
	C_Traits.GetGroupCurrencyInfo = currency
	-- pending edits keep the committed answer of that configuration only, never another one's
	expectEq(Flavor.TalentTree().name, 'Feral Combat', 'configuration 501 confirmed')
	HK_CONFIGS[1], HK_TALENTS.staged = 502, true
	expectEq(Flavor.TalentTrees(), nil, 'another configuration being edited: nothing was confirmed for it')
	HK_CONFIGS[1], HK_TALENTS.staged = 501, false
	local group = HK_SPEC_GROUP
	HK_SPEC_GROUP = nil
	expectEq(Flavor.TalentTree().name, 'Feral Combat', 'the class-talent configuration answers when the spec group does not')
	HK_SPEC_GROUP = group
	local traits = C_Traits
	C_Traits = nil
	expectEq(Flavor.TalentTrees(), nil, 'no trait API')
	expectEq(Flavor.PlayerSpec(), nil, 'no spec without it')
	C_Traits = traits
	expectEq(Flavor.TalentTree().name, 'Feral Combat', 'and back again')
end)

test('the spec shown is the leading talent tree: its name and icon, no ID, no role - and never the starter spec', function()
	HK_STARTER_CALLS = 0
	local spec = Flavor.PlayerSpec()
	expectEq(spec.name, 'Feral Combat', 'name')
	expectEq(spec.icon, 132115, 'icon')
	expectEq(spec.source, 'talents', 'source')
	expectEq(spec.points, '0 / 31 / 20', 'points')
	expectEq(spec.id, nil, 'no specialization ID')
	expectEq(spec.role, nil, 'no role')
	local roles = ns.Roles.Spec()
	expectEq(roles.name, 'Feral Combat', 'Roles.Spec')
	expectEq(roles.role, 'DPS', 'Feral keeps the available DPS layout while its tree is ambiguous')
	expectEq(roles.layout, 'DPS', 'the frame layout stays DPS')
	expectEq(ns.Roles.Current(), 'DPS', 'current layout')
	local detection = ns.Roles:Detection()
	expectEq(detection.role, nil, 'Feral is not auto-classified as DPS or tank')
	expect(string.find(detection.reason, 'ambiguous', 1, true), 'the ambiguity is reported')
	expectEq(ns.Roles:Override(), 'AUTO', 'override is local and automatic by default')
	expectEq(ns.Roles:SetOverride('HEALER'), true, 'explicit local override')
	expectEq(ns.Roles.Current(), 'HEALER', 'override selects the healer layout')
	expectEq(ns.Roles:SetOverride('AUTO'), true, 'return to automatic')
	expectEq(ns.Roles.Current(), 'DPS', 'ambiguous Feral returns to the last safe layout')
	expectEq(ns.Roles.ClassifyForever({ index = 1 }, 'SHAMAN'), nil, 'unverified class maps stay unmapped')
	local who = ns.Sync:Identity()
	expectEq(who.spec, 'Feral Combat', 'Character Sync names the tree')
	expectEq(who.role, 'DPS', 'and the DPS layout')
	local home = HK_Plain(ns.Options.HomeText())
	expect(string.find(home, 'TALENT TREE   Feral Combat  (0 / 31 / 20)', 1, true), 'HOME: ' .. home)
	expect(string.find(home, 'FRAME LAYOUT   DPS', 1, true), 'HOME layout')
	expect(not string.find(home, 'STARTER', 1, true), 'the starter specialization is never shown')
	expectEq(HK_STARTER_CALLS, 0, 'C_SpecializationInfo\'s selected specialization was never read')
	-- a restoration druid is not made a HEALER by inference
	HK_TALENTS.trees[1].spent = 40
	expectEq(Flavor.PlayerSpec().name, 'Restoration', 'restoration leads')
	expectEq(ns.Roles.Spec().layout, 'HEALER', 'the verified Restoration tree selects the HEALER layout')
	expectEq(ns.Roles.Current(), 'HEALER', 'the detected layout')
	HK_TALENTS.trees[1].spent = 20
end)

test('prerequisites on WoW Forever: every one answers; each is checked against what Banzai uses', function()
	E.oUF.Tags.Methods['mMT-health:current:short'] = function() end
	E.oUF.Tags.Methods['name:eltruism:gradientshortcaps'] = function() end
	local media = LibStub('LibSharedMedia-3.0')
	media:Register('statusbar', 'mMediaTag S1', 'x')
	HK_LOADED['!mMT_MediaPack'] = true
	JiberishIcons = { { GetIdentityIcon = function() end } }
	local pre = ns.Restore:Preflight()
	expectEq(pre.blocked, nil, 'not blocked')
	expectEq(pre.flavor, 'FOREVER', 'flavor')
	expectEq(pre.client, 'WoW Forever 1.60.1 (build 70862, Interface 16001)', 'client')
	local states = {}
	for _, item in ipairs(pre.items) do states[#states + 1] = item.name .. '=' .. item.state end
	expectEq(table.concat(states, '; '), 'ElvUI=READY; ElvUI Libraries=READY; ElvUI Options=ON DEMAND; Banzai Art=READY; JiberishMedia=READY; mMediaTag & Tools=READY; Eltruism=READY; Jiberish Icons=READY; Details=READY; mMT Media Pack=READY', 'every component')
	local lines = table.concat(ns.Restore:PreflightLines(), '\n')
	expect(string.find(lines, 'BANZAI 1.5.0 (release) on WoW Forever 1.60.1 (build 70862, Interface 16001)', 1, true), 'headline')
	expect(string.find(lines, 'Every required component is ready.', 1, true), 'ready')
	local text = HK_Plain(ns.Options.ClientText())
	expect(string.find(text, 'CLIENT   WoW Forever 1.60.1', 1, true), 'settings: client')
	expect(string.find(text, 'Details   READY   v1.0', 1, true), 'settings: a component with its version')
	-- a loaded addon whose part Banzai uses is not there is NOT READY, with what is missing
	E.oUF.Tags.Methods['mMT-health:current:short'] = nil
	local byName = {}
	for _, item in ipairs(ns.Restore:Preflight().items) do byName[item.name] = item end
	expectEq(byName['mMediaTag & Tools'].state, 'NOT READY', 'the tag Banzai uses is gone')
	expect(string.find(byName['mMediaTag & Tools'].detail, 'mMT-health:current:short', 1, true), 'named')
	expectEq(ns.Restore:Preflight().blocked, nil, 'an optional component never blocks')
	E.oUF.Tags.Methods['mMT-health:current:short'] = function() end
end)

test('a missing required component: Banzai is not applied and nothing at all is written', function()
	local media = LibStub('LibSharedMedia-3.0')
	local isValid = media.IsValid
	media.IsValid = function(self, kind, name) if kind == 'font' and name == T.SMALL_FONT then return false end return isValid(self, kind, name) end
	local pre = ns.Restore:Preflight()
	expect(pre.blocked and string.find(pre.blocked, 'JiberishMedia NOT READY', 1, true), 'blocked: ' .. tostring(pre.blocked))
	HK_PRINTS, HK_POPUPS = {}, {}
	local ok = ns.Restore:ApplyHere('manual')
	expectEq(ok, false, 'not applied')
	expectEq(profile(), nil, 'no Banzai profile was created')
	expectEq(E.data:GetCurrentProfile(), 'HARDKORHUI', 'the ElvUI profile is untouched')
	expectEq(#HK_POPUPS, 0, 'no reload prompt')
	expectEq(record() and record().applied, nil, 'nothing marked as applied')
	expectEq(Baseline(), BASELINE, 'the character is exactly as it was')
	-- nothing was recorded either: a later apply takes its pre-Banzai snapshot then, not from this attempt
	expectEq(record() and record().previous, nil, 'no pre-Banzai snapshot is left behind')
	expectEq(record() and record().syncBackup, nil, 'and no settings backup')
	expectEq(ns.Restore:Apply('manual'), false, 'the direct apply is stopped as well')
	expectEq(profile(), nil, 'still no Banzai profile')
	expectEq(record() and record().previous, nil, 'still nothing recorded')
	expectEq(Baseline(), BASELINE, 'still exactly as it was')
	media.IsValid = isValid
	HK_LOADED.ElvUI_Libraries = false
	expect(string.find(tostring(ns.Restore:Preflight().blocked), 'ElvUI Libraries MISSING', 1, true), 'a required addon that is not loaded')
	HK_LOADED.ElvUI_Libraries = true
	expectEq(ns.Restore:Preflight().blocked, nil, 'ready again')
end)

test('Character Sync blocks unknown or mismatched client flavors before any backup or settings write', function()
	local S = ns.Sync
	expectEq(S:Config().flavor, 'FOREVER', 'the captured configuration identifies its client')
	S:Master()
	local db = BushidoPrivateRestoreDB
	db.sync.master = { key = 'Other - Realm', revision = 1, config = { flavor = 'RETAIL', settings = { glassOpacity = 0.1 } } }
	local before = Baseline()
	local ok, message = S:Apply()
	expectEq(ok, false, 'mismatched master rejected')
	expect(string.find(message, 'client flavor mismatch', 1, true), 'reason is explicit: ' .. tostring(message))
	expectEq(record() and record().previous, nil, 'no pre-Banzai snapshot')
	expectEq(record() and record().syncBackup, nil, 'no sync backup')
	expectEq(Baseline(), before, 'the character and ElvUI profile are untouched')
	db.sync.master.config = { settings = { glassOpacity = 0.1 } }
	ok, message = S:Apply()
	expectEq(ok, false, 'legacy flavorless master rejected')
	expect(string.find(message, 'no client flavor', 1, true), 'legacy configuration asks to be recaptured')
	expectEq(record() and record().previous, nil, 'still no snapshot')
	local preview = S:Preview()
	expectEq(preview.compatible, false, 'the dry run blocks the mismatched master')
	expect(string.find(HK_Plain(ns.Options.SyncPreviewText()), 'no client flavor', 1, true), 'the dry run reports the block')
	db.sync.master = nil
	preview = S:Preview()
	expectEq(preview.compatible, true, 'without a master, local apply remains available')
	expect(string.find(HK_Plain(ns.Options.SyncPreviewText()), 'PRESERVED ON THIS CHARACTER', 1, true), 'dry-run preview lists preserved local settings')
end)

test('APPLY BANZAI on WoW Forever: the profile is written, adapted to the client, and the pre-Banzai state recorded', function()
	HK_PRINTS, HK_POPUPS = {}, {}
	local ok = ns.Restore:ApplyHere('manual')
	HK_RunTimers()
	expectEq(ok, true, 'applied: ' .. prints())
	expectEq(E.data:GetCurrentProfile(), NAME, 'the Banzai profile is active')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload prompt')
	expectEq(record().applied.version, '1.5.0', 'version recorded')
	expectEq(record().layer, T.LAYER, 'layer recorded')
	-- the client adapter: the pet battle condition is gone from every bar
	expectEq(profile().actionbar.bar1.visibility, 'show\n', 'bar 1 (the historical line break is not the adapter\'s to remove)')
	expectEq(profile().actionbar.bar3.visibility, FOREVER_BARS, 'bar 3')
	expectEq(profile().actionbar.bar5.visibility, FOREVER_BARS, 'bar 5')
	expectEq(profile().actionbar.bar6.visibility, FOREVER_BARS, 'bar 6')
	expectEq(HK_FindString(profile(), 'petbattle'), nil, 'no pet battle condition anywhere in the profile')
	-- everything else is the profile Retail gets
	expectEq(profile().unitframe.units.player.width > 0, true, 'unit frames written')
	expectEq(profile().unitframe.units.player.customTexts['m-Health'].text_format, '[mMT-health:current:short]', 'health text as on Retail')
	-- the pre-Banzai record
	local previous = record().previous
	expectEq(previous.elvProfile, 'HARDKORHUI', 'previous ElvUI profile')
	expectEq(previous.privateProfile, 'breezy', 'previous private profile')
	expectEq(previous.details, 'DarrenUI', 'previous Details profile')
	expectEq(type(record().syncBackup.settings), 'table', 'this character\'s own BANZAI settings backed up')
	-- existing profiles are untouched
	expectEq(ElvDB.profiles.HARDKORHUI.marker, 'darren-hardkorhui', 'HARDKORHUI untouched')
	expectEq(ElvPrivateDB.profiles.breezy.install_complete, 16, 'the old private profile untouched')
	expectEq(Details.profiles.DarrenUI.marker, 'darren-details', 'the old Details profile untouched')
	-- the report
	local report = BushidoPrivateRestoreDB.client.report
	expectEq(report.flavor, 'FOREVER', 'report flavor')
	expectEq(report.version, '1.5.0', 'report version')
	expectEq(report.client, 'WoW Forever 1.60.1 (build 70862, Interface 16001)', 'report client')
	expectEq(#report.changes, 4, 'four settings adapted')
	expectEq(report.changes[1].path, 'actionbar.bar1.visibility', 'first')
	expectEq(report.changes[1].from, '[petbattle]  hide; show\n', 'from')
	expectEq(report.changes[1].to, 'show\n', 'to')
	expectEq(BushidoPrivateRestoreDB.client.error, nil, 'no adapter error')
	-- optional addons that are not installed are simply left out
	expect(string.find(prints(), 'Kaliel\'s Tracker: ', 1, true), 'the apply message')
	expectEq(KalielsTrackerDB, nil, 'no Kaliel settings were created')
	expectEq(MinimapButtonButtonOptions, nil, 'no minimap collector settings were created')
end)

test('the client report names what this client does not register - and rewrites none of it', function()
	local before = T.Serialize(profile())
	-- the mocks' ElvUI has no DataTexts module: nothing is said about datatexts
	local notes = BushidoPrivateRestoreDB.client.report.notes
	for _, note in ipairs(notes) do expect(not string.find(note.path, '^datatexts'), 'no datatext note without a registry') end
	-- with ElvUI's registry: the three mMediaTag 3.x names the historical profile still carries are reported
	local getModule = E.GetModule
	E.GetModule = function(self, name, silent)
		if name == 'DataTexts' then return { RegisteredDataTexts = { Durability = {}, Time = {}, Combat = {} } } end
		return getModule(self, name, silent)
	end
	local report = ns.Restore:AdaptClient('test', true)
	E.GetModule = getModule
	local datatexts, tags = {}, {}
	for _, note in ipairs(report.notes) do
		if string.find(note.path, '^datatexts') then datatexts[#datatexts + 1] = note.value else tags[note.value] = true end
	end
	table.sort(datatexts)
	expectEq(table.concat(datatexts, '|'), 'mGameMenu|mProfessions|mTeleports', 'unregistered datatexts')
	expectEq(tags['mMT-health:current:short'], nil, 'a registered tag is not reported')
	expectEq(tags['name:eltruism:gradientshortcaps'], nil, 'nor this one')
	expectEq(tags['mMT-role:icon'], true, 'a tag the client does not register is')
	expectEq(#report.changes, 0, 'nothing left to adapt')
	expectEq(#BushidoPrivateRestoreDB.client.report.changes, 4, 'what was adapted when the profile was written stays on record')
	expectEq(T.Serialize(profile()), before, 'the profile itself is not rewritten for a note')
	HK_PRINTS = {}
	SlashCmdList.BANZAI('forever')
	local text = prints()
	expect(string.find(text, 'client adapter (', 1, true), '/banzai forever: the adapter')
	expect(string.find(text, 'actionbar.bar1.visibility: "[petbattle]  hide; show\\n" -> "show\\n"', 1, true), 'the change (a line break is shown, not printed): ' .. text)
	expect(string.find(text, 'talent tree shown as the spec: Feral Combat (0 / 31 / 20)', 1, true), 'the talent tree')
	expect(string.find(text, 'not on WoW Forever, so left out', 1, true), 'what is left out')
	HK_PRINTS = {}
	ns.Restore:Status()
	expect(string.find(HK_PRINTS[1], 'BANZAI 1.5.0 (release; WoW Forever 1.60.1 (build 70862, Interface 16001); profile source 624839aa)', 1, true), 'status: ' .. tostring(HK_PRINTS[1]))
	expect(string.find(prints(), 'talent tree layout: DPS (Feral Combat)', 1, true), 'status names the tree and selected layout')
end)

test('a later write of the shared profile stays adapted (the character layer at the next login)', function()
	-- another character / other settings wrote the profile last, and a Retail-only value came back with it
	BushidoPrivateRestoreDB.layerOwner = { key = 'Someone - Else', signature = 'other' }
	profile().actionbar.bar1.visibility = '[petbattle]  hide; show'
	ns.Restore:CharacterLayer(KEY)
	expectEq(profile().actionbar.bar1.visibility, 'show', 'adapted again with the layer write')
	expectEq(BushidoPrivateRestoreDB.layerOwner.key, KEY, 'this character\'s layer')
	local report = BushidoPrivateRestoreDB.client.report
	expectEq(#report.changes, 5, 'added to the report')
	expectEq(report.changes[5].path, 'actionbar.bar1.visibility', 'what')
	expect(report.updated ~= nil, 'when')
	ns.Restore:OnAddonLoaded()
	expectEq(#BushidoPrivateRestoreDB.client.report.changes, 5, 'nothing more to do: idempotent')
	-- the same character and settings (no layer to write), but the profile holds a Retail value: one carried
	-- over from Retail, or written by an earlier build. It is adapted while the addons load all the same.
	profile().actionbar.bar3.visibility = '[vehicleui] hide; [petbattle] hide; [overridebar] hide; show;'
	ns.Restore:OnAddonLoaded()
	expectEq(profile().actionbar.bar3.visibility, FOREVER_BARS, 'adapted at load although no layer was written')
	expectEq(#BushidoPrivateRestoreDB.client.report.changes, 6, 'and reported')
	ns.Restore:OnAddonLoaded()
	expectEq(#BushidoPrivateRestoreDB.client.report.changes, 6, 'once')
end)

test('RESTORE PRE-BANZAI on WoW Forever: the character is exactly as it was before Banzai', function()
	expectEq(E.data:GetCurrentProfile(), NAME, 'on Banzai')
	expect(Baseline() ~= BASELINE, 'Banzai changed the character')
	HK_PRINTS, HK_POPUPS = {}, {}
	local ok = ns.Restore:Revert()
	HK_RunTimers()
	expectEq(ok, true, 'restored')
	expectEq(Baseline(), BASELINE, 'the pre-Banzai state, leaf for leaf')
	expectEq(E.data:GetCurrentProfile(), 'HARDKORHUI', 'ElvUI profile')
	expectEq(ElvPrivateDB.profileKeys[KEY], 'breezy', 'private profile')
	expectEq(ElvDB.global.general.UIScale, 0.5333333333333333, 'UI scale')
	expectEq(Details.current, 'DarrenUI', 'Details profile')
	expectEq(record().applied, nil, 'no longer applied')
	expectEq(record().previous, nil, 'the record is spent')
	expect(record().restored ~= nil, 'restored at')
	expectEq(HK_POPUPS[#HK_POPUPS], 'BANZAI_RELOAD', 'reload prompt')
	expectEq(type(profile()), 'table', 'the Banzai profile stays stored for another apply')
	expectEq(ns.Restore:Revert(), false, 'a second restore has nothing to do')
	expectEq(Baseline(), BASELINE, 'and changes nothing')
end)

test('APPLY BANZAI again after a restore: the same result, and a restore brings the baseline back again', function()
	local stored = T.Serialize(profile())
	HK_PRINTS, HK_POPUPS = {}, {}
	local ok = ns.Restore:ApplyHere('manual')
	HK_RunTimers()
	expectEq(ok, true, 'applied again: ' .. prints())
	expectEq(E.data:GetCurrentProfile(), NAME, 'on Banzai again')
	expectEq(profile().actionbar.bar1.visibility, 'show', 'still adapted')
	expectEq(HK_FindString(profile(), 'petbattle'), nil, 'no pet battle condition')
	expectEq(T.Serialize(profile()), stored, 'the shared profile is the same one (idempotent)')
	expectEq(record().previous.elvProfile, 'HARDKORHUI', 'the pre-Banzai record was taken again')
	expectEq(#BushidoPrivateRestoreDB.client.report.changes > 0, true, 'the adapter report is kept')
	-- applying on top of an applied character is a repair, not a second layer
	ns.Restore:ApplyHere('manual')
	HK_RunTimers()
	expectEq(record().previous.elvProfile, 'HARDKORHUI', 'the pre-Banzai record is never overwritten by a re-apply')
	expectEq(ns.Restore:Revert(), true, 'restored again')
	HK_RunTimers()
	expectEq(Baseline(), BASELINE, 'the pre-Banzai state again')
end)

test('missing optional addons degrade honestly: no Details, no mMediaTag, no Jiberish Icons, no Eltruism', function()
	local details, icons = Details, JiberishIcons
	Details, JiberishIcons = nil, nil
	HK_LOADED.Details, HK_LOADED.ElvUI_mMediaTag, HK_LOADED.JiberishIcons, HK_LOADED.ElvUI_EltreumUI = false, false, false, false
	local pre = ns.Restore:Preflight()
	expectEq(pre.blocked, nil, 'still not blocked')
	local byName = {}
	for _, item in ipairs(pre.items) do byName[item.name] = item.state end
	expectEq(byName.Details, 'NOT INSTALLED', 'Details')
	expectEq(byName['mMediaTag & Tools'], 'NOT INSTALLED', 'mMediaTag')
	expectEq(byName['Jiberish Icons'], 'NOT INSTALLED', 'Jiberish Icons')
	expectEq(byName.Eltruism, 'NOT INSTALLED', 'Eltruism')
	HK_PRINTS, HK_POPUPS = {}, {}
	local ok = ns.Restore:ApplyHere('manual')
	HK_RunTimers()
	expectEq(ok, true, 'applied without them: ' .. prints())
	expect(string.find(prints(), 'Details: skipped (Details not loaded)', 1, true), 'Details is skipped, and said so')
	expectEq(record().previous.details, nil, 'no Details profile recorded')
	expectEq(ns.Restore:Revert(), true, 'restored')
	HK_RunTimers()
	Details, JiberishIcons = details, icons
	HK_LOADED.Details, HK_LOADED.ElvUI_mMediaTag, HK_LOADED.JiberishIcons, HK_LOADED.ElvUI_EltreumUI = true, true, true, true
	expectEq(Baseline(), BASELINE, 'the pre-Banzai state')
end)

test('a failing client adapter never stops Banzai: the profile is left as written and the error is kept', function()
	local adapt = T.AdaptProfile
	T.AdaptProfile = function() error('adapter broke') end
	ElvDB.profiles[NAME] = nil -- a fresh profile
	BushidoPrivateRestoreDB.client = nil
	local ok = ns.Restore:ApplyHere('manual')
	HK_RunTimers()
	T.AdaptProfile = adapt
	expectEq(ok, true, 'applied')
	expectEq(E.data:GetCurrentProfile(), NAME, 'on Banzai')
	expect(string.find(BushidoPrivateRestoreDB.client.error.text, 'adapter broke', 1, true), 'the error is recorded')
	HK_PRINTS = {}
	SlashCmdList.BANZAI('forever')
	expect(string.find(prints(), 'client adapter ERROR', 1, true), 'and shown')
	-- the next write repairs it
	expectEq(#ns.Restore:AdaptClient('repair', true).changes, 4, 'adapted on the next run')
	expectEq(BushidoPrivateRestoreDB.client.error, nil, 'the error is cleared')
	expectEq(profile().actionbar.bar1.visibility, 'show\n', 'bar 1')
	expectEq(ns.Restore:Revert(), true, 'restored')
	HK_RunTimers()
	expectEq(Baseline(), BASELINE, 'the pre-Banzai state')
end)

test('the settings open on WoW Forever and name the release and the client', function()
	ns.Options.Insert()
	local page = E.Options.args.banzai
	expectEq(type(page), 'table', 'the BANZAI page')
	expect(string.find(HK_Plain(page.args.brand.name()), 'BANZAI 1.5.0', 1, true), 'brand version')
	expect(string.find(HK_Plain(page.args.brand.name()), 'release', 1, true), 'brand channel')
	expect(not string.find(HK_Plain(page.args.brand.name()), 'PROOF', 1, true), 'no proof label')
	expect(string.find(HK_Plain(page.args.home.args.status.name()), 'CLIENT   WoW Forever 1.60.1 (build 70862, Interface 16001)', 1, true), 'HOME client')
	expect(string.find(HK_Plain(page.args.home.args.client.args.list.name()), 'Every required component is ready.', 1, true), 'HOME prerequisites')
	expect(string.find(HK_Plain(page.args.about.args.version.name), 'Release for Retail and WoW Forever; this client: WoW Forever 1.60.1 (build 70862, Interface 16001).', 1, true), 'ABOUT')
	expect(not string.find(HK_Plain(page.args.about.args.version.name), 'proof', 1, true), 'not called a proof build')
	HK_PRINTS = {}
	SlashCmdList.BANZAI('')
	expect(string.find(HK_PRINTS[1], 'BANZAI 1.5.0 (release, WoW Forever 1.60.1', 1, true), '/banzai: ' .. tostring(HK_PRINTS[1]))
end)

test('Banzai never touches gameplay data on WoW Forever either', function()
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no binding, macro, talent, action or gear call: ' .. table.concat(HK_GAMEPLAY_CALLS, ','))
	expectEq(HK_STARTER_CALLS, 0, 'and the starter specialization was never read')
end)

---------------------------------------------------------------------------
-- 1.5.0: the window skins' Restore side - the ELVUI PANELS profile colour, the chat windows handed back
-- by RESTORE PRE-BANZAI, the minimap-button addon left alone, the WINDOW SKINS page, the status lines
---------------------------------------------------------------------------
local skinLog = {}
local TONE = { r = 0.015, g = 0.075, b = 0.045, a = 0.82 }
BanzaiCompat.Skins = {
	Supported = function() return true end,
	PanelColor = function() return { r = TONE.r, g = TONE.g, b = TONE.b, a = settings.panelBackground == 'SOLID' and 0.97 or TONE.a } end,
	Report = function() return { 'Blizzard Windows: on - Character SKINNED 1', 'Zygor: on - Zygor guide viewer SKINNED 1' } end,
}
BanzaiCompat.ChatLayout = {
	Release = function(_, reason) skinLog[#skinLog + 1] = 'release:' .. tostring(reason) .. ':' .. E.data:GetCurrentProfile() return 1 end,
	StatusText = function() return 'General in the BANZAI CHAT frame; docked by BANZAI: Loot / Trade' end,
}
BanzaiCompat.MinimapButtonManager = function() return HK_LOADED.MinimapButtonButton and 'MinimapButtonButton' or nil end
local mediaUpdates, templateUpdates = 0, 0
function E:UpdateMedia() mediaUpdates = mediaUpdates + 1 end
function E:UpdateFrameTemplates() templateUpdates = templateUpdates + 1 end
local function fade() local g = profile().general return g and g.backdropfadecolor end

test('window skins: a switch is a Banzai Art setting; only the four known switches are accepted', function()
	expectEq(ns.Restore:SetWindowSkin('skinBlizzard', false), true, 'accepted')
	expectEq(settings.skinBlizzard, false, 'written to Banzai Art')
	expectEq(ns.Restore:SetWindowSkin('skinBlizzard', true), true, 'on again')
	expectEq(settings.skinBlizzard, true, 'written')
	expectEq(ns.Restore:SetWindowSkin('skinZygor', false), true, 'Zygor on its own')
	expectEq(settings.skinBlizzard, true, 'the Blizzard switch is not touched by the Zygor one')
	expectEq(settings.skinBaganator, nil, 'nor the Baganator one')
	settings.skinZygor = true
	expectEq(ns.Restore:SetWindowSkin('chatFrame', false), false, 'not a window-skin switch here')
	expectEq(ns.Restore:SetWindowSkin('tracker', false), false, 'nor any other setting')
	expectEq(settings.tracker, true, 'and nothing was written')
end)

test('ELVUI PANELS: the Banzai profile\'s panel colour follows the switch and the material; off puts ElvUI\'s colour back', function()
	HK_PRINTS, HK_POPUPS = {}, {}
	expectEq(ns.Restore:ApplyHere('manual'), true, 'applied: ' .. prints())
	HK_RunTimers()
	local before = T.Serialize(fade())
	local others = T.Serialize({ ElvDB.profiles.HARDKORHUI, ElvDB.profiles.breezy })
	mediaUpdates, templateUpdates = 0, 0
	expectEq(ns.Restore:ApplyElvUIPanels(), 'unchanged', 'off by default: nothing is written')
	expectEq(T.Serialize(fade()), before, 'the approved panel colour stays')
	expectEq(BushidoPrivateRestoreDB.elvuiPanels, nil, 'nothing recorded')
	expectEq(mediaUpdates, 0, 'ElvUI is not asked to recolour')
	-- on: the BANZAI tone, what was there kept once, ElvUI recolours its own panels
	ns.Restore:SetWindowSkin('skinElvUI', true)
	expectNear(fade().g, TONE.g, 'the BANZAI glass colour')
	expectNear(fade().a, TONE.a, 'at the glass alpha')
	expectEq(T.Serialize(BushidoPrivateRestoreDB.elvuiPanels.previous or false), before, 'the profile\'s own colour is kept')
	expectEq(mediaUpdates .. '/' .. templateUpdates, '1/1', 'ElvUI\'s own two calls, once')
	expectEq(ns.Restore:ApplyElvUIPanels(), 'unchanged', 'idempotent')
	expectEq(mediaUpdates, 1, 'no second recolour')
	-- the material: ElvUI's panels follow it
	settings.panelBackground = 'SOLID'
	ns.Restore:SetPanelBackground('SOLID')
	expectNear(fade().a, 0.97, 'the solid tone')
	expectEq(T.Serialize(BushidoPrivateRestoreDB.elvuiPanels.previous or false), before, 'the kept colour is still the profile\'s own, not BANZAI\'s')
	settings.panelBackground = 'GLASS'
	ns.Restore:SetPanelBackground('GLASS')
	-- a rebuilt profile (APPLY / repair) carries the tone again
	expectEq(ns.Restore:Apply('repair'), true, 'repaired')
	HK_RunTimers()
	expectNear(fade().a, TONE.a, 'the tone is written into the rebuilt profile')
	-- only ever the Banzai profile
	expectEq(T.Serialize({ ElvDB.profiles.HARDKORHUI, ElvDB.profiles.breezy }), others, 'no other profile is written')
	-- off: ElvUI's colour as the profile had it
	ns.Restore:SetWindowSkin('skinElvUI', false)
	expectEq(T.Serialize(fade()), before, 'the profile\'s own panel colour is back')
	expectEq(BushidoPrivateRestoreDB.elvuiPanels, nil, 'record spent')
	-- in combat the profile is still written, ElvUI is not asked to recolour (it does at the next update)
	mediaUpdates = 0
	HK_IN_COMBAT = true
	ns.Restore:SetWindowSkin('skinElvUI', true)
	expectNear(fade().a, TONE.a, 'written')
	expectEq(mediaUpdates, 0, 'no ElvUI call in combat')
	HK_IN_COMBAT = false
	ns.Restore:SetWindowSkin('skinElvUI', false)
	-- on a client the window skins are not for, nothing is written
	BanzaiCompat.Skins.Supported = function() return false end
	settings.skinElvUI = true
	expectEq(ns.Restore:ApplyElvUIPanels(), 'not on this client', 'not on this client')
	expectEq(T.Serialize(fade()), before, 'nothing written')
	settings.skinElvUI = false
	BanzaiCompat.Skins.Supported = function() return true end
end)

test('RESTORE PRE-BANZAI with the window skins on: the chat windows are handed back first, the baseline is exact', function()
	settings.skinBlizzard, settings.skinBaganator, settings.skinZygor = true, true, true
	ns.Restore:SetWindowSkin('skinElvUI', true)
	skinLog = {}
	expectEq(E.data:GetCurrentProfile(), NAME, 'on Banzai')
	local ok = ns.Restore:Revert()
	HK_RunTimers()
	expectEq(ok, true, 'restored')
	expectEq(#skinLog, 1, 'the chat adapter was asked once')
	expectEq(skinLog[1], 'release:restore:' .. NAME, 'before the profile was switched away from Banzai')
	expectEq(record().chatReleased, 1, 'how many windows went back is on record')
	expectEq(Baseline(), BASELINE, 'the pre-Banzai state, leaf for leaf')
	expectEq(E.data:GetCurrentProfile(), 'HARDKORHUI', 'the character\'s own profile')
	expectEq(ElvDB.profiles.HARDKORHUI.general, nil, 'no panel colour was written into the character\'s own profile')
	-- a chat adapter that fails never stops the restore
	expectEq(ns.Restore:ApplyHere('manual'), true, 'applied again')
	HK_RunTimers()
	local release = BanzaiCompat.ChatLayout.Release
	BanzaiCompat.ChatLayout.Release = function() error('chat adapter failed') end
	expectEq(ns.Restore:Revert(), true, 'restored despite the failure')
	HK_RunTimers()
	expectEq(record().chatReleased, nil, 'nothing claimed')
	expectEq(Baseline(), BASELINE, 'the pre-Banzai state again')
	BanzaiCompat.ChatLayout.Release = release
	-- What a restore leaves, said plainly: BANZAI's own things only. The ELVUI PANELS choice is still on (a Banzai
	-- Art setting), so the Banzai profile still carries the BANZAI tone and what it replaced is still on record -
	-- neither is part of the character's own setup, which the baseline above proves untouched.
	expectEq(settings.skinElvUI, true, 'the switch is still the character\'s BANZAI preference')
	expectNear(fade().a, TONE.a, 'the Banzai profile keeps the tone for the next APPLY')
	expectEq(type(BushidoPrivateRestoreDB.elvuiPanels), 'table', 'and what it replaced is kept with it')
	-- switching it off while the character is on its own profile writes the Banzai profile only, and asks ElvUI for nothing
	mediaUpdates = 0
	ns.Restore:SetWindowSkin('skinElvUI', false)
	expectEq(BushidoPrivateRestoreDB.elvuiPanels, nil, 'record spent')
	expectEq(mediaUpdates, 0, 'ElvUI is not asked to recolour another profile\'s panels')
	expectEq(Baseline(), BASELINE, 'and the character\'s own setup is still exact')
end)

test('ELVUI PANELS: a rebuilt profile\'s own colour is what is put back, and the glass opacity reaches the panels', function()
	expectEq(ns.Restore:ApplyHere('manual'), true, 'applied')
	HK_RunTimers()
	-- (own colour: whatever the built profile carries)
	ns.Restore:SetWindowSkin('skinElvUI', true)
	-- the profile is rebuilt with another panel colour of its own (APPLY / repair after a payload change)
	profile().general.backdropfadecolor = { r = 0.2, g = 0.2, b = 0.2, a = 0.5 }
	expectEq(ns.Restore:ApplyElvUIPanels(), 'BANZAI tone', 'the tone is written over it')
	expectNear(BushidoPrivateRestoreDB.elvuiPanels.previous.r, 0.2, 'and that newer own colour is the one on record')
	-- the material changes: BANZAI's own tone is never taken for the profile's colour
	settings.panelBackground = 'SOLID'
	ns.Restore:SetPanelBackground('SOLID')
	expectNear(BushidoPrivateRestoreDB.elvuiPanels.previous.r, 0.2, 'the record is still the profile\'s own colour')
	settings.panelBackground = 'GLASS'
	ns.Restore:SetPanelBackground('GLASS')
	-- the glass-opacity slider: ElvUI's panels follow at once while the switch is on
	TONE.a = 0.9
	ns.Options.Insert()
	local slider = E.Options.args.banzai.args.appearance.args.panelStyle.args.glassOpacity
	slider.set(nil, 0.9)
	expectEq(settings.glassOpacity, 0.9, 'the Banzai Art setting')
	expectNear(fade().a, 0.9, 'and the panel colour in the profile')
	TONE.a = 0.82
	ns.Restore:SetWindowSkin('skinElvUI', false)
	expectNear(fade().r, 0.2, 'off: the profile\'s own (newer) colour is back')
	-- with the switch off the slider writes nothing into the profile
	local before = T.Serialize(fade())
	slider.set(nil, 0.72)
	expectEq(T.Serialize(fade()), before, 'the slider alone does not touch the profile')
	expectEq(ns.Restore:Revert(), true, 'restored')
	HK_RunTimers()
	expectEq(Baseline(), BASELINE, 'the pre-Banzai state')
end)

test('minimap buttons on WoW Forever: the button addon\'s own position is never written', function()
	MinimapButtonButtonOptions = { scale = 8, position = { 'TOPRIGHT', nil, 'TOPRIGHT', -40, -237.5 } }
	HK_LOADED.MinimapButtonButton = true
	HK_PRINTS = {}
	expectEq(ns.Restore:ApplyHere('manual'), true, 'applied')
	HK_RunTimers()
	expectEq(MinimapButtonButtonOptions.position[4] .. '|' .. MinimapButtonButtonOptions.position[5], '-40|-237.5', 'its position is its own')
	expectEq(record().previous.minimapButton, nil, 'nothing recorded: nothing to put back')
	expect(string.find(prints(), 'Minimap buttons: left to MinimapButtonButton', 1, true), 'said so: ' .. prints())
	local lines = table.concat(ns.Restore:ClientReport(), '\n')
	expect(string.find(lines, 'minimap buttons: owned by MinimapButtonButton (BANZAI frames the minimap only)', 1, true), 'client report')
	expectEq(ns.Restore:Revert(), true, 'restored')
	HK_RunTimers()
	expectEq(MinimapButtonButtonOptions.position[4] .. '|' .. MinimapButtonButtonOptions.position[5], '-40|-237.5', 'and a restore leaves it alone too')
	MinimapButtonButtonOptions, HK_LOADED.MinimapButtonButton = nil, nil
	lines = table.concat(ns.Restore:ClientReport(), '\n')
	expect(string.find(lines, 'minimap buttons: no dedicated button addon loaded', 1, true), 'without one')
end)

test('status: /banzai status and /banzai forever list the window skins and the chat arrangement', function()
	HK_PRINTS = {}
	SlashCmdList.BANZAI('status')
	local text = prints()
	expect(string.find(text, 'BANZAI 1.5.0 (release; WoW Forever', 1, true), 'the whole-product version')
	expect(string.find(text, 'window skin - Blizzard Windows: on - Character SKINNED 1', 1, true), 'window skins: ' .. text)
	expect(string.find(text, 'chat windows: General in the BANZAI CHAT frame; docked by BANZAI: Loot / Trade', 1, true), 'chat arrangement')
	local report = table.concat(ns.Restore:ClientReport(), '\n')
	expect(string.find(report, 'window skin - Zygor: on - Zygor guide viewer SKINNED 1', 1, true), '/banzai forever')
	expect(string.find(report, 'chat windows: General in the BANZAI CHAT frame', 1, true), '/banzai forever chat')
	-- Banzai Art without the dev3 modules (an older build): no line, no error
	local skins, chat = BanzaiCompat.Skins, BanzaiCompat.ChatLayout
	BanzaiCompat.Skins, BanzaiCompat.ChatLayout = nil, nil
	expectEq(#ns.Restore:SkinLines(), 0, 'nothing to report')
	expectEq(ns.Restore:ApplyElvUIPanels(), 'not on this client', 'and nothing to write')
	BanzaiCompat.Skins, BanzaiCompat.ChatLayout = skins, chat
end)

test('settings: BANZAI > APPEARANCE > WINDOW SKINS has the six switches, each on its own, and the version on HOME and ABOUT', function()
	ns.Options.Insert()
	local page = E.Options.args.banzai
	local section = page.args.appearance.args.windowSkins
	expectEq(type(section), 'table', 'the WINDOW SKINS section')
	expectEq(HK_Plain(section.name), 'WINDOW SKINS', 'its title')
	expectEq(section.hidden(), false, 'shown on WoW Forever')
	local names = {}
	for _, key in ipairs({ 'skinBlizzard', 'skinBaganator', 'skinZygor', 'detailsFrame', 'chatFrame', 'skinElvUI' }) do
		local option = section.args[key]
		expectEq(type(option), 'table', key)
		expectEq(option.type, 'toggle', key .. ' is a switch')
		names[#names + 1] = option.name
	end
	expectEq(table.concat(names, ', '), 'Blizzard Windows, Baganator, Zygor, Details, Chat, ElvUI Panels', 'the six switches')
	-- each switch writes its own setting and nothing else
	settings.skinBlizzard, settings.skinBaganator, settings.skinZygor, settings.detailsFrame, settings.chatFrame = true, true, true, true, true
	section.args.skinZygor.set(nil, false)
	expectEq(settings.skinZygor, false, 'Zygor off')
	expectEq(tostring(settings.skinBlizzard) .. tostring(settings.skinBaganator) .. tostring(settings.detailsFrame) .. tostring(settings.chatFrame), 'truetruetruetrue', 'the HUD frames and the other skins stay on')
	expectEq(section.args.skinZygor.get(), false, 'read back')
	section.args.skinBaganator.set(nil, false)
	expectEq(settings.skinBaganator, false, 'Baganator off')
	expectEq(settings.skinBlizzard, true, 'Blizzard windows still on')
	section.args.chatFrame.set(nil, false)
	expectEq(settings.chatFrame, false, 'the Chat switch is the approved chat frame\'s own setting')
	section.args.chatFrame.set(nil, true)
	section.args.skinZygor.set(nil, true)
	section.args.skinBaganator.set(nil, true)
	local status = HK_Plain(section.args.status.name())
	expect(string.find(status, 'Blizzard Windows: on - Character SKINNED 1', 1, true), 'status: ' .. status)
	expect(string.find(status, 'Chat windows: General in the BANZAI CHAT frame', 1, true), 'chat status')
	expect(string.find(HK_Plain(section.args.info.name), 'BANZAI skins existing windows; it does not replace them.', 1, true), 'the contract is said on the page')
	-- the whole-product version: HOME, ABOUT, the brand line
	expect(string.find(HK_Plain(page.args.home.args.status.name()), 'VERSION   BANZAI 1.5.0   release', 1, true), 'HOME')
	expect(string.find(HK_Plain(page.args.about.args.version.name), 'Version 1.5.0', 1, true), 'ABOUT')
	expect(string.find(HK_Plain(page.args.brand.name()), 'BANZAI 1.5.0', 1, true), 'brand')
	expectEq(#HK_GAMEPLAY_CALLS, 0, 'no gameplay call anywhere in dev3\'s Restore side')
end)
