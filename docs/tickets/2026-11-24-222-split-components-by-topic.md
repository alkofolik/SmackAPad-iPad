# 222 — Split `Components.swift` by topic

Status: open. Follow-up A2 from ticket 210 (Desloppify baseline 92.6 / 100 on 2026-11-24).

## Goal

Split `SmackAPad/Sources/UI/Components.swift` (1084 lines, 12 unrelated function/view groups) into a small set of focused files by topic, with zero behaviour change.

## Rules

1. Run Code Simplifier on `Components.swift` and the resulting split files only.
2. Group related views/helpers into clear topic files (for example buttons/controls, cards/banners, popovers/sheets, badges/pills), keeping each file focused and under ~350 lines where practical.
3. Add all new files to `SmackAPad.xcodeproj` so the app target builds cleanly.
4. Keep all public/internal symbol names, signatures, styling, and behaviour identical.
5. Re-run the Desloppify objective scan after committing and note the new objective score in this ticket.

## Files to read

`AGENTS.md`, `SmackAPad/Sources/UI/Components.swift`, `SmackAPad.xcodeproj/project.pbxproj`, `docs/tickets/2026-11-21-210-desloppify-baseline-cleanup-plan.md`.

## Tests

Build only (pure structural split with no behaviour change). No new tests.

## Acceptance criteria

- [ ] `Components.swift` is split into focused topic files.
- [ ] All new files are registered in `SmackAPad.xcodeproj`.
- [ ] App builds cleanly without errors.
- [ ] Desloppify objective scan re-run and new score noted.

### Manual iPad checks for Jakub

Quick smoke check across Home, Library, and Settings to confirm shared UI components render identically.

## Agent assignment

Gemini 3.8 Flash, thinking **low**. Fallback: Codex GPT-6.1 Sol, low.

## Done rule

Build, commit, re-run Desloppify scan and record score, then stop for Jakub's iPad check.
