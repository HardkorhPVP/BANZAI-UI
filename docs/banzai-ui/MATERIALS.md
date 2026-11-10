# Materials (panel style)

The chat panel, the Details frame, the minimap frame and the BUFFS panel sit in **one bamboo construction**: a stalk along each side, tied at the corners. You choose the border colouring and the interior independently, and every change shows at once on all four.

Page: **BANZAI > APPEARANCE > PANEL STYLE**.

## Border style

| Choice | Look |
|---|---|
| **CLASS** | your class colour on the bamboo (lighter -> class colour -> deeper), hemp rope ties |
| **BANZAI** (default) | natural vivid bamboo greens, purple rope |
| **HARDKORH** | green -> emerald -> violet -> purple over the bamboo, purple rope |

## Background

| Choice | Look |
|---|---|
| **SOLID** | very dark green-black, nearly opaque |
| **GLASS** (default) | BANZAI GLASS: the dark translucent green glass |
| **PARCHMENT** | HARDKORH PARCHMENT: warm cream parchment, tiled at a fixed grain so it is never stretched; the Details row text stays bright and outlined on it |

## Sliders

- **Border scale** - 70-100 %: the thickness of the bamboo (100 % = 10 units, as thick as the room beside the chat and the meters allows; the minimap frame follows it).
- **Glass opacity** - 30-100 %: the dark green glass behind chat and Details (also behind the objective tracker).
- **Parchment brightness** - 70-110 %; available only while Background is PARCHMENT.

## Where the material is used

Chat ([CHAT.md](CHAT.md)), Details ([DETAILS.md](DETAILS.md)), minimap ([MINIMAP.md](MINIMAP.md)) and the BUFFS panel ([BUFFS.md](BUFFS.md)); the objective tracker shares the glass opacity. The bottom information bar has its own **Bar glass opacity** under LAYOUT, and tooltips their own **Glass opacity** under TOOLTIPS.

## Not changed

Unit frames keep the FRAME THEME gradient, not the panel material. The content inside the panels - chat text, meter rows, the map - is not altered by the material; Details' own bar colours stay as they are.
