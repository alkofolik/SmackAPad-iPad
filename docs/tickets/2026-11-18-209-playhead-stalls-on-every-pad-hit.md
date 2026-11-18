# 209 — Playhead stalls on every pad hit

Status: done. Reported by Jakub on 2026-11-18: "the playhead still does not move smoothly during practice; this time it stalls every time I hit a pad. It is unusable."

Follows ticket 208 (display-link sampling) and commit 4b73d73 (Home no longer re-renders on each hit). Both removed other causes; this one is still there.

## Cause found in the code

Every pad hit writes `PracticeSession.padFlashes` (in `receive(_:)` and `record(_:pass:padIndex:)`). That dictionary is read directly in `PracticeScreen.body`:

- `bottomZone(...)` → `PracticeTouchPadGrid(flashes: session.padFlashes, ...)` (`PracticeScreen.swift` ~line 884)
- `padLayoutSquare(s:)` → `PracticePadLayoutSquare(flashes: session.padFlashes, ...)` (~line 1221)

Both helpers are called from the main `body` (not from a leaf view), so Observation registers `padFlashes` as a dependency of the whole practice screen. Each hit therefore rebuilds the entire practice screen (geometry readers, toolbar, HUD, band container, pads) on the main thread, at the very moment the display link needs to draw the next frame. That is the visible stall.

Smaller, same family: `padFlashes` never becomes empty after the first hit, so the `TimelineView(.animation(minimumInterval: 1/30, paused: flashes.isEmpty))` inside both pad views keeps ticking for the rest of the screen's life.

## Goal

Hitting pads (MIDI or touch) during practice causes no visible hitch in the playhead or tape, on 60 Hz and 120 Hz iPads.

## Rules

1. Per-hit state must be observed only by small leaf views. `PracticeScreen.body` and its helper functions must not read `session.padFlashes`. Pass the `session` (or a tiny wrapper) into `PracticePadLayoutSquare` / `PracticeTouchPadGrid` and read `padFlashes` inside their own `body`, so a hit rebuilds only the pads.
2. Check the same for every other value a hit changes: `padFlashes`, `playedHits`, `judgmentVersion` / `hitJudgments`, `timingHistory`, and the MIDI input's `lastNote`, `lastPad`, `pressedPadIndices`, `pressedPadVelocities`, `noteOnCount`. Each may be read only inside a leaf view or inside a `PracticeDisplayFrame` closure, never in `PracticeScreen.body`, `TrainingScreen.body` or any other screen that is mounted during practice. Fix any other place you find the same way.
3. Pause the pad flash animation when no flash is still fading (expire old flashes, or pause based on "any flash younger than its fade time"), so the 30 Hz timeline does not run forever.
4. Do not change scoring, audio schedule, calibration, the flash colours or how long a flash is shown.
5. Do not touch the display-link sampling from ticket 208.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (search: `padFlashes`, `bottomZone`, `padLayoutSquare`, `var body`), `SmackAPad/Sources/UI/PracticeComponents.swift` (`PracticePadLayoutSquare`, `PracticeTouchPadGrid`), `SmackAPad/Sources/UI/PracticeSession.swift` (search: `padFlashes`, `PadFlash`, `func receive`). Use `grep` for the MIDI property names in `SmackAPad/Sources/UI/` (rule 2); open only files that hit.

## Tests

No new tests (view observation change only). Build, run the practice-area tests with `-only-testing`, and the full suite once before the commit.

## Acceptance criteria

- [x] No `session.padFlashes` (or other per-hit value from rule 2) read in `PracticeScreen.body` or its helper functions.
- [x] Pad flashes still light up with the same colours and fade as before.
- [x] Pad flash timeline pauses when no flash is fading.
- [x] Build and tests pass.

### Manual iPad checks for Jakub

- Play a 4-bar lesson for two minutes, hitting pads fast (e.g. 16ths on hi-hat): the playhead never stutters at a hit.
- Same with the on-screen touch pads in portrait.
- Pads still flash green / orange / red as before.

## Agent assignment

Gemini 3.8 Flash, thinking **medium** (focused SwiftUI observation fix, cause already located). Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run tests per `AGENTS.md`, commit, stop for Jakub's iPad check.
