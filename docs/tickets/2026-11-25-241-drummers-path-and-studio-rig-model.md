# 241 — Drummer's Path & Studio Rig data and game model

Status: done

## Goal

Build the clean, unit-tested data and game-progression model for **Drummer's Path & Studio Rig** (RPG drummer card with XP, levels/ranks, and 4 attributes; keys earned from stage exams and milestones; unlocking the 8 existing drum kits with 1 key = 1 kit and kit-to-lesson binding; unlockable instrument skins and bonus jam tracks; safe automatic migration for existing players and full persistence + backup export/import), without modifying the Path or Studio Rig UI (deferred to tickets 242 and 243) and without touching audio/MIDI engine timing.

## Rules

1. **Drummer Card (XP, Level/Rank, 4 Attributes + Post-Lesson Delta):**
   - Compute XP, `level`, `DrummerRank` (e.g. Pad Rookie → Beat Keeper → Pocket Player → Session Drummer → Groove Architect → Master Percussionist), and 4 attributes (`0...100`): `TIMING`, `SPEED`, `TECHNIQUE`, `MEMORY` deterministically from real play results (`LessonProgress`, `TrainingLog`, completed stage exams, and earned milestones).
   - Provide post-lesson delta calculation (`DrummerProgressDelta`, e.g. `+2 SPEED · +1 TIMING`) comparing before/after snapshots.
2. **Keys & Unlocking the 8 Drum Kits (Kit → Lesson Binding):**
   - Map all 8 bundled drum kits (`acoustic` as Starter unlocked from the beginning; `rock`, `808`, `house`, `jazz`, `brush`, `world`, `worldperc` initially locked).
   - Introduce `keys` earned by completing stage exams (Boss lessons at the end of chapters/stages) and major milestones.
   - Allow spending 1 key to unlock any locked drum kit (`1 key = 1 kit`).
   - Bind kits to lessons/chapters (Intro lessons stay on Starter `acoustic`; genre/chapter lessons require their matching kit) and return a clear access status (`"Requires <Kit> kit (unlock for 1 key)"` / Czech `"Vyžaduje sadu <Kit> (odemkni za 1 klíč)"`).
3. **Unlockable Instrument Skins & Bonus Jam Tracks:**
   - Define studio instrument skin variants (`Smack Orange` default + 3 additional unlockable studio variants) with persisted selection.
   - Define bonus jam/practice tracks bound to milestones and stage exams.
4. **Safe Migration & Persistence / Backup:**
   - On first run for existing players with saved stars/progress, automatically compute initial XP, attributes, completed stage exams, earned milestones, keys, and unlocked kits/skins/tracks so no existing progress is lost.
   - Persist all RPG state in `ProgressStore` (`progress.json`) and `SettingsManager`, and include it in backup export/import (`ProgressBackupEnvelope`, `BackupSettings`, `ProgressMerge`).
5. **Unit Tests & Verification:**
   - Add unit tests covering attribute calculation, post-lesson deltas, key awards from stage exams and milestones, kit unlocking with keys, kit-to-lesson availability status, skins/bonus tracks unlocking, legacy progress migration, and backup round-trip/merge.
   - Do not alter audio/MIDI timing; keep all existing tests green.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Audio/SoundKitResolver.swift`, `SmackAPad/Sources/Data/LessonData.swift`, `SmackAPad/Sources/Persistence/ProgressModels.swift`, `SmackAPad/Sources/Persistence/ProgressStore.swift`, `SmackAPad/Sources/Persistence/ProgressBackup.swift`, `SmackAPad/Sources/Persistence/ProgressMerge.swift`, `SmackAPad/Sources/Persistence/SettingsTypes.swift`, `SmackAPad/Sources/Persistence/SettingsManager.swift`, `SmackAPad/Sources/Persistence/SettingsManager+Backup.swift`, `SmackAPad/Sources/Progression/LibraryCatalog.swift`, `SmackAPad/Sources/Progression/Progression.swift`.

## Tests

Build and run the full test suite on the iPad simulator (`xcodebuild test`), including new tests in `SmackAPadTests/DrummerPathTests.swift`, plus existing `ProgressBackupTests`, `ProgressionTests`, `StageCompletionTests`, `SoundKitResolverTests`, and `LocalizationTests`.

## Acceptance criteria

- [x] Drummer Card computes XP, Level, Rank, and 4 monotonic attributes (`TIMING`, `SPEED`, `TECHNIQUE`, `MEMORY`, `0...100`) from real play data, plus post-lesson delta formatting.
- [x] All 8 bundled kits are mapped (`acoustic`/Starter unlocked initially, 7 locked); keys are awarded for stage exams (Boss lessons) and milestones; 1 key unlocks any locked kit; lessons clearly report required locked kit status.
- [x] Instrument skins (`Smack Orange` + 3 variants) and bonus jam tracks are modeled and unlocked by milestones and stage exams.
- [x] Existing player progress migrates automatically without losing stars, unlocked kits, keys, or rewards, and full RPG state persists and round-trips through backup export/import.
- [x] App builds and all unit tests pass on the iPad simulator.

### Manual iPad checks for Jakub

- Verify in code/test output that existing saved progress migrates cleanly without locking already-played lessons or losing stars/kits (UI integration follows in tickets 242 and 243).

## Agent assignment

Gemini 4 Hydrogen, thinking **medium**.

## Done rule

Build, run the full test suite on the iPad simulator, commit on `release-polish`, and report changed files concisely.
