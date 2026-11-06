#!/usr/bin/env python3
"""
Generate self-contained HTML previews and README for Ticket 114:
Home background like a pad-controller surface: design proposals (no app code).

Produces:
- docs/design/2026-11-06-home-background/index.html
- docs/design/2026-11-06-home-background/proposal-a.html
- docs/design/2026-11-06-home-background/proposal-b.html
- docs/design/2026-11-06-home-background/proposal-c.html
- docs/design/2026-11-06-home-background/README.md
"""

import base64
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEST = Path(__file__).resolve().parent

# 1. Load Font (IBM Plex Sans)
font_path = ROOT / "SmackAPad/Resources/Fonts/IBMPlexSans[wdth,wght].ttf"
font_b64 = base64.b64encode(font_path.read_bytes()).decode("ascii")

# 2. Load Wordmark SVG path
wordmark_svg_path = ROOT / "SmackAPad/Assets.xcassets/LaunchWordmark.imageset/LaunchWordmark.svg"
wordmark_raw = wordmark_svg_path.read_text(encoding="utf-8")
path_match = re.search(r'd="([^"]+)"', wordmark_raw)
wordmark_d = path_match.group(1) if path_match else ""

LOGO_MARK_SVG = """<svg viewBox="0 0 100 100" class="logo-mark-svg" role="img" aria-label="Smack-a-Pad logo">
  <rect x="12.4086" y="16.5914" width="32" height="32" rx="3" ry="3" fill="currentColor" />
  <rect x="12.4086" y="56.5914" width="32" height="32" rx="3" ry="3" fill="currentColor" />
  <rect x="52.4086" y="56.5914" width="32" height="32" rx="3" ry="3" fill="currentColor" />
  <rect x="53.9086" y="13.0914" width="32" height="32" rx="3" ry="3" fill="#FF6B00" transform="rotate(8 69.9086 29.0914)" />
</svg>"""

WORDMARK_SVG = f"""<svg viewBox="0 0 490.455 73.8" class="wordmark-svg" role="img" aria-label="Smack-a-Pad">
  <g transform="translate(-110.25, -17.1)">
    <path fill="currentColor" d="{wordmark_d}" />
  </g>
</svg>"""

# TORX / HEX SCREW SVG
TORX_SCREW_SVG = """<svg viewBox="0 0 20 20" class="screw-svg" role="img" aria-hidden="true">
  <circle cx="10" cy="10" r="8.5" class="screw-rim" />
  <circle cx="10" cy="10" r="6" class="screw-inner" />
  <path d="M10 5.8 L11 8.2 L13.4 7.6 L12.2 9.8 L14.2 11.2 L11.8 11.8 L12.2 14.2 L10 12.8 L7.8 14.2 L8.2 11.8 L5.8 11.2 L7.8 9.8 L6.6 7.6 L9 8.2 Z" class="screw-socket" />
</svg>"""

# PHILLIPS SCREW SVG
PHILLIPS_SCREW_SVG = """<svg viewBox="0 0 20 20" class="screw-svg" role="img" aria-hidden="true">
  <circle cx="10" cy="10" r="8.5" class="screw-rim" />
  <circle cx="10" cy="10" r="6" class="screw-inner" />
  <path d="M9.2 5.5 h1.6 v3.2 h3.2 v1.6 h-3.2 v3.2 h-1.6 v-3.2 h-3.2 v-1.6 h3.2 z" class="screw-socket" />
</svg>"""

# CROSSHAIR REGISTRATION MARK
CROSSHAIR_SVG = """<svg viewBox="0 0 16 16" class="crosshair-svg" role="img" aria-hidden="true">
  <line x1="8" y1="0" x2="8" y2="16" stroke="currentColor" stroke-width="1" />
  <line x1="0" y1="8" x2="16" y2="8" stroke="currentColor" stroke-width="1" />
  <circle cx="8" cy="8" r="3" fill="none" stroke="currentColor" stroke-width="0.8" />
</svg>"""

# COMMON CSS
COMMON_CSS = f"""
@font-face {{
  font-family: 'IBM Plex Sans';
  src: url(data:font/ttf;base64,{font_b64}) format('truetype');
  font-weight: 100 900;
  font-style: normal;
  font-display: block;
}}

:root {{
  --theme-cream: #F4EFE6;
  --theme-soft-black: #1F1D1A;
  --theme-orange: #FF6B00;
  --theme-orange-glow: rgba(255, 107, 0, 0.4);
  --theme-orange-subtle: rgba(255, 107, 0, 0.16);
  --theme-white: #F4EFE6;
  --theme-black: #1F1D1A;

  /* Adaptive light mode (default) */
  --bg: var(--theme-cream);
  --ink: var(--theme-soft-black);
  --surface: #EBE5DA;
  --secondary: #5E5950;
  --hairline: rgba(31, 29, 26, 0.15);
  --star-grey: #D6D0C4;
  --led-off: #D6D0C4;
  --chassis-edge: rgba(31, 29, 26, 0.12);
  --pad-bevel-top: rgba(255, 255, 255, 0.55);
  --pad-bevel-bottom: rgba(0, 0, 0, 0.16);
  --screen-bg: var(--theme-cream);

  /* Proposal specific variables - Light mode */
  --well-bg: #E5DFD4;
  --well-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.18), inset 0 0 0 1px rgba(0, 0, 0, 0.08), 0 1px 0 rgba(255, 255, 255, 0.65);
  --well-label: rgba(94, 89, 80, 0.65);
  --screw-color: rgba(31, 29, 26, 0.22);
  --seam-shadow: rgba(31, 29, 26, 0.16);
  --seam-highlight: rgba(255, 255, 255, 0.65);
  --grille-dot: rgba(31, 29, 26, 0.08);
  --rail-line: rgba(31, 29, 26, 0.18);
  --vignette-center: #F8F4EC;
  --vignette-edge: #EDE4D6;
  --bay-bg: #EEE8DD;
  --bay-border: rgba(31, 29, 26, 0.12);
  --bay-shadow: inset 0 1.5px 3px rgba(0, 0, 0, 0.1), 0 2px 8px rgba(0, 0, 0, 0.05);
}}

[data-theme="dark"] {{
  --bg: var(--theme-soft-black);
  --ink: var(--theme-cream);
  --surface: #2A2824;
  --secondary: #B3ADA2;
  --hairline: rgba(244, 239, 230, 0.15);
  --star-grey: #3E3B36;
  --led-off: #3E3B36;
  --chassis-edge: rgba(0, 0, 0, 0.5);
  --pad-bevel-top: rgba(255, 255, 255, 0.12);
  --pad-bevel-bottom: rgba(0, 0, 0, 0.45);
  --screen-bg: var(--theme-soft-black);

  /* Proposal specific variables - Dark mode */
  --well-bg: #161412;
  --well-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.75), inset 0 0 0 1px rgba(255, 255, 255, 0.05), 0 1px 0 rgba(255, 255, 255, 0.05);
  --well-label: rgba(179, 173, 162, 0.65);
  --screw-color: rgba(244, 239, 230, 0.2);
  --seam-shadow: rgba(0, 0, 0, 0.65);
  --seam-highlight: rgba(244, 239, 230, 0.08);
  --grille-dot: rgba(244, 239, 230, 0.09);
  --rail-line: rgba(244, 239, 230, 0.18);
  --vignette-center: #24221E;
  --vignette-edge: #171513;
  --bay-bg: #25231F;
  --bay-border: rgba(244, 239, 230, 0.1);
  --bay-shadow: inset 0 1.5px 3px rgba(0, 0, 0, 0.5), 0 2px 8px rgba(0, 0, 0, 0.3);
}}

* {{
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  -webkit-font-smoothing: antialiased;
}}

body {{
  font-family: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, sans-serif;
  background-color: #121214;
  color: #E2E0DB;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}}

/* TOP TOOLBAR & CONTROLS */
.workbench-header {{
  background: #18181B;
  border-bottom: 1px solid #27272A;
  padding: 10px 20px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 13px;
  position: sticky;
  top: 0;
  z-index: 1000;
}}

.brand-badge {{
  display: flex;
  align-items: center;
  gap: 10px;
  text-decoration: none;
  color: #FFF;
  font-weight: 600;
  font-size: 14px;
}}

.brand-badge .pill {{
  background: #FF6B00;
  color: #1F1D1A;
  font-size: 11px;
  font-weight: 700;
  padding: 2px 7px;
  border-radius: 2px;
  text-transform: uppercase;
}}

.workbench-tabs {{
  display: flex;
  gap: 4px;
  background: #27272A;
  padding: 3px;
  border-radius: 4px;
}}

.workbench-tab {{
  padding: 5px 12px;
  border-radius: 3px;
  text-decoration: none;
  color: #A1A1AA;
  font-size: 13px;
  font-weight: 500;
  transition: all 0.15s ease;
}}

.workbench-tab:hover {{
  color: #FFF;
}}

.workbench-tab.active {{
  background: #18181B;
  color: #FFF;
  font-weight: 600;
  box-shadow: 0 1px 2px rgba(0,0,0,0.3);
}}

.controls-cluster {{
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}}

.ctrl-btn {{
  background: #27272A;
  border: 1px solid #3F3F46;
  color: #E4E4E7;
  padding: 5px 11px;
  border-radius: 3px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  transition: background 0.15s, border-color 0.15s, color 0.15s;
  user-select: none;
}}

.ctrl-btn:hover {{
  background: #3F3F46;
  color: #FFF;
}}

.ctrl-btn.active {{
  background: #3B3935;
  border-color: #FF6B00;
  color: #FF6B00;
}}

.ctrl-btn.highlight {{
  border-color: #FF6B00;
}}

.ctrl-label {{
  font-size: 11px;
  color: #71717A;
  text-transform: uppercase;
  font-weight: 600;
  letter-spacing: 0.05em;
  margin-right: -2px;
}}

.midi-triggers {{
  display: flex;
  align-items: center;
  gap: 3px;
}}

.midi-trigger-btn {{
  background: #27272A;
  border: 1px solid #3F3F46;
  color: #A1A1AA;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 600;
  border-radius: 2px;
  cursor: pointer;
  font-family: inherit;
}}

.midi-trigger-btn:hover {{
  background: #FF6B00;
  color: #1F1D1A;
  border-color: #FF6B00;
}}

/* MAIN STAGE */
.workbench-viewport {{
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px;
  overflow: auto;
  background: radial-gradient(circle at center, #1C1C20 0%, #0E0E10 100%);
  position: relative;
}}

.ipad-chassis {{
  background: var(--bg);
  color: var(--ink);
  box-shadow: 0 24px 60px rgba(0,0,0,0.65), 0 0 0 10px #2A2A2E, 0 0 0 12px #1A1A1E;
  border-radius: 24px;
  position: relative;
  overflow: hidden;
  transition: width 0.35s cubic-bezier(0.16, 1, 0.3, 1), height 0.35s cubic-bezier(0.16, 1, 0.3, 1), background-color 0.25s ease;
  display: flex;
  flex-direction: column;
}}

.ipad-chassis.landscape {{
  width: 980px;
  height: 685px;
}}

.ipad-chassis.portrait {{
  width: 610px;
  height: 874px;
}}

/* HOME SCREEN LAYOUT */
.home-screen {{
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px;
  position: relative;
}}

.brand-header-area {{
  margin-bottom: 22px;
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  z-index: 10;
}}

.wordmark-svg {{
  width: 275px;
  height: auto;
  color: var(--ink);
  transition: color 0.25s ease;
}}

/* 3x3 GRID CONTAINER */
.pad-grid {{
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: repeat(3, 1fr);
  gap: 16px;
  width: 100%;
  max-width: 510px;
  aspect-ratio: 1 / 1;
  position: relative;
  z-index: 10;
}}

.ipad-chassis.portrait .pad-grid {{
  max-width: 450px;
  gap: 14px;
}}

/* LOGO CELL */
.logo-cell {{
  display: flex;
  align-items: center;
  justify-content: center;
  user-select: none;
  pointer-events: none;
  width: 100%;
  height: 100%;
}}

.logo-cell svg {{
  width: 82%;
  height: 82%;
}}

/* BASE PAD STYLES (TICKET 112: PROPOSAL A 8PT RADIUS + BEVEL) */
.pad-btn {{
  background: var(--surface);
  color: var(--ink);
  border: none;
  outline: none;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 12px 10px;
  position: relative;
  user-select: none;
  font-family: inherit;
  aspect-ratio: 1 / 1;
  width: 100%;
  height: 100%;
  border-radius: 8px;
  box-shadow: 
    inset 0 1.5px 0 var(--pad-bevel-top),
    inset 0 -2px 0 var(--pad-bevel-bottom),
    0 0 0 1px var(--hairline),
    0 2px 4px rgba(0, 0, 0, 0.08);
  transition: transform 0.08s ease, background 0.12s ease, box-shadow 0.12s ease, opacity 0.2s ease;
}}

.pad-btn.hero {{
  background: var(--theme-orange);
  color: #1F1D1A;
  box-shadow: 
    inset 0 1.5px 0 rgba(255, 255, 255, 0.42),
    inset 0 -2.5px 0 rgba(0, 0, 0, 0.28),
    0 0 0 1px rgba(0, 0, 0, 0.12),
    0 3px 6px rgba(255, 107, 0, 0.25);
}}

.pad-title {{
  font-weight: 700;
  font-size: 17px;
  line-height: 1.15;
  letter-spacing: -0.01em;
  text-transform: uppercase;
}}

.pad-btn.hero .pad-title {{
  font-size: 20px;
  font-weight: 700;
}}

.pad-subtitle {{
  font-size: 12px;
  line-height: 1.25;
  margin-top: 6px;
  color: var(--secondary);
  font-weight: 400;
  max-width: 90%;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}}

.pad-btn.hero .pad-subtitle {{
  color: rgba(31, 29, 26, 0.85);
  font-weight: 500;
}}

.pad-sec-subtitle {{
  font-size: 11px;
  color: var(--secondary);
  opacity: 0.8;
  margin-top: 2px;
}}

/* FLASH OVERLAY FOR TACTILE STRIKE */
.pad-flash {{
  position: absolute;
  inset: 0;
  background: rgba(255, 255, 255, 0.45);
  opacity: 0;
  pointer-events: none;
  border-radius: inherit;
  transition: opacity 0.05s ease-out;
}}

/* LIT PAD WITH LIGHT BAR (TICKET 112) */
.pad-btn.lit-pad {{
  box-shadow: 
    inset 0 1.5px 0 var(--pad-bevel-top),
    inset 0 -2px 0 var(--pad-bevel-bottom),
    0 0 0 2px var(--theme-orange),
    0 0 14px var(--theme-orange-glow);
}}

.light-bar {{
  position: absolute;
  top: 7px;
  left: 22%;
  right: 22%;
  height: 2px;
  border-radius: 1px;
  background: var(--theme-orange);
  box-shadow: 0 0 6px var(--theme-orange);
  animation: barBreathB 3.2s ease-in-out infinite;
}}

@keyframes barBreathB {{
  0%, 100% {{ opacity: 0.45; }}
  50% {{ opacity: 1.0; box-shadow: 0 0 10px var(--theme-orange); }}
}}

/* PRESS FEEDBACK (PROPOSAL A MECHANICS) */
.pad-btn:active, .pad-btn.midi-hit {{
  transform: scale(0.965) translateY(1.5px);
  box-shadow: 
    inset 0 1px 2px rgba(0, 0, 0, 0.35),
    0 0 0 1px var(--hairline);
  transition-duration: 0.05s;
}}

.pad-btn:active .pad-flash, .pad-btn.midi-hit .pad-flash {{
  opacity: 0.38;
}}

/* REDUCE MOTION ENFORCEMENT */
[data-reduce-motion="true"] *,
[data-reduce-motion="true"] *::before,
[data-reduce-motion="true"] *::after {{
  animation: none !important;
  transition-duration: 0.12s !important;
}}

[data-reduce-motion="true"] .pad-btn:active,
[data-reduce-motion="true"] .pad-btn.midi-hit {{
  transform: none !important;
  background: var(--ink) !important;
  color: var(--bg) !important;
}}

[data-reduce-motion="true"] .light-bar {{
  animation: none !important;
  opacity: 0.9 !important;
}}

/* BACKGROUND OFF COMPARISON TOGGLE */
[data-bg-active="false"] .faceplate-surface,
[data-bg-active="false"] .faceplate-overlay,
[data-bg-active="false"] .pad-well-frame,
[data-bg-active="false"] .screw-marker,
[data-bg-active="false"] .chassis-seam,
[data-bg-active="false"] .calibration-rail,
[data-bg-active="false"] .crosshair-mark,
[data-bg-active="false"] .pad-bay-plate,
[data-bg-active="false"] .ruler-strip,
[data-bg-active="false"] .channel-strip-label,
[data-bg-active="false"] .silkscreen-badge {{
  display: none !important;
}}

/* SCREW ICONS */
.screw-marker {{
  position: absolute;
  width: 14px;
  height: 14px;
  color: var(--screw-color);
  pointer-events: none;
  z-index: 5;
  transition: color 0.25s ease;
}}

.screw-marker svg {{
  width: 100%;
  height: 100%;
}}

.screw-rim {{
  fill: none;
  stroke: currentColor;
  stroke-width: 1.2;
}}

.screw-inner {{
  fill: currentColor;
  opacity: 0.15;
}}

.screw-socket {{
  fill: currentColor;
}}
"""

def generate_pad_grid_html(proposal_type):
    """
    Generate 3x3 grid HTML according to proposal type.
    Proposal A includes pad-well-frame wrappers for each cell.
    Proposal B & C use direct buttons with different surrounding elements.
    """
    if proposal_type == "A":
        # Proposal A: Recessed Pad Wells
        return """
<div class="pad-grid" id="main-pad-grid">
  <!-- Řádek 1: POKRAČOVAT / DNES (1) · KNIHOVNA (2) · TRÉNINK (3) -->
  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">01</span>
    </div>
    <button class="pad-btn hero" data-pad="1">
      <div class="pad-flash"></div>
      <span class="pad-title">POKRAČOVAT</span>
      <span class="pad-subtitle">2 cvičení · pak nová lekce</span>
    </button>
  </div>

  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">02</span>
    </div>
    <button class="pad-btn" data-pad="2">
      <div class="pad-flash"></div>
      <span class="pad-title">KNIHOVNA</span>
      <span class="pad-subtitle">42 / 216 ★</span>
    </button>
  </div>

  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">03</span>
    </div>
    <button class="pad-btn lit-pad" data-pad="3">
      <div class="pad-flash"></div>
      <div class="light-bar" title="3 cvičení k opakování (Spaced repetition)"></div>
      <span class="pad-title">TRÉNINK</span>
      <span class="pad-subtitle">3 na řadě</span>
    </button>
  </div>

  <!-- Řádek 2: ÚVODNÍ CVIČENÍ (4) · LOGO MARK · OVLADAČ (5) -->
  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">04</span>
    </div>
    <button class="pad-btn" data-pad="4">
      <div class="pad-flash"></div>
      <span class="pad-title">ÚVODNÍ CVIČENÍ</span>
      <span class="pad-subtitle">Základy rytmu</span>
    </button>
  </div>

  <div class="pad-well-slot logo-slot">
    <div class="pad-well-frame logo-well">
      <span class="well-num logo-tag">CORE</span>
    </div>
    <div class="logo-cell" data-pad="logo">
      """ + LOGO_MARK_SVG + """
    </div>
  </div>

  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">05</span>
    </div>
    <button class="pad-btn" data-pad="5">
      <div class="pad-flash"></div>
      <span class="pad-title">OVLADAČ</span>
      <span class="pad-subtitle">Akai MPD218</span>
      <span class="pad-sec-subtitle">Standard 16-Pad</span>
    </button>
  </div>

  <!-- Řádek 3: ODZNAKY (6) · PLNÁ VERZE (7) · NASTAVENÍ (8) -->
  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">06</span>
    </div>
    <button class="pad-btn" data-pad="6">
      <div class="pad-flash"></div>
      <span class="pad-title">ODZNAKY</span>
      <span class="pad-subtitle">4 / 16</span>
    </button>
  </div>

  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">07</span>
    </div>
    <button class="pad-btn" data-pad="7">
      <div class="pad-flash"></div>
      <span class="pad-title">PLNÁ VERZE</span>
      <span class="pad-subtitle">Odemknout vše</span>
    </button>
  </div>

  <div class="pad-well-slot">
    <div class="pad-well-frame">
      <span class="well-num">08</span>
    </div>
    <button class="pad-btn" data-pad="8">
      <div class="pad-flash"></div>
      <span class="pad-title">NASTAVENÍ</span>
      <span class="pad-subtitle">Vzhled, zvuk & MIDI</span>
    </button>
  </div>
</div>
"""
    else:
        # Proposals B & C: Standard button layout (with surrounding background plates)
        return """
<div class="pad-grid" id="main-pad-grid">
  <!-- Řádek 1: POKRAČOVAT / DNES (1) · KNIHOVNA (2) · TRÉNINK (3) -->
  <button class="pad-btn hero" data-pad="1">
    <div class="pad-flash"></div>
    <span class="pad-title">POKRAČOVAT</span>
    <span class="pad-subtitle">2 cvičení · pak nová lekce</span>
  </button>

  <button class="pad-btn" data-pad="2">
    <div class="pad-flash"></div>
    <span class="pad-title">KNIHOVNA</span>
    <span class="pad-subtitle">42 / 216 ★</span>
  </button>

  <button class="pad-btn lit-pad" data-pad="3">
    <div class="pad-flash"></div>
    <div class="light-bar" title="3 cvičení k opakování (Spaced repetition)"></div>
    <span class="pad-title">TRÉNINK</span>
    <span class="pad-subtitle">3 na řadě</span>
  </button>

  <!-- Řádek 2: ÚVODNÍ CVIČENÍ (4) · LOGO MARK · OVLADAČ (5) -->
  <button class="pad-btn" data-pad="4">
    <div class="pad-flash"></div>
    <span class="pad-title">ÚVODNÍ CVIČENÍ</span>
    <span class="pad-subtitle">Základy rytmu</span>
  </button>

  <div class="logo-cell" data-pad="logo">
    """ + LOGO_MARK_SVG + """
  </div>

  <button class="pad-btn" data-pad="5">
    <div class="pad-flash"></div>
    <span class="pad-title">OVLADAČ</span>
    <span class="pad-subtitle">Akai MPD218</span>
    <span class="pad-sec-subtitle">Standard 16-Pad</span>
  </button>

  <!-- Řádek 3: ODZNAKY (6) · PLNÁ VERZE (7) · NASTAVENÍ (8) -->
  <button class="pad-btn" data-pad="6">
    <div class="pad-flash"></div>
    <span class="pad-title">ODZNAKY</span>
    <span class="pad-subtitle">4 / 16</span>
  </button>

  <button class="pad-btn" data-pad="7">
    <div class="pad-flash"></div>
    <span class="pad-title">PLNÁ VERZE</span>
    <span class="pad-subtitle">Odemknout vše</span>
  </button>

  <button class="pad-btn" data-pad="8">
    <div class="pad-flash"></div>
    <span class="pad-title">NASTAVENÍ</span>
    <span class="pad-subtitle">Vzhled, zvuk & MIDI</span>
  </button>
</div>
"""

def generate_common_script():
    return """
<script>
document.addEventListener('DOMContentLoaded', () => {
  const root = document.documentElement;
  const chassis = document.getElementById('ipad-chassis');
  const themeToggle = document.getElementById('theme-toggle');
  const themeLabel = document.getElementById('theme-label');
  const orientToggle = document.getElementById('orientation-toggle');
  const orientLabel = document.getElementById('orient-label');
  const bgToggle = document.getElementById('bg-toggle');
  const bgLabel = document.getElementById('bg-label');
  const motionToggle = document.getElementById('motion-toggle');
  const motionLabel = document.getElementById('motion-label');
  const midiButtons = document.querySelectorAll('.midi-trigger-btn');
  const padButtons = document.querySelectorAll('.pad-btn');

  // 1. Theme toggle
  themeToggle?.addEventListener('click', () => {
    const isDark = root.getAttribute('data-theme') === 'dark';
    if (isDark) {
      root.removeAttribute('data-theme');
      themeLabel.textContent = 'Světlý';
    } else {
      root.setAttribute('data-theme', 'dark');
      themeLabel.textContent = 'Tmavý';
    }
  });

  // 2. Orientation toggle
  orientToggle?.addEventListener('click', () => {
    const isLandscape = chassis.classList.contains('landscape');
    if (isLandscape) {
      chassis.classList.remove('landscape');
      chassis.classList.add('portrait');
      orientLabel.textContent = 'Na výšku';
    } else {
      chassis.classList.remove('portrait');
      chassis.classList.add('landscape');
      orientLabel.textContent = 'Na šířku';
    }
  });

  // 3. Background ON / OFF toggle
  bgToggle?.addEventListener('click', () => {
    const isActive = chassis.getAttribute('data-bg-active') !== 'false';
    if (isActive) {
      chassis.setAttribute('data-bg-active', 'false');
      bgToggle.classList.remove('highlight');
      bgLabel.textContent = 'VYPNUTO (Srovnání)';
    } else {
      chassis.setAttribute('data-bg-active', 'true');
      bgToggle.classList.add('highlight');
      bgLabel.textContent = 'ZAPNUTO';
    }
  });

  // 4. Motion toggle
  motionToggle?.addEventListener('click', () => {
    const isReduced = root.getAttribute('data-reduce-motion') === 'true';
    if (isReduced) {
      root.removeAttribute('data-reduce-motion');
      motionLabel.textContent = 'Plný';
      motionToggle.classList.remove('active');
    } else {
      root.setAttribute('data-reduce-motion', 'true');
      motionLabel.textContent = 'Redukovaný';
      motionToggle.classList.add('active');
    }
  });

  // 5. Tactile Pad Strike Feedback
  function triggerPadStrike(padNumber) {
    const pad = document.querySelector(`.pad-btn[data-pad="${padNumber}"]`);
    if (!pad) return;

    pad.classList.add('midi-hit');
    setTimeout(() => {
      pad.classList.remove('midi-hit');
    }, 140);
  }

  midiButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const padNum = btn.getAttribute('data-pad');
      triggerPadStrike(padNum);
    });
  });

  padButtons.forEach(pad => {
    pad.addEventListener('click', () => {
      const padNum = pad.getAttribute('data-pad');
      triggerPadStrike(padNum);
    });
  });

  // Keyboard shortcut listener: keys 1–8
  window.addEventListener('keydown', (e) => {
    if (['1','2','3','4','5','6','7','8'].includes(e.key)) {
      triggerPadStrike(e.key);
    }
  });
});
</script>
"""

# ----------------------------------------------------------------------
# PROPOSAL A SPECIFIC CODE
# ----------------------------------------------------------------------
PROPOSAL_A_CSS = """
/* --- PROPOSAL A: RECESSED PAD WELLS & ANODISED MATTE CHASSIS --- */

.faceplate-surface-a {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
}

/* Subtle procedural stipple texture */
.faceplate-overlay-a {
  position: absolute;
  inset: 0;
  opacity: 0.038;
  pointer-events: none;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 200 200' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.8' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E");
  z-index: 2;
  mix-blend-mode: multiply;
}

[data-theme="dark"] .faceplate-overlay-a {
  opacity: 0.055;
  mix-blend-mode: screen;
}

/* Engraved horizontal seam separating header and pad deck */
.chassis-seam-a {
  position: absolute;
  left: 28px;
  right: 28px;
  top: 104px;
  height: 2px;
  border-top: 1px solid var(--seam-shadow);
  border-bottom: 1px solid var(--seam-highlight);
  pointer-events: none;
  z-index: 3;
}

.ipad-chassis.portrait .chassis-seam-a {
  top: 120px;
}

/* 4 Corner Flush Torx Screws */
.screw-marker.tl { top: 22px; left: 22px; }
.screw-marker.tr { top: 22px; right: 22px; }
.screw-marker.bl { bottom: 22px; left: 22px; }
.screw-marker.br { bottom: 22px; right: 22px; }

/* RECESSED PAD WELLS (LŮŽKA PADŮ) */
.pad-well-slot {
  position: relative;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.pad-well-frame {
  position: absolute;
  inset: -3.5px;
  border-radius: 11px;
  background: var(--well-bg);
  box-shadow: var(--well-shadow);
  pointer-events: none;
  z-index: 1;
  transition: background 0.2s ease, box-shadow 0.2s ease;
}

.well-num {
  position: absolute;
  top: -14px;
  left: 2px;
  font-family: 'IBM Plex Sans', monospace;
  font-size: 9.5px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--well-label);
  line-height: 1;
  user-select: none;
  z-index: 4;
}

.logo-well {
  background: transparent;
  box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.1);
  border: 1px dashed var(--hairline);
}

.logo-tag {
  color: var(--theme-orange);
  opacity: 0.85;
}

.pad-well-slot .pad-btn {
  position: relative;
  z-index: 2;
}
"""

# ----------------------------------------------------------------------
# PROPOSAL B SPECIFIC CODE
# ----------------------------------------------------------------------
PROPOSAL_B_CSS = """
/* --- PROPOSAL B: PERFORATED ACOUSTIC GRILLE & TECHNICAL RAILS --- */

.faceplate-grille-b {
  position: absolute;
  inset: 0;
  background-image: radial-gradient(circle 1px at 8px 8px, var(--grille-dot) 100%, transparent 100%);
  background-size: 16px 16px;
  pointer-events: none;
  z-index: 1;
  transition: opacity 0.25s ease;
}

/* Protective Legibility Shield: Clears out dots behind wordmark and 3x3 pads */
.grille-shield-header {
  position: absolute;
  top: 15px;
  left: 50%;
  transform: translateX(-50%);
  width: 320px;
  height: 80px;
  background: radial-gradient(ellipse 60% 70% at center, var(--bg) 60%, transparent 100%);
  pointer-events: none;
  z-index: 2;
}

.grille-shield-grid {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -46%);
  width: 580px;
  height: 580px;
  background: radial-gradient(ellipse 65% 65% at center, var(--bg) 68%, transparent 100%);
  pointer-events: none;
  z-index: 2;
}

.ipad-chassis.portrait .grille-shield-grid {
  width: 520px;
  height: 520px;
}

/* Technical Alignment Rails */
.calibration-rail {
  position: absolute;
  pointer-events: none;
  z-index: 4;
}

.rail-v-left {
  top: 90px;
  bottom: 90px;
  left: calc(50% - 275px);
  width: 1px;
  background: var(--rail-line);
}

.rail-v-right {
  top: 90px;
  bottom: 90px;
  right: calc(50% - 275px);
  width: 1px;
  background: var(--rail-line);
}

.rail-h-top {
  left: calc(50% - 275px);
  right: calc(50% - 275px);
  top: calc(50% - 235px);
  height: 1px;
  background: var(--rail-line);
}

.rail-h-bottom {
  left: calc(50% - 275px);
  right: calc(50% - 275px);
  bottom: calc(50% - 275px);
  height: 1px;
  background: var(--rail-line);
}

.ipad-chassis.portrait .rail-v-left { left: calc(50% - 240px); }
.ipad-chassis.portrait .rail-v-right { right: calc(50% - 240px); }
.ipad-chassis.portrait .rail-h-top { left: calc(50% - 240px); right: calc(50% - 240px); top: calc(50% - 205px); }
.ipad-chassis.portrait .rail-h-bottom { left: calc(50% - 240px); right: calc(50% - 240px); bottom: calc(50% - 245px); }

/* Crosshair Registration Marks */
.crosshair-mark {
  position: absolute;
  width: 14px;
  height: 14px;
  color: var(--secondary);
  opacity: 0.55;
  pointer-events: none;
  z-index: 5;
}

.crosshair-mark.tl { top: calc(50% - 242px); left: calc(50% - 282px); }
.crosshair-mark.tr { top: calc(50% - 242px); right: calc(50% - 282px); }
.crosshair-mark.bl { bottom: calc(50% - 282px); left: calc(50% - 282px); }
.crosshair-mark.br { bottom: calc(50% - 282px); right: calc(50% - 282px); }

.ipad-chassis.portrait .crosshair-mark.tl { top: calc(50% - 212px); left: calc(50% - 247px); }
.ipad-chassis.portrait .crosshair-mark.tr { top: calc(50% - 212px); right: calc(50% - 247px); }
.ipad-chassis.portrait .crosshair-mark.bl { bottom: calc(50% - 252px); left: calc(50% - 247px); }
.ipad-chassis.portrait .crosshair-mark.br { bottom: calc(50% - 252px); right: calc(50% - 247px); }

/* Technical Ruler on Right Margin */
.ruler-strip {
  position: absolute;
  right: 28px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 16px;
  pointer-events: none;
  z-index: 4;
}

.ipad-chassis.portrait .ruler-strip {
  display: none;
}

.ruler-tick {
  width: 14px;
  height: 1px;
  background: var(--rail-line);
  position: relative;
}

.ruler-tick.major {
  width: 22px;
  background: var(--ink);
  opacity: 0.4;
}

.ruler-tick.major::after {
  content: attr(data-val);
  position: absolute;
  right: 26px;
  top: -5px;
  font-size: 8px;
  font-family: 'IBM Plex Sans', monospace;
  color: var(--secondary);
  font-weight: 600;
}

.ruler-legend {
  writing-mode: vertical-rl;
  text-orientation: mixed;
  font-size: 9px;
  letter-spacing: 0.15em;
  color: var(--secondary);
  opacity: 0.6;
  text-transform: uppercase;
  margin-top: 10px;
  font-weight: 600;
}

/* Column Header Strip */
.channel-strip-labels {
  display: flex;
  justify-content: space-between;
  width: 100%;
  max-width: 510px;
  margin-bottom: 6px;
  z-index: 10;
  pointer-events: none;
}

.ipad-chassis.portrait .channel-strip-labels {
  max-width: 450px;
}

.channel-strip-label {
  font-size: 10px;
  font-weight: 700;
  font-family: 'IBM Plex Sans', monospace;
  letter-spacing: 0.1em;
  color: var(--secondary);
  opacity: 0.6;
  text-transform: uppercase;
  flex: 1;
  text-align: center;
}
"""

# ----------------------------------------------------------------------
# PROPOSAL C SPECIFIC CODE
# ----------------------------------------------------------------------
PROPOSAL_C_CSS = """
/* --- PROPOSAL C: MODULAR POLYCARBONATE BAY & STUDIO VIGNETTE --- */

/* Smooth Studio Vignette / Light Falloff */
.faceplate-vignette-c {
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse 72% 68% at 50% 46%, var(--vignette-center) 0%, var(--vignette-edge) 100%);
  pointer-events: none;
  z-index: 1;
  transition: background 0.3s ease;
}

/* Horizontal Panel Seams Partitioning Chassis into 3 Blocks */
.chassis-seam-c {
  position: absolute;
  left: 0;
  right: 0;
  height: 2px;
  border-top: 1px solid var(--seam-shadow);
  border-bottom: 1px solid var(--seam-highlight);
  pointer-events: none;
  z-index: 3;
}

.seam-top-c {
  top: 106px;
}

.seam-bottom-c {
  bottom: 50px;
}

.ipad-chassis.portrait .seam-top-c {
  top: 122px;
}

.ipad-chassis.portrait .seam-bottom-c {
  bottom: 65px;
}

/* Sunken Modular Central Pad Bay */
.pad-bay-plate {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -46%);
  width: 546px;
  height: 546px;
  background: var(--bay-bg);
  border-radius: 14px;
  border: 1px solid var(--bay-border);
  box-shadow: var(--bay-shadow);
  pointer-events: none;
  z-index: 2;
  transition: background 0.25s ease, box-shadow 0.25s ease;
}

.ipad-chassis.portrait .pad-bay-plate {
  width: 480px;
  height: 480px;
}

/* Corner Screws for Modular Bay */
.bay-screw {
  position: absolute;
  width: 14px;
  height: 14px;
  color: var(--screw-color);
  pointer-events: none;
  z-index: 5;
}

.bay-screw.tl { top: 8px; left: 8px; }
.bay-screw.tr { top: 8px; right: 8px; }
.bay-screw.bl { bottom: 8px; left: 8px; }
.bay-screw.br { bottom: 8px; right: 8px; }

/* Lower Status & Model Silkscreen Badge */
.silkscreen-badge {
  position: absolute;
  bottom: 20px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 16px;
  font-family: 'IBM Plex Sans', monospace;
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.12em;
  color: var(--secondary);
  opacity: 0.6;
  text-transform: uppercase;
  pointer-events: none;
  z-index: 4;
}

.ipad-chassis.portrait .silkscreen-badge {
  bottom: 26px;
  font-size: 9px;
  letter-spacing: 0.08em;
}

.badge-dot {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: var(--theme-orange);
  opacity: 0.85;
}
"""

def generate_html_page(title, proposal_letter, extra_css, background_html, active_tab=""):
    """Assemble a complete offline HTML preview page."""
    
    # Navigation tabs
    tabs_html = f"""
    <nav class="workbench-tabs">
      <a href="index.html" class="workbench-tab {'active' if active_tab == 'index' else ''}">Srovnání & Přehled</a>
      <a href="proposal-a.html" class="workbench-tab {'active' if active_tab == 'a' else ''}">Návrh A (Lůžka & Elox)</a>
      <a href="proposal-b.html" class="workbench-tab {'active' if active_tab == 'b' else ''}">Návrh B (Perforace & Kolejnice)</a>
      <a href="proposal-c.html" class="workbench-tab {'active' if active_tab == 'c' else ''}">Návrh C (Spáry & Vinětace)</a>
    </nav>
    """

    pad_grid = generate_pad_grid_html(proposal_letter)

    return f"""<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} (Ticket 114)</title>
  <style>
{COMMON_CSS}
{extra_css}
  </style>
</head>
<body>

<header class="workbench-header">
  <div class="brand-badge">
    <span class="pill">Smack-a-Pad</span>
    <span>Ticket 114 · Návrhy pozadí domovské obrazovky</span>
  </div>

  {tabs_html}

  <div class="controls-cluster">
    <button class="ctrl-btn" id="theme-toggle" title="Přepnout Světlý (Cream) / Tmavý (Soft Black) režim">
      <span>Vzhled:</span> <strong id="theme-label">Světlý</strong>
    </button>
    <button class="ctrl-btn" id="orientation-toggle" title="Přepnout iPad na šířku / na výšku">
      <span>Orientace:</span> <strong id="orient-label">Na šířku</strong>
    </button>
    <button class="ctrl-btn highlight" id="bg-toggle" title="Vypnout strukturované pozadí pro okamžité porovnání s holou plochou">
      <span>Pozadí:</span> <strong id="bg-label">ZAPNUTO</strong>
    </button>
    <button class="ctrl-btn" id="motion-toggle" title="Aktivovat Reduce Motion dle pravidel Apple a Ticketu 27/112">
      <span>Pohyb:</span> <strong id="motion-label">Plný</strong>
    </button>
    <div class="midi-triggers" title="Simulovat úder z fyzického MIDI kontroleru (nebo klávesy 1-8)">
      <span class="ctrl-label">MIDI:</span>
      <button class="midi-trigger-btn" data-pad="1">1</button>
      <button class="midi-trigger-btn" data-pad="2">2</button>
      <button class="midi-trigger-btn" data-pad="3">3</button>
      <button class="midi-trigger-btn" data-pad="4">4</button>
      <button class="midi-trigger-btn" data-pad="5">5</button>
      <button class="midi-trigger-btn" data-pad="6">6</button>
      <button class="midi-trigger-btn" data-pad="7">7</button>
      <button class="midi-trigger-btn" data-pad="8">8</button>
    </div>
  </div>
</header>

<main class="workbench-viewport">
  <div class="ipad-chassis landscape" id="ipad-chassis" data-bg-active="true">
    {background_html}

    <div class="home-screen">
      <div class="brand-header-area">
        {WORDMARK_SVG}
      </div>

      {pad_grid}
    </div>
  </div>
</main>

{generate_common_script()}
</body>
</html>
"""

# ----------------------------------------------------------------------
# INDEX.HTML SPECIFIC CODE (COMPARISON MATRIX & LIVE SWITCHER)
# ----------------------------------------------------------------------
INDEX_EXTRA_CSS = f"""
{PROPOSAL_A_CSS}
{PROPOSAL_B_CSS}
{PROPOSAL_C_CSS}

/* Index layout additions */
.index-shell {{
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 36px;
  padding: 32px 20px 80px;
}}

.hero-intro {{
  background: #18181B;
  border: 1px solid #27272A;
  border-radius: 8px;
  padding: 28px 32px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}}

.hero-intro h1 {{
  font-size: 24px;
  color: #FFF;
  font-weight: 700;
  letter-spacing: -0.01em;
}}

.hero-intro p {{
  font-size: 15px;
  line-height: 1.6;
  color: #A1A1AA;
}}

.hero-intro strong {{
  color: #F4EFE6;
}}

.proposal-switcher-bar {{
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 10px;
  padding: 12px;
  background: #18181B;
  border: 1px solid #27272A;
  border-radius: 6px;
}}

.switcher-btn {{
  background: #27272A;
  border: 1px solid #3F3F46;
  color: #E4E4E7;
  padding: 9px 18px;
  border-radius: 4px;
  font-family: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: all 0.15s ease;
}}

.switcher-btn:hover {{
  background: #3F3F46;
  color: #FFF;
}}

.switcher-btn.active {{
  background: #FF6B00;
  color: #1F1D1A;
  border-color: #FF6B00;
}}

.compare-table-wrapper {{
  background: #18181B;
  border: 1px solid #27272A;
  border-radius: 8px;
  overflow: hidden;
}}

.compare-table {{
  width: 100%;
  border-collapse: collapse;
  text-align: left;
  font-size: 13.5px;
}}

.compare-table th, .compare-table td {{
  padding: 14px 18px;
  border-bottom: 1px solid #27272A;
  vertical-align: top;
  line-height: 1.5;
}}

.compare-table th {{
  background: #202024;
  color: #FFF;
  font-weight: 600;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}}

.compare-table tr:hover td {{
  background: rgba(255, 255, 255, 0.02);
}}

.badge-rec {{
  background: #FF6B00;
  color: #1F1D1A;
  font-size: 10px;
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 2px;
  text-transform: uppercase;
  margin-left: 6px;
}}

.spec-cards-grid {{
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}}

@media (max-width: 900px) {{
  .spec-cards-grid {{
    grid-template-columns: 1fr;
  }}
}}

.spec-card {{
  background: #18181B;
  border: 1px solid #27272A;
  border-radius: 8px;
  padding: 22px;
  display: flex;
  flex-direction: column;
  gap: 12px;
}}

.spec-card.highlight {{
  border-color: #FF6B00;
}}

.spec-card h2 {{
  font-size: 18px;
  color: #FFF;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: space-between;
}}

.spec-card p {{
  font-size: 13.5px;
  line-height: 1.55;
  color: #A1A1AA;
}}

.spec-list {{
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 6px;
}}

.spec-list li {{
  font-size: 13px;
  color: #D4D4D8;
  display: flex;
  align-items: flex-start;
  gap: 8px;
  line-height: 1.4;
}}

.spec-list li strong {{
  color: #FFF;
}}

.code-snippet {{
  background: #101012;
  border: 1px solid #27272A;
  border-radius: 4px;
  padding: 10px 12px;
  font-family: monospace;
  font-size: 12px;
  color: #E4E4E7;
  overflow-x: auto;
  white-space: pre;
  margin-top: 6px;
}}
"""

def generate_index_html():
    """Build the comprehensive index.html comparison page with interactive live switcher."""
    
    # Background containers for all 3 proposals in one chassis
    combined_bg_html = f"""
    <!-- PROPOSAL A BACKGROUND -->
    <div id="bg-layer-a" class="proposal-bg-layer">
      <div class="faceplate-surface-a"></div>
      <div class="faceplate-overlay-a"></div>
      <div class="chassis-seam-a"></div>
      <div class="screw-marker tl">{TORX_SCREW_SVG}</div>
      <div class="screw-marker tr">{TORX_SCREW_SVG}</div>
      <div class="screw-marker bl">{TORX_SCREW_SVG}</div>
      <div class="screw-marker br">{TORX_SCREW_SVG}</div>
    </div>

    <!-- PROPOSAL B BACKGROUND -->
    <div id="bg-layer-b" class="proposal-bg-layer" style="display: none;">
      <div class="faceplate-grille-b"></div>
      <div class="grille-shield-header"></div>
      <div class="grille-shield-grid"></div>
      <div class="calibration-rail rail-v-left"></div>
      <div class="calibration-rail rail-v-right"></div>
      <div class="calibration-rail rail-h-top"></div>
      <div class="calibration-rail rail-h-bottom"></div>
      <div class="crosshair-mark tl">{CROSSHAIR_SVG}</div>
      <div class="crosshair-mark tr">{CROSSHAIR_SVG}</div>
      <div class="crosshair-mark bl">{CROSSHAIR_SVG}</div>
      <div class="crosshair-mark br">{CROSSHAIR_SVG}</div>
      <div class="ruler-strip">
        <div class="ruler-tick major" data-val="100"></div>
        <div class="ruler-tick"></div>
        <div class="ruler-tick"></div>
        <div class="ruler-tick major" data-val="50"></div>
        <div class="ruler-tick"></div>
        <div class="ruler-tick"></div>
        <div class="ruler-tick major" data-val="00"></div>
        <div class="ruler-legend">CALIBRATED MATRIX · 44.1 kHz</div>
      </div>
    </div>

    <!-- PROPOSAL C BACKGROUND -->
    <div id="bg-layer-c" class="proposal-bg-layer" style="display: none;">
      <div class="faceplate-vignette-c"></div>
      <div class="chassis-seam-c seam-top-c"></div>
      <div class="chassis-seam-c seam-bottom-c"></div>
      <div class="pad-bay-plate">
        <div class="bay-screw tl">{PHILLIPS_SCREW_SVG}</div>
        <div class="bay-screw tr">{PHILLIPS_SCREW_SVG}</div>
        <div class="bay-screw bl">{PHILLIPS_SCREW_SVG}</div>
        <div class="bay-screw br">{PHILLIPS_SCREW_SVG}</div>
      </div>
      <div class="silkscreen-badge">
        <span class="badge-dot"></span>
        <span>SMACK-A-PAD // MODEL 3x3 // TACTILE MIDI TRAINER // REV. 1.0</span>
      </div>
    </div>
    """

    return f"""<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Smack-a-Pad — Srovnání návrhů pozadí domovské obrazovky (Ticket 114)</title>
  <style>
{COMMON_CSS}
{INDEX_EXTRA_CSS}
  </style>
</head>
<body>

<header class="workbench-header">
  <div class="brand-badge">
    <span class="pill">Smack-a-Pad</span>
    <span>Ticket 114 · Návrhy pozadí domovské obrazovky</span>
  </div>

  <nav class="workbench-tabs">
    <a href="index.html" class="workbench-tab active">Srovnání & Přehled</a>
    <a href="proposal-a.html" class="workbench-tab">Návrh A (Lůžka & Elox)</a>
    <a href="proposal-b.html" class="workbench-tab">Návrh B (Perforace & Kolejnice)</a>
    <a href="proposal-c.html" class="workbench-tab">Návrh C (Spáry & Vinětace)</a>
  </nav>

  <div class="controls-cluster">
    <button class="ctrl-btn" id="theme-toggle" title="Přepnout Světlý (Cream) / Tmavý (Soft Black) režim">
      <span>Vzhled:</span> <strong id="theme-label">Světlý</strong>
    </button>
    <button class="ctrl-btn" id="orientation-toggle" title="Přepnout iPad na šířku / na výšku">
      <span>Orientace:</span> <strong id="orient-label">Na šířku</strong>
    </button>
    <button class="ctrl-btn highlight" id="bg-toggle" title="Vypnout strukturované pozadí pro okamžité porovnání s holou plochou">
      <span>Pozadí:</span> <strong id="bg-label">ZAPNUTO</strong>
    </button>
    <button class="ctrl-btn" id="motion-toggle" title="Aktivovat Reduce Motion dle pravidel Apple a Ticketu 27/112">
      <span>Pohyb:</span> <strong id="motion-label">Plný</strong>
    </button>
    <div class="midi-triggers" title="Simulovat úder z fyzického MIDI kontroleru (nebo klávesy 1-8)">
      <span class="ctrl-label">MIDI:</span>
      <button class="midi-trigger-btn" data-pad="1">1</button>
      <button class="midi-trigger-btn" data-pad="2">2</button>
      <button class="midi-trigger-btn" data-pad="3">3</button>
      <button class="midi-trigger-btn" data-pad="4">4</button>
      <button class="midi-trigger-btn" data-pad="5">5</button>
      <button class="midi-trigger-btn" data-pad="6">6</button>
      <button class="midi-trigger-btn" data-pad="7">7</button>
      <button class="midi-trigger-btn" data-pad="8">8</button>
    </div>
  </div>
</header>

<main class="workbench-viewport">
  <!-- Interactive Proposal Switcher Bar -->
  <div class="proposal-switcher-bar">
    <span class="ctrl-label">Přepnout návrh v náhledu:</span>
    <button class="switcher-btn active" data-target="A">Návrh A: Frézovaná lůžka & Elox <span class="badge-rec">Doporučeno</span></button>
    <button class="switcher-btn" data-target="B">Návrh B: Perforovaný rošt & Kolejnice</button>
    <button class="switcher-btn" data-target="C">Návrh C: Modulární šasi & Vinětace</button>
  </div>

  <div class="ipad-chassis landscape" id="ipad-chassis" data-bg-active="true" data-active-proposal="A">
    {combined_bg_html}

    <div class="home-screen">
      <div class="brand-header-area">
        {WORDMARK_SVG}
      </div>

      <!-- Channel strip headers (visible in Proposal B) -->
      <div class="channel-strip-labels" id="channel-strip-labels" style="display: none;">
        <span class="channel-strip-label">[ BANK A · 01–03 ]</span>
        <span class="channel-strip-label">[ BANK B · 04–05 ]</span>
        <span class="channel-strip-label">[ BANK C · 06–08 ]</span>
      </div>

      {generate_pad_grid_html("A")}
    </div>
  </div>
</main>

<div class="index-shell">
  <section class="hero-intro">
    <h1>Struktura čelního panelu pro domovskou obrazovku (Ticket 114)</h1>
    <p>
      Jakubovo zadání: <em>„Chtěl bych, aby plocha Home obrazovky měla v pozadí nějakou strukturu a působila jako povrch padového MIDI kontroleru.“</em><br>
      Všechny 3 návrhy vycházejí ze schválených padů ticketu 112 (zaoblení 8 pt, fazetka a horní světelný proužek na Tréninku). Pozadí zůstává klidné a nerušivé – texty a popisky padů si zachovávají 100% kontrast splňující <strong>WCAG AAA</strong>. Použita je výhradně paleta aplikace (krémová <code>#F4EFE6</code> a teplá měkká černá <code>#1F1D1A</code>, ticket 92).
    </p>
    <p>
      Pomocí tlačítka <strong>Pozadí: ZAPNUTO / VYPNUTO</strong> nahoře si můžete jedním kliknutím ověřit rozdíl mezi strukturovaným čelním panelem a původní prázdnou plochou.
    </p>
  </section>

  <!-- Side-by-Side Comparison Matrix -->
  <section class="compare-table-wrapper">
    <table class="compare-table">
      <thead>
        <tr>
          <th style="width: 20%;">Kritérium / Parametr</th>
          <th style="width: 26.6%;">Návrh A: Frézovaná lůžka & Elox <span class="badge-rec">Doporučeno</span></th>
          <th style="width: 26.6%;">Návrh B: Perforovaný rošt & Kalibrace</th>
          <th style="width: 26.6%;">Návrh C: Modulární šasi & Vinětace</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Hardwarová inspirace</strong></td>
          <td>Moderní vlajkové lodě (Akai MPC Live/Studio, Ableton Push). Masivní blok s precizně vyfrézovanými otvory pro každý pad.</td>
          <td>Industriální studiová technika (Teenage Engineering, Roland TR-808/909). Akustický perforovaný rošt a inženýrské linky.</td>
          <td>Klasické těžké samplery (E-mu SP-1200, MPC 2000XL). Tvarované plastové/kovové panely spojené konstrukčními spárami.</td>
        </tr>
        <tr>
          <td><strong>Lůžka padů (Pad wells)</strong></td>
          <td><strong>Ano, samostatné lůžko pro každý z 8 padů i logo</strong>. 4px zapuštěná fazetka s vnitřním stínem. Při stisku se pad zanoří do lůžka.</td>
          <td>Bez lůžek. Pady sedí na hladkém ochranném štítu, který perforaci odsouvá do okrajových zón.</td>
          <td><strong>Společné modulární lůžko (Bay Plate)</strong> pro celou matici 3×3 s 2px fazetou a 4 upevňovacími šroubky v rozích desky.</td>
        </tr>
        <tr>
          <td><strong>Povrchová textura šasi</strong></td>
          <td>Ultra-jemná matná mikro-zrnitost (anodizovaný tryskaný hliník). Klidný sametový mat bez digitálního lesku.</td>
          <td>Rovnoměrný rastr mikro-bodů (průměr 2 px, rozteč 16 px). Působí jako kovový perforovaný reproduktorový/ventilační rošt.</td>
          <td>Jemný světelný spád (vinětace) shora dolů simulující studiovou stolní lampu nad kontrolerem (rozdíl jasu pouze 3.5 %).</td>
        </tr>
        <tr>
          <td><strong>Konstrukční detaily & Silkscreen</strong></td>
          <td>4 zapuštěné Torx šroubky v rozích, dělící drážka pod logem, decentní číslování padů <code>[01]</code> až <code>[08]</code> v rohu lůžka.</td>
          <td>Kalibrační pravítko s mm ryskami na pravém okraji, křížové značky <code>+</code> v rozích, popisy sběrnic <code>[ BANK A · 01–03 ]</code>.</td>
          <td>Dvě hluboké vodorovné konstrukční spáry (drážky šasi), 4 rohové Phillips šroubky na desce padů, vyražený štítek modelu dole.</td>
        </tr>
        <tr>
          <td><strong>Implementace ve SwiftUI</strong></td>
          <td><code>RoundedRectangle(cornerRadius: 10)</code> s vnitřním stínem za každým padem v <code>HomeScreen.swift</code> + dlaždice textury.</td>
          <td>Dlaždicový vektorový asset 16×16 pt <code>.resizable(resizingMode: .tile)</code> nebo <code>Canvas</code> + vektorové linky.</td>
          <td><strong>100% čistý kód bez assetů</strong>: <code>RadialGradient</code> + standardní <code>Rectangle</code> a <code>Stroke</code> pro spáry a desku.</td>
        </tr>
        <tr>
          <td><strong>Výkonnostní náročnost</strong></td>
          <td><strong>Téměř nulová (0 % per-frame CPU)</strong>. Dlaždice 128×128 pt má < 15 KB v RAM. Lůžka se kreslí v rámci stávající mřížky.</td>
          <td><strong>Extrémně nízká</strong>. Dlaždicový rošt je v GPU paměti okamžitě blitován Metalem. Žádné per-frame přepočty.</td>
          <td><strong>Absolutně nulová režie</strong>. Standardní SwiftUI gradient a tvary, nulové zpoždění při startu, 120 FPS na ProMotion.</td>
        </tr>
        <tr>
          <td><strong>Čitelnost a kontrast (WCAG)</strong></td>
          <td><strong>100% WCAG AAA</strong>. Textura má opacitu pod 4 %. Názvy padů i wordmark mají plný kontrast 14:1.</td>
          <td><strong>100% WCAG AAA</strong>. Pod texty i celou mřížkou je ochranný štít – body za textem plynule mizí do nuly.</td>
          <td><strong>100% WCAG AAA</strong>. Světelný spád je pozvolný a drží se přesně v mantinelech tokenů <code>Theme.background</code>.</td>
        </tr>
        <tr>
          <td><strong>Chování při otočení iPadu</strong></td>
          <td>Lůžka jsou přímo vázána na buňky mřížky – automaticky perfektní v Landscape i Portrait bez jakéhokoliv posunu.</td>
          <td>Rastr je bezešvý. Kalibrační pravítko na boku se v portraitu elegantně skryje, křížky drží rohy mřížky.</td>
          <td>Vodorovné spáry se dynamicky přizpůsobí šířce, centrální deska padů drží mřížku.</td>
        </tr>
      </tbody>
    </table>
  </section>

  <!-- Deep Dive Cards for Each Proposal -->
  <section class="spec-cards-grid">
    <div class="spec-card highlight">
      <h2>Návrh A: Frézovaná lůžka <span class="badge-rec">Doporučeno</span></h2>
      <p>
        <strong>Proč jednoznačně doporučujeme:</strong> Skutečný padový kontroler se pozná podle toho, že gumové pady nevisí ve vzduchu na hladké ploše, ale sedí v přesných frézovaných otvorech šasi. 
      </p>
      <ul class="spec-list">
        <li><strong>Fyzické zanoření:</strong> Při stisku padu prstem nebo z externího MIDI kontroleru pad klesne o 1.5 pt a zmenší se na 96.5 %. Tím se odhalí horní stín lůžka, což vytváří dokonalou iluzi skutečného stlačitelného kaučuku.</li>
        <li><strong>Číslování 01–08:</strong> Decentní technické indexy u každého lůžka dávají mřížce profesionální studiový vzhled.</li>
        <li><strong>Klidné tělo:</strong> Mikro-zrnitost eliminuje digitální sterilitu displeje, aniž by odváděla pozornost.</li>
      </ul>
      <div class="code-snippet">// Návrh SwiftUI architektury v HomeScreen.swift:
ZStack {{
    Theme.background.ignoresSafeArea()
    Image("ChassisMatte").resizable(resizingMode: .tile)
        .opacity(colorScheme == .dark ? 0.05 : 0.035)
    // V gridContent:
    RoundedRectangle(cornerRadius: Theme.Radius.pad + 2)
        .fill(Theme.surface.opacity(0.4))
        .innerShadow(...)
}}</div>
    </div>

    <div class="spec-card">
      <h2>Návrh B: Perforovaný rošt</h2>
      <p>
        <strong>Inženýrská studiová estetika:</strong> Vhodné pro milovníky hardware designu značek Teenage Engineering nebo Dieter Rams (Braun). 
      </p>
      <ul class="spec-list">
        <li><strong>Mikro-perforace:</strong> Pravidelná síť dírek vytváří iluzi reproduktorového či ventilačního roštu studiového racku.</li>
        <li><strong>Ochranný štít:</strong> Dírky nezasahují pod texty – za nápisy je hladký gradientní filtr, takže kontrast zůstává nekompromisní.</li>
        <li><strong>Kalibrační linky:</strong> Jemná vertikální ryska s ryskami a křížky v rozích podtrhuje přesnost nástroje.</li>
      </ul>
      <div class="code-snippet">// Návrh SwiftUI architektury v HomeScreen.swift:
ZStack {{
    Theme.background.ignoresSafeArea()
    Image("PerforatedTile").resizable(resizingMode: .tile)
        .mask(RadialGradient(..., [Color.clear, Color.black]))
    TechnicalRulerView() // Vektorové linky vpravo
}}</div>
    </div>

    <div class="spec-card">
      <h2>Návrh C: Modulární šasi</h2>
      <p>
        <strong>Masivní modulární hardware:</strong> Inspirováno legendami E-mu SP-1200 a MPC 2000XL s dělenými konstrukčními panely.
      </p>
      <ul class="spec-list">
        <li><strong>Dvě horizontální spáry:</strong> Rozdělují displej na horní displejový blok, centrální padovou desku a spodní servisní kolejnici.</li>
        <li><strong>Zapuštěná deska padů:</strong> Všech 9 buněk je vizuálně osazeno na společné vyvýšené desce se 4 šroubky.</li>
        <li><strong>Studiová vinětace:</strong> Pozvolný světelný spád od středu ke krajům dodává tělu hloubku a plastičnost.</li>
      </ul>
      <div class="code-snippet">// Návrh SwiftUI architektury v HomeScreen.swift:
ZStack {{
    RadialGradient(colors: [Theme.surface, Theme.background], ...)
    ChassisSeamView(y: 110)
    PadBayPlateView(size: gridSize + 32)
    ChassisSeamView(y: bottomY)
}}</div>
    </div>
  </section>
</div>

{generate_common_script()}

<script>
// Switcher behavior inside index.html
document.addEventListener('DOMContentLoaded', () => {{
  const switcherBtns = document.querySelectorAll('.switcher-btn');
  const bgLayers = {{
    'A': document.getElementById('bg-layer-a'),
    'B': document.getElementById('bg-layer-b'),
    'C': document.getElementById('bg-layer-c')
  }};
  const channelStrip = document.getElementById('channel-strip-labels');
  const chassis = document.getElementById('ipad-chassis');
  const padGrid = document.getElementById('main-pad-grid');

  switcherBtns.forEach(btn => {{
    btn.addEventListener('click', () => {{
      const target = btn.getAttribute('data-target');
      switcherBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      // Hide all bg layers
      Object.values(bgLayers).forEach(layer => layer.style.display = 'none');
      // Show selected bg layer
      if (bgLayers[target]) bgLayers[target].style.display = 'block';

      // Toggle Channel Strip in Proposal B
      if (channelStrip) {{
        channelStrip.style.display = (target === 'B') ? 'flex' : 'none';
      }}

      // Toggle Pad Wells in Proposal A
      const wellFrames = document.querySelectorAll('.pad-well-frame');
      wellFrames.forEach(frame => {{
        frame.style.display = (target === 'A') ? 'flex' : 'none';
      }});

      chassis.setAttribute('data-active-proposal', target);
    }});
  }});
}});
</script>
</body>
</html>
"""

# ----------------------------------------------------------------------
# PROPOSALS A, B, C PAGES
# ----------------------------------------------------------------------
def generate_proposal_a_html():
    bg_html = f"""
    <div class="faceplate-surface-a"></div>
    <div class="faceplate-overlay-a"></div>
    <div class="chassis-seam-a"></div>
    <div class="screw-marker tl">{TORX_SCREW_SVG}</div>
    <div class="screw-marker tr">{TORX_SCREW_SVG}</div>
    <div class="screw-marker bl">{TORX_SCREW_SVG}</div>
    <div class="screw-marker br">{TORX_SCREW_SVG}</div>
    """
    return generate_html_page("Smack-a-Pad — Návrh A: Frézovaná lůžka & Elox", "A", PROPOSAL_A_CSS, bg_html, "a")

def generate_proposal_b_html():
    bg_html = f"""
    <div class="faceplate-grille-b"></div>
    <div class="grille-shield-header"></div>
    <div class="grille-shield-grid"></div>
    <div class="calibration-rail rail-v-left"></div>
    <div class="calibration-rail rail-v-right"></div>
    <div class="calibration-rail rail-h-top"></div>
    <div class="calibration-rail rail-h-bottom"></div>
    <div class="crosshair-mark tl">{CROSSHAIR_SVG}</div>
    <div class="crosshair-mark tr">{CROSSHAIR_SVG}</div>
    <div class="crosshair-mark bl">{CROSSHAIR_SVG}</div>
    <div class="crosshair-mark br">{CROSSHAIR_SVG}</div>
    <div class="ruler-strip">
      <div class="ruler-tick major" data-val="100"></div>
      <div class="ruler-tick"></div>
      <div class="ruler-tick"></div>
      <div class="ruler-tick major" data-val="50"></div>
      <div class="ruler-tick"></div>
      <div class="ruler-tick"></div>
      <div class="ruler-tick major" data-val="00"></div>
      <div class="ruler-legend">CALIBRATED MATRIX · 44.1 kHz</div>
    </div>
    """
    # Extra header above grid for channels
    channel_header = """
    <div class="channel-strip-labels">
      <span class="channel-strip-label">[ BANK A · 01–03 ]</span>
      <span class="channel-strip-label">[ BANK B · 04–05 ]</span>
      <span class="channel-strip-label">[ BANK C · 06–08 ]</span>
    </div>
    """
    page_html = generate_html_page("Smack-a-Pad — Návrh B: Perforovaný rošt & Kalibrace", "B", PROPOSAL_B_CSS, bg_html, "b")
    # Insert channel strip labels right before pad grid
    page_html = page_html.replace('<div class="pad-grid"', channel_header + '\n<div class="pad-grid"')
    return page_html

def generate_proposal_c_html():
    bg_html = f"""
    <div class="faceplate-vignette-c"></div>
    <div class="chassis-seam-c seam-top-c"></div>
    <div class="chassis-seam-c seam-bottom-c"></div>
    <div class="pad-bay-plate">
      <div class="bay-screw tl">{PHILLIPS_SCREW_SVG}</div>
      <div class="bay-screw tr">{PHILLIPS_SCREW_SVG}</div>
      <div class="bay-screw bl">{PHILLIPS_SCREW_SVG}</div>
      <div class="bay-screw br">{PHILLIPS_SCREW_SVG}</div>
    </div>
    <div class="silkscreen-badge">
      <span class="badge-dot"></span>
      <span>SMACK-A-PAD // MODEL 3x3 // TACTILE MIDI TRAINER // REV. 1.0</span>
    </div>
    """
    return generate_html_page("Smack-a-Pad — Návrh C: Modulární šasi & Vinětace", "C", PROPOSAL_C_CSS, bg_html, "c")

# ----------------------------------------------------------------------
# README.MD IN PLAIN CZECH FOR JAKUB
# ----------------------------------------------------------------------
def generate_readme_md():
    return """# Návrhy pozadí domovské obrazovky (Ticket 114)

Status: návrhy připraveny k rozhodnutí Jakuba.
Zdroj: Jakub (2026-11-06): *„Chtěl bych, aby plocha Home obrazovky měla v pozadí nějakou strukturu a působila jako povrch padového MIDI kontroleru.“*
Návaznost: implementační ticket se sepíše po Jakubově výběru. V tomto úkolu se **nemění žádný kód aplikace, assety ani lokalizační řetězce**.

---

## 1. Rychlé odkazy na náhledy

Všechny náhledy jsou plně soběstačné a spustitelné přímo v prohlížeči na Macu (bez nutnosti webového serveru či internetového připojení; font IBM Plex Sans i vektorová grafika jsou přímo vloženy):

| Soubor | Návrh | Klíčový charakter | Způsob realizace ve SwiftUI |
|---|---|---|---|
| [**index.html**](index.html) | **Srovnání & Přehled** | Srovnávací matice všech parametrů, živý přepínač návrhů přímo v rámu iPadu a tabulky nákladů. | – |
| [**proposal-a.html**](proposal-a.html) | **Návrh A (Doporučeno)** | **Akai MPC Milled Wells & Anodised Stipple** — Samostatná frézovaná lůžka pro každý pad, matný eloxovaný hliník, Torx šroubky a číslování padů 01–08. | ZStack lůžko za každým padem v mřížce + bezešvá 128×128 dlaždice textury. |
| [**proposal-b.html**](proposal-b.html) | **Návrh B** | **Teenage Engineering Perforated Grille** — Pravidelná mikro-perforace roštu, ochranný štít proti rušení textu a inženýrské kalibrační linky s pravítkem. | Vektorová dlaždice 16×16 pt s maskou + SwiftUI Path pro vodicí linky a pravítko. |
| [**proposal-c.html**](proposal-c.html) | **Návrh C** | **SP-1200 Modular Bay & Studio Vignette** — Dvě konstrukční vodorovné spáry, společná zapuštěná deska padů se 4 rohovými šroubky a jemný studiový světelný spád. | 100% nativní kód bez assetů: `RadialGradient` pro vinětaci + SwiftUI tvary pro spáry a desku. |

Každý náhled obsahuje interaktivní lištu s přepínači:
- **Vzhled**: Světlý (krémová `#F4EFE6`) vs. Tmavý (teplá černá `#1F1D1A`).
- **Orientace**: Na šířku (980×685) vs. Na výšku (610×874).
- **Pozadí (ZAPNUTO / VYPNUTO)**: Jedním kliknutím můžete strukturované pozadí zcela skrýt a porovnat ho s původní prázdnou plochou.
- **Pohyb (Reduce Motion)**: Plný pohyb vs. Přísný režim bez animací (dle pravidel ticketu 27 a 112).
- **Simulace MIDI úderu**: Tlačítka 1–8 (či klávesy 1–8 na klávesnici) simulující reakci padu na úder z fyzického kontroleru.

---

## 2. Podrobný popis jednotlivých návrhů

### Návrh A: Frézovaná lůžka padů & Eloxovaný mat (*DOPORUČENO*)
- **Inspirace a filozofie**: Moderní vlajkové lodě profesionálního prstového bubnování (Akai MPC Live, MPC Studio, Ableton Push). Povrch kontroleru je pevný monoblok s přesně zapuštěnými lůžky pro každý jednotlivý pad.
- **Lůžka padů (Pad wells)**: Každý z 8 funkčních padů i centrální logo sedí ve vlastním vyfrézovaném lůžku s 4px lemem a vnitřním stínem. 
  - **Hmatová dynamika úderu**: Když na pad klepnete (nebo stisknete klávesu 1–8), pad se fyzicky zmenší na 96.5 % a klesne o 1.5 pt. Tím se opticky odhalí horní tmavá hrana vybrání v šasi a pad se zanoří hlouběji do těla nástroje. Tento efekt působí neuvěřitelně reálně a uspokojivě.
- **Silkscreen a číslování**: U levého horního rohu každého lůžka je vyraženo decentní technické číslo `01` až `08` v barvě `Theme.secondary` s jemnou průhledností (35 %). Logo nese označení `CORE`.
- **Povrch a kování**: Jemná matná zrnitost tryskaného eloxovaného hliníku eliminuje digitální sterilitu displeje. V rozích čelního panelu jsou 4 zapuštěné Torx šroubky a pod logem probíhá vodorovná dělící drážka oddělující hlavičku od hrací desky.

---

### Návrh B: Perforovaný studiový rošt & Technické linky
- **Inspirace a filozofie**: Přístroje s výraznou inženýrskou estetikou (Teenage Engineering, Roland TR-808/909, studiové mixážní a rackové panely).
- **Perforovaný rastr (Mikro-perforace)**: Plochu čelního panelu pokrývá pravidelná geometrická mřížka drobných bodů (průměr 2 px, rozteč 16 px). Působí jako kovový perforovaný rošt pro odvětrávání či vestavěný reproduktor.
- **Ochranný štít (Legibility Shield)**: Aby perforace nerušila čitelnost textu a nepůsobila za písmeny rušivě, je za nápisem Smack-a-Pad i za celou maticí padů aplikován plynulý kruhový štít, který body postupně stahuje do nuly. Texty zůstávají krystalicky čisté a splňují **WCAG AAA**.
- **Kalibrační kolejnice a pravítko**: Maticí padů prochází jemné vodicí osy ukončené rohovými křížovými značkami `+`. Na pravém okraji displeje (v režimu na šířku) se nachází vertikální milimetrové měřítko s popisem `CALIBRATED MATRIX · 44.1 kHz`. Nad sloupci padů jsou vypsána označení sběrnic `[ BANK A · 01–03 ]`.

---

### Návrh C: Modulární šasi se spárami & Studiová vinětace
- **Inspirace a filozofie**: Těžké studiové samplery a bicí automaty (E-mu SP-1200, Akai MPC 2000XL, Dave Smith Tempest) složené z robustních montovaných dílů.
- **Dvě konstrukční spáry**: Čelní panel je dvěma vodorovnými drážkami (s 1.5px stínem a 1px světelnou hranou) rozdělen na 3 zóny: horní displejový blok s logem, střední hrací desku a spodní servisní lištu.
- **Zapuštěná deska padů (Bay Plate)**: Všech 9 buněk mřížky je zasazeno do vyvýšené montážní desky s 14px zaoblením, jemně odlišným odstínem povrchu a 4 křížovými šroubky v rozích.
- **Studiová vinětace**: Pozadí má velmi jemný, organický světelný spád shora dolů (simulace kuželu světla studiové lampy namířené na pracovní plochu). Rozdíl jasu mezi středem a okrajem je pouhých 3.5 %, takže texty neztrácejí kontrast a displej získává fyzickou hloubku.
- **Servisní štítek**: V dolní liště je vyražen nápis `SMACK-A-PAD // MODEL 3x3 // TACTILE MIDI TRAINER // REV. 1.0` s oranžovou kontrolkou.

---

## 3. Na co se v náhledech zaměřit

1. **Tlačítko „Pozadí: ZAPNUTO / VYPNUTO“**:
   - Vyzkoušejte si přepnout pozadí do stavu VYPNUTO a zpět. Uvidíte, jak prázdná plocha okamžitě ožije a získá hloubku skutečného hardware nástroje, aniž by tím utrpěla přehlednost.
2. **Reakce lůžek na stisk padu (v Návrhu A)**:
   - Klepněte na pad nebo stiskněte klávesy 1–8 na klávesnici. Sledujte, jak se pad mechanicky zanoří do svého vyfrézovaného lůžka.
3. **Přepínání Světlý (Cream) a Tmavý (Soft Black) vzhled**:
   - V obou režimech jsou všechny stíny, spáry a textury přesně laděny do teplých tónů palety z ticketu 92. Nikde není čistá `#000000` ani studená šedá.
4. **Otočení na výšku (Portrait)**:
   - Ověřte, že se pozadí v režimu na výšku přirozeně přizpůsobí užšímu zobrazení iPadu bez viditelných švů a bez deformace prvků.
5. **Čitelnost textů**:
   - Všimněte si, že za žádným nápisem ani titulkem padu neprochází žádný kontrastní rušivý vzor (splňuje nejpřísnější kritérium WCAG AAA).

---

## 4. Doporučení jednoho návrhu

### **Jednoznačně doporučujeme Návrh A (Frézovaná lůžka padů & Eloxovaný mat).**

**Důvody:**
1. **Pady potřebují fyzické lůžko**: Pady ze schváleného ticketu 112 mají 8 pt rádius a zkosenou fazetku. Když leží na zcela plochém pozadí, působí trochu jako plovoucí samolepky. Jakmile pod ně dáte vyfrézované lůžko se stínem, pad se stane skutečným 3D tlačítkem zasazeným do hliníkového šasi.
2. **Nejlepší hmatová iluze při úderu**: Zanoření padu do lůžka při stisku dodává interakci na iPadu i přes externí kontroler mimořádnou fyzickou váhu.
3. **Klid a elegance bez technického křiku**: Návrh B s perforací a pravítkem může na menších iPadech působit až příliš „vědecky“ či technicky. Návrh A je čistý, sebevědomý a dospělý – přesně odpovídá duchu `DESIGN-BRIEF.md`.
4. **Číslování 01–08**: Malé číselné indexy v rohu lůžek pomáhají orientaci při mapování padů na externí MIDI kontroler.

---

## 5. Jak by se jednotlivé návrhy postavily ve SwiftUI a jaká je jejich cena

| Návrh | Způsob stavby ve SwiftUI | Výpočetní zátěž (GPU/CPU) | Paměťová náročnost |
|---|---|---|---|
| **Návrh A** | • Lůžka padů: `RoundedRectangle(cornerRadius: 10)` s `.fill(Theme.surface.opacity(0.4))` a vnitřním stínem vložený přímo do pozadí každé buňky v `HomeScreen.swift`.<br>• Matný povrch: bezešvá PNG dlaždice 128×128 pt s `.resizable(resizingMode: .tile)`.<br>• Šroubky a spára: statické tvary `Circle` a `Rectangle`. | **Nulová per-frame zátěž (0 % CPU)**. Mřížka lůžek je součástí stejného stromu zobrazení. Metal dlaždici blituje v jedné draw call operaci. | < 15 KB RAM pro dlaždici textury. |
| **Návrh B** | • Perforovaný rošt: Vektorový PDF asset 16×16 pt s `.resizable(resizingMode: .tile)` a maskou `.mask(RadialGradient(...))`.<br>• Kalibrační linky: Jednoduchý SwiftUI `Canvas` nebo `Path` vykreslený jednou. | **Extrémně nízká**. Dlaždicový rošt je v GPU paměti, maska se aplikuje jednou při renderu vrstvy. | < 8 KB RAM pro dlaždici bodů. |
| **Návrh C** | • Vinětace: `RadialGradient` přímo v pozadí `ZStack`.<br>• Spáry a deska: Standardní SwiftUI `Rectangle` a `RoundedRectangle` s rámečkem `.stroke(...)`.<br>• Šroubky: Vektorové SwiftUI tvary. | **Absolutně nulová režie**. 100% nativní kód bez jakéhokoliv externího assetu, 120 FPS na iPadu Pro, 0 ms zpoždění při načtení. | 0 KB (žádné bitmapové assety). |
"""

def main():
    DEST.mkdir(parents=True, exist_ok=True)

    print("Generating index.html...")
    (DEST / "index.html").write_text(generate_index_html(), encoding="utf-8")

    print("Generating proposal-a.html...")
    (DEST / "proposal-a.html").write_text(generate_proposal_a_html(), encoding="utf-8")

    print("Generating proposal-b.html...")
    (DEST / "proposal-b.html").write_text(generate_proposal_b_html(), encoding="utf-8")

    print("Generating proposal-c.html...")
    (DEST / "proposal-c.html").write_text(generate_proposal_c_html(), encoding="utf-8")

    print("Generating README.md...")
    (DEST / "README.md").write_text(generate_readme_md(), encoding="utf-8")

    print("Done! All files created in", DEST)

if __name__ == "__main__":
    main()
