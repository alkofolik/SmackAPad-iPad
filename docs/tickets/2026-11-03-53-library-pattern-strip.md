# 53 — Library: a small step strip of each lesson's real pattern

Status: ready-for-agent. Source: unslop audit (the product's signature detail), approved by Jakub 2026-11-03.
Blocked by: 49, 50, 52.

## Why

The Library is clean but could belong to any list app. The one detail only this product has is the **sequencer step cell**: a row of 16 small cells, like the step buttons of a drum machine. Each lesson row shows its own first bar as such a strip, so you can see the groove before you open it.

## Rules

1. New view `LessonPatternStrip` in a new file `SmackAPad/Sources/UI/LessonPatternStrip.swift`:
   - Input: `hits: [LessonHit]` (use `lesson.hits`).
   - Shows **the first bar only**: steps `0..<16`.
   - Rows: the distinct `padIndex` values that occur in the first bar, ordered by how often they occur (most first), **at most 3 rows**. Hits on other pads are ignored.
   - Cell: 6 × 6 pt, corner radius 1, gap 2 pt between cells and rows. One extra 2 pt gap before steps 4, 8 and 12 so the four beats read as groups. Total width = 16·6 + 15·2 + 3·2 = 132 pt. Height for 3 rows = 22 pt.
   - Colours: a hit cell is `Theme.ink`; an empty cell is `Theme.hairline`. **No orange** (orange carries the score). No hand colours.
   - Draw it with a single `Canvas` (not 48 separate views).
   - `.accessibilityHidden(true)`: the row's title already describes the lesson.
2. In `LibraryLessonRow` (`LibraryScreen.swift`), in the `trailing:` block, put the strip **before** `StarsView`, vertically centred, with `Theme.Space.regular` between them.
   - Hide it when the row is narrow: wrap the trailing content in `ViewThatFits(in: .horizontal)` with a first option that includes the strip and a second without it.
   - Hide it for intro rows (`introGoal != nil`).
   - Dimmed rows (`locked`) draw the hit cells in `Theme.secondary` instead of `Theme.ink`.
3. No new strings, no settings toggle.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Data/LessonData.swift` (`LessonHit`, `Lesson` only), `SmackAPad/Sources/UI/LibraryScreen.swift` (`LibraryLessonRow` only), `SmackAPad/Sources/UI/Theme.swift`. If the new file has to be added to `SmackAPad.xcodeproj/project.pbxproj`, add it the same way as the other UI files.

## Do not

- Do not change `ListRow`, `StarsView` or any other screen.
- Do not use orange, gradients, shadows or animation in the strip.

## Acceptance criteria

- [ ] Each standard lesson row shows a 3-row × 16-step strip of its first bar; intro rows do not.
- [ ] A one-pad lesson shows one row; the strip never shows more than 3 rows.
- [ ] Locked lessons show a grey strip.
- [ ] Scrolling the Library stays smooth on the iPad.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: Library in landscape and portrait, light and dark. Decide whether the strip stays.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), **medium** thinking — one new view with drawing logic. Alternative: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after a successful build; do not commit.
