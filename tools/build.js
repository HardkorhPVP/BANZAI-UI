#!/usr/bin/env node
// Builds the private deployables into dist/ (never committed):
//   dist/JiberishMedia           unmodified copy of the audited JiberishMedia 1.1.0 addon
//   dist/BushidoPrivateCompat    original code + Geometry.lua generated from the historical auras
//                                (1.3.0: + IdentityManifest.lua, Darren's identity icons when present - 1.3.2: his 13;
//                                1.3.1: OFL-licensed Shojumaru supplied from the addon source and hash checked)
//   dist/BushidoPrivateRestore   original code + Payloads.lua (historical payload strings, verbatim)
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const src = require('./lib/bushido-source');
const geometry = require('./lib/geometry');
const codecs = require('./lib/codecs');
const bamboo = require('./lib/bamboo');
const panel = require('./lib/panel');
const tga = require('./lib/tga');
const wordmark = require('./lib/wordmark');
const bonsai = require('./lib/bonsai');
const hub = require('./lib/hub');
const identity = require('./lib/identity');
const fonts = require('./lib/fonts');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');

function copyDir(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    const a = path.join(from, entry.name);
    const b = path.join(to, entry.name);
    if (entry.isDirectory()) copyDir(a, b);
    else fs.copyFileSync(a, b);
  }
}

function longString(text) {
  let level = 1;
  while (text.includes(']' + '='.repeat(level) + ']')) level++;
  const eq = '='.repeat(level);
  return `[${eq}[${text}]${eq}]`;
}

function main() {
  for (const [name, repo, commit] of [['Bushido', src.BUSHIDO_REPO, src.BUSHIDO_COMMIT], ['JiberishMedia', src.JIBERISHMEDIA_REPO, src.JIBERISHMEDIA_COMMIT]]) {
    const head = src.headOf(repo);
    if (head !== commit) throw new Error(`${name} reference clone is at ${head}, expected ${commit}`);
    if (!src.isClean(repo)) throw new Error(`${name} reference clone has local changes`);
  }

  fs.rmSync(DIST, { recursive: true, force: true });
  fs.mkdirSync(DIST, { recursive: true });

  // 1. JiberishMedia, unchanged
  copyDir(path.join(src.JIBERISHMEDIA_REPO, 'JiberishMedia'), path.join(DIST, 'JiberishMedia'));

  // 2. BushidoPrivateCompat
  const { payloads, uiScale } = src.readPayloads();
  const compatDir = path.join(DIST, 'BushidoPrivateCompat');
  copyDir(path.join(ROOT, 'addons', 'BushidoPrivateCompat'), compatDir);
  const geo = geometry.build(payloads);
  fs.writeFileSync(path.join(compatDir, 'Geometry.lua'), geometry.toLua(geo, src.BUSHIDO_COMMIT));
  // Banzai media: original bamboo textures (procedural) + Darren's Banzai branding
  const mediaDir = path.join(compatDir, 'media');
  fs.mkdirSync(mediaDir, { recursive: true });
  for (const [name, t] of Object.entries(bamboo.generate())) tga.write(path.join(mediaDir, name + '.tga'), t.w, t.h, t.px);
  // 1.1.0 panel material: the bamboo frame stalks / ends / rope tie and the parchment
  for (const [name, t] of Object.entries(panel.generate())) tga.write(path.join(mediaDir, name + '.tga'), t.w, t.h, t.px);
  // 1.3.0 BANZAI SPLIT: the central hub (disc, class ring, accent, icon mask, cast swipe) and the class-disc sheet
  for (const [name, t] of Object.entries(hub.generate())) tga.write(path.join(mediaDir, name + '.tga'), t.w, t.h, t.px);
  // 1.3.0 Darren's own identity icons (1.3.2: assets/identity/class-<class>.png, made by tools/icons.js), converted when
  // present and valid; the manifest says which. A broken file is left out for its class only (that class falls back).
  const icons = identity.prepare(path.join(ROOT, 'assets', 'identity'));
  for (const r of icons.rejected) console.warn(`identity art: ${r.file} left out (its class falls back): ${r.errors.join('; ')}`);
  for (const f of icons.unknown) console.warn(`identity art: assets/identity/${f} is not a class master - ignored`);
  if (Object.keys(icons.classes).length) {
    const iconDir = path.join(mediaDir, 'BanzaiIdentity');
    fs.mkdirSync(iconDir, { recursive: true });
    for (const [name, px] of Object.entries(icons.images)) tga.write(path.join(iconDir, name + '.tga'), identity.CONTRACT.runtime, identity.CONTRACT.runtime, px);
    if (icons.details) tga.write(path.join(iconDir, 'details-classes.tga'), icons.details.w, icons.details.h, icons.details.px);
  }
  fs.writeFileSync(path.join(compatDir, 'IdentityManifest.lua'), identity.manifestLua(icons));
  // The shipped display faces are copied from the addon source and hash-checked; their supplied notices ride along.
  const fontDir = path.join(mediaDir, 'fonts');
  fs.rmSync(fontDir, { recursive: true, force: true });
  fs.mkdirSync(fontDir, { recursive: true });
  for (const f of fonts.prepare()) fs.writeFileSync(path.join(fontDir, f.file), f.data);
  for (const notice of fonts.NOTICES) fs.copyFileSync(path.join(fonts.DIR, notice), path.join(fontDir, notice));
  // HUD wordmark: the BANZAI letters cut out of Darren's own logo (transparent background)
  const wm = wordmark.generate(path.join(ROOT, 'assets', 'branding', 'BanzaiLogo.tga'));
  tga.write(path.join(mediaDir, 'BanzaiWordmark.tga'), wm.w, wm.h, wm.px);
  // combat logo: the original miniature tree behind the wordmark (full colour)
  const tree = bonsai.generate();
  tga.write(path.join(mediaDir, 'BanzaiBonsai.tga'), tree.w, tree.h, tree.px);
  for (const file of fs.readdirSync(path.join(ROOT, 'assets', 'branding')).filter((f) => f.endsWith('.tga'))) {
    fs.copyFileSync(path.join(ROOT, 'assets', 'branding', file), path.join(mediaDir, file));
  }

  // 3. BushidoPrivateRestore
  const restoreDir = path.join(DIST, 'BushidoPrivateRestore');
  copyDir(path.join(ROOT, 'addons', 'BushidoPrivateRestore'), restoreDir);
  // The historical exports are decoded here (ElvUI 16 cannot read "!E1!"),
  // so the addon needs no decoder libraries at runtime.
  const elvProfile = codecs.decodeElvUIExport(payloads['ElvUI.Profile1String']);
  const elvPrivate = codecs.decodeElvUIExport(payloads['ElvUI.Private1String']);
  const elvGlobal = codecs.decodeElvUIExport(payloads['ElvUI.Global1String']);
  if (elvProfile.type !== 'profile' || elvPrivate.type !== 'private' || elvGlobal.type !== 'global') {
    throw new Error('unexpected ElvUI export types');
  }
  const details = codecs.decodeDetailsExport(payloads['Details.Profile1String']);
  const lines = [
    `-- GENERATED LOCALLY by tools/build.js from Bushido commit ${src.BUSHIDO_COMMIT}:`,
    '-- historical ElvUI / Details exports decoded to tables, Edit Mode string verbatim.',
    '-- Derived from the JiberishUI Bushido profile (original profile data: JiberishUI, LLC). Redistributed as part of BANZAI UI with the original author\'s permission; see the docs folder of this addon.',
    'local _, ns = ...',
    'ns.Payloads = {',
    `\tsource = ${JSON.stringify(src.BUSHIDO_COMMIT)},`,
    `\tuiScale = ${uiScale},`,
    `\telvuiProfileKey = ${geometry.lua(elvProfile.key)},`,
    `\telvuiProfile = ${geometry.lua(elvProfile.data, '\t')},`,
    `\telvuiPrivate = ${geometry.lua(elvPrivate.data, '\t')},`,
    `\telvuiGlobal = ${geometry.lua(elvGlobal.data, '\t')},`,
    `\tdetailsProfile = ${geometry.lua(details.get('profile'), '\t')},`,
    `\teditMode = ${longString(payloads['Blizzard.Profile1String'])},`,
    '}',
    '',
  ];
  fs.writeFileSync(path.join(restoreDir, 'Payloads.lua'), lines.join('\n'));

  // 4. manifest
  const manifest = {};
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else manifest[path.relative(DIST, full).replace(/\\/g, '/')] = crypto.createHash('sha1').update(fs.readFileSync(full)).digest('hex');
    }
  };
  walk(DIST);
  fs.writeFileSync(path.join(ROOT, 'build-manifest.json'), JSON.stringify(manifest, null, 1));
  console.log(`built ${Object.keys(manifest).length} files into dist/ (JiberishMedia, BushidoPrivateCompat, BushidoPrivateRestore)`);
  console.log(`geometry: ${geo.units.reduce((n, u) => n + u.parts.length, 0)} unit parts, party ${geo.party.length}, raid ${geo.raid.length}, boss ${geo.boss.length}, minimap ${geo.minimap.length}, details ${geo.details.length}; skipped ${geo.skipped.length}`);
}

main();
