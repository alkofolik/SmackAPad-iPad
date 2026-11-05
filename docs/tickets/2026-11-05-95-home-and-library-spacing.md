# 95 — Home grid centred and larger; Library header spacing even

Status: resolved. Source: Jakub, 2026-11-05 (agreed with Claude's review).

## Rule

- **Home**: make the 3×3 tile grid slightly larger and centre the grid (with the title) vertically, so the space above the title and below the grid is equal. Keep the title, tiles and their texts as they are. Content stays centred and does not stretch beyond a sensible maximum width on the iPad.
- **Library**: in the top-right row of controls (search, filter chips, Clear) use one equal gap between all neighbouring controls and the same control height. No control is added or removed.
- No decoration, no new elements.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/HomeScreen.swift`, `SmackAPad/Sources/UI/LibraryScreen.swift` (header/filter row only), `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [x] Home: equal space above and below the group on portrait and landscape.
- [x] Library: equal gaps and heights in the filter row.
- [x] Build passes; do not run tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium. Run after 92 (same Theme/HomeScreen files).

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
