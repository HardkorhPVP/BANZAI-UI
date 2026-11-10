// BANZAI 1.3.2: local QA sheets for the class-art masters (tools/icons.js -> build/icons,
// git-ignored, never built into the addon or packaged). They exist to expose matte left in
// the art: every master over white, black, magenta, the Banzai glass, the parchment and its
// own class colour; enlarged seams; the full art at 105 / 64 / 48 / 32 / 24 px, both as a
// high-quality reduction of the master and as the game draws the 256 px runtime texture
// (its mip-maps: box-filtered halves, sampled trilinearly).
'use strict';

const resample = require('./resample');
const panel = require('./panel');
const hub = require('./hub');

const L = resample.LIN;
const SRGB = (c) => resample.toSRGB(c);

function canvas(w, h, rgb) {
  const px = Buffer.alloc(w * h * 4);
  for (let i = 0; i < w * h; i++) { px[i * 4] = rgb[0]; px[i * 4 + 1] = rgb[1]; px[i * 4 + 2] = rgb[2]; px[i * 4 + 3] = 255; }
  return { w, h, px };
}

// fills a rectangle with a background function (x, y local -> sRGB 0..255)
function fill(cv, x0, y0, w, h, fn) {
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const X = x0 + x; const Y = y0 + y;
    if (X < 0 || Y < 0 || X >= cv.w || Y >= cv.h) continue;
    const c = fn(x, y, w, h); const o = (Y * cv.w + X) * 4;
    cv.px[o] = c[0]; cv.px[o + 1] = c[1]; cv.px[o + 2] = c[2]; cv.px[o + 3] = 255;
  }
}

// alpha-composites an RGBA image (straight alpha, sRGB) onto the canvas in linear light; `zoom` = nearest upscale
function blit(cv, img, x0, y0, zoom = 1) {
  for (let y = 0; y < img.h * zoom; y++) for (let x = 0; x < img.w * zoom; x++) {
    const X = x0 + x; const Y = y0 + y;
    if (X < 0 || Y < 0 || X >= cv.w || Y >= cv.h) continue;
    const i = (Math.floor(y / zoom) * img.w + Math.floor(x / zoom)) * 4; const o = (Y * cv.w + X) * 4;
    const a = img.px[i + 3] / 255;
    if (a === 0) continue;
    for (let k = 0; k < 3; k++) cv.px[o + k] = SRGB(L[img.px[i + k]] * a + L[cv.px[o + k]] * (1 - a));
  }
}

const crop = (img, x0, y0, w, h) => {
  const px = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const sx = x0 + x; const sy = y0 + y;
    if (sx < 0 || sy < 0 || sx >= img.w || sy >= img.h) continue;
    img.px.copy(px, (y * w + x) * 4, (sy * img.w + sx) * 4, (sy * img.w + sx) * 4 + 4);
  }
  return { w, h, px };
};

// the backgrounds
const PARCH = panel.parchment();
const GLASS = [0.015, 0.075, 0.045]; // Theme.COLORS.glass, at the default glass opacity 0.72 over a dusky world
const BACKGROUNDS = {
  white: () => [255, 255, 255],
  black: () => [0, 0, 0],
  magenta: () => [255, 0, 255],
  glass: (x, y, w, h) => {
    const t = y / h; const world = [0.30 - 0.14 * t, 0.36 - 0.16 * t, 0.42 - 0.18 * t].map((v, k) => v + 0.04 * Math.sin((x + y * (k + 1)) / 23));
    const g = GLASS.map((v) => v * (1.25 - 0.45 * t)); const a = 0.72 + 0.06 * t;
    return world.map((v, k) => SRGB(L[Math.round(v * 255)] * (1 - a) + L[Math.round(g[k] * 255)] * a));
  },
  parchment: (x, y) => { const m = (v) => { const t = v % 600; return 106 + (t < 300 ? t : 599 - t); }; const o = (m(y) * PARCH.w + m(x)) * 4; return [PARCH.px[o], PARCH.px[o + 1], PARCH.px[o + 2]]; }, // the paper inside its torn edge, mirrored
};
const classColour = (cls) => hub.CLASS_COLORS[cls.toUpperCase()].map((v) => Math.round(v * 255));
// the hub's dark disc (Identity.Hub: 0.01, 0.03, 0.02 -> 0.04, 0.08, 0.06)
const DISC = (x, y, w, h) => [0.01, 0.03, 0.02].map((v, k) => Math.round((v + ([0.04, 0.08, 0.06][k] - v) * (1 - y / h)) * 255));

// the game's view of the runtime texture: box mip chain, trilinear sample at `size` px
function straightLevels(img) {
  // straight-alpha (not premultiplied) mips in sRGB bytes, the way an alpha-unaware box filter makes them
  const levels = [{ w: img.w, h: img.h, px: img.px }];
  while (levels[levels.length - 1].w > 1) {
    const p = levels[levels.length - 1]; const w = p.w >> 1; const h = p.h >> 1;
    const px = Buffer.alloc(w * h * 4);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) for (let k = 0; k < 4; k++) {
      let s = 0;
      for (const [dx, dy] of [[0, 0], [1, 0], [0, 1], [1, 1]]) s += p.px[((2 * y + dy) * p.w + 2 * x + dx) * 4 + k];
      px[(y * w + x) * 4 + k] = Math.round(s / 4);
    }
    levels.push({ w, h, px });
  }
  return levels;
}

function bilinear(level, u, v) {
  const x = u * level.w - 0.5; const y = v * level.h - 0.5;
  const x0 = Math.floor(x); const y0 = Math.floor(y); const tx = x - x0; const ty = y - y0;
  const at = (xx, yy) => { xx = Math.max(0, Math.min(level.w - 1, xx)); yy = Math.max(0, Math.min(level.h - 1, yy)); return (yy * level.w + xx) * 4; };
  const out = [0, 0, 0, 0];
  for (const [dx, dy, wt] of [[0, 0, (1 - tx) * (1 - ty)], [1, 0, tx * (1 - ty)], [0, 1, (1 - tx) * ty], [1, 1, tx * ty]]) {
    const o = at(x0 + dx, y0 + dy);
    for (let k = 0; k < 4; k++) out[k] += level.px[o + k] * wt;
  }
  return out;
}

function gameView(runtime, size) {
  const levels = straightLevels(runtime);
  const lod = Math.log2(runtime.w / size); const l0 = Math.max(0, Math.min(levels.length - 1, Math.floor(lod))); const l1 = Math.min(levels.length - 1, l0 + 1); const t = Math.max(0, Math.min(1, lod - l0));
  const px = Buffer.alloc(size * size * 4);
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const u = (x + 0.5) / size; const v = (y + 0.5) / size;
    const a = bilinear(levels[l0], u, v); const b = bilinear(levels[l1], u, v);
    for (let k = 0; k < 4; k++) px[(y * size + x) * 4 + k] = Math.round(a[k] * (1 - t) + b[k] * t);
  }
  return { w: size, h: size, px };
}

// 1. every master over every background
function backgroundSheet(masters, cell = 192) {
  const icon = cell - 16; const rows = [...Object.keys(BACKGROUNDS), 'class'];
  const cv = canvas(masters.length * cell, rows.length * cell, [40, 40, 40]);
  masters.forEach(({ cls, img }, col) => {
    const small = resample.resize(img, icon);
    rows.forEach((row, r) => {
      const bg = row === 'class' ? () => classColour(cls) : BACKGROUNDS[row];
      fill(cv, col * cell, r * cell, cell, cell, bg);
      blit(cv, small, col * cell + 8, r * cell + 8);
    });
  });
  return { img: cv, rows, columns: masters.map((m) => m.cls) };
}

// 1b. the masters large (4 x 4 grid) over one background: matte left between ring and emblem shows here
function gridSheet(masters, bg, cell = 512) {
  const cols = 4; const rows = Math.ceil(masters.length / cols);
  const cv = canvas(cols * cell, rows * cell, [40, 40, 40]);
  masters.forEach(({ img }, i) => {
    const X = (i % cols) * cell; const Y = Math.floor(i / cols) * cell;
    fill(cv, X, Y, cell, cell, BACKGROUNDS[bg]);
    blit(cv, resample.resize(img, cell - 8), X + 4, Y + 4);
  });
  return { img: cv };
}

// 2. enlarged seams: the outer edge, the inner edge of the ring and the emblem edge along one ray
function seamPoints(img, angle) {
  const c = img.w / 2; const dx = Math.cos(angle); const dy = Math.sin(angle);
  const a = (r) => { const x = Math.floor(c + dx * r); const y = Math.floor(c + dy * r); return img.px[(y * img.w + x) * 4 + 3]; };
  const pts = []; let prev = a(c - 2) >= 128;
  for (let r = c - 3; r > 0 && pts.length < 3; r -= 1) { const now = a(r) >= 128; if (now !== prev) pts.push([c + dx * r, c + dy * r]); prev = now; }
  return pts;
}

function seamSheet(masters, { zoom = 4, size = 32, angle = (200 * Math.PI) / 180 } = {}) {
  const bgs = ['white', 'black', 'magenta'];
  const tile = size * zoom; const gap = 6;
  const cols = 3 * bgs.length;
  const cv = canvas(cols * (tile + gap), masters.length * (tile + gap), [40, 40, 40]);
  masters.forEach(({ img }, r) => {
    const pts = seamPoints(img, angle);
    pts.forEach(([x, y], p) => {
      const part = crop(img, Math.round(x - size / 2), Math.round(y - size / 2), size, size);
      bgs.forEach((bg, b) => {
        const X = (p * bgs.length + b) * (tile + gap); const Y = r * (tile + gap);
        fill(cv, X, Y, tile, tile, BACKGROUNDS[bg]);
        blit(cv, part, X, Y, zoom);
      });
    });
  });
  return { img: cv, columns: ['outer edge', 'ring inner edge', 'emblem edge'].flatMap((p) => bgs.map((b) => p + ' / ' + b)) };
}

// a named enlarged seam (the difficult edges)
function detailSheet(details, { zoom = 4, size = 48 } = {}) {
  const bgs = ['white', 'black', 'magenta', 'parchment'];
  const tile = size * zoom; const gap = 6;
  const cv = canvas(bgs.length * (tile + gap), details.length * (tile + gap), [40, 40, 40]);
  details.forEach(({ img, x, y }, r) => {
    const part = crop(img, Math.round(x - size / 2), Math.round(y - size / 2), size, size);
    bgs.forEach((bg, b) => {
      const X = b * (tile + gap); const Y = r * (tile + gap);
      fill(cv, X, Y, tile, tile, BACKGROUNDS[bg]);
      blit(cv, part, X, Y, zoom);
    });
  });
  return { img: cv, columns: bgs };
}

// 3. the small sizes: per row a size, per column a class; on the hub's dark disc and on the glass;
// the left block a reduction of the master, the right block the game's view of the runtime texture
function sizeSheet(masters, runtimes, sizes = [64, 48, 32, 24]) {
  const pad = 10; const colW = sizes[0] + pad;
  const rowH = sizes.map((s) => s + pad);
  const blockW = masters.length * colW;
  const H = 2 * rowH.reduce((a, b) => a + b, 0);
  const cv = canvas(2 * blockW + 20, H, [40, 40, 40]);
  ['disc', 'glass'].forEach((bgName, g) => {
    let y = g * rowH.reduce((a, b) => a + b, 0);
    sizes.forEach((s, si) => {
      masters.forEach(({ img }, c) => {
        for (let block = 0; block < 2; block++) {
          const X = block * (blockW + 20) + c * colW; const bg = bgName === 'disc' ? DISC : BACKGROUNDS.glass;
          fill(cv, X, y, colW, rowH[si], bg);
          const small = block === 0 ? resample.resize(img, s) : gameView(runtimes[c], s);
          blit(cv, small, X + Math.floor((colW - s) / 2), y + Math.floor((rowH[si] - s) / 2));
        }
      });
      y += rowH[si];
    });
  });
  return { img: cv, sizes, blocks: ['master reduced (Mitchell, linear light)', 'game view of the 256 px runtime texture (box mips, trilinear)'], backgrounds: ['hub disc', 'glass'] };
}

function zoomed(img, k) {
  const out = { w: img.w * k, h: img.h * k, px: Buffer.alloc(img.w * k * img.h * k * 4) };
  for (let y = 0; y < out.h; y++) for (let x = 0; x < out.w; x++) img.px.copy(out.px, (y * out.w + x) * 4, (Math.floor(y / k) * img.w + Math.floor(x / k)) * 4, (Math.floor(y / k) * img.w + Math.floor(x / k)) * 4 + 4);
  return out;
}

module.exports = { BACKGROUNDS, backgroundSheet, gridSheet, seamSheet, seamPoints, detailSheet, sizeSheet, gameView, zoomed, canvas, fill, blit, crop, classColour, DISC };
