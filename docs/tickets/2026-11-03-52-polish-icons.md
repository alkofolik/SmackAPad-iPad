# 52 — Polish: one icon style (outline) and one icon size

Status: ready-for-agent. Source: unslop audit, approved by Jakub 2026-11-03.
Blocked by: 48, 51.

## Why

Outline symbols (`lock`, `info.circle`, `magnifyingglass`) sit next to filled ones (`lock.fill`, `…decrease.circle.fill`, `square.grid.4x3.fill`), and one chevron uses its own system font size and bold weight. Filled symbols are only for state that has a filled/empty pair (stars, row state circles, play).

## Changes

| File | Find | Replace with |
|---|---|---|
| `LibraryScreen.swift` | filter button `Image(systemName: cross.isEmpty ? "line.3.horizontal.decrease" : "line.3.horizontal.decrease.circle.fill")` | `Image(systemName: "line.3.horizontal.decrease")` — the active state is already shown by the ink outline from ticket 48 |
| `LibraryScreen.swift` | purchase button `Image(systemName: "lock.fill")` | `Image(systemName: "lock")` |
| `LibraryScreen.swift` | `padRequirement`: `Image(systemName: "square.grid.4x3.fill")` with `.accessibilityLabel(settings.localized("Requires 16 pads"))` | `Text(settings.localized("16 pads"))` with the same accessibility label. A 4 × 3 grid icon does not say "16 pads"; the words do, and the key exists in both languages |
| `PracticeInstruments.swift` | tempo tile chevron `.font(.system(size: 12, weight: .bold))` | `.font(Theme.meta)` |

Keep: `star` / `star.fill`, the row state circles in `LibraryLessonRow.symbol`, `play.fill`, `trash` in red, the custom `PracticeGlyph` and `PracticeDetailIcon` shapes, and `StarBurst` (its 40 pt stars are the award moment).

## Files to read

`AGENTS.md`, this ticket, `LibraryScreen.swift`, `PracticeInstruments.swift` (struct with the tempo tile only).

## Acceptance criteria

- [ ] `grep -n '\.fill"' SmackAPad/Sources/UI/LibraryScreen.swift` lists only stars and row-state symbols.
- [ ] `grep -n 'system(size: 12' SmackAPad/Sources/UI/*.swift` finds nothing.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: Library with an active filter, a purchase-locked lesson, an 8-pad profile showing a 16-pad lesson; Practice tempo tile.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), low thinking.

## Done rule

Stop after a successful build; do not commit.
