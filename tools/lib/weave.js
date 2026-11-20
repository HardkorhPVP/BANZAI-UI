// BANZAI Weave (1.5.1-dev2): the bar texture Darren approved as "Candidate D" - a slashed, brushed surface.
// An original drawing, constructed here from geometry and a fixed number sequence alone. Nothing is read, sampled
// or traced from any image: every texel is the area coverage of the strokes this file lays down.
//
//   construction   a sheet of WIDTH x HEIGHT texels, value 1 (white, tint-neutral), darkened by
//                    - STREAKS broad faint streaks (3 - 6 texels across, value 0.85 - 0.93, 70 - 160 long)
//                    - SLASHES free slashes: roughly a third bold (1.6 - 2.6 across, value 0.28 - 0.50, 34 - 84
//                      long), the rest fine (0.9 - 1.6 across, value 0.48 - 0.72, 16 - 50 long)
//                  every stroke runs DOWN to the right at 0.44 - 0.58 down per texel across (24 - 30 degrees), is
//                  tapered toward both ends, and sits where the number sequence puts it: uneven lengths, weights,
//                  strengths and spacing - no lattice, no counter-direction, no crosshatch. Where strokes overlap the
//                  darker one shows (no blots). No gloss, no bevel, no grain, no colour.
//   seamless       every stroke is drawn wrapped around both edges of the sheet, so the sheet repeats without a seam
//                  in x and in y (tests/test_weave.js draws the same strokes on a larger sheet and compares)
//   deterministic  the number sequence is a fixed-seed generator: the same texels on every build, every machine
//
// One drawing, two encodings (the second is a channel transform of the first, never a second drawing):
//   BanzaiWeave         RGB = the value, alpha 255: a tintable status-bar texture (LibSharedMedia "BANZAI Weave")
//   BanzaiWeaveStrands  RGB = 0, alpha = 255 - value: the same strokes as a layer BANZAI lays over a whole bar - over
//                       its coloured fill and over its dark empty part alike (one material, two brightnesses)
'use strict';

const WEAVE = {
  width: 256, height: 64, // the sheet (powers of two): long enough that its repeat is not seen along a bar
  seed: 0xBA27A1,
  streaks: 26,
  slashes: 120,
  samples: 4,             // 4 x 4 area samples per texel
};

// mulberry32: the same sequence every run
function sequence(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6D2B79F5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// the strokes, in the order they are laid down: { x, y (start), length (along x), slope (down per across),
// width (across, at the middle), depth (how dark), taper (the share of the length each end thins over) }
function strokes(W = WEAVE) {
  const r = sequence(W.seed);
  const list = [];
  for (let i = 0; i < W.streaks; i++) {
    list.push({ x: r() * W.width, y: r() * W.height, length: 70 + r() * 90, slope: 0.46 + r() * 0.10, width: 3 + r() * 3, depth: 0.07 + r() * 0.08, taper: 0.35 });
  }
  for (let i = 0; i < W.slashes; i++) {
    const bold = r() < 0.3;
    list.push({
      x: r() * W.width, y: r() * W.height,
      length: (bold ? 34 : 16) + r() * (bold ? 50 : 34),
      slope: 0.44 + r() * 0.14,
      width: bold ? 1.6 + r() * 1.0 : 0.9 + r() * 0.7,
      depth: bold ? 0.50 + r() * 0.22 : 0.28 + r() * 0.24,
      taper: 0.22 + r() * 0.2,
    });
  }
  return list;
}

// the area-averaged value of every texel of a sheet w x h whose strokes wrap around its edges.
// (w, h default to the sheet; a multiple of it with the strokes repeated draws the same surface in one piece)
function values(W = WEAVE, w = W.width, h = W.height) {
  const dark = new Float64Array(w * h);
  const n = W.samples;
  const all = [];
  for (const s of strokes(W)) {
    for (let oy = 0; oy < h; oy += W.height) for (let ox = 0; ox < w; ox += W.width) all.push({ ...s, x: s.x + ox, y: s.y + oy });
  }
  for (const s of all) {
    const dx = s.length; const dy = s.length * s.slope;
    const len = Math.hypot(dx, dy); const ux = dx / len; const uy = dy / len;
    const pad = Math.ceil(s.width) + 1;
    const x0 = Math.floor(s.x) - pad; const x1 = Math.ceil(s.x + dx) + pad;
    const y0 = Math.floor(s.y) - pad; const y1 = Math.ceil(s.y + dy) + pad;
    for (let py = y0; py <= y1; py++) for (let px = x0; px <= x1; px++) {
      let cover = 0;
      for (let j = 0; j < n; j++) for (let i = 0; i < n; i++) {
        const qx = px + (i + 0.5) / n - s.x; const qy = py + (j + 0.5) / n - s.y;
        const t = (qx * ux + qy * uy) / len; // 0 .. 1 along the stroke
        if (t < 0 || t > 1) continue;
        const thin = Math.min(1, Math.min(t, 1 - t) / s.taper); // thinner toward both ends
        if (Math.abs(qx * uy - qy * ux) <= (s.width / 2) * (0.25 + 0.75 * thin)) cover++;
      }
      if (!cover) continue;
      const o = ((((py % h) + h) % h) * w) + (((px % w) + w) % w);
      dark[o] = Math.max(dark[o], s.depth * cover / (n * n));
    }
  }
  const out = new Float64Array(w * h);
  for (let i = 0; i < w * h; i++) out[i] = 1 - dark[i];
  return out;
}

const byte = (v) => Math.max(0, Math.min(255, Math.round(v * 255)));

// BanzaiWeave: the tintable sheet
function tile(W = WEAVE, w = W.width, h = W.height) {
  const v = values(W, w, h);
  const px = Buffer.alloc(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    const c = byte(v[i]);
    px[i * 4] = c; px[i * 4 + 1] = c; px[i * 4 + 2] = c; px[i * 4 + 3] = 255;
  }
  return { w, h, px };
}

// BanzaiWeaveStrands: the same texels as a layer (black, alpha = 255 - value)
function strands(source) {
  const px = Buffer.alloc(source.w * source.h * 4);
  for (let i = 0; i < source.w * source.h; i++) px[i * 4 + 3] = 255 - source.px[i * 4];
  return { w: source.w, h: source.h, px };
}

function generate() {
  const weave = tile();
  return { BanzaiWeave: weave, BanzaiWeaveStrands: strands(weave) };
}

// the mean value of the sheet (how much the weave darkens a bar overall)
function mean(t) {
  let sum = 0;
  for (let i = 0; i < t.w * t.h; i++) sum += t.px[i * 4];
  return sum / (t.w * t.h * 255);
}

module.exports = { WEAVE, sequence, strokes, values, tile, strands, generate, mean };
