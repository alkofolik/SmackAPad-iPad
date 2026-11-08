# 151 — Ignore same-pad double triggers

Status: draft, waiting for Jakub to hand it to the agent. Blocked by: none. Source: AI panel round 1 (`docs/reviews/ai-panel/results/round1-claude.md` R1-04; `synthesis.md` item 6); `docs/2026-11-08-ai-panel-action-plan.md`, Batch 1.

## Goal

A worn pad or a Bluetooth re-send can fire two note-ons on the same pad a few milliseconds apart. Today the second one is scored as a wrong extra hit, and on short patterns one extra hit ruins a clean run (0 errors are allowed for 15 hits or fewer). Such a double trigger is not something the player played, so it must be ignored without any penalty.

## Current behaviour

`SmackAPad/Sources/Scoring/ScoringEngine.swift`, `receive(padIndex:at:)` (around lines 113–119): if the same pad was **matched** within 30 ms before, the new hit adds to `extraHitCount` and returns `.wrongPad`. Genuine extra hits (not a duplicate) must keep being counted.

## Rules

1. A note-on on the same pad within **25 ms** of the previous accepted note-on on that pad is ignored: no change to `extraHitCount`, matches, misses or accuracy, and no error mark in the pattern.
2. Compare against the previous *accepted* note-on on that pad (matched or not), not only the previously matched one. A genuine extra hit that was counted still opens the 25 ms window for the next duplicate.
3. Hits on different pads are never affected. Real fast playing stays untouched (a 16th note at 240 BPM is about 62 ms apart).
4. The scoring engine needs a clear way to report "ignored" to its callers. Check every caller (`PracticeSession.swift` `recordPlayedHit` and the touch-pad and keyboard paths) so an ignored hit shows no coloured mark and no verdict change. If it is simpler, add an `ignored` result case and handle it everywhere the result is switched over.
5. Keep the 25 ms value as one named constant with a short comment. Do not change timing windows, calibration or the scoring formula.
6. Sound is out of scope: do not touch audio playback in this ticket. Mention in the final message whether the duplicate still plays a sound, so Jakub can decide on a follow-up.

## Files to read

`AGENTS.md`, this ticket, `ScoringEngine.swift`, `SmackAPadTests/ScoringEngineTests.swift`, `SmackAPadTests/PlayedHitTests.swift`, `PracticeSession.swift` (`recordPlayedHit` and where `receive` results are used).

## Tests (write first)

- Same pad twice, 10 ms apart, second note-on ignored: `extraHitCount` stays 0 and a short pattern still ends clean.
- Same pad twice, 24 ms apart: ignored. 26 ms apart: counted as a genuine extra hit.
- Genuine extra hit followed by a duplicate of it 10 ms later: counted once.
- Two different pads 5 ms apart: both processed normally.
- Fast legitimate roll on one pad, 62 ms apart: both processed normally.
- Existing scoring tests still pass unchanged (the old 30 ms behaviour was only covered, if at all, by tests that must now be updated to the new rule).

## Acceptance criteria

- [ ] A same-pad duplicate within 25 ms never counts as an error.
- [ ] Genuine extra hits still count.
- [ ] An ignored hit leaves no mark in the pattern and does not break the played-pad colouring.
- [ ] Full test suite passes before commit.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **medium**. Fallback: Claude Opus 5.5, normal thinking.
- **Reasoning**: a small, well-located change; the care goes into checking every caller of the scoring result, which medium handles.

## Done rule

Stop when the acceptance criteria are met and the full test suite passes. Commit (AGENTS.md); Jakub pushes.
