# 22 — Announce a tempo increase during a run

Status: ready-for-agent (2026-11-01). **Start only after tickets 17 and 18 are finished and committed** (all touch `PracticeSession.swift` and `PracticeScreen.swift`).

## Goal

During a run the tempo rises after a clean pass. Today the change is easy to miss. Show a short, tasteful but clearly visible announcement at the moment the faster pass begins.

## Behaviour

- Trigger: a pass starts at a higher BPM than the previous pass of the same run. **Not** when the next pass is queued: passes are queued ahead (`PracticeSession`, around the `tempo.queue(after:...)` call), so the announcement must follow the pass that actually starts, in step with the audible change. A manual tempo change by the student is not announced.
- Visual: the tempo field pulses once, and a label "Tempo up: 80 -> 85 BPM" appears next to it for about 1.2 s, then fades. It must not cover the pattern, the playhead or the pads.
- Reduce Motion: no pulse or movement, only the label fading in and out.
- VoiceOver: post an announcement ("Tempo 85").
- Colours: orange, black, white only (no new colours). Use `Theme.swift` tokens and the same motion style as `StarBurst.swift`.
- Not shown in the count-in or after STOP.

## Files to read

`AGENTS.md`, `docs/design/2026-10-30-practice-screen-spec.md` (tempo, status row), `docs/design/2026-11-01-practice-feedback-round.md`, `SmackAPad/Sources/UI/PracticeSession.swift`, `PracticeScreen.swift`, `PracticeComponents.swift`, `StarBurst.swift`, `SmackAPadTests/PracticeTempoTests.swift`.

## Tasks

1. In `PracticeSession` expose a small observable event "tempo rose from X to Y" when a pass with a higher BPM starts (pure logic, testable).
2. Show the pulse and label in the practice screen near the tempo field.
3. Texts via the localisation catalogs (`en` and `cs` keys).
4. One unit test for the event: raised on a higher next pass, not raised on a manual change, not raised on the first pass.

## Acceptance criteria

- [ ] The announcement appears exactly when the faster pass starts and disappears by itself.
- [ ] Nothing important is hidden; Reduce Motion works.
- [ ] Build succeeds, tests pass.
- [ ] **iPad check (Jakub)**: it is noticeable but not distracting while playing.

## Agent assignment

- **Agent**: Claude Opus 4.6 (Antigravity), high thinking.
- **Reasoning**: Timing against the audio clock and queued passes is easy to get wrong. Flash is not recommended.

## Done rule

Stop after successful build and tests. Commit after the task.
