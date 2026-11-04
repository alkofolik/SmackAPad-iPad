#!/usr/bin/env python3
"""
Generate self-contained HTML previews and README for Ticket 60 (Home screen design proposals).
Uses plain template strings with .replace() to avoid f-string curly brace conflicts.
Outputs:
- proposal-a.html (Pad Matrix / The Logo Is the Menu)
- proposal-b.html (Front Panel / Typographic Master Rows)
- proposal-c.html (Studio Console Split / Asymmetric Station & Dispatch)
- index.html (Interactive Hub & Comparison Workbench)
- README.md (Comprehensive Documentation, Storyboards, SwiftUI Mapping, Recommendations, Open Questions)
"""

import base64
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEST = Path(__file__).resolve().parent

# Read font as base64
font_path = ROOT / "SmackAPad/Resources/Fonts/IBMPlexSans[wdth,wght].ttf"
font_b64 = base64.b64encode(font_path.read_bytes()).decode("ascii")

# Read wordmark SVG path
wordmark_svg_path = ROOT / "SmackAPad/Assets.xcassets/LaunchWordmark.imageset/LaunchWordmark.svg"
wordmark_raw = wordmark_svg_path.read_text(encoding="utf-8")
path_match = re.search(r'd="([^"]+)"', wordmark_raw)
wordmark_d = path_match.group(1) if path_match else ""

print("Assets loaded: Font base64 and SVG wordmark paths ready.")

# Shared CSS styles
SHARED_CSS = """
@font-face {
  font-family: 'IBM Plex Sans';
  src: url(data:font/ttf;base64,__FONT_B64__) format('truetype');
  font-weight: 100 900;
  font-style: normal;
  font-display: block;
}

:root {
  --cream: #F2F0EA;
  --black: #111111;
  --orange: #FF5B1F;
  --theme-orange: #FF6B00;
  --grey-surface-light: #E7E5DF;
  --grey-border-light: rgba(17, 17, 17, 0.16);
  --grey-secondary-light: #5A5A56;
  
  --dark-bg: #111111;
  --dark-surface: #1E1E20;
  --dark-border: rgba(242, 240, 234, 0.16);
  --dark-ink: #F2F0EA;
  --dark-secondary: #9E9E98;
  
  --current-bg: var(--cream);
  --current-ink: var(--black);
  --current-surface: var(--grey-surface-light);
  --current-border: var(--grey-border-light);
  --current-secondary: var(--grey-secondary-light);
  
  --radius-control: 4px;
  --radius-pad: 8px;
  --radius-card: 10px;
}

body.dark-mode {
  --current-bg: var(--dark-bg);
  --current-ink: var(--dark-ink);
  --current-surface: var(--dark-surface);
  --current-border: var(--dark-border);
  --current-secondary: var(--dark-secondary);
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  -webkit-tap-highlight-color: transparent;
}

body {
  background: #141416;
  color: #ECECEC;
  font-family: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, sans-serif;
  font-size: 16px;
  line-height: 1.5;
  padding: 24px 20px 48px;
  min-height: 100vh;
}

.app-header {
  max-width: 1360px;
  margin: 0 auto 20px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.title-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  flex-wrap: wrap;
  gap: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.15);
  padding-bottom: 16px;
}

.title-group h1 {
  font-size: 26px;
  font-weight: 700;
  letter-spacing: -0.02em;
  color: #FFFFFF;
  display: flex;
  align-items: center;
  gap: 12px;
}

.title-group p {
  font-size: 15px;
  color: #A6A6A6;
  margin-top: 4px;
}

.badge {
  display: inline-block;
  padding: 3px 8px;
  border-radius: 4px;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  background: var(--orange);
  color: #111;
}

.nav-tabs {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.nav-tab {
  background: #242426;
  color: #CCCCCC;
  border: 1px solid rgba(255, 255, 255, 0.15);
  padding: 8px 16px;
  font-size: 14px;
  font-weight: 600;
  border-radius: 6px;
  text-decoration: none;
  transition: all 0.15s ease;
  min-height: 40px;
  display: inline-flex;
  align-items: center;
}

.nav-tab:hover {
  background: #333336;
  color: #FFF;
}

.nav-tab.active {
  background: #FFFFFF;
  color: #111;
  border-color: #FFFFFF;
}

.controls-panel {
  background: #202022;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 8px;
  padding: 12px 18px;
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  align-items: center;
}

.control-group {
  display: flex;
  align-items: center;
  gap: 10px;
}

.control-label {
  font-size: 13px;
  font-weight: 600;
  color: #999;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.seg-picker {
  display: inline-flex;
  background: #141416;
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 6px;
  padding: 2px;
}

.seg-btn {
  background: transparent;
  border: none;
  color: #AAA;
  padding: 6px 12px;
  font-family: inherit;
  font-size: 13px;
  font-weight: 600;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.12s;
  min-height: 32px;
}

.seg-btn.active {
  background: #38383B;
  color: #FFF;
}

.toggle-label {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  cursor: pointer;
  user-select: none;
}

.toggle-label input[type="checkbox"] {
  accent-color: var(--orange);
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.btn-replay {
  background: var(--orange);
  color: #111;
  border: none;
  font-family: inherit;
  font-size: 14px;
  font-weight: 700;
  padding: 8px 18px;
  border-radius: 6px;
  cursor: pointer;
  transition: transform 0.1s, filter 0.15s;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  min-height: 38px;
  margin-left: auto;
}

.btn-replay:hover {
  filter: brightness(1.1);
}

.btn-replay:active {
  transform: scale(0.97);
}

/* Device Viewport and Frame */
.viewport-container {
  max-width: 1360px;
  margin: 0 auto;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  gap: 32px;
}

.device-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

.device-title {
  font-size: 13px;
  font-weight: 600;
  color: #888;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.ipad-frame {
  background: #0A0A0C;
  border: 4px solid #222225;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.7), 0 0 0 1px rgba(255, 255, 255, 0.08);
  border-radius: 36px;
  padding: 16px;
  position: relative;
  transition: all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1);
}

.ipad-screen {
  background: var(--current-bg);
  color: var(--current-ink);
  border-radius: 20px;
  overflow: hidden;
  position: relative;
  user-select: none;
  cursor: default;
}

/* Landscape: iPad 11" 1194 x 834 */
.ipad-frame.landscape {
  width: 960px;
}

.ipad-frame.landscape .ipad-screen {
  width: 928px;
  height: 648px;
}

/* Portrait: iPad 11" 834 x 1194 */
.ipad-frame.portrait {
  width: 600px;
}

.ipad-frame.portrait .ipad-screen {
  width: 568px;
  height: 813px;
}

/* Side-by-side mode scaling */
.viewport-container.side-by-side {
  max-width: 1560px;
  flex-direction: row;
  align-items: flex-start;
}

.viewport-container.side-by-side .ipad-frame.landscape {
  width: 720px;
}
.viewport-container.side-by-side .ipad-frame.landscape .ipad-screen {
  width: 688px;
  height: 480px;
}

.viewport-container.side-by-side .ipad-frame.portrait {
  width: 440px;
}
.viewport-container.side-by-side .ipad-frame.portrait .ipad-screen {
  width: 408px;
  height: 584px;
}

/* Toast inside iPad */
.ipad-toast {
  position: absolute;
  top: 24px;
  left: 50%;
  transform: translateX(-50%) translateY(-20px);
  background: #111111;
  color: #F2F0EA;
  border: 1px solid var(--orange);
  padding: 8px 18px;
  border-radius: 20px;
  font-size: 15px;
  font-weight: 600;
  z-index: 999;
  opacity: 0;
  pointer-events: none;
  transition: all 0.25s ease;
  white-space: nowrap;
  box-shadow: 0 4px 16px rgba(0,0,0,0.3);
}

.ipad-toast.visible {
  opacity: 1;
  transform: translateX(-50%) translateY(0);
}

.skip-hint {
  position: absolute;
  bottom: 12px;
  right: 16px;
  font-size: 13px;
  color: var(--current-secondary);
  background: var(--current-surface);
  border: 1px solid var(--current-border);
  padding: 4px 10px;
  border-radius: 4px;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.2s;
  z-index: 100;
}

.skip-hint.visible {
  opacity: 0.85;
}

/* Hardware LED status dot */
.led-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
  display: inline-block;
  flex-shrink: 0;
}

.led-dot.green {
  background: #28CD41;
  box-shadow: 0 0 6px #28CD41;
}

.led-dot.amber {
  background: #FF9F0A;
  box-shadow: 0 0 5px #FF9F0A;
}

.tactile-chip {
  font-family: inherit;
  cursor: pointer;
  border: 1px solid var(--current-border);
  background: var(--current-surface);
  color: var(--current-ink);
  min-height: 48px;
  padding: 0 16px;
  border-radius: 6px;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  font-size: 16px;
  font-weight: 600;
  transition: transform 0.08s, filter 0.15s;
}

.tactile-chip:hover {
  filter: brightness(0.96);
}

body.dark-mode .tactile-chip:hover {
  filter: brightness(1.15);
}

.tactile-chip:active {
  transform: translateY(2px);
}

/* Wordmark SVG */
.wordmark-svg {
  display: block;
  fill: currentColor;
}
""".replace("__FONT_B64__", font_b64)

SHARED_JS = """
// Setup interactive state management
let currentOrientation = 'landscape';
let currentPlayerState = 'returning';
let currentAppearance = 'light';
let reduceMotion = false;
let isAnimating = false;
let animationTimers = [];

function showToast(screen, text) {
  const toast = screen.querySelector('.ipad-toast');
  if (!toast) return;
  toast.textContent = text;
  toast.classList.add('visible');
  clearTimeout(toast._timer);
  toast._timer = setTimeout(() => {
    toast.classList.remove('visible');
  }, 2200);
}

function updateStateVisuals() {
  document.querySelectorAll('.ipad-screen').forEach(screen => {
    const isFirstRun = currentPlayerState === 'first-run';
    
    // Primary action button (Pokračovat vs Začít)
    const heroBtn = screen.querySelector('.action-hero');
    if (heroBtn) {
      const heroTitle = heroBtn.querySelector('.hero-title');
      const heroSub = heroBtn.querySelector('.hero-sub');
      const heroStars = heroBtn.querySelector('.hero-stars');
      if (heroTitle) heroTitle.textContent = isFirstRun ? 'Začít' : 'Pokračovat';
      if (heroSub) heroSub.textContent = isFirstRun ? '01 · První úder' : '04 · Funk 16ths';
      if (heroStars) heroStars.textContent = isFirstRun ? '' : '★★★';
    }
    
    // Controller status chip
    const controllerChips = screen.querySelectorAll('.controller-chip');
    controllerChips.forEach(chip => {
      const dot = chip.querySelector('.led-dot');
      const label = chip.querySelector('.controller-label');
      if (dot && label) {
        if (isFirstRun) {
          dot.className = 'led-dot amber';
          label.textContent = 'Připoj ovladač';
        } else {
          dot.className = 'led-dot green';
          label.textContent = 'AKAI MPD218';
        }
      }
    });

    // Overall Progress chip
    const progressTexts = screen.querySelectorAll('.progress-text');
    progressTexts.forEach(el => {
      el.textContent = isFirstRun ? '★ 0 / 216' : '★ 42 / 216';
    });

    const progressSub = screen.querySelectorAll('.progress-sub');
    progressSub.forEach(el => {
      el.textContent = isFirstRun ? '0 z 72 lekcí hotovo' : '14 z 72 lekcí hotovo';
    });
  });
}

function initControls(runAnimationFn, resetFn) {
  // Orientation
  document.querySelectorAll('#orientationPicker .seg-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#orientationPicker .seg-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const mode = btn.dataset.orient;
      currentOrientation = mode;
      const container = document.getElementById('viewportContainer');
      const landscapeWrap = document.getElementById('landscapeWrapper');
      const portraitWrap = document.getElementById('portraitWrapper');

      if (mode === 'landscape') {
        container.className = 'viewport-container';
        landscapeWrap.style.display = 'flex';
        portraitWrap.style.display = 'none';
      } else if (mode === 'portrait') {
        container.className = 'viewport-container';
        landscapeWrap.style.display = 'none';
        portraitWrap.style.display = 'flex';
      } else {
        container.className = 'viewport-container side-by-side';
        landscapeWrap.style.display = 'flex';
        portraitWrap.style.display = 'flex';
      }
    });
  });

  // State
  document.querySelectorAll('#statePicker .seg-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#statePicker .seg-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentPlayerState = btn.dataset.state;
      updateStateVisuals();
    });
  });

  // Appearance
  document.querySelectorAll('#appearancePicker .seg-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('#appearancePicker .seg-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentAppearance = btn.dataset.appearance;
      if (currentAppearance === 'dark') {
        document.body.classList.add('dark-mode');
      } else {
        document.body.classList.remove('dark-mode');
      }
    });
  });

  // Reduce motion
  const reduceToggle = document.getElementById('reduceMotionToggle');
  if (reduceToggle) {
    reduceToggle.addEventListener('change', (e) => {
      reduceMotion = e.target.checked;
    });
  }

  // Replay
  const replayBtn = document.getElementById('replayBtn');
  if (replayBtn) {
    replayBtn.addEventListener('click', () => {
      runAnimationFn();
    });
  }

  // Tap on screen to skip
  document.querySelectorAll('.ipad-screen').forEach(screen => {
    screen.addEventListener('click', (e) => {
      if (isAnimating) {
        skipAnimation(resetFn);
      }
    });
  });
}

function skipAnimation(finishFn) {
  animationTimers.forEach(t => clearTimeout(t));
  animationTimers = [];
  isAnimating = false;
  document.querySelectorAll('.skip-hint').forEach(el => el.classList.remove('visible'));
  if (finishFn) finishFn();
}
"""

def get_header_html(active_tab, title, desc):
    return f"""
    <header class="app-header">
      <div class="title-row">
        <div class="title-group">
          <h1>{title} <span class="badge">Ticket 60</span></h1>
          <p>{desc}</p>
        </div>
        <nav class="nav-tabs" aria-label="Návrhy domovské obrazovky">
          <a href="proposal-a.html" class="nav-tab {'active' if active_tab == 'proposal-a' else ''}">Návrh A (Pady)</a>
          <a href="proposal-b.html" class="nav-tab {'active' if active_tab == 'proposal-b' else ''}">Návrh B (Master řádky)</a>
          <a href="proposal-c.html" class="nav-tab {'active' if active_tab == 'proposal-c' else ''}">Návrh C (Konzole split)</a>
          <a href="index.html" class="nav-tab {'active' if active_tab == 'index' else ''}">Srovnání & Přehled</a>
        </nav>
      </div>

      <div class="controls-panel">
        <div class="control-group">
          <span class="control-label">Orientace:</span>
          <div class="seg-picker" id="orientationPicker">
            <button type="button" class="seg-btn active" data-orient="landscape">Na šířku (Landscape)</button>
            <button type="button" class="seg-btn" data-orient="portrait">Na výšku (Portrait)</button>
            <button type="button" class="seg-btn" data-orient="both">Vedle sebe (Obě)</button>
          </div>
        </div>

        <div class="control-group">
          <span class="control-label">Stav hráče:</span>
          <div class="seg-picker" id="statePicker">
            <button type="button" class="seg-btn active" data-state="returning">Vracející se hráč (Pokračovat)</button>
            <button type="button" class="seg-btn" data-state="first-run">První spuštění (Začít)</button>
          </div>
        </div>

        <div class="control-group">
          <span class="control-label">Vzhled:</span>
          <div class="seg-picker" id="appearancePicker">
            <button type="button" class="seg-btn active" data-appearance="light">Krémový (Světlý)</button>
            <button type="button" class="seg-btn" data-appearance="dark">Černý (Tmavý)</button>
          </div>
        </div>

        <label class="toggle-label">
          <input type="checkbox" id="reduceMotionToggle">
          <span>Omezit pohyb (Reduce Motion)</span>
        </label>

        <button type="button" class="btn-replay" id="replayBtn">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor"><path d="M12 5V1L7 6l5 5V7c3.31 0 6 2.69 6 6s-2.69 6-6 6-6-2.69-6-6H4c0 4.42 3.58 8 8 8s8-3.58 8-8-3.58-8-8-8z"/></svg>
          Přehrát start (Replay)
        </button>
      </div>
    </header>
    """

# Read proposal templates from separate files or generate them cleanly
print("Compiling templates...")

# PROPOSAL A
tmpl_a = """<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Návrh A — Padová matice | Smack-a-Pad iPad</title>
  <style>
__SHARED_CSS__

/* Specific styling for Proposal A */
.screen-content {
  width: 100%;
  height: 100%;
  padding: 32px 36px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  position: relative;
}

.top-chrome {
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 10;
}

.center-hero-group {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  margin: auto;
  z-index: 10;
}

.pads-grid {
  display: grid;
  grid-template-columns: repeat(2, 180px);
  grid-template-rows: repeat(2, 180px);
  gap: 16px;
  position: relative;
}

.ipad-frame.portrait .pads-grid {
  grid-template-columns: repeat(2, 170px);
  grid-template-rows: repeat(2, 170px);
  gap: 14px;
}

.viewport-container.side-by-side .ipad-frame.landscape .pads-grid {
  grid-template-columns: repeat(2, 130px);
  grid-template-rows: repeat(2, 130px);
  gap: 10px;
}

.viewport-container.side-by-side .ipad-frame.portrait .pads-grid {
  grid-template-columns: repeat(2, 120px);
  grid-template-rows: repeat(2, 120px);
  gap: 10px;
}

.pad-unit {
  position: relative;
  border-radius: 12px;
  cursor: pointer;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  padding: 16px;
  user-select: none;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.12);
  transition: transform 0.1s, box-shadow 0.1s, filter 0.12s;
  min-height: 48px;
}

.pad-unit:active {
  transform: scale(0.96) translateY(2px) !important;
}

.pad-black {
  background: #111111;
  color: #F2F0EA;
  border: 2px solid rgba(255, 255, 255, 0.08);
}

body.dark-mode .pad-black {
  background: #F2F0EA;
  color: #111111;
  border: 2px solid rgba(0, 0, 0, 0.1);
}

.pad-orange {
  background: var(--orange);
  color: #111111;
  border: 2px solid rgba(0, 0, 0, 0.15);
  box-shadow: 0 8px 24px rgba(255, 91, 31, 0.35);
}

.pad-tag {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  opacity: 0.75;
}

.pad-title {
  font-size: 22px;
  font-weight: 700;
  line-height: 1.15;
  letter-spacing: -0.01em;
}

.pad-orange .pad-title {
  font-size: 24px;
}

.pad-meta {
  font-size: 14px;
  font-weight: 500;
  opacity: 0.85;
}

.pad-stars {
  font-size: 18px;
  letter-spacing: 2px;
  font-weight: 700;
}

.viewport-container.side-by-side .pad-title {
  font-size: 17px !important;
}
.viewport-container.side-by-side .pad-meta {
  font-size: 12px !important;
}

.wordmark-wrap {
  display: flex;
  justify-content: center;
  align-items: center;
  color: var(--current-ink);
  transition: opacity 0.3s;
}

.wordmark-wrap svg {
  width: 280px;
  height: 42px;
}

.bottom-chrome {
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 10;
}

.about-line {
  font-size: 13px;
  color: var(--current-secondary);
  font-weight: 400;
}

.anim-logo-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  pointer-events: none;
  z-index: 50;
}

.anim-pads-box {
  width: 140px;
  height: 140px;
  position: relative;
}

.anim-pad {
  position: absolute;
  width: 46px;
  height: 46px;
  border-radius: 5px;
}

.anim-pad.p1 { top: 12px; left: 12px; background: #111111; }
.anim-pad.p2 { bottom: 12px; left: 12px; background: #111111; }
.anim-pad.p3 { bottom: 12px; right: 12px; background: #111111; }
.anim-pad.p4 {
  top: 6px;
  right: 6px;
  background: var(--orange);
  transform-origin: 50% 50%;
}

body.dark-mode .anim-pad.p1,
body.dark-mode .anim-pad.p2,
body.dark-mode .anim-pad.p3 {
  background: #F2F0EA;
}

.anim-wordmark {
  width: 220px;
  height: 33px;
  color: var(--current-ink);
}
  </style>
</head>
<body>
__HEADER__

<main class="viewport-container" id="viewportContainer">
  <!-- Landscape View -->
  <div class="device-wrapper" id="landscapeWrapper">
    <div class="device-title">iPad Landscape (1194 × 834)</div>
    <div class="ipad-frame landscape">
      <div class="ipad-screen" id="screenLandscape" role="region" aria-label="Návrh A v orientaci na šířku">
        <div class="ipad-toast" id="toastL">Akce spuštěna</div>
        <div class="skip-hint">Klepnutím přeskočíte animaci</div>

        <!-- Animation Layer -->
        <div class="anim-logo-overlay" id="animOverlayL">
          <div class="anim-pads-box" id="animBoxL">
            <div class="anim-pad p1" id="aL_p1"></div>
            <div class="anim-pad p2" id="aL_p2"></div>
            <div class="anim-pad p3" id="aL_p3"></div>
            <div class="anim-pad p4" id="aL_p4"></div>
          </div>
          <div class="anim-wordmark" id="aL_wordmark">
            <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
          </div>
        </div>

        <!-- Finished Home Screen UI -->
        <div class="screen-content" id="contentL">
          <div class="top-chrome">
            <button type="button" class="tactile-chip controller-chip" id="btnControllerL">
              <span class="led-dot green"></span>
              <span class="controller-label">AKAI MPD218</span>
            </button>
            <button type="button" class="tactile-chip" id="btnProgressL">
              <span class="progress-text">★ 42 / 216</span>
            </button>
          </div>

          <div class="center-hero-group">
            <div class="pads-grid">
              <!-- Top-Left: Knihovna -->
              <div class="pad-unit pad-black" id="btnLibraryL" role="button" tabindex="0">
                <span class="pad-tag">Katalog</span>
                <div>
                  <div class="pad-title">Knihovna</div>
                  <div class="pad-meta">72 lekcí · 5 úrovní</div>
                </div>
              </div>

              <!-- Top-Right: Pokračovat / Začít (Orange Smack Pad) -->
              <div class="pad-unit pad-orange action-hero" id="btnHeroL" role="button" tabindex="0">
                <span class="pad-tag">Další cvičení</span>
                <div>
                  <div class="pad-title hero-title">Pokračovat</div>
                  <div class="pad-meta hero-sub">04 · Funk 16ths</div>
                </div>
                <div class="pad-stars hero-stars">★★★</div>
              </div>

              <!-- Bottom-Left: Úvodní cvičení -->
              <div class="pad-unit pad-black" id="btnIntroL" role="button" tabindex="0">
                <span class="pad-tag">Základy</span>
                <div>
                  <div class="pad-title">Úvodní cvičení</div>
                  <div class="pad-meta">8 cvičení pro start</div>
                </div>
              </div>

              <!-- Bottom-Right: Nastavení -->
              <div class="pad-unit pad-black" id="btnSettingsL" role="button" tabindex="0">
                <span class="pad-tag">Možnosti</span>
                <div>
                  <div class="pad-title">Nastavení</div>
                  <div class="pad-meta">Ovladač, zvuk, odezva</div>
                </div>
              </div>
            </div>

            <div class="wordmark-wrap">
              <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
            </div>
          </div>

          <div class="bottom-chrome">
            <button type="button" class="tactile-chip" id="btnCalibL">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm.5-13H11v6l5.2 3.2.8-1.3-4.5-2.7V7z"/></svg>
              <span>Kalibrace latence (1.2 ms)</span>
            </button>
            <div class="about-line">Smack-a-Pad v1.0 · IBM Plex Sans (OFL)</div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Portrait View -->
  <div class="device-wrapper" id="portraitWrapper" style="display: none;">
    <div class="device-title">iPad Portrait (834 × 1194)</div>
    <div class="ipad-frame portrait">
      <div class="ipad-screen" id="screenPortrait" role="region" aria-label="Návrh A v orientaci na výšku">
        <div class="ipad-toast" id="toastP">Akce spuštěna</div>
        <div class="skip-hint">Klepnutím přeskočíte animaci</div>

        <!-- Animation Layer -->
        <div class="anim-logo-overlay" id="animOverlayP">
          <div class="anim-pads-box" id="animBoxP">
            <div class="anim-pad p1" id="aP_p1"></div>
            <div class="anim-pad p2" id="aP_p2"></div>
            <div class="anim-pad p3" id="aP_p3"></div>
            <div class="anim-pad p4" id="aP_p4"></div>
          </div>
          <div class="anim-wordmark" id="aP_wordmark">
            <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
          </div>
        </div>

        <!-- Finished Home Screen UI -->
        <div class="screen-content" id="contentP">
          <div class="top-chrome">
            <button type="button" class="tactile-chip controller-chip" id="btnControllerP">
              <span class="led-dot green"></span>
              <span class="controller-label">AKAI MPD218</span>
            </button>
            <button type="button" class="tactile-chip" id="btnProgressP">
              <span class="progress-text">★ 42 / 216</span>
            </button>
          </div>

          <div class="center-hero-group">
            <div class="pads-grid">
              <div class="pad-unit pad-black" id="btnLibraryP" role="button" tabindex="0">
                <span class="pad-tag">Katalog</span>
                <div>
                  <div class="pad-title">Knihovna</div>
                  <div class="pad-meta">72 lekcí · 5 úrovní</div>
                </div>
              </div>

              <div class="pad-unit pad-orange action-hero" id="btnHeroP" role="button" tabindex="0">
                <span class="pad-tag">Další cvičení</span>
                <div>
                  <div class="pad-title hero-title">Pokračovat</div>
                  <div class="pad-meta hero-sub">04 · Funk 16ths</div>
                </div>
                <div class="pad-stars hero-stars">★★★</div>
              </div>

              <div class="pad-unit pad-black" id="btnIntroP" role="button" tabindex="0">
                <span class="pad-tag">Základy</span>
                <div>
                  <div class="pad-title">Úvodní cvičení</div>
                  <div class="pad-meta">8 cvičení pro start</div>
                </div>
              </div>

              <div class="pad-unit pad-black" id="btnSettingsP" role="button" tabindex="0">
                <span class="pad-tag">Možnosti</span>
                <div>
                  <div class="pad-title">Nastavení</div>
                  <div class="pad-meta">Ovladač, zvuk, odezva</div>
                </div>
              </div>
            </div>

            <div class="wordmark-wrap">
              <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
            </div>
          </div>

          <div class="bottom-chrome">
            <button type="button" class="tactile-chip" id="btnCalibP">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm.5-13H11v6l5.2 3.2.8-1.3-4.5-2.7V7z"/></svg>
              <span>Kalibrace latence (1.2 ms)</span>
            </button>
            <div class="about-line">Smack-a-Pad v1.0 · IBM Plex Sans (OFL)</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</main>

<script>
__SHARED_JS__

function resetProposalA() {
  document.querySelectorAll('.anim-logo-overlay').forEach(el => el.style.display = 'none');
  document.querySelectorAll('.screen-content').forEach(el => {
    el.style.opacity = '1';
    el.style.pointerEvents = 'auto';
  });
  document.querySelectorAll('.pads-grid').forEach(el => {
    el.style.opacity = '1';
    el.style.transform = 'none';
  });
  document.querySelectorAll('.top-chrome, .bottom-chrome').forEach(el => {
    el.style.opacity = '1';
    el.style.transform = 'none';
  });
}

function runAnimationProposalA() {
  skipAnimation();
  isAnimating = true;

  const screens = document.querySelectorAll('.ipad-screen');
  screens.forEach(s => s.querySelector('.skip-hint')?.classList.add('visible'));

  if (reduceMotion) {
    document.querySelectorAll('.anim-logo-overlay').forEach(el => el.style.display = 'none');
    document.querySelectorAll('.screen-content').forEach(el => {
      el.style.opacity = '0';
      el.style.transition = 'opacity 0.25s ease';
      setTimeout(() => el.style.opacity = '1', 20);
    });
    setTimeout(() => {
      isAnimating = false;
      screens.forEach(s => s.querySelector('.skip-hint')?.classList.remove('visible'));
      resetProposalA();
    }, 270);
    return;
  }

  document.querySelectorAll('.screen-content').forEach(el => {
    el.style.opacity = '0';
    el.style.pointerEvents = 'none';
  });

  document.querySelectorAll('.anim-logo-overlay').forEach(el => {
    el.style.display = 'flex';
    el.style.opacity = '1';
  });

  const prefixes = ['aL_', 'aP_'];
  prefixes.forEach(p => {
    const p1 = document.getElementById(p + 'p1');
    const p2 = document.getElementById(p + 'p2');
    const p3 = document.getElementById(p + 'p3');
    const p4 = document.getElementById(p + 'p4');
    const wm = document.getElementById(p + 'wordmark');

    [p1, p2, p3].forEach(el => {
      if (el) {
        el.style.opacity = '0';
        el.style.transform = 'scale(0.4)';
        el.style.transition = 'none';
      }
    });
    if (p4) {
      p4.style.opacity = '0';
      p4.style.transform = 'translateY(-50px) scale(1.35) rotate(0deg)';
      p4.style.transition = 'none';
    }
    if (wm) {
      wm.style.opacity = '0';
      wm.style.transform = 'translateY(12px)';
      wm.style.transition = 'none';
    }
  });

  // 0.00s: Black Pad 1
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p1');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 50));

  // 0.16s: Black Pad 2
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p2');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 210));

  // 0.32s: Black Pad 3
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p3');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 370));

  // 0.65s: Orange Pad Smack in at 12 deg
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p4');
      if (el) {
        el.style.transition = 'all 0.28s cubic-bezier(0.175, 0.885, 0.32, 1.15)';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0) scale(1) rotate(12deg)';
      }
    });
  }, 700));

  // 0.78s: Bounce on black pads
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      ['p1', 'p2', 'p3'].forEach(k => {
        const el = document.getElementById(p + k);
        if (el) {
          el.style.transition = 'transform 0.08s ease';
          el.style.transform = 'translateY(2px)';
        }
      });
    });
  }, 830));

  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      ['p1', 'p2', 'p3'].forEach(k => {
        const el = document.getElementById(p + k);
        if (el) {
          el.style.transition = 'transform 0.12s ease';
          el.style.transform = 'translateY(0)';
        }
      });
    });
  }, 910));

  // 1.10s: Wordmark rises
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'wordmark');
      if (el) {
        el.style.transition = 'all 0.35s ease-out';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
      }
    });
  }, 1150));

  // 1.60s: Morph & expand logo into Pad Matrix
  animationTimers.push(setTimeout(() => {
    document.querySelectorAll('.anim-logo-overlay').forEach(el => {
      el.style.transition = 'opacity 0.3s ease';
      el.style.opacity = '0';
    });

    document.querySelectorAll('.screen-content').forEach(el => {
      el.style.transition = 'opacity 0.3s ease';
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
    });

    const pads = document.querySelectorAll('.pad-unit');
    pads.forEach((pad, idx) => {
      pad.style.opacity = '0';
      pad.style.transform = 'scale(0.85)';
      setTimeout(() => {
        pad.style.transition = 'all 0.28s cubic-bezier(0.2, 0.8, 0.2, 1)';
        pad.style.opacity = '1';
        pad.style.transform = 'scale(1)';
      }, 100 + idx * 80);
    });

    document.querySelectorAll('.top-chrome, .bottom-chrome').forEach(el => {
      el.style.opacity = '0';
      el.style.transform = 'translateY(-6px)';
      setTimeout(() => {
        el.style.transition = 'all 0.3s ease';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
      }, 450);
    });
  }, 1650));

  // 3.10s: Completed
  animationTimers.push(setTimeout(() => {
    isAnimating = false;
    screens.forEach(s => s.querySelector('.skip-hint')?.classList.remove('visible'));
    resetProposalA();
  }, 3100));
}

document.addEventListener('DOMContentLoaded', () => {
  initControls(runAnimationProposalA, resetProposalA);

  ['L', 'P'].forEach(sfx => {
    const screen = document.getElementById(sfx === 'L' ? 'screenLandscape' : 'screenPortrait');
    
    document.getElementById('btnHero' + sfx)?.addEventListener('click', () => {
      const isFirst = currentPlayerState === 'first-run';
      showToast(screen, isFirst ? '▶ Spouštím lekci 01: První úder' : '▶ Spouštím lekci 04: Funk 16ths');
    });

    document.getElementById('btnLibrary' + sfx)?.addEventListener('click', () => {
      showToast(screen, '📚 Otevírám Knihovnu (LibraryScreen)');
    });

    document.getElementById('btnIntro' + sfx)?.addEventListener('click', () => {
      showToast(screen, '🎓 Otevírám Úvodní cvičení');
    });

    document.getElementById('btnSettings' + sfx)?.addEventListener('click', () => {
      showToast(screen, '⚙ Otevírám Nastavení');
    });

    document.getElementById('btnController' + sfx)?.addEventListener('click', () => {
      showToast(screen, '🎹 Nastavení → MIDI Hardware');
    });

    document.getElementById('btnCalib' + sfx)?.addEventListener('click', () => {
      showToast(screen, '⏱ Nastavení → Kalibrace odezvy');
    });

    document.getElementById('btnProgress' + sfx)?.addEventListener('click', () => {
      showToast(screen, '★ Celkový pokrok: 42 z 216 hvězdiček');
    });
  });

  runAnimationProposalA();
});
</script>
</body>
</html>
"""

# PROPOSAL B
tmpl_b = """<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Návrh B — Master řádky panelu | Smack-a-Pad iPad</title>
  <style>
__SHARED_CSS__

/* Specific styling for Proposal B */
.screen-content {
  width: 100%;
  height: 100%;
  padding: 36px 44px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  position: relative;
}

.ipad-frame.portrait .screen-content {
  padding: 36px 28px;
}

.header-brand-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
  z-index: 10;
}

.brand-lockup {
  display: flex;
  align-items: center;
  gap: 16px;
}

.mini-logo-pads {
  width: 48px;
  height: 48px;
  position: relative;
  flex-shrink: 0;
}

.mini-pad {
  position: absolute;
  width: 16px;
  height: 16px;
  border-radius: 2px;
}

.mini-pad.p1 { top: 4px; left: 4px; background: #111111; }
.mini-pad.p2 { bottom: 4px; left: 4px; background: #111111; }
.mini-pad.p3 { bottom: 4px; right: 4px; background: #111111; }
.mini-pad.p4 {
  top: 2px;
  right: 2px;
  background: var(--orange);
  transform: rotate(12deg);
}

body.dark-mode .mini-pad.p1,
body.dark-mode .mini-pad.p2,
body.dark-mode .mini-pad.p3 {
  background: #F2F0EA;
}

.brand-wordmark svg {
  width: 220px;
  height: 33px;
}

.header-hardware-cluster {
  display: flex;
  align-items: center;
  gap: 12px;
}

.master-rows-container {
  display: flex;
  flex-direction: column;
  gap: 14px;
  width: 100%;
  max-width: 840px;
  margin: auto;
  z-index: 10;
}

.master-row {
  border-radius: 8px;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  user-select: none;
  transition: transform 0.08s, filter 0.15s, box-shadow 0.15s;
  min-height: 48px;
}

.master-row:active {
  transform: translateY(2px) scale(0.99);
}

.hero-master-row {
  background: var(--orange);
  color: #111111;
  min-height: 94px;
  border: 2px solid rgba(0, 0, 0, 0.15);
  box-shadow: 0 6px 20px rgba(255, 91, 31, 0.3);
  position: relative;
  overflow: hidden;
}

.hero-left {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.hero-tag {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  opacity: 0.8;
}

.hero-title {
  font-size: 28px;
  font-weight: 700;
  line-height: 1.1;
  letter-spacing: -0.02em;
}

.hero-sub {
  font-size: 17px;
  font-weight: 500;
}

.hero-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.hero-stars {
  font-size: 22px;
  letter-spacing: 3px;
  font-weight: 700;
}

.hero-bpm {
  background: #111111;
  color: #F2F0EA;
  padding: 4px 10px;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 600;
}

.row-arrow {
  font-size: 26px;
  font-weight: 700;
}

.standard-master-row {
  background: var(--current-surface);
  color: var(--current-ink);
  min-height: 74px;
  border: 1px solid var(--current-border);
}

.row-left {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.row-title {
  font-size: 22px;
  font-weight: 700;
  letter-spacing: -0.01em;
}

.row-sub {
  font-size: 15px;
  color: var(--current-secondary);
  font-weight: 500;
}

.dual-master-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 14px;
}

.split-row {
  background: var(--current-surface);
  color: var(--current-ink);
  border: 1px solid var(--current-border);
  min-height: 70px;
  border-radius: 8px;
  padding: 0 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  cursor: pointer;
  transition: transform 0.08s, filter 0.15s;
}

.split-row:active {
  transform: translateY(2px);
}

.footer-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 10;
}

.anim-logo-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  pointer-events: none;
  z-index: 50;
}

.anim-pads-box {
  width: 140px;
  height: 140px;
  position: relative;
}

.anim-pad {
  position: absolute;
  width: 46px;
  height: 46px;
  border-radius: 5px;
}

.anim-pad.p1 { top: 12px; left: 12px; background: #111111; }
.anim-pad.p2 { bottom: 12px; left: 12px; background: #111111; }
.anim-pad.p3 { bottom: 12px; right: 12px; background: #111111; }
.anim-pad.p4 {
  top: 6px;
  right: 6px;
  background: var(--orange);
  transform-origin: 50% 50%;
}

body.dark-mode .anim-pad.p1,
body.dark-mode .anim-pad.p2,
body.dark-mode .anim-pad.p3 {
  background: #F2F0EA;
}

.anim-wordmark {
  width: 220px;
  height: 33px;
  color: var(--current-ink);
}
  </style>
</head>
<body>
__HEADER__

<main class="viewport-container" id="viewportContainer">
  <!-- Landscape View -->
  <div class="device-wrapper" id="landscapeWrapper">
    <div class="device-title">iPad Landscape (1194 × 834)</div>
    <div class="ipad-frame landscape">
      <div class="ipad-screen" id="screenLandscape" role="region" aria-label="Návrh B v orientaci na šířku">
        <div class="ipad-toast" id="toastL">Akce spuštěna</div>
        <div class="skip-hint">Klepnutím přeskočíte animaci</div>

        <!-- Animation Layer -->
        <div class="anim-logo-overlay" id="animOverlayL">
          <div class="anim-pads-box" id="animBoxL">
            <div class="anim-pad p1" id="bL_p1"></div>
            <div class="anim-pad p2" id="bL_p2"></div>
            <div class="anim-pad p3" id="bL_p3"></div>
            <div class="anim-pad p4" id="bL_p4"></div>
          </div>
          <div class="anim-wordmark" id="bL_wordmark">
            <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
          </div>
        </div>

        <!-- Content -->
        <div class="screen-content" id="contentL">
          <div class="header-brand-row">
            <div class="brand-lockup">
              <div class="mini-logo-pads">
                <div class="mini-pad p1"></div>
                <div class="mini-pad p2"></div>
                <div class="mini-pad p3"></div>
                <div class="mini-pad p4"></div>
              </div>
              <div class="brand-wordmark">
                <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
              </div>
            </div>

            <div class="header-hardware-cluster">
              <button type="button" class="tactile-chip controller-chip" id="btnControllerL">
                <span class="led-dot green"></span>
                <span class="controller-label">AKAI MPD218</span>
              </button>
              <button type="button" class="tactile-chip" id="btnCalibL">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm.5-13H11v6l5.2 3.2.8-1.3-4.5-2.7V7z"/></svg>
                <span>Kalibrace (1.2 ms)</span>
              </button>
              <button type="button" class="tactile-chip" id="btnProgressL">
                <span class="progress-text">★ 42 / 216</span>
              </button>
            </div>
          </div>

          <div class="master-rows-container">
            <!-- Row 1: Hero Practice (Continue / Start) -->
            <div class="master-row hero-master-row action-hero" id="btnHeroL" role="button" tabindex="0">
              <div class="hero-left">
                <span class="hero-tag">Doporučené pokračování</span>
                <div class="hero-title">Pokračovat</div>
                <div class="hero-sub">04 · Funk 16ths</div>
              </div>
              <div class="hero-right">
                <div class="hero-stars">★★★</div>
                <div class="hero-bpm">96 BPM</div>
                <div class="row-arrow">→</div>
              </div>
            </div>

            <!-- Row 2: Library -->
            <div class="master-row standard-master-row" id="btnLibraryL" role="button" tabindex="0">
              <div class="row-left">
                <div class="row-title">Knihovna lekcí</div>
                <div class="row-sub">Všechny úrovně a žánry · 72 cvičení ve 3 zobrazeních</div>
              </div>
              <div class="row-arrow">→</div>
            </div>

            <!-- Row 3: Dual Action Grid (Intro + Settings) -->
            <div class="dual-master-grid">
              <div class="split-row" id="btnIntroL" role="button" tabindex="0">
                <div class="row-left">
                  <div class="row-title" style="font-size: 19px;">Úvodní cvičení</div>
                  <div class="row-sub">8 cvičení pro nováčky</div>
                </div>
                <div class="row-arrow" style="font-size: 20px;">→</div>
              </div>

              <div class="split-row" id="btnSettingsL" role="button" tabindex="0">
                <div class="row-left">
                  <div class="row-title" style="font-size: 19px;">Nastavení</div>
                  <div class="row-sub">MIDI, zvuk, odezva, vzhled</div>
                </div>
                <div class="row-arrow" style="font-size: 20px;">→</div>
              </div>
            </div>
          </div>

          <div class="footer-row">
            <div class="progress-sub" style="font-size: 14px; color: var(--current-secondary);">14 z 72 lekcí hotovo</div>
            <div class="about-line">Smack-a-Pad v1.0 · Trénink prstového bubnování pro iPad · IBM Plex Sans (OFL)</div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Portrait View -->
  <div class="device-wrapper" id="portraitWrapper" style="display: none;">
    <div class="device-title">iPad Portrait (834 × 1194)</div>
    <div class="ipad-frame portrait">
      <div class="ipad-screen" id="screenPortrait" role="region" aria-label="Návrh B v orientaci na výšku">
        <div class="ipad-toast" id="toastP">Akce spuštěna</div>
        <div class="skip-hint">Klepnutím přeskočíte animaci</div>

        <!-- Animation Layer -->
        <div class="anim-logo-overlay" id="animOverlayP">
          <div class="anim-pads-box" id="animBoxP">
            <div class="anim-pad p1" id="bP_p1"></div>
            <div class="anim-pad p2" id="bP_p2"></div>
            <div class="anim-pad p3" id="bP_p3"></div>
            <div class="anim-pad p4" id="bP_p4"></div>
          </div>
          <div class="anim-wordmark" id="bP_wordmark">
            <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
          </div>
        </div>

        <!-- Content -->
        <div class="screen-content" id="contentP">
          <div class="header-brand-row" style="flex-direction: column; align-items: flex-start; gap: 14px;">
            <div class="brand-lockup">
              <div class="mini-logo-pads">
                <div class="mini-pad p1"></div>
                <div class="mini-pad p2"></div>
                <div class="mini-pad p3"></div>
                <div class="mini-pad p4"></div>
              </div>
              <div class="brand-wordmark">
                <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
              </div>
            </div>

            <div class="header-hardware-cluster" style="width: 100%; justify-content: space-between;">
              <button type="button" class="tactile-chip controller-chip" id="btnControllerP">
                <span class="led-dot green"></span>
                <span class="controller-label">AKAI MPD218</span>
              </button>
              <button type="button" class="tactile-chip" id="btnCalibP">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm.5-13H11v6l5.2 3.2.8-1.3-4.5-2.7V7z"/></svg>
                <span>Kalibrace</span>
              </button>
              <button type="button" class="tactile-chip" id="btnProgressP">
                <span class="progress-text">★ 42 / 216</span>
              </button>
            </div>
          </div>

          <div class="master-rows-container">
            <div class="master-row hero-master-row action-hero" id="btnHeroP" role="button" tabindex="0">
              <div class="hero-left">
                <span class="hero-tag">Doporučené pokračování</span>
                <div class="hero-title">Pokračovat</div>
                <div class="hero-sub">04 · Funk 16ths</div>
              </div>
              <div class="hero-right">
                <div class="hero-stars">★★★</div>
                <div class="hero-bpm">96 BPM</div>
                <div class="row-arrow">→</div>
              </div>
            </div>

            <div class="master-row standard-master-row" id="btnLibraryP" role="button" tabindex="0">
              <div class="row-left">
                <div class="row-title">Knihovna lekcí</div>
                <div class="row-sub">Všechny úrovně a žánry · 72 cvičení</div>
              </div>
              <div class="row-arrow">→</div>
            </div>

            <div class="dual-master-grid">
              <div class="split-row" id="btnIntroP" role="button" tabindex="0">
                <div class="row-left">
                  <div class="row-title" style="font-size: 19px;">Úvodní cvičení</div>
                  <div class="row-sub">8 lekcí pro nováčky</div>
                </div>
                <div class="row-arrow" style="font-size: 20px;">→</div>
              </div>

              <div class="split-row" id="btnSettingsP" role="button" tabindex="0">
                <div class="row-left">
                  <div class="row-title" style="font-size: 19px;">Nastavení</div>
                  <div class="row-sub">MIDI, zvuk, vzhled</div>
                </div>
                <div class="row-arrow" style="font-size: 20px;">→</div>
              </div>
            </div>
          </div>

          <div class="footer-row">
            <div class="progress-sub" style="font-size: 14px; color: var(--current-secondary);">14 z 72 lekcí hotovo</div>
            <div class="about-line">Smack-a-Pad v1.0 · IBM Plex Sans (OFL)</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</main>

<script>
__SHARED_JS__

function resetProposalB() {
  document.querySelectorAll('.anim-logo-overlay').forEach(el => el.style.display = 'none');
  document.querySelectorAll('.screen-content').forEach(el => {
    el.style.opacity = '1';
    el.style.pointerEvents = 'auto';
  });
  document.querySelectorAll('.master-row, .split-row').forEach(el => {
    el.style.opacity = '1';
    el.style.transform = 'none';
  });
}

function runAnimationProposalB() {
  skipAnimation();
  isAnimating = true;

  const screens = document.querySelectorAll('.ipad-screen');
  screens.forEach(s => s.querySelector('.skip-hint')?.classList.add('visible'));

  if (reduceMotion) {
    document.querySelectorAll('.anim-logo-overlay').forEach(el => el.style.display = 'none');
    document.querySelectorAll('.screen-content').forEach(el => {
      el.style.opacity = '0';
      el.style.transition = 'opacity 0.25s ease';
      setTimeout(() => el.style.opacity = '1', 20);
    });
    setTimeout(() => {
      isAnimating = false;
      screens.forEach(s => s.querySelector('.skip-hint')?.classList.remove('visible'));
      resetProposalB();
    }, 270);
    return;
  }

  document.querySelectorAll('.screen-content').forEach(el => {
    el.style.opacity = '0';
    el.style.pointerEvents = 'none';
  });

  document.querySelectorAll('.anim-logo-overlay').forEach(el => {
    el.style.display = 'flex';
    el.style.opacity = '1';
    el.style.transform = 'none';
  });

  const prefixes = ['bL_', 'bP_'];
  prefixes.forEach(p => {
    const p1 = document.getElementById(p + 'p1');
    const p2 = document.getElementById(p + 'p2');
    const p3 = document.getElementById(p + 'p3');
    const p4 = document.getElementById(p + 'p4');
    const wm = document.getElementById(p + 'wordmark');

    [p1, p2, p3].forEach(el => {
      if (el) {
        el.style.opacity = '0';
        el.style.transform = 'scale(0.4)';
        el.style.transition = 'none';
      }
    });
    if (p4) {
      p4.style.opacity = '0';
      p4.style.transform = 'translateY(-50px) scale(1.35) rotate(0deg)';
      p4.style.transition = 'none';
    }
    if (wm) {
      wm.style.opacity = '0';
      wm.style.transform = 'translateY(12px)';
      wm.style.transition = 'none';
    }
  });

  // 0.00s-0.45s: 3 black pads pop
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p1');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 50));

  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p2');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 210));

  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p3');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 370));

  // 0.65s: Orange smack pad lands
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p4');
      if (el) {
        el.style.transition = 'all 0.28s cubic-bezier(0.175, 0.885, 0.32, 1.15)';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0) scale(1) rotate(12deg)';
      }
    });
  }, 700));

  // 0.78s: Bounce
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      ['p1', 'p2', 'p3'].forEach(k => {
        const el = document.getElementById(p + k);
        if (el) {
          el.style.transition = 'transform 0.08s ease';
          el.style.transform = 'translateY(2px)';
        }
      });
    });
  }, 830));

  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      ['p1', 'p2', 'p3'].forEach(k => {
        const el = document.getElementById(p + k);
        if (el) {
          el.style.transition = 'transform 0.12s ease';
          el.style.transform = 'translateY(0)';
        }
      });
    });
  }, 910));

  // 1.10s: Wordmark
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'wordmark');
      if (el) {
        el.style.transition = 'all 0.35s ease-out';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
      }
    });
  }, 1150));

  // 1.55s: Glide up into Header and reveal master rows
  animationTimers.push(setTimeout(() => {
    document.querySelectorAll('.anim-logo-overlay').forEach(el => {
      el.style.transition = 'all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1)';
      el.style.opacity = '0';
      el.style.transform = 'translate(-35%, -35%) scale(0.6)';
    });

    document.querySelectorAll('.screen-content').forEach(el => {
      el.style.transition = 'opacity 0.3s ease';
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
    });

    const rows = document.querySelectorAll('.master-row, .split-row');
    rows.forEach((row, idx) => {
      row.style.opacity = '0';
      row.style.transform = 'translateY(20px)';
      setTimeout(() => {
        row.style.transition = 'all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1)';
        row.style.opacity = '1';
        row.style.transform = 'translateY(0)';
      }, 120 + idx * 90);
    });
  }, 1600));

  // 3.10s: Settle
  animationTimers.push(setTimeout(() => {
    isAnimating = false;
    screens.forEach(s => s.querySelector('.skip-hint')?.classList.remove('visible'));
    resetProposalB();
  }, 3100));
}

document.addEventListener('DOMContentLoaded', () => {
  initControls(runAnimationProposalB, resetProposalB);

  ['L', 'P'].forEach(sfx => {
    const screen = document.getElementById(sfx === 'L' ? 'screenLandscape' : 'screenPortrait');
    
    document.getElementById('btnHero' + sfx)?.addEventListener('click', () => {
      const isFirst = currentPlayerState === 'first-run';
      showToast(screen, isFirst ? '▶ Spouštím lekci 01: První úder' : '▶ Spouštím lekci 04: Funk 16ths');
    });

    document.getElementById('btnLibrary' + sfx)?.addEventListener('click', () => {
      showToast(screen, '📚 Otevírám Knihovnu lekcí');
    });

    document.getElementById('btnIntro' + sfx)?.addEventListener('click', () => {
      showToast(screen, '🎓 Otevírám Úvodní cvičení');
    });

    document.getElementById('btnSettings' + sfx)?.addEventListener('click', () => {
      showToast(screen, '⚙ Otevírám Nastavení');
    });

    document.getElementById('btnController' + sfx)?.addEventListener('click', () => {
      showToast(screen, '🎹 Nastavení → MIDI Hardware');
    });

    document.getElementById('btnCalib' + sfx)?.addEventListener('click', () => {
      showToast(screen, '⏱ Nastavení → Kalibrace latence');
    });

    document.getElementById('btnProgress' + sfx)?.addEventListener('click', () => {
      showToast(screen, '★ Celkový pokrok: 42 z 216 hvězdiček');
    });
  });

  runAnimationProposalB();
});
</script>
</body>
</html>
"""

# PROPOSAL C
tmpl_c = """<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Návrh C — Studio Console Split | Smack-a-Pad iPad</title>
  <style>
__SHARED_CSS__

/* Specific styling for Proposal C */
.screen-content {
  width: 100%;
  height: 100%;
  padding: 32px 36px;
  position: relative;
}

.split-layout {
  display: grid;
  grid-template-columns: 320px 1fr;
  gap: 32px;
  height: 100%;
}

.ipad-frame.portrait .split-layout {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.station-column {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  border-right: 1px solid var(--current-border);
  padding-right: 24px;
}

.ipad-frame.portrait .station-column {
  border-right: none;
  border-bottom: 1px solid var(--current-border);
  padding-right: 0;
  padding-bottom: 16px;
  gap: 16px;
}

.station-top {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.brand-unit {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.brand-pads-row {
  width: 52px;
  height: 52px;
  position: relative;
}

.brand-pad {
  position: absolute;
  width: 17px;
  height: 17px;
  border-radius: 3px;
}

.brand-pad.p1 { top: 4px; left: 4px; background: #111111; }
.brand-pad.p2 { bottom: 4px; left: 4px; background: #111111; }
.brand-pad.p3 { bottom: 4px; right: 4px; background: #111111; }
.brand-pad.p4 {
  top: 2px;
  right: 2px;
  background: var(--orange);
  transform: rotate(12deg);
}

body.dark-mode .brand-pad.p1,
body.dark-mode .brand-pad.p2,
body.dark-mode .brand-pad.p3 {
  background: #F2F0EA;
}

.brand-unit svg {
  width: 230px;
  height: 35px;
}

.hardware-monitor-card {
  background: var(--current-surface);
  border: 1px solid var(--current-border);
  border-radius: 8px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.card-label {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--current-secondary);
}

.hw-status-row {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 17px;
  font-weight: 700;
}

.hw-detail {
  font-size: 13px;
  color: var(--current-secondary);
}

.hw-actions {
  display: flex;
  gap: 8px;
  margin-top: 4px;
}

.hw-btn {
  background: transparent;
  border: 1px solid var(--current-border);
  color: var(--current-ink);
  font-family: inherit;
  font-size: 13px;
  font-weight: 600;
  padding: 6px 12px;
  border-radius: 4px;
  cursor: pointer;
  min-height: 48px;
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.progress-box {
  background: var(--current-surface);
  border: 1px solid var(--current-border);
  border-radius: 8px;
  padding: 14px 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.progress-val {
  font-size: 22px;
  font-weight: 700;
  letter-spacing: -0.01em;
}

.dispatch-column {
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  gap: 16px;
}

.hero-card {
  background: var(--orange);
  color: #111111;
  border-radius: 12px;
  padding: 24px 28px;
  box-shadow: 0 10px 28px rgba(255, 91, 31, 0.35);
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  min-height: 200px;
  cursor: pointer;
  transition: transform 0.08s, filter 0.12s;
  position: relative;
}

.hero-card:active {
  transform: translateY(2px) scale(0.99);
}

.hero-card-top {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
}

.hero-card-meta {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  opacity: 0.8;
}

.hero-card-badge {
  background: #111111;
  color: #F2F0EA;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 13px;
  font-weight: 700;
}

.hero-card-title {
  font-size: 34px;
  font-weight: 700;
  line-height: 1.1;
  letter-spacing: -0.02em;
  margin-top: 4px;
}

.hero-card-lesson {
  font-size: 20px;
  font-weight: 600;
  margin-top: 2px;
}

.hero-card-bottom {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 16px;
}

.hero-card-stats {
  display: flex;
  align-items: center;
  gap: 16px;
  font-size: 16px;
  font-weight: 600;
}

.btn-launch {
  background: #111111;
  color: #F2F0EA;
  border: none;
  font-family: inherit;
  font-size: 16px;
  font-weight: 700;
  padding: 10px 24px;
  border-radius: 6px;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-height: 48px;
}

.action-grid-two {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.action-tile {
  background: var(--current-surface);
  border: 1px solid var(--current-border);
  border-radius: 8px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  cursor: pointer;
  min-height: 110px;
  transition: transform 0.08s, filter 0.15s;
}

.action-tile:active {
  transform: translateY(2px);
}

.tile-title {
  font-size: 22px;
  font-weight: 700;
  letter-spacing: -0.01em;
}

.tile-sub {
  font-size: 14px;
  color: var(--current-secondary);
  font-weight: 500;
  margin-top: 4px;
}

.anim-logo-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 20px;
  pointer-events: none;
  z-index: 50;
}

.anim-pads-box {
  width: 140px;
  height: 140px;
  position: relative;
}

.anim-pad {
  position: absolute;
  width: 46px;
  height: 46px;
  border-radius: 5px;
}

.anim-pad.p1 { top: 12px; left: 12px; background: #111111; }
.anim-pad.p2 { bottom: 12px; left: 12px; background: #111111; }
.anim-pad.p3 { bottom: 12px; right: 12px; background: #111111; }
.anim-pad.p4 {
  top: 6px;
  right: 6px;
  background: var(--orange);
  transform-origin: 50% 50%;
}

body.dark-mode .anim-pad.p1,
body.dark-mode .anim-pad.p2,
body.dark-mode .anim-pad.p3 {
  background: #F2F0EA;
}

.anim-wordmark {
  width: 220px;
  height: 33px;
  color: var(--current-ink);
}
  </style>
</head>
<body>
__HEADER__

<main class="viewport-container" id="viewportContainer">
  <!-- Landscape View -->
  <div class="device-wrapper" id="landscapeWrapper">
    <div class="device-title">iPad Landscape (1194 × 834)</div>
    <div class="ipad-frame landscape">
      <div class="ipad-screen" id="screenLandscape" role="region" aria-label="Návrh C v orientaci na šířku">
        <div class="ipad-toast" id="toastL">Akce spuštěna</div>
        <div class="skip-hint">Klepnutím přeskočíte animaci</div>

        <!-- Animation Layer -->
        <div class="anim-logo-overlay" id="animOverlayL">
          <div class="anim-pads-box" id="animBoxL">
            <div class="anim-pad p1" id="cL_p1"></div>
            <div class="anim-pad p2" id="cL_p2"></div>
            <div class="anim-pad p3" id="cL_p3"></div>
            <div class="anim-pad p4" id="cL_p4"></div>
          </div>
          <div class="anim-wordmark" id="cL_wordmark">
            <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
          </div>
        </div>

        <!-- Content -->
        <div class="screen-content" id="contentL">
          <div class="split-layout">
            <!-- Left: Station Anchor -->
            <div class="station-column">
              <div class="station-top">
                <div class="brand-unit">
                  <div class="brand-pads-row">
                    <div class="brand-pad p1"></div>
                    <div class="brand-pad p2"></div>
                    <div class="brand-pad p3"></div>
                    <div class="brand-pad p4"></div>
                  </div>
                  <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
                </div>

                <div class="hardware-monitor-card">
                  <span class="card-label">Hardware Controller</span>
                  <div class="hw-status-row controller-chip" id="btnControllerL" role="button" tabindex="0">
                    <span class="led-dot green"></span>
                    <span class="controller-label">AKAI MPD218</span>
                  </div>
                  <div class="hw-detail">USB MIDI · 16 Padů · Ch 10</div>
                  <div class="hw-actions">
                    <button type="button" class="hw-btn" id="btnCalibL">
                      <svg width="15" height="15" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm.5-13H11v6l5.2 3.2.8-1.3-4.5-2.7V7z"/></svg>
                      Kalibrace latence
                    </button>
                  </div>
                </div>

                <div class="progress-box" id="btnProgressL" role="button" tabindex="0">
                  <span class="card-label">Celkový pokrok</span>
                  <div class="progress-val progress-text">★ 42 / 216</div>
                  <div class="progress-sub" style="font-size: 13px; color: var(--current-secondary);">14 z 72 lekcí hotovo</div>
                </div>
              </div>

              <div class="station-bottom">
                <button type="button" class="tactile-chip" id="btnSettingsL" style="width: 100%; justify-content: center;">
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/></svg>
                  Nastavení aplikace
                </button>
                <div class="about-line" style="margin-top: 12px; font-size: 12px;">Smack-a-Pad v1.0 · OFL</div>
              </div>
            </div>

            <!-- Right: Action Dispatch -->
            <div class="dispatch-column">
              <!-- Hero Practice Card -->
              <div class="hero-card action-hero" id="btnHeroL" role="button" tabindex="0">
                <div class="hero-card-top">
                  <span class="hero-card-meta">Doporučené cvičení</span>
                  <span class="hero-card-badge">Úroveň 2</span>
                </div>
                <div>
                  <div class="hero-card-title hero-title">Pokračovat</div>
                  <div class="hero-card-lesson hero-sub">04 · Funk 16ths</div>
                </div>
                <div class="hero-card-bottom">
                  <div class="hero-card-stats">
                    <span class="hero-stars" style="font-size: 20px;">★★★</span>
                    <span>96 BPM</span>
                    <span>2 takty</span>
                  </div>
                  <button type="button" class="btn-launch">
                    <span>Spustit lekci</span>
                    <span style="font-size: 18px;">→</span>
                  </button>
                </div>
              </div>

              <!-- Action Grid (Library & Intro) -->
              <div class="action-grid-two">
                <div class="action-tile" id="btnLibraryL" role="button" tabindex="0">
                  <span class="card-label">Katalog</span>
                  <div>
                    <div class="tile-title">Knihovna</div>
                    <div class="tile-sub">Procházet 72 lekcí (Cesta, Žánr, Technika)</div>
                  </div>
                  <div style="font-size: 18px; font-weight: 700; align-self: flex-end;">→</div>
                </div>

                <div class="action-tile" id="btnIntroL" role="button" tabindex="0">
                  <span class="card-label">Startovní balíček</span>
                  <div>
                    <div class="tile-title">Úvodní cvičení</div>
                    <div class="tile-sub">8 základních rytmů, sezení a pravidla</div>
                  </div>
                  <div style="font-size: 18px; font-weight: 700; align-self: flex-end;">→</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>

  <!-- Portrait View -->
  <div class="device-wrapper" id="portraitWrapper" style="display: none;">
    <div class="device-title">iPad Portrait (834 × 1194)</div>
    <div class="ipad-frame portrait">
      <div class="ipad-screen" id="screenPortrait" role="region" aria-label="Návrh C v orientaci na výšku">
        <div class="ipad-toast" id="toastP">Akce spuštěna</div>
        <div class="skip-hint">Klepnutím přeskočíte animaci</div>

        <!-- Animation Layer -->
        <div class="anim-logo-overlay" id="animOverlayP">
          <div class="anim-pads-box" id="animBoxP">
            <div class="anim-pad p1" id="cP_p1"></div>
            <div class="anim-pad p2" id="cP_p2"></div>
            <div class="anim-pad p3" id="cP_p3"></div>
            <div class="anim-pad p4" id="cP_p4"></div>
          </div>
          <div class="anim-wordmark" id="cP_wordmark">
            <svg class="wordmark-svg" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
          </div>
        </div>

        <!-- Content -->
        <div class="screen-content" id="contentP">
          <div class="split-layout">
            <div class="station-column">
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <div class="brand-unit">
                  <svg class="wordmark-svg" style="width: 180px; height: 28px;" viewBox="0 0 490.455 73.8"><path d="__WORDMARK_D__"/></svg>
                </div>
                <button type="button" class="tactile-chip controller-chip" id="btnControllerP">
                  <span class="led-dot green"></span>
                  <span class="controller-label">AKAI MPD218</span>
                </button>
              </div>
              <div style="display: flex; justify-content: space-between; align-items: center;">
                <button type="button" class="tactile-chip" id="btnProgressP">
                  <span class="progress-text">★ 42 / 216</span>
                </button>
                <button type="button" class="tactile-chip" id="btnSettingsP">
                  ⚙ Nastavení
                </button>
              </div>
            </div>

            <div class="dispatch-column">
              <div class="hero-card action-hero" id="btnHeroP" role="button" tabindex="0">
                <div class="hero-card-top">
                  <span class="hero-card-meta">Doporučené cvičení</span>
                  <span class="hero-card-badge">Úroveň 2</span>
                </div>
                <div>
                  <div class="hero-card-title hero-title">Pokračovat</div>
                  <div class="hero-card-lesson hero-sub">04 · Funk 16ths</div>
                </div>
                <div class="hero-card-bottom">
                  <div class="hero-card-stats">
                    <span class="hero-stars" style="font-size: 20px;">★★★</span>
                    <span>96 BPM</span>
                  </div>
                  <button type="button" class="btn-launch">
                    <span>Spustit lekci</span>
                    <span>→</span>
                  </button>
                </div>
              </div>

              <div class="action-grid-two">
                <div class="action-tile" id="btnLibraryP" role="button" tabindex="0">
                  <span class="card-label">Katalog</span>
                  <div>
                    <div class="tile-title">Knihovna</div>
                    <div class="tile-sub">72 lekcí</div>
                  </div>
                  <div style="font-size: 18px; font-weight: 700; align-self: flex-end;">→</div>
                </div>

                <div class="action-tile" id="btnIntroP" role="button" tabindex="0">
                  <span class="card-label">Základy</span>
                  <div>
                    <div class="tile-title">Úvodní cvičení</div>
                    <div class="tile-sub">8 cvičení</div>
                  </div>
                  <div style="font-size: 18px; font-weight: 700; align-self: flex-end;">→</div>
                </div>
              </div>

              <div style="text-align: center; margin-top: 10px;">
                <button type="button" class="tactile-chip" id="btnCalibP">
                  ⏱ Kalibrace latence (1.2 ms)
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</main>

<script>
__SHARED_JS__

function resetProposalC() {
  document.querySelectorAll('.anim-logo-overlay').forEach(el => el.style.display = 'none');
  document.querySelectorAll('.screen-content').forEach(el => {
    el.style.opacity = '1';
    el.style.pointerEvents = 'auto';
  });
  document.querySelectorAll('.hero-card, .action-tile, .hardware-monitor-card, .progress-box').forEach(el => {
    el.style.opacity = '1';
    el.style.transform = 'none';
  });
}

function runAnimationProposalC() {
  skipAnimation();
  isAnimating = true;

  const screens = document.querySelectorAll('.ipad-screen');
  screens.forEach(s => s.querySelector('.skip-hint')?.classList.add('visible'));

  if (reduceMotion) {
    document.querySelectorAll('.anim-logo-overlay').forEach(el => el.style.display = 'none');
    document.querySelectorAll('.screen-content').forEach(el => {
      el.style.opacity = '0';
      el.style.transition = 'opacity 0.25s ease';
      setTimeout(() => el.style.opacity = '1', 20);
    });
    setTimeout(() => {
      isAnimating = false;
      screens.forEach(s => s.querySelector('.skip-hint')?.classList.remove('visible'));
      resetProposalC();
    }, 270);
    return;
  }

  document.querySelectorAll('.screen-content').forEach(el => {
    el.style.opacity = '0';
    el.style.pointerEvents = 'none';
  });

  document.querySelectorAll('.anim-logo-overlay').forEach(el => {
    el.style.display = 'flex';
    el.style.opacity = '1';
    el.style.transform = 'none';
  });

  const prefixes = ['cL_', 'cP_'];
  prefixes.forEach(p => {
    const p1 = document.getElementById(p + 'p1');
    const p2 = document.getElementById(p + 'p2');
    const p3 = document.getElementById(p + 'p3');
    const p4 = document.getElementById(p + 'p4');
    const wm = document.getElementById(p + 'wordmark');

    [p1, p2, p3].forEach(el => {
      if (el) {
        el.style.opacity = '0';
        el.style.transform = 'scale(0.4)';
        el.style.transition = 'none';
      }
    });
    if (p4) {
      p4.style.opacity = '0';
      p4.style.transform = 'translateY(-50px) scale(1.35) rotate(0deg)';
      p4.style.transition = 'none';
    }
    if (wm) {
      wm.style.opacity = '0';
      wm.style.transform = 'translateY(12px)';
      wm.style.transition = 'none';
    }
  });

  // 0.00s-0.45s: 3 black pads pop
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p1');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 50));

  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p2');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 210));

  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p3');
      if (el) {
        el.style.transition = 'all 0.22s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
        el.style.opacity = '1';
        el.style.transform = 'scale(1)';
      }
    });
  }, 370));

  // 0.65s: Orange smack pad lands
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'p4');
      if (el) {
        el.style.transition = 'all 0.28s cubic-bezier(0.175, 0.885, 0.32, 1.15)';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0) scale(1) rotate(12deg)';
      }
    });
  }, 700));

  // 0.78s: Bounce
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      ['p1', 'p2', 'p3'].forEach(k => {
        const el = document.getElementById(p + k);
        if (el) {
          el.style.transition = 'transform 0.08s ease';
          el.style.transform = 'translateY(2px)';
        }
      });
    });
  }, 830));

  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      ['p1', 'p2', 'p3'].forEach(k => {
        const el = document.getElementById(p + k);
        if (el) {
          el.style.transition = 'transform 0.12s ease';
          el.style.transform = 'translateY(0)';
        }
      });
    });
  }, 910));

  // 1.10s: Wordmark
  animationTimers.push(setTimeout(() => {
    prefixes.forEach(p => {
      const el = document.getElementById(p + 'wordmark');
      if (el) {
        el.style.transition = 'all 0.35s ease-out';
        el.style.opacity = '1';
        el.style.transform = 'translateY(0)';
      }
    });
  }, 1150));

  // 1.55s: Transition to Split Console
  animationTimers.push(setTimeout(() => {
    document.querySelectorAll('.anim-logo-overlay').forEach(el => {
      el.style.transition = 'all 0.4s cubic-bezier(0.2, 0.8, 0.2, 1)';
      el.style.opacity = '0';
      el.style.transform = 'translate(-30%, 0) scale(0.65)';
    });

    document.querySelectorAll('.screen-content').forEach(el => {
      el.style.transition = 'opacity 0.3s ease';
      el.style.opacity = '1';
      el.style.pointerEvents = 'auto';
    });

    const heroCards = document.querySelectorAll('.hero-card');
    heroCards.forEach(c => {
      c.style.opacity = '0';
      c.style.transform = 'translateX(24px)';
      setTimeout(() => {
        c.style.transition = 'all 0.35s cubic-bezier(0.2, 0.8, 0.2, 1)';
        c.style.opacity = '1';
        c.style.transform = 'translateX(0)';
      }, 100);
    });

    const tiles = document.querySelectorAll('.action-tile');
    tiles.forEach((t, idx) => {
      t.style.opacity = '0';
      t.style.transform = 'translateY(16px)';
      setTimeout(() => {
        t.style.transition = 'all 0.3s cubic-bezier(0.2, 0.8, 0.2, 1)';
        t.style.opacity = '1';
        t.style.transform = 'translateY(0)';
      }, 240 + idx * 80);
    });

    const stationCards = document.querySelectorAll('.hardware-monitor-card, .progress-box');
    stationCards.forEach(sc => {
      sc.style.opacity = '0';
      sc.style.transform = 'translateY(12px)';
      setTimeout(() => {
        sc.style.transition = 'all 0.3s ease';
        sc.style.opacity = '1';
        sc.style.transform = 'translateY(0)';
      }, 320);
    });
  }, 1600));

  // 3.10s: Settle
  animationTimers.push(setTimeout(() => {
    isAnimating = false;
    screens.forEach(s => s.querySelector('.skip-hint')?.classList.remove('visible'));
    resetProposalC();
  }, 3100));
}

document.addEventListener('DOMContentLoaded', () => {
  initControls(runAnimationProposalC, resetProposalC);

  ['L', 'P'].forEach(sfx => {
    const screen = document.getElementById(sfx === 'L' ? 'screenLandscape' : 'screenPortrait');
    
    document.getElementById('btnHero' + sfx)?.addEventListener('click', () => {
      const isFirst = currentPlayerState === 'first-run';
      showToast(screen, isFirst ? '▶ Spouštím lekci 01: První úder' : '▶ Spouštím lekci 04: Funk 16ths');
    });

    document.getElementById('btnLibrary' + sfx)?.addEventListener('click', () => {
      showToast(screen, '📚 Otevírám Knihovnu lekcí');
    });

    document.getElementById('btnIntro' + sfx)?.addEventListener('click', () => {
      showToast(screen, '🎓 Otevírám Úvodní cvičení');
    });

    document.getElementById('btnSettings' + sfx)?.addEventListener('click', () => {
      showToast(screen, '⚙ Otevírám Nastavení');
    });

    document.getElementById('btnController' + sfx)?.addEventListener('click', () => {
      showToast(screen, '🎹 Nastavení → MIDI Hardware');
    });

    document.getElementById('btnCalib' + sfx)?.addEventListener('click', () => {
      showToast(screen, '⏱ Nastavení → Kalibrace latence');
    });

    document.getElementById('btnProgress' + sfx)?.addEventListener('click', () => {
      showToast(screen, '★ Celkový pokrok: 42 z 216 hvězdiček');
    });
  });

  runAnimationProposalC();
});
</script>
</body>
</html>
"""

# INDEX
tmpl_index = """<!doctype html>
<html lang="cs">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Smack-a-Pad — Přehled návrhů domovské obrazovky (Ticket 60)</title>
  <style>
__SHARED_CSS__

.overview-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 24px;
  max-width: 1360px;
  margin: 0 auto 36px;
}

@media (max-width: 1000px) {
  .overview-grid {
    grid-template-columns: 1fr;
  }
}

.concept-card {
  background: #202022;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: transform 0.15s, border-color 0.15s, box-shadow 0.15s;
}

.concept-card:hover {
  border-color: var(--orange);
  transform: translateY(-4px);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.5);
}

.concept-card.recommended {
  border: 2px solid var(--orange);
}

.card-header {
  padding: 20px 24px 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.card-badge-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.card-title {
  font-size: 22px;
  font-weight: 700;
  color: #FFF;
}

.card-tagline {
  font-size: 14px;
  color: #AAA;
  margin-top: 4px;
}

.card-body {
  padding: 20px 24px;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-desc {
  font-size: 15px;
  color: #DDD;
  line-height: 1.5;
}

.card-features {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 14px;
  color: #BBB;
}

.card-features li {
  display: flex;
  align-items: flex-start;
  gap: 8px;
}

.card-features li::before {
  content: "■";
  color: var(--orange);
  font-size: 10px;
  margin-top: 5px;
}

.card-footer {
  padding: 16px 24px;
  background: #18181A;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.btn-open {
  display: block;
  text-align: center;
  background: var(--orange);
  color: #111;
  text-decoration: none;
  font-weight: 700;
  font-size: 15px;
  padding: 12px;
  border-radius: 6px;
  transition: filter 0.15s, transform 0.1s;
}

.btn-open:hover {
  filter: brightness(1.1);
}

.btn-open:active {
  transform: scale(0.98);
}

.comparison-section {
  max-width: 1360px;
  margin: 0 auto;
  background: #202022;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 12px;
  padding: 28px;
}

.section-title {
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 20px;
  color: #FFF;
}

.comp-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 15px;
}

.comp-table th, .comp-table td {
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.comp-table th {
  color: #888;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.comp-table tr:hover td {
  background: rgba(255, 255, 255, 0.02);
}
  </style>
</head>
<body>
__HEADER__

<main>
  <div class="overview-grid">
    <!-- Concept A -->
    <div class="concept-card">
      <div class="card-header">
        <div class="card-badge-row">
          <span class="badge" style="background: #3A3A3D; color: #FFF;">Návrh A</span>
          <span style="font-size: 13px; color: #888;">Interaktivní logo</span>
        </div>
        <div class="card-title">Padová matice</div>
        <div class="card-tagline">"The logo is the menu"</div>
      </div>
      <div class="card-body">
        <p class="card-desc">
          Čtyři pady z loga Smack-a-Pad se přímo v animaci zvětší a stanou se čtyřmi hlavními akčními pady domovské obrazovky:
          oranžový "smack" pad = Pokračovat/Začít, tři černé pady = Knihovna, Úvodní cvičení, Nastavení.
        </p>
        <ul class="card-features">
          <li><strong>Gesto:</strong> Z animace se stává menu — žádný fade out, logo je samotné menu.</li>
          <li><strong>Pocit:</strong> Sedíte u reálného MPC padového ovladače; stačí klepnout na oranžový pad.</li>
          <li><strong>Status:</strong> Ovladač (LED dot) a pokrok decentně usazeny na okrajích.</li>
        </ul>
      </div>
      <div class="card-footer">
        <a href="proposal-a.html" class="btn-open">Otevřít Návrh A (Pady) →</a>
      </div>
    </div>

    <!-- Concept B -->
    <div class="concept-card recommended">
      <div class="card-header">
        <div class="card-badge-row">
          <span class="badge">Doporučený</span>
          <span style="font-size: 13px; color: var(--orange); font-weight: 600;">Návrh B</span>
        </div>
        <div class="card-title">Master řádky panelu</div>
        <div class="card-tagline">"Hardware Front Panel"</div>
      </div>
      <div class="card-body">
        <p class="card-desc">
          Čistý industriální hardware panel. Logo se usadí nahoře a pod ním se rozvine vertikální sada masivních typografických řádků (výška 94 pt a 74 pt) s perfektní hierarchií a obřím oranžovým akčním řádkem Pokračovat.
        </p>
        <ul class="card-features">
          <li><strong>Ergonomie:</strong> Maximální čitelnost z 2 metrů v šeru studia (iPad vedle bicích padů).</li>
          <li><strong>Rychlost:</strong> Okamžitý úder na obří řádek Pokračovat s hvězdami a BPM.</li>
          <li><strong>Hardware:</strong> Integrovaný stavový čip ovladače s LED diodou a přímou kalibrací latence.</li>
        </ul>
      </div>
      <div class="card-footer">
        <a href="proposal-b.html" class="btn-open">Otevřít Návrh B (Master řádky) →</a>
      </div>
    </div>

    <!-- Concept C -->
    <div class="concept-card">
      <div class="card-header">
        <div class="card-badge-row">
          <span class="badge" style="background: #3A3A3D; color: #FFF;">Návrh C</span>
          <span style="font-size: 13px; color: #888;">Zónový rozvrh</span>
        </div>
        <div class="card-title">Studio Console Split</div>
        <div class="card-tagline">"Asymmetric Station & Dispatch"</div>
      </div>
      <div class="card-body">
        <p class="card-desc">
          Moderní studiová konzole s asymetrickým rozdělením: Vlevo (40 %) Stanice hráče (velké logo, MIDI hardware karta s latencí, pokrok), vpravo (60 %) velká Hero cvičební karta s tlačítkem Spustit a dlaždice Knihovny a Úvodu.
        </p>
        <ul class="card-features">
          <li><strong>Zónování:</strong> Oddělení "můj hardware a stav" od "co jdu hrát teď".</li>
          <li><strong>Hardware:</strong> Vyhrazená karta pro MIDI kontroler s kanálem a přímým tlačítkem kalibrace.</li>
          <li><strong>Adaptace:</strong> Na výšku se plynule skládá do horního hardware pruhu a dolního herního panelu.</li>
        </ul>
      </div>
      <div class="card-footer">
        <a href="proposal-c.html" class="btn-open">Otevřít Návrh C (Konzole split) →</a>
      </div>
    </div>
  </div>

  <section class="comparison-section">
    <div class="section-title">Srovnání parametrů návrhů</div>
    <table class="comp-table">
      <thead>
        <tr>
          <th>Parametr</th>
          <th>Návrh A (Padová matice)</th>
          <th>Návrh B (Master řádky)</th>
          <th>Návrh C (Studio split)</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>Hlavní myšlenka</strong></td>
          <td>Logo = 4 pady menu</td>
          <td>Typografický hardware rack</td>
          <td>Dvou-zónová studiová konzole</td>
        </tr>
        <tr>
          <td><strong>Primární akce (Pokračovat / Začít)</strong></td>
          <td>Oranžový smack pad (180×180 pt)</td>
          <td>Oranžový master řádek (výška 94 pt)</td>
          <td>Velká Hero practice karta (výška 150 pt)</td>
        </tr>
        <tr>
          <td><strong>Zobrazení lekce a hvězd</strong></td>
          <td>Přímo na těle oranžového padu</td>
          <td>Uvnitř hero řádku s BPM a šipkou</td>
          <td>Uvnitř hero karty s takty a BPM</td>
        </tr>
        <tr>
          <td><strong>Stav MIDI ovladače</strong></td>
          <td>Taktilní čip v horní liště (LED)</td>
          <td>Hardware čip u loga s LED diodou</td>
          <td>Samostatná karta v levém sloupci</td>
        </tr>
        <tr>
          <td><strong>Zkratka kalibrace latence</strong></td>
          <td>Spodní lišta (min 48 pt)</td>
          <td>Horní hardware lišta (min 48 pt)</td>
          <td>Přímo v hardware kartě ovladače</td>
        </tr>
        <tr>
          <td><strong>Celkový čas animace</strong></td>
          <td>3.1 sekundy</td>
          <td>3.1 sekundy</td>
          <td>3.2 sekundy</td>
        </tr>
        <tr>
          <td><strong>Reduce Motion varianta</strong></td>
          <td>0.25 s fade-in hotového stavu</td>
          <td>0.25 s fade-in hotového stavu</td>
          <td>0.25 s fade-in hotového stavu</td>
        </tr>
        <tr>
          <td><strong>Doporučení pozadí</strong></td>
          <td colspan="3" style="text-align: center; color: var(--orange); font-weight: 600;">
            Krémové (#F2F0EA) v obou režimech — 100% kontinuita se startem bez probliknutí a pocit šasi nástroje.
          </td>
        </tr>
      </tbody>
    </table>
  </section>
</main>
</body>
</html>
"""

def render(tmpl, active_tab, title, desc):
    h = get_header_html(active_tab, title, desc)
    res = tmpl.replace("__SHARED_CSS__", SHARED_CSS)
    res = res.replace("__SHARED_JS__", SHARED_JS)
    res = res.replace("__HEADER__", h)
    res = res.replace("__WORDMARK_D__", wordmark_d)
    return res

print("Generating proposal-a.html...")
(DEST / "proposal-a.html").write_text(render(tmpl_a, 'proposal-a', 'Návrh A — Padová matice', 'Čtyři pady loga se stávají čtyřmi hlavními akcemi na domovské obrazovce.'), encoding="utf-8")

print("Generating proposal-b.html...")
(DEST / "proposal-b.html").write_text(render(tmpl_b, 'proposal-b', 'Návrh B — Master řádky panelu', 'Čitelný typografický rack s velkými řádky akcí. Vynikající čitelnost na vzdálenost paže od iPadu.'), encoding="utf-8")

print("Generating proposal-c.html...")
(DEST / "proposal-c.html").write_text(render(tmpl_c, 'proposal-c', 'Návrh C — Studio Console Split', 'Asymetrický dvou-sloupcový split: Vlevo hardware stanice a stav, vpravo hero practice akce a knihovna.'), encoding="utf-8")

print("Generating index.html...")
(DEST / "index.html").write_text(render(tmpl_index, 'index', 'Smack-a-Pad — Přehled tří návrhů domovské obrazovky', 'Ticket 60: Návrhy konceptů bez zásahu do kódu aplikace. Jakub vybírá řešení pro implementační ticket 61.'), encoding="utf-8")

print("Writing README.md...")
readme_content = """# Smack-a-Pad — Home Screen Design Proposals (Ticket 60)

Status: proposals ready for Jakub's decision. Source: Jakub, 2026-11-03. Follow-up: ticket 61 (implementation) is written after Jakub chooses a proposal.

> [!NOTE]
> This ticket delivers **design proposals and interactive offline previews only**. No application code, asset catalogs, or project settings have been modified.

---

## 1. Quick Review Links

Open any of these files directly in your web browser locally (no web server, no network connection required; font is embedded, SVGs are self-contained):

| File | Concept | Tagline | Main Tradeoff & Character |
|---|---|---|---|
| [**index.html**](index.html) | **Srovnání & Přehled** | Comparative Workbench | Side-by-side parameter comparison and direct links to all three proposals. |
| [**proposal-a.html**](proposal-a.html) | **Návrh A / Padová matice** | "The logo is the menu" | The 4 pads of the logo expand to become the 4 main tactile buttons: Orange Smack Pad = Pokračovat/Začít, 3 Black Pads = Knihovna, Úvodní cvičení, Nastavení. |
| [**proposal-b.html**](proposal-b.html) | **Návrh B / Master řádky** | "Hardware Front Panel" | *(Recommended)* Industrial rack layout. Logo sits proud at the top; massive, left-aligned typographic action rows (height 94 pt and 74 pt) give immediate legibility from arm's length. |
| [**proposal-c.html**](proposal-c.html) | **Návrh C / Studio Console Split** | "Asymmetric Station & Dispatch" | Two-column split (40% Station / 60% Action Dispatch) in landscape; stacked in portrait. Dedicated MIDI controller hardware monitor with latency calibration. |

Every preview includes:
- **Landscape (1194×834)**, **Portrait (834×1194)**, and **Side-by-Side (Obě)** orientation switcher.
- **Returning Player** (Pokračovat · 04 · Funk 16ths · ★★★ · Akai MPD218) vs **First Run** (Začít · 01 · První úder · Připoj ovladač).
- **Light (Cream #F2F0EA)** vs **Dark (Black #111111)** appearance switcher.
- **Reduce Motion** toggle (smooth 0.25 s crossfade, zero motion).
- **Replay** button to re-run cold start sequence from the empty cream launch screen.
- **Tap anywhere on screen to skip** immediately to the settled home screen.
- **Tactile feedback toasts** when tapping any button, showing what action is triggered in the app.

---

## 2. Storyboards with Timings

Total animation time until the menu is fully usable is **3.1–3.2 s** (stretched calmly from ticket 46's 1.6 s). Menu items become tappable as soon as they appear.

### Universal Launch Sequence (First 1.5 s)

All three proposals share the exact cold-start build sequence established in ticket 46, ensuring brand continuity from the solid cream `#F2F0EA` launch screen:

| Time | Action | Visual details |
|---|---|---|
| **0.00–0.05 s** | Static start | Empty cream screen `#F2F0EA` (matches static launch screen, zero flash). |
| **0.05–0.45 s** | Three black pads pop | Pad 1 (top-left) pops at 0.05 s, Pad 2 (bottom-left) at 0.21 s, Pad 3 (bottom-right) at 0.37 s. Spring scale 0.4 → 1.0, opacity 0 → 1. |
| **0.65–0.78 s** | Orange pad smacks in | Orange pad drops from above (`offsetY: -50px`, scale 1.35 → 1.0) and settles at 12° with one slight overshoot. |
| **0.78–0.91 s** | Impact bounce | Three black pads give a subtle 2 pt downward bounce upon impact and settle back. |
| **1.10–1.45 s** | Wordmark rises | The outlined vector wordmark "Smack-a-Pad" fades in and rises 12 pt into place below the pads. |

---

### Proposal-Specific Settling & Menu Reveal (1.50–3.10 s)

#### Proposal A: Padová matice (Pad Matrix)
| Time | What happens |
|---|---|
| **1.50–2.20 s** | The 4 pads of the logo expand smoothly in place into large tactile touch pads (180×180 pt each). |
| **2.20–2.70 s** | Labels stagger onto the pads (0.08 s apart): Hero orange pad reveals "POKRAČOVAT" (or "ZAČÍT") + lesson title + stars; top-left reveals "KNIHOVNA"; bottom-left reveals "ÚVODNÍ CVIČENÍ"; bottom-right reveals "NASTAVENÍ". Each is immediately tappable! |
| **2.70–3.10 s** | Top status bar (Controller chip with green LED, Progress chip) and bottom bar (Calibration shortcut, About line) fade in. |
| **3.10 s** | Home screen completely settled. |

#### Proposal B: Master řádky panelu (Hardware Front Panel)
| Time | What happens |
|---|---|
| **1.50–2.00 s** | The assembled logo glides upward and anchors into the top-left brand position, scaling slightly to 0.85. |
| **2.00–2.60 s** | Master action rows slide up from below with crisp ease-out (0.10 s stagger): Row 1 ("POKRAČOVAT", height 94 pt) at 2.00 s; Row 2 ("KNIHOVNA", height 74 pt) at 2.12 s; Row 3 ("ÚVODNÍ CVIČENÍ" & "NASTAVENÍ", height 70 pt) at 2.24 s. |
| **2.60–3.10 s** | Hardware cluster (Controller chip with live LED dot, Latency calibration shortcut, Progress ratio) settles in the header. |
| **3.10 s** | Home screen completely settled. |

#### Proposal C: Studio Console Split
| Time | What happens |
|---|---|
| **1.50–2.10 s** | In landscape: Logo shifts leftward to anchor the Station Column (40% width). In portrait: Shifts upward into top header. |
| **2.10–2.80 s** | Right Action Dispatch column elements slide in from the right: Giant Hero Practice Card (height 150 pt) at 2.10 s; Library and Intro tiles at 2.25 s. |
| **2.60–3.20 s** | Hardware monitor card (Controller status, channel info, calibration button) and Progress card fade in on the Station side. |
| **3.20 s** | Home screen completely settled. |

*Reduce Motion for all proposals*: 0.00–0.25 s smooth opacity crossfade directly from cream to the settled home screen. Zero position or scale movement.

---

## 3. Proposal Profiles & Secondary Items

### Proposal A: Padová matice ("The logo is the menu")
- **Concept**: Maximum brand cohesion. The four pads of the logo are the menu.
- **Secondary items kept**:
  - **Úvodní cvičení**: Elevated to one of the 4 primary pads (bottom-left). Warm-up shortcut for returning players; essential starting point for new players.
  - **Ovladač**: Dedicated tactile chip in top header (`[● AKAI MPD218]` with green LED, or `[○ Připoj ovladač]` with amber LED), height 48 pt. Tapping opens Settings (Hardware section).
  - **Kalibrace**: Direct shortcut chip in bottom bar (`⏱ Kalibrace latence (1.2 ms)`), height 48 pt.
  - **Pokrok**: Quiet stat line in top bar (`★ 42 / 216`).
  - **Plná verze**: Optional chip in bottom utility strip if locked content exists.
  - **O aplikaci**: Quiet one-line footer at bottom right.
- **SwiftUI mapping**:
  ```swift
  // LaunchAnimationView pads morph with matchedGeometryEffect(id:in:) directly into PadButton views
  ```

### Proposal B: Master řádky panelu ("Hardware Front Panel") — *RECOMMENDED*
- **Concept**: Typographic industrial instrument front plate (inspired by Roland, vintage Akai, and Braun). Ultra-clean hierarchy, zero decorative fluff.
- **Secondary items kept**:
  - **Úvodní cvičení**: Integrated as an equal tactile action row alongside Nastavení (height 70 pt).
  - **Ovladač**: Pinned directly beside the brand anchor as a hardware monitor chip with green/amber LED dot.
  - **Kalibrace**: Direct button right next to the controller chip (`⏱ Kalibrace (1.2 ms)`), solving the problem of calibration being buried.
  - **Pokrok**: Progress chip in header (`★ 42 / 216`) plus total completed lessons in footer (`14 z 72 lekcí hotovo`).
  - **Plná verze**: Banner / chip when locked content exists.
  - **O aplikaci**: Subtle footer line at the bottom.
- **SwiftUI mapping**:
  ```swift
  // HomeScreen animates the logo to .topLeading via matchedGeometryEffect, while MasterRow components stagger in via VStack with offset/opacity transitions
  ```

### Proposal C: Studio Console Split ("Asymmetric Station & Dispatch")
- **Concept**: Professional audio workstation layout (similar to Ableton Push or standalone MPC). Distinct zones: "My Station & Setup" on the left vs "Practice & Play Dispatch" on the right.
- **Secondary items kept**:
  - **Úvodní cvičení**: Large dedicated action tile in the dispatch column (height 110 pt).
  - **Ovladač**: Full Hardware Monitor card with device name, connection protocol (USB/Bluetooth), MIDI channel, and embedded calibration button.
  - **Kalibrace**: Prominent button inside the Hardware Monitor card.
  - **Pokrok**: Dedicated card in the Station column with large score (`42 / 216 ★`).
  - **Nastavení**: Dedicated full-width button in the Station column.
  - **O aplikaci**: Footer in the station column.
- **SwiftUI mapping**:
  ```swift
  // Responsive container (HStack in landscape, VStack in portrait) with matchedTransition and spring-animated column reveals
  ```

---

## 4. Background Recommendation: Cream in Both Appearances

Ticket 60 asks to decide and show what the home background is:
1. **Cream in both appearances (`#F2F0EA`)** *(Recommended)*
2. **Adaptive: Cream in light, Black (`#111111`) in dark**

### Why we recommend Cream in both appearances:
1. **Zero-flash continuity from launch**: The static launch screen required by ticket 46 is solid cream `#F2F0EA` in both light and dark modes (to prevent iOS system flashes). The launch animation runs on cream. If the Home screen is cream, the animation settles **seamlessly with zero background shift or crossfade**.
2. **Physical instrument chassis feel**: Vintage and modern hardware instruments (Akai MPC 2000XL, E-mu SP-1200, Roland TR-808) have a distinct physical casing color (cream/beige/grey) with high-contrast pads and orange triggers. The home screen feels like the instrument itself sitting on your desk.
3. **Intentional contrast between "Instrument Home" and "Practice Arena"**: Entering a lesson transitions into the focused dark/light practice arena with the vivid orange playband. This creates an unmistakable psychological shift between app navigation and active playing.
4. **Adaptive Dark Mode is still fully supported**: For users who play on dark stages or in dim studios and prefer a fully dark home screen, the dark variant (deep `#111111` background, cream pads `#F2F0EA`, orange smack pad) is completely designed and functional in all our previews (toggle with the "Vzhled" switch).

---

## 5. Recommendation of One Proposal

### **We recommend Proposal B (Master řádky panelu / Hardware Front Panel)**.

**Reasons**:
1. **Ergonomics at arm's length**: The iPad sits on a stand or table beside an external MIDI drum controller. The player's eyes are mostly on the physical drum pads. Proposal B's large, full-width typographic master rows (height 94 pt and 74 pt) are instantly recognizable and operable with a casual glance from 1.5 to 2 meters away.
2. **Unmistakable primary call to action**: The orange "POKRAČOVAT" row is impossible to miss. It clearly presents the next lesson name ("04 · Funk 16ths"), the user's star rating (`★★★`), and tempo (`96 BPM`). On first launch, it seamlessly shifts to "ZAČÍT" ("01 · První úder").
3. **Tactile hardware aesthetic without gimmicks**: Adheres 100% to the anti-slop rules of `DESIGN-BRIEF.md`. No purple glow, no blur cards, no fake 3D, no generic icons. Pure typographic precision using the app's bundled IBM Plex Sans font.
4. **Hardware status clarity**: A finger drummer needs to know immediately whether their MIDI controller is connected. Proposal B places a high-visibility LED chip (`● AKAI MPD218` in green, or `○ Připoj ovladač` in amber) right next to the brand anchor, along with a direct one-tap shortcut to latency calibration.

*Alternative*: If Jakub wants the most playful, iconic brand expression, **Proposal A** is the runner-up because tapping the physical smack pad of the logo to launch practice is uniquely satisfying.

---

## 6. Open Questions for Jakub

1. **Background appearance**: Do you agree with keeping the cream background `#F2F0EA` in both Light and Dark modes on the Home screen (for seamless continuity with the static launch screen and a physical instrument chassis feel), or do you want the Home screen to turn deep black (`#111111`) when dark mode is enabled?
2. **Proposal preference**: Do you prefer the bold typographic rows of **Proposal B**, the direct pad interactivity of **Proposal A**, or the two-column workstation split of **Proposal C**?
3. **Latency calibration shortcut**: All three proposals elevate Latency Calibration to a direct shortcut on the home screen (previously buried in Settings → Hardware). Do you want it always visible, or only when an external controller is connected?
4. **Haptic feedback (iPad)**: When tapping the primary "Pokračovat" or "Začít" button on iPad, should we trigger a tactile impact haptic (`UIImpactFeedbackGenerator(style: .medium)`)?
"""

(DEST / "README.md").write_text(readme_content, encoding="utf-8")
print("All files generated successfully!")
