#!/usr/bin/env node
// Offline tests: run the built addons (dist/) in a Lua VM (fengari) against
// mocked ElvUI / Details / LibSharedMedia state and check the results.
'use strict';

const fs = require('fs');
const path = require('path');
const { lua, lauxlib, lualib, to_luastring, to_jsstring } = require('fengari');

const ROOT = path.join(__dirname, '..');
const DIST = path.join(ROOT, 'dist');

function runLua(files, testFile, flavor) {
  const L = lauxlib.luaL_newstate();
  lualib.luaL_openlibs(L);
  const q = (s) => JSON.stringify(s.replace(/\\/g, '/'));
  // the Lua VM has no file access: hand it the list of deployed JiberishMedia textures
  const texDir = path.join(DIST, 'JiberishMedia', 'textures');
  const textures = fs.existsSync(texDir) ? fs.readdirSync(texDir).filter((f) => /\.tga$/i.test(f)).map((f) => f.replace(/\.tga$/i, '')) : [];
  const prelude = [
    `HK_FLAVOR = ${JSON.stringify(flavor || 'retail')}`, // 1.5.0-dev1: the client the mocks stand in for (retail | forever)
    `HK_TEXTURES = { ${textures.map((t) => `[${JSON.stringify(t)}] = true`).join(', ')} }`,
    `HK_FILES = { ${files.map(q).join(', ')} }`,
    `HK_DIST = ${q(DIST)}`,
    `dofile(${q(path.join(__dirname, 'mocks.lua'))})`,
    `dofile(${q(testFile)})`,
    'return HK_REPORT()',
  ].join('\n');
  if (lauxlib.luaL_loadstring(L, to_luastring(prelude)) !== lua.LUA_OK) {
    return { passed: 0, failed: 1, output: 'load error: ' + to_jsstring(lua.lua_tostring(L, -1)) };
  }
  if (lua.lua_pcall(L, 0, 3, 0) !== lua.LUA_OK) {
    return { passed: 0, failed: 1, output: 'runtime error: ' + to_jsstring(lua.lua_tostring(L, -1)) };
  }
  return { passed: lua.lua_tointeger(L, -3), failed: lua.lua_tointeger(L, -2), output: to_jsstring(lua.lua_tostring(L, -1)) || '' };
}

// the files of each addon in its TOC's load order (0.9.0: read from the built TOC, so new files are tested as they load)
const tocFiles = (addon) => fs.readFileSync(path.join(DIST, addon, addon + '.toc'), 'utf8').split(/\r?\n/).map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
const suites = [
  { file: 'test_restore.lua', addon: 'BushidoPrivateRestore', files: tocFiles('BushidoPrivateRestore') },
  { file: 'test_compat.lua', addon: 'BushidoPrivateCompat', files: tocFiles('BushidoPrivateCompat') },
  // 1.5.0-dev1: the client adapter on Retail (pure functions, no Retail change) and both addons on WoW Forever
  { file: 'test_client.lua', addon: 'BushidoPrivateRestore', files: tocFiles('BushidoPrivateRestore') },
  { file: 'test_forever_restore.lua', addon: 'BushidoPrivateRestore', files: tocFiles('BushidoPrivateRestore'), flavor: 'forever' },
  { file: 'test_forever_compat.lua', addon: 'BushidoPrivateCompat', files: tocFiles('BushidoPrivateCompat'), flavor: 'forever' },
  // 1.5.0-dev3: the Forever chat adapter and the window skins (Banzai Art on WoW Forever), and the same files on Retail
  { file: 'test_forever_skins.lua', addon: 'BushidoPrivateCompat', files: tocFiles('BushidoPrivateCompat'), flavor: 'forever' },
  { file: 'test_retail_skins.lua', addon: 'BushidoPrivateCompat', files: tocFiles('BushidoPrivateCompat') },
];

let passed = 0;
let failed = 0;
// 1.3.2: `node tests/run.js icons|restore|compat` runs one suite (the targeted mutation runner uses it); 1.3.7: | parchment
const only = process.argv[2];
if (!only || only === 'icons') {
  const result = require('./test_icons').run(); // the class-art pipeline (node)
  passed += result.passed;
  failed += result.failed;
  console.log(`${result.failed ? 'FAIL' : 'ok  '} test_icons.js  (${result.passed} passed, ${result.failed} failed)`);
  if (result.output) console.log(result.output.split('\n').map((l) => '     ' + l).join('\n'));
}
if (!only || only === 'release') {
  const result = require('./test_release').run(); // 1.5.0: the package scan, the client metadata and the publish mapping (node)
  passed += result.passed;
  failed += result.failed;
  console.log(`${result.failed ? 'FAIL' : 'ok  '} test_release.js  (${result.passed} passed, ${result.failed} failed)`);
  if (result.output) console.log(result.output.split('\n').map((l) => '     ' + l).join('\n'));
}
if (!only || only === 'parchment') {
  const result = require('./test_parchment').run(); // 1.3.7: the parchment material (node + the built layout in a Lua VM)
  passed += result.passed;
  failed += result.failed;
  console.log(`${result.failed ? 'FAIL' : 'ok  '} test_parchment.js  (${result.passed} passed, ${result.failed} failed)`);
  if (result.output) console.log(result.output.split('\n').map((l) => '     ' + l).join('\n'));
}
for (const suite of suites) {
  if (only && !suite.file.includes(only)) continue;
  const files = suite.files.map((f) => path.join(DIST, suite.addon, f));
  const result = runLua(files, path.join(__dirname, suite.file), suite.flavor);
  passed += result.passed;
  failed += result.failed;
  console.log(`${result.failed ? 'FAIL' : 'ok  '} ${suite.file}  (${result.passed} passed, ${result.failed} failed)`);
  if (result.output) console.log(result.output.split('\n').map((l) => '     ' + l).join('\n'));
}
console.log(`\ntests: ${passed} passed, ${failed} failed`);
process.exit(failed ? 1 : 0);
