# 11b — Fix tempo oscillation between continuous passes

Status: implemented; iPad validation pending

## Cause and change

`PracticeSession.tick()` queues the next pass about 0.5 seconds ahead. The latest finished scoring result can belong to a slower, earlier pass. Previously, adopting its absolute `nextBpm` directly could lower a tempo already queued by another result. `ScoringEngine.finish()` calculates the selected BPM step correctly and remains unchanged.

Extract tempo choice into the value-only `PracticeTempo` policy. Queue the maximum of the last queued BPM and the latest pending result's `nextBpm`, capped at the lesson target. Consume each pending result once. START/RESTART clear both `lastResult` and pending tempo state. Listen retains its existing current-tempo behaviour.

The next pass is already queued when the current pass's last timing window closes. A clean result therefore affects the pass after the already queued one: a one-pass delay before a rise is expected, with no pauses or countdowns between passes.

## Validation

- Six focused tests: monotone clean staircase for steps 1/2/5/10, unclean hold, single consumption, target cap, reset/manual tempo, and unchanged Listen tempo.
- Red: the unclean-pass regression test failed with the original absolute-result selection (50 BPM returned instead of the already queued 55 BPM).
- Green: all six new `PracticeTempoTests` passed on the iPad Air 11-inch (M4) simulator. No previously passing tests rerun.
- Build: final simulator build recorded in `build/tempo11b/build.log`.
- iPad check (Jakub): start at 50 BPM, step 5; play several clean passes and verify a staircase without decreases. Play one pass badly and confirm its result holds the tempo (allow for an already queued rise from an earlier clean pass). Check manual tempo after STOP/START and RESTART, and Listen.
