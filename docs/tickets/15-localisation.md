# 15 — Localisation (Czech + English)

Status: ready-for-agent

## Goal

Implement full Czech + English localisation for all UI strings.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§1 Goals — localisation, §9 Open Questions — cs.tsv completeness)
- `docs/DECISIONS.md` (§19 Localisation)

## Tasks

1. Convert legacy `cs.tsv` (tab-separated key/value) into Swift-native `.strings` or `.xcstrings` format.
2. Create `en.lproj/Localizable.strings` and `cs.lproj/Localizable.strings`.
3. Audit all UI screens for hardcoded strings. Replace with `NSLocalizedString` / `String(localized:)`.
4. Add any new strings needed for the native app that weren't in the legacy `cs.tsv` (settings labels, calibration instructions, progression messages, etc.).
5. Czech is the primary language. Language switchable from settings (ticket 13).
6. Ensure the app respects the user's language setting from SettingsManager.

## Acceptance criteria

- [ ] All UI strings are localised (no hardcoded user-facing text).
- [ ] Czech and English translations present for every string key.
- [ ] Language switch in settings takes effect immediately.
- [ ] New strings not covered by legacy cs.tsv are identified and translated.
- [ ] **iPad test**: both languages display correctly, no truncation or layout issues.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: String extraction and file conversion, no complex logic.

## Done rule

Stop after successful build; Jakub tests on iPad.
