# 175 — Show and store the true (un-centred) timing error

Status: ready-for-human. Implemented and verified on 2026-11-11; awaiting Jakub's manual iPad check. Approved by Jakub on 2026-11-11. Corresponds to AI panel item #23 (claude R3-02). Model: Codex GPT-6.1 Sol, thinking high (fallback Gemini 3.8 Pro, high). Do not use Flash: this touches scoring and it could silently change hit matching.

## Goal

The adaptive centre in `ScoringEngine` (`corrected = calibrated − center`, centre = median of the last 8 errors, up to ±110 ms) hides steady dragging or rushing: a player who is 80 ms late on every hit sees about 0 ms after a few beats. Keep the centre for hit matching only. Show and store the calibrated, un-centred error instead.

## Steps

1. Find every consumer of the centred error (`ScoringEngine` around lines 131, 147 and 156–165, `FeedbackWindow`, `timingHistory`, the "Late 47 ms" figure, the run result and the rushing/dragging cue on the practice screen). Write the list to `docs/design/2026-11-11-175-timing-consumers.md`.
2. Add the calibrated, un-centred error as a separate field of the hit result. Do not change existing fields or the matching windows.
3. Switch only display and storage to the new field.
4. Scoring, stars and the windows (±200/175/150 ms) stay exactly as they are.

## Rules

- No new UI text, no new features, no change to star or pass rules.
- No change of the stored data format that breaks progress Export/Import (ticket 161). If a new stored field is needed, make it optional and backward compatible.
- No clean-up "while at it".

## Tests

- New test: a player steadily 80 ms late gets a displayed error of about +80 ms, while matching and stars come out the same as before.
- The full suite (244 tests) must still pass.

## Acceptance criteria

- [x] Displayed and stored error is the un-centred one.
- [x] Matching, scoring and stars unchanged.
- [x] Old saved progress and backups still load.
- [x] Consumer list documented.

### Manual iPad check for Jakub

Play a lesson slightly late on purpose. The rushing/dragging cue should settle on "late" and not drift back to the middle after a few hits.

## Agent assignment

Codex GPT-6.1 Sol, thinking high (fallback Gemini 3.8 Pro, high).

## Done rule

Build, full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check. If the build fails twice, stop and report. Final report: max 5 lines.

## Implementation and verification

- Added `HitFeedback.calibratedTimingErrorMilliseconds` without changing the centred field, matching, judgments or scoring windows.
- Switched timing history and Bluetooth diagnostic storage to the calibrated, un-centred value. The result graph and rushing/dragging cue consume that history.
- Documented consumers in `docs/design/2026-11-11-175-timing-consumers.md`. No persisted progress or backup schema changed.
- Added one MIDI-to-session regression test for steady +80 ms lateness through star completion. It first failed on the original code's zeroed history and cue; matching, judgments, score and stars already passed. That initial test process stalled after reporting the expected failure and was terminated.
- `xcodebuild build test` on the iPad (A16), iOS 27.0 simulator: build succeeded; all 245 tests passed with no failures. The final process exited normally.
- Manual iPad check above remains for Jakub.
