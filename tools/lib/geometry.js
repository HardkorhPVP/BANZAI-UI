// Turns Bushido's historical WeakAuras data into the static placement table
// BushidoPrivateCompat draws (generated locally, never committed).
'use strict';

const codecs = require('./codecs');

// WeakAuras frameStrata index -> strata ("inherited" regions sat in the
// WeakAuras frame; LOW keeps them with the unit frames).
const STRATA = { 1: 'LOW', 2: 'BACKGROUND', 3: 'LOW', 4: 'MEDIUM', 5: 'HIGH', 6: 'DIALOG' };
const UNIT_FRAMES = ['ElvUF_Player', 'ElvUF_Target', 'ElvUF_TargetTarget', 'ElvUF_Focus', 'ElvUF_Pet'];
const UNIT_TOKENS = { ElvUF_Player: 'player', ElvUF_Target: 'target', ElvUF_TargetTarget: 'targettarget', ElvUF_Focus: 'focus', ElvUF_Pet: 'pet' };
const round = (n) => Math.round(Number(n || 0) * 100) / 100;

function decodeAura(text) {
  return codecs.libDeserialize(codecs.inflate(codecs.decodeForPrint(text.replace(/^!WA:2!/, ''))));
}

function color(c) {
  if (!c || c[1] === undefined) return [1, 1, 1, 1];
  return [round(c[1] * 1000) / 1000, round(c[2] * 1000) / 1000, round(c[3] * 1000) / 1000, c[4] === undefined ? 1 : round(c[4] * 1000) / 1000];
}

function textureOf(region) {
  const path = String(region.texture || '');
  if (/Square_White$/i.test(path)) return { texture: 'WHITE' };
  if (/^Interface\\/i.test(path)) {
    const file = path.split(/[\\/]/).pop();
    return { texture: file };
  }
  return { atlas: path }; // e.g. Crosshair_unableAttack_128
}

function classColorsOf(region) {
  const colors = {};
  for (const cond of Object.values(region.conditions || {})) {
    const check = cond.check || {};
    if (check.variable !== 'class') continue;
    for (const change of Object.values(cond.changes || {})) {
      if (change.property === 'color' && change.value && change.value[1] !== undefined) colors[check.value] = color(change.value);
    }
  }
  return colors;
}

function partOf(region) {
  const rotation = region.rotate ? Number(region.rotation || 0) : 0;
  const half = rotation === 180;
  return {
    id: region.id,
    ...textureOf(region),
    w: round(region.width),
    h: round(region.height),
    x: round(region.xOffset),
    y: round(region.yOffset),
    strata: STRATA[region.frameStrata] || 'LOW',
    color: color(region.color),
    flipH: Boolean(region.mirror) !== half,
    flipV: half,
    rotation: half ? 0 : rotation,
    classColored: Object.keys(classColorsOf(region)).length > 0,
  };
}

// Bushido's Details frame and swords were placed in screen coordinates around
// Details window 1 (bottom window, libwindow BOTTOMRIGHT). Banzai anchors them
// to that window instead, so they stay on it. Screen size of the historical
// layout: UI scale 0.71 (Bushido global payload), 16:9.
const HISTORICAL_HALF_HEIGHT = 768 / 0.71 / 2;
const HISTORICAL_HALF_WIDTH = HISTORICAL_HALF_HEIGHT * 16 / 9;

function detailsAnchor(payloads) {
  const details = codecs.decodeDetailsExport(payloads['Details.Profile1String']);
  const window1 = details.get('profile').get('instances').get(1);
  const lw = window1.get('libwindow');
  if (lw.get('point') !== 'BOTTOMRIGHT') throw new Error('Details window 1 is not anchored BOTTOMRIGHT in the payload');
  return { x: HISTORICAL_HALF_WIDTH + lw.get('x'), y: -HISTORICAL_HALF_HEIGHT + lw.get('y') };
}

function build(payloads) {
  const geometry = {
    media: 'Interface\\AddOns\\JiberishMedia\\textures\\',
    classColors: {},
    units: UNIT_FRAMES.map((frame) => ({ frame, unit: UNIT_TOKENS[frame], parts: [] })),
    party: [], raid: [], boss: [], minimap: [], details: [],
    skipped: [],
  };
  const unitIndex = Object.fromEntries(geometry.units.map((u) => [u.frame, u]));

  for (const key of ['WeakAuras.Profile1String', 'WeakAuras.Profile2String', 'WeakAuras.Profile3String', 'WeakAuras.Profile4String']) {
    const aura = decodeAura(payloads[key]);
    for (const region of Object.values(aura.c || {})) {
      Object.assign(geometry.classColors, classColorsOf(region));
      if (region.regionType !== 'texture') {
        geometry.skipped.push(`${region.id} (${region.regionType}: replaced by mMediaTag cast ring / not restored)`);
        continue;
      }
      const part = partOf(region);
      const anchor = region.anchorFrameFrame || '';
      const unit = region.triggers && region.triggers[1] && region.triggers[1].trigger && region.triggers[1].trigger.unit;
      if (region.anchorFrameType === 'SELECTFRAME' && unitIndex[anchor]) {
        unitIndex[anchor].parts.push(part);
      } else if (region.anchorFrameType === 'SELECTFRAME' && /^ElvUF_Boss1$/.test(anchor)) {
        geometry.boss.push(part);
      } else if (region.anchorFrameType === 'SELECTFRAME' && /^ElvUF_Boss\d$/.test(anchor)) {
        // same art on boss 2-8: drawn from the Boss1 entry for every boss frame
      } else if (region.anchorFrameType === 'SELECTFRAME' && anchor === 'Minimap') {
        geometry.minimap.push(part);
      } else if (region.anchorFrameType === 'UNITFRAME' && /party/i.test(unit || '')) {
        geometry.party.push(part);
      } else if (region.anchorFrameType === 'UNITFRAME' && /raid/i.test(unit || '')) {
        geometry.raid.push(part);
      } else if (region.anchorFrameType === 'SCREEN' && /Details/i.test(region.id)) {
        geometry.details.push(part);
      } else if (region.anchorFrameType === 'SCREEN' && /^BushidoCombat(Nemesis)?$/.test(region.id)) {
        // the two combat mascots between Player and Target: not part of Banzai (0.6.0)
        geometry.skipped.push(`${region.id} (combat mascot: removed in Banzai 0.6.0)`);
      } else {
        geometry.skipped.push(`${region.id} (unhandled anchor ${region.anchorFrameType} ${anchor})`);
      }
    }
  }
  const corner = detailsAnchor(payloads);
  for (const part of geometry.details) {
    part.anchor = { point: 'BOTTOMRIGHT', x: round(part.x - corner.x), y: round(part.y - corner.y) };
  }
  return geometry;
}

// Lua string literal for arbitrary latin1 text (escapes everything non-printable)
function luaString(text) {
  let out = '"';
  for (const ch of text) {
    const code = ch.charCodeAt(0);
    if (ch === '"' || ch === '\\') out += '\\' + ch;
    else if (code < 32 || code > 126) out += '\\' + code;
    else out += ch;
  }
  return out + '"';
}

function luaNumber(n) {
  if (Number.isInteger(n)) return String(n);
  return String(n); // JS shortest round-trip representation is exact for doubles
}

// JS value -> Lua literal. Map keeps key types (number keys stay numbers).
function lua(value, indent = '') {
  if (value === null || value === undefined) return 'nil';
  if (typeof value === 'boolean') return String(value);
  if (typeof value === 'number') return luaNumber(value);
  if (typeof value === 'string') return luaString(value);
  const next = indent + '\t';
  if (value instanceof Map) {
    if (!value.size) return '{}';
    const entries = [];
    for (const [k, v] of value) {
      const key = typeof k === 'number' ? `[${luaNumber(k)}]` : (/^[A-Za-z_][A-Za-z0-9_]*$/.test(k) && !LUA_KEYWORDS.has(k) ? k : `[${luaString(String(k))}]`);
      entries.push(`${next}${key} = ${lua(v, next)}`);
    }
    return `{\n${entries.join(',\n')},\n${indent}}`;
  }
  if (Array.isArray(value)) {
    if (value.every((v) => typeof v !== 'object')) return `{ ${value.map((v) => lua(v)).join(', ')} }`;
    return `{\n${value.map((v) => next + lua(v, next)).join(',\n')},\n${indent}}`;
  }
  const keys = Object.keys(value);
  if (!keys.length) return '{}';
  const key = (k) => (/^[A-Za-z_][A-Za-z0-9_]*$/.test(k) && !LUA_KEYWORDS.has(k) ? k : `[${luaString(k)}]`);
  return `{\n${keys.map((k) => `${next}${key(k)} = ${lua(value[k], next)}`).join(',\n')},\n${indent}}`;
}

const LUA_KEYWORDS = new Set(['and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'goto', 'if', 'in',
  'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while']);

function toLua(geometry, source) {
  const { skipped, ...data } = geometry;
  return [
    '-- GENERATED LOCALLY by tools/build.js from Bushido commit ' + source + ' (historical WeakAuras data).',
    '-- Part of BANZAI UI. Derived from the historical Bushido WeakAuras data and redistributed with the original author\'s permission.',
    '-- Skipped: ' + skipped.join('; '),
    'local _, ns = ...',
    'ns.Geometry = ' + lua({ source, ...data }),
    '',
  ].join('\n');
}

module.exports = { build, toLua, lua };
