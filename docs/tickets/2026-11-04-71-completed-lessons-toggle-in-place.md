# 71 — Library and Intro: hide completed lessons again without going to Settings

Status: ready. Source: Jakub, 2026-11-04: "On Intro I used Show completed, they appeared, but I don't know how to hide them again." Follows ticket 65.

## Today

The "Show completed" button (`IntroScreen.swift`, `LibraryScreen.swift`) sets `settings.hideCompletedLessons = false`. The only way back is the Settings toggle, which nobody finds from the list.

## Rule

- On the Intro page and in the library detail pane, add one toolbar button (top bar, trailing) that switches the same setting both ways:
  - setting on → icon `eye` + label "Show completed" / "Zobrazit hotové";
  - setting off → icon `eye.slash` + label "Hide completed" / "Skrýt hotové".
- Visible only when the current list contains at least one completed lesson.
- Keep the in-list "Show completed" button of the all-completed line as it is.
- Same setting as in Settings (one source of truth); list motion as in ticket 65.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/IntroScreen.swift`, `SmackAPad/Sources/UI/LibraryScreen.swift` (toolbar, `Show completed`), `SmackAPad/Sources/Persistence/Persistence.swift` (`hideCompletedLessons`), both `Localizable.strings`.

## Acceptance criteria

- [ ] Show and hide again from the Intro page and the library, without Settings.
- [ ] Settings toggle reflects the change.
- [ ] Cs and en; light and dark; VoiceOver labels.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
