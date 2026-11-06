# CSS Styles for Smack-a-Pad App-wide Visual Unity Proposal (Ticket 125)

def get_css():
    return r"""
:root {
  --theme-cream: #F4EFE6;
  --theme-soft-black: #1F1D1A;
  --theme-orange: #FF6B00;
  --theme-orange-glow: rgba(255, 107, 0, 0.45);
  --theme-mark-correct: #0a5726;
  --theme-mark-off: #5c4200;
  --theme-mark-wrong: #9e0f1a;

  /* Light Theme (Cream White) */
  --bg: #F4EFE6;
  --ink: #1F1D1A;
  --surface: #EBE5DA;
  --secondary: #5E5950;
  --hairline: rgba(31, 29, 26, 0.15);
  --hairline-strong: rgba(31, 29, 26, 0.28);
  --shadow-color: rgba(0, 0, 0, 0.08);

  /* Chassis Body in Light */
  --body-plastic-grad: linear-gradient(172deg, #F5EFE5 0%, #E8E0D2 100%);
  --body-rib-light: rgba(244, 239, 230, 0.55);
  --body-rib-dark: rgba(31, 29, 26, 0.08);
  --calm-chassis-grad: linear-gradient(175deg, #F2EBE0 0%, #E6DECFA0 100%);

  /* Plate Surface in Light */
  --plate-bg-satin: linear-gradient(165deg, #ECE5DC 0%, #DDD5C8 100%);
  --plate-bg-brushed: linear-gradient(170deg, #E6DFD4 0%, #D5CDC0 38%, #ECE5DC 62%, #DDD5C8 100%);
  --plate-border: rgba(31, 29, 26, 0.18);
  --plate-bevel: inset 0 1.5px 0 rgba(255, 255, 255, 0.85), inset 0 -1.5px 0 rgba(31, 29, 26, 0.2);
  --plate-shadow: 0 6px 24px rgba(0, 0, 0, 0.09), 0 1px 3px rgba(0, 0, 0, 0.06);

  /* Pad Material in Light */
  --pad-bevel-top: rgba(255, 255, 255, 0.65);
  --pad-bevel-bottom: rgba(31, 29, 26, 0.18);
  --pad-well-bg: #DCD6CA;
  --pad-well-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.15), inset 0 0 0 1px rgba(0, 0, 0, 0.04), 0 1px 0 rgba(255, 255, 255, 0.6);

  /* Inset Instrument Display in Light */
  --display-bg: #1A1917;
  --display-glass: linear-gradient(180deg, rgba(255,255,255,0.08) 0%, rgba(0,0,0,0.2) 100%);
  --display-ink: #F4EFE6;
  --display-meta: #A59E92;
  --display-border: rgba(31, 29, 26, 0.35);
  --display-inner-shadow: inset 0 2px 6px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.06);

  /* Screws in Light */
  --screw-rim-stroke: rgba(31, 29, 26, 0.32);
  --screw-socket-fill: #2B2925;
  --screw-socket-highlight: rgba(255, 255, 255, 0.6);

  /* Faders in Light */
  --fader-slot-bg: #1A1816;
  --fader-slot-border: rgba(31, 29, 26, 0.22);
  --fader-slot-highlight: rgba(255, 255, 255, 0.65);
  --fader-slot-line: rgba(255, 255, 255, 0.18);
  --fader-cap-bg: linear-gradient(180deg, #F3ECE2 0%, #D7D0C5 48%, #C5BEB2 52%, #DFD8CC 100%);
  --fader-cap-border: rgba(31, 29, 26, 0.32);
  --fader-cap-shadow: 0 4px 8px rgba(0, 0, 0, 0.22), inset 0 1px 0 rgba(255, 255, 255, 0.75), inset 0 -1px 0 rgba(0, 0, 0, 0.25);
  --fader-rib: rgba(31, 29, 26, 0.28);
  --fader-indicator: #1F1D1A;

  /* Star colors */
  --star-off: #D6D0C4;
}

[data-theme="dark"] {
  /* Dark Theme (Warm Soft Black) */
  --bg: #1F1D1A;
  --ink: #F4EFE6;
  --surface: #2A2824;
  --secondary: #B3ADA2;
  --hairline: rgba(244, 239, 230, 0.15);
  --hairline-strong: rgba(244, 239, 230, 0.28);
  --shadow-color: rgba(0, 0, 0, 0.45);

  /* Chassis Body in Dark */
  --body-plastic-grad: linear-gradient(172deg, #24221E 0%, #171513 100%);
  --body-rib-light: rgba(255, 255, 255, 0.06);
  --body-rib-dark: rgba(0, 0, 0, 0.45);
  --calm-chassis-grad: linear-gradient(175deg, #22201C 0%, #191715 100%);

  /* Plate Surface in Dark */
  --plate-bg-satin: linear-gradient(165deg, #272521 0%, #1E1C19 100%);
  --plate-bg-brushed: linear-gradient(170deg, #2C2924 0%, #1D1B18 38%, #312E28 62%, #201E1B 100%);
  --plate-border: rgba(244, 239, 230, 0.18);
  --plate-bevel: inset 0 1.5px 0 rgba(255, 255, 255, 0.24), inset 0 -1.5px 0 rgba(0, 0, 0, 0.7);
  --plate-shadow: 0 6px 24px rgba(0, 0, 0, 0.55), 0 1px 3px rgba(0, 0, 0, 0.35);

  /* Pad Material in Dark */
  --pad-bevel-top: rgba(255, 255, 255, 0.14);
  --pad-bevel-bottom: rgba(0, 0, 0, 0.45);
  --pad-well-bg: #151412;
  --pad-well-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.8), inset 0 0 0 1px rgba(255, 255, 255, 0.04), 0 1px 0 rgba(255, 255, 255, 0.04);

  /* Inset Instrument Display in Dark */
  --display-bg: #121110;
  --display-glass: linear-gradient(180deg, rgba(255,255,255,0.04) 0%, rgba(0,0,0,0.3) 100%);
  --display-ink: #F4EFE6;
  --display-meta: #8A8478;
  --display-border: rgba(0, 0, 0, 0.65);
  --display-inner-shadow: inset 0 2px 6px rgba(0,0,0,0.85), inset 0 0 0 1px rgba(255,255,255,0.04);

  /* Screws in Dark */
  --screw-rim-stroke: rgba(244, 239, 230, 0.22);
  --screw-socket-fill: #0B0A09;
  --screw-socket-highlight: rgba(255, 255, 255, 0.2);

  /* Faders in Dark */
  --fader-slot-bg: #0C0B0A;
  --fader-slot-border: rgba(0, 0, 0, 0.85);
  --fader-slot-highlight: rgba(244, 239, 230, 0.08);
  --fader-slot-line: rgba(244, 239, 230, 0.1);
  --fader-cap-bg: linear-gradient(180deg, #3A3731 0%, #262420 48%, #1D1C18 52%, #2F2C26 100%);
  --fader-cap-border: rgba(0, 0, 0, 0.65);
  --fader-cap-shadow: 0 4px 8px rgba(0, 0, 0, 0.6), inset 0 1px 0 rgba(255, 255, 255, 0.2), inset 0 -1px 0 rgba(0, 0, 0, 0.55);
  --fader-rib: rgba(0, 0, 0, 0.5);
  --fader-indicator: #F4EFE6;

  /* Star colors */
  --star-off: #3E3B36;
}

* {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
  -webkit-font-smoothing: antialiased;
}

body {
  font-family: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, sans-serif;
  background-color: #101012;
  color: #E2E0DB;
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  user-select: none;
}

/* WORKBENCH TOP BAR */
.workbench-header {
  background: #18181B;
  border-bottom: 1px solid #27272A;
  padding: 6px 14px;
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  font-size: 12px;
  flex-shrink: 0;
  z-index: 1000;
}

.brand-cluster {
  display: flex;
  align-items: center;
  gap: 10px;
}

.brand-badge {
  display: flex;
  align-items: center;
  gap: 8px;
  color: #FFF;
  font-weight: 600;
  font-size: 13px;
}

.brand-badge .pill {
  background: #FF6B00;
  color: #1F1D1A;
  font-size: 10.5px;
  font-weight: 700;
  padding: 2px 6px;
  border-radius: 3px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}

.screen-select-wrap {
  display: flex;
  align-items: center;
  gap: 6px;
}

.screen-dropdown {
  background: #27272A;
  border: 1px solid #3F3F46;
  color: #FFF;
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
  padding: 4px 10px;
  border-radius: 4px;
  outline: none;
  cursor: pointer;
}
.screen-dropdown:focus {
  border-color: #FF6B00;
}

.controls-cluster {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
}

.ctrl-btn {
  background: #27272A;
  border: 1px solid #3F3F46;
  color: #E4E4E7;
  padding: 4px 8px;
  border-radius: 3px;
  font-family: inherit;
  font-size: 11px;
  font-weight: 500;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  transition: all 0.15s ease;
}
.ctrl-btn:hover {
  background: #3F3F46;
  color: #FFF;
}
.ctrl-btn.active {
  background: #382A1C;
  border-color: #FF6B00;
  color: #FF6B00;
  font-weight: 600;
}
.ctrl-btn.motion-active {
  background: #1B382B;
  border-color: #00E676;
  color: #00E676;
}

/* VIEWPORT CONTAINER */
.workbench-viewport {
  flex: 1;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 12px;
  overflow: hidden;
  background: radial-gradient(circle at center, #1C1C20 0%, #0E0E10 100%);
  position: relative;
}

/* STAGE & SCALER */
.viewport-stage {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 28px;
}

.chassis-scaler {
  position: relative;
  transform-origin: center center;
  display: flex;
  gap: 24px;
  align-items: center;
  justify-content: center;
}

/* IPAD CHASSIS */
.ipad-chassis {
  background: var(--body-plastic-grad);
  color: var(--ink);
  box-shadow: 0 24px 60px rgba(0,0,0,0.65), 0 0 0 10px #2A2A2E, 0 0 0 12px #1A1A1E;
  border-radius: 28px;
  position: relative;
  overflow: hidden;
  flex-shrink: 0;
  transition: width 0.25s ease, height 0.25s ease;
}

/* Device sizes */
.ipad-chassis.device-11.landscape { width: 1194px; height: 834px; }
.ipad-chassis.device-11.portrait  { width: 834px; height: 1194px; }
.ipad-chassis.device-mini.landscape { width: 1133px; height: 744px; }
.ipad-chassis.device-mini.portrait  { width: 744px; height: 1133px; }
.ipad-chassis.device-10.landscape { width: 1180px; height: 820px; }
.ipad-chassis.device-10.portrait  { width: 820px; height: 1180px; }

/* CHASSIS TEXTURES */
.chassis-ribbing-layer {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 1;
  background-image: repeating-linear-gradient(
    180deg,
    transparent 0px,
    transparent 2px,
    var(--body-rib-light) 2.5px,
    var(--body-rib-dark) 3.5px,
    transparent 4px
  );
  background-size: 100% 4px;
  transition: opacity 0.2s ease;
}

/* Variant B: Calm Satin Background for dense screens */
[data-variant="B"] .chassis-ribbing-layer,
.ipad-chassis.variant-b .chassis-ribbing-layer {
  opacity: 0.05 !important;
}
[data-variant="B"] .ipad-chassis,
.ipad-chassis.variant-b {
  background: var(--calm-chassis-grad);
}

.chassis-speckle-layer {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 2;
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.85' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E");
  background-repeat: repeat;
  background-size: 180px 180px;
  opacity: 0.035;
  mix-blend-mode: multiply;
}
[data-theme="dark"] .chassis-speckle-layer {
  opacity: 0.055;
  mix-blend-mode: overlay;
}

.chassis-vignette {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 3;
  background: radial-gradient(ellipse 80% 75% at 50% 50%, transparent 45%, rgba(0, 0, 0, 0.08) 100%);
}
[data-theme="dark"] .chassis-vignette {
  background: radial-gradient(ellipse 80% 75% at 50% 50%, transparent 45%, rgba(0, 0, 0, 0.35) 100%);
}

.screen-content-layer {
  position: absolute;
  inset: 0;
  z-index: 10;
  display: flex;
  flex-direction: column;
}

/* HARDWARE SURFACES: SMOOTH PLATES */
.hardware-plate {
  background: var(--plate-bg-brushed);
  border: 1px solid var(--plate-border);
  box-shadow: var(--plate-shadow), var(--plate-bevel);
  border-radius: 16px;
  position: relative;
}
.hardware-plate-satin {
  background: var(--plate-bg-satin);
  border: 1px solid var(--plate-border);
  box-shadow: var(--plate-shadow), var(--plate-bevel);
  border-radius: 16px;
  position: relative;
}

/* CORNER SCREWS (18pt) */
.plate-screw {
  position: absolute;
  width: 18px;
  height: 18px;
  pointer-events: none;
  z-index: 30;
}
.plate-screw.tl { top: 9px; left: 9px; transform: rotate(-24deg); }
.plate-screw.tr { top: 9px; right: 9px; transform: rotate(51deg); }
.plate-screw.bl { bottom: 9px; left: 9px; transform: rotate(108deg); }
.plate-screw.br { bottom: 9px; right: 9px; transform: rotate(-63deg); }

.plate-screw svg {
  width: 100%;
  height: 100%;
  display: block;
  filter: drop-shadow(0 1px 1.5px rgba(0,0,0,0.3));
}

/* HARDWARE CONTROLS: PADS & KEYS */
.hw-pad {
  border-radius: 8px;
  background: var(--surface);
  color: var(--ink);
  box-shadow: 0 2px 4px var(--shadow-color);
  border: 1px solid var(--hairline);
  position: relative;
  cursor: pointer;
  user-select: none;
  transition: transform 0.18s cubic-bezier(0.175, 0.885, 0.32, 1.275), background 0.15s;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
}
.hw-pad::before {
  content: "";
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 1.5px;
  background: var(--pad-bevel-top);
  border-top-left-radius: 7px;
  border-top-right-radius: 7px;
  pointer-events: none;
}
.hw-pad::after {
  content: "";
  position: absolute;
  bottom: 0; left: 0; right: 0;
  height: 2px;
  background: var(--pad-bevel-bottom);
  border-bottom-left-radius: 7px;
  border-bottom-right-radius: 7px;
  pointer-events: none;
}

.hw-pad:hover {
  filter: brightness(1.02);
}
.hw-pad:active, .hw-pad.pressed {
  transform: translateY(1.5px) scale(0.965);
}
.hw-pad .flash-overlay {
  position: absolute;
  inset: 0;
  border-radius: 7px;
  background: #FFF;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.06s ease-out;
}
.hw-pad.flashing .flash-overlay {
  opacity: 0.38;
}

/* Hero Orange Pad */
.hw-pad.hero-pad {
  background: var(--theme-orange);
  color: #1F1D1A;
  box-shadow: 0 3px 8px rgba(255, 107, 0, 0.35);
  border-color: rgba(0, 0, 0, 0.15);
}
.hw-pad.hero-pad::before {
  background: rgba(255, 255, 255, 0.42);
}
.hw-pad.hero-pad::after {
  height: 2.5px;
  background: rgba(0, 0, 0, 0.28);
}

/* Pad Well Bed (Zapuštěné lůžko) */
.pad-well {
  background: var(--pad-well-bg);
  box-shadow: var(--pad-well-shadow);
  border-radius: 10px;
  padding: 1.5px;
  display: flex;
  align-items: stretch;
  justify-content: stretch;
}

/* Pad Number Stamp (Vyryté číslo) */
.pad-num-stamp {
  position: absolute;
  top: 7px;
  left: 9px;
  font-size: 9.5px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  color: var(--secondary);
  text-shadow: 0 0.8px 0 rgba(255, 255, 255, 0.45);
  pointer-events: none;
}
[data-theme="dark"] .pad-num-stamp {
  text-shadow: 0 0.8px 0 rgba(255, 255, 255, 0.08);
}
.hero-pad .pad-num-stamp {
  color: #1F1D1A;
  text-shadow: 0 0.8px 0 rgba(255, 255, 255, 0.3);
}

/* Orange Light Bar (Capsule along top edge) */
.light-bar {
  position: absolute;
  top: 6px;
  left: 20%;
  right: 20%;
  height: 2.5px;
  background: var(--theme-orange);
  border-radius: 3px;
  box-shadow: 0 0 6px rgba(255, 107, 0, 0.85);
  pointer-events: none;
}
.light-bar.breathing {
  animation: ledBreath 1.6s ease-in-out infinite alternate;
}
@keyframes ledBreath {
  from { opacity: 0.4; box-shadow: 0 0 3px rgba(255, 107, 0, 0.4); }
  to   { opacity: 1.0; box-shadow: 0 0 8px rgba(255, 107, 0, 0.95); }
}

/* SEGMENTED HARDWARE KEYS (Mode switch row) */
.hw-key-group {
  display: inline-flex;
  background: var(--pad-well-bg);
  box-shadow: var(--pad-well-shadow);
  border-radius: 9px;
  padding: 3px;
  gap: 3px;
}

.hw-key {
  border-radius: 7px;
  background: var(--surface);
  color: var(--secondary);
  border: 1px solid var(--hairline);
  padding: 6px 14px;
  font-size: 13.5px;
  font-weight: 600;
  cursor: pointer;
  position: relative;
  transition: all 0.18s;
  user-select: none;
}
.hw-key::before {
  content: "";
  position: absolute;
  top: 0; left: 0; right: 0; height: 1px;
  background: var(--pad-bevel-top);
  border-radius: 6px 6px 0 0;
}
.hw-key::after {
  content: "";
  position: absolute;
  bottom: 0; left: 0; right: 0; height: 1.5px;
  background: var(--pad-bevel-bottom);
  border-radius: 0 0 6px 6px;
}
.hw-key:active {
  transform: translateY(1px);
}
.hw-key.active {
  color: var(--ink);
  background: var(--surface);
  border-color: var(--theme-orange);
  box-shadow: 0 0 8px rgba(255, 107, 0, 0.25);
}
.hw-key.active .key-light-bar {
  display: block;
}
.key-light-bar {
  display: none;
  position: absolute;
  top: 3px;
  left: 20%;
  right: 20%;
  height: 2px;
  background: var(--theme-orange);
  border-radius: 2px;
  box-shadow: 0 0 5px rgba(255, 107, 0, 0.85);
}

/* HARDWARE ICON BUTTON */
.hw-icon-btn {
  width: 44px;
  height: 44px;
  border-radius: 8px;
  background: var(--surface);
  color: var(--ink);
  border: 1px solid var(--hairline);
  box-shadow: 0 2px 4px var(--shadow-color);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  position: relative;
  font-size: 17px;
  transition: transform 0.15s;
}
.hw-icon-btn::before {
  content: "";
  position: absolute;
  top: 0; left: 0; right: 0; height: 1.5px;
  background: var(--pad-bevel-top);
  border-radius: 7px 7px 0 0;
}
.hw-icon-btn:active {
  transform: translateY(1.5px) scale(0.965);
}
.hw-icon-btn.active {
  border-color: var(--theme-orange);
  color: var(--theme-orange);
  box-shadow: 0 0 6px rgba(255, 107, 0, 0.3);
}

/* INSET INSTRUMENT DISPLAY (BPM & Numbers) */
.instrument-display {
  background: var(--display-bg);
  border: 1.5px solid var(--display-border);
  box-shadow: var(--display-inner-shadow), 0 2px 5px rgba(0,0,0,0.15);
  border-radius: 10px;
  position: relative;
  overflow: hidden;
  color: var(--display-ink);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.instrument-display::before {
  content: "";
  position: absolute;
  top: 0; left: 0; right: 0; height: 45%;
  background: var(--display-glass);
  pointer-events: none;
}
.instrument-display .display-label {
  font-size: 10.5px;
  font-weight: 700;
  letter-spacing: 0.08em;
  color: var(--display-meta);
  text-transform: uppercase;
}
.instrument-display .display-val {
  font-size: 44px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  line-height: 1;
  margin: 3px 0;
  text-shadow: 0 0 10px rgba(244, 239, 230, 0.25);
}
.instrument-display .display-sub {
  font-size: 11px;
  color: var(--display-meta);
  font-variant-numeric: tabular-nums;
}

/* MINI PADS (4x4 Grid in Practice) */
.mini-pad-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 5px;
  background: var(--pad-well-bg);
  box-shadow: var(--pad-well-shadow);
  padding: 6px;
  border-radius: 10px;
}
.mini-pad {
  aspect-ratio: 1;
  border-radius: 4px;
  background: var(--surface);
  border: 1px solid var(--hairline);
  box-shadow: 0 1px 2px rgba(0,0,0,0.12);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-size: 11px;
  font-weight: 700;
  color: var(--secondary);
  cursor: pointer;
  position: relative;
  transition: all 0.15s;
}
.mini-pad::before {
  content: "";
  position: absolute;
  top: 0; left: 0; right: 0; height: 1px;
  background: var(--pad-bevel-top);
  border-radius: 3px 3px 0 0;
}
.mini-pad:active, .mini-pad.hit {
  transform: scale(0.92);
  background: var(--theme-orange);
  color: #1F1D1A;
  box-shadow: 0 0 8px rgba(255, 107, 0, 0.7);
}
.mini-pad.used {
  color: var(--ink);
  font-weight: 800;
  border-color: var(--hairline-strong);
}

/* FADERS & SLIDERS */
.hw-fader-slot {
  position: relative;
  background: var(--fader-slot-bg);
  border: 1px solid var(--fader-slot-border);
  box-shadow: inset 0 2px 5px rgba(0,0,0,0.8), 0 1px 0 var(--fader-slot-highlight);
  border-radius: 3px;
}
.hw-fader-cap {
  position: absolute;
  background: var(--fader-cap-bg);
  border: 1px solid var(--fader-cap-border);
  box-shadow: var(--fader-cap-shadow);
  border-radius: 3px;
  cursor: grab;
  z-index: 10;
}
.hw-fader-indicator {
  position: absolute;
  height: 2px;
  left: 2px;
  right: 2px;
  top: 50%;
  transform: translateY(-50%);
  background: var(--theme-orange);
}

/* VU-METER (8-step LED stack) */
.vu-meter-column {
  display: flex;
  flex-direction: column;
  gap: 3px;
  flex: 1;
}
.vu-seg {
  height: 8px;
  background: var(--star-off);
  border-radius: 1px;
  transition: background 0.15s;
}
.vu-seg.lit {
  background: var(--ink);
}
.vu-seg.lit.orange {
  background: var(--theme-orange);
  box-shadow: 0 0 4px rgba(255, 107, 0, 0.5);
}

/* SCREEN COMPARISON LAYOUT MODES */
.screen-wrapper {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

/* Split view (Home left, Screen right) */
.split-view-container {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 24px;
  height: 100%;
}
.chassis-tag {
  position: absolute;
  top: -24px;
  left: 16px;
  background: #27272A;
  color: #FFF;
  font-size: 11px;
  font-weight: 700;
  padding: 3px 8px;
  border-radius: 4px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  display: flex;
  align-items: center;
  gap: 6px;
}
.chassis-tag .indicator-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #FF6B00;
}

/* GALLERY GRID VIEW */
.gallery-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(420px, 1fr));
  gap: 20px;
  padding: 24px;
  overflow-y: auto;
  max-height: calc(100vh - 60px);
  width: 100%;
}
.gallery-card {
  background: #18181B;
  border: 1px solid #27272A;
  border-radius: 12px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
}
.gallery-card:hover {
  border-color: #FF6B00;
  transform: translateY(-2px);
}
.gallery-card-title {
  font-size: 13px;
  font-weight: 700;
  color: #FFF;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.gallery-card-preview {
  height: 270px;
  background: #121214;
  border-radius: 8px;
  overflow: hidden;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* WORKBENCH UTILITIES & SUB-BAR */
.info-sub-bar {
  background: #121214;
  border-bottom: 1px solid #27272A;
  padding: 7px 18px;
  font-size: 12px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  flex-shrink: 0;
  z-index: 900;
}

.block-tag {
  background: rgba(255, 107, 0, 0.12);
  border: 1px solid rgba(255, 107, 0, 0.35);
  color: #FF6B00;
  font-size: 11px;
  font-weight: 600;
  padding: 2px 7px;
  border-radius: 4px;
  letter-spacing: 0.02em;
  display: inline-block;
}

.stage-chassis-column {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.stage-chassis-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  padding: 0 8px;
  box-sizing: border-box;
}

/* PORTRAIT ADAPTATIONS */
.ipad-chassis.portrait .home-faders-side {
  display: none !important;
}
.ipad-chassis.portrait .home-plate-box {
  top: 42% !important;
}
.ipad-chassis.portrait .home-faders-portrait {
  display: flex !important;
}
.ipad-chassis.landscape .home-faders-portrait {
  display: none !important;
}

"""
