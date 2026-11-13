# 193 — No monospaced ("typewriter") text anywhere in the app

Status: ready-for-agent. Asked by Jakub on 2026-11-13 (taste audit findings 3, 29, 48, 49).

## Goal

Some labels use the system monospaced font, which looks like typewriter or code text. Jakub does not like it, and it is one of the clearest "AI-generated" tells in the audit. Replace every monospaced text with the app's own fonts. Where the label is a small uppercase, letter-spaced tag above a heading (an eyebrow), delete it, because the step strip or the position on screen already says the same thing.

## Rules

1. **Delete `Theme.stepTag`** and every use of it. On the Today hand-off and summary cards (`TodaySessionScreen.swift`, the `kicker` labels at about lines 836 and 928): delete the label (for example "FIRST STEP OF THE DAY"); the step strip already shows the step.
2. **"STEP %lld OF 4"** (`TrainingScreen.swift` about line 1012) and **"Step %lld of 4"** (about line 1156): sentence case "Step 2 of 4", in `Theme.meta` (Plex Sans), with `.monospacedDigit()` only so the figure does not jump. No `.uppercased`, no `.tracking`. Remove the uppercase string key from both `Localizable.strings` files if nothing else uses it.
3. **Step tags with `.tracking`** in `TodaySessionScreen.swift` (the `stepTag(...)` helpers about lines 515/564 and 1215/1329) and in `TrainingScreen.swift` (the tracked labels about lines 518, 1207, 1315): sentence case in Plex Sans, no tracking, no uppercase. If the tag only repeats the position ("1 · Reviews"), drop the number and keep the word.
4. **Keyboard keys in Settings** (`SettingsView.swift` about line 310, the Q W E R rows): show each key as a small keycap (rounded tone-step background, `Theme` colours) in `Theme.control`, not as monospaced text joined by spaces.
5. **Search the whole app** for `.monospaced()`, `design: .monospaced` and `Font.system(...).monospaced` and remove them all. `.monospacedDigit()` stays allowed (it only fixes figure widths).
6. Delete what becomes unused (helpers, string keys); no dead code.

## Files to read

`AGENTS.md`, `Theme.swift`, `TodaySessionScreen.swift`, `TrainingScreen.swift`, `SettingsView.swift`, `en.lproj/Localizable.strings`, `cs.lproj/Localizable.strings`.

## Tests

None (font change only). If a localization test lists the removed keys, update it.

## Acceptance criteria

- [x] `grep` for `.monospaced()` and `design: .monospaced` in `SmackAPad/Sources` finds nothing.
- [x] Training and Today screens show no small uppercase letter-spaced labels; "Step 2 of 4" is in sentence case.
- [x] Settings shows the keyboard keys as keycaps.
- [x] Czech and English both correct.
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

Training → Today session → hand-off card and day summary; Settings → keyboard pads: no typewriter text anywhere, nothing looks missing.

## Agent assignment

Gemini 3.8 Flash, thinking **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
