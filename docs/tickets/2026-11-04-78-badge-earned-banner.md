# 78 — Practice: short banner when a badge is earned

Status: ready. Blocked by: none (independent of 76, 77; if 77 is already done, use the result card area only for nothing — the banner floats above the layout). Source: Jakub, 2026-11-04: "How does the app announce a new badge? Prepare a ticket: a banner that is shown somewhere for a moment."

## Problem

When a run earns a badge, `PracticeSession.evaluateBadges()` stores it in `earnedBadgesInRun`, but the only consumer is `resultAnnouncement` (VoiceOver text). Sighted players see nothing and find the badge only later in the Badges screen.

## Rule

- When `earnedBadgesInRun` gets a new badge during a run end, show a **badge banner** for about 2.5 s, then fade out. No sheet, no alert, no button; it must never block touch or MIDI input (`allowsHitTesting(false)`).
- Placement: floating overlay at the **top centre of the practice screen**, below the navigation bar, above all other content. Does not move or resize any other element. Same overlay layer as `TempoUpBanner` (see `PracticeScreen.swift` near line 309), but a separate view so both can show at once without overlapping (badge banner sits above tempo banner).
- Content: a badge/medal SF Symbol (or the badge icon already used in `BadgesScreen.swift`), small caption "New badge" / "Nový odznak", and the badge name (localized) in strong font. Several badges earned at once: show **one banner** "N new badges" / "N nových odznaků" (existing strings `New badge: %@`, `Earned %lld new badges`, reuse them), not a queue.
- Style: same family as `TempoUpBanner` (Theme colours, black border, block radius), but a different fill so it is not confused with the tempo banner. Must work in light and dark.
- Motion: slide in from the top + fade (same `Theme.Motion` policy as `TempoUpBanner`); with Reduce Motion only a fade.
- Timing: appear when the run result is known (right after `evaluateBadges()` returns new badges), not at the start of the next run. If the player starts a new run while it is visible, let it finish; do not restart it.
- Tapping nothing. Badge details stay in the Badges screen (tile on Home).
- `earnedBadgesInRun` is reset at run start (`PracticeSession.swift` line ~407): keep that behaviour. Add a separate `badgeBannerEvent` (value with a unique id, like `StarEvent` / `TempoUpEvent`) so the banner shows once per earning and not again when the view redraws.
- Do not show anything for badges awarded silently at app start (`awardSilently` in `SmackAPadApp.swift`).

## VoiceOver

- Post one `UIAccessibility.announcement` with the same text as the banner. Move the existing badge text out of `resultAnnouncement` so it is not read twice.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/TempoUpBanner.swift` (pattern to copy), `SmackAPad/Sources/UI/PracticeSession.swift` (`evaluateBadges`, `badgeSummaryMessage`, `earnedBadgesInRun`, the places that set `starEvent` / `tempoUpEvent`), `SmackAPad/Sources/UI/PracticeScreen.swift` (banner overlay near line 309, `resultAnnouncement` near line 499), `SmackAPad/Sources/UI/BadgesScreen.swift` (icon only), `SmackAPad/Sources/UI/Theme.swift`, both `Localizable.strings`.

## Acceptance criteria

- [ ] Earning a badge shows a banner for about 2.5 s at the top centre, then it fades away.
- [ ] Nothing else moves; pads, MIDI and touch input still work while it is visible.
- [ ] Two badges at once give one banner with the count.
- [ ] No banner for badges awarded silently at launch, and none on a redraw.
- [ ] VoiceOver reads the text once.
- [ ] Landscape and portrait; cs and en; light and dark; Reduce Motion.
- [ ] Build passes; do not run tests.
- [ ] **iPad test (Jakub)**: reset badges, pass the first lesson, watch the banner; then earn two at once if possible.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **medium** thinking. Fallback: **Codex GPT-6.1 Sol, high** if it fails twice.

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
