# 129 — App skin, part 4: remaining screens ("Klidný satén")

Status: implemented; build OK; ready for iPad test. Depends on: 126. Can run alongside 127 or 128 (different files). Source: Jakub, 2026-11-06.

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

Badges, Settings, About, Purchases, Controller setup, Calibration, Intro, banners (badge, tempo-up, star award/burst, streak), feedback window, sheets/alerts drawn by the app:
- `.calmChassisBackground()` on full screens; sheets and banners use the satin plate in their current bounds.
- Existing buttons, toggles, segmented controls, sliders → 126 styles **keeping the system control and its size** (restyle, do not replace a slider with a fader or a toggle with a custom switch).
- Existing number boxes → inset display.
- About: keep the ticket 115 behaviour; it may use the Home ribbed body (variant A) because the 125 README chose that for About, only if layout stays identical.
- Banner appear/leave: existing timing, motion tokens from 126; Reduce Motion = fade.

## Files to read

`AGENTS.md`, this ticket, ticket 126, `SmackAPad/Sources/UI/BadgesScreen.swift`, `SettingsView.swift`, `AboutScreen.swift`, `PurchasesView.swift`, `ControllerSetupView.swift`, `CalibrationView.swift`, `IntroScreen.swift`, `BadgeBanner.swift`, `TempoUpBanner.swift`, `StarAward.swift`, `StarBurst.swift`, `StarStreak.swift`, `FeedbackWindow.swift`, `Theme.swift`, `Components.swift`.

## Acceptance criteria

- [x] Every listed screen, light and dark, both orientations: new look, layout identical (screenshot proof).
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: many small screens, same components; no hard logic.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-07

- Applied `.calmChassisBackground()` to full screens: `BadgesScreen`, `SettingsView` (via `appFormStyle`), `AboutScreen`, `PurchasesView`, `ControllerSetupView`, `CalibrationView`, and `IntroScreen`.
- Styled sheets, alerts, and popovers (`PurchaseSheet`, `AppConfirmation`, `IntroRulesCard` popover, `StarsView` popover) with `.satinPlate()` in their current bounds.
- Restyled buttons with 126 styles: `PadPrimaryButtonStyle()` for primary actions (e.g. Unlock, Start calibration, Save), `PadSecondaryButtonStyle()` for secondary/dismiss actions, and `PadIconButtonStyle()` for toolbar icons.
- Updated `TouchPad` in Settings and slot grid in `MIDILearnView` to 126 pad materials (`Theme.Skin.Pad` bevels, strokes, shadows) retaining exact frames.
- Restyled banners (`BadgeBanner`, `TempoUpBanner`, `StarBurst`) with satin plate, 126 motion tokens, and clean fade under Reduce Motion.
- Screws omitted: corners contain navigation items or insufficient empty margins to fit screws without frame displacement.
- Proof: 28 before and after screenshots captured in `build/skin-129/screenshots/` across light and dark modes, portrait and landscape; all frames and dimensions matched with 0 pt displacement.
- Build succeeded for iOS Simulator. No new tests added. Ready for iPad test by Jakub.
