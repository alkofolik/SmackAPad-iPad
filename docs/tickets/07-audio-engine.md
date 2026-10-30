# 07 — Audio Engine + Sample Kits

Status: ready-for-human

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

## Implementation — 2026-10-30

- Added `SmackAPad/Sources/Audio/AudioEngine.swift` using AVAudioEngine and a `.playback` audio session. AVAudioSession has no `.interactive` latency hint; its native equivalent here is a preferred 5 ms I/O buffer, with the actual duration read after activation.
- `prepare()` decodes the bundled manifest, loads every kit and voice, resolves paths relative to `samples.bundle` (including cross-kit references), and converts WAVs into shared, cached stereo PCM buffers. No sample file I/O occurs during a hit.
- A pool of 64 player nodes supports overlapping samples. Velocity chooses the first matching `maxVel` layer; repeated hits cycle through its variants. Velocity zero is silent. Invalid input, missing resources, and exhausted polyphony produce explicit errors; asynchronous live-hit errors are available through `lastError`.
- `start()` activates audio; `selectKit(_:)` changes the kit; `play(padIndex:velocity:)` triggers live hits; `schedule(padIndex:velocity:audibleHostTime:)` schedules future hits against absolute mach host time. All control operations use a dedicated serial queue.
- `startMetronome(bpm:firstBeatHostTime:beatCount:)` returns the first audible click time. BPM 60 with `beatCount: 10` supplies the calibration sequence. A short look-ahead timer schedules host-timed buffers; late beats are skipped rather than bunched. `stopMetronome()` cancels queued clicks.
- Output latency plus actual I/O buffer duration is subtracted only when scheduling future audio. Live hits play immediately. No scoring code or scoring window was changed; SPEC §5.2 and this ticket take precedence over the conflicting wording in DECISIONS §10.
- Interruptions stop pending playback. Eligible interruption recovery and output-route changes reactivate the session and refresh latency. A metronome/calibration sequence must be restarted after a route change.

## Validation and remaining handoff

- **Build passed:** Debug, generic iOS device, signing disabled, using `xcodebuild`. The first sandboxed attempt could not launch Swift macro plugins; the retry with Xcode execution permission succeeded. No tests were added or run.
- Jakub confirmed the full sixteen-pad voice mapping. It is recorded in DECISIONS §2 and used by `AudioEngine.defaultPadVoices`, so `AudioEngine()` uses the canonical mapping without extra configuration. Paired pads 8/11, 12/15, and 13/14 share sounds. An explicit `padVoices` override remains available; eight-pad slots must first resolve through the current lesson's layout.
- **Build with canonical mapping passed:** Debug, generic iOS device, signing disabled. No tests were added or run.
- All acceptance checkboxes remain open for runtime/device verification: all eight kits, correct pad sounds, velocity layers, metronome tempo, audible glitches, and the <15 ms trigger-to-sound target. A successful build does not establish these measurements.
- Existing changes in other modules, resources, tests, and the Xcode project were left outside this task's commit.
