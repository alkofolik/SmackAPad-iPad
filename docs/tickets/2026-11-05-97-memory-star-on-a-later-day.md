# 97 — The memory star can only be earned on a later day than the goal-tempo star

Status: ready-for-agent. Source: Jakub, 2026-11-05 (retention discussion; legacy "Trénink" concept 2026-10-06, §4: practice performance overstates what is retained, sleep consolidates motor sequences).

## Goal

Star 3 (From memory) must prove the pattern is remembered, not just held in short-term memory from the minutes before. So the memory star can be earned only on a **local calendar day after** the day the lesson earned star 2 (goal tempo). Nothing is locked: the player may still play From memory on the same day; it just does not earn star 3 yet.

## Rules

1. Store `masteryDay` (local calendar day, `YYYY-MM-DD` string, device time zone) in `LessonProgress` the first time `mastery` becomes true. Never change it afterwards.
2. Old records: `mastery == true` without `masteryDay` → treat as earned on an earlier day (memory star allowed today). Decode with `decodeIfPresent`; no migration write needed. `merging` (import, intro migration) keeps the earlier of two days.
3. A memory qualification (`fromMemory`, bpm ≥ target, score ≥ 80 %) counts toward star 3 only when `today > masteryDay`. If star 2 is earned in this very run or earlier today, the run adds no memory credit (Learning or Challenge).
4. A memory star already earned stays earned. Pass and goal-tempo stars are unchanged. Section loops still never earn stars.
5. **Tell the player.** When From memory is on and today == `masteryDay`, the requirement line (`StarRequirement`) says "From memory: from tomorrow. Today it is practice." After such a run the result card shows the same sentence instead of a memory counter. Czech: "Zpaměti: od zítřka. Dnes je to jen cvičení."
6. "Today" comes from one injectable clock/calendar so tests can set the date. Ticket 98 reuses it.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/Persistence/Persistence.swift` (`LessonProgress`, `merging`, `recordResult`, `recordPass`), `SmackAPad/Sources/UI/PracticeSession.swift` (memory qualification in the star evaluation), `SmackAPad/Sources/UI/StarStreak.swift`, `SmackAPad/Sources/UI/StarRequirement.swift`, `SmackAPad/Resources/en.lproj/Localizable.strings`, `SmackAPad/Resources/cs.lproj/Localizable.strings`.

## Tasks

1. Use the tdd skill (star rule). Pure function: "may this run earn memory credit?" from `masteryDay`, today and the run result.
2. Persist `masteryDay`; decode old files; merge keeps the earlier day.
3. Requirement and result texts in `en` and `cs`.
4. Unit tests (only these): same day → no credit; next day → credit; old record without a day → credit; star 2 earned in the current run → no credit; merge keeps the earlier day.

## Acceptance criteria

- [ ] Earning star 2 and then playing From memory the same day never gives star 3, and the screen says why.
- [ ] The next day the same run gives memory credit as before.
- [ ] Old progress files load; already earned memory stars stay.
- [ ] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: earn star 2, try From memory, see "from tomorrow"; the next day earn star 3.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: small, but it changes a star rule and the progress file; the tests must pin it down.

## Done rule

Run before ticket 98. Stop after successful build and tests; do not commit. Jakub tests on iPad, Claude commits afterwards.
