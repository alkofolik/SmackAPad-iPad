# HTML Templates for all screens in the Smack-a-Pad Visual Unity Proposal (Ticket 125)

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from extracted_assets import WORDMARK_SVG, LOGO_SVG

def get_screw(cls="tl"):
    return f"""
    <div class="plate-screw {cls}">
      <svg viewBox="0 0 24 24" role="img" aria-hidden="true">
        <circle cx="12" cy="12" r="9" fill="url(#screwHeadLight)" class="screw-head" stroke="var(--screw-rim-stroke)" stroke-width="1.2" />
        <rect x="7" y="11" width="10" height="2" rx="0.5" fill="var(--screw-socket-fill)" />
        <line x1="7" y1="13.2" x2="17" y2="13.2" stroke="var(--screw-socket-highlight)" stroke-width="0.8" />
      </svg>
    </div>
    """

def render_home():
    return f"""
    <div class="screen-wrapper home-screen-view" style="position:relative; width:100%; height:100%;">
      <!-- Top Wordmark Band -->
      <div style="position:absolute; top:0; left:0; right:0; height:147px; display:flex; align-items:center; justify-content:center; z-index:10; pointer-events:none;">
        {WORDMARK_SVG}
      </div>

      <!-- Central Bay Plate (540x540) -->
      <div class="hardware-plate home-plate-box" style="position:absolute; top:50%; left:50%; transform:translate(-50%, -50%); width:540px; height:540px; padding:36px; z-index:20;">
        {get_screw("tl")}
        {get_screw("tr")}
        {get_screw("bl")}
        {get_screw("br")}

        <!-- 3x3 Pad Grid (468x468) -->
        <div style="display:grid; grid-template-columns:repeat(3, 146px); grid-template-rows:repeat(3, 146px); gap:15px; width:468px; height:468px;">
          <!-- Pad 1: HERO ORANGE -->
          <div class="pad-well">
            <div class="hw-pad hero-pad" data-pad="1" style="width:100%; height:100%; padding:14px 10px;">
              <span class="pad-num-stamp">01</span>
              <div class="flash-overlay"></div>
              <div style="font-size:20px; font-weight:800; line-height:1.15; margin-bottom:4px;">POKRAČOVAT</div>
              <div style="font-size:12px; font-weight:600; line-height:1.2; opacity:0.9;">2 cvičení · pak nová lekce</div>
            </div>
          </div>

          <!-- Pad 2 -->
          <div class="pad-well">
            <div class="hw-pad" data-pad="2" style="width:100%; height:100%; padding:14px 10px;">
              <span class="pad-num-stamp">02</span>
              <div class="flash-overlay"></div>
              <div style="font-size:18px; font-weight:700; margin-bottom:4px;">KNIHOVNA</div>
              <div style="font-size:12px; color:var(--secondary);">16 lekcí · 2/3 ★</div>
            </div>
          </div>

          <!-- Pad 3: LIT WITH BREATHING LIGHT BAR -->
          <div class="pad-well">
            <div class="hw-pad" data-pad="3" style="width:100%; height:100%; padding:14px 10px; border-color:var(--theme-orange); box-shadow:0 0 10px rgba(255,107,0,0.35);">
              <span class="pad-num-stamp">03</span>
              <div class="light-bar breathing"></div>
              <div class="flash-overlay"></div>
              <div style="font-size:18px; font-weight:700; margin-bottom:4px;">TRÉNINK</div>
              <div style="font-size:12px; color:var(--theme-orange); font-weight:600;">2 k opakování</div>
            </div>
          </div>

          <!-- Pad 4 -->
          <div class="pad-well">
            <div class="hw-pad" data-pad="4" style="width:100%; height:100%; padding:14px 10px;">
              <span class="pad-num-stamp">04</span>
              <div class="flash-overlay"></div>
              <div style="font-size:18px; font-weight:700; margin-bottom:4px;">NASTAVENÍ</div>
              <div style="font-size:12px; color:var(--secondary);">Kity, MIDI, jazyk</div>
            </div>
          </div>

          <!-- Pad 5: LOGO CENTER -->
          <div class="pad-well">
            <div class="hw-pad" style="width:100%; height:100%; cursor:default;">
              {LOGO_SVG}
            </div>
          </div>

          <!-- Pad 6 -->
          <div class="pad-well">
            <div class="hw-pad" data-pad="5" style="width:100%; height:100%; padding:14px 10px;">
              <span class="pad-num-stamp">05</span>
              <div class="flash-overlay"></div>
              <div style="font-size:18px; font-weight:700; margin-bottom:4px;">ODZNAKY</div>
              <div style="font-size:12px; color:var(--secondary);">4 z 16 splněno</div>
            </div>
          </div>

          <!-- Pad 7 -->
          <div class="pad-well">
            <div class="hw-pad" data-pad="6" style="width:100%; height:100%; padding:14px 10px;">
              <span class="pad-num-stamp">06</span>
              <div class="flash-overlay"></div>
              <div style="font-size:18px; font-weight:700; margin-bottom:4px;">KONTROLER</div>
              <div style="font-size:12px; color:var(--secondary);">Akai MPD218</div>
            </div>
          </div>

          <!-- Pad 8 -->
          <div class="pad-well">
            <div class="hw-pad" data-pad="7" style="width:100%; height:100%; padding:14px 10px;">
              <span class="pad-num-stamp">07</span>
              <div class="flash-overlay"></div>
              <div style="font-size:18px; font-weight:700; margin-bottom:4px;">NÁKUPY</div>
              <div style="font-size:12px; color:var(--secondary);">Plná verze</div>
            </div>
          </div>

          <!-- Pad 9 -->
          <div class="pad-well">
            <div class="hw-pad" data-pad="8" style="width:100%; height:100%; padding:14px 10px;">
              <span class="pad-num-stamp">08</span>
              <div class="flash-overlay"></div>
              <div style="font-size:18px; font-weight:700; margin-bottom:4px;">O APLIKACI</div>
              <div style="font-size:12px; color:var(--secondary);">Verze 1.0</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Faders Left & Right (Landscape) -->
      <div class="home-faders-side" style="position:absolute; left:96px; top:50%; transform:translateY(-50%); display:flex; gap:22px; z-index:15;">
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 01</div>
          <div class="hw-fader-slot" style="width:12px; height:200px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:65px;">
              <div class="hw-fader-indicator"></div>
            </div>
          </div>
        </div>
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 02</div>
          <div class="hw-fader-slot" style="width:12px; height:200px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:110px;">
              <div class="hw-fader-indicator"></div>
            </div>
          </div>
        </div>
      </div>

      <div class="home-faders-side" style="position:absolute; right:96px; top:50%; transform:translateY(-50%); display:flex; gap:22px; z-index:15;">
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 03</div>
          <div class="hw-fader-slot" style="width:12px; height:200px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:35px;">
              <div class="hw-fader-indicator" style="background:#FF6B00;"></div>
            </div>
          </div>
        </div>
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 04</div>
          <div class="hw-fader-slot" style="width:12px; height:200px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:145px;">
              <div class="hw-fader-indicator"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Faders Portrait Docked Below Central Plate -->
      <div class="home-faders-portrait" style="display:none; position:absolute; bottom:60px; left:0; right:0; justify-content:center; gap:36px; z-index:15;">
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 01</div>
          <div class="hw-fader-slot" style="width:12px; height:180px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:60px;">
              <div class="hw-fader-indicator"></div>
            </div>
          </div>
        </div>
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 02</div>
          <div class="hw-fader-slot" style="width:12px; height:180px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:105px;">
              <div class="hw-fader-indicator"></div>
            </div>
          </div>
        </div>
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 03</div>
          <div class="hw-fader-slot" style="width:12px; height:180px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:30px;">
              <div class="hw-fader-indicator" style="background:#FF6B00;"></div>
            </div>
          </div>
        </div>
        <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
          <div style="font-size:9.5px; font-weight:700; color:var(--secondary);">CH 04</div>
          <div class="hw-fader-slot" style="width:12px; height:180px;">
            <div class="hw-fader-cap" style="width:34px; height:24px; left:-11px; top:135px;">
              <div class="hw-fader-indicator"></div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """

def render_practice_play():
    return f"""
    <div class="screen-wrapper practice-screen-view" style="padding:24px; display:flex; flex-direction:column; justify-content:space-between; height:100%;">
      <!-- TOP ZONE -->
      <div style="display:flex; align-items:center; justify-content:space-between; gap:16px;">
        <!-- Left: Library Button & Title -->
        <div style="display:flex; align-items:center; gap:16px;">
          <button class="hw-pad" style="flex-direction:row; gap:8px; padding:10px 18px; font-size:16px; font-weight:700;">
            <span style="font-size:16px;">⊞</span> Knihovna
          </button>
          <div>
            <div style="font-size:24px; font-weight:700; line-height:1.2;">Lekce 04 · Hip-hop Funk</div>
            <div style="font-size:14px; color:var(--secondary); display:flex; align-items:center; gap:6px;">
              <span style="letter-spacing:2px;">●●●○○</span> · 2 takty · 96 → 120 BPM
            </div>
          </div>
        </div>

        <!-- Center/Right: Hardware Mode Switch & Tools -->
        <div style="display:flex; align-items:center; gap:14px;">
          <!-- Mode Switch Keys -->
          <div class="hw-key-group">
            <button class="hw-key" data-mode="listen">
              <span class="key-light-bar"></span>Poslech
            </button>
            <button class="hw-key active" data-mode="play">
              <span class="key-light-bar"></span>Hra
            </button>
            <button class="hw-key" data-mode="afterme">
              <span class="key-light-bar"></span>Po mně
            </button>
          </div>

          <!-- Tool Icons in Pad Material -->
          <div style="display:flex; align-items:center; gap:6px;">
            <button class="hw-icon-btn" title="Zpaměti (Ø)">Ø</button>
            <div style="width:1px; height:28px; background:var(--hairline); margin:0 4px;"></div>
            <button class="hw-icon-btn active" title="Statické zobrazení">⊞<span style="font-size:10px; margin-left:2px;">4</span></button>
            <button class="hw-icon-btn" title="Posouvané zobrazení">→</button>
            <div style="width:1px; height:28px; background:var(--hairline); margin:0 4px;"></div>
            <button class="hw-icon-btn" title="Informace o lekci">ⓘ</button>
            <button class="hw-icon-btn" title="Legenda">?</button>
            <button class="hw-icon-btn" title="Nástroje">⚙</button>
          </div>
        </div>
      </div>

      <!-- MIDDLE ZONE: ORANGE PATTERN BAND & HIT TIMING -->
      <div style="flex:1; display:flex; flex-direction:column; justify-content:center; align-items:center; margin:16px 0; position:relative;">
        <!-- Pattern Band Container (Fixed Orange Look) -->
        <div class="pattern-band-wrap" style="width:100%; max-width:1146px; background:#FF6B00; border-radius:12px; padding:14px 20px; box-shadow:0 8px 24px rgba(255,107,0,0.3); position:relative; overflow:hidden;">
          
          <!-- Beat Numbers Bar -->
          <div style="display:grid; grid-template-columns:repeat(8, 1fr); padding-left:70px; margin-bottom:8px; font-size:15px; font-weight:800; color:#1F1D1A; opacity:0.85;">
            <div>1.1</div><div>1.2</div><div>1.3</div><div>1.4</div>
            <div>2.1</div><div>2.2</div><div>2.3</div><div>2.4</div>
          </div>

          <!-- Pattern Grid Rows -->
          <!-- Hi-hat Track -->
          <div style="display:flex; align-items:center; margin-bottom:6px;">
            <div style="width:70px; font-size:13px; font-weight:800; color:#1F1D1A; letter-spacing:0.04em;">HH</div>
            <div style="flex:1; display:grid; grid-template-columns:repeat(8, 1fr); gap:6px;">
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px; box-shadow:0 2px 4px rgba(0,0,0,0.2);">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
            </div>
          </div>

          <!-- Snare Track -->
          <div style="display:flex; align-items:center; margin-bottom:6px;">
            <div style="width:70px; font-size:13px; font-weight:800; color:#1F1D1A; letter-spacing:0.04em;">SN</div>
            <div style="flex:1; display:grid; grid-template-columns:repeat(8, 1fr); gap:6px;">
              <div></div>
              <div class="note-box" style="background:#1F1D1A; color:#FFF; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px; box-shadow:0 2px 4px rgba(0,0,0,0.3);">SN</div>
              <div></div>
              <div></div>
              <div></div>
              <div class="note-box" style="background:#1F1D1A; color:#FFF; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px; box-shadow:0 2px 4px rgba(0,0,0,0.3);">SN</div>
              <div></div>
              <div></div>
            </div>
          </div>

          <!-- Kick Track -->
          <div style="display:flex; align-items:center;">
            <div style="width:70px; font-size:13px; font-weight:800; color:#1F1D1A; letter-spacing:0.04em;">KD</div>
            <div style="flex:1; display:grid; grid-template-columns:repeat(8, 1fr); gap:6px;">
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px; box-shadow:0 2px 4px rgba(0,0,0,0.2);">KD</div>
              <div></div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px; box-shadow:0 2px 4px rgba(0,0,0,0.2);">KD</div>
              <div></div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px; box-shadow:0 2px 4px rgba(0,0,0,0.2);">KD</div>
              <div></div>
              <div></div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px; box-shadow:0 2px 4px rgba(0,0,0,0.2);">KD</div>
            </div>
          </div>

          <!-- Playhead Line -->
          <div class="pattern-playhead" style="position:absolute; top:0; bottom:0; left:280px; width:3px; background:#FFF; box-shadow:0 0 8px #FFF; pointer-events:none;"></div>
        </div>

        <!-- Hit Timing Bar -->
        <div style="width:100%; max-width:840px; margin-top:14px; display:flex; align-items:center; justify-content:space-between; gap:20px; padding:0 10px;">
          <div style="flex:1;">
            <div style="display:flex; justify-content:space-between; font-size:12px; color:var(--secondary); font-weight:600; margin-bottom:4px;">
              <span>Před (-80 ms)</span>
              <span style="color:var(--ink); font-weight:700;">Včas</span>
              <span>Po (+80 ms)</span>
            </div>
            <div style="height:6px; background:var(--pad-well-bg); border-radius:3px; position:relative; overflow:hidden;">
              <div style="position:absolute; left:35%; width:30%; top:0; bottom:0; background:var(--theme-orange); border-radius:2px;"></div>
              <div style="position:absolute; left:51%; top:0; bottom:0; width:4px; background:var(--ink); border-radius:2px;"></div>
            </div>
          </div>
          <div style="font-size:22px; font-weight:800; font-variant-numeric:tabular-nums; min-width:80px; text-align:right;">
            Včas
          </div>
        </div>
      </div>

      <!-- BOTTOM ZONE: 3 HARMONIC MODULE BLOCKS -->
      <div style="display:grid; grid-template-columns:1fr 1fr 1fr; gap:18px; max-width:1146px; margin:0 auto; width:100%;">
        <!-- 1. Mini Pad Grid (Miniature MPC Rubber Pads) -->
        <div class="hardware-plate-satin" style="padding:14px; display:flex; flex-direction:column; align-items:center; justify-content:center; min-height:150px;">
          <div style="font-size:11px; font-weight:700; color:var(--secondary); margin-bottom:8px; text-transform:uppercase; letter-spacing:0.05em;">Rozložení padů (16)</div>
          <div class="mini-pad-grid" style="width:100%; max-width:180px;">
            <div class="mini-pad">TH</div><div class="mini-pad">TL</div><div class="mini-pad">CR</div><div class="mini-pad">RD</div>
            <div class="mini-pad">SH</div><div class="mini-pad">WD</div><div class="mini-pad">CB</div><div class="mini-pad">OH</div>
            <div class="mini-pad used">HH</div><div class="mini-pad">CP</div><div class="mini-pad">RM</div><div class="mini-pad used">HH</div>
            <div class="mini-pad used">KD</div><div class="mini-pad used">SN</div><div class="mini-pad used">SN</div><div class="mini-pad used">KD</div>
          </div>
        </div>

        <!-- 2. BPM Inset Instrument Display -->
        <div class="instrument-display" style="padding:16px; cursor:pointer;" title="Klepnutím změnit tempo">
          <div class="display-label">Tempo skladby</div>
          <div class="display-val bpm-val" style="font-size:52px;">96</div>
          <div class="display-sub">BPM · CÍL: 120</div>
        </div>

        <!-- 3. Hardware Transport Keys (Start & Restart) -->
        <div style="display:flex; flex-direction:column; gap:10px;">
          <button class="hw-pad hero-pad start-btn" style="flex:1; font-size:22px; font-weight:800; display:flex; flex-direction:row; gap:10px;">
            <span style="font-size:20px;">▶</span> ZAČÍT
          </button>
          <button class="hw-pad restart-btn" style="flex:1; font-size:17px; font-weight:700; display:flex; flex-direction:row; gap:8px;">
            <span>↺</span> Znovu
          </button>
        </div>
      </div>
    </div>
    """

def render_practice_afterme():
    return f"""
    <div class="screen-wrapper practice-afterme-view" style="padding:24px; display:flex; flex-direction:column; justify-content:space-between; height:100%;">
      <!-- TOP ZONE -->
      <div style="display:flex; align-items:center; justify-content:space-between; gap:16px;">
        <div style="display:flex; align-items:center; gap:16px;">
          <button class="hw-pad" style="flex-direction:row; gap:8px; padding:10px 18px; font-size:16px; font-weight:700;">
            <span style="font-size:16px;">⊞</span> Knihovna
          </button>
          <div>
            <div style="font-size:24px; font-weight:700;">Lekce 04 · Hip-hop Funk</div>
            <div style="font-size:14px; color:var(--theme-orange); font-weight:600;">Pouze trénink · bez hvězd</div>
          </div>
        </div>

        <div style="display:flex; align-items:center; gap:14px;">
          <div class="hw-key-group">
            <button class="hw-key" data-mode="listen">
              <span class="key-light-bar"></span>Poslech
            </button>
            <button class="hw-key" data-mode="play">
              <span class="key-light-bar"></span>Hra
            </button>
            <button class="hw-key active" data-mode="afterme">
              <span class="key-light-bar"></span>Po mně
            </button>
          </div>
          <button class="hw-icon-btn" title="Informace">ⓘ</button>
          <button class="hw-icon-btn" title="Nástroje">⚙</button>
        </div>
      </div>

      <!-- MIDDLE ZONE: AFTER ME PHASE & BAND -->
      <div style="flex:1; display:flex; flex-direction:column; justify-content:center; align-items:center; margin:16px 0;">
        <!-- Phase Pill Badge -->
        <div style="background:var(--theme-orange); color:#1F1D1A; padding:6px 18px; border-radius:20px; font-weight:800; font-size:15px; margin-bottom:12px; letter-spacing:0.06em; box-shadow:0 0 10px rgba(255,107,0,0.5);">
          ● POSLECH (PŘEDLOHA)
        </div>

        <div class="pattern-band-wrap" style="width:100%; max-width:1146px; background:#FF6B00; border-radius:12px; padding:14px 20px; box-shadow:0 8px 24px rgba(255,107,0,0.3); position:relative; overflow:hidden;">
          <div style="display:grid; grid-template-columns:repeat(8, 1fr); padding-left:70px; margin-bottom:8px; font-size:15px; font-weight:800; color:#1F1D1A; opacity:0.85;">
            <div>1.1</div><div>1.2</div><div>1.3</div><div>1.4</div>
            <div>2.1</div><div>2.2</div><div>2.3</div><div>2.4</div>
          </div>
          <!-- Notes -->
          <div style="display:flex; align-items:center; margin-bottom:6px;">
            <div style="width:70px; font-size:13px; font-weight:800; color:#1F1D1A;">HH</div>
            <div style="flex:1; display:grid; grid-template-columns:repeat(8, 1fr); gap:6px;">
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">HH</div>
            </div>
          </div>
          <div style="display:flex; align-items:center;">
            <div style="width:70px; font-size:13px; font-weight:800; color:#1F1D1A;">KD</div>
            <div style="flex:1; display:grid; grid-template-columns:repeat(8, 1fr); gap:6px;">
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">KD</div>
              <div></div><div></div><div></div>
              <div class="note-box" style="background:#FFF; color:#1F1D1A; height:34px; border-radius:4px; display:flex; align-items:center; justify-content:center; font-weight:800; font-size:12px;">KD</div>
              <div></div><div></div><div></div>
            </div>
          </div>
          <div class="pattern-playhead" style="position:absolute; top:0; bottom:0; left:180px; width:3px; background:#FFF; box-shadow:0 0 8px #FFF;"></div>
        </div>
      </div>

      <!-- BOTTOM ZONE: AFTER ME RESULTS & TRANSPORT -->
      <div style="display:grid; grid-template-columns:2fr 1fr; gap:18px; max-width:1146px; margin:0 auto; width:100%;">
        <!-- After Me Result Card on Smooth Plate -->
        <div class="hardware-plate-satin" style="padding:16px 24px; display:flex; align-items:center; justify-content:space-between; gap:20px;">
          <div>
            <div style="font-size:18px; font-weight:700; margin-bottom:4px;">Režim Po mně</div>
            <div style="font-size:13px; color:var(--secondary);">Poslechni takt z reproduktoru, pak přesně zopakuj.</div>
          </div>
          <div style="display:flex; gap:24px; text-align:right;">
            <div>
              <div style="font-size:11px; color:var(--secondary); text-transform:uppercase;">Poslední odpověď</div>
              <div style="font-size:24px; font-weight:800; color:var(--theme-orange);">94 %</div>
            </div>
            <div>
              <div style="font-size:11px; color:var(--secondary); text-transform:uppercase;">Nejlepší odpověď</div>
              <div style="font-size:24px; font-weight:800; color:var(--ink);">98 %</div>
            </div>
          </div>
        </div>

        <!-- Transport Keys -->
        <div style="display:flex; flex-direction:column; gap:10px;">
          <button class="hw-pad hero-pad" style="flex:1; font-size:20px; font-weight:800;">
            ▶ ZAČÍT CVIČENÍ
          </button>
          <button class="hw-pad" style="flex:1; font-size:16px; font-weight:700;">
            ↺ Znovu
          </button>
        </div>
      </div>
    </div>
    """

def render_practice_result():
    return f"""
    <div class="screen-wrapper practice-result-view" style="padding:24px; display:flex; flex-direction:column; justify-content:space-between; height:100%;">
      <!-- TOP ZONE -->
      <div style="display:flex; align-items:center; justify-content:space-between; gap:16px;">
        <div style="display:flex; align-items:center; gap:16px;">
          <button class="hw-pad" style="flex-direction:row; gap:8px; padding:10px 18px; font-size:16px; font-weight:700;">
            <span style="font-size:16px;">⊞</span> Knihovna
          </button>
          <div>
            <div style="font-size:24px; font-weight:700;">Lekce 04 · Hip-hop Funk</div>
            <div style="font-size:14px; color:var(--secondary);">Cvičení dokončeno · 3 běhy</div>
          </div>
        </div>
        <button class="hw-icon-btn" title="Informace">ⓘ</button>
      </div>

      <!-- MIDDLE ZONE: BAND WITH VERDICTS -->
      <div style="flex:1; display:flex; flex-direction:column; justify-content:center; align-items:center; margin:16px 0;">
        <div class="pattern-band-wrap" style="width:100%; max-width:1146px; background:#FF6B00; border-radius:12px; padding:14px 20px; box-shadow:0 8px 24px rgba(255,107,0,0.3); opacity:0.85;">
          <div style="display:flex; justify-content:space-around; margin-bottom:8px; font-size:13px; font-weight:800; color:#1F1D1A;">
            <span style="background:rgba(255,255,255,0.4); padding:2px 10px; border-radius:4px;">Takt 1: Čistě</span>
            <span style="background:rgba(255,255,255,0.4); padding:2px 10px; border-radius:4px;">Takt 2: Včas</span>
          </div>
          <!-- Dimmed Notes -->
          <div style="display:grid; grid-template-columns:repeat(8, 1fr); gap:6px; opacity:0.7;">
            <div class="note-box" style="background:#FFF; height:24px; border-radius:3px;"></div>
            <div class="note-box" style="background:#1F1D1A; height:24px; border-radius:3px;"></div>
            <div class="note-box" style="background:#FFF; height:24px; border-radius:3px;"></div>
            <div class="note-box" style="background:#1F1D1A; height:24px; border-radius:3px;"></div>
            <div class="note-box" style="background:#FFF; height:24px; border-radius:3px;"></div>
            <div class="note-box" style="background:#1F1D1A; height:24px; border-radius:3px;"></div>
            <div class="note-box" style="background:#FFF; height:24px; border-radius:3px;"></div>
            <div class="note-box" style="background:#1F1D1A; height:24px; border-radius:3px;"></div>
          </div>
        </div>
      </div>

      <!-- BOTTOM ZONE: UNIFIED RESULT CARD PLATE & TRANSPORT -->
      <div style="display:grid; grid-template-columns:2.2fr 1fr; gap:18px; max-width:1146px; margin:0 auto; width:100%;">
        <!-- RESULT CARD PLATE (Smooth Brushed Finish with 4 Corner Screws) -->
        <div class="hardware-plate" style="padding:20px 28px; display:flex; align-items:center; justify-content:space-between; gap:24px;">
          {get_screw("tl")}
          {get_screw("tr")}
          {get_screw("bl")}
          {get_screw("br")}

          <!-- Column 1: Score -->
          <div style="display:flex; flex-direction:column; align-items:flex-start;">
            <div style="font-size:56px; font-weight:800; font-variant-numeric:tabular-nums; line-height:1; color:var(--ink);">
              92 %
            </div>
            <div style="font-size:13px; color:var(--secondary); font-weight:600; margin-top:4px;">Poslední běh</div>
          </div>

          <!-- Divider -->
          <div style="width:1px; height:70px; background:var(--hairline);"></div>

          <!-- Column 2: Stars with StarBurst Award Effect -->
          <div style="display:flex; flex-direction:column; align-items:center;">
            <div style="display:flex; gap:10px; margin-bottom:6px;">
              <!-- Star 1 -->
              <div style="font-size:32px; color:var(--theme-orange); filter:drop-shadow(0 0 6px rgba(255,107,0,0.6));">★</div>
              <!-- Star 2 -->
              <div style="font-size:32px; color:var(--theme-orange); filter:drop-shadow(0 0 6px rgba(255,107,0,0.6));">★</div>
              <!-- Star 3 -->
              <div style="font-size:32px; color:var(--star-off);">☆</div>
            </div>
            <div style="font-size:13px; font-weight:700; color:var(--theme-orange);">Zítra se vrátí k opakování</div>
          </div>

          <!-- Divider -->
          <div style="width:1px; height:70px; background:var(--hairline);"></div>

          <!-- Column 3: Run Summary -->
          <div style="display:flex; flex-direction:column; align-items:flex-start;">
            <div style="font-size:17px; font-weight:700; margin-bottom:2px;">3 běhy · nejlepší 95 %</div>
            <div style="font-size:13px; color:var(--secondary); margin-bottom:6px;">Tempo: 96 BPM</div>
            <button class="hw-key" style="padding:4px 10px; font-size:12px;">Podrobnosti ▾</button>
          </div>
        </div>

        <!-- Right: Transport Action Keys -->
        <div style="display:flex; flex-direction:column; gap:10px;">
          <button class="hw-pad hero-pad" style="flex:1; font-size:20px; font-weight:800; display:flex; flex-direction:row; gap:8px;">
            POKRAČOVAT ➔
          </button>
          <button class="hw-pad" style="flex:1; font-size:16px; font-weight:700; display:flex; flex-direction:row; gap:8px;">
            ↺ Znovu zkusit
          </button>
        </div>
      </div>
    </div>
    """

def render_library():
    return f"""
    <div class="screen-wrapper library-screen-view" style="display:grid; grid-template-columns:320px 1fr; height:100%; overflow:hidden;">
      <!-- SIDEBAR -->
      <div style="border-right:1px solid var(--hairline); padding:20px 16px; display:flex; flex-direction:column; gap:16px; background:var(--plate-bg-satin); overflow-y:auto;">
        
        <!-- Overall Course Progress Box -->
        <div class="hardware-plate" style="padding:14px 16px;">
          <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:700; margin-bottom:6px;">
            <span style="color:var(--secondary);">Celkový postup</span>
            <span style="color:var(--theme-orange); font-variant-numeric:tabular-nums;">38 / 75 ★</span>
          </div>
          <div style="height:6px; background:var(--pad-well-bg); border-radius:3px; overflow:hidden; display:flex;">
            <div style="width:40%; background:var(--theme-orange);"></div>
            <div style="width:20%; background:var(--ink);"></div>
          </div>
          <div style="font-size:11.5px; color:var(--secondary); margin-top:6px;">25 lekcí celkem</div>
        </div>

        <!-- Intro Lessons Row Button -->
        <button class="hw-pad" style="padding:12px 14px; text-align:left; align-items:flex-start;">
          <div style="font-size:15px; font-weight:700;">Úvodní cvičení</div>
          <div style="font-size:12px; color:var(--secondary); margin-top:2px;">6 cvičení · vždy otevřeno</div>
        </button>

        <!-- Segmented Key: Organise by -->
        <div>
          <div style="font-size:11px; font-weight:700; text-transform:uppercase; color:var(--secondary); margin-bottom:6px; padding-left:4px;">Uspořádat podle</div>
          <div class="hw-key-group" style="width:100%; display:grid; grid-template-columns:repeat(3, 1fr);">
            <button class="hw-key active" style="padding:6px 0; text-align:center;"><span class="key-light-bar"></span>Cesta</button>
            <button class="hw-key" style="padding:6px 0; text-align:center;"><span class="key-light-bar"></span>Žánr</button>
            <button class="hw-key" style="padding:6px 0; text-align:center;"><span class="key-light-bar"></span>Technika</button>
          </div>
        </div>

        <!-- Level Group List -->
        <div style="display:flex; flex-direction:column; gap:6px;">
          <div class="hw-pad" style="padding:12px 14px; text-align:left; align-items:flex-start; border-color:var(--theme-orange); background:var(--surface);">
            <div style="display:flex; justify-content:space-between; width:100%; font-size:15px; font-weight:800;">
              <span>Úroveň 1: Základy rytmu</span>
              <span style="color:var(--theme-orange);">12/12 ★</span>
            </div>
            <div style="font-size:12px; color:var(--secondary);">4 lekce · Splněno</div>
          </div>

          <div class="hw-pad" style="padding:12px 14px; text-align:left; align-items:flex-start;">
            <div style="display:flex; justify-content:space-between; width:100%; font-size:15px; font-weight:700;">
              <span>Úroveň 2: Koordinace rukou</span>
              <span>10/18 ★</span>
            </div>
            <div style="font-size:12px; color:var(--secondary);">6 lekcí · Rozpracováno</div>
          </div>

          <div class="hw-pad" style="padding:12px 14px; text-align:left; align-items:flex-start;">
            <div style="display:flex; justify-content:space-between; width:100%; font-size:15px; font-weight:700;">
              <span>Úroveň 3: Osminový hi-hat</span>
              <span>4/15 ★</span>
            </div>
            <div style="font-size:12px; color:var(--secondary);">5 lekcí</div>
          </div>

          <div class="hw-pad" style="padding:12px 14px; text-align:left; align-items:flex-start; opacity:0.6;">
            <div style="display:flex; justify-content:space-between; width:100%; font-size:15px; font-weight:700;">
              <span>Úroveň 4: Synkopy 🔒</span>
              <span>0/15 ★</span>
            </div>
            <div style="font-size:12px; color:var(--secondary);">Zamčeno</div>
          </div>
        </div>
      </div>

      <!-- DETAIL PANE -->
      <div style="padding:24px 32px; display:flex; flex-direction:column; gap:16px; overflow-y:auto;">
        <!-- Top Search and Filter Chips -->
        <div style="display:flex; align-items:center; gap:10px; flex-wrap:wrap;">
          <input type="text" placeholder="🔍 Hledat lekci..." style="background:var(--surface); border:1px solid var(--hairline); color:var(--ink); padding:8px 14px; border-radius:8px; font-family:inherit; font-size:14px; width:220px; outline:none;" />
          <button class="hw-key" style="font-size:13px; padding:6px 12px;">Technika: Vše ▾</button>
          
          <div style="display:flex; gap:6px;">
            <button class="hw-key active" style="font-size:12px; padding:4px 10px;"><span class="key-light-bar"></span>Vše (25)</button>
            <button class="hw-key" style="font-size:12px; padding:4px 10px;">★1 (6)</button>
            <button class="hw-key" style="font-size:12px; padding:4px 10px;">★★2 (5)</button>
            <button class="hw-key" style="font-size:12px; padding:4px 10px;">★★★3 (6)</button>
          </div>
        </div>

        <!-- Section Header with Primary Play Button -->
        <div style="display:flex; align-items:center; justify-content:space-between; margin-top:8px;">
          <div>
            <div style="font-size:26px; font-weight:800;">Úroveň 1 · Základy rytmu</div>
            <div style="font-size:14px; color:var(--secondary);">Postup: 12 z 12 hvězd splněno</div>
          </div>
          <button class="hw-pad hero-pad" style="padding:10px 22px; font-size:16px; font-weight:800; display:flex; flex-direction:row; gap:8px;">
            <span>▶</span> HRÁT DALŠÍ LEKCI
          </button>
        </div>

        <!-- Lesson Modular Cards List -->
        <div style="display:flex; flex-direction:column; gap:10px;">
          <!-- Lesson 1 Card -->
          <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; justify-content:space-between; gap:20px; border-radius:10px;">
            <div style="display:flex; align-items:center; gap:14px;">
              <span style="font-size:20px; color:var(--theme-orange);">●</span>
              <div style="text-align:left;">
                <div style="font-size:18px; font-weight:800;">Lekce 01 · První úder</div>
                <div style="font-size:13px; color:var(--secondary);">Základní · ●○○○○ · 60 → 80 BPM</div>
              </div>
            </div>
            <div style="display:flex; align-items:center; gap:20px;">
              <!-- Mini Strip Preview -->
              <div style="display:flex; gap:3px; background:var(--pad-well-bg); padding:4px 6px; border-radius:4px;">
                <div style="width:8px; height:18px; background:#FFF; border-radius:2px;"></div>
                <div style="width:8px; height:18px; background:transparent;"></div>
                <div style="width:8px; height:18px; background:#FFF; border-radius:2px;"></div>
                <div style="width:8px; height:18px; background:transparent;"></div>
              </div>
              <div style="font-size:20px; color:var(--theme-orange);">★★★</div>
            </div>
          </div>

          <!-- Lesson 2 Card (Due for review) -->
          <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; justify-content:space-between; gap:20px; border-radius:10px; border-color:var(--theme-orange);">
            <div style="display:flex; align-items:center; gap:14px;">
              <span style="font-size:20px; color:var(--theme-orange);">●</span>
              <div style="text-align:left;">
                <div style="font-size:18px; font-weight:800;">Lekce 02 · Střídání rukou</div>
                <div style="font-size:13px; color:var(--secondary);">Koordinace · ●●○○○ · 65 → 85 BPM</div>
              </div>
            </div>
            <div style="display:flex; align-items:center; gap:16px;">
              <span style="background:rgba(255,107,0,0.18); color:var(--theme-orange); font-size:11.5px; font-weight:700; padding:3px 8px; border-radius:4px;">⏰ K OPAKOVÁNÍ</span>
              <div style="font-size:20px; color:var(--theme-orange);">★★<span style="color:var(--star-off);">☆</span></div>
            </div>
          </div>

          <!-- Lesson 3 Card (Up Next) -->
          <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; justify-content:space-between; gap:20px; border-radius:10px;">
            <div style="display:flex; align-items:center; gap:14px;">
              <span style="font-size:20px; color:var(--ink);">▶</span>
              <div style="text-align:left;">
                <div style="font-size:18px; font-weight:800;">Lekce 03 · Základní groove</div>
                <div style="font-size:13px; color:var(--secondary);">Rock / Pop · ●●●○○ · 70 → 95 BPM</div>
              </div>
            </div>
            <div style="display:flex; align-items:center; gap:20px;">
              <span style="background:var(--surface); border:1px solid var(--hairline); font-size:11.5px; font-weight:700; padding:3px 8px; border-radius:4px;">NA ŘADĚ</span>
              <div style="font-size:20px; color:var(--theme-orange);">★<span style="color:var(--star-off);">☆☆</span></div>
            </div>
          </div>

          <!-- Lesson 4 Card -->
          <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; justify-content:space-between; gap:20px; border-radius:10px; opacity:0.8;">
            <div style="display:flex; align-items:center; gap:14px;">
              <span style="font-size:20px; color:var(--secondary);">🔒</span>
              <div style="text-align:left;">
                <div style="font-size:18px; font-weight:800;">Lekce 04 · Synkopa na snare</div>
                <div style="font-size:13px; color:var(--secondary);">Funk · ●●●○○ · 80 → 105 BPM</div>
              </div>
            </div>
            <div style="font-size:20px; color:var(--star-off);">☆☆☆</div>
          </div>
        </div>
      </div>
    </div>
    """

def render_training():
    return f"""
    <div class="screen-wrapper training-screen-view" style="padding:24px 32px; display:flex; flex-direction:column; gap:24px; height:100%; overflow-y:auto;">
      
      <!-- 1. DOMINANT ORANGE TODAY BAND -->
      <div class="today-band-module" style="background:#FF6B00; color:#1F1D1A; border-radius:16px; padding:22px 28px; box-shadow:0 8px 30px rgba(255,107,0,0.35); position:relative;">
        <!-- Header Line -->
        <div style="display:flex; align-items:baseline; justify-content:space-between; margin-bottom:18px;">
          <div style="font-size:34px; font-weight:900; letter-spacing:0.04em;">DNES</div>
          <div style="font-size:14px; font-weight:700; opacity:0.85;">Pátek 6. listopadu · 2 k opakování</div>
        </div>

        <!-- 3 Step Blocks (Cassettes in Pad Material) -->
        <div style="display:grid; grid-template-columns:repeat(3, 1fr); gap:14px; margin-bottom:20px;">
          <!-- Step 1 -->
          <div class="hw-pad" style="background:#FFF; color:#1F1D1A; padding:16px; align-items:flex-start; text-align:left; border:none; box-shadow:0 3px 6px rgba(0,0,0,0.18);">
            <div style="display:flex; justify-content:space-between; width:100%; margin-bottom:4px;">
              <span style="font-size:11px; font-weight:800; color:#888;">KROK 1</span>
              <span style="width:10px; height:10px; border-radius:50%; background:#FF6B00; box-shadow:0 0 6px #FF6B00;" class="breathing"></span>
            </div>
            <div style="font-size:17px; font-weight:800; margin-bottom:4px;">Opakování</div>
            <div style="font-size:12.5px; color:#555;">2 lekce zpaměti v cílovém tempu</div>
          </div>

          <!-- Step 2 -->
          <div class="hw-pad" style="background:#FFF; color:#1F1D1A; padding:16px; align-items:flex-start; text-align:left; border:none; box-shadow:0 3px 6px rgba(0,0,0,0.18);">
            <div style="display:flex; justify-content:space-between; width:100%; margin-bottom:4px;">
              <span style="font-size:11px; font-weight:800; color:#888;">KROK 2</span>
              <span style="width:10px; height:10px; border-radius:50%; background:#FF6B00;"></span>
            </div>
            <div style="font-size:17px; font-weight:800; margin-bottom:4px;">Nová lekce</div>
            <div style="font-size:12.5px; color:#555;">Lekce 03 · Základní groove</div>
          </div>

          <!-- Step 3 -->
          <div class="hw-pad" style="background:#FFF; color:#1F1D1A; padding:16px; align-items:flex-start; text-align:left; border:none; box-shadow:0 3px 6px rgba(0,0,0,0.18); opacity:0.9;">
            <div style="display:flex; justify-content:space-between; width:100%; margin-bottom:4px;">
              <span style="font-size:11px; font-weight:800; color:#888;">KROK 3 · VOLITELNÉ</span>
              <span style="width:10px; height:10px; border-radius:50%; background:#D6D0C4;"></span>
            </div>
            <div style="font-size:17px; font-weight:800; margin-bottom:4px;">Mix</div>
            <div style="font-size:12.5px; color:#555;">4 lekce, každá jednou</div>
          </div>
        </div>

        <!-- Band Footer -->
        <div style="display:flex; align-items:center; justify-content:space-between; gap:20px;">
          <div style="font-size:14px; font-weight:600;">Nic není zamčené. Kterýkoliv krok můžeš přeskočit.</div>
          <div style="display:flex; gap:12px;">
            <button class="hw-pad" style="background:rgba(255,255,255,0.25); border:1.5px solid #1F1D1A; color:#1F1D1A; font-weight:800; padding:12px 20px; font-size:15px;">
              Dnes ne
            </button>
            <button class="hw-pad" style="background:#1F1D1A; color:#FFF; font-weight:900; padding:12px 26px; font-size:16px; letter-spacing:0.04em;">
              SPUSTIT DNEŠNÍ TRÉNINK ➔
            </button>
          </div>
        </div>
      </div>

      <!-- 2. MIDDLE ROW: MEMORY METER & NEXT 7 DAYS FORECAST -->
      <div style="display:grid; grid-template-columns:1fr 1fr; gap:20px;">
        <!-- Memory VU-Meter Panel -->
        <div class="hardware-plate" style="padding:20px;">
          <div style="font-size:16px; font-weight:800; margin-bottom:14px;">Paměťový trenažér (VU-metr)</div>
          <div style="display:flex; gap:14px; align-items:flex-end;">
            <div class="vu-meter-column">
              <div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div>
              <div class="vu-seg lit"></div><div class="vu-seg lit"></div><div class="vu-seg lit"></div><div class="vu-seg lit"></div>
              <div style="font-size:18px; font-weight:800; margin-top:4px;">4</div>
              <div style="font-size:11px; color:var(--secondary);">Naučeno ★★</div>
            </div>
            <div class="vu-meter-column">
              <div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div>
              <div class="vu-seg"></div><div class="vu-seg lit"></div><div class="vu-seg lit"></div><div class="vu-seg lit"></div>
              <div style="font-size:18px; font-weight:800; margin-top:4px;">3</div>
              <div style="font-size:11px; color:var(--secondary);">Krok 1</div>
            </div>
            <div class="vu-meter-column">
              <div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div>
              <div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg lit"></div><div class="vu-seg lit"></div>
              <div style="font-size:18px; font-weight:800; margin-top:4px;">2</div>
              <div style="font-size:11px; color:var(--secondary);">Krok 2</div>
            </div>
            <div class="vu-meter-column">
              <div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div>
              <div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg"></div><div class="vu-seg lit"></div>
              <div style="font-size:18px; font-weight:800; margin-top:4px;">1</div>
              <div style="font-size:11px; color:var(--secondary);">Krok 3</div>
            </div>
            <div class="vu-meter-column">
              <div class="vu-seg"></div><div class="vu-seg"></div>
              <div class="vu-seg lit orange"></div><div class="vu-seg lit orange"></div><div class="vu-seg lit orange"></div>
              <div class="vu-seg lit orange"></div><div class="vu-seg lit orange"></div><div class="vu-seg lit orange"></div>
              <div style="font-size:18px; font-weight:800; color:var(--theme-orange); margin-top:4px;">6</div>
              <div style="font-size:11px; font-weight:700; color:var(--theme-orange);">Usazeno ★★★</div>
            </div>
          </div>
        </div>

        <!-- Next 7 Days Forecast -->
        <div class="hardware-plate" style="padding:20px;">
          <div style="font-size:16px; font-weight:800; margin-bottom:14px;">Příštích 7 dní</div>
          <div style="display:flex; justify-content:space-between; align-items:flex-end; height:120px;">
            <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
              <div style="font-size:14px; font-weight:800; color:var(--theme-orange);">2</div>
              <div style="width:28px; height:50px; background:var(--theme-orange); border-radius:4px;"></div>
              <div style="font-size:12px; font-weight:700;">Dnes</div>
            </div>
            <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
              <div style="font-size:14px; font-weight:700;">1</div>
              <div style="width:28px; height:28px; background:var(--surface); border:1px solid var(--hairline); border-radius:4px;"></div>
              <div style="font-size:12px; color:var(--secondary);">So</div>
            </div>
            <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
              <div style="font-size:14px; font-weight:700; color:var(--secondary);">0</div>
              <div style="width:28px; height:8px; background:var(--pad-well-bg); border-radius:4px;"></div>
              <div style="font-size:12px; color:var(--secondary);">Ne</div>
            </div>
            <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
              <div style="font-size:14px; font-weight:700;">3</div>
              <div style="width:28px; height:68px; background:var(--surface); border:1px solid var(--hairline); border-radius:4px;"></div>
              <div style="font-size:12px; color:var(--secondary);">Po</div>
            </div>
            <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
              <div style="font-size:14px; font-weight:700;">1</div>
              <div style="width:28px; height:28px; background:var(--surface); border:1px solid var(--hairline); border-radius:4px;"></div>
              <div style="font-size:12px; color:var(--secondary);">Út</div>
            </div>
            <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
              <div style="font-size:14px; font-weight:700;">2</div>
              <div style="width:28px; height:50px; background:var(--surface); border:1px solid var(--hairline); border-radius:4px;"></div>
              <div style="font-size:12px; color:var(--secondary);">St</div>
            </div>
            <div style="display:flex; flex-direction:column; align-items:center; gap:6px;">
              <div style="font-size:14px; font-weight:700; color:var(--secondary);">0</div>
              <div style="width:28px; height:8px; background:var(--pad-well-bg); border-radius:4px;"></div>
              <div style="font-size:12px; color:var(--secondary);">Čt</div>
            </div>
          </div>
        </div>
      </div>

      <!-- 3. LOWER ROW: DUE NOW & MIX -->
      <div style="display:grid; grid-template-columns:1.5fr 1fr; gap:20px;">
        <!-- Due Now List -->
        <div class="hardware-plate" style="padding:20px;">
          <div style="font-size:16px; font-weight:800; margin-bottom:12px;">K opakování právě teď</div>
          <div style="display:flex; flex-direction:column; gap:8px;">
            <div class="hw-pad" style="padding:12px 16px; display:flex; flex-direction:row; align-items:center; justify-content:space-between;">
              <div style="text-align:left;">
                <div style="font-size:16px; font-weight:800;">Lekce 02 · Střídání rukou</div>
                <div style="font-size:12px; color:var(--secondary);">Krok 1 · 85 BPM zpaměti</div>
              </div>
              <div style="display:flex; align-items:center; gap:12px;">
                <span style="background:rgba(255,107,0,0.18); color:var(--theme-orange); font-size:11px; font-weight:800; padding:3px 8px; border-radius:4px;">DNES</span>
                <button class="hw-pad hero-pad" style="padding:6px 14px; font-size:13px; font-weight:800;">Cvičit</button>
              </div>
            </div>

            <div class="hw-pad" style="padding:12px 16px; display:flex; flex-direction:row; align-items:center; justify-content:space-between;">
              <div style="text-align:left;">
                <div style="font-size:16px; font-weight:800;">Lekce 01 · První úder</div>
                <div style="font-size:12px; color:var(--secondary);">Krok 2 · 80 BPM zpaměti</div>
              </div>
              <div style="display:flex; align-items:center; gap:12px;">
                <span style="background:rgba(158,15,26,0.15); color:var(--theme-mark-wrong); font-size:11px; font-weight:800; padding:3px 8px; border-radius:4px;">+2 DNY</span>
                <button class="hw-pad hero-pad" style="padding:6px 14px; font-size:13px; font-weight:800;">Cvičit</button>
              </div>
            </div>
          </div>
        </div>

        <!-- Mix & Play after me -->
        <div style="display:flex; flex-direction:column; gap:12px;">
          <div class="hardware-plate" style="padding:16px; display:flex; align-items:center; justify-content:space-between;">
            <div>
              <div style="font-size:16px; font-weight:800;">Mix skladeb</div>
              <div style="font-size:12px; color:var(--secondary);">Mix 4 zvládnutých lekcí za sebou</div>
            </div>
            <button class="hw-pad" style="padding:8px 16px; font-size:14px; font-weight:700;">Hrát mix</button>
          </div>

          <div class="hardware-plate" style="padding:16px; display:flex; align-items:center; justify-content:space-between;">
            <div>
              <div style="font-size:16px; font-weight:800;">Hraj po mně</div>
              <div style="font-size:12px; color:var(--secondary);">Trénink reakce a sluchu bez not</div>
            </div>
            <button class="hw-pad" style="padding:8px 16px; font-size:14px; font-weight:700;">Spustit</button>
          </div>
        </div>
      </div>
    </div>
    """

def render_today():
    return f"""
    <div class="screen-wrapper today-session-view" style="padding:40px; display:flex; flex-direction:column; justify-content:center; align-items:center; height:100%;">
      
      <!-- Handoff Card Plate (16pt radius, screws) -->
      <div class="hardware-plate" style="width:100%; max-width:640px; padding:36px; display:flex; flex-direction:column; gap:20px;">
        {get_screw("tl")}
        {get_screw("tr")}
        {get_screw("bl")}
        {get_screw("br")}

        <!-- Step Tag -->
        <div style="font-size:12px; font-weight:800; letter-spacing:0.08em; color:var(--secondary); text-transform:uppercase;">
          OPAKOVÁNÍ 1 Z 2
        </div>

        <!-- Outcome Heading -->
        <div style="font-size:28px; font-weight:800; line-height:1.25; color:var(--ink);">
          Výborně! První opakování hotovo zpaměti v tempu 85 BPM.
        </div>

        <!-- Meta Line -->
        <div style="font-size:15px; color:var(--secondary); font-weight:600;">
          Lekce 02 · Střídání rukou · 95 %
        </div>

        <div style="height:1px; background:var(--hairline); margin:6px 0;"></div>

        <!-- Next Step Preview -->
        <div>
          <div style="font-size:11.5px; font-weight:800; letter-spacing:0.06em; color:var(--secondary); text-transform:uppercase; margin-bottom:4px;">
            DALŠÍ KROK
          </div>
          <div style="font-size:19px; font-weight:700; color:var(--ink);">
            Lekce 01 · První úder (opakování 2 z 2)
          </div>
        </div>

        <!-- Button Row (Pad Material) -->
        <div style="display:flex; gap:12px; margin-top:10px;">
          <button class="hw-pad hero-pad" style="flex:2; padding:14px; font-size:18px; font-weight:800;">
            POKRAČOVAT ➔
          </button>
          <button class="hw-pad" style="flex:1; padding:14px; font-size:15px; font-weight:700;">
            Přeskočit
          </button>
          <button class="hw-pad" style="flex:1.2; padding:14px; font-size:15px; font-weight:700;">
            Dnes hotovo
          </button>
        </div>
      </div>
    </div>
    """

def render_badges():
    return f"""
    <div class="screen-wrapper badges-view" style="padding:28px 40px; display:flex; flex-direction:column; gap:20px; height:100%; overflow-y:auto;">
      <!-- Header -->
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div>
          <div style="font-size:28px; font-weight:800;">Odznaky a ocenění</div>
          <div style="font-size:14px; color:var(--secondary);">Získáno 4 z 16 odznaků</div>
        </div>
        <button class="hw-pad" style="padding:8px 18px; font-size:15px; font-weight:700;">Hotovo</button>
      </div>

      <!-- Badges Grid Sections -->
      <div style="display:flex; flex-direction:column; gap:20px;">
        <!-- Category: Trénink -->
        <div>
          <div style="font-size:13px; font-weight:800; text-transform:uppercase; letter-spacing:0.06em; color:var(--secondary); margin-bottom:10px;">Pravidelnost a trénink</div>
          <div style="display:grid; grid-template-columns:repeat(2, 1fr); gap:12px;">
            <!-- Badge 1: Earned Gold -->
            <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; gap:16px; text-align:left;">
              <div style="width:48px; height:48px; border-radius:50%; background:var(--theme-orange); color:#1F1D1A; display:flex; align-items:center; justify-content:center; font-size:24px; font-weight:900; box-shadow:0 0 10px rgba(255,107,0,0.5);">
                ★
              </div>
              <div style="flex:1;">
                <div style="font-size:17px; font-weight:800;">Cesta za rytmem</div>
                <div style="font-size:12.5px; color:var(--secondary); margin-bottom:4px;">Dokonči svoji první lekci</div>
                <div style="font-size:11px; font-weight:700; color:var(--theme-orange);">Získáno: 1. 11. 2026</div>
              </div>
            </div>

            <!-- Badge 2: Earned Silver -->
            <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; gap:16px; text-align:left;">
              <div style="width:48px; height:48px; border-radius:50%; background:var(--ink); color:var(--bg); display:flex; align-items:center; justify-content:center; font-size:22px; font-weight:900;">
                5
              </div>
              <div style="flex:1;">
                <div style="font-size:17px; font-weight:800;">Železná pravidelnost</div>
                <div style="font-size:12.5px; color:var(--secondary); margin-bottom:4px;">Cvič 5 dní v řadě</div>
                <div style="font-size:11px; font-weight:700; color:var(--theme-orange);">Získáno: 5. 11. 2026</div>
              </div>
            </div>

            <!-- Badge 3: In Progress -->
            <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; gap:16px; text-align:left;">
              <div style="width:48px; height:48px; border-radius:50%; background:var(--pad-well-bg); color:var(--secondary); display:flex; align-items:center; justify-content:center; font-size:20px; font-weight:900;">
                7
              </div>
              <div style="flex:1;">
                <div style="font-size:17px; font-weight:800;">Týdenní šňůra</div>
                <div style="font-size:12.5px; color:var(--secondary); margin-bottom:6px;">Cvič 7 dní v řadě</div>
                <div style="height:4px; background:var(--pad-well-bg); border-radius:2px; overflow:hidden;">
                  <div style="width:71%; height:100%; background:var(--theme-orange);"></div>
                </div>
                <div style="font-size:10.5px; color:var(--secondary); margin-top:4px;">Postup: 5 / 7 dní</div>
              </div>
            </div>

            <!-- Badge 4: In Progress -->
            <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; gap:16px; text-align:left;">
              <div style="width:48px; height:48px; border-radius:50%; background:var(--pad-well-bg); color:var(--secondary); display:flex; align-items:center; justify-content:center; font-size:20px; font-weight:900;">
                30
              </div>
              <div style="flex:1;">
                <div style="font-size:17px; font-weight:800;">Měsíční maraton</div>
                <div style="font-size:12.5px; color:var(--secondary); margin-bottom:6px;">Cvič 30 dní v kalendářním měsíci</div>
                <div style="height:4px; background:var(--pad-well-bg); border-radius:2px; overflow:hidden;">
                  <div style="width:20%; height:100%; background:var(--theme-orange);"></div>
                </div>
                <div style="font-size:10.5px; color:var(--secondary); margin-top:4px;">Postup: 6 / 30 dní</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Category: Přesnost a paměť -->
        <div>
          <div style="font-size:13px; font-weight:800; text-transform:uppercase; letter-spacing:0.06em; color:var(--secondary); margin-bottom:10px;">Přesnost a paměť</div>
          <div style="display:grid; grid-template-columns:repeat(2, 1fr); gap:12px;">
            <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; gap:16px; text-align:left;">
              <div style="width:48px; height:48px; border-radius:50%; background:var(--theme-orange); color:#1F1D1A; display:flex; align-items:center; justify-content:center; font-size:20px; font-weight:900;">
                98%
              </div>
              <div style="flex:1;">
                <div style="font-size:17px; font-weight:800;">Chirurgická přesnost</div>
                <div style="font-size:12.5px; color:var(--secondary); margin-bottom:4px;">Dosáhni skóre alespoň 98 %</div>
                <div style="font-size:11px; font-weight:700; color:var(--theme-orange);">Získáno: 3. 11. 2026</div>
              </div>
            </div>

            <div class="hw-pad" style="padding:16px 20px; display:flex; flex-direction:row; align-items:center; gap:16px; text-align:left;">
              <div style="width:48px; height:48px; border-radius:50%; background:var(--theme-orange); color:#1F1D1A; display:flex; align-items:center; justify-content:center; font-size:22px; font-weight:900;">
                Ø
              </div>
              <div style="flex:1;">
                <div style="font-size:17px; font-weight:800;">Hra poslepu</div>
                <div style="font-size:12.5px; color:var(--secondary); margin-bottom:4px;">Získej 3. hvězdu v tempu zpaměti</div>
                <div style="font-size:11px; font-weight:700; color:var(--theme-orange);">Získáno: 4. 11. 2026</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """

def render_settings():
    return f"""
    <div class="screen-wrapper settings-view" style="padding:28px 40px; display:flex; flex-direction:column; gap:20px; height:100%; overflow-y:auto;">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div style="font-size:28px; font-weight:800;">Nastavení</div>
        <button class="hw-pad" style="padding:8px 18px; font-size:15px; font-weight:700;">Hotovo</button>
      </div>

      <!-- Settings Hardware Modules -->
      <div style="display:grid; grid-template-columns:1fr 1fr; gap:20px;">
        <!-- Column 1 -->
        <div style="display:flex; flex-direction:column; gap:16px;">
          <!-- 1. Controller & Calibration -->
          <div class="hardware-plate" style="padding:18px;">
            <div style="font-size:15px; font-weight:800; margin-bottom:10px;">Kontroler a kalibrace</div>
            <div class="hw-pad" style="padding:12px 16px; display:flex; flex-direction:row; justify-content:space-between; align-items:center;">
              <div style="text-align:left;">
                <div style="font-size:16px; font-weight:800;">Akai MPD218</div>
                <div style="font-size:12px; color:var(--theme-orange); font-weight:700;">● Připojeno přes USB · -14 ms</div>
              </div>
              <button class="hw-key" style="font-size:12px;">Upravit ▾</button>
            </div>
          </div>

          <!-- 2. Sound Kit Selection -->
          <div class="hardware-plate" style="padding:18px;">
            <div style="font-size:15px; font-weight:800; margin-bottom:10px;">Zvuková sada</div>
            <div class="hw-key-group" style="width:100%; display:grid; grid-template-columns:repeat(3, 1fr);">
              <button class="hw-key active"><span class="key-light-bar"></span>Auto</button>
              <button class="hw-key">Funk 808</button>
              <button class="hw-key">Vintage Neo</button>
            </div>
          </div>

          <!-- 3. Hardware Fader Volume Sliders -->
          <div class="hardware-plate" style="padding:18px;">
            <div style="font-size:15px; font-weight:800; margin-bottom:14px;">Hlasitosti mixu</div>
            
            <div style="margin-bottom:12px;">
              <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:700; margin-bottom:6px;">
                <span>Metronom</span><span>80 %</span>
              </div>
              <div class="hw-fader-slot" style="width:100%; height:8px;">
                <div style="position:absolute; left:0; width:80%; top:0; bottom:0; background:var(--theme-orange); border-radius:2px;"></div>
              </div>
            </div>

            <div style="margin-bottom:12px;">
              <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:700; margin-bottom:6px;">
                <span>Pady (vlastní úder)</span><span>100 %</span>
              </div>
              <div class="hw-fader-slot" style="width:100%; height:8px;">
                <div style="position:absolute; left:0; width:100%; top:0; bottom:0; background:var(--theme-orange); border-radius:2px;"></div>
              </div>
            </div>

            <div>
              <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:700; margin-bottom:6px;">
                <span>Zvuk vzoru</span><span>70 %</span>
              </div>
              <div class="hw-fader-slot" style="width:100%; height:8px;">
                <div style="position:absolute; left:0; width:70%; top:0; bottom:0; background:var(--theme-orange); border-radius:2px;"></div>
              </div>
            </div>
          </div>
        </div>

        <!-- Column 2 -->
        <div style="display:flex; flex-direction:column; gap:16px;">
          <!-- 4. BPM Auto-step -->
          <div class="hardware-plate" style="padding:18px;">
            <div style="font-size:15px; font-weight:800; margin-bottom:10px;">Automatický krok tempa (BPM)</div>
            <div class="hw-key-group" style="width:100%; display:grid; grid-template-columns:repeat(3, 1fr);">
              <button class="hw-key">+2 BPM</button>
              <button class="hw-key active"><span class="key-light-bar"></span>+5 BPM</button>
              <button class="hw-key">+10 BPM</button>
            </div>
          </div>

          <!-- 5. Appearance & Language Keys -->
          <div class="hardware-plate" style="padding:18px;">
            <div style="font-size:15px; font-weight:800; margin-bottom:10px;">Vzhled aplikace</div>
            <div class="hw-key-group" style="width:100%; display:grid; grid-template-columns:repeat(3, 1fr); margin-bottom:16px;">
              <button class="hw-key active theme-btn-light"><span class="key-light-bar"></span>Světlý</button>
              <button class="hw-key theme-btn-dark">Tmavý</button>
              <button class="hw-key">Systém</button>
            </div>

            <div style="font-size:15px; font-weight:800; margin-bottom:10px;">Jazyk</div>
            <div class="hw-key-group" style="width:100%; display:grid; grid-template-columns:repeat(2, 1fr);">
              <button class="hw-key active"><span class="key-light-bar"></span>Čeština</button>
              <button class="hw-key">English</button>
            </div>
          </div>

          <!-- 6. Touch Pads Test Matrix -->
          <div class="hardware-plate" style="padding:18px;">
            <div style="font-size:15px; font-weight:800; margin-bottom:10px;">Test dotykových padů</div>
            <div style="display:grid; grid-template-columns:repeat(4, 1fr); gap:8px;">
              <div class="hw-pad" style="aspect-ratio:1; font-size:12px; font-weight:800;">1</div>
              <div class="hw-pad" style="aspect-ratio:1; font-size:12px; font-weight:800;">2</div>
              <div class="hw-pad" style="aspect-ratio:1; font-size:12px; font-weight:800;">3</div>
              <div class="hw-pad" style="aspect-ratio:1; font-size:12px; font-weight:800;">4</div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """

def render_about():
    return f"""
    <div class="screen-wrapper about-view" style="padding:40px; display:flex; flex-direction:column; justify-content:center; align-items:center; height:100%;">
      <!-- Centered Instrument Plate -->
      <div class="hardware-plate" style="width:100%; max-width:560px; padding:44px; display:flex; flex-direction:column; align-items:center; text-align:center; gap:16px;">
        {get_screw("tl")}
        {get_screw("tr")}
        {get_screw("bl")}
        {get_screw("br")}

        <div style="margin-bottom:10px;">
          {WORDMARK_SVG}
        </div>

        <div style="font-size:22px; font-weight:800; color:var(--ink);">
          Smack-a-Pad iPad
        </div>
        <div style="font-size:14px; font-weight:600; color:var(--secondary);">
          Profesionální trenažér prstového bubnování
        </div>

        <div style="width:60px; height:2px; background:var(--theme-orange); margin:8px 0;"></div>

        <div style="font-size:14px; color:var(--ink); line-height:1.6;">
          Verze 1.0 (Build 42)<br/>
          Písmo: IBM Plex Sans (SIL Open Font License 1.1)<br/>
          © 2026 Smack-a-Pad Team
        </div>

        <button class="hw-pad hero-pad" style="margin-top:14px; padding:12px 32px; font-size:16px; font-weight:800;">
          Zavřít
        </button>
      </div>
    </div>
    """

def render_purchases():
    return f"""
    <div class="screen-wrapper purchases-view" style="padding:40px; display:flex; flex-direction:column; justify-content:center; align-items:center; height:100%;">
      <div class="hardware-plate" style="width:100%; max-width:560px; padding:36px; display:flex; flex-direction:column; gap:20px;">
        {get_screw("tl")}
        {get_screw("tr")}
        {get_screw("bl")}
        {get_screw("br")}

        <div style="font-size:28px; font-weight:900;">Plné odemknutí aplikace</div>

        <div style="display:flex; flex-direction:column; gap:12px; font-size:16px; font-weight:600;">
          <div>✓ Všech 75 lekcí ve všech 5 úrovních</div>
          <div>✓ Všech 8 zvukových studiových kitů</div>
          <div>✓ Neomezený tréninkový režim Dnes & Mix</div>
          <div>✓ Žádné předplatné · Jednorázová platba</div>
        </div>

        <div style="font-size:13px; color:var(--secondary); margin-top:4px;">
          Postup odemykání úrovní stále závisí na tvých získaných hvězdách.
        </div>

        <div style="display:flex; flex-direction:column; gap:10px; margin-top:8px;">
          <button class="hw-pad hero-pad" style="padding:16px; font-size:20px; font-weight:800;">
            ODEMKNOUT · 249 Kč
          </button>
          <button class="hw-pad" style="padding:12px; font-size:14px; font-weight:700;">
            Obnovit nákupy
          </button>
        </div>
      </div>
    </div>
    """

def render_controller_setup():
    return f"""
    <div class="screen-wrapper controller-setup-view" style="padding:28px 40px; display:flex; flex-direction:column; gap:20px; height:100%; overflow-y:auto;">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div style="font-size:28px; font-weight:800;">Nastavení kontroleru</div>
        <button class="hw-pad" style="padding:8px 18px; font-size:15px; font-weight:700;">Hotovo</button>
      </div>

      <div style="display:flex; flex-direction:column; gap:16px; max-width:760px;">
        <!-- Status Box -->
        <div class="hardware-plate" style="padding:20px; display:flex; align-items:center; justify-content:space-between;">
          <div>
            <div style="font-size:20px; font-weight:800;">Akai MPD218</div>
            <div style="font-size:13px; color:var(--theme-orange); font-weight:700;">● Připojeno (USB MIDI)</div>
          </div>
          <button class="hw-pad" style="padding:10px 18px; font-size:14px; font-weight:700;">Připojit Bluetooth MIDI</button>
        </div>

        <!-- Latency Calibration Link -->
        <div class="hardware-plate" style="padding:20px; display:flex; align-items:center; justify-content:space-between;">
          <div>
            <div style="font-size:16px; font-weight:800;">Kalibrace odezvy zvuku</div>
            <div style="font-size:13px; color:var(--secondary);">Kompenzuje zpoždění Bluetooth a zvukového výstupu</div>
          </div>
          <div style="display:flex; align-items:center; gap:14px;">
            <span style="font-size:18px; font-weight:800; font-variant-numeric:tabular-nums; color:var(--theme-orange);">-14 ms</span>
            <button class="hw-key" style="font-size:13px; padding:6px 14px;">Kalibrovat ➔</button>
          </div>
        </div>

        <!-- Profiles List -->
        <div class="hardware-plate" style="padding:20px;">
          <div style="font-size:16px; font-weight:800; margin-bottom:12px;">Profily mapování padů</div>
          <div style="display:flex; flex-direction:column; gap:8px;">
            <div class="hw-pad" style="padding:14px; display:flex; flex-direction:row; justify-content:space-between; align-items:center; border-color:var(--theme-orange);">
              <div>
                <span style="font-weight:800;">Akai MPD218 (Aktivní)</span>
                <span style="font-size:12px; color:var(--secondary); margin-left:8px;">16 padů</span>
              </div>
              <span style="color:var(--theme-orange); font-weight:800;">✓</span>
            </div>
            <div class="hw-pad" style="padding:14px; display:flex; flex-direction:row; justify-content:space-between; align-items:center;">
              <div>
                <span style="font-weight:700;">Novation Launchkey Mini</span>
                <span style="font-size:12px; color:var(--secondary); margin-left:8px;">16 padů</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """

def render_calibration():
    return f"""
    <div class="screen-wrapper calibration-view" style="padding:32px 40px; display:flex; flex-direction:column; justify-content:center; align-items:center; height:100%;">
      <!-- Calibration Console Plate -->
      <div class="hardware-plate" style="width:100%; max-width:680px; padding:36px; display:flex; flex-direction:column; gap:22px; text-align:center;">
        {get_screw("tl")}
        {get_screw("tr")}
        {get_screw("bl")}
        {get_screw("br")}

        <div>
          <div style="font-size:26px; font-weight:900;">Kalibrace odezvy zvuku</div>
          <div style="font-size:14px; color:var(--secondary); margin-top:4px;">
            Poslouchej 4 údery metronomu, pak klepni přesně do rytmu s dalšími 10 údery.
          </div>
        </div>

        <!-- Large Interactive TAP PAD in Pad Material -->
        <div class="pad-well" style="width:260px; height:180px; margin:10px auto;">
          <div class="hw-pad tap-pad hero-pad" id="calibration-tap-btn" style="width:100%; height:100%; font-size:28px; font-weight:900; letter-spacing:0.06em; cursor:pointer;">
            <div class="flash-overlay"></div>
            KLEPNI SEM
            <div style="font-size:12px; font-weight:700; opacity:0.85; margin-top:4px;">DO RYTMU S METRONOMEM</div>
          </div>
        </div>

        <!-- Progress and Stats -->
        <div>
          <div style="display:flex; justify-content:space-between; font-size:13px; font-weight:700; margin-bottom:6px;">
            <span style="color:var(--secondary);">Zaznamenané údery</span>
            <span id="calib-progress-label" style="color:var(--theme-orange); font-variant-numeric:tabular-nums;">7 / 10</span>
          </div>
          <div style="height:8px; background:var(--pad-well-bg); border-radius:4px; overflow:hidden;">
            <div id="calib-progress-bar" style="width:70%; height:100%; background:var(--theme-orange); transition:width 0.2s;"></div>
          </div>
        </div>

        <div style="display:grid; grid-template-columns:1fr 1fr; gap:16px;">
          <div class="instrument-display" style="padding:14px;">
            <div class="display-label">Naměřený posun</div>
            <div class="display-val" style="font-size:32px; color:var(--theme-orange);">-18 ms</div>
          </div>
          <div class="instrument-display" style="padding:14px;">
            <div class="display-label">Rozptyl přesnosti</div>
            <div class="display-val" style="font-size:32px;">6 ms</div>
          </div>
        </div>

        <div style="display:flex; gap:12px; margin-top:6px;">
          <button class="hw-pad" style="flex:1; padding:12px; font-size:15px; font-weight:700;">Zrušit</button>
          <button class="hw-pad hero-pad" style="flex:2; padding:12px; font-size:16px; font-weight:800;">Uložit kalibraci</button>
        </div>
      </div>
    </div>
    """

def render_intro():
    return f"""
    <div class="screen-wrapper intro-view" style="padding:28px 40px; display:flex; flex-direction:column; gap:20px; height:100%; overflow-y:auto;">
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div>
          <div style="font-size:28px; font-weight:800;">Úvodní cvičení</div>
          <div style="font-size:14px; color:var(--secondary);">25 cvičení pro absolutní základy · vždy otevřeno</div>
        </div>
        <button class="hw-pad" style="padding:8px 18px; font-size:14px; font-weight:700;">Pravidla ⓘ</button>
      </div>

      <!-- Stages List -->
      <div style="display:flex; flex-direction:column; gap:20px; max-width:880px;">
        <!-- Stage 1 -->
        <div>
          <div style="font-size:17px; font-weight:800; margin-bottom:4px;">1. Pulz</div>
          <div style="font-size:13px; color:var(--secondary); margin-bottom:10px;">Stabilní čtvrťový pulz jednou a oběma rukama · cvičení 1–4</div>
          <div style="display:grid; grid-template-columns:repeat(2, 1fr); gap:10px;">
            <div class="hw-pad" style="padding:14px 18px; display:flex; flex-direction:row; justify-content:space-between; align-items:center;">
              <div>
                <div style="font-size:16px; font-weight:800;">Cvičení 01 · První čtvrťové</div>
                <div style="font-size:12px; color:var(--secondary);">Pravá ruka · 60 BPM</div>
              </div>
              <span style="font-size:18px; color:var(--theme-orange);">★★★</span>
            </div>
            <div class="hw-pad" style="padding:14px 18px; display:flex; flex-direction:row; justify-content:space-between; align-items:center;">
              <div>
                <div style="font-size:16px; font-weight:800;">Cvičení 02 · Levá ruka</div>
                <div style="font-size:12px; color:var(--secondary);">Levá ruka · 60 BPM</div>
              </div>
              <span style="font-size:18px; color:var(--theme-orange);">★★★</span>
            </div>
          </div>
        </div>

        <!-- Stage 2 -->
        <div>
          <div style="font-size:17px; font-weight:800; margin-bottom:4px;">2. Obě ruce</div>
          <div style="font-size:13px; color:var(--secondary); margin-bottom:10px;">Koordinace rukou a střídání · cvičení 5–8</div>
          <div style="display:grid; grid-template-columns:repeat(2, 1fr); gap:10px;">
            <div class="hw-pad" style="padding:14px 18px; display:flex; flex-direction:row; justify-content:space-between; align-items:center;">
              <div>
                <div style="font-size:16px; font-weight:800;">Cvičení 05 · Střídání R-L</div>
                <div style="font-size:12px; color:var(--secondary);">Kick a Snare · 70 BPM</div>
              </div>
              <span style="font-size:18px; color:var(--theme-orange);">★★<span style="color:var(--star-off);">☆</span></span>
            </div>
            <div class="hw-pad" style="padding:14px 18px; display:flex; flex-direction:row; justify-content:space-between; align-items:center;">
              <div>
                <div style="font-size:16px; font-weight:800;">Cvičení 06 · Společný úder</div>
                <div style="font-size:12px; color:var(--secondary);">Kick + Hi-hat · 70 BPM</div>
              </div>
              <span style="font-size:18px; color:var(--theme-orange);">★<span style="color:var(--star-off);">☆☆</span></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """

def render_banners():
    return f"""
    <div class="screen-wrapper banners-view" style="padding:40px; display:flex; flex-direction:column; gap:32px; height:100%; overflow-y:auto; align-items:center;">
      <div style="text-align:center;">
        <div style="font-size:28px; font-weight:800;">Bannery, překryvy a notifikace</div>
        <div style="font-size:14px; color:var(--secondary);">Jednotný hardware styl pro vyskakovací prvky a oznámení</div>
      </div>

      <!-- 1. Floating Badge Banner -->
      <div style="width:100%; max-width:540px;">
        <div style="font-size:12px; font-weight:700; color:var(--secondary); text-transform:uppercase; margin-bottom:8px;">1. Plovoucí oznámení o novém odznaku (BadgeBanner)</div>
        <div class="hw-pad" style="background:#FFF; color:#1F1D1A; padding:14px 22px; display:flex; flex-direction:row; align-items:center; gap:16px; border:2px solid #1F1D1A; box-shadow:0 8px 24px rgba(0,0,0,0.25);">
          <div style="font-size:26px; color:#FF6B00;">🏵</div>
          <div style="text-align:left;">
            <div style="font-size:11px; font-weight:800; text-transform:uppercase; color:#777;">NOVÝ ODZNAK ZÍSKÁN</div>
            <div style="font-size:18px; font-weight:900;">Železná pravidelnost</div>
          </div>
        </div>
      </div>

      <!-- 2. Tempo Up Banner -->
      <div style="width:100%; max-width:540px;">
        <div style="font-size:12px; font-weight:700; color:var(--secondary); text-transform:uppercase; margin-bottom:8px;">2. Pulzující zrychlení tempa (TempoUpBanner)</div>
        <div class="hw-pad hero-pad" style="padding:14px 24px; font-size:22px; font-weight:900; letter-spacing:0.04em; box-shadow:0 0 20px rgba(255,107,0,0.6);">
          ⚡ ZRYCHLENÍ: 80 → 85 BPM
        </div>
      </div>

      <!-- 3. StarBurst Award Moment -->
      <div style="width:100%; max-width:540px;">
        <div style="font-size:12px; font-weight:700; color:var(--secondary); text-transform:uppercase; margin-bottom:8px;">3. Ocenění novou hvězdou (StarBurst Moment)</div>
        <div class="hardware-plate" style="padding:24px; text-align:center; display:flex; flex-direction:column; align-items:center; gap:10px;">
          <div style="font-size:48px; color:var(--theme-orange); filter:drop-shadow(0 0 16px rgba(255,107,0,0.8));">★</div>
          <div style="font-size:20px; font-weight:800;">Druhá hvězda získána!</div>
          <div style="font-size:13px; color:var(--secondary);">Zvládl jsi cílové tempo 110 BPM s přesností 96 %</div>
        </div>
      </div>
    </div>
    """
