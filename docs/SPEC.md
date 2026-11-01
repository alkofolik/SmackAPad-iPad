# Smack-a-Pad iPad — v1 Specification

> Source documents: AGENTS.md, LEGACY-NOTES.md, CONTEXT.md, DECISIONS.md.

---

## 1. Goals

- Full-feature native SwiftUI iPad app replacing the JS/Capacitor prototype.
- Lesson library (547 core + 24 intro + electronic-path + genre-extensions), play screen, scoring, calibration, 8 bundled sample kits (acoustic, 808, jazz, world, rock, brush, worldperc, house).
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
- 8 bundled sample kits (jazz, world and worldperc reuse WAV files from other kit folders), each with named voices and optional velocity variants (WAV files).
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
- Path stages are grouped by level and technique; the first non-empty stage is always open (ticket 19).
- **Unlock rule**: `min(ceil(previous stage lesson count / 2), maximumStageCompletions)` lessons with `passed && mastery` (two stars) open the next stage; `maximumStageCompletions = 10`. Memory is optional. In 8-pad mode, lessons without a layout do not count. Previously open stages stay open, and any stage with an already played lesson is open (ticket 21).
- **Soft unlock**: user can tap any locked stage, confirm, and unlock it immediately. Nobody gets stuck.
- Intro (24 exercises): separate section, always accessible, no unlock needed.
- Electronic-path lessons are folded into the main category/genre system.

### 3.8 Screens
- **Library**: browse lessons by category/genre. Locked categories shown with lock icon + soft-unlock tap.
- **Play screen**: minimal chrome, pattern first. Pattern is the dominant element of the play screen and always visible: a grid with one row per used pad and one column per sixteenth step, count labels 1 e & a, beat starts emphasised. A hit is a cell carrying the pad abbreviation; the hand is shown by cell colour (white = right, black = left) and the currently playing cell is outlined. User-selectable modes: **static** (the whole pattern visible, a position marker moves) and **scrolling** (the pattern moves past a fixed hit marker). 1 bar = one block across the width; 2-4 bars = blocks stacked or 2x2 with the current bar emphasised; longer patterns and whole tracks = pages of 4 bars or scrolling, with a thin overview strip of the whole track. Everything else (score details, settings, section loop) is hidden but one touch or gesture away. The 4x4 pad-layout grid is hidden by default; a Settings option shows it small and unobtrusive in the lesson. Current BPM and score stay small and peripheral. There is no per-hit feedback: each bar gets a one-word verdict (clean / ahead / behind / uneven) in its header, and a small summary strip appears at the end. Details: `docs/design/2026-10-30-practice-screen-spec.md`.
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
{lessonId: {passed: Bool, mastery: Bool, memory: Bool, currentBpm: Int, bestScore: Float}}
```

### 4.4 Controller Profile
```
{profileName: String, noteMap: {midiNote: padIndex}, padCount: 8|16}
```
For `padCount` 8 the map values are physical slots 0–7, not padIndex (see §6). Lessons may carry an optional `hits8` field (same format as `hits`).

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

**Calibration offset is the ONE place where input timing is compensated.** Each tap is compared with the click's hardware presentation time, derived from the rendered audio timestamp. The signed offset captures MIDI input delay, human perception, and systematic tapping bias; it does not include output latency. The offset is subtracted from incoming timestamps exactly once before scoring.

**Audio output timing**: scheduling uses intended audible time minus `mainMixerNode.outputPresentationLatency`; calibration observes rendered click onset plus that same presentation latency, independently of the intended schedule. `AVAudioSession.outputLatency + ioBufferDuration` is diagnostic only; `ioBufferDuration` also supplies a scheduling lead-time safety margin. No output-latency value is added to the calibration offset or scoring window.

**Adaptive timing center** (rolling median, window of 8 samples, gated ±100–110 ms): shifts the scoring window at runtime to follow systematic player drift. Does not widen the windows.

**Summary of timestamp flow:**
1. Raw MIDI timestamp arrives (mach time; or receipt time for BLE fallback).
2. Subtract calibration offset → corrected timestamp.
3. Subtract adaptive timing-center shift → final timestamp used for window comparison.

### 5.3 Pass & Mastery

- **Pass**: score ≥ 70% (non-intro), ≥ 80% (intro).
- **Mastery**: clean run at or above `targetBpm`.
- **Memory** (third star): score ≥ 80 % at `targetBpm` or above with the pattern hidden (From memory mode). See `docs/design/2026-10-30-practice-screen-spec.md` §8.
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

In continuous Play, the next queued pass takes the maximum of the last queued tempo and the latest finished result's `nextBpm`, capped at `targetBpm`. Each result is consumed once; unclean passes do not lower the tempo. Because the next pass is queued before the current pass's final timing window closes, a rise has a one-pass delay. START/RESTART clear stale results and preserve the manually selected starting tempo. Listen does not progress automatically. See the practice-screen specification §§4 and 9 (ticket 11b).

---

## 6. 8-Pad Controller Rule

Source: behaviour of the legacy prototype (`app/v21/src/ui/pad-layout.js`, function `layoutForEight`), verified 2026-10-30. This replaces the earlier "filter, not remap" rule.

Lessons use `padIndex` 0–15. In **8-pad mode** the controller has 8 physical pads (slots 0–7), and the lesson decides which sound each slot plays.

- **Controller profile in 8-pad mode**: `noteMap` maps a MIDI note to a physical slot 0–7 (not to a padIndex). MIDI learn in 8-pad mode asks the user to press the 8 pads in order.
- **Lesson data**: a lesson may carry an optional `hits8` array (same format as `hits`). 6 bundled lessons use 9 pads and have a `hits8` simplified version. In 8-pad mode the app plays `hits8` when it exists, otherwise `hits`.
- **Layout per lesson** (`EightPadLayout`):
  1. `required` = set of padIndex used in the lesson's hits (hits8 in 8-pad mode).
  2. If `required` has more than 8 pads, the lesson has no layout (not playable in 8-pad mode).
  3. Start from the base slots `[9, 10, 2, 3, 12, 13, 11, 7]` (Clap, Rim, Crash, Ride, Kick L, Snare L, Hat R, Open hat).
  4. Pads in `required` that are not in the base go to a waiting list (in ascending order). Walk the slots in the order `[0, 1, 3, 2, 7, 6, 5, 4]`; if the waiting list is not empty and the pad in that slot is not in `required`, replace it with the next waiting pad.
  5. If the waiting list is empty at the end, the resulting 8 slots are the layout; otherwise there is no layout.
- **Result on bundled data**: all 595 lessons have a layout in 8-pad mode (589 directly, 6 via `hits8`). Nothing needs to be hidden or greyed out today.
- A lesson with no layout (only possible for future content packs) is shown greyed-out with the label "requires 16 pads", stays visible and openable but cannot be scored.
- Progression counts are the same in both modes; a lesson without a layout is simply excluded from the unlock count.
- The play screen shows the 8 slots with the sound names of the current lesson's layout.

---

## 7. Acceptance Criteria per Module

### MIDI Input
- [ ] CoreMIDI receives note-on/off from a connected USB controller.
- [ ] BLE fallback triggers when timestamp is >250 ms stale or >50 ms future.
- [ ] Controller profile correctly maps note numbers to padIndex.
- [ ] MIDI learn builds a working profile from user input.
- [ ] **iPad test**: USB and BLE controllers both register hits.

### Audio
- [ ] All 8 sample kits load and play with <15 ms trigger-to-sound latency.
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
- [ ] First Path stage unlocked by default.
- [ ] Stage unlocking counts only lessons with both pass and goal-tempo stars; memory is optional. Threshold: half the preceding stage rounded up, capped at 10.
- [ ] Previously open stages stay open across the two-star migration and app restarts.
- [ ] Soft unlock works with single tap + confirmation.
- [ ] 8-pad mode: all bundled lessons get a layout (6 via `hits8`); unlocking works the same as in 16-pad mode.
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
6. **Sample kit audio** — all 8 kits play correctly, no glitches or pops.
7. **On-screen pads** — touch response and latency.

Everything else (data loading, persistence, progression logic, UI layout) can be verified in simulator or unit tests.

---

## 9. Open Questions (Remaining)

1. **Controller preset profiles** — Which 2–3 controllers get built-in profiles? Need to confirm the most common devices among finger-drumming players.
2. **Calibration thresholds** — Ticket 09 selects at least 6 usable taps, robust spread at most 80 ms, and an outlier cut of max(60 ms, 3 × 1.4826 × MAD), with no hard drift or duplicate limit. Real-iPad success rate and tuning remain pending.
3. **Sample license audit** — Each kit's LICENSE.txt must be reviewed before App Store submission. Separate task, does not block development.
4. **Content pack format** — Exact format and loading mechanism for future extension packs. v2+ decision.
5. **cs.tsv completeness** — Whether legacy Czech translations cover all strings needed, or if new strings need translating.
