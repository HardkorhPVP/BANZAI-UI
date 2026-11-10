// BANZAI 1.1.0 panel material: original bamboo frame and parchment assets for
// the chat, Details and minimap panels, generated procedurally (no third-party
// artwork is read, copied or traced; Darren's reference images are looked at
// by eye only and never enter the build). Greyscale with alpha, so the in-game
// gradients colour the stalks per border style (CLASS / BANZAI / HARDKORH)
// and the rope independently; the parchment is full colour.
//
//   BanzaiStalk      1024x128  one straight bamboo stalk, horizontal, tileable
//                              along its length: four node periods of 256 px,
//                              each a little different (node groove, swelling,
//                              a gentle wobble of the axis), diameter 88 px
//   BanzaiStalkEnd   512x128   the two stalk ends: a diagonal cut tip with its
//                              hollow face (left half) and a plain node end
//                              with a rounded cap (right half); the body runs
//                              in from the left of each half
//   BanzaiRopeTie    256x256   the lashing over a corner crossing: two cord
//                              bands crossing (three strands each, twist
//                              grooves), a knot and two short tails, a soft
//                              shadow where the cord lies on the stalks
//   1.3.7 HARDKORH PARCHMENT, one material that is never stretched (the
//   1.1.0 - 1.3.6 BanzaiParchment sheet was stretched to every panel's shape;
//   its generator stays below as legacyParchment for the before / after sheet
//   and the class-art QA backdrop, and is no longer built):
//   BanzaiParchmentTile     1024x512  the paper body: warm cream, restrained tan
//                              blotches, faint fibre and strands, seamless in both
//                              directions (every noise octave periodic over the
//                              tile), drawn at PARCHMENT.density texels per UI
//                              unit on every panel
//   BanzaiParchmentEdge     512x256   the worn edge, four strips of 64 px (top,
//                              right, bottom, left, alternately turned so that
//                              neighbouring strips meet on equal texels): black
//                              with alpha - the darkening toward the edge, the
//                              burnt rim and the torn line over the body; each
//                              strip periodic along its 512 px
//   BanzaiParchmentCorners  128x128   the four corners (64 px each, with their
//                              nibbles), continuous with the strips where they
//                              start, so no corner meets its edges on a step
//
// The geometry (PANEL) is shared by Compat.lua (Compat.PANEL) and the offline
// preview (tools/panelcheck.js): every size is a multiple of the stalk
// diameter d, so one border scale moves everything together.
'use strict';

const { render, noise, g, clamp } = require('./bamboo');

const PANEL = {
  stalk: 10,        // stalk diameter at border scale 1 (UI units): the 0.5.0 content inset (10.5) minus the outer margin
  outer: 0.5,       // the stalk's outer edge sits this far inside the holder rectangle
  ext: 1.0,         // how far the stalks run past the corner crossing beyond the holder (x d)
  extBottom: 0,     // the chat / Details side stalks end on the bottom panel's top line (anything lower would sit behind the panel's glass)
  period: 3.6,      // node spacing along a stalk (x d)
  tie: 2.6,         // the rope tie square over each crossing (x d)
  parchment: 0.55,  // the parchment rectangle is inset outer + this x d from the holder (its torn edge then wanders under the stalk and just past it)
  parchmentCorner: 2.4, // nine-slice corner (x d) = 96 px of 512
  texD: 88,         // stalk diameter in the textures (px)
  texH: 128,        // texture strip height (px): a piece is texH / texD x d tall
  tipPx: 256,       // one tip piece (px) in BanzaiStalkEnd = tipPx / texD x d long
  periodPx: 256,    // one node period (px) in BanzaiStalk
  periods: 4,
  tipGap: 6,        // transparent px between the two halves of BanzaiStalkEnd, so neither half's outline bleeds into the other's piece
};

// ---- stalk ------------------------------------------------------------------
const R = PANEL.texD / 2;
const CY = PANEL.texH / 2;
// the four periods: axis wobble (px, a half sine over the period: zero at both ends so the tiles join),
// node groove depth, swelling, the seed of the fine streaks
const PERIODS = [
  { wob: 1.3, groove: 1.0, swell: 1.0, seed: 11 },
  { wob: -0.9, groove: 0.85, swell: 1.12, seed: 23 },
  { wob: 0.7, groove: 1.1, swell: 0.92, seed: 37 },
  { wob: -1.4, groove: 0.95, swell: 1.05, seed: 51 },
];
const P = PANEL.periodPx;

// radius of the stalk at u px from the node (swelling at the node, a slight waist between nodes)
function radiusAt(d, p, waistAt) {
  let r = 1 + 0.11 * p.swell * g(d, 14);
  if (waistAt !== undefined) r -= 0.022 * g(d - waistAt, 60);
  return R * r;
}

// shade of the stalk surface: t -1 (top) .. 1 (bottom) across, d px from the node
function shade(d, t, p, u) {
  const at = Math.min(1, Math.abs(t));
  const round = Math.sqrt(Math.max(0, 1 - at * at));
  let v = 0.34 + 0.58 * Math.pow(round, 0.65);
  v += 0.20 * g(t + 0.38, 0.17);                    // soft highlight along the upper part
  v += 0.05 * g(t - 0.45, 0.12);                    // faint rim light underneath
  if (at > 0.86) v *= Math.max(0.18, 1 - (at - 0.86) * 5.5); // darker toward the silhouette
  v -= 0.55 * p.groove * g(d + 9, 2.8) * (0.5 + 0.5 * round); // groove before the node ring
  v -= 0.30 * p.groove * g(d - 10, 2.2) * (0.5 + 0.5 * round); // lighter groove after it
  v += 0.16 * g(d, 6) * round;                      // the raised ring between
  v += 0.04 * g(d, 18);
  v += 0.035 * (noise(u / 55 + p.seed, t * 7) - 0.5) + 0.02 * (noise(u / 8 + p.seed * 2, t * 24) - 0.5); // fine lengthwise streaks
  return clamp(v);
}

function stalkSample(x, y) {
  const period = Math.min(PANEL.periods - 1, Math.floor(x / P));
  const p = PERIODS[period];
  const u = x - period * P;
  const cy = CY + p.wob * Math.sin((2 * Math.PI * u) / P);
  const d = u - P / 2;
  const r = radiusAt(d, p, -P / 2) ; // the waist at the period boundary (u = 0 / 256)
  const r2 = r - 0.022 * R * g(u - P, 60); // and at the other boundary
  const t = (y - cy) / Math.min(r, r2);
  if (Math.abs(t) > 1) return null;
  return [shade(d, t, p, u), 1];
}

// ---- ends -------------------------------------------------------------------
// left half: body from the left, a diagonal cut (the plane leans back from the
// bottom at 165 px to the top at 235 px) with the hollow face beyond it;
// right half: body with a node at 196 px and a rounded cap ending at 215 px
const CUT = { u: 200, lean: 35, wall: 0.8 };
const CAP = { node: 196, end: 215, round: 9 };

function tipSample(x, y) {
  const half = x < PANEL.tipPx ? 0 : 1;
  const u = x - half * PANEL.tipPx;
  const p = PERIODS[half === 0 ? 2 : 1];
  if (half === 0 ? u > PANEL.tipPx - PANEL.tipGap : u < PANEL.tipGap) return null;
  if (half === 0) {
    const d = u - 100; // one node well before the cut
    const r = radiusAt(d, p);
    const t = (y - CY) / r;
    const te = (y - CY) / R; // the ellipse of the cut face on the true radius
    const line = CUT.u - CUT.lean * te;
    if (u <= line) {
      if (Math.abs(t) > 1) return null;
      let v = shade(d, t, p, u);
      if (line - u < 4) v = Math.min(1, v + 0.25); // bright rim where the body meets the cut
      return [v, 1];
    }
    const e = Math.pow((u - CUT.u) / CUT.lean, 2) + te * te;
    if (e > 1) return null;
    const inner = Math.pow((u - CUT.u) / (CUT.lean * CUT.wall), 2) + Math.pow(te / CUT.wall, 2);
    if (inner <= 1) { // hollow: dark, a little lighter toward the bottom where light enters
      return [clamp(0.12 + 0.12 * (te + 1) / 2 + 0.06 * (1 - inner)), 1];
    }
    return [clamp(0.95 - 0.30 * (te + 1) / 2), 1]; // the cut wall: bright at the top, shaded below
  }
  const d = u - CAP.node;
  if (u > CAP.end) return null;
  let r = radiusAt(d, p);
  if (u > CAP.end - CAP.round) r *= Math.sqrt(Math.max(0, 1 - Math.pow((u - (CAP.end - CAP.round)) / CAP.round, 2)));
  const t = (y - CY) / Math.max(r, 0.001);
  if (Math.abs(t) > 1) return null;
  let v = shade(d, t, p, u);
  if (u > CAP.end - CAP.round) v *= 0.55 + 0.45 * (1 - (u - (CAP.end - CAP.round)) / CAP.round); // the cap turns away from the light
  return [v, 1];
}

// ---- rope tie ---------------------------------------------------------------
// canvas 256 px = 2.6 d: the crossing square is the middle 98 px, the two cord
// bands run corner to corner across it and fade where they pass behind the
// stalks; the knot sits low right, its two tails hang down
const TIE = { d: 256 / PANEL.tie, band: 66, strands: 2, reach: 1.42, fade: 10, knot: { x: 18, y: 22, r: 14 } };
const DIAG = [[Math.SQRT1_2, Math.SQRT1_2], [Math.SQRT1_2, -Math.SQRT1_2]];

function cordAlong(along, across, width, k) {
  // across -1..1 over the band: three round strands with dark seams and twist grooves
  const s = (across + 1) / 2 * TIE.strands;
  const strand = Math.min(TIE.strands - 1, Math.floor(s));
  const sk = (s - strand) * 2 - 1;
  let v = 0.46 + 0.50 * Math.sqrt(Math.max(0, 1 - sk * sk));
  if (Math.abs(sk) > 0.84) v *= 0.38;
  const twist = ((((along * 0.95 + strand * 7 + k * 7) % 14) + 14) % 14);
  v -= 0.30 * g(twist - 7, 1.7);
  v += 0.06 * g(across + 0.3, 0.3); // light from the upper left
  return clamp(v);
}

function tieSample(x, y) {
  const cx = x - 128; const cy = y - 128;
  const half = TIE.d / 2;
  const reach = half * TIE.reach; // past the corners of the crossing square
  let best = null; let shadow = false;
  for (let k = 0; k < 2; k++) {
    const [dx, dy] = DIAG[k];
    const along = cx * dx + cy * dy;
    const across = -cx * dy + cy * dx;
    const w = TIE.band / 2;
    if (Math.abs(along) > reach + TIE.fade) continue;
    if (Math.abs(across) <= w) {
      const a = clamp((reach - Math.abs(along)) / TIE.fade + 0.5);
      if (a > 0) best = [cordAlong(along, across / w, w, k), a]; // the second band lies over the first
    } else if (Math.abs(across) <= w + 5 && Math.abs(along) <= reach - 4 && Math.abs(cx) <= half + 4 && Math.abs(cy) <= half + 4) {
      shadow = true;
    }
  }
  // knot and tails on top of everything
  const kx = cx - TIE.knot.x; const ky = cy - TIE.knot.y;
  const dk = Math.hypot(kx, ky);
  if (dk <= TIE.knot.r) {
    let v = 0.48 + 0.47 * Math.sqrt(1 - Math.pow(dk / TIE.knot.r, 2));
    v -= 0.18 * g(Math.hypot(kx + 3, ky - 2) - 6, 1.6); // the loop of the knot
    if (dk > TIE.knot.r - 2.2) v *= 0.4;
    return [clamp(v), 1];
  }
  for (const tail of [{ dir: [0.16, 1], len: 46, w: 6.5, k: 0 }, { dir: [0.62, 0.78], len: 38, w: 5.5, k: 1 }]) {
    const l = Math.hypot(tail.dir[0], tail.dir[1]); const d0 = [tail.dir[0] / l, tail.dir[1] / l];
    const u = (kx * d0[0] + ky * d0[1]) / tail.len;
    if (u < 0.2 || u > 1) continue;
    const across = kx * -d0[1] + ky * d0[0];
    const hw = tail.w * (1 - 0.5 * u);
    if (Math.abs(across) <= hw) {
      const tt = across / hw;
      let v = 0.42 + 0.48 * Math.sqrt(Math.max(0, 1 - tt * tt));
      const twist = ((((u * tail.len * 1.1 + tail.k * 5) % 9) + 9) % 9);
      v -= 0.2 * g(twist - 4.5, 1.2);
      if (Math.abs(tt) > 0.8) v *= 0.4;
      return [clamp(v), 1];
    }
  }
  if (best) return best;
  if (shadow) return [0, 0.22];
  return null;
}

// ---- parchment, 1.1.0 - 1.3.6 (legacy: not built since 1.3.7) -----------------
// One 512 px sheet, drawn as a nine-slice whose middle and edge strips took each panel's shape: on the wide
// Details / chat frames the grain ran 4 - 5 times longer across than down, on BUFFS 8 times. Kept for the
// before / after sheet (tools/panelcheck.js), the historical record (tools/validate.js block 17) and the
// class-art QA backdrop (tools/lib/iconqa.js); its colours are the approved paper the 1.3.7 tile keeps.
const PARCH = { size: 512, inset: 14, amp: 9, corner: 96, cream: [0.91, 0.83, 0.65], tan: [0.73, 0.59, 0.40], lift: 1.1 };

function legacyParchment() {
  const S = PARCH.size;
  const px = Buffer.alloc(S * S * 4);
  const SS = 3;
  // the torn edge: periodic over the 320 px between the corners, so the edge strips of the nine-slice
  // tile it without a step and meet the corners exactly
  const span = S - 2 * PARCH.corner;
  const wobble = (along, seed) => PARCH.amp * (0.6 * Math.sin((2 * Math.PI * 3 * along) / span + seed) + 0.3 * Math.sin((2 * Math.PI * 7 * along) / span + seed * 2.3) + 0.18 * Math.sin((2 * Math.PI * 11 * along) / span + seed * 1.7)); // gentle: a worn edge, not a sawtooth
  const inside = (x, y) => {
    const dl = x - PARCH.inset + wobble(y - PARCH.corner, 3);
    const dr = S - PARCH.inset - x + wobble(y - PARCH.corner, 17);
    const dt = y - PARCH.inset + wobble(x - PARCH.corner, 29);
    const db = S - PARCH.inset - y + wobble(x - PARCH.corner, 41);
    let d = Math.min(dl, dr, dt, db);
    // the corners are nibbled a little rounder than the sides
    const cxd = Math.min(x, S - x); const cyd = Math.min(y, S - y);
    if (cxd < 40 && cyd < 40) d -= 10 * g(Math.hypot(cxd, cyd), 22) * (1 - Math.min(cxd, cyd) / 40);
    return d;
  };
  for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
    let cover = 0; let dSum = 0;
    for (let j = 0; j < SS; j++) for (let i = 0; i < SS; i++) {
      const d = inside(x + (i + 0.5) / SS, y + (j + 0.5) / SS);
      if (d > 0) { cover++; dSum += d; }
    }
    const o = (y * S + x) * 4;
    if (cover === 0) continue;
    const a = cover / (SS * SS);
    const d = dSum / cover;
    // paper: fibre at three scales, faint directional strands, a few soft blotches toward tan
    const fibre = (noise(x / 3.1, y / 3.3) - 0.5) * 0.5 + (noise(x / 11 + 5, y / 13 + 2) - 0.5) * 0.3 + (noise(x / 47 + 9, y / 43 + 4) - 0.5) * 0.2;
    const strand = (noise(x / 70 + 21, y / 2.6 + 8) - 0.5) * 0.05;
    const blot = clamp((noise(x / 90 + 33, y / 85 + 12) - 0.5) * 3.2);
    const k = 1 + 0.07 * fibre + strand * 0.6;
    let c = PARCH.cream.map((v, i) => (v + (PARCH.tan[i] - v) * 0.28 * blot) * k);
    // darker toward the edge, a thin burnt rim at the torn edge
    const edge = 1 - 0.20 * (1 - clamp(d / 44));
    const rim = 0.72 + 0.28 * clamp(d / 4);
    c = c.map((v) => clamp(v * edge * rim * PARCH.lift));
    px[o] = Math.round(c[0] * 255); px[o + 1] = Math.round(c[1] * 255); px[o + 2] = Math.round(c[2] * 255); px[o + 3] = Math.round(a * 255);
  }
  return { w: S, h: S, px };
}

// ---- parchment, 1.3.7: one material, never stretched ---------------------------
// The same numbers as Compat.PARCHMENT (tools/validate.js compares them):
//   tileW x tileH  the body tile (texels), drawn at `density` texels per UI unit on every panel and both axes: the
//                  grain has one size everywhere and a larger panel shows more paper, never larger paper (512 x 256
//                  units: wider than any Banzai panel, so none shows the same patch twice)
//   edgeW x edgeH  the edge strips: four rows of `edgeH / 4`, each one band thick (PANEL.parchmentCorner x the stalk)
//                  and `period` bands long, repeated along its edge
//   corners        the corner atlas: four corners of one band each
//   phase          where each panel starts in the tile (fractions of it): fixed, so the chat and Details - the same size
//                  - are different pieces of the same paper
const PARCHMENT = { tileW: 1024, tileH: 512, density: 2, edgeW: 512, edgeH: 256, corners: 128, period: 8,
  phase: { chat: [0, 0], details: [0.46, 0.38], buffs: [0.23, 0.71] } };
// The worn edge in stalk diameters (d) from the parchment rectangle's side (the 1.1.0 look: the torn line 0.35 d in,
// wandering about 0.25 d, a burnt rim 0.1 d wide to 72 %, the paper 20 % darker toward the edge over 1.1 d); outside the
// torn line the paper is darkened to `outside` (a scorched margin under the stalk) instead of cut away, so the
// material is opaque everywhere. Harmonics: whole cycles per strip period (so the strip repeats without a step),
// the 1.1.0 wavelengths (2.7 d, 1.1 d, 0.7 d) and two irregular ones; seeds per side as in 1.1.0.
const WEAR = { tear: 0.35, amp: 0.19, rim: 0.1, rimDark: 0.72, fade: 1.1, fadeDark: 0.2, outside: 0.3, nibble: 0.25, nibbleR: 0.55, nibbleIn: 1,
  harmonics: [[3, 0.18, 1], [7, 0.5, 2.3], [11, 0.2, 1.7], [17, 0.28, 3.1], [26, 0.16, 0.7]],
  seeds: { top: 29, right: 17, bottom: 41, left: 3 }, corner: { TOPLEFT: 1, TOPRIGHT: 0.8, BOTTOMLEFT: 1.15, BOTTOMRIGHT: 0.9 } };
const BLOT = { offset: 0.17, gain: 0.45 }; // the blotch field (deviation 1) -> 0..1 of the way to tan (x 0.28, as in 1.1.0)
const BAND = PARCHMENT.edgeH / 4;        // texels across one band (= PANEL.parchmentCorner x d)
const DT = BAND / PANEL.parchmentCorner; // texels per stalk diameter in the edge and corner textures
const PERIOD = PARCHMENT.edgeW;          // one strip period (texels)

// periodic value noise: an nx x ny lattice over the tile, wrapped (the tile's two sides are neighbours)
function hash3(x, y, seed) {
  let h = (x * 374761393 + y * 668265263 + seed * 1442695041) | 0;
  h = Math.imul(h ^ (h >>> 13), 1274126177);
  return ((h ^ (h >>> 16)) >>> 0) / 4294967295;
}
function noiseP(u, v, nx, ny, seed) {
  const xi = Math.floor(u); const yi = Math.floor(v);
  const xf = u - xi; const yf = v - yi;
  const sx = xf * xf * (3 - 2 * xf); const sy = yf * yf * (3 - 2 * yf);
  const x0 = ((xi % nx) + nx) % nx; const x1 = (x0 + 1) % nx; const y0 = ((yi % ny) + ny) % ny; const y1 = (y0 + 1) % ny;
  const a = hash3(x0, y0, seed); const b = hash3(x1, y0, seed); const c = hash3(x0, y1, seed); const d = hash3(x1, y1, seed);
  return a + (b - a) * sx + (c - a) * sy + (a - b - c + d) * sx * sy;
}

// The blotches: a sum of waves whose whole cycles fit the tile (so it repeats without a step), wavelengths 25 - 150
// units in every direction, the longer ones stronger - soft round patches with no lattice or grid in them.
function blotchWaves() {
  const waves = []; const uW = PARCHMENT.tileW / PARCHMENT.density; const uH = PARCHMENT.tileH / PARCHMENT.density;
  for (let ky = 0; ky <= 10; ky++) for (let kx = -20; kx <= 20; kx++) {
    if (ky === 0 && kx <= 0) continue; // one of each +/- pair
    const lambda = 1 / Math.hypot(kx / uW, ky / uH);
    if (lambda < 40 || lambda > 256) continue;
    const r = hash3(kx + 64, ky + 64, 21); const p = hash3(kx + 64, ky + 64, 22);
    waves.push({ kx, ky, amp: Math.pow(lambda / 256, 1.5) * (0.35 + 0.65 * r), phase: 2 * Math.PI * p });
  }
  const norm = Math.sqrt(waves.reduce((n, w) => n + (w.amp * w.amp) / 2, 0));
  for (const w of waves) w.amp /= norm; // the sum: mean 0, deviation 1
  return waves;
}

// The body: the 1.1.0 paper recipe (fibre at three scales, faint strands, soft blotches toward tan, the 10 % lift the
// brightness setting takes back) on periodic noise, its feature sizes in UI units at `density`: fibre 0.8 / 2.75 / 12,
// strands 14 x 1 (lengthwise and crosswise, so no direction dominates), blotches 25 - 150 across, as much tan as the
// 1.1.0 sheet carried. Opaque.
function parchmentTile() {
  const W = PARCHMENT.tileW; const H = PARCHMENT.tileH;
  const px = Buffer.alloc(W * H * 4);
  const waves = blotchWaves();
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const u = (x + 0.5) / W; const v = (y + 0.5) / H;
    const oct = (nx, ny, seed) => noiseP(u * nx, v * ny, nx, ny, seed) - 0.5;
    const fibre = oct(640, 320, 1) * 0.25 + oct(186, 93, 2) * 0.5 + oct(43, 21, 3) * 0.25; // the weight on the scales a screen shows (1.1.0: 0.5 / 0.3 / 0.2 at 3 texels a pixel)
    const strand = (oct(37, 256, 4) + oct(512, 18, 5)) * 0.5 * 0.05;
    let field = 0;
    for (const w of waves) field += w.amp * Math.cos(2 * Math.PI * (w.kx * u + w.ky * v) + w.phase);
    const blot = clamp(BLOT.offset + BLOT.gain * field);
    const k = 1 + 0.1 * fibre + strand * 0.9; // 1.1.0: 0.07 / 0.6, its fibre then mostly finer than a pixel
    const c = PARCH.cream.map((val, i) => clamp((val + (PARCH.tan[i] - val) * 0.28 * blot) * k * PARCH.lift));
    const o = (y * W + x) * 4;
    px[o] = Math.round(c[0] * 255); px[o + 1] = Math.round(c[1] * 255); px[o + 2] = Math.round(c[2] * 255); px[o + 3] = 255;
  }
  return { w: W, h: H, px };
}

// the torn line of one side, `phase` texels along it from where its strip starts (periodic over the strip)
function tearAt(side, phase) {
  const seed = WEAR.seeds[side];
  let w = 0;
  for (const [n, weight, m] of WEAR.harmonics) w += weight * Math.sin((2 * Math.PI * n * phase) / PERIOD + seed * m);
  return (WEAR.tear + WEAR.amp * w) * DT;
}
// what the edge leaves of the body at `dist` texels inside the torn line (negative: outside it), 0..1
function wearFactor(dist) {
  if (dist < 0) return WEAR.outside;
  const rim = WEAR.rimDark + (1 - WEAR.rimDark) * clamp(dist / (WEAR.rim * DT));
  const fade = 1 - WEAR.fadeDark * (1 - clamp(dist / (WEAR.fade * DT)));
  return rim * fade;
}
const SS = 3;
const wearPixel = (px, o, sum) => { px[o] = 0; px[o + 1] = 0; px[o + 2] = 0; px[o + 3] = Math.round(clamp(1 - sum / (SS * SS)) * 255); };

// The strips: row 0 top, 1 right, 2 bottom, 3 left, `BAND` texels each; even rows run outward -> inward downward,
// odd rows inward -> outward, so each row boundary joins two equal sides (two inner sides, both clear, or two outer
// sides, both the scorched margin) and filtering across it changes nothing.
function parchmentEdge() {
  const W = PARCHMENT.edgeW; const H = PARCHMENT.edgeH;
  const px = Buffer.alloc(W * H * 4);
  const sides = ['top', 'right', 'bottom', 'left'];
  for (let y = 0; y < H; y++) for (let x = 0; x < W; x++) {
    const row = Math.floor(y / BAND); const local = y - row * BAND;
    let sum = 0;
    for (let j = 0; j < SS; j++) for (let i = 0; i < SS; i++) {
      const along = x + (i + 0.5) / SS; const t = local + (j + 0.5) / SS;
      const depth = row % 2 === 0 ? t : BAND - t;
      sum += wearFactor(depth - tearAt(sides[row], along));
    }
    wearPixel(px, (y * W + x) * 4, sum);
  }
  return { w: W, h: H, px };
}

// The corner atlas: a 2 x 2 band sheet whose four quadrants are the four corners and whose strips have no length
// between them - every side's torn line at -|distance from the middle| (the strips' phase continued backwards past
// where they start), the nearest torn line counting, a nibble at each outer corner. Its middle lines are where the
// strips join: the columns / rows there are the strips' own first texels.
function parchmentCorners() {
  const S = PARCHMENT.corners; const half = S / 2;
  const px = Buffer.alloc(S * S * 4);
  for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
    const corner = (y < half ? 'TOP' : 'BOTTOM') + (x < half ? 'LEFT' : 'RIGHT');
    let sum = 0;
    for (let j = 0; j < SS; j++) for (let i = 0; i < SS; i++) {
      const sx = x + (i + 0.5) / SS; const sy = y + (j + 0.5) / SS;
      const ph = -Math.abs(sx - half); const pv = -Math.abs(sy - half);
      let dist = Math.min(sy - tearAt('top', ph), S - sy - tearAt('bottom', ph), sx - tearAt('left', pv), S - sx - tearAt('right', pv));
      const cx = Math.min(sx, S - sx); const cy = Math.min(sy, S - sy); const near = WEAR.nibbleIn * DT;
      if (cx < near && cy < near) dist -= WEAR.corner[corner] * WEAR.nibble * DT * g(Math.hypot(cx, cy), WEAR.nibbleR * DT) * (1 - Math.min(cx, cy) / near);
      sum += wearFactor(dist);
    }
    wearPixel(px, (y * S + x) * 4, sum);
  }
  return { w: S, h: S, px };
}

function generate() {
  return {
    BanzaiStalk: { w: PANEL.periodPx * PANEL.periods, h: PANEL.texH, px: render(PANEL.periodPx * PANEL.periods, PANEL.texH, stalkSample, 3) },
    BanzaiStalkEnd: { w: 2 * PANEL.tipPx, h: PANEL.texH, px: render(2 * PANEL.tipPx, PANEL.texH, tipSample, 3) },
    BanzaiRopeTie: { w: 256, h: 256, px: render(256, 256, tieSample, 2) },
    BanzaiParchmentTile: parchmentTile(),
    BanzaiParchmentEdge: parchmentEdge(),
    BanzaiParchmentCorners: parchmentCorners(),
  };
}

// ---- frame geometry (mirrors Compat.lua's LayoutBamboo) ----------------------
// pieces of one frame of W x H units at stalk diameter d (y down from the
// holder's top-left): every piece has x, y, w, h, the texture, its 8 tex
// coords (UL, LL, UR, LR as the game takes them), the stalk it belongs to and
// its 0..1 position along that stalk (pa, pb) for the colour field.
// opts.shortBottom: chat / Details (the side stalks end on the bottom panel's top line);
// opts.flushLeft: the frame's x on the screen when it sits on the left screen edge (1.2.0 chat)
function layout(W, H, d, opts = {}) {
  const extBottom = opts.shortBottom ? PANEL.extBottom : PANEL.ext;
  const flush = typeof opts.flushLeft === 'number';
  const startLeft = flush ? Math.max(0, -opts.flushLeft) : -PANEL.ext * d; // flush: the stalks start on the screen edge
  const half = d / 2;
  const strip = (PANEL.texH / PANEL.texD) * d;
  const tip = (PANEL.tipPx / PANEL.texD) * d;
  const axis = { top: PANEL.outer + half, bottom: H - PANEL.outer - half, left: PANEL.outer + half, right: W - PANEL.outer - half };
  const pieces = [];
  const stalks = [
    { name: 'top', horizontal: true, at: axis.top, from: startLeft, to: W + PANEL.ext * d, cutEnd: 'end', sub: 2 },
    { name: 'bottom', horizontal: true, at: axis.bottom, from: startLeft, to: W + PANEL.ext * d, cutEnd: flush ? 'end' : 'start', sub: 0 },
    { name: 'left', horizontal: false, at: axis.left, from: -PANEL.ext * d, to: H + extBottom * d, cutEnd: 'start', sub: 1 },
    { name: 'right', horizontal: false, at: axis.right, from: -PANEL.ext * d, to: H + extBottom * d, cutEnd: 'end', sub: 1 },
  ];
  const coords = (horizontal, u0, u1, flip) => {
    // horizontal: U along x, V down; vertical: U along y, V along x (the highlight stays up / left)
    const a = flip ? u1 : u0; const b = flip ? u0 : u1;
    return horizontal ? [a, 0, a, 1, b, 0, b, 1] : [a, 0, b, 0, a, 1, b, 1];
  };
  for (const s of stalks) {
    const L = s.to - s.from;
    const bodyFrom = s.from + tip; const bodyTo = s.to - tip;
    const n = Math.max(1, Math.round((bodyTo - bodyFrom) / (PANEL.period * d)));
    const seg = (bodyTo - bodyFrom) / n;
    const put = (a, b, tex, uv) => {
      const piece = { stalk: s.name, sub: s.sub, tex, uv, pa: (a - s.from) / L, pb: (b - s.from) / L };
      if (s.horizontal) Object.assign(piece, { x: a, y: s.at - strip / 2, w: b - a, h: strip });
      else Object.assign(piece, { x: s.at - strip / 2, y: a, w: strip, h: b - a });
      pieces.push(piece);
    };
    for (let i = 0; i < n; i++) {
      const k = i % PANEL.periods;
      put(bodyFrom + i * seg, bodyFrom + (i + 1) * seg + (i < n - 1 ? 0.25 : 0), 'BanzaiStalk', coords(s.horizontal, k / PANEL.periods, (k + 1) / PANEL.periods, false));
    }
    // the ends: the cut tip on one end, the plain node end on the other; a piece's body runs in from u = 0
    const cutStart = s.cutEnd === 'start';
    const gap = PANEL.tipGap / (2 * PANEL.tipPx);
    const cut = [0, 0.5 - gap]; const plain = [0.5 + gap, 1];
    const start = cutStart ? cut : plain; const end = cutStart ? plain : cut;
    put(s.from, bodyFrom, 'BanzaiStalkEnd', coords(s.horizontal, start[0], start[1], true));
    put(bodyTo, s.to, 'BanzaiStalkEnd', coords(s.horizontal, end[0], end[1], false));
  }
  const tie = PANEL.tie * d;
  const ties = [];
  const leftTie = flush ? Math.max(axis.left, tie / 2 - opts.flushLeft) : axis.left;
  for (const [cx, cy, name] of [[leftTie, axis.top, 'TOPLEFT'], [axis.right, axis.top, 'TOPRIGHT'], [leftTie, axis.bottom, 'BOTTOMLEFT'], [axis.right, axis.bottom, 'BOTTOMRIGHT']]) {
    const t = { corner: name, x: cx - tie / 2, y: cy - tie / 2, w: tie, h: tie, flip: /RIGHT/.test(name), v1: 1 };
    if (opts.shortBottom && /BOTTOM/.test(name) && t.y + t.h > H) { t.v1 = (H - t.y) / tie; t.h = H - t.y; } // the rope passes behind the bottom panel
    ties.push(t);
  }
  const inset = PANEL.outer + PANEL.parchment * d;
  return { pieces, ties, axis, strip, tip, parchment: { x: inset, y: inset, w: W - 2 * inset, h: H - 2 * inset, corner: PANEL.parchmentCorner * d }, inner: PANEL.outer + d };
}

// ---- 1.3.7 the parchment's pieces (mirrors Compat.ParchmentLayout) -----------
// For a pw x ph parchment rectangle at stalk diameter d (x right, y down from its top-left): the body (one quad, the
// tile repeating from the panel's phase at `density` texels per unit on both axes), the four corners (one band
// square each, the atlas quadrants) and every edge in two halves - the strip repeating along it from each corner,
// mirrored where the halves meet in the middle, so both corner joins meet the strip where it starts (phase 0) and
// the two halves meet on the same texels. Coords as the game takes them (UL, LL, UR, LR; u, v each). Every overlay
// piece shares its sides exactly with its neighbours: nothing overlaps (no doubled darkening), nothing is left open.
function parchmentLayout(pw, ph, d, kind) {
  const M = PARCHMENT;
  const c = Math.min(PANEL.parchmentCorner * d, pw / 2, ph / 2);
  const period = M.period * c;
  const phase = M.phase[kind] || M.phase.chat;
  const pieces = [];
  const add = (name, texture, x0, y0, x1, y1, coords) => pieces.push({ name, texture, x0, y0, x1, y1, coords });
  const u0 = phase[0]; const v0 = phase[1]; const u1 = u0 + (pw * M.density) / M.tileW; const v1 = v0 + (ph * M.density) / M.tileH;
  add('body', 'tile', 0, 0, pw, ph, [u0, v0, u0, v1, u1, v0, u1, v1]);
  add('TOPLEFT', 'corners', 0, 0, c, c, [0, 0, 0, 0.5, 0.5, 0, 0.5, 0.5]);
  add('TOPRIGHT', 'corners', pw - c, 0, pw, c, [0.5, 0, 0.5, 0.5, 1, 0, 1, 0.5]);
  add('BOTTOMLEFT', 'corners', 0, ph - c, c, ph, [0, 0.5, 0, 1, 0.5, 0.5, 0.5, 1]);
  add('BOTTOMRIGHT', 'corners', pw - c, ph - c, pw, ph, [0.5, 0.5, 0.5, 1, 1, 0.5, 1, 1]);
  const mx = pw / 2; const my = ph / 2;
  const uw = (mx - c) / period; const uh = (my - c) / period;
  add('top1', 'edge', c, 0, mx, c, [0, 0, 0, 0.25, uw, 0, uw, 0.25]);
  add('top2', 'edge', mx, 0, pw - c, c, [uw, 0, uw, 0.25, 0, 0, 0, 0.25]);
  add('bottom1', 'edge', c, ph - c, mx, ph, [0, 0.75, 0, 0.5, uw, 0.75, uw, 0.5]);
  add('bottom2', 'edge', mx, ph - c, pw - c, ph, [uw, 0.75, uw, 0.5, 0, 0.75, 0, 0.5]);
  add('left1', 'edge', 0, c, c, my, [0, 1, uh, 1, 0, 0.75, uh, 0.75]);
  add('left2', 'edge', 0, my, c, ph - c, [uh, 1, 0, 1, uh, 0.75, 0, 0.75]);
  add('right1', 'edge', pw - c, c, pw, my, [0, 0.25, uh, 0.25, 0, 0.5, uh, 0.5]);
  add('right2', 'edge', pw - c, my, pw, ph - c, [uh, 0.25, 0, 0.25, uh, 0.5, 0, 0.5]);
  return { pieces, band: c, period };
}
// the texture behind each piece kind and its wrap modes (horizontal, vertical), as Compat.lua sets them
const PARCHMENT_TEXTURES = { tile: ['BanzaiParchmentTile', 'REPEAT', 'REPEAT'], corners: ['BanzaiParchmentCorners', 'CLAMP', 'CLAMP'], edge: ['BanzaiParchmentEdge', 'REPEAT', 'CLAMP'] };

module.exports = { PANEL, generate, layout, stalkSample, tipSample, tieSample, parchment: legacyParchment, legacyParchment, PARCH, TIE,
  PARCHMENT, WEAR, parchmentLayout, PARCHMENT_TEXTURES, parchmentTile, parchmentEdge, parchmentCorners, tearAt, wearFactor, noiseP };
