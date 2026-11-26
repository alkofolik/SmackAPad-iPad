# 251 — Boss encounter v1 (one lesson in a loop, stamina, Pattern Veil)

Status: open · after 250

Design source: `docs/design/2026-11-26-story-mode-gdd-v1.md` — the **Amendments** section at its top is binding and wins over the draft below it.

## Goal

Replace the boss node's "play the last lesson" with a real, beginner-friendly encounter built only from what the practice engine already does. No seamless multi-pattern medley and no mid-run tempo change (those are v2, a later ticket).

## Rules (GDD Amendment 3)

1. **Pattern:** one lesson of the stage with ★2, preferring the last ★2 keystone on the student's route, otherwise any ★2 lesson of the stage. Shown before the attempt; unchanged on immediate retry.
2. **Length:** 8 bars — the pattern repeats until 8 bars (a 3-bar pattern → 9 bars is fine: use the smallest whole number of repeats ≥ 8 bars). Count-in one bar as today.
3. **Tempo:** level % of the lesson's goal tempo — L1 85 %, L2 88 %, L3 90 %, L4 92 %, L5 95 %, rounded down. Fixed for the whole encounter.
4. **Stamina** = ⌈0.75 × bars⌉. Each clean played bar removes 1 (see 4a); other bars remove nothing. Stamina updates during the run, after every bar. The run always plays to its end. Victory = stamina 0 at the end.
4a. **Clean bar** (amended 2026-11-26, approved by Jakub). There is no per-bar verdict in the app (`receiveBarSummary` has no caller). Do not revive the cancelled ticket `2026-10-30-bar-summary-scoring.md`; no ahead/behind/uneven.
   - Clean = every expected note of that bar is judged `perfect` or `good`, and no `wrong` hit was played inside the bar (same criterion as `computeBarSummary`). A bar without expected notes is clean if it has no wrong hit.
   - Judge every played bar of every repetition separately, from the existing `judgmentsByPass` and `playedHits`. Never merge repetitions.
   - Judge a bar once, only after the matching window of its last note has closed (bar end plus the scorer's maximum window, allowing for calibration and timing centre as `earlyResult` does), so a late but valid hit still counts. The last bar is judged before the result is shown.
   - This only reads existing data. Put the rule in a small pure function with its own tests.
5. **Attack — Pattern Veil only:** hide the note prompts for one played bar. The existing From-memory visibility is one value for the whole pattern, so add display-only per-bar hiding (scrolling and static view) with the same hidden look; do not switch the run to From memory and do not award memory credit; pads, grid, metronome and playhead stay. Announced one bar ahead with one short line ("One bar hidden" / "Jeden takt skrytý"). Count: L1 none, L2 one, L3–L5 two; never on the first bar, never on a bar not yet shown, never overlapping.
6. **Losing:** nothing is lost. Result shows "Retry the boss" / "Gentle attempt" (same encounter without attacks, same rewards) / "Practice first" (opens the lesson).
7. **First victory:** marks the stage exam completed (existing `completedExamStageIDs`), opens the next stage (subject to purchase), shows the boss victory. Key and skin rewards come from ticket 252; until then keep the current key award. Repeated wins give nothing extra. A boss win does not give ★3.
8. **Boss identity:** name + level form from the GDD roster (§2.4, Amendment 1); strings `story.boss.<stageId>.name/intro/victory` with the GDD names and placeholder lines until 253. Monochrome emblem per boss family (5 SF Symbols-based emblems is fine for v1).
9. **Do not change** the audio scheduler, MIDI timing or the scoring engine; the boss is a configuration of an ordinary looping run plus a stamina counter fed by the clean-bar rule in 4a. Reading judgments from the run loop is allowed; changing how or when notes are scheduled, matched or scored is not. If that is impossible, stop and report what is missing.
10. Available in Story mode from the boss node and in Free practice from the stage (GDD §1.10).

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Practice/PracticeSession.swift` (`computeBarSummary`, `tick`, `judgmentsByPass`, looping, From-memory hiding), `SmackAPad/Sources/UI/Practice/PatternField.swift`, `SmackAPad/Sources/Progression/DrummerPathEvaluator.swift` (stage exams), 250's boss node.

## Tests

Pattern choice; bar count for 1/2/3/4-bar patterns; tempo per level; stamina formula; clean bar (all perfect/good; miss; off; wrong hit; empty bar; repetitions judged separately; late valid hit near the bar end still counts; each bar judged only once; last bar counted); veil hides only its bar and gives no memory credit; veil schedule rules (count, never first bar, announced, no overlap); gentle attempt has no attacks; first victory marks the exam once, repeats add nothing; nothing lost on defeat. Narrow tests while working, full `SmackAPadTests` once at the end.

## Acceptance criteria

- [ ] Boss node starts an 8-bar encounter at the level tempo with a visible stamina count.
- [ ] Pattern Veil works per level and is announced; gentle attempt removes it.
- [ ] Victory marks the stage exam and opens the next stage; defeat loses nothing.
- [ ] Timing/scoring code untouched; builds, `SmackAPadTests` passes on the iPad simulator.

### Manual iPad checks for Jakub (no good playing needed)

- A debug scenario with an open Level 1 boss (add one if 160's scenarios lack it): start the boss, watch the stamina and the result screen; play badly on purpose → "Retry / Gentle attempt / Practice first", nothing lost.
- On your real profile open a Level 2 boss, watch for the "One bar hidden" warning.

## Agent assignment

**Codex Sol 6.2, thinking high** (touches the practice run loop; this is the risky ticket). Fallback: Antigravity Gemini 4 Hydrogen, high.

## Done rule

Build, full test suite once, commit on `release-polish`, report changed files concisely.
