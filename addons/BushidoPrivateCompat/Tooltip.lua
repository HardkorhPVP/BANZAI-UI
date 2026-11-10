--[[
	BANZAI - Tooltip.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	1.0.0 tooltip theme. ElvUI keeps skinning the game's tooltips (its border
	coloured by item quality / class, its backdrop, its anchor); Banzai adds,
	as plain textures on the tooltip frames:
	  glass    dark translucent green over ElvUI's backdrop, inside its border
	  edge     a thin green -> purple line just inside ElvUI's border (the
	           quality / class colour stays on ElvUI's own border, restrained)
	  shadow   a soft dark fall-off around the outside
	The font (the small-text font, crisp: shadow, no outline) is ElvUI's own
	tooltip font setting, written by BushidoPrivateRestore. Nothing is hooked
	and nothing of the content is read or rebuilt: the textures stay on the
	frames and are only re-coloured when a setting changes (no per-frame work).
	ELVUI theme: the textures are hidden, Bushido's tooltip shows as it was.

	Banzai's own tooltips (bottom panel, objectives, the BANZAI wordmark) use
	GameTooltip through Begin / Finish / End: anchored next to what is
	hovered (above the panel, left of the objectives - never over the
	minimap), kept on screen, hidden again when the mouse leaves or the owner
	hides (never stuck, never two at once).
]]
local _, ns = ...
local Theme = ns.Theme

local Tooltip = {}
ns.Tooltip = Tooltip

Tooltip.FRAMES = { 'GameTooltip', 'ItemRefTooltip', 'ShoppingTooltip1', 'ShoppingTooltip2', 'ItemRefShoppingTooltip1', 'ItemRefShoppingTooltip2' }
Tooltip.SHADOW = 5   -- units of soft shadow outside the frame
Tooltip.INSET = 1    -- the glass and edge start inside ElvUI's 1-unit border
Tooltip.GAP = 6      -- between a Banzai tooltip and what it explains

local skins = {} -- [tooltip frame] = its Banzai textures (kept here, nothing written onto the game's frames)
Tooltip.skins = skins

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

-- one screen pixel in UI units (ElvUI's own value when it has one)
local function Pixel()
	local E = Engine()
	local mult = E and tonumber(E.mult)
	if mult and mult > 0 then return mult end
	return 1
end

local function Solid(tt, layer, sublevel)
	local t = tt:CreateTexture(nil, layer, nil, sublevel)
	t:SetTexture(Theme.WHITE)
	return t
end

-- the Banzai textures on one tooltip frame (once)
function Tooltip:Skin(tt)
	if not tt or skins[tt] then return skins[tt] end
	if tt.IsForbidden and tt:IsForbidden() then return nil end
	local s = { edges = {}, shadow = {} }
	s.glass = Solid(tt, 'BACKGROUND', 1)
	for i = 1, 4 do s.edges[i] = Solid(tt, 'BACKGROUND', 3) end
	for i = 1, 4 do s.shadow[i] = Solid(tt, 'BACKGROUND', -8) end
	skins[tt] = s
	self:Layout(tt, s)
	return s
end

function Tooltip:Layout(tt, s)
	local inset, px, sh = self.INSET, Pixel(), self.SHADOW
	s.glass:ClearAllPoints()
	s.glass:SetPoint('TOPLEFT', tt, 'TOPLEFT', inset, -inset)
	s.glass:SetPoint('BOTTOMRIGHT', tt, 'BOTTOMRIGHT', -inset, inset)
	local top, bottom, left, right = s.edges[1], s.edges[2], s.edges[3], s.edges[4]
	for _, e in ipairs(s.edges) do e:ClearAllPoints() end
	top:SetPoint('TOPLEFT', tt, 'TOPLEFT', inset, -inset)
	top:SetPoint('TOPRIGHT', tt, 'TOPRIGHT', -inset, -inset)
	top:SetHeight(px)
	bottom:SetPoint('BOTTOMLEFT', tt, 'BOTTOMLEFT', inset, inset)
	bottom:SetPoint('BOTTOMRIGHT', tt, 'BOTTOMRIGHT', -inset, inset)
	bottom:SetHeight(px)
	left:SetPoint('TOPLEFT', tt, 'TOPLEFT', inset, -inset)
	left:SetPoint('BOTTOMLEFT', tt, 'BOTTOMLEFT', inset, inset)
	left:SetWidth(px)
	right:SetPoint('TOPRIGHT', tt, 'TOPRIGHT', -inset, -inset)
	right:SetPoint('BOTTOMRIGHT', tt, 'BOTTOMRIGHT', -inset, inset)
	right:SetWidth(px)
	-- shadow strips outside: top, bottom, left, right
	local st, sb, sl, sr = s.shadow[1], s.shadow[2], s.shadow[3], s.shadow[4]
	for _, e in ipairs(s.shadow) do e:ClearAllPoints() end
	st:SetPoint('BOTTOMLEFT', tt, 'TOPLEFT', 0, 0)
	st:SetPoint('BOTTOMRIGHT', tt, 'TOPRIGHT', 0, 0)
	st:SetHeight(sh)
	sb:SetPoint('TOPLEFT', tt, 'BOTTOMLEFT', 0, 0)
	sb:SetPoint('TOPRIGHT', tt, 'BOTTOMRIGHT', 0, 0)
	sb:SetHeight(sh)
	sl:SetPoint('TOPRIGHT', tt, 'TOPLEFT', 0, sh)
	sl:SetPoint('BOTTOMRIGHT', tt, 'BOTTOMLEFT', 0, -sh)
	sl:SetWidth(sh)
	sr:SetPoint('TOPLEFT', tt, 'TOPRIGHT', 0, sh)
	sr:SetPoint('BOTTOMLEFT', tt, 'BOTTOMRIGHT', 0, -sh)
	sr:SetWidth(sh)
end

-- colours from the theme and the settings (only when something changed)
function Tooltip:Paint(s, db)
	local on = db.tooltipTheme ~= 'ELVUI'
	local alpha = math.max(0.5, math.min(1, tonumber(db.tooltipOpacity) or 0.86))
	Theme:Glass(s.glass, alpha)
	local from, to = (Theme:Accents()), Theme.COLORS.violet
	Theme:Gradient(s.edges[1], 'HORIZONTAL', from, to, 0.95, 0.95)
	Theme:Gradient(s.edges[2], 'HORIZONTAL', from, to, 0.95, 0.95)
	Theme:Gradient(s.edges[3], 'VERTICAL', from, from, 0.95, 0.95)
	Theme:Gradient(s.edges[4], 'VERTICAL', to, to, 0.95, 0.95)
	local dark = { 0, 0, 0 }
	Theme:Gradient(s.shadow[1], 'VERTICAL', dark, dark, 0.32, 0) -- fades away from the frame
	Theme:Gradient(s.shadow[2], 'VERTICAL', dark, dark, 0, 0.32)
	Theme:Gradient(s.shadow[3], 'HORIZONTAL', dark, dark, 0, 0.32)
	Theme:Gradient(s.shadow[4], 'HORIZONTAL', dark, dark, 0.32, 0)
	s.glass:SetShown(on)
	for _, e in ipairs(s.edges) do e:SetShown(on) end
	for _, e in ipairs(s.shadow) do e:SetShown(on) end
end

-- tooltip scale: only touched once Darren has changed it (another addon's
-- scale stays otherwise); off the Banzai profile it goes back to 1
function Tooltip:ApplyScale(tt, scale)
	scale = math.max(0.8, math.min(1.3, tonumber(scale) or 1))
	if scale == 1 and not self.scaled[tt] then return end
	if tt.SetScale then tt:SetScale(scale) end
	self.scaled[tt] = (scale ~= 1) or nil
end
Tooltip.scaled = {}

function Tooltip:Refresh()
	local db = Theme:DB()
	local active = ns.Compat and ns.Compat.Active and ns.Compat.Active()
	for _, name in ipairs(self.FRAMES) do
		local tt = _G[name]
		if tt then
			local s = active and self:Skin(tt) or skins[tt]
			if s then
				if active then
					self:Paint(s, db)
				else
					s.glass:Hide()
					for _, e in ipairs(s.edges) do e:Hide() end
					for _, e in ipairs(s.shadow) do e:Hide() end
				end
			end
			self:ApplyScale(tt, active and db.tooltipScale or 1)
		end
	end
end

---------------------------------------------------------------------------
-- Banzai's own tooltips
---------------------------------------------------------------------------
-- side: TOP (above the owner), BOTTOM, LEFT (left of it, top edges level) or CURSOR
function Tooltip:Begin(owner, side)
	local tt = _G.GameTooltip
	if not (tt and owner) then return nil end
	if side == 'CURSOR' then
		tt:SetOwner(owner, 'ANCHOR_CURSOR')
	else
		tt:SetOwner(owner, 'ANCHOR_NONE')
		tt:ClearAllPoints()
		if side == 'BOTTOM' then
			tt:SetPoint('TOP', owner, 'BOTTOM', 0, -self.GAP)
		elseif side == 'LEFT' then
			tt:SetPoint('TOPRIGHT', owner, 'TOPLEFT', -self.GAP, 0)
		else
			tt:SetPoint('BOTTOM', owner, 'TOP', 0, self.GAP)
		end
	end
	if tt.SetClampedToScreen then tt:SetClampedToScreen(true) end
	tt:ClearLines()
	self.owner = owner
	return tt
end

function Tooltip:Finish(tt)
	if tt then tt:Show() end
	return tt
end

-- hides the tooltip only while `owner` still owns it (never someone else's)
function Tooltip:End(owner)
	local tt = _G.GameTooltip
	if tt and owner and tt.IsOwned and tt:IsOwned(owner) then tt:Hide() end
	if self.owner == owner then self.owner = nil end
end

function Tooltip:Owns(owner)
	local tt = _G.GameTooltip
	return tt and owner and tt.IsOwned and tt:IsOwned(owner) and tt:IsShown() and true or false
end
