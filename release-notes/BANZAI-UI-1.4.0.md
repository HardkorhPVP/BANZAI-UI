# BANZAI UI 1.4.0

First public release. World of Warcraft Retail only (Interface 120105).

## What is in it
- The complete BANZAI look over ElvUI: bamboo construction, the green → emerald → violet → purple identity gradient, Darren's original class identity artwork for all thirteen classes.
- Unit frames in **BANZAI CLASSIC** (class circles, default) or **BANZAI SPLIT** (health left, resource right, central identity + cast hub, bamboo cast bar), chosen per character under UNIT FRAMES → FRAME STYLE.
- One panel material for chat, Details, minimap and BUFFS: SOLID, GLASS or PARCHMENT behind a CLASS, BANZAI or HARDKORH border, with border thickness, glass opacity and parchment brightness.
- Action bars in BANZAI SQUARE, BANZAI CIRCLES or ElvUI square; cast history; offensive / defensive cooldown bars; tooltip theme; bottom information bar; AFK screen; combat logo; targeted nameplate; Banzai objective tracker; bamboo minimap.
- PvP: interruptible / uninterruptible cast colours, dispel glow, small defensives, trinket circles, role icons, CC / dispel emphasis - secure frames untouched.
- **Character Sync**: a Master Character captured at logout; APPLY BANZAI / UPDATE CHARACTER on the others. Nothing applies by itself.
- **Restore Pre-Banzai**: BACKUP & RESTORE or `/banzai restore` returns ElvUI, Details and the tracker to their pre-BANZAI state.

## Display fonts
- **BANZAI Default is Shojumaru at 105 %** (Shojumaru Regular, SIL Open Font License 1.1).
- The selector offers Automatic, BANZAI Default, Shojumaru, Ryujin Attack, Gang of Three, Osaka Sans, Sekaiwo, Xangda Shiny, Ninja Naruto and the Information Font (the ElvUI profile's small font).
- Automatic uses BANZAI Default when every character of a string is supported; otherwise the whole string is drawn in the Information Font. An explicitly chosen alternate is drawn at its own size and falls back the same way. Xangda Shiny has letters only.
- Notices and SHA-256 per font file: `media/fonts/FONT-NOTICES.txt`.

## Changed since 1.3.8
- The display-font set is final. Saved selections of fonts that no longer ship become BANZAI Default.
- Public documentation, credits and licence notices added.

## Requirements
- ElvUI and JiberishMedia (JiberishMedia is a separate download under its own licence; not packaged).
- Optional: Details!, ElvUI_mMediaTag + !mMT_MediaPack, ElvUI_EltreumUI (Eltruism), JiberishIcons, !KalielsTracker, MinimapButtonButton.
- Addon folders `BushidoPrivateCompat` (Banzai Art) and `BushidoPrivateRestore` (Banzai); saved variables `BanzaiCompatDB`, `BushidoPrivateRestoreDB`. Settings: ElvUI options → BANZAI or `/banzai`; `/banzai status`.

## Known limitations
- Retail only. WoW Forever compatibility is the next milestone and is not supported by this release.
- A few settings need a reload; the reload prompt says which.

Licence: see the LICENCE and notices shipped in the package. BANZAI UI grew out of a private restoration of the JiberishUI Shinto/Bushido look and is published with the permission Darren established with its original author. The original author does not endorse, support or maintain BANZAI UI; please do not contact JiberishUI about it.
