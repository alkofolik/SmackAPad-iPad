# 85 — Practice: shorter label on the "From memory for ★3" button

Status: ready. Source: Jakub, 2026-11-05 (photo 2): the button text is cut off ("From memory fo…").

## Rule

- Visible button label (`transportSecondAction`, the `Text` in the `Menu` label):
  - en: **"Memory ★3"**
  - cs: **"Zpaměti ★3"** (also fixes the spelling: "zpaměti" is one word)
- Add these as new keys (e.g. `"Memory ★3"`) in both `Localizable.strings`. Keep the existing key `"From memory for ★3"` for the menu item and for the VoiceOver label, and fix its Czech value to "Zpaměti pro ★3".
- The label must fit in one line without truncation at the transport square size in landscape and portrait, cs and en.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeScreen.swift` (`transportSecondAction` only), both `Localizable.strings`.

## Acceptance criteria

- [ ] Full label visible, no "…", cs and en, landscape and portrait.
- [ ] VoiceOver still reads the long form.
- [ ] Build passes; do not run tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium** thinking.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
