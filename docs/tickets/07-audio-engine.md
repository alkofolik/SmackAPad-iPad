# 07 — Audio Engine + Sample Kits

Status: ready-for-agent

## Goal

Implement the AVAudioEngine-based audio engine: load sample kits, play voices per padIndex with velocity variants, metronome click.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.2 Audio, §4.2 Sample Kit JSON, §5.2 outputLatency usage)
- `docs/DECISIONS.md` (§10 Audio engine, §13 Sample kits)

## Tasks

1. Set up `AVAudioEngine` with `AVAudioSession` category `.playback`, latency hint `.interactive`.
2. Load all sample kits from `sample-kits.json` + WAV files in `Resources/Samples/`.
3. Play the correct voice per padIndex, selecting velocity variant by MIDI velocity.
4. Handle virtual kits (jazz, world) that reference WAV files from other kit directories.
5. Implement metronome click at configurable tempo for calibration and practice.
6. Read `AVAudioSession.outputLatency` + `ioBufferDuration` — use these ONLY for scheduling audio playback so sound reaches the speaker at the intended musical moment. Do NOT add to scoring window.

## Acceptance criteria

- [ ] All 8 sample kits load and play with <15 ms trigger-to-sound latency.
- [ ] Correct voice selected per padIndex.
- [ ] Velocity variants triggered appropriately.
- [ ] Metronome plays at correct tempo.
- [ ] **iPad test**: audio output latency is acceptable; no audible glitches.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, high
- **Reasoning**: Low-latency audio engine with precise timing. Hardware-facing code.

## Done rule

Stop after successful build; Jakub tests on iPad.
