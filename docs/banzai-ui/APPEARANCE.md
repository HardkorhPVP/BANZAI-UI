# Appearance

Page: **BANZAI > APPEARANCE**. Everything here applies at once unless its description says *A reload applies it*.

## FRAME THEME

- **Banzai frames** - **VIBRANT**: the green -> purple bamboo gradient (default). **CLASS**: your class colour on the same bamboo. `/banzai theme vibrant|class` does the same.
- **Frame gradient** - *Green -> purple* or *Purple -> green*: which way the ramp runs along the frames.
- **Frame intensity** - 50-100 %: how saturated the gradient is painted.
- **Bamboo bundles** - the tied three-stalk bamboo bundles at the ends of the Player and Target frames (other unit frames stay clean).
- **Smooth health bars** - one continuous Banzai surface on unit frames, nameplates and Details rows; off gives Bushido's slotted textures. A reload applies it.

## BAR TEXTURE

The texture of BANZAI's own bars. It shows at once; no reload.

- **BANZAI Weave** (default) - a slashed, brushed surface: free diagonal strokes running down to the right across the whole bar. The filled part keeps its colour; the empty part stays dark and neutral with the same strokes running through it, so a bar that is half empty is still one material. It is drawn one texel per screen pixel, so no bar stretches it and no UI scale blurs it. Absorb, shield and heal-prediction overlays and all texts stay on top of it, unchanged.
- **BANZAI Smooth** - one continuous surface: the bars as they were before 1.5.1.

Bars that take it: the Player, Target, Focus, Target of Target, Pet, party, raid, boss and arena enemy health and resource bars BANZAI dresses (BANZAI CLASSIC and BANZAI SPLIT), the targeted enemy nameplate, the BANZAI SPLIT cast bar, the cooldown bars and the unit-frame samples. `/banzai bars smooth|weave` does the same.

Party, raid, boss and arena frames stay ElvUI's own secure unit frames at their own sizes: the material is laid on the bar, nothing is built on a frame in combat (a frame that appears in combat gets it when combat ends), and ElvUI's absorb, heal-prediction, debuff and dispel indicators stay above it. `/banzai frames` lists what each kind of frame shows.

Not affected: raid pets and tank / assist frames, other nameplates, the game's own compact frames, Details rows, and everything that is not a status bar - panels (glass, solid or parchment), chat, windows, buttons, tabs, borders and the minimap. The **Smooth health bars** switch above is separate and unchanged. Both textures are also registered with LibSharedMedia as status-bar textures named *BANZAI Smooth* and *BANZAI Weave*.

## PANEL STYLE

The chat, Details, minimap and BUFFS panels share one bamboo construction. **Border style** (CLASS / BANZAI / HARDKORH), **Background** (SOLID / GLASS / PARCHMENT), **Border scale**, **Glass opacity** and **Parchment brightness** are described in [MATERIALS.md](MATERIALS.md).

## BRANDING

- **BANZAI logo** - the small BANZAI wordmark at the top centre, out of combat. Clicking it opens these settings. (When BanzaiSland hosts the integrated BANZAI SLAND launcher, this wordmark steps aside; the setting itself is not changed.)
- **Combat logo** - in combat the wordmark moves between Player and Target, larger, with a small Banzai tree behind it, and returns to the top afterwards.
- **Targeted enemy nameplate** - class or reaction gradient on your current target's nameplate with its health and percentage inside the bar.

## FONTS

The **Display font** selector, **Preview display font**, **Banzai display size**, **Profile display font**, **Small text font** and **Apply fonts** are described in [FONTS.md](FONTS.md).

## TEXT ON THE FRAMES

- **Health inside the bars** - current health and percentage inside the Player, Target, Focus, Party, Arena and Boss bars (raid frames: the percentage). Over the empty part of a bar the text is ghosted instead of disappearing.
- **Health percentage** - show the percentage beside the health value.
- **Specialization in names** - *PLAYER - SPEC* on your frame, *SPEC - NAME* on player targets; NPCs show the name only. On narrow frames the spec gets its own line.
- **Health number size** - the health under the bar, shown only when *Health inside the bars* is off.

## What this page does not change

Unit-frame positions and sizes (UNIT FRAMES), the action-button look (ACTION BARS), what is shown in chat, Details or the tracker (LAYOUT), tooltips (TOOLTIPS). Nothing here touches spells, bars, macros or keybinds.
