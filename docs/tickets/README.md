# Tickets — Build Order & Dependencies

## Dependency graph

```
01-project-skeleton
├── 02-data-port
│   └── 03-lesson-models
│       ├── 04-persistence
│       │   └── 05-progression
│       │       └── 12-library-screen ─────┐
│       ├── 06-midi-input ─────────────────┤
│       ├── 07-audio-engine ───────────────┤
│       ├── 08-scoring-engine (tdd) ───────┤
│       └── 09-calibration (tdd) ──────────┤
│                                          │
10-design-directions ──────────────────────┤
    └── 11-theme-and-play-screen ──────────┤
                                           │
                              ┌────────────┘
                              ▼
                    13-settings-screen
                    14-intro-screen
                    15-localisation
                              │
                              ▼
                    16-integration-review
```

## Build order

| Phase | Tickets | Can run in parallel? |
|-------|---------|---------------------|
| 1 | 01-project-skeleton | — |
| 2 | 02-data-port | — |
| 3 | 03-lesson-models | — |
| 4 | 04-persistence, 06-midi-input, 07-audio-engine, 10-design-directions | ✅ All four in parallel |
| 5 | 05-progression, 08-scoring-engine, 09-calibration, 11-theme-and-play-screen | ✅ All four in parallel (05 waits for 04; 08/09 wait for 03; 11 waits for 10) |
| 6 | 12-library-screen, 13-settings-screen, 14-intro-screen | ✅ All three in parallel (after 05 + 11) |
| 7 | 15-localisation | — (after all screens exist) |
| 8 | 16-integration-review | — (after everything) |

## Agent assignments summary

| Agent | Tickets |
|-------|---------|
| Gemini 3.8 Flash High (Antigravity) | 01, 02, 03, 04, 05, 12, 13, 14, 15 |
| Codex GPT-6.1 Sol, high | 06, 07, 08, 09, 11, 16 |
| Claude Opus 4.6 Thinking (Antigravity, account B; before 2 Nov) | 10 |

## Skills used

| Skill | Tickets |
|-------|---------|
| tdd | 08-scoring-engine, 09-calibration |
| imagegen-frontend-mobile | 10-design-directions |
| gpt-taste | 11-theme-and-play-screen |
| code-review | 16-integration-review |

## Feedback round 3 (2026-11-01)

| Ticket | Topic | Agent / thinking | Order |
|---|---|---|---|
| 24 | Practice screen: third star, tempo banner, colour tail, progress | Codex GPT-6.1 Sol, xhigh | 1st |
| 25 | Library redesign, unified look, Intro rows, First steps removed, unlock flow | Codex GPT-6.1 Sol, high (two conversations A and B) | 2nd (after 24) |
| 26 | Sound kit "Automatic" and per-lesson choice | Gemini 3.8 Flash, high (done 2026-11-01) | done |
| 27 | Motion: `2026-11-01-27-motion.md` (spec: `docs/design/2026-11-01-motion-proposals.md`) | Codex GPT-6.1 Sol, medium | after 24-26 (approved) |
