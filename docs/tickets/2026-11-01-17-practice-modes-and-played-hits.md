# 17 — Practice screen: hide pattern only in Play, show played hits in from-memory

Status: ready-for-review (2026-11-01). Implementation complete; build validation blocked by concurrent library changes. iPad validation pending. Ticket 15 was committed (`b3a2f9c`) before this work started. Run before ticket 18 (both touch `PracticeSession.swift`).

## Goal

1. The pattern may be hidden **only in Play mode** (with "From memory" on). In Listen mode the pattern is always visible, otherwise the student does not know what to play.
2. In Play + From memory the orange field must not look empty: show the hits the student actually plays on the controller.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md` (§3 Modes, §5 Pattern look, §6 Views), `docs/design/2026-11-01-practice-feedback-round.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (line ~32: `hidden: session.fromMemory && session.running`), `PatternField.swift`, `PracticeSession.swift`.

## Tasks

1. `hidden` becomes `fromMemory && running && mode == .play`. In Listen the pattern is shown even when From memory is on. A memory star can only be earned in Play (check this in code, do not change star rules).
2. Record every hit the student plays during a run as a played hit: pad, step position within the pass (fractional), judgment (right / wrong, the same data already used for the result colours from 2026-11-01). Keep it in the session; clear it on START, RESTART and STOP.
3. Draw played hits in the pattern field **only while the pattern is hidden** (Play + From memory + running):
   - a block with the pad abbreviation in the row of the pad that was played; colours from the existing palette (the right/wrong shades already decided on 2026-11-01);
   - a hit on a pad that has no row in this lesson is **not drawn** (it still counts as an error in scoring);
   - grid skeleton, counts and position marker stay as they are now.
4. Visibility rule (one rule for both views): a played hit is visible only if its step is **before the current position in the current pass**. The student never sees his earlier playing ahead of the marker.
   - **Static view**: when a new pass starts (or the visible bars page to the next ones) the played hits are cleared; they appear again as the marker moves on.
   - **Scrolling view**: played hits are visible only behind the hit marker (to the left) and scroll away with the strip.
5. After STOP or the end of the lesson the real pattern is shown again and the played hits disappear.
6. Do not change scoring, tempo logic or star rules. English is the default language; texts via the localisation catalogs (both `en` and `cs` keys).

## Acceptance criteria

- [ ] Listen with From memory on: pattern fully visible during the run.
- [ ] Play with From memory on: pattern hidden after START, the student's hits appear behind the marker.
- [ ] Static view: hits from the previous pass are not visible at the start of the next pass.
- [ ] Scrolling view: nothing is drawn ahead of the marker.
- [ ] Hits on pads not used by the lesson are not drawn.
- [ ] Play without From memory is unchanged (pattern visible, no played-hit overlay).
- [ ] Build succeeds; a unit test for the visibility rule if it is a pure function.
- [ ] **iPad test (Jakub)**: 1, 2 and 4 bars, static and scrolling, light and dark.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), high thinking.
- **Reasoning**: Touches rendering and session state at once; Flash is not recommended.

## Done rule

Stop after successful build; Jakub tests on iPad. Commit after the task.

## Implementation and validation (2026-11-01)

- Pattern hiding and the stopped memory hint now apply only to Play + From memory. Listen stays visible. Listen passes already have no scorer, so they cannot award a memory star; star rules are unchanged.
- The session records pad, fractional strike position, pass number and the existing feedback colour. START/RESTART/STOP clear the history. Strike position uses the actual pass clock even when scoring matches a note in a neighbouring pass.
- Both views use `PlayedHit.isVisible` to admit only strikes before the current position in the current pass and visible bar range. Rows remain lesson-defined. Scrolling blocks are clipped behind the marker, and static pages cannot show strikes from another page or pass. Count-in strikes have negative positions and are never drawn.
- Added `PlayedHitTests.testVisibilityUsesTheCurrentPassPositionAndVisibleBars` for fractional positions, strict marker boundaries, pass changes, static paging and count-in exclusion. No existing tests were rerun. No scoring or tempo rules changed, and no new user-facing strings were added.
- `git diff --check` passed. The new test could not execute because compilation failed before testing. First attempt: a concurrently created `LibraryCatalog.swift` referenced missing `LessonProgress.hasPlayed`. Second attempt: excluding that file via a build parameter failed because concurrent edits to `Persistence.swift` and `Progression.swift` now depended on its types. No unrelated source files were changed or excluded in the project configuration. Stopped after two failed builds as required by AGENTS.md.
- Build and the single new test must be run again after the library work settles. Acceptance checkboxes remain pending runtime validation; Jakub still checks 1/2/4 bars, both views and both appearances on iPad.
