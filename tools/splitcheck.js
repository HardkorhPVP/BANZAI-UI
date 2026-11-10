#!/usr/bin/env node
// BANZAI 1.3.0 offline preview: draws the BANZAI SPLIT frames (Player idle /
// casting / channeling / low health and resources, Target player / NPC /
// casting, Focus, ToT, DPS / HEALER party, the enhanced targeted nameplate),
// the whole lower / upper screen composition and the BANZAI CURRENT /
// COMPACT Details rows on glass and parchment - at Darren's pixel scale
// (2560 x 1440, UI scale 0.71), from the numbers in the built addons and the
// generated Banzai textures; the text layer with the real Banzai fonts
// (tools/lib/textdraw.ps1). The Fabled class art comes from the installed
// Jiberish Icons for this local check only (never copied anywhere); spell
// icons are drawn stand-ins.
// 1.3.2: the hubs and party circles show Darren's original BANZAI class art from the
// built media (as the game draws the 256 px texture: its mip-maps, trilinear), where
// Banzai Art uses it (Identity.BANZAI_MIN; never the nameplate hub or the Details rows).
// 1.3.3: the Player / Target hubs at 125 % with the spell icon alone in them while a cast
// shows, the bamboo cast bar (the built panel stalk / stalk-end / rope textures, the
// BANZAI panel colours) above the values: cast, channel, locked, interrupted; the
// TARGET NPC preview sample with Banzai's crest; sheet split-cast.png.
//   node tools/splitcheck.js [outDir]
'use strict';

const fs = require('fs');
const path = require('path');
const { execFileSync } = require('child_process');
const tga = require('./lib/tga');
const { noise } = require('./lib/bamboo');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');
const MEDIA = path.join(DIST, 'BushidoPrivateCompat', 'media');
const OUT = process.argv[2] || path.join(ROOT, 'build', 'splitcheck');
const JI = 'D:\\Program Files (x86)\\World of Warcraft\\_retail_\\Interface\\AddOns\\JiberishIcons\\Media\\Class\\fabledclass.tga';
const PX = 0.71 * 1440 / 768; // screen pixels per UI unit
fs.mkdirSync(OUT, { recursive: true });

// ---- the numbers, read from the built code (the same the game uses)
const splitLua = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Split.lua'), 'utf8');
const themeLua = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Theme.lua'), 'utf8');
const unit = (k) => {
  const m = splitLua.match(new RegExp('\\t' + k + " = \\{ frame = '[^']+', unit = '\\w+', bar = (\\d+), height = (\\d+)(?:, powerHeight = (\\d+))?, hub = (\\d+), name = (\\d+), cast = (\\d+), value = (\\d+), percent = (\\d+)"));
  return { bar: +m[1], height: +m[2], powerHeight: +(m[3] || m[2]), hub: +m[4], name: +m[5], cast: +m[6], value: +m[7], percent: +m[8] };
};
const U = { player: unit('player'), target: unit('target'), focus: unit('focus') };
// 1.3.3 the identity factor and the cast bar numbers on the entry's second line
for (const k of ['player', 'target']) {
  const body = (splitLua.match(new RegExp('\\t' + k + " = \\{ frame = [^\\n]*\\n\\t\\t([^\\n]*)")) || [])[1] || '';
  for (const key of ['identity', 'castInterior', 'castStalk', 'castValues', 'castName', 'castTime']) U[k][key] = Number((body.match(new RegExp(key + ' = ([\\d.]+)')) || [])[1]);
}
const CAST_BAR = { inner: Number((splitLua.match(/Split\.CAST_BAR = \{ inner = ([\d.]+)/) || [])[1]), gap: Number((splitLua.match(/Split\.CAST_BAR = \{[^}]*gap = ([\d.]+)/) || [])[1]) };
const castLua = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'CastBar.lua'), 'utf8');
const SHAPE = Object.fromEntries([...((castLua.match(/CastBar\.SHAPE = \{([^}]*)\}/) || [])[1] || '').matchAll(/(\w+) = ([\d.]+)/g)].map((m) => [m[1], Number(m[2])]));
const LOCK_VEIL = Number((castLua.match(/CastBar\.LOCK_VEIL = ([\d.]+)/) || [])[1]);
const TUCK = Number((splitLua.match(/Split\.TUCK = ([\d.]+)/) || [])[1]);
const LINE_GAP = Number((splitLua.match(/Split\.LINE_GAP = (\d+)/) || [])[1]);
const PARTY_CIRCLE = Number((splitLua.match(/Split\.PARTY = \{ circle = (\d+)/) || [])[1]);
const num = (re) => Number((themeLua.match(re) || [])[1]);
const POS = { px: num(/splitPlayerX = (-?\d+)/), py: num(/splitPlayerY = (\d+)/), tx: num(/splitTargetX = (-?\d+)/), ty: num(/splitTargetY = (\d+)/) };
const geo = (k) => {
  const d = U[k]; const hub = d.hub * (d.identity || 1); const tuck = Math.round(hub * TUCK); const inner = Math.round(hub / 2 - tuck);
  const g = { ...d, hub, tuck, inner };
  if (d.castInterior) { // 1.3.3: Split.Geometry's cast bar
    g.castHeight = d.castInterior + 2 * CAST_BAR.inner * d.castStalk;
    g.castWidth = 2 * (inner + d.bar);
    g.castLift = Math.max(Math.round(d.height / 2) + d.castValues, hub / 2) + CAST_BAR.gap;
  }
  return g;
};
const C = { lime: [0.62, 1.00, 0.12], emerald: [0.00, 0.90, 0.42], violet: [0.56, 0.22, 1.00], purple: [0.62, 0.10, 0.86] };
// 1.3.1 the split colour family (Theme.Ramp, its numbers read from Theme.lua)
const RAMP = { shift: num(/Theme\.RAMP = \{ shift = ([\d.]+)/), light: num(/Theme\.RAMP = \{[^}]*light = ([\d.]+)/), saturation: num(/Theme\.RAMP = \{[^}]*saturation = ([\d.]+)/), deep: num(/Theme\.RAMP = \{[^}]*deep = ([\d.]+)/) };
function toHSV([r, g, b]) { const max = Math.max(r, g, b); const min = Math.min(r, g, b); const d = max - min; let h = 0; if (d > 0) { if (max === r) h = 60 * ((((g - b) / d) % 6 + 6) % 6); else if (max === g) h = 60 * ((b - r) / d + 2); else h = 60 * ((r - g) / d + 4); } return [h, max > 0 ? d / max : 0, max]; }
function fromHSV(h, s, v) { h = ((h % 360) + 360) % 360; const c = v * s; const x = c * (1 - Math.abs((h / 60) % 2 - 1)); const m = v - c; const [r, g, b] = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x]; return [r + m, g + m, b + m]; }
function ramp(c) {
  const [h, s, v] = toHSV(c);
  const mixW = (a, t) => [a[0] + (1 - a[0]) * t, a[1] + (1 - a[1]) * t, a[2] + (1 - a[2]) * t];
  if (s < 0.08) return { bright: mixW(c, 0.5), base: c, deep: [v * 0.56, v * 0.58, v * 0.62] };
  const ty = ((60 - h + 540) % 360) - 180; const dir = ty >= 0 ? 1 : -1;
  return { bright: mixW(fromHSV(h + dir * Math.min(RAMP.shift, Math.abs(ty)), s * RAMP.saturation, Math.min(1, v * 1.12)), RAMP.light), base: c, deep: fromHSV(h - dir * RAMP.shift, Math.min(1, s * 1.04), v * RAMP.deep) };
}
const NAME_STOPS = [C.lime, C.emerald, C.violet, C.purple];
function rampCols(text, stops) { const n = text.length; return [...text].map((_, i) => { const p = n > 1 ? i / (n - 1) : 0; const seg = Math.min(stops.length - 2, Math.floor(p * (stops.length - 1))); return mix(stops[seg], stops[seg + 1], p * (stops.length - 1) - seg); }); }
const CAST = { cast: [1.00, 0.70, 0.00], channel: [0.00, 0.90, 0.42], empower: [0.56, 0.22, 1.00], lock: [0.46, 0.44, 0.56], fail: [0.95, 0.20, 0.18] };
const CLASS = { DRUID: [1.0, 0.49, 0.04], MAGE: [0.25, 0.78, 0.92], ROGUE: [1.0, 0.96, 0.41], PRIEST: [1, 1, 1], SHAMAN: [0.0, 0.44, 0.87], WARRIOR: [0.78, 0.61, 0.43],
  HUNTER: [0.67, 0.83, 0.45], PALADIN: [0.96, 0.55, 0.73], WARLOCK: [0.53, 0.53, 0.93], DEATHKNIGHT: [0.77, 0.12, 0.23], MONK: [0.0, 1.0, 0.6], DEMONHUNTER: [0.64, 0.19, 0.79], EVOKER: [0.2, 0.58, 0.5] };
const JI_CELL = { WARRIOR: [0, 0], MAGE: [1, 0], ROGUE: [2, 0], DRUID: [3, 0], EVOKER: [4, 0], HUNTER: [0, 1], SHAMAN: [1, 1], PRIEST: [2, 1], WARLOCK: [3, 1], PALADIN: [0, 2], DEATHKNIGHT: [1, 2], MONK: [2, 2], DEMONHUNTER: [3, 2] };
const HOSTILE = [0.94, 0.16, 0.14];
const mix = (a, b, t) => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
const clamp = (v) => Math.max(0, Math.min(1, v));

// ---- textures
const tex = {};
for (const n of ['BanzaiHubDisc', 'BanzaiHubRing', 'BanzaiHubAccent', 'BanzaiHubMask', 'BanzaiHubSwipe', 'BanzaiBar', 'BanzaiClassDiscs', 'BanzaiParchmentTile', 'BanzaiStalk', 'BanzaiStalkEnd', 'BanzaiRopeTie', 'BanzaiHubCrest']) tex[n] = tga.read(path.join(MEDIA, n + '.tga'));
const fabled = fs.existsSync(JI) ? tga.read(JI) : null;
// 1.3.2 the BANZAI class art the build shipped (IdentityManifest.lua) and where Banzai Art uses it
const identityLua = fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Identity.lua'), 'utf8');
const BANZAI_MIN = Number((identityLua.match(/Identity\.BANZAI_MIN = (\d+)/) || [])[1]);
const ART_FULL = Number((identityLua.match(/Identity\.HUB = \{[^}]*art = ([\d.]+)/) || [])[1]); // 1.3.3: a bar hub's BANZAI art
const banzaiListed = [...fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'IdentityManifest.lua'), 'utf8').matchAll(/\t\t([A-Z]+) = '([a-z]+)'/g)].map((m) => m[1]);
const banzaiViews = {};
function banzaiArt(cls, px) {
  if (!banzaiListed.includes(cls)) return null;
  const key = cls + '@' + Math.round(px);
  if (!banzaiViews[key]) banzaiViews[key] = require('./lib/iconqa').gameView(tga.read(path.join(MEDIA, 'BanzaiIdentity', cls.toLowerCase() + '.tga')), Math.round(px));
  return banzaiViews[key];
}
function sample(t, u, v) { // bilinear, clamped; u, v 0..1
  const x = clamp(u) * t.w - 0.5; const y = clamp(v) * t.h - 0.5;
  const x0 = Math.max(0, Math.min(t.w - 1, Math.floor(x))); const y0 = Math.max(0, Math.min(t.h - 1, Math.floor(y)));
  const x1 = Math.min(t.w - 1, x0 + 1); const y1 = Math.min(t.h - 1, y0 + 1);
  const fx = Math.max(0, Math.min(1, x - x0)); const fy = Math.max(0, Math.min(1, y - y0));
  const out = [0, 0, 0, 0];
  for (let c = 0; c < 4; c++) {
    const p = (xx, yy) => t.px[(yy * t.w + xx) * 4 + c];
    out[c] = ((p(x0, y0) * (1 - fx) + p(x1, y0) * fx) * (1 - fy) + (p(x0, y1) * (1 - fx) + p(x1, y1) * fx) * fy) / 255;
  }
  return out;
}

// ---- canvas
class Canvas {
  constructor(w, h) { this.w = Math.round(w); this.h = Math.round(h); this.px = new Float32Array(this.w * this.h * 3); this.texts = []; }
  put(x, y, c, a) {
    if (x < 0 || y < 0 || x >= this.w || y >= this.h || a <= 0) return;
    const o = (y * this.w + x) * 3;
    for (let k = 0; k < 3; k++) this.px[o + k] = this.px[o + k] * (1 - a) + c[k] * a;
  }
  // fn(u, v, sx, sy) -> [r, g, b, a] over the rectangle (px), 3 x 3 samples per pixel at the edges
  region(x0, y0, x1, y1, fn) {
    const ss = 3;
    for (let y = Math.floor(y0); y < Math.ceil(y1); y++) for (let x = Math.floor(x0); x < Math.ceil(x1); x++) {
      let r = 0; let g = 0; let b = 0; let a = 0;
      for (let j = 0; j < ss; j++) for (let i = 0; i < ss; i++) {
        const sx = x + (i + 0.5) / ss; const sy = y + (j + 0.5) / ss;
        if (sx < x0 || sx > x1 || sy < y0 || sy > y1) continue;
        const c = fn((sx - x0) / (x1 - x0), (sy - y0) / (y1 - y0), sx, sy);
        if (!c || c[3] <= 0) continue;
        r += c[0] * c[3]; g += c[1] * c[3]; b += c[2] * c[3]; a += c[3];
      }
      if (a > 0) this.put(x, y, [r / a, g / a, b / a], a / (ss * ss));
    }
  }
  text(op) { this.texts.push(op); }
  save(name) {
    const base = path.join(OUT, name + '.base.png');
    const buf = Buffer.alloc(this.w * this.h * 4);
    for (let i = 0; i < this.w * this.h; i++) { for (let k = 0; k < 3; k++) buf[i * 4 + k] = Math.round(clamp(this.px[i * 3 + k]) * 255); buf[i * 4 + 3] = 255; }
    tga.writePNG(base, this.w, this.h, buf);
    const scene = path.join(OUT, name + '.json');
    fs.writeFileSync(scene, JSON.stringify({ base, out: path.join(OUT, name + '.png'), fonts: { small: path.join(DIST, 'JiberishMedia', 'font', 'Rubik-Bold.ttf'), display: path.join(MEDIA, 'fonts', 'Shojumaru-Regular.ttf'), previous: path.join(DIST, 'JiberishMedia', 'font', 'GasoekOne.ttf') }, ops: this.texts }));
    execFileSync('pwsh', ['-NoProfile', '-File', path.join(__dirname, 'lib', 'textdraw.ps1'), scene], { stdio: 'inherit' });
    fs.unlinkSync(base); fs.unlinkSync(scene);
    return path.join(OUT, name + '.png');
  }
}

// a dark dungeon-like floor (the contrast the frames are read against in play)
function scene(cv, seed = 0) {
  cv.region(0, 0, cv.w, cv.h, (u, v, x, y) => {
    const n = noise(x / 60 + seed, y / 60) * 0.6 + noise(x / 13, y / 13 + seed) * 0.4;
    return [0.07 + 0.06 * n, 0.06 + 0.04 * n, 0.10 + 0.07 * n, 1];
  });
}

// ---- the WoW pieces, in units at (ox, oy) = a pixel origin
const U2 = (v) => v * PX;
function gradientAt(from, to, t) { return mix(from, to, clamp(t)); }
// a texture with a vertex gradient (HORIZONTAL: from left; VERTICAL: from bottom - as the game paints it)
function drawTex(cv, t, x0, y0, w, h, opts = {}) {
  const { from = [1, 1, 1], to = from, orient = 'HORIZONTAL', alpha = 1, coords = [0, 1, 0, 1], mask } = opts;
  cv.region(x0, y0, x0 + w, y0 + h, (u, v, sx, sy) => {
    const s = sample(t, coords[0] + (coords[1] - coords[0]) * u, coords[2] + (coords[3] - coords[2]) * v);
    const col = gradientAt(from, to, orient === 'HORIZONTAL' ? u : 1 - v);
    let a = s[3] * alpha;
    if (mask) a *= mask(sx, sy);
    return [s[0] * col[0], s[1] * col[1], s[2] * col[2], a];
  });
}
function solid(cv, x0, y0, w, h, c, a = 1) { cv.region(x0, y0, x0 + w, y0 + h, () => [c[0], c[1], c[2], a]); }
function trough(cv, x0, y0, w, h) { cv.region(x0, y0, x0 + w, y0 + h, (u, v) => [...gradientAt([0.010, 0.026, 0.020], [0.045, 0.080, 0.064], 1 - v), 0.94]); }
function border(cv, x0, y0, w, h, c = [0, 0, 0], a = 0.9) { solid(cv, x0 - 1, y0 - 1, w + 2, 1, c, a); solid(cv, x0 - 1, y0 + h, w + 2, 1, c, a); solid(cv, x0 - 1, y0, 1, h, c, a); solid(cv, x0 + w, y0, 1, h, c, a); }

// letters of a gradient text (per-letter colours, as Theme:GradientText / Eltruism's gradient names)
function grad(text, from, to) { const n = text.length; return [...text].map((_, i) => mix(from, to, n > 1 ? i / (n - 1) : 0)); }
function label(cv, text, x, y, anchor, size, opts = {}) {
  cv.text({ text, x, y, anchor, size: U2(size), font: opts.font || 'small', color: opts.color || [1, 1, 1], colors: opts.colors, alpha: opts.alpha, outline: opts.outline !== false, shadow: opts.shadow !== false, clip: opts.clip });
}

// a split bar: track, fill (the Banzai texture under the class / resource gradient), ElvUI's 1 px border
function bar(cv, x0, y0, w, h, value, colors) {
  trough(cv, x0, y0, w, h);
  const fw = w * value;
  if (fw > 0) drawTex(cv, tex.BanzaiBar, x0, y0, fw, h, { from: colors[0], to: colors[1], alpha: 0.94, coords: [0, value, 0, 1] });
  border(cv, x0, y0, w, h, [0, 0, 0], 0.85);
  return { x0, y0, w, h, fx: x0 + fw };
}
function classPair(c) { return [[c[0] * 0.55, c[1] * 0.55, c[2] * 0.55], mix(c, [1, 1, 1], 0.22)]; }

// 1.3.1 a Player / Target split bar: the family's gradient on the fill (as the live overlay, anchored to it), opaque
function barFull(cv, x0, y0, w, h, value, colors) {
  trough(cv, x0, y0, w, h);
  const fw = w * value;
  if (fw > 0) drawTex(cv, tex.BanzaiBar, x0, y0, fw, h, { from: colors[0], to: colors[1], alpha: 1 });
  border(cv, x0, y0, w, h, [0, 0, 0], 0.85);
  return { x0, y0, w, h, fx: x0 + fw };
}

// HP / resource inside a bar: value at the outer end, percent beside the hub; bright over the fill, ghosted elsewhere
// (1.3.1: Focus / party / plates - their numbers keep the previous display font)
function inside(cv, b, value, percent, side, d, gapPx, edge = 6) {
  const y = b.y0 + b.h / 2;
  const vx = side === 'LEFT' ? b.x0 + U2(edge) : b.x0 + b.w - U2(edge);
  const px = side === 'LEFT' ? b.x0 + b.w - gapPx : b.x0 + gapPx;
  const lime = C.lime;
  const clip = [b.x0, b.y0 - 20, b.fx, b.y0 + b.h + 20];
  for (const [ghost, c] of [[true, null], [false, clip]]) {
    const a = ghost ? 0.62 : 1; // Health.SPLIT_GHOST_ALPHA
    if (value) label(cv, value, vx, y, side, d.value, { font: 'previous', alpha: a, clip: c || undefined });
    if (percent) label(cv, percent, px, y, side === 'LEFT' ? 'RIGHT' : 'LEFT', d.percent, { color: lime, alpha: a, clip: c || undefined });
  }
}

// 1.3.1 Player / Target values ABOVE a bar: the value over the outer end (Want Coffee), the percent over the inner end clear of the hub (small font)
function above(cv, b, value, percent, side, d, gapPx) {
  const y = b.y0 - U2(2);
  const vx = side === 'LEFT' ? b.x0 : b.x0 + b.w;
  const px = side === 'LEFT' ? b.x0 + b.w - gapPx : b.x0 + gapPx;
  if (value) label(cv, value, vx, y, 'BOTTOM' + side, d.value, { font: 'display', color: [1, 1, 1] });
  if (percent) label(cv, percent, px, y, 'BOTTOM' + (side === 'LEFT' ? 'RIGHT' : 'LEFT'), d.percent, { color: C.lime });
}

// the hub: disc, icon (Fabled cell / stand-in / glyph / portrait), ring, accent; casting: spell, track, progress, lock; name above
function hub(cv, cx, cy, sizeU, o = {}) {
  const size = U2(sizeU); const canvas = size * 128 / 120;
  const x0 = cx - canvas / 2; const y0 = cy - canvas / 2;
  drawTex(cv, tex.BanzaiHubDisc, x0, y0, canvas, canvas, { from: [0.01, 0.03, 0.02], to: [0.04, 0.08, 0.06], orient: 'VERTICAL', alpha: 0.94 });
  const icon = size * 0.80; const ix = cx - icon / 2; const iy = cy - icon / 2;
  const mask = (sx, sy) => sample(tex.BanzaiHubMask, (sx - x0) / canvas, (sy - y0) / canvas)[3];
  const ring = o.ring || [1, 1, 1];
  if (o.spell) {
    cv.region(ix, iy, ix + icon, iy + icon, (u, v, sx, sy) => [...o.spell(u, v), mask(sx, sy)]);
  } else if (o.class && !o.plate && sizeU * 0.80 >= BANZAI_MIN && banzaiArt(o.class, icon)) {
    if (o.bar) { // 1.3.3: a bar hub - the art at full size (Identity.HUB.art), its own transparency and bamboo ring
      const a = size * ART_FULL; o.fullArt = true;
      drawTex(cv, banzaiArt(o.class, a), cx - a / 2, cy - a / 2, a, a);
    } else drawTex(cv, banzaiArt(o.class, icon), ix, iy, icon, icon, { mask });
  } else if (o.class && fabled) {
    const [cxl, cyl] = JI_CELL[o.class];
    drawTex(cv, fabled, ix, iy, icon, icon, { coords: [cxl * 0.125, (cxl + 1) * 0.125, cyl * 0.125, (cyl + 1) * 0.125], mask });
  } else if (o.crest) { // 1.3.3: the TARGET NPC preview sample - Banzai's crest
    drawTex(cv, tex.BanzaiHubCrest, ix, iy, icon, icon, { mask });
  } else if (o.portrait) {
    cv.region(ix, iy, ix + icon, iy + icon, (u, v, sx, sy) => [...o.portrait(u, v), mask(sx, sy)]);
  } else if (o.glyph) {
    cv.region(ix, iy, ix + icon, iy + icon, (u, v, sx, sy) => [...gradientAt(mix([0, 0, 0], ring, 0.55), mix(ring, [1, 1, 1], 0.18), 1 - v), mask(sx, sy)]);
    label(cv, o.glyph, cx, cy, 'CENTER', sizeU * 0.42 * 0.82, { font: 'previous' });
  }
  const ringAlpha = o.cast && o.timed !== false && !o.bar ? 0.35 : 1;
  const rc = o.bar ? ring : (o.fail ? CAST.fail : (o.cast && o.timed === false ? CAST[o.cast] : ring));
  if (!o.fullArt) drawTex(cv, tex.BanzaiHubRing, x0, y0, canvas, canvas, { from: [rc[0] * 0.62, rc[1] * 0.62, rc[2] * 0.62], to: mix(rc, [1, 1, 1], 0.3), orient: 'VERTICAL', alpha: ringAlpha }); // 1.3.3: not round the full BANZAI art
  const ac = o.accent;
  if (!o.noAccent) drawTex(cv, tex.BanzaiHubAccent, x0, y0, canvas, canvas, ac ? { from: ac.map((c) => c * 0.6), to: ac, orient: 'VERTICAL' } : { from: C.violet, to: C.lime, orient: 'VERTICAL', alpha: 0.9 });
  if (o.cast && o.timed !== false && !o.bar) {
    drawTex(cv, tex.BanzaiHubSwipe, x0, y0, canvas, canvas, { from: [0.03, 0.04, 0.04], to: [0.08, 0.09, 0.09], orient: 'VERTICAL', alpha: 0.92 });
    // the game's swipe: clockwise from 12 o'clock; a cast covers what has elapsed, a channel what remains
    const done = o.progress;
    const sector = (sx, sy) => {
      let ang = Math.atan2(sx - cx, -(sy - cy)) / (2 * Math.PI); if (ang < 0) ang += 1;
      return o.cast === 'cast' ? (ang <= done ? 1 : 0) : (ang >= done ? 1 : 0);
    };
    const pc = CAST[o.cast];
    drawTex(cv, tex.BanzaiHubSwipe, x0, y0, canvas, canvas, { from: pc, to: pc, mask: sector });
    if (o.lock) { // the steel border round the hub (the accent band and a halo just outside it) and a small shield, upper right
      const lc = { from: CAST.lock.map((c) => c * 0.75), to: mix(CAST.lock, [1, 1, 1], 0.35), orient: 'VERTICAL' };
      drawTex(cv, tex.BanzaiHubAccent, x0, y0, canvas, canvas, lc);
      const hc = canvas * 1.07; drawTex(cv, tex.BanzaiHubAccent, cx - hc / 2, cy - hc / 2, hc, hc, lc);
      const sx = cx + size * 0.38; const sy = cy - size * 0.36; const sr = size * 0.17;
      cv.region(sx - sr, sy - sr, sx + sr, sy + sr, (u, v) => { const inS = Math.abs(u - 0.5) < 0.42 - 0.3 * Math.max(0, v - 0.45) && v > 0.06 && v < 0.98; return inS ? [...(Math.abs(u - 0.5) < 0.3 - 0.3 * Math.max(0, v - 0.5) && v > 0.18 && v < 0.88 ? [0.72, 0.72, 0.78] : [0.15, 0.15, 0.18]), 1] : null; });
    }
  }
  if (o.castName && !o.bar) { // 1.3.1: the spell name in the display font, the timer in the small font
    const top = cy - size / 2 - U2(3);
    label(cv, o.castName, cx, top, 'BOTTOM', o.castSize || 11, { color: o.fail ? CAST.fail : [1, 1, 1], font: o.plate ? 'small' : 'display' });
    if (o.castTime) label(cv, o.castTime, cx + o.castName.length * U2(o.castSize || 11) * (o.plate ? 0.36 : 0.25) + U2(4), top - U2(o.castSize || 11) / 2, 'LEFT', Math.max(8, (o.castSize || 11) - 2), { color: C.lime });
  }
  return { cx, cy, size };
}

// 1.3.3 the bamboo cast bar (CastBar.lua): interior, fill, edge, lock, interrupted, the panel bamboo, the texts;
// (cx, bottom) px: its bottom centre; g: geo(k); c: { kind, value, ramp, lock, interrupted, name, time }
const STALKS = { top: [0.58, 0.93, 0.22], right: [0.44, 0.86, 0.28], bottom: [0.52, 0.90, 0.20], left: [0.36, 0.84, 0.34] }; // Theme BANZAI_STALKS
const stalkAt = (st, p, vary) => { const b = STALKS[st]; const k = 0.92 + 0.10 * p + 0.05 * (vary - 0.5); return b.map((x) => Math.min(1, x * k)); }; // Theme:PanelStalk BANZAI
const ROPE = [C.violet, C.purple]; // VIBRANT_TIE
function castBar(cv, cx, bottom, g, c) {
  const W = U2(g.castWidth); const H = U2(g.castHeight); const d = U2(g.castStalk); const x0 = cx - W / 2; const y0 = bottom - H;
  const inset = (H - U2(g.castInterior)) / 2;
  const ix = x0 + inset; const iy = y0 + inset; const iw = W - 2 * inset; const ih = H - 2 * inset;
  cv.region(ix, iy, ix + iw, iy + ih, (u, v) => [...mix([0.010, 0.030, 0.022], [0.040, 0.075, 0.058], 1 - v), 0.82]);
  if (c.interrupted) {
    const red = [0.82, 0.06, 0.22];
    drawTex(cv, tex.BanzaiBar, ix, iy, iw, ih, { from: red.map((x) => x * 0.55), to: red });
  } else if (c.value !== undefined) {
    const fw = iw * c.value; const r = c.ramp;
    const [from, to] = c.kind === 'channel' ? [r.bright, r.base] : [r.deep, r.bright];
    if (fw > 0) {
      drawTex(cv, tex.BanzaiBar, ix, iy, fw, ih, { from, to });
      solid(cv, ix + fw - U2(SHAPE.spark) / 2, iy, U2(SHAPE.spark), ih, mix(r.bright, [1, 1, 1], 0.55), 0.9);
    }
    if (c.lock) { solid(cv, ix, iy, iw, ih, CAST.lock, LOCK_VEIL); solid(cv, ix, iy, iw, U2(SHAPE.lock), CAST.lock, 1); }
  }
  cv.region(ix, iy + ih - U2(SHAPE.accent), ix + iw, iy + ih, (u) => [...mix(C.lime, C.violet, u), 0.9]);
  // the bamboo: the panel's construction at the bar's scale
  const strip = (128 / 88) * d; const tip = (256 / 88) * d; const axis = SHAPE.axis * d; const period = 3.6 * d;
  let n0 = 0; const vary = () => ((n0++ * 7919) % 97) / 97;
  const piece = (st, horizontal, path, a, b, at, u0, u1, flip, len) => {
    const v0 = vary();
    const ca = stalkAt(st, a / len, v0); const cb = stalkAt(st, Math.min(1, b / len), v0);
    if (horizontal) drawTex(cv, path, x0 + a, y0 + at - strip / 2, b - a, strip, { from: ca, to: cb, coords: flip ? [u1, u0, 0, 1] : [u0, u1, 0, 1] });
    else {
      // a vertical piece: the texture turned (U along y)
      const t = path; const px0 = x0 + at - strip / 2; const py0 = y0 + a; const pw = strip; const ph = b - a;
      cv.region(px0, py0, px0 + pw, py0 + ph, (u, v) => { const uu = flip ? u1 + (u0 - u1) * v : u0 + (u1 - u0) * v; const s0 = sample(t, uu, u); const col = mix(ca, cb, v); return [s0[0] * col[0], s0[1] * col[1], s0[2] * col[2], s0[3]]; });
    }
  };
  for (const [st, at] of [['bottom', H - axis], ['top', axis]]) {
    const n = Math.max(1, Math.round(W / period)); const seg = W / n;
    for (let i = 0; i < n; i++) { const k = i % 4; piece(st, true, tex.BanzaiStalk, i * seg, (i + 1) * seg + (i < n - 1 ? 0.3 : 0), at, k / 4, (k + 1) / 4, false, W); }
  }
  const gap = 6 / 512; const cutU = [0, 0.5 - gap]; const plainU = [0.5 + gap, 1];
  for (const [st, at, cutTop] of [['left', axis, true], ['right', W - axis, false]]) {
    const first = cutTop ? cutU : plainU; const last = cutTop ? plainU : cutU;
    piece(st, false, tex.BanzaiStalkEnd, 0, tip, at, first[0], first[1], true, H);
    if (H - tip > tip) piece(st, false, tex.BanzaiStalk, tip, H - tip + 0.3, at, 0, (H - 2 * tip) / (period * 4), false, H);
    piece(st, false, tex.BanzaiStalkEnd, Math.max(tip, H - tip), H, at, last[0], last[1], false, H);
  }
  const ts = SHAPE.tie * d; const cc = Math.max(axis, ts * 0.30);
  for (const [tx, ty, mirror] of [[cc, cc, false], [W - cc, cc, true], [cc, H - cc, false], [W - cc, H - cc, true]]) {
    drawTex(cv, tex.BanzaiRopeTie, x0 + tx - ts / 2, y0 + ty - ts / 2, ts, ts, { from: ROPE[1], to: ROPE[0], orient: 'VERTICAL', coords: mirror ? [1, 0, 0, 1] : [0, 1, 0, 1] });
  }
  // the texts: the spell name centred (Want Coffee, off-white / cyan), the timer right-aligned (small font, lime)
  const right = U2(SHAPE.tie * g.castStalk * 0.65 + SHAPE.pad);
  if (c.name) label(cv, c.name, cx, y0 + H / 2, 'CENTER', g.castName, { font: 'display', color: c.interrupted ? [0.30, 0.90, 1.00] : [0.96, 0.95, 0.90] });
  if (c.time) label(cv, c.time, x0 + W - right, y0 + H / 2, 'RIGHT', g.castTime, { color: C.lime });
  return { x0, y0, W, H };
}

// a spell-icon stand-in (procedural: the preview has no game files)
const SPELLS = {
  lava: (u, v) => { const n = noise(u * 6, v * 6); return [0.95, 0.35 + 0.4 * n * (1 - v), 0.05 + 0.1 * n]; },
  drain: (u, v) => { const n = noise(u * 5 + 3, v * 5); return [0.35 + 0.3 * n, 0.85 * n, 0.25 + 0.2 * n]; },
  chaos: (u, v) => { const n = noise(u * 7, v * 7 + 5); return [0.3 + 0.5 * n, 0.9 * n, 0.1]; },
  frost: (u, v) => { const n = noise(u * 6, v * 6 + 9); return [0.4 + 0.3 * n, 0.7 + 0.2 * n, 1.0]; },
};
const PORTRAIT = (u, v) => { const n = noise(u * 4 + 7, v * 4); const d = Math.hypot(u - 0.5, v - 0.42); return d < 0.3 ? [0.55 + 0.25 * n, 0.42 + 0.2 * n, 0.4] : [0.18 + 0.1 * n, 0.12, 0.2 + 0.1 * n]; };

// the identity line: NAME - SPEC (or SPEC - NAME), class gradient name, spec gradient
function identity(cv, x, y, size, name, cls, spec, before) {
  const c = CLASS[cls] || HOSTILE;
  const specFrom = (c[1] > c[0] + 0.1 && c[1] > c[2]) ? C.violet : C.lime; const specTo = specFrom === C.violet ? C.purple : C.emerald;
  const nameCols = grad(name, mix(c, [1, 1, 1], 0.25), c);
  let text = name; let cols = nameCols;
  if (spec) {
    const sep = ' - '; const sepCols = [...sep].map(() => [0.55, 0.57, 0.6]);
    const specCols = grad(spec, specFrom, specTo);
    text = before ? spec + sep + name : name + sep + spec;
    cols = before ? [...specCols, ...sepCols, ...nameCols] : [...nameCols, ...sepCols, ...specCols];
  }
  label(cv, text, x, y, 'CENTER', size, { colors: cols });
}

// one split frame (Player / Target / Focus) centred on its hub at (cx, cy) px
// (1.3.1 Player / Target: one class family over both bars, the values above, NAME under the health bar on
// the left, SPEC under the resource bar on the right; Focus as in 1.3.0 but in its class family too)
function splitFrame(cv, cx, cy, k, s) {
  const g = geo(k);
  const inner = U2(g.inner);
  const fam = ramp(s.npc ? HOSTILE : CLASS[s.class]);
  const gap = U2(g.tuck + 4);
  const lines = k !== 'focus';
  let hb; let pb;
  if (lines) {
    hb = barFull(cv, cx - inner - U2(g.bar), cy - U2(g.height) / 2, U2(g.bar), U2(g.height), s.health, [fam.bright, fam.base]);
    above(cv, hb, s.healthText, s.percent, 'LEFT', g, gap);
    if (s.power !== undefined) {
      pb = barFull(cv, cx + inner, cy - U2(g.powerHeight) / 2, U2(g.bar), U2(g.powerHeight), s.power, [fam.base, fam.deep]);
      above(cv, pb, s.powerText, s.powerPercent, 'RIGHT', g, gap);
    }
  } else {
    hb = bar(cv, cx - inner - U2(g.bar), cy - U2(g.height) / 2, U2(g.bar), U2(g.height), s.health, [fam.bright, fam.base]);
    inside(cv, hb, s.healthText, s.percent, 'LEFT', g, gap);
    if (s.power !== undefined) {
      pb = bar(cv, cx + inner, cy - U2(g.powerHeight) / 2, U2(g.bar), U2(g.powerHeight), s.power, [fam.base, fam.deep]);
      if (g.powerHeight >= 10) inside(cv, pb, s.powerText, s.powerPercent, 'RIGHT', g, gap);
    }
  }
  if (s.classbar && pb) { // the class bar above the resource values, from clear of the spell name to 8 short of the outer end (1.3.3: above the cast bar's place)
    const x0 = cx + inner + U2(48); const w = U2(g.bar - 48 - 8); const y0 = cy - U2(g.castHeight ? Math.round(g.castLift + g.castHeight + 3) : Math.round(g.height / 2) + 18 + 3) - U2(5);
    const pc = s.classbar.points;
    for (let i = 0; i < pc; i++) { const sw = (w - U2(2) * (pc - 1)) / pc; const bx = x0 + i * (sw + U2(2)); trough(cv, bx, y0, sw, U2(5)); if (i < s.classbar.filled) solid(cv, bx, y0, sw, U2(5), fam.bright, 1); border(cv, bx, y0, sw, U2(5), [0, 0, 0], 0.85); }
  }
  const withBar = g.castInterior !== undefined && !Number.isNaN(g.castInterior); // 1.3.3: Player / Target
  hub(cv, cx, cy, g.hub, { class: s.npc ? null : s.class, portrait: s.npc && !s.crest ? PORTRAIT : null, crest: s.crest, ring: s.npc ? HOSTILE : CLASS[s.class], accent: s.elite ? [1, 0.78, 0.22] : null,
    spell: s.spell && !(withBar && s.fail) && SPELLS[s.spell], cast: s.cast, progress: s.progress, lock: s.lock, timed: s.timed, castName: s.castName, castTime: s.castTime, castSize: g.cast, fail: s.fail, bar: withBar });
  if (withBar && (s.cast || s.fail)) {
    castBar(cv, cx, cy - U2(g.castLift), g, { kind: s.cast, value: s.cast ? (s.cast === 'channel' ? 1 - s.progress : s.progress) : undefined, ramp: fam, lock: s.lock, interrupted: s.fail, name: s.castName, time: s.castTime });
  }
  if (lines) {
    const top = hb.y0 + hb.h + U2(LINE_GAP);
    label(cv, s.name, hb.x0, top, 'TOPLEFT', g.name, { font: 'display', colors: rampCols(s.name, NAME_STOPS) });
    if (s.spec && pb) label(cv, s.spec, pb.x0 + pb.w, top, 'TOPRIGHT', g.name, { font: 'display', colors: rampCols(s.spec, [fam.bright, fam.base, mix(fam.base, fam.deep, 0.35)]) }); // Theme.RampLetters
  } else {
    identity(cv, cx, cy + U2(Math.round(g.hub / 2 - 5)), g.name, s.name, s.npc ? null : s.class, s.spec, s.before);
  }
}

function caption(cv, text, x, y) { label(cv, text, x, y, 'LEFT', 9, { color: [0.6, 0.63, 0.68] }); }

// ---- sheet 1: the split frames, one per row
function sheetFrames() {
  // 1.3.1: one class family over both bars whatever the resource (the resource type is the row's caption only)
  const rows = [
    ['PLAYER IDLE - MISTWEAVER MONK, MANA (DARREN\'S RUNTIME CASE)', 'player', { class: 'MONK', spec: 'MISTWEAVER', name: 'DARRENSMONKY', health: 1, healthText: '501K', percent: '100%', power: 1, powerText: '250K', powerPercent: '100%' }],
    ['PLAYER CASTING - MISTWEAVER (62 %)', 'player', { class: 'MONK', spec: 'MISTWEAVER', name: 'DARRENSMONKY', health: 0.93, healthText: '466K', percent: '93%', power: 0.74, powerText: '185K', powerPercent: '74%', spell: 'drain', cast: 'cast', progress: 0.62, castName: 'ENVELOPING MIST', castTime: '0.9' }],
    ['PLAYER CHANNELING - MISTWEAVER (40 % LEFT)', 'player', { class: 'MONK', spec: 'MISTWEAVER', name: 'DARRENSMONKY', health: 0.71, healthText: '356K', percent: '71%', power: 0.55, powerText: '138K', powerPercent: '55%', spell: 'frost', cast: 'channel', progress: 0.6, castName: 'SOOTHING MIST', castTime: '2.0' }],
    ['PLAYER LOW HEALTH - ROGUE, ENERGY, COMBO POINTS', 'player', { class: 'ROGUE', spec: 'SUBTLETY', name: 'HARDKORH', health: 0.14, healthText: '71K', percent: '14%', power: 0.36, powerText: '36', powerPercent: '36%', classbar: { points: 7, filled: 4 } }],
    ['DRUID - BALANCE, ASTRAL POWER', 'player', { class: 'DRUID', spec: 'BALANCE', name: 'DARRENSDROOD', health: 0.96, healthText: '502K', percent: '96%', power: 0.4, powerText: '40', powerPercent: '40%' }],
    ['PALADIN - HOLY, MANA, HOLY POWER', 'player', { class: 'PALADIN', spec: 'HOLY', name: 'DARRENSPALA', health: 0.82, healthText: '588K', percent: '82%', power: 0.9, powerText: '225K', powerPercent: '90%', classbar: { points: 5, filled: 3 } }],
    ['DEATH KNIGHT - UNHOLY, RUNIC POWER', 'player', { class: 'DEATHKNIGHT', spec: 'UNHOLY', name: 'HARDKORH', health: 0.62, healthText: '410K', percent: '62%', power: 0.4, powerText: '40', powerPercent: '40%' }],
    ['MAGE - FROST, MANA', 'player', { class: 'MAGE', spec: 'FROST', name: 'HARDKORH', health: 0.88, healthText: '512K', percent: '88%', power: 0.7, powerText: '175K', powerPercent: '70%' }],
    ['TARGET PLAYER - DEATH KNIGHT (DARREN\'S RUNTIME TARGET)', 'target', { class: 'DEATHKNIGHT', spec: 'UNHOLY', name: 'EVELIANNA', health: 1, healthText: '661K', percent: '100%', power: 0, powerText: '0', powerPercent: '0%' }],
    ['TARGET PLAYER - MAGE', 'target', { class: 'MAGE', spec: 'FROST', name: 'ICEBORN', health: 0.64, healthText: '426K', percent: '64%', power: 0.72, powerText: '98K', powerPercent: '72%' }],
    ['TARGET NPC (ELITE, NO RESOURCE: NO RESOURCE SIDE, NO SPEC)', 'target', { npc: true, elite: true, name: 'JANDICE BAROV', health: 0.52, healthText: '956K', percent: '52%' }],
    ['TARGET NPC CASTING (1.3.3: THE REACTION FAMILY ON THE BAR, NO INTERRUPTIBILITY CLAIMED)', 'target', { npc: true, elite: true, name: 'JANDICE BAROV', health: 0.52, healthText: '956K', percent: '52%', spell: 'drain', cast: 'cast', progress: 0.45, castName: 'SHADOW BOLT VOLLEY', castTime: '1.4' }],
    ['TARGET NPC PREVIEW SAMPLE (1.3.3: BANZAI\'S OWN CREST - NO PORTRAIT, NO GAME ICON)', 'target', { npc: true, crest: true, elite: true, name: 'NPC PREVIEW', health: 0.52, healthText: '957K', percent: '52%' }],
    ['TARGET CASTING (NOT INTERRUPTIBLE)', 'target', { class: 'WARLOCK', spec: 'DESTRUCTION', name: 'FELBANE', health: 0.8, healthText: '512K', percent: '80%', power: 0.6, powerText: '61K', powerPercent: '60%', spell: 'chaos', cast: 'cast', progress: 0.35, lock: true, castName: 'CHAOS BOLT', castTime: '1.9' }],
    ['FOCUS (ROGUE, ENERGY) - UNCHANGED LAYOUT, CLASS FAMILY', 'focus', { class: 'ROGUE', name: 'SHADOWSTEP', health: 0.42, healthText: '341K', percent: '42%', power: 0.8 }],
    ['INTERRUPTED', 'player', { class: 'MONK', spec: 'MISTWEAVER', name: 'DARRENSMONKY', health: 0.96, healthText: '481K', percent: '96%', power: 0.81, powerText: '203K', powerPercent: '81%', spell: 'drain', fail: true, castName: 'INTERRUPTED' }],
  ];
  const w = U2(700); const rowH = U2(190); // 1.3.3: room for the bamboo cast bar above a casting Player / Target
  const cv = new Canvas(w, rowH * rows.length);
  scene(cv, 1);
  rows.forEach(([title, k, s], i) => {
    const cy = rowH * i + rowH * 0.66;
    caption(cv, title, U2(8), rowH * i + U2(9));
    splitFrame(cv, w / 2, cy, k, s);
  });
  // the Target-of-Target beside the first target row: one compact bar right of the Target, name above, percent inside
  const ti = rows.findIndex((r) => r[0].startsWith('TARGET PLAYER'));
  const tg = geo('target'); const ty = rowH * ti + rowH * 0.66;
  const tx = w / 2 + U2(tg.inner + tg.bar + 14);
  const tb = bar(cv, tx, ty - U2(5), U2(90), U2(10), 0.18, classPair(CLASS.PRIEST));
  label(cv, 'HOLYLIGHT', tx, ty - U2(5) - U2(6), 'LEFT', 9, { colors: grad('HOLYLIGHT', [1, 1, 1], [0.85, 0.85, 0.85]) });
  label(cv, '18%', tx + U2(90) - U2(3), ty, 'RIGHT', 9, { color: [0.87, 0.89, 0.91] });
  void tb;
  return cv.save('split-frames');
}

// ---- sheet 2: party (DPS column, HEALER row) with states
function partyFrame(cv, x0, y0, w, h, s) {
  const b = bar(cv, x0, y0, U2(w), U2(h), s.health, classPair(CLASS[s.class]));
  const cy = y0 + U2(h) / 2; const cx = x0 + U2(w) / 2;
  const alpha = s.range ? 0.45 : 1;
  inside(cv, b, s.dead ? '' : s.value, s.dead ? '' : s.percent, 'LEFT', { value: 9, percent: 8 }, U2(4), 4);
  hub(cv, cx, cy, PARTY_CIRCLE, { class: s.class, ring: CLASS[s.class], noAccent: true }); // the party circle (Identity.Circle: disc, icon, class ring - no accent)
  // the role badge on the circle's upper left (a stand-in disc for mMediaTag's role icon)
  const rx = cx - U2(PARTY_CIRCLE / 2 - 1); const ry = cy - U2(PARTY_CIRCLE / 2 - 6);
  cv.region(rx - U2(5.5), ry - U2(5.5), rx + U2(5.5), ry + U2(5.5), (u, v) => { const d = Math.hypot(u - 0.5, v - 0.5); return d < 0.5 ? (d > 0.38 ? [0, 0, 0, 1] : [0.2, 0.75, 0.95, 1]) : null; });
  identity(cv, cx, cy + U2(PARTY_CIRCLE / 2 - 4), 9, s.name, s.class);
  if (s.dead) label(cv, 'Dead', cx, cy - U2(PARTY_CIRCLE / 2 + 2), 'CENTER', 9, { color: [0.72, 0.74, 0.77] });
  // trinket circle right of the bar (PvP furniture, unchanged)
  cv.region(x0 + U2(w + 4), cy - U2(13.5), x0 + U2(w + 31), cy + U2(13.5), (u, v) => { const d = Math.hypot(u - 0.5, v - 0.5); return d < 0.5 ? (d > 0.41 ? [...C.lime, 1] : [0.25, 0.22, 0.12, 1]) : null; });
  if (s.cc) {
    const sz = Math.min(30, h - 4);
    cv.region(x0 + U2(w - 3 - sz), cy - U2(sz / 2), x0 + U2(w - 3), cy + U2(sz / 2), (u, v) => [0.75 + 0.2 * noise(u * 5, v * 5), 0.45, 0.9, 1]);
    const m = [1, 0.18, 0.62]; border(cv, x0 - U2(2), y0 - U2(2), U2(w + 4), U2(h + 4), m, 1); border(cv, x0 - U2(3), y0 - U2(3), U2(w + 6), U2(h + 6), m, 1);
    label(cv, 'CC', x0 + U2(w - 3 - sz / 2), y0 - U2(1), 'BOTTOM', 11, { font: 'display', color: m });
  }
  if (s.dispel) { const d = [0.2, 0.85, 1]; border(cv, x0 - U2(1), y0 - U2(1), U2(w + 2), U2(h + 2), d, 1); label(cv, 'DISPEL', x0 + U2(w - 16), y0 + U2(h + 9), 'RIGHT', 9, { font: 'display', color: d }); }
  if (alpha < 1) solid(cv, x0 - U2(4), y0 - U2(20), U2(w + 40), U2(h + 30), [0.08, 0.07, 0.11], 0.45); // the range fade (ElvUI lowers the whole frame)
}
function sheetParty() {
  const members = [
    { class: 'PALADIN', name: 'TITANTANK', health: 0.88, value: '458K', percent: '88%' },
    { class: 'SHAMAN', name: 'TIDECALLER', health: 1, value: '520K', percent: '100%', dispel: true },
    { class: 'WARLOCK', name: 'TIRAVIELLE', health: 0.46, value: '239K', percent: '46%', cc: true },
    { class: 'DRUID', name: 'NERIEN', health: 0, value: '', percent: '', dead: true },
    { class: 'HUNTER', name: 'QUIKKSHOT', health: 0.71, value: '369K', percent: '71%', range: true },
  ];
  const cv = new Canvas(U2(980), U2(330));
  scene(cv, 2);
  caption(cv, 'DPS PARTY (100 x 39, LEFT EDGE COLUMN) - NORMAL, DISPELLABLE, CC\'D, DEAD, OUT OF RANGE', U2(8), U2(9));
  members.forEach((s, i) => partyFrame(cv, U2(54), U2(30 + i * 58), 100, 39, s));
  caption(cv, 'HEALER PARTY (100 x 27, CENTRAL ROW, 70 APART)', U2(260), U2(9));
  members.forEach((s, i) => partyFrame(cv, U2(260 + i * 170), U2(70), 100, 27, s));
  caption(cv, 'HEALER PARTY - NORMAL STATE', U2(260), U2(150));
  members.forEach((s, i) => partyFrame(cv, U2(260 + i * 170), U2(200), 100, 27, { ...s, cc: false, dispel: false, dead: false, range: false, health: s.health || 0.92, value: s.value || '478K', percent: s.percent || '92%' }));
  return cv.save('split-party');
}

// ---- sheet 3: the enhanced targeted nameplate (and an ordinary plate)
function plate(cv, cx, cy, s, enhanced) {
  const w = U2(140); const h = U2(12); const x0 = cx - w / 2; const y0 = cy - h / 2;
  const b = bar(cv, x0, y0, w, h, s.health, classPair(CLASS[s.class] || HOSTILE));
  inside(cv, b, s.value, s.percent, 'LEFT', { value: 10, percent: 9 }, U2(4), 4);
  identity(cv, cx, y0 - U2(9), 11, s.name, s.class);
  if (enhanced) {
    border(cv, x0 - U2(1), y0 - U2(1), w + U2(2), h + U2(2), C.lime, 1);
    hub(cv, x0 - U2(3) - U2(13), cy, 26, { class: s.class, ring: CLASS[s.class], spell: s.spell && SPELLS[s.spell], cast: s.cast, progress: s.progress, castName: null, plate: true });
    if (s.cast) {
      bar(cv, x0, y0 + h + U2(2), w, U2(6), s.progress, [[0.6, 0.42, 0], CAST.cast]);
      label(cv, s.castName, x0, y0 + h + U2(14), 'LEFT', 9);
    }
  }
}
function sheetPlate() {
  const cv = new Canvas(U2(640), U2(160));
  scene(cv, 3);
  caption(cv, 'ENHANCED TARGETED NAMEPLATE (TARGET ONLY)', U2(8), U2(9));
  plate(cv, U2(130), U2(60), { class: 'WARLOCK', name: 'FELBANE', health: 0.62, value: '426K', percent: '62%' }, true);
  caption(cv, '... WHILE THE TARGET CASTS', U2(240), U2(9));
  plate(cv, U2(330), U2(60), { class: 'WARLOCK', name: 'FELBANE', health: 0.62, value: '426K', percent: '62%', spell: 'chaos', cast: 'cast', progress: 0.55, castName: 'CHAOS BOLT' }, true);
  caption(cv, 'ANY OTHER PLATE (UNCHANGED)', U2(450), U2(9));
  const w = U2(140); const x0 = U2(540) - w / 2;
  bar(cv, x0, U2(60) - U2(6), w, U2(12), 0.8, classPair(HOSTILE));
  label(cv, 'SKELETAL GUARDIAN', U2(540), U2(60) - U2(15), 'CENTER', 11, { color: [0.95, 0.3, 0.25] });
  return cv.save('split-plate');
}

// ---- sheet 4: the screen composition (where everything sits, 1:2)
function sheetScreen() {
  const SW = 2560; const SH = 1440; const k = 0.5;
  const cv = new Canvas(SW * k, SH * k);
  scene(cv, 4);
  const u2s = (x, y) => [(SW / 2 + U2(x)) * k, (SH - U2(y)) * k]; // units from the bottom centre
  const box = (xu, yu, wu, hu, c, name) => { const [x, y] = u2s(xu, yu + hu); solid(cv, x, y, U2(wu) * k, U2(hu) * k, c, 0.22); border(cv, x, y, U2(wu) * k, U2(hu) * k, c, 0.8); label(cv, name, x + 3, y + 8, 'LEFT', 7, { color: c }); };
  const UW = SW / PX; const UH = SH / PX;
  box(-UW / 2, 0, UW, 32, [0.3, 0.9, 0.5], 'BOTTOM PANEL');
  box(-UW / 2 - 0.655, 31.5, 493.31, 161, [0.6, 0.6, 0.65], 'CHAT');
  box(UW / 2 - 16 - 493.31, 31.5, 493.31, 161, [0.6, 0.6, 0.65], 'DETAILS');
  box(-(12 * 30 + 11 * 6) / 2, 50, 12 * 30 + 11 * 6, 30, [0.9, 0.8, 0.3], 'ACTION BARS');
  box(-(12 * 30 + 11 * 6) / 2, 86, 12 * 30 + 11 * 6, 30, [0.9, 0.8, 0.3], '');
  box(-100, 250 - 14 - 4 * 21, 200, 14 + 4 * 21, [0.7, 0.7, 0.9], 'CAST HISTORY (4 ROWS)');
  box(-335 - 75, 54, 150, 5 * 19, [0.9, 0.5, 0.3], 'OFFENSIVE CDS');
  box(335 - 75, 54, 150, 5 * 19, [0.9, 0.5, 0.3], 'DEFENSIVE CDS');
  box(-400, 454, 800, 27, [0.5, 0.8, 1], 'HEALER PARTY ROW');
  box(UW / 2 - 21 - 185 - 21, UH - 48 - 185 - 21, 227, 227, [0.6, 0.6, 0.65], 'MINIMAP');
  box(-48, UH - 34, 96, 24, [0.62, 1, 0.12], 'WORDMARK');
  // the split frames at their real places, at half size
  const P = geo('player'); const Tg = geo('target'); const F = geo('focus');
  const frame = (xu, yu, g, name, cls) => {
    const [cx, cy] = u2s(xu, yu);
    const inner = U2(g.inner) * k;
    solid(cv, cx - inner - U2(g.bar) * k, cy - U2(g.height) * k / 2, U2(g.bar) * k, U2(g.height) * k, CLASS[cls], 0.9);
    solid(cv, cx + inner, cy - U2(g.powerHeight) * k / 2, U2(g.bar) * k, U2(g.powerHeight) * k, ramp(CLASS[cls]).deep, 0.9); // 1.3.1: the class family
    cv.region(cx - U2(g.hub) * k / 2, cy - U2(g.hub) * k / 2, cx + U2(g.hub) * k / 2, cy + U2(g.hub) * k / 2, (u, v) => (Math.hypot(u - 0.5, v - 0.5) < 0.5 ? [...CLASS[cls], 1] : null));
    label(cv, name, cx, cy - U2(g.hub) * k / 2 - 4, 'BOTTOM', 7, { color: [1, 1, 1] });
  };
  frame(POS.px, POS.py, P, 'PLAYER', 'DRUID');
  box(POS.px - P.castWidth / 2, POS.py + P.castLift, P.castWidth, P.castHeight, [0.62, 1, 0.12], 'PLAYER CAST BAR (1.3.3)');
  box(POS.px + P.inner + 48, POS.py + Math.round(P.castLift + P.castHeight + 3), P.bar - 48 - 8, 5, [1, 0.7, 0.2], 'CLASS BAR');
  box(POS.tx - Tg.castWidth / 2, UH - POS.ty + Tg.castLift, Tg.castWidth, Tg.castHeight, [0.62, 1, 0.12], 'TARGET CAST BAR (1.3.3)');
  frame(POS.tx, UH - POS.ty, Tg, 'TARGET', 'MAGE');
  frame(POS.px - 330, POS.py + 70, F, 'FOCUS', 'ROGUE');
  const [tx, ty] = u2s(POS.tx + Tg.inner + Tg.bar + 14, UH - POS.ty);
  solid(cv, tx, ty - U2(5) * k, U2(90) * k, U2(10) * k, CLASS.PRIEST, 0.9);
  label(cv, 'TOT', tx, ty - 10, 'LEFT', 7);
  caption(cv, 'BANZAI SPLIT AT 2560 x 1440 (UI SCALE 0.71), HALF SIZE: THE SPLIT FRAMES AND THE APPROVED PIECES AROUND THEM', 10, 14);
  return cv.save('split-screen');
}

// ---- sheet 5: Details rows, CURRENT and COMPACT, on glass and parchment
function detailsWindow(cv, x0, y0, style, material, kind) {
  const WS = 0.75; // Details window scale
  const W = U2(212); const H = U2(124);
  if (material === 'parchment') {
    // 1.3.7: the parchment tile at its own density (2 texels per unit, both ways: never stretched)
    drawTex(cv, tex.BanzaiParchmentTile, x0 - U2(6), y0 - U2(6), W + U2(12), H + U2(12), { from: [0.91, 0.91, 0.91], to: [0.91, 0.91, 0.91], coords: [0, (212 + 12) * 2 / 1024, 0, (124 + 12) * 2 / 512] });
  } else {
    solid(cv, x0 - U2(6), y0 - U2(6), W + U2(12), H + U2(12), [0.015, 0.075, 0.045], 0.72);
  }
  const title = kind === 'damage' ? 'DAMAGE' : 'HEALING';
  const tc = kind === 'damage' ? [[1, 0.4, 0.32], [0.8, 0.03, 0.1]] : [[0.55, 1, 0.45], [0, 0.66, 0.3]];
  solid(cv, x0 + U2(4), y0 - U2(12), U2(80), U2(17), [0.01, 0.025, 0.018], 0.97);
  label(cv, title, x0 + U2(11), y0 - U2(4), 'LEFT', 22 * 0.85, { font: 'display', colors: grad(title, tc[0], tc[1]) });
  const rows = kind === 'damage'
    ? [['NERIEN', 'DRUID', 1, '170K (14.2K)'], ['QUIKKSHOT', 'HUNTER', 0.39, '67K (5.6K)'], ['TIDECALLER', 'SHAMAN', 0.39, '67K (5.6K)'], ['TITANTANK', 'PALADIN', 0.31, '52K (4.3K)'], ['TIRAVIELLE', 'WARLOCK', 0.27, '46K (3.7K)'], ['ICEBORN', 'MAGE', 0.2, '34K (2.8K)'], ['SHADE', 'ROGUE', 0.12, '21K (1.7K)']]
    : [['TITANTANK', 'PALADIN', 1, '162K (13.5K)'], ['TIDECALLER', 'SHAMAN', 0.16, '26K (2.2K)'], ['HOLYLIGHT', 'PRIEST', 0.12, '19K (1.6K)'], ['NERIEN', 'DRUID', 0.05, '8K (0.7K)']];
  const ink = material === 'parchment' ? [0.96, 0.95, 0.92] : [1, 1, 1];
  const top = y0 + U2(8 * WS);
  rows.forEach(([name, cls, v, val], i) => {
    const c = CLASS[cls];
    if (style === 'CURRENT') {
      const bh = U2(5 * WS); const pitch = U2((5 + 12) * WS); const y = top + U2(8 * WS) + i * pitch;
      solid(cv, x0, y, W, bh, [0.02, 0.04, 0.03], 0.55);
      drawTex(cv, tex.BanzaiBar, x0, y, W * v, bh, { from: c, to: c });
      label(cv, name, x0 + U2(2 * WS), y + bh / 2, 'LEFT', 13 * WS, { color: ink });
      label(cv, val, x0 + W, y + bh / 2, 'RIGHT', 13 * WS, { color: ink });
    } else {
      const bh = U2(4 * WS); const pitch = U2((4 + 14) * WS); const y = top + U2(15 * WS) + i * pitch;
      solid(cv, x0, y, W, bh, [0.02, 0.04, 0.03], 0.55);
      drawTex(cv, tex.BanzaiBar, x0, y, W * v, bh, { from: c, to: c });
      const isz = U2((4 + 14) * WS); const ix = x0; const iy = y + bh / 2 - isz / 2 - U2(5 * WS);
      if (fabled) { const [gx, gy] = JI_CELL[cls]; drawTex(cv, fabled, ix, iy, isz, isz, { coords: [gx * 0.125, (gx + 1) * 0.125, gy * 0.125, (gy + 1) * 0.125] }); }
      label(cv, name, x0 + U2(21 * WS), y - U2(1 * WS), 'BOTTOMLEFT', 14 * WS, { colors: [...name].map(() => c), font: 'display' }); // 1.3.1: the names in Want Coffee (14)
      label(cv, val, x0 + W, y - U2(1 * WS), 'BOTTOMRIGHT', 13 * WS, { color: ink });
    }
  });
}
function sheetDetails() {
  const cv = new Canvas(U2(980), U2(640));
  scene(cv, 5);
  const cells = [['CURRENT', 'glass'], ['COMPACT', 'glass'], ['CURRENT', 'parchment'], ['COMPACT', 'parchment']];
  cells.forEach(([style, mat], i) => {
    const x = U2(20 + (i % 2) * 480); const y = U2(40 + Math.floor(i / 2) * 300);
    caption(cv, 'BANZAI ' + style + ' - ' + (mat === 'glass' ? 'BANZAI GLASS' : 'HARDKORH PARCHMENT'), x, y - U2(26));
    detailsWindow(cv, x, y, style, mat, 'damage');
    detailsWindow(cv, x + U2(218), y, style, mat, 'healing');
  });
  return cv.save('details-styles');
}

// ---- sheet 6 (1.3.1): the centre column of Darren's 2560 x 1440 screen at 1:1 - the Target and the Player where
// they sit (the same crop as his 1.3.0 runtime screenshot), Mistweaver / Unholy as in it
function sheetRuntime() {
  const X0 = 900; const W = 760; const H = 1180; const SH = 1440;
  const cv = new Canvas(W, H);
  cv.region(0, 0, W, H, (u, v, x, y) => { const n = noise(x / 70 + 3, y / 70) * 0.6 + noise(x / 17, y / 17 + 3) * 0.4; return [0.27 + 0.08 * n, 0.21 + 0.06 * n, 0.42 + 0.10 * n, 1]; });
  const at = (xu, yTop) => [1280 - X0 + U2(xu), yTop];
  const [tx, ty] = at(POS.tx, U2(POS.ty));
  splitFrame(cv, tx, ty, 'target', { class: 'DEATHKNIGHT', spec: 'UNHOLY', name: 'EVELIANNA', health: 1, healthText: '661K', percent: '100%', power: 0, powerText: '0', powerPercent: '0%' });
  const [px, py] = at(POS.px, SH - U2(POS.py));
  splitFrame(cv, px, py, 'player', { class: 'MONK', spec: 'MISTWEAVER', name: 'DARRENSMONKY', health: 1, healthText: '501K', percent: '100%', power: 1, powerText: '250K', powerPercent: '100%', spell: 'drain', cast: 'cast', progress: 0.55, castName: 'VIVIFY', castTime: '0.7' }); // 1.3.3: casting
  caption(cv, 'BANZAI ' + (fs.readFileSync(path.join(DIST, 'BushidoPrivateCompat', 'Theme.lua'), 'utf8').match(/Theme\.VERSION = '([^']+)'/) || [])[1] + ' SPLIT - THE CENTRE OF DARREN\'S SCREEN AT 1:1 (2560 X 1440, UI SCALE 0.71), SAME CROP AS THE 1.3.0 RUNTIME SCREENSHOT', 8, 12);
  return cv.save('split-runtime');
}

// ---- sheet 7 (1.3.3): the split Player / Target cast states at Darren's scale - idle (the class art, its bamboo ring),
// casting (the spell icon alone in the 125 % hub, the bamboo cast bar the full width above the values), channelling
// (drains right to left), interrupted (crimson, the class art back), a locked target cast, an NPC cast
function sheetCast() {
  const MONK = { class: 'MONK', spec: 'MISTWEAVER', name: 'DARRENSMONKY', health: 0.93, healthText: '466K', percent: '93%', power: 0.74, powerText: '185K', powerPercent: '74%' };
  const rows = [
    ['PLAYER IDLE - THE BANZAI MONK ART, 125 % (62.5 UNITS, 83 PX), NO CAST BAR', 'player', { ...MONK, health: 1, healthText: '501K', percent: '100%', power: 1, powerText: '250K', powerPercent: '100%' }],
    ['PLAYER CASTING - ENVELOPING MIST 62 %: THE SPELL ICON IN THE CENTRE, THE BAR FILLS LEFT -> RIGHT', 'player', { ...MONK, spell: 'drain', cast: 'cast', progress: 0.62, castName: 'ENVELOPING MIST', castTime: '0.9' }],
    ['PLAYER CHANNELLING - CRACKLING JADE LIGHTNING, 40 % LEFT: THE BAR DRAINS RIGHT -> LEFT', 'player', { ...MONK, spell: 'frost', cast: 'channel', progress: 0.6, castName: 'CRACKLING JADE LIGHTNING', castTime: '1.6' }],
    ['PLAYER INTERRUPTED - FOR A MOMENT: CRIMSON, THE CLASS ART BACK AT ONCE', 'player', { ...MONK, spell: 'drain', fail: true, castName: 'INTERRUPTED' }],
    ['TARGET PLAYER CASTING, NOT INTERRUPTIBLE (THE GAME\'S FLAG: STEEL)', 'target', { class: 'WARLOCK', spec: 'DESTRUCTION', name: 'FELBANE', health: 0.8, healthText: '512K', percent: '80%', power: 0.6, powerText: '61K', powerPercent: '60%', spell: 'chaos', cast: 'cast', progress: 0.35, lock: true, castName: 'CHAOS BOLT', castTime: '1.9' }],
    ['TARGET PLAYER CASTING - VIVIFY (SHORT NAME)', 'target', { class: 'MONK', spec: 'MISTWEAVER', name: 'JADEPAW', health: 0.71, healthText: '402K', percent: '71%', power: 0.88, powerText: '220K', powerPercent: '88%', spell: 'drain', cast: 'cast', progress: 0.8, castName: 'VIVIFY', castTime: '0.3' }],
  ];
  const w = U2(700); const rowH = U2(190);
  const cv = new Canvas(w, rowH * rows.length);
  scene(cv, 7);
  rows.forEach(([title, k, sm], i) => {
    caption(cv, title, U2(8), rowH * i + U2(9));
    splitFrame(cv, w / 2, rowH * i + rowH * 0.66, k, sm);
  });
  return cv.save('split-cast');
}

const made = [sheetFrames(), sheetParty(), sheetPlate(), sheetScreen(), sheetDetails(), sheetRuntime(), sheetCast()];
console.log(made.join('\n'));
