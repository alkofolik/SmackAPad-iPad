# 24 — Practice screen: feedback round 3 (third star, tempo banner, colour tail, progress)

Status: ready-for-ipad-test (2026-11-01). Implementation and targeted simulator tests complete. Run **first** of tickets 24, 25, 26 (24 and 25 both touch `PracticeScreen.swift`; do 24 before 25).

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

- [x] Unit test proves star 3 -> fresh star, `StarEvent`, automatic stop; existing award rules verified.
- [x] A run ended by star 2 or 3 has a roughly 3 s burst and a persistent, dismissible summary line naming the reason (iPad visual check pending).
- [ ] Tempo-up banner overlaps nothing at compact and wide widths.
- [x] Both views use the trailing-colour policy; visibility-function tests pass (iPad visual check pending).
- [x] Shared bar/progress status implemented independently of view and mode for every bar count (iPad visual check pending).
- [x] Build succeeds, new tests pass; only the changed PlayedHitTests file and new PracticeSessionTests file were run.
- [ ] **iPad test (Jakub)**: a 1-bar and a 4-bar lesson, both views, earn star 3 from memory, watch the loop point.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app).
- **Reasoning effort**: **xhigh**. Do not use `max` (worse results on coding tasks than `xhigh`).
- **Reasoning**: Touches session state, rendering and star logic together, and a root cause must be found for problem 1. Claude Opus 4.6 on Antigravity is no longer available; Gemini Flash is not recommended for this ticket.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task. Final report max 5 lines.


## Implementation and validation (2026-11-01)

- Verified the third-star path without changing scoring, star thresholds or tempo progression. A session-level test drives actual pad input through the real scorer and scheduler: five expected hits, four correct hits (exactly 80%), Play + From memory at 120 BPM goal tempo, four consecutive passes. It asserts `fresh == [false, false, true]`, `StarEvent`, automatic stop, summary cause, saved memory progress and cleared feedback on a subsequent START. The existing third-star award/stop path works; missing persistent practice feedback was the confirmed problem in this scope. Intro library rows remain ticket 25.
- Added a run-end cause to `RunSummary`, preferring star 3 when both stopping stars are fresh. The large burst lasts about 3 s; the summary names star 2/goal tempo or star 3/from memory and remains until Close, a new run or navigation. Existing per-star VoiceOver announcements remain. Star 1 still continues the run.
- Replaced the tempo overlay with a 240 pt status slot reserved throughout a run, immediately after the tempo control. Its 220 pt content has room for the 1.08 pulse (237.6 pt); score follows the slot. Bar progress and consecutive-pass count share the next status line so portrait widths do not squeeze them into the banner. Compact widths omit the hand legend as before. The banner is absent during count-in and after STOP, and lasts about 1.2 s with or without Reduce Motion. Layout was checked in source; native portrait/landscape visual verification at compact and wide widths remains with Jakub, so the overlap acceptance checkbox stays open. No browser or design-skill scripts were run.
- Added pure `FeedbackWindow.visibleJudgments`/`strength`, retaining pass keys and one `trailingSteps = 4` window. Both Canvas views keep the last beat of the preceding pass, then crossfade scored blocks to their neutral hand colours over 0.25 s, measured from the current tempo. Scrolling uses the preceding repeat's negative step coordinates, so colours travel left across the wrap. Played-hit blocks use the same window and fade out; current-pass blocks remain behind the marker. Reduce Motion removes the tail at the boundary without fading. START/STOP clear history; old passes are pruned at each wrap. All fading is derived during TimelineView rendering, with no animation on scoring or sound scheduling.
- Added bar number, total bars and a thin full-pass progress line outside the pattern. This works for static and scrolling, Listen and Play, and section-loop lengths. It is hidden during count-in. The existing consecutive-pass counter stays next to it, with separate plain VoiceOver labels. New strings are in both English and Czech.
- The only session timing seam is an injectable host-clock reader for deterministic tests; its production default is the existing `mach_absolute_time` conversion. AudioEngine, scoring code and tempo policy are unchanged.

### Data bar-count inventory

A quick recursive Python scan of `bars` fields in `SmackAPad/Resources/Data/*.json` found **1, 2, 3 and 4 bars**. Counts below are records per source file, not a deduplicated catalog:

| Source | 1 bar | 2 bars | 3 bars | 4 bars |
| --- | ---: | ---: | ---: | ---: |
| lessons-core.json | 367 | 129 | 43 | 0 |
| intro.json | 22 | 2 | 0 | 0 |
| genre-extensions.json | 9 | 3 | 0 | 0 |
| electronic-path.json | 7 | 2 | 0 | 3 |

The pure visibility test covers those four lengths and an 8-bar fixture for longer future lessons, including the tail's start/end, fractional fade, different tempos, first-pass isolation, pass identity and empty restart history. Played-hit tests cover strict marker and page boundaries and Reduce Motion.

### Checks

- Simulator: iPad Air 11-inch (M4), iOS 27.0.
- First command built the app and all test sources, then ran only `PlayedHitTests` and `PracticeSessionTests`. All three `PlayedHitTests` passed. The session test initially failed because its host clock was captured before sample preparation, making the first count-in click late. Corrected the test fixture to capture time after preparation; production audio behavior was not changed.
- Re-ran only `PracticeSessionTests`: **1 test passed**, including fresh star 3, automatic stop and persistence. Previously passed tests were not repeated. Total final targeted coverage: **4 tests passed** (3 new, 1 existing in the changed file).
- Final targeted build/test command (compilation and XCTest passed; see log-finalization limitation below): `xcodebuild test -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'platform=iOS Simulator,id=BCAE2B5C-6C6F-4607-98FE-A62E2A96F473' -derivedDataPath build/ticket-24 -resultBundlePath build/ticket-24-session-results.xcresult -only-testing:SmackAPadTests/PracticeSessionTests CODE_SIGNING_ALLOWED=NO`.
- Logs/results: `build/ticket-24-test.log`, `build/ticket-24-results.xcresult`, `build/ticket-24-session-test.log`, `build/ticket-24-session-results.xcresult` (local ignored build artifacts).
- Xcode did not complete its final test-log collection after XCTest reported the selected suite passed. Its operation dump identifies `_IDETestingFinalizeLogsOperation` (`Finalize test log`). After several minutes without progress, the command was interrupted and then terminated when it did not exit. The second `.xcresult` bundle may be incomplete; the plain log records the successful test and suite. No clean overall `TEST SUCCEEDED` exit is claimed. No test was repeated after passing.
- No full-suite rerun, additional build, library work or sound-kit work. Jakub still checks 1- and 4-bar lessons, both views, portrait/landscape, tempo announcement, Reduce Motion/VoiceOver and earning star 3 on the physical iPad.
