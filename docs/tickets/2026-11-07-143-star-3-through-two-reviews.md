# 143 — Star 3 is earned by two passed reviews in Training

Status: ready-for-human. Blocked by: 142. Source: Jakub, 2026-11-07, chose option B in `docs/2026-11-07-training-stop-star-list-badges-proposal.md` §2.

## Goal

Star 3 means "it holds in the hands": the lesson passed two reviews on different days (first review day + 1, second 3 days later, ticket 98 gaps). Practice no longer awards star 3; From memory stays there as a practice tool. One system instead of two.

## Rules

1. **Award.** When a review outcome (ticket 142) is `passed` and the lesson has now passed **two reviews in total** (`reviewStep` reaches ≥ 2 after the pass; passes after a failed review still count), star 3 is awarded in that run: fresh star → `StarEvent`, animation, badge evaluation, the ticket 142 success stop (one stop only).
2. **Practice.** `StarStreak.mayEarnMemoryCredit` no longer grants star 3 outside a review. From memory still works and is scored; it just earns no star.
3. **Requirement line** (`StarRequirement`) for star 3: "Star 3: two reviews in Training · %lld of 2" / "Třetí hvězda: dvě opakování v Tréninku · %lld ze 2". Shown in Practice and on the result card instead of the old memory counter.
4. **Remove** the same-day rule texts of tickets 97 and 132 ("from tomorrow", "Star 3: from tomorrow.") and their display paths. Keep `masteryDay` (the schedule needs it).
5. **Existing data.** Already earned stars 3 stay. Lessons with `reviewStep ≥ 2` or `settled` but no star 3 get it silently at launch (no banner, like `awardSilently` for badges).
6. **Settled mark.** A lesson with `settled == true` shows the existing small settled mark next to its stars (Library rows already have it; also add it next to the stars on the Practice header if not there). No new colour.
7. Unchanged: stars 1 and 2, stage unlock (star 2), review gaps, Mix and After me rules, memory badges (`metric memory` counts stars 3).

## Files to read

`AGENTS.md`, this ticket, ticket 142, `SmackAPad/Sources/UI/StarStreak.swift`, `SmackAPad/Sources/UI/StarAward.swift`, `SmackAPad/Sources/UI/StarRequirement.swift`, `SmackAPad/Sources/UI/PracticeSession.swift` (memory credit and review evaluation ~895–990), `SmackAPad/Sources/UI/PracticeScreen.swift` (requirement line, result card, header stars), `SmackAPad/Sources/Persistence/Persistence.swift` (`LessonProgress`, `recordResult`), `SmackAPad/Sources/App/SmackAPadApp.swift` (launch migration), both `Localizable.strings`.

## Tasks

1. **Use the tdd skill** (star rule). Pure function: review outcome + progress → may this run earn star 3?
2. Remove star 3 from Practice; award it in the review path.
3. Requirement texts, removal of the "from tomorrow" texts, settled mark.
4. Launch migration (rule 5).
5. Tests (only these): second passed review → star 3; first passed review → no star 3; pass, fail, pass → star 3 on the second pass; From memory run in Practice (not a due review) → no star 3; migration gives star 3 to `reviewStep 2` without star 3.

## Acceptance criteria

- [x] From memory in Practice never gives star 3; the line says how to get it.
- [x] Second passed review gives star 3 with animation and stop.
- [x] Old stars 3 stay; old lessons with two passed reviews get star 3 silently.
- [x] No "from tomorrow" text anywhere.
- [x] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: over several days earn star 3 through two reviews.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: a star rule change plus a small migration; tests pin it down.

## Done rule

Stop after successful build and tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Implementation — 2026-11-07

- Added pure `ReviewScheduler.mayEarnStar3` function deciding when a review outcome awards star 3 (`reviewStep >= 2` or `settled`).
- Awarded star 3 in review success stop path with `StarEvent`, animation, badge evaluation and stop.
- Practice `StarStreak.mayEarnMemoryCredit` now returns `false`; From memory in practice never awards star 3.
- Requirement line (`StarRequirement`) updated to show "Star 3: two reviews in Training · %lld of 2" in English and Czech.
- Removed all "from tomorrow" texts, `isMemoryPracticeToday`, and `showsMemoryChallenge` shortcut for star 3.
- Settled mark checkmark added next to header stars in Practice and ResultCard.
- Silent launch migration `ProgressStore.migrateTwoReviewsStar3` for lessons with `reviewStep >= 2` or `settled == true` without star 3.
- Tests in `Star3ReviewTests` for all 5 scenarios passed. Build succeeded.
