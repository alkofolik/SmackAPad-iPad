# 15 — Localisation (English primary, Czech optional)

Status: ready-for-review (updated 2026-11-01)

## Goal

Move all user-facing text into the localisation catalogs. **English is the primary and default language; Czech is optional and selectable in Settings.**

## Files to read

- `AGENTS.md`
- `docs/DECISIONS.md` (§19 Localisation)
- `SmackAPad/Resources/en.lproj/Localizable.strings`, `SmackAPad/Resources/cs.lproj/Localizable.strings`
- `SmackAPad/Sources/Persistence/Persistence.swift` (`AppLanguage`, `defaultLanguage`)

## Current state

- User-facing text is currently duplicated in code as `czech ? "…" : "…"` and the helper `label(cs, en)` (about 98 places) in `LibraryScreen`, `IntroScreen`, `SettingsView`, `ContentView` (MIDI learn), `PracticeScreen`, `PracticeComponents`, `PatternField` and `Progression.swift`.
- Catalog files already exist (about 100 lines each).
- `AppLanguage.defaultLanguage` is already `.english`; the language picker lists English first, then Czech. Do not change this.

## Tasks

1. List every occurrence of `czech ?` and `label(` (file, line, Czech text, English text).
2. For each text create a key in BOTH `Localizable.strings` files (identical key sets). English is the reference wording; Czech is the translation.
3. Replace the code with `String(localized:)` or `LocalizedStringKey`. Texts with variables become format keys (`%d`, `%@`).
4. Remove `czech` / `label` helpers where no longer needed.
5. The language switch in Settings must take effect immediately. The app uses `settings.languagePreference`, not the system language, so make sure strings really load from the selected language (e.g. `.environment(\.locale, …)` plus loading from the matching bundle).
6. Do not change logic, visual design or file names.

## Acceptance criteria

- [x] No hardcoded user-facing text remains in code.
- [x] English and Czech have the same key set.
- [x] A fresh install starts in English; Czech can be selected in Settings and applies immediately.
- [x] Build succeeds.
- [ ] **iPad test (Jakub)**: both languages display correctly, no truncation or layout issues, switching at runtime works.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, High (Antigravity)
- **Reasoning**: String extraction and file conversion, no complex logic.

## Done rule

Stop after successful build; Jakub tests on iPad. Commit after the task.
