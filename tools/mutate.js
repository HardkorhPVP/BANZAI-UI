#!/usr/bin/env node
// BANZAI targeted mutation tests: only the contracts a milestone changed. Each mutant breaks one rule;
// the suite that guards it must fail. Not a full-project mutation run.
//   1.3.2  the matte segmentation, the seam unmixing / decontamination, the class-source mapping and
//          its uniqueness, the runtime asset validation, the BANZAI-first chain, the per-class fallback
//   1.3.3  the PvP frames' forbidden geometry removed and the safe emphasis (combat deferral), the
//          TARGET NPC preview's isolation (no live / protected object, no asynchronous game media), the
//          125 % Player / Target identity, the spell icon in the centre, the radial progress gone, the
//          class art restored, the bamboo cast bar's geometry and progress direction, interrupted /
//          failed cleanup, the non-interruptible flag unread, BANZAI CLASSIC isolated
//   1.3.4  the PvP access gate, the retired in-tree decoration, no child / script / geometry on a unit frame,
//          refusals cached; the lower cast bar (height, its own bamboo proportions), the text sizes, the width,
//          the central spell-icon states
//   1.3.5  Banzai's line ownership (no Line, rotation or warp; the outlines bound to one health bar), the
//          PvP visuals' cleanup lifecycle (target / focus clears, sweeps, the inactive state, refusals, no
//          polling), developer surfaces hidden by default, the PvP safe layer (the roots), the Details
//          divider (its existence, bounds, width, gradient, alpha, the materials, only on Banzai's frame)
//   1.3.6  the Details centre gutter: its geometry (both layouts), the outer panel kept, both meters equal,
//          every row inside its own window, the update placing the windows geometry only, on Banzai's
//          Details profile only and after combat
//   1.3.7  HARDKORH PARCHMENT as one material: the body tile (repeating, never stretched, its phase), the edge strips
//          (repeated along, mirrored halves, the rows turned), the corners (square, their quadrants, continuing the
//          strips), the seams (no overlap, no crack, the body under the worn pieces, the band's end clear), the brightness
//          on every piece, one shared renderer (every panel; Banzai Art = the preview), the 1.3.6 Details gutter kept
//          (tools/lib/panel.js mutants run the parchment suite, tests/test_parchment.js)
//   node tools/mutate.js font-bakeoff   (after npm run build: only private font-selector contracts)
//   node tools/mutate.js [1.3.2|1.3.3|1.3.4|1.3.5|1.3.6|1.3.7|1.3.8] [word]   (after npm run build: the Lua mutants change dist/
//          copies; the milestone's set, 1.3.8 by default; word: only those mutants)
// Every file is put back exactly as it was, whatever happens.
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.join(__dirname, '..');
const ID_LUA = 'dist/BushidoPrivateCompat/Identity.lua';
const PVP = 'dist/BushidoPrivateCompat/PvPFrames.lua';
const SPLIT = 'dist/BushidoPrivateCompat/Split.lua';
const CASTBAR = 'dist/BushidoPrivateCompat/CastBar.lua';
const THEME = 'dist/BushidoPrivateCompat/Theme.lua';
const TRANSFORM = 'dist/BushidoPrivateRestore/Transform.lua';
const RESTORE = 'dist/BushidoPrivateRestore/Restore.lua';
const COMPAT = 'dist/BushidoPrivateCompat/Compat.lua';
const PREVIEW = 'dist/BushidoPrivateCompat/Preview.lua';

const MUTANTS_132 = [
  // matte segmentation (tools/lib/matte.js)
  ['segmentation', 'tools/lib/matte.js', 'a hole may be tinted (no neutrality test)', ' && st.chroma <= o.maxChroma', ''],
  ['segmentation', 'tools/lib/matte.js', 'a hole may be shaded (no flatness test)', 'st.sd <= o.maxSd && ', ''],
  ['segmentation', 'tools/lib/matte.js', 'a hole may be another grey (no offset test)', 'st.offset <= o.maxOffset && ', ''],
  ['segmentation', 'tools/lib/matte.js', 'a hole may have soft edges (no hard-edge test)', ' && st.hard >= o.minHard', ''],
  ['segmentation', 'tools/lib/matte.js', 'matte holes inside the art never removed', 'if (isHole(st, o.hole)) {', 'if (false) {'],
  ['segmentation', 'tools/lib/matte.js', 'a global colour key (every matte-grey region removed)', 'if (comp.border) {', 'if (true) {'],
  // seam alpha and decontamination
  ['decontamination', 'tools/lib/matte.js', 'the seam colour left as it is (matte grey stays in it)', 'col = est.map((e, k) => F[k] + (e - F[k]) * t);', 'col = C;'],
  ['decontamination', 'tools/lib/matte.js', 'binary alpha (no solved coverage)', 'let a = bestA;', 'let a = isBg ? 0 : 1;'],
  ['decontamination', 'tools/lib/matte.js', 'the deepest pixel as the art colour (the fill behind a thin outline)', 'const score = res - 0.05 * Math.sqrt(ff) + 0.5 * Math.hypot(dx, dy);', 'const score = -toBg[j];'],
  // composition
  ['composition', 'tools/lib/classart.js', 'the ring off the canvas centre', 'fit.cx, fit.cy, size / 2, size / 2);', 'fit.cx, fit.cy, size / 2 + 8, size / 2);'],
  ['composition', 'tools/lib/classart.js', 'protrusions ignored (horns clipped)', '(room * f.R) / f.maxR', 'room'],
  // the class-source manifest
  ['class mapping', 'tools/lib/classart.js', 'a source mapped twice accepted', 'if (used[s]) errors.push(`${s} is mapped twice', 'if (false) errors.push(`${s} is mapped twice'],
  ['class mapping', 'tools/lib/classart.js', 'a missing class accepted', 'if (missing.length) errors.push(', 'if (false) errors.push('],
  ['class mapping', 'tools/lib/classart.js', 'an unmapped file in the folder accepted', 'if (!used[f] && !excluded.includes(f)) errors.push(', 'if (false) errors.push('],
  ['class mapping', 'tools/lib/classart.js', 'a changed source accepted', 'if (hash !== e.sha256) errors.push(', 'if (false) errors.push('],
  // runtime asset validation (tools/lib/identity.js)
  ['runtime validation', 'tools/lib/identity.js', 'a broken master shipped anyway', "result.rejected.push({ name, file: sourceName(name), errors }); continue; }", 'result.rejected.push({ name, file: sourceName(name), errors }); }'],
  ['runtime validation', 'tools/lib/identity.js', 'matte left in the corners accepted', 'if (outside > 0) errors.push(', 'if (false) errors.push('],
  ['runtime validation', 'tools/lib/identity.js', 'transparent pixels not bled (black pulled into the edge)', 'return resampleLib.bleed({ w: CONTRACT.runtime, h: CONTRACT.runtime, px: resample(img, CONTRACT.runtime) });', 'return { w: CONTRACT.runtime, h: CONTRACT.runtime, px: resample(img, CONTRACT.runtime) };'],
  // the BANZAI-first chain and the per-class fallback (the built Identity.lua)
  ['banzai first', ID_LUA, 'BANZAI art never chosen', 'local file = mode ~= \'FABLED\' and Identity.BanzaiFits(where) and Identity.BanzaiFile(classToken)', 'local file = false'],
  ['per-class fallback', ID_LUA, 'one class\'s file used for another', 'manifest.classes[classToken]', 'manifest.classes.MAGE'],
  ['per-class fallback', ID_LUA, 'a bad manifest entry used', "if type(file) == 'string' and string.match(file, '^%l+$') then return file end", "if type(file) == 'string' then return file end"],
  ['per-class fallback', ID_LUA, 'a file the client refuses kept', "== false and art.kind == 'BANZAI' then", "== 'never' then"],
  ['banzai first', ID_LUA, 'the full art at any size', 'return size == nil or size >= Identity.BANZAI_MIN', 'return true'],
  ['banzai first', ID_LUA, 'the frozen nameplate hub given the new art', 'if where.plate or where.noBanzai then return false end', 'if where.noBanzai then return false end'],
  ['banzai first', ID_LUA, 'the classic circles changed under AUTO', "if not c.def.arena and (mode == 'BANZAI' or mode == 'CLASS') then", 'if not c.def.arena then'],
  ['banzai first', ID_LUA, 'the arena enemy circles changed', "if not c.def.arena and (mode == 'BANZAI' or mode == 'CLASS') then", "if (mode == 'BANZAI' or mode == 'CLASS') then"],
];

const MUTANTS_133 = [
  // the PvP frames: no geometry after creation, nothing called on what the client made forbidden, the emphasis shown once
  ['forbidden PvP geometry', PVP, 'Emphasize resizes the border again (1.3.2)', 'for _, edge in ipairs(set) do edge:SetShown(thickness == level.border) end', 'for _, edge in ipairs(set) do edge:SetShown(thickness == level.border) edge:SetHeight(thickness) end'],
  ['forbidden PvP geometry', PVP, 'a forbidden part emphasised (no IsForbidden first)', '\tif not Accessible(parts.frame) then return false end\n\tlocal key = Level(', '\tlocal key = Level('],
  ['forbidden PvP geometry', PVP, 'parts made on a forbidden icon', '\tif not Accessible(button) then return nil end -- 1.3.3: nothing is made on a forbidden icon\n', ''],
  ['forbidden PvP geometry', PVP, 'a forbidden unit frame\'s trinket refreshed', '\tif not (Accessible(c.unitFrame) and Accessible(c)) then return nil end -- 1.3.3: a forbidden tree is left alone\n', ''],
  ['safe overlay emphasis', PVP, 'every refresh re-emphasises every part (1.3.2)', '\tif self.applied == wanted and not force then return false end\n', ''],
  ['safe combat deferral', PVP, 'a level change applied in combat', '\tif InCombatLockdown() then\n\t\tself.emphasisPending = true\n\t\treturn false\n\tend\n', ''],
  // the TARGET NPC preview: synthetic, Banzai media only, no live or protected object
  ['NPC preview isolation', SPLIT, 'the game icon back on the NPC sample (FileData 134153)', 'path = Split.SAMPLE.npcCrest, coords = { 0, 1, 0, 1 }', "path = 'Interface\\\\Icons\\\\INV_Misc_Head_Dragon_01', coords = { 0, 1, 0, 1 }"],
  ['no live preview object', SPLIT, 'the NPC sample asks the live target (portrait, unit tokens)', "\t\tns.Identity.PaintArt(u.hub, { kind = 'CREST'", "\t\tSplit.PaintIdentity(u.hub, 'target', def) ns.Identity.PaintArt(u.hub, { kind = 'CREST'"],
  ['NPC preview isolation', SPLIT, 'the NPC sample casts (a game spell icon)', '\t\t\tif s.npc then -- 1.3.3', '\t\t\tif false then -- 1.3.3'],
  ['no asynchronous preview media', SPLIT, 'the sample\'s media not requested at load', '\tfor i, path in ipairs(Split.NPC_MEDIA) do\n', '\tfor i, path in ipairs({}) do\n'],
  ['no live preview object', SPLIT, 'the NPC sample hub with the radial parts (a cooldown widget, the game shield)', 'local withBar = def.castInterior ~= nil and ns.CastBar ~= nil -- 1.3.3: Player / Target as live', 'local withBar = def.castInterior ~= nil and ns.CastBar ~= nil and not sample.npc -- 1.3.3: Player / Target as live'],
  // the identity 125 %
  ['icon 125 %', SPLIT, 'the Player / Target hubs at their 1.3.2 size', ' * (def.identity or 1) -- 1.3.3: Player / Target 125 %', ''],
  ['icon 125 %', SPLIT, 'Focus enlarged too', "focus = { frame = 'ElvUF_Focus', unit = 'focus', bar = 110,", "focus = { frame = 'ElvUF_Focus', unit = 'focus', identity = 1.25, bar = 110,"],
  ['icon 125 %', TRANSFORM, 'the split layer keeps the 1.3.2 hub (the bars under the larger hub)', ' * (d.identity or 1) -- 1.3.3: Player / Target 125 %', ''],
  // the spell icon alone in the centre, the radial progress gone, the class art back
  ['spell icon replaces the class icon', SPLIT, 'the class art left under the spell icon', '\t\tSplit.Veil(hub, true)\n\t\ttimed = false', '\t\ttimed = false'],
  ['spell icon replaces the class icon', SPLIT, 'no spell icon in the centre (the radial removal taken too far)', "\thub.spell:SetTexture(info.texture) -- the game's icon, unread\n\thub.spell:SetDesaturated(false)\n\thub.spell:Show()", "\thub.spell:SetTexture(info.texture) -- the game's icon, unread\n\thub.spell:SetDesaturated(false)\n\tif not hub.barHub then hub.spell:Show() end"],
  ['radial progress removed', ID_LUA, 'the Player / Target hubs keep the radial cooldown', '\tif bar then return Identity.BarHub(h) end -- 1.3.3', '\tif false then return Identity.BarHub(h) end -- 1.3.3'],
  ['class icon restoration', SPLIT, 'the class art not restored after a cast', '\tif hub.barHub then -- 1.3.3: the class art back, the bar gone\n\t\tSplit.Veil(hub, false)\n', '\tif hub.barHub then -- 1.3.3: the class art back, the bar gone\n'],
  ['class icon restoration', SPLIT, 'the interrupted moment keeps the spell icon', '\t\thub.spell:Hide()\n\t\thub.spell:SetDesaturated(false)\n\t\tSplit.Veil(hub, false)\n\t\tif hub.clock then hub.clock:Hide() end\n\t\tif hub.bar then ns.CastBar.Interrupt', '\t\tif hub.clock then hub.clock:Hide() end\n\t\tif hub.bar then ns.CastBar.Interrupt'],
  ['class icon restoration', ID_LUA, 'the class ring over the full BANZAI art (its own ring hidden)', 'if c.barHub then c.ring:SetShown(not (c.artFull and not c.veiled)) end', 'if c.barHub then c.ring:SetShown(true) end'],
  // the bamboo cast bar
  ['cast bar geometry', SPLIT, 'the bar as wide as one side only', 'g.castWidth = 2 * (g.inner + g.bar) -- the whole composition', 'g.castWidth = g.bar -- the whole composition'],
  ['cast bar geometry', SPLIT, 'the bar over the values (no lift)', 'g.castLift = math.max(math.floor(g.height / 2 + 0.5) + def.castValues, hub / 2) + C.gap', 'g.castLift = math.floor(g.height / 2 + 0.5)'],
  ['cast bar geometry', SPLIT, 'the interior no thicker than the bar', 'castInterior = 37.5, castStalk = 7.5', 'castInterior = 24, castStalk = 7.5'],
  ['cast bar geometry', CASTBAR, 'the spell name off centre', "bar.name:SetPoint('CENTER', bar, 'CENTER', 0, 0)", "bar.name:SetPoint('LEFT', bar, 'LEFT', 12, 0)"],
  ['cast bar geometry', TRANSFORM, 'the class bar left where the cast bar goes', '\tif opts.splitCastBar ~= false then bottom = Round(g.castLift + g.castHeight + C.gap) end\n', ''],
  ['progress direction', CASTBAR, 'a channel fills like a cast', "local direction = (info.kind == 'channel') and Enum.StatusBarTimerDirection.RemainingTime or Enum.StatusBarTimerDirection.ElapsedTime", 'local direction = Enum.StatusBarTimerDirection.ElapsedTime'],
  ['progress direction', CASTBAR, 'a plain-time channel grows', 'bar.status:SetValue(p.channel and (p.start + p.finish - now) or now)', 'bar.status:SetValue(now)'],
  ['progress direction', CASTBAR, 'a fill invented without the game\'s timing', '\tstatus:SetShown(timed) -- the game keeps the timing', '\tstatus:SetShown(true) -- the game keeps the timing'],
  ['interrupted / failed cleanup', SPLIT, 'a FAILED cast kept on the bar', "\t\tif label ~= 'INTERRUPTED' then return Split.Idle(hub) end", '\t\tif false then return Split.Idle(hub) end'],
  ['interrupted / failed cleanup', CASTBAR, 'the bar left on screen after the cast', '\tUnlock(bar)\n\tbar:Hide()\nend', '\tUnlock(bar)\nend'],
  ['interrupted / failed cleanup', CASTBAR, 'no crimson moment', '\tbar.flash:Show()\n', ''],
  ['non-interruptible', CASTBAR, 'the game\'s flag tested (a secret boolean read)', '\t\tif t.SetAlphaFromBoolean then\n\t\t\tt:Show()\n\t\t\tt:SetAlphaFromBoolean(notInterruptible, on, 0)\n\t\telseif', '\t\tif notInterruptible then t:Show() elseif'],
  // BANZAI CLASSIC isolated, the settings carried
  ['classic isolation', SPLIT, 'the split frames built in a CLASSIC session', '\tif not self:Session() or InCombatLockdown() then return false end\n\tfor _, key in ipairs(Split.ORDER) do BuildUnit(key) end', '\tif InCombatLockdown() then return false end\n\tfor _, key in ipairs(Split.ORDER) do BuildUnit(key) end'],
  ['classic isolation', RESTORE, 'the cast-bar choice in a CLASSIC layer\'s signature', "\tif T.FrameStyle(CompatSetting('frameStyle', 'CLASSIC')) == 'SPLIT' then\n\t\topts.frameStyle = 'SPLIT'", "\topts.splitCastBar = true\n\tif T.FrameStyle(CompatSetting('frameStyle', 'CLASSIC')) == 'SPLIT' then\n\t\topts.frameStyle = 'SPLIT'"],
  ['character sync', THEME, 'the cast bar choices not BANZAI settings (not synced)', '\tsplitCastBar = true,        -- the bamboo cast bar', '\t-- splitCastBar = true,        -- the bamboo cast bar'],
];
const MUTANTS_134 = [
  // the PvP frames hands-off: one access gate, nothing decorated inside a unit frame's tree, refusals cached
  ['forbidden object gate', PVP, 'the access gate asks nothing (every frame accessible)', '\t\tif ask and ask(object) then return false end\n', '\t\tif false then return false end\n'],
  ['forbidden object gate', PVP, 'the secret-aspect questions dropped (IsForbidden only, as 1.3.3)', "PvP.ACCESS = { 'IsForbidden', 'HasAnySecretAspect', 'IsAnchoringSecret' }", "PvP.ACCESS = { 'IsForbidden' }"],
  ['forbidden object gate', PVP, 'a hidden swipe state tested', "if IsSecret(running) or not Accessible(c.cd) then PvP.PaintTrinket(c, 'UNKNOWN') else", "if false then PvP.PaintTrinket(c, 'UNKNOWN') else"],
  ['unsafe Decorate removal', PVP, 'the aura icons decorated again on the refresh', '\t\tself:UpdateMarkers(entry)\n\tend\nend', "\t\tself:UpdateMarkers(entry)\n\t\tfor _, key in ipairs({ 'Auras', 'Debuffs' }) do local el = entry.frame[key] if type(el) == 'table' then for b in pairs(el.buttons or {}) do CreateFrame('Frame', nil, b) end end end\n\tend\nend"],
  ['unsafe Decorate removal', PVP, 'Decorate makes a part on the icon again', 'function PvP.Decorate() return nil end', "function PvP.Decorate(button) if type(button) == 'table' then CreateFrame('Frame', nil, button) end return nil end"],
  ['no child CreateFrame on protected PvP frames', PVP, 'the trinket circle a child of the unit frame again (1.3.3)', 'local c = PvP.Trinket(PvP.Layer(), size)', 'local c = PvP.Trinket(frame, size)'],
  ['no child CreateFrame on protected PvP frames', PVP, 'the TARGET marker a child of the arena frame again', "entry.target = PvP.Marker(PvP.Layer(), health, PvP.COLORS.target, 'TARGET', 2, -6)", "entry.target = PvP.Marker(frame, health, PvP.COLORS.target, 'TARGET', 2, -6)"],
  ['no SetScript / HookScript on protected PvP frames', PVP, 'a script assigned on the unit frame', "c.cd:SetScript('OnCooldownDone', function() PvP:UpdateTrinket(c) end) -- Banzai's own cooldown widget", "frame:SetScript('OnShow', function() PvP:UpdateTrinket(c) end) -- Banzai's own cooldown widget"],
  ['no protected geometry mutation', PVP, 'the unit frame re-levelled by Banzai', '\t\t\t\t\tRaise(c, 6)\n', '\t\t\t\t\tRaise(c, 6)\n\t\t\t\t\tframe:SetFrameLevel(type(level) == \'number\' and level or 1)\n'],
  ['unsafe frames cached / skipped', PVP, 'a refused frame probed again on every refresh', '\t\t\tif frame and not built[frame] and not refused[frame] then', '\t\t\tif frame and not built[frame] then'],
  ['unsafe frames cached / skipped', PVP, 'a refused entry asked again on every refresh', '\tif entry.refused or refused[entry.frame] then return false end\n', ''],
  ['unsafe frames cached / skipped', PVP, 'refusals never reconsidered after a loading screen', "\tif event == 'PLAYER_ENTERING_WORLD' then PvP:Reconsider() end\n", ''],
  // the lower bamboo cast bar
  ['cast-bar 40 % height reduction', SPLIT, 'the 1.3.3 interior back (Player)', 'castInterior = 22.5, castStalk = 4.5', 'castInterior = 37.5, castStalk = 4.5'],
  ['cast-bar 40 % height reduction', SPLIT, 'the 1.3.3 bamboo back (Target)', 'castInterior = 19.5, castStalk = 3.75', 'castInterior = 19.5, castStalk = 5.25'],
  ['cast-bar 40 % height reduction', CASTBAR, 'the bamboo squashed (the strip not at its own proportions)', 'local strip = (P.texH / P.texD) * d', 'local strip = d'],
  ['cast-bar 40 % height reduction', TRANSFORM, 'the class bar left at the 1.3.3 height', 'identity = 1.25, castInterior = 22.5, castStalk = 4.5, castValues = 20', 'identity = 1.25, castInterior = 37.5, castStalk = 7.5, castValues = 20'],
  ['text size preservation', SPLIT, 'the spell name made smaller to fit', 'castValues = 20, castName = 16, castTime = 12', 'castValues = 20, castName = 12, castTime = 12'],
  ['text size preservation', SPLIT, 'the timer made smaller', 'castValues = 18, castName = 15, castTime = 11', 'castValues = 18, castName = 15, castTime = 8'],
  ['full-width preservation', SPLIT, 'the bar narrowed', 'g.castWidth = 2 * (g.inner + g.bar) -- the whole composition', 'g.castWidth = 2 * g.bar -- the whole composition'],
  ['central spell-icon state preservation', SPLIT, 'the class art left under the spell icon', '\t\tSplit.Veil(hub, true)\n\t\ttimed = false', '\t\ttimed = false'],
  ['central spell-icon state preservation', SPLIT, 'the class art not back after the cast', '\tif hub.barHub then -- 1.3.3: the class art back, the bar gone\n\t\tSplit.Veil(hub, false)\n', '\tif hub.barHub then -- 1.3.3: the class art back, the bar gone\n'],
  ['central spell-icon state preservation', ID_LUA, 'the radial ring back on the Player / Target hubs', '\tif bar then return Identity.BarHub(h) end -- 1.3.3', '\tif false then return Identity.BarHub(h) end -- 1.3.3'],
];
const MUTANTS_135 = [
  // persistent-line ownership: nothing of Banzai's can reach across the world view
  ['persistent-line ownership', PVP, 'a TARGET / FOCUS outline stretched to the screen corner', "\tm:SetPoint('BOTTOMRIGHT', region, 'BOTTOMRIGHT', inset, -inset)", "\tm:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', inset, -inset)"],
  ['persistent-line ownership', PVP, 'an outline edge anchored outside its outline', '\t\tt:SetPoint(side[2], m, side[2], 0, 0)', '\t\tt:SetPoint(side[2], UIParent, side[2], 0, 0)'],
  ['persistent-line ownership', COMPAT, 'a rotated Banzai texture (the divider turned)', "\t\tt:SetTexture(WHITE)\n\t\tif t.SetSnapToPixelGrid then", "\t\tt:SetTexture(WHITE)\n\t\tt:SetRotation(0.6)\n\t\tif t.SetSnapToPixelGrid then"],
  // the cleanup lifecycle
  ['cleanup lifecycle', PVP, 'a target / focus change waits for the debounced refresh (a cleared TARGET lingers)', "\tif event == 'PLAYER_TARGET_CHANGED' or event == 'PLAYER_FOCUS_CHANGED' then", "\tif event == 'PLAYER_FOCUS_CHANGED' then"],
  ['cleanup lifecycle', PVP, 'no sweep on a loading screen', 'PvP.SWEEP_EVENTS = { PLAYER_ENTERING_WORLD = true, ZONE_CHANGED_NEW_AREA = true, PLAYER_SPECIALIZATION_CHANGED = true }', 'PvP.SWEEP_EVENTS = { ZONE_CHANGED_NEW_AREA = true, PLAYER_SPECIALIZATION_CHANGED = true }'],
  ['cleanup lifecycle', PVP, 'no sweep on a spec change', 'ZONE_CHANGED_NEW_AREA = true, PLAYER_SPECIALIZATION_CHANGED = true }', 'ZONE_CHANGED_NEW_AREA = true }'],
  ['cleanup lifecycle', PVP, 'the spec change not watched', "'PLAYER_REGEN_ENABLED', 'PLAYER_SPECIALIZATION_CHANGED' }) do", "'PLAYER_REGEN_ENABLED' }) do"],
  ['cleanup lifecycle', PVP, 'the sweep hides nothing', '\t\tif entry.root and Accessible(entry.root) then entry.root:Hide() end', '\t\tif false then entry.root:Hide() end'],
  ['cleanup lifecycle', COMPAT, 'Banzai Art switched off: nothing swept', '\tif not active and ns.PvPFrames and ns.PvPFrames.Sweep then ns.PvPFrames:Sweep() end\n', ''],
  ['cleanup lifecycle', PVP, 'the PvP visuals kept while Banzai Art is off', '\tif root and Accessible(root) then root:SetShown(usable and Active()) end', '\tif root and Accessible(root) then root:SetShown(usable) end'],
  ['cleanup lifecycle', PVP, 'a refused entry left showing (not hidden at its root)', '\tif root and Accessible(root) then root:SetShown(usable and Active()) end', '\tif usable and root and Accessible(root) then root:SetShown(Active()) end'],
  ['cleanup lifecycle', PVP, 'a polling loop (OnUpdate refresh)', "events:SetScript('OnEvent', function(_, event)", "events:SetScript('OnUpdate', function() PvP:Refresh() end)\nevents:SetScript('OnEvent', function(_, event)"],
  // developer surfaces hidden by default
  ['debug UI hidden-by-default', THEME, 'a preview surface shown by default (a default-on setting)', "\tpreviewState = 'NORMAL',", "\tpreviewState = 'NORMAL', previewShown = true,"],
  ['debug UI hidden-by-default', PREVIEW, 'a preview sample shown at login', "events:RegisterEvent('PLAYER_REGEN_DISABLED')\nevents:SetScript('OnEvent', function()\n", "events:RegisterEvent('PLAYER_REGEN_DISABLED')\nevents:RegisterEvent('PLAYER_ENTERING_WORLD')\nevents:SetScript('OnEvent', function(_, event)\n\tif event == 'PLAYER_ENTERING_WORLD' then Preview:Show('party', true) return end\n"],
  ['debug UI hidden-by-default', PREVIEW, 'the previews not hidden when combat starts', "events:RegisterEvent('PLAYER_REGEN_DISABLED')\n", ''],
  ['debug UI hidden-by-default', PREVIEW, 'a preview shown in combat', '\tif show and InCombatLockdown() then', '\tif false then'],
  // the PvP safe layer (1.3.4) kept with the roots
  ['PvP safe-layer preservation', PVP, 'the root a child of the unit frame', "\t\t\t\t\tlocal root = CreateFrame('Frame', nil, PvP.Layer())", "\t\t\t\t\tlocal root = CreateFrame('Frame', nil, frame)"],
  ['PvP safe-layer preservation', PVP, 'the root anchored to the health bar (refusals would reach it)', '\t\t\t\t\troot:SetAllPoints(PvP.Layer())', '\t\t\t\t\troot:SetAllPoints(health)'],
  ['PvP safe-layer preservation', PVP, 'the trinket circle outside the root (never swept)', '\t\t\t\t\tlocal c = PvP.Trinket(root, size)', '\t\t\t\t\tlocal c = PvP.Trinket(PvP.Layer(), size)'],
  ['PvP safe-layer preservation', PVP, 'the sweep touches the unit frame', '\t\tif entry.root and Accessible(entry.root) then entry.root:Hide() end', '\t\tif entry.root and Accessible(entry.root) then entry.root:Hide() entry.health:SetAlpha(1) end'],
  ['PvP safe-layer preservation', PVP, 'a UNIT_AURA watcher back', "'PLAYER_REGEN_ENABLED', 'PLAYER_SPECIALIZATION_CHANGED' }) do", "'PLAYER_REGEN_ENABLED', 'PLAYER_SPECIALIZATION_CHANGED', 'UNIT_AURA' }) do"],
  // the Details divider
  ['Details divider existence', COMPAT, 'no divider', '\tframe.divider = DetailsDivider(frame)\n', ''],
  ['Details divider existence', COMPAT, 'shown with one meter closed', '\t\tlocal both = visible and loaded and DetailsWindow(1) ~= nil and DetailsWindow(2) ~= nil or false', '\t\tlocal both = visible and loaded or false'],
  ['Details divider existence', COMPAT, 'drawn on a Details window (not Banzai\'s frame)', '\tframe.divider = DetailsDivider(frame)', '\tframe.divider = DetailsDivider(_G.DetailsBaseFrame2 or frame)'],
  ['Details divider bounds', COMPAT, 'through the top stalk and the titles', '\tlocal top = P.outer + d + V.pad * d\n', '\tlocal top = P.outer\n'],
  ['Details divider bounds', COMPAT, 'through the bottom stalk', '\tlocal bottom = frame.bh - (P.outer + d + V.pad * d)', '\tlocal bottom = frame.bh'],
  ['Details divider bounds', COMPAT, 'off the centre (over a meter)', '\tlocal x, y = frame.bw / 2 - width / 2, top', '\tlocal x, y = frame.bw / 2 - width / 2 + 8, top'],
  ['Details divider bounds', COMPAT, 'over the stalks (OVERLAY)', "\t\tlocal t = holder:CreateTexture(nil, 'BORDER')", "\t\tlocal t = holder:CreateTexture(nil, 'OVERLAY')"],
  ['Details divider bounds', COMPAT, 'a thick bar (6 px)', 'Compat.DETAILS_DIVIDER = { px = 2,', 'Compat.DETAILS_DIVIDER = { px = 6,'],
  ['Details divider bounds', COMPAT, 'blurred (not snapped to the pixel grid)', 'if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(true) end -- crisp', 'if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end -- crisp'],
  ['Details divider material compatibility', COMPAT, 'a neon beam (full alpha)', 'fade = 14, alpha = 0.5, parchment = 0.72 }', 'fade = 14, alpha = 1, parchment = 0.72 }'],
  ['Details divider material compatibility', COMPAT, 'invisible on the parchment', "\tlocal a = Theme:DB().panelBackground == 'PARCHMENT' and V.parchment or V.alpha", "\tlocal a = Theme:DB().panelBackground == 'PARCHMENT' and 0 or V.alpha"],
  ['Details divider material compatibility', COMPAT, 'the gradient upside down', "\t\t\tTheme:Gradient(t, 'VERTICAL', S[i], S[i - 1], a, a)", "\t\t\tTheme:Gradient(t, 'VERTICAL', S[i - 1], S[i], a, a)"],
];
const MUTANTS_136 = [
  // the gutter's geometry (Compat.DETAILS for Banzai Art, T.DETAILS_LAYOUT for the windows Banzai places)
  ['gutter geometry', COMPAT, 'the 1.3.5 gap back (6, the windows 212)', 'width = 207.5, height = 124, gap = 15,', 'width = 212, height = 124, gap = 6,'],
  ['gutter geometry', TRANSFORM, 'the 1.3.5 gap back in the layout Banzai places (6, 212)', 'T.DETAILS_LAYOUT = { width = 207.5, height = 124, gap = 15,', 'T.DETAILS_LAYOUT = { width = 212, height = 124, gap = 6,'],
  ['gutter geometry', COMPAT, 'a 30 px gutter (beyond the 18 - 20 asked)', 'width = 207.5, height = 124, gap = 15,', 'width = 203.75, height = 124, gap = 22.5,'],
  // the outer panel kept
  ['outer panel preserved', COMPAT, 'the panel widened instead (the windows kept at 212)', 'width = 207.5, height = 124, gap = 15,', 'width = 212, height = 124, gap = 15,'],
  ['outer panel preserved', COMPAT, 'the bamboo frame made wider', 'frameWidth = 493.31, frameHeight = 161,', 'frameWidth = 502.31, frameHeight = 161,'],
  // both meters equal
  ['equal meters', RESTORE, 'the left meter wider (into the gutter)', '\t\twindow.posicao.normal.w = L.width / scale', '\t\twindow.posicao.normal.w = (window == left and L.width + 4.5 or L.width) / scale'],
  ['equal meters', RESTORE, 'the left window shifted into the gutter', '\tplace(left, L.right - L.width - L.gap)', '\tplace(left, L.right - L.width - L.gap + 4.5)'],
  // nothing of a meter past its window's edge
  ['rows inside their window', TRANSFORM, 'the CURRENT rows run past the window\'s right edge', '\t\t\t\trow.row_offsets = { left = 0, right = 0, top = S.rowOffset, bottom = 0 }', '\t\t\t\trow.row_offsets = { left = 0, right = 6, top = S.rowOffset, bottom = 0 }'],
  ['rows inside their window', TRANSFORM, 'the COMPACT rows run past the window\'s right edge', '\trow.row_offsets = { left = 0, right = 0, top = C.rowOffset, bottom = 0 }', '\trow.row_offsets = { left = 0, right = 8, top = C.rowOffset, bottom = 0 }'],
  ['rows inside their window', TRANSFORM, 'the value anchored past the bar\'s right end', "\t\t[4] = DetailsText('right', 0, 'right'),", "\t\t[4] = DetailsText('right', 6, 'right'),"],
  // the update places the windows, geometry only
  ['geometry-only update', RESTORE, 'the update forces DAMAGE | HEALING back', '\tif not geometryOnly then\n\t\tlocal segment', '\tif true then\n\t\tlocal segment'],
  ['geometry-only update', RESTORE, 'the update reopens a closed window', '\tif not geometryOnly then\n\t\tfor _, window in ipairs', '\tif true then\n\t\tfor _, window in ipairs'],
  ['geometry-only update', RESTORE, 'no placement at the update (the old 212 / 6 windows stay)', ' then self:LayoutDetailsSoon(true) end', ' then end'],
  // only on Banzai's Details profile, after combat when it is on
  ['update scope', RESTORE, 'another Details profile\'s windows moved', 'details:GetCurrentProfileName() == T.PROFILE then self:LayoutDetailsSoon(true) end', 'details:GetCurrentProfileName() then self:LayoutDetailsSoon(true) end'],
  ['update scope', RESTORE, 'in combat: never placed (no wait for the end of combat)', '\t\tif geometryOnly then self.detailsGeometryPending = true end\n', ''],
  ['update scope', RESTORE, 'after combat the full arrangement (displays forced)', '\t\tRestore:LayoutDetails(true)\n', '\t\tRestore:LayoutDetails()\n'],
];
const PANEL_JS = 'tools/lib/panel.js';
const MUTANTS_137 = [
  // the body: one tile repeating at a fixed density, never stretched
  ['no texture stretching', COMPAT, 'the body stretched to the panel (the tile once over the whole paper, the 1.3.6 fault)', 'local u1, v1 = u0 + pw * M.density / M.tileW, v0 + ph * M.density / M.tileH', 'local u1, v1 = u0 + 1, v0 + 1'],
  ['no texture stretching', COMPAT, 'the body squashed down (half the density down)', 'local u1, v1 = u0 + pw * M.density / M.tileW, v0 + ph * M.density / M.tileH', 'local u1, v1 = u0 + pw * M.density / M.tileW, v0 + ph * M.density / M.tileH / 2'],
  ['no texture stretching', COMPAT, 'the grain scaled with the border (density x the stalk)', 'local u1, v1 = u0 + pw * M.density / M.tileW, v0 + ph * M.density / M.tileH', 'local u1, v1 = u0 + pw * M.density * d / 10 / M.tileW, v0 + ph * M.density * d / 10 / M.tileH'],
  ['centre tiles', COMPAT, 'the body clamped instead of repeating', "tile = { Theme.MEDIA .. 'BanzaiParchmentTile', 'REPEAT', 'REPEAT' }", "tile = { Theme.MEDIA .. 'BanzaiParchmentTile', 'CLAMP', 'CLAMP' }"],
  ['centre tiles', COMPAT, 'every panel the same patch of paper (no phase)', 'local phase = M.phase[kind] or M.phase.chat', 'local phase = M.phase.chat'],
  ['centre tiles', PANEL_JS, 'the tile not seamless (its noise not wrapped)', 'const x0 = ((xi % nx) + nx) % nx; const x1 = (x0 + 1) % nx;', 'const x0 = ((xi % nx) + nx) % nx; const x1 = x0 + 1;'],
  ['centre tiles', PANEL_JS, 'the tile\'s grain stretched across (half the cells across)', 'const fibre = oct(640, 320, 1) * 0.25 + oct(186, 93, 2) * 0.5 + oct(43, 21, 3) * 0.25;', 'const fibre = oct(320, 320, 1) * 0.25 + oct(93, 93, 2) * 0.5 + oct(21, 21, 3) * 0.25;'],
  ['centre tiles', PANEL_JS, 'the paper colour changed (the 10 % lift lost)', '* k * PARCH.lift));', '* k));'],
  // the worn edge strips: repeated along, at the corners' density
  ['edge tiling', COMPAT, 'the top / bottom strips stretched over their half (one period whatever the length)', 'local uw, uh = (mx - c) / period, (my - c) / period', 'local uw, uh = 1, (my - c) / period'],
  ['edge tiling', COMPAT, 'the side strips stretched', 'local uw, uh = (mx - c) / period, (my - c) / period', 'local uw, uh = (mx - c) / period, 1'],
  ['edge tiling', COMPAT, 'the strips clamped along instead of repeating', "edge = { Theme.MEDIA .. 'BanzaiParchmentEdge', 'REPEAT', 'CLAMP' }", "edge = { Theme.MEDIA .. 'BanzaiParchmentEdge', 'CLAMP', 'CLAMP' }"],
  ['edge tiling', COMPAT, 'the right half not mirrored (a step where the halves meet)', "add('top2', 'edge', mx, 0, pw - c, c, uw, 0, uw, 0.25, 0, 0, 0, 0.25)", "add('top2', 'edge', mx, 0, pw - c, c, 0, 0, 0, 0.25, uw, 0, uw, 0.25)"],
  ['edge tiling', PANEL_JS, 'the torn line not repeating over the strip (a step every period)', 'w += weight * Math.sin((2 * Math.PI * n * phase) / PERIOD + seed * m);', 'w += weight * Math.sin((2 * Math.PI * n * 1.1 * phase) / PERIOD + seed * m);'],
  ['edge tiling', PANEL_JS, 'neighbouring strip rows not turned (filtering bleeds across rows)', 'const depth = row % 2 === 0 ? t : BAND - t;', 'const depth = t;'],
  // the corners keep their shape and continue the strips
  ['corner preservation', COMPAT, 'the corners stretched (a third of the panel wide)', 'local c = math.min(Compat.PANEL.parchmentCorner * d, pw / 2, ph / 2)', 'local c = math.min(pw / 3, ph / 2)'],
  ['corner preservation', COMPAT, 'a corner reading the wrong quadrant', "add('TOPRIGHT', 'corners', pw - c, 0, pw, c, 0.5, 0, 0.5, 0.5, 1, 0, 1, 0.5)", "add('TOPRIGHT', 'corners', pw - c, 0, pw, c, 0, 0, 0, 0.5, 0.5, 0, 0.5, 0.5)"],
  ['corner preservation', PANEL_JS, 'the corners not continuing the strips (phase not run backwards)', 'const ph = -Math.abs(sx - half); const pv = -Math.abs(sy - half);', 'const ph = sx - half; const pv = sy - half;'],
  // seams: no overlap, no crack, the body under the worn pieces, the band's end clear
  ['seam handling', COMPAT, 'the old overlap allowance back (doubled darkening at every join)', "t:SetPoint('BOTTOMRIGHT', holder, 'TOPLEFT', inset + piece.x1, -(inset + piece.y1))", "t:SetPoint('BOTTOMRIGHT', holder, 'TOPLEFT', inset + piece.x1 + 0.25, -(inset + piece.y1 + 0.25))"],
  ['seam handling', COMPAT, 'a strip half short of its corner (an open crack)', "add('left2', 'edge', 0, my, c, ph - c, uh, 1, 0, 1, uh, 0.75, 0, 0.75)", "add('left2', 'edge', 0, my, c, ph - c - 1, uh, 1, 0, 1, uh, 0.75, 0, 0.75)"],
  ['seam handling', COMPAT, 'the worn pieces on the body\'s sublevel (in any order with it)', "piece.texture == 'tile' and 0 or 1", '0'],
  ['seam handling', PANEL_JS, 'the darkening still running at the band\'s end (a line where the strips end)', 'fade: 1.1, fadeDark: 0.2', 'fade: 2.6, fadeDark: 0.2'],
  ['seam handling', PANEL_JS, 'the torn line lost (nothing darkened outside it)', 'if (dist < 0) return WEAR.outside;', 'if (dist < 0) return 1;'],
  // brightness on the whole material alike
  ['brightness propagation', COMPAT, 'the brightness on the body only', 't:SetVertexColor(k, k, k, 1)', "if t.piece == 'body' then t:SetVertexColor(k, k, k, 1) end"],
  ['brightness propagation', PANEL_JS, 'the worn pieces coloured (a tint the brightness scales unevenly)', 'px[o] = 0; px[o + 1] = 0; px[o + 2] = 0;', 'px[o] = 40; px[o + 1] = 30; px[o + 2] = 20;'],
  // one shared renderer: every panel, Banzai Art and the preview alike
  ['shared renderer', COMPAT, 'BUFFS with a parchment of its own (a thinner edge)', 'local pieces = Compat.ParchmentLayout(W - 2 * inset, H - 2 * inset, d, holder.artKind)', "local pieces = Compat.ParchmentLayout(W - 2 * inset, H - 2 * inset, holder.artKind == 'buffs' and 7 or d, holder.artKind)"],
  ['shared renderer', PANEL_JS, 'the preview lays the parchment out unlike Banzai Art (its strips half as long)', 'const uw = (mx - c) / period; const uh = (my - c) / period;', 'const uw = (mx - c) / period / 2; const uh = (my - c) / period;'],
  // the 1.3.6 Details gutter and the divider kept
  ['Details gutter preservation', COMPAT, 'the gutter closed again (the 1.3.5 windows)', 'width = 207.5, height = 124, gap = 15,', 'width = 212, height = 124, gap = 6,'],
  ['Details gutter preservation', COMPAT, 'the parchment over the divider (its body on BORDER)', "local t = holder:CreateTexture(nil, 'BACKGROUND', nil, piece.texture == 'tile' and 0 or 1)", "local t = holder:CreateTexture(nil, piece.texture == 'tile' and 'BORDER' or 'BACKGROUND', nil, piece.texture == 'tile' and 0 or 1)"],
];
// 1.3.8: the launcher host (BanzaiSland hosts the top-centre identity; the saved logo preference is never written)
const MUTANTS_138 = [
  ['host registration', COMPAT, 'the host ignored (the standalone wordmark stays)', "self.logo:SetShown(active and db.logo and not combat and not self:LauncherHosted() and true or false)", "self.logo:SetShown(active and db.logo and not combat and true or false)"],
  ['host registration', COMPAT, 'the push side lost (SetLauncherHost records nothing)', 'Compat.launcherHost = host\n\tCompat:UpdateBranding()', 'Compat:UpdateBranding()'],
  ['host registration', COMPAT, 'the pull side lost (the API never asked)', "if type(api) == 'table' and type(api.HostsBanzaiLauncher) == 'function' then", 'if false then'],
  ['host registration', COMPAT, "a host answer of anything counts (the API's false taken as hosting)", 'return ok and hosted == true', 'return ok'],
  ['host release', COMPAT, 'a release ignored (nil keeps the last host)', "if type(host) ~= 'string' or host == '' then host = nil end", "if type(host) ~= 'string' or host == '' then host = Compat.launcherHost end"],
  ['host release', COMPAT, 'the (name, false) form hosts instead of releasing', 'if on == false then host = nil end', 'if on == true then host = nil end'],
  ['saved preference preservation', COMPAT, 'the host written into the saved preference', 'Compat.launcherHost = host\n\tCompat:UpdateBranding()', 'Compat.launcherHost = host\n\tTheme:DB().logo = not host\n\tCompat:UpdateBranding()'],
  ['saved preference preservation', COMPAT, 'the preference ignored while unhosted', "self.logo:SetShown(active and db.logo and not combat and not self:LauncherHosted() and true or false)", "self.logo:SetShown(active and not combat and not self:LauncherHosted() and true or false)"],
  ['no polling', COMPAT, 'a ticker polling the host', 'Compat.launcherHost = host\n\tCompat:UpdateBranding()', "Compat.launcherHost = host\n\tC_Timer.After(1, function() Compat:UpdateBranding() end)\n\tCompat:UpdateBranding()"],
  ['BANZAI-only state', COMPAT, 'the standalone hidden whenever BanzaiSland merely exists (API present, not hosting)', 'return ok and hosted == true', 'return true'],
];
const MUTANTS_FONT_BAKEOFF = [
  ['selection lock default', 'dist/BushidoPrivateCompat/FontBakeoff.lua', 'the semantic default no longer resolves to Shojumaru', 'local DEFAULT_KEY = "SHOJUMARU"', 'local DEFAULT_KEY = "INFORMATION"'],
  ['selection lock scale', 'dist/BushidoPrivateCompat/FontBakeoff.lua', 'BANZAI Default loses its 105% base', 'local DEFAULT_SCALE = 1.05', 'local DEFAULT_SCALE = 1'],
  ['selection lock migration', THEME, 'a retired saved face survives normalization', "if not self.DISPLAY_FACE_SET[db.displayFace] then db.displayFace = 'BANZAI_DEFAULT' end", "if false then db.displayFace = 'BANZAI_DEFAULT' end"],
  ['selection lock fallback', 'dist/BushidoPrivateCompat/FontBakeoff.lua', 'unsupported text does not use Information Font as a whole', 'if face.information or not supports(face, text) then return self:SmallFont() end', 'if face.information then return self:SmallFont() end'],
  ['selection lock fallback size', 'dist/BushidoPrivateCompat/FontBakeoff.lua', 'default fallback retains the 105% scaled size', 'if defaultChoice and id == DEFAULT_KEY and path == self:SmallFont() then adjusted = fallbackSize end', 'if defaultChoice and id == DEFAULT_KEY and path == self:SmallFont() then adjusted = size end'],
];
const SETS = { '1.3.2': MUTANTS_132, '1.3.3': MUTANTS_133, '1.3.4': MUTANTS_134, '1.3.5': MUTANTS_135, '1.3.6': MUTANTS_136, '1.3.7': MUTANTS_137, '1.3.8': MUTANTS_138, 'font-bakeoff': MUTANTS_FONT_BAKEOFF };

function suiteFor(file) {
  if (file.startsWith('dist/BushidoPrivateRestore/')) return 'restore';
  if (file === PANEL_JS) return 'parchment'; // 1.3.7: the parchment material's generator and the preview's layout
  return file.startsWith('dist/') ? 'compat' : 'icons';
}

const originals = new Map();
function restoreAll() { for (const [file, text] of originals) fs.writeFileSync(file, text); originals.clear(); }
process.on('SIGINT', () => { restoreAll(); process.exit(130); });

function main() {
  const set = SETS[process.argv[2]] ? process.argv[2] : '1.3.8';
  const MUTANTS = SETS[set];
  const only = SETS[process.argv[2]] ? process.argv[3] : process.argv[2]; // a word of the mutants to run (all when absent)
  for (const rel of new Set(MUTANTS.map((m) => m[1]).filter((r) => r.startsWith('dist/')))) {
    if (!fs.existsSync(path.join(ROOT, rel))) throw new Error('run npm run build first (the Lua mutants change the built ' + rel + ')');
    if (fs.readFileSync(path.join(ROOT, rel), 'utf8') !== fs.readFileSync(path.join(ROOT, rel.replace(/^dist\//, 'addons/')), 'utf8')) throw new Error('dist/ is older than addons/ (' + rel + ') - run npm run build first');
  }
  // the suites must pass unmutated
  for (const suite of [...new Set(MUTANTS.map((m) => suiteFor(m[1])))]) {
    const r = spawnSync(process.execPath, [path.join(ROOT, 'tests', 'run.js'), suite], { cwd: ROOT, encoding: 'utf8' });
    if (r.status !== 0) throw new Error(`the ${suite} suite fails without any mutation:\n${r.stdout}`);
  }
  const rows = [];
  console.log(`BANZAI ${set} targeted mutants (${MUTANTS.length})`);
  for (const [contract, rel, what, find, replace] of MUTANTS.filter((m) => !only || m[2].includes(only) || m[0].includes(only))) {
    const file = path.join(ROOT, rel);
    const text = fs.readFileSync(file, 'utf8');
    const count = text.split(find).length - 1;
    if (count !== 1) { rows.push({ contract, what, rel, result: `NOT APPLIED (${count} matches)` }); continue; }
    originals.set(file, text);
    try {
      fs.writeFileSync(file, text.replace(find, () => replace));
      const t0 = Date.now();
      const r = spawnSync(process.execPath, [path.join(ROOT, 'tests', 'run.js'), suiteFor(rel)], { cwd: ROOT, encoding: 'utf8' });
      const failed = (r.stdout.match(/tests: \d+ passed, (\d+) failed/) || [])[1];
      rows.push({ contract, what, rel, result: r.status !== 0 ? `killed (${failed || '?'} failing)` : 'SURVIVED', ms: Date.now() - t0 });
    } finally { restoreAll(); }
    const last = rows[rows.length - 1];
    console.log(`${last.result.startsWith('killed') ? 'killed  ' : 'SURVIVED'}  [${contract}] ${what}  (${rel}, ${last.ms} ms)`);
  }
  const killed = rows.filter((r) => r.result.startsWith('killed')).length;
  console.log(`\nmutation: ${killed} of ${rows.length} mutants killed` + (killed === rows.length ? '' : ' - survivors: ' + rows.filter((r) => !r.result.startsWith('killed')).map((r) => r.what).join('; ')));
  process.exit(killed === rows.length ? 0 : 1);
}

try { main(); } catch (e) { restoreAll(); console.error(String(e.message || e)); process.exit(1); }
