// Where things are on the machine that runs the tools. Nothing personal is written in the source: every
// location comes from an environment variable or from a place relative to this repository.
//
//   BANZAI_REFERENCE_DIR        folder holding the two pinned upstream clones (JiberishUI_Bushido, JiberishMedia).
//                               Default: <repo>/upstream when `node tools/fetch-references.js` made it (CI and any
//                               fresh clone), else a sibling folder of the repository.
//   BANZAI_WOW_DIR              the World of Warcraft folder (holds _retail_ and _forever_); local deploy tools only
//   BANZAI_RETAIL_BACKUP_DIR    where the Retail deploy / backup tools keep their backups
//   BANZAI_FOREVER_BACKUP_DIR   where the Forever deploy tool keeps its backups
//   BANZAI_CHARACTER_ADDONS_TXT a character's AddOns.txt the Retail deploy tool may update (unset: left alone)
//
// The build, the tests and the release package need only the reference folder.
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..', '..');
const env = (name, fallback) => (process.env[name] && process.env[name].trim()) || fallback;
const fetched = path.join(ROOT, 'upstream');

module.exports = {
  ROOT,
  REFERENCES: env('BANZAI_REFERENCE_DIR', fs.existsSync(path.join(fetched, 'JiberishUI_Bushido')) ? fetched : path.join(ROOT, '..', 'HARDKORHUI-Bushido-Assessment')),
  FETCHED: fetched,
  WOW: env('BANZAI_WOW_DIR', 'D:\\Program Files (x86)\\World of Warcraft'),
  RETAIL_BACKUPS: env('BANZAI_RETAIL_BACKUP_DIR', path.join(ROOT, '..', 'Bushido-Private-Restoration-Backups')),
  FOREVER_BACKUPS: env('BANZAI_FOREVER_BACKUP_DIR', path.join(ROOT, '..', 'BANZAI-UI-Forever-Backups')),
  CHARACTER_ADDONS_TXT: env('BANZAI_CHARACTER_ADDONS_TXT', null),
};
