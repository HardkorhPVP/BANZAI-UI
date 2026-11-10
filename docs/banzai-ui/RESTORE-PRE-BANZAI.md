# Restore Pre-Banzai

Everything BANZAI changes is **recorded before it is changed**. When you apply BANZAI on a character, its ElvUI layout, its Details layout and its Kaliel's Tracker state are saved; the restore puts them back.

Page: **BANZAI > BACKUP & RESTORE**. Command: `/banzai restore`.

## CURRENT SNAPSHOT

Shows whether BANZAI is applied on this character, when, and what was saved from before: the ElvUI layout name, the Details layout, and - for a synced character - its own BANZAI settings from before Character Sync.

## PRE-BANZAI RESTORE

**Restore pre-Banzai settings** - this character back to its ElvUI, Details and Kaliel's Tracker setup from before BANZAI. Confirm, then reload. The BANZAI setup stays saved, so you can apply it again any time from HOME.

## CHARACTER RESTORE

**Restore this character** - the same, plus this character's own BANZAI settings from before Character Sync gave it the master's. It stops being synced (and stops being the master if it was). CHARACTER SYNC > **RESTORE PRE-BANZAI** is the same action.

## STATUS

Never touched by a restore: spells, action bars, macros, talents, keybinds, equipment sets, Details history, chat history, currencies, other addons. Snapshots are per character; the shared Banzai ElvUI profile stays for your other characters.

## Behaviour

- A restore cannot run in combat (chat says so); try again after combat.
- The restore returns Blizzard's objective tracker and Kaliel's Tracker visibility to the recorded state.
- The buttons are disabled when there is nothing recorded for this character.
- Restoring one character never changes another character or the master's captured setup.

## Uninstalling

Restore each character first, then remove the two addon folders - see [INSTALLATION.md](INSTALLATION.md).
