-- Minimal WoW / ElvUI / Details / LibSharedMedia / tracker stand-ins for the offline tests.
unpack = table.unpack
format = string.format
date = os.date
HK_PRINTS, HK_POPUPS, HK_TIMERS, HK_IN_COMBAT = {}, {}, {}, false
function print(...) local t = {} for i = 1, select('#', ...) do t[#t + 1] = tostring(select(i, ...)) end HK_PRINTS[#HK_PRINTS + 1] = table.concat(t, ' ') end

-- frames / textures
local Methods = {}
local Meta = { __index = Methods }
local allFrames = {}
local function New(kind, name, parent)
	local o = setmetatable({ kind = kind, name = name, parent = parent, shown = true, events = {}, scripts = {}, points = {} }, Meta)
	if name then _G[name] = o end
	allFrames[#allFrames + 1] = o
	return o
end
HK_NewFrame = New
function Methods:RegisterEvent(e) self.events[e] = true end
function Methods:UnregisterEvent(e) self.events[e] = nil end
function Methods:SetScript(s, f) self.scripts[s] = f end
function Methods:SetFrameStrata(s) self.strata = s end
function Methods:SetFixedFrameStrata(v) self.fixedStrata = v end
function Methods:SetFrameLevel(l) self.level = l end
function Methods:GetFrameLevel() return self.level or 1 end
function Methods:SetSize(w, h) self.w, self.h = w, h end
function Methods:SetPoint(p, rel, relP, x, y) self.points[#self.points + 1] = { p, rel, relP, x, y } end
function Methods:ClearAllPoints() self.points = {} end
function Methods:SetAllPoints(rel) self.allPoints = rel or true end
function Methods:EnableMouse(v) self.mouse = v and true or false end
function Methods:Show() self.shown = true end
function Methods:Hide() self.shown = false end
function Methods:SetShown(v) self.shown = v and true or false end
function Methods:IsShown() return self.shown end
function Methods:CreateTexture(_, layer, _, sublevel)
	local t = New('Texture', nil, self)
	t.layer, t.sublevel = layer, sublevel
	self.textures = self.textures or {}
	self.textures[#self.textures + 1] = t
	return t
end
function Methods:CreateMaskTexture()
	local m = New('MaskTexture', nil, self)
	self.maskTextures = self.maskTextures or {}
	self.maskTextures[#self.maskTextures + 1] = m
	return m
end
function Methods:SetTexture(p, wrapH, wrapV, filter) self.path, self.wrapH, self.wrapV, self.filter = p, wrapH, wrapV, filter end
function Methods:SetSnapToPixelGrid(v) self.snap = v end
function Methods:SetTexelSnappingBias(v) self.texelBias = v end
function Methods:EnableMouseWheel(v) self.wheel = v and true or false end
function Methods:SetScrollChild(child) self.scrollChild = child end
function Methods:SetVerticalScroll(v) self.verticalScroll = v end
function Methods:SetAtlas(a) self.atlas = a end
function Methods:SetTexCoord(...) self.coords = { ... } end
function Methods:SetRotation(r) self.rotation = r end
function Methods:SetVertexColor(r, g, b, a) self.color = { r, g, b, a } self.gradient = nil end
function Methods:SetGradient(orientation, from, to) self.gradient = { orientation, from, to } end
function Methods:SetAlpha(a) self.alpha = a end
function Methods:AddMaskTexture(m) self.masks = self.masks or {} self.masks[#self.masks + 1] = m end
function Methods:SetBackdropBorderColor(r, g, b, a) self.borderColor = { r, g, b, a } end
function Methods:SetBackdropColor(r, g, b, a) self.backdropColor = { r, g, b, a } end
function Methods:SetMaskTexture(p) self.mask = p end
function Methods:GetAttribute(k) return self.attributes and self.attributes[k] end
function Methods:SetWidth(w) self.w = w end
function Methods:SetHeight(h) self.h = h end
function Methods:GetWidth() return self.w or 0 end
function Methods:SetDrawLayer(layer, sublevel) self.layer, self.sublevel = layer, sublevel end
function Methods:RegisterForClicks() end
function Methods:RegisterUnitEvent(e, unit) self.events[e] = true self.unitEvents = self.unitEvents or {} self.unitEvents[e] = unit end
function Methods:SetClipsChildren(v) self.clips = v end
function Methods:GetStatusBarTexture() self.fill = self.fill or New('Texture', nil, self) return self.fill end
function Methods:Tag(fs, tag) self.tags = self.tags or {} self.tags[#self.tags + 1] = { fs, tag } fs.tag = tag end
function Methods:UpdateTags() self.tagsUpdated = (self.tagsUpdated or 0) + 1 end
function Methods:GetHeight() return self.h or 0 end
function Methods:SetScale(s) self.scale = s end
function Methods:SetDesaturated(v) self.desaturated = v end
function Methods:SetShadowOffset(x, y) self.shadow = { x, y } end
function Methods:SetTextColor(r, g, b, a) self.textColor = { r, g, b, a or 1 } end
function Methods:SetWordWrap(v) self.wordWrap = v end
function Methods:GetStringHeight() return (self.fontSize or 10) + 2 end
function Methods:GetName() return self.name end
function Methods:RemoveMaskTexture(m) for i, x in ipairs(self.masks or {}) do if x == m then table.remove(self.masks, i) break end end end
function Methods:SetSwipeTexture(p) self.swipe = p end
function Methods:GetHighlightTexture() return self.highlightTexture end
function Methods:GetPushedTexture() return self.pushedTexture end
function Methods:GetCheckedTexture() return self.checkedTexture end
function Methods:SetStatusBarTexture(p) self.statusTexture = p self.fill = self.fill or New('Texture', nil, self) self.fill.path = p end
function Methods:SetMinMaxValues(a, b) self.min, self.max = a, b end
function Methods:SetValue(v) self.value = v end
function Methods:GetRect() if self.rect then return unpack(self.rect) end end
function Methods:GetEffectiveScale() return self.effectiveScale or 1 end
function Methods:GetAlpha() return self.alpha or 1 end
function Methods:SetBlendMode(m) self.blend = m end
function Methods:SetVertexOffset(i, x, y) self.vertex = self.vertex or {} self.vertex[i] = { x, y } end
function Methods:CreateAnimationGroup()
	local g = { playing = false, anims = {} }
	function g:CreateAnimation(kind)
		local a = { kind = kind }
		function a:SetFromAlpha(v) self.from = v end
		function a:SetToAlpha(v) self.to = v end
		function a:SetDuration(v) self.duration = v end
		self.anims[#self.anims + 1] = a
		return a
	end
	function g:SetLooping(v) self.looping = v end
	function g:Play() self.playing = true end
	function g:Stop() self.playing = false end
	function g:IsPlaying() return self.playing end
	self.animationGroup = g
	return g
end
function Methods:CreateFontString(_, _, template)
	local fs = New('FontString', nil, self)
	fs.template = template -- 1.3.1: a template gives the font string its font
	self.fontStrings = self.fontStrings or {}
	self.fontStrings[#self.fontStrings + 1] = fs
	return fs
end
function Methods:SetFont(path, size, flags) self.font, self.fontSize, self.fontFlags = path, size, flags return HK_FONT_FAILS ~= path end -- 1.3.1: as the client, true when the font loaded
-- 1.3.1: as the game - SetText on a font string that has no font yet is an error ("Font not set"; the 1.3.0 split frames' fault)
function Methods:SetText(text)
	if self.kind == 'FontString' and not self.font and not self.template then error('FontString:SetText(): Font not set', 2) end
	self.text = text
end
function Methods:SetShadowColor(r, g, b, a) self.shadowColor = { r, g, b, a } end
-- the widget formats (secret values stay inside it): a secret argument is kept as given
function Methods:SetFormattedText(fmt, ...)
	self.formatArgs = { ... }
	if issecretvalue(self.formatArgs[1]) then self.text = self.formatArgs[1] else self.text = string.format(fmt, ...) end
end
function Methods:GetText() return self.text end
function Methods:SetJustifyH(j) self.justify = j end
function Methods:GetStringWidth()
	local plain = (self.text or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''):gsub('|T.-|t', 'II')
	return #plain * (self.fontSize or 10) * 0.6
end
function CreateFrame(kind, name, parent) return New(kind, name, parent) end
function CreateColor(r, g, b, a) return { r = r, g = g, b = b, a = a } end
function HK_Plain(text) return ((text or ''):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')) end
function HK_Fire(event, ...)
	local unit = ...
	for _, f in ipairs(allFrames) do
		local only = f.unitEvents and f.unitEvents[event]
		if f.events[event] and f.scripts.OnEvent and (not only or only == unit) then f.scripts.OnEvent(f, event, ...) end
	end
end
function HK_Children(parent)
	local list = {}
	for _, f in ipairs(allFrames) do
		if f.parent == parent and f.kind == 'Frame' then list[#list + 1] = f end
	end
	return list
end
-- 1.2.0: every frame (any kind) whose parent is this frame
function Methods:GetChildren()
	local list = {}
	for _, f in ipairs(allFrames) do if f.parent == self and f.kind ~= 'Texture' and f.kind ~= 'FontString' and f.kind ~= 'MaskTexture' then list[#list + 1] = f end end
	return unpack(list)
end
function HK_RunTimers() local list = HK_TIMERS HK_TIMERS = {} for _, fn in ipairs(list) do fn() end end

UIParent = New('Frame', 'UIParent')
UIParent.w = 1923
-- 1.0.2: frames that change parent, and Blizzard's objective tracker
function Methods:SetParent(p) self.parent = p self.parentChanges = (self.parentChanges or 0) + 1 end
function Methods:GetParent() return self.parent end
ObjectiveTrackerFrame = New('Frame', 'ObjectiveTrackerFrame', UIParent)
function ObjectiveTrackerFrame:IsCollapsed() return self.collapsed and true or false end
function ObjectiveTrackerFrame:SetCollapsed(v) self.collapsed = v and true or false self.collapseChanges = (self.collapseChanges or 0) + 1 end
Minimap = New('Frame', 'Minimap', UIParent)
Minimap.w = 185
HK_ZONE = 'Dornogal'
function GetMinimapZoneText() return HK_ZONE end

-- quest log (supported API only) and spells
HK_QUESTS = {
	[101] = { title = 'The Bamboo Path', objectives = { { text = 'Bamboo gathered: 3/5', finished = false }, { text = 'Speak to the elder', finished = true } } },
	[202] = { title = 'Rings of Dornogal', complete = true, objectives = {} },
	[303] = { title = 'World Quest: Glass Shards', objectives = { { text = 'Shards: 1/8', finished = false } } },
}
HK_WATCHES, HK_WQ_WATCHES, HK_SUPERTRACK = { 101, 202 }, { 303 }, 101
C_QuestLog = {
	GetNumQuestWatches = function() return #HK_WATCHES end,
	GetQuestIDForQuestWatchIndex = function(i) return HK_WATCHES[i] end,
	GetNumWorldQuestWatches = function() return #HK_WQ_WATCHES end,
	GetQuestIDForWorldQuestWatchIndex = function(i) return HK_WQ_WATCHES[i] end,
	GetTitleForQuestID = function(id) return HK_QUESTS[id] and HK_QUESTS[id].title end,
	GetQuestObjectives = function(id) return HK_QUESTS[id] and HK_QUESTS[id].objectives or {} end,
	IsComplete = function(id) return HK_QUESTS[id] and HK_QUESTS[id].complete or false end,
}
C_SuperTrack = {
	GetSuperTrackedQuestID = function() return HK_SUPERTRACK end,
	SetSuperTrackedQuestID = function(id) HK_SUPERTRACK = id end,
}
function QuestMapFrame_OpenToQuestDetails(id) HK_OPENED_QUEST = id end
HK_SPELLS = { [5221] = { 'Shred', 132152 }, [1822] = { 'Rake', 132122 }, [106830] = { 'Thrash', 451161 }, [22568] = { 'Ferocious Bite', 132127 } }
C_Spell = {
	GetSpellInfo = function(id) local s = HK_SPELLS[id] if s then return { name = s[1], iconID = s[2] } end end,
	-- a hidden (secret) spell ID resolves to a name / icon the addon only passes on
	GetSpellName = function(id) if id == 'SECRET' then return 'Hidden Spell' end local s = HK_SPELLS[id] return s and s[1] end,
	GetSpellTexture = function(id) if id == 'SECRET' then return 4242 end local s = HK_SPELLS[id] return s and s[2] end,
}
HK_TICKERS = {}
C_Timer = {
	After = function(_, fn) HK_TIMERS[#HK_TIMERS + 1] = fn end,
	NewTicker = function(_, fn) HK_TICKERS[#HK_TICKERS + 1] = fn return {} end,
}
HK_LOADED = { Details = true, JiberishMedia = true, ElvUI = true, ElvUI_EltreumUI = true, ElvUI_mMediaTag = true, JiberishIcons = true }
HK_INSTALLED = { ['!KalielsTracker'] = 'DISABLED' }
C_AddOns = {
	IsAddOnLoaded = function(name) return HK_LOADED[name] == true end,
	GetAddOnInfo = function(name) return name, name, '', true, HK_LOADED[name] and nil or (HK_INSTALLED[name] or 'MISSING') end,
	GetAddOnMetadata = function(name, field) if field == 'Version' then return '1.0' elseif field == 'Author' then return 'Author of ' .. name end end,
}

-- player data (Darren's druid); HK_SPEC_INDEX switches the spec (role) in the tests
HK_SPEC_INDEX = 2
HK_SPECINFO = { [1] = { 102, 'Balance', '', 136096, 'DAMAGER' }, [2] = { 103, 'Feral', '', 132115, 'DAMAGER' }, [3] = { 104, 'Guardian', '', 132276, 'TANK' }, [4] = { 105, 'Restoration', '', 136041, 'HEALER' } }
function GetSpecialization() return HK_SPEC_INDEX end
function GetSpecializationInfo(i) local s = HK_SPECINFO[i] if s then return s[1], s[2], s[3], s[4], s[5] end end
function GetRealmName() return 'Stormrage' end
HK_INSTANCE = 'none'
function IsInInstance() return HK_INSTANCE ~= 'none', HK_INSTANCE end
function GetPhysicalScreenSize() return 2560, 1440 end
HK_ARENA_SPECS = {}
function GetArenaOpponentSpec(i) return HK_ARENA_SPECS[i] end
CLASS_ICON_TCOORDS = { DRUID = { 0.75, 1, 0, 0.25 }, MAGE = { 0.25, 0.5, 0, 0.25 }, SHAMAN = { 0.25, 0.5, 0.25, 0.5 }, PALADIN = { 0, 0.25, 0.5, 0.75 }, PRIEST = { 0.5, 0.75, 0.25, 0.5 }, ROGUE = { 0.5, 0.75, 0, 0.25 } }
-- nameplates: C_NamePlate gives the Blizzard plate, ElvUI's frame is plate.unitFrame
HK_PLATES, HK_REACTION = {}, {}
C_NamePlate = { GetNamePlateForUnit = function(unit) return HK_PLATES[unit] end }
function UnitReaction(unit) return HK_REACTION[unit] end
-- gameplay-data APIs: Banzai must never call these (Character Sync keeps them per character)
HK_GAMEPLAY_CALLS = {}
for _, name in ipairs({ 'SetBinding', 'SetBindingClick', 'SaveBindings', 'CreateMacro', 'EditMacro', 'DeleteMacro', 'PickupAction', 'PlaceAction', 'ClearCursor', 'SetSpecialization', 'C_EquipmentSet', 'LearnTalent' }) do
	_G[name] = function() HK_GAMEPLAY_CALLS[#HK_GAMEPLAY_CALLS + 1] = name end
end
-- 1.0.1: more of what a sync must never touch (talent loadouts, override bindings, spells / macros on the cursor, gear)
for _, name in ipairs({ 'SetOverrideBinding', 'ClearOverrideBindings', 'LoadBindings', 'PickupSpell', 'PickupMacro', 'EquipItemByName', 'UseEquipmentSet', 'SetLootSpecialization' }) do
	_G[name] = function() HK_GAMEPLAY_CALLS[#HK_GAMEPLAY_CALLS + 1] = name end
end
C_ClassTalents = {}
for _, name in ipairs({ 'LoadConfig', 'CommitConfig', 'SetUsesSharedActionBars', 'UpdateLastSelectedSavedConfigID' }) do
	C_ClassTalents[name] = function() HK_GAMEPLAY_CALLS[#HK_GAMEPLAY_CALLS + 1] = 'C_ClassTalents.' .. name end
end
C_Traits = { CommitConfig = function() HK_GAMEPLAY_CALLS[#HK_GAMEPLAY_CALLS + 1] = 'C_Traits.CommitConfig' end }
function C_CurrencyInfo_Stub(id) return { quantity = (id == 1792) and 12345 or 1650 } end
C_CurrencyInfo = { GetCurrencyInfo = C_CurrencyInfo_Stub }
function GetMasteryEffect() return 34.56 end
function GetHaste() return 21.04 end
CR_VERSATILITY_DAMAGE_DONE = 29
function GetCombatRatingBonus() return 8.5 end
function GetVersatilityBonus() return 1.5 end
HK_DURABILITY = { [1] = { 40, 100 }, [5] = { 90, 100 } }
function GetInventoryItemDurability(slot) local d = HK_DURABILITY[slot] if d then return d[1], d[2] end end
function GetFramerate() return 143.6 end
function GetNetStats() return 0, 0, 38, 45 end
function GetAverageItemLevel() return 714.2, 712.6, 718.1 end
function GetProfessions() return 1, 2 end
function GetProfessionInfo(i) return (i == 1 and 'Herbalism' or 'Alchemy'), (i == 1 and 136246 or 136240), 100 end
C_FriendList = { GetNumOnlineFriends = function() return 3 end }
function BNGetNumFriends() return 10, 4 end
function IsInGuild() return true end
function GetNumGuildMembers() return 50, 12, 14 end
function GetMoney() return 1234567890 end
StaticPopupDialogs, SlashCmdList = {}, {}
function StaticPopup_Show(name) HK_POPUPS[#HK_POPUPS + 1] = name end
function ReloadUI() end
function InCombatLockdown() return HK_IN_COMBAT end
-- 1.3.0: HK_Secret() values are secret (everything else is plain)
HK_SECRET_SET = setmetatable({}, { __mode = 'k' })
function HK_IsSecret(v) return type(v) == 'table' and HK_SECRET_SET[v] == true end
issecretvalue = HK_IsSecret
function UnitIsUnit(a, b) return a == b end
HK_OVERLAYED = {}
-- inspect data (the game's own spec of another player)
HK_GUIDS, HK_INSPECT, HK_NOW, HK_INSPECT_REQUESTS = { player = 'Player-1', target = 'Player-2' }, {}, 100, {}
function UnitGUID(unit) return HK_GUIDS[unit] end
function GetTime() return HK_NOW end
function CanInspect(unit) return HK_UNITS[unit] ~= nil end
function NotifyInspect(unit) HK_INSPECT_REQUESTS[#HK_INSPECT_REQUESTS + 1] = unit end
function ClearInspectPlayer() HK_INSPECT_CLEARED = (HK_INSPECT_CLEARED or 0) + 1 end
function GetInspectSpecialization(unit) return HK_INSPECT[HK_GUIDS[unit]] or 0 end
HK_SPEC_BY_ID = { [62] = 'Arcane', [63] = 'Fire', [64] = 'Frost', [254] = 'Marksmanship' }
HK_SPEC_CLASS = { [62] = 'MAGE', [63] = 'MAGE', [64] = 'MAGE', [254] = 'HUNTER', [257] = 'PRIEST', [264] = 'SHAMAN' }
function GetSpecializationInfoByID(id) return id, HK_SPEC_BY_ID[id], '', 0, nil, HK_SPEC_CLASS[id] end
C_SpellActivationOverlay = { IsSpellOverlayed = function(id) return HK_OVERLAYED[id] == true end }
function GetScreenHeight() return 768 / 0.71 end
HK_UNITS = { player = 'DRUID', target = 'MAGE' }
function UnitExists(unit) return HK_UNITS[unit] ~= nil end
HK_CLASS_IDS = { WARRIOR = 1, PALADIN = 2, HUNTER = 3, ROGUE = 4, PRIEST = 5, DEATHKNIGHT = 6, SHAMAN = 7, MAGE = 8, WARLOCK = 9, MONK = 10, DRUID = 11, DEMONHUNTER = 12, EVOKER = 13 }
HK_CLASS_NAMES = { MAGE = 'Mage', HUNTER = 'Hunter', DRUID = 'Druid', SHAMAN = 'Shaman', PRIEST = 'Priest' }
function UnitClass(unit) local c = HK_UNITS[unit] if not c then return nil end return HK_CLASS_NAMES[c] or c, c, HK_CLASS_IDS[c] end
function UnitIsPlayer(unit) return HK_UNITS[unit] ~= nil and not HK_NPC[unit] end
HK_NPC = {}
HK_SPECS_BY_CLASS = { [8] = { 'Arcane', 'Fire', 'Frost' }, [3] = { 'Beast Mastery', 'Marksmanship', 'Survival' }, [11] = { 'Balance', 'Feral', 'Guardian', 'Restoration' } }
function GetNumSpecializationsForClassID(id) return #(HK_SPECS_BY_CLASS[id] or {}) end
function GetSpecializationInfoForClassID(id, i) local s = HK_SPECS_BY_CLASS[id] return 1000 + i, s and s[i] end
HK_TOOLTIP = {}
C_TooltipInfo = { GetUnit = function(unit) local lines = {} for _, t in ipairs(HK_TOOLTIP[unit] or {}) do lines[#lines + 1] = { leftText = t } end return { lines = lines } end }
HK_PLAYER_NAME = 'Darrensdrood'
function UnitName(unit) if unit == 'player' then return HK_PLAYER_NAME end end
RAID_CLASS_COLORS = {
	DRUID = { r = 1.0, g = 0.49, b = 0.04 },
	MAGE = { r = 0.25, g = 0.78, b = 0.92 },
	SHAMAN = { r = 0.0, g = 0.44, b = 0.87 },
	HUNTER = { r = 0.67, g = 0.83, b = 0.45 },
}

-- LibSharedMedia (fonts and the Eltruism / JiberishMedia names are present)
local media = {
	font = { GasoekOne = 'Interface\\AddOns\\JiberishMedia\\font\\GasoekOne.ttf', ['Rubik-Bold'] = 'Interface\\AddOns\\JiberishMedia\\font\\Rubik-Bold.ttf', ['Rubik-Regular'] = 'x', ['Montserrat-Bold'] = 'x', Expressway = 'x', RussoOne = 'x', ['Urbanist-Black'] = 'x' },
	statusbar = { OverwatchJiberish1 = 'x', OverwatchJiberish2 = 'x', OverwatchJiberish3 = 'x', OverwatchJiberish4 = 'x', ['Eltreum-Blank'] = 'x' },
}
local LSM = {
	IsValid = function(_, kind, name) return media[kind] and media[kind][name] ~= nil end,
	Fetch = function(_, kind, name) return media[kind] and media[kind][name] end,
	Register = function(_, kind, name, path) media[kind] = media[kind] or {} media[kind][name] = path return true end,
}
LibStub = setmetatable({}, { __call = function(_, name)
	if name == 'LibSharedMedia-3.0' then return LSM end
	return HK_LIBS and HK_LIBS[name]
end })

-- ElvUI
ElvDB = {
	profiles = { HARDKORHUI = { marker = 'darren-hardkorhui' }, breezy = { marker = 'darren-breezy' } },
	global = { general = { UIScale = 0.5333333333333333 }, datatexts = { settings = { Gold = { goldFormat = 'BLIZZARD' } } } },
}
ElvPrivateDB = {
	profileKeys = { ['Darrensdrood - Stormrage'] = 'breezy' },
	profiles = { breezy = { install_complete = 16, chat = { enable = false }, bags = { enable = false }, ElvUI_EltreumUI = { install_version = '5.1.6' } } },
}
HK_SETPROFILE = {}
local data = { current = 'HARDKORHUI', keys = { profile = 'HARDKORHUI' }, callbacks = {} }
function data:GetCurrentProfile() return self.current end
function data:SetProfile(name)
	self.current = name self.keys.profile = name HK_SETPROFILE[#HK_SETPROFILE + 1] = name
	ElvDB.profileKeys = ElvDB.profileKeys or {}
	ElvDB.profileKeys[ElvUI[1].mynameRealm] = name -- AceDB keeps the character's choice
end
function data.RegisterCallback(target, event, method) data.callbacks[#data.callbacks + 1] = { target, event, method } end
HK_ElvData = data
local E = { data = data, mynameRealm = 'Darrensdrood - Stormrage', Initialized = true, global = ElvDB.global, media = { unitframeBorderColor = { 0, 0, 0 } } }
-- same contract as ElvUI 16 General/Core.lua E:ForceBorderColor
function E:ForceBorderColor(frame, r, g, b, a)
	if r then frame.forcedBorderColors = { r, g, b, a } else frame.forcedBorderColors = nil end
end
HK_TAGS, HK_TAGINFO = {}, {}
HK_SPEC = { player = 'Feral', target = 'Frost' } -- what ElvUI's [spec] tag would return
E.oUF = { Tags = { Methods = { spec = function(unit) return HK_SPEC[unit] end } } }
function E:AddTag(name, events, fn) HK_TAGS[name] = { events = events, fn = fn } end
function E:AddTagInfo(name, category, desc) HK_TAGINFO[name] = { category, desc } end
HK_UF = { updates = 0 }
function HK_UF:Update_AllFrames() self.updates = self.updates + 1 end
HK_UF.headerUpdates = {}
function HK_UF:CreateAndUpdateHeaderGroup(group) self.headerUpdates[#self.headerUpdates + 1] = group end
-- 1.2.0: ElvUI's Auras module (its buff header update)
HK_AURA_HEADER_UPDATES = 0
HK_AURAS = { BuffFrame = {} }
function HK_AURAS:UpdateHeader(header) if header == self.BuffFrame then HK_AURA_HEADER_UPDATES = HK_AURA_HEADER_UPDATES + 1 end end
function E:GetModule(name) if name == 'UnitFrames' then return HK_UF elseif name == 'Auras' then return HK_AURAS end end
HK_MOVERS_SET = 0
function E:SetMoversPositions() HK_MOVERS_SET = HK_MOVERS_SET + 1 end
HK_MOVER_POINTS = {}
function E:SetMoverPoints(name) HK_MOVER_POINTS[#HK_MOVER_POINTS + 1] = name end
function E:ToggleOptions(msg) HK_OPENED = msg end
E.Options = { args = {} }
ElvUI = { E }
HK_PLUGINS = {}
HK_LIBS = {
	['LibElvUIPlugin-1.0'] = { RegisterPlugin = function(_, name, callback) HK_PLUGINS[name] = callback end },
}

-- Details
Details = {
	current = 'DarrenUI', profiles = { DarrenUI = { marker = 'darren-details' } },
	mythic_plus_log = { 'darren-history' },
	default_profile = {},
	always_use_profile = true, always_use_profile_name = 'DarrenUI', always_use_profile_exception = {},
	applied = {},
}
function Details:GetCurrentProfileName() return self.current end
function Details:GetProfile(name, create) if not self.profiles[name] and create then self.profiles[name] = {} end return self.profiles[name] end
function Details:ApplyProfile(name, noSave) self.current = name self.applied[#self.applied + 1] = { name, noSave } end
-- Details windows with the instance methods Banzai uses
local Window = {}
Window.__index = Window
function Window:IsEnabled() return self.ativa end
function Window:EnableInstance() self.ativa = true end
function Window:UngroupInstance() self.ungrouped = true self.snap = {} end
function Window:RestoreMainWindowPosition()
	local lw = self.libwindow
	self.baseframe.w, self.baseframe.h = self.posicao.normal.w, self.posicao.normal.h
	self.baseframe.points = { { lw.point, UIParent, lw.point, lw.x / lw.scale, lw.y / lw.scale } }
	self.restored = (self.restored or 0) + 1
end
function Window:SaveMainWindowPosition() self.saved = (self.saved or 0) + 1 end
function Window:ReajustaGump() self.adjusted = true end
function Window:GetSegment() return self.segmento end
function Window:SetDisplay(segment, attribute, sub) self.display = { segment, attribute, sub } end
function Window:InstanceRefreshRows() self.rowsRefreshed = (self.rowsRefreshed or 0) + 1 end
-- 1.3.0: Details' public bar settings call (re-anchors and refreshes the rows)
function Window:SetBarSettings(height, _, _, _, _, _, _, _, iconfile, barstart, spacement, _, iconSizeOffset) self.barSettings = { height = height, icon = iconfile, start = barstart, spacing = spacement, iconSize = iconSizeOffset } self.barSettingsCalls = (self.barSettingsCalls or 0) + 1 end
local function NewWindow(id)
	return setmetatable({ meu_id = id, ativa = true, window_scale = 0.75, segmento = -1, row_info = { fixed_text_color = { 1, 1, 1, 1 } }, posicao = { normal = { x = 0, y = 0, w = 374, h = 179 } }, libwindow = { point = 'BOTTOM', x = 498, y = 0, scale = 0.75 }, snap = { [1] = 2 }, baseframe = New('Frame', 'DetailsBaseFrame' .. id, UIParent) }, Window)
end
HK_DetailsWindow = NewWindow(1)
HK_DetailsWindow2 = NewWindow(2)
function Details:GetInstance(id) if id == 1 then return HK_DetailsWindow elseif id == 2 then return HK_DetailsWindow2 end end
DetailsFramework = { table = { copy = function(t, s) for k, v in pairs(s) do if type(v) == 'table' then t[k] = DetailsFramework.table.copy({}, v) else t[k] = v end end return t end } }

-- Kaliel's Tracker / MinimapButtonButton saved settings (Darren's values)
KalielsTrackerDB = {
	profileKeys = { ['Darrensdrood - Stormrage'] = 'breezy' },
	profiles = { breezy = { xOffset = 0, yOffset = -230, maxHeight = 862, frameScale = 0.751173734664917 }, Default = { yOffset = -230 } },
}
MinimapButtonButtonOptions = { scale = 8, position = { 'TOPRIGHT', nil, 'TOPRIGHT', 0, -237.6588745117188 } }

-- 1.0.3: what Banzai must never do (secure hooks: recorded, never expected), the
-- game's EventRegistry (Edit Mode announces itself there) and every frame made
function HK_Frames() return allFrames end
HK_HOOKS = {}
function hooksecurefunc(a, b, c) HK_HOOKS[#HK_HOOKS + 1] = { a, b, c } end
HK_REGISTRY = {}
EventRegistry = {
	RegisterCallback = function(_, event, fn, owner) HK_REGISTRY[event] = HK_REGISTRY[event] or {} table.insert(HK_REGISTRY[event], { fn = fn, owner = owner }) end,
	TriggerEvent = function(_, event, ...) for _, cb in ipairs(HK_REGISTRY[event] or {}) do cb.fn(cb.owner, ...) end end,
}

-- load the addon files like the client does
HK_NS = {}
for _, file in ipairs(HK_FILES) do
	local chunk = assert(loadfile(file))
	chunk('TestAddon', HK_NS)
end

-- 0.9.0: the player's cooldowns, arena trinket data, duration objects, addon list, secure hooks
HK_COOLDOWNS = {} -- [spellID] = { active = true, gcd = false, remaining = 40 }
HK_KNOWN = {}     -- [spellID] = true: the player knows it
HK_TRINKETS = {}  -- [unit] = remaining seconds (0 = ready); nil: the game gives nothing
function HK_Duration(remaining) return { remaining = remaining, GetRemainingDuration = function(self) return self.remaining end } end
C_Spell.GetSpellCooldown = function(id)
	local c = HK_COOLDOWNS[id]
	if not c then return { isActive = false, isOnGCD = false } end
	return { isActive = c.active, isOnGCD = c.gcd or false }
end
C_Spell.GetSpellCooldownDuration = function(id) local c = HK_COOLDOWNS[id] return c and HK_Duration(c.remaining or 0) end
C_SpellBook = { IsSpellKnown = function(id) return HK_KNOWN[id] == true end }
C_PvP = { GetArenaCrowdControlDuration = function(unit) local r = HK_TRINKETS[unit] if r == nil then return nil end return HK_Duration(r) end }
function Methods:SetCooldownFromDurationObject(d) self.durationObject = d self.shown = issecretvalue(d.remaining) or (d.remaining or 0) > 0 end
function Methods:Clear() self.durationObject = nil self.shown = false end
function Methods:SetUseCircularEdge(v) self.circular = v end
function Methods:SetDrawEdge(v) self.drawEdge = v end
function Methods:SetHideCountdownNumbers(v) self.hideNumbers = v end
function Methods:SetSwipeColor(...) self.swipeColor = { ... } end
function Methods:SetTimerDuration(d, interpolation, direction) self.timer = { d, interpolation, direction } end
Enum = Enum or {}
Enum.StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 }
Enum.StatusBarTimerDirection = { ElapsedTime = 0, RemainingTime = 1 }
HK_ADDON_ENABLED, HK_ADDON_CALLS = {}, {}
C_AddOns.GetAddOnEnableState = function(name) return HK_ADDON_ENABLED[name] or 0 end
C_AddOns.EnableAddOn = function(name, character) HK_ADDON_ENABLED[name] = 2 HK_ADDON_CALLS[#HK_ADDON_CALLS + 1] = { name = name, character = character, on = true } end
C_AddOns.DisableAddOn = function(name, character) HK_ADDON_ENABLED[name] = 0 HK_ADDON_CALLS[#HK_ADDON_CALLS + 1] = { name = name, character = character, on = false } end
HK_UF.groupUpdates = {}
function HK_UF:CreateAndUpdateUFGroup(group) self.groupUpdates[#self.groupUpdates + 1] = group end

-- 1.0.0: tooltips, the AFK screen's model and the game data the tooltips explain
function Methods:SetOwner(owner, anchor) self.owner, self.anchorType, self.lines, self.shown = owner, anchor, {}, false end
function Methods:IsOwned(owner) return self.owner == owner end
function Methods:ClearLines() self.lines = {} end
function Methods:AddLine(text, r, g, b, wrap) self.lines = self.lines or {} self.lines[#self.lines + 1] = { left = text, color = { r, g, b }, wrap = wrap } end
function Methods:AddDoubleLine(l, r, lr, lg, lb, rr, rg, rb) self.lines = self.lines or {} self.lines[#self.lines + 1] = { left = l, right = r, color = { rr, rg, rb } } end
function Methods:AppendInfo(kind, id) self.appended = self.appended or {} self.appended[#self.appended + 1] = { kind, id } self:AddLine('SPELL ' .. tostring(id)) end
function Methods:SetClampedToScreen(v) self.clamped = v end
function Methods:IsForbidden() return false end
function Methods:EnableKeyboard(v) self.keyboard = v and true or false end
function Methods:GetScale() return self.scale or 1 end
function Methods:SetUnit(unit) self.modelUnit = unit end
function Methods:SetFacing(f) self.facing = f end
function Methods:ClearModel() self.modelUnit = nil self.cleared = (self.cleared or 0) + 1 end
function Methods:SetCamDistanceScale(v) self.camDistance = v end
function Methods:SetPortraitZoom(v) self.portraitZoom = v end
function Methods:SetPosition(x, y, z) self.position = { x, y, z } end
function HK_TipText(tt)
	local out = {}
	for _, l in ipairs(tt.lines or {}) do out[#out + 1] = HK_Plain(tostring(l.left or '')) .. (l.right and ('  ' .. HK_Plain(tostring(l.right))) or '') end
	return table.concat(out, '\n')
end
GameTooltip = New('Frame', 'GameTooltip', UIParent)
GameTooltip.shown = false
for _, name in ipairs({ 'ItemRefTooltip', 'ShoppingTooltip1', 'ShoppingTooltip2' }) do New('Frame', name, UIParent) end
HK_AFK = false
function UnitIsAFK(unit) return unit == 'player' and HK_AFK end
function UnitLevel() return 80 end
function GetZoneText() return HK_ZONE end
C_PetBattles = { IsInBattle = function() return false end }
function GetBattlefieldStatus() return HK_BATTLEFIELD or 'none' end
-- stats / currencies / social data for the bottom-panel tooltips
CR_MASTERY, CR_HASTE_MELEE, CR_VERSATILITY_DAMAGE_TAKEN = 26, 18, 31
function GetCombatRating(id) return ({ [26] = 1234, [18] = 2345, [29] = 3456 })[id] or 0 end
function BreakUpLargeNumbers(n) return tostring(n) end
C_SpecializationInfo = { GetSpecialization = function() return HK_SPEC_INDEX end, GetSpecializationMasterySpells = function() return { 77493 } end }
STAT_MASTERY_TOOLTIP = 'Mastery rating of %s adds %.2f%% Mastery.'
STAT_HASTE_TOOLTIP = 'Increases attack and casting speed.'
STAT_HASTE_BASE_TOOLTIP = '\nHaste rating of %s adds %.2f%% Haste.'
CR_VERSATILITY_TOOLTIP = 'Increases damage and healing done by %.2f%% and decreases damage taken by %.2f%%.\n\nVersatility: %s [%.2f%%/%.2f%%]'
HK_CURRENCY = {
	[1792] = { name = 'Honor', quantity = 12345, maxQuantity = 15000, description = 'Earned in PvP.' },
	[1602] = { name = 'Conquest', quantity = 1650, totalEarned = 2200, maxQuantity = 0, useTotalEarnedForMaxQty = true },
}
C_CurrencyInfo.GetCurrencyInfo = function(id) return HK_CURRENCY[id] end
function UnitHonorLevel() return 120 end
function UnitHonor() return 4200 end
function UnitHonorMax() return 5500 end
function GetLootSpecialization() return 0 end
function GetGameTime() return 21, 5 end
C_DateAndTime = { GetCurrentCalendarTime = function() return { weekday = 3, monthDay = 27, month = 10, year = 2026 } end,
	GetSecondsUntilDailyReset = function() return 3 * 3600 + 20 * 60 end, GetSecondsUntilWeeklyReset = function() return 2 * 86400 + 3600 end }
HK_PROFS = { 1, 2, nil, 4, 5 }
function GetProfessions() return HK_PROFS[1], HK_PROFS[2], HK_PROFS[3], HK_PROFS[4], HK_PROFS[5] end
function GetProfessionInfo(i) return ({ 'Herbalism', 'Alchemy', 'Archaeology', 'Fishing', 'Cooking' })[i], 136240 + i, 100, 100 end
HK_BN = {}
function BNGetNumFriends() return #HK_BN, 0 end
C_BattleNet = { GetFriendAccountInfo = function(i) return HK_BN[i] end }
HK_WOW_FRIENDS = {}
C_FriendList.GetNumFriends = function() return #HK_WOW_FRIENDS end
C_FriendList.GetFriendInfoByIndex = function(i) return HK_WOW_FRIENDS[i] end
HK_GUILD = {}
function GetNumGuildMembers() return #HK_GUILD, 0 end
function GetGuildRosterInfo(i) local m = HK_GUILD[i] if m then return m[1], 'Member', 2, m[2], 'Druid', m[3], '', '', m[4], m[5], m[6], 0, 0, m[7] end end
function GetGuildInfo() return 'Bamboo Grove', 'Officer', 1 end
function GetGuildRosterMOTD() return 'Raid at eight.' end
function Ambiguate(name) return (string.gsub(name, '%-.*$', '')) end
HK_ROSTER_REQUESTS = 0
C_GuildInfo = { GuildRoster = function() HK_ROSTER_REQUESTS = HK_ROSTER_REQUESTS + 1 end }
HK_PANELS = {}
for _, name in ipairs({ 'TogglePVPUI', 'ToggleCharacter', 'ToggleCalendar', 'ToggleProfessionsBook', 'ToggleFriendsFrame', 'ToggleGuildFrame', 'ToggleAllBags' }) do
	_G[name] = function(arg) HK_PANELS[#HK_PANELS + 1] = name .. (arg ~= nil and ('(' .. tostring(arg) .. ')') or '') end
end
PlayerSpellsUtil = { FrameTabs = { ClassSpecializations = 1, ClassTalents = 2, SpellBook = 3 },
	TogglePlayerSpellsFrame = function(tab) HK_PANELS[#HK_PANELS + 1] = 'TogglePlayerSpellsFrame(' .. tostring(tab) .. ')' end }
C_Bank = { FetchDepositedMoney = function() return HK_WARBAND end }
Enum.BankType = { Account = 2 }
-- quest details for the tracker tooltips
HK_QUEST_LOG = { [101] = 3, [202] = 5 }
C_QuestLog.GetLogIndexForQuestID = function(id) return HK_QUEST_LOG[id] end
C_QuestLog.GetInfo = function(i)
	if i == 1 then return { isHeader = true, title = 'Isle of Dorn' } end
	if i == 3 then return { title = 'The Bamboo Path', level = 80, frequency = 1, campaignID = 0 } end
	if i == 5 then return { title = 'Rings of Dornogal', level = 79 } end
	return { title = 'other' }
end
C_QuestLog.GetQuestTagInfo = function(id) if id == 303 then return { tagName = 'World Quest' } end end
C_QuestLog.IsWorldQuest = function(id) return id == 303 end
C_QuestLog.GetQuestWatchType = function(id) if id == 101 then return 1 end if id == 202 then return 0 end end
C_QuestLog.GetTimeAllowed = function() return 0, 0 end
Enum.QuestWatchType = { Automatic = 0, Manual = 1 }
C_TaskQuest = { GetQuestZoneID = function() return 2248 end, GetQuestTimeLeftSeconds = function(id) return id == 303 and 5400 or nil end }
C_Map = { GetMapInfo = function() return { name = 'Isle of Dorn' } end }
-- ElvUI's options dialog (AceConfigDialog): status tables, an open window, group selection
HK_ACD = { Status = {}, OpenFrames = {}, selected = {} }
function HK_ACD:GetStatusTable(app, path)
	local key = app .. ':' .. table.concat(path or {}, ',')
	self.Status[key] = self.Status[key] or {}
	return self.Status[key]
end
function HK_ACD:SelectGroup(app, ...) self.selected[#self.selected + 1] = app .. ':' .. table.concat({ ... }, ',') end
ElvUI[1].Libs = { AceConfigDialog = HK_ACD }

-- tiny test API
local passed, failed, lines = 0, 0, {}
function test(name, fn)
	local ok, err = xpcall(fn, debug.traceback)
	if ok then passed = passed + 1 else failed = failed + 1 lines[#lines + 1] = 'FAIL ' .. name .. '\n' .. tostring(err) end
end
function expect(cond, msg) if not cond then error(msg or 'expectation failed', 2) end end
function expectEq(a, b, msg) if a ~= b then error(string.format('%s: expected [%s], got [%s]', msg or 'value', tostring(b), tostring(a)), 2) end end
function expectNear(a, b, msg) if type(a) ~= 'number' or math.abs(a - b) > 1e-6 then error(string.format('%s: expected [%s], got [%s]', msg or 'value', tostring(b), tostring(a)), 2) end end
function HK_REPORT() return passed, failed, table.concat(lines, '\n') end

-- search helpers
function HK_FindString(tbl, needle, seen)
	seen = seen or {}
	if seen[tbl] then return nil end
	seen[tbl] = true
	for k, v in pairs(tbl) do
		if type(v) == 'table' then
			local hit = HK_FindString(v, needle, seen)
			if hit then return tostring(k) .. '.' .. hit end
		elseif type(v) == 'string' and string.find(v, needle, 1, true) then
			return tostring(k)
		end
	end
end

-- 1.3.0 BANZAI SPLIT: the game's cast data, resources and NPC state, portraits, and secret values
-- that refuse to be read (any index, arithmetic, comparison, concatenation, length or tostring errors)
function HK_Secret(label)
	local fail = function() error('secret value read: ' .. tostring(label), 2) end
	local s = setmetatable({}, { __index = fail, __newindex = fail, __add = fail, __sub = fail, __mul = fail, __div = fail, __unm = fail,
		__concat = fail, __len = fail, __lt = fail, __le = fail, __eq = fail, __tostring = fail, __call = fail })
	HK_SECRET_SET[s] = true
	return s
end
HK_CASTS = {} -- [unit] = { kind = 'cast' | 'channel' | 'empower', name, texture, start, finish, notInterruptible, duration }
function UnitCastingInfo(unit) local c = HK_CASTS[unit] if c and c.kind == 'cast' then return c.name, 'text', c.texture, c.start, c.finish, false, 'cast-1', c.notInterruptible, 51505, c.barID or 7 end end
function UnitChannelInfo(unit) local c = HK_CASTS[unit] if c and c.kind ~= 'cast' then return c.name, 'text', c.texture, c.start, c.finish, false, c.notInterruptible, 234153, c.kind == 'empower', 3, c.barID or 8 end end
function UnitCastingDuration(unit) local c = HK_CASTS[unit] HK_DURATION_CALLS = (HK_DURATION_CALLS or 0) + 1 return c and c.kind == 'cast' and c.duration or nil end
function UnitChannelDuration(unit) local c = HK_CASTS[unit] return c and c.kind == 'channel' and c.duration or nil end
function UnitEmpoweredChannelDuration(unit) local c = HK_CASTS[unit] HK_EMPOWER_CALLS = (HK_EMPOWER_CALLS or 0) + 1 return c and c.kind == 'empower' and c.duration or nil end
HK_POWER = {} -- [unit] = { token = 'MANA', max = 100 }
function UnitPowerType(unit) local p = HK_POWER[unit] if p then return p.type or 0, p.token end return 0, 'MANA' end
function UnitPowerMax(unit) local p = HK_POWER[unit] if p then return p.max end return 100 end
HK_TAPPED, HK_OFFLINE, HK_CLASSIFICATION = {}, {}, {}
function UnitIsTapDenied(unit) return HK_TAPPED[unit] == true end
function UnitIsConnected(unit) return HK_OFFLINE[unit] ~= true end
function UnitClassification(unit) return HK_CLASSIFICATION[unit] or 'normal' end
HK_PORTRAITS = {}
function SetPortraitTexture(texture, unit) texture.portraitUnit = unit HK_PORTRAITS[#HK_PORTRAITS + 1] = unit end
function Methods:SetAlphaFromBoolean(value, yes, no) self.alphaBoolean = value if issecretvalue(value) then self.alpha = 'from-secret' else self.alpha = value and yes or no end end
function Methods:SetReverse(v) self.reverse = v end
function Methods:SetCooldown(start, duration) self.cooldown = { start, duration } self.shown = true end
function Methods:SetDrawBling(v) self.drawBling = v end
function Methods:SetDrawSwipe(v) self.drawSwipe = v end

-- 1.3.3 an object the client has made forbidden: IsForbidden answers (the one method the game answers for it),
-- every other method errors as the live client did at 20:46:04 ("calling 'SetHeight' on bad self ...")
HK_FORBIDDEN_CALLS = {}
function Methods:IsForbidden() return false end
function HK_Forbid(obj)
	setmetatable(obj, { __index = function(_, k)
		if k == 'IsForbidden' then return function() return true end end
		local m = Methods[k]
		if type(m) == 'function' then
			return function()
				HK_FORBIDDEN_CALLS[#HK_FORBIDDEN_CALLS + 1] = k
				error("calling '" .. k .. "' on bad self (Attempt to access forbidden object from code tainted by an AddOn)", 2)
			end
		end
		return nil
	end })
	return obj
end
-- every frame / region below `root` (any depth)
function HK_Descendants(root)
	local list = {}
	for _, f in ipairs(allFrames) do
		local p = f.parent
		while p and p ~= root do p = p.parent end
		if p == root and f ~= root then list[#list + 1] = f end
	end
	return list
end
-- 1.3.4 the 12.x access questions (false for every mock object unless a test says otherwise) and effective visibility
function Methods:HasAnySecretAspect() return false end
function Methods:IsAnchoringSecret() return false end
function Methods:GetFrameStrata() return self.strata or 'MEDIUM' end
function Methods:IsVisible()
	local f = self
	while f do
		if not f.shown then return false end
		f = f.parent
	end
	return true
end
