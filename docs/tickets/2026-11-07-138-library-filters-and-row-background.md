# 138 — Library and Intro: all filters visible, no grey band behind lesson rows

Status: ready-for-agent. Type: implementation. Depends on: 133 (chip style). Source: Jakub, 2026-11-07 (Library and Intro screenshots).

## Problems

1. Filter row is cut off: "Vymazat" is half hidden; chips are wide because of long labels.
2. Between and behind lesson rows there is a **grey band** (list/scroll background) that does not match the warm page background. Seen in Library (rows Rock 1 / Funk 1) and Intro (between section 1 "Puls" and section 2 "Obě ruce").

## Rules

1. Shorter Czech chip labels: "Rozehráno" → **"Začaté"**, "Nezahájeno" → **"Nové"** (cs strings only; English unchanged). Counts stay: "Nové (24)".
2. "Vymazat" becomes an icon-only clear button (xmark) with accessibility label "Vymazat filtry"; shown only when a filter is active.
3. All chips fit in one row on iPad 11″ landscape. If they do not fit (portrait), the row scrolls horizontally; nothing is clipped mid-chip.
4. Lesson list background = page background (`Theme` page colour). Remove the `List`/`ScrollView` grey (`scrollContentBackground(.hidden)`, row/section backgrounds `.clear`, no section inset fill). Rows keep their own plate.
5. No other layout change.

## Files

`LibraryScreen.swift`, `IntroScreen.swift`, `Components.swift` (`FilterChip`) only if needed, both `Localizable.strings`.

## Acceptance criteria

- [ ] Every filter fully visible (landscape) or scrollable (portrait).
- [ ] No grey band in Library or Intro, light and dark.
- [ ] Build succeeds. No new tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build. Commit (AGENTS.md); Jakub tests on the iPad.
