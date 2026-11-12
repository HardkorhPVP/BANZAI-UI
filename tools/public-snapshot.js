#!/usr/bin/env node
// The public source of BANZAI UI: exactly the tracked files that belong in the public repository, written to a
// folder, and scanned. The public repository is this snapshot - it must build the complete release package by
// itself (node tools/fetch-references.js, npm run build, node tools/release.js) with no private input.
//
//   node tools/public-snapshot.js <folder>     (the folder must be empty or absent; nothing is pushed anywhere)
//
// Left out: private development notes and proofs (docs/ other than docs/banzai-ui/, the legacy validation notes,
// the publication worksheets). Everything else that is tracked goes in: addon source, the shared client adapter,
// BANZAI's own assets, the tools, the tests, the user documentation, credits, release notes, the workflow.
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const PRIVATE = [
  /^docs\/(?!banzai-ui\/)/,          // proofs, crash / lines notes, validator reconciliations
  /^LEGACY-VALIDATION-NOTES\.md$/,
  /^publication\//,                  // store copy, announcements, reconciliation worksheets
];
// what must never be in public source (the package has its own, stricter scan in tools/release.js)
const USER = (process.env.USERPROFILE || process.env.HOME || '').split(/[\\/]/).pop() || 'no-local-user';
const FORBIDDEN = [
  [new RegExp(USER.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i'), 'the local account name'],
  [/[A-Za-z]:\\\\?Users\\|\/Users\/[A-Za-z]|\/home\/[a-z]/, 'a user folder path'],
  [/Account[\\/]+\d{6,}#\d/, 'a game account folder'],
  [/ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]+|-----BEGIN [A-Z ]*PRIVATE KEY-----/, 'a token or key'],
  [/predeploy-\d{8}|forever-dev\d+-\d{8}|Banzai-\d+\.\d+\.\d+(-dev)?-\d{8}/, 'a local backup snapshot name'],
  [/discord(app)?\.com\/api\/webhooks/i, 'a Discord webhook'],
];
const FORBIDDEN_FILES = [/(^|\/)WTF\//i, /SavedVariables/i, /\.(bak|log|dmp|zip|7z)$/i, /WantCoffee|WantBanzai|Changchangwoodcut|RootsOfChina|Odishi/i, /(^|\/)(dist|build|release|upstream|node_modules|design-references)\//];
const TEXT = /\.(lua|toc|md|txt|json|xml|js|yml|yaml|ps1|gitignore|gitattributes)$|^\.[a-z]+$/i;

function main() {
  const out = process.argv[2] && path.resolve(process.argv[2]);
  if (!out) throw new Error('name the folder to write the snapshot to');
  if (fs.existsSync(out) && fs.readdirSync(out).filter((f) => f !== '.git').length) throw new Error('the folder is not empty: ' + out);
  const tracked = execFileSync('git', ['ls-files', '-z'], { cwd: ROOT, encoding: 'utf8' }).split('\0').filter(Boolean);
  const files = tracked.filter((f) => !PRIVATE.some((re) => re.test(f)));
  const problems = [];
  const blobs = [];
  for (const rel of files) {
    for (const re of FORBIDDEN_FILES) if (re.test(rel)) problems.push(`${rel}: a file that does not belong in public source`);
    // the blob as committed (LF), never the working copy: the snapshot is what a clone would hold
    const data = execFileSync('git', ['show', 'HEAD:' + rel], { cwd: ROOT, maxBuffer: 1 << 28 });
    if (TEXT.test(rel)) {
      const lines = data.toString('utf8').split('\n');
      lines.forEach((line, i) => {
        for (const [re, what] of FORBIDDEN) if (re.test(line)) problems.push(`${rel}:${i + 1}: ${what}`);
      });
    }
    blobs.push([rel, data]);
  }
  if (problems.length) {
    for (const p of problems) console.log('SCAN FAIL ' + p);
    throw new Error(`${problems.length} problem(s): the snapshot is not fit to publish - nothing was written`);
  }
  // written only once the whole set is clean
  for (const [rel, data] of blobs) {
    const target = path.join(out, rel);
    fs.mkdirSync(path.dirname(target), { recursive: true });
    fs.writeFileSync(target, data);
  }
  const left = tracked.length - files.length;
  console.log(`public snapshot: ${files.length} files written to ${out} (${left} private file(s) left out); source scan clean`);
}

try { main(); } catch (e) { console.error('SNAPSHOT STOPPED: ' + e.message); process.exit(1); }
