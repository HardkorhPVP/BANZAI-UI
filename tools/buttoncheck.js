#!/usr/bin/env node
// 1.2.0: the Banzai action buttons as the game draws them at Darren's setup
// (2560 x 1440, ElvUI UI scale 0.71: ElvUI sizes a 30-unit button in whole
// pixels = 39 px; the square's 39 px drawing one texel per pixel, its mask
// stretched over the button, the cooldown swipe stretched over the 37 px icon
// and drawn above the border, as LibActionButton anchors it). Both Banzai shapes on
// the same sample icons: BANZAI SQUARE (keybind top-right, count bottom-centre,
// cooldown numbers in the middle) and BANZAI CIRCLES (keybind centred, cooldown
// numbers at the top), with a cooldown, a proc halo and an empty slot. The
// icons are procedural stand-ins with detail up to their corners (Blizzard's
// icons are not readable offline); ElvUI's own crop (8 % each side) and its
// 1 px inset are applied first, as in the game.
//   node tools/buttoncheck.js <outDir>
// Writes buttons.png (1:1) and buttons-x4.png (each pixel 4 x 4), and prints
// the share of each button that shows the picture.
'use strict';

const fs = require('fs');
const path = require('path');
const bamboo = require('./lib/bamboo');
const tga = require('./lib/tga');
const glyphs = require('./lib/glyphs');

const out = process.argv[2] || path.join(__dirname, '..', 'build', 'buttoncheck');
fs.mkdirSync(out, { recursive: true });
const tex = bamboo.generate();
const mult = (768 / 1440) / 0.71; const BTN = Math.floor(30 / mult + 1e-9); const GAP = Math.round(6 / mult); const CANVAS = 64; const OFF = Math.floor((CANVAS - BTN) / 2);
const N = 8; const MARGIN = 28;
const W = MARGIN * 2 + N * BTN + (N - 1) * GAP; const ROW = BTN + 44;
const H = MARGIN + 2 * ROW + 10;
const px = new Float32Array(W * H * 3);
const clamp = (v) => Math.max(0, Math.min(1, v));
function blend(x, y, c, a) {
  if (x < 0 || y < 0 || x >= W || y >= H || a <= 0) return;
  const o = (y * W + x) * 3;
  for (let i = 0; i < 3; i++) px[o + i] += (c[i] - px[o + i]) * clamp(a);
}
// the scene behind the bars
for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
  const n = bamboo.noise(x / 40, y / 35) * 0.6 + bamboo.noise(x / 9, y / 8) * 0.4;
  blend(x, y, [0.22 + 0.25 * n, 0.30 + 0.22 * n, 0.24 + 0.18 * n], 1);
}

// ---- procedural sample icons (64 px source, as Blizzard's), the detail reaching their corners
const ICONS = [
  { a: [0.85, 0.35, 0.05], b: [0.25, 0.04, 0.02], shape: 'claw' },
  { a: [0.20, 0.55, 0.95], b: [0.02, 0.08, 0.30], shape: 'star' },
  { a: [0.55, 0.90, 0.25], b: [0.05, 0.25, 0.05], shape: 'leaf' },
  { a: [0.95, 0.85, 0.30], b: [0.40, 0.15, 0.02], shape: 'sun' },
  { a: [0.70, 0.30, 0.95], b: [0.15, 0.02, 0.30], shape: 'moon' },
  { a: [0.95, 0.25, 0.25], b: [0.30, 0.02, 0.05], shape: 'claw' },
  { a: [0.30, 0.85, 0.85], b: [0.02, 0.20, 0.25], shape: 'star' },
];
function icon(i, u, v) { // u, v 0..1 over the full 64 px source
  const I = ICONS[i % ICONS.length];
  const x = u * 2 - 1; const y = v * 2 - 1; const r = Math.hypot(x, y);
  let t = clamp(1 - r * 0.7);
  let c = I.b.map((b, k) => b + (I.a[k] - b) * t);
  let on = false;
  if (I.shape === 'claw') on = [-0.5, 0, 0.5].some((o) => Math.abs(x - o - 0.35 * y) < 0.09 && Math.abs(y) < 0.85);
  if (I.shape === 'star') { const ang = Math.atan2(y, x); on = r < 0.35 + 0.45 * Math.pow(Math.abs(Math.cos(ang * 2.5)), 3); }
  if (I.shape === 'leaf') on = Math.abs(x + y) < 0.95 && Math.abs(x - y) < 0.38 + 0.1 * Math.cos((x + y) * 3);
  if (I.shape === 'sun') on = r < 0.4 || (r < 0.95 && Math.abs(Math.sin(Math.atan2(y, x) * 6)) > 0.85);
  if (I.shape === 'moon') on = r < 0.7 && Math.hypot(x - 0.3, y + 0.2) > 0.55;
  if (on) c = c.map((v0, k) => 0.35 * v0 + 0.65 * Math.min(1, I.a[k] * 1.25 + 0.25));
  // detail in the corners (where the circles cut the picture)
  if (Math.abs(x) > 0.62 && Math.abs(y) > 0.62) c = c.map((v0, k) => 0.5 * v0 + 0.5 * I.a[k]);
  // Blizzard's own bevel on the outermost texels (ElvUI crops it away)
  const edge = Math.min(u, v, 1 - u, 1 - v);
  if (edge < 0.06) c = c.map((v0) => v0 * 0.35);
  return c;
}

// keybinds / counts / cooldowns: the preview font, outlined like ElvUI's text
const text = (str, cx, cy, h, color, anchor) => glyphs.draw(blend, str, cx, cy, h, color, anchor);

// ---- the game's layers for one button
const stops = [[0, [0.62, 1.0, 0.12]], [0.42, [0, 0.9, 0.42]], [0.6, [0, 0.76, 0.72]], [0.8, [0.56, 0.22, 1]], [1, [0.62, 0.1, 0.86]]];
const at = (p) => { p = clamp(p); for (let i = 1; i < stops.length; i++) if (p <= stops[i][0]) { const [p0, a] = stops[i - 1]; const [p1, b] = stops[i]; const k = (p - p0) / (p1 - p0); return a.map((v, j) => v + (b[j] - v) * k); } return stops[stops.length - 1][1]; };
const A = (img, x, y) => (x < 0 || y < 0 || x >= img.w || y >= img.h) ? [0, 0] : [img.px[(y * img.w + x) * 4] / 255, img.px[(y * img.w + x) * 4 + 3] / 255];
const stats = {};
function button(shape, col, bx, by, opts) {
  const square = shape === 'SQUARE';
  const maskT = tex[square ? 'BanzaiSquareMask' : 'BanzaiButtonMask'];
  const ring = tex[square ? 'BanzaiSquareBorder' + BTN : 'BanzaiButtonRing'];
  const coff = square ? OFF : Math.floor((CANVAS - BTN) / 2); // the circle's 40 px drawing on a 39 px button (as in the game since 0.7.0)
  const maskAt = (x, y) => (square ? A(maskT, Math.floor((x - coff + 0.5) / BTN * 64), Math.floor((y - coff + 0.5) / BTN * 64)) : A(maskT, x, y)); // canvas px
  const glowT = tex[shape === 'SQUARE' ? 'BanzaiSquareGlow' : 'BanzaiButtonGlow'];
  const swipe = tex[shape === 'SQUARE' ? 'BanzaiSquareSwipe' : 'BanzaiButtonCircle'];
  if (opts.proc) { // the halo behind the button (ADD), 1.5 / 1.6 x the button
    const scale = shape === 'SQUARE' ? 1.5 : 1.6; const size = BTN * scale; const gx0 = bx + BTN / 2 - size / 2;
    for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
      const [, a] = A(glowT, Math.floor(x / size * glowT.w), Math.floor(y / size * glowT.h));
      const X = Math.round(gx0 + x); const Y = Math.round(by + BTN / 2 - size / 2 + y);
      if (X >= 0 && Y >= 0 && X < W && Y < H) for (let i = 0; i < 3; i++) px[(Y * W + X) * 3 + i] = clamp(px[(Y * W + X) * 3 + i] + a * [0.72, 1, 0.34][i] * 0.9);
    }
  }
  let picture = 0;
  for (let y = 0; y < CANVAS; y++) for (let x = 0; x < CANVAS; x++) {
    const X = bx - OFF + x; const Y = by - OFF + y;
    const ix = x - OFF; const iy = y - OFF; // button pixels
    const [, ma] = maskAt(x, y); const [rv, ra] = A(ring, x, y);
    if (!opts.empty && ix >= 1 && iy >= 1 && ix < BTN - 1 && iy < BTN - 1) { // ElvUI: the icon 1 px inside, texcoords 0.08 .. 0.92
      const u = 0.08 + 0.84 * (ix - 1 + 0.5) / (BTN - 2); const v = 0.08 + 0.84 * (iy - 1 + 0.5) / (BTN - 2);
      let c = icon(col, u, v);
      blend(X, Y, c, ma);
    }
    if (ix >= 0 && iy >= 0 && ix < BTN && iy < BTN) picture += ma * (1 - ra);
    if (ra > 0) {
      const t = col / (N - 1) * 0.6 + (ix / BTN) * 0.4; // each ring a window of the ramp
      const c = at(t).map((k) => k * rv);
      blend(X, Y, c, ra * (opts.empty ? 0.35 : 1));
    }
    // the cooldown swipe: stretched over the icon (1 px inside the button), above the border, 0.8 black
    if (opts.cooldown && ix >= 1 && iy >= 1 && ix < BTN - 1 && iy < BTN - 1) {
      const q = BTN - 2; const [, sa] = A(swipe, Math.floor((ix - 1 + 0.5) / q * swipe.w), Math.floor((iy - 1 + 0.5) / q * swipe.h));
      const ang = Math.atan2(ix - BTN / 2 + 0.5, -(iy - BTN / 2 + 0.5));
      if (ang < 0.2 * Math.PI) blend(X, Y, [0, 0, 0], 0.8 * sa);
    }
  }
  stats[shape] = (stats[shape] || []).concat(picture / (BTN * BTN));
  if (!opts.empty) {
    if (shape === 'SQUARE') {
      text(opts.key, bx + BTN - 4, by + 4, 10, [1, 1, 1], 'topright'); // TOPRIGHT -3, -3 units (4 px), size 10: digits ~ 10 px
      if (opts.count) text(opts.count, bx + BTN / 2, by + BTN - 3 - 5, 10, [1, 1, 1], 'center'); // BOTTOM +2 units
      if (opts.cooldown) text('12', bx + BTN / 2, by + BTN / 2 + 0.7, 10, [1, 1, 0.6], 'center'); // CENTER 0, -0.5 units, size 11: digits ~ 10.5 px
    } else {
      text(opts.key, bx + BTN / 2, by + BTN / 2, 13, [1, 1, 1], 'center');
      if (opts.count) text(opts.count, bx + BTN / 2, by + BTN - 2 - 5, 9, [1, 1, 1], 'center');
      if (opts.cooldown) text('12', bx + BTN / 2, by + 7, 10, [1, 1, 0.6], 'center');
    }
  }
}
const KEYS = ['1', '2', '3', '4', 'Q', 'E', 'F', 'S-2'];
['SQUARE', 'CIRCLE'].forEach((shape, r) => {
  for (let i = 0; i < N; i++) {
    const bx = MARGIN + i * (BTN + GAP); const by = MARGIN + r * ROW;
    button(shape, i, bx, by, { key: KEYS[i], count: i === 2 ? '3' : (i === 5 ? '2' : null), cooldown: i === 1, proc: i === 3, empty: i === 7 });
  }
});
const rgba = Buffer.alloc(W * H * 4);
for (let i = 0; i < W * H; i++) { for (let k = 0; k < 3; k++) rgba[i * 4 + k] = Math.round(clamp(px[i * 3 + k]) * 255); rgba[i * 4 + 3] = 255; }
tga.writePNG(path.join(out, 'buttons.png'), W, H, rgba);
const Z = 4; const big = Buffer.alloc(W * Z * H * Z * 4);
for (let y = 0; y < H * Z; y++) for (let x = 0; x < W * Z; x++) rgba.copy(big, (y * W * Z + x) * 4, ((Math.floor(y / Z)) * W + Math.floor(x / Z)) * 4, ((Math.floor(y / Z)) * W + Math.floor(x / Z)) * 4 + 4);
tga.writePNG(path.join(out, 'buttons-x4.png'), W * Z, H * Z, big);
const mean = (a) => a.reduce((n, v) => n + v, 0) / a.length;
console.log(`top row BANZAI SQUARE, bottom row BANZAI CIRCLES (cooldown on 2, proc on 4, empty slot 8) -> ${path.join(out, 'buttons.png')}`);
console.log(`picture shown: square ${(100 * mean(stats.SQUARE.slice(0, 7))).toFixed(1)} % of the button, circles ${(100 * mean(stats.CIRCLE.slice(0, 7))).toFixed(1)} %`);
