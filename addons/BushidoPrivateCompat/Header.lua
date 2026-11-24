--[[
	BANZAI - Header.lua  (Banzai Art)
	1.5.3: the chat tabs on the CHAT frame's bamboo header (Retail / Midnight).

	The CHAT title sits on the top stalk of its frame (Compat.lua). This file puts
	the game's own chat tabs of the windows docked with General ("General",
	"Loot / Trade", any tab the player made) on that stalk, left and right of the
	title. They are the real tab buttons: BANZAI gives them a place, a font and an
	opacity - the click, the right-click menu, the drag, the alert and the text
	stay the game's and ElvUI's.

	The visual contract of a tab label (Header.CONTRACT, Header.STYLE):
	  font      the font the CHAT title is really set in (title.text:GetFont) - a
	            label BANZAI's display face cannot draw takes the Information Font as
	            a whole (Theme:DisplayFontFor: never a mix of fonts in one label)
	  size      half the title's font size (ratio 0.5), fallback or not
	  letters   bright, with the title's own black outline and a black edge under
	            it: they stand on the bamboo itself, nothing is drawn behind them
	            (no plate, no strip, no fill)
	  opacity   the selected label 1.0, every other label 0.5; an inactive label
	            under the pointer is brighter (hover) and goes back to exactly 0.5
	            when the pointer leaves
	The title itself is not changed by anything here.

	DAMAGE / HEALING have no secondary label: nothing here reads, hooks, listens
	to or calls Details.

	Nothing runs per frame and nothing is polled: the labels follow the game's own
	tab updates (post-hooks on FCFDock_UpdateTabs / FCFTab_UpdateColors and on
	ElvUI's chat styling) and are laid out again on Compat:Refresh.

	Midnight first: on WoW Forever nothing here runs yet (Header.Available) - the
	Forever port switches it on with the Forever chat adapter.
]]
local _, ns = ...
local Theme = ns.Theme
local Compat = ns.Compat

local Header = { chat = { state = {} } }
ns.Header = Header
Compat.Header = Header

-- the shared secondary-label contract
Header.CONTRACT = { ratio = 0.5, selected = 1.0, inactive = 0.5, hover = 0.8 }
-- gap between two labels (closing to minGap before a label is shortened), clear of the title's backing, clear of a
-- corner's rope tie, the click padding left and right of a label's letters; the letters (a bright off-white) and
-- the black edge under them (colour and opacity, offset in units) - with the title's own outline it carries the
-- letters on the bamboo whatever the border style and the panel material: nothing is drawn behind a label
Header.STYLE = { gap = 10, minGap = 3, clear = 6, corner = 4, pad = 3,
	ink = { 0.96, 0.95, 0.92 }, edge = { 0, 0, 0, 1 }, edgeOffset = 1 }

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function PlainNumber(value)
	return type(value) == 'number' and not IsSecret(value)
end

-- a call into the game's, ElvUI's or Details' own code: an error there is kept (Header.lastError, /banzai header)
local function Call(fn, ...)
	local ok, a, b, c = pcall(fn, ...)
	if not ok then
		Header.lastError = tostring(a)
		return false
	end
	return true, a, b, c
end

-- the one access gate for objects BANZAI did not make (PvPFrames.lua, 1.3.4): not forbidden, no secret aspect
local function Usable(frame)
	local gate = ns.PvPFrames and ns.PvPFrames.Accessible
	if gate then return gate(frame) end
	return type(frame) == 'table' and not (frame.IsForbidden and frame:IsForbidden())
end

-- Midnight first (1.5.3): the header labels and the filled content are Retail's until the Forever port
function Header.Available()
	return not (ns.Flavor and ns.Flavor.IsForever())
end

---------------------------------------------------------------------------
-- The contract: font, size, opacity
---------------------------------------------------------------------------
-- the font a title is really set in: file, size, flags (the display font at the display size when it has none yet)
function Header:TitleFont(title)
	local text = title and title.text
	if text and text.GetFont then
		local path, size, flags = text:GetFont()
		if type(path) == 'string' and PlainNumber(size) and size > 0 then return path, size, flags or '' end
	end
	return Theme:DisplayFont(), Theme:DisplaySize(Compat.DETAILS_TITLE.size), 'OUTLINE'
end

-- The font of a secondary label: the title's own font file and flags at half its size. A label the title's face
-- cannot draw (Theme:DisplayFontFor answers with another file for it than for the title's own letters) takes that
-- file - the Information Font - for the whole label, still at half the title's size.
function Header:LabelFont(title, label)
	local path, size, flags = self:TitleFont(title)
	local titleText = title and title.style and title.style.text or nil
	local want, titleWant = Theme:DisplayFontFor(label), Theme:DisplayFontFor(titleText)
	local fallback = want ~= titleWant
	if fallback then path = want end
	return path, size * self.CONTRACT.ratio, flags, fallback
end

-- sets a label's font string; what was set is kept on it (the tests and /banzai header read it back)
function Header:ApplyFont(fs, title, label)
	local path, size, flags, fallback = self:LabelFont(title, label)
	local ok = fs:SetFont(path, size, flags)
	if not ok then
		-- the client refused that file: the Information Font, the same size
		path, fallback = Theme:SmallFont(), true
		fs:SetFont(path, size, flags)
	end
	-- the letters stand on the bamboo itself: the title's outline (its flags), and a black edge under it
	local S = self.STYLE
	if fs.SetShadowColor then fs:SetShadowColor(S.edge[1], S.edge[2], S.edge[3], S.edge[4]) end
	if fs.SetShadowOffset then fs:SetShadowOffset(S.edgeOffset, -S.edgeOffset) end
	local ink = S.ink
	fs:SetTextColor(ink[1], ink[2], ink[3], 1)
	fs.banzaiHeader = { font = path, size = size, flags = flags, fallback = fallback and true or false }
	return path, size, flags, fallback
end

-- the opacity of a label: selected 1.0; inactive 0.5, brighter only while the pointer is on it
function Header.Alpha(selected, hover)
	local C = Header.CONTRACT
	if selected then return C.selected end
	if hover then return C.hover end
	return C.inactive
end

---------------------------------------------------------------------------
-- The layout: labels in the free parts of a top stalk
---------------------------------------------------------------------------
-- The widths of the labels of one span, fitted into `room`: as they are while they fit; else the gap between them
-- closes (down to minGap), and only then the widest labels give way first - every label is cut to one common
-- width, the shorter ones staying whole. Returns the widths, the gap, and whether a label was shortened. The
-- labels and their gaps never take more than `room`: nothing can run past the span.
function Header.Fit(widths, room, style)
	local S = style or Header.STYLE
	local n = #widths
	local out = {}
	if n == 0 then return out, S.gap, false end
	room = math.max(0, room)
	local total = 0
	for i = 1, n do total = total + widths[i] end
	if total + S.gap * (n - 1) <= room then
		for i = 1, n do out[i] = widths[i] end
		return out, S.gap, false
	end
	if n > 1 and total + S.minGap * (n - 1) <= room then
		for i = 1, n do out[i] = widths[i] end
		return out, (room - total) / (n - 1), false
	end
	local gap = (n > 1) and S.minGap or 0
	if room - gap * (n - 1) < n then gap = 0 end -- (more labels than units: no gap is kept)
	local avail = room - gap * (n - 1)
	local sorted = {}
	for i = 1, n do sorted[i] = widths[i] end
	table.sort(sorted)
	local left, level = avail, 0
	for i = 1, n do
		local share = left / (n - i + 1)
		if sorted[i] <= share then
			left = left - sorted[i]
		else
			level = share
			break
		end
	end
	for i = 1, n do out[i] = math.min(widths[i], level) end
	return out, gap, true
end

-- Places the labels of one span from `from` to `to` (units from the frame's left edge): align 'LEFT' from the
-- span's start, 'RIGHT' against its end. Returns { { x, width, natural, truncated } } in the order given.
function Header.Place(widths, from, to, align, style)
	local fitted, gap = Header.Fit(widths, to - from, style)
	local n = #fitted
	local used = 0
	for i = 1, n do used = used + fitted[i] end
	used = used + gap * math.max(0, n - 1)
	local x = (align == 'RIGHT') and (to - used) or from
	local out = {}
	for i = 1, n do
		out[i] = { x = x, width = fitted[i], natural = widths[i], truncated = fitted[i] < widths[i] - 0.01 }
		x = x + fitted[i] + gap
	end
	return out
end

-- the two free parts of a top stalk beside a centred title: from the corner's rope tie to the title, and from
-- the title to the other corner's tie (units from the frame's left edge); and the stalk's axis, below the frame's
-- top edge - the frame's own (the CHAT frame's top stalk sits a little lower: Compat.CHAT_TOP)
function Header:Spans(chassis, title)
	local P, S = Compat.PANEL, self.STYLE
	local d = Compat.StalkDiameter()
	local edge = P.outer + d / 2 + P.tie * d / 2 + S.corner
	local x0, x1 = title and title.x0, title and title.x1
	if not (PlainNumber(x0) and PlainNumber(x1)) then x0, x1 = chassis.bw / 2, chassis.bw / 2 end
	local line = chassis.axis and chassis.axis.top
	if not PlainNumber(line) then line = P.outer + d / 2 end
	return { from = edge, to = x0 - S.clear }, { from = x1 + S.clear, to = chassis.bw - edge }, line
end

-- the whole label in a tooltip (a shortened label only)
local function ShowTip(owner, text)
	local tip = _G.GameTooltip
	if not (tip and tip.SetOwner and type(text) == 'string' and not IsSecret(text) and text ~= '') then return false end
	tip:SetOwner(owner, 'ANCHOR_TOP')
	tip:SetText(text, 1, 1, 1)
	tip:Show()
	return true
end

local function HideTip(owner)
	local tip = _G.GameTooltip
	if tip and tip.Hide and (not tip.IsOwned or tip:IsOwned(owner)) then tip:Hide() end
end

-- the full width of a font string's text (never a secret, never less than one unit)
local function TextWidth(fs)
	local width
	if fs.GetUnboundedStringWidth then width = fs:GetUnboundedStringWidth() else width = fs:GetStringWidth() end
	if not PlainNumber(width) or width < 1 then return nil end
	return width
end

---------------------------------------------------------------------------
-- CHAT: the game's own tabs on the CHAT frame's top stalk
---------------------------------------------------------------------------
local function ChatModule()
	local E = Engine()
	if not (E and E.GetModule) then return nil end
	if type(E.private) == 'table' and type(E.private.chat) == 'table' and E.private.chat.enable == false then return nil end
	local ok, CH = pcall(E.GetModule, E, 'Chat', true)
	if not ok or type(CH) ~= 'table' then return nil end
	return CH, E
end

local function Dock()
	local dock = _G.GeneralDockManager
	if type(dock) ~= 'table' or not Usable(dock.primary) or type(dock.DOCKED_CHAT_FRAMES) ~= 'table' then return nil end
	return dock
end

local function SelectedWindow(dock)
	local get = _G.FCFDock_GetSelectedWindow
	if type(get) == 'function' then
		local ok, chat = pcall(get, dock)
		if ok then return chat end
	end
	return dock.selected
end

local function TabOf(chat)
	local name = chat.GetName and chat:GetName()
	if type(name) ~= 'string' or IsSecret(name) then return nil end
	local tab = _G[name .. 'Tab']
	if not Usable(tab) then return nil end
	return tab, tab.Text or _G[name .. 'TabText']
end

-- BANZAI presents the chat tabs only here: this client, the Banzai profile, the Banzai chat frame on and shown,
-- ElvUI presenting the chat with the dock's window in its left panel (the window inside the BANZAI CHAT frame)
function Header:ChatOwned()
	if not Header.Available() then return false end
	local frame = Compat.chatFrame
	if not (frame and Compat.Active() and Theme:DB().chatFrame and frame:IsShown()) then return false end
	local CH = ChatModule()
	local dock = Dock()
	if not (CH and dock and CH.LeftChatWindow == dock.primary) then return false end
	return true, dock, CH
end

-- the alpha a tab has now, by the contract
local function TabAlpha(st)
	return Header.Alpha(st.selected, st.hover)
end

local pinning = false
local function SetTabAlpha(tab, st)
	pinning = true
	local ok, err = pcall(tab.SetAlpha, tab, TabAlpha(st), true) -- (true: ElvUI's own hook on the tab's SetAlpha leaves this call alone)
	pinning = false
	if not ok then Header.lastError = tostring(err) end
	st.alpha = TabAlpha(st)
end

-- Whoever sets a tab's alpha (the game fades its tabs; ElvUI holds them at 1 / 0.6): while BANZAI presents the
-- tab, the contract's alpha is what it has.
local function PinAlpha(tab)
	if pinning then return end
	local st = Header.chat.state[tab]
	if not (st and st.owned) then return end
	SetTabAlpha(tab, st)
end

-- once per tab: the alpha hook and the pointer (script post-hooks: the tab's own scripts run first, untouched)
local function Adopt(tab, st)
	if st.hooked then return end
	st.hooked = true
	hooksecurefunc(tab, 'SetAlpha', PinAlpha)
	if tab.HookScript then
		tab:HookScript('OnEnter', function(self)
			local s = Header.chat.state[self]
			if not (s and s.owned) then return end
			s.hover = true
			SetTabAlpha(self, s)
			if s.truncated then s.tip = ShowTip(self, s.name) end
		end)
		tab:HookScript('OnLeave', function(self)
			local s = Header.chat.state[self]
			if not (s and s.owned) then return end
			s.hover = false
			SetTabAlpha(self, s)
			if s.text and s.text.Show then s.text:Show() end -- (ElvUI hides a faded tab's text when the pointer leaves)
			if s.tip then HideTip(self) s.tip = nil end
		end)
	end
end

-- the game's and ElvUI's functions whose work the labels follow: hooked once, each a plain call to the layout
function Header:HookChat(CH)
	if self.chat.hooked then return true end
	if type(_G.FCFDock_UpdateTabs) ~= 'function' then return false end
	self.chat.hooked = true
	local function relayout() Header:LayoutChat('tabs') end
	-- the game may ask its dock to update often and change nothing: only a dock whose tabs it really moved, or
	-- whose selection or number of tabs changed, is laid out again
	hooksecurefunc('FCFDock_UpdateTabs', function() if not Header:ChatIntact() then relayout() end end)
	if type(_G.FCFTab_UpdateColors) == 'function' then hooksecurefunc('FCFTab_UpdateColors', relayout) end
	if type(CH) == 'table' then
		-- ElvUI sets its own tab font again when it styles a chat window, and hides a faded tab's text
		if type(CH.StyleChat) == 'function' then hooksecurefunc(CH, 'StyleChat', relayout) end
		if type(CH.PositionChat) == 'function' then hooksecurefunc(CH, 'PositionChat', relayout) end
		if type(CH.TabOnLeave) == 'function' then
			hooksecurefunc(CH, 'TabOnLeave', function(_, tab)
				local s = Header.chat.state[tab]
				if s and s.owned and s.text and s.text.Show then s.text:Show() end
			end)
		end
	end
	return true
end

-- true while every docked window's tab is still where BANZAI put it, with the same window selected
function Header:ChatIntact()
	local C = self.chat
	if not C.active then return false end
	local owned, dock = self:ChatOwned()
	if not owned then return false end
	local docked = dock.DOCKED_CHAT_FRAMES
	if #docked ~= C.count or SelectedWindow(dock) ~= C.selected then return false end
	local chassis = Compat.chatFrame
	for _, chat in ipairs(docked) do
		local tab = Usable(chat) and TabOf(chat)
		local st = tab and C.state[tab]
		if not (st and st.owned and tab.GetPoint and tab.GetNumPoints) then return false end
		-- the game clears a tab's anchors, anchors it to the dock and sizes it to its text: one anchor on the BANZAI
		-- frame and the width BANZAI gave it is a tab the game has not touched since
		local _, anchor = tab:GetPoint(1)
		local width = tab:GetWidth()
		if anchor ~= chassis or tab:GetNumPoints() ~= 1 then return false end
		if not PlainNumber(width) or math.abs(width - math.max(1, st.width or 0)) > 0.01 then return false end
	end
	return true
end

-- the docked windows in the dock's order: { chat, tab, text, name, selected }
function Header:ChatTabs(dock)
	local list = {}
	local selected = SelectedWindow(dock)
	for _, chat in ipairs(dock.DOCKED_CHAT_FRAMES) do
		if Usable(chat) then
			local tab, text = TabOf(chat)
			if tab and text and text.SetFont then
				local name = chat.name
				if type(name) ~= 'string' or IsSecret(name) then name = nil end
				list[#list + 1] = { chat = chat, tab = tab, text = text, name = name, selected = (chat == selected) }
			end
		end
	end
	return list
end

-- Hands the tabs back: the game lays its tabs out again and ElvUI gives them its own font, colour and alpha.
function Header:ReleaseChat(reason)
	local C = self.chat
	if not C.active then return 0 end
	C.active = false
	local n = 0
	local CH = ChatModule()
	for tab, st in pairs(C.state) do
		if st.owned then
			st.owned, st.hover, st.truncated = false, false, false
			if st.text then
				if st.text.SetWidth then st.text:SetWidth(0) end
				if CH and CH.db and st.text.FontTemplate then Call(st.text.FontTemplate, st.text, CH.db.tabFont, CH.db.tabFontSize, CH.db.tabFontOutline) end
				st.text.banzaiHeader = nil
			end
			tab:SetAlpha(1) -- (ElvUI's own hook sets its 1 / 0.6 from here)
			n = n + 1
		end
	end
	local dock = Dock()
	if dock and type(_G.FCFDock_UpdateTabs) == 'function' then
		self.laying = true -- (the post-hook must not answer this call)
		Call(_G.FCFDock_UpdateTabs, dock, true)
		self.laying = false
	end
	C.reason, C.count = reason, 0
	return n
end

-- Puts the docked windows' tabs on the CHAT frame's top stalk: the first half left of the CHAT title, the rest
-- right of it, each label in the title's font at half its size, the selected one opaque. Idempotent.
function Header:LayoutChat(reason)
	if self.laying then return false, 'busy' end
	local owned, dock, CH = self:ChatOwned()
	if not owned then
		self:ReleaseChat(reason or 'not presented')
		return false, 'not presented here'
	end
	if not self:HookChat(CH) then return false, 'the chat dock cannot be followed' end
	self.laying = true
	local ok, err = pcall(self.LayChat, self, dock, reason)
	self.laying = false
	if not ok then
		self.lastError = tostring(err)
		return false, self.lastError
	end
	return true
end

function Header:LayChat(dock, reason)
	local C, S = self.chat, self.STYLE
	local chassis, title = Compat.chatFrame, Compat.chatTitle
	local list = self:ChatTabs(dock)
	local left, right, line = self:Spans(chassis, title)
	local _, size = self:LabelFont(title, nil)
	local seen = {}
	-- 1. every tab in the title's font; its letters measured
	for _, item in ipairs(list) do
		local st = C.state[item.tab] or {}
		C.state[item.tab] = st
		st.owned, st.chat, st.text, st.name, st.selected = true, item.chat, item.text, item.name, item.selected
		seen[item.tab] = true
		Adopt(item.tab, st)
		if item.text.SetWidth then item.text:SetWidth(0) end
		if item.text.SetWordWrap then item.text:SetWordWrap(false) end
		-- (a name the client keeps to itself cannot be checked against the title's face: `false` - the Information Font)
		local _, _, _, fallback = self:ApplyFont(item.text, title, item.name or false)
		st.fallback = fallback
		if item.text.Show then item.text:Show() end
		item.width = TextWidth(item.text) or (size * 4) -- (a text the client keeps to itself: a fixed room, the client shortens it)
		-- a whisper tab's little icon sits left of its letters (isTemporary: a plain flag of the game's own)
		item.lead = (item.tab.conversationIcon and item.chat.isTemporary == true) and size or 0
	end
	-- a tab that left the dock is the game's again
	for tab, st in pairs(C.state) do
		if st.owned and not seen[tab] then
			st.owned, st.hover, st.truncated = false, false, false
			if st.text and st.text.SetWidth then st.text:SetWidth(0) end
			if st.text then st.text.banzaiHeader = nil end
			tab:SetAlpha(1)
		end
	end
	-- 2. the first half left of the title, the rest right of it
	local half = math.ceil(#list / 2)
	local groups = { { span = left, align = 'LEFT', items = {} }, { span = right, align = 'RIGHT', items = {} } }
	for i, item in ipairs(list) do
		local group = groups[i <= half and 1 or 2]
		group.items[#group.items + 1] = item
	end
	for _, group in ipairs(groups) do
		local widths = {}
		for i, item in ipairs(group.items) do widths[i] = item.width + item.lead + 2 * S.pad end
		local placed = Header.Place(widths, group.span.from, group.span.to, group.align, S)
		for i, item in ipairs(group.items) do
			local slot, st = placed[i], C.state[item.tab]
			local tab, text = item.tab, item.text
			st.x, st.width, st.truncated = slot.x, slot.width, slot.truncated
			-- a tab of a window that is not the dock's first one lives in the dock's scrolling strip, which would cut
			-- it off outside its own rectangle: on the stalk it is a child of the dock, like the first tab
			if item.chat ~= dock.primary and tab.GetParent and tab.SetParent and tab:GetParent() ~= dock then tab:SetParent(dock) end
			tab:ClearAllPoints()
			tab:SetPoint('LEFT', chassis, 'TOPLEFT', slot.x, -line)
			tab:SetWidth(math.max(1, slot.width))
			if slot.truncated and text.SetWidth then text:SetWidth(math.max(1, slot.width - item.lead - 2 * S.pad)) end
			if tab.Show then tab:Show() end
			SetTabAlpha(tab, st)
		end
	end
	-- the game's "more tabs" arrow belongs to its scrolling strip: every tab is on the stalk, so it has nothing to open
	local overflow = dock.overflowButton
	if overflow and overflow.Hide and Usable(overflow) then overflow:Hide() end
	C.active, C.count, C.reason, C.size, C.line = true, #dock.DOCKED_CHAT_FRAMES, reason, size, line
	C.selected = SelectedWindow(dock)
	C.layouts = (C.layouts or 0) + 1
	return #list
end

---------------------------------------------------------------------------
-- Refresh, and the read-only report (/banzai header)
---------------------------------------------------------------------------
function Header:Refresh(reason)
	self:LayoutChat(reason or 'refresh')
end

local function FileName(path)
	if type(path) ~= 'string' then return tostring(path) end
	return (string.match(path, '([^\\/]+)$')) or path
end

-- the gutters of a content region inside a frame's bamboo (units): left, right, top, bottom; nil without a layout
function Header.Gutters(chassis, region)
	local cl, cb, cw, ch = Compat.Rect(chassis)
	local rl, rb, rw, rh = Compat.Rect(region)
	if not (cl and rl) then return nil end
	local inset = Compat.BAND.inset
	return rl - (cl + inset), (cl + cw - inset) - (rl + rw), (cb + ch - inset) - (rb + rh), rb - (cb + inset)
end

local function GutterText(chassis, region)
	local l, r, t, b = Header.Gutters(chassis, region)
	if not l then return 'not laid out' end
	return string.format('left %.1f, right %.1f, top %.1f, bottom %.1f', l, r, t, b)
end

-- Read only: the titles' fonts, the chat labels' fonts, sizes and opacities, the content gutters. Nothing is changed.
function Header:Report()
	local C = self.CONTRACT
	local lines = {}
	if not Header.Available() then
		lines[1] = 'header labels: not used on this client yet'
		return lines
	end
	local function titleLine(name, title, half)
		local path, size, flags = self:TitleFont(title)
		if not half then return string.format('%s title: %s, size %s, %s; no secondary label', name, FileName(path), tostring(size), tostring(flags)), path end
		return string.format('%s title: %s, size %s, %s; its labels: size %s (%d %%), outlined, nothing behind them', name, FileName(path), tostring(size), tostring(flags), tostring(half), C.ratio * 100), path
	end
	local _, chatHalf = self:LabelFont(Compat.chatTitle, nil)
	local chatLine, chatFont = titleLine('CHAT', Compat.chatTitle, chatHalf)
	lines[#lines + 1] = chatLine
	local chassis = Compat.chatFrame
	if chassis and chassis.axis then lines[#lines + 1] = string.format('  top stalk: its axis %.1f under the frame\'s top edge', chassis.axis.top) end
	local owned, dock = self:ChatOwned()
	if owned then
		for _, item in ipairs(self:ChatTabs(dock)) do
			local st = self.chat.state[item.tab] or {}
			local set = item.text.banzaiHeader or {}
			local alpha = item.tab.GetAlpha and item.tab:GetAlpha()
			lines[#lines + 1] = string.format('  tab %s: %s, opacity %s, font %s size %s%s%s', tostring(item.name or '(kept by the client)'), item.selected and 'selected' or 'inactive',
				PlainNumber(alpha) and string.format('%.2f', alpha) or '?', FileName(set.font), tostring(set.size),
				(set.font == chatFont) and ' (the CHAT title\'s font)' or ' (Information Font: the title\'s face cannot draw this label)', st.truncated and ', shortened (tooltip has the whole name)' or '')
		end
		lines[#lines + 1] = '  chat text inside the bamboo: ' .. GutterText(Compat.chatFrame, dock.primary)
	else
		lines[#lines + 1] = '  chat tabs: not presented by BANZAI here (another profile, the chat frame off, or ElvUI is not presenting the chat)'
	end
	for index, name in ipairs({ 'window 1', 'window 2' }) do
		local title = Compat.detailsTitles and Compat.detailsTitles[index]
		if title and title:IsShown() then
			lines[#lines + 1] = (titleLine(title.style and title.style.text or name, title))
			local details = _G.Details
			local window = details and details.GetInstance and details:GetInstance(index)
			if type(window) == 'table' and window.baseframe then lines[#lines + 1] = '  meter inside the bamboo: ' .. GutterText(Compat.detailsFrame, window.baseframe) end
		end
	end
	if self.lastError then lines[#lines + 1] = 'last error: ' .. tostring(self.lastError) end
	return lines
end
