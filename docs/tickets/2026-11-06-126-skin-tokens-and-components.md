# 126 — App skin, part 1: shared tokens and components ("Klidný satén")

Status: ready-for-agent. Depends on: 125 (preview, done). Source: Jakub, 2026-11-06: chose **variant B "Klidný satén"** for all non-Home screens; only colours, materials and motion may change, never layout or sizes.

## Hard rule: skin only, never layout (read first)

Jakub, 2026-11-06: the 125 preview "is terribly broken" in layout. **Do not copy anything about layout from the preview.** From it take only colours, materials, bevels, shadows and motion (the token values in `docs/design/2026-11-06-app-visual-unity/README.md` section 2 and `css_styles.py`). Never its HTML structure, sizes, paddings or extra elements.

- Every view keeps its exact **frame**: same position, width, height, padding, spacing, font size, line count, order and number of elements, in both orientations. No new elements (no faders replacing sliders, no MIDI monitor, no numbered steps, no extra filters, no labels).
- Allowed: fills, gradients, strokes, corner radius of the **existing** shape, inner bevels drawn inside the existing bounds, shadows (they do not affect layout in SwiftUI), text colour, press/appear animations.
- Screws only where they fit inside existing empty corner space of a large plate without moving anything; otherwise leave them out and say so in the report.
- **Proof**: before you change a screen, take simulator screenshots (iPad Pro 11″, landscape + portrait, light). After the change take the same ones and overlay/compare: element edges must be in the same place (±1 pt). Put the before/after pairs in `build/skin-<ticket>/` (not committed) and say in the report that they match. If something cannot get the new look without a layout change, skip it and list it.
- Orange pattern band in Practice stays exactly as it is (colour, notes, numbers, playhead). Home stays exactly as it is.
- Palette of ticket 92 only, light and dark, AA contrast. Reduce Motion via `Theme.Motion.Policy` / `.motion(_:value:)` only.
- No change to timing, audio, scoring, MIDI, navigation, texts.
- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).

## What to build

Shared building blocks only, used by tickets 127–129. **No screen changes in this ticket** except where a screen already uses one of the components below (then it changes automatically; check it with the screenshot proof).

1. **Theme tokens** (`Theme.swift`): calm satin chassis (175° gradient, ribbing at 5 % opacity, 4 pt pitch, same colours as Home body), satin plate (165° gradient, 16 pt radius, 1.5 pt top highlight / bottom shadow bevel, plate shadow), pad material for controls (8 pt radius, bevel, press), inset display (dark glass `#151412`-ish from the palette, inner shadow), light bar (2 pt orange, breathing `Theme.Motion.ledBreath`). Reuse the Home tokens from tickets 112/119 wherever they exist; do not create a second copy of the same value.
2. **Background modifier** `.calmChassisBackground()`: draws the calm satin body full screen, rasterised once (as in ticket 119, `drawingGroup` or cached Canvas), no per-frame work.
3. **Plate modifier** `.satinPlate()`: draws the plate **behind the existing content in its existing bounds** (background, never padding).
4. **Button styles**: `PadPrimaryButtonStyle` (orange hero pad like the Home hero), `PadSecondaryButtonStyle` (satin pad), `PadIconButtonStyle` (toolbar icons). Press = Home `padPress` + `padFlash`; Reduce Motion = darker fill only. They must not change the button label size or the button frame compared to the current styles in `Components.swift`.
5. **Segmented hardware keys**: a style for the existing mode switch / segmented controls: same segment sizes, selected segment gets the orange light bar along the bottom edge (inside the bounds), switching animates the bar with the existing Listen ↔ Play animation.
6. **Inset display** modifier for number boxes (BPM, score): same frame, new fill, inner shadow, numeric roll (ticket 27) kept.

## Files to read

`AGENTS.md`, this ticket, tickets 27, 92, 112, 119, 125, `docs/design/2026-11-06-app-visual-unity/README.md` (section 2 only), `css_styles.py` (token values only), `SmackAPad/Sources/UI/Theme.swift`, `Components.swift`, `HomeScreen.swift` (existing pad material and tokens only).

## Acceptance criteria

- [ ] Tokens and components exist, reuse Home values, light and dark.
- [ ] Any screen already using the changed components: before/after screenshots match in layout (±1 pt).
- [ ] Build succeeds. No new tests.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: the foundation for three more tickets; must be exact and must not shift frames. Sol first because the previous Flash preview broke layout.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
