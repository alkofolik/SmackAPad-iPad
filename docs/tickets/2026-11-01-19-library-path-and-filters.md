# 19 — Library: Path / Genres / Techniques views, filters and stage unlocking

Status: ready-for-human (2026-11-01). Ticket 15 prerequisite verified at commit `b3a2f9c`; working tree was clean before this task.

## Goal

Make the iPad library work exactly like the legacy app's library (same system, new look): three ways to organise the same lessons, cross filters, star filters and stage-based unlocking.

## Source of truth (legacy, read-only)

`~/AI COWORK/Smack-a-Pad/Smack-a-Pad/2026-10-28-Smack-a-Pad-ipad/app/v21/src/`
- `engine/path.js` — `LESSON_TECHNIQUES`, `GENRE_GROUPS`, `lessonTechnique`, `lessonGenreGroup`, `orderStageLessons`, `PATH_STAGES`, `stageUnlockProgress`, `stageOpen`, `nextLesson`
- `ui/library-model.js` — views, star filter states, grouping, matching
- `ui/library.js` — sidebar, filters bar, lesson rows

If the agent cannot reach the legacy folder, Jakub pastes the files. Do not guess the rules.

## Files to read

`AGENTS.md`, `docs/DECISIONS.md` (§15 Progression), `docs/design/2026-10-30-practice-screen-spec.md` §10 (colours), `SmackAPad/Sources/UI/LibraryScreen.swift`, `SmackAPad/Sources/Progression/Progression.swift`, `SmackAPad/Sources/Data/LessonData.swift`.

## Behaviour to port

1. **Organise by** switch in the sidebar: **Path / Genres / Techniques**. The same lessons, different grouping; the choice is remembered.
2. **Techniques** (5): basic groove, sixteenths, ghost notes, swing & shuffle, fills & toms. Rule per lesson: `toms` tag or `cat == fills` → fills; `triplet feel` tag or `division == 12` → swing; `ghost notes` tag → ghost; `16ths` tag → sixteenths; otherwise groove.
3. **Genre groups**: Rock & punk, Funk/soul/blues, Jazz & New Orleans, Hip hop & trap, Latin & world, Pop & country, everything else = Electronic (use the legacy genre lists exactly).
4. **Path**: 5 levels; each level is split into stages by technique (levels 1–3: groove, sixteenths, ghost, swing, fills; levels 4–5 without groove). Levels collapse/expand in the sidebar; a stage with no lessons is omitted. Inside a stage: intro/starter lessons first, then genres taken in turn (round-robin), as in `orderStageLessons`. Jersey club and Footwork lessons are **extensions**: shown as an extra group outside the Path.
5. Each sidebar group shows "passed / total" and a thin progress bar (full stars vs. partly starred).
6. **Filters above the list**: search (title and genre), a cross filter (in Genres view: by technique; in the other views: by genre), star toggles **3★ / 2★ / 1★ / in progress / not started** each with a count (multi-select, remembered), a "X of Y lessons" counter and "Clear filters".
7. **Lesson row**: state icon, number in the group, title, genre (or technique in Genres view), level as 5 dots, bars, current tempo, stars.
8. **Unlocking**: the old category unlocking is replaced by **stage unlocking**. A stage opens when the previous stage in the Path has at least `min(ceil(lessons/2), 10)` lessons passed, or when any of its lessons was already played. The existing "soft unlock" (single tap + confirmation) stays: it unlocks a stage. Locked stages show a lock and the text "Pass N lessons in <stage>". Genres and Techniques views never block a lesson that is open in the Path. Migrate saved category unlocks so no earlier progress is lost.
9. Intro section stays a separate always-accessible entry point (unchanged).
10. Optional setting (Settings screen): **"Next lesson from"** = Path / Genre / Technique / All (easiest first). It drives the "Play next" button as in `nextLesson`.

## Design

Three colours only (orange, black, white), light and dark variants, no status colours: states are told apart by icon and shape (filled circle, half, empty, lock, play), not colour. Touch targets at least 44 pt. Use `Theme.swift` tokens. English is the default language; all texts via the localisation catalogs introduced by ticket 15 (add keys to both `en` and `cs`).

## Acceptance criteria

- [x] Three views switch instantly and the choice is remembered.
- [x] Path shows levels and stages as in the legacy app; counts match the legacy app for the same progress.
- [x] Search, cross filter and star filters combine; counts and "Clear filters" work.
- [x] Stage unlocking follows the rule above; soft unlock still works; old unlocks are migrated.
- [x] Unit tests for technique/genre classification, stage ordering and stage unlock rule.
- [x] Build succeeds.
- [ ] **iPad test (Jakub)**: landscape and portrait, light and dark, both languages.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), high thinking.
- **Reasoning**: Changes the unlocking and progression logic and needs a faithful port of rules from JavaScript; Flash is not recommended.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task.


## Implementation notes (2026-11-01)

- Legacy reference reading of the three named JavaScript files was explicitly authorised by Jakub for this ticket. Rules were reimplemented in Swift; legacy source was not copied or changed.
- Added a shared immutable catalogue projection, persisted view/star preferences, stage access and one-time category access migration, both localisation catalogs, and the optional next-source setting with Play next.
- Intro remains a separate entry point and also retains its original catalogue position in the Path, matching the legacy population (583 Path lessons plus 12 extensions).
- Added a persisted played flag; legacy progress without that flag conservatively preserves access. New tempo-only changes do not count as playing.
- Validation: simulator build succeeded. All 9 new LibraryCatalogTests passed: 8 on the initial run; the next-lesson test passed after correcting its expected legacy wraparound order and rerunning only that test. Existing passing tests were not rerun. All three views contain the same 595 unique bundled lesson IDs (583 Path + 12 extensions), with 23 non-empty stages.
- Manual UI acceptance remains pending on Jakub’s iPad: landscape/portrait, light/dark, English/Czech. No browser scripts or hardware tests were run.
