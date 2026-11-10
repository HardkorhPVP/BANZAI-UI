--[[
	BANZAI - Identity.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	0.7.0: a small circular identity anchor on the secondary unit frames - Focus,
	Party (Arena allies are the party frames in an arena), Arena enemies and Boss
	frames that hold a player - in place of mMediaTag's large portraits there
	(switched off by BushidoPrivateRestore while this is on). Player and Target
	keep their large Fabled Class anchors.

	  icon     the Jiberish "Fabled Specializations" icon when the unit's
	           specialization is reliably known, else its "Fabled Class" icon
	           (Jiberish Icons' own API and artwork; without Jiberish Icons the
	           game's class icon). A spec is never guessed:
	             the player      the client's own specialization
	             arena enemies   the game's arena data (GetArenaOpponentSpec);
	                             12.1.5 keeps it secret, so they normally show
	                             their class icon; during arena preparation the
	                             circle appears as soon as the game names a spec
	             other players   Jiberish Icons' lookup (the game's inspect data,
	                             ElvUI's tooltip spec, group data)
	           NPCs (most focus targets, bosses) get no circle at all; a class
	           the game keeps secret gets none either.
	  look     a dark disc, the icon inside a circular mask, a thin ring in the
	           unit's class colour; disc, mask and ring are drawn for the screen
	           pixels they cover (a 36 px circle on a 64 px canvas, like the
	           action buttons), the Jiberish sheets filtered trilinearly
	  place    outside the frame's end, vertically centred on the health bar:
	           left of Focus and Party (where mMediaTag's portraits were), left
	           of Boss; 0.9.0: right of Arena enemies, mirroring the allies
	           (their trinket circle sits on the left, PvPFrames.lua)

	Textures only: nothing secure is created, nothing is hooked; the circles are
	refreshed on the game's own events and on a slow timer while shown.

	1.3.0 (BANZAI SPLIT, Split.lua; BANZAI CLASSIC keeps everything above):
	  art      one identity-art chain for the split hubs and the split party
	           circles (the COMPACT Details rows follow the same order):
	             1 BANZAI   Darren's original class icon, once the build has
	                        validated it (assets/identity -> media/BanzaiIdentity,
	                        IdentityManifest.lua)
	             2 FABLED   Jiberish Icons' Fabled spec icon (spec reliably known)
	                        or Fabled class icon - an external, temporary
	                        fallback, referenced in place, never copied
	             3 GLYPH    a class-colour disc with the class's two letters
	             4 UNKNOWN  a neutral disc with '?'
	           A missing or rejected file never reaches the game: only the
	           manifest is read, so nothing can error or stay blank.
	  hub      the central circle of the split frames: dark disc, the icon (or
	           an NPC's portrait) in a circular mask, the class ring, a thin
	           green -> purple accent and, for Split.lua's cast presentation, the
	           spell icon, the radial progress (a Cooldown swipe on the ring), a
	           non-interruptible ring and the spell name / time above it
	  party    in a split session the party circles sit in the middle of the bar
	           (the split construction) and use the chain; Focus has a hub

	1.3.1: the hub's cast texts have a font from the moment they exist (the
	1.3.0 runtime fault, see Identity.Hub); the chain and its fallbacks are
	unchanged.

	1.3.2: Darren's 13 original class identities are in the manifest, so BANZAI
	is the first level for real. Where it is used is decided here, in one place:
	  size     the full art reads down to about 30 screen px (the QA sheets:
	           readable at 32, muddy at 24), so a circle / hub whose icon is
	           smaller than Identity.BANZAI_MIN takes the next level (Fabled)
	  plates   the enhanced nameplate's hub keeps its 1.3.1 art (nameplates are
	           frozen); the BANZAI COMPACT Details rows keep theirs (too small)
	  setting  IDENTITY ART (identityArt): AUTO - BANZAI for the split frames,
	           the classic circles as they were; BANZAI - also the classic
	           circles; FABLED - Fabled first everywhere; CLASS - the class-colour
	           discs. A missing or rejected file falls back for its class only
	           (the manifest lists only what the build validated).

	1.3.3: the BANZAI SPLIT Player / Target hubs are bar hubs (Identity.Hub with
	`bar`): no radial progress, no swipe track, no lock ring, no game shield -
	their cast progress, spell name, timer and steel marking are the bamboo cast
	bar's (CastBar.lua). In them Darren's BANZAI art is drawn at full size with
	its own transparency (Identity.FitArt): its bamboo ring is the hub's ring and
	the class ring steps aside while the hub is idle (Identity.BarRing; back round
	the spell icon during a cast). Focus, the party circles and the enhanced
	nameplate hub are as in 1.3.2.
]]
local _, ns = ...
local Theme = ns.Theme

local Identity = {}
ns.Identity = Identity

local DISC = Theme.MEDIA .. 'BanzaiIdentityMask'
local RING = Theme.MEDIA .. 'BanzaiIdentityRing'
local CLASS_SHEET = 'Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES'
Identity.SIZE = 27            -- UI units: 36 screen px at Darren's setup (Player / Target anchors are 105)
Identity.CANVAS = 64 / 36     -- canvas : circle of the identity textures (tools/lib/bamboo.js)
Identity.ICON = 0.86          -- icon disc, of the circle
Identity.GAP = 4              -- from the frame's end
Identity.SPEC_STYLE = 'fabledspecializations'
Identity.CLASS_STYLE = 'fabledclass'
-- frames and their side (the circle sits outside this end of the frame)
Identity.FRAMES = {
	{ frame = 'ElvUF_Focus', unit = 'focus', side = 'LEFT' },
	{ prefix = 'ElvUF_PartyGroup1UnitButton', count = 5, side = 'LEFT' },
	{ prefix = 'ElvUF_Arena', count = 5, unit = 'arena', side = 'RIGHT', arena = true }, -- 0.9.0: mirrored
	{ prefix = 'ElvUF_Boss', count = 8, unit = 'boss', side = 'LEFT' },
}

local built = {} -- [unit frame] = circle

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Plain(value)
	if IsSecret(value) then return nil end
	return value
end

local function Call(fn, ...)
	if not fn then return nil end
	local ok, a, b, c = pcall(fn, ...)
	if not ok then return nil end
	return Plain(a), Plain(b), Plain(c)
end

-- Jiberish Icons (JiberishIcons[1]), when loaded
local function Jiberish()
	local addon = _G.JiberishIcons
	local JI = type(addon) == 'table' and addon[1]
	return (type(JI) == 'table' and JI.GetIdentityIcon) and JI or nil
end
Identity.Jiberish = Jiberish

-- the icon of a class / spec: texture path and tex coords (4 or 8 values), and
-- whether it is the spec icon. specID must come from a reliable source.
function Identity.Icon(classToken, specID)
	if type(classToken) ~= 'string' then return nil end
	local JI = Jiberish()
	if JI then
		if type(specID) == 'number' then
			local ok, icon, path = pcall(JI.GetIdentityIcon, JI, classToken, nil, Identity.SPEC_STYLE, specID)
			if ok and type(icon) == 'table' and icon.texCoords and path then return path, icon.texCoords, true end
		end
		local ok, icon, path = pcall(JI.GetIdentityIcon, JI, classToken, nil, Identity.CLASS_STYLE)
		if ok and type(icon) == 'table' and icon.texCoords and path then return path, icon.texCoords, false end
	end
	local coords = _G.CLASS_ICON_TCOORDS and _G.CLASS_ICON_TCOORDS[classToken]
	if coords then return CLASS_SHEET, coords, false end
	return nil
end

-- the specialization of a unit, only from a reliable source (nil when unknown)
function Identity.SpecOf(unit, arenaIndex)
	if type(unit) ~= 'string' then return nil end
	if unit == 'player' or Call(UnitIsUnit, unit, 'player') == true then
		local index = Call(GetSpecialization)
		if type(index) == 'number' and index > 0 then
			local id = Call(GetSpecializationInfo, index)
			if type(id) == 'number' and id > 0 then return id end
		end
		return nil
	end
	if arenaIndex and GetArenaOpponentSpec then
		local id = Call(GetArenaOpponentSpec, arenaIndex)
		if type(id) == 'number' and id > 0 then return id end
	end
	local JI = Jiberish()
	if JI and JI.GetUnitSpecialization then
		local id = Call(JI.GetUnitSpecialization, JI, unit)
		if type(id) == 'number' and id > 0 then return id end
	end
	return nil
end

local function Snap(texture)
	if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(true) end
	if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
end

-- a circle on `parent` (also used by the unit-frame preview)
function Identity.Circle(parent, size)
	size = size or Identity.SIZE
	local c = CreateFrame('Frame', nil, parent)
	c:SetSize(size, size)
	c:EnableMouse(false)
	local canvas = size * Identity.CANVAS
	c.disc = c:CreateTexture(nil, 'BACKGROUND')
	c.disc:SetTexture(DISC, 'CLAMP', 'CLAMP', 'TRILINEAR')
	c.mask = c:CreateMaskTexture()
	c.mask:SetTexture(DISC, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE', 'TRILINEAR')
	c.icon = c:CreateTexture(nil, 'ARTWORK')
	c.icon:SetPoint('CENTER', c, 'CENTER', 0, 0)
	c.icon:SetSize(size * Identity.ICON, size * Identity.ICON)
	c.icon:AddMaskTexture(c.mask)
	c.ring = c:CreateTexture(nil, 'OVERLAY')
	c.ring:SetTexture(RING, 'CLAMP', 'CLAMP', 'TRILINEAR')
	for _, t in ipairs({ c.disc, c.mask, c.ring }) do
		t:SetPoint('CENTER', c, 'CENTER', 0, 0)
		t:SetSize(canvas, canvas)
		Snap(t)
	end
	Theme:Gradient(c.disc, 'VERTICAL', { 0.01, 0.03, 0.02 }, { 0.03, 0.07, 0.05 }, 0.92, 0.92)
	c.iconSize = size * Identity.ICON -- 1.3.2: the art chain sizes its choice by it
	return c
end

-- show a class (and spec) on a circle; false when there is nothing to show
function Identity.Paint(c, classToken, specID)
	local path, coords, isSpec = Identity.Icon(classToken, specID)
	if not path then
		c:Hide()
		return false
	end
	if c.glyph then c.glyph:Hide() c.glyphDisc:Hide() end -- 1.3.2: after a class-colour disc (IDENTITY ART)
	c.icon:SetTexture(path, 'CLAMP', 'CLAMP', 'TRILINEAR')
	c.icon:SetTexCoord(unpack(coords))
	local color = Theme:ClassColor(classToken)
	Theme:Gradient(c.ring, 'VERTICAL', { color[1] * 0.7, color[2] * 0.7, color[3] * 0.7 }, Theme.Mix(color, { 1, 1, 1 }, 0.3), 1, 1)
	Snap(c.ring)
	c.class, c.spec, c.isSpec = classToken, specID, isSpec
	c:Show()
	return true
end

---------------------------------------------------------------------------
-- 1.3.0 the identity-art chain and the central hub (BANZAI SPLIT)
---------------------------------------------------------------------------
Identity.BANZAI_DIR = Theme.MEDIA .. 'BanzaiIdentity\\'
Identity.GLYPHS = { DEATHKNIGHT = 'DK', DEMONHUNTER = 'DH', DRUID = 'DR', EVOKER = 'EV', HUNTER = 'HU', MAGE = 'MA', MONK = 'MO',
	PALADIN = 'PA', PRIEST = 'PR', ROGUE = 'RO', SHAMAN = 'SH', WARLOCK = 'WL', WARRIOR = 'WA' }
Identity.UNKNOWN = { 0.42, 0.45, 0.50 }
Identity.ART_ORDER = { 'BANZAI', 'FABLED', 'GLYPH', 'UNKNOWN' }
-- the hub textures: a 128 px canvas around a circle of 120 px (tools/lib/hub.js)
-- art (1.3.3, a bar hub's BANZAI art): its ring (492.4 / 512 of the master's radius) at 0.94 of the hub's, where the class ring ends
Identity.HUB = { canvas = 128 / 120, icon = 0.80, halo = 1.07, art = 0.98 } -- icon: the mask's disc (tools/lib/hub.js HUB.mask); halo: the lock border's outer band
Identity.SHIELD = 'Interface\\CastingBar\\UI-CastingBar-Small-Shield' -- the game's own cast-bar shield (referenced in place)
local HUB_DISC, HUB_RING, HUB_ACCENT, HUB_MASK, HUB_SWIPE = Theme.MEDIA .. 'BanzaiHubDisc', Theme.MEDIA .. 'BanzaiHubRing', Theme.MEDIA .. 'BanzaiHubAccent', Theme.MEDIA .. 'BanzaiHubMask', Theme.MEDIA .. 'BanzaiHubSwipe'
Identity.HUB_SWIPE = HUB_SWIPE

-- 1.3.2 where the full BANZAI art is used: icons of at least this many UI units (about 30 px at
-- Darren's scale - the Player / Target / Focus hubs and the split party circles; never the
-- nameplate hub or a Details row), the IDENTITY ART choice
Identity.BANZAI_MIN = 22
Identity.ART_MODES = { AUTO = true, BANZAI = true, FABLED = true, CLASS = true }

function Identity.ArtMode()
	local mode = Theme:DB().identityArt
	return Identity.ART_MODES[mode] and mode or 'AUTO'
end

-- the BANZAI file of a class, only when the build validated it (the manifest), else nil
function Identity.BanzaiFile(classToken)
	local manifest = ns.IdentityManifest
	local file = type(manifest) == 'table' and type(manifest.classes) == 'table' and manifest.classes[classToken]
	if type(file) == 'string' and string.match(file, '^%l+$') then return file end
	return nil
end

-- how many classes have their BANZAI art (/banzai status)
if ns.Compat then
	function ns.Compat:IdentityArtCount()
		local manifest, n = ns.IdentityManifest, 0
		if type(manifest) == 'table' and type(manifest.classes) == 'table' then
			for token in pairs(manifest.classes) do if Identity.BanzaiFile(token) then n = n + 1 end end
		end
		return n
	end
end

-- the full art suits this circle / hub (nil: the caller gives no size - a sample at full size)
function Identity.BanzaiFits(where)
	if type(where) ~= 'table' then return true end
	if where.plate or where.noBanzai then return false end
	local size = tonumber(where.iconSize)
	return size == nil or size >= Identity.BANZAI_MIN
end

-- the art for a class (and a reliably known spec), in Darren's order; 1.3.2: `where` is the
-- circle / hub it is for (its icon size, a nameplate hub)
function Identity.Art(classToken, specID, where)
	if type(classToken) ~= 'string' or IsSecret(classToken) or not Identity.GLYPHS[classToken] then
		return { kind = 'UNKNOWN', glyph = '?', color = Identity.UNKNOWN }
	end
	local color = Theme:ClassColor(classToken)
	local mode = Identity.ArtMode()
	if mode == 'CLASS' then return { kind = 'GLYPH', glyph = Identity.GLYPHS[classToken], color = color } end
	local file = mode ~= 'FABLED' and Identity.BanzaiFits(where) and Identity.BanzaiFile(classToken)
	if file then
		return { kind = 'BANZAI', path = Identity.BANZAI_DIR .. file, coords = { 0, 1, 0, 1 }, color = color, class = classToken, spec = specID }
	end
	local JI = Jiberish()
	if JI then
		if type(specID) == 'number' and not IsSecret(specID) then
			local ok, icon, path = pcall(JI.GetIdentityIcon, JI, classToken, nil, Identity.SPEC_STYLE, specID)
			if ok and type(icon) == 'table' and icon.texCoords and path then return { kind = 'FABLED', path = path, coords = icon.texCoords, color = color, spec = true } end
		end
		local ok, icon, path = pcall(JI.GetIdentityIcon, JI, classToken, nil, Identity.CLASS_STYLE)
		if ok and type(icon) == 'table' and icon.texCoords and path then return { kind = 'FABLED', path = path, coords = icon.texCoords, color = color } end
	end
	return { kind = 'GLYPH', glyph = Identity.GLYPHS[classToken], color = color }
end

-- the glyph parts of a circle / hub (made the first time a glyph is shown)
local function GlyphParts(c, size)
	if c.glyph then return end
	c.glyphDisc = c:CreateTexture(nil, 'ARTWORK', nil, 0)
	c.glyphDisc:SetTexture(Theme.WHITE)
	c.glyphDisc:SetPoint('CENTER', c, 'CENTER', 0, 0)
	c.glyphDisc:SetSize(size, size)
	c.glyphDisc:AddMaskTexture(c.mask)
	c.glyph = c:CreateFontString(nil, 'OVERLAY')
	c.glyph:SetPoint('CENTER', c, 'CENTER', 0, 0)
	c.glyphSize = size
end

-- paints the chain's art on a circle (Identity.Circle) or a hub (Identity.Hub)
function Identity.PaintArt(c, art)
	art = art or Identity.Art(nil)
	local color = art.color or Identity.UNKNOWN
	if art.path then
		-- 1.3.2: a BANZAI file the client refuses falls back for that class only
		if c.icon:SetTexture(art.path, 'CLAMP', 'CLAMP', 'TRILINEAR') == false and art.kind == 'BANZAI' then
			return Identity.PaintArt(c, Identity.Art(art.class, art.spec, { noBanzai = true }))
		end
		c.icon:SetTexCoord(unpack(art.coords or { 0, 1, 0, 1 }))
		c.icon:Show()
		if c.glyph then c.glyph:Hide() c.glyphDisc:Hide() end
	else
		c.icon:Hide()
		GlyphParts(c, c.iconSize or c:GetWidth())
		Theme:Gradient(c.glyphDisc, 'VERTICAL', Theme.Mix({ 0, 0, 0 }, color, 0.55), Theme.Mix(color, { 1, 1, 1 }, 0.18), 1, 1)
		c.glyph:SetFont(Theme:PreviousDisplayFont(), math.max(7, math.floor((c.glyphSize or 20) * 0.42 + 0.5)), 'OUTLINE') -- 1.3.1: the fallback art as it was
		c.glyph:SetShadowOffset(1, -1)
		c.glyph:SetText(art.glyph or '?')
		c.glyph:SetTextColor(1, 1, 1, art.kind == 'UNKNOWN' and 0.7 or 1)
		c.glyphDisc:Show()
		c.glyph:Show()
	end
	if c.portrait then c.portrait:Hide() end
	Theme:Gradient(c.ring, 'VERTICAL', { color[1] * 0.62, color[2] * 0.62, color[3] * 0.62 }, Theme.Mix(color, { 1, 1, 1 }, 0.3), 1, 1)
	c.artKind, c.ringColor = art.kind, color
	Identity.FitArt(c, art.kind == 'BANZAI') -- 1.3.3: a bar hub - the BANZAI art at full size, its own ring
	Identity.BarRing(c)
	c:Show()
	return art.kind
end

-- the central hub of a split frame: disc, icon / portrait / glyph, ring and accent,
-- and the parts of the cast presentation (Split.lua drives them). 1.3.3: `bar` - a hub whose cast
-- progress is the BANZAI SPLIT bamboo cast bar (Player / Target, CastBar.lua): it has no radial
-- progress, no dark track, no lock ring and no game shield texture (only Banzai media and the
-- spell icon the game hands over while a cast shows); Focus and the targeted nameplate keep theirs
function Identity.Hub(parent, size, bar)
	local h = CreateFrame('Frame', nil, parent)
	h:SetSize(size, size)
	h:EnableMouse(false)
	local canvas = size * Identity.HUB.canvas
	h.disc = h:CreateTexture(nil, 'BACKGROUND')
	h.disc:SetTexture(HUB_DISC, 'CLAMP', 'CLAMP', 'TRILINEAR')
	h.mask = h:CreateMaskTexture()
	h.mask:SetTexture(HUB_MASK, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE', 'TRILINEAR')
	h.iconSize = size * Identity.HUB.icon
	h.icon = h:CreateTexture(nil, 'ARTWORK', nil, 1)
	h.portrait = h:CreateTexture(nil, 'ARTWORK', nil, 2)
	h.spell = h:CreateTexture(nil, 'ARTWORK', nil, 3)
	h.spell:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	for _, t in ipairs({ h.icon, h.portrait, h.spell }) do
		t:SetPoint('CENTER', h, 'CENTER', 0, 0)
		t:SetSize(h.iconSize, h.iconSize)
		t:AddMaskTexture(h.mask)
	end
	h.portrait:Hide()
	h.spell:Hide()
	h.ring = h:CreateTexture(nil, 'OVERLAY', nil, 1)
	h.ring:SetTexture(HUB_RING, 'CLAMP', 'CLAMP', 'TRILINEAR')
	h.accent = h:CreateTexture(nil, 'OVERLAY', nil, 2)
	h.accent:SetTexture(HUB_ACCENT, 'CLAMP', 'CLAMP', 'TRILINEAR')
	for _, t in ipairs({ h.disc, h.mask, h.ring, h.accent }) do
		t:SetPoint('CENTER', h, 'CENTER', 0, 0)
		t:SetSize(canvas, canvas)
		Snap(t)
	end
	Theme:Gradient(h.disc, 'VERTICAL', { 0.01, 0.03, 0.02 }, { 0.04, 0.08, 0.06 }, 0.94, 0.94)
	Theme:Gradient(h.accent, 'VERTICAL', Theme.COLORS.violet, Theme.COLORS.lime, 0.9, 0.9)
	h.size = size
	if bar then return Identity.BarHub(h) end -- 1.3.3
	h.track = h:CreateTexture(nil, 'OVERLAY', nil, 3) -- the dark track the cast progress runs on
	h.track:SetTexture(HUB_SWIPE, 'CLAMP', 'CLAMP', 'TRILINEAR')
	h.track:Hide()
	h.track:SetPoint('CENTER', h, 'CENTER', 0, 0)
	h.track:SetSize(canvas, canvas)
	Snap(h.track)
	Theme:Gradient(h.track, 'VERTICAL', { 0.03, 0.04, 0.04 }, { 0.08, 0.09, 0.09 }, 0.92, 0.92)
	-- radial progress: the game's Cooldown swipe drawn with the ring-shaped texture
	local cd = CreateFrame('Cooldown', nil, h, 'CooldownFrameTemplate')
	cd:SetPoint('CENTER', h, 'CENTER', 0, 0)
	cd:SetSize(canvas, canvas)
	if cd.SetSwipeTexture then cd:SetSwipeTexture(HUB_SWIPE) end
	if cd.SetUseCircularEdge then cd:SetUseCircularEdge(true) end
	if cd.SetDrawEdge then cd:SetDrawEdge(false) end
	if cd.SetDrawBling then cd:SetDrawBling(false) end
	if cd.SetDrawSwipe then cd:SetDrawSwipe(true) end
	if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
	cd:Hide()
	h.progress = cd
	-- above the swipe: the non-interruptible marking (a steel border round the hub, a small shield - the
	-- progress stays visible inside it) and the texts
	h.over = CreateFrame('Frame', nil, h)
	h.over:SetAllPoints(h)
	h.over:SetFrameLevel(h:GetFrameLevel() + 3)
	h.lock = h.over:CreateTexture(nil, 'OVERLAY', nil, 1)
	h.lockHalo = h.over:CreateTexture(nil, 'OVERLAY', nil, 1)
	h.shield = h.over:CreateTexture(nil, 'OVERLAY', nil, 2)
	for i, t in ipairs({ h.lock, h.lockHalo }) do
		t:SetTexture(HUB_ACCENT, 'CLAMP', 'CLAMP', 'TRILINEAR')
		t:SetPoint('CENTER', h, 'CENTER', 0, 0)
		t:SetSize(canvas * (i == 1 and 1 or Identity.HUB.halo), canvas * (i == 1 and 1 or Identity.HUB.halo))
		Snap(t)
	end
	h.shield:SetTexture(Identity.SHIELD)
	h.shield:SetSize(size * 0.42, size * 0.42)
	h.shield:SetPoint('CENTER', h, 'CENTER', size * 0.38, size * 0.36)
	h.lockParts = { h.lock, h.lockHalo, h.shield }
	for _, t in ipairs(h.lockParts) do t:Hide() end
	h.castName = h.over:CreateFontString(nil, 'OVERLAY')
	h.castName:SetPoint('BOTTOM', h, 'TOP', 0, 3)
	h.castName:SetWordWrap(false)
	h.castTime = h.over:CreateFontString(nil, 'OVERLAY')
	h.castTime:SetPoint('LEFT', h.castName, 'RIGHT', 4, 0)
	-- 1.3.1: a font from the start - the game refuses SetText on a font string without one ("Font not
	-- set"), and the first idle repaint clears these texts before any cast has set the cast fonts
	-- (in 1.3.0 that error stopped the split frames' first paint: white bars, an empty hub)
	for _, fs in ipairs({ h.castName, h.castTime }) do fs:SetFont(Theme:SmallFont(), 11, 'OUTLINE') end
	h.size = size
	return h
end

-- 1.3.3 the rest of a bar hub (Identity.Hub with `bar`): the layer above it and two spare cast texts (a font from
-- the start, hidden - the bamboo cast bar brings the shown ones); no lock parts of its own
function Identity.BarHub(h)
	h.over = CreateFrame('Frame', nil, h)
	h.over:SetAllPoints(h)
	h.over:SetFrameLevel(h:GetFrameLevel() + 3)
	h.lockParts = {}
	h.castName = h.over:CreateFontString(nil, 'OVERLAY')
	h.castTime = h.over:CreateFontString(nil, 'OVERLAY')
	for _, fs in ipairs({ h.castName, h.castTime }) do
		fs:SetFont(Theme:SmallFont(), 11, 'OUTLINE')
		fs:Hide()
	end
	h.barHub, h.artFull = true, false
	return h
end

-- 1.3.3 a bar hub shows Darren's BANZAI art at its full size (Identity.HUB.art of the hub: the art's own bamboo
-- ring lands where the class ring was, its own transparency instead of the round mask) and the class ring steps
-- aside while it is idle - the artwork's ring is the hub's ring; while a cast shows (the art veiled) the ring is
-- back round the spell icon. Any other art (Fabled, glyph, portrait, crest) keeps the masked disc in the ring.
function Identity.FitArt(c, full)
	full = full and true or false
	if not c.barHub or c.artFull == full then return end
	c.artFull = full
	local size = full and c.size * Identity.HUB.art or c.iconSize
	c.icon:SetSize(size, size)
	if full then c.icon:RemoveMaskTexture(c.mask) else c.icon:AddMaskTexture(c.mask) end
end

function Identity.BarRing(c)
	if c.barHub then c.ring:SetShown(not (c.artFull and not c.veiled)) end
end

local function Place(c, frame, side)
	local anchor = frame.Health or frame
	c:ClearAllPoints()
	if side == 'RIGHT' then
		c:SetPoint('LEFT', anchor, 'RIGHT', Identity.GAP, 0)
	else
		c:SetPoint('RIGHT', anchor, 'LEFT', -Identity.GAP, 0)
	end
end

local function UnitOf(frame, def, index)
	local unit = Plain(frame.unit)
	if type(unit) ~= 'string' and frame.GetAttribute then unit = Plain(frame:GetAttribute('unit')) end
	if type(unit) ~= 'string' and def.unit then unit = def.count and (def.unit .. index) or def.unit end
	return unit
end

-- 1.3.0: in a BANZAI SPLIT session the Focus circle gives way to its hub and
-- the party circles sit in the middle of their bar (Split.lua says which)
local function SplitRole(def)
	local split = ns.Split
	if not (split and split.Session and split:Session()) then return nil end
	if def.frame == 'ElvUF_Focus' then return 'skip' end
	if def.prefix == 'ElvUF_PartyGroup1UnitButton' and split:PartySplit() then return 'centre' end
	return nil
end

-- every secondary frame that exists gets its circle
function Identity:Build()
	for _, def in ipairs(self.FRAMES) do
		local role = SplitRole(def)
		for i = 1, (role ~= 'skip') and (def.count or 1) or 0 do
			local frame = _G[def.frame or (def.prefix .. i)]
			if frame and not built[frame] then
				local size = (role == 'centre') and ns.Split.PARTY.circle or nil
				local c = Identity.Circle(frame, size)
				c:SetFrameLevel((frame.GetFrameLevel and frame:GetFrameLevel() or 1) + 6)
				c.def, c.index, c.unitFrame = def, i, frame
				if role == 'centre' then
					c.split, c.iconSize = true, size * Identity.ICON
					c:ClearAllPoints()
					c:SetPoint('CENTER', frame.Health or frame, 'CENTER', 0, 0)
				else
					Place(c, frame, def.side)
				end
				c:Hide()
				built[frame] = c
			end
		end
	end
end

-- arena preparation: the opponent is not a unit yet, but the game may already
-- name its spec (12.1.5 keeps it secret: then there is nothing to show)
function Identity.PrepClass(index)
	if not (GetArenaOpponentSpec and GetSpecializationInfoByID) then return nil end
	local ok, specID = pcall(GetArenaOpponentSpec, index)
	specID = ok and Plain(specID) or nil
	if type(specID) ~= 'number' or specID <= 0 then return nil end
	local ok2, _, _, _, _, _, classToken = pcall(GetSpecializationInfoByID, specID)
	classToken = ok2 and Plain(classToken) or nil
	if type(classToken) ~= 'string' then return nil end
	return classToken, specID
end

function Identity:Update(c)
	local frame = c.unitFrame
	local unit = UnitOf(frame, c.def, c.index)
	local on = (c.split or Theme:DB().identityCircles ~= false) and ns.Compat and ns.Compat.Active and ns.Compat.Active() -- 1.3.0: the split party circle is part of the frame
	if not (on and unit) then
		c:Hide()
		return false
	end
	if Call(UnitExists, unit) ~= true then
		-- arena preparation frames
		local classToken, specID
		if c.def.arena and frame.IsShown and frame:IsShown() then classToken, specID = Identity.PrepClass(c.index) end
		if not classToken then
			c:Hide()
			return false
		end
		return Identity.Paint(c, classToken, specID)
	end
	-- arena frames only ever hold players (the game may keep UnitIsPlayer secret there)
	if not (c.def.arena or Call(UnitIsPlayer, unit) == true) then
		c:Hide()
		return false
	end
	local _, classToken = Call(UnitClass, unit)
	local spec = Identity.SpecOf(unit, c.def.arena and c.index or nil)
	if c.split then return Identity.PaintArt(c, Identity.Art(classToken, spec, c)) ~= nil end -- 1.3.0: the split party circle takes the art chain
	-- 1.3.2: the classic circles take it only when IDENTITY ART is chosen as BANZAI or CLASS (AUTO / FABLED:
	-- as they were); the arena enemy circles never (the PvP frames are frozen)
	local mode = Identity.ArtMode()
	if not c.def.arena and (mode == 'BANZAI' or mode == 'CLASS') then return Identity.PaintArt(c, Identity.Art(classToken, spec, c)) ~= nil end
	return Identity.Paint(c, classToken, spec)
end

function Identity:Refresh()
	if not InCombatLockdown() then self:Build() end -- new circles only out of combat (their parents are secure unit frames)
	for _, c in pairs(built) do self:Update(c) end
end

function Identity:Get(frameName)
	return built[_G[frameName]]
end

local events = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_ENTERING_WORLD', 'GROUP_ROSTER_UPDATE', 'PLAYER_FOCUS_CHANGED', 'ARENA_OPPONENT_UPDATE', 'ARENA_PREP_OPPONENT_SPECIALIZATIONS',
	'INSPECT_READY', 'PLAYER_SPECIALIZATION_CHANGED', 'INSTANCE_ENCOUNTER_ENGAGE_UNIT', 'PLAYER_REGEN_ENABLED' }) do
	pcall(events.RegisterEvent, events, event)
end
events:SetScript('OnEvent', function()
	if Identity.scheduled then return end
	Identity.scheduled = true
	C_Timer.After(0.2, function()
		Identity.scheduled = false
		Identity:Refresh()
	end)
end)
-- spec data from inspections arrives later on its own: look again now and then
if C_Timer and C_Timer.NewTicker then
	C_Timer.NewTicker(3, function() for _, c in pairs(built) do if c.unitFrame:IsShown() then Identity:Update(c) end end end)
end
