# B9 — Result, light, user screenshot style

## Brief and precedence

Source task: docs/design/2026-10-30-direction-b-home-result-prompts.md. The user approved proceeding with the light Result screen and explicitly skipped dark variants for now. B7-home-light.png was supplied as the layout/style continuity reference.

The user's current graphic instruction overrides the document's instrument glyph and L/R labels: hits contain only HH, SN or KD. Right-hand hits remain white with black abbreviations; left-hand hits black with white abbreviations. Timing rings, discs and crosses are feedback shapes, not instrument drawings. Condensed headings and technical supporting copy continue the user's supplied screenshot style.

## Inspection

- Header: Basic groove, 80 BPM, Passed as bracketed plain text, 92%.
- Right spine actions: Try again, Next: 85 BPM, Library.
- Two stacked bars, each with 16 columns and the count sequence 1 e & a 2 e & a 3 e & a 4 e & a.
- Both bars: white HH at 1,3,5,7,9,11,13,15; black SN at 5,13. Black KD at 1,9 in bar 1 and 1,9,11 in bar 2. No instrument glyphs or R/L labels.
- Timing marks visually checked: filled discs at bar 1 HH3, bar 1 SN13 and bar 2 KD11; cross at bar 2 HH15; the other 21 occupied cells carry hollow rings. Timing marks leave abbreviations readable.
- Breakdown values: Perfect 61, Early 3, Late 2, Wrong pad 1, Best streak 28. These are illustrative figures from the supplied brief, not recomputed from the two visible bars.
- Last-attempt values: 71,78,80,85,88,92; final point is a hollow ring. The chart joins these points without a separately visible baseline. Caption: Better than your last four runs.
- Output: 1448 × 1086 px. Exact font identities, point sizes, 88 pt spine and strict flat pixel colours are not verified. This is static concept artwork, not app implementation. No dark variants were generated.

## Generation prompt

Built-in image generation tool; B7 supplied as the reference image.

Use case: ui-mockup. Create ONLY B9 — RESULT, LIGHT, Smack-a-Pad CUT TAPE, matching the attached APPROVED B7 image's graphic system and iPad framing. One front-on landscape4:3iPad, same thin flatblack bezel, device scale, white outer margins and safe areas; no collage. High resolution requested screen2732×2048px. This is a FINISHED LESSON RESULTS screen, not Home or Play.

STYLE: same compact all-black SMACK-A-PAD identity at top, bold condensed headings/numbers, technical monospaced supporting copy, firm black rules, square tiles, WHITE page, BLACK ink. Orange#FF6B00 belongs ONLY to pattern. Only#FF6B00,#000000,#FFFFFF. No grey,tint,texture,gradients,glass,shadows,metallicbezel,bluecamera,photos,emoji,stars,badges,confetti,green/red status,roundedcards.32ptmargins,16ptgaps. Supporting/essential text at least18pt, typically20–24pt. No giant hero lesson heading. Preserve bottom home indicator clearance.

USER OVERRIDES: NO drum/cymbal/instrument pictures or hand illustrations. NO R/L hand letters in rhythm. ONLY abbreviations HH,SN,KD as hit labels. Right hand = WHITE tiles with BLACK abbreviation; left hand = BLACK tiles with WHITE abbreviation. Same as B7. Do not invert tile fills to indicate result. Small timing feedback rings/discs/crosses are allowed as feedback, never instrument glyphs.

RIGHT SPINE: white narrow side spine same as B7, target88pt; main content stays left of it. Replace Home navigation with THREE result ACTIONS only, vertically arranged:
“Try again”
“Next: 85 BPM”
“Library”
Each at least56pt high, BLACK OUTLINE, WHITE fill, black text,4ptcorners or square. Wrap Next: /85 BPM if needed, with legible text. Do not include Home,Intro,Progress,Settings or extra controls in this spine.

TOP MAIN: below compact identity line, heading “Basic groove”, supporting “80 BPM”. Plain state text “Passed” with a black side bracket, never a badge. Next to the title/state cluster, a large “92%” about64pt in black condensed type, not orange. Keep compact header space so whole result fits.

MIDDLE MAIN: one broad ORANGE field containing exactly TWO complete bars stacked, each with its own “Bar 1” or “Bar 2” caption, own16-column count row and exactly3pad rows (top to bottom HH,SN,KD). Repeated row labels in left label gutter OUTSIDE timecolumns. All steps and labels fully visible. No cursor/positionmarker because lesson finished.
Each bar has FOUR equal beat groups, FOUR equal subdivisions each, total precisely16equal columns:
1 e & a 2 e & a 3 e & a 4 e & a
Heavier BLACK beat-start rules, thinner BLACK subdivision rules. Square hit tiles as in B7, same size for every instrument.

EXACT PLAYED RHYTHM, one-based step positions:
Bar1 WHITE HH tiles at1,3,5,7,9,11,13,15; BLACK SN tiles at5,13; BLACK KD tiles at1,9.
Bar2 WHITE HH tiles at1,3,5,7,9,11,13,15; BLACK SN tiles at5,13; BLACK KD tiles at1,9,11.
Print ONLY HH or SN or KD in corresponding occupied tile; every empty cell stays ORANGE, unmarked. NoOHrow and no invented notes. There are25occupied tiles across both bars.
Each occupied tile ALSO has a SMALL timing mark BELOW its abbreviation, with comfortable vertical clearance. Keep letters fully readable and minimum18pt. Timing mark colour matches that tile's abbreviation: black on white tiles, white on black tiles.
Hollow ring = on time; FILLED DISC displaced left or right of tile centre = early/late; SMALL CROSS = wrong pad/miss.
EXACTLY3filled discs and1cross TOTAL inside pattern:
1) Bar1 HH step3: early, small filled disc left of centre.
2) Bar1 SN step13: late, small filled disc right of centre.
3) Bar2 KD step11: early, small filled disc left of centre.
4) Bar2 HH step15: small cross.
ALL other21occupied tiles have hollow rings at centre.
No rings in empty cells. No circular instrument drawings. Marks are clearly small feedback below text, not a replacement for abbreviations.

Below orange field, optional compact black-on-white key “On time”, “Early / late”, “Wrong pad” with matching ring,disc,cross. No coloured result legend.

LOWER MAIN: TWO OPEN COLUMNS, no card boxes:
LEFT heading “Breakdown”, five aligned rows with thin black bars:
“Perfect” — “61”
“Early” — “3”
“Late” — “2”
“Wrong pad” — “1”
“Best streak” — “28”
Bars can be short horizontal proportional marks under each row; black only. Illustrative summary numbers must print exactly.
RIGHT heading “Last attempts”. A simple BLACK LINE joining SIX scores in order71,78,80,85,88,92 over a baseline. Print these six values legibly, last point marked with a HOLLOW RING. No coloured series, no chart card or background grid. Beneath exactly:
“Better than your last four runs.”
Wrap that sentence to2lines if necessary, never tinytext.
All lower content fully on screen.

Never add stars, confetti, mascots, mood faces, level badges, charts not requested, purchase copy, invented controller mappings or app navigation from screenshot. No R/L, no instrument pictures anywhere in pattern; abbreviations and hand colour only. Match attached B7 condensed/technical typographic voice and white/black/orange blocks. Check all16columns,25tile labels,21rings/3discs/1cross, summary text and right actions before final.

