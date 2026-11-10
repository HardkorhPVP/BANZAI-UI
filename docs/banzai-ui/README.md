# BANZAI UI

**Version 1.4.0** - World of Warcraft Retail (Interface 120105).

BANZAI UI is a complete ElvUI-based look for World of Warcraft: a bamboo construction around chat, meters, minimap and buffs, a green -> emerald -> violet -> purple identity gradient on every frame, and Darren's original class identity artwork for all thirteen classes. It installs as two addons:

| Folder | Shown in the AddOns list as | Does |
|---|---|---|
| `BushidoPrivateRestore` | **Banzai** | the ElvUI / Details profile layer, the BANZAI settings pages, Character Sync, Backup & Restore |
| `BushidoPrivateCompat` | **Banzai Art** | everything drawn: bamboo panels, class circles, BANZAI SPLIT frames, cast history, objective tracker, AFK screen, fonts |

## Requirements

- **ElvUI** - required.
- **JiberishMedia** - required. Separate download under its own licence; it is **not** included in this zip.
- Optional (used when installed, never required): Details!, ElvUI_mMediaTag + !mMT_MediaPack, ElvUI_EltreumUI (Eltruism), JiberishIcons, !KalielsTracker, MinimapButtonButton.

## Install

1. Close World of Warcraft.
2. Extract the zip into `World of Warcraft\_retail_\Interface\AddOns\` - you get `BushidoPrivateCompat` and `BushidoPrivateRestore`.
3. Install ElvUI and JiberishMedia separately if you do not have them.
4. Start the game and make sure **Banzai**, **Banzai Art**, **ElvUI** and **JiberishMedia** are ticked in the AddOns list.
5. Log in. Details: [INSTALLATION.md](INSTALLATION.md).

## First steps

Nothing is applied automatically. On a fresh character BANZAI UI loads, registers its settings and waits for you.

1. Open the settings: ElvUI options > **BANZAI**, or type `/banzai`.
2. On **HOME** press **Apply / repair Banzai** (the confirmation reads *APPLY BANZAI* and lists what will change). Your current ElvUI, Details and tracker setup is saved first.
3. Reload when asked. Everything after that applies immediately except a few settings whose description says *A reload applies it*.
4. `/banzai status` prints the version and the current state in chat.

To go back at any time: **BACKUP & RESTORE** > **Restore pre-Banzai settings**, or `/banzai restore`. See [RESTORE-PRE-BANZAI.md](RESTORE-PRE-BANZAI.md).

## Guides

| Start | Look | Frames and combat | Screen | More |
|---|---|---|---|---|
| [Installation](INSTALLATION.md) | [Appearance](APPEARANCE.md) | [BANZAI CLASSIC](CLASSIC.md) | [Chat](CHAT.md) | [Character Sync](CHARACTER-SYNC.md) |
| [Getting started](GETTING-STARTED.md) | [Materials](MATERIALS.md) | [BANZAI SPLIT](SPLIT.md) | [Details](DETAILS.md) | [Master Character](MASTER-CHARACTER.md) |
| [FAQ](FAQ.md) | [Fonts](FONTS.md) | [PvP](PVP.md) | [Buffs](BUFFS.md) | [Restore Pre-Banzai](RESTORE-PRE-BANZAI.md) |
| [Troubleshooting](TROUBLESHOOTING.md) | [AFK screen](AFK.md) | [Action bars](ACTION-BARS.md) | [Objectives](OBJECTIVES.md) | [Changelog](CHANGELOG.md) |
| [Support](SUPPORT.md) | | [Cast history](CAST-HISTORY.md) | [Minimap](MINIMAP.md) | [Credits](CREDITS.md) |

## Where it comes from

BANZAI UI grew out of a private restoration of the JiberishUI Shinto/Bushido look and is published with the permission Darren established with its original author. The original author does not endorse, support or maintain BANZAI UI; please do not contact JiberishUI about it.

## Licence and notices

BANZAI UI's own code, bamboo art, wordmark and class identity artwork are by Darren (HARDKORH). The display fonts shipped in `BushidoPrivateCompat\media\fonts\` belong to their authors and are listed with source, licence basis and checksum in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md) and in `media\fonts\FONT-NOTICES.txt` inside the addon. ElvUI, JiberishMedia and the optional addons are separate projects under their own licences and are not included.

World of Warcraft and Blizzard Entertainment are trademarks or registered trademarks of Blizzard Entertainment, Inc. BANZAI UI is not affiliated with or endorsed by Blizzard Entertainment.
