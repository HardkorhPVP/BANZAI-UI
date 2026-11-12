#!/usr/bin/env node
// Fetches the two pinned upstream references the build reads, into <repo>/upstream (git-ignored):
//   JiberishUI_Bushido  the historical profile exports BANZAI's generated Geometry.lua / Payloads.lua derive from
//   JiberishMedia       the media addon BANZAI requires (copied to dist/ for the tests; never packaged)
// Both are public repositories of their original author; each is checked out at exactly the commit
// tools/lib/bushido-source.js pins, so the same source always builds the same package. Nothing of them is
// committed to this repository.
//   node tools/fetch-references.js          (needs git and network access; safe to run again)
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const local = require('./lib/local');
const src = require('./lib/bushido-source');

const REFERENCES = [
  { name: 'JiberishUI_Bushido', url: 'https://github.com/Repooc/JiberishUI_Bushido.git', commit: src.BUSHIDO_COMMIT },
  { name: 'JiberishMedia', url: 'https://github.com/Repooc/JiberishMedia.git', commit: src.JIBERISHMEDIA_COMMIT },
];

function git(cwd, ...args) {
  return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
}

function main() {
  fs.mkdirSync(local.FETCHED, { recursive: true });
  for (const ref of REFERENCES) {
    const dir = path.join(local.FETCHED, ref.name);
    if (!fs.existsSync(path.join(dir, '.git'))) {
      fs.mkdirSync(dir, { recursive: true });
      git(dir, 'init', '-q');
      git(dir, 'remote', 'add', 'origin', ref.url);
    }
    let head = '';
    try { head = git(dir, 'rev-parse', 'HEAD'); } catch (e) { head = ''; }
    if (head !== ref.commit) {
      git(dir, '-c', 'core.autocrlf=false', 'fetch', '-q', '--depth', '1', 'origin', ref.commit); // exactly the pinned commit, nothing else
      git(dir, '-c', 'core.autocrlf=false', '-c', 'advice.detachedHead=false', 'checkout', '-q', '--force', 'FETCH_HEAD');
      head = git(dir, 'rev-parse', 'HEAD');
    }
    if (head !== ref.commit) throw new Error(`${ref.name} is at ${head}, expected ${ref.commit}`);
    if (git(dir, 'status', '--porcelain') !== '') throw new Error(`${ref.name} has local changes`);
    console.log(`${ref.name} @ ${head}`);
  }
  console.log('references ready in ' + path.relative(local.ROOT, local.FETCHED));
}

try { main(); } catch (e) { console.error('FETCH FAILED: ' + (e.stderr || e.message)); process.exit(1); }
