--[[
	BANZAI - TargetPlate.lua  (Banzai Art)
	Part of BANZAI UI. Credits and notices: the docs folder of the Banzai addon.

	0.6.0: the nameplate of the CURRENTLY TARGETED ENEMY gets the Banzai
	treatment on top of ElvUI's own plate; every other plate stays as ElvUI
	draws it (lighter, simpler):

	  gradient  a smooth gradient over the health fill: the class colour for an
	            enemy player whose class the game reports, the reaction colour
	            (hostile red, neutral amber) for an NPC. It is anchored to the
	            bar's own fill texture, so it follows the health exactly.
	  health    current health at the left end and the percentage at the right
	            end, inside the bar, through ElvUI's tag system (the same tags as
	            the Player / Target bars); bright over the fill, ghosted over the
	            empty part; ElvUI's own health text on that plate steps aside.
	            No health value is read here (12.x secret values).
	  name      directly above the bar and the green target arrows on both sides
	            come from the Banzai nameplate settings (BushidoPrivateRestore)

	The plate is found through C_NamePlate.GetNamePlateForUnit('target') and
	ElvUI's unitFrame on it; plates are recycled, so the treatment is shown only
	while that plate is the target's. Nothing secure is created or changed.

	1.3.0 ENHANCED TARGET NAMEPLATE (BANZAI SPLIT only, its own switch, on by
	default): the same plate - still only the current target's, every other
	plate exactly as before - gets the split language on top of the treatment
	above: a small central-style hub at the bar's left end (the class art for
	enemy players, the portrait for NPCs) that turns into the spell icon with
	the radial progress while the target casts (Split.lua's cast presentation,
	the game's own duration object; ElvUI's plate cast bar stays below), and a
	thin green -> purple outline around the bar marking the target.
]]
local _, ns = ...
local Theme = ns.Theme

local TargetPlate = {}
ns.TargetPlate = TargetPlate

TargetPlate.TEXT = { side = 'LEFT', x = 4, y = 0, value = 10, percent = 9, split = true }
TargetPlate.REACTION = {
	hostile = { 0.94, 0.16, 0.14 },
	neutral = { 1.00, 0.72, 0.12 },
}
TargetPlate.ALPHA = 0.92

local decorations = {} -- [ElvUI plate frame] = { overlay, health }
local current
local scheduled = false

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

local function Plain(value)
	if IsSecret(value) then return nil end
	return value
end

-- 1.3.0: the enhanced plate (BANZAI SPLIT this session and its switch on)
local function Enhanced()
	local split = ns.Split
	return split and split.Session and split:Session() and Theme:DB().splitTargetPlate ~= false or false
end
TargetPlate.Enhanced = Enhanced

local function Active()
	return ns.Compat and ns.Compat.Active and ns.Compat.Active() and (Theme:DB().targetPlate ~= false or Enhanced()) or false
end

local function TargetFrame()
	local api = _G.C_NamePlate
	local plate = api and api.GetNamePlateForUnit and api.GetNamePlateForUnit('target')
	return plate and plate.unitFrame
end
TargetPlate.TargetFrame = TargetFrame

local function IsEnemy(frame)
	local kind = Plain(frame.frameType)
	return type(kind) == 'string' and string.find(kind, '^ENEMY') ~= nil
end

-- colour of the gradient: class (enemy players) or reaction (NPCs); nil = leave ElvUI's colour
function TargetPlate.Color(frame)
	if Plain(frame.frameType) == 'ENEMY_PLAYER' then
		local _, token = UnitClass('target')
		token = Plain(token)
		if token then return Theme:ClassColor(token) end
		return nil
	end
	local reaction = UnitReaction and Plain(UnitReaction('target', 'player'))
	if type(reaction) == 'number' and reaction == 4 then return TargetPlate.REACTION.neutral end
	return TargetPlate.REACTION.hostile
end

local function Build(frame)
	local bar = frame.Health
	local fill = bar and bar.GetStatusBarTexture and bar:GetStatusBarTexture()
	if not fill then return nil end
	local overlay = bar:CreateTexture(nil, 'ARTWORK', nil, 7)
	overlay:SetTexture(Theme.MEDIA .. 'BanzaiBar')
	overlay:SetAllPoints(fill)
	local health = ns.Health and ns.Health.Attach and ns.Health:Attach(bar, TargetPlate.TEXT)
	if health and frame.Tag then
		for _, set in ipairs({ health.ghost, health.bright }) do
			frame:Tag(set.value, ns.Health.VALUE_TAG)
			frame:Tag(set.percent, ns.Health.PERCENT_TAG)
		end
	end
	local deco = { overlay = overlay, health = health, frame = frame }
	decorations[frame] = deco
	return deco
end

-- 1.3.0 the enhanced parts, made the first time this plate is the target's in a split session
local function BuildEnhanced(deco)
	if deco.hub or not (ns.Identity and ns.Identity.Hub) then return deco.hub end
	local bar = deco.frame.Health
	local P = ns.Split.PLATE
	local hub = ns.Identity.Hub(bar, P.hub)
	hub:SetPoint('RIGHT', bar, 'LEFT', -P.gap, 0)
	hub:SetFrameLevel((bar.GetFrameLevel and bar:GetFrameLevel() or 1) + 3)
	hub.castSize = 9
	hub.plate = true -- 1.3.1: nameplates are frozen - the spell name keeps the small font (Split.lua CastFonts)
	hub.castName:ClearAllPoints()
	hub.castName:SetPoint('TOPLEFT', bar, 'BOTTOMLEFT', 0, -2) -- under the bar, clear of the name above it
	deco.hub = hub
	local o = CreateFrame('Frame', nil, bar)
	o:SetPoint('TOPLEFT', bar, 'TOPLEFT', -P.outline, P.outline)
	o:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', P.outline, -P.outline)
	o:SetFrameLevel((bar.GetFrameLevel and bar:GetFrameLevel() or 1) + 2)
	o.edges = {}
	for i, side in ipairs({ { 'TOPLEFT', 'TOPRIGHT', true }, { 'BOTTOMLEFT', 'BOTTOMRIGHT', true }, { 'TOPLEFT', 'BOTTOMLEFT', false }, { 'TOPRIGHT', 'BOTTOMRIGHT', false } }) do
		local t = o:CreateTexture(nil, 'OVERLAY')
		t:SetTexture(Theme.WHITE)
		t:SetPoint(side[1], o, side[1], 0, 0)
		t:SetPoint(side[2], o, side[2], 0, 0)
		if side[3] then
			t:SetHeight(1)
			Theme:Gradient(t, 'HORIZONTAL', Theme.COLORS.lime, Theme.COLORS.violet, 1, 1)
		else
			t:SetWidth(1)
			t:SetVertexColor(side[1] == 'TOPLEFT' and Theme.COLORS.lime[1] or Theme.COLORS.violet[1], side[1] == 'TOPLEFT' and Theme.COLORS.lime[2] or Theme.COLORS.violet[2], side[1] == 'TOPLEFT' and Theme.COLORS.lime[3] or Theme.COLORS.violet[3], 1)
		end
		o.edges[i] = t
	end
	deco.outline = o
	return hub
end
TargetPlate.BuildEnhanced = BuildEnhanced

-- ElvUI's own health text on that plate steps aside while Banzai's is shown
-- (1.3.0: the gradient and texts follow the targeted-plate switch; a split session's
-- enhanced parts their own - with the classic treatment off, only the hub and the outline)
local function Show(deco, shown)
	local classic = shown and Theme:DB().targetPlate ~= false
	deco.overlay:SetShown(classic)
	if deco.health then deco.health.holder:SetShown(classic) end
	local text = deco.frame and deco.frame.Health and deco.frame.Health.Text
	if text and text.SetAlpha then text:SetAlpha(classic and 0 or 1) end
	-- 1.3.0: the enhanced parts only on the current target's plate in a split session
	local enhanced = shown and Enhanced()
	if enhanced then BuildEnhanced(deco) end
	if deco.hub then deco.hub:SetShown(enhanced and true or false) end
	if deco.outline then deco.outline:SetShown(enhanced and true or false) end
end

function TargetPlate:Apply()
	if not Active() then return end
	local frame = TargetFrame()
	if not (frame and frame.Health and IsEnemy(frame)) then return end
	local deco = decorations[frame] or Build(frame)
	if not deco then return end
	Show(deco, true)
	local c = Theme:DB().targetPlate ~= false and self.Color(frame) -- 1.3.0: only with the targeted-plate treatment on
	if c then
		Theme:Gradient(deco.overlay, 'HORIZONTAL', { c[1] * 0.55, c[2] * 0.55, c[3] * 0.55 }, Theme.Mix(c, { 1, 1, 1 }, 0.2), self.ALPHA, self.ALPHA)
	else
		deco.overlay:Hide() -- class not reported: ElvUI's own colour stays
	end
	if deco.health and frame.UpdateTags then pcall(frame.UpdateTags, frame) end
	if deco.hub and Enhanced() then ns.Split.PaintIdentity(deco.hub, 'target', { npc = true }) end -- 1.3.0: the class art / portrait before the cast state
	current = deco
	return deco
end

function TargetPlate:Update()
	if current then Show(current, false) current = nil end
	local deco = self:Apply()
	-- 1.3.0: the target's casts go to the enhanced plate's hub while one is shown (none otherwise)
	if ns.Split and ns.Split.SetPlateHub then ns.Split:SetPlateHub((deco and deco.hub and Enhanced()) and deco.hub or nil) end
	return deco
end

function TargetPlate:Schedule()
	if scheduled then return end
	scheduled = true
	C_Timer.After(0, function() -- after ElvUI has set the plate up for its unit
		scheduled = false
		TargetPlate:Update()
	end)
end

function TargetPlate:Refresh()
	self:Update()
end

function TargetPlate:Get(frame)
	return decorations[frame]
end

local events = CreateFrame('Frame')
for _, event in ipairs({ 'PLAYER_TARGET_CHANGED', 'NAME_PLATE_UNIT_ADDED', 'NAME_PLATE_UNIT_REMOVED', 'UNIT_FACTION' }) do
	pcall(events.RegisterEvent, events, event)
end
events:SetScript('OnEvent', function() TargetPlate:Schedule() end)
