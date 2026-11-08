# AI panel — synthesis (round 1)

Date: 2026-11-08. Inputs: `round1-gemini.md` (Gemini 3.8 Flash, high; saw brief, screenshots, data, video 1 only), `round1-chatgpt.md` (GPT-6 Astra, high; brief, screenshot PDF, GitHub), `round1-claude.md` (Claude Opus 5.5, extended thinking; brief, screenshot PDF, GitHub). A Gemini 3.1 Pro run saw only the brief and is excluded (not saved). Round 2 skipped by Jakub's decision. No reviewer watched videos 2–3.

## 1. Scores

| Axis | Gemini | ChatGPT | Claude | Avg | Spread |
|---|---|---|---|---|---|
| First 10 minutes | 6 | 5 | 5 | 5.3 | 1 |
| Learning effectiveness | 7 | 6 | 6 | 6.3 | 1 |
| Motivation to return | 8 | 6 | 6 | 6.7 | 2 |
| Visual design | 8 | 7 | 7 | 7.3 | 1 |
| App Store readiness | 6 | 4 | 3 | 4.3 | **3 ⚑** |
| Commercial potential | 7 | 5 | 5 | 5.7 | 2 |

⚑ Readiness: Gemini did not read the persistence code; Claude's 3 rests on the confirmed data-loss bug (§5).

Price: all three say **USD 19.99** one-time (Gemini: 14.99 launch offer; Claude: not below 14.99). All three recommend a **real-hardware beta with 5–10 outside players** as the one thing for next month.

## 2. Consensus (2–3 reviewers)

- **Today summary says "Reviews 0 of 2" next to ✓ 100 %** — gemini R2-06 + chatgpt A4-1, R4-03 + claude A4-2, R3-07.
- **Review backlog shown as debt** ("29 due", Training 29 vs Today 2, cumulative forecast) — gemini R3-04 + chatgpt R4-02 + claude R3-05.
- **Velocity/dynamics ignored by scoring** (ghost-note lessons) — gemini R3-02 + chatgpt R4-01 + claude (A2) + Gemini Pro.
- **Timing windows too wide to certify "in time"** — gemini R3-01 + claude R3-03 (conflicts with a decision, §6).
- **Missing CC BY-SA sound credits, privacy/support links, privacy manifest** — gemini R2-03, R2-05 + chatgpt R3-03, R3-05 + claude A2.
- **Hardware not field-tested; presets look like verified compatibility** — chatgpt A4-2, R3-06 + claude A6 + gemini C.
- **Paywall sells "587 lessons" instead of the 529 extra** — chatgpt R2-01 + claude A5 + gemini A5.
- **First launch unclear / no obvious first step** — gemini R1-01, R1-05 + chatgpt A2 + claude A2 (all low–medium confidence: no empty-state screenshots).

## 3. Contested

Round 2 not run. Only internal disagreement: Gemini R1-07 (no count-in) vs code, which has a count-in (`PracticeSession.swift` `countInEvents`). Treated as wrong.

## 4. Single-source but strong

- claude R1-01 progress wipe on decode failure (blocker, confirmed).
- claude R1-02 legacy ★3 shown next to "Review · 0 of 2 passed".
- claude R1-04 pad double-trigger counted as an error.
- claude R1-05 every practice screen decodes all kits; R1-03 live pad sound via main thread; R1-06 route change silences run.
- claude R2-01 learning thresholds duplicated across ≥6 files; R2-02 files 47–68 KB; R2-03 "no re-run of tests" rule let ticket 143 regressions through (ticket 147).
- claude R3-01 reviews show notes before the hidden passes; R3-02 adaptive centre hides steady drag/rush.
- chatgpt R3-01 reviewer may not find touch-pad fallback (portrait + 16-pad only); R3-04 Bluetooth text unverified; R3-06 "NI Maschine" preset (Maschine generally not usable on iOS).
- gemini R1-02 MIDI learn numbers Pad 1 top-left; R1-03 pad abbreviations unexplained; R2-01 ghost-note contrast in From memory; R2-02 small toolbar targets; R2-04 "Síť Session" Czech leak.

## 5. Verified against the code

| Claim | Result | Where |
|---|---|---|
| Decode failure → empty records → next save overwrites file | confirmed | `Persistence.swift` catch ~1091–1097 sets `records = [:]`; `save()` 1225 never checks `lastLoadError` |
| Same-pad hit within 30 ms counts as extra error | confirmed | `ScoringEngine.swift` 116–117 |
| Bar verdicts not shipped | confirmed | `PracticeSession.swift` 731 `receiveBarSummary` has no caller |
| Today plays only 2 reviews | confirmed | `TodayPlan.swift` 28 `prefix(2)` |
| ✓ shown for played step, count only passed/settled | confirmed | `TodaySessionScreen.swift` 332–337 vs 759–766 (why the 2 reviews did not pass: cannot tell) |
| Windows L1–2 ±45/100/200 ms | confirmed (decided) | `ScoringEngine.swift` 103; DECISIONS §41 |
| Scorer receives no velocity | confirmed | `ScoringEngine.receive(padIndex:at:)` 113 |
| Adaptive centre shifts the shown error | confirmed | `ScoringEngine.swift` 131, 147 |
| `fadeMemoryNotes` defaults to true | confirmed | `Persistence.swift` 543 |
| Practice and calibration each create an AudioEngine | confirmed | `PracticeSession.swift` 156, `CalibrationSession.swift` 23 (RAM size not measured) |
| MIDI callback hops to MainActor before sound | confirmed (latency not measured) | `MIDIInput.swift` 205 |
| Route change restarts engine, stops players, no session callback | likely | `AudioEngine.swift` 703–712 |
| Calibration keyed by input device only | confirmed | `Persistence.swift` 647 |
| Late tick aborts run | cannot tell | `AudioEngine.swift` 512–515 throws; catch path not traced |
| Legacy ★3 records vs two-review rule | cannot tell (symptom visible on screens 09, 19) | `Persistence.swift` 1118, 1140 |
| "NI Maschine (36–51)" is a note map only | confirmed | `LessonData.swift` 301–303 |

## 6. Already decided or already planned

- Timing windows and equal credit (DECISIONS §41, §51; brief §8) — gemini R3-01, claude R3-03 call it a serious mistake. Jakub decides (#25).
- Adaptive centre kept (DECISIONS §9) — claude R3-02 keeps it for matching, only changes what is shown: compatible.
- Star 3 only via Training (ticket 143) — gemini R3-03 provisional same-day star: conflicts, not taken.
- Touch pads portrait only (ticket 40) — Gemini Pro R2-02: conflicts.
- Phrases, songs, results by part, "slow down" suggestion — post-v1 plan §1–4 (gemini R3-06, claude R3-06 partly).
- Privacy manifest, About/credits, support site, store texts — tickets 79–83 and release checklist C/E.
- TestFlight beta — release checklist D.
- Brief §8 "per-bar verdict" is stale: Jakub chose a running per-hit timing indicator (round 5, 2026-11-02). Fix the brief/SPEC, not the app.

## 7. Decision list

Last column filled 2026-11-08: Jakub approved working through the findings; order set by Claude. "decide" = touches a recorded decision, Jakub chooses before a ticket.

| # | Action | Sources | Severity | Effort | Before 1.0? | Jakub |
|---|---|---|---|---|---|---|
| 1 | Never overwrite progress after a failed load: backup corrupt file, block saves, warn; schemaVersion; per-record decode; tests with golden files | claude R1-01, R2 #2 | blocker | S | yes | take |
| 2 | Full test suite must pass before every commit (AGENTS.md) | claude R2-03 | major | S | yes | take |
| 3 | Today summary and step ✓ consistent; trace why 2 reviews did not count; states Played / Passed / Did not count + reason | 3 reviewers | major | M | yes | take |
| 4 | Legacy ★3 vs "0 of 2 passed" migration | claude R1-02 | major | S | yes | take |
| 5 | Review load: Today shows "2 today", separate queue, forecast label, no orange backlog on Home | 3 reviewers | major | S | yes | take |
| 6 | Ignore same-pad double triggers (~25 ms) | claude R1-04 | major | S | yes | take |
| 7 | Docs drift: SPEC star 3, brief bar verdicts, 574 vs 587, 24 vs 25 intro, Learning 60 % | claude R2-04, Gemini Pro, brief notes | major | S | yes | take |
| 8 | About + AVL CC BY-SA credits + support/privacy links (tickets 80/81) | 3 reviewers | blocker | M | yes | take |
| 9 | Privacy manifest + export compliance (ticket 79) | chatgpt R3-03, claude | blocker | S | yes | take |
| 10 | Paywall: "529 more lessons", show what you learn next | 3 reviewers | major | S | yes | take |
| 11 | Controller presets: tested list, rename "NI Maschine", no-controller hint, App Review notes | chatgpt R3-01, R3-06 | major | M | yes | take |
| 12 | Audio route change: stop run with message; calibration per output type or BLE warning | claude R1-06 | major | M | yes | take |
| 13 | One shared AudioEngine, load selected kit only; then live pad sound off main thread (measure on old iPad) | claude R1-05, R1-03 | major | M | yes | take |
| 14 | Verify Bluetooth permission text and refusal path | chatgpt R3-04 | major | S | yes | take |
| 15 | First launch: clear "Start here" when progress is empty | gemini R1-01/05, chatgpt, claude | major | S | yes | take |
| 16 | MIDI learn: check Pad 1 position vs hardware | gemini R1-02 | major | S | yes | take |
| 17 | Pad abbreviation legend (HH, SN, KD…) | gemini R1-03 | major | S | yes | take |
| 18 | Toolbar touch targets ≥ 44 pt | gemini R2-02 | major | S | yes | take |
| 19 | Ghost-note contrast in From memory | gemini R2-01 | major | S | yes | take |
| 20 | Purchase messages localized; "Síť Session" leak | claude R1-08, gemini R2-04 | minor | S | yes | take |
| 21 | Skip one late sound instead of stopping the run | claude R1-07 | minor | S | yes | take |
| 22 | Reviews hide notes from pass 1 (retry with notes after a failed hidden attempt) | claude R3-01 | major | S | yes | decide |
| 23 | Show and store un-centred timing error | claude R3-02 | major | S | yes | decide |
| 24 | Today sized by time; pause new lessons above ~10 due | claude R3-05, gemini R3-04 | major | S | yes | decide |
| 25 | Star 2 needs ≥ 80 % perfect/good hits (or tighter windows) | claude R3-03, gemini R3-01 | major | S | ? | decide |
| 26 | Star 3 wording "Remembered twice", "Settled" only at step 4 | claude R3-08 | minor | S | yes | decide |
| 27 | Hide per-hit readout in From memory / reviews / Mix | claude R3-04 | major | S | ? | decide |
| 28 | LearningRules.swift single source of thresholds | claude R2-01 | major | M | after #1–7 | take |
| 29 | Split large files (start with Persistence.swift), no logic change | claude R2-02 | major | M | after #28 | take |
| 30 | Delete dead code paths; AGENTS rule "remove rule = remove code and tests" | claude R2-05 | minor | S | yes | take |
| 31 | One String Catalog + key-coverage test | claude R2-06 | minor | M | later | take |
| 32 | Ticket template: "Docs to update", "Rules touched", symbols not lines, status "accepted on iPad" | claude R2-07/08 | minor | S | yes | take |
| 33 | Closed TestFlight, 5–10 outside drummers, old iPad + BLE controller | all three A6 | major | M | yes | take |
| 34 | Tempo also steps down (2 up / 2 down) | claude R3-06 | minor | S | later | later |
| 35 | Velocity check for ghost-note lessons | 3 reviewers | major | L | no | later |
| 36 | Marketing route: setup videos, communities, controller makers, campaign links | chatgpt R2-02 | major | L | around release | later |

## 8. Noise / not taken

- Count-in missing (gemini R1-07): wrong, count-in exists.
- Bigger popover switches (gemini R2-07): no evidence of a problem.
- Calibration "intimidating" with default offsets (gemini R1-06): guess, revisit after beta.
- Posture/finger diagrams (gemini R3-05): idea, post-1.0.
- Landscape touch pads (Gemini Pro): conflicts with ticket 40.
- Provisional same-day star 3 (gemini R3-03): conflicts with ticket 143.
- "Audience is narrow" (chatgpt R1-02): true, strategy only, no action.
