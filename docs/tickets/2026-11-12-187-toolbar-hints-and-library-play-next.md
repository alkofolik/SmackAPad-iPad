# 187 — One style of toolbar hints; Library filter row and "Play next" aligned

Status: done (tested on iPad by Jakub and pushed 2026-11-12). Approved by Jakub on 2026-11-12 (iPad check steps 10 and 32).

## A. Toolbar hints (practice screen)

### Problem
A long press on a toolbar button shows a small dark bubble with an arrow (for example "Hra" under the mode button). It looks like a second style on top of the app's own look ("two styles on top of each other"). The short-loop (1 bar) button shows no hint at all.

### Rules
- Use one custom hint style for all toolbar buttons (`practiceToolbarHint` in the practice components): three colours only (orange, black, white), the app font, rounded like the other chips, no system arrow or shadow that clashes.
- Every toolbar button has a hint, including the loop button and the bars-count button (what it does, short, English drum names rule not relevant here). Texts short in both languages, e.g. Listen / Play / After me / From memory; Loop; Bars; Static / Scrolling view; Info; Legend; Help; Settings. Use existing localisation keys where they exist.
- The hint appears above or below the button without covering the pattern band's content more than necessary and disappears when the finger is lifted or after about 2 seconds.
- Do not add visible text to the toolbar itself.

## B. Library: "Play next" on the filter row

### Problem
In the Library the filter chips row and the "Play next" button are in different rows. With English labels the chip row is wider and runs into the button's column ("Not started (53)" ends above "Play next"); in Czech it only looks fine because the labels are shorter.

### Rules
- Put "Play next" at the right end of the filter row, same height as the chips, and let the chips use the remaining width (scroll or wrap) so they never overlap the button, in both languages, landscape and portrait.
- The level heading with the progress ("53 of 57 lessons") stays in its own row below.
- Same behaviour as now (opens the next lesson; disabled when there is none).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (`practiceToolbarHint`, the toolbar popovers), `PracticeComponents.swift`, `LibraryScreen.swift` (`filters(matching:)`, `playNextButton`), localisation files.

## Acceptance criteria

- [ ] Long press on any practice toolbar button shows a hint in the app's style; the loop button has one.
- [ ] Library: "Play next" sits on the filter row, nothing overlaps in CS/EN, landscape/portrait.
- [ ] Build and full test suite pass; localisation validation passes.

### Manual iPad checks for Jakub

Lesson: long-press every toolbar button. Library in Czech and English, landscape and portrait: the filter row and "Play next" are one line without overlap.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
