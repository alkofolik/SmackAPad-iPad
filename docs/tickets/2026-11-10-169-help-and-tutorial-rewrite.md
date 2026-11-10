# 169 — Rewrite help and first-launch tutorial

Status: ready-for-agent. Approved by Jakub on 2026-11-10 (all five questions in the T163 report answered yes; the pass-mark question is handled in T170).

## Goal

Make help and the tutorial easy to understand and cover the app's real features, following the [T163 review](../design/2026-11-10-163-tutorial-review.md), section 5 (new structure, draft CZ + EN copy, illustrations) and the inaccuracies in section 4.

## Decisions

1. Help cards may have 2–4 short lines (not one sentence). Still no new text in the main UI; help stays behind the (?) in Practice and the **How it works** rows in Home and Settings.
2. Tutorial: 5 cards as proposed in the report (playing a lesson, hit colours, the three modes incl. After me, stars and tempo, where to go next). Keep all T162 rules for when it appears, Skip on every card, the seen flag and **Watch tutorial**.
3. Help opens on a topic list (12 topics from the report). Opened from Practice it opens straight on "The lesson screen" topic, with a way back to the list.
4. Rename the 3rd star app-wide from "From memory" to a review name (EN "Review", CZ "Opakování"; adjust if a clearer pair fits the existing labels). Keep "From memory" as the name of the practice option only. Update `HelpIllustration.swift`, `StarRequirement.swift` (also drop "in Training": since T158 reviews from Library and Home count), Library star rules and any other place.
5. Illustrations get drawn-in labels/arrows; the animation loops calmly while the card is visible (stills with Reduce Motion / VoiceOver as in T162). The tempo picture shows the real control (tap the tempo field → −5/−1/+1/+5, Starting tempo).
6. Use the app's own words in Czech ("pattern", the Settings label "Nápověda zpaměti postupně mizí", etc.). All copy in English and Czech; the report's drafts are a starting point, fix anything that contradicts the code.
7. Fix the duplicate Czech key `"Start"` (cs `Localizable.strings` lines 434 "Začít" and 798 "Začátek"): the START button must read "Začít"; give the other use its own key.
8. Explain only shipped behaviour. If T170 (80 % pass mark) lands first, use 80 %; otherwise read the threshold from code, do not hard-code a number in copy that can drift.

## Tests

- Every help/tutorial key has a nonempty value in both bundles (checked per bundle).
- No duplicate keys in either `Localizable.strings` (add a test that parses both files).
- Tutorial policy tests from T162 still pass with 5 cards.

## Acceptance criteria

- [ ] 5-card tutorial, topic-list help, Practice opens on "The lesson screen".
- [ ] No statement in help contradicts the app (check against T163 section 4).
- [ ] 3rd star is called the review star everywhere; From memory remains only the practice option.
- [ ] START reads "Začít" in Czech.

### Manual iPad checks for Jakub

Fresh profile (T160 debug scenario): go through the tutorial, then open help from Home, Settings and a lesson. Read each topic in Czech and English. Check the 3rd-star name in Library and in the lesson.

## Files to read

`AGENTS.md`, the T163 report, T159 and T162 tickets, `HelpDeck.swift`, `HelpIllustration.swift`, `TutorialLaunch.swift`, `StarRequirement.swift`, `StarStreak.swift`, `LibraryScreen.swift`, `IntroScreen.swift`, `PracticeScreen.swift`, both `Localizable.strings`, `SmackAPadTests/FirstRunAndLegibilityTests.swift`.

## Agent assignment

Codex GPT-6.1 Sol, high. Lots of copy that must match code behaviour exactly.

## Done rule

Build, full `SmackAPad` test plan per `AGENTS.md`, commit, stop for Jakub's iPad check.
