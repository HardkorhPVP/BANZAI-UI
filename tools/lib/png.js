// Minimal PNG reader for Darren's original BANZAI identity art (tools/lib/identity.js):
// 8-bit RGBA (colour type 6) or RGB (2), non-interlaced - the formats the asset
// contract allows. Returns { w, h, px } (RGBA, top-left origin, sRGB as stored).
'use strict';

const zlib = require('zlib');

const SIGNATURE = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

function paeth(a, b, c) {
  const p = a + b - c; const pa = Math.abs(p - a); const pb = Math.abs(p - b); const pc = Math.abs(p - c);
  if (pa <= pb && pa <= pc) return a;
  return pb <= pc ? b : c;
}

function decode(buf) {
  if (buf.length < 8 || !buf.subarray(0, 8).equals(SIGNATURE)) throw new Error('not a PNG file');
  let p = 8; let w = 0; let h = 0; let depth = 0; let type = 0; let interlace = 0;
  const idat = [];
  while (p < buf.length) {
    const len = buf.readUInt32BE(p); const kind = buf.toString('latin1', p + 4, p + 8);
    const data = buf.subarray(p + 8, p + 8 + len);
    if (kind === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); depth = data[8]; type = data[9]; interlace = data[12]; }
    else if (kind === 'IDAT') idat.push(data);
    else if (kind === 'IEND') break;
    p += 12 + len;
  }
  if (!w || !h) throw new Error('PNG without a header');
  if (depth !== 8) throw new Error(`PNG bit depth ${depth} (8-bit channels required)`);
  if (type !== 6 && type !== 2) throw new Error(`PNG colour type ${type} (RGBA or RGB required)`);
  if (interlace) throw new Error('interlaced PNG (save it non-interlaced)');
  const bpp = type === 6 ? 4 : 3;
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const stride = w * bpp;
  const out = Buffer.alloc(w * h * 4);
  let prev = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)];
    const line = Buffer.from(raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1)));
    for (let x = 0; x < stride; x++) {
      const a = x >= bpp ? line[x - bpp] : 0; const b = prev[x]; const c = x >= bpp ? prev[x - bpp] : 0;
      if (f === 1) line[x] = (line[x] + a) & 255;
      else if (f === 2) line[x] = (line[x] + b) & 255;
      else if (f === 3) line[x] = (line[x] + ((a + b) >> 1)) & 255;
      else if (f === 4) line[x] = (line[x] + paeth(a, b, c)) & 255;
      else if (f !== 0) throw new Error(`PNG filter ${f}`);
    }
    for (let x = 0; x < w; x++) {
      const o = (y * w + x) * 4; const i = x * bpp;
      out[o] = line[i]; out[o + 1] = line[i + 1]; out[o + 2] = line[i + 2]; out[o + 3] = bpp === 4 ? line[i + 3] : 255;
    }
    prev = line;
  }
  return { w, h, px: out, type };
}

// 1.3.2: the writer for the class-art masters and QA sheets - 8-bit RGBA, each row's filter
// chosen by the usual smallest-sum rule, zlib level 9: the same pixels always give the same bytes
const CRC = new Int32Array(256);
for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; CRC[n] = c; }
function crc32(bytes) {
  let c = -1;
  for (let i = 0; i < bytes.length; i++) c = CRC[(c ^ bytes[i]) & 255] ^ (c >>> 8);
  return (c ^ -1) >>> 0;
}

function chunk(kind, data) {
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  out.write(kind, 4, 'latin1');
  data.copy(out, 8);
  out.writeUInt32BE(crc32(out.subarray(4, 8 + data.length)), 8 + data.length);
  return out;
}

function encode(w, h, px) {
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  const stride = w * 4;
  const raw = Buffer.alloc((stride + 1) * h);
  const line = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    let best = 0; let bestSum = Infinity;
    for (let f = 0; f <= 4; f++) {
      let sum = 0;
      for (let x = 0; x < stride; x++) {
        const cur = px[y * stride + x]; const a = x >= 4 ? px[y * stride + x - 4] : 0;
        const b = y > 0 ? px[(y - 1) * stride + x] : 0; const c = x >= 4 && y > 0 ? px[(y - 1) * stride + x - 4] : 0;
        const pred = f === 0 ? 0 : f === 1 ? a : f === 2 ? b : f === 3 ? (a + b) >> 1 : paeth(a, b, c);
        const v = (cur - pred) & 255;
        sum += v < 128 ? v : 256 - v;
      }
      if (sum < bestSum) { bestSum = sum; best = f; }
    }
    for (let x = 0; x < stride; x++) {
      const cur = px[y * stride + x]; const a = x >= 4 ? px[y * stride + x - 4] : 0;
      const b = y > 0 ? px[(y - 1) * stride + x] : 0; const c = x >= 4 && y > 0 ? px[(y - 1) * stride + x - 4] : 0;
      const pred = best === 0 ? 0 : best === 1 ? a : best === 2 ? b : best === 3 ? (a + b) >> 1 : paeth(a, b, c);
      line[x] = (cur - pred) & 255;
    }
    raw[y * (stride + 1)] = best;
    line.copy(raw, y * (stride + 1) + 1);
  }
  return Buffer.concat([SIGNATURE, chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}

module.exports = { decode, encode };
