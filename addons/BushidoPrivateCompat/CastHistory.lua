--[[
	BANZAI - CastHistory.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	A small list of the spells the player has just cast or is casting, centred
	between Player and Target, below their frames and the player cast bar,
	above the action bars. A tiny CAST HISTORY heading with a thin Banzai
	gradient line on each side; newest entry on top and brightest, older
	entries fade; only the last few are kept (bounded, at most 6 shown).

	Source: the player's own UNIT_SPELLCAST_* events (START / CHANNEL_START /
	SUCCEEDED / INTERRUPTED / FAILED / STOP) with the spell ID they carry, and
	C_Spell for its name and icon. Nothing is inferred, nothing is automated,
	no combat log. 0.5.0: in 12.x the spell ID / cast ID can arrive as a hidden
	(secret) value; such a completed cast is still listed, its name and icon
	passed straight to the text / texture without being read or compared (the
	0.4.0 list stayed empty because those casts were skipped). If the client
	will not resolve a hidden ID, nothing is listed; no entry is made up.
]]
local _, ns = ...
local Theme = ns.Theme

local CastHistory = {}
ns.CastHistory = CastHistory

CastHistory.MAX = 8          -- kept
CastHistory.SHOWN_MAX = 6    -- shown at most (option range 1 - 6)
CastHistory.TOP = 250        -- top edge above the screen bottom: under the player cast bar (253), above the action bars (top 104)
CastHistory.ROW = 21
CastHistory.HEADER = 14
CastHistory.WIDTH = 200
CastHistory.LINE = 72        -- length of each side line
local FADE = { 1, 0.78, 0.6, 0.45, 0.35, 0.28, 0.22, 0.18 }
local MUTED = { 0.60, 0.63, 0.68 }

local entries = {}           -- newest first: { id, name, icon, state, guid, hidden }

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Safe(value)
	if value == nil or IsSecret(value) then return nil end
	return value
end

local function SpellData(spellID)
	spellID = Safe(spellID)
	if type(spellID) ~= 'number' then return nil end
	local name, icon
	if C_Spell and C_Spell.GetSpellInfo then
		local info = C_Spell.GetSpellInfo(spellID)
		if info then name, icon = Safe(info.name), Safe(info.iconID) end
	end
	if not name and C_Spell and C_Spell.GetSpellName then name = Safe(C_Spell.GetSpellName(spellID)) end
	if not icon and C_Spell and C_Spell.GetSpellTexture then icon = Safe(C_Spell.GetSpellTexture(spellID)) end
	if type(name) ~= 'string' or name == '' or not icon then return nil end
	return spellID, name, icon
end

local function Find(guid)
	guid = Safe(guid)
	if not guid then return nil end
	for _, e in ipairs(entries) do
		if not e.hidden and e.guid == guid then return e end
	end
end

local function Add(entry)
	table.insert(entries, 1, entry)
	while #entries > CastHistory.MAX do table.remove(entries) end
	CastHistory:Update()
	return entry
end

function CastHistory:Push(spellID, guid, state)
	local id, name, icon = SpellData(spellID)
	if not id then return nil end
	local existing = Find(guid)
	if existing then
		existing.state = state
		self:Update()
		return existing
	end
	return Add({ id = id, name = name, icon = icon, state = state, guid = Safe(guid) })
end

-- A completed cast whose spell ID is hidden: name and icon resolved by the
-- client and handed on unread. Any error (the client refusing the hidden ID)
-- means the cast is simply not listed.
function CastHistory:PushHidden(spellID)
	if not (C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellTexture) then return nil end
	local ok, entry = pcall(function()
		local name, icon = C_Spell.GetSpellName(spellID), C_Spell.GetSpellTexture(spellID)
		if name == nil or icon == nil then return nil end
		return { name = name, icon = icon, state = 'done', hidden = true }
	end)
	if ok and entry then return Add(entry) end
	return nil
end

function CastHistory:Mark(guid, state)
	local e = Find(guid)
	if e then
		e.state = state
		self:Update()
	end
end

function CastHistory:Entries() return entries end

function CastHistory:OnEvent(event, unit, guid, spellID)
	-- the events are registered for the player only; in 12.x the unit argument
	-- itself can arrive hidden, and comparing a hidden value is an error (0.4.0)
	if not IsSecret(unit) and unit ~= 'player' then return end
	self.seen = (self.seen or 0) + 1
	if IsSecret(spellID) or IsSecret(guid) then
		-- hidden values: completed casts only (no matching of casts is possible)
		if event == 'UNIT_SPELLCAST_SUCCEEDED' or event == 'UNIT_SPELLCAST_CHANNEL_START' then
			self.hiddenSeen = (self.hiddenSeen or 0) + 1
			self:PushHidden(spellID)
		end
		return
	end
	if event == 'UNIT_SPELLCAST_START' or event == 'UNIT_SPELLCAST_CHANNEL_START' then
		self:Push(spellID, guid, 'casting')
	elseif event == 'UNIT_SPELLCAST_SUCCEEDED' then
		local e = Find(guid)
		if e then
			if e.state == 'casting' then e.state = 'done' end
			self:Update()
		else
			self:Push(spellID, guid, 'done')
		end
	elseif event == 'UNIT_SPELLCAST_INTERRUPTED' or event == 'UNIT_SPELLCAST_FAILED' then
		self:Mark(guid, 'failed') -- only casts already listed; failed attempts are not added
	elseif event == 'UNIT_SPELLCAST_CHANNEL_STOP' or event == 'UNIT_SPELLCAST_STOP' then
		local e = Find(guid)
		if e and e.state == 'casting' then self:Mark(guid, 'done') end
	end
end

function CastHistory:Build()
	if self.frame then return self.frame end
	local f = CreateFrame('Frame', 'BanzaiCastHistory', UIParent)
	f:SetFrameStrata('LOW')
	f:SetSize(self.WIDTH, self.HEADER + self.ROW * self.SHOWN_MAX)
	f:SetPoint('TOP', UIParent, 'BOTTOM', 0, self.TOP)
	f:EnableMouse(false)
	-- heading with a thin gradient line on each side:  ----  CAST HISTORY  ----
	f.header = f:CreateFontString(nil, 'OVERLAY')
	f.header:SetPoint('TOP', f, 'TOP', 0, -1)
	f.lines = {}
	for i, side in ipairs({ 'LEFT', 'RIGHT' }) do
		local line = f:CreateTexture(nil, 'ARTWORK')
		line:SetTexture(Theme.WHITE)
		line:SetSize(self.LINE, 1)
		if side == 'LEFT' then
			line:SetPoint('RIGHT', f.header, 'LEFT', -8, 0)
		else
			line:SetPoint('LEFT', f.header, 'RIGHT', 8, 0)
		end
		f.lines[i] = line
	end
	f.rows = {}
	for i = 1, self.SHOWN_MAX do
		local row = CreateFrame('Frame', nil, f)
		row:SetSize(self.WIDTH, self.ROW)
		row:SetPoint('TOP', f, 'TOP', 0, -self.HEADER - (i - 1) * self.ROW)
		row.icon = row:CreateTexture(nil, 'ARTWORK')
		row.icon:SetSize(self.ROW - 4, self.ROW - 4)
		row.icon:SetPoint('LEFT', row, 'LEFT', 24, 0)
		row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		row.text = row:CreateFontString(nil, 'OVERLAY')
		row.text:SetPoint('LEFT', row.icon, 'RIGHT', 6, 0)
		row.text:SetJustifyH('LEFT')
		row.state = row:CreateFontString(nil, 'OVERLAY')
		row.state:SetPoint('LEFT', row.text, 'RIGHT', 4, 0)
		f.rows[i] = row
	end
	local events = { 'UNIT_SPELLCAST_START', 'UNIT_SPELLCAST_CHANNEL_START', 'UNIT_SPELLCAST_SUCCEEDED', 'UNIT_SPELLCAST_INTERRUPTED',
		'UNIT_SPELLCAST_FAILED', 'UNIT_SPELLCAST_STOP', 'UNIT_SPELLCAST_CHANNEL_STOP' }
	for _, event in ipairs(events) do
		if f.RegisterUnitEvent then pcall(f.RegisterUnitEvent, f, event, 'player') else pcall(f.RegisterEvent, f, event) end
	end
	f:SetScript('OnEvent', function(_, event, ...) CastHistory:OnEvent(event, ...) end)
	self.frame = f
	return f
end

function CastHistory:Paint()
	local f = self.frame
	if not f then return end
	local stops = Theme:Stops('h')
	local left, right = Theme:ColorAt(stops, 0), Theme:ColorAt(stops, 1)
	-- subtle: transparent at the outer end, soft colour next to the heading
	Theme:Gradient(f.lines[1], 'HORIZONTAL', left, left, 0, 0.7)
	Theme:Gradient(f.lines[2], 'HORIZONTAL', right, right, 0.7, 0)
	f.header:SetFont(Theme:SmallFont(), 9, 'OUTLINE')
	f.header:SetText('CAST HISTORY')
	f.header:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
end

function CastHistory:Update()
	local f = self.frame
	if not (f and f:IsShown()) then return end
	local db = Theme:DB()
	local count = math.max(1, math.min(self.SHOWN_MAX, db.castEntries or 4))
	local font = Theme:SmallFont()
	local accent = Theme:Accents()
	local shown = 0
	for i, row in ipairs(f.rows) do
		local e = entries[i]
		if e and i <= count then
			shown = shown + 1
			row.icon:SetTexture(e.icon)
			row.text:SetFont(font, i == 1 and 12 or 11, 'OUTLINE')
			row.state:SetFont(font, 10, 'OUTLINE')
			local color = (e.state == 'casting' and accent) or (e.state == 'failed' and { 0.95, 0.35, 0.35 }) or { 1, 1, 1 }
			row.text:SetText(e.name)
			row.text:SetTextColor(color[1], color[2], color[3])
			row.state:SetText(e.state == 'casting' and '...' or '')
			row.state:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
			row:SetAlpha((FADE[i] or 0.2) * (db.castOpacity or 0.9))
			row.icon:SetDesaturated(e.state == 'failed')
			row:Show()
		else
			row:Hide()
		end
	end
	-- heading and lines only with something to show
	f.header:SetShown(shown > 0)
	for _, line in ipairs(f.lines) do line:SetShown(shown > 0) end
end

function CastHistory:Refresh()
	local db = Theme:DB()
	local active = ns.Compat and ns.Compat.Active and ns.Compat.Active()
	local show = active and db.castHistory and true or false
	if show and not self.frame then self:Build() end
	if not self.frame then return end
	self.frame:SetScale(db.castScale or 1)
	self.frame:SetShown(show)
	if show then
		self:Paint()
		self:Update()
	end
end
