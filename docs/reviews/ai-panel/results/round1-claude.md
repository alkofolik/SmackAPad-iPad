I'll read the repository source first, then write the review.

## A. Common core

**A1.** Smack-a-Pad is an offline iPad trainer for beginner and intermediate finger drummers who play an external MIDI pad controller. It takes them through about 587 short groove lessons, scores their timing against a metronome, raises the tempo automatically, and brings mastered grooves back on a spaced-review schedule to be played from memory.

**A2.**

| Axis | Score | Reason |
|---|---|---|
| First 10 minutes for a new user | 5 | Controller presets, MIDI learn and an always-open Intro are solid (27, 28, 08), but no empty-state or onboarding screenshot exists, and Home offers 8 equal pads plus four faders with no clear first step (01). Low confidence. |
| Learning effectiveness | 6 | The structure is right (spacing, interleaved Mix, Play after me, from-memory recall), but reviews show the notes first, the adaptive centre hides drag and rush, and the windows are too wide to certify timing (R3-01 to R3-03). |
| Motivation to come back daily | 6 | The Today session is a good single entry point (23, 24), but an orange "29 due" backlog and contradictory summaries ("0 of 2" next to ✓ 100 %) undercut it. |
| Visual design and clarity | 7 | It has a distinctive, calm hardware identity and a Practice screen readable at arm's length (09–12), but Library and Training are dense and star and step semantics conflict on screen (09, 19). |
| Readiness for App Store release | 3 | Any file decode error causes silent total progress loss, CC BY-SA sound credits are missing (32 shows only fonts), the privacy manifest is pending, and nothing has been field-tested on physical controllers. |
| Commercial potential | 5 | A real but narrow niche (iPad plus pad controller). The one-time price beats subscription competitors, but discoverability and trust in the scoring are unproven. |

**A3. Strongest things (protect these)**
1. **Timing core.** Hardware MIDI timestamps drive scoring, independent of the main thread and screen refresh. Audio is scheduled ahead on the host clock. Calibration measures the actually rendered click (`AudioEngine.startCalibrationClicks` tap), not the scheduled time. Never let display ticks or UI time into scoring.
2. **Learning-loop skeleton.** Listen → Play → From memory → spaced review, plus interleaved Mix, Play after me, soft unlock ("nothing is locked") and one daily Today session.
3. **Product stance.** Calm industrial look, per-lesson 8-pad mapping, no accounts or tracking, one-time price, and a generous free tier (58 lessons) that already includes the whole learning loop.

**A4. Most serious problems, ranked**
1. Any decode failure of `progress.json` (for example after a future format change) silently wipes all progress on the next background save (R1-01).
2. The app contradicts itself and the brief:
   - Reviews show "✓ 100 %" but the summary says "Reviews 0 of 2" (23, 24).
   - Lessons show ★★★ next to "Review · 0 of 2 passed" (09).
   - The Training banner says 29 reviews while Today plays 2 (18).
   - Bar verdicts are described as shipped but do not exist.
   
   Every number loses credibility (R3-07, R1-02, R3-05, R2-04).
3. Stars do not certify in-time playing from long-term memory. Reviews pre-show the pattern, the adaptive centre hides steady drag or rush, and ±200 ms binary windows pass sloppy timing (R3-01 to R3-03).

**A5. Would a target user pay?** Yes, a minority of committed pad owners would, if they trust the scoring. The main competitor is subscription-only: Melodics for iPad lists a monthly subscription at USD 29.99 and an annual one at USD 179.99, and its free tier offers 20 free lessons per instrument with 5 minutes of play time each day.

The $19.99 shown in screen 31 is right: less than one month of the competitor, and credible for 529 extra lessons. I would not go below $14.99, because a low price signals a toy to producers who already spend hundreds on controllers. The paywall should say "529 more lessons", not "587 lessons" (58 are already free).

**A6. One thing for the next month.** Run a closed TestFlight with 5–10 real finger drummers on their own controllers and iPads, including at least one older iPad and one Bluetooth controller. Fix R1-01 on day one so testers cannot lose data. Every other priority (timing trust, review load, latency) needs real-hardware evidence that does not yet exist.

## B. Role findings

**R1 — Senior iOS engineer**

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|
| R1-01 | A decode failure of the progress file silently wipes all progress on the next save. | `Persistence.swift`, `ProgressStore.load()` catch block sets `records = [:]` and only stores `lastLoadError`. `save()` never checks it. `setupLifecycleObservers()` saves on every `didEnterBackground`; `recordResult` and `setProgress` autosave. Decoding is all-or-nothing: `LessonProgress.init(from:)` uses non-optional `decode` for `passed`, `mastery`, `currentBpm` and `bestScore`. There is no schema version and no backup before migrations. Only the DEBUG `importLegacyBackup` guards on `lastLoadError`. | blocker | high | Ticket for an agent: (1) on load failure, copy the file to `progress.corrupt-<date>.json`, block every `save()` while `lastLoadError != nil` and show a one-line warning; (2) add `schemaVersion` to `ProgressRoot`; (3) back up before any migration write; (4) decode per record, so one bad record is skipped instead of all; (5) tests: a corrupt file is never overwritten, and a file with unknown future fields loads. | S |
| R1-02 | Old star-3 records contradict the new rule: ★★★ next to "Review · 0 of 2 passed" and "STEP 1 OF 4, 2 days late". | Screens 09, 10, 18, 19 (Intro lessons). `migrateTwoReviewsStar3` only adds `memory`. Records with `memory == true` from the old From-memory rule keep it, while `migrateLegacyMasteredReviewSchedule` puts them at review step 0. | major | high | Choose one rule for legacy ★3: either treat those lessons as past step 2, or hide the "of 2" counter for them. Implement it as a migration, with a fixture file from a pre-ticket-143 build. | S |
| R1-03 | Live pad sound goes through the main thread, so audible latency varies with UI load. | `MIDIInput.swift`: port callback → `Task { @MainActor }` → `receive` → `emit` → `PracticeSession.receive` → `audio.play` (`queue.async`). Scoring is unaffected because it uses timestamps; the sound the player hears is affected. Per hit, `MIDIInput` also mutates four observed properties (`lastNote`, `lastPad`, `pressedPadIndices`, `noteOnCount`), and `PracticeSession` writes `padFlashes`. This causes SwiftUI invalidations at exactly the moment sound must be instant. | major | medium (architecture clear, not measured) | Trigger `AudioEngine.play` directly in the CoreMIDI callback from an immutable note→pad snapshot, then hop to main only for UI and scoring. Mark debug counters `@ObservationIgnored`. Measure on the oldest supported iPad. | M |
| R1-04 | Pad double-triggers are counted as errors instead of being ignored. | `ScoringEngine.swift` L114–119: a second note-on on the same pad within 30 ms of a matched hit increments `extraHitCount`. The brief calls this a "debounce guard". One extra hit breaks a clean run on short patterns (0 errors allowed for ≤15 hits, L178–179). Worn pads and BLE re-sends double-fire. | major | medium | Ignore same-pad note-ons within about 25 ms without counting them; keep counting genuine extras. Add one ScoringEngine test. | S |
| R1-05 | Every practice screen decodes all bundled kits into RAM again. | `PracticeSession` owns `private let audio = AudioEngine()`. `prepare()` → `loadKits()` decodes every WAV of every kit to 48 kHz stereo Float32. The `acoustic` folder alone is about 7 MB of WAV (65 files); decoded it is several times larger, times 7–8 kits. Calibration uses a separate engine instance. | major | medium (other kits and WAV formats not checked) | Use one shared engine for the app, load only the selected kit on demand (keep at most 2 resident) and prepare once. Ticket 121 ("slow open and lesson start") is likely related. | M |
| R1-06 | An audio route change mid-run silences the metronome and pattern while scoring continues. Calibration ignores the output route. | `AudioEngine.resumeAfterSessionChange()` stops all players and restarts the engine; its comment says the caller restarts clicks, but no callback to `PracticeSession` exists. `calibrationOffset(for: deviceID)` is keyed by input only, so speaker, wired and Bluetooth headphones share one offset. | major | medium | Publish a route-change event and stop the run with a short message. Store calibration per input and output-route type, or warn when audio output is Bluetooth. | M |
| R1-07 | One late scheduling tick aborts the whole run. | `PracticeSession.tick()` catch → `stop()`. `AudioEngine.renderTime` throws `insufficientLeadTime`. The metronome path in the same file skips late beats instead (`scheduleMetronome`). A main-thread stall of about 0.5 s (sheet, save, badges) ends the run. | minor | medium | Skip and log a late sound; stop only after repeated failures. | S |
| R1-08 | StoreKit logic is sound; purchase messages are English-only. | `StoreManager.purchase()` and `restore()` assign English literals to `message`. Verification, revocation, `Transaction.updates` and foreground refresh (`SmackAPadApp`) look correct. A checklist item is still open. | minor | high | Return an enum and localize it in the view. Do not touch the entitlement logic. | S |

**R2 — Maintainability with AI agents**

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|
| R2-01 | Learning rules are spread over at least 6 files, with duplicated literals. | 70/80 % pass and clean-error limits: `ScoringEngine.finish()` and again in `earlyResult()`. Windows 200/175/150 ms in `ScoringEngine.init`, repeated as seconds in `PracticeSession.Pass.init`. 60 %/85 % alternative pass in `StarStreak.learningPassed`. The 0.80 threshold in `ReviewScheduler.evaluate`, twice in `PracticeSession.finishCompleted` (`memoryRunPassed`, `runMemoryPass`) and in `recordAfterMeResponse`. "Hidden pass = pass ≥ 3" in `ReviewScheduler`, twice in `PracticeSession`, and in `NoteVisibility.derive`. | major | high | Create one `LearningRules.swift` with named constants and pure functions, plus one test that pins every number. Tickets cite rule names, never numbers. | M |
| R2-02 | Several files are too large for an agent to read whole. | `HomeScreen` 68 KB, `TrainingScreen` 65 KB, `PracticeScreen` 65 KB, `Persistence` 61 KB, `PracticeSession` 58 KB, `LibraryScreen` 47 KB. `Persistence.swift` mixes calendar, settings, localization (with a TSV fallback), progress model, migrations and legacy import. | major | high | Do mechanical splits only (no logic change) into files of about 400 lines or less, one ticket per file. Start with `Persistence.swift`. | M |
| R2-03 | The agent rules let regressions through. | `AGENTS.md`: "Do not re-run tests that already passed. No extra tests." Ticket 143 ("Tests (only these)") reported success; ticket 147 the next day found 5 failing tests out of 177. | major | high | Run the full suite before every commit; a ticket is not done while any test fails. | S |
| R2-04 | Docs and the brief disagree with the code. Agents read only the files they are given, so drift is never corrected. | Bar verdicts (`clean/ahead/behind/uneven`) appear as shipped in brief §3 and §8, but `PracticeSession.receiveBarSummary` has no caller and `docs/tickets/2026-10-30-bar-summary-scoring.md` is still "draft". The brief says Star 1 needs ≥70 %, but Learning mode passes at 60 %. Required runs per star and Learning/Challenge modes are undocumented in the brief. The paywall says "587 lessons" (31) while Library says "574 lessons" (03–08). | major | high | Every rule-changing ticket lists `SPEC.md` and `DECISIONS.md` in "Files to read" and updates them in the same commit. The brief counts only features accepted on the iPad. | S |
| R2-05 | Agents add overloads and leave dead paths instead of deleting. | `StarStreak.mayEarnMemoryCredit`: 2 overloads with 10 parameters, always returns `false`, still called. `memoryRuns` and `forgetAll()` (a no-op) remain. `ReviewForecast.dueCounts` has 4 identical overloads; `mayEarnStar3` has 2. | minor | high | AGENTS.md rule: "When a rule is removed, delete its code paths and tests in the same ticket." Plus one cleanup ticket now. | S |
| R2-06 | Localization uses 4 mechanisms. | `Localizable.strings`; `AppLanguage.czechTSVLookup`; Czech and English literals in `ReviewFeedback.message`; English-only `StoreManager` messages and `AppAppearance.title`. | minor | high | Move to one String Catalog and delete the TSV fallback. Add a test that every key exists in both languages. | M |
| R2-07 | Tickets point to line ranges and close without human acceptance. | Ticket 143: "PracticeSession.swift (… ~895–990)"; its iPad acceptance is unchecked, yet the brief lists the feature as done. | minor | high | Reference symbols, not lines. Add a status "accepted on iPad" separate from "done in code". | S |
| R2-08 | Protect the ticket template, which works well. | Tickets 143 and 147: Goal, numbered Rules, Files to read, Tests, Acceptance, Agent, Done rule. | idea | high | Keep it, and add two fields: "Docs to update" and "Rules touched". | S |

Structural changes that would make agent work safer, in order:
1. Create `LearningRules` as the single source of every threshold (R2-01).
2. Split `Persistence.swift`, and keep a folder of golden `progress.json` files from every release that must always load (R1-01, R2-02).
3. Make the full test suite a gate on every commit (R2-03).
4. Use one localization path (R2-06).
5. Update the docs in the same ticket that changes a rule (R2-04).

**R3 — Learning scientist**

| ID | Finding | Evidence | Severity | Confidence | Suggested action | Effort |
|---|---|---|---|---|---|---|
| R3-01 | Reviews start by showing the pattern again, so they test short-term copying, not long-term recall. | `fadeMemoryNotes` defaults to `true` (`SettingsManager.init`). In `ReviewScheduler.evaluate`, passes before 3 do not count. Screen 13 shows a review at "Pass 1 · notes shown". The testing effect depends on effortful retrieval before re-exposure. | major | high | In Training and Today reviews, hide the notes from pass 1 regardless of the setting. If the first hidden attempt fails, show the notes once and let the player retry. | S |
| R3-02 | The adaptive centre hides the most important error: steady dragging or rushing. | `ScoringEngine` L131 (`corrected = calibrated − center`), L147, L156–165 (centre = median of the last 8 errors, up to ±110 ms). That error feeds "Late 47 ms" (09) and `timingHistory`. A player 80 ms late on every hit will see about 0 ms after a few beats. | major | high | Keep the centre for matching only (as decided), but show and store the calibrated, un-centred error. | S |
| R3-03 | The decided timing tolerance is a serious mistake for Star 2. | Windows ±200/175/150 ms (L101–109), binary credit, plus the centre shift. At 120 BPM, sixteenths are 125 ms apart, so Star 2 certifies "right pads, roughly right order", not "in time". | major | medium | Keep the formula. Add one Star 2 gate: at least 80 % of hits rated perfect or good (`perfectOrGoodHitCount` already exists). | S |
| R3-04 | The app gives per-hit numeric feedback during play, but no per-bar summary. | Screen 09 ("Late 47 ms", early/late bar, hit colouring via `PracticeSession.record`). Bar verdicts are not implemented (R2-04). Frequent concurrent feedback helps in practice but hurts retention (guidance hypothesis). | major | medium | Hide the per-hit readout in From memory, reviews and Mix. Build the bar-summary ticket, and show one summary sentence after each run. | M |
| R3-05 | The review load is set up to overflow and to shame. | Home shows "29 due" in orange (01). The banner says "29 lessons" while `TodayPlan.make` plays `prefix(2)` (18). The 7-day strip is cumulative (`ReviewForecast.dueCounts`) but labelled "coming back that day". Each new Star 2 adds a review. | major | medium | Size Today by time, not count (a 1-bar review takes under 1 minute; aim for about 6–8). Pause new lessons when more than about 10 are due. Show "due today", and drop the orange backlog number from Home. | S |
| R3-06 | The tempo ladder only goes up. | Brief §4 and `ScoringEngine.finish` (`nextBpm`): one clean pass → +5 BPM, never down. Errors at too-high tempos get rehearsed. | minor | medium | Use 2-up/1-down: step up after 2 clean passes, step down after 2 failed passes in a row, never below the start BPM. | S |
| R3-07 | Contradictory feedback erodes trust in every number. | Screens 23 and 24: "1. Review ✓ 100 %", "2. Review ✓ 100 %", then "Reviews 0 of 2". "Review · 0 of 2 passed" counts passes today, while "Star 3: two reviews · 0 of 2" counts days. | major | medium (the cause of "0 of 2" was not traced; possibly `doesNotCount`) | A review that did not count must not show a green ✓; say why. Rename the in-run counter to "Hidden passes today 0/2". | S |
| R3-08 | "Settled in hands" overclaims at about day 4. | Gaps are 1, 3, 7 and 21 days (`ReviewScheduler.gaps`), and Star 3 comes at step 2. | minor | medium | Word Star 3 as "Remembered twice"; reserve "Settled" for step 4 (about day 32). | S |
| R3-09 | Mix and Play after me are well grounded and must not be lost. | Screen 20, `TrainingMix.swift`, After-me mode. These use interleaving (contextual interference) and ear-to-hand imitation without notation. | idea | high | Keep the Mix step in Today, and add a weekly Play-after-me step. | S |

## C. What I could not judge

- **Screen recordings.** Timing feel, sound quality, audio latency and animation smoothness were not provided and are not judged.
- **First-run experience.** There are no empty-state or first-launch screenshots, and screenshots 16, 21 and 22 are missing from the PDF. The first-10-minutes score has low confidence.
- **Real hardware.** No latency or memory measurements exist. R1-03 and R1-05 are architecture-based estimates; Instruments traces on an older iPad would confirm or refute them.
- **Purchase state.** Home shows "Unlocked" (01) while Settings shows "Free" (26) and the paywall offers the unlock (31). The code uses the same flag in both places, so this is probably a change in test state, but I cannot confirm it.
- **Calibration sign.** A saved offset of −75 ms on a Bluetooth controller (29, 30) is an unusual sign for transport latency. It is worth checking in the field test.
- **Root causes not traced.** I did not trace why the Today summary says "Reviews 0 of 2", or why the "new lesson" was Hip hop 2 (already at ★★, 23) when Training announced Rock 3 (18).
- **Line numbers.** The GitHub API returns file text without line numbers. `ScoringEngine.swift` lines were counted by hand (±2). Other references use exact type and function names.
- **Not reviewed in depth.** Czech wording quality, 8-pad mode in practice, and the legal implications of the CC BY-SA samples beyond the missing attribution.