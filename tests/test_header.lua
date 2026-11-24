-- 1.5.3: the CHAT + DETAILS full-chassis layout on Retail / Midnight - the content regions inside the unchanged
-- bamboo frames (Compat.FILL), and the game's own chat tabs on the CHAT frame's top stalk (Header.lua): the title's
-- font at half its size, outlined letters on the bamboo itself, the selected one opaque. 1.5.3: nothing
-- behind a label, no label beside DAMAGE / HEALING, the CHAT frame's top stalk 2 lower.
local ns = HK_NS
local Theme = ns.Theme
local Compat = ns.Compat
local Header = ns.Header
local NAME = 'JiberishUI - Bushido Private'
local Methods = getmetatable(UIParent).__index

-- what the mocks lack: script post-hooks, fonts read back, the rendered width at a chosen letter width
function Methods:HookScript(script, fn) self.hooks = self.hooks or {} self.hooks[script] = self.hooks[script] or {} table.insert(self.hooks[script], fn) end
function Methods:GetFont() return self.font, self.fontSize, self.fontFlags end
function Methods:GetPoint(i) local p = self.points[i or 1] if p then return unpack(p) end end
function Methods:GetID() return self.id end
function Methods:GetNumPoints() return #self.points end
function Methods:FontTemplate(font, size, outline) self.template = { font, size, outline } self.font, self.fontSize, self.fontFlags = font, size, outline end
HK_LETTER = 0.6 -- a letter's width in font sizes (the real Shojumaru is wider: 0.78)
function Methods:GetStringWidth()
	if issecretvalue(self.text) then local w = {} HK_SECRET_SET[w] = true return w end -- (a secret text's width is a secret too)
	local plain = (self.text or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('[\128-\191]', '') -- (one letter per code point)
	return #plain * (self.fontSize or 10) * HK_LETTER
end
-- a script as the client runs it: the owner's script, then every post-hook
local function Fire(frame, script, ...)
	if frame.scripts[script] then frame.scripts[script](frame, ...) end
	for _, fn in ipairs(frame.hooks and frame.hooks[script] or {}) do fn(frame, ...) end
end
-- a secure post-hook that really runs (the stock stand-in only records it)
function hooksecurefunc(a, b, c)
	HK_HOOKS[#HK_HOOKS + 1] = { a, b, c }
	if type(a) == 'string' then
		local orig = _G[a]
		_G[a] = function(...) local r = { orig(...) } b(...) return unpack(r) end
	else
		local orig = a[b]
		a[b] = function(...) local r = { orig(...) } c(...) return unpack(r) end
	end
end
HK_TIPS = {}
GameTooltip = HK_NewFrame('GameTooltip', 'GameTooltip', UIParent) -- (a frame: Banzai Art's tooltip theme dresses it)
GameTooltip.shown = false
function GameTooltip:SetOwner(owner) self.owner = owner end
function GameTooltip:SetText(text) self.text = text end
function GameTooltip:Show() self.shown = true HK_TIPS[#HK_TIPS + 1] = self.text end
function GameTooltip:Hide() self.shown = false self.owner = nil end
function GameTooltip:IsOwned(owner) return self.owner == owner end

HK_ElvData.current = NAME
ElvUI[1].db = {
	unitframe = { units = { player = { customTexts = {} } } }, movers = {}, actionbar = { bar1 = { buttonsPerRow = 12 } }, general = { minimap = { circle = false } },
	auras = { buffs = { size = 25, height = 21, horizontalSpacing = 6, verticalSpacing = 10, wrapAfter = 10, maxWraps = 2, keepSizeRatio = false } },
	chat = { panelSnapping = true, panelWidth = 474, panelHeight = 159, tabFont = 'Rubik-Bold', tabFontSize = 12, tabFontOutline = 'SHADOWOUTLINE' },
}
ElvUI[1].private = { chat = { enable = true }, skins = { blizzard = { enable = true } } }
HK_NewFrame('AuraContainer', 'ElvUIPlayerBuffs', UIParent)
HK_NewFrame('Button', 'BuffsMover', UIParent)
BanzaiCompatDB = { bar = true, theme = 'VIBRANT', gradient = 'FORWARD' }

---------------------------------------------------------------------------
-- The game's chat dock and ElvUI's chat module, as Retail 12.1.5 and ElvUI 16.01 run them
---------------------------------------------------------------------------
CHAT_FRAMES = {}
local dock = HK_NewFrame('Frame', 'GeneralDockManager', UIParent)
dock.DOCKED_CHAT_FRAMES = {}
dock.scrollChild = HK_NewFrame('Frame', 'GeneralDockManagerScrollFrameChild', dock)
dock.overflowButton = HK_NewFrame('Button', 'GeneralDockManagerOverflowButton', dock)
local CH = { positioned = 0, styled = 0, db = ElvUI[1].db.chat }
local chats = {}
HK_TAB_CLICKS = {}
local function ChatWindow(id, name, docked)
	local f = HK_NewFrame('ScrollingMessageFrame', 'ChatFrame' .. id, UIParent)
	f.id, f.isDocked, f.shown = id, docked or nil, false
	f.GetName = function() return 'ChatFrame' .. id end -- (the frame's own name; f.name is the window's title, as in the game)
	f.name = name
	local tab = HK_NewFrame('Button', 'ChatFrame' .. id .. 'Tab', UIParent)
	tab.GetName = function() return 'ChatFrame' .. id .. 'Tab' end
	tab.id = id
	tab.Text = tab:CreateFontString(nil, 'ARTWORK')
	tab.Text:SetFont('Rubik-Bold', 12, 'SHADOWOUTLINE') -- ElvUI's tab font
	tab.Text:SetText(name)
	-- the game's own tab scripts: a click selects (left) or opens the tab's menu (right); a drag undocks
	tab.scripts.OnClick = function(self, button) HK_TAB_CLICKS[#HK_TAB_CLICKS + 1] = id .. ':' .. tostring(button) if button ~= 'RightButton' then FCF_SelectDockFrame(f) end end
	tab.scripts.OnDragStart = function() HK_TAB_CLICKS[#HK_TAB_CLICKS + 1] = id .. ':drag' end
	tab.scripts.OnEnter = function(self) self.gameEntered = (self.gameEntered or 0) + 1 end
	-- ElvUI holds a tab at 1 (selected) / 0.6 (ElvUI Chat.lua 756), unless its own flag says the call is its own
	hooksecurefunc(tab, 'SetAlpha', function(self, _, skip)
		if skip then return end
		self:SetAlpha((not f.isDocked or f == dock.selected) and 1 or 0.6, true)
	end)
	CHAT_FRAMES[#CHAT_FRAMES + 1] = 'ChatFrame' .. id
	if docked then table.insert(dock.DOCKED_CHAT_FRAMES, f) end
	chats[id] = f
	return f, tab
end
local general, generalTab = ChatWindow(1, 'General', true)
local loot, lootTab = ChatWindow(4, 'Loot / Trade', true)
dock.primary, dock.selected = general, general
general.shown = true
HK_DOCK_UPDATES = 0
function FCFDock_GetSelectedWindow(d) return d.selected end
-- ElvUI's FCFTab_UpdateColors: the tab's text is the window's name (tabSelector NONE), in ElvUI's value colour
function FCFTab_UpdateColors(tab, selected)
	local chat = _G['ChatFrame' .. tab.id]
	tab.selected = selected
	tab.Text:SetText(chat.name)
	tab.Text:SetTextColor(0.2, 0.2, 0.2, 1) -- (a dark value colour: what BANZAI's ink must replace)
end
-- the game's FCFDock_UpdateTabs: the first window's tab on the dock, the others in its scrolling strip, each
-- sized to its text, anchored one after another
function FCFDock_UpdateTabs(d, force)
	if HK_DOCK_IDLE and not force then return end -- (nothing dirty: the game returns at once)
	HK_DOCK_UPDATES = HK_DOCK_UPDATES + 1
	local last
	for i, chat in ipairs(d.DOCKED_CHAT_FRAMES) do
		local tab = _G[chat:GetName() .. 'Tab']
		chat.shown = (chat == d.selected)
		tab:ClearAllPoints()
		tab:Show()
		FCFTab_UpdateColors(tab, chat == d.selected)
		if i == 1 then
			tab:SetParent(d)
			tab:SetPoint('LEFT', d, 'LEFT', 0, 0)
		else
			tab:SetParent(d.scrollChild)
			tab:SetPoint('LEFT', last, 'RIGHT', 0, 0)
		end
		local textWidth = tab.Text:GetStringWidth()
		tab:SetWidth(type(textWidth) == 'number' and textWidth + 20 or 80) -- (the game sizes a secret text's tab itself)
		tab:SetAlpha(chat == d.selected and 1 or 0.4) -- (the game's own tab fade)
		last = tab
	end
	d.overflowButton:SetShown(#d.DOCKED_CHAT_FRAMES > 3)
end
function FCF_SelectDockFrame(chat)
	dock.selected = chat
	FCFDock_UpdateTabs(dock, true)
end
function CH:PositionChat() self.positioned = self.positioned + 1 end
function CH:StyleChat(chat)
	self.styled = self.styled + 1
	_G[chat:GetName() .. 'Tab'].Text:FontTemplate(self.db.tabFont, self.db.tabFontSize, self.db.tabFontOutline)
end
function CH:TabOnLeave(tab) tab.Text:Hide() end -- (ElvUI hides a faded tab's text when the pointer leaves)
CH.LeftChatWindow = general
local baseModule = ElvUI[1].GetModule
ElvUI[1].GetModule = function(self, name, silent) if name == 'Chat' then return CH end return baseModule(self, name, silent) end

---------------------------------------------------------------------------
-- Details as the installed build runs it on Midnight: the game's own damage meter data (session types), its
-- event listener, its locale
---------------------------------------------------------------------------
HK_DETAILS_BLIZZARD = true
HK_DETAILS_CALLS = {}
Details.RegistredEvents = {}
for _, event in ipairs({ 'DETAILS_INSTANCE_CHANGESESSION', 'DETAILS_INSTANCE_CHANGESEGMENT', 'DETAILS_INSTANCE_CHANGEATTRIBUTE', 'DETAILS_INSTANCE_CHANGEMODE', 'DETAILS_DATA_RESET', 'COMBAT_PLAYER_LEAVE' }) do
	Details.RegistredEvents[event] = {}
end
HK_DETAILS_LISTENERS = {}
function Details:CreateEventListener()
	local listener = { registered = {} }
	function listener:RegisterEvent(event, fn)
		if not Details.RegistredEvents[event] then error('unknown event ' .. tostring(event)) end
		self.registered[event] = fn
		table.insert(Details.RegistredEvents[event], fn)
		return true
	end
	HK_DETAILS_LISTENERS[#HK_DETAILS_LISTENERS + 1] = listener
	return listener
end
function Details:SendEvent(event, _, ...) for _, fn in ipairs(self.RegistredEvents[event] or {}) do fn(event, ...) end end
function Details:IsUsingBlizzardAPI() return HK_DETAILS_BLIZZARD end
local WindowMeta = getmetatable(HK_DetailsWindow).__index
function WindowMeta:GetSegmentType() return self.sessionType or 1 end
function WindowMeta:SetSegmentType(kind, refresh, byUser)
	HK_DETAILS_CALLS[#HK_DETAILS_CALLS + 1] = string.format('%d:SetSegmentType(%s,%s,%s)', self.meu_id, tostring(kind), tostring(refresh), tostring(byUser))
	local old = self:GetSegmentType()
	self.sessionType = kind
	if kind ~= old then Details:SendEvent('DETAILS_INSTANCE_CHANGESESSION', nil, self, kind) end
end
function WindowMeta:SetSegmentId(id, byUser) HK_DETAILS_CALLS[#HK_DETAILS_CALLS + 1] = string.format('%d:SetSegmentId(%s,%s)', self.meu_id, tostring(id), tostring(byUser)) self.segmento = id end
function WindowMeta:SetSegment(id, force)
	HK_DETAILS_CALLS[#HK_DETAILS_CALLS + 1] = string.format('%d:SetSegment(%s,%s)', self.meu_id, tostring(id), tostring(force))
	self.segmento = id
	Details:SendEvent('DETAILS_INSTANCE_CHANGESEGMENT', nil, self, id)
end
function WindowMeta:SetMode(mode) HK_DETAILS_CALLS[#HK_DETAILS_CALLS + 1] = self.meu_id .. ':SetMode' self.modo = mode end
HK_DETAILS_LOCALE = { STRING_CURRENT = 'Current', STRING_OVERALL = 'Overall', STRING_SEGMENT = 'Segment' }
HK_LIBS['AceLocale-3.0'] = { GetLocale = function(_, addon) if addon == 'Details' then return HK_DETAILS_LOCALE end end }
HK_DetailsWindow.sessionType, HK_DetailsWindow2.sessionType = 1, 1

local function Build()
	HK_Fire('PLAYER_ENTERING_WORLD', true, false)
	HK_RunTimers()
	HK_RunTimers()
end
-- the frames where the client would have laid them out (the 32-unit bottom panel; a 1923-wide screen)
local SCREEN = 1923
local function Rects()
	local C = Compat
	C.chatFrame.rect = { C.CHAT.left, 31.5, C.CHAT.width, C.CHAT.height }
	local D = C.DETAILS
	local right, bottom = SCREEN + D.right, D.bottom
	HK_DetailsWindow2.baseframe.rect = { right - D.width, bottom, D.width, D.height }
	HK_DetailsWindow.baseframe.rect = { right - 2 * D.width - D.gap, bottom, D.width, D.height }
	C.detailsFrame.rect = { right + D.centerX - D.frameWidth / 2, bottom + D.centerY - D.frameHeight / 2, D.frameWidth, D.frameHeight }
	-- ElvUI's chat text for BushidoPrivateRestore's panel (T.CHAT): Compat.CHAT_CONTENT, above the 32-unit bar
	local T = C.CHAT_CONTENT
	general.rect = { T.x, 32 + T.bottom, T.width, T.height }
end
local function State(tab) return Header.chat.state[tab] end
local function Reset()
	HK_LETTER = 0.6
	for i = #dock.DOCKED_CHAT_FRAMES, 1, -1 do dock.DOCKED_CHAT_FRAMES[i] = nil end
	dock.DOCKED_CHAT_FRAMES[1], dock.DOCKED_CHAT_FRAMES[2] = general, loot
	general.name, loot.name = 'General', 'Loot / Trade'
	dock.selected = general
	CH.LeftChatWindow = general
	HK_ElvData.current = NAME
	local db = Theme:DB()
	db.chatFrame, db.detailsFrame, db.displayFace, db.displayScale, db.panelBackground = true, true, 'BANZAI_DEFAULT', 1, 'GLASS'
	HK_DetailsWindow.sessionType, HK_DetailsWindow2.sessionType = 1, 1
	HK_DetailsWindow.ativa, HK_DetailsWindow2.ativa = true, true
	HK_DETAILS_BLIZZARD = true
	HK_DETAILS_LOCALE = { STRING_CURRENT = 'Current', STRING_OVERALL = 'Overall', STRING_SEGMENT = 'Segment' }
	HK_FONT_FAILS = nil
	Compat:Refresh()
	Rects()
	FCFDock_UpdateTabs(dock, true)
end
local SHOJUMARU = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\fonts\\Shojumaru-Regular.ttf'

test('1.5.3 Banzai Art builds on Retail with the header labels and no error; the version is the private proof\'s', function()
	expectEq(Theme.VERSION, '1.5.3', 'version')
	expectEq(Theme.CHANNEL, 'release', 'a release')
	expect(Header ~= nil and BanzaiCompat.Header == Header, 'the header labels are reachable through BanzaiCompat')
	expectEq(Header.Available(), true, 'used on Retail / Midnight')
	Build()
	Reset()
	expectEq(BanzaiCompat.lastError, nil, 'no module failed: ' .. tostring(BanzaiCompat.lastError))
	expectEq(Header.lastError, nil, 'header labels: ' .. tostring(Header.lastError))
end)

---------------------------------------------------------------------------
-- The frozen geometry
---------------------------------------------------------------------------
test('1.5.3 frozen: the CHAT and DAMAGE / HEALING bamboo frames keep their size and their place, the titles their place, size and letters', function()
	Reset()
	local chat, details = Compat.chatFrame, Compat.detailsFrame
	expectEq(chat.bw .. 'x' .. chat.bh, '493.31x161', 'CHAT frame size')
	expectEq(chat.points[1][1] .. '|' .. chat.points[1][3], 'BOTTOMLEFT|BOTTOMLEFT', 'CHAT anchor')
	expectNear(chat.points[1][4], -0.655, 'flush with the left screen edge')
	expectNear(chat.points[1][5], 31.5, 'on the bottom panel')
	expectEq(details.bw .. 'x' .. details.bh, '493.31x161', 'DAMAGE / HEALING frame size')
	-- the Details frame follows the right window; the wider window and the new offset give the same place on screen
	local D, old = Compat.DETAILS, Compat.DETAILS_152
	expectEq(details.points[1][2], HK_DetailsWindow2.baseframe, 'still following the right window')
	expectNear(D.right + D.centerX, old.right + old.centerX, 'the frame\'s centre where it was (x)')
	expectNear(D.bottom + D.centerY, old.bottom + old.centerY, 'the frame\'s centre where it was (y)')
	expectNear(details.points[1][4], D.centerX, 'anchored with the new offset')
	expectEq(D.frameWidth .. 'x' .. D.frameHeight, old.frameWidth .. 'x' .. old.frameHeight, 'the frame\'s numbers')
	-- the titles: on the top stalk's axis, where 1.3.6 put them, at the display size, fully opaque
	local line = Compat.PANEL.outer + Compat.StalkDiameter() / 2
	local centre = details.bw / 2
	local TT = Compat.DETAILS_TITLE
	local dmg, heal, chatTitle = Compat.detailsTitles[1], Compat.detailsTitles[2], Compat.chatTitle
	expectEq(HK_Plain(chatTitle.text.text) .. '/' .. HK_Plain(dmg.text.text) .. '/' .. HK_Plain(heal.text.text), 'CHAT/DAMAGE/HEALING', 'the titles\' letters')
	expectEq(chatTitle.points[1][1], 'CENTER', 'CHAT centred')
	expectNear(chatTitle.points[1][4], chat.bw / 2, 'on the frame\'s centre')
	expectNear(chatTitle.points[1][5], -line, 'on the top stalk')
	expectNear(dmg.points[1][4], centre - 215 + TT.inset - TT.pad, 'DAMAGE where it was (215 left of the centre)')
	expectNear(heal.points[1][4], centre + 215 - TT.inset + TT.pad, 'HEALING where it was (215 right of the centre)')
	for _, t in ipairs({ chatTitle, dmg, heal }) do
		expectEq(t.text.font, SHOJUMARU, 'title font')
		expectEq(t.text.fontSize, 23, 'title size (22 at the BANZAI Default 105 %)')
		expectEq(t:GetAlpha(), 1, 'fully opaque')
		expectEq(t.strata, 'MEDIUM', 'above the stalk')
	end
	-- the divider on the frame's centre, between the two meters
	expectNear(details.divider[1].points[1][4] + details.dividerWidth / 2, centre, 'the centre divider on the centre')
end)

test('1.5.3 CHAT top stalk: 2 units lower inside the unchanged frame - its pieces and the two rope ties on it; the CHAT title, the side and bottom stalks, the background, the chat text and the Details frame where they were', function()
	Reset()
	local chat, details = Compat.chatFrame, Compat.detailsFrame
	local P, d = Compat.PANEL, Compat.StalkDiameter()
	local usual = P.outer + d / 2
	expectEq(Compat.CHAT_TOP.drop, 2, 'a few pixels, no more')
	expectEq(chat.bw .. 'x' .. chat.bh, '493.31x161', 'the frame\'s outer size')
	expectNear(chat.points[1][4], -0.655, 'its place (x)')
	expectNear(chat.points[1][5], 31.5, 'its place (y)')
	expectNear(chat.axis.top, usual + 2, 'the top stalk\'s axis 2 lower')
	expectNear(chat.axis.bottom, chat.bh - usual, 'the bottom stalk where it was')
	expectNear(chat.axis.left, usual, 'the left stalk where it was')
	expectNear(chat.axis.right, chat.bw - usual, 'the right stalk where it was')
	expectNear(details.axis.top, usual, 'the DAMAGE / HEALING frame\'s top stalk is not moved')
	expectEq(details.topDrop, nil, 'no drop on the Details frame')
	local tops, bottoms = 0, 0
	for i = 1, chat.pieceCount do
		local piece = chat.pieces[i]
		local t = piece.texture
		if piece.stalk == 'top' then
			tops = tops + 1
			expectNear(-t.points[1][5] + t.h / 2, usual + 2, 'a piece of the top stalk on the lower axis')
		elseif piece.stalk == 'bottom' then
			bottoms = bottoms + 1
			expectNear(-t.points[1][5] + t.h / 2, chat.bh - usual, 'a piece of the bottom stalk on its axis')
		end
	end
	expect(tops >= 3 and bottoms >= 3, 'both stalks drawn (' .. tops .. ', ' .. bottoms .. ')')
	local tie = P.tie * d
	for i, t in ipairs(chat.ties) do
		expectNear(-t.points[1][5] + tie / 2, (i <= 2) and usual + 2 or chat.bh - usual, 'rope tie ' .. i .. ' on its crossing')
	end
	-- what does not move: the title, the background, the text
	expectNear(Compat.chatTitle.points[1][5], -usual, 'the CHAT title where it was')
	if chat.glass then expectNear(chat.glass.points[1][5], -usual, 'the background where it was (still under the stalk)') end
	expect(usual > chat.axis.top - d / 2, 'the background starts under the lowered stalk, not above it')
	expect(Compat.BAND.inset + Compat.FILL.chatTop > chat.axis.top + d / 2, 'the chat text starts under the lowered stalk')
	local TT = Compat.DETAILS_TITLE
	expect(Compat.BAND.inset + Compat.FILL.chatTop > usual + TT.size * 0.78 / 2 + TT.gap + TT.accent, 'and under the title\'s accent line')
	-- the tabs stand on it
	expectNear(generalTab.points[1][5], -chat.axis.top, 'General on the lowered stalk')
	expectNear(lootTab.points[1][5], -chat.axis.top, 'Loot / Trade on the lowered stalk')
	-- laid out again: the same
	local n = chat.pieceCount
	Compat:Refresh()
	expectNear(chat.axis.top, usual + 2, 'the same after a refresh')
	expectEq(chat.pieceCount, n, 'the same pieces')
end)

---------------------------------------------------------------------------
-- CHAT: the content region
---------------------------------------------------------------------------
test('1.5.3 chat content bounds: ElvUI\'s chat text fills the useful interior of the CHAT frame - 4.155 from each side stalk, 4 above the bottom stalk, 9 under the top stalk (clear of the CHAT title and its accent line)', function()
	Reset()
	local F, T = Compat.FILL, Compat.CHAT_CONTENT
	local l, r, t, b = Header.Gutters(Compat.chatFrame, general)
	expectNear(l, 4.155, 'left gutter')
	expectNear(r, 4.155, 'right gutter')
	expectNear(l, r, 'the same on both sides')
	expectNear(b, F.gutter, 'bottom gutter')
	expectNear(t, F.chatTop, 'top gutter')
	-- the interior between the stalks is 472.31 x 140; the text takes 464 x 127 of it (1.5.2: 420 x 108)
	local inside = Compat.CHAT.width - 2 * Compat.BAND.inset
	expectNear(inside, 472.31, 'the room between the side stalks')
	expectEq(T.width .. 'x' .. T.height, '464x127', 'the chat text')
	expect(T.width / inside > 0.98, 'nearly the whole width (' .. T.width / inside .. ')')
	expect(T.width * T.height > 1.29 * 420 * 108, 'at least 29 % more room than 1.5.2\'s 420 x 108')
	-- clear of the title: the title's backing and its accent line end 7.58 under the stalk's inner edge
	local TT = Compat.DETAILS_TITLE
	local overhang = (Compat.PANEL.outer + Compat.StalkDiameter() / 2) + TT.size * 0.78 / 2 + TT.gap + TT.accent - Compat.BAND.inset
	expect(F.chatTop > overhang, 'the text starts under the CHAT title\'s accent line (' .. overhang .. ')')
	-- nothing outside the frame
	expect(l > 0 and r > 0 and t > 0 and b > 0, 'inside the bamboo on every side')
end)

---------------------------------------------------------------------------
-- CHAT: the labels
---------------------------------------------------------------------------
test('1.5.3 chat tabs on the top stalk: General left of CHAT, Loot / Trade right of it - the game\'s own tab buttons, re-anchored, never copies', function()
	Reset()
	local chassis, title = Compat.chatFrame, Compat.chatTitle
	local line = chassis.axis.top -- (the CHAT frame's top stalk: 2 lower than a frame's, Compat.CHAT_TOP)
	expectNear(line, Compat.PANEL.outer + Compat.StalkDiameter() / 2 + 2, 'the CHAT frame\'s top stalk')
	local left, right, spanLine = Header:Spans(chassis, title)
	expectNear(spanLine, line, 'the labels\' line is the stalk\'s axis')
	for _, tab in ipairs({ generalTab, lootTab }) do
		expectEq(tab.points[1][1] .. '|' .. tab.points[1][3], 'LEFT|TOPLEFT', 'anchored to the frame\'s top edge')
		expectEq(tab.points[1][2], chassis, 'on the BANZAI CHAT frame')
		expectNear(tab.points[1][5], -line, 'on the top stalk\'s axis')
		expectEq(#tab.points, 1, 'one anchor (the game\'s own is replaced, not added to)')
		expectEq(tab.shown, true, 'shown')
		expectEq(tab.Text.shown, true, 'its letters shown')
	end
	expectNear(generalTab.points[1][4], left.from, 'General from the left end, clear of the corner\'s rope tie')
	expectNear(lootTab.points[1][4] + lootTab.w, right.to, 'Loot / Trade against the right end, clear of the other tie')
	expect(generalTab.points[1][4] + generalTab.w <= left.to + 1e-6, 'General ends before the CHAT title')
	expect(lootTab.points[1][4] >= right.from - 1e-6, 'Loot / Trade starts after the CHAT title')
	-- the labels are the real tabs: the same objects the game made, their text the game's
	expectEq(State(generalTab).chat, general, 'General\'s own tab')
	expectEq(State(lootTab).chat, loot, 'Loot / Trade\'s own tab')
	expectEq(generalTab.Text.text, 'General', 'the tab\'s own text')
	expectEq(lootTab.Text.text, 'Loot / Trade', 'the tab\'s own text')
	-- a tab of the scrolling strip would be cut off outside it: on the stalk it is a child of the dock
	expectEq(lootTab.parent, dock, 'out of the dock\'s scrolling strip')
	expectEq(generalTab.parent, dock, 'the first tab where the game put it')
	-- no second label anywhere: BANZAI makes no text of its own
	for _, f in ipairs(HK_Frames()) do
		if f.kind == 'FontString' and f ~= generalTab.Text and f ~= lootTab.Text then
			expect(f.text ~= 'General' and f.text ~= 'Loot / Trade', 'no copy of a tab label')
		end
	end
end)

test('1.5.3 chat label font: the CHAT title\'s own font file and flags, at exactly half its size', function()
	Reset()
	local title = Compat.chatTitle
	local path, size, flags = title.text:GetFont()
	expectEq(path, SHOJUMARU, 'the title is in Shojumaru')
	expectEq(size, 23, 'at 23')
	for _, tab in ipairs({ generalTab, lootTab }) do
		expectEq(tab.Text.font, path, 'the same font file as the title')
		expectEq(tab.Text.fontFlags, flags, 'the same flags')
		expectEq(tab.Text.fontSize, size * 0.5, 'half the title\'s size')
		expectEq(tab.Text.fontSize, 11.5, '11.5')
		expectEq(tab.Text.banzaiHeader.fallback, false, 'no fallback')
		-- the letters' stroke: the title's own outline, and a black edge under it - the same for every label
		expect(string.find(tab.Text.fontFlags, 'OUTLINE', 1, true) and not string.find(tab.Text.fontFlags, 'THICK', 1, true), 'outlined as the title is, never thick')
		expectEq(table.concat(tab.Text.shadowColor, '/'), '0/0/0/1', 'a black edge, fully opaque (it fades with the label, not by itself)')
		expectEq(table.concat(tab.Text.shadow, '/'), '1/-1', 'one unit down and right')
	end
	expectEq(Header.CONTRACT.ratio, 0.5, 'the ratio is a size ratio')
	-- another display face, another display size: the labels follow the title, whatever it is
	Compat:Set('displayFace', 'OSAKA_SANS')
	local p2, s2 = title.text:GetFont()
	expect(string.find(p2, 'osaka-re.ttf', 1, true), 'the title in Osaka Sans')
	expectEq(s2, 22, 'at 22 (no 105 % outside BANZAI Default)')
	expectEq(generalTab.Text.font, p2, 'the labels in Osaka Sans too')
	expectEq(generalTab.Text.fontSize, 11, 'half of 22')
	Compat:Set('displayFace', 'BANZAI_DEFAULT')
	Compat:Set('displayScale', 1.2)
	local _, s3 = title.text:GetFont()
	expectEq(s3, 28, 'the title at 120 % (22 x 1.2 x 1.05)')
	expectEq(lootTab.Text.fontSize, 14, 'half of 28')
	expectEq(lootTab.Text.font, SHOJUMARU, 'Shojumaru again')
	Compat:Set('displayScale', 1)
	-- ElvUI styles its chat windows again (its own tab font): the labels are the title's again at once
	CH:StyleChat(general)
	expectEq(generalTab.Text.font, SHOJUMARU, 'after ElvUI\'s styling')
	expectEq(generalTab.Text.fontSize, 11.5, 'and half the title\'s size')
end)

test('1.5.3 chat label opacity: the selected tab exactly 1.0, every other exactly 0.5 - whatever the game or ElvUI set', function()
	Reset()
	expectEq(generalTab:GetAlpha(), 1.0, 'General selected: 1.0')
	expectEq(lootTab:GetAlpha(), 0.5, 'Loot / Trade inactive: 0.5')
	expectEq(Header.CONTRACT.selected .. '/' .. Header.CONTRACT.inactive, '1.0/0.5', 'the contract')
	-- the game fades its tabs, ElvUI holds an inactive tab at 0.6: neither is what the tab has
	lootTab:SetAlpha(0.2)
	expectEq(lootTab:GetAlpha(), 0.5, 'after the game\'s fade: 0.5')
	lootTab:SetAlpha(1)
	expectEq(lootTab:GetAlpha(), 0.5, 'after a fade in: 0.5')
	generalTab:SetAlpha(0.4)
	expectEq(generalTab:GetAlpha(), 1.0, 'the selected tab stays 1.0')
	-- the letters themselves are opaque and bright: the opacity is the tab's alpha, not a grey text
	for _, tab in ipairs({ generalTab, lootTab }) do
		local c = tab.Text.textColor
		expectEq(c[4], 1, 'text alpha 1')
		expect(c[1] > 0.9 and c[2] > 0.9 and c[3] > 0.9, 'the same bright ink on the selected and the inactive tab')
	end
	expectEq(lootTab.Text.textColor[1], generalTab.Text.textColor[1], 'no dimmer colour for the inactive tab')
end)

test('1.5.3 chat selection: a click on a tab is the game\'s own click - the window switches and the opacities swap at once; the right click and the drag stay the tab\'s own', function()
	Reset()
	HK_TAB_CLICKS = {}
	local click, drag = lootTab.scripts.OnClick, lootTab.scripts.OnDragStart
	Fire(lootTab, 'OnClick', 'LeftButton')
	expectEq(dock.selected, loot, 'Loot / Trade selected by the game')
	expectEq(loot.shown and not general.shown, true, 'its window on show')
	expectEq(lootTab:GetAlpha(), 1.0, 'Loot / Trade now 1.0')
	expectEq(generalTab:GetAlpha(), 0.5, 'General now 0.5')
	Fire(generalTab, 'OnClick', 'LeftButton')
	expectEq(dock.selected, general, 'General again')
	expectEq(generalTab:GetAlpha() .. '/' .. lootTab:GetAlpha(), '1.0/0.5', 'swapped back')
	-- the tab's own scripts are the ones the game set: BANZAI replaced none of them
	expectEq(lootTab.scripts.OnClick, click, 'OnClick untouched')
	expectEq(lootTab.scripts.OnDragStart, drag, 'OnDragStart untouched')
	Fire(lootTab, 'OnClick', 'RightButton')
	Fire(lootTab, 'OnDragStart')
	expectEq(table.concat(HK_TAB_CLICKS, ' '), '4:LeftButton 1:LeftButton 4:RightButton 4:drag', 'left click, right click (the tab\'s menu) and drag all reach the game\'s scripts')
	expectEq(dock.selected, general, 'a right click selects nothing')
	-- a selection made anywhere else (the game's own function) is followed too
	FCF_SelectDockFrame(loot)
	expectEq(lootTab:GetAlpha() .. '/' .. generalTab:GetAlpha(), '1.0/0.5', 'followed')
	FCF_SelectDockFrame(general)
end)

test('1.5.3 chat hover: an inactive tab is brighter under the pointer and exactly 0.5 again when it leaves; the selected tab stays 1.0; ElvUI hiding a faded tab\'s text does not hide the label', function()
	Reset()
	Fire(lootTab, 'OnEnter')
	expectEq(lootTab:GetAlpha(), Header.CONTRACT.hover, 'brighter under the pointer')
	expect(Header.CONTRACT.hover > 0.5 and Header.CONTRACT.hover <= 1, 'between inactive and selected')
	lootTab:SetAlpha(0.3) -- (the game fading while the pointer is on it)
	expectEq(lootTab:GetAlpha(), Header.CONTRACT.hover, 'held while hovered')
	expectEq(lootTab.gameEntered, 1, 'the tab\'s own OnEnter ran first')
	Fire(lootTab, 'OnLeave')
	expectEq(lootTab:GetAlpha(), 0.5, 'exactly 0.5 again')
	Fire(generalTab, 'OnEnter')
	expectEq(generalTab:GetAlpha(), 1.0, 'the selected tab: 1.0 under the pointer')
	Fire(generalTab, 'OnLeave')
	expectEq(generalTab:GetAlpha(), 1.0, 'and after')
	-- ElvUI's fading tabs: the text hidden when the pointer leaves the chat - the label stays
	CH:TabOnLeave(lootTab)
	expectEq(lootTab.Text.shown, true, 'the label stays visible')
	expectEq(lootTab:GetAlpha(), 0.5, 'at 0.5')
end)

test('1.5.3 chat title collision: no label ever touches the CHAT title, leaves the frame or overlaps another label - from one tab to thirty', function()
	Reset()
	local chassis, title = Compat.chatFrame, Compat.chatTitle
	local S = Header.STYLE
	local names = { 'General', 'Loot / Trade', 'Combat Log', 'Guild', 'Whispers', 'Trade', 'LookingForGroup', 'Officer', 'Raid', 'A very long custom chat window name', 'Party', 'Say' }
	local extra = {}
	for count = 1, 30 do
		for i = #dock.DOCKED_CHAT_FRAMES, 1, -1 do dock.DOCKED_CHAT_FRAMES[i] = nil end
		for i = 1, count do
			local chat
			if i == 1 then chat = general elseif i == 2 then chat = loot else
				extra[i] = extra[i] or (ChatWindow(10 + i, names[(i - 1) % #names + 1] .. ' ' .. i, false))
				chat = extra[i]
				chat.isDocked = true
			end
			dock.DOCKED_CHAT_FRAMES[i] = chat
		end
		FCFDock_UpdateTabs(dock, true)
		expectEq(Header.chat.count, count, count .. ' tabs: every one presented')
		local boxes = {}
		for i = 1, count do
			local chat = dock.DOCKED_CHAT_FRAMES[i]
			local tab = _G[chat:GetName() .. 'Tab']
			local x0, x1 = tab.points[1][4], tab.points[1][4] + tab.w
			boxes[#boxes + 1] = { x0, x1 }
			expect(tab.w >= 1, count .. ' tabs: tab ' .. i .. ' keeps a width to click (' .. tab.w .. ')')
			expectEq(tab.shown, true, count .. ' tabs: tab ' .. i .. ' reachable')
			expect(x0 >= 0 and x1 <= chassis.bw + 1e-6, count .. ' tabs: tab ' .. i .. ' inside the frame')
			expect(x1 <= title.x0 - S.clear + 1e-6 or x0 >= title.x1 + S.clear - 1e-6, count .. ' tabs: tab ' .. i .. ' clear of the CHAT title (' .. x0 .. ' .. ' .. x1 .. ')')
		end
		table.sort(boxes, function(a, b) return a[1] < b[1] end)
		for i = 2, #boxes do expect(boxes[i][1] >= boxes[i - 1][2] - 1e-6, count .. ' tabs: no two labels overlap') end
		-- the first half left of the title, the rest right of it
		local leftCount = 0
		for _, box in ipairs(boxes) do if box[2] <= title.x0 then leftCount = leftCount + 1 end end
		expectEq(leftCount, math.ceil(count / 2), count .. ' tabs: the first half left of CHAT')
	end
	expectEq(dock.overflowButton.shown, false, 'the game\'s "more tabs" arrow has nothing to open: every tab is on the stalk')
	for i = 3, 30 do extra[i].isDocked = nil end
end)

test('1.5.3 chat truncation: a label that does not fit is shortened by the client (never cut by a neighbour), the whole name is in its tooltip, and a tab that fits has no tooltip of BANZAI\'s', function()
	Reset()
	-- two tabs fit: nothing shortened, no tooltip
	HK_TIPS = {}
	Fire(lootTab, 'OnEnter') Fire(lootTab, 'OnLeave')
	expectEq(State(lootTab).truncated, false, 'Loot / Trade fits')
	expectEq(#HK_TIPS, 0, 'no tooltip for a label that fits')
	-- a very long name in a narrow span
	loot.name = 'An extremely long custom chat window name that cannot fit beside the title at all'
	FCFDock_UpdateTabs(dock, true)
	local st = State(lootTab)
	local _, right = Header:Spans(Compat.chatFrame, Compat.chatTitle)
	expectEq(st.truncated, true, 'shortened')
	expect(lootTab.w <= right.to - right.from + 1e-6, 'no wider than its side of the stalk')
	expectNear(lootTab.Text.w, lootTab.w - 2 * Header.STYLE.pad, 'the letters are given the room that is left: the client ends them with an ellipsis')
	expectEq(lootTab.Text.wordWrap, false, 'on one line')
	expectEq(lootTab.Text.text, loot.name, 'the tab\'s own text is not rewritten')
	Fire(lootTab, 'OnEnter')
	expectEq(HK_TIPS[#HK_TIPS], loot.name, 'the whole name in the tooltip')
	expectEq(GameTooltip.owner, lootTab, 'on the tab')
	Fire(lootTab, 'OnLeave')
	expectEq(GameTooltip.shown, false, 'put away when the pointer leaves')
	-- General beside it is whole
	expectEq(State(generalTab).truncated, false, 'General is not shortened')
	-- fits again: whole again
	loot.name = 'Loot / Trade'
	FCFDock_UpdateTabs(dock, true)
	expectEq(State(lootTab).truncated, false, 'whole again')
	expectEq(lootTab.Text.w, 0, 'its letters free again')
end)

test('1.5.3 Header.Fit: labels as they are while they fit; then the gap closes; then the widest give way first to one common width - never more than the room', function()
	local S = Header.STYLE
	local w, gap, cut = Header.Fit({ 50, 60 }, 200, S)
	expectEq(w[1] .. '/' .. w[2] .. '/' .. gap .. '/' .. tostring(cut), '50/60/' .. S.gap .. '/false', 'they fit')
	w, gap, cut = Header.Fit({ 50, 60 }, 115, S)
	expectEq(w[1] .. '/' .. w[2] .. '/' .. tostring(cut), '50/60/false', 'the gap closes first')
	expectNear(gap, 5, 'to what is left')
	w, gap, cut = Header.Fit({ 20, 100, 60 }, 106, S)
	expectEq(cut, true, 'shortened')
	expectEq(gap, S.minGap, 'the least gap')
	expectEq(w[1], 20, 'the short label whole')
	expectNear(w[2], 40, 'the widest cut to the common width')
	expectNear(w[3], 40, 'and the next')
	expectNear(w[1] + w[2] + w[3] + 2 * gap, 106, 'exactly the room')
	for _, room in ipairs({ 0, 1, 7, 30, 59.5, 400 }) do
		for n = 1, 40 do
			local widths = {}
			for i = 1, n do widths[i] = 10 + (i * 37 % 90) end
			local out, g = Header.Fit(widths, room, S)
			local total = 0
			for i = 1, n do
				total = total + out[i]
				expect(out[i] <= widths[i] + 1e-9 and out[i] >= 0, 'never wider than the label, never negative')
			end
			expect(total + g * (n - 1) <= room + 1e-6, n .. ' labels in ' .. room .. ': within the room (' .. total + g * (n - 1) .. ')')
		end
	end
	local placed = Header.Place({ 30, 40 }, 100, 300, 'RIGHT', S)
	expectNear(placed[2].x + placed[2].width, 300, 'RIGHT: against the span\'s end')
	expectNear(placed[1].x, 300 - 40 - S.gap - 30, 'in order')
	placed = Header.Place({ 30, 40 }, 100, 300, 'LEFT', S)
	expectNear(placed[1].x, 100, 'LEFT: from the span\'s start')
end)

test('1.5.3 chat ownership: only while BANZAI presents the chat - another profile, the chat frame off or General out of ElvUI\'s left panel hands every tab back to the game and ElvUI', function()
	Reset()
	local function handedBack(why)
		expectEq(Header.chat.active, false, why .. ': not presented')
		expectEq(State(lootTab).owned, false, why .. ': the tab is the game\'s')
		expectEq(lootTab.points[1][2] ~= Compat.chatFrame, true, why .. ': anchored by the game again')
		expectEq(lootTab.parent, dock.scrollChild, why .. ': back in the dock\'s strip')
		expectEq(lootTab.Text.font, 'Rubik-Bold', why .. ': ElvUI\'s tab font')
		expectEq(lootTab.Text.fontSize, 12, why .. ': ElvUI\'s tab size')
		expectEq(lootTab.Text.w, 0, why .. ': its letters free')
		lootTab:SetAlpha(0.3)
		expectEq(lootTab:GetAlpha(), 0.6, why .. ': ElvUI\'s own 0.6 holds again (BANZAI pins nothing)')
		HK_TIPS = {}
		Fire(lootTab, 'OnEnter') Fire(lootTab, 'OnLeave')
		expectEq(lootTab:GetAlpha(), 0.6, why .. ': no hover of BANZAI\'s')
	end
	HK_ElvData.current = 'HARDKORHUI'
	Compat:Refresh()
	handedBack('another profile')
	Reset()
	expectEq(lootTab:GetAlpha(), 0.5, 'presented again')
	Compat:Set('chatFrame', false)
	handedBack('the chat frame off')
	Reset()
	CH.LeftChatWindow = nil
	FCFDock_UpdateTabs(dock, true)
	handedBack('General not in ElvUI\'s left panel')
	Reset()
	-- a window undocked by the player: its tab is the game's, the others are laid out again
	local n = HK_DOCK_UPDATES
	table.remove(dock.DOCKED_CHAT_FRAMES, 2)
	loot.isDocked = nil
	FCFDock_UpdateTabs(dock, true)
	expectEq(State(lootTab).owned, false, 'the undocked window\'s tab is released')
	expectEq(Header.chat.count, 1, 'one tab on the stalk')
	lootTab:SetAlpha(1)
	expectEq(lootTab:GetAlpha(), 1, 'a floating window\'s tab: ElvUI\'s 1, not pinned')
	loot.isDocked = true
end)

test('1.5.3 chat reload and repeat: laying the tabs out again changes nothing and hooks nothing twice; nothing runs per frame', function()
	Reset()
	local hooks, tickers = #HK_HOOKS, #HK_TICKERS
	local x1, x2, w1, w2 = generalTab.points[1][4], lootTab.points[1][4], generalTab.w, lootTab.w
	Build() -- a /reload's login pass
	Compat:Refresh()
	Header:Refresh('again')
	FCFDock_UpdateTabs(dock, true)
	expectEq(#HK_HOOKS, hooks, 'no hook made twice')
	expectEq(#HK_TICKERS, tickers, 'no ticker')
	expectNear(generalTab.points[1][4], x1, 'General where it was')
	expectNear(lootTab.points[1][4], x2, 'Loot / Trade where it was')
	expectEq(generalTab.w .. '/' .. lootTab.w, w1 .. '/' .. w2, 'the same widths')
	expectEq(generalTab:GetAlpha() .. '/' .. lootTab:GetAlpha(), '1.0/0.5', 'the same opacities')
	expectEq(#generalTab.hooks.OnEnter, 1, 'one pointer hook per tab')
	for _, tab in ipairs({ generalTab, lootTab }) do expectEq(tab.scripts.OnUpdate, nil, 'no OnUpdate on a tab') end
	expectEq(Header.chat.frame, nil, 'no frame of BANZAI\'s behind the tabs')
	-- the hooks are post-hooks of the game's and ElvUI's own functions - nothing is replaced, nothing polled
	local names = {}
	for i = 1, #HK_HOOKS do names[#names + 1] = type(HK_HOOKS[i][1]) == 'string' and HK_HOOKS[i][1] or tostring(HK_HOOKS[i][2]) end
	local text = table.concat(names, ' ')
	for _, needle in ipairs({ 'FCFDock_UpdateTabs', 'FCFTab_UpdateColors', 'StyleChat', 'PositionChat', 'TabOnLeave' }) do expect(string.find(text, needle, 1, true), 'follows ' .. needle) end
end)

test('1.5.3 edit box and chat windows: BANZAI touches no edit box, no chat window\'s size, place, parent, scroll or script', function()
	Reset()
	local edit = HK_NewFrame('EditBox', 'ChatFrame1EditBox', general)
	general.editBox = edit
	edit.points = { { 'TOPRIGHT', UIParent, 'TOPRIGHT', 2, 22 } }
	local before = { #general.points, general.w, general.h, general.parent, general.parentChanges, general.scripts.OnMouseWheel, #edit.points, edit.shown, edit.parentChanges }
	Compat:Refresh()
	Header:Refresh('again')
	FCF_SelectDockFrame(loot)
	FCF_SelectDockFrame(general)
	local after = { #general.points, general.w, general.h, general.parent, general.parentChanges, general.scripts.OnMouseWheel, #edit.points, edit.shown, edit.parentChanges }
	for i = 1, #before do expectEq(after[i], before[i], 'chat window / edit box untouched (' .. i .. ')') end
	expectEq(general.hooks, nil, 'no script hook on a chat window')
	expectEq(edit.hooks, nil, 'none on the edit box')
end)

---------------------------------------------------------------------------
-- Font fallback
---------------------------------------------------------------------------
test('1.5.3 font fallback: a label the title\'s face cannot draw takes the Information Font as a whole - still half the title\'s size; the other labels keep the title\'s font', function()
	Reset()
	local info = Theme:SmallFont()
	loot.name = 'Гильдия' -- (Shojumaru has no Cyrillic)
	FCFDock_UpdateTabs(dock, true)
	expectEq(lootTab.Text.font, info, 'the Information Font for the whole label')
	expectEq(lootTab.Text.fontSize, 11.5, 'still half the title\'s 23')
	expectEq(lootTab.Text.banzaiHeader.fallback, true, 'recorded as a fallback')
	expectEq(generalTab.Text.font, SHOJUMARU, 'General keeps the title\'s font')
	expectEq(lootTab:GetAlpha(), 0.5, 'the same opacity contract')
	-- an ASCII-only face: a label with an umlaut falls back as a whole, "General" beside it does not
	loot.name = 'Größe'
	Compat:Set('displayFace', 'NINJA_NARUTO')
	local titlePath, titleSize = Compat.chatTitle.text:GetFont()
	expect(string.find(titlePath, 'njnaruto.ttf', 1, true), 'the title in Ninja Naruto')
	expectEq(generalTab.Text.font, titlePath, 'General in the title\'s face')
	expectEq(lootTab.Text.font, info, 'the label with an umlaut in the Information Font')
	expectEq(lootTab.Text.fontSize, titleSize * 0.5, 'half the title\'s size')
	expectEq(generalTab.Text.fontSize, titleSize * 0.5, 'the same size for both')
	loot.name = 'Loot / Trade'
	-- a face the title itself is not drawn in (Xangda Shiny has letters only; Banzai's titles carry colour codes and
	-- are drawn in the Information Font with it): the labels are in the font the title really has, whatever it is
	Compat:Set('displayFace', 'XANGDA_SHINY')
	titlePath, titleSize = Compat.chatTitle.text:GetFont()
	expectEq(titlePath, info, 'the title\'s real font with this face')
	expectEq(generalTab.Text.font, titlePath, 'the label in the title\'s real font')
	expectEq(generalTab.Text.fontSize, titleSize * 0.5, 'at half the title\'s real size')
	Compat:Set('displayFace', 'BANZAI_DEFAULT')
	-- a name the client keeps to itself is never read: the Information Font, a fixed room
	local secret = {}
	HK_SECRET_SET[secret] = true
	loot.name = secret
	FCFDock_UpdateTabs(dock, true)
	expectEq(lootTab.Text.font, info, 'a secret name: the Information Font')
	expectEq(State(lootTab).name, nil, 'the name is not kept')
	expectEq(Header.lastError, nil, 'no error: ' .. tostring(Header.lastError))
	loot.name = 'Loot / Trade'
	-- the client refuses the title's font file for a label: the Information Font, the same size
	HK_FONT_FAILS = SHOJUMARU
	FCFDock_UpdateTabs(dock, true)
	expectEq(generalTab.Text.font, info, 'a refused file: the Information Font')
	expectEq(generalTab.Text.fontSize, 11.5, 'the same size')
	HK_FONT_FAILS = nil
end)

---------------------------------------------------------------------------
-- DETAILS: the content region
---------------------------------------------------------------------------
test('1.5.3 Details content bounds: each meter 224.655 x 128 (was 207.5 x 124), 4 from its side stalk, 12 under the top stalk, down to the bottom stalk; the 15-unit centre gutter kept on the frame\'s centre', function()
	Reset()
	local D, old, F = Compat.DETAILS, Compat.DETAILS_152, Compat.FILL
	local frame = Compat.detailsFrame
	local l1, r1, t1, b1 = Header.Gutters(frame, HK_DetailsWindow.baseframe)
	local l2, r2, t2, b2 = Header.Gutters(frame, HK_DetailsWindow2.baseframe)
	expectNear(l1, F.gutter, 'DAMAGE: 4 from the left stalk')
	expectNear(r2, F.gutter, 'HEALING: 4 from the right stalk')
	expectNear(t1, F.detailsTop, 'DAMAGE: 12 under the top stalk')
	expectNear(b1, 0, 'DAMAGE: down to the bottom stalk\'s inner edge')
	expectEq(D.width .. 'x' .. D.height, '224.655x128', 'the meters')
	expect(D.width > old.width and D.height > old.height, 'wider and taller than 1.5.2\'s')
	-- the room between the side stalks: 2 meters + the gutter + 4 each side
	local inside = D.frameWidth - 2 * Compat.BAND.inset
	expectNear(2 * D.width + D.gap + 2 * F.gutter, inside, 'the composition fills the frame\'s width')
	expectNear(D.height + F.detailsTop, D.frameHeight - 2 * Compat.BAND.inset, 'and its height, less the top band')
	expectEq(D.gap, old.gap, 'the centre gutter is the 1.3.6 one')
	-- ten rows where there were nine: Details fits floor(height / (bar 5 + 12 between)) rows at window scale 0.75
	local rows = function(h) return math.floor(h / 0.75 / 17) end
	expectEq(rows(old.height) .. ' -> ' .. rows(D.height), '9 -> 10', 'one more row, the rows themselves unchanged')
	-- the top band: the titles\' lower half and accent line (7.58) end above the windows, as before
	local TT = Compat.DETAILS_TITLE
	local overhang = (Compat.PANEL.outer + Compat.StalkDiameter() / 2) + TT.size * 0.78 / 2 + TT.gap + TT.accent - Compat.BAND.inset
	expect(F.detailsTop > overhang, 'the meters start under the titles\' accent lines (' .. overhang .. ')')
	expectNear(l2 - (r1 + 0), l2 - r1, 'sanity')
	expect(l1 > 0 and r2 > 0 and t1 > 0 and t2 > 0 and b1 >= 0 and b2 >= 0, 'both meters inside the bamboo')
end)

test('1.5.3 DAMAGE / HEALING symmetry: equal width, equal height, the same top and bottom edge, the same padding on the outer sides, the gutter centred on the divider', function()
	Reset()
	local frame = Compat.detailsFrame
	local a, b = HK_DetailsWindow.baseframe.rect, HK_DetailsWindow2.baseframe.rect
	expectNear(a[3], b[3], 'equal width')
	expectNear(a[4], b[4], 'equal height')
	expectNear(a[2], b[2], 'the same bottom edge')
	expectNear(a[2] + a[4], b[2] + b[4], 'the same top edge')
	local l1, r1, t1, b1 = Header.Gutters(frame, HK_DetailsWindow.baseframe)
	local l2, r2, t2, b2 = Header.Gutters(frame, HK_DetailsWindow2.baseframe)
	expectNear(l1, r2, 'the same outer padding left and right')
	expectNear(t1, t2, 'the same top padding')
	expectNear(b1, b2, 'the same bottom padding')
	local centre = frame.rect[1] + frame.rect[3] / 2
	expectNear(centre - (a[1] + a[3]), (b[1]) - centre, 'the gutter the same either side of the frame\'s centre')
	expectNear(b[1] - (a[1] + a[3]), Compat.DETAILS.gap, '15 between the meters')
	-- the layout is one table for both windows: there is no second set of numbers to drift
	expectEq(Compat.DETAILS.widthLeft, nil, 'one width')
	expectEq(Compat.DETAILS.heightRight, nil, 'one height')
end)

---------------------------------------------------------------------------
-- DETAILS: no secondary label
---------------------------------------------------------------------------
test('1.5.3 no Details label: DAMAGE and HEALING stand alone on their stalk - no Current / Overall / Segment text, no BANZAI button beside them, no listener, no hook and no call into Details, whatever the windows show', function()
	Reset()
	HK_DETAILS_CALLS = {}
	local hooks, tickers, frames = #HK_HOOKS, #HK_TICKERS, #HK_Frames()
	local dmg, heal = Compat.detailsTitles[1], Compat.detailsTitles[2]
	local before = { HK_DetailsWindow.display, HK_DetailsWindow.modo, HK_DetailsWindow.rowsRefreshed, HK_DetailsWindow.barSettingsCalls, HK_DetailsWindow.saved, HK_DetailsWindow.restored }
	-- every state a window can be in, announced the way Details announces it
	for _, kind in ipairs({ 0, 2, 1 }) do
		HK_DetailsWindow.sessionType, HK_DetailsWindow2.sessionType = kind, kind
		Details:SendEvent('DETAILS_INSTANCE_CHANGESESSION', nil, HK_DetailsWindow, kind)
		Details:SendEvent('COMBAT_PLAYER_LEAVE')
		Details:SendEvent('DETAILS_DATA_RESET')
		Compat:Refresh()
		Header:Refresh('again')
		for _, f in ipairs(HK_Frames()) do
			if f.kind == 'FontString' and type(f.text) == 'string' then
				local plain = string.lower(HK_Plain(f.text))
				for _, word in ipairs({ 'current', 'overall', 'segment', 'curr...', 'over...' }) do
					expect(plain ~= word, 'no "' .. word .. '" label anywhere (session type ' .. kind .. ')')
				end
			end
		end
	end
	expectEq(#HK_Frames(), frames, 'no frame, button or text made for a label')
	expectEq(#HK_DETAILS_LISTENERS, 0, 'no Details listener')
	expectEq(#HK_DETAILS_CALLS, 0, 'no call into Details')
	expectEq(#HK_HOOKS, hooks, 'no hook')
	expectEq(#HK_TICKERS, tickers, 'no ticker')
	local after = { HK_DetailsWindow.display, HK_DetailsWindow.modo, HK_DetailsWindow.rowsRefreshed, HK_DetailsWindow.barSettingsCalls, HK_DetailsWindow.saved, HK_DetailsWindow.restored }
	for i = 1, 6 do expectEq(after[i], before[i], 'the window untouched (' .. i .. ')') end
	-- the code that made them is gone
	for _, name in ipairs({ 'details', 'RefreshDetails', 'LayoutDetailsWindow', 'SegmentState', 'SegmentText', 'SelectSegment', 'WatchDetails', 'SEGMENT_KEYS', 'DETAILS_EVENTS' }) do
		expectEq(Header[name], nil, 'Header.' .. name)
	end
	-- the titles as they were
	expectEq(HK_Plain(dmg.text.text) .. '/' .. dmg.text.fontSize .. '/' .. dmg:GetAlpha(), 'DAMAGE/23/1', 'DAMAGE unchanged')
	expectEq(HK_Plain(heal.text.text) .. '/' .. heal.text.fontSize .. '/' .. heal:GetAlpha(), 'HEALING/23/1', 'HEALING unchanged')
	expectEq(dmg.shown and heal.shown, true, 'both shown')
	expectEq(Header.lastError, nil, 'no error: ' .. tostring(Header.lastError))
end)

---------------------------------------------------------------------------
-- Materials
---------------------------------------------------------------------------
test('1.5.3 materials: on BANZAI GLASS, SOLID and HARDKORH PARCHMENT the content regions and the labels are the same - bright outlined letters on the bamboo, nothing behind them', function()
	Reset()
	local function luma(c) return 0.2126 * c[1] + 0.7152 * c[2] + 0.0722 * c[3] end
	local frames = #HK_Frames()
	local reference
	for _, material in ipairs({ 'GLASS', 'SOLID', 'PARCHMENT' }) do
		Compat:Set('panelBackground', material)
		Rects()
		FCFDock_UpdateTabs(dock, true)
		local l, r, t, b = Header.Gutters(Compat.chatFrame, general)
		local dl, _, dt, db = Header.Gutters(Compat.detailsFrame, HK_DetailsWindow.baseframe)
		local state = table.concat({ l, r, t, b, dl, dt, db, Compat.chatFrame.bw, Compat.chatFrame.bh, Compat.detailsFrame.bw, Compat.chatFrame.axis.top, generalTab.points[1][4], generalTab.points[1][5], lootTab.points[1][4],
			generalTab.Text.font, generalTab.Text.fontSize, generalTab.Text.fontFlags, generalTab:GetAlpha(), lootTab:GetAlpha() }, '|')
		reference = reference or state
		expectEq(state, reference, material .. ': the content insets, the stalk, the labels\' places, font, size, outline and opacity as on GLASS')
		for _, text in ipairs({ generalTab.Text, lootTab.Text }) do
			expect(luma(text.textColor) > 0.9, material .. ': bright letters')
			expectEq(text.textColor[4], 1, material .. ': the ink itself opaque (the opacity is the tab\'s alpha)')
			expect(string.find(text.fontFlags, 'OUTLINE', 1, true), material .. ': outlined')
			expect(luma(text.shadowColor) < 0.05 and text.shadowColor[4] == 1, material .. ': a black edge under the letters')
			-- the letters against their own black stroke (WCAG contrast): far above 7, whatever is under them
			expect((luma(text.textColor) + 0.05) / (luma(text.shadowColor) + 0.05) > 12, material .. ': letters against their stroke')
		end
	end
	-- nothing behind a label: no plate, strip or fill was made for one
	expectEq(#HK_Frames(), frames, 'no frame or texture made behind the labels')
	expectEq(Header.chat.plates, nil, 'no plates kept')
	expectEq(Header.LayPlate, nil, 'no plate code')
	expectEq(Header.STYLE.plate, nil, 'no plate colour')
	Compat:Set('panelBackground', 'GLASS')
end)

---------------------------------------------------------------------------
-- The read-only report
---------------------------------------------------------------------------
test('1.5.3 /banzai header: the titles\' fonts, the labels\' fonts, sizes and opacities and the content gutters, read only', function()
	Reset()
	local points, alpha = #generalTab.points, lootTab:GetAlpha()
	local text = table.concat(Header:Report(), '\n')
	for _, needle in ipairs({ 'CHAT title: Shojumaru-Regular.ttf, size 23, OUTLINE; its labels: size 11.5 (50 %), outlined, nothing behind them', 'top stalk: its axis 7.5 under the frame\'s top edge', 'tab General: selected, opacity 1.00, font Shojumaru-Regular.ttf size 11.5 (the CHAT title\'s font)',
		'tab Loot / Trade: inactive, opacity 0.50', 'chat text inside the bamboo: left 4.2, right 4.2, top 9.0, bottom 4.0', 'DAMAGE title: Shojumaru-Regular.ttf, size 23, OUTLINE; no secondary label', 'HEALING title: Shojumaru-Regular.ttf, size 23, OUTLINE; no secondary label',
		'meter inside the bamboo: left 4.0' }) do
		expect(string.find(text, needle, 1, true), 'the report says: ' .. needle .. '\n' .. text)
	end
	expectEq(string.find(text, 'label ', 1, true), nil, 'no Details label reported')
	expectEq(#generalTab.points .. '/' .. lootTab:GetAlpha(), points .. '/' .. alpha, 'asking changes nothing')
end)

---------------------------------------------------------------------------
-- After the independent review
---------------------------------------------------------------------------
test('1.5.3 review: the Details frame keeps its place on screen whichever width the right window has - still 207.5 (the first seconds after the update, another Details profile, a login in combat) or the filled 224.655', function()
	Reset()
	local frame, base = Compat.detailsFrame, HK_DetailsWindow2.baseframe
	local D, old = Compat.DETAILS, Compat.DETAILS_152
	local function centre() return base.rect[1] + base.rect[3] + frame.points[1][4] end -- the frame's centre x on screen
	Compat:PlaceDetails(true)
	expectNear(frame.points[1][4], D.centerX, 'the filled window: 232.155 from the frame\'s centre')
	local filled = centre()
	expectNear(filled, SCREEN - 262.15, 'the frame\'s centre 262.15 from the screen\'s right edge')
	-- the right window as 1.5.2 left it
	base.rect = { SCREEN + old.right - old.width, old.bottom, old.width, old.height }
	Compat:PlaceDetails(true)
	expectNear(frame.points[1][4], old.centerX, 'a 207.5 window: 215 from the frame\'s centre, as in 1.5.2')
	expectNear(centre(), filled, 'the frame has not moved on screen')
	expectNear(frame.points[1][5], D.centerY, 'nor up or down')
	-- and placed again by the update
	Rects()
	Compat:PlaceDetails(true)
	expectNear(centre(), filled, 'the same place once the window is filled')
	-- a window without a layout yet: the filled composition is assumed
	base.rect = nil
	Compat:PlaceDetails(true)
	expectNear(frame.points[1][4], D.centerX, 'no layout: the numbers in use')
	Rects()
end)

test('1.5.3 review: labels in a span with no room at all stay at the span, with no width - never a negative size', function()
	Reset()
	local placed = Header.Place({ 40, 50, 60 }, 100, 100, 'LEFT', Header.STYLE)
	for i = 1, 3 do
		expectNear(placed[i].x, 100, 'no room: at the span')
		expectNear(placed[i].width, 0, 'no room: no width')
	end
	expectEq(Header.lastError, nil, 'no error: ' .. tostring(Header.lastError))
end)

test('1.5.3 review: the game asking its dock to update again and again (nothing moved, the same window selected, the same tabs) lays nothing out again; a real change does, once', function()
	Reset()
	local update = FCFDock_UpdateTabs
	-- the dock\'s own early return: asked, nothing dirty, nothing done (the post-hooks still run, as in the game)
	local real = HK_DOCK_REAL
	local n = Header.chat.layouts
	HK_DOCK_IDLE = true
	for _ = 1, 500 do FCFDock_UpdateTabs(dock) end
	HK_DOCK_IDLE = nil
	expectEq(Header.chat.layouts, n, '500 idle updates: not one layout')
	expectEq(Header:ChatIntact(), true, 'the tabs are where BANZAI put them')
	-- the game really moved its tabs
	FCFDock_UpdateTabs(dock, true)
	expect(Header.chat.layouts > n, 'a real update is followed')
	expectEq(lootTab.points[1][2], Compat.chatFrame, 'and the tabs are back on the stalk')
	expectEq(#lootTab.points .. '/' .. #generalTab.points, '1/1', 'on one anchor each (the game\'s own is gone)')
	-- a selection the dock holds without having moved a tab
	n = Header.chat.layouts
	dock.selected = loot
	HK_DOCK_IDLE = true
	FCFDock_UpdateTabs(dock)
	HK_DOCK_IDLE = nil
	expect(Header.chat.layouts > n, 'another window selected: laid out again')
	expectEq(lootTab:GetAlpha() .. '/' .. generalTab:GetAlpha(), '1.0/0.5', 'the opacities follow')
	dock.selected = general
	FCFDock_UpdateTabs(dock, true)
	-- an alpha the game cannot set does not leave the guard closed
	local set = lootTab.SetAlpha
	lootTab.SetAlpha = function() error('refused') end
	Header:LayoutChat('a refused alpha')
	lootTab.SetAlpha = set
	expect(Header.lastError ~= nil, 'the refusal is kept for /banzai header')
	Header.lastError = nil
	lootTab:SetAlpha(0.2)
	expectEq(lootTab:GetAlpha(), 0.5, 'still held at 0.5 afterwards')
end)
