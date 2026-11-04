# 74 — Library: hide the completed Intro row; remove the eye button from the library toolbar

Status: ready. Source: Jakub, 2026-11-04 (photos 3–4). Follows tickets 71 and 72 (all touch `LibraryScreen.swift`).

## Problems

1. Intro exercises is fully done (75/75) but stays at the top of the sidebar. Ticket 72 made it impossible to hide.
2. The "Hide/Show completed" eye button in the library detail toolbar (ticket 71) sits oddly next to Settings and duplicates the filter chips (All, 3★, 2★, 1★, In progress, Not started), which already let him narrow the list.

## Rule

1. **Intro row can be hidden** with the same long press → "Hide category" → confirm flow as other categories (ticket 72). It then appears in "Hidden categories (n)" and can be shown again there. The overall progress row stays unhideable. Store it with the same id set (use a fixed id like `intro`, valid in all three view modes).
2. **Remove the eye button from the library detail toolbar.** The Settings toggle and the in-list "Show completed" button of the all-completed line stay. Keep the eye button on the Intro page (it has no filter chips).
3. If the hide-completed setting is on, the "All" chip count and the list still follow it as today; nothing else changes.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/LibraryScreen.swift` (`sidebar`, around line 314 Intro row, toolbar around line 178, hidden-categories code from ticket 72), `SmackAPad/Sources/Persistence/Persistence.swift` (hidden category ids), both `Localizable.strings`.

## Acceptance criteria

- [ ] Long press Intro exercises → hide → confirm; it moves to Hidden categories; survives restart; can be shown again.
- [ ] Library detail toolbar has only Settings (no eye); Intro page keeps its eye button.
- [ ] Cs and en; light and dark; VoiceOver custom action on the Intro row.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
