# Fonts

BANZAI's own texts - headings, names, spell labels, the zone name, the large Player / Target numbers - use a **display font** you choose. Everything small (names elsewhere, nameplates, chat, tracker, tooltips, cast history, Details rows, bottom bar, timers) uses the **small text font**.

Page: **BANZAI > APPEARANCE > FONTS**. Changes to the display font apply immediately.

## Display font

The selector offers, in this order:

1. **Automatic**
2. **BANZAI Default**
3. **Shojumaru**
4. **Ryujin Attack**
5. **Gang of Three**
6. **Osaka Sans**
7. **Sekaiwo**
8. **Xangda Shiny**
9. **Ninja Naruto**
10. **Information Font**

### The rules

- **BANZAI Default** is **Shojumaru at 105 %**. It is the default for every character.
- **Automatic** uses BANZAI Default only when **every character of a string** is supported by Shojumaru; otherwise the **whole string** is drawn in the Information Font. Text is never spliced letter by letter. On game clients whose language Shojumaru cannot cover, Automatic uses the Information Font.
- An **explicitly chosen alternate** (Shojumaru, Ryujin Attack, Gang of Three, Osaka Sans, Sekaiwo, Xangda Shiny, Ninja Naruto) is drawn **at its own size** - no 105 % base. Any string it cannot show falls back to the Information Font as a whole.
- **Xangda Shiny has letters only**: any string with digits or punctuation (health values, timers, "Level 80") is drawn in the Information Font.
- **Information Font** is the ElvUI profile's small font - the one under **Small text font**. Choosing it explicitly draws all display text in that font.
- A font file the game cannot load falls back to the Information Font the same way.
- If a saved selection names a font that is no longer shipped, it becomes BANZAI Default on login.

### Other controls

- **Preview display font** - opens a preview with sample strings in the selected face and shows its author, source, licence and whether a fallback is in effect.
- **Banzai display size** - 85-120 %: scales the selected display face. BANZAI Default already includes its 105 % base; the slider is applied on top.
- **Profile display font** - ElvUI's own big numbers in the Banzai profile (a LibSharedMedia list). **Small text font** - the small font everywhere else. Press **Apply fonts** to write these two into the profile; a reload finishes it.

## Independent from BanzaiSland

If you also run BanzaiSland, it has the same list of display fonts but its own selection. Changing the font in BANZAI UI does not change BanzaiSland and vice versa.

## Notices

The shipped font files, their authors, sources, licence basis and checksums are listed in `BushidoPrivateCompat\media\fonts\FONT-NOTICES.txt` inside the addon and in [THIRD-PARTY-NOTICES.md](THIRD-PARTY-NOTICES.md). The Information Font adds no file.
