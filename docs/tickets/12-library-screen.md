# 12 — Library Screen

Status: implemented; build OK; awaiting iPad verification

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

- [x] Library shows all categories, genres, pass/mastery status.
- [x] Locked categories display lock icon.
- [x] Soft unlock works with tap + confirmation.
- [x] A lesson with no 8-pad layout is shown greyed-out with the label in 8-pad mode.
- [x] Intro section has a separate entry point, always accessible.
- [ ] **iPad test**: all screens render correctly on iPad, landscape and portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash High (Antigravity)
- **Reasoning**: UI screen driven by data models and progression logic. No hardware interaction.

## Done rule

Stop after successful build; Jakub tests on iPad.

## Implementation notes (2026-11-01)

- Created `LibraryScreen.swift` using `NavigationSplitView` with `.balanced` style and `Theme.swift` tokens.
- Sidebar displays:
  - Separate Intro section at the top, always accessible (24 exercises, pass count).
  - Progression categories in order (`starter`, `eighth`, `sixteenth`, `electronic`, `ghost`, `swing`, `world`, `fills`), with lock icon on locked categories and passed/total progress counts.
- Detail view displays:
  - Category header with pass counts.
  - Horizontal genre filter chips bar allowing genre filtering within the category.
  - Searchable lesson list with title, genre, level, BPM range, pass/mastery badge, and 3 stars.
  - Electronic-path and genre-extension lessons appear integrated inside the Electronic category.
- Soft unlock:
  - Tapping a locked category in the sidebar, the detail banner, or a locked lesson row requests soft unlock.
  - Confirmation alert dialog allows immediate unlock, which updates progression state and selects the category.
- 8-pad mode:
  - Checks `EightPadLayout.slots(for: lesson) == nil` in 8-pad mode; when true, dims row to 0.45 opacity and displays orange "REQUIRES 16 PADS" / "VYŽADUJE 16 PADŮ" label while keeping it openable.
- PracticeScreen navigation:
  - Full-screen cover presentation ensures the play screen receives 100% iPad display in both landscape and portrait, with its own dismiss button.
- Hardware-styled lock glyph:
  - Added `.lock` case to `PracticeGlyph` using technical square miter strokes (no default SF symbols/emojis).
- Environment integration:
  - Injected `ProgressionManager.shared` in `SmackAPadApp.swift`.
  - Replaced temporary lesson list in `LessonPicker.swift` with `LibraryScreen`.
