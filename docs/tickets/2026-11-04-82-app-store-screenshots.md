# 82 — App Store screenshots (13" iPad, EN + CS) via UI test and demo state

Status: parked (App Store release track, not scheduled; run when the UI is frozen for 1.0). Source: Claude's pre-release audit, 2026-11-04.

## Why

App Store Connect requires at least one screenshot for **13-inch iPad** (2064 × 2752 portrait or 2752 × 2064 landscape; 2048 × 2732 also accepted; PNG/JPEG without alpha, max 10). Taking them by hand in both languages after every UI change is slow; a UI test makes them repeatable.

## Rule

1. Debug-only launch argument `-ScreenshotDemo YES` that loads a fixed demo state in memory (some lessons with 1–3 stars, Full unlocked via the local StoreKit config or a debug override, a chosen lesson opened) and **never writes** to the real `progress.json`. Must be under `#if DEBUG`.
2. UI test target (or a separate test plan) `ScreenshotTests` that, for `en` and `cs`, captures in this order:
   1. Home screen
   2. Practice screen during a run (scrolling band, hits coloured)
   3. Practice screen, static view
   4. Result card after a run with a star
   5. Library (Path view with stars and progress)
   6. Touch pads in portrait (no controller needed)
   7. Controller / calibration hub
   8. Purchase sheet is **not** captured.
3. Run on simulator "iPad Pro 13-inch (M5)" (or newest 13" available), light mode; save PNGs to `docs/store/screenshots/<lang>/NN-name.png` and verify pixel size + no alpha channel (strip alpha if needed with `sips`).
4. Write `docs/store/screenshots/README.md` with the one command to regenerate.

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/App/SmackAPadApp.swift`, `SmackAPad/Sources/Persistence/Persistence.swift`, `SmackAPad/Sources/Store/StoreManager.swift`, `SmackAPad/Sources/UI/ContentView.swift`, existing `SmackAPadTests`.

## Acceptance criteria

- [ ] 7 PNGs per language, correct size, no alpha.
- [ ] Demo state never touches real progress (test: run demo, then normal launch, progress unchanged).
- [ ] Release build contains no demo code.
- [ ] **Jakub** picks the final 5–8 and their order.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high** (needs to run the simulator and UI tests). Fallback: Gemini 3.8 Pro, high.

## Done rule

Do not commit. Jakub reviews images, Claude commits afterwards.
