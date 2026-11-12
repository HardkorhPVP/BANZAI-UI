# BANZAI UI 1.5.0

One BANZAI UI for two clients: **World of Warcraft Retail 12.1.5** (Interface 120105) and **WoW Forever 1.60.1**
(Interface 16001). The same package installs in either.

## WoW Forever

- Added WoW Forever 1.60.1 support.
- Added Forever-aware ElvUI profile adaptation (the macro conditions and names that client does not have).
- Added Forever talent-tree handling: the leading talent tree is shown as the spec; nothing is guessed on a tie.
- Added flavor-aware Character Sync: a configuration from one client is never written into the other.
- Added Forever-aware cooldown and PvP capability handling: what the client has no data for is left out, not faked.
- Added Restore Pre-Banzai support for Forever, and a prerequisite check (`/banzai forever`).

## Window Skins (WoW Forever)

- Fixed the Forever Chat tab / layout interaction (the undocked "Loot / Trade" window over General).
- Added optional BANZAI skins for supported Blizzard windows.
- Added optional Zygor skin integration.
- Added optional Baganator skin integration.
- Added independent Window Skin toggles (BANZAI > APPEARANCE > WINDOW SKINS).

## Compatibility

- Preserved Retail support: the Retail look, layouts and features are those of 1.4.0.
- Preserved BanzaiSland integration on both clients.
- BANZAI Default remains Shojumaru at 105 %.
- A dedicated minimap-button addon owns the minimap buttons; BANZAI frames the minimap.

## Known / Deferred Validation

- Dedicated healer-role live validation deferred: automatic healer-role adaptation is implemented for Forever
  but has not yet completed dedicated live healer validation. `/banzai role healer` is always available.
- Dedicated PvP / Arena / Battleground live validation deferred on Forever.
- Own cooldown bars show nothing on Forever yet: no spell list is verified for that client.
- Window skins depend on the other addon: Blizzard windows where ElvUI's skin is on, Baganator while its theme
  is ElvUI.

## Requirements

- **Required:** ElvUI and JiberishMedia (a separate download under its own licence; not packaged).
- **Optional:** Details!, ElvUI_mMediaTag + !mMT_MediaPack, ElvUI_EltreumUI (Eltruism), JiberishIcons,
  BanzaiSland, MinimapButtonButton; Retail also !KalielsTracker; Forever also Zygor Guides Viewer and Baganator
  for their optional skins.
- Addon folders `BushidoPrivateCompat` (Banzai Art) and `BushidoPrivateRestore` (Banzai). Settings: ElvUI options
  > BANZAI or `/banzai`; `/banzai status`.

## Upgrading from 1.4.0

Replace both folders. Saved settings are kept. Nothing changes on a Retail character beyond the version.

Licence: see the notices shipped in the package. BANZAI UI grew out of a private restoration of the JiberishUI
Shinto/Bushido look and is published with the permission Darren established with its original author. The
original author does not endorse, support or maintain BANZAI UI; please do not contact JiberishUI about it.
