#!/usr/bin/env node
// BANZAI UI publication: uploads the package tools/release.js built to CurseForge. Run by the release
// workflow (.github/workflows/release.yml) on a release tag - never by hand without Darren's word.
//
//   node tools/publish.js --dry-run     nothing is uploaded: prints exactly what would be sent and checks what can
//                                       be checked (the game-version IDs too, when CF_API_KEY is set)
//   node tools/publish.js curseforge    needs CF_API_KEY
//
// The GitHub Release is made by the workflow itself, before this runs, and never depends on it. BANZAI UI is
// published to GitHub and CurseForge only (Wago stopped at 1.4.0; the TOCs' X-Wago-ID is historical).
//
// One package, two clients: the game versions come from the built TOCs' `## Interface:` line (120105 -> Retail
// 12.1.5, 16001 -> WoW Forever 1.60.1) and the project ID from `## X-Curse-Project-ID`. The numeric game-version
// IDs are never written here: they are looked up in CurseForge's current version list at upload time. A client
// CurseForge does not list is an error, never a silent substitution. The token is read from the environment and
// never printed.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const RELEASE_DIR = path.join(ROOT, 'release');
const DIST = path.join(ROOT, 'dist');
const MAIN_TOC = path.join(DIST, 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc');
// CurseForge's game-version types (BigWigs packager release.sh; WowUp's CurseForge provider)
const CURSE_TYPE = { mainline: 517, forever: 88568 };

const args = process.argv.slice(2);
const DRY = args.includes('--dry-run');
const targets = args.filter((a) => !a.startsWith('--'));

// 120105 -> 12.1.5, 16001 -> 1.60.1
const patchOf = (n) => `${Math.floor(n / 10000)}.${Math.floor((n % 10000) / 100)}.${n % 100}`;

function plan() {
  const audits = fs.existsSync(RELEASE_DIR) ? fs.readdirSync(RELEASE_DIR).filter((f) => /^release-audit-.*\.json$/.test(f)) : [];
  if (!fs.existsSync(MAIN_TOC)) throw new Error('no build: run npm run build and node tools/release.js first');
  const toc = fs.readFileSync(MAIN_TOC, 'utf8');
  const field = (name) => ((toc.match(new RegExp('^## ' + name + ':\\s*(.+)$', 'm')) || [])[1] || '').trim();
  const version = field('Version');
  if (!/^\d+\.\d+\.\d+$/.test(version)) throw new Error(`the built version ${version} is not a release (x.y.z)`);
  if (!audits.includes(`release-audit-${version}.json`)) throw new Error('no release audit for ' + version + ': run node tools/release.js');
  const audit = JSON.parse(fs.readFileSync(path.join(RELEASE_DIR, `release-audit-${version}.json`), 'utf8'));
  const zip = path.join(RELEASE_DIR, `BANZAI-UI-${version}.zip`);
  const data = fs.readFileSync(zip);
  const sha256 = crypto.createHash('sha256').update(data).digest('hex');
  if (sha256 !== audit.sha256) throw new Error('the package is not the audited one (SHA-256 differs from release-audit)');
  const clients = audit.clients.map((c) => ({ flavor: c.flavor, interface: c.interface, patch: patchOf(c.interface) }));
  for (const c of clients) if (!CURSE_TYPE[c.flavor]) throw new Error('no platform mapping for client ' + c.flavor);
  const notes = path.join(ROOT, 'release-notes', `BANZAI-UI-${version}.md`);
  if (!fs.existsSync(notes)) throw new Error('no release notes: ' + path.relative(ROOT, notes));
  const changelog = fs.readFileSync(notes, 'utf8').replace(/\r\n/g, '\n');
  return { version, zip, data, sha256, clients, changelog, curseProject: field('X-Curse-Project-ID'), label: `BANZAI UI ${version}` };
}

async function json(response, what) {
  const text = await response.text();
  if (!response.ok) throw new Error(`${what}: HTTP ${response.status} ${text.slice(0, 300)}`);
  try { return JSON.parse(text); } catch (e) { return text; }
}

function form(metadata, p) {
  const body = new FormData();
  body.append('metadata', JSON.stringify(metadata));
  body.append('file', new Blob([p.data], { type: 'application/zip' }), path.basename(p.zip));
  return body;
}

async function curseforge(p) {
  if (!/^\d+$/.test(p.curseProject)) throw new Error('no X-Curse-Project-ID in the built TOC');
  const token = process.env.CF_API_KEY;
  const metadata = { changelog: p.changelog, changelogType: 'markdown', displayName: p.label, gameVersions: [], releaseType: 'release' };
  console.log(`CurseForge project ${p.curseProject}: ${p.label}, release, clients ${p.clients.map((c) => `${c.flavor} ${c.patch} (type ${CURSE_TYPE[c.flavor]})`).join(', ')}`);
  if (DRY && !token) {
    console.log('  dry run: no CF_API_KEY here, so the game-version IDs are resolved in the workflow (the version list needs the token).');
    console.log('  would POST https://wow.curseforge.com/api/projects/' + p.curseProject + '/upload-file with metadata ' + JSON.stringify({ ...metadata, changelog: `<${p.changelog.length} characters of release notes>`, gameVersions: p.clients.map((c) => `<id of ${c.patch}, type ${CURSE_TYPE[c.flavor]}>`) }));
    return;
  }
  if (!token) throw new Error('CF_API_KEY is not set');
  const versions = await json(await fetch('https://wow.curseforge.com/api/game/wow/versions', { headers: { 'X-Api-Token': token } }), 'CurseForge game versions');
  for (const c of p.clients) {
    const hit = versions.find((v) => v.gameVersionTypeID === CURSE_TYPE[c.flavor] && v.name === c.patch);
    if (!hit) {
      const known = versions.filter((v) => v.gameVersionTypeID === CURSE_TYPE[c.flavor]).map((v) => v.name).slice(-8).join(', ');
      throw new Error(`CurseForge lists no game version ${c.patch} for ${c.flavor} (type ${CURSE_TYPE[c.flavor]}); it has: ${known || 'none'}. Nothing was uploaded.`);
    }
    metadata.gameVersions.push(hit.id);
    console.log(`  ${c.flavor} ${c.patch} -> game version id ${hit.id}`);
  }
  if (DRY) { console.log('  dry run: both clients resolved; nothing uploaded.'); return; }
  const result = await json(await fetch(`https://wow.curseforge.com/api/projects/${p.curseProject}/upload-file`, { method: 'POST', headers: { 'X-Api-Token': token }, body: form(metadata, p) }), 'CurseForge upload');
  console.log('  uploaded: file id ' + (result && result.id));
}

async function main() {
  const p = plan();
  console.log(`${p.label}: ${path.relative(ROOT, p.zip)} (${p.data.length} bytes, SHA-256 ${p.sha256})${DRY ? ' - DRY RUN' : ''}`);
  const run = targets.length ? targets : (DRY ? ['curseforge'] : []);
  if (!run.length) throw new Error('name a target: curseforge (or --dry-run)');
  for (const t of run) {
    if (t === 'curseforge') await curseforge(p);
    else throw new Error('unknown target ' + t);
  }
}

if (require.main === module) main().catch((e) => { console.error('PUBLISH STOPPED: ' + e.message); process.exit(1); });
module.exports = { patchOf, CURSE_TYPE };
