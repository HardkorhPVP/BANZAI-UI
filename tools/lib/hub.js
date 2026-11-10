// BANZAI 1.3.0 BANZAI SPLIT media (original, procedural): the central identity /
// cast hub of the split unit frames and the class-colour disc sheet the
// BANZAI COMPACT Details rows fall back to. Greyscale with alpha (the game
// colours them with SetVertexColor / SetGradient), except BanzaiClassDiscs.
//
//   BanzaiHubDisc     the dark disc behind the icon            (0 .. 0.96 R)
//   BanzaiHubRing     the class ring                           (0.78 .. 0.94 R, thin dark edges)
//   BanzaiHubAccent   the thin outer green -> purple accent     (0.95 .. 1.00 R)
//   BanzaiHubMask     the icon mask (tucked under the ring)     (0 .. 0.80 R)
//   BanzaiHubSwipe    the radial cast progress (Cooldown swipe) (0.765 .. 0.945 R, flat)
//   BanzaiClassDiscs  512 x 512, Details' class-icon layout: one class-colour disc per class
//   BanzaiHubCrest    1.3.3, 256 x 256 full colour: the neutral NPC crest of the TARGET NPC preview sample
//
// Every hub texture is a 128 px canvas holding a circle of R = 60 px (the hub's
// size; Identity.HUB.canvas = 128 / 120 in Banzai Art), drawn as the exact
// pixel coverage (16 x 16 samples per pixel) and mip-filtered by the game.
'use strict';

const { renderExact, ringAt, discAt, clamp } = require('./bamboo');

const HUB = { canvas: 128, design: 120, disc: 0.96, ring: { outer: 0.94, inner: 0.78, line: 0.015 }, accent: { outer: 1.0, inner: 0.95, line: 0 }, mask: 0.80, swipe: { outer: 0.945, inner: 0.765 } };

// a flat band (no edge lines): the cooldown swipe covers the ring exactly
function bandAt(cx, cy, R, inner, outer) {
  return (x, y) => {
    const r = Math.hypot(x - cx, y - cy) / R;
    return (r >= inner && r <= outer) ? [1, 1] : null;
  };
}

// Details' class_coords (functions/profiles.lua): an 8 x 8 grid of 0.125 cells
const DETAILS_CELLS = {
  WARRIOR: [0, 0], MAGE: [1, 0], ROGUE: [2, 0], DRUID: [3, 0], EVOKER: [4, 0],
  HUNTER: [0, 1], SHAMAN: [1, 1], PRIEST: [2, 1], WARLOCK: [3, 1],
  PALADIN: [0, 2], DEATHKNIGHT: [1, 2], MONK: [2, 2], DEMONHUNTER: [3, 2],
  ENEMY: [0, 3], PET: [1, 3], UNKNOW: [2, 3], Horde: [3, 3],
};
// the game's public class colours (RAID_CLASS_COLORS); neutral / hostile for the other cells
const CLASS_COLORS = {
  DEATHKNIGHT: [0.77, 0.12, 0.23], DEMONHUNTER: [0.64, 0.19, 0.79], DRUID: [1.00, 0.49, 0.04], EVOKER: [0.20, 0.58, 0.50],
  HUNTER: [0.67, 0.83, 0.45], MAGE: [0.25, 0.78, 0.92], MONK: [0.00, 1.00, 0.60], PALADIN: [0.96, 0.55, 0.73],
  PRIEST: [1.00, 1.00, 1.00], ROGUE: [1.00, 0.96, 0.41], SHAMAN: [0.00, 0.44, 0.87], WARLOCK: [0.53, 0.53, 0.93],
  WARRIOR: [0.78, 0.61, 0.43], ENEMY: [0.86, 0.16, 0.14], PET: [0.42, 0.62, 0.38], UNKNOW: [0.55, 0.58, 0.62], Horde: [0.70, 0.12, 0.10],
};

const mix = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];

// one disc per cell: the class colour light at the top, deeper at the bottom,
// a dark rim and a soft highlight - readable at Details' 14 - 18 unit icons
function classDiscs() {
  const S = 512; const cell = 64; const ss = 8;
  const px = Buffer.alloc(S * S * 4);
  for (const [name, [cx0, cy0]] of Object.entries(DETAILS_CELLS)) {
    const base = CLASS_COLORS[name];
    const ox = cx0 * cell; const oy = cy0 * cell; const c = cell / 2; const R = 27;
    for (let y = 0; y < cell; y++) for (let x = 0; x < cell; x++) {
      let r = 0; let g = 0; let b = 0; let a = 0;
      for (let j = 0; j < ss; j++) for (let i = 0; i < ss; i++) {
        const sx = x + (i + 0.5) / ss - c; const sy = y + (j + 0.5) / ss - c;
        const d = Math.hypot(sx, sy) / R;
        if (d > 1) continue;
        const t = clamp((sy / R + 1) / 2); // 0 top .. 1 bottom
        let col = mix(mix(base, [1, 1, 1], 0.38), mix([0, 0, 0], base, 0.62), t);
        const hi = Math.exp(-Math.pow((Math.hypot(sx + R * 0.28, sy + R * 0.34) / R) / 0.32, 2)) * 0.32;
        col = mix(col, [1, 1, 1], hi);
        if (d > 0.86) col = mix(col, [0.02, 0.03, 0.03], clamp((d - 0.86) / 0.06)); // dark rim
        r += col[0]; g += col[1]; b += col[2]; a += 1;
      }
      const n = ss * ss; const o = ((oy + y) * S + ox + x) * 4;
      if (a > 0) { px[o] = Math.round(clamp(r / a) * 255); px[o + 1] = Math.round(clamp(g / a) * 255); px[o + 2] = Math.round(clamp(b / a) * 255); }
      px[o + 3] = Math.round(clamp(a / n) * 255);
    }
  }
  return { w: S, h: S, px };
}

// 1.3.3 the neutral BANZAI NPC crest of the TARGET NPC preview sample (Banzai Art's own; until 1.3.2 the sample
// showed the game icon INV_Misc_Head_Dragon_01): full colour, 256 x 256, drawn for the hub's icon square (the
// hub's round mask shows the inscribed circle) - a dark field, a steel heater shield with a bronze rim, a horned
// iron mask with two amber eye slits. Original and procedural (no game file, no reference image).
const CREST = { size: 256, ss: 4, shield: { top: 54, straight: 140, point: 212, half: 70, corner: 10, rim: 7 } };
function crest() {
  const S = CREST.size; const ss = CREST.ss; const K = CREST.shield; const cx = S / 2;
  const px = Buffer.alloc(S * S * 4);
  const halfAt = (y) => {
    if (y < K.top || y > K.point) return -1;
    if (y <= K.straight) return K.half;
    const t = (y - K.straight) / (K.point - K.straight);
    return K.half * Math.pow(Math.max(0, 1 - Math.pow(t, 1.7)), 0.85);
  };
  // signed distance (px, inside positive) to the shield outline, close enough for a 7 px rim
  const shieldDist = (x, y) => {
    const h = halfAt(y);
    if (h < 0) return -Math.min(Math.abs(y - K.top), Math.abs(y - K.point));
    let d = Math.min(h - Math.abs(x - cx), y - K.top);
    // the rounded top corners
    const qx = Math.abs(x - cx) - (K.half - K.corner); const qy = (K.top + K.corner) - y;
    if (qx > 0 && qy > 0) d = Math.min(d, K.corner - Math.hypot(qx, qy));
    // the curved lower edge: measured across the slope
    if (y > K.straight) { const dy = 1.2; const slope = Math.abs(halfAt(Math.min(K.point, y + dy)) - h) / dy; d = Math.min(d, (h - Math.abs(x - cx)) / Math.sqrt(1 + slope * slope)); }
    return d;
  };
  // a horn: a curved stroke from its base to its tip, tapering
  const horn = (bx, by, mx, my, tx, ty) => {
    const pts = [];
    for (let i = 0; i <= 48; i++) {
      const t = i / 48; const a = (1 - t) * (1 - t); const b = 2 * (1 - t) * t; const c = t * t;
      pts.push([a * bx + b * mx + c * tx, a * by + b * my + c * ty, 9.5 * (1 - t) + 1.2 * t, t]);
    }
    return (x, y) => {
      let best = null;
      for (const p of pts) { const d = Math.hypot(x - p[0], y - p[1]) - p[2]; if (!best || d < best[0]) best = [d, p[3]]; }
      return best;
    };
  };
  const horns = [horn(110, 108, 84, 100, 80, 62), horn(146, 108, 172, 100, 176, 62)];
  const maskHalf = (y) => (y < 100 || y > 178) ? -1 : 31 - 19 * Math.pow((y - 100) / 78, 1.4);
  const eye = (x, y, ex, dir) => { const a = dir * 0.33; const u = (x - ex) * Math.cos(a) + (y - 124) * Math.sin(a); const v = -(x - ex) * Math.sin(a) + (y - 124) * Math.cos(a); return Math.hypot(u / 10.5, v / 3.6); };
  const sampleAt = (x, y) => {
    const r = Math.hypot(x - cx, y - cx) / (S / 2);
    let col = mix([0.13, 0.15, 0.15], [0.035, 0.045, 0.045], Math.min(1, r * r));
    const d = shieldDist(x, y);
    if (d > -2.5 && d <= 0) col = mix(col, [0.02, 0.02, 0.02], 0.85); // the dark outline just outside
    if (d > 0) {
      const ty = clamp((y - K.top) / (K.point - K.top));
      let steel = mix([0.62, 0.65, 0.70], [0.20, 0.22, 0.26], ty);
      const sheen = Math.exp(-Math.pow(((x - cx) + (y - 110) * 0.8) / 26, 2)) * 0.10;
      steel = mix(steel, [1, 1, 1], sheen);
      if (d < K.rim) col = mix([0.84, 0.66, 0.32], [0.44, 0.30, 0.11], ty); // the bronze rim
      else if (d < K.rim + 1.6) col = [0.07, 0.07, 0.08];                    // its inner line
      else col = steel;
    }
    // the horns (bone, darker at the base), over the shield
    for (const h of horns) {
      const [hd, t] = h(x, y);
      if (hd < 0) col = mix(mix([0.50, 0.45, 0.36], [0.92, 0.88, 0.76], t), [0.05, 0.05, 0.05], hd > -1.4 ? 0.7 : 0);
    }
    // the iron mask
    const mh = maskHalf(y);
    if (mh > 0) {
      const md = Math.min(mh - Math.abs(x - cx), y - 100, 178 - y);
      if (md > 0) {
        const tm = (y - 100) / 78;
        col = md < 1.6 ? [0.03, 0.03, 0.04] : mix([0.24, 0.24, 0.27], [0.08, 0.08, 0.10], tm);
        if (md >= 1.6 && Math.abs(x - cx) < 1.6 && y > 130 && y < 172) col = mix(col, [0.36, 0.36, 0.40], 0.6); // the nose ridge
        // the eye slits with a soft amber glow on the iron
        for (const [ex, dir] of [[cx - 15, 1], [cx + 15, -1]]) {
          const e = eye(x, y, ex, dir);
          if (e < 1) col = mix([1.0, 0.80, 0.30], [1.0, 0.55, 0.08], e);
          else if (e < 2.2) col = mix(col, [1.0, 0.55, 0.10], 0.45 * (1 - (e - 1) / 1.2));
        }
      }
    }
    return col;
  };
  for (let y = 0; y < S; y++) for (let x = 0; x < S; x++) {
    let r = 0; let g = 0; let b = 0;
    for (let j = 0; j < ss; j++) for (let i = 0; i < ss; i++) {
      const c = sampleAt(x + (i + 0.5) / ss, y + (j + 0.5) / ss);
      r += c[0]; g += c[1]; b += c[2];
    }
    const n = ss * ss; const o = (y * S + x) * 4;
    px[o] = Math.round(clamp(r / n) * 255); px[o + 1] = Math.round(clamp(g / n) * 255); px[o + 2] = Math.round(clamp(b / n) * 255); px[o + 3] = 255;
  }
  return { w: S, h: S, px };
}

function generate() {
  const s = HUB.canvas; const c = s / 2; const R = HUB.design / 2;
  return {
    BanzaiHubCrest: crest(), // 1.3.3
    BanzaiHubDisc: { w: s, h: s, px: renderExact(s, s, discAt(c, c, HUB.disc * R)) },
    BanzaiHubRing: { w: s, h: s, px: renderExact(s, s, ringAt(c, c, R, HUB.ring)) },
    BanzaiHubAccent: { w: s, h: s, px: renderExact(s, s, ringAt(c, c, R, HUB.accent)) },
    BanzaiHubMask: { w: s, h: s, px: renderExact(s, s, discAt(c, c, HUB.mask * R)) },
    BanzaiHubSwipe: { w: s, h: s, px: renderExact(s, s, bandAt(c, c, R, HUB.swipe.inner, HUB.swipe.outer)) },
    BanzaiClassDiscs: classDiscs(),
  };
}

module.exports = { generate, HUB, DETAILS_CELLS, CLASS_COLORS };
