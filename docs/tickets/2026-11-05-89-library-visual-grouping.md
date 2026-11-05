# 89 — Library: separate levels, categories and lessons visually

Status: ready. Source: Jakub, 2026-11-05 (photo 6): "The library needs the lessons, categories and courses separated more — for example with a frame. So it's not just a pile of text on top of each other."

## Rule

Use the existing tokens only (`Theme.surface`, `Theme.hairline`, `Theme.Space`, `Theme.Size.border`, existing radius). Follow the house style of the app (flat, hairline outlines, no shadows, no gradients). Read the rules of the `design-taste-frontend` skill only; do not run its scripts.

### Sidebar
- Each **level** ("Level 1 · 82/357") is a header with a slightly stronger weight; its **categories** sit inside one framed group under it (one rounded box with `Theme.surface` fill or hairline outline, categories separated by hairlines inside the box). Collapsed levels are a single framed row.
- The selected category gets a clear selected state (filled background), not only text colour.
- Locked categories keep the lock, inside the same box.

### Lesson list (detail)
- Each lesson row is its own card: rounded rectangle, hairline outline (or `Theme.surface` fill), `Theme.Space.small` gap between cards. Number, title, meta, pattern strip, stars and info button stay in today's order, aligned inside the card.
- The category header ("Level 1 · Basic groove", progress, "Play next") sits above the cards, clearly separate from the first card.

### Bug seen on the same photo
- At the top left, the overall progress ("Overall progress ★ 82/1 722 · 574 lessons", `overallCourseProgress`) is drawn over the status bar and the "Home" / "Library" title. Move it so nothing overlaps (e.g. into the sidebar under the title, or the toolbar), in both orientations.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/LibraryScreen.swift` (`sidebar`, `pathLevelsList`, `sidebarRow`, `sidebarLabel`, `detail`, `overallCourseProgress`, `LibraryLessonRow`), `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [ ] Levels, categories and lessons are visibly grouped; nothing reads as one block of text.
- [ ] Selected category is obvious.
- [ ] No overlap at the top left.
- [ ] Light and dark; landscape and portrait; cs and en (long Czech titles still fit).
- [ ] VoiceOver order unchanged.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: scroll Level 1 and open Level 2.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking. Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
