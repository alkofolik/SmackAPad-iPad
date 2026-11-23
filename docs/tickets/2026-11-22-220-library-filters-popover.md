# 220 — Library: filters in one pop-up, search as a magnifier

Status: open. From the checklist (2026-11-20, "Library: filters, Play next and overall progress"): Jakub wants the filters designed more economically, e.g. under a pop-up; search only as a magnifier; the filter bar does not fit completely in any orientation or language. Mockup approved on 2026-11-22 ("může být"): design canvas "Smack-a-Pad – návrhy (kolo 22. 11.)", artboard F. **The mockup shows illustrative filters (a "state" row and an "instruments" row) that do not exist in the app; implement only the filters the app already has, listed below.**

## Goal

The Library header never overflows. All filters live behind one button; search is a magnifier icon that opens a text field.

## Rules

1. **Header.** Back arrow, title, overall progress, magnifier button, "Filters" button with a count of active filter groups, as in the mockup. Replace the horizontally scrolling filter strip (`filters(matching:)` in `LibraryScreen.swift`).
2. **Filters pop-up** (SwiftUI popover anchored to the Filters button, adapts to a sheet on narrow widths). Contents, all existing behaviour:
   - the five star filters with counts (`LibraryStarFilter`: 3★, 2★, 1★, In progress, Not started) as chips, same selection logic as now (`settings.libraryStarFilters`);
   - the cross picker: Technique when browsing Genres, Genre otherwise (`cross`);
   - "Clear filters" (small, text) and a "Done" button.
   The count on the button = number of groups that differ from the default (stars not all selected, cross not empty).
3. **Search.** Tapping the magnifier slides a search field in above the list and focuses it; it stays visible while the text is non-empty; an × clears and closes it. Search behaves as now (`query`, ignores "hide completed" while searching).
4. **Everything must fit** in portrait and landscape, in Czech and English, with no horizontal scrolling and no clipped chips (chips wrap to a second line inside the pop-up).
5. Keep the left category column, course progress indicators, "Play next" and star colouring as they are. Do not change catalogue logic or the settings model.
6. No new filters, no new text apart from the "Filters" button label (short in both languages) and what the pop-up needs ("Done"; reuse existing strings where they exist).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/LibraryScreen.swift` (`filters(matching:)`, `hasActiveFilter`, `crossTitle`, header), `SmackAPad/Sources/Progression/LibraryCatalog.swift` (`LibraryStarFilter`), `SmackAPad/Sources/UI/Components.swift` (`FilterChip`), localisation files.

## Acceptance criteria

- [ ] Header never overflows in any orientation or language.
- [ ] All existing filters work from the pop-up; the button shows the active count.
- [ ] Search opens from the magnifier and closes cleanly.
- [ ] Build and tests pass.

### Manual iPad checks for Jakub

Open the Library in portrait and landscape, Czech and English; set several filters, clear them; search for a lesson and close the search.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (layout in several sizes). Fallback: Codex GPT-6.1 Sol, high. Independent of the practice-screen tickets, can run in parallel with them.

## Done rule

Build, run tests per `AGENTS.md`, stop for Jakub's iPad check. Do not commit.
