// HUD wordmark from Darren's own Banzai branding (assets/branding/BanzaiLogo.tga):
// the BANZAI letters (with their dark outline, the blossom dot and a little of
// their glow) cut out of the logo's background, on a transparent 512x128
// texture. No other artwork is read.
//
//   1. letter cores: bright, saturated pixels (the green / purple bamboo letters)
//   2. keep the large connected shapes away from the image border (drops the
//      corner leaves and sparkles of the background)
//   3. alpha by distance to those shapes: solid over the outline, fading over
//      the glow, transparent beyond
//   4. crop, then fit into 512x128 (area resampling, alpha weighted)
'use strict';

const tga = require('./tga');

const SOLID = 5;   // px around the letters kept fully (dark outline)
const FADE = 10;   // px where the glow fades out
const OUT_W = 512;
const OUT_H = 128;

function cores(src) {
  const { w, h, px } = src;
  const core = new Uint8Array(w * h);
  for (let i = 0; i < w * h; i++) {
    const r = px[i * 4] / 255; const g = px[i * 4 + 1] / 255; const b = px[i * 4 + 2] / 255;
    const max = Math.max(r, g, b); const min = Math.min(r, g, b);
    const s = max > 0 ? (max - min) / max : 0;
    if (max > 0.5 && s > 0.3) core[i] = 1;
  }
  return core;
}

function keepShapes(core, w, h) {
  const label = new Int32Array(w * h).fill(-1);
  const keep = new Uint8Array(w * h);
  const stack = [];
  for (let start = 0; start < w * h; start++) {
    if (!core[start] || label[start] >= 0) continue;
    const members = [];
    let border = false; let sx = 0; let sy = 0;
    label[start] = start; stack.push(start);
    while (stack.length) {
      const i = stack.pop(); members.push(i);
      const x = i % w; const y = (i - x) / w;
      sx += x; sy += y;
      if (x < 3 || y < 3 || x >= w - 3 || y >= h - 3) border = true;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const xx = x + dx; const yy = y + dy;
        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
        const j = yy * w + xx;
        if (core[j] && label[j] < 0) { label[j] = start; stack.push(j); }
      }
    }
    const cx = sx / members.length; const cy = sy / members.length;
    if (!border && members.length >= 400 && cx > w * 0.08 && cx < w * 0.93) {
      for (const i of members) keep[i] = 1;
    }
  }
  return keep;
}

// chamfer distance (3-4) to the kept shapes, in px
function distance(keep, w, h) {
  const INF = 1e9;
  const d = new Float32Array(w * h);
  for (let i = 0; i < w * h; i++) d[i] = keep[i] ? 0 : INF;
  const pass = (xs, ys, dirs) => {
    for (const y of ys) for (const x of xs) {
      const i = y * w + x;
      for (const [dx, dy, c] of dirs) {
        const xx = x + dx; const yy = y + dy;
        if (xx < 0 || yy < 0 || xx >= w || yy >= h) continue;
        const v = d[yy * w + xx] + c;
        if (v < d[i]) d[i] = v;
      }
    }
  };
  const range = (n) => [...Array(n).keys()];
  pass(range(w), range(h), [[-1, 0, 1], [0, -1, 1], [-1, -1, 1.4142], [1, -1, 1.4142]]);
  pass(range(w).reverse(), range(h).reverse(), [[1, 0, 1], [0, 1, 1], [1, 1, 1.4142], [-1, 1, 1.4142]]);
  return d;
}

function generate(file) {
  const src = tga.read(file);
  const { w, h, px } = src;
  const keep = keepShapes(cores(src), w, h);
  const dist = distance(keep, w, h);
  const alpha = new Float32Array(w * h);
  let x0 = w; let y0 = h; let x1 = -1; let y1 = -1;
  for (let i = 0; i < w * h; i++) {
    const d = dist[i];
    const a = d <= SOLID ? 1 : d >= FADE ? 0 : 1 - (d - SOLID) / (FADE - SOLID);
    alpha[i] = a * (px[i * 4 + 3] / 255);
    if (alpha[i] > 0) {
      const x = i % w; const y = (i - x) / w;
      x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y);
    }
  }
  if (x1 < 0) throw new Error('wordmark: no letters found in the branding image');
  x0 = Math.max(0, x0 - 2); y0 = Math.max(0, y0 - 2); x1 = Math.min(w - 1, x1 + 2); y1 = Math.min(h - 1, y1 + 2);
  const cw = x1 - x0 + 1; const ch = y1 - y0 + 1;
  const scale = Math.min(OUT_W / cw, OUT_H / ch);
  const ow = cw * scale; const oh = ch * scale;
  const ox = (OUT_W - ow) / 2; const oy = (OUT_H - oh) / 2;
  const out = Buffer.alloc(OUT_W * OUT_H * 4);
  for (let y = 0; y < OUT_H; y++) for (let x = 0; x < OUT_W; x++) {
    // source footprint of this output pixel (area average, alpha weighted)
    const sx0 = x0 + (x - ox) / scale; const sx1 = x0 + (x + 1 - ox) / scale;
    const sy0 = y0 + (y - oy) / scale; const sy1 = y0 + (y + 1 - oy) / scale;
    let r = 0; let g = 0; let b = 0; let a = 0; let n = 0;
    for (let yy = Math.floor(sy0); yy < Math.ceil(sy1); yy++) for (let xx = Math.floor(sx0); xx < Math.ceil(sx1); xx++) {
      n++;
      if (xx < x0 || yy < y0 || xx > x1 || yy > y1) continue;
      const i = yy * w + xx; const al = alpha[i];
      r += px[i * 4] * al; g += px[i * 4 + 1] * al; b += px[i * 4 + 2] * al; a += al;
    }
    const o = (y * OUT_W + x) * 4;
    if (a > 0) { out[o] = Math.round(r / a); out[o + 1] = Math.round(g / a); out[o + 2] = Math.round(b / a); }
    out[o + 3] = n ? Math.round((a / n) * 255) : 0;
  }
  return { w: OUT_W, h: OUT_H, px: out, aspect: cw / ch };
}

module.exports = { generate };
