#!/usr/bin/env python3
"""
Smack-a-Pad Button System Proposal Generator (Ticket 131)
Generates:
1. index.html - Interactive preview application (offline, side-by-side comparison, live states, sound FX)
2. rules-variant-a.html - Dedicated rules sheet for Variant A ("Haptický hardware")
3. rules-variant-b.html - Dedicated rules sheet for Variant B ("Akustický minimalismus")
4. README.md - Complete proposal with inventory table, screenshot references, and rules
"""

import os
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

CSS_TOKENS = """
:root {
  /* Ticket 92 & 126 Light Theme */
  --bg-app: #F4EFE6;
  --chassis-top: #F5EFE5;
  --chassis-bottom: #E8E0D2;
  --chassis-angle: 175deg;
  --chassis-rib-light: rgba(244, 239, 230, 0.55);
  --chassis-rib-shadow: rgba(31, 29, 26, 0.08);
  
  --plate-top: #ECE5DC;
  --plate-bottom: #DDD5C8;
  --plate-angle: 165deg;
  --plate-bevel-highlight: rgba(244, 239, 230, 0.85);
  --plate-bevel-shade: rgba(31, 29, 26, 0.20);
  --plate-shadow: 0 6px 12px rgba(31, 29, 26, 0.09);
  --plate-contact: 0 1px 1.5px rgba(31, 29, 26, 0.06);
  
  --surface: #EBE5DA;
  --ink: #1F1D1A;
  --secondary: #5E5950;
  --hairline: rgba(31, 29, 26, 0.15);
  --slot: #1A1816;
  --inset-display-fill: #151412;
  --inset-display-ink: #F4EFE6;
  
  --orange: #FF6B00;
  --orange-glow: rgba(255, 107, 0, 0.35);
  --orange-subtle: rgba(255, 107, 0, 0.14);
  
  --destructive: #C0392B;
  --destructive-ink: #F4EFE6;
  --destructive-outline: rgba(192, 57, 43, 0.4);
  
  --star-gold: #FF6B00;
  --star-empty: #D6D0C4;
}

[data-theme="dark"] {
  /* Ticket 92 & 126 Dark Theme */
  --bg-app: #1F1D1A;
  --chassis-top: #24221E;
  --chassis-bottom: #171513;
  --chassis-angle: 175deg;
  --chassis-rib-light: rgba(244, 239, 230, 0.06);
  --chassis-rib-shadow: rgba(0, 0, 0, 0.45);
  
  --plate-top: #272521;
  --plate-bottom: #1E1C19;
  --plate-angle: 165deg;
  --plate-bevel-highlight: rgba(244, 239, 230, 0.24);
  --plate-bevel-shade: rgba(31, 29, 26, 0.70);
  --plate-shadow: 0 6px 12px rgba(0, 0, 0, 0.55);
  --plate-contact: 0 1px 1.5px rgba(0, 0, 0, 0.35);
  
  --surface: #2A2824;
  --ink: #F4EFE6;
  --secondary: #B3ADA2;
  --hairline: rgba(244, 239, 230, 0.15);
  --slot: #0C0B0A;
  --inset-display-fill: #151412;
  --inset-display-ink: #F4EFE6;
  
  --orange: #FF6B00;
  --orange-glow: rgba(255, 107, 0, 0.45);
  --orange-subtle: rgba(255, 107, 0, 0.20);
  
  --destructive: #E74C3C;
  --destructive-ink: #F4EFE6;
  --destructive-outline: rgba(231, 76, 60, 0.4);
  
  --star-gold: #FF6B00;
  --star-empty: #3E3B36;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  -webkit-font-smoothing: antialiased;
}

body {
  font-family: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif;
  background-color: var(--bg-app);
  color: var(--ink);
  line-height: 1.45;
  transition: background-color 0.2s ease, color 0.2s ease;
  overflow-x: hidden;
}

/* Background textures */
.bg-plate {
  background: linear-gradient(var(--plate-angle), var(--plate-top), var(--plate-bottom));
  border: 1px solid var(--hairline);
  box-shadow: var(--plate-shadow), var(--plate-contact);
}

.bg-chassis {
  background: linear-gradient(var(--chassis-angle), var(--chassis-top), var(--chassis-bottom));
  position: relative;
}

.bg-chassis::before {
  content: "";
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(
    0deg,
    var(--chassis-rib-light) 0px,
    var(--chassis-rib-light) 2px,
    var(--chassis-rib-shadow) 2px,
    var(--chassis-rib-shadow) 4px
  );
  opacity: 0.05;
  pointer-events: none;
}

.bg-dark-glass {
  background: var(--inset-display-fill);
  color: var(--inset-display-ink);
  box-shadow: inset 0 2px 6px rgba(0, 0, 0, 0.85);
  border: 1px solid rgba(255, 255, 255, 0.06);
}

/* Base button resets */
button {
  font-family: inherit;
  border: none;
  background: none;
  cursor: pointer;
  outline: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  text-decoration: none;
  user-select: none;
  -webkit-tap-highlight-color: transparent;
  transition: transform 0.08s ease, box-shadow 0.08s ease, background 0.08s ease;
  min-height: 48px;
  min-width: 48px;
}

/* ==========================================================================
   VARIANTA A: Haptický hardware (Akai MPC / Tactile Elastomer)
   - Radius: 8pt
   - Precision Bevels (1.5pt highlight, 2.0pt shadow)
   - Recessed Well depth
   - Motion: Scale 0.965, Y +1.5px, Pad Flash 120ms
   ========================================================================== */
.var-a .btn-base {
  border-radius: 8px;
  position: relative;
  font-size: 16px;
  font-weight: 600;
  padding: 0 16px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.12);
  border: 1px solid var(--hairline);
}

.var-a .btn-base::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: 7px;
  pointer-events: none;
  border-top: 1.5px solid rgba(255,255,255,0.45);
  border-bottom: 2.0px solid rgba(0,0,0,0.25);
}

/* A: Primary Action (Hero Pad) */
.var-a .btn-primary {
  background: var(--orange);
  color: #1F1D1A;
  box-shadow: 0 2px 6px rgba(0,0,0,0.2), 0 0 16px var(--orange-glow);
  border: 1px solid rgba(0,0,0,0.15);
}
.var-a .btn-primary::before {
  border-top: 1.5px solid rgba(255,255,255,0.55);
  border-bottom: 2.5px solid rgba(0,0,0,0.35);
}

/* A: Secondary Action */
.var-a .btn-secondary {
  background: var(--surface);
  color: var(--ink);
}

/* A: Toolbar Button */
.var-a .btn-toolbar {
  min-height: 44px;
  padding: 0 14px;
  font-size: 15px;
  background: var(--surface);
  color: var(--ink);
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}

/* A: Icon Button */
.var-a .btn-icon {
  width: 48px;
  height: 48px;
  padding: 0;
  background: var(--surface);
  color: var(--ink);
  border-radius: 8px;
}
.var-a .btn-icon svg {
  width: 20px;
  height: 20px;
}

/* A: Segmented Hardware Keys */
.var-a .segmented-group {
  display: inline-flex;
  background: var(--slot);
  padding: 3px;
  border-radius: 10px;
  border: 1px solid var(--hairline);
  box-shadow: inset 0 2px 5px rgba(0,0,0,0.3);
}

.var-a .segmented-key {
  border-radius: 7px;
  background: var(--surface);
  color: var(--ink);
  padding: 0 18px;
  min-height: 44px;
  font-size: 15px;
  font-weight: 600;
  position: relative;
  border: 1px solid transparent;
  margin: 0 1px;
}

.var-a .segmented-key.active {
  background: var(--surface);
  box-shadow: 0 2px 4px rgba(0,0,0,0.15);
  border-color: var(--hairline);
}

.var-a .segmented-key.active::after {
  content: "";
  position: absolute;
  bottom: 0;
  left: 6px;
  right: 6px;
  height: 2.5px;
  background: var(--orange);
  border-radius: 2px 2px 0 0;
  box-shadow: 0 0 8px var(--orange);
  animation: ledPulse 3s infinite ease-in-out;
}

/* A: Filter Chips */
.var-a .filter-chip {
  min-height: 38px;
  padding: 0 14px;
  font-size: 14px;
  font-weight: 600;
  border-radius: 8px;
  background: var(--surface);
  color: var(--secondary);
  border: 1px solid var(--hairline);
  box-shadow: 0 1px 2px rgba(0,0,0,0.06);
}

.var-a .filter-chip.active {
  background: var(--surface);
  color: var(--orange);
  border: 1.5px solid var(--orange);
  box-shadow: 0 0 8px var(--orange-subtle);
}

/* A: Destructive */
.var-a .btn-destructive {
  background: var(--destructive);
  color: #F4EFE6;
  border: 1px solid rgba(0,0,0,0.25);
  box-shadow: 0 2px 5px rgba(192,57,43,0.3);
}
.var-a .btn-destructive::before {
  border-top: 1.5px solid rgba(255,255,255,0.4);
  border-bottom: 2.0px solid rgba(0,0,0,0.4);
}

/* A: Disabled */
.var-a .btn-disabled {
  opacity: 0.45;
  cursor: not-allowed;
  box-shadow: none !important;
  transform: none !important;
  filter: grayscale(0.5);
}

/* A: Interactive Press */
.var-a button:not(.btn-disabled):active,
.var-a .is-pressed {
  transform: scale(0.965) translateY(1.5px) !important;
  box-shadow: 0 1px 2px rgba(0,0,0,0.2) !important;
}

.var-a button:not(.btn-disabled):active::after,
.var-a .is-pressed::after {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  background: rgba(255,255,255,0.25);
  pointer-events: none;
  animation: flashFade 0.12s forwards ease-out;
}

/* ==========================================================================
   VARIANTA B: Akustický minimalismus (Studio Console / Braun Precision)
   - Radius: 6pt
   - Crisp 1px hairline boundary, no heavy double-bevels
   - Flat satin plates with mechanical contact edge
   - Motion: Scale 0.985, Y +1.0px, instant tone step (no flash)
   ========================================================================== */
.var-b .btn-base {
  border-radius: 6px;
  position: relative;
  font-size: 15px;
  font-weight: 600;
  padding: 0 16px;
  border: 1px solid var(--hairline);
  box-shadow: 0 1.5px 0 rgba(0,0,0,0.22);
}

/* B: Primary Action (Hero Pad) */
.var-b .btn-primary {
  background: var(--orange);
  color: #1F1D1A;
  border: 1px solid rgba(0,0,0,0.2);
  box-shadow: 0 2px 0 rgba(0,0,0,0.25), 0 2px 8px var(--orange-glow);
}

/* B: Secondary Action */
.var-b .btn-secondary {
  background: var(--surface);
  color: var(--ink);
  box-shadow: 0 1.5px 0 rgba(0,0,0,0.18);
}

/* B: Toolbar Button */
.var-b .btn-toolbar {
  min-height: 44px;
  padding: 0 14px;
  font-size: 15px;
  background: transparent;
  color: var(--ink);
  border: 1px solid var(--hairline);
  border-radius: 6px;
  box-shadow: none;
}
.var-b .btn-toolbar:hover {
  background: var(--surface);
}

/* B: Icon Button */
.var-b .btn-icon {
  width: 44px;
  height: 44px;
  padding: 0;
  background: var(--surface);
  color: var(--ink);
  border-radius: 6px;
  border: 1px solid var(--hairline);
  box-shadow: 0 1px 0 rgba(0,0,0,0.15);
}
.var-b .btn-icon svg {
  width: 18px;
  height: 18px;
}

/* B: Segmented Hardware Keys */
.var-b .segmented-group {
  display: inline-flex;
  background: var(--surface);
  border: 1px solid var(--hairline);
  border-radius: 8px;
  padding: 2px;
  box-shadow: 0 1.5px 0 rgba(0,0,0,0.15);
}

.var-b .segmented-key {
  border-radius: 6px;
  background: transparent;
  color: var(--secondary);
  padding: 0 16px;
  min-height: 42px;
  font-size: 14px;
  font-weight: 600;
  position: relative;
  border: 1px solid transparent;
}

.var-b .segmented-key.active {
  background: var(--bg-app);
  color: var(--ink);
  border-color: var(--hairline);
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

.var-b .segmented-key.active::after {
  content: "";
  position: absolute;
  bottom: 2px;
  left: 10px;
  right: 10px;
  height: 2.0px;
  background: var(--orange);
  border-radius: 1px;
}

/* B: Filter Chips */
.var-b .filter-chip {
  min-height: 36px;
  padding: 0 12px;
  font-size: 14px;
  font-weight: 600;
  border-radius: 6px;
  background: transparent;
  color: var(--secondary);
  border: 1px solid var(--hairline);
}

.var-b .filter-chip.active {
  background: var(--ink);
  color: var(--bg-app);
  border-color: var(--ink);
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.var-b .filter-chip.active::before {
  content: "";
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--orange);
}

/* B: Destructive */
.var-b .btn-destructive {
  background: var(--surface);
  color: var(--destructive);
  border: 1px solid var(--destructive-outline);
  box-shadow: 0 1.5px 0 rgba(0,0,0,0.15);
}

/* B: Disabled */
.var-b .btn-disabled {
  opacity: 0.35;
  cursor: not-allowed;
  box-shadow: none !important;
  transform: none !important;
  border-color: var(--hairline) !important;
  background: var(--surface) !important;
  color: var(--secondary) !important;
}

/* B: Interactive Press */
.var-b button:not(.btn-disabled):active,
.var-b .is-pressed {
  transform: scale(0.985) translateY(1.0px) !important;
  box-shadow: 0 0.5px 0 rgba(0,0,0,0.2) !important;
  filter: brightness(0.92);
}

/* Row Button / Lesson Row (Shared Structure) */
.lesson-card-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 20px;
  border-radius: 12px;
  border: 1px solid var(--hairline);
  background: var(--plate-top);
  box-shadow: 0 2px 6px rgba(0,0,0,0.06);
  min-height: 68px;
  transition: transform 0.1s ease, box-shadow 0.1s ease;
  cursor: pointer;
  text-decoration: none;
}
.lesson-card-row:hover {
  border-color: var(--orange);
}
.lesson-card-row:active {
  transform: scale(0.995);
}

/* Animations */
@keyframes ledPulse {
  0%, 100% { opacity: 0.85; filter: drop-shadow(0 0 4px var(--orange)); }
  50% { opacity: 1.0; filter: drop-shadow(0 0 9px var(--orange)); }
}

@keyframes flashFade {
  0% { opacity: 0.3; }
  100% { opacity: 0; }
}

/* Reduce Motion */
[data-reduce-motion="true"] * {
  animation: none !important;
  transition: opacity 0.05s ease !important;
  transform: none !important;
}
"""

def generate_index_html():
    html_content = f"""<!DOCTYPE html>
<html lang="cs" data-theme="light" data-variant="a" data-reduce-motion="false">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Smack-a-Pad — Systém tlačítek (Ticket 131)</title>
  <style>
    {CSS_TOKENS}
    
    /* Layout styling for the proposal presentation */
    .top-nav {{
      position: sticky;
      top: 0;
      z-index: 100;
      background: var(--bg-app);
      border-bottom: 1px solid var(--hairline);
      padding: 12px 24px;
      display: flex;
      flex-wrap: wrap;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      backdrop-filter: blur(12px);
    }}
    
    .nav-title h1 {{
      font-size: 20px;
      font-weight: 700;
      letter-spacing: -0.01em;
    }}
    .nav-title p {{
      font-size: 13px;
      color: var(--secondary);
    }}
    
    .nav-controls {{
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }}
    
    .ctrl-pill {{
      display: inline-flex;
      background: var(--surface);
      border: 1px solid var(--hairline);
      border-radius: 8px;
      padding: 3px;
    }}
    .ctrl-pill button {{
      min-height: 32px;
      padding: 0 12px;
      font-size: 13px;
      font-weight: 600;
      border-radius: 6px;
      color: var(--secondary);
    }}
    .ctrl-pill button.active {{
      background: var(--bg-app);
      color: var(--ink);
      box-shadow: 0 1px 3px rgba(0,0,0,0.1);
    }}
    
    .tab-nav {{
      background: var(--surface);
      border-bottom: 1px solid var(--hairline);
      padding: 8px 24px;
      display: flex;
      gap: 8px;
      overflow-x: auto;
    }}
    .tab-btn {{
      min-height: 36px;
      padding: 0 16px;
      font-size: 14px;
      font-weight: 600;
      border-radius: 8px;
      color: var(--secondary);
      border: 1px solid transparent;
    }}
    .tab-btn.active {{
      background: var(--bg-app);
      color: var(--orange);
      border-color: var(--hairline);
    }}
    
    .main-container {{
      max-width: 1400px;
      margin: 0 auto;
      padding: 32px 24px 80px;
    }}
    
    .section-title {{
      font-size: 24px;
      font-weight: 700;
      margin-bottom: 8px;
    }}
    .section-desc {{
      font-size: 15px;
      color: var(--secondary);
      margin-bottom: 24px;
      max-width: 800px;
    }}
    
    /* Grid for button matrix */
    .button-matrix-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
      gap: 24px;
      margin-bottom: 48px;
    }}
    
    .matrix-card {{
      border-radius: 16px;
      padding: 24px;
      border: 1px solid var(--hairline);
      position: relative;
    }}
    
    .card-header {{
      display: flex;
      justify-content: space-between;
      align-items: flex-start;
      margin-bottom: 20px;
      border-bottom: 1px solid var(--hairline);
      padding-bottom: 12px;
    }}
    .card-header h3 {{
      font-size: 17px;
      font-weight: 700;
    }}
    .card-badge {{
      font-size: 11px;
      text-transform: uppercase;
      font-weight: 700;
      letter-spacing: 0.05em;
      padding: 3px 8px;
      border-radius: 4px;
      background: var(--surface);
      color: var(--secondary);
      border: 1px solid var(--hairline);
    }}
    
    .states-row {{
      display: flex;
      flex-direction: column;
      gap: 16px;
    }}
    
    .state-item {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
    }}
    .state-label {{
      font-size: 13px;
      font-weight: 500;
      color: var(--secondary);
      width: 110px;
      flex-shrink: 0;
    }}
    
    /* Comparison View */
    .comparison-container {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 32px;
      margin-top: 24px;
    }}
    @media (max-width: 900px) {{
      .comparison-container {{
        grid-template-columns: 1fr;
      }}
    }}
    
    .variant-banner {{
      padding: 16px 20px;
      border-radius: 12px;
      margin-bottom: 20px;
      border: 1px solid var(--hairline);
    }}
    .variant-banner h2 {{
      font-size: 19px;
      font-weight: 700;
      margin-bottom: 4px;
    }}
    .variant-banner p {{
      font-size: 14px;
      color: var(--secondary);
    }}
    
    /* Simulated screen panels */
    .screen-panel {{
      border-radius: 16px;
      padding: 24px;
      border: 1px solid var(--hairline);
      margin-bottom: 24px;
    }}
    
    .inventory-table {{
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
      font-size: 14px;
    }}
    .inventory-table th, .inventory-table td {{
      padding: 14px 16px;
      text-align: left;
      border-bottom: 1px solid var(--hairline);
      vertical-align: top;
    }}
    .inventory-table th {{
      background: var(--surface);
      font-weight: 700;
    }}
    
    .screenshot-thumb {{
      width: 160px;
      border-radius: 6px;
      border: 1px solid var(--hairline);
      cursor: pointer;
      transition: transform 0.15s ease;
    }}
    .screenshot-thumb:hover {{
      transform: scale(1.08);
      box-shadow: 0 4px 12px rgba(0,0,0,0.25);
    }}
    
    .rules-box {{
      background: var(--surface);
      border-radius: 12px;
      padding: 20px;
      border-left: 4px solid var(--orange);
      margin-bottom: 24px;
      line-height: 1.6;
    }}
  </style>
</head>
<body>

  <!-- Top Sticky Navigation Bar -->
  <header class="top-nav">
    <div class="nav-title">
      <h1>Smack-a-Pad — Systém tlačítek (Ticket 131)</h1>
      <p>Sjednocený designový návrh tlačítek a pravidel pro celou aplikaci</p>
    </div>
    
    <div class="nav-controls">
      <!-- Theme Switcher -->
      <div class="ctrl-pill">
        <button id="btnThemeLight" class="active" onclick="setTheme('light')">☀️ Světlý (L)</button>
        <button id="btnThemeDark" onclick="setTheme('dark')">🌙 Tmavý</button>
      </div>
      
      <!-- Variant Switcher -->
      <div class="ctrl-pill">
        <button id="btnVarA" class="active" onclick="setVariant('a')">Var A: Haptický hardware (V)</button>
        <button id="btnVarB" onclick="setVariant('b')">Var B: Akustický minimalismus</button>
        <button id="btnVarCompare" onclick="setVariant('compare')">⚖️ Srovnání A / B</button>
      </div>
      
      <!-- Sound FX Toggle -->
      <div class="ctrl-pill">
        <button id="btnSound" class="active" onclick="toggleSound()">🔊 Zvuk kliku</button>
        <button id="btnMotion" onclick="toggleMotion()">⚡ Motion: ON</button>
      </div>
    </div>
  </header>

  <!-- Secondary Tab Bar -->
  <nav class="tab-nav">
    <button class="tab-btn active" onclick="showTab('matrix')">1. Matice všech 9 typů tlačítek</button>
    <button class="tab-btn" onclick="showTab('simulations')">2. Kontextové simulace obrazovek</button>
    <button class="tab-btn" onclick="showTab('comparison')">3. Srovnání A vs B</button>
    <button class="tab-btn" onclick="showTab('rules')">4. Pravidla &amp; Specifikace</button>
    <button class="tab-btn" onclick="showTab('inventory')">5. Inventář původního stavu (Before)</button>
  </nav>

  <main class="main-container">

    <!-- ====================================================================
         TAB 1: Matice všech 9 typů tlačítek
         ==================================================================== -->
    <div id="tab-matrix">
      <h2 class="section-title">Matice všech 9 typů tlačítek v aplikaci</h2>
      <p class="section-desc">
        Každé tlačítko je plně interaktivní — vyzkoušejte kliknutí, podržení myši, haptický zvuk a odezvu. Všechny stavy (klid, stisknuto, vybráno, vypnuto) splňují přísné minimální dotykové rozměry a kontrast.
      </p>

      <div id="matrixWrapper" class="var-a">
        <div class="button-matrix-grid">

          <!-- 1. Toolbar Button -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>1. Toolbar Button (Lišta nástrojů)</h3>
                <p style="font-size:13px; color:var(--secondary)">Navigace Domů, Knihovna, Zpět, Hotovo</p>
              </div>
              <span class="card-badge">Min 44 pt</span>
            </div>
            <div class="states-row">
              <div class="state-item">
                <span class="state-label">Klid (Rest)</span>
                <button class="btn-base btn-toolbar">← Domů</button>
              </div>
              <div class="state-item">
                <span class="state-label">Stisknuto (Pressed)</span>
                <button class="btn-base btn-toolbar is-pressed">← Domů</button>
              </div>
              <div class="state-item">
                <span class="state-label">Akce vpravo</span>
                <button class="btn-base btn-toolbar">Hotovo</button>
              </div>
            </div>
          </div>

          <!-- 2. Primary Action (Hero Pad) -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>2. Primární akce (Hero Pad)</h3>
                <p style="font-size:13px; color:var(--secondary)">Oranžový funkční pad ("Začít", "Pokračovat")</p>
              </div>
              <span class="card-badge">Hero Pad</span>
            </div>
            <div class="states-row">
              <div class="state-item">
                <span class="state-label">Klid (Rest)</span>
                <button class="btn-base btn-primary">Začít trénovat</button>
              </div>
              <div class="state-item">
                <span class="state-label">Stisknuto (Pressed)</span>
                <button class="btn-base btn-primary is-pressed">Pokračovat</button>
              </div>
              <div class="state-item">
                <span class="state-label">Vypnuto (Disabled)</span>
                <button class="btn-base btn-primary btn-disabled" disabled>Uložit</button>
              </div>
            </div>
          </div>

          <!-- 3. Secondary Action -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>3. Sekundární akce (Saténový pad)</h3>
                <p style="font-size:13px; color:var(--secondary)">"Znovu", "Od začátku", "Dnes ne", "Zrušit"</p>
              </div>
              <span class="card-badge">Min 48 pt</span>
            </div>
            <div class="states-row">
              <div class="state-item">
                <span class="state-label">Klid (Rest)</span>
                <button class="btn-base btn-secondary">Znovu</button>
              </div>
              <div class="state-item">
                <span class="state-label">Stisknuto (Pressed)</span>
                <button class="btn-base btn-secondary is-pressed">Od začátku</button>
              </div>
              <div class="state-item">
                <span class="state-label">Vypnuto (Disabled)</span>
                <button class="btn-base btn-secondary btn-disabled" disabled>Zrušit</button>
              </div>
            </div>
          </div>

          <!-- 4. Icon Button -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>4. Ikona tlačítka (Icon Button)</h3>
                <p style="font-size:13px; color:var(--secondary)">Nastavení, servisní klíč, mřížka padů, zavřít</p>
              </div>
              <span class="card-badge">44 × 44 pt</span>
            </div>
            <div class="states-row">
              <div class="state-item">
                <span class="state-label">Klid (Nastavení)</span>
                <button class="btn-base btn-icon" title="Nastavení">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
                </button>
              </div>
              <div class="state-item">
                <span class="state-label">Stisknuto (Nástroj)</span>
                <button class="btn-base btn-icon is-pressed" title="Nástroje">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
                </button>
              </div>
              <div class="state-item">
                <span class="state-label">Zavřít křížek</span>
                <button class="btn-base btn-icon" title="Zavřít">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                </button>
              </div>
            </div>
          </div>

          <!-- 5. Segmented Hardware Keys -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>5. Mechanické klávesy režimů</h3>
                <p style="font-size:13px; color:var(--secondary)">Hardware klávesy s oranžovou LED lištou</p>
              </div>
              <span class="card-badge">LED Bar</span>
            </div>
            <div class="states-row">
              <div style="padding: 10px 0;">
                <div class="segmented-group">
                  <button class="segmented-key" onclick="selectSegment(this)">Poslech</button>
                  <button class="segmented-key active" onclick="selectSegment(this)">Hra</button>
                  <button class="segmented-key" onclick="selectSegment(this)">Po mně</button>
                </div>
              </div>
              <p style="font-size:12px; color:var(--secondary)">Aktivní klávesa nese 2 pt oranžovou LED lištu na spodním okraji s jemným dýcháním (3.0s perioda).</p>
            </div>
          </div>

          <!-- 6. Filter Chips -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>6. Filtrační štítky (Filter Chips)</h3>
                <p style="font-size:13px; color:var(--secondary)">Kategorie v Knihovně (Vše, Základ, Funk, Rock)</p>
              </div>
              <span class="card-badge">Kompaktní</span>
            </div>
            <div class="states-row">
              <div style="display:flex; gap:8px; flex-wrap:wrap; padding: 8px 0;">
                <button class="filter-chip active" onclick="toggleChip(this)">Vše</button>
                <button class="filter-chip" onclick="toggleChip(this)">Základ</button>
                <button class="filter-chip" onclick="toggleChip(this)">Funk</button>
                <button class="filter-chip" onclick="toggleChip(this)">Rock</button>
              </div>
              <p style="font-size:12px; color:var(--secondary)">Filtry nemají LED lištu — jsou to lehké štítky. Lišta patří pouze funkčním přepínačům režimů cvičení.</p>
            </div>
          </div>

          <!-- 7. Row Button (Lesson Row) -->
          <div class="matrix-card bg-plate" style="grid-column: 1 / -1;">
            <div class="card-header">
              <div>
                <h3>7. Řádek lekce v seznamu (ListRow / Lesson Card)</h3>
                <p style="font-size:13px; color:var(--secondary)">Strukturální deska, nikoliv plastický gumový pad</p>
              </div>
              <span class="card-badge">Karta vs Pad</span>
            </div>
            <div style="display:flex; flex-direction:column; gap:12px;">
              <div class="lesson-card-row">
                <div style="display:flex; align-items:center; gap:16px;">
                  <span style="font-size:22px; font-weight:700; color:var(--orange)">01</span>
                  <div>
                    <h4 style="font-size:18px; font-weight:700;">Kick na každou dobu</h4>
                    <p style="font-size:13px; color:var(--secondary)">Základní 4/4 takt · 90 BPM · 8 taktů</p>
                  </div>
                </div>
                <div style="display:flex; align-items:center; gap:14px;">
                  <div style="display:flex; gap:3px; color:var(--star-gold)">★ ★ ★</div>
                  <button class="btn-base btn-toolbar" style="min-height:36px; padding:0 12px; font-size:13px;">Hrát</button>
                </div>
              </div>
            </div>
          </div>

          <!-- 8. Destructive Action -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>8. Destruktivní akce (Smazat)</h3>
                <p style="font-size:13px; color:var(--secondary)">Smazat profil ovladače, vymazat mapování</p>
              </div>
              <span class="card-badge">Warm Red</span>
            </div>
            <div class="states-row">
              <div class="state-item">
                <span class="state-label">Klid (Rest)</span>
                <button class="btn-base btn-destructive">Smazat profil</button>
              </div>
              <div class="state-item">
                <span class="state-label">Ikona v řádku</span>
                <button class="btn-base btn-icon" style="color:var(--destructive)" title="Smazat">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                </button>
              </div>
            </div>
          </div>

          <!-- 9. Disabled State -->
          <div class="matrix-card bg-plate">
            <div class="card-header">
              <div>
                <h3>9. Vypnutý stav (Disabled)</h3>
                <p style="font-size:13px; color:var(--secondary)">Neaktivní obvod, žádné falešné podsvícení</p>
              </div>
              <span class="card-badge">Inert State</span>
            </div>
            <div class="states-row">
              <div class="state-item">
                <span class="state-label">Hero vypnuto</span>
                <button class="btn-base btn-primary btn-disabled" disabled>Uložit profil</button>
              </div>
              <div class="state-item">
                <span class="state-label">Sekundární vypnuto</span>
                <button class="btn-base btn-secondary btn-disabled" disabled>Připojit Bluetooth</button>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>

    <!-- ====================================================================
         TAB 2: Kontextové simulace obrazovek
         ==================================================================== -->
    <div id="tab-simulations" style="display:none;">
      <h2 class="section-title">Kontextové simulace skutečných obrazovek</h2>
      <p class="section-desc">Jak tlačítka zapadají do reálných ploch aplikace — toolbar hlavička, spodní ovládací transport Cvičení, a filtry v Knihovně.</p>

      <div id="simWrapper" class="var-a">
        <!-- Mockup 1: Toolbar Navigation -->
        <div class="screen-panel bg-chassis">
          <div style="font-size:12px; font-weight:700; color:var(--secondary); text-transform:uppercase; margin-bottom:12px;">Hlavička Knihovny (Toolbar Navigation)</div>
          <div style="display:flex; justify-content:space-between; align-items:center; background:var(--plate-top); padding:16px 20px; border-radius:14px; border:1px solid var(--hairline); box-shadow:var(--plate-shadow);">
            <button class="btn-base btn-toolbar">← Domů</button>
            <h2 style="font-size:22px; font-weight:700;">Knihovna lekcí</h2>
            <button class="btn-base btn-icon" title="Nastavení">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>
            </button>
          </div>
        </div>

        <!-- Mockup 2: Practice Screen Transport Bar -->
        <div class="screen-panel bg-chassis">
          <div style="font-size:12px; font-weight:700; color:var(--secondary); text-transform:uppercase; margin-bottom:12px;">Spodní ovládací lišta Cvičení (Transport Panel)</div>
          <div style="display:flex; justify-content:space-between; align-items:center; background:var(--plate-top); padding:16px 24px; border-radius:14px; border:1px solid var(--hairline); box-shadow:var(--plate-shadow); flex-wrap:wrap; gap:16px;">
            <div class="segmented-group">
              <button class="segmented-key" onclick="selectSegment(this)">Poslech</button>
              <button class="segmented-key active" onclick="selectSegment(this)">Hra</button>
              <button class="segmented-key" onclick="selectSegment(this)">Po mně</button>
            </div>
            
            <div style="display:flex; align-items:center; gap:12px;">
              <button class="btn-base btn-secondary">Znovu</button>
              <button class="btn-base btn-primary" style="padding:0 28px; font-size:17px;">Start</button>
              <button class="btn-base btn-secondary">Od začátku</button>
            </div>
            
            <div style="display:flex; align-items:center; gap:8px;">
              <div class="bg-dark-glass" style="padding:8px 14px; border-radius:8px; font-weight:700; font-family:monospace; font-size:18px;">100 BPM</div>
              <button class="btn-base btn-icon" title="Nástroj">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ====================================================================
         TAB 3: Srovnání A vs B
         ==================================================================== -->
    <div id="tab-comparison" style="display:none;">
      <h2 class="section-title">Srovnání Variant: Haptický hardware (A) vs. Akustický minimalismus (B)</h2>
      <p class="section-desc">Přímé porovnání dvou estetických směrů vedle sebe. Všechny rozměry zachovávají přesnou polohu a kompatibilitu.</p>

      <div class="comparison-container">
        <!-- Col A -->
        <div class="var-a">
          <div class="variant-banner bg-plate">
            <h2>Varianta A: Haptický hardware</h2>
            <p><strong>Estetika:</strong> Akai MPC Pro, hmatový silikon, vylisovaná lůžka, jednotný 8 pt rádius rohů, plastické fazety a živé oranžové LED dýchání.</p>
          </div>
          <div class="screen-panel bg-plate" style="display:flex; flex-direction:column; gap:16px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Hero akce:</span>
              <button class="btn-base btn-primary">Začít cvičit</button>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Sekundární pad:</span>
              <button class="btn-base btn-secondary">Znovu</button>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Toolbar:</span>
              <button class="btn-base btn-toolbar">← Domů</button>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Režimy:</span>
              <div class="segmented-group">
                <button class="segmented-key active">Hra</button>
                <button class="segmented-key">Po mně</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Col B -->
        <div class="var-b">
          <div class="variant-banner bg-plate">
            <h2>Varianta B: Akustický minimalismus</h2>
            <p><strong>Estetika:</strong> Studiový pult Braun / Dieter Rams, přesný 6 pt rádius, čistá 1 px linka bez masivních fazet, plochý satén a mechanické cvaknutí.</p>
          </div>
          <div class="screen-panel bg-plate" style="display:flex; flex-direction:column; gap:16px;">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Hero akce:</span>
              <button class="btn-base btn-primary">Začít cvičit</button>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Sekundární pad:</span>
              <button class="btn-base btn-secondary">Znovu</button>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Toolbar:</span>
              <button class="btn-base btn-toolbar">← Domů</button>
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-size:14px; font-weight:600;">Režimy:</span>
              <div class="segmented-group">
                <button class="segmented-key active">Hra</button>
                <button class="segmented-key">Po mně</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ====================================================================
         TAB 4: Pravidla a specifikace
         ==================================================================== -->
    <div id="tab-rules" style="display:none;">
      <h2 class="section-title">Designová pravidla systému tlačítek</h2>
      <p class="section-desc">Pravidla specifikovaná Ticketem 131, která musí být dodržena při budoucí implementaci ve SwiftUI.</p>

      <div class="rules-box">
        <h3 style="font-size:17px; margin-bottom:8px;">1. Pravidlo minimální dotykové plochy (Min Touch Size &ge; 44 pt)</h3>
        <p>Všechna tlačítka v celé aplikaci bez výjimky garantují minimální rozměr <strong>48 × 48 pt</strong> (převyšuje Apple standard 44 pt). Vnitřní odsazení (padding) je <strong>vždy uvnitř</strong> vykresleného rámu tlačítka. Viditelné tělo tlačítka se rovná jeho interaktivní dotykové ploše.</p>
      </div>

      <div class="rules-box">
        <h3 style="font-size:17px; margin-bottom:8px;">2. Pravidlo jednotného rádiusu rohů (One Corner Radius)</h3>
        <p><strong>Varianta A:</strong> Jednotný rádius <strong>8 pt</strong> pro všechny běžné ovládací prvky (odvozeno od 3×3 padů na Home screenu). Velké šasi desky mají 16 pt.<br>
        <strong>Varianta B:</strong> Jednotný rádius <strong>6 pt</strong> pro funkční tlačítka (odlišuje funkční prvky od velkých 8 pt bicích padů).</p>
      </div>

      <div class="rules-box">
        <h3 style="font-size:17px; margin-bottom:8px;">3. Kde se používá světelná LED lišta (Hardware Light Bar)</h3>
        <p>Oranžový 2 pt LED světelný proužek se používá <strong>výhradně</strong> pro indikaci aktivního mechanického režimu (Poslech / Hra / Po mně) a v notovém pruhu cvičení. <strong>Nikdy</strong> se nepoužívá na běžných tlačítkách, ikonách ani filtračních čipech v Knihovně.</p>
      </div>

      <div class="rules-box">
        <h3 style="font-size:17px; margin-bottom:8px;">4. Pohyb při stlačení a chování při omezení pohybu (Reduce Motion)</h3>
        <p>Při běžném stlačení: pružné stlačení (scale 0.965, posun dolů o 1.5 pt, u Variant A jemný záblesk).<br>
        Při zapnutém <code>accessibilityReduceMotion</code>: <strong>žádná změna měřítka (scale 1.0) ani posun (offset 0)</strong>. Odezva je realizována výhradně okamžitým 12% ztmavením povrchu padu. LED dýchání se vypíná na statické světlo.</p>
      </div>

      <div class="rules-box">
        <h3 style="font-size:17px; margin-bottom:8px;">5. Rozdíl mezi Toolbar tlačítkem a tlačítkem v ploše (Toolbar vs In-page)</h3>
        <p>Tlačítka v navigační liště (Toolbar) nesmí působit jako masivní gumové kostky bojující s titulkem obrazovky. Mají kompaktní výšku 44 pt, jemnější obvodovou linku a zapuštěný saténový podklad bez těžkých vrhacích stínů.</p>
      </div>

      <div class="rules-box">
        <h3 style="font-size:17px; margin-bottom:8px;">6. Rozdíl mezi řádkem lekce a tlačítkem (ListRow vs Button)</h3>
        <p>Řádek lekce je <strong>strukturální deska (panel/plate)</strong>, nikoliv akční tlačítko. Má ploché saténové tělo a jemné ohraničení. Uvnitř řádku jsou vnořené samostatné akční prvky (hvězdičky, popover info, zámek) jako plnohodnotní sourozenci s vlastní dotykovou geometrií.</p>
      </div>
    </div>

    <!-- ====================================================================
         TAB 5: Inventář původního stavu (Before screenshots)
         ==================================================================== -->
    <div id="tab-inventory" style="display:none;">
      <h2 class="section-title">Inventář stávajícího stavu tlačítek (Before)</h2>
      <p class="section-desc">Seznam všech zjištěných problémů z fyzického testování na iPadu a snímků ze simulátoru iPad Pro 11″.</p>

      <table class="inventory-table bg-plate" style="border-radius:12px;">
        <thead>
          <tr>
            <th>Typ tlačítka</th>
            <th>Kde se nachází</th>
            <th>Současný styl v kódu</th>
            <th>Co působí špatně / rozbitě</th>
            <th>Referenční snímek</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><strong>Toolbar Home / Zpět</strong></td>
            <td>Knihovna, Trénink, Dnešní cvičení, Cvičení</td>
            <td><code>PadSecondaryButtonStyle</code></td>
            <td>Příliš masivní gumový blok s ostrým stínem v navigační liště; vizuálně soutěží s názvem obrazovky.</td>
            <td><a href="screenshots/library_landscape_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/library_landscape_light.png" alt="Library"></a></td>
          </tr>
          <tr>
            <td><strong>Primární akce (Hero)</strong></td>
            <td>Knihovna ("Hrát další"), Cvičení ("Start"), Trénink</td>
            <td><code>PadPrimaryButtonStyle</code></td>
            <td>Dvojitá bílá a černá fazeta působí v ploše jako nepřirozeně vytažená pryž; bílý flash je příliš agresivní.</td>
            <td><a href="screenshots/practice_landscape_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/practice_landscape_light.png" alt="Practice"></a></td>
          </tr>
          <tr>
            <td><strong>Sekundární akce</strong></td>
            <td>Cvičení ("Znovu"), Trénink ("Dnes ne")</td>
            <td><code>PadSecondaryButtonStyle</code></td>
            <td>Ve světlém režimu barva povrchu splývá s podkladovou deskou; v dialozích mají různou šířku a výšku.</td>
            <td><a href="screenshots/today_portrait_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/today_portrait_light.png" alt="Today"></a></td>
          </tr>
          <tr>
            <td><strong>Ikona (Icon Button)</strong></td>
            <td>Nastavení v Knihovně, Nástroj ve Cvičení</td>
            <td><code>PadIconButtonStyle</code></td>
            <td>Ikona v kostce 48×48 pt působí těžkopádně; LED lišta při vybrání ořezává rohy podivným způsobem.</td>
            <td><a href="screenshots/library_portrait_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/library_portrait_light.png" alt="Icon"></a></td>
          </tr>
          <tr>
            <td><strong>Přepínač režimů</strong></td>
            <td>Cvičení (Poslech / Hra / Po mně)</td>
            <td><code>HardwareKeyButtonStyle</code></td>
            <td>Jednotlivé klávesy plavou s mezerami namísto souvislého mechanického bloku.</td>
            <td><a href="screenshots/practice_portrait_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/practice_portrait_light.png" alt="Modes"></a></td>
          </tr>
          <tr>
            <td><strong>Filtrační čipy</strong></td>
            <td>Knihovna (Vše, Základ, Funk, Rock)</td>
            <td><code>HardwareKeyButtonStyle</code></td>
            <td>Filtry měly vylisovanou LED lištu na spodku! Čip je štítek, nikoliv mechanická přepínací klávesa.</td>
            <td><a href="screenshots/library_landscape_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/library_landscape_light.png" alt="Chips"></a></td>
          </tr>
          <tr>
            <td><strong>Řádek lekce</strong></td>
            <td>Knihovna (seznam lekcí)</td>
            <td><code>ListRow</code> + <code>satinPlate()</code></td>
            <td>Každý řádek má dvě vrstvy stínů a fazet; v rolovacím seznamu působí přeplácaně a těžce.</td>
            <td><a href="screenshots/library_landscape_dark.png" target="_blank"><img class="screenshot-thumb" src="screenshots/library_landscape_dark.png" alt="Rows"></a></td>
          </tr>
          <tr>
            <td><strong>Destruktivní akce</strong></td>
            <td>Nastavení ovladače ("Smazat profil")</td>
            <td>Žádný styl / systémová červená</td>
            <td>Chybí dedikovaný hardware styl pro destruktivní akce v paletě; systémová červená bije do očí.</td>
            <td><a href="screenshots/controller_landscape_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/controller_landscape_light.png" alt="Delete"></a></td>
          </tr>
          <tr>
            <td><strong>Vypnuté tlačítko</strong></td>
            <td>Odemknout nákupy, Uložit před dokončením</td>
            <td>Pouze <code>opacity: 0.45</code></td>
            <td>Průhledná 45% oranžová vypadá jako špinavá broskev; přístroj má mít vypnuté podsvícení, ne průhlednost.</td>
            <td><a href="screenshots/purchases_landscape_light.png" target="_blank"><img class="screenshot-thumb" src="screenshots/purchases_landscape_light.png" alt="Purchases"></a></td>
          </tr>
        </tbody>
      </table>
    </div>

  </main>

  <!-- Interactive JavaScript logic -->
  <script>
    let soundEnabled = true;
    let audioCtx = null;

    function playClickSound() {{
      if (!soundEnabled) return;
      try {{
        if (!audioCtx) {{
          audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        }}
        if (audioCtx.state === 'suspended') {{
          audioCtx.resume();
        }}
        const osc = audioCtx.createOscillator();
        const gain = audioCtx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(140, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(40, audioCtx.currentTime + 0.04);
        gain.gain.setValueAtTime(0.18, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.04);
        osc.connect(gain);
        gain.connect(audioCtx.destination);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.05);
      }} catch(e) {{}}
    }}

    document.addEventListener('pointerdown', (e) => {{
      if (e.target.closest('button')) {{
        playClickSound();
      }}
    }});

    function setTheme(theme) {{
      document.documentElement.setAttribute('data-theme', theme);
      document.getElementById('btnThemeLight').classList.toggle('active', theme === 'light');
      document.getElementById('btnThemeDark').classList.toggle('active', theme === 'dark');
    }}

    function setVariant(variant) {{
      if (variant === 'compare') {{
        showTab('comparison');
        document.getElementById('btnVarA').classList.remove('active');
        document.getElementById('btnVarB').classList.remove('active');
        document.getElementById('btnVarCompare').classList.add('active');
        return;
      }}
      document.documentElement.setAttribute('data-variant', variant);
      document.getElementById('btnVarA').classList.toggle('active', variant === 'a');
      document.getElementById('btnVarB').classList.toggle('active', variant === 'b');
      document.getElementById('btnVarCompare').classList.remove('active');
      
      const mw = document.getElementById('matrixWrapper');
      const sw = document.getElementById('simWrapper');
      if (mw) {{
        mw.className = variant === 'a' ? 'var-a' : 'var-b';
      }}
      if (sw) {{
        sw.className = variant === 'a' ? 'var-a' : 'var-b';
      }}
    }}

    function toggleSound() {{
      soundEnabled = !soundEnabled;
      const btn = document.getElementById('btnSound');
      btn.innerText = soundEnabled ? '🔊 Zvuk kliku' : '🔇 Zvuk vypnut';
      btn.classList.toggle('active', soundEnabled);
    }}

    function toggleMotion() {{
      const current = document.documentElement.getAttribute('data-reduce-motion') === 'true';
      const next = !current;
      document.documentElement.setAttribute('data-reduce-motion', next ? 'true' : 'false');
      const btn = document.getElementById('btnMotion');
      btn.innerText = next ? '⚡ Motion: OFF (Reduced)' : '⚡ Motion: ON';
      btn.classList.toggle('active', !next);
    }}

    function showTab(tabId) {{
      const tabs = ['matrix', 'simulations', 'comparison', 'rules', 'inventory'];
      tabs.forEach(t => {{
        const el = document.getElementById('tab-' + t);
        if (el) el.style.display = (t === tabId) ? 'block' : 'none';
      }});
      document.querySelectorAll('.tab-nav .tab-btn').forEach((btn, idx) => {{
        btn.classList.toggle('active', tabs[idx] === tabId);
      }});
    }}

    function selectSegment(btn) {{
      btn.parentElement.querySelectorAll('.segmented-key').forEach(k => k.classList.remove('active'));
      btn.classList.add('active');
    }}

    function toggleChip(btn) {{
      btn.parentElement.querySelectorAll('.filter-chip').forEach(k => k.classList.remove('active'));
      btn.classList.add('active');
    }}

    // Keyboard Shortcuts
    document.addEventListener('keydown', (e) => {{
      const key = e.key.toUpperCase();
      if (key === 'L') {{
        const cur = document.documentElement.getAttribute('data-theme');
        setTheme(cur === 'light' ? 'dark' : 'light');
      }} else if (key === 'V') {{
        const cur = document.documentElement.getAttribute('data-variant');
        setVariant(cur === 'a' ? 'b' : 'a');
      }} else if (key === 'M') {{
        toggleMotion();
      }}
    }});
  </script>
</body>
</html>"""
    with open(os.path.join(BASE_DIR, "index.html"), "w", encoding="utf-8") as f:
        f.write(html_content)
    print("Wrote index.html")

def generate_rules_variant_a():
    content = f"""<!DOCTYPE html>
<html lang="cs" data-theme="light">
<head>
  <meta charset="utf-8">
  <title>Pravidla: Varianta A — Haptický hardware (Smack-a-Pad)</title>
  <style>
    {CSS_TOKENS}
    body {{ max-width: 900px; margin: 40px auto; padding: 0 24px; line-height: 1.6; }}
    h1 {{ font-size: 28px; margin-bottom: 8px; }}
    h2 {{ font-size: 20px; margin-top: 32px; margin-bottom: 12px; border-bottom: 1px solid var(--hairline); padding-bottom: 8px; }}
    ul {{ margin-left: 24px; margin-bottom: 16px; }}
    li {{ margin-bottom: 8px; }}
    .rule-badge {{ background: var(--surface); border: 1px solid var(--hairline); padding: 2px 8px; border-radius: 4px; font-weight: 700; font-size: 12px; }}
  </style>
</head>
<body>
  <p><a href="index.html" style="color:var(--orange); text-decoration:none; font-weight:600;">← Zpět na interaktivní náhled</a></p>
  <h1 style="margin-top:16px;">Varianta A: Haptický hardware ("Akai MPC Tactile")</h1>
  <p style="color:var(--secondary);">Designový manuál a technická pravidla pro implementaci varianty A.</p>

  <h2>1. Filozofie a charakter</h2>
  <p>Varianta A přímo rozšiřuje materiálový jazyk domovské obrazovky (HomeScreen.swift, tickety 112, 119). Tlačítka působí jako precision-molded silikonové klávesy usazené ve vyfrézovaných lůžkách na saténové desce nástroje.</p>

  <h2>2. Geometrie a rozměry</h2>
  <ul>
    <li><span class="rule-badge">Rádius rohů:</span> <strong>Přesně 8 pt</strong> pro všechna běžná tlačítka (Hero pad, sekundární pad, ikony, toolbar tlačítka, filtrační čipy). Velké šasi desky mají 16 pt.</li>
    <li><span class="rule-badge">Minimální dotyková plocha:</span> <strong>48 × 48 pt</strong> (splňuje a převyšuje 44 pt standard).</li>
    <li><span class="rule-badge">Vnitřní odsazení:</span> Vždy uvnitř rámu tlačítka (<code>Padding</code> uvnitř label closure). Tělo tlačítka = plná dotyková plocha.</li>
  </ul>

  <h2>3. Hloubka, fazety a stíny</h2>
  <ul>
    <li><strong>Horní odlesk (Highlight Bevel):</strong> 1.5 pt šířka, barva <code>rgba(255,255,255,0.45)</code> ve světlém / <code>0.12</code> v tmavém režimu.</li>
    <li><strong>Spodní stín stlačení (Shade Bevel):</strong> 2.0 pt šířka (2.5 pt u Hero padu), barva <code>rgba(0,0,0,0.25)</code> ve světlém / <code>0.45</code> v tmavém režimu.</li>
    <li><strong>Vnější stín (Drop Shadow):</strong> <code>0 2px 4px rgba(0,0,0,0.12)</code> imitující vyfrézované lůžko.</li>
  </ul>

  <h2>4. Použití světelné LED lišty (Hardware Light Bar)</h2>
  <ul>
    <li><strong>Výhradní použití:</strong> Pouze na mechanických klávesách přepínače režimů (Poslech / Hra / Po mně) a v notovém pásu cvičení.</li>
    <li><strong>Zákaz:</strong> Nikdy neumisťovat LED lištu na běžná toolbar tlačítka, ikony, ani filtrační čipy v Knihovně.</li>
    <li><strong>Animace:</strong> Sinusové dýchání jasu s periodou 3.0 s (vypíná se při Reduce Motion).</li>
  </ul>

  <h2>5. Pohyb a odezva (Motion)</h2>
  <ul>
    <li><strong>Při stisku:</strong> Downward travel <code>offset(y: 1.5pt)</code>, stlačení <code>scale(0.965)</code>, blesk podsvícení bílou barvou 0.28 krytí (120 ms odeznění).</li>
    <li><strong>Reduce Motion:</strong> 0 scale, 0 travel, 0 flash. Pouze 12% ztmavení těla tlačítka pro okamžitou tónovou zpětnou vazbu.</li>
  </ul>
</body>
</html>"""
    with open(os.path.join(BASE_DIR, "rules-variant-a.html"), "w", encoding="utf-8") as f:
        f.write(content)
    print("Wrote rules-variant-a.html")

def generate_rules_variant_b():
    content = f"""<!DOCTYPE html>
<html lang="cs" data-theme="light">
<head>
  <meta charset="utf-8">
  <title>Pravidla: Varianta B — Akustický minimalismus (Smack-a-Pad)</title>
  <style>
    {CSS_TOKENS}
    body {{ max-width: 900px; margin: 40px auto; padding: 0 24px; line-height: 1.6; }}
    h1 {{ font-size: 28px; margin-bottom: 8px; }}
    h2 {{ font-size: 20px; margin-top: 32px; margin-bottom: 12px; border-bottom: 1px solid var(--hairline); padding-bottom: 8px; }}
    ul {{ margin-left: 24px; margin-bottom: 16px; }}
    li {{ margin-bottom: 8px; }}
    .rule-badge {{ background: var(--surface); border: 1px solid var(--hairline); padding: 2px 8px; border-radius: 4px; font-weight: 700; font-size: 12px; }}
  </style>
</head>
<body>
  <p><a href="index.html" style="color:var(--orange); text-decoration:none; font-weight:600;">← Zpět na interaktivní náhled</a></p>
  <h1 style="margin-top:16px;">Varianta B: Akustický minimalismus ("Studio Console / Braun")</h1>
  <p style="color:var(--secondary);">Designový manuál a technická pravidla pro implementaci varianty B.</p>

  <h2>1. Filozofie a charakter</h2>
  <p>Varianta B vychází z klasických studiových rackových jednotek a designového jazyka Dietera Ramse (Braun). Eliminuje masivní plastické fazety ve prospěch precizních 1 px obvodových linek, plochých saténových materiálů a chirurgické čitelnosti.</p>

  <h2>2. Geometrie a rozměry</h2>
  <ul>
    <li><span class="rule-badge">Rádius rohů:</span> <strong>Přesně 6 pt</strong> pro všechna funkční tlačítka v aplikaci. Tím se vytváří jasná hierarchie: 8 pt zůstává pro velké hrací pady na Home screenu, zatímco 6 pt patří precizním ovládacím prvkům.</li>
    <li><span class="rule-badge">Minimální dotyková plocha:</span> <strong>48 × 48 pt</strong> (vždy &ge; 44 pt dle Apple HIG).</li>
    <li><span class="rule-badge">Vnitřní odsazení:</span> Vždy uvnitř rámu tlačítka.</li>
  </ul>

  <h2>3. Hloubka a obvodová linka</h2>
  <ul>
    <li><strong>Žádné tlusté fazety:</strong> Tlačítka nemají 1.5 pt vnitřní rámečky. Místo toho mají ostrou 1 px obvodovou linku <code>Theme.hairline</code>.</li>
    <li><strong>Spodní mechanická hrana:</strong> Přesný spodní kontakt <code>0 1.5px 0 rgba(0,0,0,0.22)</code>, který dává pocit fyzického mikrospínače.</li>
    <li><strong>Hero Pad:</strong> Plochý oranžový satén s lehkým ambientním stínem <code>0 2px 8px rgba(255,107,0,0.25)</code>.</li>
  </ul>

  <h2>4. Použití světelné LED lišty</h2>
  <ul>
    <li>Pouze na přepínači režimů (Poslech/Hra/Po mně). Zde má lišta výšku 1.5 pt a čisté geometrické ohraničení bez rozmazané záře.</li>
    <li>Filtrační čipy mají namísto lišty reverzní kontrastní tělo (černý inkoust) a 6 pt oranžový indikační bod.</li>
  </ul>

  <h2>5. Pohyb a odezva (Motion)</h2>
  <ul>
    <li><strong>Při stisku:</strong> Mikroskopický zdvih <code>translateY(1.0px)</code> a <code>scale(0.985)</code>, rychlá odezva 90 ms bez bílého záblesku (pouze okamžité ztmavení oranžové na sytý odstín <code>#E55A00</code>).</li>
    <li><strong>Reduce Motion:</strong> 0 scale, 0 posun, okamžitý tónový skok.</li>
  </ul>
</body>
</html>"""
    with open(os.path.join(BASE_DIR, "rules-variant-b.html"), "w", encoding="utf-8") as f:
        f.write(content)
    print("Wrote rules-variant-b.html")

def generate_proposal_readme():
    content = """# 131 — Návrh: Jednotný systém tlačítek pro celou aplikaci (Button System Proposal)

Tento dokument a doprovodný interaktivní offline náhled v `docs/design/2026-11-07-button-system/index.html` představují ucelený systém tlačítek pro Smack-a-Pad. 

Cílem návrhu je vyřešit vizuální nesourodost a vychýlení tlačítek po zavedení saténového skinu v ticketech 126–129 a navrhnout **dvě čisté, hapticky věrné varianty** (A a B), které respektují tělo nástroje ("Klidný satén" & Home MPC controller) a striktní pravidla minimální dotykové plochy bez jakýchkoliv změn v rozvržení obrazovek (layoutu).

---

## 1. Jak otevřít interaktivní náhled

Otevřete soubor v Safari nebo jiném prohlížeči (funguje zcela offline):
```bash
open docs/design/2026-11-07-button-system/index.html
```

### Klávesové zkratky a ovládání:
- **`L`**: Přepnutí Světlý (Cream White) / Tmavý (Warm Soft Black) motiv.
- **`V`**: Přepnutí varianty tlačítek: **Varianta A** (Haptický hardware) vs. **Varianta B** (Akustický minimalismus).
- **`M`**: Zapnutí / vypnutí šetření pohybu (Reduce Motion).
- **Zvukový klik**: Každé stisknutí tlačítka generuje autentický tichý mechanický zvuk (Web Audio API syntetizér).

---

## 2. Inventář stávajícího stavu tlačítek (Inventory Table)

Při read-only auditu všech souborů v `SmackAPad/Sources/UI/` bylo identifikováno 9 odlišných funkčních typů tlačítek. Níže uvedená tabulka dokumentuje jejich současný stav, velikost, problémy a referenční snímky pořízené na simulátoru iPad Pro 11″ (M5).

| Typ tlačítka | Obrazovky | Současný styl v kódu | Současná velikost | Co působí špatně / rozbitě | Referenční snímek |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **1. Toolbar tlačítko (Home/Zpět)** | Knihovna, Trénink, Dnešní cvičení, Cvičení | `PadSecondaryButtonStyle` | `minHeight: 48pt`, padding v labelu | Působí jako plovoucí gumová kostka s těžkým stínem; v navigační liště vizuálně soutěží s nadpisem obrazovky; nízký kontrast vůči šasi. | [Snímek](screenshots/library_landscape_light.png) |
| **2. Primární akce (Hero Pad)** | Knihovna ("Hrát další"), Cvičení ("Start"), Trénink ("Zahájit"), Nákupy | `PadPrimaryButtonStyle` | Oranžový podklad `#FF6B00`, černý text | Masivní 1.5pt horní bílá a 2.5pt spodní černá fazeta působí jako vytažená pryž; bílý 38% flash při stisku vypadá jako blesk fotoaparátu; rozostřená oranžová záře. | [Snímek](screenshots/practice_landscape_light.png) |
| **3. Sekundární akce** | Cvičení ("Znovu", "Od začátku"), Trénink ("Dnes ne"), Nákupy ("Obnovit") | `PadSecondaryButtonStyle` | `surface` `#EBE5DA` / `#2A2824` | Ve světlém režimu barva povrchu splývá se saténovou deskou; v dialozích a formulářích mají tlačítka nekonzistentní poměry stran. | [Snímek](screenshots/today_portrait_light.png) |
| **4. Ikona tlačítka (Icon Button)** | Knihovna (Ozubené kolo), Cvičení (Nástroj, Rozložení padů), Nákupy (Zavřít) | `PadIconButtonStyle` | Pevný čtverec 48×48 pt | Ikona uvnitř 48pt těžkého padu s fazetami působí humpolácky; oranžová LED lišta ve vybraném stavu nehezky ořezává spodní rádius. | [Snímek](screenshots/library_portrait_light.png) |
| **5. Přepínač režimů (Segmented)** | Cvičení (Poslech / Hra / Po mně), Nastavení, MIDI Learn | `HardwareKeyButtonStyle` / `PlexSegmentedPicker` | Segmenty spojené či dělené | V Cvičení plavou jednotlivá tlačítka s mezerami namísto souvislé klávesnice; v Nastavení se používá systémový `UISegmentedControl`, který neladí se saténem. | [Snímek](screenshots/practice_portrait_light.png) |
| **6. Filtrační štítky (Filter Chips)** | Knihovna (Vše, Základ, Funk, Rock...) | `HardwareKeyButtonStyle(isSelected:)` | Horizontální řada štítků | Používaly `HardwareKeyButtonStyle`, takže aktivní filtr měl vylisovanou LED lištu na spodku! Čip je filtrační štítek, nikoliv mechanická transportní klávesa. | [Snímek](screenshots/library_landscape_light.png) |
| **7. Řádek lekce v seznamu** | Knihovna (`LibraryLessonRow` / `ListRow`) | `ListRow` + `.satinPlate()` | Výška &ge; 68 pt | Každý řádek má dvě vrstvy stínů a mikrofazet; v rolovacím seznamu vzniká obrovský vizuální šum a compete o pozornost s tlačítky. | [Snímek](screenshots/library_landscape_dark.png) |
| **8. Destruktivní akce** | Nastavení ovladače ("Smazat profil"), potvrzovací dialog | `Button(role: .destructive)` | Běžný text / červená ikona | Chybí dedikovaný hardware styl; výchozí systémová červená bije do očí a neladí s teplou paletou soft black & cream. | [Snímek](screenshots/controller_landscape_light.png) |
| **9. Vypnuté tlačítko (Disabled)** | Odemknout nákupy, Uložit před dokončením učení | Pouze `opacity: 0.45` | Poloprůhledný podklad | 45% průhledná oranžová barva vypadá jako vybledlá broskev; reálný hardware má vypnuté podsvícení, ne průhledný plast, kterým prosvítá podklad. | [Snímek](screenshots/purchases_landscape_light.png) |

---

## 3. Představení dvou variant systému (Variant A & B)

Obě varianty striktně vycházejí z palety ticketu 92 a saténových tokenů ticketu 126. Oranžová `#FF6B00` zůstává jedinou primární barvou.

### Varianta A: "Haptický hardware" (Akai MPC Tactile)
- **Charakter:** Přímé rozšíření domovské obrazovky. Tlačítka působí jako precision-molded silikonové klávesy usazené ve vyfrézovaných lůžkách na těle přístroje.
- **Rádius rohů:** **8 pt** jednotně pro všechny běžné ovládací prvky (odvozeno z 3×3 bicích padů na Home).
- **Hloubka:** Jemné vyfrézované lůžko se stínem `0 2px 4px rgba(0,0,0,0.12)`, horní odlesk fazety 1.5 pt a spodní stín stlačení 2.0 pt (2.5 pt u Hero padu).
- **Hero Pad:** Zářivý oranžový satén `#FF6B00` s tmavým nápisem `#1F1D1A` a teplou oranžovou elektroluminiscenční září `0 0 16px rgba(255,107,0,0.35)`.
- **Segmentové klávesy:** Jednolitý blok kláves usazený v zapuštěné drážce. Aktivní klávesa má vylisovanou **2 pt oranžovou LED lištu** na spodní hraně s pomalým dýcháním (3.0 s perioda).
- **Filtrační čipy:** Tvar zaoblené kapsle (8 pt), vybraný čip má oranžový rámeček a sytý text (bez LED lišty).
- **Odezva při stlačení:** Fyzické stlačení `scale(0.965)`, posun dolů o 1.5 pt a rychlý bílý záblesk podsvícení (120 ms).

### Varianta B: "Akustický minimalismus" (Studio Console / Braun Precision)
- **Charakter:** Styl špičkových studiových pultů a přístrojů Dietera Ramse (Braun). Eliminuje masivní plastické fazety ve prospěch precizních 1 px obvodových linek a plochého saténu.
- **Rádius rohů:** **6 pt** pro všechna funkční tlačítka v aplikaci. Vytváří jasnou hierarchii: 8 pt rádius patří velkým hracím padům na Home screenu, zatímco 6 pt patří precizním ovládacím prvkům.
- **Hloubka:** Žádné tlusté fazety; pouze ostrá 1 px obvodová linka `Theme.hairline` a spodní mechanická hrana `0 1.5px 0 rgba(0,0,0,0.22)`, která dává pocit fyzického mikrospínače.
- **Hero Pad:** Čistý oranžový satén s lehkým ambientním stínem `0 2px 8px rgba(255,107,0,0.25)`.
- **Toolbar tlačítka:** Vzdušná tlačítka s 1 px linkou, která v klidovém stavu neruší název obrazovky.
- **Filtrační čipy:** Plochý štítek (6 pt), aktivní stav má plné tělo v barvě inkoustu s 6 pt oranžovým indikačním bodem.
- **Odezva při stlačení:** Mikroskopický zdvih dolů o 1.0 pt a `scale(0.985)`, okamžité ztmavení oranžové na sytý odstín `#E55A00` bez rušivého bílého blesku.

---

## 4. Pravidla systému tlačítek (Rules)

Následující pravidla jsou závazná pro budoucí implementační ticket:

1. **Minimální dotyková plocha (Min Touch Size &ge; 44 pt):** Všechna tlačítka v aplikaci musí garantovat dotykovou plochu minimálně **48 × 48 pt** (respektive 44 pt u kompaktních toolbar prvků).
2. **Padding uvnitř padu:** Vnitřní odsazení (`padding`) musí být vždy uvnitř label closure tlačítka, aby viditelný pad přesně odpovídal ploše reagující na dotyk.
3. **Jeden rádius rohů:** Buď striktně 8 pt (Varianta A), nebo 6 pt pro ovládací prvky (Varianta B). Žádné náhodné poloměry 4, 10 nebo 14 pt na tlačítkách.
4. **Světelná LED lišta:** Vyhrazena **pouze pro přepínač režimů** (Poslech/Hra/Po mně) a notový pás. Nikdy na filtrech ani ikonách.
5. **Chování při Reduce Motion:** Při zapnutém šetření pohybu v iOS se vypíná jakýkoliv `scale` i `offset`. Tlačítko reaguje výhradně 12% ztmavením povrchu. LED lišta svítí stabilně bez dýchání.
6. **Toolbar tlačítko vs. tlačítko v ploše:** Toolbar tlačítka musí být opticky lehčí (výška 44 pt, jemná linka), aby nepotlačovala titulek stránky.
7. **Řádek lekce vs. tlačítko:** Řádek lekce je strukturální karta/deska se seznamem informací, nikoliv mačkací pryžový pad. Akční prvky uvnitř řádku (hvězdičky, zámek) mají vlastní oddělenou dotykovou geometrii.
8. **Žádná změna layoutu:** Pozice, šířky, pořadí a rozvržení obrazovek zůstávají zachovány.

---

## 5. Otevřené otázky pro Jakuba (max 3)

1. **Volba charakteru: Varianta A (Haptický hardware / MPC) nebo Varianta B (Akustický minimalismus / Braun)?**
   - *Varianta A* přináší plný pocit gumových padů z Home screenu i do zbytku aplikace s výraznými fazetami a 8 pt rádiusem.
   - *Varianta B* působí dospěleji, čistěji a lehčeji díky 6 pt rádiusu a precizním 1 px linkám bez těžkých stínů.
2. **Podoba Toolbar tlačítek (Domů / Zpět):**
   - Vyhovuje vám, aby tlačítko "Domů" v liště bylo decentní nízkoprofilové tlačítko s jemnou linkou, nebo má mít plné tělo saténového padu jako na domovské obrazovce?
3. **Odezva při stisku (Press Feedback):**
   - Preferujete haptický bílý záblesk podsvícení padu (Varianta A — MPC styl), nebo čisté mechanické ztmavení barvy bez záblesku (Varianta B — studiový mikrospínač)?
"""
    with open(os.path.join(BASE_DIR, "README.md"), "w", encoding="utf-8") as f:
        f.write(content)
    print("Wrote README.md")

if __name__ == "__main__":
    generate_index_html()
    generate_rules_variant_a()
    generate_rules_variant_b()
    generate_proposal_readme()
    print("All files generated successfully!")
