# 34 — Practice screen: controls, icons, next lesson, lesson info

Status: implemented; iOS build passed, Jakub's iPad acceptance pending. Source: Jakub's test 2026-11-02 (feedback round 5). Run after ticket 33 (same files).

## Goal

Tidy the controls on the practice screen so that it is clear what belongs together and what each icon does.

## Changes

1. **No wrapping.** Listen, Play and Restart labels must never wrap to two lines, in portrait or landscape. Adjust size or layout.
2. **Icon row.** Group the icons by meaning (for example mode, view, sound) with visible spacing and a subtle separator between groups. Use clearer icons (SF Symbols or custom). No text written out in the row. Each icon has an accessibility label and a long-press hint with its name.
3. **Move to Settings:** the number of bars shown (display setting). **The "from memory" toggle stays on the practice screen**: it earns the 3rd star, so it must not require going to Settings.
4. **Library icon.** Replace the current return icon (it makes no sense) with a clear one (lesson grid or list) and the label "Library".
5. **Next lesson.** After a lesson is completed, show a "Next lesson" button that starts the following lesson according to the "next lesson from" setting. If there is none, or it is locked by purchase, show the matching state or the purchase sheet.
6. **Lesson info panel.** Today it is one block of unseparated text. Split it into blocks with headings (Goal, How to play, Tips, Stars), with spacing and short paragraphs; star rules as their own block.

## Rules

- Three colours only (orange, black, white), light and dark variants. Keep the compact transport sizing (about 72 px high, bottom right).
- Do not change scoring, progression or purchase logic.
- Texts in `en` and `cs`.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md`, `SmackAPad/Sources/UI/PracticeScreen.swift`, `PracticeComponents.swift`, `SettingsView.swift`, `Progression/LibraryCatalog.swift`, localisation catalogs.

## Acceptance criteria

- [ ] No label wraps in any size or orientation of the iPad (check iPad mini and Pro 13").
- [ ] "From memory" is still on the practice screen; bars-shown moved to Settings and persisted.
- [ ] Next-lesson button works, including the locked case.
- [ ] Lesson info is readable in blocks.
- [ ] Both languages; light and dark; build and tests pass.
- [ ] **iPad test (Jakub)**: finish a lesson and press Next lesson; open Lesson info; check the icon row.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, reasoning **high**. UI layout work across a large view.

## Done rule

Stop after successful build; Jakub tests on iPad. Claude commits afterwards.


## Implementation

- Kept Listen / Play labels on one line and localized the compact 380 × 72 pt transport; Restart scales its single-line label when needed.
- Grouped SF Symbols for memory mode, pattern view, and lesson information/tools. Each icon has an accessibility label and a long-press name popover.
- Moved visible-bar selection into Settings and practice tools, retaining the existing persisted preference. From memory remains on the practice screen.
- Added Library navigation and a Next lesson control for passed lessons. It uses the existing progression selector and purchase sheet; switching lessons closes the previous audio/MIDI session first.
- Split lesson information into Goal, How to play, Tips and Stars, preserving finger instructions and existing star requirements.
- Added Czech and English UI strings. Existing unrelated library changes are excluded from this task's commit.

## Validation

- Localization catalogs: `plutil -lint` passed.
- Generic iOS Debug build passed with code signing disabled (Xcode 27.1). The first sandboxed attempt could not launch Swift compiler macros; the second attempt with build permissions succeeded.
- Automated tests were not run or added for this UI-only task, following AGENTS.md. Device acceptance remains open.
- Jakub: check iPad mini / Pro 13-inch in both orientations, both languages and appearances; short taps versus long-press hints; saved bar count; next lesson, purchase and empty states; lesson info blocks.
