# 48 — Polish: one hairline, one active fill, orange only where it means something

Status: ready-for-agent. Source: unslop audit, approved by Jakub 2026-11-03.
Blocked by: 47.

## Why

Orange should carry the score: stars, progress, the next lesson, the primary action. Today it also colours a lock, a filter outline, the word "Active" and selected outlines, so nothing leads. Lines use four opacities (0.2, 0.25, 0.35, 0.4).

## Changes

Use the tokens from ticket 47. Search each string below and replace it exactly as described. Line numbers are hints only; search by text.

### Lines → `Theme.hairline`
| File | Find | Replace with |
|---|---|---|
| `Components.swift` | `FilterChip`: outline `selected ? Theme.orange : Theme.secondary.opacity(0.35)` | `selected ? Theme.ink : Theme.hairline` |
| `Components.swift` | `FilterChip`: `.foregroundStyle(selected ? Theme.orange : Theme.ink)` | `.foregroundStyle(Theme.ink)` (selection is shown by the surface fill and the ink outline) |
| `LibraryScreen.swift` | `Theme.secondary.opacity(0.35)` (sidebar level rail, search field outline) | `Theme.hairline` |
| `LibraryScreen.swift` | `cross.isEmpty ? Theme.secondary.opacity(0.35) : Theme.orange` (filter button) | `cross.isEmpty ? Theme.hairline : Theme.ink` |
| `LibraryScreen.swift` | `Theme.secondary.opacity(0.4)` (clear-filter chip) | `Theme.hairline` |
| `PracticeScreen.swift` | `Theme.ink.opacity(0.2)` (two dividers) | `Theme.hairline` |
| `PracticeComponents.swift` | `Theme.secondary.opacity(0.4)` (the 1 pt centre line of the timing history chart) | `Theme.hairline` |

Keep `Theme.secondary.opacity(0.35)` in `PracticeComponents.swift` (the 4 pt track of the live timing meter is data, not a divider).

### Active fill → `Theme.activeFill`
| File | Find | Replace with |
|---|---|---|
| `CalibrationView.swift` | `Theme.orange.opacity(0.25)` | `Theme.activeFill` |
| `ContentView.swift` | `Theme.orange.opacity(0.3)` (2×, learn slot and active row) | `Theme.activeFill` |

Keep `Theme.orange.opacity(0.12)` in `PracticeComponents.swift` (the good-window band of the timing chart is data, not chrome).

### Orange that does not mean "score"
| File | What | Change |
|---|---|---|
| `LibraryScreen.swift` | purchase lock `Image(systemName: "lock.fill")…foregroundStyle(Theme.orange)` | `foregroundStyle(Theme.secondary)` |
| `SettingsView.swift` | `Text(Theme.sentenceCase(settings.localized("ACTIVE")))…foregroundStyle(Theme.orange)` | `foregroundStyle(Theme.ink)` |
| `LibraryScreen.swift` | `sidebarRow`: `.foregroundStyle(selected ? Theme.orange : Theme.ink)` | `.foregroundStyle(Theme.ink)` — the selected row already has the `Theme.surface` background |

Stars, progress lines, the "Up next" state, the tempo-up banner and the practice band stay orange.

## Files to read

`AGENTS.md`, this ticket, `Theme.swift`, and the files named in the tables.

## Do not

- Do not touch `PatternField.swift` or `PracticeBandStyle` (the orange band is the main visual and stays as it is).
- Do not change layout, fonts or copy.

## Acceptance criteria

- [ ] `grep -n "secondary.opacity(0\.[234]" SmackAPad/Sources/UI/*.swift` finds only the one kept line in `PracticeComponents.swift`.
- [ ] `grep -n "orange.opacity(0\.[23]" SmackAPad/Sources/UI/*.swift` finds nothing.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: Library (sidebar selection, filter, locked lesson) and Settings (active profile) in light and dark.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), low thinking.

## Done rule

Stop after a successful build; do not commit.
