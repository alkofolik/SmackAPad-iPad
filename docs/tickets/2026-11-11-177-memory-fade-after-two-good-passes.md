# 177 — From memory: notes hide only after two successful warm-up passes

Status: ready-for-agent. Approved by Jakub on 2026-11-11 (point 5; he chose "two").

## Goal

Today the first two From-memory passes are fixed warm-ups (`LearningRules.firstHiddenMemoryPass = 3`): the notes fade on pass 3 no matter how the first two went. That is sometimes not enough. New rule: the notes stay visible until the player has played **two warm-up passes in a row at the pass mark (80 %) or better**; only then do they fade and the hidden (counting) passes begin.

## Rules

1. Warm-up passes = passes with notes visible. A warm-up pass is "successful" when its score is ≥ `Scoring.passMark` (80 %). Tempo does not matter for warm-ups.
2. The notes fade after the **second consecutive** successful warm-up pass. A weaker warm-up pass resets the warm-up streak to 0 (notes stay visible).
3. Everything after that is unchanged: hidden passes count for the review / 3rd star exactly as today.
4. If `settings.fadeMemoryNotes` is off, nothing changes (all passes hidden from the start, as today).
5. Replace the fixed pass-number rule everywhere it is used (`PracticeSession.swift` 330, 1100, 1122, 1240; `StarStreak.swift`; `ReviewScheduler.swift` 165–177) with one helper in `LearningRules.swift`, e.g. `warmUpPassesNeeded = 2` plus a small state value "notes visible / hidden" kept in the session. Delete `firstHiddenMemoryPass` and any test that enforces the old rule; no dead code.
6. Mix (`isMix`) and Today must use the same helper.
7. The HUD indicator for warm-ups (eye symbols in the design, existing fade-phase indicator today) shows how many successful warm-ups are done (0, 1, 2).
8. Help: update the existing review/From-memory help card (ticket 169 texts, key `help.reviews.warmups` and its Czech twin): "Notes hide after 2 good passes in a row (80 %+)." / "Noty zmizí po 2 úspěšných průchodech za sebou (80 % a víc)." No new text elsewhere in the UI.

## Files to read

- `AGENTS.md`
- `SmackAPad/Sources/Progression/LearningRules.swift`, `ReviewScheduler.swift`, `StarStreak.swift`
- `SmackAPad/Sources/UI/PracticeSession.swift`, `HelpIllustration.swift`, `HelpDeck.swift`
- `SmackAPad/Resources/en.lproj`, `cs.lproj` strings

## Tests

Unit tests: (a) two good warm-ups → hidden from pass 3; (b) good, weak, good, good → hidden from pass 5; (c) fade setting off → hidden from pass 1. Run the full test suite.

## Acceptance criteria

- [ ] Notes hide only after two consecutive warm-up passes ≥ 80 %.
- [ ] One rule helper, used by practice, review, mix and Today; old constant removed.
- [ ] Help text updated in English and Czech.
- [ ] New tests pass; the full suite passes.

### Manual iPad check for Jakub

From memory on: play the first pass badly → notes stay; then two good passes → notes fade.

## Agent assignment

Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Pro, high. Run after ticket 176 (same code area).

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
