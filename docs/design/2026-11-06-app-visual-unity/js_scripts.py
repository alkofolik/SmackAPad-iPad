# JavaScript Logic for Smack-a-Pad App-wide Visual Unity Proposal (Ticket 125)

def get_js():
    return r"""
(function() {
  'use strict';

  // --- AUDIO SYNTHESIS FOR HARDWARE TACTILE FEEDBACK ---
  let audioCtx = null;
  function getAudioContext() {
    if (!audioCtx) {
      const AudioCtxClass = window.AudioContext || window.webkitAudioContext;
      if (AudioCtxClass) {
        audioCtx = new AudioCtxClass();
      }
    }
    if (audioCtx && audioCtx.state === 'suspended') {
      audioCtx.resume();
    }
    return audioCtx;
  }

  function playHardwareClick(freq = 950, decay = 0.025, volume = 0.15) {
    try {
      const ctx = getAudioContext();
      if (!ctx) return;
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      const now = ctx.currentTime;

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, now);
      osc.frequency.exponentialRampToValueAtTime(120, now + decay);

      gain.gain.setValueAtTime(volume, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + decay);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(now);
      osc.stop(now + decay);
    } catch (e) {
      // Audio autoplay policy or unavailable, silent fallback
    }
  }

  // --- APPLICATION STATE ---
  const state = {
    theme: 'light',          // 'light' | 'dark'
    orientation: 'landscape',// 'landscape' | 'portrait'
    device: '11',            // '11' | 'mini' | '10'
    viewMode: 'split',       // 'split' | 'ab' | 'single' | 'gallery'
    screenId: 'practice_play',
    variant: 'B',            // 'A' (Full ribbing) | 'B' (Calm satin)
    zoom: 'fit',             // 'fit' | '100' | '80' | '60'
    isMotionRunning: false
  };

  // --- METADATA OF SCREENS ---
  const SCREEN_DEFS = [
    {
      id: 'practice_play',
      name: 'Cvičení — Režim Hra',
      category: 'practice',
      shortcutKey: '1',
      badge: 'Cvičení',
      description: 'Základní tréninková obrazovka. Oranžový pruh notace tvoří vizuální střed. Tlačítka a přepínače v padovém materiálu, zápustný BPM displej.',
      blocks: ['Klidný satén (Var B)', 'Pad tlačítka 8pt', 'Zápustný displej BPM', 'Segmentové klávesy s LED', 'Mini-pady 4×4']
    },
    {
      id: 'practice_afterme',
      name: 'Cvičení — Režim Po mně',
      category: 'practice',
      shortcutKey: '2',
      badge: 'Cvičení',
      description: 'Dva pruhy: vzor lektora nahoře, stopa hráče dole. Hardwarová přepínací lišta s oranžovým LED proužkem na aktivním režimu.',
      blocks: ['Klidný satén (Var B)', 'Dvojitý pás osnovy', 'Segmentové klávesy s LED', 'Kombinované transportní panely']
    },
    {
      id: 'practice_result',
      name: 'Cvičení — Výsledek (Summary)',
      category: 'practice',
      shortcutKey: '3',
      badge: 'Cvičení',
      description: 'Závěrečný stav po dokončení cvičení. Velké skóre v zápustném panelu, 8pt pad tlačítka "Znovu", "Knihovna" a Hero "Pokračovat".',
      blocks: ['Klidný satén (Var B)', 'Zápustný displej skóre', 'Hero oranžový pad 8pt', 'Hvězdný ukazatel', 'Statistické mini-karty']
    },
    {
      id: 'library',
      name: 'Knihovna skladeb (Library)',
      category: 'library',
      shortcutKey: '4',
      badge: 'Knihovna',
      description: 'Přehled lekcí v rytmických stylech. Levý navigační panel v saténu, karty lekcí jako matné destičky s mikro-fazetou a hvězdami.',
      blocks: ['Saténový panel (Var B)', 'Karty skladeb 8pt', 'Segmentový filtr stylů', 'Pulsní hvězdné ukazatele']
    },
    {
      id: 'training',
      name: 'Trénink (Training roadmap)',
      category: 'library',
      shortcutKey: '5',
      badge: 'Knihovna',
      description: 'Postup v učebním plánu. Úrovňové karty s progress barem, odznaky jako hardwarové medailony na satinované desce.',
      blocks: ['Saténové šasi (Var B)', 'Úrovňové panely 16pt', 'Hardware progress fader', 'Ocelové šrouby na sekcích']
    },
    {
      id: 'today',
      name: 'Dnešní cvičení (Today session)',
      category: 'library',
      shortcutKey: '6',
      badge: 'Denní plán',
      description: 'Kompaktní denní karta cvičení. Masivní středový panel ve stylu hlavní desky Home screenu, výrazné Hero tlačítko "Zahájit".',
      blocks: ['Středová deska 16pt se šrouby', 'Hero oranžový pad', 'Stavový proužek denní řady']
    },
    {
      id: 'badges',
      name: 'Odznaky (Badges grid)',
      category: 'system',
      shortcutKey: '7',
      badge: 'Úspěchy',
      description: 'Mřížka odznaků a milníků. Jednotlivé odznaky zapuštěné v kruhových i čtvercových lůžkách, odemčené svítí oranžovým glow.',
      blocks: ['Matná lůžka odznaků', 'Oranžový elektroluminiscenční glow', 'Filtrovací segmentové klávesy']
    },
    {
      id: 'settings',
      name: 'Nastavení (Settings)',
      category: 'system',
      shortcutKey: '8',
      badge: 'Nastavení',
      description: 'Nastavení aplikace. Hardwarové přepínače s indikační LED diodou, fader drážky pro hlasitost a citlivost, saténové panely.',
      blocks: ['Saténové sekční desky', 'Hardware fader posuvníky', 'Kolébkové přepínače s LED', 'Segmentový přepínač témat']
    },
    {
      id: 'calibration',
      name: 'Kalibrace odezvy (Latency tap)',
      category: 'system',
      shortcutKey: '9',
      badge: 'Hardware',
      description: 'Kalibrace zpoždění externího kontroléru. Zápustný display latence a velký dotykový kalibrační pad reagující na poklepání.',
      blocks: ['Zápustný měřicí displej', 'Velký dotykový kalibrační pad', 'Progress segmenty', 'Ocelové šrouby TL/TR/BL/BR']
    },
    {
      id: 'controller_setup',
      name: 'Nastavení ovladače (Controller)',
      category: 'system',
      shortcutKey: '0',
      badge: 'Hardware',
      description: 'Detekce MIDI hardware a mapování padů. Indikační signální LED, terminálový monitor MIDI zpráv na tmavém skle.',
      blocks: ['Signální hardware LED', 'Terminálový monitor MIDI', 'Testovací matice padů 4×4']
    },
    {
      id: 'about',
      name: 'O aplikaci (About screen)',
      category: 'info',
      badge: 'Informace',
      description: 'Informace o projektu a tvůrci. Kompaktní kovová destička se šrouby, reliéfní logo a padové tlačítko webu.',
      blocks: ['Brushed destička se šrouby', 'Reliéfní logo Smack-a-Pad', 'Ocelový rádius 16pt']
    },
    {
      id: 'purchases',
      name: 'Nákupy (Purchases / Pro)',
      category: 'info',
      badge: 'Informace',
      description: 'Obrazovka nákupu plné verze. Zlatavě tónovaný Hero panel, odemčené funkce v saténovém seznamu, Hero oranžový pad.',
      blocks: ['Zlatavý akcentový rámeček', 'Hero pad tlačítko', 'Saténová deska s mikro-fazetou']
    },
    {
      id: 'intro',
      name: 'Úvodní obrazovka (Intro wizard)',
      category: 'info',
      badge: 'Průvodce',
      description: 'První spuštění aplikace. 3-krokový hardwarový panel s očíslovanými indikátory a velkým startovacím padem.',
      blocks: ['Krokové indikátory', 'Saténová centrální deska', 'Hero tlačítko Začít']
    },
    {
      id: 'banners',
      name: 'Bannery a notifikace (Overlays)',
      category: 'info',
      badge: 'Překryvy',
      description: 'In-game notifikační plovoucí karty: Odemčení odznaku, Zvýšení tempa (+5 BPM), Hvězdný burst a zpětná vazba po cvičení.',
      blocks: ['Plovoucí saténové bannery', 'LED světelné proužky', 'Zápustné okno zpětné vazby']
    }
  ];

  // --- INITIALIZATION ---
  window.addEventListener('DOMContentLoaded', () => {
    initUI();
    bindEvents();
    renderAll();
    setupAutoScaler();
  });

  // --- BUILD TOP BAR & NAVIGATION ---
  function initUI() {
    const selector = document.getElementById('screen-select');
    if (selector) {
      selector.innerHTML = '';
      let currentGroup = null;
      let optgroup = null;

      SCREEN_DEFS.forEach(s => {
        if (s.category !== currentGroup) {
          currentGroup = s.category;
          optgroup = document.createElement('optgroup');
          optgroup.label = getCategoryLabel(currentGroup);
          selector.appendChild(optgroup);
        }
        const opt = document.createElement('option');
        opt.value = s.id;
        opt.textContent = `${s.shortcutKey ? '[' + s.shortcutKey + '] ' : ''}${s.name}`;
        if (s.id === state.screenId) opt.selected = true;
        optgroup.appendChild(opt);
      });
    }

    updateControlsUI();
  }

  function getCategoryLabel(cat) {
    switch(cat) {
      case 'practice': return 'Cvičení (Practice)';
      case 'library': return 'Knihovna a postupy';
      case 'system': return 'Systém a hardware';
      case 'info': return 'Informace a překryvy';
      default: return 'Obrazovky';
    }
  }

  function updateControlsUI() {
    // Theme button
    const btnTheme = document.getElementById('btn-toggle-theme');
    if (btnTheme) {
      btnTheme.innerHTML = state.theme === 'light' 
        ? '<span style="color:#FF6B00;">●</span> Světlý [L]' 
        : '<span style="color:#B3ADA2;">○</span> Tmavý [L]';
    }

    // Orientation button
    const btnOrient = document.getElementById('btn-toggle-orient');
    if (btnOrient) {
      btnOrient.innerHTML = state.orientation === 'landscape'
        ? '<span>▰</span> Na šířku [O]'
        : '<span>▱</span> Na výšku [O]';
    }

    // View mode buttons
    document.querySelectorAll('[data-view-mode]').forEach(btn => {
      const mode = btn.getAttribute('data-view-mode');
      if (mode === state.viewMode) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    // Variant button
    const btnVar = document.getElementById('btn-toggle-variant');
    if (btnVar) {
      btnVar.innerHTML = state.variant === 'A'
        ? '<span style="color:#FF6B00;">A:</span> Žebrování [V]'
        : '<span style="color:#4CAF50;">B:</span> Klidný satén [V]';
    }

    // Update screen selector
    const selector = document.getElementById('screen-select');
    if (selector && selector.value !== state.screenId) {
      selector.value = state.screenId;
    }

    // Update breadcrumb / info banner
    const infoBanner = document.getElementById('active-screen-info');
    if (infoBanner) {
      const def = SCREEN_DEFS.find(s => s.id === state.screenId);
      if (def) {
        const blocksHtml = def.blocks.map(b => `<span class="block-tag">${b}</span>`).join(' ');
        infoBanner.innerHTML = `
          <div style="display:flex; align-items:center; gap:12px; flex-wrap:wrap;">
            <strong style="color:var(--ink); font-size:14px;">${def.name}</strong>
            <span style="color:var(--secondary); font-size:12px;">| ${def.description}</span>
          </div>
          <div style="display:flex; align-items:center; gap:6px; flex-wrap:wrap; margin-top:4px;">
            <span style="font-size:11px; text-transform:uppercase; color:var(--secondary); font-weight:700;">Použité prvky:</span>
            ${blocksHtml}
          </div>
        `;
      }
    }
  }

  // --- EVENT BINDING ---
  function bindEvents() {
    // Screen selector
    const selector = document.getElementById('screen-select');
    if (selector) {
      selector.addEventListener('change', (e) => {
        state.screenId = e.target.value;
        renderAll();
        updateControlsUI();
      });
    }

    // Prev / Next screen buttons
    const btnPrev = document.getElementById('btn-prev-screen');
    if (btnPrev) {
      btnPrev.addEventListener('click', () => navigateScreen(-1));
    }
    const btnNext = document.getElementById('btn-next-screen');
    if (btnNext) {
      btnNext.addEventListener('click', () => navigateScreen(1));
    }

    // Theme toggle
    const btnTheme = document.getElementById('btn-toggle-theme');
    if (btnTheme) {
      btnTheme.addEventListener('click', toggleTheme);
    }

    // Orientation toggle
    const btnOrient = document.getElementById('btn-toggle-orient');
    if (btnOrient) {
      btnOrient.addEventListener('click', toggleOrientation);
    }

    // Variant toggle
    const btnVar = document.getElementById('btn-toggle-variant');
    if (btnVar) {
      btnVar.addEventListener('click', toggleVariant);
    }

    // Motion button
    const btnMotion = document.getElementById('btn-play-motion');
    if (btnMotion) {
      btnMotion.addEventListener('click', runMotionDemo);
    }

    // View mode buttons
    document.querySelectorAll('[data-view-mode]').forEach(btn => {
      btn.addEventListener('click', () => {
        state.viewMode = btn.getAttribute('data-view-mode');
        updateControlsUI();
        renderAll();
      });
    });

    // Device selector
    const deviceSelect = document.getElementById('device-select');
    if (deviceSelect) {
      deviceSelect.addEventListener('change', (e) => {
        state.device = e.target.value;
        renderAll();
      });
    }

    // Zoom buttons
    document.querySelectorAll('[data-zoom]').forEach(btn => {
      btn.addEventListener('click', () => {
        state.zoom = btn.getAttribute('data-zoom');
        document.querySelectorAll('[data-zoom]').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        setupAutoScaler();
      });
    });

    // Keyboard Shortcuts
    window.addEventListener('keydown', (e) => {
      // Don't intercept if user is typing in an input
      if (['INPUT', 'SELECT', 'TEXTAREA'].includes(e.target.tagName)) return;

      const key = e.key.toUpperCase();
      if (key === 'L') {
        e.preventDefault();
        toggleTheme();
      } else if (key === 'O') {
        e.preventDefault();
        toggleOrientation();
      } else if (key === 'M') {
        e.preventDefault();
        runMotionDemo();
      } else if (key === 'V') {
        e.preventDefault();
        toggleVariant();
      } else if (key === 'S') {
        e.preventDefault();
        cycleViewMode();
      } else if (e.key === 'ArrowLeft') {
        e.preventDefault();
        navigateScreen(-1);
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        navigateScreen(1);
      } else {
        // Quick jump via number keys
        const match = SCREEN_DEFS.find(s => s.shortcutKey === e.key);
        if (match) {
          e.preventDefault();
          state.screenId = match.id;
          renderAll();
          updateControlsUI();
        }
      }
    });

    // Window resize: auto fit
    window.addEventListener('resize', debounce(() => {
      setupAutoScaler();
    }, 100));
  }

  function toggleTheme() {
    state.theme = state.theme === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', state.theme);
    updateControlsUI();
  }

  function toggleOrientation() {
    state.orientation = state.orientation === 'landscape' ? 'portrait' : 'landscape';
    renderAll();
    updateControlsUI();
    setupAutoScaler();
  }

  function toggleVariant() {
    state.variant = state.variant === 'A' ? 'B' : 'A';
    renderAll();
    updateControlsUI();
  }

  function cycleViewMode() {
    const modes = ['split', 'ab', 'single', 'gallery'];
    const idx = modes.indexOf(state.viewMode);
    state.viewMode = modes[(idx + 1) % modes.length];
    updateControlsUI();
    renderAll();
  }

  function navigateScreen(dir) {
    const idx = SCREEN_DEFS.findIndex(s => s.id === state.screenId);
    let nextIdx = (idx + dir) % SCREEN_DEFS.length;
    if (nextIdx < 0) nextIdx = SCREEN_DEFS.length - 1;
    state.screenId = SCREEN_DEFS[nextIdx].id;
    renderAll();
    updateControlsUI();
  }

  // --- RENDER STAGE (SPLIT, A/B, SINGLE, GALLERY) ---
  function renderAll() {
    const stage = document.getElementById('viewport-stage');
    if (!stage) return;

    // Apply global theme
    document.documentElement.setAttribute('data-theme', state.theme);

    if (state.viewMode === 'split') {
      renderSplitMode(stage);
    } else if (state.viewMode === 'ab') {
      renderABMode(stage);
    } else if (state.viewMode === 'single') {
      renderSingleMode(stage);
    } else if (state.viewMode === 'gallery') {
      renderGalleryMode(stage);
    }

    // Attach interactive clicks on buttons, pads, segmented keys
    bindChassisInteractions();
    setupAutoScaler();
  }

  function buildChassisMarkup(screenId, forcedVariant = null, label = '', isHome = false) {
    const variant = forcedVariant || state.variant;
    const templateFn = window.SP_TEMPLATES[screenId] || window.SP_TEMPLATES['practice_play'];
    const htmlContent = templateFn();

    const variantBadge = isHome 
      ? '<span class="chassis-tag"><span class="indicator-dot"></span>REFERENCE HOME</span>'
      : (variant === 'A' 
          ? '<span class="chassis-tag" style="background:#553010; border:1px solid #FF6B00;"><span class="indicator-dot"></span>VARIANTA A: ŽEBROVÁNÍ (4pt)</span>'
          : '<span class="chassis-tag" style="background:#153520; border:1px solid #4CAF50;"><span class="indicator-dot" style="background:#4CAF50;"></span>VARIANTA B: KLIDNÝ SATÉN</span>');

    return `
      <div class="stage-chassis-column">
        <div class="stage-chassis-header">
          <div style="font-weight:700; font-size:13px; color:#FFF; display:flex; align-items:center; gap:8px;">
            ${label}
          </div>
          <div>${variantBadge}</div>
        </div>
        <div class="ipad-chassis device-${state.device} ${state.orientation} ${variant === 'B' ? 'variant-b' : ''}" data-variant="${variant}">
          <div class="chassis-ribbing-layer"></div>
          <div class="chassis-speckle-layer"></div>
          <div class="chassis-vignette-layer"></div>
          <div class="screen-wrapper" style="position:relative; width:100%; height:100%;">
            ${htmlContent}
          </div>
        </div>
      </div>
    `;
  }

  function renderSplitMode(stage) {
    const activeDef = SCREEN_DEFS.find(s => s.id === state.screenId) || SCREEN_DEFS[0];
    stage.className = 'viewport-stage mode-split';
    stage.innerHTML = `
      <div class="chassis-scaler" id="chassis-scaler">
        <div class="split-columns-container" style="display:flex; gap:36px; align-items:center; justify-content:center;">
          ${buildChassisMarkup('home', 'A', '1. REFERENCE: HOME SCREEN (Neměnný etalon)', true)}
          ${buildChassisMarkup(state.screenId, state.variant, `2. NÁVRH: ${activeDef.name.toUpperCase()}`, false)}
        </div>
      </div>
    `;
  }

  function renderABMode(stage) {
    const activeDef = SCREEN_DEFS.find(s => s.id === state.screenId) || SCREEN_DEFS[0];
    stage.className = 'viewport-stage mode-ab';
    stage.innerHTML = `
      <div class="chassis-scaler" id="chassis-scaler">
        <div class="split-columns-container" style="display:flex; gap:36px; align-items:center; justify-content:center;">
          ${buildChassisMarkup(state.screenId, 'A', `${activeDef.name.toUpperCase()} — VARIANTA A (ŽEBROVANÉ ŠASI)`, false)}
          ${buildChassisMarkup(state.screenId, 'B', `${activeDef.name.toUpperCase()} — VARIANTA B (KLIDNÝ SATÉN)`, false)}
        </div>
      </div>
    `;
  }

  function renderSingleMode(stage) {
    const activeDef = SCREEN_DEFS.find(s => s.id === state.screenId) || SCREEN_DEFS[0];
    stage.className = 'viewport-stage mode-single';
    stage.innerHTML = `
      <div class="chassis-scaler" id="chassis-scaler">
        <div style="display:flex; justify-content:center;">
          ${buildChassisMarkup(state.screenId, state.variant, activeDef.name.toUpperCase(), false)}
        </div>
      </div>
    `;
  }

  function renderGalleryMode(stage) {
    stage.className = 'viewport-stage mode-gallery';
    let cardsHtml = '';

    SCREEN_DEFS.forEach(def => {
      const isHome = def.id === 'home';
      cardsHtml += `
        <div class="gallery-card" data-screen="${def.id}">
          <div class="gallery-card-title">
            <span>${def.name}</span>
            <span class="block-tag">${def.badge}</span>
          </div>
          <div class="gallery-card-preview">
            <div class="ipad-chassis device-${state.device} landscape ${state.variant === 'B' ? 'variant-b' : ''}" style="transform:scale(0.32); transform-origin:top left; pointer-events:none; position:absolute; top:12px; left:12px;">
              <div class="chassis-ribbing-layer"></div>
              <div class="chassis-speckle-layer"></div>
              <div class="chassis-vignette-layer"></div>
              <div class="screen-wrapper" style="position:relative; width:100%; height:100%;">
                ${(window.SP_TEMPLATES[def.id] || window.SP_TEMPLATES['practice_play'])()}
              </div>
            </div>
          </div>
          <div style="font-size:11px; color:#A1A1AA; line-height:1.3;">
            ${def.description}
          </div>
        </div>
      `;
    });

    stage.innerHTML = `
      <div class="gallery-grid">
        ${cardsHtml}
      </div>
    `;

    // Click on gallery card jumps to split view
    stage.querySelectorAll('.gallery-card').forEach(card => {
      card.addEventListener('click', () => {
        state.screenId = card.getAttribute('data-screen');
        state.viewMode = 'split';
        updateControlsUI();
        renderAll();
      });
    });
  }

  // --- BIND LIVE HARDWARE INTERACTIONS ---
  function bindChassisInteractions() {
    // 1. Pad & Button Press with Tactile Click Sound
    const pressables = document.querySelectorAll(
      '.hw-pad, .hw-pad-btn, .action-pad-btn, .library-card, .tp-pad, .nav-item, .fader-channel, .btn-mode-key'
    );

    pressables.forEach(el => {
      el.addEventListener('pointerdown', (e) => {
        el.classList.add('is-active-press');
        playHardwareClick(900, 0.025, 0.2);

        // Flash overlay if present
        const flash = el.querySelector('.flash-overlay');
        if (flash) {
          flash.style.opacity = '1';
          setTimeout(() => { flash.style.opacity = '0'; }, 120);
        }
      });

      el.addEventListener('pointerup', () => {
        setTimeout(() => el.classList.remove('is-active-press'), 100);
      });
      el.addEventListener('pointerleave', () => {
        el.classList.remove('is-active-press');
      });
    });

    // 2. Segmented Mode Keys Switching (Poslech / Hra / Po mně)
    const modeKeys = document.querySelectorAll('.btn-mode-key');
    modeKeys.forEach(btn => {
      btn.addEventListener('click', () => {
        const group = btn.closest('.hw-key-group');
        if (group) {
          group.querySelectorAll('.btn-mode-key').forEach(b => {
            b.classList.remove('active');
            const bar = b.querySelector('.key-light-bar');
            if (bar) bar.remove();
          });
          btn.classList.add('active');
          const bar = document.createElement('div');
          bar.className = 'key-light-bar';
          btn.appendChild(bar);
          playHardwareClick(1150, 0.02, 0.15);
        }
      });
    });

    // 3. Calibration TAP pad counter
    const calibPad = document.getElementById('calib-tap-target');
    if (calibPad) {
      let taps = 7;
      calibPad.addEventListener('click', () => {
        taps++;
        if (taps > 10) taps = 1;
        playHardwareClick(800, 0.035, 0.25);

        const lbl = document.getElementById('calib-progress-label');
        if (lbl) lbl.textContent = `${taps} / 10`;

        const fill = document.getElementById('calib-progress-fill');
        if (fill) fill.style.width = `${(taps / 10) * 100}%`;

        const offsets = [-14, -12, -15, -13, -11, -14, -12, -13, -14, -12];
        const val = offsets[(taps - 1) % offsets.length];
        const stat = document.getElementById('calib-current-offset');
        if (stat) stat.textContent = `${val > 0 ? '+' : ''}${val} ms`;

        if (taps === 10) {
          const alert = document.getElementById('calib-status-msg');
          if (alert) {
            alert.textContent = 'Kalibrace dokončena! Naměřeno -12 ms (stabilní jitter ±1.2 ms).';
            alert.style.color = 'var(--theme-mark-correct)';
          }
        }
      });
    }

    // 4. BPM Stepper adjustments
    const bpmDisplay = document.getElementById('bpm-display-val');
    const bpmMinus = document.getElementById('bpm-btn-minus');
    const bpmPlus = document.getElementById('bpm-btn-plus');

    if (bpmDisplay && bpmMinus && bpmPlus) {
      bpmMinus.addEventListener('click', () => {
        let val = parseInt(bpmDisplay.textContent, 10) || 120;
        if (val > 40) val--;
        bpmDisplay.textContent = val;
        playHardwareClick(750, 0.02, 0.15);
      });
      bpmPlus.addEventListener('click', () => {
        let val = parseInt(bpmDisplay.textContent, 10) || 120;
        if (val < 240) val++;
        bpmDisplay.textContent = val;
        playHardwareClick(1050, 0.02, 0.15);
      });
    }
  }

  // --- MOTION DEMO RUNNER [M] ---
  function runMotionDemo() {
    if (state.isMotionRunning) return;
    state.isMotionRunning = true;

    const btn = document.getElementById('btn-play-motion');
    const origHtml = btn ? btn.innerHTML : '';
    if (btn) btn.innerHTML = '<span style="color:#FF6B00;">⚡</span> Přehrávání animací...';

    // Sequence of animations:
    // 1. Stagger entrance of plates and cards
    const cards = document.querySelectorAll('.hardware-plate, .hardware-plate-satin, .library-card, .training-row');
    cards.forEach((c, idx) => {
      c.style.transition = 'transform 0.3s cubic-bezier(0.16, 1, 0.3, 1), opacity 0.3s ease';
      c.style.transform = 'translateY(8px)';
      c.style.opacity = '0.6';
      setTimeout(() => {
        c.style.transform = 'translateY(0)';
        c.style.opacity = '1';
      }, idx * 40);
    });

    // 2. Play rhythmic pad taps (Home & Practice)
    setTimeout(() => {
      const pads = document.querySelectorAll('.hw-pad, .hw-pad-btn');
      const rhythmSequence = [0, 2, 4, 1, 3, 5, 0];
      rhythmSequence.forEach((padIndex, step) => {
        setTimeout(() => {
          if (pads[padIndex]) {
            pads[padIndex].classList.add('is-active-press');
            playHardwareClick(880 + step * 40, 0.03, 0.22);
            setTimeout(() => pads[padIndex].classList.remove('is-active-press'), 120);
          }
        }, step * 180);
      });
    }, 300);

    // 3. Roll BPM or Score
    setTimeout(() => {
      const bpmEl = document.getElementById('bpm-display-val');
      if (bpmEl) {
        animateNumberRoll(bpmEl, 120, 126, 600);
      }
      const scoreEl = document.getElementById('summary-score-num');
      if (scoreEl) {
        animateNumberRoll(scoreEl, 74, 94, 700, '%');
      }
    }, 700);

    // 4. Gliding segmented key switch
    setTimeout(() => {
      const keys = document.querySelectorAll('.btn-mode-key');
      if (keys.length >= 3) {
        // Switch to next key
        keys[0].classList.remove('active');
        const b0 = keys[0].querySelector('.key-light-bar');
        if (b0) b0.remove();

        keys[1].classList.add('active');
        const b1 = document.createElement('div');
        b1.className = 'key-light-bar';
        keys[1].appendChild(b1);
        playHardwareClick(1200, 0.025, 0.18);

        setTimeout(() => {
          keys[1].classList.remove('active');
          b1.remove();
          keys[2].classList.add('active');
          const b2 = document.createElement('div');
          b2.className = 'key-light-bar';
          keys[2].appendChild(b2);
          playHardwareClick(1300, 0.025, 0.18);
        }, 350);
      }
    }, 1100);

    // 5. Light bar breathing pulse
    const lightBars = document.querySelectorAll('.key-light-bar, .active-light-bar');
    lightBars.forEach(b => {
      b.style.animation = 'lightBarBreathing 1.2s ease-in-out infinite alternate';
    });

    // Reset button after demo completes
    setTimeout(() => {
      state.isMotionRunning = false;
      if (btn) btn.innerHTML = origHtml;
    }, 2200);
  }

  function animateNumberRoll(el, start, end, duration, suffix = '') {
    const startTime = performance.now();
    function update(now) {
      const progress = Math.min((now - startTime) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      const current = Math.round(start + (end - start) * eased);
      el.textContent = `${current}${suffix}`;
      if (progress < 1) {
        requestAnimationFrame(update);
      }
    }
    requestAnimationFrame(update);
  }

  // --- RESPONSIVE AUTO-SCALER (FIT TO WORKBENCH) ---
  function setupAutoScaler() {
    if (state.viewMode === 'gallery') return;

    const scaler = document.getElementById('chassis-scaler');
    const viewport = document.querySelector('.workbench-viewport');
    if (!scaler || !viewport) return;

    if (state.zoom !== 'auto' && state.zoom !== 'fit') {
      const scaleNum = parseFloat(state.zoom) / 100;
      scaler.style.transform = `scale(${scaleNum})`;
      scaler.style.transformOrigin = 'top center';
      return;
    }

    // Available viewport space (leaving padding for header & margin)
    const availWidth = viewport.clientWidth - 48;
    const availHeight = viewport.clientHeight - 48;

    // Dimensions of unscaled content
    const container = scaler.querySelector('.split-columns-container') || scaler.firstElementChild;
    if (!container) return;

    const isSplit = state.viewMode === 'split' || state.viewMode === 'ab';
    const isPortrait = state.orientation === 'portrait';

    let baseWidth, baseHeight;
    if (state.device === 'mini') {
      baseWidth = isPortrait ? 744 : 1133;
      baseHeight = isPortrait ? 1133 : 744;
    } else if (state.device === '10') {
      baseWidth = isPortrait ? 820 : 1180;
      baseHeight = isPortrait ? 1180 : 820;
    } else {
      // 11"
      baseWidth = isPortrait ? 834 : 1194;
      baseHeight = isPortrait ? 1194 : 834;
    }

    let totalWidth = isSplit ? (baseWidth * 2 + 36) : baseWidth;
    let totalHeight = baseHeight + 50; // chassis header + padding

    const scaleX = availWidth / totalWidth;
    const scaleY = availHeight / totalHeight;
    const finalScale = Math.min(scaleX, scaleY, 1.0); // max 100%

    scaler.style.transform = `scale(${Math.max(finalScale, 0.25)})`;
    scaler.style.transformOrigin = 'top center';
  }

  function debounce(fn, ms) {
    let timer;
    return function(...args) {
      clearTimeout(timer);
      timer = setTimeout(() => fn.apply(this, args), ms);
    };
  }

})();
"""
