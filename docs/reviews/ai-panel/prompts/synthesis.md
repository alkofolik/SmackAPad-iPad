# Synthesis task (for Claude Code in this repository)

Read `AGENTS.md`, `docs/reviews/ai-panel/README.md`, `docs/reviews/ai-panel/pack/00-brief.md` and every file in `docs/reviews/ai-panel/results/` named `round1-*.md` or `round2-*.md`. Read source files only to verify a code finding that would become a blocker or major item. Do not change any code.

Write `docs/reviews/ai-panel/results/synthesis.md` in English with these sections:

1. **Scores** — one table: the six Part A axes × three reviewers (round 2 corrections applied), plus the average and the spread. Flag axes where reviewers differ by 3 or more.
2. **Consensus** — findings raised by 2 or 3 reviewers (merge duplicates; keep all original IDs, e.g. `gemini R2-04 + claude R1-07`).
3. **Contested** — findings one reviewer raised and another explicitly rejected in round 2. Give both sides in one line each.
4. **Single-source but strong** — raised by one reviewer only, with concrete evidence and high confidence.
5. **Verified against the code** — for every blocker/major code claim: `confirmed`, `wrong` or `cannot tell`, with file and line.
6. **Already decided or already planned** — findings that conflict with `docs/DECISIONS.md`, `docs/2026-11-05-post-v1-plan.md` or existing tickets. Say which, do not re-argue.
7. **Decision list** — one table of all remaining candidate actions, ranked by (severity × number of reviewers × confidence) and effort:

| # | Action | Sources | Severity | Effort | Before 1.0? | Jakub: take / no / later |
|---|---|---|---|---|---|---|

   Leave the last column empty for Jakub.
8. **Noise** — generic advice without evidence (one line each, so Jakub sees it was considered).

Keep it under ~250 lines. Then stop: Jakub fills the last column, and only then are tickets written. Commit (AGENTS.md).
