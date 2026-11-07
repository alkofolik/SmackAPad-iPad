# 139 — Practice: fix the back button, quieter result card, no arrow on "Další lekce"

Status: ready-for-human. Type: implementation. Depends on: 136 (button padding). Source: Jakub, 2026-11-07 (Practice screenshots, Rock 1).

## Problems and rules

1. **Back button is broken** (`PracticeScreen.swift` ~229, `Label(... "Library"/"Training"/"Today", systemImage: "square.grid.2x2")`): the grid icon sits outside the left edge of the screen, the word "Knihovna" spills out of the button and overlaps the lesson title "Rock 1". Fix: icon + label inside one button with normal padding (ticket 136), button fully on screen with the screen margin, lesson title starts after the button with ≥ 12 pt gap. Same for "Trénink" and "Dnes" variants.
2. **Result card:** do not show the review line ("Opakování splněno · další za …" — keys `Review passed · next in …`) under the stars. Show it only in the run details (the "3 běhy · nejlepší 95 % ›" sheet). Stars and % stay.
3. **"Další lekce" button:** remove the `arrow.right` icon (~812, ~842). Keep the `lock` icon when the next lesson is locked.

## Acceptance criteria

- [ ] Back button fully visible, never overlaps the title, all three variants, both orientations.
- [x] Review line gone from the card, present in details.
- [x] "Další lekce" has no arrow; locked state still shows the lock.
- [x] Build succeeds. No new tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build. Commit (AGENTS.md); Jakub tests on the iPad.

## Implementation — 2026-11-07

- Enhanced `PadLabelLayout` and `PadControlBody` to support multi-subview labels such as `Label` with icon + title, calculating proper bounds and spacing so icons and titles stay enclosed with 16 pt pad margins.
- Cleaned up `libraryButton` in `PracticeScreen.swift` by removing duplicate inner padding and fixedSize, locking the button to its intrinsic width so it never gets squeezed or overlaps the lesson title (maintaining 16 pt gap).
- Removed review status text from `ResultCard` (card remains focused on score and stars) and added it to the session run details sheet.
- Removed `arrow.right` icon from "Další lekce" / "Next lesson" buttons in both the memory challenge menu and post-run button, preserving the `lock` icon when the next lesson is locked.
- Build verified with Xcode simulator build without errors.
