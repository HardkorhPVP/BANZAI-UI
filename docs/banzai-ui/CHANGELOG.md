# Changelog

## 1.5.0 - WoW Forever

One BANZAI UI for Retail 12.1.5 and WoW Forever 1.60.1. On Retail nothing changes beyond the version.

**WoW Forever**
- Added WoW Forever 1.60.1 support ([WOW-FOREVER.md](WOW-FOREVER.md)).
- Added Forever-aware ElvUI profile adaptation.
- Added Forever talent-tree handling (the leading tree is shown as the spec).
- Added flavor-aware Character Sync: a configuration from one client is never written into the other.
- Added Forever-aware cooldown and PvP capability handling - what the client has no data for is left out.
- Added Restore Pre-Banzai support for Forever and the prerequisite check `/banzai forever`.

**Window Skins (WoW Forever, [WINDOW-SKINS.md](WINDOW-SKINS.md))**
- Fixed the Forever Chat tab / layout interaction.
- Added optional BANZAI skins for supported Blizzard windows.
- Added optional Zygor skin integration.
- Added optional Baganator skin integration.
- Added independent Window Skin toggles.

**Compatibility**
- Preserved Retail support.
- Preserved BanzaiSland integration.
- BANZAI Default remains Shojumaru at 105 %.

**Known / deferred validation**
- Dedicated healer-role live validation deferred (automatic healer-role adaptation is implemented for Forever but has not yet completed dedicated live healer validation).
- Dedicated PvP / Arena / Battleground live validation deferred.
- Own cooldown bars show nothing on Forever yet (no verified spell list).

## 1.4.0 - first public release

Based on the 1.3.8 line. Release engineering and the final display-font set; no new features.

- **Display fonts**: the full selector - Automatic, BANZAI Default, Shojumaru, Ryujin Attack, Gang of Three, Osaka Sans, Sekaiwo, Xangda Shiny, Ninja Naruto, Information Font. **BANZAI Default is Shojumaru at 105 %**; Automatic uses it only for fully supported strings and the Information Font otherwise; an alternate is drawn at its own size with whole-string fallback.
- **Notices and provenance**: every shipped font file is listed with author, source, licence basis and SHA-256 in `media\fonts\FONT-NOTICES.txt`; the supplied licence / readme texts ship beside the fonts. Faces that were evaluated but not cleared for distribution are not shipped; an old selection of one becomes BANZAI Default.
- **No auto-apply on first login**: BANZAI waits until you press **Apply / repair Banzai** on HOME (or APPLY BANZAI under CHARACTER SYNC).
- Player documentation (this folder).

## Earlier milestones (1.3.x)

- **1.3.8** - launcher-host compatibility: BANZAI UI's small top-centre wordmark steps aside while BanzaiSland hosts the integrated BANZAI SLAND launcher; the saved logo setting is never changed.
- **1.3.7** - HARDKORH PARCHMENT material corrected: tiled at a fixed grain, never stretched.
- **1.3.6** - a real centre gutter between the Details DAMAGE and HEALING meters.
- **1.3.5** - runtime cleanup: stray lines traced and removed; BANZAI's own PvP visuals cleaned up; a Details divider.
- **1.3.4** - PvP frames made fully hands-off; a lower bamboo cast bar in BANZAI SPLIT.
- **1.3.3** - PvP frame safety, a synthetic TARGET NPC preview, the BANZAI SPLIT identity circle and the bamboo cast bar.
- **1.3.2** - Darren's original BANZAI class identities (13 classes) with the **Identity art** choice.
- **1.3.1** - BANZAI SPLIT runtime corrections, the **Bar thickness** setting, tracker ownership.
- **1.3.0** - the optional **BANZAI SPLIT** unit frames, split party frames and **BANZAI COMPACT** Details rows; BANZAI CLASSIC unchanged and still the default.

## Before 1.3

- **1.2.x** - gameplay polish: Banzai Square / Circles action buttons, chat flush with the left edge, the BUFFS panel.
- **1.1.x** - the panel material (border style and background) for chat, Details and minimap; parchment readability.
- **1.0.x** - unit frames, the BANZAI settings pages, AFK screen, tooltips, Character Sync, objective tracker ownership.
