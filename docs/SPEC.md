# Smack-a-Pad iPad — v1 Specification

> Source documents: AGENTS.md, LEGACY-NOTES.md, CONTEXT.md, DECISIONS.md.

---

## 1. Goals

- Full-feature native SwiftUI iPad app replacing the JS/Capacitor prototype.
- Lesson library (547 core + 24 intro + electronic-path + genre-extensions), play screen, scoring, calibration, 9 bundled sample kits.
- External MIDI controller is the primary input (CoreMIDI). On-screen pads are a bonus.
- Czech + English localisation. Czech primary.
- iPadOS 17+, iPad-only.

## 2. Non-goals

- iPhone support.
- Visual design / UI polish (separate phase).
- Content pack distribution mechanism (v2+).
- iCloud sync, haptics, practice statistics (v2+).
- App Store submission (TestFlight first; license audit is a separate task).

---

## 3. Architecture — Modules

### 3.1 MIDI Input
- Native CoreMIDI. Mach timestamps used directly.
- BLE detection: if timestamp is >250 ms stale or >50 ms in the future relative to receipt time, fall back to receipt time.
- Controller profile: mapping table from MIDI note numbers → padIndex (0–15).
- MIDI learn: user presses each pad, app builds a custom profile.
- Ship 2–3 preset profiles (Akai MPD, NI Maschine, TBD).

### 3.2 Audio
- `AVAudioEngine` with `AVAudioSession` category `.playback`, latency hint `.interactive`.
- 9 bundled sample kits, each with named voices and optional velocity variants (WAV files).
- Metronome click for calibration and practice.

### 3.3 Lesson Data
- JSON files copied from legacy unchanged: `lessons-core.json` (547), `intro.json` (24), `electronic-path.json`, `genre-extensions.json`, `sample-kits.json`.
- Schema per lesson: `{id, cat, title, genre, tags, text, division, bars, startBpm, targetBpm, level, score, src, hits}`.
- `hits`: array of `[step, padIndex, hand, velocity]`. `step` is 0-based sixteenth index. `padIndex` is 0–15.
- `division` is always 16. `bars` is 1, 2, or 3.
- Architecture supports loading from multiple sources (bundled + external JSON) for future content packs.

### 3.4 Scoring
- See §5 for exact rules.

### 3.5 Calibration
- 10-click guided procedure: metronome at 1 s intervals, user taps along.
- Ground-truth clock: `AVAudioSession` output timestamp.
- Result: signed per-device offset (median-based, capped ±200 ms).
- Stored per device (keyed by MIDI device identifier).
- Acceptance thresholds must be significantly looser than legacy (legacy failed >50% of the time).

### 3.6 Persistence
- **Settings** → `UserDefaults`: kit selection, BPM step, MIDI profiles, calibration offsets.
- **Progress** → JSON file in Documents: per-lesson `{passed, mastery, currentBpm, bestScore}`.
- **User sample kits** → audio files in Documents + JSON manifest.
- No Core Data / SwiftData. Clean keyspace.

### 3.7 Progression
- Categories: starter, eighth, sixteenth, electronic, ghost, swing, world, fills.
- First category (starter) is unlocked by default.
- **Unlock rule**: passing **5 lessons** in the current category unlocks the next category. This is a configurable constant (`kLessonsToUnlock = 5`).
- **Soft unlock**: user can tap any locked category, confirm, and unlock it immediately. Nobody gets stuck.
- Intro (24 exercises): separate section, always accessible, no unlock needed.
- Electronic-path lessons are folded into the main category/genre system.

### 3.8 Screens
- **Library**: browse lessons by category/genre. Locked categories shown with lock icon + soft-unlock tap.
- **Play screen**: clean, eyes-off design. Optional small pad-layout thumbnail (user setting). Pattern display shows pad names, not a visual grid. Current BPM, score feedback, timing feedback.
- **Calibration**: guided 10-click flow per device.
- **Settings**: kit selection, BPM step (1/2/5/10), controller profile management, MIDI learn, language.
- **Intro section**: separate entry point for the 24 intro exercises.

---

## 4. Data Formats

### 4.1 Lesson JSON
```
{id: Int, cat: String, title: String, genre: String, tags: [String],
 text: String, division: 16, bars: 1|2|3, startBpm: Int, targetBpm: Int,
 level: 1–5, score: Float, src: String,
 hits: [[step: Int, padIndex: 0–15, hand: "L"|"R", velocity: 0–127]]}
```

### 4.2 Sample Kit JSON
```
{kitId: {name: String, license: String,
  voices: {voiceName: [{url: String, variants: [String]}]}}}
```

### 4.3 Progress JSON
```
{lessonId: {passed: Bool, mastery: Bool, currentBpm: Int, bestScore: Float}}
```

### 4.4 Controller Profile
```
{profileName: String, noteMap: {midiNote: padIndex}, padCount: 8|16}
```

---

## 5. Scoring Rules — Exact Numbers

### 5.1 Timing Windows (level-dependent)

| Level | Perfect | Good | Max (miss beyond this) |
|-------|---------|------|------------------------|
| 1–2   | ±45 ms  | ±100 ms | ±200 ms |
| 3–4   | ±38 ms  | ±85 ms  | ±175 ms |
| 5     | ±30 ms  | ±70 ms  | ±150 ms |

The scoring window is symmetric around the expected note time.

### 5.2 Latency Compensation — Single Point of Truth

**Calibration offset is the ONE place where latency is compensated.** The calibration procedure inherently measures the total round-trip offset — the sum of MIDI input delay, audio output latency, speaker latency, and human perception. It produces a single signed offset that is applied to all incoming MIDI timestamps before scoring.

**`AVAudioSession.outputLatency` + `ioBufferDuration`**: used exclusively for **scheduling audio playback** (metronome clicks, sample triggering) so that the sound reaches the speaker at the intended musical moment. It is NOT added to the scoring window. Adding it to scoring would double-count the latency that calibration already captured.

**Adaptive timing center** (rolling median, window of 8 samples, gated ±100–110 ms): shifts the scoring window at runtime to follow systematic player drift. Does not widen the windows.

**Summary of timestamp flow:**
1. Raw MIDI timestamp arrives (mach time; or receipt time for BLE fallback).
2. Subtract calibration offset → corrected timestamp.
3. Subtract adaptive timing-center shift → final timestamp used for window comparison.

### 5.3 Pass & Mastery

- **Pass**: score ≥ 70% (non-intro), ≥ 80% (intro).
- **Mastery**: clean run at or above `targetBpm`.
- **Clean run error limits**:

| Total expected hits | Allowed errors |
|---------------------|----------------|
| ≤ 15                | 0              |
| 16–32               | 1              |
| > 32                | 2              |

Intro lessons always require 0 errors for mastery.

### 5.4 Double-Hit Guard

A second hit on the same pad within **30 ms** of a previously matched hit counts as a wrong pad, not a second match.

### 5.5 BPM Auto-Progression

After a clean run below `targetBpm`, tempo increases by the user-selected step: **1, 2, 5, or 10 BPM**.

---

## 6. 8-Pad Controller Rule

Lessons use `padIndex` 0–15. An 8-pad controller maps to only 8 of these indices.

**Rule: filter, not remap.** When an 8-pad controller profile is active:
- The lesson library marks each lesson as **playable** or **not playable** based on the user's current profile.
- A lesson is **playable** if every `padIndex` that appears in its `hits` array is present in the active controller profile's `noteMap`.
- **Not-playable lessons** are shown greyed-out with a label ("requires 16 pads") but remain visible — not hidden. The user can still open them (they just can't be scored).
- Progression counts (category unlocks, pass/mastery) only require playable lessons. A user is never blocked from unlocking categories because unplayable lessons exist.
- If the user switches to a 16-pad profile, all lessons become playable immediately.

---

## 7. Acceptance Criteria per Module

### MIDI Input
- [ ] CoreMIDI receives note-on/off from a connected USB controller.
- [ ] BLE fallback triggers when timestamp is >250 ms stale or >50 ms future.
- [ ] Controller profile correctly maps note numbers to padIndex.
- [ ] MIDI learn builds a working profile from user input.
- [ ] **iPad test**: USB and BLE controllers both register hits.

### Audio
- [ ] All 9 sample kits load and play with <15 ms trigger-to-sound latency.
- [ ] Correct voice selected per padIndex.
- [ ] Velocity variants triggered appropriately.
- [ ] Metronome plays at correct tempo.
- [ ] **iPad test**: audio output latency is acceptable; no audible glitches.

### Lesson Data
- [ ] All 547 core + 24 intro lessons load from bundled JSON.
- [ ] Electronic-path and genre-extension lessons load and appear in correct categories.
- [ ] Invalid or missing JSON produces a clear error, not a crash.

### Scoring
- [ ] Timing windows match §5.1 exactly for each level.
- [ ] Calibration offset applied once (not double-counted with outputLatency).
- [ ] Adaptive timing center shifts window correctly.
- [ ] Double-hit guard prevents re-matching within 30 ms.
- [ ] Pass/mastery thresholds match §5.3.
- [ ] BPM auto-progression fires after clean run below targetBpm.
- [ ] **iPad test**: scoring feels fair and matches player perception.

### Calibration
- [ ] 10-click procedure completes successfully >90% of the time for a normal human.
- [ ] Produces a signed offset capped ±200 ms.
- [ ] Stored per device; survives app restart.
- [ ] **iPad test**: calibration with USB controller, BLE controller, and on-screen pads.

### Persistence
- [ ] Progress JSON saves and loads correctly across app restarts.
- [ ] Settings persist in UserDefaults.
- [ ] No data loss on normal app lifecycle (background, terminate, relaunch).

### Progression
- [ ] First category unlocked by default.
- [ ] Next category unlocks after 5 passed lessons in current category.
- [ ] Soft unlock works with single tap + confirmation.
- [ ] 8-pad users can unlock categories without needing 16-pad lessons.
- [ ] Intro section always accessible.

### Screens
- [ ] Library shows all categories, genres, pass/mastery status.
- [ ] Play screen displays pattern, current BPM, timing feedback.
- [ ] Settings screen allows kit, BPM step, profile, and language changes.
- [ ] **iPad test**: all screens render correctly on iPad, landscape and portrait.

---

## 8. Items Requiring Real-iPad Test by Jakub

These items cannot be verified in the simulator and must be tested on a physical iPad:

1. **USB MIDI controller** — hit registration, timestamp accuracy, MIDI learn.
2. **BLE MIDI controller** — hit registration, BLE timestamp fallback.
3. **Audio output latency** — whether trigger-to-sound is acceptable.
4. **Calibration** — full 10-click flow with USB, BLE, and on-screen pads.
5. **Scoring feel** — whether timing windows feel fair during actual play.
6. **Sample kit audio** — all 9 kits play correctly, no glitches or pops.
7. **On-screen pads** — touch response and latency.

Everything else (data loading, persistence, progression logic, UI layout) can be verified in simulator or unit tests.

---

## 9. Open Questions (Remaining)

1. **Controller preset profiles** — Which 2–3 controllers get built-in profiles? Need to confirm the most common devices among finger-drumming players.
2. **Calibration thresholds** — Exact loosened parameters (MAD multiplier, acceptance spread) to be determined during implementation and tested on real hardware.
3. **Sample license audit** — Each kit's LICENSE.txt must be reviewed before App Store submission. Separate task, does not block development.
4. **Content pack format** — Exact format and loading mechanism for future extension packs. v2+ decision.
5. **cs.tsv completeness** — Whether legacy Czech translations cover all strings needed, or if new strings need translating.
