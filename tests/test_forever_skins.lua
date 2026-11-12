-- 1.5.0: Banzai Art on WoW Forever - the chat windows inside the BANZAI CHAT frame (ChatLayout.lua), the
-- BANZAI Window Skin framework (Skins.lua) and its adapters (SkinAdapters.lua), the minimap-button hand-off.
local ns = HK_NS
local Theme = ns.Theme
local Skins = ns.Skins
local Chat = ns.ChatLayout
local NAME = 'JiberishUI - Bushido Private'
local Methods = getmetatable(UIParent).__index

-- what the mocks lack: script post-hooks (kept apart from the owner's script), fonts and colours read back
function Methods:HookScript(script, fn) self.hooks = self.hooks or {} self.hooks[script] = self.hooks[script] or {} table.insert(self.hooks[script], fn) end
function Methods:GetFont() return self.font, self.fontSize, self.fontFlags end
function Methods:GetTextColor() local c = self.textColor or { 1, 0.82, 0, 1 } return c[1], c[2], c[3], c[4] end
function Methods:GetObjectType() return self.kind end
function Methods:GetID() return self.id end
function Methods:GetPoint(i) local p = self.points[i or 1] if p then return unpack(p) end end
local function Show(frame) -- the window shows: its owner's script, then every post-hook there was when it showed
	frame.shown = true
	if frame.scripts.OnShow then frame.scripts.OnShow(frame) end
	local hooks = {}
	for i, fn in ipairs(frame.hooks and frame.hooks.OnShow or {}) do hooks[i] = fn end -- (a hook made during the dispatch runs at the next show, as in the game)
	for _, fn in ipairs(hooks) do fn(frame) end
end

HK_ElvData.current = NAME
ElvUI[1].db = {
	unitframe = { units = { player = { customTexts = {} } } }, movers = {}, actionbar = { bar1 = { buttonsPerRow = 12 } }, general = { minimap = { circle = false } },
	auras = { buffs = { size = 25, height = 21, horizontalSpacing = 6, verticalSpacing = 10, wrapAfter = 10, maxWraps = 2, keepSizeRatio = false } },
	chat = { panelSnapping = true, panelWidth = 430, panelHeight = 140 },
}
ElvUI[1].private = { chat = { enable = true }, skins = { blizzard = { enable = true } } }
HK_NewFrame('AuraContainer', 'ElvUIPlayerBuffs', UIParent)
HK_NewFrame('Button', 'BuffsMover', UIParent)
BanzaiCompatDB = { bar = true, theme = 'VIBRANT', gradient = 'FORWARD' }

---------------------------------------------------------------------------
-- The game's chat dock and ElvUI's chat module, as the installed ElvUI 16.01 uses them
---------------------------------------------------------------------------
CHAT_FRAMES = {}
GeneralDockManager = { DOCKED_CHAT_FRAMES = {} }
local function ChatWindow(id, name, docked, shown, rect)
	local f = HK_NewFrame('ScrollingMessageFrame', 'ChatFrame' .. id, UIParent)
	f.id, f.name, f.isDocked, f.shown, f.rect = id, name, docked or nil, shown, rect
	f.w, f.h = rect and rect[3] or 0, rect and rect[4] or 0
	f.messages = { name .. ' line' }
	HK_NewFrame('Button', 'ChatFrame' .. id .. 'Tab', UIParent)
	CHAT_FRAMES[id] = 'ChatFrame' .. id
	if docked then table.insert(GeneralDockManager.DOCKED_CHAT_FRAMES, f) end
	return f
end
-- Darren's Forever character after the dev2 test (chat-cache.txt, 19:42): General docked; "Loot / Trade" undocked,
-- shown, at the left chat panel's own place and size (panel + 5: 36, 47; 420 x 108)
local general = ChatWindow(1, 'General', true, true, { 36, 47, 420, 108 })
local log = ChatWindow(2, 'Log', true, false, { 36, 47, 420, 108 })
local voice = ChatWindow(3, 'Voice', false, false, nil)
local loot = ChatWindow(4, 'Loot / Trade', false, true, { 36, 47, 420, 108 })
GeneralDockManager.primary = general
HK_FCF = {}
function FCF_DockFrame(chat, index, selected)
	HK_FCF[#HK_FCF + 1] = { 'dock', chat, index, selected }
	chat.isDocked = true
	chat.shown = selected and true or false -- a docked window that is not selected is not on show
	table.insert(GeneralDockManager.DOCKED_CHAT_FRAMES, chat)
end
function FCF_UnDockFrame(chat)
	HK_FCF[#HK_FCF + 1] = { 'undock', chat }
	chat.isDocked = nil
	for i, f in ipairs(GeneralDockManager.DOCKED_CHAT_FRAMES) do if f == chat then table.remove(GeneralDockManager.DOCKED_CHAT_FRAMES, i) break end end
end
function FCF_SelectDockFrame(chat) HK_FCF[#HK_FCF + 1] = { 'select', chat } end
function FCF_SavePositionAndDimensions(chat) HK_FCF[#HK_FCF + 1] = { 'save', chat } end
function IsCombatLog(chat) return chat == log end
-- ElvUI's chat module: FindChatWindows by the profile's snapping ID (Chat.lua 1389), PositionChats
local CH = { positioned = 0 }
function CH:PositionChats()
	self.positioned = self.positioned + 1
	local id = ElvUI[1].db.chat.panelSnapLeftID
	self.LeftChatWindow = (id and _G['ChatFrame' .. id] and _G['ChatFrame' .. id] == GeneralDockManager.primary) and _G['ChatFrame' .. id] or self.LeftChatWindow
end
local baseModule = ElvUI[1].GetModule
ElvUI[1].GetModule = function(self, name, silent) if name == 'Chat' then return CH end return baseModule(self, name, silent) end

local function Build()
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	HK_RunTimers()
end
local function Calls(kind) local n = 0 for _, c in ipairs(HK_FCF) do if c[1] == kind then n = n + 1 end end return n end

test('Banzai Art 1.5.0 builds on WoW Forever with the chat adapter and the window skins and no error', function()
	expectEq(Theme.VERSION, '1.5.0', 'version')
	expect(Chat ~= nil and BanzaiCompat.ChatLayout == Chat, 'the chat adapter is reachable through BanzaiCompat')
	expect(Skins ~= nil and BanzaiCompat.Skins == Skins, 'the window skins are reachable through BanzaiCompat')
	-- the BANZAI CHAT frame is where 1.2.0 put it: the stand-in gives it its screen rectangle
	Build()
	expectEq(BanzaiCompat.lastError, nil, 'no module failed: ' .. tostring(BanzaiCompat.lastError))
	expectEq(Chat.lastError, nil, 'chat adapter: ' .. tostring(Chat.lastError))
	expectEq(Skins.lastError, nil, 'window skins: ' .. tostring(Skins.lastError))
end)

---------------------------------------------------------------------------
-- Forever chat
---------------------------------------------------------------------------
local function ResetChat()
	HK_FCF = {}
	CH.LeftChatWindow, CH.positioned = nil, 0
	ElvUI[1].db.chat.panelSnapLeftID, ElvUI[1].db.chat.panelSnapRightID = nil, nil
	loot.isDocked, loot.shown, loot.rect = nil, true, { 36, 47, 420, 108 }
	for i = #GeneralDockManager.DOCKED_CHAT_FRAMES, 1, -1 do if GeneralDockManager.DOCKED_CHAT_FRAMES[i] == loot then table.remove(GeneralDockManager.DOCKED_CHAT_FRAMES, i) end end
	Theme:DB().chatDocked = nil
	Theme:DB().chatFrame = true
	BanzaiCompat.chatFrame.rect = { -0.655, 31.5, 493.31, 161 }
	BanzaiCompat.chatFrame.shown = true
	BanzaiCompat.detailsFrame.rect = { 1382, 31.5, 493.31, 161 }
	BanzaiCompat.detailsFrame.shown = true
end

test('chat: the BANZAI CHAT frame itself is not moved or resized by the fix', function()
	ResetChat()
	local frame = BanzaiCompat.chatFrame
	BanzaiCompat:Refresh()
	expectEq(frame.bw, 493.31, 'width')
	expectEq(frame.bh, 161, 'height')
	expectEq(frame.points[1][1] .. '|' .. frame.points[1][3], 'BOTTOMLEFT|BOTTOMLEFT', 'anchor')
	expectNear(frame.points[1][4], -0.655, 'flush with the left screen edge')
	expectNear(frame.points[1][5], 31.5, 'on the bottom panel')
	expectEq(BanzaiCompat.CHAT.width .. 'x' .. BanzaiCompat.CHAT.height, '493.31x161', 'the approved numbers')
end)

test('chat root cause: the undocked Loot / Trade window lying on General becomes a tab of the General window', function()
	ResetChat()
	local list, primary = Chat:Candidates()
	expectEq(primary, general, 'General is the dock\'s window')
	expectEq(#list, 1, 'one window to bring in')
	expectEq(list[1].chat, loot, 'Loot / Trade')
	local ok, state = Chat:Apply('test')
	expectEq(ok, true, 'arranged')
	expectEq(Calls('dock'), 1, 'docked once, with the game\'s own function')
	expectEq(HK_FCF[1][2], loot, 'the Loot / Trade window')
	expectEq(HK_FCF[1][3], 3, 'after the windows already docked (General, Log)')
	expectEq(HK_FCF[1][4], false, 'not selected: General stays on show')
	expectEq(loot.isDocked, true, 'now a tab')
	expectEq(state.docked[1], 'Loot / Trade', 'reported by its name')
	expectEq(Calls('select'), 1, 'General selected again')
	-- its content and identity are untouched
	expectEq(loot.name, 'Loot / Trade', 'name')
	expectEq(loot.messages[1], 'Loot / Trade line', 'messages')
	expectEq(#general.points, 0, 'General is never anchored by BANZAI (ElvUI positions it)')
	expectEq(general.w .. 'x' .. general.h, '420x108', 'nor resized')
end)

test('chat: General becomes ElvUI\'s left-panel window through the profile\'s own snapping key', function()
	ResetChat()
	Chat:Apply('test')
	expectEq(ElvUI[1].db.chat.panelSnapLeftID, 1, 'General\'s window ID in the Banzai profile')
	expectEq(CH.positioned, 1, 'ElvUI positioned its chat windows itself, once')
	expectEq(CH.LeftChatWindow, general, 'General is the left window')
	expectEq(Chat.state.snapped, true, 'reported')
	-- a right-panel ID naming General is cleared (one window cannot be both)
	ResetChat()
	ElvUI[1].db.chat.panelSnapRightID = 1
	Chat:Apply('test')
	expectEq(ElvUI[1].db.chat.panelSnapRightID, nil, 'right ID cleared')
	-- ElvUI snapping switched off: nothing of the profile is written
	ResetChat()
	ElvUI[1].db.chat.panelSnapping = false
	Chat:Apply('test')
	expectEq(ElvUI[1].db.chat.panelSnapLeftID, nil, 'no snapping ID while snapping is off')
	expectEq(CH.positioned, 0, 'ElvUI not asked')
	ElvUI[1].db.chat.panelSnapping = true
end)

test('chat: idempotent - a second pass, a refresh and a reload change nothing more', function()
	ResetChat()
	Chat:Apply('first')
	local calls, positioned = #HK_FCF, CH.positioned
	Chat:Apply('second')
	BanzaiCompat:Refresh()
	Chat:Refresh('login')
	expectEq(#HK_FCF, calls, 'no further dock / select call')
	expectEq(CH.positioned, positioned, 'ElvUI not positioned again')
	expectEq(#Chat.state.docked, 0, 'nothing left to dock')
	expectEq(Chat.state.snapped, true, 'General still the left window')
end)

test('chat: only a window lying on a BANZAI frame is docked - floating, hidden, whisper and combat-log windows stay', function()
	ResetChat()
	loot.rect = { 800, 500, 420, 108 } -- floating in the middle of the screen: its owner's choice
	expectEq(#Chat:Candidates(), 0, 'a floating window is left alone')
	loot.rect = { 1400, 47, 420, 108 } -- over the DAMAGE / HEALING frame (ElvUI's right panel place)
	expectEq(#Chat:Candidates(), 1, 'a window over the Details frame joins the tabs')
	BanzaiCompat.detailsFrame.shown = false
	expectEq(#Chat:Candidates(), 0, 'not while the Banzai Details frame is off')
	BanzaiCompat.detailsFrame.shown = true
	loot.rect = { 36, 47, 420, 108 }
	loot.shown = false
	expectEq(#Chat:Candidates(), 0, 'a closed window')
	loot.shown = true
	loot.isTemporary = true
	expectEq(#Chat:Candidates(), 0, 'a whisper window')
	loot.isTemporary = nil
	loot.rect = nil
	expectEq(#Chat:Candidates(), 0, 'a window without a layout')
	loot.rect = { 36, 47, 420, 108 }
	-- the combat log, undocked on the chat frame, is the game's own special window
	log.isDocked, log.shown = nil, true
	local list = Chat:Candidates()
	expectEq(#list, 1, 'only Loot / Trade')
	expectEq(list[1].chat, loot, 'not the combat log')
	log.isDocked, log.shown = true, false
	expectEq(voice.isDocked, nil, 'the hidden Voice window was never touched')
end)

test('chat: in combat nothing is docked; the work is done once combat ends', function()
	ResetChat()
	HK_IN_COMBAT = true
	local ok, why = Chat:Apply('test')
	expectEq(ok, false, 'not in combat')
	expectEq(why, 'waiting (combat)', 'said why')
	expectEq(#HK_FCF, 0, 'no chat function called')
	expectEq(Chat.pending, true, 'remembered')
	expectEq(Chat:StatusText(), 'waiting for combat to end', 'status')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(loot.isDocked, true, 'docked after combat')
	expectEq(Chat.pending, false, 'nothing pending')
end)

test('chat: not arranged off the Banzai profile, with the chat frame off, or with ElvUI chat off', function()
	ResetChat()
	HK_ElvData.current = 'HARDKORHUI'
	expectEq(Chat.Owned(), false, 'another profile')
	expectEq(Chat:Apply('test'), false, 'nothing done')
	expectEq(#HK_FCF, 0, 'no call')
	HK_ElvData.current = NAME
	Theme:DB().chatFrame = false
	expectEq(Chat.Owned(), false, 'chat frame off')
	Chat:Refresh('test')
	expectEq(#HK_FCF, 0, 'no call')
	Theme:DB().chatFrame = true
	ElvUI[1].private.chat.enable = false
	local ok, why = Chat:Apply('test')
	expectEq(ok, false, 'ElvUI chat off')
	expectEq(why, 'ElvUI chat is not presenting the chat', 'said why')
	expectEq(#HK_FCF, 0, 'no call')
	ElvUI[1].private.chat.enable = true
	local dock = GeneralDockManager
	GeneralDockManager = nil
	local ok2, why2 = Chat:Apply('test')
	expectEq(ok2, false, 'no dock')
	expectEq(why2, 'the chat dock is not there', 'said why')
	GeneralDockManager = dock
end)

test('chat restore: the docked window goes back where it was, exactly once, and only if it is still that window', function()
	ResetChat()
	Chat:Apply('test')
	local saved = Theme:DB().chatDocked
	expectEq(saved.ChatFrame4.name, 'Loot / Trade', 'what was docked is on record')
	expectNear(saved.ChatFrame4.x, 36, 'x')
	expectNear(saved.ChatFrame4.y, 47, 'y')
	expectEq(saved.ChatFrame4.width .. 'x' .. saved.ChatFrame4.height, '420x108', 'size')
	expectEq(Theme:Export().chatDocked, nil, 'never part of Character Sync')
	HK_FCF = {}
	expectEq(Chat:Release('restore'), 1, 'one window handed back')
	expectEq(loot.isDocked, nil, 'undocked')
	expectEq(loot.shown, true, 'shown')
	expectEq(loot.points[1][1], 'BOTTOMLEFT', 'placed')
	expectNear(loot.points[1][4], 36, 'x')
	expectNear(loot.points[1][5], 47, 'y')
	expectEq(Calls('undock'), 1, 'the game\'s own undock')
	expectEq(Calls('save'), 1, 'position saved by the game')
	expectEq(Theme:DB().chatDocked, nil, 'record cleared')
	expectEq(Chat:Release('again'), 0, 'nothing more to hand back')
	expectEq(Calls('undock'), 1, 'no second undock')
	-- a window renamed / replaced in that slot is not BANZAI's to move
	ResetChat()
	Chat:Apply('test')
	loot.name = 'Guild'
	HK_FCF = {}
	expectEq(Chat:Release('restore'), 0, 'another window now: left alone')
	expectEq(Calls('undock'), 0, 'not undocked')
	loot.name = 'Loot / Trade'
	-- General is never undocked
	Theme:DB().chatDocked = { ChatFrame1 = { name = 'General', x = 1, y = 1, width = 10, height = 10 } }
	expectEq(Chat:Release('restore'), 0, 'the dock\'s own window stays')
	expectEq(general.isDocked, true, 'General docked')
end)

test('chat: switching the Banzai chat frame off hands the windows back; on again brings them in', function()
	ResetChat()
	BanzaiCompat:Set('chatFrame', true)
	expectEq(loot.isDocked, true, 'docked while BANZAI owns the chat frame')
	BanzaiCompat:Set('chatFrame', false)
	expectEq(loot.isDocked, nil, 'handed back with the frame off')
	expectEq(BanzaiCompat.chatFrame.shown, false, 'the frame is hidden')
	BanzaiCompat.chatFrame.shown, BanzaiCompat.chatFrame.rect = true, { -0.655, 31.5, 493.31, 161 }
	BanzaiCompat:Set('chatFrame', true)
	expectEq(loot.isDocked, true, 'docked again')
	expect(string.find(Chat:StatusText(), 'docked by BANZAI: Loot / Trade', 1, true), 'status: ' .. Chat:StatusText())
end)

test('chat: no hook, no OnUpdate and no ticker belongs to the chat adapter', function()
	ResetChat()
	local tickers, hooks = #HK_TICKERS, #HK_HOOKS
	Chat:Apply('test')
	Chat:Release('test')
	expectEq(#HK_TICKERS, tickers, 'no ticker')
	expectEq(#HK_HOOKS, hooks, 'no secure hook')
	for _, chat in ipairs({ general, log, voice, loot }) do
		expectEq(chat.scripts.OnUpdate, nil, 'no OnUpdate on ' .. chat.name)
		expectEq(chat.hooks, nil, 'no script hook on ' .. chat.name)
		expectEq(chat.textures, nil, 'no texture on ' .. chat.name)
	end
	ResetChat()
	Chat:Apply('test')
end)

---------------------------------------------------------------------------
-- BANZAI Window Skin: the framework, the Blizzard windows, Baganator
---------------------------------------------------------------------------
function Methods:GetBackdropColor() local c = self.backdropColor or { 0, 0, 0, 1 } return c[1], c[2], c[3], c[4] end
function Methods:IsObjectType(kind) return self.kind == kind or (kind == 'Frame' and (self.kind == 'Button' or self.kind == 'ScrollingMessageFrame')) end
local STOCK_FONT = 'Fonts\\FRIZQT__.TTF'
-- a window as ElvUI's Blizzard skin leaves it: 'self' S:HandlePortraitFrame (the frame is the template),
-- 'backdrop' CreateBackdrop (a child panel), 'stock' not skinned by ElvUI at all
local function Window(name, mode, parent)
	local f = HK_NewFrame('Frame', name, parent or UIParent)
	f.w, f.h, f.shown = 338, 424, false
	f.TitleContainer = HK_NewFrame('Frame', nil, f)
	local title = f.TitleContainer:CreateFontString()
	title:SetFont(STOCK_FONT, 12, '')
	title:SetText(name or 'Window')
	title.textColor = { 1, 0.82, 0, 1 }
	f.TitleContainer.TitleText = title
	if mode == 'backdrop' then
		f.backdrop = HK_NewFrame('Frame', nil, f)
		f.backdrop.template, f.backdrop.backdropColor, f.backdrop.w = 'Transparent', { 0, 0, 0, 1 }, 330
	elseif mode ~= 'stock' then
		f.template, f.backdropColor = 'Transparent', { 0, 0, 0, 1 }
	end
	return f
end
local function Title(f) return f.TitleContainer.TitleText end
local function Shown(f) local n = 0 for _, t in ipairs(f.textures or {}) do if t.shown then n = n + 1 end end return n end
local function Keys(f) local list = {} for k in pairs(f) do if k ~= 'textures' and k ~= 'hooks' then list[#list + 1] = tostring(k) end end table.sort(list) return table.concat(list, ' ') end
local function State(id) return Skins.byId[id].state end
local function Material(mode) Theme:DB().panelBackground = mode BanzaiCompat:Refresh() end

local character = Window('CharacterFrame', 'self')
local merchant = Window('MerchantFrame', 'self')
local gossip = Window('GossipFrame', 'backdrop')
local map = Window('WorldMapFrame', 'backdrop')
local friends = Window('FriendsFrame', 'stock')

test('window skins: the six switches in their order, each with its setting; Details and Chat are BANZAI\'s own frames', function()
	local seen = {}
	for i, group in ipairs(Skins.GROUPS) do seen[i] = group.label .. '=' .. group.key .. (group.owned and '(own)' or '') end
	expectEq(table.concat(seen, ', '), 'Blizzard Windows=skinBlizzard, Baganator=skinBaganator, Zygor=skinZygor, Details=detailsFrame(own), Chat=chatFrame(own), ElvUI Panels=skinElvUI', 'the switches')
	local db = Theme:DB()
	expectEq(db.skinBlizzard, true, 'Blizzard windows on by default')
	expectEq(db.skinBaganator, true, 'Baganator on by default')
	expectEq(db.skinZygor, true, 'Zygor on by default')
	expectEq(db.skinElvUI, false, 'ElvUI panels keep the approved colour by default')
	expectEq(db.detailsFrame, true, 'the approved Details frame stays on')
	expectEq(db.chatFrame, true, 'the approved chat frame stays on')
	expectEq(Skins.Supported(), true, 'on WoW Forever')
	-- the registry refuses what is not an adapter, a second adapter of one id, and an adapter for a frame BANZAI owns
	expectEq(Skins:Register({ id = 'x', group = 'blizzard' }), false, 'no windows function')
	expectEq(Skins:Register({ id = 'blizzard.character', group = 'blizzard', windows = function() return {} end }), false, 'an id twice')
	expectEq(Skins:Register({ id = 'own', group = 'details', windows = function() return {} end }), false, 'Details is never skinned twice')
	expectEq(Skins:Register({ id = 'own2', group = 'chat', windows = function() return {} end }), false, 'nor Chat')
	expectEq(Skins:Register({ id = 'nogroup', group = 'weakauras', windows = function() return {} end }), false, 'an unknown group')
	local tier1 = 0
	for _, adapter in ipairs(Skins.adapters) do if adapter.group == 'blizzard' then tier1 = tier1 + 1 end end
	expectEq(tier1, 13, 'the thirteen Tier 1 windows')
	for _, id in ipairs({ 'character', 'spells', 'professions', 'questlog', 'quest', 'merchant', 'gossip', 'trainer', 'mail', 'friends', 'guild', 'inspect', 'trade' }) do
		expect(Skins.byId['blizzard.' .. id] ~= nil, id .. ' is registered')
	end
end)

test('Blizzard windows: the BANZAI surface lies on the panel ElvUI made; the window itself is not changed', function()
	Material('GLASS')
	local before = { character = Keys(character), title = Title(character).text }
	BanzaiCompat:Refresh()
	expectEq(State('blizzard.character').status, 'SKINNED', 'Character')
	expectEq(State('blizzard.merchant').status, 'SKINNED', 'Merchant')
	expectEq(State('blizzard.gossip').status, 'SKINNED', 'Gossip')
	local s = Skins.surfaces[character]
	expect(s ~= nil, 'a surface for the Character window')
	expectEq(#character.textures, 8, 'glass, heading band, four edges, two accent halves')
	for _, t in ipairs(character.textures) do
		expectEq(t.layer, 'BACKGROUND', 'under the window\'s content')
		expect(t.sublevel >= -7 and t.sublevel <= -4, 'over the panel\'s own backdrop, under everything else: ' .. tostring(t.sublevel))
	end
	expectEq(s.glass.points[1][2], character, 'laid on the frame ElvUI templated')
	expectEq(Skins.surfaces[gossip].glass.points[1][2], gossip.backdrop, 'or on the backdrop child ElvUI made')
	-- ElvUI's panel: its centre clear while the glass is on, its colour and border untouched
	expectEq(character.backdropColor[4], 0, 'centre clear')
	expectEq(character.backdropColor[1] .. character.backdropColor[2] .. character.backdropColor[3], '000', 'colour as ElvUI set it')
	expectEq(character.borderColor, nil, 'ElvUI\'s border is not recoloured')
	expectEq(gossip.backdrop.backdropColor[4], 0, 'the backdrop child likewise')
	-- the window: not moved, sized, shown, hidden, re-parented; no field written onto it
	expectEq(#character.points, 0, 'never anchored')
	expectEq(character.allPoints, nil, 'never SetAllPoints')
	expectEq(character.w .. 'x' .. character.h, '338x424', 'never resized')
	expectEq(character.shown, false, 'never shown')
	expectEq(character.parentChanges, nil, 'never re-parented')
	expectEq(character.scripts.OnShow, nil, 'its scripts are not replaced')
	expectEq(character.scripts.OnUpdate, nil, 'no OnUpdate')
	expectEq(Keys(character), before.character, 'no field written onto the window')
	-- the heading: BANZAI's display face on the owner's own title, text, size and colour as they were
	local title = Title(character)
	expectEq(title.text, before.title, 'the title text is its owner\'s')
	expectEq(title.font, Theme:DisplayFontFor('CharacterFrame'), 'the BANZAI display face')
	expectEq(title.fontSize, 12, 'its own size')
	expectEq(title.fontFlags, 'OUTLINE', 'outlined on the dark surface')
	expectEq(title.textColor[1] .. '|' .. title.textColor[2], '1|0.82', 'its own colour on glass')
end)

test('Blizzard windows: a window ElvUI has not skinned is left exactly as it is - and skinned once ElvUI has', function()
	BanzaiCompat:Refresh()
	expectEq(State('blizzard.friends').status, 'NOT READY', 'Friends without ElvUI\'s skin')
	expectEq(State('blizzard.friends').detail, 'ElvUI has not skinned it', 'said why')
	expectEq(Shown(friends), 0, 'no BANZAI texture shows on it')
	expectEq(Title(friends).font, STOCK_FONT, 'its heading is untouched')
	expectEq(friends.backdropColor, nil, 'no colour set')
	-- ElvUI skins it later (its own callback), the window shows: skinned then, through the OnShow post-hook
	friends.template, friends.backdropColor = 'Transparent', { 0, 0, 0, 1 }
	Show(friends)
	expectEq(State('blizzard.friends').status, 'SKINNED', 'skinned when it shows')
	expectEq(Shown(friends), 7, 'the surface (no parchment band on glass)')
	expectEq(#friends.hooks.OnShow, 1, 'one post-hook, made once')
end)

test('window skins are idempotent: refreshing, re-showing and reloading settings add nothing', function()
	for _ = 1, 4 do BanzaiCompat:Refresh() Show(character) end
	expectEq(#character.textures, 8, 'the same eight textures')
	expectEq(#character.hooks.OnShow, 1, 'one OnShow post-hook')
	expectEq(character.backdropColor[4], 0, 'still clear')
	expectEq(Skins.muted[character], 1, 'ElvUI\'s own alpha is remembered once')
	-- ElvUI recolours its panels (a media update): BANZAI clears the centre again and keeps ElvUI's new alpha
	character.backdropColor = { 0.06, 0.06, 0.06, 0.8 }
	Show(character)
	expectEq(character.backdropColor[4], 0, 'clear again')
	expectNear(character.backdropColor[1], 0.06, 'ElvUI\'s new colour kept')
	expectNear(Skins.muted[character], 0.8, 'ElvUI\'s new alpha is the one to give back')
	character.backdropColor = { 0, 0, 0, 0 }
	Skins.muted[character] = 1
end)

test('each skin switches off on its own: the window is exactly its owner\'s again, the others stay skinned', function()
	BanzaiCompat:Refresh()
	BanzaiCompat:Set('skinBlizzard', false)
	expectEq(State('blizzard.character').status, 'OFF', 'Character off')
	expectEq(Shown(character), 0, 'every BANZAI texture hidden')
	expectEq(character.backdropColor[4], 1, 'ElvUI\'s panel has its alpha back')
	expectEq(Skins.muted[character], nil, 'nothing kept')
	local title = Title(character)
	expectEq(title.font .. '|' .. title.fontSize .. '|' .. title.fontFlags, STOCK_FONT .. '|12|', 'the heading has its own font back')
	expectEq(gossip.backdrop.backdropColor[4], 1, 'Gossip likewise')
	expectEq(BanzaiCompat.chatFrame.shown, true, 'the BANZAI HUD is not affected: chat frame')
	expectEq(Theme:DB().detailsFrame, true, 'Details frame setting untouched')
	Show(character)
	expectEq(Shown(character), 0, 'showing the window does not bring the skin back while it is off')
	BanzaiCompat:Set('skinBlizzard', true)
	expectEq(State('blizzard.character').status, 'SKINNED', 'on again')
	expectEq(Shown(character), 7, 'the surface is back')
	expectEq(character.backdropColor[4], 0, 'centre clear again')
end)

test('materials: GLASS is deep and translucent, SOLID opaque, PARCHMENT a heading band with ink over the solid body', function()
	Theme:DB().glassOpacity = 0.4
	Material('GLASS')
	local s = Skins.surfaces[character]
	expectEq(s.material, 'GLASS', 'material')
	expectNear(s.glass.gradient[3].a, Skins.GLASS_MIN, 'a window\'s glass is never thinner than the minimum')
	expectEq(s.band.shown, false, 'no parchment on glass')
	Theme:DB().glassOpacity = 0.9
	Material('GLASS')
	expectNear(s.glass.gradient[3].a, 0.9, 'and follows the glass opacity above it')
	Theme:DB().glassOpacity = 0.72
	Material('SOLID')
	expectEq(s.material, 'SOLID', 'material')
	expectNear(s.glass.gradient[3].a, Theme.SOLID_ALPHA, 'the opaque surface')
	expectEq(s.band.shown, false, 'no parchment on solid')
	expectEq(Title(character).textColor[2], 0.82, 'the owner\'s heading colour on a dark surface')
	Material('PARCHMENT')
	expectEq(s.material, 'PARCHMENT', 'material')
	expectEq(s.band.shown, true, 'the heading band is parchment')
	expect(string.find(s.band.path, 'BanzaiParchmentTile', 1, true), 'the one parchment tile')
	expectEq(s.band.wrapH .. s.band.wrapV, 'REPEATREPEAT', 'repeated, never stretched')
	expectEq(s.band.h, Skins.HEADER, 'only as tall as the heading')
	local u = (338 - 2) * BanzaiCompat.PARCHMENT.density / BanzaiCompat.PARCHMENT.tileW
	expectNear(s.band.coords[2] - s.band.coords[1], u, 'at the panels\' own texel density')
	expectNear(s.glass.gradient[3].a, Theme.SOLID_ALPHA, 'the body under the owner\'s light text stays the dark solid surface')
	local title = Title(character)
	expectEq(title.textColor[1] .. '|' .. title.textColor[2] .. '|' .. title.textColor[3], Skins.INK[1] .. '|' .. Skins.INK[2] .. '|' .. Skins.INK[3], 'dark ink on the parchment band')
	expectEq(title.fontFlags, '', 'ink needs no outline')
	expectNear(s.edges[1].color[1], Skins.EDGE.PARCHMENT[1], 'a parchment-toned border')
	-- a window without a heading band (the map / quest log): parchment is never laid under text BANZAI does not colour
	local m = Skins.surfaces[map]
	expectEq(m.band.shown, false, 'no band on the quest log / map')
	expectEq(Title(map).font, STOCK_FONT, 'and its heading is its owner\'s')
	Material('GLASS')
	expectEq(s.band.shown, false, 'band gone')
	expectEq(title.textColor[1] .. '|' .. title.textColor[2], '1|0.82', 'the owner\'s colour is back off the parchment')
	expectEq(title.fontFlags, 'OUTLINE', 'outlined again')
	expectNear(s.edges[1].color[1], Skins.EDGE.GLASS[1], 'the BANZAI border')
end)

test('ElvUI panels: the panel tone for each material', function()
	Theme:DB().glassOpacity = 0.72
	local glass = Skins.PanelColor('GLASS')
	expectNear(glass.a, Skins.GLASS_MIN, 'glass')
	expectNear(glass.g, Theme.COLORS.glass[2], 'the BANZAI glass colour')
	expectNear(Skins.PanelColor('SOLID').a, Theme.SOLID_ALPHA, 'solid')
	expectNear(Skins.PanelColor('PARCHMENT').a, Theme.SOLID_ALPHA, 'parchment reads as the solid tone on a flat ElvUI panel')
end)

test('load order: a window that arrives later is skinned one frame after its addon loads; other addons queue nothing', function()
	HK_TIMERS = {}
	HK_Fire('ADDON_LOADED', 'SomeOtherAddon')
	expectEq(#HK_TIMERS, 0, 'an unrelated addon queues nothing')
	HK_Fire('ADDON_LOADED', 'Blizzard_TrainerUI') -- (its window is made by the game while it loads; ElvUI skins it in its own handler)
	expectEq(#HK_TIMERS, 1, 'one timer for the trainer adapter')
	local trainer = Window('ClassTrainerFrame', 'self')
	expectEq(trainer.textures, nil, 'nothing yet: ElvUI\'s own skin runs first')
	HK_RunTimers()
	expectEq(State('blizzard.trainer').status, 'SKINNED', 'skinned one frame later')
	expectEq(#trainer.textures, 8, 'the surface')
	expectEq(#HK_TIMERS, 0, 'and no timer is left running')
	-- the addon loaded, the window not made yet: waiting, and no error
	HK_Fire('ADDON_LOADED', 'Blizzard_InspectUI')
	HK_RunTimers()
	expectEq(State('blizzard.inspect').status, 'WAITING', 'no window yet')
	expectEq(State('blizzard.inspect').error, nil, 'no error')
end)

test('combat: nothing is created or changed in combat; the skin is applied when combat ends', function()
	local trade = Window('TradeFrame', 'self')
	HK_IN_COMBAT = true
	BanzaiCompat:Refresh()
	expectEq(State('blizzard.trade').status, 'COMBAT', 'waiting')
	expectEq(trade.textures, nil, 'no texture made in combat')
	expectEq(trade.backdropColor[4], 1, 'ElvUI\'s panel untouched')
	expectEq(trade.hooks, nil, 'no hook made in combat')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(State('blizzard.trade').status, 'SKINNED', 'skinned after combat')
end)

test('optional addons absent: Baganator and Zygor adapters stay dormant without an error', function()
	expectEq(Baganator, nil, 'Baganator is not installed in this stand-in')
	BanzaiCompat:Refresh()
	expectEq(State('baganator').status, 'ABSENT', 'Baganator absent')
	expectEq(State('baganator').error, nil, 'no error')
	expectEq(ns.SkinAdapters.Baganator.attached, nil, 'nothing was attached')
	expectEq(State('zygor').status, 'ABSENT', 'Zygor absent')
	expectEq(State('zygor').error, nil, 'no error')
	expectEq(ns.SkinAdapters.Zygor.attached, nil, 'nothing was attached')
	expectEq(Skins.lastError, nil, 'the refresh did not fail')
	local text = table.concat(Skins:Report(), '\n')
	expect(string.find(text, 'Baganator: on - Baganator windows ABSENT', 1, true), 'reported: ' .. text)
end)

---------------------------------------------------------------------------
-- Baganator 847, as its public skin API (API\Main.lua, Skins\Initialize.lua) behaves
---------------------------------------------------------------------------
local bagSkin, bagListeners, bagFrames = 'elvui', {}, {}
local function Announce(regionType, region, tags)
	local details = { regionType = regionType, region = region, tags = tags }
	bagFrames[#bagFrames + 1] = details
	for _, listener in ipairs(bagListeners) do listener(details) end
	return region
end
local backpack, itemButton, searchBox, divider

test('Baganator: only its windows are skinned, through its own skin API - no item, search box or tab is touched', function()
	HK_LOADED.Baganator = true
	Baganator = { API = { Skins = {
		GetCurrentSkin = function() return bagSkin end,
		GetAllFrames = function() return bagFrames end,
		RegisterListener = function(callback) bagListeners[#bagListeners + 1] = callback end,
	} } }
	-- made at login, before BANZAI looks: the backpack window (ElvUI theme: S:HandlePortraitFrame), an item button, the search box, a divider texture
	backpack = Announce('ButtonFrame', Window('Baganator_SingleViewBackpackViewFrameelvui', 'self'), { 'backpack' })
	itemButton = Announce('ItemButton', HK_NewFrame('Button', nil, backpack))
	searchBox = Announce('SearchBox', HK_NewFrame('EditBox', nil, backpack))
	divider = Announce('Divider', backpack:CreateTexture())
	local own = #backpack.textures
	local listed = #bagFrames
	BanzaiCompat:Refresh()
	expectEq(State('baganator').status, 'SKINNED', 'skinned')
	expectEq(State('baganator').count, 1, 'one window')
	expectEq(#backpack.textures, own + 8, 'the BANZAI surface on the backpack window')
	expectEq(backpack.backdropColor[4], 0, 'its ElvUI panel centre clear')
	expectEq(itemButton.textures, nil, 'the item button is not touched')
	expectEq(itemButton.hooks, nil, 'nor hooked')
	expectEq(searchBox.textures, nil, 'the search box is not touched')
	expectEq(divider.color, nil, 'the divider is not touched')
	expectEq(#bagFrames, listed, 'Baganator\'s own list is only read')
	expectEq(#bagListeners, 1, 'one listener')
	expectEq(backpack.added, nil, 'Baganator\'s own marker is never written')
	for _ = 1, 3 do BanzaiCompat:Refresh() end
	expectEq(#bagListeners, 1, 'the listener is registered once')
	expectEq(#backpack.textures, own + 8, 'and the surface made once')
	expectEq(Title(backpack).font, Theme:DisplayFontFor('x'), 'the heading in the BANZAI face')
end)

test('Baganator: a window made later (the bank, a new theme\'s set) is skinned one frame after Baganator announces it', function()
	HK_TIMERS = {}
	local bank = Window('Baganator_SingleViewBankViewFrameelvui', 'self')
	Announce('ButtonFrame', bank, { 'bank' })
	local guild = Window('Baganator_SingleViewGuildViewFrameelvui', 'self')
	Announce('ButtonFrame', guild, { 'guild' })
	expectEq(#HK_TIMERS, 1, 'one timer however many windows arrive together')
	expectEq(bank.textures, nil, 'not while Baganator is still building it')
	HK_RunTimers()
	expectEq(State('baganator').count, 3, 'backpack, bank, guild bank')
	expectEq(#bank.textures, 8, 'the bank is skinned')
	Announce('ItemButton', HK_NewFrame('Button', nil, bank))
	expectEq(#HK_TIMERS, 0, 'an item button queues nothing')
	Announce('ButtonFrame', bank, { 'bank' })
	expectEq(#HK_TIMERS, 0, 'a window is noted once')
end)

test('Baganator: with another Baganator theme the adapter stands by; switched off it hands every window back', function()
	bagSkin = 'blizzard'
	BanzaiCompat:Refresh()
	expectEq(State('baganator').status, 'NOT READY', 'standing by')
	expect(string.find(State('baganator').detail, 'own theme is "blizzard"', 1, true), 'said why: ' .. tostring(State('baganator').detail))
	expectEq(Shown(backpack) - 1, 0, 'no BANZAI texture shows (the one left is Baganator\'s own divider)')
	expectEq(backpack.backdropColor[4], 1, 'its panel has its alpha back')
	bagSkin = 'elvui'
	BanzaiCompat:Refresh()
	expectEq(State('baganator').status, 'SKINNED', 'skinned again')
	BanzaiCompat:Set('skinBaganator', false)
	expectEq(State('baganator').status, 'OFF', 'off')
	expectEq(backpack.backdropColor[4], 1, 'handed back')
	expectEq(Title(backpack).font, STOCK_FONT, 'heading handed back')
	expectEq(State('blizzard.character').status, 'SKINNED', 'the Blizzard windows keep their skin')
	BanzaiCompat:Set('skinBaganator', true)
	expectEq(State('baganator').status, 'SKINNED', 'on again')
end)

test('off the Banzai profile every window skin is taken off; back on it they return', function()
	HK_ElvData.current = 'HARDKORHUI'
	BanzaiCompat:Refresh()
	expectEq(State('blizzard.character').status, 'OFF', 'Character')
	expectEq(State('baganator').status, 'OFF', 'Baganator')
	expectEq(Skins:Count(), 0, 'nothing skinned')
	expectEq(character.backdropColor[4], 1, 'panels as their owners made them')
	expectEq(Title(character).font, STOCK_FONT, 'headings as their owners made them')
	HK_ElvData.current = NAME
	BanzaiCompat:Refresh()
	expect(Skins:Count() >= 6, 'skinned again: ' .. Skins:Count())
end)

test('window skins poll nothing: no OnUpdate, no ticker, no secure hook for the Blizzard and Baganator skins', function()
	local tickers, hooks = #HK_TICKERS, #HK_HOOKS
	for _ = 1, 3 do BanzaiCompat:Refresh() Show(character) Show(backpack) end
	expectEq(#HK_TICKERS, tickers, 'no ticker')
	expectEq(#HK_HOOKS, hooks, 'no secure hook')
	expectEq(Skins.events.scripts.OnUpdate, nil, 'no OnUpdate on the skins\' event frame')
	for _, f in ipairs({ character, merchant, gossip, backpack }) do expectEq(f.scripts.OnUpdate, nil, 'no OnUpdate on a window') end
	local text = table.concat(Skins:Report(), '\n')
	for _, needle in ipairs({ 'Blizzard Windows: on - Character SKINNED 1', 'Details: on (BANZAI\'s own frame)', 'Chat: on (BANZAI\'s own frame)', 'ElvUI Panels: off' }) do
		expect(string.find(text, needle, 1, true), 'report: ' .. needle .. '\n' .. text)
	end
end)

---------------------------------------------------------------------------
-- Minimap buttons: a dedicated button addon owns them
---------------------------------------------------------------------------
test('minimap buttons: with MinimapButtonButton loaded BANZAI lays out no button and drives no Eltruism bar', function()
	expectEq(BanzaiCompat.MinimapButtonManager(), nil, 'no manager loaded')
	HK_LOADED.MinimapButtonButton = true
	expectEq(BanzaiCompat.MinimapButtonManager(), 'MinimapButtonButton', 'the dedicated button addon')
	local bar = HK_NewFrame('Frame', 'EltruismMinimapButtonBar', UIParent)
	bar:SetSize(200, 30)
	local button = HK_NewFrame('Button', 'DevThreeMinimapButton', bar)
	button.EltruismInBar = true
	button:SetSize(24, 24)
	local calls = 0
	ElvUI_EltreumUI = { UpdateMinimapButtonBar = function() calls = calls + 1 end }
	local ok, why = BanzaiCompat:LayoutMinimapButtonBar()
	expectEq(ok, false, 'not laid out')
	expectEq(why, 'left to MinimapButtonButton', 'said whose they are')
	expectEq(#button.points, 0, 'the button is not anchored')
	expectEq(bar.w .. 'x' .. bar.h, '200x30', 'the bar is not resized')
	BanzaiCompat:RefreshMinimapButtonBar()
	BanzaiCompat:Refresh()
	expectEq(calls, 0, 'Eltruism\'s button bar is not driven by BANZAI')
	HK_IN_COMBAT = true
	BanzaiCompat:RefreshMinimapButtonBar()
	expectEq(BanzaiCompat.minimapButtonsPending, nil, 'nothing left pending for after combat')
	HK_IN_COMBAT = false
	expect(BanzaiCompat.minimapFrame ~= nil and BanzaiCompat.minimapFrame.shown, 'BANZAI still frames the minimap')
	-- without it, dev2's containment is as it was
	HK_LOADED.MinimapButtonButton = nil
	local ok2, why2 = BanzaiCompat:LayoutMinimapButtonBar()
	expectEq(ok2, true, 'dev2 behaviour: ' .. tostring(why2))
	expectEq(button.points[1][1], 'TOPRIGHT', 'contained grid')
	BanzaiCompat:RefreshMinimapButtonBar()
	expectEq(calls, 1, 'and Eltruism\'s bar is refreshed as in dev2')
	ElvUI_EltreumUI = nil
end)

---------------------------------------------------------------------------
-- Zygor Guides Viewer Forever 1.6, as its viewer frame is built (Skins\Default) and re-skinned (ApplySkin / AlignFrame)
---------------------------------------------------------------------------
function Methods:GetBackdropBorderColor() local c = self.borderColor or { 1, 1, 1, 1 } return c[1], c[2], c[3], c[4] end
-- a post-hook as the game makes it: the owner's function runs, its result is returned, then the hook
local recordHook = hooksecurefunc
function hooksecurefunc(target, name, fn)
	recordHook(target, name, fn)
	local original = target[name]
	target[name] = function(...)
		local a, b, c = original(...)
		fn(...)
		return a, b, c
	end
end
local viewer, zygorLogic
local function BuildZygor()
	viewer = HK_NewFrame('Frame', 'ZygorGuidesViewerFrame', UIParent)
	viewer.alpha = 1
	local border = HK_NewFrame('Frame', nil, viewer)
	border.Back = HK_NewFrame('Frame', nil, border)
	border.Toolbar = HK_NewFrame('Frame', nil, border)
	border.TitleBar = HK_NewFrame('Frame', nil, border)
	border.TitleBar.w, border.TitleBar.h = 420, 30
	border.TitleBar.Logo = border.TitleBar:CreateTexture()
	border.TitleBar.Logo.path = 'stand-in-viewer-logo'
	viewer.Border = border
	-- the current goal line: its red is Zygor's meaning (incomplete)
	local line = HK_NewFrame('Frame', nil, border)
	line.back = HK_NewFrame('Frame', nil, line)
	line.back.color = { 0.65, 0.08, 0.10, 0.7 }
	viewer.stepframes = { { lines = { line } } }
	zygorLogic = { skins = 0, aligns = 0, step = 100, guide = 'Stand-in Guide' }
	-- the viewer's own skin pass, as a dark opaque theme sets it: a near-black body edge, a dark steps area, a lighter toolbar (stand-in greys)
	function viewer:ApplySkin()
		zygorLogic.skins = zygorLogic.skins + 1
		self.Border:SetBackdropBorderColor(0.067, 0.067, 0.067, 1)
		self.Border.Toolbar:SetBackdropColor(0.231, 0.231, 0.231, 1)
		self:AlignFrame()
		return 'zygor-result'
	end
	function viewer:AlignFrame()
		zygorLogic.aligns = zygorLogic.aligns + 1
		self.Border.Back:SetBackdropColor(0.125, 0.125, 0.125, 1)
		self.Border.Back:SetBackdropBorderColor(0.125, 0.125, 0.125, 1)
	end
	viewer:ApplySkin()
	zygorLogic.skins, zygorLogic.aligns = 0, 0
	return viewer
end
local Z = ns.SkinAdapters.Zygor
local function Near(color, r, g, b, a, what)
	what = what or 'colour'
	expectNear(color[1], r, what .. ' r') expectNear(color[2], g, what .. ' g') expectNear(color[3], b, what .. ' b') expectNear(color[4], a, what .. ' a')
end
local function ZygorTone(index, material, alpha)
	local t = Z.Tone(Z.PARTS[index], material, alpha or 1)
	return t[1], t[2], t[3], t[4]
end

test('Zygor: the viewer gets the BANZAI tone and the accent line by colour calls only - nothing of the guide is touched', function()
	HK_LOADED.ZygorGuidesViewerForever = true
	BuildZygor()
	Theme:DB().glassOpacity = 0.72
	Material('GLASS')
	expectEq(State('zygor').status, 'SKINNED', 'skinned: ' .. tostring(State('zygor').error))
	local border = viewer.Border
	Near(border.borderColor, ZygorTone(1, 'GLASS'))
	Near(border.Back.backdropColor, ZygorTone(2, 'GLASS'))
	Near(border.Back.borderColor, ZygorTone(3, 'GLASS'))
	Near(border.Toolbar.backdropColor, ZygorTone(4, 'GLASS'))
	expectNear(border.borderColor[4], Skins.GLASS_MIN, 'translucent body on glass')
	expect(border.borderColor[2] > border.borderColor[1] and border.borderColor[2] < 0.1, 'a very dark BANZAI green, not black and not neon')
	-- the accent hairline: BANZAI's own two textures on the title bar, nothing else of the surface
	local bar = border.TitleBar
	local s = Skins.surfaces[bar]
	expectEq(s.accentOnly, true, 'accent only')
	expectEq(s.accent[1].shown and s.accent[2].shown, true, 'the accent shows')
	expectEq(s.glass.shown, false, 'no BANZAI glass over Zygor\'s own body')
	expectEq(s.band.shown, false, 'no parchment')
	expectEq(s.accent[1].points[1][1] .. '>' .. s.accent[1].points[1][3], 'BOTTOMLEFT>BOTTOMLEFT', 'along the title bar\'s bottom edge')
	expectEq(s.accent[1].points[1][2], bar, 'anchored to the bar (BANZAI\'s texture, not Zygor\'s frame)')
	-- never: the viewer's alpha, a size, an anchor, visibility, a backdrop definition, the logo, a step line
	expectEq(viewer.alpha, 1, 'the viewer\'s alpha is never set (Zygor\'s step completion reads it)')
	expectEq(#viewer.points, 0, 'not anchored')
	expectEq(viewer.w, nil, 'not resized')
	expectEq(#bar.points, 0, 'the title bar is not anchored')
	expectEq(bar.w .. 'x' .. bar.h, '420x30', 'nor resized')
	expectEq(bar.Logo.path, 'stand-in-viewer-logo', 'the logo is Zygor\'s')
	expectEq(bar.Logo.color, nil, 'and not tinted')
	local line = viewer.stepframes[1].lines[1]
	Near(line.back.color, 0.65, 0.08, 0.10, 0.7, 'the incomplete goal\'s red')
	expectEq(line.back.textures, nil, 'no BANZAI texture on a step line')
	expectEq(zygorLogic.step .. '|' .. zygorLogic.guide, '100|Stand-in Guide', 'guide state untouched')
	expectEq(viewer.scripts.OnUpdate, nil, 'no OnUpdate')
end)

test('Zygor: its own skin pass still runs whole and returns its result; BANZAI re-tints after it', function()
	local hooks = 0
	for _, h in ipairs(HK_HOOKS) do if h[1] == viewer then hooks = hooks + 1 end end
	expectEq(hooks, 2, 'two post-hooks on the viewer: ApplySkin and AlignFrame')
	local result = viewer:ApplySkin() -- (a size change, an option: Zygor recolours everything)
	expectEq(result, 'zygor-result', 'Zygor\'s function returns what it returned')
	expectEq(zygorLogic.skins, 1, 'Zygor\'s skin pass ran')
	expectEq(zygorLogic.aligns, 1, 'and its alignment inside it')
	Near(viewer.Border.borderColor, ZygorTone(1, 'GLASS'))
	Near(viewer.Border.Back.backdropColor, ZygorTone(2, 'GLASS'))
	Near(viewer.Border.Toolbar.backdropColor, ZygorTone(4, 'GLASS'))
	-- Zygor's own opacity option: its alpha is kept as a factor
	function viewer:ApplySkin()
		self.Border:SetBackdropBorderColor(0.067, 0.067, 0.067, 0.5)
		self.Border.Toolbar:SetBackdropColor(0.231, 0.231, 0.231, 0.5)
	end
	viewer:ApplySkin()
	ns.SkinAdapters.Zygor.AfterSkin() -- (the replaced stand-in function is not hooked: the hook body directly)
	expectNear(viewer.Border.borderColor[4], Skins.GLASS_MIN * 0.5, 'Zygor\'s opacity still applies')
	for _ = 1, 3 do BanzaiCompat:Refresh() end
	hooks = 0
	for _, h in ipairs(HK_HOOKS) do if h[1] == viewer then hooks = hooks + 1 end end
	expectEq(hooks, 2, 'the hooks are made once')
	expectNear(viewer.Border.borderColor[4], Skins.GLASS_MIN * 0.5, 'and a refresh does not compound the alpha')
end)

test('Zygor materials: SOLID is opaque; PARCHMENT keeps the dark tone under the viewer\'s light icons and text', function()
	viewer.Border:SetBackdropBorderColor(0.067, 0.067, 0.067, 1)
	Material('SOLID')
	expectNear(viewer.Border.borderColor[4], Theme.SOLID_ALPHA, 'solid')
	Material('PARCHMENT')
	expectNear(viewer.Border.borderColor[4], Theme.SOLID_ALPHA, 'parchment: the solid dark tone')
	expect(viewer.Border.borderColor[1] < 0.1, 'never a light surface under Zygor\'s light text')
	expectEq(Skins.surfaces[viewer.Border.TitleBar].band.shown, false, 'no parchment band on the viewer')
	Material('GLASS')
	expectNear(viewer.Border.borderColor[4], Skins.GLASS_MIN, 'glass again')
end)

test('Zygor: switched off, the viewer has the colours Zygor last set; the other skins and Zygor itself are unaffected', function()
	viewer.ApplySkin = nil -- (the stand-in's replaced function: Zygor's colours are set by hand below)
	viewer.Border:SetBackdropBorderColor(0.067, 0.067, 0.067, 1)
	viewer.Border.Toolbar:SetBackdropColor(0.231, 0.231, 0.231, 1)
	viewer.Border.Back:SetBackdropColor(0.125, 0.125, 0.125, 1)
	viewer.Border.Back:SetBackdropBorderColor(0.125, 0.125, 0.125, 1)
	BanzaiCompat:Refresh()
	Near(viewer.Border.borderColor, ZygorTone(1, 'GLASS'))
	BanzaiCompat:Set('skinZygor', false)
	expectEq(State('zygor').status, 'OFF', 'off')
	Near(viewer.Border.borderColor, 0.067, 0.067, 0.067, 1, 'the body is Zygor\'s colour')
	Near(viewer.Border.Back.backdropColor, 0.125, 0.125, 0.125, 1, 'the steps area')
	Near(viewer.Border.Back.borderColor, 0.125, 0.125, 0.125, 1, 'its edge')
	Near(viewer.Border.Toolbar.backdropColor, 0.231, 0.231, 0.231, 1, 'the toolbar')
	local s = Skins.surfaces[viewer.Border.TitleBar]
	expectEq(s.accent[1].shown or s.accent[2].shown, false, 'the accent is hidden')
	-- while off, Zygor's skin pass is left exactly alone
	ns.SkinAdapters.Zygor.AfterSkin()
	Near(viewer.Border.borderColor, 0.067, 0.067, 0.067, 1, 'not re-tinted while off')
	expectEq(State('blizzard.character').status, 'SKINNED', 'the Blizzard windows keep their skin')
	expectEq(State('baganator').status, 'SKINNED', 'Baganator keeps its skin')
	BanzaiCompat:Set('skinZygor', true)
	expectEq(State('zygor').status, 'SKINNED', 'on again')
	Near(viewer.Border.borderColor, ZygorTone(1, 'GLASS'))
	-- off the Banzai profile: Zygor's colours as well
	HK_ElvData.current = 'HARDKORHUI'
	BanzaiCompat:Refresh()
	Near(viewer.Border.borderColor, 0.067, 0.067, 0.067, 1, 'Zygor\'s colour off the Banzai profile')
	HK_ElvData.current = NAME
	BanzaiCompat:Refresh()
end)

test('Zygor loaded after BANZAI: the viewer is skinned one frame after Zygor loads; before it exists nothing fails', function()
	local kept = ZygorGuidesViewerFrame
	ZygorGuidesViewerFrame = nil
	local adapter = ns.SkinAdapters.Zygor
	adapter.attached = nil
	BanzaiCompat:Refresh()
	expectEq(State('zygor').status, 'WAITING', 'loaded, the viewer not made yet')
	expectEq(State('zygor').error, nil, 'no error')
	expectEq(adapter.attached, nil, 'not attached yet: asked again later')
	HK_TIMERS = {}
	ZygorGuidesViewerFrame = kept
	HK_Fire('ADDON_LOADED', 'ZygorGuidesViewerForever')
	expectEq(#HK_TIMERS, 1, 'one timer')
	HK_RunTimers()
	expectEq(State('zygor').status, 'SKINNED', 'skinned after Zygor initialised')
	-- a Zygor without the parts this adapter knows: nothing is guessed, nothing fails
	local border = kept.Border
	kept.Border = nil
	BanzaiCompat:Refresh()
	expectEq(State('zygor').status, 'WAITING', 'no title bar: nothing to dress')
	expectEq(State('zygor').error, nil, 'no error')
	kept.Border = border
	BanzaiCompat:Refresh()
	expectEq(State('zygor').status, 'SKINNED', 'back')
end)

---------------------------------------------------------------------------
-- After the independent review: ElvUI's own recolouring followed per panel, the chat windows positioned after a
-- dock, the hand-back retried after combat, roster rebuilds leaving chat and skins alone
---------------------------------------------------------------------------
test('ElvUI recolours a panel BANZAI keeps clear: it is cleared again at once, through ElvUI\'s own plugin callback', function()
	-- the stand-in ElvUI has no plugin callback so far: nothing was registered, nothing failed
	expectEq(Skins:Follow(), false, 'no E:CoroutineCallback: not followed (the next show re-asserts instead)')
	local registered = {}
	local Engine = ElvUI[1]
	function Engine:UpdateFrameTemplate() end
	function Engine:UpdateBackdropColor() end
	function Engine:CoroutineCallback(func, callback) registered[#registered + 1] = { func, callback } end
	BanzaiCompat:Refresh()
	expectEq(#registered, 2, 'asked for once, for ElvUI\'s template and colour updates')
	expectEq(registered[1][1], ElvUI[1].UpdateFrameTemplate, 'the template update')
	expectEq(registered[2][1], ElvUI[1].UpdateBackdropColor, 'the colour update')
	expectEq(registered[1][2], Skins.AfterElvUI, 'BANZAI\'s per-panel handler')
	for _ = 1, 3 do BanzaiCompat:Refresh() end
	expectEq(#registered, 2, 'never asked for again')
	-- ElvUI re-templates the Character window's panel (as E:UpdateFrameTemplates does, one panel at a time)
	expectEq(character.backdropColor[4], 0, 'clear before')
	character.backdropColor = { 0.02, 0.08, 0.05, 0.82 }
	registered[1][2](character, true)
	expectEq(character.backdropColor[4], 0, 'clear again at once - no doubled glass')
	expectNear(character.backdropColor[2], 0.08, 'in ElvUI\'s new colour')
	expectNear(Skins.muted[character], 0.82, 'ElvUI\'s new alpha is the one given back later')
	-- a panel BANZAI does not keep clear is none of its business
	local other = HK_NewFrame('Frame', nil, UIParent)
	other.template, other.backdropColor = 'Transparent', { 0, 0, 0, 0.8 }
	registered[2][2](other, true)
	expectEq(other.backdropColor[4], 0.8, 'another ElvUI panel is left alone')
	registered[2][2](nil)
	-- and after the skin is off, the callback leaves the window alone too
	BanzaiCompat:Set('skinBlizzard', false)
	expectNear(character.backdropColor[4], 0.82, 'given back: ElvUI\'s newest alpha')
	registered[1][2](character, true)
	expectNear(character.backdropColor[4], 0.82, 'not cleared while the skin is off')
	BanzaiCompat:Set('skinBlizzard', true)
	character.backdropColor = { 0, 0, 0, 0 }
	Skins.muted[character] = 1
end)

test('chat: after a dock ElvUI positions all its chat windows once, even when it already holds General as the left window', function()
	ResetChat()
	CH.LeftChatWindow = general -- (ElvUI's own hook on FCF_DockFrame may have promoted General already)
	ElvUI[1].db.chat.panelSnapLeftID = 1
	Chat:Apply('test')
	expectEq(loot.isDocked, true, 'docked')
	expectEq(CH.positioned, 1, 'ElvUI positioned its chat windows after the dock')
	expectEq(Chat.state.snapped, true, 'General is the left window')
	Chat:Apply('again')
	expectEq(CH.positioned, 1, 'and not again when nothing was docked')
end)

test('chat: a window docked again is recorded where it was that time; a failed dock records nothing new', function()
	ResetChat()
	Chat:Apply('first')
	-- its owner undocks it and leaves it elsewhere on the chat frame; BANZAI docks it again at the next pass
	loot.isDocked, loot.shown, loot.rect = nil, true, { 60, 70, 300, 90 }
	loot.w, loot.h = 300, 90
	for i = #GeneralDockManager.DOCKED_CHAT_FRAMES, 1, -1 do if GeneralDockManager.DOCKED_CHAT_FRAMES[i] == loot then table.remove(GeneralDockManager.DOCKED_CHAT_FRAMES, i) end end
	Chat:Apply('second')
	local place = Theme:DB().chatDocked.ChatFrame4
	expectNear(place.x, 60, 'the newer place is the one to hand back')
	expectEq(place.width .. 'x' .. place.height, '300x90', 'and the newer size')
	-- a dock the game refuses: the earlier record stands, the failure is kept, nothing is hidden
	loot.isDocked, loot.shown, loot.rect = nil, true, { 10, 40, 200, 80 }
	local dock = FCF_DockFrame
	FCF_DockFrame = function() error('the game refused') end
	local ok, state = Chat:Apply('third')
	FCF_DockFrame = dock
	expectEq(ok, true, 'the pass itself completes')
	expectEq(state.failed[1], 'Loot / Trade', 'the window is reported as not docked')
	expect(string.find(tostring(Chat.lastError), 'the game refused', 1, true), 'the game\'s error is kept: ' .. tostring(Chat.lastError))
	expectNear(Theme:DB().chatDocked.ChatFrame4.x, 60, 'the record is the last successful one')
	Chat.lastError = nil
	loot.w, loot.h = 420, 108
end)

test('chat: a hand-back blocked by combat is done when combat ends', function()
	ResetChat()
	BanzaiCompat:Set('chatFrame', true)
	expectEq(loot.isDocked, true, 'docked')
	HK_IN_COMBAT = true
	BanzaiCompat:Set('chatFrame', false)
	expectEq(loot.isDocked, true, 'not undocked in combat')
	expectEq(Chat.pending, true, 'remembered')
	HK_IN_COMBAT = false
	HK_Fire('PLAYER_REGEN_ENABLED')
	expectEq(loot.isDocked, nil, 'handed back after combat')
	expectEq(Chat.pending, false, 'nothing pending')
	BanzaiCompat:Set('chatFrame', true)
end)

test('a group or arena roster change rebuilds unit frames only: the chat windows and window skins are not passed over', function()
	ResetChat()
	Chat:Apply('settle')
	loot.isDocked, loot.shown = nil, true -- its owner floats it over the chat frame during the session
	local textures = #character.textures
	local touched = 0
	local touch = Skins.Touch
	Skins.Touch = function(...) touched = touched + 1 return touch(...) end
	HK_FCF = {}
	HK_Fire('GROUP_ROSTER_UPDATE')
	HK_Fire('ARENA_OPPONENT_UPDATE')
	expectEq(#HK_FCF, 0, 'no chat function on a roster change')
	expectEq(loot.isDocked, nil, 'the floated window stays floated')
	expectEq(touched, 0, 'no window skin pass on a roster change')
	expectEq(BanzaiCompat.rosterBuild, nil, 'the marker does not outlive the rebuild')
	expectEq(BanzaiCompat.chatFrame.shown, true, 'the HUD itself was refreshed as before')
	BanzaiCompat:Refresh()
	expect(touched > 0, 'a settings / profile refresh still passes over the skins')
	expectEq(loot.isDocked, true, 'and arranges the chat')
	Skins.Touch = touch
	expectEq(#character.textures, textures, 'nothing was added')
end)
