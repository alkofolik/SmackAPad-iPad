# 122 — Practice header: subtitle on one line

Status: ready-for-agent. Source: Jakub, 2026-11-06, screenshot of Practice in Play mode, Czech.

## Problem

Under the lesson title (top left, next to "Knihovna") the subtitle wraps onto two lines, e.g. "Opakování · krok 1 ze 4 · zpaměti při 94 / BPM, 80 %". Jakub does not like the two lines.

## Rules

1. The header subtitle is always one line, in every mode and session type (Library, Training/review step, Today, Just practice), Czech and English, portrait and landscape.
2. Make it fit by shortening the **content**, not by "…" and not by tiny text: keep the most important part (session/step, e.g. "Opakování · krok 1 ze 4") in the header; the goal ("zpaměti při 94 BPM, 80 %") moves to a place that already shows goals (the star requirement / goal line), or gets a shorter Czech and English wording (e.g. "zpaměti · 94 BPM · 80 %"). Choose one and say which in the report.
3. Shrink limit: `minimumScaleFactor` floor 85 %. Header height must not change between modes (see also ticket 123).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PracticeScreen.swift` (header), `SmackAPad/Sources/UI/StarRequirement.swift`, both `Localizable.strings` (header strings only).

## Acceptance criteria

- [ ] Subtitle on one line in all session types, Czech and English, both orientations.
- [ ] No "…", no lost information.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: Training review step in Czech, portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: text and layout in one view.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
