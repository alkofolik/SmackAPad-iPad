# 131 — Proposal: one button system for the whole app (HTML previews, no code)

Status: ready-for-human. Type: design proposal, **no Swift code**. Source: Jakub, 2026-11-07: "go through all the buttons; after the last graphic change most are misaligned and do not look good; this needs to be designed."

## Goal

Jakub wants the buttons to look right and consistent with the Home controller / "Klidný satén" skin. Ticket 130 fixes taps and geometry; this ticket proposes the **look and the rules**. Implementation is a later ticket, only after Jakub chooses.

## Steps

1. **Inventory** (read-only): list every distinct button kind in `SmackAPad/Sources/UI/` (Home/back in toolbar, primary action, secondary action, icon button, segmented/selected key, filter chip, row button, destructive, disabled). For each: screen, current style, size, and what looks wrong. Put it in a table in the proposal README. Use simulator screenshots of the current state (iPad Pro 11″, landscape + portrait) as "before".
2. **Proposal**: at most **two variants** (A, B) of one button system, as HTML previews in `docs/design/2026-11-07-button-system/` (open offline; same approach as tickets 111/114/117). Each variant shows all kinds above in rest, pressed, selected, disabled, light and dark, on the real screen backgrounds. Palette of ticket 92 and the skin tokens of ticket 126; orange stays the primary colour.
3. **Rules** each variant must state: min touch size 44 pt, label/padding inside the pad, one corner radius, where the light bar is used, pressed motion, Reduce Motion behaviour, how a toolbar button differs from an in-page button, how a lesson row differs from a button.
4. **Do not change layout** of screens (same rule as 129). Show only the buttons.

## Files to read

`AGENTS.md`, this ticket, tickets 126 and 130, `docs/design/2026-11-06-app-visual-unity/README.md`, `SmackAPad/Sources/UI/Components.swift` (styles), `Theme.swift` (`Theme.Skin`). design-taste-frontend: read its rules only.

## Acceptance criteria

- [x] Inventory table of all button kinds with screenshots.
- [x] Two variants as HTML previews, all states, light + dark.
- [x] Rules page per variant (see step 3).
- [x] No Swift changes. Report lists open questions for Jakub (max 3).

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: design exploration, no hard logic.

## Done rule

Stop after commit. Jakub chooses a variant; the implementation ticket is written afterwards.

## Proposal notes — 2026-11-07

- Performed a complete read-only audit of all button usages in `SmackAPad/Sources/UI/`, categorized into 9 distinct button kinds.
- Captured high-resolution simulator screenshots (iPad Pro 11″, landscape and portrait, light and dark) of all relevant screens in `docs/design/2026-11-07-button-system/screenshots/`.
- Designed two cohesive button system variants:
  - **Variant A ("Haptický hardware")**: Akai MPC style, 8 pt corner radius, tactile bevels, recessed wells, orange LED breathing light bar, white pad flash.
  - **Variant B ("Akustický minimalismus")**: Braun / studio console style, 6 pt corner radius, crisp 1 px hairline borders, flat satin finishes, instantaneous mechanical color darkening (no flash).
- Delivered interactive offline HTML preview application in `docs/design/2026-11-07-button-system/index.html` with real screen simulations, side-by-side comparison, Web Audio haptic click feedback, and keyboard shortcuts (`L`, `V`, `M`).
- Created dedicated rules documents (`rules-variant-a.html`, `rules-variant-b.html`, and `README.md`).
- Zero Swift code changed. Ready for Jakub's decision.
