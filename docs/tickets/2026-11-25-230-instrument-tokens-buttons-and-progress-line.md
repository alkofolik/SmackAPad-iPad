# 230 — Instrument tokens: strict 8/6 pt radii, IBM Plex scale, single button system, and readable ProgressLine

Status: ready-for-agent

## Goal

Establish one unified studio-instrument token system for all non-Home screens in `Theme.swift`, `HardwareSurfaces.swift`, `PadButtons.swift`, and `StarsAndProgress.swift`, removing competing button styles and fixing the 2 pt single-colour `ProgressLine`, while keeping `HomeScreen` hardware drawing completely unchanged.

## Rules

1. **Home untouched.** Do not modify `HomeScreen.swift`, `HomeControllerChassis.swift`, `HomeHardwareControls.swift`, `HomeControllerFaders.swift`, `HomePadGrid.swift`, `HomePadView.swift`, `Theme.HomeController`, or `Theme.padTitle`.
2. **Radii (`Theme.Radius`).** Define `panel: CGFloat = 8` (matching `pad = 8`) and keep `button: CGFloat = 6` and `controllerPlate: CGFloat = 16` (used only by Home's plate). Update `Theme.Skin.Plate.radius` to `Theme.Radius.panel` (`8`) and remove drop shadows from `SatinPlateSurface` (`HardwareSurfaces.swift`) so non-Home plates use clean 1 pt borders and subtle surface steps instead of floating card shadows.
3. **Typography scale (`Theme.swift`).** Reserve `BarlowCondensed-ExtraBold` strictly for Home pads, the `SMACK-A-PAD` wordmark, and `CountInNumeral`. Standardize `IBM Plex Sans` tokens for inner screens:
   - `screenTitle`: `boldDisplay(26)` (26 pt Bold)
   - `sectionTitle`: `strong(19)` (19 pt SemiBold)
   - `rowTitle`: `strong(18)` (18 pt SemiBold)
   - `control` / `navigation`: `text(16)` (16 pt Regular)
   - `meta`: `text(14)` (14 pt Regular)
   - `caption`: `text(13)` (13 pt Regular)
   - `action`: `strong(18)` (18 pt SemiBold)
   Keep `mainValue` (`strong(44)`) for primary instrument readouts (BPM / score).
4. **Single tactile button system (`PadButtons.swift`).** Add an optional `onDark: Bool = false` parameter to `PadSecondaryButtonStyle` (using `Theme.white.opacity(0.10)` fill, `Theme.white.opacity(0.28)` 1 pt border, and `Theme.white` ink when `onDark == true`). Delete `TrainingActionButtonStyle` (`DaySummaryView.swift`), `ResultPrimaryButtonStyle`, and `ResultSecondaryButtonStyle` (`PracticeInstruments.swift`), replacing all their call sites in `DaySummaryView.swift`, `TrainingScreen.swift`, and `PracticeInstruments.swift` with `PadPrimaryButtonStyle()` and `PadSecondaryButtonStyle(onDark:)`.
5. **Three-step `ProgressLine` (`StarsAndProgress.swift`, `Theme.swift`).** Keep `Theme.starColor(for:)` returning full `Theme.orange` for earned star icons (`1...3`) and neutral track colour for `0`, and add `Theme.progressSegmentColor(for stars: Int) -> Color` returning `Theme.orange` for 3★, `Theme.orange.opacity(0.68)` for 2★, and `Theme.orange.opacity(0.38)` for 1★. Update `ProgressLine` to use `Theme.progressSegmentColor(for:)` and increase its height from `Theme.Size.border` (`2 pt`) to `5 pt` clipped to `RoundedRectangle(cornerRadius: 2.5)` so 1★, 2★, and 3★ segments clearly read apart.
6. Light and dark mode, portrait and landscape, Czech and English, and Reduce Motion must work cleanly.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Shared/Theme.swift`, `SmackAPad/Sources/UI/Shared/HardwareSurfaces.swift`, `SmackAPad/Sources/UI/Shared/PadButtons.swift`, `SmackAPad/Sources/UI/Shared/StarsAndProgress.swift`, `SmackAPad/Sources/UI/Practice/DaySummaryView.swift` (lines 25–70, 320–345), `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift` (lines 1320–1380), `SmackAPad/Sources/UI/Practice/TrainingScreen.swift` (button style call sites only).

## Tests

Update unit assertions in `SmackAPadTests/FirstRunAndLegibilityTests.swift` or `MotionTests.swift` only if existing tests check `starColor` or removed button styles; run `-only-testing:SmackAPadTests/FirstRunAndLegibilityTests` and `-only-testing:SmackAPadTests/MotionTests`.

## Acceptance criteria

- [ ] `Theme.Radius.panel` is `8` and `Theme.Radius.button` is `6`; Home controller layout and look are untouched.
- [ ] `TrainingActionButtonStyle`, `ResultPrimaryButtonStyle`, and `ResultSecondaryButtonStyle` are deleted; all buttons use `PadPrimaryButtonStyle` / `PadSecondaryButtonStyle`.
- [ ] `ProgressLine` is `5 pt` tall and visually distinguishes 3★, 2★, and 1★ segments.
- [ ] Typography tokens use `IBM Plex Sans` across inner-screen roles (`26 / 19 / 18 / 16 / 14 / 13`).
- [ ] App builds cleanly and tests pass.

### Manual iPad checks for Jakub

Check Home (must look identical to before), then open Library, Training, Practice result card, and Day summary in light and dark mode: verify crisp 6–8 pt buttons with unified tactile press feel and the thicker 3-shade orange progress bars.

## Agent assignment

Gemini Flash, thinking **low** (mechanical token, button-style, and `ProgressLine` update; all values and call sites are explicitly specified). Fallback: Codex Sol, low. Run first before 231–237.

## Done rule

Build, run tests per `AGENTS.md`, commit on `release-polish`, stop for Jakub's iPad check.
