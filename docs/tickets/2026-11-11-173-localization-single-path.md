# 173 — One localisation path and a test that every key exists in both languages

Status: ready-for-agent. Approved by Jakub on 2026-11-11. Corresponds to AI panel item #31. No behaviour or look change.

## Goal

All UI text comes from one place: `en.lproj/Localizable.strings` and `cs.lproj/Localizable.strings`. An automated test guarantees that no key is missing in either language.

## Rules

- No new UI text, no new features, no change to existing translations except fixing defects the new test finds.
- Delete dead code and tests for the removed path (AGENTS.md).
- Czech translations are written in plain Czech in the style of the existing app. If the meaning of a key is unclear, do not guess: list it as open in the inventory and leave it for Jakub.

## Known starting point (verify first)

- EN has 818 keys, CS has 819.
- Only in EN: `"%lld lessons due for review"`, `"1 lesson due for review"`, `"Review in %lld days · practice only"`.
- Only in CS: `"%lld lekce čekají na opakování"`, `"%lld lekcí čeká na opakování"`, `"1 lekce čeká na opakování"`, `"Learn a new profile (MIDI learn)"`.
- `localized(_:)` in `Persistence/Persistence.swift` (~line 189) falls back to `czechTSVLookup`: a second translation path.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Resources/{en,cs}.lproj/Localizable.strings`, `SmackAPad/Sources/Persistence/Persistence.swift` (the `AppLanguage` / `localized` part only), the existing localisation tests in `SmackAPadTests/`.

## Steps

1. Inventory: compare the keys of both files and all `localized("…")` / `String.LocalizationValue` keys used in code. Write the result to `docs/design/2026-11-11-173-localization-inventory.md` (key, where missing, action).
2. Find out what `czechTSVLookup` contains. Move every entry that `cs.lproj` lacks into `cs.lproj/Localizable.strings`, then delete the table and its loading code.
3. Add the missing EN and CS keys. Do not touch correct existing values.
4. Keep one public lookup path, `localized(_:)`. The argument and `String.LocalizationValue` variants only forward to it.
5. Add one test that loads both files and checks: (a) every key exists in both languages, (b) no duplicate key inside a file, (c) the same format specifiers (`%lld`, `%@`, `%d`, …) in both languages for each key, (d) no empty value. Czech plural variants legitimately have different keys: handle them with an explicit exception list with a comment explaining why, never a silent skip.

## Tests

The new test above. The full existing suite (238+ tests) must pass unchanged, except tests for the removed TSV path.

## Acceptance criteria

- [ ] No `czechTSVLookup` or any second translation path remains.
- [ ] The new test passes and fails if a key is removed from either file (check once by hand, then restore).
- [ ] The inventory lists what was fixed and what stays open.

### Manual iPad check for Jakub

Switch the language between English and Czech and walk through Home, Practice, Training, Settings and Help. Look for English text in the Czech UI and the other way round.

## Agent assignment

Codex GPT-6.1 Sol, thinking high (fallback Gemini 3.8 Pro, high). Do not use Flash: it can miss format specifiers and plural keys when moving strings.

## Done rule

Build, full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check. Final report: max 5 lines.
