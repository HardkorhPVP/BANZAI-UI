# Troubleshooting

Short answers first. If none fits, see [SUPPORT.md](SUPPORT.md).

## BANZAI does not appear in the ElvUI options / `/banzai` does nothing

- Both **Banzai** and **Banzai Art** must be ticked in the AddOns list, together with **ElvUI** and **JiberishMedia**. Banzai Art depends on both; without JiberishMedia it does not load.
- Check the folders are `Interface\AddOns\BushidoPrivateCompat` and `Interface\AddOns\BushidoPrivateRestore` with the `.toc` directly inside each (not nested one level deeper).
- `/reload`.

## I logged in and nothing changed

Intended. Open **HOME** and press **Apply / repair Banzai**, then reload.

## The frames look half-applied after an upgrade

**HOME > Apply / repair Banzai** writes the full setup again without losing your pre-BANZAI snapshot. Reload afterwards.

## A setting did nothing

Read its description: settings that say *A reload applies it* need **Reload UI** (HOME) or `/reload`. Everything else applies at once.

## Headings or names are drawn in the small font

The display face cannot show every character of that string, so the whole string uses the Information Font (Xangda Shiny has letters only). Pick another face under **APPEARANCE > FONTS > Display font** or use **BANZAI Default**. [FONTS.md](FONTS.md)

## My font choice reset to BANZAI Default

The face you had chosen is not shipped in this release; the selection was normalised to BANZAI Default. Choose any of the shipped faces.

## Kaliel's Tracker disappeared

The Banzai tracker is on (**LAYOUT > OBJECTIVE TRACKER > Banzai tracker**). Kaliel's is hidden through its own visibility setting while Banzai's shows and comes back when you turn the Banzai tracker off (reload).

## Details is not side by side / the frame is wrong

**LAYOUT > DETAILS > Arrange side by side**. If Details' own profile keeps overriding it, check that Details' "always use profile" is not forcing another profile on this character.

## The BANZAI wordmark at the top is gone

Either **APPEARANCE > BRANDING > BANZAI logo** is off, you are in combat (it moves between Player and Target if **Combat logo** is on), or BanzaiSland is hosting the integrated BANZAI SLAND launcher - the setting is unchanged and the wordmark returns when BanzaiSland is not showing the mark.

## Restore says it cannot run

Restores do not run in combat. Leave combat and press it again.

## An alt looks different from my main

Character Sync does not apply by itself. On the alt, **CHARACTER SYNC > APPLY BANZAI** (or **UPDATE CHARACTER** if it was synced before). Make sure a master is set and has logged out since its last change (or press **CAPTURE MASTER NOW** on it).

## Something else

1. `/reload`.
2. `/banzai status` and copy the chat output.
3. Copy the full text of any Lua error (BugSack / BugTabs or the game's error window).
4. Follow [SUPPORT.md](SUPPORT.md).
