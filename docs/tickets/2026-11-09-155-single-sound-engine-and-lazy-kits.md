# 155 — One sound engine, load only the selected kit

Status: approved by Jakub 2026-11-09, ready for the agent. Source: AI panel finding #13 (plan: `docs/2026-11-08-ai-panel-action-plan.md`, batch 3). Related: ticket 121 (slow Training open), review item R09 in `docs/reviews/2026-11-02-fresh-review.md`.

## Problem (read from the code, 2026-11-09)

1. `AudioEngine.prepare()` → `loadKits()` decodes **every** sample of **all 8 kits** (808, acoustic, brush, house, jazz, rock, world, worldperc): about 371 WAV files, converted to 48 kHz stereo float32. Estimated memory: **~290 MB** (source files are 44.1 kHz 16-bit, ~96 MB in the bundle). Only one kit is ever used per lesson.
2. Every `PracticeSession` creates its own `AudioEngine()` (`PracticeSession.swift:156`) and `CalibrationSession` another (`CalibrationSession.swift:23`). Each one calls `prepare()`, so the same ~290 MB is decoded again every time a lesson opens, and two engines can exist at once. Each engine also attaches 96 player nodes.
3. Result to expect: slow lesson start, memory pressure (risk of the system killing the app on smaller iPads), and extra load on the main path. Not yet measured on a device.

## Rules

1. **Kits load on demand.** Only the kit chosen for the lesson (`resolvedKitId`) is decoded. The default kit `acoustic` stays available as the fallback. Keep the existing manifest validation (`sample-kits.json` checks) but run it for the whole manifest cheaply (without decoding audio), so a broken kit is still reported.
2. **One shared sample store.** Decoded buffers live in one process-wide cache (kit id → voices), shared by all sessions. Opening another lesson with the same kit does not decode again. When memory is tight (memory warning) or a different kit is selected, kits not in use may be released; the kit in use is never released while playing.
3. **One engine at a time.** Practice and calibration must not each prepare a full engine in parallel. Preferred: one shared `AudioEngine` instance kept by the app and reused by practice sessions (prepared once, started/stopped per lesson). Calibration may keep its own small graph if merging it is risky — then it must not load any kits (it only needs the click). The agent decides and explains the choice in the report; it must not change the timing or calibration maths.
4. **Loading never blocks the main thread or the audio queue while playing.** Decode on a background task before `start()`. `selectKit` to a kit that is not loaded yet must be completed before playback starts (Start stays disabled until the kit is ready, as today for `prepare`). If the loading fails, fall back to `acoustic` and keep the lesson usable.
5. **Pad sound path off the main thread (verify, change only if needed).** `play(padIndex:velocity:)` already hops to the audio queue. Check the whole path from the MIDI callback (`MIDI/MIDIInput.swift`) to `audio.play`, and `audio.schedule` (it uses `queue.sync` from the main actor, `PracticeSession.swift:~890`). If anything on that path waits on the main actor or does disk/JSON work, move it off; if it is already off, say so with evidence. Do not change scoring, timing, latency compensation or scheduling horizon.
6. No new UI text. No change to which kit is chosen for which lesson (`SoundKitResolver` stays as it is).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Audio/AudioEngine.swift` (esp. `prepare`, `loadKits`, `selectKit`, `playOnQueue`), `SmackAPad/Sources/Audio/SoundKitResolver.swift`, `SmackAPad/Sources/UI/PracticeSession.swift` (lines ~150–160, ~335–345, ~520–580, ~780–790, ~880–895, ~1091), `SmackAPad/Sources/Calibration/CalibrationSession.swift` (lines ~20–80), `SmackAPad/Sources/MIDI/MIDIInput.swift` (callback to sound only), `SmackAPad/Resources/Data/sample-kits.json`.

## Measurements (required, report before/after)

Add debug-only log lines (like ticket 121): `[Audio] prepare … ms`, `[Audio] kit <id> loaded … ms`, and resident memory after opening a lesson (`task_vm_info` phys_footprint). Jakub runs the same sequence before and after on his iPad (A16): open a lesson, leave, open another with a different kit, open one with the same kit, start calibration. Give the numbers in the report. Simulator numbers do not count.

## Acceptance criteria

- [ ] Only the selected kit is decoded; memory after opening a lesson is clearly lower than before (numbers).
- [ ] Opening a lesson with an already loaded kit does not decode again (log shows no load).
- [ ] No two full engines are prepared at once; calibration works as before.
- [ ] Sound, metronome and pad hits behave exactly as before (no change in timing or scoring).
- [ ] Build succeeds; existing tests pass; add small tests for the cache (loads one kit only, reuses it, falls back to `acoustic`).
- [ ] **iPad test (Jakub)**: lessons with at least three different kits, Listen and Play, MIDI pad hits, calibration, switching sound set in Settings between lessons.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: shared state across sessions plus real-time audio; a mistake shows up as silence or dropouts only on a device.

## Done rule

Stop after a successful build and passing tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad. Ticket 156 (route change during play) builds on this and starts only after this one is tested.

## Test result (Jakub, iPad A16, 2026-11-09)

Debug log, one sound kit decoded per lesson:

| Lesson | Kit | Kit load | `prepare` total | App footprint |
|---|---|---|---|---|
| 10001 | house | 9.6 ms | 240.4 ms | 128.4 MiB |
| 10003 | rock | 70.5 ms | 161.6 ms | 162.5 MiB |
| 10004 | 808 | 10.3 ms | 110.2 ms | 132.8 MiB |
| 10005 | 808 (again) | none (cached) | 104.7 ms | 137.4 MiB |

Previously estimated ~290 MB for samples alone (all 8 kits decoded per lesson). Jakub checked sound, pad hits, calibration and sound-set switching on the iPad: all fine. Ticket closed.
