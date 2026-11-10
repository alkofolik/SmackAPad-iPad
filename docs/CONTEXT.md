# Domain Glossary

## Controller & Input

| Term | Definition |
|---|---|
| **Pad** | One of 16 (or 8) trigger surfaces on a MIDI controller, struck by a finger. |
| **padIndex** | 0-based index (0–15) identifying a pad's position in the layout. All lessons reference pads by this index. |
| **Pad layout** | Spatial arrangement of pads: 4×4 (16 pads) or 2×4 (8 pads). |
| **Eight-pad layout** | In 8-pad mode, the assignment of the 8 physical pads (slots 0–7) to the sounds a given lesson needs. Computed per lesson; see SPEC §6. |
| **hits8** | Optional simplified version of a lesson's hits for 8-pad mode. Present in 6 lessons that use 9 pads. |
| **Controller profile** | Mapping table from MIDI note numbers to padIndex values. Each controller model sends different note numbers for the same physical pad position. |
| **MIDI learn** | Process where the user presses each pad on their controller so the app can build a custom controller profile. |
| **BLE controller** | Bluetooth Low Energy MIDI controller. Timestamps from BLE are unreliable (batched by CoreBluetooth); the app falls back to receipt time. |

## Lessons & Patterns

| Term | Definition |
|---|---|
| **Lesson** | A single practice pattern with metadata: id, category, title, genre, BPM range, level, hits. |
| **Hit** | One note event in a pattern: `[step, padIndex, hand, velocity]`. |
| **Step** | 0-based sixteenth-note position within a pattern. Range: 0 to `bars × division − 1`. |
| **Division** | Subdivisions per bar. Always 16 (sixteenth-note grid). |
| **Bars** | Number of bars in a pattern (1, 2, or 3). |
| **Category** | Lesson grouping: starter, eighth, sixteenth, electronic, ghost, swing, world, fills. |
| **Level** | Difficulty rating 1–5. Determines timing window strictness. |
| **Intro** | 25 guided introductory exercises (24 from `intro.json` + core lesson 6). Separate section, always accessible, recommended for beginners. Stricter pass threshold (80%). |
| **Content pack** | A loadable bundle of additional lessons. Architecture prepared in v1; actual extension packs delivered in v2+. |

## Audio

| Term | Definition |
|---|---|
| **Sample kit** | A set of audio samples mapped to pad voices (e.g., acoustic, 808, jazz). 8 kits bundled in v1. |
| **Voice** | A named drum sound within a kit (e.g., kick, snare, hihat), with optional velocity variants (multiple WAV files). |

## Scoring & Timing

| Term | Definition |
|---|---|
| **Timing window** | Level-dependent time range around the expected note time. Three zones: Perfect, Good, Max/Miss. |
| **Timing center** | Adaptive rolling-median corrector (8 samples, gated ±100–110 ms) that shifts the scoring window to follow a player's systematic early/late tendency, without widening the windows. |
| **Calibration** | 10-click guided procedure to measure per-device hardware timing offset. Forgiving thresholds — must not frustrate the user. |
| **Double-hit guard** | 30 ms window preventing a second hit on the same pad from being scored as a second match. |
| **Pass** | Score ≥ 80% (all lessons). In Learning mode, alternative pass threshold is ≥ 60% with error/quality requirements. |
| **Mastery** | Achieving a clean run at or above `targetBpm`. |
| **Star 3 (Settled)** | Retention star earned exclusively by passing two spaced reviews in Training on separate days. |
| **Clean run** | A play-through within the allowed error count: 0 errors for ≤15 hits, 1 for 16–32, 2 for >32. Intro always 0. |
| **BPM auto-progression** | Automatic tempo increase (1, 2, 5, or 10 BPM — user-selectable) after a clean run below `targetBpm`. |
| **Practice Mode** | Learning (default; passes accumulate across sessions, alternative 60% Star 1 rule) vs Challenge (consecutive passes in a row, session-only). |
| **Bar verdict** | Planned / not shipped per-bar evaluation (`clean`, `ahead`, `behind`, `uneven`). Practice currently scores runs and passes as a whole. |

## Progression

| Term | Definition |
|---|---|
| **Stage unlock** | Path stages unlock when earning 2 stars on half the preceding stage's lessons (capped at 10). |
| **Soft unlock** | Manual override: user can tap a locked stage banner, confirm, and unlock it immediately. Nobody gets stuck. |
| **Progress** | Per-lesson persistent data: passed/mastery status, current BPM, best score. Stored as a JSON file. |

## Backup & Sync

| Term | Definition |
|---|---|
| **Backup envelope** | Single portable JSON file (`Smack-a-Pad backup YYYY-MM-DD.json`) wrapping progress, training log, badges, and portable settings with format versioning and device identifier. |
| **Local backups directory** | `<Documents>/Backups/`: stores up to 5 pre-import safety snapshots (`before-import-*.json`) and up to 3 daily rolling copies (`auto-*.json`). |
| **"Never lose anything" merge** | Pure merge function (`ProgressMerge`): stars and high scores never decrease; review schedule is preserved as an inseparable group from the more recently reviewed record; training log takes max counters and union of sets; badges take union with earliest earned date; settings are replaced only on a fresh device. Reused by ticket 162 for CloudKit sync. |
