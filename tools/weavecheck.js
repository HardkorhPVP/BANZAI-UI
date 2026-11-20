#!/usr/bin/env node
// BANZAI Weave offline proofs (1.5.1-dev2: the approved slashed surface, filled and empty part alike). Draws, from
// the built media (dist/) and the addon's own numbers (Theme.WEAVE.empty, read from the built Theme.lua), what the
// client shows:
//
//   BANZAI Smooth   BanzaiBar stretched over the fill and tinted; the empty part the plain dark trough (today's bar)
//   BANZAI Weave    the same fill and, under it, the dark neutral empty surface - both under ONE sheet of
//                   BanzaiWeaveStrands laid over the whole bar from its top-left corner, one texel per SCREEN PIXEL
//                   (Theme:BarWeave): the slashes continue from the fill into the empty part
//
// Sheets (docs/development/banzai-weave/):
//   weave-fill-levels.png              100 / 75 / 50 / 25 / 0 % in green health, blue resource, orange, red, purple,
//                                      at health and resource bar heights, with enlargements of the fill boundary
//   weave-smooth-vs-weave-<scale>.png  Smooth | Weave side by side in five colours at 100 / 125 / 150 % UI scale
//   weave-tints.png                    Smooth | Weave in ten tints
//   weave-materials.png                the same bars on Banzai Glass, Solid and HARDKORH Parchment panels
//   weave-tile.png                     the sheet at 1 : 1, repeated (seam check) and enlarged
//
//   node tools/weavecheck.js      (after npm run build)
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const tga = require('./lib/tga');
const panel = require('./lib/panel');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');
const MEDIA = path.join(DIST, 'BushidoPrivateCompat', 'media');
const OUT = path.join(ROOT, 'docs', 'development', 'banzai-weave');

const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
const mix = (a, b, t) => a.map((x, i) => x + (b[i] - x) * t);

const TINTS = {
  lime: [0.61, 1.00, 0.12], emerald: [0.12, 0.80, 0.44], blue: [0.18, 0.48, 1.00], cyan: [0.13, 0.85, 0.91], orange: [1.00, 0.54, 0.12],
  yellow: [1.00, 0.82, 0.12], red: [0.95, 0.23, 0.23], pink: [1.00, 0.37, 0.66], purple: [0.60, 0.30, 1.00], 'neutral grey': [0.70, 0.72, 0.75],
};
const FIVE = { green: TINTS.emerald, blue: TINTS.blue, orange: TINTS.orange, red: TINTS.red, purple: TINTS.purple };
const SCALES = [1, 1.25, 1.5];
const LIVE = 1.333; // Darren's Retail client: screen pixels per UI unit
const INK = [0.84, 0.88, 0.86];
const DIM = [0.54, 0.58, 0.57];
const PAGE = [0.035, 0.045, 0.042];
const TROUGH = [[0.010, 0.026, 0.020], [0.045, 0.080, 0.064]]; // Theme:Trough, bottom -> top (alpha 0.94)
let EMPTY; // Theme.WEAVE.empty of the built addon: { bottom, top, alpha }

class Canvas {
  constructor(w, h, color = PAGE) {
    this.w = Math.round(w); this.h = Math.round(h); this.px = new Float32Array(this.w * this.h * 3); this.texts = [];
    for (let i = 0; i < this.w * this.h; i++) for (let k = 0; k < 3; k++) this.px[i * 3 + k] = color[k];
  }
  put(x, y, c, a = 1) {
    if (x < 0 || y < 0 || x >= this.w || y >= this.h || a <= 0) return;
    const o = (y * this.w + x) * 3;
    for (let k = 0; k < 3; k++) this.px[o + k] = this.px[o + k] * (1 - a) + c[k] * a;
  }
  get(x, y) { const o = (clamp(y, 0, this.h - 1) * this.w + clamp(x, 0, this.w - 1)) * 3; return [this.px[o], this.px[o + 1], this.px[o + 2]]; }
  rect(x0, y0, w, h, c, a = 1) { for (let y = y0; y < y0 + h; y++) for (let x = x0; x < x0 + w; x++) this.put(x, y, typeof c === 'function' ? c(x - x0, y - y0) : c, a); }
  frame(x0, y0, w, h, c) { this.rect(x0 - 1, y0 - 1, w + 2, 1, c); this.rect(x0 - 1, y0 + h, w + 2, 1, c); this.rect(x0 - 1, y0, 1, h, c); this.rect(x0 + w, y0, 1, h, c); }
  // an enlargement of the canvas's own pixels (nearest: every screen pixel becomes k x k)
  zoom(sx, sy, sw, sh, dx, dy, k) {
    const copy = [];
    for (let y = 0; y < sh; y++) for (let x = 0; x < sw; x++) copy.push(this.get(sx + x, sy + y));
    for (let y = 0; y < sh; y++) for (let x = 0; x < sw; x++) this.rect(dx + x * k, dy + y * k, k, k, copy[y * sw + x]);
    this.frame(dx, dy, sw * k, sh * k, DIM);
  }
  text(text, x, y, size = 13, color = INK, anchor = 'LEFT') { this.texts.push({ text, font: 'small', size, x, y, anchor, color, outline: false, shadow: false }); }
  save(name) {
    fs.mkdirSync(OUT, { recursive: true });
    const base = path.join(OUT, name + '.base.png');
    const buf = Buffer.alloc(this.w * this.h * 4);
    for (let i = 0; i < this.w * this.h; i++) { for (let k = 0; k < 3; k++) buf[i * 4 + k] = Math.round(clamp(this.px[i * 3 + k]) * 255); buf[i * 4 + 3] = 255; }
    tga.writePNG(base, this.w, this.h, buf);
    const scene = path.join(OUT, name + '.json');
    const out = path.join(OUT, name + '.png');
    fs.writeFileSync(scene, JSON.stringify({ base, out, fonts: { small: path.join(DIST, 'JiberishMedia', 'font', 'Rubik-Bold.ttf'), display: path.join(MEDIA, 'fonts', 'Shojumaru-Regular.ttf') }, ops: this.texts }));
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(__dirname, 'lib', 'textdraw.ps1'), scene], { stdio: 'inherit' });
    fs.unlinkSync(base); fs.unlinkSync(scene);
    console.log('wrote ' + path.relative(ROOT, out).replace(/\\/g, '/'));
  }
}

let smoothTex; let weaveTex; let strandsTex;
function smoothAt(u, v) { // BanzaiBar stretched (bilinear, clamped)
  const t = smoothTex;
  const x = clamp(u) * t.w - 0.5; const y = clamp(v) * t.h - 0.5;
  const x0 = clamp(Math.floor(x), 0, t.w - 1); const y0 = clamp(Math.floor(y), 0, t.h - 1); const x1 = Math.min(t.w - 1, x0 + 1); const y1 = Math.min(t.h - 1, y0 + 1);
  const fx = clamp(x - x0); const fy = clamp(y - y0); const p = (a, b) => t.px[(b * t.w + a) * 4] / 255;
  return (p(x0, y0) * (1 - fx) + p(x1, y0) * fx) * (1 - fy) + (p(x0, y1) * (1 - fx) + p(x1, y1) * fx) * fy;
}
// the strand sheet's darkness at a screen pixel of a bar (one texel per pixel from the bar's top-left corner)
const strandAt = (x, y) => strandsTex.px[(((y % strandsTex.h) * strandsTex.w) + (x % strandsTex.w)) * 4 + 3] / 255;

// A bar as the client draws it. units: [w, h] in UI units; scale: screen pixels per UI unit; value: the fill 0..1;
// mode: 'SMOOTH' | 'WEAVE'; gradient: BANZAI's own two-colour fill instead of the flat tint
function bar(cv, x0, y0, units, scale, tint, mode, value = 1, gradient = false) {
  const W = Math.round(units[0] * scale); const H = Math.round(units[1] * scale);
  const fillW = Math.round(W * value);
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const t = H > 1 ? y / (H - 1) : 0;
    const strand = mode === 'WEAVE' ? 1 - strandAt(x, y) : 1;
    if (x >= fillW) { // the empty part
      if (mode === 'WEAVE') cv.put(x0 + x, y0 + y, mix(EMPTY.top, EMPTY.bottom, t).map((c) => c * strand), EMPTY.alpha);
      else cv.put(x0 + x, y0 + y, mix(TROUGH[1], TROUGH[0], t), 0.94);
      continue;
    }
    // the fill: BanzaiBar over the whole bar (a status bar crops it, it never squeezes it)
    let color = tint;
    if (gradient) color = mix(tint.map((c) => c * 0.55), mix(tint, [1, 1, 1], 0.22), W > 1 ? x / (W - 1) : 0);
    const v = smoothAt((x + 0.5) / W, (y + 0.5) / H) * strand;
    cv.put(x0 + x, y0 + y, color.map((c) => c * v));
  }
  return { w: W, h: H, fill: fillW };
}

function load() {
  for (const n of ['BanzaiBar', 'BanzaiWeave', 'BanzaiWeaveStrands']) {
    if (!fs.existsSync(path.join(MEDIA, n + '.tga'))) throw new Error('run npm run build first (dist/ has no ' + n + '.tga)');
  }
  smoothTex = tga.read(path.join(MEDIA, 'BanzaiBar.tga'));
  weaveTex = tga.read(path.join(MEDIA, 'BanzaiWeave.tga'));
  strandsTex = tga.read(path.join(MEDIA, 'BanzaiWeaveStrands.tga'));
  const theme = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Theme.lua'), 'utf8');
  const m = theme.match(/empty = \{ bottom = \{ ([\d.]+), ([\d.]+), ([\d.]+) \}, top = \{ ([\d.]+), ([\d.]+), ([\d.]+) \}, alpha = ([\d.]+) \}/);
  if (!m) throw new Error('Theme.WEAVE.empty not found in the built Theme.lua');
  EMPTY = { bottom: [+m[1], +m[2], +m[3]], top: [+m[4], +m[5], +m[6]], alpha: +m[7] };
}

// ---- the fill levels (the final proof) --------------------------------------------------------------------------
function levelSheet() {
  const names = Object.keys(FIVE);
  const LEVELS = [1, 0.75, 0.5, 0.25, 0];
  const HEALTH = [200, 24]; const POWER = [200, 11];
  const s = LIVE; const Z = 4;
  const colW = Math.round(200 * s) + 26;
  const rowH = Math.round((24 + 11) * s) + 46;
  const left = 150; const top = 124;
  const zoomTop = top + names.length * rowH + 44;
  const cv = new Canvas(left + LEVELS.length * colW + 20, zoomTop + Math.round(24 * s) * Z + 44);
  cv.text('BANZAI WEAVE (1.5.1-dev2) - FILL LEVELS: TEXTURED FILL, TEXTURED DARK EMPTY PART', 30, 30, 20);
  cv.text('Each cell: a 200 x 24 health bar over a 200 x 11 resource bar (UI units) at this client\'s 1.33 screen pixels per unit, BANZAI\'s own two-colour fill. View at 100 %.', 30, 56, 13, DIM);
  cv.text('One sheet of slashes lies over the whole bar: the fill keeps its colour, the empty part is a dark neutral surface - the same slashes run through the boundary.', 30, 76, 13, DIM);
  LEVELS.forEach((v, i) => cv.text(Math.round(v * 100) + ' %', left + i * colW, top - 12, 15));
  const boundaries = [];
  names.forEach((name, r) => {
    const y = top + r * rowH;
    cv.text(name.toUpperCase(), 30, y + 14, 14);
    cv.text(r === 0 ? 'health / resource' : r === 1 ? 'health / resource' : '', 30, y + 32, 11, DIM);
    LEVELS.forEach((v, i) => {
      const x = left + i * colW;
      const h = bar(cv, x, y, HEALTH, s, FIVE[name], 'WEAVE', v, true);
      bar(cv, x, y + h.h + 6, POWER, s, FIVE[name], 'WEAVE', v, true);
      if (v === 0.5) boundaries.push([name, x + h.fill - 34, y, h.h]);
    });
  });
  cv.text('THE FILL BOUNDARY AT 50 %, ENLARGED 4 x (actual pixels): the slashes cross it unbroken; only colour and brightness change', 30, zoomTop - 14, 13, DIM);
  boundaries.forEach(([name, sx, sy, sh], i) => {
    const x = 30 + i * (68 * Z + 26);
    cv.zoom(sx, sy, 68, sh, x, zoomTop, Z);
    cv.text(name.toUpperCase(), x, zoomTop + sh * Z + 16, 11, DIM);
  });
  cv.save('weave-fill-levels');
}

// ---- ten tints --------------------------------------------------------------------------------------------------
function tintSheet() {
  const names = Object.keys(TINTS);
  const U = [230, 22]; const P = [230, 10];
  const rowH = 58; const colW = 260;
  const cv = new Canvas(150 + colW * 4 + 20, 96 + names.length * rowH + 20);
  cv.text('BANZAI WEAVE - TEN TINTS AT 100 %', 30, 28, 20);
  cv.text('each tint: a 230 x 22 bar (80 % full) and a 230 x 10 bar (55 % full); flat tint, then BANZAI\'s own two-colour fill', 30, 54, 13, DIM);
  ['BANZAI SMOOTH', 'BANZAI WEAVE', 'SMOOTH, BANZAI FILL', 'WEAVE, BANZAI FILL'].forEach((t, i) => cv.text(t, 150 + i * colW, 82, 12, DIM));
  names.forEach((name, r) => {
    const y = 96 + r * rowH;
    cv.text(name.toUpperCase(), 30, y + 16, 13);
    [['SMOOTH', false], ['WEAVE', false], ['SMOOTH', true], ['WEAVE', true]].forEach(([mode, grad], i) => {
      bar(cv, 150 + i * colW, y, U, 1, TINTS[name], mode, 0.8, grad);
      bar(cv, 150 + i * colW, y + 28, P, 1, TINTS[name], mode, 0.55, grad);
    });
  });
  cv.save('weave-tints');
}

// ---- Smooth | Weave at one scale --------------------------------------------------------------------------------
function compareSheet(scale) {
  const names = Object.keys(FIVE);
  const HEALTH = [230, 24]; const POWER = [230, 12]; const COOL = [163, 14];
  const s = scale; const Z = 4; const CROP = [56, Math.round(24 * s)];
  const colW = Math.round(230 * s) + 30 + CROP[0] * Z + 50;
  const rowH = Math.max(Math.round((24 + 12 + 14 + 16) * s) + 34, CROP[1] * Z + 40);
  const cv = new Canvas(130 + colW * 2, 110 + names.length * rowH + 10);
  const pct = Math.round(scale * 100);
  cv.text(`BANZAI SMOOTH  vs  BANZAI WEAVE  -  ${pct} %`, 30, 28, 20);
  cv.text(`${scale} screen pixels per UI unit. Bars in UI units: health 230 x 24 (72 % full), resource 230 x 12 (40 %), cooldown 163 x 14 (55 %). Right of each: the fill boundary's actual pixels, enlarged ${Z} x.`, 30, 54, 13, DIM);
  cv.text('BANZAI SMOOTH', 130, 90, 13, DIM);
  cv.text('BANZAI WEAVE', 130 + colW, 90, 13, DIM);
  names.forEach((name, r) => {
    const y = 110 + r * rowH;
    cv.text(name.toUpperCase(), 30, y + 14, 13);
    ['SMOOTH', 'WEAVE'].forEach((mode, i) => {
      const x = 130 + i * colW;
      const h = bar(cv, x, y, HEALTH, s, FIVE[name], mode, 0.72, true);
      const p = bar(cv, x, y + h.h + Math.round(4 * s), POWER, s, FIVE[name], mode, 0.4, true);
      bar(cv, x, y + h.h + p.h + Math.round(12 * s), COOL, s, FIVE[name], mode, 0.55, false);
      cv.zoom(x + h.fill - 34, y, CROP[0], CROP[1], x + h.w + 30, y, Z);
    });
  });
  cv.save(`weave-smooth-vs-weave-${pct}`);
}

// ---- materials --------------------------------------------------------------------------------------------------
function materialSheet() {
  const paper = panel.parchmentTile();
  const W = 330; const H = 250;
  const cv = new Canvas(40 + (W + 30) * 3 + 10, 120 + H + 30);
  cv.text('BANZAI WEAVE ON THE THREE PANEL MATERIALS', 30, 28, 20);
  cv.text('The bars are the same pixels on each: the bar texture never follows the panel material. (100 %; Smooth above, Weave below.)', 30, 54, 13, DIM);
  // a stand-in for the game world behind the panels
  const world = (x, y) => { const n = 0.5 + 0.5 * Math.sin(x * 0.045) * Math.cos(y * 0.06); return [0.16 + 0.10 * n, 0.24 + 0.12 * n, 0.20 + 0.06 * n]; };
  const mats = [
    ['BANZAI GLASS', (x, y, under) => mix(under, mix([0.016, 0.047, 0.034], [0.025, 0.074, 0.053], 1 - y / H), 0.72)],
    ['SOLID', (x, y, under) => mix(under, mix([0.016, 0.047, 0.034], [0.025, 0.074, 0.053], 1 - y / H), 0.97)],
    ['HARDKORH PARCHMENT', (x, y) => [0, 1, 2].map((k) => (paper.px[((y % paper.h) * paper.w + (x % paper.w)) * 4 + k] / 255) * 0.91)],
  ];
  mats.forEach(([name, fn], i) => {
    const x0 = 40 + i * (W + 30); const y0 = 110;
    cv.text(name, x0, 90, 13, DIM);
    for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) cv.put(x0 + x, y0 + y, fn(x, y, world(x0 + x, y0 + y)));
    let y = y0 + 22;
    for (const mode of ['SMOOTH', 'WEAVE']) {
      bar(cv, x0 + 50, y, [230, 22], 1, TINTS.emerald, mode, 0.7, true); y += 28;
      bar(cv, x0 + 50, y, [230, 10], 1, TINTS.blue, mode, 0.45, true); y += 20;
      bar(cv, x0 + 50, y, [163, 14], 1, TINTS.orange, mode, 0.6, false); y += 28;
      bar(cv, x0 + 50, y, [163, 14], 1, TINTS.purple, mode, 0.3, false); y += 34;
    }
  });
  cv.save('weave-materials');
}

// ---- the sheet itself -------------------------------------------------------------------------------------------
function tileSheet() {
  const N = weaveTex.w; const M = weaveTex.h; const Z = 4;
  const cv = new Canvas(60 + N * Z, 150 + M * Z + 60 + M * 3 + 60 + 3 * 60);
  const grey = (v) => [v, v, v];
  cv.text('BANZAI WEAVE - THE SHEET (approved Candidate D)', 30, 28, 20);
  cv.text(`${N} x ${M} texels, drawn from geometry and a fixed number sequence (tools/lib/weave.js): 120 free slashes down to the right over 26 broad faint streaks. White base, no colour of its own.`, 30, 52, 13, DIM);
  cv.text(`ONE SHEET, ENLARGED ${Z} x`, 30, 92, 12, DIM);
  for (let y = 0; y < M; y++) for (let x = 0; x < N; x++) cv.rect(30 + x * Z, 104 + y * Z, Z, Z, grey(weaveTex.px[(y * N + x) * 4] / 255));
  cv.frame(30, 104, N * Z, M * Z, DIM);
  const y1 = 104 + M * Z + 44;
  cv.text('3 x 3 SHEETS AT 1 : 1 (no line marks the joins: there is nothing to see at them)', 30, y1 - 12, 12, DIM);
  for (let y = 0; y < M * 3; y++) for (let x = 0; x < N * 3; x++) cv.put(30 + x, y1 + y, grey(weaveTex.px[((y % M) * N + (x % N)) * 4] / 255));
  cv.frame(30, y1, N * 3, M * 3, DIM);
  let y2 = y1 + M * 3 + 44;
  cv.text('THE STRAND LAYER OVER A FILL COLOUR AND OVER THE EMPTY SURFACE, 1 : 1', 30, y2 - 12, 12, DIM);
  for (const c of [TINTS.emerald, TINTS.purple, null]) {
    for (let y = 0; y < 40; y++) for (let x = 0; x < 760; x++) {
      const base = c || mix(EMPTY.top, EMPTY.bottom, y / 39);
      cv.put(30 + x, y2 + y, base.map((k) => k * (1 - strandAt(x, y))));
    }
    y2 += 52;
  }
  cv.save('weave-tile');
}

function main() {
  load();
  levelSheet();
  for (const s of SCALES) compareSheet(s);
  tintSheet();
  materialSheet();
  tileSheet();
  const stale = path.join(OUT, 'weave-scale-method.png'); // a dev1 sheet about the rejected texture
  if (fs.existsSync(stale)) fs.unlinkSync(stale);
}

main();
