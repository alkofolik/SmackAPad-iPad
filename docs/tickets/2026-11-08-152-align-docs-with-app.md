# 152 — Align the documents with the app

Status: ready-for-human. Blocked by: none. Source: AI panel round 1 (`docs/reviews/ai-panel/results/round1-claude.md` R2-04; `synthesis.md` item 7); `docs/2026-11-08-ai-panel-action-plan.md`, Batch 1.

## Goal

Agents read only the files they are given, so a document that disagrees with the code keeps misleading them and the AI reviewers. Make the documents state what the app really does today. Documents only: **no Swift, JSON data or string files change in this ticket.**

## What to fix (verify each point in the code first, then edit the text)

1. **Lesson counts.** The brief and SPEC say 587 lessons (24 intro + 539 core + 12 electronic), the paywall and ticket 32 say 587, the Library shows 574. Count the real lessons in `SmackAPad/Resources/Data/` (`intro.json`, `lessons-core.json`, `electronic-path.json`, `genre-extensions.json`) and in what the Library and the paywall actually display. Write one correct number per place and explain any difference (for example hidden or duplicate lessons removed in ticket 20) in one sentence. Also settle "24 vs 25 intro lessons".
2. **Star 3.** SPEC must describe the current rule: star 3 comes through two spaced reviews (tickets 143, 97, 99, 147), not the old single from-memory run. Check `Star3ReviewTests` and `ReviewScheduler` for the exact rule and wording.
3. **Bar verdicts.** The brief (§3 and §8) lists per-bar verdicts (clean / ahead / behind / uneven) as shipped. `PracticeSession.receiveBarSummary` has no caller and `docs/tickets/2026-10-30-bar-summary-scoring.md` is still a draft. Mark them as **not shipped / planned**.
4. **Learning mode threshold.** The brief says star 1 needs 70 % accuracy; Learning mode passes at 60 %. State both, per mode. Also document the required runs per star and the Learning / Challenge modes, which the brief does not describe at all.
5. **Anything else you notice** that clearly contradicts the code while doing 1–4: list it in the final message instead of fixing it silently.

## Files to read

`AGENTS.md`, this ticket, `docs/SPEC.md`, `docs/DECISIONS.md`, `docs/CONTEXT.md`, `docs/reviews/ai-panel/pack/00-brief.md`, `docs/tickets/2026-10-30-bar-summary-scoring.md`, `docs/tickets/2026-11-02-32-in-app-purchases.md`, `docs/tickets/2026-11-02-28-learning-and-challenge-modes.md`, `docs/tickets/2026-11-07-143-star-3-through-two-reviews.md`, the data files above, `SmackAPad/Sources/Progression/` and `StarRequirement.swift` / `StarStreak.swift`.

## Rules

- The code is the truth; the documents follow it. If the code looks wrong rather than the document, do not fix the code: list it in the final message.
- Keep wording short and plain. Change numbers and statements, do not rewrite whole documents.
- Old tickets are history: do not edit them, except marking the bar-summary ticket status line if it is the only way to avoid confusion.

## Acceptance criteria

- [x] Each lesson count in SPEC, the brief and the store documents matches the code, and any difference is explained once.
- [x] SPEC describes the two-review rule for star 3.
- [x] The brief no longer claims bar verdicts are shipped.
- [x] The brief states the Learning (60 %) and normal (70 %) thresholds and the Learning / Challenge modes.
- [x] The final message lists every file changed and every other discrepancy found but not fixed.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: reading and comparing text with code, no risky edits; Flash with high thinking is enough and does not use up Codex limits.

## Done rule

Stop when the acceptance criteria are met. Commit (AGENTS.md); Jakub pushes.
