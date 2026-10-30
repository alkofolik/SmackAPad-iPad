# 05 — Progression (Category Unlock Logic)

Status: ready-for-agent

## Goal

Implement the category unlock / progression system.

## Files to read

- `AGENTS.md`
- `docs/SPEC.md` (§3.7 Progression, §6 8-Pad Controller Rule)
- `docs/DECISIONS.md` (§15 Lesson progression, §16 Intro)

## Tasks

1. Define category order: starter, eighth, sixteenth, electronic, ghost, swing, world, fills.
2. First category (starter) unlocked by default.
3. Unlock rule: passing 5 lessons in the current category unlocks the next. Configurable constant `kLessonsToUnlock = 5`.
4. Soft unlock: user taps a locked category → confirmation alert → immediate unlock.
5. 8-pad users: progression counts only playable lessons. Never blocked by 16-pad-only lessons.
6. Intro section (24 exercises): always accessible, no unlock needed, separate section.
7. Electronic-path lessons folded into the main category/genre system.

## Acceptance criteria

- [ ] First category unlocked by default.
- [ ] Next category unlocks after 5 passed lessons in current category.
- [ ] Soft unlock works with single tap + confirmation.
- [ ] 8-pad users can unlock categories without needing 16-pad lessons.
- [ ] Intro section always accessible.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: Business logic without hardware dependencies.

## Done rule

Stop after successful build; Jakub tests on iPad.
