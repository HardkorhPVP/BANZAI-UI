# Minimap

The minimap sits in the top right of the screen in a square bamboo frame, the **zone name above it in the display font**, the minimap-button collector (MinimapButtonButton, if installed) in the corner and the objective tracker below. ElvUI's buffs / debuffs, queue eye and durability sit in the cluster as Bushido placed them.

Page: **BANZAI > LAYOUT > CHAT / DETAILS / MINIMAP / TRACKER > MINIMAP**.

## Settings

- **Banzai minimap frame** - the bamboo frame around the minimap on / off.
- **Zone name** - the zone label above the frame on / off.
- The frame's border and interior come from **APPEARANCE > PANEL STYLE**; **Border scale** also sets the minimap frame's thickness ([MATERIALS.md](MATERIALS.md)).
- The zone name uses the **Display font** chosen under **APPEARANCE > FONTS** ([FONTS.md](FONTS.md)); a zone name the chosen face cannot show is drawn in the Information Font as a whole.

## Behaviour

- The minimap itself is ElvUI's; Banzai Art draws the frame and the label around it.
- Kaliel's Tracker and the minimap-button collector are moved only when they would overlap, through their own saved settings, and are restored by Restore Pre-Banzai.

## Not changed

Minimap tracking, zoom, the map's contents, the minimap buttons themselves.
