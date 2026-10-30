# Direction B (Cut Tape) — Home and Result image prompts

Date: 2026-10-30. Supplements `DIRECTIONS.md` (images B1–B6). For ticket "UX Flow: Home, Library Layout, Lesson Result".

Procedure: use the SAME conversation in which B1–B6 were generated, so the design system carries over. Request one image per turn, in order B7, B8, B9, B10. Never a board or collage. All numbers are illustrative.

## Copy-ready prompt (B7–B10)

```text
Continue the Smack-a-Pad direction B (CUT TAPE) set with four more separate
images, same iPad framing, device scale, safe areas, margins, type and
palette as B1–B6. Only #FF6B00, #000000, #FFFFFF. Light page white with
black ink, dark page black with white ink; orange field with black ink in
both. No greys, gradients, shadows, status colours, emoji, mascots,
confetti, photos, rounded card grid. No white text on orange. Same compact
top identity line, same 88 pt right spine in the page colour, Space Grotesk
Medium for headings and numbers, IBM Plex Sans for text, 32 pt margins,
16 pt gaps, square pattern corners, 4 pt transport radius, unboxed rows.

B7 — HOME, LIGHT
Right spine = navigation: Home (selected: black side bracket + medium
weight), Library, Intro, Progress, Settings; each target at least 56 pt.
Main area, top: one orange field (same proportion as the Play field, but
about 40% of the height) holding a static ONE-bar preview of “Basic groove”
(Hat, Snare, Kick rows, 16 columns, counts 1 e & a 2 e & a 3 e & a 4 e & a,
glyph + L/R in each hit, no position marker). To its left inside the page
colour, a short heading “Continue”, below it “Basic groove · Electronic ·
80 → 100 BPM · best 92%” and a large black-on-white “Continue” button at
least 56 pt high (page ink fill, page colour text). Below the orange field,
two open columns, no cards:
 left, “This month”: a calendar of days 1–31 as an aligned number grid; a
 practised day is marked by a filled black square, today by a bracket,
 unpractised days are plain numbers. Under it “Streak 4 days · best 9”.
 right, “Progress”: aligned text rows with a thin black bar each:
 Electronic 3 / 5 passed, Funk 0 / 5, Rock “Locked” with a flat lock icon;
 then a row “Next up: Offbeat hats” with an “Open” action and a separate
 row “Intro — 24 exercises” with an “Open” action.
No hero banner, no carousel, no level badge, no stars, no three-card row.

B8 — HOME, DARK
Exact B7 content and layout on a black page with white ink; the orange
field and its black glyphs unchanged; calendar marks white filled squares.

B9 — RESULT, LIGHT
A screen shown after finishing “Basic groove” at 80 BPM. Right spine
= actions instead of navigation: “Try again”, “Next: 85 BPM”, “Library”,
each at least 56 pt high, page-ink outline, no colour fill.
Main area, top: heading “Basic groove”, state line “Passed” in medium
weight (a “Mastery” state would be shown the same way, as text with a
black bracket, not as a badge). Next to it a large number “92%” in
Space Grotesk Medium, about 64 pt, in page ink.
Below, the orange field with the played two-bar pattern (same glyph +
L/R cells as Play) where every cell also carries its timing result using
the existing shapes only: hollow ring = on time, filled disc displaced
left or right of centre = early or late, small cross = miss/wrong pad.
Most cells are rings; show 3 discs and 1 cross so it reads at a glance.
Under the field, two open columns, no cards:
 left, “Breakdown”: aligned rows with a thin black bar: Perfect 61,
 Early 3, Late 2, Wrong pad 1, Best streak 28.
 right, “Last attempts”: a simple black line of six scores
 (71, 78, 80, 85, 88, 92) over a baseline, last point marked with a ring,
 and one short line “Better than your last four runs.”
No stars, no confetti, no emoji, no mood face, no coloured pass/fail.

B10 — RESULT, DARK
Exact B9 content and layout on a black page with white ink; orange field
and black glyphs unchanged; the line and bars in white.

REJECT AND REDO IF ANY APPEARS
Extra colours, status green/red, gradients, glass, equal rounded cards
with shadows, emoji, default SF Symbols, mascots, photos, confetti, stars
or level badges, hero banner or carousel, tiny text (under 18 pt),
phone UI stretched onto an iPad, missing glyphs or L/R in the pattern.
```

## Notes for the agent (ticket 17)

- Home and Result use the same visual vocabulary as Play: orange belongs to the pattern only.
- Result reuses the Play timing shapes (ring, disc, cross); no new colours for good/bad.
- Pass and mastery are shown as text states, not stars (SPEC has no star thresholds).
