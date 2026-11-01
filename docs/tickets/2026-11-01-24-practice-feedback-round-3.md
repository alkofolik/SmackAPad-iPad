# 24 — Practice screen: feedback round 3 (third star, tempo banner, colour tail, progress)

Status: ready-for-agent (2026-11-01). Run **first** of tickets 24, 25, 26 (24 and 25 both touch `PracticeScreen.swift`; do 24 before 25).

## Goal

Fix what Jakub found on the iPad after tickets 17–23. Four problems, all in the practice screen.

## Problems and required behaviour

### 1. Third star is not announced, and it is unclear whether it ended the run

Findings from the code review (verify, do not assume):
- `StarAward.shouldStop` is true for a fresh star 2 **or** star 3, and `PracticeSession.tick()` stops the run, so the stop probably works; but the only feedback is the `StarBurst` overlay (about 2 s) and the run then ends silently.
- The library shows the third star only through `LibraryLessonRow`. **Intro lessons use `IntroExerciseRow`, which draws only two stars** (see ticket 25), so a memory star earned in an Intro lesson never shows up. Ticket 25 fixes that row; here fix the practice side.

Required:
- Reproduce with a session-level unit test: a Play + From memory run at goal tempo with score >= 80 % for the required number of consecutive passes produces a fresh star 3 (`StarAward.fresh[2]`), a `StarEvent` and an automatic stop. Fix whatever breaks.
- When a run ends **because** star 2 or 3 was earned, show it clearly and keep it until dismissed: the large `StarBurst` stays about 3 s, then the end-of-run summary strip names the cause in one line ("Run finished: star 3 earned, from memory"). Earning star 1 keeps the run going (unchanged).
- VoiceOver announcement for every new star (already exists for the burst; keep it).
- Library check: after returning from practice the row shows the new star (covered by ticket 25 for Intro).

### 2. Tempo-up banner overlaps the accuracy figure

`PracticeScreen.status()` draws `TempoUpBanner` as an overlay on the tempo button with `.offset(x: 8)` and `.frame(width: 0)`, so it lands on the score text. Neither can be read.

Required: the banner must never overlap any text, the pattern or the pads. Use a layout slot, not an overlay: reserve a fixed-width slot directly right of the tempo field in the status row (reserved while a run is active so nothing shifts when it appears), and move score and pass counter after it. Same pulse, 1.2 s, Reduce Motion and VoiceOver behaviour as in ticket 22. Check at compact width (< 1000 pt) and wide, portrait and landscape.

### 3. Colours of the last hits vanish at the loop point

When a pass ends and the next starts, `judgmentsByPass` is filtered to the new pass and `session.hitJudgments` switches to the new pass at once. The last hits of the previous pass lose their colour at the very moment the marker wraps, so they look unplayed.

Required (both views):
- Keep the previous pass's judgments for a trailing window: the last 4 steps (one beat) of the previous pass stay coloured while the marker has not yet moved 4 steps into the new pass, then fade to the neutral look over about 0.25 s (colour interpolation, no movement). Make the window one named constant.
- Static view: the end of the last bar keeps its colours across the wrap; the first bar of the new pass starts neutral. Scrolling view: hits scroll away to the left with their colours (check that nothing resets early at the wrap).
- Hits in the new pass are never coloured from the old pass.
- Play + From memory played-hit blocks follow the same rule (they stay visible behind the marker for the same trailing window).
- Pure function for "which judgments are visible at position p of pass n", unit-tested (window boundaries, first pass has no tail, restart clears the tail).
- Reduce Motion: no fade, the tail is simply removed after the window.

### 4. Remaining distance to the end of the lesson must be visible everywhere

Currently there is no explicit indicator; the student only sees bar headers inside the pattern.

Required, for **every** lesson (1-bar, 2-bar, 4-bar, longer lessons; static and scrolling; Listen and Play):
- A quiet indicator in the status row: "Bar 3 / 4" plus a thin progress line for the current pass (position within the pass). For 1-bar lessons show the progress line only plus "Bar 1 / 1".
- Next to it the existing run counter ("2 / 4" from ticket 18) stays, so the student sees both: where he is in the pass and how many passes remain for the next star. Label both in plain words via VoiceOver.
- Hidden during the count-in, shown in Listen too (without the star counter).
- Check every bar count that exists in the data (list them with a quick script) and attach the list to the report.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md`, `docs/tickets/2026-11-01-17-*.md`, `-18-*.md`, `-22-*.md`, `-23-*.md`, `SmackAPad/Sources/UI/PracticeScreen.swift`, `PracticeSession.swift`, `PatternField.swift`, `StarAward.swift`, `StarBurst.swift`, `TempoUpBanner.swift`, `PracticeComponents.swift`, `SmackAPadTests/PlayedHitTests.swift`, `PracticeTempoTests.swift`.

## Constraints

- Orange, black, white only (plus the existing result shades). Tokens from `Theme.swift`. Touch targets >= 44 pt.
- Do not change scoring, tempo logic or star rules. Do not touch audio timing; no animation may run on the audio or scoring path (the Canvas pattern is redrawn from `TimelineView` only).
- Texts via the localisation catalogs, `en` and `cs`.
- Do not start ticket 25 or 26 work (library, Intro rows, sound kits).

## Acceptance criteria

- [ ] Unit test proves star 3 -> fresh star, `StarEvent`, automatic stop; fixed if it failed.
- [ ] A run ended by star 2 or 3 shows the burst for about 3 s and a summary line naming the reason.
- [ ] Tempo-up banner overlaps nothing at compact and wide widths.
- [ ] Trailing colour window works in static and scrolling views; unit test for the visibility function.
- [ ] Bar and progress indicator visible in all bar counts, static and scrolling, Listen and Play.
- [ ] Build succeeds, new tests pass (do not re-run old passing tests except those in files you changed).
- [ ] **iPad test (Jakub)**: a 1-bar and a 4-bar lesson, both views, earn star 3 from memory, watch the loop point.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), **high** thinking.
- **Reasoning**: Touches session state, rendering and star logic together; a root cause must be found for problem 1. Gemini Flash is not recommended.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task. Final report max 5 lines.
