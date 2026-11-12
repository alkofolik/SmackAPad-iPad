# 166 — Even out sample loudness and add per-instrument volume

Status: done (checked and passed by Jakub 2026-11-12). Approved by Jakub on 2026-11-10.

## Problem

Crashes, rides and hi-hats in the sound sets (`SmackAPad/Resources/Samples/*`, 7 sets) are far louder than kicks, snares and toms and drown them out.

## Part 1 — Loudness normalisation (non-destructive)

1. Add a script `tools/measure-sample-loudness.py` (Python 3, numpy/soundfile or wave; document how to run it) that measures every WAV in every set. Use a measure that matches perceived loudness of short percussive hits: e.g. K-weighted RMS (ITU-R BS.1770 filter) over the first 300 ms, plus true peak. State in the ticket log which measure you chose and why.
2. Write the per-file gain in dB to a resource (e.g. `Resources/Data/sample-gains.json`) so that all instruments in a set sit at one reference level. Instrument families may get a small intentional offset (kick and snare slightly forward, cymbals and hats slightly back), defined in one table in the script and easy to change.
3. Never boost past a true peak of −1 dBFS; cap the gain instead.
4. Do not rewrite the WAV files or their licences.
5. `AudioEngine` / `SampleKitCache` apply the gain at playback (with velocity as today, `AudioEngine.swift` ~574). The pattern sound in Listen and the student's pad sounds both use it. No extra latency, no allocation on the audio path.

## Part 2 — Per-instrument volume in Settings

1. In Settings, under the existing volume section, add **Instrument volumes**: one slider per instrument role (the same abbreviations the pattern uses: KK, SN, HH, OH, CR, RD, toms, perc…), −12 dB to +6 dB, default 0 dB, and one **Reset** button.
2. Settings are global (all lessons, all sets), saved with other settings, included in the T161 backup if settings are part of it.
3. Show only roles that exist in the app's lessons. Group them if the list is long. Slider changes are audible at once if a lesson is open.
4. Text only in the Settings row and slider labels; English and Czech.

## Tests

- Gain table covers every WAV; no entry raises true peak above −1 dBFS.
- Combined gain (normalisation + user trim + velocity) is clamped and applied to the right role.
- Settings persist and Reset returns all to 0 dB.

## Acceptance criteria

- [ ] In every set, crash/ride/hi-hat no longer drown out kick and snare at default settings.
- [ ] Per-instrument sliders change loudness immediately; Reset works; values survive relaunch.
- [ ] No audible timing change, no clicks, no new late-sound reports in `AudioTimingDiagnostics`.

### Manual iPad checks for Jakub

Play a lesson with kick, snare, HH and crash in each of the 7 sets (and Automatic). Then turn the crash down −6 dB in Settings and check it during a run, in Listen and with the pad sounds.

## Files to read

`AGENTS.md`, `Sources/Audio/AudioEngine.swift`, `SampleKitCache.swift`, `SoundKitResolver.swift`, `Sources/UI/SettingsView.swift`, the settings manager, `Resources/Samples/*/CREDITS.md`, T161 backup code (`Persistence/ProgressBackup.swift`).

## Agent assignment

Codex GPT-6.1 Sol, high. Audio-path work and careful measurement.

## Done rule

Build, run the full `SmackAPad` test plan per `AGENTS.md`, commit, stop for Jakub's iPad check.

## Log

- Measure: K-weighted RMS (BS.1770 filters) over the first 300 ms, plus 4x-oversampled true peak. K-weighting matches how loud short bright hits (cymbals, hats) sound; plain RMS or peak would not.
- Gains are per kit and voice (`Resources/Data/sample-gains.json`), not per file, because kits such as `world` share WAVs with `acoustic`. Velocity layers of one voice share one gain, so the soft-to-loud dynamics are kept.
- Gains are never above 0 dB: `AVAudioPlayerNode.volume` cannot exceed 1, so loud voices are turned down and quiet ones stay as they are. A +6 dB user trim therefore saturates at full volume on very hard hits of voices with a 0 dB gain.
- Settings: `instrumentTrims` (voice name to dB) is saved, reset and included in the backup. Backups from older versions load with all trims at 0 dB.
