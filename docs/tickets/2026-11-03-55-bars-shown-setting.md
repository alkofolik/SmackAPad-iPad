# 55 — "Bars shown" setting is ignored in static pattern view

Status: ready-for-agent. Source: Jakub's iPad test, 2026-11-03.
Agent: Gemini 3.8 Flash, high thinking.

## Symptom

For lessons longer than one bar, the static pattern view offers 1 bar, 2 bars or all bars per screen (1 bar pages bar by bar, 2 bars page by two, all bars shows everything at once). Whatever Jakub picks, he always sees exactly one bar.

## Likely cause (verify)

`PatternField.swift`, around line 97:

```swift
let count = min(visibleBars, min(lesson.bars, min(4, columns * verticalSlots)))
```

The fit check (`columns` from `PracticeBandStyle.barWidth`, `verticalSlots` from `PracticeBandStyle.minimumHeight`) silently overrides the user's choice. After the recent typography and spacing polish (tickets 38-53), the minimum bar size is probably too large, so `columns * verticalSlots` comes out as 1 on the iPad.

## Required behaviour

1. The user's choice wins: 1 = one bar, 2 = two bars, all = every bar of the lesson (up to 4). Bars scale down to fit the screen instead of being dropped. Notation stays readable; reducing the notation scale is fine.
2. Pick columns and rows sensibly for the iPad in landscape and portrait (e.g. 2 bars side by side in landscape, stacked in portrait).
3. Paging stays as it is: the page changes when the playhead leaves it.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PatternField.swift`, `SmackAPad/Sources/UI/PracticeScreen.swift` (`visibleBars` only, around lines 18, 127 and 711), `SmackAPad/Sources/UI/SettingsView.swift` (the `visibleBars` picker only), and the definition of `PracticeBandStyle`.

## Do not

- Do not touch scoring, timing or the scrolling view.
- No new tests.
- If something fails twice, stop and report.

## Acceptance criteria

- [ ] With a 2-bar lesson, "2 bars" and "all" show both bars; "1 bar" pages bar by bar.
- [ ] With a 4-bar lesson, "2 bars" pages by two and "all" shows all four.
- [ ] Works in landscape and portrait on the iPad.
