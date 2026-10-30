# Visual Directions — Smack-a-Pad iPad

Three distinct visual directions for Jakub to generate in Gemini or ChatGPT. Each direction has a design bible and two image prompts (play screen + library screen).

**Context for all directions:**
- iPad app, landscape orientation, on a stand next to a MIDI controller.
- Viewed from arm's length — big type, high contrast, dark theme.
- Finger-drumming trainer. Hardware feel, not gamified. Calm, confident, a bit raw.
- No purple/blue gradients, no glassmorphism, no identical card grids, no emoji/SF Symbols, no default system font, no centered-hero-three-cards, no uniform corner radii, no fake 3D.

---

## Direction 1: "Studio Hardware"

### Design Bible

| Property | Value |
|---|---|
| Feel | Like the built-in screen of a high-end drum machine — Elektron Digitakt, Ableton Push, or a mixing console display. Technical, precise, confident. |
| Base colour | Anthracite `#111114` |
| Accent colour | Warm amber `#E8A824` (like hardware LED indicators) |
| Good / hit status | Muted leaf green `#4A8C50` |
| Miss status | Signal red-orange `#D85A48` |
| Text colour | Cool off-white `#E0E0E4` for primary, `#8A8A90` for secondary |
| Display typeface | **Space Grotesk** (Bold/Medium, OFL license — free to embed) |
| Body typeface | **Inter** (Regular/Medium, OFL license) |
| Texture | Ultra-subtle brushed-aluminum noise on panel areas, otherwise matte dark |
| Corner radii | Sharp (2px) on data readouts, medium (8px) on interactive buttons, no radius on section panels |
| Icons | Custom minimal line icons, technical/geometric, consistent 1.5px stroke, monochrome white |
| Decorative elements | Thin horizontal rule separators between sections, tiny dot-grid micro-pattern on section headers |
| Structure | List-led utility layout, horizontal data strips, no floating cards |
| Motion cues | Precise amber highlight pulse on hit feedback, smooth numeric counter transitions |

### Prompt 1A — Play Screen

```
Premium iPad app screen concept, landscape orientation, shown inside a clean
subtle iPad mockup with visible frame. Dark theme finger-drumming practice app
called "Smack-a-Pad".

PLAY SCREEN — the primary screen, designed for glancing at from arm's length.

Background: deep anthracite (#111114), matte with ultra-subtle brushed-metal
noise texture. No gradients, no glow.

Layout (landscape, left to right):
— LEFT PANEL (≈30% width): Pattern display. A vertical list of upcoming pad
  hits as large text labels (pad names like "Kick", "Snare", "Hi-Hat" in cool
  off-white). The next hit is highlighted with a warm amber (#E8A824) background
  strip. Past hits are dimmed. Clean left-aligned text, Space Grotesk Bold,
  generous line spacing. Feels like a teleprompter / hardware sequencer readout.

— CENTER AREA (≈45% width): Timing feedback zone. A wide horizontal bar with a
  center marker — hits land on this bar as coloured dots: green (#4A8C50) near
  center = good timing, amber at center = perfect, red-orange (#D85A48) far from
  center = miss. Below the bar: large BPM readout in Space Grotesk Bold, ≈48pt,
  amber accent. Below that: score percentage in off-white, ≈32pt.

— RIGHT PANEL (≈25% width): Small optional pad-layout thumbnail — a 4×4 grid of
  small squares showing which pads are used (used pads in amber outline, unused
  in dark grey). Below: current lesson title in Inter Medium, muted text.

Top bar: minimal — thin horizontal rule, lesson category tag in small caps
(Inter Medium, muted), a back arrow icon (line style, 1.5px stroke).

Bottom: nothing. Clean. No tab bar. Player is focused on the pads, not the screen.

Typography: Space Grotesk for display elements (BPM, score, pad names), Inter
for secondary labels. Technical, not decorative. Clear hierarchy.

Overall feel: like looking at the screen of a professional drum machine. Clean,
precise, industrial. Not a game, not a SaaS dashboard. Hardware confidence.

No purple, no blue gradients, no glassmorphism, no neon glow, no emoji, no
default SF Symbols, no system font, no fake 3D.
```

### Prompt 1B — Library Screen

```
Premium iPad app screen concept, landscape orientation, shown inside a clean
subtle iPad mockup with visible frame. Same app as the play screen: dark theme
finger-drumming trainer "Smack-a-Pad". Same design system.

LIBRARY SCREEN — browsing lessons by category.

Background: deep anthracite (#111114), same matte brushed-metal noise texture.

Layout (landscape):
— LEFT SIDEBAR (≈22% width): Vertical list of category names, left-aligned.
  Categories: Starter, Eighth, Sixteenth, Electronic, Ghost, Swing, World,
  Fills. Each is a text row in Space Grotesk Medium, off-white. The selected
  category has an amber (#E8A824) left border accent (3px vertical line) and
  slightly brighter text. Locked categories have a small minimal lock icon
  (line style, 1.5px) to the right of the name in muted grey. At the top of
  the sidebar: "Intro" as a separate section link. Clean thin horizontal rules
  between groups.

— MAIN AREA (≈78% width): A scrollable list of lessons in the selected category.
  Each lesson is a horizontal row (not a card — no shadow, no border, just a
  row separated by thin rules). Row contains: lesson title (Inter Medium,
  off-white, left), genre tag (small caps, muted, Inter), difficulty dots
  (1–5 small squares, amber = filled, dark grey = empty), pass/mastery status
  (a small green checkmark for passed, a small amber star for mastery, or
  nothing). Right side: start BPM → target BPM in muted Inter text.

  Section header at top of list: category name in Space Grotesk Bold, ≈28pt,
  with a dot-grid micro-pattern decorative accent to the right.

Top bar: app name "Smack-a-Pad" in Space Grotesk Bold, left-aligned, small. A
settings gear icon (custom line icon, 1.5px stroke) at the far right.

Bottom: no tab bar. Navigation is through the sidebar.

Overall feel: clean list utility — like browsing presets on hardware. Efficient,
scannable, technical. Not a colourful app store, not a game menu.

Same type system, same palette, same texture as the play screen. One unified
product. No purple, no blue gradients, no glassmorphism, no card grid, no emoji.
```

---

## Direction 2: "Matte Ink"

### Design Bible

| Property | Value |
|---|---|
| Feel | Stark, minimal, high-contrast. Inspired by Japanese record sleeve design and letterpress printing. Deliberate emptiness. Every element earns its place. |
| Base colour | Near-black `#0B0B0F` |
| Accent colour | Vermillion / cinnabar `#D44527` (like a seal stamp or record label centre) |
| Good / hit status | Desaturated teal `#4A9E8E` |
| Miss status | Soft rose `#C45B5B` |
| Text colour | Warm parchment white `#F0E8DC` for primary, `#6B6760` for secondary |
| Display typeface | **DM Serif Display** (OFL license — free to embed) |
| Body typeface | **DM Sans** (Regular/Medium, OFL license) |
| Texture | Soft paper/film grain over dark surfaces, like matte photographic paper |
| Corner radii | Mostly square (0–2px), only 4px radius on interactive buttons |
| Icons | Filled minimal glyphs, monochrome warm-white, custom, weighty |
| Decorative elements | Abstract arc lines (like vinyl record grooves), thin dotted guide lines |
| Structure | Editorial layout — bold serif headlines, generous whitespace, strong typographic hierarchy |
| Motion cues | Soft fade transitions, sheet-rise energy on screen changes |

### Prompt 2A — Play Screen

```
Premium iPad app screen concept, landscape orientation, shown inside a clean
subtle iPad mockup with visible frame. Dark theme finger-drumming practice app
called "Smack-a-Pad".

PLAY SCREEN — designed for glancing at from arm's length during practice.

Background: near-black (#0B0B0F) with a subtle matte paper-grain texture, like
dark photographic paper. No gradients, no glow, no mesh.

Layout (landscape):
— LEFT SIDE (≈35% width): The next hit displayed very large — pad name (e.g.
  "Snare") in DM Serif Display, ≈72pt, warm parchment white (#F0E8DC). Below
  it: hand indicator "R" or "L" in DM Sans Medium, smaller, vermillion accent
  (#D44527). Below that: a short vertical sequence of upcoming 3–4 hits as
  smaller text (DM Sans, ≈20pt, muted #6B6760), fading downward. Feels like
  reading a poem — one big word, then the next lines.

— RIGHT SIDE (≈40% width): Timing feedback as a large vertical arc — a thin
  semicircular arc line (like a vinyl record groove). Hits appear as dots on
  the arc: centre = on time (teal #4A9E8E), above/below = early/late, far out
  = miss (rose #C45B5B). The arc is rendered in a thin muted line (#2A2A2E)
  with hit dots overlaid. Clean, abstract, beautiful.

— TOP RIGHT CORNER: BPM in DM Serif Display, ≈56pt, warm white. Score
  percentage below in DM Sans, muted.

— BOTTOM RIGHT: Small pad-layout thumbnail — 4×4 grid of tiny squares, active
  pads outlined in vermillion, inactive in dark grey. Very small, optional.

Top bar: ultra-minimal. A thin line, lesson title in DM Sans small caps, muted.
A single back arrow glyph (filled, warm-white).

Bottom: empty. Dark. Clean.

Overall feel: stark, editorial, almost typographic poster quality. Like a
beautifully printed record sleeve turned into a practice interface. High
contrast, deliberate emptiness, every element matters.

No purple, no blue gradients, no glassmorphism, no neon, no emoji, no default
SF Symbols, no system font, no fake 3D. No cards, no shadows.
```

### Prompt 2B — Library Screen

```
Premium iPad app screen concept, landscape orientation, shown inside a clean
subtle iPad mockup with visible frame. Same app: dark theme finger-drumming
trainer "Smack-a-Pad". Same design system as the play screen.

LIBRARY SCREEN — browsing lessons by category.

Background: near-black (#0B0B0F), same matte paper-grain texture.

Layout (landscape):
— TOP AREA: Large category name as a dramatic headline — e.g. "Sixteenth" in
  DM Serif Display, ≈64pt, warm parchment white (#F0E8DC), left-aligned with
  generous top margin. A thin abstract arc line (like a vinyl groove) sweeps
  from the right side of the headline toward the right edge, decorative but
  restrained. Below the headline: a thin dotted guide line separating the
  header from content.

— CATEGORY NAVIGATION: A horizontal row of category names below the headline —
  Starter, Eighth, Sixteenth, Electronic, Ghost, Swing, World, Fills — in
  DM Sans Medium, ≈14pt. Selected category in warm white with a vermillion
  (#D44527) underline. Others in muted (#6B6760). Locked categories have a
  small filled lock glyph next to them. Clean horizontal scroll if needed.

— LESSON LIST (below): Lessons as clean horizontal rows, no card borders, no
  shadows. Each row: lesson title (DM Sans Medium, warm white, left-aligned),
  genre (DM Sans, muted, italic), difficulty shown as 1–5 small vermillion
  dots (filled = level, empty outline = remaining), pass/mastery shown as a
  small teal checkmark or vermillion star. Rows separated by ultra-thin lines
  (#1A1A1E). Right side of each row: BPM range in muted text.

— INTRO SECTION: Accessible via a separate "Intro" label at the left end of
  the category row, set apart with a thin vertical divider.

Top right: settings icon (filled glyph, warm-white) and app name "Smack-a-Pad"
in DM Serif Display, small.

Overall feel: editorial, like a beautifully typeset table of contents in a
premium publication. Stark, readable, high-contrast. The serif headlines give
it gravitas. The generous whitespace gives it calm.

Same palette, same grain, same type system as the play screen. Unified product.
No purple, no blue gradients, no glassmorphism, no card grid, no emoji.
```

---

## Direction 3: "Felt & Copper"

### Design Bible

| Property | Value |
|---|---|
| Feel | Warm, tactile, like a vintage practice room. Leather drum throne, felt-topped surfaces, copper-trimmed gear. Analogue warmth in a digital tool. Not retro kitsch — refined, modern warmth. |
| Base colour | Warm dark `#141210` (slightly brown-black, not pure black) |
| Accent colour | Aged copper `#C47D3E` (warm, metallic-feeling without being shiny) |
| Good / hit status | Sage green `#6B8E6B` |
| Miss status | Dusty coral `#C06050` |
| Text colour | Warm cream `#E8E0D4` for primary, `#7A7268` for secondary |
| Display typeface | **Instrument Serif** (OFL license — free to embed) |
| Body typeface | **Instrument Sans** (Regular/Medium, OFL license) |
| Texture | Tolex/felt-like matte surface with visible grain — like drum machine casing material |
| Corner radii | 6px on containers, 3px on small elements — deliberate, not uniform |
| Icons | Rounded line icons, slightly warm stroke (2px), consistent, custom feel |
| Decorative elements | Soft waveform lines (like audio oscilloscope traces), mini geometric markers (triangles, circles as section markers) |
| Structure | Card-led modular — but cards are warm panels with subtle felt texture, not floating glass |
| Motion cues | Springy card lift on tap, soft dashboard fade-up on transitions |

### Prompt 3A — Play Screen

```
Premium iPad app screen concept, landscape orientation, shown inside a clean
subtle iPad mockup with visible frame. Dark theme finger-drumming practice app
called "Smack-a-Pad".

PLAY SCREEN — designed for eyes-off glancing during practice with a MIDI
controller.

Background: warm dark (#141210, slightly brown-black) with a visible felt/tolex
grain texture — like the surface material of a vintage drum machine or amp
cabinet. Tactile, matte, warm. Not flat, not glossy.

Layout (landscape):
— LEFT PANEL (≈28% width): A warm panel area (slightly lighter, #1C1A16, same
  felt texture) containing the pattern sequence. Pad names listed vertically
  in Instrument Sans Medium, warm cream (#E8E0D4), ≈22pt. The current/next
  hit is highlighted with a copper (#C47D3E) background bar and slightly larger
  text (≈28pt). Hand indicators (L/R) shown in small Instrument Sans beside
  each pad name. A soft waveform line decoration runs along the left edge of
  the panel, like an audio oscilloscope trace, in muted (#2A2620).

— CENTER (≈45% width): Large BPM counter in Instrument Serif, ≈64pt, copper
  accent. Below: score as a percentage in Instrument Sans Medium, ≈36pt, warm
  cream. Below that: timing feedback as a horizontal strip with a centre
  notch — hits appear as small circles: sage green (#6B8E6B) near centre, dusty
  coral (#C06050) far from centre. The strip has subtle tick marks like a
  ruler/VU meter. Clean, functional, warm.

— RIGHT PANEL (≈27% width): Pad layout as a 4×4 grid of small rounded squares
  (6px radius). Active pads have a copper outline and the pad name inside
  (Instrument Sans, tiny, cream). Inactive pads are dark (#1C1A16) with no
  text. Below: lesson info — title in Instrument Sans, genre tag with a small
  geometric triangle marker (▸) in copper.

Top bar: thin, warm. Lesson category in Instrument Sans small caps, muted.
Back arrow as a rounded line icon (2px stroke, cream). Right side: a small
metronome icon (custom, rounded).

Bottom: empty, warm dark felt surface.

Overall feel: warm, tactile, analogue. Like practising in a well-loved studio
with nice gear. The felt texture and copper accents give it physical presence.
Not cold, not clinical, not gamified. Refined warmth.

No purple, no blue gradients, no glassmorphism, no neon, no emoji, no default
SF Symbols, no system font, no fake 3D, no same corner radius everywhere.
```

### Prompt 3B — Library Screen

```
Premium iPad app screen concept, landscape orientation, shown inside a clean
subtle iPad mockup with visible frame. Same app: dark theme finger-drumming
trainer "Smack-a-Pad". Same design system as the play screen.

LIBRARY SCREEN — browsing lessons by category.

Background: warm dark (#141210), same felt/tolex grain texture.

Layout (landscape):
— LEFT SIDEBAR (≈24% width): A warm panel (#1C1A16, felt texture) with category
  list. Each category is a modular block — category name in Instrument Serif,
  ≈20pt, warm cream. Below each name: a tiny progress indicator (e.g. "3/5
  passed" in Instrument Sans, muted #7A7268). Selected category has a copper
  (#C47D3E) left accent bar (4px wide, rounded ends) and warmer background.
  Locked categories show a rounded lock icon (2px stroke, muted) and slightly
  dimmed text. A small geometric circle marker (●) in copper marks the current
  category. Intro section at the top, separated by a soft waveform line
  decoration.

— MAIN AREA (≈76% width): Lessons displayed as warm horizontal rows inside a
  subtle panel. Each lesson row has:
  - Title in Instrument Sans Medium, warm cream, left-aligned
  - Genre tag in Instrument Sans, muted, with a small triangle marker (▸)
  - Difficulty as 1–5 small filled/outlined circles (copper filled, dark outlined)
  - Status: sage green checkmark (passed) or copper star (mastery)
  - BPM range on the right in muted text
  Rows separated by very thin lines (#221F1B). Generous vertical padding
  between rows — not cramped, easy to tap.

  Section header: category name in Instrument Serif, ≈32pt, copper accent.
  A mini geometric marker row (▸ ▸ ▸) as a decorative accent below the header.

Top bar: "Smack-a-Pad" in Instrument Serif, small, left. Settings icon (rounded
line, 2px stroke, cream) right. A soft waveform line runs along the bottom edge
of the top bar as a subtle decorative separator.

Overall feel: like browsing a well-organised vinyl collection in a warm room.
The felt texture and copper accents create physical warmth. The serif headlines
add character. Generous spacing, easy to read at arm's length.

Same palette, same texture, same type system as the play screen. Unified product.
No purple, no blue gradients, no glassmorphism, no card grid with identical
shadows, no emoji, no same corner radius everywhere.
```

---

## Summary

| | Direction 1: Studio Hardware | Direction 2: Matte Ink | Direction 3: Felt & Copper |
|---|---|---|---|
| Inspiration | Drum machine displays, mixing consoles | Japanese record sleeves, letterpress | Vintage practice room, analogue gear |
| Base | Anthracite `#111114` | Near-black `#0B0B0F` | Warm dark `#141210` |
| Accent | Warm amber `#E8A824` | Vermillion `#D44527` | Aged copper `#C47D3E` |
| Good | Green `#4A8C50` | Teal `#4A9E8E` | Sage `#6B8E6B` |
| Miss | Red-orange `#D85A48` | Rose `#C45B5B` | Coral `#C06050` |
| Display font | Space Grotesk (OFL) | DM Serif Display (OFL) | Instrument Serif (OFL) |
| Body font | Inter (OFL) | DM Sans (OFL) | Instrument Sans (OFL) |
| Texture | Brushed metal noise | Paper/film grain | Felt/tolex grain |
| Structure | List-led, technical | Editorial, typographic | Card-led, warm |
| Temperature | Cool, precise | Neutral, stark | Warm, tactile |
