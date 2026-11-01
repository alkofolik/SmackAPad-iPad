# 23 — Make it clear how to earn the third star

Status: ready-for-agent (2026-11-01). **Start only after tickets 18, 21 and 22 are finished and committed** (touches the practice screen and the Library row).

## Goal

Nothing in the app tells the student how to earn star 3. Tell him where he decides, in one plain line, without a manual.

## The three stars (texts)

1. "Pass the lesson" (score high enough, N times in a row when ticket 18 requires several runs).
2. "Reach the goal tempo cleanly".
3. "Play it from memory at goal tempo, 80 % or better" (turn on From memory, the pattern is hidden).

When `requiredRuns > 1` (ticket 18) add "N times in a row" to the line.

## Where to show it

1. **Result screen** (mockup `docs/design/mockups/A · Konec cvičení (hvězdy)@2x.png`): under the stars, one line for the **next missing star**, e.g. "Next: play it from memory at 85 BPM, 80 % or better". Nothing when all three are earned.
2. **Practice screen**: after star 2 is earned, a quiet one-time hint (per lesson) pointing at the From memory control. No popup that blocks playing.
3. **Library row**: tapping the stars opens a small popover with the three lines above, earned ones marked by shape/icon (no new colours).

Three colours only (orange, black, white); state by icon and shape. Touch targets at least 44 pt. Texts via the localisation catalogs (`en` and `cs`).

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md` (§8 Stars), `docs/design/2026-11-01-star-feedback.md`, `SmackAPad/Sources/UI/StarAward.swift`, `PracticeScreen.swift`, `PracticeComponents.swift`, `LibraryScreen.swift` (stars view, around `isPassed`), `docs/tickets/2026-11-01-18-minimum-runs-per-star.md`.

## Tasks

1. One shared helper that returns the text of the next missing star from the saved progress and `requiredRuns` (testable).
2. Use it in the three places above.
3. Texts and keys in `en` and `cs`.
4. Unit test for the helper (no star, one, two, three stars; with and without several required runs).

## Acceptance criteria

- [ ] A student who has 2 stars sees how to get the third one on the result screen and in the Library.
- [ ] The hint on the practice screen appears once and does not interrupt playing.
- [ ] Build succeeds, tests pass.
- [ ] **iPad check (Jakub)**: the wording is understandable without explanation.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity).
- **Reasoning**: Mostly text and small views on top of finished logic; the rules themselves come from tickets 18 and 21.

## Done rule

Stop after successful build and tests. Commit after the task.
