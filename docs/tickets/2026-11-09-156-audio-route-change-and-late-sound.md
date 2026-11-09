# 156 — Audio route change stops the run cleanly; one late sound does not end the run

Status: approved by Jakub 2026-11-09 (Option 1 chosen in section B), ready for the agent. Blocked by: 155 (tested 2026-11-09, done). Source: AI panel findings #12 and #21 (`docs/reviews/ai-panel/results/synthesis.md`; `round1-claude.md` R1-06, R1-07; plan: `docs/2026-11-08-ai-panel-action-plan.md`, batch 3). Next: ticket 157.

## Problem (read from the code, 2026-11-09)

1. **Route change silences a running lesson, scoring goes on.** `AudioEngine.observeSession()` reacts to `routeChangeNotification` with `resumeAfterSessionChange()` (`AudioEngine.swift` ~824–846): it stops all players and restarts the engine. Its own comment says "the caller restarts the click sequence", but nothing tells `PracticeSession`. Plugging or unplugging headphones (wired, USB-C, Bluetooth) during a run therefore leaves a silent run (no metronome, no pattern) while hits are still scored. The same applies to an interruption that begins (Siri, call, alarm): `interruptionNotification` stops the players and pauses the engine, and again the run carries on silently.
2. **Calibration ignores the output route.** `calibrationOffset(for: deviceID)` (`Persistence.swift` ~658) is keyed by the *input* only (MIDI source id, "touch", "keyboard"). Built-in speaker, wired and Bluetooth output have very different latency, but they share one stored offset. After a route change the old offset is wrong.
3. **One late sound ends the whole run.** `PracticeSession` (~999–1007) passes an error callback to `audio.schedule`; any error calls `stop()`. `AudioEngine.schedule` (~392–409) sets `schedulingFailed = true` after the first error and then ignores every later sound until reset (~359). `renderTime` throws `insufficientLeadTime` when a sound is scheduled too late (~584–587), e.g. after a main-thread stall of about half a second (sheet, save, badge). The metronome path (`scheduleMetronome`, ~600–615) already skips late beats instead; the pattern path does not.

## Rules

### A. Route change and interruption (finding #12)

1. `AudioEngine` publishes an event when the output route really changes (reasons `newDeviceAvailable`, `oldDeviceUnavailable`, `override`, `routeConfigurationChange`, and others except `categoryChange`, which stays ignored as today) and when an interruption **begins**. Deliver it on the main actor to the owner of the engine (shared engine from ticket 155), so the active `PracticeSession` can react. Keep the audio queue free of main-actor waits.
2. When this event arrives **while a run is active** (Listen or Play), `PracticeSession` stops the run through its normal stop path (no star, no tempo, no review result gained or lost by the aborted run, exactly like pressing STOP) and shows **one short message** through the existing error/message mechanism. Wording (both languages, via `settings.localized`, no other new UI text): EN "Audio output changed. Run stopped, press Start to continue." / CS "Zvukový výstup se změnil. Běh se zastavil, pokračuj tlačítkem Start." For an interruption the same message is fine. The agent may shorten it but must not add more text or new UI elements.
3. After the stop the engine must be running again on the new route (as `resumeAfterSessionChange` does today), so the next Start works without leaving the lesson. If it cannot restart, the existing failure path is used.
4. A route change while **not running** (library, stopped lesson) shows nothing. Calibration in progress keeps its present behaviour (`clockChanged`); do not change calibration maths or its flow.
5. Do not change scoring, timing, latency compensation or the scheduling horizon.

### B. Calibration and output route (finding #12, second half) — DECIDED: Option 1 (Jakub, 2026-11-09)

Implement Option 1. Options 2 and 3 are kept only as the record of what was rejected:

- **Option 1 (CHOSEN): store the offset per input *and* output route type** (built-in speaker / wired or USB / Bluetooth / other). Key e.g. `"<inputId>|<routeType>"`. Reading falls back to the old single value for that input when no route-specific value exists, so nobody loses their calibration; writing always uses the new key. Nothing visible changes in the UI (the "Saved offset" line shows the value for the current route). No new text. Add a migration test. Medium size.
- **Option 2: no storage change, only a warning** when the current output is Bluetooth and calibration is used. Needs new UI text, which you do not want, so only if you prefer it.
- **Option 3: leave as is** and note it as a known limitation for the first App Store version.

### C. Late sound (finding #21)

1. In `AudioEngine.schedule`, a sound that cannot be scheduled because it is late (`Failure.insufficientLeadTime`, and `voiceLimit` if the agent judges it equally harmless) is **skipped**, not fatal: the loop continues with the next sound and `schedulingFailed` is not set. Log a debug line `[Audio] late sound skipped` with a running count.
2. Stop the run only after **repeated** failures: more than 3 skipped sounds within one pass (`PracticeSession` already tracks passes) or when the engine itself is not running. All other errors (`notRunning`, `notPrepared`, `invalidPad`, manifest/voice errors) behave as today (stop with message).
3. The skipped sound is simply not heard; scoring is by time and is not touched. Put the skip/stop policy in a small pure type that can be unit-tested with a fake clock.
4. Keep the existing "never bunch missed beats" behaviour of the metronome.

## Files to read

`AGENTS.md`, this ticket, ticket 155 (`docs/tickets/2026-11-09-155-*.md`), `SmackAPad/Sources/Audio/AudioEngine.swift` (`observeSession`, `resumeAfterSessionChange`, `schedule`, `renderTime`, `scheduleMetronome`), `SmackAPad/Sources/Audio/AudioSessionOwnership.swift`, `SmackAPad/Sources/UI/PracticeSession.swift` (~150–160, ~720–740, ~925–1010), `SmackAPad/Sources/Calibration/CalibrationSession.swift`, `SmackAPad/Sources/Persistence/Persistence.swift` (~250–260, ~650–670), `docs/tickets/2026-11-03-54-bluetooth-midi-timing.md` (earlier Bluetooth timing work).

## Acceptance criteria

- [ ] Plugging/unplugging headphones (wired/USB-C and Bluetooth) during a run stops the run with the one short message; Start works again on the new route; no star/tempo/review credit is changed by the aborted run.
- [ ] An interruption (Siri/alarm/call) during a run does the same.
- [ ] No message and no stop when the route changes outside a run.
- [ ] A single late pattern sound is skipped and the run continues; four or more late sounds in one pass stop the run with the message as today.
- [ ] Decision B implemented as chosen (Option 1: offsets per route type with fallback and migration test).
- [ ] Build succeeds; existing tests pass; new unit tests: late-sound policy, route-reason mapping (categoryChange ignored), offset key/fallback (Option 1).
- [ ] Sound, metronome, pad hits, scoring and calibration behave exactly as before in normal play.
- [ ] **iPad test (Jakub)**: Play and Listen with built-in speaker; plug in USB-C/wired headphones mid-run; connect and disconnect Bluetooth headphones mid-run; trigger Siri mid-run; start again after each; calibration still works; with Option 1 calibrate on speaker and on headphones and check both values are kept.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: asynchronous audio-session events crossing the audio queue and the main actor; mistakes appear only on a device as silence or a stuck Start.

## Done rule

Stop after a successful build and passing tests. Commit (AGENTS.md); Jakub pushes and tests on the iPad. Ticket 157 starts after this one is tested.

## Test result (Jakub, iPad A16, 2026-11-09)

Tested on the iPad per the acceptance list (route changes during a run, interruption, calibration per route): all passed. Ticket closed.
