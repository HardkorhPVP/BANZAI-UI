# Getting started

## Open the settings

Any of these:

- ElvUI options > **BANZAI**
- `/banzai`
- left-click the small **BANZAI** wordmark at the top centre of the screen (out of combat)

The pages are listed on the left: **HOME, APPEARANCE, UNIT FRAMES, PVP, ACTION BARS, LAYOUT, CHARACTER SYNC, COMPONENTS, TOOLTIPS, AFK SCREEN, BACKUP & RESTORE, ABOUT**.

## Apply BANZAI

Nothing applies by itself. On **HOME** > **APPLY / REPAIR** press **Apply / repair Banzai**. The confirmation (*APPLY BANZAI to this character?*) lists exactly what will be written. Your current ElvUI layout, Details layout and tracker state are recorded first so you can go back. Press **Reload UI** when prompted.

The same button on an already-applied character acts as a repair: it writes the full BANZAI setup again without losing your saved pre-BANZAI snapshot.

## The first things to look at

- **UNIT FRAMES > FRAME STYLE** - **BANZAI CLASSIC** (default) or **BANZAI SPLIT**. Per character. [CLASSIC.md](CLASSIC.md), [SPLIT.md](SPLIT.md)
- **APPEARANCE > PANEL STYLE** - border style and background for chat, Details, minimap and the BUFFS panel. [MATERIALS.md](MATERIALS.md)
- **APPEARANCE > FONTS** - the display font (BANZAI Default is Shojumaru at 105 %), **Preview display font**, **Banzai display size**. [FONTS.md](FONTS.md)
- **ACTION BARS > BUTTON STYLE** - Banzai Square (default), Banzai Circles or ElvUI Square. [ACTION-BARS.md](ACTION-BARS.md)
- **LAYOUT** - chat, Details, minimap, objective tracker, cast history, bottom panel, BUFFS panel.

Most changes show at once. A setting whose description ends in *A reload applies it* needs **Reload UI** (HOME) or `/reload`.

## Your other characters

Once one character looks right, make it the **Banzai Master** (CHARACTER SYNC > BANZAI MASTER > **SET AS BANZAI MASTER**). Its BANZAI setup is captured when it logs out. On another character open **CHARACTER SYNC** and press **APPLY BANZAI**; later, **UPDATE CHARACTER** brings it in line with the master again. Nothing moves until you press the button on that character. [CHARACTER-SYNC.md](CHARACTER-SYNC.md), [MASTER-CHARACTER.md](MASTER-CHARACTER.md)

## Chat commands

| Command | Does |
|---|---|
| `/banzai` | opens the settings |
| `/banzai status` | prints version, profile, theme, panel style, frame style, sync state and more |
| `/banzai apply` | the same as HOME > Apply / repair Banzai |
| `/banzai restore` | the same as BACKUP & RESTORE > Restore pre-Banzai settings |
| `/banzai theme vibrant` / `/banzai theme class` | switches the frame theme |

## Going back

**BACKUP & RESTORE** > **Restore pre-Banzai settings** returns this character's ElvUI, Details and Kaliel's Tracker setup from before BANZAI. Spells, action bars, macros, keybinds, talents and other addons are never touched. [RESTORE-PRE-BANZAI.md](RESTORE-PRE-BANZAI.md)
