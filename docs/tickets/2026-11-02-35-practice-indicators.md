# 35 — Practice screen: progress line, accuracy, hit timing

Status: ready-for-human. Source: Jakub's test 2026-11-02 (feedback round 5). Run after ticket 34.

## Goal

Replace unclear indicators with three clear ones.

## 1. Run progress

Remove the "Bar 1/1" text. Show progress as a thin line across the full screen width; bars appear as short small vertical ticks at their boundaries.

## 2. Accuracy

Today the percentage wanders around the screen before and during a lesson and Jakub does not know what it means. Replace with one fixed place that never jumps:

- During a run: the accuracy of the current run, large, with the label "This run".
- Below it, small: "Best".
- Before START: only "Best".

## 3. Per-hit timing (from the legacy tool)

Study how the legacy app does it: `~/AI COWORK/Smack-a-Pad/Smack-a-Pad/2026-10-28-Smack-a-Pad-ipad/app/v21/src/engine/scoring.js` (`renderTimingMeter`) and `src/ui/practice-d.js` (`practiceDPaintTiming`). Legacy shows (a) a bar Early – On time – Late with a tick for the last hit, (b) a plot of the last 32 hits as dots, (c) a short tendency text.

Build this version:

- **During play:** a narrow horizontal bar Early – On time – Late under the orange field. The tick of the last hit jumps to its position by deviation in ms (full width = the current scoring window, as in `scoring.js`). The previous ~6 hits stay as fading ticks. Beside it a small tendency text ("Late 12 ms", "Early 8 ms", "Centred" under 8 ms) from a rolling median of the last 8 hits.
- **After the run**, in the detail of the summary strip: a plot of the last 32 hits as dots left to right (higher = early, lower = late); dots outside the "good" window in a different shade.
- Palette only: middle orange, edges grey/neutral. It must be calm: Jakub earlier did not want live per-hit shapes that make him nervous, so no flashing, no big animations; ticks fade gently.

## Rules

- Deviations are the signed ms values from the existing scoring. Do not change scoring, stars or hit windows.
- The indicators never cover the pattern or the accuracy number.
- Texts in `en` and `cs`.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md`, `SmackAPad/Sources/Scoring/ScoringEngine.swift`, `UI/PracticeScreen.swift`, `PracticeComponents.swift`, `PracticeSession.swift`, `FeedbackWindow.swift`.

## Acceptance criteria

- [x] "Bar 1/1" gone; progress line with bar ticks implemented for 1–4+ bars.
- [x] Accuracy readout fixed, never moves, labelled.
- [x] Hit timing bar and tendency text update on every matched hit; post-run dot plot in the detail.
- [x] Unit test for tendency calculation (median of last 8, "Centred" threshold).
- [ ] Both languages; light and dark; build and tests pass.
- [ ] **iPad test (Jakub)**: play a lesson slightly late on purpose and check the tendency says "Late".

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, reasoning **high**.

## Done rule

Stop after successful build; Jakub tests on iPad. Claude commits afterwards.

## Implementation notes

- Added a full-width pass progress line with bar-boundary ticks, a reserved accuracy slot, and a reserved live timing lane below the pattern.
- Run accuracy aggregates completed passes and judged input in the current pass. Best uses the existing saved score. Partial runs also expose the timing detail without awarding stars.
- Timing history retains the last 32 matched deviations from scoring, with the last seven shown as calm ticks and the last eight used for the median. Unmatched input has no signed deviation and is not plotted.
- Scoring windows are exposed through read-only properties; scoring, star rules, and hit windows are unchanged.
- The legacy source was not read because AGENTS.md only allows legacy reads for copying explicitly named data files. The ticket's behavioral description was sufficient.
- Validation: the requested tendency test passed (1 test, 0 failures), including early/late medians, the rolling eight-hit window, a 7.5 ms centred median, and both ±8 ms boundaries. English and Czech string files passed syntax validation. Final build result is recorded below.
- iPad checks remain with Jakub: both orientations, light/dark, progress over different bar counts, fixed readout placement, and deliberately late hits.
- Final validation: generic iOS build succeeded with code signing disabled (`xcodebuild build`, scheme `SmackAPad`). No additional tests were run.
