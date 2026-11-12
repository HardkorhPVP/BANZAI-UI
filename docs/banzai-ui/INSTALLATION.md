# Installing BANZAI UI

BANZAI UI 1.5.0 is for **World of Warcraft Retail 12.1.5** (Interface 120105) and **WoW Forever 1.60.1** (Interface 16001). The same zip installs in either client; WoW Forever specifics are in [WOW-FOREVER.md](WOW-FOREVER.md).

## What you need first

| Addon | Required? | Notes |
|---|---|---|
| **ElvUI** | required | BANZAI UI is an ElvUI profile layer plus its own art; without ElvUI it does not load |
| **JiberishMedia** | required | separate download, its own licence - **not** in the BANZAI UI zip |
| Details! | optional | the bamboo DAMAGE / HEALING meter frame |
| ElvUI_mMediaTag + !mMT_MediaPack | optional | class / spec portraits and role icons in the frames |
| ElvUI_EltreumUI (Eltruism) | optional | nameplate and frame details the Bushido layout uses |
| JiberishIcons | optional | the Fabled class / spec art in the identity circles |
| !KalielsTracker | optional | hidden while the Banzai objective tracker is on, restored when it is off |
| MinimapButtonButton | optional | the minimap-button collector (Retail: placed in the top-right corner; WoW Forever: left entirely to that addon) |
| BanzaiSland | optional | hosts the top-centre BANZAI launcher |
| Zygor Guides Viewer, Baganator | optional, WoW Forever | optional BANZAI [window skins](WINDOW-SKINS.md) |

Install ElvUI and JiberishMedia the way their authors describe. BANZAI UI never modifies their files.

## Install

1. Close World of Warcraft completely.
2. Extract the BANZAI UI zip into `World of Warcraft\_retail_\Interface\AddOns\` (Retail) or `World of Warcraft\_forever_\Interface\AddOns\` (WoW Forever).
   You should now have two folders there: `BushidoPrivateCompat` and `BushidoPrivateRestore`, each with its `.toc` file directly inside.
3. Start the game. On the character screen open **AddOns** and make sure these are ticked: **Banzai**, **Banzai Art**, **ElvUI**, **JiberishMedia** (and any optional addons you use).
4. Log in. Nothing is applied yet - open ElvUI options > **BANZAI** (or `/banzai`) and press **Apply / repair Banzai** on **HOME** when you are ready. See [GETTING-STARTED.md](GETTING-STARTED.md).

The folder names are historical and must stay as they are: your saved settings (`BushidoPrivateRestoreDB`, `BanzaiCompatDB`) and the ElvUI profile BANZAI writes are tied to them.

## Upgrading

1. Close the game.
2. Replace the two folders `BushidoPrivateCompat` and `BushidoPrivateRestore` with the new ones. Do **not** delete anything in `WTF\` - your settings live there and are kept.
3. Log in. Your choices persist (frame style, materials, fonts, positions, Character Sync master). Where a new version adds a setting it starts at its default.
4. If you chose a display font that is no longer shipped, that selection becomes **BANZAI Default** on first login - nothing else changes.

## Uninstalling

1. In game, put the character back first: **BANZAI > BACKUP & RESTORE > Restore pre-Banzai settings** (or `/banzai restore`) on each character that applied BANZAI, then reload. This returns the ElvUI, Details and Kaliel's Tracker state recorded before BANZAI. See [RESTORE-PRE-BANZAI.md](RESTORE-PRE-BANZAI.md).
2. Close the game and delete `BushidoPrivateCompat` and `BushidoPrivateRestore` from `Interface\AddOns\`.
3. Optional, for a clean slate: delete `BushidoPrivateRestoreDB.lua` and `BanzaiCompatDB.lua` from `WTF\Account\<account>\SavedVariables\`.

ElvUI, JiberishMedia and the optional addons are untouched by any of this.
