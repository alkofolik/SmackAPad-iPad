# 125 — Proposal: whole app looks like one piece with the Home screen (HTML previews, no code)

Status: resolved (Jakub chose variant B "Klidný satén"; layout of the preview rejected — see 126). Type: design proposal, **no Swift code**. Source: Jakub, 2026-11-06: "Make the rest of the app match the Home screen, which I want to keep — colour palette, graphics, animation. Keep the layouts and the orange colour of the pattern band, but every window should fit together visually, nothing should stand out, everything should form one whole."

## Goal

Home (tickets 112, 113, 115, 116, 119) is the reference and **does not change**: ribbed controller body, smooth brushed plate with screws, pads with bevel and orange light bar, real wordmark, pad zoom and boot wave. Every other screen should look like it belongs to the same instrument. Today they use a plain background and flat bordered boxes (e.g. Practice: black-outlined buttons, flat BPM box, flat pad-layout grid, plain "Začít"/"Znovu" buttons), which looks like a different app.

## Fixed (do not propose changes)

- **Layout** of every screen: same elements, same positions, same order.
- **Orange pattern band** in Practice (colour and look of the band itself, notes, beat numbers).
- Home screen as built.
- Practice drawing, playhead, timing, scoring, audio.

## What to propose

One **design language** taken from Home and applied to every screen, as a small set of shared building blocks (later `Theme` tokens and components):

1. **Surfaces**: which screens get the ribbed body as background (all, or a calmer/finer variant for dense screens such as Practice and Library so it does not compete with content); where the smooth plate is used (panels, cards, sheets, the area around the orange band); screws only where it makes sense (large plates), never on small elements.
2. **Controls** in the pad material of Home (bevel, 8 pt radius, press with scale + flash, Reduce Motion variant): primary button ("Začít"), secondary ("Znovu", "Knihovna"), segmented mode switch (Poslech / Hra / Po mně) as a row of hardware keys with the orange light bar on the selected one, icon buttons in the toolbar, toggles, the small pad-layout grid (mini pads), steppers.
3. **Displays**: BPM box and other numbers as an instrument display (inset screen look, numeric roll from ticket 27), star/goal lines, badges, progress.
4. **Lists and cards**: Library lesson rows/cards, Training list, Badges grid, Settings rows, About, Purchases, Controller setup and Calibration, Intro, banners (badge, tempo-up, star burst), feedback window, alerts/sheets.
5. **Text**: same fonts and weights as Home (Theme), engraved style only for small labels, never for body text.
6. **Motion**: the same tokens everywhere (`padPress`, `padFlash`, `padZoom`, `cardStep`, boot-like stagger for list appearance, light-bar breathing for "attention" states). List which animation every screen uses for appear, change and leave; nothing gets its own new style.
7. **Light and dark**: both, palette of ticket 92 only, AA contrast (table like in ticket 117/118 README).

## Deliverable

Folder `docs/design/2026-11-06-app-visual-unity/` with:

- `index.html`: one page that shows, **side by side with Home**, every non-Home screen in the new language, using the real current layouts (take them from the Swift files and Jakub's screenshots in `docs/design` if present), landscape and portrait, keys L = light/dark, O = orientation, M = play the motion (press, mode switch, list appear, pad zoom). At minimum: Practice (Play and After me), Library, Training, Today session, Badges, Settings, About, Purchases, Controller setup, Calibration, Intro, banners.
- Where a choice is unclear (e.g. ribbed vs. calm background on Practice), show **2 variants** next to each other, labelled A / B, so Jakub just picks.
- `README.md` (Czech for Jakub, short): the building blocks with exact numbers (radius, bevel, shadows, ribbing pitch of each surface variant, colours as palette names, motion tokens), a table "screen → which blocks it uses", the contrast table, and a list of anything that would need a layout change (should be none; if something truly cannot fit without one, list it as a question, do not draw it).
- Nothing in `SmackAPad/` changes.

## Rules

- Copy the real look of Home from the Swift code (`HomeScreen.swift`, `Theme.swift`) and the preview `docs/design/2026-11-06-home-controller-body/`, so the previews match what is on the iPad.
- Calm over decoration: dense screens must stay readable; the orange band stays the visual centre of Practice.
- No new user-facing text (previews use the real Czech strings).
- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).

## Files to read

`AGENTS.md`, this ticket, tickets 27, 92, 94, 112, 113, 119, `docs/design/2026-11-06-home-controller-body/` (README + index.html), `docs/design/2026-11-06-home-pads-and-motion/README.md`, `SmackAPad/Sources/UI/Theme.swift`, `HomeScreen.swift`, and for layouts only: `PracticeScreen.swift`, `PracticeComponents.swift`, `LibraryScreen.swift`, `TrainingScreen.swift`, `TodaySessionScreen.swift`, `BadgesScreen.swift`, `SettingsView.swift`, `AboutScreen.swift`, `PurchasesView.swift`, `ControllerSetupView.swift`, `CalibrationView.swift`, `IntroScreen.swift`, `Components.swift`.

## Acceptance criteria

- [ ] `index.html` shows every listed screen next to Home, light/dark, both orientations, with motion demo.
- [ ] Layouts and the orange band unchanged; Home unchanged.
- [ ] Open choices shown as A/B variants.
- [ ] README with building blocks, screen table, contrast table.
- [ ] No Swift changes.

## Next step

After Jakub picks the variants, write implementation tickets: 1) shared tokens and components in `Theme`/`Components`, 2) Practice, 3) Library + Training + Today, 4) the remaining screens. Tickets 122 and 123 (Practice header, After me jump) should be done before the Practice implementation.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: large but straightforward HTML/CSS preview work with a fixed reference (Home); same kind as tickets 111, 114, 117.

## Done rule

Stop when the preview folder is complete. Commit (AGENTS.md); Jakub pushes and checks the preview in a browser.
