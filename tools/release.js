#!/usr/bin/env node
// BANZAI UI release packaging (1.4.0; 1.5.0: one package for Retail and WoW Forever): a DETERMINISTIC
// installation package from the audited build plus a public-content safety scan and a release audit record.
// Nothing is uploaded or published by this tool.
//
//   node tools/release.js        -> release/BANZAI-UI-<version>.zip (+ .sha256, release-audit-<version>.json,
//                                   release.json: the clients the package is for, as WowUp reads it)
//
// Package layout (extract straight into World of Warcraft\_retail_\Interface\AddOns\ or ...\_forever_\Interface\AddOns\):
//   BushidoPrivateCompat/   Banzai Art (the frames, panels, fonts, identity art)      - from dist/
//   BushidoPrivateRestore/  Banzai (settings, Character Sync, Restore Pre-Banzai)     - from dist/
//   BushidoPrivateRestore/docs/  the user documentation and notices from docs/banzai-ui/ (1.5.0: the public
//                                documentation folder itself, so the public source reproduces the package)
// JiberishMedia is a separately distributed dependency (its own licence) and is NOT packaged; the
// installation guide names it with ElvUI as required.
//
// Deterministic: sorted entries, a fixed DOS timestamp, deflate level 9, no extra fields - the same build
// always gives the same SHA-256 (the zip writer is the one BanzaiSland's tools/release.js uses).
'use strict';

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');
const RELEASE_DIR = path.join(ROOT, 'release');
const DOCS_DIR = path.join(ROOT, 'docs', 'banzai-ui');
// the game clients a TOC interface number belongs to (release.json flavor names; WoW Forever is 16xxx)
const FLAVOR = (n) => (n >= 16000 && n < 17000 ? 'forever' : 'mainline');
const ADDONS = ['BushidoPrivateCompat', 'BushidoPrivateRestore'];
const PRODUCT = 'BANZAI-UI';

const sha256 = (buf) => crypto.createHash('sha256').update(buf).digest('hex');
const sha1 = (buf) => crypto.createHash('sha1').update(buf).digest('hex');
function walk(dir, base = dir) {
  const out = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) out.push(...walk(full, base)); else out.push(path.relative(base, full).replace(/\\/g, '/'));
  }
  return out.sort();
}

// ---------------------------------------------------------------- a small deterministic zip writer
const CRC_TABLE = (() => { const t = new Uint32Array(256); for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; } return t; })();
function crc32(buf) { let c = 0xFFFFFFFF; for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xFF] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }
const DOS_DATE = ((2026 - 1980) << 9) | (1 << 5) | 1;
const DOS_TIME = 0;
function writeZip(entries, out) {
  const locals = [], centrals = [];
  let offset = 0;
  for (const e of entries) {
    const nameBuf = Buffer.from(e.name, 'utf8');
    const deflated = zlib.deflateRawSync(e.data, { level: 9 });
    const store = deflated.length >= e.data.length;
    const body = store ? e.data : deflated;
    const method = store ? 0 : 8;
    const crc = crc32(e.data);
    const local = Buffer.alloc(30);
    local.writeUInt32LE(0x04034b50, 0); local.writeUInt16LE(20, 4); local.writeUInt16LE(0x0800, 6); local.writeUInt16LE(method, 8);
    local.writeUInt16LE(DOS_TIME, 10); local.writeUInt16LE(DOS_DATE, 12); local.writeUInt32LE(crc, 14); local.writeUInt32LE(body.length, 18);
    local.writeUInt32LE(e.data.length, 22); local.writeUInt16LE(nameBuf.length, 26); local.writeUInt16LE(0, 28);
    locals.push(local, nameBuf, body);
    const central = Buffer.alloc(46);
    central.writeUInt32LE(0x02014b50, 0); central.writeUInt16LE(20, 4); central.writeUInt16LE(20, 6); central.writeUInt16LE(0x0800, 8); central.writeUInt16LE(method, 10);
    central.writeUInt16LE(DOS_TIME, 12); central.writeUInt16LE(DOS_DATE, 14); central.writeUInt32LE(crc, 16); central.writeUInt32LE(body.length, 20);
    central.writeUInt32LE(e.data.length, 24); central.writeUInt16LE(nameBuf.length, 28); central.writeUInt16LE(0, 30); central.writeUInt16LE(0, 32);
    central.writeUInt16LE(0, 34); central.writeUInt16LE(0, 36); central.writeUInt32LE(0, 38); central.writeUInt32LE(offset, 42);
    centrals.push(central, nameBuf);
    offset += local.length + nameBuf.length + body.length;
  }
  const centralSize = centrals.reduce((n, b) => n + b.length, 0);
  const end = Buffer.alloc(22);
  end.writeUInt32LE(0x06054b50, 0); end.writeUInt16LE(0, 4); end.writeUInt16LE(0, 6); end.writeUInt16LE(entries.length, 8); end.writeUInt16LE(entries.length, 10);
  end.writeUInt32LE(centralSize, 12); end.writeUInt32LE(offset, 16); end.writeUInt16LE(0, 20);
  fs.writeFileSync(out, Buffer.concat([...locals, ...centrals, end]));
}

// ---------------------------------------------------------------- the public-content safety scan
const TEXT = /\.(lua|toc|md|txt|json|xml)$/i;
const FORBIDDEN_FILES = [
  [/\.(jpe?g|png|psd|ai|xcf|bak|tmp|log|dmp|zip|7z|rar)$/i, 'source image / scratch / archive / log / crash dump'],
  [/(^|\/)(\.git|\.vscode|tests?|tools|upstream|backups?|dist|release|WTF|SavedVariables|design-references|build)\//i, 'development or private folder'],
  [/Gemini|Thumbs\.db|\.DS_Store|\.lua\.bak$|LiveHud|class-sources|provenance\.json/i, 'Gemini source, OS cache, scratch, the abandoned Live HUD or an identity source manifest'],
  [/WantCoffee|WantBanzai|Changchangwoodcut|RootsOfChina|Odishi/i, 'a font that is not shipped'],
  [/PVPVCR|Sylvanas|\bPS[_-]/i, 'PVPVCR or PS material'],
  [/FOREVER-PROOF|FOREVER-PREP|mutation-|EVIDENCE\.md|build-manifest|\.sha256$|release\.json$/i, 'a proof document, mutation output or build record'],
];
const USERNAME = (process.env.USERPROFILE || process.env.HOME || '').split(/[\\/]/).pop() || 'no-local-user'; // the local account name must never appear in a package
const PATTERNS = [
  { re: new RegExp(USERNAME, 'i'), what: "Darren's local Windows username" },
  { re: /[A-Za-z]:\\(?!\\)/, what: 'an absolute Windows path (drive letter)', allow: (f) => /\/media\/fonts\/[^/]+\.txt$/.test(f) }, // a font author's verbatim install note (C:\WINDOWS\Fonts)
  { re: /(\/Users\/|\/home\/|C:\/Users)/, what: 'an absolute user path' },
  { re: /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/, what: 'an e-mail address', allow: (f) => /\/media\/fonts\/[^/]+\.txt$/.test(f) || /\/docs\//.test(f) }, // a font notice's own contact, or a support address in the user docs
  { re: /\bSFC\b|Dataverse/, what: 'SFC / Dataverse data' },
  // (1.5.0: the project's public community invite - the one in the public README - may stand in the user documentation; nothing else of Discord)
  { re: /discord\.gg\/|discord\.com\/(api\/webhooks|channels)|discordapp/i, what: 'private Discord data', allow: (f, line) => /\/docs\//.test(f) && /https:\/\/discord\.gg\/sv2WNwk2WZ\b/.test(line || '') && !/webhooks|channels|discordapp/i.test(line || '') },
  { re: /ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]+|-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[0-9A-Za-z_-]{30,}/, what: 'an API token, secret or access key' },
  { re: /Bushido-Private-Restoration-Backups|BANZAISLAND-Backups|predeploy-\d{8}/, what: 'a private backup path' },
  { re: /BANZAI-UI-Forever-Backups|forever-dev\d+-\d{8}/, what: 'a private backup path' },
  { re: /^## Version:.*-(dev|RC)/i, what: 'a proof / candidate version in a TOC' },
  // 1.5.0: the proof-build label. The only place it may stand is the one line in each addon that derives the channel
  // from the version (a "-dev" build names itself; a release never shows it).
  { re: /PRIVATE PROOF/, what: 'the private proof label', allow: (f, line) => /(Theme|Restore)\.lua$/.test(f) && /CHANNEL = string\.find\((Theme\.)?VERSION, '-dev', 1, true\) and 'PRIVATE PROOF' or 'release'/.test(line || '') },
  { re: /PVPVCR|Project Sylvanas|\bPS (logs?|strip|overlay)/i, what: 'PVPVCR / PS material' },
  { re: /LiveHud|LIVE HUD/, what: 'the abandoned Live HUD experiment' },
  { re: /WantCoffee\.ttf|WantBanzai\.otf|Changchangwoodcut|TheRootsOfChina|Odishi-ALV7/, what: 'a font file that is not shipped', allow: (f) => /FONT-NOTICES\.txt$|\/docs\//.test(f) }, // the notice says which faces are NOT shipped
  { re: /Darrensdrood|Darrens[a-z]+ - [A-Z][a-z]+/, what: 'a character / realm name' },
  { re: /Gemini/, what: 'a Gemini source reference', allow: (f) => /\/docs\//.test(f) }, // the credits say the identity art was generated with Gemini, nothing more
];

function scan(files, read) {
  const hits = [], allowed = [];
  for (const rel of files) {
    for (const [re, what] of FORBIDDEN_FILES) if (re.test(rel)) hits.push({ file: rel, what: `forbidden file: ${what}` });
    if (!TEXT.test(rel)) continue;
    const text = read(rel).toString('utf8');
    for (const p of PATTERNS) {
      // 1.5.0: every occurrence is judged (not only the first), and an allowance may look at the line itself
      const every = new RegExp(p.re.source, p.re.flags.replace('g', '') + 'g' + (p.re.flags.includes('m') ? '' : 'm'));
      const lines = text.split('\n');
      const seen = new Set();
      for (const m of text.matchAll(every)) {
        const line = text.slice(0, m.index).split('\n').length;
        if (seen.has(line)) continue;
        seen.add(line);
        const rec = { file: rel, line, what: p.what, sample: m[0].slice(0, 60) };
        if (p.allow && p.allow(rel, lines[line - 1])) allowed.push(rec); else hits.push(rec);
      }
    }
  }
  return { hits, allowed };
}

// ---------------------------------------------------------------- main
function main() {
  const manifestPath = path.join(ROOT, 'build-manifest.json');
  if (!fs.existsSync(manifestPath)) throw new Error('no build: run npm run build first');
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const version = (fs.readFileSync(path.join(DIST, 'BushidoPrivateRestore', 'BushidoPrivateRestore.toc'), 'utf8').match(/## Version: (\S+)/) || [])[1];
  if (!/^\d+\.\d+\.\d+(-RC\d+)?$/.test(version || '')) throw new Error(`the built version ${version} is not a release label (x.y.z or x.y.z-RCn)`);
  const compatVersion = (fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'BushidoPrivateCompat.toc'), 'utf8').match(/## Version: (\S+)/) || [])[1];
  if (compatVersion !== version) throw new Error(`the two TOCs disagree: ${compatVersion} / ${version}`);

  // the build must be exactly its manifest
  const entries = [];
  for (const addon of ADDONS) {
    const dir = path.join(DIST, addon);
    if (!fs.existsSync(dir)) throw new Error(`no dist/${addon}: run npm run build first`);
    for (const rel of walk(dir)) {
      const data = fs.readFileSync(path.join(dir, rel));
      const key = `${addon}/${rel}`;
      if (manifest[key] !== sha1(data)) throw new Error(`dist differs from build-manifest.json: ${key} - run npm run build`);
      entries.push({ name: key, data });
    }
    const expected = Object.keys(manifest).filter((k) => k.startsWith(addon + '/')).length;
    const got = entries.filter((e) => e.name.startsWith(addon + '/')).length;
    if (expected !== got) throw new Error(`${addon}: ${got} files built, the manifest lists ${expected}`);
  }
  console.log(`build ${version}: ${entries.length} addon files match the manifest`);
  // the user documentation rides inside the settings addon
  if (fs.existsSync(DOCS_DIR)) {
    for (const rel of walk(DOCS_DIR)) entries.push({ name: `BushidoPrivateRestore/docs/${rel}`, data: fs.readFileSync(path.join(DOCS_DIR, rel)) });
    console.log(`documentation: ${walk(DOCS_DIR).length} files from docs/banzai-ui`);
  } else throw new Error('docs/banzai-ui is missing: the package carries its documentation');
  entries.sort((a, b) => (a.name < b.name ? -1 : 1));

  // the scan, on exactly what the package will contain
  const byName = new Map(entries.map((e) => [e.name, e.data]));
  const { hits, allowed } = scan(entries.map((e) => e.name), (rel) => byName.get(rel));
  for (const h of hits) console.log(`SCAN FAIL ${h.file}${h.line ? ':' + h.line : ''}: ${h.what}${h.sample ? ` (${h.sample})` : ''}`);
  for (const a of allowed) console.log(`scan note ${a.file}:${a.line}: ${a.what} - allowed (notice / documentation statement)`);
  if (hits.length) { console.log(`\nrelease: public-content scan failed (${hits.length}); no package produced`); process.exit(1); }
  console.log(`public-content scan: ${entries.length} files clean (${allowed.length} documented allowance(s))`);

  // the package
  fs.mkdirSync(RELEASE_DIR, { recursive: true });
  const zip = path.join(RELEASE_DIR, `${PRODUCT}-${version}.zip`);
  writeZip(entries, zip);
  const hash = sha256(fs.readFileSync(zip));
  fs.writeFileSync(zip + '.sha256', `${hash}  ${path.basename(zip)}\n`);
  const again = zip + '.again';
  writeZip(entries, again);
  const same = sha256(fs.readFileSync(again)) === hash;
  fs.rmSync(again, { force: true });
  if (!same) throw new Error('the package is not deterministic (two writes differ)');

  // the clients: both TOCs must name the same interfaces; release.json says so to WowUp's GitHub provider
  const interfaces = ADDONS.map((a) => (fs.readFileSync(path.join(DIST, a, a + '.toc'), 'utf8').match(/^## Interface:\s*(.+)$/m) || [])[1] || '')
    .map((line) => line.split(',').map((x) => Number(x.trim())).filter(Boolean).sort((x, y) => x - y));
  if (JSON.stringify(interfaces[0]) !== JSON.stringify(interfaces[1]) || !interfaces[0].length) throw new Error('the two TOCs do not name the same interfaces: ' + JSON.stringify(interfaces));
  const metadata = interfaces[0].map((n) => ({ flavor: FLAVOR(n), interface: n })).sort((a, b) => (a.flavor < b.flavor ? 1 : -1));
  const releaseJson = { releases: [{ name: 'BANZAI UI', version, filename: path.basename(zip), nolib: false, metadata }] };
  fs.writeFileSync(path.join(RELEASE_DIR, 'release.json'), JSON.stringify(releaseJson, null, 2) + '\n');

  const record = {
    product: 'BANZAI UI', version, addons: ADDONS, dependenciesNotPackaged: ['ElvUI', 'JiberishMedia'],
    package: path.relative(ROOT, zip).replace(/\\/g, '/'), sha256: hash, bytes: fs.statSync(zip).size, files: entries.length, deterministic: true,
    clients: metadata, scan: { clean: hits.length === 0, allowed }, at: new Date().toISOString(),
  };
  fs.writeFileSync(path.join(RELEASE_DIR, `release-audit-${version}.json`), JSON.stringify(record, null, 1) + '\n');
  console.log(`package: ${path.relative(ROOT, zip)} (${record.bytes} bytes, ${entries.length} files, deterministic) SHA-256 ${hash}`);
}

if (require.main === module) {
  try { main(); } catch (e) { console.error('RELEASE STOPPED: ' + e.message); process.exit(1); }
}
module.exports = { scan, writeZip, PATTERNS, FORBIDDEN_FILES, FLAVOR };
