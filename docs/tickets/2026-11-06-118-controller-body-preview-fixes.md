# 118 — Controller body preview: swap textures, fix the layout (preview only, no app code)

Status: ready-for-agent. Depends on: 117 (same folder, same file). Source: Jakub, 2026-11-06, after looking at `docs/design/2026-11-06-home-controller-body/index.html` (two screenshots, landscape and portrait).

## What is wrong (seen on the screenshots)

1. **Textures are the wrong way round.** Now: the body has grain and the plate under the pads has fine ribbing. Jakub wants the **opposite**: the **body/background is ribbed (grooved)** and the **plate under the pads is smooth**.
2. **Nothing is centred; the layout is broken.**
   - The plate is **smaller than the pad grid**: the pads stick out past the plate on the right and bottom, the plate is shifted to the left/up, and the bottom screws are hidden under the pads.
   - The pad grid, the plate and the faders do not share one centre line.
   - In landscape the left and right fader groups are not symmetric with each other.
3. **The title "SMACK-A-PAD" overlaps the plate and the pads.** It must sit in its own free space and touch nothing.
4. **Portrait is broken:** the controller is taller than the viewport and cut off at the top, the plate is off-centre, the faders lie under and behind the bottom pads, and the page scrolls with the controller half outside.
5. The hero pad subtitle shows "2 cvičení · pak nová l…" with an ellipsis. Ticket 116 forbids cut text on Home pads: wrap it or shorten the content at a word boundary. Also the small pad number "01" on the orange pad is hardly visible; raise its contrast.

## What to do

1. **Textures**: body = ribbed/grooved surface (fine parallel grooves, like moulded plastic ribbing; direction and depth subtle so the faders and the title stay readable), keep a light speckle only if it helps. Plate = smooth (satin or brushed metal option stays, but "brushed" must be very fine and uniform, not ribbed). Update the switches: "Texture of body" (off / subtle / strong) now controls the ribbing; keep plate material switch.
2. **Layout as one centred system**, computed from the pad grid size, not guessed:
   - plate = pad grid + equal padding on all four sides (padding ≥ the screw size + 8 px), so the four screws are always visible in the plate corners and no pad touches or crosses the plate edge;
   - plate centred horizontally and vertically in the controller body; the pad grid centred in the plate;
   - **title in its own band** above the plate (or engraved on the body above it) with clear space on all sides; never over the plate;
   - faders: **landscape** = two on the left and two on the right in the free side space, mirrored, vertically centred on the plate; **portrait** = one row of faders **below** the plate, horizontally centred, fully inside the body, not behind pads;
   - equal outer margins on all sides.
3. **Portrait and any size**: the whole controller fits the viewport without scrolling (scale the preview as one unit, keep aspect). Check 834×1194 (iPad portrait), 1194×834 (landscape) and one smaller size (for example 744×1133). If the free space is too small for faders in portrait, reduce their number or length rather than overlapping.
4. Fix the small items from point 5 above. Everything else from ticket 117 stays.
5. Add a **"show guides"** switch that draws the centre lines, the plate padding and the safe margins, so Jakub can see the layout is centred. In the README list the layout rules as numbers (plate padding, margins, fader positions per orientation) so the later SwiftUI ticket can copy them.

## Rules

- Preview only, same folder `docs/design/2026-11-06-home-controller-body/`. No app code, assets, project settings or `Localizable.strings`.
- Self-contained and offline. Update the Czech `README.md` (what changed, layout numbers, build recipe per layer).
- design-taste-frontend: read its rules only; never run its scripts or browser steps (AGENTS.md).

## Files to read

`AGENTS.md`, this ticket, ticket 117 and 116, `docs/design/2026-11-06-home-controller-body/index.html` and `README.md`.

## Acceptance criteria

- [ ] Body ribbed, plate smooth, in light and dark.
- [ ] Plate fully contains the pads with equal padding; four screws visible; everything centred (verified with the guides switch).
- [ ] Title never touches or overlaps anything.
- [ ] Portrait fits the viewport, nothing overlaps or is cut off, at 834×1194, 1194×834 and 744×1133.
- [ ] No "…" on pad text; pad numbers readable on all pads.
- [ ] README updated with the layout numbers.

## Agent assignment

- **Agent**: Gemini 3.8 Flash, **high**. Fallback: Codex GPT-6.1 Sol, high.
- **Reasoning**: layout arithmetic and CSS material work; high thinking so that sizes are derived from one set of variables instead of patched by eye.

## Done rule

Stop when the files are written. Commit (AGENTS.md); Jakub opens the preview and decides.
