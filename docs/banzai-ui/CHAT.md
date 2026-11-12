# Chat

The chat sits in a bamboo-framed panel **flush with the left edge of the screen**, the same size as the Details frame on the right, with a **CHAT** title on its top border. Both panels rest on the bottom information bar.

## Settings

- **LAYOUT > CHAT / DETAILS / MINIMAP / TRACKER > CHAT > Banzai chat frame** - the bamboo frame and background around the chat on / off.
- The frame's border colouring and interior (SOLID / GLASS / PARCHMENT) follow **APPEARANCE > PANEL STYLE** - see [MATERIALS.md](MATERIALS.md).
- The chat's font is the **Small text font** under **APPEARANCE > FONTS**.
- **LAYOUT > CAST HISTORY / BOTTOM PANEL / BUFFS > BOTTOM PANEL > Bar height** - the chat and Details frames stay on the bar when its height changes.

## Behaviour

- ElvUI's own chat backdrop is turned off while the Banzai frame is on; the frame is drawn by Banzai Art around ElvUI's chat.
- With the frame off, the chat stays where BANZAI placed it without a panel.
- The panel takes the material exactly like Details, the minimap and the BUFFS panel; a parchment chat keeps bright, outlined text.

## WoW Forever

ElvUI's installer there leaves a second, undocked chat window ("Loot / Trade"). Lying inside the Banzai chat frame it would cover General, so BANZAI docks it as a tab of the General window (the same as dragging its tab onto the dock) and keeps General in the frame. A window floating anywhere else, a whisper window and the combat log are left alone. **Restore pre-Banzai settings**, or switching the Banzai chat frame off, puts the window back where it was.

## Not changed

Chat channels, tabs, chat history, chat settings in ElvUI other than the backdrop and position, and any chat addon's behaviour.
