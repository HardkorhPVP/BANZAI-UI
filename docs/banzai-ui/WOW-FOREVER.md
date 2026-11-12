# BANZAI UI on WoW Forever

BANZAI UI 1.5.0 is one addon for two clients: **World of Warcraft Retail 12.1.5** (Interface 120105) and
**WoW Forever 1.60.1** (Interface 16001). The same two folders work in both; BANZAI detects the client it runs in
and adapts where the two games really differ.

## Install on WoW Forever

1. Close the game.
2. Install the required addons below in their Forever versions.
3. Extract the BANZAI UI zip into `World of Warcraft\_forever_\Interface\AddOns\` - you get `BushidoPrivateCompat`
   (shown as **Banzai Art**) and `BushidoPrivateRestore` (shown as **Banzai**).
4. Log in, open ElvUI options > **BANZAI** (or `/banzai`) and press **Apply / repair Banzai** on HOME.

`/banzai forever` prints the client, every prerequisite as BANZAI actually uses it, and what was adapted.
Nothing is applied while a required component is missing.

## Prerequisites

**Required**

| Addon | Why |
|---|---|
| ElvUI (with ElvUI Libraries and ElvUI Options) | BANZAI is an ElvUI profile layer and plugin |
| JiberishMedia | fonts and bar textures of the look; separate download, not in the zip |

**Optional - used when installed, never required**

| Addon | What BANZAI does with it |
|---|---|
| Details! | the DAMAGE / HEALING bamboo frame and meter layout |
| ElvUI_mMediaTag (+ mMT Media Pack) | health text, portraits, role icons |
| ElvUI_EltreumUI (Eltruism) | name gradient, bar textures, nameplate extras |
| JiberishIcons | Fabled class / talent-tree art in the identity circles |
| BanzaiSland | hosts the top-centre BANZAI launcher; BANZAI's own wordmark steps aside |
| Zygor Guides Viewer | optional BANZAI window skin (below) |
| Baganator | optional BANZAI window skin (below) |
| a minimap-button addon (MinimapButtonButton) | owns the minimap buttons; BANZAI frames the minimap only |

Without an optional addon its part is simply left out.

## What is supported

BANZAI CLASSIC and BANZAI SPLIT unit frames, Player and Target, the cast presentation, action bars, Cast History,
the BUFFS panel, Chat, the Details frame, the minimap frame, Objectives, the bottom information strip, the
display-font selector (BANZAI Default = Shojumaru at 105 %), the GLASS / SOLID / HARDKORH PARCHMENT materials,
tooltips, the AFK screen, Restore Pre-Banzai and Character Sync.

Where WoW Forever has no such thing, BANZAI leaves it out instead of showing a made-up value: conquest, mastery,
versatility, loot specialization, another player's specialization, a separate PvP item level, pet battles.

### Talent trees instead of specializations

WoW Forever has talent trees. BANZAI shows the tree with the most committed points as your "spec" (its own name
and icon); on a tie, or with no points spent, it shows the class alone.

### Role layout

WoW Forever has no game-provided role. BANZAI switches to the HEALER layout automatically only where the
mapping is certain (in 1.5.0: a Druid in Balance is DPS, in Restoration HEALER); every other class and tree
keeps the DPS layout until you choose. `/banzai role auto|dps|healer` (or
the selector in the BANZAI settings) sets it per character.

### Chat

ElvUI's installer on WoW Forever leaves a second, undocked chat window ("Loot / Trade"). Inside the BANZAI CHAT
frame it would sit on top of General, so BANZAI docks it as a tab of the General window. Restore Pre-Banzai, or
switching the Banzai chat frame off, puts it back where it was. See [CHAT.md](CHAT.md).

### Window skins

Optional BANZAI surfaces for the game's own windows, Zygor and Baganator: [WINDOW-SKINS.md](WINDOW-SKINS.md).

### Restore Pre-Banzai and Character Sync

Both work as on Retail. A configuration captured on one client is never written into the other: Character Sync
records the client with every master configuration and refuses a mismatch before anything is backed up or
changed.

## Known limitations

- **Healer layout:** automatic healer-role adaptation is implemented for WoW Forever but has not yet completed
  dedicated live healer validation. The manual choice (`/banzai role healer`) is always available.
- **PvP:** battleground, arena and other PvP presentation is implemented where WoW Forever supports it and
  validated offline; dedicated live PvP / Arena / Battleground validation is deferred. Arena trinket state is
  shown as unknown, and no PvP item level is shown.
- **Own cooldown bars:** the offensive / defensive cooldown bars show nothing on WoW Forever yet - no spell list
  has been verified for this client, and Retail's is not reused.
- **Window skins** depend on the other addon's own state: Blizzard windows are skinned where ElvUI's skin for
  that window is on; Baganator while its theme is ElvUI; see the window-skin page.
- Character Sync between Retail and WoW Forever is blocked on purpose.
