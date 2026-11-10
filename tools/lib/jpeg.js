// BANZAI 1.3.2: a small baseline JPEG decoder for Darren's class-art masters
// (tools/icons.js). Pure JavaScript, so the same source JPEG gives the same
// pixels on any machine (no system codec in the chain):
//   baseline sequential Huffman (SOF0 / SOF1), 8-bit, 1 or 3 components, any
//   sampling factors, restart intervals; chroma upsampled with the centred
//   linear ("fancy") filter; YCbCr -> RGB as JFIF defines it.
// Progressive / arithmetic / 12-bit files are refused with the reason.
// Returns { w, h, px } (RGBA, alpha 255, top-left origin).
'use strict';

const ZIGZAG = [
  0, 1, 8, 16, 9, 2, 3, 10, 17, 24, 32, 25, 18, 11, 4, 5, 12, 19, 26, 33, 40, 48, 41, 34, 27, 20, 13, 6, 7, 14, 21,
  28, 35, 42, 49, 56, 57, 50, 43, 36, 29, 22, 15, 23, 30, 37, 44, 51, 58, 59, 52, 45, 38, 31, 39, 46, 53, 60, 61, 54,
  47, 55, 62, 63,
];

// the exact 8-point inverse DCT basis: COS[x * 8 + u] = C(u) / 2 * cos((2x + 1) u pi / 16)
const COS = new Float64Array(64);
for (let x = 0; x < 8; x++) for (let u = 0; u < 8; u++) COS[x * 8 + u] = (u === 0 ? Math.SQRT1_2 : 1) / 2 * Math.cos(((2 * x + 1) * u * Math.PI) / 16);

function idct(coef, out, outOffset, stride) {
  const tmp = new Float64Array(64);
  for (let y = 0; y < 8; y++) { // rows of the coefficient block -> columns
    for (let x = 0; x < 8; x++) {
      let s = 0;
      for (let u = 0; u < 8; u++) s += COS[x * 8 + u] * coef[y * 8 + u];
      tmp[y * 8 + x] = s;
    }
  }
  for (let x = 0; x < 8; x++) {
    for (let y = 0; y < 8; y++) {
      let s = 0;
      for (let v = 0; v < 8; v++) s += COS[y * 8 + v] * tmp[v * 8 + x];
      const value = Math.round(s + 128);
      out[outOffset + y * stride + x] = value < 0 ? 0 : value > 255 ? 255 : value;
    }
  }
}

function huffmanTable(counts, symbols) {
  // canonical codes: maxcode / valptr / mincode per length
  const maxcode = new Int32Array(18).fill(-1);
  const valptr = new Int32Array(17);
  const mincode = new Int32Array(17);
  let code = 0; let k = 0;
  for (let len = 1; len <= 16; len++) {
    valptr[len] = k; mincode[len] = code;
    code += counts[len - 1]; k += counts[len - 1];
    if (counts[len - 1]) maxcode[len] = code - 1;
    code <<= 1;
  }
  maxcode[17] = 0x7fffffff;
  return { maxcode, valptr, mincode, symbols };
}

function decode(buf) {
  if (buf[0] !== 0xff || buf[1] !== 0xd8) throw new Error('not a JPEG file');
  const quant = [];
  const dcTables = [];
  const acTables = [];
  let frame = null;
  let restart = 0;
  let p = 2;
  while (p < buf.length) {
    if (buf[p] !== 0xff) throw new Error(`JPEG marker expected at ${p}`);
    const marker = buf[p + 1];
    if (marker === 0xff) { p++; continue; }
    if (marker === 0xd9) break;
    if (marker >= 0xd0 && marker <= 0xd7) { p += 2; continue; }
    const len = buf.readUInt16BE(p + 2);
    const seg = buf.subarray(p + 4, p + 2 + len);
    if (marker === 0xdb) { // quantisation tables
      let q = 0;
      while (q < seg.length) {
        const precision = seg[q] >> 4; const id = seg[q] & 15; q++;
        if (precision) throw new Error('16-bit quantisation tables are not supported');
        const table = new Int32Array(64);
        for (let i = 0; i < 64; i++) table[ZIGZAG[i]] = seg[q + i];
        quant[id] = table; q += 64;
      }
    } else if (marker === 0xc4) { // Huffman tables
      let q = 0;
      while (q < seg.length) {
        const cls = seg[q] >> 4; const id = seg[q] & 15; q++;
        const counts = Array.from(seg.subarray(q, q + 16)); q += 16;
        const total = counts.reduce((a, b) => a + b, 0);
        const table = huffmanTable(counts, Array.from(seg.subarray(q, q + total))); q += total;
        (cls ? acTables : dcTables)[id] = table;
      }
    } else if (marker === 0xdd) {
      restart = seg.readUInt16BE(0);
    } else if (marker === 0xc0 || marker === 0xc1) {
      if (seg[0] !== 8) throw new Error(`${seg[0]}-bit JPEG (8-bit required)`);
      const h = seg.readUInt16BE(1); const w = seg.readUInt16BE(3); const n = seg[5];
      if (n !== 1 && n !== 3) throw new Error(`${n} JPEG components (1 or 3 supported)`);
      const comps = [];
      for (let i = 0; i < n; i++) comps.push({ id: seg[6 + i * 3], hs: seg[7 + i * 3] >> 4, vs: seg[7 + i * 3] & 15, tq: seg[8 + i * 3] });
      const hmax = Math.max(...comps.map((c) => c.hs)); const vmax = Math.max(...comps.map((c) => c.vs));
      const mcuW = 8 * hmax; const mcuH = 8 * vmax;
      const mcusX = Math.ceil(w / mcuW); const mcusY = Math.ceil(h / mcuH);
      for (const c of comps) {
        c.bw = mcusX * c.hs; c.bh = mcusY * c.vs; // blocks, padded to whole MCUs
        c.stride = c.bw * 8;
        c.data = new Uint8Array(c.stride * c.bh * 8);
      }
      frame = { w, h, comps, hmax, vmax, mcusX, mcusY };
    } else if (marker >= 0xc2 && marker <= 0xcf && marker !== 0xc4 && marker !== 0xc8 && marker !== 0xcc) {
      throw new Error(`JPEG frame type 0x${marker.toString(16)} (only baseline sequential is supported)`);
    } else if (marker === 0xda) {
      if (!frame) throw new Error('JPEG scan before its frame header');
      const ns = seg[0];
      const scomps = [];
      for (let i = 0; i < ns; i++) {
        const id = seg[1 + i * 2]; const t = seg[2 + i * 2];
        const c = frame.comps.find((x) => x.id === id);
        c.dc = dcTables[t >> 4]; c.ac = acTables[t & 15]; c.q = quant[c.tq];
        scomps.push(c);
      }
      p = decodeScan(buf, p + 2 + len, frame, scomps, restart);
      continue;
    }
    p += 2 + len;
  }
  if (!frame) throw new Error('JPEG without a frame');
  return toRGBA(frame);
}

function decodeScan(buf, start, frame, comps, restart) {
  let pos = start; let bitBuf = 0; let bitCount = 0;
  const readBit = () => {
    if (bitCount === 0) {
      let byte = buf[pos++];
      if (byte === 0xff) {
        const next = buf[pos];
        if (next === 0) pos++;
        else if (next >= 0xd0 && next <= 0xd7) { byte = 0; pos--; } // a marker: feed zeros until the restart
        else { byte = 0; pos--; }
      }
      bitBuf = byte; bitCount = 8;
    }
    bitCount--;
    return (bitBuf >> bitCount) & 1;
  };
  const receive = (n) => { let v = 0; for (let i = 0; i < n; i++) v = (v << 1) | readBit(); return v; };
  const extend = (v, n) => (n === 0 ? 0 : v < (1 << (n - 1)) ? v - (1 << n) + 1 : v);
  const decodeSymbol = (t) => {
    let code = 0;
    for (let len = 1; len <= 16; len++) {
      code = (code << 1) | readBit();
      if (code <= t.maxcode[len]) return t.symbols[t.valptr[len] + code - t.mincode[len]];
    }
    throw new Error('bad Huffman code in the JPEG scan');
  };
  const coef = new Float64Array(64);
  const block = (c, bx, by) => {
    coef.fill(0);
    const t = decodeSymbol(c.dc);
    c.pred += extend(receive(t), t);
    coef[0] = c.pred * c.q[0];
    for (let k = 1; k < 64;) {
      const rs = decodeSymbol(c.ac);
      const r = rs >> 4; const s = rs & 15;
      if (s === 0) { if (r === 15) { k += 16; continue; } break; }
      k += r;
      if (k > 63) break;
      coef[ZIGZAG[k]] = extend(receive(s), s) * c.q[ZIGZAG[k]];
      k++;
    }
    idct(coef, c.data, by * 8 * c.stride + bx * 8, c.stride);
  };
  for (const c of comps) c.pred = 0;
  const single = comps.length === 1;
  const total = single ? Math.ceil(Math.ceil(frame.w * comps[0].hs / frame.hmax) / 8) * Math.ceil(Math.ceil(frame.h * comps[0].vs / frame.vmax) / 8) : frame.mcusX * frame.mcusY;
  const perRow = single ? Math.ceil(Math.ceil(frame.w * comps[0].hs / frame.hmax) / 8) : frame.mcusX;
  for (let m = 0; m < total; m++) {
    if (restart && m > 0 && m % restart === 0) {
      // byte-align, skip the RSTn marker, reset the predictions
      bitCount = 0;
      while (pos < buf.length && !(buf[pos] === 0xff && buf[pos + 1] >= 0xd0 && buf[pos + 1] <= 0xd7)) pos++;
      pos += 2;
      for (const c of comps) c.pred = 0;
    }
    const mx = m % perRow; const my = Math.floor(m / perRow);
    if (single) block(comps[0], mx, my);
    else for (const c of comps) for (let v = 0; v < c.vs; v++) for (let h = 0; h < c.hs; h++) block(c, mx * c.hs + h, my * c.vs + v);
  }
  // to the next marker
  while (pos < buf.length && !(buf[pos] === 0xff && buf[pos + 1] !== 0 && !(buf[pos + 1] >= 0xd0 && buf[pos + 1] <= 0xd7))) pos++;
  return pos;
}

// one component's sample at full-resolution pixel (x, y): centred linear upsampling
function sampler(c, frame) {
  const fx = frame.hmax / c.hs; const fy = frame.vmax / c.vs;
  const cw = Math.ceil(frame.w / fx); const ch = Math.ceil(frame.h / fy);
  if (fx === 1 && fy === 1) return (x, y) => c.data[y * c.stride + x];
  return (x, y) => {
    const sx = (x + 0.5) / fx - 0.5; const sy = (y + 0.5) / fy - 0.5;
    let x0 = Math.floor(sx); let y0 = Math.floor(sy);
    const tx = sx - x0; const ty = sy - y0;
    let x1 = x0 + 1; let y1 = y0 + 1;
    if (x0 < 0) x0 = 0; if (y0 < 0) y0 = 0; if (x1 > cw - 1) x1 = cw - 1; if (y1 > ch - 1) y1 = ch - 1;
    const a = c.data[y0 * c.stride + x0]; const b = c.data[y0 * c.stride + x1];
    const d = c.data[y1 * c.stride + x0]; const e = c.data[y1 * c.stride + x1];
    return (a * (1 - tx) + b * tx) * (1 - ty) + (d * (1 - tx) + e * tx) * ty;
  };
}

function toRGBA(frame) {
  const { w, h, comps } = frame;
  const px = Buffer.alloc(w * h * 4);
  const s = comps.map((c) => sampler(c, frame));
  const clamp = (v) => { const r = Math.round(v); return r < 0 ? 0 : r > 255 ? 255 : r; };
  for (let y = 0; y < h; y++) for (let x = 0; x < w; x++) {
    const o = (y * w + x) * 4;
    if (comps.length === 1) { const v = s[0](x, y); px[o] = px[o + 1] = px[o + 2] = clamp(v); }
    else {
      const Y = s[0](x, y); const cb = s[1](x, y) - 128; const cr = s[2](x, y) - 128;
      px[o] = clamp(Y + 1.402 * cr);
      px[o + 1] = clamp(Y - 0.344136 * cb - 0.714136 * cr);
      px[o + 2] = clamp(Y + 1.772 * cb);
    }
    px[o + 3] = 255;
  }
  return { w, h, px };
}

module.exports = { decode };
