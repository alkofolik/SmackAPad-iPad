# 98 — Home pad "Training" and spaced review ("Due")

Status: ready-for-agent. Blocked by: 97 (`masteryDay`, injectable "today"). Source: Jakub, 2026-11-05; legacy "Trénink" concept 2026-10-06 §5–6.1 and the legacy lesson from 2026-10-09 (the player could not find how to start a review nor tell whether it counted).

## Goal

Learned lessons come back after a gap so they stay in the hands. One Home pad opens a new **Training** screen. This ticket builds the screen with its first card, **Due**; tickets 100 and 101 add the cards Mix and Play after me. Training only recommends. It never locks a lesson and never removes a star.

## Home screen (Jakub's decision)

1. Pad 3 (top right, today "Settings") becomes **"TRAINING"** / **"TRÉNINK"**. Subtitle: "%lld due" / "%lld na řadě" when reviews are due, otherwise none.
2. Pad 8 (bottom right, today "About") becomes **"SETTINGS"** / **"NASTAVENÍ"** and opens Settings exactly as pad 3 does today. No subtitle.
3. The About popover content (name, version, text) moves unchanged into Settings as the last row "About" / "O aplikaci" (ticket 80 later expands it).
4. Same pad component, sizes and corner/edge styling as today; nothing else on Home changes. Update the grid comments in `gridContent`.

## Review schedule

1. When a lesson first earns star 2, schedule its first review for `masteryDay + 1`. Lessons that had star 2 before this update get their first review **tomorrow** (the first launch after the update), not today.
2. Steps and gaps: step 0 → 1 day, step 1 → 3 days, step 2 → 7 days, step 3 → 21 days. Passing step 3 marks the lesson **settled** ("upevněno"); it is no longer scheduled.
3. **A review run** = one full scored run (not a section loop) **From memory** at ≥ goal tempo on a day ≥ the due day. Pass = score ≥ 80 % (the memory-star threshold, one number for the player to remember).
   - Pass → next step, due = today + gap. If the lesson has no star 3 yet, the same run also earns memory credit as usual (ticket 97 allows it because the day is later).
   - Fail (full run at goal tempo from memory, < 80 %) → one step back (minimum step 0), due tomorrow.
   - Run below goal tempo, or not From memory → does not count; schedule unchanged.
   - One review counts per lesson per day; further runs that day are ordinary practice.
4. Nothing piles up as debt: overdue reviews simply wait; no penalty for lateness.
5. Store per lesson in `LessonProgress` (optional fields; old files decode as "no schedule"): `reviewStep`, `reviewDueDay`, `settled`. `merging` keeps the further-progressed schedule. Stars, unlock rules and Learning credit are untouched.

## Training screen

- Opens from the Home pad as a full screen with the usual back control (same look as Library: `Theme` tokens, ticket 94 shape language, no new colours).
- Card **Due** / **Na řadě**: due lessons, oldest due day first; each row shows title, stars and "Step 2 of 4" / "Krok 2 ze 4". Tap opens the lesson in Practice with **From memory already on** and tempo set to goal tempo.
- Nothing due: "Nothing to review today. Next: %@" / "Dnes nic k opakování. Další: %@" (nearest due day). No lesson with star 2 yet: "Reviews start once a lesson has two stars." / "Opakování začne, až bude mít lekce dvě hvězdy."
- Leave room below the card for Mix and Play after me (tickets 100, 101); no placeholders.

## Clear feedback (required)

- Opened due lesson: Practice status line shows "Review · step 2 of 4 · from memory at %lld BPM, 80 %" / "Opakování · krok 2 ze 4 · zpaměti při %lld BPM, 80 %".
- Result card: pass "Review passed · next in %lld days" / "Opakování splněno · další za %lld dní"; last step "Lesson settled" / "Lekce je upevněná"; fail "Review not passed · again tomorrow" / "Opakování nesplněno · znovu zítra"; not counted "Does not count · play from memory at %lld BPM" / "Nepočítá se · hraj zpaměti při %lld BPM". Czech plural forms via the existing localisation approach.
- Library lesson row: a small settled mark (existing symbol style from ticket 52; no new colour).

## Files to read

`AGENTS.md`, this ticket, ticket 97, `SmackAPad/Sources/Persistence/Persistence.swift`, `SmackAPad/Sources/UI/PracticeSession.swift` (result recording only), `SmackAPad/Sources/UI/HomeScreen.swift`, `SmackAPad/Sources/UI/ContentView.swift` (navigation), `SmackAPad/Sources/UI/LibraryScreen.swift` (row mark only), `SmackAPad/Sources/UI/PracticeScreen.swift` (status line and result card only), `SmackAPad/Sources/UI/SettingsView.swift` (About row), `SmackAPad/Sources/UI/Theme.swift`, `SmackAPad/Resources/en.lproj/Localizable.strings`, `SmackAPad/Resources/cs.lproj/Localizable.strings`.

## Tasks

1. Use the tdd skill for the schedule (pure function: schedule + run result + today → new schedule and the message to show).
2. Persistence fields and migration ("tomorrow" for lessons that already have star 2).
3. Home pads 3 and 8, Training screen with the Due card, About row in Settings.
4. Practice status line, result messages, Library settled mark; texts in `en` and `cs`.
5. Unit tests (only these): pass advances with the right gap for each step; fail steps back and is due tomorrow; below goal tempo / not from memory / not yet due → unchanged; second review the same day ignored; step 3 pass → settled; old file → first review tomorrow.

## Acceptance criteria

- [ ] Home pad 3 reads TRAINING with the due count; pad 8 opens Settings; About is in Settings.
- [ ] A lesson with star 2 appears in Due the next day; tapping it starts From memory at goal tempo.
- [ ] Pass, fail and "does not count" each show their sentence; the schedule moves as specified.
- [ ] Stars, unlocking and Learning credit unchanged; old progress files load.
- [ ] Tests pass, build succeeds.
- [ ] **iPad test (Jakub)**: over several days one pass and one fail; check the Due list and the messages.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: new screen plus a progress-file change; the schedule rules are pure and covered by tests.

## Done rule

Stop after successful build and tests; do not commit. Jakub tests on iPad, Claude commits afterwards.
