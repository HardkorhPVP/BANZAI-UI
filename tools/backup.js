#!/usr/bin/env node
// BANZAI release backup (1.3.1: "Back up BANZAI 1.3.0 first"): before a milestone
// is built and deployed, the installed release is kept as it is - its addon
// folders, the WTF folder as last saved, the repository at its tag (a git
// bundle) and the third-party addon state (file sizes / times only, never their
// contents: tools/thirdparty.js) the validator compares against afterwards.
// Refuses to run while World of Warcraft is open (the saved variables must be
// the game's last save).
//   node tools/backup.js <version>
'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const thirdparty = require('./thirdparty');

const ROOT = path.join(__dirname, '..');
const RETAIL = 'D:\\Program Files (x86)\\World of Warcraft\\_retail_';
const ADDONS = path.join(RETAIL, 'Interface', 'AddOns');
const WTF = path.join(RETAIL, 'WTF');
const BACKUP_ROOT = 'C:\\Users\\DarrenSteinke\\Desktop\\Bushido-Private-Restoration-Backups';
const DEPLOYED = ['JiberishMedia', 'BushidoPrivateCompat', 'BushidoPrivateRestore'];

function copyDir(from, to) {
  fs.mkdirSync(to, { recursive: true });
  for (const entry of fs.readdirSync(from, { withFileTypes: true })) {
    const a = path.join(from, entry.name);
    const b = path.join(to, entry.name);
    if (entry.isDirectory()) copyDir(a, b); else fs.copyFileSync(a, b);
  }
}
function count(dir) {
  let n = 0;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) n += entry.isDirectory() ? count(path.join(dir, entry.name)) : 1;
  return n;
}

const version = process.argv[2];
// 1.3.8: a "-dev" build may be the installed one; 1.4.0: a release candidate too (the label follows the installed TOC exactly)
if (!/^\d+\.\d+\.\d+(-dev|-RC\d+)?$/.test(version || '')) { console.error('usage: backup.js <version>'); process.exit(2); }
if (/Wow\.exe/i.test(execSync('tasklist /FI "IMAGENAME eq Wow.exe" /NH', { encoding: 'utf8' }))) {
  console.error('World of Warcraft is running. Close it completely and run again.');
  process.exit(1);
}
const toc = fs.readFileSync(path.join(ADDONS, 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8');
if (!toc.includes(`## Version: ${version}`)) { console.error(`the installed Banzai is not ${version}`); process.exit(1); }
const stamp = new Date().toISOString().replace(/[-:]/g, '').replace('T', '-').slice(0, 15);
const dir = path.join(BACKUP_ROOT, `Banzai-${version}-${stamp}`);
for (const addon of DEPLOYED) copyDir(path.join(ADDONS, addon), path.join(dir, 'addons', addon));
copyDir(WTF, path.join(dir, 'WTF-as-last-saved'));
fs.mkdirSync(path.join(dir, 'workspace'), { recursive: true });
execSync(`git bundle create "${path.join(dir, 'workspace', `banzai-${version}.bundle`)}" banzai-${version}`, { cwd: ROOT, stdio: 'ignore' });
const state = thirdparty.state();
fs.writeFileSync(path.join(dir, 'thirdparty-baseline.json'), JSON.stringify(state));
fs.writeFileSync(path.join(dir, 'README.txt'), `BANZAI ${version} as installed, taken by tools/backup.js before the next milestone (WoW closed): the installed private addon folders, the WTF folder as last saved, the repository at tag banzai-${version} (workspace bundle) and the third-party addon state (sizes / times).\r\n`);
console.log(`backup: ${dir} (${count(path.join(dir, 'WTF-as-last-saved'))} WTF files, ${Object.keys(state).length} third-party files recorded)`);
