# Smack-a-Pad iPad — Ticket 10, revised design directions

Date: 2026-10-30. Status: three prompt sets delivered; image generation and direction selection remain with Jakub. No direction is selected.

This replaces the Signal Panel / Practice Ledger / Open Cue delivery. The updated [design brief](../DESIGN-BRIEF.md) and [SPEC §3.8](../SPEC.md#38-screens) govern this revision: the orange pattern grid leads; BPM and feedback stay peripheral. These are image-generation prompts, not a SwiftUI implementation. No build is required by Ticket 10.

## What is being compared

Play answers “Which pads and hands come next, and where are they in the rhythm?” Library answers “Which category and exercise shall I open?” The shared material is Smack-a-Pad's pad symbols, simultaneous hits, sixteenth-note counting and external-controller practice. The visual identity comes from that material, not from unrelated imagery or a dashboard shell.

| Direction | Structural idea | Orange pattern placement | Typography | Library structure | Main tradeoff |
| --- | --- | --- | --- | --- | --- |
| A — Rehearsal Folio | An open exercise sheet, read down the page | Broad inset middle field; bars stacked | Fraunces Medium + Source Sans 3 | Open category contents with inline lessons | Excellent reading order; longer eye travel between bars |
| B — Cut Tape | A timing tape with a small control spine | Upper field, nearly full width; paired bar blocks | Space Grotesk Medium + IBM Plex Sans | Category index beside a lesson list | Strong temporal continuity; side-by-side bars need adequate width |
| C — Open Bench | A large practice surface beneath a touch shelf | Lower field extending across the content width | Bricolage Grotesque Semibold, normal width + Atkinson Hyperlegible Next | Horizontal categories above a lesson list | Clear separation of playing and navigation; the shelf must stay shallow |

The three must remain distinguishable when converted to greyscale or viewed with their headings covered. A uses a sheet and vertical reading order; B uses a tape and right control spine; C uses a top control shelf and a low, expansive practice field. None uses a large tempo column, a giant isolated next-pad word, or condensed bold typography as its organising device. Light and dark are equally complete variants of every direction.

## Delivery and generation procedure

Each self-contained prompt below requests six **separate** images. Copy the whole block into Gemini or ChatGPT image generation. If the generator handles one image per turn, request the listed image ID, starting with A1, B1 or C1, and retain that image as the framing and design-system reference for the remaining five. Do not generate a six-screen board and crop it. Use a fresh conversation for each competing direction.

| Image in each set | Screen | Theme | Sample state |
| --- | --- | --- | --- |
| 1 | Play, static | Light | Two bars, current position at bar 2, beat 2 |
| 2 | Play, static | Dark | Identical data and position to image 1 |
| 3 | Play, scrolling | Light | Same two-bar exercise, bar 2 beat 2 under the fixed hit marker |
| 4 | Play, scrolling | Dark | Identical data and position to image 3 |
| 5 | Library, category browse | Light | Electronic selected, Intro distinct, Rock locked |
| 6 | Library, category browse | Dark | Identical content and selection to image 5 |

That is 18 primary screen images across the three directions. The prompt sets also define one-, three-, four- and eight-bar adaptations below. These can be requested as additional individual images to inspect density; they are not substitutes for the six primary images. Image generators may approximate type and lettering: a prompt check cannot certify the resulting pixels, interaction or timing.

## Shared design contract

### Palette and hierarchy

Use exactly three solid colours: orange `#FF6B00`, black `#000000`, white `#FFFFFF`. This is deliberately stricter than the brief's allowance for derived greys. There are no grey design tokens, tinted whites, tinted blacks, alternate oranges, translucent fills, green/red feedback, gradients, grain or shadows. Edge antialiasing is not an additional design colour.

In light mode the page is white with black text. In dark mode it is black with white text. The orange field and its black grid ink remain the same in both. Use black text on orange; white on orange is insufficient for ordinary labels. Use opposite page ink for navigation and primary transport. Orange belongs to the pattern and, in Library, to one small rhythm preview of the selected lesson. A selected category is identified by weight and a bracket/underline in page ink, not by an additional colour.

The orange pattern field occupies approximately 55–65% of the usable Play screen. Its cell symbols, hands and count labels are the first read. BPM is a peripheral 28–32 pt value with its unit, not a billboard. Score is subordinate 20 pt text. General body text is 20–24 pt; essential labels and L/R are at least 18 pt. Navigation targets are at least 44 × 44 pt; Pause/Stop targets at least 56 pt high. The pattern is a display of external MIDI-controller practice, not a mandatory touch-pad bank.

All colours are intended to become centrally defined Theme.swift tokens in a later implementation ticket. This task does not create or modify Theme.swift.

### Rhythm, symbols and hands

One row per **used physical pad**, with a stable order across bars. One column per sixteenth step. Preserve different physical pads even when their instruments share a name. For the comparison fixture there are exactly three rows, ordered Hat, Snare, Kick. These names are illustrative, not new pad IDs or changes to controller mapping.

Each bar has exactly 16 columns, labelled `1 e & a 2 e & a 3 e & a 4 e & a`. Beat starts are heavier vertical rules; subdivisions are lighter strokes of the same ink. An occupied cell contains **both the pad's instrument symbol and L or R**, not just a letter, generic dot or rectangle. Empty cells contain no hit. Simultaneous hits occupy the same column on different rows. Instrument drawings are flat, simplified silhouettes/contours: kick = concentric drum rings with a small off-centre port; snare = shallow drum cylinder with a horizontal wire line; closed hat = two close cymbal contours. Keep the same symbol vocabulary in the row labels and hit cells. L/R are hand instructions, not instrument names or timing judgements; do not add finger numbers.

Fixture, using one-based step positions:

| Bar | Hat | Snare | Kick |
| --- | --- | --- | --- |
| 1 | R at 1, 3, 5, 7, 9, 11, 13, 15 | L at 5, 13 | L at 1, 9 |
| 2 | R at 1, 3, 5, 7, 9, 11, 13, 15 | L at 5, 13 | L at 1, 9, 11 |

The active column is bar 2, step 5, which is beat 2. Hat R and Snare L are simultaneous there; both must be legible. The sample is “Basic groove”, 80 BPM, MIDI connected, score 92%. The score is illustrative, not calculated from this fixture or a product claim.

### Position and feedback

Static: all bars of the short exercise remain fixed and visible. A narrow marker moves through the active bar; it does not sweep through the gap between stacked blocks. The current bar has an extra external bracket or heavier title, without recolouring or fading the other bars.

Scrolling: rows and their left labels stay fixed vertically. The grid, count labels, bar numbers and all simultaneous hits translate together from right to left past a fixed hit marker, about one-third of the time viewport from its left edge. The view contains previous context, the current beat and upcoming beats. The next repeat is labelled as the next cycle, not as a fictitious extra bar. Clip only at the time viewport edges; no fading gradients, moving row labels or waterfall game lanes. A still image should make the fixed marker clear; do not add motion blur or decorative arrows.

Position markers use a black core with a narrow white clearance edge so they remain distinguishable from black symbols on orange. Place a small pointer outside the occupied cells; do not obscure the L/R pairs. The playback marker represents time, independently of hit feedback.

A compact peripheral timing rail has a centre notch. A filled disc left/right of centre means early/late; its displacement carries the offset. At centre, a larger hollow ring means on time. A cross in a reserved slot beside the rail means miss; do not place a miss at zero as if it were on time. Shapes remain within a fixed-size feedback footprint. The sample shows the on-time ring. No flashing, background pulses, colour-coded states or decorative motion. Feedback stays noticeable through shape and position without becoming a second hero panel.

### Pattern length, density and orientation

| Length | Static layout | Scrolling layout |
| --- | --- | --- |
| 1 bar | One full-width 16-column block; never stretch one word across the band | Repeat the one-bar grid, with explicit cycle boundaries |
| 2 bars | A/C: two stacked full-width blocks; B: a pair if legible, otherwise stacked | A continuous two-bar sequence; retain the same row labels |
| 3 bars | Three stacked full-width blocks; no invented fourth bar or empty peer panel | Three consecutive bar boundaries before the next cycle |
| 4 bars | A: four stacked blocks for the three-row fixture at the primary size, 2 × 2 on shorter screens; B/C: 2 × 2 with bar order 1,2 / 3,4 | One continuous four-bar time viewport |
| More than 4 / whole track | Pages of up to four bars; thin whole-track overview, current-page outline, explicit range such as “5–8 / 8” | Continuous track; thin overview with a visible viewport bracket and current position |

Use bar 1 alone for the one-bar example; bars 1,2,1 for three bars; bars 1,2,1,2 for four; repeat that four-bar phrase for eight. The overview must show eight equal segments for the eight-bar example, not a made-up waveform. It is navigation, not a performance chart. Reveal section-loop handles only after the Loop action.

Primary framing is a 1366 × 1024 pt landscape screen rendered at 2732 × 2048 px or the nearest supported size. Include one thin front-on iPad bezel, equal outer margins, no environment, perspective, props or hands. Reserve safe areas and home-indicator space. Keep the same device, scale and margins for every image.

At 1024 × 768 pt, move B's side controls into a shallow edge row before compressing the time grid. In portrait, put full-width bar blocks vertically and move side tools into the top row. The pattern remains visible and orange. Never solve density by dropping pad rows, removing hand labels, shrinking essential text below 18 pt, or covering the pattern with a control sheet. Cells are not touch targets; the mode switch and navigation are.

For a concrete width check, a 1286 pt content field minus a 24 pt inter-block gap gives two 631 pt blocks. A 72 pt row-label gutter leaves 559 pt for 16 columns, about 35 pt each. Symbols and hands can stack within a cell. Use full-width stacks when a pair cannot hold the labels. For A's four-bar primary-size render, place symbol and hand side by side in the wider cells: four blocks of 128 pt (three 28 pt pad rows, 22 pt counts, 22 pt bar label), plus three 16 pt gaps, total 560 pt. This is a proposed layout budget, not a measured render. Use 2 × 2 on shorter landscape screens rather than squeezing four vertical blocks. A four-bar, sixteen-used-pad case is not validated by the three-row fixture: request a separate density render before approving the chosen direction for implementation. Do not claim this document proves every content size fits.

### On-demand controls

Pause and Stop stay visible. BPM and mode controls keep fixed footprints. A visible “Tools” action opens Pads, Score details, Settings and Loop in one touch; they may also have a gesture shortcut but must not rely on an undiscoverable gesture. The default images keep those secondary surfaces closed. Library has explicit Settings and Calibration actions. Switching state does not shift other controls or the grid.

For later supporting-screen work, Settings keeps the chosen direction's flat rows for kit selection, BPM step 1/2/5/10, controller profiles, MIDI learn and language. Calibration carries the same type and monochrome feedback through the guided 10-click flow per device. These continuity notes do not add screen-generation or implementation scope to Ticket 10.

## A — Rehearsal Folio

**Idea:** the pad-and-hand exercise becomes an open rehearsal folio. A serif is used for compact screen/lesson headings only; rhythm and navigation use a clear humanist sans. The character is typographic and spatial, with no paper texture, binding, ornamental numbering or website hero.

**Design bible:** inset middle orange field; 40 pt equal content margins; 16 pt block gaps; stacked reading order; square pattern field and open list rows; 8 pt transport corners; feedback circles reserved for timing. Fraunces Medium headings 30–32 pt; Source Sans 3 Regular/Semibold for everything else, including hands/counts and 28 pt BPM. No condensed faces. In Library, Electronic expands within the category contents rather than driving a separate pane.

### Copy-ready prompt A

```text
Create six separate high-resolution iPadOS-native screen concept images
for Smack-a-Pad, direction A: REHEARSAL FOLIO. Generate A1 first, then
A2–A6 separately. If one image per turn is supported, deliver only the
requested ID and wait for the next ID. Never combine screens in a collage.

FIXED PRESENTATION
One front-on landscape 4:3 iPad per image, thin black bezel, equal outer
margins, no hands, props, room, perspective or drop shadow. Target screen
2732 × 2048 px, representing 1366 × 1024 pt. Keep all six frames identical.
Preserve safe areas and home-indicator space. The app content dominates.
An external MIDI controller is played; touch navigates. Variance 7/10,
motion 3/10, density 4/10. Calm, confident, slightly raw practice instrument.

DESIGN BIBLE — LOCK THROUGH ALL SIX IMAGES
Exactly orange #FF6B00, black #000000, white #FFFFFF. No designed greys,
tints, transparency, texture, gradients or other colours. Light page:
white with black text. Dark page: black with white text. Pattern field:
the same solid orange with black ink in both themes. No white labels on
orange. No green/red hit states. Primary transport uses page ink on the
opposite page colour. The orange pattern occupies about 55–65% of the
usable Play screen and is read before BPM or score.
Fraunces Medium for compact 30–32 pt screen/lesson headings only; Source
Sans 3 Regular/Semibold for counts, hands, navigation and all supporting
text. Body 20–24 pt; essential labels at least 18 pt. BPM 28 pt, peripheral.
No condensed bold type. Equal 40 pt content margins, 16 pt internal gaps,
an open exercise-sheet composition. The orange field is inset and sits
across the middle. No sidebar or giant isolated next-pad word. Square
pattern corners, unboxed list rows, transport corners 8 pt, circular
timing marks only. No simulated book, paper, grain or binding.

EXACT RHYTHM FIXTURE
Lesson “Basic groove”; 80 BPM; “MIDI connected”; sample score “92%”.
Exactly three stable pad rows, top to bottom: Hat, Snare, Kick.
Each bar has 16 equal step columns with these exact count labels:
1 e & a 2 e & a 3 e & a 4 e & a
Make beat-start rules heavier, subdivision rules thinner, all black.
Occupied cells show BOTH the instrument symbol and hand L or R, stacked
if needed; empty cells have no mark. Symbols are flat black contours:
hat = two close cymbal contours; snare = shallow drum with wire line;
kick = concentric drum rings with a small off-centre port. Repeat the
same glyph in row labels. No generic dots, finger numbers or pad-ID changes.
One-based steps:
Bar 1: Hat R at 1,3,5,7,9,11,13,15; Snare L at 5,13; Kick L at 1,9.
Bar 2: same Hat and Snare; Kick L at 1,9,11.
The current position is bar 2, step 5 = beat 2. Hat R and Snare L align
vertically at that exact column. Keep both symbols/hands unobscured.

A1 — PLAY STATIC, LIGHT
White page. Quiet top line: “Library”, compact “Basic groove”, and
“MIDI connected”. Beneath it, a shallow row has “Static / Scrolling”,
Static selected by a black underline, and “80 BPM” at the far right.
The broad middle orange field contains two complete bars stacked in
reading order, each with its own count row and repeated pad labels.
Both bars stay fixed and fully visible. Bar 2 has a black external
bracket and a moving time cursor at beat 2. The cursor has a black core,
white clearance edge and small pointer outside the hit cells. It does
not hide the symbols or letters and is not a third pad row.
Below the field, a compact timing rail with centre notch shows a hollow
ring at centre, labelled “On time”, describing the previous hit. Early
or late uses a filled disc displaced left/right; miss uses a cross in a
separate reserved slot. All feedback uses page ink, shape and position.
Keep the sample “92%” small and peripheral. Bottom-left “Pause” and
“Stop” have 56 pt targets. Bottom-right “Tools” opens Pads, Score details,
Settings and Loop in one touch; keep that surface closed. Navigation
targets at least 44 pt. Nothing shifts when feedback changes.

A2 — PLAY STATIC, DARK
Exact A1 data, placement and device framing. Black page, white page text,
same orange/black pattern. Theme inversion changes no rhythm, glyph,
control position or hit state. No extra status colours or tinted blacks.

A3 — PLAY SCROLLING, LIGHT
Use A1 shell, transport and type. Select Scrolling. Inside the same orange
field, replace stacked bars with one continuous horizontal time viewport
with tall readable pad rows. Row labels remain anchored at the left.
Grid, counts, bar labels and hits translate together right-to-left under
a fixed black marker with white clearance at one-third of the time
viewport. Bar 2 beat 2 is under that marker. Show previous context to
the left and upcoming beats to the right, with the next repetition
explicitly labelled “Cycle 2”. No vertical falling notes, blur or arrows.

A4 — PLAY SCROLLING, DARK
Exact A3 composition and position, black page and white page text;
same orange grid with black symbols. Maintain the fixed hit marker.

A5 — LIBRARY, LIGHT
White page with the same heading/body faces and margins. Header “Library”
with “Settings” and “Calibration” text actions. An open table of contents:
separate “Intro — 24 exercises” row, then Electronic, Funk and Rock.
Electronic is expanded inline, marked by a black bracket and weight.
Indent plain lesson rows “Basic groove”, “Offbeat hats”, “Kick variations”
beneath it. One small orange rhythm preview belongs to Basic groove;
it uses the same three pad glyphs and is subordinate to readable names.
“Open” leads from Basic groove to Play. Rock has a custom flat lock and
the word “Locked”; its full readable row remains tappable for soft unlock.
No purchase copy or other category counts. No numbered chapter costume,
repeated card boxes, achievement badges or invented progress charts.

A6 — LIBRARY, DARK
Exact A5 content, hierarchy and framing. Black page, white text and lock;
same orange preview with black rhythm ink. Selection uses a white bracket.

LENGTH AND ORIENTATION RULES FOR FURTHER INDIVIDUAL RENDERS
1 bar: one full-width 16-column block. 2 bars: two stacked blocks.
3 bars: three stacked blocks, no empty fourth slot. 4 bars: four stacked
blocks at this primary size; use symbol and hand side by side in the
wider cells. Budget each block at 128 pt high: three 28 pt pad rows,
22 pt counts and 22 pt bar label; with three 16 pt gaps the stack is
560 pt high. On shorter landscape screens use 2 × 2 instead of squeezing
four vertical blocks, preserving the same minimum type.
Longer tracks: pages of up to four bars plus a thin whole-track overview
with a current-page outline and labelled range, or continuous scrolling.
An eight-bar fixture repeats bars 1,2,1,2 twice; overview has eight equal
segments. The active bar is bracketed; other bars remain readable orange.
In portrait use full-width vertical blocks and a shallow top control row.
Do not hide used pads or hand labels or reduce essential type below 18 pt.
Keep pattern visible; Tools is closed by default. No scoring thresholds
or new controller mappings are being designed.

REJECT AND REDO
Any colour outside orange/black/white; green/red feedback; gradients of
any kind; neon; glass or blur cards; uniform rounded shadow-card grids;
emoji; untouched SF Symbols or stock icon packs; default system type;
condensed-bold-on-black composition; centred hero plus three cards;
same radius on everything; fake 3D; texture, confetti, mascots, photos;
tiny labels; giant BPM; single-word pattern cue; missing pad symbol or
hand; misaligned simultaneous hits; hidden pattern; stretched phone UI.
Check every A image against these rules. Check the grid and L/R pairs
before judging style. Do not claim a still proves scrolling behaviour.
```

**Prompt review A:** the orange grid replaces the old single text cue; the tempo column is gone. Static stacking and an inline Library contents view are explicit. The serif is confined to headings; hands/counts stay in Source Sans 3. The main risk is vertical travel for four bars: inspect A with four complete bar blocks before selecting it.

## B — Cut Tape

**Idea:** the sixteenth grid becomes a continuous timing tape. A narrow right control spine leaves the orange data surface wide. The same rhythm of fixed labels and aligned fields becomes a category index plus lesson pane in Library. This is a flat timing instrument, without reels, console ornament or a retro terminal costume.

**Design bible:** 32 pt equal outer margins; 16 pt gaps; compact top identity line; upper orange field; 88 pt right control spine in the page colour. Space Grotesk Medium for 28–30 pt headings/BPM, IBM Plex Sans for counts, hands and text. Pattern corners square; transport corners 4 pt; open category/list rows. In narrow landscape or portrait the control spine moves into a shallow row before it costs pattern legibility.

### Copy-ready prompt B

```text
Create six separate high-resolution iPadOS-native concept images for
Smack-a-Pad, direction B: CUT TAPE. Start with B1. B2–B6 are separate
images, never a board or collage; if necessary generate one requested ID
per turn. Keep a single consistent design system across the set.

PRESENTATION AND PURPOSE
One front-on 4:3 landscape iPad, thin black bezel, equal outer margins,
no perspective, room, props, hands or shadow. Screen target 2732 × 2048 px
at 1366 × 1024 logical pt, or nearest supported size. Same device scale,
safe areas and home-indicator space across all six images. A MIDI finger
drummer glances at the app from arm's length; touch is for navigation.
Variance 7, motion 3, density 4. Practice instrument, calm and direct.

LOCKED DESIGN SYSTEM
Only #FF6B00 orange, #000000 black, #FFFFFF white. Light page is white
with black ink; dark page black with white ink. Pattern stays solid
orange with black symbols/counts in both. No grey tokens, tinted blacks,
warm whites, transparency, texture or status hues. No white text on orange.
Space Grotesk Medium for compact headings and 28–30 pt BPM; IBM Plex Sans
Regular/Medium for body, navigation, counts and hands. Normal width, no
condensed-bold face. Body 20–24 pt, essential labels/L/R at least 18 pt.
Equal 32 pt content margins and 16 pt gaps. Compact product/title line
above an expansive orange timing field, about 55–65% of usable screen.
A narrow 88 pt RIGHT tool spine shares the page ground, never a coloured
sidebar. The spine groups Pause, Stop, Tools; tempo and mode sit in a
small lower edge row. No left tempo column. Pattern corners square;
transport radius 4 pt; timing symbols circular; lists unboxed. Flat
surfaces, no reels, tape texture, metal, HUD elements or terminal styling.

EXACT COMMON DATA
“Basic groove”, “80 BPM”, “MIDI connected”, sample score “92%”.
Pad rows top-to-bottom: Hat, Snare, Kick. Do not merge physical pads or
invent controller mappings. Each bar has 16 columns labelled exactly
1 e & a 2 e & a 3 e & a 4 e & a
Beat-start rules are heavier than subdivisions, both black on orange.
Each hit has its instrument glyph AND hand L/R, with the same glyph in
the row label. Hat: two close cymbal contours. Snare: shallow cylinder
with wire line. Kick: concentric drum rings and small off-centre port.
Use simple flat black line drawings, not stock icons or generic squares.
One-based steps in bar 1: Hat R 1,3,5,7,9,11,13,15; Snare L 5,13;
Kick L 1,9. Bar 2 repeats these with an extra Kick L at step 11.
Current position: bar 2, step 5, beat 2. Hat R and Snare L are simultaneous
in that column. Show all other occupied/empty cells accurately.

B1 — PLAY STATIC, LIGHT
White page. A compact top line says “Smack-a-Pad”, “Library”, “Basic
groove”, “MIDI connected”. Two complete bar blocks sit side by side
INSIDE ONE orange field, with an internal gap, repeated count rows and
pad labels. They are data blocks, not rounded cards. Both stay fixed.
Bracket bar 2 in black. Its moving position marker is at beat 2, with a
black core, white clearance edge and a small pointer above the cells;
keep all symbols/hands legible. No decorative full-screen crosshair.
Right of the orange field, the narrow page-colour spine contains labelled
Pause and Stop targets at least 56 pt high and Tools at least 44 pt.
Tools opens Pads, Score details, Settings and Loop in one touch; keep it
closed. At the lower edge, “Static / Scrolling” selects Static with a
black underline, plus small “80 BPM” and “92%”. A compact timing rail
uses a centre notch and a larger hollow ring at centre for “On time”.
Early/late uses a filled disc displaced left/right; miss uses a cross
in a separate reserved slot. Feedback is page ink, shape and position,
with fixed occupied space. It must not compete with the orange grid.

B2 — PLAY STATIC, DARK
Exact B1 framing, fixture, position and component placement. Black page
and white page ink; same orange field and black grid. The control spine
is black, without neon, outlines around every group or coloured buttons.

B3 — PLAY SCROLLING, LIGHT
Same upper orange field and right spine as B1; select Scrolling. The two
bar panels become one continuous horizontal timing tape. Pad labels stay
fixed on the left. Bar numbers, counts, cells and simultaneous hits move
together right-to-left through a fixed hit marker about one-third across
the time viewport. The marker is black with white clearance; bar 2 beat 2
is under it. Past context remains left, upcoming beats right. Mark the
following repetition “Cycle 2”. No vertical game lanes, fading edges,
motion blur, waveform art or moving row labels. Bottom feedback/transport
positions do not move when modes change.

B4 — PLAY SCROLLING, DARK
Exact B3 position and framing, black page, white page labels, unchanged
orange tape/black glyphs and fixed hit marker. The theme changes no data.

B5 — LIBRARY, LIGHT
Same compact identity line, typography and margins. Header “Library”,
with “Settings” and “Calibration” text actions. A 240 pt open category
index at left lists separate “Intro — 24 exercises”, then Electronic,
Funk, Rock. Electronic uses a black side bracket and medium weight;
do not fill its row with accent colour. Rock carries a custom flat lock
and “Locked”; the entire legible row remains tappable for soft unlock,
with no payment copy. The wider right pane lists “Basic groove”,
“Offbeat hats”, “Kick variations” in comfortable flat rows with aligned
“Open” actions. A small orange rhythm preview belongs only to Basic
groove and uses the same glyphs as Play. No other category counts,
metric cards, badges, covers or progress charts. One selected category
clearly controls this lesson pane; opening Basic groove leads to Play.

B6 — LIBRARY, DARK
Exact B5 information, alignment and framing. Black ground throughout,
white headings/text/brackets/lock, same orange preview with black ink.
Do not introduce a second surface hue or a glowing selected row.

BAR COUNT AND SMALLER-SCREEN ADAPTATIONS
1 bar is one full-width 16-column block. 2 bars are paired only while
symbols and L/R fit; otherwise stack. 3 bars are three full-width stacked
blocks with no dummy fourth slot. 4 bars use 2 × 2 in order 1,2 / 3,4,
one continuous orange field, repeated labels and current-bar bracket.
For more than four bars, static mode pages up to four with a thin whole-
track overview, page outline and range; scrolling mode stays continuous
with a visible viewport bracket in the overview. Eight-bar example:
repeat bars 1,2,1,2 twice and draw exactly eight equal overview segments.
At 1024 × 768 pt or in portrait move the right spine into a shallow edge
row before compressing the grid; portrait uses full-width vertical bars.
Keep all used pad rows and essential labels at least 18 pt. Use stacked
symbol and hand inside a cell when needed. Do not make cells touch pads.
Loop handles and the pad-layout thumbnail stay hidden until requested.

REJECT AND REDO IF ANY APPEARS
Colours other than orange/black/white, status green/red, gradients, mesh,
neon, glass, blur cards, equal rounded cards with shadows, emoji, untouched
SF Symbols or stock icons, default system type, condensed-bold-on-black
as the design idea, centred hero plus three cards, one radius everywhere,
fake 3D, retro tape machinery, mascots, photos, confetti, grain, tiny text,
giant tempo column, isolated word cue instead of a grid, missing symbols
or L/R, simultaneous hits in different columns, hidden pattern, phone UI
stretched onto an iPad. Review every B image, including both libraries.
A static render demonstrates composition, not working playback timing.
```

**Prompt review B:** the tool spine is on the right, contains transport rather than a large tempo display, and moves out of the way on smaller screens. Library is a real category-to-lessons relationship, not a grid of covers. The main risk is cell width: test a four-bar image and a 1024 × 768 pt adaptation before selecting the pair layout.

## C — Open Bench

**Idea:** the external-controller player's app becomes a large practice bench beneath a shallow shelf for touch navigation. The low orange field is the working surface. Broad, humanist letterforms and a horizontal category rail separate it from the folio and timing-tape compositions. There is no hardware simulation.

**Design bible:** 32 pt equal content margins; a shallow top shelf containing transport/tempo; expansive lower orange field; no sidebar or bottom transport dock. Bricolage Grotesque Semibold at normal width for 28–32 pt headings and BPM; Atkinson Hyperlegible Next Regular/Medium for counts, hands and navigation. Square pattern, open lesson rows, 12 pt transport corners, timing ring/disc/cross. The top shelf is at most about one-fifth of usable height.

### Copy-ready prompt C

```text
Create six separate high-resolution visual concepts for Smack-a-Pad,
a native SwiftUI iPad finger-drumming trainer. Direction C: OPEN BENCH.
Generate C1 first and C2–C6 as individual images. If one image is possible
per turn, deliver the requested ID only. No collage or concept board.

CONSISTENT PRESENTATION
One front-on landscape 4:3 iPad with a thin black bezel and equal outer
margins. No props, hands, room scene, perspective or shadow. Target screen
2732 × 2048 px at 1366 × 1024 logical pt, or nearest supported size.
Identical device scale and margins throughout. Respect safe areas and the
home indicator. Content is primary. A player uses an external MIDI
controller and glances at the iPad at arm's length; touch navigates.
Calm, direct, slightly raw; variance 7/10, motion 3/10, density 4/10.

DESIGN BIBLE — KEEP EXACTLY
Only orange #FF6B00, black #000000, white #FFFFFF. No greys, alternate
oranges, tinted surfaces, transparency, texture or other hues. Light page:
white with black text. Dark page: black with white text. The orange
pattern field always has black ink; never white text on orange.
Bricolage Grotesque Semibold at NORMAL width for compact headings and
28–32 pt BPM; Atkinson Hyperlegible Next Regular/Medium for navigation,
count labels, pad names and hands. No condensed type or system default.
Body 20–24 pt, essential labels/L/R at least 18 pt. Equal 32 pt content
margins; 16 pt gaps. A shallow TOP control shelf, at most one-fifth of
usable height, sits above a large LOWER orange practice field occupying
about 55–65% of the usable screen. No sidebar, giant next-pad word, bottom
transport dock, fake hardware or website hero. Square pattern corners,
unboxed rows, 12 pt transport corners, timing discs/rings/crosses only.

EXACT COMPARISON FIXTURE
“Basic groove”, “80 BPM”, “MIDI connected”, illustrative score “92%”.
Three fixed pad rows top-to-bottom: Hat, Snare, Kick. Every bar has exactly
16 columns, with count row: 1 e & a 2 e & a 3 e & a 4 e & a.
Emphasise beat starts with heavier black rules; lighter subdivision
strokes remain black. Each occupied cell contains the instrument symbol
AND hand L/R; empty cells have no hit. The symbol and hand can stack.
Hat glyph: two close cymbal contours; snare: shallow drum cylinder with
wire line; kick: concentric drum rings with a small off-centre port.
Use flat black drawings, repeated in row labels, consistent across bars.
No generic dots, emoji, finger numbers or invented pad mapping.
One-based steps, bar 1: Hat R at 1,3,5,7,9,11,13,15; Snare L at 5,13;
Kick L at 1,9. Bar 2: same, with extra Kick L at 11. Current position is
bar 2 step 5, beat 2: Hat R and Snare L occur together in one column.

C1 — PLAY STATIC, LIGHT
White page. A small identity line has “Library”, “Basic groove” and
“MIDI connected”. Immediately below, the shallow touch shelf groups large
“Pause” and “Stop” at left, “Static / Scrolling” in the middle, small
“80 BPM” and “Tools” at right. Static is selected by a black underline.
Pause/Stop targets at least 56 pt high; other controls at least 44 pt.
Tools reveals Pads, Score details, Settings and Loop in one touch; keep
the surface closed. Navigation is text-led, no strip of icon buttons.
The large orange field sits BELOW the shelf and extends across the
content width toward the lower safe area. It contains two full-width
stacked bars, both entirely visible and fixed. Bar 2 has a black bracket;
a moving time marker at beat 2 uses a black core, white clearance and a
pointer outside the occupied cells. It never covers either L/R pair.
A compact peripheral footer below the orange field holds the subordinate
“92%” and timing rail with centre notch. A large hollow ring at centre
means “On time”. Early/late is a filled disc displaced left/right; miss
is a cross in its own reserved slot. Use black page ink and stable space,
not green/red, flashing or a second dominant panel. Controls never move
as the result changes. Do not add a second transport row at the bottom.

C2 — PLAY STATIC, DARK
Exact C1 fixture and geometry, black page with white page text and
feedback; the same solid orange field with black grid ink. Do not change
the current bar, hands, controls, font width or device framing.

C3 — PLAY SCROLLING, LIGHT
Keep the shallow top shelf and low orange field. Select Scrolling. The
orange field now contains a continuous horizontal grid with tall readable
pad rows. Labels remain fixed at left; counts, bar numbers and all hit
cells translate together right-to-left past a fixed marker about one-
third into the time viewport. Bar 2 beat 2 is under that marker. Show
past context left, upcoming beats right, and identify the next repeated
bar as “Cycle 2”. Marker has a black core and white clearance, with no
overlap on hand letters. No falling-note game lanes, fade masks, motion
blur or decorative movement. The top shelf and timing footer stay put.

C4 — PLAY SCROLLING, DARK
Exact C3 fixture and fixed-marker position. Black page, white page text,
same orange grid/black symbols. All six images share identical framing.

C5 — LIBRARY, LIGHT
White page with the same type and shallow shelf language. Header
“Library”, “Settings”, “Calibration”. Below, a horizontal row of large
category text selectors: Intro, Electronic, Funk, Rock. Electronic is
selected by a black underline and weight, never a coloured pill. Put
“24 exercises” directly with Intro; no other counts. Rock has a custom
flat lock plus “Locked”; its full target remains readable and tappable
for soft unlock, with no purchase copy. Under the category row, list
“Basic groove”, “Offbeat hats”, “Kick variations” as open, comfortably
spaced rows with aligned “Open” actions. Only Basic groove has a small
orange rhythm preview using the same three pad symbols. It is exercise
data, not cover art. Open leads to Play. No sidebar, floating cards,
catalogue poster, carousel, badges or invented completion charts.

C6 — LIBRARY, DARK
Exact C5 content and hierarchy, black page, white text/underline/lock,
same orange rhythm preview and black preview ink. Keep the category rail
and lesson rows in the same positions and preserve large touch targets.

LENGTH AND ORIENTATION RULES
1 bar: one full-width 16-step block. 2 bars: two stacked blocks.
3 bars: three stacked blocks, no empty fourth peer. 4 bars: a 2 × 2 grid
in order 1,2 / 3,4 within the one orange field, each with its own labels.
The active bar alone gets an external bracket; all bars stay readable.
More than four bars: pages of up to four plus a thin whole-track overview
and current-page outline, or continuous scrolling with viewport bracket.
An eight-bar example repeats bars 1,2,1,2 twice, overview exactly eight
equal segments with labelled range. No invented waveform or score chart.
In smaller landscape or portrait keep the shelf shallow, full-width bars
stacked, and secondary controls behind Tools. Do not hide pad rows or
hand letters, shrink essential type below 18 pt, or cover the pattern.
Pad-layout thumbnail, score detail and loop handles are hidden by default.
Cells are rhythm notation, not mandatory touch pads. No scoring or pad
mapping changes are part of this concept.

REJECT AND REDO IF PRESENT
Any extra colour including green/red status hues; gradients or mesh;
neon glow; glass/blur cards; identical rounded shadow-card grids; emoji;
untouched default SF Symbols or generic icon packs; default system type;
condensed-bold-on-black as the skeleton; centred hero plus three cards;
one corner radius everywhere; fake 3D; hardware bevels, texture, mascots,
confetti, photos, tiny text, giant BPM, a giant word instead of a grid,
missing pad glyph or hand, simultaneous hits misaligned, hidden pattern,
or stretched phone layout. Review C1–C6 individually. A still does not
verify actual scrolling, MIDI latency or interaction.
```

**Prompt review C:** the touch shelf and lower pattern field provide a different silhouette from A/B. The broad display face is used only for short headings and peripheral tempo; rhythm text prioritises distinguishable hands/counts. Library has horizontal category selection and flat lesson rows. The main risk is the top shelf growing into a toolbar dashboard: keep it shallow and inspect portrait spacing.

## AI-look audit and acceptance checklist

This is a manual review of the **written prompts** against every item in the current brief. It is not a pass result for images that have not yet been generated. Each self-contained prompt repeats its rejection conditions so the rules survive copying into a fresh image conversation.

| Brief reject item | A — Folio: checked instruction | B — Tape: checked instruction | C — Bench: checked instruction |
| --- | --- | --- | --- |
| Purple/blue-violet gradients, mesh gradients, neon | Exactly three solid colours; all gradients/glow forbidden | Same, with explicit no-HUD/no-neon rule | Same, with no haze/fade masks |
| Glassmorphism / blur cards | Opaque sheet and flat orange field | Flat tape and page-colour spine | Flat field and shallow touch shelf |
| Uniform rounded cards with soft shadows | Open inline contents; square notation blocks | One orange data field; unboxed index/list | Open rows; no covers or floating cards |
| Emoji / untouched default SF Symbols | Described custom instrument contours; text navigation | Same glyph vocabulary; labelled tools | Same vocabulary; text-led shelf |
| Default system font without a decision | Fraunces + Source Sans 3, roles stated | Space Grotesk + IBM Plex Sans, roles stated | Bricolage + Atkinson Hyperlegible Next, roles stated |
| Centred hero plus three feature cards | Compact heading; stacked exercise sheet | Compact header; timing field and spine | Compact identity line; large low practice field |
| Same corner radius everywhere | 0 pt pattern/rows; 8 pt transport; timing ring | 0 pt pattern/rows; 4 pt transport; timing ring | 0 pt pattern/rows; 12 pt transport; timing ring |
| Fake 3D | No paper/binding effects or shadows | No reels, metal or terminal costume | No bevels or hardware simulation |

Additional prompt checks performed:

- **Hierarchy:** every Play request makes the orange grid primary; there is no large tempo column, standalone cue hero, diagnostic dashboard or obligatory pad bank. BPM, score and timing feedback stay peripheral.
- **Rhythm semantics:** exact 16-step labels, heavier beat starts, one used pad per row, glyph plus L/R in occupied cells, aligned simultaneous hits and a shared two-bar fixture are specified in all three prompts.
- **Static versus scrolling:** moving position inside a fixed short pattern is separate from a fixed hit marker with a translating time viewport. Fixed row labels and unclipped hand labels are explicit.
- **Length coverage:** each prompt covers 1, 2, 3, 4 and more than 4 bars; an eight-bar overview has defined segments and a page/viewport outline. No fictitious fourth bar fills a three-bar exercise.
- **Themes:** six image IDs per direction provide static Play, scrolling Play and Library in both themes. Orange/black pattern ink stays constant; white/black page ink swaps. No semantic colour system is carried over from the previous delivery.
- **State stability:** fixed control/feedback footprints, closed on-demand surfaces, explicit Tools access and one-touch paths are specified. No state-dependent layout shift or decorative motion is requested.
- **Content honesty:** lesson/category names, 80 BPM, 92% and pattern notes are comparison samples. Only the Intro count of 24 comes from SPEC §3.8. No other category totals, achievement data or progress history is invented. Locked Rock stays tappable for soft unlock, as required by SPEC.
- **Distinctness:** sheet versus right-spine tape versus top-shelf bench remains visible without colour or typography. The styles are not three dark condensed-font skins.
- **Generation QA still required:** inspect all 18 generated images for actual colour drift, glyph/hand omissions, count corruption, clipping, text size, safe areas and frame consistency. Re-render any failing image individually. Check at arm's length and with the chosen four-bar/dense example before choosing a direction. Image generation may only approximate the named fonts.

No automated design-skill scripts, browser inspection workflow, app code, build or tests were run for this prompt-only task. Source mockups were inspected using local Quick Look previews and source reading, not a browser validation workflow.

## Reference review and skill application

The task explicitly authorises reading the legacy reference folders. No legacy code, styles or files are copied into the native application.

| Local reference inspected | What informed the prompts | What is not carried over |
| --- | --- | --- |
| `2026-10-07-navrh-vzhledu/2026-10-07-navrh-A-noc.html` | Density of navigation and practice metadata | Left icon rail, yellow glow, large next-step card, statistics |
| `2026-10-07-navrh-vzhledu/2026-10-07-navrh-B-papir.html` | Readable grouping and open reading order | Cream ground, hero card, decorative circle, training cards |
| `2026-10-07-navrh-vzhledu/2026-10-07-navrh-C-hardware.html` | Beat grouping and simultaneous-row alignment | Multicolour role accents, glow, simulated display panel |
| `2026-10-28-Smack-a-Pad-ipad/mockupy/2026-10-03-porovnani.html` and the `illustrated-tile`, `kit-map`, `line-glow` HTML files | Recognisable instruments and relationship between grid and pad meanings | Mandatory 4 × 4 pad bank, coloured role styling, tiny diagnostics, large transport panel |
| `mockupy/2026-10-11-denni-trenink.html` | Difference between a main action and subordinate information | Daily-training dashboard, completion cards and progress badges |
| `mockupy/2026-10-12-cviceni-c.html` | Source defines 1/2/4/32-bar examples, count grid and hidden detail controls | Dense top controls, multiple dark panels, tiny labels and coloured hands |
| `mockupy/2026-10-03-pad-instruments.svg` | Custom kick/snare/hat contours and instrument distinctions | Full shaded illustrations and colour/opacity treatment |

Both reference folders are under `/Users/kju/AI COWORK/Smack-a-Pad/Smack-a-Pad/`. Quick Look displayed the A/B/C and pad-design previews; the dynamic October 12 exercise rendered blank there and was inspected in source. The SVG is a symbol collection, so its standalone preview is blank; the drawings were inspected in its source and in the pad-design HTML previews. No browser-based interaction validation is claimed.

| Rules read | Applied here | Overridden or inapplicable for this ticket |
| --- | --- | --- |
| `.agents/skills/imagegen-frontend-mobile/SKILL.md` | Explicit platform, consistent design bible, coherent flow, standalone screens, safe areas, readable type, custom glyphs, rejection checks | Ticket 10 requests prompts for Jakub to generate; phone framing becomes iPad framing. Decorative textures/photos, extra palette choices and screen-generation eagerness do not override the brief. |
| `.agents/skills/design-taste-frontend/SKILL.md` and `references/app-screens.md` | Main task determines hierarchy; colour on the product's rhythm data; flat surfaces; equal edges; honest sample content; deliberate type; no generic card dashboard | AGENTS.md requires rules only: no scripts or browser steps. Desktop-dashboard colour-share/type defaults do not override the dominant orange grid or arm's-length iPad labels. Functional grid rules and actual bar numbers are data, not decorative hairline/index costume. |
| `.agents/skills/gpt-taste/SKILL.md` | Different compositions, no arbitrary badges, readable controls, no broken grid arithmetic or accidental voids | No UI code is being written. AIDA website structure, mock randomisation, GSAP, hover physics, bento cards, stock photos, blurs and gradients contradict this practice instrument or have no role in prompts. None is used. |

## Font embedding sources

The following licence files were checked on 2026-10-30. All six families are distributed under SIL Open Font License 1.1, which permits embedding with software subject to its conditions. Carry the copyright and licence notices with the exact font files when fonts are bundled later; no font binaries or app configuration are added in this ticket.

| Direction | Display licence | Text licence |
| --- | --- | --- |
| A | [Fraunces OFL](https://raw.githubusercontent.com/google/fonts/main/ofl/fraunces/OFL.txt) | [Source Sans 3 OFL](https://raw.githubusercontent.com/google/fonts/main/ofl/sourcesans3/OFL.txt) |
| B | [Space Grotesk OFL](https://raw.githubusercontent.com/google/fonts/main/ofl/spacegrotesk/OFL.txt) | [IBM Plex Sans OFL](https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexsans/OFL.txt) |
| C | [Bricolage Grotesque OFL](https://raw.githubusercontent.com/google/fonts/main/ofl/bricolagegrotesque/OFL.txt) | [Atkinson Hyperlegible Next OFL](https://raw.githubusercontent.com/google/fonts/main/ofl/atkinsonhyperlegiblenext/OFL.txt) |

## Decision handoff

Choose A, B or C after comparing the six images for that direction, then request its four-bar and dense-pad adaptations if they are not already generated. The first test is whether the orange grid explains the next simultaneous pads and hands at arm's length in both themes. The second is whether Library reaches that exercise without competing visual machinery. Native implementation and real-iPad validation are later work.
