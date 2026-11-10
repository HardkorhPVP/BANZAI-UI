// BANZAI 1.3.7 HARDKORH PARCHMENT material tests (node): the three generated textures (the tile, the worn edge
// strips, the corner atlas) as tools/lib/panel.js makes them - seamless, unstretched, joined without a step - and the
// parchment layout of the built Banzai Art (Compat.ParchmentLayout, run in a Lua VM) against the offline preview's
// (panel.parchmentLayout). Run by tests/run.js (node tests/run.js parchment: only these).
'use strict';

const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const ROOT = path.join(__dirname, '..');
const panel = require('../tools/lib/panel');

const results = [];
function test(name, fn) {
  try { fn(); results.push({ name, ok: true }); } catch (e) { results.push({ name, ok: false, error: String((e && e.stack) || e) }); }
}
function expect(cond, msg) { if (!cond) throw new Error(msg); }
function expectEq(a, b, msg) { if (a !== b) throw new Error(`${msg}: expected [${b}], got [${a}]`); }
function expectNear(a, b, msg, eps = 1e-9) { if (!(Math.abs(a - b) <= eps)) throw new Error(`${msg}: expected ${b}, got ${a}`); }

const M = panel.PARCHMENT;
const P = panel.PANEL;
const tile = panel.parchmentTile();
const edge = panel.parchmentEdge();
const corners = panel.parchmentCorners();
const at = (t, x, y, c) => t.px[(y * t.w + x) * 4 + c];
const luma = (t, x, y) => 0.2126 * at(t, x, y, 0) + 0.7152 * at(t, x, y, 1) + 0.0722 * at(t, x, y, 2);
const BAND = M.edgeH / 4;

// ---- the built Banzai Art's layout, in a Lua VM ----------------------------------------------------------------
const compatFile = path.join(ROOT, 'dist', 'BushidoPrivateCompat', 'Compat.lua');
const compat = fs.existsSync(compatFile) ? fs.readFileSync(compatFile, 'utf8').replace(/\r\n/g, '\n') : '';
// a table constructor from `head` to its matching brace
function luaTable(code, head) {
  const a = code.indexOf(head);
  if (a < 0) return '';
  let depth = 0;
  for (let i = code.indexOf('{', a); i < code.length; i++) {
    if (code[i] === '{') depth++;
    else if (code[i] === '}' && --depth === 0) return code.slice(a, i + 1);
  }
  return '';
}
function luaFunction(code, head) {
  const a = code.indexOf(head);
  return a < 0 ? '' : code.slice(a, code.indexOf('\nend\n', a) + 5);
}
function luaLayouts(cases) {
  const chunk = [
    'local Compat = {}',
    luaTable(compat, 'Compat.PANEL = {'),
    luaTable(compat, 'Compat.PARCHMENT = {'),
    luaFunction(compat, 'function Compat.ParchmentLayout('),
    'local out = {}',
    'for _, c in ipairs(CASES) do',
    '\tlocal pieces, band, period = Compat.ParchmentLayout(c[1], c[2], c[3], c[4])',
    '\tlocal rows = { string.format("%.17g %.17g", band, period) }',
    '\tfor _, q in ipairs(pieces) do',
    '\t\tlocal k = {}',
    '\t\tfor i = 1, 8 do k[i] = string.format("%.17g", q.coords[i]) end',
    '\t\trows[#rows + 1] = string.format("%s %s %.17g %.17g %.17g %.17g %s", q.name, q.texture, q.x0, q.y0, q.x1, q.y1, table.concat(k, " "))',
    '\tend',
    '\tout[#out + 1] = table.concat(rows, ";")',
    'end',
    'return table.concat(out, "\\n")',
  ].join('\n');
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const cases0 = 'CASES = { ' + cases.map((c) => `{ ${c[0]}, ${c[1]}, ${c[2]}, ${c[3] === null ? 'nil' : JSON.stringify(c[3])} }`).join(', ') + ' }';
  if (lauxlib.luaL_loadstring(L, to_luastring(cases0 + '\n' + chunk)) !== lua.LUA_OK) throw new Error('load: ' + to_jsstring(lua.lua_tostring(L, -1)));
  if (lua.lua_pcall(L, 0, 1, 0) !== lua.LUA_OK) throw new Error('run: ' + to_jsstring(lua.lua_tostring(L, -1)));
  return to_jsstring(lua.lua_tostring(L, -1)).split('\n').map((line) => line.split(';'));
}

test('1.3.7 the material\'s numbers: Compat.PARCHMENT in the built Banzai Art = tools/lib/panel.js PARCHMENT (tile 1024 x 512 at 2 texels per unit, strips 512 x 256, corner atlas 128, 8 corner sizes a strip period, the panels\' phases); one band = PANEL.parchmentCorner x the stalk', () => {
  expect(compat.length > 1000, 'built Compat.lua (npm run build)');
  const t = luaTable(compat, 'Compat.PARCHMENT = {');
  const num = (k) => Number((t.match(new RegExp(`\\b${k} = ([0-9.]+)`)) || [])[1]);
  for (const k of ['tileW', 'tileH', 'density', 'edgeW', 'edgeH', 'corners', 'period']) expectEq(num(k), M[k], `PARCHMENT.${k}`);
  for (const [kind, ph] of Object.entries(M.phase)) {
    const m = t.match(new RegExp(`${kind} = \\{ ([0-9.]+), ([0-9.]+) \\}`));
    expect(m && Number(m[1]) === ph[0] && Number(m[2]) === ph[1], `phase ${kind}`);
  }
  expectEq(Object.keys(M.phase).sort().join(), 'buffs,chat,details', 'a phase for each panel with a background');
  expectEq(M.edgeW / BAND, M.period, 'a strip period is 8 bands (the texels across a band = the texels along one)');
  expectEq(M.corners / 2, BAND, 'a corner is one band: 64 texels both ways');
});

test('1.3.7 the built Banzai Art and the offline preview lay the parchment out the same: every piece, its place and its texture coordinates, at the real panels\' sizes, synthetic sizes and border scales', () => {
  const cases = [];
  const inset = (d) => P.outer + P.parchment * d;
  for (const d of [10, 8.5, 7]) {
    for (const [W, H, kind] of [[493.31, 161, 'chat'], [493.31, 161, 'details'], [335, 96, 'buffs'], [335, 127, 'buffs'], [120, 330, 'chat'], [260, 260, 'details'], [560, 200, 'buffs'], [1400, 150, 'details'], [30, 20, 'chat'], [600, 90, null]]) {
      cases.push([W - 2 * inset(d), H - 2 * inset(d), d, kind]);
    }
  }
  const lua0 = luaLayouts(cases);
  cases.forEach((c, i) => {
    const js = panel.parchmentLayout(c[0], c[1], c[2], c[3] || undefined);
    const rows = lua0[i];
    const [band, period] = rows[0].split(' ').map(Number);
    expectNear(band, js.band, `case ${i} band`); expectNear(period, js.period, `case ${i} period`);
    expectEq(rows.length - 1, js.pieces.length, `case ${i}: pieces`);
    js.pieces.forEach((q, k) => {
      const f = rows[k + 1].split(' ');
      expectEq(f[0] + ' ' + f[1], q.name + ' ' + q.texture, `case ${i} piece ${k}`);
      [q.x0, q.y0, q.x1, q.y1, ...q.coords].forEach((v, j) => expectNear(Number(f[2 + j]), v, `case ${i} ${q.name} value ${j}`, 1e-12));
    });
  });
});

test('1.3.7 the tile: 1024 x 512, opaque, seamless both ways (its wrap no steeper than its own steps), the approved paper colour (the 1.1.0 sheet\'s middle within 1 %: warm cream, restrained tan), the same grain across as down', () => {
  expectEq(tile.w + 'x' + tile.h, M.tileW + 'x' + M.tileH, 'size');
  for (let i = 3; i < tile.px.length; i += 4) if (tile.px[i] !== 255) throw new Error('a translucent texel at ' + (i >> 2));
  // seams: the step across the wrap against the steps inside
  let wrapX = 0; let inX = 0; let nX = 0;
  for (let y = 0; y < tile.h; y++) { wrapX += Math.abs(luma(tile, 0, y) - luma(tile, tile.w - 1, y)); for (const x of [100, 400, 700, 1000]) { inX += Math.abs(luma(tile, x + 1, y) - luma(tile, x, y)); nX++; } }
  let wrapY = 0; let inY = 0; let nY = 0;
  for (let x = 0; x < tile.w; x++) { wrapY += Math.abs(luma(tile, x, 0) - luma(tile, x, tile.h - 1)); for (const y of [60, 200, 340, 480]) { inY += Math.abs(luma(tile, x, y + 1) - luma(tile, x, y)); nY++; } }
  const rx = (wrapX / tile.h) / (inX / nX); const ry = (wrapY / tile.w) / (inY / nY);
  expect(rx < 1.25 && ry < 1.25, `wrap steps ${rx.toFixed(2)} / ${ry.toFixed(2)} x the steps inside`);
  // colour: the 1.1.0 sheet's middle (inside its darkened edge) and the tile, mean per channel
  const legacy = panel.legacyParchment();
  const mean = (t, x0, y0, x1, y1) => { const s = [0, 0, 0]; let n = 0; for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) { for (let c = 0; c < 3; c++) s[c] += at(t, x, y, c); n++; } return s.map((v) => v / n); };
  const a = mean(legacy, 120, 120, 392, 392); const b = mean(tile, 0, 0, tile.w, tile.h);
  for (let c = 0; c < 3; c++) expect(Math.abs(a[c] - b[c]) <= 2.55 * 1.5, `channel ${c}: ${b[c].toFixed(1)} vs the 1.1.0 paper ${a[c].toFixed(1)}`);
  expect(b[0] > b[1] + 12 && b[1] > b[2] + 25 && b[2] > 150, `warm cream (${b.map((v) => v.toFixed(0)).join(', ')})`);
  let lo = 255; let hi = 0; for (let y = 0; y < tile.h; y += 4) for (let x = 0; x < tile.w; x += 4) { const g = at(tile, x, y, 1); lo = Math.min(lo, g); hi = Math.max(hi, g); }
  expect(hi - lo > 12 && hi - lo < 60, `restrained variation (green ${lo} - ${hi})`);
  // isotropic: the mean step across = the mean step down (no direction stretched into the tile itself)
  let sx = 0; let sy = 0; let n = 0;
  for (let y = 0; y < tile.h - 1; y++) for (let x = 0; x < tile.w - 1; x++) { sx += Math.abs(luma(tile, x + 1, y) - luma(tile, x, y)); sy += Math.abs(luma(tile, x, y + 1) - luma(tile, x, y)); n++; }
  expect(sx / sy > 0.92 && sx / sy < 1.08, `the same grain across as down (${(sx / sy).toFixed(3)})`);
});

test('1.3.7 the worn edge strips: 512 x 256, black (they only darken the paper under them), four rows of 64 alternately turned so neighbouring rows meet on equal texels; each row repeats along its length; its inner part clear, its outer side scorched; the torn line 0.1 - 0.6 stalks in, the darkening gone 1.1 stalks inside it - before the band ends', () => {
  expectEq(edge.w + 'x' + edge.h, M.edgeW + 'x' + M.edgeH, 'size');
  for (let i = 0; i < edge.px.length; i += 4) if (edge.px[i] || edge.px[i + 1] || edge.px[i + 2]) throw new Error('a coloured texel at ' + (i >> 2));
  const alpha = (x, y) => at(edge, x, y, 3);
  const DT = BAND / P.parchmentCorner; // texels per stalk diameter
  for (let row = 0; row < 4; row++) {
    const depthRow = (depth) => row * BAND + (row % 2 === 0 ? depth : BAND - 1 - depth); // texel row at `depth` texels from the outer side
    for (let x = 0; x < edge.w; x += 7) {
      for (let k = 0; k < Math.floor(BAND - 1.75 * DT); k++) if (alpha(x, depthRow(BAND - 1 - k)) !== 0) throw new Error(`row ${row}: the inner part not clear at ${x}, depth ${BAND - 1 - k}`);
      expect(alpha(x, depthRow(0)) >= 170, `row ${row}: the outer side scorched at ${x} (${alpha(x, depthRow(0))})`);
    }
    // repeats along: the last column next to the first like any two neighbours
    let wrap = 0; let inner = 0; let n = 0;
    for (let k = 0; k < BAND; k++) { const y = row * BAND + k; wrap += Math.abs(alpha(0, y) - alpha(edge.w - 1, y)); for (const x of [50, 200, 350]) { inner += Math.abs(alpha(x + 1, y) - alpha(x, y)); n++; } }
    expect(wrap / BAND <= 1.5 * (inner / n) + 1, `row ${row}: seamless along (wrap ${(wrap / BAND).toFixed(2)}, inside ${(inner / n).toFixed(2)})`);
  }
  for (const y of [BAND, 2 * BAND, 3 * BAND]) for (let x = 0; x < edge.w; x++) expect(Math.abs(alpha(x, y - 1) - alpha(x, y)) <= 2, `rows meet on equal texels at ${y} (${x})`);
  // the torn line over a whole period, in stalk diameters, and where the darkening ends
  let lo = Infinity; let hi = -Infinity;
  for (const side of ['top', 'right', 'bottom', 'left']) for (let a = 0; a < M.edgeW; a += 0.5) { const t = panel.tearAt(side, a) / DT; lo = Math.min(lo, t); hi = Math.max(hi, t); }
  expect(lo >= 0.08 && hi <= 0.62, `the torn line ${lo.toFixed(2)} - ${hi.toFixed(2)} d in`);
  expect(hi + panel.WEAR.fade < P.parchmentCorner - 0.5, 'the darkening ends well inside the band');
  expectEq(panel.wearFactor(panel.WEAR.fade * DT + 0.01), 1, 'nothing darkened past the fade');
  expect(panel.wearFactor(-1) === panel.WEAR.outside && panel.WEAR.outside > 0, 'outside the torn line: scorched, not cut away (opaque paper)');
  expect(Math.abs(panel.tearAt('top', 3) - panel.tearAt('top', 3 + M.edgeW)) < 1e-9, 'the torn line repeats every strip period');
});

test('1.3.7 the corner atlas joins the strips without a step: the texels where a corner meets its strip are the strip\'s own first texels (every side, every corner), the corners darken only (black), square 128 with 64 per corner', () => {
  expectEq(corners.w + 'x' + corners.h, M.corners + 'x' + M.corners, 'size');
  for (let i = 0; i < corners.px.length; i += 4) if (corners.px[i] || corners.px[i + 1] || corners.px[i + 2]) throw new Error('a coloured texel at ' + (i >> 2));
  const ca = (x, y) => at(corners, x, y, 3); const ea = (x, y) => at(edge, x, y, 3);
  const last = M.edgeW - 1; // the strip texel just before phase 0 (REPEAT: next to its first)
  let worst = 0;
  const same = (a, b, what) => { worst = Math.max(worst, Math.abs(a - b)); if (Math.abs(a - b) > 1) throw new Error(`${what}: ${a} vs ${b}`); };
  for (let k = 0; k < BAND; k++) {
    // depth k from the outer side
    same(ca(63, k), ea(last, k), `TOPLEFT | top, depth ${k}`);
    same(ca(64, k), ea(last, k), `TOPRIGHT | top, depth ${k}`);
    same(ca(63, 127 - k), ea(last, 2 * BAND + k), `BOTTOMLEFT | bottom, depth ${k}`);
    same(ca(64, 127 - k), ea(last, 2 * BAND + k), `BOTTOMRIGHT | bottom, depth ${k}`);
    same(ca(k, 63), ea(last, 4 * BAND - 1 - k), `TOPLEFT | left, depth ${k}`);
    same(ca(k, 64), ea(last, 4 * BAND - 1 - k), `BOTTOMLEFT | left, depth ${k}`);
    same(ca(127 - k, 63), ea(last, 2 * BAND - 1 - k), `TOPRIGHT | right, depth ${k}`);
    same(ca(127 - k, 64), ea(last, 2 * BAND - 1 - k), `BOTTOMRIGHT | right, depth ${k}`);
  }
  expect(worst <= 1, 'byte for byte (rounding)');
  expect(ca(0, 0) >= 170 && ca(127, 127) >= 170, 'the outer corners scorched');
  expectEq(ca(63, 63) + ca(64, 64), 0, 'the inner corners clear (the body shows)');
});

test('1.3.7 the layout never stretches: the body\'s texels per unit equal across and down on every size; the corners square; the strips repeat along at the corners\' density; the worn pieces share their sides exactly and cover exactly the band', () => {
  for (const [pw, ph, d, kind] of [[481.31, 149, 10, 'chat'], [481.31, 149, 10, 'details'], [323, 84, 10, 'buffs'], [323, 115, 10, 'buffs'], [108, 318, 10, 'chat'], [1388, 138, 10, 'details'], [400, 140, 7, 'chat']]) {
    const { pieces, band: c, period } = panel.parchmentLayout(pw, ph, d, kind);
    const by = Object.fromEntries(pieces.map((q) => [q.name, q]));
    expectNear(c, P.parchmentCorner * d, `${pw} x ${ph}: the band`);
    expectNear(period, M.period * c, `${pw} x ${ph}: the period`);
    const k = by.body.coords;
    expectNear(((k[4] - k[0]) * M.tileW) / pw, M.density, `${pw} x ${ph}: body across`);
    expectNear(((k[3] - k[1]) * M.tileH) / ph, M.density, `${pw} x ${ph}: body down`);
    const tpu = BAND / c;
    for (const n of ['top1', 'top2', 'bottom1', 'bottom2']) expectNear((Math.abs(by[n].coords[4] - by[n].coords[0]) * M.edgeW) / (by[n].x1 - by[n].x0), tpu, `${n} along`, 1e-9);
    for (const n of ['left1', 'left2', 'right1', 'right2']) expectNear((Math.abs(by[n].coords[2] - by[n].coords[0]) * M.edgeW) / (by[n].y1 - by[n].y0), tpu, `${n} along`, 1e-9);
    let area = 0;
    const worn = pieces.filter((q) => q.texture !== 'tile');
    for (const q of worn) area += (q.x1 - q.x0) * (q.y1 - q.y0);
    for (let i = 0; i < worn.length; i++) for (let j = i + 1; j < worn.length; j++) {
      const a = worn[i]; const b = worn[j];
      expect(Math.min(a.x1, b.x1) - Math.max(a.x0, b.x0) <= 1e-9 || Math.min(a.y1, b.y1) - Math.max(a.y0, b.y0) <= 1e-9, `${a.name} / ${b.name} overlap`);
    }
    expectNear(area, pw * ph - (pw - 2 * c) * (ph - 2 * c), `${pw} x ${ph}: the band covered exactly`, 1e-6);
  }
});

test('1.3.7 publication: the parchment generator reads no file and no image (Banzai-owned procedural art; tools/lib/panel.js needs only tools/lib/bamboo.js), the built code names only its own three media files, no local path', () => {
  const src = fs.readFileSync(path.join(ROOT, 'tools', 'lib', 'panel.js'), 'utf8');
  expect(!/readFileSync|tga\.read|\.png|\.jpe?g|design-references|http/.test(src.replace(/\/\/[^\n]*/g, '')), 'no file read, no reference, no download');
  expectEq([...src.matchAll(/require\('([^']+)'\)/g)].map((m) => m[1]).join(), './bamboo', 'only the shared bamboo helpers');
  expect(compat.includes("tile = { Theme.MEDIA .. 'BanzaiParchmentTile', 'REPEAT', 'REPEAT' }") && compat.includes("corners = { Theme.MEDIA .. 'BanzaiParchmentCorners', 'CLAMP', 'CLAMP' }") && compat.includes("edge = { Theme.MEDIA .. 'BanzaiParchmentEdge', 'REPEAT', 'CLAMP' }"), 'the three Banzai textures, in the addon\'s own media folder');
  expect(!/'BanzaiParchment'/.test(compat) && !/[A-Z]:\\\\|Users\\\\|\/Users\//.test(compat), 'the 1.1.0 sheet no longer used; no local path');
});

function run() {
  const passed = results.filter((r) => r.ok).length;
  const failed = results.length - passed;
  const output = results.filter((r) => !r.ok).map((r) => `FAIL ${r.name}\n${r.error}`).join('\n');
  return { passed, failed, output };
}

module.exports = { run };
