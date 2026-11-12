# 163 — Independent review of help and first-launch tutorial

Status: done (checked and passed by Jakub 2026-11-12). Approved by Jakub on 2026-11-10.

## Goal

Jakub finds the help and tutorial from T162 hard to understand and too thin on the app's features and options. An agent that did not write them reviews the eight help cards and four tutorial cards against what the app actually does.

## Output

`docs/design/2026-11-10-163-tutorial-review.md` in Czech: card-by-card problems and fixes, missing or wrongly explained features with code references, inaccuracies, a proposed new structure with draft CZ + EN copy, open questions. No code or existing doc changes.

## Next step

After Jakub reads the report, Claude writes the rewrite ticket. The rule stays: no new text in the main UI, help lives behind the (?) and How it works entries.

## Agent assignment

Claude subagent (read-only). Fallback: Codex GPT-6.1 Sol, high.
