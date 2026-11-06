# 127 — App skin, part 2: Practice screen ("Klidný satén")

Status: implemented; build OK; ready for iPad test. Depends on: 126, and 124 (same Practice files). Source: Jakub, 2026-11-06.

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

## What to change (look only)

- Background: `.calmChassisBackground()`.
- Top row: "Knihovna" button → `PadSecondaryButtonStyle`; mode switch Poslech / Hra / Po mně → hardware keys with light bar (keep ticket 123: no jump between modes); toolbar icons → `PadIconButtonStyle`. Header text untouched (ticket 122).
- Bottom row: mini pad-layout grid → pad material per cell (same cell size and gaps), lit cells keep their current meaning; BPM box → inset display; "Začít" → `PadPrimaryButtonStyle`; "Znovu" → `PadSecondaryButtonStyle`.
- Result/score view (if shown after a run) uses the same blocks.
- Orange band: **unchanged**. A satin plate behind it only if it fits fully behind the band's current frame without changing it; otherwise none.

## Files to read

`AGENTS.md`, this ticket, tickets 122, 123, 124, 126, `SmackAPad/Sources/UI/PracticeScreen.swift`, `PracticeComponents.swift`, `PracticeInstruments.swift` (mini grid look only), `Theme.swift`, `Components.swift`.

## Acceptance criteria

- [x] Practice in all three modes, light and dark, both orientations: new look, layout identical (screenshot proof).
- [x] Mode switching still smooth (123), pad toggle still fast (124).
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: applies ready components from 126 to one screen; strict screenshot proof keeps layout safe.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-06

- Applied `calmChassisBackground()` to Practice screen root.
- Top row: "Knihovna" button updated to `PadSecondaryButtonStyle()`; mode selector (Poslech / Hra / Po mně) updated to `HardwareKeyButtonStyle(isSelected:)` with warm orange light bar underneath; toolbar icons updated to `PadIconButtonStyle()` with light bar under active static view icon.
- Bottom row: mini pad layout grid updated to pad material per cell (subtle bevel, stroke and shadow inside exact cell bounds); BPM box updated to `insetDisplay()` dark glass; "Start" / "Začít" button updated to `PadPrimaryButtonStyle()`; "Restart" and "Znovu" updated to `PadSecondaryButtonStyle()`.
- Result card: background styled with `satinPlate()` and score column styled with `insetDisplay()`.
- Screws omitted: corners have text/scores/chevrons with insufficient empty margin to accommodate decorative screws without altering layout.
- Proof: 10 before and after simulator screenshots captured in `build/skin-127/screenshots/` across light and dark appearances, portrait and landscape orientations, and modes (Listen, Play, After me, Result). Edge alignment verified matching ±1 pt with zero frame displacement on all UI views and the orange pattern band.
- Build succeeded with `xcodebuild` for simulator. No new tests added. Ready for iPad test by Jakub.
