# 134 — Shorter Czech labels: "Intro", "Systém"

Status: ready-for-agent. Type: implementation. Source: Jakub, 2026-11-07 (screenshots Home and Settings).

## Changes (Czech only, English stays)

1. Intro category: "Úvodní cvičení" → **"Intro"** everywhere it is a name (Home pad 04, Library sidebar/header, Intro screen title). Keys in `cs.lproj/Localizable.strings`: `"Intro"`, `"Intro Exercises"`, `"Intro exercises"` (lines ~106, ~215, ~234). The long explanation sentence (~218) may keep the word "Úvodní cvičení" in its prose, or use "Intro cvičení"; keep it readable.
2. Appearance option: `"System" = "Podle systému"` → **"Systém"** (~187). Check `cs.tsv` line ~2439 ("Podle systému · výchozí") — change to "Systém · výchozí" if it is the same control.
3. Home pad 04 must then show "INTRO" without "…" (ticket 116 rule).

## Acceptance criteria

- [ ] Home pad reads "INTRO", fully visible.
- [ ] Settings › Vzhled shows "Světlý · Tmavý · Systém".
- [ ] English texts unchanged. Build succeeds. No new tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **low**. Fallback: Codex GPT-6.1 Sol, low.
- **Reasoning**: strings only.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub tests on the iPad.
