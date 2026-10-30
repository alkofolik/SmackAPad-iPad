# Decisions

All decisions from the grilling session (2026-10-30).

---

## 1. v1 scope: full feature parity

v1 is the first full native SwiftUI iPad app, replacing the legacy JS/Capacitor prototype. It must cover everything the prototype could do: lesson library, play screen, scoring, calibration, sample kits, localisation. No features are intentionally cut from what the prototype offered.

## 2. Pad layouts: 16-pad and 8-pad

The app supports two pad layouts: 4×4 (16 pads) and 2×4 (8 pads). All lessons use padIndex 0–15. Controller profiles map MIDI note numbers to padIndex values (16-pad mode) or to physical slots 0–7 (8-pad mode). Users can create custom mappings (MIDI learn). Ship 2–3 preset profiles for common controllers (Akai MPD, NI Maschine, etc.).

**8-pad mode (revised 2026-10-30 after reading the legacy prototype):** no lesson filtering. As in the legacy app, the 8 physical pads are assigned per lesson to the sounds that lesson needs (`layoutForEight`), and 6 lessons that use 9 pads carry a simplified `hits8` version. All 595 bundled lessons are playable in 8-pad mode. Details: SPEC §6.

## 3. Play screen: clean, eyes-off design

The play screen prioritises minimal distraction. The player should not need to stare at the screen while playing. The pad layout diagram is optionally shown as a small thumbnail or hidden entirely (user setting). Pattern display shows pad names, not a visual grid.

## 4. CoreMIDI: native timestamps, no JS hacks

Use native CoreMIDI with mach timestamps directly. No JS bridge, no clock-sync workarounds. For BLE controllers: detect unreliable timestamps (>250 ms stale or >50 ms in the future) and fall back to message receipt time. Same logic as legacy, implemented natively in Swift.

## 5. Lesson data: keep legacy schema unchanged

The lesson JSON schema (`id, cat, title, genre, tags, text, division, bars, startBpm, targetBpm, level, score, src, hits[]` where hits = `[step, padIndex, hand, velocity]`) is carried over exactly. All JSON data files (lessons-core.json with 547 lessons, intro.json, electronic-path.json, genre-extensions.json, sample-kits.json) are copied from legacy as-is. No field renaming, no schema conversion.

## 6. Scoring: carry over 1:1 with one addition

All scoring rules from the legacy prototype are preserved exactly:

- Timing windows by level: L1–2 ±45/100/200 ms, L3–4 ±38/85/175 ms, L5 ±30/70/150 ms.
- Mastery error limits: ≤15 hits → 0 errors, 16–32 → 1, >32 → 2. Intro always 0.
- Pass threshold: ≥70% (non-intro), ≥80% (intro).
- Double-hit guard: 30 ms.
- BPM auto-progression step: **1, 2, 5, or 10 BPM** (user-selectable). The 10 BPM option is new.

## 7. Philosophy of tolerance

The app tolerates human imperfection. It accepts human groove and swing. If you can't hear the difference, the app shouldn't penalise it. Single-millisecond precision is irrelevant. This philosophy applies to calibration, scoring, and all timing logic.

## 8. Calibration: keep but soften

The 10-click guided calibration is kept (per-device signed offset, median-based, capped ±200 ms). However, the acceptance thresholds must be significantly loosened — the legacy calibration failed >50% of the time due to overly strict outlier rejection. The calibration must succeed for normal human tapping, not just robotic precision.

## 9. Adaptive timing center: keep as-is

The rolling-median timing center (window of 8 samples, gated ±100–110 ms) is kept. It shifts the scoring window at runtime to follow systematic player drift without widening the windows. Implemented natively in Swift.

## 10. Audio engine: AVAudioEngine

Use `AVAudioEngine` with `AVAudioSession` category `.playback` and `.interactive` latency hint. At startup (or after calibration), read `AVAudioSession.outputLatency` + `ioBufferDuration` and factor this into the scoring window. Do not attempt to measure acoustic speaker latency — that is what calibration is for.

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

Categories are locked by default (except the first). Completing a certain number of lessons in a category unlocks the next one. **Soft unlock**: any locked category can be manually unlocked with a single tap + confirmation. Nobody gets stuck. Experienced players can skip ahead freely.

## 16. Intro: separate, always accessible

The 24 intro exercises are a separate section, always accessible (no unlock needed). Recommended as a starting point for beginners but never forced. Stricter pass threshold (80%) and 0 errors for mastery.

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

1. **Category unlock criteria** — How many lessons must be completed to unlock the next category? A fixed count, a percentage, or specific key lessons? (To be decided during implementation.)
2. **Controller preset profiles** — Which 2–3 controllers get built-in profiles? Need to confirm the most common devices among finger-drumming players.
3. **Calibration thresholds** — The legacy calibration was too strict. Exact loosened parameters (MAD multiplier, acceptance spread) to be determined during implementation and tested on real hardware.
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
