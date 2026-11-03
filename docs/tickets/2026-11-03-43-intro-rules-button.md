# 43 — Library: collapse the Intro rules behind a button

Status: implemented; build OK; awaiting iPad verification. Source: Jakub, 2026-11-03 (approved).

## Problem

The page "Úvodní cvičení / Intro" in the library opens with a long block "Pravidla úvodní sekce" (pass ≥ 80 %, mastery 0 mistakes, completed 11/25 …). It pushes the lesson list down although the rules are only needed occasionally.

## Goal

The rules are hidden behind a small, clearly tappable control at the top of the Intro page. The lesson list starts directly below the page title.

## Rules

- Replace the block with one compact button: text "Pravidla" / "Rules" with an ⓘ icon, left-aligned under the title, at least 48 pt touch height.
- Tapping it opens the same content in a popover (same style as the lesson info popover in the practice screen), with a Close action. Content and wording of the rules stay unchanged.
- Localise the button label in cs and en (`Localizable.strings`); no other strings change.
- Only the Intro page is affected. No change to colours, typography scale or other library pages.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/LibraryScreen.swift`, `SmackAPad/Sources/UI/IntroScreen.swift`, the lesson-info popover in `PracticeScreen.swift`, `Resources/cs.lproj/Localizable.strings`, `Resources/en.lproj/Localizable.strings`.

## Acceptance criteria

- [ ] The Intro page shows the lesson list without the rules block; the "Pravidla / Rules" button is visible.
- [ ] The popover shows the full rules text and closes properly.
- [ ] Works in Czech and English, light and dark.
- [ ] Build passes; do not run tests (see AGENTS.md).
- [ ] **iPad test (Jakub)**: open Intro in both languages, open and close the rules.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol (Codex app), **low** reasoning — small UI change in one file plus two strings.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
