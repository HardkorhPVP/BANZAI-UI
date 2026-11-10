#!/usr/bin/env node
// Offline validation of the private deployables in dist/.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');
const luaparse = require('luaparse');
const thirdparty = require('./thirdparty');
const strip0 = (code) => code.replace(/--\[\[[\s\S]*?\]\]/g, '').replace(/--[^\n]*/g, '');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');
const BACKUP_ROOT = 'C:\\Users\\DarrenSteinke\\Desktop\\Bushido-Private-Restoration-Backups';
const ADDONS = 'D:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns';
const CLIENT_INTERFACE = 120105;

const results = [];
let failures = 0;
function check(name, ok, detail = '') {
  results.push(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? '  -  ' + detail : ''}`);
  if (!ok) failures++;
}

function files(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...files(full)); else out.push(full);
  }
  return out;
}

function toc(addon) {
  const file = fs.readdirSync(path.join(DIST, addon)).find((f) => f.endsWith('.toc'));
  const text = fs.readFileSync(path.join(DIST, addon, file), 'utf8');
  const fields = {};
  const list = [];
  for (const line of text.split(/\r?\n/)) {
    const m = line.match(/^##\s*([^:]+):\s*(.*)$/);
    if (m) fields[m[1].trim()] = m[2].trim();
    else if (line.trim() && !line.startsWith('#')) list.push(line.trim());
  }
  return { file, fields, list };
}

// 1. syntax + TOC + load order
for (const addon of ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia']) {
  const t = toc(addon);
  const ifaces = (t.fields.Interface || '').split(',').map((s) => Number(s.trim()));
  const retail = ifaces.filter((n) => n >= 120000);
  check(`${addon}: TOC retail interface`, retail.some((n) => Math.floor(n / 100) === Math.floor(CLIENT_INTERFACE / 100)), `Interface ${t.fields.Interface}`);
  for (const entry of t.list) {
    const p = path.join(DIST, addon, entry.replace(/\\/g, path.sep));
    check(`${addon}: TOC file ${entry} exists`, fs.existsSync(p));
  }
  for (const file of files(path.join(DIST, addon)).filter((f) => f.endsWith('.lua'))) {
    try {
      luaparse.parse(fs.readFileSync(file, 'utf8'), { luaVersion: '5.1' });
      check(`${addon}: Lua 5.1 syntax ${path.basename(file)}`, true);
    } catch (e) {
      check(`${addon}: Lua 5.1 syntax ${path.basename(file)}`, false, e.message);
    }
  }
}
const restoreToc = toc('BushidoPrivateRestore');
check('Restore: Payloads.lua loads before Transform/Restore', restoreToc.list.indexOf('Payloads.lua') < restoreToc.list.indexOf('Restore.lua'));
check('Restore: depends on ElvUI, loads after Eltruism/mMediaTag/Details', /ElvUI/.test(restoreToc.fields.Dependencies) && /ElvUI_EltreumUI/.test(restoreToc.fields.OptionalDeps) && /ElvUI_mMediaTag/.test(restoreToc.fields.OptionalDeps) && /Details/.test(restoreToc.fields.OptionalDeps));
const compatToc = toc('BushidoPrivateCompat');
check('Compat: depends on ElvUI and JiberishMedia', /ElvUI/.test(compatToc.fields.Dependencies) && /JiberishMedia/.test(compatToc.fields.Dependencies));
check('Compat: Geometry.lua loads before Compat.lua', compatToc.list.indexOf('Geometry.lua') < compatToc.list.indexOf('Compat.lua'));
check('Compat: theme setting saved (BanzaiCompatDB)', compatToc.fields.SavedVariables === 'BanzaiCompatDB');
check('Compat: font registry loads after Theme and before runtime consumers; existing module order stays intact',
  compatToc.list.join(',') === 'Geometry.lua,IdentityManifest.lua,Theme.lua,FontBakeoff.lua,Tags.lua,Compat.lua,Health.lua,Identity.lua,Split.lua,CastBar.lua,PvPFrames.lua,TargetPlate.lua,Tooltip.lua,Bar.lua,Info.lua,Tracker.lua,CastHistory.lua,ActionButtons.lua,CooldownBars.lua,AFK.lua,Preview.lua', compatToc.list.join(','));
check('Compat: Jiberish Icons optional (identity circles), loads before Banzai Art', /JiberishIcons/.test(compatToc.fields.OptionalDeps || ''));
check('Restore: load order Payloads, Transform, Restore, Roles, Sync, Options', restoreToc.list.join(',') === 'Payloads.lua,Transform.lua,Restore.lua,Roles.lua,Sync.lua,Options.lua', restoreToc.list.join(','));

// 1b. BANZAI version and names (folders, SavedVariables and the ElvUI profile name keep their old identifiers)
const VERSION = '1.4.0';
const restoreSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', 'Restore.lua'), 'utf8');
const themeSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Theme.lua'), 'utf8');
const codeVersion = (restoreSource.match(/local VERSION = '([^']+)'/) || [])[1];
const artVersion = (themeSource.match(/Theme\.VERSION = '([^']+)'/) || [])[1];
check(`BANZAI version ${VERSION} in both TOCs, the status code and the art`, restoreToc.fields.Version === VERSION && compatToc.fields.Version === VERSION && codeVersion === VERSION && artVersion === VERSION, `${restoreToc.fields.Version} / ${compatToc.fields.Version} / ${codeVersion} / ${artVersion}`);
const plainTitle = (t) => String(t || '').replace(/\|c\x66\x66[0-9a-fA-F]{6}|\|r/g, '');
check('Banzai titles', plainTitle(restoreToc.fields.Title) === 'Banzai' && plainTitle(compatToc.fields.Title) === 'Banzai Art', `${restoreToc.fields.Title} / ${compatToc.fields.Title}`);
const optionsSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', 'Options.lua'), 'utf8');
check('Options: registered through ElvUI\'s plugin library into E.Options.args', /LibElvUIPlugin-1\.0/.test(optionsSource) && /RegisterPlugin\(addonName, Options\.Insert\)/.test(optionsSource) && /E\.Options\.args\.banzai = /.test(optionsSource));
check('Options: no edits to the ElvUI options window frames', !/Config_GetWindow|leftHolder|E\.OptionsUI|hooksecurefunc/.test(strip0(optionsSource)));
const transformSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', 'Transform.lua'), 'utf8');
const compatSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Compat.lua'), 'utf8');
const layoutT = (transformSource.match(/T\.DETAILS_LAYOUT = \{([^}]*)\}/) || [])[1] || '';
const layoutC = (compatSource.match(/Compat\.DETAILS = \{([\s\S]*?)frameWidth/) || [])[1] || '';
const nums = (s) => ['width', 'height', 'gap', 'right', 'bottom'].map((k) => (s.match(new RegExp(k + ' = (-?[0-9.]+)')) || [])[1]).join(',');
check('Details layout numbers identical in Banzai and Banzai Art', nums(layoutT) === nums(layoutC) && !nums(layoutT).includes('undefined'), nums(layoutT));
{
  // 0.5.0 composition: chat panel inside a frame of the Details frame's size, both on the bottom panel
  const num = (src, re) => Number((src.match(re) || [])[1]);
  const inset = num(compatSource, /Compat\.BAND = \{[^}]*inset = ([0-9.]+)/);
  const outer = num(compatSource, /Compat\.BAND = \{[^}]*outer = ([0-9.]+)/);
  const fw = num(compatSource, /frameWidth = ([0-9.]+)/); const fh = num(compatSource, /frameHeight = ([0-9.]+)/);
  const chatLeft = num(compatSource, /Compat\.CHAT = \{[^}]*left = (-?[0-9.]+)/); // 1.2.0: negative (flush with the left screen edge)
  const chatW = num(compatSource, /Compat\.CHAT = \{[^}]*width = ([0-9.]+)/); const chatH = num(compatSource, /Compat\.CHAT = \{[^}]*height = ([0-9.]+)/);
  const tChat = (transformSource.match(/T\.CHAT = \{([^}]*)\}/) || [])[1] || '';
  const tx = num(tChat, /x = ([0-9.]+)/); const tw = num(tChat, /width = ([0-9.]+)/); const th = num(tChat, /height = ([0-9.]+)/); const ti = num(tChat, /inset = ([0-9.]+)/);
  const bar = num(themeSource, /barHeight = ([0-9]+)/);
  const dBottom = num(layoutC, /bottom = (-?[0-9.]+)/);
  // 1.1.0: the frame keeps its 0.6.0 outer size (square again: the bamboo stalks run straight); the panel sits in its middle, clear of the stalks
  const stalk = num(compatSource, /Compat\.PANEL = \{[^}]*stalk = ([0-9.]+)/);
  check('chat frame = Details frame size (the approved dimensions); chat panel upright in its middle, the side stalks clear of it, the content inset = outer margin + stalk', chatW === fw && chatH === fh && th === fh - 2 * inset && (fw - tw) / 2 >= outer + stalk && inset === outer + stalk && Math.abs(tx - (chatLeft + (fw - tw) / 2)) < 0.01,
    `frame ${fw}x${fh}, panel ${tw}x${th} at x ${tx}, stalk ${stalk}`);
  check('Details and chat frames flush with the bottom panel top edge', dBottom - inset + outer === bar && ti === dBottom - bar, `bar ${bar}, windows at ${dBottom}, inset ${inset}`);
}
check('/banzai command with /bushido kept', /SLASH_BANZAI1 = '\/banzai'/.test(restoreSource) && /SLASH_BANZAI2 = '\/bushido'/.test(restoreSource));
check('SavedVariables name unchanged (rollback record kept)', restoreToc.fields.SavedVariables === 'BushidoPrivateRestoreDB');

// 2. JiberishMedia is the audited 1.1.0 and every registered media file exists
const jm = toc('JiberishMedia');
check('JiberishMedia: version 1.1.0', jm.fields.Version === '1.1.0', jm.fields.Version);
const mediaLua = fs.readFileSync(path.join(DIST, 'JiberishMedia', 'Media.lua'), 'utf8');
const registered = [...mediaLua.matchAll(/\[\[Interface\\Addons\\JiberishMedia\\([^\]]+)\]\]/gi)].map((m) => m[1]);
const missingMedia = registered.filter((rel) => !fs.existsSync(path.join(DIST, 'JiberishMedia', rel.replace(/\\/g, path.sep))));
check('JiberishMedia: all LibSharedMedia paths exist', missingMedia.length === 0, `${registered.length} registered${missingMedia.length ? ', missing ' + missingMedia.join(', ') : ''}`);
check('JiberishMedia: GasoekOne (Lixdu stand-in) registered', /"GasoekOne"/.test(mediaLua));
const srcFiles = files(path.join('C:\\Users\\DarrenSteinke\\Desktop\\HARDKORHUI-Bushido-Assessment\\JiberishMedia\\JiberishMedia'));
const sameAsSource = srcFiles.every((f) => {
  const rel = path.relative('C:\\Users\\DarrenSteinke\\Desktop\\HARDKORHUI-Bushido-Assessment\\JiberishMedia\\JiberishMedia', f);
  const d = path.join(DIST, 'JiberishMedia', rel);
  return fs.existsSync(d) && fs.readFileSync(d).equals(fs.readFileSync(f));
});
check('JiberishMedia: byte-identical to the audited source', sameAsSource && files(path.join(DIST, 'JiberishMedia')).length === srcFiles.length);

// 3. Compat media references
const geometryText = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Geometry.lua'), 'utf8');
const textures = [...new Set([...geometryText.matchAll(/texture = "([^"]+)"/g)].map((m) => m[1]).filter((t) => t !== 'WHITE'))];
const missingTex = textures.filter((t) => !fs.existsSync(path.join(DIST, 'JiberishMedia', 'textures', t + '.tga')));
check('Compat: every texture referenced exists in JiberishMedia', missingTex.length === 0, textures.join(', '));
// Bushido / Jiberish art is referenced in place; the only images in the Banzai
// addons are the Banzai media (original bamboo + Darren's Banzai branding).
const compatImages = files(path.join(DIST, 'BushidoPrivateCompat')).filter((f) => /\.(tga|blp|png|jpe?g)$/i.test(f) && !/[\\/]BanzaiIdentity[\\/]/.test(f)).map((f) => path.basename(f)).sort();
const BANZAI_MEDIA = ['BanzaiBar.tga', 'BanzaiBonsai.tga', 'BanzaiBundle.tga', 'BanzaiBundleTie.tga', 'BanzaiButtonCircle.tga', 'BanzaiButtonGlow.tga', 'BanzaiButtonGlowSquare.tga', 'BanzaiButtonMask.tga', 'BanzaiButtonMask128.tga', 'BanzaiButtonRing.tga', 'BanzaiButtonRing128.tga', 'BanzaiIcon.tga', 'BanzaiIdentityMask.tga', 'BanzaiIdentityRing.tga', 'BanzaiLogo.tga', 'BanzaiParchmentCorners.tga', 'BanzaiParchmentEdge.tga', 'BanzaiParchmentTile.tga', 'BanzaiRopeTie.tga', // 1.3.7: the parchment material (the 1.1.0 BanzaiParchment sheet no longer built)
  'BanzaiSquareBorder128.tga', 'BanzaiSquareBorder34.tga', 'BanzaiSquareBorder35.tga', 'BanzaiSquareBorder36.tga', 'BanzaiSquareBorder37.tga', 'BanzaiSquareBorder38.tga', 'BanzaiSquareBorder39.tga',
  'BanzaiSquareBorder40.tga', 'BanzaiSquareBorder41.tga', 'BanzaiSquareBorder42.tga', 'BanzaiSquareGlow.tga', 'BanzaiSquareMask.tga', 'BanzaiSquareSwipe.tga', // 1.2.0 BANZAI SQUARE (a border per whole-pixel button width)
  'BanzaiStalk.tga', 'BanzaiStalkEnd.tga', 'BanzaiWordmark.tga',
  'BanzaiClassDiscs.tga', 'BanzaiHubAccent.tga', 'BanzaiHubDisc.tga', 'BanzaiHubMask.tga', 'BanzaiHubRing.tga', 'BanzaiHubSwipe.tga', // 1.3.0 BANZAI SPLIT hub + COMPACT Details discs
  'BanzaiHubCrest.tga'].sort(); // 1.3.3 the TARGET NPC preview's crest
// 1.3.0: Darren's own identity icons (assets/identity) are converted into media/BanzaiIdentity only when present and valid (checked in the 1.3.0 block)
const identityIcons = files(path.join(DIST, 'BushidoPrivateCompat')).filter((f) => /[\\/]BanzaiIdentity[\\/]/.test(f));
check('Compat: only Banzai media in the addon (Bushido art referenced in place)', compatImages.join(',') === BANZAI_MEDIA.join(',') && /JiberishMedia/.test(geometryText), compatImages.join(', '));
const jmBytes = new Set(files(path.join(DIST, 'JiberishMedia')).map((f) => crypto.createHash('sha1').update(fs.readFileSync(f)).digest('hex')));
check('Compat: no Banzai media file is a copy of a JiberishMedia file', compatImages.every((name) => !jmBytes.has(crypto.createHash('sha1').update(fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'media', name))).digest('hex'))));
for (const name of BANZAI_MEDIA) {
  const file = path.join(DIST, 'BushidoPrivateCompat', 'media', name);
  let ok = false; let detail = 'missing';
  if (fs.existsSync(file)) {
    const h = fs.readFileSync(file).subarray(0, 18);
    const w = h.readUInt16LE(12); const hh = h.readUInt16LE(14);
    const pow2 = (n) => n > 0 && (n & (n - 1)) === 0;
    ok = h[2] === 2 && h[16] === 32 && h[17] === 0x28 && pow2(w) && pow2(hh) && w >= 64 && hh >= 32;
    detail = `${w}x${hh}, 32-bit, same TGA layout as JiberishMedia's textures`;
  }
  check(`Banzai media ${name} loads (power-of-two, high resolution)`, ok, detail);
}
const actionSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'ActionButtons.lua'), 'utf8');
const previewSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Preview.lua'), 'utf8');
const plateSource = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'TargetPlate.lua'), 'utf8');
const identitySource = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Identity.lua'), 'utf8');
const mediaRefs = [...new Set([...(compatSource + themeSource + optionsSource + actionSource + previewSource + plateSource + identitySource).matchAll(/'(Banzai[A-Za-z0-9]+)(?:\.tga)?'/g)].map((m) => m[1]))].filter((n) => /^Banzai(Bamboo|Bundle|Bar$|Logo$|Icon|Button(?!$)|Wordmark|Bonsai|Identity|Stalk|RopeTie|Parchment|Square)/.test(n) && n !== 'BanzaiLogoButton');
for (const ref of mediaRefs) {
  check(`media referenced by code exists: ${ref}`, BANZAI_MEDIA.includes(ref + '.tga') || BANZAI_MEDIA.some((m) => m.startsWith(ref) && /^\d+\.tga$/.test(m.slice(ref.length)))); // 1.2.0: a size appended (BanzaiSquareBorder39)
}
check('1.3.0 media referenced by code: the hub disc / ring / accent / mask / swipe (Identity.lua) and the class discs (Transform, BANZAI COMPACT)', ['BanzaiHubDisc', 'BanzaiHubRing', 'BanzaiHubAccent', 'BanzaiHubMask', 'BanzaiHubSwipe'].every((n) => identitySource.includes("'" + n + "'")) && /BanzaiClassDiscs/.test(transformSource));
check('media referenced by code: bundle, cord, bar, button mask / ring / swipe / halos, identity ring / mask, wordmark, tree; 1.1.0: stalk, stalk ends, rope tie, parchment (no band, no minimap mask; 1.3.7: the parchment tile, edge strips and corners - no longer the 1.1.0 sheet)', ['BanzaiBundle', 'BanzaiBundleTie', 'BanzaiBar', 'BanzaiButtonMask', 'BanzaiButtonCircle', 'BanzaiButtonRing', 'BanzaiButtonGlow', 'BanzaiButtonGlowSquare', 'BanzaiIdentityRing', 'BanzaiIdentityMask', 'BanzaiWordmark', 'BanzaiBonsai', 'BanzaiStalk', 'BanzaiStalkEnd', 'BanzaiRopeTie', 'BanzaiParchmentTile', 'BanzaiParchmentEdge', 'BanzaiParchmentCorners'].every((n) => mediaRefs.includes(n)) && !mediaRefs.includes('BanzaiParchment') && !mediaRefs.includes('BanzaiFrameBand') && !mediaRefs.includes('BanzaiMinimapMask'), mediaRefs.join(', '));
check('every size variant the code builds exists (128 px button set)', /RING \.\. set\.suffix/.test(actionSource) && /MASK \.\. set\.suffix/.test(actionSource) && ['BanzaiButtonRing128.tga', 'BanzaiButtonMask128.tga'].every((n) => BANZAI_MEDIA.includes(n)));
{
  // the HUD wordmark: transparent background (corners and edges clear), letters solid
  const wm = path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiWordmark.tga');
  const img = require('./lib/tga').read(wm);
  const alpha = (x, y) => img.px[(y * img.w + x) * 4 + 3];
  const corners = [alpha(0, 0), alpha(img.w - 1, 0), alpha(0, img.h - 1), alpha(img.w - 1, img.h - 1)];
  let solid = 0;
  for (let i = 3; i < img.px.length; i += 4) if (img.px[i] > 200) solid++;
  // circular action buttons (0.7.0): ring / mask drawn for the pixels they cover; the shape unchanged
  const tgaLib = require('./lib/tga');
  const bamboo = require('./lib/bamboo');
  const ring = tgaLib.read(path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiButtonRing.tga'));
  const mask = tgaLib.read(path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiButtonMask.tga'));
  const swipe = tgaLib.read(path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiButtonCircle.tga'));
  const row = (img, y) => [...Array(img.w).keys()].map((x) => img.px[(y * img.w + x) * 4 + 3]);
  const col = (img, x) => [...Array(img.h).keys()].map((y) => img.px[(y * img.w + x) * 4 + 3]);
  const cover = (a) => a.reduce((n, v) => n + v / 255, 0); // exact covered width (anti-aliased edges count by coverage)
  const set = bamboo.BUTTON_SETS[0];
  check('circular buttons: square canvases, circles not squashed (row = column coverage)', ring.w === ring.h && mask.w === mask.h && swipe.w === swipe.h
    && Math.abs(cover(row(mask, mask.h / 2)) - cover(col(mask, mask.w / 2))) < 0.05, `${ring.w}x${ring.h}, mask ${cover(row(mask, mask.h / 2)).toFixed(2)} / ${cover(col(mask, mask.w / 2)).toFixed(2)} px across`);
  // the ring band on the middle row: from the inner to the outer edge, over the radius of the button it is drawn for
  const mid = row(ring, ring.h / 2);
  const ringSolid = mid.filter((v) => v > 200).length / 2;
  check('circular buttons: ring thickness kept (0.5.x shape, 24 % of the radius; at least twice the old 8.5 % rim)', bamboo.RING.outer === 0.98 && bamboo.RING.inner === 0.74 && ringSolid / (set.design / 2) >= 0.17, `${(100 * ringSolid / (set.design / 2)).toFixed(1)} % of the radius solid`);
  check('HUD wordmark: transparent background, no panel', corners.every((a) => a === 0) && solid > img.w * img.h * 0.05 && solid < img.w * img.h * 0.7, `${img.w}x${img.h}, ${Math.round(100 * solid / (img.w * img.h))}% solid`);
}

// 4. forbidden behaviour in the original code
const original = [
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Theme.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Tags.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Compat.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Health.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Bar.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Tracker.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'CastHistory.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'ActionButtons.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Preview.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'PvPFrames.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'CooldownBars.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'TargetPlate.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Identity.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Split.lua'), // 1.3.0
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Tooltip.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Info.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'AFK.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'Transform.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'Restore.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'Roles.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'Sync.lua'),
  path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'Options.lua'),
];
const strip = (code) => code.replace(/--\[\[[\s\S]*?\]\]/g, '').replace(/--[^\n]*/g, '');
const forbidden = [
  ['WeakAuras runtime calls', /\bWeakAuras\b|WeakAurasSaved/],
  ['combat-log registration', /COMBAT_LOG_EVENT|CombatLogGetCurrentEventInfo/],
  ['HARDKORHUI hooks / references', /HARDKORHUI/],
  ['secure hooks', /hooksecurefunc|SecureHook/],
  ['old ElvUI StaggeredUpdateAll', /StaggeredUpdateAll/],
  ['LibDeflate / old ElvUI decoder', /LibDeflate|E\.Libs\.Deflate/],
  ['GCD inference', /61304/],
  // 0.9.0: the player's own cooldowns are read where Darren asked for them (the cooldown bars), nowhere else
  ['cooldown reads', /GetSpellCooldown/, ['CooldownBars.lua']],
  ['aura / health inference', /UnitAura|C_UnitAuras|UnitHealth\b/],
  ['mask textures on art (0.3.0 grey target)', /CreateMaskTexture|AddMaskTexture/, ['ActionButtons.lua', 'Identity.lua']],
  ['uninstalling addons', /DeleteFile|C_AddOns\.UninstallAddOn/],
  // 1.0.1: no exception any more - the sArena choice is gone, Banzai switches no addon on or off
  ['switching addons on / off', /DisableAddOn|EnableAddOn/],
  // 0.9.0: the game's arena trinket data only for Banzai Art's trinket circles
  ['arena trinket reads', /C_PvP\./, ['PvPFrames.lua']],
  ['secure templates / unit frames of its own', /Secure\w*Template|SecureHandler|RegisterUnitWatch|SecureUnitButton/],
  ['sword art', /Crosshair_unableAttack|[Ss]word/],
  ['Kaliel tracker frame edits', /KT_ObjectiveTracker|KalielsTrackerFrame/],
  // 1.0.2: Blizzard's objective tracker parked while the Banzai tracker shows - Restore.lua only (checked below)
  ['Blizzard tracker frame edits', /ObjectiveTrackerFrame/, ['Restore.lua']],
  ['gameplay-data writes (bindings, macros, action slots, talents, equipment)', /SetBinding|SaveBindings|CreateMacro|EditMacro|DeleteMacro|PickupAction|PlaceAction|SetSpecialization|LearnTalent|C_EquipmentSet|C_ClassTalents/],
];
for (const file of original) {
  const code = strip(fs.readFileSync(file, 'utf8'));
  for (const [label, re, except] of forbidden) {
    if (except && [].concat(except).includes(path.basename(file))) continue;
    check(`${path.basename(file)}: no ${label}`, !re.test(code));
  }
}

// 5. global reads in the original code are known WoW / Lua globals
const KNOWN = new Set(['_G', 'print', 'format', 'date', 'type', 'pairs', 'ipairs', 'next', 'tostring', 'tonumber', 'string', 'table', 'math',
  'rawget', 'rawset', 'pcall', 'select', 'unpack', 'ElvUI', 'ElvDB', 'ElvPrivateDB', 'LibStub', 'Details', 'DetailsFramework',
  'C_AddOns', 'C_Timer', 'C_EditMode', 'Enum', 'CreateFrame', 'UIParent', 'Minimap', 'StaticPopupDialogs', 'StaticPopup_Show',
  'SlashCmdList', 'SLASH_BANZAI1', 'SLASH_BANZAI2', 'ReloadUI', 'InCombatLockdown', 'UnitClass', 'UnitExists', 'UnitName', 'issecretvalue',
  'GetScreenHeight', 'CreateColor', 'C_ClassColor', 'RAID_CLASS_COLORS',
  // bottom bar / options: the player's own client data only
  'C_CurrencyInfo', 'GetMasteryEffect', 'GetHaste', 'GetCombatRatingBonus', 'GetVersatilityBonus', 'CR_VERSATILITY_DAMAGE_DONE',
  'GetInventoryItemDurability', 'GetFramerate', 'GetNetStats', 'GetSpecialization', 'GetSpecializationInfo', 'GetAverageItemLevel',
  'GetProfessions', 'GetProfessionInfo', 'C_FriendList', 'BNGetNumFriends', 'IsInGuild', 'GetNumGuildMembers', 'GetMoney', 'PlayerSpellsUtil',
  'BushidoPrivateRestoreDB', 'BanzaiCompat', 'BanzaiCompatDB', 'KalielsTrackerDB', 'MinimapButtonButtonOptions',
  // 0.4.0: tracker (quest log API), cast history (spell data), zone name
  'C_QuestLog', 'C_SuperTrack', 'QuestMapFrame_OpenToQuestDetails', 'C_Spell', 'GetMinimapZoneText', 'GetZoneText',
  // 0.5.0: the player's own spec for the identity line
  'UnitIsUnit', 'UnitIsPlayer', 'C_TooltipInfo', 'GetSpecializationInfoForClassID', 'GetNumSpecializationsForClassID',
  // circular action buttons: the game's own proc highlight
  'C_SpellActivationOverlay', 'IsSpellOverlayed',
  // 0.5.1: another player's spec from the game's inspect data
  'NotifyInspect', 'CanInspect', 'GetInspectSpecialization', 'GetSpecializationInfoByID', 'ClearInspectPlayer', 'UnitGUID', 'GetTime',
  // 0.6.0: per-character settings, the targeted nameplate
  'GetRealmName', 'C_NamePlate', 'UnitReaction',
  // 0.7.0: pixel-exact circles, the arena context of the role layouts, arena enemy specs, the preview's role arrangement
  'GetPhysicalScreenSize', 'IsInInstance', 'GetArenaOpponentSpec', 'setmetatable',
  // 0.9.0: the player's own known spells / cooldowns (cooldown bars), the game's arena trinket data (trinket circles)
  'C_SpellBook', 'IsPlayerSpell', 'IsSpellKnown', 'C_PvP',
  // 1.0.0: the bottom-panel / objective tooltips (the player's own data, the quest log), the AFK screen
  'error', 'Ambiguate', 'BreakUpLargeNumbers', 'CR_HASTE_MELEE', 'CR_MASTERY', 'CR_VERSATILITY_DAMAGE_TAKEN', 'C_Bank', 'C_BattleNet', 'C_DateAndTime', 'C_GuildInfo',
  'C_SpecializationInfo', 'GetCombatRating', 'GetGameTime', 'GetGuildInfo', 'GetGuildRosterInfo', 'GetGuildRosterMOTD', 'GetLootSpecialization', 'PlayerIsTimerunning',
  'UnitHonor', 'UnitHonorLevel', 'UnitHonorMax', 'C_TaskQuest', 'C_Map', 'C_PetBattles', 'GetBattlefieldStatus', 'UnitIsAFK', 'UnitLevel',
  // 1.3.0 BANZAI SPLIT: the game's cast data and duration objects for the hubs (Split.lua only, checked there), the unit's resource type /
  // maximum, tapped / connected / classification state, the game drawing an NPC's portrait
  'UnitCastingInfo', 'UnitChannelInfo', 'UnitCastingDuration', 'UnitChannelDuration', 'UnitEmpoweredChannelDuration', 'UnitPowerType', 'UnitPowerMax',
  'UnitIsTapDenied', 'UnitIsConnected', 'UnitClassification', 'SetPortraitTexture',
  // 1.3.4 the 12.x access question for a table (PvPFrames.lua's access gate)
  'issecrettable']);
for (const file of original) {
  const ast = luaparse.parse(fs.readFileSync(file, 'utf8'), { luaVersion: '5.1', scope: true });
  const unknown = new Set((ast.globals || []).map((g) => g.name).filter((name) => !KNOWN.has(name)));
  check(`${path.basename(file)}: only known globals`, unknown.size === 0, [...unknown].join(', '));
}

// 6. package integrity
const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'build-manifest.json'), 'utf8'));
const distFiles = files(DIST).map((f) => path.relative(DIST, f).replace(/\\/g, '/'));
const mismatched = distFiles.filter((f) => manifest[f] !== crypto.createHash('sha1').update(fs.readFileSync(path.join(DIST, f))).digest('hex'));
check('dist matches the build manifest', mismatched.length === 0 && distFiles.length === Object.keys(manifest).length, `${distFiles.length} files`);
check('dist contains no Git metadata or assessment files', !distFiles.some((f) => /(^|\/)\.git|\.md$|assessment/i.test(f) && !/^JiberishMedia\/(Libs\/README\.md|licenses\/README\.md)$/.test(f)));

// 7. backup + environment
const backupDirs = fs.existsSync(BACKUP_ROOT) ? fs.readdirSync(BACKUP_ROOT) : [];
const original01 = backupDirs.filter((d) => d.startsWith('WTF-')).sort().pop();
const originalFiles = original01 ? files(path.join(BACKUP_ROOT, original01)).length : 0;
check('original WTF backup (before any restoration) exists', Boolean(original01) && originalFiles > 1000, original01 ? `${path.join(BACKUP_ROOT, original01)} (${originalFiles} files)` : 'none');
let banzaiDir = null;
for (const version of ['0.1.0', '0.2.0', '0.3.0', '0.4.0', '0.5.0', '0.5.1', '0.6.0']) {
  const name = backupDirs.filter((d) => d.startsWith(`Banzai-${version}-`)).sort().pop();
  const dir = name && path.join(BACKUP_ROOT, name);
  const ok = dir && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(dir, 'addons', a)))
    && fs.existsSync(path.join(dir, 'workspace', `banzai-${version}.bundle`)) && files(path.join(dir, 'WTF-as-last-saved')).length > 1000;
  const toc = dir && path.join(dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc');
  const right = toc && fs.existsSync(toc) && fs.readFileSync(toc, 'utf8').includes(`## Version: ${version}`);
  check(`BANZAI ${version} backup (installed addons ${version}, workspace, WTF) exists`, Boolean(ok && right), dir || 'none');
  if (ok) banzaiDir = dir;
}
let wowRunning = false;
try { wowRunning = /Wow\.exe/i.test(execSync('tasklist /FI "IMAGENAME eq Wow.exe" /NH', { encoding: 'utf8' })); } catch (e) { /* ignore */ }
check('World of Warcraft is not running', !wowRunning);
check('third-party addon folders are not targets of this build', !distFiles.some((f) => /^(ElvUI|ElvUI_EltreumUI|ElvUI_mMediaTag|Details|JiberishIcons|!KalielsTracker|MinimapButtonButton)\//.test(f)));
// 1.3.1: the newest recorded third-party state (a release backup by tools/backup.js, a deploy backup by tools/deploy.js,
// else the 0.6.0 backup's): Darren's addon manager updates third-party addons between milestones, so each backup records it anew
const stampOf = (d) => (d.match(/(\d{8}-\d{6})$/) || [])[1] || '';
const baselineDir = backupDirs.filter((d) => /^Banzai-/.test(d) && fs.existsSync(path.join(BACKUP_ROOT, d, 'thirdparty-baseline.json'))).sort((x, y) => stampOf(x).localeCompare(stampOf(y))).pop();
if (baselineDir) banzaiDir = path.join(BACKUP_ROOT, baselineDir);
const baselineFile = banzaiDir && path.join(banzaiDir, 'thirdparty-baseline.json');
if (baselineFile && fs.existsSync(baselineFile)) {
  const r = thirdparty.compare(JSON.parse(fs.readFileSync(baselineFile, 'utf8')));
  check(`third-party addon files unchanged since the latest backup (${path.basename(banzaiDir)}; no source modified)`, r.changed.length === 0, r.changed.length ? r.changed.slice(0, 5).join(', ') : `${r.files} files in ${thirdparty.FOLDERS.length} folders`);
} else {
  check('third-party baseline recorded', false, 'missing thirdparty-baseline.json');
}
check('HARDKORHUI addon folder present and untouched by this build', fs.existsSync(path.join(ADDONS, 'HARDKORHUI')) && !distFiles.some((f) => /^HARDKORHUI\//.test(f)));

// 8. git hygiene (only original work is tracked)
let tracked = [];
try { tracked = execSync('git ls-files', { cwd: ROOT, encoding: 'utf8' }).split('\n').filter(Boolean); } catch (e) { /* no commits yet */ }
check('git: no generated or third-party files tracked (only Darren\'s Banzai branding as images and the seven approved display fonts under media/fonts)', !tracked.some((f) => (/^(dist|build)\/|Payloads\.lua|Geometry\.lua|build-manifest/.test(f) || (/\.(ttf|otf)$/i.test(f) && !/^addons\/BushidoPrivateCompat\/media\/fonts\//.test(f))) || (/\.(tga|blp|png|jpe?g)$/i.test(f) && !/^assets\/branding\/Banzai(Logo|Icon)\.tga$/.test(f)
  && !/^assets\/identity\/class-(deathknight|demonhunter|druid|evoker|hunter|mage|monk|paladin|priest|rogue|shaman|warlock|warrior)\.png$/.test(f))), `${tracked.length} tracked (1.3.0: and Darren's own identity icons - 1.3.2: assets/identity/class-<class>.png)`);
let remotes = '';
try { remotes = execSync('git remote', { cwd: ROOT, encoding: 'utf8' }).trim(); } catch (e) { /* ignore */ }
check('git: no remote configured', remotes === '');
check('installed AddOns folder found', fs.existsSync(ADDONS));

// 10. BANZAI 0.6.0, read from the built code / configuration / media
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const buttons = src('ActionButtons.lua'); const plate = src('TargetPlate.lua'); const preview = src('Preview.lua');
  const roles = rsrc('Roles.lua'); const sync = rsrc('Sync.lua'); const options = rsrc('Options.lua'); const restore = rsrc('Restore.lua');
  const T = transformSource;
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  const tgaLib = require('./lib/tga');
  // shell: 1.1.0 replaced the 0.6.0 parallelograms, corner bundles and the minimap mask with the bamboo construction (checked in the 1.1.0 block)
  check('0.6.0 frames gone on purpose (1.1.0): no lean, no vertex offsets, no rotation, no corner bundles, no minimap mask in Banzai Art',
    !/Compat\.LEAN|SetVertexOffset|CornerBundle|MINIMAP_MASK|BanzaiMinimapMask|CORNER_INSET|BanzaiFrameBand/.test(strip0(compat)) && !/SetRotation\(/.test(strip0(compat)) && !/BanzaiMinimapMask|BanzaiFrameBand/.test(strip0(preview)));
  check('0.6.0 combat samurai art removed (Bushido combat mascots neither generated nor drawn)', !/BushidoCombatPengu|BushidoCombatNemesis|mascots/.test(geometryText.split('\n').slice(3).join('\n')) && !/mascot/i.test(strip0(compat)));
  check('0.6.0 logo: one small wordmark top centre; in combat 1.75x between Player and Target with the original tree, back after combat',
    /SetPoint\('TOP', UIParent, 'TOP', 0, self\.LOGO\.top\)/.test(compat) && num(compat, /scale = ([\d.]+), tree/) === 1.75 && /BONSAI/.test(compat) && /PLAYER_REGEN_DISABLED/.test(compat) && /function Compat:UpdateBranding/.test(compat) && /ElvUF_Target\.Health/.test(compat));
  const tree = tgaLib.read(path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiBonsai.tga'));
  const treeAlpha = (x, y) => tree.px[(y * tree.w + x) * 4 + 3];
  let green = 0; let purple = 0; let dark = 0;
  for (let i = 0; i < tree.w * tree.h; i++) {
    const [r, g, b, a] = [tree.px[i * 4], tree.px[i * 4 + 1], tree.px[i * 4 + 2], tree.px[i * 4 + 3]];
    if (a < 200) continue;
    if (g > r + 40 && g > b + 20) green++; else if (b > g + 60 && r > g + 30) purple++; else if (r + g + b < 200) dark++;
  }
  check('0.6.0 tree: transparent background, green foliage, small purple accent, dark trunk / pot', [treeAlpha(0, 0), treeAlpha(tree.w - 1, 0), treeAlpha(0, tree.h - 1), treeAlpha(tree.w - 1, tree.h - 1)].every((a) => a === 0) && green > 4000 && purple > 100 && purple < green / 5 && dark > 1500,
    `${tree.w}x${tree.h}, green ${green}, purple ${purple}, dark ${dark} px`);
  check('0.6.0 action bars: lowest row ACTION_GAP above the bottom panel, follows its height', num(T, /T\.ACTION_GAP = (\d+)/) >= 8 && /\(barHeight or T\.BAR_HEIGHT\) \+ T\.ACTION_GAP - base/.test(T) && /T\.ApplyActionMovers\(profile, P\.elvuiProfile, height/.test(restore));
  check('0.6.0 action bars: no black backdrop (ElvUI per-frame overrides, re-checked on updates), keybind 35 % smaller and centred',
    /button\.customBackdropAlpha = 0/.test(buttons) && /E:ForceBorderColor\(button, 0, 0, 0, 0\)/.test(buttons) && /if not combat then SetBackdropHidden\(button, true\) end/.test(buttons)
    && num(T, /hotkeyScale = ([\d.]+)/) === 1.3 && /db\.hotkeyTextPosition, db\.hotkeyTextXOffset, db\.hotkeyTextYOffset = 'CENTER', 0, 0/.test(T), `keybind x${num(T, /hotkeyScale = ([\d.]+)/)} (0.5.1: x2)`);
  // Details
  check('0.6.0 Details: titles 22 in the display font, red / green, accent lines; bars 5 (0.5.1: 12), text 13 (0.5.1: 11.5), outlined, centred',
    num(T, /titleSize = (\d+)/) >= 20 && /title\.text_face = fonts\.display/.test(T) && num(T, /rowHeight = (\d+)/) === Math.round(12 * 0.4) && num(T, /rowFontSize = (\d+)/) === Math.round(11.5 * 1.15)
    && /row\.text_yoffset = 0/.test(T) && /outline = 'OUTLINE'/.test(T) && /DETAILS_ACCENT/.test(compat));
  // nameplate
  check('0.6.0 targeted enemy nameplate: gradient over the fill, health + percent inside through ElvUI tags, names above enemy bars, arrows kept',
    /GetNamePlateForUnit\('target'\)/.test(plate) && /SetAllPoints\(fill\)/.test(plate) && /frame:Tag\(set\.value, ns\.Health\.VALUE_TAG\)/.test(plate) && !/UnitHealth/.test(strip0(plate))
    && /name\.parent, name\.position, name\.xOffset, name\.yOffset = 'Health', 'TOP', 0/.test(T) && /targetGlow = 'style7'/.test(T));
  // sync + roles
  check('0.6.0 Character Sync: master capture with revisions, apply with backup, update on request, restore, GUI buttons',
    ['function Sync:Capture', 'function Sync:SetMaster', 'function Sync:Apply', 'function Sync:Update', 'function Sync:RestoreCharacter', 'syncBackup'].every((k) => sync.includes(k))
    && ['APPLY BANZAI', 'UPDATE CHARACTER', 'RESTORE PRE-BANZAI', 'SET AS BANZAI MASTER', 'THIS CHARACTER'].every((k) => options.includes(k)) && /reuse = true/.test(sync));
  check('0.6.0 Character Sync: only mapped settings (Banzai settings, fonts, layout); no whole saved-variable copies', !/ElvDB\.profiles\[[^\]]+\]\s*=\s*T\.DeepCopy|_G\.ElvDB\s*=|ElvPrivateDB\s*=|KalielsTrackerDB\s*=|Details\.profiles\[[^\]]+\]\s*=/.test(strip0(sync)) && /settings = art and art\.Export/.test(sync));
  check('0.6.0 role layouts: spec role from the game, DPS / HEALER positions, deferred in combat, own positions kept per role, preview switch',
    /GetSpecializationInfo\(index\)/.test(roles) && /if InCombatLockdown\(\) then\s+self\.pending = role/.test(roles) && /overrides\[state\.active\]\[OverrideKey\(key, state\.context\)\] = now/.test(roles) && /function Preview:SetRole/.test(preview) && /HEALER = \{/.test(T));
  // approved pieces untouched
  const same = (rel) => { try { return execSync(`git show banzai-0.5.1:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n') === fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n'); } catch (e) { return false; } };
  check('0.6.0 approved pieces unchanged since 0.5.1: cast history (1.0.0 added the bottom panel\'s tooltips / clicks and the spec-only tag as asked: checked in the 1.0.0 block)', same('addons/BushidoPrivateCompat/CastHistory.lua'));
}

// 11. BANZAI 0.7.0, read from the built code / configuration / media
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const buttons = src('ActionButtons.lua'); const preview = src('Preview.lua'); const health = src('Health.lua');
  const identity = src('Identity.lua'); const tracker = src('Tracker.lua'); const theme = src('Theme.lua');
  const roles = rsrc('Roles.lua'); const sync = rsrc('Sync.lua'); const options = rsrc('Options.lua');
  const T = transformSource;
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  const SCREEN_W = 2560 / (0.71 * 1440 / 768);
  // 1-3 healer layout
  const hParty = (T.match(/HEALER = \{[\s\S]*?ElvUF_PartyMover = '([^']+)'/) || [])[1] || '';
  const hAllies = (T.match(/HEALER = \{[\s\S]*?ArenaAlliesMover = '([^']+)'/) || [])[1] || '';
  const hUnits = (T.match(/party = \{\s*growthDirection = '(\w+)', horizontalSpacing = (\d+), width = (\d+),/) || []);
  const [, point, , rel, x, y] = hParty.match(/^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$/) || [];
  const rowW = 5 * Number(hUnits[3]) + 4 * Number(hUnits[2]);
  const rowLeft = SCREEN_W / 2 + Number(x) - rowW / 2;
  check('0.7.0 HEALER party: one horizontal row (growth sideways), central, above Player / Target / bamboo / combat tree, on screen (1.0.0: lower, see the 1.0.0 block)',
    /^RIGHT_/.test(hUnits[1] || '') && point === 'BOTTOM' && rel === 'BOTTOM' && Math.abs(Number(x)) <= 40 && Number(y) - 16 > 422 && rowLeft > 0 && rowLeft + rowW < SCREEN_W && Number(hUnits[2]) >= 27 + 8,
    `${hParty}, ${hUnits[1]}, row ${rowW} wide from ${rowLeft.toFixed(0)}`);
  check('0.7.0 HEALER arena allies: their own position (ArenaAlliesMover), same horizontal row philosophy; the party mover takes it in an arena',
    /^BOTTOM,UIParent,BOTTOM,/.test(hAllies) && /T\.ARENA_ALLIES = 'ArenaAlliesMover'/.test(T) && /if context == 'arena' then out\.ElvUF_PartyMover = layout\[T\.ARENA_ALLIES\]/.test(T)
    && /kind == 'arena'/.test(roles) && /ZONE_CHANGED_NEW_AREA/.test(roles), hAllies);
  const dpsLayout = (T.match(/T\.ROLE_LAYOUTS = \{\s*DPS = \{([\s\S]*?)\n\t\},\n\tHEALER/) || [])[1] || '';
  check('0.7.0 DPS column kept (Bushido\'s growth and spacing; 0.9.0: on the left edge in line with the raid frames, 100 wide)',
    !/growthDirection|horizontalSpacing|verticalSpacing/.test(dpsLayout) && /ElvUF_PartyMover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,54,/.test(dpsLayout) && /out\[path\] = value/.test(T) && /T\.GetPath\(oldUnit, key\)/.test(T));
  check('0.7.0 role switching: arrangement written with the positions, ElvUI rebuilds the party header (out of combat), own changes kept per role and per frame kind',
    /CreateAndUpdateHeaderGroup, UF, 'party'/.test(roles) && /T\.ROLE_UNIT_KEYS = \{ 'growthDirection', 'horizontalSpacing', 'verticalSpacing', 'width',/.test(T) && /keep\(group\.unit \.\. '\.' \.\. key, T\.GetPath\(unit, key\)\)/.test(roles));
  // 4 bamboo only on Player / Target
  check('0.7.0 bamboo: unit-frame bundles only on Player and Target (Focus, ToT, Pet, Party, Raid, Arena, Boss clean); preview the same',
    /Compat\.END_ART = \{ ElvUF_Player = true, ElvUF_Target = true \}/.test(compat) && /Decorate\(_G\[def\.frame\], def\.parts, scale, nil, not self\.END_ART\[def\.frame\], self\.DESIGN_WIDTH\[def\.frame\]\)/.test(compat)
    && /G\.party, nil, nil, true\)/.test(compat) && /part\.texture == 'BushidoEndPoint' and bamboo and/.test(preview) && (preview.match(/bamboo = true/g) || []).length === 2);
  // 5 identity circles
  check('0.7.0 identity circles: Jiberish spec icon when the spec is reliably known (client, arena data, Jiberish lookup), class icon otherwise, none for NPCs',
    /GetArenaOpponentSpec/.test(identity) && /JI\.GetUnitSpecialization/.test(identity) && /GetSpecialization\)/.test(identity) && /Identity\.SPEC_STYLE = 'fabledspecializations'/.test(identity)
    && /Identity\.CLASS_STYLE = 'fabledclass'/.test(identity) && /UnitIsPlayer, unit\) == true/.test(identity) && /CLASS_ICON_TCOORDS/.test(identity) && !/random|guess\(/i.test(strip0(identity)));
  check('0.7.0 identity circles: small (27 vs 105), drawn for their pixels, Focus / Party / Arena / Boss; mMediaTag portraits off there only',
    num(identity, /Identity\.SIZE = (\d+)/) <= 105 / 3 && /'TRILINEAR'/.test(identity) && /SetSnapToPixelGrid\(true\)/.test(identity)
    && /T\.IDENTITY_UNITS = \{ 'focus', 'party', 'arena', 'boss' \}/.test(T) && /identityCircles = true/.test(theme));
  // 6 health text
  check('0.7.0 secondary health: value + percent inside Party / Arena / Boss bars (ghost over the empty part); raid percent only',
    /T\.HEALTH_INSIDE_UNITS = \{ 'player', 'target', 'focus', 'party', 'arena', 'boss' \}/.test(T) && /prefix = 'ElvUF_PartyGroup1UnitButton'/.test(health) && /prefix = 'ElvUF_Arena'/.test(health) && /prefix = 'ElvUF_Boss'/.test(health)
    && /T\.RAID_PERCENT = \{ format = '[^']*\[(perhp<%|health:percent)\][^']*'/.test(T) && !/RAID_PERCENT = \{[^}]*health:current/.test(T));
  // 7-10 Details
  const style = (T.match(/T\.DETAILS_STYLE = \{([\s\S]*?)\n\}/) || [])[1] || '';
  const rowOffset = num(style, /rowOffset = (-?\d+)/); const rowHeight = num(style, /rowHeight = (\d+)/); const rowFont = num(style, /rowFontSize = (\d+)/);
  const titleSize = num(compat, /Compat\.DETAILS_TITLE = \{ size = (\d+)/); const gap = num(compat, /Compat\.DETAILS_TITLE = \{[^}]*gap = (\d+)/); const accent = num(compat, /Compat\.DETAILS_TITLE = \{[^}]*accent = (\d+)/);
  const B = { outer: num(compat, /Compat\.BAND = \{[^}]*outer = ([0-9.]+)/), ring: num(compat, /Compat\.PANEL = \{[^}]*stalk = ([0-9.]+)/) }; // 1.1.0: the title line is the top stalk's axis (outer + stalk / 2); the stalk is at most 10
  const D = { frameHeight: num(compat, /frameHeight = ([0-9.]+)/), centerY: num(compat, /centerY = ([0-9.]+)/), height: num(compat, /Compat\.DETAILS = \{[^}]*height = (\d+)/) };
  const chassisTop = D.frameHeight / 2 + D.centerY - D.height; // above the windows' top edge
  const accentBottom = chassisTop - (B.outer + B.ring / 2) - titleSize * 0.78 / 2 - gap - accent;
  const rowTextTop = rowOffset - rowHeight / 2 + rowFont / 2 + 1;
  check('0.7.0 Details titles exactly DAMAGE / HEALING, DAMAGE left / HEALING right (clear of the bamboo), centred on the top border, red / green',
    /\[1\] = \{ text = 'DAMAGE'/.test(compat) && /\[2\] = \{ text = 'HEALING'/.test(compat) && /DetailsTitle\(frame, 1, 'LEFT'\), self:DetailsTitle\(frame, 2, 'RIGHT'\)/.test(compat)
    && /t:SetPoint\('LEFT', chassis, 'TOPLEFT', left, -line\)/.test(compat) && /- T\.bamboo \+ T\.pad/.test(compat) && /title\.enabled = false/.test(T));
  check('0.7.0 Details rows lower: no row text or bar reaches the titles\' accent lines', rowOffset <= -6 && accentBottom - rowTextTop >= 8, `accent bottom ${accentBottom.toFixed(1)}, row text top ${rowTextTop.toFixed(1)} (window top = 0)`);
  check('0.7.0 Details values without the percentage ("245K (6.1K)"), thin class-coloured bars, text centred on them',
    /format_tsp = '%s \(%s\)'/.test(style) && /format_ts = '%s \(%s\)'/.test(style) && /row\.textR_show_data = \{ true, true, false \}/.test(T) && rowHeight === 5 && /row\.texture_class_colors = true/.test(T)
    && /justifyV = 'middle'/.test(T) && /row\.texts = T\.DetailsRowTexts\(\)/.test(T));
  // 11 action buttons
  const rc = require('./ringcheck').run();
  const o = rc.versions['0.6.0']; const n = rc.versions['0.7.0'];
  check('0.7.0 action buttons: ring / mask drawn for Darren\'s 39.9 px buttons, one texel per screen pixel (64 px canvas, 128 px set for larger)',
    Math.abs(rc.canvasPx - 64) < 0.5 && /ActionButtons\.SETS = \{ \{ suffix = '', canvas = 64, design = 40 \}, \{ suffix = '128', canvas = 128, design = 80 \} \}/.test(buttons) && /w \* set\.canvas \/ set\.design/.test(buttons),
    `button ${rc.buttonPx.toFixed(2)} px, canvas ${rc.canvasPx.toFixed(2)} px`);
  check('0.7.0 action buttons: rendered edge matches the ideal circle (offline GPU sampling at Darren\'s setup)', n.rms < 0.006 && n.rms < o.rms / 4 && n.sd <= rc.ideal.sd + 0.01 && n.max < 0.05,
    `alpha error rms ${n.rms.toFixed(4)} (0.6.0: ${o.rms.toFixed(4)}), max ${n.max.toFixed(3)} (0.6.0: ${o.max.toFixed(3)}), edge sd ${n.sd.toFixed(3)} px (ideal ${rc.ideal.sd.toFixed(3)})`);
  check('0.7.0 action buttons: trilinear filtering, pixel-grid snapping, no square background, clicks / bindings / cooldowns / procs left to ElvUI',
    /'TRILINEAR'/.test(buttons) && /SetSnapToPixelGrid\(true\)/.test(buttons) && /button\.customBackdropAlpha = 0/.test(buttons) && /cd:SetSwipeTexture\(swipe or Theme\.WHITE\)/.test(buttons) /* 1.2.0: the swipe of the shape in use */
    && !/SetAttribute|:SetScript\('On(Click|MouseDown|MouseUp)|RegisterForClicks|EnableMouse\(false\)/.test(strip0(buttons)));
  // 12-16 objectives
  check('0.7.0 objectives: quest title, thin separator line, objectives, space; title larger / brighter, progress green, optional subdued',
    /Separator\(self, s\)/.test(tracker) && /sep:SetHeight\(1\)/.test(tracker) && /SIZES = \{ title = (\d+), objective = (\d+) \}/.test(tracker) && num(tracker, /SIZES = \{ title = (\d+)/) > num(tracker, /objective = (\d+) \}/)
    && /\(Optional\)', COLORS\.muted/.test(tracker) && /group = \d+/.test(tracker));
  check('0.7.0 objectives: bounded height (down to the Details frame / boss frames, MAX_HEIGHT at most), clipped scrolling with the mouse wheel, slim position bar, SHOW / HIDE kept',
    /CreateFrame\('ScrollFrame'/.test(tracker) && /SetClipsChildren\(true\)/.test(tracker) && /EnableMouseWheel\(f\.overflow > 0\)/.test(tracker) && /OnMouseWheel/.test(tracker)
    && /function Tracker:MaxHeight/.test(tracker) && /detailsFrame/.test(tracker) && /f\.thumb/.test(tracker) && /trackerCollapsed/.test(tracker));
  // 17 inventory
  const inv = (options.match(/Options\.REPLACEMENT = \{([\s\S]*?)\n\}/) || [])[1] || '';
  const folders = [...inv.matchAll(/\{ '([^']+)', '/g)].map((m) => m[1]);
  const keepInv = (inv.match(/KEEP = \{([\s\S]*?)\n\t\},/) || [])[1] || '';
  const missing = [...keepInv.matchAll(/\{ '([^']+)', '/g)].map((m) => m[1]).filter((folder) => !fs.existsSync(path.join(ADDONS, folder)));
  check('0.7.0 addon replacement status: read-only page under COMPONENTS (three sections, no uninstall button), every addon Banzai still uses really installed (the others shown live: Darren removes them)',
    /replacement = Tab\(2, 'ADDON REPLACEMENT STATUS'/.test(options) && ['BANZAI REPLACEMENT COMPLETE', 'BANZAI STILL USES', 'NOT REPLACED'].every((k) => options.includes(k)) && folders.length >= 15 && missing.length === 0
    && !/type = 'execute'|Button\(/.test(options.slice(options.indexOf('replacement = Tab('), options.indexOf('ownership = Tab('))), missing.length ? 'not installed: ' + missing.join(', ') : `${folders.length} entries`);
  // 18 sync
  check('0.7.0 Character Sync: role layouts (arena allies, party arrangement) and the identity circle choice inside the synced Banzai settings; gameplay data still never written',
    /out\.roles = Copy\(db\.roles\)/.test(theme) && /identityCircles = true/.test(theme) && /party \/ arena allies arrangement/.test(sync));
  // 20 approved pieces
  // 1.3.0: up to the last release before the split style (banzai-1.2.1); 1.3.0's own changes are checked in its block
  const same = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n') === execSync(`git show banzai-1.2.1:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return false; } };
  const block = (rel, tag, re) => { try { const a = (execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).match(re) || [])[0]; const b = (fs.readFileSync(path.join(ROOT, rel), 'utf8').match(re) || [])[0]; return Boolean(a) && a === b; } catch (e) { return false; } };
  const C = 'addons/BushidoPrivateCompat/Compat.lua'; const TR = 'addons/BushidoPrivateRestore/Transform.lua';
  check('0.7.0 approved pieces unchanged since 0.6.0: cast history, target nameplate; Player / Target text and anchors; frames, logo, combat tree, minimap, chat (1.0.0 changed the bottom panel, the tags and the end-art anchoring as asked: checked in the 1.0.0 block)',
    ['CastHistory.lua', 'TargetPlate.lua'].every((f0) => same('addons/BushidoPrivateCompat/' + f0, 'banzai-0.6.0'))
    && block(TR, 'banzai-0.6.0', /T\.IDENTITY = \{[\s\S]*?\n\}/) && block(TR, 'banzai-0.6.0', /\tplayer = \{ value[^\n]*\n\ttarget = \{ value[^\n]*/) && block(TR, 'banzai-0.6.0', /T\.CLASS_ICON = '[^']+'/)
    && block(C, 'banzai-0.6.0', /Compat\.COMBAT = \{[^}]*\}/)
    && block(C, 'banzai-0.6.0', /function Compat:BuildCombatLogo[\s\S]*?\nend/)); // 1.1.0 replaced Compat.LEAN and BuildMinimap, 1.2.0 moved Compat.CHAT flush-left (checked in their blocks)
}

// 12. BANZAI 0.8.0: unit frames + PvP, read from the built code / configuration
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const preview = src('Preview.lua'); const health = src('Health.lua'); const theme = src('Theme.lua');
  const roles = rsrc('Roles.lua'); const sync = rsrc('Sync.lua'); const options = rsrc('Options.lua'); const restore = rsrc('Restore.lua');
  const T = transformSource;
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const same = (rel, tag) => git(rel, tag) === git(rel, 'banzai-1.2.1'); // 1.3.0: the history up to the release before the split style
  const files = (text) => text.split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
  // load order
  const tocSame = ['BushidoPrivateRestore', 'BushidoPrivateCompat'].every((a) => {
    const rel = `addons/${a}/${a}.toc`; const old = git(rel, 'banzai-0.7.0');
    return old !== null && files(old).join('|') === files(fs.readFileSync(path.join(ROOT, rel), 'utf8')).join('|');
  });
  const compatOld = files(git('addons/BushidoPrivateCompat/BushidoPrivateCompat.toc', 'banzai-0.8.0') || '');
  check('load order: Restore unchanged since 0.7.0, Compat keeps the 0.8.0 order (0.9.0 adds PvPFrames after Identity, CooldownBars after ActionButtons); 1.0.1: no sArena in the OptionalDeps',
    ['BushidoPrivateRestore'].every((a) => { const rel = `addons/${a}/${a}.toc`; const old = git(rel, 'banzai-0.7.0'); return old !== null && files(old).join('|') === files(fs.readFileSync(path.join(ROOT, rel), 'utf8')).join('|'); })
    && compatToc.list.filter((x) => !['PvPFrames.lua', 'CooldownBars.lua', 'Tooltip.lua', 'Info.lua', 'AFK.lua', 'IdentityManifest.lua', 'Split.lua', 'CastBar.lua'].includes(x)).join('|') === compatOld.join('|') && !/sArena/.test(restoreToc.fields.OptionalDeps || ''));
  // 1 chat title
  const titles = (compat.match(/Compat\.DETAILS_TITLES = \{([\s\S]*?)\n\}/) || [])[1] || '';
  const bright = (name) => ((titles.match(new RegExp("text = '" + name + "', bright = \\{ ([^}]+) \\}")) || [])[1] || '').replace(/\s/g, '');
  const chatT = compat.match(/Compat\.CHAT_TITLE = \{ text = 'CHAT', bright = \{ ([^}]+) \}, deep = \{ ([^}]+) \} \}/) || [];
  const rgb = (txt) => (txt || '').split(',').map(Number);
  const sum = (c) => c.reduce((a, b) => a + b, 0);
  const [cb, cd, hb, db] = [rgb(chatT[1]), rgb(chatT[2]), rgb(bright('HEALING')), rgb(bright('DAMAGE'))];
  check('0.8.0 / 0.9.0 CHAT title: same title piece as DAMAGE / HEALING (font, size, weight, backing), centred on the chat frame\'s top border; 0.9.0: a darker green -> red, quieter than HEALING / DAMAGE',
    chatT.length === 3 && cb[1] > cb[0] && cb[1] > cb[2] && cd[0] > cd[1] && cd[0] > cd[2] && sum(cb) < sum(hb) && sum(cd) < sum(db)
    && /local title = self:DetailsTitle\(frame, 0, 'CENTER'\)\s+title\.fixedStyle = self\.CHAT_TITLE/.test(compat) && /t\.side == 'CENTER' then -- the middle/.test(compat)
    && /self:LayoutDetailsTitle\(self\.chatTitle\)/.test(compat), `CHAT ${chatT[1]} -> ${chatT[2]}`);
  // 2 names above the bars
  check('0.8.0 names / spec above fill, track, gradients, absorbs, range fade: ElvUI keeps them on its raised layer (100), Banzai\'s inside text capped below it; the preview draws them on a text layer',
    /holder:SetFrameLevel\(math\.min\(\(bar:GetFrameLevel\(\) or 10\) \+ 3, 90\)\)/.test(health) && /u\.textLayer:SetFrameLevel\(health:GetFrameLevel\(\) \+ 8\)/.test(preview)
    && /local name = Text\(u\.textLayer/.test(preview) && /\[banzai:spec:after\]/.test(T) && /\[banzai:spec:before\]/.test(T));
  // 4/5 preview states
  const states = ((preview.match(/Preview\.STATES = \{([^}]*)\}/) || [])[1] || '').match(/'(\w+)'/g) || [];
  check('0.8.0 / 0.9.0 preview: 14 synthetic states (ALLY / ENEMY CC\'D, DISPELLABLE, OFFENSIVE / DEFENSIVE ACTIVE, TRINKET AVAILABLE / USED / UNKNOWN ...; no DR) on every sample frame, named in every title with SAMPLE DATA, kept with the Banzai settings, target / focus / both markers',
    states.length === 16 /* 1.3.0: + CHANNELING; 1.3.3: + INTERRUPTED (split samples) */ && states.includes("'CHANNELING'") && states.includes("'INTERRUPTED'") && ['NORMAL', 'LOW_HEALTH', 'OUT_OF_RANGE', 'DEAD', 'CASTING', 'CAST_LOCKED', 'CC_ALLY', 'CC_ENEMY', 'DISPELLABLE', 'OFFENSIVE', 'DEFENSIVE', 'TRINKET_READY', 'TRINKET_USED', 'TRINKET_UNKNOWN'].every((k) => states.includes("'" + k + "'"))
    && /PREVIEW: '\s*\.\. Preview\.STATE_LABELS\[self:State\(\)\] \.\. '  -  SAMPLE DATA/.test(preview) && /previewState = 'NORMAL'/.test(theme)
    && /targetMark:SetShown\(i == 1 or i == 3\)/.test(preview) && /focusMark:SetShown\(i == 2 or i == 3\)/.test(preview), states.length + ' states');
  check('0.8.0 / 0.9.0 preview honest: no countdowns drawn; party and arena allies (the same frames in the game) never on top of each other - shown together, the allies sit above the party and say so',
    !/'\d+:\d\d'/.test(strip0(preview)) && /function Preview:Stack\(\)/.test(preview) && /SHOWN ABOVE PARTY \(SAME PLACE IN THE GAME\)/.test(preview));
  // 3/14-18 legitimate data only
  // 1.3.0: Split.lua reads the game's cast data for the split hubs (asked for; checked in the 1.3.0 block) - aura and combat-log data stay forbidden there too
  const banzaiLua = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(DIST, a)).filter((x) => x.endsWith('.lua') && x !== 'Payloads.lua').map((x) => { const code = strip0(fs.readFileSync(path.join(DIST, a, x), 'utf8')); return x === 'Split.lua' ? code.replace(/UnitCastingInfo|UnitChannelInfo/g, 'CAST_READ') : code; }));
  const byName = (name) => strip0(fs.readFileSync(path.join(DIST, name.startsWith('Restore/') ? 'BushidoPrivateRestore' : 'BushidoPrivateCompat', name.replace(/^\w+\//, '')), 'utf8'));
  const forbidden = /UnitAura\b|C_UnitAuras|GetAuraDataBy|GetArenaCrowdControlInfo|CombatLogGetCurrentEventInfo|COMBAT_LOG_EVENT|UnitCastingInfo|UnitChannelInfo/;
  const pvpCode = byName('PvPFrames.lua'); const barsCode = byName('CooldownBars.lua');
  check('0.8.0 / 0.9.0 PvP through ElvUI\'s own elements and the game\'s own categories: no aura, cast or combat-log reading anywhere; the game\'s arena trinket data only handed to a Cooldown widget (trinket circles), the player\'s own cooldown state only in the cooldown bars',
    banzaiLua.every((code) => !forbidden.test(code)) && /'HARMFUL\|\|CROWD_CONTROL'/.test(T) && /function T\.ApplyPvP/.test(T) && /T\.ApplyPvP\(p, opts, historical\)/.test(T)
    && (pvpCode.match(/C_PvP\.\w+/g) || []).every((x) => x === 'C_PvP.GetArenaCrowdControlDuration') && /SetCooldownFromDurationObject\(data\)/.test(pvpCode)
    && (barsCode.match(/info\.\w+/g) || []).every((x) => x === 'info.isActive' || x === 'info.isOnGCD') && !/startTime|\.duration\s*[-+*\/<>]/.test(barsCode));
  check('0.8.0 casts: interruptible attention amber, not interruptible restrained steel violet (ElvUI cast colours); Player / Target keep their own cast-bar colours',
    /castColor = \{ r = 1\.00, g = 0\.70, b = 0\.00 \}/.test(T) && /castNoInterrupt = \{ r = 0\.46, g = 0\.44, b = 0\.56 \}/.test(T) && /Preview\.CAST = \{ open = \{ 1\.00, 0\.70, 0\.00 \}, locked = \{ 0\.46, 0\.44, 0\.56 \} \}/.test(preview));
  const dpsCC = num(T, /DPS = \{[\s\S]*?\['auras\.sizeOverride'\] = (\d+)/);
  check('0.8.0 / 0.9.0 friendly CC highly noticeable (one large icon inside the bar\'s right end, its size per role), dispel as ElvUI\'s border glow; enemy CC smaller',
    /partyCC = \{ enable = true, filter = 'HARMFUL', attachTo = 'HEALTH', anchorPoint = 'RIGHT'/.test(T) && dpsCC >= 28
    && /uf\.debuffHighlighting = \(opts\.pvpDispelGlow ~= false\) and 'GLOW'/.test(T) && num(T, /arenaDebuffs = \{[^}]*sizeOverride = (\d+)/) < dpsCC, `DPS CC ${dpsCC}`);
  // 25 sArena
  check('0.8.0 arena enemies (1.0.1): one live system - ElvUI\'s arena enemy frames in the Banzai design, always on; no sArena detection, and sArena\'s data never read',
    /arena\.enable = true -- 1\.0\.1/.test(T) && !/arenaAddons|arenaOwner/.test(strip0(T)) && !/ArenaOwner|arenaOwner/.test(strip0(restore))
    && banzaiLua.every((code) => !/sArena_ReloadedDB|sArenaDB/.test(code)));
  // 6-9 friendly placement per role
  // 9 raid / 19-22 focus, ToT, pet, boss
  check('0.8.0 raid compact (small role icon, one raid debuff, percent, Dead / Ghost / Offline via oUF [status], no circles; only Retail-registered tags); focus / boss cast bars that render (boss: own bar above each frame); ToT percent, ToT / pet without portraits',
    /raidRole = \{ enable = true[^}]*size = 10 \}/.test(T) && /raidDebuffs = \{ enable = true, attachTo = 'HEALTH'/.test(T) && /\[perhp<%\]/.test((T.match(/T\.RAID_PERCENT = \{[^}]*\}/) || [''])[0])
    && /status = \{ format = '[^']*\[status\]/.test(T) && !/\[health:/.test(strip0(T)) && !/'rdebuffs'/.test(T)
    && /castAbove = \{ enable = true, overlayOnFrame = 'None'/.test(T) && /boss\.spacing = P\.castSpacing/.test(T)
    && /Ensure\(units, 'focus', 'castbar'\)\.enable = true/.test(T) && /Fill\(Ensure\(boss, 'castbar'\), P\.castAbove\)/.test(T) && /minorPortraits = \{ 'targettarget', 'pet' \}/.test(T)
    && /T\.IDENTITY_UNITS = \{ 'focus', 'party', 'arena', 'boss' \}/.test(T));
  // 26 PVP page
  const pvpPage = options.slice(options.indexOf('function Options.PvPGroup'), options.indexOf('function Options:Build'));
  const controls = (pvpPage.match(/PvPToggle\(\d|ArtSetting\(\d|type = 'select'|type = 'multiselect'|Tracked\(\d/g) || []).length;
  check('0.9.0 BANZAI -> PVP: PARTY / ARENA FRAME SIZE, ROLE ICON, TRINKET, CC, DISPELLABLE STATE, OFFENSIVE / DEFENSIVE COOLDOWN BARS, PREVIEW (state selector, NEXT STATE, PARTY + ARENA, COOLDOWN BARS, HIDE ALL); no wall of controls',
    ['PARTY / ARENA FRAME SIZE', 'ROLE ICON', "'TRINKET'", "'CC'", 'DISPELLABLE STATE', 'OFFENSIVE COOLDOWN BARS', 'DEFENSIVE COOLDOWN BARS', "'PREVIEW'", 'NEXT STATE', 'PARTY + ARENA', "'COOLDOWN BARS'", 'HIDE ALL'].every((k) => pvpPage.includes(k))
    && controls <= 20 && /pvp = Options\.PvPGroup\(\)/.test(options) && /previewState = Options\.PreviewState\(/.test(options), `${controls} controls`);
  check('1.0.1 addon replacement status: sArena Reloaded no longer required by Banzai (under BANZAI REPLACEMENT COMPLETE, not under BANZAI STILL USES); removing it is left to Darren',
    /REPLACED = \{[\s\S]*?'sArena_Reloaded', 'sArena Reloaded'[^\n]*no longer required by Banzai[^\n]*Banzai deletes nothing[\s\S]*?KEEP = \{/.test(options)
    && !/KEEP = \{[\s\S]*?'sArena_Reloaded'[\s\S]*?UNRELATED/.test(options));
  // 23/24 sync
  check('0.8.0 Character Sync: PvP choices and preview preferences inside the synced Banzai settings, aura placement inside the role layouts; gameplay data still never written (1.0.1: the tracked cooldowns stay with each character)',
    ['pvpCastColors = true', 'pvpDispelGlow = true', 'pvpDefensives = true', "previewState = 'NORMAL'"].every((k) => theme.includes(k)) && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme)
    && /PvP choices/.test(sync) && /preview preferences/.test(sync) && /Sync\.CHARACTER_OWN = \{ 'cdTracked' \}/.test(sync) && /except the tracked cooldowns/.test(sync) && /sizes of party, arena allies and arena enemies/.test(sync)
    && ['roleIcons = true', 'trinketCircles = true', "ccEmphasis = 'STRONG'", "dispelEmphasis = 'STRONG'", 'cdBars = true', 'cdTracked = false', 'cdSpread = ', 'cdHeight = '].every((k) => theme.includes(k)));
  // approved pieces
  check('approved pieces unchanged since 0.8.0: cast history, target nameplate (1.0.0: bottom panel, tags and action buttons changed as asked, checked in the 1.0.0 block)',
    ['CastHistory.lua', 'TargetPlate.lua'].every((f0) => same('addons/BushidoPrivateCompat/' + f0, 'banzai-0.8.0')));
}

// 13. BANZAI 0.9.0: PvP unit frames + the player's cooldown bars, read from the built code / configuration
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const preview = src('Preview.lua'); const health = src('Health.lua'); const identity = src('Identity.lua');
  const pvp = src('PvPFrames.lua'); const bars = src('CooldownBars.lua'); const tracker = src('Tracker.lua'); const theme = src('Theme.lua');
  const restore = rsrc('Restore.lua'); const options = rsrc('Options.lua'); const roles = rsrc('Roles.lua');
  const T = transformSource;
  const banzaiLua = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(DIST, a)).filter((x) => x.endsWith('.lua') && x !== 'Payloads.lua').map((x) => strip0(fs.readFileSync(path.join(DIST, a, x), 'utf8'))));
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  const mover = (layout, name) => ((layout.match(new RegExp(name + " = '([^']+)'")) || [])[1] || '').split(',');
  const dps = (T.match(/T\.ROLE_LAYOUTS = \{\s*DPS = \{([\s\S]*?)\n\t\},\n\tHEALER/) || [])[1] || '';
  const healer = (T.match(/\n\tHEALER = \{([\s\S]*?)\n\t\},\n\}/) || [])[1] || '';
  const payloadText = fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', 'Payloads.lua'), 'utf8');
  const raidX = Number(((payloadText.match(/ElvUF_Raid1Mover = "([^"]+)"/) || [])[1] || '').split(',')[3]);
  const partyX = Number(mover(dps, 'ElvUF_PartyMover')[3]);
  const circle = num(identity, /Identity\.SIZE = (\d+)/); const gap = num(identity, /Identity\.GAP = (\d+)/);
  check('0.9.0 DPS party / arena allies on the left edge: their identity circles start where the raid frames start; party and arena allies one placement system',
    partyX - circle - gap === raidX && mover(dps, 'ArenaAlliesMover').join(',') === mover(dps, 'ElvUF_PartyMover').join(',')
    && /out\[T\.ARENA_ALLIES\] = own\[T\.ARENA_ALLIES\] or own\.ElvUF_PartyMover or defaults\[T\.ARENA_ALLIES\]/.test(T), `party x ${partyX}, raid x ${raidX}`);
  const dpsW = num(dps, /party = \{[^}]*width = (\d+)/); const hW = num(healer, /party = \{[^}]*width = (\d+)/); const hH = num(healer, /party = \{[^}]*height = (\d+)/);
  check('0.9.0 party frames: DPS 50 % narrower at Bushido\'s height (200 -> 100 x 39), HEALER the DPS width and 30 % lower (39 -> 27), central row with room for both circles',
    dpsW === 100 && !/party = \{[^}]*height/.test(dps) && hW === dpsW && hH === Math.floor(39 * 0.7) && /growthDirection = 'RIGHT_DOWN'/.test(healer)
    && num(healer, /horizontalSpacing = (\d+)/) >= 2 * (circle + gap) && mover(healer, 'ElvUF_PartyMover').join(',') === 'BOTTOM,UIParent,BOTTOM,0,454', `DPS ${dpsW}, HEALER ${hW} x ${hH} (1.0.0: the row at 454)`);
  check('0.9.0 party frame structure: CLASS / SPEC CIRCLE | HEALTH BAR (HP + % from the left, [mMT-role:icon] at the right end) | TRINKET CIRCLE',
    /roleText = \{ format = '\[mMT-role:icon\]', spec = \{ 'RIGHT'/.test(T) && /prefix = 'ElvUF_PartyGroup1UnitButton', count = 5, side = 'LEFT', x = 4/.test(health)
    && /\{ prefix = 'ElvUF_PartyGroup1UnitButton', count = 5, side = 'RIGHT', kind = 'friendly' \}/.test(pvp) && /c:SetPoint\('LEFT', health, 'RIGHT', gap, 0\)/.test(pvp));
  check('0.9.0 party auras: no ordinary buffs, debuff rows or DR; the one debuff is an effect this character can dispel (RAID_PLAYER_DISPELLABLE), compact, clear of HP and name',
    /Ensure\(units, 'party', 'buffs'\)\.enable = false/.test(T) && /partyDispelList = \{ 'HARMFUL\|\|RAID_PLAYER_DISPELLABLE' \}/.test(T) && /partyDispel = \{[^}]*perrow = 1, numrows = 1/.test(T)
    && /function T\.SetFilterGroups/.test(T) && !/DR = \{|u\.dr\b/.test(strip0(preview)));
  check('0.9.0 arena enemies mirrored on the right edge at the allies\' level, the allies\' size: TRINKET | HEALTH BAR | CLASS / SPEC CIRCLE; ElvUI\'s own trinket element off',
    mover(dps, 'ArenaHeaderMover').join(',') === 'BOTTOMRIGHT,UIParent,BOTTOMRIGHT,-54,362' && mover(healer, 'ArenaHeaderMover')[4] === '454'
    && /arena = \{ width = 100, height = 39 \}/.test(dps) && /arena = \{ width = 100, height = 27 \}/.test(healer)
    && /\{ prefix = 'ElvUF_Arena', count = 5, unit = 'arena', side = 'RIGHT', arena = true \}/.test(identity) && /\{ prefix = 'ElvUF_Arena', count = 5, unit = 'arena', side = 'LEFT', kind = 'enemy' \}/.test(pvp)
    && /Ensure\(arena, 'pvpTrinket'\)\.enable = false/.test(T) && /arenaDebuffList = \{ 'HARMFUL\|\|CROWD_CONTROL' \}/.test(T));
  check('1.0.1 the 0.9.0 arena-system choice removed: no SARENA / BANZAI selector, no SetArenaSystem, no addon switched on / off anywhere (apply, restore), no DR section; a 0.9.0 choice left in the saved data is forgotten at login',
    banzaiLua.every((code) => !/C_AddOns\.(Enable|Disable)AddOn|SetArenaSystem|ArenaSystem\(|ArenaAddonState/.test(code))
    && !/SARENA/.test(strip0(options)) && !/\bdr = Section\(|PVP_TEXT\.dr/.test(strip0(options))
    && /record\.arenaSystem = nil/.test(strip0(restore)) && /arenaAddonState = nil/.test(strip0(restore))
    && /The only arena enemy system; DR is not a Banzai feature/.test(options));
  check('0.9.0 trinket: a circle the size of the identity circle, the game\'s own arena data handed unread to a Cooldown widget; AVAILABLE / USED / UNKNOWN, no timer',
    /function PvP\.Trinket\(parent, size\)/.test(pvp) && /c\.cd:SetCooldownFromDurationObject\(data\)/.test(pvp) && /SetHideCountdownNumbers\(true\)/.test(pvp)
    && /'READY'/.test(pvp) && /'USED'/.test(pvp) && /'UNKNOWN'/.test(pvp) && /P\.Trinket\(u, circle\)/.test(preview) && /InArena\(\)/.test(pvp));
  const pvp133 = (() => { try { return execSync('git show banzai-1.3.3:addons/BushidoPrivateCompat/PvPFrames.lua', { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return ''; } })();
  check('0.9.0 CC must scream / dispel stays disciplined: border, bold label and restrained pulse as parts of ElvUI\'s own aura icons (nothing hooked, nothing read); magenta CC never a health colour; STRONG / CLEAR / MINIMAL (1.3.4: retired on the live frames - the design checked as released up to banzai-1.3.3; its levels still shape the preview samples)',
    /function PvP\.Decorate\(button\)/.test(pvp133) && /element\.buttons/.test(strip0(pvp133)) && /'UNIT_AURA'/.test(pvp133) && /SetLooping\('BOUNCE'\)/.test(pvp133) && /function PvP\.Decorate\(\) return nil end/.test(pvp)
    && /function PvP\.Decorate\(button\)/.test(pvp133) && /element\.buttons/.test(strip0(pvp133)) && !/hooksecurefunc/.test(strip0(pvp)) && /cc = \{ 1\.00, 0\.18, 0\.62 \}/.test(pvp)
    && /STRONG = \{ border = 3, label = true, pulse = true \}/.test(pvp) && /MINIMAL = \{\}/.test(pvp));
  // cooldown bars: between chat and the action bars / the action bars and Details, never overlapping them
  const spread = num(theme, /cdSpread = (\d+)/); const height = num(theme, /cdHeight = (\d+)/);
  const barW = num(bars, /CB\.BAR = \{ w = (\d+)/); const maxScale = 1.2;
  const SCREEN = 2560 / (0.71 * 1440 / 768);
  const fw = num(compat, /frameWidth = ([0-9.]+)/);
  const chatRight = num(compat, /Compat\.CHAT = \{[^}]*left = (-?[0-9.]+)/) + fw; // the chat frame's right edge (its left edge + its width)
  const detailsLeft = SCREEN - (num(compat, /edge = (\d+)/) - num(compat, /Compat\.BAND = \{[^}]*outer = ([0-9.]+)/) + fw); // 1.2.0: Details has its own place (the chat moved flush-left)
  const ab = 12 * 30 + 11 * 6; // ElvUI bars 1 / 6: 12 buttons of 30, 6 apart
  const half = (barW * maxScale) / 2;
  const groupL = SCREEN / 2 - spread - half, groupR = SCREEN / 2 - spread + half;
  check('0.9.0 cooldown bars: OFFENSIVE between the chat and the action bars, DEFENSIVE mirrored between the action bars and Details, above the bottom panel, bounded (5 bars, scale up to 1.2)',
    groupL > chatRight && groupR < SCREEN / 2 - ab / 2 && SCREEN - groupL < detailsLeft && SCREEN - groupR > SCREEN / 2 + ab / 2 && height > 40 && /CB\.MAX = 5/.test(bars),
    `group ${groupL.toFixed(0)}..${groupR.toFixed(0)}, chat right ${chatRight.toFixed(0)}, action bars from ${(SCREEN / 2 - ab / 2).toFixed(0)}`);
  check('0.9.0 cooldown bars honest: the player\'s own known spells only, shown while isActive and not isOnGCD (nothing when secret), the game\'s duration on the bar, no empty groups, no history',
    /function CB\.Known/.test(bars) && /active == true and gcd ~= true/.test(bars) && /if active == nil then return nil end/.test(bars) && /SetTimerDuration\(bar\.duration/.test(bars)
    && /g:SetShown\(shown > 0\)/.test(bars) && /SAMPLE DATA/.test(bars));
  check('0.9.0 tracker stays above arena enemy frames on the right edge (as above boss frames)', /'ElvUF_Arena' \.\. i/.test(tracker) && /Tracker\.RIGHT_FRAMES/.test(tracker));
  check('0.9.0 role layouts carry the arena enemy size; ElvUI rebuilds the arena frames on a switch; Banzai\'s own DPS places are never seeded as hand moves',
    /T\.ROLE_UNITS = \{ \{ unit = 'party', keys = T\.ROLE_UNIT_KEYS \}, \{ unit = 'arena', keys = T\.ROLE_ARENA_KEYS \} \}/.test(T) && /CreateAndUpdateUFGroup, UF, 'arena', 5/.test(roles)
    && /now ~= banzai\[name\]/.test(roles));
}

// 14. BANZAI 1.0.0: half-width unit frames, the settings app, AFK screen, tooltips, read from the built code / configuration
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const theme = src('Theme.lua'); const tooltip = src('Tooltip.lua'); const info = src('Info.lua'); const afk = src('AFK.lua');
  const bar = src('Bar.lua'); const tracker = src('Tracker.lua'); const preview = src('Preview.lua'); const tags = src('Tags.lua'); const health = src('Health.lua');
  const options = rsrc('Options.lua'); const restore = rsrc('Restore.lua'); const sync = rsrc('Sync.lua');
  const T = transformSource;
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const same = (rel, tag) => git(rel, tag) === fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');
  const payloadText = fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', 'Payloads.lua'), 'utf8');
  const pmover = (name) => ((payloadText.match(new RegExp(name + ' = "([^"]+)"')) || [])[1] || '').split(',');
  // A. unit frames
  check('1.0.0 Player / Target / Focus / ToT: half Bushido\'s width by default (0.5 .. 1), heights kept, nothing scaled; written per character before ElvUI builds',
    /T\.FRAME_WIDTH = 0\.5/.test(T) && /return math\.max\(0\.5, math\.min\(1, value\)\)/.test(T) && /db\.width = Round\(full \* width\)/.test(T) && !/height = Round\(full/.test(T)
    && /T\.ApplyFrameWidths\(p, historical, opts, fonts\.small\)/.test(T) && /frameWidth = 0\.5/.test(theme) && /frameWidth = T\.FrameWidth\(CompatSetting\('frameWidth'/.test(restore));
  const playerX = Number(pmover('ElvUF_PlayerMover')[3]); const focusY = Number(pmover('ElvUF_FocusMover')[4]);
  check('1.0.0 inner ends kept: Player / Target movers move by the cut toward the centre (bamboo, combat tree, cast history stay), Focus left-aligned with the Player, power / class / mana bars the same',
    /\{ name = 'ElvUF_PlayerMover', unit = 'player', side = 1, layout = true \}/.test(T) && /\{ name = 'ElvUF_TargetMover', unit = 'target', side = -1, layout = true \}/.test(T)
    && /\{ name = 'ElvUF_FocusMover', unit = 'player', side = 1, layout = true \}/.test(T) && /'ClassBarMover'/.test(T) && /'AdditionalPowerMover'/.test(T)
    && /T\.ShiftMover\(base, m\.side \* \(cuts\[m\.unit\] \+ \(m\.layout and spread or 0\)\), m\.layout and height or 0\)/.test(T) && playerX === 411,
    `Player ${playerX} + 302 = inner end ${playerX + 302}; half width moves it to ${playerX + 151}`);
  check('1.0.0 reflow: name and spec on two lines on narrow frames ([banzai:spec], spec choice kept), health text closer to the class circle, buffs per row, ToT narrowed under the Target\'s inner end and lowered below its spec line',
    /\[banzai:spec\]/.test(T) && /E:AddTag\('banzai:spec', events/.test(tags) && /T\.ApplyIdentityLines\(p, width < 1, font\)/.test(T) && /narrowX = 14/.test(health) && /narrowX = -14/.test(health)
    && /Ensure\(player, 'buffs'\)\.perrow = math\.max\(1, math\.floor\(perrow \* width\)\)/.test(T) && /T\.TOT_DROP = 14/.test(T) && /T\.ShiftMover\(T\.TOT\.mover, dx, dy\)/.test(T)
    // review fixes: the spec / health-size choices survive an upgrade; health under the narrow bars reflows (value from the inner end), ToT clear of it
    && /local choices = T\.TextChoices\(profile\)[\s\S]*?T\.RestoreTextChoices\(profile, choices\)/.test(restore) && /spec\.value\[2\] \+ \(\(spec\.value\[1\] == 'RIGHT'\) and cut or -cut\)/.test(T)
    && /T\.TOT_OUTSIDE_DROP = 30/.test(T) && /afk = _G\.BanzaiCompat ~= nil and CompatSetting\('afk', true\) ~= false/.test(restore));
  check('1.0.0 art reflow: plates and bamboo anchored to their own frame end at Bushido\'s design widths (live frames and the preview)',
    /Compat\.DESIGN_WIDTH = \{ ElvUF_Player = 302, ElvUF_Target = 302, ElvUF_Focus = 210, ElvUF_TargetTarget = 210, ElvUF_Pet = 210 \}/.test(compat)
    && /region:SetPoint\('CENTER', parent, 'RIGHT', part\.x \* scale - half/.test(compat) && /region:SetPoint\('LEFT', parent, 'LEFT'/.test(compat) && /ns\.Compat\.PlacePart/.test(preview));
  const healerY = num(T, /T\.HEALER_ROW = (\d+)/);
  const focusTop = focusY + 35;
  check('1.0.0 HEALER row just above the Player / Target region: its dispel icons (16 below) clear the Focus frame\'s top by a clean gap, the combat tree (422) and bamboo (394) by more; arena allies the same row, their own saved place',
    healerY - 16 - focusTop >= 6 && healerY - 16 - focusTop <= 10 && healerY - 16 > 422 && /ElvUF_PartyMover = 'BOTTOM,UIParent,BOTTOM,0,454'/.test(T) && /ArenaAlliesMover = 'BOTTOM,UIParent,BOTTOM,0,454'/.test(T)
    && /ElvUF_Raid1Mover = 'BOTTOMLEFT,UIParent,BOTTOMLEFT,560,454'/.test(T) && /T\.ARENA_ALLIES = 'ArenaAlliesMover'/.test(T),
    `row ${healerY}, focus top ${focusTop}, gap ${healerY - 16 - focusTop}`);
  // B. settings app
  const pages = ((options.match(/Options\.PAGES = \{([\s\S]*?)\n\}/) || [])[1] || '').match(/\{ '(\w+)', '([^']+)' \}/g) || [];
  check('1.0.0 settings: one BANZAI application - logo, UI BY HARDKORH and the version above a persistent page list (AceConfig tree), the twelve pages in order',
    pages.map((p0) => p0.match(/'([^']+)' \}/)[1]).join('|') === 'HOME|APPEARANCE|UNIT FRAMES|PVP|ACTION BARS|LAYOUT|CHARACTER SYNC|COMPONENTS|TOOLTIPS|AFK SCREEN|BACKUP & RESTORE|ABOUT'
    && /childGroups = 'tree'/.test(options) && /MEDIA \.\. 'BanzaiLogo', 256, 64/.test(options) && /Gradient\('BANZAI ' \.\. version/.test(options) && /UI BY HARDKORH/.test(options), pages.length + ' pages');
  check('1.0.0 settings: standard controls (one width), green / purple identity, amber / red only for warnings, one scroll per page (no tab group inside a section)',
    /local WIDTH = 1\.15/.test(options) && !/inline = true, name = Title\([^)]*\), childGroups/.test(options) && !/Section\(\d+, '[^']+', \{[^}]*childGroups/.test(options));
  check('1.0.0 version shown in the GUI, HOME, the AFK screen, ABOUT and /banzai status; a private milestone (no release wording)',
    /Gradient\('BANZAI ' \.\. version/.test(options) && /Header\(1, 'BANZAI ' \.\. version\)/.test(options) && /BANZAI ' \.\. tostring\(Theme\.VERSION\)/.test(afk)
    && /Retail release\./.test(options) && /Print\(NAME \.\. ' ' \.\. VERSION \.\. ' \(release;/.test(restore));
  // logo click
  check('1.0.0 BANZAI wordmark: left click opens ElvUI options at BANZAI > HOME through ElvUI\'s own ToggleOptions / AceConfigDialog (an open window reused), never in combat (a message, nothing queued), the combat wordmark never clickable',
    /CreateFrame\('Button', 'BanzaiLogoButton', frame\)/.test(compat) && /RegisterForClicks\('LeftButtonUp'\)/.test(compat) && /return open\('home'\)/.test(compat)
    && /function Compat:LogoClick[\s\S]*?InCombatLockdown\(\)[\s\S]*?cannot open in combat/.test(compat) && /BanzaiCombatLogo', UIParent\)[\s\S]*?frame:EnableMouse\(false\)/.test(compat)
    && /status\.groups\.selected = page/.test(options) && /ACD\.OpenFrames\.ElvUI and ACD\.SelectGroup/.test(options) && /pcall\(E\.ToggleOptions, E, 'banzai'\)/.test(options)
    && /function Options\.Open[\s\S]*?InCombatLockdown\(\)[\s\S]*?return false/.test(options) && !/E\.ShowOptions/.test(options));
  // C. AFK
  check('1.0.0 AFK screen: the player model (current gear) turning by OnUpdate only while shown, centred; no camera moved, no game setting changed',
    /CreateFrame\('PlayerModel', nil, f\)/.test(afk) && /SetUnit, m, 'player'/.test(afk) && /m:SetFacing\(state\.facing\)/.test(afk) && /model:SetPoint\('CENTER', f, 'CENTER'/.test(afk)
    && !/MoveView|SetCVar|CameraZoom|SetView\(/.test(strip0(afk)));
  check('1.0.0 AFK screen: the HUD hidden only out of combat and shown again only if this screen hid it (no alpha), ended by combat (before lockdown), loading, leaving the world, queue pops, ready checks, keys, clicks, Escape; ElvUI\'s AFK off while Banzai\'s is on',
    /if UIParent:IsShown\(\) then\s+UIParent:Hide\(\)\s+state\.hidUI = true/.test(afk) && /if state\.hidUI then\s+state\.hidUI = false\s+if not UIParent:IsShown\(\) then UIParent:Show\(\) end/.test(afk)
    && ['PLAYER_REGEN_DISABLED', 'LOADING_SCREEN_ENABLED', 'PLAYER_LEAVING_WORLD', 'LFG_PROPOSAL_SHOW', 'READY_CHECK', 'CINEMATIC_START'].every((e) => afk.includes(`'${e}'`))
    && /if InCombatLockdown\(\) then return false end/.test(afk) && !/UIParent:SetAlpha/.test(strip0(afk + compat + tooltip + info)) && /general\.afk = false/.test(T) && /AFK\.Toggle/.test(restore));
  // D. tooltips
  check('1.0.0 tooltip theme: textures on the game\'s tooltips (glass inside ElvUI\'s border, thin gradient edge, soft shadow), nothing hooked or rebuilt, ElvUI fonts in the small crisp font; Banzai tooltips anchored beside their owner, clamped, hidden on leave / hide',
    /Tooltip\.FRAMES = \{ 'GameTooltip', 'ItemRefTooltip'/.test(tooltip) && !/hooksecurefunc|HookScript|SetScript/.test(strip0(tooltip)) && /SetClampedToScreen\(true\)/.test(tooltip)
    && /tt:IsOwned\(owner\) then tt:Hide\(\)/.test(tooltip) && /T\.TOOLTIP_FONTS = \{ outline = 'SHADOW', header = 12, text = 11, small = 10 \}/.test(T));
  // E. bottom panel
  const items = (code) => [...(code.match(/Bar\.ITEMS = \{([\s\S]*?)\n\}/) || [])[1].matchAll(/key = '(\w+)', label = (nil|'[^']*')/g)].map((m) => m[1] + ':' + m[2]).join(',');
  const oldBar = git('addons/BushidoPrivateCompat/Bar.lua', 'banzai-0.9.0') || '';
  check('1.0.0 bottom panel: content, order and labels unchanged since 0.9.0; every entry has a tooltip and its window',
    items(bar) === items(oldBar) && items(bar).split(',').length === 15
    && ['honor', 'conquest', 'mastery', 'haste', 'versatility', 'durability', 'fps', 'ms', 'time', 'spec', 'ilvl', 'professions', 'friends', 'guild', 'gold'].every((k) => new RegExp(`function TIPS\\.${k}\\(tt\\)`).test(info))
    && /button:SetScript\('OnEnter'/.test(bar) && /button:SetScript\('OnLeave'/.test(bar), items(bar));
  check('1.0.0 bottom panel clicks: the game\'s own toggles; in combat one line and nothing queued (bags excepted); spec window only opened, never changed',
    (info.match(/combat = true/g) || []).length === 1 && /gold = \{ name = 'Your bags', fn = 'ToggleAllBags', combat = true \}/.test(info) && /cannot open in combat/.test(info)
    && !/C_Timer|pending/.test(strip0(info.slice(info.indexOf('function Info:Click'), info.indexOf('function Info:Allowed')))) && /TogglePlayerSpellsFrame, tabs\.ClassSpecializations/.test(info)
    && !/SetSpecialization|SetLootSpecialization/.test(strip0(info)));
  check('1.0.0 bottom panel data honest: no hard-coded caps (the game\'s maxQuantity / weekly values, "not reported" otherwise), secret values never shown as numbers, no invented FPS average, lists capped with "+N more"',
    /not reported by the game/.test(info) && /not available from the game/.test(info) && /Banzai keeps no average and no history/.test(info) && /Info\.CAP = 12/.test(info) && /'\+%d more'/.test(info)
    && !/(maxQuantity|cap|seasonCap)\s*=\s*\d{3,}/i.test(strip0(info)) && /issecretvalue/.test(info));
  check('1.0.0 gold: this character, session, Warband bank (the game\'s value first), other characters through Syndicator\'s public API only - read only, hidden characters respected, totals labelled KNOWN',
    /Syndicator\.API|S\.API/.test(info) && ['GetAllCharacters', 'GetByCharacterFullName', 'GetWarband', 'GetCurrentCharacter', 'IsReady'].every((fn) => info.includes('api.' + fn))
    && !/SYNDICATOR_DATA|SYNDICATOR_SUMMARIES|api\.\w+\s*=[^=]|\.money\s*=[^=]|DeleteCharacter|ToggleCharacterHidden/.test(strip0(info)) && /d\.show\.gold == false/.test(info)
    && /C_Bank\.FetchDepositedMoney/.test(info) && /Total KNOWN/.test(info) && /sessionStart/.test(info));
  // F. tracker
  check('1.0.0 objective tooltips: quest title and objective lines, the quest log API only, left of the tracker; clicks and wheel scrolling unchanged',
    /line:SetScript\('OnEnter', function\(btn\) Tracker:Tip\(btn\) end\)/.test(tracker) && /ns\.Tooltip:Begin\(line, 'LEFT'\)/.test(tracker) && /C_QuestLog/.test(tracker)
    && /if not btn\.questID or InCombatLockdown\(\) then return end/.test(tracker) && /EnableMouseWheel\(f\.overflow > 0\)/.test(tracker) && /GetQuestTimeLeftSeconds|GetTimeAllowed/.test(tracker));
  // G. sync
  check('1.0.0 Character Sync: widths, action-button look, tooltip, panel / tracker tooltip and AFK preferences are BANZAI settings (exported per character); the plan says so; gameplay data still never written',
    ['frameWidth = 0.5', 'abSize = 30', 'ringIntensity = 1', "tooltipTheme = 'BANZAI'", 'tooltipScale = 1', 'panelTips = true', 'trackerTips = true', 'afk = true', 'afkTurn = 24', 'afkZone = true'].every((k) => theme.includes(k))
    && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme) && /Target-of-Target width/.test(sync) && /AFK screen/.test(sync) && /every choice made in the BANZAI settings/.test(sync)
    && /unitHeight = own\.layout\.unitHeight, unitSpread = own\.layout\.unitSpread/.test(sync));
  // H. not redesigned
  check('1.0.0 not redesigned: cast history, target nameplate, PvP frames, identity circles, cooldown-bar look, combat tree, chat / Details / minimap frames, Fabled art, gradients unchanged since 0.9.0',
    ['CastHistory.lua', 'TargetPlate.lua', 'PvPFrames.lua', 'Identity.lua'].every((f0) => git('addons/BushidoPrivateCompat/' + f0, 'banzai-0.9.0') === git('addons/BushidoPrivateCompat/' + f0, 'banzai-1.2.1')) /* 1.3.0: up to the release before the split style */
    && [/Compat\.COMBAT = \{[^}]*\}/, /Compat\.CHAT_TITLE = \{[^\n]*/, /Compat\.DETAILS_TITLES = \{[\s\S]*?\n\}/, // 1.2.0 moved Compat.CHAT flush-left on purpose
      /function Compat:BuildCombatLogo[\s\S]*?\nend/, /function Compat:PlaceCombatLogo[\s\S]*?\nend/, /local function Bundle[\s\S]*?\nend/] // 1.1.0 replaced Compat.LEAN and BuildMinimap on purpose
      .every((r) => { const a0 = (git('addons/BushidoPrivateCompat/Compat.lua', 'banzai-0.9.0') || '').match(r); const b0 = fs.readFileSync(path.join(ROOT, 'addons/BushidoPrivateCompat/Compat.lua'), 'utf8').replace(/\r\n/g, '\n').match(r); return a0 && b0 && a0[0] === b0[0]; })
    && /T\.CLASS_ICON = 'fabledclass'/.test(T) && /T\.IDENTITY = \{[\r\n]+\tplayer = '\[name:eltruism:gradientshortcaps\]\[banzai:spec:after\]',/.test(T));
}

// 15. BANZAI 1.0.1: Character Sync live-validation preparation (sArena checked above), read from the built code
{
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const options = rsrc('Options.lua'); const restore = rsrc('Restore.lua'); const sync = rsrc('Sync.lua');
  const T = transformSource;
  const banzaiLua = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(DIST, a)).filter((x) => x.endsWith('.lua') && x !== 'Payloads.lua').map((x) => strip0(fs.readFileSync(path.join(DIST, a, x), 'utf8'))));
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const now = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');
  // code lines (comments dropped) only in a or only in b
  const codeDiff = (a, b) => {
    const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
    const count = new Map();
    for (const l of lines(a)) count.set(l, (count.get(l) || 0) + 1);
    for (const l of lines(b)) count.set(l, (count.get(l) || 0) - 1);
    return [...count].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l);
  };
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  // A. the approved UI unchanged (1.1.0: since 1.0.3, apart from the panel material - Compat.lua / Theme.lua - and the Details row ink in Transform.lua)
  const compatFiles = fs.readdirSync(path.join(ROOT, 'addons', 'BushidoPrivateCompat')).filter((x) => x.endsWith('.lua'));
  const at110 = (rel) => git(rel, 'banzai-1.1.0'); // 1.2.0: the 1.1.0 release as tagged (later milestones change these files on purpose)
  const changedCompat = compatFiles.filter((x) => git('addons/BushidoPrivateCompat/' + x, 'banzai-1.0.3') !== at110('addons/BushidoPrivateCompat/' + x));
  const tDiff = codeDiff(git('addons/BushidoPrivateRestore/Transform.lua', 'banzai-1.0.3'), at110('addons/BushidoPrivateRestore/Transform.lua'));
  const inkLine = /DetailsRowInk|fixed_text_color|^\+ink = \{|^\+text = \{ 1, 1, 1, 1 \}|^\+local c = parchment|^\+local n = 0$|^\+for _, window in pairs\(type\(profile\.instances\)|^\+local row = type\(window\)|^\+if type\(row\) == 'table' then$|^\+n = n \+ 1$|^\+end$|^\+return n$/;
  check('1.1.0 approved UI unchanged since 1.0.3: the unit frames, PvP frames, identity circles, health text, tags, tooltips, bottom panel, tracker, cast history, action buttons, cooldown bars, AFK screen and the preview (Compat.lua and Theme.lua carry the panel material only), the role layouts (Roles.lua), the profile transform (only the Details row ink), the character layer (LAYER 12)',
    changedCompat.sort().join() === 'Compat.lua,Theme.lua'
    && git('addons/BushidoPrivateRestore/Roles.lua', 'banzai-1.0.3') === at110('addons/BushidoPrivateRestore/Roles.lua')
    && tDiff.length > 0 && tDiff.every((l) => inkLine.test(l))
    && /T\.LAYER = 12\b/.test(T), `Compat changed: ${changedCompat.join(', ') || 'none'}; Transform code: ${tDiff.filter((l) => !inkLine.test(l)).join(' ') || 'ink only'}`);
  // B. master
  const capture = body(sync, 'function Sync:Capture()');
  check('1.0.1 BANZAI MASTER: NO BANZAI MASTER SET until Darren presses SET AS BANZAI MASTER (the only caller); the capture records character, class, spec, role, BANZAI version and configuration schema; only Banzai-owned settings, fonts and unit layout',
    /NO_MASTER = 'NO BANZAI MASTER SET'/.test(sync) && /Color\('NO BANZAI MASTER SET'/.test(options) && /Button\(2, 'SET AS BANZAI MASTER', nil, SyncRun\(function\(sync\) return sync:SetMaster\(\) end\)/.test(options)
    && banzaiLua.reduce((n, code) => n + (code.match(/:SetMaster\(/g) || []).length, 0) === 2 /* the definition and the button */
    && /master\.class, master\.classToken, master\.spec, master\.specID, master\.role = who\.class, who\.classToken, who\.spec, who\.specID, who\.role/.test(capture)
    && /settings = WithoutOwn\(art and art\.Export and art:Export\(\)\),/.test(sync) && /art:Import\(WithoutOwn\(config\.settings\)\)/.test(sync)
    && /master\.version = ns\.VERSION/.test(capture) && /master\.schema = self\.SCHEMA/.test(capture) && /Sync\.SCHEMA = 2\b/.test(sync)
    && /function Sync:Config\(\)[\s\S]*?return \{\n\t\tsettings = [^\n]*\n\t\tfonts = \{ display = own\.fonts\.display, small = own\.fonts\.small \},\n\t\tlayout = \{ buffScale = own\.layout\.buffScale, unitHeight = own\.layout\.unitHeight, unitSpread = own\.layout\.unitSpread \},\n\t\}/.test(sync));
  // C. backup before apply
  const apply = body(sync, 'function Sync:Apply()');
  const order = ['local blocked = self:Blocked()', 'local backed, why = self:Backup(key)', "self:Receive(master.config)", "ns.Restore:Apply('character sync', { reuse = true })", 'pcall(ns.Roles.Apply, ns.Roles', 'record.sync = {'].map((k) => apply.indexOf(k));
  check('1.0.1 APPLY BANZAI: required components, then the checked pre-Banzai backup (a failure stops it with a clear error, nothing half-made left), then the master\'s settings, the apply, the role layout; synced only after success',
    order.every((i, n) => i > 0 && (n === 0 || i > order[n - 1]))
    && /if not backed then return Fail\(key, 'PRE-BANZAI BACKUP FAILED \(' \.\. tostring\(why\) \.\. '\): Banzai was NOT applied\.'\) end/.test(apply)
    && /if not hadPrevious then record\.previous = nil end/.test(sync) && /if not hadBackup then record\.syncBackup = nil end/.test(sync)
    && /local ran, ok = pcall\(function\(\)[\s\S]*?if not \(ran and ok\) then[\s\S]*?PutBack\(key, record\.syncBackup\)[\s\S]*?return Fail\(/.test(apply)
    && /if not record\.previous then\n\t\tlocal previous, problem = self:Snapshot\(key\)\n\t\tif not previous then[\s\S]*?return false/.test(restore)
    && restore.indexOf('self:Snapshot(key)') < restore.indexOf("Payloads.lua is missing or incomplete")
    && /Color\('PRE-BANZAI BACKUP: READY'/.test(options) && /PRE-BANZAI BACKUP FAILED/.test(sync));
  // D. no automatic rollout
  check('1.0.1 no automatic rollout: Character Sync applies / updates only from Darren\'s click (CHARACTER SYNC, HOME, /banzai apply); its only event is the master\'s capture at logout; first-login apply only for Darrensdrood',
    /events:RegisterEvent\('PLAYER_LOGOUT'\)\r?\nevents:SetScript\('OnEvent', function\(\) Sync:Capture\(\) end\)/.test(sync) && (strip0(sync).match(/RegisterEvent/g) || []).length === 1
    && banzaiLua.reduce((n, code) => n + (code.match(/[Ss]ync:Apply\(\)/g) || []).length, 0) === 3 /* the definition, the button, ApplyHere */ && /local ok, message = ns\.Sync:Apply\(\)\n\t\tif not ok and message then Print\(message\) end/.test(body(restore, 'function Restore:ApplyHere'))
    && banzaiLua.reduce((n, code) => n + (code.match(/:ApplyHere\(/g) || []).length, 0) === 3 /* the definition, HOME, /banzai apply */
    && /local AUTO_APPLY = \{\}/.test(restore));
  // E. what syncs, what never does, the states shown
  check('1.0.1 CHARACTER SYNC page: the version, STATUS (THIS CHARACTER IS NOT SYNCED / BANZAI SYNCED / BANZAI UPDATE AVAILABLE, APPLY BANZAI, UPDATE CHARACTER, RESTORE PRE-BANZAI, SYNC STATUS), WHAT SYNCS (exact ownership, never synced), DIAGNOSTICS (READY / MISSING / SKIPPED / ERROR)',
    /Gradient\('BANZAI ' \.\. version, EMERALD, PURPLE\) \.\. '   ' \.\. Muted\('CHARACTER SYNC/.test(options)
    && ["NOT_SYNCED = 'THIS CHARACTER IS NOT SYNCED'", "SYNCED = 'BANZAI SYNCED'", "UPDATE = 'BANZAI UPDATE AVAILABLE'"].every((k) => sync.includes(k))
    && ["'APPLY BANZAI'", "'UPDATE CHARACTER'", "'RESTORE PRE-BANZAI'", "'SYNC STATUS'", "'BANZAI SYNCS'", "'NEVER SYNCED'", "'SYNC DIAGNOSTICS'"].every((k) => options.includes(k))
    && ["'MASTER'", "'MASTER BANZAI VERSION'", "'THIS CHARACTER'", "'CLASS'", "'SPEC'", "'ROLE'", "'APPLIED CONFIGURATION'", "'SYNC STATE'"].every((k) => options.includes("row(" + k))
    && ["'BANZAI'", "'ELVUI (the shared Banzai profile)'", "'ROLE LAYOUTS'", "'MMEDIATAG / JIBERISH'", "'DETAILS'"].every((k) => sync.includes('{ ' + k + ', '))
    && ['action-bar spell assignments', 'macros', 'keybinds', 'talents and loadouts', 'equipment and equipment sets', 'consumables', 'class-specific spell placement', 'Details combat history', 'chat history', 'currencies', 'quests', 'reputation', 'progression', 'unrelated addon settings', 'No full SavedVariables database is cloned'].every((k) => (sync.match(/Sync\.NEVER_SYNCED = '[^\n]*/) || [''])[0].includes(k))
    && /Sync\.APPLIES = \{ 'visual theme', 'Banzai layout', 'unit-frame presentation', 'role layout', 'Chat \/ Details \/ Minimap', 'tooltips', 'AFK screen', 'PvP visual configuration', 'supported addon presentation' \}/.test(sync)
    && /Sync\.NEVER = \{ 'abilities', 'action assignments', 'keybinds', 'macros', 'talents', 'gear', 'gameplay history' \}/.test(sync)
    && ["'BANZAI WILL APPLY:'", "'BANZAI WILL NOT CHANGE:'"].every((k) => sync.includes(k))
    && ["state = c.required and 'MISSING' or 'SKIPPED'", "state = (ok and ready) and 'READY' or 'ERROR'"].every((k) => sync.includes(k))
    && /\{ name = 'ElvUI', folder = 'ElvUI', required = true/.test(sync) && /\{ name = 'Banzai Art', folder = 'BushidoPrivateCompat', required = true/.test(sync)
    && ["{ name = 'Eltruism', folder = 'ElvUI_EltreumUI' }", "{ name = 'mMediaTag', folder = 'ElvUI_mMediaTag' }", "{ name = 'Jiberish Icons', folder = 'JiberishIcons' }", "{ name = 'Details', folder = 'Details', ready"].every((k) => sync.includes(k)));
  const restoreSrc = restore;
  check('1.0.1 review: fonts and the unit layout per character (a master change reaches others only by UPDATE CHARACTER); revisions only count up (a master restored and set again); every restore ends the sync / master state; the master never publishes an empty or blocked setup; Kaliel\'s Tracker asks for a reload only when it changed; pre-Sync characters backed up before their first update',
    /function Restore:Own\(key\)/.test(restoreSrc) && /local layout = self:Own\(\)\.layout/.test(body(restoreSrc, 'function Restore:LayerOptions')) && !/db\.layout\.\w+ =|db\.fonts\.(display|small) =/.test(strip0(restoreSrc))
    && /local chosen = self:Own\(\)\.fonts\.display/.test(restoreSrc) && /local own = ns\.Restore:Own\(self\.Key\(\)\)/.test(body(sync, 'function Sync:Receive'))
    && /revision = LastRevision\(\)/.test(body(sync, 'function Sync:SetMaster')) && /master\.revision = math\.max\(master\.revision or 0, LastRevision\(\)\) \+ 1/.test(sync)
    && /if ns\.Sync and ns\.Sync\.Forget then ns\.Sync:Forget\(key\) end/.test(body(restoreSrc, 'function Restore:Revert')) && /db\.sync\.lastRevision = math\.max/.test(body(sync, 'function Sync:Forget'))
    && /if self:Blocked\(\) then return false end/.test(body(sync, 'function Sync:Capture')) && /if next\(config\.settings\) == nil then return false end/.test(sync)
    && /if result == 'hidden \(Banzai tracker on\)' or result == 'shown again' then reload = true end/.test(sync)
    && /if not \(record\.syncBackup and type\(record\.syncBackup\.settings\) == 'table'\) then record\.syncBackup = OwnBackup\(key\) end/.test(body(sync, 'function Sync:Update')));
  check('1.0.1 Character Sync identity: class, spec and role are read from the logged-in character (never the master\'s); the role layout follows the spec, after combat when changed in combat',
    /function Sync:Identity\(\)\n\tlocal className, token = UnitClass\('player'\)/.test(sync) && /if InCombatLockdown\(\) then\n\t\tself\.pending = role/.test(rsrc('Roles.lua'))
    && !/master\.(classToken|spec|role)/.test(body(sync, 'function Sync:Receive')));
}

// 16. BANZAI 1.0.2 / 1.0.3: one objective tracker on screen (Character Sync hotfix; 1.0.3: the parking holds), read from the built code
{
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const restore = rsrc('Restore.lua'); const sync = rsrc('Sync.lua');
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const now = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const compatFiles = fs.readdirSync(path.join(ROOT, 'addons', 'BushidoPrivateCompat')).filter((x) => x.endsWith('.lua'));
  const restoreFiles = fs.readdirSync(path.join(ROOT, 'addons', 'BushidoPrivateRestore')).filter((x) => x.endsWith('.lua'));
  const changed = [...compatFiles.map((x) => 'BushidoPrivateCompat/' + x), ...restoreFiles.map((x) => 'BushidoPrivateRestore/' + x)]
    .filter((x) => git('addons/' + x, 'banzai-1.0.3') !== git('addons/' + x, 'banzai-1.1.0')); // 1.2.0: the 1.1.0 release as tagged
  check('1.1.0 scope: since 1.0.3 only the panel material changed - Banzai Art Compat.lua / Theme.lua, the settings (Options.lua), Restore.lua (version, panel background, status), Sync.lua (the WHAT SYNCS text), Transform.lua (Details row ink); Character Sync workflow, role layouts and every other Banzai Art file unchanged',
    changed.sort().join() === 'BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Sync.lua,BushidoPrivateRestore/Transform.lua', changed.join(', ')); // 1.1.1 touches the same files
  const own = body(restore, 'function Restore:TrackerOwnership');
  const uses = (strip0(restore).match(/\bf:[A-Za-z]+\(/g) || []).filter((x, i, a) => a.indexOf(x) === i).sort();
  check('1.0.2 Blizzard\'s objective tracker: parked under a never-shown frame (not hidden, hooked, unregistered or faded) only while the Banzai tracker shows, once (nothing when already right), never in combat (waits for its end); back on its parent otherwise',
    /local PARKED = CreateFrame\('Frame'\)\nPARKED:Hide\(\)/.test(restore) && /local f = _G\.ObjectiveTrackerFrame/.test(restore) && (strip0(restore).match(/ObjectiveTrackerFrame/g) || []).length === 1
    && uses.join() === 'f:GetParent(,f:IsCollapsed(,f:IsShown(,f:SetParent(' && /pcall\(f\.SetCollapsed, f, saved\.collapsed and true or false\)/.test(restore)
    && /if want == \(f:GetParent\(\) == PARKED\) then/.test(own) && /if InCombatLockdown\(\) then\n\t\tself\.trackerPending = true/.test(own)
    && own.indexOf('if InCombatLockdown()') < own.indexOf('f:SetParent(PARKED)')
    && /return \(CompatTracker\(\) and E and E\.data and E\.data\.GetCurrentProfile and E\.data:GetCurrentProfile\(\) == T\.PROFILE\) and true or false/.test(body(restore, 'function Restore:BanzaiTrackerShown'))
    && ['ADDON_LOADED', 'PLAYER_ENTERING_WORLD', 'EDIT_MODE_LAYOUTS_UPDATED', 'PLAYER_REGEN_ENABLED'].every((e) => restore.includes("trackerEvents:RegisterEvent('" + e + "')"))
    && /if event == 'PLAYER_REGEN_ENABLED' and not Restore\.trackerPending then return end/.test(restore));
  // 1.0.3: the parking holds - ownership reasserted one frame after the events that put the tracker back (read from the game's and Eltruism's code), never by a hook or a loop
  const queue = body(restore, 'function Restore:QueueTrackerOwnership');
  const handler = restore.slice(restore.indexOf("trackerEvents:SetScript('OnEvent'"), restore.indexOf('\nend)', restore.indexOf("trackerEvents:SetScript('OnEvent'")));
  check('1.0.3 ownership reasserted one frame after PLAYER_ENTERING_WORLD, FIRST_FRAME_RENDERED, ACTIVE_TALENT_GROUP_CHANGED, EDIT_MODE_LAYOUTS_UPDATED, PLAYER_SPECIALIZATION_CHANGED (player), EditMode.Exit (EventRegistry), the tracker built late and (when a change waited) the end of combat: one queued check at a time, the flag cleared before it runs, the same idempotent function; no hook, no OnUpdate, no ticker, nothing in chat',
    /if self\.trackerQueued then return 'queued' end/.test(queue) && /C_Timer\.After\(0, function\(\)\n\t\tRestore\.trackerQueued = nil\n\t\tRestore:TrackerOwnership\(reason\)/.test(queue)
    && restore.includes("trackerEvents:RegisterEvent('FIRST_FRAME_RENDERED')") && restore.includes("trackerEvents:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')") && restore.includes("trackerEvents:RegisterUnitEvent('PLAYER_SPECIALIZATION_CHANGED', 'player')")
    && /Restore:QueueTrackerOwnership\(event\)/.test(handler) && !/Restore:TrackerOwnership\(/.test(handler)
    && /_G\.EventRegistry:RegisterCallback\('EditMode\.Exit', function\(\) Restore:QueueTrackerOwnership\('EditMode\.Exit'\) end, trackerEvents\)/.test(restore)
    && (strip0(restore).match(/trackerEvents:SetScript\('OnEvent'/g) || []).length === 1 && (strip0(restore).match(/RegisterCallback\(/g) || []).length === 1
    && !/hooksecurefunc|HookScript|OnUpdate|NewTicker/.test(strip0(restore)) && !/Print\(/.test(own) && !/Print\(/.test(queue));
  const revert = body(restore, 'function Restore:Revert()');
  check('1.0.2 tracker ownership everywhere it changes: APPLY BANZAI, UPDATE CHARACTER, a failed sync, the tracker option, login; its state before Banzai in the pre-Banzai record (once, never overwritten), put back exactly by every restore',
    /blizzardTracker = self:BlizzardTrackerState\(\),/.test(body(restore, 'function Restore:Snapshot')) && /if record\.previous then return record\.previous end/.test(body(restore, 'function Restore:Snapshot'))
    && /if record and record\.previous and saved == nil then record\.previous\.blizzardTracker = self:BlizzardTrackerState\(\) end/.test(own)
    && /self:TrackerOwnership\('apply'\)/.test(body(restore, 'function Restore:Apply(')) && /R:TrackerOwnership\('update'\)/.test(body(sync, 'function Sync:Update'))
    && /pcall\(ns\.Restore\.TrackerOwnership, ns\.Restore, 'sync failed'\)/.test(body(sync, 'function Sync:Apply')) && /self:TrackerOwnership\('tracker option'\)/.test(body(restore, 'function Restore:SetTracker'))
    && /self:TrackerOwnership\('login'\)/.test(body(restore, 'function Restore:OnLogin'))
    && revert.indexOf('self:PutBackBlizzardTracker(previous.blizzardTracker)') > 0 && revert.indexOf('self:PutBackBlizzardTracker(previous.blizzardTracker)') < revert.indexOf('record.previous = nil'));
}

// 17. BANZAI 1.1.0: panel material (chat, Details, minimap in bamboo; border x background), read from the built code / configuration / media
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const theme = src('Theme.lua'); const tracker = src('Tracker.lua');
  const options = rsrc('Options.lua'); const restore = rsrc('Restore.lua'); const sync = rsrc('Sync.lua');
  const T = transformSource;
  const tgaLib = require('./lib/tga');
  const panel = require('./lib/panel');
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const media = (name) => tgaLib.read(path.join(DIST, 'BushidoPrivateCompat', 'media', name + '.tga'));
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  // A. the construction: one straight stalk per side, ends past the corners, rope ties on the crossings; the content where it was
  const layout = body(compat, 'local function LayoutBamboo(holder)');
  const luaPanel = Object.fromEntries([...((compat.match(/Compat\.PANEL = \{([\s\S]*?)\}/) || [])[1] || '').matchAll(/(\w+) = ([0-9.]+)/g)].map((m) => [m[1], Number(m[2])]));
  check('1.1.0 bamboo construction: TOP / BOTTOM / LEFT / RIGHT one stalk each (body segments one node period each, a cut tip on one end, a plain node end on the other), running past the corners, a rope tie over every crossing, nothing leaning or warped; the geometry shared with the offline preview (tools/lib/panel.js)',
    ["{ name = 'top', horizontal = true", "{ name = 'bottom', horizontal = true", "{ name = 'left', horizontal = false", "{ name = 'right', horizontal = false"].every((k) => layout.includes(k))
    && /cutEnd = 'end', sub = 2/.test(layout) && /cutEnd = flush and 'end' or 'start', sub = 0/.test(layout) && /from = startLeft/.test(layout) && /local startLeft = flush and math\.max\(0, -holder\.flushLeft\) or -P\.ext \* d/.test(layout) /* 1.2.0: a flush-left frame ends at its left stalk */
    && /to = W \+ P\.ext \* d/.test(layout) && /to = H \+ extBottom \* d/.test(layout)
    && luaPanel.extBottom === 0 && /if holder\.shortBottom and top \+ tie > H then v1 = \(H - top\) \/ tie end/.test(layout) /* nothing of the chat / Details frame below the bottom panel's top line */
    && /put\(st, st\.from, bodyFrom, STALK_END, first\[1\], first\[2\], true\)/.test(layout) && /put\(st, bodyTo, st\.to, STALK_END, last\[1\], last\[2\], false\)/.test(layout)
    && /math\.floor\(\(bodyTo - bodyFrom\) \/ \(P\.period \* d\) \+ 0\.5\)/.test(layout) && /\{ 'TOPLEFT', leftTie, axis\.top \}, \{ 'TOPRIGHT', axis\.right, axis\.top \}, \{ 'BOTTOMLEFT', leftTie, axis\.bottom \}, \{ 'BOTTOMRIGHT', axis\.right, axis\.bottom \}/.test(layout)
    && /local leftTie = flush and math\.max\(axis\.left, tie \/ 2 - holder\.flushLeft\) or axis\.left/.test(layout) /* 1.2.0: on the crossing; flush-left: kept on the screen */
    && !/SetVertexOffset|SetRotation|lean/.test(strip0(compat))
    && Object.keys(panel.PANEL).every((k) => luaPanel[k] === panel.PANEL[k]) && Object.keys(luaPanel).length === Object.keys(panel.PANEL).length,
    Object.entries(luaPanel).map(([k, v]) => k + ' ' + v).join(', '));
  check('1.1.0 content kept where it was: the chat panel, the Details windows (same DETAILS numbers in Banzai and Banzai Art) and the minimap (ElvUI\'s square mask, backdrop transparent while the frame shows; map never rotated, resized or re-anchored by Banzai Art)',
    /SetMaskTexture\(SQUARE_MASK\)/.test(compat) && !/MINIMAP_MASK/.test(compat) && /backdrop:SetAlpha\(on and 0 or 1\)/.test(compat) && !/Minimap:SetSize|map:SetSize|map:SetPoint|map:SetRotation|map:ClearAllPoints/.test(strip0(compat))
    && /frame:SetPoint\('CENTER', map, 'CENTER', 0, 0\)/.test(compat) && /mapSize \+ 2 \* \(self\.PANEL\.outer \+ StalkDiameter\(\)\)/.test(compat)
    && /Compat\.CHAT = \{ left = -0\.655, contentX = 31, width = 493\.31, height = 161 \}/.test(compat) /* 1.2.0: flush-left (1.1.x: 15.345 / 47) */ && /frameWidth = 493\.31, frameHeight = 161/.test(compat)
    && /label:SetPoint\('BOTTOM', frame, 'TOP', 0, self\.MINIMAP\.zoneGap\)/.test(compat) && num(tracker, /Tracker\.GAP = (\d+)/) >= panel.PANEL.ext * panel.PANEL.stalk + 2);
  check('1.1.0 titles stay clear: DAMAGE / HEALING / CHAT centred on the top stalk\'s axis, HEALING kept left of the top-right rope tie',
    /local line = self\.PANEL\.outer \+ d \/ 2/.test(compat) && /chassis\.bw - self\.PANEL\.outer - d \/ 2 - self\.PANEL\.tie \* d \/ 2 - T\.bamboo \+ T\.pad/.test(compat));
  // B. border styles x backgrounds, independent; the rope its own colour
  const stalkFn = body(theme, 'function Theme:PanelStalk(');
  check('1.1.0 border styles CLASS (lighter -> class colour -> deeper from the class colour; rope hemp), BANZAI (natural greens per stalk, per-segment variation; rope violet -> purple), HARDKORH (lime -> emerald -> teal -> violet -> purple over the frame; rope violet -> purple); defaults BANZAI + GLASS; the rope never takes the stalk colour or the intensity',
    /mode == 'CLASS'/.test(stalkFn) && /Mix\(base, \{ 1, 1, 1 \}, 0\.38\) \}, \{ 0\.5, base \}, \{ 1, Mix\(\{ 0, 0, 0 \}, base, 0\.52\)/.test(stalkFn) && /mode == 'HARDKORH'/.test(stalkFn) && /HARDKORH_STALK/.test(stalkFn) && /BANZAI_STALKS\[stalk\]/.test(stalkFn) && /vary/.test(stalkFn)
    && /local HARDKORH_STALK = \{ \{ 0\.00, COLORS\.lime \}, \{ 0\.42, COLORS\.emerald \}, \{ 0\.58, COLORS\.teal \}, \{ 0\.78, COLORS\.violet \}, \{ 1\.00, COLORS\.purple \} \}/.test(theme)
    && /local BANZAI_STALKS = \{ top = \{[^}]*\}, right = \{[^}]*\}, bottom = \{[^}]*\}, left = \{[^}]*\} \}/.test(theme)
    && /\(self:DB\(\)\.panelBorder == 'CLASS'\) and HEMP_ROPE or VIBRANT_TIE/.test(theme) && /return self:ColorAt\(stops, p, true\)/.test(body(theme, 'function Theme:PanelRope('))
    && /panelBorder = 'BANZAI'/.test(theme) && /panelBackground = 'GLASS'/.test(theme) && /parchmentBrightness = 1/.test(theme)
    && /Theme:PanelStalk\(piece\.stalk, field\(piece\.xa, piece\.ya\), piece\.pa, piece\.vary\)/.test(compat));
  check('1.1.0 backgrounds SOLID (near opaque dark green-black) / GLASS (the approved glass at the glass opacity) / PARCHMENT (the nine-slice, brightness); chosen independently of the border; the minimap has no background (the map is the interior)',
    /Theme\.SOLID_ALPHA = 0\.97/.test(theme) && /if mode == 'SOLID' then Theme:Solid\(holder\.glass\) else Theme:Glass\(holder\.glass\) end/.test(compat) && /holder\.glass:SetShown\(not parchment\)/.test(compat)
    && /t:SetShown\(parchment\)/.test(compat) && /0\.91 \* math\.max\(0\.7, math\.min\(1\.1, Theme:DB\(\)\.parchmentBrightness or 1\)\)/.test(compat)
    && /BambooFrame\(frame, true\) -- the map itself is the interior/.test(compat) && /BambooFrame\(frame, false, true\)/.test(compat)
    && !/panelBorder = [^\n]*panelBackground|panelBackground = [^\n]*panelBorder|if [^\n]*panelBorder[^\n]*panelBackground/.test(strip0(compat)) /* nothing pairs them */
    && /if piece\.horizontal then Theme:Gradient\(piece\.texture, 'HORIZONTAL', from, to, 1, 1\) else Theme:Gradient\(piece\.texture, 'VERTICAL', to, from, 1, 1\) end/.test(compat) /* a vertical gradient's first colour is its bottom */
    && /Theme:PanelRope\(1\), Theme:PanelRope\(0\)/.test(compat)
    && /Theme\.PANEL_BORDERS = \{ 'CLASS', 'BANZAI', 'HARDKORH' \}/.test(theme) && /Theme\.PANEL_BACKGROUNDS = \{ 'SOLID', 'GLASS', 'PARCHMENT' \}/.test(theme));
  // C. parchment readability: Banzai-owned Details row text bright off-white (1.1.1; 1.1.0's charcoal was unreadable live), Blizzard / chat content untouched
  const ink = ((T.match(/ink = \{ ([0-9., ]+) \}/) || [])[1] || '').split(',').map(Number);
  check('1.1.1 parchment readability: the Details row text (Banzai styles it) is a bright off-white on parchment (never charcoal), with its OUTLINE and shadow, through Details\' own row_info.fixed_text_color and InstanceRefreshRows, exactly white otherwise; the class-coloured bars, chat colours (ElvUI\'s outlined chat font) and Blizzard text never recoloured',
    /function T\.DetailsRowInk\(profile, parchment\)/.test(T) && /row\.fixed_text_color = \{ c\[1\], c\[2\], c\[3\], c\[4\] \}/.test(T) && ink.length === 4 && ink[0] >= 0.9 && ink[1] >= 0.9 && ink[2] >= 0.85 && ink[3] === 1 && /text = \{ 1, 1, 1, 1 \}/.test(T)
    && /row\.textL_outline_mode, row\.textR_outline_mode = S\.outline, S\.outline/.test(T) && /outline = 'OUTLINE'/.test(T) && /shadow = \{ color = \{ 0, 0, 0, 1 \}, offset = \{ 1, -1 \} \}/.test(T)
    && /T\.DetailsRowInk\(profile, CompatSetting\('panelBackground', 'GLASS'\) == 'PARCHMENT'\)/.test(restore) && /pcall\(window\.InstanceRefreshRows, window\)/.test(body(restore, 'function Restore:ApplyDetailsInk'))
    && /row\.texture_class_colors = true/.test(T) && !/fontOutline|AddMessage|SetTextColor|ChatFrame\d/.test(strip0(body(restore, 'function Restore:SetPanelBackground')) + strip0(body(restore, 'function Restore:ApplyDetailsInk')))
    && !/ChatFrame|AddMessage|SetTextColor/.test(strip0(compat).slice(strip0(compat).indexOf('local function LayoutBamboo'), strip0(compat).indexOf('function Compat:UpdateZone'))));
  // D. GUI, status, sync, migration
  const panelStyle = (options.match(/panelStyle = Section\(15, 'PANEL STYLE', \{([\s\S]*?)\n\t\t\t\t\}\),/) || [])[1] || '';
  check('1.1.0 GUI: BANZAI > APPEARANCE > PANEL STYLE with Border style (Class / Banzai / Hardkorh) and Background (Solid / Banzai Glass / Hardkorh Parchment) as radio selects, border scale 70 - 100 % (thicker would cover the content), glass opacity, parchment brightness 70 - 110 %; applied at once (the existing Banzai configuration model); no duplicate controls',
    /sorting = \{ 'CLASS', 'BANZAI', 'HARDKORH' \}/.test(panelStyle) && /sorting = \{ 'SOLID', 'GLASS', 'PARCHMENT' \}/.test(panelStyle) && /style = 'radio'/.test(panelStyle)
    && /ArtRange\(4, 'borderScale', 'Border scale'[^\n]*0\.7, 1, 0\.05/.test(panelStyle) && /ArtRange\(5, 'glassOpacity', 'Glass opacity'/.test(panelStyle) && /ArtRange\(6, 'parchmentBrightness', 'Parchment brightness', nil, 0\.7, 1\.1/.test(panelStyle)
    && /R:SetPanelBackground\(value\)/.test(panelStyle) && (strip0(options).match(/'glassOpacity'/g) || []).length === 1 && (strip0(options).match(/'borderScale'/g) || []).length === 1
    && /panel style \(chat \/ Details \/ minimap \/ buffs\): %s bamboo border, %s background, border scale %d%%/.test(restore)); // 1.2.0: + buffs
  check('1.1.0 Character Sync carries the panel style (border, background, border scale, glass opacity, parchment brightness: DEFAULTS keys, exported with every BANZAI setting); gameplay data still never written; the WHAT SYNCS text says so',
    ["panelBorder = 'BANZAI'", "panelBackground = 'GLASS'", 'parchmentBrightness = 1', 'borderScale = 1', 'glassOpacity = 0.72'].every((k) => theme.includes(k)) && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme)
    && /panel style \(border style, background, border scale, glass opacity, parchment brightness\)/.test(sync) && /Sync\.CHARACTER_OWN = \{ 'cdTracked' \}/.test(sync));
  check('1.1.0 migration / rollback: schema 7 clamps the old band thickness into the stalk range, unknown styles fall back to BANZAI / GLASS, a 1.0.3 saved set keeps every other choice; the saved-variable names and the profile name unchanged; upgrade message at login',
    /Theme\.SCHEMA = 8/.test(theme) /* 1.2.0: 8 */ && /\[7\] = function\(db\)[\s\S]*?db\.borderScale = math\.max\(0\.7, math\.min\(1, db\.borderScale\)\)/.test(theme) && /Theme\.BORDER_SCALE = \{ min = 0\.7, max = 1 \}/.test(theme)
    && /db\.borderScale = math\.max\(self\.BORDER_SCALE\.min, math\.min\(self\.BORDER_SCALE\.max, db\.borderScale\)\)/.test(theme)
    && /if db\.panelBorder ~= 'CLASS' and db\.panelBorder ~= 'BANZAI' and db\.panelBorder ~= 'HARDKORH' then db\.panelBorder = 'BANZAI' end/.test(theme)
    && /if db\.panelBackground ~= 'SOLID' and db\.panelBackground ~= 'GLASS' and db\.panelBackground ~= 'PARCHMENT' then db\.panelBackground = 'GLASS' end/.test(theme)
    && compatToc.fields.SavedVariables === 'BanzaiCompatDB' && /local PROFILE = 'JiberishUI - Bushido Private'/.test(compat)
    && /updated to %s %s: the small BANZAI wordmark steps aside while BanzaiSland hosts/.test(restore) /* 1.3.8's message */ && /if self\.ApplyDetailsInk then self:ApplyDetailsInk\(\) end/.test(body(restore, 'function Restore:OnLogin')));
  check('1.4.0 preserves the 1.1.0 migration contract with the licensed display-font selection-lock update message',
    /Theme\.SCHEMA = 9/.test(theme) && /\[7\] = function\(db\)[\s\S]*?db\.borderScale = math\.max\(0\.7, math\.min\(1, db\.borderScale\)\)/.test(theme)
    && /Theme\.BORDER_SCALE = \{ min = 0\.7, max = 1 \}/.test(theme)
    && /db\.borderScale = math\.max\(self\.BORDER_SCALE\.min, math\.min\(self\.BORDER_SCALE\.max, db\.borderScale\)\)/.test(theme)
    && /if db\.panelBorder ~= 'CLASS' and db\.panelBorder ~= 'BANZAI' and db\.panelBorder ~= 'HARDKORH' then db\.panelBorder = 'BANZAI' end/.test(theme)
    && /if db\.panelBackground ~= 'SOLID' and db\.panelBackground ~= 'GLASS' and db\.panelBackground ~= 'PARCHMENT' then db\.panelBackground = 'GLASS' end/.test(theme)
    && compatToc.fields.SavedVariables === 'BanzaiCompatDB' && /local PROFILE = 'JiberishUI - Bushido Private'/.test(compat)
    && /updated to %s %s: licensed display-font selection locked to Shojumaru; unsupported strings use the Information Font, and approved layouts and features are unchanged\./.test(restore)
    && /if self\.ApplyDetailsInk then self:ApplyDetailsInk\(\) end/.test(body(restore, 'function Restore:OnLogin')));
  // E. performance: built once, painted on changes, no loop
  check('1.1.0 performance: static surfaces - laid out and painted by the painters on Refresh (settings, theme, class / spec, profile), textures reused across scale changes, no OnUpdate anywhere in Banzai Art\'s frame code, no ticker added (the 0.7.0 title ticker stays the only one)',
    !/OnUpdate/.test(strip0(compat)) && (strip0(compat).match(/C_Timer\.NewTicker\(/g) || []).length === 1 && /Painter\(function\(\) PaintBamboo\(holder\) end\)/.test(compat) && /for _, holder in ipairs\(bands\) do LayoutBamboo\(holder\) end/.test(compat)
    && /local piece = holder\.pieces\[used\]\n\t\tif not piece then/.test(compat) && /for i = used \+ 1, #holder\.pieces do holder\.pieces\[i\]\.texture:Hide\(\) end/.test(compat)
    && /if holder\.layoutKey == key then return end/.test(compat)
    && /if Theme:DB\(\)\.theme == 'CLASS' or Theme:DB\(\)\.panelBorder == 'CLASS' then RefreshAll\(Compat\) end/.test(compat));
  // F. the original assets, at the quality the frame needs
  const stalk = media('BanzaiStalk'); const ends = media('BanzaiStalkEnd'); const rope = media('BanzaiRopeTie');
  const parch = panel.legacyParchment(); // 1.3.7: the 1.1.0 sheet is no longer built (block 27); its generator is kept, and this is what it makes - the approved paper the 1.3.7 tile keeps
  const at = (img, x, y) => { const o = (y * img.w + x) * 4; return { r: img.px[o], g: img.px[o + 1], b: img.px[o + 2], a: img.px[o + 3] }; };
  const row = (img, y) => [...Array(img.w).keys()].map((x) => at(img, x, y));
  const mid = row(stalk, stalk.h / 2);
  let grooves = 0; let inGroove = false; for (const px of mid) { if (px.r < 150 && px.a === 255 && !inGroove) { grooves++; inGroove = true; } else if (px.r >= 150) inGroove = false; }
  const top = row(stalk, Math.round(stalk.h / 2 - 0.3 * 44)); const bottom = row(stalk, Math.round(stalk.h / 2 + 0.3 * 44));
  const mean = (list) => list.reduce((n, px) => n + px.r, 0) / list.length;
  const col = (img, x) => [...Array(img.h).keys()].map((y) => at(img, x, y).a);
  const sameEdge = col(stalk, 0).every((a, y) => Math.abs(a - col(stalk, stalk.w - 1)[y]) <= 3);
  check('1.1.0 stalk texture: 1024 x 128, four node periods (dark grooves at every node), a highlight above and a darker underside, transparent above and below the stalk, the two ends of the strip matching (tileable), drawn at 88 px for a 13 px stalk on screen and mip-filtered',
    stalk.w === 1024 && stalk.h === 128 && grooves >= 4 && grooves <= 8 && mean(top) > mean(bottom) + 15 && at(stalk, 100, 0).a === 0 && at(stalk, 100, 127).a === 0 && at(stalk, 100, 64).a === 255 && sameEdge
    && /SetTexture\(path, 'CLAMP', 'CLAMP', 'TRILINEAR'\)/.test(compat), `grooves ${grooves}, highlight ${mean(top).toFixed(0)} vs underside ${mean(bottom).toFixed(0)}`);
  const hollow = [...Array(60).keys()].map((i) => at(ends, 180 + i, 64)).filter((px) => px.a === 255 && px.r < 70).length;
  check('1.1.0 stalk ends: a diagonal cut with a hollow face (left half) and a plain node end with a rounded cap (right half), a transparent gap between the halves so no outline bleeds across',
    ends.w === 512 && ends.h === 128 && hollow >= 15 && at(ends, 250, 64).a === 0 && at(ends, 258, 64).a === 0 && at(ends, 300, 64).a === 255 && at(ends, 256 + 214, 64).a === 255 && at(ends, 256 + 230, 64).a === 0, `hollow ${hollow} px`);
  const diag = [...Array(80).keys()].map((i) => at(rope, 88 + i, 88 + i)).filter((px) => px.a === 255).length;
  check('1.1.0 rope tie: 256 x 256, the two cord bands crossing at the centre (opaque along the diagonals), the knot, transparent corners (it lies over the crossing only)',
    rope.w === 256 && rope.h === 256 && diag >= 60 && at(rope, 128, 128).a === 255 && at(rope, 4, 4).a === 0 && at(rope, 251, 4).a === 0 && at(rope, 4, 251).a === 0 && at(rope, 251, 251).a === 0, `diagonal ${diag} / 80 opaque`);
  const centre = at(parch, 256, 256); const samples = [];
  for (let y = 120; y < 392; y += 16) for (let x = 120; x < 392; x += 16) samples.push(at(parch, x, y));
  const avg = (k) => samples.reduce((n, px) => n + px[k], 0) / samples.length;
  const edgeMean = [...Array(40).keys()].map((i) => at(parch, 30 + i * 11, 26)).filter((px) => px.a === 255);
  const edgeDark = edgeMean.length > 5 && edgeMean.reduce((n, px) => n + px.r, 0) / edgeMean.length < avg('r') - 8;
  const topEdge = [...Array(parch.w - 120).keys()].map((i) => i + 60).map((x) => { for (let y = 0; y < 60; y++) if (at(parch, x, y).a > 127) return y; return 60; });
  const wobble = Math.max(...topEdge) - Math.min(...topEdge);
  check('1.1.0 parchment: 512 x 512 cream / tan (warm: r > g > b, not white, not yellow cartoon paper, restrained variation), darker toward its edges, an uneven torn edge (the alpha boundary wanders), transparent beyond it',
    parch.w === 512 && parch.h === 512 && centre.a === 255 && avg('r') > 210 && avg('r') > avg('g') + 12 && avg('g') > avg('b') + 25 && avg('b') > 120 && avg('b') / avg('r') > 0.55 && avg('b') / avg('r') < 0.85
    && Math.max(...samples.map((px) => px.r)) - Math.min(...samples.map((px) => px.r)) < 70 && edgeDark && wobble >= 8 && wobble <= 40 && at(parch, 0, 0).a === 0 && at(parch, 511, 511).a === 0 && at(parch, 256, 0).a === 0,
    `centre ${centre.r},${centre.g},${centre.b}; mean ${avg('r').toFixed(0)},${avg('g').toFixed(0)},${avg('b').toFixed(0)}; edge wobble ${wobble} px`);
  // G. the reference images: looked at, never built in, never committed
  const refDir = path.join(ROOT, 'design-references');
  // 1.3.1: the reference IMAGES (design-references/fonts holds the Want Coffee files Darren supplied for the build - checked in block 21)
  const refFiles = fs.existsSync(refDir) ? files(refDir).filter((f) => /\.(png|jpe?g|tga|blp|bmp|webp|gif)$/i.test(f)) : [];
  const refBytes = new Set(refFiles.map((f) => crypto.createHash('sha1').update(fs.readFileSync(f)).digest('hex')));
  const distMedia = files(path.join(DIST, 'BushidoPrivateCompat', 'media'));
  let ignored = false;
  try { ignored = execSync('git check-ignore design-references', { cwd: ROOT, encoding: 'utf8' }).trim() === 'design-references'; } catch (e) { ignored = false; }
  check('1.1.0 reference images excluded: nothing from design-references/ in dist/, no built media byte-equal to a reference, the folder git-ignored and untracked; the assets are generated (tools/lib/panel.js reads no image file)',
    !distFiles.some((f) => /design-references/i.test(f)) && !distFiles.some((f) => refFiles.some((r) => path.basename(r).toLowerCase() === path.basename(f).toLowerCase())) && distMedia.every((f) => !refBytes.has(crypto.createHash('sha1').update(fs.readFileSync(f)).digest('hex')))
    && ignored && !tracked.some((f) => /^design-references\//.test(f)) && !/readFileSync|tga\.read|\.png|\.jpg/.test(strip0(fs.readFileSync(path.join(ROOT, 'tools', 'lib', 'panel.js'), 'utf8'))),
    `${refFiles.length} reference files, ${distMedia.length} media files`);
  check('version shown: GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the AFK screen and both TOCs read ' + VERSION + ' (the README too)', fs.readFileSync(path.join(ROOT, 'README.md'), 'utf8').includes('Version: **BANZAI ' + VERSION + '**'));
  // 1.1.1 hotfix scope: since 1.1.0 only the row text colour, the version and its message
  const git111 = (rel) => { try { return execSync(`git show banzai-1.1.0:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const now111 = (rel) => { try { return execSync(`git show banzai-1.1.1:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } }; // 1.2.0: the 1.1.1 release as tagged
  const changed111 = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => x.endsWith('.lua')).map((x) => a + '/' + x)).filter((x) => git111('addons/' + x) !== now111('addons/' + x));
  const lines111 = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff111 = (rel) => { const c = new Map(); for (const l of lines111(git111(rel))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines111(now111(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  const tDiff111 = diff111('addons/BushidoPrivateRestore/Transform.lua');
  check('1.1.1 hotfix scope: since 1.1.0 only Transform.lua (the parchment row text colour), Restore.lua (version, message, the text applied at login), Options.lua (one description) and the version number in Theme.lua changed; Banzai Art, the panels, the assets, Character Sync and the role layouts untouched',
    changed111.sort().join() === 'BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Transform.lua'
    && tDiff111.sort().join('|') === '+ink = { 0.96, 0.95, 0.92, 1 },|-ink = { 0.13, 0.11, 0.08, 1 },'
    && diff111('addons/BushidoPrivateCompat/Theme.lua').sort().join('|') === "+Theme.VERSION = '1.1.1'|-Theme.VERSION = '1.1.0'" /* the tags: 1.1.1 vs 1.1.0 */
    && diff111('addons/BushidoPrivateRestore/Options.lua').every((l) => /HARDKORH PARCHMENT/.test(l)) && diff111('addons/BushidoPrivateRestore/Options.lua').length === 2,
    `changed: ${changed111.join(', ')}; Transform: ${tDiff111.join(' ')}`);
}

// 18. BANZAI 1.2.0: Banzai Square action buttons, the chat flush-left, the BUFFS panel; read from the built code / configuration / media
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const theme = src('Theme.lua'); const buttons = src('ActionButtons.lua');
  const options = rsrc('Options.lua'); const restore = rsrc('Restore.lua'); const sync = rsrc('Sync.lua');
  const T = transformSource;
  const tgaLib = require('./lib/tga');
  const bamboo = require('./lib/bamboo');
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const now = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  const media = (name) => tgaLib.read(path.join(DIST, 'BushidoPrivateCompat', 'media', name + '.tga'));
  // A. scope: since 1.1.1 only the three asked-for pieces
  const files = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => x.endsWith('.lua')).map((x) => a + '/' + x));
  const changed = files.filter((x) => git('addons/' + x, 'banzai-1.1.1') !== git('addons/' + x, 'banzai-1.2.0')); // 1.2.1: the 1.2.0 release as tagged
  check('1.2.0 scope: since 1.1.1 only ActionButtons.lua (Banzai Square), Compat.lua (chat flush-left, BUFFS panel), Theme.lua (version, settings, migration), Options.lua, Restore.lua, Sync.lua (the WHAT SYNCS text) and Transform.lua (button text places, buffs / debuffs movers, the chat place) changed; unit frames, PvP, cast history, cooldown bars, tracker, minimap, Details, bottom panel, AFK screen, tooltips, preview and role layouts untouched',
    changed.sort().join() === 'BushidoPrivateCompat/ActionButtons.lua,BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Sync.lua,BushidoPrivateRestore/Transform.lua'
    && git('addons/BushidoPrivateRestore/Roles.lua', 'banzai-1.1.1') === git('addons/BushidoPrivateRestore/Roles.lua', 'banzai-1.2.0'), changed.join(', '));
  check('1.2.0 approved pieces kept in the changed files: Details placement (DETAILS numbers, PlaceDetails), the minimap frame, the panel material (bamboo assets, PANEL, PaintBamboo), the parchment row ink, the unit-frame end art',
    ['addons/BushidoPrivateCompat/Compat.lua'].every((rel) => [/Compat\.DETAILS = \{[\s\S]*?\n\}/, /function Compat:PlaceDetails[\s\S]*?\nend/, /function Compat:BuildMinimap[\s\S]*?\nend/, /Compat\.PANEL = \{[\s\S]*?\}/, /local function PaintBamboo[\s\S]*?\nend/, /local function Bundle[\s\S]*?\nend/, /local function EndArt[\s\S]*?\nend/]
      .every((r) => { const a0 = (git(rel, 'banzai-1.1.1') || '').match(r); const b0 = (git(rel, 'banzai-1.3.5') || '').replace(/\n\t-- 1\.3\.5 the divider: with the frame, while both meters are open\n\tif frame\.divider then\n(\t\t[^\n]*\n)+\tend(?=\nend)/, '').match(r); return a0 && b0 && a0[0] === b0[0]; })) /* 1.3.5: PlaceDetails also places the DAMAGE | HEALING divider (block 25); everything before it unchanged. 1.3.6: read from the banzai-1.3.5 tag - 1.3.6 narrows the two windows around the centre gutter on purpose (Compat.DETAILS width / gap); block 26 checks that only that line changed since */
    && /ink = \{ 0\.96, 0\.95, 0\.92, 1 \}/.test(T) && ['tools/lib/panel.js'].every((rel) => { const cut = (x) => (x || '').split('// ---- frame geometry')[0]; return cut(git(rel, 'banzai-1.1.1')) === cut(git(rel, 'banzai-1.3.6')) && cut(git(rel, 'banzai-1.3.6')).length > 1000; }) /* the bamboo / parchment assets byte-for-byte as in 1.1.1 (only the preview layout learnt the flush-left chat); 1.3.7: read up to the banzai-1.3.6 tag - 1.3.7 replaces the parchment generator on purpose, block 27 checks the bamboo part is unchanged since */);
  // B. Banzai Square buttons
  check('1.2.0 BUTTON STYLE: SQUARE (Banzai Square, the default) | CIRCLE (Banzai Circles, kept as an option) | ELVUI (ElvUI Square, the fallback); 1.1.x\'s BANZAI (circles at the time) becomes SQUARE once (schema 8), an ElvUI choice is kept, an unknown value falls back; the same three in the options and in the profile writer',
    /actionStyle = 'SQUARE'/.test(theme) && /Theme\.ACTION_STYLES = \{ 'SQUARE', 'CIRCLE', 'ELVUI' \}/.test(theme) && /\[8\] = function\(db\)[\s\S]*?if db\.actionStyle == 'BANZAI' then db\.actionStyle = 'SQUARE' end/.test(theme)
    && /if db\.actionStyle ~= 'SQUARE' and db\.actionStyle ~= 'CIRCLE' and db\.actionStyle ~= 'ELVUI' then db\.actionStyle = 'SQUARE' end/.test(theme)
    && /\{ SQUARE = 'Banzai Square', CIRCLE = 'Banzai Circles', ELVUI = 'ElvUI Square' \}, \{ 'SQUARE', 'CIRCLE', 'ELVUI' \}/.test(options) && /Section\(10, 'BUTTON STYLE'/.test(options)
    && /function T\.ButtonStyle\(style\)/.test(T) && /local style = T\.ButtonStyle\(opts\.actionStyle\)/.test(T) && /actionStyle = T\.ButtonStyle\(CompatSetting\('actionStyle', 'SQUARE'\)\)/.test(restore));
  check('1.2.0 Banzai Square on the main cluster only (bars 1 + 6, the circles\' place): the icon keeps its square picture (no circular crop, no extra crop of ElvUI\'s texcoords), mask with chamfered corners on the icon and its overlays, a thin border, a square swipe and proc halo, the black backdrop cleared, no glass over the icon; nothing secure created or hooked',
    /SQUARE = \{ mask = Theme\.MEDIA \.\. 'BanzaiSquareMask', ring = Theme\.MEDIA \.\. 'BanzaiSquareBorder', swipe = Theme\.MEDIA \.\. 'BanzaiSquareSwipe',\s+glow = Theme\.MEDIA \.\. 'BanzaiSquareGlow', glowScale = 1\.5 \}/.test(buttons)
    && /ActionButtons\.CIRCLE_BARS = \{ \[1\] = true, \[6\] = true \}/.test(buttons) && /if on and entry\.cluster then/.test(buttons) && /local MASK, RING = shape\.mask, shape\.ring/.test(buttons)
    && !/SetTexCoord/.test(strip0(buttons)) && /texture:AddMaskTexture\(parts\.mask\)/.test(buttons) && /SetBackdropHidden\(button, true\)/.test(buttons)
    && !/hooksecurefunc|HookScript|SetAttribute|OnUpdate/.test(strip0(buttons)));
  // Darren's button in whole screen pixels, as ElvUI sizes it (E:Scale: the units rounded down to a pixel multiple)
  const mult = (768 / 1440) / 0.71; const P39 = Math.floor(30 / mult + 1e-9);
  const sq = bamboo.SQUARE;
  const border = media('BanzaiSquareBorder' + P39); const mask = media('BanzaiSquareMask'); const border128 = media('BanzaiSquareBorder128'); const swipe = media('BanzaiSquareSwipe');
  const alphaRow = (img, y) => [...Array(img.w).keys()].map((x) => img.px[(y * img.w + x) * 4 + 3]);
  const off = Math.floor((64 - P39) / 2);
  const allCrisp = sq.sizes.every((p0) => { const r = alphaRow(media('BanzaiSquareBorder' + p0), 32); const o = Math.floor((64 - p0) / 2);
    return r.slice(o - 3, o + 4).join() === '0,166,255,255,255,0,0' && r.slice(o + p0 - 3, o + p0 + 4).join() === '0,255,255,255,166,0,0'; });
  const mid128 = alphaRow(border128, 64);
  check('1.2.0 square border crisp at Darren\'s real button (ElvUI: 30 units = ' + P39 + ' px): a drawing for every whole-pixel width 34 .. 42 px laid 64 screen pixels wide on its exact offset (one texel per pixel), every straight edge on a pixel boundary - a 1 px dark line and a 3 px band, 2 px outside / 2 px inside the button, nothing half-covered; other widths the 80 px drawing scaled',
    P39 === 39 && allCrisp && mid128.slice(19, 31).join() === '0,166,166,255,255,255,255,255,255,0,0,0' && sq.outer === 2 && sq.inner === 2 && sq.line === 1
    && /local off = math\.floor\(\(S\.canvas - p\) \/ 2\) \/ scale/.test(buttons) && /ring:SetSize\(S\.canvas \/ scale, S\.canvas \/ scale\)/.test(buttons) && /ring:SetPoint\('TOPLEFT', button, 'TOPLEFT', -off, off\)/.test(buttons)
    && /local p = math\.floor\(pixels \+ 0\.5\)/.test(buttons) && /ActionButtons\.SQUARE_PX = \{ min = 34, max = 42, canvas = 64 \}/.test(buttons),
    `39 px row ${alphaRow(border, 32).slice(off - 3, off + 4).join(',')} ... ${alphaRow(border, 32).slice(off + P39 - 3, off + P39 + 4).join(',')}`);
  // the picture a 39 px button shows: the mask stretched over the button, the border 1:1
  let pictureSq = 0; let pictureCircle = 0;
  const cMask = media('BanzaiButtonMask'); const cRing = media('BanzaiButtonRing');
  const a = (img, x, y) => img.px[(Math.min(img.h - 1, Math.max(0, y)) * img.w + Math.min(img.w - 1, Math.max(0, x))) * 4 + 3] / 255;
  for (let y = 0; y < P39; y++) for (let x = 0; x < P39; x++) {
    const mx = Math.floor((x + 0.5) / P39 * 64); const my = Math.floor((y + 0.5) / P39 * 64);
    pictureSq += a(mask, mx, my) * (1 - a(border, off + x, off + y));
  }
  for (let y = 12; y < 52; y++) for (let x = 12; x < 52; x++) pictureCircle += a(cMask, x, y) * (1 - a(cRing, x, y));
  pictureSq /= P39 * P39; pictureCircle /= 1600;
  const cornerCut = a(mask, 3, 3) === 0 && a(mask, 32, 3) === 1;
  // the swipe over the 37 px icon ends inside the border's inner edge (LibActionButton anchors every cooldown to the icon)
  const iconPx = P39 - 2; let swipeOnBorder = 0;
  for (let y = 0; y < iconPx; y++) for (let x = 0; x < iconPx; x++) {
    const sa = a(swipe, Math.floor((x + 0.5) / iconPx * 64), Math.floor((y + 0.5) / iconPx * 64));
    swipeOnBorder = Math.max(swipeOnBorder, sa * a(border, off + 1 + x, off + 1 + y));
  }
  check('1.2.0 spell picture preserved: the square shows at least 1.8x the picture the circles showed (share of the button not hidden by the mask or the border), its corners cut by a small chamfer only; the cooldown swipe (on the icon) never darkens the border',
    pictureSq >= 0.78 && pictureSq >= 1.8 * pictureCircle && cornerCut && a(swipe, 32, 32) === 1 && a(swipe, 0, 0) === 0 && swipeOnBorder < 0.2,
    `square ${(100 * pictureSq).toFixed(1)} % of the button, circles ${(100 * pictureCircle).toFixed(1)} %, swipe over the border ${swipeOnBorder.toFixed(2)}`);
  const SQ = (T.match(/T\.SQUARE = \{[^\n]*/) || [''])[0];
  check('1.2.0 square text: the keybind compact at the top-right inside the border (Bushido\'s size, the small font, outline + shadow - not the circles\' large centred keybind), the count bottom-centre at its reduced size clear of the border, the cooldown numbers in the middle; ElvUI\'s and Eltruism\'s proc glows and Eltruism\'s black shadows off; cluster size and place unchanged',
    /hotkeyScale = 1, hotkey = \{ 'TOPRIGHT', -3, -3 \}, count = \{ 'BOTTOM', 0, 2 \}, cooldown = \{ 'CENTER', 0, -0\.5, 11 \}/.test(SQ)
    && /local on, square = style ~= 'ELVUI', style == 'SQUARE'/.test(T) && /db\.countFontSize = math\.floor\(\(old\.countFontSize or 10\) \* L\.count \+ 0\.5\)/.test(T)
    && /Ensure\(p, 'actionbar'\)\.handleOverlay = \(not on\) and \(hist ~= false\) or false/.test(T) && /glow\.procglow = \(not on\)/.test(T) && /shadow\.actionbars = \(not on\)/.test(T)
    && /T\.ApplyActionMovers\(p, historical, opts\.barHeight, style ~= 'ELVUI', opts\.actionLook\)/.test(T));
  // C. chat flush-left
  const C = (compat.match(/Compat\.CHAT = \{[^}]*\}/) || [''])[0];
  const chatLeft = num(C, /left = (-?[0-9.]+)/); const contentX = num(C, /contentX = ([0-9.]+)/); const fw = num(C, /width = ([0-9.]+)/);
  const outer = num(compat, /Compat\.BAND = \{[^}]*outer = ([0-9.]+)/);
  check('1.2.0 chat flush with the left screen edge: the left stalk\'s outer edge on the edge (within a quarter unit), the ElvUI chat panel moved with it (whole-unit x), same width / height / bottom; frame, background, title, text, tabs and input move together (one mover, one frame); Details not moved',
    chatLeft + outer <= 0 && chatLeft + outer > -0.25 && Math.abs(contentX - (chatLeft + (fw - 430) / 2)) < 1e-6 && Number.isInteger(contentX)
    && /T\.CHAT = \{ x = 31, inset = 10, width = 430, height = 140 \}/.test(T) && /frame\.flushLeft = C\.left/.test(compat)
    && /Compat\.DETAILS = \{[\s\S]*?right = -47\.15[\s\S]*?edge = 16,/.test(compat),
    `frame ${chatLeft}, left stalk at ${(chatLeft + outer).toFixed(3)}, panel x ${contentX}`);
  // D. BUFFS panel
  const build = body(compat, 'function Compat:BuildBuffs()'); const place = body(compat, 'function Compat:PlaceBuffs(active)');
  check('1.2.0 BUFFS panel: one Banzai frame (built once, with the other screen pieces) in the shared panel material (border, background, border scale, glass opacity, parchment brightness: the same painter as chat / Details / minimap), BUFFS on its BOTTOM stalk, behind the buffs, never taking a click, hidden without ElvUI\'s buff header or off the Banzai profile',
    /self:BuildBuffs\(\)/.test(body(compat, 'function Compat:Build()')) && /if not self\.screenBuilt then/.test(body(compat, 'function Compat:Build()'))
    && /NewHolder\(UIParent, 'BACKGROUND', 100, 100\)/.test(build) && /BambooFrame\(frame, false, false\)/.test(build) && /title\.fixedStyle, title\.bottom = self\.BUFFS_TITLE, true/.test(build)
    && /if t\.bottom then -- 1\.2\.0 BUFFS: the middle of the bottom stalk\n\t\tt:SetPoint\('CENTER', chassis, 'TOPLEFT', center, -\(chassis\.bh - line\)\)/.test(compat)
    && /Compat\.BUFFS_TITLE = \{ text = 'BUFFS'/.test(compat) && /holder:EnableMouse\(false\)/.test(body(compat, 'local function NewHolder')) && /t:EnableMouse\(false\)/.test(body(compat, 'function Compat:DetailsTitle'))
    && /local visible = active and db\.buffsPanel and BuffsHeader\(\) ~= nil and true or false/.test(place) && /local anchor = _G\.BuffsMover or BuffsHeader\(\)/.test(place)
    && /buffs = function\(x, y\) return 0\.5 \* x \+ 0\.5 \* y end/.test(compat));
  const B = Object.fromEntries([...((T.match(/T\.BUFFS_PANEL = \{([^}]*)\}/) || [])[1] || '').matchAll(/(\w+) = ([0-9.]+)/g)].map((m) => [m[1], Number(m[2])]));
  const CB = Object.fromEntries([...((compat.match(/Compat\.BUFFS = \{([^}]*)\}/) || [])[1] || '').matchAll(/(\w+) = ([0-9.]+)/g)].map((m) => [m[1], Number(m[2])]));
  check('1.2.0 BUFFS panel compact: ElvUI\'s own buff icons at the approved 70 % size, Bushido\'s 10 per row and row gap, 2 rows (3 at most); the panel sized for exactly that (room under the last row for its durations and the title), the debuffs separate, below the panel, a row kept free for ElvUI\'s weapon-enchant icons and its bamboo ends (1.2.1: the panel no longer grows - see the 1.2.1 block); off (or without Banzai Art): the 1.0 places exactly',
    B.perRow === 10 && B.rows === 2 && B.padBottom === CB.padBottom && CB.perRow === 10 && B.frame === 10.5 && B.ends === 10 && B.gap >= 6
    && /buffs\.wrapAfter, buffs\.maxWraps = B\.perRow, panel\.rows/.test(T) && /movers\.DebuffsMover = string\.format\('TOPLEFT,UIParent,TOPLEFT,%d,%d', panel\.x, -debuffY\)/.test(T)
    && /movers\.BuffsMover, movers\.DebuffsMover = T\.AURAS\.buffs, T\.AURAS\.debuffs/.test(T) && /rows = \(tonumber\(panel\.rows\) == 3\) and 3 or 2/.test(T)
    && /local block = \(panel\.rows \+ 1\) \* height \+ panel\.rows \* buffs\.verticalSpacing -- \+ the weapon-enchant row/.test(T) && /if keep == nil then keep = true end/.test(T)
    && CB.padBottom >= 3 + 8 + 3.5 + 2 /* durations: 3 under the icon + half of 16; the title reaches 3.5 above the stalk */, JSON.stringify(B));
  check('1.2.0 BUFFS panel safe with the game\'s buffs: no aura is read, cancelled, hooked or re-created by Banzai (ElvUI keeps icons, tooltips, right-click cancelling and timers); position / rows written into the profile and applied through ElvUI\'s own mover update and buff header update, out of combat only (after combat otherwise)',
    !/UnitAura|C_UnitAuras|CancelUnitBuff|CancelSpellByName|GetPlayerAuraBySpellID|AuraUtil/.test(strip0(compat) + strip0(restore) + strip0(T))
    && /if InCombatLockdown\(\) then\n\t\tself\.buffsPending = true/.test(body(restore, 'function Restore:ApplyBuffsLayout')) && /pcall\(E\.SetMoversPositions, E\)/.test(body(restore, 'function Restore:ApplyBuffsLayout'))
    && /pcall\(A\.UpdateHeader, A, A\.BuffFrame\)/.test(body(restore, 'function Restore:ApplyBuffsLayout')) && /buffsEvents:RegisterEvent\('PLAYER_REGEN_ENABLED'\)/.test(restore)
    && /on = _G\.BanzaiCompat ~= nil and CompatSetting\('buffsPanel', true\) ~= false/.test(restore)
    && body(restore, 'function Restore:ApplyBuffsLayout').indexOf('self.buffsPending = nil') < body(restore, 'function Restore:ApplyBuffsLayout').indexOf('GetCurrentProfile() == T.PROFILE'));
  check('1.2.0 GUI: ACTION BARS > BUTTON STYLE (Banzai Square / Banzai Circles / ElvUI Square); LAYOUT > BUFFS PANEL (on, maximum rows 2 / 3, buff size, position X / Y, reset); concise',
    /auras = Section\(30, 'BUFFS PANEL'/.test(options) && ['buffsPanel', 'buffsRows', 'buffScale', 'buffsX', 'buffsY', 'buffsReset'].every((k) => new RegExp('\\t' + k + ' = ').test(options))
    && /\{ \[2\] = '2 rows \(20 buffs\)', \[3\] = '3 rows \(30 buffs\)' \}, \{ 2, 3 \}/.test(options));
  check('1.2.0 Character Sync carries the button style and the BUFFS panel (on, rows, position: BANZAI settings, exported with every other) and the buff size (the unit layout); never the buffs or other gameplay data; the WHAT SYNCS text says so; the layer carries them to the shared profile at login',
    ["actionStyle = 'SQUARE'", 'buffsPanel = true', 'buffsRows = 2', 'buffsX = 30', 'buffsY = 30'].every((k) => theme.includes(k)) && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme)
    && /button style: Banzai Square \/ Banzai Circles \/ ElvUI Square\), BUFFS panel \(on, rows, position; never the buffs themselves\)/.test(sync)
    && /buffsPanel = self:BuffsPanel\(\), -- 1\.2\.0/.test(restore) && /chatX = T\.CHAT\.x/.test(restore) && /T\.ApplyAuras\(p, opts\.buffScale, historical, opts\.buffsPanel\)/.test(T)
    && /layout = \{ buffScale = own\.layout\.buffScale/.test(sync) && /Sync\.CHARACTER_OWN = \{ 'cdTracked' \}/.test(sync));
  check('1.2.0 migration / rollback: schema 8 (BANZAI -> SQUARE), buffs settings bounded on every read (rows 2 / 3, the panel on the screen); the saved variables, the profile name and T.LAYER unchanged; the upgrade message names the three changes',
    /Theme\.SCHEMA = 8/.test(theme) && /if db\.buffsRows ~= 2 and db\.buffsRows ~= 3 then db\.buffsRows = 2 end/.test(theme) && /Theme\.BUFFS_POSITION = \{ min = 26, maxX = 900, maxY = 600 \}/.test(theme)
    && /T\.LAYER = 12\b/.test(T) && compatToc.fields.SavedVariables === 'BanzaiCompatDB' && restoreToc.fields.SavedVariables === 'BushidoPrivateRestoreDB'
    && /BANZAI SQUARE action buttons \(BANZAI > ACTION BARS: square, circles or ElvUI\), the chat flush with the left screen edge, the BUFFS panel at the top-left/.test(git('addons/BushidoPrivateRestore/Restore.lua', 'banzai-1.2.1') || '')); // 1.3.0 replaced the message
  check('1.2.0 performance: no OnUpdate in Banzai Art\'s frames or buttons, no new ticker; the BUFFS panel sized and laid out only on refresh (settings, profile) and skipped when unchanged',
    !/OnUpdate/.test(strip0(compat) + strip0(buttons)) && (strip0(compat).match(/C_Timer\.NewTicker\(/g) || []).length === 1
    && /if frame\.bw ~= W or frame\.bh ~= H then/.test(body(compat, 'function Compat:SizeBuffs()')) && /if holder\.layoutKey == key then return end/.test(compat));
}

// 19. BANZAI 1.2.1: Midnight secret-value hotfix for the BUFFS panel, read from the built code
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const compat = src('Compat.lua'); const restore = rsrc('Restore.lua'); const T = transformSource;
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const now = (rel) => fs.readFileSync(path.join(ROOT, rel), 'utf8').replace(/\r\n/g, '\n');
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff = (rel) => { const c = new Map(); for (const l of lines(git(rel, 'banzai-1.2.0'))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(git(rel, 'banzai-1.2.1'))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); }; // 1.3.0: the release as tagged
  // A. scope: only the BUFFS overflow code went, plus the version
  const files = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => x.endsWith('.lua')).map((x) => a + '/' + x));
  const changed = files.filter((x) => git('addons/' + x, 'banzai-1.2.0') !== git('addons/' + x, 'banzai-1.2.1') && git('addons/' + x, 'banzai-1.2.1') !== null);
  const cDiff = diff('addons/BushidoPrivateCompat/Compat.lua');
  check('1.2.1 scope: since 1.2.0 only Compat.lua (the BUFFS overflow check and its aura watcher removed, the rows from the settings), the version (Theme.lua, Restore.lua with its login message) and a comment in Transform.lua changed - action buttons, chat, panel material, Details, minimap, unit frames, PvP, objectives, bottom panel, tooltips, AFK, Character Sync untouched',
    changed.sort().join() === 'BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Transform.lua'
    && cDiff.length > 0 && cDiff.filter((l) => l.startsWith('+')).every((l) => l === '+local rows = Theme:DB().buffsRows' || l === "+local function num(v, default) return (type(v) == 'number' and v > 0) and v or default end")
    /* Compat: code removed; the rows from the settings, ElvUI's numbers without a secret check */
    && diff('addons/BushidoPrivateRestore/Transform.lua').length === 0 /* comment only */
    && diff('addons/BushidoPrivateCompat/Theme.lua').sort().join('|') === "+Theme.VERSION = '1.2.1'|-Theme.VERSION = '1.2.0'"
    && diff('addons/BushidoPrivateRestore/Restore.lua').length === 4 /* the version and the login message */,
    `changed: ${changed.join(', ')}; Compat: ${cDiff.filter((l) => l.startsWith('+')).join(' ') || 'removals only'}`);
  // B. the BUFFS code never reads ElvUI's buff icons or aura state
  const buffs = compat.slice(compat.indexOf('-- 1.2.0 BUFFS panel (top-left)'), compat.indexOf('-- BANZAI wordmark'));
  const forbidden = /[.:]\s*Is(Shown|Visible)\b|GetChildren|GetAttribute|GetNumChildren|GetRegions|GetAlpha\(|UNIT_AURA|UNIT_INVENTORY_CHANGED|PLAYER_EQUIPMENT_CHANGED|C_UnitAuras|UnitAura|UnitBuff|GetWeaponEnchantInfo|AuraUtil|issecretvalue|IsSecret\(|OnUpdate|C_Timer|RegisterEvent|RegisterUnitEvent|SetScript|extraRow|CheckBuffsOverflow|buffsWatch|buffsCheck/;
  const hit = (strip0(buffs).match(forbidden) || [])[0];
  check('1.2.1 BUFFS panel code reads no buff icon, header child, visibility, aura, duration, stack or weapon-enchant state (no IsShown / GetChildren / aura API / aura events / timers / secret checks in it); its geometry comes from Banzai\'s rows and ElvUI\'s buff settings only',
    buffs.length > 1000 && !hit && /local rows = Theme:DB\(\)\.buffsRows\n/.test(body(compat, 'function Compat:BuffsBlock()')) && /E\.db\.auras\.buffs/.test(body(compat, 'function Compat:BuffsBlock()'))
    && !/CheckBuffsOverflow|buffsWatch|extraRow|buffsCheck/.test(strip0(compat)), hit ? 'found: ' + hit : 'clean');
  check('1.2.1 nothing else of 1.2.0 tests or counts aura-derived state: the BUFFS functions in Banzai (settings, layout) and the profile writer use configuration values only',
    !/UnitAura|C_UnitAuras|GetWeaponEnchantInfo|UNIT_AURA|GetChildren|:IsShown\(/.test(strip0(body(restore, 'function Restore:BuffsPanel()') + body(restore, 'function Restore:SetBuffsPanel') + body(restore, 'function Restore:ApplyBuffsLayout') + body(T, 'function T.ApplyAuras') + body(T, 'function T.BuffsPanel')))
    && ['Compat.lua', 'ActionButtons.lua', 'Theme.lua'].every((f0) => !/UNIT_AURA|UNIT_INVENTORY_CHANGED|PLAYER_EQUIPMENT_CHANGED/.test(strip0(src(f0)))) /* the files 1.2.0 touched */);
}

// 20. BANZAI 1.3.0: optional BANZAI SPLIT unit frames + party + BANZAI COMPACT Details - 1.3.1: read from the banzai-1.3.0 tag
// (the record of what 1.3.0 shipped; 1.3.1's corrections are checked in block 21; generated files from dist/)
{
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const TAG130 = 'banzai-1.3.0';
  const generated = new Set(['IdentityManifest.lua', 'Geometry.lua', 'Payloads.lua']);
  const src = (name) => (generated.has(name) ? fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8') : git('addons/BushidoPrivateCompat/' + name, TAG130) || '');
  const rsrc = (name) => git('addons/BushidoPrivateRestore/' + name, TAG130) || '';
  const split = src('Split.lua'); const identity = src('Identity.lua'); const health = src('Health.lua'); const plate = src('TargetPlate.lua');
  const compat = src('Compat.lua'); const theme = src('Theme.lua'); const preview = src('Preview.lua');
  const restore = rsrc('Restore.lua'); const options = rsrc('Options.lua'); const sync = rsrc('Sync.lua'); const T = rsrc('Transform.lua');
  const now = (rel) => git(rel, TAG130); // 1.3.1: the 1.3.0 release itself
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const added = (rel) => { const c = new Map(); for (const l of lines(git(rel, 'banzai-1.2.1'))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(now(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  // A. scope
  const all = execSync(`git ls-tree -r --name-only ${TAG130} addons`, { cwd: ROOT, encoding: 'utf8' }).split(/\r?\n/).filter((x) => /^addons\/BushidoPrivate(Compat|Restore)\/[^/]+\.lua$/.test(x)).map((x) => x.slice(7));
  const changed = all.filter((x) => git('addons/' + x, 'banzai-1.2.1') !== now('addons/' + x));
  check('1.3.0 scope: since 1.2.1 only the new Split.lua, Health / Identity / TargetPlate / Preview (split definitions beside the classic ones), Theme (version, the style settings), Compat (no plates / bamboo / combat move in a split session), Options, Restore, Sync and Transform changed - action buttons, PvP frames, cast history, cooldown bars, tags, bottom panel, tracker, tooltips, AFK, role layouts untouched',
    changed.sort().join() === 'BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/Health.lua,BushidoPrivateCompat/Identity.lua,BushidoPrivateCompat/Preview.lua,BushidoPrivateCompat/Split.lua,BushidoPrivateCompat/TargetPlate.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Sync.lua,BushidoPrivateRestore/Transform.lua', changed.join(', '));
  const cAdded = added('addons/BushidoPrivateCompat/Compat.lua');
  check('1.3.0 Compat.lua: only the split guards added (the split frame list, the session in Build and UpdateBranding, Split among the modules); every approved function byte-for-byte as in 1.2.1 (Details, chat, minimap, BUFFS, bamboo, end art, decoration, combat logo placement, titles)',
    cAdded.filter((l) => l.startsWith('-')).every((l) => /^-local combat = active and db\.combatLogo and self\.inCombat and true or false$|^-Decorate\(_G\[def\.frame\], def\.parts|^-local MODULES = /.test(l))
    && cAdded.filter((l) => l.startsWith('+')).length <= 7
    && [/function Compat:PlaceDetails[\s\S]*?\nend/, /function Compat:BuildMinimap[\s\S]*?\nend/, /local function LayoutBamboo[\s\S]*?\nend/, /local function PaintBamboo[\s\S]*?\nend/, /local function Bundle[\s\S]*?\nend/, /local function EndArt[\s\S]*?\nend/,
      /local function Decorate[\s\S]*?\nend/, /function Compat:BuildDetails[\s\S]*?\nend/, /function Compat:BuildChat[\s\S]*?\nend/, /function Compat:SizeBuffs[\s\S]*?\nend/, /function Compat:PlaceBuffs[\s\S]*?\nend/,
      /function Compat:LayoutDetailsTitle[\s\S]*?\nend/, /function Compat:PlaceCombatLogo[\s\S]*?\nend/, /function Compat:BuildCombatLogo[\s\S]*?\nend/, /function Compat:Refresh\(\)[\s\S]*?\nend/]
      .every((r) => { const a0 = (git('addons/BushidoPrivateCompat/Compat.lua', 'banzai-1.2.1') || '').match(r); const b0 = now('addons/BushidoPrivateCompat/Compat.lua').match(r); return a0 && b0 && a0[0] === b0[0]; }),
    cAdded.join(' | '));
  check('1.3.0 classic code kept in the changed Banzai Art files: Health (the classic definitions, Attach, BuildFor, Style), Identity (Circle, Paint, Icon, SpecOf, the classic placing), TargetPlate (Build, Color, the gradient), Preview (BuildUnit, BuildSingle, BuildGroup, Furnish) byte-for-byte as in 1.2.1',
    [['Health.lua', [/Health\.UNITS = \{[\s\S]*?\n\}/, /Health\.GROUPS = \{[\s\S]*?\n\}/, /function Health:Attach[\s\S]*?\nend/, /function Health:BuildFor[\s\S]*?\nend/, /local function Style[\s\S]*?\nend/]],
      ['Identity.lua', [/function Identity\.Circle[\s\S]*?\nend/, /function Identity\.Paint\([\s\S]*?\nend/, /function Identity\.Icon[\s\S]*?\nend/, /function Identity\.SpecOf[\s\S]*?\nend/, /local function Place\(c, frame, side\)[\s\S]*?\nend/]],
      ['TargetPlate.lua', [/local function Build\(frame\)[\s\S]*?\nend/, /function TargetPlate\.Color[\s\S]*?\nend/, /TargetPlate\.REACTION = \{[\s\S]*?\n\}/]],
      ['Preview.lua', [/local function BuildUnit[\s\S]*?\nend/, /function Preview:BuildSingle[\s\S]*?\nend/, /function Preview:BuildGroup[\s\S]*?\nend/, /local function Furnish[\s\S]*?\nend/]]]
      .every(([f0, res]) => res.every((r) => { const a0 = (git('addons/BushidoPrivateCompat/' + f0, 'banzai-1.2.1') || '').match(r); const b0 = now('addons/BushidoPrivateCompat/' + f0).match(r); return a0 && b0 && a0[0] === b0[0]; })));
  // B. BANZAI CLASSIC behaviourally unchanged: the 1.2.1 and the 1.3.0 profile writers in the Lua VM, the same input
  let classicSame = false; let roundTrip = false; let detailsSame = false; let splitLeaves = []; let vmError = '';
  try {
    const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
    const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
    const q = (x) => JSON.stringify(x.replace(/\\/g, '/'));
    const oldT = path.join(ROOT, 'build', 'validate-Transform-1.2.1.lua');
    fs.mkdirSync(path.dirname(oldT), { recursive: true });
    fs.writeFileSync(oldT, git('addons/BushidoPrivateRestore/Transform.lua', 'banzai-1.2.1') || '');
    const newT = path.join(ROOT, 'build', 'validate-Transform-1.3.0.lua'); // 1.3.1: the 1.3.0 release
    fs.writeFileSync(newT, T);
    const prog = `
      local function load(file) local ns = {} assert(loadfile(file))('x', ns) return ns end
      local P = load(${q(path.join(DIST, 'BushidoPrivateRestore', 'Payloads.lua'))}).Payloads
      local Old, New = load(${q(oldT)}).Transform, load(${q(newT)}).Transform
      local fonts = { display = 'GasoekOne', small = 'Rubik-Bold' }
      local opts = { healthInside = true, healthPercent = true, barHeight = 32, smoothBars = true, actionStyle = 'SQUARE', frameWidth = 0.5, totScale = 0.72, identityCircles = true, roleIcons = true, role = 'DPS', roleContext = 'world', tooltipTheme = 'BANZAI', afk = true }
      local base = Old.TransformProfile(P.elvuiProfile, 'GasoekOne', nil, 'Rubik-Bold', opts)
      local a, b = Old.DeepCopy(base), Old.DeepCopy(base)
      Old.ApplyCharacterLayer(a, P.elvuiProfile, fonts, opts)
      New.ApplyCharacterLayer(b, P.elvuiProfile, fonts, opts)
      CLASSIC = Old.Serialize(a) == New.Serialize(b)
      local state = {}
      local o2 = New.DeepCopy(opts) o2.splitState = state o2.frameStyle = 'SPLIT'
      local c = New.DeepCopy(b)
      New.ApplyCharacterLayer(c, P.elvuiProfile, fonts, o2)
      SPLIT_DIFFERS = New.Serialize(c) ~= New.Serialize(b)
      local o3 = New.DeepCopy(opts) o3.splitState = state
      New.ApplyCharacterLayer(c, P.elvuiProfile, fonts, o3)
      ROUND = SPLIT_DIFFERS and New.Serialize(c) == New.Serialize(b)
      local paths = {}
      for _, leaf in ipairs(New.SplitLeaves(b, P.elvuiProfile, fonts, { frameStyle = 'SPLIT' })) do paths[#paths + 1] = table.concat(leaf.path, '.') end
      LEAVES = table.concat(paths, '\\n')
      local d1, d2 = Old.DeepCopy(P.detailsProfile), Old.DeepCopy(P.detailsProfile)
      Old.StyleDetailsWindows(d1, true, fonts)
      New.StyleDetailsWindows(d2, true, fonts, 'CURRENT', New.DETAILS_ICONS.fabled)
      DETAILS = Old.Serialize(d1) == New.Serialize(d2)
    `;
    if (lauxlib.luaL_loadstring(L, to_luastring(prog)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) vmError = to_jsstring(lua.lua_tostring(L, -1));
    const get = (name) => { lua.lua_getglobal(L, to_luastring(name)); const v = lua.lua_toboolean(L, -1); lua.lua_pop(L, 1); return v; };
    classicSame = get('CLASSIC'); roundTrip = get('ROUND'); detailsSame = get('DETAILS');
    lua.lua_getglobal(L, to_luastring('LEAVES')); splitLeaves = (to_jsstring(lua.lua_tostring(L, -1)) || '').split('\n').filter(Boolean); lua.lua_pop(L, 1);
  } catch (e) { vmError = String(e); }
  check('1.3.0 BANZAI CLASSIC unchanged, proven in the Lua VM: the 1.3.0 character layer with the default (CLASSIC) settings writes exactly what 1.2.1 wrote on the same profile (every key, compared as text)', classicSame, vmError || 'identical');
  check('1.3.0 switching is reversible and idempotent: CLASSIC -> SPLIT changes the profile, SPLIT -> CLASSIC gives back exactly the classic profile (the record of the split layer taken back first)', roundTrip, vmError || 'round trip exact');
  check('1.3.0 BANZAI CURRENT Details unchanged: the 1.3.0 Details styling with CURRENT writes exactly what 1.2.1 wrote', detailsSame, vmError || 'identical');
  const leafUnits = [...new Set(splitLeaves.filter((p) => p.startsWith('unitframe.units.')).map((p) => p.split('.')[2]))].sort();
  const leafMovers = splitLeaves.filter((p) => p.startsWith('movers.')).map((p) => p.slice(7)).sort();
  check('1.3.0 the split layer touches only Player, Target, Focus, Target-of-Target and party (never arena / boss / raid / pet frames, never the role-layout keys or movers: party size, spacing, growth, aura size / offset, party / raid / arena / boss movers)',
    leafUnits.join() === 'focus,party,player,target,targettarget' && !splitLeaves.some((p) => /^unitframe\.units\.(arena|boss|raid\d|pet)\./.test(p))
    && !splitLeaves.some((p) => /^unitframe\.units\.party\.(width|height|growthDirection|horizontalSpacing|verticalSpacing|auras\.)/.test(p))
    && leafMovers.join() === 'AdditionalPowerMover,ClassBarMover,ElvUF_FocusMover,ElvUF_PlayerMover,ElvUF_TargetMover,ElvUF_TargetTargetMover,FocusPowerBarMover,PlayerPowerBarMover,TargetPowerBarMover'
    && splitLeaves.every((p) => /^(unitframe\.units\.|movers\.|mMediaTag\.portraits\.)/.test(p)), `${splitLeaves.length} leaves: ${leafUnits.join(', ')}; movers ${leafMovers.join(', ')}`);
  // C. the split construction
  const S = (re) => Number((T.match(re) || [])[1]);
  check('1.3.0 BANZAI SPLIT geometry: Player lower centre (hub 290 above the bottom), Target upper centre (112 below the top); health LEFT of the hub (the ElvUI frame RIGHT-anchored), resource RIGHT of it (its detached power bar LEFT-anchored); not excessively wide (Player 2 x 180 + the hub); the same numbers in Banzai Art and Banzai',
    /leaf\(Mover\('RIGHT', a\.rel, a\.x - g\.inner, a\.y\), 'movers', a\.mover\)/.test(T) && /leaf\(Mover\('LEFT', a\.rel, a\.x \+ g\.inner, a\.y\), 'movers', a\.power\)/.test(T)
    && /player = \{ rel = 'BOTTOM', x = px, y = py/.test(T) && /target = \{ rel = 'TOP', x = tx, y = -ty/.test(T)
    && /splitPlayerY = 290,/.test(theme) && /splitTargetY = 112,/.test(theme) && /defaults = \{ splitPlayerX = 0, splitPlayerY = 290, splitTargetX = 0, splitTargetY = 112/.test(T)
    && ['player', 'target', 'focus'].every((k) => { const a0 = (T.match(new RegExp('\\t' + k + ' = \\{ bar = (\\d+), height = (\\d+)[^}]*hub = (\\d+)')) || []).slice(1).join(); const b0 = (split.match(new RegExp('\\t' + k + " = \\{ frame = '[^']+', unit = '\\w+', bar = (\\d+), height = (\\d+)[^}]*hub = (\\d+)")) || []).slice(1).join(); return a0 && a0 === b0; })
    && S(/player = \{ bar = (\d+)/) * 2 + S(/player = \{ bar = \d+, height = \d+, hub = (\d+)/) < 420
    && /tuck = 0\.16/.test(T) && /Split\.TUCK = 0\.16/.test(split) && /circle = 32/.test(T) && /Split\.PARTY = \{ circle = 32/.test(split));
  check('1.3.0 the split frames are ElvUI\'s own (secure, clickable, the game\'s values): Banzai Art adds the hub, the gradients and the tracks only - no unit frame, secure template, health or power bar of its own; ElvUI\'s player / target / focus cast bars and portraits off, mMediaTag\'s circles off there; the name line one centred custom text across the hub\'s lower part',
    !/Secure\w*Template|RegisterUnitWatch|SetAttribute|UnitHealth\b|UnitPower\(/.test(strip0(split)) && /unit\(key, false, 'castbar', 'enable'\)/.test(T) && /unit\(key, false, 'portrait', 'enable'\)/.test(T)
    && /noPortrait\(key\)/.test(T) && /text\(key, 'b-SplitName', \{ attachTextTo = 'Health', justifyH = 'CENTER', xOffset = Round\(g\.bar \/ 2 \+ g\.inner\), yOffset = -Round\(g\.hub \/ 2 - 5\)/.test(T)
    && /hub:SetPoint\('CENTER', frame\.Health, 'RIGHT', g\.inner, 0\)/.test(split) && /return math\.min\(level \+ 2, 95\)/.test(split) /* under ElvUI's raised texts (100) */);
  check('1.3.0 HP inside the split bars: current value at the outer end, the percent at the end beside the hub (clear of the part it covers), bright over the fill / ghosted over the empty part (Health.lua\'s own two copies), ElvUI\'s own tags; the resource the same way mirrored with ElvUI\'s power tags (a tag the installed ElvUI lacks is left out); party: value after the role icon, percent at the right end',
    /local opposite = \(def\.side == 'LEFT'\) and 'RIGHT' or 'LEFT'/.test(health) && /out\.percentX = g\.tuck \+ Health\.SPLIT_GAP/.test(health) && /Health\.POWER_VALUE_TAGS = \{ '\[power:current:shortvalue\]', '\[curpp\]' \}/.test(health)
    && /Health\.POWER_PERCENT_TAG = '\[perpp<%\]'/.test(health) && /if valueTag then frame:Tag\(set\.value, valueTag\) end/.test(health)
    && /SPLIT_POWER = \{[\s\S]*?side = 'RIGHT'/.test(health) && /SPLIT_PARTY = \{ prefix = 'ElvUF_PartyGroup1UnitButton', count = 5, side = 'LEFT', x = 4, y = 0, percentX = 4/.test(health));
  check('1.3.0 resources: the canonical colour family per power type (mana blue / cyan, energy yellow, rage red, focus orange, runic power, fury, pain, insanity, maelstrom, lunar power, essence) from the game\'s power token; an unknown type keeps ElvUI\'s own colour; an NPC loses its resource side only when the game plainly reports a maximum of 0',
    ['MANA', 'ENERGY', 'RAGE', 'FOCUS', 'RUNIC_POWER', 'FURY', 'PAIN', 'INSANITY', 'MAELSTROM', 'LUNAR_POWER', 'ESSENCE'].every((k) => new RegExp('\\t' + k + ' = \\{ \\{').test(theme))
    && /return type\(token\) == 'string' and Theme\.POWER\[token\] or nil/.test(split) && /local max = Call\(UnitPowerMax, unit\)\n\treturn type\(max\) == 'number' and max <= 0/.test(split));
  // D. cast transformation + secret-value safety
  const cast = split.slice(split.indexOf('-- The cast presentation'), split.indexOf('-- Live frames'));
  check('1.3.0 cast transformation: the spell icon in the hub, the radial progress on the ring (the game\'s duration object into a Cooldown swipe; plain times only when readable), the spell name above the hub, the remaining time formatted by the font string; cast fills, channel / empower drain; INTERRUPTED / FAILED for a moment; then the class art again',
    /hub\.spell:SetTexture\(info\.texture\)/.test(cast) && /cd:SetCooldownFromDurationObject\(info\.duration\)/.test(cast) && /PlainNumber\(info\.startMS\) and PlainNumber\(info\.endMS\) and info\.endMS > info\.startMS/.test(cast)
    && /cd:SetReverse\(info\.kind ~= 'channel'\)/.test(cast) /* review: an empower fills as it charges */ &&/hub\.castTime:SetFormattedText\('%\.1f', remaining\)/.test(cast) && /h\.castName:SetPoint\('BOTTOM', h, 'TOP', 0, 3\)/.test(identity)
    && /'INTERRUPTED' or 'FAILED'/.test(cast) && /Split\.FAIL_HOLD = 0\.8/.test(split) && /if state\.token ~= token then return end/.test(cast) && /UnitEmpoweredChannelDuration/.test(cast)
    && /-- protected timing: the ring says "casting" in the cast colour, no progress is drawn/.test(cast));
  const reads = (strip0(split).match(/\bUnit(CastingInfo|ChannelInfo)\b[^,\n]*/g) || []);
  check('1.3.0 secret values (focused review of Split.lua): the cast APIs only through pcall, a name / empower flag tested only after issecretvalue says it is plain, the non-interruptible flag handed to SetAlphaFromBoolean (or shown only when plainly true), times used only when plain, the remaining time never compared or computed, unit tokens never compared when hidden (events registered per unit), no aura data or widget state read',
    reads.every((r) => /^UnitCastingInfo then|^UnitChannelInfo then|^UnitCastingInfo, unit\)|^UnitChannelInfo, unit\)|^UnitCastingDuration$|^UnitChannelDuration\)|^UnitCastingInfo$|^UnitChannelInfo$/.test(r) || /pcall/.test(r))
    && /local ok, name, _, texture, startMS, endMS, _, _, notInterruptible, _, barID = pcall\(UnitCastingInfo, unit\)/.test(split) && /barID = Plain\(barID\)/.test(split)
    && /local plainID = not IsSecret\(barID\) and barID ~= nil and state\.barID ~= nil/.test(split) && /if \(IsSecret\(by\) or by ~= nil\) and \(plainID or state\.active\) then return 'INTERRUPTED' end/.test(split) /* review: kicked channels / empowers; ids compared only when plain */ &&/if not \(IsSecret\(name\) or name ~= nil\) then/.test(split)
    && /\(not IsSecret\(empowering\) and empowering == true\)/.test(split) && /t:SetAlphaFromBoolean\(notInterruptible, 1, 0\)/.test(split) && /elseif not IsSecret\(notInterruptible\) then\n\t\t\tt:SetShown\(notInterruptible == true\)/.test(split)
    && (strip0(split).match(/notInterruptible/g) || []).length <= 12 /* read, handed to Lock, to the widget, the plain-only branch; never tested anywhere else */
    && !/remaining\s*(==|~=|<=?|>=?|[+\-*\/])|(==|~=|<=?|>=?|[+\-*\/])\s*remaining/.test(body(split, 'local function Tick').replace(/math\.max\(0, hub\.endTime - GetTime\(\)\)/, '')) && /if w\.RegisterUnitEvent then pcall\(w\.RegisterUnitEvent, w, event, unit\) end/.test(split)
    && /w:SetScript\('OnEvent', function\(_, event, _, \.\.\.\) Split:CastEvent\(unit, event, \.\.\.\) end\)/.test(split) && /local unit = \(type\(arg1\) == 'string' and not IsSecret\(arg1\)\) and arg1 or nil/.test(split)
    && !/UNIT_AURA|C_UnitAuras|UnitAura|AuraUtil|GetChildren|:IsShown\(|IsVisible\(/.test(strip0(split)) && !/:IsShown\(/.test(strip0(body(plate, 'local function BuildEnhanced') + body(plate, 'function TargetPlate:Apply'))));
  check('1.3.0 performance: one event frame per unit for casts (player / target / focus), no ticker in Split.lua, the only OnUpdate on the hub\'s clock (shown only while a timed cast is on it), the live frames built once (built[frame]) and re-painted on the game\'s events',
    (strip0(split).match(/OnUpdate/g) || []).length === 1 && /clock:SetScript\('OnUpdate'/.test(split) && /clock:SetShown\(timed\)/.test(split) && !/NewTicker/.test(strip0(split))
    && /if watchers\[unit\] then return watchers\[unit\] end/.test(split) && /or built\[frame\] then return built\[frame\] end/.test(split));
  // E. identity art chain + the icon contract
  const idLib = fs.readFileSync(path.join(ROOT, 'tools', 'lib', 'identity.js'), 'utf8');
  const manifestLua = src('IdentityManifest.lua');
  const sources = fs.existsSync(path.join(ROOT, 'assets', 'identity')) ? fs.readdirSync(path.join(ROOT, 'assets', 'identity')).filter((x) => /\.png$/i.test(x)) : [];
  check('1.3.0 identity art chain: 1 Darren\'s original class icon (validated by the build: IdentityManifest), 2 the Fabled spec / class art Jiberish Icons provides (referenced in place, never copied), 3 a class-colour disc with the class\'s two letters, 4 a neutral unknown disc - only the manifest is read, so a missing file can never error or leave a blank circle',
    /Identity\.ART_ORDER = \{ 'BANZAI', 'FABLED', 'GLYPH', 'UNKNOWN' \}/.test(identity) && /local manifest = ns\.IdentityManifest/.test(identity) && /return \{ kind = 'BANZAI', path = Identity\.BANZAI_DIR \.\. file/.test(identity)
    && /return \{ kind = 'GLYPH', glyph = Identity\.GLYPHS\[classToken\]/.test(identity) && /return \{ kind = 'UNKNOWN', glyph = '\?'/.test(identity) && Object.keys({}).length === 0
    && ['DEATHKNIGHT', 'DEMONHUNTER', 'DRUID', 'EVOKER', 'HUNTER', 'MAGE', 'MONK', 'PALADIN', 'PRIEST', 'ROGUE', 'SHAMAN', 'WARLOCK', 'WARRIOR'].every((k) => new RegExp(k + " = '[A-Z]{2}'").test(identity))
    && !/JiberishIcons\\\\Media/.test(strip0(identity)) /* the Fabled art is asked for through Jiberish Icons' API */);
  let pipeline = ''; let pipelineOk = false;
  try {
    const idl = require('./lib/identity');
    const os = require('os'); const zlib = require('zlib');
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'banzai-identity-check-'));
    const pngOf = (n, fn) => { const raw = Buffer.alloc((n * 4 + 1) * n); for (let y = 0; y < n; y++) { raw[y * (n * 4 + 1)] = 0; for (let x = 0; x < n; x++) { const c = fn(x, y); const o = y * (n * 4 + 1) + 1 + x * 4; raw[o] = c[0]; raw[o + 1] = c[1]; raw[o + 2] = c[2]; raw[o + 3] = c[3]; } }
      const chunk = (t, d) => { const len = Buffer.alloc(4); len.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t, 'latin1'), d]); const crc = Buffer.alloc(4); let c = 0xffffffff; for (const b of td) { c ^= b; for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1)); } crc.writeUInt32BE((c ^ 0xffffffff) >>> 0); return Buffer.concat([len, td, crc]); };
      const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(n, 0); ihdr.writeUInt32BE(n, 4); ihdr[8] = 8; ihdr[9] = 6;
      return Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]); };
    // a throwaway synthetic disc (never kept, never in the repo or the addon): the contract's checks and the conversion run on it
    const disc = (x, y) => (Math.hypot(x + 0.5 - 512, y + 0.5 - 512) < 420 ? [40, 200, 120, 255] : [0, 0, 0, 0]);
    // 1.3.2: the sources are class-<class>.png, and a file that breaks the contract is left out for its class only
    fs.writeFileSync(path.join(dir, 'class-mage.png'), pngOf(1024, disc));
    const good = idl.prepare(dir);
    fs.writeFileSync(path.join(dir, 'class-monk.png'), pngOf(1024, () => [255, 255, 255, 255]));
    const mixed = idl.prepare(dir);
    const rejected = mixed.rejected.some((r) => r.name === 'monk') && !mixed.classes.MONK && Boolean(mixed.classes.MAGE);
    fs.writeFileSync(path.join(dir, 'wizard.png'), pngOf(4, disc));
    const named = idl.prepare(dir).unknown.includes('wizard.png');
    fs.rmSync(dir, { recursive: true, force: true });
    pipelineOk = good.classes.MAGE && good.images.mage.length === 256 * 256 * 4 && good.images.mage[(128 * 256 + 128) * 4 + 3] === 255 && good.images.mage[3] === 0 && !good.details && rejected && named
      && /ns\.IdentityManifest = \{/.test(idl.manifestLua(good)) && /MAGE = 'mage'/.test(idl.manifestLua(good));
    pipeline = `synthetic 1024 px disc converted to 256 x 256 (centre opaque, corner clear), an opaque square left out for its class only: ${rejected}, an unknown name reported: ${named}`;
  } catch (e) { pipeline = String(e); }
  check('1.3.0 the identity-icon contract and its deterministic converter: 13 fixed lowercase names (1.3.2: class-<class>.png in assets/identity, 8-bit RGBA, square, >= 1024, transparent outside the inscribed circle, artwork in the circular safe area) -> 256 x 256 32-bit TGA in media/BanzaiIdentity (linear-light, premultiplied area filter), the Details sheet only with all 13 (1.3.2: and once the simplified family exists); 1.3.2: a source breaking the contract is left out for its class only, with the reason',
    pipelineOk && /const CLASSES = \['deathknight', 'demonhunter', 'druid', 'evoker', 'hunter', 'mage', 'monk', 'paladin', 'priest', 'rogue', 'shaman', 'warlock', 'warrior'\];/.test(idLib)
    && /CONTRACT = \{ minSize: 1024, runtime: 256/.test(idLib) && fs.existsSync(path.join(ROOT, 'docs', 'BANZAI-IDENTITY-ICONS.md')), pipeline);
  const shipped = identityIcons.map((f) => path.basename(f, '.tga')).filter((n) => n !== 'details-classes').sort();
  const listed = [...manifestLua.matchAll(/\t\t([A-Z]+) = '([a-z]+)'/g)].map((m) => m[2]).sort();
  check('1.3.0 no placeholder art: Darren\'s identity icons ship only as he made them - the built BanzaiIdentity files are exactly the manifest\'s classes, each from a source in assets/identity (1.3.2: his 13 class identities); nothing else of Banzai ships as class art',
    shipped.join() === listed.join() && listed.every((n) => sources.includes('class-' + n + '.png')) && sources.every((n) => listed.includes(n.replace(/^class-/, '').replace(/\.png$/, '')))
    && (/details = true/.test(manifestLua) === identityIcons.some((f) => /details-classes\.tga$/.test(f))), `${listed.length} Banzai identity icons (sources: ${sources.length})`);
  // F. party, focus / ToT, nameplate, enemy frames
  check('1.3.0 party / arena allies in BANZAI SPLIT: the identity circle (32, smaller than every hub) in the middle of the bar, the name centred across its lower part above it, the role icon at the left end, Dead / Offline above the circle; the role layouts\' places and sizes, the trinket / CC / dispel parts and the range fade kept; no buffs, no bamboo; arena enemy frames untouched',
    /c:SetPoint\('CENTER', frame\.Health or frame, 'CENTER', 0, 0\)/.test(identity) && /if c\.split then return Identity\.PaintArt\(c, Identity\.Art\(classToken, spec\)\) ~= nil end/.test(identity)
    && /text\('party', 'm-Name', \{ justifyH = 'CENTER', xOffset = 0, yOffset = -Round\(P\.circle \/ 2 - 4\), size = P\.name \}\)/.test(T) && /text\('party', 'b-Role', \{ justifyH = 'CENTER', xOffset = -Round\(P\.circle \/ 2 - 1\), yOffset = Round\(P\.circle \/ 2 - 6\) \}\)/.test(T)
    && /text\('party', 'b-Status', \{ justifyH = 'CENTER', xOffset = 0, yOffset = Round\(P\.circle \/ 2 \+ 2\) \}\)/.test(T) && git('addons/BushidoPrivateCompat/PvPFrames.lua', 'banzai-1.2.1') === now('addons/BushidoPrivateCompat/PvPFrames.lua')
    && git('addons/BushidoPrivateRestore/Roles.lua', 'banzai-1.2.1') === now('addons/BushidoPrivateRestore/Roles.lua') && /if def\.frame == 'ElvUF_Focus' then return 'skip' end/.test(identity));
  check('1.3.0 Focus: a smaller split frame (hub 30) up and left of the Player, its crowd control above its health bar; Target-of-Target: one compact bar right of the Target with its name and percent - no cast or resource system of their own',
    /focus = \{ bar = 110, height = 12, powerHeight = 7, hub = 30, name = 9, dx = -330, dy = 70 \}/.test(T) && /for k, v in pairs\(\{ anchorPoint = 'TOPLEFT', growthX = 'RIGHT', xOffset = 0, yOffset = 2, sizeOverride = 18 \}\) do unit\('focus', v, 'debuffs', k\) end/.test(T)
    && /unit\('targettarget', false, 'power', 'enable'\)/.test(T) && /leaf\(Mover\('LEFT', 'TOP', tx \+ t\.inner \+ t\.bar \+ S\.gap, -ty\), 'movers', 'ElvUF_TargetTargetMover'\)/.test(T) && /Split\.FOCUS_OFFSET = \{ -330, 70 \}/.test(split));
  check('1.3.0 enhanced targeted nameplate: only the current target\'s plate (the one C_NamePlate gives for "target"), only in a split session with its own switch (on by default), every other plate as before; the hub follows the plate and takes the target\'s casts; a green -> purple outline marks it',
    /local function Enhanced\(\)\n\tlocal split = ns\.Split\n\treturn split and split\.Session and split:Session\(\) and Theme:DB\(\)\.splitTargetPlate ~= false or false/.test(plate) && /splitTargetPlate = true,/.test(theme)
    && /local enhanced = shown and Enhanced\(\)/.test(plate) && /ns\.Split:SetPlateHub\(\(deco and deco\.hub and Enhanced\(\)\) and deco\.hub or nil\)/.test(plate) && /if current then Show\(current, false\) current = nil end/.test(plate)
    && /Theme:Gradient\(t, 'HORIZONTAL', Theme\.COLORS\.lime, Theme\.COLORS\.violet, 1, 1\)/.test(plate));
  check('1.3.0 a split session draws no classic plates / bamboo on Player / Target / Focus / ToT and keeps the small wordmark in combat; a classic session is exactly as before; the session is split only when the character chose SPLIT and its profile carries the split layer',
    /if not \(split and self\.SPLIT_FRAMES\[def\.frame\]\) then/.test(compat) && /local combat = active and db\.combatLogo and self\.inCombat and not split and true or false/.test(compat)
    && /self\.session = \(Active\(\) and Theme:DB\(\)\.frameStyle == 'SPLIT' and Split\.ProfileSplit\(\)\) and true or false/.test(split));
  // G. preview
  check('1.3.0 preview: a FRAME STYLE selector (CLASSIC / SPLIT, by default the session\'s), the split samples (Player idle / casting / channeling, Target player and NPC, Target casting, Focus, ToT, DPS / HEALER party, the enhanced nameplate) as plain non-secure frames labelled SAMPLE DATA, the synthetic progress not a live cast, hidden in combat with the rest',
    /function Preview:SetStyle\(style\)/.test(preview) && /function Preview:Style\(\)/.test(preview) && /Split\.PREVIEW = \{ player = true, target = true, targetNPC = true, targettarget = true, focus = true, party = true, arenaAllies = true, nameplate = true \}/.test(split)
    && /SAMPLE DATA\|r'\)/.test(split) && /for key, c in pairs\(splitFrames\) do -- 1\.3\.0\n\t\tc:Hide\(\)/.test(preview) && /'CHANNELING'/.test(preview) && !/Secure\w*Template/.test(split)
    && /previewStyle = Select\(3\.5, 'Frame style'/.test(options));
  // H. Details COMPACT
  check('1.3.0 BANZAI COMPACT Details: DAMAGE | HEALING kept side by side in the same frame; thin class-coloured bars (4), a round identity icon at each row\'s start (Darren\'s sheet, else the Fabled set Jiberish Icons registers, else Banzai\'s class-colour discs), the name above its bar in the class colour, the value large on the same line, tight rows - through Details\' own row settings and its window API (SetBarSettings), no Details file changed; CURRENT puts Bushido\'s icon settings back',
    /T\.DETAILS_COMPACT = \{ rowHeight = 4, rowGap = 14,/.test(T) && /\[1\] = CompactText\('bottomleft', 'topleft', C\.nameX, 'left', C\.nameSize, true\)/.test(T) && /row\.start_after_icon = false/.test(T)
    && /discs = 'Interface\\\\AddOns\\\\BushidoPrivateCompat\\\\media\\\\BanzaiClassDiscs'/.test(T) && /fabled = 'Interface\\\\AddOns\\\\JiberishIcons\\\\Media\\\\Class\\\\fabledclass'/.test(T)
    && /pcall\(window\.SetBarSettings, window, row\.height/.test(restore) && /if T\.DetailsStyle\(style\) == 'COMPACT' then T\.DetailsCompactRow\(row, iconFile\) end/.test(T)
    && /for _, key in ipairs\(T\.DETAILS_ICON_KEYS\) do row\[key\] = T\.DeepCopy\(historicalRow\[key\]\) end/.test(T) && /detailsStyle = 'CURRENT'/.test(theme)
    && fs.existsSync(path.join(ADDONS, 'JiberishIcons', 'Media', 'Class', 'fabledclass.tga')));
  check('1.3.0 Details text readable on every material: the COMPACT names in their class colour with the dark outline and shadow, the values in the row ink - the 1.1.1 parchment off-white with its outline untouched; the DAMAGE red / HEALING green titles and the bamboo frame unchanged',
    /font = \{ size = size, outline = T\.DETAILS_STYLE\.outline \},\n\t\tshadow = \{ color = \{ 0, 0, 0, 1 \}, offset = \{ 1, -1 \} \}/.test(T) && /ink = \{ 0\.96, 0\.95, 0\.92, 1 \}/.test(T)
    && /function T\.DetailsRowInk/.test(T) && /Compat\.DETAILS_TITLES = \{[\s\S]*?text = 'DAMAGE', bright = \{ 1\.00, 0\.40, 0\.32 \}/.test(compat) && /text = 'HEALING', bright = \{ 0\.55, 1\.00, 0\.45 \}/.test(compat));
  // I. GUI, sync, migration
  check('1.3.0 GUI: UNIT FRAMES > FRAME STYLE (Banzai Classic / Banzai Split, what this session runs) and BANZAI SPLIT (Player / Target position, reset, frame scale, central icon scale, HP text, resource text, enhanced target nameplate, party style, preview); LAYOUT > DETAILS > Meter style (Banzai Current / Banzai Compact) - concise',
    /style = Tab\(5, 'FRAME STYLE'/.test(options) && /frameStyle = Section\(1, 'FRAME STYLE'/.test(options) && /split = Section\(10, 'BANZAI SPLIT'/.test(options)
    && ['playerX', 'playerY', 'targetX', 'targetY', 'resetPositions', 'scale', 'hubScale', 'hpText', 'powerText', 'plate', 'party', 'preview'].every((k) => new RegExp('\\t' + k + ' = ').test(body(options, "split = Section(10, 'BANZAI SPLIT'")))
    && /detailsStyle = Select\(4, 'Meter style'/.test(options) && /\{ CURRENT = 'Banzai Current', COMPACT = 'Banzai Compact' \}/.test(options));
  check('1.3.0 Character Sync carries the unit-frame style, the split positions, scales, text choices, the enhanced nameplate, the party style and the Details meter style (BANZAI settings, exported with every other; the layer writes the split side per character at login); never abilities, actions, keybinds, talents, auras or Details history',
    ["frameStyle = 'CLASSIC'", 'splitPlayerX = 0', 'splitPlayerY = 290', 'splitTargetX = 0', 'splitTargetY = 112', 'splitScale = 1', 'splitHubScale = 1', 'splitHpText = true', 'splitPowerText = true', 'splitTargetPlate = true', 'splitParty = true', "detailsStyle = 'CURRENT'"].every((k) => theme.includes(k))
    && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme) && /the unit-frame style \(BANZAI CLASSIC \/ BANZAI SPLIT/.test(sync) && /the Details meter style \(BANZAI CURRENT \/ BANZAI COMPACT; never the Details history\)/.test(sync)
    && /Sync\.CHARACTER_OWN = \{ 'cdTracked' \}/.test(sync) && /R:ApplyDetails\(record, R:Fonts\(\)\.small\)/.test(sync));
  check('1.3.0 migration: every existing character stays BANZAI CLASSIC / BANZAI CURRENT (the defaults, an unknown value falls back to them, nothing switches by itself); a CLASSIC layer\'s options are exactly 1.2.1\'s (no split key in them, so nothing is rewritten at the upgrade); schema, saved variables, profile name and T.LAYER unchanged; the meter style applied at login only when it differs from what was applied last',
    /if db\.frameStyle ~= 'CLASSIC' and db\.frameStyle ~= 'SPLIT' then db\.frameStyle = 'CLASSIC' end/.test(theme) && /if db\.detailsStyle ~= 'CURRENT' and db\.detailsStyle ~= 'COMPACT' then db\.detailsStyle = 'CURRENT' end/.test(theme)
    && /Theme\.SCHEMA = 8/.test(theme) && /T\.LAYER = 12\b/.test(T) && /if T\.FrameStyle\(CompatSetting\('frameStyle', 'CLASSIC'\)\) == 'SPLIT' then\n\t\topts\.frameStyle = 'SPLIT'/.test(restore)
    && /for k, v in pairs\(opts\) do if k ~= 'splitState' then plain\[k\] = v end end/.test(restore) && /~= T\.DetailsStyle\(DB\(\)\.detailsStyleApplied\) then self:ApplyDetailsStyle\(\) end/.test(restore)
    && compatToc.fields.SavedVariables === 'BanzaiCompatDB' && restoreToc.fields.SavedVariables === 'BushidoPrivateRestoreDB');
  check('1.3.0 a classic option changed while the profile carries the split layer is written over the classic values and the split layer is written again after it (no mixed profile); a new profile starts a new split record',
    /function Restore:ClassicEdit\(fn\)/.test(restore) && (restore.match(/self:ClassicEdit\(function\(\)/g) || []).length >= 6 && (options.match(/ns\.Restore:ClassicEdit\(function\(\)/g) || []).length === 3
    && /opts\.splitState = \{\} -- 1\.3\.0: a new profile, a new record of its split layer/.test(restore) && /T\.RevertFrameStyle\(p, opts and opts\.splitState\)/.test(T));
  // J. provenance / publication readiness
  check('1.3.0 provenance: the hub and disc art are generated by Banzai (tools/lib/hub.js reads no image file); the Fabled art stays Jiberish Icons\' (referenced through its API / the path Details is given, never copied into the addon); the reference screenshots are never read by the build or packaged',
    !/readFileSync|tga\.read|png\.decode/.test(strip0(fs.readFileSync(path.join(ROOT, 'tools', 'lib', 'hub.js'), 'utf8'))) && !files(path.join(DIST, 'BushidoPrivateCompat')).some((f) => /fabled|jiberish/i.test(path.basename(f)))
    && !/design-references/.test(fs.readFileSync(path.join(ROOT, 'tools', 'build.js'), 'utf8')) && /docs\/BANZAI-IDENTITY-ICONS\.md|BANZAI-IDENTITY-ICONS/.test(idLib));
}

// 21. BANZAI 1.3.1: BANZAI SPLIT runtime correction, Want Coffee display typography, objective tracker ownership that holds
{
  const src = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', name), 'utf8');
  const rsrc = (name) => fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', name), 'utf8');
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const TAG131 = 'banzai-1.3.1';
  const now = (rel) => git(rel, TAG131); // 1.3.2: the 1.3.1 release itself (its scope against 1.3.0)
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff = (rel) => { const c = new Map(); for (const l of lines(git(rel, 'banzai-1.3.0'))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(now(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  const split = src('Split.lua'); const identity = src('Identity.lua'); const health = src('Health.lua'); const plate = src('TargetPlate.lua'); const tags = src('Tags.lua');
  const compat = src('Compat.lua'); const theme = src('Theme.lua'); const afk = src('AFK.lua'); const pvp = src('PvPFrames.lua'); const preview = src('Preview.lua');
  const restore = rsrc('Restore.lua'); const options = rsrc('Options.lua'); const sync = rsrc('Sync.lua'); const T = transformSource;
  const PX0 = 0.71 * 1440 / 768; // screen pixels per UI unit at Darren's setup
  // A. scope
  const all = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => /\.(lua|toc)$/.test(x)).map((x) => a + '/' + x));
  const changed = all.filter((x) => git('addons/' + x, 'banzai-1.3.0') !== now('addons/' + x)).sort();
  check('1.3.1 scope (tag banzai-1.3.1 against banzai-1.3.0): since 1.3.0 only the split correction (Split / Health / Identity / Tags / Theme, the split leaves in Transform), the display typography (Theme, Compat titles / zone, AFK, a font call each in PvPFrames / Preview / TargetPlate to keep their look), the tracker ownership (Restore), settings, sync text and both TOCs - action buttons, bottom panel, Banzai tracker, cast history, cooldown bars, tooltips, role layouts untouched',
    changed.join() === 'BushidoPrivateCompat/AFK.lua,BushidoPrivateCompat/BushidoPrivateCompat.toc,BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/Health.lua,BushidoPrivateCompat/Identity.lua,BushidoPrivateCompat/Preview.lua,BushidoPrivateCompat/PvPFrames.lua,BushidoPrivateCompat/Split.lua,BushidoPrivateCompat/Tags.lua,BushidoPrivateCompat/TargetPlate.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/BushidoPrivateRestore.toc,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Sync.lua,BushidoPrivateRestore/Transform.lua', changed.join(', '));
  const pvpD = diff('addons/BushidoPrivateCompat/PvPFrames.lua'); const prevD = diff('addons/BushidoPrivateCompat/Preview.lua'); const plateD = diff('addons/BushidoPrivateCompat/TargetPlate.lua');
  check('1.3.1 PvP frames, the preview and the targeted nameplate: only the font call that keeps their look (the previous display font / the plate hub\'s small font) - PvP labels, arena / BG enemy frames and nameplates frozen',
    pvpD.length === 2 && pvpD.some((l) => /^\+label:SetFont\(Theme:PreviousDisplayFont\(\), \(role == 'cc'\) and 11 or 9, 'OUTLINE'\)$/.test(l))
    && prevD.length === 2 && prevD.some((l) => /^\+b\.label:SetFont\(Theme:PreviousDisplayFont\(\), labelSize or 10, 'OUTLINE'\)$/.test(l))
    && plateD.length === 1 && plateD[0] === '+hub.plate = true', [...pvpD, ...prevD, ...plateD].join(' | '));
  // B. the root cause of the white bars / empty hub
  const hubCode = body(identity, 'function Identity.Hub(');
  check('1.3.1 root cause fixed: the 1.3.0 split frames\' first paint stopped at an idle hub ("Font not set": the game refuses SetText on a font string without a font; Split.Idle clears the cast texts before any cast had set their fonts) - the hub\'s cast texts now get a font where they are made, before any text; every split frame is painted on its own (pcall per entry: one fault never leaves the Player white again), the last fault shown in /banzai status',
    hubCode.indexOf("for _, fs in ipairs({ h.castName, h.castTime }) do fs:SetFont(Theme:SmallFont(), 11, 'OUTLINE') end") > hubCode.indexOf('h.castTime = h.over:CreateFontString') && hubCode.indexOf('SetFont') > 0
    && /local ok, err = pcall\(self\.Paint, self, entry\)\n\t\t\tif not ok then Split\.Unpainted\(entry, err\) end/.test(split) && /local ok, err = pcall\(Split\.Paint, Split, entry\)\n\t\t\tif not ok then Split\.Unpainted\(entry, err\) end/.test(body(split, 'local function PaintUnit'))
    && /if split and split\.lastError then Print\('BANZAI SPLIT paint error \(last seen\): '/.test(restore)
    && /Theme:SetDisplayFont\(fs, Theme:DisplaySize\(entry\.def\.name\), 'OUTLINE'\) -- a font before any text/.test(split));
  // C. colours: the class family on both bars, continuous, never the resource type
  let ramp = null; let rampErr = '';
  try {
    const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
    const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
    const prog = `local ns = {} assert(loadfile(${JSON.stringify(path.join(DIST, 'BushidoPrivateCompat', 'Theme.lua').replace(/\\/g, '/'))}))('x', ns)
      local out = {}
      local classes = { MONK = { 0, 1, 0.59 }, MAGE = { 0.25, 0.78, 0.92 }, DRUID = { 1, 0.49, 0.04 }, ROGUE = { 1, 0.96, 0.41 }, DEATHKNIGHT = { 0.77, 0.12, 0.23 }, PALADIN = { 0.96, 0.55, 0.73 }, PRIEST = { 1, 1, 1 } }
      for k, c in pairs(classes) do local r = ns.Theme.Ramp(c) out[#out + 1] = string.format('%s %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f %.3f', k, r.bright[1], r.bright[2], r.bright[3], r.base[1], r.base[2], r.base[3], r.deep[1], r.deep[2], r.deep[3]) end
      RAMPS = table.concat(out, '\\n')`;
    if (lauxlib.luaL_loadstring(L, to_luastring(prog)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) rampErr = to_jsstring(lua.lua_tostring(L, -1));
    lua.lua_getglobal(L, to_luastring('RAMPS'));
    ramp = {}; for (const l of (to_jsstring(lua.lua_tostring(L, -1)) || '').split('\n').filter(Boolean)) { const [k, ...n] = l.split(' '); ramp[k] = n.map(Number); }
  } catch (e) { rampErr = String(e); }
  const r = (k) => (ramp && ramp[k]) || [];
  const monk = r('MONK');
  check('1.3.1 the class family (Theme.Ramp, run in the Lua VM): Mistweaver jade -> turquoise (light jade, the Monk colour, deeper turquoise), Mage cyan -> blue, Druid amber -> orange, Rogue yellow -> gold, Death Knight red -> burgundy - the canonical colour in the middle, saturated, never white for a known class, never a black end',
    monk.length === 9 && monk[1] > 0.95 && monk[0] < 0.35 && Math.abs(monk[3]) < 0.01 && Math.abs(monk[4] - 1) < 0.01 && monk[7] > 0.35 && monk[7] < 0.7 && monk[8] > monk[7] * 0.6 && monk[6] < 0.1
    && r('MAGE')[1] / r('MAGE')[2] > r('MAGE')[7] / r('MAGE')[8] && r('DRUID')[1] / r('DRUID')[0] > 0.55 && r('DRUID')[7] / r('DRUID')[6] < 0.45
    && r('DEATHKNIGHT')[8] > r('DEATHKNIGHT')[7] && Object.entries(ramp || {}).every(([k, v]) => Math.max(v[6], v[7], v[8]) > 0.3 && (k === 'PRIEST' || !(v[0] > 0.97 && v[1] > 0.97 && v[2] > 0.97))),
    rampErr || 'MONK ' + monk.map((x) => x.toFixed(2)).join(' '));
  const paint = body(split, 'function Split:Paint(entry)');
  check('1.3.1 BANZAI SPLIT colours: health AND resource in the unit\'s class family (an NPC: its reaction family) - never the resource type\'s colour (Theme.POWER and Split.PowerColor gone); one continuous composition through the hub: health light -> canonical, resource canonical -> deep, on each bar\'s own fill (review: no mask - an empty bar must look empty); opaque, hidden until painted and after a failed paint (never the raw white texture); recoloured only when the game\'s events / a refresh ask',
    !/Theme\.POWER|PowerColor\b|UnitPowerType/.test(strip0(paint)) && !/Theme\.POWER\b/.test(strip0(theme + split + compat + health + preview))
    && /local ramp = exists and entry\.def and Split\.UnitRamp\(unit\) or nil/.test(paint) && /Split\.PaintSurface\(entry\.health, Split\.HealthColors\(ramp\), Split\.SURFACE_ALPHA\)/.test(paint) && /Split\.PaintSurface\(entry\.power, \(not none\) and Split\.PowerColors\(ramp\) or nil, Split\.SURFACE_ALPHA\)/.test(paint)
    && /function Split\.HealthColors\(ramp\) return ramp and \{ ramp\.bright, ramp\.base \} or nil end/.test(split) && /function Split\.PowerColors\(ramp\) return ramp and \{ ramp\.base, ramp\.deep \} or nil end/.test(split) && /Split\.SURFACE_ALPHA = 1\b/.test(split)
    && /overlay:SetAllPoints\(fill\)\n\toverlay:Hide\(\)\n\treturn \{ track = track, overlay = overlay \}/.test(split) && !/CreateMaskTexture|AddMaskTexture/.test(strip0(split))
    && /entry\.health = Surface\(frame\.Health\)\n/.test(split) && /if not on then s\.overlay:Hide\(\) end/.test(split)
    && /function Split\.Unpainted\(entry, err\)\n\tSplit\.lastError = tostring\(err\)\n\tfor _, s in ipairs\(\{ entry\.health, entry\.power \}\) do if s then s\.overlay:Hide\(\) end end/.test(split) && (strip0(split).match(/OnUpdate/g) || []).length === 1 && !/NewTicker/.test(strip0(split)));
  // D. geometry, thickness, the split leaves, CLASSIC unchanged (VM)
  check('1.3.1 thicker bars: Player 24 / Target 21 (32 / 28 whole pixels at Darren\'s scale) in Banzai Art and Banzai alike, the bar thickness setting on top (0.75 .. 1.3, Player / Target only); hub larger than the bars; bar lengths unchanged',
    /player = \{ frame = 'ElvUF_Player', unit = 'player', bar = 180, height = 24, hub = 50,/.test(split) && /target = \{ frame = 'ElvUF_Target', unit = 'target', bar = 170, height = 21, hub = 46,/.test(split)
    && /player = \{ bar = 180, height = 24, hub = 50, name = 11, thick = true(, identity = 1\.25[^}\n]*)? \}/.test(T) && /target = \{ bar = 170, height = 21, hub = 46, name = 11, thick = true(, identity = 1\.25[^}\n]*)? \}/.test(T) /* 1.3.3: + the identity / cast bar numbers */
    && /focus = \{ bar = 110, height = 12, powerHeight = 7, hub = 30, name = 9, dx = -330, dy = 70 \}/.test(T) && /splitThickness = \{ 0\.75, 1\.3, 1 \}/.test(theme)
    && /local t = d\.thick and \(tonumber\(opts\.splitThickness\) or 1\) or 1/.test(T) && /local t = def\.thick and \(tonumber\(db\.splitThickness\) or 1\) or 1/.test(split)
    && [24, 21].every((u) => Math.abs(u * PX0 - Math.round(u * PX0)) < 0.06));
  let classic131 = false; let round131 = false; let details131 = false; let compact130 = false; let leaves131 = []; let plates131 = false; let vm131 = '';
  try {
    const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');
    const L = lauxlib.luaL_newstate(); lualib.luaL_openlibs(L);
    const q = (x) => JSON.stringify(x.replace(/\\/g, '/'));
    const oldT = path.join(ROOT, 'build', 'validate-Transform-1.3.0.lua');
    fs.mkdirSync(path.dirname(oldT), { recursive: true });
    fs.writeFileSync(oldT, git('addons/BushidoPrivateRestore/Transform.lua', 'banzai-1.3.0') || '');
    const prog = `
      local function load(file) local ns = {} assert(loadfile(file))('x', ns) return ns end
      local P = load(${q(path.join(DIST, 'BushidoPrivateRestore', 'Payloads.lua'))}).Payloads
      local Old, New = load(${q(oldT)}).Transform, load(${q(path.join(DIST, 'BushidoPrivateRestore', 'Transform.lua'))}).Transform
      local fonts = { display = 'GasoekOne', small = 'Rubik-Bold' }
      local opts = { healthInside = true, healthPercent = true, barHeight = 32, smoothBars = true, actionStyle = 'SQUARE', frameWidth = 0.5, totScale = 0.72, identityCircles = true, roleIcons = true, role = 'DPS', roleContext = 'world', tooltipTheme = 'BANZAI', afk = true }
      local base = New.TransformProfile(P.elvuiProfile, 'GasoekOne', nil, 'Rubik-Bold', opts)
      local a, b = Old.DeepCopy(base), Old.DeepCopy(base)
      Old.ApplyCharacterLayer(a, P.elvuiProfile, fonts, opts)
      New.ApplyCharacterLayer(b, P.elvuiProfile, fonts, opts)
      CLASSIC = Old.Serialize(a) == New.Serialize(b)
      local state = {}
      local o2 = New.DeepCopy(opts) o2.splitState = state o2.frameStyle = 'SPLIT' o2.splitLayout = New.SPLIT.version
      local c = New.DeepCopy(b)
      New.ApplyCharacterLayer(c, P.elvuiProfile, fonts, o2)
      local differs = New.Serialize(c) ~= New.Serialize(b)
      PLATES = New.Serialize(c.nameplates or {}) == New.Serialize(b.nameplates or {}) and New.Serialize(a.nameplates or {}) == New.Serialize(b.nameplates or {})
      local o3 = New.DeepCopy(opts) o3.splitState = state
      New.ApplyCharacterLayer(c, P.elvuiProfile, fonts, o3)
      ROUND = differs and New.Serialize(c) == New.Serialize(b)
      local paths = {}
      for _, leaf in ipairs(New.SplitLeaves(b, P.elvuiProfile, fonts, { frameStyle = 'SPLIT' })) do paths[#paths + 1] = table.concat(leaf.path, '.') end
      LEAVES = table.concat(paths, '\\n')
      local d1, d2 = Old.DeepCopy(P.detailsProfile), Old.DeepCopy(P.detailsProfile)
      Old.StyleDetailsWindows(d1, true, fonts, 'CURRENT', New.DETAILS_ICONS.fabled)
      New.StyleDetailsWindows(d2, true, fonts, 'CURRENT', New.DETAILS_ICONS.fabled, 'Interface\\\\AddOns\\\\BushidoPrivateCompat\\\\media\\\\fonts\\\\WantCoffee.ttf')
      DETAILS = Old.Serialize(d1) == New.Serialize(d2)
      local e1, e2 = Old.DeepCopy(P.detailsProfile), Old.DeepCopy(P.detailsProfile)
      Old.StyleDetailsWindows(e1, true, fonts, 'COMPACT', New.DETAILS_ICONS.fabled)
      New.StyleDetailsWindows(e2, true, fonts, 'COMPACT', New.DETAILS_ICONS.fabled)
      COMPACT = Old.Serialize(e1) == New.Serialize(e2)
    `;
    if (lauxlib.luaL_loadstring(L, to_luastring(prog)) !== lua.LUA_OK || lua.lua_pcall(L, 0, 0, 0) !== lua.LUA_OK) vm131 = to_jsstring(lua.lua_tostring(L, -1));
    const get = (name) => { lua.lua_getglobal(L, to_luastring(name)); const v = lua.lua_toboolean(L, -1); lua.lua_pop(L, 1); return v; };
    classic131 = get('CLASSIC'); round131 = get('ROUND'); details131 = get('DETAILS'); compact130 = get('COMPACT'); plates131 = get('PLATES');
    lua.lua_getglobal(L, to_luastring('LEAVES')); leaves131 = (to_jsstring(lua.lua_tostring(L, -1)) || '').split('\n').filter(Boolean); lua.lua_pop(L, 1);
  } catch (e) { vm131 = String(e); }
  check('1.3.1 BANZAI CLASSIC unchanged, proven in the Lua VM: the 1.3.1 character layer with CLASSIC settings writes exactly what 1.3.0 wrote (every key, as text); SPLIT -> CLASSIC still gives the classic profile back exactly with the new leaves; the nameplate settings identical in every case (nameplates frozen)',
    classic131 && round131 && plates131, vm131 || 'identical, round trip exact, nameplates identical');
  check('1.3.1 BANZAI CURRENT Details unchanged (the 1.3.1 styling with CURRENT writes exactly 1.3.0\'s, whatever the display font); BANZAI COMPACT without the Banzai display font is exactly 1.3.0\'s', details131 && compact130, vm131 || 'identical');
  const leafMovers = leaves131.filter((p) => p.startsWith('movers.')).map((p) => p.slice(7)).sort();
  check('1.3.1 the split leaves: still only Player, Target, Focus, ToT and party (never arena / boss / raid / pet / role-layout keys or movers); the Player / Target b-SplitName entry is the layer\'s marker (enable off, banzaiSplit, banzaiSpec), Focus keeps its centred line; the class bar above the resource values, clear of the spell name over the hub',
    [...new Set(leaves131.filter((p) => p.startsWith('unitframe.units.')).map((p) => p.split('.')[2]))].sort().join() === 'focus,party,player,target,targettarget'
    && !leaves131.some((p) => /^unitframe\.units\.(arena|boss|raid\d|pet)\./.test(p)) && !leaves131.some((p) => /^unitframe\.units\.party\.(width|height|growthDirection|horizontalSpacing|verticalSpacing|auras\.)/.test(p))
    && leafMovers.join() === 'AdditionalPowerMover,ClassBarMover,ElvUF_FocusMover,ElvUF_PlayerMover,ElvUF_TargetMover,ElvUF_TargetTargetMover,FocusPowerBarMover,PlayerPowerBarMover,TargetPowerBarMover'
    && ['player', 'target'].every((u) => ['enable', 'banzaiSplit', 'banzaiSpec'].every((k) => leaves131.includes(`unitframe.units.${u}.customTexts.b-SplitName.${k}`)) && !leaves131.includes(`unitframe.units.${u}.customTexts.b-SplitName.text_format`))
    && leaves131.includes('unitframe.units.focus.customTexts.b-SplitName.text_format')
    && /classbar = \{ inset = 8, height = 5, gap = 3, additional = 7, values = 18, start = 48 \}/.test(T) && /leaf\(Mover\('BOTTOMLEFT', 'BOTTOM', px \+ g\.inner \+ C\.start, py \+ bottom\), 'movers', 'ClassBarMover'\)/.test(T),
    `${leaves131.length} leaves`);
  check('1.3.1 migration: a CLASSIC character\'s layer options are exactly 1.3.0\'s (no rewrite at the upgrade); a SPLIT character\'s carry the layout of the split leaves (T.SPLIT.version 2) and the bar thickness, so its layer is rewritten once at its next login before ElvUI builds (its positions kept); a 1.3.0 layer still runs (ElvUI\'s own line, no second Banzai line); schema, profile, T.LAYER unchanged',
    /if T\.FrameStyle\(CompatSetting\('frameStyle', 'CLASSIC'\)\) == 'SPLIT' then\n\t\topts\.frameStyle = 'SPLIT'\n\t\tfor _, k in ipairs\(Restore\.SPLIT_LAYER\) do opts\[k\] = CompatSetting\(k, T\.SPLIT\.defaults\[k\]\) end\n\t\topts\.splitParty = CompatSetting\('splitParty', true\) ~= false\n\t\topts\.splitLayout = T\.SPLIT\.version/.test(restore)
    && /Restore\.SPLIT_LAYER = \{ 'splitPlayerX', 'splitPlayerY', 'splitTargetX', 'splitTargetY', 'splitScale', 'splitHubScale', 'splitThickness' \}/.test(restore) && /version = 3,/.test(T) /* 1.3.3: 3 */
    && /return line and \(line\.enable == true or line\.banzaiSplit == true\) or false/.test(split) && /if not \(line and line\.banzaiSplit == true\) then return false, false end/.test(split)
    && /Theme\.SCHEMA = 9/.test(theme) && /T\.LAYER = 12\b/.test(T) && /if not self\.DISPLAY_FACE_SET\[db\.displayFace\] then db\.displayFace = 'BANZAI_DEFAULT' end/.test(theme));
  // E. texts above / lines under
  check('1.3.1 Player / Target texts: current HP over the health bar\'s outer end, HP % over its inner end (clear of the hub), resource % over the resource bar\'s inner end, current resource over its outer end - one copy each (nothing to clip above a bar), ElvUI\'s own tags (nothing read); Focus and party keep theirs inside',
    /\{ frame = 'ElvUF_Player', key = 'player', side = 'LEFT', x = 0, y = 2, split = true, splitStyle = true, above = true, display = true \}/.test(health) && /\{ frame = 'ElvUF_Target', key = 'target', side = 'RIGHT', x = 0, y = 2, split = true, splitStyle = true, above = true, display = true \}/.test(health)
    && /\{ frame = 'ElvUF_Focus', key = 'focus', side = 'LEFT', x = 4, y = 0, split = true, splitStyle = true \}/.test(health)
    && /set\.value:SetPoint\('BOTTOM' \.\. def\.side, bar, 'TOP' \.\. def\.side, def\.x or 0, def\.y or 2\)/.test(health) && /set\.percent:SetPoint\('BOTTOM' \.\. opposite, bar, 'TOP' \.\. opposite, \(opposite == 'RIGHT'\) and -px or px, def\.y or 2\)/.test(health)
    && /if def\.above then -- 1\.3\.1: over the bar, nothing to clip: one bright copy/.test(health) && /out\.percentX = g\.tuck \+ Health\.SPLIT_GAP/.test(health));
  const lineCode = body(split, 'function Split.BuildLines');
  check('1.3.1 identity lines: the NAME under the health bar from its outer end (left-justified), the SPEC under the resource bar to its outer end (right-justified), each narrower than its bar minus the hub\'s part (never under the hub), one line, outlined with a shadow, in the Banzai display font; through ElvUI\'s tag system - [banzai:split:name] the BANZAI green -> emerald -> violet -> purple gradient, [banzai:split:spec] the class family, only a reliably known spec (none for NPCs), a hidden name handed on unread',
    /line\(frame\.Health, 'TOPLEFT', 'BOTTOMLEFT', 'LEFT'\)/.test(lineCode) && /line\(frame\.Power, 'TOPRIGHT', 'BOTTOMRIGHT', 'RIGHT'\)/.test(lineCode) && /local width = g\.bar - g\.tuck - Split\.LINE_GAP \* 2 -- never under the hub/.test(lineCode)
    && /fs:SetWordWrap\(false\)/.test(lineCode) && /frame:Tag\(lines\.name, '\[banzai:split:name\]'\)/.test(lineCode) && /frame:Tag\(lines\.specText, '\[banzai:split:spec\]'\)/.test(lineCode)
    && /E:AddTag\('banzai:split:name', 'UNIT_NAME_UPDATE', function\(unit\) return Tags\.SplitName\(unit\) end\)/.test(tags) && /E:AddTag\('banzai:split:spec', events, function\(unit\) return Tags\.SplitSpec\(unit\) end\)/.test(tags)
    && /if IsSecret\(name\) then return name end/.test(body(tags, 'function Tags.SplitName')) && /Theme\.NAME_STOPS = \{ COLORS\.lime, COLORS\.emerald, COLORS\.violet, COLORS\.purple \}/.test(theme)
    && /local spec = Tags\.Spec\(unit\)\n\tif not spec then return nil end/.test(tags) && /fs:SetShadowOffset\(1, -1\)/.test(body(split, 'function Split.LineFonts')));
  // F. typography scope
  const bakeoff = src('FontBakeoff.lua');
  const fontLib = require('./lib/fonts');
  const runtimeFonts = fontLib.FONTS.map((f) => f.file);
  const retiredFonts = fontLib.RETIRED_FILES;
  check('licensed display face: semantic BANZAI Default maps to Shojumaru at 105%; the six approved alternates and the Information Font are selectable; retired bake-off faces are not registered',
    /displayFace = 'BANZAI_DEFAULT'/.test(theme) && /local DEFAULT_FACE = "SHOJUMARU"/.test(bakeoff)
    && /local DEFAULT_KEY = "SHOJUMARU"/.test(bakeoff) && /local DEFAULT_SCALE = 1\.05/.test(bakeoff)
    && /BANZAI_DEFAULT_FONT = DEFAULT_KEY/.test(bakeoff) && /BANZAI_DEFAULT_SCALE = DEFAULT_SCALE/.test(bakeoff)
    && runtimeFonts.every((file) => bakeoff.includes(`file = "${file}"`)) && !retiredFonts.some((file) => bakeoff.includes(`file = "${file}"`))
    && fontLib.FONTS.every((f) => bakeoff.includes(`${f.id} = "${f.sha256}"`)) && fontLib.FONTS.every((f) => new RegExp(`"${f.id}",`).test(bakeoff))
    && /"AUTO", "BANZAI_DEFAULT", "SHOJUMARU", "RYUJIN_ATTACK", "GANG_OF_THREE", "OSAKA_SANS", "SEKAIWO", "XANGDA_SHINY", "NINJA_NARUTO", "INFORMATION"/.test(bakeoff)
    && /local RETIRED = \{ WANTBANZAI = true, WANTCOFFEE = true, CHANG_CHANG_WOODCUT = true, ROOTS_OF_CHINA = true, ODISHI = true \}/.test(bakeoff)
    && /INFORMATION = \{ label = "Information Font"/.test(bakeoff) && /function Theme:SetDisplayFont/.test(bakeoff)
    && /if face\.information or not supports\(face, text\) then return self:SmallFont\(\) end/.test(bakeoff)
    && /function Theme:DisplayFontInfo/.test(bakeoff) && /displayScale = \{ 0\.85, 1\.2, 1 \}/.test(theme)
    && /self\.BANZAI_DEFAULT_SCALE/.test(body(theme, 'function Theme:DisplaySize'))
    && /Theme:SetDisplayFont\(t\.text, Theme:DisplaySize\(T\.size\), 'OUTLINE'\)/.test(compat) && /Theme:SetDisplayFont\(label\.text, Theme:DisplaySize\(self\.MINIMAP\.zoneSize\), 'OUTLINE', zone\)/.test(compat)
    && /Theme:SetDisplayFont\(f\.name, Theme:DisplaySize\(26\), 'OUTLINE', name\)/.test(afk) && /Theme:SetDisplayFont\(f\.spec, Theme:DisplaySize\(AFK\.SPEC_SIZE\), 'OUTLINE'/.test(afk)
    && /Theme:SetDisplayFont\(hub\.castName, Theme:DisplaySize\(size\), 'OUTLINE', text\)/.test(split) && /if def\.display then\r?\n\t\tTheme:SetDisplayFont\(set\.value, Theme:DisplaySize\(def\.value\), 'OUTLINE'\)/.test(health));
  check('display fallback: unsupported/malformed strings use Information Font as a whole; failed font loads remain readable',
    /local function supports\(face, text\)/.test(bakeoff) && /local function nextCodepoint\(text, index\)/.test(bakeoff)
    && /if face\.information or not supports\(face, text\) then return self:SmallFont\(\) end/.test(bakeoff)
    && /if not fs:SetFont\(path, adjusted, flags\) then\r?\n\t\treturn fs:SetFont\(self:SmallFont\(\), fallbackSize, flags\)/.test(bakeoff)
    && /Theme:SetDisplayFont\(fs, Theme:DisplaySize\(entry\.def\.name\), 'OUTLINE', pair\[2\]\)/.test(split) && /local name = Call\(UnitName, entry\.unit\)/.test(split)
    && /return math\.max\(3, math\.ceil\(percentTop - g\.hub \/ 2\)\)/.test(split) && /hub\.castName:SetPoint\('BOTTOM', hub, 'TOP', 0, Split\.CastLift\(g, def\)\)/.test(split)
    && /return \{ bright = \{ v, v, v \}, base = \{ v \* 0\.80, v \* 0\.83, v \* 0\.88 \}/.test(theme) /* Priest: white -> silver, never one flat white */);
  check('1.3.1 the small information font unchanged: percentages, cast timers, chat, Details meter values, tracker, tooltips, cooldown bars, cast history, bottom panel, keybinds / counts; the previous display font kept where the look is frozen (nameplate numbers, PvP labels, identity glyphs, party / arena / boss / focus numbers); the targeted nameplate\'s hub keeps its small font',
    /set\.percent:SetFont\(Theme:SmallFont\(\), def\.percent, 'OUTLINE'\)/.test(health) && /hub\.castTime:SetFont\(Theme:SmallFont\(\), hub\.timeSize or math\.max\(8, size - 2\), 'OUTLINE'\)/.test(split) /* 1.3.3: a bar hub's timer size */
    && /if hub\.plate then\n\t\thub\.castName:SetFont\(Theme:SmallFont\(\), size, 'OUTLINE'\)/.test(split) && /set\.value:SetFont\(Theme:PreviousDisplayFont\(\), def\.value, 'OUTLINE'\)/.test(health)
    && /c\.glyph:SetFont\(Theme:PreviousDisplayFont\(\)/.test(identity) && ['Tracker.lua', 'CastHistory.lua', 'CooldownBars.lua', 'Bar.lua', 'Tooltip.lua', 'ActionButtons.lua'].every((f0) => git('addons/BushidoPrivateCompat/' + f0, 'banzai-1.3.0') === now('addons/BushidoPrivateCompat/' + f0))
    && /chat\.font, chat\.tabFont = fonts\.small, fonts\.small/.test(T) && !/TargetPlate\.TEXT = \{[^}]*display/.test(plate));
  // G. the font files: provenance and licence
  const fontDir = path.join(DIST, 'BushidoPrivateCompat', 'media', 'fonts');
  const sourceFontDir = path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'media', 'fonts');
  const shipped = fs.existsSync(fontDir) ? fs.readdirSync(fontDir) : [];
  const sha256Of = (file) => (fs.existsSync(file) ? crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex') : '');
  const shojumaru = path.join(fontDir, 'Shojumaru-Regular.ttf');
  const ofl = path.join(fontDir, 'OFL.txt');
  const oflText = fs.existsSync(ofl) ? fs.readFileSync(ofl, 'utf8') : '';
  const nameTable = (file) => {
    const b = fs.readFileSync(file); const n = b.readUInt16BE(4); let off = 0;
    for (let i = 0; i < n; i++) if (b.toString('latin1', 12 + 16 * i, 16 + 16 * i) === 'name') off = b.readUInt32BE(20 + 16 * i);
    const count = b.readUInt16BE(off + 2); const str = off + b.readUInt16BE(off + 4); const out = {};
    for (let i = 0; i < count; i++) { const rec = off + 6 + 12 * i; if (b.readUInt16BE(rec) !== 1) continue; out[b.readUInt16BE(rec + 6)] = b.toString('latin1', str + b.readUInt16BE(rec + 10), str + b.readUInt16BE(rec + 10) + b.readUInt16BE(rec + 8)); }
    return out;
  };
  const names = fs.existsSync(shojumaru) ? nameTable(shojumaru) : {};
  const W = fontLib.FONTS[0];
  const forbiddenRuntimeFonts = ['WantCoffee', 'WantBanzai', 'Changchangwoodcut', 'RootsOfChina', 'Odishi'];
  const forbiddenDist = distFiles.filter((file) => forbiddenRuntimeFonts.some((name) => file.toLowerCase().includes(name.toLowerCase())));
  const expectedShipped = [...fontLib.FONTS.map((f) => f.file), ...fontLib.NOTICES].sort();
  const hashesMatch = fontLib.FONTS.every((f) => sha256Of(path.join(fontDir, f.file)) === f.sha256 && sha256Of(path.join(sourceFontDir, f.file)) === f.sha256);
  const noticesShip = fontLib.NOTICES.every((n) => fs.existsSync(path.join(fontDir, n)) && fs.existsSync(path.join(sourceFontDir, n)));
  const noticesName = fontLib.FONTS.every((f) => fs.existsSync(path.join(fontDir, 'FONT-NOTICES.txt')) && fs.readFileSync(path.join(fontDir, 'FONT-NOTICES.txt'), 'utf8').includes(f.sha256));
  check('display-font packaging: the seven shipped faces match their recorded SHA-256 in source and build, every supplied notice ships with FONT-NOTICES.txt naming each hash, and the retired bake-off faces are absent',
    JSON.stringify(shipped.slice().sort()) === JSON.stringify(expectedShipped) && hashesMatch && noticesShip && noticesName && W.id === 'SHOJUMARU'
    && names[1] === 'Shojumaru' && names[2] === 'Regular'
    && oflText.includes('SIL OPEN FONT LICENSE Version 1.1') && oflText.includes('Reserved Font Names "Shojumaru"')
    && forbiddenDist.length === 0,
    `${shipped.join(', ')}; ${names[1]} ${names[2]}${forbiddenDist.length ? '; forbidden: ' + forbiddenDist.join(', ') : ''}`);
  const readme = fs.readFileSync(path.join(ROOT, 'README.md'), 'utf8');
  const legacyCoffee = fontLib.LEGACY_WANT_COFFEE;
  check('selection-lock documentation and private historical evidence are distinct from runtime packaging',
    /Shojumaru.*105%/.test(readme) && legacyCoffee.copyright.includes('All rights reserved')
    && /100% free for personal use & commercial use/.test(legacyCoffee.terms)
    && /BANZAI Default/.test(options) && /license: %s/.test(restore));
  // H. the objective tracker
  const watch = body(restore, 'function Restore:WatchTracker');
  check('1.3.1 objective tracker ownership holds: what reclaimed it was found in the installed code (ElvUI\'s auto-hider brings it back to UIParent when boss / arena units go - a state driver with no event of its own; Eltruism re-anchors it; Edit Mode re-parents it) - a tiny empty sentinel frame of Banzai\'s own inside Blizzard\'s tracker fires its own OnShow the moment the tracker is visible again and queues the same idempotent one-frame check; nothing hooked, no OnUpdate, no polling, the tracker never hidden',
    /local sentinel = CreateFrame\('Frame', nil, f\)/.test(watch) && /sentinel:SetScript\('OnShow', function\(\)\n\t\tif Restore:BanzaiTrackerShown\(\) then Restore:QueueTrackerOwnership\('shown again'\) end/.test(watch) && /sentinel:EnableMouse\(false\)/.test(watch)
    && /self:WatchTracker\(\) -- 1\.3\.1/.test(body(restore, 'function Restore:TrackerOwnership')) && !/hooksecurefunc|HookScript|OnUpdate|NewTicker/.test(strip0(restore))
    && !/ObjectiveTrackerFrame:Hide|f:Hide\(\)|SetAlpha\(0\)/.test(strip0(body(restore, 'function Restore:TrackerOwnership') + watch)) && fs.existsSync(path.join(ADDONS, 'ElvUI', 'Game', 'Shared', 'Modules', 'Blizzard', 'ObjectiveFrame.lua'))
    && /BL:ObjectiveTracker_Expand\(tracker\)/.test(fs.readFileSync(path.join(ADDONS, 'ElvUI', 'Game', 'Shared', 'Modules', 'Blizzard', 'ObjectiveFrame.lua'), 'utf8')));
  check('1.3.1 tracker states: BANZAI Objectives ON - Banzai\'s tracker only (Blizzard\'s parked again whenever it comes back); OFF - Blizzard\'s tracker returns and is left alone; in combat one deferred correction after it (never duplicated); RESTORE PRE-BANZAI puts its parent / collapsed state back; a re-park keeps the parent it had before Banzai',
    /self\.trackerParent = self\.trackerParent or f:GetParent\(\)/.test(restore) && /if InCombatLockdown\(\) then\n\t\tself\.trackerPending = true\n\t\treturn 'pending'/.test(restore) && /function Restore:PutBackBlizzardTracker\(saved\)/.test(restore) && /if self\.trackerQueued then return 'queued' end/.test(restore));
  // I. secret values in the changed code
  const changedCode = strip0([body(split, 'function Split.UnitRamp'), body(split, 'function Split:Paint(entry)'), lineCode, body(split, 'function Split.LineFonts'), body(tags, 'function Tags.SplitName'), body(tags, 'function Tags.SplitSpec'), watch, body(theme, 'function Theme.Ramp')].join('\n'));
  check('1.3.1 secret values (focused review of the changed code): no health / power / aura value read anywhere in it; the unit\'s class and reaction only through the plain-only readers (Call / Plain, issecretvalue first); a hidden name handed to the tag unread, a hidden class gives no spec; no comparison, arithmetic or concatenation on a game value; the tracker sentinel reads no state',
    !/UnitHealth|UnitPower\b|UnitPowerMax|UnitAura|C_UnitAuras|GetChildren|:IsShown\(|IsVisible\(/.test(changedCode) && /local color = Split\.UnitColor\(unit\)/.test(body(split, 'function Split.UnitRamp'))
    && /if type\(unit\) ~= 'string' or IsSecret\(unit\) or not UnitName then return nil end/.test(tags) && /token = ok and Plain\(token\) or nil/.test(body(tags, 'function Tags.SplitSpec'))
    && !/name \.\.|\.\. name|#name/.test(body(tags, 'function Tags.SplitName')));
  // J. sync, GUI, version, backups, icons
  check('Character Sync carries the stable display-face setting, its size and bar thickness; the WHAT SYNCS text says so; tracker ownership follows the synced choice',
    ["displayFace = 'BANZAI_DEFAULT'", 'displayScale = 1,', 'splitThickness = 1,'].every((k) => theme.includes(k)) && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme)
    && /fonts \(display face: BANZAI Default \/ Shojumaru at 105%, Automatic, Information Font or Previous - plus its size\)/.test(sync) && /bar thickness/.test(sync) && /R:TrackerOwnership\('update'\)/.test(sync));
  check('BANZAI FONTS GUI offers the licensed face selector and preview without exposing unrelated candidate choices',
    /displayFace = Select\(1\.2, 'Display font'/.test(options) && /Preview display font/.test(options) && /displayScale = ArtRange\(1\.4, 'displayScale', 'Banzai display size'/.test(options) && /thickness = Options\.SplitRange\(8\.5, 'splitThickness', 'Bar thickness'/.test(options)
    && /R:SetDisplayFace\(v\)/.test(options) && /function Restore:SetDisplayFace\(face\)/.test(restore) && /Shojumaru at 105%/.test(options));
  check('BANZAI COMPACT Details follows the selected display face; the row font remains for values',
    /T\.DETAILS_COMPACT_FACE_SIZE = 14/.test(T) && /\[1\] = CompactText\('bottomleft', 'topleft', C\.nameX, 'left', nameFace and T\.DETAILS_COMPACT_FACE_SIZE or C\.nameSize, true, nil, nameFace\)/.test(T)
    && /function Restore:CompactNameFace\(\)/.test(restore) && /DB\(\)\.detailsFaceApplied = face or false/.test(restore) && /style == 'COMPACT' and \(self:CompactNameFace\(\) or false\) ~= DB\(\)\.detailsFaceApplied/.test(restore));
  check('1.3.1 version 1.3.1 everywhere (the release, tag banzai-1.3.1): both TOCs, Banzai Art, Banzai (GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the reload dialog), the AFK screen, the README',
    now('addons/BushidoPrivateCompat/BushidoPrivateCompat.toc').includes('## Version: 1.3.1') && now('addons/BushidoPrivateRestore/BushidoPrivateRestore.toc').includes('## Version: 1.3.1')
    && /Theme\.VERSION = '1\.3\.1'/.test(now('addons/BushidoPrivateCompat/Theme.lua')) && /local VERSION = '1\.3\.1'/.test(now('addons/BushidoPrivateRestore/Restore.lua'))
    && /'\|cff8c919aBANZAI ' \.\. tostring\(Theme\.VERSION\)/.test(afk) && now('README.md').includes('Version: **BANZAI 1.3.1**'));
  const b130 = backupDirs.filter((d) => /^Banzai-1\.3\.0-\d{8}-\d{6}$/.test(d)).sort().pop();
  const b130dir = b130 && path.join(BACKUP_ROOT, b130);
  check('1.3.1 BANZAI 1.3.0 backed up first (tools/backup.js, WoW closed): the installed 1.3.0 addons, the WTF folder as last saved, the repository at banzai-1.3.0 (bundle) and the third-party addon state the checks compare against',
    Boolean(b130dir) && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(b130dir, 'addons', a))) && fs.readFileSync(path.join(b130dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').includes('## Version: 1.3.0')
    && fs.existsSync(path.join(b130dir, 'workspace', 'banzai-1.3.0.bundle')) && files(path.join(b130dir, 'WTF-as-last-saved')).length > 1000 && fs.existsSync(path.join(b130dir, 'thirdparty-baseline.json')), b130dir || 'none');
  let tagFiles = [];
  try { tagFiles = execSync(`git ls-tree -r --name-only ${TAG131}`, { cwd: ROOT, encoding: 'utf8' }).split('\n').filter(Boolean); } catch (e) { /* no tag */ }
  check('1.3.1 no icon integration (the release, tag banzai-1.3.1): no JPEG anywhere in the addons or their sources, the Gemini test images not used, assets/identity held no image, no Banzai identity icon shipped (the 1.3.0 fallback chain unchanged: Banzai original -> Fabled -> class glyph -> unknown)',
    tagFiles.length > 0 && !tagFiles.some((f) => /\.jpe?g$/i.test(f) || /^assets\/identity\//.test(f)) && !distFiles.some((f) => /\.jpe?g$/i.test(f))
    && /Identity\.ART_ORDER = \{ 'BANZAI', 'FABLED', 'GLYPH', 'UNKNOWN' \}/.test(now('addons/BushidoPrivateCompat/Identity.lua')) && !/Gemini/i.test(strip0(now('addons/BushidoPrivateCompat/Split.lua') + now('addons/BushidoPrivateCompat/Identity.lua'))));
  check('1.3.1 preview: the BANZAI SPLIT Player / Target samples drawn as live (the class family over both bars through the same masked surface, the values above, the name / spec lines under them; SAMPLE DATA)',
    /u\.healthSurface = PFull\(u\.Health\)/.test(split) && /u\.powerSurface = PFull\(u\.Power\)/.test(split) && /above = true, display = true, percentX = gap/.test(split) && /u\.name:SetText\(Split\.NameText\(sample\.label\)\)/.test(split) && /u\.spec:SetText\(Split\.SpecText\(sample\.spec, color\)\)/.test(split));
}

// 22. BANZAI 1.3.2: Darren's original BANZAI class identities - the asset pipeline and the runtime integration
// (1.3.3: the 1.3.2 release itself - its code and scope read from the banzai-1.3.2 tag; the media, the masters and the
// re-derivation still checked on the current build, block 23 for what 1.3.3 changed)
{
  const TAG131 = 'banzai-1.3.1';
  const TAG132 = 'banzai-1.3.2';
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const src = (name) => git('addons/BushidoPrivateCompat/' + name, TAG132) || '';
  const rsrc = (name) => git('addons/BushidoPrivateRestore/' + name, TAG132) || '';
  const now = (rel) => git(rel, TAG132); // (null where the file did not exist at the tag: 1.3.3's CastBar.lua)
  const compatToc = { fields: { Version: ((src('BushidoPrivateCompat.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const restoreToc = { fields: { Version: ((rsrc('BushidoPrivateRestore.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff = (rel) => { const c = new Map(); for (const l of lines(git(rel, TAG131))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(now(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  const identity = src('Identity.lua'); const split = src('Split.lua'); const theme = src('Theme.lua'); const plate = src('TargetPlate.lua');
  const restore = rsrc('Restore.lua'); const options = rsrc('Options.lua'); const sync = rsrc('Sync.lua');
  const readme = now('README.md');
  const art = require('./lib/classart'); const idl = require('./lib/identity');
  // A. scope
  const all = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => /\.(lua|toc)$/.test(x)).map((x) => a + '/' + x));
  const changed = all.filter((x) => git('addons/' + x, TAG131) !== now('addons/' + x)).sort();
  check('1.3.2 scope: since 1.3.1 only the identity art (Identity.lua), the hub asking with its size (Split.lua), the IDENTITY ART setting (Theme, Options, Restore, Sync text) and both TOCs - Health, Tags, TargetPlate, PvP frames, Compat, AFK, Preview, Transform, Roles and everything else untouched',
    changed.join() === 'BushidoPrivateCompat/BushidoPrivateCompat.toc,BushidoPrivateCompat/Identity.lua,BushidoPrivateCompat/Split.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/BushidoPrivateRestore.toc,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Sync.lua', changed.join(', '));
  const splitD = diff('addons/BushidoPrivateCompat/Split.lua'); const themeD = diff('addons/BushidoPrivateCompat/Theme.lua');
  check('1.3.2 Split.lua: only the four art requests now pass their hub / circle (the live hub and the preview samples); bars, values, name / spec lines, cast presentation and geometry byte-for-byte as 1.3.1',
    splitD.length === 8 && splitD.includes('+return identity.PaintArt(hub, identity.Art(token, nil, hub))') && splitD.includes('+ns.Identity.PaintArt(u.circle, ns.Identity.Art(class, sample.specID, u.circle))')
    && splitD.filter((l) => l[0] === '+').every((l) => /Art\(/.test(l)), splitD.join(' | '));
  check('1.3.2 Theme.lua: the version and the IDENTITY ART setting only (default AUTO, every read brings an unknown value back to AUTO; Character Sync exports every DEFAULTS key)',
    themeD.length === 5 && themeD.includes("+identityArt = 'AUTO',") && themeD.includes("+if db.identityArt ~= 'AUTO' and db.identityArt ~= 'BANZAI' and db.identityArt ~= 'FABLED' and db.identityArt ~= 'CLASS' then db.identityArt = 'AUTO' end")
    && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme), themeD.join(' | '));
  check('1.3.2 hub geometry, nameplates, Details unchanged: the hub textures (tools/lib/hub.js), the identity circles (tools/lib/bamboo.js), TargetPlate.lua and the profile transform identical to 1.3.1; Identity.HUB as approved',
    ['tools/lib/hub.js', 'tools/lib/bamboo.js', 'addons/BushidoPrivateCompat/TargetPlate.lua', 'addons/BushidoPrivateRestore/Transform.lua', 'addons/BushidoPrivateCompat/Health.lua'].every((f) => git(f, TAG131) === now(f))
    && /Identity\.HUB = \{ canvas = 128 \/ 120, icon = 0\.80, halo = 1\.07 \}/.test(identity) && /hub\.plate = true/.test(plate));
  // B. the sources and the class mapping
  const mapping = art.loadMapping(ROOT);
  const sourcesThere = fs.existsSync(path.join(ROOT, mapping.sourceDir));
  const v = sourcesThere ? art.verifySources(ROOT, mapping) : { errors: ['source folder missing'] };
  check('1.3.2 class mapping (assets/identity/class-sources.json): every file in the source folder mapped or excluded; 13 sources, 13 unique classes, 0 duplicates, 0 missing; each source\'s SHA-256, size and baseline JPEG format as recorded (the JPEGs are only read); the second Warrior excluded on Darren\'s choice',
    v.errors.length === 0 && Object.keys(mapping.classes).sort().join() === art.CLASSES.join() && new Set(Object.values(mapping.classes).map((e) => e.source)).size === 13
    && mapping.excluded.length === 1 && /Darren chose/.test(mapping.excluded[0].reason) && mapping.classes.warrior.source === 'Gemini_Generated_Image_p0cfhqp0cfhqp0cf (6).jpeg', v.errors.join('; ') || `${v.files.length} files`);
  // C. the masters, the provenance and a re-derivation from the JPEGs
  const prov = JSON.parse(now('assets/identity/class-provenance.json'));
  const masterFiles = fs.readdirSync(path.join(ROOT, 'assets', 'identity')).filter((f) => /\.png$/.test(f)).sort();
  check('1.3.2 masters: exactly class-<class>.png for the 13 classes in assets/identity, each the hash its provenance records, 1024 x 1024 RGBA within the identity-icon contract',
    masterFiles.join() === art.CLASSES.map((c) => `class-${c}.png`).join() && art.CLASSES.every((c) => {
      const bytes = fs.readFileSync(path.join(ROOT, 'assets', 'identity', `class-${c}.png`)); const img = require('./lib/png').decode(bytes);
      return art.sha256(bytes) === prov.classes[c].master.sha256 && img.w === 1024 && img.h === 1024 && img.type === 6 && idl.check(img).length === 0;
    }), masterFiles.length + ' masters');
  let rederive = 'sources absent';
  let rederived = false;
  if (sourcesThere) {
    try { rederive = execSync('node tools/icons.js --check', { cwd: ROOT, encoding: 'utf8', timeout: 600000 }).trim(); rederived = /identical/.test(rederive); } catch (e) { rederive = String(e.stdout || e.message || e).trim(); }
  }
  check('1.3.2 deterministic: tools/icons.js --check derives all 13 masters again from the JPEGs (decode, matte, seams, ring, scale) and gets the committed bytes and provenance exactly',
    rederived, rederive);
  const radii = art.CLASSES.map((c) => prov.classes[c].master.ring.R);
  check('1.3.2 composition: every ring centred within 1 px and the same radius within 1 px (the family\'s apparent scale), one uniform scale (both ring axes within 1.5 %), corners clear, the matte holes clear and the near-matte steel opaque at the recorded probes',
    art.CLASSES.every((c) => { const m = prov.classes[c].master; return Math.abs(m.ring.cx - 512) <= 1 && Math.abs(m.ring.cy - 512) <= 1 && m.corners && Math.abs(m.extent.horizontal - m.extent.vertical) / m.extent.horizontal <= 0.015 && prov.classes[c].probes.transparent.length >= 1; })
    && Math.max(...radii) - Math.min(...radii) <= 1 && art.CLASSES.every((c) => prov.classes[c].evidence.pass), radii.join(', '));
  check('1.3.2 provenance: generated for BANZAI UI, Darren\'s original art (not Blizzard\'s, no Blizzard icon as a source), source / master / runtime hashes, the tool and its version, the class mapping, the excluded image; the pipeline reads no game file',
    /BANZAI UI/.test(prov.generatedFor) && /not Blizzard art/.test(prov.owner) && prov.tool.name === 'tools/icons.js' && /^\d+\.\d+\.\d+$/.test(prov.tool.version) && prov.excluded.length === 1
    && art.CLASSES.every((c) => /^[0-9a-f]{64}$/.test(prov.classes[c].source.sha256) && /^[0-9a-f]{64}$/.test(prov.classes[c].runtime.sha256) && prov.classes[c].source.file === mapping.classes[c].source)
    && /public packaging remains blocked pending separate release authorization/i.test(prov.publication) && ['tools/lib/classart.js', 'tools/lib/matte.js', 'tools/lib/jpeg.js', 'tools/icons.js'].every((f) => !/World of Warcraft|Interface\\\\|JiberishIcons/.test(now(f))));
  // D. the runtime assets
  const ids = identityIcons.map((f) => path.basename(f)).sort();
  const manifestLua = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'IdentityManifest.lua'), 'utf8'); // a build product (1.3.3: the build of today)
  check('1.3.2 runtime: media/BanzaiIdentity holds exactly the 13 <class>.tga (256 x 256, 32-bit, the hashes the provenance records - transparent colour bled); the manifest lists all 13; no Details sheet (the full art is muddy at a meter row: the simplified family later)',
    ids.join() === art.CLASSES.map((c) => c + '.tga').join() && art.CLASSES.every((c) => art.sha256(fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiIdentity', c + '.tga'))) === prov.classes[c].runtime.sha256)
    && art.CLASSES.every((c) => new RegExp(`\\t\\t${c.toUpperCase()} = '${c}'`).test(manifestLua)) && /details = false/.test(manifestLua) && idl.CONTRACT.detailsSheet === false
    && /resampleLib\.bleed\(/.test(fs.readFileSync(path.join(ROOT, 'tools', 'lib', 'identity.js'), 'utf8')), ids.join(', '));
  check('1.3.2 nothing else ships: no JPEG, no PNG master, no QA sheet, no mapping / provenance file in the built addons or the installed ones; the build converts the masters only (it never reads design-references); the QA sheets live in build/ (git-ignored)',
    !distFiles.some((f) => /\.jpe?g$|\.png$/i.test(f) || /qa-|provenance|class-sources|Gemini/i.test(f)) && !/design-references|require\('\.\/lib\/(classart|jpeg|matte)'\)/.test(strip0(fs.readFileSync(path.join(ROOT, 'tools', 'build.js'), 'utf8')).replace(/\/\/[^\n]*/g, ''))
    && /^build\/$/m.test(now('.gitignore')) && /^design-references\/$/m.test(now('.gitignore')) && !tracked.some((f) => /\.jpe?g$/i.test(f) || /^build\//.test(f)));
  // E. the chain, where the art is used, the fallback per class
  check('1.3.2 loading priority BANZAI -> Fabled -> class-colour disc -> unknown, one central provider (Identity.Art; file paths only through Identity.BANZAI_DIR): a class is BANZAI only when the build listed its file (a plain name) - a missing / rejected / refused file falls back for that class alone; a hidden class is unknown',
    /Identity\.ART_ORDER = \{ 'BANZAI', 'FABLED', 'GLYPH', 'UNKNOWN' \}/.test(identity) && /local file = mode ~= 'FABLED' and Identity\.BanzaiFits\(where\) and Identity\.BanzaiFile\(classToken\)/.test(identity)
    && /if type\(file\) == 'string' and string\.match\(file, '\^%l\+\$'\) then return file end/.test(identity) && /== false and art\.kind == 'BANZAI' then\n\t\t\treturn Identity\.PaintArt\(c, Identity\.Art\(art\.class, art\.spec, \{ noBanzai = true \}\)\)/.test(identity)
    && /IsSecret\(classToken\)/.test(identity) && !/BanzaiIdentity/.test(strip0(split + plate + restore + options)));
  check('1.3.2 where the full art goes: icons of Identity.BANZAI_MIN (22) units and more - the Player / Target / Focus hubs and the split party circles; never the enhanced nameplate hub (frozen) nor anything smaller; the split hubs ask with themselves',
    /Identity\.BANZAI_MIN = 22/.test(identity) && /if where\.plate or where\.noBanzai then return false end/.test(identity) && /return size == nil or size >= Identity\.BANZAI_MIN/.test(identity)
    && /c\.iconSize = size \* Identity\.ICON/.test(identity) && /h\.iconSize = size \* Identity\.HUB\.icon/.test(identity) && /identity\.PaintArt\(hub, identity\.Art\(token, nil, hub\)\)/.test(split));
  check('1.3.2 BANZAI CLASSIC preserved: its identity circles keep Identity.Paint (the Fabled art) unless IDENTITY ART is BANZAI or CLASS; the arena enemy circles never change; Player / Target classic anchors are ElvUI\'s (untouched)',
    /if not c\.def\.arena and \(mode == 'BANZAI' or mode == 'CLASS'\) then return Identity\.PaintArt\(c, Identity\.Art\(classToken, spec, c\)\) ~= nil end\n\treturn Identity\.Paint\(c, classToken, spec\)/.test(identity)
    && /if c\.glyph then c\.glyph:Hide\(\) c\.glyphDisc:Hide\(\) end -- 1\.3\.2/.test(identity));
  check('1.3.2 no runtime processing: Banzai Art reads only the generated manifest and points textures at the shipped files - no file reading, no image work, nothing loaded at runtime beyond the textures',
    !/\bio\.|loadstring|loadfile|require\(/.test(strip0(identity)) && (strip0(identity).match(/C_Timer\.NewTicker\(/g) || []).length === 1 /* the 0.7.0 spec look-up ticker only */);
  // F. the setting, Character Sync, the version
  check('1.3.2 IDENTITY ART: one select on UNIT FRAMES > FRAME STYLE (BANZAI default / BANZAI everywhere / FABLED / CLASS COLOUR), at once through Banzai Art (no reload), /banzai status names it with the classes that have their art; Character Sync carries the choice, never the files',
    /identityArt = Section\(20, 'IDENTITY ART'/.test(options) && /\{ 'AUTO', 'BANZAI', 'FABLED', 'CLASS' \}/.test(options) && /R:SetIdentityArt\(v\)/.test(options)
    && /function Restore:SetIdentityArt\(mode\)\n\tmode = self\.IDENTITY_ARTS\[mode\] and mode or 'AUTO'\n\tCompatSet\('identityArt', mode\)\n\treturn mode\nend/.test(restore)
    && /identity art: %s, BANZAI class art for %d of 13 classes/.test(restore) && /identity art \(1\.3\.2: BANZAI \/ FABLED \/ CLASS COLOUR - the choice only, never the art files\)/.test(sync));
  check('1.3.2 version 1.3.2 everywhere: both TOCs, Banzai Art, Banzai (GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the reload dialog, the update message), the AFK screen, the README',
    compatToc.fields.Version === '1.3.2' && restoreToc.fields.Version === '1.3.2' && /Theme\.VERSION = '1\.3\.2'/.test(theme) && /local VERSION = '1\.3\.2'/.test(restore)
    && /updated to %s %s: your original BANZAI class identities/.test(restore) && readme.includes('Version: **BANZAI 1.3.2**') && /1\.3\.2 \(Darren's original BANZAI class identities/.test(readme));
  // G. tests, mutation, backup
  const mut = now('tools/mutate.js');
  check('1.3.2 tests: the class-art suite runs with the Lua suites (tests/test_icons.js in tests/run.js); the targeted mutation runner covers segmentation, decontamination, the mapping, runtime validation, BANZAI-first and the per-class fallback (no full-project mutation run)',
    /require\('\.\/test_icons'\)\.run\(\)/.test(now('tests/run.js')) && ['segmentation', 'decontamination', 'class mapping', 'runtime validation', 'banzai first', 'per-class fallback'].every((k) => mut.includes(`['${k}'`))
    && (mut.match(/^  \['/gm) || []).length >= 20);
  const b131 = backupDirs.filter((d) => /^Banzai-1\.3\.1-\d{8}-\d{6}$/.test(d)).sort().pop();
  const b131dir = b131 && path.join(BACKUP_ROOT, b131);
  check('1.3.2 BANZAI 1.3.1 backed up first (tools/backup.js, WoW closed): the installed 1.3.1 addons, the WTF folder as last saved, the repository at banzai-1.3.1 (bundle) and the third-party addon state',
    Boolean(b131dir) && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(b131dir, 'addons', a))) && fs.readFileSync(path.join(b131dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').includes('## Version: 1.3.1')
    && fs.existsSync(path.join(b131dir, 'workspace', 'banzai-1.3.1.bundle')) && files(path.join(b131dir, 'WTF-as-last-saved')).length > 1000 && fs.existsSync(path.join(b131dir, 'thirdparty-baseline.json')), b131dir || 'none');
  check('1.3.2 publication: the docs say the class art is Darren\'s (no Blizzard art), only cleaned masters / runtime textures ship, the source JPEGs never; the private addon remains blocked from public packaging',
    /no Blizzard\s+icon is a source/.test(now('docs/BANZAI-IDENTITY-ICONS.md')) && /source JPEGs stay out of\s+every package/.test(now('docs/BANZAI-IDENTITY-ICONS.md')) && /public packaging is blocked/.test(readme) && /source JPEGs stay out of every package/.test(readme));
}

// 23. BANZAI 1.3.3: PvP frame safety, the synthetic TARGET NPC preview, the 125 % split identity and the bamboo cast bar
// (1.3.4: the 1.3.3 release itself - its code and scope read from the banzai-1.3.3 tag; block 24 for what the hotfix changed)
{
  const TAG132 = 'banzai-1.3.2';
  const TAG133 = 'banzai-1.3.3';
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const src = (name) => git('addons/BushidoPrivateCompat/' + name, TAG133) || '';
  const rsrc = (name) => git('addons/BushidoPrivateRestore/' + name, TAG133) || '';
  const now = (rel) => git(rel, TAG133);
  const transformSource = rsrc('Transform.lua');
  const compatToc = { fields: { Version: ((src('BushidoPrivateCompat.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const restoreToc = { fields: { Version: ((rsrc('BushidoPrivateRestore.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const pvp = src('PvPFrames.lua'); const split = src('Split.lua'); const cast = src('CastBar.lua'); const identity = src('Identity.lua'); const theme = src('Theme.lua');
  const preview = src('Preview.lua'); const restore = rsrc('Restore.lua'); const options = rsrc('Options.lua'); const sync = rsrc('Sync.lua'); const T = transformSource;
  const readme = now('README.md'); const note = fs.existsSync(path.join(ROOT, 'docs', 'BANZAI-1.3.3-CRASH-NOTE.md')) ? now('docs/BANZAI-1.3.3-CRASH-NOTE.md') : '';
  const PX0 = 0.71 * 1440 / 768;
  const GEOMETRY = /:(SetHeight|SetWidth|SetSize|SetPoint|ClearAllPoints|SetAllPoints|SetParent|SetScale|SetAttribute)\(/;
  // A. scope
  const all = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => /\.(lua|toc)$/.test(x)).map((x) => a + '/' + x));
  const changed = all.filter((x) => git('addons/' + x, TAG132) !== now('addons/' + x)).sort();
  check('1.3.3 scope: since 1.3.2 only the PvP frames\' emphasis (PvPFrames.lua), the split hub / cast presentation / preview (Split.lua, Identity.lua, Preview.lua), the new bamboo cast bar (CastBar.lua), the settings (Theme, Options, Restore, Sync text), the split layer (Transform: the 125 % hub, the class bar above the cast bar) and both TOCs - Compat.lua (classic frames, panels), Health, Tags, TargetPlate (nameplates), Tooltip, Bar, Info, Tracker, CastHistory, ActionButtons, CooldownBars, AFK, Roles untouched',
    changed.join() === 'BushidoPrivateCompat/BushidoPrivateCompat.toc,BushidoPrivateCompat/CastBar.lua,BushidoPrivateCompat/Identity.lua,BushidoPrivateCompat/Preview.lua,BushidoPrivateCompat/PvPFrames.lua,BushidoPrivateCompat/Split.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/BushidoPrivateRestore.toc,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Sync.lua,BushidoPrivateRestore/Transform.lua', changed.join(', '));
  check('1.3.3 frozen pieces byte-for-byte as 1.3.2: the enhanced targeted nameplate (TargetPlate.lua), the classic frames / panels / cast bars (Compat.lua), the split texts (Health.lua), the class art pipeline and its masters (tools/lib/classart.js, matte.js, identity.js, assets/identity)',
    ['addons/BushidoPrivateCompat/TargetPlate.lua', 'addons/BushidoPrivateCompat/Compat.lua', 'addons/BushidoPrivateCompat/Health.lua', 'tools/lib/classart.js', 'tools/lib/matte.js', 'tools/lib/identity.js', 'assets/identity/class-sources.json', 'assets/identity/class-provenance.json'].every((f) => git(f, TAG132) === now(f))
    && fs.readdirSync(path.join(ROOT, 'assets', 'identity')).filter((x) => /\.png$/.test(x)).every((x) => execSync(`git diff --quiet ${TAG132} -- "assets/identity/${x}" && echo same`, { cwd: ROOT, encoding: 'utf8' }).trim() === 'same'));
  // B. the PvP frames: no geometry after creation, nothing called on a forbidden object, the emphasis shown once out of combat
  const emph = body(pvp, 'function PvP.Emphasize(parts)');
  const made = ['function PvP.Trinket(', 'function PvP.Marker(', 'local function BorderSet(', 'function PvP.Decorate(', 'function PvP:Build()'].map((h) => body(pvp, h));
  let rest = strip0(pvp); for (const b of made) rest = rest.replace(strip0(b), '');
  check('1.3.3 PvP root cause removed (Darren\'s 20:46:04 PvPFrames.lua:226 "calling \'SetHeight\' on bad self (Attempt to access forbidden object from code tainted by an AddOn)"): Emphasize only shows / hides (a border set of each thickness drawn once at creation), no SetHeight / SetWidth / SetSize / SetPoint / ClearAllPoints / SetParent / SetScale / SetAttribute anywhere outside the functions that make the parts',
    emph.length > 0 && !GEOMETRY.test(strip0(emph)) && /edge:SetShown\(thickness == level\.border\)/.test(emph) && /if side\[3\] then t:SetHeight\(thickness\) else t:SetWidth\(thickness\) end -- at creation only/.test(pvp)
    && made.every((b) => b.length > 0) && !GEOMETRY.test(rest), (rest.match(GEOMETRY) || [''])[0]);
  check('1.3.3 PvP safety: IsForbidden asked before anything is called (Accessible: the one question the client answers for a forbidden object) - on the aura icon, its frame and health bar before parts are made, on a part before it is emphasised (and in its own OnShow), on a unit frame and its trinket / markers before they are refreshed; a forbidden object is left as it is; no pcall around the decoration',
    /local function Accessible\(object\)\n\tif type\(object\) ~= 'table' then return false end\n\tlocal forbidden = object\.IsForbidden\n\treturn not \(forbidden and forbidden\(object\)\)\nend/.test(pvp)
    && /if not Accessible\(button\) then return nil end/.test(body(pvp, 'function PvP.Decorate(')) && /if not \(role and Accessible\(frame\)\) then return nil end/.test(pvp) && /if not Accessible\(health\) then return nil end/.test(pvp)
    && /^\tif not Accessible\(parts\.frame\) then return false end/m.test(emph) && /if parts\.pulseOn and Accessible\(self\) and not pulse:IsPlaying\(\) then pulse:Play\(\) end/.test(pvp)
    && /if not \(Accessible\(c\.unitFrame\) and Accessible\(c\)\) then return nil end/.test(pvp) && /if not \(Accessible\(entry\.frame\) and Accessible\(entry\.target\) and Accessible\(entry\.focus\)\) then return end/.test(pvp)
    && /if not Accessible\(frame\) then return end -- 1\.3\.3/.test(body(pvp, 'local function DecorateExisting')) && !/pcall\(PvP\.Decorate/.test(pvp) && (strip0(pvp).match(/pcall\(/g) || []).length === 4 /* RegisterEvent, IsInInstance, the trinket data, UnitIsUnit - as since 0.9.0 */
    && !/hooksecurefunc|HookScript|OnUpdate/.test(strip0(pvp)));
  check('1.3.3 PvP emphasis applied once per change and never in combat (a change in combat waits for its end): Refresh asks ApplyEmphasis, which does nothing while the level is the one shown (1.3.2 re-emphasised every part on every event)',
    /self:ApplyEmphasis\(\) -- 1\.3\.3/.test(body(pvp, 'function PvP:Refresh()')) && !/for _, parts in pairs\(decorated\) do PvP\.Emphasize\(parts\) end\nend/.test(body(pvp, 'function PvP:Refresh()') + '\nend')
    && /if self\.applied == wanted and not force then return false end\n\tif InCombatLockdown\(\) then\n\t\tself\.emphasisPending = true\n\t\treturn false\n\tend/.test(pvp) && /'PLAYER_REGEN_ENABLED'/.test(pvp)
    && /PvP\.EMPHASIS = \{\n\tSTRONG = \{ border = 3, label = true, pulse = true \},\n\tCLEAR = \{ border = 2, label = true \},\n\tMINIMAL = \{\},\n\}/.test(pvp) && /cc = \{ 1\.00, 0\.18, 0\.62 \}, dispel = \{ 0\.20, 0\.85, 1\.00 \}/.test(pvp));
  // C. the TARGET NPC preview
  const sampleUnit = body(split, 'local function SampleUnit(');
  const crestTga = path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiHubCrest.tga');
  const crest = fs.existsSync(crestTga) ? require('./lib/tga').read(crestTga) : null;
  let coloured = 0; if (crest) for (let i = 0; i < crest.w * crest.h; i += 97) { const o = i * 4; if (Math.abs(crest.px[o] - crest.px[o + 2]) > 30) coloured++; }
  check('1.3.3 TARGET NPC preview synthetic (Darren\'s native crash: the Disk Queue thread reading FileData 134153 = inv_misc_head_dragon_01, the game icon the 1.3.2 sample requested): Banzai\'s procedural NPC crest (media/BanzaiHubCrest, 256 x 256 full colour, tools/lib/hub.js) in place of any game icon; the game icon gone from Banzai Art',
    /npcCrest = Theme\.MEDIA \.\. 'BanzaiHubCrest'/.test(split) && /kind = 'CREST', path = Split\.SAMPLE\.npcCrest/.test(sampleUnit) && !/Head_Dragon/i.test(strip0(split + preview + identity + cast))
    && Boolean(crest) && crest.w === 256 && crest.h === 256 && coloured > 20 && /function crest\(\)/.test(now('tools/lib/hub.js')) && /BanzaiHubCrest: crest\(\)/.test(now('tools/lib/hub.js')));
  check('1.3.3 TARGET NPC preview isolated: its sample asks no unit (no Unit* / SetPortraitTexture / GetAttribute in the sample builder), makes no PlayerModel / ModelScene / cooldown widget / secure frame (a bar hub: no radial parts, no game shield), never casts, and the split preview calls nothing of the PvP frames but the trinket circle\'s own paint; every texture it shows requested once at load (Split.NPC_MEDIA, a hidden holder)',
    !/\bUnit[A-Z]\w*\(|SetPortraitTexture|GetAttribute|SetAttribute|PlayerModel|ModelScene|Cooldown|Secure/.test(strip0(sampleUnit)) && /local withBar = def\.castInterior ~= nil and ns\.CastBar ~= nil/.test(sampleUnit) && /if withBar and not sample\.npc then/.test(sampleUnit)
    && /if s\.npc then -- 1\.3\.3: the TARGET NPC sample stays idle in every state/.test(split) && !/PvP(Frames)?[.:](Emphasize|Refresh|ApplyEmphasis|Scan|Build|Decorate)\(/.test(strip0(split + preview))
    && /Split\.NPC_MEDIA = \{ Split\.SAMPLE\.npcCrest, Theme\.MEDIA \.\. 'BanzaiHubDisc', Theme\.MEDIA \.\. 'BanzaiHubRing', Theme\.MEDIA \.\. 'BanzaiHubAccent',\n\tTheme\.MEDIA \.\. 'BanzaiHubMask', BAR, Theme\.WHITE \}/.test(split) && /keeper:Hide\(\)/.test(split)
    && /if show and InCombatLockdown\(\) then/.test(body(preview, 'function Preview:Show(')) && /events:RegisterEvent\('PLAYER_REGEN_DISABLED'\)/.test(preview));
  check('1.3.3 the crash is recorded honestly (docs/BANZAI-1.3.3-CRASH-NOTE.md): the crash file, ERROR #132, ACCESS_VIOLATION at 0xffffffffffffffff, the Disk Queue 0 thread, FileData ID 134153, the earlier crash at the same offset, D3D12 / NVIDIA, DiscordHook64.dll, the 13 Lua errors - not claimed as Banzai\'s, not claimed fixed without Darren\'s runtime proof',
    ['2026-11-05_20.49.17_Crash_40748.txt', 'ERROR #132', 'ACCESS_VIOLATION', '0xffffffffffffffff', 'Disk Queue 0', 'FileData ID 134153', 'inv_misc_head_dragon_01', '2026-11-05_07.39.44_Crash_44452.txt', 'D3D12', 'NVIDIA', 'DiscordHook64.dll', '13 Lua errors'].every((k) => note.includes(k))
    && /does not say the\s+crash is\s+fixed/.test(note) && /BANZAI is not claimed to have caused the\s+crash/.test(note));
  // D. the identity 125 % (Player / Target only), the same numbers on both sides
  const unitNum = (code, key, field) => Number(((code.match(new RegExp('\\t' + key + ' = \\{[^\\n]*\\n?[^\\n]*?' + field + ' = ([\\d.]+)')) || [])[1]));
  const tsplit = (key, field) => Number(((T.match(new RegExp('\\t' + key + ' = \\{[^}\\n]*' + field + ' = ([\\d.]+)')) || [])[1]));
  check('1.3.3 identity 125 %: Player / Target hubs identity = 1.25 (62.5 / 57.5 units, 83 / 77 px at Darren\'s scale) in Banzai Art and the split layer alike, applied after the 1.3.2 rounding; the bars keep size and tuck; Focus, ToT, party circles, the nameplate hub unchanged',
    ['player', 'target'].every((k) => unitNum(split, k, 'identity') === 1.25 && tsplit(k, 'identity') === 1.25)
    && /local hub = math\.floor\(def\.hub \* s \* \(tonumber\(db\.splitHubScale\) or 1\) \+ 0\.5\) \* \(def\.identity or 1\)/.test(split) && /local hub = Round\(d\.hub \* s \* \(tonumber\(opts\.splitHubScale\) or 1\)\) \* \(d\.identity or 1\)/.test(T)
    && !/identity = /.test((split.match(/\tfocus = \{[^\n]*/) || [''])[0]) && /Split\.PARTY = \{ circle = 32,/.test(split) && /Split\.PLATE = \{ hub = 26,/.test(split)
    && Math.abs(62.5 * PX0 - 83.2) < 0.1 && /focus = \{ bar = 110, height = 12, powerHeight = 7, hub = 30,/.test(T));
  check('1.3.3 the idle art: a bar hub draws Darren\'s BANZAI art at full size with its own transparency (Identity.HUB.art 0.98: its bamboo ring where the class ring was), the class ring steps aside while idle and is back round the spell icon during a cast; Fabled / glyph / portrait / crest keep the masked disc in the ring; Focus and party circles as in 1.3.2',
    /Identity\.HUB = \{ canvas = 128 \/ 120, icon = 0\.80, halo = 1\.07, art = 0\.98 \}/.test(identity) && /function Identity\.FitArt\(c, full\)\n\tfull = full and true or false\n\tif not c\.barHub or c\.artFull == full then return end/.test(identity)
    && /if c\.barHub then c\.ring:SetShown\(not \(c\.artFull and not c\.veiled\)\) end/.test(identity) && /Identity\.FitArt\(c, art\.kind == 'BANZAI'\)/.test(identity) && /ns\.Identity\.FitArt\(hub, false\)/.test(body(split, 'function Split.PaintIdentity(')));
  // E. the cast in the centre, the radial progress gone from Player / Target
  const hubCode = body(identity, 'function Identity.Hub(');
  check('1.3.3 radial cast progress removed from the Player / Target hubs (bar hubs: no Cooldown swipe, no dark track, no lock ring, no game shield; Focus and the targeted nameplate keep theirs); the central spell icon kept: casting / channelling show the game\'s icon ALONE in the centre (the identity veiled by alpha, never under or beside it), success / failure / cancel bring the class art back at once, interrupted too (the moment is the bar\'s)',
    hubCode.indexOf('if bar then return Identity.BarHub(h) end') > 0 && hubCode.indexOf('if bar then return Identity.BarHub(h) end') < hubCode.indexOf("CreateFrame('Cooldown'") && hubCode.indexOf('if bar then return Identity.BarHub(h) end') < hubCode.indexOf('Identity.SHIELD')
    && /local withBar = def\.castInterior ~= nil and ns\.CastBar ~= nil -- 1\.3\.3: Player \/ Target\n\tlocal hub = ns\.Identity\.Hub\(frame, g\.hub, withBar\)/.test(split)
    && /\thub\.spell:Show\(\)\n\thub\.endTime = nil\n\tlocal timed\n\tif hub\.barHub then\n\t\tSplit\.Veil\(hub, true\)/.test(body(split, 'function Split.Begin('))
    && /if hub\.barHub then -- 1\.3\.3: the class art back, the bar gone\n\t\tSplit\.Veil\(hub, false\)/.test(body(split, 'function Split.Idle(')) && /if label ~= 'INTERRUPTED' then return Split\.Idle\(hub\) end/.test(split)
    && /\t\thub\.spell:Hide\(\)\n\t\thub\.spell:SetDesaturated\(false\)\n\t\tSplit\.Veil\(hub, false\)/.test(body(split, 'function Split.Fail(')) && /if hub\.barHub then return end -- 1\.3\.3: a bar hub's ring/.test(split)
    && !/castInterior/.test((split.match(/\tfocus = \{[^\n]*/) || [''])[0]) && /if hub\.plate then/.test(split));
  // F. the bamboo cast bar
  const g = (k) => { const hub = Number((split.match(new RegExp('\\t' + k + " = \\{ frame = '[^']+', unit = '\\w+', bar = \\d+, height = \\d+, hub = (\\d+)")) || [])[1]) * 1.25; return { hub, height: Number((split.match(new RegExp('\\t' + k + " = \\{ frame = '[^']+', unit = '\\w+', bar = \\d+, height = (\\d+)")) || [])[1]), interior: unitNum(split, k, 'castInterior'), stalk: unitNum(split, k, 'castStalk') }; };
  const gp = g('player'); const gt = g('target');
  check('1.3.3 bamboo cast bar size: exactly the whole composition\'s width (2 x (inner + bar): health end to resource end), the interior 155 % of the split bar (Player 37.5 units = 50 px over 24 = 32 px, Target 33 = 44 px over 21 = 28 px; whole pixels at 2560 x 1440, UI scale 0.71), stalks 7.5 / 5.25 units (10 / 7 px) - the interior at least two thirds of the bar; the same numbers in the split layer (T.SPLIT castInterior / castStalk / castValues, castbar)',
    /g\.castWidth = 2 \* \(g\.inner \+ g\.bar\) -- the whole composition/.test(split) && /g\.castHeight = g\.castInterior \+ 2 \* C\.inner \* g\.castStalk/.test(split)
    && [gp, gt].every((x) => x.interior / x.height > 1.5 && x.interior / x.height < 1.6 && Math.abs(x.interior * PX0 - Math.round(x.interior * PX0)) < 0.1 && Math.abs(x.stalk * PX0 - Math.round(x.stalk * PX0)) < 0.1 && x.interior / (x.interior + 2.2 * x.stalk) > 0.65)
    && Math.round(gp.interior * PX0) === 50 && Math.round(gt.interior * PX0) === 44
    && 112 - (Math.max(11 + unitNum(split, 'target', 'castValues'), gt.hub / 2) + 3) - (gt.interior + 2.2 * gt.stalk) >= 10 + 24 + 1 /* the Target bar's top clear of the BANZAI wordmark (Compat.LOGO, the default Target place) */
    && /splitTargetY = 112,/.test(theme) && /Compat\.LOGO = \{ height = 24, top = -10 \}/.test(src('Compat.lua'))
    && ['player', 'target'].every((k) => ['castInterior', 'castStalk', 'castValues'].every((f) => unitNum(split, k, f) === tsplit(k, f)))
    && /Split\.CAST_BAR = \{ inner = 1\.1, gap = 3 \}/.test(split) && /castbar = \{ inner = 1\.1, gap = 3 \}/.test(T));
  check('1.3.3 bamboo cast bar place: its bottom centre on the hub\'s centre, castLift above it - above the values (their room at the largest display size) and the hub\'s top with a 3-unit gap; the spell name centred on the bar, the timer at its right end clear of the rope tie; the class bar above the cast bar while it is on (Transform), back above the values when it is off',
    /bar:SetPoint\('BOTTOM', hub, 'CENTER', 0, g\.castLift\)/.test(cast) && /g\.castLift = math\.max\(math\.floor\(g\.height \/ 2 \+ 0\.5\) \+ def\.castValues, hub \/ 2\) \+ C\.gap/.test(split) && /g\.castLift = math\.max\(Round\(g\.height \/ 2\) \+ d\.castValues, hub \/ 2\) \+ C\.gap/.test(T)
    && unitNum(split, 'player', 'castValues') + 3 >= 2 + 15 * 1.2 + 2 && unitNum(split, 'target', 'castValues') + 3 >= 2 + 14 * 1.2 + 2 /* 2 units clear of the values at the largest display size */
    && /bar\.name:SetPoint\('CENTER', bar, 'CENTER', 0, 0\)/.test(cast) && /bar\.name:SetJustifyH\('CENTER'\)/.test(cast) && /bar\.time:SetPoint\('RIGHT', bar, 'RIGHT', -right, 0\)/.test(cast) && /local right = S\.tie \* d \* 0\.65 \+ S\.pad/.test(cast)
    && /if opts\.splitCastBar ~= false then bottom = Round\(g\.castLift \+ g\.castHeight \+ C\.gap\) end/.test(T) && /local bottom = Round\(g\.height \/ 2\) \+ C\.values \+ C\.gap/.test(T));
  const castMedia = [...strip0(cast).matchAll(/SetTexture\(([^,)]+)/g)].map((m) => m[1].trim());
  check('1.3.3 bamboo cast bar construction: the approved panel bamboo (Banzai\'s BanzaiStalk / BanzaiStalkEnd / BanzaiRopeTie, the panel style\'s Theme:PanelStalk / PanelRope colours, the panel node period) - top / bottom stalks, an end piece at each end, a rope tie on each crossing, inside the outline - round a dark translucent interior; Banzai media only (no game texture, no spell icon on the bar)',
    /local STALK, STALK_END, ROPE = Theme\.MEDIA \.\. 'BanzaiStalk', Theme\.MEDIA \.\. 'BanzaiStalkEnd', Theme\.MEDIA \.\. 'BanzaiRopeTie'/.test(cast) && /Theme:PanelStalk\(p\.stalk, p\.fa, p\.pa, p\.vary\)/.test(cast) && /Theme:PanelRope\(1\), Theme:PanelRope\(0\)/.test(cast)
    && /for _, st in ipairs\(\{ \{ 'top', axis, 1 \}, \{ 'bottom', H - axis, 0 \} \}\) do/.test(cast) && /for _, st in ipairs\(\{ \{ 'left', axis, true \}, \{ 'right', W - axis, false \} \}\) do/.test(cast) && /local c = math\.max\(axis, size \* 0\.30\)/.test(cast)
    && castMedia.length > 0 && castMedia.every((m) => /^(path|Theme\.WHITE|BAR|ROPE)$/.test(m)) && !/info\.texture|Interface\\\\/.test(strip0(cast))
    && ['BanzaiStalk', 'BanzaiStalkEnd', 'BanzaiRopeTie', 'BanzaiBar'].every((n) => fs.existsSync(path.join(DIST, 'BushidoPrivateCompat', 'media', n + '.tga'))));
  check('1.3.3 cast progress from the game only: the duration object on SetTimerDuration (a cast / empower ElapsedTime - left to right; a channel RemainingTime - drains right to left), plain start / end only when they are plain numbers (stepped by the hub\'s clock, the only OnUpdate in Split.lua; none in CastBar.lua), no fill when the game keeps both; non-interruptible through SetAlphaFromBoolean (never tested); interrupted crimson / cyan, failed / cancelled cleared; nothing hooked',
    /local direction = \(info\.kind == 'channel'\) and Enum\.StatusBarTimerDirection\.RemainingTime or Enum\.StatusBarTimerDirection\.ElapsedTime/.test(cast) && /status:SetTimerDuration\(info\.duration, /.test(cast)
    && /elseif PlainNumber\(info\.startMS\) and PlainNumber\(info\.endMS\) and info\.endMS > info\.startMS then/.test(cast) && /status:SetShown\(timed\) -- the game keeps the timing/.test(cast) && /bar\.status:SetValue\(p\.channel and \(p\.start \+ p\.finish - now\) or now\)/.test(cast)
    && /t:SetAlphaFromBoolean\(notInterruptible, on, 0\)/.test(cast) && /elseif not IsSecret\(notInterruptible\) then/.test(cast) && !/if notInterruptible then/.test(strip0(cast))
    && /if hub\.bar and hub\.bar\.plain then ns\.CastBar\.Step\(hub\.bar\) end/.test(split) && !/OnUpdate|NewTicker|hooksecurefunc|HookScript|UNIT_AURA|GetAttribute|SetAttribute|pcall\(/.test(strip0(cast))
    && (strip0(split).match(/OnUpdate/g) || []).length === 1 && /interrupted = \{ 0\.82, 0\.06, 0\.22 \}/.test(cast) && /cyan = \{ 0\.30, 0\.90, 1\.00 \}/.test(cast));
  // G. BANZAI CLASSIC isolated, the settings, Character Sync, the version
  check('1.3.3 BANZAI CLASSIC isolated: nothing of the cast bar exists outside a split session (Split:Build needs the session; the split layer is written only for SPLIT; LayerOptions carries splitCastBar only in SPLIT, so a CLASSIC layer\'s signature is the one it had); the classic frames\' code (Compat.lua) unchanged',
    /if not self:Session\(\) or InCombatLockdown\(\) then return false end/.test(body(split, 'function Split:Build()')) && /\t\topts\.splitCastBar = CompatSetting\('splitCastBar', true\) ~= false/.test(body(restore, 'function Restore:LayerOptions()'))
    && body(restore, 'function Restore:LayerOptions()').indexOf('opts.splitCastBar') > body(restore, 'function Restore:LayerOptions()').indexOf("if T.FrameStyle(CompatSetting('frameStyle', 'CLASSIC')) == 'SPLIT' then")
    && /version = 3,/.test((T.match(/T\.SPLIT = \{[\s\S]*?\n\}/) || [''])[0]) && git('addons/BushidoPrivateCompat/Compat.lua', TAG132) === now('addons/BushidoPrivateCompat/Compat.lua'));
  check('1.3.3 SPLIT CAST BAR settings (UNIT FRAMES > FRAME STYLE): bamboo cast bar (a reload key: the class bar\'s place), spell name and timer (at once) - on by default, every read brings a bad value back on, per character; Character Sync carries the choices (every DEFAULTS key), never a live cast; /banzai status names them',
    /splitCastBar = true,/.test(theme) && /splitCastName = true,/.test(theme) && /splitCastTimer = true,/.test(theme) && /for _, key in ipairs\(\{ 'splitCastBar', 'splitCastName', 'splitCastTimer' \}\) do -- 1\.3\.3: on unless plainly off\n\t\tif type\(db\[key\]\) ~= 'boolean' then db\[key\] = true end/.test(theme)
    && /castBar = Section\(15, 'SPLIT CAST BAR'/.test(options) && /Options\.SplitToggle\(2, 'splitCastBar'/.test(options) && /Options\.SplitToggle\(3, 'splitCastName'/.test(options) && /Options\.SplitToggle\(4, 'splitCastTimer'/.test(options)
    && /splitCastBar = true \} -- 1\.3\.3/.test(restore) && /Restore\.SPLIT_ART = \{ splitHpText = true, splitPowerText = true, splitTargetPlate = true, splitCastName = true, splitCastTimer = true \}/.test(restore)
    && /split cast bar \(Player \/ Target\): %s, spell name: %s, timer: %s/.test(restore) && /the split cast bar \(1\.3\.3: on \/ off, spell name, timer - the choices only, never a live cast\)/.test(sync) && /for k in pairs\(self\.DEFAULTS\) do out\[k\]/.test(theme));
  check('1.3.3 version 1.3.3 everywhere: both TOCs, Banzai Art, Banzai (GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the reload dialog, the update message), the AFK screen, the README',
    compatToc.fields.Version === '1.3.3' && restoreToc.fields.Version === '1.3.3' && /Theme\.VERSION = '1\.3\.3'/.test(theme) && /local VERSION = '1\.3\.3'/.test(restore)
    && /updated to %s %s: BANZAI SPLIT - larger Player \/ Target identities, the spell icon in the centre while you cast, a bamboo cast bar above the frame/.test(restore) && readme.includes('Version: **BANZAI 1.3.3**') && /1\.3\.3 \(PvP frame safety, a synthetic TARGET NPC preview/.test(readme));
  // H. tests, targeted mutation, backup
  const tc = now('tests/test_compat.lua'); const tr = now('tests/test_restore.lua'); const mut = now('tools/mutate.js');
  const mutOut = fs.existsSync(path.join(ROOT, 'build', 'mutation-1.3.3.txt')) ? fs.readFileSync(path.join(ROOT, 'build', 'mutation-1.3.3.txt'), 'utf8') : '';
  const mutLine = (mutOut.match(/mutation: (\d+) of (\d+) mutants killed/) || []);
  check('1.3.3 tests and targeted mutation: 1.3.3 tests for the PvP geometry / forbidden objects, the NPC preview\'s isolation, the 125 % identity, the cast flow, the bar geometry and states, the settings and the split layer; the 1.3.3 mutants cover exactly the changed contracts and every one is killed (no full-project mutation run)',
    (tc.match(/^test\('1\.3\.3 /gm) || []).length >= 8 && (tr.match(/^test\('1\.3\.3 /gm) || []).length >= 1
    && ['forbidden PvP geometry', 'safe overlay emphasis', 'safe combat deferral', 'NPC preview isolation', 'no live preview object', 'no asynchronous preview media', 'icon 125 %', 'spell icon replaces the class icon', 'radial progress removed', 'class icon restoration', 'cast bar geometry', 'progress direction', 'interrupted / failed cleanup', 'non-interruptible', 'classic isolation'].every((k) => mut.includes(`['${k}'`))
    && mutLine.length === 3 && mutLine[1] === mutLine[2] && Number(mutLine[2]) >= 30 && /BANZAI 1\.3\.3 targeted mutants/.test(mutOut), mutLine[0] || 'no build/mutation-1.3.3.txt');
  const b132 = backupDirs.filter((d) => /^Banzai-1\.3\.2-\d{8}-\d{6}$/.test(d)).sort().pop();
  const b132dir = b132 && path.join(BACKUP_ROOT, b132);
  check('1.3.3 BANZAI 1.3.2 backed up first (tools/backup.js, WoW closed): the installed 1.3.2 addons, the WTF folder as last saved, the repository at banzai-1.3.2 (bundle) and the third-party addon state',
    Boolean(b132dir) && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(b132dir, 'addons', a))) && fs.readFileSync(path.join(b132dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').includes('## Version: 1.3.2')
    && fs.existsSync(path.join(b132dir, 'workspace', 'banzai-1.3.2.bundle')) && files(path.join(b132dir, 'WTF-as-last-saved')).length > 1000 && fs.existsSync(path.join(b132dir, 'thirdparty-baseline.json')), b132dir || 'none');
}

// 24. BANZAI 1.3.4 hotfix: the PvP frames hands-off, the lower bamboo cast bar
// (1.3.5: the 1.3.4 release itself - its code and scope read from the banzai-1.3.4 tag; block 25 for what 1.3.5 changed)
{
  const TAG133 = 'banzai-1.3.3';
  const TAG134 = 'banzai-1.3.4';
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const src = (name) => git('addons/BushidoPrivateCompat/' + name, TAG134) || '';
  const rsrc = (name) => git('addons/BushidoPrivateRestore/' + name, TAG134) || '';
  const now = (rel) => git(rel, TAG134);
  const transformSource = rsrc('Transform.lua');
  const compatToc = { fields: { Version: ((src('BushidoPrivateCompat.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const restoreToc = { fields: { Version: ((rsrc('BushidoPrivateRestore.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff = (rel) => { const c = new Map(); for (const l of lines(git(rel, TAG133))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(now(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  const pvp = src('PvPFrames.lua'); const split = src('Split.lua'); const cast = src('CastBar.lua'); const theme = src('Theme.lua');
  const restore = rsrc('Restore.lua'); const options = rsrc('Options.lua'); const T = transformSource; const readme = now('README.md');
  const PX0 = 0.71 * 1440 / 768;
  const code = strip0(pvp);
  // A. scope
  const all = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => /\.(lua|toc)$/.test(x)).map((x) => a + '/' + x));
  const changed = all.filter((x) => git('addons/' + x, TAG133) !== now('addons/' + x)).sort();
  check('1.3.4 scope (a hotfix): since 1.3.3 only the PvP frames (PvPFrames.lua), the cast bar\'s numbers (Split.lua, Transform.lua) and its comment (CastBar.lua), the version / texts (Theme, Restore, Options) and both TOCs - Identity, Preview (the TARGET NPC sample), Compat, Health, TargetPlate (nameplates), Sync and everything else untouched',
    changed.join() === 'BushidoPrivateCompat/BushidoPrivateCompat.toc,BushidoPrivateCompat/CastBar.lua,BushidoPrivateCompat/PvPFrames.lua,BushidoPrivateCompat/Split.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/BushidoPrivateRestore.toc,BushidoPrivateRestore/Options.lua,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Transform.lua', changed.join(', '));
  const splitD = diff('addons/BushidoPrivateCompat/Split.lua'); const castD = diff('addons/BushidoPrivateCompat/CastBar.lua');
  check('1.3.4 Split.lua / CastBar.lua: only the cast bar\'s interior and stalk numbers changed (Player 37.5 / 7.5 -> 22.5 / 4.5, Target 33 / 5.25 -> 19.5 / 3.75); the spell name / timer sizes, the cast states, the hub, the identity and the TARGET NPC sample byte-for-byte as 1.3.3',
    splitD.length === 4 && splitD.every((l) => /^[-+]identity = 1\.25, castInterior = [\d.]+, castStalk = [\d.]+, castValues = (20|18), castName = (16|15), castTime = (12|11) \},$/.test(l)) && castD.length === 0
    && git('addons/BushidoPrivateCompat/Identity.lua', TAG133) === now('addons/BushidoPrivateCompat/Identity.lua') && git('addons/BushidoPrivateCompat/Preview.lua', TAG133) === now('addons/BushidoPrivateCompat/Preview.lua'), [...splitD, ...castD].join(' | '));
  // B. the PvP frames hands-off
  check('1.3.4 PvP root cause retired (Darren\'s 22:46:33 CreateFrame "Attempt to access forbidden object" and 22:49:31 SetScript "blocked by secret aspects", both in Decorate <- Scan; 1.3.2\'s SetHeight before them): nothing is made, scripted or changed inside a party / arena frame\'s tree - Decorate a no-op, no scan of ElvUI\'s aura lists, no UNIT_AURA watcher, no Emphasize; the aura icons\' Banzai border / label / pulse gone from the live frames',
    /function PvP\.Decorate\(\) return nil end/.test(pvp) && !/function PvP\.Emphasize|function PvP:Scan|function PvP:ApplyEmphasis|BorderSet|DecorateExisting/.test(code)
    && !/UNIT_AURA|element\.buttons|\.container\b|frame\[key\]|'Auras'|'Debuffs'/.test(code) && !/CreateFrame\([^)]*,\s*(button|frame|health|region)\b/.test(code)
    && !/hooksecurefunc|HookScript|OnUpdate/.test(code));
  check('1.3.4 Banzai-owned PvP visuals: the trinket circles and the arena target / focus markers are Banzai\'s own frames on Banzai\'s PvP layer (BanzaiPvPLayer, a UIParent child), never children of a unit frame - given its strata / level and anchored to its health bar once, out of combat; shown only while the client plainly says the unit frame is visible; nothing set, shown, hidden, scripted or created on a frame Banzai did not make',
    /layer = CreateFrame\('Frame', 'BanzaiPvPLayer', UIParent\)/.test(pvp) && /local c = PvP\.Trinket\(PvP\.Layer\(\), size\)/.test(pvp) && /entry\.target = PvP\.Marker\(PvP\.Layer\(\), health,/.test(pvp) && /entry\.focus = PvP\.Marker\(PvP\.Layer\(\), health,/.test(pvp)
    && /function PvP:Build\(\)\n\tif InCombatLockdown\(\) then return false end/.test(pvp) && /local shown = frame:IsVisible\(\)\n\treturn not IsSecret\(shown\) and shown == true/.test(pvp)
    && !/\b(frame|health|region|entry\.frame|entry\.health)[:.](Set\w+|Show|Hide|ClearAllPoints|SetAllPoints|HookScript|CreateTexture|CreateFontString|CreateAnimationGroup|EnableMouse)\(/.test(code)
    && /c\.cd:SetScript\('OnCooldownDone'/.test(pvp) && (code.match(/SetScript\(/g) || []).length === 2 /* Banzai's own cooldown widget and its own event frame */);
  check('1.3.4 one central access gate (PvP.Accessible: issecrettable, IsForbidden first, HasAnySecretAspect, IsAnchoringSecret - the 12.x client\'s own answers) before anything is read from a unit frame or done with Banzai\'s frames that follow one; a refused frame is remembered and skipped - never probed, scripted or rebuilt on the 0.2 s refresh - and asked again only after a loading screen (PLAYER_ENTERING_WORLD); no pcall hides a refused call; a hidden swipe state is UNKNOWN',
    /PvP\.ACCESS = \{ 'IsForbidden', 'HasAnySecretAspect', 'IsAnchoringSecret' \}/.test(pvp) && /if issecrettable and issecrettable\(object\) then return false end/.test(pvp)
    && /if frame and not built\[frame\] and not refused\[frame\] then/.test(pvp) && /if entry\.refused or refused\[entry\.frame\] then return false end/.test(pvp)
    && /if event == 'PLAYER_ENTERING_WORLD' then PvP:Reconsider\(\) end/.test(pvp) && (code.match(/:Reconsider\(\)/g) || []).length === 2 /* its definition and the loading-screen call */ && !/Reconsider/.test(body(pvp, 'function PvP:Refresh()'))
    && /if not \(entry and Usable\(entry\)\) then return nil end/.test(pvp) && /if not Usable\(entry\) then return end/.test(pvp) && (code.match(/pcall\(/g) || []).length === 4 && !/pcall\(\s*Accessible|pcall\(PvP\./.test(code)
    && /if IsSecret\(running\) or not Accessible\(c\.cd\) then PvP\.PaintTrinket\(c, 'UNKNOWN'\)/.test(pvp));
  check('1.3.4 the truth on the settings page: the CC / dispel texts say the Banzai border is retired on the live frames (ElvUI\'s icon and glow stay) and that the level shapes the preview samples only',
    /1\.3\.4: Banzai no longer draws its magenta border and CC label on the live frames/.test(options) && /1\.3\.4: Banzai no longer draws its cyan border and DISPEL label on the live frames/.test(options));
  // C. the lower cast bar
  const num = (code0, key, field) => Number(((code0.match(new RegExp('\\t' + key + ' = \\{[^\\n]*\\n?[^\\n]*?' + field + ' = ([\\d.]+)')) || [])[1]));
  const was = git('addons/BushidoPrivateCompat/Split.lua', TAG133) || '';
  const heightOf = (c0, k) => num(c0, k, 'castInterior') + 2 * 1.1 * num(c0, k, 'castStalk');
  const tnum = (key, field) => Number(((T.match(new RegExp('\\t' + key + ' = \\{[^}\\n]*' + field + ' = ([\\d.]+)')) || [])[1])); // T.SPLIT: one line per unit
  check('1.3.4 the bamboo cast bar about 40 % lower: Player 22.5 units (30 px) / Target 19.5 (26 px) interiors at 2560 x 1440, UI scale 0.71 (1.3.3: 50 / 44 px), stalks 4.5 / 3.75 units (6 / 5 px) - whole pixels - the whole bar 40 / 38 % lower; the bamboo pieces placed again at the panel\'s own proportions (the strip 128 / 88 of the stalk, never a squashed texture); the spell name and timer sizes, the full width and the place above the values unchanged; the split layer the same numbers (version 4: the class bar follows the bar down)',
    ['player', 'target'].every((k) => { const cut = 1 - heightOf(split, k) / heightOf(was, k); return cut > 0.36 && cut < 0.44 && ['castName', 'castTime', 'castValues'].every((fl) => num(split, k, fl) === num(was, k, fl)) && ['castInterior', 'castStalk', 'castValues'].every((fl) => num(split, k, fl) === tnum(k, fl)) && Math.abs(num(split, k, 'castInterior') * PX0 - Math.round(num(split, k, 'castInterior') * PX0)) < 0.1 && Math.abs(num(split, k, 'castStalk') * PX0 - Math.round(num(split, k, 'castStalk') * PX0)) < 0.1; })
    && Math.round(num(split, 'player', 'castInterior') * PX0) === 30 && Math.round(num(split, 'target', 'castInterior') * PX0) === 26
    && /local strip = \(P\.texH \/ P\.texD\) \* d/.test(cast) && /g\.castWidth = 2 \* \(g\.inner \+ g\.bar\) -- the whole composition/.test(split) && /version = 4,/.test((T.match(/T\.SPLIT = \{[\s\S]*?\n\}/) || [''])[0]));
  check('1.3.4 the central icon and the TARGET NPC preview locked: the bar hub (no radial ring), the veil while a cast shows, the class art after, no icon on the bar; the synthetic NPC sample (its crest, its media requested at load, no game icon) as in 1.3.3',
    /if bar then return Identity\.BarHub\(h\) end -- 1\.3\.3/.test(src('Identity.lua')) && /\t\tSplit\.Veil\(hub, true\)/.test(split) && /if hub\.barHub then -- 1\.3\.3: the class art back, the bar gone\n\t\tSplit\.Veil\(hub, false\)/.test(split)
    && /npcCrest = Theme\.MEDIA \.\. 'BanzaiHubCrest'/.test(split) && !/Head_Dragon/i.test(strip0(split + src('Preview.lua'))) && !/info\.texture/.test(strip0(cast)));
  // D. version, README, tests, mutation, backup
  check('1.3.4 version 1.3.4 everywhere: both TOCs, Banzai Art, Banzai (GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the reload dialog, the update message), the AFK screen, the README',
    compatToc.fields.Version === '1.3.4' && restoreToc.fields.Version === '1.3.4' && /Theme\.VERSION = '1\.3\.4'/.test(theme) && /local VERSION = '1\.3\.4'/.test(restore)
    && /updated to %s %s: a slimmer bamboo cast bar/.test(restore) && readme.includes('Version: **BANZAI 1.3.4**') && /1\.3\.4 \(hotfix: the PvP frames hands-off, a lower bamboo cast bar/.test(readme));
  const tc = now('tests/test_compat.lua'); const tr = now('tests/test_restore.lua'); const mut = now('tools/mutate.js');
  const mutOut = fs.existsSync(path.join(ROOT, 'build', 'mutation-1.3.4.txt')) ? fs.readFileSync(path.join(ROOT, 'build', 'mutation-1.3.4.txt'), 'utf8') : '';
  const mutLine = (mutOut.match(/mutation: (\d+) of (\d+) mutants killed/) || []);
  check('1.3.4 tests and targeted mutation: 1.3.4 tests for the hands-off PvP frames, the access gate and its cache, the lower cast bar; the 1.3.4 mutants cover exactly the changed contracts and every one is killed (no full-project mutation run)',
    (tc.match(/^test\('1\.3\.4 /gm) || []).length >= 3 && (tr.match(/^test\('1\.3\.4 /gm) || []).length >= 1
    && ['forbidden object gate', 'unsafe Decorate removal', 'no child CreateFrame on protected PvP frames', 'no SetScript / HookScript on protected PvP frames', 'no protected geometry mutation', 'unsafe frames cached / skipped', 'cast-bar 40 % height reduction', 'text size preservation', 'full-width preservation', 'central spell-icon state preservation'].every((k) => mut.includes(`['${k}'`))
    && mutLine.length === 3 && mutLine[1] === mutLine[2] && Number(mutLine[2]) >= 20 && /BANZAI 1\.3\.4 targeted mutants/.test(mutOut), mutLine[0] || 'no build/mutation-1.3.4.txt');
  const b133 = backupDirs.filter((d) => /^Banzai-1\.3\.3-\d{8}-\d{6}$/.test(d)).sort().pop();
  const b133dir = b133 && path.join(BACKUP_ROOT, b133);
  check('1.3.4 BANZAI 1.3.3 backed up first (tools/backup.js, WoW closed): the installed 1.3.3 addons, the WTF folder as last saved, the repository at banzai-1.3.3 (bundle) and the third-party addon state',
    Boolean(b133dir) && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(b133dir, 'addons', a))) && fs.readFileSync(path.join(b133dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').includes('## Version: 1.3.3')
    && fs.existsSync(path.join(b133dir, 'workspace', 'banzai-1.3.3.bundle')) && files(path.join(b133dir, 'WTF-as-last-saved')).length > 1000 && fs.existsSync(path.join(b133dir, 'thirdparty-baseline.json')), b133dir || 'none');
}

// 25. BANZAI 1.3.5 targeted runtime cleanup: the gold lines and the strip traced (not Banzai's), Banzai's own PvP
// visuals cleaned up deterministically, developer surfaces hidden by default, the Details DAMAGE | HEALING divider
// (1.3.6: the 1.3.5 release itself - its code and scope read from the banzai-1.3.5 tag; block 26 for what 1.3.6 changed)
{
  const TAG134 = 'banzai-1.3.4';
  const TAG135 = 'banzai-1.3.5';
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const src = (name) => git('addons/BushidoPrivateCompat/' + name, TAG135) || '';
  const rsrc = (name) => git('addons/BushidoPrivateRestore/' + name, TAG135) || '';
  const now = (rel) => git(rel, TAG135);
  const compatToc = { fields: { Version: ((src('BushidoPrivateCompat.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const restoreToc = { fields: { Version: ((rsrc('BushidoPrivateRestore.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff = (rel) => { const c = new Map(); for (const l of lines(git(rel, TAG134))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(now(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  const pvp = src('PvPFrames.lua'); const compat = src('Compat.lua'); const theme = src('Theme.lua'); const preview = src('Preview.lua');
  const restore = rsrc('Restore.lua'); const T = rsrc('Transform.lua'); const readme = now('README.md');
  const code = strip0(pvp); const ccode = strip0(compat);
  const note = fs.existsSync(path.join(ROOT, 'docs', 'BANZAI-1.3.5-LINES-NOTE.md')) ? now('docs/BANZAI-1.3.5-LINES-NOTE.md') : '';
  const PX0 = 0.71 * 1440 / 768;
  // A. scope
  const all = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => /\.(lua|toc)$/.test(x)).map((x) => a + '/' + x));
  const changed = all.filter((x) => git('addons/' + x, TAG134) !== now('addons/' + x)).sort();
  check('1.3.5 scope (a targeted cleanup): since 1.3.4 only the Details divider and the PvP sweep call (Compat.lua), the PvP visuals\' roots and sweep (PvPFrames.lua), the version / texts (Theme, Restore) and both TOCs - Split, CastBar, Identity, Preview, Health, Tags, TargetPlate (nameplates), ActionButtons, Tracker, Transform (no layer key), Options, Sync, Roles and everything else untouched',
    changed.join() === 'BushidoPrivateCompat/BushidoPrivateCompat.toc,BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/PvPFrames.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/BushidoPrivateRestore.toc,BushidoPrivateRestore/Restore.lua', changed.join(', '));
  const compatD = diff('addons/BushidoPrivateCompat/Compat.lua'); const themeD = diff('addons/BushidoPrivateCompat/Theme.lua'); const restoreD = diff('addons/BushidoPrivateRestore/Restore.lua');
  check('1.3.5 Compat.lua only gains code (no line of 1.3.4\'s classic frames, panels, bamboo, titles, chat, minimap, BUFFS or Details placement changed or removed); Theme.lua only the version; Restore.lua only the version and its update message',
    compatD.length > 0 && compatD.every((l) => l.startsWith('+')) && themeD.join('|') === "-Theme.VERSION = '1.3.4'|+Theme.VERSION = '1.3.5'"
    && restoreD.length === 4 && restoreD.every((l) => /^[-+](local VERSION = '1\.3\.[45]'|Print\(format\('updated to %s %s: )/.test(l)), [...compatD.filter((l) => l.startsWith('-')), ...themeD, ...restoreD].join(' | '));
  // B. the lines and the strip: traced, not Banzai's
  const all0 = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(DIST, a)).filter((x) => /\.lua$/.test(x)).map((x) => strip0(fs.readFileSync(path.join(DIST, a, x), 'utf8'))));
  check('1.3.5 line ownership: no Banzai file makes a Line or a rotated / warped texture (CreateLine, SetStartPoint, SetEndPoint, SetThickness, SetRotation, SetVertexOffset) or carries the strip\'s labels (OFF / CD / DEF / INT / DISP / GUI) or the lines\' "Target N" / "Lost Page" labels; the only unit-relation visuals - the arena TARGET / FOCUS outlines - are rectangles with both corners on one region, every edge, the tab and the label inside them',
    all0.every((c) => !/CreateLine|SetStartPoint|SetEndPoint|SetThickness|SetRotation|SetVertexOffset/.test(c) && !/['"](OFF|CD|DEF|INT|DISP|GUI)['"]/.test(c) && !/['"]Target %d|Target %d['"]|'Target ' \.\.|Lost Page/.test(c))
    && /\tm:SetPoint\('TOPLEFT', region, 'TOPLEFT', -inset, inset\)\n\tm:SetPoint\('BOTTOMRIGHT', region, 'BOTTOMRIGHT', inset, -inset\)/.test(pvp)
    && /\t\tt:SetPoint\(side\[1\], m, side\[1\], 0, 0\)\n\t\tt:SetPoint\(side\[2\], m, side\[2\], 0, 0\)/.test(pvp) && /m\.tab:SetPoint\('TOPLEFT', m, 'TOPLEFT', inset, -inset\)/.test(pvp) && /m\.label:SetPoint\('BOTTOMRIGHT', m, 'BOTTOMRIGHT'/.test(pvp));
  check('1.3.5 the trace on record (docs/BANZAI-1.3.5-LINES-NOTE.md): what was seen, why it is not Banzai\'s nor any installed addon\'s (no line drawing, no labels in any addon or saved variable, world positions the addon API does not give, drawn under the game\'s interface), when it appeared, and the check to run (every AddOn disabled); Banzai hides nothing of another program\'s',
    /BANZAI draws no line/.test(note) && /No installed addon contains the labels/.test(note) && /world positions the addon API does not give/.test(note) && /drawn inside the game, under its interface/.test(note)
    && /Launch WoW with every AddOn disabled/.test(note) && /BANZAI does not hide or touch another program's frames/.test(note) && /docs\/BANZAI-1\.3\.5-LINES-NOTE\.md/.test(readme));
  // C. the cleanup lifecycle and the PvP safe layer
  check('1.3.5 deterministic cleanup: each PvP entry\'s parts are children of its root (Banzai\'s own, on the layer, all points on the layer, hidden until a refresh finds it usable); Settle shows a root only for a usable entry while Banzai Art is on; PvP:Sweep hides every root on a loading screen, a zone or spec change (all three watched) and Compat:Refresh sweeps when Banzai Art is off; target / focus changes settle the outlines at once',
    /local root = CreateFrame\('Frame', nil, PvP\.Layer\(\)\)\n\t+root:SetAllPoints\(PvP\.Layer\(\)\)\n\t+root:EnableMouse\(false\)\n\t+root:Hide\(\)/.test(pvp)
    && /local c = PvP\.Trinket\(root, size\)/.test(pvp) && /entry\.target = PvP\.Marker\(root, health,/.test(pvp) && /entry\.focus = PvP\.Marker\(root, health,/.test(pvp)
    && /if root and Accessible\(root\) then root:SetShown\(usable and Active\(\)\) end/.test(pvp) && /if not \(entry and Settle\(entry\)\) then return nil end/.test(pvp) && /if not Settle\(entry\) then return end/.test(pvp)
    && /PvP\.SWEEP_EVENTS = \{ PLAYER_ENTERING_WORLD = true, ZONE_CHANGED_NEW_AREA = true, PLAYER_SPECIALIZATION_CHANGED = true \}/.test(pvp) && /if PvP\.SWEEP_EVENTS\[event\] then PvP:Sweep\(\) end/.test(pvp)
    && /if entry\.root and Accessible\(entry\.root\) then entry\.root:Hide\(\) end/.test(pvp) && /'PLAYER_REGEN_ENABLED', 'PLAYER_SPECIALIZATION_CHANGED' \}\) do/.test(pvp)
    && /if event == 'PLAYER_TARGET_CHANGED' or event == 'PLAYER_FOCUS_CHANGED' then\n\t\tfor _, entry in pairs\(built\) do PvP:UpdateMarkers\(entry\) end\n\t\treturn/.test(pvp)
    && /\tif not active and ns\.PvPFrames and ns\.PvPFrames\.Sweep then ns\.PvPFrames:Sweep\(\) end/.test(body(compat, 'function Compat:Refresh()')));
  check('1.3.5 the 1.3.4 safe layer kept and nothing polls: no OnUpdate, ticker or UNIT_AURA in the PvP code; nothing set, shown, hidden, scripted or created on a frame Banzai did not make (the sweep and the roots only touch Banzai\'s own); two SetScript calls (its cooldown widget and event frame), four pcalls, the access gate and the loading-screen reconsideration as in 1.3.4',
    !/OnUpdate|NewTicker|C_Timer\.NewTimer|UNIT_AURA|hooksecurefunc|HookScript/.test(code)
    && !/\b(frame|health|region|entry\.frame|entry\.health)[:.](Set\w+|Show|Hide|ClearAllPoints|SetAllPoints|HookScript|CreateTexture|CreateFontString|CreateAnimationGroup|EnableMouse)\(/.test(code)
    && (code.match(/SetScript\(/g) || []).length === 2 && (code.match(/pcall\(/g) || []).length === 4 && /PvP\.ACCESS = \{ 'IsForbidden', 'HasAnySecretAspect', 'IsAnchoringSecret' \}/.test(pvp)
    && /if event == 'PLAYER_ENTERING_WORLD' then PvP:Reconsider\(\) end/.test(pvp) && /function PvP\.Decorate\(\) return nil end/.test(pvp) && /function PvP:Build\(\)\n\tif InCombatLockdown\(\) then return false end/.test(pvp));
  // D. developer surfaces hidden by default
  const defaults = (theme.match(/Theme\.DEFAULTS = \{([\s\S]*?)\n\}/) || [])[1] || '';
  const devKeys = [...defaults.matchAll(/^\t(\w+) = /gm)].map((m) => m[1]).filter((k) => /preview|debug|diagnos|dev|sample|test|strip/i.test(k));
  check('1.3.5 developer surfaces hidden by default: Banzai has no developer strip; no setting shows a preview / debug / diagnostic surface (previewState only names the samples\' state); the previews are built only when asked for, refused in combat and hidden when combat starts; the diagnostics are a settings-page text',
    devKeys.join() === 'previewState' && /previewState = 'NORMAL'/.test(defaults) && /if show and InCombatLockdown\(\) then/.test(body(preview, 'function Preview:Show(key, show)'))
    && /events:RegisterEvent\('PLAYER_REGEN_DISABLED'\)\nevents:SetScript\('OnEvent', function\(\)\n\tif Preview:AnyShown\(\) then\n\t\tPreview:HideAll\(\)/.test(preview) && /c = SINGLE\[key\] and self:BuildSingle\(key\) or self:BuildGroup\(key\)/.test(preview)
    && /function Options\.DiagnosticsText\(\)/.test(rsrc('Options.lua')), devKeys.join());
  // E. the Details divider
  const V = { px: 2, pad: 0.8, fade: 14, alpha: 0.5, parchment: 0.72 };
  check('1.3.5 the DAMAGE | HEALING divider: 2 screen pixels (1.5 units at Darren\'s 2560 x 1440, UI scale 0.71), snapped, on the Banzai Details frame\'s centre (the middle of the 6-unit gap between the windows), from 0.8 x the stalk below the top stalk to as far above the bottom one (clear of the stalks, titles, accents and rope ties), both ends fading over 14 units; textures of Banzai\'s Details frame (BORDER: over the glass / parchment, under the stalks), shown only while both meters are open',
    /Compat\.DETAILS_DIVIDER = \{ px = 2, pad = 0\.8, fade = 14, alpha = 0\.5, parchment = 0\.72 \}/.test(compat) && Math.abs(V.px / PX0 - 1.5) < 0.01
    && /local t = holder:CreateTexture\(nil, 'BORDER'\)\n\t\tt:SetTexture\(WHITE\)\n\t\tif t\.SetSnapToPixelGrid then t:SetSnapToPixelGrid\(true\) end/.test(compat) && /\tframe\.divider = DetailsDivider\(frame\)\n\tPainter\(function\(\) Compat:PaintDetailsDivider\(\) end\)/.test(compat)
    && /local width = V\.px \/ Theme\.PixelScale\(frame\)\n\tlocal top = P\.outer \+ d \+ V\.pad \* d\n\tlocal bottom = frame\.bh - \(P\.outer \+ d \+ V\.pad \* d\)/.test(compat) && /local x, y = frame\.bw \/ 2 - width \/ 2, top/.test(compat)
    && /local both = visible and loaded and DetailsWindow\(1\) ~= nil and DetailsWindow\(2\) ~= nil or false\n\t\tif both then self:LayoutDetailsDivider\(\) end\n\t\tfor _, t in ipairs\(frame\.divider\) do t:SetShown\(both\) end/.test(body(compat, 'function Compat:PlaceDetails(active)'))
    && 0.5 + 10 + V.pad * 10 >= 0.5 + 5 + (0.78 * 22 / 2 + 2) + 2 /* below the titles' accents at scale 1 */ && 0.8 * 10 >= 0.5 * 10);
  check('1.3.5 the divider\'s colour: top to bottom the BANZAI gradient lime -> green -> emerald -> violet -> purple (Theme.COLORS; green halfway between lime and emerald), the ends fading to 0, alpha 0.5 on GLASS / SOLID and 0.72 on HARDKORH PARCHMENT - restrained, not a beam; Details\' text colours (T.DETAILS_STYLE text / ink) and the outer bamboo frame untouched; tools/panelcheck.js draws it with the same numbers',
    /Compat\.DIVIDER_STOPS = \{ Theme\.COLORS\.lime, Theme\.Mix\(Theme\.COLORS\.lime, Theme\.COLORS\.emerald, 0\.5\), Theme\.COLORS\.emerald, Theme\.COLORS\.violet, Theme\.COLORS\.purple \}/.test(compat)
    && /local a = Theme:DB\(\)\.panelBackground == 'PARCHMENT' and V\.parchment or V\.alpha/.test(compat) && /Theme:Gradient\(t, 'VERTICAL', S\[1\], S\[1\], a, 0\)/.test(compat) && /Theme:Gradient\(t, 'VERTICAL', S\[#S\], S\[#S\], 0, a\)/.test(compat) && /Theme:Gradient\(t, 'VERTICAL', S\[i\], S\[i - 1\], a, a\)/.test(compat)
    && V.alpha <= 0.75 && V.parchment <= 0.75 && /text = \{ 1, 1, 1, 1 \}/.test(T) && /ink = \{ 0\.96, 0\.95, 0\.92, 1 \}/.test(T)
    && /const DIVIDER = \{ px: 2, pad: 0\.8, fade: 14, alpha: 0\.5, parchment: 0\.72 \};/.test(now('tools/panelcheck.js')) && /drawDivider\(cv, ox, oy, W, H, d, background\)/.test(now('tools/panelcheck.js')));
  // F. version, README, tests, mutation, backup
  check('1.3.5 version 1.3.5 everywhere: both TOCs, Banzai Art, Banzai (GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the reload dialog, the update message), the AFK screen, the README',
    compatToc.fields.Version === '1.3.5' && restoreToc.fields.Version === '1.3.5' && /Theme\.VERSION = '1\.3\.5'/.test(theme) && /local VERSION = '1\.3\.5'/.test(restore)
    && /updated to %s %s: a thin gradient divider between the DAMAGE and HEALING meters/.test(restore) && readme.includes('Version: **BANZAI 1.3.5**') && /1\.3\.5 \(targeted runtime cleanup: the gold lines and the strip traced/.test(readme));
  const tc = now('tests/test_compat.lua'); const tr = now('tests/test_restore.lua'); const mut = now('tools/mutate.js');
  const mutOut = fs.existsSync(path.join(ROOT, 'build', 'mutation-1.3.5.txt')) ? fs.readFileSync(path.join(ROOT, 'build', 'mutation-1.3.5.txt'), 'utf8') : '';
  const mutLine = (mutOut.match(/mutation: (\d+) of (\d+) mutants killed/) || []);
  check('1.3.5 tests and targeted mutation: 1.3.5 tests for the hidden-by-default state at login, the line ownership, the cleanup lifecycle and the divider (compat) and the version-only update (restore); the 1.3.5 mutants cover exactly the listed contracts and every one is killed (no full-project mutation run)',
    (tc.match(/^test\('1\.3\.5 /gm) || []).length >= 4 && (tr.match(/^test\('1\.3\.5 /gm) || []).length >= 1
    && ['persistent-line ownership', 'cleanup lifecycle', 'debug UI hidden-by-default', 'PvP safe-layer preservation', 'Details divider existence', 'Details divider bounds', 'Details divider material compatibility'].every((k) => mut.includes(`['${k}'`))
    && mutLine.length === 3 && mutLine[1] === mutLine[2] && Number(mutLine[2]) >= 30 && /BANZAI 1\.3\.5 targeted mutants/.test(mutOut), mutLine[0] || 'no build/mutation-1.3.5.txt');
  const b134 = backupDirs.filter((d) => /^Banzai-1\.3\.4-\d{8}-\d{6}$/.test(d)).sort().pop();
  const b134dir = b134 && path.join(BACKUP_ROOT, b134);
  check('1.3.5 BANZAI 1.3.4 backed up first (tools/backup.js, WoW closed): the installed 1.3.4 addons, the WTF folder as last saved, the repository at banzai-1.3.4 (bundle) and the third-party addon state',
    Boolean(b134dir) && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(b134dir, 'addons', a))) && fs.readFileSync(path.join(b134dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').includes('## Version: 1.3.4')
    && fs.existsSync(path.join(b134dir, 'workspace', 'banzai-1.3.4.bundle')) && files(path.join(b134dir, 'WTF-as-last-saved')).length > 1000 && fs.existsSync(path.join(b134dir, 'thirdparty-baseline.json')), b134dir || 'none');
}

// 26. BANZAI 1.3.6 micro-polish: a real centre gutter between the Details DAMAGE and HEALING meters, read from the
// built code, the installed Details (read only) and the focused render
// (1.3.7: the 1.3.6 release itself - its code and scope read from the banzai-1.3.6 tag; the gutter's render is drawn
// afresh and must still measure 20 = 9 + 2 + 9; block 27 for what 1.3.7 changed)
{
  const read = (p) => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
  const TAG135 = 'banzai-1.3.5';
  const TAG136 = 'banzai-1.3.6';
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const src = (name) => git('addons/BushidoPrivateCompat/' + name, TAG136) || '';
  const rsrc = (name) => (name === 'Payloads.lua' ? read(path.join(DIST, 'BushidoPrivateRestore', name)) /* generated locally, never committed */ : git('addons/BushidoPrivateRestore/' + name, TAG136) || '');
  const now = (rel) => git(rel, TAG136);
  const compatToc = { fields: { Version: ((src('BushidoPrivateCompat.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const restoreToc = { fields: { Version: ((rsrc('BushidoPrivateRestore.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff = (rel) => { const c = new Map(); for (const l of lines(git(rel, TAG135))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(now(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  const num = (s0, re) => Number((s0.match(re) || [])[1]);
  const compat = src('Compat.lua'); const theme = src('Theme.lua'); const restore = rsrc('Restore.lua'); const T = rsrc('Transform.lua'); const readme = now('README.md');
  const was = git('addons/BushidoPrivateCompat/Compat.lua', TAG135) || '';
  const PX0 = 0.71 * 1440 / 768;
  // A. scope
  const all = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => /\.(lua|toc)$/.test(x)).map((x) => a + '/' + x));
  const changed = all.filter((x) => git('addons/' + x, TAG135) !== now('addons/' + x)).sort();
  check('1.3.6 scope (Details centre-gutter polish only): since 1.3.5 only the two windows\' numbers (Compat.lua, Transform.lua), their placement at the update (Restore.lua), the version / texts (Theme, Restore) and both TOCs - Player / Target, Split, CastBar, Identity (class icons), Preview, PvPFrames, Health, Tags, TargetPlate (nameplates), ActionButtons, Tracker, AFK, Tooltip, Options, Sync (Character Sync), Roles and everything else untouched',
    changed.join() === 'BushidoPrivateCompat/BushidoPrivateCompat.toc,BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/BushidoPrivateRestore.toc,BushidoPrivateRestore/Restore.lua,BushidoPrivateRestore/Transform.lua', changed.join(', '));
  const compatD = diff('addons/BushidoPrivateCompat/Compat.lua'); const transD = diff('addons/BushidoPrivateRestore/Transform.lua');
  const themeD = diff('addons/BushidoPrivateCompat/Theme.lua'); const restoreD = diff('addons/BushidoPrivateRestore/Restore.lua');
  check('1.3.6 Compat.lua and Transform.lua: one code line each - the windows\' width and gap (212 / 6 -> 207.5 / 15); the frame, the divider, the titles, the panels, PlaceDetails and everything else byte-for-byte in code; Theme.lua only the version',
    compatD.join('|') === '-width = 212, height = 124, gap = 6, title = 16, right = -47.15, bottom = 42,|+width = 207.5, height = 124, gap = 15, title = 16, right = -47.15, bottom = 42,'
    && transD.join('|') === '-T.DETAILS_LAYOUT = { width = 212, height = 124, gap = 6, right = -47.15, bottom = 42 }|+T.DETAILS_LAYOUT = { width = 207.5, height = 124, gap = 15, right = -47.15, bottom = 42 }'
    && themeD.join('|') === "-Theme.VERSION = '1.3.5'|+Theme.VERSION = '1.3.6'", [...compatD, ...transD, ...themeD].join(' | '));
  const allowed = [
    /^[-+]local VERSION = '1\.3\.[56]'$/, /^-Print\(format\('updated to %s %s: a thin gradient divider/, /^\+Print\(format\('updated to %s %s: a real gutter between the DAMAGE and HEALING meters/,
    /^-function Restore:LayoutDetails\(\)$/, /^\+function Restore:LayoutDetails\(geometryOnly\)$/,
    /^-if InCombatLockdown\(\) then return 'waiting \(combat\)' end$/, /^\+if InCombatLockdown\(\) then$/, /^\+if geometryOnly then self\.detailsGeometryPending = true end$/, /^\+return 'waiting \(combat\)'$/,
    /^\+if not geometryOnly then$/, /^\+end$/,
    /^-function Restore:LayoutDetailsSoon\(\)$/, /^\+function Restore:LayoutDetailsSoon\(geometryOnly\)$/, /^-local result = self:LayoutDetails\(\)$/, /^\+local result = self:LayoutDetails\(geometryOnly\)$/,
    /^-C_Timer\.After\(5, function\(\) Restore:LayoutDetails\(\) end\)$/, /^\+C_Timer\.After\(5, function\(\) Restore:LayoutDetails\(geometryOnly\) end\)$/,
    /^\+if Restore\.detailsGeometryPending then$/, /^\+Restore\.detailsGeometryPending = nil$/, /^\+Restore:LayoutDetails\(true\)$/,
    /^\+local details = _G\.Details$/, /^\+if details and details\.GetCurrentProfileName and details:GetCurrentProfileName\(\) == T\.PROFILE then self:LayoutDetailsSoon\(true\) end$/,
  ];
  check('1.3.6 Restore.lua: only the version, its update message and the geometry-only placement (LayoutDetails / LayoutDetailsSoon geometryOnly, the version-only update calling it on Banzai\'s Details profile, the wait for the end of combat) - every other line as in 1.3.5',
    restoreD.length === allowed.length + 1 /* the two VERSION lines share a pattern */ && restoreD.every((l) => allowed.some((r) => r.test(l))) && allowed.every((r) => restoreD.some((l) => r.test(l))), restoreD.join(' | '));
  // B. the gutter
  const DC = (compat.match(/Compat\.DETAILS = \{([\s\S]*?)\n\}/) || [])[1] || '';
  const G = { width: num(DC, /\bwidth = ([\d.]+)/), gap: num(DC, /\bgap = ([\d.]+)/), right: num(DC, /\bright = (-?[\d.]+)/), frameWidth: num(DC, /frameWidth = ([\d.]+)/), frameHeight: num(DC, /frameHeight = ([\d.]+)/), centerX: num(DC, /centerX = (-?[\d.]+)/) };
  const old = { width: 212, gap: 6 };
  const gutterPx = G.gap * PX0; const side = (gutterPx - 2) / 2;
  const edges = [-G.right + G.width, -G.right + G.width + G.gap].map((u) => u * PX0);
  check('1.3.6 a real centre gutter: the windows 207.5 wide (were 212), 15 apart (were 6) - 20 screen pixels at 2560 x 1440, UI scale 0.71: 9 empty, the 2 px divider, 9 empty (asked: 18 - 20 px, 8 - 9 a side); both inner edges on whole pixels there; both meters 4.5 narrower, the composition as wide as before (2 x 207.5 + 15 = 2 x 212 + 6 = 430), so the windows\' outer edges, the bamboo frame (493.31 x 161) and its place (centerX -215 from the right window, right -47.15) stay',
    G.width === 207.5 && G.gap === 15 && 2 * G.width + G.gap === 2 * old.width + old.gap && (old.width - G.width) * 2 === G.gap - old.gap
    && G.frameWidth === 493.31 && G.frameHeight === 161 && G.centerX === -215 && G.centerX === -(G.width + G.gap / 2) && G.right === -47.15
    && Math.abs(gutterPx - 20) < 0.05 && side >= 8 && side <= 9.05 && edges.every((e) => Math.abs(e - Math.round(e)) < 0.05),
    `gutter ${gutterPx.toFixed(2)} px = ${side.toFixed(2)} + 2 + ${side.toFixed(2)}; inner edges ${edges.map((e) => e.toFixed(3)).join(' / ')} px in from the right screen edge`);
  // C. everything of a meter inside its own window
  const payload = rsrc('Payloads.lua'); const p0 = payload.indexOf('\tdetailsProfile = {'); const dp = p0 < 0 ? '' : payload.slice(p0, payload.indexOf('\n\t},', p0));
  const spaces = [...dp.matchAll(/\n\t+space = \{\n\t+right = (-?[\d.]+),\n\t+left = (-?[\d.]+),/g)].map((m) => [Number(m[2]), Number(m[1])]);
  const offsets = [...dp.matchAll(/\n\t+row_offsets = \{\n\t+top = -?[\d.]+,\n\t+right = (-?[\d.]+),\n\t+left = (-?[\d.]+),/g)].map((m) => [Number(m[2]), Number(m[1])]);
  const writes = T.match(/row\.row_offsets = \{[^}]*\}/g) || [];
  const dwin = path.join(ADDONS, 'Details', 'frames', 'window_main.lua'); const dcode = fs.existsSync(dwin) ? read(dwin) : '';
  check('1.3.6 every row inside its own window, so nothing of DAMAGE reaches past the gutter\'s left edge and nothing of HEALING past its right edge (bars, tracks, names, values, highlights, the COMPACT icon, the rows\' mouse areas): Details (installed, read only) anchors a row at the window\'s left edge + space.left + row_offsets.left and makes it the window\'s width + space.right + row_offsets.right; the Banzai profile has space 0 / 0 and no side bars on every window, Banzai writes row offsets 0 / 0 (CURRENT and COMPACT) and anchors every row text on the bar, the name in from its left end, the values in from its right end',
    /local x = self\.row_info\.space\.left \+ leftOffset/.test(dcode) && /row:SetPoint\("topleft", baseframe, "topleft", x, y \+ row_y_offset\)/.test(dcode)
    && /bars\[index\]:SetWidth\(baseframe:GetWidth\(\) \+ self\.row_info\.space\.right \+ rightOffset\)/.test(dcode) && /newLine:SetWidth\(baseframe:GetWidth\(\)\+instance\.row_info\.space\.right \+ instance\.row_info\.row_offsets\.right\)/.test(dcode)
    && spaces.length >= 2 && spaces.every(([l, r]) => l >= 0 && r <= 0) && offsets.length >= 2 && offsets.every(([l, r]) => l >= 0 && r <= 0)
    && (dp.match(/show_sidebars = false/g) || []).length >= 2 && !/show_sidebars = true/.test(dp)
    && writes.length === 3 && writes.every((w) => /left = 0, right = 0,/.test(w)) && !/space\.(left|right)\s*=/.test(strip0(T + restore))
    && /\[1\] = DetailsText\('left', 2, 'left'\),\n\t\t\[2\] = DetailsText\('right', -73, 'right', -4\),\n\t\t\[3\] = DetailsText\('right', -38, 'right', -4\),\n\t\t\[4\] = DetailsText\('right', 0, 'right'\),/.test(T)
    && /\[1\] = CompactText\('bottomleft', 'topleft', C\.nameX,/.test(T) && /nameX = 21,/.test(T) && /\[4\] = CompactText\('bottomright', 'topright', 0, 'right'/.test(T) && /iconX = 0,/.test(T),
    `${spaces.length} space / ${offsets.length} offset entries in the Banzai profile; Details ${dcode ? 'read' : 'NOT FOUND'}`);
  // D. the placement
  const lay = body(restore, 'function Restore:LayoutDetails(geometryOnly)');
  check('1.3.6 placed through Details\' own window API as before (its size, the LibWindow anchor, saved by Details): the right window at the right edge, the left one width + gutter left of it; geometryOnly opens no window and changes no display or segment; a version-only update places both again on Banzai\'s Details profile only (once more 5 s later, after combat when it is on); no Details window made, Details\' code untouched (the third-party check above)',
    /\tplace\(right, L\.right\)\n\tplace\(left, L\.right - L\.width - L\.gap\)/.test(lay) && /window\.posicao\.normal\.w = L\.width \/ scale/.test(lay)
    && /if not geometryOnly then\n\t\tfor _, window in ipairs\(\{ left, right \}\) do/.test(lay) && /if not geometryOnly then\n\t\tlocal segment = left\.GetSegment and left:GetSegment\(\)/.test(lay) && /if geometryOnly then self\.detailsGeometryPending = true end/.test(lay)
    && /C_Timer\.After\(5, function\(\) Restore:LayoutDetails\(geometryOnly\) end\)/.test(body(restore, 'function Restore:LayoutDetailsSoon(geometryOnly)'))
    && /if details and details\.GetCurrentProfileName and details:GetCurrentProfileName\(\) == T\.PROFILE then self:LayoutDetailsSoon\(true\) end/.test(body(restore, 'function Restore:OnLogin()'))
    && /\tif Restore\.detailsGeometryPending then[^\n]*\n\t\tRestore\.detailsGeometryPending = nil\n\t\tRestore:LayoutDetails\(true\)\n\tend/.test(restore)
    && !/CreateInstance|NewInstance|CreateNewInstance/.test(strip0(restore + compat)) && (restore.match(/:LayoutDetails\(true\)|:LayoutDetailsSoon\(true\)/g) || []).length === 2);
  // E. the divider and the titles as in 1.3.5
  const same = (re) => { const a = (compat.match(re) || [null])[0]; const b = (was.match(re) || [undefined])[0]; return a !== null && a === b; };
  check('1.3.6 the divider and the titles as in 1.3.5: its numbers and colours (2 px, lime -> green -> emerald -> violet -> purple, fading ends, alpha 0.5 GLASS / SOLID, 0.72 PARCHMENT), its layout on the frame\'s centre (= the gutter\'s centre) and inside the interior, its paint; the titles\' layout - DAMAGE from window 1\'s left edge, HEALING to window 2\'s right edge (centerX unchanged, so neither moves), red / green, the Want Coffee display font; PlaceDetails - all byte-for-byte',
    ['local function DetailsDivider(holder)', 'function Compat:LayoutDetailsDivider()', 'function Compat:PaintDetailsDivider()', 'function Compat:LayoutDetailsTitle(t)', 'function Compat:DetailsTitle(chassis, index, side)', 'function Compat:PlaceDetails(active)'].every((h) => body(compat, h).length > 100 && body(compat, h) === body(was, h))
    && [/Compat\.DETAILS_DIVIDER = \{[^\n]*\}/, /Compat\.DIVIDER_STOPS = [^\n]*/, /Compat\.DETAILS_TITLES = \{[\s\S]*?\n\}/, /Compat\.DETAILS_TITLE = \{[^\n]*\}/, /Compat\.DETAILS_ACCENT = \{[\s\S]*?\n\}/].every(same)
    && /local x, y = frame\.bw \/ 2 - width \/ 2, top/.test(compat) && /local left = center \+ D\.centerX \+ T\.inset - T\.pad/.test(compat) && /local right = center - D\.centerX - T\.inset \+ T\.pad/.test(compat)
    && /Theme:SetDisplayFont\(t\.text, Theme:DisplaySize\(T\.size\), 'OUTLINE'\)/.test(compat));
  // F. the materials and the focused render
  const pc = now('tools/panelcheck.js');
  const gfile = path.join(ROOT, 'build', 'panelcheck', 'details-gutter.txt'); const gtext = fs.existsSync(gfile) ? read(gfile) : '';
  const glines = gtext.split('\n').filter((l) => /^  (BANZAI|HARDKORH) /.test(l));
  check('1.3.6 the materials and the focused render: GLASS / SOLID / PARCHMENT keep the divider\'s alpha and Details\' row ink (white; the 1.1.1 parchment off-white); tools/panelcheck.js draws the meters with Compat.DETAILS\' numbers and a details-gutter sheet at the real screen place (BANZAI GLASS, BANZAI SOLID, HARDKORH PARCHMENT) that measures the gutter from its own pixels - on record: 20 px = 9 empty + the 2 px divider + 9 empty on all three, the two meters equally wide, nothing of either in the gutter',
    /text = \{ 1, 1, 1, 1 \}/.test(T) && /ink = \{ 0\.96, 0\.95, 0\.92, 1 \}/.test(T) && /local c = parchment and T\.DETAILS_STYLE\.ink or T\.DETAILS_STYLE\.text/.test(T)
    && new RegExp(`const METERS = \\{ width: ${G.width}, gap: ${G.gap} \\};`).test(pc) && /const combos = \[\['BANZAI', 'GLASS'\], \['BANZAI', 'SOLID'\], \['HARDKORH', 'PARCHMENT'\]\];/.test(pc)
    && /const pass = gutter >= 18 && gutter <= 20 && left >= 8 && left <= 9 && right >= 8 && right <= 9 && divider === 2 && Math\.abs\(dmgW - healW\) <= 1;/.test(pc) && /const DIVIDER = \{ px: 2, pad: 0\.8, fade: 14, alpha: 0\.5, parchment: 0\.72 \};/.test(pc)
    && gtext.includes(`width ${G.width}, gap ${G.gap}`) && glines.length === 3 && ['BANZAI GLASS', 'BANZAI SOLID', 'HARDKORH PARCHMENT'].every((k) => glines.some((l) => l.startsWith('  ' + k + ': gutter 20 px = 9 empty + 2 px divider + 9 empty')))
    && glines.every((l) => /meters (\d+) \/ \1 px\)$/.test(l)) && !/OUT OF SPEC/.test(gtext), glines.map((l) => l.trim().split(' (')[0]).join(' | ') || 'no build/panelcheck/details-gutter.txt (node tools/panelcheck.js)');
  // G. version, README, tests, mutation, backup
  check('1.3.6 version 1.3.6 everywhere: both TOCs, Banzai Art, Banzai (GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the reload dialog, the update message), the AFK screen, the README',
    compatToc.fields.Version === '1.3.6' && restoreToc.fields.Version === '1.3.6' && /Theme\.VERSION = '1\.3\.6'/.test(theme) && /local VERSION = '1\.3\.6'/.test(restore)
    && /updated to %s %s: a real gutter between the DAMAGE and HEALING meters/.test(restore) && readme.includes('Version: **BANZAI 1.3.6**') && /1\.3\.6 \(micro-polish: a real centre gutter/.test(readme));
  const tc = now('tests/test_compat.lua'); const tr = now('tests/test_restore.lua'); const mut = now('tools/mutate.js');
  const mutOut = fs.existsSync(path.join(ROOT, 'build', 'mutation-1.3.6.txt')) ? read(path.join(ROOT, 'build', 'mutation-1.3.6.txt')) : '';
  const mutLine = (mutOut.match(/mutation: (\d+) of (\d+) mutants killed/) || []);
  check('1.3.6 tests and targeted mutation: 1.3.6 tests for the gutter, the divider in it, the titles and the materials (compat) and the window placement, the rows inside their windows and the geometry-only update (restore); the 1.3.6 mutants cover exactly the changed contracts and every one is killed (no full-project mutation run)',
    (tc.match(/^test\('1\.3\.6 /gm) || []).length >= 1 && (tr.match(/^test\('1\.3\.6 /gm) || []).length >= 1
    && ['gutter geometry', 'outer panel preserved', 'equal meters', 'rows inside their window', 'geometry-only update', 'update scope'].every((k) => mut.includes(`['${k}'`))
    && mutLine.length === 3 && mutLine[1] === mutLine[2] && Number(mutLine[2]) >= 12 && /BANZAI 1\.3\.6 targeted mutants/.test(mutOut), mutLine[0] || 'no build/mutation-1.3.6.txt');
  const b135 = backupDirs.filter((d) => /^Banzai-1\.3\.5-\d{8}-\d{6}$/.test(d)).sort().pop();
  const b135dir = b135 && path.join(BACKUP_ROOT, b135);
  check('1.3.6 BANZAI 1.3.5 backed up first (tools/backup.js, WoW closed): the installed 1.3.5 addons, the WTF folder as last saved, the repository at banzai-1.3.5 (bundle) and the third-party addon state',
    Boolean(b135dir) && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(b135dir, 'addons', a))) && fs.readFileSync(path.join(b135dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').includes('## Version: 1.3.5')
    && fs.existsSync(path.join(b135dir, 'workspace', 'banzai-1.3.5.bundle')) && files(path.join(b135dir, 'WTF-as-last-saved')).length > 1000 && fs.existsSync(path.join(b135dir, 'thirdparty-baseline.json')), b135dir || 'none');
}

// 27. BANZAI 1.3.7 HARDKORH PARCHMENT material correction: one material that is never stretched (the body tile, the
// worn edge strips, the corner atlas; Compat.ParchmentLayout for every panel), read from the built code / media, the
// banzai-1.3.6 tag, the parchment suite and the focused render's record
// (1.3.8: the 1.3.7 release itself - its code and scope read from the banzai-1.3.7 tag; the built media and the
// render's record are still the current ones, unchanged since; block 28 for what 1.3.8 changed)
{
  const read = (p) => fs.readFileSync(p, 'utf8').replace(/\r\n/g, '\n');
  const TAG137 = 'banzai-1.3.7';
  const gitAt = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const src = (name) => gitAt('addons/BushidoPrivateCompat/' + name, TAG137) || '';
  const rsrc = (name) => (name === 'Payloads.lua' ? read(path.join(DIST, 'BushidoPrivateRestore', name)) /* generated locally, never committed */ : gitAt('addons/BushidoPrivateRestore/' + name, TAG137) || '');
  const compatToc = { fields: { Version: ((src('BushidoPrivateCompat.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const restoreToc = { fields: { Version: ((rsrc('BushidoPrivateRestore.toc').match(/## Version: (\S+)/) || [])[1]) } };
  const TAG136 = 'banzai-1.3.6';
  const git = (rel, tag) => { try { return execSync(`git show ${tag}:${rel}`, { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n'); } catch (e) { return null; } };
  const now = (rel) => git(rel, TAG137);
  const body = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(a, code.indexOf('\nend', a)); };
  const lines = (x) => strip0(x || '').split('\n').map((l) => l.trim()).filter(Boolean);
  const diff = (rel) => { const c = new Map(); for (const l of lines(git(rel, TAG136))) c.set(l, (c.get(l) || 0) + 1); for (const l of lines(now(rel))) c.set(l, (c.get(l) || 0) - 1); return [...c].filter(([, n]) => n !== 0).map(([l, n]) => (n > 0 ? '-' : '+') + l); };
  const compat = src('Compat.lua'); const theme = src('Theme.lua'); const restore = rsrc('Restore.lua'); const readme = now('README.md');
  const was = git('addons/BushidoPrivateCompat/Compat.lua', TAG136) || '';
  const panel = require('./lib/panel'); const tgaLib = require('./lib/tga');
  const PM = panel.PARCHMENT;
  // A. scope
  const all = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((a) => fs.readdirSync(path.join(ROOT, 'addons', a)).filter((x) => /\.(lua|toc)$/.test(x)).map((x) => a + '/' + x));
  const changed = all.filter((x) => git('addons/' + x, TAG136) !== now('addons/' + x)).sort();
  check('1.3.7 scope (the parchment material only): since 1.3.6 only Compat.lua (the parchment), Theme.lua and Restore.lua (the version, its update message) and both TOCs - Transform (the Details row ink, the gutter numbers), Split, CastBar, Identity (class icons), PvPFrames, Preview, Health, Tags, TargetPlate (nameplates), ActionButtons, Tracker, AFK, Tooltip, Bar, Options, Sync (Character Sync), Roles and everything else untouched',
    changed.join() === 'BushidoPrivateCompat/BushidoPrivateCompat.toc,BushidoPrivateCompat/Compat.lua,BushidoPrivateCompat/Theme.lua,BushidoPrivateRestore/BushidoPrivateRestore.toc,BushidoPrivateRestore/Restore.lua', changed.join(', '));
  const themeD = diff('addons/BushidoPrivateCompat/Theme.lua'); const restoreD = diff('addons/BushidoPrivateRestore/Restore.lua');
  check('1.3.7 Theme.lua only the version (no new setting: the parchment brightness keeps its 70 - 110 % range); Restore.lua only the version and its update message - the 1.1.1 ink and the 1.3.6 geometry-only Details placement stay on the version-only path',
    themeD.join('|') === "-Theme.VERSION = '1.3.6'|+Theme.VERSION = '1.3.7'" && restoreD.length === 4 && restoreD.every((l) => /^[-+](local VERSION = '1\.3\.[67]'|Print\(format\('updated to %s %s: )/.test(l))
    && /if self\.ApplyDetailsInk then self:ApplyDetailsInk\(\) end/.test(body(restore, 'function Restore:OnLogin')) && /details:GetCurrentProfileName\(\) == T\.PROFILE then self:LayoutDetailsSoon\(true\) end/.test(restore)
    && /ArtRange\(6, 'parchmentBrightness', 'Parchment brightness', nil, 0\.7, 1\.1/.test(rsrc('Options.lua')), [...themeD, ...restoreD].join(' | '));
  const cutParchment = (code) => code
    .replace(/local PARCHMENT = Theme\.MEDIA \.\. 'BanzaiParchment'\n/, '')
    .replace(/local PARCHMENT_STRIPS = 8[^\n]*\nlocal PARCHMENT_SIDE_STRIPS = 2[^\n]*\n/, '')
    .replace(/local PARCHMENT_TEXTURES = \{[\s\S]*?\n\}\n/, '')
    .replace(/Compat\.PARCHMENT = \{[\s\S]*?\} \} \}\n/, '')
    .replace(/\tif holder\.parchment then\n[\s\S]*?\n\tend\nend\nCompat\.LayoutBamboo = LayoutBamboo\n/, 'end\nCompat.LayoutBamboo = LayoutBamboo\n')
    .replace(/function Compat\.ParchmentLayout\([\s\S]*?\nend\n/, '')
    .replace(/local function PanelBackground\(holder\)[\s\S]*?\nend\n/, '');
  const a0 = lines(cutParchment(was)); const b0 = lines(cutParchment(compat));
  const firstDiff = (a, b) => { for (let i = 0; i < Math.max(a.length, b.length); i++) if (a[i] !== b[i]) return `line ${i}: ${a[i]} | ${b[i]}`; return `the rest identical (${a.length} code lines)`; };
  check('1.3.7 Compat.lua: only the parchment changed - its three textures, Compat.PARCHMENT, Compat.ParchmentLayout, the parchment part of LayoutBamboo and PanelBackground; every other code line as in 1.3.6 (the bamboo stalks, ends and rope ties, the glass / solid background and its place, PaintBamboo, the panels\' sizes and places, the titles, the Details frame, gutter and divider, the minimap, chat, BUFFS, the unit frames)',
    a0.length > 500 && a0.join('\n') === b0.join('\n') && cutParchment(was) !== was && cutParchment(compat) !== compat && /function Compat\.ParchmentLayout\(pw, ph, d, kind\)/.test(compat), firstDiff(a0, b0));
  // B. the material and its one renderer
  const luaM = (compat.match(/Compat\.PARCHMENT = \{([\s\S]*?\} \} \})/) || [])[1] || '';
  const mnum = (k) => Number((luaM.match(new RegExp(`\\b${k} = ([0-9.]+)`)) || [])[1]);
  const layoutFn = body(compat, 'function Compat.ParchmentLayout(');
  const bg = body(compat, 'local function PanelBackground(holder)');
  const lb = compat.slice(compat.indexOf('\tif holder.parchment then'), compat.indexOf('Compat.LayoutBamboo = LayoutBamboo'));
  const wraps = Object.entries(panel.PARCHMENT_TEXTURES).every(([k, [name, h, v]]) => compat.includes(`${k} = { Theme.MEDIA .. '${name}', '${h}', '${v}' }`));
  check('1.3.7 one material, one shared renderer: Compat.PARCHMENT = tools/lib/panel.js PARCHMENT (the tile 1024 x 512 at 2 texels per unit, the strips 512 x 256, the corner atlas 128, a strip period of 8 corner sizes, a fixed phase per panel); every panel with a background (BUFFS, chat, Details - the minimap has none) gets its 13 pieces from Compat.ParchmentLayout through the one PanelBackground and LayoutBamboo: the body tile repeating both ways under the corners (CLAMP) and the strips (REPEAT along); the body\'s texels per unit fixed on both axes, the corners one corner size square, the strip halves mirrored; each piece anchored at both corners, no size of its own, no overlap allowance',
    ['tileW', 'tileH', 'density', 'edgeW', 'edgeH', 'corners', 'period'].every((k) => mnum(k) === PM[k]) && Object.entries(PM.phase).every(([k, v]) => new RegExp(`${k} = \\{ ${v[0]}, ${v[1]} \\}`).test(luaM)) && Object.keys(PM.phase).length === 3 && wraps
    && /local u1, v1 = u0 \+ pw \* M\.density \/ M\.tileW, v0 \+ ph \* M\.density \/ M\.tileH/.test(layoutFn) && /local c = math\.min\(Compat\.PANEL\.parchmentCorner \* d, pw \/ 2, ph \/ 2\)/.test(layoutFn) && /local period = M\.period \* c/.test(layoutFn)
    && /local uw, uh = \(mx - c\) \/ period, \(my - c\) \/ period/.test(layoutFn) && (layoutFn.match(/\n\tadd\('/g) || []).length === 13
    && /for i, piece in ipairs\(Compat\.ParchmentLayout\(100, 100, Compat\.PANEL\.stalk, 'chat'\)\) do/.test(bg) && /holder:CreateTexture\(nil, 'BACKGROUND', nil, piece\.texture == 'tile' and 0 or 1\)/.test(bg) && /t:SetTexture\(tex\[1\], tex\[2\], tex\[3\], 'TRILINEAR'\)/.test(bg)
    && /local pieces = Compat\.ParchmentLayout\(W - 2 \* inset, H - 2 \* inset, d, holder\.artKind\)/.test(lb) && /t:SetPoint\('TOPLEFT', holder, 'TOPLEFT', inset \+ piece\.x0, -\(inset \+ piece\.y0\)\)/.test(lb)
    && /t:SetPoint\('BOTTOMRIGHT', holder, 'TOPLEFT', inset \+ piece\.x1, -\(inset \+ piece\.y1\)\)/.test(lb) && !/SetSize|0\.25|SetTexture\(/.test(strip0(lb))
    && (compat.match(/PanelBackground\(holder\)/g) || []).length === 2 && /if not bare then PanelBackground\(holder\) end/.test(compat)
    && /BambooFrame\(frame, true\) -- the map itself is the interior/.test(compat) && (compat.match(/\tBambooFrame\(frame, false, (true|false)\)/g) || []).length === 3,
    `PARCHMENT ${luaM.replace(/\s+/g, ' ').trim()}`);
  // C. the media, as generated
  const gen = { BanzaiParchmentTile: panel.parchmentTile(), BanzaiParchmentEdge: panel.parchmentEdge(), BanzaiParchmentCorners: panel.parchmentCorners() };
  const built = Object.fromEntries(Object.keys(gen).map((n) => { const f = path.join(DIST, 'BushidoPrivateCompat', 'media', n + '.tga'); return [n, fs.existsSync(f) ? tgaLib.read(f) : null]; }));
  const every4 = (px, fn) => { for (let i = 0; i < px.length; i += 4) if (!fn(px[i], px[i + 1], px[i + 2], px[i + 3])) return false; return true; };
  check('1.3.7 the built parchment media are the generator\'s, texel for texel: BanzaiParchmentTile 1024 x 512 (opaque paper), BanzaiParchmentEdge 512 x 256 and BanzaiParchmentCorners 128 x 128 (black with alpha: they only darken the paper); the 1.1.0 BanzaiParchment sheet neither built nor referenced',
    Object.entries(gen).every(([n, g]) => built[n] && built[n].w === g.w && built[n].h === g.h && built[n].px.equals(g.px))
    && gen.BanzaiParchmentTile.w === PM.tileW && gen.BanzaiParchmentTile.h === PM.tileH && gen.BanzaiParchmentEdge.w === PM.edgeW && gen.BanzaiParchmentEdge.h === PM.edgeH && gen.BanzaiParchmentCorners.w === PM.corners
    && every4(gen.BanzaiParchmentTile.px, (r, g, b, a) => a === 255) && every4(gen.BanzaiParchmentEdge.px, (r, g, b) => r === 0 && g === 0 && b === 0) && every4(gen.BanzaiParchmentCorners.px, (r, g, b) => r === 0 && g === 0 && b === 0)
    && !fs.existsSync(path.join(DIST, 'BushidoPrivateCompat', 'media', 'BanzaiParchment.tga')) && !/'BanzaiParchment'/.test(compat),
    Object.entries(built).map(([n, t]) => `${n} ${t ? t.w + 'x' + t.h : 'missing'}`).join(', '));
  // D. the parchment suite (the textures, the joins, the Lua layout = the preview's) and the focused render
  const pt = require('../tests/test_parchment').run();
  const pfile = path.join(ROOT, 'build', 'panelcheck', 'parchment.txt'); const ptext = fs.existsSync(pfile) ? read(pfile) : '';
  const fresh = Boolean(ptext) && ['tools/lib/panel.js', 'tools/panelcheck.js'].every((rel) => fs.statSync(pfile).mtimeMs >= fs.statSync(path.join(ROOT, rel)).mtimeMs);
  const grainOf = (text, name) => (text.match(new RegExp(`^  ${name}[^:\\n]*: fibre ([\\d.]+) x ([\\d.]+) px \\(across x down\\), stretch ([\\d.]+)`, 'm')) || []);
  const at137 = ptext.slice(0, ptext.indexOf('grain, 1.3.6')); const at136 = ptext.slice(ptext.indexOf('grain, 1.3.6'), ptext.indexOf('synthetic sizes'));
  const g137 = ['BUFFS 335', 'BUFFS 3 ROWS', 'CHAT', 'DETAILS'].map((n) => grainOf(at137, n)); const g136 = ['BUFFS', 'CHAT', 'DETAILS'].map((n) => grainOf(at136, n));
  const synth = ['NARROW 120 x 330', 'SQUARE 260 x 260', 'MEDIUM-WIDE 560 x 200', 'VERY WIDE 1400 x 150', 'ONE TILE'].map((n) => grainOf(ptext, n));
  const roundG = (m) => m.length === 4 && Number(m[3]) > 0.8 && Number(m[3]) < 1.25 && Number(m[1]) / Number(m[2]) > 0.75 && Number(m[1]) / Number(m[2]) < 1.33;
  check('1.3.7 the parchment suite passes against the built Banzai Art (the tile seamless and isotropic in the approved colour, the strips periodic and turned, the corners byte-equal to the strips where they join, the Lua layout = the preview\'s at every size and border scale, nothing stretched, nothing read from a file) and the focused render, drawn after the last change to the generator and the renderer (tools/panelcheck.js at 2560 x 1440, UI scale 0.71; build/panelcheck/parchment.txt), has the grain one size and round on BUFFS (2 and 3 rows), chat and Details - where 1.3.6 stretched it 4 - 5 times across - and on the narrow, square, medium-wide and very wide synthetic sizes and a whole tile; every sheet and crop drawn; nothing out of spec',
    pt.failed === 0 && pt.passed >= 7 && fresh && g137.every(roundG) && g136.every((m) => m.length === 4 && Number(m[3]) > 3) && synth.every(roundG)
    && /the same grain on every panel/.test(ptext) && /one grain over all eight sizes/.test(ptext) && !/OUT OF SPEC/.test(ptext)
    && ['parchment', 'parchment-material', 'parchment-before-after', 'parchment-stress', 'parchment-seams', 'parchment-brightness', 'parchment-seams-corner-x4', 'parchment-seams-middle-x4', 'parchment-crop-buffs-centre-x4', 'parchment-crop-chat-centre-x4', 'parchment-crop-details-centre-x4', 'parchment-crop-details-corner-x4', 'parchment-crop-chat-corner-x4'].every((n) => fs.existsSync(path.join(ROOT, 'build', 'panelcheck', n + '.png'))),
    `suite ${pt.passed} / ${pt.passed + pt.failed}; 1.3.7 stretch ${g137.map((m) => m[3]).join(' / ')}; 1.3.6 ${g136.map((m) => m[3]).join(' / ')}; synthetic ${synth.map((m) => m[3]).join(' / ')}${fresh ? '' : '; parchment.txt missing or older than the generator / renderer (node tools/panelcheck.js)'}`);
  const seamLines = ptext.split('\n').filter((l) => /^  (BUFFS|BUFFS 3 ROWS|CHAT|DETAILS|VERY WIDE): cracks/.test(l));
  const excess = seamLines.map((l) => Number((l.match(/\(([+-]?[\d.]+)\)$/) || [])[1]));
  const edgeM = ptext.match(/the same worn edge on every panel and every side: (\d+) - (\d+) px deep/) || [];
  check('1.3.7 seams, cracks, the edge and the brightness in the render: over a contrasting checker no pixel of the paper uncovered (no crack) or darkened twice (no overlap), the body opaque; every join - corner | strip, the strip halves, the worn band\'s inner end, the tile\'s own wraps - within one 8-bit level of the paper beside it; the worn edge as deep on every panel and every side; the brightness scaling every pixel of the paper alike',
    seamLines.length === 5 && seamLines.every((l) => /cracks 0, doubled 0;/.test(l)) && excess.every((e) => Number.isFinite(e) && e < 1) && /the body opaque everywhere \(0 translucent body pixels\)/.test(ptext)
    && edgeM.length === 3 && Number(edgeM[2]) - Number(edgeM[1]) <= 1 && /brightness: every pixel of the paper scaled alike \(largest deviation 0\.00\d\d at 70 %, 0\.00\d\d at 110 %\)/.test(ptext),
    `joins at most ${Math.max(...excess).toFixed(2)} levels above the paper beside them; edge ${edgeM[1]} - ${edgeM[2]} px`);
  // E. everything else of the panels as before
  const theme136 = git('addons/BushidoPrivateCompat/Theme.lua', TAG136) || '';
  const pjs = now('tools/lib/panel.js'); const pjs136 = git('tools/lib/panel.js', TAG136) || '';
  const bambooPart = (code) => code.slice(code.indexOf("'use strict';"), code.indexOf('// ---- parchment'));
  const framePart = (code) => { const a = code.indexOf('// ---- frame geometry'); const b = code.indexOf('// ---- 1.3.7 the parchment\'s pieces'); return code.slice(a, b > a ? b : code.indexOf('module.exports')); };
  const legacyBody = (code, head) => { const a = code.indexOf(head); return a < 0 ? '' : code.slice(code.indexOf('\n', a), code.indexOf('\n}\n', a)); };
  check('1.3.7 BANZAI GLASS and SOLID and the rest of the panels exactly as before: Theme:Glass / Theme:Solid / SOLID_ALPHA and PaintBamboo (the glass, the stalk and rope colours, the one parchment brightness range and vertex colour on every piece) as in 1.3.6; the bamboo stalk / ends / rope tie generators and the frame geometry (tools/lib/panel.js) byte-for-byte as in 1.3.6; the 1.1.0 parchment generator kept as it was (legacyParchment) and no longer built; the 1.1.1 Details row ink, the 1.3.6 gutter numbers and the divider unchanged',
    ['function Theme:Glass(', 'function Theme:Solid('].every((h) => body(theme, h).length > 50 && body(theme, h) === body(theme136, h)) && /Theme\.SOLID_ALPHA = 0\.97/.test(theme)
    && body(compat, 'local function PaintBamboo(holder)').length > 300 && body(compat, 'local function PaintBamboo(holder)') === body(was, 'local function PaintBamboo(holder)')
    && bambooPart(pjs).length > 5000 && bambooPart(pjs) === bambooPart(pjs136) && framePart(pjs).length > 2000 && framePart(pjs) === framePart(pjs136)
    && legacyBody(pjs, 'function legacyParchment()').length > 1000 && legacyBody(pjs, 'function legacyParchment()') === legacyBody(pjs136, 'function parchment()') && !/legacyParchment\(\)/.test(body(pjs, 'function generate()'))
    && /ink = \{ 0\.96, 0\.95, 0\.92, 1 \}/.test(transformSource) && /T\.DETAILS_LAYOUT = \{ width = 207\.5, height = 124, gap = 15, right = -47\.15, bottom = 42 \}/.test(transformSource)
    && /width = 207\.5, height = 124, gap = 15, title = 16, right = -47\.15, bottom = 42,/.test(compat) && /Compat\.DETAILS_DIVIDER = \{ px = 2, pad = 0\.8, fade = 14, alpha = 0\.5, parchment = 0\.72 \}/.test(compat));
  // F. static, as before
  check('1.3.7 static, as before: the parchment laid out only when a panel\'s size or the stalk changes (LayoutBamboo\'s layout key), its 13 textures made once per panel (PanelBackground) and reused, painted only by the painters; no OnUpdate, the one 0.7.0 title ticker, no timer added; no image processing at run time (the textures are generated at build)',
    /if holder\.layoutKey == key then return end/.test(compat) && !/OnUpdate/.test(strip0(compat)) && (strip0(compat).match(/C_Timer\.NewTicker\(/g) || []).length === 1
    && (strip0(compat).match(/C_Timer\.After\(/g) || []).length === (strip0(was).match(/C_Timer\.After\(/g) || []).length && !/CreateTexture/.test(strip0(lb)) && (strip0(bg).match(/CreateTexture\(/g) || []).length === 2
    && !/SetHorizTile|SetVertTile|CreateMaskTexture|GetPixel|SetAlphaFromBoolean/.test(strip0(lb + bg + layoutFn)));
  // G. publication readiness of the material
  const pcode = pjs.replace(/\/\/[^\n]*/g, '');
  check('1.3.7 publication-ready material: Banzai-owned procedural art generated at build by tools/lib/panel.js (it reads no file or image, needs only tools/lib/bamboo.js, downloads nothing; the same every time), no generated texture committed, no reference image, no local path in Banzai Art; the README documents the three textures, how they are made and that the 1.1.0 sheet is no longer built',
    !/readFileSync|tga\.read|\.png'|\.jpe?g|design-references|https?:/.test(pcode) && [...pjs.matchAll(/require\('([^']+)'\)/g)].map((m) => m[1]).join() === './bamboo'
    && panel.parchmentEdge().px.equals(gen.BanzaiParchmentEdge.px) && panel.parchmentCorners().px.equals(gen.BanzaiParchmentCorners.px)
    && !tracked.some((f) => /\.(tga|blp)$/i.test(f) && /Parchment/i.test(f)) && !/[A-Za-z]:\\\\|\/Users\//.test(strip0(compat))
    && ['BanzaiParchmentTile', 'BanzaiParchmentEdge', 'BanzaiParchmentCorners'].every((n) => readme.includes('`' + n + '`')) && /generated at build by `tools\/lib\/panel\.js`, procedural, no image read; nothing committed/.test(readme) && /`BanzaiParchment` sheet is no longer built/.test(readme));
  // H. version, README, tests, mutation, backup
  check('1.3.7 version 1.3.7 everywhere: both TOCs, Banzai Art, Banzai (GUI header, HOME, CHARACTER SYNC, ABOUT, /banzai status, the reload dialog, the update message), the AFK screen, the README',
    compatToc.fields.Version === '1.3.7' && restoreToc.fields.Version === '1.3.7' && /Theme\.VERSION = '1\.3\.7'/.test(theme) && /local VERSION = '1\.3\.7'/.test(restore)
    && /updated to %s %s: HARDKORH PARCHMENT is one paper now/.test(restore) && readme.includes('Version: **BANZAI 1.3.7**') && /1\.3\.7 \(HARDKORH PARCHMENT material correction/.test(readme));
  const tc = now('tests/test_compat.lua'); const runjs = now('tests/run.js'); const mut = now('tools/mutate.js');
  const mutOut = fs.existsSync(path.join(ROOT, 'build', 'mutation-1.3.7.txt')) ? read(path.join(ROOT, 'build', 'mutation-1.3.7.txt')) : '';
  const mutLine = (mutOut.match(/mutation: (\d+) of (\d+) mutants killed/) || []);
  check('1.3.7 tests and targeted mutation: 1.3.7 tests for the material on the panels and at synthetic sizes (compat) and the generated textures and the Lua / preview layout (tests/test_parchment.js, run by npm test); the 1.3.7 mutants cover exactly the asked contracts - centre tiles, edge tiling, corner preservation, seam handling, brightness propagation, shared renderer, no texture stretching, Details gutter preservation - and every one is killed (no full-project mutation run)',
    (tc.match(/^test\('1\.3\.7 /gm) || []).length >= 2 && /require\('\.\/test_parchment'\)\.run\(\)/.test(runjs)
    && ['centre tiles', 'edge tiling', 'corner preservation', 'seam handling', 'brightness propagation', 'shared renderer', 'no texture stretching', 'Details gutter preservation'].every((k) => mut.includes(`['${k}'`))
    && mutLine.length === 3 && mutLine[1] === mutLine[2] && Number(mutLine[2]) >= 20 && /BANZAI 1\.3\.7 targeted mutants/.test(mutOut), mutLine[0] || 'no build/mutation-1.3.7.txt');
  const b136 = backupDirs.filter((d) => /^Banzai-1\.3\.6-\d{8}-\d{6}$/.test(d)).sort().pop();
  const b136dir = b136 && path.join(BACKUP_ROOT, b136);
  check('1.3.7 BANZAI 1.3.6 backed up first (tools/backup.js, WoW closed): the installed 1.3.6 addons, the WTF folder as last saved, the repository at banzai-1.3.6 (bundle) and the third-party addon state',
    Boolean(b136dir) && ['BushidoPrivateCompat', 'BushidoPrivateRestore', 'JiberishMedia'].every((a) => fs.existsSync(path.join(b136dir, 'addons', a))) && fs.readFileSync(path.join(b136dir, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').includes('## Version: 1.3.6')
    && fs.existsSync(path.join(b136dir, 'workspace', 'banzai-1.3.6.bundle')) && files(path.join(b136dir, 'WTF-as-last-saved')).length > 1000 && fs.existsSync(path.join(b136dir, 'thirdparty-baseline.json')), b136dir || 'none');
}

// 28. Licensed display-font selection lock: exact clean 1.3.8 base, typography-only scope, preserved launcher adapter.
{
  const BASE = 'banzai-1.3.8';
  const BASE_COMMIT = '3be9d3387877a05f1881b1fe282cdd9d126c75d2';
  const head = execSync('git rev-parse HEAD', { cwd: ROOT, encoding: 'utf8' }).trim();
  const base = execSync('git rev-parse ' + BASE, { cwd: ROOT, encoding: 'utf8' }).trim();
  let onBase = false; try { execSync('git merge-base --is-ancestor ' + BASE_COMMIT + ' HEAD', { cwd: ROOT, stdio: 'ignore' }); onBase = true; } catch (e) { onBase = false; }
  check('the release line descends from the clean banzai-1.3.8 compatibility release', onBase && base === BASE_COMMIT, head + ' / ' + base);

  const changed = execSync('git diff --name-only ' + BASE + ' --', { cwd: ROOT, encoding: 'utf8' }).split(/\r?\n/).filter(Boolean).sort();
  const allowed = new Set([
    'README.md',
    '.gitignore',
    'LEGACY-VALIDATION-NOTES.md',
    'assets/identity/class-sources.json',
    'docs/WANT-BANZAI-VALIDATOR-RECONCILIATION.md',
    'tools/lib/geometry.js',
    'tools/release.js',
    'addons/BushidoPrivateCompat/AFK.lua',
    'addons/BushidoPrivateCompat/Compat.lua',
    'addons/BushidoPrivateCompat/FontBakeoff.lua',
    'addons/BushidoPrivateCompat/Health.lua',
    'addons/BushidoPrivateCompat/media/fonts/OFL.txt',
    'addons/BushidoPrivateCompat/media/fonts/Shojumaru-Regular.ttf',
    'addons/BushidoPrivateCompat/Preview.lua',
    'addons/BushidoPrivateCompat/Split.lua',
    'addons/BushidoPrivateCompat/Theme.lua',
    'assets/identity/class-provenance.json',
    'addons/BushidoPrivateCompat/BushidoPrivateCompat.toc',
    'docs/BANZAI-IDENTITY-ICONS.md',
    'addons/BushidoPrivateRestore/Options.lua',
    'addons/BushidoPrivateRestore/Restore.lua',
    'addons/BushidoPrivateRestore/Sync.lua',
    'addons/BushidoPrivateRestore/Transform.lua',
    'addons/BushidoPrivateRestore/BushidoPrivateRestore.toc',
    'tests/test_compat.lua',
    'tests/test_restore.lua',
    'tools/build.js',
    'tools/backup.js',
    'tools/icons.js',
    'tools/lib/fonts.js',
    'tools/mutate.js',
    'tools/splitcheck.js',
    'tools/validate.js',
  ]);
  // 1.4.0: every shipped source file lost its "PRIVATE LOCAL USE ONLY" header line (release wording); a file
  // outside the allowed set may differ from the base ONLY by that header
  const headerNeutral = (s) => s.replace(/\r\n/g, '\n')
    .replace(/PRIVATE LOCAL USE ONLY\. Not for distribution\.|Part of BANZAI UI\. Credits and notices: the docs folder of the Banzai addon\./g, '<HEADER>')
    .replace(/PRIVATE LOCAL USE ONLY\.|Part of BANZAI UI\./g, '<HEADER>')
    .replace(/\(private restoration of JiberishUI Bushido\)|\(Banzai\)/g, '<ORIGIN>');
  const headerOnlyChange = (rel) => {
    try {
      const base = execSync('git show ' + BASE + ':' + rel, { cwd: ROOT, encoding: 'utf8' });
      return headerNeutral(base) === headerNeutral(fs.readFileSync(path.join(ROOT, rel), 'utf8'));
    } catch (e) { return false; }
  };
  const unexpected = changed.filter((rel) => !allowed.has(rel) && !/^addons\/BushidoPrivateCompat\/media\/fonts\//.test(rel) && !/^docs\/release\//.test(rel) && !headerOnlyChange(rel));
  check('selection-lock diff against banzai-1.3.8 is limited to display typography, licensing provenance, proof metadata, release wording and related tests/tooling', unexpected.length === 0, unexpected.join(', ') || changed.join(', '));

  const compatBase = execSync('git show ' + BASE + ':addons/BushidoPrivateCompat/Compat.lua', { cwd: ROOT, encoding: 'utf8' }).replace(/\r\n/g, '\n');
  const functionBody = (code, marker) => {
    const begin = code.indexOf(marker);
    if (begin < 0) return '';
    const end = code.indexOf('\nend', begin);
    return end < 0 ? '' : code.slice(begin, end + 4);
  };
  const compatPath = path.join(ROOT, 'addons', 'BushidoPrivateCompat', 'Compat.lua');
  const compatNow = fs.readFileSync(compatPath, 'utf8').replace(/\r\n/g, '\n');
  check('1.3.8 launcher-host adapter remains byte-identical to the approved base',
    ['function Compat.SetLauncherHost(host, on)', 'function Compat:LauncherHosted()'].every((name) => functionBody(compatNow, name) === functionBody(compatBase, name)));

  const liveHud = path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'LiveHud.lua');
  const restoreTocSource = fs.readFileSync(path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8');
  const options = fs.readFileSync(path.join(ROOT, 'addons', 'BushidoPrivateRestore', 'Options.lua'), 'utf8');
  const runtimeLua = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].flatMap((addon) => files(path.join(ROOT, 'addons', addon)).filter((file) => file.endsWith('.lua')).map((file) => fs.readFileSync(file, 'utf8'))).join('\n');
  check('abandoned Live HUD and optional Island bridge are absent', !fs.existsSync(liveHud) && !/LiveHud\.lua|LIVE HUD|IslandAPI/.test(restoreTocSource + options + runtimeLua));
  check('no active runtime registration or path points to Want Coffee (the retired-key migration may name it)', !/WantCoffee\.ttf|WANT_COFFEE|BANZAI Want Coffee|media\\fonts\\WantCoffee|file = "WantCoffee/i.test(strip0(runtimeLua)));

}
// 9. integrations read from the installed addons (read only)
const classIcon = (transformSource.match(/T\.CLASS_ICON = '([^']+)'/) || [])[1];
const jiCore = path.join(ADDONS, 'JiberishIcons', 'Core', 'Core.lua');
check(`class anchor: Jiberish style "${classIcon}" is shipped by the installed Jiberish Icons`, Boolean(classIcon) && fs.existsSync(path.join(ADDONS, 'JiberishIcons', 'Media', 'Class', classIcon + '.tga')) && fs.existsSync(jiCore) && new RegExp(classIcon + ' = \\{\\s*name = \'Fabled Class\'').test(fs.readFileSync(jiCore, 'utf8')), classIcon);
const mmtIcons = path.join(ADDONS, 'ElvUI_mMediaTag', 'modules', 'misc', 'class_icons.lua');
check('class anchor: mMediaTag registers Jiberish Icons class styles (its own integration)', fs.existsSync(mmtIcons) && /function mMT:AddJIIcons/.test(fs.readFileSync(mmtIcons, 'utf8')));
const ktConstants = path.join(ADDONS, '!KalielsTracker', 'Standard', 'System', 'Constants.lua');
const ktContexts = fs.existsSync(ktConstants) ? ((fs.readFileSync(ktConstants, 'utf8').match(/KT\.VISIBILITY_CONTEXTS = \{([^}]*)\}/) || [])[1] || '').match(/"([a-z+]+)"/g).map((s) => s.slice(1, -1)) : [];
const ourContexts = ((restoreSource.match(/KALIEL_CONTEXTS = \{([^}]*)\}/) || [])[1] || '').match(/'([a-z]+)'/g).map((s) => s.slice(1, -1));
check('Kaliel\'s Tracker: Banzai hides it through every one of its visibility contexts', ktContexts.length > 0 && ktContexts.join(',') === ourContexts.join(','), ktContexts.join(','));

console.log(results.join('\n'));
console.log(`\nvalidate: ${results.length - failures} passed, ${failures} failed`);
process.exit(failures ? 1 : 0);
