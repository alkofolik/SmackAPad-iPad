#!/usr/bin/env python3
"""
Builder script to generate self-contained docs/design/2026-11-06-app-visual-unity/index.html
"""
import os
import sys

# Ensure local imports work
CURR_DIR = os.path.dirname(os.path.abspath(__file__))
if CURR_DIR not in sys.path:
    sys.path.insert(0, CURR_DIR)

import extracted_assets
import css_styles
import screen_templates
import js_scripts

def build():
    print("Loading styles, fonts and templates...")
    font_css = extracted_assets.FONT_FACE
    styles_css = css_styles.get_css()
    js_code = js_scripts.get_js()

    # Screen templates dictionary mapping
    screens = {
        'home': screen_templates.render_home(),
        'practice_play': screen_templates.render_practice_play(),
        'practice_afterme': screen_templates.render_practice_afterme(),
        'practice_result': screen_templates.render_practice_result(),
        'library': screen_templates.render_library(),
        'training': screen_templates.render_training(),
        'today': screen_templates.render_today(),
        'badges': screen_templates.render_badges(),
        'settings': screen_templates.render_settings(),
        'about': screen_templates.render_about(),
        'purchases': screen_templates.render_purchases(),
        'controller_setup': screen_templates.render_controller_setup(),
        'calibration': screen_templates.render_calibration(),
        'intro': screen_templates.render_intro(),
        'banners': screen_templates.render_banners(),
    }

    # Format templates into JS map
    templates_js_parts = ["window.SP_TEMPLATES = {"]
    for sid, html in screens.items():
        # Escape backticks and dollars for JS template string
        escaped_html = html.replace('\\', '\\\\').replace('`', '\\`').replace('${', '\\${')
        templates_js_parts.append(f"  '{sid}': function() {{ return `{escaped_html}`; }},")
    templates_js_parts.append("};\n")
    templates_js = "\n".join(templates_js_parts)

    html_doc = f"""<!DOCTYPE html>
<html lang="cs" data-theme="light">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>Smack-a-Pad — Návrh jednotného vizuálního jazyka aplikace (Ticket 125)</title>
  <style>
{font_css}
{styles_css}
  </style>
</head>
<body style="margin:0; padding:0; height:100vh; display:flex; flex-direction:column; overflow:hidden; font-family:'IBM Plex Sans', -apple-system, sans-serif;">

  <!-- WORKBENCH HEADER -->
  <header class="workbench-header">
    <div class="brand-cluster">
      <div class="brand-badge">
        <span>SMACK-A-PAD</span>
        <span class="pill">TICKET 125</span>
      </div>
      <span style="color:#71717A; font-size:12px;">|</span>
      <span style="color:#A1A1AA; font-size:12px; font-weight:500;">Návrh jednotného vizuálního jazyka aplikace</span>
    </div>

    <!-- Screen Navigation -->
    <div class="screen-select-wrap">
      <button class="ctrl-btn" id="btn-prev-screen" title="Předchozí obrazovka [Šipka vlevo]">◀</button>
      <select id="screen-select" class="screen-dropdown">
        <!-- Populated dynamically -->
      </select>
      <button class="ctrl-btn" id="btn-next-screen" title="Další obrazovka [Šipka vpravo]">▶</button>
    </div>

    <!-- View & Display Controls -->
    <div class="controls-cluster">
      <!-- View Modes -->
      <div style="display:flex; background:#27272A; border:1px solid #3F3F46; border-radius:4px; padding:2px; gap:2px;">
        <button class="ctrl-btn active" data-view-mode="split" title="Rozděleno: Home etalon vedle vybrané obrazovky [S]">
          <span>◫</span> Home vs Screen [S]
        </button>
        <button class="ctrl-btn" data-view-mode="ab" title="Srovnání: Varianta A (Žebrování) vs Varianta B (Satén) [V]">
          <span>◫</span> Srovnání A / B
        </button>
        <button class="ctrl-btn" data-view-mode="single" title="Samostatná obrazovka">
          <span>◻</span> Detail
        </button>
        <button class="ctrl-btn" data-view-mode="gallery" title="Galerie všech 15 obrazovek">
          <span>☷</span> Galerie (15)
        </button>
      </div>

      <!-- Variant A/B Toggle -->
      <button class="ctrl-btn" id="btn-toggle-variant" title="Přepnout variantu šasi [V]">
        <span style="color:#4CAF50;">B:</span> Klidný satén [V]
      </button>

      <!-- Theme Toggle -->
      <button class="ctrl-btn" id="btn-toggle-theme" title="Přepnout Světlý / Tmavý režim [L]">
        <span style="color:#FF6B00;">●</span> Světlý [L]
      </button>

      <!-- Orientation Toggle -->
      <button class="ctrl-btn" id="btn-toggle-orient" title="Otočit na šířku / na výšku [O]">
        <span>▰</span> Na šířku [O]
      </button>

      <!-- Device Selector -->
      <select id="device-select" class="screen-dropdown" style="padding:3px 6px; font-size:11px;">
        <option value="11" selected>iPad Pro 11"</option>
        <option value="mini">iPad mini</option>
        <option value="10">iPad 10.9"</option>
      </select>

      <!-- Motion Demo Button -->
      <button class="ctrl-btn motion-active" id="btn-play-motion" title="Spustit živé animace [M]">
        <span>⚡</span> Animace [M]
      </button>

      <!-- Zoom Controls -->
      <div style="display:flex; background:#27272A; border:1px solid #3F3F46; border-radius:4px; padding:2px; gap:2px;">
        <button class="ctrl-btn active" data-zoom="fit" title="Přizpůsobit oknu">Fit</button>
        <button class="ctrl-btn" data-zoom="100" title="Skutečná velikost (100%)">100%</button>
        <button class="ctrl-btn" data-zoom="80">80%</button>
        <button class="ctrl-btn" data-zoom="60">60%</button>
      </div>
    </div>
  </header>

  <!-- SUB-BAR / INFO & SHORTCUTS -->
  <div class="info-sub-bar" id="sub-bar">
    <div id="active-screen-info" style="display:flex; flex-direction:column; gap:2px;">
      <!-- Populated dynamically -->
    </div>
    <div style="display:flex; align-items:center; gap:8px; font-size:11px; color:#71717A; white-space:nowrap;">
      <span>Zkratky:</span>
      <kbd style="background:#27272A; border:1px solid #3F3F46; padding:1px 5px; border-radius:3px; color:#E4E4E7;">L</kbd> Téma
      <kbd style="background:#27272A; border:1px solid #3F3F46; padding:1px 5px; border-radius:3px; color:#E4E4E7;">O</kbd> Otočení
      <kbd style="background:#27272A; border:1px solid #3F3F46; padding:1px 5px; border-radius:3px; color:#E4E4E7;">M</kbd> Animace
      <kbd style="background:#27272A; border:1px solid #3F3F46; padding:1px 5px; border-radius:3px; color:#E4E4E7;">V</kbd> Var A/B
      <kbd style="background:#27272A; border:1px solid #3F3F46; padding:1px 5px; border-radius:3px; color:#E4E4E7;">S</kbd> Split
      <kbd style="background:#27272A; border:1px solid #3F3F46; padding:1px 5px; border-radius:3px; color:#E4E4E7;">1-9</kbd> Obrazovky
    </div>
  </div>

  <!-- WORKBENCH VIEWPORT STAGE -->
  <main class="workbench-viewport">
    <div class="viewport-stage" id="viewport-stage">
      <!-- Chassis injected here by JS -->
    </div>
  </main>

  <!-- JAVASCRIPT TEMPLATES & CONTROLLER -->
  <script>
{templates_js}
{js_code}
  </script>
</body>
</html>
"""
    out_path = os.path.join(CURR_DIR, 'index.html')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(html_doc)
    print(f"Successfully generated {out_path} ({len(html_doc):,} bytes)")

if __name__ == '__main__':
    build()
