--[[
	BANZAI - Options.lua
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	The BANZAI settings inside the ElvUI options window, registered through
	ElvUI's plugin library (LibElvUIPlugin-1.0: RegisterPlugin + an entry in
	E.Options.args, the same way Eltruism and mMediaTag add theirs). 1.0.0: one
	BANZAI application - the logo, UI BY HARDKORH and the version above a
	persistent list of pages on the left (AceConfig's own tree, Eltruism's
	arrangement), the chosen page on the right:

	  HOME              version, character, class, spec, role, master / sync state, components, apply / repair, reload
	  APPEARANCE        VIBRANT / CLASS, gradient, intensity, bamboo, smooth bars; 1.1.0 PANEL STYLE (bamboo border
	                    CLASS / BANZAI / HARDKORH x background SOLID / GLASS / PARCHMENT, border scale, glass opacity,
	                    parchment brightness); branding, fonts, text on the frames
	  UNIT FRAMES       Player / Target / Focus / ToT width and position, Focus / ToT / Pet, Party, Raid,
	                    Arena allies / enemies, Boss, role layouts, the unit-frame preview
	  PVP               party / arena frames, role icon, trinket, CC, dispel, casts,
	                    offensive / defensive cooldown bars, PvP preview states
	  ACTION BARS       circles or ElvUI squares, size, spacing, ring intensity, keybind / count size
	  LAYOUT            chat, Details, minimap, tracker, cast history, bottom panel, buffs, DPS / HEALER placement
	  CHARACTER SYNC    1.0.1: STATUS (this character with its pre-Banzai backup, the master, sync status,
	                    version), WHAT SYNCS (exact ownership, never synced), DIAGNOSTICS (components)
	  COMPONENTS        detected addons, ADDON REPLACEMENT STATUS (read-only), feature ownership
	  TOOLTIPS          theme, opacity, scale, bottom-panel and objective tooltips, anchors
	  AFK SCREEN        enable, model, rotation, speed, background, what is shown, branding, preview
	  BACKUP & RESTORE  the snapshot, pre-Banzai restore, character restore, what is never touched
	  ABOUT             BANZAI UI BY HARDKORH, version, release, credits

	The BANZAI wordmark at the top of the screen and /banzai open it on HOME
	(Options.Open: ElvUI's own ToggleOptions / AceConfigDialog, never in combat).
]]
local addonName, ns = ...
local T = ns.Transform

local Options = {}
ns.Options = Options

local MEDIA = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\'
local ICON = '|T' .. MEDIA .. 'BanzaiIcon:16:16:0:0|t'
local LIME, EMERALD, VIOLET, PURPLE = { 0.62, 1, 0.12 }, { 0, 0.9, 0.42 }, { 0.56, 0.22, 1 }, { 0.62, 0.1, 0.86 }
local MUTED = 'ff9aa0aa'

Options.COMPONENTS = {
	{ 'ElvUI', 'ElvUI' },
	{ 'ElvUI_EltreumUI', 'Eltruism' },
	{ 'ElvUI_mMediaTag', 'mMediaTag & Tools' },
	{ 'JiberishIcons', 'Jiberish Icons' },
	{ 'JiberishMedia', 'JiberishMedia' },
	{ 'Details', 'Details! Damage Meter' },
	{ '!KalielsTracker', 'Kaliel\'s Tracker' },
}

-- 0.7.0 ADDON REPLACEMENT STATUS: the result of a read-only inventory of
-- Darren's AddOns folder, his saved settings and Banzai's own code (27 Oct
-- 2026, 62 folders). { folder (state shown live), name, what it provides,
-- what Banzai does instead / still uses, recommendation }.
Options.REPLACEMENT = {
	REPLACED = {
		{ 'SexyMap', 'SexyMap', 'minimap skin', 'Banzai square bamboo minimap frame (ElvUI minimap). Banzai uses nothing of it.', 'Remove. Keep it off: it would fight the Banzai minimap frame.' },
		{ 'Chattynator', 'Chattynator', 'chat window replacement', 'ElvUI chat inside the Banzai chat frame. Banzai uses nothing of it.', 'Remove. Its saved data (about 11 MB) stays in WTF until deleted.' },
		{ 'MiniMeter', 'MiniMeter', 'FPS / latency / durability readout', 'Banzai bottom panel (FPS, MS, durability). Banzai uses nothing of it.', 'Remove.' },
		{ 'sArena_Reloaded', 'sArena Reloaded', 'arena enemy frames (with DR)', '1.0.1: no longer required by Banzai. Banzai\'s mirrored arena enemy frames are the only arena enemy system; DR is not a Banzai feature. Banzai uses nothing of it and never switches it on or off.', 'Remove or disable it yourself with WoW closed (Banzai deletes nothing).' },
		{ 'Masque', 'Masque + 11 Masque skins', 'button skins', 'Banzai circular action buttons. Banzai uses nothing of it.', 'Remove with its skins. Enabled, it would take ElvUI\'s action bars over the Banzai circles.' },
	},
	KEEP = {
		{ 'ElvUI', 'ElvUI (+ ElvUI Libraries, ElvUI Options)', 'unit frames, nameplates, action bars, chat, minimap', 'Banzai is an ElvUI profile and plugin; the BANZAI page lives in the ElvUI options.', 'Keep.' },
		{ 'ElvUI_EltreumUI', 'Eltruism', 'textures, nameplate extras, name tags', 'The Banzai profile uses its unit-frame textures, nameplate heights and name tags.', 'Keep.' },
		{ 'ElvUI_mMediaTag', 'mMediaTag & Tools', 'portraits, cast ring, health tags', 'Player / Target / Target-of-Target / Pet portraits with the Fabled Class icon, the health number tag.', 'Keep.' },
		{ '!mMT_MediaPack', 'mMT Media Pack', 'bar textures and fonts', 'The profile uses its "mMediaTag S1" and "MaUIv3" bars and the Montserrat-Bold font.', 'Keep. Without it those bars and fonts fall back to defaults.' },
		{ 'JiberishMedia', 'JiberishMedia', 'Jiberish fonts and Bushido textures', 'Banzai Art depends on it: GasoekOne, Rubik, the Bushido health textures.', 'Keep (Banzai deploys it).' },
		{ 'JiberishIcons', 'Jiberish Fabled Icons', 'Fabled class / spec artwork', 'The Player / Target class anchors and the Banzai identity circles (spec icons).', 'Keep.' },
		{ 'Details', 'Details! Damage Meter', 'damage / healing meter', 'Banzai lays out and styles its DAMAGE | HEALING windows.', 'Keep.' },
		{ '!KalielsTracker', 'Kaliel\'s Tracker', 'objective tracker', 'Replaced on screen by the Banzai tracker, but it still keeps Blizzard\'s own tracker hidden and is the fallback when the Banzai tracker is off. Banzai writes its visibility.', 'Keep.' },
		{ 'MinimapButtonButton', 'MinimapButtonButton', 'minimap button collector', 'Banzai places it in the top-right corner; Banzai has no collector of its own.', 'Keep.' },
	},
	NOT_REPLACED = {
		{ 'MiniAuras', 'MiniAuras (+ MiniCC bridge)', 'PvP crowd-control icons', 'Not replaced. MiniCC only carried old settings over; MiniAuras has them now.', 'Keep MiniAuras if wanted; MiniCC can go.' },
		{ 'ElvUI_WindTools', 'ElvUI WindTools', 'ElvUI extras (tracker, chat, minimap tools)', 'Not enabled; its tracker / chat / minimap features overlap Banzai.', 'Optional; keep it off with Banzai.' },
		{ 'Baganator', 'Baganator + Syndicator', 'bags and bank', 'Not replaced (ElvUI bags are off in the Banzai profile).', 'Keep.' },
		{ 'BlizzMove', 'BlizzMove, BugTabs', 'movable Blizzard windows, Lua error viewer', 'Not related to Banzai.', 'Keep or remove by preference.' },
		{ 'LibSharedMedia-3.0', 'LibSharedMedia-3.0', 'shared media library', 'Banzai uses the copies built into ElvUI and JiberishMedia.', 'Harmless; keep.' },
		{ 'Details_Compare2', 'Details! plugins (7)', 'optional Details extras', 'Not enabled; Banzai uses Details itself only.', 'Keep or remove by preference.' },
	},
	-- not related to Banzai at all: keep or remove by preference
	UNRELATED = 'DialogueUI, Glider, QueueSound, MiniTabTarget, CityGuide, EAAutoUnshift, FollowTheArrow, MassQuestAbandon, RCT + RdysDevTools, Reflux Enhanced (keep it off: it swaps saved variables), Spellid, TomTom, ZygorGuidesViewer. GSE_QoL and WeakAurasCompanion cannot load (their main addons are not installed). Darren\'s own separate HUD project stays as it is.',
}

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function Art()
	return _G.BanzaiCompat
end

local function PreviewModule()
	local art = Art()
	return art and art.Preview
end

local function Hex(c) return string.format('%02x%02x%02x', math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5)) end

local function Gradient(text, from, to)
	local art = Art()
	if art and art.Theme and art.Theme.GradientText then return art.Theme:GradientText(text, from, to) end
	return '|cff' .. Hex(from) .. text .. '|r'
end

local function Color(text, c) return '|cff' .. Hex(c) .. text .. '|r' end
local function Muted(text) return '|c' .. MUTED .. text .. '|r' end

local function Title(text) return Gradient(text, LIME, EMERALD) end

local function DB()
	_G.BushidoPrivateRestoreDB = _G.BushidoPrivateRestoreDB or {}
	local db = _G.BushidoPrivateRestoreDB
	db.characters = db.characters or {}
	db.layout = db.layout or {}
	db.fonts = db.fonts or {}
	return db
end

local function Record()
	local E = Engine()
	return E and E.mynameRealm and DB().characters[E.mynameRealm]
end

local function Profile()
	return _G.ElvDB and _G.ElvDB.profiles and _G.ElvDB.profiles[T.PROFILE]
end

local function Notify()
	local E = Engine()
	local registry = E and E.Libs and E.Libs.AceConfigRegistry
	if registry and registry.NotifyChange then registry:NotifyChange('ElvUI') end
end

local function UpdateUnitFrames()
	local E = Engine()
	local UF = E and E.GetModule and E:GetModule('UnitFrames', true)
	if UF and UF.Update_AllFrames and not InCombatLockdown() then pcall(UF.Update_AllFrames, UF) end
end

---------------------------------------------------------------------------
-- Status helpers (also used by the tests)
---------------------------------------------------------------------------
function Options.ComponentState(folder)
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(folder)
	if loaded then return 'active' end
	if not (C_AddOns and C_AddOns.GetAddOnInfo) then return 'missing' end
	local reason = select(5, C_AddOns.GetAddOnInfo(folder))
	if reason == 'MISSING' then return 'missing' end
	return 'detected'
end

function Options.ComponentLines()
	local lines, active = {}, 0
	for _, c in ipairs(Options.COMPONENTS) do
		local state = Options.ComponentState(c[1])
		local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(c[1], 'Version')
		local label = (state == 'active' and Color('ACTIVE', EMERALD)) or (state == 'detected' and Color('DETECTED - NOT ENABLED', { 1, 0.8, 0.2 })) or Color('MISSING', { 1, 0.3, 0.3 })
		if state == 'active' then active = active + 1 end
		lines[#lines + 1] = string.format('%s   %s   %s', Color(c[2], { 1, 1, 1 }), label, Muted(version and ('v' .. tostring(version):gsub('^v', '')) or ''))
	end
	return table.concat(lines, '\n'), active, #Options.COMPONENTS
end

-- one section of ADDON REPLACEMENT STATUS: name, live state, what it was / does, recommendation
function Options.ReplacementText(kind)
	local states = { active = Color('LOADED', EMERALD), detected = Color('INSTALLED, NOT ENABLED', { 1, 0.8, 0.2 }), missing = Muted('NOT INSTALLED') }
	local lines = {}
	for _, entry in ipairs(Options.REPLACEMENT[kind] or {}) do
		local folder, name, provides, banzai, advice = entry[1], entry[2], entry[3], entry[4], entry[5]
		lines[#lines + 1] = Color(name, { 1, 1, 1 }) .. '   ' .. (states[Options.ComponentState(folder)] or '') .. '   ' .. Muted(provides)
		lines[#lines + 1] = '      ' .. banzai
		lines[#lines + 1] = '      ' .. Color(advice, LIME)
		lines[#lines + 1] = ' '
	end
	return table.concat(lines, '\n')
end

local function SpecName()
	local index = GetSpecialization and GetSpecialization()
	if not index then return '-' end
	local _, name = GetSpecializationInfo(index)
	return name or '-'
end

function Options.HomeText()
	local E = Engine()
	local record = Record()
	local _, classFile = UnitClass('player')
	local className = UnitClass('player')
	local art = Art()
	local classColor = (art and art.Theme and art.Theme:ClassColor(classFile)) or { 1, 1, 1 }
	local _, active, total = Options.ComponentLines()
	local master = ns.Sync and ns.Sync:Master()
	local lines = {
		Muted('VERSION') .. '   ' .. Color('BANZAI ' .. tostring(ns.VERSION), EMERALD) .. '   ' .. Muted('release'),
		Muted('CHARACTER') .. '   ' .. tostring(E and E.mynameRealm or UnitName('player')),
		Muted('CLASS') .. '   ' .. Color(tostring(className or '-'), classColor),
		Muted('SPECIALIZATION') .. '   ' .. Color(tostring(SpecName()), classColor),
		Muted('SPEC ROLE') .. '   ' .. Color(Options.CurrentRole(), EMERALD),
		Muted('ELVUI PROFILE') .. '   ' .. tostring(E and E.data and E.data:GetCurrentProfile() or '-'),
		Muted('BANZAI') .. '   ' .. ((record and record.applied) and Color('ACTIVE  (applied ' .. tostring(record.applied.time) .. ')', EMERALD) or Color('NOT APPLIED ON THIS CHARACTER', { 1, 0.8, 0.2 })),
		Muted('CHARACTER SYNC') .. '   ' .. Options.SyncBadge(),
		Muted('BANZAI MASTER') .. '   ' .. (master and tostring(master.key) or Muted('none yet')),
		Muted('FRAME THEME') .. '   ' .. tostring(art and art:GetTheme() or '-'),
		Muted('COMPONENTS') .. '   ' .. (active == total and Color(string.format('%d of %d active', active, total), EMERALD) or Color(string.format('%d of %d active', active, total), { 1, 0.8, 0.2 })),
	}
	return table.concat(lines, '\n')
end

---------------------------------------------------------------------------
-- Roles and Character Sync (Roles.lua, Sync.lua)
---------------------------------------------------------------------------
function Options.CurrentRole()
	return (ns.Roles and ns.Roles.Current()) or 'DPS'
end

local BADGE_COLORS = { MASTER = PURPLE, SYNCED = EMERALD, UPDATE = { 1, 0.8, 0.2 }, NOT_SYNCED = { 1, 0.45, 0.35 }, NO_MASTER = LIME }
function Options.SyncState()
	return ns.Sync and ns.Sync:State() or 'NOT_SYNCED'
end

function Options.SyncBadge(state)
	state = state or Options.SyncState()
	local text = ns.Sync and ns.Sync.STATES[state] or state
	return Color(text, BADGE_COLORS[state] or { 1, 1, 1 })
end

local function ClassColored(text, token)
	local art = Art()
	return Color(tostring(text or '-'), (art and art.Theme and art.Theme:ClassColor(token)) or { 1, 1, 1 })
end

-- THIS CHARACTER card
function Options.SyncIdentity()
	local who = ns.Sync and ns.Sync:Identity() or {}
	return table.concat({
		ClassColored(who.key, who.classToken),
		ClassColored(who.class, who.classToken) .. '   ' .. Muted(string.upper(tostring(who.spec or '-'))) .. '   ' .. Color(tostring(who.role or 'DPS'), EMERALD),
	}, '\n')
end

function Options.SyncDetail()
	local state = Options.SyncState()
	local record = Record()
	if state == 'NOT_SYNCED' then return Muted('APPLY BANZAI brings the approved Banzai setup to this character. Your current setup is saved first.') end
	if state == 'UPDATE' then return Muted('The master has a newer Banzai setup. Nothing changes until you choose UPDATE CHARACTER.') end
	if state == 'MASTER' then return Muted('Your other characters take their Banzai setup from this one.') end
	if state == 'NO_MASTER' then return Muted('Banzai runs here. Set a master below so your other characters can follow it.') end
	local sync = record and record.sync
	return Muted('In step with the master' .. (sync and sync.time and (' since ' .. tostring(sync.time)) or '') .. '.')
end

local CLASS_ICONS = 'Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES'
function Options.ClassIcon()
	local _, token = UnitClass('player')
	local coords = token and _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[token]
	return coords and CLASS_ICONS or (MEDIA .. 'BanzaiIcon')
end

function Options.ClassCoords()
	local _, token = UnitClass('player')
	local coords = token and _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[token]
	return coords or { 0, 1, 0, 1 }
end

-- BANZAI MASTER card
function Options.MasterText()
	local master = ns.Sync and ns.Sync:Master()
	if not master then
		return Color('NO BANZAI MASTER SET', { 1, 1, 1 }) .. '\n' .. Muted('On the character whose Banzai setup you approve, press SET AS BANZAI MASTER. Banzai never sets a master by itself.')
	end
	return table.concat({
		ClassColored(master.key, master.classToken),
		ClassColored(master.class, master.classToken) .. '   ' .. Muted(string.upper(tostring(master.spec or '-'))) .. '   ' .. Color(tostring(master.role or 'DPS'), EMERALD),
		Muted('BANZAI') .. ' ' .. Color(tostring(master.version or '-'), EMERALD) .. '   ' .. Muted('SCHEMA') .. ' ' .. Color(tostring(master.schema or 1), EMERALD)
			.. '   ' .. Muted('CONFIGURATION') .. ' ' .. Color('#' .. tostring(master.revision or 0), LIME) .. '   ' .. Muted('CAPTURED') .. ' ' .. tostring(master.captured or '-'),
	}, '\n')
end

-- the confirmation before APPLY BANZAI / UPDATE CHARACTER: what it applies and what it never changes
function Options.PlanText()
	local lines = {}
	for _, line in ipairs(ns.Sync and ns.Sync:Plan() or {}) do
		lines[#lines + 1] = string.find(line, '^BANZAI') and Color(line, { 1, 1, 1 }) or Muted(line)
	end
	return table.concat(lines, '\n')
end

-- PRE-BANZAI BACKUP: READY (or not taken yet), and the last failure on this character
function Options.BackupLine()
	local record = Record()
	local previous = record and record.previous
	local line
	if previous and previous.time then
		line = Color('PRE-BANZAI BACKUP: READY', EMERALD) .. Muted('  (taken ' .. tostring(previous.time) .. ')')
	else
		line = Muted('PRE-BANZAI BACKUP: not taken yet - APPLY BANZAI takes it first, before anything changes, and stops if it fails.')
	end
	local E = Engine()
	local failed = ns.Sync and ns.Sync.lastError
	if failed and E and failed.key == E.mynameRealm then line = line .. '\n' .. Color(tostring(failed.text), { 1, 0.3, 0.3 }) end
	return line
end

-- SYNC STATUS: master, versions, this character, its own class / spec / role, the configuration it took
function Options.SyncStatusText()
	local S = ns.Sync
	if not S then return '' end
	local master = S:Master()
	local who = S:Identity()
	local record = Record()
	local sync = record and record.sync
	local function row(label, value) return Muted(label) .. '   ' .. value end
	local white = { 1, 1, 1 }
	return table.concat({
		row('MASTER', master and ClassColored(master.key, master.classToken) or Color('NO BANZAI MASTER SET', white)),
		row('MASTER BANZAI VERSION', master and Color(tostring(master.version or '-'), EMERALD) or Muted('-')),
		row('THIS CHARACTER', Color(tostring(who.key or '-'), white)),
		row('CLASS', ClassColored(who.class, who.classToken)),
		row('SPEC', Color(string.upper(tostring(who.spec or '-')), white)),
		row('ROLE', Color(tostring(who.role or 'DPS'), EMERALD)),
		row('APPLIED CONFIGURATION', sync and Color('BANZAI ' .. tostring(sync.version or '-') .. ', schema ' .. tostring(sync.schema or 1) .. ', #' .. tostring(sync.revision or 0)
			.. (sync.time and (', ' .. tostring(sync.time)) or ''), EMERALD) or Muted('none')),
		row('SYNC STATE', Options.SyncBadge()),
	}, '\n')
end

-- WHAT SYNCS: the exact ownership and what is never synced
function Options.OwnershipSyncText()
	local lines = {}
	for _, row in ipairs(ns.Sync and ns.Sync.OWNERSHIP or {}) do lines[#lines + 1] = Color(row[1], { 1, 1, 1 }) .. '\n      ' .. Muted(row[2]) end
	return table.concat(lines, '\n')
end

-- SYNC DIAGNOSTICS: READY / MISSING / SKIPPED / ERROR per component
function Options.DiagnosticsText()
	local colors = { READY = EMERALD, SKIPPED = { 0.62, 0.64, 0.70 }, MISSING = { 1, 0.3, 0.3 }, ERROR = { 1, 0.3, 0.3 } }
	local lines = {}
	for _, c in ipairs(ns.Sync and ns.Sync:Diagnostics() or {}) do
		local state = c.state
		if state == 'MISSING' and not c.required then state = 'SKIPPED' end
		lines[#lines + 1] = Color(c.name, { 1, 1, 1 }) .. '   ' .. Color(state, colors[state] or { 1, 1, 1 }) .. (c.required and Muted('   required') or '')
	end
	lines[#lines + 1] = Muted('A required component that is not READY stops APPLY BANZAI / UPDATE CHARACTER; an optional one that is missing is skipped.')
	return table.concat(lines, '\n')
end

function Options.CharactersText()
	local lines = {}
	for _, c in ipairs(ns.Sync and ns.Sync:Characters() or {}) do
		if c.state ~= 'NOT_SYNCED' then lines[#lines + 1] = Color(c.key, { 1, 1, 1 }) .. '   ' .. Options.SyncBadge(c.state) end
		if #lines >= 12 then break end
	end
	return #lines > 0 and table.concat(lines, '\n') or Muted('No character runs Banzai yet.')
end

local function SyncRun(fn)
	return function()
		local ok, message = fn(ns.Sync)
		if not ok and message then print('|cff00ccffBanzai|r: ' .. message) end
		Notify()
	end
end

---------------------------------------------------------------------------
-- Profile edits (unit-frame text, positions)
---------------------------------------------------------------------------
local HEALTH_UNITS = { 'player', 'target', 'focus', 'party', 'arena' }
local INSIDE = {} -- units whose health sits inside the bar (BushidoPrivateCompat Health.lua) while that is on
for _, unit in ipairs(T.HEALTH_INSIDE_UNITS) do INSIDE[unit] = true end

local function Texts(unit)
	local p = Profile()
	local units = p and p.unitframe and p.unitframe.units
	return units and units[unit] and units[unit].customTexts
end

function Options.HealthInside()
	local art = Art()
	return art and art:Get('healthInside') and true or false
end

function Options.GetPercent()
	local art = Art()
	if Options.HealthInside() then return art:Get('healthPercent') ~= false end
	local player = Texts('player')
	local mark = player and player['b-SplitName']
	if mark and (mark.enable or mark.banzaiSplit) then return art:Get('healthPercent') ~= false end -- 1.3.0: the split layer hides the classic text (1.3.1: its marker)
	local texts = Texts('player')
	return not (texts and texts['b-HealthPct'] and texts['b-HealthPct'].enable == false)
end

function Options.SetPercent(value)
	ns.Restore:ClassicEdit(function() -- 1.3.0: over the classic values (BANZAI SPLIT is written again after it)
		local inside = Options.HealthInside()
		for _, unit in ipairs(HEALTH_UNITS) do
			local texts = Texts(unit)
			if texts and texts['b-HealthPct'] and not (inside and INSIDE[unit]) then texts['b-HealthPct'].enable = value and true or false end
		end
		local art = Art()
		if art then art:Set('healthPercent', value and true or false) end
	end)
	UpdateUnitFrames()
end

-- 1.0.0: on the narrow frames the spec has its own line ('b-Spec' under the name)
function Options.GetSpecNames()
	local texts = Texts('player')
	local line = texts and texts['b-SplitName'] -- 1.3.0: the split name line while the profile carries BANZAI SPLIT
	if line and line.banzaiSplit then return line.banzaiSpec == true end -- 1.3.1: the marker says whether the spec line shows
	if line and line.enable then return string.find(line.text_format or '', 'banzai:spec', 1, true) ~= nil end
	if not (texts and texts['m-Name']) then return true end
	if texts['b-Spec'] and texts['b-Spec'].enable then return true end
	return string.find(texts['m-Name'].text_format or '', 'banzai:spec', 1, true) ~= nil
end

function Options.SetSpecNames(value)
	ns.Restore:ClassicEdit(function() -- 1.3.0: the classic lines decide; the split line follows them
		for unit, line in pairs(T.IDENTITY_SPLIT) do
			local texts = Texts(unit)
			if texts and texts['m-Name'] then
				texts['m-Name'].text_format = value and T.IDENTITY[unit] or line.name
				if texts['b-Spec'] then texts['b-Spec'].enable = value and true or false end
			end
		end
		local p = Profile()
		if p then T.ApplyIdentityLines(p, Options.FrameWidth() < 1) end
	end)
	UpdateUnitFrames()
end

function Options.FrameWidth()
	local art = Art()
	return T.FrameWidth(art and art:Get('frameWidth'))
end

function Options.SquareButtons()
	local art = Art()
	return art and art:Get('actionStyle') == 'ELVUI' or false
end

-- 1.2.0: the keybind size applies to the circles' large centred keybind only (the square keeps a compact one at the top-right)
function Options.NotCircles()
	local art = Art()
	return not (art and art:Get('actionStyle') == 'CIRCLE')
end

function Options.BuffsOff()
	local art = Art()
	return not (art and art:Get('buffsPanel'))
end

function Options.ElvUITooltips()
	local art = Art()
	return art and art:Get('tooltipTheme') == 'ELVUI' or false
end

function Options.PreviewAFK()
	local art = Art()
	if art and art.AFK and art.AFK.Preview then return art.AFK:Preview() end
	return false
end

function Options.GetHealthSize()
	local texts = Texts('player')
	return texts and texts['m-Health'] and texts['m-Health'].size or 20
end

function Options.SetHealthSize(value)
	ns.Restore:ClassicEdit(function()
		for _, unit in ipairs({ 'player', 'target' }) do
			local texts = Texts(unit)
			if texts and texts['m-Health'] then texts['m-Health'].size = value end
		end
	end)
	UpdateUnitFrames()
end

-- Player / Target height and spread on top of their 1.0.0 width (Transform T.ApplyFrameWidths)
function Options.SetUnitLayout(height, spread)
	return ns.Restore:SetUnitLayout(height, spread)
end

-- 1.0.0: the BANZAI settings on a page (the BANZAI wordmark: HOME). ElvUI's
-- own ToggleOptions opens the window (loading ElvUI_Options when needed);
-- an open window is reused - the page is selected in it, nothing new opens.
-- BANZAI is a tree inside ElvUI's hidden root tree, so the page is chosen in
-- the BANZAI tree's own status (AceConfigDialog:GetStatusTable) before the
-- BANZAI category is selected. Never in combat: a short message, nothing
-- queued for later.
Options.PAGE_KEYS = {}
for _, p in ipairs({ 'home', 'appearance', 'unitframes', 'pvp', 'actionbars', 'layout', 'sync', 'components', 'tooltips', 'afk', 'backup', 'about' }) do Options.PAGE_KEYS[p] = true end
function Options.Open(page)
	page = Options.PAGE_KEYS[page] and page or 'home'
	if InCombatLockdown() then
		print('|cff00ccffBanzai|r: settings cannot open in combat.')
		return false
	end
	local E = Engine()
	local ACD = E and E.Libs and E.Libs.AceConfigDialog
	if not (E and E.ToggleOptions) then return false end
	if ACD and ACD.GetStatusTable then
		local status = ACD:GetStatusTable('ElvUI', { 'banzai' })
		status.groups = status.groups or {}
		status.groups.selected = page
	end
	if ACD and ACD.OpenFrames and ACD.OpenFrames.ElvUI and ACD.SelectGroup then
		return (pcall(ACD.SelectGroup, ACD, 'ElvUI', 'banzai'))
	end
	return (pcall(E.ToggleOptions, E, 'banzai'))
end
_G.BanzaiOpenSettings = Options.Open -- the BANZAI wordmark (BushidoPrivateCompat) calls this

---------------------------------------------------------------------------
-- The options table: one BANZAI application inside the ElvUI options
---------------------------------------------------------------------------
-- 1.0.0: the BANZAI category is a tree (Eltruism's arrangement): the twelve
-- pages stay listed on the left, the chosen page fills the right. One scroll
-- per page (AceConfig's own), sections drawn as titled cards, every control
-- built by the same few helpers below so they look and size alike. Green /
-- purple is the identity; amber / red only ever mark a warning.
Options.PAGES = {
	{ 'home', 'HOME' }, { 'appearance', 'APPEARANCE' }, { 'unitframes', 'UNIT FRAMES' }, { 'pvp', 'PVP' },
	{ 'actionbars', 'ACTION BARS' }, { 'layout', 'LAYOUT' }, { 'sync', 'CHARACTER SYNC' }, { 'components', 'COMPONENTS' },
	{ 'tooltips', 'TOOLTIPS' }, { 'afk', 'AFK SCREEN' }, { 'backup', 'BACKUP & RESTORE' }, { 'about', 'ABOUT' },
}
local WIDTH = 1.15 -- every toggle, slider, select and button

local function Header(order, text) return { order = order, type = 'header', name = Title(text) } end
local function Text(order, text, size) return { order = order, type = 'description', name = text, fontSize = size or 'medium', width = 'full' } end
local function Space(order) return { order = order, type = 'description', name = ' ', width = 'full' } end
local function Section(order, title, args) return { order = order, type = 'group', inline = true, name = Title(title), args = args } end
local function Tab(order, name, args) return { order = order, type = 'group', name = name, args = args } end

local function Control(kind, order, name, desc, get, set, extra)
	local option = { order = order, type = kind, name = name, desc = desc, width = WIDTH, get = get, set = set }
	for k, v in pairs(extra or {}) do option[k] = v end
	return option
end
local function Toggle(order, name, desc, get, set, extra) return Control('toggle', order, name, desc, get, set, extra) end
local function Range(order, name, desc, min, max, step, get, set, extra)
	local option = Control('range', order, name, desc, get, set, extra)
	option.min, option.max, option.step = min, max, step
	return option
end
local function Select(order, name, desc, values, sorting, get, set, extra)
	local option = Control('select', order, name, desc, get, set, extra)
	option.values, option.sorting = values, sorting
	return option
end
local function Button(order, name, desc, func, extra)
	local option = { order = order, type = 'execute', name = name, desc = desc, width = WIDTH, func = func }
	for k, v in pairs(extra or {}) do option[k] = v end
	return option
end

local function ArtGet(key) return function() local art = Art() return art and art:Get(key) end end
local function ArtSet(key) return function(_, value) local art = Art() if art then art:Set(key, value) end Notify() end end
-- a Banzai Art setting drawn live (no reload)
local function ArtToggle(order, key, name, desc, extra) return Toggle(order, name, desc, ArtGet(key), ArtSet(key), extra) end
local function ArtRange(order, key, name, desc, min, max, step, extra) return Range(order, name, desc, min, max, step, ArtGet(key), ArtSet(key), extra) end

---------------------------------------------------------------------------
-- 1.3.0 FRAME STYLE / BANZAI SPLIT / METER STYLE
---------------------------------------------------------------------------
function Options.FrameStyle()
	local art = Art()
	return T.FrameStyle(art and art:Get('frameStyle'))
end

function Options.NotSplit() return Options.FrameStyle() ~= 'SPLIT' end

-- the style this session runs and the one chosen (they differ until the reload)
function Options.FrameStyleText()
	local art = Art()
	local session = art and art.Split and art.Split.Session and art.Split:Session()
	local now = session and 'SPLIT' or 'CLASSIC'
	local chosen = Options.FrameStyle()
	local text = Muted('This session: ') .. Color('BANZAI ' .. now, EMERALD)
	if chosen ~= now then text = text .. Muted('   -   chosen: ') .. Color('BANZAI ' .. chosen, { 1, 0.8, 0.2 }) .. Muted(' (a reload applies it)') end
	return text
end

-- BANZAI SPLIT choices go through Banzai (it writes the ElvUI side while SPLIT is the style)
local function SplitGet(key) return function() local art = Art() return art and art:Get(key) end end
local function SplitSet(key) return function(_, value) ns.Restore:SetSplit(key, value) Notify() end end
function Options.SplitRange(order, key, name, desc, min, max, step, extra)
	return Range(order, name, desc, min, max, step, SplitGet(key), SplitSet(key), extra)
end
function Options.SplitToggle(order, key, name, desc)
	return Toggle(order, name, desc, SplitGet(key), SplitSet(key))
end

-- shows the BANZAI SPLIT samples (labelled SAMPLE DATA) without changing the live style
function Options.PreviewSplit()
	local p = PreviewModule()
	if not p then return false end
	if p.SetStyle then p:SetStyle('SPLIT') end
	for _, key in ipairs({ 'player', 'target', 'targettarget', 'focus', 'party', 'targetNPC', 'nameplate' }) do p:Show(key, true) end
	return true
end

local function FontValues()
	local lists = _G.AceGUIWidgetLSMlists
	if lists and lists.font then return lists.font end
	local media = _G.LibStub and _G.LibStub('LibSharedMedia-3.0', true)
	return media and media:HashTable('font') or {}
end

-- one toggle per preview type (BANZAI > UNIT FRAMES > PREVIEW)
function Options.PreviewToggle(order, key, extra)
	local art = Art()
	local labels = art and art.Preview and art.Preview.LABELS
	local option = { order = order, type = 'toggle', width = 0.8, name = (labels and labels[key]) or key,
		get = function() local p = PreviewModule() return p and p:IsShown(key) or false end,
		set = function(_, v) local p = PreviewModule() if p then p:Show(key, v) end Notify() end }
	for k, v in pairs(extra or {}) do option[k] = v end
	return option
end

local function PreviewStates()
	local p = PreviewModule()
	local out = {}
	for key, label in pairs(p and p.STATE_LABELS or { NORMAL = 'NORMAL' }) do out[key] = label end
	return out
end

local function PreviewStateOrder()
	local p = PreviewModule()
	return p and p.STATES or { 'NORMAL' }
end

-- the preview-state selector (UNIT FRAMES and PVP share it)
function Options.PreviewState(order, width)
	return { order = order, type = 'select', width = width or WIDTH, name = 'Preview state',
		desc = 'Synthetic visual states on every sample frame (SAMPLE DATA). They show the design only: a state shown here is not proof that the live game exposes that data.',
		values = PreviewStates, sorting = PreviewStateOrder,
		get = function() local p = PreviewModule() return p and p:State() or 'NORMAL' end,
		set = function(_, v) local p = PreviewModule() if p then p:SetState(v) end Notify() end }
end

local function PreviewRole(order)
	return Select(order, 'Layout', 'Shows the sample frames where the DPS or the HEALER layout puts them, without changing your spec.',
		{ DPS = 'DPS', HEALER = 'HEALER' }, { 'DPS', 'HEALER' },
		function() local p = PreviewModule() return (p and p.Role and p:Role()) or Options.CurrentRole() end,
		function(_, v) local p = PreviewModule() if p and p.SetRole then p:SetRole(v) end Notify() end)
end

local function PreviewRun(fn)
	return function()
		local p = PreviewModule()
		if p then fn(p) end
		Notify()
	end
end

---------------------------------------------------------------------------
-- PVP (0.8.0; 0.9.0 sections; 1.0.0: three tabs)
---------------------------------------------------------------------------
-- the arena enemies (1.0.1: Banzai's mirrored frames are the only arena enemy system)
function Options.ArenaText()
	return Color('ARENA ENEMIES:  ', EMERALD) .. Color('Banzai mirrored frames', { 1, 1, 1 }) .. Muted('  (right edge: trinket | health | class / spec circle, cast bar above, target / focus outline). The only arena enemy system; DR is not a Banzai feature.')
end

Options.PVP_TEXT = {
	size = 'DPS: party and arena allies 100 wide (half of Bushido\'s 200) at full height, on the left edge in line with the raid frames. HEALER: the central row just above Player / Target, 100 wide and 30 % lower. Each frame: class / spec circle | health bar (HP + % at the left, role icon at the right end) | trinket circle. Arena enemies mirror them on the right edge. No ordinary buffs, debuff rows or DR on party frames. Positions: kept per role (LAYOUT > DPS / HEALER PLACEMENT).',
	role = 'mMediaTag\'s [mMT-role:icon] inside the right end of each party / arena ally bar.',
	trinket = 'A circle the size of the class / spec circle: right of allies, left of enemies. The state is the game\'s own arena trinket data, only inside arenas: AVAILABLE (bright ring), USED (greyed, the game\'s cooldown swipe), UNKNOWN (dimmed). No timer is invented.',
	cc = 'Crowd control from the game\'s own CROWD_CONTROL category: a large icon inside the ally\'s bar (over the enemy\'s class circle), its time where the game gives one - ElvUI\'s own icon. 1.3.4: Banzai no longer draws its magenta border and CC label on the live frames (the game restricts that icon\'s frames in arenas and battlegrounds); the level below shapes the preview samples only.',
	dispel = 'A harmful effect this character can dispel (the game\'s RAID_PLAYER_DISPELLABLE): a compact icon below the frame\'s right end and ElvUI\'s glow. 1.3.4: Banzai no longer draws its cyan border and DISPEL label on the live frames; the level below shapes the preview samples only. Health and name stay clear.',
	casts = 'Interruptible: attention amber. Not interruptible: restrained steel violet with a shield. Arena enemies and Boss: a cast bar above each frame; Focus keeps its own.',
	cooldowns = 'Your own major cooldowns only, as compact bars: OFFENSIVE between the chat and the action bars, DEFENSIVE between the action bars and Details. A bar is there only while its spell cools down; empty groups are not drawn. The time is the game\'s own; enemy cooldowns are never guessed.',
}

local function PvPToggle(order, key, name, desc)
	return Toggle(order, name, desc .. ' A reload applies it.',
		function() local art = Art() local v = art and art:Get(key) if v == nil then return true end return v end,
		function(_, v) ns.Restore:SetPvP(key, v) Notify() end)
end

-- a Banzai Art setting the preview follows at once
local function ArtSetting(order, kind, key, name, extra)
	local option = { order = order, type = kind, name = name, width = WIDTH, get = ArtGet(key),
		set = function(_, v)
			local art = Art()
			if art then art:Set(key, v) end
			local p = PreviewModule()
			if p and p.SetState and p.State then p:SetState(p:State()) end
			Notify()
		end }
	for k, v in pairs(extra or {}) do option[k] = v end
	return option
end

local EMPHASIS = { STRONG = 'STRONG - border, label, pulse', CLEAR = 'CLEAR - border, label', MINIMAL = 'MINIMAL - icon only' }
local EMPHASIS_ORDER = { 'STRONG', 'CLEAR', 'MINIMAL' }

local function CooldownBars()
	local art = Art()
	return art and art.CooldownBars
end

-- the tracked cooldowns of a group: this character's known spells of BANZAI's list
function Options.CooldownValues(kind)
	local bars = CooldownBars()
	local out = {}
	for _, id in ipairs(bars and bars:Candidates(kind) or {}) do
		local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id)
		local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id)
		out[id] = (icon and ('|T' .. icon .. ':14:14:0:0:64:64:5:59:5:59|t ') or '') .. tostring(name or id)
	end
	return out
end

local function Tracked(order, kind)
	return { order = order, type = 'multiselect', width = 'full', name = 'Tracked ' .. string.lower(kind) .. ' cooldowns',
		desc = 'Your known spells from Banzai\'s list for your class, in priority order. Unticked spells never get a bar.',
		values = function() return Options.CooldownValues(kind) end,
		get = function(_, id)
			local bars = CooldownBars()
			if not bars then return false end
			for i, known in ipairs(bars:Candidates(kind)) do
				if known == id then return bars:IsTracked(kind, id, i) end
			end
			return false
		end,
		set = function(_, id, v) local bars = CooldownBars() if bars then bars:SetTracked(id, v) end Notify() end }
end

function Options.PvPGroup()
	return {
		order = 40, type = 'group', name = 'PVP', childGroups = 'tab',
		args = {
			intro = Text(1, Muted('PvP-first unit frames and your own cooldown bars, also used in PvE. Everything comes from ElvUI\'s own frames and the game\'s own categories; nothing hidden by the game is guessed.')),
			frames = Tab(10, 'FRAMES', {
				size = Section(10, 'PARTY / ARENA FRAME SIZE', {
					text = Text(1, Muted(Options.PVP_TEXT.size)),
					owner = { order = 2, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.ArenaText() end },
					defensives = PvPToggle(4, 'pvpDefensives', 'Enemy offensive / defensive icons', 'Their big / external defensives and important buffs, left of the trinket.'),
				}),
				role = Section(20, 'ROLE ICON', {
					text = Text(1, Muted(Options.PVP_TEXT.role)),
					toggle = PvPToggle(2, 'roleIcons', 'Role icon in the bar', 'mMediaTag\'s role icon at the right end of party / arena ally bars.'),
				}),
				trinket = Section(30, 'TRINKET', {
					text = Text(1, Muted(Options.PVP_TEXT.trinket)),
					toggle = ArtSetting(2, 'toggle', 'trinketCircles', 'Trinket circles'),
				}),
				cc = Section(40, 'CC', {
					text = Text(1, Muted(Options.PVP_TEXT.cc)),
					level = ArtSetting(2, 'select', 'ccEmphasis', 'CC emphasis', { values = EMPHASIS, sorting = EMPHASIS_ORDER }),
				}),
				dispel = Section(50, 'DISPELLABLE STATE', {
					text = Text(1, Muted(Options.PVP_TEXT.dispel)),
					level = ArtSetting(2, 'select', 'dispelEmphasis', 'Dispellable emphasis', { values = EMPHASIS, sorting = EMPHASIS_ORDER }),
				}),
				casts = Section(55, 'CASTS', {
					text = Text(1, Color('INTERRUPTIBLE', { 1, 0.70, 0 }) .. '   ' .. Color('NOT INTERRUPTIBLE', { 0.62, 0.60, 0.74 }) .. '\n' .. Muted(Options.PVP_TEXT.casts)),
					colors = PvPToggle(2, 'pvpCastColors', 'Banzai cast colours', 'Amber / steel violet on ElvUI\'s cast bars (off: Bushido\'s colours).'),
				}),
			}),
			cooldowns = Tab(20, 'COOLDOWN BARS', {
				bars = Section(60, 'COOLDOWN BARS', {
					text = Text(1, Muted(Options.PVP_TEXT.cooldowns)),
					toggle = ArtSetting(2, 'toggle', 'cdBars', 'Cooldown bars'),
					scale = ArtSetting(3, 'range', 'cdScale', 'Scale', { min = 0.7, max = 1.2, step = 0.05, isPercent = true }),
					opacity = ArtSetting(4, 'range', 'cdOpacity', 'Opacity', { min = 0.4, max = 1, step = 0.05, isPercent = true }),
					spread = ArtSetting(5, 'range', 'cdSpread', 'Distance from the centre', { min = 280, max = 400, step = 1 }),
					height = ArtSetting(6, 'range', 'cdHeight', 'Height', { min = 44, max = 160, step = 1 }),
				}),
				offensive = Section(70, 'OFFENSIVE COOLDOWN BARS', {
					count = ArtSetting(1, 'range', 'cdOffensiveCount', 'Bars at most', { min = 1, max = 5, step = 1 }),
					tracked = Tracked(2, 'offensive'),
				}),
				defensive = Section(80, 'DEFENSIVE COOLDOWN BARS', {
					count = ArtSetting(1, 'range', 'cdDefensiveCount', 'Bars at most', { min = 1, max = 5, step = 1 }),
					tracked = Tracked(2, 'defensive'),
				}),
			}),
			previewTab = Tab(30, 'PREVIEW', {
				preview = Section(90, 'PREVIEW', {
					info = Text(1, Muted('Sample frames and bars, labelled SAMPLE DATA. The states are synthetic: they show the design, not live data. Hidden automatically in combat.')),
					role = PreviewRole(2),
					state = Options.PreviewState(3),
					next = Button(4, 'NEXT STATE', nil, PreviewRun(function(p) p:NextState() end)),
					arena = Button(6, 'PARTY + ARENA', 'Party, arena allies (shown just above the party: the same place in the game) and arena enemies.', PreviewRun(function(p) p:ShowArenaSet() end)),
					raid = Button(7, 'RAID', nil, PreviewRun(function(p) p:Show('raid', true) end)),
					bars = Button(8, 'COOLDOWN BARS', 'Offensive and defensive cooldown bars with SAMPLE DATA.', PreviewRun(function(p) p:Show('cooldowns', true) end)),
					hide = Button(9, 'HIDE ALL', nil, PreviewRun(function(p) p:HideAll() end)),
				}),
			}),
		},
	}
end

---------------------------------------------------------------------------
-- 1.0.0 texts
---------------------------------------------------------------------------
Options.TEXT = {
	castBar = 'BANZAI SPLIT Player and Target (1.3.3): while a spell is cast or channelled its icon replaces the class art in the central circle, and a bamboo cast bar as wide as the whole frame shows the progress above the health / resource values - a cast fills left to right, a channel drains right to left, in the unit\'s class colours; steel when it cannot be interrupted; INTERRUPTED for a moment in crimson. The class art returns as soon as the cast ends. Off: the spell icon in the circle alone. The bar on / off moves the class bar (combo points, holy power ...) - a reload applies that part. Per character (Character Sync carries these choices).',
	targetNPC = 'A synthetic sample (1.3.3): Banzai\'s own NPC crest and sample numbers only - no real unit, no portrait, no game icon.',
	identityArt = 'Your original BANZAI class identities (1.3.2) in the BANZAI SPLIT central circles and party circles. BANZAI (default): there, while the classic identity circles keep the Fabled art; BANZAI everywhere: the classic Focus / Party / Boss circles too (arena enemies keep theirs). FABLED: the Fabled art first. CLASS COLOUR: class-colour discs. The enhanced target nameplate and the BANZAI COMPACT Details rows keep their art - too small for the full artwork. Per character (Character Sync carries the choice, never the art files).',
	frameStyle = 'BANZAI CLASSIC: the approved Banzai frames (bamboo, the large class circles, health inside the bars) - the default. BANZAI SPLIT: a second style - Player at the lower centre and Target at the upper centre with the health bar to the left of a central class / cast circle and the resource bar to its right; while you cast, the circle shows the spell icon and a bamboo cast bar above the frame shows its progress, name and time (1.3.3; Focus: a ring that fills, the spell name above it). Focus, Target-of-Target and party in the same language. Per character; a reload applies it, and switching back gives the classic frames exactly as they were.',
	split = 'Positions are the centres of the Player and Target circles (units from the screen centre / the bottom or top edge); they move at once. Frame scale, circle scale and bar thickness take a reload. Health and resource are one class-colour family; the values sit above the bars, the name under the health bar, the spec under the resource bar. The texts and the enhanced nameplate show at once.',
	-- 1.3.1
	fonts = 'Display font: BANZAI-owned headings, names, spell labels and large Player / Target numbers. BANZAI Default is Shojumaru at 105%; Automatic uses it only for fully supported strings, otherwise the Information Font. Profile display font: ElvUI\'s own big numbers. Small text font: names elsewhere, nameplates, chat, tracker, tooltips, cast history, Details rows, bottom bar, timers.',
	detailsStyle = 'BANZAI CURRENT: the approved meter rows (DAMAGE | HEALING unchanged). BANZAI COMPACT: thin class-coloured bars with a small round identity icon at the start of each row, the name above the bar in its class colour and a large value - tighter rows. Both keep the bamboo frame, the panel style and the red DAMAGE / green HEALING titles.',
	width = 'Player, Target, Focus and Target-of-Target as a share of Bushido\'s width. Heights stay; every frame keeps its inner end (the bamboo, the combat tree and cast history stay where they are) and loses its outer part; the name and spec take two lines on narrow frames. Per character; a reload applies it. Their places come from BANZAI (height / distance below): a frame moved with ElvUI\'s movers goes back there when BANZAI writes them again.',
	groups = {
		party = 'DPS: a column on the left edge, in line with the raid frames. HEALER: one horizontal row in the centre, just above Player / Target.',
		raid = 'Compact: small role icon, one raid debuff, percent, Dead / Ghost / Offline. HEALER: on the healer row\'s baseline.',
		arenaAllies = 'The party frames inside an arena, with a position of their own per role (HEALER: the same row by default).',
		arenaEnemies = 'Banzai\'s mirrored frames on the right edge: trinket | health | class / spec circle (PVP > FRAMES).',
		boss = 'At the right screen edge, a cast bar above each, debuffs to the left.',
	},
	tooltips = 'BANZAI: dark green glass, a thin green -> purple edge inside ElvUI\'s border (item quality / class colour kept there), the small crisp font, a soft shadow. ELVUI: Bushido\'s tooltip as it was. The tooltip content is the game\'s and ElvUI\'s, unchanged.',
	anchors = 'Ordinary tooltips keep ElvUI\'s anchor (the tooltip mover above Details, or the cursor if ElvUI is set so). Banzai\'s own tooltips open next to what you hover - above the bottom panel, left of the objectives (clear of the minimap) - and are kept on screen.',
	afk = 'When you go AFK out of combat: a dark green glass screen, your character turning slowly in the middle, BANZAI, your Fabled class art, name, class / spec, level and zone. The HUD is hidden while it shows and comes back exactly as it was: any key or click, moving, combat, a queue pop, a ready check or a loading screen ends it. ElvUI\'s AFK screen is off while this one is on.',
}

-- what owns which feature (COMPONENTS > FEATURE OWNERSHIP)
Options.OWNERSHIP = {
	{ 'Unit frames, nameplates, action bars, chat, minimap', 'ElvUI (the Banzai profile and its per-character layer)' },
	{ 'Bamboo art, frames, health in the bars, identity / trinket circles, CC / dispel states', 'Banzai Art' },
	{ 'Arena enemy frames', 'Banzai (ElvUI\'s arena frames in the Banzai design) - the only arena enemy system' },
	{ 'Bottom panel and its tooltips, objectives (Banzai tracker)', 'Banzai Art (Kaliel\'s Tracker hidden while it is on)' },
	{ 'Tooltips', 'ElvUI (content, anchor) + the Banzai tooltip theme (glass, edge, font)' },
	{ 'AFK screen', 'Banzai (ElvUI\'s off while Banzai\'s is on)' },
	{ 'Damage / healing meters', 'Details! in the Banzai layout' },
	{ 'Gold of your other characters and the Warband bank', 'Syndicator, read only (when installed)' },
	{ 'Fabled class / spec art', 'Jiberish Icons' },
}

function Options.OwnershipText()
	local lines = {}
	for _, row in ipairs(Options.OWNERSHIP) do lines[#lines + 1] = Color(row[1], { 1, 1, 1 }) .. '\n      ' .. Muted(row[2]) end
	return table.concat(lines, '\n')
end

-- CHARACTER SYNC: the Banzai version the master's setup was captured with
function Options.VersionText()
	local master = ns.Sync and ns.Sync:Master()
	local here = ns.VERSION or '?'
	if not (master and master.version) then return Muted('This character runs BANZAI ' .. here .. '. No master setup captured yet.') end
	if master.version == here then return Color('In step: ', EMERALD) .. Muted('the master\'s setup was captured with BANZAI ' .. here .. ', the version running here.') end
	return Color('Version drift: ', { 1, 0.8, 0.2 }) .. Muted('the master\'s setup was captured with BANZAI ' .. tostring(master.version) .. ', this character runs BANZAI ' .. here
		.. '. Settings that version did not know keep their BANZAI ' .. here .. ' defaults; log in on the master once to capture it again.')
end

function Options.BackupText()
	local record = Record()
	if not (record and record.applied) then return Muted('Banzai is not applied on this character, so there is nothing to restore.') end
	local previous = record.previous or {}
	return table.concat({
		Color('Banzai ' .. tostring(record.applied.version) .. ' applied ' .. tostring(record.applied.upgraded or record.applied.time), EMERALD),
		'Saved from before Banzai: the ElvUI layout ' .. Color(tostring(previous.elvProfile or 'Default'), { 1, 1, 1 }) .. ', your Details layout ' .. Color(tostring(previous.details or 'Default'), { 1, 1, 1 })
			.. (record.syncBackup and (' and this character\'s own BANZAI settings (' .. tostring(record.syncBackup.time) .. ')') or '') .. '.',
		'Restoring switches this character back to them. The Banzai setup stays saved, so you can apply it again any time.',
	}, '\n')
end

Options.BACKUP_STATUS = 'Never touched by a restore: spells, action bars, macros, talents, keybinds, equipment sets, Details history, chat history, currencies, other addons. Snapshots are per character; the shared Banzai profile stays for your other characters.'

local function AfkToggle(order, key, name, desc) return ArtToggle(order, key, name, desc, { disabled = function() local art = Art() return not (art and art:Get('afk')) end }) end

function Options:Build()
	local R = ns.Restore
	local version = ns.VERSION or '?'
	local page = {}
	for i, p in ipairs(Options.PAGES) do page[p[1]] = { order = i * 10, name = p[2] } end
	local function Page(key, args, childGroups)
		return { order = page[key].order, type = 'group', name = page[key].name, childGroups = childGroups, args = args }
	end
	return {
		order = 6,
		type = 'group',
		name = ICON .. ' ' .. Gradient('BANZAI', LIME, PURPLE),
		desc = 'BANZAI UI by HARDKORH',
		childGroups = 'tree',
		args = {
			-- above the page list: the logo, UI BY HARDKORH and the version, on every page
			brand = { order = 1, type = 'description', fontSize = 'large', width = 'full',
				image = function() return MEDIA .. 'BanzaiLogo', 256, 64 end,
				name = function()
					return Gradient('BANZAI ' .. version, EMERALD, PURPLE) .. '\n' .. Gradient('UI BY HARDKORH', LIME, VIOLET) .. '      ' .. Muted('release')
				end },

			home = Page('home', {
				header = Header(1, 'BANZAI ' .. version),
				status = { order = 2, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.HomeText() end },
				actions = Section(10, 'APPLY / REPAIR', {
					info = Text(1, Muted('Apply / repair writes the full Banzai setup for this character again (your setup from before Banzai stays saved). A reload finishes it.')),
					apply = Button(2, 'Apply / repair Banzai', 'Apply the full Banzai setup to this character. Your current setup is saved first and can be restored under BACKUP & RESTORE.',
						function() R:ApplyHere('options') Notify() end,
						{ confirm = function() -- 1.0.1: a character not on Banzai yet gets the APPLY BANZAI summary
							local record = Record()
							if record and record.applied then return 'Apply Banzai to this character now? Your current setup is saved first.' end
							return 'APPLY BANZAI to this character?\n\n' .. Options.PlanText()
						end }),
					reload = Button(3, 'Reload UI', nil, function() ReloadUI() end),
				}),
			}),

			appearance = Page('appearance', {
				frameTheme = Section(10, 'FRAME THEME', {
					theme = { order = 1, type = 'select', style = 'radio', width = 'full', name = 'Banzai frames',
						values = { VIBRANT = Gradient('VIBRANT', LIME, PURPLE) .. '   green -> purple bamboo (default)', CLASS = 'CLASS   your class colour on the same bamboo' },
						sorting = { 'VIBRANT', 'CLASS' },
						get = function() local art = Art() return art and art:GetTheme() or 'VIBRANT' end,
						set = function(_, value) local art = Art() if art then art:SetTheme(value) end Notify() end },
					gradient = Select(2, 'Frame gradient', nil, { FORWARD = 'Green -> purple', REVERSE = 'Purple -> green' }, { 'FORWARD', 'REVERSE' }, ArtGet('gradient'), ArtSet('gradient')),
					intensity = ArtRange(3, 'intensity', 'Frame intensity', nil, 0.5, 1, 0.05, { isPercent = true }),
					bambooArt = ArtToggle(4, 'bambooArt', 'Bamboo bundles', 'The tied three-stalk bamboo bundles on the Player and Target frames (the other unit frames stay clean).'),
					smoothBars = Toggle(7, 'Smooth health bars', 'One continuous Banzai surface on unit frames, nameplates and Details rows (off: Bushido\'s slotted textures). A reload applies it.',
						ArtGet('smoothBars'), function(_, v) R:SetSmoothBars(v) Notify() end),
				}),
				-- 1.1.0: the chat, Details and minimap frames - one bamboo construction, three border colourings, three interiors, any with any
				panelStyle = Section(15, 'PANEL STYLE', {
					info = Text(1, Muted('Chat, Details, the minimap and the BUFFS panel sit in one bamboo construction: a stalk along each side, tied at the corners. Choose the border and the background independently; every change shows at once on all four.')),
					panelBorder = { order = 2, type = 'select', style = 'radio', width = 'full', name = 'Border style',
						values = { CLASS = 'CLASS   your class colour on the bamboo (lighter -> class colour -> deeper), hemp rope', BANZAI = Gradient('BANZAI', LIME, EMERALD) .. '   natural vivid bamboo greens, purple rope (default)', HARDKORH = Gradient('HARDKORH', LIME, PURPLE) .. '   green -> emerald -> violet -> purple over the bamboo, purple rope' },
						sorting = { 'CLASS', 'BANZAI', 'HARDKORH' },
						get = ArtGet('panelBorder'), set = ArtSet('panelBorder') },
					panelBackground = { order = 3, type = 'select', style = 'radio', width = 'full', name = 'Background',
						values = { SOLID = 'SOLID   very dark green-black, nearly opaque', GLASS = Gradient('BANZAI GLASS', LIME, EMERALD) .. '   the dark translucent green glass (default)', PARCHMENT = Gradient('HARDKORH PARCHMENT', LIME, PURPLE) .. '   warm cream parchment (the Details row text stays bright, outlined)' },
						sorting = { 'SOLID', 'GLASS', 'PARCHMENT' },
						get = ArtGet('panelBackground'), set = function(_, value) R:SetPanelBackground(value) Notify() end },
					borderScale = ArtRange(4, 'borderScale', 'Border scale', 'The thickness of the bamboo (100% = 10 units, as thick as the room beside the chat and the meters allows; the minimap frame follows it).', 0.7, 1, 0.05, { isPercent = true }),
					glassOpacity = ArtRange(5, 'glassOpacity', 'Glass opacity', 'The dark green glass behind the chat and Details (also the objective tracker).', 0.3, 1, 0.02, { isPercent = true }),
					parchmentBrightness = ArtRange(6, 'parchmentBrightness', 'Parchment brightness', nil, 0.7, 1.1, 0.02, { isPercent = true, disabled = function() local art = Art() return not (art and art:Get('panelBackground') == 'PARCHMENT') end }),
				}),
				branding = Section(20, 'BRANDING', {
					logo = ArtToggle(1, 'logo', 'BANZAI logo', 'The small BANZAI wordmark at the top centre of the screen (out of combat). Click it to open these settings.'),
					combatLogo = ArtToggle(2, 'combatLogo', 'Combat logo', 'In combat the wordmark moves between Player and Target, larger, with a small Banzai tree behind it; back to the top after combat.'),
					targetPlate = ArtToggle(3, 'targetPlate', 'Targeted enemy nameplate', 'Class or reaction gradient on your target\'s nameplate, with its health and percentage inside the bar.'),
				}),
				fonts = Section(30, 'FONTS', {
					info = Text(1, Muted(Options.TEXT.fonts)),
					-- 1.3.1 Banzai's own display typography
					displayFace = Select(1.2, 'Display font', 'BANZAI Default is Shojumaru at 105%. Automatic uses that default for complete supported strings and the Information Font otherwise. An alternate face is drawn at its own size; a string it cannot show uses the Information Font. Changes apply immediately.',
						{ AUTO = 'Automatic', BANZAI_DEFAULT = 'BANZAI Default', SHOJUMARU = 'Shojumaru', RYUJIN_ATTACK = 'Ryujin Attack', GANG_OF_THREE = 'Gang of Three', OSAKA_SANS = 'Osaka Sans', SEKAIWO = 'Sekaiwo', XANGDA_SHINY = 'Xangda Shiny', NINJA_NARUTO = 'Ninja Naruto', INFORMATION = 'Information Font' },
						{ 'AUTO', 'BANZAI_DEFAULT', 'SHOJUMARU', 'RYUJIN_ATTACK', 'GANG_OF_THREE', 'OSAKA_SANS', 'SEKAIWO', 'XANGDA_SHINY', 'NINJA_NARUTO', 'INFORMATION' },
						function() local art = Art() return art and art:Get('displayFace') or 'BANZAI_DEFAULT' end, function(_, v) R:SetDisplayFace(v) Notify() end),
					fontPreview = Button(1.3, 'Preview display font', 'Show sample strings and the selected face’s source, license and fallback status.', function()
						local art = _G.BanzaiCompat
						local preview = art and art.Preview
						if not (preview and preview.ShowFontBakeoff) then print('BANZAI: display-font preview is unavailable.') return end
						preview:ShowFontBakeoff()
					end),
					displayScale = ArtRange(1.4, 'displayScale', 'Banzai display size', 'Scales the selected display face; BANZAI Default has a 105% base scale.', 0.85, 1.2, 0.05, { isPercent = true }),
					displayFont = Select(2, 'Profile display font', 'ElvUI\'s own big numbers in the Banzai profile (Banzai\'s own texts use the Banzai display font above).', FontValues, nil, function() return R:Fonts().display end, function(_, value) DB().fonts.pendingDisplay = value end, { dialogControl = 'LSM30_Font' }),
					smallFont = Select(3, 'Small text font', nil, FontValues, nil, function() return R:Fonts().small end, function(_, value) DB().fonts.pendingSmall = value end, { dialogControl = 'LSM30_Font' }),
					applyFonts = Button(4, 'Apply fonts', 'Writes the fonts into the Banzai profile; a reload finishes it.', function()
						local db = DB()
						R:ApplyFonts(db.fonts.pendingDisplay, db.fonts.pendingSmall)
						db.fonts.pendingDisplay, db.fonts.pendingSmall = nil, nil
					end),
				}),
				texts = Section(40, 'TEXT ON THE FRAMES', {
					healthInside = Toggle(1, 'Health inside the bars', 'Current health and percentage inside the Player, Target, Focus, Party, Arena and Boss bars (raid frames: the percentage); over the empty part of the bar the text turns translucent.',
						Options.HealthInside, function(_, v) ns.Restore:SetHealthInside(v) Notify() end),
					percent = Toggle(2, 'Health percentage', 'Show the health percentage next to the health value (Player, Target, Focus, Party, Arena).', Options.GetPercent, function(_, v) Options.SetPercent(v) end),
					specNames = Toggle(3, 'Specialization in names', 'PLAYER - SPEC on your frame, SPEC - NAME on player targets (NPCs show the name only); on the narrow frames the spec has its own line under the name.',
						Options.GetSpecNames, function(_, v) Options.SetSpecNames(v) end),
					healthSize = Range(4, 'Health number size', 'Health under the bar (when it is not inside the bar).', 14, 28, 1, Options.GetHealthSize, function(_, v) Options.SetHealthSize(v) end, { hidden = Options.HealthInside }),
				}),
			}),

			unitframes = Page('unitframes', {
				-- 1.3.0 the second visual family (BANZAI CLASSIC stays the default)
				style = Tab(5, 'FRAME STYLE', {
					frameStyle = Section(1, 'FRAME STYLE', {
						text = Text(1, Muted(Options.TEXT.frameStyle)),
						frameStyle = { order = 2, type = 'select', style = 'radio', width = 'full', name = 'Frame style',
							values = { CLASSIC = Gradient('BANZAI CLASSIC', LIME, EMERALD) .. '   the approved Banzai frames (default)', SPLIT = Gradient('BANZAI SPLIT', LIME, PURPLE) .. '   health  <-  class / cast circle  ->  resource' },
							sorting = { 'CLASSIC', 'SPLIT' },
							get = function() return Options.FrameStyle() end, set = function(_, v) R:SetFrameStyle(v) Notify() end },
						now = { order = 3, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.FrameStyleText() end },
					}),
					split = Section(10, 'BANZAI SPLIT', {
						text = Text(1, Muted(Options.TEXT.split)),
						playerX = Options.SplitRange(2, 'splitPlayerX', 'Player position X', 'The Player circle\'s centre, units right (+) or left (-) of the screen centre.', -400, 400, 1),
						playerY = Options.SplitRange(3, 'splitPlayerY', 'Player position Y', 'The Player circle\'s centre, units above the bottom of the screen (clear of cast history and the action bars at the default).', 150, 520, 1),
						targetX = Options.SplitRange(4, 'splitTargetX', 'Target position X', 'The Target circle\'s centre, units right (+) or left (-) of the screen centre.', -400, 400, 1),
						targetY = Options.SplitRange(5, 'splitTargetY', 'Target position Y', 'The Target circle\'s centre, units below the top of the screen.', 70, 320, 1),
						resetPositions = Button(6, 'Reset positions', nil, function() R:ResetSplitPositions() Notify() end),
						scale = Options.SplitRange(7, 'splitScale', 'Frame scale', 'Bar length and height of the split frames. A reload applies it.', 0.8, 1.25, 0.05, { isPercent = true }),
						hubScale = Options.SplitRange(8, 'splitHubScale', 'Central icon scale', 'The class / cast circles. A reload applies it.', 0.8, 1.3, 0.05, { isPercent = true }),
						thickness = Options.SplitRange(8.5, 'splitThickness', 'Bar thickness', 'The Player / Target health and resource bars\' thickness. A reload applies it.', 0.75, 1.3, 0.05, { isPercent = true }), -- 1.3.1
						hpText = Options.SplitToggle(9, 'splitHpText', 'HP text', 'Player / Target: current health over the outer end of the health bar, the percentage over its end beside the circle (Focus: inside its bar).'),
						powerText = Options.SplitToggle(10, 'splitPowerText', 'Resource text', 'Player / Target: the percentage over the resource bar\'s end beside the circle, the current value over its outer end (Focus: inside its bar; NPCs without a resource show no resource side).'),
						plate = Options.SplitToggle(11, 'splitTargetPlate', 'Enhanced target nameplate', 'Your current target\'s nameplate gets a small class / cast circle and a green -> purple outline over the targeted-plate treatment (APPEARANCE); every other nameplate stays as it is. BANZAI SPLIT only.'),
						party = Options.SplitToggle(12, 'splitParty', 'Party style', 'Party and arena allies in the split construction (the class circle in the middle of the bar, the name across its lower part). Off: the classic party frames. A reload applies it.'),
						preview = Button(13, 'Preview BANZAI SPLIT', 'Labelled sample frames (SAMPLE DATA) in the BANZAI SPLIT style, wherever the style in use is; hidden in combat.', function() Options.PreviewSplit() Notify() end),
					}),
					-- 1.3.3 the bamboo cast bar of the split Player / Target
					castBar = Section(15, 'SPLIT CAST BAR', {
						text = Text(1, Muted(Options.TEXT.castBar)),
						bar = Options.SplitToggle(2, 'splitCastBar', 'Bamboo cast bar', 'The cast bar above the split Player / Target (the class bar moves above it; a reload applies that part).'),
						name = Options.SplitToggle(3, 'splitCastName', 'Spell name', 'The spell name centred on the cast bar. At once.'),
						timer = Options.SplitToggle(4, 'splitCastTimer', 'Timer', 'The remaining time at the cast bar\'s right end. At once.'),
					}),
					-- 1.3.2 Darren's original class identities
					identityArt = Section(20, 'IDENTITY ART', {
						text = Text(1, Muted(Options.TEXT.identityArt)),
						identityArt = Select(2, 'Identity art', 'Which class art the identity circles show. At once.',
							{ AUTO = 'BANZAI (classic circles: Fabled) - default', BANZAI = 'BANZAI everywhere', FABLED = 'FABLED', CLASS = 'CLASS COLOUR' }, { 'AUTO', 'BANZAI', 'FABLED', 'CLASS' },
							function() local art = Art() return art and art:Get('identityArt') or 'AUTO' end, function(_, v) R:SetIdentityArt(v) Notify() end),
					}),
				}),
				frames = Tab(10, 'PLAYER / TARGET / FOCUS / TOT', {
					width = Section(10, 'WIDTH', {
						text = Text(1, Muted(Options.TEXT.width)),
						frameWidth = Range(2, 'Player / Target / Focus / ToT width', 'Share of Bushido\'s width (BANZAI 1.0: 50 %). A reload applies it.', 0.5, 1, 0.05,
							function() return Options.FrameWidth() end, function(_, v) R:SetFrameWidth(v) Notify() end, { isPercent = true }),
						widthReset = Button(3, 'BANZAI 1.0 width (50 %)', nil, function() R:SetFrameWidth(T.FRAME_WIDTH) Notify() end),
					}),
					position = Section(20, 'PLAYER & TARGET', {
						unitHeight = Range(1, 'Height', 'Moves Player, Target, Focus, Target-of-Target and their bars up or down together (the HEALER row stays where it is).', -120, 120, 1,
							function() return R:Own().layout.unitHeight or 0 end, function(_, v) Options.SetUnitLayout(v, nil) end),
						unitSpread = Range(2, 'Distance from the screen edges', 'Moves Player and Target (with Focus and Target-of-Target) symmetrically toward (+) or away from (-) the centre.', -150, 150, 1,
							function() return R:Own().layout.unitSpread or 0 end, function(_, v) Options.SetUnitLayout(nil, v) end),
						unitReset = Button(3, 'Reset positions', nil, function() Options.SetUnitLayout(0, 0) Notify() end),
						cooldownBars = Toggle(4, 'Target cooldown bars', 'Bushido\'s cooldown display between Player and Target (ElvUI action bars 2 and 4, shown when you have a target). Off in Banzai; the spells stay on their bars. A reload applies it.',
							ArtGet('cooldownBars'), function(_, v) R:SetCooldownBars(v) Notify() end),
					}),
					minor = Section(30, 'FOCUS, TARGET-OF-TARGET, PET', {
						totScale = Range(1, 'Target-of-Target size', 'Under the Target frame\'s inner end; a reload applies it.', 0.5, 1, 0.02,
							ArtGet('totScale'), function(_, v) ns.Restore:SetToTScale(v) Notify() end, { isPercent = true }),
						totReset = Button(2, 'Reset Target-of-Target', 'Banzai size and position.', function() ns.Restore:SetToTScale(T.TOT.scale) Notify() end),
						identityCircles = Toggle(3, 'Identity circles', 'A small circle with the Fabled spec icon (class icon when the spec is not known) on Focus, Party, Arena and player Boss frames, in place of the large mMediaTag portraits there. A reload applies it.',
							ArtGet('identityCircles'), function(_, v) R:SetIdentityCircles(v) Notify() end),
					}),
				}),
				groups = Tab(20, 'GROUP FRAMES', {
					roles = Section(1, 'ROLE LAYOUTS', {
						text = Text(1, Muted('Party, raid, arena and boss frames take the DPS or the HEALER layout from your spec by themselves; each role keeps its own positions (party and arena allies separately). Reset them on LAYOUT > DPS / HEALER PLACEMENT.')),
						current = { order = 2, type = 'description', fontSize = 'medium', width = 'full', name = function() return Muted('CURRENT SPEC ROLE:  ') .. Color(Options.CurrentRole(), EMERALD) end },
					}),
					party = Section(10, 'PARTY', { text = Text(1, Muted(Options.TEXT.groups.party)), preview = Options.PreviewToggle(2, 'party') }),
					raid = Section(20, 'RAID', { text = Text(1, Muted(Options.TEXT.groups.raid)), preview = Options.PreviewToggle(2, 'raid') }),
					arenaAllies = Section(30, 'ARENA ALLIES', { text = Text(1, Muted(Options.TEXT.groups.arenaAllies)), preview = Options.PreviewToggle(2, 'arenaAllies') }),
					arenaEnemies = Section(40, 'ARENA ENEMIES', { text = Text(1, Muted(Options.TEXT.groups.arenaEnemies)), preview = Options.PreviewToggle(2, 'arenaEnemies') }),
					boss = Section(50, 'BOSS', { text = Text(1, Muted(Options.TEXT.groups.boss)), preview = Options.PreviewToggle(2, 'boss') }),
				}),
				preview = Tab(30, 'PREVIEW', {
					preview = Section(1, 'UNIT FRAME PREVIEW', {
						previewInfo = Text(1, Muted('Visual test mode: labelled sample frames in the current Banzai style (no real units, nothing clickable). Hidden automatically in combat.')),
						previewRole = PreviewRole(2),
						previewState = Options.PreviewState(3),
						previewStyle = Select(3.5, 'Frame style', 'Shows the samples in BANZAI CLASSIC or BANZAI SPLIT (the frames in use do not change).', { CLASSIC = 'Banzai Classic', SPLIT = 'Banzai Split' }, { 'CLASSIC', 'SPLIT' },
							function() local p = PreviewModule() return (p and p.Style and p:Style()) or 'CLASSIC' end,
							function(_, v) local p = PreviewModule() if p and p.SetStyle then p:SetStyle(v) end Notify() end),
						previewSpecRole = { order = 4, type = 'description', fontSize = 'medium', width = 'full', name = function() return Muted('CURRENT SPEC ROLE:  ') .. Color(Options.CurrentRole(), EMERALD) end },
						previewAll = Button(5, 'SHOW ALL', nil, function() local p = PreviewModule() if p then p:ShowAll() end Notify() end),
						previewNone = Button(6, 'HIDE ALL', nil, function() local p = PreviewModule() if p then p:HideAll() end Notify() end),
						previewPlayer = Options.PreviewToggle(10, 'player'),
						previewTarget = Options.PreviewToggle(11, 'target'),
						previewToT = Options.PreviewToggle(12, 'targettarget'),
						previewFocus = Options.PreviewToggle(13, 'focus'),
						previewPet = Options.PreviewToggle(14, 'pet'),
						previewParty = Options.PreviewToggle(15, 'party'),
						previewRaid = Options.PreviewToggle(16, 'raid'),
						previewArenaAllies = Options.PreviewToggle(17, 'arenaAllies'),
						previewArenaEnemies = Options.PreviewToggle(18, 'arenaEnemies'),
						previewBoss = Options.PreviewToggle(19, 'boss'),
						previewTargetNPC = Options.PreviewToggle(20, 'targetNPC', { desc = Options.TEXT.targetNPC, hidden = function() local p = PreviewModule() return not (p and p.Style and p:Style() == 'SPLIT') end }), -- 1.3.3: synthetic
						previewPlate = Options.PreviewToggle(21, 'nameplate', { hidden = function() local p = PreviewModule() return not (p and p.Style and p:Style() == 'SPLIT') end }),
					}),
				}),
			}, 'tab'),

			pvp = Options.PvPGroup(),

			actionbars = Page('actionbars', {
				style = Section(10, 'BUTTON STYLE', {
					text = Text(1, Muted('BANZAI SQUARE: the whole spell picture, square with small cut corners and a thin green -> purple border; the keybind small at the top-right, the count at the bottom (the default). BANZAI CIRCLES: circles with a green -> purple ring and the keybind in the centre. ELVUI SQUARE: ElvUI\'s own buttons, Bushido\'s look - the fallback. Main action bars.')),
					actionStyle = Select(2, 'Button style', 'A reload applies it.', { SQUARE = 'Banzai Square', CIRCLE = 'Banzai Circles', ELVUI = 'ElvUI Square' }, { 'SQUARE', 'CIRCLE', 'ELVUI' },
						ArtGet('actionStyle'), function(_, v) R:SetActionStyle(v) Notify() end),
				}),
				circles = Section(20, 'BANZAI BUTTONS', {
					abSize = Range(1, 'Button size', 'The Banzai buttons on the main action bars (30 = BANZAI; up to 32 so the two rows stay clear of the cooldown bars). A reload applies it.', 26, 32, 1, ArtGet('abSize'), function(_, v) R:SetActionLook('abSize', v) Notify() end, { disabled = Options.SquareButtons }),
					abSpacing = Range(2, 'Spacing', 'Space between the buttons (6 = BANZAI). A reload applies it.', 4, 7, 1, ArtGet('abSpacing'), function(_, v) R:SetActionLook('abSpacing', v) Notify() end, { disabled = Options.SquareButtons }),
					ringIntensity = ArtRange(3, 'ringIntensity', 'Border / ring intensity', 'Strength of the green -> purple border or ring (drawn live).', 0.4, 1, 0.05, { isPercent = true, disabled = Options.SquareButtons }),
				}),
				typography = Section(30, 'KEYBIND / COUNT', {
					abKeybind = Range(1, 'Keybind size (circles)', 'Against Bushido\'s keybind size (130 % = BANZAI): the circles\' centred keybind. The square keeps a compact keybind at the top-right. A reload applies it.', 1, 1.6, 0.05, ArtGet('abKeybind'), function(_, v) R:SetActionLook('abKeybind', v) Notify() end, { isPercent = true, disabled = Options.NotCircles }),
					abCount = Range(2, 'Charge / stack count size', 'Against Bushido\'s count size (80 % = BANZAI). A reload applies it.', 0.6, 1.2, 0.05, ArtGet('abCount'), function(_, v) R:SetActionLook('abCount', v) Notify() end, { isPercent = true, disabled = Options.SquareButtons }),
				}),
			}),

			layout = Page('layout', {
				frames = Tab(10, 'CHAT / DETAILS / MINIMAP / TRACKER', {
					chat = Section(10, 'CHAT', {
						chatFrame = ArtToggle(1, 'chatFrame', 'Banzai chat frame', 'The bamboo frame and background around the chat, flush with the left screen edge, the same size as the Details frame (its style: APPEARANCE > PANEL STYLE).'),
					}),
					details = Section(20, 'DETAILS', {
						detailsInfo = Text(1, Muted('DAMAGE | HEALING side by side in the lower right, inside one Banzai frame, the titles on its top border.')),
						detailsFrame = ArtToggle(2, 'detailsFrame', 'Banzai Details frame'),
						detailsLayout = Button(3, 'Arrange side by side', nil, function() R:LayoutDetails() end),
						-- 1.3.0
						detailsStyle = Select(4, 'Meter style', Options.TEXT.detailsStyle, { CURRENT = 'Banzai Current', COMPACT = 'Banzai Compact' }, { 'CURRENT', 'COMPACT' },
							function() local art = Art() return (art and art:Get('detailsStyle')) or 'CURRENT' end, function(_, v) R:SetDetailsStyle(v) Notify() end),
					}),
					minimap = Section(30, 'MINIMAP', {
						mapInfo = Text(1, Muted('Top right in a square bamboo frame with the zone name above it; the minimap buttons collector in the corner, the objective tracker below.')),
						minimapFrame = ArtToggle(2, 'minimapFrame', 'Banzai minimap frame'),
						zoneLabel = ArtToggle(3, 'zoneLabel', 'Zone name'),
					}),
					objectives = Section(40, 'OBJECTIVE TRACKER', {
						tracker = Toggle(1, 'Banzai tracker', 'Banzai objective tracker under the minimap. While it is on, Kaliel\'s Tracker is hidden through its own visibility setting (restored when you turn this off). A reload applies it.',
							ArtGet('tracker'), function(_, v) ns.Restore:SetTracker(v) Notify() end),
						trackerCollapsed = ArtToggle(2, 'trackerCollapsed', 'Collapsed', 'Same as its HIDE / SHOW button.'),
					}),
				}),
				hud = Tab(20, 'CAST HISTORY / BOTTOM PANEL / BUFFS', {
					cast = Section(10, 'CAST HISTORY', {
						castHistory = ArtToggle(1, 'castHistory', 'Show cast history', 'Your last casts between Player and Target, newest on top.'),
						castEntries = ArtRange(2, 'castEntries', 'Entries', nil, 1, 6, 1),
						castOpacity = ArtRange(3, 'castOpacity', 'Opacity', nil, 0.3, 1, 0.05, { isPercent = true }),
						castScale = ArtRange(4, 'castScale', 'Scale', nil, 0.6, 1.5, 0.05, { isPercent = true }),
					}),
					bottomPanel = Section(20, 'BOTTOM PANEL', {
						bar = ArtToggle(1, 'bar', 'Show bottom bar'),
						barHeight = Range(2, 'Bar height', 'The chat and Details frames stay on the bar.', 24, 40, 1, ArtGet('barHeight'), function(_, v) R:SetBarHeight(v) Notify() end),
						barCenter = ArtRange(3, 'barCenterSize', 'FPS / MS / time size', nil, 12, 22, 1),
						barText = ArtRange(4, 'barTextSize', 'Text size', nil, 9, 15, 1),
						barOpacity = ArtRange(5, 'barOpacity', 'Bar glass opacity', nil, 0.3, 1, 0.02, { isPercent = true }),
					}),
					-- 1.2.0: the BUFFS panel (its look: APPEARANCE > PANEL STYLE, like chat / Details / minimap)
					auras = Section(30, 'BUFFS PANEL', {
						buffsInfo = Text(1, Muted('Your buffs at the top-left in a bamboo panel in the PANEL STYLE material, the BUFFS title on its bottom border; debuffs stay separate below it. The buffs keep their tooltips and right-click cancelling.')),
						buffsPanel = Toggle(2, 'BUFFS panel', 'Off: the buffs as before, without a panel.', ArtGet('buffsPanel'), function(_, v) R:SetBuffsPanel('buffsPanel', v) Notify() end),
						buffsRows = Select(3, 'Maximum rows', '10 buffs per row.', { [2] = '2 rows (20 buffs)', [3] = '3 rows (30 buffs)' }, { 2, 3 }, ArtGet('buffsRows'), function(_, v) R:SetBuffsPanel('buffsRows', v) Notify() end, { disabled = Options.BuffsOff }),
						buffScale = Range(4, 'Buff size', 'The buff icons (debuffs below them stay full size). A reload applies it.', 0.5, 1, 0.05,
							function() return ns.Restore:Own().layout.buffScale or T.AURAS.scale end, function(_, v) ns.Restore:SetBuffScale(v) Notify() end, { isPercent = true }),
						buffsX = Range(5, 'Position X', 'The buffs\' left edge, units from the left screen edge (the panel around them).', T.BUFFS_PANEL.min, T.BUFFS_PANEL.maxX, 1, ArtGet('buffsX'), function(_, v) R:SetBuffsPanel('buffsX', v) Notify() end, { disabled = Options.BuffsOff }),
						buffsY = Range(6, 'Position Y', 'The buffs\' top edge, units from the top screen edge.', T.BUFFS_PANEL.min, T.BUFFS_PANEL.maxY, 1, ArtGet('buffsY'), function(_, v) R:SetBuffsPanel('buffsY', v) Notify() end, { disabled = Options.BuffsOff }),
						buffsReset = Button(7, 'Reset position', nil, function() R:ResetBuffsPosition() Notify() end, { disabled = Options.BuffsOff }),
					}),
				}),
				roles = Tab(30, 'DPS / HEALER PLACEMENT', {
					roles = Section(10, 'DPS / HEALER PLACEMENT', {
						roleInfo = Text(1, Muted('DPS: party and arena allies in a column on the left. HEALER: party and arena allies in one horizontal row in the centre, just above Player / Target; HEALER raid frames on the same baseline. Move them with ElvUI\'s movers: each role keeps its own positions, party and arena allies separately.')),
						current = { order = 2, type = 'description', fontSize = 'medium', width = 'full', name = function() return Muted('CURRENT SPEC ROLE:  ') .. Color(Options.CurrentRole(), EMERALD) end },
						roleResetDPS = Button(3, 'Reset DPS positions', nil, function() if ns.Roles then ns.Roles:Reset('DPS') end Notify() end),
						roleResetHealer = Button(4, 'Reset HEALER positions', nil, function() if ns.Roles then ns.Roles:Reset('HEALER') end Notify() end),
					}),
				}),
			}, 'tab'),

			sync = Page('sync', {
				header = { order = 1, type = 'description', fontSize = 'large', width = 'full', name = function() return Gradient('BANZAI ' .. version, EMERALD, PURPLE) .. '   ' .. Muted('CHARACTER SYNC - validation build') end },
				intro = Text(2, Muted('One approved Banzai setup on your characters. Only Banzai-owned visual settings move; each character keeps its spells, bars, macros, talents and keybinds, and its own class, spec and role. Nothing changes on a character until you choose it there.')),
				status = Tab(10, 'STATUS', {
					this = Section(10, 'THIS CHARACTER', {
						identity = { order = 1, type = 'description', fontSize = 'large', width = 'full', name = function() return Options.SyncIdentity() end,
							image = function() return Options.ClassIcon() end, imageWidth = 34, imageHeight = 34, imageCoords = function() return Options.ClassCoords() end },
						state = { order = 2, type = 'description', fontSize = 'large', width = 'full', name = function() return Options.SyncBadge() end },
						backup = { order = 3, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.BackupLine() end },
						detail = { order = 4, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.SyncDetail() end },
						apply = Button(10, 'APPLY BANZAI', nil, SyncRun(function(sync) return sync:Apply() end), {
							hidden = function() return Options.SyncState() ~= 'NOT_SYNCED' end,
							confirm = function() return 'APPLY BANZAI to this character?\n\n' .. Options.PlanText() end }),
						update = Button(11, 'UPDATE CHARACTER', nil, SyncRun(function(sync) return sync:Update() end), {
							hidden = function() return Options.SyncState() ~= 'UPDATE' end,
							confirm = function() return 'UPDATE CHARACTER to the master\'s Banzai setup?\n\n' .. Options.PlanText() end }),
						restore = Button(12, 'RESTORE PRE-BANZAI', nil, SyncRun(function(sync) return sync:RestoreCharacter() end), {
							hidden = function() local record = Record() return not (record and record.applied and record.previous) end,
							confirm = function()
								if Options.SyncState() == 'MASTER' then return 'Put this character back to its setup from before Banzai? It is the BANZAI MASTER: it stops being the master (synced characters keep their setup; set a master again afterwards).' end
								return 'Put this character back to its setup from before Banzai? The master\'s setup stays as it is.'
							end }),
					}),
					master = Section(20, 'BANZAI MASTER', {
						info = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.MasterText() end },
						setMaster = Button(2, 'SET AS BANZAI MASTER', nil, SyncRun(function(sync) return sync:SetMaster() end), {
							hidden = function() local s = Options.SyncState() return s == 'MASTER' or s == 'NOT_SYNCED' end,
							confirm = true, confirmText = 'Make this character\'s Banzai setup the one your other characters follow? Its Banzai-owned visual configuration is captured; nothing of its gameplay.' }),
						capture = Button(3, 'CAPTURE MASTER NOW', 'Also happens by itself whenever the master logs out.', SyncRun(function(sync) return sync:Capture() end), {
							hidden = function() return Options.SyncState() ~= 'MASTER' end }),
					}),
					synced = Section(30, 'SYNC STATUS', {
						list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.SyncStatusText() end },
					}),
					version = Section(40, 'VERSION', {
						text = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.VersionText() end },
					}),
				}),
				what = Tab(20, 'WHAT SYNCS', {
					owned = Section(10, 'BANZAI SYNCS', {
						list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.OwnershipSyncText() end },
					}),
					never = Section(20, 'NEVER SYNCED', {
						list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Color(ns.Sync and ns.Sync.NEVER_SYNCED or '', { 1, 1, 1 }) end },
					}),
				}),
				diagnostics = Tab(30, 'DIAGNOSTICS', {
					components = Section(10, 'SYNC DIAGNOSTICS', {
						list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.DiagnosticsText() end },
					}),
					characters = Section(20, 'CHARACTERS ON BANZAI', {
						list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.CharactersText() end },
					}),
				}),
			}, 'tab'),

			components = Page('components', {
				detected = Tab(1, 'COMPONENTS', {
					header = Header(1, 'Components'),
					list = { order = 2, type = 'description', fontSize = 'medium', width = 'full', name = function() return (Options.ComponentLines()) end },
					note = Text(3, Muted('ACTIVE: loaded now. DETECTED: installed but not enabled for this character. MISSING: not installed.')),
				}),
				replacement = Tab(2, 'ADDON REPLACEMENT STATUS', {
					header = Header(1, 'Addon replacement status'),
					intro = Text(2, Muted('Read-only. Which installed addons Banzai has replaced, which it still uses, and which it does not replace. Nothing is removed from here.')),
					replaced = Section(10, 'BANZAI REPLACEMENT COMPLETE', { list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.ReplacementText('REPLACED') end } }),
					keep = Section(20, 'BANZAI STILL USES', { list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.ReplacementText('KEEP') end } }),
					other = Section(30, 'NOT REPLACED', {
						list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.ReplacementText('NOT_REPLACED') end },
						unrelated = { order = 2, type = 'description', fontSize = 'medium', width = 'full', name = function() return Color('Not related to Banzai: ', { 1, 1, 1 }) .. Muted(Options.REPLACEMENT.UNRELATED) end },
					}),
				}),
				ownership = Tab(3, 'FEATURE OWNERSHIP', {
					header = Header(1, 'Who draws what'),
					list = { order = 2, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.OwnershipText() end },
				}),
			}, 'tab'),

			tooltips = Page('tooltips', {
				theme = Section(10, 'THEME', {
					text = Text(1, Muted(Options.TEXT.tooltips)),
					tooltipTheme = Select(2, 'Tooltip theme', 'The font part needs a reload to reach every tooltip.', { BANZAI = 'BANZAI glass', ELVUI = 'ElvUI (Bushido)' }, { 'BANZAI', 'ELVUI' },
						ArtGet('tooltipTheme'), function(_, v) R:SetTooltipTheme(v) Notify() end),
					tooltipOpacity = ArtRange(3, 'tooltipOpacity', 'Glass opacity', nil, 0.5, 1, 0.02, { isPercent = true, disabled = Options.ElvUITooltips }),
					tooltipScale = ArtRange(4, 'tooltipScale', 'Tooltip scale', 'Every tooltip, Banzai\'s and the game\'s.', 0.8, 1.3, 0.05, { isPercent = true }),
				}),
				panel = Section(20, 'BOTTOM PANEL', {
					panelTips = ArtToggle(1, 'panelTips', 'Bottom-panel tooltips', 'Honor, conquest, stats, durability, FPS, latency, time, spec, item level, professions, friends, guild and gold explained when you hover them.'),
					panelTipsCombat = ArtToggle(2, 'panelTipsCombat', 'Also in combat', 'Off: hovering the panel shows nothing while you are in combat.', { disabled = function() local art = Art() return not (art and art:Get('panelTips')) end }),
					panelTipAnchor = Select(3, 'Anchor', nil, { ITEM = 'Above the item', CURSOR = 'At the cursor' }, { 'ITEM', 'CURSOR' }, ArtGet('panelTipAnchor'), ArtSet('panelTipAnchor')),
				}),
				tracker = Section(30, 'OBJECTIVES', {
					trackerTips = ArtToggle(1, 'trackerTips', 'Objective tooltips', 'Hovering a quest or an objective in the Banzai tracker: full title and text, level / type, zone, tracking, progress and its timer where the game has one.'),
				}),
				anchors = Section(40, 'ANCHORS', {
					text = Text(1, Muted(Options.TEXT.anchors)),
				}),
			}),

			afk = Page('afk', {
				screen = Section(10, 'AFK SCREEN', {
					text = Text(1, Muted(Options.TEXT.afk)),
					afk = Toggle(2, 'Enable', 'Banzai\'s AFK screen (ElvUI\'s is switched off while this is on).', ArtGet('afk'), function(_, v) R:SetAFK(v) Notify() end),
					afkModel = AfkToggle(3, 'afkModel', 'Character model', 'Your character in the middle of the screen (off: your Fabled class art there).'),
					afkRotate = AfkToggle(4, 'afkRotate', 'Model rotation', 'The model turns slowly through a full circle.'),
					afkTurn = ArtRange(5, 'afkTurn', 'Seconds per turn', 'Rotation speed: one full turn of the model.', 8, 60, 1, { disabled = function() local art = Art() return not (art and art:Get('afk') and art:Get('afkRotate')) end }),
					afkOpacity = ArtRange(6, 'afkOpacity', 'Background opacity', nil, 0.4, 0.95, 0.05, { isPercent = true }),
					afkBrand = ArtRange(7, 'afkBrand', 'Branding intensity', 'BANZAI, the bamboo tree and the green / purple light.', 0.3, 1, 0.05, { isPercent = true }),
				}),
				shown = Section(20, 'SHOWN', {
					afkName = AfkToggle(1, 'afkName', 'Character name'),
					afkSpec = AfkToggle(2, 'afkSpec', 'Class / spec'),
					afkLevel = AfkToggle(3, 'afkLevel', 'Level'),
					afkZone = AfkToggle(4, 'afkZone', 'Zone'),
				}),
				preview = Section(30, 'PREVIEW', {
					text = Text(1, Muted('Shows the AFK screen now, labelled PREVIEW, without going AFK. Any key or click ends it; combat ends it at once.')),
					afkPreview = Button(2, 'PREVIEW AFK SCREEN', nil, function() Options.PreviewAFK() end),
				}),
			}),

			backup = Page('backup', {
				snapshot = Section(10, 'CURRENT SNAPSHOT', {
					status = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.BackupText() end },
				}),
				preBanzai = Section(20, 'PRE-BANZAI RESTORE', {
					text = Text(1, Muted('This character back to its ElvUI, Details and Kaliel\'s Tracker setup from before Banzai.')),
					restore = Button(2, 'Restore pre-Banzai settings', nil, function() R:Revert() Notify() end, {
						disabled = function() local record = Record() return not (record and record.applied and record.previous) end,
						confirm = true, confirmText = 'Switch this character back to its setup from before Banzai?' }),
				}),
				character = Section(30, 'CHARACTER RESTORE', {
					text = Text(1, Muted('The same, plus this character\'s own BANZAI settings from before Character Sync gave it the master\'s; it stops being synced (and stops being the master).')),
					restoreCharacter = Button(2, 'Restore this character', nil, SyncRun(function(sync) return sync:RestoreCharacter() end), {
						disabled = function() local record = Record() return not (record and record.applied and record.previous) end,
						confirm = true, confirmText = 'Put this character and its BANZAI settings back to how they were before Banzai?' }),
				}),
				kept = Section(40, 'STATUS', {
					text = Text(1, Muted(Options.BACKUP_STATUS)),
				}),
			}),

			about = Page('about', {
				header = Header(1, 'BANZAI'),
				brand = Text(2, Gradient('BANZAI UI BY HARDKORH', LIME, PURPLE), 'large'),
				version = Text(3, 'Version ' .. Color(version, EMERALD) .. '   ' .. Muted('Retail release. Credits, font notices and third-party notices: the docs folder inside the Banzai addon.')),
				credits = Section(10, 'CREDITS', {
					list = { order = 1, type = 'description', fontSize = 'medium', width = 'full', name = function() return Options.CreditsText() end },
				}),
			}),
		},
	}
end

function Options.CreditsText()
	local function author(folder)
		local value = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(folder, 'Author')
		return value and Muted(' - ' .. value) or ''
	end
	return table.concat({
		'Built on ' .. Color('JiberishUI Bushido', { 1, 1, 1 }) .. Muted(' - layout, art and media by JiberishUI (personal use)'),
		Color('ElvUI', { 1, 1, 1 }) .. author('ElvUI'),
		Color('Eltruism', { 1, 1, 1 }) .. author('ElvUI_EltreumUI'),
		Color('mMediaTag & Tools', { 1, 1, 1 }) .. author('ElvUI_mMediaTag'),
		Color('Jiberish Icons, JiberishMedia', { 1, 1, 1 }) .. author('JiberishMedia'),
		Color('Details! Damage Meter', { 1, 1, 1 }) .. author('Details'),
		Color('Kaliel\'s Tracker', { 1, 1, 1 }) .. author('!KalielsTracker') .. Muted(' (hidden while the Banzai tracker is on)'),
		Color('Syndicator', { 1, 1, 1 }) .. author('Syndicator') .. Muted(' (gold of your other characters and the Warband bank, read only)'),
		Color('MinimapButtonButton', { 1, 1, 1 }) .. author('MinimapButtonButton'),
		Color('Fonts', { 1, 1, 1 }) .. Muted(' - Shojumaru as BANZAI Default at 105%, Information Font for explicit selection and whole-string fallback, GasoekOne as the previous display face'),
		Color('Banzai bamboo art and code', { 1, 1, 1 }) .. Muted(' - original, HARDKORH'),
	}, '\n')
end

function Options.Insert()
	local E = Engine()
	if E and E.Options and E.Options.args then
		E.Options.args.banzai = Options:Build()
	end
end

function Options:Register()
	local plugins = _G.LibStub and _G.LibStub('LibElvUIPlugin-1.0', true)
	if not plugins or self.registered then return false end
	plugins:RegisterPlugin(addonName, Options.Insert)
	self.registered = true
	return true
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('PLAYER_LOGIN')
frame:SetScript('OnEvent', function(self)
	self:UnregisterEvent('PLAYER_LOGIN')
	Options:Register()
end)
