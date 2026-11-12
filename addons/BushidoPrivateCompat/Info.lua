--[[
	BANZAI - Info.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	1.0.0: what each entry of the bottom panel means, on hover, and what a
	click opens. The panel itself (Bar.lua: content, order, look) is unchanged.

	  data      the game's own data for this character, read through its
	            current API when the tooltip opens (and once a second while
	            FPS / MS / TIME stay hovered); Blizzard's own explanation texts
	            for the stats. A value the game does not give (or keeps secret)
	            says so - never a zero, never a made-up cap or average.
	  gold      this character (live), the session gain / loss (since login or
	            reload), the Warband bank (the game's own value when it gives
	            one, else Syndicator's last-seen value), the other characters
	            Syndicator has seen - through Syndicator's public API, read
	            only - and the total of what is KNOWN (never called complete)
	  lists     friends / guild members online: at most Info.CAP lines, then
	            "+N more"
	  clicks    the matching Blizzard window through its own toggle function;
	            in combat only the bags open, every other entry says in one
	            line that it cannot open now (nothing is queued for later)
	  tooltips  Banzai's tooltip (Tooltip.lua) above the entry (or at the
	            cursor, BANZAI > TOOLTIPS); they never show in combat unless
	            Darren allows it there
]]
local _, ns = ...
local Theme = ns.Theme

local Info = {}
ns.Info = Info

Info.CAP = 12 -- list lines at most (friends, guild members, other characters)
local HONOR_ID, CONQUEST_ID = 1792, 1602
local SLOTS = { 1, 3, 5, 6, 7, 8, 9, 10, 16, 17 } -- the equipment slots that wear down
local SLOT_NAMES = { [1] = 'HEADSLOT', [3] = 'SHOULDERSLOT', [5] = 'CHESTSLOT', [6] = 'WAISTSLOT', [7] = 'LEGSSLOT', [8] = 'FEETSLOT',
	[9] = 'WRISTSLOT', [10] = 'HANDSSLOT', [16] = 'MAINHANDSLOT', [17] = 'SECONDARYHANDSLOT' }
local SLOT_FALLBACK = { [1] = 'Head', [3] = 'Shoulder', [5] = 'Chest', [6] = 'Waist', [7] = 'Legs', [8] = 'Feet', [9] = 'Wrist', [10] = 'Hands', [16] = 'Main Hand', [17] = 'Off Hand' }
local ICON = {
	gold = '|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:2:0|t',
	silver = '|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:2:0|t',
	copper = '|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:2:0|t',
}
local C = {
	title = { 1, 1, 1 },
	label = { 0.70, 0.73, 0.78 },
	value = { 0.95, 0.97, 1.00 },
	muted = { 0.56, 0.60, 0.63 },
	good = { 0.42, 0.95, 0.45 },
	hint = { 0.62, 1.00, 0.12 },
	warn = { 1.00, 0.80, 0.20 }, -- warnings only
	bad = { 1.00, 0.30, 0.30 },  -- warnings only
}
Info.COLORS = C

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Safe(value)
	if IsSecret(value) then return nil end
	return value
end

-- the first four results of a game function, secret ones as nil
local function Call(fn, ...)
	if type(fn) ~= 'function' then return nil end
	local ok, a, b, c, d = pcall(fn, ...)
	if not ok then return nil end
	return Safe(a), Safe(b), Safe(c), Safe(d)
end
Info.Call = Call

-- every result of a game function (a table), secret ones as nil
local function CallAll(fn, ...)
	if type(fn) ~= 'function' then return {} end
	local r = { pcall(fn, ...) }
	if not r[1] then return {} end
	local out = {}
	for i = 2, 20 do out[i - 1] = Safe(r[i]) end
	return out
end
Info.CallAll = CallAll

local function Num(n)
	n = tonumber(n)
	if not n then return '-' end
	local s = tostring(math.floor(n + 0.5))
	local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
	return (out:gsub('^(-?),', '%1'))
end
Info.Num = Num

local function Pct(n) return n and string.format('%.2f%%', n) or nil end

function Info.Money(copper)
	copper = tonumber(copper)
	if not copper then return '-' end
	local sign = copper < 0 and '-' or ''
	copper = math.abs(math.floor(copper + 0.5))
	local gold, silver, rest = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
	return sign .. Num(gold) .. ICON.gold .. ' ' .. string.format('%02d', silver) .. ICON.silver .. ' ' .. string.format('%02d', rest) .. ICON.copper
end

function Info.Duration(seconds)
	seconds = tonumber(seconds)
	if not seconds or seconds < 0 then return nil end
	local d, h, m = math.floor(seconds / 86400), math.floor(seconds / 3600) % 24, math.floor(seconds / 60) % 60
	if d > 0 then return string.format('%dd %dh', d, h) end
	if h > 0 then return string.format('%dh %dm', h, m) end
	return string.format('%dm', math.max(m, seconds > 0 and 1 or 0))
end

local function ClassColor(token)
	return (token and Theme:ClassColor(token)) or C.value
end

---------------------------------------------------------------------------
-- Tooltip lines
---------------------------------------------------------------------------
local function Title(tt, text, color)
	color = color or C.title
	tt:AddLine(text, color[1], color[2], color[3])
end

local function Pair(tt, left, right, color)
	color = color or C.value
	tt:AddDoubleLine(left, right, C.label[1], C.label[2], C.label[3], color[1], color[2], color[3])
end

local function Note(tt, text, color)
	if type(text) ~= 'string' or text == '' then return end
	color = color or C.muted
	tt:AddLine(text, color[1], color[2], color[3], true)
end

local function Space(tt) tt:AddLine(' ') end

local function Hint(tt, text)
	Space(tt)
	tt:AddLine(text, C.hint[1], C.hint[2], C.hint[3])
end

local function Unavailable(tt, what) Pair(tt, what, 'not available from the game', C.muted) end

local function Currency(id)
	local get = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo
	if not get then return nil end
	local ok, info = pcall(get, id)
	if not ok or type(info) ~= 'table' then return nil end
	local out = {}
	for _, key in ipairs({ 'name', 'description', 'quantity', 'maxQuantity', 'totalEarned', 'useTotalEarnedForMaxQty', 'quantityEarnedThisWeek', 'maxWeeklyQuantity', 'canEarnPerWeek' }) do
		out[key] = Safe(info[key])
	end
	return out
end
Info.Currency = Currency

local function Rating(id)
	local rating = Call(GetCombatRating, id)
	return rating and (BreakUpLargeNumbers and BreakUpLargeNumbers(rating) or Num(rating)) or nil
end

local function Bonus(id, coeff)
	local timerunning = Call(PlayerIsTimerunning)
	local bonus = Call(GetCombatRatingBonus, id)
	if not bonus then return nil end
	if timerunning then return nil end
	return bonus * (coeff or 1)
end

-- Blizzard's own explanation text, formatted the way the character window does
local function Explain(tt, key, ...)
	local text = _G[key]
	if type(text) ~= 'string' then return false end
	local ok, line = pcall(string.format, text, ...)
	if ok then Note(tt, line, C.value) end
	return ok
end

---------------------------------------------------------------------------
-- One tooltip per entry
---------------------------------------------------------------------------
Info.TIPS = {}
local TIPS = Info.TIPS

function TIPS.honor(tt)
	Title(tt, 'HONOR', { 1.00, 0.42, 0.30 })
	local c = Currency(HONOR_ID)
	if c and c.quantity then
		local cap = (c.maxQuantity and c.maxQuantity > 0) and (' / ' .. Num(c.maxQuantity)) or ''
		Pair(tt, 'Honor', Num(c.quantity) .. cap)
		if not (c.maxQuantity and c.maxQuantity > 0) then Pair(tt, 'Cap', 'none reported by the game', C.muted) end
		if c.canEarnPerWeek and c.maxWeeklyQuantity and c.maxWeeklyQuantity > 0 then
			Pair(tt, 'This week', Num(c.quantityEarnedThisWeek) .. ' / ' .. Num(c.maxWeeklyQuantity))
		end
	else
		Unavailable(tt, 'Honor')
	end
	local level = Call(UnitHonorLevel, 'player')
	if level then Pair(tt, 'Honor level', Num(level)) end
	local cur, max = Call(UnitHonor, 'player'), Call(UnitHonorMax, 'player')
	if cur and max and max > 0 then Pair(tt, 'Toward the next level', Num(cur) .. ' / ' .. Num(max)) end
	if c and c.description then Space(tt) Note(tt, c.description) end
	Hint(tt, 'Click: open the PvP window')
end

function TIPS.conquest(tt)
	Title(tt, 'CONQUEST', { 1.00, 0.72, 0.22 })
	if ns.Flavor and not ns.Flavor.Has('conquest') then
		Unavailable(tt, 'Conquest')
		Hint(tt, 'Click: open the PvP window')
		return
	end
	local c = Currency(CONQUEST_ID)
	if not (c and c.quantity) then
		Unavailable(tt, 'Conquest')
	else
		Pair(tt, 'Current', Num(c.quantity))
		local cap = c.maxQuantity and c.maxQuantity > 0 and c.maxQuantity or nil
		if c.useTotalEarnedForMaxQty and c.totalEarned then
			Pair(tt, 'Earned this season', Num(c.totalEarned))
		end
		if cap then
			Pair(tt, c.useTotalEarnedForMaxQty and 'Seasonal cap' or 'Cap', Num(cap))
			if c.useTotalEarnedForMaxQty and c.totalEarned then Pair(tt, 'Still to earn', Num(math.max(0, cap - c.totalEarned))) end
		else
			Pair(tt, 'Seasonal cap', 'not reported by the game', C.muted)
		end
		if c.canEarnPerWeek and c.maxWeeklyQuantity and c.maxWeeklyQuantity > 0 then
			Pair(tt, 'This week', Num(c.quantityEarnedThisWeek) .. ' / ' .. Num(c.maxWeeklyQuantity))
		end
		if c.description then Space(tt) Note(tt, c.description) end
	end
	Hint(tt, 'Click: open the PvP window')
end

function TIPS.mastery(tt)
	if ns.Flavor and not ns.Flavor.Has('mastery') then
		Title(tt, 'MASTERY', { 0.72, 0.48, 1.00 })
		Unavailable(tt, 'Mastery')
		Hint(tt, 'Click: open the character window')
		return
	end
	local mastery, coeff = Call(GetMasteryEffect)
	Title(tt, 'MASTERY  ' .. (Pct(mastery) or ''), { 0.72, 0.48, 1.00 })
	if not mastery then Unavailable(tt, 'Mastery') Hint(tt, 'Click: open the character window') return end
	local spec = Call(C_SpecializationInfo and C_SpecializationInfo.GetSpecialization) or Call(GetSpecialization)
	local spells = spec and C_SpecializationInfo and C_SpecializationInfo.GetSpecializationMasterySpells
		and select(2, pcall(C_SpecializationInfo.GetSpecializationMasterySpells, spec))
	local shown = false
	if type(spells) == 'table' and tt.AppendInfo then
		for _, spell in ipairs(spells) do
			if Safe(spell) and pcall(tt.AppendInfo, tt, 'GetSpellByID', spell) then shown = true end
		end
	end
	if shown then Space(tt) end
	local bonus = Bonus(CR_MASTERY, coeff)
	if not (bonus and Explain(tt, 'STAT_MASTERY_TOOLTIP', Rating(CR_MASTERY) or '-', bonus)) then
		Pair(tt, 'Rating', Rating(CR_MASTERY) or '-')
	end
	Hint(tt, 'Click: open the character window')
end

function TIPS.haste(tt)
	local haste = Call(GetHaste)
	Title(tt, 'HASTE  ' .. (Pct(haste) or ''), { 0.20, 0.92, 0.85 })
	if not haste then Unavailable(tt, 'Haste') Hint(tt, 'Click: open the character window') return end
	local _, class = Call(UnitClass, 'player')
	local text = class and _G['STAT_HASTE_' .. class .. '_TOOLTIP'] or _G.STAT_HASTE_TOOLTIP
	if type(text) == 'string' then Note(tt, text, C.value) end
	local rating, bonus = Rating(CR_HASTE_MELEE), Bonus(CR_HASTE_MELEE)
	if not (rating and bonus and Explain(tt, 'STAT_HASTE_BASE_TOOLTIP', rating, bonus)) then Pair(tt, 'Rating', rating or '-') end
	Hint(tt, 'Click: open the character window')
end

function TIPS.versatility(tt)
	if ns.Flavor and not ns.Flavor.Has('versatility') then
		Title(tt, 'VERSATILITY', { 0.58, 1.00, 0.32 })
		Unavailable(tt, 'Versatility')
		Hint(tt, 'Click: open the character window')
		return
	end
	local doneID, takenID = CR_VERSATILITY_DAMAGE_DONE or 29, CR_VERSATILITY_DAMAGE_TAKEN or 31
	local doneR, takenR = Call(GetCombatRatingBonus, doneID), Call(GetCombatRatingBonus, takenID)
	local doneV, takenV = Call(GetVersatilityBonus, doneID), Call(GetVersatilityBonus, takenID)
	local done = doneR and (doneR + (doneV or 0)) or nil
	local taken = takenR and (takenR + (takenV or 0)) or nil
	Title(tt, 'VERSATILITY  ' .. (Pct(done) or ''), { 0.58, 1.00, 0.32 })
	if not done then Unavailable(tt, 'Versatility') Hint(tt, 'Click: open the character window') return end
	Pair(tt, 'Damage and healing done', '+' .. Pct(done), C.good)
	if taken then Pair(tt, 'Damage taken', '-' .. Pct(taken), C.good) end
	local rating = Rating(doneID)
	Pair(tt, 'Rating', rating or '-')
	if taken and rating then Space(tt) Explain(tt, 'CR_VERSATILITY_TOOLTIP', done, taken, rating, done, taken) end
	Hint(tt, 'Click: open the character window')
end

local function SlotName(slot)
	local name = _G[SLOT_NAMES[slot]]
	return type(name) == 'string' and name or SLOT_FALLBACK[slot]
end

function TIPS.durability(tt)
	Title(tt, 'DURABILITY', { 0.58, 1.00, 0.32 })
	local total, max, lowest, lowSlot = 0, 0, nil, nil
	for _, slot in ipairs(SLOTS) do
		local cur, most = Call(GetInventoryItemDurability, slot)
		if cur and most and most > 0 then
			local p = cur / most * 100
			total, max = total + cur, max + most
			local color = (p >= 50 and C.value) or (p >= 25 and C.warn) or C.bad
			Pair(tt, SlotName(slot), string.format('%d%%', math.floor(p + 0.5)), color)
			if not lowest or p < lowest then lowest, lowSlot = p, slot end
		end
	end
	if max == 0 then
		Note(tt, 'No equipped item that wears down.')
	else
		Space(tt)
		local overall = total / max * 100
		Pair(tt, 'Overall', string.format('%d%%', math.floor(overall + 0.5)))
		Pair(tt, 'Lowest', SlotName(lowSlot) .. '  ' .. string.format('%d%%', math.floor(lowest + 0.5)), (lowest >= 50 and C.value) or (lowest >= 25 and C.warn) or C.bad)
		if lowest < 25 then Note(tt, 'Repair soon: an item at 0 % stops giving its stats.', C.bad)
		elseif lowest < 50 then Note(tt, 'Wearing down.', C.warn) end
	end
	Hint(tt, 'Click: open the character window')
end

function TIPS.fps(tt)
	local fps = Call(GetFramerate)
	Title(tt, 'FPS  ' .. (fps and tostring(math.floor(fps + 0.5)) or '-'), ns.Bar and ns.Bar.FPS_COLOR)
	if not fps then Unavailable(tt, 'Frame rate') return end
	if fps >= 60 then Pair(tt, 'State', 'smooth', C.good)
	elseif fps >= 30 then Pair(tt, 'State', 'playable', C.value)
	else Pair(tt, 'State', 'low - the game may feel sluggish', C.warn) end
	Note(tt, 'Frames drawn per second right now. Banzai keeps no average and no history.')
end

local function LatencyColor(ms)
	return (ms < 150 and C.good) or (ms < 300 and C.warn) or C.bad
end

function TIPS.ms(tt)
	local _, _, home, world = Call(GetNetStats)
	Title(tt, 'LATENCY')
	if not (home or world) then Unavailable(tt, 'Latency') return end
	if home then Pair(tt, 'Home', home .. ' ms', LatencyColor(home)) end
	if world then Pair(tt, 'World', world .. ' ms', LatencyColor(world)) end
	local worst = math.max(home or 0, world or 0)
	Pair(tt, 'State', (worst < 150 and 'healthy') or (worst < 300 and 'elevated') or 'high', LatencyColor(worst))
	Space(tt)
	Note(tt, 'Home: your connection to the realm - chat, guild, auction house. World: the game world - combat, movement, other players. The panel shows World.')
end

local function Clock(h, m)
	local suffix = (h >= 12) and 'PM' or 'AM'
	local h12 = h % 12
	if h12 == 0 then h12 = 12 end
	return string.format('%d:%02d %s', h12, m, suffix)
end

function TIPS.time(tt)
	Title(tt, 'TIME')
	local now = date('*t')
	Pair(tt, 'Local time', Clock(now.hour, now.min))
	local h, m = Call(GetGameTime)
	if h and m then Pair(tt, 'Realm time', Clock(h, m)) else Unavailable(tt, 'Realm time') end
	Pair(tt, 'Local date', date('%A %d %B %Y'))
	local cal = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and select(2, pcall(C_DateAndTime.GetCurrentCalendarTime))
	if type(cal) == 'table' and Safe(cal.monthDay) and Safe(cal.month) and Safe(cal.year) then
		local weekdays, months = _G.CALENDAR_WEEKDAY_NAMES, _G.CALENDAR_FULLDATE_MONTH_NAMES
		local weekday = type(weekdays) == 'table' and weekdays[cal.weekday] or nil
		local month = type(months) == 'table' and months[cal.month] or tostring(cal.month)
		Pair(tt, 'Realm date', ((weekday and (weekday .. ' ')) or '') .. cal.monthDay .. ' ' .. tostring(month) .. ' ' .. cal.year)
	end
	local daily = C_DateAndTime and Call(C_DateAndTime.GetSecondsUntilDailyReset)
	local weekly = C_DateAndTime and Call(C_DateAndTime.GetSecondsUntilWeeklyReset)
	if daily then Pair(tt, 'Daily reset in', Info.Duration(daily)) end
	if weekly then Pair(tt, 'Weekly reset in', Info.Duration(weekly)) end
	Space(tt)
	Note(tt, 'Local time is this computer\'s clock; realm time is the server\'s - daily and weekly resets follow the realm.')
	Hint(tt, 'Click: open the calendar')
end

function TIPS.spec(tt)
	-- 1.5.0-dev1 (WoW Forever): talent trees, not a specialization - every tree with its committed points,
	-- the leading one named (the game's own names); role layouts use only verified class/tree mappings
	local Flavor = ns.Flavor
	if Flavor and Flavor.IsForever() then
		local tree, trees = Flavor.TalentTree()
		Title(tt, tree and ((tree.icon and ('|T' .. tree.icon .. ':16:16:0:0:64:64:5:59:5:59|t ') or '') .. string.upper(tree.name)) or 'TALENT TREES', Theme:PlayerClassColor())
		if trees then
			for _, t in ipairs(trees) do Pair(tt, t.name, tostring(t.points)) end
			if not tree then Note(tt, 'No leading tree (no points spent, or two trees tie): Banzai shows your class only.') end
		else
			Note(tt, 'The game has not reported your talents yet.')
		end
		local roles = _G.BanzaiRoles
		local detection = roles and roles.Detection and roles:Detection()
		if detection then
			Pair(tt, 'Detected role / Banzai layout', tostring(detection.role or 'unmapped') .. ' / ' .. tostring(detection.layout))
			Note(tt, tostring(detection.reason) .. '; local override: ' .. tostring(detection.override))
		end
		Space(tt)
		Note(tt, 'WoW Forever has no game-provided spec role. Ambiguous or unmapped trees retain the last layout; use LAYOUT > DPS / HEALER PLACEMENT or /banzai role auto|dps|healer.')
		Hint(tt, 'Click: open the talent window (Banzai never changes your talents)')
		return
	end
	local index = Call(GetSpecialization)
	local spec = index and CallAll(GetSpecializationInfo, index) or {}
	local name, description, icon, role = spec[2], spec[3], spec[4], spec[5]
	if not name then
		Title(tt, 'SPECIALIZATION')
		Note(tt, 'No specialization chosen yet.')
		Hint(tt, 'Click: open the specialization window')
		return
	end
	Title(tt, (icon and ('|T' .. icon .. ':16:16:0:0:64:64:5:59:5:59|t ') or '') .. string.upper(name), Theme:PlayerClassColor())
	local roleName = role and _G[role]
	Pair(tt, 'Role', type(roleName) == 'string' and roleName or (role or '-'))
	local loot = Call(GetLootSpecialization)
	if loot == 0 then
		Pair(tt, 'Loot specialization', 'current (' .. name .. ')')
	elseif loot then
		local _, lootName = Call(GetSpecializationInfoByID, loot)
		Pair(tt, 'Loot specialization', lootName or tostring(loot))
	end
	local roles = _G.BanzaiRoles
	local layout = roles and roles.Current and roles.Current()
	if layout then Pair(tt, 'Banzai frame layout', layout) end
	if description then Space(tt) Note(tt, description) end
	Hint(tt, 'Click: open the specialization window (Banzai never changes your spec)')
end

function TIPS.ilvl(tt)
	local overall, equipped, pvp = Call(GetAverageItemLevel)
	local pvpAvailable = not (ns.Flavor and not ns.Flavor.Has('pvpItemLevel'))
	Title(tt, 'ITEM LEVEL', { 0.62, 0.80, 1.00 })
	if not equipped then Unavailable(tt, 'Item level') Hint(tt, 'Click: open the character window') return end
	Pair(tt, 'Equipped', string.format('%.1f', equipped))
	if overall then Pair(tt, 'Overall (best you own)', string.format('%.1f', overall)) end
	if pvpAvailable and pvp and pvp > 0 then Pair(tt, 'PvP (the game\'s PvP item level)', string.format('%.1f', pvp), { 1.00, 0.55, 0.40 })
	elseif not pvpAvailable then Pair(tt, 'PvP', 'not available on this client', C.muted)
	else Pair(tt, 'PvP', 'not reported by the game', C.muted) end
	local text = _G.STAT_AVERAGE_ITEM_LEVEL_TOOLTIP
	if type(text) == 'string' then Space(tt) Note(tt, text) end
	Hint(tt, 'Click: open the character window')
end

function TIPS.professions(tt)
	Title(tt, 'PROFESSIONS', { 0.96, 0.86, 0.56 })
	local list = CallAll(GetProfessions) -- primary, secondary, archaeology, fishing, cooking (any may be missing)
	local n = 0
	for i = 1, 5 do
		local index = list[i]
		if index then
			local pname, icon, rank, maxRank = Call(GetProfessionInfo, index)
			if pname then
				n = n + 1
				Pair(tt, (icon and ('|T' .. icon .. ':14:14:0:0:64:64:5:59:5:59|t ') or '') .. pname, (rank and maxRank) and (rank .. ' / ' .. maxRank) or '-')
			end
		end
	end
	if n == 0 then Note(tt, 'No profession learned.') end
	Hint(tt, 'Click: open your professions')
end

-- one status word for a friend / guild member, nothing when they are just online
local function Away(afk, dnd)
	if afk then return ' |cff9aa0aa(' .. (_G.CHAT_FLAG_AFK and tostring(_G.CHAT_FLAG_AFK):gsub('[<>]', '') or 'AFK') .. ')|r' end
	if dnd then return ' |cff9aa0aa(' .. (_G.CHAT_FLAG_DND and tostring(_G.CHAT_FLAG_DND):gsub('[<>]', '') or 'DND') .. ')|r' end
	return ''
end

local function Colored(text, c) return '|cff' .. Theme:Hex(c) .. tostring(text) .. '|r' end

local GAMES = { App = 'Battle.net', BSAp = 'Battle.net mobile', WoW = 'World of Warcraft' }

-- online friends: Battle.net first, then this realm's character friends
function Info.Friends()
	local out = {}
	local bnTotal = Call(BNGetNumFriends) or 0
	local getAccount = C_BattleNet and C_BattleNet.GetFriendAccountInfo
	for i = 1, (getAccount and bnTotal or 0) do
		local ok, acc = pcall(getAccount, i)
		local game = ok and type(acc) == 'table' and acc.gameAccountInfo
		if type(game) == 'table' and Safe(game.isOnline) then
			local who = Safe(acc.accountName) or Safe(acc.battleTag) or '?'
			local client = Safe(game.clientProgram)
			local detail
			if client == (_G.BNET_CLIENT_WOW or 'WoW') and Safe(game.characterName) then
				local level = Safe(game.characterLevel)
				detail = Colored(Safe(game.characterName), ClassColor(Safe(game.className) and Info.ClassToken(Safe(game.className))))
					.. (level and (' ' .. level) or '') .. ((Safe(game.areaName) and ('  ' .. Safe(game.areaName))) or '')
			else
				detail = Safe(game.richPresence) or GAMES[client] or client or ''
			end
			out[#out + 1] = { left = who .. Away(Safe(acc.isAFK) or Safe(game.isGameAFK), Safe(acc.isDND) or Safe(game.isGameBusy)), right = detail }
		end
	end
	local list = C_FriendList
	local count = list and list.GetNumFriends and Call(list.GetNumFriends) or 0
	for i = 1, (count or 0) do
		local ok, f = pcall(list.GetFriendInfoByIndex, i)
		if ok and type(f) == 'table' and Safe(f.connected) and Safe(f.name) then
			local token = Info.ClassToken(Safe(f.className))
			out[#out + 1] = { left = Colored(Safe(f.name), ClassColor(token)) .. Away(Safe(f.afk), Safe(f.dnd)),
				right = (Safe(f.level) and ('Level ' .. Safe(f.level)) or '') .. ((Safe(f.area) and ('  ' .. Safe(f.area))) or '') }
		end
	end
	return out, (bnTotal or 0) + (count or 0)
end

-- localized class name -> class token (friend lists give the localized name)
function Info.ClassToken(className)
	if type(className) ~= 'string' then return nil end
	local male, female = _G.LOCALIZED_CLASS_NAMES_MALE, _G.LOCALIZED_CLASS_NAMES_FEMALE
	for _, names in ipairs({ male, female }) do
		if type(names) == 'table' then
			for token, name in pairs(names) do if name == className then return token end end
		end
	end
	local upper = string.upper(className):gsub('%s', '')
	if RAID_CLASS_COLORS and RAID_CLASS_COLORS[upper] then return upper end
	return nil
end

local function List(tt, rows, total, word)
	for i = 1, math.min(#rows, Info.CAP) do tt:AddDoubleLine(rows[i].left, rows[i].right, 1, 1, 1, C.label[1], C.label[2], C.label[3]) end
	if #rows > Info.CAP then Note(tt, string.format('+%d more', #rows - Info.CAP)) end
	if #rows == 0 then Note(tt, 'Nobody ' .. word .. ' is online.') end
end

function TIPS.friends(tt)
	local rows, total = Info.Friends()
	Title(tt, 'FRIENDS', { 0.40, 0.76, 1.00 })
	Pair(tt, 'Online', #rows .. ' of ' .. total)
	Space(tt)
	List(tt, rows, total, 'on your friends list')
	Hint(tt, 'Click: open the friends list')
end

-- the guild roster is the game's; asked for again at most every 15 s while hovered
Info.ROSTER_EVERY = 15
function Info.RequestRoster()
	local now = GetTime and GetTime() or 0
	if Info.rosterAsked and now - Info.rosterAsked < Info.ROSTER_EVERY then return false end
	Info.rosterAsked = now
	if C_GuildInfo and C_GuildInfo.GuildRoster then pcall(C_GuildInfo.GuildRoster) return true end
	return false
end

function Info.Guild()
	local out = {}
	local total = Call(GetNumGuildMembers) or 0
	for i = 1, total do
		local r = CallAll(GetGuildRosterInfo, i)
		local name, level, zone, online, status, class, mobile = r[1], r[4], r[6], r[9], r[10], r[11], r[14]
		if name and online and not mobile then
			local short = (Ambiguate and Ambiguate(name, 'guild')) or name
			out[#out + 1] = { left = Colored(short, ClassColor(class)) .. Away(status == 1, status == 2), right = (level and ('Level ' .. level) or '') .. (zone and ('  ' .. zone) or '') }
		end
	end
	return out, total
end

function TIPS.guild(tt)
	if not Call(IsInGuild) then
		Title(tt, 'GUILD', { 0.35, 1.00, 0.50 })
		Note(tt, 'You are not in a guild.')
		Hint(tt, 'Click: open the guild window (guild finder)')
		return
	end
	Info.RequestRoster()
	local guildName, rankName = Call(GetGuildInfo, 'player')
	Title(tt, guildName or 'GUILD', { 0.35, 1.00, 0.50 })
	if rankName then Pair(tt, 'Your rank', rankName) end
	local rows, total = Info.Guild()
	local _, online = Call(GetNumGuildMembers)
	Pair(tt, 'Online', (online or #rows) .. ' of ' .. total)
	Space(tt)
	List(tt, rows, total, 'in the guild')
	local motd = Call(GetGuildRosterMOTD)
	if motd and motd ~= '' then Space(tt) Note(tt, 'MOTD: ' .. motd) end
	Hint(tt, 'Click: open the guild window')
end

---------------------------------------------------------------------------
-- Gold
---------------------------------------------------------------------------
-- Syndicator's public API (Syndicator.API), read only: nothing of it is
-- changed, copied or kept; every value is the one it last saw
function Info.Syndicator()
	local S = _G.Syndicator
	local api = type(S) == 'table' and type(S.API) == 'table' and S.API or nil
	if not api then return nil end
	local ok, ready = pcall(api.IsReady or error)
	if not ok or not ready then return nil end
	return api
end

function Info.Gold()
	local out = { here = Safe(GetMoney and GetMoney()), others = {}, othersTotal = 0, source = nil }
	local api = Info.Syndicator()
	if api then
		out.source = 'Syndicator'
		local okCurrent, current = pcall(api.GetCurrentCharacter or error)
		local ok, names = pcall(api.GetAllCharacters or error)
		if ok and type(names) == 'table' then
			for _, full in ipairs(names) do
				if not (okCurrent and full == current) then
					local okChar, c = pcall(api.GetByCharacterFullName, full)
					local d = okChar and type(c) == 'table' and c.details
					local money = okChar and type(c) == 'table' and tonumber(c.money)
					local hidden = type(d) == 'table' and type(d.show) == 'table' and d.show.gold == false
					if money and not hidden then
						out.others[#out.others + 1] = { name = (type(d) == 'table' and d.character) or full, realm = type(d) == 'table' and d.realm or nil,
							class = type(d) == 'table' and d.className or nil, money = money }
						out.othersTotal = out.othersTotal + money
					end
				end
			end
		end
		local okWarband, warband = pcall(api.GetWarband or error, 1)
		if okWarband and type(warband) == 'table' and tonumber(warband.money) then out.warband, out.warbandSource = tonumber(warband.money), 'Syndicator, last seen' end
	end
	-- the game's own Warband bank value when it gives one (preferred)
	if C_Bank and C_Bank.FetchDepositedMoney and Enum and Enum.BankType and Enum.BankType.Account then
		local live = Call(C_Bank.FetchDepositedMoney, Enum.BankType.Account)
		if type(live) == 'number' then out.warband, out.warbandSource = live, 'the game' end
	end
	table.sort(out.others, function(a, b) return a.money > b.money end)
	out.known = (out.here or 0) + out.othersTotal + (out.warband or 0)
	return out
end

function TIPS.gold(tt)
	local g = Info.Gold()
	Title(tt, 'GOLD', { 1.00, 0.82, 0.25 })
	local name = Call(UnitName, 'player') or 'This character'
	local _, token = Call(UnitClass, 'player')
	if g.here then Pair(tt, Colored(name, ClassColor(token)) .. '  (this character)', Info.Money(g.here)) else Unavailable(tt, 'This character') end
	local start = Info.sessionStart
	if g.here and start then
		local delta = g.here - start
		Pair(tt, 'This session', (delta > 0 and '+' or '') .. Info.Money(delta), (delta > 0 and C.good) or C.label)
	end
	if g.warband then Pair(tt, 'Warband bank  (' .. g.warbandSource .. ')', Info.Money(g.warband)) end
	if g.source then
		if #g.others > 0 then
			Space(tt)
			Title(tt, 'OTHER CHARACTERS  (Syndicator, last seen)', C.label)
			for i = 1, math.min(#g.others, Info.CAP) do
				local o = g.others[i]
				Pair(tt, Colored(o.name, ClassColor(o.class)) .. (o.realm and ('  ' .. o.realm) or ''), Info.Money(o.money))
			end
			if #g.others > Info.CAP then
				local rest = 0
				for i = Info.CAP + 1, #g.others do rest = rest + g.others[i].money end
				Pair(tt, string.format('+%d more', #g.others - Info.CAP), Info.Money(rest), C.muted)
			end
		else
			Note(tt, 'Syndicator has not seen your other characters yet.')
		end
	else
		Space(tt)
		Note(tt, 'Other characters: shown when Syndicator is installed and enabled (Banzai only reads it).')
	end
	Space(tt)
	Pair(tt, 'Total KNOWN', Info.Money(g.known), { 1.00, 0.82, 0.25 })
	Note(tt, 'KNOWN: only this character and what Syndicator has seen - characters it never saw (and guild banks) are not in it.')
	Hint(tt, 'Click: open your bags')
end

---------------------------------------------------------------------------
-- Hover and click
---------------------------------------------------------------------------
-- each entry's window: the game's own toggle function; bags also in combat
Info.CLICKS = {
	honor = { name = 'The PvP window', fn = 'TogglePVPUI' },
	conquest = { name = 'The PvP window', fn = 'TogglePVPUI' },
	mastery = { name = 'The character window', fn = 'ToggleCharacter', arg = 'PaperDollFrame' },
	haste = { name = 'The character window', fn = 'ToggleCharacter', arg = 'PaperDollFrame' },
	versatility = { name = 'The character window', fn = 'ToggleCharacter', arg = 'PaperDollFrame' },
	durability = { name = 'The character window', fn = 'ToggleCharacter', arg = 'PaperDollFrame' },
	ilvl = { name = 'The character window', fn = 'ToggleCharacter', arg = 'PaperDollFrame' },
	time = { name = 'The calendar', fn = 'ToggleCalendar' },
	spec = { name = 'The specialization window', spec = true },
	professions = { name = 'Your professions', fn = 'ToggleProfessionsBook' },
	friends = { name = 'The friends list', fn = 'ToggleFriendsFrame', arg = 1 },
	guild = { name = 'The guild window', fn = 'ToggleGuildFrame' },
	gold = { name = 'Your bags', fn = 'ToggleAllBags', combat = true },
}

function Info:Click(key)
	local click = self.CLICKS[key]
	if not click then return false end
	if InCombatLockdown() and not click.combat then
		print('|cff00ccffBanzai|r: ' .. click.name .. ' cannot open in combat.')
		return false
	end
	if click.spec then
		local util = _G.PlayerSpellsUtil
		local tabs = util and util.FrameTabs
		if util and util.TogglePlayerSpellsFrame and tabs and tabs.ClassSpecializations then
			return (pcall(util.TogglePlayerSpellsFrame, tabs.ClassSpecializations))
		end
		if util and util.ToggleClassTalentOrSpecFrame then return (pcall(util.ToggleClassTalentOrSpecFrame)) end
		return false
	end
	local fn = _G[click.fn]
	if type(fn) ~= 'function' then return false end
	if click.arg ~= nil then return (pcall(fn, click.arg)) end
	return (pcall(fn))
end

function Info:Allowed()
	local db = Theme:DB()
	if not db.panelTips then return false end
	if InCombatLockdown() and not db.panelTipsCombat then return false end
	return true
end

function Info:Show(button)
	local key = button and button.def and button.def.key
	local build = key and TIPS[key]
	local tip = ns.Tooltip
	if not (build and tip and self:Allowed()) then return false end
	local tt = tip:Begin(button, (Theme:DB().panelTipAnchor == 'CURSOR') and 'CURSOR' or 'TOP')
	if not tt then return false end
	local ok, err = pcall(build, tt)
	if not ok then
		tt:AddLine('Not available right now.', C.muted[1], C.muted[2], C.muted[3])
		if ns.Compat then ns.Compat.lastError = ns.Compat.lastError or tostring(err) end
	end
	tip:Finish(tt)
	self.button = button
	return true
end

function Info:Hide(button)
	if ns.Tooltip then ns.Tooltip:End(button) end
	if self.button == button then self.button = nil end
end

-- once a second (Bar.lua's ticker) while an entry stays hovered: FPS, MS and TIME move
Info.LIVE = { fps = true, ms = true, time = true }
function Info:Tick()
	local button = self.button
	if not (button and button.def and self.LIVE[button.def.key]) then return end
	if not (ns.Tooltip and ns.Tooltip:Owns(button)) then self.button = nil return end
	if not self:Allowed() then return self:Hide(button) end
	self:Show(button)
end

-- the session's starting money (login or reload)
local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_ENTERING_WORLD')
events:RegisterEvent('PLAYER_REGEN_DISABLED')
events:SetScript('OnEvent', function(_, event)
	if event == 'PLAYER_ENTERING_WORLD' then
		if Info.sessionStart == nil then Info.sessionStart = Safe(GetMoney and GetMoney()) end
	elseif event == 'PLAYER_REGEN_DISABLED' then
		-- a panel tooltip goes away when combat starts (unless allowed there); the lockdown
		-- itself only begins after this event, so the setting decides, not InCombatLockdown
		if Info.button and not Theme:DB().panelTipsCombat then Info:Hide(Info.button) end
	end
end)
