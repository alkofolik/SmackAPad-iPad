# Ticket 175 — Timing error consumers

## Matching and grading (keep centred)

- `ScoringEngine.receive`: subtracts the adaptive centre to select the closest unmatched note inside the existing ±200/175/150 ms windows. The centred error still determines `HitJudgment` and `perfectOrGoodHitCount`.
- `ScoringEngine.receive`: learns the median of the last eight calibrated, un-centred errors within ±110 ms. Learning, duplicate rejection and centre reset stay unchanged.
- `ScoringEngine.earlyResult`: uses the centre to decide which matching windows have closed. Keep this unchanged.
- `PracticeSession.receive`: compares `HitFeedback.timingErrorMilliseconds` when choosing between overlapping passes. Keep this centred so pass ownership stays unchanged.
- `PracticeSession.record`: uses the existing judgment for pad colours and expected-note feedback. `FeedbackWindow` only controls visibility and fading; it does not read timing errors.

## Display and storage (use calibrated, un-centred error)

- Add `HitFeedback.calibratedTimingErrorMilliseconds` alongside the unchanged centred field. Unmatched and ignored inputs have no error.
- `PracticeSession.receive` records the new field in `TimingHistory`. Its last 32 samples are in-memory storage, retained for the result screen.
- `TimingHistory.Sample` uses that stored error for graph position and its good-window colour. `TimingHistory.cueOffset` uses the last eight recent samples for the rushing/dragging cue.
- `PracticeScreen` feeds `TimingCue` from this history in both practice layouts.
- `HitTimingPlot` in `PracticeComponents` reads the same history for the result graph and the accessible “Early … ms” / “Late … ms” figures. No text changes are needed.
- `PracticeSession.receive` sends the new field to `BluetoothTimingDiagnostics.logNoteOn`, so the stored diagnostic `err` value is also un-centred. The separate `center` value remains available.

## Run results and saved progress

`ScoringEngine.finish`, `PracticeRunResult` and `RunSummary` contain counts, scores, tempo and qualification, not timing-error aggregates. Their scoring and star inputs stay unchanged. The result screen's timing graph reads `session.timingHistory` directly.

`ProgressModels`, `ProgressStore` and `ProgressBackup` do not persist per-hit timing errors. No new progress field, migration or backup format change is needed; old progress and Export/Import remain compatible.

## Regression test boundary

Use `PracticeSession`'s existing MIDI input callback and read-only history, judgments, scoring result, summary and progress. A steadily +80 ms late player must retain +80 ms samples and a late cue through star completion, while matching, centred judgments, score and earned stars keep their existing outcomes.
