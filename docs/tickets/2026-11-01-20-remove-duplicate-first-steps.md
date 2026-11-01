# 20 — Remove First steps lessons that duplicate the Intro

Status: ready-for-human (2026-11-01). Prerequisites verified: ticket 19 at `342f9d3`, ticket 21 at `8116fc1`. Stage unlocking is unchanged.

## Goal

Intro (24 lessons) and First steps (`cat == starter`, 9 lessons) teach the same patterns. Decision (Jakub, 2026-11-01, see `docs/design/2026-11-01-feedback-round-2-proposals.md` §4, option A): keep the Intro, remove the duplicates from First steps, and do not lose anyone's saved progress.

## Lessons to remove from `lessons-core.json`

Removed lesson -> Intro lesson that receives its saved progress:

| Remove | Title | Progress goes to |
|---|---|---|
| 1 | Four on the floor | 10001 Kick on every beat |
| 2 | Kick and offbeat hat | 10015 Dance offbeats |
| 3 | Quarter-note hats | 10008 Your first groove |
| 4 | Eighth-note hats | 10010 Hats with a kick anchor |
| 5 | Backbeat | 10011 A complete backbeat |
| 7 | Four on the floor with clap | 10016 Dance with a clap |
| 8 | Backbeat with extra kick | 10013 Extra kick after two |
| 9 | Backbeat, kick on the and of 3 | 10014 Extra kick after three |

**Keep lesson 6 "Open hat on the and"** in First steps (it has no Intro twin). Only these eight entries are removed; the schema of the file stays unchanged (DECISIONS §5). Do not renumber other lessons.

## Progress migration (saved data)

One-time, idempotent migration in the persistence layer, run when progress is loaded:
- For each removed ID that has a saved record, merge it into the target ID: `passed`, `mastery`, `memory` are OR-ed; `bestScore` is the maximum; `currentBpm` of the target is kept unless the target has none.
- Delete the old record afterwards. Running the migration twice changes nothing.
- Never lower anything already earned on the target lesson.

Note for the reader: the twins have the same notes but may differ in hand or velocity, so this is a deliberate, accepted simplification.

## Files to read

`AGENTS.md`, `docs/design/2026-11-01-feedback-round-2-proposals.md` (§4), `SmackAPad/Resources/Data/lessons-core.json`, `SmackAPad/Sources/Persistence/Persistence.swift` (`ProgressStore`, `LessonProgress`), `SmackAPad/Sources/Data/LessonData.swift`, `SmackAPadTests/ProgressionTests.swift`.

## Tasks

1. Remove the eight entries from `lessons-core.json`.
2. Add the migration with the map above (one named constant for the map).
3. Search for places that depend on the old content and fix them: lesson counts (547 before; 539 after) in docs and tests, `SPEC.md` mentions of 8-pad layouts (`hits8`) if any removed lesson was among them, and the test that expects at least 5 lessons in `starter` (`ProgressionTests`). Do not change the unlock rules themselves; tickets 19 and 21 own them.
4. Unit tests for the migration: record on a removed ID moves to the target; flags are OR-ed; an existing target record is never lowered; second run changes nothing; a user without old records is untouched.

## Acceptance criteria

- [x] `lessons-core.json` has 539 lessons; First steps contains only lesson 6.
- [x] A user who had stars on lesson 3 now has the same stars on Intro 10008.
- [x] Build succeeds, tests pass.
- [ ] **iPad check (Jakub)**: First steps looks intentional (one lesson or hidden by ticket 19), Intro shows migrated stars.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), high thinking.
- **Reasoning**: Deletes content and rewrites saved user data; a mistake loses progress. Flash is not recommended.

## Done rule

Stop after successful build and tests. Commit after the task.


## Implementation notes (2026-11-01)

- Removed only IDs 1–5 and 7–9 from the core JSON. The retained lesson objects, IDs, category metadata, and schema are unchanged; starter contains only ID 6. Current totals: 539 core, 587 bundled, 575 Path lessons plus 12 extensions.
- Added the named `ProgressStore.duplicateIntroLessonMap`. On load, retired records merge into their specified Intro targets: earned flags (including played state) are OR-ed, best score takes the maximum, and a positive existing target tempo is retained. Old records are consumed; the merged file is saved atomically. A save failure retains merged progress in memory and leaves the original file intact for retry.
- All six `hits8` lessons remain (IDs 480, 502, 520, 524, 532, 541). Updated current SPEC/DECISIONS counts, data-loader documentation, and affected data/library tests. Historical ticket validation totals remain historical.
- Historical category-rule tests now use synthetic starter fixtures instead of assuming production starter has five lessons. The bundled eight-pad progression fixture uses the current two-star stage rule. No production unlock rules were changed.
- Validation: simulator build and all 5 new `IntroProgressMigrationTests` passed. Previously passing tests were not rerun. Content removal was checked against the original parsed JSON to confirm that only the eight specified entries changed.
- Remaining: Jakub checks the one-lesson First steps presentation and migrated Intro stars on iPad.
