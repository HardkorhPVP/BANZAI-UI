#!/usr/bin/env node
// BANZAI UI private Forever proof: build / package validation and offline configuration evidence.
//   node tools/forevercheck.js      (after node tools/build.js)
// 1. BUILD     the two BANZAI addons as built in dist/: one version everywhere, both clients in the TOCs, every
//              listed file present, the shared client adapter identical in both, Lua syntax, the font set.
// 2. CONFIG    APPLY BANZAI run offline (the test stand-ins) for Retail and for WoW Forever, BANZAI CLASSIC and
//              BANZAI SPLIT: what is written, per surface, and exactly what differs between the two clients.
// 3. INSTALLED the WoW Forever client's own addons, READ ONLY (nothing is ever written there): the versions,
//              ElvUI's default profile under both clients (so the adapter is checked against the installed
//              ElvUI itself), and every ElvUI / Details / Jiberish Icons member, tag, datatext and media name
//              BANZAI uses. Skipped, and said so, when the client is not installed on this machine.
// The report goes to build/forever-proof/ (never committed). Exit 1 when a check fails.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { spawnSync } = require('child_process');
const luaparse = require('luaparse');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
const fonts = require('./lib/fonts');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');
const OUT = path.join(ROOT, 'build', 'forever-proof');
const FOREVER = path.join(require('./lib/local').WOW, '_forever_');
const FOREVER_ADDONS = path.join(FOREVER, 'Interface', 'AddOns');
const ADDONS = ['BushidoPrivateCompat', 'BushidoPrivateRestore']; // what a Forever proof deploys - and nothing else
const PROFILE = 'JiberishUI - Bushido Private';

let failures = 0;
const log = [];
function check(name, ok, detail) {
  if (!ok) failures++;
  const line = `${ok ? 'ok  ' : 'FAIL'} ${name}${detail ? '  [' + detail + ']' : ''}`;
  log.push(line);
  console.log(line);
  return ok;
}
function note(text) { log.push('     ' + text); console.log('     ' + text); }

const read = (file) => fs.readFileSync(file, 'utf8');
const sha256 = (file) => crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
// 1.5.0-dev3: Lua source without its comments (a static check reads the code, not what a comment says about it)
const code = (text) => text.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, '').replace(/--[^\n]*/g, '');
function walk(dir, out = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, e.name);
    if (e.isDirectory()) walk(full, out); else out.push(full);
  }
  return out;
}
function toc(addon, root = DIST) {
  const fields = {}; const files = [];
  for (const raw of read(path.join(root, addon, addon + '.toc')).split(/\r?\n/)) {
    const line = raw.trim();
    const m = line.match(/^##\s*([^:]+):\s*(.*)$/);
    if (m) fields[m[1].trim()] = m[2].trim(); else if (line && !line.startsWith('#')) files.push(line);
  }
  return { fields, files };
}

// --------------------------------------------------------------------------- Lua VM (the offline stand-ins)
function runLua(source) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  if (lauxlib.luaL_loadstring(L, to_luastring(source)) !== lua.LUA_OK) throw new Error('load: ' + to_jsstring(lua.lua_tostring(L, -1)));
  if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) throw new Error('run: ' + to_jsstring(lua.lua_tostring(L, -1)));
  return to_jsstring(lua.lua_tostring(L, -1)) || '';
}
const q = (s) => JSON.stringify(s.replace(/\\/g, '/'));
const LEAVES = `
  local function leaves(t, prefix, out)
    for k, v in pairs(t) do
      local p = prefix .. tostring(k)
      if type(v) == 'table' then leaves(v, p .. '.', out) else out[#out + 1] = p .. '\\t' .. type(v) .. ':' .. tostring(v):gsub('\\n', '\\\\n') end
    end
    return out
  end`;

// APPLY BANZAI offline for a client and a frame style; returns the leaves of what was written and the adapter's report
function applied(flavor, style) {
  const files = toc('BushidoPrivateRestore').files.map((f) => path.join(DIST, 'BushidoPrivateRestore', f));
  const out = runLua([
    `HK_FLAVOR = ${JSON.stringify(flavor)}`, 'HK_TEXTURES = {}', `HK_FILES = { ${files.map(q).join(', ')} }`, `HK_DIST = ${q(DIST)}`,
    `dofile(${q(path.join(ROOT, 'tests', 'mocks.lua'))})`, LEAVES, `
    local ns = HK_NS
    HK_LOADED.BushidoPrivateCompat, HK_LOADED.ElvUI_Libraries = true, true
    HK_INSTALLED.ElvUI_Options = 'DEMAND_LOADED'
    KalielsTrackerDB, MinimapButtonButtonOptions = nil, nil
    local settings = { tracker = true, frameStyle = ${JSON.stringify(style)} }
    BanzaiCompat = { Get = function(_, k) return settings[k] end, Set = function(_, k, v) settings[k] = v return true end, GetTheme = function() return 'VIBRANT' end,
      Export = function() return { frameStyle = settings.frameStyle } end, Import = function() return true end, Roles = function() return {} end,
      RoleState = function() return {} end, PanelStyle = function() return 'BANZAI', 'GLASS', 1 end }
    for key in pairs(ns.Payloads.detailsProfile) do Details.default_profile[key] = true end
    assert(ns.Restore:ApplyHere('evidence') == true, 'APPLY BANZAI failed: ' .. table.concat(HK_PRINTS, ' | '))
    HK_RunTimers()
    local out = leaves(ElvDB.profiles[${JSON.stringify(PROFILE)}], 'profile.', {})
    leaves(ElvPrivateDB.profiles[${JSON.stringify(PROFILE)}], 'private.', out)
    leaves(ElvDB.global, 'global.', out)
    leaves(Details.profiles[${JSON.stringify(PROFILE)}] or {}, 'details.', out)
    local report = BushidoPrivateRestoreDB.client and BushidoPrivateRestoreDB.client.report
    for i, c in ipairs(report and report.changes or {}) do out[#out + 1] = 'ADAPTER.' .. i .. '\\tstring:' .. c.path .. ' :: ' .. tostring(c.reason) end
    out[#out + 1] = 'STATE.elvProfile\\tstring:' .. tostring(ElvUI[1].data:GetCurrentProfile())
    out[#out + 1] = 'STATE.client\\tstring:' .. ns.Flavor.ClientText()
    out[#out + 1] = 'STATE.version\\tstring:' .. tostring(ns.VERSION) .. ' ' .. tostring(ns.CHANNEL)
    local spec = ns.Flavor.PlayerSpec()
    out[#out + 1] = 'STATE.spec\\tstring:' .. tostring(spec and spec.name) .. ' (' .. tostring(spec and spec.source) .. ')'
    -- RESTORE PRE-BANZAI brings the pre-Banzai state back
    assert(ns.Restore:Revert() == true, 'RESTORE PRE-BANZAI failed')
    out[#out + 1] = 'STATE.restored\\tstring:' .. tostring(ElvUI[1].data:GetCurrentProfile()) .. ' / ' .. tostring(ElvPrivateDB.profileKeys[ElvUI[1].mynameRealm]) .. ' / ' .. tostring(Details.current) .. ' / UIScale ' .. tostring(ElvDB.global.general.UIScale)
    table.sort(out)
    return table.concat(out, '\\n')`,
  ].join('\n'));
  return new Map(out.split('\n').filter(Boolean).map((l) => { const i = l.indexOf('\t'); return [l.slice(0, i), l.slice(i + 1)]; }));
}

// the adapter's own function, from the built Transform.lua
function adaptConditions(text) {
  const files = ['Flavor.lua', 'Transform.lua'].map((f) => path.join(DIST, 'BushidoPrivateRestore', f));
  return runLua(`
    local ns = {}
    for _, file in ipairs({ ${files.map(q).join(', ')} }) do assert(loadfile(file))('BANZAI', ns) end
    local adapted = ns.Transform.AdaptConditions(${JSON.stringify(text)}, 'FOREVER')
    return adapted == nil and '<left out>' or adapted`);
}

// --------------------------------------------------------------------------- 1. BUILD
function build() {
  console.log('\n1. BUILD');
  const tocs = Object.fromEntries(ADDONS.map((a) => [a, toc(a)]));
  const theme = (read(path.join(DIST, 'BushidoPrivateCompat', 'Theme.lua')).match(/Theme\.VERSION = '([^']+)'/) || [])[1];
  const restore = (read(path.join(DIST, 'BushidoPrivateRestore', 'Restore.lua')).match(/local VERSION = '([^']+)'/) || [])[1];
  const versions = [tocs.BushidoPrivateCompat.fields.Version, tocs.BushidoPrivateRestore.fields.Version, theme, restore];
  check('one whole-product version in both TOCs, Banzai Art and Banzai', new Set(versions).size === 1, versions.join(' / '));
  check('the version is a release label (x.y.z) or a private proof label (x.y.z-devN)', /^\d+\.\d+\.\d+(-dev\d+)?$/.test(restore || ''), restore);
  for (const addon of ADDONS) {
    const t = tocs[addon];
    const interfaces = (t.fields.Interface || '').split(',').map((s) => Number(s.trim())).sort((a, b) => a - b);
    check(`${addon}.toc declares Retail 120105 and WoW Forever 16001`, JSON.stringify(interfaces) === '[16001,120105]', t.fields.Interface);
    check(`${addon}.toc loads the shared client adapter first`, t.files[0] === 'Flavor.lua', t.files[0]);
    const missing = t.files.filter((f) => !fs.existsSync(path.join(DIST, addon, f)));
    check(`${addon}: every file its TOC lists is built`, missing.length === 0, missing.join(', ') || `${t.files.length} files`);
    check(`${addon}: Flavor.lua is the shared source, unchanged`, sha256(path.join(DIST, addon, 'Flavor.lua')) === sha256(path.join(ROOT, 'shared', 'Flavor.lua')));
    check(`${addon}.toc has no game-type restriction (one folder for both clients)`, !/AllowLoadGameType|ExcludeLoadGameType/.test(read(path.join(DIST, addon, addon + '.toc'))));
    let bad = [];
    for (const file of walk(path.join(DIST, addon)).filter((f) => f.endsWith('.lua'))) {
      try { luaparse.parse(read(file), { luaVersion: '5.1' }); } catch (e) { bad.push(path.basename(file) + ': ' + e.message); }
    }
    check(`${addon}: every Lua file parses as Lua 5.1 (the game's)`, bad.length === 0, bad.join('; ') || `${walk(path.join(DIST, addon)).filter((f) => f.endsWith('.lua')).length} files`);
  }
  // the suites run on a Lua 5.3 VM; the game is Lua 5.1 - so the pure adapter runs once more where it would show
  const jit = spawnSync('luajit', [path.join(ROOT, 'tests', 'lua51_client.lua'), path.join(DIST, 'BushidoPrivateRestore')], { encoding: 'utf8' });
  if (jit.error) note('SKIPPED: no luajit on PATH - the client adapter was not run under a real Lua 5.1');
  else check('the client adapter behaves the same under a real Lua 5.1 (LuaJIT)', jit.status === 0, (jit.status === 0 ? jit.stdout : jit.stderr || jit.stdout).trim().split(/\r?\n/).pop());
  const requires = tocs.BushidoPrivateCompat.fields.Dependencies + ' | ' + tocs.BushidoPrivateRestore.fields.Dependencies;
  check('required addons are unchanged from 1.4.0 (ElvUI, JiberishMedia / ElvUI)', requires === 'ElvUI, JiberishMedia | ElvUI', requires);
  const fontDir = path.join(DIST, 'BushidoPrivateCompat', 'media', 'fonts');
  const faces = fs.readdirSync(fontDir).filter((f) => /\.(ttf|otf)$/i.test(f)).sort();
  check('the seven approved display faces, each at its recorded SHA-256', JSON.stringify(faces) === JSON.stringify(fonts.FONTS.map((f) => f.file).sort())
    && fonts.FONTS.every((f) => sha256(path.join(fontDir, f.file)) === f.sha256), faces.join(', '));
  check('every font notice rides along', fonts.NOTICES.every((n) => fs.existsSync(path.join(fontDir, n))));
  const all = ADDONS.flatMap((a) => walk(path.join(DIST, a)).map((f) => path.relative(DIST, f)));
  const retired = all.filter((f) => fonts.RETIRED_FILES.some((r) => f.toLowerCase().includes(r.toLowerCase())) || /WantBanzai|WantCoffee|Changchang|RootsOfChina|Odishi/i.test(f));
  check('no retired font file in the proof', retired.length === 0, retired.join(', '));
  const bakeoff = read(path.join(DIST, 'BushidoPrivateCompat', 'FontBakeoff.lua'));
  check('BANZAI Default is Shojumaru at 105%', /local DEFAULT_KEY = "SHOJUMARU"/.test(bakeoff) && /local DEFAULT_SCALE = 1\.05/.test(bakeoff));
  // 1.5.0-dev3: the Forever chat adapter and the window skins, as built
  const compatToc = tocs.BushidoPrivateCompat.files;
  check('Banzai Art loads the chat adapter, the window-skin framework and its adapters (in that order, after the HUD)',
    compatToc.indexOf('ChatLayout.lua') > compatToc.indexOf('Compat.lua') && compatToc.indexOf('Skins.lua') > compatToc.indexOf('ChatLayout.lua')
    && compatToc.indexOf('SkinAdapters.lua') === compatToc.indexOf('Skins.lua') + 1, compatToc.slice(compatToc.indexOf('ChatLayout.lua'), compatToc.indexOf('ChatLayout.lua') + 3).join(' > '));
  const dev3 = ['ChatLayout.lua', 'Skins.lua', 'SkinAdapters.lua'].map((f) => [f, code(read(path.join(DIST, 'BushidoPrivateCompat', f)))]);
  const FORBIDDEN = [
    [/OnUpdate/, 'an OnUpdate script'], [/NewTicker/, 'a ticker'], [/StripTextures|:Kill\(/, 'texture removal'], [/:SetBackdrop\(/, 'a backdrop definition'],
    [/:SetParent\(/, 're-parenting'], [/:SetScript\((?!'OnEvent')/, 'a replaced script'], [/SetAttribute|RegisterStateDriver|SecureHandler/, 'a secure-frame write'],
    [/\bloadstring\b|\bRunScript\b/, 'run-time code'],
  ];
  const found = [];
  for (const [file, text] of dev3) for (const [re, what] of FORBIDDEN) if (re.test(text)) found.push(`${file}: ${what}`);
  check('the chat adapter and the window skins use no OnUpdate, ticker, texture removal, backdrop definition, re-parenting, replaced script or secure-frame write', found.length === 0, found.join('; ') || 'none in 3 files');
  const skinsCode = dev3[1][1] + dev3[2][1];
  const hooks = (skinsCode.match(/hooksecurefunc\(/g) || []).length;
  check('the window skins make one kind of secure post-hook only: Zygor\'s own skin pass on its viewer frame', hooks === 1 && /hooksecurefunc\(viewer, method, Zygor\.AfterSkin\)/.test(skinsCode), `${hooks} call site`);
  check('the chat adapter makes no hook at all', !/hooksecurefunc|HookScript/.test(dev3[0][1]));
  const alpha = skinsCode.match(/[\w.]+:SetAlpha\(/g) || [];
  check('no frame\'s alpha is ever set by the window skins (the one alpha they change is an ElvUI panel\'s backdrop-colour alpha, given back with the skin)',
    alpha.length === 0 && skinsCode.includes('base:SetBackdropColor(r, g, b, 0)') && skinsCode.includes('base:SetBackdropColor(r, g, b, alpha)'), alpha.join(', ') || 'no SetAlpha call');
  const foreign = all.filter((f) => /SavedVariables|\.bak$|\.zip$|WTF[\\/]/i.test(f));
  check('nothing but the two BANZAI addons is in the proof (no saved variables, archives or backups)', foreign.length === 0, `${all.length} files`);
  return { version: restore, files: all.length, bytes: all.reduce((n, f) => n + fs.statSync(path.join(DIST, f)).size, 0) };
}

// --------------------------------------------------------------------------- 2. CONFIG
const SURFACES = [
  ['Player', [/^profile\.unitframe\.units\.player\.(width|height|orientation)$/, /^profile\.unitframe\.units\.player\.(health|power)\.(height|text_format|enable|width)$/, /^profile\.unitframe\.units\.player\.customTexts\.(m-Name|m-Health|b-HealthPct|b-Spec)\.(text_format|font|size|enable)$/, /^profile\.movers\.ElvUF_PlayerMover$/]],
  ['Target', [/^profile\.unitframe\.units\.target\.(width|height|orientation)$/, /^profile\.unitframe\.units\.target\.(health|power)\.(height|text_format|enable|width)$/, /^profile\.unitframe\.units\.target\.customTexts\.(m-Name|m-Health|b-HealthPct|b-Spec)\.(text_format|font|size|enable)$/, /^profile\.movers\.ElvUF_TargetMover$/]],
  ['Cast bar', [/^profile\.unitframe\.units\.(player|target)\.castbar\.(enable|width|height|icon|iconSize|format|textColor\.\w|overlayOnFrame|hidetext|spark|timeToHold)$/, /^profile\.movers\.ElvUF_(Player|Target)CastbarMover$/]],
  ['Chat', [/^profile\.chat\.(font|fontSize|fontOutline|panelBackdrop|panelWidth|panelHeight|hideChatToggles|tabFont|tabFontSize|fadeTabsNoBackdrop|panelColor\.\w)$/, /^profile\.movers\.LeftChatMover$/, /^private\.chat\.enable$/]],
  ['Details', [/^details\.instances\.[12]\.(row_info\.(height|font_size|font_face|texture)|attribute_text\.(text_size|text_face|enabled)|bg_alpha|show_statusbar|menu_icons\.1)$/, /^STATE\.restored$/]],
  ['BUFFS', [/^profile\.auras\.(buffs|debuffs)\.(size|height|horizontalSpacing|verticalSpacing|wrapAfter|maxWraps|growthDirection|countFont|timeFont|barTexture)$/, /^profile\.movers\.(Buffs|Debuffs)Mover$/]],
  ['Minimap', [/^profile\.general\.minimap\.(size|locationText|locationFont|locationFontSize|circle|clusterDisable|icons\.(mail|difficulty|classHall)\.(position|scale|xOffset|yOffset))$/, /^profile\.movers\.(MinimapMover|QueueStatusMover|DurabilityFrameMover)$/]],
  ['Objectives', [/^profile\.general\.(objectiveFrameHeight|objectiveFrameAutoHide|bonusObjectivePosition)$/, /^profile\.movers\.ObjectiveFrameMover$/]],
  ['Action bars', [/^profile\.actionbar\.bar[1-6]\.(enabled|buttons|buttonsPerRow|buttonSize|buttonSpacing|visibility|backdrop)$/, /^profile\.actionbar\.(font|fontSize|fontOutline)$/, /^profile\.movers\.ElvAB_[1-6]$/]],
  ['Fonts / materials', [/^profile\.general\.(font|fontSize|fontStyle|backdropcolor\.\w|backdropfadecolor\.\w|bordercolor\.\w)$/, /^profile\.unitframe\.(font|fontSize|fontOutline|statusbar)$/, /^private\.general\.(normTex|glossTex|namefont|dmgfont|chatBubbleFont)$/, /^private\.theme$/]],
];

function config() {
  console.log('\n2. CONFIG (APPLY BANZAI offline, then RESTORE PRE-BANZAI)');
  const runs = {};
  for (const flavor of ['retail', 'forever']) for (const style of ['CLASSIC', 'SPLIT']) runs[flavor + ':' + style] = applied(flavor, style);
  const evidence = { differences: {}, surfaces: {}, state: {} };
  for (const style of ['CLASSIC', 'SPLIT']) {
    const retail = runs['retail:' + style]; const forever = runs['forever:' + style];
    const settings = (m) => [...m.keys()].filter((k) => !/^(ADAPTER|STATE)\./.test(k));
    const onlyRetail = settings(retail).filter((k) => !forever.has(k));
    const onlyForever = settings(forever).filter((k) => !retail.has(k));
    const differ = settings(retail).filter((k) => forever.has(k) && forever.get(k) !== retail.get(k));
    evidence.differences[style] = differ.map((k) => ({ path: k, retail: retail.get(k), forever: forever.get(k) }));
    check(`BANZAI ${style}: WoW Forever gets every setting Retail gets (none dropped, none added)`, onlyRetail.length === 0 && onlyForever.length === 0, `${settings(forever).length} settings`);
    check(`BANZAI ${style}: exactly the four bar visibilities differ between the clients (the pet battle condition)`, JSON.stringify(differ.sort()) === JSON.stringify(['profile.actionbar.bar1.visibility', 'profile.actionbar.bar3.visibility', 'profile.actionbar.bar5.visibility', 'profile.actionbar.bar6.visibility']), differ.join(', '));
    check(`BANZAI ${style}: no pet battle or spec condition is left in the Forever profile`, ![...forever.entries()].some(([k, v]) => /^profile\./.test(k) && /petbattle|\bspec:/i.test(v)));
    check(`BANZAI ${style}: Retail's profile is not adapted at all (no adapter record)`, ![...retail.keys()].some((k) => k.startsWith('ADAPTER.')) && [...forever.keys()].filter((k) => k.startsWith('ADAPTER.')).length === 4);
    check(`BANZAI ${style}: RESTORE PRE-BANZAI returns the pre-Banzai ElvUI, private and Details profiles and the UI scale`, forever.get('STATE.restored') === 'string:HARDKORHUI / breezy / DarrenUI / UIScale 0.53333333333333', forever.get('STATE.restored'));
    evidence.state[style] = Object.fromEntries([...forever.entries()].filter(([k]) => k.startsWith('STATE.') || k.startsWith('ADAPTER.')));
    evidence.surfaces[style] = {};
    for (const [name, patterns] of SURFACES) {
      const rows = settings(forever).filter((k) => patterns.some((p) => p.test(k))).map((k) => ({ path: k, forever: forever.get(k), retail: retail.get(k) }));
      evidence.surfaces[style][name] = rows;
    }
  }
  const classic = runs['forever:CLASSIC']; const split = runs['forever:SPLIT'];
  const styleDiff = [...classic.keys()].filter((k) => /^profile\./.test(k) && split.get(k) !== classic.get(k)).length + [...split.keys()].filter((k) => /^profile\./.test(k) && !classic.has(k)).length;
  check('BANZAI SPLIT writes its own layer over BANZAI CLASSIC on WoW Forever (the two styles really differ)', styleDiff > 20, `${styleDiff} settings differ`);
  evidence.splitDifferences = styleDiff;
  check('the client shown offline is WoW Forever, and the spec is the leading talent tree', classic.get('STATE.client') === 'string:WoW Forever 1.60.1 (build 70862, Interface 16001)' && classic.get('STATE.spec') === 'string:Feral Combat (talents)', classic.get('STATE.spec'));
  return evidence;
}

// --------------------------------------------------------------------------- 3. INSTALLED (read only)
function installedDefaults(flavor) {
  const file = path.join(FOREVER_ADDONS, 'ElvUI', 'Game', 'Shared', 'Defaults', 'Profile.lua');
  const out = runLua(`
    unpack = table.unpack
    local flavor = ${JSON.stringify(flavor)}
    local E = { Retail = flavor == 'retail', Forever = flavor == 'forever', filterMax = 8 }
    E.Modern = E.Retail or E.Forever
    function E:CopyTable(a, b) if type(a) ~= 'table' then a = {} end for k, v in pairs(b) do if type(v) == 'table' then a[k] = E:CopyTable(a[k], v) else a[k] = v end end return a end
    local P = {}
    ElvUI = { E, setmetatable({}, { __index = function(_, k) return k end }), {}, P, {} }
    DEFAULT_CHAT_FRAME = { GetName = function() return 'ChatFrame1' end }
    setmetatable(_G, { __index = function(_, k) if type(k) == 'string' and k:match('^[A-Z_0-9]+$') then return k end end })
    assert(loadfile(${q(file)}))('ElvUI', {})
    ${LEAVES}
    local out = leaves(P, '', {})
    table.sort(out)
    return table.concat(out, '\\n')`);
  return new Map(out.split('\n').filter(Boolean).map((l) => { const i = l.indexOf('\t'); return [l.slice(0, i), l.slice(i + 1)]; }));
}

function installed(evidence) {
  console.log('\n3. INSTALLED WoW Forever addons (read only)');
  if (!fs.existsSync(path.join(FOREVER_ADDONS, 'ElvUI', 'ElvUI.toc'))) {
    note(`skipped: no WoW Forever client with ElvUI at ${FOREVER_ADDONS}`);
    return { skipped: true };
  }
  const out = { prerequisites: [], api: [] };
  const sources = {};
  const luaOf = (addon) => {
    if (!sources[addon]) sources[addon] = fs.existsSync(path.join(FOREVER_ADDONS, addon)) ? walk(path.join(FOREVER_ADDONS, addon)).filter((f) => /\.lua$/i.test(f)).map((f) => read(f)).join('\n') : '';
    return sources[addon];
  };
  // versions and the Forever interface
  for (const [addon, tocName] of [['ElvUI', 'ElvUI.toc'], ['ElvUI_Libraries', 'ElvUI_Libraries.toc'], ['ElvUI_Options', 'ElvUI_Options.toc'], ['JiberishMedia', 'JiberishMedia.toc'], ['JiberishIcons', 'JiberishIcons.toc'],
    ['ElvUI_mMediaTag', 'ElvUI_mMediaTag.toc'], ['ElvUI_EltreumUI', 'ElvUI_EltreumUI.toc'], ['Details', 'Details_Camelot.toc'], ['!mMT_MediaPack', '!mMT_MediaPack_Camelot.toc']]) {
    const file = path.join(FOREVER_ADDONS, addon, tocName);
    const text = fs.existsSync(file) ? read(file) : null;
    const version = text && ((text.match(/^## Version:\s*(.+)$/m) || [])[1] || '').trim();
    const forever = text && /^## Interface:.*\b16001\b/m.test(text);
    out.prerequisites.push({ addon, version: version || null, installed: Boolean(text), interface16001: Boolean(forever) });
    check(`${addon} is installed and declares Interface 16001`, Boolean(text) && forever, version || 'not installed');
  }
  // ElvUI's default profile under both clients: the adapter is checked against the installed ElvUI itself
  const retail = installedDefaults('retail'); const forever = installedDefaults('forever');
  const onlyRetail = [...retail.keys()].filter((k) => !forever.has(k));
  const differ = [...retail.keys()].filter((k) => forever.has(k) && forever.get(k) !== retail.get(k));
  out.elvuiDefaults = { leaves: forever.size, onlyRetail, onlyForever: [...forever.keys()].filter((k) => !retail.has(k)), differ: differ.map((k) => ({ path: k, retail: retail.get(k), forever: forever.get(k) })) };
  check('installed ElvUI: no profile setting exists on Retail only (the Banzai profile has the same shape on WoW Forever)', onlyRetail.length === 0, `${forever.size} default leaves, ${differ.length} values differ`);
  const conditions = differ.filter((k) => /\[/.test(retail.get(k)));
  const wrong = [];
  for (const k of conditions) {
    const adapted = adaptConditions(retail.get(k).replace(/^string:/, ''));
    const want = forever.get(k).replace(/^string:/, '');
    // a numbered-spec condition is left out by the adapter: ElvUI's own Forever default then stands, which is `want`
    if (adapted !== want && adapted !== '<left out>') wrong.push(`${k}: ${adapted} (ElvUI: ${want})`);
  }
  check('installed ElvUI: every macro condition its Retail default has and its Forever default lacks is adapted to exactly the Forever default', wrong.length === 0, wrong.join('; ') || `${conditions.length} settings`);
  const other = differ.filter((k) => !/\[/.test(retail.get(k)));
  note(`other default differences (not conditions; the Banzai profile does not write a Retail-only value there): ${other.map((k) => k + ' ' + retail.get(k) + ' -> ' + forever.get(k)).join('; ')}`);
  const written = evidence && evidence.written;
  if (written) {
    const stale = other.filter((k) => written.has('profile.' + k) && written.get('profile.' + k) === retail.get(k));
    check('the Banzai profile writes none of ElvUI\'s other Retail-only default values', stale.length === 0, stale.join(', '));
  }
  // every member of other addons BANZAI calls (the calls are in addons/: Engine(), E:GetModule, Details, Jiberish Icons)
  const elv = luaOf('ElvUI') + luaOf('ElvUI_Libraries');
  const member = (name, re, text) => { const ok = re.test(text); out.api.push({ name, state: ok ? 'SAME' : 'MISSING' }); return ok; };
  const E_MEMBERS = ['AddTag', 'AddTagInfo', 'ForceBorderColor', 'SetMoverPoints', 'SetMoversPositions', 'ToggleOptions'];
  const missing = [];
  for (const m of E_MEMBERS) if (!member('E:' + m, new RegExp('function E:' + m + '\\b'), elv)) missing.push('E:' + m);
  for (const m of ['data', 'db', 'Libs', 'media', 'mult', 'mynameRealm', 'Options', 'oUF', 'Initialized']) if (!member('E.' + m, new RegExp('\\bE\\.' + m + '\\s*[=,]'), elv)) missing.push('E.' + m);
  for (const m of ['UnitFrames', 'Auras', 'AFK', 'Tooltip', 'DataTexts']) if (!member(`E:GetModule('${m}')`, new RegExp("NewModule\\('" + m + "'"), elv)) missing.push('module ' + m);
  for (const m of ['GetCurrentProfile', 'SetProfile', 'RegisterCallback']) if (!member('E.data:' + m + ' (AceDB-3.0)', new RegExp(m), elv)) missing.push('AceDB ' + m);
  member('E.Forever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT (the client test BANZAI uses)', /E\.Forever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT/, elv) || missing.push('E.Forever');
  member('ElvUI names no tag: an unknown tag shows nothing (no error)', /tinsert\(data, tagFunc or ''\)/, elv) || missing.push('tag fallback');
  member('DT.RegisteredDataTexts', /RegisteredDataTexts\[/, elv) || missing.push('RegisteredDataTexts');
  const details = luaOf('Details');
  for (const m of ['GetProfile', 'ApplyProfile', 'GetCurrentProfileName', 'GetInstance']) if (!member('Details:' + m, new RegExp('function Details:' + m + '\\b'), details)) missing.push('Details:' + m);
  for (const m of ['default_profile', 'always_use_profile_exception', 'UngroupInstance', 'RestoreMainWindowPosition', 'SaveMainWindowPosition', 'ReajustaGump', 'InstanceRefreshRows', 'SetBarSettings', 'EnableInstance']) if (!member('Details ' + m, new RegExp(m), details)) missing.push('Details ' + m);
  const ji = luaOf('JiberishIcons');
  for (const m of ['GetIdentityIcon', 'GetUnitSpecialization']) if (!member('JiberishIcons:' + m, new RegExp('function JI:' + m + '\\b'), ji)) missing.push('JI:' + m);
  check('every ElvUI, Details and Jiberish Icons member BANZAI calls exists in the installed Forever addons', missing.length === 0, missing.join(', ') || `${out.api.length} members: SAME`);
  // 1.5.0-dev3: what the Forever chat adapter and the window skins rely on, against the installed addons themselves
  const lacks = [];
  const rely = (name, ok) => { out.api.push({ name, state: ok ? 'SAME' : 'MISSING' }); if (!ok) lacks.push(name); };
  rely("E:GetModule('Chat')", /NewModule\('Chat'/.test(elv));
  rely('CH:PositionChats', /function CH:PositionChats\b/.test(elv));
  rely('CH.LeftChatWindow found by the profile\'s chat.panelSnapLeftID', /CH\.db\.panelSnapLeftID == index/.test(elv) && /CH\.LeftChatWindow, CH\.RightChatWindow = CH:FindChatWindows\(\)/.test(elv));
  rely('ElvUI repositions on FCF_DockFrame / FCF_UnDockFrame (its own secure hooks)', /SecureHook\('FCF_DockFrame', 'SnappingChanged'\)/.test(elv) && /SecureHook\('FCF_UnDockFrame', 'SnappingChanged'\)/.test(elv));
  rely('ElvUI\'s installer makes the undocked Loot / Trade window (the dev2 chat defect\'s origin)', /local rightChat = FCF_OpenNewWindow\(LOOT\)\s*FCF_UnDockFrame\(rightChat\)/.test(elv));
  rely('GeneralDockManager.primary / DOCKED_CHAT_FRAMES', /GeneralDockManager\.primary/.test(elv) && /DOCKED_CHAT_FRAMES/.test(elv));
  rely('E:CoroutineCallback: ElvUI tells a plugin, per panel, right after it re-templates or recolours it',
    elv.includes('function E:CoroutineCallback(func, callback, remove)') && elv.includes('callback(key, value, info.data)') && /function E:UpdateFrameTemplate\b/.test(elv) && /function E:UpdateBackdropColor\b/.test(elv));
  rely('E:UpdateMedia', /function E:UpdateMedia\b/.test(elv));
  rely('E:UpdateFrameTemplates', /function E:UpdateFrameTemplates\b/.test(elv));
  rely('E.db.general.backdropfadecolor is ElvUI\'s Transparent panel colour', /E\.media\.backdropfadecolor = E:SetColorTable\(E\.media\.backdropfadecolor, E:UpdateClassColor\(E\.db\.general\.backdropfadecolor\)\)/.test(elv));
  rely('ElvUI marks a templated frame with frame.template', /frame\.template = template or 'Default'/.test(elv));
  rely('S:HandlePortraitFrame templates the frame itself or a backdrop child', /function S:HandlePortraitFrame\(frame, createBackdrop, noStrip\)/.test(elv) && /frame:CreateBackdrop\('Transparent', nil, nil, nil, nil, nil, nil, true\)\s*else\s*frame:SetTemplate\('Transparent'\)/.test(elv));
  // the Tier 1 windows: the skin file ElvUI loads on WoW Forever names the window BANZAI dresses
  const loadForever = read(path.join(FOREVER_ADDONS, 'ElvUI', 'Game', 'load_forever.xml'));
  const TIER1 = [['Character', 'CharacterFrame'], ['PlayerSpells', 'PlayerSpellsFrame'], ['Professions', 'ProfessionsFrame'], ['WorldMap', 'WorldMapFrame'], ['Quest', 'QuestFrame'], ['Merchant', 'MerchantFrame'],
    ['Gossip', 'GossipFrame'], ['Trainer', 'ClassTrainerFrame'], ['Mail', 'MailFrame'], ['Mail', 'OpenMailFrame'], ['Friends', 'FriendsFrame'], ['Friends', 'SocialUIFrame'], ['Communities', 'CommunitiesFrame'], ['Inspect', 'InspectFrame'], ['Trade', 'TradeFrame']];
  const adapters = read(path.join(DIST, 'BushidoPrivateCompat', 'SkinAdapters.lua'));
  const unknownWindows = [];
  for (const [file, frame] of TIER1) {
    const skinFile = path.join(FOREVER_ADDONS, 'ElvUI', 'Game', 'Shared', 'Skins', file + '.lua');
    const ok = loadForever.includes(`Shared\\Skins\\${file}.lua`) && fs.existsSync(skinFile) && new RegExp('\\b' + frame + '\\b').test(read(skinFile)) && adapters.includes(`'${frame}'`);
    if (!ok) unknownWindows.push(`${frame} (${file}.lua)`);
  }
  out.windows = TIER1.map(([file, frame]) => ({ frame, skin: file + '.lua' }));
  check('every Tier 1 window BANZAI dresses is one the installed ElvUI skins on WoW Forever (its load_forever.xml skin file names it)', unknownWindows.length === 0, unknownWindows.join(', ') || `${TIER1.length} windows`);
  const notLoaded = ['SpellBook', 'Talent', 'TradeSkill', 'Craft'].filter((f) => loadForever.includes(`Shared\\Skins\\${f}.lua`));
  check('the classic spellbook / talent / trade-skill windows are not Forever\'s (BANZAI names none of them)', notLoaded.length === 0 && !/'(SpellBookFrame|PlayerTalentFrame|TradeSkillFrame|CraftFrame)'/.test(adapters), notLoaded.join(', '));
  // Baganator (optional)
  const bagToc = path.join(FOREVER_ADDONS, 'Baganator', 'Baganator.toc');
  if (fs.existsSync(bagToc)) {
    const bag = luaOf('Baganator');
    out.baganator = { version: ((read(bagToc).match(/^## Version:\s*(.+)$/m) || [])[1] || '').trim() };
    rely('Baganator.API.Skins.RegisterListener / GetAllFrames / GetCurrentSkin', /function Baganator\.API\.Skins\.RegisterListener\(callback\)/.test(bag) && /function Baganator\.API\.Skins\.GetAllFrames\(\)/.test(bag) && /function Baganator\.API\.Skins\.GetCurrentSkin\(\)/.test(bag));
    rely('Baganator announces { regionType, region, tags } to every listener, whatever its theme', /local details = \{regionType = regionType, region = region, tags = tags\}/.test(bag) && /for _, listener in ipairs\(addonTable\.Skins\.skinListeners\) do/.test(bag));
    rely('Baganator\'s windows are "ButtonFrame" regions; its ElvUI theme hands them to S:HandlePortraitFrame', /AddFrame\("ButtonFrame"/.test(bag) && /ButtonFrame = function\(frame\)\s*S:HandlePortraitFrame\(frame\)/.test(bag));
    check(`Baganator ${out.baganator.version} is installed for WoW Forever (Interface 16001)`, /^## Interface:.*\b16001\b/m.test(read(bagToc)), out.baganator.version);
  } else note('Baganator is not installed: its adapter stays ABSENT (nothing to check against)');
  // Zygor (optional)
  const zygorDir = path.join(FOREVER_ADDONS, 'ZygorGuidesViewerForever');
  if (fs.existsSync(path.join(zygorDir, 'ZygorGuidesViewerForever.toc'))) {
    const zy = luaOf('ZygorGuidesViewerForever');
    const viewerXml = fs.existsSync(path.join(zygorDir, 'Skins', 'Default', 'ViewerFrame.xml')) ? read(path.join(zygorDir, 'Skins', 'Default', 'ViewerFrame.xml')) : '';
    out.zygor = { version: ((read(path.join(zygorDir, 'ZygorGuidesViewerForever.toc')).match(/^## Version:\s*(.+)$/m) || [])[1] || '').trim() };
    rely('Zygor makes its viewer once as the global ZygorGuidesViewerFrame', /CreateFrame\("FRAME","ZygorGuidesViewerFrame"/.test(zy));
    rely('the viewer frame has its own ApplySkin and AlignFrame', /function FrameProto:ApplySkin\(/.test(zy) && /function FrameProto:AlignFrame\(/.test(zy));
    rely('the viewer\'s Border / Back / Toolbar / TitleBar parts', ['Border', 'Back', 'Toolbar', 'TitleBar'].every((k) => new RegExp(`parentKey="${k}"`).test(viewerXml)));
    check(`Zygor Guides Viewer ${out.zygor.version} is installed for WoW Forever (Interface 16001)`, /^## Interface:.*\b16001\b/m.test(read(path.join(zygorDir, 'ZygorGuidesViewerForever.toc'))), out.zygor.version);
    // nothing of Zygor's is in BANZAI: no file of its folder, no guide text
    const copied = walk(path.join(DIST, 'BushidoPrivateCompat')).concat(walk(path.join(DIST, 'BushidoPrivateRestore'))).filter((f) => /zygor/i.test(path.basename(f)));
    check('no Zygor file is part of BANZAI', copied.length === 0, copied.map((f) => path.basename(f)).join(', '));
  } else note('Zygor is not installed: its adapter stays ABSENT (nothing to check against)');
  check('every ElvUI, Baganator and Zygor member the dev3 chat adapter and window skins rely on exists in the installed Forever addons', lacks.length === 0, lacks.join(' | ') || 'all present');
  out.minimapButtons = { manager: fs.existsSync(path.join(FOREVER_ADDONS, 'MinimapButtonButton')) ? 'MinimapButtonButton' : null };
  note(`dedicated minimap-button addon installed: ${out.minimapButtons.manager || 'none'}`);
  // tags, datatexts and media the Forever profile names
  const stack = elv + luaOf('ElvUI_mMediaTag') + luaOf('ElvUI_EltreumUI') + luaOf('JiberishIcons');
  const tags = new Set();
  for (const m of stack.matchAll(/AddTag\(\s*(['"])([^'"]+)\1/g)) tags.add(m[2]);
  for (const m of stack.matchAll(/\{\s*"(mMT-[A-Za-z:\-]+)"\s*,/g)) tags.add(m[1]); // mMediaTag registers its health tags from a list
  for (const base of ['name', 'target']) for (const len of ['veryshort', 'short', 'medium', 'long']) { tags.add(`${base}:${len}`); tags.add(`name:abbrev:${len}`); tags.add(`name:${len}:status`); } // ElvUI builds these by length
  for (const t of ['perhp', 'perpp', 'powercolor', 'status', 'name', 'difficulty', 'classcolor', 'namecolor']) if (new RegExp("\\['" + t + "'\\]\\s*=|AddTag\\('" + t + "'").test(elv)) tags.add(t); // oUF's own and ElvUI's
  for (const t of ['banzai:spec', 'banzai:spec:after', 'banzai:spec:before', 'banzai:split:name', 'banzai:split:spec']) tags.add(t); // BANZAI's own
  const used = new Map();
  for (const [k, v] of (written || new Map())) {
    if (!/\.(text_format|format)$/.test(k) || !/\[/.test(v)) continue;
    for (const m of v.matchAll(/\[..*?\]+/g)) {
      const b = m[0];
      const first = (b.match(/^.*>/) || [''])[0].length || 1;
      const lastIdx = b.indexOf('<');
      const name = b.slice(first, lastIdx === -1 ? -1 : lastIdx).replace(/\{[^}]*\}/g, '').replace(/^\[|\]$/g, '');
      if (name) used.set(name, k);
    }
  }
  const unknownTags = [...used.keys()].filter((t) => !tags.has(t)).sort();
  out.tags = { used: [...used.keys()].sort(), unknown: unknownTags };
  check('every tag the Forever profile uses is registered by the installed addons or by BANZAI itself', unknownTags.length === 0, unknownTags.join(', ') || `${used.size} tags`);
  const dts = new Set();
  for (const m of stack.matchAll(/RegisterDatatext\(\s*(['"])([^'"]+)\1/g)) dts.add(m[2]);
  const usedDts = [...(written || new Map())].filter(([k, v]) => /^profile\.datatexts\.panels\..*\.\d+$/.test(k) && /^string:./.test(v)).map(([, v]) => v.replace(/^string:/, ''));
  out.datatexts = { used: usedDts, unregistered: usedDts.filter((d) => !dts.has(d)) };
  note(`datatexts the historical profile names that mMediaTag 4.x no longer registers under that name (an empty slot on both clients, reported by the adapter, never rewritten): ${out.datatexts.unregistered.join(', ') || 'none'}`);
  const media = new Set();
  for (const a of ['ElvUI', 'ElvUI_EltreumUI', 'JiberishMedia', 'ElvUI_mMediaTag']) for (const m of luaOf(a).matchAll(/:Register\(\s*(['"])(font|statusbar)\1\s*,\s*(['"])([^'"]+)\3/g)) media.add(m[2] + '|' + m[4]);
  const pack = luaOf('!mMT_MediaPack');
  const need = [['font', 'GasoekOne'], ['font', 'Rubik-Bold'], ['statusbar', 'OverwatchJiberish1'], ['statusbar', 'Eltreum-Blank']];
  const noMedia = need.filter(([kind, name]) => !media.has(kind + '|' + name)).map((x) => x.join(' '));
  check('the fonts and bar textures the Banzai look needs are registered by the installed JiberishMedia / Eltruism', noMedia.length === 0, noMedia.join(', ') || need.map((x) => x[1]).join(', '));
  check('the mMT Media Pack carries Montserrat-Bold and the mMediaTag S series (optional media)', /Montserrat-Bold/.test(pack) && /"mMediaTag " \.\. upper \.\. i/.test(pack));
  return out;
}

// --------------------------------------------------------------------------- report
function report(b, c, i) {
  fs.mkdirSync(OUT, { recursive: true });
  const md = [`# BANZAI UI ${b.version} - offline evidence`, '', `Generated ${new Date().toISOString()} by tools/forevercheck.js. Nothing here was written to a game folder.`, '',
    `Proof: ${ADDONS.join(' + ')}, ${b.files} files, ${b.bytes} bytes.`, '', '## Checks', '', '```', ...log, '```', ''];
  for (const style of ['CLASSIC', 'SPLIT']) {
    md.push(`## BANZAI ${style} on WoW Forever (offline APPLY BANZAI)`, '');
    md.push('State: ' + Object.entries(c.state[style]).map(([k, v]) => `${k.replace(/^STATE\./, '')} = ${v.replace(/^string:/, '')}`).join('; '), '');
    md.push('Differences from the same apply on Retail:', '', '| setting | Retail | WoW Forever |', '|---|---|---|');
    for (const d of c.differences[style]) md.push(`| ${d.path} | \`${d.retail.replace(/^string:/, '')}\` | \`${d.forever.replace(/^string:/, '')}\` |`);
    md.push('');
    for (const [name] of SURFACES) {
      const rows = c.surfaces[style][name];
      md.push(`### ${name} (${rows.length} settings; * = differs from Retail)`, '', '```');
      for (const r of rows) md.push(`${r.forever === r.retail ? ' ' : '*'} ${r.path} = ${r.forever.replace(/^\w+:/, '')}`);
      md.push('```', '');
    }
  }
  if (i && !i.skipped) {
    md.push('## Installed WoW Forever addons (read only)', '', '| addon | version | Interface 16001 |', '|---|---|---|');
    for (const p of i.prerequisites) md.push(`| ${p.addon} | ${p.version || '-'} | ${p.interface16001 ? 'yes' : 'NO'} |`);
    md.push('', `ElvUI default profile: ${i.elvuiDefaults.leaves} leaves; Retail-only keys: ${i.elvuiDefaults.onlyRetail.length}; Forever-only keys: ${i.elvuiDefaults.onlyForever.join(', ')}.`, '',
      '| ElvUI default that differs | Retail | WoW Forever |', '|---|---|---|');
    for (const d of i.elvuiDefaults.differ) md.push(`| ${d.path} | \`${d.retail.replace(/^\w+:/, '')}\` | \`${d.forever.replace(/^\w+:/, '')}\` |`);
    md.push('', '| member BANZAI calls | installed |', '|---|---|');
    for (const a of i.api) md.push(`| ${a.name} | ${a.state} |`);
    md.push('', `Tags used by the Forever profile (${i.tags.used.length}): ${i.tags.used.join(', ')}`, '', `Datatext names not registered on this client: ${i.datatexts.unregistered.join(', ') || 'none'}`, '');
  }
  fs.writeFileSync(path.join(OUT, 'EVIDENCE.md'), md.join('\n'));
  fs.writeFileSync(path.join(OUT, 'evidence.json'), JSON.stringify({ build: b, config: { differences: c.differences, state: c.state, splitDifferences: c.splitDifferences }, installed: i }, null, 1));
}

function main() {
  if (!fs.existsSync(path.join(DIST, 'BushidoPrivateRestore', 'Flavor.lua'))) { console.error('run node tools/build.js first'); process.exit(2); }
  const b = build();
  const c = config();
  c.written = applied('forever', 'CLASSIC');
  const i = installed(c);
  report(b, c, i);
  console.log(`\n${failures ? failures + ' check(s) FAILED' : 'all checks passed'}; report: ${path.relative(ROOT, path.join(OUT, 'EVIDENCE.md'))}`);
  process.exit(failures ? 1 : 0);
}

main();
