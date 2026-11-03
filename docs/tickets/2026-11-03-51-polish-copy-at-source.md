# 51 — Polish: copy fixed at the source (sentence case, short labels, no stray periods)

Status: ready-for-agent. Source: unslop audit, approved by Jakub 2026-11-03.
Blocked by: 48 (48 still searches for `localized("ACTIVE")`).

## Why

Many keys are written in capitals (`"SOUND KIT"`, `"1. PULSE"`) and are only turned into sentence case at runtime by `Theme.sentenceCase`. That is a patch. Some short status lines end with a period, one placeholder is wordy, and three subtitles use "&" while the rest of the app writes "and".

## Rules

- For every row: change the key in the Swift code **and** in both `SmackAPad/Resources/en.lproj/Localizable.strings` and `SmackAPad/Resources/cs.lproj/Localizable.strings`.
- If the new key already exists in a `.strings` file, keep the existing line and **delete** the old capital line. Never leave two lines with the same key.
- If it does not exist, replace the old line with the new key and the new value.
- Keep `Theme.sentenceCase` and its calls (it still handles category titles that come from lesson data). It does nothing to text that is not all capitals.
- Search the whole `SmackAPad/Sources` folder for each old key (`grep -rn '"OLD KEY"' SmackAPad/Sources`), not only the UI folder.

## Key changes

| Old key | New key (= en value) | cs value |
|---|---|---|
| `SOUND KIT` | `Sound kit` (exists) | `Zvuková sada` (exists) |
| `SOUND` | `Sound` (exists) | `Zvuk` (exists) |
| `PRACTICE SCREEN` | `Practice screen` | `Obrazovka cvičení` |
| `CONTROLLER PROFILES` | `Controller profiles` (exists) | `Profily kontroléru` (exists) |
| `KEYBOARD` | `Keyboard` (exists) | `Klávesnice` (exists) |
| `APPEARANCE` | `Appearance` (exists) | `Vzhled` (exists) |
| `LANGUAGE` | `Language` (exists) | `Jazyk` (exists) |
| `HARDWARE & CALIBRATION` | `Hardware and calibration` | `Hardware a kalibrace` |
| `INPUT MONITOR` | `Input monitor` (exists) | `Kontrola vstupu` (exists) |
| `TOUCH PADS` | `Touch pads` (exists) | `Dotykové pady` (exists) |
| `ACTIVE` | `Active` (exists) | `Aktivní` (exists) |
| `LEVEL` | `Level` | `Úroveň` |
| `MIDI LEARN` | `MIDI learn` (exists) | `Učení MIDI` (exists) |
| `INTRO SECTION RULES` | `Intro section rules` | `Pravidla úvodní sekce` |
| `TEMPO AUTO-STEP (BPM)` | `Tempo auto-step (BPM)` | `Zrychlení tempa (BPM)` |
| `REQUIRES 16 PADS` | `Requires 16 pads` | `Vyžaduje 16 padů` |
| `1. PULSE` | `1. Pulse` | `1. Puls` |
| `2. TWO HANDS` | `2. Two hands` | `2. Obě ruce` |
| `3. EIGHTH NOTES` | `3. Eighth notes` | `3. Osminové noty` |
| `4. GROOVE VARIATIONS` | `4. Groove variations` | `4. Variace groovů` |
| `5. CONTROL AND DETAIL` | `5. Control and detail` | `5. Kontrola a detail` |
| `6. FIRST FILLS` | `6. First fills` | `6. První přechody` |
| `Search lessons...` | `Search` | `Hledat` (cs exists; add `"Search" = "Search";` to en) |
| `From memory · notes hide after START` | `From memory · notes hide once you start` | `Z paměti · pattern se po spuštění skryje` |
| `Calibration saved.` | `Calibration saved` | `Kalibrace uložena` |
| `Outlier taps were ignored.` | `Outlier taps were ignored` | `Odlehlé úhozy byly vynechány` |
| `Eighth-note hi-hat patterns & stability · lessons 9–12` | `Eighth-note hi-hat patterns and stability · lessons 9–12` | unchanged value |
| `Syncopations, offbeats & clap · lessons 13–16` | `Syncopations, offbeats and clap · lessons 13–16` | unchanged value |
| `Dynamics, open hi-hat & rests · lessons 17–21` | `Dynamics, open hi-hat and rests · lessons 17–21` | unchanged value |

Leave multi-sentence messages with their periods (for example `Ready. Choose an input and start.`).

## Files to read

`AGENTS.md`, this ticket, both `Localizable.strings` files, and the Swift files where `grep` finds the old keys (expected: `SettingsView.swift`, `ContentView.swift`, `IntroScreen.swift`, `LibraryScreen.swift`, `PracticeScreen.swift`, `CalibrationView.swift`, and the file that holds the intro subtitles).

## Acceptance criteria

- [ ] `grep -rnE 'localized\("[A-Z0-9 .&()-]{4,}"\)' SmackAPad/Sources` finds no all-capital keys (abbreviations like `"BPM"` alone are fine).
- [ ] No duplicate keys in either `.strings` file (`plutil -lint` passes for both).
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: Settings section headers, Intro page, Library search, calibration result, in Czech and English.

## Agent assignment

- **Agent**: Gemini 3.8 Flash (Antigravity), low thinking.

## Done rule

Stop after a successful build; do not commit.
