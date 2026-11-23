# 228 — Review queue: one section per step, easiest first, plus an "All lessons" section

Status: done. Requested by Jakub on 2026-11-23.

## Goal

The review queue (Training tab, "Review queue" screen, panel `dueNowPanel`) no longer shows one long column with filter chips. It shows one collapsible section per review step (Step 1 to Step 4) and, after them, one section with all queued lessons. Inside every section the lessons go from the easiest to the hardest. The panel looks tidier and Jakub finds a lesson faster.

## Rules

1. **Step sections.** Replace the chip row (`stepFilterChips`) and the single list with four collapsible sections: "Step 1" … "Step 4" (existing strings, Czech "Krok 1" …). Each header shows the title and the number of lessons ("3 lessons" / "3 lekce"), plus a chevron. Tapping the header opens or closes the section. Only lessons with that `reviewStep` are listed inside.
2. **Empty steps** are shown dimmed with count 0 and cannot be opened (same idea as the old disabled chip), or are hidden if that looks cleaner. Pick one, keep it consistent. Do not show the old text "No lessons for this step." any more.
3. **All lessons section** comes after the four step sections, same look, title "All lessons" / "Všechny lekce", with the count of the whole queue. Its list shows every queued lesson from all steps.
4. **Order inside every section (including "All lessons"):** easiest first. Difficulty is `Lesson.level` ascending, then `targetBpm` ascending, then lesson id ascending. Do not reuse `ReviewQueue.order` for the display. That order (lowest step, most days late, oldest mastery) still decides which lessons Today picks and must not change.
5. **Open/closed state.** Sections start closed except the first non-empty step, which starts open. The state is kept only while the screen is open (`@State`), not saved.
6. **Remove the old UI.** Delete `DueStepFilter`, `stepFilterChips`, `filteredDueLessons`, `isDueExpanded`, the "Show all (%lld)" / "Show fewer" button (a section shows all its lessons) and the setting `trainingDueStepFilter` with its `UserDefaults` key. Old backup files that still contain `trainingDueStepFilter` must keep loading (ignore the key on read, do not write it). Remove strings that nothing uses any more.
7. **Rows stay as they are.** Reuse `dueLessonRow` (title, stars, "Step x of 4", "Tried today · not met yet" from ticket 227). Use the existing panel look (`satinPlate`, hairlines, `Theme` tokens) and the existing chevron style of other collapsible parts of the app. No new colour, no new component beyond one small section header view.
8. The "Waiting" and "Settled" panels below the queue are **not** part of this ticket. Do not change them.
9. Texts through `settings.localized`, Czech and English.

## Files to read

`AGENTS.md`, `TrainingScreen.swift` (search `dueNowPanel`, `stepFilterChips`, `dueLessonRow`, `DueStepFilter`, `reviewQueueDestination`), `SettingsManager.swift` and `ProgressBackup.swift` (search `trainingDueStepFilter`), `LessonData.swift` (`Lesson.level`, `targetBpm`), the two `Localizable.strings` files (search only). Read the design-taste-frontend rules only.

## Tests

One small test for the sort helper: lessons sorted by `level`, then `targetBpm`, then id. One test that a backup containing `trainingDueStepFilter` still loads. Layout and texts: build only.

## Acceptance criteria

- [x] Queue shows Step 1–4 sections and "All lessons"; no chips, no "Show all" button.
- [x] Each section lists only its step's lessons, easiest first; "All lessons" lists everything, easiest first.
- [x] Counts in the headers match the lists.
- [x] The order Today uses for picking reviews is unchanged (existing tests still pass).
- [x] Old backups still load; no dead code or unused strings left.
- [x] Build and tests of the area pass.

### Manual iPad checks for Jakub

Open Training → Review queue. Open and close each step section and "All lessons". Check that lessons go from easy to hard, that a step with no lessons looks right, that tapping a lesson still starts the review, and that the layout is fine in portrait and landscape.

## Open point for Jakub

"Easiest" is taken from the lesson `level` (then target tempo). If the level number does not match how hard a lesson feels to Jakub, say so before starting and the sort key will be changed.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (layout plus removal of old code). Fallback: Codex GPT-6.1 Sol, high. Touches `TrainingScreen.swift`: do not run in parallel with ticket 220.

## Done rule

Build, run tests per `AGENTS.md` (persistence area touched: run the full suite once before the commit), commit, stop for Jakub's iPad check.
