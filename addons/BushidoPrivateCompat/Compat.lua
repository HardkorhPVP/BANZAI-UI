--[[
	BANZAI - Compat.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	The Banzai art on the restored Bushido layout:

	  end art      Player / Target: an original Banzai bundle of three bamboo
	               stalks tied with a cord, in place of Bushido's spike. Own
	               alpha, no masks: the target copy is a plain mirror at full
	               colour. Stalks green, cord violet / purple. 0.7.0: Player and
	               Target only; Focus, Target of Target, Pet, Party, Raid, Arena
	               and Boss frames are clean and compact (identity circles:
	               Identity.lua).
	  health       0.5.0: Bushido's slotted health art is gone; the empty part of
	               every Banzai health bar is one smooth dark trough (the fill is
	               ElvUI's own bar with the smooth Banzai texture); 0.6.0: arena too
	  frames       1.1.0: minimap, chat and Details sit in an original bamboo
	               construction: one straight stalk along each side (nodes,
	               highlight, darker underside, a cut tip on one end and a plain
	               node end on the other), the stalks running a little past the
	               corners where they overlap and are lashed together with a rope
	               tie (its own colour in every style). The frames are square and
	               level: nothing leans, rotates or stretches (the 0.6.0
	               parallelograms and the corner bundles are gone), the content
	               stays exactly where it was. Border style CLASS / BANZAI /
	               HARDKORH and background SOLID / GLASS / PARCHMENT are chosen
	               independently (BANZAI > APPEARANCE > PANEL STYLE); the minimap
	               itself fills its frame, so it has no background of its own.
	  logo         the small BANZAI wordmark at the top centre; in combat it moves
	               between Player and Target at 1.75x with an original miniature
	               tree behind it, and comes back to the top after combat;
	               1.0.0: a left click on it opens the BANZAI settings on HOME
	  Details      0.7.0: Banzai's own titles DAMAGE (red, left in the damage half)
	               and HEALING (green, right in the healing half, clear of the
	               top-right bamboo) sit centred on the frame's top border with a
	               dark backing behind the letters, a short accent line in their
	               colour family under them; the meter rows start below that
	  Chat         0.8.0: the same title, CHAT, centred on the chat frame's top
	               border; 0.9.0: its letters run from a dark green into a dark red,
	               quieter than DAMAGE / HEALING; 1.2.0: the whole chat composition
	               flush with the left screen edge (its left stalk on the edge)
	  Buffs        1.2.0: a compact BUFFS panel at the top-left in the same panel
	               material, around ElvUI's own buff icons (2 or 3 rows of 10), the
	               BUFFS title on its BOTTOM stalk; debuffs stay separate below it

	1.0.0: Player / Target / Focus / Target-of-Target are half Bushido's width:
	plates and bamboo keep their place against the frame end they belong to
	(Compat.PlacePart), so the bamboo stays at the inner ends.

	1.3.0: in a BANZAI SPLIT session (Split.lua) Player, Target, Focus and
	Target-of-Target carry the split construction instead of Bushido's plates
	and the bamboo ends, and the combat wordmark stays the small one at the top
	(the classic combat logo sits between side-by-side frames the split style
	does not have). A BANZAI CLASSIC session is exactly as before.

	1.3.1: the CHAT / BUFFS / DAMAGE / HEALING titles and the zone name above
	the minimap are in the Banzai display font (Theme:DisplayFont)
	at the character's display size; colours, places and backings unchanged.

	The thin black rectangle ElvUI drew around the Player / Target frame is made
	transparent with ElvUI's own ForceBorderColor; end art sits above the bar.
	Bushido sizes and offsets come from Geometry.lua (generated locally, never
	committed); Bushido textures are referenced in place, Banzai art is original
	(tools/lib/bamboo.js, tools/lib/panel.js, tools/lib/bonsai.js). Static
	presentation only; shown only on the Banzai ElvUI profile. The panels are
	laid out and coloured only when settings, the theme, the class or the
	profile change: no OnUpdate, nothing per frame.
]]
local _, ns = ...
local G = ns.Geometry
local Theme = ns.Theme

local PROFILE = 'JiberishUI - Bushido Private'
local WHITE = Theme.WHITE
local BUNDLE = Theme.MEDIA .. 'BanzaiBundle'
local TIE = Theme.MEDIA .. 'BanzaiBundleTie'
local WORDMARK = Theme.MEDIA .. 'BanzaiWordmark'
local BONSAI = Theme.MEDIA .. 'BanzaiBonsai'
local STALK = Theme.MEDIA .. 'BanzaiStalk'
local STALK_END = Theme.MEDIA .. 'BanzaiStalkEnd'
local ROPE = Theme.MEDIA .. 'BanzaiRopeTie'
local SQUARE_MASK = 130937 -- ElvUI's own square minimap mask (retail file ID)
local STALK_STRIPS = 6
-- 1.3.7 HARDKORH PARCHMENT: the three textures of the one parchment material and their wrap modes (Compat.ParchmentLayout)
local PARCHMENT_TEXTURES = {
	tile = { Theme.MEDIA .. 'BanzaiParchmentTile', 'REPEAT', 'REPEAT' },      -- the paper body, repeating both ways
	corners = { Theme.MEDIA .. 'BanzaiParchmentCorners', 'CLAMP', 'CLAMP' },  -- the four corners
	edge = { Theme.MEDIA .. 'BanzaiParchmentEdge', 'REPEAT', 'CLAMP' },       -- the worn edge strips, repeating along
}
-- Bushido's slotted health art (diagonal cuts); replaced by a smooth trough
local SLOT_ART = { NewBushidoHealth = true, ['20Bushido'] = true }

local Compat = {}
ns.Compat = Compat
_G.BanzaiCompat = Compat -- options page and /banzai (BushidoPrivateRestore) talk to this
Compat.Theme = Theme
Compat.Flavor = ns.Flavor -- 1.5.0-dev1: the client adapter (shared/Flavor.lua)
Compat.VERSION = Theme.VERSION

-- 1.1.0 bamboo frame geometry (the same numbers as tools/lib/panel.js PANEL,
-- which draws the offline preview): every size is a multiple of the stalk
-- diameter d = stalk x border scale (0.7 .. 1: thicker would cover the
-- content). The stalk's outer edge sits `outer` inside the holder rectangle,
-- so the content inset of 10.5 (unchanged since 0.5.0) is exactly outer +
-- stalk at scale 1. The stalks run `ext` x d past the corners; the chat /
-- Details side stalks end on the bottom panel's top line (`extBottom` 0: the
-- panel's glass lies over everything lower, and its text sits there), and the
-- bottom ties stop there too. Nodes every `period` x d, a rope tie of `tie`
-- x d over each crossing. Texture facts: stalk diameter texD px in a texH px
-- strip, a tip piece tipPx px, one node period periodPx px (periods of them).
Compat.PANEL = { stalk = 10, outer = 0.5, ext = 1.0, extBottom = 0, period = 3.6, tie = 2.6, parchment = 0.55, parchmentCorner = 2.4,
	texD = 88, texH = 128, tipPx = 256, periodPx = 256, periods = 4, tipGap = 6 }
Compat.BAND = { outer = 0.5, inset = 10.5 } -- the frame edge margin and the content inset (0.5.0), kept by the bamboo frame
-- 1.3.7 HARDKORH PARCHMENT as one material that is never stretched (the same numbers as tools/lib/panel.js PARCHMENT;
-- 1.1.0 - 1.3.6 stretched one 512 px sheet to every panel's shape, so the grain ran 4 - 8 times longer across than
-- down): the body tile (tileW x tileH texels) at `density` texels per UI unit on both axes of every panel, so a wider
-- panel shows more paper, never larger paper; the worn edge strips (edgeW x edgeH: four rows, each one corner size
-- thick and `period` corner sizes long) and the corner atlas (`corners` texels: four corners) at the stalk's scale,
-- so every panel has the same edge; `phase`: where each panel starts in the tile (fractions), fixed per panel
Compat.PARCHMENT = { tileW = 1024, tileH = 512, density = 2, edgeW = 512, edgeH = 256, corners = 128, period = 8,
	phase = { chat = { 0, 0 }, details = { 0.46, 0.38 }, buffs = { 0.23, 0.71 } } }
-- Lower-right / lower-left compositions (UIParent units). BushidoPrivateRestore
-- places the two Details windows and the ElvUI chat panel with these numbers:
-- windows bottom = bar height + 10, frame bottom edge on the bar's top edge.
-- 0.6.0 made the frame wider than its content for the leaning sides; 1.1.0
-- keeps the outer size (the approved dimensions) with the square content in
-- the middle of it, the lower outer corner 16 from the edge.
-- 1.3.6 a real centre gutter between DAMAGE and HEALING: each window 4.5 narrower (212 -> 207.5), the gap
-- between them 6 -> 15 (20 screen pixels at Darren's 2560 x 1440, UI scale 0.71: 9 empty, the 2 px divider,
-- 9 empty; both inner edges on whole pixels there). The outer edges, the frame and centerX stay
-- (2 x width + gap = 430 as before), so the bamboo frame and the titles do not move.
Compat.DETAILS = {
	width = 207.5, height = 124, gap = 15, title = 16, right = -47.15, bottom = 42,
	edge = 16,
	frameWidth = 493.31, frameHeight = 161, centerX = -215, centerY = 70,
}
-- 1.2.0: flush with the left screen edge - the left stalk's outer edge on it (-0.155: the ElvUI chat panel keeps a
-- whole-unit x, 31 = BushidoPrivateRestore's T.CHAT.x); same width, height and bottom as before (1.1.x: left 15.345, x 47)
Compat.CHAT = { left = -0.655, contentX = 31, width = 493.31, height = 161 }
Compat.MINIMAP = { zoneGap = 5, zoneSize = 16 } -- 1.1.0: the frame hugs the map (outer + stalk around it); the zone name this far above the top stalk (1.3.1: in the Banzai display font)
-- 1.2.0 BUFFS panel: around ElvUI's buff icons (its header, BuffsMover), `pad` inside the stalks on top and the
-- sides, `padBottom` below the last row: ElvUI draws each buff's duration under its icon (cooldown text BOTTOM, -3,
-- size 16) and the BUFFS title sits on the bottom stalk. Debuffs are placed below by BushidoPrivateRestore (T.BUFFS_PANEL).
Compat.BUFFS = { pad = 5, padBottom = 18, perRow = 10, size = 25, height = 21, spacing = 6, rowGap = 10 }
Compat.LOGO = { height = 24, top = -10 } -- top centre of the screen
-- in combat: 1.75x the HUD wordmark, centred between Player and Target, the tree
-- behind it (its lower trunk under the letters); fallback when the frames have no layout
Compat.COMBAT = { scale = 1.75, tree = 132, lift = 26, fallbackY = -211, fade = 0.15 }
-- 1.1.0: each panel's own gradient direction over the frame (HARDKORH / CLASS):
-- chat lime top-left -> purple bottom-right, Details the other way round
-- (Darren, 0.4.0), the minimap left -> right. x, y 0..1 from the top-left.
Compat.FIELD = {
	minimap = function(x) return x end,
	chat = function(x, y) return 0.5 * x + 0.5 * y end,
	details = function(x, y) return 1 - (0.5 * x + 0.5 * y) end,
	buffs = function(x, y) return 0.5 * x + 0.5 * y end, -- 1.2.0: like the chat (top-left green)
}
Compat.END_ART = { ElvUF_Player = true, ElvUF_Target = true } -- 0.7.0: the only unit frames with bamboo
Compat.SPLIT_FRAMES = { ElvUF_Player = true, ElvUF_Target = true, ElvUF_Focus = true, ElvUF_TargetTarget = true } -- 1.3.0: no Bushido plates / bamboo in a split session
-- the arena frames get the smooth dark trough under their bar
Compat.ARENA_PARTS = { { id = 'BanzaiArenaTrough', texture = 'NewBushidoHealth', w = 200, h = 35, x = 0, y = 0, strata = 'LOW' } }
-- 0.7.0 Details titles (window 1 left-aligned, window 2 right-aligned) by what
-- the window shows (Details attribute: 1 damage, 2 healing, 3 resources, 4 utility)
Compat.DETAILS_TITLES = {
	[1] = { text = 'DAMAGE', bright = { 1.00, 0.40, 0.32 }, deep = { 0.80, 0.03, 0.10 } },
	[2] = { text = 'HEALING', bright = { 0.55, 1.00, 0.45 }, deep = { 0.00, 0.66, 0.30 } },
	[3] = { text = 'RESOURCES', bright = { 0.45, 0.80, 1.00 }, deep = { 0.10, 0.35, 0.85 } },
	[4] = { text = 'UTILITY', bright = { 0.80, 0.55, 1.00 }, deep = { 0.45, 0.12, 0.80 } },
}
-- size (display font), inset from the window edge, room left of the top-right
-- rope tie, backing padding, accent line thickness / gap
Compat.DETAILS_TITLE = { size = 22, inset = 4, bamboo = 6, pad = 7, fade = 9, accent = 2, gap = 2 }
-- 0.8.0 the chat frame's title: same font, size, backing and accent, centred, green -> red
-- 0.9.0: darker and more restrained than DAMAGE / HEALING (a dark green into a dark red)
Compat.CHAT_TITLE = { text = 'CHAT', bright = { 0.20, 0.64, 0.32 }, deep = { 0.70, 0.16, 0.16 } }
-- 1.2.0 the BUFFS panel's title (on its bottom stalk): Banzai green -> violet, the dark backing keeps it readable on any border / background
Compat.BUFFS_TITLE = { text = 'BUFFS', bright = { 0.55, 1.00, 0.30 }, deep = { 0.62, 0.32, 1.00 } }
Compat.DETAILS_ACCENT = { -- line under each title, by what the window shows (1: DAMAGE, 2: HEALING)
	{ bright = { 1.00, 0.30, 0.26 }, deep = { 0.55, 0.03, 0.08 } },
	{ bright = { 0.32, 0.96, 0.40 }, deep = { 0.02, 0.45, 0.22 } },
}
-- 1.3.5 the divider between the DAMAGE and HEALING meters: one thin vertical line on the frame's centre (the
-- middle of the gap between the two windows; 1.3.6: the 15-unit gutter), `px` screen pixels wide (2 at Darren's 2560 x 1440, UI
-- scale 0.71), in the interior only - `pad` x the stalk clear of the top and bottom stalks, so no stalk, title,
-- rope tie or the bottom panel is crossed - both ends fading out over `fade` units. Top to bottom the BANZAI
-- gradient (lime, green, emerald, violet, purple) at a restrained alpha, a little stronger on the light parchment.
Compat.DETAILS_DIVIDER = { px = 2, pad = 0.8, fade = 14, alpha = 0.5, parchment = 0.72 }
Compat.DIVIDER_STOPS = { Theme.COLORS.lime, Theme.Mix(Theme.COLORS.lime, Theme.COLORS.emerald, 0.5), Theme.COLORS.emerald, Theme.COLORS.violet, Theme.COLORS.purple }

local holders = {}    -- every art frame
local decorated = {}  -- [frame] = true
local bordered = {}   -- [unit frame] = true: Bushido chassis, health border hidden
local ends = {}       -- end-art holders (raised above the health bar)
local bands = {}      -- 1.1.0: bamboo frames (laid out again when the border scale changes)
local painters = {}   -- functions that (re)colour art with the current theme
local pending = false

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function Active()
	local E = Engine()
	return E and E.data and E.data:GetCurrentProfile() == PROFILE or false
end
Compat.Active = Active

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Painter(fn)
	painters[#painters + 1] = fn
	return fn
end

-- rectangle of a region in UIParent units (nil when it has no layout)
local function Rect(region)
	if not (region and region.GetRect) then return nil end
	local l, b, w, h = region:GetRect()
	if type(l) ~= 'number' or IsSecret(l) or type(b) ~= 'number' or IsSecret(b) or type(w) ~= 'number' or IsSecret(w) or w <= 0 or type(h) ~= 'number' or IsSecret(h) then return nil end
	local scale = 1
	if region.GetEffectiveScale and UIParent.GetEffectiveScale then
		local own, parent = region:GetEffectiveScale(), UIParent:GetEffectiveScale()
		if type(own) == 'number' and type(parent) == 'number' and not IsSecret(own) and parent > 0 then scale = own / parent end
	end
	return l * scale, b * scale, w * scale, h * scale
end
Compat.Rect = Rect -- 1.5.0-dev3: ChatLayout.lua and Skins.lua measure with the same rule

---------------------------------------------------------------------------
-- Building blocks
---------------------------------------------------------------------------
local function NewHolder(parent, strata, w, h)
	local holder = CreateFrame('Frame', nil, parent)
	holder:SetFrameStrata(strata or 'LOW')
	if holder.SetFixedFrameStrata then holder:SetFixedFrameStrata(true) end -- keep the layer when ElvUI re-strata's the unit frame
	holder:SetSize(w, h)
	holder.bw, holder.bh = w, h
	holder:EnableMouse(false)
	holders[#holders + 1] = holder
	return holder
end

local function Texture(holder, sublevel, path)
	local t = holder:CreateTexture(nil, 'ARTWORK', nil, sublevel)
	if path then t:SetTexture(path) end
	return t
end

-- Three tied bamboo stalks filling `holder`. stalkAt(p) / tieAt(p) give the
-- colour at height p (0 bottom .. 1 top) when the theme paints.
local function Bundle(holder, flipH, stalkAt, tieAt)
	local w, h = holder.bw, holder.bh
	local l, r = 0, 1
	if flipH then l, r = 1, 0 end
	holder.stalks = {}
	for i = 1, STALK_STRIPS do
		local p0, p1 = (i - 1) / STALK_STRIPS, i / STALK_STRIPS
		local strip = Texture(holder, 1, BUNDLE)
		strip:SetTexCoord(l, r, 1 - p1, 1 - p0)
		strip:SetPoint('BOTTOMLEFT', holder, 'BOTTOMLEFT', 0, p0 * h)
		strip:SetSize(w, (p1 - p0) * h + ((i < STALK_STRIPS) and 0.25 or 0))
		holder.stalks[i] = { texture = strip, p0 = p0, p1 = p1 }
	end
	local tie = Texture(holder, 2, TIE)
	tie:SetAllPoints()
	tie:SetTexCoord(l, r, 0, 1)
	holder.tie = tie
	holder.isBundle = true
	Painter(function()
		for _, s in ipairs(holder.stalks) do
			Theme:Gradient(s.texture, 'VERTICAL', stalkAt(s.p0), stalkAt(s.p1), 1, 1)
		end
		Theme:Gradient(tie, 'VERTICAL', tieAt(0), tieAt(1), 1, 1)
	end)
	return holder
end
Compat.Bundle = Bundle

local function StalkRamp(p) return Theme:ColorAt(Theme:Stops('stalk'), p) end
local function TieRamp(p) return Theme:ColorAt(Theme:Stops('tie'), p) end
Compat.StalkRamp, Compat.TieRamp = StalkRamp, TieRamp
-- corner bamboo: its own colours, never the theme, intensity or a frame gradient

-- The tracker (Tracker.lua) reads the minimap frame's bottom edge through
-- these; 1.1.0: the frames are square again, so the edge is the whole width.
function Compat.Shift() return 0 end
function Compat.RowWidth(holder) return holder.bw end

---------------------------------------------------------------------------
-- 1.1.0 bamboo frame: four stalks, four rope ties, the background inside
---------------------------------------------------------------------------
local function BorderScale()
	local S = Theme.BORDER_SCALE
	return math.max(S.min, math.min(S.max, Theme:DB().borderScale or 1))
end

-- the stalk diameter in units at the current border scale
local function StalkDiameter()
	return Compat.PANEL.stalk * BorderScale()
end
Compat.StalkDiameter = StalkDiameter

-- The game takes eight tex coords (upper-left, lower-left, upper-right,
-- lower-right). A horizontal piece reads the texture as it is (U along x,
-- V down); a vertical piece turns it (U along y, V along x) so the
-- highlight stays on the upper / left side. `flip` runs U the other way
-- (a tip pointing left / up).
local function Coords(horizontal, u0, u1, flip)
	local a, b = u0, u1
	if flip then a, b = u1, u0 end
	if horizontal then return a, 0, a, 1, b, 0, b, 1 end
	return a, 0, b, 0, a, 1, b, 1
end

local function PanelTexture(holder, sublevel, path)
	local t = holder:CreateTexture(nil, 'ARTWORK', nil, sublevel)
	t:SetTexture(path, 'CLAMP', 'CLAMP', 'TRILINEAR')
	return t
end

-- Lays the frame out for the holder's size and the current border scale:
-- body segments (one node period each, cycling through the texture's four
-- periods), a tip piece on each end, the ties on the crossings, the
-- background inside. Textures are made on the first layout and reused; a
-- different scale may need another segment or leave one unused (hidden).
local function LayoutBamboo(holder)
	local P = Compat.PANEL
	local W, H = holder.bw, holder.bh
	local d = StalkDiameter()
	local key = d .. ':' .. W .. ':' .. H
	if holder.layoutKey == key then return end -- nothing changed: the pieces stay as they are
	holder.layoutKey = key
	local half = d / 2
	local strip = (P.texH / P.texD) * d
	local tip = (P.tipPx / P.texD) * d
	local extBottom = holder.shortBottom and P.extBottom or P.ext
	-- 1.2.0 a frame flush with the left screen edge (holder.flushLeft: its x on the screen): the horizontal
	-- stalks end at the left stalk (nothing runs off the screen), plain node ends there, cut tips on the open side
	local flush = type(holder.flushLeft) == 'number'
	local extLeft = flush and 0 or P.ext
	local startLeft = flush and math.max(0, -holder.flushLeft) or -P.ext * d -- flush: the stalks start on the screen edge
	local axis = { top = P.outer + half, bottom = H - P.outer - half, left = P.outer + half, right = W - P.outer - half }
	holder.axis, holder.stalkDiameter = axis, d
	-- (name, along the holder's x or y, at, from, to, the end with the cut tip, draw order: bottom under the sides under the top)
	local stalks = {
		{ name = 'top', horizontal = true, at = axis.top, from = startLeft, to = W + P.ext * d, cutEnd = 'end', sub = 2 },
		{ name = 'bottom', horizontal = true, at = axis.bottom, from = startLeft, to = W + P.ext * d, cutEnd = flush and 'end' or 'start', sub = 0 },
		{ name = 'left', horizontal = false, at = axis.left, from = -P.ext * d, to = H + extBottom * d, cutEnd = 'start', sub = 1 },
		{ name = 'right', horizontal = false, at = axis.right, from = -P.ext * d, to = H + extBottom * d, cutEnd = 'end', sub = 1 },
	}
	holder.pieces = holder.pieces or {}
	local used = 0
	local function put(st, a, b, path, u0, u1, flip)
		used = used + 1
		local piece = holder.pieces[used]
		if not piece then
			piece = { texture = PanelTexture(holder, st.sub, path) }
			holder.pieces[used] = piece
		end
		local t = piece.texture
		if piece.path ~= path then t:SetTexture(path, 'CLAMP', 'CLAMP', 'TRILINEAR') piece.path = path end
		if piece.sub ~= st.sub and t.SetDrawLayer then t:SetDrawLayer('ARTWORK', st.sub) end
		piece.sub = st.sub
		t:SetTexCoord(Coords(st.horizontal, u0, u1, flip))
		t:ClearAllPoints()
		if st.horizontal then
			t:SetPoint('TOPLEFT', holder, 'TOPLEFT', a, -(st.at - strip / 2))
			t:SetSize(b - a, strip)
		else
			t:SetPoint('TOPLEFT', holder, 'TOPLEFT', st.at - strip / 2, -a)
			t:SetSize(strip, b - a)
		end
		t:Show()
		piece.stalk, piece.horizontal = st.name, st.horizontal
		-- the two ends in frame space (0..1): the colour field is read there
		local function at(v)
			local f = math.max(0, math.min(1, v / (st.horizontal and W or H)))
			if st.name == 'top' then return f, 0 elseif st.name == 'bottom' then return f, 1 elseif st.name == 'left' then return 0, f end
			return 1, f
		end
		piece.xa, piece.ya = at(a)
		piece.xb, piece.yb = at(b)
		piece.pa, piece.pb = (a - st.from) / (st.to - st.from), (b - st.from) / (st.to - st.from)
		piece.vary = ((used * 7919) % 97) / 97
	end
	local gap = P.tipGap / (2 * P.tipPx)
	local cutU, plainU = { 0, 0.5 - gap }, { 0.5 + gap, 1 }
	for _, st in ipairs(stalks) do
		local bodyFrom, bodyTo = st.from + tip, st.to - tip
		local n = math.max(1, math.floor((bodyTo - bodyFrom) / (P.period * d) + 0.5))
		local seg = (bodyTo - bodyFrom) / n
		for i = 0, n - 1 do
			local k = i % P.periods
			put(st, bodyFrom + i * seg, bodyFrom + (i + 1) * seg + ((i < n - 1) and 0.25 or 0), STALK, k / P.periods, (k + 1) / P.periods, false)
		end
		local cutStart = st.cutEnd == 'start'
		local first, last = cutStart and cutU or plainU, cutStart and plainU or cutU
		put(st, st.from, bodyFrom, STALK_END, first[1], first[2], true)   -- the start: its tip points back (left / up)
		put(st, bodyTo, st.to, STALK_END, last[1], last[2], false)       -- the end: its tip points on (right / down)
	end
	for i = used + 1, #holder.pieces do holder.pieces[i].texture:Hide() end
	holder.pieceCount = used
	-- the rope ties over the four crossings; the right-hand ones mirrored
	local tie = P.tie * d
	holder.ties = holder.ties or {}
	-- on a flush-left frame the two left ties keep their whole rope on the screen: shifted along the horizontal stalk, still over the crossing
	local leftTie = flush and math.max(axis.left, tie / 2 - holder.flushLeft) or axis.left
	for i, corner in ipairs({ { 'TOPLEFT', leftTie, axis.top }, { 'TOPRIGHT', axis.right, axis.top }, { 'BOTTOMLEFT', leftTie, axis.bottom }, { 'BOTTOMRIGHT', axis.right, axis.bottom } }) do
		local t = holder.ties[i]
		if not t then
			t = PanelTexture(holder, 3, ROPE)
			holder.ties[i] = t
		end
		t.corner = corner[1]
		local top = corner[3] - tie / 2
		local v1 = 1
		if holder.shortBottom and top + tie > H then v1 = (H - top) / tie end -- the rope passes behind the bottom panel: cut at its top line
		if string.find(corner[1], 'RIGHT', 1, true) then t:SetTexCoord(1, 0, 1, v1, 0, 0, 0, v1) else t:SetTexCoord(0, 0, 0, v1, 1, 0, 1, v1) end
		t:ClearAllPoints()
		t:SetPoint('TOPLEFT', holder, 'TOPLEFT', corner[2] - tie / 2, -top)
		t:SetSize(tie, tie * v1)
	end
	-- the background: glass / solid up to the stalk axis (under the stalk), the
	-- parchment a little inside with its worn, torn edge under the stalk and just past it
	if holder.glass then
		local inset = P.outer + half
		holder.glass:ClearAllPoints()
		holder.glass:SetPoint('TOPLEFT', holder, 'TOPLEFT', inset, -inset)
		holder.glass:SetSize(W - 2 * inset, H - 2 * inset)
	end
	if holder.parchment then
		local inset = P.outer + P.parchment * d
		local pieces = Compat.ParchmentLayout(W - 2 * inset, H - 2 * inset, d, holder.artKind)
		for i, piece in ipairs(pieces) do
			local t = holder.parchment[i]
			t:SetTexCoord(unpack(piece.coords))
			t:ClearAllPoints()
			-- both corners given: a piece's side is exactly its neighbour's (no gap, no overlap)
			t:SetPoint('TOPLEFT', holder, 'TOPLEFT', inset + piece.x0, -(inset + piece.y0))
			t:SetPoint('BOTTOMRIGHT', holder, 'TOPLEFT', inset + piece.x1, -(inset + piece.y1))
			t.piece = piece.name
		end
	end
end
Compat.LayoutBamboo = LayoutBamboo

-- 1.3.7 the parchment's pieces for a pw x ph parchment rectangle at stalk diameter d (x right, y down from its
-- top-left; the same as tools/lib/panel.js parchmentLayout, which the offline preview draws):
--   body     the whole rectangle in one piece, the tile repeating from the panel's phase at Compat.PARCHMENT.density
--            texels per unit on both axes - the grain is the same size on every panel, never stretched
--   corners  one corner size square each (PANEL.parchmentCorner x d), a quadrant of the corner atlas
--   edges    each side in two halves: the worn strip repeating along it from each corner, mirrored where the halves
--            meet in the middle, so both corner joins meet the strip where it starts and both halves meet on the
--            same texels; one corner size thick on every panel
-- The worn pieces darken the body (black with alpha) and share their sides exactly: nothing overlaps, nothing is
-- left open, and the body under them is opaque, so no crack can show through.
function Compat.ParchmentLayout(pw, ph, d, kind)
	local M = Compat.PARCHMENT
	local c = math.min(Compat.PANEL.parchmentCorner * d, pw / 2, ph / 2)
	local period = M.period * c
	local phase = M.phase[kind] or M.phase.chat
	local pieces = {}
	local function add(name, texture, x0, y0, x1, y1, ...)
		pieces[#pieces + 1] = { name = name, texture = texture, x0 = x0, y0 = y0, x1 = x1, y1 = y1, coords = { ... } }
	end
	local u0, v0 = phase[1], phase[2]
	local u1, v1 = u0 + pw * M.density / M.tileW, v0 + ph * M.density / M.tileH
	add('body', 'tile', 0, 0, pw, ph, u0, v0, u0, v1, u1, v0, u1, v1)
	add('TOPLEFT', 'corners', 0, 0, c, c, 0, 0, 0, 0.5, 0.5, 0, 0.5, 0.5)
	add('TOPRIGHT', 'corners', pw - c, 0, pw, c, 0.5, 0, 0.5, 0.5, 1, 0, 1, 0.5)
	add('BOTTOMLEFT', 'corners', 0, ph - c, c, ph, 0, 0.5, 0, 1, 0.5, 0.5, 0.5, 1)
	add('BOTTOMRIGHT', 'corners', pw - c, ph - c, pw, ph, 0.5, 0.5, 0.5, 1, 1, 0.5, 1, 1)
	local mx, my = pw / 2, ph / 2
	local uw, uh = (mx - c) / period, (my - c) / period
	add('top1', 'edge', c, 0, mx, c, 0, 0, 0, 0.25, uw, 0, uw, 0.25)
	add('top2', 'edge', mx, 0, pw - c, c, uw, 0, uw, 0.25, 0, 0, 0, 0.25)
	add('bottom1', 'edge', c, ph - c, mx, ph, 0, 0.75, 0, 0.5, uw, 0.75, uw, 0.5)
	add('bottom2', 'edge', mx, ph - c, pw - c, ph, uw, 0.75, uw, 0.5, 0, 0.75, 0, 0.5)
	add('left1', 'edge', 0, c, c, my, 0, 1, uh, 1, 0, 0.75, uh, 0.75)
	add('left2', 'edge', 0, my, c, ph - c, uh, 1, 0, 1, uh, 0.75, 0, 0.75)
	add('right1', 'edge', pw - c, c, pw, my, 0, 0.25, uh, 0.25, 0, 0.5, uh, 0.5)
	add('right2', 'edge', pw - c, my, pw, ph - c, uh, 0.25, 0, 0.25, uh, 0.5, 0, 0.5)
	return pieces, c, period
end

-- the background textures of a panel (not the minimap: the map is its own interior); 1.3.7: the parchment's
-- 13 pieces, made once - the body under the worn pieces
local function PanelBackground(holder)
	holder.glass = holder:CreateTexture(nil, 'BACKGROUND')
	holder.parchment = {}
	for i, piece in ipairs(Compat.ParchmentLayout(100, 100, Compat.PANEL.stalk, 'chat')) do
		local tex = PARCHMENT_TEXTURES[piece.texture]
		local t = holder:CreateTexture(nil, 'BACKGROUND', nil, piece.texture == 'tile' and 0 or 1)
		t:SetTexture(tex[1], tex[2], tex[3], 'TRILINEAR')
		holder.parchment[i] = t
	end
end

-- Paints the frame for the current border style, background and class:
-- every segment a two-stop gradient along the stalk from the colour field,
-- the rope its own ramp, the interior the chosen material. Runs with the
-- other painters (settings, theme, class, profile changes), never per frame.
local function PaintBamboo(holder)
	local field = Compat.FIELD[holder.artKind] or Compat.FIELD.minimap
	for i = 1, holder.pieceCount or 0 do
		local piece = holder.pieces[i]
		local from = Theme:PanelStalk(piece.stalk, field(piece.xa, piece.ya), piece.pa, piece.vary)
		local to = Theme:PanelStalk(piece.stalk, field(piece.xb, piece.yb), piece.pb, piece.vary)
		-- a vertical gradient takes its first colour at the bottom: a vertical piece's `from` is its upper end
		if piece.horizontal then Theme:Gradient(piece.texture, 'HORIZONTAL', from, to, 1, 1) else Theme:Gradient(piece.texture, 'VERTICAL', to, from, 1, 1) end
	end
	for _, t in ipairs(holder.ties or {}) do
		Theme:Gradient(t, 'VERTICAL', Theme:PanelRope(1), Theme:PanelRope(0), 1, 1)
	end
	if holder.glass then
		local mode = Theme:DB().panelBackground
		local parchment = mode == 'PARCHMENT'
		holder.glass:SetShown(not parchment)
		if mode == 'SOLID' then Theme:Solid(holder.glass) else Theme:Glass(holder.glass) end
		local k = 0.91 * math.max(0.7, math.min(1.1, Theme:DB().parchmentBrightness or 1)) -- the texture is drawn 10 % brighter than its default
		for _, t in ipairs(holder.parchment) do
			t:SetShown(parchment)
			t:SetVertexColor(k, k, k, 1)
		end
	end
end

-- a panel holder with the bamboo frame (and, unless `bare`, a background)
local function BambooFrame(holder, bare, shortBottom)
	holder.shortBottom = shortBottom
	if not bare then PanelBackground(holder) end
	LayoutBamboo(holder)
	bands[#bands + 1] = holder
	Painter(function() PaintBamboo(holder) end)
	return holder
end

-- 1.0.0: Bushido placed its plates and spikes for its own frame widths (Player /
-- Target 302, the smaller frames 210). On narrower frames every piece keeps
-- its place against the frame end it belongs to: a plate stretches between its
-- two insets, an end piece stays as far outside its end as it was. Without a
-- design width (raid, boss, ...) a piece sits on the frame's centre as before.
Compat.DESIGN_WIDTH = { ElvUF_Player = 302, ElvUF_Target = 302, ElvUF_Focus = 210, ElvUF_TargetTarget = 210, ElvUF_Pet = 210 }
function Compat.PlacePart(region, parent, part, scale, design, k)
	scale, k = scale or 1, k or 1
	region:ClearAllPoints()
	if not design then
		region:SetSize(part.w * scale * k, part.h * scale * k)
		region:SetPoint('CENTER', parent, 'CENTER', part.x * scale, part.y * scale)
		return 'CENTER'
	end
	local half = design * scale / 2
	if part.texture == 'WHITE' then
		region:SetHeight(part.h * scale)
		region:SetPoint('LEFT', parent, 'LEFT', (part.x - part.w / 2) * scale + half, part.y * scale)
		region:SetPoint('RIGHT', parent, 'RIGHT', (part.x + part.w / 2) * scale - half, part.y * scale)
		return 'SPAN'
	end
	region:SetSize(part.w * scale * k, part.h * scale * k)
	if part.x >= 0 then
		region:SetPoint('CENTER', parent, 'RIGHT', part.x * scale - half, part.y * scale)
		return 'RIGHT'
	end
	region:SetPoint('CENTER', parent, 'LEFT', part.x * scale + half, part.y * scale)
	return 'LEFT'
end

-- Unit end art: same place and layer as Bushido's spike, Banzai bundle instead.
-- `size` (optional) scales the bundle without moving it off the frame end.
local function EndArt(parent, part, scale, size, design)
	scale = scale or 1
	local k = scale * (size or 1)
	local holder = NewHolder(parent, part.strata, part.w * k, part.h * k)
	Compat.PlacePart(holder, parent, part, scale, design, size)
	holder.part, holder.unitFrame, holder.artKind = part, parent, 'end'
	Bundle(holder, part.flipH, StalkRamp, TieRamp)
	return holder
end

local function PlainArt(holder, part)
	local texture = Texture(holder, 1)
	texture:SetAllPoints()
	if part.atlas then
		texture:SetAtlas(part.atlas)
	elseif part.texture == 'WHITE' then
		texture:SetTexture(WHITE)
	else
		texture:SetTexture(G.media .. part.texture)
	end
	local l, r, top, bottom = 0, 1, 0, 1
	if part.flipH then l, r = 1, 0 end
	if part.flipV then top, bottom = 1, 0 end
	texture:SetTexCoord(l, r, top, bottom)
	local c = part.color
	texture:SetVertexColor(c[1], c[2], c[3], c[4])
	holder.texture = texture
	return texture
end

local function PlainPart(parent, part, scale, design)
	scale = scale or 1
	local holder = NewHolder(parent, part.strata, part.w * scale, part.h * scale)
	Compat.PlacePart(holder, parent, part, scale, design)
	holder.part, holder.unitFrame, holder.artKind = part, parent, 'plain'
	PlainArt(holder, part)
	return holder
end

-- 0.5.0: smooth dark trough under the health bar in place of the slot art. It
-- follows the bar itself, so it fits every frame without Bushido's offsets.
local function Trough(parent, part, scale)
	local bar = parent.Health
	local holder = NewHolder(parent, 'LOW', 1, 1)
	holder.part, holder.unitFrame, holder.artKind = part, parent, 'trough'
	holder:ClearAllPoints()
	if bar then
		holder:SetPoint('TOPLEFT', bar, 'TOPLEFT', -1, 1)
		holder:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', 1, -1)
		local level = bar.GetFrameLevel and bar:GetFrameLevel()
		if type(level) == 'number' and not IsSecret(level) then holder:SetFrameLevel(math.max(0, level - 1)) end
	else
		scale = scale or 1
		holder:SetSize(part.w * scale, 20 * scale)
		holder:SetPoint('CENTER', parent, 'CENTER', part.x * scale, part.y * scale)
	end
	local texture = holder:CreateTexture(nil, 'BACKGROUND')
	texture:SetAllPoints()
	holder.texture = texture
	Painter(function() Theme:Trough(texture) end)
	return holder
end

-- noEnd: the frame keeps Bushido's chassis treatment but no bamboo (0.7.0 secondary frames)
-- design: the frame width Bushido's parts were placed for (1.0.0, Compat.DESIGN_WIDTH)
local function Decorate(frame, parts, scale, endSize, noEnd, design)
	if not frame or decorated[frame] then return end
	for _, part in ipairs(parts) do
		if part.texture == 'BushidoEndPoint' then
			if not noEnd then ends[#ends + 1] = EndArt(frame, part, scale, endSize, design) end
			bordered[frame] = true
		elseif SLOT_ART[part.texture] then
			Trough(frame, part, scale)
		else
			PlainPart(frame, part, scale, design)
		end
	end
	decorated[frame] = true
end
Compat.Decorate = Decorate

---------------------------------------------------------------------------
-- Minimap: a square bamboo frame hugging the map, the zone name above it
---------------------------------------------------------------------------
-- the frame's size: the map plus the stalk around it (outer + d each side)
function Compat:MinimapFrameSize()
	local map = _G.Minimap
	local mapSize = map and map.GetWidth and map:GetWidth() or 0
	if type(mapSize) ~= 'number' or IsSecret(mapSize) or mapSize < 50 then mapSize = 185 end
	return mapSize + 2 * (self.PANEL.outer + StalkDiameter())
end

function Compat:BuildMinimap(map)
	local size = self:MinimapFrameSize()
	local frame = NewHolder(map, 'MEDIUM', size, size)
	frame:SetPoint('CENTER', map, 'CENTER', 0, 0)
	frame.artKind = 'minimap'
	BambooFrame(frame, true) -- the map itself is the interior
	-- zone name centred over the top stalk, between the two top ties
	local label = CreateFrame('Frame', nil, frame)
	label:SetSize(size, 18)
	label:SetPoint('BOTTOM', frame, 'TOP', 0, self.MINIMAP.zoneGap)
	label.text = label:CreateFontString(nil, 'OVERLAY')
	label.text:SetPoint('CENTER')
	label.text:SetWidth(size - 44) -- long names truncate: clear of the ties and the minimap button collector
	label.text:SetWordWrap(false)
	frame.zone = label
	self.minimapFrame = frame
	self:UpdateZone()
	return frame
end

function Compat.MinimapButtonLayout(mapSize, count, preferredSize)
	if type(mapSize) ~= 'number' or mapSize < 50 or type(count) ~= 'number' or count < 1 then return nil end
	local columns = math.min(2, math.floor(count))
	local rows = math.ceil(count / columns)
	local gap, padding = 2, 4
	local size = math.floor(math.min(preferredSize or 24,
		(mapSize - 2 * padding - (columns + 1) * gap) / columns,
		(mapSize - 2 * padding - (rows + 1) * gap) / rows))
	if size < 8 then return nil end
	local positions = {}
	for index = 1, count do
		local column, row = (index - 1) % columns, math.floor((index - 1) / columns)
		positions[index] = {
			size = size,
			x = -(padding + gap + column * (size + gap)),
			y = -(padding + gap + row * (size + gap)),
		}
	end
	return positions, columns * (size + gap) + gap, rows * (size + gap) + gap
end

-- 1.5.0-dev3: a dedicated minimap-button addon owns the buttons (their collection and their places). While
-- one is loaded, the dev2 containment of Eltruism's button bar does nothing at all - BANZAI owns the minimap
-- frame, its border and its look, never the buttons. Without one, dev2's behaviour is unchanged.
Compat.MINIMAP_BUTTON_MANAGERS = { 'MinimapButtonButton' }
function Compat.MinimapButtonManager()
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
	if not loaded then return nil end
	for _, name in ipairs(Compat.MINIMAP_BUTTON_MANAGERS) do
		if loaded(name) then return name end
	end
	return nil
end

function Compat:LayoutMinimapButtonBar()
	local owner = Compat.MinimapButtonManager()
	if owner then
		self.minimapButtonsPending = nil
		return false, 'left to ' .. owner
	end
	if InCombatLockdown() then
		self.minimapButtonsPending = true
		return false, 'waiting (combat)'
	end
	local map, bar = _G.Minimap, _G.EltruismMinimapButtonBar
	if not (map and bar and bar.GetChildren and bar.SetPoint and bar.SetSize) then return false, 'Eltruism button bar unavailable' end
	if (map.IsForbidden and map:IsForbidden()) or (bar.IsForbidden and bar:IsForbidden()) then return false, 'forbidden frame' end
	local children = { bar:GetChildren() }
	local buttons = {}
	for _, button in ipairs(children) do
		if button and button.EltruismInBar and (not button.IsForbidden or not button:IsForbidden()) and (not button.IsShown or button:IsShown()) then
			buttons[#buttons + 1] = button
		end
	end
	table.sort(buttons, function(a, b)
		local an = (a.GetName and a:GetName()) or a.name or ''
		local bn = (b.GetName and b:GetName()) or b.name or ''
		return an < bn
	end)
	if #buttons == 0 then return true, 'no visible addon buttons' end
	local mapSize = map:GetWidth()
	local layout, width, height = Compat.MinimapButtonLayout(mapSize, #buttons, buttons[1]:GetWidth())
	if not layout then return false, 'button group does not fit the minimap' end
	bar:ClearAllPoints()
	bar:SetSize(width, height)
	bar:SetPoint('TOPRIGHT', map, 'TOPRIGHT', -4, -4)
	for index, button in ipairs(buttons) do
		local position = layout[index]
		button:ClearAllPoints()
		button:SetSize(position.size, position.size)
		button:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', position.x, position.y)
	end
	self.minimapButtonsPending = nil
	return true, 'contained within the minimap border'
end

function Compat:RefreshMinimapButtonBar()
	if not (ns.Flavor and ns.Flavor.IsForever()) then return end
	if Compat.MinimapButtonManager() then -- 1.5.0-dev3: the button addon's business; Eltruism's bar is not driven from here
		self.minimapButtonsPending = nil
		return
	end
	if InCombatLockdown() then
		self.minimapButtonsPending = true
		return
	end
	local manager = _G.ElvUI_EltreumUI
	if not (self.minimapFrame and Active() and Theme:DB().minimapFrame and _G.EltruismMinimapButtonBar) then
		if manager and manager.UpdateMinimapButtonBar then manager:UpdateMinimapButtonBar() end
		return
	end
	if manager and manager.UpdateMinimapButtonBar then manager:UpdateMinimapButtonBar() end
	self:LayoutMinimapButtonBar()
end

function Compat:HookMinimapButtonBar()
	local manager = _G.ElvUI_EltreumUI
	if self.minimapButtonHooked or not (manager and type(manager.UpdateMinimapButtonBar) == 'function' and hooksecurefunc) then return false end
	hooksecurefunc(manager, 'UpdateMinimapButtonBar', function()
		if ns.Flavor and ns.Flavor.IsForever() and Compat.minimapFrame and Active() and Theme:DB().minimapFrame and not Compat.MinimapButtonManager() then Compat:LayoutMinimapButtonBar() end
	end)
	self.minimapButtonHooked = true
	return true
end

-- the frame follows the border scale (its stalk thickness changes the size)
function Compat:SizeMinimapFrame()
	local frame = self.minimapFrame
	if not frame then return end
	local size = self:MinimapFrameSize()
	if frame.bw ~= size then
		frame.bw, frame.bh = size, size
		frame:SetSize(size, size)
		frame.zone:SetSize(size, 18)
		frame.zone.text:SetWidth(size - 44)
	end
end

function Compat:UpdateZone()
	local frame = self.minimapFrame
	local label = frame and frame.zone
	if not label then return end
	local db = Theme:DB()
	local zone = (GetMinimapZoneText and GetMinimapZoneText()) or (GetZoneText and GetZoneText()) or ''
	if IsSecret(zone) or type(zone) ~= 'string' then zone = '' end
	Theme:SetDisplayFont(label.text, Theme:DisplaySize(self.MINIMAP.zoneSize), 'OUTLINE', zone) -- unsupported strings use the previous display font
	local from, to = Theme:Accents()
	if db.theme ~= 'CLASS' then from, to = Theme.COLORS.lime, Theme.COLORS.violet end
	label.text:SetText(Theme:GradientText(string.upper(zone), from, to))
	label:SetShown(db.zoneLabel and zone ~= '' and true or false)
end

local function CircleMinimap()
	local E = Engine()
	local m = E and E.db and E.db.general and E.db.general.minimap
	return m and m.circle and true or false
end

-- 1.1.0: the map fills the square bamboo frame as it is: ElvUI's own square
-- mask (nothing clipped away, nothing rotated, moved or scaled; clicks, zoom
-- and pings untouched) and ElvUI's square border made transparent while the
-- Banzai frame is on. Re-applied on refresh / zone change, since ElvUI sets
-- its mask when it updates the minimap.
function Compat:UpdateMinimapMask()
	local map = _G.Minimap
	if not (map and map.SetMaskTexture and self.minimapFrame) then return end
	local on = Active() and Theme:DB().minimapFrame and not CircleMinimap() and true or false
	if on then map:SetMaskTexture(SQUARE_MASK) end -- ElvUI's own square mask (what ElvUI applies itself); a circle map keeps its circle
	self.minimapMasked = on
	local backdrop = map.backdrop
	if backdrop and backdrop.SetAlpha then backdrop:SetAlpha(on and 0 or 1) end
end

---------------------------------------------------------------------------
-- Details: bamboo frame around both meters, the background inside, title accents
---------------------------------------------------------------------------
-- 1.3.5 the DAMAGE | HEALING divider: textures of the Details frame itself (BORDER: over its glass / parchment,
-- under every stalk) - a fading end, four gradient sections, a fading end
local function DetailsDivider(holder)
	local parts = {}
	for i = 1, #Compat.DIVIDER_STOPS + 1 do
		local t = holder:CreateTexture(nil, 'BORDER')
		t:SetTexture(WHITE)
		if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(true) end -- crisp: whole screen pixels
		if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
		parts[i] = t
	end
	return parts
end

function Compat:BuildDetails()
	local D = self.DETAILS
	local frame = NewHolder(UIParent, 'BACKGROUND', D.frameWidth, D.frameHeight) -- behind the Details windows (LOW)
	frame:SetFrameLevel(0)
	frame.artKind = 'details'
	BambooFrame(frame, false, true)
	frame.divider = DetailsDivider(frame)
	Painter(function() Compat:PaintDetailsDivider() end)
	self.detailsFrame = frame
	self.detailsTitles = { self:DetailsTitle(frame, 1, 'LEFT'), self:DetailsTitle(frame, 2, 'RIGHT') }
	-- the window may be switched to another display: its title follows
	if C_Timer and C_Timer.NewTicker then C_Timer.NewTicker(1, function() Compat:UpdateDetailsTitles() end) end
end

-- One title on the Details frame's top border: the letters (display font,
-- per-letter gradient in the title's colour family) over a dark backing with
-- soft ends, so the border line runs behind them; an accent line under them.
function Compat:DetailsTitle(chassis, index, side)
	local T = self.DETAILS_TITLE
	local t = CreateFrame('Frame', nil, UIParent)
	t:SetFrameStrata('MEDIUM')
	t:SetSize(10, T.size)
	t:EnableMouse(false)
	t.index, t.side, t.chassis = index, side, chassis
	t.text = t:CreateFontString(nil, 'OVERLAY')
	t.text:SetPoint('CENTER', t, 'CENTER', 0, 0)
	t.backing = {}
	for i = 1, 3 do -- fading end, solid middle, fading end
		local b = t:CreateTexture(nil, 'BACKGROUND')
		b:SetTexture(WHITE)
		t.backing[i] = b
	end
	t.accent = t:CreateTexture(nil, 'ARTWORK')
	t.accent:SetTexture(WHITE)
	t:Hide()
	return t
end

-- what a Details window shows (DAMAGE / HEALING / ...); window 1 damage, 2 healing by default
local function DetailsAttribute(index)
	local details = _G.Details
	local window = details and details.GetInstance and details:GetInstance(index)
	local attribute = window and window.GetDisplay and select(1, window:GetDisplay())
	if type(attribute) ~= 'number' or IsSecret(attribute) then return index end
	return attribute
end

-- lays out one title: centred on the top border, left- or right-aligned in its window's half
function Compat:LayoutDetailsTitle(t)
	local D, T = self.DETAILS, self.DETAILS_TITLE
	local chassis = t.chassis
	local style = t.fixedStyle or self.DETAILS_TITLES[DetailsAttribute(t.index)] or self.DETAILS_TITLES[t.index]
	Theme:SetDisplayFont(t.text, Theme:DisplaySize(T.size), 'OUTLINE') -- 1.3.1: the Banzai display font at the character's display size
	t.text:SetShadowOffset(1, -1)
	t.text:SetText(Theme:GradientText(style.text, style.bright, style.deep))
	t.style = style
	local width = (t.text:GetStringWidth() or 0) + 2 * T.pad
	t:SetSize(width, T.size)
	-- the border line: the top stalk's axis (outer margin + half the stalk)
	local d = StalkDiameter()
	local line = self.PANEL.outer + d / 2
	local center = chassis.bw / 2 -- the windows sit in the middle of the frame (centerX)
	t:ClearAllPoints()
	if t.bottom then -- 1.2.0 BUFFS: the middle of the bottom stalk
		t:SetPoint('CENTER', chassis, 'TOPLEFT', center, -(chassis.bh - line))
	elseif t.side == 'CENTER' then -- the middle of the top stalk
		t:SetPoint('CENTER', chassis, 'TOPLEFT', center, -line)
	elseif t.side == 'LEFT' then
		local left = center + D.centerX + T.inset - T.pad -- window 1's left edge (two windows + gap = 2 x 215)
		t:SetPoint('LEFT', chassis, 'TOPLEFT', left, -line)
	else
		local right = center - D.centerX - T.inset + T.pad -- window 2's right edge
		-- clear of the top-right rope tie
		local x = chassis.bw - self.PANEL.outer - d / 2 - self.PANEL.tie * d / 2 - T.bamboo + T.pad
		t:SetPoint('RIGHT', chassis, 'TOPLEFT', math.min(right, x), -line)
	end
	-- backing: soft ends, solid middle (alpha in the gradient colours)
	local glass = { 0.01, 0.025, 0.018 }
	local h = T.size * 0.78
	local fade = T.fade
	local a = math.min(1, (Theme:DB().glassOpacity or 0.72) + 0.25)
	local b1, b2, b3 = t.backing[1], t.backing[2], t.backing[3]
	b1:ClearAllPoints() b1:SetPoint('LEFT', t, 'LEFT', 0, 0) b1:SetSize(fade, h)
	b3:ClearAllPoints() b3:SetPoint('RIGHT', t, 'RIGHT', 0, 0) b3:SetSize(fade, h)
	b2:ClearAllPoints() b2:SetPoint('LEFT', b1, 'RIGHT', 0, 0) b2:SetSize(math.max(1, width - 2 * fade), h)
	Theme:Gradient(b1, 'HORIZONTAL', glass, glass, 0, a)
	Theme:Gradient(b2, 'HORIZONTAL', glass, glass, a, a)
	Theme:Gradient(b3, 'HORIZONTAL', glass, glass, a, 0)
	-- accent line under the letters, fading away from the title's aligned side
	local accent = t.fixedStyle or self.DETAILS_ACCENT[t.attribute or t.index] or style -- the colour family of what the window shows
	t.accent:ClearAllPoints()
	t.accent:SetSize(math.max(1, width - 2 * T.pad + 18), T.accent)
	if t.side == 'CENTER' then
		t.accent:SetPoint('TOP', t, 'BOTTOM', 0, T.size / 2 - h / 2 - T.gap)
		Theme:Gradient(t.accent, 'HORIZONTAL', accent.bright, accent.deep, 1, 1)
	elseif t.side == 'LEFT' then
		t.accent:SetPoint('TOPLEFT', t, 'BOTTOMLEFT', T.pad, T.size / 2 - h / 2 - T.gap)
		Theme:Gradient(t.accent, 'HORIZONTAL', accent.bright, accent.deep, 1, 0)
	else
		t.accent:SetPoint('TOPRIGHT', t, 'BOTTOMRIGHT', -T.pad, T.size / 2 - h / 2 - T.gap)
		Theme:Gradient(t.accent, 'HORIZONTAL', accent.deep, accent.bright, 0, 1)
	end
end

-- 1.3.5 the divider's place: the frame's centre, from `pad` x d below the top stalk (its lower edge: outer + d)
-- to `pad` x d above the bottom one, `px` screen pixels wide at the frame's scale
function Compat:LayoutDetailsDivider()
	local frame = self.detailsFrame
	local parts = frame and frame.divider
	if not parts then return end
	local V, P = self.DETAILS_DIVIDER, self.PANEL
	local d = StalkDiameter()
	local width = V.px / Theme.PixelScale(frame)
	local top = P.outer + d + V.pad * d
	local bottom = frame.bh - (P.outer + d + V.pad * d)
	local fade = math.min(V.fade, (bottom - top) / 4)
	local section = (bottom - top - 2 * fade) / (#self.DIVIDER_STOPS - 1)
	local x, y = frame.bw / 2 - width / 2, top
	for i, t in ipairs(parts) do
		local h = (i == 1 or i == #parts) and fade or section
		t:ClearAllPoints()
		t:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, -y)
		t:SetSize(width, h)
		y = y + h
	end
	frame.dividerTop, frame.dividerBottom, frame.dividerWidth = top, bottom, width
end

-- top to bottom lime -> green -> emerald -> violet -> purple, both ends fading out; the alpha for the material
function Compat:PaintDetailsDivider()
	local frame = self.detailsFrame
	local parts = frame and frame.divider
	if not parts then return end
	local V, S = self.DETAILS_DIVIDER, self.DIVIDER_STOPS
	local a = Theme:DB().panelBackground == 'PARCHMENT' and V.parchment or V.alpha
	-- a vertical gradient takes its first colour at the bottom
	for i, t in ipairs(parts) do
		if i == 1 then
			Theme:Gradient(t, 'VERTICAL', S[1], S[1], a, 0)
		elseif i == #parts then
			Theme:Gradient(t, 'VERTICAL', S[#S], S[#S], 0, a)
		else
			Theme:Gradient(t, 'VERTICAL', S[i], S[i - 1], a, a)
		end
	end
end

function Compat:UpdateDetailsTitles()
	for _, t in ipairs(self.detailsTitles or {}) do
		if t:IsShown() then
			local attribute = DetailsAttribute(t.index)
			if attribute ~= t.attribute then
				t.attribute = attribute
				self:LayoutDetailsTitle(t)
			end
		end
	end
end

---------------------------------------------------------------------------
-- Chat (lower left): the same outer size as Details, its own gradient direction
---------------------------------------------------------------------------
function Compat:BuildChat()
	local C = self.CHAT
	local frame = NewHolder(UIParent, 'BACKGROUND', C.width, C.height)
	frame:SetFrameLevel(0)
	frame.artKind = 'chat'
	frame.flushLeft = C.left -- 1.2.0: on the left screen edge
	BambooFrame(frame, false, true)
	self.chatFrame = frame
	-- 0.8.0: CHAT on the top border, the DAMAGE / HEALING title treatment
	local title = self:DetailsTitle(frame, 0, 'CENTER')
	title.fixedStyle = self.CHAT_TITLE
	self.chatTitle = title
end

function Compat:PlaceChat()
	local frame = self.chatFrame
	if not frame then return end
	local db = Theme:DB()
	frame:ClearAllPoints()
	frame:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', self.CHAT.left, (db.barHeight or 32) - self.BAND.outer)
end

---------------------------------------------------------------------------
-- 1.2.0 BUFFS panel (top-left): the bamboo frame around ElvUI's own buff icons
---------------------------------------------------------------------------
-- The icons, their tooltips, right-click cancelling and timers stay ElvUI's
-- (its buff header and BuffsMover; BushidoPrivateRestore writes the position,
-- 10 per row and 2 / 3 rows into the Banzai profile). The panel only frames
-- them: sized from ElvUI's buff settings for the chosen number of rows,
-- anchored to the buffs' mover, never in front of them, never taking a click.
local function BuffsHeader()
	return _G.ElvUIPlayerBuffs
end

-- the icon block (units): ElvUI's buff size / spacing for `perRow` x rows
function Compat:BuffsBlock()
	local B = self.BUFFS
	local E = Engine()
	local db = E and E.db and E.db.auras and E.db.auras.buffs or {}
	local function num(v, default) return (type(v) == 'number' and v > 0) and v or default end -- ElvUI's saved settings: plain numbers
	local size = num(db.size, B.size)
	local height = db.keepSizeRatio and size or num(db.height, B.height)
	local perRow = math.max(1, math.min(20, math.floor(num(db.wrapAfter, B.perRow))))
	local spacing, rowGap = num(db.horizontalSpacing, B.spacing), num(db.verticalSpacing, B.rowGap)
	local rows = Theme:DB().buffsRows
	return perRow * size + (perRow - 1) * spacing, rows * height + (rows - 1) * rowGap, rows, perRow
end

-- 1.2.1: the panel's geometry is deterministic - Banzai's configured rows and
-- ElvUI's buff settings (size, spacing, per row) only. 1.2.0 grew the panel by
-- a row while ElvUI's weapon-enchant icons overflowed, counted from the shown
-- state of the icons in ElvUI's buff header (an AuraContainer): on Midnight
-- those icons' IsShown() is a secret boolean (the client shows / hides them
-- from aura data), and testing it raised a Lua error. Banzai never reads the
-- buff icons, their visibility, the auras or the weapon enchants: ElvUI lays
-- the icons out (weapon enchants are up to two more icons before the buffs,
-- outside its rows x 10; the debuffs keep a row free below the panel for them).
function Compat:SizeBuffs()
	local frame = self.buffsFrame
	if not frame then return end
	local B, P = self.BUFFS, self.PANEL
	local w, h, rows = self:BuffsBlock()
	local side = P.outer + StalkDiameter() + B.pad
	local bottom = P.outer + StalkDiameter() + B.padBottom
	local W, H = w + 2 * side, h + side + bottom
	frame.inset, frame.rows = side, rows
	if frame.bw ~= W or frame.bh ~= H then
		frame.bw, frame.bh = W, H
		frame:SetSize(W, H)
	end
end

function Compat:BuildBuffs()
	local frame = NewHolder(UIParent, 'BACKGROUND', 100, 100)
	frame:SetFrameLevel(0)
	frame.artKind = 'buffs'
	self.buffsFrame = frame
	self:SizeBuffs()
	BambooFrame(frame, false, false)
	local title = self:DetailsTitle(frame, 0, 'CENTER')
	title.fixedStyle, title.bottom = self.BUFFS_TITLE, true
	self.buffsTitle = title
end

-- on the buffs' mover (ElvUI's buff header sits at its top-left), else at the Banzai position
function Compat:PlaceBuffs(active)
	local frame = self.buffsFrame
	if not frame then return end
	local db = Theme:DB()
	local inset = frame.inset or 0
	local anchor = _G.BuffsMover or BuffsHeader()
	frame:ClearAllPoints()
	if anchor then
		frame:SetPoint('TOPLEFT', anchor, 'TOPLEFT', -inset, inset)
	else
		frame:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', db.buffsX - inset, -(db.buffsY - inset))
	end
	local visible = active and db.buffsPanel and BuffsHeader() ~= nil and true or false
	frame:SetShown(visible)
	if self.buffsTitle then
		self.buffsTitle:SetShown(visible)
		if visible then self:LayoutDetailsTitle(self.buffsTitle) end
	end
end

---------------------------------------------------------------------------
-- BANZAI wordmark: small at the top centre; in combat larger between Player
-- and Target with the miniature tree behind it
---------------------------------------------------------------------------
-- 1.0.0: a left click on the wordmark opens the BANZAI settings on HOME
-- (BushidoPrivateRestore Options.Open). Nothing of its look changes: an
-- invisible click area `pad` units larger than the letters, on hover the
-- letters a touch brighter and the tooltip "Open Banzai Settings". In combat
-- it opens nothing and says so in one line; the large combat wordmark and its
-- tree are never clickable.
Compat.LOGO_CLICK = { pad = 6, glow = 0.35 }

function Compat:BuildLogo()
	local L = self.LOGO
	local frame = CreateFrame('Frame', 'BanzaiLogo', UIParent)
	frame:SetFrameStrata('BACKGROUND')
	frame:SetSize(L.height * 4, L.height) -- texture is 512 x 128
	frame:EnableMouse(false)
	frame.texture = frame:CreateTexture(nil, 'ARTWORK')
	frame.texture:SetAllPoints()
	frame.texture:SetTexture(WORDMARK)
	-- hover: the same letters once more on top, added, faint
	frame.glow = frame:CreateTexture(nil, 'ARTWORK', nil, 1)
	frame.glow:SetAllPoints()
	frame.glow:SetTexture(WORDMARK)
	if frame.glow.SetBlendMode then frame.glow:SetBlendMode('ADD') end
	frame.glow:SetAlpha(self.LOGO_CLICK.glow)
	frame.glow:Hide()
	local pad = self.LOGO_CLICK.pad
	local button = CreateFrame('Button', 'BanzaiLogoButton', frame)
	button:SetPoint('TOPLEFT', frame, 'TOPLEFT', -pad, pad)
	button:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', pad, -pad)
	button:RegisterForClicks('LeftButtonUp')
	button:SetScript('OnClick', function(_, mouse) Compat:LogoClick(mouse) end)
	button:SetScript('OnEnter', function(b) Compat:LogoHover(b, true) end)
	button:SetScript('OnLeave', function(b) Compat:LogoHover(b, false) end)
	button:SetScript('OnHide', function(b) Compat:LogoHover(b, false) end)
	frame.button = button
	self.logo = frame
end

function Compat:LogoHover(button, on)
	local logo = self.logo
	if logo and logo.glow then logo.glow:SetShown(on and true or false) end
	local tip = ns.Tooltip
	if not tip then return end
	if on then
		local tt = tip:Begin(button, 'BOTTOM')
		if not tt then return end
		tt:AddLine('Open Banzai Settings', 1, 1, 1)
		tt:AddLine('Left-click: BANZAI > HOME', 0.62, 1.00, 0.12)
		tip:Finish(tt)
	else
		tip:End(button)
	end
end

function Compat:LogoClick(mouse)
	if mouse and mouse ~= 'LeftButton' then return false end
	if InCombatLockdown() then
		print('|cff00ccffBanzai|r: settings cannot open in combat.')
		return false
	end
	local open = _G.BanzaiOpenSettings
	if type(open) ~= 'function' then
		print('|cff00ccffBanzai|r: the BANZAI settings are part of the Banzai addon, which is not loaded.')
		return false
	end
	return open('home')
end

function Compat:PlaceLogo()
	local frame = self.logo
	if not frame then return end
	frame:ClearAllPoints()
	frame:SetPoint('TOP', UIParent, 'TOP', 0, self.LOGO.top)
end

---------------------------------------------------------------------------
-- 1.3.8 launcher host: BanzaiSland presents the top-centre identity itself (its integrated BANZAI SLAND
-- wordmark, whose BANZAI half opens these settings through BanzaiOpenSettings). While it does, the
-- small standalone wordmark steps aside; the saved `logo` preference is never written, so the moment
-- the host goes (BanzaiSland disabled, blocked or absent on the next login) the preference decides
-- again. showStandaloneLauncher = db.logo AND no external host. Two sides, both handled:
--   push  BanzaiCompat.SetLauncherHost('BanzaiSland') / SetLauncherHost(nil) - BanzaiSland calls this
--         when its wordmark appears or goes (it also accepts the (name, on) form)
--   pull  BanzaiSlandAPI.HostsBanzaiLauncher() - asked at every UpdateBranding, so whichever addon
--         loads first, the branding settles at Build without duplication. No polling, no timers.
---------------------------------------------------------------------------
Compat.launcherHost = nil
function Compat.SetLauncherHost(host, on)
	if on == false then host = nil end
	if type(host) ~= 'string' or host == '' then host = nil end
	Compat.launcherHost = host
	Compat:UpdateBranding()
	return host
end

function Compat:LauncherHosted()
	if self.launcherHost then return true end
	local api = _G.BanzaiSlandAPI
	if type(api) == 'table' and type(api.HostsBanzaiLauncher) == 'function' then
		local ok, hosted = pcall(api.HostsBanzaiLauncher)
		return ok and hosted == true
	end
	return false
end

function Compat:BuildCombatLogo()
	local L, C = self.LOGO, self.COMBAT
	local w, h = L.height * 4 * C.scale, L.height * C.scale
	local frame = CreateFrame('Frame', 'BanzaiCombatLogo', UIParent)
	frame:SetFrameStrata('BACKGROUND')
	frame:SetSize(math.max(w, C.tree), C.tree)
	frame:EnableMouse(false)
	frame.tree = frame:CreateTexture(nil, 'ARTWORK', nil, 0)
	frame.tree:SetTexture(BONSAI)
	frame.tree:SetSize(C.tree, C.tree)
	frame.tree:SetPoint('CENTER', frame, 'CENTER', 0, 0)
	frame.wordmark = frame:CreateTexture(nil, 'ARTWORK', nil, 3) -- above the tree: the letters are never covered
	frame.wordmark:SetTexture(WORDMARK)
	frame.wordmark:SetSize(w, h)
	frame.wordmark:SetPoint('CENTER', frame, 'CENTER', 0, -C.lift)
	if frame.CreateAnimationGroup then
		local fade = frame:CreateAnimationGroup()
		local alpha = fade:CreateAnimation('Alpha')
		alpha:SetFromAlpha(0)
		alpha:SetToAlpha(1)
		alpha:SetDuration(C.fade)
		frame.fade = fade
	end
	frame:Hide()
	self.combatLogo = frame
end

-- the letters sit centred between the Player and Target health bars
function Compat:PlaceCombatLogo()
	local frame = self.combatLogo
	if not frame then return end
	local C = self.COMBAT
	frame:ClearAllPoints()
	local pl, pb, pw, ph = Rect(_G.ElvUF_Player and _G.ElvUF_Player.Health)
	local tl, tb, _, th = Rect(_G.ElvUF_Target and _G.ElvUF_Target.Health)
	if pl and tl and tl > pl + pw then
		local x = (pl + pw + tl) / 2
		local y = ((pb + ph / 2) + (tb + th / 2)) / 2
		frame:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', x, y + C.lift)
	else
		frame:SetPoint('CENTER', UIParent, 'CENTER', 0, C.fallbackY + C.lift)
	end
end

function Compat:UpdateBranding()
	local db = Theme:DB()
	local active = Active()
	local split = ns.Split and ns.Split.Session and ns.Split:Session() -- 1.3.0: the small wordmark stays in a split session
	local combat = active and db.combatLogo and self.inCombat and not split and true or false
	if self.logo then
		self:PlaceLogo()
		-- 1.3.8: hidden while an external host (BanzaiSland) presents the identity; db.logo itself untouched
		self.logo:SetShown(active and db.logo and not combat and not self:LauncherHosted() and true or false)
	end
	local frame = self.combatLogo
	if frame then
		local was = frame:IsShown()
		if combat then self:PlaceCombatLogo() end
		frame:SetShown(combat)
		if combat and not was and frame.fade then frame.fade:Play() end
	end
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------
function Compat:Build()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = false
	local db = Theme:DB()
	local split = ns.Split and ns.Split.Session and ns.Split:Session()
	for _, def in ipairs(G.units) do
		local scale = (def.frame == 'ElvUF_TargetTarget') and (db.totScale or 1) or 1
		if not (split and self.SPLIT_FRAMES[def.frame]) then
			Decorate(_G[def.frame], def.parts, scale, nil, not self.END_ART[def.frame], self.DESIGN_WIDTH[def.frame])
		end
	end
	for i = 1, 5 do
		Decorate(_G['ElvUF_PartyGroup1UnitButton' .. i], G.party, nil, nil, true)
	end
	for _, raid in ipairs({ 'Raid1', 'Raid2', 'Raid3' }) do
		for group = 1, 8 do
			for i = 1, 5 do
				Decorate(_G['ElvUF_' .. raid .. 'Group' .. group .. 'UnitButton' .. i], G.raid)
			end
		end
	end
	for i = 1, 8 do
		Decorate(_G['ElvUF_Boss' .. i], G.boss)
	end
	for i = 1, 5 do
		Decorate(_G['ElvUF_Arena' .. i], self.ARENA_PARTS)
	end
	if _G.Minimap and not decorated[_G.Minimap] then
		decorated[_G.Minimap] = true
		self:BuildMinimap(_G.Minimap)
	end
	if not self.screenBuilt then
		self.screenBuilt = true
		self:BuildDetails()
		self:BuildChat()
		self:BuildBuffs()
		self:BuildLogo()
		self:BuildCombatLogo()
	end
	if ns.Health and ns.Health.Build then ns.Health:Build() end
	self:Refresh()
end

---------------------------------------------------------------------------
-- Theme and settings
---------------------------------------------------------------------------
function Compat:GetTheme()
	return Theme:DB().theme
end

local MODULES = { 'Tracker', 'CastHistory', 'ActionButtons', 'TargetPlate', 'Identity', 'Split', 'PvPFrames', 'CooldownBars', 'Tooltip', 'AFK' }
local function RefreshAll(self)
	self:Refresh()
	for _, name in ipairs(MODULES) do
		local module = ns[name]
		if module and module.Refresh then module:Refresh() end
	end
end
Compat.RefreshAll = RefreshAll

function Compat:SetTheme(mode)
	mode = type(mode) == 'string' and string.upper(mode) or ''
	if mode ~= 'VIBRANT' and mode ~= 'CLASS' then return false end
	Theme:DB().theme = mode
	RefreshAll(self)
	return true
end

function Compat:Set(key, value)
	local db = Theme:DB()
	if Theme.DEFAULTS[key] == nil then return false end
	db[key] = value
	RefreshAll(self)
	return true
end

function Compat:Get(key)
	return Theme:DB()[key]
end

-- Character Sync (BushidoPrivateRestore): this character's synced settings
function Compat:Export(key)
	return Theme:Export(key)
end

function Compat:Import(values, key)
	Theme:Import(values, key)
	if not key or key == Theme.CharKey() then RefreshAll(self) end
	return true
end

-- per-role frame positions this character keeps (Roles.lua in BushidoPrivateRestore)
function Compat:Roles()
	local db = Theme:DB()
	if type(db.roles) ~= 'table' then db.roles = {} end
	return db.roles
end

-- which role layout was last written for this character, and what (not synced)
function Compat:RoleState()
	local db = Theme:DB()
	if type(db.roleState) ~= 'table' then db.roleState = {} end
	return db.roleState
end

function Compat:ForeverRoleOverride(value)
	local db = Theme:DB()
	if value ~= nil then
		if value == 'AUTO' then db.foreverRoleOverride = nil else db.foreverRoleOverride = value end
	elseif db.foreverRoleOverride ~= 'DPS' and db.foreverRoleOverride ~= 'HEALER' then
		db.foreverRoleOverride = nil
	end
	return db.foreverRoleOverride or 'AUTO'
end

function Compat:ApplyTheme()
	for _, paint in ipairs(painters) do paint() end
end

---------------------------------------------------------------------------
-- Health border, layering, Details placement, visibility
---------------------------------------------------------------------------
local function SetHealthBorder(frame, hidden)
	local E = Engine()
	local backdrop = frame and frame.Health and frame.Health.backdrop
	if not (E and E.ForceBorderColor and backdrop and backdrop.SetBackdropBorderColor) then return end
	if hidden then
		E:ForceBorderColor(backdrop, 0, 0, 0, 0) -- kept by ElvUI when it re-templates the bar
		backdrop:SetBackdropBorderColor(0, 0, 0, 0)
		backdrop.banzaiBorder = true
	elseif backdrop.banzaiBorder then
		backdrop.banzaiBorder = nil
		E:ForceBorderColor(backdrop)
		local c = E.media and E.media.unitframeBorderColor
		if c then backdrop:SetBackdropBorderColor(c[1], c[2], c[3], 1) end
	end
end

local function RaiseEnd(holder)
	local frame = holder.unitFrame
	local level = 0
	for _, key in ipairs({ 'Health', 'Power' }) do
		local element = frame and frame[key]
		local value = element and element.GetFrameLevel and element:GetFrameLevel()
		if type(value) == 'number' and not IsSecret(value) and value > level then level = value end
	end
	if level > 0 then holder:SetFrameLevel(math.min(level + 2, 95)) end -- under ElvUI's raised texts (100)
end

local function DetailsWindow(id)
	local details = _G.Details
	local window = details and details.GetInstance and details:GetInstance(id)
	if not (window and window.baseframe) then return nil, details ~= nil and details.GetInstance ~= nil end
	local open = window.IsEnabled and window:IsEnabled()
	return open and window.baseframe or nil, true
end

-- The Banzai Details frame follows the right window (window 2); without
-- Details' window API it sits at the Banzai default spot.
function Compat:PlaceDetails(active)
	local frame = self.detailsFrame
	if not frame then return end
	local D = self.DETAILS
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded('Details')
	local base, hasApi = nil, false
	if loaded then base, hasApi = DetailsWindow(2) end
	frame:ClearAllPoints()
	if base then
		frame:SetPoint('CENTER', base, 'BOTTOMRIGHT', D.centerX, D.centerY)
	else
		local bottom = (Theme:DB().barHeight or 32) + 10
		frame:SetPoint('CENTER', UIParent, 'BOTTOMRIGHT', D.right + D.centerX, bottom + D.centerY)
	end
	local db = Theme:DB()
	local visible = active and loaded and db.detailsFrame and (base ~= nil or not hasApi) and true or false
	frame:SetShown(visible)
	for i, title in ipairs(self.detailsTitles or {}) do
		local window = loaded and DetailsWindow(i)
		local shown = visible and window ~= nil and true or false
		title:SetShown(shown)
		if shown then
			title.attribute = DetailsAttribute(i)
			self:LayoutDetailsTitle(title)
		end
	end
	-- 1.3.5 the divider: with the frame, while both meters are open
	if frame.divider then
		local both = visible and loaded and DetailsWindow(1) ~= nil and DetailsWindow(2) ~= nil or false
		if both then self:LayoutDetailsDivider() end
		for _, t in ipairs(frame.divider) do t:SetShown(both) end
	end
end

function Compat:Refresh()
	local active = Active()
	local db = Theme:DB()
	for _, holder in ipairs(holders) do
		holder:SetShown(active)
	end
	for _, holder in ipairs(ends) do
		holder:SetShown(active and db.bambooArt and true or false)
		RaiseEnd(holder)
	end
	self:SizeMinimapFrame()
	self:SizeBuffs()
	for _, holder in ipairs(bands) do LayoutBamboo(holder) end
	local map = self.minimapFrame
	if map then
		map:SetShown(active and db.minimapFrame and true or false)
		self:UpdateZone()
		self:UpdateMinimapMask()
	end
	self:RefreshMinimapButtonBar()
	if self.chatFrame then
		self:PlaceChat()
		self.chatFrame:SetShown(active and db.chatFrame and true or false)
		if self.chatTitle then
			self.chatTitle:SetShown(active and db.chatFrame and true or false)
			self:LayoutDetailsTitle(self.chatTitle)
		end
	end
	for frame in pairs(bordered) do
		SetHealthBorder(frame, active)
	end
	self:PlaceDetails(active)
	self:PlaceBuffs(active)
	-- 1.3.5: Banzai Art switched off (a profile / style switch): every Banzai PvP visual put away at once
	if not active and ns.PvPFrames and ns.PvPFrames.Sweep then ns.PvPFrames:Sweep() end
	self:ApplyTheme()
	self:UpdateBranding()
	if ns.Bar and ns.Bar.Refresh then ns.Bar:Refresh() end
	if ns.Health and ns.Health.Refresh then ns.Health:Refresh() end
	-- 1.0.0: the tooltip glass and the AFK screen follow a profile switch at once (Backup & Restore)
	if ns.Tooltip and ns.Tooltip.Refresh then ns.Tooltip:Refresh() end
	if ns.AFK and ns.AFK.Refresh then ns.AFK:Refresh() end
	-- 1.5.0-dev3: the Forever chat windows inside the chat frame, and the optional window skins. Each on its
	-- own: a failure in one never reaches the HUD above (the reason is kept for /banzai forever).
	-- (not on a group / arena roster change: that rebuild is about unit frames only - the chat windows and the
	-- skinned windows have nothing to do with who joined, and a window that shows is looked at then anyway)
	for _, name in ipairs({ 'ChatLayout', 'Skins' }) do
		local module = ns[name]
		if module and module.Refresh and not self.rosterBuild then
			local ok, err = pcall(module.Refresh, module)
			if not ok then module.lastError = tostring(err) end
		end
	end
end

function Compat:Counts()
	return { holders = #holders, painters = #painters, ends = #ends, bands = #bands }
end

-- 1.1.0: the panel style, for the status line and the tests
function Compat:PanelStyle()
	local db = Theme:DB()
	return db.panelBorder, db.panelBackground, BorderScale()
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local frame = CreateFrame('Frame')
local events = { 'ADDON_LOADED', 'PLAYER_ENTERING_WORLD', 'PLAYER_REGEN_DISABLED', 'PLAYER_REGEN_ENABLED', 'GROUP_ROSTER_UPDATE', 'ARENA_OPPONENT_UPDATE',
	'PLAYER_SPECIALIZATION_CHANGED', 'ZONE_CHANGED', 'ZONE_CHANGED_INDOORS', 'ZONE_CHANGED_NEW_AREA' }
for _, event in ipairs(events) do pcall(frame.RegisterEvent, frame, event) end

-- each module refreshes on its own, so one failing piece never keeps the others from showing
local function SafeRefresh(module)
	if module and module.Refresh then
		local ok, err = pcall(module.Refresh, module)
		if not ok then Compat.lastError = tostring(err) end
	end
end

frame:SetScript('OnEvent', function(_, event)
	if event == 'ADDON_LOADED' then
		Compat:HookMinimapButtonBar()
	elseif event == 'PLAYER_ENTERING_WORLD' then
		C_Timer.After(1, function()
			Compat:HookMinimapButtonBar()
			local E = Engine()
			if E and E.data and E.data.RegisterCallback and not Compat.callbacks then
				Compat.callbacks = true
				E.data.RegisterCallback(Compat, 'OnProfileChanged', 'Refresh')
				E.data.RegisterCallback(Compat, 'OnProfileCopied', 'Refresh')
				E.data.RegisterCallback(Compat, 'OnProfileReset', 'Refresh')
			end
			Compat.inCombat = InCombatLockdown()
			local ok, err = pcall(Compat.Build, Compat)
			if not ok then Compat.lastError = tostring(err) end
			for _, name in ipairs(MODULES) do SafeRefresh(ns[name]) end
		end)
		-- Details windows open / move a little later (profile switch and Banzai layout at login)
		C_Timer.After(5, function()
			Compat:PlaceDetails(Active())
			Compat:UpdateMinimapMask()
			-- 1.5.0-dev3: once more after ElvUI has placed its chat windows and the meters are in place
			if ns.ChatLayout then pcall(ns.ChatLayout.Refresh, ns.ChatLayout, 'login') end
		end)
		C_Timer.After(10, function() Compat:PlaceDetails(Active()) end)
	elseif event == 'PLAYER_REGEN_DISABLED' then
		Compat.inCombat = true
		Compat:UpdateBranding()
	elseif event == 'PLAYER_REGEN_ENABLED' then
		Compat.inCombat = false
		if pending then Compat:Build() end
		if Compat.minimapButtonsPending then Compat:RefreshMinimapButtonBar() end
		Compat:UpdateBranding()
	elseif event == 'GROUP_ROSTER_UPDATE' or event == 'ARENA_OPPONENT_UPDATE' then
		if InCombatLockdown() then
			pending = true
		else
			Compat.rosterBuild = true -- 1.5.0-dev3: unit frames only (see Compat:Refresh)
			local ok, err = pcall(Compat.Build, Compat)
			Compat.rosterBuild = nil
			if not ok then error(err, 0) end -- (the flag never outlives the build; the error is raised as before)
		end
	elseif event == 'PLAYER_SPECIALIZATION_CHANGED' then
		if Theme:DB().theme == 'CLASS' or Theme:DB().panelBorder == 'CLASS' then RefreshAll(Compat) end
	elseif event == 'ZONE_CHANGED' or event == 'ZONE_CHANGED_INDOORS' or event == 'ZONE_CHANGED_NEW_AREA' then
		Compat:UpdateZone()
		Compat:UpdateMinimapMask()
	end
end)
