# 36 — Library: overall progress, star colours, filters, sidebar

Status: ready. Source: Jakub's test 2026-11-02 (feedback round 5). Can run in parallel with ticket 33 (different files).

## Changes

1. **Overall progress** across all lessons of the whole course (stars earned out of the maximum). Merge the lesson count into it: replace the large "57 of 57 lessons" with a smaller text next to this indicator (no hard-coded counts; compute them).
2. **Star colours.** Progress indicators distinguish how many stars were earned: not done grey; 1 star light orange; 2 stars medium orange; 3 stars full orange. Same in the left sidebar for each category and course.
3. **Star rules under an icon.** The requirements for each star are hidden behind an (i) icon on each lesson, in the Intro section and everywhere else, so it is clear what to do for each star.
4. **Filters.** All filter parameters visible without scrolling: use the free space above the course name. Replace "Clear filters" with a small bordered "Clear" button (smaller font) so it looks tappable. Everything tappable must look tappable (border or icon).
5. **Left sidebar.** Visually separate categories from sub-categories (weight, indent, vertical guide line) so they do not blend.

## Rules

- Three colours only plus orange tints; light and dark variants; keep the unified look of ticket 25A.
- Do not change unlock, lock or purchase logic (purchase locks and stage locks stay as they are).
- Texts in `en` and `cs`.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/LibraryScreen.swift`, `Progression/LibraryCatalog.swift`, `Progression/Progression.swift`, `UI/StarRequirement.swift`, `UI/Theme.swift`, localisation catalogs.

## Acceptance criteria

- [x] Overall progress shown; no hard-coded counts.
- [x] Star colours visible in lesson rows and in the sidebar.
- [x] (i) icon opens the star rules for every lesson.
- [x] All filters visible without scrolling in portrait and landscape; Clear works.
- [x] Categories vs sub-categories clearly distinct.
- [x] Both languages; light and dark; build and tests pass.
- [ ] **iPad test (Jakub)**: look at the library with 0, 1, 2 and 3 stars on different lessons.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), **high**. UI-only change, similar to ticket 12 and 25A. If Flash is unavailable, use Codex GPT-6.1 Sol, high.

## Done rule

Stop after successful build; Jakub tests on iPad. Claude commits afterwards.

## Implementation — 2026-11-02

- Computed dynamic overall star progress across all path lessons at the top of the sidebar and in the course header, merging the lesson count into a smaller companion label.
- Added adaptive star colors to `Theme` (0 stars grey, 1 star light orange, 2 stars medium orange, 3 stars full orange) and applied them to `StarsView`, lesson row state symbols, and multi-segment `ProgressLine`s across categories, courses, and overall progress.
- Added dedicated `(i)` button on all lesson rows (standard library views and Intro section) opening the star rules popover.
- Moved filter controls above the course header so all controls fit on one line without scrolling, added borders to tappable elements, and added bordered "Clear" button.
- Visually distinguished sidebar categories from sub-categories using font weight, indentation, and a subtle vertical guide line.
- Added localization strings in `en` and `cs`. Project compiles cleanly.
