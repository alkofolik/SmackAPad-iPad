# 28 — Practice mode: Learning (default) and Challenge

Status: ready-for-ipad-test (2026-11-02). Source: legacy comparison 2026-11-02 (legacy manual §5.2), Jakub's feedback round 4 ("intro lessons too strict, one failed run resets the whole streak").

## Precondition

Commit `1fc4a31` ("Ease star streaks…") already makes qualifying passes accumulate: a weaker pass no longer resets them, counts are kept per lesson in memory until the app quits, and intro star 1 no longer needs 3 runs. This ticket builds on it; do not revert it.

## Goal

Copy the legacy app's two progression modes:

- **Learning · keep progress** (default): qualifying passes for each star accumulate. A weaker pass never removes credit.
- **Challenge · consecutive clean runs** (option in Settings): the ticket-18 behaviour. Qualifying passes for a star must be consecutive; a pass that fails a star resets only that star's counter.

## Rules

1. Setting `practiceMode` (`learning` | `challenge`), default `learning`, stored in `SettingsManager` (UserDefaults). Changing it while a run is active takes effect on the next START.
2. **Required runs per star** stay as today (`StarStreak.requiredRuns`, ticket 18, including the intro minimum of 3 for goal tempo and memory). Only *how* qualifying passes are counted changes.
3. **Learning: persist the credit.** Store the three counters per lesson **and per pad mode (8 / 16)** in the progress JSON, so credit survives quitting the app (legacy keeps guided checks per pad mode). Counters for an already earned star can be dropped. Old progress files without counters load as zero. This replaces the in-memory `StarStreak.saved` dictionary.
4. **Challenge:** counters are session-only and reset on START, RESTART and STOP, exactly as ticket 18 specified.
5. **Learning alternative for star 1 (legacy rule).** In Learning, a full pass also qualifies for star 1 if all three hold:
   - score >= 60 %,
   - hits judged perfect or good >= 85 % of expected hits,
   - missed + extra hits <= max(1, floor(10 % of expected hits)).
   This is an alternative to the normal threshold (70 %, intro 80 %), not a replacement. Challenge uses only the normal threshold.
6. Goal tempo and memory qualifications, clean-run error limits, tempo rise after a clean pass, auto-stop after a newly earned 2nd or 3rd star, section loops never earning stars: **unchanged**.
7. Requirement texts (`StarRequirement`): in Learning say "%lld times" / "%lld passes" instead of "%lld times in a row"; in Challenge keep "in a row". The quiet counter next to the score (ticket 18) stays; in Learning it shows accumulated credit.

## UI

Settings, practice section: a two-option control "Practice mode" with one short explanation line under it:
- Learning · keep progress — "Good passes add up. A weaker pass never takes them away."
- Challenge · consecutive clean runs — "Each star needs its passes in a row."
Use the existing Settings components and look (ticket 25A). No new colours.

## Files to read

`AGENTS.md`, `docs/tickets/2026-11-01-18-minimum-runs-per-star.md`, `SmackAPad/Sources/UI/StarStreak.swift`, `StarRequirement.swift`, `PracticeSession.swift`, `SmackAPad/Sources/Scoring/ScoringEngine.swift`, `SmackAPad/Sources/Persistence/Persistence.swift`, `SmackAPad/Sources/UI/SettingsView.swift`, `SmackAPad/Resources/en.lproj/Localizable.strings`, `cs.lproj/Localizable.strings`.

## Tasks

1. Use the tdd skill (scoring rules). Pure functions: alternative star-1 qualification; counting in Learning vs Challenge.
2. Persist Learning counters per lesson and pad mode; migration from files without them.
3. Settings control and texts in `en` and `cs`.
4. Unit tests (only these): alternative star-1 rule at its boundaries (60 %, 85 %, error budget for 4, 16, 40 expected hits); Learning keeps credit after a failing pass and across a save/load; Challenge resets only the failed star's counter.

## Acceptance criteria

- [x] Default is Learning; a failed pass no longer removes credit; credit survives app restart and is separate for 8 and 16 pads.
- [x] Challenge behaves exactly like ticket 18.
- [x] Star 1 can be earned through the alternative Learning rule.
- [x] Requirement texts match the selected mode in both languages.
- [x] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: an intro lesson with one bad pass between good ones (Learning), then the same in Challenge.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**.
- **Reasoning**: changes star rules and the progress file format; mistakes here silently lose or give away stars.

## Done rule

Stop after successful build and tests; Jakub tests on iPad. Commit after the task.

## Implementation and validation (2026-11-02)

- Added the persisted Learning/Challenge setting, defaulting to Learning. Practice snapshots the mode at START; Challenge clears its counters at START/RESTART/STOP. Required run counts, tempo progression, section-loop restrictions and star auto-stop remain unchanged.
- Replaced the static in-memory dictionary with three Learning counters stored in each lesson record under separate `8` / `16` pad-mode keys. Older JSON records decode with no credit. Every completed full practice pass saves credit alongside progress. Challenge does not modify stored Learning credit.
- Added the alternative first-star policy and the scoring summary's perfect-or-good hit count without changing the existing score formula or normal qualification. Added the Settings menu and mode-aware requirement text in English and Czech.
- Three requested XCTest cases passed, each following a failing compilation for its missing production interface: alternative first-star boundaries (60%, 85%, error budgets for 4/16/40 hits); Learning retention and independent Challenge failure resets; real ProgressStore save/load, pad-mode/lesson separation and old-file migration. No already-passed test was rerun. Tests ran on macOS through `build/ticket-28/pure`: production StarStreak was symlinked; the unchanged LessonProgress/ProgressStore section was extracted from Persistence.swift to avoid unrelated app dependencies.
- Localization files passed `plutil -lint`; `git diff --check` passed before the build. The initial sandboxed app build could not launch Swift macro plugins. The second build succeeded with `xcodebuild build -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ticket-28/app CODE_SIGNING_ALLOWED=NO 'OTHER_SWIFT_FLAGS=$(inherited) -disable-sandbox'`. No further tests or builds after success.
- Jakub still verifies an intro lesson with a bad pass between good passes in Learning and Challenge on iPad.
