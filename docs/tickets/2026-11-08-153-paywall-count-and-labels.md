# 153 — Paywall: show what the player actually buys, and fix label leaks

Status: ready-for-agent. Blocked by: none. Source: AI panel round 1 (`docs/reviews/ai-panel/results/synthesis.md`, items 10 and 20; `round1-claude.md` R1-08, `round1-gemini.md` R2-04); `docs/2026-11-08-ai-panel-action-plan.md`, Batch 2. Approved by Jakub 2026-11-08.

## Goal

The purchase sheet says "587 lessons", but 58 of them are free. The player buys **529**. Three reviewers saw this as misleading. Fix the number, tell the player in one short line what the purchase contains, and remove two language leaks.

## Facts checked in the code (2026-11-08)

- `PurchaseSheet.lessonCount` (`SmackAPad/Sources/UI/PurchasesView.swift`) counts lessons with access `free` or `full` when `access == "full"`. Real data: free = 58 (intro 24, core 31, electronic 3), full = 529 (core 508, genre extensions 12, electronic 9), total 587.
- The purchase messages ("Purchase failed…", "Purchases restored" and so on) already have English and Czech entries in both `Localizable.strings` and the view translates them through `settings.localized`. A reviewer still reported them as English-only, so verify before changing anything.
- "Síť Session 1" is the name of the CoreMIDI network session, supplied by iPadOS in the system language (`MIDIInput.swift`, `kMIDIPropertyDisplayName`). The app shows it unchanged.
- Product names and descriptions are translated in App Store Connect, not in the app. Out of scope here.

## Rules

1. The "Full unlock" sheet shows the number of lessons that the purchase unlocks (lessons with access `full`), counted from the data, never typed by hand. A pack sheet keeps counting its own lessons.
2. Under that number, one short line saying what the purchase contains, built from the data (for example how many Path stages, genres and techniques the unlocked lessons cover). Do not hand-type numbers or names into the strings. If this needs more than one short line, stop and report.
3. Find which purchase messages are really not shown in the app language (check every place that assigns `StoreManager.message` and every `localizedDescription` that reaches the screen). Fix only those. Do not change entitlement, verification, restore or transaction logic.
4. Show the CoreMIDI network session name in the app language: when the endpoint is the system network session, display "Network session N" / the Czech equivalent from the app's strings, not the system-localized name. Other device names stay as they are.
5. English and Czech strings for everything new. No new screens.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/PurchasesView.swift`, `SmackAPad/Sources/Store/StoreManager.swift` (message sites only), `SmackAPad/Sources/MIDI/MIDIInput.swift` (endpoint display names), the Settings view that lists MIDI sources, both `Localizable.strings`.

## Tests

- The unlocked-lesson count for "full" equals the number of lessons with access `full` in the catalogue (computed, not a literal), and is smaller than the total catalogue count.
- The pack count still equals the lessons with that pack's access value.

## Acceptance criteria

- [ ] The Full unlock sheet shows 529 (computed), in English and Czech.
- [ ] The sheet has one short line on what is included, derived from the data.
- [ ] Every purchase message is shown in the app language; the final report lists which ones were not before.
- [ ] The network session name follows the app language.
- [ ] No change to purchase, entitlement or restore logic.
- [ ] The full test suite passes before commit (AGENTS.md).
- [ ] **iPad check (Jakub, separate):** English and Czech; free and unlocked state; the sheet from Settings and from a locked lesson; Settings → MIDI sources.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **medium**. Fallback: Gemini 3.8 Flash, high.
- **Reasoning**: small, well-bounded change in one view plus a data-derived count; the care goes into not touching purchase logic.

## Done rule

Stop when the acceptance criteria are met and the full test suite passes. Commit (AGENTS.md); Jakub pushes.
