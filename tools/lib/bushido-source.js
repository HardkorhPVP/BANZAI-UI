// Reads the historical Bushido payload strings from the read-only reference clone.
'use strict';

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const ASSESSMENT = require('./local').REFERENCES; // the folder with the two pinned upstream clones (tools/fetch-references.js makes it)
const BUSHIDO_REPO = path.join(ASSESSMENT, 'JiberishUI_Bushido');
const JIBERISHMEDIA_REPO = path.join(ASSESSMENT, 'JiberishMedia');
const BUSHIDO_COMMIT = '624839aa2d632d97868249d77360d603c7cac3f7';
const JIBERISHMEDIA_COMMIT = '3351a91736e18b8b3a800c37df4a556704a4cc25';

function headOf(repo) {
  return execSync('git rev-parse HEAD', { cwd: repo, encoding: 'utf8' }).trim();
}

function isClean(repo) {
  return execSync('git status --porcelain', { cwd: repo, encoding: 'utf8' }).trim() === '';
}

// { 'ElvUI.Profile1String': '...', 'WeakAuras.Profile1String': '...', ... }
function readPayloads() {
  const head = headOf(BUSHIDO_REPO);
  if (head !== BUSHIDO_COMMIT) throw new Error(`Bushido clone is at ${head}, expected ${BUSHIDO_COMMIT}`);
  const text = fs.readFileSync(path.join(BUSHIDO_REPO, 'JiberishUI_Bushido', 'Config.lua'), 'utf8');
  const payloads = {};
  let section = null;
  for (const line of text.split(/\r?\n/)) {
    const sec = line.match(/^\t(\w+) = \{/);
    if (sec) section = sec[1];
    const m = line.match(/^\t\t(\w+String)\s*=\s*(['"])(.*)\2,?\s*$/);
    if (m && section) payloads[`${section}.${m[1]}`] = m[3];
  }
  const ui = text.match(/Scale = ([0-9.]+)/);
  return { payloads, uiScale: ui ? Number(ui[1]) : null };
}

module.exports = { ASSESSMENT, BUSHIDO_REPO, JIBERISHMEDIA_REPO, BUSHIDO_COMMIT, JIBERISHMEDIA_COMMIT, headOf, isClean, readPayloads };
