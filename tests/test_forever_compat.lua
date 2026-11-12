-- 1.5.0-dev1: Banzai Art (BushidoPrivateCompat) on WoW Forever 1.60.1 - the mocks stand in for the Forever client
-- (HK_FLAVOR = 'forever': no GetSpecialization globals, talents as a trait configuration, no pet battles, no conquest).
local ns = HK_NS
local Theme = ns.Theme
local Flavor = ns.Flavor
local NAME = 'JiberishUI - Bushido Private'

local function Frame(name, unit)
	local f = HK_NewFrame('Button', name, UIParent)
	f.unit = unit
	f.Health = HK_NewFrame('StatusBar', nil, f)
	f.Health.level = 10
	f.Health.backdrop = HK_NewFrame('Frame', nil, f.Health)
	f.Health.backdrop.borderColor = { 0, 0, 0, 1 }
	f.Power = HK_NewFrame('StatusBar', nil, f)
	f.Power.level = 8
	return f
end
local player = Frame('ElvUF_Player', 'player')
Frame('ElvUF_Target', 'target')
Frame('ElvUF_TargetTarget', 'targettarget')
Frame('ElvUF_Focus', 'focus')
player.rect, player.Health.rect, player.Power.rect = { 411, 308, 302, 45 }, { 412, 330, 300, 22 }, { 412, 312, 302, 7 }
player.UpdateTags = function(self) self.tagUpdates = (self.tagUpdates or 0) + 1 end
HK_ElvData.current = NAME
ElvUI[1].db = {
	unitframe = { units = { player = { customTexts = { ['m-Name'] = { justifyH = 'LEFT', xOffset = 12, yOffset = -32, size = 11 } } } } },
	movers = {}, actionbar = { bar1 = { buttonsPerRow = 12 } }, general = { minimap = { circle = false } },
	auras = { buffs = { size = 25, height = 21, horizontalSpacing = 6, verticalSpacing = 10, wrapAfter = 10, maxWraps = 2, keepSizeRatio = false } },
}
HK_NewFrame('AuraContainer', 'ElvUIPlayerBuffs', UIParent)
HK_NewFrame('Button', 'BuffsMover', UIParent)
BanzaiCompatDB = { bar = true, theme = 'VIBRANT', gradient = 'FORWARD' }

local function plain(fs) return (HK_Plain(fs.text):gsub('|T.-|t ?', '')) end
local function barItem(key)
	for _, item in ipairs(ns.Bar.frame.items) do if item.def.key == key then return item end end
end

test('Banzai Art loads on WoW Forever and knows its client', function()
	expectEq(Flavor.Id(), 'FOREVER', 'client')
	expectEq(BanzaiCompat.Flavor, Flavor, 'the adapter is reachable through BanzaiCompat')
	expectEq(Theme.VERSION, '1.5.0', 'version')
	expectEq(Theme.CHANNEL, 'release', 'channel')
	expectEq(BanzaiCompat.VERSION, '1.5.0', 'Banzai Art version')
	expectEq(GetSpecialization, nil, 'no specialization globals, as in the client')
	expectEq(C_PetBattles, nil, 'no pet battles')
end)

test('the whole of Banzai Art builds and refreshes on WoW Forever without an error', function()
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	HK_RunTimers()
	expectEq(BanzaiCompat.lastError, nil, 'no module failed: ' .. tostring(BanzaiCompat.lastError))
	expect(ns.Bar.frame ~= nil, 'the bottom panel was built')
	expectEq(ns.Tags.registered, true, 'the BANZAI tags are registered')
	expect(HK_TAGS['banzai:spec'] ~= nil, 'banzai:spec')
	expect(ns.Tags.updater.events.TRAIT_CONFIG_UPDATED, 'the identity line follows the talents')
end)

test('identity line: the player\'s leading talent tree; another player gets no spec and no inspect request', function()
	HK_STARTER_CALLS = 0
	expectEq(ns.Tags.PlayerSpec(), 'Feral Combat', 'the tree')
	expectEq(ns.Tags.Spec('player'), 'FERAL COMBAT', 'in capitals')
	expectEq(HK_Plain(ns.Tags.Alone('player')), 'FERAL COMBAT', 'the banzai:spec tag text')
	expectEq(HK_Plain(HK_TAGS['banzai:spec'].fn('player')), 'FERAL COMBAT', 'through ElvUI\'s tag')
	-- a tie: no spec at all (the class stands alone)
	HK_TALENTS.trees[1].spent = 31
	expectEq(ns.Tags.Spec('player'), nil, 'a tie shows nothing')
	expectEq(ns.Tags.Alone('player'), nil, 'no tag text')
	HK_TALENTS.trees[1].spent = 20
	-- the target is a mage: the inspect "specialization" and ElvUI's own [spec] answer are a starter ID on Forever
	HK_INSPECT['Player-2'] = 63
	HK_INSPECT_REQUESTS = {}
	expectEq(ns.Tags.RequestInspect('target'), false, 'no inspect is requested')
	ns.Tags.OnEvent('PLAYER_TARGET_CHANGED')
	expectEq(#HK_INSPECT_REQUESTS, 0, 'NotifyInspect was never called')
	expectEq(ns.Tags.Spec('target'), nil, 'another player has no spec on WoW Forever')
	expectEq(ns.Tags.After('target'), nil, 'and no identity suffix')
	expectEq(HK_STARTER_CALLS, 0, 'the starter specialization was never read')
end)

test('identity art: the Fabled icon follows Jiberish Icons\' own talent reading; without it the class icon', function()
	JiberishIcons = nil
	expectEq(ns.Identity.SpecOf('player'), nil, 'no Jiberish Icons: no spec ID is made up')
	local asked
	JiberishIcons = { {
		GetIdentityIcon = function(_, class, _, style, specID)
			if style == 'fabledspecializations' then return { texCoords = { 0, 0, 0, 1, 1, 0, 1, 1 }, spec = specID }, 'SPEC' end
			return { texCoords = { 0, 0, 0, 1, 1, 0, 1, 1 }, class = class }, 'CLASS'
		end,
		GetUnitSpecialization = function(_, unit) asked = unit return 103 end,
	} }
	expectEq(ns.Identity.SpecOf('player'), 103, 'Jiberish Icons names the player\'s tree with its own ID')
	expectEq(asked, 'player', 'asked for the player')
	local path, _, isSpec = ns.Identity.Icon('DRUID', ns.Identity.SpecOf('player'))
	expectEq(path, 'SPEC', 'the Fabled spec sheet')
	expectEq(isSpec, true, 'a spec icon')
	-- another player: no spec art, whatever Jiberish Icons or the arena data would answer (a starter ID there)
	asked = nil
	HK_ARENA_SPECS[1] = 63
	expectEq(ns.Identity.SpecOf('target'), nil, 'a target has no spec art')
	expectEq(ns.Identity.SpecOf('arena1', 1), nil, 'nor an arena opponent')
	expectEq(asked, nil, 'Jiberish Icons is not asked about another player (it would inspect)')
	expectEq(ns.Identity.PrepClass(1), nil, 'arena preparation names nothing from a starter ID')
	HK_ARENA_SPECS[1] = nil
	JiberishIcons[1].GetUnitSpecialization = function() return nil, true end
	expectEq(ns.Identity.SpecOf('player'), nil, 'a tie in Jiberish Icons: the class icon')
	local classPath, _, classIsSpec = ns.Identity.Icon('DRUID', nil)
	expectEq(classPath, 'CLASS', 'the Fabled class sheet')
	expectEq(classIsSpec, false, 'a class icon')
	expectEq(HK_STARTER_CALLS, 0, 'never the starter specialization')
end)

test('bottom panel: what WoW Forever does not have is left out; the rest keeps its order', function()
	local keys = { left = {}, center = {}, right = {} }
	local items = {}
	for _, item in ipairs(ns.Bar.frame.items) do items[#items + 1] = item end
	table.sort(items, function(a, b) return a.index < b.index end)
	for _, item in ipairs(items) do table.insert(keys[item.group], item.def.key) end
	expectEq(table.concat(keys.left, ' '), 'honor haste durability', 'left: no conquest, mastery or versatility')
	expectEq(table.concat(keys.center, ' '), 'fps ms time', 'centre')
	expectEq(table.concat(keys.right, ' '), 'spec ilvl professions friends guild gold', 'right')
	expectEq(barItem('honor').index, 1, 'the indexes stay contiguous')
	expectEq(barItem('haste').index, 2, 'haste moves up')
	expectEq(barItem('durability').index, 3, 'durability moves up')
	expectEq(barItem('conquest'), nil, 'no conquest entry')
	for _, def in ipairs(ns.Bar.ITEMS.left) do
		if def.key == 'conquest' or def.key == 'mastery' or def.key == 'versatility' then expectEq(ns.Bar.Shown(def), false, def.key .. ' is not shown') else expectEq(ns.Bar.Shown(def), true, def.key .. ' is shown') end
	end
	ns.Bar:Update()
	expectEq(plain(barItem('spec').value), 'FERAL COMBAT', 'SPEC is the leading talent tree')
	expect(string.find(barItem('spec').value.text, '|T132115:', 1, true), 'with the game\'s own icon')
	expectEq(plain(barItem('honor').value), '12,345', 'honor still reads its currency')
	HK_TALENTS.trees[1].spent = 31
	ns.Bar:Update()
	expectEq(plain(barItem('spec').value), '-', 'a tie: no tree is named')
	HK_TALENTS.trees[1].spent = 20
	expect(ns.Bar.frame.events.TRAIT_CONFIG_UPDATED, 'the panel follows the talents')
end)

test('bottom-panel tooltip: every talent tree with its points, no role or loot specialization', function()
	local tt = HK_NewFrame('GameTooltip', nil, UIParent)
	tt.lines = {}
	ns.Info.TIPS.spec(tt)
	local text = HK_TipText(tt)
	expect(string.find(text, 'FERAL COMBAT', 1, true), 'the leading tree: ' .. text)
	expect(string.find(text, 'Balance  0', 1, true), 'Balance')
	expect(string.find(text, 'Feral Combat  31', 1, true), 'Feral Combat')
	expect(string.find(text, 'Restoration  20', 1, true), 'Restoration')
	expect(string.find(text, 'WoW Forever has no game-provided spec role', 1, true), 'said honestly')
	expect(string.find(text, 'Ambiguous or unmapped trees', 1, true), 'the limits of auto-detection are stated')
	expect(not string.find(text, 'Loot specialization', 1, true), 'no loot specialization')
	expect(not string.find(text, 'STARTER', 1, true), 'never the starter specialization')
end)

test('Forever minimap buttons are laid out inside the square map without changing Eltruism settings', function()
	local positions, width, height = BanzaiCompat.MinimapButtonLayout(180, 7, 24)
	expectEq(#positions, 7, 'all visible buttons')
	expect(width <= 180 and height <= 180, 'the group fits the map')
	for i, position in ipairs(positions) do
		expect(position.size <= 24 and position.size >= 8, 'button ' .. i .. ' has a safe size')
		expect(-position.x + position.size <= 180 and -position.y + position.size <= 180, 'button ' .. i .. ' stays within the map')
	end
	local map = HK_NewFrame('Frame', 'Minimap', UIParent)
	map:SetSize(180, 180)
	local bar = HK_NewFrame('Frame', 'EltruismMinimapButtonBar', UIParent)
	bar:SetSize(200, 30)
	ElvUI[1].db.ElvUI_EltreumUI = { otherstuff = { minimapbuttons = { iconSize = 24, buttonsPerRow = 12, orientation = 'HORIZONTAL' } } }
	local savedButtonsPerRow = ElvUI[1].db.ElvUI_EltreumUI.otherstuff.minimapbuttons.buttonsPerRow
	local buttons = {}
	for i = 1, 7 do
		local button = HK_NewFrame('Button', 'TestMinimapButton' .. i, bar)
		button.EltruismInBar = true
		button:SetSize(24, 24)
		buttons[i] = button
	end
	local ok, reason = BanzaiCompat:LayoutMinimapButtonBar()
	expectEq(ok, true, 'adapter ran: ' .. tostring(reason))
	expect(bar:GetWidth() <= 180 and bar:GetHeight() <= 180, 'container fits inside the minimap')
	for i, button in ipairs(buttons) do
		expectEq(button.points[1][1], 'TOPRIGHT', 'button ' .. i .. ' uses the contained grid')
		expect(button:GetWidth() <= 24, 'button ' .. i .. ' is not enlarged')
	end
	expectEq(ElvUI[1].db.ElvUI_EltreumUI.otherstuff.minimapbuttons.buttonsPerRow, savedButtonsPerRow, 'Eltruism saved settings are unchanged')
	HK_IN_COMBAT = true
	local old = buttons[1].points[1]
	local inCombat, status = BanzaiCompat:LayoutMinimapButtonBar()
	expectEq(inCombat, false, 'combat defers the protected layout')
	expectEq(status, 'waiting (combat)', 'defer status')
	expectEq(buttons[1].points[1], old, 'no frame mutation in combat')
	HK_IN_COMBAT = false
end)

test('Forever cooldown and PvP item-level displays do not reuse unverified Retail data', function()
	local bars = ns.CooldownBars
	expectEq(#bars:Candidates('offensive'), 0, 'no Retail offensive spell IDs')
	expectEq(#bars:Candidates('defensive'), 0, 'no Retail defensive spell IDs')
	expect(string.find(bars:MappingReport(), 'no spell IDs verified', 1, true), 'unverified mappings are explicit')
	local old = GetAverageItemLevel
	GetAverageItemLevel = function() return 300, 290, 400 end
	local value = barItem('ilvl').def.value(barItem('ilvl'))
	expectEq(value, 'PVE 290', 'the unverified PvP item level is omitted')
	local tt = HK_NewFrame('GameTooltip', nil, UIParent)
	tt.lines = {}
	ns.Info.TIPS.ilvl(tt)
	local text = HK_TipText(tt)
	expect(string.find(text, 'not available on this client', 1, true), 'the tooltip says the PvP value is unavailable')
	expect(not string.find(text, '400', 1, true), 'it never reports the unverified numeric value')
	GetAverageItemLevel = old
end)

test('objectives: the Banzai tracker reads the quest log on WoW Forever, with or without world quests', function()
	local list = ns.Tracker:Collect()
	expect(#list >= 2, 'the watched quests: ' .. #list)
	local worldWatches, taskQuest = C_QuestLog.GetNumWorldQuestWatches, C_TaskQuest
	C_QuestLog.GetNumWorldQuestWatches, C_QuestLog.GetQuestIDForWorldQuestWatchIndex, C_TaskQuest = nil, nil, nil
	local without = ns.Tracker:Collect()
	expectEq(#without, 2, 'the two watched quests without any world quest API')
	C_QuestLog.GetNumWorldQuestWatches, C_TaskQuest = worldWatches, taskQuest
end)

test('the AFK screen and the previews carry the release channel (no proof label)', function()
	expectEq(Theme.CHANNEL, 'release', 'channel')
	expect(Flavor.Has('petBattles') == false, 'no pet battle check is needed on WoW Forever')
end)
