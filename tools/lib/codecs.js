// Decoders for the serialized strings inside Bushido's Config.lua (read-only use).
//   decodeForPrint   LibDeflate:DecodeForPrint
//   inflate          LibDeflate:DecompressDeflate (raw deflate)
//   aceDeserialize   AceSerializer-3.0
//   libDeserialize   LibSerialize (format used by WeakAuras `!WA:2!` exports)
'use strict';

const zlib = require('zlib');

const PRINT_ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()';

function decodeForPrint(text) {
  const bytes = [];
  let acc = 0;
  let bits = 0;
  for (const ch of text.trim()) {
    const value = PRINT_ALPHABET.indexOf(ch);
    if (value < 0) throw new Error(`invalid print character "${ch}"`);
    acc |= value << bits;
    bits += 6;
    while (bits >= 8) {
      bytes.push(acc & 0xff);
      acc >>>= 8;
      bits -= 8;
    }
  }
  return Buffer.from(bytes);
}

function inflate(buffer) {
  return zlib.inflateRawSync(buffer);
}

// With { typedKeys: true } tables come back as Map objects so number and
// string keys stay distinct (ElvUI stores spell IDs as number keys).
function aceDeserialize(text, options = {}) {
  if (!text.startsWith('^1')) throw new Error('not an AceSerializer-3.0 string');
  const tokens = [];
  const re = /\^(.)([^^]*)/g;
  re.lastIndex = 2;
  let match;
  while ((match = re.exec(text))) tokens.push([match[1], match[2]]);

  // AceSerializer-3.0 escapes: ~z = \030, ~} = "^", ~| = "~", ~{ = DEL, otherwise char(n + 64) for n <= 32
  const unescape = (s) => s.replace(/~(.)/g, (_, c) => {
    if (c === 'z') return '\x1e';
    if (c === '}') return '^';
    if (c === '|') return '~';
    if (c === '{') return '\x7f';
    return String.fromCharCode(c.charCodeAt(0) - 64);
  });

  let i = 0;
  function value() {
    const [type, data] = tokens[i++];
    switch (type) {
      case 'S': return unescape(data);
      case 'N': return Number(data);
      case 'F': { const [, exponent] = tokens[i++]; return Number(data) * Math.pow(2, Number(exponent)); }
      case 'B': return true;
      case 'b': return false;
      case 'Z': return null;
      case 'T': {
        const table = options.typedKeys ? new Map() : {};
        while (tokens[i][0] !== 't') {
          const key = value();
          const entry = value();
          if (options.typedKeys) table.set(key, entry); else table[key] = entry;
        }
        i++;
        return table;
      }
      default: throw new Error(`unknown AceSerializer token ^${type}`);
    }
  }

  const values = [];
  while (i < tokens.length && tokens[i][0] !== '^') values.push(value());
  return values;
}

// LibSerialize v1 reader. Arrays become JS objects keyed 1..n (Lua semantics kept).
function libDeserialize(buffer) {
  let pos = 0;
  const stringRefs = [];
  const tableRefs = [];
  const byte = () => buffer[pos++];
  const int = (n) => { let v = 0; for (let k = 0; k < n; k++) v = v * 256 + byte(); return v; };
  const str = (n) => { const s = buffer.toString('latin1', pos, pos + n); pos += n; if (n > 2) stringRefs.push(s); return s; };

  // Table references are registered before the contents are read (as LibSerialize does).
  function readTable(count, table) {
    if (!table) { table = {}; tableRefs.push(table); }
    for (let k = 0; k < count; k++) { const key = object(); table[key] = object(); }
    return table;
  }
  function readArray(count, table) {
    if (!table) { table = {}; tableRefs.push(table); }
    for (let k = 1; k <= count; k++) table[k] = object();
    return table;
  }
  function readMixed(arrayCount, mapCount) {
    const table = {};
    tableRefs.push(table);
    readArray(arrayCount, table);
    readTable(mapCount, table);
    return table;
  }
  const rawString = (n) => { const s = buffer.toString('latin1', pos, pos + n); pos += n; return s; };

  // LibSerialize._ReaderIndex (NIL = 0 ... TABLEREF_24 = 31)
  const readers = {
    0: () => null,
    1: () => int(2), 2: () => -int(2), 3: () => int(3), 4: () => -int(3),
    5: () => int(4), 6: () => -int(4), 7: () => int(7), 8: () => -int(7),
    9: () => { const v = buffer.readDoubleBE(pos); pos += 8; return v; },
    10: () => Number(rawString(byte())), 11: () => -Number(rawString(byte())),
    12: () => true, 13: () => false,
    14: () => str(int(1)), 15: () => str(int(2)), 16: () => str(int(3)),
    17: () => readTable(int(1)), 18: () => readTable(int(2)), 19: () => readTable(int(3)),
    20: () => readArray(int(1)), 21: () => readArray(int(2)), 22: () => readArray(int(3)),
    23: () => { const a = int(1); return readMixed(a, int(1)); },
    24: () => { const a = int(2); return readMixed(a, int(2)); },
    25: () => { const a = int(3); return readMixed(a, int(3)); },
    26: () => stringRefs[int(1) - 1], 27: () => stringRefs[int(2) - 1], 28: () => stringRefs[int(3) - 1],
    29: () => tableRefs[int(1) - 1], 30: () => tableRefs[int(2) - 1], 31: () => tableRefs[int(3) - 1],
  };

  function object() {
    const value = byte();
    if (value % 2 === 1) return (value - 1) / 2;
    if (value % 4 === 2) {
      const shifted = (value - 2) / 4;
      const type = shifted % 4;
      const count = (shifted - type) / 4;
      if (type === 0) return str(count);
      if (type === 1) return readTable(count);
      if (type === 2) return readArray(count);
      return readMixed(count % 4 + 1, Math.floor(count / 4) + 1);
    }
    if (value % 8 === 4) {
      const packed = byte() * 256 + value;
      return value % 16 === 12 ? -(packed - 12) / 16 : (packed - 4) / 16;
    }
    const reader = readers[value / 8];
    if (!reader) throw new Error(`unknown LibSerialize type ${value / 8} at ${pos - 1}`);
    return reader();
  }

  pos = 1; // version byte
  return object();
}

// Historical ElvUI "!E1!" export -> { type, key, data } (data as typed Maps)
function decodeElvUIExport(text) {
  const raw = inflate(decodeForPrint(text.replace(/^!E1!/, ''))).toString('latin1');
  const m = raw.match(/^([\s\S]*)::([^:]*)::([\s\S]*)$/) || raw.match(/^([\s\S]*)::([^:]*)$/);
  if (!m) throw new Error('unexpected ElvUI export layout');
  return { type: m[2], key: m[3], data: aceDeserialize(m[1], { typedKeys: true })[0] };
}

// Details "print" export -> { profile, playerData, globaData, version } (typed Maps)
function decodeDetailsExport(text) {
  const raw = inflate(decodeForPrint(text)).toString('latin1');
  return aceDeserialize(raw, { typedKeys: true })[0];
}

module.exports = { decodeForPrint, inflate, aceDeserialize, libDeserialize, decodeElvUIExport, decodeDetailsExport };
