// BANZAI 1.5.1 BANZAI Weave asset tests (node): the sheet Darren approved ("Candidate D") as tools/lib/weave.js
// constructs it - seamless, tint-neutral, slashes down to the right at a shallow angle, irregular (no lattice, no
// crosshatch), restrained overall - its strand-layer encoding, the two files in the build (dist/, the folder that is
// packaged and deployed, and nothing else of the design review) and the runtime paths the built addon names.
// Run by tests/run.js (node tests/run.js weave: these and the bar-texture suite).
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const ROOT = path.join(__dirname, '..');
const weave = require('../tools/lib/weave');
const tga = require('../tools/lib/tga');

const MEDIA = path.join(ROOT, 'dist', 'BushidoPrivateCompat', 'media');
const COMPAT = path.join(ROOT, 'dist', 'BushidoPrivateCompat');
// The approved asset, byte for byte (the encoded .tga files). WoW Forever takes these same two files: a change of
// the drawing changes these and must be a decision, never an accident.
const SHA256 = {
  BanzaiWeave: '010eb988c551a41fe9224568d776b3fd3a7debd9ae60186f8f985ff5229dbedd',
  BanzaiWeaveStrands: '2bf3513ce7c71929b4f736674c7bdf38b2a019539ae6f09da522b55c4203c4a0',
};

const results = [];
function test(name, fn) {
  try { fn(); results.push({ name, ok: true }); } catch (e) { results.push({ name, ok: false, error: String((e && e.stack) || e) }); }
}
function expect(cond, msg) { if (!cond) throw new Error(msg); }
function expectEq(a, b, msg) { if (a !== b) throw new Error(`${msg}: expected [${b}], got [${a}]`); }

const W = weave.WEAVE;
const made = weave.generate();
const sheet = made.BanzaiWeave;
const strands = made.BanzaiWeaveStrands;
const list = weave.strokes();
const at = (t, x, y, c = 0) => t.px[(((y % t.h) + t.h) % t.h * t.w + ((x % t.w) + t.w) % t.w) * 4 + c];
const sha = (buf) => crypto.createHash('sha256').update(buf).digest('hex');
const read = (rel) => fs.readFileSync(path.join(COMPAT, rel), 'utf8').replace(/\r\n/g, '\n');

test('the sheet: 256 x 64 (powers of two), two encodings of one drawing, 146 strokes in a fixed order', () => {
  expectEq(sheet.w + 'x' + sheet.h, '256x64', 'the sheet');
  expectEq(W.width + 'x' + W.height, '256x64', 'the size the generator states');
  expect((sheet.w & (sheet.w - 1)) === 0 && (sheet.h & (sheet.h - 1)) === 0, 'powers of two');
  expectEq(strands.w + 'x' + strands.h, '256x64', 'the strand layer');
  expectEq(Object.keys(made).sort().join(','), 'BanzaiWeave,BanzaiWeaveStrands', 'exactly these two files');
  expectEq(list.length, W.streaks + W.slashes, 'every stroke');
  expectEq(W.streaks + '+' + W.slashes, '26+120', '26 broad streaks under 120 slashes');
});

test('seamless: the strokes drawn on a sheet of 2 x 2 tiles in one piece are the tile repeated - in x, in y and at the corners', () => {
  const big = weave.tile(W, 512, 128);
  let differences = 0;
  for (let y = 0; y < 128; y++) for (let x = 0; x < 512; x++) if (big.px[(y * 512 + x) * 4] !== at(sheet, x, y)) differences++;
  expectEq(differences, 0, 'texels that differ between the repeated tile and the continuous drawing');
  // strokes really cross both edges (the wrap is exercised, not avoided)
  expect(list.some((s) => s.x + s.length > W.width), 'a stroke crosses the right edge');
  expect(list.some((s) => s.y + s.length * s.slope > W.height), 'a stroke crosses the bottom edge');
  // the joins are like any other place: no larger step across an edge than the largest inside the sheet
  let inside = 0; let across = 0;
  for (let y = 0; y < 64; y++) for (let x = 0; x < 255; x++) inside = Math.max(inside, Math.abs(at(sheet, x, y) - at(sheet, x + 1, y)));
  for (let y = 0; y < 64; y++) across = Math.max(across, Math.abs(at(sheet, 255, y) - at(sheet, 256, y)));
  expect(across <= inside, `the left / right join shows no step of its own (${across} <= ${inside})`);
  let insideY = 0; let acrossY = 0;
  for (let y = 0; y < 63; y++) for (let x = 0; x < 256; x++) insideY = Math.max(insideY, Math.abs(at(sheet, x, y) - at(sheet, x, y + 1)));
  for (let x = 0; x < 256; x++) acrossY = Math.max(acrossY, Math.abs(at(sheet, x, 63) - at(sheet, x, 64)));
  expect(acrossY <= insideY, `the top / bottom join shows no step of its own (${acrossY} <= ${insideY})`);
});

test('tint-neutral: pure greys on a white base, fully opaque - the bar\'s colour stays the colour', () => {
  let white = 0;
  for (let i = 0; i < sheet.w * sheet.h; i++) {
    expect(sheet.px[i * 4] === sheet.px[i * 4 + 1] && sheet.px[i * 4 + 1] === sheet.px[i * 4 + 2], `texel ${i} has no colour of its own`);
    expectEq(sheet.px[i * 4 + 3], 255, `texel ${i} opaque`);
    if (sheet.px[i * 4] === 255) white++;
  }
  expect(white / (sheet.w * sheet.h) >= 0.15, `a good part of the surface is the untouched base (${(white / (sheet.w * sheet.h)).toFixed(2)}): a tint shows at full strength there`);
});

test('the approved strokes: every one runs DOWN to the right at 24 - 30 degrees; lengths, weights and strengths vary across the approved ranges', () => {
  const deg = (s) => Math.atan(s.slope) * 180 / Math.PI;
  for (const s of list) {
    expect(s.slope > 0, 'down to the right');
    expect(deg(s) >= 23.5 && deg(s) <= 30.5, `a shallow diagonal (${deg(s).toFixed(1)} degrees)`);
    expect(s.length >= 16 && s.length <= 160, `length ${s.length.toFixed(1)}`);
    expect(s.depth > 0 && s.depth <= 0.72, `strength ${s.depth.toFixed(2)}`);
  }
  const slashes = list.slice(W.streaks);
  const streaks = list.slice(0, W.streaks);
  for (const s of streaks) expect(s.width >= 3 && s.width <= 6 && s.depth >= 0.07 && s.depth <= 0.15, 'a broad faint streak');
  for (const s of slashes) expect(s.width >= 0.9 && s.width <= 2.6 && s.depth >= 0.28, 'a slash');
  const spread = (key) => { const v = slashes.map((s) => s[key]); return Math.max(...v) / Math.min(...v); };
  expect(spread('length') >= 3, `lengths vary (x ${spread('length').toFixed(1)})`);
  expect(spread('width') >= 2, `weights vary (x ${spread('width').toFixed(1)})`);
  expect(spread('depth') >= 2, `strengths vary (x ${spread('depth').toFixed(1)})`);
  const bold = slashes.filter((s) => s.width >= 1.6).length;
  expect(bold >= 20 && bold <= 60, `bold and fine slashes together (${bold} bold of ${slashes.length})`);
});

test('one direction, no crosshatch: the surface changes far less along the slashes than across them or along the opposite diagonal', () => {
  let along = 0; let against = 0; let level = 0;
  for (let y = 0; y < 64; y++) for (let x = 0; x < 256; x++) {
    along += Math.abs(at(sheet, x, y) - at(sheet, x + 2, y + 1));   // the slashes' own direction
    against += Math.abs(at(sheet, x, y) - at(sheet, x + 2, y - 1)); // the mirrored diagonal
    level += Math.abs(at(sheet, x, y) - at(sheet, x, y + 2));       // straight down
  }
  expect(against > 2 * along, `the mirrored diagonal is not a direction of the drawing (${against} vs ${along})`);
  expect(level > 2 * along, `nor is the vertical (${level} vs ${along})`);
});

test('irregular, not a lattice: the surface repeats at no shorter period, and the slashes are unevenly spaced', () => {
  for (const period of [4, 8, 16, 32, 64, 128]) {
    let same = 0;
    for (let y = 0; y < 64; y++) for (let x = 0; x < 256; x++) if (at(sheet, x, y) === at(sheet, x + period, y)) same++;
    expect(same / (256 * 64) < 0.75, `the surface does not repeat every ${period} texels (${(same / 16384).toFixed(2)} equal)`);
  }
  for (const period of [4, 8, 16, 32]) {
    let same = 0;
    for (let y = 0; y < 64; y++) for (let x = 0; x < 256; x++) if (at(sheet, x, y) === at(sheet, x, y + period)) same++;
    expect(same / (256 * 64) < 0.75, `nor every ${period} texels down (${(same / 16384).toFixed(2)} equal)`);
  }
  // the gaps between dark runs along the middle row are of many different lengths
  const gaps = new Set(); let run = 0;
  for (let x = 0; x < 256; x++) { if (at(sheet, x, 32) > 215) run++; else if (run) { gaps.add(run); run = 0; } }
  expect(gaps.size >= 6, `uneven spacing (${gaps.size} different gap lengths in one row)`);
});

test('restrained: the bar keeps about four fifths of its brightness, the darkest slash is not black, no blot where strokes overlap', () => {
  const mean = weave.mean(sheet);
  expect(mean >= 0.78 && mean <= 0.84, `mean value 0.78 - 0.84 (${mean.toFixed(4)})`);
  let min = 255;
  for (let i = 0; i < sheet.w * sheet.h; i++) min = Math.min(min, sheet.px[i * 4]);
  expect(min >= 0.26 * 255 && min <= 0.34 * 255, `the darkest texel 0.26 - 0.34 (${(min / 255).toFixed(3)}): overlapping strokes do not add up`);
  let dark = 0;
  for (let i = 0; i < sheet.w * sheet.h; i++) if (sheet.px[i * 4] < 0.5 * 255) dark++;
  expect(dark / (sheet.w * sheet.h) <= 0.12, `strong slashes are a small part of the surface (${(dark / 16384).toFixed(3)})`);
});

test('the strand layer is the same drawing as a layer: black, alpha = 255 - value (surface x layer = the tinted sheet, exactly) - one geometry for the filled and the empty part of a bar', () => {
  for (let i = 0; i < sheet.w * sheet.h; i++) {
    expectEq(strands.px[i * 4] + strands.px[i * 4 + 1] + strands.px[i * 4 + 2], 0, `layer texel ${i} is black`);
    expectEq(strands.px[i * 4 + 3], 255 - sheet.px[i * 4], `layer texel ${i}: alpha is the sheet's darkness`);
  }
  expect(Buffer.compare(weave.strands(sheet).px, strands.px) === 0, 'derived from the sheet\'s texels, nothing drawn twice');
});

test('original: the generator reads no image and no file - geometry and a fixed number sequence only', () => {
  const source = fs.readFileSync(path.join(ROOT, 'tools', 'lib', 'weave.js'), 'utf8');
  expect(!/require\(/.test(source), 'no module is loaded (no file access, no image decoder)');
  expect(!/readFile|\.png|\.jpe?g|\.webp|\.tga|\.blp|decode\(|Math\.random|Date\./i.test(source.replace(/^\s*\/\/.*$/gm, '')), 'no image is read and nothing is left to chance');
  const a = weave.generate(); const b = weave.generate();
  expect(Buffer.compare(a.BanzaiWeave.px, b.BanzaiWeave.px) === 0, 'deterministic: the same texels every time');
  const r = weave.sequence(W.seed); const first = [r(), r(), r()].join(',');
  const r2 = weave.sequence(W.seed);
  expectEq([r2(), r2(), r2()].join(','), first, 'the number sequence is fixed by its seed');
});

test('the build: both files are in dist/ (what is packaged and deployed), decode to the generated texels, and are the approved bytes; nothing else of the design review is built', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(ROOT, 'build-manifest.json'), 'utf8'));
  for (const name of ['BanzaiWeave', 'BanzaiWeaveStrands']) {
    const file = path.join(MEDIA, name + '.tga');
    expect(fs.existsSync(file), `dist has media/${name}.tga`);
    const bytes = fs.readFileSync(file);
    expectEq(bytes.length, 18 + 256 * 64 * 4, `${name}.tga: an uncompressed 32-bit 256 x 64 image`);
    const img = tga.read(file);
    expectEq(img.w + 'x' + img.h, '256x64', `${name}.tga dimensions`);
    expect(Buffer.compare(Buffer.from(img.px), made[name].px) === 0, `${name}.tga holds the generated texels`);
    expectEq(sha(bytes), SHA256[name], `${name}.tga SHA-256 (the approved asset)`);
    expect(manifest[`BushidoPrivateCompat/media/${name}.tga`], `${name}.tga is in the build manifest`);
  }
  expect(fs.existsSync(path.join(MEDIA, 'BanzaiBar.tga')), 'BANZAI Smooth\'s file is still built');
  // development evidence stays out of the package: no candidate, no reference, no proof sheet, no image that is not a .tga
  const built = Object.keys(manifest);
  const weaveFiles = built.filter((f) => /weave/i.test(f)).sort();
  expectEq(weaveFiles.join(','), 'BushidoPrivateCompat/media/BanzaiWeave.tga,BushidoPrivateCompat/media/BanzaiWeaveStrands.tga', 'the only weave files in the build');
  expect(!built.some((f) => /candidate|reference|design-references|docs\/development/i.test(f)), 'no candidate or reference file is built');
  expect(!built.filter((f) => /^BushidoPrivate/.test(f)).some((f) => /\.(png|jpe?g|webp)$/i.test(f)), 'no screenshot or proof image is in the BANZAI addons');
  const build = fs.readFileSync(path.join(ROOT, 'tools', 'build.js'), 'utf8');
  expect(!/weave-candidates|design-references|candidate/i.test(build), 'the build does not know the candidates or the reference');
});

test('runtime paths: every bar file the built Banzai Art names exists in the built media folder, and the sheet\'s size there is the generator\'s', () => {
  const theme = read('Theme.lua');
  expect(/Theme\.MEDIA = 'Interface\\\\AddOns\\\\BushidoPrivateCompat\\\\media\\\\'/.test(theme), 'the media folder of the addon as it is installed');
  const table = (theme.match(/Theme\.BAR_TEXTURES = \{[\s\S]*?\n\}/) || [''])[0];
  const files = [...table.matchAll(/(?:file|strands) = '(\w+)'/g)].map((m) => m[1]);
  expectEq(files.join(','), 'BanzaiBar,BanzaiWeave,BanzaiWeaveStrands', 'the files of the two bar textures');
  for (const f of files) expect(fs.existsSync(path.join(MEDIA, f + '.tga')), `media/${f}.tga exists`);
  expect(/media:Register\('statusbar', def\.label, Theme\.MEDIA \.\. def\.file \.\. '\.tga'\)/.test(theme), 'LibSharedMedia is given the file with its extension');
  const size = theme.match(/Theme\.WEAVE = \{ width = (\d+), height = (\d+),/);
  expect(size, 'the sheet\'s size in the addon');
  expectEq(size[1] + 'x' + size[2], W.width + 'x' + W.height, 'the addon counts texels of the sheet the generator makes');
  const toc = read('BushidoPrivateCompat.toc');
  expect(/## Interface: 120105/.test(toc), 'the Retail / Midnight interface');
  expect(/## Version: 1\.5\.1\r?$/m.test(toc), 'the release version');
});

test('status bars only: the bar texture is given out in the bar code alone - no panel, window skin, chat, tooltip, tracker, button or PvP code names it, and nothing is written for Details or ElvUI', () => {
  const callers = {};
  for (const f of fs.readdirSync(COMPAT).filter((x) => x.endsWith('.lua'))) {
    const code = read(f);
    const calls = (code.match(/Theme:BarWeave\(/g) || []).length + (code.match(/Theme:ShowBarWeave\(/g) || []).length;
    if (calls && f !== 'Theme.lua') callers[f] = calls; // Theme.lua defines them (and names them in its comments)
    if (f !== 'Theme.lua') expect(!/BanzaiWeave/.test(code), `${f} names no weave file itself (Theme.lua owns them)`);
  }
  expectEq(Object.keys(callers).sort().join(','), 'CastBar.lua,Compat.lua,CooldownBars.lua,Preview.lua,Split.lua,TargetPlate.lua', 'the files that give a bar the texture');
  for (const f of ['Skins.lua', 'SkinAdapters.lua', 'ChatLayout.lua', 'Tooltip.lua', 'Tracker.lua', 'Bar.lua', 'Info.lua', 'ActionButtons.lua', 'AFK.lua', 'PvPFrames.lua', 'CastHistory.lua', 'Identity.lua', 'Health.lua']) {
    expect(!/BarWeave|barTexture|WeaveEmpty/.test(read(f)), `${f}: no bar texture`);
  }
  const compat = read('Compat.lua');
  expectEq((compat.match(/Theme:BarWeave\(/g) || []).length, 2, 'Banzai Art itself: a dressed unit frame\'s health and resource bar, nothing else');
  expect(/Compat\.WEAVE_SKIP = \{ '\^ElvUF_Raid', '\^ElvUF_Arena' \}/.test(compat), 'raid and arena frames are left out');
  const restore = path.join(ROOT, 'dist', 'BushidoPrivateRestore');
  const transform = fs.readFileSync(path.join(restore, 'Transform.lua'), 'utf8');
  expect(!/BANZAI Weave|BanzaiWeave|barTexture/.test(transform), 'the profile writer (ElvUI unit frames, nameplates, Details rows) does not know the weave');
  expect(/T\.SMOOTH_TEXTURE = 'Banzai'/.test(transform), 'the written profiles keep the texture they had');
});

test('nothing polls and nothing foreign is scripted: the bar-texture code has no OnUpdate, ticker, timer or hook; it listens to the two scale events and to its own sizer frame', () => {
  const theme = read('Theme.lua');
  const block = theme.slice(theme.indexOf('-- 1.5.1 BAR TEXTURE (BANZAI > APPEARANCE > BAR TEXTURE)'));
  expect(block.length > 1000, 'the bar-texture block');
  expect(!/OnUpdate|NewTicker|C_Timer|hooksecurefunc|HookScript/.test(block), 'no polling, no hook');
  expectEq([...block.matchAll(/'([A-Z_]+_CHANGED)'/g)].map((m) => m[1]).join(','), 'UI_SCALE_CHANGED,DISPLAY_SIZE_CHANGED', 'its events');
  expectEq([...block.matchAll(/(\w+):SetScript\('(\w+)'/g)].map((m) => m[1] + '.' + m[2]).join(','), 'sizer.OnSizeChanged,events.OnEvent', 'scripts on BANZAI\'s own two frames only');
  expect(!/bar:SetScript|bar:SetFrameLevel|bar:SetStatusBarTexture|bar:SetAlpha|fill:Set|bar:SetClipsChildren/.test(block), 'the bar itself is never scripted, re-levelled, re-textured, faded or clipped');
  expect(!/GetValue|GetMinMaxValues|UnitHealth|UnitPower/.test(block), 'no value of a bar is read');
  expectEq((theme.match(/media:Register\('statusbar'/g) || []).length, 2, 'two registration statements (the old name, the loop over the two textures), both in the one media block');
});

function run() {
  const failed = results.filter((r) => !r.ok);
  return { passed: results.length - failed.length, failed: failed.length, output: failed.map((r) => `FAIL ${r.name}\n${r.error}`).join('\n') };
}

module.exports = { run };
