# Domain Glossary

## Controller & Input

| Term | Definition |
|---|---|
| **Pad** | One of 16 (or 8) trigger surfaces on a MIDI controller, struck by a finger. |
| **padIndex** | 0-based index (0–15) identifying a pad's position in the layout. All lessons reference pads by this index. |
| **Pad layout** | Spatial arrangement of pads: 4×4 (16 pads) or 2×4 (8 pads). |
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
| **Intro** | 24 guided introductory exercises. Separate section, always accessible, recommended for beginners. Stricter pass threshold (80%). |
| **Content pack** | A loadable bundle of additional lessons. Architecture prepared in v1; actual extension packs delivered in v2+. |

## Audio

| Term | Definition |
|---|---|
| **Sample kit** | A set of audio samples mapped to pad voices (e.g., acoustic, 808, jazz). 9 kits bundled in v1. |
| **Voice** | A named drum sound within a kit (e.g., kick, snare, hihat), with optional velocity variants (multiple WAV files). |

## Scoring & Timing

| Term | Definition |
|---|---|
| **Timing window** | Level-dependent time range around the expected note time. Three zones: Perfect, Good, Max/Miss. |
| **Timing center** | Adaptive rolling-median corrector (8 samples, gated ±100–110 ms) that shifts the scoring window to follow a player's systematic early/late tendency, without widening the windows. |
| **Calibration** | 10-click guided procedure to measure per-device hardware timing offset. Forgiving thresholds — must not frustrate the user. |
| **Double-hit guard** | 30 ms window preventing a second hit on the same pad from being scored as a second match. |
| **Pass** | Score ≥ 70% (non-intro) or ≥ 80% (intro). |
| **Mastery** | Achieving a clean run at or above `targetBpm`. |
| **Clean run** | A play-through within the allowed error count: 0 errors for ≤15 hits, 1 for 16–32, 2 for >32. Intro always 0. |
| **BPM auto-progression** | Automatic tempo increase (1, 2, 5, or 10 BPM — user-selectable) after a clean run below `targetBpm`. |

## Progression

| Term | Definition |
|---|---|
| **Category unlock** | Categories are locked by default (except the first). Completing a certain number of lessons in a category unlocks the next one. |
| **Soft unlock** | Manual override: user can tap a locked category, confirm, and unlock it immediately. Nobody gets stuck. |
| **Progress** | Per-lesson persistent data: passed/mastery status, current BPM, best score. Stored as a JSON file. |
