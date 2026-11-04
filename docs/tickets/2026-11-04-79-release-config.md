# 79 — Release configuration: privacy manifest, export compliance, release hygiene

Status: parked (App Store release track, not scheduled). Source: Claude's pre-release audit, 2026-11-04.

## Why

App Store Connect rejects or warns on uploads without a privacy manifest when the app uses "required reason" APIs. The app uses `UserDefaults`, `mach_absolute_time` (system boot time category) and file `creationDate` (file timestamp category). Without `ITSAppUsesNonExemptEncryption` every TestFlight build stops at the export-compliance question.

## Rule

1. Add `SmackAPad/PrivacyInfo.xcprivacy` to the app target (Copy Bundle Resources):
   - `NSPrivacyTracking` = false, `NSPrivacyTrackingDomains` = empty, `NSPrivacyCollectedDataTypes` = empty (the app collects nothing; progress stays on the device).
   - `NSPrivacyAccessedAPITypes`:
     - `NSPrivacyAccessedAPICategoryUserDefaults` → `CA92.1`
     - `NSPrivacyAccessedAPICategorySystemBootTime` → `35F9.1`
     - `NSPrivacyAccessedAPICategoryFileTimestamp` → `C617.1`
   - Before finishing, grep `SmackAPad/Sources` for other required-reason APIs (`systemUptime`, `volumeAvailableCapacity`, `attributesOfItem`, `modificationDate`, `activeInputModes`) and add categories only if found.
2. Add `ITSAppUsesNonExemptEncryption` = NO (Info.plist or `INFOPLIST_KEY_` build setting, both configurations).
3. Release hygiene, report only (do not change behaviour without asking Jakub):
   - List everything that is visible in a **Release** build but meant for development (diagnostics toggles, debug sections, log files written to Documents). The legacy import must stay `#if DEBUG`.
   - `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` expose `Documents/progress.json` in the Files app. Report whether anything else lands in Documents in Release. Jakub decides whether to keep it (backup use) or remove it.
   - Confirm `MARKETING_VERSION` 1.0 and `CURRENT_PROJECT_VERSION` 1 are set for both configurations; do not bump them.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad-Info.plist`, `SmackAPad.xcodeproj/project.pbxproj` (app target), `SmackAPad/Sources/MIDI/BluetoothTimingDiagnostics.swift`, `SmackAPad/Sources/Audio/AudioTimingDiagnostics.swift`, `SmackAPad/Sources/Persistence/Persistence.swift` (file locations only).

## Acceptance criteria

- [ ] `PrivacyInfo.xcprivacy` is in the app bundle (check in the built `.app`).
- [ ] Release build passes (`xcodebuild -configuration Release`); do not run tests.
- [ ] Short report in the final message: release-visible debug items, Documents contents, version numbers.
- [ ] **Jakub**: Product → Archive succeeds; Organizer → *Generate Privacy Report* lists the three categories.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests, Claude commits afterwards.
