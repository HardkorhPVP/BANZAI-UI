#!/usr/bin/env node
// Copies dist/ addons into the Retail AddOns folder, verifies every file, and
// sets the test character's addon list (HARDKORHUI off, the Banzai stack on).
// Refuses to run while World of Warcraft is open. Before touching anything it
// backs up the installed private addon folders and the WTF folder, and it
// checks that no third-party addon file changed during the deploy.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');
const thirdparty = require('./thirdparty');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');
const local = require('./lib/local');
const RETAIL = path.join(local.WOW, '_retail_');
const ADDONS = path.join(RETAIL, 'Interface', 'AddOns');
const WTF = path.join(RETAIL, 'WTF');
const BACKUP_ROOT = local.RETAIL_BACKUPS;
const CHARACTER_ADDONS_TXT = local.CHARACTER_ADDONS_TXT; // (BANZAI_CHARACTER_ADDONS_TXT; unset: no character's addon list is touched)
const DEPLOY = ['JiberishMedia', 'BushidoPrivateCompat', 'BushidoPrivateRestore'];
const ENABLE = ['ElvUI', 'ElvUI_Libraries', 'ElvUI_Options', 'ElvUI_EltreumUI', 'ElvUI_mMediaTag', '!mMT_MediaPack', 'Details', 'JiberishIcons', ...DEPLOY];
const DISABLE = ['HARDKORHUI'];

function wowRunning() {
  try { return /Wow\.exe/i.test(execSync('tasklist /FI "IMAGENAME eq Wow.exe" /NH', { encoding: 'utf8' })); } catch (e) { return false; }
}

function files(dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...files(full)); else out.push(full);
  }
  return out;
}

function copyDir(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    const a = path.join(from, entry.name);
    const b = path.join(to, entry.name);
    if (entry.isDirectory()) copyDir(a, b); else fs.copyFileSync(a, b);
  }
}

const sha1 = (file) => crypto.createHash('sha1').update(fs.readFileSync(file)).digest('hex');
const stamp = () => new Date().toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 15);

function backup() {
  const dir = path.join(BACKUP_ROOT, `Banzai-predeploy-${stamp()}`);
  for (const addon of DEPLOY) {
    const installed = path.join(ADDONS, addon);
    if (fs.existsSync(installed)) copyDir(installed, path.join(dir, 'addons', addon));
  }
  copyDir(WTF, path.join(dir, 'WTF'));
  const count = files(path.join(dir, 'WTF')).length;
  if (count < 1000) throw new Error(`WTF backup looks incomplete (${count} files); nothing deployed`);
  fs.writeFileSync(path.join(dir, 'thirdparty-baseline.json'), JSON.stringify(thirdparty.state())); // 1.3.1: what the next validation compares against
  fs.writeFileSync(path.join(dir, 'README.txt'), 'Taken by tools/deploy.js immediately before deploying (WoW closed): the installed private addon folders, the complete WTF folder and the third-party addon state (sizes / times).\r\n');
  console.log(`backup: ${dir} (${count} WTF files + installed private addons)`);
  return dir;
}

function main() {
  // 1.5.0-dev1: this script writes to the RETAIL client. A private proof build (x.y.z-devN) is never deployed
  // to Retail - BANZAI UI 1.4.0 stays there untouched; a WoW Forever proof is deployed by hand, with WoW closed.
  const built = (fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').match(/## Version: (\S+)/) || [])[1] || '';
  if (/-dev/.test(built)) {
    console.error(`BANZAI ${built} is a private proof build: tools/deploy.js deploys to Retail and refuses it. Nothing was written.`);
    process.exit(1);
  }
  if (wowRunning()) {
    console.error('World of Warcraft is running. Close it completely and run again.');
    process.exit(1);
  }
  const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'build-manifest.json'), 'utf8'));
  for (const addon of DEPLOY) {
    const target = path.join(ADDONS, addon);
    if (!fs.existsSync(target)) continue;
    const tocFile = fs.readdirSync(target).find((f) => f.endsWith('.toc')) || '';
    const toc = tocFile ? fs.readFileSync(path.join(target, tocFile), 'utf8') : '';
    if (!/Banzai|Bushido Private|JiberishMedia/.test(toc)) throw new Error(`${target} exists and is not one of the private restoration addons; refusing to overwrite`);
  }

  backup();
  const before = thirdparty.state();

  for (const addon of DEPLOY) {
    const target = path.join(ADDONS, addon);
    fs.rmSync(target, { recursive: true, force: true });
    copyDir(path.join(DIST, addon), target);
    const deployed = files(target);
    const bad = deployed.filter((f) => manifest[path.join(addon, path.relative(target, f)).replace(/\\/g, '/')] !== sha1(f));
    const expected = Object.keys(manifest).filter((k) => k.startsWith(addon + '/')).length;
    if (bad.length || deployed.length !== expected) throw new Error(`${addon}: verification failed (${bad.length} mismatched, ${deployed.length}/${expected} files)`);
    console.log(`deployed ${addon}: ${deployed.length} files verified (SHA-1) -> ${target}`);
  }

  // test character's addon list
  if (!CHARACTER_ADDONS_TXT || !fs.existsSync(CHARACTER_ADDONS_TXT)) { console.log('no character addon list named (BANZAI_CHARACTER_ADDONS_TXT): none changed'); return; }
  const raw = fs.readFileSync(CHARACTER_ADDONS_TXT, 'utf8');
  const eol = raw.includes('\r\n') ? '\r\n' : '\n';
  const lines = raw.split(/\r?\n/).filter((l, i, all) => !(i === all.length - 1 && l === ''));
  const index = new Map(lines.map((l, i) => [l.split(':')[0], i]));
  const set = (name, state) => {
    const line = `${name}: ${state}`;
    if (index.has(name)) lines[index.get(name)] = line; else { index.set(name, lines.length); lines.push(line); }
  };
  ENABLE.forEach((n) => set(n, 'enabled'));
  DISABLE.forEach((n) => set(n, 'disabled'));
  fs.writeFileSync(CHARACTER_ADDONS_TXT, lines.join(eol) + eol);
  console.log(`character addon list: ${ENABLE.join(', ')} enabled; ${DISABLE.join(', ')} disabled`);

  const after = thirdparty.compare(before);
  if (after.changed.length) throw new Error(`third-party addon files changed during deploy: ${after.changed.slice(0, 5).join(', ')}`);
  console.log(`third-party addons unchanged (${after.files} files checked)`);
}

main();
