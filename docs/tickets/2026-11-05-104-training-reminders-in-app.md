# 104 — Training reminders inside the app: lit Training pad, result line, Library due mark

Status: ready-for-human. Depends on: 98. Source: Jakub, 2026-11-05, `docs/2026-11-05-training-push-proposal.md` §3.3 (option A). Mockup: `docs/design/2026-11-05-training-page/training-page.html` (frame 2).

## Goal

Show the player that reviews are waiting in the places they already look, and set the expectation at the moment of success.

## Rules

1. **Lit Training pad (Home pad 3)**: when at least one review is due today, the pad gets an **LED**: a small orange dot in the top right corner (`Theme.orange`, ink outline) and an orange inner edge (4 pt) along the pad border. No due review → the pad looks as today. The due-count subtitle stays (ticket 98). No animation, no pulsing. Accessibility value: "%lld due" / "%lld na řadě".
2. **Result card line after star 2**: when a run earns the goal-tempo star (star 2) **for the first time**, the result card adds one line: "Comes back tomorrow for a review" / "Zítra se vrátí k opakování". Shown only in that run. Not for later runs, not for lessons that already had star 2.
3. **Library due mark**: a lesson row whose review is due today shows a small due symbol next to the stars, in the same symbol style and size as the settled mark (ticket 98 / ticket 52), ink colour, no new colour. Accessibility label "Due for review" / "Na řadě k opakování". A settled lesson never shows it.
4. Light and dark, landscape and portrait, `en` and `cs`.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/HomeScreen.swift` (Training pad, `HomePadView`), `SmackAPad/Sources/UI/PracticeScreen.swift` (result card only), `SmackAPad/Sources/UI/PracticeSession.swift` (where star 2 is first awarded only), `SmackAPad/Sources/UI/LibraryScreen.swift` (row marks only), `SmackAPad/Sources/Persistence/Persistence.swift` (`dueLessonsCount`, `reviewSchedule`), `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Tasks

1. LED state on `HomePadView` (a flag), used by pad 3 only.
2. One-shot result line on first star 2.
3. Library due mark.
4. No new tests; build only.

## Acceptance criteria

- [x] Training pad shows the LED only when something is due.
- [x] First star 2 shows the "comes back tomorrow" line once.
- [x] Due lessons show the mark in Library; settled ones never.
- [x] Build succeeds.
- [ ] **iPad test (Jakub)**: earn star 2 on a new lesson, read the line; next day see the lit pad and the Library mark.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: three small visual additions, no new rules.

## Done rule

Stop after successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
