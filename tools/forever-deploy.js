#!/usr/bin/env node
// BANZAI UI private Forever proof: backup + deploy into the WoW Forever client. NEVER run before Darren has
// written FOREVER CLOSED: the tool itself refuses while Wow.exe is running, it does not decide that he is done.
//   node tools/forever-deploy.js --check    nothing is written: is the client closed, is dist/ the built proof,
//                                           what would be deployed
//   node tools/forever-deploy.js            1. Wow.exe must be absent
//                                           2. dist/ must equal build-manifest.json (the two BANZAI addons)
//                                           3. the whole Forever Interface\AddOns and WTF are copied to
//                                              the Forever backup folder (tools/lib/local.js) \forever-<version>-<stamp>, every
//                                              copy compared with its source by size and SHA-256
//                                              (SHA256-MANIFEST.csv, README.txt)
//                                           4. only BushidoPrivateCompat and BushidoPrivateRestore are replaced
//                                           5. every deployed file is compared with build-manifest.json; every
//                                              other addon file and every WTF file with the backup manifest
// Nothing else is deployed: not JiberishMedia (the installed one stays), not BanzaiSland, no prerequisite.
// Retail is never touched. Exit 1 on any failure; a failure before step 4 leaves the client exactly as it was.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { execSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');
const local = require('./lib/local');
const FOREVER = path.join(local.WOW, '_forever_');
const ADDONS = path.join(FOREVER, 'Interface', 'AddOns');
const WTF = path.join(FOREVER, 'WTF');
const BACKUPS = local.FOREVER_BACKUPS;
const DEPLOY = ['BushidoPrivateCompat', 'BushidoPrivateRestore']; // what a Forever proof deploys - and nothing else
const CHECK = process.argv.includes('--check');

const hash = (algo, file) => crypto.createHash(algo).update(fs.readFileSync(file)).digest('hex');
function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out); else out.push(full);
  }
  return out;
}
function fail(message) { console.error('FAILED: ' + message); process.exit(1); }
function step(text) { console.log(text); }

// every World of Warcraft client process (any flavor shares the game folder's launcher data; a running Retail
// client does not lock Forever's files, but a running Forever client does - both are named Wow.exe)
function wowProcesses() {
  const out = execSync('tasklist /FO CSV /NH', { encoding: 'utf8' });
  return out.split(/\r?\n/).map((l) => (l.match(/^"([^"]+)","(\d+)"/) || []).slice(1)).filter((m) => m.length && /^Wow(Classic|T|B)?(-64)?\.exe$/i.test(m[0]));
}

function builtProof() {
  const manifestFile = path.join(ROOT, 'build-manifest.json');
  if (!fs.existsSync(manifestFile)) fail('no build-manifest.json - run node tools/build.js first');
  const manifest = JSON.parse(fs.readFileSync(manifestFile, 'utf8'));
  const expected = Object.keys(manifest).filter((f) => DEPLOY.includes(f.split('/')[0]));
  if (!expected.length) fail('the build manifest lists no BANZAI addon file');
  const built = DEPLOY.flatMap((a) => walk(path.join(DIST, a))).map((f) => path.relative(DIST, f).replace(/\\/g, '/'));
  const extra = built.filter((f) => !expected.includes(f));
  const missing = expected.filter((f) => !built.includes(f));
  const changed = expected.filter((f) => built.includes(f) && hash('sha1', path.join(DIST, f)) !== manifest[f]);
  if (extra.length || missing.length || changed.length) fail(`dist/ is not the built proof (extra ${extra.length}, missing ${missing.length}, changed ${changed.length}: ${[...extra, ...missing, ...changed].slice(0, 5).join(', ')}) - run node tools/build.js`);
  const versions = DEPLOY.map((a) => (fs.readFileSync(path.join(DIST, a, a + '.toc'), 'utf8').match(/^## Version:\s*(.+)$/m) || [])[1]);
  if (new Set(versions).size !== 1 || !/^\d+\.\d+\.\d+(-dev\d+)?$/.test(versions[0] || '')) fail('the two TOCs do not carry one version: ' + versions.join(' / '));
  return { manifest, expected, version: versions[0].trim() };
}

function copyTree(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    const a = path.join(from, entry.name);
    const b = path.join(to, entry.name);
    if (entry.isDirectory()) copyTree(a, b); else fs.copyFileSync(a, b);
  }
}

function main() {
  if (!fs.existsSync(ADDONS) || !fs.existsSync(WTF)) fail('no WoW Forever client at ' + FOREVER);
  const running = wowProcesses();
  const proof = builtProof();
  step(`BANZAI UI ${proof.version}: ${proof.expected.length} files in ${DEPLOY.join(' + ')}`);
  if (running.length) {
    if (CHECK) { step(`World of Warcraft is RUNNING (${running.map((p) => p[0] + ' ' + p[1]).join(', ')}): a deploy would be refused.`); process.exit(0); }
    fail(`World of Warcraft is running (${running.map((p) => p[0] + ' ' + p[1]).join(', ')}). Nothing was read or written. Close it first.`);
  }
  step('Wow.exe is not running.');
  if (CHECK) { step('check only: nothing was written. The client is closed and dist/ is the built proof.'); process.exit(0); }

  // 3. backup, verified
  const stamp = new Date(Date.now() - new Date().getTimezoneOffset() * 60000).toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 15);
  const backup = path.join(BACKUPS, `forever-${proof.version.includes('-') ? proof.version.replace(/^.*-/, '') : proof.version}-${stamp}`);
  if (fs.existsSync(backup)) fail('the backup folder already exists: ' + backup);
  step('backing up Interface\\AddOns and WTF to ' + backup + ' ...');
  const rows = [];
  for (const [name, source] of [['AddOns', ADDONS], ['WTF', WTF]]) {
    const target = path.join(backup, name);
    copyTree(source, target);
    for (const file of walk(source)) {
      const rel = path.relative(source, file);
      const copy = path.join(target, rel);
      if (!fs.existsSync(copy)) fail('not in the backup: ' + name + '\\' + rel);
      const size = fs.statSync(file).size;
      const sum = hash('sha256', file);
      if (fs.statSync(copy).size !== size || hash('sha256', copy) !== sum) fail('the backup copy differs from its source: ' + name + '\\' + rel);
      rows.push({ root: name, rel, size, sum });
    }
    const stray = walk(target).length - rows.filter((r) => r.root === name).length;
    if (stray !== 0) fail(`the ${name} backup has ${stray} file(s) its source does not`);
  }
  fs.writeFileSync(path.join(backup, 'SHA256-MANIFEST.csv'), ['"Root","RelativePath","Length","SHA256"', ...rows.map((r) => `"${r.root}","${r.rel}","${r.size}","${r.sum.toUpperCase()}"`)].join('\r\n') + '\r\n');
  fs.writeFileSync(path.join(backup, 'README.txt'), [`BANZAI UI Forever ${proof.version} pre-deployment backup`, 'Created: ' + new Date().toISOString(),
    'Contents: complete Forever Interface\\AddOns and WTF trees.', 'Every backed-up file was compared with its source by size and SHA-256 before deployment.', ''].join('\r\n'));
  step(`backup verified: ${rows.filter((r) => r.root === 'AddOns').length} addon files, ${rows.filter((r) => r.root === 'WTF').length} WTF files, size and SHA-256 each.`);

  // 4. deploy the two BANZAI addons only
  if (wowProcesses().length) fail('World of Warcraft was started during the backup. Nothing was deployed.');
  for (const addon of DEPLOY) {
    const installed = path.join(ADDONS, addon);
    if (!path.resolve(installed).startsWith(path.resolve(ADDONS) + path.sep)) fail('refusing to replace ' + installed);
    fs.rmSync(installed, { recursive: true, force: true });
    copyTree(path.join(DIST, addon), installed);
  }
  step('deployed: ' + DEPLOY.join(', '));

  // 5. verify
  const problems = [];
  for (const file of proof.expected) {
    const installed = path.join(ADDONS, file);
    if (!fs.existsSync(installed)) problems.push('missing ' + file);
    else if (hash('sha1', installed) !== proof.manifest[file]) problems.push('differs ' + file);
  }
  const installedFiles = DEPLOY.flatMap((a) => walk(path.join(ADDONS, a))).map((f) => path.relative(ADDONS, f).replace(/\\/g, '/'));
  for (const file of installedFiles) if (!proof.expected.includes(file)) problems.push('unexpected ' + file);
  let others = 0;
  for (const r of rows) {
    if (r.root === 'AddOns' && DEPLOY.includes(r.rel.split(/[\\/]/)[0])) continue;
    const live = path.join(r.root === 'AddOns' ? ADDONS : WTF, r.rel);
    if (!fs.existsSync(live)) problems.push('gone: ' + r.root + '\\' + r.rel);
    else if (hash('sha256', live) !== r.sum) problems.push('changed: ' + r.root + '\\' + r.rel);
    others++;
  }
  const liveOthers = walk(ADDONS).filter((f) => !DEPLOY.includes(path.relative(ADDONS, f).split(/[\\/]/)[0])).length + walk(WTF).length;
  if (liveOthers !== others) problems.push(`${liveOthers - others} file(s) appeared outside the BANZAI addons`);
  if (problems.length) fail(`verification: ${problems.length} problem(s): ${problems.slice(0, 10).join('; ')}\nThe backup is at ${backup}`);
  step(`verified: ${proof.expected.length} deployed files match build-manifest.json (SHA-1); ${others} other addon / WTF files are unchanged (SHA-256).`);
  step('backup: ' + backup);
  step(`BANZAI UI ${proof.version} is deployed to WoW Forever. BanzaiSland, JiberishMedia and every prerequisite were not touched.`);
}

main();
