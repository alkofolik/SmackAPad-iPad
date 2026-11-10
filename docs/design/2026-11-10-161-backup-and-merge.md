# Progress backup: Export / Import, "never lose anything" merge, sync-ready data model

Design note for ticket [161](../tickets/2026-11-10-161-progress-backup-export-import.md) (Phase 1).  
Status: **Proposed for review by Jakub**. Phase 2 (code) will start only after approval.

---

## 1. Why and Context

On 2026-11-09 Jakub deleted and reinstalled the app during testing and lost all progress: everything had lived exclusively in `<Documents>/progress.json` and `UserDefaults.standard` without any backup or cloud mechanism. Any user reinstalling the app or switching iPads would suffer the same total loss.

Full iCloud sync (via CloudKit) is planned as **ticket 162**, which requires an active paid Apple Developer Program account (scheduled for purchase shortly before the App Store release). In the interim, ticket 161 delivers:

1. **User-facing Export / Import:** A clean, production (Release) file-based backup that allows players to save their full progress into the Files app or iCloud Drive via the native iOS document picker without needing entitlements.
2. **"Never lose anything" pure merge:** A robust, mathematically sound merge function that guarantees an older backup or a second device will never downgrade stars, scores, or earned achievements. Ticket 162 will reuse this exact merge function for CloudKit synchronization.
3. **Sync-ready data model:** Introducing modification timestamps (`modifiedAt`, `settingsModifiedAt`), persistent install UUID (`deviceId`), and container format versioning (`formatVersion`) so ticket 162 only has to transport records rather than redesigning the schema.

---

## 2. Current App State Audit

A thorough audit of `Persistence.swift`, `BadgeStore.swift`, `SettingsManager.swift`, and `UserDefaults.standard` reveals exactly what is stored today:

| Component | Storage Location | Data Stored | Device-Specific? |
|---|---|---|---|
| **Lesson Progress** | `<Documents>/progress.json` (`ProgressRoot.lessons`) | `[Int: LessonProgress]`: `hasPlayed`, `passed`, `mastery`, `memory`, `currentBpm`, `bestScore`, `lastPlayedDay`, `masteryDay`, `reviewStep`, `reviewDueDay`, `settled`, `lastReviewedDay`, `lastReviewFailDay`, `learningCreditByPadCount`. | **No** (Core player progress) |
| **Training Log** | `<Documents>/progress.json` (`ProgressRoot.trainingLog`) | `TrainingLog`: `reviewsPassed`, `bounceBacks`, `mixRounds`, `mixMemoryRounds`, `afterMeLessons: Set<Int>`, `trainingDays: Set<String>`. | **No** (Core player progress) |
| **Badges** | `UserDefaults` (`smackapad.badges`) | `records: [String: Date]` mapping badge ID to ISO 8601 earned date. | **No** (Core player progress) |
| **Player Settings** | `UserDefaults` (`smackapad.settings.*`, `smackapad.library.*`, `smackapad.practice.*`) | Selected kit, kit overrides, BPM step, MIDI mapping, active profile, custom profiles, language, appearance, volumes (metronome, pads, pattern), keyboard play, fade memory notes, review reminder toggle/time, library view/filters, hidden categories. | **No** (Player preferences, portable to fresh install) |
| **First-Run Flags** | `UserDefaults` (`smackapad.tutorial.seen`, `smackapad.legend.shownOnce`, `smackapad.memoryHintShownLessonIds`) | Flags tracking whether one-time introductory guidance was shown. | **No** (Portable on fresh install) |
| **Audio Calibration** | `UserDefaults` (`smackapad.settings.calibrationOffsets`) | Latency offsets in milliseconds keyed by audio route (speaker, wired, Bluetooth A2DP). | **YES — DO NOT EXPORT.** Hardware- and route-dependent. |
| **Bluetooth Diagnostics** | `UserDefaults` (`smackapad.bluetooth.*`) | Hardware packet latency statistics and test logs. | **YES — DO NOT EXPORT.** Hardware-dependent. |
| **Debug Overrides & Snapshots** | `<Documents>/DebugSnapshots/`, `UserDefaults` (`smackapad.debug.*`) | Ticket 160 debug states, simulated clock offsets, fake store entitlements. | **YES — DO NOT EXPORT.** Debug-only. |
| **Purchases / StoreKit** | StoreKit 2 transaction history & entitlements | Full unlock entitlement managed by Apple ID. | **YES — DO NOT EXPORT.** Handled by StoreKit ("Restore purchases"). |

---

## 3. Backup File Format

### 3.1 Suggested Filename
`Smack-a-Pad backup YYYY-MM-DD.json`  
(Example: `Smack-a-Pad backup 2026-11-10.json`. If multiple backups are exported on the same calendar day, standard iOS Files picker naming appends ` 2`, ` 3`, etc. automatically).

### 3.2 Envelope Schema
The backup is a single human-readable, pretty-printed UTF-8 JSON file containing an envelope that identifies the application, format version, export timestamp, originating device identifier, and the data payloads:

```json
{
  "app": "smack-a-pad",
  "formatVersion": 1,
  "exportedAt": "2026-11-10T13:25:00Z",
  "appVersion": "1.0 (42)",
  "deviceId": "E621E1F8-C36C-495A-93FC-0C247A3E6E5F",
  "progress": {
    "10001": {
      "hasPlayed": true,
      "passed": true,
      "mastery": true,
      "memory": false,
      "currentBpm": 90,
      "bestScore": 0.94,
      "masteryDay": "2026-11-08",
      "lastPlayedDay": "2026-11-10",
      "reviewStep": 1,
      "reviewDueDay": "2026-11-11",
      "settled": false,
      "lastReviewedDay": "2026-11-09",
      "lastReviewFailDay": null,
      "learningCreditByPadCount": {},
      "modifiedAt": "2026-11-10T12:00:00Z"
    }
  },
  "trainingLog": {
    "reviewsPassed": 14,
    "bounceBacks": 2,
    "mixRounds": 5,
    "mixMemoryRounds": 3,
    "afterMeLessons": [10001, 10002],
    "trainingDays": ["2026-11-08", "2026-11-09", "2026-11-10"]
  },
  "badges": {
    "intro-graduate": "2026-11-08T15:30:00Z",
    "streak-3": "2026-11-10T09:12:00Z"
  },
  "settings": {
    "settingsModifiedAt": "2026-11-09T18:45:00Z",
    "selectedKitId": "auto",
    "lessonKitOverrides": {},
    "bpmStep": 5,
    "practiceMode": "learning",
    "activeProfileName": "Standard 16-Pad",
    "language": "en",
    "appearance": "dark",
    "metronomeVolume": 80,
    "padsVolume": 100,
    "patternVolume": 70,
    "playPadsWithKeyboard": true,
    "fadeMemoryNotes": true,
    "reviewReminderEnabled": false,
    "reviewReminderTime": "18:00",
    "hideCompletedLessons": true,
    "tutorialSeen": true,
    "legendShownOnce": true
  }
}
```

### 3.3 File Type: `.json` vs Custom UTType (`.smackapad`)

| Aspect | Standard `.json` (Recommended) | Custom UTType (`.smackapad`) |
|---|---|---|
| **System support** | Universal (`public.json` / `UTType.json`) across iOS, iPadOS, macOS, Windows, Linux. | Requires custom `UTExportedTypeDeclarations` in Info.plist. |
| **Files & AirDrop** | 100% reliable across all sharing methods (Files, iCloud Drive, AirDrop, email, Google Drive, Dropbox). | High risk of AirDrop or third-party cloud apps flagging the file as an unrecognized binary octet-stream. |
| **Sandbox & Reinstall resilience** | Functions immediately even on fresh install before any document type registry indexing completes. | If the app is uninstalled, custom file associations can become dormant or unlinked in Files app until launched. |
| **Safety & Validation** | Protected by explicit envelope check: `guard envelope.app == "smack-a-pad"` and `formatVersion <= 1`. Non-matching JSON files are rejected instantly without touching disk. | Slightly narrower file selection in picker, but still requires the exact same envelope validation inside. |
| **Inspectability** | Player or developer can open and inspect the backup with any text editor or browser. | Requires renaming or specialized tooling to view. |

**Recommendation:** **Stay on `.json`** (e.g. `Smack-a-Pad backup YYYY-MM-DD.json`). It avoids all custom UTI declaration issues in iOS, works reliably with standard `.fileExporter` and `.fileImporter`, and provides total safety via envelope verification.

---

## 4. Sync-Ready Data Model (Preparing for Ticket 162)

To prepare for seamless CloudKit synchronization in ticket 162 without having to redesign data structures later:

1. **Per-lesson `modifiedAt: Date?`**:
   - Added as an optional property to `LessonProgress`.
   - Updated to `AppCalendar.now()` whenever `ProgressStore` mutates a lesson record (passing a lesson, completing a review, changing tempo, updating high score).
   - Defaults to `nil` for legacy progress files (in merge operations, `nil` is treated as older than any explicit date).
2. **`formatVersion` in `progress.json`**:
   - Added to `ProgressRoot`: `public var formatVersion: Int = 1`.
   - When loading older existing files without `formatVersion`, `ProgressRoot` decodes with default `1`.
   - If a file is encountered with `formatVersion > 1`, the app rejects loading/saving to prevent silently corrupting future formats.
3. **`settingsModifiedAt: Date?`**:
   - Stored in `UserDefaults` (`smackapad.settings.modifiedAt`) and updated whenever player preferences change.
4. **Stable `deviceId: String`**:
   - Stored in `UserDefaults` (`smackapad.deviceId`). Generated once via `UUID().uuidString` on first run. Never changes for the lifetime of that install.
   - Identifies the originating device in backups and will be used by ticket 162 to differentiate local vs remote modifications.

### 4.1 CloudKit Record Mapping Recommendation (for Ticket 162)

Ticket 162 will use CloudKit in the user's private database (`CKDatabase`). We recommend mapping the data as **per-record entities within a custom `CKRecordZone` (`"SmackAPadZone"`)**:

- `RecordType "LessonProgress"`:
  - `recordID = CKRecord.ID(recordName: "lesson_\(id)", zoneID: zoneID)`
  - Fields: `lessonId: Int64`, `passed: Int64`, `mastery: Int64`, `memory: Int64`, `currentBpm: Int64`, `bestScore: Double`, `lastPlayedDay: String?`, `masteryDay: String?`, `reviewStep: Int64?`, `reviewDueDay: String?`, `settled: Int64?`, `lastReviewedDay: String?`, `lastReviewFailDay: String?`, `modifiedAt: Date`.
- `RecordType "TrainingLog"`:
  - `recordID = CKRecord.ID(recordName: "trainingLog", zoneID: zoneID)`
  - Fields: Counters, string list of `trainingDays`, int list of `afterMeLessons`.
- `RecordType "Badge"`:
  - `recordID = CKRecord.ID(recordName: "badge_\(badgeId)", zoneID: zoneID)`
  - Fields: `badgeId: String`, `earnedAt: Date`.
- `RecordType "PlayerSettings"`:
  - `recordID = CKRecord.ID(recordName: "settings", zoneID: zoneID)`
  - Fields: Serialized settings JSON, `modifiedAt: Date`.

**Why per-record instead of a single giant blob?**
Using `CKFetchRecordZoneChangesOperation` allows CloudKit to send *delta updates* (only lessons modified since the last sync server token). If a user plays one lesson on the train, syncing takes milliseconds and transfers <1 KB. When records arrive from CloudKit, the app simply feeds each remote record into the pure merge function defined below.

---

## 5. Merge Rules Field by Field ("Never Lose Anything")

The core merge function is a pure function:
```swift
func merge(local: AppState, incoming: AppState) -> AppState
```
with zero disk I/O, zero network calls, zero store dependencies, and 100% test coverage.

### 5.1 Principle
*A player never loses anything they earned.*
Importing an old backup over newer progress leaves newer stars and records intact. Importing progress from another device combines the best of both worlds.

### 5.2 Field-by-Field Merge Matrix

| Field | Source Type | Merge Resolution | Rationale |
|---|---|---|---|
| `hasPlayed` | `Bool` | `local.hasPlayed \|\| incoming.hasPlayed` | Once played, never unplayed. |
| `passed` | `Bool` | `local.passed \|\| incoming.passed` | Star 1 is permanent. |
| `mastery` | `Bool` | `local.mastery \|\| incoming.mastery` | Star 2 is permanent. |
| `memory` | `Bool` | `local.memory \|\| incoming.memory` | Star 3 is permanent. |
| `bestScore` | `Float` | `max(local.bestScore, incoming.bestScore)` | High score never decreases. |
| `learningCreditByPadCount` | `[String: StarStreak]` | Key-by-key union. For matching keys, take `max` of `passedRuns`, `masteryRuns`, `memoryRuns`. | Preserves highest earned streak progression per pad configuration. |
| `masteryDay` | `String?` | Earlier non-nil day (`min(d1, d2)`). | You mastered the lesson on the day you first achieved it. |
| `lastPlayedDay` | `String?` | Later non-nil day (`max(d1, d2)`). | Represents most recent practice date. |
| `lastReviewedDay` | `String?` | Later non-nil day (`max(d1, d2)`). | Represents most recent review execution. |
| `lastReviewFailDay` | `String?` | Later non-nil day (`max(d1, d2)`). | Represents most recent failed review attempt. |
| `currentBpm` | `Int` | From the record with the later `lastPlayedDay`. If dates tie or either is nil: `max(local.currentBpm, incoming.currentBpm)`. (If one BPM is 0, use the non-zero BPM). | Current practice tempo should reflect the most recently played session, but never drop down to 0 if an unplayed record is merged. |
| **Review Schedule** (`reviewStep`, `reviewDueDay`, `settled`) | Group | **Taken as a single, indivisible group** from the record that was reviewed more recently (see details below). | Mixing schedule fields across records creates invalid schedule states. |
| `modifiedAt` | `Date?` | `max(d1, d2)` (or whichever record supplied the latest review state). | Keeps track of latest activity timestamp. |

### 5.3 Review Schedule Group Merge Details

Spaced repetition relies on internal consistency between `reviewStep`, `reviewDueDay`, and `settled`. Never take `reviewStep` from one record and `reviewDueDay` from another.

The winning review schedule `(reviewStep, reviewDueDay, settled)` is selected by:

1. **Settled status takes precedence unless overridden by a later review:**
   - If one record has `settled == true` (the lesson has permanently graduated through all spaced repetition stages) and the other record does not have a `lastReviewedDay` that is *later* than the settled record's `lastReviewedDay`, the **settled schedule wins**. A graduated lesson is never forced back into early review stages by an older backup.
2. **Most recent review date (`lastReviewedDay`):**
   - If both records have `lastReviewedDay` and they differ, the record with the **later `lastReviewedDay` wins**. Its complete schedule tuple is taken.
   - If only one record has `lastReviewedDay`, that record was actually reviewed; it wins over a record that was never reviewed.
3. **Modification timestamp tie-break (`modifiedAt`):**
   - If `lastReviewedDay` matches or neither has been reviewed yet, compare `modifiedAt`. The record with the later `modifiedAt` wins.
4. **Progress depth tie-break:**
   - If timestamps tie or are nil: pick the higher `reviewStep`. If steps match, pick the earlier `reviewDueDay`.
5. **Validation check:**
   - The resulting schedule is verified against `ReviewScheduler` rules: if `settled == true`, `reviewDueDay` is nil.

### 5.4 Training Log Merge

Uses the existing, proven `TrainingLog.merging(_:with:)` logic:
- `reviewsPassed`: `max(local, incoming)`
- `bounceBacks`: `max(local, incoming)`
- `mixRounds`: `max(local, incoming)`
- `mixMemoryRounds`: `max(local, incoming)`
- `afterMeLessons`: `local.afterMeLessons.union(incoming.afterMeLessons)`
- `trainingDays`: `local.trainingDays.union(incoming.trainingDays)`

### 5.5 Badges Merge

- Badge records dictionary: `[String: Date]`
- Union of all earned badge keys from both records.
- For any badge earned in both records, retain the **earlier earned date** (`min(localDate, incomingDate)`), honoring the exact day and time the player originally unlocked it.
- After import, call `BadgeStore.awardSilently()` with the merged lesson progress and catalog to ensure any newly qualified badges (e.g. from combined progress) are immediately awarded.

### 5.6 Settings & First-Run Flags Merge Rule

**Rule: Replace, not merge — and only on a fresh device.**

1. **Definition of a "Fresh Device":**
   A device is deemed fresh if:
   - `ProgressStore.records` has zero earned stars (`passed == false && mastery == false && memory == false` for all records), **AND**
   - `TrainingLog.trainingDays.isEmpty`, **AND**
   - `BadgeStore.earnedCount == 0`.
2. **Fresh Device Behavior (New iPad / Reinstalled App):**
   - The player is restoring their profile onto a clean installation.
   - The backup's portable settings (volumes, kits, appearance, language, custom profiles, library filters, tutorial/legend flags) are applied to `SettingsManager` and `UserDefaults`.
3. **Existing Device Behavior (Device Already Has Progress):**
   - The device already has an active player who has configured their preferred volume, theme, language, and MIDI controllers on this specific iPad.
   - Progress, training log, and badges are merged.
   - **Local settings and first-run flags remain 100% untouched.** An import never overrides the user's current iPad volume, language, or controller configuration.
4. **Device-Specific Exclusions (Under All Conditions):**
   - `calibrationOffsets` (Audio calibration offsets per route) are **never exported and never imported**.
   - Bluetooth timing diagnostics are **never exported and never imported**.
   - Debug snapshots and overrides are **never exported and never imported**.
   - StoreKit purchases/status are **never exported and never imported** (handled by Apple ID StoreKit restoration).

### 5.7 Retired Lessons and Catalog Migrations

- **Retired Intro Lessons (Ticket 20):** If an incoming backup contains retired duplicate First Steps IDs (1..9), run `ProgressStore.migrateDuplicateIntroProgress` to map them onto Intro IDs (10001..) before merging.
- **Two-Reviews Star 3 Migration (Ticket 143):** Run `ProgressStore.migrateTwoReviewsStar3` on incoming data.
- **Legacy Review Migration (Ticket 98):** Run `ProgressStore.migrateLegacyMasteredReviewSchedule`.
- **Unknown Catalog IDs:** Any lesson IDs in the backup that do not exist in the app's `LibraryCatalog` are ignored and omitted from active records, but tracked in an `unrecognizedLessonsCount` metric for logging.

### 5.8 Format Version Safeguard

- If an incoming file has `formatVersion > 1` (created by a future app version with schema changes this version cannot interpret), the import is **refused**.
- Disk state is completely untouched, and the user is shown the clear error alert.

---

## 6. UI & Localization

Jakub's hard constraint: **No extra explanatory paragraphs, no new screens, exactly two rows in one section, one result alert.**

### 6.1 Section Placement in `SettingsView.swift`

Add a new section titled **Progress** / **Pokrok** directly below `PurchasesSection()` (and above `#if DEBUG LegacyProgressImportSection`):

```swift
// SettingsView.swift
Section {
    Button(settings.localized("Back up progress")) {
        viewModel.exportBackup()
    }
    Button(settings.localized("Restore from backup")) {
        viewModel.importBackup()
    }
} header: {
    SectionHeader(title: settings.localized("Progress"))
}
```

### 6.2 Exact Copy (English and Czech)

#### Rows and Section Header:
| Key | English (`en`) | Czech (`cs`) |
|---|---|---|
| `Progress` | `Progress` | `Pokrok` |
| `Back up progress` | `Back up progress` | `Zálohovat pokrok` |
| `Restore from backup` | `Restore from backup` | `Obnovit ze zálohy` |

#### Result & Error Alerts:
| Scenario | English (`en`) | Czech (`cs`) |
|---|---|---|
| **Success Alert Title** | `Restore complete` | `Obnovení dokončeno` |
| **Success Alert Body** | `Restored. %d lessons updated.` *(e.g. "Restored. 96 lessons updated.")* | `Obnoveno. Aktualizováno %d lekcí.` *(handles Czech plural: 1 lekce / 2-4 lekce / 5+ lekcí)* |
| **Invalid Backup Alert Title** | `Cannot restore` | `Nelze obnovit` |
| **Invalid Backup Alert Body** | `This file is not a Smack-a-Pad backup. Nothing was changed.` | `Tento soubor není zálohou Smack-a-Pad. Nic nebylo změněno.` |
| **Incompatible Version Alert Title**| `Update required` | `Vyžadována aktualizace` |
| **Incompatible Version Alert Body** | `This backup was created in a newer version of Smack-a-Pad. Update the app to restore it.` | `Tato záloha byla vytvořena v novější verzi Smack-a-Pad. Pro její obnovení aktualizuj aplikaci.` |
| **Safety Backup Failure Alert** | `Could not create a safety backup. Import was cancelled.` | `Nepodařilo se vytvořit bezpečnostní zálohu. Import byl zrušen.` |

### 6.3 Document Picker Integration

- **Export:** Uses SwiftUI `.fileExporter(isPresented: $isExporting, document: backupDoc, contentType: .json, defaultFilename: "Smack-a-Pad backup \(today).json")`.
  - When tapped, serializes current state into a memory document and opens the native system picker. The user can save to Files, iCloud Drive, or AirDrop.
- **Import:** Uses SwiftUI `.fileImporter(isPresented: $isImporting, allowedContentTypes: [.json], allowsMultipleSelection: false)`.
  - When a file is selected:
    1. Obtains security-scoped access (`startAccessingSecurityScopedResource()`).
    2. Reads and parses the envelope JSON.
    3. Validates `envelope.app == "smack-a-pad"` and `formatVersion <= 1`. If invalid, presents the error alert and aborts.
    4. Creates a safety backup of the current state to `<Documents>/Backups/before-import-<timestamp>.json` (pruning to keep last 5).
    5. Performs pure merge in memory.
    6. Writes merged state to `<Documents>/progress.json.tmp` and performs an atomic replace of `progress.json`.
    7. Updates `BadgeStore.records` and calls `awardSilently`.
    8. If fresh device, applies portable settings to `SettingsManager`.
    9. Presents the success result alert.

---

## 7. Safety Backups & Recommendation on Daily Auto-Copy

### 7.1 Pre-Import Safety Backups (Hard Constraint 4)
- Location: `<Documents>/Backups/before-import-YYYYMMDD-HHmmss.json`.
- Kept count: Exactly the last **5** pre-import snapshots (older ones pruned automatically).
- Guarantee: Before any import changes memory or disk, the full pre-existing state is saved to this directory. If writing the safety backup fails, the entire import aborts immediately with zero modifications.

### 7.2 Rolling Automatic Local Copy (Ticket 161 §5 Recommendation)

**Question from ticket:** *After the first star of a day, keep a rolling automatic local copy (`<Documents>/Backups/auto-*.json`, last 3). It does not survive deletion of the app — say so honestly; it only protects against a corrupt file. Recommend yes/no.*

**Recommendation: YES.**

#### Honest Assessment:
- **What it CANNOT do:** Because `<Documents>` lives inside the iPad app sandbox container, **it will NOT survive the user deleting the app from their iPad**. We must be 100% honest about this: only Exporting to Files / iCloud Drive or CloudKit sync (162) survives app deletion.
- **Why YES anyway?**
  1. **Protection against file corruption:** If an unexpected crash, device power failure during save, or storage error corrupts `progress.json`, the app has 3 daily snapshots right in `<Documents>/Backups/` to automatically or manually recover from.
  2. **Zero noticeable cost:** Creating one copy per calendar day (triggered only when the user earns their first star of the day) costs ~30 ms of CPU and <150 KB total disk space for all 3 files.
  3. **Implementation simplicity:** Reuses the exact same backup envelope serialization code. Automatically rotates `auto-YYYYMMDD.json`, keeping only the newest 3.

---

## 8. Implementation Structure (Phase 2 Preview)

When approved by Jakub, Phase 2 will implement:

1. `SmackAPad/Sources/Persistence/ProgressBackup.swift`:
   - `ProgressBackupEnvelope`: Codable schema matching §3.2.
   - `BackupSettings`: Codable representation of non-device preferences.
   - Envelope encode/decode and validation helpers.
2. `SmackAPad/Sources/Persistence/ProgressMerge.swift`:
   - Pure merge functions:
     - `merge(local: LessonProgress, incoming: LessonProgress) -> LessonProgress`
     - `merge(local: TrainingLog, incoming: TrainingLog) -> TrainingLog`
     - `merge(localBadges: [String: Date], incomingBadges: [String: Date]) -> [String: Date]`
     - `merge(local: ProgressBackupEnvelope, incoming: ProgressBackupEnvelope, isFreshDevice: Bool) -> MergeResult`
3. `SmackAPad/Sources/Persistence/BackupStorage.swift`:
   - Pre-import snapshot writer and pruning (keeps last 5).
   - Daily rolling snapshot writer (keeps last 3).
4. `ProgressStore.swift`, `BadgeStore.swift`, `SettingsManager.swift`:
   - Add `modifiedAt: Date?` to `LessonProgress`.
   - Add `formatVersion: Int` to `ProgressRoot`.
   - Expose `exportEnvelope() -> ProgressBackupEnvelope` and `importEnvelope(_: ProgressBackupEnvelope) throws -> ImportSummary`.
5. `SettingsView.swift`:
   - Section "Progress" / "Pokrok" with the two buttons and alerts.
6. Localization:
   - English and Czech strings in `Localizable.strings` and `cs.tsv`.
7. Tests:
   - Complete unit test suite verifying all 10 test requirements from ticket 161.

---

## 9. Next Step

**Phase 1 is complete.**  
We stop here and await Jakub's review and approval ("ano" / adjustments) before writing any Phase 2 code.
