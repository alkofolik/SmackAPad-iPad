# 255 — URGENT: Story availability makes the whole app slow (clicks take seconds)

Status: open · highest priority, before any other story work

## Problem (Jakub, 2026-11-27)

Since the story tickets (247–252) every tap in the app reacts after several seconds. Behaviour is otherwise unchanged; the slowness is the only visible difference.

## Cause found by reading the code (not yet measured — see rule 1)

`Progression.isLessonOpen(_:)` (`SmackAPad/Sources/Progression/Progression.swift`, ~line 572–590) calls `DrummerPathMapBuilder.isOpenInStory(...)` (`DrummerPathMapModel.swift`, ~line 295), which calls `buildStages(...)`: it rebuilds **all 23 stages / ~550 lessons** of the story map and then searches the result for one lesson. It is called **once per lesson** and on every redraw from:

- `UI/Library/LibraryScreen.swift` ~lines 864 and 1230 (one call per row → hundreds of full map builds per redraw),
- `UI/Home/HomeScreen.swift` ~lines 426–431,
- `UI/Practice/TrainingScreen.swift` ~lines 638, 1154–1208 (also reached through the "Today" pad),
- `UI/Practice/PracticeScreen.swift` ~lines 1807, 1824,
- `Progression.swift` itself: `nextLesson(...)` and `dailyLessons(...)` loop over lessons and call `isLessonOpen` per lesson.

Each build also copies `progressStore.records` and `drummerPath`. Result: roughly (number of lessons asked) × (full map build) per redraw.

## Rules

1. **Measure first.** Before changing anything, add a test (or a temporary counter) that records how many times `buildStages` runs when `isLessonOpen` is asked for every lesson of the catalog on a profile with realistic progress. Report the number before and after in the final report. The app already has `TrainingOpenMeasurement` for open timing — reuse it if it helps.
2. **Compute once, read many.** Calculate the set of open lesson IDs for Story mode **once** and keep it (for example in `Progression`, outside the Observation tracking so reading it does not itself cause redraws). `isLessonOpen(lesson)` and `isOpenInStory(lesson)` then only do a set lookup (Free practice stays `true`, Intro stays open).
3. **Invalidation must be O(1), not a rescan.** Recompute only when one of the inputs changes: lesson progress (stars/records), drummer path state (completed exams), remembered/soft-unlocked open stages, the fork route choices, play mode, or the catalog. Use a change counter or an explicit "invalidate" call from the places that change those inputs; do **not** hash or compare all records on every `isLessonOpen` call, that would just move the same cost.
4. **Correctness must not change.** The set must be identical to what the current per-lesson function returns for every lesson, in both modes, on a fresh profile, a mid-progress profile and a full profile. Add a test that compares the cached answer to the old uncached computation (keep the old builder function as the reference used only by the test).
5. **Other hot spots:** while there, check the other direct callers of `buildStages` (`TrainingScreen.swift` ~1221, `StoryRouteChoices.swift` ~72) and make sure one screen redraw builds the stage models at most once (reuse one result for the whole redraw); do not redesign anything else.
6. Do not touch audio/MIDI timing, scoring, or the look of any screen.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Progression/Progression.swift`, `SmackAPad/Sources/Progression/DrummerPathMapModel.swift`, `SmackAPad/Sources/Progression/StoryRouteChoices.swift`, `SmackAPad/Sources/Persistence/ProgressStore.swift`, and the call sites listed above.

## Tests

- Count test (rule 1): asking `isLessonOpen` for all ~550 lessons triggers at most one `buildStages`.
- Equality test (rule 4) on fresh, mid and full profiles, Story and Free mode.
- Invalidation tests: after a lesson gets ★1/★2, after a stage exam is passed, after a fork route is chosen, after switching play mode, the answer is correct immediately (no stale cache).
Run the narrow tests while working, the full `SmackAPadTests` suite once at the end.

## Acceptance criteria

- [ ] Number of `buildStages` runs per full lesson scan: before → after reported (target: 1).
- [ ] Cached answers equal the old function for all lessons in all test profiles.
- [ ] No stale answer after any of the invalidating events.
- [ ] Builds and `SmackAPadTests` passes on the iPad simulator.

### Manual iPad checks for Jakub (no good playing needed)

- Install a fresh build (delete the old app first so no old build stays): open **Dnes**, **Knihovna**, **Pokračovat**, **Intro** and tap around — each tap reacts at once.
- Library: scroll the long list, open a stage filter — no freezing.
- Switch Story / Free practice in Settings and back: the Library lock icons change immediately.

## Agent assignment

Antigravity: **Gemini 4 Hydrogen, thinking medium**. Fallback: Codex Sol 6.2, medium.

## Done rule

Measure, fix, run the narrow tests, then the full suite once, commit on `release-polish`, report the before/after count and changed files concisely.
