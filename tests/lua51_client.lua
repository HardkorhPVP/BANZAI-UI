-- 1.5.0-dev1: the client adapter under a real Lua 5.1 (LuaJIT), as the game runs it. The suites in tests/run.js use
-- a Lua 5.3 VM, so this repeats the pure parts - shared/Flavor.lua and Transform's adapter - where a 5.3-only
-- habit would show. Run by tools/forevercheck.js:  luajit tests/lua51_client.lua <dist/BushidoPrivateRestore>
local dir = assert(arg[1], 'usage: luajit tests/lua51_client.lua <dist/BushidoPrivateRestore>')
assert(_VERSION == 'Lua 5.1', 'this check is for Lua 5.1, got ' .. tostring(_VERSION))

local ns = {}
for _, file in ipairs({ 'Flavor.lua', 'Transform.lua' }) do
	local chunk = assert(loadfile(dir .. '/' .. file))
	chunk('BushidoPrivateRestore', ns)
end
local T, Flavor = ns.Transform, ns.Flavor

local passed = 0
local function eq(got, want, what)
	if got ~= want then error(string.format('%s: expected [%s], got [%s]', what, tostring(want), tostring(got)), 2) end
	passed = passed + 1
end

-- the client: nothing of the game exists here, so it is Retail; then WoW Forever by each of the three signs
eq(Flavor.Id(), 'RETAIL', 'no client globals')
WOW_PROJECT_ID, WOW_PROJECT_CAMELOT = 18, 18
eq(Flavor.Id(), 'FOREVER', 'project constant')
WOW_PROJECT_ID = 1
eq(Flavor.Id(), 'RETAIL', 'mainline project')
function GetBuildInfo() return '1.60.1', '70862', 'Nov 3 2026', 16001 end
eq(Flavor.Id(), 'FOREVER', 'interface number')
eq(Flavor.ClientText(), 'WoW Forever 1.60.1 (build 70862, Interface 16001)', 'client text')
eq(Flavor.Has('conquest'), false, 'no conquest on Forever')
eq(Flavor.Has('honor'), true, 'honor exists')

-- talent trees through the trait API
local trees = { { groupID = 13, displayName = 'Restoration', icon = 3, orderIndex = 3, spent = 20 }, { groupID = 11, displayName = 'Balance', icon = 1, orderIndex = 1, spent = 0 }, { groupID = 12, displayName = 'Feral Combat', icon = 2, orderIndex = 2, spent = 31 } }
C_SpecializationInfo = { GetActiveSpecGroup = function() return 1 end, GetCombatConfigIDForSpecGroup = function() return 501 end }
C_Traits = {
	GetConfigInfo = function() return { treeIDs = { 77 } } end,
	ConfigHasStagedChanges = function() return false end,
	GetGroupDisplayInfoByTreeID = function() return trees end,
	GetGroupCurrencyInfo = function(_, ids)
		local out = {}
		for _, id in ipairs(ids) do for _, t in ipairs(trees) do if t.groupID == id then out[#out + 1] = { traitNodeGroupID = id, currencyInfos = { { spent = t.spent } } } end end end
		return out
	end,
}
local spec = Flavor.PlayerSpec()
eq(spec.name, 'Feral Combat', 'leading tree')
eq(spec.points, '0 / 31 / 20', 'points text (no ".0" under Lua 5.1 numbers)')
eq(spec.source, 'talents', 'source')
eq(spec.role, nil, 'no role')
trees[1].spent = 31
eq(Flavor.PlayerSpec(), nil, 'a tie names nothing')

-- macro conditions
eq(T.AdaptConditions('[petbattle]  hide; show\n', 'FOREVER'), 'show\n', 'bar 1 (the historical value)')
eq(T.AdaptConditions('[vehicleui] hide; [petbattle] hide; [overridebar] hide; show;', 'FOREVER'), '[vehicleui] hide; [overridebar] hide; show;', 'bars 3 / 5 / 6')
eq(T.AdaptConditions('[vehicleui][petbattle][overridebar] hide; show', 'FOREVER'), '[vehicleui][overridebar] hide; show', 'ElvUI default bars')
eq(T.AdaptConditions('[vehicleui][petbattle] hide; show', 'FOREVER'), '[vehicleui] hide; show', 'stance bar')
eq(T.AdaptConditions('[petbattle] hide; [novehicleui,pet,nooverridebar,nopossessbar] show; hide', 'FOREVER'), '[novehicleui,pet,nooverridebar,nopossessbar] show; hide', 'pet bar')
eq(T.AdaptConditions('[form:1, spec:3] 7;', 'FOREVER'), nil, 'spec paging is left out')
eq(T.AdaptConditions('[petbattle] hide; show', 'RETAIL'), '[petbattle] hide; show', 'Retail untouched')
eq(T.AdaptConditions('[@raid6,noexists][@raid21,exists] hide;show', 'FOREVER'), '[@raid6,noexists][@raid21,exists] hide;show', 'untouched')
eq(T.TagName('[ - >mMT-level]'), 'mMT-level', 'tag prefix')
eq(T.TagName('[perhp<%]'), 'perhp', 'tag suffix')
eq(T.TagName('[name:eltruism:gradientshortcaps{10}]'), 'name:eltruism:gradientshortcaps', 'tag arguments')

-- the profile adapter: deterministic, idempotent, Retail untouched
local function sample()
	return { actionbar = { bar1 = { visibility = '[petbattle]  hide; show', paging = { PRIEST = '[form:1, spec:3] 7;', DRUID = '[bonusbar:1] 7;' } }, bar3 = { visibility = '[vehicleui] hide; [petbattle] hide; [overridebar] hide; show;' } },
		datatexts = { panels = { Left = { 'mTeleports', 'Time' } } }, unitframe = { units = { player = { customTexts = { h = { text_format = '[mMT-health:current:short]' } } } } } }
end
local a, b = sample(), sample()
local ra, rb = T.AdaptProfile(a, 'FOREVER', { datatexts = { mTeleports = false }, tags = {} }), T.AdaptProfile(b, 'FOREVER', { datatexts = { mTeleports = false }, tags = {} })
eq(T.Serialize(a), T.Serialize(b), 'deterministic profile')
eq(T.Serialize(ra), T.Serialize(rb), 'deterministic report')
eq(#ra.changes, 3, 'three changes')
eq(ra.changes[1].path, 'actionbar.bar1.paging.PRIEST', 'sorted report')
eq(a.actionbar.bar1.visibility, 'show', 'bar 1 adapted')
eq(a.actionbar.bar1.paging.PRIEST, nil, 'spec paging left out')
eq(a.actionbar.bar1.paging.DRUID, '[bonusbar:1] 7;', 'other paging kept')
eq(#ra.notes, 1, 'one note')
eq(a.datatexts.panels.Left[1], 'mTeleports', 'a note rewrites nothing')
eq(#T.AdaptProfile(a, 'FOREVER').changes, 0, 'idempotent')
local r = sample()
local before = T.Serialize(r)
eq(#T.AdaptProfile(r, 'RETAIL').changes, 0, 'Retail: no changes')
eq(T.Serialize(r), before, 'Retail: untouched')

print(string.format('lua51_client: %d passed (%s)', passed, jit and jit.version or _VERSION))
