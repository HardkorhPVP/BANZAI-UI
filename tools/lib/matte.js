// BANZAI 1.3.2: the alpha extraction for Darren's class-art JPEGs (tools/icons.js).
// The masters were generated on a flat neutral grey matte (about 110 - 123 here,
// not exactly #808080, with JPEG noise of about 1 level) and every artwork edge
// that faces the matte is a dark outline. A pixel is never keyed on its colour
// alone - the art has grey steel, charcoal and silver of its own:
//
//   1 matte     the median colour of the image border
//   2 exterior  pixels close to the matte colour, connected to the image border
//   3 holes     the other matte-coloured regions (the gap inside the bamboo ring,
//               the spaces between horns, spikes and ring) become transparent only
//               when they look like the matte: flat (matte noise, no shading),
//               neutral and the matte's own colour, and closed by hard edges (dark
//               outlines / saturated art) - painted steel near the matte grey is
//               shaded and tinted (and mostly has soft edges) and stays opaque
//   4 alpha     inside, opaque; at the edge (the 1 - 2 px anti-aliased seam) the
//               coverage is solved from the local matte colour and the art colour
//               just behind the edge: C = a F + (1 - a) B
//   5 decontaminate  each seam pixel's colour is solved for the art alone,
//               F = B + (C - B) / a (blended toward the art behind it where a is
//               small), so no matte grey is left in the edge on any background
//
// Everything works on the full-resolution source; nothing is resized before the
// matte is gone. Deterministic: integer labels, fixed scan order.
'use strict';

const MATTE = {
  border: 16,        // px: the strip the matte colour is measured on
  tolerance: 12,     // RGB distance: closer than this to the matte, a pixel may be matte
  hole: {
    minArea: 64,     // px: smaller matte-coloured specks inside the art stay art (invisible at any size)
    maxSd: 2.5,      // flat: the matte's JPEG noise is 1.3 - 2.1 levels; shaded steel 2.6 and up
    maxOffset: 6,    // the hole's mean colour within this of the matte colour
    maxChroma: 2.0,  // neutral: the matte holes' mean colour is grey within 0.0 - 1.4; tinted steel 2.3 and up
    minHard: 0.85,   // share of the hole's edge that steps into clearly different art
    hard: 40,        // RGB distance to the matte that counts as a hard edge
    probe: 3,        // px: how far past the edge that is measured (past the anti-aliased seam)
  },
  band: 2,           // px: art pixels this close to the matte get a solved coverage
  window: 4,         // px: the neighbourhood the local matte colour comes from
  reach: 3,          // px: how far the art colour behind a seam is looked for
  residual: 20,      // RGB: a seam pixel further than this from the matte -> art line is no mix of them
  conditioned: 30,   // art this close to the matte colour is not unmixed against (kept opaque)
  floor: 0.04,       // a coverage below this on the matte side is 0
  speck: 24,         // px: detached specks this small outside the art are matte noise
};

const dist = (px, i, c) => Math.hypot(px[i * 4] - c[0], px[i * 4 + 1] - c[1], px[i * 4 + 2] - c[2]);

// 1 the matte colour: per-channel median of the border strip
function matteColour(img, border = MATTE.border) {
  const { w, h, px } = img;
  const ch = [[], [], []];
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    if (x >= border && y >= border && x < w - border && y < h - border) continue;
    const o = (y * w + x) * 4; ch[0].push(px[o]); ch[1].push(px[o + 1]); ch[2].push(px[o + 2]);
  }
  return ch.map((a) => { a.sort((p, q) => p - q); return a[a.length >> 1]; });
}

// connected components of mask (4-connected; eight: 8-connected); labels (0 = not in mask) and the list
function components(mask, w, h, eight = false) {
  const labels = new Int32Array(w * h);
  const stack = new Int32Array(w * h);
  const list = [];
  for (let start = 0; start < w * h; start++) {
    if (!mask[start] || labels[start]) continue;
    const id = list.length + 1;
    let sp = 0; stack[sp++] = start; labels[start] = id;
    const pixels = [];
    let border = false;
    while (sp) {
      const i = stack[--sp]; pixels.push(i);
      const x = i % w; const y = (i - x) / w;
      if (x === 0 || y === 0 || x === w - 1 || y === h - 1) border = true;
      if (x > 0 && mask[i - 1] && !labels[i - 1]) { labels[i - 1] = id; stack[sp++] = i - 1; }
      if (x < w - 1 && mask[i + 1] && !labels[i + 1]) { labels[i + 1] = id; stack[sp++] = i + 1; }
      if (y > 0 && mask[i - w] && !labels[i - w]) { labels[i - w] = id; stack[sp++] = i - w; }
      if (y < h - 1 && mask[i + w] && !labels[i + w]) { labels[i + w] = id; stack[sp++] = i + w; }
      if (eight) {
        for (const j of [y > 0 && x > 0 ? i - w - 1 : -1, y > 0 && x < w - 1 ? i - w + 1 : -1, y < h - 1 && x > 0 ? i + w - 1 : -1, y < h - 1 && x < w - 1 ? i + w + 1 : -1]) {
          if (j >= 0 && mask[j] && !labels[j]) { labels[j] = id; stack[sp++] = j; }
        }
      }
    }
    list.push({ id, pixels, border });
  }
  return { labels, list };
}

// the statistics a candidate hole is judged on
function holeStats(img, comp, labels, matte, o = MATTE.hole) {
  const { w, h, px } = img;
  const s = [0, 0, 0]; const q = [0, 0, 0];
  for (const i of comp.pixels) for (let k = 0; k < 3; k++) { const v = px[i * 4 + k]; s[k] += v; q[k] += v * v; }
  const n = comp.pixels.length;
  const mean = s.map((v) => v / n);
  const sd = Math.max(...q.map((v, k) => Math.sqrt(Math.max(0, v / n - mean[k] * mean[k]))));
  let edges = 0; let hard = 0;
  for (const i of comp.pixels) {
    const x = i % w; const y = (i - x) / w;
    for (const [dx, dy] of [[-1, 0], [1, 0], [0, -1], [0, 1]]) {
      const nx = x + dx; const ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h || labels[ny * w + nx] === comp.id) continue;
      edges++;
      const px2 = x + dx * o.probe; const py2 = y + dy * o.probe;
      if (px2 < 0 || py2 < 0 || px2 >= w || py2 >= h) continue;
      if (dist(px, py2 * w + px2, matte) > o.hard) hard++;
    }
  }
  const offset = Math.hypot(mean[0] - matte[0], mean[1] - matte[1], mean[2] - matte[2]);
  return { area: n, mean, sd, offset, chroma: Math.max(...mean) - Math.min(...mean), hard: edges ? hard / edges : 0 };
}

function isHole(st, o = MATTE.hole) {
  return st.area >= o.minArea && st.sd <= o.maxSd && st.offset <= o.maxOffset && st.chroma <= o.maxChroma && st.hard >= o.minHard;
}

// 2 + 3: background = exterior + accepted holes; also reports what was judged
function segment(img, opts = {}) {
  const o = { ...MATTE, ...opts, hole: { ...MATTE.hole, ...(opts.hole || {}) } };
  const { w, h, px } = img;
  const matte = opts.matte || matteColour(img, o.border);
  const near = new Uint8Array(w * h);
  for (let i = 0; i < w * h; i++) near[i] = dist(px, i, matte) < o.tolerance ? 1 : 0;
  const { labels, list } = components(near, w, h);
  const bg = new Uint8Array(w * h);
  const holes = []; const kept = [];
  let exterior = 0;
  for (const comp of list) {
    if (comp.border) { for (const i of comp.pixels) bg[i] = 1; exterior += comp.pixels.length; continue; }
    if (comp.pixels.length < 16) continue; // single noisy pixels inside the art
    const st = holeStats(img, comp, labels, matte, o.hole);
    const entry = { ...st, x: comp.pixels[0] % w, y: Math.floor(comp.pixels[0] / w), pixels: comp.pixels };
    if (isHole(st, o.hole)) { for (const i of comp.pixels) bg[i] = 1; holes.push(entry); } else kept.push(entry);
  }
  // detached specks of "art" floating in the matte are JPEG noise
  const fg = new Uint8Array(w * h);
  for (let i = 0; i < w * h; i++) fg[i] = bg[i] ? 0 : 1;
  const parts = components(fg, w, h, true).list; // the art is 8-connected (thin diagonal lines stay whole)
  let specks = 0;
  for (const p of parts) if (p.pixels.length <= o.speck) { for (const i of p.pixels) bg[i] = 1; specks += p.pixels.length; }
  holes.sort((a, b) => b.area - a.area); kept.sort((a, b) => b.area - a.area);
  return { matte, bg, exterior, holes, kept, specks, opts: o };
}

// chessboard distance (8-connected) from every pixel to the nearest pixel where mask == target, capped
function distanceTo(mask, target, w, h, cap) {
  const d = new Uint8Array(w * h).fill(cap + 1);
  let queue = [];
  for (let i = 0; i < w * h; i++) if (mask[i] === target) { d[i] = 0; queue.push(i); }
  for (let step = 1; step <= cap && queue.length; step++) {
    const next = [];
    for (const i of queue) {
      const x = i % w; const y = (i - x) / w;
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx; const ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        const j = ny * w + nx;
        if (d[j] > step) { d[j] = step; next.push(j); }
      }
    }
    queue = next;
  }
  return d;
}

const smoothstep = (a, b, x) => { const t = Math.max(0, Math.min(1, (x - a) / (b - a))); return t * t * (3 - 2 * t); };

// 4 + 5: RGBA with real alpha and decontaminated edges
function extract(img, seg) {
  const { w, h, px } = img;
  const o = seg.opts; const { bg, matte } = seg;
  const R = o.window;
  const toBg = distanceTo(bg, 1, w, h, R + 2);  // for art pixels: how far the matte is
  const toFg = distanceTo(bg, 0, w, h, R + 2);  // for matte pixels: how far the art is
  const out = Buffer.alloc(w * h * 4);
  const stats = { band: 0, partial: 0, unmixed: 0, illConditioned: 0 };
  for (let i = 0; i < w * h; i++) {
    const isBg = bg[i] === 1;
    if (isBg ? toFg[i] > 1 : toBg[i] > o.band) {
      if (!isBg) { out[i * 4] = px[i * 4]; out[i * 4 + 1] = px[i * 4 + 1]; out[i * 4 + 2] = px[i * 4 + 2]; out[i * 4 + 3] = 255; }
      continue;
    }
    stats.band++;
    const x = i % w; const y = (i - x) / w;
    // the local matte: the pure matte pixels around
    const bs = [0, 0, 0]; let bn = 0;
    for (let dy = -R; dy <= R; dy++) for (let dx = -R; dx <= R; dx++) {
      const nx = x + dx; const ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      const j = ny * w + nx;
      if (bg[j] && toFg[j] >= 2) { bs[0] += px[j * 4]; bs[1] += px[j * 4 + 1]; bs[2] += px[j * 4 + 2]; bn++; }
    }
    const B = bn ? bs.map((v) => v / bn) : matte;
    const C = [px[i * 4], px[i * 4 + 1], px[i * 4 + 2]];
    const v = [C[0] - B[0], C[1] - B[1], C[2] - B[2]];
    // the art behind the seam: of the deeper art pixels close by, the one that explains this pixel best as a
    // mix with the matte (the smallest distance of C from the line B -> F), the purest when several do -
    // on a thin outline that is the outline, never the fill behind it
    const depth = isBg ? 0 : toBg[i];
    const need = Math.max(2, depth + 1);
    let best = -1; let bestScore = Infinity; let bestA = 0; let bestRes = Infinity;
    for (let dy = -o.reach; dy <= o.reach; dy++) for (let dx = -o.reach; dx <= o.reach; dx++) {
      const nx = x + dx; const ny = y + dy;
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      const j = ny * w + nx;
      if (bg[j] || toBg[j] < need) continue;
      const f0 = px[j * 4] - B[0]; const f1 = px[j * 4 + 1] - B[1]; const f2 = px[j * 4 + 2] - B[2];
      const ff = f0 * f0 + f1 * f1 + f2 * f2;
      if (ff < o.conditioned * o.conditioned) continue;
      let t = (v[0] * f0 + v[1] * f1 + v[2] * f2) / ff;
      t = t < 0 ? 0 : t > 1 ? 1 : t;
      const res = Math.hypot(v[0] - t * f0, v[1] - t * f1, v[2] - t * f2);
      const score = res - 0.05 * Math.sqrt(ff) + 0.5 * Math.hypot(dx, dy);
      if (score < bestScore) { bestScore = score; best = j; bestA = t; bestRes = res; }
    }
    if (best < 0) { // nothing to unmix against: matte stays matte, art stays art
      if (isBg) continue;
      out[i * 4] = C[0]; out[i * 4 + 1] = C[1]; out[i * 4 + 2] = C[2]; out[i * 4 + 3] = 255;
      stats.illConditioned++;
      continue;
    }
    const F = [px[best * 4], px[best * 4 + 1], px[best * 4 + 2]];
    let a = bestA;
    // a pixel that is no mix of the matte and that art (its colour off the line) keeps what it was
    if (bestRes > o.residual) { a = isBg ? 0 : 1; stats.illConditioned++; } else stats.unmixed++;
    if (isBg && a < o.floor) a = 0;
    if (a <= 0) continue;
    let col = C;
    if (a < 1) {
      stats.partial++;
      const est = v.map((vk, k) => Math.max(0, Math.min(255, B[k] + vk / a)));
      const t = smoothstep(0.15, 0.5, a);
      col = est.map((e, k) => F[k] + (e - F[k]) * t);
    }
    out[i * 4] = Math.round(col[0]); out[i * 4 + 1] = Math.round(col[1]); out[i * 4 + 2] = Math.round(col[2]);
    out[i * 4 + 3] = Math.round(a * 255);
  }
  return { w, h, px: out, stats, toBg, toFg };
}

// the outer ring: a circle fitted to the outermost opaque pixel of 1440 rays, protrusions
// (horns, spikes past the ring) rejected; also the radius of everything visible
function ringFit(rgba) {
  const { w, h, px } = rgba;
  let x0 = w; let y0 = h; let x1 = -1; let y1 = -1;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) if (px[(y * w + x) * 4 + 3] > 0) { if (x < x0) x0 = x; if (x > x1) x1 = x; if (y < y0) y0 = y; if (y > y1) y1 = y; }
  let cx = (x0 + x1 + 1) / 2; let cy = (y0 + y1 + 1) / 2;
  const reach = Math.hypot(x1 - x0, y1 - y0);
  const N = 1440;
  const pts = [];
  for (let k = 0; k < N; k++) {
    const t = (2 * Math.PI * k) / N; const dx = Math.cos(t); const dy = Math.sin(t);
    for (let r = reach; r > 0; r -= 0.5) {
      const x = Math.floor(cx + dx * r); const y = Math.floor(cy + dy * r);
      if (x < 0 || y < 0 || x >= w || y >= h) continue;
      if (px[(y * w + x) * 4 + 3] >= 128) { pts.push([cx + dx * r, cy + dy * r]); break; }
    }
  }
  // algebraic circle fit, three rounds, dropping points more than 1.5 % off the circle
  let use = pts; let R = 0;
  for (let round = 0; round < 4; round++) {
    let sx = 0; let sy = 0; let n = use.length;
    for (const [x, y] of use) { sx += x; sy += y; }
    const mx = sx / n; const my = sy / n;
    let suu = 0; let svv = 0; let suv = 0; let suuu = 0; let svvv = 0; let suvv = 0; let svuu = 0;
    for (const [x, y] of use) {
      const u = x - mx; const v = y - my;
      suu += u * u; svv += v * v; suv += u * v; suuu += u * u * u; svvv += v * v * v; suvv += u * v * v; svuu += v * u * u;
    }
    const a1 = (suuu + suvv) / 2; const b1 = (svvv + svuu) / 2;
    const det = suu * svv - suv * suv;
    const uc = (a1 * svv - b1 * suv) / det; const vc = (b1 * suu - a1 * suv) / det;
    cx = uc + mx; cy = vc + my; R = Math.sqrt(uc * uc + vc * vc + (suu + svv) / n);
    use = pts.filter(([x, y]) => Math.abs(Math.hypot(x - cx, y - cy) - R) <= 0.015 * R);
  }
  let maxR = 0;
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) if (px[(y * w + x) * 4 + 3] > 8) { const r = Math.hypot(x + 0.5 - cx, y + 0.5 - cy); if (r > maxR) maxR = r; }
  const protruding = pts.length - use.length;
  return { cx, cy, R, maxR, bounds: { x0, y0, x1: x1 + 1, y1: y1 + 1 }, rays: pts.length, protruding };
}

module.exports = { MATTE, matteColour, components, holeStats, isHole, segment, distanceTo, extract, ringFit };
