# Details!

With Details! installed, BANZAI shows **DAMAGE | HEALING** side by side in the lower right of the screen inside one bamboo frame, the titles on its top border (red DAMAGE, green HEALING), with a real centre gutter between the two meters. Details' own profile and window API are used; Details' files are not touched.

Page: **BANZAI > LAYOUT > CHAT / DETAILS / MINIMAP / TRACKER > DETAILS**.

## Settings

- **Banzai Details frame** - the bamboo frame around both meters on / off.
- **Arrange side by side** - puts the two Details windows back into the BANZAI side-by-side layout if you moved or resized them.
- **Meter style**:
  - **Banzai Current** (default) - the approved meter rows.
  - **Banzai Compact** - thin class-coloured bars with a small round identity icon at the start of each row, the name above the bar in its class colour and a large value; tighter rows.
  Both keep the bamboo frame, the panel style and the DAMAGE / HEALING titles.

The frame's border and interior (SOLID / GLASS / PARCHMENT) come from **APPEARANCE > PANEL STYLE** ([MATERIALS.md](MATERIALS.md)); on parchment the row text stays bright and outlined. **Smooth health bars** (APPEARANCE > FRAME THEME) also gives the Details rows the continuous Banzai surface.

## Behaviour

- BANZAI writes a Banzai Details profile for the meters (layout, fonts, bar and window styling, position). This character is exempted from Details' "always use profile" so the BANZAI layout stays.
- Character Sync carries the Banzai Details profile and the meter style; **Details combat history is never synced or restored**.
- Restore Pre-Banzai returns the Details layout recorded before BANZAI.

## Not changed

Details' data, segments and history; Details' own options outside the Banzai profile; meter bar colours.
