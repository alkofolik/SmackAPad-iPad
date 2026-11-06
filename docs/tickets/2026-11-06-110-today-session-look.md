# 110 — Today session screen: match the mockup (frame 3)

Status: ready-for-agent. Source: Jakub, 2026-11-06: "the Today screen looks terrible, nothing like the design". Depends on: 109 (same file; do 109 first).

Mockup: `docs/design/2026-11-05-training-page/training-page.html`, frame **3 · Přechod mezi kroky dnešního tréninku** (`.handoff` block, CSS lines ~107–108). Open it in a browser and compare side by side with the app.

## What is wrong now (`TodaySessionScreen.swift` body)

- Large screen title "Today" on top that the mockup does not have.
- All content sits inside a bordered surface **panel** (`Theme.surface` + hairline). The mockup has no panel: content lies directly on the page background.
- Outcome is shown as lesson title (row title) + plain line; the mockup leads with the **result sentence** in big type.
- No small step label ("REVIEW 1 OF 2") and no "NEXT" label.
- Buttons are stacked vertically; the mockup puts them **in one row**.
- Content is squeezed to 760 pt in a ScrollView; on iPad landscape it reads like a form, not like a screen.

## Target layout (top to bottom, left aligned, generous padding like the mockup's 28 px)

1. Small label, mono, secondary colour, uppercase, letter-spaced: the step just played, e.g. "REVIEW 1 OF 2" / "OPAKOVÁNÍ 1 ZE 2", "NEW LESSON" / "NOVÁ LEKCE", "MIX".
2. **Big result sentence** (about 28 pt bold, condensed like Theme display titles, balanced wrapping): the outcome text from ticket 103 (review feedback, "Best score: 91 %", "Not played").
3. Meta line, secondary colour: lesson title · score · tempo, e.g. "Rock 2 · Hi-hat eighths · 91 % from memory at 96 BPM". Leave out parts that are not known.
4. Small label "NEXT" / "DALŠÍ" (same style as 1), some space above it.
5. Next step, about 20 pt semibold: "Funk 1 · Shuffle (review 2 of 2)".
6. One horizontal row of buttons: **Continue** (filled, main) · **Skip** · **Done for today** (outlined). Square corners, ticket 94.
7. Before the first step (nothing played yet) leave out 1–3 and start with "NEXT".
8. End card ("That's enough for today"): same typography — big sentence "That's enough for today", then the day's numbers as meta lines, then the Home button. No panel.

Use only Theme tokens (fonts, colours, spacing). Add new Theme tokens only if a size from the mockup has no match, and name them by role. Keep the Home top-bar button from ticket 109. Keep working in portrait (buttons may wrap to two rows only when they do not fit). Light and dark mode both.

## Files to read

`AGENTS.md`, this ticket, ticket 103, ticket 109, the mockup above, `SmackAPad/Sources/UI/TodaySessionScreen.swift`, `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Sources/UI/PracticeScreen.swift` (result card typography only, for consistency), both `Localizable.strings`.

## Rules

- Layout and text only. Do not change the session logic, plan storage or the coordinator.
- New strings in `en` and `cs`.
- design-taste-frontend: you may read its rules; never run its scripts or browser steps (AGENTS.md).

## Acceptance criteria

- [ ] Side by side with mockup frame 3 the screen has the same order, hierarchy and no panel.
- [ ] Buttons in one row on iPad landscape.
- [ ] End card uses the same typography.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: run a Today session in light and dark mode, landscape and portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: a single-screen layout rewrite against a clear mockup; high thinking so it reads the mockup carefully instead of patching the old panel.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
