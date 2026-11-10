#!/usr/bin/env node
// Offline preview of the 1.1.0 bamboo panels as the game draws them at
// Darren's setup (2560 x 1440, UI scale 0.71: 1 unit = 1.333 px): the chat,
// Details and minimap frames with every border style (CLASS / BANZAI /
// HARDKORH) x background (SOLID / GLASS / PARCHMENT), from the generated
// textures and the same geometry as Compat.lua (tools/lib/panel.js). Sample
// content stands in for the chat text, the meter rows and the map so that
// clearance and readability can be judged.
// 1.2.0: the chat drawn as it sits on the left screen edge (the canvas's left
// edge is the screen's), the BUFFS panel (2 and 3 rows of sample buffs with
// their durations under the icons) and the CHAT / BUFFS titles.
//   node tools/panelcheck.js <outDir> [zoom]
'use strict';

const fs = require('fs');
const path = require('path');
const panel = require('./lib/panel');
const tga = require('./lib/tga');
const { noise } = require('./lib/bamboo');
const glyphs = require('./lib/glyphs');

const PX = 0.71 * 1440 / 768; // screen pixels per UI unit
const ZOOM = Number(process.argv[3] || 1);
const out = process.argv[2] || path.join(__dirname, '..', 'build', 'panelcheck');
fs.mkdirSync(out, { recursive: true });

const tex = panel.generate();
tex.BanzaiParchment = panel.legacyParchment(); // 1.3.7: the 1.1.0 - 1.3.6 sheet, for the before / after sheet only (not built)
const sampleTex = (t, u, v) => { // bilinear, clamped
  const x = Math.max(0, Math.min(t.w - 1, u * t.w - 0.5)); const y = Math.max(0, Math.min(t.h - 1, v * t.h - 0.5));
  const x0 = Math.floor(x); const y0 = Math.floor(y); const x1 = Math.min(t.w - 1, x0 + 1); const y1 = Math.min(t.h - 1, y0 + 1);
  const fx = x - x0; const fy = y - y0;
  const o = [];
  for (let c = 0; c < 4; c++) {
    const a = t.px[(y0 * t.w + x0) * 4 + c]; const b = t.px[(y0 * t.w + x1) * 4 + c]; const cc = t.px[(y1 * t.w + x0) * 4 + c]; const d = t.px[(y1 * t.w + x1) * 4 + c];
    o[c] = (a + (b - a) * fx) + ((cc + (d - cc) * fx) - (a + (b - a) * fx)) * fy;
  }
  return o;
};

class Canvas {
  // 1.3.6: `tag` marks whose pixels are being drawn (owner: 1 DAMAGE, 2 HEALING, 4 the divider), so a sheet can measure itself
  constructor(w, h) { this.w = w; this.h = h; this.px = new Float32Array(w * h * 4); this.tag = 0; this.owner = new Uint8Array(w * h); }
  blend(x, y, r, g, b, a) {
    if (x < 0 || y < 0 || x >= this.w || y >= this.h || a <= 0) return;
    if (this.tag) this.owner[y * this.w + x] |= this.tag;
    const o = (y * this.w + x) * 4; const p = this.px;
    p[o] += (r - p[o]) * a; p[o + 1] += (g - p[o + 1]) * a; p[o + 2] += (b - p[o + 2]) * a; p[o + 3] = Math.min(1, p[o + 3] + a * (1 - p[o + 3]));
  }
  // a texture quad at (x, y, w, h) px, tex coords [ULu, ULv, LLu, LLv, URu, URv, LRu, LRv], tint from -> to along the piece's U axis (gradient on the quad: horizontal when `horiz`)
  quad(t, x, y, w, h, uv, from, to, horiz, alphaMul = 1, ss = 4) {
    const x0 = Math.floor(x); const y0 = Math.floor(y); const x1 = Math.ceil(x + w); const y1 = Math.ceil(y + h);
    for (let py = y0; py < y1; py++) for (let px = x0; px < x1; px++) {
      let r = 0; let g = 0; let b = 0; let a = 0;
      for (let j = 0; j < ss; j++) for (let i = 0; i < ss; i++) {
        const fx = (px + (i + 0.5) / ss - x) / w; const fy = (py + (j + 0.5) / ss - y) / h;
        if (fx < 0 || fx > 1 || fy < 0 || fy > 1) continue;
        // bilinear interpolation of the four corner tex coords
        const u = uv[0] + (uv[4] - uv[0]) * fx + (uv[2] - uv[0]) * fy + (uv[0] - uv[4] - uv[2] + uv[6]) * fx * fy;
        const v = uv[1] + (uv[5] - uv[1]) * fx + (uv[3] - uv[1]) * fy + (uv[1] - uv[5] - uv[3] + uv[7]) * fx * fy;
        const s = sampleTex(t, u, v);
        const k = horiz ? fx : fy;
        const tint = from && to ? [from[0] + (to[0] - from[0]) * k, from[1] + (to[1] - from[1]) * k, from[2] + (to[2] - from[2]) * k] : [1, 1, 1];
        const ta = s[3] / 255 * alphaMul;
        r += s[0] / 255 * tint[0] * ta; g += s[1] / 255 * tint[1] * ta; b += s[2] / 255 * tint[2] * ta; a += ta;
      }
      const n = ss * ss;
      if (a > 0) this.blend(px, py, r / a, g / a, b / a, a / n);
    }
  }
  rect(x, y, w, h, c, a = 1) {
    for (let py = Math.floor(y); py < Math.ceil(y + h); py++) for (let px = Math.floor(x); px < Math.ceil(x + w); px++) this.blend(px, py, c[0], c[1], c[2], a);
  }
  // text stand-in: a row of "words" with a dark outline, like SHADOWOUTLINE text
  words(x, y, width, size, color, seed) {
    let cx = x;
    let k = seed;
    while (cx < x + width - size * 2) {
      k = (k * 1103515245 + 12345) & 0x7fffffff;
      const len = size * (1.5 + (k % 5));
      if (cx + len > x + width) break;
      this.rect(cx - 1, y - 1, len + 2, size * 0.7 + 2, [0, 0, 0], 0.85);
      this.rect(cx, y, len, size * 0.7, color, 1);
      cx += len + size * 0.6;
    }
  }
  toRGBA() {
    const b = Buffer.alloc(this.w * this.h * 4);
    for (let i = 0; i < this.w * this.h * 4; i++) b[i] = Math.round(Math.max(0, Math.min(1, this.px[i])) * 255);
    return b;
  }
}

// ---- 1.3.7 the parchment as the game draws it ----------------------------------
// Each piece's corners on whole screen pixels (the client snaps textures to the pixel grid; neighbours given the same
// side land on the same pixel), every covered pixel sampled at its centre: a box-filtered mip chain, the texel rate
// choosing the level and two levels blended (TRILINEAR), bilinear inside a level, the piece's wrap mode (REPEAT /
// CLAMP) deciding what lies past the texture's edge, the vertex colour (the parchment brightness) multiplied in.
const mipCache = new Map();
function mipChain(t) {
  if (mipCache.has(t)) return mipCache.get(t);
  const levels = [{ w: t.w, h: t.h, px: Float32Array.from(t.px, (v) => v / 255) }];
  while (levels[levels.length - 1].w > 1 || levels[levels.length - 1].h > 1) {
    const a = levels[levels.length - 1]; const w = Math.max(1, a.w >> 1); const h = Math.max(1, a.h >> 1);
    const px = new Float32Array(w * h * 4);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) for (let c = 0; c < 4; c++) {
      let s = 0;
      for (let j = 0; j < 2; j++) for (let i = 0; i < 2; i++) s += a.px[(Math.min(a.h - 1, 2 * y + j) * a.w + Math.min(a.w - 1, 2 * x + i)) * 4 + c];
      px[(y * w + x) * 4 + c] = s / 4;
    }
    levels.push({ w, h, px });
  }
  mipCache.set(t, levels);
  return levels;
}
const wrapIndex = (i, n, mode) => (mode === 'REPEAT' ? ((i % n) + n) % n : Math.max(0, Math.min(n - 1, i)));
function sampleLevel(L, u, v, wu, wv, out) {
  const x = u * L.w - 0.5; const y = v * L.h - 0.5; const x0 = Math.floor(x); const y0 = Math.floor(y); const fx = x - x0; const fy = y - y0;
  const xa = wrapIndex(x0, L.w, wu); const xb = wrapIndex(x0 + 1, L.w, wu); const ya = wrapIndex(y0, L.h, wv); const yb = wrapIndex(y0 + 1, L.h, wv);
  for (let c = 0; c < 4; c++) {
    const p00 = L.px[(ya * L.w + xa) * 4 + c]; const p10 = L.px[(ya * L.w + xb) * 4 + c]; const p01 = L.px[(yb * L.w + xa) * 4 + c]; const p11 = L.px[(yb * L.w + xb) * 4 + c];
    out[c] = (p00 * (1 - fx) + p10 * fx) * (1 - fy) + (p01 * (1 - fx) + p11 * fx) * fy;
  }
}
// one piece: (x0, y0) - (x1, y1) in canvas pixels, coords UL, LL, UR, LR as the game takes them; `visit(x, y, alpha)` sees every pixel drawn
function gpuQuad(cv, t, wu, wv, x0, y0, x1, y1, uv, tint, visit) {
  const X0 = Math.round(x0); const X1 = Math.round(x1); const Y0 = Math.round(y0); const Y1 = Math.round(y1);
  if (X1 <= X0 || Y1 <= Y0) return;
  const levels = mipChain(t); const W = X1 - X0; const H = Y1 - Y0;
  const rate = Math.max(Math.hypot(((uv[4] - uv[0]) / W) * t.w, ((uv[5] - uv[1]) / W) * t.h), Math.hypot(((uv[2] - uv[0]) / H) * t.w, ((uv[3] - uv[1]) / H) * t.h));
  const lod = Math.max(0, Math.min(levels.length - 1, Math.log2(Math.max(rate, 1e-9))));
  const l0 = Math.floor(lod); const l1 = Math.min(levels.length - 1, l0 + 1); const f = lod - l0;
  const a = [0, 0, 0, 0]; const b = [0, 0, 0, 0];
  for (let py = Y0; py < Y1; py++) for (let px = X0; px < X1; px++) {
    const fx = (px + 0.5 - X0) / W; const fy = (py + 0.5 - Y0) / H;
    const u = uv[0] + (uv[4] - uv[0]) * fx + (uv[2] - uv[0]) * fy + (uv[0] - uv[4] - uv[2] + uv[6]) * fx * fy;
    const v = uv[1] + (uv[5] - uv[1]) * fx + (uv[3] - uv[1]) * fy + (uv[1] - uv[5] - uv[3] + uv[7]) * fx * fy;
    sampleLevel(levels[l0], u, v, wu, wv, a);
    if (f > 0) { sampleLevel(levels[l1], u, v, wu, wv, b); for (let c = 0; c < 4; c++) a[c] += (b[c] - a[c]) * f; }
    cv.blend(px, py, a[0] * tint, a[1] * tint, a[2] * tint, a[3]);
    if (visit) visit(px, py, a[3]);
  }
}
// the parchment of one frame (Compat.ParchmentLayout's pieces, the body first), at the brightness setting (0.7 .. 1.1)
function drawParchment(cv, ox, oy, L, d, kind, opts = {}) {
  const px = (u) => u * PX * ZOOM;
  const p = L.parchment; const lay = panel.parchmentLayout(p.w, p.h, d, kind);
  const k = 0.91 * Math.max(0.7, Math.min(1.1, opts.brightness === undefined ? 1 : opts.brightness));
  for (const piece of [...lay.pieces].sort((a, b) => (a.texture === 'tile' ? 0 : 1) - (b.texture === 'tile' ? 0 : 1)).filter((q) => !opts.bodyOnly || q.texture === 'tile')) {
    const [name, wu, wv] = panel.PARCHMENT_TEXTURES[piece.texture];
    gpuQuad(cv, tex[name], wu, wv, px(ox + p.x + piece.x0), px(oy + p.y + piece.y0), px(ox + p.x + piece.x1), px(oy + p.y + piece.y1), piece.coords, k, opts.visit && opts.visit(piece));
  }
  return lay;
}

// ---- colour, mirroring Theme.lua's panel ramps ------------------------------
const C = { lime: [0.62, 1.00, 0.12], emerald: [0.00, 0.90, 0.42], teal: [0.00, 0.76, 0.72], violet: [0.56, 0.22, 1.00], purple: [0.62, 0.10, 0.86], glass: [0.015, 0.075, 0.045] };
const DRUID = [1.00, 0.49, 0.04];
const mix = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
const at = (stops, p) => { p = Math.max(0, Math.min(1, p)); for (let i = 1; i < stops.length; i++) if (p <= stops[i][0]) { const [p0, a] = stops[i - 1]; const [p1, b] = stops[i]; return mix(a, b, p1 > p0 ? (p - p0) / (p1 - p0) : 0); } return stops[stops.length - 1][1]; };
const HARDKORH = [[0, C.lime], [0.42, C.emerald], [0.58, C.teal], [0.78, C.violet], [1, C.purple]];
const BANZAI_STALKS = { top: [0.58, 0.93, 0.22], right: [0.44, 0.86, 0.28], bottom: [0.52, 0.90, 0.20], left: [0.36, 0.84, 0.34] }; // natural: lime-leaning greens, one emerald-leaning
const ROPE = { CLASS: [[0, [0.56, 0.42, 0.24]], [1, [0.38, 0.27, 0.14]]], BANZAI: [[0, C.violet], [1, C.purple]], HARDKORH: [[0, C.violet], [1, C.purple]] };
function classStops(base) { return [[0, mix(base, [1, 1, 1], 0.38)], [0.5, base], [1, mix([0, 0, 0], base, 0.52)]]; }
function field(kind, x, y) { return (kind === 'chat' || kind === 'buffs') ? 0.5 * x + 0.5 * y : kind === 'details' ? 1 - (0.5 * x + 0.5 * y) : x; }
function stalkColor(border, kind, stalk, p, W, H, hash) {
  // the piece's point in frame space (0..1)
  const pos = { top: [p, 0], bottom: [p, 1], left: [0, p], right: [1, p] }[stalk];
  const f = field(kind, pos[0], pos[1]);
  if (border === 'CLASS') return at(classStops(DRUID), f);
  if (border === 'HARDKORH') return at(HARDKORH, f);
  const base = BANZAI_STALKS[stalk];
  const drift = 0.92 + 0.10 * p + 0.05 * (hash - 0.5); // a little lighter toward one end, a little different per segment
  return base.map((v) => Math.min(1, v * drift));
}

// 1.3.5 the DAMAGE | HEALING divider (Compat.DETAILS_DIVIDER / DIVIDER_STOPS): 2 screen pixels on the frame's centre
// (whole pixels: the game snaps it), pad x d clear of the top and bottom stalks, the BANZAI gradient top to bottom,
// both ends fading over `fade` units, the alpha for the material
const DIVIDER = { px: 2, pad: 0.8, fade: 14, alpha: 0.5, parchment: 0.72 };
const DIVIDER_STOPS = [C.lime, mix(C.lime, C.emerald, 0.5), C.emerald, C.violet, C.purple];
function drawDivider(cv, ox, oy, W, H, d, background) {
  const px = (u) => u * PX * ZOOM;
  const top = panel.PANEL.outer + d + DIVIDER.pad * d; const len = H - 2 * top;
  const fade = Math.min(DIVIDER.fade, len / 4); const a = background === 'PARCHMENT' ? DIVIDER.parchment : DIVIDER.alpha;
  const w = DIVIDER.px * ZOOM; const x0 = Math.round(px(ox + W / 2) - w / 2);
  cv.tag = 4;
  for (let y = Math.round(px(oy + top)); y < Math.round(px(oy + top + len)); y++) {
    const u = (y + 0.5) / (PX * ZOOM) - (oy + top); // units from the top end
    const alpha = a * Math.max(0, Math.min(1, u / fade, (len - u) / fade));
    const s = Math.max(0, Math.min(1, (u - fade) / (len - 2 * fade))) * (DIVIDER_STOPS.length - 1); const i = Math.min(DIVIDER_STOPS.length - 2, Math.floor(s));
    cv.rect(x0, y, w, 1, mix(DIVIDER_STOPS[i], DIVIDER_STOPS[i + 1], s - i), alpha);
  }
  cv.tag = 0;
}

// 1.3.6 the two meters around the centre gutter (Compat.DETAILS width / gap; the outer edges as before: 2 x 207.5 + 15 =
// 2 x 212 + 6 = 430): each window's rows - the dark track, the class bar, the name and the value - from its left edge to
// its right edge (Details' rows: space / row_offsets 0), edges snapped to whole pixels as the game draws them; each
// meter's pixels tagged (DAMAGE 1, HEALING 2)
const METERS = { width: 207.5, gap: 15 };
const METER_COLOURS = [[1, 0.49, 0.04], [0, 0.44, 0.87], [0.64, 0.19, 0.79], [0.67, 0.83, 0.45], [1, 0.96, 0.41], [0.96, 0.55, 0.73]];
function drawMeters(cv, ox, oy, W) {
  const px = (u) => u * PX * ZOOM;
  const snap = (x0u, x1u, yu, hu, c, a) => { const a0 = Math.round(px(x0u)); const a1 = Math.round(px(x1u)); const b0 = Math.round(px(yu)); cv.rect(a0, b0, a1 - a0, Math.round(px(yu + hu)) - b0, c, a); };
  const M = METERS; const content = 2 * M.width + M.gap;
  for (const w of [0, 1]) {
    const wx = ox + (W - content) / 2 + w * (M.width + M.gap); const wy = oy + 10.5 + 8;
    cv.tag = w + 1;
    for (let i = 0; i < 6; i++) {
      const y = wy + i * 17 + 10;
      snap(wx, wx + M.width, y + 4, 5, [0.02, 0.04, 0.03], 0.55);
      snap(wx, wx + M.width * (1 - i * 0.13), y + 4, 5, METER_COLOURS[i], 1);
      cv.words(Math.round(px(wx + 2)), px(y), px(90), px(8), [1, 1, 1], 31 + i + w * 7);
      cv.words(Math.round(px(wx + M.width - 62)), px(y), px(60), px(8), [1, 1, 1], 51 + i + w * 3);
    }
    cv.tag = 0;
  }
}

// DAMAGE / HEALING on the top stalk as Compat:LayoutDetailsTitle places them: DAMAGE from window 1's left edge, HEALING
// to window 2's right edge (clear of the top-right rope tie); the dark backing, the letters, the accent under them
const SIDE_TITLES = [
  { side: 'LEFT', text: 'DAMAGE', bright: [1.00, 0.40, 0.32], deep: [0.80, 0.03, 0.10], accent: [[1.00, 0.30, 0.26], [0.55, 0.03, 0.08]] },
  { side: 'RIGHT', text: 'HEALING', bright: [0.55, 1.00, 0.45], deep: [0.00, 0.66, 0.30], accent: [[0.32, 0.96, 0.40], [0.02, 0.45, 0.22]] },
];
function drawSideTitles(cv, ox, oy, W, d) {
  const px = (u) => u * PX * ZOOM;
  const T = { inset: 4, pad: 7, bamboo: 6, fade: 9 }; const line = panel.PANEL.outer + d / 2;
  for (const t of SIDE_TITLES) {
    const textW = t.text.length * (16 * 6 / 7) - 16 / 7; const width = textW + 2 * T.pad; const bh = 22 * 0.78;
    const left = t.side === 'LEFT' ? W / 2 - 215 + T.inset - T.pad
      : Math.min(W / 2 + 215 - T.inset + T.pad, W - panel.PANEL.outer - d / 2 - panel.PANEL.tie * d / 2 - T.bamboo + T.pad) - width;
    for (let xx = 0; xx < Math.round(px(width)); xx++) {
      const u = xx / px(width) * width; const a = 0.97 * Math.min(1, u / T.fade, (width - u) / T.fade);
      cv.rect(px(ox + left) + xx, px(oy + line - bh / 2), 1, px(bh), [0.01, 0.025, 0.018], a);
    }
    glyphs.draw((X, Y, col0, a) => cv.blend(X, Y, col0[0], col0[1], col0[2], a), t.text, px(ox + left + width / 2), px(oy + line), px(16), (i, n) => mix(t.bright, t.deep, n > 1 ? i / (n - 1) : 0));
    const aw = textW + 18; const ax = t.side === 'LEFT' ? left + T.pad : left + width - T.pad - aw;
    for (let xx = 0; xx < Math.round(px(aw)); xx++) {
      const k = xx / px(aw); const c = mix(t.accent[0], t.accent[1], t.side === 'LEFT' ? k : 1 - k);
      cv.rect(px(ox + ax) + xx, px(oy + line + 11 - 0.42), 1, px(2), c, t.side === 'LEFT' ? 1 - k : k);
    }
  }
}

// ---- one frame ---------------------------------------------------------------
function drawFrame(cv, ox, oy, W, H, d, kind, border, background, opts) {
  const L = panel.layout(W, H, d, opts);
  const px = (u) => u * PX * ZOOM;
  // background
  if (background !== 'NONE') {
    const inner = L.inner;
    if (background === 'PARCHMENT' && !opts.legacy) {
      drawParchment(cv, ox, oy, L, d, kind, opts); // 1.3.7: one material (Compat.ParchmentLayout)
    } else if (background === 'PARCHMENT') { // 1.1.0 - 1.3.6, for the before / after sheet: the one sheet stretched to the frame
      const p = L.parchment; const c = p.corner; const S = 512; const q = 96 / S;
      const put = (x, y, w, h, u0, u1, v0, v1) => cv.quad(tex.BanzaiParchment, px(ox + x), px(oy + y), px(w), px(h), [u0, v0, u0, v1, u1, v0, u1, v1], [0.91, 0.91, 0.91], [0.91, 0.91, 0.91], true);
      put(p.x, p.y, c, c, 0, q, 0, q); put(p.x + p.w - c, p.y, c, c, 1 - q, 1, 0, q); put(p.x, p.y + p.h - c, c, c, 0, q, 1 - q, 1); put(p.x + p.w - c, p.y + p.h - c, c, c, 1 - q, 1, 1 - q, 1);
      // every edge strip reads the whole span between the corners (the torn edge is periodic over it)
      const N = 8; const M = 2;
      for (let i = 0; i < N; i++) {
        const a = c + (p.w - 2 * c) * i / N; const b = c + (p.w - 2 * c) * (i + 1) / N;
        put(p.x + a, p.y, b - a, c, q, 1 - q, 0, q); put(p.x + a, p.y + p.h - c, b - a, c, q, 1 - q, 1 - q, 1);
      }
      for (let i = 0; i < M; i++) {
        const a = c + (p.h - 2 * c) * i / M; const b = c + (p.h - 2 * c) * (i + 1) / M;
        put(p.x, p.y + a, c, b - a, 0, q, q, 1 - q); put(p.x + p.w - c, p.y + a, c, b - a, 1 - q, 1, q, 1 - q);
      }
      put(p.x + c, p.y + c, p.w - 2 * c, p.h - 2 * c, q, 1 - q, q, 1 - q);
    } else {
      const a = background === 'SOLID' ? 0.97 : 0.72;
      const g = C.glass;
      for (let yy = 0; yy < px(H - 2 * inner); yy++) {
        const t = yy / px(H - 2 * inner);
        const k = 0.8 + 0.45 * t; const al = (a + 0.06) + (a - (a + 0.06)) * t;
        cv.rect(px(ox + inner), px(oy + inner) + yy, px(W - 2 * inner), 1, [g[0] * k, g[1] * k, g[2] * k], Math.min(1, al));
      }
    }
  }
  // sample content (1.3.7: none on the material sheets - the paper alone)
  if (opts.noContent) {
    // nothing
  } else if (kind === 'chat') {
    const cx = ox + (W - 430) / 2; const cy = oy + 10.5;
    const colours = [[1, 1, 1], [1, 1, 1], [0.6, 0.6, 1], [1, 0.5, 0.5], [1, 1, 1], [0.3, 1, 0.3], [1, 0.8, 0.3], [1, 1, 1]];
    for (let i = 0; i < 8; i++) cv.words(px(cx + 4), px(cy + 4 + i * 16.5), px(360 + (i % 3) * 20), px(9), colours[i], 17 + i);
  } else if (kind === 'details') {
    drawDivider(cv, ox, oy, W, H, d, background); // the frame's own texture: under the meters (their windows are above it)
    drawMeters(cv, ox, oy, W); // 1.3.6: the two meters around the centre gutter
  } else if (kind === 'buffs') {
    // ElvUI's buff icons (25 x 21 units, 6 apart, rows 10 apart), their durations under them (BOTTOM -3, 16)
    const side = panel.PANEL.outer + d + 5; const n = opts.buffs || 17;
    const colours = [[0.95, 0.75, 0.2], [0.3, 0.6, 1], [0.6, 0.95, 0.3], [0.9, 0.3, 0.9], [1, 0.45, 0.2], [0.3, 0.9, 0.85], [0.95, 0.95, 0.95], [0.85, 0.2, 0.2]];
    const times = ['42', '9', '5m', '1h', '58', '3m', '12', '7', '2h', '30'];
    for (let i = 0; i < n; i++) {
      const col = i % 10; const row = Math.floor(i / 10);
      const x = ox + side + col * 31; const y = oy + side + row * 31;
      const c = colours[i % colours.length];
      for (let yy = 0; yy < Math.round(px(21)); yy++) for (let xx = 0; xx < Math.round(px(25)); xx++) {
        const u = xx / px(25); const v = yy / px(21);
        const r = Math.hypot(u - 0.5, v - 0.5);
        const k = 0.35 + 0.65 * Math.max(0, 1 - r * 1.6) + (Math.abs(u - v) < 0.12 || Math.abs(u + v - 1) < 0.12 ? 0.25 : 0);
        cv.blend(Math.round(px(x)) + xx, Math.round(px(y)) + yy, Math.min(1, c[0] * k), Math.min(1, c[1] * k), Math.min(1, c[2] * k), 1);
      }
      const t = times[i % times.length];
      glyphs.draw((X, Y, col0, a) => cv.blend(X, Y, col0[0], col0[1], col0[2], a), t, px(x + 12.5), px(y + 21 + 3), px(10), t.endsWith('m') || t.endsWith('h') ? [0, 0.99, 1] : [1, 1, 0.3]);
      if (i % 7 === 2) glyphs.draw((X, Y, col0, a) => cv.blend(X, Y, col0[0], col0[1], col0[2], a), '3', px(x + 25 - 1), px(y + 1), px(8), [1, 1, 1], 'topright');
    }
  } else {
    // a map square: terrain-like noise
    const m = L.inner;
    for (let yy = 0; yy < Math.round(px(H - 2 * m)); yy++) for (let xx = 0; xx < Math.round(px(W - 2 * m)); xx++) {
      const n = noise(xx / 23, yy / 21) * 0.6 + noise(xx / 7, yy / 6) * 0.4;
      cv.blend(Math.round(px(ox + m)) + xx, Math.round(px(oy + m)) + yy, 0.25 + 0.25 * n, 0.32 + 0.3 * n, 0.18 + 0.15 * n, 1);
    }
  }
  if (opts.noStalks) return; // 1.3.7: the seam sheet - the parchment alone over a contrasting backing
  // stalks (bottom 0, sides 1, top 2) then ties
  const order = [...L.pieces].sort((a, b) => a.sub - b.sub);
  let h = 0.3;
  for (const p of order) {
    h = (h * 9301 + 49297) % 233280 / 233280;
    const from = stalkColor(border, kind, p.stalk, p.pa, W, H, h); const to = stalkColor(border, kind, p.stalk, p.pb, W, H, h);
    cv.quad(tex[p.tex], px(ox + p.x), px(oy + p.y), px(p.w), px(p.h), p.uv, from, to, p.stalk === 'top' || p.stalk === 'bottom');
  }
  for (const t of L.ties) {
    const rope = ROPE[border];
    const uv = t.flip ? [1, 0, 1, t.v1, 0, 0, 0, t.v1] : [0, 0, 0, t.v1, 1, 0, 1, t.v1];
    cv.quad(tex.BanzaiRopeTie, px(ox + t.x), px(oy + t.y), px(t.w), px(t.h), uv, rope[0][1], rope[1][1], false);
  }
  if (opts.sideTitles) drawSideTitles(cv, ox, oy, W, d); // 1.3.6: DAMAGE / HEALING (the gutter sheet)
  // the panel titles: letters (display font, 22: ~16 units of capital) over a dark backing with soft ends, an accent under them
  if (opts.title && !opts.noContent) {
    const T = opts.title; const line = panel.PANEL.outer + d / 2;
    const cy = oy + (T.bottom ? H - line : line); const cx = ox + W / 2;
    const textW = T.text.length * (16 * 6 / 7) - 16 / 7; const width = textW + 14; const bh = 22 * 0.78; const fade = 9;
    for (let xx = 0; xx < Math.round(px(width)); xx++) {
      const u = xx / px(width) * width; const a = 0.97 * Math.min(1, u / fade, (width - u) / fade);
      cv.rect(px(cx - width / 2) + xx, px(cy - bh / 2), 1, px(bh), [0.01, 0.025, 0.018], a);
    }
    const mix = (a, b, t) => a.map((v, k) => v + (b[k] - v) * t);
    glyphs.draw((X, Y, col0, a) => cv.blend(X, Y, col0[0], col0[1], col0[2], a), T.text, px(cx), px(cy), px(16), (i, n) => mix(T.bright, T.deep, n > 1 ? i / (n - 1) : 0));
    const ay = cy + 11 - 0.42; const aw = textW + 18;
    for (let xx = 0; xx < Math.round(px(aw)); xx++) { const c = mix(T.bright, T.deep, xx / px(aw)); cv.rect(px(cx - aw / 2) + xx, px(ay), 1, px(2), c, 1); }
  }
  // the bottom information panel (32 high, dark glass, over the frame's bottom line) on the chat / Details sheets
  if (opts.shortBottom) {
    cv.rect(px(ox - 24), px(oy + H + 0.5), px(W + 48), px(32), [0.012, 0.06, 0.036], 0.72);
    cv.rect(px(ox - 24), px(oy + H + 0.5), px(W + 48), px(1), [0.4, 0.8, 0.3], 0.9);
  }
}

function world(cv) {
  for (let y = 0; y < cv.h; y++) for (let x = 0; x < cv.w; x++) {
    const n = noise(x / 60, y / 50) * 0.5 + noise(x / 13, y / 11) * 0.3 + noise(x / 3, y / 3) * 0.2;
    const sky = y / cv.h;
    cv.blend(x, y, 0.30 + 0.35 * n - 0.1 * sky, 0.38 + 0.35 * n, 0.30 + 0.25 * n + 0.15 * (1 - sky), 1);
  }
}

const BORDERS = ['CLASS', 'BANZAI', 'HARDKORH'];
const BACKS = ['SOLID', 'GLASS', 'PARCHMENT'];
const d = panel.PANEL.stalk;
const CHAT_TITLE = { text: 'CHAT', bright: [0.20, 0.64, 0.32], deep: [0.70, 0.16, 0.16] };
const BUFFS_TITLE = { text: 'BUFFS', bright: [0.55, 1.00, 0.30], deep: [0.62, 0.32, 1.00], bottom: true };
const CHAT_LEFT = -0.655; // 1.2.0: Compat.CHAT.left, the left stalk on the screen edge
const buffsH = (rows) => (rows * 21 + (rows - 1) * 10) + (panel.PANEL.outer + d + 5) + (panel.PANEL.outer + d + 18);
const buffsW = (10 * 25 + 9 * 6) + 2 * (panel.PANEL.outer + d + 5);
const sheets = [
  { name: 'chat', W: 493.31, H: 161, opts: { shortBottom: true, flushLeft: CHAT_LEFT, title: CHAT_TITLE }, backs: BACKS },
  { name: 'buffs', W: buffsW, H: buffsH(2), opts: { title: BUFFS_TITLE, buffs: 17 }, backs: BACKS },
  { name: 'buffs-3rows', kind: 'buffs', W: buffsW, H: buffsH(3), opts: { title: BUFFS_TITLE, buffs: 26 }, backs: BACKS },
  { name: 'details', W: 493.31, H: 161, opts: { shortBottom: true }, backs: BACKS },
  { name: 'minimap', W: 185 + 2 * (panel.PANEL.outer + d), H: 185 + 2 * (panel.PANEL.outer + d), opts: {}, backs: ['NONE'] },
];
for (const s of sheets) {
  const margin = 24;
  const cols = s.backs.length; const rows = BORDERS.length;
  const cw = (s.W + 2 * margin) * PX * ZOOM; const ch = (s.H + 2 * margin) * PX * ZOOM;
  const cv = new Canvas(Math.ceil(cw * cols), Math.ceil(ch * rows));
  world(cv);
  BORDERS.forEach((border, r) => s.backs.forEach((back, c) => {
    drawFrame(cv, margin + c * (s.W + 2 * margin), margin + r * (s.H + 2 * margin), s.W, s.H, d, s.kind || s.name, border, back, s.opts);
  }));
  const file = path.join(out, `${s.name}${ZOOM > 1 ? '-x' + ZOOM : ''}.png`);
  if (ZOOM > 1) {
    const crop = (name, ux, uy, uw, uh) => {
      const x0 = Math.round(ux * PX * ZOOM); const y0 = Math.round(uy * PX * ZOOM); const w = Math.round(uw * PX * ZOOM); const h = Math.round(uh * PX * ZOOM);
      const b = Buffer.alloc(w * h * 4); const all = cv.toRGBA();
      for (let y = 0; y < h; y++) all.copy(b, y * w * 4, ((y0 + y) * cv.w + x0) * 4, ((y0 + y) * cv.w + x0 + w) * 4);
      tga.writePNG(path.join(out, `${s.name}-${name}-x${ZOOM}.png`), w, h, b);
    };
    const col = Math.min(1, cols - 1); const row = 1;
    crop('tr', margin + col * (s.W + 2 * margin) + s.W - 150, margin + row * (s.H + 2 * margin) - 20, 170, 110);
    crop('bl', margin + (cols - 1) * (s.W + 2 * margin) - 20, margin + 2 * (s.H + 2 * margin) + s.H - 90, 170, 110);
  } else tga.writePNG(file, cv.w, cv.h, cv.toRGBA());
  console.log(`${file}  ${cv.w}x${cv.h}  rows ${BORDERS.join(' / ')}  columns ${s.backs.join(' / ')}`);
}
// 1.2.0: the chat on the left screen edge - the canvas's left edge is the screen's (BANZAI + GLASS, HARDKORH + PARCHMENT, CLASS + GLASS)
{
  const W = 493.31; const H = 161; const top = 30; const gap = 60;
  const combos = [['BANZAI', 'GLASS'], ['HARDKORH', 'PARCHMENT'], ['CLASS', 'GLASS']];
  const cv = new Canvas(Math.ceil((W + 60) * PX * ZOOM), Math.ceil((top + combos.length * (H + gap)) * PX * ZOOM));
  world(cv);
  combos.forEach(([border, back], r) => drawFrame(cv, CHAT_LEFT, top + r * (H + gap), W, H, d, 'chat', border, back, { shortBottom: true, flushLeft: CHAT_LEFT, title: CHAT_TITLE }));
  const file = path.join(out, `chat-flush${ZOOM > 1 ? '-x' + ZOOM : ''}.png`);
  if (ZOOM > 1) { // the left edge, enlarged
    const w = Math.round(80 * PX * ZOOM); const all = cv.toRGBA(); const b = Buffer.alloc(w * cv.h * 4);
    for (let y = 0; y < cv.h; y++) all.copy(b, y * w * 4, y * cv.w * 4, (y * cv.w + w) * 4);
    tga.writePNG(file, w, cv.h, b);
  } else tga.writePNG(file, cv.w, cv.h, cv.toRGBA());
  console.log(`${file}  the left screen edge at x 0  rows ${combos.map((c) => c.join(' + ')).join(' / ')}`);
}
// 1.3.6 the Details centre gutter as it sits on Darren's screen: the canvas's right edge is the screen's (2560 x 1440,
// UI scale 0.71; the frame's centre 47.15 + 215 units in from it), so every edge falls on the game's pixel grid. BANZAI
// GLASS, BANZAI SOLID, HARDKORH PARCHMENT. The meters' own pixels (tagged) measure the gutter: nothing of DAMAGE right
// of its left edge, nothing of HEALING left of its right edge, only the divider in it. Zoom 1 only (screen pixels);
// details-gutter-x8.png is the gutter enlarged pixel for pixel.
if (ZOOM === 1) {
  const W = 493.31; const H = 161; const top = 30; const gap = 50;
  const combos = [['BANZAI', 'GLASS'], ['BANZAI', 'SOLID'], ['HARDKORH', 'PARCHMENT']];
  const cv = new Canvas(Math.ceil((W + 80) * PX), Math.ceil((top + combos.length * (H + gap)) * PX));
  world(cv);
  const centre = cv.w / PX - (47.15 + 215); // Compat.DETAILS right + centerX, from the screen's right edge
  const ox = centre - W / 2;
  const report = [];
  let ok = true;
  combos.forEach(([border, back], r) => {
    const oy = top + r * (H + gap);
    drawFrame(cv, ox, oy, W, H, d, 'details', border, back, { shortBottom: true, sideTitles: true });
    // measure across the rows' band (the divider's whole height: the meters' rows and the empty interior below them)
    const y0 = Math.round((oy + panel.PANEL.outer + d + DIVIDER.pad * d + DIVIDER.fade) * PX); const y1 = Math.round((oy + H - (panel.PANEL.outer + d + DIVIDER.pad * d + DIVIDER.fade)) * PX);
    let dmgMax = -1; let healMin = cv.w; let divMin = cv.w; let divMax = -1; let dmgMin = cv.w; let healMax = -1;
    for (let y = y0; y < y1; y++) for (let x = 0; x < cv.w; x++) {
      const o = cv.owner[y * cv.w + x];
      if (o & 1) { dmgMax = Math.max(dmgMax, x); dmgMin = Math.min(dmgMin, x); }
      if (o & 2) { healMin = Math.min(healMin, x); healMax = Math.max(healMax, x); }
      if (o & 4) { divMin = Math.min(divMin, x); divMax = Math.max(divMax, x); }
    }
    const gutter = healMin - dmgMax - 1; const left = divMin - dmgMax - 1; const right = healMin - divMax - 1; const divider = divMax - divMin + 1;
    const dmgW = dmgMax - dmgMin + 1; const healW = healMax - healMin + 1;
    const pass = gutter >= 18 && gutter <= 20 && left >= 8 && left <= 9 && right >= 8 && right <= 9 && divider === 2 && Math.abs(dmgW - healW) <= 1;
    ok = ok && pass;
    report.push(`  ${border} ${back}: gutter ${gutter} px = ${left} empty + ${divider} px divider + ${right} empty (DAMAGE ${dmgMin}..${dmgMax}, HEALING ${healMin}..${healMax}, divider ${divMin}..${divMax}; meters ${dmgW} / ${healW} px)${pass ? '' : '  <- OUT OF SPEC'}`);
  });
  const file = path.join(out, 'details-gutter.png');
  tga.writePNG(file, cv.w, cv.h, cv.toRGBA());
  // the gutter enlarged (nearest neighbour: one screen pixel = 8 x 8), the first combination's middle rows
  {
    const k = 8; const cx = Math.round(centre * PX); const cw = 48; const cy = Math.round((top + 18) * PX); const ch = 60;
    const all = cv.toRGBA(); const b = Buffer.alloc(cw * k * ch * k * 4);
    for (let y = 0; y < ch * k; y++) for (let x = 0; x < cw * k; x++) {
      const s = ((cy + Math.floor(y / k)) * cv.w + (cx - cw / 2 + Math.floor(x / k))) * 4; const t = (y * cw * k + x) * 4;
      all.copy(b, t, s, s + 4);
    }
    tga.writePNG(path.join(out, 'details-gutter-x8.png'), cw * k, ch * k, b);
  }
  console.log(`${file}  the right screen edge at the canvas's right edge  rows ${combos.map((c) => c.join(' + ')).join(' / ')}`);
  const summary = `details gutter (Compat.DETAILS width ${METERS.width}, gap ${METERS.gap}; frame ${W} wide, unchanged):\n${report.join('\n')}`;
  fs.writeFileSync(path.join(out, 'details-gutter.txt'), summary + '\n'); // the measurement on record (tools/validate.js block 26)
  console.log(summary);
  if (!ok) { console.error('details gutter: OUT OF SPEC'); process.exitCode = 1; }
}
// 1.3.7 HARDKORH PARCHMENT, one material, at Darren's screen pixels (zoom 1): the three panels with their content and
// without it (the paper alone), before (1.3.6, the one sheet stretched to each frame) and after, the synthetic sizes
// (narrow, square, medium-wide, very wide), the parchment alone over a contrasting backing (seams, cracks, overlaps),
// three brightness settings, enlarged crops; the measurements go to parchment.txt (tools/validate.js block 27) and
// out-of-spec numbers fail the run.
if (ZOOM === 1) {
  const D0 = d; const P0 = panel.PANEL;
  const PANELS = [
    { name: 'BUFFS', kind: 'buffs', W: buffsW, H: buffsH(2), opts: { title: BUFFS_TITLE, buffs: 17 } },
    { name: 'BUFFS 3 ROWS', kind: 'buffs', W: buffsW, H: buffsH(3), opts: { title: BUFFS_TITLE, buffs: 26 } },
    { name: 'CHAT', kind: 'chat', W: 493.31, H: 161, opts: { shortBottom: true, title: CHAT_TITLE } },
    { name: 'DETAILS', kind: 'details', W: 493.31, H: 161, opts: { shortBottom: true, sideTitles: true } },
  ];
  const STRESS = [
    { name: 'NARROW', kind: 'chat', W: 120, H: 330, opts: {} },
    { name: 'SQUARE', kind: 'chat', W: 260, H: 260, opts: {} },
    { name: 'MEDIUM-WIDE', kind: 'chat', W: 560, H: 200, opts: {} },
    { name: 'VERY WIDE', kind: 'details', W: 1400, H: 150, opts: {} },
  ];
  const margin = 24; const gapY = 40;
  // a column of frames; returns the canvas and each frame's place (units)
  const column = (list, extra, backing) => {
    const W = Math.max(...list.map((s) => s.W)) + 2 * margin; const H = list.reduce((n, s) => n + s.H + gapY, margin);
    const cv = new Canvas(Math.ceil(W * PX), Math.ceil(H * PX));
    if (backing) backing(cv); else world(cv);
    let y = margin; const at = [];
    for (const s of list) { at.push({ s, ox: margin, oy: y }); drawFrame(cv, margin, y, s.W, s.H, D0, s.kind, 'HARDKORH', 'PARCHMENT', { ...s.opts, ...extra(s) }); y += s.H + gapY; }
    return { cv, at };
  };
  const save = (cv, name) => { tga.writePNG(path.join(out, name + '.png'), cv.w, cv.h, cv.toRGBA()); console.log(`${path.join(out, name + '.png')}  ${cv.w}x${cv.h}`); };
  const crop = (cv, name, x0, y0, w, h, k = 4) => { // nearest neighbour: one screen pixel = k x k
    const all = cv.toRGBA(); const b = Buffer.alloc(w * k * h * k * 4);
    for (let y = 0; y < h * k; y++) for (let x = 0; x < w * k; x++) { const s = ((y0 + Math.floor(y / k)) * cv.w + x0 + Math.floor(x / k)) * 4; all.copy(b, (y * w * k + x) * 4, s, s + 4); }
    tga.writePNG(path.join(out, name + '.png'), w * k, h * k, b);
  };
  const lum = (cv, x, y) => { const o = (y * cv.w + x) * 4; return 0.2126 * cv.px[o] + 0.7152 * cv.px[o + 1] + 0.0722 * cv.px[o + 2]; };
  const rectPx = (ox, oy, s, inset) => { const L = panel.layout(s.W, s.H, D0, s.opts); const p = L.parchment; return { x0: Math.round((ox + p.x + inset) * PX), y0: Math.round((oy + p.y + inset) * PX), x1: Math.round((ox + p.x + p.w - inset) * PX), y1: Math.round((oy + p.y + p.h - inset) * PX), p }; };
  const blur = (a, w, h, r) => {
    const t = new Float64Array(w * h); const o = new Float64Array(w * h);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) { let s = 0; let n = 0; for (let k = -r; k <= r; k++) { const xx = Math.max(0, Math.min(w - 1, x + k)); s += a[y * w + xx]; n++; } t[y * w + x] = s / n; }
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) { let s = 0; let n = 0; for (let k = -r; k <= r; k++) { const yy = Math.max(0, Math.min(h - 1, y + k)); s += t[yy * w + x]; n++; } o[y * w + x] = s / n; }
    return o;
  };
  // the grain of one region, three scales, each as far as it stays alike across and down (px: the lag where its
  // autocorrelation halves - equal both ways when nothing is stretched): the fibre (minus a 7 px blur; also its mean
  // step down / across, `stretch`, 1 when round), the mottle (a 5 px blur minus a 25 px blur) and the blotches (a 13 px
  // blur minus the region's mean; measured where the region is tall enough)
  const grain = (cv, r) => {
    const w = r.x1 - r.x0; const h = r.y1 - r.y0; const a = new Float64Array(w * h);
    for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) a[y * w + x] = lum(cv, r.x0 + x, r.y0 + y);
    const lp = blur(a, w, h, 3); const hp = a.map((v, i) => v - lp[i]);
    const b2 = blur(a, w, h, 2); const b25 = blur(a, w, h, 12); const bp = b2.map((v, i) => v - b25[i]);
    const mean = a.reduce((n, v) => n + v, 0) / a.length; const bl = blur(a, w, h, 6).map((v) => v - mean);
    const step = (f, dx, dy) => { let s = 0; let n = 0; for (let y = 0; y + dy < h; y++) for (let x = 0; x + dx < w; x++) { s += Math.abs(f[(y + dy) * w + x + dx] - f[y * w + x]); n++; } return s / n; };
    const length = (f, dx, dy, max) => {
      const corr = (k) => { let s = 0; let s0 = 0; for (let y = 0; y + k * dy < h; y++) for (let x = 0; x + k * dx < w; x++) { const v = f[y * w + x]; s += v * f[(y + k * dy) * w + x + k * dx]; s0 += v * v; } return s / s0; };
      let prev = 1;
      for (let k = 1; k <= max; k++) { const c = corr(k); if (c < 0.5) return k - 1 + (prev - 0.5) / (prev - c); prev = c; }
      return max;
    };
    const lim = Math.floor(Math.min(w, h) / 2);
    return { stretch: step(hp, 0, 1) / step(hp, 1, 0), fibreX: length(hp, 1, 0, 20), fibreY: length(hp, 0, 1, 20), mottleX: length(bp, 1, 0, lim), mottleY: length(bp, 0, 1, lim),
      blotX: length(bl, 1, 0, Math.floor(w / 2)), blotY: length(bl, 0, 1, Math.floor(h / 2)), tall: h >= 120, w, h };
  };
  const fmt = (g) => `fibre ${g.fibreX.toFixed(2)} x ${g.fibreY.toFixed(2)} px (across x down), stretch ${g.stretch.toFixed(2)}; mottle ${g.mottleX.toFixed(1)} x ${g.mottleY.toFixed(1)} px`
    + (g.tall ? `; blotches ${g.blotX.toFixed(0)} x ${g.blotY.toFixed(0)} px` : '') + ` (region ${g.w} x ${g.h} px)`;
  const report = []; let ok = true;
  const need = (pass, line) => { ok = ok && pass; report.push(`  ${line}${pass ? '' : '  <- OUT OF SPEC'}`); };

  // A. the panels, with their content and without it; the grain inside each (the body alone: one band in from the paper's edge)
  save(column(PANELS, () => ({})).cv, 'parchment');
  const mat = column(PANELS, () => ({ noContent: true }));
  save(mat.cv, 'parchment-material');
  const band = P0.parchmentCorner * D0;
  report.push(`grain, 1.3.7 (the body: ${panel.PARCHMENT.tileW} x ${panel.PARCHMENT.tileH} tile at ${panel.PARCHMENT.density} texels per unit on both axes of every panel):`);
  const grains = mat.at.map(({ s, ox, oy }) => ({ s, g: grain(mat.cv, rectPx(ox, oy, s, band + 2)) }));
  // round: the fibre and the mottle alike across and down (the blotches are a few large patches per panel - their numbers are shown, and
  // judged over a whole tile below, where there are enough of them)
  const round = (g) => g.stretch > 0.8 && g.stretch < 1.25 && g.fibreX / g.fibreY > 0.75 && g.fibreX / g.fibreY < 1.33 && g.mottleX / g.mottleY > 0.75 && g.mottleX / g.mottleY < 1.33;
  for (const { s, g } of grains) need(round(g), `${s.name} ${s.W.toFixed(1)} x ${s.H.toFixed(1)}: ${fmt(g)}`);
  const spread = (list) => Math.max(...list) / Math.min(...list);
  const same = (list) => ['fibreX', 'fibreY', 'mottleX', 'mottleY'].map((k) => spread(list.map((g) => g[k])));
  const sp = same(grains.map(({ g }) => g));
  need(sp.every((v) => v < 1.2), `the same grain on every panel: fibre across ${grains.map(({ g }) => g.fibreX.toFixed(2)).join(' / ')}, down ${grains.map(({ g }) => g.fibreY.toFixed(2)).join(' / ')} px; mottle across ${grains.map(({ g }) => g.mottleX.toFixed(1)).join(' / ')}, down ${grains.map(({ g }) => g.mottleY.toFixed(1)).join(' / ')} px (largest / smallest at most ${Math.max(...sp).toFixed(2)})`);

  // B. before / after: 1.3.6 (the stretched sheet) left, 1.3.7 right
  {
    const list = [PANELS[0], PANELS[2], PANELS[3]];
    const W = 493.31 + 2 * margin; const H = list.reduce((n, s) => n + s.H + gapY, margin);
    const cv = new Canvas(Math.ceil(2 * W * PX), Math.ceil(H * PX)); world(cv);
    let y = margin; const at = [];
    for (const s of list) {
      drawFrame(cv, margin, y, s.W, s.H, D0, s.kind, 'HARDKORH', 'PARCHMENT', { ...s.opts, noContent: true, legacy: true });
      drawFrame(cv, W + margin, y, s.W, s.H, D0, s.kind, 'HARDKORH', 'PARCHMENT', { ...s.opts, noContent: true });
      at.push({ s, y }); y += s.H + gapY;
    }
    save(cv, 'parchment-before-after');
    report.push('grain, 1.3.6 for comparison (the 512 px sheet stretched to each frame):');
    for (const { s, y: oy } of at) report.push(`  ${s.name}: ${fmt(grain(cv, rectPx(margin, oy, s, band + 2)))}`);
  }

  // C. the synthetic sizes (the material, not one panel): undistorted everywhere, one grain size
  {
    const st = column(STRESS, () => ({ noContent: true }));
    save(st.cv, 'parchment-stress');
    report.push('synthetic sizes (the same renderer, nothing of the real layout changed):');
    const sg = st.at.map(({ s, ox, oy }) => ({ s, g: grain(st.cv, rectPx(ox, oy, s, band + 2)) }));
    for (const { s, g } of sg) need(round(g), `${s.name} ${s.W} x ${s.H}: ${fmt(g)}`);
    const all = same([...grains, ...sg].map(({ g }) => g));
    // the blotches over one whole tile (512 x 256 units of paper, the body alone): as large across as down
    const T = { name: 'ONE TILE', kind: 'chat', W: panel.PARCHMENT.tileW / panel.PARCHMENT.density + 2 * (P0.outer + P0.parchment * D0), H: panel.PARCHMENT.tileH / panel.PARCHMENT.density + 2 * (P0.outer + P0.parchment * D0), opts: {} };
    const tc = new Canvas(Math.ceil((T.W + 2 * margin) * PX), Math.ceil((T.H + 2 * margin) * PX));
    drawFrame(tc, margin, margin, T.W, T.H, D0, T.kind, 'HARDKORH', 'PARCHMENT', { noContent: true, noStalks: true, bodyOnly: true });
    const tg = grain(tc, rectPx(margin, margin, T, 0));
    need(round(tg) && tg.blotX / tg.blotY > 0.6 && tg.blotX / tg.blotY < 1.65, `${T.name} (the body alone, ${T.W - 2 * (P0.outer + P0.parchment * D0)} x ${T.H - 2 * (P0.outer + P0.parchment * D0)} units): ${fmt(tg)}`);
    need(all.every((v) => v < 1.2), `one grain over all eight sizes (largest / smallest fibre ${all[0].toFixed(2)} across, ${all[1].toFixed(2)} down; mottle ${all[2].toFixed(2)} across, ${all[3].toFixed(2)} down)`);
  }

  // D. the parchment alone over a magenta / cyan checker: every pixel of the paper covered by the body exactly once
  // (no crack), by at most one worn piece (no doubled darkening), opaque; the joins (corner | strip, the two halves of a
  // strip, the worn band's inner end) and the tile's own wrap lines no steeper than the paper around them
  // E. (with D) the worn edge from the wear alone - the paper divided by its body drawn without the worn pieces, so the
  // blotches do not count: as deep on every panel and every side (where the darkening falls under 1 %)
  {
    const list = [PANELS[0], PANELS[1], PANELS[2], PANELS[3], STRESS[3]];
    const checker = (cv) => { for (let y = 0; y < cv.h; y++) for (let x = 0; x < cv.w; x++) { const on = ((x >> 3) + (y >> 3)) % 2 === 0; cv.blend(x, y, on ? 1 : 0, on ? 0 : 1, 1, 1); } };
    const W = Math.max(...list.map((s) => s.W)) + 2 * margin; const H = list.reduce((n, s) => n + s.H + gapY, margin);
    const cv = new Canvas(Math.ceil(W * PX), Math.ceil(H * PX)); checker(cv);
    const bare = new Canvas(cv.w, cv.h); checker(bare);
    const bodyHits = new Uint8Array(cv.w * cv.h); const wornHits = new Uint8Array(cv.w * cv.h); let translucent = 0;
    const visit = (piece) => (x, y, a) => { if (x < 0 || y < 0 || x >= cv.w || y >= cv.h) return; const i = y * cv.w + x; if (piece.texture === 'tile') { bodyHits[i]++; if (a < 0.999) translucent++; } else wornHits[i]++; };
    let y = margin; const at = [];
    for (const s of list) {
      drawFrame(cv, margin, y, s.W, s.H, D0, s.kind, 'HARDKORH', 'PARCHMENT', { ...s.opts, noContent: true, noStalks: true, visit });
      drawFrame(bare, margin, y, s.W, s.H, D0, s.kind, 'HARDKORH', 'PARCHMENT', { ...s.opts, noContent: true, noStalks: true, bodyOnly: true });
      at.push({ s, oy: y }); y += s.H + gapY;
    }
    save(cv, 'parchment-seams');
    const wear = (x, yy) => lum(cv, x, yy) / Math.max(1e-6, lum(bare, x, yy));
    report.push('seams (the parchment alone over a contrasting checker; a join\'s step against the steps beside it, in 8-bit levels):');
    const depths = []; const edges = [];
    for (const { s, oy } of at) {
      const r = rectPx(margin, oy, s, 0); const p = r.p;
      let cracks = 0; let doubled = 0; let worn = 0;
      for (let yy = r.y0; yy < r.y1; yy++) for (let xx = r.x0; xx < r.x1; xx++) { const i = yy * cv.w + xx; if (bodyHits[i] !== 1) cracks++; if (wornHits[i] > 1) doubled++; if (wornHits[i]) worn++; }
      // the joins over the visible part of their band (from the stalk's inner edge): the mean step across the join line
      // and the mean step of the lines 2 - 4 px either side of it, in 8-bit levels
      const lay = panel.parchmentLayout(p.w, p.h, D0, s.kind); const c = lay.band; const vis = (P0.outer + D0) - (P0.outer + P0.parchment * D0);
      const X = (u) => Math.round((margin + p.x + u) * PX); const Y = (u) => Math.round((oy + p.y + u) * PX);
      const stepV = (x, ya, yb) => { let j = 0; let ref = 0; let n = 0; for (let yy = ya; yy < yb; yy++) { j += Math.abs(lum(cv, x, yy) - lum(cv, x - 1, yy)); for (const k of [2, 3, 4, -2, -3, -4]) { ref += Math.abs(lum(cv, x + k, yy) - lum(cv, x + k - 1, yy)); n++; } } return [255 * j / (yb - ya), 255 * ref / n]; };
      const stepH = (yy, xa, xb) => { let j = 0; let ref = 0; let n = 0; for (let x = xa; x < xb; x++) { j += Math.abs(lum(cv, x, yy) - lum(cv, x, yy - 1)); for (const k of [2, 3, 4, -2, -3, -4]) { ref += Math.abs(lum(cv, x, yy + k) - lum(cv, x, yy + k - 1)); n++; } } return [255 * j / (xb - xa), 255 * ref / n]; };
      const joins = [];
      for (const [label, ya, yb] of [['top', Y(vis), Y(c)], ['bottom', Y(p.h - c), Y(p.h - vis)]]) for (const u of [c, p.w / 2, p.w - c]) joins.push([`${label} x ${u.toFixed(1)}`, ...stepV(X(u), ya, yb)]);
      for (const [label, xa, xb] of [['left', X(vis), X(c)], ['right', X(p.w - c), X(p.w - vis)]]) for (const u of [c, p.h / 2, p.h - c]) joins.push([`${label} y ${u.toFixed(1)}`, ...stepH(Y(u), xa, xb)]);
      joins.push(['band end top', ...stepH(Y(c), X(c), X(p.w - c))], ['band end bottom', ...stepH(Y(p.h - c), X(c), X(p.w - c))]);
      joins.push(['band end left', ...stepV(X(c), Y(c), Y(p.h - c))], ['band end right', ...stepV(X(p.w - c), Y(c), Y(p.h - c))]);
      // the tile's own wrap lines (u, v passing a whole tile) inside the body-only middle
      const M = panel.PARCHMENT; const ph0 = M.phase[s.kind] || M.phase.chat;
      for (let n = 1; ; n++) { const u = (n - ph0[0]) * M.tileW / M.density; if (u >= p.w - c) break; if (u > c) joins.push([`tile wrap x ${u.toFixed(1)}`, ...stepV(X(u), Y(c), Y(p.h - c))]); }
      for (let n = 1; ; n++) { const v = (n - ph0[1]) * M.tileH / M.density; if (v >= p.h - c) break; if (v > c) joins.push([`tile wrap y ${v.toFixed(1)}`, ...stepH(Y(v), X(c), X(p.w - c))]); }
      const excess = (j) => j[1] - j[2]; // levels above the paper beside it
      const worst = joins.reduce((m, j) => (excess(j) > excess(m) ? j : m), joins[0]);
      need(cracks === 0 && doubled === 0 && worn > 0 && excess(worst) < 1, `${s.name}: cracks ${cracks}, doubled ${doubled}; ${joins.length} joins, the largest step ${worst[0]}: ${worst[1].toFixed(2)} vs ${worst[2].toFixed(2)} levels beside it (${excess(worst) >= 0 ? '+' : ''}${excess(worst).toFixed(2)})`);
      // the edge's depth per side, the mean over the strip's run, outward -> inward
      const run = (a, b) => { const out0 = []; for (let k = a; k < b; k++) out0.push(k); return out0; };
      const rx = run(X(c), X(p.w - c)); const ry = run(Y(c), Y(p.h - c));
      const profile = (at0) => { const prof = []; for (let k = 0; k < Math.round(c * PX); k++) prof.push(at0(k)); return prof; };
      const sides = {
        top: profile((k) => rx.reduce((n, x) => n + wear(x, r.y0 + k), 0) / rx.length), bottom: profile((k) => rx.reduce((n, x) => n + wear(x, r.y1 - 1 - k), 0) / rx.length),
        left: profile((k) => ry.reduce((n, yy) => n + wear(r.x0 + k, yy), 0) / ry.length), right: profile((k) => ry.reduce((n, yy) => n + wear(r.x1 - 1 - k, yy), 0) / ry.length) };
      const depth = (prof) => { let k = prof.length - 1; while (k > 0 && prof[k - 1] >= 0.99) k--; return k; };
      const d4 = Object.fromEntries(Object.entries(sides).map(([k, prof]) => [k, depth(prof)]));
      depths.push(...Object.values(d4)); edges.push(sides);
      report.push(`    worn edge ${d4.top} / ${d4.bottom} / ${d4.left} / ${d4.right} px deep (top / bottom / left / right, from the paper's edge; the stalk covers the outer ${(vis * PX).toFixed(1)}); its darkest visible row ${(100 * (1 - Math.min(...Object.values(sides).map((prof) => prof[Math.ceil(vis * PX)])))).toFixed(0)} %`);
    }
    need(translucent === 0, `the body opaque everywhere (${translucent} translucent body pixels)`);
    need(Math.max(...depths) - Math.min(...depths) <= 1, `the same worn edge on every panel and every side: ${Math.min(...depths)} - ${Math.max(...depths)} px deep`);
    crop(cv, 'parchment-seams-corner-x4', Math.round((margin + 6) * PX) - 4, Math.round((at[2].oy + 6) * PX) - 4, 60, 50); // the chat's top-left corner and the start of its strips
    crop(cv, 'parchment-seams-middle-x4', Math.round((margin + 6 + (493.31 - 12) / 2) * PX) - 30, Math.round((at[3].oy + 6) * PX) - 4, 60, 50); // where the Details top strip's halves meet
  }

  // F. brightness 70 / 100 / 110 %: the whole paper - body, corners, strips - scaled alike (the parchment alone)
  {
    const s = PANELS[3]; const shots = {};
    for (const b of [0.7, 1, 1.1]) {
      const cv = new Canvas(Math.ceil((s.W + 2 * margin) * PX), Math.ceil((s.H + 2 * margin) * PX));
      drawFrame(cv, margin, margin, s.W, s.H, D0, s.kind, 'HARDKORH', 'PARCHMENT', { ...s.opts, noContent: true, noStalks: true, brightness: b });
      shots[b] = cv;
    }
    const r = rectPx(margin, margin, s, 0);
    const dev = (b) => { let worst = 0; for (let yy = r.y0; yy < r.y1; yy++) for (let xx = r.x0; xx < r.x1; xx++) { const o = (yy * shots[1].w + xx) * 4; for (let c = 0; c < 3; c++) { const base = shots[1].px[o + c]; if (base > 0.05) worst = Math.max(worst, Math.abs(shots[b].px[o + c] / base - b)); } } return worst; };
    need(dev(0.7) < 0.01 && dev(1.1) < 0.01, `brightness: every pixel of the paper scaled alike (largest deviation ${dev(0.7).toFixed(4)} at 70 %, ${dev(1.1).toFixed(4)} at 110 %)`);
    const cv = new Canvas(Math.ceil((s.W + 2 * margin) * PX), Math.ceil((3 * (s.H + gapY) + margin) * PX)); world(cv);
    [0.7, 1, 1.1].forEach((b, i) => drawFrame(cv, margin, margin + i * (s.H + gapY), s.W, s.H, D0, s.kind, 'HARDKORH', 'PARCHMENT', { ...s.opts, noContent: true, brightness: b }));
    save(cv, 'parchment-brightness');
  }

  // G. enlarged crops (one screen pixel = 4 x 4) from the paper-alone sheet, and the Details text on parchment
  {
    const at = (name) => mat.at.find((a) => a.s.name === name);
    const centre = (name, w = 80, h = 40) => { const a = at(name); return [Math.round((a.ox + a.s.W / 2) * PX) - w / 2, Math.round((a.oy + a.s.H / 2) * PX) - h / 2, w, h]; };
    crop(mat.cv, 'parchment-crop-buffs-centre-x4', ...centre('BUFFS', 80, 30));
    crop(mat.cv, 'parchment-crop-chat-centre-x4', ...centre('CHAT'));
    crop(mat.cv, 'parchment-crop-details-centre-x4', ...centre('DETAILS'));
    const dl = at('DETAILS'); crop(mat.cv, 'parchment-crop-details-corner-x4', Math.round((dl.ox + dl.s.W) * PX) - 70, Math.round(dl.oy * PX) - 6, 76, 56);
    const ch = at('CHAT'); crop(mat.cv, 'parchment-crop-chat-corner-x4', Math.round(ch.ox * PX) - 6, Math.round(ch.oy * PX) - 6, 76, 56);
  }
  const summary = `parchment (1.3.7, HARDKORH border, Darren's 2560 x 1440 at UI scale 0.71):\n${report.join('\n')}`;
  fs.writeFileSync(path.join(out, 'parchment.txt'), summary + '\n');
  console.log(summary);
  if (!ok) { console.error('parchment: OUT OF SPEC'); process.exitCode = 1; }
}

// the textures themselves
for (const [name, t] of Object.entries(tex)) tga.writePNG(path.join(out, name + '.png'), t.w, t.h, t.px);
