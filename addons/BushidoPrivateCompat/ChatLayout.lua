--[[
	BANZAI - ChatLayout.lua  (Banzai Art)
	1.5.0-dev3 (private Forever proof): the chat windows inside the BANZAI CHAT
	frame on WoW Forever. Retail is not touched: nothing here runs there.

	What was wrong (read from the live client's saved state after the dev2 test,
	chat-cache.txt and ElvUI.lua of 11 Nov 2026 19:42):
	  ElvUI's installer on WoW Forever makes a second, UNDOCKED chat window
	  ("Loot / Trade", chat window 4) for its right chat panel. The Banzai
	  profile has no right chat panel on screen (the DAMAGE / HEALING meters
	  are there) and carries no panel snapping IDs, so ElvUI found its panel
	  windows by position: window 4 was saved at exactly the left panel's
	  place and size (panel + 5, 420 x 108), on top of General. Two windows
	  then drew in one place: both tab labels over each other at the top
	  left, both texts over each other at the bottom, two sets of buttons,
	  and the undocked tab never fading like the panel's own tabs. On
	  Darren's Retail characters the same window is a docked tab of the
	  General window, which is the approved look.

	What this does, on WoW Forever only, while the Banzai profile is active
	and the Banzai chat frame is on (BANZAI > APPEARANCE > WINDOW SKINS > Chat,
	the same setting as LAYOUT > CHAT):
	  1. a shown, undocked, ordinary chat window that lies over the BANZAI
	     CHAT frame or the DAMAGE / HEALING frame becomes a tab of the General
	     window (the game's own FCF_DockFrame - what dragging the tab onto the
	     dock does). Its messages, channels, name, font size and colours are
	     its own and are not changed. A window floating anywhere else, a
	     whisper window and the combat log are left alone.
	  2. the General window is the one ElvUI snaps into its left chat panel
	     (the profile's chat.panelSnapLeftID - a key of the Banzai profile),
	     and ElvUI positions its own chat windows again (CH:PositionChats).
	The BANZAI CHAT frame itself does not move or change: Compat.CHAT.

	Ownership: BANZAI owns the frame around the chat and which window sits in
	it. ElvUI and the game own every chat window, tab, edit box, link, menu,
	scroll and channel; none of them is hooked, re-anchored or resized here.

	Restore: where each window was before it was docked is kept per character
	(BanzaiCompatDB, never synced). Chat:Release() - Restore Pre-Banzai, or
	the chat frame switched off - undocks exactly those windows and puts
	them back there. Nothing runs per frame; in combat the work waits for
	PLAYER_REGEN_ENABLED.
]]
local _, ns = ...
local Theme = ns.Theme
local Compat = ns.Compat

local Chat = { pending = false }
ns.ChatLayout = Chat
Compat.ChatLayout = Chat

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

-- A call into the game's or ElvUI's own chat code. An error there is kept (Chat.lastError, shown by
-- /banzai forever) and the step counts as not done - it is never hidden.
local function Call(fn, ...)
	local ok, err = pcall(fn, ...)
	if not ok then Chat.lastError = tostring(err) end
	return ok
end

-- ElvUI's chat module while ElvUI presents the chat (nil: Banzai has nothing to arrange)
local function ChatModule()
	local E = Engine()
	if not (E and E.GetModule) then return nil end
	if type(E.private) == 'table' and type(E.private.chat) == 'table' and E.private.chat.enable == false then return nil end
	local ok, CH = pcall(E.GetModule, E, 'Chat', true)
	if not ok or type(CH) ~= 'table' then return nil end
	return CH, E
end

-- BANZAI arranges the chat only here: WoW Forever, the Banzai profile, the Banzai chat frame on
function Chat.Owned()
	return (ns.Flavor and ns.Flavor.IsForever() and Compat.Active() and Theme:DB().chatFrame and true) or false
end

-- the one access gate for objects BANZAI did not make (PvPFrames.lua, 1.3.4): not forbidden, no secret aspect
local function Usable(frame)
	local gate = ns.PvPFrames and ns.PvPFrames.Accessible
	if gate then return gate(frame) end
	return type(frame) == 'table' and not (frame.IsForbidden and frame:IsForbidden())
end

-- two regions share some area (both in UIParent units; false when either has no layout)
function Chat.Overlaps(a, b)
	local al, ab, aw, ah = Compat.Rect(a)
	local bl, bb, bw, bh = Compat.Rect(b)
	if not (al and bl) then return false end
	return al < bl + bw and bl < al + aw and ab < bb + bh and bb < ab + ah
end

local function WindowName(chat)
	local name = chat and chat.name
	if type(name) ~= 'string' or IsSecret(name) then return nil end
	return name
end

-- The chat dock and the windows to bring into it: { { chat, frame = 'ChatFrame4', id, name } }, the dock's
-- primary window. nil and why when the game's chat dock is not there.
function Chat:Candidates()
	local dock = _G.GeneralDockManager
	local primary = type(dock) == 'table' and dock.primary or nil
	local names = _G.CHAT_FRAMES
	if not (Usable(primary) and type(names) == 'table') then return nil, 'the chat dock is not there' end
	local zones = {}
	for _, holder in ipairs({ Compat.chatFrame, Compat.detailsFrame }) do
		if holder and holder:IsShown() then zones[#zones + 1] = holder end
	end
	local list = {}
	for index, frameName in ipairs(names) do
		local chat = _G[frameName]
		if Usable(chat) and chat ~= primary and not chat.isDocked and not chat.isTemporary and chat:IsShown()
			and not (_G.IsCombatLog and _G.IsCombatLog(chat)) then
			for _, zone in ipairs(zones) do
				if Chat.Overlaps(chat, zone) then
					local id = chat.GetID and chat:GetID()
					if type(id) ~= 'number' or IsSecret(id) then id = index end
					list[#list + 1] = { chat = chat, frame = frameName, id = id, name = WindowName(chat) }
					break
				end
			end
		end
	end
	return list, primary, dock
end

-- where a window is now (UIParent's bottom-left, its own size), kept for Chat:Release
local function Placement(item)
	local chat = item.chat
	local left, bottom = Compat.Rect(chat)
	local width, height = chat.GetWidth and chat:GetWidth(), chat.GetHeight and chat:GetHeight()
	if not (left and type(width) == 'number' and type(height) == 'number') or IsSecret(width) or IsSecret(height) then return nil end
	return { frame = item.frame, name = item.name, x = left, y = bottom, width = width, height = height }
end

local function Saved(create)
	local db = Theme:DB()
	if type(db.chatDocked) ~= 'table' then
		if not create then return nil end
		db.chatDocked = {}
	end
	return db.chatDocked
end

-- General is the window ElvUI keeps in its left chat panel (the profile's own snapping key); ElvUI then
-- positions its chat windows itself. True when General is (now) the left panel's window.
-- docked: a window was just docked - ElvUI positions all its chat windows once more (its own hook on
-- FCF_DockFrame positions only the window that was docked).
function Chat:Snap(CH, E, primary, docked)
	if CH.LeftChatWindow == primary then
		if docked and type(CH.PositionChats) == 'function' then Call(CH.PositionChats, CH) end
		return CH.LeftChatWindow == primary
	end
	local profile = type(E.db) == 'table' and E.db.chat
	if type(profile) ~= 'table' or profile.panelSnapping == false then return false end -- (snapping switched off in ElvUI: the windows stay where its owner put them)
	if CH.LeftChatWindow ~= nil then return false end -- another window is ElvUI's left window and lies clear of the BANZAI frames: its owner's choice
	local id = primary.GetID and primary:GetID()
	if type(id) ~= 'number' or IsSecret(id) then return false end
	profile.panelSnapLeftID = id
	if profile.panelSnapRightID == id then profile.panelSnapRightID = nil end
	if type(CH.PositionChats) == 'function' then Call(CH.PositionChats, CH) end
	return CH.LeftChatWindow == primary
end

-- Brings the chat into the BANZAI CHAT frame. Returns true and the state, or false and why not.
-- Idempotent: with nothing to dock and General snapped it changes nothing.
function Chat:Apply(reason)
	if not Chat.Owned() then
		self.state = nil
		return false, 'not arranged here'
	end
	if InCombatLockdown() then
		self.pending = true
		return false, 'waiting (combat)'
	end
	self.pending = false
	local CH, E = ChatModule()
	local dockFrame = _G.FCF_DockFrame
	if not (CH and type(dockFrame) == 'function') then
		self.state = { reason = reason, problem = 'ElvUI chat is not presenting the chat' }
		return false, self.state.problem
	end
	local list, primary, dock = self:Candidates()
	if not list then
		self.state = { reason = reason, problem = primary }
		return false, primary
	end
	local docked, failed = {}, {}
	for _, item in ipairs(list) do
		local saved = Saved(true)
		local before = saved[item.frame]
		saved[item.frame] = Placement(item) or before or false -- where it is now, each time it is docked
		local count = type(dock.DOCKED_CHAT_FRAMES) == 'table' and #dock.DOCKED_CHAT_FRAMES or 0
		local ok = Call(dockFrame, item.chat, count + 1, false)
		if ok and item.chat.isDocked then
			docked[#docked + 1] = item.name or item.frame
		else
			failed[#failed + 1] = item.name or item.frame
			saved[item.frame] = before -- not docked: nothing new to hand back
		end
	end
	-- General stays the window on show (what a click on its tab does)
	if #docked > 0 and type(_G.FCF_SelectDockFrame) == 'function' then Call(_G.FCF_SelectDockFrame, primary) end
	local snapped = self:Snap(CH, E, primary, #docked > 0)
	self.state = { reason = reason, docked = docked, failed = failed, snapped = snapped }
	return true, self.state
end

-- Hands the windows back: every window BANZAI docked is undocked and put where it was. Returns how many
-- (nil and why while it has to wait). Restore Pre-Banzai calls this before it switches the profile.
function Chat:Release(reason)
	local saved = Saved(false)
	if not saved or next(saved) == nil then
		if saved then Theme:DB().chatDocked = nil end
		return 0
	end
	if InCombatLockdown() then return nil, 'waiting (combat)' end
	local dock = _G.GeneralDockManager
	local primary = type(dock) == 'table' and dock.primary or nil
	local undock = _G.FCF_UnDockFrame
	local count = 0
	for frameName, place in pairs(saved) do
		local chat = _G[frameName]
		-- only a window that is still the one BANZAI docked: same slot, same name, still a tab of the dock
		if Usable(chat) and chat ~= primary and chat.isDocked and type(undock) == 'function' and (type(place) ~= 'table' or place.name == WindowName(chat)) then
			if Call(undock, chat) then
				if type(place) == 'table' then
					chat:ClearAllPoints()
					chat:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', place.x, place.y)
					chat:SetSize(place.width, place.height)
				end
				chat:Show()
				local tab = _G[frameName .. 'Tab']
				if Usable(tab) and tab.Show then tab:Show() end
				if type(_G.FCF_SavePositionAndDimensions) == 'function' then Call(_G.FCF_SavePositionAndDimensions, chat) end
				count = count + 1
			end
		end
	end
	Theme:DB().chatDocked = nil
	self.state = { reason = reason, released = count }
	return count
end

-- settings, the profile, a login: arranged while BANZAI owns the chat frame; handed back when the Banzai
-- chat frame is switched off on the Banzai profile (a profile switch away is Restore's business)
function Chat:Refresh(reason)
	if not (ns.Flavor and ns.Flavor.IsForever()) then return end
	if Chat.Owned() then return self:Apply(reason or 'refresh') end
	if Compat.Active() and Theme:DB().chatFrame == false and Saved(false) then
		local count, why = self:Release('chat frame off')
		self.pending = (count == nil) -- blocked by combat: done when combat ends
		return count, why
	end
end

-- one line for /banzai status and /banzai forever
function Chat:StatusText()
	if not (ns.Flavor and ns.Flavor.IsForever()) then return 'not used on this client' end
	if not Chat.Owned() then return 'off (the Banzai chat frame is off or another profile is active)' end
	local s = self.state
	if self.pending then return 'waiting for combat to end' end
	if type(s) ~= 'table' then return 'not arranged yet' end
	if s.problem then return 'not arranged: ' .. tostring(s.problem) end
	local saved = Saved(false)
	local held = {}
	for frameName, place in pairs(saved or {}) do held[#held + 1] = (type(place) == 'table' and place.name) or frameName end
	table.sort(held)
	return string.format('General %s; docked by BANZAI: %s%s', s.snapped and 'in the BANZAI CHAT frame' or 'not in ElvUI\'s left panel (ElvUI snapping is off or another window holds it)',
		#held > 0 and table.concat(held, ', ') or 'none', (s.failed and #s.failed > 0) and ('; could not dock: ' .. table.concat(s.failed, ', ')) or '')
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:SetScript('OnEvent', function()
	if Chat.pending then Chat:Refresh('after combat') end
end)
