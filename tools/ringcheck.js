#!/usr/bin/env node
// Action-button circles as the game draws them (0.7.0 render check).
//
// The game samples an addon's TGA bilinearly from its full-size level unless
// the texture is set with TRILINEAR (then from mip levels). This script draws
// the ring the way the GPU does at Darren's setup (2560 x 1440, ElvUI UI scale
// 0.71, a 30-unit button = 39.94 px) and compares it with the ideal image (the
// exact coverage of the analytic ring in every screen pixel):
//
//   0.6.0   256 px ring stretched over the button: bilinear, 6.4x shrink
//   0.7.0   64 px canvas sized so one texel lands on one screen pixel
//
// Reported per version: RMS / max alpha error against the ideal and the
// roundness of the outer edge (spread of the radius where alpha crosses 50 %
// over 720 directions). `node tools/ringcheck.js <out dir>` also writes 8x
// enlargements (nearest neighbour, the pixels as they land on screen).
'use strict';

const fs = require('fs');
const path = require('path');
const bamboo = require('./lib/bamboo');
const tga = require('./lib/tga');

const PX_PER_UNIT = 0.71 * 1440 / 768; // Darren: UI scale 0.71 at 1440 lines
const BUTTON_UNITS = 30;

// bilinear sample of an RGBA texture at texel coordinates (u, v), clamp to edge
function bilinear(img, u, v) {
  const x = u - 0.5; const y = v - 0.5;
  const x0 = Math.floor(x); const y0 = Math.floor(y);
  const fx = x - x0; const fy = y - y0;
  const at = (xx, yy) => {
    xx = Math.max(0, Math.min(img.w - 1, xx)); yy = Math.max(0, Math.min(img.h - 1, yy));
    const o = (yy * img.w + xx) * 4;
    return [img.px[o] / 255, img.px[o + 3] / 255];
  };
  const a = at(x0, y0); const b = at(x0 + 1, y0); const c = at(x0, y0 + 1); const d = at(x0 + 1, y0 + 1);
  const mix = (i) => (a[i] * (1 - fx) + b[i] * fx) * (1 - fy) + (c[i] * (1 - fx) + d[i] * fx) * fy;
  return [mix(0), mix(1)];
}

// alpha the screen shows in a w x w pixel window for a texture spanning `span`
// screen pixels, centred on the window centre
function onScreen(img, span, w) {
  const out = new Float32Array(w * w);
  const k = img.w / span; // texels per screen pixel
  for (let y = 0; y < w; y++) for (let x = 0; x < w; x++) {
    const u = (x + 0.5 - w / 2) * k + img.w / 2;
    const v = (y + 0.5 - w / 2) * k + img.h / 2;
    out[y * w + x] = (u < 0 || v < 0 || u > img.w || v > img.h) ? 0 : bilinear(img, u, v)[1];
  }
  return out;
}

// the ideal: exact coverage of the analytic ring in every screen pixel
function ideal(buttonPx, w) {
  const c = w / 2; const R = buttonPx / 2;
  const px = bamboo.renderExact(w, w, bamboo.ringAt(c, c, R), 16);
  const out = new Float32Array(w * w);
  for (let i = 0; i < w * w; i++) out[i] = px[i * 4 + 3] / 255;
  return out;
}

// outer edge radius (alpha crossing 0.5 going outward) in many directions
function roundness(alpha, w, buttonPx) {
  const c = w / 2; const radii = [];
  const sample = (x, y) => {
    const x0 = Math.floor(x - 0.5); const y0 = Math.floor(y - 0.5); const fx = x - 0.5 - x0; const fy = y - 0.5 - y0;
    const at = (xx, yy) => (xx < 0 || yy < 0 || xx >= w || yy >= w ? 0 : alpha[yy * w + xx]);
    return (at(x0, y0) * (1 - fx) + at(x0 + 1, y0) * fx) * (1 - fy) + (at(x0, y0 + 1) * (1 - fx) + at(x0 + 1, y0 + 1) * fx) * fy;
  };
  for (let i = 0; i < 720; i++) {
    const a = (i / 720) * Math.PI * 2;
    let prev = sample(c + Math.cos(a) * buttonPx * 0.43, c + Math.sin(a) * buttonPx * 0.43);
    for (let r = buttonPx * 0.43; r < buttonPx * 0.6; r += 0.02) {
      const s = sample(c + Math.cos(a) * r, c + Math.sin(a) * r);
      if (prev >= 0.5 && s < 0.5) { radii.push(r); break; }
      prev = s;
    }
  }
  const mean = radii.reduce((s, r) => s + r, 0) / radii.length;
  const sd = Math.sqrt(radii.reduce((s, r) => s + (r - mean) ** 2, 0) / radii.length);
  return { mean, sd, spread: Math.max(...radii) - Math.min(...radii), found: radii.length };
}

function compare(alpha, truth) {
  let sum = 0; let max = 0;
  for (let i = 0; i < alpha.length; i++) { const d = alpha[i] - truth[i]; sum += d * d; max = Math.max(max, Math.abs(d)); }
  return { rms: Math.sqrt(sum / alpha.length), max };
}

function run(outDir) {
  const buttonPx = BUTTON_UNITS * PX_PER_UNIT; // 39.94
  const w = 64;
  const truth = ideal(buttonPx, w);
  const old = bamboo.legacyCircles().ring;
  const set = bamboo.BUTTON_SETS[0];
  const textures = bamboo.generate();
  const fresh = textures.BanzaiButtonRing;
  const canvasPx = BUTTON_UNITS * (set.canvas / set.design) * PX_PER_UNIT; // what ActionButtons.lua sizes it to
  const versions = {
    '0.6.0': onScreen(old, buttonPx, w),
    '0.7.0': onScreen(fresh, canvasPx, w),
  };
  const report = { buttonPx, canvasPx, versions: {} };
  for (const [name, alpha] of Object.entries(versions)) {
    report.versions[name] = { ...compare(alpha, truth), ...roundness(alpha, w, buttonPx) };
  }
  report.ideal = roundness(truth, w, buttonPx);
  if (outDir) {
    fs.mkdirSync(outDir, { recursive: true });
    const Z = 8; const tiles = [['ideal', truth], ...Object.entries(versions)];
    const W = w * Z * tiles.length + 8 * (tiles.length - 1); const H = w * Z;
    const img = Buffer.alloc(W * H * 4);
    tiles.forEach(([, alpha], t) => {
      for (let y = 0; y < H; y++) for (let x = 0; x < w * Z; x++) {
        const a = alpha[Math.floor(y / Z) * w + Math.floor(x / Z)];
        const gx = x / (w * Z); // green -> purple across the tile, like the Banzai ring
        const col = [0.62 * (1 - gx) + 0.62 * gx, 1.0 * (1 - gx) + 0.1 * gx, 0.12 * (1 - gx) + 0.86 * gx];
        const o = (y * W + t * (w * Z + 8) + x) * 4;
        const bg = 0.16; // dark game scene
        for (let i = 0; i < 3; i++) img[o + i] = Math.round(255 * (bg * (1 - a) + col[i] * a));
        img[o + 3] = 255;
      }
    });
    tga.writePNG(path.join(outDir, 'ringcheck_8x.png'), W, H, img);
  }
  return report;
}

module.exports = { run, PX_PER_UNIT };

if (require.main === module) {
  const report = run(process.argv[2]);
  console.log(`button ${report.buttonPx.toFixed(2)} px, 0.7.0 canvas ${report.canvasPx.toFixed(2)} px`);
  for (const [name, r] of Object.entries(report.versions)) {
    console.log(`${name}: alpha error rms ${r.rms.toFixed(4)} max ${r.max.toFixed(3)}; outer edge radius ${r.mean.toFixed(2)} px, sd ${r.sd.toFixed(3)} px, spread ${r.spread.toFixed(3)} px (${r.found} directions)`);
  }
  console.log(`ideal: outer edge radius ${report.ideal.mean.toFixed(2)} px, sd ${report.ideal.sd.toFixed(3)} px, spread ${report.ideal.spread.toFixed(3)} px`);
}
