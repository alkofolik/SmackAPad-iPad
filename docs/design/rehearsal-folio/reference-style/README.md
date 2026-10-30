# A1 revision — reference screenshot style

## Brief

The user rejected A1–A3 and requested a new A1 using the original layout and UI, but the graphic style of the supplied Smack-a-Pad screenshot. The user explicitly requested both an image and a short animation.

The new direction uses compact condensed display typography, technical supporting text, sharp black rules, white right-hand hit tiles and black left-hand hit tiles. Each hit retains its instrument glyph and R/L letter. These graphic choices intentionally replace the original Fraunces/Source Sans treatment and all-black unboxed hit symbols. The reference screenshot supplies graphic direction only; its desktop navigation, large BPM, goals, pad bank and different lesson data are not copied.

## Deliverables

- A1-reference-style.png: 2732 × 2048 px still at bar 2, step 5 (beat 2), with simultaneous Hat R and Snare L unobscured.
- A1-reference-style-motion.gif: 1200 × 900 px silent six-second repeating demonstration, 48 encoded frames after duplicate-frame optimization. Two four-beat bars at 80 BPM.
- A1-clean-plate.png: generated background, 1449 × 1086 px. The large PNG enlarges this raster and adds cursor/bracket/feedback overlays at export resolution; it does not add native detail to generated type or icons.
- style-reference.png: the user's supplied screenshot, preserved for this concept.
- render-animation.cjs: standalone concept export source. No application source files were changed.

## Motion

Both bars and all controls stay fixed. The marker steps along subdivision boundaries, then moves to the second bar. A small external bracket follows the current bar. Played tiles receive a brief black/white outline; the on-time ring thickens briefly on a hit. Glyphs and hand letters remain visible. The motion is illustrative and does not validate production MIDI, scoring or playback behaviour. GIF frame timing is quantized for presentation.

## Inspection

Both bars visually contain 16 steps with counts 1 e & a 2 e & a 3 e & a 4 e & a. Hat R occupies odd steps; Snare L occupies 5 and 13; Kick L occupies 1 and 9 in bar 1, and 1, 9 and 11 in bar 2. The still's active position is bar 2 step 5. Decoded GIF frames at the start and 3.75 seconds were visually inspected: the active bar and cursor differ while the interface remains fixed. Encoded duration is 6000 ms and loop count is infinite. Generated device highlights, exact glyph contour details and font identity remain concept artwork rather than a verified native UI specification. Older concepts are preserved in their original files.

## Image generation prompt

Built-in image generation tool; screenshot supplied as a style reference.

Use case: ui-mockup. Create a NEW A1 PLAY STATIC LIGHT iPad screen concept for Smack-a-Pad. The attached screenshot is ONLY the GRAPHIC STYLE reference, never its layout, content, controller mapping or rhythm. The user rejected previous concepts. Make this feel like the attached bold black/white/orange rehearsal instrument, with crisp rectangular hit blocks, compact condensed display type and technical supporting text. Do not reproduce the reference's giant heading, giant BPM, bottom dashboard, goals, stars, pad bank or desktop navigation.

ONE front-on landscape4:3 iPad with thin solid black bezel and equal white outer margins. Entire device visible, no perspective, room,props,hands,shadow. White page, black ink, vivid solid#FF6B00 orange field. High-resolution target screen2732×2048px representing1366×1024pt.

ORIGINAL A1 LAYOUT stays: compact quiet header with “Library” left, compact “Basic groove” lesson heading near left, “MIDI connected” right. Heading condensed heavy black as STYLE reference, but compact32pt only. Supporting typography crisp technical monospace20–24pt like reference, essential18pt minimum; no serif fonts. Next shallow row “Static / Scrolling” with black underline selecting Static; small peripheral “80 BPM” far right.40pt outer content margins,16pt gaps.
Broad inset ORANGE field across middle, square corners, about60% usable page height. Exactly TWO complete bars stacked in reading order, each OWN “Bar 1”/“Bar 2” label, OWN count row and OWN three pad rows with repeated left labels. Do not show a third/fourth empty bar. All16steps in each bar stay visible.

GRAPHIC STYLE WITHIN THE FIELD: reference-like sharp rectangular HIT TILES rather than loose oversized floating drum drawings. RIGHT-hand Hat hits are solid WHITE square/rectangular tiles, containing BLACK hat contour glyph and R, stacked. LEFT-hand Snare/Kick hits are solid BLACK tiles, containing WHITE respective drum contour glyph and L, stacked. Keep hit tiles safely inside cells with a small gap, no round corners, no shadows. Tile sizes consistent across instruments. This black/white tile language deliberately replaces the previous all-black line-art rendering, per user's new style instruction.
Empty cells have only orange background, no tiny dots or symbols. Thin black subdivision rules, heavier beat-start rules, all equal widths. Row-label gutter outside16timecolumns: Hat,Snare,Kick, with compact corresponding glyph beside each word. Hat glyph two close cymbal contours; Snare shallow wire drum; Kick concentric drum rings with small off-centre port. Same custom glyph per instrument in label and tiles. Never substitute OH/HH/SN/KD abbreviations, finger numbers or mappings. Every occupied tile MUST contain BOTH symbol and correct R/L hand. Three pad rows only per bar.

EXACT RHYTHM: Each bar has precisely16equal columns with count labels centered exactly:
1 e & a 2 e & a 3 e & a 4 e & a
Organize FOUR equal beat groups, FOUR equal columns each. No extra columns.
Bar1 HatR: steps1,3,5,7,9,11,13,15.
Bar1 SnareL: steps5,13.
Bar1 KickL: steps1,9.
Bar2 HatR: steps1,3,5,7,9,11,13,15.
Bar2 SnareL: steps5,13.
Bar2 KickL: steps1,9,11.
All other cells empty. The simultaneous HatR+SnareL at step5 must be exactly vertically aligned in each bar. Bar2 step11 extraKickL aligns with its HatR at count& of beat3. Do not invent any notes.

ANIMATION-READY CLEAN PLATE: Do NOT bake any time cursor, pointer, active-cell outline or active-bar bracket into this image. The still and short animation will receive precisely positioned moving overlays afterward. Leave exact clean grid boundaries. This is the only deliberate departure from original A1's current-position still; do not change any other UI. All hit tiles visible at rest. No motion blur or arrows.

BELOW orange field: compact black timing rail, center notch and centered hollow ring, label “On time”, empty reserved miss slot. Small peripheral“92%” at far right. Feedback never green/red.
BOTTOM LEFT: compact black “Pause” button with white text and pause symbol,56pt target,8ptcorner. Adjacent “Stop” black label with small square; same56pttarget. BOTTOM RIGHT “Tools” text action,44pttarget, CLOSED. Do not expose pads, scoring panels, settings or loop. Preserve bottom home indicator safe area.

Match reference's flat graphic discipline, black typography, orange stage, white right-hand tiles, black left-hand tiles and firm rules. Avoid cream/grey designed surfaces, texture, gradients, glow,neon,rounded cards,serif,photographic lighting,stock icons or extraUI. Do not include the reference lesson name,120BPM,93%,stars or desktop header. This is ONLY Basic groove,80BPM,92%, two bars in ORIGINAL A1 UI. Verify all16columns and all R/L pairs before final.

