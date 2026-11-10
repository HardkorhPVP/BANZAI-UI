--[[
	BANZAI - Theme.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	Colour identity and settings shared by the Banzai art, the bottom bar, the
	tracker, cast history and the options page.

	VIBRANT (default): green-heavy  lime -> emerald -> (teal) -> electric violet -> purple
	CLASS            : the player's class colour, bright -> base -> deep

	Ramps are evaluated at any position 0..1 and painted with many two-stop
	segments, so they stay saturated (no muddy midpoint). Alpha always travels
	inside the gradient colours: the game ignores SetAlpha on textures coloured
	with SetGradient (0.3.0's white line under the bottom bar).

	0.6.0: settings are kept per character (BanzaiCompatDB.chars["Name - Realm"])
	so Character Sync decides when an alt takes the master's settings. The one
	account-wide set of 0.5.x becomes the starting point of every character.

	1.1.0 panel material (chat, Details, minimap): the bamboo frame's border
	style (CLASS: the class colour family light -> base -> deep; BANZAI: natural
	vivid bamboo greens with purple rope; HARDKORH: the green -> emerald ->
	violet -> purple identity gradient) and, independently, the interior
	(SOLID dark green-black, GLASS the approved translucent dark green,
	PARCHMENT the original cream / tan paper). The rope keeps its own colour
	in every style (hemp in CLASS, violet / purple otherwise).

	1.2.0: action buttons BANZAI SQUARE (the new default) | BANZAI CIRCLES |
	ELVUI SQUARE; the BUFFS panel (on, 2 or 3 rows, the buff icons' position)
	in the same panel material.

	1.3.0: a second, optional unit-frame family - FRAME STYLE CLASSIC (the
	approved Banzai frames, the default for every character) | SPLIT (health
	left / resource right of a central identity and cast hub, Split.lua) - with
	its own positions, scales, texts, enhanced targeted nameplate and party
	choice, and the Details meter interior CURRENT (default) | COMPACT. No
	setting changes by itself: an upgraded character keeps CLASSIC / CURRENT.

	1.3.1 introduced Banzai's own display typography. BANZAI Default is
	Shojumaru at 105%; Automatic uses it only for fully supported strings,
	otherwise the Information Font. The separate small information font is
	unchanged.
	BANZAI SPLIT's health and resource bars are one class colour family
	(Theme.Ramp) and a little thicker.

	1.3.2: IDENTITY ART (identityArt, BANZAI > UNIT FRAMES): AUTO (Darren's
	original BANZAI class art in the BANZAI SPLIT hubs and party circles, the
	classic circles as before) | BANZAI (the classic circles too) | FABLED |
	CLASS (class-colour discs). Identity.lua decides where the art fits.

	1.3.3: the BANZAI SPLIT bamboo cast bar (BANZAI > UNIT FRAMES > FRAME STYLE >
	SPLIT CAST BAR: splitCastBar, splitCastName, splitCastTimer - all on by
	default, kept per character, carried by Character Sync like every key here).

	1.3.4: no new setting (a hotfix: the PvP frames' safety, a lower cast bar).
	ccEmphasis / dispelEmphasis now shape the preview samples only (the live
	CC / dispel border on ElvUI's aura icons is retired, PvPFrames.lua).

	1.3.5: no new setting (the Details divider follows the Details frame and the
	panel background; the PvP visuals' cleanup needs none).

	1.3.6: no new setting (the Details centre gutter is the two windows' geometry,
	Compat.DETAILS).

	1.3.7: no new setting (HARDKORH PARCHMENT is one material that never stretches,
	Compat.PARCHMENT; the parchment brightness keeps its range).
]]
local _, ns = ...

local Theme = {}
ns.Theme = Theme

Theme.VERSION = '1.4.0'
Theme.MEDIA = 'Interface\\AddOns\\BushidoPrivateCompat\\media\\'
Theme.WHITE = 'Interface\\Buttons\\WHITE8X8'

Theme.DEFAULTS = {
	theme = 'VIBRANT',     -- VIBRANT | CLASS
	gradient = 'FORWARD',  -- FORWARD (green -> purple) | REVERSE   (Details keeps its own direction)
	intensity = 1,         -- 0.5 .. 1  colour strength of the frames
	bambooArt = true,      -- tied bamboo bundles on end points, minimap and Details
	glassOpacity = 0.72,   -- dark green glass (Details, tracker, bottom bar)
	healthInside = true,   -- health value + percent inside the Player / Target / Focus bars
	healthPercent = true,  -- the percent part of it
	bar = true,            -- Banzai bottom information bar
	barHeight = 32,        -- 0.5.0: room above and below the text
	barCenterSize = 15,
	barOpacity = 0.72,
	barTextSize = 11,
	detailsFrame = true,
	chatFrame = true,      -- Banzai glass + band around the chat (lower left), same size as Details
	borderScale = 1,       -- 1.1.0: the bamboo stalks' thickness on the minimap / Details / chat (0.7 .. 1; 1 = 10 units, the content inset)
	smoothBars = true,     -- smooth Banzai health texture instead of the Bushido slots
	actionStyle = 'SQUARE', -- 1.2.0: SQUARE Banzai square buttons (default) | CIRCLE Banzai circles | ELVUI ElvUI's square buttons
	cooldownBars = false,  -- Bushido's target cooldown bars (ElvUI bars 2 + 4) shown
	logo = true,           -- small BANZAI wordmark, top centre (out of combat)
	combatLogo = true,     -- 0.6.0: in combat the wordmark moves between Player and Target, larger, with the miniature tree
	targetPlate = true,    -- 0.6.0: Banzai treatment of the targeted enemy nameplate
	identityCircles = true, -- 0.7.0: small Fabled spec / class circles on Focus, Party, Arena and player Boss frames
	-- 0.8.0 PvP (BANZAI > PVP): ElvUI's own elements, written by BushidoPrivateRestore
	pvpCastColors = true,  -- interruptible casts attention amber, uninterruptible restrained steel
	pvpDispelGlow = true,  -- dispellable effects as a border glow, not a recoloured bar
	pvpDefensives = true,  -- big / external defensives small on friendly frames and Banzai arena frames
	previewState = 'NORMAL', -- unit-frame preview state (synthetic sample data)
	-- 0.9.0 party / arena frames and the player's cooldown bars (BANZAI > PVP)
	roleIcons = true,      -- mMediaTag's role icon ([mMT-role:icon]) inside the right end of party / arena ally bars
	trinketCircles = true, -- PvP medallion circle beside party / arena frames (the game's own arena trinket data)
	ccEmphasis = 'STRONG', -- STRONG (border, CC text, restrained pulse) | CLEAR (border, text) | MINIMAL (icon only)
	dispelEmphasis = 'STRONG', -- the same levels for a harmful effect this character can dispel
	cdBars = true,         -- offensive / defensive cooldown bars of the player's own spells
	cdOffensiveCount = 5,  -- at most this many bars at once (1 .. 5)
	cdDefensiveCount = 5,
	cdScale = 1,           -- 0.7 .. 1.2
	cdOpacity = 1,         -- 0.4 .. 1
	cdSpread = 335,        -- each group's centre, units from the screen centre (between chat / Details and the action bars)
	cdHeight = 54,         -- the lowest bar's bottom edge above the screen bottom
	cdTracked = false,     -- false: Banzai's selection; else { [class] = { [spellID] = true | false } }
	minimapFrame = true,
	zoneLabel = true,
	tracker = true,        -- Banzai objective tracker (Kaliel's hidden while on)
	trackerCollapsed = false,
	castHistory = true,
	castEntries = 4,
	castOpacity = 0.9,
	castScale = 1,
	totScale = 0.72,       -- Target-of-Target size
	-- 1.0.0 (all of them per character, so Character Sync carries them)
	frameWidth = 0.5,      -- Player / Target / Focus / Target-of-Target width, share of Bushido's (BushidoPrivateRestore writes it)
	abSize = 30,           -- circular action buttons (BANZAI > ACTION BARS; BushidoPrivateRestore writes them)
	abSpacing = 6,
	abKeybind = 1.3,       -- keybind size against Bushido's
	abCount = 0.8,         -- charge / stack count size against Bushido's
	ringIntensity = 1,     -- strength of the circles' green -> purple ring (0.4 .. 1)
	tooltipTheme = 'BANZAI', -- BANZAI glass | ELVUI (Bushido's tooltip as it was)
	tooltipOpacity = 0.86, -- the glass
	tooltipScale = 1,      -- every tooltip
	panelTips = true,      -- bottom-panel tooltips
	panelTipsCombat = false, -- ... in combat too
	panelTipAnchor = 'ITEM', -- ITEM (above the hovered entry) | CURSOR
	trackerTips = true,    -- objective tracker tooltips
	afk = true,            -- Banzai's AFK screen (ElvUI's off while it is on)
	afkModel = true,       -- the character model (off: the Fabled class art in its place)
	afkRotate = true,
	afkTurn = 24,          -- seconds per full turn of the model
	afkOpacity = 0.8,      -- background glass
	afkBrand = 1,          -- BANZAI, the tree and the green / purple light
	afkName = true,
	afkSpec = true,
	afkLevel = true,
	afkZone = true,
	-- 1.1.0 panel material (BANZAI > APPEARANCE > PANEL STYLE), any border with any background
	panelBorder = 'BANZAI',     -- CLASS | BANZAI | HARDKORH
	panelBackground = 'GLASS',  -- SOLID | GLASS | PARCHMENT
	parchmentBrightness = 1,    -- 0.7 .. 1.1
	-- 1.2.0 BUFFS panel (BANZAI > LAYOUT): the player's buffs (ElvUI's own buff icons) in a bamboo panel at the top-left
	buffsPanel = true,
	buffsRows = 2,              -- 2 | 3 rows of 10 (ElvUI's buffs per row in the Banzai profile)
	buffsX = 30,                -- the buff icons' top-left corner, units from the screen's top-left (the panel around them)
	buffsY = 30,
	-- 1.3.0 BANZAI > UNIT FRAMES > FRAME STYLE (Darren chooses SPLIT himself; BushidoPrivateRestore writes the ElvUI side, a reload applies it)
	frameStyle = 'CLASSIC',     -- CLASSIC | SPLIT
	splitPlayerX = 0,           -- the Player hub's centre: units right of the screen centre
	splitPlayerY = 290,         -- ... above the screen bottom (clear of cast history and the action bars)
	splitTargetX = 0,           -- the Target hub's centre: units right of the screen centre
	splitTargetY = 112,         -- ... below the screen top (clear of the wordmark and encounter bars)
	splitScale = 1,             -- bar length and height of the split frames (0.8 .. 1.25)
	splitHubScale = 1,          -- the central hubs (0.8 .. 1.3)
	splitHpText = true,         -- current health + percent of the split health bars (1.3.1: above the Player / Target bars)
	splitPowerText = true,      -- current resource + percent of the split resource bars (1.3.1: above the Player / Target bars)
	splitTargetPlate = true,    -- the enhanced targeted nameplate (only while BANZAI SPLIT is the style)
	splitParty = true,          -- party / arena allies in the split construction (off: the classic party frames)
	splitThickness = 1,         -- 1.3.1: the Player / Target bars' thickness on top of the frame scale (0.75 .. 1.3)
	-- 1.3.0 BANZAI > LAYOUT > DETAILS > METER STYLE
	detailsStyle = 'CURRENT',   -- CURRENT | COMPACT
	-- 1.3.1 BANZAI > APPEARANCE > FONTS: Banzai's own display typography (the small information font is separate)
	displayFace = 'BANZAI_DEFAULT', -- AUTO | BANZAI_DEFAULT | an approved display face
	displayScale = 1,           -- the Banzai display texts' size (0.85 .. 1.2)
	-- 1.3.2 BANZAI > UNIT FRAMES > IDENTITY ART (Identity.lua)
	identityArt = 'AUTO',       -- AUTO | BANZAI | FABLED | CLASS
	-- 1.3.3 BANZAI > UNIT FRAMES > FRAME STYLE > SPLIT CAST BAR (CastBar.lua; Player / Target in BANZAI SPLIT only)
	splitCastBar = true,        -- the bamboo cast bar above the Player / Target (off: the spell icon in the hub alone; a reload moves the class bar)
	splitCastName = true,       -- the spell name on it
	splitCastTimer = true,      -- the remaining time on it
}
Theme.ACTION_STYLES = { 'SQUARE', 'CIRCLE', 'ELVUI' }
Theme.BUFFS_POSITION = { min = 26, maxX = 900, maxY = 600 } -- min: the bamboo ends stay on screen
Theme.PANEL_BORDERS = { 'CLASS', 'BANZAI', 'HARDKORH' }
Theme.PANEL_BACKGROUNDS = { 'SOLID', 'GLASS', 'PARCHMENT' }
Theme.BORDER_SCALE = { min = 0.7, max = 1 }
-- 1.3.0 the choices and the ranges every read brings a value back into (Character Sync imports, old masters)
Theme.FRAME_STYLES = { 'CLASSIC', 'SPLIT' }
Theme.DETAILS_STYLES = { 'CURRENT', 'COMPACT' }
Theme.SPLIT_LIMITS = {
	splitPlayerX = { -400, 400, 0 }, splitPlayerY = { 150, 520, 290 },
	splitTargetX = { -400, 400, 0 }, splitTargetY = { 70, 320, 112 },
	splitScale = { 0.8, 1.25, 1 }, splitHubScale = { 0.8, 1.3, 1 },
	splitThickness = { 0.75, 1.3, 1 }, -- 1.3.1
	displayScale = { 0.85, 1.2, 1 },   -- 1.3.1
}
-- 1.3.1 Banzai display font; the separate information font remains unchanged.
Theme.DISPLAY_FACES = { 'SHOJUMARU', 'RYUJIN_ATTACK', 'GANG_OF_THREE', 'OSAKA_SANS', 'SEKAIWO', 'XANGDA_SHINY', 'NINJA_NARUTO', 'INFORMATION', 'PREVIOUS' } -- FontBakeoff.lua owns the final list
Theme.IDENTITY_ARTS = { 'AUTO', 'BANZAI', 'FABLED', 'CLASS' } -- 1.3.2

local COLORS = {
	lime = { 0.62, 1.00, 0.12 },
	emerald = { 0.00, 0.90, 0.42 },
	teal = { 0.00, 0.76, 0.72 },
	violet = { 0.56, 0.22, 1.00 },
	purple = { 0.62, 0.10, 0.86 },
	glass = { 0.015, 0.075, 0.045 }, -- very dark green
}
Theme.COLORS = COLORS

-- horizontal ramp (minimap frame, bottom-bar edge): ~60% green, purple counter-colour
local VIBRANT_H = {
	{ 0.00, COLORS.lime }, { 0.42, COLORS.emerald }, { 0.60, COLORS.teal }, { 0.80, COLORS.violet }, { 1.00, COLORS.purple },
}
-- Details frame only (Darren, 0.4.0): purple at the top-left, through violet and
-- emerald to vivid lime, green dominant toward the bottom-right
local VIBRANT_DETAILS = {
	{ 0.00, COLORS.purple }, { 0.16, COLORS.violet }, { 0.30, COLORS.teal }, { 0.48, COLORS.emerald }, { 0.75, COLORS.lime }, { 1.00, COLORS.lime },
}
-- bamboo stalks (bottom -> top) and their cord
local VIBRANT_STALK = { { 0.00, COLORS.emerald }, { 0.55, COLORS.lime }, { 1.00, COLORS.lime } }
local VIBRANT_TIE = { { 0.00, COLORS.violet }, { 1.00, COLORS.purple } }
-- 1.1.0 panel bamboo. HARDKORH: the identity gradient over the frame (the
-- field of each panel: chat lime top-left -> purple bottom-right, Details the
-- other way round, minimap left -> right). BANZAI: natural bamboo, every stalk
-- its own green (lime-leaning, one emerald-leaning), a little lighter toward
-- one end, every segment a touch different. The rope never takes the stalk
-- colours: natural hemp in CLASS, violet -> purple in BANZAI / HARDKORH.
local HARDKORH_STALK = { { 0.00, COLORS.lime }, { 0.42, COLORS.emerald }, { 0.58, COLORS.teal }, { 0.78, COLORS.violet }, { 1.00, COLORS.purple } }
local BANZAI_STALKS = { top = { 0.58, 0.93, 0.22 }, right = { 0.44, 0.86, 0.28 }, bottom = { 0.52, 0.90, 0.20 }, left = { 0.36, 0.84, 0.34 } }
local HEMP_ROPE = { { 0.00, { 0.56, 0.42, 0.24 } }, { 1.00, { 0.38, 0.27, 0.14 } } }

-- Settings saved by an older build: values still at a default that a newer
-- build changed take the new default (a value Darren changed himself is
-- kept); retired keys go. One step per schema.
Theme.SCHEMA = 9
local MIGRATIONS = {
	[4] = function(db) -- 0.3.0 -> 0.4.0
		if db.barHeight == 22 then db.barHeight = 28 end
		if db.barOpacity == 0.86 then db.barOpacity = 0.72 end
		if db.bambooEnds == false then db.bambooArt = false end
		db.bambooEnds, db.detail = nil, nil
	end,
	[5] = function(db) -- 0.4.0 -> 0.5.0
		if db.barHeight == 28 then db.barHeight = 32 end
		if type(db.castEntries) == 'number' and db.castEntries > 6 then db.castEntries = 6 end
	end,
	[7] = function(db) -- 1.0.3 -> 1.1.0: the band's thickness range (0.5 .. 1.8) becomes the stalk's (0.7 .. 1); the new panel keys take their defaults
		if type(db.borderScale) == 'number' then db.borderScale = math.max(0.7, math.min(1, db.borderScale)) end
	end,
	[8] = function(db) -- 1.1.1 -> 1.2.0: the old default BANZAI (circles) becomes the new default SQUARE; ELVUI is kept
		if db.actionStyle == 'BANZAI' then db.actionStyle = 'SQUARE' end
	end,
	[9] = function(db) -- display-font selection lock: a retired bake-off face becomes the semantic default
		if db.displayFace == 'WANTBANZAI' or db.displayFace == 'WANTCOFFEE' or db.displayFace == 'CHANG_CHANG_WOODCUT' or db.displayFace == 'ROOTS_OF_CHINA' or db.displayFace == 'ODISHI' then db.displayFace = 'BANZAI_DEFAULT' end
	end,
}

local function Copy(value)
	if type(value) ~= 'table' then return value end
	local out = {}
	for k, v in pairs(value) do out[k] = Copy(v) end
	return out
end
Theme.Copy = Copy

-- "Name - Realm", the key ElvUI and BANZAI use for a character
function Theme.CharKey()
	local E = _G.ElvUI and _G.ElvUI[1]
	local key = E and E.mynameRealm
	if type(key) == 'string' and key ~= '' then return key end
	local name = UnitName and UnitName('player')
	local realm = GetRealmName and GetRealmName()
	if type(name) == 'string' and type(realm) == 'string' then return name .. ' - ' .. realm end
	return 'UNKNOWN'
end

-- BanzaiCompatDB = { chars = { [key] = settings }, legacy = the 0.5.x account-wide settings }
function Theme:Root()
	_G.BanzaiCompatDB = _G.BanzaiCompatDB or {}
	local root = _G.BanzaiCompatDB
	if type(root.chars) ~= 'table' then
		local legacy = {}
		for k, v in pairs(root) do legacy[k] = v end
		for k in pairs(legacy) do root[k] = nil end
		root.chars = {}
		if next(legacy) then root.legacy = legacy end
	end
	return root
end

function Theme:DB(key)
	local root = self:Root()
	key = key or self.CharKey()
	local db = root.chars[key]
	if not db then
		db = Copy(root.legacy or {})
		root.chars[key] = db
	end
	if (db.schema or 0) < self.SCHEMA then
		for step = (db.schema or 0) + 1, self.SCHEMA do
			if MIGRATIONS[step] then MIGRATIONS[step](db) end
		end
		db.schema = self.SCHEMA
	end
	for key, value in pairs(self.DEFAULTS) do
		if db[key] == nil then db[key] = value end
	end
	if db.theme ~= 'VIBRANT' and db.theme ~= 'CLASS' then db.theme = 'VIBRANT' end
	if db.panelBorder ~= 'CLASS' and db.panelBorder ~= 'BANZAI' and db.panelBorder ~= 'HARDKORH' then db.panelBorder = 'BANZAI' end
	if db.panelBackground ~= 'SOLID' and db.panelBackground ~= 'GLASS' and db.panelBackground ~= 'PARCHMENT' then db.panelBackground = 'GLASS' end
	-- a value out of range (a master captured before 1.1.0, Character Sync's import) is brought back in
	if type(db.borderScale) ~= 'number' then db.borderScale = 1 end
	db.borderScale = math.max(self.BORDER_SCALE.min, math.min(self.BORDER_SCALE.max, db.borderScale))
	-- 1.2.0: a master captured before 1.2.0 hands on BANZAI (circles at the time): the new default, as the migration does
	if db.actionStyle ~= 'SQUARE' and db.actionStyle ~= 'CIRCLE' and db.actionStyle ~= 'ELVUI' then db.actionStyle = 'SQUARE' end
	if db.buffsRows ~= 2 and db.buffsRows ~= 3 then db.buffsRows = 2 end
	local B = self.BUFFS_POSITION
	db.buffsX = math.floor(math.max(B.min, math.min(B.maxX, tonumber(db.buffsX) or 30)) + 0.5)
	db.buffsY = math.floor(math.max(B.min, math.min(B.maxY, tonumber(db.buffsY) or 30)) + 0.5)
	-- 1.3.0: an unknown style is the approved one (never SPLIT / COMPACT by accident)
	if db.frameStyle ~= 'CLASSIC' and db.frameStyle ~= 'SPLIT' then db.frameStyle = 'CLASSIC' end
	if db.detailsStyle ~= 'CURRENT' and db.detailsStyle ~= 'COMPACT' then db.detailsStyle = 'CURRENT' end
	if not self.DISPLAY_FACE_SET[db.displayFace] then db.displayFace = 'BANZAI_DEFAULT' end
	if db.identityArt ~= 'AUTO' and db.identityArt ~= 'BANZAI' and db.identityArt ~= 'FABLED' and db.identityArt ~= 'CLASS' then db.identityArt = 'AUTO' end -- 1.3.2
	for _, key in ipairs({ 'splitCastBar', 'splitCastName', 'splitCastTimer' }) do -- 1.3.3: on unless plainly off
		if type(db[key]) ~= 'boolean' then db[key] = true end
	end
	for key, range in pairs(self.SPLIT_LIMITS) do
		db[key] = math.max(range[1], math.min(range[2], tonumber(db[key]) or range[3]))
	end
	return db
end

-- Character Sync: the synced part of a character's settings (every DEFAULTS key
-- plus the per-role frame positions) as a plain copy, and writing one back
function Theme:Export(key)
	local db = self:DB(key)
	local out = {}
	for k in pairs(self.DEFAULTS) do out[k] = Copy(db[k]) end
	out.roles = Copy(db.roles)
	return out
end

function Theme:Import(values, key)
	local db = self:DB(key)
	for k in pairs(self.DEFAULTS) do
		if values[k] ~= nil then db[k] = Copy(values[k]) end
	end
	db.roles = Copy(values.roles)
	return db
end

local function Mix(a, b, t)
	return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end
Theme.Mix = Mix

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

-- screen pixels per UI unit of a region (0.7.0: circles are drawn one texel per pixel)
function Theme.PixelScale(region)
	if not GetPhysicalScreenSize then return 1 end
	local _, height = GetPhysicalScreenSize()
	local scale = region and region.GetEffectiveScale and region:GetEffectiveScale() or 1
	if type(height) ~= 'number' or IsSecret(height) or height <= 0 or type(scale) ~= 'number' or IsSecret(scale) then return 1 end
	return scale * height / 768
end

function Theme:ClassColor(token)
	if type(token) ~= 'string' or IsSecret(token) then return { 1, 1, 1 } end
	local color = C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(token)
	if not color and RAID_CLASS_COLORS then color = RAID_CLASS_COLORS[token] end
	if color and color.r then return { color.r, color.g, color.b } end
	local fallback = ns.Geometry and ns.Geometry.classColors and ns.Geometry.classColors[token]
	return fallback and { fallback[1], fallback[2], fallback[3] } or { 1, 1, 1 }
end

function Theme:PlayerClassColor()
	local _, token = UnitClass('player')
	return self:ClassColor(token)
end

local function Reverse(stops)
	local out = {}
	for i = #stops, 1, -1 do out[#out + 1] = { 1 - stops[i][1], stops[i][2] } end
	return out
end

-- Named ramps: 'h' (frames, edges), 'details' (Details frame), 'stalk', 'tie'
function Theme:Stops(kind)
	local db = self:DB()
	if db.theme == 'CLASS' then
		local base = self:PlayerClassColor()
		local bright = Mix(base, { 1, 1, 1 }, 0.42)
		local deep = Mix({ 0, 0, 0 }, base, 0.5)
		if kind == 'stalk' then return { { 0, deep }, { 0.5, base }, { 1, bright } } end
		if kind == 'tie' then return { { 0, Mix({ 0, 0, 0 }, base, 0.35) }, { 1, deep } } end
		if kind == 'details' then return { { 0, deep }, { 0.4, base }, { 1, bright } } end
		local h = { { 0, bright }, { 0.45, base }, { 0.75, Mix({ 0, 0, 0 }, base, 0.78) }, { 1, deep } }
		return db.gradient == 'REVERSE' and Reverse(h) or h
	end
	if kind == 'stalk' then return VIBRANT_STALK end
	if kind == 'tie' then return VIBRANT_TIE end
	if kind == 'details' then return VIBRANT_DETAILS end
	return db.gradient == 'REVERSE' and Reverse(VIBRANT_H) or VIBRANT_H
end

-- 1.1.0 panel bamboo: the colour of a stalk ('top' / 'bottom' / 'left' /
-- 'right') at `field` (0..1, the panel's own gradient direction), p 0..1
-- along the stalk, `vary` 0..1 a fixed per-segment number (the natural
-- variation of BANZAI). The frame intensity applies.
function Theme:PanelStalk(stalk, field, p, vary)
	local db = self:DB()
	local mode = db.panelBorder
	local c
	if mode == 'CLASS' then
		local base = self:PlayerClassColor()
		c = self:ColorAt({ { 0, Mix(base, { 1, 1, 1 }, 0.38) }, { 0.5, base }, { 1, Mix({ 0, 0, 0 }, base, 0.52) } }, field, true)
	elseif mode == 'HARDKORH' then
		c = self:ColorAt(HARDKORH_STALK, field, true)
	else
		local base = BANZAI_STALKS[stalk] or BANZAI_STALKS.top
		local drift = 0.92 + 0.10 * (p or 0) + 0.05 * ((vary or 0.5) - 0.5)
		c = { math.min(1, base[1] * drift), math.min(1, base[2] * drift), math.min(1, base[3] * drift) }
	end
	local k = db.intensity or 1
	return { c[1] * k, c[2] * k, c[3] * k }
end

-- the rope at height p (0 top .. 1 bottom of the tie): its own material in every style
function Theme:PanelRope(p)
	local stops = (self:DB().panelBorder == 'CLASS') and HEMP_ROPE or VIBRANT_TIE
	return self:ColorAt(stops, p, true)
end


function Theme:ColorAt(stops, p, raw)
	p = math.max(0, math.min(1, p))
	local c = stops[#stops][2]
	for i = 2, #stops do
		if p <= stops[i][1] then
			local p0, a = stops[i - 1][1], stops[i - 1][2]
			local p1, b = stops[i][1], stops[i][2]
			c = Mix(a, b, (p1 > p0) and (p - p0) / (p1 - p0) or 0)
			break
		end
	end
	local k = raw and 1 or (self:DB().intensity or 1)
	return { c[1] * k, c[2] * k, c[3] * k }
end

function Theme:Hex(c)
	return string.format('%02x%02x%02x', math.floor(c[1] * 255 + 0.5), math.floor(c[2] * 255 + 0.5), math.floor(c[3] * 255 + 0.5))
end

-- per-character colour gradient for short labels (ASCII / UTF-8 safe)
function Theme:GradientText(text, from, to)
	local chars = {}
	for ch in string.gmatch(text, '[%z\1-\127\194-\244][\128-\191]*') do chars[#chars + 1] = ch end
	local n = #chars
	if n == 0 then return '' end
	local out = {}
	for i, ch in ipairs(chars) do
		local c = Mix(from, to, (n > 1) and (i - 1) / (n - 1) or 0)
		out[#out + 1] = '|cff' .. self:Hex(c) .. ch
	end
	return table.concat(out) .. '|r'
end

-- Two-stop gradient with alpha carried in the colours.
function Theme:Gradient(texture, orientation, from, to, alphaFrom, alphaTo)
	local a1 = alphaFrom or from[4] or 1
	local a2 = alphaTo or to[4] or a1
	if texture.SetGradient and CreateColor then
		texture:SetGradient(orientation, CreateColor(from[1], from[2], from[3], a1), CreateColor(to[1], to[2], to[3], a2))
	else
		texture:SetVertexColor(from[1], from[2], from[3], a1)
	end
end

-- Banzai accents used in text (spec, bottom bar, tracker, options page)
function Theme:Accents()
	if self:DB().theme == 'CLASS' then
		local base = self:PlayerClassColor()
		return Mix(base, { 1, 1, 1 }, 0.35), base
	end
	return COLORS.lime, COLORS.emerald
end

-- 1.3.1 the BANZAI name lines: green -> emerald -> violet -> purple
Theme.NAME_STOPS = { COLORS.lime, COLORS.emerald, COLORS.violet, COLORS.purple }

-- 1.3.1 a per-letter gradient through several colours (ASCII / UTF-8 safe)
function Theme:RampText(text, colors)
	local chars = {}
	for ch in string.gmatch(text, '[%z\1-\127\194-\244][\128-\191]*') do chars[#chars + 1] = ch end
	local n = #chars
	if n == 0 then return '' end
	local stops = {}
	for i, c in ipairs(colors) do stops[i] = { (#colors > 1) and (i - 1) / (#colors - 1) or 0, c } end
	local out = {}
	for i, ch in ipairs(chars) do
		out[#out + 1] = '|cff' .. self:Hex(self:ColorAt(stops, (n > 1) and (i - 1) / (n - 1) or 0, true)) .. ch
	end
	return table.concat(out) .. '|r'
end

-- 1.3.1 BANZAI SPLIT: one colour family across a whole split frame (the health
-- bar, the hub, the resource bar) - a lighter tone, the canonical colour, a
-- deeper tone. The light end leans a little toward yellow (the brightest hue),
-- the deep end away from it, so the family reads as one colour: Monk jade ->
-- turquoise, Mage cyan -> blue, Druid amber -> orange, Rogue yellow -> gold,
-- Death Knight red -> burgundy, Paladin rose -> pink. Saturation is kept;
-- neither end is white or black. A grey colour (Priest's white) goes white ->
-- silver -> a deeper cool silver, so its bars never read as one flat white.
Theme.RAMP = { shift = 10, light = 0.14, saturation = 0.9, deep = 0.56 }

local function ToHSV(c)
	local r, g, b = c[1], c[2], c[3]
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local d = max - min
	local h = 0
	if d > 0 then
		if max == r then h = 60 * (((g - b) / d) % 6)
		elseif max == g then h = 60 * ((b - r) / d + 2)
		else h = 60 * ((r - g) / d + 4) end
	end
	return h, (max > 0) and d / max or 0, max
end

local function FromHSV(h, s, v)
	h = h % 360
	local c = v * s
	local x = c * (1 - math.abs((h / 60) % 2 - 1))
	local m = v - c
	local r, g, b
	if h < 60 then r, g, b = c, x, 0
	elseif h < 120 then r, g, b = x, c, 0
	elseif h < 180 then r, g, b = 0, c, x
	elseif h < 240 then r, g, b = 0, x, c
	elseif h < 300 then r, g, b = x, 0, c
	else r, g, b = c, 0, x end
	return { r + m, g + m, b + m }
end

function Theme.Ramp(c)
	local R = Theme.RAMP
	local base = { c[1], c[2], c[3] }
	local h, s, v = ToHSV(base)
	if s < 0.08 then
		return { bright = { v, v, v }, base = { v * 0.80, v * 0.83, v * 0.88 }, deep = { v * 0.50, v * 0.53, v * 0.60 } }
	end
	local towardYellow = ((60 - h + 540) % 360) - 180 -- signed, the shorter way round
	local dir = (towardYellow >= 0) and 1 or -1
	local bright = FromHSV(h + dir * math.min(R.shift, math.abs(towardYellow)), s * R.saturation, math.min(1, v * 1.12))
	return { bright = Mix(bright, { 1, 1, 1 }, R.light), base = base, deep = FromHSV(h - dir * R.shift, math.min(1, s * 1.04), v * R.deep) }
end

-- the family as letters (the BANZAI SPLIT spec line): light -> canonical -> a little deeper, never so
-- dark that the outline swallows it
function Theme.RampLetters(ramp)
	return { ramp.bright, ramp.base, Mix(ramp.base, ramp.deep, 0.35) }
end

-- dark green glass: vertical gradient, alpha in the colours
function Theme:Glass(texture, alpha)
	local a = alpha or self:DB().glassOpacity or 0.72
	local g = COLORS.glass
	texture:SetTexture(self.WHITE)
	self:Gradient(texture, 'VERTICAL', { g[1] * 0.8, g[2] * 0.8, g[3] * 0.8 }, { g[1] * 1.25, g[2] * 1.25, g[3] * 1.25 }, math.min(1, a + 0.06), a)
end

-- 1.1.0 SOLID: the same very dark green-black, nearly opaque
Theme.SOLID_ALPHA = 0.97
function Theme:Solid(texture)
	self:Glass(texture, self.SOLID_ALPHA)
end

-- empty part of a health bar: one smooth dark surface (0.5.0, no slots)
function Theme:Trough(texture)
	texture:SetTexture(self.WHITE)
	self:Gradient(texture, 'VERTICAL', { 0.010, 0.026, 0.020 }, { 0.045, 0.080, 0.064 }, 0.94, 0.94)
end

-- readable small-text font (BANZAI options) and the display font
function Theme:SmallFont()
	local media = _G.LibStub and _G.LibStub('LibSharedMedia-3.0', true)
	local db = _G.BushidoPrivateRestoreDB
	local name = (db and db.fonts and db.fonts.small) or 'Rubik-Bold'
	return (media and (media:Fetch('font', name, true) or media:Fetch('font', 'Expressway', true))) or 'Fonts\\FRIZQT__.TTF'
end

-- the display font before 1.3.1 (the profile's, GasoekOne): kept where the look
-- is frozen - the targeted nameplate, the PvP labels, the identity glyphs, the
-- secondary frames' numbers
function Theme:PreviousDisplayFont()
	local media = _G.LibStub and _G.LibStub('LibSharedMedia-3.0', true)
	local db = _G.BushidoPrivateRestoreDB
	local name = (db and db.fonts and db.fonts.display) or 'GasoekOne'
	return (media and (media:Fetch('font', name, true) or media:Fetch('font', 'Expressway', true))) or 'Fonts\\FRIZQT__.TTF'
end

-- 1.3.1 a Banzai display size at the character's display scale (whole units)
function Theme:DisplaySize(size)
	local db = self:DB()
	local scale = tonumber(db.displayScale) or 1
	if (db.displayFace == 'BANZAI_DEFAULT' or (db.displayFace == 'AUTO' and self:SelectedDisplayFace() == self.BANZAI_DEFAULT_FONT))
		and self:SelectedDisplayFace() == self.BANZAI_DEFAULT_FONT then
		scale = scale * self.BANZAI_DEFAULT_SCALE
	end
	return math.floor(size * scale + 0.5)
end

-- The Banzai nameplate / bar texture, available to ElvUI before it builds nameplates.
do
	local media = _G.LibStub and _G.LibStub('LibSharedMedia-3.0', true)
	if media and media.Register then
		media:Register('statusbar', 'Banzai', Theme.MEDIA .. 'BanzaiBar.tga')
		Theme.statusbarRegistered = true
	end
end
