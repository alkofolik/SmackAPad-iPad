# 13 — Settings Screen

Status: ready-for-agent

## Goal

Build the settings screen: kit selection, BPM step, controller profile management, MIDI learn trigger, language switch.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.8 Screens — Settings)
- `docs/DECISIONS.md` (§2 Pad layouts, §11 Persistence, §19 Localisation)

## Tasks

1. **Kit selection**: picker showing all 9 kit names from sample-kits.json. Selection saved to SettingsManager.
2. **BPM step**: picker with options 1, 2, 5, 10. Saved to SettingsManager.
3. **Controller profiles**: list of saved profiles (presets + custom). Active profile indicator. Delete custom profiles.
4. **MIDI learn**: button that opens the MIDI learn flow (from ticket 06).
5. **Language**: switch between Czech and English. Saved to SettingsManager. App updates immediately.
6. Use Theme.swift tokens for all styling.

## Acceptance criteria

- [ ] Settings screen allows kit, BPM step, profile, and language changes.
- [ ] All settings persist across app restarts.
- [ ] **iPad test**: all screens render correctly on iPad, landscape and portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: Standard settings UI, reads from existing data models.

## Done rule

Stop after successful build; Jakub tests on iPad.
