--[[
	BANZAI - Skins.lua  (Banzai Art)
	1.5.0-dev3 (private Forever proof): BANZAI Window Skin - one optional,
	central way to give windows BANZAI does not own a restrained BANZAI
	surface. WoW Forever only in this proof (Skins.Supported): on Retail the
	adapters are listed and stay idle - no window gets a texture, a hook, a
	colour or a font from here (this file's one event frame listens, finds
	the client is not WoW Forever, and does nothing).

	BANZAI SKINS EXISTING WINDOWS. IT DOES NOT REIMPLEMENT THEM.

	  BANZAI owns        the surface it draws: background material, a thin
	                     border, the green -> violet accent hairline, the
	                     heading's typeface (and its ink on parchment)
	  the window's owner everything else: data, layout, buttons and what they
	                     do, secure interactions, sorting, search, navigation,
	                     guide / merchant / bag / trainer / quest logic

	How a window is skinned (the pattern of Tooltip.lua, approved since 1.0.0):
	plain textures on the window, under its content and over the backdrop its
	own skin (ElvUI, Baganator, Zygor) already gives it. Nothing of the window
	is stripped, hidden, moved, resized, re-parented or re-anchored; no
	function of its owner is replaced; no field is written onto it (BANZAI's
	textures are kept in a private table). Where the window's panel is an
	ElvUI template (the Banzai profile's panel colour is opaque black), its
	centre is made clear while the BANZAI surface is on - the alpha of its
	backdrop colour only, with the frame's own SetBackdropColor - so GLASS is
	really glass; ElvUI's border stays. Taking the skin off hides BANZAI's
	textures, gives the panel its alpha and the heading its own font and
	colour back - the window is then exactly its owner's again.

	Materials (BANZAI > APPEARANCE > PANEL STYLE > Background, shared with the
	chat / Details / BUFFS panels):
	  GLASS      the deep translucent BANZAI glass, never thinner than
	             Skins.GLASS_MIN so a window full of text stays readable
	  SOLID      the opaque BANZAI surface
	  PARCHMENT  surface-aware: the heading band is HARDKORH PARCHMENT with
	             dark ink (BANZAI sets that heading's colour, so it can);
	             the body under the owner's light text stays the SOLID dark
	             surface with a parchment-toned border. Parchment is never
	             laid under text BANZAI does not colour.

	Settings (Theme.DEFAULTS, per character, carried by Character Sync as
	visual preferences): skinBlizzard, skinBaganator, skinZygor, skinElvUI.
	Details and Chat are BANZAI's own approved frames: their switches are the
	existing detailsFrame / chatFrame settings - listed here, skinned by
	Compat.lua, never a second time.

	Lifecycle: an adapter (SkinAdapters.lua) names its windows. They are
	skinned when BANZAI builds (login / reload), when the adapter's addon
	loads later (ADDON_LOADED, one frame later so the owner's own skin ran
	first), and again whenever a window shows (a post-hook on its OnShow -
	idempotent, a few comparisons). No OnUpdate, no ticker, no rescan. In
	combat nothing is created or changed: the work waits for
	PLAYER_REGEN_ENABLED. A missing addon or window is simply ABSENT.
]]
local _, ns = ...
local Theme = ns.Theme
local Compat = ns.Compat

local Skins = { adapters = {}, byId = {}, pending = false }
ns.Skins = Skins
Compat.Skins = Skins

-- the switches of BANZAI > APPEARANCE > WINDOW SKINS, in their order. `owned`: a frame BANZAI already owns
-- and Compat.lua draws (its existing setting; no adapter, never skinned twice).
Skins.GROUPS = {
	{ id = 'blizzard', key = 'skinBlizzard', label = 'Blizzard Windows' },
	{ id = 'baganator', key = 'skinBaganator', label = 'Baganator' },
	{ id = 'zygor', key = 'skinZygor', label = 'Zygor' },
	{ id = 'details', key = 'detailsFrame', label = 'Details', owned = true },
	{ id = 'chat', key = 'chatFrame', label = 'Chat', owned = true },
	{ id = 'elvui', key = 'skinElvUI', label = 'ElvUI Panels', profile = true }, -- written into the Banzai profile by BushidoPrivateRestore
}
Skins.GROUP = {}
for _, group in ipairs(Skins.GROUPS) do Skins.GROUP[group.id] = group end

Skins.GLASS_MIN = 0.82                      -- a window's glass is at least this opaque
Skins.HEADER = 22                           -- a heading band's height (units) where an adapter gives none
Skins.ACCENT = 2                            -- the accent hairline, screen pixels
Skins.INK = { 0.17, 0.11, 0.05 }            -- the heading on parchment
Skins.EDGE = { GLASS = { 0.03, 0.22, 0.13, 0.95 }, SOLID = { 0.03, 0.22, 0.13, 0.95 }, PARCHMENT = { 0.52, 0.42, 0.26, 0.95 } }
local TILE = Theme.MEDIA .. 'BanzaiParchmentTile'

local surfaces = setmetatable({}, { __mode = 'k' }) -- [window] = BANZAI's textures on it
local titles = setmetatable({}, { __mode = 'k' })   -- [heading font string] = its owner's font and colour
local hooked = setmetatable({}, { __mode = 'k' })   -- [window] = its adapter (OnShow post-hook made once)
local muted = setmetatable({}, { __mode = 'k' })    -- [ElvUI-templated panel] = its own backdrop alpha
Skins.surfaces, Skins.titles, Skins.hooked, Skins.muted = surfaces, titles, hooked, muted

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Pixel()
	local E = Engine()
	local mult = E and tonumber(E.mult)
	if mult and mult > 0 then return mult end
	return 1
end

-- The one access gate BANZAI uses for every object it did not make (PvPFrames.lua, 1.3.4): the client must say
-- the object is neither forbidden nor carrying a secret aspect. Anything refused is skipped whole - nothing
-- is read from it, drawn on it or hooked.
local function Usable(frame)
	local gate = ns.PvPFrames and ns.PvPFrames.Accessible
	if gate then return gate(frame) end
	return type(frame) == 'table' and not (frame.IsForbidden and frame:IsForbidden())
end
Skins.Usable = Usable

---------------------------------------------------------------------------
-- Ownership
---------------------------------------------------------------------------
-- this proof skins windows on WoW Forever only: the frame names were read from that client's addons
function Skins.Supported()
	return (ns.Flavor and ns.Flavor.IsForever()) or false
end

-- the group's switch (the setting alone)
function Skins:GroupEnabled(id)
	local group = self.GROUP[id]
	if not group then return false end
	return Theme:DB()[group.key] and true or false
end

-- BANZAI skins this group right now: this client, the Banzai profile, the switch
function Skins:Owns(id)
	return (Skins.Supported() and Compat.Active() and self:GroupEnabled(id)) or false
end

function Skins.Material()
	local mode = Theme:DB().panelBackground
	if mode == 'SOLID' or mode == 'PARCHMENT' then return mode end
	return 'GLASS'
end

-- ElvUI's own panels (its "Transparent" template) in the BANZAI tone: { r, g, b, a } for the profile's
-- general.backdropfadecolor. ElvUI panels are flat colour, so parchment reads as the SOLID tone there.
function Skins.PanelColor(material)
	material = material or Skins.Material()
	local g = Theme.COLORS.glass
	local alpha = (material == 'GLASS') and math.max(Skins.GLASS_MIN, tonumber(Theme:DB().glassOpacity) or 0.72) or Theme.SOLID_ALPHA
	return { r = g[1], g = g[2], b = g[3], a = alpha }
end

---------------------------------------------------------------------------
-- The surface: BANZAI's textures on one window
---------------------------------------------------------------------------
local function Plain(window, sublevel)
	local t = window:CreateTexture(nil, 'BACKGROUND', nil, sublevel)
	t:SetTexture(Theme.WHITE)
	return t
end

-- made once per window; nil for a window BANZAI may not touch
function Skins:Surface(window)
	if surfaces[window] then return surfaces[window] end
	if not (Usable(window) and window.CreateTexture) then return nil end
	local s = { edges = {}, accent = {} }
	s.glass = Plain(window, -7)
	s.band = window:CreateTexture(nil, 'BACKGROUND', nil, -6)
	s.band:SetTexture(TILE, 'REPEAT', 'REPEAT', 'TRILINEAR')
	for i = 1, 4 do s.edges[i] = Plain(window, -5) end
	for i = 1, 2 do s.accent[i] = Plain(window, -4) end
	surfaces[window] = s
	return s
end

-- the rectangle the surface covers: what the adapter names, else the backdrop the window's own skin made
-- (ElvUI's CreateBackdrop child), else the window
function Skins.Anchor(spec)
	local window = spec.frame
	local anchor = spec.anchor
	if type(anchor) == 'function' then anchor = anchor(window) end
	if not Usable(anchor) then
		local backdrop = window.backdrop
		anchor = (Usable(backdrop) and backdrop.GetObjectType) and backdrop or window
	end
	return anchor
end

-- places the textures (only BANZAI's own regions are anchored; the window's are read, never set)
function Skins:Layout(s, spec)
	local anchor = Skins.Anchor(spec)
	local px = Pixel()
	local inset = (spec.inset or 1) * px
	local header = spec.header and math.max(0, spec.header) or nil
	local key = tostring(anchor) .. ':' .. inset .. ':' .. tostring(header) .. ':' .. tostring(spec.accentOnly)
	local width = anchor.GetWidth and anchor:GetWidth()
	if type(width) ~= 'number' or IsSecret(width) then width = 0 end
	if s.layoutKey == key and s.layoutWidth == width then return anchor end
	s.layoutKey, s.layoutWidth, s.header, s.accentOnly = key, width, header, spec.accentOnly and true or false
	if spec.accentOnly then
		-- a window whose owner draws its own body (Zygor): BANZAI adds the accent hairline alone, along the
		-- bottom edge of the bar the adapter names
		s.glass:ClearAllPoints()
		s.band:ClearAllPoints()
		for _, e in ipairs(s.edges) do e:ClearAllPoints() end
		local a, b = s.accent[1], s.accent[2]
		a:ClearAllPoints()
		a:SetPoint('BOTTOMLEFT', anchor, 'BOTTOMLEFT', 0, 0)
		a:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOM', 0, 0)
		a:SetHeight(self.ACCENT * px)
		b:ClearAllPoints()
		b:SetPoint('BOTTOMLEFT', anchor, 'BOTTOM', 0, 0)
		b:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', 0, 0)
		b:SetHeight(self.ACCENT * px)
		return anchor
	end
	s.glass:ClearAllPoints()
	s.glass:SetPoint('TOPLEFT', anchor, 'TOPLEFT', inset, -inset)
	s.glass:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', -inset, inset)
	-- the heading band: the parchment tile at the panels' fixed density (never stretched)
	s.band:ClearAllPoints()
	if header and header > 0 then
		s.band:SetPoint('TOPLEFT', anchor, 'TOPLEFT', inset, -inset)
		s.band:SetPoint('TOPRIGHT', anchor, 'TOPRIGHT', -inset, -inset)
		s.band:SetHeight(header)
		local M = Compat.PARCHMENT
		local u = math.max(0.01, (width - 2 * inset) * M.density / M.tileW)
		local v = header * M.density / M.tileH
		s.band:SetTexCoord(0.31, 0.31 + u, 0.12, 0.12 + v)
	end
	local top, bottom, left, right = s.edges[1], s.edges[2], s.edges[3], s.edges[4]
	for _, e in ipairs(s.edges) do e:ClearAllPoints() end
	top:SetPoint('TOPLEFT', anchor, 'TOPLEFT', inset, -inset)
	top:SetPoint('TOPRIGHT', anchor, 'TOPRIGHT', -inset, -inset)
	top:SetHeight(px)
	bottom:SetPoint('BOTTOMLEFT', anchor, 'BOTTOMLEFT', inset, inset)
	bottom:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', -inset, inset)
	bottom:SetHeight(px)
	left:SetPoint('TOPLEFT', anchor, 'TOPLEFT', inset, -inset)
	left:SetPoint('BOTTOMLEFT', anchor, 'BOTTOMLEFT', inset, inset)
	left:SetWidth(px)
	right:SetPoint('TOPRIGHT', anchor, 'TOPRIGHT', -inset, -inset)
	right:SetPoint('BOTTOMRIGHT', anchor, 'BOTTOMRIGHT', -inset, inset)
	right:SetWidth(px)
	-- the accent hairline: under the heading band, or along the top edge without one; two halves, three colours
	local y = -(inset + (header or 0))
	local a, b = s.accent[1], s.accent[2]
	a:ClearAllPoints()
	a:SetPoint('TOPLEFT', anchor, 'TOPLEFT', inset, y)
	a:SetPoint('TOPRIGHT', anchor, 'TOP', 0, y)
	a:SetHeight(self.ACCENT * px)
	b:ClearAllPoints()
	b:SetPoint('TOPLEFT', anchor, 'TOP', 0, y)
	b:SetPoint('TOPRIGHT', anchor, 'TOPRIGHT', -inset, y)
	b:SetHeight(self.ACCENT * px)
	return anchor
end

-- the material and the theme's colours (only when something changed or the window shows)
function Skins:Paint(s, material)
	local db = Theme:DB()
	local stops = Theme:Stops('h')
	local from, mid, to = Theme:ColorAt(stops, 0), Theme:ColorAt(stops, 0.5), Theme:ColorAt(stops, 1)
	-- (every pass names BANZAI's textures again: a later texture strip by the window's own skin cannot leave them blank)
	s.accent[1]:SetTexture(Theme.WHITE)
	s.accent[2]:SetTexture(Theme.WHITE)
	Theme:Gradient(s.accent[1], 'HORIZONTAL', from, mid, 1, 1)
	Theme:Gradient(s.accent[2], 'HORIZONTAL', mid, to, 1, 1)
	s.accent[1]:Show()
	s.accent[2]:Show()
	if s.accentOnly then
		s.glass:Hide()
		s.band:Hide()
		for _, e in ipairs(s.edges) do e:Hide() end
		s.material, s.banded, s.shown = material, false, true
		return
	end
	local parchment = material == 'PARCHMENT'
	if material == 'GLASS' then
		Theme:Glass(s.glass, math.max(self.GLASS_MIN, tonumber(db.glassOpacity) or 0.72))
	else
		Theme:Solid(s.glass) -- SOLID, and the body under the owner's light text on PARCHMENT
	end
	local band = parchment and s.header ~= nil and s.header > 0
	if band then
		s.band:SetTexture(TILE, 'REPEAT', 'REPEAT', 'TRILINEAR')
		local k = 0.91 * math.max(0.7, math.min(1.1, tonumber(db.parchmentBrightness) or 1)) -- the panels' own brightness rule
		s.band:SetVertexColor(k, k, k, 1)
	end
	s.band:SetShown(band and true or false)
	local edge = self.EDGE[material] or self.EDGE.GLASS
	for _, e in ipairs(s.edges) do
		e:SetTexture(Theme.WHITE)
		e:SetVertexColor(edge[1], edge[2], edge[3], edge[4])
		e:Show()
	end
	s.glass:Show()
	s.material, s.banded, s.shown = material, band and true or false, true
end

function Skins:Hide(s)
	s.glass:Hide()
	s.band:Hide()
	for _, e in ipairs(s.edges) do e:Hide() end
	for _, e in ipairs(s.accent) do e:Hide() end
	s.shown = false
end

---------------------------------------------------------------------------
-- The panel under the surface: an ElvUI template's centre made clear while BANZAI's surface is on
---------------------------------------------------------------------------
-- the ElvUI-templated panel of a window: the window itself (S:HandlePortraitFrame / SetTemplate) or the
-- backdrop child ElvUI made for it (CreateBackdrop); nil when ElvUI has not skinned it
function Skins.Base(window)
	local function templated(obj)
		return Usable(obj) and type(obj.template) == 'string' and obj.template ~= 'NoBackdrop' and obj.SetBackdropColor ~= nil
	end
	if templated(window) then return window end
	local backdrop = window.backdrop
	if templated(backdrop) then return backdrop end
	return nil
end

-- Clear centre (alpha 0), the colour as ElvUI set it; the alpha it had is kept. Called again at every skin
-- pass: when ElvUI has recoloured its panels meanwhile, its new alpha is the one kept.
function Skins:Mute(base)
	if not (base.GetBackdropColor and base.SetBackdropColor) then return false end
	local r, g, b, a = base:GetBackdropColor()
	if type(r) ~= 'number' or type(a) ~= 'number' or IsSecret(r) or IsSecret(a) then return false end
	if muted[base] == nil then
		muted[base] = a
	elseif a ~= 0 then
		muted[base] = a
	else
		return true -- still clear
	end
	base:SetBackdropColor(r, g, b, 0)
	return true
end

-- ElvUI recolours the panels it registered over the next moments whenever its media or the profile changes
-- (E:UpdateFrameTemplates / E:UpdateBackdropColors, a few panels per tick). E:CoroutineCallback is ElvUI's
-- own way for a plugin to be told, per panel, right after such an update: a panel BANZAI keeps clear is
-- cleared again at once and ElvUI's new alpha is the one remembered. One table lookup per panel; asked for
-- once, the first time a panel is cleared.
local following = false
function Skins.AfterElvUI(panel)
	if panel ~= nil and muted[panel] ~= nil then Skins:Mute(panel) end
end

function Skins:Follow()
	if following then return true end
	local E = Engine()
	if not (E and type(E.CoroutineCallback) == 'function') then return false end
	for _, name in ipairs({ 'UpdateFrameTemplate', 'UpdateBackdropColor' }) do
		if type(E[name]) == 'function' then E:CoroutineCallback(E[name], Skins.AfterElvUI) end
	end
	following = true
	return true
end

function Skins:Unmute(base)
	local alpha = muted[base]
	if alpha == nil then return false end
	muted[base] = nil
	if not (base.GetBackdropColor and base.SetBackdropColor) then return false end
	local r, g, b = base:GetBackdropColor()
	if type(r) ~= 'number' or IsSecret(r) then return false end
	base:SetBackdropColor(r, g, b, alpha)
	return true
end

---------------------------------------------------------------------------
-- The heading: the BANZAI display face on the owner's own title, its text untouched
---------------------------------------------------------------------------
local function Heading(spec)
	local title = spec.title
	if type(title) == 'function' then
		local ok, found = pcall(title, spec.frame)
		title = ok and found or nil
	end
	if Usable(title) and title.SetFont and title.GetFont then return title end
	return nil
end

-- inked: on the parchment band (dark ink, no outline); else the owner's colour stays
function Skins:StyleTitle(fs, inked)
	local saved = titles[fs]
	if not saved then
		local path, size, flags = fs:GetFont()
		if type(path) ~= 'string' or IsSecret(path) or type(size) ~= 'number' or IsSecret(size) then return false end -- (no font yet: its owner has not set the heading up)
		saved = { path = path, size = size, flags = flags }
		if fs.GetTextColor then saved.r, saved.g, saved.b, saved.a = fs:GetTextColor() end
		titles[fs] = saved
	end
	local text = fs.GetText and fs:GetText()
	if type(text) ~= 'string' or IsSecret(text) then text = nil end
	local path = Theme.DisplayFontFor and Theme:DisplayFontFor(text) or Theme:SmallFont()
	if not fs:SetFont(path, saved.size, inked and '' or 'OUTLINE') then fs:SetFont(saved.path, saved.size, saved.flags) end
	if fs.SetTextColor then
		if inked then
			fs:SetTextColor(self.INK[1], self.INK[2], self.INK[3], 1)
		elseif saved.inked and type(saved.r) == 'number' then
			fs:SetTextColor(saved.r, saved.g, saved.b, saved.a or 1) -- off the parchment again: the owner's colour
		end
	end
	saved.inked = inked and true or false
	return true
end

function Skins:RestoreTitle(fs)
	local saved = titles[fs]
	if not saved then return false end
	titles[fs] = nil
	fs:SetFont(saved.path, saved.size, saved.flags)
	if saved.inked and fs.SetTextColor and type(saved.r) == 'number' then fs:SetTextColor(saved.r, saved.g, saved.b, saved.a or 1) end
	return true
end

---------------------------------------------------------------------------
-- One window
---------------------------------------------------------------------------
-- spec: { frame, anchor?, inset?, header?, title?, noTitle? } - the adapter's description of one window
function Skins:SkinWindow(adapter, spec)
	local window = spec.frame
	local s = self:Surface(window)
	if not s then return false end
	self:Layout(s, spec)
	local material = Skins.Material()
	self:Paint(s, material)
	local base = (not spec.accentOnly) and Skins.Base(window) or nil
	if base and self:Mute(base) then
		s.base = base
		self:Follow()
	end
	local fs = Heading(spec)
	if fs then
		self:StyleTitle(fs, s.banded)
		s.title = fs
	end
	if adapter.extra then adapter:extra(spec, true, material, s) end
	-- re-asserted whenever the window shows (its owner may have re-skinned or resized it meanwhile)
	if not hooked[window] and window.HookScript then
		hooked[window] = adapter
		window:HookScript('OnShow', function() Skins:Touch(hooked[window]) end)
	end
	return true
end

function Skins:UnskinWindow(adapter, spec)
	local window = spec.frame
	local s = surfaces[window]
	if not s then return false end
	local was = s.shown
	self:Hide(s)
	if s.base then
		self:Unmute(s.base)
		s.base = nil
	end
	if s.title then
		self:RestoreTitle(s.title)
		s.title = nil
	end
	if was and adapter.extra then adapter:extra(spec, false, nil, s) end
	return was and true or false
end

---------------------------------------------------------------------------
-- Adapters
---------------------------------------------------------------------------
-- adapter: { id, group, label,
--            addon?    the addon whose ADDON_LOADED brings its windows (skinned one frame after it loads),
--            requires? an optional addon that must be loaded at all (else ABSENT),
--            windows = function(self) -> { spec, ... }   the windows that exist now,
--            ready?  = function(self, spec) -> true | false, why,
--            attach? = function(self)   once, the first time BANZAI owns the group and the addon is there,
--            extra?  = function(self, spec, on, material, surface)   adapter-specific visuals }
function Skins:Register(adapter)
	if type(adapter) ~= 'table' or type(adapter.id) ~= 'string' or self.byId[adapter.id] then return false end
	if not (self.GROUP[adapter.group] and not self.GROUP[adapter.group].owned and type(adapter.windows) == 'function') then return false end
	self.adapters[#self.adapters + 1] = adapter
	self.byId[adapter.id] = adapter
	adapter.state = { status = 'NOT CHECKED' }
	return true
end

local function AddonLoaded(name)
	if not name then return true end
	local loaded = C_AddOns and C_AddOns.IsAddOnLoaded
	return (loaded and loaded(name)) and true or false
end

local function Windows(adapter)
	local ok, list = pcall(adapter.windows, adapter)
	if not ok then return nil, tostring(list) end
	local out = {}
	for _, spec in ipairs(type(list) == 'table' and list or {}) do
		if type(spec) == 'table' and Usable(spec.frame) and spec.frame.CreateTexture then out[#out + 1] = spec end
	end
	return out
end

-- Skins or unskins one adapter's windows for the current ownership. Returns its status:
--   SKINNED n      n windows carry the BANZAI surface
--   OFF            its switch is off (or another profile is active): every window is its owner's
--   ABSENT         its addon is not loaded
--   WAITING        loaded, no window yet (made later: skinned when it shows or its addon reports it)
--   NOT READY      a window is there but its own skin has not run (the reason is kept)
--   COMBAT         waiting for combat to end
function Skins:Touch(adapter)
	if type(adapter) ~= 'table' or not adapter.state then return nil end
	local state = adapter.state
	if not Skins.Supported() then
		state.status, state.detail = 'NOT ON THIS CLIENT', nil
		return state.status
	end
	if not AddonLoaded(adapter.requires) then -- an optional addon that is not installed / loaded: nothing to do, nothing looked for
		state.status, state.detail = 'ABSENT', nil
		return state.status
	end
	if InCombatLockdown() then
		self.pending = true
		state.status = 'COMBAT'
		return state.status
	end
	local owns = self:Owns(adapter.group)
	if owns and adapter.attach and not adapter.attached then
		-- (false: what it attaches to is not there yet - asked again at the next pass)
		local ok, result = pcall(adapter.attach, adapter)
		if not ok then state.error = tostring(result) end
		adapter.attached = (ok and result ~= false) or nil
	end
	local list, problem = Windows(adapter)
	if not list then
		state.status, state.detail = 'ERROR', problem
		return state.status
	end
	if not owns then
		for _, spec in ipairs(list) do self:UnskinWindow(adapter, spec) end
		state.status, state.detail, state.count = 'OFF', nil, 0
		return state.status
	end
	local count, waiting, note = 0, nil, nil
	for _, spec in ipairs(list) do
		note = note or spec.note
		local ready, why = true, nil
		if adapter.ready then
			local ok, a, b = pcall(adapter.ready, adapter, spec)
			if ok then ready, why = a, b else ready, why = false, tostring(a) end
		end
		if ready then
			local ok, done = pcall(self.SkinWindow, self, adapter, spec)
			if ok and done then count = count + 1 elseif not ok then state.error = tostring(done) end
		else
			waiting = why or 'its own skin has not run'
			self:UnskinWindow(adapter, spec)
			-- skinned as soon as it shows with its own skin in place
			local window = spec.frame
			if not hooked[window] and window.HookScript then
				hooked[window] = adapter
				window:HookScript('OnShow', function() Skins:Touch(hooked[window]) end)
			end
		end
	end
	state.count = count
	if count > 0 then
		state.status, state.detail = 'SKINNED', waiting or note
	elseif waiting then
		state.status, state.detail = 'NOT READY', waiting
	else
		state.status, state.detail = 'WAITING', nil
	end
	return state.status
end

-- every adapter (settings, theme, material, profile, login). Cheap: a window already skinned is repainted
-- only; nothing is searched for.
function Skins:Refresh()
	for _, adapter in ipairs(self.adapters) do self:Touch(adapter) end
end

-- an addon loaded after login (a load-on-demand Blizzard window, Baganator, Zygor): its adapters one frame
-- later, when its owner's own skin has run. One timer per load, never a ticker.
function Skins:OnAddonLoaded(name)
	if not Skins.Supported() then return 0 end
	local mine = {}
	for _, adapter in ipairs(self.adapters) do
		if adapter.addon == name then mine[#mine + 1] = adapter end
	end
	if #mine == 0 then return 0 end
	local function run() for _, adapter in ipairs(mine) do Skins:Touch(adapter) end end
	if C_Timer and C_Timer.After then C_Timer.After(0, run) else run() end
	return #mine
end

-- status lines (/banzai forever, the WINDOW SKINS page)
function Skins:Report()
	local lines = {}
	if not Skins.Supported() then return { 'window skins: WoW Forever only in this build - nothing is skinned on this client.' } end
	for _, group in ipairs(self.GROUPS) do
		local on = self:GroupEnabled(group.id)
		if group.owned then
			lines[#lines + 1] = string.format('%s: %s (BANZAI\'s own frame)', group.label, on and 'on' or 'off')
		elseif group.profile then
			lines[#lines + 1] = string.format('%s: %s (ElvUI\'s panel colour in the Banzai profile)', group.label, on and 'on' or 'off')
		else
			local parts = {}
			for _, adapter in ipairs(self.adapters) do
				if adapter.group == group.id then
					local st = adapter.state
					local text = adapter.label .. ' ' .. tostring(st.status) .. ((st.status == 'SKINNED' and st.count) and (' ' .. st.count) or '')
					if st.detail then text = text .. ' (' .. tostring(st.detail) .. ')' end
					if st.error then text = text .. ' [error: ' .. tostring(st.error) .. ']' end
					parts[#parts + 1] = text
				end
			end
			lines[#lines + 1] = string.format('%s: %s - %s', group.label, on and 'on' or 'off', #parts > 0 and table.concat(parts, '; ') or 'no adapter')
		end
	end
	return lines
end

-- how many windows carry the BANZAI surface right now (the tests, the status line)
function Skins:Count()
	local n = 0
	for _, adapter in ipairs(self.adapters) do n = n + ((adapter.state.status == 'SKINNED' and adapter.state.count) or 0) end
	return n
end

local events = CreateFrame('Frame')
events:RegisterEvent('ADDON_LOADED')
events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:SetScript('OnEvent', function(_, event, name)
	if event == 'ADDON_LOADED' then
		Skins:OnAddonLoaded(name)
	elseif Skins.pending then
		Skins.pending = false
		Skins:Refresh()
	end
end)
Skins.events = events
