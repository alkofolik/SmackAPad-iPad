# 132 — Third star not awarded although the run scored 100 %

Status: ready-for-agent. Source: Jakub, 2026-11-07 (iPad): "the third star does not unlock even though I played it at 100 %."

## Problem

A From-memory run with a 100 % score does not give star 3. The player is not told why. Either a rule blocks it (by design but invisible) or there is a bug.

## Read-only review: rules that can legitimately block star 3 (`StarStreak.mayEarnMemoryCredit`, `PracticeSession.swift` ~897–970)

All must hold for one credited run: From memory is on · not a section loop · BPM ≥ lesson **target** BPM (100 % at a lower tempo does not count) · score ≥ 80 % · with "fade notes" on, only **pass 3 or later** of the run counts (passes 1–2 still show notes) · star 2 already earned **and on an earlier calendar day** (ticket 97: same day = "from tomorrow") · enough credited runs (`requiredRuns`, and **in a row** in Challenge mode; a failed run resets the streak) · `isHiddenPass` true.

## Rules

1. **Reproduce with a unit test first** (tdd skill, star rule): for each condition above, one case where a 100 % run is correctly refused and one where it is correctly granted. If any case grants too little or too much, that is the bug: name it and fix it.
2. **Make refusal visible.** After a From-memory run that scored ≥ 80 % but earned no memory credit, the result card must say the exact reason in one short line (en + cs, existing `Localizable.strings` keys style): tempo below goal ("Play at least %lld BPM"), still on pass 1–2 of fade, star 2 earned today ("from tomorrow"), or "n of m runs counted". Reuse the existing line from ticket 97 for the same-day case; do not add a second one.
3. Check the counter shown to the player (`starStreak.memoryRuns` / required) matches what is actually credited.
4. Do not weaken any rule (the day rule, 80 %, target BPM stay). No scoring or timing changes beyond a proven bug.

## Files to read

`AGENTS.md`, this ticket, tickets 97 and 18 (`docs/tickets/2026-11-05-97-memory-star-on-a-later-day.md`, `2026-11-01-18-minimum-runs-per-star.md`), `SmackAPad/Sources/UI/StarStreak.swift`, `StarRequirement.swift`, `PracticeSession.swift` (lines ~890–980, 417–450), `SmackAPad/Sources/Persistence/Persistence.swift` (`LessonProgress`), `SmackAPadTests/MemoryStarRuleTests.swift`, `StarStreakTests.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] Report names the cause (rule that blocked it, or the bug).
- [ ] Tests for each blocking condition, pass; no other new tests.
- [ ] A refused ≥ 80 % From-memory run shows the reason on the result card.
- [ ] Build succeeds.
- [ ] **iPad test (Jakub)**: a lesson with star 2 from an earlier day, From memory at goal BPM, 100 % → star 3; same day → the "from tomorrow" line.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: star rule with several interacting conditions; needs a diagnosis, not a guess.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
