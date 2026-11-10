// The shipped display faces: Shojumaru (BANZAI Default) and the six approved alternates, each the unmodified
// file preserved in the bake-off sources, hash-checked, with the licence / readme text supplied in its download.
'use strict';

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const FONTS = [
  {
    id: 'SHOJUMARU', file: 'Shojumaru-Regular.ttf',
    family: 'Shojumaru', style: 'Regular',
    sha256: '8607110ef45da664861c72d95fb804c3609169ebfd2a380cb47b353a7b241c75',
    supplied: 'the preserved Shojumaru font archive',
    license: 'SIL Open Font License 1.1',
    licenseFile: 'OFL.txt', licenseContains: 'SIL OPEN FONT LICENSE Version 1.1',
  },
  { id: 'RYUJIN_ATTACK', file: 'RyujinAttack.otf', family: 'Ryujin Attack', style: 'Regular', sha256: 'a6d8aa6b08da6bef1b7a94f574dd92983477b1f282c94b350956578f627c06ac', supplied: 'the preserved ryujin-attack archive', license: 'author README (free to use)', licenseFile: 'RyujinAttack-README.txt', licenseContains: 'FOR FREE' },
  { id: 'GANG_OF_THREE', file: 'go3v2.ttf', family: 'Gang of Three', style: 'Regular', sha256: '8bb0d23e78dc94851b86732c28b9e0da1724893ba9301483bfdfcea50c19fac4', supplied: 'the preserved gang-of-three archive', license: 'author terms at the source page (no text in the download)', licenseFile: 'FONT-NOTICES.txt', licenseContains: 'Gang of Three' },
  { id: 'OSAKA_SANS', file: 'osaka-re.ttf', family: 'Osaka-Sans Serif', style: 'Regular', sha256: '79f10ac3196dcdb5925504315c648cab9df286994da4f8d49156e016d01f5d4d', supplied: 'the preserved osaka-sans archive', license: '1001Fonts Free For Commercial Use licence', licenseFile: 'OsakaSans-1001fonts-FFC-EULA.txt', licenseContains: '1001Fonts Free For Commercial Use License' },
  { id: 'SEKAIWO', file: 'Sekaiwo-Regular.otf', family: 'Sekaiwo', style: 'Regular', sha256: 'c3d71f31790becff50f42292d8edcb3123ac0a165c8ff196d6795e5eae17ccb6', supplied: 'the preserved sekaiwo archive', license: 'author READ ME (free for personal and commercial use)', licenseFile: 'Sekaiwo-READ-ME.txt', licenseContains: 'FREE for personal & commercial use' },
  { id: 'XANGDA_SHINY', file: 'Xangda Shiny.ttf', family: 'Xangda Shiny', style: 'Regular', sha256: '13d7561e1a52658f7bbec8e12282f629c9ada5c00bc0b88b7d51ef1c9dadb87f', supplied: 'the preserved xangda-shiny archive', license: 'author terms at the source page (no text in the download)', licenseFile: 'FONT-NOTICES.txt', licenseContains: 'Xangda Shiny' },
  { id: 'NINJA_NARUTO', file: 'njnaruto.ttf', family: 'Ninja Naruto', style: 'Regular', sha256: 'd7dac597f70d9e53bc6617e364c5f4e705767ea8be2c678995249cfe179d9335', supplied: 'the preserved ninja-naruto archive', license: 'supplied readme (distribute unmodified, free of charge)', licenseFile: 'NinjaNaruto-readme.txt', licenseContains: 'LICENSE AGREEMENT' },
];
// every notice file that ships beside the fonts (FONT-NOTICES.txt summarises all seven)
const NOTICES = [...new Set(['FONT-NOTICES.txt', ...FONTS.map((f) => f.licenseFile)])];
// evaluated in the private bake-off, never shipped
const RETIRED_FILES = ['WantCoffee.ttf', 'WantBanzai.otf', 'Changchangwoodcut-BL25.ttf', 'TheRootsOfChina-Regular.otf', 'Odishi-ALV7.ttf'];

const LEGACY_WANT_COFFEE = {
  file: 'WantCoffee.ttf',
  sha1: '7575115b9e41a8e8ba97b2e2d30ed98e4d7b220b',
  sibling: { file: 'Want Coffee.otf', sha1: 'd4b5bd12e06a277e5d1baf9ba6ab00ef8b2b5126' },
  copyright: 'Copyright (c) 2022 by Khurasan. All rights reserved.',
  trademark: 'Want Coffee is a trademark of Khurasan.',
  terms: '"This product 100% free for personal use & commercial use" (More Info.txt in the download); no licence text or URL in the font (name ID 13: "contact me at khurasantype@gmail.com"); OS/2 fsType 0x0004 (preview & print embedding)',
  publicPackaging: 'BLOCKED: no explicit permission to redistribute the font file inside a published addon',
};

const DIR = path.join(__dirname, '..', '..', 'addons', 'BushidoPrivateCompat', 'media', 'fonts');

function prepare(dir = DIR) {
  return FONTS.map((font) => {
    const src = path.join(dir, font.file);
    if (!fs.existsSync(src)) throw new Error(`font ${font.file} missing in ${dir}: restore it from ${font.supplied}`);
    const data = fs.readFileSync(src);
    const sha256 = crypto.createHash('sha256').update(data).digest('hex');
    if (sha256 !== font.sha256) throw new Error(`font ${font.file} SHA-256 ${sha256}, expected ${font.sha256}`);
    const license = path.join(dir, font.licenseFile);
    if (!fs.existsSync(license)) throw new Error(`${font.licenseFile} missing beside ${font.file}`);
    if (!fs.readFileSync(license, 'utf8').includes(font.licenseContains)) {
      throw new Error(`${font.licenseFile} does not contain the expected ${font.family} notice text`);
    }
    return { ...font, src, data };
  });
}

module.exports = { FONTS, NOTICES, RETIRED_FILES, LEGACY_WANT_COFFEE, DIR, prepare };
