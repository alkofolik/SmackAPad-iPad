# 66 — Practice: run ruler on the band, lap vault and star moment (proposal B of ticket 64)

Status: ready. Source: Jakub, 2026-11-04, chose proposal B from `docs/design/2026-11-04-practice-run-feedback/` (open `proposal-b.html` and the README sections on B). Run after ticket 63 (both touch the result area of the practice screen). The previews are the visual reference; this ticket is the rule.

## Goal

Replace the small texts "2/4" (`session.repetitionProgress`) and "1 / 3" (`session.starRunProgress`) in the practice header with three text-free indicators, and announce earned stars without interrupting the lesson. Do not change scoring, star thresholds, run length, tempo steps or the existing result flow of stars 2 and 3.

## 1. Run ruler on the top rim of the pattern band

- A thin ruler (8 pt high) along the top edge of the orange band, spanning the band width, **inside the band's frame**, never over notes, hit cells or the playhead.
- Divided into **one sector per bar of the current run** (`bars = repeatsPerRun × lesson.bars`, about four; do not hard-code 4). A light track (white on the orange band, ink in dark appearance, whichever has the better contrast; check both) fills along with the playhead across the run, so the filled part is the elapsed part.
- The **last sector** has a notched/bevelled tooth on its leading edge (a clear shape, black-and-white contrast) that **lights up (brighter fill, no flashing) during the last beat of the second-to-last bar**, so the player is warned before the final bar starts. Calm: one steady change, no pulsing loop.
- Shown only while a scored run is running (`running`, not listen mode, not count-in); in section-loop mode it spans the loop. Hidden otherwise.
- VoiceOver: one element, label "Run progress", value "bar %lld of %lld" (the text you removed).

## 2. Lap vault in the instrument row (replaces "1 / 3" text)

- A compact row of **slots** where the text was, one slot per run needed for the star being worked on (`starRunProgress.required`; 1 slot when only one run is needed). Filled slots = `starRunProgress.count`. Slot style: pad-like squares from `Theme`, radius `Theme.Radius.control`, size at least 24 pt.
- **Learning mode** (`PracticeMode.learning`): a counted run fills a slot with a solid plate that is never taken away. A run that did not count leaves the slot unchanged and shows a quiet **notch mark** (a short hairline tick above the next free slot for about 1.2 s) so the player knows that run was not credited. *(Jakub has not answered this open question of the README; this is the default, easy to remove later.)*
- **Challenge mode**: plates are filled in a row; a run that breaks the chain makes the filled plates spring back to empty in one short motion (0.25 s).
- Small verdict flag next to the slots, no text: for about 1.2 s after each run, a filled flag for "run passed" or an outlined flag for "run did not pass". Palette: ink / orange / hairline; `markCorrect` and `markWrong` only if the contrast on the instrument row needs it.
- Label under the slots is the star being worked on as a small mark (1, 2 or 3 filled star outlines), not words. VoiceOver: label "Consecutive passes for %@", value "%lld of %lld" (as today).
- Nothing changes size or position when slots fill; the layout stays stable.

## 3. Star moment while the lesson runs

- When a **fresh star is earned and the lesson continues** (mainly star 1; `StarAward.shouldStop == false`): at the next downbeat the last slot seals, a **narrow light beam runs once along the ruler** (left to right, about 20 % of the width, 0.45 s), then the star indicator pulses once (scale 1.15 → 1.0). Total at most **0.7 s**. The run, metronome and playhead are not touched; nothing covers the notes; nothing shifts.
- For stars 2 and 3 (the lesson stops) keep the existing `StarBurst` flow unchanged; the vault slots seal the same way just before it.
- **Reduce Motion**: no beam, no scale; the slot and star simply light up with a 0.2 s opacity change.
- VoiceOver announces once: "Star %lld earned" (cs: "Získána %lld. hvězda").
- Ticket 63 may show "New badge" in the result area; if both happen after one run, the star moment plays first, the badge line stays as is.

## Removal and layout

- Remove the two Text views in the practice header (`repetitionProgress`, `starRunProgress`) and keep the properties only if still used (e.g. for accessibility values); delete dead code you leave behind.
- Landscape and portrait (the portrait layout of `docs/design/2026-11-03-portrait-practice-layout.md`, including the touch deck) must keep every existing element visible; if the vault does not fit next to the tempo controls in portrait, put it in the same row as the tempo banner and say so in the report.
- Colours and sizes from `Theme.swift`; add tokens there only if truly needed.

## Files to read

`AGENTS.md`, this ticket, `docs/design/2026-11-04-practice-run-feedback/README.md` and `proposal-b.html` (look and timing only; do not copy code), `SmackAPad/Sources/UI/PracticeScreen.swift` (header, instrument row), `SmackAPad/Sources/UI/PracticeSession.swift` (`repetitionProgress`, `currentRepetition`, `repeatsPerRun`, `starRunProgress`, `starEvent`, `stopAfterStar`), `SmackAPad/Sources/UI/PatternField.swift`, `SmackAPad/Sources/UI/PracticeInstruments.swift`, `SmackAPad/Sources/UI/StarAward.swift`, `SmackAPad/Sources/UI/StarBurst.swift`, `SmackAPad/Sources/UI/StarStreak.swift`, `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] No "2/4" or "1 / 3" text remains; the ruler and the vault show the same information without text.
- [ ] The ruler fills with the playhead across the whole run; the last-sector tooth lights during the last beat of the second-to-last bar; works for 1-, 2-, 3- and 4-bar lessons (run lengths from ticket 59) and in a section loop.
- [ ] Learning: credited runs stay filled, uncredited run shows the notch. Challenge: a broken chain resets the plates.
- [ ] Earning star 1 mid-lesson plays the ≤ 0.7 s moment; the next run starts on time; nothing is covered or moved.
- [ ] Reduce Motion, VoiceOver values, cs and en strings, light and dark, landscape and portrait.
- [ ] Build passes; do not run tests (see AGENTS.md).
- [ ] **iPad test (Jakub)**: play an Intro lesson (3 runs per star) in Learning and Challenge with a deliberately bad run; earn star 1 in a lesson that continues.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high** thinking: the most important screen, tight timing coupling with the playhead, and a layout shared with portrait. If the ruler drifts from the playhead or the layout breaks after one fix, hand over to **Codex GPT-6.1 Sol, high**.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
