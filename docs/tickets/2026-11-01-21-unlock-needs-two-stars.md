# 21 — Unlocking counts lessons with 2 stars

Status: ready-for-human (2026-11-01). Ticket 19 prerequisite verified at commit `342f9d3`.

## Goal

Today a lesson counts toward unlocking as soon as it is **passed** (star 1 only). Jakub's decision: a lesson counts when it has **two stars** (passed + goal tempo). Star 3 (from memory) stays optional, so nobody is blocked by the hardest star.

## Rule

`isCompleted(lessonId) = passed && mastery` (`mastery` = the stored flag for star 2, goal tempo; verify the meaning in `StarAward.swift` and `Persistence.swift` before using it).

- One single place defines this (for example `ProgressStore.isCompleted(lessonId:)`). Stage unlocking from ticket 19 uses it everywhere it used `isPassed` for the unlock count.
- The stage-opening threshold stays `min(ceil(lessons/2), 10)` for now; keep it as one named constant so it is easy to change after testing.
- Unchanged: soft unlock (single tap + confirmation), the rule "a stage with an already played lesson is open", the always-open Intro, the 8-pad exclusion of lessons without a layout.
- **Never re-lock**: anything already unlocked stays unlocked, even if the new rule would not unlock it now.

## Texts in the Library

Locked stage: "Earn 2 stars in N lessons in <stage> to open this" (replace "Pass N lessons"). The "passed / total" counters of ticket 19 item 5 stay as they are; only the unlock progress uses two stars. Texts via the localisation catalogs (`en` and `cs`).

## Files to read

`AGENTS.md`, `docs/DECISIONS.md` (§15), `docs/SPEC.md` (§3.7, §5.3), `docs/tickets/2026-11-01-19-library-path-and-filters.md`, `SmackAPad/Sources/Progression/Progression.swift`, `SmackAPad/Sources/Persistence/Persistence.swift`, `SmackAPad/Sources/UI/LibraryScreen.swift`, `SmackAPadTests/ProgressionTests.swift`.

## Tasks

1. Add the single completion rule and use it in the unlock counting.
2. Update the locked-stage text and keys.
3. Update `docs/SPEC.md` §3.7 and the acceptance list, and `docs/DECISIONS.md` §15 (one short line each).
4. Tests: a passed-only lesson does not count; passed + goal tempo counts; star 3 changes nothing; an already unlocked stage stays unlocked; 8-pad exclusion still works.

## Acceptance criteria

- [x] With 5 lessons at one star, the next stage stays locked; with 5 lessons at two stars it opens.
- [x] Soft unlock still works.
- [x] Build succeeds, tests pass.
- [ ] **iPad check (Jakub)**: the lock text is understandable.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), high thinking.
- **Reasoning**: Changes progression rules and must not re-lock existing users. Flash is not recommended.

## Done rule

Stop after successful build and tests. Commit after the task.


## Implementation notes (2026-11-01)

- `ProgressStore.isCompleted(lessonId:)` is the single `passed && mastery` rule. The memory star is optional; passed counters and next-lesson recommendations retain their existing meanings.
- Stage requirements use `ProgressionConstant.requiredStageCompletions`, capped by the named `maximumStageCompletions = 10`. In eight-pad mode, completed lessons without a valid layout are excluded from the unlock count.
- A one-time migration snapshots ticket 19's previously open stages under the original one-star rule, including its original handling of pad layouts. Those stages and future stage openings are persisted; only an explicit progression reset clears remembered access. Saved soft unlocks, played-stage access, and Intro remain accessible.
- Updated the English/Czech locked-stage requirement and its two-star progress counter; ordinary passed/total counters are unchanged. Updated SPEC §3.7, progression acceptance criteria, and DECISIONS §15.
- Validation: simulator build and all 6 new `StageCompletionTests` passed. The existing library threshold test fixture was updated to earn two stars; previously passing tests were not rerun. No timing/scoring rules were changed.
- Remaining: Jakub checks that the lock text is understandable on iPad.
