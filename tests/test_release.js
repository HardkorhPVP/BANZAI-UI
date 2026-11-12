// 1.5.0: the release tooling - what may be in a package (tools/release.js scan), which clients a package is for
// (release.json), how they are named to CurseForge and Wago (tools/publish.js), and that the public source keeps
// nothing private (the tracked tools carry no user path). Pure node; no network, nothing written.
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const release = require('../tools/release');
const publish = require('../tools/publish');

function run() {
  const results = [];
  const test = (name, fn) => { try { fn(); results.push({ name, ok: true }); } catch (e) { results.push({ name, ok: false, error: String(e && e.message || e) }); } };
  const expect = (cond, msg) => { if (!cond) throw new Error(msg); };
  const expectEq = (a, b, msg) => { if (a !== b) throw new Error(`${msg}: expected [${b}], got [${a}]`); };
  const scanOf = (files) => release.scan(Object.keys(files), (rel) => Buffer.from(files[rel]));
  const whats = (r) => r.hits.map((h) => h.what).join(' | ');

  test('package scan: a clean two-addon package passes', () => {
    const r = scanOf({ 'BushidoPrivateRestore/Restore.lua': 'local VERSION = "1.5.0"\n', 'BushidoPrivateRestore/BushidoPrivateRestore.toc': '## Interface: 120105, 16001\n## Version: 1.5.0\n' });
    expectEq(r.hits.length, 0, 'no hit: ' + whats(r));
  });

  test('package scan: a proof or candidate version in a TOC stops the package', () => {
    expect(/proof \/ candidate version/.test(whats(scanOf({ 'A/A.toc': '## Interface: 16001\n## Version: 1.5.0-dev3\n' }))), 'a -dev version');
    expect(/proof \/ candidate version/.test(whats(scanOf({ 'A/A.toc': '## Version: 1.5.0-RC1\n' }))), 'an RC version');
    expectEq(scanOf({ 'A/A.toc': '## Version: 1.5.0\n' }).hits.length, 0, 'a release version passes');
  });

  test('package scan: the proof label may stand only on the line that derives the channel', () => {
    const line = "local CHANNEL = string.find(VERSION, '-dev', 1, true) and 'PRIVATE PROOF' or 'release'\n";
    const ok = scanOf({ 'BushidoPrivateRestore/Restore.lua': line });
    expectEq(ok.hits.length, 0, 'the channel line: ' + whats(ok));
    expectEq(ok.allowed.length, 1, 'and it is recorded as an allowance');
    expect(/private proof label/.test(whats(scanOf({ 'BushidoPrivateRestore/Options.lua': "name = 'PRIVATE PROOF build'\n" }))), 'anywhere else in code');
    expect(/private proof label/.test(whats(scanOf({ 'BushidoPrivateRestore/docs/README.md': 'PRIVATE PROOF\n' }))), 'in the documentation');
    // every occurrence is judged, not only the first
    expect(/private proof label/.test(whats(scanOf({ 'BushidoPrivateRestore/Restore.lua': line + "Print('PRIVATE PROOF')\n" }))), 'a second occurrence in the same file');
  });

  test('package scan: development and private material never ships', () => {
    for (const [file, what] of [['BushidoPrivateRestore/docs/FOREVER-PROOF-3.md', 'proof document'], ['BushidoPrivateCompat/build/mutation-dev3.txt', 'private folder'],
      ['tests/test_compat.lua', 'private folder'], ['BushidoPrivateCompat/WTF/Config.wtf', 'private folder'], ['BushidoPrivateCompat/media/fonts/WantCoffee.ttf', 'not shipped'],
      ['BushidoPrivateCompat/LiveHud.lua', 'Live HUD'], ['BushidoPrivateCompat/notes.bak', 'scratch'], ['BushidoPrivateCompat/SavedVariables/x.lua', 'private folder']]) {
      const r = scanOf({ [file]: 'x\n' });
      expect(r.hits.length > 0 && new RegExp(what, 'i').test(whats(r)), file + ' is refused: ' + whats(r));
    }
    expect(/backup path/.test(whats(scanOf({ 'A/a.lua': '-- forever-dev3-' + '20261111-200311\n' }))), 'a Forever backup snapshot name');
    expect(/backup path/.test(whats(scanOf({ 'A/a.lua': '-- BANZAI-UI-Forever-Backups\n' }))), 'the Forever backup folder');
    expect(/absolute Windows path/.test(whats(scanOf({ 'A/a.lua': 'local p = "D:\\\\Games\\\\x"\n'.replace(/\\\\/g, '\\') }))), 'a drive path');
    expect(/token/.test(whats(scanOf({ 'A/a.lua': 'key = "ghp_' + 'a'.repeat(30) + '"\n' }))), 'a token');
  });

  test('package scan: only the public community invite may stand in the documentation', () => {
    const invite = '- **Discord** - `https://discord.gg/sv2WNwk2WZ` - questions\n';
    expectEq(scanOf({ 'BushidoPrivateRestore/docs/SUPPORT.md': invite }).hits.length, 0, 'the public invite in the docs');
    expect(/Discord/.test(whats(scanOf({ 'BushidoPrivateRestore/Restore.lua': invite }))), 'not in code');
    expect(/Discord/.test(whats(scanOf({ 'BushidoPrivateRestore/docs/SUPPORT.md': 'https://discord.gg/someOtherInvite\n' }))), 'not another invite');
    expect(/Discord/.test(whats(scanOf({ 'BushidoPrivateRestore/docs/SUPPORT.md': 'https://discord.com/api/' + 'webhooks/1/abc\n' }))), 'never a webhook');
  });

  test('clients: the interface numbers name Retail and WoW Forever, and their patch strings', () => {
    expectEq(release.FLAVOR(120105), 'mainline', 'Retail');
    expectEq(release.FLAVOR(16001), 'forever', 'WoW Forever');
    expectEq(release.FLAVOR(16999), 'forever', 'any 16xxx');
    expectEq(release.FLAVOR(17000), 'mainline', 'not above it');
    expectEq(release.FLAVOR(11508), 'mainline', 'nor below it');
    expectEq(publish.patchOf(120105), '12.1.5', 'Retail patch');
    expectEq(publish.patchOf(16001), '1.60.1', 'Forever patch');
    expectEq(publish.CURSE_TYPE.mainline + '/' + publish.CURSE_TYPE.forever, '517/88568', 'CurseForge game-version types');
    expectEq(publish.WAGO_KEY.mainline + '/' + publish.WAGO_KEY.forever, 'supported_retail_patches/supported_forever_patches', 'Wago keys');
    expectEq(publish.WAGO_DATA.forever, 'forever', 'Wago game data name');
  });

  test('the two TOCs: one release version, both clients, the project IDs, no game-type restriction', () => {
    const tocs = ['BushidoPrivateCompat', 'BushidoPrivateRestore'].map((a) => fs.readFileSync(path.join(ROOT, 'addons', a, a + '.toc'), 'utf8'));
    const field = (toc, name) => ((toc.match(new RegExp('^## ' + name + ':\\s*(.+)$', 'm')) || [])[1] || '').trim();
    expectEq(field(tocs[0], 'Version'), field(tocs[1], 'Version'), 'one version');
    expect(/^\d+\.\d+\.\d+(-dev\d+)?$/.test(field(tocs[0], 'Version')), 'a version label');
    for (const toc of tocs) {
      expectEq(field(toc, 'Interface'), '120105, 16001', 'Retail and WoW Forever in one TOC');
      expectEq(field(toc, 'X-Curse-Project-ID'), '1793334', 'CurseForge project');
      expectEq(field(toc, 'X-Wago-ID'), 'BKpEZrGE', 'Wago project');
      expect(!/AllowLoadGameType|ExcludeLoadGameType/.test(toc), 'no game-type restriction');
    }
    expectEq(field(tocs[0], 'Dependencies') + ' | ' + field(tocs[1], 'Dependencies'), 'ElvUI, JiberishMedia | ElvUI', 'required addons as in 1.4.0');
    for (const optional of ['Details', 'Baganator', 'ZygorGuidesViewerForever']) expect(!new RegExp('Dependencies:.*' + optional).test(tocs[0].split('\n').filter((l) => /^## Dependencies/.test(l)).join('')), optional + ' is not required');
  });

  test('public source: no tracked tool, test or addon file carries a user folder path or a game account folder', () => {
    const walk = (dir, out = []) => { for (const e of fs.readdirSync(dir, { withFileTypes: true })) { const f = path.join(dir, e.name); if (e.isDirectory()) walk(f, out); else out.push(f); } return out; };
    const bad = [];
    for (const dir of ['tools', 'tests', 'addons', 'shared', '.github']) {
      for (const file of walk(path.join(ROOT, dir)).filter((f) => /\.(js|lua|toc|yml|ps1)$/.test(f))) {
        const text = fs.readFileSync(file, 'utf8');
        if (/[A-Za-z]:\\\\Users\\\\[A-Za-z]|Account[\\/]+\d{6,}#\d|'\d{9,}#\d'/.test(text)) bad.push(path.relative(ROOT, file));
      }
    }
    expectEq(bad.join(', '), '', 'files with a private path');
    const source = fs.readFileSync(path.join(ROOT, 'tools', 'lib', 'bushido-source.js'), 'utf8');
    expect(/require\('\.\/local'\)\.REFERENCES/.test(source), 'the build reads its references from the configurable place');
    const workflow = fs.readFileSync(path.join(ROOT, '.github', 'workflows', 'release.yml'), 'utf8');
    expect(/node tools\/fetch-references\.js/.test(workflow) && /node tools\/release\.js/.test(workflow), 'the workflow fetches the public references and builds the package itself');
    expect(/the built package is not the reviewed package/.test(workflow), 'and refuses a package that is not the reviewed one');
    expect(/already exists - nothing is published twice/.test(workflow), 'and never publishes a tag twice');
    expect(!/CF_API_KEY: [^$]|WAGO_API_TOKEN: [^$]/.test(workflow), 'secrets only by reference');
  });

  const failed = results.filter((r) => !r.ok);
  return { passed: results.length - failed.length, failed: failed.length, output: failed.map((r) => `FAIL ${r.name}\n${r.error}`).join('\n') };
}

module.exports = { run };
