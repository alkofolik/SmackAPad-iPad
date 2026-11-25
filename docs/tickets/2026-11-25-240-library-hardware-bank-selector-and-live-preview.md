# 240 — Library hardware bank selector & live pattern preview

Status: done

## Goal

Refine `LibraryScreen.swift` and `LessonPatternStrip.swift` so the left sidebar reads as a unified hardware bank selector (8pt panels, 1pt hairline dividers without shadows, strong orange active indicator, clear star counts) and every lesson row offers an immediate live audio preview (`▶` / `■`) at `targetBpm` with a smooth 60 fps orange playhead running across its mini pattern strip.

## Rules

1. **Hardware bank selector in the left sidebar (`LibraryScreen.swift`).**
   - Unify the left-column level/chapter/extension groups (`Intro exercises`, `Level 1`–`Level 5`, `Extensions`, and `Genre`/`Technique` groups) into clean hardware bank modules using 8pt panels (`Theme.Radius.panel` / `.instrumentPanel()`), 1pt `Theme.hairline` dividers with no drop shadows.
   - Highlight the active bank with a crisp orange side/edge indicator and active fill, while keeping the earned/max star count and progress bar clearly legible.
2. **Live preview button (`▶` / `■`) in each lesson row (`LibraryScreen.swift`).**
   - Pair a compact tactile play/stop button (`▶` when idle, active orange `■` when playing) with `LessonPatternStrip` in each lesson row.
   - Tapping plays a seamless loop of the lesson's rhythm at `lesson.targetBpm` through `AudioEngine.practice` using the resolved sound kit.
   - At most one row plays at a time; tapping another row switches playback to that row, and tapping the active row stops it.
3. **Running orange playhead over the mini pattern strip (`LessonPatternStrip.swift`).**
   - While a lesson preview is playing, render a crisp orange vertical playhead smoothly sweeping across the 16-step mini grid (wrapping per bar for multi-bar lessons) at 60 fps via `TimelineView`, lightly highlighting the active step column/notes as they sound.
   - Respect `accessibilityReduceMotion` (snap per discrete step without continuous sliding motion).
   - Keep idle rows completely static with zero animation overhead.
4. **Clean row hierarchy and safe audio stop (`LibraryScreen.swift`, `LibraryPatternPreviewPlayer.swift`, `AudioEngine.swift`).**
   - Preserve all existing library features: search, filters, progress indicator, BPM (`current -> target`), 3 stars, info/due/settled marks, and tapping a row to open the lesson.
   - Stop preview playback cleanly whenever opening a lesson, switching banks/views/intro, leaving `LibraryScreen`, or moving the app out of active foreground.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Library/LibraryScreen.swift`, `SmackAPad/Sources/UI/Library/LessonPatternStrip.swift`, `SmackAPad/Sources/Audio/AudioEngine.swift`, `SmackAPad/Sources/Audio/SoundKitResolver.swift`, `SmackAPad/Sources/UI/Shared/ScreenChrome.swift`, `SmackAPad/Sources/UI/Shared/PadButtons.swift`, `SmackAPad/Sources/UI/Shared/Theme.swift`.

## Tests

Build and run the Library/Audio tests and full test suite on the iPad simulator (`xcodebuild test`) to verify zero regressions and add unit coverage for the preview loop scheduling / step timing math.

## Acceptance criteria

- [x] Left sidebar bank groups use 8pt hardware panels, 1pt hairline dividers, no shadows, clear orange active bank indicator, and readable star counts.
- [x] Every lesson row with a pattern strip has a tactile `▶` / `■` button that loops the lesson at `targetBpm` via `AudioEngine.practice` (single active row at a time).
- [x] Playing row's `LessonPatternStrip` shows a smooth 60 fps orange playhead and step highlight synchronized with audio; idle rows have no animation overhead; `accessibilityReduceMotion` disables continuous sliding.
- [x] Search, filters, progress bar, BPM, 3 stars, review marks, and tapping row to open lesson all work unchanged.
- [x] Preview audio stops cleanly on lesson open, bank/view switch, screen exit, and backgrounding.
- [x] App builds and iPad simulator tests pass.

### Manual iPad checks for Jakub

Open Library on iPad and verify:
- Left sidebar banks look like cohesive 8pt hardware modules with crisp 1pt dividers and clear orange active indicator.
- Tapping `▶` on any lesson row plays its groove at target BPM with the orange playhead sweeping across the mini pattern grid.
- Tapping `▶` on another row switches playback immediately; tapping `■` stops it.
- Opening a lesson, switching banks, or going back to Home stops preview audio immediately without overlap.

## Agent assignment

Gemini 4 Hydrogen, thinking **medium**.

## Done rule

Build, run tests on the iPad simulator, commit on `release-polish`, and report changed files concisely.
