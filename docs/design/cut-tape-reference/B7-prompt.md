# B7 — Home, light, user screenshot style

## Brief and precedence

Source task: docs/design/2026-10-30-direction-b-home-result-prompts.md. The user additionally required the appearance of their previously supplied screenshot and abbreviation-only hits. This latest instruction overrides the document's instrument glyph and L/R requirements and typography direction.

Graphic reference: ../rehearsal-folio/reference-style/style-reference.png.

- Right-hand hits are white tiles with black abbreviations.
- Left-hand hits are black tiles with white abbreviations.
- No instrument pictures, drum glyphs or R/L hand letters appear in the rhythm.
- The existing Basic groove fixture uses HH, SN and KD. OH is not added because that fixture has no open-hat notes.
- Condensed headings and technical supporting text follow the user's screenshot.
- One image per turn, beginning with B7 as specified in the supplied file. B8–B10 were not generated.

## Inspection

Visually checked: 16 step columns with counts 1 e & a 2 e & a 3 e & a 4 e & a. White HH tiles at 1,3,5,7,9,11,13,15; black SN tiles at 5,13; black KD tiles at 1,9. No cursor. Calendar has dates 1–31 once each, days 26–29 filled and day 30 bracketed. Continue, right navigation, category progress, Offbeat hats/Open and Intro/Open are visible. The refinement removed the orange logo accent and device highlights. The final raster is 1448 × 1086 px; exact point dimensions, font identity, an 88 pt spine and strict flat colour values are not verified. This is concept artwork, not implemented app UI.

## Initial prompt

Generated with the built-in image generation tool, using the screenshot as a style reference.

Use case: ui-mockup. Generate ONLY B7 — HOME, LIGHT for Smack-a-Pad, direction B CUT TAPE. One single standalone front-on landscape4:3 iPad, thin BLACK bezel, equal small white outer margins, no collage. High resolution requested: screen2732×2048px corresponding1366×1024pt. Preserve safe areas/home-indicator space.

INPUT: attached screenshot is the USER'S OWN GRAPHIC STYLE REFERENCE, NOT the screen layout. Use its crisp orange/white/black block language, compact bold CONDENSED headings and numbers, technical monospaced supporting labels, sharp rule/grid discipline and rectangular pad-letter hits. No serif, no drum illustrations. Do not copy the screenshot's giant lesson title,120BPM, bottom dashboard, goals, stars or desktop navigation.

USER OVERRIDE — MOST IMPORTANT: ABSOLUTELY NO musical instrument pictures/glyphs or finger/hand illustrations. Hit cells contain ONLY abbreviations, e.g. HH, SN, KD. No R or L hand letters anywhere in the pattern or labels. Hand is encoded solely by tile fill: right-hand hits WHITE with BLACK abbreviation; left-hand hits BLACK with WHITE abbreviation. These white letters sit INSIDE black tiles, never directly on orange. Keep a consistent square tile style. Do not invent extra instruments/OH notes; Basic groove uses HH,SN,KD only. Do not include hand-letter legends.

LOCKED B7 LAYOUT: WHITE page, BLACK text, exact orange#FF6B00 only on the rhythm preview. Exact#000000/#FFFFFF, no designedgrey,tint,gradient,texture,shadow,statuscolour,photo,emoji,mascot,confetti,roundedcardgrid.32pt content margins,16pt gaps. Compact top identity line “SMACK-A-PAD”. Very narrow right navigation spine88pt wide in WHITE, extending down page, separate from main content. Its vertical touch targets at least56pt: “Home”, “Library”, “Intro”, “Progress”, “Settings”. Home selected by BLACK SIDE BRACKET plus heavier text, no coloured fill. Use compact condensed legible20pt nav so all words fit this narrow spine. No desktop horizontal nav, no left sidebar, no invented tools or status indicators.
Headings compact30–32pt condensed black like reference; numbers clear; technical supporting copy20–24pt, minimum18pt. Do not shrink labels to decorative tiny type.

UPPER MAIN AREA: left column in white page, about300pt wide, heading “Continue”. Below it readable lines:
“Basic groove”
“Electronic”
“80 → 100 BPM”
“best 92%”
Below this metadata a large BLACK filled, WHITE text “Continue” button, at least56pt high,4pt corners.
Immediately TO ITS RIGHT one broad ORANGE inset field, occupying about40% of usable page HEIGHT, square corners, with a static ONE-BAR rhythm preview of Basic groove. Do not place heading or Continue inside orange. Keep the orange rhythm field visually dominant; no hero banner, no carousel, no extra cards.

PATTERN PREVIEW IN ORANGE: three stable pad rows, top to bottom labels “HH”, “SN”, “KD” in black technical type, anchored left in a label gutter OUTSIDE16timecolumns. Exactly16EQUAL time columns, four groups of four. Count labels centered above each column exactly:
1 e & a 2 e & a 3 e & a 4 e & a
Heavier BLACK beat-start rules, thinner BLACK subdivision rules. No position marker, cursor or active-step highlight. Occupied cells show abbreviation ONLY in flat square tiles:
HH white tiles black“HH” at steps1,3,5,7,9,11,13,15;
SN black tiles white“SN” at steps5,13;
KD black tiles white“KD” at steps1,9.
Every other cell empty orange. No R/L, no cymbal,drum,glyph,ring,pictogram or hand inside ANY hit. No addedOHrow. The HH+SN at step5 and step13 must align vertically in exactly the same columns. HH+KD at step1 and9 align vertically. Do not drop or shift notes. Square tile corners, consistent size, readable abbreviations minimum18pt. White HH tiles are right hand; black SN/KD left hand, communicated by colour only.

LOWER MAIN AREA: TWO OPEN COLUMNS on white, no cards, no panel boxes:
LEFT: heading “This month”. A calendar of days1–31 as an aligned7-column grid. Prefer this exact placement (October):
weekday line “Mo Tu We Th Fr Sa Su”
first week [blank,blank,blank,1,2,3,4]
second [5,6,7,8,9,10,11]
third [12,13,14,15,16,17,18]
fourth [19,20,21,22,23,24,25]
fifth [26,27,28,29,30,31,blank].
Each date once. Practised days26,27,28,29 are FILLED BLACK SQUARES with white numbers; today30 has BLACK CORNER BRACKETS, no fill. Unpractised dates plain black numbers. Do not colour dates orange. Below: “Streak 4 days · best 9”.
RIGHT: heading “Progress”. Aligned readable text rows:
“Electronic” and “3 / 5 passed”, thin black progress bar at60%;
“Funk” and “0 / 5”, empty black-outline bar with zero fill;
“Rock” and “Locked”, a tiny CUSTOM FLAT BLACK LOCK beside Locked, no default stock icon.
Then an unboxed row “Next up: Offbeat hats” with an “Open” action right-aligned.
Then separate unboxed row “Intro — 24 exercises” with an “Open” action right-aligned.
Thin progress tracks only, no invented charts, no additional category counts.

Keep lower columns aligned and fully visible within safe areas; main content must not run beneath the right spine. Make layout calm enough to tap on an iPad. ALL numbers illustrative.
REJECT: instrument images/icons, R or L hand letters, white text directly on orange, incorrect16-step fixture, extra colours/grey, gradients, shadow, glass, tinylabels, roundedcards, stars/badges, achievements, decorativecharts, hero/carousel, giantBPM, giantheading, phoneUI stretched to tablet, collage or other screens. New typography and abbreviation tiles follow user's current request over older design-bible font/glyph instructions.

## Cleanup prompt

Edit this B7 Home light screen with one precise graphic cleanup. Preserve ALL content, exact counts, rhythm tiles, calendar numbers/marks, text, positions and composition. Do not redesign or change any data.
Remove the orange square from the top-left SMACK-A-PAD mark: make that square BLACK instead. The compact logo must be entirely BLACK on WHITE; orange is used only on the rhythm preview.
Make device frame pure flat BLACK without metallic-grey highlights, blue camera point, reflections, shadow or shading. All page white must be flat pure WHITE. Orange preview must be flat exact#FF6B00 with no tonal variation or texture. Use only#FF6B00,#000000,#FFFFFF, with normal antialiasing at boundaries.
Keep the right navigation spine narrow and white; target88pt wide if possible while keeping all labels at least18pt and main content unaltered. Do not add icons or new navigation.
Most important, preserve the perfectly correct pattern:16equal columns, counts1 e & a 2 e & a 3 e & a 4 e & a; white HH tiles with blackHH at steps1,3,5,7,9,11,13,15; black SN tiles with whiteSN at5,13; black KD tiles with whiteKD at1,9. ALL other cells empty. No instrument pictures, no cymbal/drum glyphs, no R/L letters, no hand drawings, no cursor. Do not add OH row.
Calendar dates1–31 remain exactly once;26,27,28,29 black-filled,30 bracketed. Electronic3/5passed and60%bar; Funk0/5 andemptybar; RockLocked. All titles and row copy exactly unchanged. Keep Continue,NextupOffbeat hats/Open,Intro24exercises/Open.
Keep the same condensed black headings and technical supporting type, matching user's screenshot style. Flat squared rectangular blocks, no cards, no decoration or extra colours. One front-on landscape4:3iPad, same framing, no collage. Request full high resolution2732×2048screen; do not alter proportions or composition.

