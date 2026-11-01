# Feedback round 2: proposals (2026-11-01)

Status: proposals from Jakub, not yet turned into tickets. Facts below were checked in the code and data on 2026-11-01.

## 1. What counts as "completed" for unlocking

**Today:** unlocking counts lessons with `passed` = star 1 only (`Progression.passedLessonCount`, SPEC §3.7, `kLessonsToUnlock = 5`). Ticket 19 keeps the same idea for stages ("lessons passed").

**Proposal:** a lesson counts toward unlocking when it has **2 stars** (passed + goal tempo), not all 3. Star 3 (from memory) stays optional, so nobody is blocked by the hardest star.

**Open point:** with ticket 18 (several runs per star) a 2-star lesson takes longer. Decide whether the unlock threshold `min(ceil(lessons/2), 10)` still feels right, or should be lower. Soft unlock stays as the escape hatch.

**Also:** the Library must say what counts, e.g. "Earn 2 stars in 5 lessons to open the next stage".

## 2. Visible announcement of a tempo increase during a run

When the tempo rises after a clean pass, show a short, visible but tasteful animation (not a popup) and a clear label, e.g. the tempo number pulses and "Tempo up: 80 → 85 BPM" appears briefly near the tempo field.

- Must not hide the pattern or cover the pads.
- Short (about 1 s), respects Reduce Motion (then only the text, no movement).
- Fits the colour rules (orange, black, white; no status colours).

## 3. How to earn the third star is not clear

Nothing in the app explains it. Proposal: tell the student where he decides, not in a manual.

- Lesson result and legend: one line per star, with the missing one highlighted, e.g. "★★★ Play it from memory at goal tempo, 80 % or better".
- Library row: tap or long-press on the stars shows the same three lines.
- Practice screen: after star 2, hint that "From memory" is now worth trying.

## 4. Intro and First steps repeat the same lessons

Checked against `intro.json` (24 lessons) and `lessons-core.json` category `starter` ("First steps", 9 lessons):

- **Identical:** First steps #1 "Four on the floor" = Intro 10001 "Kick on every beat" (same hits, hands and velocity).
- **Same notes (pads and steps), differing only in hand or velocity:** 8 of 9 First steps lessons have an Intro twin:

| First steps | Intro |
|---|---|
| 2 Kick and offbeat hat | 10005 Hands take turns, 10015 Dance offbeats |
| 3 Quarter-note hats | 10008 Your first groove |
| 4 Eighth-note hats | 10010 Hats with a kick anchor |
| 5 Backbeat | 10011 A complete backbeat, 10018 Strong and soft hats |
| 7 Four on the floor with clap | 10016 Dance with a clap |
| 8 Backbeat with extra kick | 10013 Extra kick after two |
| 9 Backbeat, kick on the and of 3 | 10014 Extra kick after three |

Only First steps #6 "Open hat on the and" has no twin.

**Options (Jakub to choose):**
- A. Remove the duplicated lessons from First steps (keep Intro, it is the teaching path). Progress for those lesson IDs would need migrating.
- B. Keep both but mark First steps as "repeat in groove form" and change the hands or patterns so they are really different.
- C. Keep both, only fix #1 (the exact copy).

**Decision (Jakub, 2026-11-01): A.** Remove the duplicated lessons from First steps, keep Intro. The exact retired IDs and Intro progress targets are confirmed in ticket 20; lesson 6 remains in First steps.

Reason:  the 24 Intro lessons are stricter and always available, and the Path would otherwise start with things the student has just done.

## Files likely touched

`Progression.swift`, `LibraryScreen.swift` (1, 3, ticket 19), `PracticeSession.swift` and `PracticeScreen.swift` (2, 3, tickets 17 and 18), `lessons-core.json` and `intro.json` (4), localisation catalogs `en` and `cs`.

## Tickets and order

| Ticket | Topic | Starts after |
|---|---|---|
| 17 | Hide pattern only in Play, show played hits | — (chain A) |
| 18 | Minimum runs per star | 17 |
| 22 | Tempo-up announcement | 17, 18 |
| 19 | Library: Path, filters, stage unlocking | — (chain B) |
| 21 | Unlock needs 2 stars | 19 |
| 20 | Remove duplicate First steps lessons | 19, 21 |
| 23 | Explain the third star | 18, 21, 22 |

Chains A (17 -> 18 -> 22) and B (19 -> 21 -> 20) touch different files and can run in parallel; 23 closes both.
