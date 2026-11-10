# Objectives (Banzai tracker)

The Banzai objective tracker lists your tracked quests under the minimap in the Banzai style: click a quest to focus it or open it in the quest log, a **HIDE / SHOW** button to collapse it, a **LAYOUT** toggle, and tooltips for each quest and objective.

Page: **BANZAI > LAYOUT > CHAT / DETAILS / MINIMAP / TRACKER > OBJECTIVE TRACKER**.

## Settings

- **Banzai tracker** - on / off. A reload applies it.
- **Collapsed** - the same as the tracker's HIDE / SHOW button.
- **TOOLTIPS > OBJECTIVES > Objective tooltips** - hovering a quest or objective shows the full title and text, level / type, zone, tracking state, progress and its timer where the game has one.
- The glass behind the tracker follows **APPEARANCE > PANEL STYLE > Glass opacity**.

## Behaviour

- While the Banzai tracker is on, **Blizzard's objective tracker is parked** (not destroyed) and **Kaliel's Tracker, if installed, is hidden through its own per-zone visibility setting**. That setting is recorded first and put back when you turn the Banzai tracker off or restore pre-Banzai. Kaliel's files are never touched.
- The tracker reads the game's quest log API only; it never automates quest actions.
- `/banzai status` prints which tracker owns the screen.

## Not changed

Your quests, what is tracked, quest progress; Kaliel's Tracker's own settings beyond the visibility switch; Blizzard's tracker when the Banzai tracker is off.
