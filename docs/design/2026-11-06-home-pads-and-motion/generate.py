#!/usr/bin/env python3
"""
Generate self-contained HTML previews and README for Ticket 111:
Home pads and app motion design proposals.

Produces:
- docs/design/2026-11-06-home-pads-and-motion/index.html
- docs/design/2026-11-06-home-pads-and-motion/proposal-a.html
- docs/design/2026-11-06-home-pads-and-motion/proposal-b.html
- docs/design/2026-11-06-home-pads-and-motion/proposal-c.html
- docs/design/2026-11-06-home-pads-and-motion/README.md
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

# SHARED BASE CSS
SHARED_CSS = f"""
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
  transform: translateY(0);
  opacity: 1;
  transition: opacity 0.25s ease, transform 0.25s ease;
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

/* BASE PAD STYLES */
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
  transition: transform 0.08s ease, background 0.12s ease, box-shadow 0.12s ease, opacity 0.2s ease;
}}

.pad-btn.hero {{
  background: var(--theme-orange);
  color: #1F1D1A;
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

/* ZOOM PLACEHOLDER SCREEN */
.screen-overlay {{
  position: absolute;
  inset: 0;
  background: var(--screen-bg);
  color: var(--ink);
  z-index: 500;
  display: flex;
  flex-direction: column;
  padding: 32px;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.25s ease, transform 0.28s cubic-bezier(0.16, 1, 0.3, 1);
  transform: scale(0.98);
}}

.screen-overlay.active {{
  opacity: 1;
  pointer-events: auto;
  transform: scale(1);
}}

.screen-header {{
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--hairline);
  padding-bottom: 16px;
  margin-bottom: 24px;
}}

.back-btn {{
  background: var(--surface);
  border: 1px solid var(--hairline);
  color: var(--ink);
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 600;
  font-family: inherit;
  border-radius: 0; /* Square button per ticket 94 */
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  transition: background 0.15s ease;
}}

.back-btn:hover {{
  background: var(--ink);
  color: var(--bg);
}}

.screen-title {{
  font-size: 24px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: -0.01em;
}}

.screen-content {{
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: auto;
}}

/* TODAY SESSION (Ticket 109 / 110 layout) */
.today-stage {{
  max-width: 720px;
  margin: 0 auto;
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding-top: 12px;
}}

.today-step-container {{
  position: relative;
  min-height: 220px;
}}

.today-step-card {{
  display: flex;
  flex-direction: column;
  gap: 14px;
  transition: opacity 0.22s ease, transform 0.24s cubic-bezier(0.16, 1, 0.3, 1);
}}

.today-step-card.exiting {{
  opacity: 0;
  transform: translateX(-20px);
  position: absolute;
  inset: 0;
}}

.today-step-card.entering {{
  opacity: 0;
  transform: translateX(24px);
}}

.today-step-tag {{
  font-size: 13px;
  font-weight: 600;
  color: var(--secondary);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}}

.today-verdict {{
  font-size: 30px;
  font-weight: 700;
  line-height: 1.18;
  letter-spacing: -0.02em;
}}

.today-meta {{
  font-size: 16px;
  color: var(--secondary);
}}

.today-next-block {{
  margin-top: 12px;
  padding-top: 16px;
  border-top: 1px solid var(--hairline);
  display: flex;
  flex-direction: column;
  gap: 6px;
}}

.today-next-label {{
  font-size: 12px;
  font-weight: 600;
  color: var(--secondary);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}}

.today-next-title {{
  font-size: 21px;
  font-weight: 600;
}}

.today-actions-row {{
  display: flex;
  align-items: center;
  gap: 12px;
  margin-top: 24px;
}}

.btn-primary {{
  background: var(--theme-orange);
  color: #1F1D1A;
  border: none;
  padding: 13px 26px;
  font-size: 16px;
  font-weight: 700;
  font-family: inherit;
  cursor: pointer;
  border-radius: 0; /* Square per ticket 94 */
  transition: opacity 0.15s ease;
}}

.btn-primary:hover {{
  opacity: 0.92;
}}

.btn-secondary {{
  background: transparent;
  color: var(--ink);
  border: 1px solid var(--hairline);
  padding: 13px 22px;
  font-size: 16px;
  font-weight: 600;
  font-family: inherit;
  cursor: pointer;
  border-radius: 0;
  transition: background 0.15s ease;
}}

.btn-secondary:hover {{
  background: var(--surface);
}}

/* PLACEHOLDER SCREENS CONTENT */
.info-card-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 14px;
  margin-top: 16px;
}}

.info-card {{
  border: 1px solid var(--hairline);
  background: var(--surface);
  padding: 18px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}}

.info-card-title {{
  font-size: 17px;
  font-weight: 600;
}}

.info-card-meta {{
  font-size: 14px;
  color: var(--secondary);
}}

/* HINT NOTIFICATION TOAST */
.hit-toast {{
  position: fixed;
  bottom: 24px;
  right: 24px;
  background: #18181B;
  border: 1px solid #3F3F46;
  color: #FFF;
  padding: 10px 18px;
  border-radius: 4px;
  font-size: 13px;
  font-weight: 500;
  box-shadow: 0 8px 24px rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  gap: 10px;
  opacity: 0;
  transform: translateY(12px);
  transition: opacity 0.2s ease, transform 0.2s ease;
  pointer-events: none;
  z-index: 2000;
}}

.hit-toast.active {{
  opacity: 1;
  transform: translateY(0);
}}

.hit-toast .toast-dot {{
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #FF6B00;
}}

/* REDUCE MOTION ENFORCEMENT */
[data-reduce-motion="true"] *,
[data-reduce-motion="true"] *::before,
[data-reduce-motion="true"] *::after {{
  animation: none !important;
  transition-duration: 0.15s !important;
}}

[data-reduce-motion="true"] .pad-btn:active {{
  transform: none !important;
  background: var(--ink) !important;
  color: var(--bg) !important;
}}
"""

def generate_header(active_id):
    tabs = [
        ("index", "Přehled & Srovnání", "index.html"),
        ("a", "Návrh A (Akai MPC)", "proposal-a.html"),
        ("b", "Návrh B (Maschine)", "proposal-b.html"),
        ("c", "Návrh C (SP-1200)", "proposal-c.html"),
    ]
    tabs_html = ""
    for tid, tlabel, thref in tabs:
        act = " active" if tid == active_id else ""
        tabs_html += f'<a href="{thref}" class="workbench-tab{act}">{tlabel}</a>\n'

    return f"""
<header class="workbench-header">
  <div class="brand-badge">
    <span class="pill">Smack-a-Pad</span>
    <span>Ticket 111 · Návrhy padů & motion</span>
  </div>

  <nav class="workbench-tabs">
    {tabs_html}
  </nav>

  <div class="controls-cluster">
    <button class="ctrl-btn" id="theme-toggle" title="Přepnout Světlý (Cream) / Tmavý (Soft Black) režim">
      <span>Vzhled:</span> <strong id="theme-label">Světlý</strong>
    </button>
    <button class="ctrl-btn" id="orientation-toggle" title="Přepnout iPad na šířku / na výšku">
      <span>Orientace:</span> <strong id="orient-label">Na šířku</strong>
    </button>
    <button class="ctrl-btn" id="motion-toggle" title="Aktivovat Reduce Motion dle pravidel Apple a Ticketu 27">
      <span>Pohyb:</span> <strong id="motion-label">Plný</strong>
    </button>
    <button class="ctrl-btn" id="ios-toggle" title="Přepnout mezi iOS 18 zoomem a iOS 17 fallbackem">
      <span>Zoom:</span> <strong id="ios-label">iOS 18</strong>
    </button>
    <button class="ctrl-btn" id="replay-boot" title="Znovu přehrát náběhovou animaci mřížky (Boot sweep)">
      <span>↺ Replay</span>
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
"""

def generate_pad_grid(proposal_id):
    lit_extra = ""
    if proposal_id == "a":
        lit_extra = '<div class="led-dot" title="3 cvičení k opakování (Spaced repetition)"></div>'
    elif proposal_id == "b":
        lit_extra = '<div class="light-bar" title="3 cvičení k opakování"></div>'
    elif proposal_id == "c":
        lit_extra = '<div class="status-jewel" title="3 cvičení k opakování"><div class="lens"></div><span>DUE</span></div>'

    return f"""
<div class="pad-grid" id="main-pad-grid">
  <!-- Řádek 1: POKRAČOVAT / DNES (1) · KNIHOVNA (2) · TRÉNINK (3) -->
  <button class="pad-btn hero" data-pad="1" data-screen="dnes" title="Klepnutím otevřete obrazovku Dnes">
    <div class="pad-flash"></div>
    <span class="pad-title">POKRAČOVAT</span>
    <span class="pad-subtitle">2 cvičení · pak nová lekce</span>
  </button>

  <button class="pad-btn" data-pad="2" data-screen="knihovna" title="Klepnutím otevřete Knihovnu">
    <div class="pad-flash"></div>
    <span class="pad-title">KNIHOVNA</span>
    <span class="pad-subtitle">42 / 216 ★</span>
  </button>

  <button class="pad-btn lit-pad" data-pad="3" data-screen="trenink" title="Klepnutím otevřete Trénink">
    <div class="pad-flash"></div>
    {lit_extra}
    <span class="pad-title">TRÉNINK</span>
    <span class="pad-subtitle">3 na řadě</span>
  </button>

  <!-- Řádek 2: ÚVODNÍ CVIČENÍ (4) · LOGO MARK · OVLADAČ (5) -->
  <button class="pad-btn" data-pad="4" data-screen="knihovna" title="Klepnutím otevřete Úvodní cvičení">
    <div class="pad-flash"></div>
    <span class="pad-title">ÚVODNÍ CVIČENÍ</span>
    <span class="pad-subtitle">Základy rytmu</span>
  </button>

  <div class="logo-cell" data-pad="logo">
    {LOGO_MARK_SVG}
  </div>

  <button class="pad-btn" data-pad="5" data-screen="ovladac" title="Klepnutím otevřete Nastavení ovladače">
    <div class="pad-flash"></div>
    <span class="pad-title">OVLADAČ</span>
    <span class="pad-subtitle">Akai MPD218</span>
    <span class="pad-sec-subtitle">Standard 16-Pad</span>
  </button>

  <!-- Řádek 3: ODZNAKY (6) · PLNÁ VERZE (7) · NASTAVENÍ (8) -->
  <button class="pad-btn" data-pad="6" data-screen="odznaky" title="Klepnutím otevřete Odznaky">
    <div class="pad-flash"></div>
    <span class="pad-title">ODZNAKY</span>
    <span class="pad-subtitle">4 / 16</span>
  </button>

  <button class="pad-btn" data-pad="7" data-screen="nakup" title="Klepnutím otevřete Plnou verzi">
    <div class="pad-flash"></div>
    <span class="pad-title">PLNÁ VERZE</span>
    <span class="pad-subtitle">Odemknout</span>
  </button>

  <button class="pad-btn" data-pad="8" data-screen="nastaveni" title="Klepnutím otevřete Nastavení">
    <div class="pad-flash"></div>
    <span class="pad-title">NASTAVENÍ</span>
    <span class="pad-subtitle">Zvuk, MIDI, latency</span>
  </button>
</div>
"""

def generate_screens_overlay():
    return """
<!-- SCREEN: DNES / TODAY (Ticket 109 & 110 implementation mockup) -->
<div class="screen-overlay" data-screen="dnes">
  <div class="screen-header">
    <button class="back-btn" data-action="back">← Domů</button>
    <div class="screen-title">DNEŠNÍ TRÉNINK</div>
    <div style="width: 80px;"></div>
  </div>
  <div class="screen-content">
    <div class="today-stage">
      <div class="today-step-container">
        <!-- Step 1 Card -->
        <div class="today-step-card" id="today-card-step1">
          <div class="today-step-tag">OPAKOVÁNÍ 1 ZE 2</div>
          <div class="today-verdict">Výborně · čistý rytmus bez zaváhání</div>
          <div class="today-meta">Rock 2 · Hi-hat eighths · 94 % zpaměti při 100 BPM</div>
          
          <div class="today-next-block">
            <div class="today-next-label">DALŠÍ KROK</div>
            <div class="today-next-title">Funk 1 · Shuffle (opakování 2 ze 2)</div>
          </div>
        </div>

        <!-- Step 2 Card (Hidden initially) -->
        <div class="today-step-card entering" id="today-card-step2" style="display: none;">
          <div class="today-step-tag">OPAKOVÁNÍ 2 ZE 2</div>
          <div class="today-verdict">Skvělá dynamika · 91 % tempo upevněno</div>
          <div class="today-meta">Funk 1 · Shuffle · 91 % zpaměti při 105 BPM</div>
          
          <div class="today-next-block">
            <div class="today-next-label">DALŠÍ KROK</div>
            <div class="today-next-title">Nová lekce: Soul 16ths (1. hvězda)</div>
          </div>
        </div>

        <!-- Step End Card (Hidden initially) -->
        <div class="today-step-card entering" id="today-card-stepend" style="display: none;">
          <div class="today-step-tag">DNEŠNÍ RELACE JE DOKONČENA</div>
          <div class="today-verdict">To je pro dnešek vše! Skvělá práce.</div>
          <div class="today-meta">2 opakování splněna · 1 nová lekce odemčena · 16 minut cvičení</div>
          
          <div class="today-next-block">
            <div class="today-next-label">DALŠÍ TRÉNINK</div>
            <div class="today-next-title">Zítra: 1 cvičení k upevnění rytmu</div>
          </div>
        </div>
      </div>

      <!-- Action buttons in one horizontal row (ticket 110) -->
      <div class="today-actions-row">
        <button class="btn-primary" id="btn-today-continue">Pokračovat</button>
        <button class="btn-secondary" id="btn-today-skip">Přeskočit</button>
        <button class="btn-secondary" id="btn-today-done">Dnes hotovo</button>
      </div>
    </div>
  </div>
</div>

<!-- SCREEN: KNIHOVNA / LIBRARY -->
<div class="screen-overlay" data-screen="knihovna">
  <div class="screen-header">
    <button class="back-btn" data-action="back">← Domů</button>
    <div class="screen-title">KNIHOVNA LEKCÍ</div>
    <div style="font-size: 14px; font-weight: 600;">42 / 216 ★</div>
  </div>
  <div class="screen-content">
    <div class="info-card-grid">
      <div class="info-card">
        <div class="info-card-title">01 · První úder (Kick & Snare)</div>
        <div class="info-card-meta">Základní čtvrtiny · 3 hvězdy ★★★ · Upevněno</div>
      </div>
      <div class="info-card">
        <div class="info-card-title">02 · Osminky na hi-hat</div>
        <div class="info-card-meta">Přímý rytmus · 3 hvězdy ★★★ · Upevněno</div>
      </div>
      <div class="info-card">
        <div class="info-card-title">03 · Rock 1 — Základní beat</div>
        <div class="info-card-meta">Střídání rukou · 2 hvězdy ★★☆ · Opakování zítra</div>
      </div>
      <div class="info-card">
        <div class="info-card-title">04 · Funk 1 — Shuffle</div>
        <div class="info-card-meta">Synkopy na snare · 1 hvězda ★☆☆ · Otevřeno</div>
      </div>
    </div>
  </div>
</div>

<!-- SCREEN: TRÉNINK / TRAINING -->
<div class="screen-overlay" data-screen="trenink">
  <div class="screen-header">
    <button class="back-btn" data-action="back">← Domů</button>
    <div class="screen-title">TRÉNINK & OPAKOVÁNÍ</div>
    <div style="font-size: 14px; font-weight: 600; color: var(--theme-orange);">3 NA ŘADĚ</div>
  </div>
  <div class="screen-content">
    <div style="max-width: 680px; margin: 0 auto; width: 100%;">
      <h3 style="font-size: 18px; margin-bottom: 12px; text-transform: uppercase;">Karta: Na řadě (Due)</h3>
      <div class="info-card-grid" style="grid-template-columns: 1fr;">
        <div class="info-card" style="border-left: 4px solid var(--theme-orange);">
          <div class="info-card-title">Rock 2 · Hi-hat eighths</div>
          <div class="info-card-meta">Krok 2 ze 4 · Zpaměti při 100 BPM (80 % práh)</div>
        </div>
        <div class="info-card" style="border-left: 4px solid var(--theme-orange);">
          <div class="info-card-title">Funk 1 · Shuffle</div>
          <div class="info-card-meta">Krok 1 ze 4 · Zpaměti při 96 BPM</div>
        </div>
        <div class="info-card" style="border-left: 4px solid var(--theme-orange);">
          <div class="info-card-title">Linear 1 · Kick & Ghost note</div>
          <div class="info-card-meta">Krok 3 ze 4 · Zpaměti při 110 BPM</div>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- SCREEN: OVLADAČ / CONTROLLER -->
<div class="screen-overlay" data-screen="ovladac">
  <div class="screen-header">
    <button class="back-btn" data-action="back">← Domů</button>
    <div class="screen-title">NASTAVENÍ OVLADAČE</div>
    <div style="font-size: 14px; font-weight: 600;">PŘIPOJENO</div>
  </div>
  <div class="screen-content">
    <div style="max-width: 600px; margin: 0 auto; width: 100%;">
      <div class="info-card">
        <div class="info-card-title">Aktivní vstup: Akai MPD218</div>
        <div class="info-card-meta">Protokol: CoreMIDI USB · Profil: Standard 16-Pad</div>
        <div style="margin-top: 14px;">
          <button class="btn-secondary" style="padding: 8px 16px; font-size: 14px;">Kalibrovat latenci (aktuálně 1.2 ms)</button>
        </div>
      </div>
    </div>
  </div>
</div>

<!-- SCREEN: ODZNAKY / BADGES -->
<div class="screen-overlay" data-screen="odznaky">
  <div class="screen-header">
    <button class="back-btn" data-action="back">← Domů</button>
    <div class="screen-title">ODZNAKY & VÝZVY</div>
    <div style="font-size: 14px; font-weight: 600;">4 / 16 ZÍSKÁNO</div>
  </div>
  <div class="screen-content">
    <div class="info-card-grid">
      <div class="info-card">
        <div class="info-card-title">První úder ★</div>
        <div class="info-card-meta">Získejte první hvězdu v kterékoli lekci.</div>
      </div>
      <div class="info-card">
        <div class="info-card-title">Železná ruka ★</div>
        <div class="info-card-meta">Odehrajte 4 takty se 100% čistotou bez jediného zaváhání.</div>
      </div>
      <div class="info-card">
        <div class="info-card-title">Poutník paměti ★</div>
        <div class="info-card-meta">Úspěšně upevněte první lekci zpaměti ve 4 krocích.</div>
      </div>
    </div>
  </div>
</div>

<!-- SCREEN: NASTAVENÍ / SETTINGS -->
<div class="screen-overlay" data-screen="nastaveni">
  <div class="screen-header">
    <button class="back-btn" data-action="back">← Domů</button>
    <div class="screen-title">NASTAVENÍ APLIKACE</div>
    <div style="font-size: 14px; font-weight: 600;">v1.4.2</div>
  </div>
  <div class="screen-content">
    <div style="max-width: 600px; margin: 0 auto; width: 100%;">
      <div class="info-card">
        <div class="info-card-title">Zvuková souprava: Roland TR-808 Studio</div>
        <div class="info-card-meta">Sample rate: 48 kHz · Audio latency buffer: 64 frames (1.3 ms)</div>
      </div>
      <div class="info-card" style="margin-top: 14px;">
        <div class="info-card-title">O aplikaci Smack-a-Pad</div>
        <div class="info-card-meta">Písmo: IBM Plex Sans (SIL Open Font License 1.1)</div>
        <div class="info-card-meta" style="margin-top: 4px;">Vyvinuto nativně ve SwiftUI pro iPadOS.</div>
      </div>
    </div>
  </div>
</div>

<!-- SCREEN: PLNÁ VERZE / NÁKUP -->
<div class="screen-overlay" data-screen="nakup">
  <div class="screen-header">
    <button class="back-btn" data-action="back">← Domů</button>
    <div class="screen-title">PLNÁ VERZE</div>
    <div style="font-size: 14px; font-weight: 600; color: var(--theme-orange);">ODEMKNOUT</div>
  </div>
  <div class="screen-content">
    <div style="max-width: 600px; margin: 0 auto; width: 100%; text-align: center; padding-top: 20px;">
      <h2 style="font-size: 28px; margin-bottom: 12px;">Odemkněte všech 72 lekcí & 6 zvukových sad</h2>
      <p style="color: var(--secondary); margin-bottom: 24px; font-size: 16px;">Jednorázový nákup pro iPad. Žádné předplatné.</p>
      <button class="btn-primary" style="padding: 14px 32px; font-size: 18px;">Odemknout plnou verzi</button>
    </div>
  </div>
</div>
"""

def generate_interactive_script(proposal_id):
    return f"""
<script>
(function() {{
  const proposalId = "{proposal_id}";
  let isDarkMode = false;
  let isPortrait = false;
  let isReduceMotion = false;
  let isIOS18 = true;
  let activeZoomPad = null;
  let todayStep = 1;

  // DOM Elements
  const body = document.body;
  const chassis = document.getElementById("ipad-chassis");
  const padGrid = document.getElementById("main-pad-grid");
  const themeToggle = document.getElementById("theme-toggle");
  const themeLabel = document.getElementById("theme-label");
  const orientationToggle = document.getElementById("orientation-toggle");
  const orientLabel = document.getElementById("orient-label");
  const motionToggle = document.getElementById("motion-toggle");
  const motionLabel = document.getElementById("motion-label");
  const iosToggle = document.getElementById("ios-toggle");
  const iosLabel = document.getElementById("ios-label");
  const replayBtn = document.getElementById("replay-boot");
  const hitToast = document.getElementById("hit-toast");
  const toastText = document.getElementById("toast-text");

  // Overlays
  const overlays = document.querySelectorAll(".screen-overlay");
  const backButtons = document.querySelectorAll(".back-btn");

  // 1. Theme toggle
  themeToggle.addEventListener("click", () => {{
    isDarkMode = !isDarkMode;
    if (isDarkMode) {{
      body.setAttribute("data-theme", "dark");
      themeLabel.textContent = "Tmavý";
      themeToggle.classList.add("active");
    }} else {{
      body.removeAttribute("data-theme");
      themeLabel.textContent = "Světlý";
      themeToggle.classList.remove("active");
    }}
  }});

  // 2. Orientation toggle
  orientationToggle.addEventListener("click", () => {{
    isPortrait = !isPortrait;
    if (isPortrait) {{
      chassis.classList.remove("landscape");
      chassis.classList.add("portrait");
      orientLabel.textContent = "Na výšku";
      orientationToggle.classList.add("active");
    }} else {{
      chassis.classList.remove("portrait");
      chassis.classList.add("landscape");
      orientLabel.textContent = "Na šířku";
      orientationToggle.classList.remove("active");
    }}
  }});

  // 3. Motion toggle (Reduce motion policy)
  motionToggle.addEventListener("click", () => {{
    isReduceMotion = !isReduceMotion;
    if (isReduceMotion) {{
      body.setAttribute("data-reduce-motion", "true");
      motionLabel.textContent = "Omezený";
      motionToggle.classList.add("active");
    }} else {{
      body.removeAttribute("data-reduce-motion");
      motionLabel.textContent = "Plný";
      motionToggle.classList.remove("active");
    }}
  }});

  // 4. iOS 18 Zoom vs iOS 17 Fallback
  iosToggle.addEventListener("click", () => {{
    isIOS18 = !isIOS18;
    if (isIOS18) {{
      iosLabel.textContent = "iOS 18";
      iosToggle.classList.remove("active");
    }} else {{
      iosLabel.textContent = "iOS 17";
      iosToggle.classList.add("active");
    }}
  }});

  // 5. Toast trigger
  let toastTimer = null;
  function showToast(msg) {{
    toastText.textContent = msg;
    hitToast.classList.add("active");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {{
      hitToast.classList.remove("active");
    }}, 1600);
  }}

  // 6. External MIDI Trigger simulator
  function triggerMidiHit(padNumber) {{
    const pad = document.querySelector(`.pad-btn[data-pad="${{padNumber}}"]`);
    if (!pad) return;

    pad.classList.add("midi-hit");
    const flash = pad.querySelector(".pad-flash");
    if (flash) flash.style.opacity = isDarkMode ? "0.6" : "0.45";

    const padTitle = pad.querySelector(".pad-title")?.textContent || `Pad ${{padNumber}}`;
    showToast(`MIDI úder: ${{padTitle}} (Pad ${{padNumber}})`);

    setTimeout(() => {{
      pad.classList.remove("midi-hit");
      if (flash) flash.style.opacity = "";
    }}, isReduceMotion ? 100 : 160);
  }}

  document.querySelectorAll(".midi-trigger-btn").forEach(btn => {{
    btn.addEventListener("click", (e) => {{
      e.stopPropagation();
      const p = btn.getAttribute("data-pad");
      triggerMidiHit(p);
    }});
  }});

  window.addEventListener("keydown", (e) => {{
    if (e.key >= "1" && e.key <= "8") {{
      triggerMidiHit(e.key);
    }} else if (e.key === "Escape") {{
      closeAllScreens();
    }}
  }});

  // 7. Boot sequence animation (Replay)
  function runBootSequence() {{
    const pads = document.querySelectorAll(".pad-btn");
    if (isReduceMotion) {{
      padGrid.style.opacity = "0";
      setTimeout(() => {{
        padGrid.style.transition = "opacity 0.2s ease";
        padGrid.style.opacity = "1";
      }}, 30);
      return;
    }}

    pads.forEach(p => {{
      p.style.opacity = "0";
      p.style.transform = "scale(0.85)";
    }});

    if (proposalId === "a") {{
      // Diagonal wave sweep (0 to 8)
      pads.forEach((p, idx) => {{
        setTimeout(() => {{
          p.style.transition = "opacity 0.28s ease, transform 0.28s cubic-bezier(0.16, 1, 0.3, 1)";
          p.style.opacity = "1";
          p.style.transform = "scale(1)";
        }}, idx * 45);
      }});
    }} else if (proposalId === "b") {{
      // Radial matrix burst from center
      const cross = [document.querySelector('[data-pad="2"]'), document.querySelector('[data-pad="4"]'),
                     document.querySelector('[data-pad="5"]'), document.querySelector('[data-pad="7"]')];
      const corners = [document.querySelector('[data-pad="1"]'), document.querySelector('[data-pad="3"]'),
                       document.querySelector('[data-pad="6"]'), document.querySelector('[data-pad="8"]')];
      
      setTimeout(() => {{
        cross.forEach(p => {{
          if (p) {{
            p.style.transition = "opacity 0.26s ease, transform 0.26s cubic-bezier(0.16, 1, 0.3, 1)";
            p.style.opacity = "1";
            p.style.transform = "scale(1)";
          }}
        }});
      }}, 80);

      setTimeout(() => {{
        corners.forEach(p => {{
          if (p) {{
            p.style.transition = "opacity 0.26s ease, transform 0.26s cubic-bezier(0.16, 1, 0.3, 1)";
            p.style.opacity = "1";
            p.style.transform = "scale(1)";
          }}
        }});
      }}, 190);
    }} else {{
      // Row by row self-test
      [ [1,2,3], [4,5], [6,7,8] ].forEach((row, rIdx) => {{
        setTimeout(() => {{
          row.forEach(pNum => {{
            const p = document.querySelector(`.pad-btn[data-pad="${{pNum}}"]`);
            if (p) {{
              p.style.transition = "opacity 0.22s ease, transform 0.22s ease-out";
              p.style.opacity = "1";
              p.style.transform = "scale(1)";
            }}
          }});
        }}, rIdx * 70);
      }});
    }}
  }}

  replayBtn.addEventListener("click", runBootSequence);

  // 8. Pad Click -> Screen Zoom
  document.querySelectorAll(".pad-btn").forEach(pad => {{
    pad.addEventListener("click", () => {{
      const screenId = pad.getAttribute("data-screen");
      if (!screenId) return;

      const targetOverlay = document.querySelector(`.screen-overlay[data-screen="${{screenId}}"]`);
      if (!targetOverlay) return;

      activeZoomPad = pad;

      if (isReduceMotion) {{
        // Reduce Motion: pure opacity crossfade
        targetOverlay.style.transition = "opacity 0.15s ease";
        targetOverlay.style.transform = "none";
        targetOverlay.classList.add("active");
        return;
      }}

      if (!isIOS18) {{
        // iOS 17 fallback: scale 0.98 -> 1.0 + fade
        targetOverlay.style.transition = "opacity 0.20s ease, transform 0.20s ease-out";
        targetOverlay.style.transform = "scale(1)";
        targetOverlay.classList.add("active");
        return;
      }}

      // iOS 18 Zoom: Expand from pad rect
      const padRect = pad.getBoundingClientRect();
      const chassisRect = chassis.getBoundingClientRect();

      const startLeft = padRect.left - chassisRect.left;
      const startTop = padRect.top - chassisRect.top;
      const startW = padRect.width;
      const startH = padRect.height;

      // Animate overlay zoom
      targetOverlay.style.transition = "none";
      targetOverlay.style.clipPath = `inset(${{startTop}}px ${{chassisRect.width - (startLeft + startW)}}px ${{chassisRect.height - (startTop + startH)}}px ${{startLeft}}px round ${{proposalId === 'a' ? 8 : (proposalId === 'b' ? 12 : 5)}}px)`;
      targetOverlay.style.opacity = "1";
      targetOverlay.classList.add("active");

      requestAnimationFrame(() => {{
        targetOverlay.style.transition = "clip-path 0.28s cubic-bezier(0.16, 1, 0.3, 1)";
        targetOverlay.style.clipPath = "inset(0px 0px 0px 0px round 0px)";
      }});
    }});
  }});

  // 9. Close Zoom / Back to Home
  function closeAllScreens() {{
    overlays.forEach(ov => {{
      if (!ov.classList.contains("active")) return;

      if (isReduceMotion || !isIOS18 || !activeZoomPad) {{
        ov.style.transition = "opacity 0.18s ease";
        ov.style.opacity = "0";
        setTimeout(() => {{
          ov.classList.remove("active");
          ov.style.clipPath = "";
        }}, 180);
        return;
      }}

      // Reverse zoom into pad
      const padRect = activeZoomPad.getBoundingClientRect();
      const chassisRect = chassis.getBoundingClientRect();

      const endLeft = padRect.left - chassisRect.left;
      const endTop = padRect.top - chassisRect.top;
      const endW = padRect.width;
      const endH = padRect.height;

      ov.style.transition = "clip-path 0.24s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.24s ease";
      ov.style.clipPath = `inset(${{endTop}}px ${{chassisRect.width - (endLeft + endW)}}px ${{chassisRect.height - (endTop + endH)}}px ${{endLeft}}px round ${{proposalId === 'a' ? 8 : (proposalId === 'b' ? 12 : 5)}}px)`;
      ov.style.opacity = "0.2";

      setTimeout(() => {{
        ov.classList.remove("active");
        ov.style.clipPath = "";
        ov.style.opacity = "";
      }}, 240);
    }});
  }}

  backButtons.forEach(btn => {{
    btn.addEventListener("click", closeAllScreens);
  }});

  // 10. Today Session Interactive Stepping (Ticket 109 / 110)
  const cardStep1 = document.getElementById("today-card-step1");
  const cardStep2 = document.getElementById("today-card-step2");
  const cardStepEnd = document.getElementById("today-card-stepend");
  const btnContinue = document.getElementById("btn-today-continue");
  const btnSkip = document.getElementById("btn-today-skip");
  const btnDone = document.getElementById("btn-today-done");

  function transitionTodayStep(nextStep) {{
    const currentCard = todayStep === 1 ? cardStep1 : (todayStep === 2 ? cardStep2 : cardStepEnd);
    const nextCard = nextStep === 2 ? cardStep2 : cardStepEnd;

    if (isReduceMotion) {{
      currentCard.style.display = "none";
      nextCard.style.display = "flex";
      nextCard.classList.remove("entering");
      todayStep = nextStep;
      if (todayStep === 3) {{
        btnContinue.textContent = "Zpět na Home";
      }}
      return;
    }}

    // Slide out current card
    currentCard.classList.add("exiting");
    setTimeout(() => {{
      currentCard.style.display = "none";
      currentCard.classList.remove("exiting");

      nextCard.style.display = "flex";
      requestAnimationFrame(() => {{
        nextCard.classList.remove("entering");
      }});
      todayStep = nextStep;
      if (todayStep === 3) {{
        btnContinue.textContent = "Zpět na Home";
      }}
    }}, 160);
  }}

  if (btnContinue) {{
    btnContinue.addEventListener("click", () => {{
      if (todayStep === 1) {{
        transitionTodayStep(2);
      }} else if (todayStep === 2) {{
        transitionTodayStep(3);
      }} else {{
        // Reset and back to home
        closeAllScreens();
        setTimeout(() => {{
          cardStepEnd.style.display = "none";
          cardStepEnd.classList.add("entering");
          cardStep2.style.display = "none";
          cardStep2.classList.add("entering");
          cardStep1.style.display = "flex";
          btnContinue.textContent = "Pokračovat";
          todayStep = 1;
        }}, 300);
      }}
    }});
  }}

  if (btnSkip) {{
    btnSkip.addEventListener("click", () => {{
      if (todayStep === 1) transitionTodayStep(2);
      else transitionTodayStep(3);
    }});
  }}

  if (btnDone) {{
    btnDone.addEventListener("click", () => {{
      closeAllScreens();
    }});
  }}

}})();
</script>
"""

# PROPOSAL SPECIFIC STYLES
def get_proposal_css(proposal_id):
    if proposal_id == "a":
        # Proposal A: Akai MPC Tactile Rubber (8 pt radius, inset bevel shade, backlight halo)
        return """
/* --- PROPOSAL A: AKAI MPC TACTILE RUBBER --- */
.pad-btn {
  border-radius: 8px;
  box-shadow: 
    inset 0 1.5px 0 var(--pad-bevel-top),
    inset 0 -2px 0 var(--pad-bevel-bottom),
    0 0 0 1px var(--hairline),
    0 2px 4px rgba(0, 0, 0, 0.08);
}

.pad-btn.hero {
  background: var(--theme-orange);
  box-shadow: 
    inset 0 1.5px 0 rgba(255, 255, 255, 0.42),
    inset 0 -2.5px 0 rgba(0, 0, 0, 0.28),
    0 0 0 1px rgba(0, 0, 0, 0.12),
    0 3px 6px rgba(255, 107, 0, 0.25);
}

.pad-btn.lit-pad {
  box-shadow: 
    inset 0 1.5px 0 var(--pad-bevel-top),
    inset 0 -2px 0 var(--pad-bevel-bottom),
    0 0 0 2px var(--theme-orange),
    0 0 14px var(--theme-orange-glow);
}

.led-dot {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 9px;
  height: 9px;
  border-radius: 50%;
  background: var(--theme-orange);
  box-shadow: 0 0 6px var(--theme-orange);
  animation: ledBreathA 2.4s ease-in-out infinite;
}

@keyframes ledBreathA {
  0%, 100% { opacity: 0.55; transform: scale(0.9); }
  50% { opacity: 1.0; transform: scale(1.15); box-shadow: 0 0 9px var(--theme-orange); }
}

.pad-btn:active, .pad-btn.midi-hit {
  transform: scale(0.965) translateY(1.5px);
  box-shadow: 
    inset 0 1px 2px rgba(0, 0, 0, 0.35),
    0 0 0 1px var(--hairline);
  transition-duration: 0.05s;
}

.pad-btn:active .pad-flash, .pad-btn.midi-hit .pad-flash {
  opacity: 0.38;
}
"""
    elif proposal_id == "b":
        # Proposal B: Maschine / Push Milk-Silicone Backlit (12 pt radius, perimeter light-strip)
        return """
/* --- PROPOSAL B: MASCHINE MILK-SILICONE BACKLIT --- */
.pad-btn {
  border-radius: 12px;
  box-shadow: 
    0 0 0 2px var(--hairline),
    inset 0 0 0 1px rgba(255, 255, 255, 0.08);
}

.pad-btn.hero {
  background: var(--theme-orange);
  box-shadow: 
    0 0 0 2.5px rgba(255, 107, 0, 0.35),
    inset 0 0 0 1.5px rgba(255, 255, 255, 0.25);
}

.pad-btn.lit-pad {
  box-shadow: 
    0 0 0 2.5px var(--theme-orange),
    0 0 16px var(--theme-orange-glow);
}

.light-bar {
  position: absolute;
  top: 7px;
  left: 22%;
  right: 22%;
  height: 2px;
  border-radius: 1px;
  background: var(--theme-orange);
  box-shadow: 0 0 6px var(--theme-orange);
  animation: barBreathB 3.2s ease-in-out infinite;
}

@keyframes barBreathB {
  0%, 100% { opacity: 0.45; }
  50% { opacity: 1.0; box-shadow: 0 0 10px var(--theme-orange); }
}

.pad-btn:active, .pad-btn.midi-hit {
  transform: scale(0.975);
  box-shadow: 
    0 0 0 2px var(--hairline),
    inset 0 0 10px rgba(0, 0, 0, 0.2);
  transition-duration: 0.04s;
}

.pad-btn:active .pad-flash, .pad-btn.midi-hit .pad-flash {
  opacity: 0.48;
}
"""
    elif proposal_id == "c":
        # Proposal C: SP-1200 / TR-808 Industrial Metal Collar (5 pt radius, metal collar & status jewel LED)
        return """
/* --- PROPOSAL C: SP-1200 / TR-808 METAL COLLAR --- */
.pad-btn {
  border-radius: 5px;
  box-shadow: 
    0 0 0 2px var(--chassis-edge),
    inset 0 1px 0 rgba(255, 255, 255, 0.28),
    inset 0 -1.5px 0 rgba(0, 0, 0, 0.22),
    0 3px 5px rgba(0, 0, 0, 0.12);
}

.pad-btn.hero {
  background: var(--theme-orange);
  box-shadow: 
    0 0 0 2px rgba(31, 29, 26, 0.35),
    inset 0 1.5px 0 rgba(255, 255, 255, 0.4),
    inset 0 -2px 0 rgba(0, 0, 0, 0.3),
    0 3px 6px rgba(0, 0, 0, 0.18);
}

.pad-btn.lit-pad {
  box-shadow: 
    0 0 0 2px var(--chassis-edge),
    inset 0 1px 0 rgba(255, 255, 255, 0.28),
    inset 0 -1.5px 0 rgba(0, 0, 0, 0.22),
    0 0 0 1px var(--theme-orange);
}

.status-jewel {
  position: absolute;
  top: 8px;
  right: 8px;
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 9px;
  font-weight: 700;
  letter-spacing: 0.05em;
  color: var(--theme-orange);
}

.status-jewel .lens {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #FFA740, #FF6B00 65%, #A33A00);
  box-shadow: 0 0 0 1.5px #1F1D1A, 0 0 6px var(--theme-orange);
  animation: jewelGlowC 2.0s ease-in-out infinite;
}

@keyframes jewelGlowC {
  0%, 100% { opacity: 0.65; }
  50% { opacity: 1.0; box-shadow: 0 0 0 1.5px #1F1D1A, 0 0 9px var(--theme-orange); }
}

.pad-btn:active, .pad-btn.midi-hit {
  transform: translateY(2px) scale(0.985);
  box-shadow: 
    0 0 0 2px var(--chassis-edge),
    inset 0 1.5px 3px rgba(0, 0, 0, 0.45);
  transition-duration: 0.05s;
}

.pad-btn:active .pad-flash, .pad-btn.midi-hit .pad-flash {
  opacity: 0.28;
}
"""
    return ""

def build_proposal_page(proposal_id, title_cs, token_radius, desc_cs):
    proposal_css = get_proposal_css(proposal_id)
    header_html = generate_header(proposal_id)
    grid_html = generate_pad_grid(proposal_id)
    screens_html = generate_screens_overlay()
    script_html = generate_interactive_script(proposal_id)

    html = f"""<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Smack-a-Pad — {title_cs} (Ticket 111)</title>
  <style>
{SHARED_CSS}
{proposal_css}
  </style>
</head>
<body>

{header_html}

<main class="workbench-viewport">
  <div class="ipad-chassis landscape" id="ipad-chassis">
    <!-- Home Screen -->
    <div class="home-screen">
      <div class="brand-header-area">
        {WORDMARK_SVG}
      </div>

      {grid_html}
    </div>

    <!-- Zoom Destination Screens Overlay -->
    {screens_html}
  </div>
</main>

<div class="hit-toast" id="hit-toast">
  <div class="toast-dot"></div>
  <span id="toast-text">MIDI úder zaznamenán</span>
</div>

{script_html}

</body>
</html>
"""
    return html

# -------------------------------------------------------------
# BUILD INDEX / COMPARATIVE WORKBENCH
# -------------------------------------------------------------
def build_index_page():
    header_html = generate_header("index")
    
    html = f"""<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Smack-a-Pad — Přehled & srovnání návrhů (Ticket 111)</title>
  <style>
{SHARED_CSS}

/* INDEX SPECIFIC STYLES */
.index-container {{
  max-width: 1140px;
  margin: 0 auto;
  padding: 40px 24px 80px 24px;
}}

.hero-intro {{
  margin-bottom: 40px;
}}

.hero-intro h1 {{
  font-size: 32px;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin-bottom: 12px;
  color: #FFF;
}}

.hero-intro p {{
  font-size: 17px;
  line-height: 1.5;
  color: #A1A1AA;
  max-width: 840px;
}}

.proposals-grid {{
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 48px;
}}

.proposal-card {{
  background: #18181B;
  border: 1px solid #27272A;
  border-radius: 8px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  transition: transform 0.2s ease, border-color 0.2s ease;
  position: relative;
  overflow: hidden;
}}

.proposal-card:hover {{
  border-color: #3F3F46;
  transform: translateY(-2px);
}}

.proposal-card.recommended {{
  border-color: #FF6B00;
  box-shadow: 0 0 0 1px #FF6B00;
}}

.rec-badge {{
  position: absolute;
  top: 14px;
  right: 14px;
  background: #FF6B00;
  color: #1F1D1A;
  font-size: 10px;
  font-weight: 700;
  text-transform: uppercase;
  padding: 3px 8px;
  border-radius: 2px;
  letter-spacing: 0.05em;
}}

.card-tag {{
  font-size: 12px;
  font-weight: 600;
  color: #71717A;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 6px;
}}

.card-title {{
  font-size: 22px;
  font-weight: 700;
  color: #FFF;
  margin-bottom: 8px;
}}

.card-desc {{
  font-size: 14px;
  line-height: 1.45;
  color: #A1A1AA;
  margin-bottom: 20px;
  flex: 1;
}}

.card-preview-stage {{
  background: #0E0E10;
  border: 1px solid #27272A;
  border-radius: 6px;
  padding: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 20px;
}}

.card-preview-pad {{
  width: 110px;
  height: 110px;
  background: #EBE5DA;
  color: #1F1D1A;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  user-select: none;
  text-align: center;
  padding: 8px;
  position: relative;
}}

/* Card specific pad styles for preview */
.preview-a {{
  border-radius: 8px;
  box-shadow: inset 0 1.5px 0 rgba(255,255,255,0.6), inset 0 -2px 0 rgba(0,0,0,0.18), 0 0 0 1px rgba(31,29,26,0.15), 0 2px 4px rgba(0,0,0,0.08);
}}
.preview-a:active {{
  transform: scale(0.965) translateY(1.5px);
}}

.preview-b {{
  border-radius: 12px;
  box-shadow: 0 0 0 2px rgba(31,29,26,0.18), inset 0 0 0 1px rgba(255,255,255,0.2);
}}
.preview-b:active {{
  transform: scale(0.975);
}}

.preview-c {{
  border-radius: 5px;
  box-shadow: 0 0 0 2px rgba(31,29,26,0.18), inset 0 1px 0 rgba(255,255,255,0.4), inset 0 -1.5px 0 rgba(0,0,0,0.22), 0 3px 5px rgba(0,0,0,0.12);
}}
.preview-c:active {{
  transform: translateY(2px) scale(0.985);
}}

.card-link-btn {{
  background: #27272A;
  color: #FFF;
  border: 1px solid #3F3F46;
  padding: 10px 16px;
  text-align: center;
  text-decoration: none;
  font-weight: 600;
  font-size: 14px;
  border-radius: 4px;
  transition: background 0.15s ease;
}}

.card-link-btn:hover {{
  background: #3F3F46;
}}

.proposal-card.recommended .card-link-btn {{
  background: #FF6B00;
  color: #1F1D1A;
  border-color: #FF6B00;
}}

.proposal-card.recommended .card-link-btn:hover {{
  opacity: 0.9;
}}

/* COMPARISON TABLE */
.table-section {{
  margin-top: 48px;
}}

.table-section h2 {{
  font-size: 24px;
  font-weight: 700;
  color: #FFF;
  margin-bottom: 16px;
}}

.comp-table {{
  width: 100%;
  border-collapse: collapse;
  background: #18181B;
  border: 1px solid #27272A;
  border-radius: 8px;
  overflow: hidden;
  font-size: 14px;
}}

.comp-table th, .comp-table td {{
  padding: 14px 18px;
  text-align: left;
  border-bottom: 1px solid #27272A;
}}

.comp-table th {{
  background: #121214;
  color: #A1A1AA;
  font-weight: 600;
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}}

.comp-table tr:last-child td {{
  border-bottom: none;
}}

.comp-table td:first-child {{
  font-weight: 600;
  color: #FFF;
  width: 20%;
}}

.comp-table td {{
  color: #D4D4D8;
  line-height: 1.45;
}}

.comp-table .rec-col {{
  background: rgba(255, 107, 0, 0.05);
}}

/* MOTION SPECIFICATION TABLE */
.token-code {{
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  font-size: 12px;
  background: #27272A;
  padding: 2px 6px;
  border-radius: 3px;
  color: #FF6B00;
}}
</style>
</head>
<body>

{header_html}

<main class="index-container">
  <div class="hero-intro">
    <h1>Domovská padová mřížka & systém pohybu</h1>
    <p>
      Podrobný přehled tří svébytných návrhů řešících zadání <strong>Ticketu 111</strong>: přeměnu plochých dlaždic na autentické kontrolerové pady s hmatovou hloubkou, jasným stavem rozsvícení pro opakování lekcí a moderními plynulými přechody pro celý chrome aplikace.
    </p>
  </div>

  <div class="proposals-grid">
    <!-- NÁVRH A -->
    <div class="proposal-card recommended">
      <span class="rec-badge">Doporučeno</span>
      <div class="card-tag">Návrh A · Radius 8 pt</div>
      <div class="card-title">Akai MPC Tactile Rubber</div>
      <div class="card-desc">
        Hutný, taktilní silikonový pad s fazetkou (horní hrana se světelným akcentem a spodní měkký stín). Při stisku mechanické stlačení a rychlý záblesk. Diagonální náběh mřížky a zoom do obrazovky z rámečku padu.
      </div>
      <div class="card-preview-stage">
        <div class="card-preview-pad preview-a" onclick="this.classList.toggle('active')">
          <strong style="font-size: 13px;">TRÉNINK</strong>
          <span style="font-size: 11px; color: #5E5950; margin-top: 4px;">3 na řadě</span>
          <div style="position: absolute; top: 6px; right: 6px; width: 7px; height: 7px; border-radius: 50%; background: #FF6B00;"></div>
        </div>
      </div>
      <a href="proposal-a.html" class="card-link-btn">Otevřít interaktivní náhled A →</a>
    </div>

    <!-- NÁVRH B -->
    <div class="proposal-card">
      <div class="card-tag">Návrh B · Radius 12 pt</div>
      <div class="card-title">Maschine Milk-Silicone</div>
      <div class="card-desc">
        Moderní mléčný difuzní silikon s obvodovým světlovodným kanálkem a horním proužkem. Bleskový luminescenční záblesk plochy, měkké radiální rozsvícení od loga a rozptyl rámečku padu do celé obrazovky.
      </div>
      <div class="card-preview-stage">
        <div class="card-preview-pad preview-b" onclick="this.classList.toggle('active')">
          <strong style="font-size: 13px;">TRÉNINK</strong>
          <span style="font-size: 11px; color: #5E5950; margin-top: 4px;">3 na řadě</span>
          <div style="position: absolute; top: 5px; left: 25%; right: 25%; height: 2px; background: #FF6B00; border-radius: 1px;"></div>
        </div>
      </div>
      <a href="proposal-b.html" class="card-link-btn">Otevřít interaktivní náhled B →</a>
    </div>

    <!-- NÁVRH C -->
    <div class="proposal-card">
      <div class="card-tag">Návrh C · Radius 5 pt</div>
      <div class="card-title">SP-1200 Metal Collar</div>
      <div class="card-desc">
        Industriální hardware zapuštěný do kovového šasi s lemem a fazetou. Klenutá LED kontrolka s označením DUE. Ostrý mechanický stisk bez zpoždění a sekvenční boot po řádcích jako u vintage syntezátorů.
      </div>
      <div class="card-preview-stage">
        <div class="card-preview-pad preview-c" onclick="this.classList.toggle('active')">
          <strong style="font-size: 13px;">TRÉNINK</strong>
          <span style="font-size: 11px; color: #5E5950; margin-top: 4px;">3 na řadě</span>
          <div style="position: absolute; top: 6px; right: 6px; display: flex; align-items: center; gap: 2px;">
            <div style="width: 6px; height: 6px; border-radius: 50%; background: #FF6B00;"></div>
            <span style="font-size: 8px; font-weight: 700; color: #FF6B00;">DUE</span>
          </div>
        </div>
      </div>
      <a href="proposal-c.html" class="card-link-btn">Otevřít interaktivní náhled C →</a>
    </div>
  </div>

  <!-- SROVNÁVACÍ TABULKA -->
  <section class="table-section">
    <h2>Srovnání parametrů & charakteru</h2>
    <table class="comp-table">
      <thead>
        <tr>
          <th>Parametr</th>
          <th class="rec-col">Návrh A: Akai MPC Rubber (Doporučeno)</th>
          <th>Návrh B: Maschine Milk-Silicone</th>
          <th>Návrh C: SP-1200 Metal Collar</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Vizuální charakter</td>
          <td class="rec-col">Hutný, hmatový silikonový blok; přirozená fyzická substance bicího kontroleru.</td>
          <td>Hladký, difuzní mléčný silikon moderních kontrolerů (Push/Maschine).</td>
          <td>Strojní hardware zasazený do kovového panelu (Roland 808 / SP-1200).</td>
        </tr>
        <tr>
          <td>Token zaoblení</td>
          <td class="rec-col"><span class="token-code">Theme.Radius.pad = 8 pt</span></td>
          <td><span class="token-code">Theme.Radius.pad = 12 pt</span></td>
          <td><span class="token-code">Theme.Radius.pad = 5 pt</span></td>
        </tr>
        <tr>
          <td>Hloubka & materiál</td>
          <td class="rec-col">Horní světelná hrana + spodní 2px stín; dojem 4mm vyvýšeného silikonu v šasi.</td>
          <td>Zapuštěný 2px difuzní kanálek po obvodu, rovná lícní plocha.</td>
          <td>Vnější 2px rámeček šasi + 1px vnitřní stín zapuštění; pad pevně sedí v panelu.</td>
        </tr>
        <tr>
          <td>Svítící stav (Trénink)</td>
          <td class="rec-col">Oranžový obvodový rámeček + pomalu dýchající kruhová kontrolka LED (2.4s).</td>
          <td>Kompletně rozsvícený difuzní obvod + integrovaný vodorovný světelný proužek (3.2s).</td>
          <td>Vyražená klenutá LED čočka s mosazným lemem a mikroštítkem DUE (2.0s žhavení).</td>
        </tr>
        <tr>
          <td>Odezva na úder / stisk</td>
          <td class="rec-col">Ztlačení (scale 0.965, y: 1.5px), bleskový záblesk (60ms) a pružný návrat (0.18s spring).</td>
          <td>Plošný luminescenční záblesk (40ms), lehký squash (0.975), měkký rozpad.</td>
          <td>Ostrý mechanický ráz (y: 2px, 0.07s), ztmavnutí hrany lůžka, okamžitý odskok.</td>
        </tr>
        <tr>
          <td>Náběh mřížky (Boot)</td>
          <td class="rec-col">Diagonální vlna (pad 1 → pad 8, 40ms odstup), rozsvícení hran a usazení.</td>
          <td>Radiální záblesk od středu (křížové pady v 0.08s, rohové v 0.18s).</td>
          <td>Sekvenční hardware self-test (řádek 1, 2, 3 po 60ms jako při zapnutí pultu).</td>
        </tr>
        <tr>
          <td>Zoom pad → obrazovka</td>
          <td class="rec-col">iOS 18 zoom z rámečku padu (0.28s spring); iOS 17 fallback: fade + scale 0.98.</td>
          <td>Tvarový rozptyl obvodu padu do celé obrazovky (0.30s spring); fallback: 0.20s fade.</td>
          <td>Přímá projekce průzoru (0.22s ease-out); fallback: scale 0.98 + 0.15s fade.</td>
        </tr>
        <tr>
          <td>Krokování Dnes (109/110)</td>
          <td class="rec-col">Karta plynule odjede vlevo a nová vstoupí zprava; tlačítka drží fixní pozici.</td>
          <td>Kaskádový nájezd textů s odstupem 60ms; tlačítka pevně ukotvena v liště.</td>
          <td>Okamžitý krok textu s jemným odskokem; ohraničený spodní blok tlačítek.</td>
        </tr>
        <tr>
          <td>Pracnost implementace</td>
          <td class="rec-col">Nízká (standardní SwiftUI tvary, stíny, podpora matchedTransitionSource).</td>
          <td>Nízká až střední (vícevrstvý podsvícený obrys padu a světelný proužek).</td>
          <td>Nízká (přesné geometrické rámečky a SVG kontrolka).</td>
        </tr>
        <tr>
          <td>Riziko</td>
          <td class="rec-col">Minimální (plně v souladu s iOS 17/18 a pravidly Ticketu 27 a 92).</td>
          <td>Minimální (žádné výkonově náročné shadery, pouze čisté vrstvy a barvy).</td>
          <td>Nulové (nejkonzervativnější varianta nejbližší původnímu ticketu 94).</td>
        </tr>
      </tbody>
    </table>
  </section>

  <!-- TOKENY POHYBU -->
  <section class="table-section">
    <h2>Katalog animací a mapování na tokeny Theme.Motion</h2>
    <table class="comp-table">
      <thead>
        <tr>
          <th>Akce / Místo</th>
          <th>Token v Theme.swift</th>
          <th>Doba & křivka</th>
          <th>Reduce Motion chování</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Stisk padu (úder)</td>
          <td><span class="token-code">Theme.Motion.padPress</span></td>
          <td>0.08 s ease-out (stlačení) + 0.18 s spring (návrat)</td>
          <td>Bez posunu a scale, pouze ztmavení výplně (0.10 s)</td>
        </tr>
        <tr>
          <td>Záblesk úderu</td>
          <td><span class="token-code">Theme.Motion.padFlash</span></td>
          <td>0.05 s ease-out fade</td>
          <td>Vypnuto (žádný záblesk)</td>
        </tr>
        <tr>
          <td>Zoom pad → obrazovka (iOS 18)</td>
          <td><span class="token-code">Theme.Motion.padZoom</span></td>
          <td>0.28 s spring (response 0.28, damping 0.82)</td>
          <td>Čistý opacity cross-fade 0.15 s</td>
        </tr>
        <tr>
          <td>Návrat obrazovka → pad</td>
          <td><span class="token-code">Theme.Motion.padDismiss</span></td>
          <td>0.22 s ease-out</td>
          <td>Čistý opacity cross-fade 0.15 s</td>
        </tr>
        <tr>
          <td>Krok relace Dnes (předěl)</td>
          <td><span class="token-code">Theme.Motion.cardStep</span></td>
          <td>0.24 s ease-out (+20 pt posun s prolnutím)</td>
          <td>Pouze prolnutí textu bez pohybu (0.15 s)</td>
        </tr>
        <tr>
          <td>Dýchání LED u Tréninku</td>
          <td><span class="token-code">Theme.Motion.ledBreath</span></td>
          <td>2.40 s sine ease-in-out (nekonečná smyčka)</td>
          <td>Statické svícení bez pulzování</td>
        </tr>
        <tr>
          <td>Odstup náběhu mřížky (Boot)</td>
          <td><span class="token-code">Theme.Motion.bootStagger</span></td>
          <td>40 ms mezi sousedními pady</td>
          <td>Mřížka se zobrazí celá najednou prolnutím (0.20 s)</td>
        </tr>
      </tbody>
    </table>
  </section>
</main>

<script>
// Toggle for index page
(function() {{
  const themeToggle = document.getElementById("theme-toggle");
  const themeLabel = document.getElementById("theme-label");
  let isDark = false;
  themeToggle.addEventListener("click", () => {{
    isDark = !isDark;
    if (isDark) {{
      document.body.setAttribute("data-theme", "dark");
      themeLabel.textContent = "Tmavý";
      themeToggle.classList.add("active");
    }} else {{
      document.body.removeAttribute("data-theme");
      themeLabel.textContent = "Světlý";
      themeToggle.classList.remove("active");
    }}
  }});
}})();
</script>

</body>
</html>
"""
    return html

# -------------------------------------------------------------
# BUILD README.md (Czech, plain language)
# -------------------------------------------------------------
def build_readme_markdown():
    return """# Návrhy domovských padů a animací aplikace (Ticket 111)

Status: návrhy připraveny k rozhodnutí Jakuba.
Zdroj: Jakub (2026-11-06): *„Pady na Home vypadají obyčejně; šlo by je udělat modernější a hezčí? Taky mi celkově chybí moderní animace a přechody.“*
Návaznost: implementační ticket se sepíše po Jakubově výběru. V tomto úkolu se **nemění žádný kód aplikace, assety ani lokalizační řetězce**.

---

## 1. Rychlé odkazy na náhledy

Všechny náhledy jsou plně soběstačné a spustitelné přímo v prohlížeči na Macu (bez nutnosti webového serveru či internetového připojení; font IBM Plex Sans i vektorová grafika jsou přímo vloženy):

| Soubor | Návrh | Token zaoblení | Klíčový charakter |
|---|---|---|---|
| [**index.html**](index.html) | **Srovnání & Přehled** | – | Srovnávací přehled všech parametrů, živý tester padů vedle sebe a tabulky tokenů. |
| [**proposal-a.html**](proposal-a.html) | **Návrh A (Doporučeno)** | `Theme.Radius.pad = 8 pt` | **Akai MPC Tactile Rubber** — Taktilní silikonový pad s fazetkou, přirozeným stlačením a pružným odskokem. |
| [**proposal-b.html**](proposal-b.html) | **Návrh B** | `Theme.Radius.pad = 12 pt` | **Maschine Milk-Silicone** — Difuzní mléčný silikon s obvodovým světlovodem a horním proužkem. |
| [**proposal-c.html**](proposal-c.html) | **Návrh C** | `Theme.Radius.pad = 5 pt` | **SP-1200 Metal Collar** — Industriální pad zasazený do kovového šasi s klenutou kontrolkou DUE. |

Každý náhled obsahuje interaktivní lištu s přepínači:
- **Vzhled**: Světlý (krémová `#F4EFE6`) vs. Tmavý (teplá černá `#1F1D1A`).
- **Orientace**: Na šířku (1194×834) vs. Na výšku (834×1194).
- **Pohyb (Reduce Motion)**: Plný pohyb vs. Přísný režim bez posunů a deformací (max 0.2 s prolnutí).
- **Přechod (Zoom)**: Simulace nativního iOS 18 zoomu z rámečku padu vs. náhradní iOS 17 přechod.
- **Replay náběhu**: Znovuspuštění bootovací animace mřížky 3×3.
- **Simulace MIDI úderu**: Tlačítka 1–8 (či klávesy 1–8 na klávesnici) simulující reakci padu na úder z fyzického kontroleru.
- **Test relace Dnes**: Klepnutím na oranžový pad POKRAČOVAT/DNES se otevře obrazovka relace (ticket 109/110) s plynulým krokem mezi výsledkem a dalším cvičením bez poskakování tlačítek.

---

## 2. Podrobný popis jednotlivých návrhů

### Návrh A: Akai MPC Tactile Rubber (*DOPORUČENO*)
- **Inspirace a filozofie**: Klasické hutné silikonové pady bicích automatů Akai MPC (od MPC 2000XL po MPC One/Live). Pady mají přirozenou fyzickou váhu a hloubku, aniž by působily kýčovitě či plasticky.
- **Zaoblení**: `Theme.Radius.pad = 8 pt` (~8 px). Zlatá střední cesta – pad je na první pohled odlišen od ostrých tlačítek a panelů (ticket 94), ale zůstává přesně vymezeným bicím padem.
- **Materiál a hloubka**: Dvoutónová fazetka vytvořená jemnou horní světelnou hranou a spodním 2px stínem lůžka. Vytváří dojem autentického 4mm vyvýšeného silikonového bloku.
- **Stav svícení (Trénink)**: Při čekajících opakováních svítí obvodový oranžový lem padu s jemnou září a v pravém horním rohu klidně dýchá kruhová LED kontrolka (perioda 2.4 s).
- **Odezva na úder**: Mechanické stlačení (scale 0.965, y: 1.5 px) s bleskovým plošným zábleskem (60 ms) a rychlým pružným odskokem zpět (0.18 s spring).
- **Náběh mřížky**: Diagonální vlna z levého horního rohu (pad 1) do pravého dolního (pad 8) s odstupem 40 ms mezi sousedy.

---

### Návrh B: Maschine Milk-Silicone Backlit
- **Inspirace a filozofie**: Moderní elektronické nástroje jako Native Instruments Maschine MK3 nebo Ableton Push. Hladký, difuzní mléčný silikon s jemným sametovým povrchem a obvodovým světlovodem.
- **Zaoblení**: `Theme.Radius.pad = 12 pt` (~12 px). Měkčí, moderní křivka příjemná pro bříška prstů.
- **Materiál a hloubka**: Lícní plocha padu je rovná a flush s panelem, ohraničená 2px zapuštěným difuzním kanálkem.
- **Stav svícení (Trénink)**: Celý obvodový kanálek padu se rozsvítí teplým oranžovým světlem a horní hrana padu nese integrovaný 2px světelný proužek s klidným pulzem (3.2 s).
- **Odezva na úder**: Čistě luminescenční záblesk plochy (40 ms) bez vertikálního propadu, doprovázený nepatrným stlačením (scale 0.975) a plynulým radiálním rozpadem světla.
- **Náběh mřížky**: Radiální záblesk šířící se od středového loga – nejprve se v 80 ms rozsvítí 4 křížové pady (2, 4, 5, 7) a následně ve 190 ms 4 rohové pady (1, 3, 6, 8).

---

### Návrh C: SP-1200 / TR-808 Industrial Metal Collar
- **Inspirace a filozofie**: Industriální nástroje zlaté éry hip-hopu a elektroniky (E-mu SP-1200, Roland TR-808, studiové mixážní pulty). Pevný hardware s přesným strojním lůžkem.
- **Zaoblení**: `Theme.Radius.pad = 5 pt` (~5 px). Velmi jemné, architektonické zaoblení respektující původní pravoúhlou geometrii aplikace.
- **Materiál a hloubka**: Dvojitý rámeček – vnější 2px kovový límec šasi a vnitřní stín zapuštění. Pad vizuálně sedí ve frézovaném otvoru čelního panelu.
- **Stav svícení (Trénink)**: Vyražená kruhová LED kontrolka s mosazným lemem a klenutou oranžovou čočkou, doplněná mikronápisem `● DUE`.
- **Odezva na úder**: Ostrý mechanický ráz (y: 2 px, 0.07 s) se ztmavnutím stínu lůžka a okamžitým cvakavým odskokem.
- **Náběh mřížky**: Sekvenční hardware self-test po řádcích (řádek 1, řádek 2, řádek 3 po 70 ms), stejně jako při zapnutí studiového rackového modulu.

---

## 3. Doporučení jednoho návrhu

### **Jednoznačně doporučujeme Návrh A (Akai MPC Tactile Rubber).**

**Důvody:**
1. **Pravá podstata prstového bubnování**: Smack-a-Pad je trenažér pro finger drumming. Pady v Návrhu A mají přesně tu správnou hmatovou hloubku a odezvu, jakou hráč očekává od skutečného bicího kontroleru (Akai MPD / MPC).
2. **Přirozený kompromis zaoblení (8 pt)**: Zaoblení 8 pt zřetelně odděluje herní pady od běžných systémových tlačítek a panelů (které dle ticketu 94 zůstávají pravoúhlé), ale nepůsobí přehnaně jako měkká mobilní pilulka (což by hrozilo u 12 pt a více).
3. **Mimořádně uspokojivá odezva**: Krátké stlačení s bleskovým zábleskem (60 ms) a pružným návratem (0.18 s) dává perfektní vizuální potvrzení jak při dotyku prstem na iPadu, tak při úderu na externím MIDI kontroleru.
4. **Klidný a účelný pohyb**: Diagonální náběh i iOS 18 zoom z rámečku padu probíhají v bezpečném rozmezí 0.15–0.28 s, nezdržují uživatele a plně vyhovují všem zásadám `DESIGN-BRIEF.md`.

---

## 4. Mapování animací na Theme tokeny a Reduce Motion

Všechny animace jsou přesně navrženy tak, aby se v budoucím implementačním ticketu začlenily do `Theme.swift`:

| Animace | Navržený token | Doba a křivka | Reduce Motion varianta (Ticket 27) |
|---|---|---|---|
| **Stisk padu** | `Theme.Motion.padPress` | `0.08 s ease-out` + `0.18 s spring` | Žádný scale ani posun, pouze ztmavení výplně (0.10 s) |
| **Záblesk padu** | `Theme.Motion.padFlash` | `0.05 s ease-out` | Vypnuto |
| **Zoom pad → obrazovka** | `Theme.Motion.padZoom` | `0.28 s spring (response 0.28, damping 0.82)` | Čisté prolnutí opacity (0.15 s) |
| **Návrat obrazovka → pad** | `Theme.Motion.padDismiss` | `0.22 s ease-out` | Čisté prolnutí opacity (0.15 s) |
| **Krokování Dnes (109/110)** | `Theme.Motion.cardStep` | `0.24 s ease-out (+20 pt posun)` | Čisté prolnutí opacity bez posunu (0.15 s) |
| **Dýchání LED Tréninku** | `Theme.Motion.ledBreath` | `2.40 s sine ease-in-out` | Statické svícení bez animace |
| **Náběh mřížky (Boot)** | `Theme.Motion.bootStagger` | `40 ms mezi sousedními pady` | Zobrazení mřížky naráz prolnutím (0.20 s) |
"""

print("Index and README generation functions defined.")

# -------------------------------------------------------------
# MAIN WRITER
# -------------------------------------------------------------
def main():
    DEST.mkdir(parents=True, exist_ok=True)
    
    # 1. Proposal A
    prop_a_html = build_proposal_page("a", "Návrh A (Akai MPC Tactile Rubber)", "8 pt", "Taktilní MPC silikonový pad s fazetkou")
    (DEST / "proposal-a.html").write_text(prop_a_html, encoding="utf-8")
    print(f"Written proposal-a.html ({len(prop_a_html)} bytes)")

    # 2. Proposal B
    prop_b_html = build_proposal_page("b", "Návrh B (Maschine Milk-Silicone Backlit)", "12 pt", "Difuzní mléčný silikon s obvodovým světlovodem")
    (DEST / "proposal-b.html").write_text(prop_b_html, encoding="utf-8")
    print(f"Written proposal-b.html ({len(prop_b_html)} bytes)")

    # 3. Proposal C
    prop_c_html = build_proposal_page("c", "Návrh C (SP-1200 Metal Collar)", "5 pt", "Industriální pad v kovovém šasi s klenutou LED")
    (DEST / "proposal-c.html").write_text(prop_c_html, encoding="utf-8")
    print(f"Written proposal-c.html ({len(prop_c_html)} bytes)")

    # 4. Index
    index_html = build_index_page()
    (DEST / "index.html").write_text(index_html, encoding="utf-8")
    print(f"Written index.html ({len(index_html)} bytes)")

    # 5. README.md
    readme_md = build_readme_markdown()
    (DEST / "README.md").write_text(readme_md, encoding="utf-8")
    print(f"Written README.md ({len(readme_md)} bytes)")

    print("All deliverables for Ticket 111 successfully created.")

if __name__ == "__main__":
    main()

