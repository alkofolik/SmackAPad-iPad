# Cut Tape band proposals v2 — working draft

Status: the Detail correction is applied. The complete proposal package is not yet verified or delivered. Application sources were read only; no application implementation is authorized by this document.

## Detail correction, 2026-11-02

The user accepted the general direction and requested a larger, fully black or white Detail icon. The shared result panel in `2026-11-02-band-proposals-v2/index.html` now uses the actual SF Symbol `chart.xyaxis.line`, Regular, in a **44 × 44 pt image frame**, increased from 24 × 24 pt. Its transparent touch target is **56 × 56 pt**. The symbol is solid black on the light surface and solid white on the dark surface, without reduced opacity. The accessible name remains `Detail`. Both variants use this same result panel.

The light HTML preview was opened in Chrome and visually inspected. The full `Poslední běh` label, percentage, stars and Detail icon rendered. Chrome reported a successful 1316 × 915 PNG download; that downloaded file has not been retrieved into this project or inspected. Dark-mode verification and the complete PNG package remain pending. Automatic approval review rejected a new local export server because it considered further work contrary to the project's stop-after-two-failures rule. No replacement server was started after that rejection.

## Source findings used by this draft

- `PatternField.swift`: used pad indices are deduplicated, then filtered through `PadVoice.rowOrder`. Hands and abbreviations do not merge pads. Two physical HH pads therefore produce two rows.
- The referenced `PadVoice` declaration in `PracticeComponents.swift` defines the order `[8, 11, 7, 2, 3, 4, 5, 6, 9, 10, 13, 14, 0, 1, 12, 15]`. This small declaration was read to resolve the dependency; the file was not edited.
- Scrolling mode divides the available lane area equally by the used pad count. Its marker is fixed at one third of the inner canvas width. Tape coordinates move past it. Static mode also divides each bar's lane area equally.
- `PracticeScreen.swift` gives the pattern the remaining flexible height. It does not impose a special one-, two-, three- or four-pad arrangement. The footer changes below a width of 1000 pt.
- The bottom position indicator is already conditional on `lesson.bars > 1`. Right-edge feedback means rushing; left-edge feedback means dragging.

## Proposed directions, pending complete visual verification

**A / Continuous tape:** one rounded orange field, subtle row boundaries and white hit tiles. Recommended direction: the continuous field keeps simultaneous hits visually aligned and adds the least structure as pad count increases.

**B / Cut strips:** a common rounded band containing individually rounded orange lanes with small gaps. Time coordinates, marker position and pad ordering are identical to A. Its separation is stronger, at the cost of more vertical structure in dense lessons.

The HTML contains selectable light/dark appearances, one through four rows, a five-pad example with distinct HH pads, and all sixteen pads. Its state atlas contains idle, running, count-in, one/two/three-star results and a star-award frame for one, two and four rows, plus a three-row density example. Scores and three/four-pad rhythms are illustrative visual data, not new lesson content or changed star rules.

The whole package requires visual review and browser PNG export before it can be marked complete. No app build or app tests were run for this design-only task.
