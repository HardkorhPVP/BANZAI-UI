--[[
	BANZAI - Restore.lua  (Banzai)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	Applies the historical JiberishUI Bushido configuration (payloads from
	Bushido commit 624839aa, see Payloads.lua) to the addon versions installed
	today, without running Bushido's old installer, then the Banzai layer:

	  ElvUI     profile, private profile and global values, written as the
	            profile "JiberishUI - Bushido Private" (existing profiles untouched;
	            the profile keeps its name so saved state and rollback stay valid)
	  Eltruism  carried inside the ElvUI profile (its own settings namespace)
	  mMediaTag 3.73 settings rebuilt for 4.17 (Transform.lua)
	  Details   Bushido window profile only (Details global / player data and
	            combat history are left alone); this character is exempted from
	            Details' "always use this profile" so the layout survives a login
	  Banzai    minimap cluster top-right; Kaliel's Tracker placed below it (its
	            own saved settings); 0.3.0: identity line, health value + percent,
	            readable small font, Details DAMAGE | HEALING side by side
	            (Details' own window API), Banzai bottom bar in place of Bushido's
	            datatext panel; 0.4.0: nameplates, health inside the bars, buffs
	            top-left at 70%, smaller Target-of-Target, small chat font, the
	            minimap button collector in the top-right corner and, while the
	            Banzai tracker is on, Kaliel's Tracker hidden through its own
	            visibility setting; 0.5.0: smooth health textures (Eltruism /
	            ElvUI texture settings, Details rows), Bushido's target cooldown
	            bars (ElvUI bars 2 + 4) off, bottom action bars 4 up for the
	            taller panel, chat panel inside the lower-left Banzai frame

	Everything it changes is recorded first; Backup & Restore in the BANZAI
	options (or /banzai restore) puts it back. Applies on demand (HOME > APPLY
	BANZAI, /banzai apply, Character Sync); AUTO_APPLY is empty in the public
	release. A character
	that applied an older build gets the Banzai layer on its next login
	(targeted keys only, written while the addons load).

	0.6.0: Character Sync (Sync.lua) applies the master's approved setup to an
	alt through the same Apply (the shared Banzai ElvUI profile is reused, not
	rebuilt), and every character's own BANZAI settings and role layout are
	written into that profile when it logs in, before ElvUI builds its frames
	(only when another character or other settings wrote it last).

	0.7.0: the HEALER layout puts party / arena allies in one horizontal row in
	the centre (Roles.lua, with the arena context); the secondary frames get
	their health inside the bars and Banzai identity circles (mMediaTag's
	portraits off on those frames); Details titles are Banzai's own, its rows
	lower and its values without the percentage.

	0.8.0: PvP-first unit frames (Transform T.ApplyPvP) through ElvUI's own
	elements and the game's own aura categories; one live arena enemy system:
	sArena Reloaded when it is loaded (ElvUI's arena enemy frames off), else
	ElvUI's arena frames in the Banzai design. BANZAI -> PVP in the options.

	0.9.0: PvP unit frames refined (narrow party / arena frames with role icon,
	trinket circle, CC and dispel states; arena enemies mirrored on the right)
	and the player's own cooldown bars (BushidoPrivateCompat).

	1.0.0 (a private milestone, not a public release): Player / Target / Focus /
	Target-of-Target at half width (BANZAI > UNIT FRAMES, per character, a
	reload applies it), the HEALER row just above the Player / Target region,
	the settings as one BANZAI application (Options.lua), Banzai's own AFK
	screen (ElvUI's off while it is on), the tooltip theme and the bottom-panel
	/ objective tooltips (BushidoPrivateCompat).

	1.0.1 (Character Sync validation build): Banzai's mirrored arena enemy
	frames are the only arena enemy system - no sArena integration, choice or
	state handling any more (DR is not a Banzai feature; sArena is never
	touched, Darren removes it himself). Character Sync takes a checked
	pre-Banzai backup before it applies anything (Sync.lua).

	1.0.2: one objective tracker on screen - Blizzard's objective tracker is
	parked out of sight while the Banzai tracker shows (Kaliel's Tracker is not
	loaded on most of Darren's characters, so nothing else kept it away); its
	state before Banzai is in the pre-Banzai record and comes back on restore.

	1.0.3: the parking holds. The game and Eltruism put Blizzard's tracker
	back on screen after Banzai parked it: Edit Mode re-anchors every system
	frame (SetParent to its managed container or to UIParent) whenever a layout
	is applied - at login, on EDIT_MODE_LAYOUTS_UPDATED, on a spec change and
	on leaving Edit Mode - and Eltruism re-anchors the tracker (SetParent to
	UIParent) at every PLAYER_ENTERING_WORLD (in a handler registered at ElvUI's
	init, after Banzai's, so it ran after Banzai's 1.0.2 check), FIRST_FRAME_RENDERED,
	ACTIVE_TALENT_GROUP_CHANGED and EDIT_MODE_LAYOUTS_UPDATED. Ownership is now
	reasserted one frame after each of those events (one queued check at a
	time, so it runs after every other handler of the same event whatever the
	order), out of combat; the function itself is unchanged and idempotent.

	1.3.0: the optional BANZAI SPLIT unit frames (BANZAI > UNIT FRAMES > FRAME
	STYLE, never chosen by itself: every character stays BANZAI CLASSIC until
	Darren picks SPLIT) - written as part of the character layer over the
	classic one and taken back exactly (Transform T.ApplyFrameStyle, the record
	in BushidoPrivateRestoreDB.splitLayer); and the Details meter interior
	BANZAI CURRENT (default) | BANZAI COMPACT through Details' own row settings
	and window API, applied live.

	1.3.1: BANZAI SPLIT corrected after Darren's runtime screenshots (Banzai Art:
	class-coloured continuous bars, values above / name and spec under them,
	thicker bars; the split layer marks those lines as Banzai Art's and moves the
	class bar above the values - a split character's layer is rewritten at its
	next login), 	the licensed Banzai display-font selection (BANZAI > APPEARANCE >
	FONTS; the BANZAI COMPACT Details names follow it), and the objective tracker
	ownership made to hold: Blizzard's tracker is parked again whenever anything
	puts it back on screen while the Banzai tracker shows (Restore:WatchTracker).

	1.3.2: Darren's original BANZAI class identities (Banzai Art's media,
	converted by the build from his masters) in the BANZAI SPLIT hubs and party
	circles, with BANZAI > UNIT FRAMES > IDENTITY ART (Restore:SetIdentityArt,
	at once, carried by Character Sync). Nothing else changes.

	1.3.3: BANZAI SPLIT Player / Target - the central hub 25 % larger, the spell
	icon alone in it while a cast shows, the bamboo cast bar above the values
	(BANZAI > UNIT FRAMES > FRAME STYLE > SPLIT CAST BAR: the bar, the spell name,
	the timer; the class bar moves above the cast bar while it is on - a split
	character's layer is rewritten at its next login); the PvP frames' CC /
	dispel emphasis never resizes anything after it is made; the TARGET NPC
	preview is Banzai's own synthetic sample.

	1.3.4 (hotfix): the PvP frames never decorate inside a party / arena frame's
	tree any more (the CC / dispel border on ElvUI's aura icons is retired; the
	trinket circles and target / focus markers are Banzai's own frames beside
	the unit frames, behind one access check); the bamboo cast bar about 40 %
	lower with the same spell name size (a split character's layer is rewritten
	once: the class bar follows the bar down).

	1.3.5: a thin BANZAI gradient divider between the DAMAGE and HEALING meters;
	Banzai's own PvP target / focus outlines are put away at once on a loading
	screen, a zone or spec change and when Banzai Art is switched off. (The
	gold lines across the world and the OFF / CD / DEF / INT / CC / DISP / GUI
	strip Darren saw are not Banzai's: docs/BANZAI-1.3.5-LINES-NOTE.md.)

	1.3.6: a real centre gutter between the DAMAGE and HEALING meters - both
	windows a little narrower inside the unchanged bamboo frame, the divider in
	the middle of the gutter. A character's first 1.3.6 login places the two
	windows again (geometry only: what they show, their segments and whether
	they are open stay as they are), on Banzai's Details profile only.

	1.3.7: HARDKORH PARCHMENT is one paper that is never stretched - the same
	grain size on BUFFS, chat and Details, its worn edge repeating along every
	side (Banzai Art); GLASS, SOLID and the bamboo unchanged.

	Normal configuration: ElvUI options > BANZAI (Options.lua); the BANZAI
	wordmark at the top of the screen opens it on HOME.
	/banzai opens it; /banzai status | apply | restore | theme vibrant|class | editmode
	(/bushido works too).
]]
local addonName, ns = ...
local T = ns.Transform

local Restore = {}
ns.Restore = Restore

local NAME = 'BANZAI'
local VERSION = '1.4.0'
ns.VERSION = VERSION
ns.NAME = NAME

-- Applies automatically for the characters listed here at their first login (empty in the public release:
-- every character applies from HOME > APPLY BANZAI, /banzai apply or Character Sync).
local AUTO_APPLY = {}
local STATUSBARS = { 'OverwatchJiberish1', 'OverwatchJiberish2', 'OverwatchJiberish3', 'OverwatchJiberish4', 'Eltreum-Blank' }

-- Top-right column (UIParent units below the top edge / left of the right edge).
-- The minimap composition (TOPRIGHT -21,-48, 185 map, Banzai frame + zone name
-- above it) ends about 270 below the top and about 250 from the right edge.
local CLEAR_RIGHT = 260
local MINIMAP_BUTTON_CORNER = 2 -- minimap button collector: extreme top-right corner
local TRACKER_TOP = 292         -- Kaliel's Tracker (when the Banzai tracker is off): below the minimap
local DETAILS_TOP = 276        -- Bushido Details frame + swords reach ~270 above the bottom edge (+6 gap)
local MIN_TRACKER_HEIGHT = 200
-- Kaliel's Tracker visibility contexts (its options: visibility per zone type)
local KALIEL_CONTEXTS = { 'world', 'city', 'house', 'dungeon', 'mythicplus', 'raid', 'arena', 'battleground', 'petbattle', 'rare' }

local function Print(...)
	print('|cff00ccffBanzai|r:', ...)
end

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function LSM()
	return _G.LibStub and _G.LibStub('LibSharedMedia-3.0', true)
end

local function FontValid(name)
	local media = LSM()
	return media and media:IsValid('font', name) or false
end

-- 1.0.1: the fonts and the unit layout (Player / Target height and spread,
-- buff size) are each character's own once it has a Banzai record, like its
-- BANZAI settings: a change on the master reaches another character only with
-- UPDATE CHARACTER. The account-wide values (up to 1.0.0) are where a
-- character without its own starts from (nothing is written to them any more).
function Restore:Own(key)
	_G.BushidoPrivateRestoreDB = _G.BushidoPrivateRestoreDB or {}
	local db = _G.BushidoPrivateRestoreDB
	db.fonts, db.layout = db.fonts or {}, db.layout or {}
	local E = Engine()
	key = key or (E and E.mynameRealm)
	local record = key and type(db.characters) == 'table' and db.characters[key]
	if not record then return { fonts = db.fonts, layout = db.layout } end
	if type(record.fonts) ~= 'table' then record.fonts = { display = db.fonts.display, small = db.fonts.small } end
	if type(record.layout) ~= 'table' then record.layout = { buffScale = db.layout.buffScale, unitHeight = db.layout.unitHeight, unitSpread = db.layout.unitSpread } end
	return { fonts = record.fonts, layout = record.layout }
end

function Restore:PickFont()
	local chosen = self:Own().fonts.display
	if chosen and FontValid(chosen) then return chosen end
	if FontValid(T.FONT) then return T.FONT end
	return T.FALLBACK_FONT
end

-- display font (big numbers, headings) + readable small-text font
function Restore:Fonts()
	local small = self:Own().fonts.small
	if not (small and FontValid(small)) then small = FontValid(T.SMALL_FONT) and T.SMALL_FONT or T.FALLBACK_FONT end
	return { display = self:PickFont(), small = small }
end

local function Theme()
	local art = _G.BanzaiCompat
	return art and art.GetTheme and art:GetTheme() or 'n/a (Banzai art not loaded)'
end

-- a setting of the Banzai art addon (BanzaiCompatDB), or the default
local function CompatSetting(key, default)
	local art = _G.BanzaiCompat
	local value = art and art.Get and art:Get(key)
	if value == nil then return default end
	return value
end

-- the Banzai tracker replaces Kaliel's Tracker on screen while it is on
local function CompatTracker()
	return _G.BanzaiCompat ~= nil and CompatSetting('tracker', true) ~= false
end

---------------------------------------------------------------------------
-- Saved state
---------------------------------------------------------------------------
local function DB()
	_G.BushidoPrivateRestoreDB = _G.BushidoPrivateRestoreDB or {}
	local db = _G.BushidoPrivateRestoreDB
	db.characters = db.characters or {}
	return db
end

local function Record(key)
	local db = DB()
	db.characters[key] = db.characters[key] or {}
	return db.characters[key]
end

---------------------------------------------------------------------------
-- Details: profile only
---------------------------------------------------------------------------
function Restore:ApplyDetails(record, font)
	local details = _G.Details
	if not (details and details.GetProfile and details.ApplyProfile and details.default_profile) then
		return 'skipped (Details not loaded)'
	end
	if record.previous.details == nil then
		record.previous.details = details:GetCurrentProfileName() or false
	end

	local profileData = ns.Payloads.detailsProfile
	if type(profileData) ~= 'table' then return 'failed (no Details profile data)' end
	local profile = details:GetProfile(T.PROFILE, true)
	if not profile then return 'failed (could not create the Details profile)' end

	local copy = _G.DetailsFramework and _G.DetailsFramework.table and _G.DetailsFramework.table.copy
	for key in pairs(details.default_profile) do
		local value = profileData[key]
		if value ~= nil then
			profile[key] = (type(value) == 'table') and (copy and copy({}, value) or T.DeepCopy(value)) or value
		end
	end
	if type(profileData.instances) == 'table' then
		profile.instances = copy and copy({}, profileData.instances) or T.DeepCopy(profileData.instances)
	end

	local media = LSM()
	local fontPath = media and media:Fetch('font', font, true)
	T.ReplaceDetailsFonts(profile, font, fontPath)
	T.SmoothDetailsRows(profile, CompatSetting('smoothBars', true)) -- 0.5.0: no slotted meter rows
	local style = T.DetailsStyle(CompatSetting('detailsStyle', 'CURRENT'))
	local face = self:CompactNameFace()
	T.StyleDetailsWindows(profile, CompatSetting('smoothBars', true), self:Fonts(), style, self:DetailsIconFile(), face) -- big titles in the display font, sleek rows, larger row text (1.3.0: or COMPACT; 1.3.1: its names in the Banzai display font)
	DB().detailsStyleApplied = style
	DB().detailsFaceApplied = face or false
	T.DetailsRowInk(profile, CompatSetting('panelBackground', 'GLASS') == 'PARCHMENT') -- 1.1.0 / 1.1.1: the row text for the panel background (off-white on parchment)
	for _, window in pairs(type(profile.instances) == 'table' and profile.instances or {}) do
		if type(window) == 'table' then
			if type(window.row_info) == 'table' then window.row_info.font_size = math.max(window.row_info.font_size or 0, T.DETAILS_TEXT_SIZE) end
			if type(window.attribute_text) == 'table' then window.attribute_text.text_size = math.max(window.attribute_text.text_size or 0, T.DETAILS_TEXT_SIZE) end
		end
	end

	-- Details' account option "always use this profile" switches every character
	-- back to that profile at login (Details loaddata.lua), which is why 0.1.0
	-- showed the old side-by-side windows. Its per-character exception list is
	-- the supported way out; the previous entry is recorded for /banzai restore.
	local note = ''
	local name = UnitName and UnitName('player')
	if details.always_use_profile and type(details.always_use_profile_exception) == 'table' and type(name) == 'string' then
		if record.previous.detailsException == nil then
			record.previous.detailsException = details.always_use_profile_exception[name] or false
		end
		details.always_use_profile_exception[name] = true
		note = ' (character exempt from "always use profile ' .. tostring(details.always_use_profile_name) .. '")'
	end

	-- when the Bushido profile is already active, do not let Details save the
	-- current windows over the layout that was just copied in
	local current = details.GetCurrentProfileName and details:GetCurrentProfileName()
	details:ApplyProfile(T.PROFILE, current == T.PROFILE)
	return 'applied' .. note
end

-- DAMAGE | HEALING side by side in the lower right, through Details' own
-- window API (ungroup, size, LibWindow anchor, display), saved by Details.
-- 1.3.6 geometryOnly: only the windows' size and place (the centre gutter) -
-- no window opened, no display or segment changed; after combat if it is on.
function Restore:LayoutDetails(geometryOnly)
	local details = _G.Details
	if not (details and details.GetInstance) then return 'skipped (Details not loaded)' end
	if InCombatLockdown() then
		if geometryOnly then self.detailsGeometryPending = true end
		return 'waiting (combat)'
	end
	local left, right = details:GetInstance(1), details:GetInstance(2)
	if not (left and right) then return 'skipped (Details needs two windows)' end
	if not geometryOnly then
		for _, window in ipairs({ left, right }) do
			if window.IsEnabled and not window:IsEnabled() and window.EnableInstance then pcall(window.EnableInstance, window) end
		end
	end
	if not (left.baseframe and right.baseframe) then return 'skipped (Details windows not built yet)' end
	local L = (_G.BanzaiCompat and _G.BanzaiCompat.DETAILS) or T.DETAILS_LAYOUT
	-- the frame around the windows sits on the bottom panel, whatever its height
	local bottom = L.bottom + (CompatSetting('barHeight', T.BAR_HEIGHT) - T.BAR_HEIGHT)
	local function place(window, x)
		if window.UngroupInstance then pcall(window.UngroupInstance, window) end
		local scale = window.window_scale or 1
		window.posicao = window.posicao or {}
		window.posicao.normal = window.posicao.normal or {}
		window.posicao.normal.w = L.width / scale
		window.posicao.normal.h = L.height / scale
		window.libwindow = window.libwindow or {}
		window.libwindow.point, window.libwindow.x, window.libwindow.y, window.libwindow.scale = 'BOTTOMRIGHT', x, bottom, scale
		if window.RestoreMainWindowPosition then window:RestoreMainWindowPosition() end
		if window.SaveMainWindowPosition then window:SaveMainWindowPosition() end
		if window.ReajustaGump then pcall(window.ReajustaGump, window) end
	end
	place(right, L.right)
	place(left, L.right - L.width - L.gap)
	if not geometryOnly then
		local segment = left.GetSegment and left:GetSegment()
		if left.SetDisplay then pcall(left.SetDisplay, left, segment, 1, 1) end -- damage done
		segment = right.GetSegment and right:GetSegment()
		if right.SetDisplay then pcall(right.SetDisplay, right, segment, 2, 1) end -- healing done
	end
	if _G.BanzaiCompat and _G.BanzaiCompat.PlaceDetails then
		_G.BanzaiCompat:PlaceDetails(_G.BanzaiCompat.Active and _G.BanzaiCompat.Active())
	end
	return 'side by side (damage | healing)'
end

-- Details settles its windows during the first seconds after login; lay out
-- again once it has, so the Banzai composition is what stays.
function Restore:LayoutDetailsSoon(geometryOnly)
	local result = self:LayoutDetails(geometryOnly)
	if C_Timer and C_Timer.After then
		C_Timer.After(5, function() Restore:LayoutDetails(geometryOnly) end)
	end
	return result
end

---------------------------------------------------------------------------
-- Top-right column: Kaliel's Tracker and the minimap button collector
---------------------------------------------------------------------------
-- Kaliel's Tracker keeps its position in its own profile (anchorPoint,
-- xOffset, yOffset, maxHeight; the values its mover writes). It is moved down
-- below the minimap only when it would overlap it; its lowest edge does not
-- move further down and stays above the Bushido Details frame.
function Restore:PlaceTracker(record, key)
	local db = _G.KalielsTrackerDB
	if type(db) ~= 'table' or type(db.profiles) ~= 'table' then return 'not installed' end
	local name = (type(db.profileKeys) == 'table' and db.profileKeys[key]) or 'Default'
	local profile = db.profiles[name]
	if type(profile) ~= 'table' then return 'no profile for this character' end
	if (profile.anchorPoint or 'TOPRIGHT') ~= 'TOPRIGHT' then return 'unchanged (not anchored top-right)' end

	local scale = tonumber(profile.frameScale) or 1
	local right = -(tonumber(profile.xOffset) or -115)
	local top = -(tonumber(profile.yOffset) or -340)
	if right > CLEAR_RIGHT then return 'unchanged (clear of the minimap)' end
	if top >= TRACKER_TOP then return 'unchanged (already below the minimap)' end

	if record.previous.tracker == nil then
		record.previous.tracker = { profile = name, yOffset = profile.yOffset or false, maxHeight = profile.maxHeight or false }
	end
	local screen = (GetScreenHeight and GetScreenHeight()) or 1081.69
	local bottom = math.min(top + (tonumber(profile.maxHeight) or 600) * scale, screen - DETAILS_TOP)
	profile.yOffset = -TRACKER_TOP
	profile.maxHeight = math.max(MIN_TRACKER_HEIGHT, math.floor((bottom - TRACKER_TOP) / scale))
	return format('moved below the minimap (%d from the top, max height %d)', TRACKER_TOP, profile.maxHeight)
end

-- MinimapButtonButton keeps its button position as { point, nil, relativePoint, x, y }
-- in button scale (its own saved setting). 0.4.0: the extreme top-right corner,
-- above the minimap frame and clear of the zone name. Changed in place.
function Restore:PlaceMinimapButton(record)
	local options = _G.MinimapButtonButtonOptions
	local position = type(options) == 'table' and options.position
	if type(position) ~= 'table' then return 'not installed' end
	if position[1] ~= 'TOPRIGHT' or position[3] ~= 'TOPRIGHT' then return 'unchanged (not anchored top-right)' end
	local scale = (tonumber(options.scale) or 10) / 10
	record.previous.minimapButton = record.previous.minimapButton or {}
	local saved = record.previous.minimapButton
	if saved.y == nil then saved.y = position[5] end
	if saved.x == nil then saved.x = position[4] end
	position[4], position[5] = -MINIMAP_BUTTON_CORNER / scale, -MINIMAP_BUTTON_CORNER / scale
	return 'in the top-right corner'
end

function Restore:PlaceTopRight(record, key)
	local tracker = self:PlaceTracker(record, key)
	if CompatTracker() then tracker = tracker .. ', ' .. self:SetKalielHidden(record, key, true) end
	return tracker, self:PlaceMinimapButton(record)
end

-- Kaliel's Tracker while the Banzai tracker is on: Kaliel's own per-context
-- visibility setting set to "hide" (it stays loaded and keeps Blizzard's tracker
-- away, but shows nothing). Previous values are recorded; nothing of Kaliel's
-- files is touched.
function Restore:SetKalielHidden(record, key, hidden)
	local db = _G.KalielsTrackerDB
	if type(db) ~= 'table' or type(db.profiles) ~= 'table' then return 'not installed' end
	local name = (type(db.profileKeys) == 'table' and db.profileKeys[key]) or 'Default'
	local profile = db.profiles[name]
	if type(profile) ~= 'table' then return 'no profile for this character' end
	if hidden then
		if record.previous.trackerVisibility == nil then
			local saved = { profile = name, values = {} }
			for _, ctx in ipairs(KALIEL_CONTEXTS) do saved.values[ctx] = profile['visibility' .. ctx] or false end
			record.previous.trackerVisibility = saved
		end
		for _, ctx in ipairs(KALIEL_CONTEXTS) do profile['visibility' .. ctx] = 'hide' end
		return 'hidden (Banzai tracker on)'
	end
	local saved = record.previous.trackerVisibility
	if saved and type(db.profiles[saved.profile]) == 'table' then
		for ctx, value in pairs(saved.values) do db.profiles[saved.profile]['visibility' .. ctx] = value or nil end
	end
	record.previous.trackerVisibility = nil
	return 'shown again'
end

-- 1.0.2: one objective tracker on screen. While the Banzai tracker shows (this
-- character on the Banzai profile, Banzai Art loaded, its tracker on - the
-- rule Banzai Art's tracker follows), Blizzard's objective tracker is parked
-- under a frame that is never shown, the way ElvUI parks it for its own
-- auto-hide: it is not hidden, hooked or unregistered and keeps working
-- unseen. Only out of combat (a change in combat waits for its end), and only
-- when it is not already where it belongs. With the Banzai tracker off or the
-- character off Banzai it goes back to its parent (Kaliel's Tracker, when
-- loaded, keeps it away by itself as before). Its state before Banzai is part
-- of the pre-Banzai record (previous.blizzardTracker), put back by every restore.
local PARKED = CreateFrame('Frame')
PARKED:Hide()
Restore.TRACKER_PARK = PARKED

local function BlizzardTracker()
	local f = _G.ObjectiveTrackerFrame
	return (type(f) == 'table' and f.GetParent and f.SetParent) and f or nil
end

-- Blizzard's tracker as the game has it (nil before it exists or while Banzai has it parked)
function Restore:BlizzardTrackerState()
	local f = BlizzardTracker()
	if not f or f:GetParent() == PARKED then return nil end
	local parent = f:GetParent()
	return {
		parent = parent and parent.GetName and parent:GetName() or nil,
		shown = f.IsShown and f:IsShown() and true or false,
		collapsed = f.IsCollapsed and f:IsCollapsed() and true or false,
	}
end

function Restore:BanzaiTrackerShown()
	local E = Engine()
	return (CompatTracker() and E and E.data and E.data.GetCurrentProfile and E.data:GetCurrentProfile() == T.PROFILE) and true or false
end

-- parks or puts back Blizzard's tracker to match; 'parked' | 'released' | 'kept' | 'pending' (combat) | 'n/a'
function Restore:TrackerOwnership(reason)
	local f = BlizzardTracker()
	if not f then return 'n/a' end
	self:WatchTracker() -- 1.3.1
	local want = self:BanzaiTrackerShown()
	if want == (f:GetParent() == PARKED) then
		self.trackerPending = nil
		return 'kept'
	end
	if InCombatLockdown() then
		self.trackerPending = true
		return 'pending'
	end
	self.trackerPending = nil
	local E = Engine()
	local record = E and E.mynameRealm and DB().characters[E.mynameRealm]
	local saved = record and record.previous and record.previous.blizzardTracker
	self.trackerReason = reason
	if want then
		-- a character on Banzai from before 1.0.2: its state now is its state from before Banzai (Banzai never moved it)
		if record and record.previous and saved == nil then record.previous.blizzardTracker = self:BlizzardTrackerState() end
		self.trackerParent = self.trackerParent or f:GetParent() -- 1.3.1: the parent it had before the first park (a re-park keeps it)
		f:SetParent(PARKED)
		return 'parked'
	end
	f:SetParent((saved and saved.parent and _G[saved.parent]) or self.trackerParent or UIParent)
	self.trackerParent = nil
	return 'released'
end

-- 1.3.1: the parking holds whatever brings the tracker back. Darren's 1.3.0 screenshots still showed
-- Blizzard's tracker beside the Banzai one until a reload: other code puts it back under a shown parent
-- at moments none of the events below covers - ElvUI's objective auto-hider moves it to its hidden
-- frame while boss / arena units exist and back to UIParent when they go (BL:ObjectiveTracker_AutoHide:
-- a secure state driver, no event of its own), Eltruism re-anchors it (BreakFromFrameManager: SetParent
-- UIParent) and, with its quest options, after combat, encounters and indoor / outdoor zone changes
-- (QuestCombat, ArenaQuest), Edit Mode re-parents it whenever it lays its systems out. So Banzai asks
-- the tracker itself: a tiny empty frame of Banzai's own inside it (the sentinel) is visible only while
-- the tracker is - its own OnShow fires the moment anything puts the tracker back on screen, and queues
-- the same one-frame ownership check while the Banzai tracker shows. One queued check at a time, out of
-- combat (a change in combat waits for its end, once). No hook, no polling, no OnUpdate; the tracker is
-- never hidden, its functions and scripts never hooked, its events never unregistered.
function Restore:WatchTracker()
	local f = BlizzardTracker()
	if self.trackerSentinel or not f then return self.trackerSentinel ~= nil end
	local sentinel = CreateFrame('Frame', nil, f)
	sentinel:SetSize(1, 1)
	sentinel:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, 0)
	sentinel:EnableMouse(false)
	sentinel:SetScript('OnShow', function()
		if Restore:BanzaiTrackerShown() then Restore:QueueTrackerOwnership('shown again') end
	end)
	self.trackerSentinel = sentinel
	return true
end

-- 1.0.3: the same check one frame later, after every other handler of the
-- event that asked for it has run (Edit Mode re-anchors the tracker when it
-- applies a layout; Eltruism re-anchors it at every loading screen, both in
-- handlers that run after Banzai's). One check queued at a time; a change in
-- combat waits for its end as before. No hook, no polling: nothing runs
-- unless one of the events below fires.
function Restore:QueueTrackerOwnership(reason)
	if self.trackerQueued then return 'queued' end
	if not (C_Timer and C_Timer.After) then return self:TrackerOwnership(reason) end
	self.trackerQueued = reason or true
	C_Timer.After(0, function()
		Restore.trackerQueued = nil
		Restore:TrackerOwnership(reason)
	end)
	return 'queued'
end

-- RESTORE PRE-BANZAI: Blizzard's tracker exactly as recorded before Banzai (its parent and collapsed state)
function Restore:PutBackBlizzardTracker(saved)
	local result = self:TrackerOwnership('restore')
	local f = BlizzardTracker()
	if f and type(saved) == 'table' and f.IsCollapsed and f.SetCollapsed and (f:IsCollapsed() and true or false) ~= (saved.collapsed and true or false) then
		pcall(f.SetCollapsed, f, saved.collapsed and true or false)
	end
	return result
end

-- options for the character part of the layer (choices made on the BANZAI
-- page, kept per character since 0.6.0) and the role layout in use
-- 1.3.0 the BANZAI SPLIT settings the ElvUI side is written from (the HP / resource texts and the enhanced plate are Banzai Art's alone)
Restore.SPLIT_LAYER = { 'splitPlayerX', 'splitPlayerY', 'splitTargetX', 'splitTargetY', 'splitScale', 'splitHubScale', 'splitThickness' } -- 1.3.1: + the bar thickness

function Restore:LayerOptions()
	local layout = self:Own().layout
	local art = _G.BanzaiCompat
	local opts = {
		healthInside = CompatSetting('healthInside', true),
		healthPercent = CompatSetting('healthPercent', true),
		barHeight = CompatSetting('barHeight', T.BAR_HEIGHT),
		smoothBars = CompatSetting('smoothBars', true),
		cooldownBars = CompatSetting('cooldownBars', false),
		actionStyle = T.ButtonStyle(CompatSetting('actionStyle', 'SQUARE')),
		buffsPanel = self:BuffsPanel(), -- 1.2.0
		chatX = T.CHAT.x, -- 1.2.0: a new chat place is written at the next login like any other layer change
		totScale = CompatSetting('totScale', T.TOT.scale),
		identityCircles = CompatSetting('identityCircles', true),
		pvpCastColors = CompatSetting('pvpCastColors', true),
		pvpDispelGlow = CompatSetting('pvpDispelGlow', true),
		pvpDefensives = CompatSetting('pvpDefensives', true),
		roleIcons = CompatSetting('roleIcons', true),
		buffScale = layout.buffScale or T.AURAS.scale,
		-- 1.0.0
		frameWidth = T.FrameWidth(CompatSetting('frameWidth', T.FRAME_WIDTH)),
		unitHeight = layout.unitHeight or 0,
		unitSpread = layout.unitSpread or 0,
		afk = _G.BanzaiCompat ~= nil and CompatSetting('afk', true) ~= false, -- without Banzai Art: ElvUI's AFK screen
		tooltipTheme = CompatSetting('tooltipTheme', 'BANZAI'),
		actionLook = self:ActionLook(),
		role = ns.Roles and ns.Roles:Active() or 'DPS',
		roleContext = ns.Roles and ns.Roles:ActiveContext() or 'world',
		roles = art and art.Roles and T.DeepCopy(art:Roles()) or nil,
	}
	-- 1.3.0 the record of the split layer in the shared profile (never part of the signature)
	local db = DB()
	db.splitLayer = type(db.splitLayer) == 'table' and db.splitLayer or {}
	opts.splitState = db.splitLayer
	-- 1.3.0 BANZAI SPLIT: only when it is the chosen style (a BANZAI CLASSIC layer is exactly the 1.2.1 one)
	if T.FrameStyle(CompatSetting('frameStyle', 'CLASSIC')) == 'SPLIT' then
		opts.frameStyle = 'SPLIT'
		for _, k in ipairs(Restore.SPLIT_LAYER) do opts[k] = CompatSetting(k, T.SPLIT.defaults[k]) end
		opts.splitParty = CompatSetting('splitParty', true) ~= false
		opts.splitLayout = T.SPLIT.version -- 1.3.1: a new layout of the split leaves rewrites the layer once
		opts.splitCastBar = CompatSetting('splitCastBar', true) ~= false -- 1.3.3: the class bar goes above the cast bar while it is on
	end
	return opts
end

-- what a layer was written from (1.3.0: without the split record, which changes as it is written)
function Restore.Signature(opts, fonts)
	local plain = {}
	for k, v in pairs(opts) do if k ~= 'splitState' then plain[k] = v end end
	return T.Serialize({ plain, fonts })
end

-- Writes this character's part of the layer into the shared Banzai profile
-- when the profile was last written for another character or other settings.
-- Returns true when something ElvUI reads at load changed (a reload is due).
function Restore:CharacterLayer(key, force)
	local profile = _G.ElvDB and _G.ElvDB.profiles and _G.ElvDB.profiles[T.PROFILE]
	local P = ns.Payloads
	if not (type(profile) == 'table' and P and type(P.elvuiProfile) == 'table') then return false end
	local fonts = self:Fonts()
	local opts = self:LayerOptions()
	local signature = Restore.Signature(opts, fonts)
	local db = DB()
	local owner = db.layerOwner
	if not force and owner and owner.key == key and owner.signature == signature then return false end
	T.ApplyCharacterLayer(profile, P.elvuiProfile, fonts, opts)
	local private = _G.ElvPrivateDB and _G.ElvPrivateDB.profiles and _G.ElvPrivateDB.profiles[T.PROFILE]
	if type(private) == 'table' and type(P.elvuiPrivate) == 'table' then T.ApplyBanzaiPrivate(private, P.elvuiPrivate, fonts) end
	if ns.Roles then ns.Roles:Written(opts.role, T.RoleWritten(T.RoleLayout(opts.role, P.elvuiProfile, opts.roles), opts.roleContext), opts.roleContext) end
	local changed = not (owner and owner.signature == signature)
	db.layerOwner = { key = key, signature = signature }
	return changed
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------
-- 1.0.1: the pre-Banzai record of a character, taken before anything changes:
-- what Backup & Restore / RESTORE PRE-BANZAI need to put back - its ElvUI and
-- private profile names and its Details profile with its "always use profile"
-- exception (Kaliel's Tracker and the minimap button collector are recorded
-- right before Banzai moves them). Nothing else is copied. An existing record
-- is kept (never overwritten later). Returns the record, or nil and why not.
function Restore:Snapshot(key)
	local E = Engine()
	if not (E and E.data and E.data.GetCurrentProfile and _G.ElvDB and _G.ElvPrivateDB and key) then return nil, 'ElvUI is not ready' end
	local record = Record(key)
	if record.previous then return record.previous end
	local ok, current = pcall(E.data.GetCurrentProfile, E.data)
	if not ok or type(current) ~= 'string' then return nil, 'the current ElvUI profile could not be read' end
	local previous = {
		elvProfile = (current ~= T.PROFILE) and current or nil,
		privateProfile = _G.ElvPrivateDB.profileKeys and _G.ElvPrivateDB.profileKeys[key],
		time = date('%Y-%m-%d %H:%M:%S'),
		blizzardTracker = self:BlizzardTrackerState(), -- 1.0.2: Blizzard's objective tracker (parent, shown, collapsed)
	}
	local details = _G.Details
	if details and details.GetCurrentProfileName then
		local okName, name = pcall(details.GetCurrentProfileName, details)
		previous.details = (okName and name) or false
		local who = UnitName and UnitName('player')
		if type(details.always_use_profile_exception) == 'table' and type(who) == 'string' then
			previous.detailsException = details.always_use_profile_exception[who] or false
		end
	end
	record.previous = previous
	return previous
end

-- HOME > Apply Banzai and /banzai apply: a character that does not run Banzai
-- yet goes through Character Sync (its snapshot, the master's settings, the
-- shared profile reused); a character already on Banzai re-applies in full.
function Restore:ApplyHere(reason)
	local E = Engine()
	local record = E and E.mynameRealm and DB().characters[E.mynameRealm]
	if ns.Sync and not (record and record.applied) then
		local ok, message = ns.Sync:Apply()
		if not ok and message then Print(message) end -- (a failed backup / missing component said here too)
		return ok, message
	end
	return self:Apply(reason)
end

-- options.reuse (Character Sync): when the Banzai profile already exists (the
-- master's approved setup), this character switches to it and only its own
-- part of the layer is written; nothing of the shared profile is rebuilt.
function Restore:Apply(reason, options)
	options = options or {}
	if InCombatLockdown() then
		Print('Cannot apply in combat. Try again after combat.')
		return false
	end
	local E = Engine()
	if not (E and E.data and _G.ElvDB and _G.ElvPrivateDB and E.mynameRealm) then
		Print('ElvUI is not ready.')
		return false
	end
	local P = ns.Payloads
	local key = E.mynameRealm
	local db = DB()
	local record = Record(key)
	local fonts = self:Fonts()
	local font = fonts.display

	-- 1. record what this character used before (never overwritten later)
	if not record.previous then
		local previous, problem = self:Snapshot(key)
		if not previous then
			Print('Pre-Banzai backup failed (' .. tostring(problem) .. ') - nothing was changed.')
			return false
		end
	end

	-- 2. the historical payloads (decoded locally at build time)
	if not (P and type(P.elvuiProfile) == 'table' and type(P.elvuiPrivate) == 'table' and type(P.elvuiGlobal) == 'table') then
		Print('Payloads.lua is missing or incomplete - nothing was changed.')
		return false
	end
	local profile, private, global = P.elvuiProfile, T.DeepCopy(P.elvuiPrivate), T.DeepCopy(P.elvuiGlobal)
	local reuse = options.reuse and type(_G.ElvDB.profiles[T.PROFILE]) == 'table'

	-- 3. ElvUI profile (Bushido values + Banzai layer; existing profiles untouched)
	local report
	if reuse then
		report = { fonts = 0, tags = 0, mediaTagMigrated = 'shared profile kept' }
		self:CharacterLayer(key, true)
	else
		local newProfile
		local opts = self:LayerOptions()
		opts.splitState = {} -- 1.3.0: a new profile, a new record of its split layer
		newProfile, report = T.TransformProfile(profile, font, FontValid, fonts.small, opts)
		_G.ElvDB.profiles[T.PROFILE] = newProfile
		db.splitLayer = opts.splitState
		db.layerOwner = { key = key, signature = Restore.Signature(opts, fonts) }
	end

	-- 4. ElvUI private profile for this character
	if not (reuse and type(_G.ElvPrivateDB.profiles[T.PROFILE]) == 'table') then
		local previousPrivate = record.previous.privateProfile
		local basePrivate = previousPrivate and _G.ElvPrivateDB.profiles[previousPrivate]
		_G.ElvPrivateDB.profiles[T.PROFILE] = T.TransformPrivate(private, basePrivate, font, FontValid, fonts.small)
	end
	_G.ElvPrivateDB.profileKeys = _G.ElvPrivateDB.profileKeys or {}
	_G.ElvPrivateDB.profileKeys[key] = T.PROFILE

	-- 5. ElvUI global values (account-wide): snapshot once, then write
	T.ReplaceFonts(global, font, FontValid)
	_G.ElvDB.global = _G.ElvDB.global or {}
	local leaves = T.Leaves(global)
	leaves[#leaves + 1] = { path = { 'general', 'UIScale' }, value = P.uiScale }
	if not db.globalSnapshot then
		db.globalSnapshot = T.Snapshot(_G.ElvDB.global, leaves)
	end
	T.ApplyLeaves(_G.ElvDB.global, leaves)

	-- 6. Details window profile and side-by-side layout, then the top-right column
	local detailsResult = self:ApplyDetails(record, fonts.small)
	local layoutResult = self:LayoutDetailsSoon()
	local trackerResult, buttonResult = self:PlaceTopRight(record, key)

	-- 7. switch this character's ElvUI profile
	if E.data:GetCurrentProfile() == T.PROFILE and E.data.keys then
		E.data.keys.profile = T.PROFILE .. '_Temp' -- force a full refresh when re-applying
	end
	E.data:SetProfile(T.PROFILE)

	record.layer = T.LAYER
	record.applied = { version = VERSION, source = P.source, time = date('%Y-%m-%d %H:%M:%S'), font = font, reason = reason or 'manual' }
	Print(format('%s %s applied (%s). Font %s, %d font settings and %d tags updated, mMediaTag migrated: %s.',
		NAME, VERSION, record.applied.reason, font, report.fonts, report.tags, tostring(report.mediaTagMigrated)))
	Print('Details: ' .. detailsResult .. ', ' .. layoutResult .. '. Kaliel\'s Tracker: ' .. trackerResult .. '. Minimap buttons: ' .. buttonResult .. '.')
	Print('Previous ElvUI profile: ' .. tostring(record.previous.elvProfile) .. ', previous private profile: ' .. tostring(record.previous.privateProfile) .. '. Backup & Restore in the BANZAI options puts them back.')
	self:TrackerOwnership('apply') -- 1.0.2: Blizzard's objective tracker parked while the Banzai tracker shows
	StaticPopup_Show('BANZAI_RELOAD')
	return true
end

---------------------------------------------------------------------------
-- Upgrade a character that applied an older build (0.1.0): targeted keys only
---------------------------------------------------------------------------
local function NeedsLayer(record)
	return record and record.applied and record.previous and (record.layer or 0) < T.LAYER
end

-- Settings part. Run while the addons load (our ADDON_LOADED: after ElvUI,
-- Kaliel's Tracker and MinimapButtonButton have read their saved variables,
-- before any of them builds its frames at PLAYER_LOGIN), so the new positions
-- are used on this very login and no reload is needed.
function Restore:UpgradeSettings(record, key)
	local profile = _G.ElvDB and _G.ElvDB.profiles and _G.ElvDB.profiles[T.PROFILE]
	local P = ns.Payloads
	if not (type(profile) == 'table' and P and type(P.elvuiProfile) == 'table') then return false end
	local fonts = self:Fonts()
	-- group frames moved by hand under an older build stay where they are (as this character's DPS positions)
	if ns.Roles and (record.layer or 0) < 8 then ns.Roles:Seed(profile) end
	T.RevertFrameStyle(profile, DB().splitLayer) -- 1.3.0: the classic values first (the text choices are read from them)
	-- 1.0.0: choices kept only in the profile (spec in the names, health number size) survive the rewrite
	local choices = T.TextChoices(profile)
	T.ApplyBanzaiProfile(profile, P.elvuiProfile, fonts, self:LayerOptions())
	T.RestoreTextChoices(profile, choices)
	self:CharacterLayer(key, true) -- records whose settings the profile now carries
	local tracker, button = self:PlaceTopRight(record, key)
	record.layerSettings = { layer = T.LAYER, tracker = tracker, button = button }
	return true
end

local function UsesBanzaiProfile(key)
	local keys = _G.ElvDB and _G.ElvDB.profileKeys
	return type(keys) == 'table' and keys[key] == T.PROFILE
end

function Restore:OnAddonLoaded()
	local E = Engine()
	local key = E and E.mynameRealm
	local record = key and DB().characters[key]
	if NeedsLayer(record) then
		self:UpgradeSettings(record, key)
	elseif record and record.applied and UsesBanzaiProfile(key) then
		self:CharacterLayer(key) -- this character's settings and role layout, before ElvUI builds
	end
end

-- Completes the upgrade once the UI is running (Details can switch profiles live).
function Restore:Upgrade()
	if InCombatLockdown() then return false end
	local E = Engine()
	if not (E and E.mynameRealm) then return false end
	local key = E.mynameRealm
	local record = Record(key)
	if not NeedsLayer(record) then return false end

	local settings = record.layerSettings
	local early = type(settings) == 'table' and settings.layer == T.LAYER
	if not early then
		if not self:UpgradeSettings(record, key) then return false end
		settings = record.layerSettings
	end
	local detailsResult = self:ApplyDetails(record, self:Fonts().small)
	local layoutResult = self:LayoutDetailsSoon()

	record.layer = T.LAYER
	record.layerSettings = nil
	record.applied.version = VERSION
	record.applied.upgraded = date('%Y-%m-%d %H:%M:%S')
	Print(format('updated to %s %s: half-width Player / Target / Focus / Target-of-Target, the HEALER row just above them, the BANZAI settings app (click the BANZAI wordmark), the Banzai AFK screen, the tooltip theme and tooltips on the bottom panel and the objectives.', NAME, VERSION))
	Print('Details: ' .. detailsResult .. ', ' .. layoutResult .. '. Kaliel\'s Tracker: ' .. tostring(settings.tracker) .. '. Minimap buttons: ' .. tostring(settings.button) .. '.')
	if not early then StaticPopup_Show('BANZAI_RELOAD') end -- settings written too late for this session
	return true
end

---------------------------------------------------------------------------
-- Restore
---------------------------------------------------------------------------
function Restore:Revert()
	if InCombatLockdown() then
		Print('Cannot restore in combat.')
		return false
	end
	local E = Engine()
	if not (E and E.data) then return false end
	local key = E.mynameRealm
	local db = DB()
	local record = db.characters[key]
	if not (record and record.previous) then
		Print('Nothing recorded for this character.')
		return false
	end

	local previous = record.previous
	-- (none recorded: the character used ElvUI's own per-character private profile)
	if _G.ElvPrivateDB and _G.ElvPrivateDB.profileKeys and _G.ElvPrivateDB.profileKeys[key] == T.PROFILE then
		_G.ElvPrivateDB.profileKeys[key] = previous.privateProfile or nil
	end

	local details = _G.Details
	if details then
		local name = UnitName and UnitName('player')
		if previous.detailsException ~= nil and type(details.always_use_profile_exception) == 'table' and type(name) == 'string' then
			details.always_use_profile_exception[name] = previous.detailsException or nil
		end
		if details.ApplyProfile and previous.details then
			details:ApplyProfile(previous.details)
		end
	end

	local tracker = previous.tracker
	local trackerDB = _G.KalielsTrackerDB
	if tracker and type(trackerDB) == 'table' and type(trackerDB.profiles) == 'table' and type(trackerDB.profiles[tracker.profile]) == 'table' then
		local profile = trackerDB.profiles[tracker.profile]
		profile.yOffset = tracker.yOffset or nil
		profile.maxHeight = tracker.maxHeight or nil
	end
	if previous.trackerVisibility then self:SetKalielHidden(record, key, false) end
	local button = previous.minimapButton
	local options = _G.MinimapButtonButtonOptions
	if button and type(options) == 'table' and type(options.position) == 'table' then
		if button.x ~= nil then options.position[4] = button.x end
		if button.y ~= nil then options.position[5] = button.y end
	end

	-- account-wide values go back only when no other character still uses the Bushido profile
	local others = 0
	for otherKey, otherRecord in pairs(db.characters) do
		if otherKey ~= key and otherRecord.applied then others = others + 1 end
	end
	if others == 0 and db.globalSnapshot and _G.ElvDB and _G.ElvDB.global then
		T.RevertSnapshot(_G.ElvDB.global, db.globalSnapshot)
		db.globalSnapshot = nil
	end

	record.arenaSystem = nil -- (a 0.9.0 arena-system choice: nothing to put back, sArena is no longer Banzai's business)

	if previous.elvProfile then
		E.data:SetProfile(previous.elvProfile)
	end
	record.applied = nil
	record.layer = nil
	record.layerSettings = nil
	if ns.Roles and ns.Roles.Forget then ns.Roles:Forget() end
	if ns.Sync and ns.Sync.Forget then ns.Sync:Forget(key) end -- 1.0.1: no longer synced (nor the master), whichever restore ran
	self:PutBackBlizzardTracker(previous.blizzardTracker) -- 1.0.2: off Banzai now - Blizzard's tracker back as recorded
	record.restored = date('%Y-%m-%d %H:%M:%S')
	record.previous = nil
	Print('Restored. The Bushido / Banzai profiles stay available but are no longer active on this character.')
	StaticPopup_Show('BANZAI_RELOAD')
	return true
end

---------------------------------------------------------------------------
-- Optional: Blizzard Edit Mode layout (not activated)
---------------------------------------------------------------------------
function Restore:ImportEditMode()
	if InCombatLockdown() then Print('Not in combat.') return end
	if not (C_EditMode and C_EditMode.GetLayouts and C_EditMode.ConvertStringToLayoutInfo and C_EditMode.SaveLayouts) then
		Print('Edit Mode API not available.')
		return
	end
	local ok, info = pcall(C_EditMode.ConvertStringToLayoutInfo, ns.Payloads.editMode)
	if not ok or type(info) ~= 'table' then
		Print('This client could not read the historical Edit Mode layout; skipped.')
		return
	end
	local layouts = C_EditMode.GetLayouts()
	local name = 'JiberishUI Bushido Private'
	for i = #layouts.layouts, 1, -1 do
		if layouts.layouts[i].layoutName == name then table.remove(layouts.layouts, i) end
	end
	info.layoutName = name
	info.layoutType = Enum.EditModeLayoutType.Account
	table.insert(layouts.layouts, info)
	local saved = pcall(C_EditMode.SaveLayouts, layouts)
	Print(saved and ('Edit Mode layout "' .. name .. '" added (not activated). Select it in Edit Mode if you want it.') or 'Saving the Edit Mode layout failed; nothing changed.')
end

---------------------------------------------------------------------------
-- Status
---------------------------------------------------------------------------
function Restore:Status()
	local E = Engine()
	local media = LSM()
	local key = E and E.mynameRealm or '?'
	local record = DB().characters[key]
	Print(NAME .. ' ' .. VERSION .. ' (release; profile source ' .. string.sub(tostring(ns.Payloads and ns.Payloads.source), 1, 8) .. ')')
	Print('ElvUI profile: ' .. tostring(E and E.data and E.data:GetCurrentProfile()) .. ', applied: ' .. tostring(record and record.applied and record.applied.time or 'no')
		.. ', Banzai layer: ' .. tostring(record and record.layer or 'no'))
	Print('frame theme: ' .. Theme())
	local art0 = _G.BanzaiCompat
	if art0 and art0.PanelStyle then
		local border, background, scale = art0:PanelStyle()
		Print(format('panel style (chat / Details / minimap / buffs): %s bamboo border, %s background, border scale %d%%', tostring(border), tostring(background), math.floor((scale or 1) * 100 + 0.5)))
	end
	local buffs = self:BuffsPanel()
	Print(format('buffs panel: %s, %d rows of %d, buffs at %d, %d (top-left); chat flush with the left screen edge', buffs.on and 'on' or 'off', buffs.rows, T.BUFFS_PANEL.perRow, buffs.x, buffs.y))
	local art = _G.BanzaiCompat
	if art and art.lastError then Print('Banzai art error (first seen): ' .. tostring(art.lastError)) end
	Print('health bars: ' .. (CompatSetting('smoothBars', true) and 'smooth' or 'Bushido') .. ', action buttons: ' .. T.ButtonStyle(CompatSetting('actionStyle', 'SQUARE'))
		.. ', target cooldown bars (ElvUI 2 + 4): ' .. (CompatSetting('cooldownBars', false) and 'shown' or 'off'))
	Print('Banzai tracker: ' .. (CompatTracker() and 'on' or 'off') .. ', Kaliel\'s Tracker: '
		.. ((record and record.previous and record.previous.trackerVisibility) and 'hidden while it is on' or 'as configured in Kaliel\'s Tracker')
		.. ', Blizzard\'s tracker: ' .. (BlizzardTracker() and (BlizzardTracker():GetParent() == PARKED and 'parked while the Banzai tracker shows' or 'shown by the game') or 'not loaded'))
	local roles = ns.Roles
	local spec = roles and roles.Spec and roles.Spec()
	Print('spec role: ' .. tostring(spec and spec.layout or '-') .. ' (' .. tostring(spec and spec.name or '-') .. '), frame layout in use: ' .. tostring(roles and roles:Active() or '-')
		.. ' (' .. tostring(roles and roles:ActiveContext() or '-') .. '), identity circles: ' .. (CompatSetting('identityCircles', true) and 'on' or 'off'))
	Print('pvp: ' .. self:PvPText())
	local art1 = _G.BanzaiCompat
	local session = art1 and art1.Split and art1.Split.Session and art1.Split:Session()
	Print(format('frame style: BANZAI %s (this session: BANZAI %s), Details meter style: BANZAI %s', T.FrameStyle(CompatSetting('frameStyle', 'CLASSIC')),
		session and 'SPLIT' or 'CLASSIC', T.DetailsStyle(CompatSetting('detailsStyle', 'CURRENT'))))
	-- Display face and its actual per-selection presentation scale
	local fontInfo
	if art1 and art1.Theme and art1.Theme.DisplayFontInfo then fontInfo = art1.Theme:DisplayFontInfo() end
	local face = fontInfo and fontInfo.name or 'Information Font'
	local theme = art1 and art1.Theme
	local choice = theme and theme:DB().displayFace
	local isDefault = choice == 'BANZAI_DEFAULT' or (choice == 'AUTO' and fontInfo and fontInfo.id == 'SHOJUMARU')
	local scale = (tonumber(CompatSetting('displayScale', 1)) or 1) * (isDefault and theme.BANZAI_DEFAULT_SCALE or 1)
	local registered = fontInfo and fontInfo.metadata and fontInfo.metadata.file and media and media:IsValid('font', 'BANZAI ' .. face)
	Print(format('Display font: %s at %d%%, license: %s, registered: %s; small font: %s', face, math.floor(scale * 100 + 0.5),
		tostring(fontInfo and fontInfo.license or 'Information Font provider'), registered and 'yes' or (fontInfo and fontInfo.metadata and fontInfo.metadata.information and 'profile-selected' or 'no'),
		tostring(self:Fonts().small)))
	local split = art1 and art1.Split
	if split and split.lastError then Print('BANZAI SPLIT paint error (last seen): ' .. tostring(split.lastError)) end
	-- 1.3.2
	local manifest = art1 and art1.IdentityArtCount and art1:IdentityArtCount() or 0
	Print(format('identity art: %s, BANZAI class art for %d of 13 classes (Fabled where it is missing or too small)', tostring(CompatSetting('identityArt', 'AUTO')), manifest))
	-- 1.3.3
	Print(format('split cast bar (Player / Target): %s, spell name: %s, timer: %s; the hubs 125 %%, the spell icon alone in them while a cast shows',
		CompatSetting('splitCastBar', true) ~= false and 'on' or 'off', CompatSetting('splitCastName', true) ~= false and 'on' or 'off', CompatSetting('splitCastTimer', true) ~= false and 'on' or 'off'))
	Print(format('unit frames: Player / Target / Focus / Target-of-Target %d%% of Bushido\'s width, AFK screen: %s, tooltip theme: %s, bottom-panel tooltips: %s',
		math.floor(T.FrameWidth(CompatSetting('frameWidth', T.FRAME_WIDTH)) * 100 + 0.5), CompatSetting('afk', true) and 'Banzai' or 'ElvUI',
		tostring(CompatSetting('tooltipTheme', 'BANZAI')), CompatSetting('panelTips', true) and 'on' or 'off'))
	local sync = ns.Sync
	if sync and sync.StatusText then Print('character sync: ' .. sync:StatusText()) end
	if record and record.previous then
		Print('previous ElvUI profile: ' .. tostring(record.previous.elvProfile) .. ', previous private: ' .. tostring(record.previous.privateProfile) .. ', previous Details: ' .. tostring(record.previous.details))
	end
	if media then
		local missing = {}
		for _, name in ipairs(STATUSBARS) do
			if not media:IsValid('statusbar', name) then missing[#missing + 1] = name end
		end
		Print('Bushido status-bar textures: ' .. (#missing == 0 and 'all present' or ('MISSING ' .. table.concat(missing, ', '))))
		Print('font ' .. T.FONT .. ': ' .. (media:IsValid('font', T.FONT) and 'present' or 'missing (JiberishMedia not loaded?)'))
	end
end

-- Options page: font choices. Writes the chosen fonts into the Banzai profile
-- (display font on big numbers / headings, small font everywhere else) and
-- the Details meter; ElvUI applies fonts fully after a reload.
function Restore:ApplyFonts(display, small)
	local own = self:Own().fonts -- 1.0.1: this character's
	if display and FontValid(display) then own.display = display end
	if small and FontValid(small) then own.small = small end
	local fonts = self:Fonts()
	local P = ns.Payloads
	local profile = _G.ElvDB and _G.ElvDB.profiles and _G.ElvDB.profiles[T.PROFILE]
	if type(profile) == 'table' and P then
		T.ApplyBanzaiFonts(profile, P.elvuiProfile, fonts)
		local private = _G.ElvPrivateDB and _G.ElvPrivateDB.profiles and _G.ElvPrivateDB.profiles[T.PROFILE]
		if type(private) == 'table' then T.ApplyBanzaiPrivate(private, P.elvuiPrivate, fonts) end
	end
	local E = Engine()
	local record = E and E.mynameRealm and DB().characters[E.mynameRealm]
	local details = _G.Details
	if record and record.previous and details and details.GetCurrentProfileName and details:GetCurrentProfileName() == T.PROFILE then
		self:ApplyDetails(record, fonts.small)
		self:LayoutDetails()
	end
	StaticPopup_Show('BANZAI_RELOAD')
	return fonts
end

-- /banzai and the BANZAI wordmark: the BANZAI settings on a page (Options.lua)
function Restore:OpenOptions(page)
	if ns.Options and ns.Options.Open then return ns.Options.Open(page or 'home') end
	return false
end

function Restore:SetTheme(mode)
	local art = _G.BanzaiCompat
	if not (art and art.SetTheme) then
		Print('The Banzai art addon (BushidoPrivateCompat) is not loaded.')
		return false
	end
	if art:SetTheme(mode) then
		Print('frame theme: ' .. art:GetTheme())
		return true
	end
	Print('themes: vibrant (default) | class')
	return false
end

---------------------------------------------------------------------------
-- Options page: 0.4.0 layer choices (Banzai profile keys; ElvUI reads movers
-- and aura sizes at load, so those finish with a reload)
---------------------------------------------------------------------------
local function BanzaiProfile()
	local profile = _G.ElvDB and _G.ElvDB.profiles and _G.ElvDB.profiles[T.PROFILE]
	return type(profile) == 'table' and profile or nil
end

local function CurrentRecord()
	local E = Engine()
	local key = E and E.mynameRealm
	local record = key and DB().characters[key]
	return record, key
end

local function CompatSet(key, value)
	local art = _G.BanzaiCompat
	if art and art.Set then art:Set(key, value) end
end

function Restore:SetTracker(enabled)
	enabled = enabled and true or false
	CompatSet('tracker', enabled)
	local record, key = CurrentRecord()
	local result = 'n/a (Banzai not applied)'
	if record and record.previous then result = self:SetKalielHidden(record, key, enabled) end
	self:TrackerOwnership('tracker option') -- 1.0.2: Blizzard's tracker back while the Banzai tracker is off (parked again when it is on)
	StaticPopup_Show('BANZAI_RELOAD') -- Kaliel's Tracker reads its visibility at load
	return result
end

function Restore:SetHealthInside(enabled)
	enabled = enabled and true or false
	CompatSet('healthInside', enabled)
	self:ClassicEdit(function() -- 1.3.0: over the classic values, the split layer again after it
		local profile, P = BanzaiProfile(), ns.Payloads
		if profile then T.SetHealthInside(profile, enabled, CompatSetting('healthPercent', true), P and P.elvuiProfile) end
		-- 1.0.0: health under the narrow Target moves the Target-of-Target lower
		if profile and P then local opts = self:LayerOptions() T.ApplyToT(profile, opts.totScale, P.elvuiProfile, opts.frameWidth, opts) end
	end)
	local E = Engine()
	local UF = E and E.GetModule and E:GetModule('UnitFrames', true)
	if UF and UF.Update_AllFrames and not InCombatLockdown() then pcall(UF.Update_AllFrames, UF) end
end

local function Clamp(value, low, high, default)
	value = tonumber(value) or default
	return math.max(low, math.min(high, value))
end

-- the PvP choices in words (1.0.1: Banzai's mirrored arena enemy frames are the only arena enemy system)
function Restore:PvPText()
	local on = function(key) return CompatSetting(key, true) and 'on' or 'off' end
	return 'arena enemies: Banzai mirrored frames, cast colours ' .. on('pvpCastColors') .. ', role icons ' .. on('roleIcons') .. ', trinket circles ' .. on('trinketCircles')
		.. ', CC ' .. tostring(CompatSetting('ccEmphasis', 'STRONG')) .. ', dispel ' .. tostring(CompatSetting('dispelEmphasis', 'STRONG'))
		.. ', cooldown bars ' .. on('cdBars')
end

-- 0.8.0: a PvP choice (BANZAI -> PVP); ElvUI reads them when it builds its frames
Restore.PVP_KEYS = { pvpCastColors = true, pvpDispelGlow = true, pvpDefensives = true, roleIcons = true }
function Restore:SetPvP(key, on)
	if not self.PVP_KEYS[key] then return nil end
	on = on and true or false
	CompatSet(key, on)
	self:ClassicEdit(function()
		local profile, P = BanzaiProfile(), ns.Payloads
		if profile and P then T.ApplyPvP(profile, self:LayerOptions(), P.elvuiProfile) end
	end)
	StaticPopup_Show('BANZAI_RELOAD')
	return on
end

-- 0.7.0: Banzai identity circles on Focus / Party / Arena / Boss (mMediaTag's portraits there while off)
function Restore:SetIdentityCircles(on)
	on = on and true or false
	CompatSet('identityCircles', on)
	self:ClassicEdit(function()
		local profile, P = BanzaiProfile(), ns.Payloads
		if profile and P then T.SetIdentityCircles(profile, on, P.elvuiProfile) end
	end)
	StaticPopup_Show('BANZAI_RELOAD') -- mMediaTag builds its portraits at load
	return on
end

function Restore:SetToTScale(scale)
	scale = Clamp(scale, 0.5, 1, T.TOT.scale)
	CompatSet('totScale', scale)
	self:ClassicEdit(function()
		local profile, P = BanzaiProfile(), ns.Payloads
		if profile and P then T.ApplyToT(profile, scale, P.elvuiProfile, CompatSetting('frameWidth', T.FRAME_WIDTH), self:LayerOptions()) end
	end)
	StaticPopup_Show('BANZAI_RELOAD')
	return scale
end

-- 0.5.0 options
function Restore:SetSmoothBars(on)
	on = on and true or false
	CompatSet('smoothBars', on)
	local profile, P = BanzaiProfile(), ns.Payloads
	if profile and P then T.SetSmoothBars(profile, on, P.elvuiProfile) end
	local record = CurrentRecord()
	local details = _G.Details
	if on and record and record.previous and details and details.GetCurrentProfileName and details:GetCurrentProfileName() == T.PROFILE then
		self:ApplyDetails(record, self:Fonts().small)
		self:LayoutDetails()
	end
	StaticPopup_Show('BANZAI_RELOAD') -- ElvUI and Eltruism read the textures when they build the bars
	return on
end

-- 1.2.0: SQUARE = Banzai square buttons (default), CIRCLE = Banzai circles, ELVUI = ElvUI's square buttons
function Restore:SetActionStyle(style)
	style = T.ButtonStyle(style)
	CompatSet('actionStyle', style)
	local profile, P = BanzaiProfile(), ns.Payloads
	if profile and P then
		T.SetCircleButtons(profile, style, P.elvuiProfile, self:Fonts().small, self:ActionLook())
		T.ApplyActionMovers(profile, P.elvuiProfile, CompatSetting('barHeight', T.BAR_HEIGHT), style ~= 'ELVUI', self:ActionLook())
	end
	StaticPopup_Show('BANZAI_RELOAD') -- ElvUI sizes the buttons and places their texts when it builds the bars
	return style
end

function Restore:SetCooldownBars(show)
	show = show and true or false
	CompatSet('cooldownBars', show)
	local profile = BanzaiProfile()
	if profile then T.SetCooldownBars(profile, show) end
	StaticPopup_Show('BANZAI_RELOAD')
	return show
end

-- bottom panel height: the chat panel, the Details windows and the action
-- bars (0.6.0: with their breathing room) follow it
function Restore:SetBarHeight(height)
	height = Clamp(height, 24, 40, T.BAR_HEIGHT)
	CompatSet('barHeight', height)
	local profile, P = BanzaiProfile(), ns.Payloads
	if profile then T.Ensure(profile, 'movers').LeftChatMover = T.ChatMover(height) end
	if profile and P then T.ApplyActionMovers(profile, P.elvuiProfile, height, T.ButtonStyle(CompatSetting('actionStyle', 'SQUARE')) ~= 'ELVUI', self:ActionLook()) end
	self:LayoutDetails()
	local E = Engine()
	if E and E.SetMoversPositions and not InCombatLockdown() then pcall(E.SetMoversPositions, E) end
	return height
end

function Restore:SetBuffScale(scale)
	scale = Clamp(scale, 0.5, 1, T.AURAS.scale)
	self:Own().layout.buffScale = scale -- 1.0.1: this character's
	local profile, P = BanzaiProfile(), ns.Payloads
	if profile and P then T.ApplyAuras(profile, scale, P.elvuiProfile, self:BuffsPanel()) end
	StaticPopup_Show('BANZAI_RELOAD')
	return scale
end

-- 1.2.0 BUFFS panel (BANZAI > LAYOUT): on / off, 2 or 3 rows, the buff icons'
-- position. Banzai Art redraws the panel at once; ElvUI's buffs and debuffs
-- move and re-wrap at once out of combat (its own mover positions and buff
-- header update), after combat otherwise. Nothing about the buffs themselves.
function Restore:BuffsPanel()
	-- without Banzai Art there is no panel to draw: the buffs keep their 1.0 places
	return T.BuffsPanel({ on = _G.BanzaiCompat ~= nil and CompatSetting('buffsPanel', true) ~= false, rows = CompatSetting('buffsRows', T.BUFFS_PANEL.rows),
		x = CompatSetting('buffsX', T.BUFFS_PANEL.x), y = CompatSetting('buffsY', T.BUFFS_PANEL.y) })
end

Restore.BUFFS_KEYS = { buffsPanel = 'on', buffsRows = 'rows', buffsX = 'x', buffsY = 'y' }
function Restore:SetBuffsPanel(key, value)
	local field = self.BUFFS_KEYS[key]
	if not field then return nil end
	local panel = self:BuffsPanel()
	panel[field] = (field == 'on') and (value and true or false) or value
	panel = T.BuffsPanel(panel)
	CompatSet(key, panel[field])
	self:ApplyBuffsLayout()
	return panel[field]
end

function Restore:ResetBuffsPosition()
	CompatSet('buffsX', T.BUFFS_PANEL.x)
	CompatSet('buffsY', T.BUFFS_PANEL.y)
	return self:ApplyBuffsLayout()
end

function Restore:ApplyBuffsLayout()
	local profile, P = BanzaiProfile(), ns.Payloads
	if profile and P then T.ApplyAuras(profile, self:Own().layout.buffScale or T.AURAS.scale, P.elvuiProfile, self:BuffsPanel()) end
	local E = Engine()
	self.buffsPending = nil
	if not (E and E.data and E.data:GetCurrentProfile() == T.PROFILE) then return 'written (not on the Banzai profile)' end
	if InCombatLockdown() then
		self.buffsPending = true
		return 'waiting (combat)'
	end
	if E.SetMoversPositions then pcall(E.SetMoversPositions, E) end
	local A = E.GetModule and E:GetModule('Auras', true)
	if A and A.BuffFrame and A.UpdateHeader then pcall(A.UpdateHeader, A, A.BuffFrame) end
	return 'applied'
end

-- a buffs layout chosen in combat: applied when it ends (one check, nothing else)
local buffsEvents = CreateFrame('Frame')
buffsEvents:RegisterEvent('PLAYER_REGEN_ENABLED')
buffsEvents:SetScript('OnEvent', function() if Restore.buffsPending then Restore:ApplyBuffsLayout() end end)

-- 1.0.0 BANZAI > ACTION BARS: the circles' size, spacing and keybind / count size
Restore.ACTION_LOOK = { abSize = 'size', abSpacing = 'spacing', abKeybind = 'keybind', abCount = 'count' }
function Restore:ActionLook()
	local look = {}
	for key, field in pairs(self.ACTION_LOOK) do look[field] = CompatSetting(key, nil) end
	return T.CircleLook(look)
end

function Restore:SetActionLook(key, value)
	local field = self.ACTION_LOOK[key]
	if not field then return nil end
	local range = T.CIRCLE_LOOK[field]
	value = Clamp(value, range[1], range[2], range[1])
	CompatSet(key, value)
	local profile, P = BanzaiProfile(), ns.Payloads
	local style = T.ButtonStyle(CompatSetting('actionStyle', 'SQUARE'))
	if profile and P and style ~= 'ELVUI' then
		T.SetCircleButtons(profile, style, P.elvuiProfile, self:Fonts().small, self:ActionLook())
		T.ApplyActionMovers(profile, P.elvuiProfile, CompatSetting('barHeight', T.BAR_HEIGHT), true, self:ActionLook())
	end
	StaticPopup_Show('BANZAI_RELOAD') -- ElvUI sizes the buttons when it builds the bars
	return value
end

-- 1.0.0: Player / Target / Focus / Target-of-Target width (share of Bushido's,
-- per character); ElvUI sizes the frames and their texts when it builds them
function Restore:SetFrameWidth(width)
	width = T.FrameWidth(width)
	CompatSet('frameWidth', width)
	self:ClassicEdit(function()
		local profile, P = BanzaiProfile(), ns.Payloads
		if profile and P then
			local opts = self:LayerOptions()
			T.ApplyFrameWidths(profile, P.elvuiProfile, opts, self:Fonts().small)
			T.ApplyToT(profile, opts.totScale, P.elvuiProfile, width, opts)
		end
	end)
	StaticPopup_Show('BANZAI_RELOAD')
	return width
end

-- Player / Target height and distance from the screen edges (BANZAI > UNIT
-- FRAMES), on top of their width; ElvUI moves them at once (out of combat)
function Restore:SetUnitLayout(height, spread)
	local layout = self:Own().layout -- 1.0.1: this character's
	layout.unitHeight = Clamp(height or layout.unitHeight, -120, 120, 0)
	layout.unitSpread = Clamp(spread or layout.unitSpread, -150, 150, 0)
	self:ClassicEdit(function()
		local profile, P = BanzaiProfile(), ns.Payloads
		if profile and P then
			local opts = self:LayerOptions()
			T.ApplyFrameWidths(profile, P.elvuiProfile, opts, self:Fonts().small)
			T.ApplyToT(profile, opts.totScale, P.elvuiProfile, opts.frameWidth, opts) -- the Target-of-Target moves with the Target
		end
	end)
	local E = Engine()
	if E and E.SetMoversPositions and not InCombatLockdown() then pcall(E.SetMoversPositions, E) end
	return layout.unitHeight, layout.unitSpread
end

-- 1.0.0: Banzai's AFK screen (BushidoPrivateCompat AFK.lua) or ElvUI's; ElvUI
-- switches its own on / off through its AFK module (its options do the same)
function Restore:SetAFK(on)
	on = on and true or false
	CompatSet('afk', on)
	local profile, P = BanzaiProfile(), ns.Payloads
	if profile then T.ApplyAFK(profile, P and P.elvuiProfile, on) end
	local E = Engine()
	local AFK = E and E.GetModule and E:GetModule('AFK', true)
	if AFK and AFK.Toggle and E.db and E.db.general and E.data and E.data:GetCurrentProfile() == T.PROFILE then pcall(AFK.Toggle, AFK) end
	return on
end

-- 1.0.0 tooltip theme: BANZAI (glass, gradient edge, small crisp font) or ELVUI (Bushido's tooltip as it was)
-- 1.1.0 panel background (BANZAI > APPEARANCE > PANEL STYLE): the panels
-- repaint at once (Banzai Art); the Details row text, which Banzai styles,
-- is set for the background (1.1.1: bright off-white on parchment, white otherwise) through Details' own row settings and its
-- instance refresh (the profile for the next login, the live windows now)
function Restore:SetPanelBackground(mode)
	mode = (mode == 'SOLID' or mode == 'PARCHMENT') and mode or 'GLASS'
	CompatSet('panelBackground', mode)
	self:ApplyDetailsInk()
	return mode
end

function Restore:ApplyDetailsInk()
	local parchment = CompatSetting('panelBackground', 'GLASS') == 'PARCHMENT'
	local details = _G.Details
	if not (details and details.GetProfile and details.GetCurrentProfileName and details:GetCurrentProfileName() == T.PROFILE) then return 'skipped (Details not on the Banzai profile)' end
	local profile = details:GetProfile(T.PROFILE)
	if profile then T.DetailsRowInk(profile, parchment) end
	local n = 0
	for i = 1, 2 do
		local window = details.GetInstance and details:GetInstance(i)
		if window and type(window.row_info) == 'table' then
			local c = parchment and T.DETAILS_STYLE.ink or T.DETAILS_STYLE.text
			window.row_info.fixed_text_color = { c[1], c[2], c[3], c[4] }
			if window.InstanceRefreshRows then pcall(window.InstanceRefreshRows, window) end
			n = n + 1
		end
	end
	return (parchment and 'off-white' or 'white') .. ' row text on ' .. n .. ' windows'
end

function Restore:SetTooltipTheme(theme)
	theme = (theme == 'ELVUI') and 'ELVUI' or 'BANZAI'
	CompatSet('tooltipTheme', theme)
	local profile, P = BanzaiProfile(), ns.Payloads
	if profile then T.ApplyTooltipFonts(profile, P and P.elvuiProfile, self:Fonts(), theme) end
	local E = Engine()
	local TT = E and E.GetModule and E:GetModule('Tooltip', true)
	if TT and TT.SetTooltipFonts and E.data and E.data:GetCurrentProfile() == T.PROFILE then pcall(TT.SetTooltipFonts, TT) end
	return theme
end

---------------------------------------------------------------------------
-- 1.3.0 BANZAI SPLIT and BANZAI COMPACT
---------------------------------------------------------------------------
-- a classic profile edit (the options above) while the profile carries the split
-- layer: the classic values first, the edit, then the whole layer again
function Restore:ClassicEdit(fn)
	local profile = BanzaiProfile()
	local reverted = profile and T.RevertFrameStyle(profile, DB().splitLayer)
	local a, b = fn()
	local E = Engine()
	if profile and E and E.mynameRealm and (reverted or T.FrameStyle(CompatSetting('frameStyle', 'CLASSIC')) == 'SPLIT') then
		self:CharacterLayer(E.mynameRealm, true)
	end
	return a, b
end

-- BANZAI > UNIT FRAMES > FRAME STYLE: CLASSIC | SPLIT, this character's choice;
-- the ElvUI side is its layer (written now), a reload builds the frames with it
function Restore:SetFrameStyle(style)
	style = T.FrameStyle(style)
	CompatSet('frameStyle', style)
	local E = Engine()
	if BanzaiProfile() and E and E.mynameRealm then self:CharacterLayer(E.mynameRealm, true) end
	StaticPopup_Show('BANZAI_RELOAD')
	return style
end

-- a BANZAI SPLIT choice: positions move the frames at once (ElvUI's movers, out of
-- combat), sizes with a reload; stored for later while BANZAI CLASSIC is the style
Restore.SPLIT_LIVE = { splitPlayerX = true, splitPlayerY = true, splitTargetX = true, splitTargetY = true }
Restore.SPLIT_RELOAD = { splitScale = true, splitHubScale = true, splitParty = true, splitThickness = true, splitCastBar = true } -- 1.3.3: + the cast bar (the class bar's place)
Restore.SPLIT_ART = { splitHpText = true, splitPowerText = true, splitTargetPlate = true, splitCastName = true, splitCastTimer = true } -- Banzai Art's alone, at once (1.3.3: + the cast bar's texts)
function Restore:SetSplit(key, value)
	if not (Restore.SPLIT_LIVE[key] or Restore.SPLIT_RELOAD[key] or Restore.SPLIT_ART[key]) then return nil end -- 1.3.1: splitThickness is a reload key
	CompatSet(key, value)
	local value2 = CompatSetting(key, value) -- as Banzai Art keeps it (in range)
	if T.FrameStyle(CompatSetting('frameStyle', 'CLASSIC')) ~= 'SPLIT' or not (Restore.SPLIT_LIVE[key] or Restore.SPLIT_RELOAD[key]) then return value2 end
	local E = Engine()
	if BanzaiProfile() and E and E.mynameRealm then self:CharacterLayer(E.mynameRealm, true) end
	if Restore.SPLIT_LIVE[key] then
		if E and E.SetMoversPositions and not InCombatLockdown() then pcall(E.SetMoversPositions, E) end
	else
		StaticPopup_Show('BANZAI_RELOAD')
	end
	return value2
end

function Restore:ResetSplitPositions()
	for _, key in ipairs({ 'splitPlayerX', 'splitPlayerY', 'splitTargetX', 'splitTargetY' }) do CompatSet(key, T.SPLIT.defaults[key]) end
	return self:SetSplit('splitPlayerX', T.SPLIT.defaults.splitPlayerX)
end

-- the Details icon set BANZAI COMPACT uses: Darren's original sheet when the build
-- made one, else Jiberish Icons' Fabled class set (referenced in place), else
-- Banzai's own class-colour discs
function Restore:DetailsIconFile()
	local art = _G.BanzaiCompat
	if art and art.IdentityDetailsSheet and art:IdentityDetailsSheet() then return T.DETAILS_ICONS.banzai end
	if C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('JiberishIcons') then return T.DETAILS_ICONS.fabled end
	return T.DETAILS_ICONS.discs
end

-- BANZAI > LAYOUT > DETAILS > METER STYLE: the rows of the Banzai Details profile
-- and of the two live windows (Details' own settings and SetBarSettings, which
-- re-anchors and refreshes its rows); out of combat (after it otherwise)
function Restore:ApplyDetailsStyle()
	local style = T.DetailsStyle(CompatSetting('detailsStyle', 'CURRENT'))
	local details = _G.Details
	if not (details and details.GetProfile and details.GetCurrentProfileName and details:GetCurrentProfileName() == T.PROFILE) then return 'skipped (Details not on the Banzai profile)' end
	if InCombatLockdown() then
		self.detailsStylePending = true
		return 'waiting (combat)'
	end
	self.detailsStylePending = nil
	local icon = self:DetailsIconFile()
	local face = self:CompactNameFace() -- 1.3.1
	local P = ns.Payloads
	local historical = P and type(P.detailsProfile) == 'table' and type(P.detailsProfile.instances) == 'table' and P.detailsProfile.instances or {}
	local function restyle(row, index)
		if style == 'COMPACT' then return T.DetailsCompactRow(row, icon, face) end
		return T.DetailsCurrentRow(row, historical[index] and historical[index].row_info)
	end
	local profile = details:GetProfile(T.PROFILE)
	for index, window in pairs(profile and type(profile.instances) == 'table' and profile.instances or {}) do
		if type(window) == 'table' and type(window.row_info) == 'table' then restyle(window.row_info, index) end
	end
	local n = 0
	for i = 1, 2 do
		local window = details.GetInstance and details:GetInstance(i)
		if window and type(window.row_info) == 'table' then
			local row = restyle(window.row_info, i)
			if window.SetBarSettings then
				pcall(window.SetBarSettings, window, row.height, nil, nil, nil, nil, nil, nil, nil, row.no_icon and '' or row.icon_file, row.start_after_icon, row.space.between, nil, row.icon_size_offset)
			elseif window.InstanceRefreshRows then
				pcall(window.InstanceRefreshRows, window)
			end
			n = n + 1
		end
	end
	DB().detailsStyleApplied = style
	DB().detailsFaceApplied = face or false
	return style .. ' meter rows on ' .. n .. ' windows'
end

-- The COMPACT names follow the selected BANZAI display face.
function Restore:CompactNameFace()
	local art = _G.BanzaiCompat
	local theme = art and art.Theme
	if not (theme and theme.DisplayFont) then return nil end
	return theme:DisplayFont()
end

-- The display-font selection refreshes tracked Banzai text and COMPACT Details names at once.
function Restore:SetDisplayFace(face)
	local art = _G.BanzaiCompat
	local theme = art and art.Theme
	if not (theme and theme.DISPLAY_FACE_SET and theme.DISPLAY_FACE_SET[face]) then face = 'BANZAI_DEFAULT' end
	CompatSet('displayFace', face)
	if theme.RefreshDisplayFonts then theme:RefreshDisplayFonts() end
	local preview = art and art.Preview
	if preview and preview.RefreshFontBakeoff then preview:RefreshFontBakeoff() end
	if T.DetailsStyle(CompatSetting('detailsStyle', 'CURRENT')) == 'COMPACT' then self:ApplyDetailsStyle() end
	return face
end

-- 1.3.2 BANZAI > UNIT FRAMES > IDENTITY ART: which class art the identity circles show, at once
-- (Banzai Art repaints its hubs and circles)
Restore.IDENTITY_ARTS = { AUTO = true, BANZAI = true, FABLED = true, CLASS = true }
function Restore:SetIdentityArt(mode)
	mode = self.IDENTITY_ARTS[mode] and mode or 'AUTO'
	CompatSet('identityArt', mode)
	return mode
end

function Restore:SetDetailsStyle(style)
	style = T.DetailsStyle(style)
	CompatSet('detailsStyle', style)
	return self:ApplyDetailsStyle()
end

local detailsEvents = CreateFrame('Frame')
detailsEvents:RegisterEvent('PLAYER_REGEN_ENABLED')
detailsEvents:SetScript('OnEvent', function()
	if Restore.detailsStylePending then Restore:ApplyDetailsStyle() end
	if Restore.detailsGeometryPending then -- 1.3.6: the gutter's window places waited for combat to end
		Restore.detailsGeometryPending = nil
		Restore:LayoutDetails(true)
	end
end)

---------------------------------------------------------------------------
-- Popup, slash, lifecycle
---------------------------------------------------------------------------
StaticPopupDialogs.BANZAI_RELOAD = {
	text = 'BANZAI ' .. VERSION .. '\n\nReload the UI to finish.',
	button1 = 'Reload now',
	button2 = 'Later',
	OnAccept = function() ReloadUI() end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

SLASH_BANZAI1 = '/banzai'
SLASH_BANZAI2 = '/bushido'
SlashCmdList.BANZAI = function(input)
	local command, argument = string.match(input or '', '^%s*(%S*)%s*(%S*)')
	command = string.lower(command or '')
	if command == 'apply' then
		Restore:ApplyHere('manual')
	elseif command == 'restore' then
		Restore:Revert()
	elseif command == 'theme' then
		Restore:SetTheme(argument)
	elseif command == 'editmode' then
		Restore:ImportEditMode()
	elseif command == 'status' then
		Restore:Status()
		Print('commands: /banzai (options) | status | apply | restore | theme vibrant|class | editmode')
	else
		Print(NAME .. ' ' .. VERSION .. ' - settings: ElvUI options > BANZAI. /banzai status for details.')
		Restore:OpenOptions()
	end
end

-- first login: apply once (AUTO_APPLY); a character on an older build: Banzai layer
function Restore:OnLogin()
	local E = Engine()
	if not (E and E.Initialized) then return end
	local key = E.mynameRealm
	local record = DB().characters[key]
	local result
	-- 1.0.1: what is left of the 0.9.0 arena-system choice goes (sArena is not Banzai's business any more)
	if record then
		record.arenaSystem = nil
		if record.previous then record.previous.arenaAddonState = nil end
	end
	if AUTO_APPLY[key] and not (record and (record.applied or record.restored)) then
		result = self:Apply('first login')
	elseif record and record.applied and (record.layer or 0) < T.LAYER then
		result = self:Upgrade()
	elseif record and record.applied and record.applied.version ~= VERSION then
		-- a build without new layer keys: the version only (no reload needed)
		record.applied.version = VERSION
		record.applied.upgraded = date('%Y-%m-%d %H:%M:%S')
		Print(format('updated to %s %s: licensed display-font selection locked to Shojumaru; unsupported strings use the Information Font, and approved layouts and features are unchanged.', NAME, VERSION))
		if self.ApplyDetailsInk then self:ApplyDetailsInk() end -- 1.1.1: a character on parchment gets the readable text at once
		-- 1.3.6: the two windows placed again around the centre gutter (geometry only), on Banzai's Details profile only
		local details = _G.Details
		if details and details.GetCurrentProfileName and details:GetCurrentProfileName() == T.PROFILE then self:LayoutDetailsSoon(true) end
		result = true
	end
	-- 1.3.0: the shared Details profile shows this character's meter style (only when it differs from what was applied last)
	local style = T.DetailsStyle(CompatSetting('detailsStyle', 'CURRENT'))
	if record and record.applied and (style ~= T.DetailsStyle(DB().detailsStyleApplied) or (style == 'COMPACT' and (self:CompactNameFace() or false) ~= DB().detailsFaceApplied)) then self:ApplyDetailsStyle() end -- 1.3.1: or the COMPACT names' font
	self:TrackerOwnership('login')
	return result
end

local frame = CreateFrame('Frame')
frame:RegisterEvent('ADDON_LOADED')
frame:RegisterEvent('PLAYER_ENTERING_WORLD')
frame:SetScript('OnEvent', function(self, event, arg1, arg2)
	if event == 'ADDON_LOADED' then
		if arg1 ~= addonName then return end
		self:UnregisterEvent('ADDON_LOADED')
		Restore:OnAddonLoaded()
		return
	end
	if not (arg1 or arg2) then return end -- isInitialLogin / isReload
	self:UnregisterEvent('PLAYER_ENTERING_WORLD')
	C_Timer.After(3, function() Restore:OnLogin() end)
end)

-- 1.0.2 / 1.0.3: Blizzard's objective tracker checked one frame after each
-- event that puts it back on screen (read from the game's and Eltruism's code;
-- one frame later so the order of the handlers of one event never matters):
--   PLAYER_ENTERING_WORLD              Eltruism re-anchors it (BreakFromFrameManager:
--                                     SetParent UIParent) in a handler registered
--                                     at ElvUI's init, after Banzai's - 1.0.2 lost here
--   FIRST_FRAME_RENDERED, ACTIVE_TALENT_GROUP_CHANGED  Eltruism re-anchors it (not
--                                     listened to before)
--   EDIT_MODE_LAYOUTS_UPDATED          Edit Mode applies the layout (SetParent to
--                                     its managed container or UIParent), then
--                                     Eltruism re-anchors it
--   PLAYER_SPECIALIZATION_CHANGED      Edit Mode applies the layout again
--   EditMode.Exit (EventRegistry)      Edit Mode reverts unsaved changes (same)
--   ADDON_LOADED Blizzard_ObjectiveTracker  the tracker built late
--   PLAYER_REGEN_ENABLED               only when a change waited for combat to end
-- 1.3.1: and whenever anything puts the tracker back on screen while the Banzai
-- tracker shows (Restore:WatchTracker's sentinel, made by the first of these checks)
local trackerEvents = CreateFrame('Frame')
trackerEvents:RegisterEvent('ADDON_LOADED')
trackerEvents:RegisterEvent('PLAYER_ENTERING_WORLD')
trackerEvents:RegisterEvent('FIRST_FRAME_RENDERED')
trackerEvents:RegisterEvent('EDIT_MODE_LAYOUTS_UPDATED')
trackerEvents:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
trackerEvents:RegisterEvent('PLAYER_REGEN_ENABLED')
trackerEvents:RegisterUnitEvent('PLAYER_SPECIALIZATION_CHANGED', 'player')
trackerEvents:SetScript('OnEvent', function(_, event, arg1)
	if event == 'ADDON_LOADED' and arg1 ~= 'Blizzard_ObjectiveTracker' then return end
	if event == 'PLAYER_REGEN_ENABLED' and not Restore.trackerPending then return end
	Restore:QueueTrackerOwnership(event)
end)
if _G.EventRegistry and _G.EventRegistry.RegisterCallback then
	_G.EventRegistry:RegisterCallback('EditMode.Exit', function() Restore:QueueTrackerOwnership('EditMode.Exit') end, trackerEvents)
end
