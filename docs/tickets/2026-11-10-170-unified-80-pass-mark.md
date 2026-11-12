# 170 — One pass mark: 80 % for all lessons

Status: done (checked and passed by Jakub 2026-11-12). Verified by unit tests.

## Change

Today a standard lesson passes (star 1, Learning credit) at 70 % and an Intro lesson at 80 % (`ScoringEngine.swift` 184 and 214: `isIntro ? 0.8 : 0.7`), while Today marks a new lesson passed only at 80 % (`TodayPlan.swift` 16). Make 80 % the single pass mark everywhere.

1. Replace the hard-coded values with one named constant (e.g. `Scoring.passMark = 0.8`) used by `ScoringEngine`, `TodayPlan` and anything else that compares a score to a pass mark (grep for 0.7/0.8 comparisons against scores; the 0.80 From-memory check in `PracticeSession.swift` ~1193 should use the same constant if it means the same thing).
2. Stars and credit already earned stay. Do not recompute old progress.
3. Intro rules screen (`IntroScreen.swift` 254, key "Standard lessons require 70%"): Intro and standard lessons are now the same, so remove or reword that line (EN + CZ). Update any other text mentioning 70 %.
4. Update tests that assert 70 %.

## Acceptance criteria

- [x] A standard-lesson run at 75 % no longer passes; 80 % passes; same for Intro and Today.
- [x] No 70 % left in UI text; existing stars unchanged after update.

### Manual iPad check for Jakub

Play a standard lesson at around 75 % and 85 % and check pass/fail, then a Today new-lesson step.

## Agent assignment

Codex GPT-6.1 Sol, medium (fallback Gemini 3.8 Flash, medium). Small rule change, careful grep.

## Done rule

Build, full test plan per `AGENTS.md`, commit, stop for Jakub's iPad check. Run before or after T169, not in parallel (T169 copy mentions the pass mark).
