# 68 — Practice: show the result of every run, passed or not

Status: ready. Source: Jakub, 2026-11-04: "I never see the results of each run, even a failed one. Or is it hidden somewhere?" Run after ticket 67 (both touch `PracticeSession.swift`).

## Today

During a lesson the player sees only the lap-vault flag (filled = passed, outlined = not passed, about 1.2 s, ticket 66). The score of a run is shown nowhere until STOP, and the STOP summary shows only the last run.

## Rule

1. **Run log row while playing.** In the result area under the band (where the summary appears after STOP), a single row of small chips, one per finished run of this session, newest on the right, at most 6 visible (older ones slide out to the left).
   - Chip: score as a whole percent ("84 %"), tempo below in meta font ("96 BPM"), a small mark for passed (filled) or not passed (outlined), same palette as the vault flag.
   - The newest chip fades in at the moment the run's result is known; no other motion. Reduce Motion: no slide, just opacity.
   - Hidden in listen mode. Shown in section loops (they have results too).
   - Never covers the band, the timing bar or the touch deck; layout height stays fixed from the first run on (reserve the row height when a scored run starts).
2. **STOP summary** lists all runs of the session (same chips, scrollable horizontally if many), above the existing summary content. Keep "Next" / "Again" (ticket 58) unchanged.
3. Data: keep a per-session array of `(score, bpm, passed)` filled in `finishCompleted`; clear it on a new start.
4. VoiceOver: the row is one element, label "Run results", value e.g. "Run 3: 84 percent, 96 BPM, passed". Cs + en strings.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeSession.swift` (`finishCompleted`, `lastVerdict`, `RunSummary`, `stop`), `SmackAPad/Sources/UI/PracticeScreen.swift` (`result`, `practiceContent`), `SmackAPad/Sources/UI/PracticeComponents.swift`, `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] Every finished run, passed or not, adds a chip with score, tempo and mark.
- [ ] STOP shows all runs of the session.
- [ ] Nothing moves or jumps when chips appear; landscape and portrait; light and dark; cs and en.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: play a few runs with one deliberately bad, then STOP.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
