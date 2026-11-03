# 38 — Practice screen: bottom must never leave the display

Status: ready. Source: Jakub's iPad test 2026-11-02 (after ticket 34/35 band work).

## Problem

After a run ends, the result card appears in the footer above START/RESTART. The whole practice screen is wrapped in a `ScrollView` with a minimum height for the pattern field, so the content becomes taller than the display and the bottom part (transport buttons) slides off-screen.

## Goal

The practice screen always fits the iPad display, with and without the result card, in every orientation and with 1–4+ pattern rows. Nothing important is reachable only by scrolling.

## Rules

- Remove the outer `ScrollView` in `PracticeScreen.body`; the pattern field is the flexible element and shrinks first (it may go below its current minimum height down to a sensible floor; rows keep their own strips).
- Make the result card compact enough to fit: one tight row (stars, accuracy, Detail icon, next-lesson / from-memory button). Details stay in the Detail popover.
- START / STOP / RESTART stay in the bottom-right corner, never pushed out, same size.
- If the floor is still not enough (very small window, Split View), allow scrolling only as a last resort, never at normal full-screen size.
- No change to colours, band design or typography (typography is ticket 39).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeScreen.swift`, `UI/PracticeInstruments.swift` (`ResultCard`, `PracticeBandStyle.minimumHeight`), `UI/PatternField.swift`.

## Acceptance criteria

- [ ] After a finished run (incl. star earned, with "From memory ★3" and "Next lesson" buttons) the whole screen is visible without scrolling, portrait and landscape.
- [ ] Works with 1, 2, 3, 4 and more pattern rows.
- [ ] Transport buttons stay bottom right before, during and after the run.
- [ ] Build and the existing tests pass.
- [ ] **iPad test (Jakub)**: finish a run in a 1-row and a 4-row lesson; earn a star; check both orientations.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app), **medium**. Layout fix in two files.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
