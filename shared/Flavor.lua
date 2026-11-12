--[[
	BANZAI - Flavor.lua  (shared)
	Part of BANZAI UI. One source file (shared/Flavor.lua): the build copies it
	unchanged into Banzai Art and Banzai, and each loads it first.

	1.5.0-dev1 (private Forever proof): the game client BANZAI runs in, and the
	few places where WoW Forever really differs from Retail. Everything else
	stays shared. Each difference below was read from the installed Forever
	client's addons (ElvUI 16.01, Jiberish Icons 1.7.0, Eltruism 5.1.8) and from
	Blizzard's own interface code for 1.60.1; nothing is assumed from Retail.

	  client      FOREVER when WOW_PROJECT_ID is WOW_PROJECT_CAMELOT (the test
	              ElvUI itself uses for E.Forever), else RETAIL. Retail's code
	              paths are the 1.4.0 ones, untouched.
	  spec        Forever has talent trees, not specializations. The deprecated
	              globals GetSpecialization / GetSpecializationInfo are not
	              loaded there (Blizzard_DeprecatedSpecialization: classic,
	              standard), and C_SpecializationInfo's selected specialization
	              is a starter ID, not the talent-tree result. So on Forever the
	              player's "spec" is the talent tree with the most committed
	              points, read through the documented trait API (C_Traits group
	              display + group currency): its name and icon are the game's
	              own. A tie or no points: no spec is shown (class only). No
	              role is derived from it and other players get no spec at all
	              in this proof - nothing is guessed.
	  absent      what the Forever game does not have (Flavor.ABSENT): the panel
	              entries and texts for it are left out instead of showing a
	              made-up zero.
]]
local _, ns = ...
ns = ns or {}

local Flavor = {}
ns.Flavor = Flavor

Flavor.RETAIL, Flavor.FOREVER = 'RETAIL', 'FOREVER'
Flavor.NAMES = { RETAIL = 'Retail', FOREVER = 'WoW Forever' }

-- what the Forever game has no data for (each one read from the installed client: docs/FOREVER-PROOF-1.md)
Flavor.ABSENT = {
	FOREVER = {
		specialization = true,        -- no chosen specialization: talent trees
		specRole = true,              -- so no role comes with it
		inspectSpecialization = true, -- another player's inspect "spec" is a starter ID
		lootSpecialization = true,
		conquest = true,              -- no arena / conquest currency
		mastery = true,               -- not a Forever stat
		versatility = true,           -- not a Forever stat
		pvpItemLevel = true,          -- this build has no verified distinct PvP item-level source
		petBattles = true,
	},
}

local function IsSecret(value)
	return issecretvalue and issecretvalue(value) or false
end

-- the first return of a call the game may refuse; nil when it fails or keeps the value secret
local function First(fn, ...)
	if type(fn) ~= 'function' then return nil end
	local ok, value = pcall(fn, ...)
	if not ok or IsSecret(value) then return nil end
	return value
end

local function Number(value) return (type(value) == 'number' and not IsSecret(value)) and value or nil end
local function Text(value) return (type(value) == 'string' and not IsSecret(value) and value ~= '') and value or nil end
local function Table(value) return (type(value) == 'table' and not IsSecret(value)) and value or nil end

-- The client, decided explicitly - never by what happens to be missing:
--   1. WOW_PROJECT_ID is WOW_PROJECT_CAMELOT (the test the installed ElvUI uses for E.Forever)
--   2. else ElvUI's own E.Forever (should Blizzard rename the project constant, ElvUI follows it first)
--   3. else the interface number the client reports is a Forever one, 160xx (16001 is what the live client
--      accepted for BanzaiSland)
-- Anything else is Retail, whose code paths are the 1.4.0 ones.
function Flavor.Id()
	local project, camelot = _G.WOW_PROJECT_ID, _G.WOW_PROJECT_CAMELOT
	if project ~= nil and camelot ~= nil and project == camelot then return Flavor.FOREVER end
	local engine = _G.ElvUI
	local E = type(engine) == 'table' and engine[1]
	if type(E) == 'table' and E.Forever == true then return Flavor.FOREVER end
	if type(_G.GetBuildInfo) == 'function' then
		local ok, _, _, _, interface = pcall(_G.GetBuildInfo)
		interface = ok and Number(interface) or nil
		if interface and interface >= 16000 and interface < 17000 then return Flavor.FOREVER end
	end
	return Flavor.RETAIL
end

function Flavor.IsForever() return Flavor.Id() == Flavor.FOREVER end
function Flavor.IsRetail() return Flavor.Id() == Flavor.RETAIL end

-- false when this client's game has nothing behind `feature`
function Flavor.Has(feature)
	local absent = Flavor.ABSENT[Flavor.Id()]
	return not (absent and absent[feature])
end

-- the running client: { flavor, version, build, interface }
function Flavor.Client()
	local out = { flavor = Flavor.Id() }
	if type(_G.GetBuildInfo) == 'function' then
		local ok, version, build, _, interface = pcall(_G.GetBuildInfo)
		if ok then out.version, out.build, out.interface = Text(version), Text(build), Number(interface) end
	end
	return out
end

-- 'WoW Forever 1.60.1 (build 70862, Interface 16001)'
function Flavor.ClientText()
	local c = Flavor.Client()
	local text = Flavor.NAMES[c.flavor] or tostring(c.flavor)
	if c.version then text = text .. ' ' .. c.version end
	local detail = {}
	if c.build then detail[#detail + 1] = 'build ' .. c.build end
	if c.interface then detail[#detail + 1] = 'Interface ' .. c.interface end
	if #detail > 0 then text = text .. ' (' .. table.concat(detail, ', ') .. ')' end
	return text
end

---------------------------------------------------------------------------
-- Forever: the player's talent trees
---------------------------------------------------------------------------
-- the trait configuration the player fights with (nil when the game does not say)
local function ActiveConfig()
	local spec = Table(_G.C_SpecializationInfo)
	if spec and spec.GetActiveSpecGroup and spec.GetCombatConfigIDForSpecGroup then
		local group = Number(First(spec.GetActiveSpecGroup))
		local id = group and group > 0 and Number(First(spec.GetCombatConfigIDForSpecGroup, group))
		if id and id > 0 then return id end
	end
	local talents = Table(_G.C_ClassTalents)
	local id = talents and Number(First(talents.GetActiveConfigID))
	return (id and id > 0) and id or nil
end

-- The player's talent trees in the game's own order: { { index, name, icon, points }, ... } with the
-- committed points in each. nil when the game does not answer plainly (the trait API is missing, a value
-- is secret or malformed, a tree is answered twice). While talents are being edited the last committed
-- answer for that same configuration stands. A tree the game returns no points row for has none spent -
-- the reading the installed Jiberish Icons uses on this client (docs/FOREVER-PROOF-1.md, live test).
function Flavor.TalentTrees()
	local traits = Table(_G.C_Traits)
	if not (traits and traits.GetConfigInfo and traits.GetGroupDisplayInfoByTreeID and traits.GetGroupCurrencyInfo) then return nil end
	local configID = ActiveConfig()
	if not configID then return nil end
	if traits.ConfigHasStagedChanges and First(traits.ConfigHasStagedChanges, configID) ~= false then
		local kept = Flavor.committed -- uncommitted points would be counted: keep what was last confirmed, for this configuration only
		return kept and kept.configID == configID and kept.trees or nil
	end
	local config = Table(First(traits.GetConfigInfo, configID))
	local treeID = config and Table(config.treeIDs) and Number(config.treeIDs[1])
	if not (treeID and treeID > 0) then return nil end
	local displays = Table(First(traits.GetGroupDisplayInfoByTreeID, treeID))
	if not displays or #displays == 0 then return nil end
	local trees, byGroup, groupIDs = {}, {}, {}
	for position, display in ipairs(displays) do
		local d = Table(display)
		local groupID, name = d and Number(d.groupID), d and Text(d.displayName)
		if not (groupID and name) or byGroup[groupID] then return nil end
		local tree = { groupID = groupID, name = name, icon = Number(d.icon), order = Number(d.orderIndex) or position, position = position, points = 0 }
		trees[#trees + 1], byGroup[groupID], groupIDs[#groupIDs + 1] = tree, tree, groupID
	end
	table.sort(trees, function(a, b)
		if a.order ~= b.order then return a.order < b.order end
		return a.position < b.position
	end)
	local groups = Table(First(traits.GetGroupCurrencyInfo, configID, groupIDs))
	if not groups then return nil end
	local answered = {}
	for _, group in ipairs(groups) do
		local g = Table(group)
		local tree = g and byGroup[Number(g.traitNodeGroupID) or false]
		local currency = tree and Table(g.currencyInfos) and Table(g.currencyInfos[1])
		local spent = currency and Number(currency.spent)
		if not (spent and spent >= 0) or answered[tree] then return nil end
		tree.points, answered[tree] = spent, true
	end
	for index, tree in ipairs(trees) do tree.index, tree.order, tree.position = index, nil, nil end
	Flavor.committed = { configID = configID, trees = trees }
	return trees
end

-- the tree with the most points (nil on a tie or with no points spent), and all of them
function Flavor.TalentTree()
	local trees = Flavor.TalentTrees()
	if not trees then return nil, nil end
	local best, tied
	for _, tree in ipairs(trees) do
		if not best or tree.points > best.points then
			best, tied = tree, false
		elseif tree.points == best.points then
			tied = true
		end
	end
	if not best or tied or best.points <= 0 then return nil, trees end
	return best, trees
end

-- '0 / 31 / 20'
function Flavor.PointsText(trees)
	if type(trees) ~= 'table' then return nil end
	local parts = {}
	for _, tree in ipairs(trees) do parts[#parts + 1] = tostring(tree.points) end
	return #parts > 0 and table.concat(parts, ' / ') or nil
end

---------------------------------------------------------------------------
-- The player's specialization, whatever the client calls it
---------------------------------------------------------------------------
-- { name, icon, id, role, index, source } or nil when the game knows none.
--   RETAIL   the chosen specialization (GetSpecialization / GetSpecializationInfo, as BANZAI 1.4.0 reads it)
--   FOREVER  the leading talent tree: name and icon only (no id, no role), source 'talents', with the points
function Flavor.PlayerSpec()
	if Flavor.IsForever() then
		local tree, trees = Flavor.TalentTree()
		if not tree then return nil end
		return { name = tree.name, icon = tree.icon, index = tree.index, source = 'talents', points = Flavor.PointsText(trees) }
	end
	local index = Number(First(_G.GetSpecialization))
	if not index or index < 1 or type(_G.GetSpecializationInfo) ~= 'function' then return nil end
	local ok, id, name, _, icon, role = pcall(_G.GetSpecializationInfo, index)
	if not ok or not Text(name) then return nil end
	return { name = name, icon = Number(icon) or Text(icon), id = Number(id), role = Text(role), index = index, source = 'specialization' }
end

return Flavor
