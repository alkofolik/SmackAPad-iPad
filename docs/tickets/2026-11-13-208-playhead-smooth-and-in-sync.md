# 208 — Playhead: no catch-up jumps, and proof that it matches the click

Status: implemented; Instruments comparison and manual iPad validation pending. Reported by Jakub on 2026-11-13: "the position marker does not move evenly, at moments it speeds up a lot; I'm not sure whether it keeps to the metronome." Sound from the iPad's built-in speaker.

## What a frame-by-frame measurement showed

Source: Jakub's screen recording (13:54, "Soul motown", 104 BPM, 1 bar, 28 s, 58 fps). The playhead x position was measured in all ~1500 frames and the metronome clicks were found in the recorded audio.

- **Speed is even almost everywhere.** Against ideal linear motion the playhead is within ±1 px (≈ 1 ms) for 26 s; its tempo comes out at 104.06 BPM.
- **One catch-up jump.** At 10.40–10.88 s the playhead lags by ≈ 14 ms (one display frame) for half a second, then jumps forward by about two frames' distance. The jump is what feels like "speeding up". Likely cause: `PracticeScreen.middleZone` samples the tape at `TimelineView(.animation(minimumInterval: 1/60))`'s `date`, and `patternFrame(at:)` falls back to "now" when that date is in the past. When the render pipeline shows frames one refresh later than planned, every frame is drawn for a moment that is already gone, until the pipeline recovers and the tape snaps forward.
- **Constant offset, no drift.** In the recording, clicks come ≈ 111 ms before the playhead reaches the beat line, steadily, from start to end (drift ≈ 0.1 ms/s, inside measurement noise). This does **not** prove a lag: the screen recorder captures sound when the app renders it, and the app renders each click `outputPresentationLatency` early so it is *heard* on the beat. So 111 ms is most likely that latency, not an error. Only a camera recording (rule 5) can tell what the player really sees and hears.

## Goal

The playhead moves without visible catch-up jumps, on 60 Hz and 120 Hz iPads, and we have a real measurement of whether line and click meet on the iPad speaker.

## Rules

1. **Use the `tdd` skill** (timing code, per `AGENTS.md`).
2. **Sample for the moment the frame appears.** Drive the practice tape from a display link (`CADisplayLink`, or SwiftUI's equivalent that gives the frame's target presentation time) and compute the tape position for `targetTimestamp`, converted to the same host seconds the audio schedule uses. Do not use the `TimelineView` date or "now at body time" for the tape. Delete the old sampling path (`patternFrame(at: Date)` fallback logic) once nothing uses it.
3. **No artificial frame cap.** Remove `minimumInterval: 1.0 / 60`; let ProMotion iPads draw at 120 Hz. Keep pausing when not running.
4. **Redraw only what moves.** Per frame update only the band (playhead, tape) and the parts of the HUD that really change per frame; the toolbar, pad legend, buttons and the rest of the middle zone must not rebuild 60–120 times a second. Measure with Instruments (SwiftUI / Hitches) before and after and write both numbers in the implementation notes.
5. **Measurement kit for Jakub (DEBUG builds only).** In the existing debug test menu add a "Timing readout" toggle. When on, the practice screen shows a small overlay: output route, `outputPresentationLatency`, `session.outputLatency`, `ioBufferDuration` (ms), display refresh rate, and the count of late frames in the current run. Jakub will film the iPad with an iPhone in slow motion (240 fps) at 104 BPM from the speaker and compare the click with the line crossing a beat line. Remove the old console-only `AudioTimingDiagnostics` print ("TEMPORARY ticket 09") and use the readout instead.
6. **Do not change** the audio schedule, scoring, calibration or the meaning of `passes` / `start`. This ticket only changes how the drawing samples time. If the slow-motion check later shows line and click more than 20 ms apart, that becomes a separate ticket.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/PracticeScreen.swift` (`middleZone`, `practiceBand`), `PracticeSession.swift` (`patternFrame(at:)`, `tapeFrame(seconds:)`, `clock`, `passes`), `PatternField.swift` (`ScrollingPattern`, `StaticPattern`, playhead drawing), `SmackAPad/Sources/Audio/AudioEngine.swift` (`outputTimingOnQueue`, `renderTime(for:)`), `AudioOutputTiming.swift`, `AudioTimingDiagnostics.swift`, `DebugTestMenu.swift`.

## Tests

1. Tape sampling: for a sequence of frame target times with one late frame, the drawn position at each frame equals the position for that frame's target time (no catch-up larger than elapsed time × speed).
2. A tempo change at a pass start keeps the position continuous (existing behaviour, keep or adapt the test).

## Acceptance criteria

- [x] Practice tape position is computed for each frame's target presentation time.
- [x] No frame-rate cap; 120 Hz on ProMotion devices (maximum refresh requested; physical-device check pending).
- [ ] Instruments numbers before/after in the notes; fewer views updated per frame.
- [ ] DEBUG timing readout works; old TEMP console diagnostics removed (implemented; manual overlay check pending).
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

- Play a 4-bar lesson for two minutes while hitting pads: the playhead never jumps or speeds up.
- Turn on Timing readout, note the values, film the iPad (speaker, 104 BPM) in iPhone slow motion and send the video: we will measure click vs line from it.

## Agent assignment

Codex GPT-6.1 Sol, thinking **high** (render timing and audio-clock alignment). Fallback: Gemini 3.8 Pro, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.

## Implementation notes — 2026-11-13

- `PracticeDisplayClock` receives `CADisplayLink.targetTimestamp` from the actual window's display. It converts the target's offset from `CACurrentMediaTime()` to native audio host seconds using `AVAudioTime.seconds(forHostTime:)`. Late callbacks retain their target; there is no Date fallback or target clamping. The audio schedule, scoring, calibration, passes and start times are unchanged.
- A single display link feeds separate leaf views for the band, run meter, timing cue and pass progress. The middle-zone layout, mix header, tempo label, tempo banner, toolbar, pad legend and buttons do not observe the per-frame sample. The After me label follows the session's repetition changes. The link requests the display's maximum refresh rate and is invalidated while stopped or off screen.
- DEBUG Settings → Developer → Test scenarios → Timing → Timing readout shows the route, mixer output presentation latency, session output latency, buffer duration, callback refresh rate and late-frame count. Audio values refresh once per second. The counter resets on each run and counts callbacks that arrive after their target or follow a missed refresh; it is a callback diagnostic, not a measurement of compositor presentation. All former TEMP ticket 09 console logging and its call sites are deleted.
- TDD: the new 60/120 Hz target-sequence test failed before the host-time sampling interface existed, then passed. It includes a late callback and a skipped refresh, and checks literal tape positions and the maximum elapsed-time advance. The existing tempo-transition test now samples both sides of the queued pass boundary before the scheduler crosses it; both selected tests passed.
- Validation: Debug and Release simulator builds succeeded. The full Debug suite on iPad (A16), iOS 27.0 Simulator passed: **285 tests, 0 failures**. `xcodebuild` exited successfully; no log-finalization stall occurred.
- Instruments before: **not measured**. Instruments after: **not measured**. The original Debug build succeeded and the SwiftUI / Animation Hitches templates are installed, but the iPad is offline and the computer-use interface cannot access Simulator. No comparable running-practice trace was obtained; the fewer-updates claim above describes observation boundaries in the code, not measured Instruments numbers. This acceptance criterion remains open. Capture matching runs with SwiftUI and Animation Hitches on the connected iPad before closing the ticket.
- Manual iPad checks remain as listed above. Also verify Timing readout in the debug menu, stop/restart resets its counter, After me phase labels still alternate, and a ProMotion device reports 120 Hz when the system permits it. The camera measurement of audible click versus beat crossing is still pending; no synchronization result is claimed from a screen recording or simulator.
