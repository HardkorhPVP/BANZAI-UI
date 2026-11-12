# Window skins

**WoW Forever only in 1.5.0.** BANZAI > APPEARANCE > **WINDOW SKINS**.

BANZAI skins existing windows; it does not replace them. A skinned window gets the BANZAI surface, a thin
border, the green -> violet accent line and the BANZAI heading face. Everything inside it - lists, buttons, what
they do - stays its owner's. Switch a skin off and the window is exactly its owner's again.

| Switch | Default | Covers |
|---|---|---|
| **Blizzard Windows** | on | Character, Spellbook / Talents, Professions, Quest Log, Quest, Merchant, Gossip, Trainer, Mail, Friends, Guild, Inspect, Trade |
| **Baganator** | on | Baganator's bag, bank and guild-bank windows |
| **Zygor** | on | the Zygor guide viewer |
| **Details** | on | the Banzai DAMAGE / HEALING frame (same switch as LAYOUT > DETAILS) |
| **Chat** | on | the Banzai CHAT frame (same switch as LAYOUT > CHAT) |
| **ElvUI Panels** | off | ElvUI's own translucent panels in the BANZAI tone |

Each switch works on its own; the BANZAI HUD does not depend on any of them.

## Material

The skins follow **PANEL STYLE > Background**:

- **BANZAI GLASS** - deep translucent glass (never thinner than 82 % on a window, so text stays readable).
- **SOLID** - the opaque BANZAI surface.
- **HARDKORH PARCHMENT** - the heading band is parchment with dark ink; the body stays the solid dark surface,
  because the window's own text is light.

## Blizzard windows

BANZAI lays its surface on the panel ElvUI's own skin gives the window. A window whose ElvUI skin is switched
off is left untouched. With Eltruism's expanded character art on, that art covers the Character window's body;
only the heading shows the BANZAI face there.

## Zygor

The viewer's body, steps area and toolbar take the BANZAI tone, with the accent line under its title bar. The
guide, its steps, their colours (red, green, grey, violet keep their meaning), navigation and waypoints are
Zygor's and are not touched. Zygor's own opacity setting still applies.

## Baganator

Baganator is the bag addon; BANZAI builds no bag of its own. Its windows are skinned while Baganator's own theme
is **ElvUI** (Baganator selects that by itself when ElvUI is loaded). With another Baganator theme the BANZAI
skin stands by. Items, sorting, search, categories and the bank are Baganator's.

## ElvUI Panels

Off by default: ElvUI's panels keep the profile's own colour. On, the Banzai ElvUI profile's panel colour takes
the BANZAI tone and follows the material and the glass opacity; off again, the profile's own colour is back.

## Minimap buttons

Not a window skin, but the same rule: BANZAI frames the minimap; a dedicated minimap-button addon owns the
buttons and where they sit.

`/banzai forever` lists the state of every skin (SKINNED, OFF, ABSENT when the addon is not installed, NOT READY
with the reason).
