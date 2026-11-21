# 210 — Desloppify baseline scan and clean-up plan

Status: open (planning ticket). Created 2026-11-21 after Jakub installed Desloppify, Code Simplifier and vibeclean.

## Tools

- **Desloppify** (`~/.local/bin/desloppify`): scans Swift, tracks a health score. SwiftLint is not installed, so the lint detector was skipped (`brew install swiftlint` adds it).
- **Code Simplifier** (Claude Code agent `code-simplifier:code-simplifier`): simplifies a given file without changing behaviour. Use it inside the follow-up tickets below, one file or area per ticket.
- **vibeclean**: reads only JavaScript/TypeScript. Not useful for this Swift project.

## How the scan was run

State kept outside the project, hidden backup copies excluded (`.build/` holds old snapshots such as `Persistence.original.swift` that otherwise show up as 60 fake duplicates):

```
desloppify --lang swift --exclude build --exclude .build --exclude DerivedData \
  --exclude "Claude outputs" scan --state <scratch>/state.json --no-badge --profile objective
```

Do not run `desloppify autofix` and do not use its `plan resolve` loop; changes go through tickets.

## Baseline (2026-11-21, mechanical detectors only)

| Dimension | Score | Issues |
|---|---|---|
| File health (large files) | 86.2 % | 25 |
| Code quality (mixed responsibilities, flat folders) | 78.7 % | 7 |
| Duplication | 98.6 % | 24 |
| Security | 100 % | 0 |
| **Objective total** | **92.8 / 100** | 56 |

The "overall 23/100" Desloppify prints is not a real result: 75 % of it is a subjective review that was not run (scored as 0). Ignore it.

## Findings, sorted by risk

### A. Low risk: screens and settings UI (good first targets)

1. **Repeated UI blocks** (boilerplate, 24 clusters). Same 6–20 line blocks in `CalibrationView`, `ContentView`, `ControllerSetupView`, `SettingsView` (4 clusters between them), plus `IntroScreen` ↔ `LibraryScreen` (20 lines), `PracticeComponents` ↔ `SettingsView`, `HomeScreen` ↔ `TrainingScreen`. Candidate: one shared component per block.
2. **`UI/Components.swift`** (1084 lines, 12 unrelated function groups). Candidate: split into a few files by topic, no behaviour change.
3. **`UI/` folder has 39 files and no subfolders.** Candidate: group into subfolders (Home, Practice, Library, Settings, Shared). Pure move; needs Xcode project groups updated.

### B. Medium risk: large screens and stores

4. **`Persistence/SettingsManager.swift`** (792 lines, 26 unrelated groups of functions). Candidate: split by area (profiles, calibration, reminders, hints). Touches persistence → full test suite.
5. **`UI/HomeScreen.swift`** (1872 lines), **`UI/LibraryScreen.swift`** (1074), **`UI/PracticeComponents.swift`** (1156), **`UI/PracticeInstruments.swift`** (1322), **`UI/PatternField.swift`** (869), **`UI/SettingsView.swift`** (831), **`UI/MixLineupScreen.swift`**, **`UI/ControllerSetupView.swift`**, **`UI/HelpIllustration.swift`**, **`UI/Theme.swift`**: large view files. Candidate: extract sub-views into their own files. Respect ticket 209 rule: per-hit values are read only in leaf views.
6. **`Persistence/ProgressStore.swift`** (795), **`Progression/Progression.swift`** (633): persistence and progression rules → full suite, tdd skill not needed unless logic changes.

### C. High risk: timing, scoring, audio, MIDI (last, one at a time)

7. **`UI/PracticeSession.swift`** (1544 lines, complexity 493, the highest in the app), **`UI/PracticeScreen.swift`** (2070), **`UI/TrainingScreen.swift`** (1706), **`Audio/AudioEngine.swift`** (922), **`MIDI/MIDIInput.swift`** (690). Any change here must keep timing and scoring identical; full suite every time.

### Ignore

- `Data/LessonData.swift` (861 lines): lesson data, long by nature.
- Large test files (`PracticeSessionTests`, `TodayPlanTests`, `ProgressBackupTests`, …) and the flat `SmackAPadTests/` folder (52 files): low value.

## Proposed follow-up tickets (create one at a time, after Jakub picks)

| # | Ticket | Group | Model |
|---|---|---|---|
| 211 | Share repeated blocks between Calibration / Content / ControllerSetup / Settings views | A1 | Gemini 3.8 Flash, low |
| 212 | Split `Components.swift` by topic (Code Simplifier) | A2 | Gemini 3.8 Flash, low |
| 213 | Group `UI/` into subfolders | A3 | Gemini 3.8 Flash, low |
| 214 | Split `SettingsManager.swift` by area | B4 | Gemini 3.8 Flash, medium |
| 215+ | One large screen per ticket (start with `HomeScreen.swift`) | B5 | Gemini 3.8 Flash, medium |

Each follow-up: run Code Simplifier on the listed files only, build, run area tests with `-only-testing` (full suite for persistence / progression / timing), commit, then re-run the scan and note the new objective score in the ticket.

## Acceptance criteria

- [x] Baseline scan run and recorded above.
- [ ] Jakub picks which follow-up tickets to create.

## Agent assignment

Planning only. Follow-ups: Gemini 3.8 Flash (thinking as in the table). Fallback: Codex GPT-6.1 Sol, same thinking level.

## Done rule

Done when Jakub has picked the follow-ups and they exist as ticket files.
