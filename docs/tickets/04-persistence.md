# 04 — Persistence (Settings + Progress)

Status: ready-for-agent

## Goal

Implement persistence for user settings (UserDefaults) and lesson progress (JSON file in Documents).

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.6 Persistence, §4.3 Progress JSON)
- `docs/DECISIONS.md` (§11 Persistence)

## Tasks

1. **Settings** (UserDefaults):
   - Kit selection (kitId string)
   - BPM step (1, 2, 5, or 10)
   - Active controller profile name
   - Calibration offsets (keyed by MIDI device identifier, signed ms)
   - Language preference (cs/en)
   - Clean keyspace — no legacy prefixes.
2. **Progress** (JSON file in Documents):
   - Per-lesson record: `{ passed: Bool, mastery: Bool, currentBpm: Int, bestScore: Float }`
   - Keyed by lesson ID.
   - Load on app start, save after each lesson completion.
   - Graceful handling of missing/corrupt file (start fresh).
3. Create a `SettingsManager` (observable) and `ProgressStore` with save/load.

## Acceptance criteria

- [ ] Progress JSON saves and loads correctly across app restarts.
- [ ] Settings persist in UserDefaults.
- [ ] No data loss on normal app lifecycle (background, terminate, relaunch).
- [ ] Corrupt or missing progress file → fresh start, no crash.
- [ ] Clean keyspace (no legacy prefixes).

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: Straightforward persistence logic.

## Done rule

Stop after successful build; Jakub tests on iPad.
