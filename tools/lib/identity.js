// BANZAI 1.3.0 identity-icon contract (docs/BANZAI-IDENTITY-ICONS.md): Darren's
// own original class icons become the first choice of the BANZAI SPLIT hubs and
// party circles (1.3.2: his 13 class identities, tools/icons.js).
//
//   source   1.3.2: assets/identity/class-<class>.png - 13 fixed lowercase names,
//            square, 8-bit RGBA (sRGB), at least 1024 x 1024, transparent outside
//            the inscribed circle, the silhouette inside the circular safe area, no text
//   runtime  BushidoPrivateCompat/media/BanzaiIdentity/<class>.tga - 256 x 256,
//            32-bit, converted here deterministically (linear-light,
//            premultiplied-alpha area filter; 1.3.2: the colour of transparent
//            pixels bled from the nearest visible one, so the game's own mip-maps
//            and bilinear sampling never pull black or grey into the edge)
//   manifest IdentityManifest.lua (generated): which classes passed validation.
//            Banzai Art reads only that - a missing or rejected file can never
//            cause a Lua error or an empty circle (the next fallback is used).
//            1.3.2: a file that breaks the contract is left out for its class
//            only (the build names it); the other classes still ship
//   details  the 8 x 8 Details sheet waits for the future simplified icon family:
//            the full art is muddy at a meter row's size (CONTRACT.detailsSheet)
//
// Nothing here ships placeholder art: with no source files the manifest is empty.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const png = require('./png');
const hub = require('./hub');
const resampleLib = require('./resample');

const CLASSES = ['deathknight', 'demonhunter', 'druid', 'evoker', 'hunter', 'mage', 'monk', 'paladin', 'priest', 'rogue', 'shaman', 'warlock', 'warrior'];
const CONTRACT = { minSize: 1024, runtime: 256, edgeAlpha: 8, safe: 0.46, minArt: 0.15, sheet: 512, cell: 64, detailsSheet: false };
const sourceName = (name) => 'class-' + name + '.png'; // 1.3.2

const toLinear = (v) => { const c = v / 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); };
const toSRGB = (c) => { const v = c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; return Math.max(0, Math.min(255, Math.round(v * 255))); };

// the contract's checks on a decoded source; [] when it passes
function check(img) {
  const errors = [];
  if (img.type !== 6) errors.push('needs an alpha channel (8-bit RGBA PNG)');
  if (img.w !== img.h) errors.push(`not square (${img.w} x ${img.h})`);
  if (img.w < CONTRACT.minSize) errors.push(`smaller than ${CONTRACT.minSize} x ${CONTRACT.minSize} (${img.w} x ${img.h})`);
  if (errors.length) return errors;
  const n = img.w; const c = n / 2;
  let outside = 0; let art = 0; let safe = 0; let opaque = 0;
  for (let y = 0; y < n; y++) for (let x = 0; x < n; x++) {
    const a = img.px[(y * n + x) * 4 + 3];
    const r = Math.hypot(x + 0.5 - c, y + 0.5 - c) / n;
    if (r > 0.5 && a > CONTRACT.edgeAlpha) outside++;
    if (r <= CONTRACT.safe) { safe++; if (a >= 128) art++; }
    if (a === 255) opaque++;
  }
  if (outside > 0) errors.push(`${outside} visible pixels outside the inscribed circle (the corners must be transparent)`);
  if (art / safe < CONTRACT.minArt) errors.push(`too little artwork inside the circular safe area (${Math.round(100 * art / safe)} % opaque, ${Math.round(100 * CONTRACT.minArt)} % needed)`);
  if (opaque === n * n) errors.push('fully opaque (no transparency)');
  return errors;
}

// area filter in linear light with premultiplied alpha (no dark fringes, deterministic)
function resample(img, size) {
  const out = Buffer.alloc(size * size * 4);
  const k = img.w / size;
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    let r = 0; let g = 0; let b = 0; let a = 0; let n = 0;
    const x0 = Math.floor(x * k); const x1 = Math.floor((x + 1) * k); const y0 = Math.floor(y * k); const y1 = Math.floor((y + 1) * k);
    for (let sy = y0; sy < y1; sy++) for (let sx = x0; sx < x1; sx++) {
      const o = (sy * img.w + sx) * 4; const al = img.px[o + 3] / 255;
      r += toLinear(img.px[o]) * al; g += toLinear(img.px[o + 1]) * al; b += toLinear(img.px[o + 2]) * al; a += al; n++;
    }
    const o = (y * size + x) * 4;
    if (a > 0) { out[o] = toSRGB(r / a); out[o + 1] = toSRGB(g / a); out[o + 2] = toSRGB(b / a); }
    out[o + 3] = Math.round((a / n) * 255);
  }
  return out;
}

// Details' sheet: every class in its cell, the other cells (pet, enemy, unknown) from the class-disc sheet
function detailsSheet(images) {
  const S = CONTRACT.sheet; const cell = CONTRACT.cell;
  const discs = hub.generate().BanzaiClassDiscs;
  const px = Buffer.from(discs.px);
  for (const [token, [cx, cy]] of Object.entries(hub.DETAILS_CELLS)) {
    const file = token.toLowerCase();
    if (!images[file]) continue;
    const small = resample({ w: CONTRACT.runtime, h: CONTRACT.runtime, px: images[file] }, cell);
    for (let y = 0; y < cell; y++) for (let x = 0; x < cell; x++) {
      const s = (y * cell + x) * 4; const d = ((cy * cell + y) * S + cx * cell + x) * 4;
      small.copy(px, d, s, s + 4);
    }
  }
  return { w: S, h: S, px };
}

// 1.3.2: the runtime texture of a master - 256 x 256, area filtered, transparent pixels bled
function runtimeImage(img) {
  return resampleLib.bleed({ w: CONTRACT.runtime, h: CONTRACT.runtime, px: resample(img, CONTRACT.runtime) });
}

// reads every source present. 1.3.2: a source that breaks the contract (or cannot be read) is
// rejected for its class only - listed in result.rejected with the reason, its class falls back
// in the game; an unknown file name is listed in result.unknown. Nothing half-built ships.
function prepare(dir) {
  const result = { classes: {}, images: {}, details: null, sources: [], rejected: [], unknown: [] };
  if (!fs.existsSync(dir)) return result;
  result.unknown = fs.readdirSync(dir).filter((f) => /\.png$/i.test(f) && !CLASSES.some((c) => sourceName(c) === f));
  for (const name of CLASSES) {
    const file = path.join(dir, sourceName(name));
    if (!fs.existsSync(file)) continue;
    const bytes = fs.readFileSync(file);
    let img; let errors;
    try { img = png.decode(bytes); errors = check(img); } catch (e) { errors = [String(e.message || e)]; }
    if (errors.length) { result.rejected.push({ name, file: sourceName(name), errors }); continue; }
    result.images[name] = runtimeImage(img).px;
    result.classes[name.toUpperCase()] = { file: name, source: crypto.createHash('sha1').update(bytes).digest('hex'), size: img.w };
    result.sources.push(file);
  }
  if (CONTRACT.detailsSheet && Object.keys(result.classes).length === CLASSES.length) result.details = detailsSheet(result.images);
  return result;
}

function manifestLua(result) {
  const lines = [
    '-- GENERATED LOCALLY by tools/build.js (tools/lib/identity.js) from assets/identity/class-*.png:',
    '-- the original BANZAI class icons that passed the identity-icon contract (docs/BANZAI-IDENTITY-ICONS.md).',
    '-- A class not listed here uses the fallbacks of Banzai Art (Fabled, class-colour glyph, unknown).',
    'local _, ns = ...',
    'ns.IdentityManifest = {',
    '\tversion = 1,',
    `\tsize = ${CONTRACT.runtime},`,
    `\tdetails = ${result.details ? 'true' : 'false'},`,
    '\tclasses = {',
  ];
  for (const token of Object.keys(result.classes).sort()) {
    const c = result.classes[token];
    lines.push(`\t\t${token} = '${c.file}', -- source sha1 ${c.source}, ${c.size} x ${c.size}`);
  }
  lines.push('\t},', '}', '');
  return lines.join('\n');
}

module.exports = { CLASSES, CONTRACT, sourceName, check, resample, runtimeImage, prepare, manifestLua, detailsSheet };
