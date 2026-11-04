# 72 — Library: hide and show whole categories in the sidebar

Status: ready. Source: Jakub, 2026-11-04: "I'd like to hide and show whole categories in the left column of the library, e.g. by a gesture and confirmation, or hold and confirm." Run after ticket 71 (both touch `LibraryScreen.swift`).

## Rule

- **Hide**: long press (about 0.5 s) on a sidebar row — a path level ("Level 3"), a group (stage, genre, technique) or an extension group — opens a context menu with one action "Hide category" / "Skrýt kategorii". Choosing it asks once in a confirmation dialog: "Hide “%@”? You can show it again at the bottom of the list." / "Skrýt „%@“? Znovu ji zobrazíš dole v seznamu." with "Hide" and "Cancel".
- The Intro exercises row and the overall progress row cannot be hidden.
- **Show again**: at the bottom of the sidebar a collapsed section "Hidden categories (n)" / "Skryté kategorie (n)", shown only when n > 0. Expanding it lists the hidden rows in a muted style; long press (or a trailing "Show" button) → "Show category" / "Zobrazit kategorii", no confirmation needed.
- Hidden categories are stored per view mode (path / genre / technique) in `SettingsManager` (`Persistence.swift`) as a set of ids, persisted like other library settings and cleared by the existing settings reset.
- Hiding only affects the sidebar. Search, Continue, the "Next" banner, unlock logic, counts and stars still use all lessons. If the selected group gets hidden, select the first visible one.
- Use the existing list motion (`Theme.Motion`); Reduce Motion as elsewhere.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/LibraryScreen.swift` (`sidebar`, `sidebarRow`, `sidebarLabel`, `groups`), `SmackAPad/Sources/Persistence/Persistence.swift` (`SettingsManager`, library settings, reset), both `Localizable.strings`.

## Acceptance criteria

- [ ] Hide a level, a group and an extension group via long press + confirm; they move to "Hidden categories".
- [ ] Show again from that section; state survives app restart.
- [ ] Search still finds lessons from hidden categories.
- [ ] Cs and en; light and dark; VoiceOver (custom actions "Hide category" / "Show category").
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
