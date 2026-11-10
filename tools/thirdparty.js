#!/usr/bin/env node
// Records / compares the state of the third-party addon folders this private
// setup relies on (file list, sizes, modification times). Contents are never
// opened, so no third-party source is read; any write by our tooling would show
// up as a changed size or time.
//   node tools/thirdparty.js snapshot <file.json>
//   node tools/thirdparty.js compare <file.json>
'use strict';

const fs = require('fs');
const path = require('path');

const ADDONS = 'D:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns';
const FOLDERS = ['ElvUI', 'ElvUI_Libraries', 'ElvUI_Options', 'ElvUI_EltreumUI', 'ElvUI_mMediaTag', '!mMT_MediaPack', 'Details',
  'JiberishIcons', '!KalielsTracker', 'MinimapButtonButton', 'HARDKORHUI'];

function walk(dir, out) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else {
      const st = fs.statSync(full);
      out[path.relative(ADDONS, full).replace(/\\/g, '/')] = `${st.size}:${Math.round(st.mtimeMs)}`;
    }
  }
  return out;
}

function state() {
  const out = {};
  for (const folder of FOLDERS) {
    const dir = path.join(ADDONS, folder);
    if (fs.existsSync(dir)) walk(dir, out);
  }
  return out;
}

function compare(baseline) {
  const now = state();
  const changed = [];
  for (const [file, sig] of Object.entries(baseline)) if (now[file] !== sig) changed.push(file);
  for (const file of Object.keys(now)) if (!(file in baseline)) changed.push(file);
  return { files: Object.keys(now).length, changed };
}

module.exports = { state, compare, FOLDERS };

if (require.main === module) {
  const [, , cmd, file] = process.argv;
  if (cmd === 'snapshot' && file) {
    const s = state();
    fs.writeFileSync(file, JSON.stringify(s));
    console.log(`recorded ${Object.keys(s).length} third-party files -> ${file}`);
  } else if (cmd === 'compare' && file) {
    const r = compare(JSON.parse(fs.readFileSync(file, 'utf8')));
    console.log(r.changed.length ? `CHANGED: ${r.changed.slice(0, 20).join(', ')}` : `unchanged (${r.files} files)`);
    process.exit(r.changed.length ? 1 : 0);
  } else {
    console.error('usage: thirdparty.js snapshot|compare <file.json>');
    process.exit(2);
  }
}
