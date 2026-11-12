// BANZAI 1.3.2 class-art pipeline tests (node): the source mapping, the matte extraction and
// decontamination on synthetic art with a known answer, the 13 masters as committed, the runtime
// conversion and its per-class fallback. Run by tests/run.js (node tests/run.js icons: only these).
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const art = require('../tools/lib/classart');
const matte = require('../tools/lib/matte');
const png = require('../tools/lib/png');
const identity = require('../tools/lib/identity');
const resample = require('../tools/lib/resample');

const results = [];
function test(name, fn) {
  try { fn(); results.push({ name, ok: true }); } catch (e) { results.push({ name, ok: false, error: String(e && e.stack || e) }); }
}
function expect(cond, msg) { if (!cond) throw new Error(msg); }
function expectEq(a, b, msg) { if (a !== b) throw new Error(`${msg}: expected [${b}], got [${a}]`); }

// ---- a synthetic class icon on a grey matte, with every case the extraction has to get right,
// drawn with exact coverage (4 x 4 samples) so the true alpha of every pixel is known
const MATTE = [111, 111, 111];
const OUTLINE = [18, 12, 16];
function synthetic({ w = 260, h = 200, cx = 130, cy = 100 } = {}) {
  let seed = 12345;
  const noise = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return (seed % 3) - 1; }; // the matte's JPEG noise
  // the art: [colour, coverage test] layers, last wins
  const r = (x, y) => Math.hypot(x - cx, y - cy);
  const box = (x0, y0, s) => (x, y) => x >= x0 && x < x0 + s && y >= y0 && y < y0 + s;
  const layers = [
    [[120, 80, 50], (x, y) => r(x, y) >= 72 && r(x, y) <= 88],                      // the bamboo ring
    [OUTLINE, (x, y) => (r(x, y) >= 72 && r(x, y) < 74.5) || (r(x, y) > 85.5 && r(x, y) <= 88)], // its outlines
    [OUTLINE, (x, y) => Math.abs(y - cy) < 1.2 && x > cx + 60 && x < cx + 73],       // a thin spike into the gap
    [OUTLINE, (x, y) => r(x, y) <= 58],                                               // the emblem disc's outline
    [[150, 40, 40], (x, y) => r(x, y) < 55],                                          // the emblem
  ];
  // patches inside the emblem, each in a 2 px outline: [x0, y0, fill(x, y) -> rgb]
  const P = 14;
  const patches = {
    hole: [cx - 34, cy - 34, () => MATTE],                                            // real matte inside the art: transparent
    tinted: [cx - 7, cy - 34, () => [113, 111, 109]],                                // tinted near-matte steel: chroma keeps it
    shaded: [cx + 20, cy - 34, (x) => { const t = (x - (cx + 20)) / (P - 1); return [105 + 12 * t, 105 + 12 * t, 105 + 12 * t]; }], // shaded steel: sd keeps it
    silver: [cx - 34, cy + 8, () => [116, 116, 116]],                                // a lighter flat silver: the offset keeps it
  };
  for (const [x0, y0, fill] of Object.values(patches)) {
    layers.push([OUTLINE, box(x0 - 2, y0 - 2, P + 4)]);
    layers.push([fill, box(x0, y0, P)]);
  }
  // a soft-edged near-matte highlight (no outline, shaded steel round it): hardness keeps it
  const sx = cx + 22; const sy = cy + 22;
  layers.push([(x, y) => { const d = Math.hypot(x - sx, y - sy); const v = 111 + Math.max(0, d - 5) * 4; return [v, v, v]; }, (x, y) => Math.hypot(x - sx, y - sy) <= 14]);
  const px = Buffer.alloc(w * h * 4); const cov = new Float32Array(w * h);
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    let c = [0, 0, 0]; let a = 0;
    for (let j = 0; j < 4; j++) for (let i = 0; i < 4; i++) {
      const X = x + (i + 0.5) / 4; const Y = y + (j + 0.5) / 4;
      let col = null;
      for (const [colour, inside] of layers) if (inside(X, Y)) col = typeof colour === 'function' ? colour(X, Y) : colour;
      if (col) { c = c.map((v, k) => v + col[k]); a++; }
    }
    const o = (y * w + x) * 4; const k = a / 16; const n = noise();
    for (let ch = 0; ch < 3; ch++) px[o + ch] = Math.round((a ? c[ch] / a : 0) * k + (MATTE[ch] + n) * (1 - k));
    px[o + 3] = 255; cov[y * w + x] = k;
  }
  const centre = (name) => { const [x0, y0] = patches[name]; return [x0 + P / 2, y0 + P / 2]; };
  return { img: { w, h, px }, cov, centre, soft: [sx, sy], spike: [cx + 66, cy], gap: [cx, cy - 65], cx, cy, outer: 88 };
}

function extractSynthetic(opts) {
  const s = synthetic(opts);
  const seg = matte.segment(s.img);
  const rgba = matte.extract(s.img, seg);
  return { s, seg, rgba };
}
const A = (img, x, y) => img.px[(Math.floor(y) * img.w + Math.floor(x)) * 4 + 3];

test('1.3.2 matte: the exterior and the matte holes inside the art transparent; outlines, the thin spike and the emblem opaque', () => {
  const { s, rgba, seg } = extractSynthetic();
  for (const [x, y] of [[0, 0], [259, 0], [0, 199], [259, 199], [s.cx, 2]]) expectEq(A(rgba, x, y), 0, `exterior ${x},${y}`);
  expectEq(A(rgba, ...s.gap), 0, 'the gap between ring and emblem (an enclosed matte hole)');
  expectEq(A(rgba, ...s.centre('hole')), 0, 'a matte hole inside the emblem');
  expect(seg.holes.length >= 2, 'holes found: ' + seg.holes.length);
  expectEq(A(rgba, s.cx, s.cy + 30), 255, 'the emblem');
  expectEq(A(rgba, s.cx - 80, s.cy), 255, 'the bamboo ring');
  expectEq(A(rgba, s.cx - 87, s.cy), 255, 'its dark outline');
  expect(A(rgba, ...s.spike) >= 200, 'the 2 px spike stays: ' + A(rgba, ...s.spike));
});

test('1.3.2 matte: legitimate grey art stays opaque - tinted steel (chroma), shaded steel (flatness), a lighter silver (offset), a soft-edged highlight (hard edges)', () => {
  const { s, rgba } = extractSynthetic();
  for (const name of ['tinted', 'shaded', 'silver']) expectEq(A(rgba, ...s.centre(name)), 255, name);
  expectEq(A(rgba, ...s.soft), 255, 'soft-edged highlight');
});

test('1.3.2 edges: the coverage solved within 0.15 of the truth on the seams, the matte grey solved out of them (composites over white, black and magenta match the art drawn there)', () => {
  const { s, rgba } = extractSynthetic();
  const { w, h } = s.img;
  let worstA = 0; let worstC = 0; let seams = 0;
  // the true colour of the art at a seam pixel: the outline (every edge facing the matte is outline here)
  for (let y = 1; y < h - 1; y++) for (let x = 1; x < w - 1; x++) {
    const t = s.cov[y * w + x];
    if (t <= 0.05 || t >= 0.95) continue;
    const rr = Math.hypot(x + 0.5 - s.cx, y + 0.5 - s.cy);
    if (!(rr > 86 || (rr > 70 && rr < 76) || (rr > 56 && rr < 60))) continue; // the ring / emblem seams against the matte
    seams++;
    const o = (y * w + x) * 4; const a = rgba.px[o + 3] / 255;
    worstA = Math.max(worstA, Math.abs(a - t));
    for (const bg of [[255, 255, 255], [0, 0, 0], [255, 0, 255]]) for (let k = 0; k < 3; k++) {
      const got = rgba.px[o + k] * a + bg[k] * (1 - a); const want = OUTLINE[k] * t + bg[k] * (1 - t);
      worstC = Math.max(worstC, Math.abs(got - want));
    }
  }
  expect(seams > 200, 'seam pixels measured: ' + seams);
  expect(worstA <= 0.15, 'coverage error ' + worstA.toFixed(3));
  expect(worstC <= 28, 'composite error ' + worstC.toFixed(1) + ' levels (a grey fringe would be ~90)');
});

test('1.3.2 edges: a half-covered seam pixel gets about half alpha and the outline colour - never the grey mix', () => {
  const { s, rgba } = extractSynthetic();
  const { w } = s.img;
  let checked = 0;
  for (let x = 0; x < s.cx; x++) {
    const y = s.cy + 13; const t = s.cov[y * w + x]; // a row where the ring's edge falls inside pixels
    if (t < 0.35 || t > 0.65) continue;
    const o = (y * w + x) * 4;
    expect(Math.abs(rgba.px[o + 3] / 255 - t) < 0.15, `alpha at ${x}: ${rgba.px[o + 3]} for coverage ${t}`);
    expect(Math.max(...[0, 1, 2].map((k) => Math.abs(rgba.px[o + k] - OUTLINE[k]))) <= 20, `colour at ${x}: ${rgba.px[o]},${rgba.px[o + 1]},${rgba.px[o + 2]} (the mix was ${s.img.px[o]})`);
    checked++;
  }
  expect(checked >= 1, 'a half-covered pixel on the row');
});

test('1.3.2 composition: the ring found and centred, every ring the same radius, one uniform scale (no stretching), transparent padding, corners clear - from a wide canvas too', () => {
  for (const opts of [{}, { w: 320, h: 200, cx: 205, cy: 96 }]) {
    const { rgba } = extractSynthetic(opts);
    const fit = matte.ringFit(rgba);
    expect(Math.abs(fit.cx - (opts.cx || 130)) < 1 && Math.abs(fit.cy - (opts.cy || 100)) < 1, `ring centre ${fit.cx},${fit.cy}`);
    expect(Math.abs(fit.R - 88) < 1.5, 'ring radius ' + fit.R);
    const Rt = art.targetRadius([fit], 256);
    const m = art.master(rgba, fit, Rt, 256);
    const me = art.measure(m.img);
    expect(Math.abs(me.ring.cx - 128) < 1 && Math.abs(me.ring.cy - 128) < 1, `master centre ${me.ring.cx},${me.ring.cy}`);
    expect(Math.abs(me.ring.R - Rt) < 1.5, `master ring ${me.ring.R} vs ${Rt}`);
    expect(Math.abs(me.extent.horizontal - me.extent.vertical) <= 2, `aspect kept: ${me.extent.horizontal} x ${me.extent.vertical}`);
    expect(me.corners && me.margins.top >= art.MASTER.clear - 1 && me.margins.left >= art.MASTER.clear - 1, 'padding ' + JSON.stringify(me.margins));
    expectEq(m.img.px[3], 0, 'transparent corner');
    expectEq(m.img.px[0] + m.img.px[1] + m.img.px[2], 0, 'no colour stored where it is transparent');
  }
});

test('1.3.2 composition: a class whose art passes the ring sets the family radius; the masters are deterministic', () => {
  const fits = [{ R: 100, maxR: 101 }, { R: 100, maxR: 104 }];
  expect(Math.abs(art.targetRadius(fits, 1024) - (506 * 100) / 104) < 1e-9, 'the most protruding class decides');
  const { rgba } = extractSynthetic();
  const fit = matte.ringFit(rgba);
  const a = art.masterBytes(art.master(rgba, fit, 120, 256).img); const b = art.masterBytes(art.master(rgba, fit, 120, 256).img);
  expect(a.equals(b), 'same bytes twice');
});

// ---- the mapping
const mapping = art.loadMapping(ROOT);
const fakeFiles = (extra = []) => [...Object.values(mapping.classes).map((e) => e.source), ...mapping.excluded.map((e) => e.source), ...extra];
const realRead = (f) => fs.readFileSync(path.join(ROOT, mapping.sourceDir, f));

test('1.3.2 class mapping: 13 sources, 13 unique classes, 0 duplicates, 0 missing; the excluded second Warrior recorded with its reason', () => {
  const keys = Object.keys(mapping.classes).sort();
  expectEq(keys.join(','), art.CLASSES.join(','), 'exactly the 13 classes');
  expectEq(new Set(Object.values(mapping.classes).map((e) => e.source)).size, 13, 'unique sources');
  expectEq(mapping.excluded.length, 1, 'one excluded image');
  expect(/Warrior/.test(mapping.excluded[0].reason) && /Darren chose/.test(mapping.excluded[0].reason), 'its reason');
  for (const [cls, e] of Object.entries(mapping.classes)) expect(/^[0-9a-f]{64}$/.test(e.sha256) && e.evidence && e.w > 0, cls + ': hash, size, evidence');
});

test('1.3.2 class mapping guard: a duplicate, a missing class, an unknown file, a changed source are each refused', () => {
  const ok = { ...mapping, classes: { ...mapping.classes } };
  const read = (f) => Buffer.from('not the real bytes ' + f);
  const hashed = { ...mapping, classes: Object.fromEntries(Object.entries(mapping.classes).map(([c, e]) => [c, { ...e, sha256: art.sha256(read(e.source)) }])), excluded: mapping.excluded.map((e) => ({ ...e, sha256: art.sha256(read(e.source)) })) };
  // with hashes matching the stand-in bytes only the JPEG header check speaks
  expect(art.verifyMapping(hashed, fakeFiles(), read).every((e) => /baseline/.test(e)), 'clean apart from the stand-in bytes');
  const dup = { ...ok, classes: { ...ok.classes, mage: { ...ok.classes.mage, source: ok.classes.monk.source } } };
  expect(art.verifyMapping(dup, fakeFiles(), read).some((e) => /mapped twice/.test(e)), 'duplicate');
  const missing = { ...ok, classes: { ...ok.classes } }; delete missing.classes.evoker;
  expect(art.verifyMapping(missing, fakeFiles(), read).some((e) => /missing classes: evoker/.test(e)), 'missing class');
  expect(art.verifyMapping(ok, fakeFiles(['Gemini_new.jpeg']), read).some((e) => /neither mapped nor excluded/.test(e)), 'unknown file');
  expect(art.verifyMapping(ok, fakeFiles(), read).some((e) => /changed \(SHA-256/.test(e)), 'changed source');
});

test('1.3.2 sources preserved: every incoming JPEG (13 mapped + the excluded one) has the SHA-256, size and format recorded before processing', () => {
  const dir = path.join(ROOT, mapping.sourceDir);
  if (!fs.existsSync(dir)) {
    // 1.5.0: the incoming JPEGs are private development references - never committed, never public. Where they
    // are not present (a public clone, the release workflow) the record of them is what can be checked: every
    // mapped and excluded source still carries the SHA-256, size and format taken before processing. The bytes
    // themselves are compared only on the machine that holds them.
    const entries = [...Object.values(mapping.classes), ...mapping.excluded];
    expectEq(entries.length, 14, 'the record lists 14 sources');
    for (const e of entries) expect(/^[0-9a-f]{64}$/.test(e.sha256 || '') && e.w > 0 && e.h > 0 && typeof e.source === 'string', 'the record of ' + e.source);
    return;
  }
  const v = art.verifySources(ROOT, mapping);
  expectEq(v.errors.length, 0, 'source check: ' + v.errors.join('; '));
  expectEq(v.files.length, 14, 'the folder holds 14 files');
  for (const e of [...Object.values(mapping.classes), ...mapping.excluded]) {
    const head = art.jpegHeader(realRead(e.source));
    expect(head && head.baseline && head.w === e.w && head.h === e.h, e.source + ' header');
  }
});

// ---- the 13 masters as committed
const prov = JSON.parse(fs.readFileSync(path.join(ROOT, 'assets', 'identity', 'class-provenance.json'), 'utf8'));
const masters = {};
for (const cls of art.CLASSES) {
  const file = path.join(ROOT, 'assets', 'identity', identity.sourceName(cls));
  if (fs.existsSync(file)) masters[cls] = { bytes: fs.readFileSync(file), img: png.decode(fs.readFileSync(file)) };
}

test('1.3.2 masters: 13 class-<class>.png, 1024 x 1024 8-bit RGBA with real alpha (transparent and opaque pixels), the hash the provenance records', () => {
  expectEq(Object.keys(masters).length, 13, 'masters present');
  for (const [cls, m] of Object.entries(masters)) {
    expectEq(m.img.type, 6, cls + ': RGBA');
    expectEq(m.img.w + 'x' + m.img.h, '1024x1024', cls + ': size');
    let zero = 0; let full = 0;
    for (let i = 3; i < m.img.px.length; i += 4) { if (m.img.px[i] === 0) zero++; else if (m.img.px[i] === 255) full++; }
    expect(zero > 100000 && full > 300000, `${cls}: alpha ${zero} clear / ${full} opaque`);
    expectEq(art.sha256(m.bytes), prov.classes[cls].master.sha256, cls + ': provenance hash');
    expectEq(identity.check(m.img).length, 0, cls + ': the identity-icon contract');
  }
});

test('1.3.2 masters: the matte holes found in each source are transparent, the art near the matte grey (steel, silver) opaque, the corners clear', () => {
  for (const [cls, m] of Object.entries(masters)) {
    const p = prov.classes[cls].probes;
    expect(p.transparent.length >= 1, cls + ': at least one hole probe');
    for (const [x, y] of p.transparent) expectEq(A(m.img, x, y), 0, `${cls}: hole at ${x},${y}`);
    for (const [x, y] of p.opaque) expectEq(A(m.img, x, y), 255, `${cls}: art at ${x},${y}`);
    for (const [x, y] of [[0, 0], [1023, 0], [0, 1023], [1023, 1023], [512, 2], [2, 512]]) expectEq(A(m.img, x, y), 0, `${cls}: clear at ${x},${y}`);
  }
  expect(Object.values(prov.classes).reduce((n, c) => n + c.probes.opaque.length, 0) >= 15,'near-matte art probed across the family');
});

test('1.3.2 masters: one family scale - the ring centred within 1 px, every ring radius within 1 px of the others, aspect kept (both ring axes within 1.5 %), sane margins', () => {
  const radii = [];
  for (const cls of art.CLASSES) {
    const m = prov.classes[cls].master;
    expect(Math.abs(m.ring.cx - 512) <= 1 && Math.abs(m.ring.cy - 512) <= 1, `${cls}: centre ${m.ring.cx},${m.ring.cy}`);
    radii.push(m.ring.R);
    expect(Math.abs(m.extent.horizontal - m.extent.vertical) / m.extent.horizontal <= 0.015, `${cls}: extent ${m.extent.horizontal} x ${m.extent.vertical}`);
    for (const side of ['top', 'bottom', 'left', 'right']) expect(m.margins[side] >= 6 && m.margins[side] <= 40, `${cls}: ${side} margin ${m.margins[side]}`);
  }
  expect(Math.max(...radii) - Math.min(...radii) <= 1, 'ring radii ' + radii.join(', '));
});

test('1.3.2 masters: no matte grey left on the seams - under 2 % of each master\'s seam pixels near its matte colour (legitimate steel edges included)', () => {
  for (const cls of art.CLASSES) {
    const m = masters[cls].img; const w = m.w; const mt = prov.classes[cls].extraction.matte;
    let seam = 0; let grey = 0;
    for (let y = 1; y < w - 1; y++) for (let x = 1; x < w - 1; x++) {
      const o = (y * w + x) * 4; const a = m.px[o + 3];
      if (a === 0 || a === 255) continue;
      if (![-4, 4, -w * 4, w * 4].some((d) => m.px[o + d + 3] === 0)) continue;
      seam++;
      if (Math.hypot(m.px[o] - mt[0], m.px[o + 1] - mt[1], m.px[o + 2] - mt[2]) < 20) grey++;
    }
    expect(seam > 3000 && grey / seam < 0.02, `${cls}: ${grey} of ${seam} seam pixels matte grey`);
  }
});

test('1.3.2 masters: each class carries its colour family (a swapped mapping would fail here)', () => {
  for (const cls of art.CLASSES) expect(prov.classes[cls].evidence.pass && art.evidence(masters[cls].img, cls).pass, cls + ': ' + JSON.stringify(prov.classes[cls].evidence));
  // and not another's: Mage's art is not Druid's colours
  expect(!art.evidence(masters.mage.img, 'druid').pass && !art.evidence(masters.druid.img, 'mage').pass, 'mage / druid not interchangeable');
});

// ---- runtime
test('1.3.2 runtime: 256 x 256 TGA from each master; transparent pixels take the nearest visible colour (no black or grey pulled in by the game\'s own filtering)', () => {
  const r = identity.runtimeImage(masters.priest.img);
  expectEq(r.w + 'x' + r.h, '256x256', 'size');
  let edge = 0; let dark = 0;
  for (let y = 1; y < 255; y++) for (let x = 1; x < 255; x++) {
    const o = (y * 256 + x) * 4;
    if (r.px[o + 3] !== 0) continue;
    if (r.px[o + 3 + 4] > 128 || r.px[o + 3 - 4] > 128) { edge++; if (r.px[o] + r.px[o + 1] + r.px[o + 2] < 30) dark++; }
  }
  expect(edge > 100, 'transparent pixels beside the art: ' + edge);
  expect(dark < edge, 'they carry the art colour, not black');
  expectEq(art.sha256(art.runtimeBytes(masters.priest.img)), prov.classes.priest.runtime.sha256, 'the runtime hash the provenance records');
});

test('1.3.2 runtime: a broken or missing master falls back for its class only - the other classes still ship; an unknown name is reported, not shipped', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'banzai-icons-test-'));
  try {
    fs.writeFileSync(path.join(dir, 'class-mage.png'), masters.mage.bytes);
    const opaque = Buffer.alloc(1024 * 1024 * 4, 255);
    fs.writeFileSync(path.join(dir, 'class-monk.png'), png.encode(1024, 1024, opaque));
    fs.writeFileSync(path.join(dir, 'class-druid.png'), Buffer.from('not a png'));
    const corners = Buffer.from(masters.hunter.img.px); // the art with its matte corners left in
    for (const [x, y] of [[0, 0], [1023, 0], [0, 1023], [1023, 1023]]) for (let dy = 0; dy < 4; dy++) for (let dx = 0; dx < 4; dx++) corners[((Math.abs(y - dy)) * 1024 + Math.abs(x - dx)) * 4 + 3] = 255;
    fs.writeFileSync(path.join(dir, 'class-hunter.png'), png.encode(1024, 1024, corners));
    fs.writeFileSync(path.join(dir, 'wizard.png'), masters.mage.bytes);
    const r = identity.prepare(dir);
    expectEq(Object.keys(r.classes).join(','), 'MAGE', 'only the valid class listed');
    expectEq(r.rejected.map((x) => x.name).sort().join(','), 'druid,hunter,monk', 'the broken ones rejected');
    expect(/outside the inscribed circle|opaque/.test(r.rejected.find((x) => x.name === 'monk').errors.join()), 'with the reason');
    expect(/outside the inscribed circle/.test(r.rejected.find((x) => x.name === 'hunter').errors.join()), 'matte left in the corners: rejected');
    expectEq(r.unknown.join(), 'wizard.png', 'unknown name reported');
    expectEq(r.details, null, 'no Details sheet (the simplified family comes later)');
    expect(/MAGE = 'mage'/.test(identity.manifestLua(r)) && !/MONK|DRUID/.test(identity.manifestLua(r)), 'the manifest lists only MAGE');
  } finally { fs.rmSync(dir, { recursive: true, force: true }); }
});

test('1.3.2 nothing but runtime art deployed: the built media holds the 13 TGAs only - no source JPEG, no PNG master, no QA sheet; the build never reads design-references', () => {
  const dist = path.join(ROOT, 'dist');
  const walk = (d) => fs.readdirSync(d, { withFileTypes: true }).flatMap((e) => (e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]));
  const all = walk(dist);
  expect(!all.some((f) => /\.jpe?g$/i.test(f) || /Gemini|qa-|provenance|class-sources/i.test(path.basename(f))), 'no source / QA / manifest file in dist');
  const ids = all.filter((f) => /[\\/]BanzaiIdentity[\\/]/.test(f)).map((f) => path.basename(f)).sort();
  expectEq(ids.join(','), art.CLASSES.map((c) => c + '.tga').join(','), 'BanzaiIdentity: exactly the 13 runtime textures');
  const build = fs.readFileSync(path.join(ROOT, 'tools', 'build.js'), 'utf8').replace(/\/\/[^\n]*/g, '');
  expect(!/design-references|require\('\.\/lib\/(classart|jpeg|matte)'\)/.test(build), 'the build converts the masters only');
});

function run() {
  const passed = results.filter((r) => r.ok).length;
  const failed = results.length - passed;
  const output = results.filter((r) => !r.ok).map((r) => `FAIL ${r.name}\n${r.error}`).join('\n');
  return { passed, failed, output };
}

module.exports = { run, synthetic };
