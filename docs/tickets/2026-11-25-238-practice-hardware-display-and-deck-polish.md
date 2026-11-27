# 238 — Practice screen hardware display & unified deck polish

Status: done

## Goal

Visually elevate the practice screen (`PracticeScreen.swift`, `PatternField.swift`, `PracticeInstruments.swift`, `PracticeComponents.swift`) from a flat layout into a recessed hardware instrument without touching timing, MIDI scoring, or adding distracting animations during play.

## Rules

1. **Recessed orange display bezel (`PatternField.swift`).**
   - Wrap the orange pattern field and left drum-icon margin in a dark recessed bezel (`8–10 pt` corners, subtle inner perimeter shadow, and a very subtle vertical light gradient inside the orange surface) so it reads as a backlit hardware display rather than a flat rectangle.
   - Align the left drum icons inside a clean dark sidebar panel directly adjacent to the pattern rows, with crisp light iconography and inactive/active hit dots.
2. **Clearer beat grid and playhead (`PatternField.swift`).**
   - Strengthen vertical guide lines for main beats (`1, 2, 3, 4`) and subtly differentiate 8th/16th subdivisions within the bar.
   - Make the moving playhead more distinct and readable at high tempos (bright core with a subtle dark border/glow).
3. **Tactile note tiles (`PatternField.swift`).**
   - Give note tiles (`HH`, `SN`, `KD`, etc.) a subtle bottom drop shadow and a crisp top edge highlight so they feel like physical elements on the display while preserving maximum black/white hand contrast.
4. **Tidy top toolbar (`PracticeScreen.swift`, `PracticeComponents.swift`).**
   - Unify the right side of the top bar into clean, visually separated groups (practice modes / bar loop & view / tools) with matching tray borders and identical button heights, removing mixed white outlines and bare icons.
5. **Unified bottom hardware deck (`PracticeScreen.swift`, `PracticeInstruments.swift`, `PracticeComponents.swift`).**
   - Combine the bottom third into one cohesive dark hardware panel with three clearly separated sections:
     - Left: 4×4 mini pad grid in a recessed window.
     - Center: "OLED" BPM tempo panel with readable target tempo and direct controls.
     - Right: prominent tactile Start / Restart buttons.
6. **Stability & focus.**
   - No new blinking, text, or distracting elements during playback.
   - Preserve fixed anchoring of the pattern band (no jumping on Start/Stop).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Practice/PracticeScreen.swift`, `SmackAPad/Sources/UI/Practice/PatternField.swift`, `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift`, `SmackAPad/Sources/UI/Practice/PracticeComponents.swift`, `SmackAPad/Sources/UI/Shared/Theme.swift`, `SmackAPad/Sources/UI/Shared/HardwareSurfaces.swift`.

## Tests

Build the app and run the iPad simulator test suite (`xcodebuild test`) to verify zero regressions.

## Acceptance criteria

- [x] Pattern field sits inside a dark recessed bezel (`8–10 pt` corners, inner shadow, subtle vertical light gradient) with a clean dark left sidebar for drum icons.
- [x] Main beat lines (`1–4`) are clearly emphasized, subdivisions are subtly differentiated, and the playhead has a bright core with a dark border/glow.
- [x] Note tiles have a subtle bottom shadow and top highlight while preserving black/white hand contrast.
- [x] Top-right toolbar groups share identical tray borders and button heights.
- [x] Bottom third is a unified dark hardware deck with 3 clear sections (recessed 4×4 pad grid, OLED BPM panel with goal tempo & controls, tactile Start / Restart).
- [x] App builds and iPad simulator tests pass.

### Manual iPad checks for Jakub

Open any lesson on the iPad in landscape and portrait, light and dark mode, and verify:
- The recessed orange display, drum sidebar, beat grid, tactile notes, and playhead at 138 BPM.
- The unified top toolbar groups and bottom hardware deck (Start/Stop/Restart stability, BPM controls, 4×4 pad flashes).

## Agent assignment

Gemini 4 Hydrogen, thinking **medium**.

## Done rule

Build, run tests on the iPad simulator, commit on `release-polish`, and report changed files concisely.
