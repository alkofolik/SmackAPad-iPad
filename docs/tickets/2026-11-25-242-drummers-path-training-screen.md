# 242 — Drummer's Path UI on Training Screen

Status: done

## Goal

Replace the long scrolling `TrainingScreen.swift` layout with a compact, two-panel **Drummer's Path** screen wired to the RPG progression model from ticket 241, fitting cleanly on iPad landscape without unnecessary scrolling, while preserving a calm, adult hardware aesthetic and adding concise RPG progress feedback to the post-lesson summary card (`PracticeInstruments.swift`).

## Rules

1. **Compact Drummer Bar (Top of Screen):**
   - Show current `Level` and `DrummerRank` (e.g. `Lvl 5 · Beat Keeper`), XP bar toward the next level, 4 compact attribute meters (`TIMING`, `SPEED`, `TECHNIQUE`, `MEMORY`), and available **Keys** count with navigation to Studio Rig (Library / Studio Rig view).
2. **Signal-Patch Path Map (4 Alternating Stage Topologies):**
   - Render connected nodes like glowing hardware signal jumpers / patch cables on a dark chassis (adult hardware style, no childish animations).
   - Alternate 4 distinct layouts by stage index/type:
     1) **Straight Signal Line** (intro / foundational stages),
     2) **Split / Fork** (branches into two parallel tracks after node 2 and merges before the stage exam),
     3) **Step Sequencer (2×3 Matrix)** (6 pad nodes wired in a snake sequence for rhythmic variations),
     4) **Loop + Side Quest** (main path to Boss plus one optional side-quest memory node for extra XP).
   - Apply a subtle stage/kit color accent to jumpers and stage labels based on the stage's assigned drum kit.
3. **Node States, Boss Exam & Locked Drum Kit Banner:**
   - Distinguish completed nodes (glowing orange + stars), active current node (clear highlight + single primary `Play` / `Continue` CTA), locked nodes, and the final **Boss node (Stage Exam)** awarding **+1 Key** on completion.
   - When a stage requires a locked drum kit (from ticket 241), display a clean lock banner directly above the map with an action button `"Unlock <Kit> kit (1 key)"` (unlocks directly when keys are available or opens Studio Rig).
4. **Right / Bottom Today & Weekly Rhythm Panel (No Long Scroll):**
   - In iPad landscape, arrange into two balanced panels: left = Drummer's Path map with stage switcher; right = compact 3–5 min Today block with single `Start` button, Mon–Sun weekly rhythm strip, and calm access to *After me* / *Mix* without oversized cards.
   - Support iPad portrait cleanly as well and respect `accessibilityReduceMotion`.
5. **Post-Lesson Growth Line (`PracticeInstruments.swift`):**
   - Add one clean RPG growth line (e.g. `+2 SPEED · +1 TIMING · +40 XP` or `Earned +1 key!`) on the post-lesson summary card without cluttering its calm readability.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/Progression/DrummerPathModels.swift`, `SmackAPad/Sources/Progression/DrummerPathEvaluator.swift`, `SmackAPad/Sources/Progression/StudioRigCatalog.swift`, `SmackAPad/Sources/Progression/LibraryCatalog.swift`, `SmackAPad/Sources/Persistence/ProgressStore.swift`, `SmackAPad/Sources/UI/Practice/TrainingScreen.swift`, `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift`, `SmackAPad/Sources/UI/Home/HomeDestinations.swift`, `SmackAPad/Sources/UI/Library/LibraryScreen.swift`.

## Tests

Build and run unit tests on the iPad simulator (`xcodebuild test`), covering `DrummerPathTests`, `TrainingSessionTests`, `StageCompletionTests`, and `LocalizationTests` (plus any new pure view-model/topology helper tests for Drummer's Path).

## Acceptance criteria

- [x] Top Drummer Bar shows Level, Rank, XP bar, 4 attribute meters (`TIMING`, `SPEED`, `TECHNIQUE`, `MEMORY`), and available Keys with Studio Rig navigation.
- [x] Signal-patch map alternates across 4 stage topologies (Line, Split/Fork, 2×3 Matrix, Loop + Side Quest) with subtle kit-based accent color and clear node states (completed, active, locked, Boss +1 key).
- [x] Stages requiring a locked drum kit show a clean lock banner above the map with unlock / Studio Rig action.
- [x] iPad landscape shows a two-panel layout (left: Path map + stage switcher; right: Today block + `Start`, Mon–Sun rhythm, compact *After me* / *Mix* access) without long scrolling; portrait adapts cleanly and respects `accessibilityReduceMotion`.
- [x] Post-lesson summary card (`PracticeInstruments.swift`) displays a concise RPG delta line (`+XP`, attribute deltas, or `+1 key`).
- [x] App builds and tests pass on the iPad simulator.

### Manual iPad checks for Jakub

- Check Drummer's Path on iPad in both landscape and portrait orientations, verify switching stages cycles through all 4 map topologies, test unlocking a locked kit banner, and verify the RPG delta line on the post-lesson summary card.

## Agent assignment

Gemini 4 Hydrogen, thinking **medium**.

## Done rule

Build, run tests on the iPad simulator, commit on `release-polish`, and report changed files concisely.
