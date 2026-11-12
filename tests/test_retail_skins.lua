-- 1.5.0: the same Banzai Art files on Retail. The Forever chat adapter and the window skins are a WoW Forever
-- proof: on Retail nothing of them runs, creates, hooks or paints, whatever is installed and whatever is switched on.
local ns = HK_NS
local Theme = ns.Theme
local Skins = ns.Skins
local Chat = ns.ChatLayout
local NAME = 'JiberishUI - Bushido Private'
local Methods = getmetatable(UIParent).__index
function Methods:HookScript(script, fn) self.hooks = self.hooks or {} self.hooks[script] = self.hooks[script] or {} table.insert(self.hooks[script], fn) end
function Methods:GetFont() return self.font, self.fontSize, self.fontFlags end
function Methods:GetBackdropColor() local c = self.backdropColor or { 0, 0, 0, 1 } return c[1], c[2], c[3], c[4] end
function Methods:GetBackdropBorderColor() local c = self.borderColor or { 1, 1, 1, 1 } return c[1], c[2], c[3], c[4] end
function Methods:IsObjectType(kind) return self.kind == kind end
function Methods:GetID() return self.id end

HK_ElvData.current = NAME
ElvUI[1].db = {
	unitframe = { units = { player = { customTexts = {} } } }, movers = {}, actionbar = { bar1 = { buttonsPerRow = 12 } }, general = { minimap = { circle = false } },
	auras = { buffs = { size = 25, height = 21, horizontalSpacing = 6, verticalSpacing = 10, wrapAfter = 10, maxWraps = 2, keepSizeRatio = false } },
	chat = { panelSnapping = true },
}
ElvUI[1].private = { chat = { enable = true } }
HK_NewFrame('AuraContainer', 'ElvUIPlayerBuffs', UIParent)
HK_NewFrame('Button', 'BuffsMover', UIParent)
BanzaiCompatDB = { bar = true, theme = 'VIBRANT', gradient = 'FORWARD' }

-- everything a Forever install would offer, present on Retail too: skinned windows, Baganator, Zygor, a stray chat window
local function Window(name)
	local f = HK_NewFrame('Frame', name, UIParent)
	f.template, f.backdropColor, f.w, f.h = 'Transparent', { 0, 0, 0, 1 }, 338, 424
	f.TitleContainer = HK_NewFrame('Frame', nil, f)
	local title = f.TitleContainer:CreateFontString()
	title:SetFont('Fonts\\FRIZQT__.TTF', 12, '')
	title:SetText(name)
	f.TitleContainer.TitleText = title
	return f
end
local character, merchant = Window('CharacterFrame'), Window('MerchantFrame')
local backpack = Window('Baganator_SingleViewBackpackViewFrameelvui')
local listeners = 0
HK_LOADED.Baganator, HK_LOADED.ZygorGuidesViewerForever, HK_LOADED.MinimapButtonButton = true, true, true
Baganator = { API = { Skins = {
	GetCurrentSkin = function() return 'elvui' end,
	GetAllFrames = function() return { { regionType = 'ButtonFrame', region = backpack, tags = { 'backpack' } } } end,
	RegisterListener = function() listeners = listeners + 1 end,
} } }
local viewer = HK_NewFrame('Frame', 'ZygorGuidesViewerFrame', UIParent)
viewer.Border = HK_NewFrame('Frame', nil, viewer)
viewer.Border.borderColor = { 0.067, 0.067, 0.067, 1 }
viewer.Border.TitleBar = HK_NewFrame('Frame', nil, viewer.Border)
function viewer:ApplySkin() end
function viewer:AlignFrame() end
CHAT_FRAMES = { 'ChatFrame1', 'ChatFrame4' }
local general = HK_NewFrame('ScrollingMessageFrame', 'ChatFrame1', UIParent)
general.id, general.isDocked, general.rect = 1, true, { 36, 47, 420, 108 }
local loot = HK_NewFrame('ScrollingMessageFrame', 'ChatFrame4', UIParent)
loot.id, loot.name, loot.rect = 4, 'Loot / Trade', { 36, 47, 420, 108 }
GeneralDockManager = { primary = general, DOCKED_CHAT_FRAMES = { general } }
local chatCalls = 0
function FCF_DockFrame() chatCalls = chatCalls + 1 end
function FCF_UnDockFrame() chatCalls = chatCalls + 1 end
function FCF_SelectDockFrame() chatCalls = chatCalls + 1 end
local CH = { PositionChats = function() chatCalls = chatCalls + 1 end }
local baseModule = ElvUI[1].GetModule
ElvUI[1].GetModule = function(self, name, silent) if name == 'Chat' then return CH end return baseModule(self, name, silent) end

test('Retail: Banzai Art 1.5.0 builds with the new files and without an error', function()
	expectEq(ns.Flavor.Id(), 'RETAIL', 'client')
	expectEq(Theme.VERSION, '1.5.0', 'version')
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	HK_RunTimers()
	expectEq(BanzaiCompat.lastError, nil, 'no module failed: ' .. tostring(BanzaiCompat.lastError))
	expectEq(Skins.lastError, nil, 'skins: ' .. tostring(Skins.lastError))
	expectEq(Chat.lastError, nil, 'chat: ' .. tostring(Chat.lastError))
end)

test('Retail: no window is skinned - no texture, hook, colour or font change, whatever is switched on', function()
	local db = Theme:DB()
	db.skinBlizzard, db.skinBaganator, db.skinZygor, db.skinElvUI = true, true, true, true
	BanzaiCompat.chatFrame.rect, BanzaiCompat.detailsFrame.rect = { -0.655, 31.5, 493.31, 161 }, { 1382, 31.5, 493.31, 161 }
	local hooks = #HK_HOOKS
	for _ = 1, 3 do BanzaiCompat:Refresh() end
	expectEq(Skins.Supported(), false, 'not on this client')
	expectEq(Skins:Owns('blizzard'), false, 'BANZAI owns no window skin here')
	expectEq(Skins:Count(), 0, 'nothing skinned')
	for _, f in ipairs({ character, merchant, backpack, viewer, viewer.Border, viewer.Border.TitleBar }) do
		expectEq(f.textures, nil, 'no texture on ' .. tostring(f.name))
		expectEq(f.hooks, nil, 'no script hook on ' .. tostring(f.name))
	end
	expectEq(character.backdropColor[4], 1, 'ElvUI\'s panel untouched')
	expectEq(character.TitleContainer.TitleText.font, 'Fonts\\FRIZQT__.TTF', 'heading untouched')
	expectEq(viewer.Border.borderColor[1], 0.067, 'Zygor\'s colour untouched')
	expectEq(listeners, 0, 'no Baganator listener registered')
	expectEq(#HK_HOOKS, hooks, 'no secure hook made')
	for _, adapter in ipairs(Skins.adapters) do expectEq(adapter.state.status, 'NOT ON THIS CLIENT', adapter.id) end
	expect(string.find(Skins:Report()[1], 'WoW Forever only', 1, true), 'the report says so')
	-- an addon loading later queues nothing
	HK_TIMERS = {}
	HK_Fire('ADDON_LOADED', 'Blizzard_TrainerUI')
	HK_Fire('ADDON_LOADED', 'Baganator')
	expectEq(#HK_TIMERS, 0, 'no timer')
end)

test('Retail: the chat windows are not arranged - the Forever chat adapter does nothing', function()
	expectEq(Chat.Owned(), false, 'not owned on Retail')
	Chat:Refresh('test')
	BanzaiCompat:Refresh()
	local ok, why = Chat:Apply('test')
	expectEq(ok, false, 'nothing applied')
	expectEq(why, 'not arranged here', 'said why')
	expectEq(chatCalls, 0, 'no chat function was called')
	expectEq(loot.isDocked, nil, 'the undocked window stays its owner\'s')
	expectEq(ElvUI[1].db.chat.panelSnapLeftID, nil, 'no snapping ID written')
	expectEq(Theme:DB().chatDocked, nil, 'nothing recorded')
	expectEq(Chat:StatusText(), 'not used on this client', 'status')
	Theme:DB().chatFrame = false
	BanzaiCompat:Refresh()
	expectEq(chatCalls, 0, 'nor with the chat frame switched off')
	Theme:DB().chatFrame = true
	BanzaiCompat:Refresh()
end)

test('Retail: the approved chat, Details and minimap frames are built and placed as before', function()
	local chat = BanzaiCompat.chatFrame
	expectEq(chat.bw .. 'x' .. chat.bh, '493.31x161', 'chat frame size')
	expectNear(chat.points[1][4], -0.655, 'chat frame x')
	expectEq(chat.shown, true, 'chat frame shown')
	expectEq(BanzaiCompat.detailsFrame.bw .. 'x' .. BanzaiCompat.detailsFrame.bh, '493.31x161', 'Details frame size')
	expect(BanzaiCompat.minimapFrame ~= nil, 'minimap frame')
	-- the dev2 Forever minimap-button containment never ran on Retail, with or without a button addon
	local calls = 0
	ElvUI_EltreumUI = { UpdateMinimapButtonBar = function() calls = calls + 1 end }
	BanzaiCompat:RefreshMinimapButtonBar()
	expectEq(calls, 0, 'Eltruism\'s bar is not driven on Retail')
	ElvUI_EltreumUI = nil
end)

test('Retail: the new settings exist with their defaults and travel with Character Sync as visual preferences', function()
	BanzaiCompatDB.chars['Fresh - Stormrage'] = nil
	local db = Theme:DB('Fresh - Stormrage')
	expectEq(db.skinBlizzard, true, 'skinBlizzard')
	expectEq(db.skinBaganator, true, 'skinBaganator')
	expectEq(db.skinZygor, true, 'skinZygor')
	expectEq(db.skinElvUI, false, 'skinElvUI')
	db.skinZygor = 'yes' -- a damaged value is its default again
	db.skinElvUI = 1
	db = Theme:DB('Fresh - Stormrage')
	expectEq(db.skinZygor, true, 'normalised')
	expectEq(db.skinElvUI, false, 'normalised')
	db.skinZygor = false
	local exported = Theme:Export('Fresh - Stormrage')
	expectEq(exported.skinZygor, false, 'exported')
	expectEq(exported.skinBlizzard, true, 'exported')
	expectEq(exported.chatDocked, nil, 'the per-character chat record is never exported')
	Theme:Import({ skinBaganator = false }, 'Fresh - Stormrage')
	expectEq(Theme:DB('Fresh - Stormrage').skinBaganator, false, 'imported')
	expectEq(Theme:DB('Fresh - Stormrage').skinZygor, false, 'a value the master does not carry is kept')
	BanzaiCompatDB.chars['Fresh - Stormrage'] = nil
end)
