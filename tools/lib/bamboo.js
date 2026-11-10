// Original BANZAI art, generated procedurally (no third-party artwork is read or
// copied). Greyscale with alpha, so the in-game Banzai gradients colour it.
//
//   BanzaiBundle     512x512  three bamboo stalks of different lengths with nodes,
//                             diagonal cut tips and two leaves; dark outline
//   BanzaiBundleTie  512x512  the cord binding the stalks (wraps, knot, tails),
//                             a separate layer so it takes its own accent colour
//   (BanzaiFrameBand, the 0.5.0 bevelled band, and BanzaiMinimapMask, the 0.6.0
//   parallelogram mask, are no longer generated: 1.1.0 frames the chat, Details
//   and minimap in bamboo, tools/lib/panel.js)
//   BanzaiBar        256x64   smooth status bar (unit frames, nameplates, Details rows)
//   BanzaiButtonRing / BanzaiButtonMask (64 / 128) / BanzaiButtonCircle /
//   BanzaiButtonGlow / BanzaiButtonGlowSquare
//                             circular action buttons: thick ring and icon mask
//                             drawn for the screen pixels they cover (0.7.0),
//                             cooldown swipe, proc halos (round / rounded square)
//   BanzaiIdentityRing / BanzaiIdentityMask 64x64
//                             0.7.0: the small identity circles on the secondary
//                             unit frames (thin ring, icon mask)
//   BanzaiSquareBorder34 .. 42 / BanzaiSquareBorder128 / BanzaiSquareMask /
//   BanzaiSquareSwipe / BanzaiSquareGlow
//                             1.2.0 BANZAI SQUARE action buttons: a thin border
//                             half outside the button, drawn for every whole-pixel
//                             button width ElvUI makes (34 .. 42 px, 64 px canvas)
//                             plus an 80 px drawing for larger buttons; the icon
//                             mask, the cooldown swipe and the proc halo of the
//                             same chamfered shape
'use strict';

function hash(x, y) {
  let h = (x * 374761393 + y * 668265263) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295;
}
function smooth(t) { return t * t * (3 - 2 * t); }
function noise(x, y) {
  const xi = Math.floor(x); const yi = Math.floor(y);
  const xf = smooth(x - xi); const yf = smooth(y - yi);
  const a = hash(xi, yi); const b = hash(xi + 1, yi); const c = hash(xi, yi + 1); const d = hash(xi + 1, yi + 1);
  return a + (b - a) * xf + (c - a) * yf + (a - b - c + d) * xf * yf;
}
const g = (x, w) => Math.exp(-(x * x) / (w * w));
const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));

// Stalk surface. s: px along the stalk, t: -1..1 across, period: node spacing, phase: node offset
function stalk(s, t, period, seed, phase = 0) {
  const at = Math.min(1, Math.abs(t));
  const round = Math.sqrt(Math.max(0, 1 - at * at));
  let v = 0.42 + 0.50 * Math.pow(round, 0.55);
  v += 0.24 * g(t + 0.38, 0.13);                  // sharp specular ridge
  v += 0.07 * g(t - 0.42, 0.10);
  v += 0.06 * g(t - 0.06, 0.025);                 // thin inlay line (futuristic)
  if (at > 0.84) v *= Math.max(0.12, 1 - (at - 0.84) * 5.2); // structural dark edge
  const u = ((((s + phase) % period) + period) % period);
  const d = Math.min(u, period - u);
  const after = u < period / 2 ? u : u - period;
  v -= 0.62 * g(d, 2.4) * (0.55 + 0.45 * round);  // node groove
  v += 0.40 * g(after - 5.5, 2.8) * round;        // raised node ring
  v += 0.10 * g(d, 15);                           // swelling at the node
  v -= 0.06 * g(d - period * 0.5, period * 0.2);  // segment waist
  v += 0.03 * (noise(s / 70 + seed, t * 9) - 0.5) + 0.018 * (noise(s / 9 + seed * 3, t * 30) - 0.5);
  return clamp(v);
}

// Renders `fn(x, y) -> [value, coverage]` with 3x3 supersampling, then adds a dark outline.
function render(w, h, fn, outlinePx = 0) {
  const SS = 3;
  const val = new Float32Array(w * h); const cov = new Float32Array(w * h);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    let sv = 0; let sc = 0;
    for (let j = 0; j < SS; j++) for (let i = 0; i < SS; i++) {
      const r = fn(x + (i + 0.5) / SS, y + (j + 0.5) / SS);
      if (r) { sv += r[0] * r[1]; sc += r[1]; }
    }
    cov[y * w + x] = sc / (SS * SS);
    val[y * w + x] = sc > 0 ? sv / sc : 0;
  }
  const px = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const i = y * w + x;
    let a = cov[i]; let v = val[i];
    if (outlinePx > 0 && a < 1) {
      let near = 0;
      for (let dy = -outlinePx; dy <= outlinePx; dy++) for (let dx = -outlinePx; dx <= outlinePx; dx++) {
        if (dx * dx + dy * dy > outlinePx * outlinePx) continue;
        const xx = x + dx; const yy = y + dy;
        if (xx >= 0 && yy >= 0 && xx < w && yy < h) near = Math.max(near, cov[yy * w + xx]);
      }
      const ring = near * 0.88;
      if (ring > a) { v = (v * a + 0.04 * (ring - a)) / ring; a = ring; }
    }
    const o = i * 4;
    const c = Math.round(clamp(v) * 255);
    px[o] = c; px[o + 1] = c; px[o + 2] = c; px[o + 3] = Math.round(clamp(a) * 255);
  }
  return px;
}

// ---- tied bundle -----------------------------------------------------------
const D = [0.5, -0.866];  // stalk direction (up-right, image y down)
const N = [0.866, 0.5];   // across the bundle
const C = [250, 266];     // bundle centre
const R = 25;             // stalk radius (px)
const STALKS = [          // back to front
  { o: -46, s0: -165, s1: 150, phase: 30, seed: 1, shade: 0.8 },
  { o: 46, s0: -135, s1: 112, phase: 57, seed: 2, shade: 0.8 },
  { o: 0, s0: -208, s1: 214, phase: 0, seed: 3, shade: 1 },
];
const LEAVES = [
  { at: 150, angle: 52, len: 118, wid: 15 },
  { at: 150, angle: 84, len: 86, wid: 11 },
];
const TIE = { s: -22, half: 84, width: 32 };

function local(x, y) {
  const px = x - C[0]; const py = y - C[1];
  return [px * D[0] + py * D[1], px * N[0] + py * N[1]]; // [s along, o across]
}
function rot(v, deg) {
  const a = (deg * Math.PI) / 180;
  return [v[0] * Math.cos(a) - v[1] * Math.sin(a), v[0] * Math.sin(a) + v[1] * Math.cos(a)];
}

function stalkSample(st, s, o) {
  const t = (o - st.o) / R;
  if (Math.abs(t) > 1) return null;
  const top = st.s1 + 1.25 * t * R;    // diagonal cut tip
  const bottom = st.s0 + 0.3 * t * R;
  if (s > top || s < bottom) return null;
  let v = stalk(s, t, 88, st.seed, st.phase);
  const fromTop = top - s;
  if (fromTop < 3.2) v = 0.98;                       // bright cut rim
  else if (fromTop < 11) v *= 0.45 + 0.04 * fromTop; // hollow cut face
  if (s - bottom < 3) v *= 0.4;
  v *= st.shade || 1; // back stalks a little darker: depth
  return v;
}

function leafSample(leaf, x, y) {
  const stalkB = STALKS[2];
  const base = [C[0] + D[0] * leaf.at + N[0] * stalkB.o, C[1] + D[1] * leaf.at + N[1] * stalkB.o];
  const dir = rot(D, -leaf.angle);
  const perp = [-dir[1], dir[0]];
  const rx = x - base[0]; const ry = y - base[1];
  const u = (rx * dir[0] + ry * dir[1]) / leaf.len;
  if (u < 0 || u > 1) return null;
  const bend = 0.14 * leaf.len * u * u;
  const across = rx * perp[0] + ry * perp[1] - bend;
  const half = leaf.wid * Math.pow(Math.sin(Math.PI * Math.min(1, u * 1.05)), 0.75) * (1 - 0.35 * u);
  if (Math.abs(across) > half || half <= 0) return null;
  const tt = across / half;
  let v = 0.6 + 0.3 * (1 - Math.abs(tt)) + 0.12 * u;
  v -= 0.35 * g(tt, 0.08);                          // midrib
  if (Math.abs(tt) > 0.86) v *= 0.35;               // edge
  return clamp(v);
}

function bundleSample(x, y) {
  const [s, o] = local(x, y);
  let value = null;
  for (const st of STALKS) {
    const v = stalkSample(st, s, o);
    if (v !== null) value = v;                      // later (front) stalks cover earlier ones
  }
  for (const leaf of LEAVES) {
    const v = leafSample(leaf, x, y);
    if (v !== null) value = v;
  }
  return value === null ? null : [value, 1];
}

function tieSample(x, y) {
  const [s, o] = local(x, y);
  const centre = TIE.s + 7 * Math.pow(o / TIE.half, 2);
  const across = (s - centre) / (TIE.width / 2);
  if (Math.abs(o) <= TIE.half && Math.abs(across) <= 1) {
    const round = Math.sqrt(1 - across * across);
    let v = 0.45 + 0.45 * round + 0.2 * g(across + 0.35, 0.18);
    const wrap = (((o * 0.55 + (s - centre) * 1.1) % 21) + 21) % 21;
    v -= 0.42 * g(wrap - 10.5, 1.6);                // cord wraps
    if (Math.abs(across) > 0.84) v *= 0.3;
    return [clamp(v), 1];
  }
  // knot and two tails on the right
  const kx = C[0] + N[0] * (TIE.half + 6) + D[0] * TIE.s; const ky = C[1] + N[1] * (TIE.half + 6) + D[1] * TIE.s;
  const dk = Math.hypot(x - kx, y - ky);
  if (dk < 15) return [clamp(0.5 + 0.45 * Math.sqrt(1 - (dk / 15) ** 2) - (dk > 12.5 ? 0.35 : 0)), 1];
  for (const tail of [{ dir: [0.18, 1], len: 64, w: 7 }, { dir: [0.55, 0.84], len: 48, w: 6 }]) {
    const l = Math.hypot(tail.dir[0], tail.dir[1]); const d0 = [tail.dir[0] / l, tail.dir[1] / l];
    const rx = x - kx; const ry = y - ky;
    const u = (rx * d0[0] + ry * d0[1]) / tail.len;
    if (u < 0.15 || u > 1) continue;
    const across2 = rx * -d0[1] + ry * d0[0];
    const half = tail.w * (1 - 0.55 * u);
    if (Math.abs(across2) <= half) {
      const tt = across2 / half;
      let v = 0.5 + 0.4 * Math.sqrt(Math.max(0, 1 - tt * tt));
      if (Math.abs(tt) > 0.8) v *= 0.35;
      return [clamp(v), 1];
    }
  }
  return null;
}

// ---- frame band (nine-slice) -------------------------------------------------
function roundedRectDistance(x, y, x0, y0, x1, y1, r) {
  const cx = Math.max(x0 + r, Math.min(x, x1 - r));
  const cy = Math.max(y0 + r, Math.min(y, y1 - r));
  const inside = x >= x0 && x <= x1 && y >= y0 && y <= y1;
  const d = Math.hypot(x - cx, y - cy) - r;
  return inside ? d : Math.max(d, 0.0001); // negative inside
}
// 0.5.0: half the visible thickness of 0.4.0 and almost no outer margin, so the
// ring edge sits where the frame edge is (flush with the bottom panel).
// In a corner piece (64 px): ring from 2 px to 22 px, outer radius 24 px.
const BAND = { outer: 2, thickness: 20, radius: 24, innerRadius: 6 };
function bandSample(x, y) {
  const S = 256;
  const o = BAND.outer; const i = BAND.outer + BAND.thickness;
  const outer = roundedRectDistance(x, y, o, o, S - o, S - o, BAND.radius);
  const inner = roundedRectDistance(x, y, i, i, S - i, S - i, BAND.innerRadius);
  if (outer > 0 || inner < 0) return null;
  const thickness = BAND.thickness;
  const t = clamp(-outer / thickness) * 2 - 1; // -1 outer edge .. 1 inner edge
  const round = Math.sqrt(Math.max(0, 1 - t * t));
  let v = 0.55 + 0.38 * Math.pow(round, 0.6);
  v += 0.22 * g(t + 0.35, 0.16);                    // bevel highlight
  v += 0.10 * g(t - 0.72, 0.06);                    // inner rim line
  if (Math.abs(t) > 0.86) v *= Math.max(0.15, 1 - (Math.abs(t) - 0.86) * 5.5);
  return [clamp(v), 1];
}

// Smooth health / status bar: one continuous surface (no slots, no cuts),
// nearly white so the class / reaction gradient stays vibrant; a soft gloss
// band near the top and a gentle fall-off toward the bottom.
function barSample(x, y) {
  const h = 64;
  const t = y / h;
  let v = 1 - 0.17 * t;
  v += 0.08 * g(t - 0.2, 0.09);
  v -= 0.12 * g(t - 1, 0.1);
  if (y < 1.5) v = 1;
  return [clamp(v), 1];
}

// ---- action buttons ---------------------------------------------------------
// Perfect circles (0.5.0 correction): a circular icon mask, a thick crisp ring
// (24 % of the radius: well over twice the rejected 8.5 % rim) with thin dark
// edge lines for contrast, and soft halos for the proc state (round for the
// circular buttons, rounded-square for buttons that stay square).
//
// 0.7.0: drawn for the screen pixels they cover. Until 0.6.0 the ring and the
// mask were 256 px textures the game shrank to the ~40 px a button covers at
// Darren's 2560 x 1440 and UI scale 0.71 (30 units x 0.71 x 1440 / 768 = 39.9
// px). The game samples an addon's TGA bilinearly, without mip levels, unless
// asked otherwise: a 6.4x shrink reads 4 of the ~41 texels under each screen
// pixel, so the edges came out stair-stepped and the thin dark edge lines
// broke up. Now every circle is rendered at the size it is shown at: a 64 px
// canvas holds the circle of a 40 px button, centred, and each texel is the
// exact coverage of one screen pixel (16 x 16 samples of the analytic shape:
// a 1024 px master box-filtered down). BushidoPrivateCompat sizes the canvas
// so one texel lands on one screen pixel. A 128 px set holds an 80 px button
// (larger buttons / 4K). The shape constants are the 0.5.x ones.
const RING = { outer: 0.98, inner: 0.74, line: 0.02 };
const MASK_RADIUS = 0.9; // icon edge tucked under the ring
const radius = (x, y, size) => Math.hypot((x / size) * 2 - 1, (y / size) * 2 - 1);
// the circle sets: canvas px, button px it is drawn for
const BUTTON_SETS = [{ suffix: '', canvas: 64, design: 40 }, { suffix: '128', canvas: 128, design: 80 }];
// identity circles on the secondary unit frames: a 36 px circle on a 64 px canvas, thin ring
const IDENTITY = { canvas: 64, design: 36, outer: 0.98, inner: 0.82, line: 0.06, mask: 0.86 };
const SS_EXACT = 16;

// Renders fn(x, y) -> [value, coverage] with ss x ss samples per pixel (no outline):
// each pixel holds the exact area the shape covers in it.
function renderExact(w, h, fn, ss = SS_EXACT) {
  const px = Buffer.alloc(w * h * 4);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    let sv = 0; let sc = 0;
    for (let j = 0; j < ss; j++) for (let i = 0; i < ss; i++) {
      const r = fn(x + (i + 0.5) / ss, y + (j + 0.5) / ss);
      if (r) { sv += r[0] * r[1]; sc += r[1]; }
    }
    const a = sc / (ss * ss);
    const v = sc > 0 ? sv / sc : 0;
    const o = (y * w + x) * 4;
    const c = Math.round(clamp(v) * 255);
    px[o] = c; px[o + 1] = c; px[o + 2] = c; px[o + 3] = Math.round(clamp(a) * 255);
  }
  return px;
}

// ring of radius R px around (cx, cy), the 0.5.x proportions
function ringAt(cx, cy, R, shape = RING) {
  return (x, y) => {
    const r = Math.hypot(x - cx, y - cy) / R;
    if (r > shape.outer || r < shape.inner - shape.line) return null;
    if (r < shape.inner) return [0, 0.55];                    // dark inner edge line
    if (r > shape.outer - shape.line) return [0, 0.6];         // dark outer edge line
    const t = (r - shape.inner) / (shape.outer - shape.inner); // 0 inner .. 1 outer
    return [clamp(0.9 + 0.1 * g(t - 0.4, 0.35)), 1];           // nearly flat: the gradient stays saturated
  };
}
function discAt(cx, cy, R) {
  return (x, y) => (Math.hypot(x - cx, y - cy) <= R ? [1, 1] : null);
}
// 0.5.x (256 px, shown 6.4x smaller): kept for the offline comparison only
function circleSample(x, y) {
  return radius(x, y, 256) <= MASK_RADIUS ? [1, 1] : null;
}
function ringSample(x, y) {
  return ringAt(128, 128, 128)(x, y);
}
function glowSample(x, y) {
  const r = radius(x, y, 256);
  if (r >= 1) return null;
  const a = Math.exp(-Math.pow((r - 0.66) / 0.13, 2));
  return a > 0.004 ? [1, a] : null;
}
function glowSquareSample(x, y) {
  const S = 256; const half = S / 2; const inner = half / 1.5;  // the button covers the middle 2/3
  const d = roundedRectDistance(x, y, half - inner, half - inner, half + inner, half + inner, 10) / half;
  const a = Math.exp(-Math.pow((d - 0.04) / 0.1, 2));
  return a > 0.004 ? [1, a] : null;
}
BAND.ring = RING;

// ---- minimap mask (0.6.0) ----------------------------------------------------
// The map square clipped to the same parallelogram as the Banzai minimap frame:
// top edge shifted right, both sides leaning MINIMAP_LEAN degrees, top and
// bottom level. White and opaque inside, transparent outside.
const MINIMAP_LEAN = 7;
function minimapMaskSample(x, y) {
  const S = 256;
  const s = Math.tan((MINIMAP_LEAN * Math.PI) / 180) * S;
  const left = s * (1 - y / S);
  return x >= left && x <= left + S - s ? [1, 1] : null;
}

// ---- 1.2.0 BANZAI SQUARE action buttons ---------------------------------------
// The spell picture is the priority: the icon stays square and keeps nearly all
// of its area; only its corners are cut by a small 45-degree chamfer. The border
// is thin and sits half outside the button (in the spacing between buttons), so
// it hides only the icon's outermost pixel, never its picture.
// ElvUI sizes buttons in whole screen pixels (E:Scale: Darren's 30 units at UI
// scale 0.71 on 1440 lines = 39 px, not 39.9), so the border is drawn for each
// whole-pixel width a Banzai button can have (34 .. 42 px: sizes 26 .. 32 at
// Darren's scale), one 64 px canvas each, the button at texels [off, off + p)
// with off = floor((64 - p) / 2): Banzai Art lays the canvas 64 screen pixels
// wide with that offset, so every texel is one screen pixel and every straight
// edge of the border lies on a pixel boundary. Other widths take an 80 px
// drawing on a 128 px canvas, scaled (trilinear). In button pixels from the
// button's edge:
//   outer   2    the border's outer edge (in the spacing between buttons)
//   line    1    a dark line on that edge (definition on bright scenery)
//   inner   2    the border's inner edge inside the button (ElvUI's icon starts
//                1 px inside, so 1 px of it lies under the border)
//   cut     5    the chamfer on the outer edge; every inner outline is the same
//                outline offset inwards, so the chamfer stays parallel
// The icon mask and the cooldown swipe are stretched over the button / the icon
// (their edges lie under the opaque border, so their scaling never shows).
const SQUARE = { outer: 2, line: 1, inner: 2, cut: 5, lineAlpha: 0.65, value: 0.95, sizes: [34, 35, 36, 37, 38, 39, 40, 41, 42], canvas: 64 };
// the chamfered outline offset `t` px inwards from the border's outer outline of a box [x0, x1] x [y0, y1] (px)
function chamferInside(x, y, x0, y0, x1, y1, t, s = 1) {
  const o = SQUARE.outer * s;
  const ax0 = x0 - o + t; const ax1 = x1 + o - t; const ay0 = y0 - o + t; const ay1 = y1 + o - t;
  if (x < ax0 || x > ax1 || y < ay0 || y > ay1) return false;
  const k = SQUARE.cut * s + Math.SQRT2 * t - 2 * t; // the corner cut along each axis at this offset (parallel chamfer)
  const dx = Math.min(x - ax0, ax1 - x); const dy = Math.min(y - ay0, ay1 - y);
  return dx + dy >= k;
}
function squareBorderFor(x0, y0, x1, y1, s) {
  const o = SQUARE.outer * s; const i = SQUARE.inner * s; const l = SQUARE.line * s;
  return (x, y) => {
    if (!chamferInside(x, y, x0, y0, x1, y1, 0, s)) return null;
    if (chamferInside(x, y, x0, y0, x1, y1, o + i, s)) return null; // the picture
    if (!chamferInside(x, y, x0, y0, x1, y1, l, s)) return [0, SQUARE.lineAlpha]; // dark outer line
    return [SQUARE.value, 1]; // nearly flat: the gradient stays saturated
  };
}
// mask over the button (the texture stretched to the button): its edge 1.5 px inside a 39 px button, under the border
const SQUARE_MASK = { edge: 1.5 / 19.5, design: 39 };
function squareMaskSample(size) {
  const p = SQUARE_MASK.design; const k = size / p; // texels per button pixel
  return (x, y) => (chamferInside(x / k, y / k, 0, 0, p, p, SQUARE.outer + 1.5) ? [1, 1] : null);
}
// cooldown swipe over the icon frame (LibActionButton anchors every cooldown to the icon, 1 px inside the
// button): ends 0.3 px inside the border's inner edge, so the swipe never darkens the border
function squareSwipeSample(size) {
  const p = SQUARE_MASK.design - 2; const k = size / p; // the 37 px icon of a 39 px button
  return (x, y) => (chamferInside(x / k + 1, y / k + 1, 0, 0, SQUARE_MASK.design, SQUARE_MASK.design, SQUARE.outer + SQUARE.inner + 0.3) ? [1, 1] : null);
}
// proc halo: a soft band hugging the chamfered outline (the button covers the middle 2/3)
function squareGlowSample(x, y) {
  const S = 256; const btn = S / 3; // button half size
  const k = btn / 20; // canvas px per button px (a 40 px button)
  const half = (20 + SQUARE.outer) * k; const line = (2 * (20 + SQUARE.outer) - SQUARE.cut) * k;
  const ax = Math.abs(x - S / 2); const ay = Math.abs(y - S / 2);
  const d = Math.max(ax - half, ay - half, (ax + ay - line) / Math.SQRT2) / btn; // signed distance to the outline, in button halves
  const a = Math.exp(-Math.pow((d - 0.05) / 0.11, 2));
  return a > 0.004 ? [1, a] : null;
}
function squareSets() {
  const out = {};
  const C = SQUARE.canvas;
  for (const p of SQUARE.sizes) {
    const off = Math.floor((C - p) / 2);
    out['BanzaiSquareBorder' + p] = { w: C, h: C, px: renderExact(C, C, squareBorderFor(off, off, off + p, off + p, 1)) };
  }
  out.BanzaiSquareBorder128 = { w: 128, h: 128, px: renderExact(128, 128, squareBorderFor(24, 24, 104, 104, 2)) }; // 80 px button, scaled
  out.BanzaiSquareMask = { w: C, h: C, px: renderExact(C, C, squareMaskSample(C)) };
  out.BanzaiSquareSwipe = { w: C, h: C, px: renderExact(C, C, squareSwipeSample(C)) };
  out.BanzaiSquareGlow = { w: 256, h: 256, px: render(256, 256, squareGlowSample, 0) };
  return out;
}

// the pixel-exact circle textures (0.7.0)
function circleSets() {
  const out = {};
  for (const set of BUTTON_SETS) {
    const c = set.canvas / 2; const R = set.design / 2;
    // ring and icon mask on the canvas (shown one texel per screen pixel)
    out['BanzaiButtonRing' + set.suffix] = { w: set.canvas, h: set.canvas, px: renderExact(set.canvas, set.canvas, ringAt(c, c, R)) };
    out['BanzaiButtonMask' + set.suffix] = { w: set.canvas, h: set.canvas, px: renderExact(set.canvas, set.canvas, discAt(c, c, MASK_RADIUS * R)) };
  }
  // cooldown swipe: the game stretches it over the button itself, so it fills its canvas
  const s = BUTTON_SETS[0].canvas;
  out.BanzaiButtonCircle = { w: s, h: s, px: renderExact(s, s, discAt(s / 2, s / 2, MASK_RADIUS * s / 2)) };
  const ic = IDENTITY.canvas / 2; const iR = IDENTITY.design / 2;
  out.BanzaiIdentityRing = { w: IDENTITY.canvas, h: IDENTITY.canvas, px: renderExact(IDENTITY.canvas, IDENTITY.canvas, ringAt(ic, ic, iR, IDENTITY)) };
  out.BanzaiIdentityMask = { w: IDENTITY.canvas, h: IDENTITY.canvas, px: renderExact(IDENTITY.canvas, IDENTITY.canvas, discAt(ic, ic, IDENTITY.mask * iR)) };
  return out;
}

function generate() {
  return {
    BanzaiBundle: { w: 512, h: 512, px: render(512, 512, bundleSample, 4) },
    BanzaiBundleTie: { w: 512, h: 512, px: render(512, 512, tieSample, 3) },
    BanzaiBar: { w: 256, h: 64, px: render(256, 64, barSample, 0) },
    ...circleSets(),
    ...squareSets(),
    BanzaiButtonGlow: { w: 256, h: 256, px: render(256, 256, glowSample, 0) },
    BanzaiButtonGlowSquare: { w: 256, h: 256, px: render(256, 256, glowSquareSample, 0) },
  };
}

// the 0.5.x / 0.6.0 256 px ring and mask (offline comparison in tools/ringcheck.js)
function legacyCircles() {
  return {
    ring: { w: 256, h: 256, px: render(256, 256, ringSample, 0) },
    mask: { w: 256, h: 256, px: render(256, 256, circleSample, 0) },
  };
}

module.exports = { generate, stalk, BAND, MINIMAP_LEAN, RING, MASK_RADIUS, BUTTON_SETS, IDENTITY, SQUARE, SQUARE_MASK, chamferInside, ringAt, discAt, render, renderExact, legacyCircles, hash, noise, g, clamp };
