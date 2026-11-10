--[[
	BANZAI - Preview.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	Unit-frame preview: a VISUAL TEST MODE so Player, Target, Target of Target,
	Focus, Pet, Party, Raid, Arena allies / enemies and Boss can be looked at
	without a group, an arena or a boss (BANZAI > LAYOUT > UNIT FRAME PREVIEW,
	BANZAI > PVP > PREVIEW).

	Each preview is a plain, non-interactive frame (no secure templates, no
	unit, nothing clickable) drawn with the current Banzai styling: the smooth
	Banzai health texture over a dark trough, the Bushido plates, the identity
	line (NAME - SPEC / SPEC - NAME), health number + percentage inside the bar
	(bright over the fill, ghosted over the empty part) and a resource bar.
	Sizes come from the real frames where they exist (Player, Target, ...),
	otherwise from the ElvUI profile (width, height, growth, spacing) and the
	ElvUI mover positions of the layout shown (DPS / HEALER, Roles.lua).

	Everything shown is SAMPLE DATA and says so: PLAYER PREVIEW, PARTY 1, ENEMY 2,
	sample classes / specs / numbers / spells, and every group title reads
	"PREVIEW: <state> - SAMPLE DATA". The only real data is the player's own
	class and specialization on PLAYER PREVIEW. A state shown here proves a
	design, never that the live game exposes the data. Previews never show in
	combat and are hidden when combat starts.

	0.7.0: bamboo only on PLAYER / TARGET PREVIEW; small identity circles on
	Focus, Party, Arena allies / enemies; HEALER party / arena allies in one
	central row.

	0.8.0 (unit frames + PvP):
	  layering   names / spec text sit on their own text layer above the health
	             fill, the empty track, the gradients and the inside health text
	  states     a preview-state selector (Preview.STATES): NORMAL, LOW HEALTH,
	             OUT OF RANGE, DEAD, CASTING, NON-INTERRUPTIBLE CAST, CC'D,
	             DISPELLABLE, BURST / OFFENSIVE, DEFENSIVE, TRINKET AVAILABLE,
	             TRINKET USED, DR STATE; target / focus markers always shown on
	             the arena enemies (1 targeted, 2 focused, 3 both)
	  friendly   party / arena allies: role icon, identity circle, name, HP + %,
	             range fade, dead, a large CC icon over the bar's right end, a
	             restrained dispel border + debuff icon (thicker on HEALER),
	             debuffs to the right (DPS column) or above (HEALER row), small
	             friendly defensive; arena allies carry a violet arena accent
	  raid       compact: short name, percent, small role icon, range, dead /
	             offline, a dispel border; no circles, no bamboo
	  enemies    identity circle (CC replaces it while CC'd), SPEC - NAME, HP + %,
	             a tall readable cast bar (interruptible: attention amber;
	             not interruptible: restrained steel with a shield), target
	             (lime) / focus (violet) outline + edge tab, burst (red) and
	             defensive (teal) icons, trinket slot, DR slots
	  focus      circle, cast bar, CC in the circle
	  ToT / pet  subordinate: name + percent (ToT), name + health (pet)
	  boss       name, HP + %, cast bar; no PvP slots

	0.9.0 (PvP unit frames + cooldown bars), the same construction as live:
	  party /    CLASS / SPEC CIRCLE | HEALTH BAR (HP + % at the left, role icon
	  allies     [mMT-role:icon] at the right end) | TRINKET CIRCLE; DPS 50 %
	             narrower (100) at full height, HEALER 100 wide and 30 % lower;
	             no ordinary buffs / debuff rows / DR: crowd control as a large
	             icon in the bar with a CC border and label, a dispellable
	             effect as a compact icon below the frame with a DISPEL label and
	             a cyan border. Party and arena allies can both be shown: the
	             allies then sit just above the party (the same place in the game)
	  enemies    mirrored on the right: TRINKET | HEALTH BAR | CLASS / SPEC
	             CIRCLE, cast bar above, CC over the circle, their offensive /
	             defensive buff left of the trinket, target / focus outline
	  states     NORMAL, LOW HEALTH, OUT OF RANGE, DEAD, CASTING,
	             NON-INTERRUPTIBLE CAST, ALLY CC'D, ENEMY CC'D (long, short and
	             no-duration crowd control), DISPELLABLE, OFFENSIVE / DEFENSIVE
	             ACTIVE, TRINKET AVAILABLE / USED / UNKNOWN; DR is gone with the
	             DR icons
	  cooldowns  the offensive / defensive cooldown bars (CooldownBars.lua) as
	             labelled SAMPLE bars ('cooldowns')

	1.3.0: a FRAME STYLE selector - BANZAI CLASSIC (everything above, as it
	was) or BANZAI SPLIT (Split.lua draws the samples: Player idle / casting /
	channeling, Target player and NPC, Focus, ToT, DPS / HEALER party, the
	enhanced targeted nameplate) - by default the style the session runs; a new
	CHANNELING state (the classic samples show it as a cast). Both styles keep
	their own sample frames, hidden together in combat.

	1.3.3: an INTERRUPTED state for the BANZAI SPLIT samples (the bamboo cast
	bar's moment after an interrupt; the classic samples show their plain
	frames); the TARGET NPC sample is synthetic and Banzai's own (Split.lua).
]]
local _, ns = ...
local Theme = ns.Theme
local G = ns.Geometry

local Preview = {}
ns.Preview = Preview
if ns.Compat then ns.Compat.Preview = Preview end -- the options page reaches it through BanzaiCompat

Preview.TYPES = { 'player', 'target', 'targettarget', 'focus', 'pet', 'party', 'raid', 'arenaAllies', 'arenaEnemies', 'boss' }
Preview.LABELS = {
	player = 'Player', target = 'Target', targettarget = 'Target of Target', focus = 'Focus', pet = 'Pet',
	party = 'Party', raid = 'Raid', arenaAllies = 'Arena Allies', arenaEnemies = 'Arena Enemies', boss = 'Boss',
	targetNPC = 'Target NPC', nameplate = 'Target nameplate', -- 1.3.0 BANZAI SPLIT samples
}
Preview.SPLIT_TYPES = { 'targetNPC', 'nameplate' } -- 1.3.0: shown only in the BANZAI SPLIT style
-- preview states (synthetic visual states; they show designs, not live data)
Preview.STATES = { 'NORMAL', 'LOW_HEALTH', 'OUT_OF_RANGE', 'DEAD', 'CASTING', 'CAST_LOCKED', 'CHANNELING', 'INTERRUPTED', 'CC_ALLY', 'CC_ENEMY', 'DISPELLABLE', 'OFFENSIVE', 'DEFENSIVE',
	'TRINKET_READY', 'TRINKET_USED', 'TRINKET_UNKNOWN' }
Preview.STATE_LABELS = {
	NORMAL = 'NORMAL', LOW_HEALTH = 'LOW HEALTH', OUT_OF_RANGE = 'OUT OF RANGE', DEAD = 'DEAD', CASTING = 'CASTING',
	CAST_LOCKED = 'NON-INTERRUPTIBLE CAST', CHANNELING = 'CHANNELING', INTERRUPTED = 'INTERRUPTED', CC_ALLY = 'ALLY CC\'D', CC_ENEMY = 'ENEMY CC\'D', DISPELLABLE = 'DISPELLABLE',
	OFFENSIVE = 'OFFENSIVE ACTIVE', DEFENSIVE = 'DEFENSIVE ACTIVE', TRINKET_READY = 'TRINKET AVAILABLE', TRINKET_USED = 'TRINKET USED',
	TRINKET_UNKNOWN = 'TRINKET UNKNOWN',
}
Preview.COOLDOWNS = 'cooldowns' -- the cooldown-bar preview (CooldownBars.lua)

local BAR = Theme.MEDIA .. 'BanzaiBar'
local fontBakeoff
local FONT_SAMPLES = {
	'BANZAI   SLAND',
	'BUFFS   CHAT',
	'DAMAGE   HEALING',
	'READY CHECK',
	'CRACKLING JADE LIGHTNING',
	'MISTWEAVER   UNHOLY',
	'100%   +250   +9,800 XP',
	'12:40   1.4s   18%',
}

function Preview:RefreshFontBakeoff()
	local frame = fontBakeoff
	if not frame then return end
	local info = Theme:DisplayFontInfo(table.concat(FONT_SAMPLES, ' '))
	frame.status:SetText(format('%s | by %s | %s | fallback required: %s', info.name, tostring(info.author), info.status, info.fallback and 'yes' or 'no'))
	frame.source:SetText('Source: ' .. tostring(info.source) .. ' | file: ' .. tostring(info.file) .. ' | license: ' .. tostring(info.license)
		.. ' | SHA-256: ' .. tostring(info.sourceSha256 or 'not applicable'))
end

function Preview:ShowFontBakeoff()
	if not fontBakeoff then
		local frame = CreateFrame('Frame', 'BanzaiFontBakeoffPreview', UIParent)
		fontBakeoff = frame
		frame:SetSize(690, 390)
		frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
		frame:SetFrameStrata('DIALOG')
		frame:EnableMouse(true)
		frame:SetMovable(true)
		frame:RegisterForDrag('LeftButton')
		frame:SetScript('OnDragStart', frame.StartMoving)
		frame:SetScript('OnDragStop', frame.StopMovingOrSizing)
		frame.background = frame:CreateTexture(nil, 'BACKGROUND')
		frame.background:SetAllPoints(frame)
		frame.background:SetTexture(Theme.WHITE)
		frame.background:SetVertexColor(0.015, 0.075, 0.045, 0.97)
		frame.title = frame:CreateFontString(nil, 'OVERLAY')
		frame.title:SetFont(Theme:SmallFont(), 16, 'OUTLINE')
		frame.title:SetPoint('TOPLEFT', frame, 'TOPLEFT', 20, -18)
		frame.title:SetText('DISPLAY FONT PREVIEW')
		frame.close = CreateFrame('Button', nil, frame)
		frame.close:SetSize(24, 24)
		frame.close:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -10, -10)
		frame.close.label = frame.close:CreateFontString(nil, 'OVERLAY')
		frame.close.label:SetFont(Theme:SmallFont(), 14, 'OUTLINE')
		frame.close.label:SetPoint('CENTER')
		frame.close.label:SetText('X')
		frame.close:SetScript('OnClick', function() frame:Hide() end)
		frame.status = frame:CreateFontString(nil, 'OVERLAY')
		frame.status:SetFont(Theme:SmallFont(), 11, 'OUTLINE')
		frame.status:SetPoint('TOPLEFT', frame, 'TOPLEFT', 20, -48)
		frame.status:SetWidth(650)
		frame.source = frame:CreateFontString(nil, 'OVERLAY')
		frame.source:SetFont(Theme:SmallFont(), 10, 'OUTLINE')
		frame.source:SetPoint('TOPLEFT', frame, 'TOPLEFT', 20, -68)
		frame.source:SetWidth(650)
		for i, sample in ipairs(FONT_SAMPLES) do
			local text = frame:CreateFontString(nil, 'OVERLAY')
			text:SetFont(Theme:SmallFont(), 18, 'OUTLINE')
			text:SetText(sample)
			text:SetPoint('TOPLEFT', frame, 'TOPLEFT', 22, -100 - (i - 1) * 28)
			text:SetWidth(645)
			text:SetJustifyH('LEFT')
			Theme:SetDisplayFont(text, Theme:DisplaySize(18), 'OUTLINE', sample)
		end
	end
	self:RefreshFontBakeoff()
	fontBakeoff:Show()
end

local SEPARATOR = '|cff8c919a - |r'
local ICONS = 'Interface\\Icons\\'
local SAMPLE_CLASSES = { 'PALADIN', 'PRIEST', 'MAGE', 'ROGUE', 'SHAMAN', 'WARRIOR', 'HUNTER', 'DRUID', 'WARLOCK', 'DEATHKNIGHT', 'MONK', 'EVOKER', 'DEMONHUNTER' }
local SAMPLE_SPECS = {
	PALADIN = 'HOLY', PRIEST = 'DISCIPLINE', MAGE = 'FROST', ROGUE = 'SUBTLETY', SHAMAN = 'RESTORATION', WARRIOR = 'ARMS', HUNTER = 'MARKSMANSHIP',
	DRUID = 'BALANCE', WARLOCK = 'AFFLICTION', DEATHKNIGHT = 'UNHOLY', MONK = 'MISTWEAVER', EVOKER = 'PRESERVATION', DEMONHUNTER = 'HAVOC',
}
local POWER_COLORS = {
	mana = { 0.00, 0.55, 1.00 }, energy = { 1.00, 0.85, 0.10 }, rage = { 1.00, 0.22, 0.22 }, focus = { 1.00, 0.55, 0.25 },
	runic = { 0.00, 0.82, 1.00 }, fury = { 0.79, 0.26, 0.99 },
}
local CLASS_POWER = {
	PALADIN = 'mana', PRIEST = 'mana', MAGE = 'mana', ROGUE = 'energy', SHAMAN = 'mana', WARRIOR = 'rage', HUNTER = 'focus', DRUID = 'mana',
	WARLOCK = 'mana', DEATHKNIGHT = 'runic', MONK = 'energy', EVOKER = 'mana', DEMONHUNTER = 'fury',
}
local LEVELS = { 1.00, 0.76, 0.52, 0.23, 0.08 } -- full, partial, low
local HOSTILE = { 0.86, 0.12, 0.12 }
local FRIENDLY = { 0.20, 0.82, 0.30 }

-- single units: placed on the real frame (or its mover when it has no size)
local SINGLE = {
	player = { frame = 'ElvUF_Player', mover = 'ElvUF_PlayerMover', unit = 'player', label = 'PLAYER PREVIEW', health = 1.00, max = 571000, identity = 'after', own = true, bamboo = true, kind = 'single' },
	target = { frame = 'ElvUF_Target', mover = 'ElvUF_TargetMover', unit = 'target', label = 'TARGET PREVIEW', health = 0.64, max = 1000000, identity = 'before', class = 'MAGE', bamboo = true, kind = 'single' },
	targettarget = { frame = 'ElvUF_TargetTarget', mover = 'ElvUF_TargetTargetMover', unit = 'targettarget', label = 'TARGET OF TARGET', health = 0.18, max = 643000, class = 'PRIEST', kind = 'single', percentOnly = true },
	focus = { frame = 'ElvUF_Focus', mover = 'ElvUF_FocusMover', unit = 'focus', label = 'FOCUS PREVIEW', health = 0.42, max = 812000, identity = 'after', class = 'ROGUE', circle = true, kind = 'focus' },
	pet = { frame = 'ElvUF_Pet', mover = 'ElvUF_PetMover', unit = 'pet', label = 'PET PREVIEW', health = 0.88, max = 240000, color = FRIENDLY, kind = 'single' },
}
-- groups: laid out from the ElvUI profile at the position the selected role
-- layout gives their ElvUI mover. roleUnits = the party header arrangement
-- comes with the role layout; text = the Health.lua group whose inside text
-- the frames use; circle = identity circle; kind = which Banzai design it gets
local GROUPS = {
	party = { unit = 'party', mover = 'ElvUF_PartyMover', count = 5, label = 'PARTY %d', parts = 'party', identity = 'after', max = 520000, title = 'PARTY',
		roleUnits = true, text = 'ElvUF_PartyGroup1UnitButton', circle = true, kind = 'friendly', role = true, trinket = 'RIGHT' },
	raid = { unit = 'raid1', mover = 'ElvUF_Raid1Mover', perGroup = 5, label = 'RAID %d', parts = 'raid', max = 480000, title = 'RAID', kind = 'raid', role = true },
	arenaAllies = { unit = 'party', mover = 'ArenaAlliesMover', fallbackMover = 'ElvUF_PartyMover', count = 3, label = 'ALLY %d', parts = 'party', identity = 'after', max = 520000, title = 'ARENA ALLIES',
		roleUnits = true, text = 'ElvUF_PartyGroup1UnitButton', circle = true, kind = 'friendly', role = true, arena = true, trinket = 'RIGHT' },
	arenaEnemies = { unit = 'arena', mover = 'ArenaHeaderMover', count = 3, label = 'ENEMY %d', identity = 'before', max = 540000, offset = 3, title = 'ARENA ENEMIES',
		roleUnits = true, text = 'ElvUF_Arena', circle = true, circleSide = 'RIGHT', kind = 'enemy', trinket = 'LEFT' },
	boss = { unit = 'boss', mover = 'BossHeaderMover', count = 4, label = 'BOSS %d', parts = 'boss', max = 98000000, color = HOSTILE, title = 'BOSS',
		text = 'ElvUF_Boss', kind = 'boss' },
}
Preview.SINGLE, Preview.GROUPS = SINGLE, GROUPS
-- dispel-type colours (the same family ElvUI's debuff highlight uses)
Preview.DISPEL = { Magic = { 0.20, 0.60, 1.00 }, Curse = { 0.60, 0.00, 1.00 }, Disease = { 0.60, 0.40, 0.00 }, Poison = { 0.00, 0.60, 0.00 } }
-- 0.8.0 PvP colours: casts (the same as the live ElvUI cast colours BushidoPrivateRestore writes, T.PVP),
-- crowd-control categories, burst / defensive (0.9.0: no DR levels any more)
Preview.CAST = { open = { 1.00, 0.70, 0.00 }, locked = { 0.46, 0.44, 0.56 } }
Preview.CC = { STUN = { 1.00, 0.30, 0.25 }, INCAP = { 0.80, 0.40, 1.00 }, SILENCE = { 0.30, 0.65, 1.00 } }
Preview.OFFENSIVE = { 1.00, 0.38, 0.12 }
Preview.DEFENSIVE = { 0.25, 0.85, 1.00 }
local HEALERS = { HOLY = true, DISCIPLINE = true, RESTORATION = true, MISTWEAVER = true, PRESERVATION = true }
-- the game's specialization IDs of the sample specs (the identity circles show their Fabled spec icon)
local SAMPLE_SPEC_IDS = {
	PALADIN = 65, PRIEST = 256, MAGE = 64, ROGUE = 261, SHAMAN = 264, WARRIOR = 71, HUNTER = 254,
	DRUID = 102, WARLOCK = 265, DEATHKNIGHT = 252, MONK = 270, EVOKER = 1468, DEMONHUNTER = 577,
}
Preview.SAMPLE_SPEC_IDS = SAMPLE_SPEC_IDS
local ROLE_ICONS = 'Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES'
local ROLE_COORDS = { TANK = { 0, 19 / 64, 22 / 64, 41 / 64 }, HEALER = { 20 / 64, 39 / 64, 1 / 64, 20 / 64 }, DAMAGER = { 20 / 64, 39 / 64, 22 / 64, 41 / 64 } }
local DEBUFF_ICONS = { Magic = ICONS .. 'Spell_Frost_FrostNova', Poison = ICONS .. 'Ability_Rogue_DualWeild', Curse = ICONS .. 'Spell_Shadow_CurseOfTounges', Disease = ICONS .. 'Spell_Shadow_AbominationExplosion' }
local SHIELD = 'Interface\\CastingBar\\UI-CastingBar-Small-Shield'
-- sample spells (names and icons only: nothing here is read from the game)
local SAMPLE = {
	casts = { { 'Chaos Bolt', 'Ability_Warlock_ChaosBolt' }, { 'Greater Heal', 'Spell_Holy_GreaterHeal' }, { 'Lightning Bolt', 'Spell_Nature_Lightning' } },
	bossCast = { 'Cataclysm', 'Spell_Shadow_RainOfFire' },
	cc = { friendly = { 'Spell_Nature_Polymorph', 'INCAP', '5.2' }, raid = { 'Ability_Rogue_KidneyShot', 'STUN', '3' }, enemy = { 'Spell_Shadow_Possess', 'INCAP', '4.1' }, focus = { 'Ability_Rogue_KidneyShot', 'STUN', '2.6' } },
	offensive = 'Spell_Holy_AvengineWrath', defensive = 'Spell_Holy_DivineShield',
}
Preview.SAMPLE = SAMPLE
Preview.RANGE_ALPHA = 0.45 -- out of range, like ElvUI's range fader

local frames = {} -- [key] = container
local splitFrames = {} -- 1.3.0 [key] = BANZAI SPLIT container (Split.lua builds them)
local variants = {} -- [key .. ':' .. role] = container of a group built in that role's arrangement (kept for the next switch)

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function UnitDB(unit)
	local E = Engine()
	local units = E and E.db and E.db.unitframe and E.db.unitframe.units
	return units and units[unit] or {}
end

-- rectangle of a region in UIParent units (nil when it has no layout)
local function Rect(region)
	if not (region and region.GetRect) then return nil end
	local l, b, w, h = region:GetRect()
	if type(l) ~= 'number' or IsSecret(l) or type(w) ~= 'number' or w <= 0 then return nil end
	local scale = 1
	if region.GetEffectiveScale and UIParent.GetEffectiveScale then
		local own, parent = region:GetEffectiveScale(), UIParent:GetEffectiveScale()
		if type(own) == 'number' and type(parent) == 'number' and parent > 0 then scale = own / parent end
	end
	return l * scale, b * scale, w * scale, h * scale
end

-- the layout shown: the one chosen in the options, else the spec's
function Preview:Role()
	if self.role then return self.role end
	local roles = _G.BanzaiRoles
	return (roles and roles.Current and roles.Current()) or 'DPS'
end

-- the preview state shown (kept with the BANZAI settings)
function Preview:State()
	local state = Theme:DB().previewState
	return Preview.STATE_LABELS[state] and state or 'NORMAL'
end

local function RoleLayout()
	local roles = _G.BanzaiRoles
	return roles and roles.Layout and roles:Layout(Preview:Role()) or nil
end

-- position of a mover in the shown role layout (else the profile's own)
local function MoverValue(moverName, fallback)
	local layout = RoleLayout()
	if layout and layout[moverName] then return layout[moverName] end
	local E = Engine()
	local movers = E and E.db and E.db.movers
	return movers and (movers[moverName] or (fallback and movers[fallback]))
end
Preview.MoverValue = MoverValue

-- the ElvUI unit settings a group is laid out with; party / arena allies take
-- the arrangement of the shown role (growth, spacing, width; 0.9.0 height),
-- arena enemies its arena size (0.9.0). The unit's own settings are read
-- through (ElvUI's defaults sit behind its profile tables).
Preview.ROLE_KEYS = {
	party = { 'growthDirection', 'horizontalSpacing', 'verticalSpacing', 'width', 'height' },
	arena = { 'width', 'height' },
}
function Preview.GroupDB(def)
	local db = setmetatable({}, { __index = UnitDB(def.unit) })
	local layout = def.roleUnits and RoleLayout()
	if layout then
		for _, key in ipairs(Preview.ROLE_KEYS[def.unit] or {}) do
			if layout[def.unit .. '.' .. key] ~= nil then db[key] = layout[def.unit .. '.' .. key] end
		end
	end
	return db
end

local function Anchor(container, moverName, fallback)
	local value = MoverValue(moverName, fallback)
	container:ClearAllPoints()
	if type(value) == 'string' then
		local point, _, relative, x, y = string.match(value, '^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$')
		if point then
			container:SetPoint(point, UIParent, relative, tonumber(x) or 0, tonumber(y) or 0)
			return true
		end
	end
	local l, b = Rect(_G[moverName])
	if l then
		container:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', l, b)
		return true
	end
	container:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	return false
end

Preview.Anchor = Anchor -- 1.3.0: the split party samples use the same places

local function Short(n)
	if n >= 1e6 then return (string.format('%.1fM', n / 1e6):gsub('%.0M', 'M')) end
	if n >= 1e3 then return string.format('%dK', math.floor(n / 1e3 + 0.5)) end
	return tostring(math.floor(n))
end

local function PlayerClassAndSpec()
	local _, token = UnitClass('player')
	if IsSecret(token) then token = nil end
	local spec = ns.Tags and ns.Tags.PlayerSpec and ns.Tags.PlayerSpec()
	return token or 'DRUID', spec and string.upper(spec) or nil
end

---------------------------------------------------------------------------
-- Pieces
---------------------------------------------------------------------------
local function Bar(parent, level)
	local bar = CreateFrame('StatusBar', nil, parent)
	bar:SetStatusBarTexture(BAR)
	bar:SetMinMaxValues(0, 1)
	bar:SetFrameLevel(level)
	return bar
end

local function Paint(bar, color, value)
	bar:SetValue(value)
	local fill = bar:GetStatusBarTexture()
	if fill then
		Theme:Gradient(fill, 'HORIZONTAL', { color[1] * 0.72, color[2] * 0.72, color[3] * 0.72 }, Theme.Mix(color, { 1, 1, 1 }, 0.22), 1, 1)
	end
end

local function Text(parent, size, layer)
	local fs = parent:CreateFontString(nil, layer or 'OVERLAY')
	fs:SetFont(Theme:SmallFont(), size, 'OUTLINE')
	return fs
end

-- icon square: a 1-unit border in a colour, the icon inside, optional text on it
local function Square(parent, size, level)
	local f = CreateFrame('Frame', nil, parent)
	f:SetSize(size, size)
	f:SetFrameLevel(level)
	f.border = f:CreateTexture(nil, 'BACKGROUND')
	f.border:SetAllPoints()
	f.border:SetTexture(Theme.WHITE)
	f.icon = f:CreateTexture(nil, 'ARTWORK')
	f.icon:SetPoint('TOPLEFT', f, 'TOPLEFT', 1, -1)
	f.icon:SetSize(size - 2, size - 2)
	return f
end

local function IconSquare(parent, size, level, icon, color, text, textSize)
	local f = Square(parent, size, level)
	f.icon:SetTexture(icon)
	f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	f.border:SetVertexColor(color[1], color[2], color[3], 1)
	f.text = Text(f, textSize or math.max(8, math.floor(size * 0.38)))
	f.text:SetPoint('CENTER', f, 'CENTER', 0, 0)
	f.text:SetText(text or '')
	f:Hide()
	return f
end

-- a thin border around a region (outline), `inset` outside it
local function Border(parent, region, color, thickness, inset, level)
	local o = CreateFrame('Frame', nil, parent)
	inset = inset or 2
	o:SetPoint('TOPLEFT', region, 'TOPLEFT', -inset, inset)
	o:SetPoint('BOTTOMRIGHT', region, 'BOTTOMRIGHT', inset, -inset)
	o:SetFrameLevel(level)
	o.edges = {}
	for i, side in ipairs({ { 'TOPLEFT', 'TOPRIGHT', true }, { 'BOTTOMLEFT', 'BOTTOMRIGHT', true }, { 'TOPLEFT', 'BOTTOMLEFT', false }, { 'TOPRIGHT', 'BOTTOMRIGHT', false } }) do
		local t = o:CreateTexture(nil, 'OVERLAY')
		t:SetTexture(Theme.WHITE)
		t:SetPoint(side[1], o, side[1], 0, 0)
		t:SetPoint(side[2], o, side[2], 0, 0)
		if side[3] then t:SetHeight(thickness) else t:SetWidth(thickness) end
		t:SetVertexColor(color[1], color[2], color[3], 1)
		o.edges[i] = t
	end
	o.color = color
	o:Hide()
	return o
end

-- target / focus marker: outline + a solid tab on the bar's left edge + a short label
-- 0.9.0: the label inside the bar's bottom-right corner (the cast bar is above the frame), as live (PvPFrames.lua)
local function Marker(u, color, label, inset, labelX)
	local o = Border(u, u.Health, color, 2, inset, u:GetFrameLevel() + 7)
	o.tab = o:CreateTexture(nil, 'OVERLAY')
	o.tab:SetTexture(Theme.WHITE)
	o.tab:SetPoint('TOPLEFT', u.Health, 'TOPLEFT', 0, 0)
	o.tab:SetPoint('BOTTOMLEFT', u.Health, 'BOTTOMLEFT', 0, 0)
	o.tab:SetWidth(4)
	o.tab:SetVertexColor(color[1], color[2], color[3], 1)
	o.label = Text(o, 8)
	o.label:SetPoint('BOTTOMRIGHT', u.Health, 'BOTTOMRIGHT', labelX or -6, 2)
	o.label:SetText(label)
	o.label:SetTextColor(color[1], color[2], color[3])
	return o
end

-- a readable cast bar under the frame: icon, spell, time; amber when it can be
-- interrupted, restrained steel with a shield when it cannot
local function CastBar(u, w)
	local cast = CreateFrame('Frame', nil, u)
	local h = 11
	cast:SetSize(w, h)
	cast:SetPoint('TOPLEFT', u, 'BOTTOMLEFT', 0, -3)
	cast:SetFrameLevel(u:GetFrameLevel() + 3)
	cast.icon = cast:CreateTexture(nil, 'ARTWORK')
	cast.icon:SetSize(h, h)
	cast.icon:SetPoint('LEFT', cast, 'LEFT', 0, 0)
	cast.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	cast.back = cast:CreateTexture(nil, 'BACKGROUND')
	cast.back:SetPoint('TOPLEFT', cast, 'TOPLEFT', h + 1, 0)
	cast.back:SetSize(w - h - 1, h)
	Theme:Trough(cast.back)
	cast.bar = Bar(cast, cast:GetFrameLevel() + 1)
	cast.bar:SetPoint('TOPLEFT', cast, 'TOPLEFT', h + 1, 0)
	cast.bar:SetSize(w - h - 1, h)
	cast.textLayer = CreateFrame('Frame', nil, cast)
	cast.textLayer:SetAllPoints(cast)
	cast.textLayer:SetFrameLevel(cast:GetFrameLevel() + 4)
	cast.text = Text(cast.textLayer, 9)
	cast.text:SetPoint('LEFT', cast.bar, 'LEFT', 3, 0)
	cast.time = Text(cast.textLayer, 9)
	cast.time:SetPoint('RIGHT', cast.bar, 'RIGHT', -3, 0)
	cast.shield = cast.textLayer:CreateTexture(nil, 'OVERLAY')
	cast.shield:SetTexture(SHIELD)
	cast.shield:SetSize(h + 6, h + 6)
	cast.shield:SetPoint('CENTER', cast.icon, 'CENTER', 0, 0)
	cast:Hide()
	return cast
end

function Preview.SetCast(cast, spell, interruptible, progress)
	local color = interruptible and Preview.CAST.open or Preview.CAST.locked
	cast.icon:SetTexture(ICONS .. spell[2])
	cast.text:SetText(spell[1])
	cast.time:SetText(string.format('%.1f', 2.5 * (1 - progress)))
	Paint(cast.bar, color, progress)
	cast.shield:SetShown(not interruptible)
	cast.interruptible = interruptible
	cast:Show()
end

-- Bushido plates (dark WHITE parts) and, on Player / Target only, the bamboo end bundle at their Geometry offsets
-- design: the frame width Bushido placed the parts for (1.0.0: the narrow
-- frames keep every piece at its own end, the same as the live frames)
local function Place(region, unitFrame, part, scale, design)
	local place = ns.Compat and ns.Compat.PlacePart
	if place then return place(region, unitFrame, part, scale, design) end
	region:SetSize(part.w * scale, part.h * scale)
	region:SetPoint('CENTER', unitFrame, 'CENTER', part.x * scale, part.y * scale)
end

local function Art(unitFrame, parts, scale, bamboo, design)
	scale = scale or 1
	for _, part in ipairs(parts or {}) do
		if part.texture == 'WHITE' then
			local t = unitFrame:CreateTexture(nil, 'BACKGROUND', nil, -2)
			t:SetTexture(Theme.WHITE)
			Place(t, unitFrame, part, scale, design)
			local c = part.color
			t:SetVertexColor(c[1], c[2], c[3], c[4])
		elseif part.texture == 'BushidoEndPoint' and bamboo and ns.Compat and ns.Compat.Bundle then
			local holder = CreateFrame('Frame', nil, unitFrame)
			holder:SetFrameLevel(unitFrame:GetFrameLevel() + 6)
			holder.bw, holder.bh = part.w * scale, part.h * scale
			Place(holder, unitFrame, part, scale, design)
			ns.Compat.Bundle(holder, part.flipH, ns.Compat.StalkRamp, ns.Compat.TieRamp)
			unitFrame.bundle = holder
		end
	end
end

local function Identity(def, sample)
	local name = sample.label
	local spec = sample.spec
	if spec and def.identity == 'after' then
		return name .. SEPARATOR .. Theme:GradientText(spec, Theme.COLORS.lime, Theme.COLORS.emerald)
	elseif spec and def.identity == 'before' then
		return Theme:GradientText(spec, Theme.COLORS.lime, Theme.COLORS.emerald) .. SEPARATOR .. name
	end
	return name
end

---------------------------------------------------------------------------
-- One preview unit
---------------------------------------------------------------------------
-- unitFrame: sized frame; layout: { health = {x, y, w, h}, power = {...} | nil } relative to its TOPLEFT
local function BuildUnit(container, sample, def, w, h, layout, parts, scale, textDef, nameDB, design)
	local u = CreateFrame('Frame', nil, container)
	u:SetSize(w, h)
	u:SetFrameLevel(container:GetFrameLevel() + 1)
	u.sample, u.def = sample, def
	Art(u, parts, scale, def.bamboo, design)

	local trough = u:CreateTexture(nil, 'BACKGROUND', nil, 1)
	local hb = layout.health
	trough:SetPoint('TOPLEFT', u, 'TOPLEFT', hb[1] - 1, -hb[2] + 1)
	trough:SetSize(hb[3] + 2, hb[4] + 2)
	Theme:Trough(trough)
	u.trough = trough

	local health = Bar(u, u:GetFrameLevel() + 2)
	health:SetPoint('TOPLEFT', u, 'TOPLEFT', hb[1], -hb[2])
	health:SetSize(hb[3], hb[4])
	Paint(health, sample.color, sample.health)
	u.Health = health

	if layout.power then
		local pb = layout.power
		local back = u:CreateTexture(nil, 'BACKGROUND', nil, 1)
		back:SetPoint('TOPLEFT', u, 'TOPLEFT', pb[1], -pb[2])
		back:SetSize(pb[3], pb[4])
		Theme:Trough(back)
		local power = Bar(u, u:GetFrameLevel() + 2)
		power:SetPoint('TOPLEFT', u, 'TOPLEFT', pb[1], -pb[2])
		power:SetSize(pb[3], pb[4])
		Paint(power, sample.powerColor, sample.power)
		u.Power = power
	end

	-- 0.8.0: the identity line on its own text layer, above the fill, the empty
	-- track, the gradients and the inside health text (ElvUI keeps its custom
	-- texts on a raised layer the same way)
	u.textLayer = CreateFrame('Frame', nil, u)
	u.textLayer:SetAllPoints(u)
	u.textLayer:SetFrameLevel(health:GetFrameLevel() + 8)
	local name = Text(u.textLayer, (nameDB and nameDB.size) or 10)
	local justify = (nameDB and nameDB.justifyH) or 'LEFT'
	if nameDB then
		name:SetPoint(justify, health, justify, nameDB.xOffset or 0, nameDB.yOffset or 0)
	else
		name:SetPoint('BOTTOMLEFT', health, 'TOPLEFT', 2, 2)
	end
	u.name = name
	u.identityText = Identity(def, sample) -- name in the class colour, spec in its own Banzai gradient

	-- health number + percentage inside the bar (same treatment as the real frames)
	u.healthText = ns.Health and ns.Health.Attach and ns.Health:Attach(health, textDef) or nil
	-- identity circle outside the frame's left end (Identity.lua), spec icon of the sample spec
	local identity = ns.Identity
	if def.circle and identity and sample.class then
		local c = identity.Circle(u)
		c:SetFrameLevel(u:GetFrameLevel() + 6)
		if def.circleSide == 'RIGHT' then -- 0.9.0 arena enemies: mirrored
			c:SetPoint('LEFT', health, 'RIGHT', identity.GAP, 0)
		else
			c:SetPoint('RIGHT', health, 'LEFT', -identity.GAP, 0)
		end
		identity.Paint(c, sample.class, sample.specID)
		u.circle = c
	end
	return u
end

local SMALL_TEXT = { side = 'LEFT', x = 6, value = 11, percent = 8 }
local COMPACT_TEXT = { side = 'RIGHT', x = -3, value = 8, percent = 8 } -- raid / ToT: percent at the right end

local function TextDef(frameName)
	for _, def in ipairs((ns.Health and ns.Health.UNITS) or {}) do
		if def.frame == frameName then return def end
	end
	return SMALL_TEXT
end

-- the inside text of a secondary group (Health.lua GROUPS), the same as the real frames
local function GroupTextDef(prefix)
	for _, def in ipairs((ns.Health and ns.Health.GROUPS) or {}) do
		if def.prefix == prefix then return def end
	end
	return SMALL_TEXT
end

local function PartsFor(frameName)
	for _, u in ipairs(G.units or {}) do
		if u.frame == frameName then return u.parts end
	end
end

local function Sample(def, index, key)
	local class, spec = def.class, nil
	if def.own then class, spec = PlayerClassAndSpec() end
	if not class and not def.color then class = SAMPLE_CLASSES[((index - 1 + (def.offset or 0)) % #SAMPLE_CLASSES) + 1] end
	if class and not spec then spec = SAMPLE_SPECS[class] end
	local color = def.color or Theme:ClassColor(class)
	local level = def.health or LEVELS[((index - 1) % #LEVELS) + 1]
	local label = def.label
	if string.find(label, '%d', 1, true) then label = string.format(label, index) end
	local specID = class and SAMPLE_SPEC_IDS[class]
	if def.own then
		local current = GetSpecialization and GetSpecialization()
		local id = type(current) == 'number' and not IsSecret(current) and GetSpecializationInfo and GetSpecializationInfo(current)
		specID = (type(id) == 'number' and not IsSecret(id)) and id or nil
	end
	return {
		label = label, class = class, spec = (def.identity and spec) or nil, specID = specID, color = color, health = level, max = def.max or 500000,
		power = 0.35 + 0.6 * ((index * 37) % 10) / 10, powerColor = POWER_COLORS[(class and CLASS_POWER[class]) or 'mana'], key = key,
		role = (spec and HEALERS[spec]) and 'HEALER' or ((index == 1 and class == 'WARRIOR') and 'TANK' or 'DAMAGER'), index = index,
	}
end

---------------------------------------------------------------------------
-- The Banzai design of each kind of frame (sample furniture, hidden until a state shows it)
---------------------------------------------------------------------------
-- 0.9.0 sizes and places as the live frames (Transform T.PVP / T.ROLE_LAYOUTS, PvPFrames.lua)
Preview.CC_SIZE = { DPS = 30, HEALER = 22 } -- the party crowd-control icon inside the bar's right end
Preview.DISPEL_SIZE = 14

local function Emphasis(key)
	local P = ns.PvPFrames
	local level = Theme:DB()[key]
	return (P and P.EMPHASIS and P.EMPHASIS[level]) or { border = 3, label = true, pulse = true }
end

-- a state border (CC magenta / dispel cyan) with its label and, at STRONG, a restrained pulse
local function StateBorder(u, color, inset, level, labelText, labelSize)
	local b = Border(u, u.Health, color, 3, inset, level)
	b.label = Text(b, labelSize or 10)
	b.label:SetFont(Theme:PreviousDisplayFont(), labelSize or 10, 'OUTLINE') -- 1.3.1: as the live PvP labels
	b.label:SetText(labelText)
	b.label:SetTextColor(color[1], color[2], color[3])
	if b.CreateAnimationGroup then
		b.pulse = b:CreateAnimationGroup()
		b.pulse:SetLooping('BOUNCE')
		local fade = b.pulse:CreateAnimation('Alpha')
		fade:SetFromAlpha(1)
		fade:SetToAlpha(0.45)
		fade:SetDuration(0.7)
	end
	return b
end

local function ShowStateBorder(b, key)
	local level = Emphasis(key)
	local thickness = level.border or 0
	for i, edge in ipairs(b.edges) do
		if i <= 2 then edge:SetHeight(math.max(thickness, 1)) else edge:SetWidth(math.max(thickness, 1)) end
		edge:SetShown(thickness > 0)
	end
	b.label:SetShown(level.label and true or false)
	if b.pulse then
		if level.pulse then b.pulse:Play() else b.pulse:Stop() end
	end
	b:Show()
end

local function Furnish(u, def, w, h, role)
	local level = u:GetFrameLevel() + 6
	local kind = def.kind
	local healer = (role == 'HEALER')
	local P = ns.PvPFrames
	local circle = (ns.Identity and ns.Identity.SIZE) or 27
	local gap = (ns.Identity and ns.Identity.GAP) or 4
	if def.role then -- party / arena allies: [mMT-role:icon] inside the bar's right end; raid: ElvUI's small role icon at its left end
		local size = (kind == 'raid') and 10 or 14
		local icon = u.textLayer:CreateTexture(nil, 'OVERLAY')
		icon:SetTexture(ROLE_ICONS)
		local c = ROLE_COORDS[u.sample.role] or ROLE_COORDS.DAMAGER
		icon:SetTexCoord(c[1], c[2], c[3], c[4])
		icon:SetSize(size, size)
		if kind == 'raid' then
			icon:SetPoint('LEFT', u.Health, 'LEFT', 2, 0)
		else
			icon:SetPoint('RIGHT', u.Health, 'RIGHT', -2, 0)
		end
		u.roleIcon = icon
	end
	if kind == 'friendly' or kind == 'raid' then
		-- dispellable: party - a compact icon below the frame's right end, a DISPEL label, a cyan border; raid - a thin border and the icon in the bar
		local raid = (kind == 'raid')
		u.dispel = raid and Border(u, u.Health, Preview.DISPEL.Magic, 1, 2, level)
			or StateBorder(u, (P and P.COLORS.dispel) or Preview.DEFENSIVE, 1, level, 'DISPEL', 8)
		u.debuff = IconSquare(u, raid and 14 or Preview.DISPEL_SIZE, level + 1, DEBUFF_ICONS.Magic, Preview.DISPEL.Magic)
		if raid then
			u.debuff:SetPoint('RIGHT', u.Health, 'RIGHT', -31, 0) -- before the percent
		else
			u.debuff:SetPoint('TOPRIGHT', u, 'BOTTOMRIGHT', 0, -2)
			u.dispel.label:SetPoint('RIGHT', u.debuff, 'LEFT', -2, 0)
		end
		-- crowd control: highly noticeable on friendly frames (a large icon inside the bar's right end)
		local cc = raid and (h - 4) or math.min(Preview.CC_SIZE[healer and 'HEALER' or 'DPS'], h - 4)
		u.cc = IconSquare(u, cc, level + 2, ICONS .. SAMPLE.cc.friendly[1], Preview.CC.INCAP, '', raid and 8 or 11)
		u.cc:SetPoint('RIGHT', u.Health, 'RIGHT', -3, 0)
		if not raid then
			u.ccBorder = StateBorder(u, (P and P.COLORS.cc) or Preview.CC.STUN, 3, level + 1, 'CC', 11)
			u.ccBorder.label:SetPoint('BOTTOM', u.cc, 'TOP', 0, 1)
		end
		u.dead = Text(u.textLayer, raid and 8 or 11)
		u.dead:SetPoint('CENTER', u.Health, 'CENTER', 0, 0)
		if def.arena then -- arena context: a violet accent along the top of the bar
			u.arenaAccent = u.textLayer:CreateTexture(nil, 'OVERLAY')
			u.arenaAccent:SetTexture(Theme.WHITE)
			u.arenaAccent:SetPoint('TOPLEFT', u.Health, 'TOPLEFT', 0, 0)
			u.arenaAccent:SetPoint('TOPRIGHT', u.Health, 'TOPRIGHT', 0, 0)
			u.arenaAccent:SetHeight(2)
			Theme:Gradient(u.arenaAccent, 'HORIZONTAL', Theme.COLORS.violet, Theme.COLORS.purple, 1, 0.2)
		end
	end
	-- the trinket circle: right of party / arena allies, left of arena enemies (mirrored)
	if def.trinket and P and P.Trinket then
		local t = P.Trinket(u, circle)
		t:SetFrameLevel(level)
		if def.trinket == 'RIGHT' then
			t:SetPoint('LEFT', u.Health, 'RIGHT', gap, 0)
		else
			t:SetPoint('RIGHT', u.Health, 'LEFT', -gap, 0)
		end
		u.trinket = t
	end
	if kind == 'enemy' or kind == 'focus' or kind == 'boss' then
		u.cast = CastBar(u, w)
		if kind == 'boss' or kind == 'enemy' then -- the live boss / arena cast bar sits above each frame (Transform T.PVP.castAbove)
			u.cast:ClearAllPoints()
			u.cast:SetPoint('BOTTOMLEFT', u, 'TOPLEFT', 0, 2)
		end
		u.dead = Text(u.textLayer, 11)
		u.dead:SetPoint('CENTER', u.Health, 'CENTER', 0, 0)
	end
	if kind == 'enemy' or kind == 'focus' then
		-- crowd control in place of the identity circle (visible, not covering cast or health)
		u.cc = IconSquare(u, circle - 2, level + 3, ICONS .. SAMPLE.cc[kind][1], Preview.CC.INCAP, '', 10)
		if u.circle then u.cc:SetPoint('CENTER', u.circle, 'CENTER', 0, 0) else u.cc:SetPoint('RIGHT', u.Health, 'LEFT', -gap, 0) end
		if kind == 'enemy' then
			u.ccBorder = StateBorder(u, (P and P.COLORS.cc) or Preview.CC.STUN, 3, level + 1, 'CC', 11)
			u.ccBorder.label:SetPoint('BOTTOM', u.cc, 'TOP', 0, 2)
		end
	end
	if kind == 'enemy' then
		-- their offensive / defensive buffs (the game's IMPORTANT / BIG / EXTERNAL_DEFENSIVE categories), left of the trinket
		local anchor = u.trinket or u.Health
		u.offensive = IconSquare(u, 20, level + 1, ICONS .. SAMPLE.offensive, Preview.OFFENSIVE, '', 7)
		u.offensive:SetPoint('RIGHT', anchor, 'LEFT', -gap, 0)
		u.defensive = IconSquare(u, 20, level + 1, ICONS .. SAMPLE.defensive, Preview.DEFENSIVE, '', 7)
		u.defensive:SetPoint('RIGHT', anchor, 'LEFT', -gap, 0)
		-- target / focus markers (always on the samples: 1 targeted, 2 focused, 3 both)
		u.targetMark = Marker(u, Theme.COLORS.lime, 'TARGET', 2, -6)
		u.focusMark = Marker(u, Theme.COLORS.violet, 'FOCUS', 5, -42)
	end
	if def.percentOnly or kind == 'raid' then u.percentOnly = true end
end

---------------------------------------------------------------------------
-- States
---------------------------------------------------------------------------
-- which sample units show what, per state (index = the unit's place in its group)
local DEMO = {
	NORMAL = { dispel = { party = { [2] = 'Magic' }, arenaAllies = { [3] = 'Magic' }, raid = { [3] = 'Magic', [9] = 'Disease', [16] = 'Curse' } },
		range = { party = { [5] = true }, raid = { [7] = true, [13] = true } }, cast = { arenaEnemies = { [1] = true }, boss = { [1] = true } } },
	DEAD = { party = { [2] = 'Dead' }, arenaAllies = { [2] = 'Dead' }, raid = { [4] = 'Dead', [11] = 'Offline' }, arenaEnemies = { [3] = 'Dead' } }, -- oUF's [status] words
	-- crowd control: unit 1 a long one, unit 2 a short one, unit 3 one whose duration the game does not give
	CC_ALLY = { party = { true, true, true }, arenaAllies = { true, true, true }, raid = { [3] = true } },
	CC_ENEMY = { arenaEnemies = { true, true, true }, focus = { true } },
	CC_TIME = { '8.0', '1.4', '' },
	DISPELLABLE = { party = { [2] = 'Magic', [4] = 'Poison' }, arenaAllies = { [2] = 'Magic', [3] = 'Curse' }, raid = { [3] = 'Magic', [9] = 'Disease', [16] = 'Curse' } },
	TRINKET_USED = { [1] = true, [3] = true },
}
Preview.DEMO = DEMO

local function SetHealthText(u, value, percent)
	if not u.healthText then return end
	for _, set in ipairs({ u.healthText.ghost, u.healthText.bright }) do
		set.value:SetText(value)
		set.percent:SetText(percent)
	end
end

-- everything back to the unit's sample values (NORMAL without the demo furniture)
local function Reset(u)
	local s = u.sample
	Paint(u.Health, s.color, s.health)
	local value, percent = Short(s.max * s.health), string.format('%d%%', math.floor(s.health * 100 + 0.5))
	if u.percentOnly then value = '' end
	SetHealthText(u, value, percent)
	u.name:SetText(u.def.kind == 'raid' and s.label or u.identityText)
	u.name:SetTextColor(s.color[1], s.color[2], s.color[3])
	u:SetAlpha(1)
	if u.circle and u.circle.icon then u.circle.icon:SetDesaturated(false) end
	for _, key in ipairs({ 'dispel', 'debuff', 'cc', 'ccBorder', 'cast', 'offensive', 'defensive' }) do
		if u[key] then u[key]:Hide() end
	end
	if u.dead then u.dead:SetText('') end
	if u.roleIcon then u.roleIcon:SetShown(u.def.kind == 'raid' or Theme:DB().roleIcons ~= false) end
	if u.trinket then
		u.trinket:SetShown(Theme:DB().trinketCircles ~= false)
		if ns.PvPFrames then ns.PvPFrames.PaintTrinket(u.trinket, 'READY') end
	end
end

local function ShowDispel(u, dispelType)
	if not u.dispel then return end
	local color = Preview.DISPEL[dispelType] or Preview.DISPEL.Magic
	if u.def.kind == 'raid' then
		for _, edge in ipairs(u.dispel.edges) do edge:SetVertexColor(color[1], color[2], color[3], 1) end
		u.dispel:Show()
	else
		ShowStateBorder(u.dispel, 'dispelEmphasis')
	end
	u.debuff.icon:SetTexture(DEBUFF_ICONS[dispelType] or DEBUFF_ICONS.Magic)
	u.debuff.border:SetVertexColor(color[1], color[2], color[3], 1)
	u.debuff:Show()
	u.dispelType = dispelType
end

local function ShowCC(u, kind, i)
	local cc = SAMPLE.cc[kind]
	if not (u.cc and cc) then return end
	local color = Preview.CC[cc[2]] or Preview.CC.STUN
	u.cc.icon:SetTexture(ICONS .. cc[1])
	u.cc.border:SetVertexColor(color[1], color[2], color[3], 1)
	u.cc.text:SetText(DEMO.CC_TIME[i] or '')
	u.cc:Show()
	if u.ccBorder then ShowStateBorder(u.ccBorder, 'ccEmphasis') end
end

local function ShowDead(u, label)
	Paint(u.Health, u.sample.color, 0)
	SetHealthText(u, '', '')
	if u.dead then
		u.dead:SetText(label)
		u.dead:SetTextColor(0.72, 0.74, 0.76)
	end
	u.name:SetTextColor(0.55, 0.57, 0.60)
	if u.circle and u.circle.icon then u.circle.icon:SetDesaturated(true) end
end

-- one unit in a state
function Preview.ApplyUnitState(key, u, i, state)
	Reset(u)
	local kind = u.def.kind
	local s = u.sample
	if state == 'NORMAL' then
		local dispel = DEMO.NORMAL.dispel[key] and DEMO.NORMAL.dispel[key][i]
		if dispel then ShowDispel(u, dispel) end
		if DEMO.NORMAL.range[key] and DEMO.NORMAL.range[key][i] then u:SetAlpha(Preview.RANGE_ALPHA) end
		if DEMO.NORMAL.cast[key] and DEMO.NORMAL.cast[key][i] and u.cast then
			Preview.SetCast(u.cast, kind == 'boss' and SAMPLE.bossCast or SAMPLE.casts[1], true, 0.62)
		end
	elseif state == 'LOW_HEALTH' then
		local level = 0.12 + 0.03 * ((i - 1) % 3)
		Paint(u.Health, s.color, level)
		SetHealthText(u, u.percentOnly and '' or Short(s.max * level), string.format('%d%%', math.floor(level * 100 + 0.5)))
	elseif state == 'OUT_OF_RANGE' then
		if kind ~= 'single' and kind ~= 'boss' then u:SetAlpha(Preview.RANGE_ALPHA) end
	elseif state == 'DEAD' then
		local label = DEMO.DEAD[key] and DEMO.DEAD[key][i]
		if label then ShowDead(u, label) end
	elseif state == 'CASTING' or state == 'CAST_LOCKED' or state == 'CHANNELING' then -- 1.3.0: a channel is a cast on the classic samples
		if u.cast and (kind ~= 'boss' or i == 1) then
			Preview.SetCast(u.cast, kind == 'boss' and SAMPLE.bossCast or SAMPLE.casts[((i - 1) % #SAMPLE.casts) + 1], state ~= 'CAST_LOCKED', 0.35 + 0.15 * i)
		end
	elseif state == 'CC_ALLY' or state == 'CC_ENEMY' then
		if DEMO[state][key] and DEMO[state][key][i] then ShowCC(u, kind, i) end
	elseif state == 'DISPELLABLE' then
		local dispel = DEMO.DISPELLABLE[key] and DEMO.DISPELLABLE[key][i]
		if dispel then ShowDispel(u, dispel) end
	elseif state == 'OFFENSIVE' then
		if u.offensive and i == 1 then u.offensive:Show() end
	elseif state == 'DEFENSIVE' then
		if u.defensive and i == 2 then u.defensive:Show() end
	elseif state == 'TRINKET_USED' or state == 'TRINKET_UNKNOWN' then
		if u.trinket and ns.PvPFrames then
			local used = state == 'TRINKET_USED' and DEMO.TRINKET_USED[i]
			ns.PvPFrames.PaintTrinket(u.trinket, (state == 'TRINKET_UNKNOWN' and 'UNKNOWN') or (used and 'USED') or 'READY')
		end
	end
	-- arena enemies: who is targeted / focused is part of every state
	if u.targetMark then
		u.targetMark:SetShown(i == 1 or i == 3)
		u.focusMark:SetShown(i == 2 or i == 3)
	end
end

function Preview:ApplyState(c)
	local state = self:State()
	if c.split then return ns.Split:ApplyPreviewState(c, state, self) end -- 1.3.0
	for i, u in ipairs(c.units) do Preview.ApplyUnitState(c.key, u, i, state) end
	self:Title(c)
end

-- the next state in the selector's order (BANZAI > PVP > NEXT STATE)
function Preview:NextState()
	local current = self:State()
	for i, state in ipairs(Preview.STATES) do
		if state == current then return self:SetState(Preview.STATES[i % #Preview.STATES + 1]) end
	end
	return self:SetState('NORMAL')
end

-- BANZAI > LAYOUT / PVP: the preview state shown on every preview
function Preview:SetState(state)
	if not Preview.STATE_LABELS[state] then state = 'NORMAL' end
	Theme:DB().previewState = state
	for _, c in pairs(frames) do self:ApplyState(c) end
	for _, c in pairs(variants) do self:ApplyState(c) end
	for _, c in pairs(splitFrames) do self:ApplyState(c) end
	if ns.CooldownBars and ns.CooldownBars:IsPreview() then ns.CooldownBars:Refresh() end
	return state
end

---------------------------------------------------------------------------
-- Builders
---------------------------------------------------------------------------
local function NewContainer(key, variant)
	local c = CreateFrame('Frame', 'BanzaiPreview_' .. key .. (variant and ('_' .. variant) or ''), UIParent)
	c:SetFrameStrata('DIALOG')
	c:SetFrameLevel(20)
	c:EnableMouse(false)
	c.units = {}
	c.key = key
	return c
end

function Preview:BuildSingle(key)
	local def = SINGLE[key]
	local c = NewContainer(key)
	local real = _G[def.frame]
	local db = UnitDB(def.unit)
	local scale = (key == 'targettarget') and (Theme:DB().totScale or 1) or 1
	local l, b, w, h = Rect(real)
	if l then
		c:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', l, b)
	else
		w, h = db.width or 200, db.height or 35
		Anchor(c, def.mover)
	end
	c:SetSize(w, h)
	-- health / power where the real frame has them, else the frame minus a thin resource line
	local layout = {}
	local hl, hbm, hw, hh = Rect(real and real.Health)
	if hl and l then
		layout.health = { hl - l, (b + h) - (hbm + hh), hw, hh }
	else
		layout.health = { 0, 0, w, math.max(8, h - 6) }
	end
	local pl, pbm, pw, ph = Rect(real and real.Power)
	if pl and l then
		layout.power = { pl - l, (b + h) - (pbm + ph), pw, ph }
	elseif key ~= 'pet' then
		layout.power = { 0, layout.health[4] + 1, w, 4 }
	end
	local nameDB = db.customTexts and db.customTexts['m-Name']
	local sample = Sample(def, 1, key)
	local textDef = def.percentOnly and COMPACT_TEXT or TextDef(def.frame)
	local design = ns.Compat and ns.Compat.DESIGN_WIDTH and ns.Compat.DESIGN_WIDTH[def.frame]
	local u = BuildUnit(c, sample, def, w, h, layout, PartsFor(def.frame), scale, textDef, nameDB, design)
	u:SetPoint('TOPLEFT', c, 'TOPLEFT', 0, 0)
	-- 1.0.0: the identity line as the live frame shows it (the spec on its own line on narrow frames)
	local specDB = db.customTexts and db.customTexts['b-Spec']
	if specDB and specDB.enable and def.identity and u.name then
		u.identityText = u.sample.label
		u.spec = Text(u.textLayer, specDB.size or 10)
		u.spec:SetPoint(specDB.justifyH or 'LEFT', u.Health, specDB.justifyH or 'LEFT', specDB.xOffset or 0, specDB.yOffset or 0)
		u.spec:SetText(u.sample.spec and Theme:GradientText(u.sample.spec, Theme.COLORS.lime, Theme.COLORS.emerald) or '')
	end
	Furnish(u, def, w, h, self:Role())
	c.units[1] = u
	self:ApplyState(c)
	return c
end

-- positions of `count` frames by the ElvUI group settings (growth, spacing, groups per row / column)
function Preview.GroupLayout(db, count, perGroup)
	local w, h = db.width or 120, db.height or 30
	local primary, secondary = string.match(db.growthDirection or 'DOWN', '^(%u+)_?(%u*)$')
	primary = primary or 'DOWN'
	local vs = db.verticalSpacing or db.spacing or 4
	local hs = db.horizontalSpacing or db.spacing or 4
	local groupsPer = math.max(1, db.groupsPerRowCol or 1)
	perGroup = perGroup or count
	local vertical = primary == 'DOWN' or primary == 'UP'
	local pos, maxX, maxY = {}, 0, 0
	for i = 1, count do
		local group, k = math.floor((i - 1) / perGroup), (i - 1) % perGroup
		local gCol, gRow = group % groupsPer, math.floor(group / groupsPer)
		local x, y
		if vertical then
			x = gCol * (w + hs)
			y = k * (h + vs) + gRow * (perGroup * (h + vs))
		else
			x = k * (w + hs) + gRow * (perGroup * (w + hs))
			y = gCol * (h + vs)
		end
		pos[i] = { x, y }
		maxX, maxY = math.max(maxX, x + w), math.max(maxY, y + h)
	end
	-- mirror for growth up / left
	for _, p in ipairs(pos) do
		if primary == 'UP' or secondary == 'UP' then p[2] = maxY - p[2] - h end
		if primary == 'LEFT' or secondary == 'LEFT' then p[1] = maxX - p[1] - w end
	end
	return pos, maxX, maxY, w, h
end

function Preview:BuildGroup(key)
	local def = GROUPS[key]
	local c = NewContainer(key, def.roleUnits and self:Role() or nil)
	local db = Preview.GroupDB(def)
	local count = def.count or ((db.numGroups or 4) * (def.perGroup or 5))
	local pos, totalW, totalH, w, h = Preview.GroupLayout(db, count, def.perGroup)
	c:SetSize(totalW, totalH)
	Anchor(c, def.mover, def.fallbackMover)
	c.db, c.role = db, self:Role()
	if def.roleUnits then variants[key .. ':' .. c.role] = c end
	local power = db.power
	local powerH = (key == 'raid' or key == 'boss' or (type(power) == 'table' and power.enable == false)) and 0 or 4 -- as the live frames (Bushido: no party / arena power bar)
	local layout = { health = { 0, 0, w, h - powerH - (powerH > 0 and 1 or 0) } }
	if powerH > 0 then layout.power = { 0, h - powerH, w, powerH } end
	local parts = def.parts and G[def.parts]
	local nameDB = db.customTexts and db.customTexts['m-Name']
	local textDef = (def.kind == 'raid') and COMPACT_TEXT or (def.text and GroupTextDef(def.text)) or SMALL_TEXT
	for i = 1, count do
		local sample = Sample(def, i, key)
		local u = BuildUnit(c, sample, def, w, h, layout, parts, 1, textDef, nameDB)
		u:SetPoint('TOPLEFT', c, 'TOPLEFT', pos[i][1], -pos[i][2])
		if def.kind == 'raid' then -- compact: short name inside the bar after the role icon
			u.name:ClearAllPoints()
			u.name:SetPoint('LEFT', u.Health, 'LEFT', 14, 0)
			u.name:SetFont(Theme:SmallFont(), 9, 'OUTLINE')
		end
		Furnish(u, def, w, h, c.role)
		c.units[i] = u
	end
	-- what this is, which layout and which preview state it shows
	c.title = c:CreateFontString(nil, 'OVERLAY')
	c.title:SetFont(Theme:SmallFont(), 10, 'OUTLINE')
	c.title:SetPoint('BOTTOMLEFT', c, 'TOPLEFT', 0, (def.kind == 'friendly' and c.role == 'HEALER') and 18 or 6)
	self:ApplyState(c)
	return c
end

function Preview:Title(c)
	local def = GROUPS[c.key]
	if not (def and c.title) then return end
	c.title:SetText(Theme:GradientText(def.title, Theme.COLORS.lime, Theme.COLORS.emerald) .. '|cff8c919a  -  ' .. (c.role or self:Role()) .. ' LAYOUT  -  PREVIEW: '
		.. Preview.STATE_LABELS[self:State()] .. '  -  SAMPLE DATA' .. (c.stacked and '  -  SHOWN ABOVE PARTY (SAME PLACE IN THE GAME)' or '') .. '|r')
end

-- BANZAI > LAYOUT: show the DPS or HEALER layout without a spec change.
-- Groups whose arrangement comes with the role (party, arena allies) are
-- built again in the new arrangement; the others move.
function Preview:SetRole(role)
	self.role = (role == 'HEALER' or role == 'DPS') and role or nil
	local rebuild = {}
	for key, c in pairs(frames) do
		local def = GROUPS[key]
		if def and def.roleUnits and c.role ~= self:Role() then
			rebuild[key] = c:IsShown()
			c:Hide()
		elseif def then
			Anchor(c, def.mover, def.fallbackMover)
			self:Title(c)
		end
	end
	-- 1.3.0: the split party / arena allies samples are built again in the new arrangement
	local again = {}
	for key, c in pairs(splitFrames) do
		if GROUPS[key] and c.role ~= self:Role() then
			again[key] = c:IsShown()
			c:Hide()
		end
	end
	for key, shown in pairs(again) do
		splitFrames[key] = nil
		if shown and self:Style() == 'SPLIT' then self:Show(key, true) end
	end
	for key, shown in pairs(rebuild) do
		local def = GROUPS[key]
		local c = variants[key .. ':' .. self:Role()]
		frames[key] = c -- built before in this arrangement: reused, else built when shown
		if c then
			Anchor(c, def.mover, def.fallbackMover)
			self:ApplyState(c)
			c:SetShown(shown)
		elseif shown then
			self:Show(key, true)
		end
	end
	self:Stack()
	return self:Role()
end

-- 0.9.0: party and arena allies are the same frames in the game (ElvUI's party
-- header, one position system). Shown together in the preview, the arena allies
-- sit just above the party instead of on top of it, and say so in their title.
function Preview:Stack()
	local party, allies = frames.party, frames.arenaAllies
	if not allies then return false end
	local def = GROUPS.arenaAllies
	allies:ClearAllPoints()
	if party and party:IsShown() and allies:IsShown() then
		if (allies.role or self:Role()) == 'HEALER' then
			allies:SetPoint('BOTTOM', party, 'TOP', 0, 52)
		else
			allies:SetPoint('BOTTOMLEFT', party, 'TOPLEFT', 0, 44)
		end
		allies.stacked = true
	else
		Anchor(allies, def.mover, def.fallbackMover)
		allies.stacked = nil
	end
	self:Title(allies)
	return allies.stacked == true
end

---------------------------------------------------------------------------
-- Show / hide
---------------------------------------------------------------------------
-- 1.3.0 the style the samples are drawn in: chosen here, else the session's
function Preview:Style()
	if self.style then return self.style end
	local split = ns.Split
	return (split and split.Session and split:Session()) and 'SPLIT' or 'CLASSIC'
end

-- the split builder draws this key in the style shown
local function SplitKey(self, key)
	local split = ns.Split
	return self:Style() == 'SPLIT' and split and split.PREVIEW and split.PREVIEW[key] and true or false
end

-- BANZAI > UNIT FRAMES > PREVIEW: the samples shown move to the other style
function Preview:SetStyle(style)
	style = (style == 'SPLIT') and 'SPLIT' or 'CLASSIC'
	local shown = {}
	for _, key in ipairs(self.TYPES) do if self:IsShown(key) then shown[#shown + 1] = key end end
	for _, key in ipairs(self.SPLIT_TYPES) do if self:IsShown(key) then shown[#shown + 1] = key end end
	for key, c in pairs(splitFrames) do c:Hide() if SINGLE[key] then Preview.Cover(key, false) end end
	for key, c in pairs(frames) do c:Hide() Preview.Cover(key, false) end
	self.style = style
	for _, key in ipairs(shown) do self:Show(key, true) end
	return style
end

function Preview:Get(key)
	if SplitKey(self, key) then return splitFrames[key] end
	return frames[key]
end

function Preview:IsShown(key)
	if key == Preview.COOLDOWNS then return ns.CooldownBars and ns.CooldownBars:IsPreview() or false end
	local c = self:Get(key)
	return c and c:IsShown() and true or false
end

function Preview:Show(key, show)
	if show and InCombatLockdown() then
		print('|cff00ccffBanzai|r: unit-frame preview is not available in combat.')
		return false
	end
	if key == Preview.COOLDOWNS then
		if ns.CooldownBars then ns.CooldownBars:SetPreview(show) end
		return ns.CooldownBars ~= nil
	end
	-- 1.3.0: the BANZAI SPLIT samples (their own set; pet, raid, arena enemies and boss stay the classic ones)
	if SplitKey(self, key) then
		local c = splitFrames[key]
		if show and not c then
			c = ns.Split:BuildPreview(key, self)
			splitFrames[key] = c
			if c then self:ApplyState(c) end
		end
		if c then c:SetShown(show and true or false) end
		if SINGLE[key] then Preview.Cover(key, show and true or false) end
		return c ~= nil
	end
	if not (SINGLE[key] or GROUPS[key]) then return false end
	local c = frames[key]
	if show and not c then
		c = SINGLE[key] and self:BuildSingle(key) or self:BuildGroup(key)
		frames[key] = c
		if ns.Compat and ns.Compat.ApplyTheme then ns.Compat:ApplyTheme() end -- paints the new bundles
	end
	if c then c:SetShown(show and true or false) end
	Preview.Cover(key, show and true or false)
	if key == 'party' or key == 'arenaAllies' then self:Stack() end
	return true
end

-- the real Player / Target / ... frame fades out while its preview sits on it
-- (alpha only; the secure frame is not moved, hidden or changed otherwise)
function Preview.Cover(key, covered)
	local def = SINGLE[key]
	local real = def and _G[def.frame]
	if not (real and real.SetAlpha) then return end
	if covered then
		if real.banzaiPreviewAlpha == nil then real.banzaiPreviewAlpha = real.GetAlpha and real:GetAlpha() or 1 end
		real:SetAlpha(0)
	elseif real.banzaiPreviewAlpha ~= nil then
		real:SetAlpha(real.banzaiPreviewAlpha)
		real.banzaiPreviewAlpha = nil
	end
end

function Preview:ShowAll()
	if InCombatLockdown() then return self:Show('player', true) end
	for _, key in ipairs(self.TYPES) do self:Show(key, true) end
	if self:Style() == 'SPLIT' then for _, key in ipairs(self.SPLIT_TYPES) do self:Show(key, true) end end -- 1.3.0
	self:Show(Preview.COOLDOWNS, true)
	return true
end

-- the PvP sets (BANZAI > PVP > PREVIEW): PARTY + ARENA = party, arena allies
-- and arena enemies; FRIENDLY = party + focus; ARENA = allies + enemies + focus
Preview.ARENA_SET = { 'party', 'arenaAllies', 'arenaEnemies' }
Preview.FRIENDLY_TYPES = { 'party', 'focus' }
Preview.PVP_TYPES = { 'arenaAllies', 'arenaEnemies', 'focus' }
local function ShowSet(self, keys)
	if InCombatLockdown() then return false end
	for _, key in ipairs(keys) do self:Show(key, true) end
	return true
end
function Preview:ShowArenaSet() return ShowSet(self, self.ARENA_SET) end
function Preview:ShowFriendly() return ShowSet(self, self.FRIENDLY_TYPES) end
function Preview:ShowPvP() return ShowSet(self, self.PVP_TYPES) end

function Preview:HideAll()
	for key, c in pairs(frames) do
		c:Hide()
		Preview.Cover(key, false)
	end
	for key, c in pairs(splitFrames) do -- 1.3.0
		c:Hide()
		Preview.Cover(key, false)
	end
	if ns.CooldownBars and ns.CooldownBars:IsPreview() then ns.CooldownBars:SetPreview(false) end
	return true
end

function Preview:AnyShown()
	for _, c in pairs(frames) do if c:IsShown() then return true end end
	for _, c in pairs(splitFrames) do if c:IsShown() then return true end end -- 1.3.0
	return ns.CooldownBars and ns.CooldownBars:IsPreview() or false
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_REGEN_DISABLED')
events:SetScript('OnEvent', function()
	if Preview:AnyShown() then
		Preview:HideAll()
		print('|cff00ccffBanzai|r: unit-frame preview hidden (combat).')
	end
end)
