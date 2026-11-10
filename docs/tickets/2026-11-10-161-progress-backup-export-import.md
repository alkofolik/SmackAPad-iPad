# 161 — Progress backup: Export / Import to a file, "never lose anything" merge, data ready for iCloud sync

Status: done 2026-11-10. Tested on iPad by Jakub.
Recommended agent: **Codex GPT-6.1 Sol, reasoning high** (touches real progress persistence; a merge bug silently loses player progress). Fallback: Gemini 3.8 Flash, high.

**Two phases. Phase 1 is a design note only — stop and wait for Jakub's approval before Phase 2 (code).**

## Why

On 2026-11-09 Jakub deleted and reinstalled the app on his iPad and lost all iPad progress: everything lives only in the app container (`<Documents>/progress.json` + `UserDefaults`), there is no backup and no cloud. Every customer would lose progress the same way (reinstall, new iPad). iCloud sync (CloudKit) is planned as **ticket 162**, but it needs the paid Apple Developer Program, which Jakub will buy only shortly before release. So now:

1. A real (Release, not DEBUG) **Export / Import** of the whole player state to a file the player stores wherever he wants (Files app, iCloud Drive via the system picker — works without any entitlement).
2. One **merge function** with "never lose anything" rules, used by Import now and by iCloud sync in 162 later.
3. Data model **prepared for sync** (stable IDs, per-record modification time, format version), so 162 only has to move data, not redesign it.

## Hard constraints

1. Works without the paid developer account: **no iCloud / CloudKit entitlement, no `CKContainer`, no `NSUbiquitousKeyValueStore`, no ubiquity container** in this ticket. Only the system document picker (`fileExporter` / `fileImporter` or `UIDocumentPickerViewController`).
2. Import **never removes or lowers** anything the player already has on the device. Importing an old backup over newer progress must leave the newer progress intact.
3. Old `progress.json` files (current format, and the legacy flat-dictionary format `ProgressRoot` already decodes) must keep loading. Any new fields are optional with sensible defaults. Write a migration test with a real current-format file.
4. Before an import is applied, the current state is saved automatically to `<Documents>/Backups/before-import-<timestamp>.json` (keep the last 5). If anything fails mid-import, nothing on disk changes (write to temp, then atomic replace).
5. Jakub does not want more text in the UI. Settings gets exactly **two rows** in one section and **one result alert**. No explanatory paragraphs, no new screens. All strings in `en` and `cs` `Localizable.strings`.
6. Device-specific data is **not** exported/imported: audio calibration offsets (`calibrationOffsets`, per route type from T156), Bluetooth timing diagnostics, debug snapshots / debug overrides (T160), StoreKit state.
7. Purchases are **not** part of the backup. Restoring the Full unlock stays the job of StoreKit ("Restore purchases"). Do not touch `StoreManager`.
8. The existing DEBUG `LegacyProgressImportSection` (ticket 44) stays as it is.

## What the app stores today (check and correct this list in Phase 1)

- Lesson progress + training log: `ProgressStore`, `<Documents>/progress.json`, root `ProgressRoot { lessons: [Int: LessonProgress], trainingLog: TrainingLog }` (`Persistence.swift` ~828–1000, `load()` ~1115, `save()` ~1337). No format version field yet.
- `LessonProgress`: `hasPlayed, passed, mastery, memory, currentBpm, bestScore, lastPlayedDay, masteryDay, reviewStep, reviewDueDay, settled, lastReviewedDay, lastReviewFailDay, learningCreditByPadCount`.
- `TrainingLog` already has `merging(_:with:)` (max of counters, union of sets) — reuse / move into the new merge module.
- Badges: `BadgeStore`, UserDefaults, `records: [String: Date]`.
- Settings: `SettingsManager` (UserDefaults, `SettingsKey` + other `smackapad.*` keys): language, appearance, BPM step, volumes, sound kit + per-lesson kit overrides, MIDI controls, active controller profile + custom profiles, practice mode, library view/filters, next-lesson source, keyboard play, memory-note fading, review reminder on/time, hidden categories, first-run flags (legend shown once, etc.).

## Phase 1 — design note (no code)

Write `docs/design/2026-11-10-161-backup-and-merge.md` with:

1. **Backup file format.** One JSON file, suggested name `Smack-a-Pad backup YYYY-MM-DD.json`. Envelope: `app: "smack-a-pad"`, `formatVersion: 1`, `exportedAt`, `appVersion`, `deviceId` (random UUID created once per install, stored in UserDefaults — used later by 162), then `progress`, `trainingLog`, `badges`, `settings`. Decide whether to declare a custom UTType (e.g. `.smackapad`) or stay on `.json`; recommend one and say why.
2. **Sync-ready model.** Per lesson record: add optional `modifiedAt` (Date, set on every change in `ProgressStore`). Same for badges (earned date already exists) and for the settings block as a whole (`settingsModifiedAt`). Add `formatVersion` to `progress.json` itself. Explain how 162 will map this onto CloudKit records (one record per lesson? one record per whole state?) — a short recommendation only, no CloudKit code.
3. **Merge rules, field by field** (pure function `merge(local:, incoming:) -> State`, no I/O). Principle: *a player never loses anything they earned*. Starting proposal — confirm or correct each against how the fields are really used:
   - `hasPlayed`, `passed`, `mastery`, `memory` (stars): logical OR.
   - `bestScore`: max. `learningCreditByPadCount`: per key, the stronger streak.
   - `masteryDay`: the earlier non-nil day. `lastPlayedDay`, `lastReviewedDay`, `lastReviewFailDay`: the later non-nil day.
   - `currentBpm`: from the record with the later `lastPlayedDay` (tie → higher BPM).
   - Review schedule (`reviewStep`, `reviewDueDay`, `settled`): taken **as a group** from the record that was reviewed more recently (`lastReviewedDay`, then `modifiedAt`); never mix fields from two records. Make sure the result is a valid schedule for `ReviewScheduler`.
   - `TrainingLog`: existing `merging` rule.
   - Badges: union; for the same badge keep the earlier earned date.
   - Settings: **replace, not merge**, and only when the device has no progress yet (fresh install / new iPad). On a device that already has progress, import merges progress and badges and keeps the device's settings. First-run flags follow the same rule.
   - Lessons that no longer exist in the catalog (removed/merged IDs, e.g. the First-steps → Intro migration): apply the existing migration before merging; drop unknown IDs and count them.
   - `formatVersion` higher than the app knows → refuse with the error alert, change nothing.
4. **UI.** Settings → section "Progress" / "Pokrok" with rows "Back up progress" / "Zálohovat pokrok" and "Restore from backup" / "Obnovit ze zálohy". Result alert: e.g. "Restored. 96 lessons updated." / "Obnoveno. Aktualizováno 96 lekcí." Error alert: "This file is not a Smack-a-Pad backup. Nothing was changed." Propose final wording in both languages; keep it this short.
5. **Optional, recommend yes/no:** after the first star of a day, keep a rolling automatic local copy (`<Documents>/Backups/auto-*.json`, last 3). It does not survive deletion of the app — say so honestly; it only protects against a corrupt file.

Stop here. Jakub reviews the note; Claude may adjust it with him.

## Phase 2 — implementation (only after approval)

- Pure merge module (e.g. `ProgressMerge.swift`) + backup envelope encode/decode (`ProgressBackup.swift`), independent of the stores, fully unit-tested.
- `ProgressStore` sets `modifiedAt`, writes `formatVersion`, exposes `exportState()` and `importState(_:)` (pre-import backup, merge, atomic save, reload in place — no app restart).
- `BadgeStore` and `SettingsManager`: export/import of their parts; settings applied only under the fresh-device rule.
- Settings UI: two rows + alerts, `en` + `cs` strings.
- Short note in `docs/CONTEXT.md` (where backups live, the merge rule, that 162 will reuse the merge).

## Tests

- Export → delete everything (fresh state) → import: progress, training log, badges and settings identical to before.
- Old backup over newer progress: nothing newer is lost (stars, best score, later days, more recent review schedule).
- Newer backup over older progress: upgrades are applied.
- Two divergent states (each has stars the other lacks): result has both. Merge is idempotent (`merge(a, merge(a, b)) == merge(a, b)`) and order-independent for stars/scores.
- Review schedule taken as a whole group, valid for `ReviewScheduler`.
- Settings replaced on a fresh device, kept on a device with progress; calibration offsets never exported.
- Current-format `progress.json` without the new fields loads unchanged; legacy flat format still loads.
- Unknown higher `formatVersion` and a non-backup JSON: refused, disk unchanged.
- Pre-import backup written and pruned to 5.
- Existing tests still pass.

## Out of scope

iCloud / CloudKit sync (ticket 162, after the paid developer account), purchases restore, multiple player profiles, sharing progress between players.

## Report back

Phase 1: the design note. Phase 2: files changed, final merge table, test results, how to test on the iPad (export to Files → delete app → reinstall from Xcode → import). Commit only after Jakub has tested on the iPad.
