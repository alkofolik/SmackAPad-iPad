# 133 — Implement unified button system (Variant B style + full toolbar pads + flash)

Status: ready-for-agent. Type: implementation. Depends on: 130, 131. Source: Jakub, 2026-11-07: selected **Variant B** (studio precision, 6 pt radius, clean 1px hairline) with **full tactile pads in toolbar** and **pad flash feedback (Variant A press)** from ticket 131.

## Goal

Apply the unified button system decided in ticket 131 to `SmackAPad/Sources/UI/Components.swift` and all button call sites across the app. Fix visual misalignment, chunky double-bevels, and clumsy filter chips while preserving all hit-area fixes from ticket 130.

## Design specifications chosen by Jakub (Ticket 131)

1. **Style (Variant B — Studio Precision):**
   - Corner radius: **6 pt** for buttons and controls (replaces 8 pt, establishing a clear hierarchy: 8 pt for Home MPC pads, 6 pt for precision in-app controls, 16 pt for large plates).
   - Surfaces: Flat satin finish with clean 1 px hairline borders (`Theme.hairline`). Remove heavy 3D double-bevels (`SkinBevel`) from buttons.
   - Primary Hero Pad: Orange `#FF6B00` with dark ink text `#1F1D1A`, 1 px crisp edge definition, subtle contact shadow `0 2px 6px rgba(255,107,0,0.25)`.
   - Secondary Pad: Clean surface fill (`#EBE5DA` light / `#2A2824` dark) with 1 px hairline border.
2. **Toolbar buttons (Full tactile pads):**
   - Navigation and toolbar buttons ("Domů", "Zpět", "Knihovna", "Hotovo", "Uložit") remain full tactile pads with 6 pt radius and clean satin surface, min height 44 pt.
3. **Press feedback (Flash + Travel from A):**
   - Tactile compression: `scale(0.97)` + `translateY(1.0pt)`.
   - Light flash: `Theme.Motion.padFlash` (subtle 0.25 white flash decaying over 120 ms).
   - Under Reduce Motion: zero scale, zero offset, zero flash; instant 12% darkening only.
4. **Light bar rules:**
   - 2 pt orange LED light bar is used **strictly** on mechanical mode keys (Poslech / Hra / Po mně) and in Practice note strip.
   - Remove light bar from `FilterChip`. Filter chips become clean 6 pt tags (active state has warm solid background / orange border).
5. **Destructive actions:**
   - Unified warm brick red / terracotta `#C0392B` (light) / `#E74C3C` (dark) for destructive actions (e.g. "Smazat profil", trash icon).
6. **Disabled state:**
   - Inert unpowered matte fill `#D6D0C4` (light) / `#201E1B` (dark) with muted text (35% opacity), no drop shadow, no glowing backlight.
7. **Lesson rows (ListRow / LibraryLessonRow):**
   - Clean structural plate without double blurred shadows inside scroll views.
8. **Hard rule: NO layout changes:**
   - Sizing, frames, margins, and element hierarchy remain identical to ticket 130.

## Files to touch

- `SmackAPad/Sources/UI/Theme.swift` (`Theme.Skin.Pad` tokens: radius 6 pt, bevels, press tokens).
- `SmackAPad/Sources/UI/Components.swift` (`PadControlBody`, `PadPrimaryButtonStyle`, `PadSecondaryButtonStyle`, `PadIconButtonStyle`, `HardwareKeyButtonStyle`, `FilterChip`, `ListRow`).
- Screen files only if needed to align destructive or chip styles (e.g. `LibraryScreen.swift`, `ControllerSetupView.swift`).

## Acceptance criteria

- [ ] All button styles updated in `Components.swift` with 6 pt radius, clean 1px hairline, and flash feedback.
- [ ] Filter chips use clean tag style without bottom LED light bar.
- [ ] Hardware key button style retains bottom light bar with breathing animation.
- [ ] Destructive buttons use unified warm terracotta styling.
- [ ] Disabled buttons show inert unpowered state (not washed-out 45% transparency).
- [ ] Minimum touch size &ge; 44 pt (48 pt default) preserved everywhere from ticket 130.
- [ ] Build succeeds with zero warnings. No extra tests.
- [ ] Visual verification on iPad Pro 11″ simulator in both orientations and light/dark modes.

## Agent assignment

- **Agent**: Codex GPT-6.1 Sol, **high**. Fallback: Gemini 3.8 Flash, high.
- **Reasoning**: Mechanical UI sweep with exact token alignment; builds on ticket 130.

## Done rule

Stop after successful build and simulator verification. Commit (AGENTS.md); Jakub tests on physical iPad.
