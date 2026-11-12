--[[
	BANZAI - Sync.lua  (Character Sync)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	One approved Banzai setup, applied the same way to Darren's other characters,
	from BANZAI > CHARACTER SYNC (no slash commands needed).

	  BANZAI MASTER   a character that runs Banzai is designated master by Darren
	                  (SET AS BANZAI MASTER - never set automatically); its
	                  configuration is captured with a revision number (again at
	                  every logout of the master, and with CAPTURE MASTER NOW),
	                  with its identity (character, class, spec, role), the
	                  BANZAI version and the configuration schema
	  what is synced  only what Banzai owns and maps: this character's BANZAI
	                  settings (frames, theme, bottom panel, tracker, cast
	                  history, action-button style, health text, fonts, buff /
	                  ToT size, identity circles, the DPS / HEALER frame positions
	                  with the party / arena allies arrangement; 1.0.0: frame
	                  widths, AFK screen, tooltip preferences: every BANZAI setting) and, through
	                  Banzai's own Apply, the shared Banzai ElvUI profile (with
	                  its Eltruism / mMediaTag / Jiberish presentation), the
	                  Banzai Details layout, the minimap / Kaliel's Tracker
	                  placement and the role layout for this character's spec
	  never touched   spells and action assignments, macros, talents, equipment
	                  sets, keybindings, Details combat history, currencies, chat
	                  history, progression and unrelated addons (no full saved
	                  variables or WTF folders are copied)
	  identity        never copied: class colours, Fabled class / spec art,
	                  resources and the role layout come from the character itself

	  APPLY BANZAI        unsynced character: a checked pre-Banzai backup first
	                      (the record Backup & Restore uses plus this character's
	                      own BANZAI settings) - no backup, no apply - then the
	                      master's settings and Apply; synced only when the apply
	                      succeeded; a reload is requested (the ElvUI profile switches)
	  UPDATE CHARACTER    shown when the master's revision is newer; nothing is
	                      overwritten until Darren chooses it; a reload only when
	                      something ElvUI reads at load changed
	  RESTORE PRE-BANZAI  the character's own snapshot back

	1.0.1 (Character Sync validation build): the backup is checked before the
	apply, a required component missing blocks it, optional ones are skipped
	honestly (SYNC DIAGNOSTICS), the master records the configuration schema.
	Fonts and the unit layout are per character (Restore:Own), so a change on the
	master reaches another character only through UPDATE CHARACTER; revisions
	only ever count up (a master restored and set again still shows alts an
	update); the cooldown bars' tracked spells (class abilities) never leave a
	character. Nothing ever runs on another character by itself: every apply /
	update is Darren's click on that character. (The shared ElvUI profile is one
	profile: what is changed in ElvUI's own options on a Banzai character is
	there for every Banzai character.)
]]
local _, ns = ...
local T = ns.Transform

local Sync = {}
ns.Sync = Sync
_G.BanzaiSync = Sync

-- the Banzai configuration a master hands on: its shape (1: up to 1.0.0; 2: 1.0.1 identity / schema / backup records)
Sync.SCHEMA = 3

Sync.STATES = {
	MASTER = 'BANZAI MASTER',
	SYNCED = 'BANZAI SYNCED',
	UPDATE = 'BANZAI UPDATE AVAILABLE',
	NOT_SYNCED = 'THIS CHARACTER IS NOT SYNCED',
	NO_MASTER = 'NO BANZAI MASTER SET',
}

-- the confirmation before APPLY BANZAI / UPDATE CHARACTER
Sync.APPLIES = { 'visual theme', 'Banzai layout', 'unit-frame presentation', 'role layout', 'Chat / Details / Minimap', 'tooltips', 'AFK screen', 'PvP visual configuration', 'supported addon presentation' }
Sync.NEVER = { 'abilities', 'action assignments', 'keybinds', 'macros', 'talents', 'gear', 'gameplay history' }

-- exactly what Character Sync carries (CHARACTER SYNC > WHAT SYNCS)
Sync.OWNERSHIP = {
	{ 'BANZAI', 'theme, gradients, bamboo, panel style (border style, background, border scale, glass opacity, parchment brightness), fonts (display face: BANZAI Default / Shojumaru at 105%, Automatic, Information Font or Previous - plus its size), tooltips, AFK screen, objective tracker (on / off, collapsed - which tracker owns the screen follows it), Cast History appearance, cooldown-bar appearance, bottom panel, chat / Details / minimap appearance, action-button appearance (button style: Banzai Square / Banzai Circles / ElvUI Square), BUFFS panel (on, rows, position; never the buffs themselves), the unit-frame style (BANZAI CLASSIC / BANZAI SPLIT with its Player / Target positions, frame and central-icon scale, bar thickness, HP / resource text, enhanced targeted nameplate and party style), the Details meter style (BANZAI CURRENT / BANZAI COMPACT; never the Details history), identity art (1.3.2: BANZAI / FABLED / CLASS COLOUR - the choice only, never the art files), the split cast bar (1.3.3: on / off, spell name, timer - the choices only, never a live cast), PvP choices (role icons, trinket, CC and dispel presentation), preview preferences - every choice made in the BANZAI settings except the tracked cooldowns (class abilities: each character keeps its own)' },
	{ 'ELVUI (the shared Banzai profile)', 'the Banzai visual profile: unit-frame dimensions (Player / Target / Focus / Target-of-Target width; 1.3.0: the BANZAI SPLIT sizes and places when that is the style), Banzai positions, nameplates, chat presentation, action-bar VISUAL settings (size, spacing, keybind / count text - never what is on the bars), frame presentation' },
	{ 'ROLE LAYOUTS', 'DPS and HEALER: party, raid, arena allies and arena enemy positions with the sizes of party, arena allies and arena enemies (the HEALER party and arena allies each keep their own place); Focus / Target-of-Target placement' },
	{ 'MMEDIATAG / JIBERISH', 'only what the Banzai profile sets: the Fabled class / spec identity presentation and the cast ring' },
	{ 'DETAILS', 'the Banzai Details profile: meter layout, fonts, bar and window styling, the side-by-side position (Details\' own profile and window API; combat history stays)' },
}
Sync.NEVER_SYNCED = 'Never copied or overwritten: action-bar spell assignments, spells (the cooldown bars\' tracked spells included), macros, keybinds, talents and loadouts, equipment and equipment sets, consumables, class-specific spell placement, Details combat history, chat history, currencies, quests, reputation, progression, unrelated addon settings. No full SavedVariables database is cloned. Class colours, the Fabled class / spec art, resources and the role layout come from each character itself.'

-- BANZAI settings that are class abilities: never in the master's configuration,
-- never written to another character (1.0.1: the cooldown bars' tracked spells)
Sync.CHARACTER_OWN = { 'cdTracked' }

local function WithoutOwn(settings)
	local out = {}
	for k, v in pairs(type(settings) == 'table' and settings or {}) do out[k] = v end
	for _, k in ipairs(Sync.CHARACTER_OWN) do out[k] = nil end
	return out
end

-- what a sync needs (required) and what it presents when it is there (optional:
-- skipped honestly when missing). READY | MISSING | SKIPPED | ERROR
Sync.COMPONENTS = {
	{ name = 'ElvUI', folder = 'ElvUI', required = true, ready = function()
		local engine = _G.ElvUI
		local E = engine and engine[1]
		return E and E.data and E.data.GetCurrentProfile and _G.ElvDB and _G.ElvPrivateDB and true
	end },
	{ name = 'Banzai Art', folder = 'BushidoPrivateCompat', required = true, ready = function()
		local art = _G.BanzaiCompat
		return art and art.Export and art.Import and true
	end },
	{ name = 'Eltruism', folder = 'ElvUI_EltreumUI' },
	{ name = 'mMediaTag', folder = 'ElvUI_mMediaTag' },
	{ name = 'Jiberish Icons', folder = 'JiberishIcons' },
	{ name = 'JiberishMedia', folder = 'JiberishMedia' },
	{ name = 'Details', folder = 'Details', ready = function()
		local d = _G.Details
		return d and d.GetProfile and d.ApplyProfile and true
	end },
	{ name = 'Kaliel\'s Tracker', folder = '!KalielsTracker', ready = function() return type(_G.KalielsTrackerDB) == 'table' end },
	{ name = 'MinimapButtonButton', folder = 'MinimapButtonButton', ready = function() return type(_G.MinimapButtonButtonOptions) == 'table' end },
}

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function Art()
	return _G.BanzaiCompat
end

local function DB()
	_G.BushidoPrivateRestoreDB = _G.BushidoPrivateRestoreDB or {}
	local db = _G.BushidoPrivateRestoreDB
	db.characters = db.characters or {}
	db.sync = db.sync or {}
	db.fonts = db.fonts or {}
	db.layout = db.layout or {}
	return db
end

local function Now() return date('%Y-%m-%d %H:%M:%S') end

function Sync.Key()
	local E = Engine()
	return E and E.mynameRealm
end

local function Record(key)
	return DB().characters[key or Sync.Key()]
end

-- name, class, spec and role of the character that is logged in (its own, never the master's)
function Sync:Identity()
	local className, token = UnitClass('player')
	local spec = ns.Roles and ns.Roles.Spec and ns.Roles.Spec()
	return {
		key = self.Key(), class = className, classToken = token,
		spec = spec and spec.name, specID = spec and spec.id, role = spec and spec.layout or 'DPS', specRole = spec and spec.role,
	}
end

function Sync:Master()
	return DB().sync.master
end

-- each component's state right now
function Sync:Diagnostics()
	local out = {}
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
	for _, c in ipairs(self.COMPONENTS) do
		local isLoaded = loaded and loaded(c.folder) and true or false
		local state
		if not isLoaded then
			state = c.required and 'MISSING' or 'SKIPPED'
		elseif c.ready then
			local ok, ready = pcall(c.ready)
			state = (ok and ready) and 'READY' or 'ERROR'
		else
			state = 'READY'
		end
		out[#out + 1] = { name = c.name, state = state, required = c.required and true or false }
	end
	return out
end

-- a required component that is not READY blocks a sync (its name and state), else nil
function Sync:Blocked()
	for _, c in ipairs(self:Diagnostics()) do
		if c.required and c.state ~= 'READY' then return c.name .. ' ' .. c.state end
	end
	return nil
end

-- the configuration a master hands to its alts: Banzai-owned settings only
function Sync:Config()
	local art = Art()
	local own = ns.Restore:Own(self.Key()) -- this character's fonts and unit layout (1.0.1)
	return {
		flavor = ns.Flavor and ns.Flavor.Id() or 'RETAIL',
		settings = WithoutOwn(art and art.Export and art:Export()),
		fonts = { display = own.fonts.display, small = own.fonts.small },
		layout = { buffScale = own.layout.buffScale, unitHeight = own.layout.unitHeight, unitSpread = own.layout.unitSpread },
	}
end

function Sync:ConfigCompatibility(config)
	if type(config) ~= 'table' then return false, 'the master has no configuration to preview or apply' end
	local source = config.flavor
	local target = ns.Flavor and ns.Flavor.Id() or 'RETAIL'
	if source == nil then return false, 'the master configuration has no client flavor; recapture it on the master first' end
	if source ~= target then return false, 'client flavor mismatch (' .. tostring(source) .. ' -> ' .. tostring(target) .. ')' end
	return true
end

-- the highest configuration revision any master has published: a master set
-- again (or another one) continues from it, so characters synced earlier
-- always see the next configuration as an update
local function LastRevision()
	local db = DB()
	local last = db.sync.lastRevision or 0
	if db.sync.master then last = math.max(last, db.sync.master.revision or 0) end
	for _, record in pairs(db.characters) do
		if type(record) == 'table' and type(record.sync) == 'table' then last = math.max(last, record.sync.revision or 0) end
	end
	return last
end

-- master only, and only while it runs Banzai: store the current configuration
-- (frame positions moved this session included); a new revision when it changed
function Sync:Capture()
	local master = self:Master()
	local key = self.Key()
	if not (master and key and master.key == key) then return false end
	local record = Record(key)
	if not (record and record.applied) then return false end -- a restored master publishes nothing
	if self:Blocked() then return false end -- (Banzai Art not running: nothing to publish)
	if ns.Roles and ns.Roles.Capture then ns.Roles:Capture() end
	local config = self:Config()
	if next(config.settings) == nil then return false end -- never an empty setup (alts would lose their role positions)
	local signature = T.Serialize(config) .. '|' .. tostring(ns.VERSION) .. '|' .. self.SCHEMA
	local who = self:Identity()
	master.class, master.classToken, master.spec, master.specID, master.role = who.class, who.classToken, who.spec, who.specID, who.role
	if signature ~= master.signature then
		master.revision = math.max(master.revision or 0, LastRevision()) + 1
		DB().sync.lastRevision = master.revision
		master.signature = signature
		master.config = config
		master.version = ns.VERSION
		master.schema = self.SCHEMA
		master.captured = Now()
	end
	record.sync = { revision = master.revision, master = key, time = master.captured, version = master.version, schema = master.schema }
	return true
end

-- Darren's choice on the character whose setup he approved (never automatic).
-- A new master continues the highest revision ever published (LastRevision),
-- so characters synced to an earlier master see an update (State also
-- compares the master's name)
function Sync:SetMaster()
	local record = Record()
	if InCombatLockdown() then return false, 'Not in combat.' end
	if not (record and record.applied) then return false, 'Apply Banzai on this character first.' end
	local blocked = self:Blocked()
	if blocked then return false, blocked .. ': no master was set.' end
	DB().sync.master = { key = self.Key(), revision = LastRevision() }
	self:Capture()
	return true
end

-- the character left Banzai (any restore): it is no longer synced, and no
-- longer the master (the revisions it published stay counted)
function Sync:Forget(key)
	local db = DB()
	local record = db.characters[key]
	if record then record.sync = nil end
	local master = db.sync.master
	if master and master.key == key then
		db.sync.lastRevision = math.max(db.sync.lastRevision or 0, master.revision or 0)
		db.sync.master = nil
	end
end

-- MASTER | SYNCED | UPDATE | NOT_SYNCED | NO_MASTER
function Sync:State(key)
	key = key or self.Key()
	local record = Record(key)
	local master = self:Master()
	local applied = record and record.applied and true or false
	if not applied then return 'NOT_SYNCED' end
	if not master then return 'NO_MASTER' end
	if master.key == key then return 'MASTER' end
	local sync = record.sync
	if not sync or sync.master ~= master.key or (sync.revision or 0) < (master.revision or 0) then return 'UPDATE' end
	return 'SYNCED'
end

function Sync:StatusText()
	local state = self:State()
	local master = self:Master()
	local text = self.STATES[state]
	if master then text = text .. ' (master ' .. tostring(master.key) .. ', revision ' .. tostring(master.revision or 0) .. ')' end
	return text
end

function Sync:Preview()
	local master = self:Master()
	local config = master and master.config
	local compatible, reason = true, nil
	if master and master.key ~= self.Key() then compatible, reason = self:ConfigCompatibility(config) end
	local applied, skipped = 0, 0
	if type(config) == 'table' then
		for _ in pairs(type(config.settings) == 'table' and config.settings or {}) do applied = applied + 1 end
		for _ in pairs(type(config.fonts) == 'table' and config.fonts or {}) do applied = applied + 1 end
		for _ in pairs(type(config.layout) == 'table' and config.layout or {}) do applied = applied + 1 end
	end
	for _, component in ipairs(self:Diagnostics()) do
		if not component.required and component.state ~= 'READY' then skipped = skipped + 1 end
	end
	local clientState = DB().client
	local report = type(clientState) == 'table' and clientState.report
	local role = ns.Roles and ns.Roles.Detection and ns.Roles:Detection()
	return {
		client = ns.Flavor and ns.Flavor.Id() or 'RETAIL',
		master = master and master.key or nil,
		source = config and config.flavor or (master and 'UNKNOWN' or 'NONE'),
		compatible = compatible,
		blocked = not compatible and reason or nil,
		applied = compatible and applied or 0,
		adapted = compatible and #(type(report) == 'table' and report.changes or {}) or 0,
		skipped = skipped,
		role = role and role.layout or (ns.Roles and ns.Roles.Current()) or 'DPS',
		roleSource = role and role.reason or 'local layout',
		preserved = { 'role override', 'tracked cooldowns', 'action assignments', 'keybindings', 'talents', 'equipment' },
	}
end

-- the pre-Banzai backup is in place for this character (taken by APPLY BANZAI first)
function Sync:BackupReady(key)
	local record = Record(key)
	return record and record.previous and record.previous.time and true or false
end

-- what APPLY / UPDATE will (and will never) change, for the confirmation
function Sync:Plan()
	local who = self:Identity()
	local lines = { 'BANZAI WILL APPLY:' }
	local preview = self:Preview()
	lines[#lines + 1] = '- client: ' .. tostring(preview.client) .. '; master flavor: ' .. tostring(preview.source)
	lines[#lines + 1] = '- settings planned: ' .. tostring(preview.applied) .. '; adapted: ' .. tostring(preview.adapted) .. '; skipped: ' .. tostring(preview.skipped)
	lines[#lines + 1] = '- local role/layout: ' .. tostring(preview.role) .. ' (' .. tostring(preview.roleSource) .. ')'
	if preview.blocked then lines[#lines + 1] = '- BLOCKED: ' .. preview.blocked end
	for _, item in ipairs(self.APPLIES) do
		if item == 'role layout' then item = item .. ' (' .. who.role .. ' for ' .. tostring(who.spec or 'this spec') .. ')' end
		lines[#lines + 1] = '- ' .. item
	end
	lines[#lines + 1] = 'BANZAI WILL NOT CHANGE:'
	for _, item in ipairs(self.NEVER) do lines[#lines + 1] = '- ' .. item end
	lines[#lines + 1] = '- preserved local settings: ' .. table.concat(preview.preserved, ', ')
	return lines
end

-- this character takes the master's configuration (Banzai-owned settings only)
function Sync:Receive(config)
	local compatible, reason = self:ConfigCompatibility(config)
	if not compatible then return false, reason end
	local art = Art()
	local own = ns.Restore:Own(self.Key())
	if art and art.Import and config.settings then art:Import(WithoutOwn(config.settings)) end -- (a master captured before 1.0.1 may still carry them)
	if config.fonts then own.fonts.display, own.fonts.small = config.fonts.display, config.fonts.small end
	if config.layout then
		for k, v in pairs(config.layout) do own.layout[k] = v end
	end
	return true
end

-- this character's own BANZAI settings, fonts and unit layout, before a master's replace them
local function OwnBackup(key)
	local art = Art()
	local settings = art and art.Export and art:Export()
	if type(settings) ~= 'table' then return nil end
	local own = ns.Restore:Own(key)
	return { time = Now(), settings = settings, fonts = T.DeepCopy(own.fonts), layout = T.DeepCopy(own.layout) }
end

-- RESTORE PRE-BANZAI / a failed apply: that backup back on this character
local function PutBack(key, backup)
	if not backup then return end
	local art = Art()
	if backup.settings and art and art.Import then art:Import(backup.settings) end
	local record = DB().characters[key]
	if record then
		if backup.fonts then record.fonts = T.DeepCopy(backup.fonts) end
		if backup.layout then record.layout = T.DeepCopy(backup.layout) end
	end
end

-- the pre-Banzai backup of an unsynced character: the record Backup & Restore
-- uses (Restore:Snapshot) and its own BANZAI settings. Taken once (kept on a
-- repeat); checked before anything is applied. Returns true, or false and why.
function Sync:Backup(key)
	local db = DB()
	local record = db.characters[key] or {}
	db.characters[key] = record
	if record.syncBackup and type(record.syncBackup.settings) ~= 'table' then record.syncBackup = nil end -- (an unusable one is taken again)
	local hadPrevious, hadBackup = record.previous ~= nil, record.syncBackup ~= nil
	local ok, err = pcall(function()
		local previous, problem = ns.Restore:Snapshot(key)
		if not previous then error(problem or 'the pre-Banzai record could not be taken', 0) end
		if not record.syncBackup then
			record.syncBackup = OwnBackup(key)
			if not record.syncBackup then error('the BANZAI settings of this character could not be read', 0) end
		end
	end)
	if ok and record.previous and record.previous.time and record.syncBackup and type(record.syncBackup.settings) == 'table' then return true end
	-- nothing half-made is left behind: a failed backup leaves the character as it was
	if not hadPrevious then record.previous = nil end
	if not hadBackup then record.syncBackup = nil end
	return false, ok and 'the backup could not be checked' or tostring(err)
end

local function Fail(key, message)
	Sync.lastError = { key = key, text = message, time = Now() }
	return false, message
end

function Sync:Apply()
	if InCombatLockdown() then return false, 'Not in combat.' end
	local key = self.Key()
	if not key then return false, 'ElvUI is not ready.' end
	local record = Record(key)
	if record and record.applied then return self:Update() end -- already on Banzai: same as UPDATE (idempotent)
	local blocked = self:Blocked()
	if blocked then return Fail(key, blocked .. ': Banzai was NOT applied.') end
	local master = self:Master()
	if master and master.key ~= key then
		local compatible, reason = self:ConfigCompatibility(master.config)
		if not compatible then return Fail(key, reason .. ': Banzai was NOT applied.') end
	end
	-- 1.5.0-dev1 (WoW Forever): the prerequisites are asked before anything is recorded, so an apply that
	-- cannot go ahead leaves no pre-Banzai snapshot behind for a later one to reuse
	if ns.Flavor and ns.Flavor.IsForever() and ns.Restore.Preflight then
		local pre = ns.Restore:Preflight()
		if pre.blocked then return Fail(key, 'Banzai was NOT applied: ' .. pre.blocked .. '. /banzai forever shows every component.') end
	end
	local backed, why = self:Backup(key)
	if not backed then return Fail(key, 'PRE-BANZAI BACKUP FAILED (' .. tostring(why) .. '): Banzai was NOT applied.') end
	record = Record(key)
	local ran, ok = pcall(function()
		if master and master.key ~= key then
			local received, reason = self:Receive(master.config)
			if not received then error(reason, 0) end
		end
		return ns.Restore:Apply('character sync', { reuse = true })
	end)
	if not (ran and ok) then
		-- not applied: its own BANZAI settings, fonts and layout back, nothing marked as synced
		PutBack(key, record.syncBackup)
		pcall(ns.Restore.TrackerOwnership, ns.Restore, 'sync failed') -- 1.0.2: Blizzard's tracker only parked if the Banzai tracker really shows
		local why = ran and 'see chat' or tostring(ok)
		return Fail(key, 'Banzai could not be applied (' .. why .. '): nothing was marked as synced.'
			.. (Record(key).applied and ' RESTORE PRE-BANZAI puts this character back.' or ''))
	end
	if ns.Roles then pcall(ns.Roles.Apply, ns.Roles, ns.Roles.Current() or 'DPS', 'sync') end -- (the layer already carries the role's layout)
	record = Record(key)
	record.sync = { revision = master and master.revision or 0, master = master and master.key, time = Now(),
		version = master and master.version or ns.VERSION, schema = master and master.schema or self.SCHEMA }
	if self.lastError and self.lastError.key == key then self.lastError = nil end
	return true
end

function Sync:Update()
	if InCombatLockdown() then return false, 'Not in combat.' end
	local key = self.Key()
	local record = Record(key)
	if not (record and record.applied) then return false, 'This character is not synced yet.' end
	local blocked = self:Blocked()
	if blocked then return Fail(key, blocked .. ': nothing was updated.') end
	local master = self:Master()
	if master and master.key ~= key then
		local compatible, reason = self:ConfigCompatibility(master.config)
		if not compatible then return Fail(key, reason .. ': nothing was updated.') end
	end
	local R = ns.Restore
	if master and master.config and master.key ~= key then
		-- a character on Banzai from before Character Sync: its own setup saved first (RESTORE PRE-BANZAI)
		if not (record.syncBackup and type(record.syncBackup.settings) == 'table') then record.syncBackup = OwnBackup(key) end
		local received, reason = self:Receive(master.config)
		if not received then return Fail(key, reason .. ': nothing was updated.') end
	end
	local reload = R:CharacterLayer(key)
	-- the tracker choice came with the settings: Kaliel's Tracker follows it
	local art = Art()
	local tracker = not (art and art.Get and art:Get('tracker') == false)
	local trackerWas = record.previous and record.previous.trackerVisibility ~= nil
	if record.previous and tracker ~= trackerWas then
		local result = R:SetKalielHidden(record, key, tracker)
		-- Kaliel's Tracker reads its visibility at load (a reload only when it was changed)
		if result == 'hidden (Banzai tracker on)' or result == 'shown again' then reload = true end
	end
	R:ApplyDetails(record, R:Fonts().small)
	R:LayoutDetailsSoon()
	R:TrackerOwnership('update') -- 1.0.2: one objective tracker (the tracker choice may have come with the settings)
	if ns.Roles then ns.Roles:Apply(ns.Roles.Current() or ns.Roles:Active(), 'sync update') end
	record.sync = { revision = master and master.revision or 0, master = master and master.key, time = Now(),
		version = master and master.version or ns.VERSION, schema = master and master.schema or self.SCHEMA }
	record.applied.version = ns.VERSION
	if self.lastError and self.lastError.key == key then self.lastError = nil end
	if reload then StaticPopup_Show('BANZAI_RELOAD') end
	return true, reload
end

function Sync:RestoreCharacter()
	local key = self.Key()
	local record = Record(key)
	local backup = record and record.syncBackup
	if not ns.Restore:Revert() then return false end -- (Revert -> Forget: not synced, not the master)
	record = Record(key)
	if record then
		PutBack(key, backup)
		record.syncBackup = nil
	end
	if self.lastError and self.lastError.key == key then self.lastError = nil end
	return true
end

-- characters this account knows, with their state (short list for the page)
function Sync:Characters()
	local list, seen = {}, {}
	local db = DB()
	local function add(key)
		if seen[key] then return end
		seen[key] = true
		list[#list + 1] = { key = key, state = self:State(key) }
	end
	for key in pairs(db.characters) do add(key) end
	local keys = _G.ElvDB and _G.ElvDB.profileKeys
	if type(keys) == 'table' then for key in pairs(keys) do add(key) end end
	table.sort(list, function(a, b) return a.key < b.key end)
	return list
end

local events = CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGOUT')
events:SetScript('OnEvent', function() Sync:Capture() end)
