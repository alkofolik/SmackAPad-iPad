# 13 — Settings Screen

Status: implemented; build OK; awaiting iPad verification

## Goal

Build the settings screen: kit selection, BPM step, controller profile management, MIDI learn trigger, language switch.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.8 Screens — Settings)
- `docs/DECISIONS.md` (§2 Pad layouts, §11 Persistence, §19 Localisation)

## Tasks

1. **Kit selection**: picker showing all 8 kit names from sample-kits.json. Selection saved to SettingsManager.
2. **BPM step**: picker with options 1, 2, 5, 10. Saved to SettingsManager.
3. **Controller profiles**: list of saved profiles (presets + custom). Active profile indicator. Delete custom profiles.
4. **MIDI learn**: button that opens the MIDI learn flow (from ticket 06).
5. **Language**: switch between Czech and English. Saved to SettingsManager. App updates immediately.
6. Use Theme.swift tokens for all styling.

## Acceptance criteria

- [x] Settings screen allows kit, BPM step, profile, and language changes.
- [x] All settings persist across app restarts.
- [ ] **iPad test**: all screens render correctly on iPad, landscape and portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: Standard settings UI, reads from existing data models.

## Done rule

Stop after successful build; Jakub tests on iPad.

## Implementation notes (2026-11-01)

- Created `SettingsView.swift` implementing all required settings sections using `Theme` tokens:
  1. **Kit selection**: picker loading all 8 kit names from `sample-kits.json` in canonical order, bound to `settings.selectedKitId` and persisted via `SettingsManager`.
  2. **BPM step**: segmented picker with options 1, 2, 5, 10, bound to `settings.bpmStep` and persisted via `SettingsManager`.
  3. **Controller profiles**: list of presets and custom profiles with clear active indicator, tap-to-select, and custom profile deletion with confirmation dialog.
  4. **MIDI learn trigger**: button opening `MIDILearnView` sheet styled with `Theme` tokens and localized strings.
  5. **Language switch**: segmented picker between Czech and English updating `SettingsManager` and triggering immediate UI re-rendering.
  6. **Hardware & Calibration**: integrates MIDI source selection, Bluetooth MIDI presenter, and Timing calibration link.
- Updated `LessonPicker.swift` toolbar to present `SettingsView` via "Nastavení" / "Settings" button.
- Updated `ContentView.swift` so `MIDISettingsView` delegates to `SettingsView` and `MIDILearnView` / `TouchPad` / `PadNames` are accessible across module.
- Added localized strings for settings to `cs.lproj` and `en.lproj`.

