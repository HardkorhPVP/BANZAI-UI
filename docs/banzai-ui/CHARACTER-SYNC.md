# Character Sync

Character Sync carries **one approved BANZAI setup** to your other characters. Only BANZAI-owned visual settings move; every character keeps its own spells, bars, macros, talents, keybinds, class, spec and role. **Nothing changes on a character until you press a button on that character.**

Page: **BANZAI > CHARACTER SYNC**, tabs **STATUS**, **WHAT SYNCS**, **DIAGNOSTICS**.

## How it works

1. Set up one character the way you want it and make it the master: **BANZAI MASTER > SET AS BANZAI MASTER**. See [MASTER-CHARACTER.md](MASTER-CHARACTER.md).
2. The master's BANZAI setup is captured automatically whenever it logs out (**CAPTURE MASTER NOW** does it immediately).
3. On another character open CHARACTER SYNC. **THIS CHARACTER** shows its class, its state badge, its backup line and what would change.
   - Not on BANZAI yet: **APPLY BANZAI** - the confirmation lists the plan; the character's current setup is saved first.
   - Already synced but the master has changed: **UPDATE CHARACTER**.
   - **RESTORE PRE-BANZAI** puts the character back to its setup from before BANZAI (the master's setup is not affected; if you do this on the master it stops being the master).
4. **SYNC STATUS** lists your characters and whether each is in step with the master. **VERSION** says which BANZAI version captured the master's setup; after an upgrade, log in on the master once so it is captured again.

## WHAT SYNCS

**BANZAI SYNCS** lists exactly what carries over: frame theme and gradient, bamboo, panel style (border, background, border scale, glass opacity, parchment brightness), fonts (display font and size), tooltips, AFK screen, objective tracker on / off, cast history and cooldown-bar appearance, bottom panel, chat / Details / minimap appearance, action-button style, BUFFS panel settings, frame style (BANZAI CLASSIC / BANZAI SPLIT with its positions, scales and texts), Details meter style, identity art, split cast bar choices, PvP presentation choices, preview preferences, the shared ElvUI Banzai profile's visual values, the DPS / HEALER role layouts, and the Banzai Details profile.

**NEVER SYNCED**: action-bar spell assignments, spells (the cooldown bars' tracked spells included), macros, keybinds, talents and loadouts, equipment and equipment sets, consumables, Details combat history, chat history, currencies, quests, reputation, progression, unrelated addon settings. No full SavedVariables database is cloned. Class colours, the Fabled class / spec art, resources and the role layout come from each character itself.

## DIAGNOSTICS

**SYNC DIAGNOSTICS** shows component state; **CHARACTERS ON BANZAI** lists every character that has applied BANZAI and its state.

## Notes

- Characters sharing the ElvUI profile still each keep their own frame style; it is applied at their login.
- A synced character can be put back any time from CHARACTER SYNC or **BACKUP & RESTORE > CHARACTER RESTORE > Restore this character** (this also restores its own BANZAI settings from before sync and stops it being synced).
