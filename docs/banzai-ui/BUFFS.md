# BUFFS panel

ElvUI's buff icons at the top left sit inside a Banzai panel with a **BUFFS** title, 10 buffs per row, 2 or 3 rows. Debuffs stay below them at full size. The buffs are ElvUI's; the panel is Banzai Art's.

Page: **BANZAI > LAYOUT > CAST HISTORY / BOTTOM PANEL / BUFFS > BUFFS PANEL**.

## Settings

- **BUFFS panel** - on / off. Off: the buffs exactly as before, without a panel.
- **Maximum rows** - *2 rows (20 buffs)* or *3 rows (30 buffs)*.
- **Buff size** - 50-100 % for the buff icons (debuffs below stay full size). A reload applies it.
- **Position X** - the buffs' left edge in units from the left screen edge (the panel follows the buffs).
- **Position Y** - the buffs' top edge in units from the top screen edge.
- **Reset position** - back to the BANZAI position.

The panel's border and interior come from **APPEARANCE > PANEL STYLE** ([MATERIALS.md](MATERIALS.md)).

## Behaviour

- Panel on / off, rows and position are carried by Character Sync; **the buffs themselves never are** (they are the game's).
- `/banzai status` prints the panel state, rows and position.

## Not changed

Which buffs are shown or filtered (ElvUI's aura settings), the debuffs, and aura durations - BANZAI reads nothing the game protects.
