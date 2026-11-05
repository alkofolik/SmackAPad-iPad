# 94 — One shape language: same corners and same edge everywhere

Status: ready. Source: Jakub, 2026-11-05 (agreed with Claude's review): the app mixes rounded tiles without outline, square buttons with a black outline and a strongly rounded pattern band. It should look like one system.

## Rule

- Direction (matches ticket 91): **square corners** for all chrome: Home tiles, buttons, panels, banners, result card, Library cards, the orange pattern band.
- **Exceptions that keep their radius**: the pad shapes and cells drawn inside the pattern and the pad map, and the logo.
- One edge style: tiles and buttons use the same border (colour and width) tokens already in `Theme.Size` / hairline; no element has a border that another equivalent element lacks.
- Remove stray one-off radii: use only the radius/border tokens in `Theme.swift`. If a token is no longer used after the change, delete it.
- If a case is unclear, leave it as it is and list it in the report (max 5 lines).

## Files to read

`AGENTS.md`, this ticket, `SmackAPad/Sources/UI/Theme.swift`; for the places to change only the lines found by searching `cornerRadius`, `RoundedRectangle` and `Theme.Radius` in `SmackAPad/Sources/UI/`.

## Acceptance criteria

- [ ] No rounded corners on chrome in Home, Library, Practice, Settings, popovers.
- [ ] Tiles and buttons share one border style.
- [ ] Light and dark; portrait and landscape.
- [ ] Build passes; do not run tests.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, medium. Run **after 91 and 92** (same files).

## Done rule

Stop after successful build; do not commit. Jakub tests on iPad, Claude commits afterwards.
