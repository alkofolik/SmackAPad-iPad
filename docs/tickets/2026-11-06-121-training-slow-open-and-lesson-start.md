# 121 — Training: pad opens after ~5 s, lessons do not start from Training

Status: ready-for-human. Implementation built; original iPad symptoms and before/after timing remain unverified. Source: Jakub, 2026-11-06 (iPad).

## Problem

1. **Slow open**: tapping the Training pad on Home shows nothing for about 5 seconds, then the Training screen opens.
2. **Lesson does not start**: from the Training screen a lesson cannot be started. The same lesson starts fine from the Library.

## Rules

1. Find why the Training screen is slow to appear (likely heavy work on the main thread when the screen is built: loading all lessons/progress, computing the mix or due list, or a blocking call in `init`/`body`). Move that work off the main thread or compute it once and cache it; show the screen at once (the pad-zoom transition from ticket 113 must start right away) and fill data in when ready. Measure before and after (simple timestamps in a debug log is enough) and give both numbers in the report.
2. Find why starting a lesson from Training fails while the Library path works. Compare both paths; Training must use the same start path as the Library (same session setup), not a copy that drifted. Name the cause in the report.
3. No changes to scoring or timing code.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/TrainingScreen.swift`, `SmackAPad/Sources/UI/LibraryScreen.swift` (how it starts a lesson), `SmackAPad/Sources/UI/AppNavigation.swift`, `SmackAPad/Sources/UI/HomeScreen.swift` (Training pad action only).

## Acceptance criteria

- [ ] Training screen appears without a visible delay (numbers before/after in the report).
- [ ] Every lesson offered in Training starts and plays.
- [x] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: open Training, start a lesson.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high.
- **Reasoning**: two diagnoses (performance + broken navigation path).

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.

## Update 2026-11-07 (still open — never implemented)

No commit exists for this ticket; ticket 128 (skin) was built on top of it anyway, and Jakub still sees the ~5 s delay. Do ticket 130 first (it may already remove part of the lag), then measure again. Extra hypotheses from the read-only review of `TrainingScreen.swift`:
- `dueLessons` and `currentPlan` are computed properties used ~8× per render; each call scans all progress records, looks up lessons, and `currentPlan` also decodes JSON and builds the mix. Compute once per refresh into `@State`, not per `body`.
- Ticket 128 added `satinPlate()` (two blurred shadows) to every card and an infinitely breathing `HardwareLightBar` on every due row; with the pad-zoom transition this may block the first frame. Test by disabling them (bisect), report the numbers.
- `.task(id: mixContext)` and `.task(id: afterMeContext)` run `refreshMix` / `chooseAfterMeLesson` on the main thread at open.


## Implementation report — 2026-11-07

### Changes

- Training now presents a lightweight navigation/loading shell before scheduling its derived-data refresh. Due lessons, next lesson, Today plan, eligible Mix lessons, After me candidates, memory counts, review forecast and badge statistics are cached together in view state. The two candidate-derived task identifiers and repeated computations during `body` evaluation were removed.
- The refresh observes its model inputs once with `withObservationTracking`; changes invalidate the snapshot. Reappearance, day changes, foregrounding and persisted plan/Mix changes also refresh it. Writes to the daily Mix cache use stable JSON ordering and do not trigger another refresh of their own.
- Mix/After me access checks now examine only previously learned/played candidates, instead of repeatedly checking access for the whole catalogue. Training data work is computed once per refresh on the main actor after a cancellable 50 ms yield; it is not a background-thread calculation.
- Due-row lights remain lit without a perpetual per-row animation. Large-card satin surfaces are preserved. No measured shadow/light bisect was completed, so rendering effects are **not** claimed as the cause of the reported five-second delay.
- Library and Training now share `LessonLaunch`, `PracticeLessonDestination` and the same lesson-presentation wrapper in `AppNavigation.swift`. Ordinary/new lessons use the Library defaults. Reviews explicitly retain memory mode and goal tempo; Mix and After me retain their existing options. Training's ordinary presentation modifier now wraps its navigation container, and its first-lesson card supplies a zoom source.

### Diagnosis and limits

The source exposed repeated catalogue/progress scans, repeated Today-plan decoding and candidate selection during view evaluation. These are concrete unnecessary operations, but their contribution to the reported physical-iPad delay has not been measured.

The Training first-lesson button previously used the **review** constructor (`initialFromMemory: true`, `initialBpm: lesson.targetBpm`) for every ordinary lesson. Library used the standard constructor. This mismatch is corrected through shared construction. It is **not established as the cause of the reported inability to start a lesson**: in the pre-change iPad Pro 11-inch (M5), iPadOS 27.0 simulator, “Learn your first lesson” opened “Kick on every beat”; Start became enabled after initialization, and playback completed. The original failure could not be reproduced with that simulator's progress data.

### Measurements and validation

- Physical-iPad baseline: approximately **5 s**, as reported by Jakub; not independently measured here.
- Pre-change simulator: the Home → Training computer-control call returned the Training accessibility tree in **2.56 s** total (the click itself returned in **1.04 s**). These include automation overhead and are **not first-frame timings**; the five-second symptom was not reproduced.
- Post-change first-frame/data timings: **not measured**. A local video-analysis attempt did not produce a usable timing result. Debug builds now log `[TrainingOpen] tap to shell … ms` and `[TrainingOpen] data refresh … ms` for an actual device measurement. Tap-to-shell records `onAppear`, not a GPU-presented frame. The 50 ms scheduling yield is a code constant, not a measured improvement.
- Final build: `xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -configuration Debug -sdk iphonesimulator -destination 'id=9CC875DA-5EDB-4032-94FF-1D802565DBB5' -derivedDataPath .build/ticket130/DerivedData CODE_SIGNING_ALLOWED=NO build` → **BUILD SUCCEEDED** on the first attempt. Log: `.build/ticket121/build.log`.
- No new automated tests; no scoring, timing, audio or MIDI implementation changes. Stopped after the successful build per AGENTS.md; no post-change simulator acceptance was run.

### Handoff

The performance and lesson-start acceptance criteria remain open. Jakub must open Training on the iPad, capture the two debug timings, start a new lesson, a due review, Mix, After me and Today, and confirm the controls work. If the original non-start symptom persists, its cause remains to be diagnosed against that device/progress state. This report deliberately does not mark the original bug proven fixed.
