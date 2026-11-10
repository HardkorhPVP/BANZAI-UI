// Minimal TGA (uncompressed / RLE true-colour) reader and uncompressed 32-bit writer,
// plus a PNG writer for local previews. RGBA buffers, top-left origin.
'use strict';

const fs = require('fs');
const zlib = require('zlib');

function read(file) {
  const buf = fs.readFileSync(file);
  const idLen = buf[0];
  const type = buf[2];
  const w = buf.readUInt16LE(12);
  const h = buf.readUInt16LE(14);
  const bpp = buf[16];
  const desc = buf[17];
  if (buf[1] !== 0) throw new Error('colour-mapped TGA not supported');
  const bytes = bpp / 8;
  let p = 18 + idLen;
  const px = Buffer.alloc(w * h * 4);
  let i = 0;
  const put = (o) => {
    const b = buf[o];
    const g = bytes >= 2 ? buf[o + 1] : b;
    const r = bytes >= 3 ? buf[o + 2] : b;
    const a = bytes === 4 ? buf[o + 3] : 255;
    px[i * 4] = r; px[i * 4 + 1] = g; px[i * 4 + 2] = b; px[i * 4 + 3] = a; i++;
  };
  if (type === 2 || type === 3) {
    for (let n = 0; n < w * h; n++) { put(p); p += bytes; }
  } else if (type === 10 || type === 11) {
    while (i < w * h) {
      const c = buf[p++];
      const count = (c & 0x7f) + 1;
      if (c & 0x80) { for (let k = 0; k < count; k++) put(p); p += bytes; } else { for (let k = 0; k < count; k++) { put(p); p += bytes; } }
    }
  } else throw new Error('TGA type ' + type);
  if (!(desc & 0x20)) { // bottom-left origin: flip rows
    const row = w * 4;
    const tmp = Buffer.alloc(row);
    for (let y = 0; y < h / 2; y++) {
      const a = y * row; const b = (h - 1 - y) * row;
      px.copy(tmp, 0, a, a + row); px.copy(px, a, b, b + row); tmp.copy(px, b);
    }
  }
  return { w, h, px };
}

// 32-bit BGRA, top-left origin, uncompressed (type 2); 1.3.2: encode() for hashing without a file
function write(file, w, h, rgba) {
  fs.writeFileSync(file, encode(w, h, rgba));
}

function encode(w, h, rgba) {
  const header = Buffer.alloc(18);
  header[2] = 2;
  header.writeUInt16LE(w, 12);
  header.writeUInt16LE(h, 14);
  header[16] = 32;
  header[17] = 0x28; // 8 alpha bits, top-left origin
  const body = Buffer.alloc(w * h * 4);
  for (let i = 0; i < w * h; i++) {
    body[i * 4] = rgba[i * 4 + 2];
    body[i * 4 + 1] = rgba[i * 4 + 1];
    body[i * 4 + 2] = rgba[i * 4];
    body[i * 4 + 3] = rgba[i * 4 + 3];
  }
  return Buffer.concat([header, body]);
}

const CRC = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; }
  return t;
})();
function crc32(buf) { let c = 0xffffffff; for (const b of buf) c = CRC[(c ^ b) & 0xff] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function writePNG(file, w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) { raw[y * (w * 4 + 1)] = 0; rgba.copy(raw, y * (w * 4 + 1) + 1, y * w * 4, (y + 1) * w * 4); }
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6;
  fs.writeFileSync(file, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

module.exports = { read, write, encode, writePNG };
