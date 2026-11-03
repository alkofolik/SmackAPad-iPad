# 49 — Polish: spacing on the 4 pt grid, one height per control, radii from tokens

Status: ready-for-agent. Source: unslop audit, approved by Jakub 2026-11-03.
Blocked by: 47.

## Why

A few values fall off the 4 pt grid (7, 9, 23, 3, 50, 54) and the same kind of control has different heights (50, 54, 60). Practice buttons use radius 7 while the rest of the chrome uses 3.

## Changes

Search by the quoted code; line numbers are not given on purpose.

| File | Find | Replace with |
|---|---|---|
| `PatternField.swift` | `.padding(.horizontal, 24).padding(.bottom, 9)` | `.padding(.horizontal, Theme.Space.page).padding(.bottom, Theme.Space.small)` |
| `PatternField.swift` | the other `.padding(.horizontal, 24)` | `.padding(.horizontal, Theme.Space.page)` |
| `PatternField.swift` | bar marker `CGRect(x: x - 3, y: 12, width: 6, height: 7), cornerRadius: 2` | `CGRect(x: x - 3, y: 12, width: 6, height: 8), cornerRadius: 2` |
| `LibraryScreen.swift` | `difficulty`: `HStack(spacing: 3)` and `.frame(width: 7, height: 7)` | `HStack(spacing: Theme.Space.tight)` and `.frame(width: 8, height: 8)` |
| `StarBurst.swift` | `.padding(.horizontal, 7)` | `.padding(.horizontal, Theme.Space.small)` |
| `PracticeComponents.swift` | `star(_:_:)`: `.frame(width: 23, height: 23)` | `.frame(width: 24, height: 24)` |
| `PracticeComponents.swift` | timing meter `.frame(minHeight: 50)` | `.frame(minHeight: Theme.Size.row)` |
| `PracticeInstruments.swift` | detail icon `.frame(width: 30, height: 30)` | `.frame(width: 32, height: 32)` (keep the outer 56 × 56) |
| `PracticeInstruments.swift` | both practice button styles: `.frame(minHeight: 54)` | `.frame(minHeight: Theme.Size.rowLarge)` |
| `PracticeInstruments.swift` | both practice button styles: `cornerRadius: 7` (3×) | `cornerRadius: Theme.Radius.pad` |
| `PracticeInstruments.swift` | `PracticeNextButtonStyle`: `.padding(.horizontal, 16)` | `.padding(.horizontal, Theme.Space.regular)` |
| `PracticeInstruments.swift` | `PracticeNextButtonStyle`: `lineWidth: 1.5` | `lineWidth: Theme.Size.border` |
| `Components.swift` | `ListRow`: both `.frame(minHeight: 60)` | `.frame(minHeight: Theme.Size.listRow)` |
| `IntroScreen.swift` | Rules button `.frame(minHeight: 48, alignment: .leading)` | `.frame(minHeight: Theme.Size.touch, alignment: .leading)` |
| `PracticeScreen.swift` | hand legend swatches `.frame(width: 12, height: 18)` (2×) | `.frame(width: 12, height: 20)` |
| `PracticeScreen.swift` | band legend swatch `.frame(width: 28, height: 18)` | `.frame(width: 28, height: 20)` |

Controls that use `Theme.Size.blockRadius` get radius 4 automatically from ticket 47; do not edit them.

## Leave as they are (deliberate)

- `LibraryScreen.swift` sidebar rail `.padding(.leading, 7)`: it centres a 2 pt line under the 16 pt chevron.
- `PracticeInstruments.swift` `.padding(.horizontal, Theme.Space.regular - 2)`: it compensates the 2 pt border.
- `HStack(spacing: 2)` between a star icon and its count.
- Everything inside the orange band drawing (`PatternField.swift` radii 6, 7, 12; `PracticeBandStyle`), except the two paddings and the marker above.

## Files to read

`AGENTS.md`, this ticket, `Theme.swift`, and the files in the table.

## Do not

- Do not change colours, fonts, copy or layout structure.

## Acceptance criteria

- [ ] Every row of the table is applied; nothing in "Leave as they are" changed.
- [ ] `grep -nE "minHeight: (50|54|60)\b|cornerRadius: 7\b|height: (7|18|23)\)" SmackAPad/Sources/UI/*.swift` finds nothing outside `PatternField.swift`.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: Practice (buttons, legend, detail icon), Library rows, Intro rules button, star award.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), low thinking.

## Done rule

Stop after a successful build; do not commit.
