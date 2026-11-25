# 233 — ResultCard: measurable growth line, human review progress, and direct daily-step handoff

Status: ready-for-agent

## Goal

Show a concrete one-line proof of skill growth or bar-level diagnosis on `ResultCard`, replace discouraging `"Not counted"` / `"Nepočítá se"` labels with encouraging progress copy, and transition directly between steps of `TodayPlan` from `ResultCard`—deleting the duplicate `TrainingStepResultCard` modal.

## Rules

1. **Pre-run baseline & bar summary (`PracticeSession.swift`, `PracticeComponents.swift`).**
   - Before saving a finished full run to `ProgressStore`, capture `previousBestScore: Double?` (`hasPlayed ? Double(record.bestScore) : nil`) and `previousBpm: Int?` (`record.currentBpm > 0 ? record.currentBpm : nil`) on `RunSummary`.
   - Also compute per-bar summary on `RunSummary` from the finished run's `hitJudgments`: `totalBars: Int`, `cleanBars: Int` (bars with 0 missed/wrong/off hits), and `weakestBar: Int?` (1-based bar index with the highest error+off count when `< totalBars` are clean).
2. **One-line growth / diagnosis feedback (`EndOfRunCardModel`, `ResultCard` in `PracticeInstruments.swift`).**
   - Add `growthLine: String?` to `EndOfRunCardModel`, prioritized as:
     1. Score beat `previousBestScore` by at least 1 percentage point: `"+%lld %% osobní rekord"` / `"+%lld%% personal best"`.
     2. Clean run at a higher `bpm` than `previousBpm`: `"Nejvyšší čisté tempo · %lld BPM"` / `"New clean tempo best · %lld BPM"`.
     3. Multi-bar lesson (`totalBars >= 2`) with `cleanBars > 0` and `weakestBar != nil`: `"%lld ze %lld taktů čistě · pohlídej takt %lld"` / `"%lld of %lld bars clean · watch bar %lld"`.
     4. All bars clean: `"Všechny takty čistě"` / `"All bars clean"`.
   - Display `growthLine` calmly in `ResultCard`'s middle zone (14 pt `Theme.meta`, `Theme.orange` when it is a new personal best or all-clean, `Theme.white.opacity(0.78)` when diagnostic), updating `ResultCard`'s outer frame radius from `20` to `Theme.Radius.panel` (`8 pt`).
3. **Replace `"Not counted"` / `"Nepočítá se"` with human step progress (`PracticeInstruments.swift`, `TodayPlan.swift`, `Localizable.strings`).**
   - Remove the `"Not counted"` / `"Nepočítá se"` headline state on `ResultCard` and `PracticeStepOutcome.Status.didNotCount`.
   - Instead, show clear forward-looking titles and reasons:
     - `.notesVisible`: title `"Rozehřáto s notami"` / `"Warm-up complete"`, detail `"Teď dej 2 průchody zpaměti"` / `"Now play 2 passes from memory"`.
     - `.peeked`: title `"Nápověda využita"` / `"Peek used"`, detail `"Další průchod zkus čistě zpaměti"` / `"Try the next pass from memory"`.
     - `.unfinishedReview`: title `"1 ze 2 zpaměti"` / `"1 of 2 from memory"` (or `"Rozehřáto"` when 0 hidden passes succeeded), detail `"Ještě jeden úspěšný průchod zpaměti"` / `"One more clean memory pass to finish"`.
     - `.requirements(let bpm)`: title `"Cvičné tempo"` / `"Practice tempo"`, detail `"Pro započítání opakování hraj zpaměti na %lld BPM"` / `"For review credit, play from memory at %lld BPM"`.
     - Stopped before pass 1 finished (`summary.passes == 0`): title `"Zastaveno"` / `"Stopped early"`, detail `"Dohraj celý průchod pro vyhodnocení"` / `"Finish one full pass to see your score"`.
   - Delete tests enforcing the removed `"Not counted"` / `"Nepočítá se"` strings and update them for the new copy.
4. **Direct daily-step handoff & delete `TrainingStepResultCard.swift`.**
   - Delete `SmackAPad/Sources/UI/Practice/TrainingStepResultCard.swift`, remove its file reference from `SmackAPad.xcodeproj/project.pbxproj`, and remove its overlay from `TrainingScreen.swift`.
   - When `PracticeScreen` (or `MixFlowScreen`'s `mixSummaryCard`) runs as part of `todaySession` (`TrainingScreen`), pass `dailyNextTitle: String?` (e.g. `"Pokračovat · <další lekce>"` / `"Continue · <next>"` when another step follows, or `"Dokončit trénink"` / `"Finish training"` on the final step) and `onAdvanceDailyStep: () -> Void`.
   - Tapping that primary button records/advances `todaySession` and switches `todayPractice` directly to the next `.lesson` or `.mix`, or presents `DaySummaryView` when the plan finishes—without bouncing back to `TrainingScreen` in between. Tapping top-left `BackButton` calmly returns to `TrainingScreen` without showing a popup card.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Practice/PracticeInstruments.swift` (`EndOfRunCardModel`, `ResultCard`), `SmackAPad/Sources/UI/Practice/PracticeSession.swift`, `SmackAPad/Sources/UI/Practice/PracticeScreen.swift` (lines 960–1120, 2045–2085), `SmackAPad/Sources/UI/Practice/TrainingScreen.swift` (lines 265–335, 505–580), `SmackAPad/Sources/UI/Practice/TrainingStepResultCard.swift`, `SmackAPad/Sources/Progression/TodayPlan.swift`.

## Tests

Update `ResultNextTargetTests`, `TodayPlanTests`, `ReviewWindowTests`, and `EndOfRunCardModel` tests for `growthLine`, replaced `"Not counted"` copy, and direct daily-step progression. Run full test suite (touches `TodayPlan` and `PracticeSession`).

## Acceptance criteria

- [ ] `ResultCard` displays personal-best score delta, clean-tempo record, or clean-bar count + watch-bar hint.
- [ ] `"Not counted"` / `"Nepočítá se"` no longer appears anywhere; warm-up, peek, and partial memory runs show encouraging progress titles.
- [ ] `TrainingStepResultCard.swift` is deleted; tapping Continue on `ResultCard` during Today's block advances directly to the next step (including Mix) or `DaySummaryView`.
- [ ] Tapping `Back` during Today's block returns cleanly to `TrainingScreen` with no modal overlay.
- [ ] Build and full test suite pass.

### Manual iPad checks for Jakub

Play a lesson twice improving your score (verify `+% personal best`), play a 2–4 bar lesson missing hits in one bar (verify `X of Y bars clean · watch bar Z`), test a due review with a peek, and play through a full Today session from Step 1 → Step 2 → Mix → Day summary verifying seamless single-tap transitions.

## Agent assignment

Gemini 4 Carbon (or Codex GPT-6.1 Sol), thinking **high**.

## Done rule

Build, run full test suite per `AGENTS.md`, commit on `release-polish`, stop for Jakub's iPad check.
