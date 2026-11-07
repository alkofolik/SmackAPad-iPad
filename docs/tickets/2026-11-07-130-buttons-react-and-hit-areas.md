# 130 — Buttons react again: hit areas after the satin skin, Library lessons open

Status: ready-for-agent. Source: Jakub, 2026-11-07 (iPad): "after the last graphic change most buttons look broken; in the Library a lesson almost never opens; buttons mostly do not react."

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

- [ ] Cause of B named in the report, with the bisect result.
- [ ] Every button in the list under A: pad and tap area identical, ≥ 44 pt, both orientations.
- [ ] Library: tapping any open lesson row and "Play next" opens the lesson on the first tap.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: Library → open 5 different lessons; press Home/Settings/Show/Play next; Training and Today buttons.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: needs a real diagnosis (input + render cost), then a mechanical sweep.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
