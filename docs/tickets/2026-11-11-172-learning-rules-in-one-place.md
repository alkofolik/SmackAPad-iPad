# 172 — Learning rules in one place (no behaviour change)

Status: ready-for-human. Implemented on 2026-11-11; manual iPad checks remain for Jakub. Approved by Jakub on 2026-11-11. Model: Codex GPT-6.1 Sol, thinking high (fallback Gemini 3.8 Pro, high). Do not use Flash: it can miss a less visible threshold when moving constants. Corresponds to AI panel item #28.

## Goal

Collect every threshold and count that decides stars, passes, reviews, unlocking and the minimum number of hits into one file, `LearningRules.swift`. The app must behave exactly as before.

## Steps

1. Go through `Progression/`, `Scoring/`, `UI/StarStreak.swift`, `UI/PracticeSession.swift` and `Persistence/`. Make an inventory of all numeric thresholds and counts that decide stars, passes, reviews, unlocking and the minimum number of hits. Write it to `docs/design/2026-11-11-172-rules-inventory.md` (file, line, value, purpose).
2. Create `LearningRules.swift` in `Progression/`. Name the constants by meaning; give each a one-line English comment.
3. Replace the original literal values with references to these constants. Move `StarStreak.swift` from `UI/` to `Progression/`.
4. Do not change any value. If two thresholds contradict each other (e.g. a leftover of the old 70 % rule), do not fix it: record it in the inventory.
5. Add no UI text and no new features.

Known starting points (not a full list): `Scoring.passMark`, `StarStreak.minimumHitsPerStar = 16`, the `0.85` perfect/good ratio and the cap of 4 runs in `StarStreak.requiredRuns`.

## Done when

- All existing tests (238+) pass unchanged.
- One new test checks the main constants (80 %, 16 hits, 4 runs).
- Behaviour was checked by hand in the five replaced places.
- The inventory also lists any inconsistencies found.

## Implementation

- Centralized numeric qualification rules in `Progression/LearningRules.swift`, including clean-run error tiers, review decisions and migration thresholds. Existing constant APIs forward to the shared values.
- Moved `StarStreak.swift` from `UI/` to `Progression/`; values, formulas, persisted fields and UI text are unchanged.
- Recorded 53 original occurrences, preserved rule differences and a manual code comparison of all five areas in [the rules inventory](../design/2026-11-11-172-rules-inventory.md).

## Validation

- Simulator build and full test suite succeeded: 244 tests, zero failures. Existing tests are unchanged; the only new test checks 80%, 16 hits and the four-run cap.
- Command: `xcodebuild -project SmackAPad.xcodeproj -scheme SmackAPad -destination 'platform=iOS Simulator,id=29546CEC-E603-4A3B-AF2F-28711105A8E5' -derivedDataPath .build/ticket-172/DerivedData -resultBundlePath .build/ticket-172/Tests.xcresult CODE_SIGNING_ALLOWED=NO test`.

## Manual iPad checks for Jakub

Use the five checks in [the inventory](../design/2026-11-11-172-rules-inventory.md#manual-ipad-checks-for-jakub): Learning/Challenge qualification, sparse/Intro patterns, hidden spaced reviews and Star 3, stage access, and resumed progress with Mix/After me. Device verification has not been performed by the agent.
