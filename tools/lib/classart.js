// BANZAI 1.3.2: Darren's 13 original class identities, from his immutable JPEG masters to
// transparent RGBA masters (tools/icons.js; docs/BANZAI-IDENTITY-ICONS.md):
//
//   sources   assets/identity/class-sources.json says which JPEG is which class (made by
//             looking at each image); every file in the source folder is mapped or excluded,
//             13 sources, 13 unique classes, each source's SHA-256 unchanged - the JPEGs are
//             only ever read
//   matte     tools/lib/matte.js at full source resolution: exterior + matte holes
//             transparent, real alpha on the seams, the matte grey solved out of them
//   ring      the outer bamboo ring found by a circle fit (horns, bamboo nodes and spikes
//             past it ignored); its centre goes to the canvas centre
//   master    1024 x 1024 RGBA PNG, every class's outer ring the same diameter (the
//             family's apparent scale), one uniform scale (no stretching), transparent
//             padding, the colour of fully transparent pixels 0 (no matte stored)
//   probes    points inside the matte holes (must be transparent) and inside the art
//             regions that come close to the matte grey (steel, silver: must stay opaque),
//             kept in the provenance and checked by the tests on the masters
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const jpeg = require('./jpeg');
const png = require('./png');
const tga = require('./tga');
const matte = require('./matte');
const resample = require('./resample');
const identity = require('./identity');

const CLASSES = identity.CLASSES;
const TOOL = { name: 'tools/icons.js', version: '1.0.0', banzai: '1.3.2' };
const MASTER = { size: 1024, clear: 6 }; // clear: px kept free inside the inscribed circle (the contract's corners)
const SOURCE_DIR = path.join('design-references', 'incoming-banzai-icons', 'classes');
const FORMAT = 'JPEG baseline (SOF0), 8-bit YCbCr';

const sha256 = (buf) => crypto.createHash('sha256').update(buf).digest('hex');

function loadMapping(root) {
  return JSON.parse(fs.readFileSync(path.join(root, 'assets', 'identity', 'class-sources.json'), 'utf8'));
}

// the frame header of a JPEG (no decoding): baseline?, size
function jpegHeader(buf) {
  if (buf[0] !== 0xff || buf[1] !== 0xd8) return null;
  let p = 2;
  while (p + 9 < buf.length) {
    if (buf[p] !== 0xff) return null;
    const m = buf[p + 1];
    const len = buf.readUInt16BE(p + 2);
    if (m >= 0xc0 && m <= 0xcf && m !== 0xc4 && m !== 0xc8 && m !== 0xcc) return { baseline: m === 0xc0, h: buf.readUInt16BE(p + 5), w: buf.readUInt16BE(p + 7), components: buf[p + 9] };
    p += 2 + len;
  }
  return null;
}

// the mapping against the files: [] when everything holds
function verifyMapping(mapping, files, read) {
  const errors = [];
  const keys = Object.keys(mapping.classes || {});
  const missing = CLASSES.filter((c) => !keys.includes(c));
  const unknown = keys.filter((c) => !CLASSES.includes(c));
  if (keys.length !== 13) errors.push(`${keys.length} classes mapped (13 required)`);
  if (missing.length) errors.push(`missing classes: ${missing.join(', ')}`);
  if (unknown.length) errors.push(`not a class: ${unknown.join(', ')}`);
  const used = {};
  for (const c of keys) {
    const s = mapping.classes[c].source;
    if (used[s]) errors.push(`${s} is mapped twice (${used[s]}, ${c})`);
    used[s] = c;
  }
  const excluded = (mapping.excluded || []).map((e) => e.source);
  for (const s of excluded) if (used[s]) errors.push(`${s} is both mapped (${used[s]}) and excluded`);
  for (const f of files) if (!used[f] && !excluded.includes(f)) errors.push(`${f} is in the source folder but neither mapped nor excluded`);
  for (const c of keys) {
    const e = mapping.classes[c];
    if (!files.includes(e.source)) { errors.push(`${c}: ${e.source} is missing`); continue; }
    const buf = read(e.source);
    const hash = sha256(buf);
    if (hash !== e.sha256) errors.push(`${c}: ${e.source} changed (SHA-256 ${hash}, recorded ${e.sha256})`);
    const head = jpegHeader(buf);
    if (!head || !head.baseline || head.components !== 3) errors.push(`${c}: ${e.source} is not a baseline colour JPEG`);
    else if (head.w !== e.w || head.h !== e.h) errors.push(`${c}: ${e.source} is ${head.w} x ${head.h} (recorded ${e.w} x ${e.h})`);
  }
  for (const e of mapping.excluded || []) {
    if (!files.includes(e.source)) continue; // an excluded file may be removed
    if (sha256(read(e.source)) !== e.sha256) errors.push(`excluded ${e.source} changed`);
  }
  return errors;
}

function verifySources(root, mapping = loadMapping(root)) {
  const dir = path.join(root, mapping.sourceDir || SOURCE_DIR);
  if (!fs.existsSync(dir)) return { errors: [`source folder ${mapping.sourceDir} not found`], dir };
  const files = fs.readdirSync(dir).filter((f) => fs.statSync(path.join(dir, f)).isFile()).sort();
  return { errors: verifyMapping(mapping, files, (f) => fs.readFileSync(path.join(dir, f))), dir, files };
}

// the deepest pixel of a component in a distance map (first in scan order among the deepest)
function deepest(pixels, distance) {
  let best = -1; let depth = -1;
  for (const i of pixels) if (distance[i] > depth) { depth = distance[i]; best = i; }
  return { index: best, depth };
}

// one class at source resolution: the segmentation, the RGBA and the ring
function extract(buf) {
  const img = jpeg.decode(buf);
  const seg = matte.segment(img);
  const rgba = matte.extract(img, seg);
  const fit = matte.ringFit(rgba);
  const w = img.w;
  const probes = { transparent: [], opaque: [] };
  for (const hole of seg.holes) {
    const d = deepest(hole.pixels, rgba.toFg);
    if (d.depth >= 6) probes.transparent.push([d.index % w, Math.floor(d.index / w)]);
  }
  // the art regions near the matte colour (steel, silver) - the ones a colour key would have removed
  for (const kept of seg.kept) {
    if (kept.area < 400 || kept.offset > 8) continue;
    const d = deepest(kept.pixels, rgba.toBg);
    if (d.depth >= 6) probes.opaque.push([d.index % w, Math.floor(d.index / w)]);
  }
  const summary = {
    matte: seg.matte, exterior: seg.exterior, holes: seg.holes.length, holePixels: seg.holes.reduce((n, h) => n + h.area, 0),
    nearMatteArt: seg.kept.filter((k) => k.offset <= 8).length, specks: seg.specks, seam: rgba.stats,
  };
  return { img: { w: img.w, h: img.h }, rgba: { w: rgba.w, h: rgba.h, px: rgba.px }, fit, probes, summary };
}

// the ring radius every master gets: as large as the most protruding class allows
function targetRadius(fits, size = MASTER.size) {
  const room = size / 2 - MASTER.clear;
  return Math.min(room, ...fits.map((f) => (room * f.R) / f.maxR));
}

// the 1024 master: ring centre to the canvas centre, ring radius to `Rt`, one uniform scale
function master(rgba, fit, Rt, size = MASTER.size) {
  const scale = Rt / fit.R;
  const out = resample.transform(rgba, size, size, scale, fit.cx, fit.cy, size / 2, size / 2);
  for (let i = 0; i < size * size; i++) if (out.px[i * 4 + 3] === 0) { out.px[i * 4] = 0; out.px[i * 4 + 1] = 0; out.px[i * 4 + 2] = 0; }
  return { img: out, scale, map: (x, y) => [Math.floor((x + 0.5 - fit.cx) * scale + size / 2), Math.floor((y + 0.5 - fit.cy) * scale + size / 2)] };
}

// what the masters are measured on (the tests and the QA report)
function measure(img) {
  const { w, h, px } = img;
  let x0 = w; let y0 = h; let x1 = -1; let y1 = -1; let opaque = 0; let visible = 0;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const a = px[(y * w + x) * 4 + 3];
    if (a > 8) { visible++; if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
    if (a === 255) opaque++;
  }
  const ring = matte.ringFit(img);
  const corners = [[0, 0], [w - 1, 0], [0, h - 1], [w - 1, h - 1]].every(([x, y]) => px[(y * w + x) * 4 + 3] === 0);
  // the outer ring's extent through its centre, both axes: equal when nothing is stretched
  const run = (dx, dy) => { let r = 0; for (let k = 0; k < w; k++) { const x = Math.round(ring.cx + dx * k); const y = Math.round(ring.cy + dy * k); if (x < 0 || y < 0 || x >= w || y >= h) break; if (px[(y * w + x) * 4 + 3] >= 128) r = k; } return r; };
  const horizontal = run(1, 0) + run(-1, 0); const vertical = run(0, 1) + run(0, -1);
  return {
    bounds: { x0, y0, x1: x1 + 1, y1: y1 + 1 }, margins: { top: y0, bottom: h - 1 - y1, left: x0, right: w - 1 - x1 },
    ring: { cx: +ring.cx.toFixed(2), cy: +ring.cy.toFixed(2), R: +ring.R.toFixed(2), maxR: +ring.maxR.toFixed(2) },
    extent: { horizontal, vertical }, coverage: +(visible / (w * h)).toFixed(4), opaque: +(opaque / (w * h)).toFixed(4), corners,
  };
}

// class colour evidence: the share of the saturated art in the class's signature hues
// (a guard against two classes swapped by mistake; the mapping itself was made by eye)
const SIGNATURE = {
  deathknight: { hues: [[340, 360], [0, 15]] }, demonhunter: { hues: [[255, 300], [75, 140]] }, druid: { hues: [[15, 45]] },
  evoker: { hues: [[165, 205], [25, 50]] }, hunter: { hues: [[85, 150], [15, 40]] }, mage: { hues: [[180, 215]] },
  monk: { hues: [[140, 180]] }, paladin: { hues: [[315, 360], [0, 5], [40, 55]] }, priest: { light: true, hues: [[35, 60], [250, 290]] },
  rogue: { hues: [[45, 70], [75, 110]] }, shaman: { hues: [[195, 235]] }, warlock: { hues: [[255, 300], [75, 140]] }, warrior: { hues: [[0, 40]] },
};

function hsv(r, g, b) {
  const mx = Math.max(r, g, b); const mn = Math.min(r, g, b); const d = mx - mn;
  let hue = 0;
  if (d > 0) {
    if (mx === r) hue = 60 * (((g - b) / d) % 6); else if (mx === g) hue = 60 * ((b - r) / d + 2); else hue = 60 * ((r - g) / d + 4);
  }
  if (hue < 0) hue += 360;
  return [hue, mx ? d / mx : 0, mx / 255];
}

function evidence(img, cls) {
  const sig = SIGNATURE[cls]; const { px } = img;
  let coloured = 0; let inSig = 0; let light = 0; let opaque = 0;
  for (let i = 0; i < px.length; i += 4) {
    if (px[i + 3] < 250) continue;
    opaque++;
    const [hue, s, v] = hsv(px[i], px[i + 1], px[i + 2]);
    if (v > 0.7 && s < 0.25) light++;
    if (s < 0.3 || v < 0.2) continue;
    coloured++;
    if (sig.hues.some(([a, b]) => hue >= a && hue <= b)) inSig++;
  }
  const share = coloured ? inSig / coloured : 0;
  return { share: +share.toFixed(3), light: +(light / opaque).toFixed(3), pass: sig.light ? light / opaque >= 0.15 && share >= 0.4 : share >= 0.5 };
}

// the PNG master's bytes and the runtime texture's bytes (exactly what the build writes)
function masterBytes(img) { return png.encode(img.w, img.h, img.px); }
function runtimeBytes(img) { const r = identity.runtimeImage(img); return tga.encode(r.w, r.h, r.px); }

module.exports = { CLASSES, TOOL, MASTER, SOURCE_DIR, FORMAT, SIGNATURE, sha256, loadMapping, jpegHeader, verifyMapping, verifySources, extract, targetRadius, master, measure, evidence, hsv, masterBytes, runtimeBytes };
