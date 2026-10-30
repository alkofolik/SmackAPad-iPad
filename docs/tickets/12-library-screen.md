# 12 — Library Screen

Status: ready-for-agent

## Goal

Build the lesson library screen: browse by category/genre, show pass/mastery status, locked categories with soft unlock, a "requires 16 pads" label for lessons without an 8-pad layout.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.7 Progression, §3.8 Screens — Library, §6 8-Pad Controller Rule)
- `docs/DECISIONS.md` (§15 Progression, §16 Intro, §17 Electronic path)

## Tasks

1. Category list with lock/unlock state from ProgressionManager.
2. Per-lesson: title, genre, level, pass/mastery badge.
3. Locked categories: shown with lock icon + soft-unlock tap → confirmation → immediate unlock.
4. 8-pad mode: all bundled lessons are playable (SPEC §6). Show a greyed-out "requires 16 pads" label only for a lesson whose `EightPadLayout` is nil (none today; needed for future content packs). Still visible, still openable.
5. Intro section as a separate entry point (always accessible).
6. Electronic-path lessons appear in their main categories (not a separate section).
7. Use Theme.swift tokens for all styling.

## Acceptance criteria

- [ ] Library shows all categories, genres, pass/mastery status.
- [ ] Locked categories display lock icon.
- [ ] Soft unlock works with tap + confirmation.
- [ ] A lesson with no 8-pad layout is shown greyed-out with the label in 8-pad mode.
- [ ] Intro section has a separate entry point, always accessible.
- [ ] **iPad test**: all screens render correctly on iPad, landscape and portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: UI screen driven by data models and progression logic. No hardware interaction.

## Done rule

Stop after successful build; Jakub tests on iPad.
