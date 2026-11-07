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

## Legacy parity, priority 1 (2026-11-02)

Source: comparison of the legacy app (user manual 2026-10-25) with the iPad app. Tickets are independent of each other; 28 builds on commit 1fc4a31 (round-4 star change).

| Ticket | Topic | Agent / thinking | Order |
|---|---|---|---|
| 28 | Practice mode: Learning (default) and Challenge | Codex GPT-6.1 Sol, high | 1st |
| 29 | Start/stop from the MIDI controller, tempo knob | Codex GPT-6.1 Sol, high | after 28 (same agent) |
| 30 | Lesson instructions panel | Gemini 3.8 Flash, high | any time, parallel |
| 31 | Volume for metronome, pads and pattern sound | Gemini 3.8 Flash, high | any time, parallel with 30 (different files except Settings/PracticeTools — run one after the other if on the same account) |

## Timing and display bugs (2026-11-03)

Source: Jakub's iPad test. Bluetooth MIDI breaks timing; cable works.

| Ticket | Topic | Agent / thinking | Order |
|---|---|---|---|
| 55 | "Bars shown" setting ignored in static view | Gemini 3.8 Flash, high | 1st, independent |
| 54 | Bluetooth MIDI timing (phase A log, phase B fix) | Gemini 3.8 Pro, high (fallback Codex GPT-6.1 Sol, high) | 2nd |
| 56 | Playhead speeds up at run start | Gemini 3.8 Pro, medium | after 54 (same file) |
| 57 | App icon from the existing logo (Part 1 of 46, split off) | Gemini 3.8 Flash, high | any time, independent |
| 58 | Result card: always "Next lesson"; "Start" becomes "Again" | Gemini 3.8 Flash, high | before 59 |
| 59 | A scored run lasts about four bars, as in the original tool | Gemini 3.8 Pro, high (fallback Codex GPT-6.1 Sol, high) | after 58 |

## App Store release track (2026-11-04) — PARKED, not in the build order

Source: Claude's pre-release audit. Checklist with the full chronological list: `docs/2026-11-04-app-store-release-checklist.md`. Run when functional tickets are frozen for 1.0.

| Ticket | Topic | Agent / thinking | Order |
|---|---|---|---|
| 79 | Privacy manifest, export-compliance key, Release-build hygiene | Gemini 3.8 Flash, high | 1st |
| 81 | Public support + privacy policy pages (EN/CS); Jakub chooses hosting first | Gemini 3.8 Flash, medium | parallel with 79 |
| 80 | Settings → About: version, support/privacy links, sound and font credits | Gemini 3.8 Flash, high | after 81 (needs URLs) |
| 83 | App Store listing texts and review notes (EN/CS) | Claude (Opus), medium | any time |
| 82 | App Store screenshots 13" iPad via UI test | Codex GPT-6.1 Sol, high | last, when UI is frozen |

## iPad feedback (2026-11-05)

Source: Jakub's iPad test, photos 1–6.

| Ticket | Topic | Agent / thinking | Order |
|---|---|---|---|
| 84 | Static view: smooth bar transition, downbeat mark covers the "1" | Gemini 3.8 Flash, high (fallback Codex GPT-6.1 Sol, high) | 1st |
| 87 | Static-view button cycles bars shown (1, 2, 3, all) | Gemini 3.8 Flash, high | after 84 (same file) |
| 85 | Shorter "Memory ★3" button label | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | any time, parallel |
| 86 | Star rules / session results popovers squashed below the card | Gemini 3.8 Flash, high | after 85 (same file) |
| 88 | Appearance change applies at once | Gemini 3.8 Flash, high | any time, parallel |
| 89 | Library: framed levels, categories, lesson cards; top-left overlap | Gemini 3.8 Flash, high | any time, parallel |
| 90 | Static view: remove the extra vertical bar line | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | any time (same file as 84/87) |
| 91 | Transport buttons equal size; Czech "Znovu" | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | any time |
| 92 | Palette: cream white and soft warm black (Theme.swift only) | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | any time (after 88, same Theme file) |
| 93 | Practice: orange band larger and centred; pad map contrast | Codex GPT-6.1 Sol, high (fallback Gemini Flash, high) | after 92 |
| 94 | One shape language (square corners, one border style) | Gemini 3.8 Flash, high (fallback Codex Sol, medium) | after 91, 92 |
| 95 | Home grid centred/larger; Library filter row spacing | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | after 92 |
| 96 | Logo optically centred (icon, Home tile, wordmark SVGs) | Gemini 3.8 Flash, high (fallback Codex Sol, medium) | after 95 |

## Training (2026-11-05)

Source: Jakub, retention and memory discussion; legacy "Trénink" concept 2026-10-06. Home: pad 3 becomes Training, pad 8 becomes Settings, About moves into Settings. Later ideas: `docs/2026-11-05-post-v1-plan.md`.

| Ticket | Topic | Agent / thinking | Order |
|---|---|---|---|
| 97 | Memory star only on a later day than the goal-tempo star | Gemini 3.8 Flash, high (fallback Codex Sol, high) | 1st |
| 98 | Home pad Training, Training screen, spaced review (Due) | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 97 |
| 99 | From memory: notes fade out over the first passes | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 98 |
| 100 | Training: Mix of learned lessons | Codex GPT-6.1 Sol, high (fallback Gemini 3.8 Pro, high) | after 98 |
| 101 | Play after me (call and response) | Codex GPT-6.1 Sol, high (fallback Gemini 3.8 Pro, high) | after 100 (same session file) |
| 102 | Fix three outdated unit tests after 97–100 | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | any time |
| 108 | Fix three failing tests (review stamp, After me scoring) | Gemini 3.8 Flash, high (fallback Codex Sol, high) | any time |
| 109 | Today session: Home button that keeps the plan (way to the Library) | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | 1st (before 110) |
| 110 | Today session screen matches mockup frame 3 | Gemini 3.8 Flash, high (fallback Codex Sol, medium) | after 109 (same file) |
| 111 | Proposals: modern Home pads and app motion (HTML previews, no code) | Gemini 3.8 Flash, high (fallback Codex Sol, high) | any time; implementation ticket after Jakub chooses |
| 112 | Home pads: look of proposal A with the light bar from B | Gemini 3.8 Flash, high (fallback Codex Sol, high) | 1st (after 110) |
| 113 | Transitions: pad zoom into screens, Today step-in | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 112 (same Home files) |
| 114 | Proposals: Home background like a pad-controller surface (HTML previews, no code) | Gemini 3.8 Flash, high (fallback Codex Sol, high) | any time (needs 112 look only as reference); implementation after Jakub chooses and after 113 |
| 115 | Centre logo tile becomes a pad that opens About | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 112 and 113 |
| 116 | Home pads: text is never cut off ("…") | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | after 112 (same HomePadView) |
| 117 | Home background v2: real-looking controller body, one design, HTML preview (no code) | Gemini 3.8 Flash, high (fallback Codex Sol, high) | any time; implementation after Jakub approves |
| 118 | Controller body preview: ribbed body + smooth plate, centred layout, portrait fix (no code) | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 117 (same files); implementation ticket after Jakub approves |
| 119 | Home controller body: ribbed body, smooth plate with screws, faders, real wordmark title | Codex GPT-6.1 Sol, high (fallback Gemini 3.8 Pro, high) | now (112, 113, 115, 116 are done) |
| 120 | Home Continue pad: crash on tap, "Pokračovat" wraps in portrait | Codex GPT-6.1 Sol, high (fallback Gemini 3.8 Pro, high) | 1st (crash) |
| 121 | Training: opens after ~5 s, lessons do not start from Training | Codex GPT-6.1 Sol, high (fallback Gemini 3.8 Pro, high) | 2nd |
| 122 | Practice header subtitle on one line | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | any time |
| 123 | Mode switch to/from After me: no jump, smooth animation | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 122 (same header) |
| 124 | Pad layout toggle sometimes lags | Gemini 3.8 Flash, high (fallback Codex Sol, high) | any time |
| 125 | Proposal: whole app matches Home (palette, graphics, motion), HTML previews, no code | Gemini 3.8 Flash, high (fallback Codex Sol, high) | any time; best after 122/123; implementation tickets after Jakub picks |
| 126 | App skin 1: shared tokens and components, "Klidný satén" (skin only, no layout change) | Codex GPT-6.1 Sol, high (fallback Gemini 3.8 Pro, high) | 1st of the skin work |
| 127 | App skin 2: Practice screen | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 126 and 124 |
| 128 | App skin 3: Library, Training, Today | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 126 and 121 |
| 129 | App skin 4: remaining screens and banners | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 126; parallel with 127/128 |
| 130 | Buttons react again: hit areas after the satin skin, Library lessons open | Codex GPT-6.1 Sol, high (fallback Gemini 3.8 Pro, high) | 1st (before 121 and 131) |
| 131 | Proposal: one button system for the whole app (HTML previews, no code) | Gemini 3.8 Flash, high (fallback Codex Sol, high) | after 130; implementation ticket after Jakub chooses |
| 132 | Announce in advance that the third star unlocks the next day | Gemini 3.8 Flash, medium (fallback Codex Sol, medium) | any time (Practice files; not Training/Library while 121 runs) |
