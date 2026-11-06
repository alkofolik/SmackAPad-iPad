# 116 — Home pads: text is never cut off

Status: ready-for-agent. Depends on: 112 (same `HomePadView`). Source: Jakub, 2026-11-06: "I don't like the incomplete text on the pad top left, or really anywhere."

## Problem

`HomePadView` (`HomeScreen.swift`) limits text: title `lineLimit(2)`, subtitle `lineLimit(1…2)` with `truncationMode(.tail)`, second subtitle `lineLimit(1)`, all with `minimumScaleFactor(0.8)`. On the top-left hero pad (Continue / TODAY: title, lesson name, stars) and on other pads a long lesson name or a Czech text ends with "…". A name that is cut off is useless to the player.

## Rules

1. **No ellipsis on any Home pad** in any state (Continue with a long lesson name, TODAY with its subtitle, Library counts, Training "x due", Badges, Full version, Settings), in English and Czech, landscape and portrait, smallest and largest supported iPad, and with larger Dynamic Type (up to the size the app already supports).
2. Remove `truncationMode(.tail)` and the fixed `lineLimit`s on pad texts. Allow wrapping to as many lines as needed; keep the title on top, subtitles below, the block centred in the pad.
3. If the text still does not fit the pad at full size, shrink it in steps down to a floor of 75 % of the base size (`minimumScaleFactor`) and only then shorten the **content**, not with "…": for the lesson name use the short form if the lesson has one; otherwise show the lesson number plus the first words that fit on a whole word boundary. The full name stays in the accessibility label.
4. Check every pad text with a small throwaway list of the longest real lesson titles and the longest Czech strings (no new unit tests; inspect on the iPad build or in previews). Report the longest case you tested and how it looks.
5. Pad size, grid and look stay as ticket 112 defines them; only text handling changes. Do not make pads bigger.
6. Same fix for any other pad-like tile with cut text on Home (the Training pad, the logo tile has no text).

## Files to read

`AGENTS.md`, this ticket, ticket 112, `SmackAPad/Sources/UI/HomeScreen.swift` (`HomePadView`, pad definitions ~lines 460–600), `SmackAPad/Sources/UI/Theme.swift` (fonts), both `Localizable.strings` (Home texts only).

## Acceptance criteria

- [ ] No "…" on any Home pad, English and Czech, landscape and portrait.
- [ ] Long lesson name on the hero pad is whole or shortened at a word boundary, never cut mid-word.
- [ ] VoiceOver still reads the full name.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: Continue with the longest lesson title, in Czech, portrait and landscape.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: text-fitting fix in one view; medium is enough because the rule set is explicit.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
