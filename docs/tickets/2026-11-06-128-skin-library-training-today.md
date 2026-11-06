# 128 — App skin, part 3: Library, Training, Today session ("Klidný satén")

Status: ready-for-agent. Depends on: 126, and 121 (same Training/Library files). Source: Jakub, 2026-11-06.

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

- All three screens: `.calmChassisBackground()`.
- Library: existing panels/cards → `.satinPlate()` in their current bounds; existing buttons and segmented controls → 126 styles; stars and counts keep their look and colours.
- Training: same; the existing "due"/attention state may use the light bar inside existing bounds.
- Today session: hand-off card → satin plate (screws only if they fit, see hard rule); buttons → 126 styles; keep ticket 113 step-in animation and the fixed button row.
- List appearance: optional stagger with `Theme.Motion.bootStagger` (opacity only, no movement that changes layout); Reduce Motion = plain fade.

## Files to read

`AGENTS.md`, this ticket, tickets 113, 121, 126, `SmackAPad/Sources/UI/LibraryScreen.swift`, `LessonPicker.swift`, `LessonPatternStrip.swift` (look only), `TrainingScreen.swift`, `TodaySessionScreen.swift`, `Theme.swift`, `Components.swift`.

## Acceptance criteria

- [ ] Three screens, light and dark, both orientations: new look, layout identical (screenshot proof).
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: applying 126 components, three screens.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
