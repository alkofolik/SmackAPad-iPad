# 109 — Today session: a way out to Home (and so to the Library)

Status: ready-for-agent. Source: Jakub, 2026-11-06 (iPad test of ticket 103/107). Depends on: 103.

## Problem

`TodaySessionScreen` is a `fullScreenCover` (opened from the Home hero pad and from the Training page START button). While the session is not finished it shows only **Continue / Skip / Done for today**. There is no back or Home button. Leaving Practice (back) always returns to this Today screen. So the only way out is "Done for today", which ends the day's plan and postpones the reviews. A player who wants to go to the Library and practise their own lessons is stuck.

Many players will never use Today and practise only through the Library. Today must never trap them.

## Rules

1. The Today screen always has a **Home / Domů** button in the top bar (same placement and style as the other full-screen covers, e.g. the toolbar button in `BadgesScreen` / `PurchasesView`). It is visible in every phase: hand-off card, end card.
2. Home **only closes the cover**. It does **not** finish the plan, does **not** skip a step and does **not** postpone any review. The plan stays saved for today (ticket 103 rule 7), so the hero pad still reads TODAY and tapping it resumes at the same step.
3. On the end card ("That's enough for today") the existing Home button stays; the top-bar Home does the same thing.
4. From Home the player reaches the Library as usual (Home pad 2). No Library button on the Today screen is needed.
5. If the cover was opened from the Training page, Home returns to the Training page (the cover's `onHome` closure already does this; keep the name or rename to `onClose`, your choice).
6. Practice opened from Today keeps returning to the Today hand-off card (ticket 103 rule 4). Do not change that.

## Files to read

`AGENTS.md`, this ticket, ticket 103, `SmackAPad/Sources/UI/TodaySessionScreen.swift`, `SmackAPad/Sources/UI/HomeScreen.swift` (lines ~400–510, cover and hero pad), `SmackAPad/Sources/UI/TrainingScreen.swift` (cover ~line 147), `SmackAPad/Sources/UI/BadgesScreen.swift` (toolbar pattern only), both `Localizable.strings` ("Home" already exists).

## Acceptance criteria

- [ ] Today screen shows Home in the top bar at every step.
- [ ] Home closes the session; Home screen then still shows TODAY; tapping it resumes at the same step; no review was postponed.
- [ ] From Home the Library opens normally.
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: start Today, play one step, tap Home, go to the Library and play a lesson, come back to TODAY and continue.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium**. Fallback: Codex GPT-6.1 Sol, medium.
- **Reasoning**: one button and one closure; the only care is that closing must not touch the saved plan.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
