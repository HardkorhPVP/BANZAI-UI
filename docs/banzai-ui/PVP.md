# PvP

PvP-first unit frames and your own cooldown bars, also used in PvE. Everything comes from ElvUI's own frames and the game's own categories; nothing the game hides is guessed, and the party / arena frames stay **hands-off secure frames** - BANZAI colours and decorates them, it never moves or replaces them in combat.

Page: **BANZAI > PVP**, tabs **FRAMES**, **COOLDOWN BARS**, **PREVIEW**. Settings marked with *A reload applies it* take effect after a reload.

## FRAMES tab

- **PARTY / ARENA FRAME SIZE > Enemy offensive / defensive icons** - enemies' big / external defensives and important buffs, shown small to the left of the trinket.
- **ROLE ICON > Role icon in the bar** - mMediaTag's role icon at the right end of party / arena ally bars.
- **TRINKET > Trinket circles** - the PvP trinket as a round icon on the arena enemy frames (trinket | health | class / spec circle).
- **CC > CC emphasis** - how strongly crowd control on a unit is emphasised (a level selector).
- **DISPELLABLE STATE > Dispellable emphasis** - how strongly a dispellable debuff is shown (a level selector), with a dispel glow.
- **CASTS > Banzai cast colours** - **INTERRUPTIBLE** casts in amber, **NOT INTERRUPTIBLE** in steel violet on ElvUI's cast bars. Off: Bushido's colours.

## COOLDOWN BARS tab

Your own offensive and defensive cooldowns as bars beside the centre of the screen.

- **COOLDOWN BARS**: **Cooldown bars** on / off, **Scale**, **Opacity**, **Distance from the centre**, **Height**.
- **OFFENSIVE COOLDOWN BARS**: **Bars at most** (1-5) and **Tracked offensive cooldowns** - tick the spells to track.
- **DEFENSIVE COOLDOWN BARS**: **Bars at most** (1-5) and **Tracked defensive cooldowns**.

The tracked spells are class abilities: they belong to each character and are **never** carried by Character Sync.

## PREVIEW tab

Sample frames and bars labelled *SAMPLE DATA*, with synthetic states: a role selector, a state selector, **NEXT STATE**, **PARTY + ARENA**, **RAID**, **COOLDOWN BARS**, **HIDE ALL**. Hidden automatically in combat.

## WoW Forever

PvP presentation is implemented where WoW Forever supports it and validated offline; dedicated live PvP / Arena / Battleground validation is deferred. What that client has no data for is left out rather than shown as a made-up value: no conquest, no separate PvP item level, arena trinket state shown as unknown. Your own cooldown bars show nothing there yet (no spell list is verified for that client; Retail's is not reused). See [WOW-FOREVER.md](WOW-FOREVER.md).

## Not changed

Which spells you have, their keybinds, the arena frames' secure behaviour, and any sArena or other arena addon - BANZAI's arena enemy frames are ElvUI's arena frames in the Banzai design.
