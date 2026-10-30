# 08 — Scoring Engine

Status: implemented — awaiting new-test and iPad validation

## Implementation checkpoint (2026-10-30)

- Approved test boundaries: input hit → feedback; completed attempt → result and next BPM.
- Implemented native mach-clock input → feedback and attempt → result/next-BPM interfaces.
- Confirmed the previously unspecified score formula with Jakub and recorded it in DECISIONS §7.
- Jakub reports all 28 existing tests passed on iPad Air 11-inch (M4), including the
  five-level timing-window test. These tests were not rerun during the continuation.
- Added 12 scoring tests covering calibration, adaptive timing, double hits, run results,
  intro thresholds, mastery boundaries, eight-pad effective hits, and tempo progression.
- A single new calibration test was run outside the sandbox before implementing the
  subtraction. It failed as expected (`off` instead of `perfect`, ±125 ms instead of zero).
  The runner then hung after reporting that result and was terminated. Per Jakub's one-run
  instruction, no tests were rerun after the implementation. New tests still need validation.
- Final app-and-tests compilation succeeded with `build-for-testing` on the confirmed
  simulator destination (`** TEST BUILD SUCCEEDED **`). No tests ran during this build.
- Gameplay wiring and persistence are outside these approved test boundaries. The caller
  supplies resolved pad indices, calibrated device offset in milliseconds, selected BpmStep,
  and a mach-clock musical start. It stops input after the final shifted maximum window,
  calls `finish()`, then consumes/persists its immutable result and `nextBpm`.

### Implementation details

- Calibration is subtracted once; audio output latency is not part of scoring.
- Adaptive samples are matched errors after calibration but before adaptive correction.
  The learning gate is inclusive ±110 ms. The center is the median of up to the last eight
  accepted samples (mean of the middle two for even counts), updated after grading each hit.
  Rejected/out-of-gate input never trains the center. Window widths remain unchanged.
- The double-hit guard uses raw native-clock distance from the last match on that pad,
  inclusive of 30 ms. Rejections count as extra hits and do not consume another expected note.
- Errors are missed expected hits plus extra input; `perfect`, `good`, and `off` all match.
- `finish()` returns a snapshot: misses include all remaining expected notes. An empty
  pattern cannot pass, be clean, earn mastery, or advance tempo. Repeated snapshots do not
  mutate tempo. Clean runs below target advance by the selected step, capped at targetBpm;
  clean runs at/above target earn mastery and keep their current tempo.

### Next validation by Jakub (only the 12 new tests)

```sh
xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -configuration Debug \
  -destination 'platform=iOS Simulator,id=BCAE2B5C-6C6F-4607-98FE-A62E2A96F473' \
  -derivedDataPath build/TestDerivedData CODE_SIGNING_ALLOWED=NO \
  -only-testing:SmackAPadTests/ScoringEngineTests \
  -skip-testing:SmackAPadTests/ScoringEngineTests/testEveryLevelGradesBothSidesOfItsExactTimingWindows test
```

## Goal

Implement the scoring engine with timing windows, pass/mastery logic, adaptive timing center, and BPM auto-progression.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§5 Scoring Rules — all subsections)
- `docs/DECISIONS.md` (§6 Scoring, §7 Philosophy of tolerance, §9 Adaptive timing center)

## Tasks

1. **Timing windows** (level-dependent):
   - L1–2: perfect ±45 ms, good ±100 ms, max ±200 ms.
   - L3–4: perfect ±38 ms, good ±85 ms, max ±175 ms.
   - L5: perfect ±30 ms, good ±70 ms, max ±150 ms.
2. **Timestamp flow**:
   - Raw MIDI timestamp → subtract calibration offset → subtract adaptive timing-center shift → final timestamp for window comparison.
3. **Adaptive timing center**: rolling median (window of 8 samples, gated ±100–110 ms). Shifts window, does NOT widen it.
4. **Double-hit guard**: second hit on same pad within 30 ms = wrong pad, not second match.
5. **Pass**: score ≥70% (non-intro), ≥80% (intro).
6. **Mastery**: clean run at or above targetBpm. Error limits: ≤15 hits → 0 errors, 16–32 → 1, >32 → 2. Intro always 0 errors.
7. **BPM auto-progression**: after clean run below targetBpm, increase tempo by user-selected step (1/2/5/10).

## Acceptance criteria

- [x] Timing windows match §5.1 exactly for each level (test passed by Jakub).
- [ ] Calibration offset applied once (not double-counted with outputLatency).
- [ ] Adaptive timing center shifts window correctly.
- [ ] Double-hit guard prevents re-matching within 30 ms.
- [ ] Pass/mastery thresholds match §5.3.
- [ ] BPM auto-progression fires after clean run below targetBpm.
- [ ] **iPad test**: scoring feels fair and matches player perception.

## Skill

Use the **tdd** skill for this ticket. Scoring logic must be test-driven.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Precise timing logic with multiple interacting rules. Critical for gameplay feel.

## Done rule

Stop after successful build; Jakub tests on iPad.
