--[[
	BANZAI - ActionButtons.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	The Banzai look for ElvUI's action buttons: PERFECT CIRCLES on the main
	action cluster (ElvUI bars 1 and 6). Same buttons, same bindings, same
	clicks; only their surface changes:

	  shape     a true circular mask on the spell icon and on the square hover /
	            pushed / checked / highlight / flash overlays; the buttons
	            themselves are square (ElvUI's own size settings, written by
	            BushidoPrivateRestore), so the circle is never squashed
	  ring      one thick, crisp green -> purple ring (24 % of the radius) with
	            thin dark edge lines; each ring spans a window of the Banzai ramp,
	            so the cluster flows green -> purple from left to right; empty
	            slots keep only a faint ring
	  pixels    0.7.0: ring and mask are drawn for the screen pixels they cover.
	            0.6.0's 256 px textures were shrunk 6.4x onto a 40 px button with
	            the game's default bilinear sampling (no mip levels): stair-
	            stepped edges. Now a 64 px canvas holds the circle of a 40 px
	            button (Darren: 30 units at UI scale 0.71 on 1440 lines), every
	            texel the exact coverage of one screen pixel; the canvas is sized
	            so one texel lands on one pixel, snapped to the pixel grid, and
	            filtered trilinearly at any other scale (a 128 px set for buttons
	            drawn larger). tools/ringcheck.js compares both with the ideal.
	  no glass  nothing behind the icon: ElvUI's square backdrop is transparent.
	            0.6.0: the Banzai profile uses ElvUI's "transparent" button
	            template with an opaque black backdrop colour, and ElvUI
	            re-colours its templates on its own updates, so the backdrop is
	            cleared through ElvUI's own per-frame overrides (backdrop alpha 0,
	            forced border colour 0), its border frames and any shadow too,
	            and checked again on every action-bar update
	  cooldown  ElvUI's cooldown swipe uses the same circle; the numbers, the
	            centred keybind and the bottom-centre count are ElvUI's own text
	            settings (also written by BushidoPrivateRestore)
	  proc      a round, pulsing Banzai halo when a spell is highlighted by the
	            game (SPELL_ACTIVATION_OVERLAY_GLOW_SHOW / _HIDE). ElvUI's square
	            proc glow is switched off through its own setting while this style
	            is on; buttons that stay square get a rounded-square halo instead.

	Applied out of combat only; ELVUI in the options (or another profile) takes
	the circle off again. Nothing secure is created, moved or hooked.

	1.2.0 BANZAI SQUARE (the new default; BANZAI CIRCLES and ELVUI SQUARE stay
	choices, BANZAI > ACTION BARS): the circles cropped too much of the spell
	picture to read it quickly in play. The square keeps the icon square: a mask
	with small, crisp 45-degree chamfers on its corners (on the icon and the
	hover / pushed / checked / flash overlays) and a thin green -> purple border
	that sits half outside the button, in the spacing between buttons, so it
	covers only the icon's outermost pixel (80 % of the button shows the picture,
	the circles 42 %). ElvUI sizes buttons in whole screen pixels (Darren's 30
	units = 39 px), so the border is drawn for every whole-pixel width 34 .. 42 px
	and laid 64 screen pixels wide on its exact offset: one texel per screen
	pixel, every straight edge on a pixel boundary (other widths: an 80 px
	drawing scaled, trilinear); the icon mask and the cooldown swipe are
	stretched over the button / the icon, their edges under the border. The same
	transparent backdrop, a cooldown swipe and a pulsing proc halo of the same
	chamfered shape, a faint border on empty slots. The keybind sits small at the
	top-right, the count bottom-centre, the cooldown numbers in the middle
	(ElvUI's own text settings, written by BushidoPrivateRestore).
]]
local _, ns = ...
local Theme = ns.Theme

local ActionButtons = {}
ns.ActionButtons = ActionButtons

local GLOW_SQUARE = Theme.MEDIA .. 'BanzaiButtonGlowSquare' -- ElvUI square buttons outside the Banzai cluster
-- the two Banzai shapes: icon mask, ring / border (both in the 64 / 128 px sets),
-- the cooldown swipe (stretched over the button itself) and the proc halo
ActionButtons.SHAPES = {
	CIRCLE = { mask = Theme.MEDIA .. 'BanzaiButtonMask', ring = Theme.MEDIA .. 'BanzaiButtonRing', swipe = Theme.MEDIA .. 'BanzaiButtonCircle',
		glow = Theme.MEDIA .. 'BanzaiButtonGlow', glowScale = 1.6 },
	SQUARE = { mask = Theme.MEDIA .. 'BanzaiSquareMask', ring = Theme.MEDIA .. 'BanzaiSquareBorder', swipe = Theme.MEDIA .. 'BanzaiSquareSwipe',
		glow = Theme.MEDIA .. 'BanzaiSquareGlow', glowScale = 1.5 },
}
-- the square's border drawings (tools/lib/bamboo.js SQUARE): one per whole-pixel button width, on a 64 px canvas
ActionButtons.SQUARE_PX = { min = 34, max = 42, canvas = 64 }
-- the circle sets (tools/lib/bamboo.js): canvas px and the button px it is drawn for
ActionButtons.SETS = { { suffix = '', canvas = 64, design = 40 }, { suffix = '128', canvas = 128, design = 80 } }
ActionButtons.LARGE = 56 -- buttons wider than this many screen pixels take the 128 px set
ActionButtons.BARS = 15
ActionButtons.CIRCLE_BARS = { [1] = true, [6] = true } -- the main Banzai action cluster (squares or circles)
ActionButtons.GLOW_SCALE = 1.6        -- round halo around a circle
ActionButtons.GLOW_SQUARE_SCALE = 1.5 -- rounded-square halo around a square button
ActionButtons.EMPTY_ALPHA = 0.35
local BACKDROP_PIECES = { 'Center', 'TopEdge', 'BottomEdge', 'LeftEdge', 'RightEdge',
	'TopLeftCorner', 'TopRightCorner', 'BottomLeftCorner', 'BottomRightCorner', 'iborder', 'oborder' }

local skinned = {}   -- [button] = circle parts
local glows = {}     -- [button] = halo texture (+ animation)
local procs = {}     -- [spellID] = true while the game highlights it
local pending = false
local scheduled = false

local function Engine()
	local engine = _G.ElvUI
	return engine and engine[1]
end

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Plain(value)
	if IsSecret(value) then return nil end
	return value
end

-- the Banzai shape in use: 'SQUARE' (default) | 'CIRCLE' | nil (ElvUI's own buttons)
local function Shape()
	local style = Theme:DB().actionStyle
	if style == 'SQUARE' or style == 'CIRCLE' then return style end
	return nil
end
ActionButtons.Shape = Shape

local function On()
	local active = ns.Compat and ns.Compat.Active and ns.Compat.Active()
	return active and Shape() ~= nil and true or false
end
ActionButtons.On = On

-- every ElvUI action button that exists, with its column in its row
function ActionButtons.Buttons()
	local list = {}
	local shape = Shape()
	local E = Engine()
	local db = E and E.db and E.db.actionbar
	for b = 1, ActionButtons.BARS do
		local barDB = db and db['bar' .. b]
		local perRow = math.max(1, math.min(12, (barDB and barDB.buttonsPerRow) or 12))
		for i = 1, 12 do
			local button = _G['ElvUI_Bar' .. b .. 'Button' .. i]
			if button then
				local cluster = ActionButtons.CIRCLE_BARS[b] or false
				list[#list + 1] = { button = button, bar = b, column = ((i - 1) % perRow) + 1, columns = perRow, cluster = cluster,
					shape = cluster and shape or nil, circle = cluster and shape == 'CIRCLE' or false }
			end
		end
	end
	return list
end

local function Overlays(button, parts)
	local list = { parts.icon }
	for _, getter in ipairs({ 'GetHighlightTexture', 'GetPushedTexture', 'GetCheckedTexture' }) do
		if button[getter] then list[#list + 1] = button[getter](button) end
	end
	list[#list + 1] = button.SpellHighlightTexture
	list[#list + 1] = button.Flash
	return list
end

local function Build(button)
	local parts = { masked = {} }
	parts.icon = button.icon or (button.GetName and _G[(button:GetName() or '') .. 'Icon'])
	parts.mask = button:CreateMaskTexture()
	parts.ring = button:CreateTexture(nil, 'OVERLAY', nil, -1)
	skinned[button] = parts
	return parts
end

-- one texel on one screen pixel: the vertices on the pixel grid, no texel snapping
local function Snap(texture)
	if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(true) end
	if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
end

-- the set for this button's size on screen, its canvas centred on the button
-- and sized so the shape drawn for `design` pixels covers the button
-- 1.2.0 the square: the drawing for the button's width in whole screen pixels, its 64 px canvas laid 64 screen
-- pixels wide with the button where the drawing has it (the texture's top-left `off` pixels left of / above the
-- button's), so one texel lands on one pixel; the mask stretched over the button (its edge lies under the border)
local function FitSquare(parts, button, w)
	local scale = Theme.PixelScale(button)
	local pixels = w * scale
	local p = math.floor(pixels + 0.5)
	local S = ActionButtons.SQUARE_PX
	local shape = ActionButtons.SHAPES.SQUARE
	local ring = parts.ring
	ring:ClearAllPoints()
	if p >= S.min and p <= S.max then
		local off = math.floor((S.canvas - p) / 2) / scale
		ring:SetTexture(shape.ring .. p, 'CLAMP', 'CLAMP', 'TRILINEAR')
		ring:SetPoint('TOPLEFT', button, 'TOPLEFT', -off, off)
		ring:SetSize(S.canvas / scale, S.canvas / scale)
		parts.set = { suffix = tostring(p), canvas = S.canvas, design = p }
	else -- other widths: the 80 px drawing on its 128 px canvas, scaled
		ring:SetTexture(shape.ring .. '128', 'CLAMP', 'CLAMP', 'TRILINEAR')
		ring:SetPoint('CENTER', button, 'CENTER', 0, 0)
		ring:SetSize(w * 128 / 80, w * 128 / 80)
		parts.set = { suffix = '128', canvas = 128, design = 80 }
	end
	Snap(ring)
	parts.mask:SetTexture(shape.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE', 'TRILINEAR')
	parts.mask:ClearAllPoints()
	parts.mask:SetAllPoints(button)
	Snap(parts.mask)
	parts.pixels, parts.fitWidth = pixels, w
	return parts.set
end

function ActionButtons.Fit(parts, button)
	local w = Plain(button.GetWidth and button:GetWidth()) or 0
	if w <= 0 then w = 30 end
	if parts.shape == 'SQUARE' then return FitSquare(parts, button, w) end
	local pixels = w * Theme.PixelScale(button)
	local set = (pixels > ActionButtons.LARGE) and ActionButtons.SETS[2] or ActionButtons.SETS[1]
	local size = w * set.canvas / set.design
	local shape = ActionButtons.SHAPES.CIRCLE
	local MASK, RING = shape.mask, shape.ring
	parts.mask:SetTexture(MASK .. set.suffix, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE', 'TRILINEAR')
	parts.ring:SetTexture(RING .. set.suffix, 'CLAMP', 'CLAMP', 'TRILINEAR')
	for _, texture in ipairs({ parts.mask, parts.ring }) do
		texture:ClearAllPoints()
		texture:SetPoint('CENTER', button, 'CENTER', 0, 0)
		texture:SetSize(size, size)
		Snap(texture)
	end
	parts.set, parts.pixels, parts.fitWidth = set, pixels, w
	return set, size
end

-- the button was resized (ElvUI options) or the UI scale / resolution changed since the last fit
local function Refit(parts, button)
	local w = Plain(button.GetWidth and button:GetWidth())
	if not w or w <= 0 then return false end
	return w ~= parts.fitWidth or math.abs(w * Theme.PixelScale(button) - (parts.pixels or 0)) > 0.01
end

-- ElvUI's square backdrop behind a circle: invisible (hidden = true) or back
-- to ElvUI's colours. ElvUI keeps customBackdropAlpha and the forced border
-- colour whenever it re-templates or re-colours the button.
local function SetBackdropHidden(button, hidden)
	local E = Engine()
	local alpha = hidden and 0 or 1
	for _, key in ipairs(BACKDROP_PIECES) do
		local piece = button[key]
		if piece and piece.SetAlpha then piece:SetAlpha(alpha) end
	end
	if button.shadow and button.shadow.SetAlpha then button.shadow:SetAlpha(alpha) end
	if hidden then
		button.customBackdropAlpha = 0
		if button.SetBackdropColor then button:SetBackdropColor(0, 0, 0, 0) end
		if E and E.ForceBorderColor then E:ForceBorderColor(button, 0, 0, 0, 0) end
		if button.SetBackdropBorderColor then button:SetBackdropBorderColor(0, 0, 0, 0) end
		button.banzaiBackdrop = true
	elseif button.banzaiBackdrop then
		button.banzaiBackdrop = nil
		button.customBackdropAlpha = nil
		if E and E.ForceBorderColor then E:ForceBorderColor(button) end
		local media = E and E.media
		local c = media and ((button.template == 'Transparent' and media.backdropfadecolor) or media.backdropcolor)
		if c and button.SetBackdropColor then button:SetBackdropColor(c[1], c[2], c[3], c[4] or 1) end
		local b = media and media.bordercolor
		if b and button.SetBackdropBorderColor then button:SetBackdropBorderColor(b[1], b[2], b[3], 1) end
	end
end
ActionButtons.SetBackdropHidden = SetBackdropHidden

local function Cooldowns(button)
	return { button.cooldown, button.chargeCooldown, button.lossOfControlCooldown }
end

-- the cooldown swipes in the button's shape (nil: ElvUI's square swipe)
local function Swipe(button, shape)
	local swipe = shape and ActionButtons.SHAPES[shape] and ActionButtons.SHAPES[shape].swipe
	for _, cd in ipairs(Cooldowns(button)) do
		if cd and cd.SetSwipeTexture then cd:SetSwipeTexture(swipe or Theme.WHITE) end
	end
end

function ActionButtons:Skin(entry)
	local button = entry.button
	local parts = skinned[button] or Build(button)
	parts.entry = entry
	parts.shape = entry.shape or 'SQUARE'
	ActionButtons.Fit(parts, button)
	for _, texture in ipairs(Overlays(button, parts)) do
		if texture and texture.AddMaskTexture and not parts.masked[texture] then
			texture:AddMaskTexture(parts.mask)
			parts.masked[texture] = true
		end
	end
	Swipe(button, parts.shape)
	SetBackdropHidden(button, true)
	parts.ring:Show()
	parts.active = true
	self:Paint(parts)
end

function ActionButtons:Unskin(button)
	local parts = skinned[button]
	if not (parts and parts.active) then return end
	for texture in pairs(parts.masked) do
		if texture.RemoveMaskTexture then texture:RemoveMaskTexture(parts.mask) end
	end
	parts.masked = {}
	Swipe(button, nil)
	SetBackdropHidden(button, false)
	parts.ring:Hide()
	parts.active = false
end

-- each ring / border shows a window of the Banzai ramp: the cluster runs green -> purple
function ActionButtons:Paint(parts)
	local entry = parts.entry
	local stops = Theme:Stops('h')
	local t = (entry.columns > 1) and ((entry.column - 1) / (entry.columns - 1)) * 0.6 or 0
	local a = math.max(0.4, math.min(1, tonumber(Theme:DB().ringIntensity) or 1)) -- 1.0.0 BANZAI > ACTION BARS
	Theme:Gradient(parts.ring, 'HORIZONTAL', Theme:ColorAt(stops, t), Theme:ColorAt(stops, t + 0.4), a, a)
	Snap(parts.ring) -- ElvUI turns pixel snapping off whenever a texture is recoloured
end

---------------------------------------------------------------------------
-- Proc halo (round on the circles, chamfered on the Banzai squares, rounded
-- square on ElvUI's square buttons)
---------------------------------------------------------------------------
local function Glow(entry)
	local button = entry.button
	local glow = glows[button]
	if glow then return glow end
	glow = button:CreateTexture(nil, 'BACKGROUND', nil, -1)
	glow:SetPoint('CENTER', button, 'CENTER', 0, 0)
	if glow.SetBlendMode then glow:SetBlendMode('ADD') end
	glow:Hide()
	if glow.CreateAnimationGroup then
		local pulse = glow:CreateAnimationGroup()
		local alpha = pulse:CreateAnimation('Alpha')
		alpha:SetFromAlpha(1)
		alpha:SetToAlpha(0.45)
		alpha:SetDuration(0.55)
		pulse:SetLooping('BOUNCE')
		glow.pulse = pulse
	end
	glows[button] = glow
	return glow
end

local function ShowGlow(entry, show)
	local glow = (show or glows[entry.button]) and Glow(entry)
	if not glow then return end
	if show then
		local button = entry.button
		local w, h = button:GetWidth() or 0, button:GetHeight() or 0
		local shape = entry.shape and ActionButtons.SHAPES[entry.shape]
		if shape then
			glow:SetTexture(shape.glow, 'CLAMP', 'CLAMP', 'TRILINEAR')
			local size = math.max(w, h) * shape.glowScale
			glow:SetSize(size, size)
		else
			glow:SetTexture(GLOW_SQUARE, 'CLAMP', 'CLAMP', 'TRILINEAR')
			glow:SetSize(w * ActionButtons.GLOW_SQUARE_SCALE, h * ActionButtons.GLOW_SQUARE_SCALE)
		end
		local c = Theme.Mix(Theme.COLORS.lime, { 1, 1, 1 }, 0.25)
		Theme:Gradient(glow, 'HORIZONTAL', c, c, 1, 1)
		glow:Show()
		if glow.pulse and not (glow.pulse.IsPlaying and glow.pulse:IsPlaying()) then glow.pulse:Play() end
	else
		if glow.pulse then glow.pulse:Stop() end
		glow:Hide()
	end
end

local Overlayed = (C_SpellActivationOverlay and C_SpellActivationOverlay.IsSpellOverlayed) or _G.IsSpellOverlayed

local function SpellOf(button)
	if not button.GetSpellId then return nil end
	local ok, id = pcall(button.GetSpellId, button)
	return ok and Plain(id) or nil
end

local function HasAction(button)
	if not button.HasAction then return true end
	local ok, has = pcall(button.HasAction, button)
	if not ok then return true end
	has = Plain(has)
	return has == nil or has and true or false
end

-- ring of empty slots, the proc halo, charge-cooldown swipes created later, and
-- the square backdrop kept clear after ElvUI restyles a button
function ActionButtons:UpdateStates()
	local on = On()
	local combat = InCombatLockdown()
	for _, entry in ipairs(self.Buttons()) do
		local button = entry.button
		local parts = skinned[button]
		if parts and parts.active then
			if not combat and Refit(parts, button) then ActionButtons.Fit(parts, button) end
			parts.ring:SetAlpha(HasAction(button) and 1 or self.EMPTY_ALPHA)
			Swipe(button, parts.shape)
			if not combat then SetBackdropHidden(button, true) end
		end
		local proc = false
		if on then
			local id = SpellOf(button)
			if id then
				proc = procs[id] or false
				if not proc and Overlayed then
					local ok, value = pcall(Overlayed, id)
					proc = ok and Plain(value) == true
				end
			end
		end
		ShowGlow(entry, proc)
	end
end

function ActionButtons:Schedule()
	if scheduled then return end
	scheduled = true
	C_Timer.After(0.05, function()
		scheduled = false
		ActionButtons:UpdateStates()
	end)
end

function ActionButtons:OnEvent(event, arg1)
	if event == 'PLAYER_REGEN_ENABLED' then
		if pending then self:Refresh() end
		return
	end
	if event == 'SPELL_ACTIVATION_OVERLAY_GLOW_SHOW' or event == 'SPELL_ACTIVATION_OVERLAY_GLOW_HIDE' then
		local id = Plain(arg1)
		if id then procs[id] = (event == 'SPELL_ACTIVATION_OVERLAY_GLOW_SHOW') or nil end
	end
	self:Schedule()
end

function ActionButtons:Refresh()
	if InCombatLockdown() then
		pending = true
		return
	end
	pending = false
	local on = On()
	local count = 0
	for _, entry in ipairs(self.Buttons()) do
		if on and entry.cluster then
			self:Skin(entry)
			count = count + 1
		else
			self:Unskin(entry.button)
		end
	end
	self.count = count
	self:UpdateStates()
	return count
end

function ActionButtons:Get(button)
	return skinned[button]
end

function ActionButtons:GetGlow(button)
	return glows[button]
end

local frame = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_REGEN_ENABLED', 'SPELL_ACTIVATION_OVERLAY_GLOW_SHOW', 'SPELL_ACTIVATION_OVERLAY_GLOW_HIDE',
	'ACTIONBAR_SLOT_CHANGED', 'ACTIONBAR_PAGE_CHANGED', 'UPDATE_BONUS_ACTIONBAR', 'ACTIONBAR_UPDATE_COOLDOWN', 'PLAYER_ENTERING_WORLD',
	'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED' }) do
	pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript('OnEvent', function(_, event, arg1) ActionButtons:OnEvent(event, arg1) end)
