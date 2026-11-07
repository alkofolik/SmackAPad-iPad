# 130 — Buttons react again: hit areas after the satin skin, Library lessons open

Status: ready-for-human. Implementation complete; final build passed; physical-iPad acceptance pending. Source: Jakub, 2026-11-07 (iPad): "after the last graphic change most buttons look broken; in the Library a lesson almost never opens; buttons mostly do not react."

## Problem

After tickets 126–129 (skin "Klidný satén"):
1. Most skinned buttons look misaligned (pad is only as big as the text, padding sits outside the pad).
2. In the Library a lesson (row tap, "Play next") almost never opens; buttons often do not react.

## Findings from the read-only review (verify, do not trust blindly)

**A. Padding and frame sit outside the button style (confirmed in code).** The pattern `Button(...) { Text }.font(..).padding(..).frame(minHeight: ..).buttonStyle(PadSecondaryButtonStyle())` applies the style to the *bare label*; the padding and the 44 pt frame are added *around* the drawn pad. Result: the pad background hugs the text, the 44 pt area is outside the pad, and the real tap area is only the text. Seen at least in: `LibraryScreen.swift` (Settings, Home, Show, Show completed, Play next, Clear filters), `TrainingScreen.swift` (Home, Postpone, Start, Mix Start/New mix, After me Start/Another lesson), `TodaySessionScreen.swift` (Continue and other buttons near lines 120, 291–355), `ContentView.swift` (~96–150), `PurchasesView.swift` (~36–80), `ControllerSetupView.swift`, `CalibrationView.swift`, `IntroScreen.swift`, `AboutScreen.swift`, `BadgesScreen.swift`, `SettingsView.swift`. The correct form (already used in `PracticeComponents.swift` ~281–290 "Again") puts padding and frame **inside** the label closure.
**B. Library lesson does not open — cause NOT yet found.** Row path: `LibraryLessonRow` → `ListRow` → plain `Button` → `onSelect` → `open(_:)` → `selectedLesson` → `lessonPresentation`. Ticket 128 only added `.satinPlate()` (gradient + bevel + two blurred shadows, hit testing off) behind every row and `HardwareLightBar` (infinite breathing animation) on some rows. Candidates, in order: (1) main thread overloaded by ~dozens of rows each with two blur shadows + gradients + running animations inside a `List`, so taps are dropped/late; (2) a layer that now swallows touches (check `allowsHitTesting`, `contentShape`, overlays on the row and on `calmChassisBackground` which is `.drawingGroup` + `ignoresSafeArea` on the whole split view); (3) `open(_:)` returns early (stage not open / not unlocked) and only pulses the banner — check whether the skin changed that visible feedback so it now looks like "nothing happens".
**C. Lesson locked ≠ broken.** Before changing code, tell apart: row is really locked (banner pulse is expected) vs. tap not delivered.

## Rules

1. First **find the real cause of B** with evidence (iPad Pro 11″ simulator, Library): temporary bisect — (a) remove `.satinPlate()` from `LibraryLessonRow`, (b) stop `HardwareLightBar` breathing, (c) remove `calmChassisBackground()` from Library — and note which one restores taps. Remove the temporary changes afterwards. Name the cause in the report.
2. Fix A everywhere: padding/frame inside the label so the pad is the tap area and **the visible pad equals the tap area, min 44 pt**. Every `Pad*ButtonStyle` / `HardwareKeyButtonStyle` usage in `SmackAPad/Sources/UI/` (about 60) must be checked; list the ones changed.
3. If cause B is rendering cost: make rows cheap (one flat fill + hairline, shadow only on large cards, no per-row animation), keep the satin look on large plates. If B is a swallowing layer: fix the layer. Do not remove the skin globally.
4. Visible look stays as close as possible to now (the redesign is ticket 131, later). Only geometry/hit areas and cost change.
5. No changes to scoring, timing, audio, MIDI, navigation logic or texts.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/Components.swift` (styles, `ListRow`, `satinPlate`, `HardwareLightBar`), `LibraryScreen.swift`, `Theme.swift` (`LessonPresentation`, lines ~436–510), then only the files named in finding A.

## Acceptance criteria

- [x] Cause of B named in the report, with the bisect result.
- [ ] Every button in the list under A: pad and tap area identical, ≥ 44 pt, both orientations.
- [ ] Library: tapping any open lesson row and "Play next" opens the lesson on the first tap.
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: Library → open 5 different lessons; press Home/Settings/Show/Play next; Training and Today buttons.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: needs a real diagnosis (input + render cost), then a mechanical sweep.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.


## Implementation report — 2026-11-07

### Diagnosis and temporary bisect

Reproduced an unresponsive part of an **open** lesson card on the iPad Pro 11-inch (M5), iPadOS 27.0 simulator, through Device Hub. In the 2200 × 1600 window screenshot, tapping the first card's unused lower-right area at (1690, 602) left the Library visible; tapping its title at (1460, 520) opened “Kick on every beat”. This is a position-dependent missing hit target, rather than a locked lesson.

| Diagnostic configuration (one change at a time) | Unused card area | Working control |
| --- | --- | --- |
| Original skin | Did not open | Lesson title opened |
| Remove only `LibraryLessonRow.satinPlate()` | Did not open | Play next opened |
| Disable `HardwareLightBar` breathing | Did not open | Lesson title opened |
| Remove only Library `calmChassisBackground()` | Did not open | Lesson title opened |

None of the three removals restored the missing target. Temporary logging at `open(_:)` confirmed `open id=10001 purchased=true open=true` when the title was tapped. The empty area did not invoke the action. The original report's intermittent failures when tapping the title or Play next were not reproduced in this simulator session.

**Cause of the reproduced B symptom:** `ListRow` makes only its leading title/metadata region a primary Button. Its adaptive vertical layout places trailing controls below that Button, and the satin surface encloses both regions plus padding. Blank portions of that visible plate therefore have no action. The skin made the plate look like a larger tappable card without extending its hit target. The diagnostic results do not support removing shadows, lights, or the chassis as the fix.

`LibraryLessonRow` now fills the complete plate's unused area with a plain background Button using the existing `onSelect` action and the plate's rounded hit shape. The existing accessible primary Button and trailing star/info/purchase controls remain siblings, with their own actions. The background target is hidden from accessibility to avoid a duplicate lesson action. Unlocking and lesson presentation logic are unchanged.

All temporary flags, logging, and surface removals were removed. The satin surfaces and breathing behavior are preserved.

### Button audit

Audited all **57** `Pad*ButtonStyle` / `HardwareKeyButtonStyle` applications in `SmackAPad/Sources/UI/`. Moved label sizing/formatting into explicit label closures at 34 sites, and moved the external transport dimensions inside five existing labels: **39 changed call sites** in total. Existing correct labels were retained. The shared `PadControlBody` now guarantees at least the touch-size width and height, draws the background inside those bounds, and applies the same rounded shape to hit testing. Decorative background drawing does not receive touches.

| File | Audited / changed call sites | Changed buttons |
| --- | --- | --- |
| `LibraryScreen.swift` | 7 / 2 | Settings; Play next. Also added the full lesson-plate target. Home, Show, Show completed, Clear filters, and purchase lock already sized their labels correctly. |
| `TrainingScreen.swift` | 7 / 6 | Not today; Start today's training; Mix Start; New mix; After me Start; Another lesson. Home already correct. |
| `TodaySessionScreen.swift` | 5 / 5 | Toolbar Home; Continue; Skip; Done for today; final Home. Touch heights are minimums so taller text can fit. |
| `ContentView.swift` | 4 / 4 | Start again; Start MIDI learn; Cancel; Save. |
| `PurchasesView.swift` | 6 / 4 | Try again; Restore Purchases in both locations; Full unlock. Unlock purchase and Close already correct. |
| `ControllerSetupView.swift` | 6 / 5 | Reconnect MIDI; Done; Learn; Clear; Cancel learning. Connect Bluetooth MIDI already correct; Reconnect MIDI receives its minimum size from the shared style. |
| `CalibrationView.swift` | 2 / 2 | Cancel calibration; Start calibration. |
| `IntroScreen.swift` | 3 / 1 | Close rules. Visibility toggle and Show completed already correct. |
| `AboutScreen.swift` | 1 / 1 | Done. |
| `BadgesScreen.swift` | 1 / 1 | Done. |
| `SettingsView.swift` | 1 / 1 | Done. |
| `PracticeScreen.swift` | 4 / 3 | Playback mode keys; Continue; Next lesson. Library/Today/Training return button already correct. |
| `PracticeComponents.swift` | 8 / 4 | Square transport Again in both layouts; Start/Stop; Restart. Tool icon and the three regular transport labels already correct. |
| `Components.swift` | 2 / 0 | Confirmation-action style inheritance and FilterChip audited; shared style geometry fixed for all applications. |

### Validation and handoff

- Diagnostic simulator build succeeded; no tests added or run.
- Final implementation build succeeded: `xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -configuration Debug -sdk iphonesimulator -destination 'id=9CC875DA-5EDB-4032-94FF-1D802565DBB5' -derivedDataPath .build/ticket130/DerivedData CODE_SIGNING_ALLOWED=NO build` → `BUILD SUCCEEDED`. No tests added or run.
- Stopped implementation after the final successful build, as requested. Post-fix touch behavior, both orientations, and the five-lesson physical-iPad checklist remain for Jakub; the corresponding acceptance boxes are intentionally open.
