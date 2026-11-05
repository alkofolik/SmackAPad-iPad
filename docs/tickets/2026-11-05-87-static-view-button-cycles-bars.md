# 87 — Practice: tapping the static-view button again cycles the number of bars shown

Status: ready. Blocked by: 84 (same file `PatternField.swift`). Source: Jakub, 2026-11-05 (photo 4): "The static pattern button could also work as a switch for how many bars are shown when tapped repeatedly — 1, 2, 3 or all — adapted to each lesson's number of bars."

## Rule

- Toolbar button "Static view" (`PracticeScreen.swift`, `icon("rectangle.split.2x2", …)`):
  - In the scrolling view: tap switches to the static view (as today), bar count unchanged.
  - In the static view: each tap moves to the next bar count: **1 → 2 → … → all bars of the lesson → 1**. "All" = `lesson.bars` (lessons have 1–4 bars). For a 1-bar lesson the tap does nothing more.
  - The stored setting stays `smackapad.practice.visibleBars`; it holds the wish (1, 2, 3 or 4 = all). On a shorter lesson it is clamped to `lesson.bars`, without overwriting the stored value.
- The button shows the current count: a small number next to/inside the icon (e.g. "2"), hidden for 1-bar lessons. Reserved size, so the toolbar does not move.
- `PatternField`: allow 3 visible bars (today `[1, 2, 4]`, and `min(…, 4)`). With 3 shown on a 4-bar lesson the pages are bars 1–3, then bar 4.
- The "Bars shown" pickers (`SettingsView.swift` and the practice tools popover in `PracticeScreen.swift`) offer 1, 2, 3, All and stay in sync with the button.
- VoiceOver: label "Static view", value "2 bars shown" / "Zobrazeny 2 takty", hint "Tap again to show more bars".

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeScreen.swift` (toolbar `icon(…)` calls, `visibleBars`, the "Bars shown" picker), `SmackAPad/Sources/UI/PatternField.swift` (`body`, `count`), `SmackAPad/Sources/UI/SettingsView.swift` ("Bars shown" picker), both `Localizable.strings`.

## Acceptance criteria

- [ ] 4-bar lesson: taps cycle 1, 2, 3, 4, 1. 2-bar lesson: 1, 2, 1. 1-bar lesson: no change.
- [ ] Count is visible on the button; toolbar does not shift.
- [ ] Settings pickers show the same value.
- [ ] Works while a run is playing (no restart of the run).
- [ ] cs and en; landscape and portrait.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: a 3-bar and a 2-bar lesson.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
