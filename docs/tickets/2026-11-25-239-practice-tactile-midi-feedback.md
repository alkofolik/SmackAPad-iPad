# 239 — Practice screen tactile MIDI hit feedback & downbeat pulse

Status: done

## Goal

Add immediate, physically tactile visual feedback for every MIDI hit (and demo playback on the 4×4 mini pad grid) on the practice screen (`PatternField.swift`, `PracticeScreen.swift`, `PracticeInstruments.swift`, `PracticeComponents.swift`, `PracticeSession.swift`) while maintaining smooth 60 fps Canvas rendering, respecting `accessibilityReduceMotion`, and keeping timing, MIDI evaluation, and scoring untouched.

## Rules

1. **Velocity LED meters next to drum icons (`PatternField.swift`, `PracticeInstruments.swift`, `PracticeSession.swift`, `PracticeComponents.swift`).**
   - Propagate MIDI hit `velocity` (`0–127`) through `PadFlash` (`PracticeSession.recordFlash`).
   - Replace the single dot next to each drum icon in `BandMarginRowIndicator` with a clean, minimalist 4-segment LED velocity meter that jumps immediately to the hit's velocity level and smoothly fades over `~200 ms`.
   - Give the drum icon itself a subtle physical press compression (scale down briefly on strike and return smoothly; disabled under `accessibilityReduceMotion`).
2. **Crisp Canvas note-hit pulse (`PatternField.swift`).**
   - On `.correct` hits, draw a short, sharp expanding outline pulse around the note tile (`~160–200 ms`, fading out smoothly) directly in Canvas without obscuring the tile or reducing black/white hand contrast.
   - Preserve existing directional cues for `.early` / `.late` and cross marks for `.wrong`.
   - Disable expanding/scale pulse under `accessibilityReduceMotion` (keep static `.correct` highlight).
3. **Live 4×4 mini pad grid (`PracticeComponents.swift`, `PracticeScreen.swift`).**
   - Light up the struck pad in the bottom-left 4×4 mini-grid immediately on every MIDI controller hit—and also during demo playback (`Listen` and `After me` call phase)—scaled by velocity intensity with a smooth `~150 ms` fade-out at 60 fps without re-rendering the outer `PracticeScreen` tree.
   - Respect `accessibilityReduceMotion` (clean static flash opacity without motion).
4. **Subtle beat-1 downbeat pulse (`PatternField.swift`).**
   - When the playhead crosses beat `1` of a bar, render a subtle visual accent directly on the `1` beat marker/tick (no full-background flashing).
5. **Strict constraints.**
   - No popup text ("PERFECT", "+XP", combo banners) or distracting full-field flashing.
   - Do not modify timing, MIDI judgment, or scoring logic.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Practice/PatternField.swift`, `SmackAPad/Sources/UI/Practice/PracticeScreen.swift`, `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift`, `SmackAPad/Sources/UI/Practice/PracticeComponents.swift`, `SmackAPad/Sources/UI/Practice/PracticeSession.swift`, `SmackAPad/Sources/UI/Practice/PracticeDisplayClock.swift`.

## Tests

Build and run the full test suite on the iPad simulator (`xcodebuild test`) to verify zero regressions.

## Acceptance criteria

- [x] Left drum sidebar shows a 4-LED velocity meter responding to MIDI velocity `0–127` (`~200 ms` fade) and a subtle downward scale press on the drum icon.
- [x] Cleanly hit notes show a crisp expanding outline pulse (`~180 ms`) in Canvas without reducing black/white hand contrast; early/late/wrong markings remain intact.
- [x] Bottom-left 4×4 mini pad grid lights up on MIDI hits and demo playback with velocity-scaled intensity and `~150 ms` fade at 60 fps.
- [x] Beat `1` numeral/tick shows a subtle downbeat accent as the playhead crosses it, with no full-background flashing.
- [x] `accessibilityReduceMotion` disables scale/expanding motion while preserving static highlights.
- [x] App builds and iPad simulator tests pass.

### Manual iPad checks for Jakub

Play a lesson with an external MIDI controller (soft and hard hits) and also run Listen mode to verify:
- 4-LED velocity meter responsiveness and drum icon press feel.
- Expanding ring pulse on clean hits at high BPM (e.g. 138–160+ BPM) without frame drops.
- 4×4 mini pad grid 1:1 lighting on MIDI hits and Listen demo playback.
- Subtle beat-1 downbeat accent and Reduce Motion behavior.

## Agent assignment

Gemini 4 Hydrogen, thinking **high**.

## Done rule

Build, run tests on the iPad simulator, commit on `release-polish`, and report changed files concisely.
