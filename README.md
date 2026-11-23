# BANZAI UI

**A complete BANZAI visual overhaul for ElvUI on World of Warcraft Retail and WoW Forever.** Bamboo construction, a green → emerald → violet → purple identity gradient, and Darren's original BANZAI class artwork for all thirteen classes - applied over ElvUI, switchable per character, syncable across your characters and fully reversible.

Two layouts (**BANZAI CLASSIC** with class circles, or **BANZAI SPLIT** with health left, resource right and a central identity + cast hub). One panel material for Chat, Details, Minimap and BUFFS - **GLASS**, **SOLID** or **HARDKORH PARCHMENT** behind a **CLASS**, **BANZAI** or **HARDKORH** border. Banzai Objectives tracker, Cast History, AFK treatment and a role-aware PvP presentation. **Character Sync** carries the approved look from one Master Character to the others when you ask it to. **Restore Pre-Banzai** puts ElvUI, Details and your tracker back the way they were. Display-font choices under APPEARANCE → FONTS; BANZAI Default = Shojumaru at 105 %.

Settings: **ElvUI options → BANZAI** or `/banzai`. Status: `/banzai status`. Restore: `/banzai restore`.

**Requires** **ElvUI** and **JiberishMedia** (a separate download under its own licence; not included). Optional: Details!, ElvUI_mMediaTag + !mMT_MediaPack, ElvUI_EltreumUI (Eltruism), JiberishIcons, BanzaiSland, !KalielsTracker, MinimapButtonButton; on WoW Forever also Zygor Guides Viewer and Baganator for their optional window skins.

**One package for two clients:** World of Warcraft Retail 12.1.5 (Interface 120105) and WoW Forever 1.60.1 (Interface 16001). On WoW Forever BANZAI adapts to talent trees, leaves out what that game does not have, and adds optional **Window Skins** for the game's own windows, Zygor and Baganator - see [WoW Forever](docs/banzai-ui/WOW-FOREVER.md) and [Window skins](docs/banzai-ui/WINDOW-SKINS.md). Known there: dedicated live healer-layout and PvP / Arena / Battleground validation is deferred, and the own-cooldown bars show nothing yet.

> BANZAI UI grew out of a private restoration of the JiberishUI Shinto/Bushido look and is published with the permission Darren established with its original author. The original author does not endorse, support or maintain BANZAI UI; please do not contact JiberishUI about it.

Credits: [BANZAI-UI-CREDITS.md](credits/BANZAI-UI-CREDITS.md) · Notices: [THIRD-PARTY-NOTICES.md](docs/banzai-ui/THIRD-PARTY-NOTICES.md). Issues: https://github.com/HardkorhPVP/BANZAI-UI/issues · Discord: https://discord.gg/sv2WNwk2WZ

### Install

1. Install ElvUI and JiberishMedia.
2. Unzip `BANZAI-UI-1.5.2.zip` and copy both folders - `BushidoPrivateCompat` (shown in game as **Banzai Art**) and `BushidoPrivateRestore` (shown as **Banzai**) - into `World of Warcraft\_retail_\Interface\AddOns\` (Retail) or `World of Warcraft\_forever_\Interface\AddOns\` (WoW Forever).
3. Start the game, make sure **Banzai** and **Banzai Art** are enabled, log in and type `/banzai`.

The folder names are kept for saved-variable continuity; the in-game names are Banzai and Banzai Art.


## Documentation

- [User guide](docs/banzai-ui/README.md)
- [Installation](docs/banzai-ui/INSTALLATION.md)
- [WoW Forever](docs/banzai-ui/WOW-FOREVER.md) and [Window skins](docs/banzai-ui/WINDOW-SKINS.md)
- [Getting started](docs/banzai-ui/GETTING-STARTED.md)
- [Credits](credits/BANZAI-UI-CREDITS.md) and [third-party notices](docs/banzai-ui/THIRD-PARTY-NOTICES.md)
- [Changelog](docs/banzai-ui/CHANGELOG.md)
- [Support](docs/banzai-ui/SUPPORT.md) and [FAQ](docs/banzai-ui/FAQ.md)

## Building from source

The release package is reproducible from this repository alone:

```
npm ci
node tools/fetch-references.js   # the two pinned public upstream references, into upstream/ (never committed)
npm run build
npm test
node tools/release.js            # release/BANZAI-UI-<version>.zip, its SHA-256 and release.json
```

The same source always gives the same zip (sorted entries, fixed timestamps); the SHA-256 reviewed for each
release is committed beside its notes in `release-notes/`.

## Downloads and updates

- **GitHub** - https://github.com/HardkorhPVP/BANZAI-UI/releases (the release asset `BANZAI-UI-<version>.zip`)
- **CurseForge** - project 1793334
- **WowUp** - follows the GitHub Release (Install from URL with this repository's address) or CurseForge
- **Discord** - https://discord.gg/sv2WNwk2WZ for announcements and help

GitHub and CurseForge carry the same file, byte for byte. BANZAI UI is no longer updated on Wago: the page
there stops at 1.4.0.

## Releasing (maintainers)

Releases are made by `.github/workflows/release.yml` when a `banzai-X.Y.Z` tag is pushed:

1. Implement, and validate in game on both clients.
2. Set the version (both TOCs, `package.json`), write `docs/banzai-ui/CHANGELOG.md` and
   `release-notes/BANZAI-UI-X.Y.Z.md`, build the package and commit its reviewed checksum as
   `release-notes/BANZAI-UI-X.Y.Z.sha256`.
3. Commit, and push the public source to `main`.
4. Create the tag `banzai-X.Y.Z` on that commit and push it.
5. GitHub Actions builds, tests, packages and refuses a package whose SHA-256 is not the committed one.
6. The GitHub Release is published with the zip, its `.sha256` and `release.json`.
7. The same zip is uploaded to CurseForge; the game-version IDs are looked up in CurseForge's current list
   for the clients named by the TOCs' `## Interface:` line.
8. Download the file from GitHub and from CurseForge and compare both with the committed SHA-256.
9. WowUp picks the release up from GitHub / CurseForge; nothing is packaged separately for it.

The GitHub Release never depends on CurseForge. If the CurseForge step fails, the job fails and says why, the
GitHub Release stays, and re-running the failed job retries CurseForge only. The one secret is `CF_API_KEY`
(a CurseForge API token, repository secret). Run the workflow by hand (Actions > Release > Run workflow) for a
dry run that uploads nothing.
