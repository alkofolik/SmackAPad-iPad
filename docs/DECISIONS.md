# Decisions

All decisions from the grilling session (2026-10-30).

---

## 1. v1 scope: full feature parity

v1 is the first full native SwiftUI iPad app, replacing the legacy JS/Capacitor prototype. It must cover everything the prototype could do: lesson library, play screen, scoring, calibration, sample kits, localisation. No features are intentionally cut from what the prototype offered.

## 2. Pad layouts: 16-pad and 8-pad

The app supports two pad layouts: 4×4 (16 pads) and 2×4 (8 pads). All lessons use padIndex 0–15. Controller profiles map MIDI note numbers to padIndex values (16-pad mode) or to physical slots 0–7 (8-pad mode). Users can create custom mappings (MIDI learn). Ship 2–3 preset profiles for common controllers (Akai MPD, NI Maschine, etc.).

**8-pad mode (revised 2026-10-30 after reading the legacy prototype):** no lesson filtering. As in the legacy app, the 8 physical pads are assigned per lesson to the sounds that lesson needs (`layoutForEight`), and 6 lessons that use 9 pads carry a simplified `hits8` version. All 587 bundled lessons are playable in 8-pad mode. Details: SPEC §6.

**Canonical pad-to-voice mapping (confirmed by Jakub, 2026-10-30):** the array index is `padIndex` (0–15). Source supplied by Jakub: the original prototype's `app/v21/src/core.js`, `LAYOUT`.

```json
["tomHi", "tomLo", "crash", "ride", "shaker", "wood", "cowbell", "openHat", "hat", "clap", "rim", "hat", "kick", "snare", "snare", "kick"]
```

Paired pads 8/11 (hat), 12/15 (kick), and 13/14 (snare) share their sound and differ only by hand. `AudioEngine.defaultPadVoices` implements this mapping. In eight-pad mode, resolve the physical controller slot through the current lesson's layout before sending the resulting `padIndex` to the audio engine.

## 3. Play screen: clean, eyes-off design

The play screen prioritises minimal distraction. The player should not need to stare at the screen while playing. The pad layout diagram is optionally shown as a small thumbnail or hidden entirely (user setting). The pattern itself is always shown as a grid (see SPEC §3.8): the player does look at the screen to know what to play, so everything around the pattern is minimal and hidden behind one touch.

## 4. CoreMIDI: native timestamps, no JS hacks

Use native CoreMIDI with mach timestamps directly. No JS bridge, no clock-sync workarounds. For BLE controllers: detect unreliable timestamps (>250 ms stale or >50 ms in the future) and fall back to message receipt time. Same logic as legacy, implemented natively in Swift.

## 5. Lesson data: keep legacy schema unchanged

The lesson JSON schema (`id, cat, title, genre, tags, text, division, bars, startBpm, targetBpm, level, score, src, hits[]` where hits = `[step, padIndex, hand, velocity]`) is carried over exactly. JSON files retain the legacy schema without field renaming or conversion. Ticket 20 removes eight Intro duplicates from lessons-core.json (539 remaining; starter lesson 6 is retained); the other data files remain unchanged. On load, retired progress merges into the specified Intro targets without lowering stars or best score, and keeps an existing target tempo. The consumed old records make the migration idempotent.

## 6. Scoring: carry over 1:1 with one addition

All scoring rules from the legacy prototype are preserved exactly:

- Timing windows by level: L1–2 ±45/100/200 ms, L3–4 ±38/85/175 ms, L5 ±30/70/150 ms.
- Mastery error limits: ≤15 hits → 0 errors, 16–32 → 1, >32 → 2. Intro always 0.
- Pass threshold: ≥70% (non-intro), ≥80% (intro).
- Double-hit guard: 30 ms.
- BPM auto-progression step: **1, 2, 5, or 10 BPM** (user-selectable). The 10 BPM option is new.

## 7. Philosophy of tolerance

The app tolerates human imperfection. It accepts human groove and swing. If you can't hear the difference, the app shouldn't penalise it. Single-millisecond precision is irrelevant. This philosophy applies to calibration, scoring, and all timing logic.

### Scoring percentage and feedback (ticket 08, confirmed 2026-10-30)

The score is `matched hits / (expected hits + extra hits)`, stored as a fraction
from 0 to 1. For display, multiply by 100. For example, 8 matches out of 10
expected hits plus 2 extra hits produce `8 / 12`, or approximately 66.7%.
Every matched hit within the maximum timing window counts equally, without
accuracy weights. Timing feedback uses `perfect`, `good`, and `off`: `off`
means outside the good window but still inside the maximum window. Misses
remain in the expected-hit denominator; unmatched input, including a guarded
double hit, is extra input. This formula is a new decision, not a recovered
legacy rule, and applies to subsequent scoring and play-screen tickets.

## 8. Calibration: keep but soften

The 10-click guided calibration is kept (per-device signed offset, median-based, capped ±200 ms). However, the acceptance thresholds must be significantly loosened — the legacy calibration failed >50% of the time due to overly strict outlier rejection. The calibration must succeed for normal human tapping, not just robotic precision.

### Ticket 09 implementation (2026-10-30)

- Four audible count-in clicks, then ten measured clicks, one second apart.
- Match each tap to the nearest actual output click within ±350 ms. A duplicate cannot claim another click; duplicates do not cause rejection.
- Require at least 6 usable taps. Robust spread is 1.4826 × MAD, limited to 80 ms. Drop deltas outside max(60 ms, 3 × robust spread) from the median; compute the rounded signed median of the remaining deltas and clamp to ±200 ms. No hard start-to-end drift limit.
- Store only accepted results in `calibrationOffsets`, keyed by the CoreMIDI device identifier or `touch`. Cancellation, missing output records, disconnection, interruption, and audio clock changes preserve the previous settings.
- These are initial hardware-validation thresholds. The >90% human success target remains unverified until Jakub tests USB, BLE, and touch on iPad.

## 9. Adaptive timing center: keep as-is

The rolling-median timing center (window of 8 samples, gated ±100–110 ms) is kept. It shifts the scoring window at runtime to follow systematic player drift without widening the windows. Implemented natively in Swift.

## 10. Audio engine: AVAudioEngine

Use `AVAudioEngine` with `AVAudioSession` category `.playback` and a short preferred I/O buffer duration (the native equivalent of the web `.interactive` hint). Playback scheduling and calibration observation share the engine's mixer presentation-latency model. Never add output latency to scoring or the calibration offset. The I/O buffer duration is only a scheduling safety margin; the session-output-plus-buffer sum is diagnostic only.

`AVAudioSession` does not expose the web `getOutputTimestamp` API. Calibration detects click onsets in a mixer audio tap and uses the buffer's rendered `AVAudioTime` host timestamp, plus the mixer's current `outputPresentationLatency`, to obtain the hardware-reported presentation time. This conversion is inside the audio adapter; tap-minus-output analysis receives no output-latency argument. Callback receipt time and the intended schedule are never timing anchors. This is hardware-reported timing, not microphone measurement of acoustic speaker propagation. See Apple's [audio tap API](https://developer.apple.com/documentation/avfaudio/avaudionode/installtap(onbus:buffersize:format:block:)) and [output presentation latency](https://developer.apple.com/documentation/avfaudio/avaudionode/outputpresentationlatency).

During calibration, route/configuration changes, media service loss, interruptions, sample-rate changes, non-monotonic sample timestamps, presentation-latency changes over 2 ms, or a render-clock mapping shift over 2 ms invalidate the run. Practice is suspended while MIDI settings are open so the calibration owns the audible clicks and input callbacks.

### Ticket 09 follow-up: one audible clock and shared session ownership

**Decision: use the calibration presentation model for practice scheduling too.** Apple's [node presentation-latency contract](https://developer.apple.com/documentation/avfaudio/avaudionode/outputpresentationlatency) describes the downstream render pipeline, whereas the session properties describe the device and buffer. The APIs do not guarantee that `mainMixerNode.outputPresentationLatency` (P) equals `session.outputLatency + ioBufferDuration` (S) across our supported routes. This is a conclusion from the contracts, not a measurement of an iPad.

Previously, scheduling an intended audible beat T at T − S while observing it at render time + P made its audible time T + (P − S). Practice still scored against T. `AudioOutputTiming` now implements both directions: scheduling at T − P and observing rendered onset R at R + P. The audio adapter uses this model for lesson samples, practice/count-in clicks, calibration clicks, and the standalone metronome. Practice scoring continues to use intended audible beat times without any extra correction; calibration analysis, thresholds, offsets, and scoring windows are unchanged. Unknown presentation latency fails explicitly instead of falling back to S.

Temporary DEBUG-only messages print S, P, and P − S at calibration sequence start/end and practice start. Disable all output using `AudioTimingDiagnostics.enabled` in one file; remove the temporary logger after iPad validation. An end message is emitted once when a started calibration capture is stopped, including cancelled/failed/closed/backgrounded runs. Preparation failures before a capture exists have no started sequence to end. No values or equality claims have been verified on hardware.

**Session rule:** separate engines retain separate graphs, but `AudioSessionOwnership` serializes access to the process-wide AVAudioSession. Every engine has one stable owner ID. Starting reasserts activation (also after system interruptions); repeating a start cannot create another ownership entry. Stop and deinit stop that engine before releasing its ownership. Only release of the last registered owner may deactivate the shared session; repeated release is harmless. Failed engine startup/restart stops its graph and releases its ownership. This prevents calibration completion followed by late view cleanup from deactivating an already resumed practice engine. See Apple's [deactivation behavior with running audio objects](https://developer.apple.com/documentation/avfaudio/avaudiosession/setactive(_:options:)).

Two new hardware-independent tests were written before implementation and passed individually: audible-time conversion (including unavailable timing), and overlapping ownership/repeated cleanup/background-style release and reacquisition. Previously passing tests were not rerun. Actual AVAudioSession activation, AVAudioEngine restart, physical output timestamps, and audible metronome/sample recovery cannot be established by these pure tests and remain manual iPad checks in ticket 09.

## 11. Persistence: simple, no database

- **Settings** → `UserDefaults` (kit selection, BPM step, MIDI profiles, calibration offsets).
- **Progress** → JSON file in app Documents (per-lesson: passed, mastery, current BPM, score).
- **User sample kits** → audio files in Documents directory + JSON manifest.

No Core Data, no SwiftData. Clean keyspace — no legacy prefixes like `padofill.full.course.*`.

## 12. iPadOS 17 minimum, iPad-only

Minimum deployment target: iPadOS 17. This gives access to `@Observable` macro and modern SwiftUI APIs. iPad-only (no iPhone). In 2026, iPadOS 17 is 3 years old — reasonable coverage.

## 13. Sample kits: all 8 bundled

All 8 legacy sample kits are bundled in the app: acoustic, 808, jazz, world, rock, brush, worldperc, house. They are built from 7 WAV folders (acoustic, 808, brush, house, rock, virtuosity, worldperc); jazz, world and worldperc reference WAV files from other folders. The full manifest is `app/v21/data/2026-10-04-sample-kits.json` in the legacy project (371 unique WAVs, all present). No downloading — all included in the app bundle. (Corrected 2026-10-30: earlier text said 9 kits.)

## 14. Sample licenses: TestFlight first, review before App Store

Sample kit licenses (AVL Acoustic, Fischer 808, Groove MIDI Dataset, etc.) have not been verified for commercial redistribution. This does not block development. v1 starts on TestFlight / personal use. Before any App Store submission, every kit's LICENSE.txt must be reviewed. Kits with unclear licenses are replaced or removed. This is a separate task.

## 15. Lesson progression: guided but not blocking

Ticket 19 replaces category access with the legacy Path: five levels, split by technique (levels 4–5 omit basic groove), with empty stages omitted. A stage opens after `min(ceil(previous stage lesson count / 2), 10)` two-star completions (`passed && mastery`; memory optional, ticket 21) in its immediate predecessor, or if any lesson in the stage was already played. The first stage and the separate Intro entry point are always accessible. Jersey club and Footwork remain accessible extensions outside the Path.

**Soft unlock**: the stage banner is the only unlock surface, with inline Yes/Cancel confirmation; purely manual unlocks may be undone while the stage has no stars and no played, earned or migration-snapshot access (ticket 25B). Path, Genres, and Techniques share this access policy. A one-time migration preserves stages containing lessons in previously accessible categories, including saved manual category unlocks and automatic category access; saved progress is retained. New progress records distinguish actual playing from merely saving a tempo. Old records conservatively retain access when they contain saved tempo or results.

Ticket 21 preserves all previously open stages through a one-time migration and persists future stage openings; lessons without an 8-pad layout are excluded from completion counts in 8-pad mode.

Library organisation and multi-select star filters are remembered. “Next lesson from” selects Path, Genre, Technique, or All (easiest first), following legacy candidate order, wraparound, and fallback to Path.

## 16. Intro: separate, always accessible

The 25 projected Intro exercises are a separate section, always accessible (no unlock needed); ticket 25B moves core lesson 6 to the end of Control and detail (65 → 100 BPM), excludes it from Library/Path, and removes First steps without changing bundled data or saved IDs. Recommended as a starting point for beginners but never forced. Stricter pass threshold (80%) and 0 errors for mastery.

## 17. Electronic path: integrated, not separate

Electronic-path lessons are folded into the main category/genre system alongside other genres. They are not a separate linear progression.

## 18. Content packs: architecture ready in v1

Genre extensions are not included in v1. However, the lesson-loading architecture must support multiple sources (bundled + externally loaded JSON). This prepares for future paid content packs. The specific distribution mechanism (In-App Purchase, import, server) is a v2+ decision.

## 19. Localisation: Czech + English

Czech and English. Reuse the legacy `cs.tsv` translation file (convert to the appropriate Swift localisation format). Czech is the primary language.

## 20. Visual design: separate phase

Visual design, styling, and UI polish are explicitly out of scope for this decision phase. They will be handled in a dedicated design phase.

---

## Open questions

1. **Stage unlock criteria** — Resolved by ticket 19; see §15.
2. **Controller preset profiles** — Which 2–3 controllers get built-in profiles? Need to confirm the most common devices among finger-drumming players.
3. **Calibration thresholds** — Initial values are recorded in §8 (ticket 09); success-rate validation and any tuning on real hardware remain open.
4. **Sample license audit** — Each kit's LICENSE.txt must be reviewed before App Store submission. Separate task.
5. **Content pack format** — Exact format and loading mechanism for future extension packs. v2+ decision.
6. **cs.tsv completeness** — Whether the legacy Czech translations cover all strings needed for the native app, or if new strings need translating.

---

## v2+ ideas (not in v1)

- Haptic feedback on pad strikes.
- iCloud sync of progress across devices.
- Practice statistics (session history, time spent, most-played lessons).
- Additional content packs (genre extensions, new lesson sets).
- Content pack distribution mechanism (IAP, download, import).
