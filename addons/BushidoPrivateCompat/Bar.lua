--[[
	BANZAI - Bar.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	The Banzai bottom information bar: one full-width, very dark glass strip
	with a thin green -> purple edge, replacing Bushido's small datatext panel.

	Content and order are fixed:
	  left edge -> centre   HONOR  CONQUEST  MASTERY  HASTE  VERSATILITY  DURABILITY
	  centre (larger)       FPS  MS  TIME
	  centre -> right edge  SPEC  ILVL (PVE / PVP)  PROFESSIONS  FRIENDS  GUILD  GOLD

	Small readable font (the Banzai small-text font), muted labels, one vivid
	colour per value; TIME carries a subtle two-tone gradient. 0.5.0: FPS label
	and value share one green of their own; latency is neutral unless it is
	high (amber / red). Every label + value pair is centred in its own equal
	segment of its group, label and value on one baseline, the text centred
	vertically between the top edge and the bottom of the glass. Values come
	from the player's own client data only (stats, currencies, durability,
	frame rate, latency, friends / guild counts, money); nothing about other
	units and nothing restricted. Clicking an entry opens the matching
	Blizzard panel (out of combat).

	1.0.0: hovering an entry explains it and clicking opens its window
	(Info.lua: tooltips, the click targets, the one-line message in combat);
	what the panel shows and in which order is unchanged.
]]
local _, ns = ...
local Theme = ns.Theme

local Bar = {}
ns.Bar = Bar

local WHITE = Theme.WHITE
local LABEL = { 0.62, 0.64, 0.70 }
local FPS_GREEN = { 0.16, 1.00, 0.70 } -- one coherent colour for FPS (label and value), used nowhere else on the panel
local MS_NORMAL = { 0.84, 0.90, 1.00 }
Bar.FPS_COLOR = FPS_GREEN
local HONOR_ID, CONQUEST_ID = 1792, 1602
local GOLD_ICON = '|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:0:0|t'
local SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 15, 16, 17 }

local function Call(name, ...)
	if InCombatLockdown() then return end
	local fn = _G[name]
	if type(fn) == 'function' then pcall(fn, ...) end
end

local function Safe(value)
	if issecretvalue and issecretvalue(value) then return nil end
	return value
end

local function Hex(c) return '|cff' .. Theme:Hex(c) end

local function Thousands(n)
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
	return (out:gsub('^,', ''))
end

local function Currency(id)
	local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(id)
	local q = info and Safe(info.quantity)
	return q and Thousands(q) or '-' -- 1.0.0: unavailable is not a zero
end

local function Percent(v)
	v = Safe(v)
	return v and string.format('%.1f%%', v) or '-'
end

---------------------------------------------------------------------------
-- Items (fixed order)
---------------------------------------------------------------------------
Bar.ITEMS = {
	left = {
		{ key = 'honor', label = 'HONOR', color = { 1.00, 0.42, 0.30 }, value = function() return Currency(HONOR_ID) end, click = function() Call('TogglePVPUI') end },
		{ key = 'conquest', label = 'CONQUEST', color = { 1.00, 0.72, 0.22 }, value = function() return Currency(CONQUEST_ID) end, click = function() Call('TogglePVPUI') end },
		{ key = 'mastery', label = 'MASTERY', color = { 0.72, 0.48, 1.00 }, value = function() return Percent(GetMasteryEffect and GetMasteryEffect()) end, click = function() Call('ToggleCharacter', 'PaperDollFrame') end },
		{ key = 'haste', label = 'HASTE', color = { 0.20, 0.92, 0.85 }, value = function() return Percent(GetHaste and GetHaste()) end, click = function() Call('ToggleCharacter', 'PaperDollFrame') end },
		{ key = 'versatility', label = 'VERSATILITY', color = { 0.58, 1.00, 0.32 }, value = function()
			local id = CR_VERSATILITY_DAMAGE_DONE or 29
			local a = GetCombatRatingBonus and Safe(GetCombatRatingBonus(id)) or 0
			local b = GetVersatilityBonus and Safe(GetVersatilityBonus(id)) or 0
			return Percent(a + b)
		end, click = function() Call('ToggleCharacter', 'PaperDollFrame') end },
		{ key = 'durability', label = 'DURABILITY', color = { 0.58, 1.00, 0.32 }, value = function(item)
			local lowest
			for _, slot in ipairs(SLOTS) do
				local cur, max = GetInventoryItemDurability(slot)
				cur, max = Safe(cur), Safe(max)
				if cur and max and max > 0 then
					local p = cur / max * 100
					if not lowest or p < lowest then lowest = p end
				end
			end
			if not lowest then item.dynamic = nil return '-' end -- 1.0.0: nothing that wears down: no number
			item.dynamic = (lowest >= 50 and { 0.58, 1.00, 0.32 }) or (lowest >= 25 and { 1.00, 0.80, 0.20 }) or { 1.00, 0.30, 0.30 }
			return string.format('%d%%', math.floor(lowest + 0.5))
		end, click = function() Call('ToggleCharacter', 'PaperDollFrame') end },
	},
	center = {
		{ key = 'fps', label = 'FPS', color = FPS_GREEN, labelColor = FPS_GREEN, value = function()
			local fps = Safe(GetFramerate())
			return fps and tostring(math.floor(fps + 0.5)) or '-'
		end },
		{ key = 'ms', label = 'MS', color = MS_NORMAL, value = function(item)
			local _, _, home, world = GetNetStats()
			local ms = Safe(world) or Safe(home)
			if not ms then item.dynamic = MS_NORMAL return '-' end -- 1.0.0: unavailable is not a zero
			item.dynamic = (ms < 150 and MS_NORMAL) or (ms < 300 and { 1.00, 0.80, 0.20 }) or { 1.00, 0.30, 0.30 } -- warning colours only when it is high
			return tostring(ms)
		end },
		{ key = 'time', label = nil, gradient = { { 0.95, 0.97, 1.00 }, { 0.78, 0.62, 1.00 } }, value = function()
			local text = date('%I:%M %p')
			return (text:gsub('^0', ''))
		end, click = function() Call('ToggleCalendar') end },
	},
	right = {
		{ key = 'spec', label = 'SPEC', color = { 1, 1, 1 }, value = function(item)
			item.dynamic = Theme:PlayerClassColor()
			local index = GetSpecialization and GetSpecialization()
			if not index then return '-' end
			local _, name, _, icon = GetSpecializationInfo(index)
			if not name then return '-' end
			return (icon and ('|T' .. icon .. ':12:12:0:0:64:64:5:59:5:59|t ') or '') .. string.upper(name)
		end, click = function()
			if PlayerSpellsUtil and PlayerSpellsUtil.ToggleClassTalentOrSpecFrame and not InCombatLockdown() then pcall(PlayerSpellsUtil.ToggleClassTalentOrSpecFrame) end
		end },
		{ key = 'ilvl', label = 'ILVL', color = { 0.62, 0.80, 1.00 }, value = function()
			local _, equipped, pvp = GetAverageItemLevel()
			equipped, pvp = Safe(equipped), Safe(pvp)
			if not equipped then return '-' end
			local text = 'PVE ' .. math.floor(equipped)
			if pvp and pvp > 0 then text = text .. '  ' .. Hex({ 1.00, 0.55, 0.40 }) .. 'PVP ' .. math.floor(pvp) .. '|r' end
			return text
		end, click = function() Call('ToggleCharacter', 'PaperDollFrame') end },
		{ key = 'professions', label = 'PROFESSIONS', color = { 0.96, 0.86, 0.56 }, value = function()
			if not GetProfessions then return '-' end
			local parts = {}
			local p1, p2 = GetProfessions()
			for _, index in ipairs({ p1, p2 }) do
				if index then
					local _, icon, level = GetProfessionInfo(index)
					if icon then parts[#parts + 1] = '|T' .. icon .. ':12:12:0:0:64:64:5:59:5:59|t ' .. (level or '') end
				end
			end
			return #parts > 0 and table.concat(parts, '  ') or '-'
		end, click = function() Call('ToggleProfessionsBook') end },
		{ key = 'friends', label = 'FRIENDS', color = { 0.40, 0.76, 1.00 }, value = function()
			local online = (C_FriendList and C_FriendList.GetNumOnlineFriends and C_FriendList.GetNumOnlineFriends()) or 0
			local bnOnline = 0
			if BNGetNumFriends then bnOnline = select(2, BNGetNumFriends()) or 0 end
			return tostring((Safe(online) or 0) + (Safe(bnOnline) or 0))
		end, click = function() Call('ToggleFriendsFrame', 1) end },
		{ key = 'guild', label = 'GUILD', color = { 0.35, 1.00, 0.50 }, value = function()
			if not (IsInGuild and IsInGuild()) then return '-' end
			local _, online = GetNumGuildMembers()
			return tostring(Safe(online) or 0)
		end, click = function() Call('ToggleGuildFrame') end },
		{ key = 'gold', label = nil, color = { 1.00, 0.82, 0.25 }, value = function()
			local money = Safe(GetMoney()) or 0
			return Thousands(money / 10000) .. ' ' .. GOLD_ICON
		end, click = function() Call('ToggleAllBags') end },
	},
}

---------------------------------------------------------------------------
-- Frame
---------------------------------------------------------------------------
local function Font()
	return Theme:SmallFont()
end

local LABEL_GAP = 5
Bar.CENTER_SEGMENT = 104 -- each of FPS / MS / TIME

local function NewItem(parent, def, big)
	local button = CreateFrame('Button', nil, parent)
	button.def = def
	button.big = big
	button.value = button:CreateFontString(nil, 'OVERLAY')
	button.value:SetPoint('LEFT', button, 'LEFT', 0, 0)
	if def.label then
		-- the label sits on the value's baseline, just before it (Flow sets the offset)
		button.label = button:CreateFontString(nil, 'OVERLAY')
		button.label:SetPoint('BOTTOMRIGHT', button.value, 'BOTTOMLEFT', -LABEL_GAP, 1)
	end
	button:RegisterForClicks('LeftButtonUp')
	button:SetScript('OnClick', function()
		if ns.Info and ns.Info.CLICKS[def.key] then ns.Info:Click(def.key) elseif def.click then def.click() end
	end)
	-- 1.0.0 tooltips (Info.lua), gone again when the mouse leaves or the panel hides
	button:SetScript('OnEnter', function(self) if ns.Info then ns.Info:Show(self) end end)
	button:SetScript('OnLeave', function(self) if ns.Info then ns.Info:Hide(self) end end)
	button:SetScript('OnHide', function(self) if ns.Info then ns.Info:Hide(self) end end)
	return button
end

local function ItemWidth(item)
	local w = item.value:GetStringWidth() or 0
	if item.label then w = w + LABEL_GAP + (item.label:GetStringWidth() or 0) end
	return math.ceil(w)
end

function Bar:Build()
	if self.frame then return self.frame end
	local f = CreateFrame('Frame', 'BanzaiInfoBar', UIParent)
	f:SetFrameStrata('LOW')
	f:SetFrameLevel(1)
	f:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 0, 0)
	f:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', 0, 0)

	-- dark green glass (the game shows faintly through) and the thin Banzai
	-- gradient edge as its only top border (0.5.1: the soft glow band under the
	-- edge read as a second line and is gone). Alpha lives in the gradient
	-- colours (SetAlpha has no effect on gradient textures).
	f.glass = f:CreateTexture(nil, 'BACKGROUND', nil, 0)
	f.glass:SetAllPoints()
	f.glass:SetTexture(WHITE)
	f.edges = {}
	local EDGE_STRIPS = 8
	for i = 1, EDGE_STRIPS do
		local edge = f:CreateTexture(nil, 'BORDER')
		edge:SetTexture(WHITE)
		edge:SetHeight(2)
		f.edges[i] = edge
	end

	f.items = {}
	for group, defs in pairs(self.ITEMS) do
		for index, def in ipairs(defs) do
			local item = NewItem(f, def, group == 'center')
			item.group, item.index = group, index
			f.items[#f.items + 1] = item
		end
	end
	self.frame = f

	f:SetScript('OnSizeChanged', function() Bar:Layout() end)
	f:RegisterEvent('PLAYER_ENTERING_WORLD')
	for _, event in ipairs({ 'CURRENCY_DISPLAY_UPDATE', 'HONOR_XP_UPDATE', 'COMBAT_RATING_UPDATE', 'MASTERY_UPDATE', 'UNIT_STATS',
		'UPDATE_INVENTORY_DURABILITY', 'PLAYER_SPECIALIZATION_CHANGED', 'PLAYER_EQUIPMENT_CHANGED', 'PLAYER_AVG_ITEM_LEVEL_UPDATE',
		'SKILL_LINES_CHANGED', 'FRIENDLIST_UPDATE', 'BN_FRIEND_ACCOUNT_ONLINE', 'BN_FRIEND_ACCOUNT_OFFLINE', 'GUILD_ROSTER_UPDATE', 'PLAYER_MONEY' }) do
		pcall(f.RegisterEvent, f, event)
	end
	f:SetScript('OnEvent', function() Bar:Update() end)
	self:Layout()
	return f
end

local function Width()
	return (UIParent.GetWidth and UIParent:GetWidth()) or 1920
end

-- Every item gets its own segment of its group (its text width plus an equal
-- share of the free space) and its label + value pair is centred in it, so
-- every pair has the same room on both sides: the left group from the left
-- margin to the centre group, the centre group (FPS / MS / TIME) in fixed
-- segments around the screen centre, the right group from there to the right
-- margin (gold last).
function Bar:Flow()
	local f = self.frame
	if not f then return end
	local width = Width()
	local margin, groupGap = 10, 24
	local groups = { left = {}, center = {}, right = {} }
	for _, item in ipairs(f.items) do table.insert(groups[item.group], item) end
	for _, list in pairs(groups) do table.sort(list, function(a, b) return a.index < b.index end) end

	local function centre(list, x0, x1, fixed)
		local used = 0
		for _, item in ipairs(list) do item.w = ItemWidth(item); used = used + item.w end
		local share = math.max(0, (x1 - x0) - used) / math.max(1, #list)
		local x = x0
		for _, item in ipairs(list) do
			local seg = fixed or (item.w + share)
			local labelW = item.label and (math.ceil(item.label:GetStringWidth() or 0) + LABEL_GAP) or 0
			item:ClearAllPoints()
			item:SetWidth(math.max(1, item.w))
			item:SetPoint('LEFT', f, 'LEFT', x + seg / 2 - item.w / 2, -1)
			item.value:ClearAllPoints()
			item.value:SetPoint('LEFT', item, 'LEFT', labelW, 0)
			item.segment = { x, x + seg }
			x = x + seg
		end
	end
	local centerWidth = self.CENTER_SEGMENT * #groups.center
	local c0 = width / 2 - centerWidth / 2
	centre(groups.center, c0, c0 + centerWidth, self.CENTER_SEGMENT)
	centre(groups.left, margin, c0 - groupGap)
	centre(groups.right, c0 + centerWidth + groupGap, width - margin)
end

function Bar:Layout()
	local f = self.frame
	if not f then return end
	local db = Theme:DB()
	local width = Width()
	local h = db.barHeight or 32
	f:SetHeight(h)
	local font = Font()
	for _, item in ipairs(f.items) do
		local size = item.big and (db.barCenterSize or 15) or (db.barTextSize or 11)
		item:SetHeight(h - 2) -- text centred inside the glass, below the edge
		if item.label then item.label:SetFont(font, math.max(8, size - 2), 'OUTLINE') end
		item.value:SetFont(font, size, 'OUTLINE')
	end
	local strips = #f.edges
	for i, edge in ipairs(f.edges) do
		edge:ClearAllPoints()
		edge:SetPoint('TOPLEFT', f, 'TOPLEFT', (i - 1) * width / strips, 0)
		edge:SetWidth(width / strips + 0.5)
	end
	self:Paint()
	self:Update()
end

function Bar:Paint()
	local f = self.frame
	if not f then return end
	Theme:Glass(f.glass, Theme:DB().barOpacity)
	local stops = Theme:Stops('h')
	local strips = #f.edges
	for i, edge in ipairs(f.edges) do
		local c0, c1 = Theme:ColorAt(stops, (i - 1) / strips), Theme:ColorAt(stops, i / strips)
		Theme:Gradient(edge, 'HORIZONTAL', c0, c1, 0.95, 0.95)
	end
end

function Bar:Update()
	local f = self.frame
	if not (f and f:IsShown()) then return end
	for _, item in ipairs(f.items) do
		local def = item.def
		local ok, text = pcall(def.value, def)
		if not ok or type(text) ~= 'string' then text = '-' end
		if item.label then item.label:SetText(Hex(def.labelColor or LABEL) .. def.label .. '|r') end
		if def.gradient then
			local plain = text:gsub('|T.-|t', '')
			item.value:SetText(Theme:GradientText(plain, def.gradient[1], def.gradient[2]))
		else
			item.value:SetText(Hex(def.dynamic or def.color) .. text .. '|r')
		end
	end
	self:Flow()
end

function Bar:Refresh()
	local db = Theme:DB()
	local active = ns.Compat and ns.Compat.Active and ns.Compat.Active()
	local show = active and db.bar and true or false
	if show and not self.frame then self:Build() end
	if not self.frame then return end
	self.frame:SetShown(show)
	if show then
		self:Layout()
		if not self.ticker and C_Timer and C_Timer.NewTicker then
			self.ticker = C_Timer.NewTicker(1, function() Bar:UpdateFast() end)
		end
	end
end

-- frame rate, latency and time once a second
function Bar:UpdateFast()
	local f = self.frame
	if not (f and f:IsShown()) then return end
	for _, item in ipairs(f.items) do
		if item.group == 'center' then
			local def = item.def
			local ok, text = pcall(def.value, def)
			if ok and type(text) == 'string' then
				if def.gradient then
					item.value:SetText(Theme:GradientText(text, def.gradient[1], def.gradient[2]))
				else
					item.value:SetText(Hex(def.dynamic or def.color) .. text .. '|r')
				end
			end
		end
	end
	self:Flow()
	if ns.Info then ns.Info:Tick() end -- a hovered FPS / MS / TIME tooltip follows
end
