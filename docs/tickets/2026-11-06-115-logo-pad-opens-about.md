# 115 — The centre logo becomes a pad that opens About

Status: ready-for-agent. Depends on: 112 (pad look), 113 (zoom transitions). Source: Jakub, 2026-11-06: "the middle tile with the logo could work as a button too. Nothing written on it, only the logo, in effect an About button."

## Now

The centre cell of the Home 3×3 grid (`gridContent` in `HomeScreen.swift`) is an empty `Color.clear` placeholder; the logo mark (`HomeLogoMarkView`) and the wordmark are drawn on top of it and are not tappable. About exists only inside Settings (`AboutDetailView`, `private` in `SettingsView.swift`).

## Rules

1. The centre cell is a **pad** like the others (ticket 112 look: radius token, bevel, press, flash), containing **only the logo mark**. No text in the tile. The wordmark "Smack-a-Pad" stays where it is now, outside the cell; do not move it into the tile.
2. The tile should be quieter than the action pads: no orange rim, no light bar, never lit. If a full pad plate behind the three black pads and the orange pad looks too busy, use a flatter plate (same shape and bevel, background tint only). Decide on the real iPad build, say in the report which you chose.
3. Tapping it opens **About**. Reuse `AboutDetailView` (make it non-private, or move it to its own file `AboutScreen.swift`); Settings keeps its About row and shows the same screen. Home presents it like the other Home destinations (same presentation and, after ticket 113, the same pad zoom). It needs a Done/Back control (pattern of `BadgesScreen`).
4. **Launch animation (ticket 46/61) must not change**: the logo still lands in the centre cell at the end; the tile plate fades in after the logo has settled (no plate during the animation). The existing "tap anywhere skips the animation" gesture must keep working and must not open About; the tile becomes tappable only after the animation has finished (`isSettled`).
5. Accessibility: label "About" / "O aplikaci" (strings exist), trait button. The tile is no longer `accessibilityHidden`.
6. MIDI: no controller mapping for this tile (the 8 controller pads stay 1–8 as now).
7. Reduce Motion: press = darker fill only, plate appears with a 0.2 s fade (rules of ticket 112).

## Files to read

`AGENTS.md`, this ticket, tickets 61, 73, 112, 113, `SmackAPad/Sources/UI/HomeScreen.swift` (`HomeLogoMarkView`, `gridContent`, launch sequence, tap gesture), `SmackAPad/Sources/UI/SettingsView.swift` (`AboutDetailView` and its row), `SmackAPad/Sources/UI/BadgesScreen.swift` (toolbar pattern only), `SmackAPad/Sources/UI/Theme.swift`.

## Acceptance criteria

- [ ] Centre tile is a pad with only the logo; tapping it opens About; Done returns to Home.
- [ ] Settings still shows About and opens the same screen.
- [ ] Launch animation unchanged; tile not tappable until it ends; skip-tap does not open About.
- [ ] VoiceOver reads "About".
- [ ] Build succeeds. No new tests.
- [ ] **iPad test (Jakub)**: cold start, tap the logo, light and dark, landscape and portrait.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: small feature, but it sits in the launch-animation layering and gesture code, so high thinking.

## Done rule

Stop after a successful build. Commit (AGENTS.md); Jakub pushes and tests on the iPad.
