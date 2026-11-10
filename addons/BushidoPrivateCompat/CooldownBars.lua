--[[
	BANZAI - CooldownBars.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	0.9.0: two compact bar groups for the PLAYER'S OWN major cooldowns:
	OFFENSIVE between the chat frame and the action bars (lower left of the
	centre), DEFENSIVE between the action bars and the Details frame (lower
	right of the centre). Each bar: spell icon, name, a Banzai gradient bar that
	runs down with the cooldown, the remaining seconds. A bar is there only
	while its spell is cooling down; an empty group is not drawn at all. At
	most BANZAI > PVP's count (1 .. 5) per group, newest data on every update,
	nothing kept as history.

	Data (the player's own spells only; nothing about anyone else, no combat
	log, no auras):
	  known       C_SpellBook.IsSpellKnown / IsPlayerSpell: the first known
	              spell of each entry in CooldownBars.SPELLS (talent variants
	              of one cooldown are one entry)
	  shown       C_Spell.GetSpellCooldown(spell).isActive and not .isOnGCD:
	              the cooldown state the game keeps readable in Midnight; when
	              even that is secret the bar is not shown
	  bar / time  C_Spell.GetSpellCooldownDuration(spell): a duration object
	              the game hands to the bar (StatusBar:SetTimerDuration) and the
	              time text; Banzai never computes with it
	Which spells: CooldownBars.SPELLS per class, in priority order; Banzai
	tracks the first `count` known ones, BANZAI > PVP changes the selection
	(cdTracked, per class, synced). The preview shows labelled SAMPLE bars.
]]
local _, ns = ...
local Theme = ns.Theme

local CB = {}
ns.CooldownBars = CB
if ns.Compat then ns.Compat.CooldownBars = CB end -- the options page reaches it through BanzaiCompat

CB.MAX = 5
CB.BAR = { w = 178, h = 14, gap = 3, icon = 14 }
CB.KINDS = { 'offensive', 'defensive' }
CB.GROUPS = {
	offensive = { side = -1, title = 'OFFENSIVE', countKey = 'cdOffensiveCount', from = { 0.62, 1.00, 0.12 }, to = { 1.00, 0.48, 0.10 } },
	defensive = { side = 1, title = 'DEFENSIVE', countKey = 'cdDefensiveCount', from = { 0.15, 0.85, 1.00 }, to = { 0.56, 0.22, 1.00 } },
}
-- major cooldowns per class, priority order; { a, b } = one cooldown in its talent variants (first known wins)
CB.SPELLS = {
	DRUID = {
		offensive = { { 102560, 194223 }, { 391528 }, { 205636 }, { 202770 }, { 102543, 106951 }, { 5217 }, { 274837 }, { 102558, 50334 }, { 33891 }, { 740 }, { 132158 } },
		defensive = { { 22812 }, { 61336 }, { 22842 }, { 108238 }, { 102342 }, { 124974 } },
	},
	WARRIOR = {
		offensive = { { 107574 }, { 1719 }, { 227847 }, { 262161, 167105 }, { 384318 }, { 376079 }, { 228920 } },
		defensive = { { 118038 }, { 184364 }, { 871 }, { 12975 }, { 97462 }, { 23920 } },
	},
	PALADIN = {
		offensive = { { 231895, 216331, 389539, 31884 }, { 343721 }, { 343527 }, { 375576 }, { 31821 } },
		defensive = { { 642 }, { 498, 403876 }, { 184662 }, { 31850 }, { 86659, 212641 }, { 633 }, { 1022 }, { 6940 } },
	},
	HUNTER = {
		offensive = { { 19574 }, { 359844 }, { 288613 }, { 360952, 266779 }, { 321530 }, { 360966 } },
		defensive = { { 186265 }, { 109304 }, { 264735 }, { 388035, 272679 }, { 53480 } },
	},
	ROGUE = {
		offensive = { { 121471 }, { 185313 }, { 212283 }, { 13750 }, { 360194 }, { 385627 }, { 51690 } },
		defensive = { { 31224 }, { 5277 }, { 1966 }, { 185311 }, { 1856 } },
	},
	PRIEST = {
		offensive = { { 10060 }, { 391109, 228260 }, { 200174, 123040, 34433 }, { 200183 }, { 246287 }, { 47536 }, { 64843 } },
		defensive = { { 47585 }, { 19236 }, { 33206 }, { 47788 }, { 62618 }, { 15286 }, { 586 } },
	},
	MAGE = {
		offensive = { { 190319 }, { 12472 }, { 365350 }, { 321507 }, { 84714 }, { 382440 }, { 205021 } },
		defensive = { { 414658, 45438 }, { 110959 }, { 342245, 108978 }, { 55342 }, { 414660 } },
	},
	WARLOCK = {
		offensive = { { 1122 }, { 205180 }, { 265187 }, { 386997 }, { 111898 } },
		defensive = { { 104773 }, { 108416 }, { 212295 } },
	},
	SHAMAN = {
		offensive = { { 114050, 114051, 114052 }, { 191634 }, { 51533 }, { 384352 }, { 198067, 192249 }, { 375982 }, { 108280 } },
		defensive = { { 108271 }, { 98008 }, { 198103 }, { 409293 }, { 108270 }, { 207399 } },
	},
	MONK = {
		offensive = { { 123904 }, { 137639 }, { 322118, 325197 }, { 115310 }, { 116680 }, { 132578 } },
		defensive = { { 122470 }, { 115203 }, { 122783 }, { 122278 }, { 116849 }, { 115176 } },
	},
	DEATHKNIGHT = {
		offensive = { { 51271 }, { 47568 }, { 63560 }, { 275699 }, { 42650 }, { 207289 }, { 383269 }, { 49028 }, { 152279 }, { 49206 } },
		defensive = { { 48792 }, { 48707 }, { 51052 }, { 49039 }, { 48743 }, { 55233 } },
	},
	DEMONHUNTER = {
		offensive = { { 191427, 187827 }, { 370965 }, { 258860 }, { 198013 }, { 212084 } },
		defensive = { { 198589 }, { 196555 }, { 196718 }, { 204021 } },
	},
	EVOKER = {
		offensive = { { 375087 }, { 357210, 433874 }, { 370553 }, { 403631 }, { 395152 }, { 363534 }, { 359816 }, { 370960 } },
		defensive = { { 363916 }, { 374348 }, { 357170 }, { 374227 } },
	},
}
-- the preview: SAMPLE bars (icons and names only, nothing read from the game)
CB.SAMPLE = {
	offensive = { { 'Celestial Alignment', 'Spell_Nature_Natureguardian', 0.72, '92' }, { 'Convoke the Spirits', 'Ability_Ardenweald_Druid', 0.40, '48' }, { 'Force of Nature', 'Ability_Druid_ForceofNature', 0.15, '9' } },
	defensive = { { 'Barkskin', 'Spell_Nature_StoneClawTotem', 0.55, '33' }, { 'Renewal', 'Spell_Nature_NatureBlessing', 0.30, '27' } },
}

local groups = {}

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Plain(value)
	if IsSecret(value) then return nil end
	return value
end

local function Active()
	return ns.Compat and ns.Compat.Active and ns.Compat.Active() or false
end

local function Call(fn, ...)
	if not fn then return nil end
	local ok, value = pcall(fn, ...)
	if ok then return Plain(value) end
	return nil
end

function CB.Known(spellID)
	if C_SpellBook and Call(C_SpellBook.IsSpellKnown, spellID) == true then return true end
	if Call(IsPlayerSpell, spellID) == true then return true end
	return Call(IsSpellKnown, spellID) == true
end

function CB.Class()
	local _, token = UnitClass('player')
	return Plain(token)
end

-- the known spells of a group for this character, priority order
function CB:Candidates(kind)
	local list = {}
	local class = CB.Class()
	for _, entry in ipairs((CB.SPELLS[class] or {})[kind] or {}) do
		for _, id in ipairs(entry) do
			if CB.Known(id) then
				list[#list + 1] = id
				break
			end
		end
	end
	return list
end

local function Count(kind)
	local value = tonumber(Theme:DB()[CB.GROUPS[kind].countKey]) or CB.MAX
	return math.max(1, math.min(CB.MAX, math.floor(value)))
end
CB.Count = Count

-- the selection (BANZAI > PVP): saved choices per class, else the first `count` candidates
function CB:IsTracked(kind, spellID, index)
	local choices = Theme:DB().cdTracked
	local class = CB.Class()
	local own
	if type(choices) == 'table' and type(choices[class]) == 'table' then own = choices[class][spellID] end
	if own ~= nil then return own and true or false end
	return (index or 1) <= Count(kind)
end

function CB:SetTracked(spellID, on)
	local db = Theme:DB()
	if type(db.cdTracked) ~= 'table' then db.cdTracked = {} end
	local class = CB.Class() or 'UNKNOWN'
	db.cdTracked[class] = db.cdTracked[class] or {}
	db.cdTracked[class][spellID] = on and true or false
	self:Refresh()
end

function CB:Tracked(kind)
	local out = {}
	for i, id in ipairs(self:Candidates(kind)) do
		if self:IsTracked(kind, id, i) then out[#out + 1] = id end
	end
	return out
end

-- cooling down now (the readable state); nil when the game keeps it secret
function CB.OnCooldown(spellID)
	if not (C_Spell and C_Spell.GetSpellCooldown) then return nil end
	local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
	if not ok or type(info) ~= 'table' then return nil end
	local active, gcd = Plain(info.isActive), Plain(info.isOnGCD)
	if active == nil then return nil end
	return active == true and gcd ~= true
end

---------------------------------------------------------------------------
-- Frames
---------------------------------------------------------------------------
local function Bar(group, index)
	local B = CB.BAR
	local bar = CreateFrame('Frame', nil, group)
	bar:SetSize(B.w, B.h)
	bar:SetPoint('BOTTOMLEFT', group, 'BOTTOMLEFT', 0, (index - 1) * (B.h + B.gap))
	bar.icon = bar:CreateTexture(nil, 'ARTWORK')
	bar.icon:SetSize(B.icon, B.icon)
	bar.icon:SetPoint('LEFT', bar, 'LEFT', 0, 0)
	bar.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	bar.track = bar:CreateTexture(nil, 'BACKGROUND')
	bar.track:SetPoint('TOPLEFT', bar, 'TOPLEFT', B.icon + 1, 0)
	bar.track:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 0, 0)
	Theme:Trough(bar.track)
	bar.status = CreateFrame('StatusBar', nil, bar)
	bar.status:SetPoint('TOPLEFT', bar, 'TOPLEFT', B.icon + 1, 0)
	bar.status:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 0, 0)
	bar.status:SetStatusBarTexture(Theme.MEDIA .. 'BanzaiBar')
	bar.status:SetMinMaxValues(0, 1)
	bar.status:SetValue(1)
	local text = CreateFrame('Frame', nil, bar)
	text:SetAllPoints(bar)
	text:SetFrameLevel(bar.status:GetFrameLevel() + 2)
	bar.name = text:CreateFontString(nil, 'OVERLAY')
	bar.name:SetFont(Theme:SmallFont(), 9, 'OUTLINE')
	bar.name:SetPoint('LEFT', bar.status, 'LEFT', 3, 0)
	bar.name:SetJustifyH('LEFT')
	bar.time = text:CreateFontString(nil, 'OVERLAY')
	bar.time:SetFont(Theme:SmallFont(), 9, 'OUTLINE')
	bar.time:SetPoint('RIGHT', bar.status, 'RIGHT', -3, 0)
	bar.name:SetPoint('RIGHT', bar.time, 'LEFT', -3, 0)
	if bar.CreateAnimationGroup then -- short, quiet fade in
		bar.fade = bar:CreateAnimationGroup()
		local a = bar.fade:CreateAnimation('Alpha')
		a:SetFromAlpha(0)
		a:SetToAlpha(1)
		a:SetDuration(0.15)
	end
	bar:Hide()
	return bar
end

local function Paint(group)
	local def = CB.GROUPS[group.kind]
	for _, bar in ipairs(group.bars) do
		local fill = bar.status:GetStatusBarTexture()
		if fill then Theme:Gradient(fill, 'HORIZONTAL', def.from, def.to, 1, 1) end
	end
end

function CB:Group(kind)
	if groups[kind] then return groups[kind] end
	local B = CB.BAR
	local g = CreateFrame('Frame', 'BanzaiCooldownBars_' .. kind, UIParent)
	g:SetSize(B.w, CB.MAX * (B.h + B.gap) - B.gap)
	g:SetFrameStrata('MEDIUM')
	g:EnableMouse(false)
	g.kind = kind
	g.bars = {}
	for i = 1, CB.MAX do g.bars[i] = Bar(g, i) end
	g.title = g:CreateFontString(nil, 'OVERLAY')
	g.title:SetFont(Theme:SmallFont(), 9, 'OUTLINE')
	g.title:SetPoint('BOTTOMLEFT', g, 'TOPLEFT', 0, 3)
	g.title:Hide()
	Paint(g)
	g:Hide()
	groups[kind] = g
	return g
end

-- 1.0.0: never over wider circular action bars (BANZAI > ACTION BARS size / spacing)
function CB.Spread(db, scale)
	local spread = tonumber(db.cdSpread) or 335
	if db.actionStyle == 'ELVUI' then return spread end
	local half = (12 * (tonumber(db.abSize) or 30) + 11 * (tonumber(db.abSpacing) or 6)) / 2
	return math.max(spread, half + CB.BAR.w * (scale or 1) / 2 + 6)
end

function CB:Place(g)
	local db = Theme:DB()
	local scale = math.max(0.7, math.min(1.2, tonumber(db.cdScale) or 1))
	g:SetScale(scale)
	g:SetAlpha(math.max(0.4, math.min(1, tonumber(db.cdOpacity) or 1)))
	g:ClearAllPoints()
	-- the group's centre `cdSpread` units left / right of the screen centre (scale-independent)
	g:SetPoint('BOTTOM', UIParent, 'BOTTOM', CB.GROUPS[g.kind].side * CB.Spread(db, scale) / scale, (tonumber(db.cdHeight) or 54) / scale)
end

local function SetDuration(bar, spellID)
	local duration = C_Spell and C_Spell.GetSpellCooldownDuration and select(2, pcall(C_Spell.GetSpellCooldownDuration, spellID))
	local kind = type(duration)
	bar.duration = (kind == 'table' or kind == 'userdata') and duration or nil
	if bar.duration and bar.status.SetTimerDuration and Enum and Enum.StatusBarTimerDirection then
		bar.status:SetTimerDuration(bar.duration, Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate or 0, Enum.StatusBarTimerDirection.RemainingTime)
	else
		bar.status:SetValue(1)
	end
end

-- the remaining seconds, as the game reports them: in combat they can be a
-- secret value, so the font string formats them (no Lua comparison or string
-- work on it), never computed
local function UpdateTime(bar)
	local d = bar.duration
	if d and d.GetRemainingDuration then
		local ok, remaining = pcall(d.GetRemainingDuration, d)
		if ok and (IsSecret(remaining) or type(remaining) == 'number') then
			bar.time:SetFormattedText('%.0f', remaining)
			return
		end
	end
	bar.time:SetText('')
end
CB.UpdateTime = UpdateTime

function CB:UpdateGroup(kind)
	local g = self:Group(kind)
	self:Place(g)
	g.title:Hide()
	if self.preview then return self:ShowSample(g) end
	local shown = 0
	if Active() and Theme:DB().cdBars ~= false then
		local limit = Count(kind)
		for _, id in ipairs(self:Tracked(kind)) do
			if shown >= limit then break end
			if CB.OnCooldown(id) then
				shown = shown + 1
				local bar = g.bars[shown]
				local fresh = not bar:IsShown() or bar.spellID ~= id
				bar.spellID = id
				bar.icon:SetTexture(C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id))
				bar.name:SetText(C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) or '')
				SetDuration(bar, id)
				UpdateTime(bar)
				bar:SetAlpha(1) -- (the preview dims its sample bars)
				bar:Show()
				if fresh and bar.fade then bar.fade:Play() end
			end
		end
	end
	for i = shown + 1, CB.MAX do
		g.bars[i].spellID, g.bars[i].duration = nil, nil
		g.bars[i]:Hide()
	end
	g:SetShown(shown > 0)
	g.count = shown
	return shown
end

-- preview: labelled SAMPLE bars (BANZAI > PVP > PREVIEW, unit-frame preview states)
function CB:ShowSample(g)
	local samples = CB.SAMPLE[g.kind]
	local state = ns.Preview and ns.Preview.State and ns.Preview:State()
	local active = (g.kind == 'offensive' and state == 'OFFENSIVE') or (g.kind == 'defensive' and state == 'DEFENSIVE')
	for i, bar in ipairs(g.bars) do
		local s = samples[i]
		if s and i <= Count(g.kind) then
			bar.spellID, bar.duration = nil, nil
			bar.icon:SetTexture('Interface\\Icons\\' .. s[2])
			bar.name:SetText(s[1])
			bar.status:SetValue(s[3])
			bar.time:SetText(s[4])
			bar:SetAlpha((active or i == 1) and 1 or 0.8)
			bar:Show()
		else
			bar:Hide()
		end
	end
	g.title:SetText(Theme:GradientText(CB.GROUPS[g.kind].title .. ' COOLDOWNS', CB.GROUPS[g.kind].from, CB.GROUPS[g.kind].to)
		.. '|cff8c919a  -  ' .. (active and 'ACTIVE  -  ' or '') .. 'SAMPLE DATA|r')
	g.title:Show()
	g:Show()
	return #samples
end

function CB:SetPreview(on)
	self.preview = (on and not InCombatLockdown()) and true or nil
	self:Refresh()
	return self.preview == true
end

function CB:IsPreview() return self.preview == true end

function CB:Refresh()
	for _, kind in ipairs(CB.KINDS) do self:UpdateGroup(kind) end
end

function CB:Get(kind) return groups[kind] end

local ticker = CreateFrame('Frame')
local elapsed = 0
ticker:SetScript('OnUpdate', function(_, dt)
	elapsed = elapsed + (dt or 0)
	if elapsed < 0.25 then return end
	elapsed = 0
	if CB.preview then return end
	for _, g in pairs(groups) do
		if g:IsShown() then
			for _, bar in ipairs(g.bars) do
				if bar:IsShown() then UpdateTime(bar) end
			end
		end
	end
end)

local events = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'SPELL_UPDATE_COOLDOWN', 'SPELL_UPDATE_CHARGES', 'SPELLS_CHANGED', 'PLAYER_SPECIALIZATION_CHANGED',
	'PLAYER_TALENT_UPDATE', 'TRAIT_CONFIG_UPDATED', 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED' }) do
	pcall(events.RegisterEvent, events, event)
end
events:SetScript('OnEvent', function(_, event)
	if event == 'PLAYER_REGEN_DISABLED' and CB.preview then CB.preview = nil end -- the preview never stays in combat
	if CB.scheduled then return end
	CB.scheduled = true
	C_Timer.After(0.05, function()
		CB.scheduled = false
		CB:Refresh()
	end)
end)
