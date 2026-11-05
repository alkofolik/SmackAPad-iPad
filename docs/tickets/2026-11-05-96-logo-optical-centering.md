# 96 — Logo: optically centred mark (icon, Home screen, wordmark)

Status: resolved. Source: Jakub, 2026-11-05: the logo feels off-centre; wants it more symmetric everywhere (app icon, Home screen) without redesigning it.

## Problem

In `docs/design/2026-11-03-logo-source/smack-a-pad-icon.svg` (viewBox 100×100) three black pads sit on a 2×2 grid (gaps 8) and the orange pad is moved up-right (57,11 instead of the grid slot 54,18) and tilted 12°. Its rotated corners reach x ≈ 92 and y ≈ 8, while the left edge is at x = 14 and the bottom at y = 90. The whole mark is therefore pushed to the right and up: margins are about 14 left / 8 right and 8 top / 10 bottom.

## Rule

1. **Soften the orange pad**: tilt 12° → **8°**; offset from its grid slot about **+1.5 / −3.5** units (instead of +3 / −7). Keep size 32×32, radius 3, colours `#FF5B1F` / `#111111` / `#F2F0EA`. Keep the three black pads and the 8-unit gaps.
2. **Centre by the real bounds**: compute the bounding box of all four shapes **including the rotated corners of the orange pad**, then translate the whole group so left/right margins are equal and top/bottom margins are equal inside the 100×100 icon.
3. **Apply the same geometry everywhere the mark appears**, from one source of truth:
   - `smack-a-pad-icon.svg`, `app-icon-square.svg`, `render-app-icon.swift`, then regenerate `app-icon-1024.png` and replace the image in `SmackAPad/Assets.xcassets/AppIcon.appiconset` (full-bleed, no alpha, as in ticket 57; verify with `sips`).
   - `HomeLogoMarkView` in `SmackAPad/Sources/UI/HomeScreen.swift` (centre tile on Home). Keep its pop animation and the dark-appearance colours working.
   - The two horizontal logo SVGs in the same folder, if they embed the mark.
4. Do not redesign: same four pads, same orange accent top right.

## Files to read

`AGENTS.md`, this ticket, `docs/design/2026-11-03-logo-source/` (README, the SVGs, `render-app-icon.swift`), `SmackAPad/Sources/UI/HomeScreen.swift` (`HomeLogoMarkView` only), `SmackAPad/Assets.xcassets/AppIcon.appiconset/Contents.json`.

## Acceptance criteria

- [x] Left/right and top/bottom margins of the mark are equal (state the measured numbers in the report).
- [x] Icon PNG: 1024×1024, `hasAlpha: no`.
- [x] Home centre tile shows the same geometry, centred in its tile; pop animation unchanged.
- [x] Build passes; do not run tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium. Run **after 95** (same HomeScreen file).

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
