--[[
	BANZAI - SkinAdapters.lua  (Banzai Art)
	1.5.0-dev3 (private Forever proof): which windows BANZAI Window Skin
	(Skins.lua) dresses, and where their owners keep them. Every name below
	was read from the addons installed in the WoW Forever client (ElvUI 16.01
	Game\load_forever.xml and its Shared\Skins files, Baganator 847, Zygor
	Guides Viewer Forever 1.6); nothing is assumed from Retail.

	An adapter only NAMES windows and says when they are ready. It never
	calls, replaces or wraps a function that decides anything in its addon.

	BLIZZARD WINDOWS (Tier 1) - the game's own windows, as ElvUI's Blizzard
	skins leave them: ElvUI has already taken the stock art off and given the
	window its panel (S:HandlePortraitFrame / S:HandleFrame). BANZAI lays its
	surface on that panel. A window ElvUI has not skinned (its ElvUI skin is
	switched off) is NOT READY and stays untouched: BANZAI strips nothing.

	  Character            CharacterFrame        Blizzard_UIPanels_Game
	  Spellbook / Talents  PlayerSpellsFrame     Blizzard_PlayerSpells (one window on Forever: abilities and talent trees)
	  Professions          ProfessionsFrame      Blizzard_Professions
	  Quest Log            WorldMapFrame         (the quest log is the map's side pane on this client)
	  Quest                QuestFrame            Blizzard_UIPanels_Game
	  Merchant             MerchantFrame         Blizzard_UIPanels_Game
	  Gossip               GossipFrame           Blizzard_UIPanels_Game
	  Trainer              ClassTrainerFrame     Blizzard_TrainerUI
	  Mail                 MailFrame, OpenMailFrame   Blizzard_MailFrame
	  Friends              FriendsFrame
	  Guild                CommunitiesFrame      Blizzard_Communities
	  Inspect              InspectFrame          Blizzard_InspectUI
	  Trade                TradeFrame            Blizzard_UIPanels_Game

	BAGANATOR - Baganator is the bag addon; BANZAI builds no bag. Baganator
	announces every region it makes through its public skin API
	(Baganator.API.Skins.RegisterListener / GetAllFrames, API\Main.lua); the
	adapter keeps the windows among them (regionType "ButtonFrame": backpack,
	bank, guild bank and their side windows) and nothing else - no item
	button, search box, tab, category or scroll bar is touched. Skinned while
	Baganator's own theme is ElvUI (its panel is then an ElvUI template like
	the game's windows); with another Baganator theme the adapter stands by.

	ZYGOR - see the Zygor section below.
]]
local _, ns = ...
local Skins = ns.Skins
if not Skins then return end
local Usable = Skins.Usable

local Adapters = {}
ns.SkinAdapters = Adapters

-- the heading of a window built on the game's ButtonFrameTemplate / PortraitFrame, wherever this client keeps it
function Adapters.Title(window)
	local box = window.TitleContainer
	local fs = type(box) == 'table' and box.TitleText or nil
	if not fs and type(window.GetTitleText) == 'function' then
		local ok, found = pcall(window.GetTitleText, window)
		fs = ok and found or nil
	end
	if not fs then fs = window.TitleText end
	if not fs and window.GetName then
		local name = window:GetName()
		if type(name) == 'string' then fs = _G[name .. 'TitleText'] end
	end
	return fs
end

-- ready when ElvUI has given the window its panel (never before: BANZAI does not strip the stock art itself)
local function ElvUISkinned(_, spec)
	if Skins.Base(spec.frame) then return true end
	return false, 'ElvUI has not skinned it'
end

-- Art another addon lays over a whole window, by that addon's own setting (read from the installed Eltruism:
-- its expanded character art is the texture "EltruismCharacterBG" on CharacterFrame, ARTWORK). BANZAI's surface
-- is under the window's content, so it stays under that art: nothing is hidden or reordered, and the status
-- says so instead of claiming a look the window does not show.
Adapters.COVERS = { CharacterFrame = { 'EltruismCharacterBG', 'Eltruism\'s character art covers the body (its own setting); the heading face and the surface under it are BANZAI\'s' } }
function Adapters.CoveredBy(name)
	local cover = Adapters.COVERS[name]
	local art = cover and _G[cover[1]]
	if not (Usable(art) and art.IsShown) then return nil end
	local ok, shown = pcall(art.IsShown, art)
	if ok and shown == true then return cover[2] end
	return nil
end

---------------------------------------------------------------------------
-- Blizzard windows, Tier 1
---------------------------------------------------------------------------
-- { id, label, the Blizzard addon whose load brings the window (nil: there at login), frames, noHeader }
Adapters.BLIZZARD = {
	{ 'character', 'Character', 'Blizzard_UIPanels_Game', { 'CharacterFrame' } },
	{ 'spells', 'Spellbook / Talents', 'Blizzard_PlayerSpells', { 'PlayerSpellsFrame' } },
	{ 'professions', 'Professions', 'Blizzard_Professions', { 'ProfessionsFrame' } },
	{ 'questlog', 'Quest Log', nil, { 'WorldMapFrame' }, true },
	{ 'quest', 'Quest', 'Blizzard_UIPanels_Game', { 'QuestFrame' } },
	{ 'merchant', 'Merchant', 'Blizzard_UIPanels_Game', { 'MerchantFrame' } },
	{ 'gossip', 'Gossip', 'Blizzard_UIPanels_Game', { 'GossipFrame' } },
	{ 'trainer', 'Trainer', 'Blizzard_TrainerUI', { 'ClassTrainerFrame' } },
	{ 'mail', 'Mail', 'Blizzard_MailFrame', { 'MailFrame', 'OpenMailFrame' } },
	{ 'friends', 'Friends', nil, { 'FriendsFrame', 'SocialUIFrame' } }, -- (ElvUI Friends.lua skins both; whichever this client shows)
	{ 'guild', 'Guild', 'Blizzard_Communities', { 'CommunitiesFrame' } },
	{ 'inspect', 'Inspect', 'Blizzard_InspectUI', { 'InspectFrame' } },
	{ 'trade', 'Trade', 'Blizzard_UIPanels_Game', { 'TradeFrame' } },
}

for _, def in ipairs(Adapters.BLIZZARD) do
	local frames, noHeader = def[4], def[5]
	Skins:Register({
		id = 'blizzard.' .. def[1], group = 'blizzard', label = def[2], addon = def[3],
		ready = ElvUISkinned,
		windows = function()
			local list = {}
			for _, name in ipairs(frames) do
				local window = _G[name]
				if Usable(window) then
					list[#list + 1] = { frame = window, title = (not noHeader) and Adapters.Title or nil, header = (not noHeader) and Skins.HEADER or nil,
						note = Adapters.CoveredBy(name) }
				end
			end
			return list
		end,
	})
end

---------------------------------------------------------------------------
-- Baganator
---------------------------------------------------------------------------
local Baganator = { id = 'baganator', group = 'baganator', label = 'Baganator windows', addon = 'Baganator', requires = 'Baganator' }
Adapters.Baganator = Baganator
Baganator.known = {}                                  -- the windows Baganator has announced, in order
Baganator.seen = setmetatable({}, { __mode = 'k' })

local function BaganatorSkins()
	local addon = _G.Baganator
	local api = type(addon) == 'table' and type(addon.API) == 'table' and addon.API.Skins
	return type(api) == 'table' and api or nil
end

-- a region Baganator announces: only its windows are kept ("ButtonFrame", a Frame); everything else is not BANZAI's
function Baganator:Note(details)
	if type(details) ~= 'table' or details.regionType ~= 'ButtonFrame' then return false end
	local region = details.region
	if not (Usable(region) and region.CreateTexture and region.IsObjectType and region:IsObjectType('Frame')) or self.seen[region] then return false end
	self.seen[region] = true
	self.known[#self.known + 1] = region
	return true
end

-- once, when Baganator is there: the windows it already made, then every later one (a new set after its
-- theme changes). Baganator calls the listener while the window is still being built, so the skin itself
-- waits one frame; one timer however many windows arrive together.
function Baganator:attach()
	local api = BaganatorSkins()
	if not api then return false end -- (not there yet: asked again at the next pass)
	if type(api.GetAllFrames) == 'function' then
		local ok, all = pcall(api.GetAllFrames)
		for _, details in ipairs((ok and type(all) == 'table') and all or {}) do self:Note(details) end -- read only: Baganator's own list
	end
	if type(api.RegisterListener) == 'function' then
		pcall(api.RegisterListener, function(details)
			if not Baganator:Note(details) or Baganator.queued then return end
			Baganator.queued = true
			local function run() Baganator.queued = false Skins:Touch(Baganator) end
			if C_Timer and C_Timer.After then C_Timer.After(0, run) else run() end
		end)
	end
end

function Baganator:windows()
	local list = {}
	for _, window in ipairs(self.known) do
		list[#list + 1] = { frame = window, title = Adapters.Title, header = Skins.HEADER }
	end
	return list
end

function Baganator:ready(spec)
	local api = BaganatorSkins()
	if not api then return false, 'Baganator\'s skin API is not there' end
	local current = type(api.GetCurrentSkin) == 'function' and select(2, pcall(api.GetCurrentSkin)) or nil
	if current ~= 'elvui' then return false, 'Baganator\'s own theme is "' .. tostring(current) .. '" - BANZAI skins its ElvUI theme' end
	if not Skins.Base(spec.frame) then return false, 'its ElvUI theme has not dressed this window yet' end
	return true
end

Skins:Register(Baganator)

---------------------------------------------------------------------------
-- Zygor Guides Viewer (Forever 1.6)
---------------------------------------------------------------------------
-- Read from the installed viewer, by frame and field name only (no Zygor code or data is copied here):
--   ZygorGuidesViewerFrame            the viewer (made once, never recreated)
--     .Border                         its body and title bar: a backdrop whose EDGE colour is the dark body
--       .Back                         the steps area (backdrop colour and edge colour)
--       .Toolbar                      the row with the step number
--       .TitleBar                     the bar with the ZYGOR logo (a texture), the menu and close buttons
--   :ApplySkin(), :AlignFrame()       Zygor's own skin pass; it sets those colours again whenever it runs
--                                     (startup, its options, a size change)
-- What BANZAI does: after Zygor's skin pass it sets those four colours to the BANZAI tone for the material
-- (each keeping the alpha Zygor gave it, so Zygor's own opacity option still works), and lays the accent
-- hairline along the title bar's bottom edge. Colour calls only - never SetBackdrop (Zygor aligns that
-- backdrop's pieces itself), never the viewer's alpha (Zygor's step completion reads it), never a size, an
-- anchor, a Show or a Hide. The two post-hooks (hooksecurefunc on the viewer frame's own ApplySkin /
-- AlignFrame) run after Zygor's function with its result untouched; they are needed because Zygor recolours
-- on every size change. Nothing runs per frame of its own.
--
-- What stays Zygor's, untouched: the guide, the steps and their lines, the goal colours (red incomplete,
-- green complete, grey impossible, violet warning - they mean something), the progress bar, the tabs, the
-- logo, every button and what it does, the step frames' own backdrops. PARCHMENT: the viewer's icons, logo and
-- text are light, so its bars keep the dark BANZAI tone - no parchment is laid under them.
-- Taking the skin off puts back the colours Zygor last set.
local Zygor = { id = 'zygor', group = 'zygor', label = 'Zygor guide viewer', addon = 'ZygorGuidesViewerForever', requires = 'ZygorGuidesViewerForever' }
Adapters.Zygor = Zygor
Zygor.own, Zygor.set = {}, {} -- [part] = { r, g, b, a }: what Zygor set last / what BANZAI set

-- the four colours, each: the object on the viewer, its getter and setter, the tone against the BANZAI glass colour
Zygor.PARTS = {
	{ id = 'body', path = { 'Border' }, get = 'GetBackdropBorderColor', put = 'SetBackdropBorderColor', tone = 0.9 },
	{ id = 'steps', path = { 'Border', 'Back' }, get = 'GetBackdropColor', put = 'SetBackdropColor', tone = 1.5 },
	{ id = 'stepsEdge', path = { 'Border', 'Back' }, get = 'GetBackdropBorderColor', put = 'SetBackdropBorderColor', tone = 1.5 },
	{ id = 'toolbar', path = { 'Border', 'Toolbar' }, get = 'GetBackdropColor', put = 'SetBackdropColor', tone = 2.4 },
}

function Zygor.Viewer()
	local viewer = _G.ZygorGuidesViewerFrame
	return Usable(viewer) and viewer or nil
end

local function Part(viewer, part)
	local obj = viewer
	for _, key in ipairs(part.path) do
		obj = type(obj) == 'table' and obj[key] or nil
	end
	if Usable(obj) and type(obj[part.get]) == 'function' and type(obj[part.put]) == 'function' then return obj end
	return nil
end

local function Read(obj, part)
	local r, g, b, a = obj[part.get](obj)
	if type(r) ~= 'number' or type(g) ~= 'number' or type(b) ~= 'number' then return nil end
	return { r, g, b, type(a) == 'number' and a or 1 }
end

local function Same(a, b)
	if not (a and b) then return false end
	for i = 1, 4 do
		if math.abs(a[i] - b[i]) > 0.002 then return false end
	end
	return true
end

function Zygor.Tone(part, material, ownAlpha)
	local g = ns.Theme.COLORS.glass
	local alpha = (material == 'GLASS') and math.max(Skins.GLASS_MIN, tonumber(ns.Theme:DB().glassOpacity) or 0.72) or ns.Theme.SOLID_ALPHA
	return { math.min(1, g[1] * part.tone), math.min(1, g[2] * part.tone), math.min(1, g[3] * part.tone), alpha * (ownAlpha or 1) }
end

-- the BANZAI tone on every part; a colour that is not the one BANZAI set last is Zygor's newest and is kept
function Zygor:Tint(material)
	local viewer = Zygor.Viewer()
	if not viewer then return 0 end
	local n = 0
	for _, part in ipairs(self.PARTS) do
		local obj = Part(viewer, part)
		local current = obj and Read(obj, part)
		if current then
			if not Same(current, self.set[part.id]) then self.own[part.id] = current end
			local own = self.own[part.id] or current
			local want = Zygor.Tone(part, material, own[4])
			if not Same(current, want) then obj[part.put](obj, want[1], want[2], want[3], want[4]) end
			self.set[part.id] = want
			n = n + 1
		end
	end
	self.material = material
	return n
end

-- Zygor's own colours back (only where the colour is still the one BANZAI set)
function Zygor:Untint()
	local viewer = Zygor.Viewer()
	local n = 0
	for _, part in ipairs(self.PARTS) do
		local obj = viewer and Part(viewer, part)
		local own, set = self.own[part.id], self.set[part.id]
		if obj and own and set and Same(Read(obj, part), set) then
			obj[part.put](obj, own[1], own[2], own[3], own[4])
			n = n + 1
		end
		self.set[part.id] = nil
	end
	self.material = nil
	return n
end

-- after Zygor's own skin pass: the tone again, while BANZAI owns the Zygor skin (a few colour comparisons)
function Zygor.AfterSkin()
	if not Skins:Owns('zygor') then return end
	local ok, err = pcall(Zygor.Tint, Zygor, Skins.Material())
	if not ok then Zygor.state.error = tostring(err) end
end

function Zygor:attach()
	local viewer = Zygor.Viewer()
	if not (viewer and hooksecurefunc) then return false end -- (the viewer is made when Zygor initialises: asked again at the next pass)
	for _, method in ipairs({ 'ApplySkin', 'AlignFrame' }) do
		if type(viewer[method]) == 'function' then hooksecurefunc(viewer, method, Zygor.AfterSkin) end
	end
end

function Zygor:windows()
	local viewer = Zygor.Viewer()
	local bar = viewer and type(viewer.Border) == 'table' and viewer.Border.TitleBar
	if not (Usable(bar) and bar.CreateTexture) then return {} end
	return { { frame = bar, anchor = bar, accentOnly = true } }
end

function Zygor:extra(_, on, material)
	if on then self:Tint(material) else self:Untint() end
end

Skins:Register(Zygor)
