// BANZAI 1.3.2: resampling for the class-art pipeline (tools/icons.js, tools/lib/identity.js).
// Linear light, premultiplied alpha (no dark or grey fringes), deterministic:
//   transform  any uniform scale + offset with the Mitchell-Netravali filter
//              (B = C = 1/3: sharp, almost no ringing), widened when shrinking
//   bleed      the colour of fully transparent pixels taken from the nearest
//              visible pixel, so a filter that ignores alpha (the game's own
//              mip-maps, bilinear sampling) never pulls in black or matte grey
'use strict';

const LIN = new Float64Array(256);
for (let i = 0; i < 256; i++) { const c = i / 255; LIN[i] = c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
const toSRGB = (c) => {
  if (c <= 0) return 0;
  if (c >= 1) return 255;
  const v = c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
  return Math.round(v * 255);
};

function mitchell(x) {
  x = Math.abs(x);
  const B = 1 / 3; const C = 1 / 3;
  if (x < 1) return ((12 - 9 * B - 6 * C) * x * x * x + (-18 + 12 * B + 6 * C) * x * x + (6 - 2 * B)) / 6;
  if (x < 2) return ((-B - 6 * C) * x * x * x + (6 * B + 30 * C) * x * x + (-12 * B - 48 * C) * x + (8 * B + 24 * C)) / 6;
  return 0;
}

// premultiplied linear RGBA (Float32Array) of an 8-bit RGBA image
function linear(img) {
  const n = img.w * img.h;
  const out = new Float32Array(n * 4);
  for (let i = 0; i < n; i++) {
    const a = img.px[i * 4 + 3] / 255;
    out[i * 4] = LIN[img.px[i * 4]] * a; out[i * 4 + 1] = LIN[img.px[i * 4 + 1]] * a; out[i * 4 + 2] = LIN[img.px[i * 4 + 2]] * a; out[i * 4 + 3] = a;
  }
  return out;
}

// the weights of one axis: output i samples the source around (i + 0.5 - centre) / scale + origin
function weights(outSize, srcSize, scale, origin, centre) {
  const support = 2 / Math.min(1, scale); const k = Math.min(1, scale);
  const taps = [];
  for (let i = 0; i < outSize; i++) {
    const u = (i + 0.5 - centre) / scale + origin; // source coordinate (pixel centres at +0.5)
    const lo = Math.floor(u - support); const hi = Math.ceil(u + support);
    const idx = []; const w = []; let sum = 0;
    for (let s = lo; s <= hi; s++) {
      const wt = mitchell((s + 0.5 - u) * k);
      if (wt === 0) continue;
      sum += wt;
      if (s < 0 || s >= srcSize) continue; // outside the source: transparent
      idx.push(s); w.push(wt);
    }
    taps.push({ idx, w: w.map((v) => v / sum) });
  }
  return taps;
}

// scales `img` by `scale` about source point (ox, oy), which lands on output point (cx, cy)
function transform(img, W, H, scale, ox, oy, cx, cy) {
  const src = img.lin || linear(img);
  const tx = weights(W, img.w, scale, ox, cx); const ty = weights(H, img.h, scale, oy, cy);
  // rows the vertical taps need
  let y0 = img.h; let y1 = -1;
  for (const t of ty) for (const s of t.idx) { if (s < y0) y0 = s; if (s > y1) y1 = s; }
  const rows = Math.max(0, y1 - y0 + 1);
  const mid = new Float32Array(W * rows * 4);
  for (let r = 0; r < rows; r++) {
    const sy = y0 + r;
    for (let x = 0; x < W; x++) {
      const t = tx[x]; let a0 = 0; let a1 = 0; let a2 = 0; let a3 = 0;
      for (let k = 0; k < t.idx.length; k++) {
        const o = (sy * img.w + t.idx[k]) * 4; const wt = t.w[k];
        a0 += src[o] * wt; a1 += src[o + 1] * wt; a2 += src[o + 2] * wt; a3 += src[o + 3] * wt;
      }
      const o = (r * W + x) * 4; mid[o] = a0; mid[o + 1] = a1; mid[o + 2] = a2; mid[o + 3] = a3;
    }
  }
  const px = Buffer.alloc(W * H * 4);
  for (let y = 0; y < H; y++) {
    const t = ty[y];
    for (let x = 0; x < W; x++) {
      let a0 = 0; let a1 = 0; let a2 = 0; let a3 = 0;
      for (let k = 0; k < t.idx.length; k++) {
        const o = ((t.idx[k] - y0) * W + x) * 4; const wt = t.w[k];
        a0 += mid[o] * wt; a1 += mid[o + 1] * wt; a2 += mid[o + 2] * wt; a3 += mid[o + 3] * wt;
      }
      const o = (y * W + x) * 4;
      const a = a3 <= 0 ? 0 : a3 >= 1 ? 1 : a3;
      const alpha = Math.round(a * 255);
      if (alpha > 0) { // unpremultiply; a ringing lobe never pushes a colour past its alpha
        px[o] = toSRGB(Math.min(a0, a) / a); px[o + 1] = toSRGB(Math.min(a1, a) / a); px[o + 2] = toSRGB(Math.min(a2, a) / a);
      }
      px[o + 3] = alpha;
    }
  }
  return { w: W, h: H, px };
}

// shrinks a square image to `size` (the whole image, centred)
function resize(img, size) {
  const scale = size / img.w;
  return transform(img, size, Math.round(img.h * scale), scale, img.w / 2, img.h / 2, size / 2, Math.round(img.h * scale) / 2);
}

// transparent pixels take the colour of the nearest visible pixel (breadth first, 4-connected)
function bleed(img) {
  const { w, h } = img; const px = Buffer.from(img.px);
  const seen = new Uint8Array(w * h);
  let queue = [];
  for (let i = 0; i < w * h; i++) if (px[i * 4 + 3] > 0) { seen[i] = 1; queue.push(i); }
  if (!queue.length) return { w, h, px };
  while (queue.length) {
    const next = [];
    for (const i of queue) {
      const x = i % w; const y = (i - x) / w;
      for (const j of [x > 0 ? i - 1 : -1, x < w - 1 ? i + 1 : -1, y > 0 ? i - w : -1, y < h - 1 ? i + w : -1]) {
        if (j < 0 || seen[j]) continue;
        seen[j] = 1; px[j * 4] = px[i * 4]; px[j * 4 + 1] = px[i * 4 + 1]; px[j * 4 + 2] = px[i * 4 + 2];
        next.push(j);
      }
    }
    queue = next;
  }
  return { w, h, px };
}

module.exports = { LIN, toSRGB, mitchell, linear, transform, resize, bleed };
