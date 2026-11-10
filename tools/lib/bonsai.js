// Original BANZAI art, generated procedurally (no third-party artwork is read
// or copied): the miniature tree shown behind the BANZAI wordmark in combat.
//
//   BanzaiBonsai  256x256 RGBA, full colour (not tinted in game): a small
//                 Japanese-style bonsai - dark curved trunk, layered cloud
//                 pads of restrained vivid green, a shallow dark pot with a
//                 purple rim, a few purple blossoms and a thin violet rim
//                 light under the pads; dark outline, transparent background.
'use strict';

const clamp = (v, a = 0, b = 1) => Math.max(a, Math.min(b, v));
const mix = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];

const COLORS = {
  trunk: [0.17, 0.11, 0.09], trunkLight: [0.36, 0.25, 0.19],
  pad: [0.07, 0.56, 0.28], padLight: [0.52, 0.93, 0.22], padShadow: [0.02, 0.27, 0.15],
  violet: [0.56, 0.22, 1.0], purple: [0.62, 0.10, 0.86],
  pot: [0.09, 0.08, 0.12], potLight: [0.20, 0.18, 0.25], outline: [0.02, 0.03, 0.04],
};

// trunk: a curved spine from the pot to the apex, thick at the base
const TRUNK = [[128, 224], [134, 205], [143, 186], [140, 166], [126, 150], [114, 134], [117, 116], [128, 98], [130, 80]];
const TRUNK_R = [11, 10.5, 9.5, 8.6, 7.8, 7, 6.2, 5.2, 4.2];
const BRANCHES = [
  { pts: [[121, 146], [104, 140], [86, 128], [70, 121]], r: [5.4, 4.6, 3.6, 2.8] },
  { pts: [[137, 170], [158, 158], [176, 140], [188, 128]], r: [5.6, 4.8, 3.8, 2.8] },
  { pts: [[118, 118], [140, 106], [164, 96], [182, 90]], r: [4.6, 3.8, 3.2, 2.5] },
];
// cloud pads (ellipses, drawn back to front)
const PADS = [
  { x: 72, y: 112, rx: 40, ry: 15 }, { x: 190, y: 120, rx: 36, ry: 13 }, { x: 178, y: 82, rx: 40, ry: 15 },
  { x: 128, y: 64, rx: 50, ry: 21 }, { x: 96, y: 84, rx: 30, ry: 12 },
];
const BLOSSOMS = [[60, 104], [104, 56], [150, 52], [196, 74], [204, 114]];
const POT = { top: 224, bottom: 244, x0: 70, x1: 186, inset: 8, rim: 4 };

function segDist(px, py, ax, ay, bx, by) {
  const dx = bx - ax; const dy = by - ay;
  const t = clamp(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy));
  const cx = ax + dx * t; const cy = ay + dy * t;
  return { d: Math.hypot(px - cx, py - cy), t, nx: (px - cx), ny: (py - cy) };
}

// a thick curved stroke: colour with a light left edge (light from the top-left)
function stroke(pts, radii, x, y) {
  let best = null;
  for (let i = 0; i < pts.length - 1; i++) {
    const s = segDist(x, y, pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1]);
    const r = radii[i] + (radii[i + 1] - radii[i]) * s.t;
    if (s.d <= r && (!best || s.d / r < best.k)) best = { k: s.d / r, side: (s.nx * -0.7 + s.ny * -0.7) / Math.max(0.001, s.d) };
  }
  if (!best) return null;
  const light = clamp(0.5 + 0.5 * best.side * best.k);
  let c = mix(COLORS.trunk, COLORS.trunkLight, light * 0.8);
  if (best.k > 0.8) c = mix(c, COLORS.outline, (best.k - 0.8) * 2.5);
  return c;
}

function pad(p, x, y) {
  const u = (x - p.x) / p.rx; const v = (y - p.y) / p.ry;
  // cloud edge: a few bumps along the rim
  const ang = Math.atan2(v, u);
  const bump = 1 + 0.07 * Math.sin(ang * 7 + p.x * 0.1) + 0.04 * Math.sin(ang * 13 + p.y * 0.2);
  const r = Math.hypot(u, v) / bump;
  if (r > 1) return null;
  const top = clamp(0.5 - v * 0.6);                      // lighter on top
  let c = mix(COLORS.padShadow, COLORS.pad, clamp(0.35 + top));
  c = mix(c, COLORS.padLight, clamp((top - 0.55) * 1.6) * 0.75);
  const leaf = 0.035 * (Math.sin(x * 1.7 + y * 0.4) * Math.sin(y * 1.3 - x * 0.6) + 0.6 * Math.sin(x * 0.43 + y * 2.1)); // fine leaf texture
  c = c.map((ch) => clamp(ch + leaf));
  if (v > 0.45 && r > 0.82) c = mix(c, COLORS.violet, 0.55); // thin violet rim light underneath
  if (r > 0.93) c = mix(c, COLORS.outline, (r - 0.93) * 10);
  return c;
}

function pot(x, y) {
  const P = POT;
  if (y < P.top || y > P.bottom) return null;
  const f = (y - P.top) / (P.bottom - P.top);
  const x0 = P.x0 + P.inset * f; const x1 = P.x1 - P.inset * f;
  if (x < x0 || x > x1) {
    // two small feet
    const foot = y > P.bottom - 3 && ((x > x0 + 6 && x < x0 + 16) || (x < x1 - 6 && x > x1 - 16));
    if (!foot) return null;
  }
  if (y < P.top + P.rim) return mix(COLORS.purple, COLORS.violet, (y - P.top) / P.rim); // purple rim
  const shade = clamp(0.6 - Math.abs((x - 128) / 70) * 0.4 - f * 0.3);
  return mix(COLORS.pot, COLORS.potLight, shade);
}

function blossom(x, y) {
  for (const [bx, by] of BLOSSOMS) {
    const d = Math.hypot(x - bx, y - by);
    if (d < 3.6) return mix(COLORS.violet, [1, 1, 1], d < 1.2 ? 0.5 : 0);
  }
  return null;
}

function sample(x, y) {
  let c = null;
  const t = stroke(TRUNK, TRUNK_R, x, y); if (t) c = t;
  for (const b of BRANCHES) { const s = stroke(b.pts, b.r, x, y); if (s) c = s; }
  for (const p of PADS) { const s = pad(p, x, y); if (s) c = s; }
  const bl = blossom(x, y); if (bl) c = bl;
  const pt = pot(x, y); if (pt) c = pt;
  return c;
}

function generate(size = 256) {
  const SS = 4;
  const rgb = new Float32Array(size * size * 3); const cov = new Float32Array(size * size);
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    let r = 0; let g = 0; let b = 0; let n = 0;
    for (let j = 0; j < SS; j++) for (let i = 0; i < SS; i++) {
      const c = sample((x + (i + 0.5) / SS) * 256 / size, (y + (j + 0.5) / SS) * 256 / size);
      if (c) { r += c[0]; g += c[1]; b += c[2]; n++; }
    }
    const k = y * size + x;
    cov[k] = n / (SS * SS);
    if (n) { rgb[k * 3] = r / n; rgb[k * 3 + 1] = g / n; rgb[k * 3 + 2] = b / n; }
  }
  // dark outline (1.5 px) so the tree reads on any background
  const px = Buffer.alloc(size * size * 4);
  const R = 1.5;
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const k = y * size + x;
    let a = cov[k]; let c = [rgb[k * 3], rgb[k * 3 + 1], rgb[k * 3 + 2]];
    if (a < 1) {
      let near = 0;
      for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) {
        if (dx * dx + dy * dy > R * R + 0.5) continue;
        const xx = x + dx; const yy = y + dy;
        if (xx >= 0 && yy >= 0 && xx < size && yy < size) near = Math.max(near, cov[yy * size + xx]);
      }
      const ring = near * 0.9;
      if (ring > a) { c = a > 0 ? mix(COLORS.outline, c, a / ring) : COLORS.outline; a = ring; }
    }
    const o = k * 4;
    px[o] = Math.round(clamp(c[0]) * 255); px[o + 1] = Math.round(clamp(c[1]) * 255); px[o + 2] = Math.round(clamp(c[2]) * 255);
    px[o + 3] = Math.round(clamp(a) * 255);
  }
  return { w: size, h: size, px };
}

module.exports = { generate, COLORS };
