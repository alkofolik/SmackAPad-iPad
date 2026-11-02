"""Build review-only HTML/SVG scenes shared with the native PNG renderer."""
from pathlib import Path
import base64
import html
import json
import math

ROOT = Path(__file__).resolve().parent
ORANGE = '#F47B20'
VARIANTS = {
    'a': ('Cut Tape / Open rail', 'One hit lane. Beats above. Stars at the upper right.', 28),
    'b': ('Cut Tape / Split tracks', 'Hi-hat above kick/snare. Stars at the upper left.', 32),
    'c': ('Cut Tape / Wide cut', 'Hits above the beat rail. Stars below the tape.', 40),
}
STATES = [('idle', 'Ready', 'White tiles; no edge signal.'),
          ('running', 'Playing', 'Played tiles retain their tint.'),
          ('countin', 'Count-in', 'One large numeral; four pulses.'),
          ('end1', 'One star', 'Next: Další lekce.'),
          ('end2', 'Two stars', 'Next: Z paměti o ★3.'),
          ('end3', 'Three stars', '100 % plus the full caption.'),
          ('award', 'Star earned', 'Second star, at the scale peak.')]


class Scene:
    def __init__(self, width, height, dark=False):
        self.width, self.height, self.dark = width, height, dark
        self.bg = '#000000' if dark else '#FFFFFF'
        self.ink = '#FFFFFF' if dark else '#000000'
        self.star_tone = 'bright' if dark else 'orange'
        self.tone = 'white' if dark else 'black'
        self.items = []
        self.rect(0, 0, width, height, self.bg)

    def add(self, kind, **kwargs):
        self.items.append(dict(type=kind, **kwargs))

    def rect(self, x, y, w, h, fill, r=0, **kw):
        self.add('rect', x=x, y=y, w=w, h=h, r=r, fill=fill, **kw)

    def line(self, x, y, x2, y2, fill, stroke=1, **kw):
        self.add('line', x=x, y=y, x2=x2, y2=y2, fill=fill, stroke=stroke, **kw)

    def text(self, x, y, text, size=16, weight=400, fill=None, align='left', **kw):
        self.add('text', x=x, y=y, text=text, size=size, weight=weight,
                 fill=fill or self.ink, align=align, **kw)

    def image(self, x, y, src, size=44, **kw):
        self.add('image', x=x, y=y, w=size, h=size, src=src, **kw)

    def stars(self, x, y, earned, size=44, award=False):
        self.add('group-start', cls='star-rules', label='Pravidla hvězd', role='button')
        for i in range(3):
            src = f'star-fill-{self.star_tone}.png' if i < earned else f'star-{self.tone}.png'
            if award and i == earned - 1:
                self.add('group-start', cls='new-star')
                self.image(x + i * 48 - size * .04, y - size * .04, src, size * 1.08)
                self.add('group-end')
            else:
                self.image(x + i * 48, y, src, size)
        self.add('group-end')

    def detail(self, x, y):
        self.add('group-start', cls='detail-button', label='Detail', role='button')
        self.image(x, y, f'detail-{self.tone}.png', 48)
        self.add('group-end')

    def band(self, x, y, w, h, variant, state, progress=True, tempo=80, listen=False, side='both'):
        radius = VARIANTS[variant][2]
        fill = '#FFC18B' if listen else {60: '#FFA45D', 80: ORANGE, 110: '#E96C10'}[tempo]
        self.rect(x, y, w, h, fill, radius)
        self.add('clip-start', x=x, y=y, w=w, h=h, r=radius)
        if state == 'countin':
            self.add('group-start', cls='count-number')
            self.text(x + w / 2, y + h / 2 - 66, '3', 112, 600, '#000000', 'center')
            self.add('group-end')
        else:
            if variant == 'c':
                self.rect(x, y + h - 54, w, 54, '#FFAE6E')
            self.add('group-start', cls='tape-motion' if state == 'running' else 'tape-still')
            beat = 240
            offset = 54
            for i in range(10):
                bx = x + offset + i * beat
                if i and i % 4 == 0:
                    self.line(bx - 29, y + 20, bx - 29, y + h - 20, '#FFFFFF', 1.5, opacity=.9)
                else:
                    self.line(bx - 29, y + 24, bx - 29, y + h - 24, '#000000', .75, opacity=.19)
                ny = y + h - 49 if variant == 'c' else y + 9
                self.text(bx, ny, str(i % 4 + 1), 30, 600, '#000000')
                doty = ny + 22
                for sub in range(1, 4):
                    self.rect(bx + sub * 60 + 8, doty, 4, 4, '#000000', 2, opacity=.65)
                for sub, pad in [(0, 'KD' if i % 2 == 0 else 'SD'), (1, 'HH'), (2, 'HH'), (3, 'HH')]:
                    tx = bx + sub * 60 - 8
                    ty = y + (48 if variant == 'c' else 65)
                    th = 48
                    if variant == 'b':
                        th = 36
                        ty = y + (92 if sub == 0 else 49)
                    played = state != 'idle' and (i % 4 < 1 or (i % 4 == 1 and sub < 2))
                    tile = ('#FFE1C7' if sub % 2 else '#FFBC84') if played else '#FFFFFF'
                    self.rect(tx, ty, 48, th, tile, 10)
                    self.text(tx + 24, ty + (th - 22) / 2 - 1, pad, 16, 600, '#000000', 'center')
                    if played:
                        self.line(tx + 16, ty + th - 6, tx + 32, ty + th - 6, '#000000', 1.2, opacity=.65)
            self.add('group-end')
            if state == 'running':
                for edge in (['left', 'right'] if side == 'both' else [side]):
                    self.add('glow', x=x, y=y, w=w, h=h, r=radius, side=edge, fill='#FFE0BD')
            # The marker is stationary; timeline content passes underneath it.
            self.line(x + 333, y + 14, x + 333, y + h - 17, '#000000', 1.5)
            self.rect(x + 329.5, y + 8, 7, 7, '#000000', 3.5)
        if progress:
            self.line(x + 32, y + h - 9, x + w - 32, y + h - 9, '#000000', 1, opacity=.22)
            self.line(x + 32, y + h - 9, x + 32 + (w - 64) * .42, y + h - 9, '#000000', 1)
        self.add('clip-end')

    def result(self, x, y, w, variant, earned, award=False):
        percent = '100 %' if earned == 3 else ('96 %' if earned == 2 else '87 %')
        action = 'Z paměti o ★3' if earned == 2 else 'Další lekce'
        # The accuracy block reserves 260 pt even when only two digits are shown.
        if variant == 'c':
            self.text(x + 245, y - 2, percent, 64, 600, align='center')
            self.text(x + 245, y + 71, 'Přesnost', 18, align='center')
            self.stars(x + 173, y + 102, earned, award=award)
            by = y + 45
            self.detail(x + w - 60, by + 2)
            bx, bw = x + w - 410, 316
        elif variant == 'b':
            self.text(x + 24, y - 2, percent, 68, 600)
            self.text(x + 27, y + 74, 'Přesnost', 18)
            self.stars(x + 348, y + 33, earned, award=award)
            self.detail(x + 524, y + 31)
            bx, bw, by = x + w - 332, 304, y + 29
        else:
            self.text(x + 24, y, percent, 64, 600)
            self.text(x + 27, y + 73, 'Přesnost', 18)
            self.stars(x + 350, y + 25, earned, award=award)
            self.detail(x + 526, y + 23)
            bx, bw, by = x + w - 332, 304, y + 21
        self.add('group-start', cls='next-button', label=action, role='button')
        self.rect(bx, by, bw, 56, self.ink, 28)
        self.text(bx + bw / 2, by + 14, action, 21, 600, self.bg, 'center')
        self.add('group-end')

    def component(self, x, y, w, variant, state):
        ended = state.startswith('end') or state == 'award'
        header = 46
        self.image(x + 4, y, f'back-{self.tone}.png', 44)
        tempo_x = x + 65
        if variant == 'b':
            tempo_x = x + w - 130
        self.text(tempo_x, y + 11, '80 BPM', 18, 600)
        if not ended and variant != 'c':
            self.stars(x + (62 if variant == 'b' else w - 150), y, 1)
        bh = 148
        self.band(x, y + header, w, bh, variant, state, progress=state != 'countin')
        if ended:
            earned = 2 if state == 'award' else int(state[-1])
            self.result(x, y + header + bh + 12, w, variant, earned, state == 'award')
        elif variant == 'c':
            self.stars(x + w / 2 - 72, y + header + bh + 12, 1)

    def compact_result(self, x, y, w, variant, large=False):
        if large:
            self.text(x + 24, y, '100 %', 128, 600)
            self.text(x + 28, y + 150, 'Přesnost', 36)
            self.stars(x + 24, y + 214, 3)
            self.detail(x + w - 72, y + 212)
            by = y + 280
        elif variant == 'c':
            self.text(x + w / 2, y, '100 %', 64, 600, align='center')
            self.text(x + w / 2, y + 74, 'Přesnost', 18, align='center')
            self.stars(x + w / 2 - 72, y + 106, 3)
            self.detail(x + w - 72, y + 12)
            by = y + 168
        else:
            self.text(x + 24, y, '100 %', 64, 600)
            self.text(x + 28, y + 74, 'Přesnost', 18)
            self.stars(x + w - 256, y + 24, 3)
            self.detail(x + w - 72, y + 22)
            by = y + 116
        self.rect(x + 24, by, w - 48, 56 if not large else 72, self.ink, 28 if not large else 36)
        self.text(x + w / 2, by + 14, 'Další lekce', 21 if not large else 30, 600, self.bg, 'center')

    def save(self, name):
        payload = dict(width=self.width, height=self.height, items=self.items)
        (ROOT / f'{name}.json').write_text(json.dumps(payload), encoding='utf-8')
        svg = self.svg(name)
        (ROOT / f'{name}.svg').write_text(svg, encoding='utf-8')
        return svg

    def svg(self, name):
        out = [f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="{self.width}" height="{self.height}" viewBox="0 0 {self.width} {self.height}" role="img" aria-label="{name}">']
        index = 0
        for a in self.items:
            kind = a['type']
            op = f' opacity="{a.get("opacity", 1)}"'
            fill = f' fill="{a.get("fill", "#000000")}"'
            if kind == 'rect':
                out.append(f'<rect x="{a["x"]}" y="{a["y"]}" width="{a["w"]}" height="{a["h"]}" rx="{a["r"]}"{fill}{op}/>')
            elif kind == 'line':
                out.append(f'<line x1="{a["x"]}" y1="{a["y"]}" x2="{a["x2"]}" y2="{a["y2"]}" stroke="{a["fill"]}" stroke-width="{a["stroke"]}" stroke-linecap="round"{op}/>')
            elif kind == 'text':
                anchor = {'left': 'start', 'right': 'end', 'center': 'middle'}[a['align']]
                out.append(f'<text x="{a["x"]}" y="{a["y"]}" dominant-baseline="text-before-edge" text-anchor="{anchor}" font-family="-apple-system,BlinkMacSystemFont,Helvetica,Arial,sans-serif" font-size="{a["size"]}" font-weight="{a["weight"]}" style="font-variant-numeric:tabular-nums"{fill}{op}>{html.escape(a["text"])}</text>')
            elif kind == 'image':
                data = base64.b64encode((ROOT / a['src']).read_bytes()).decode()
                out.append(f'<image x="{a["x"]}" y="{a["y"]}" width="{a["w"]}" height="{a["h"]}" href="data:image/png;base64,{data}"/>')
            elif kind == 'group-start':
                role = f' role="{a["role"]}" tabindex="0" aria-label="{html.escape(a["label"])}"' if a.get('role') else ''
                out.append(f'<g class="{a["cls"]}"{role}>')
            elif kind == 'group-end':
                out.append('</g>')
            elif kind == 'clip-start':
                index += 1
                out.append(f'<defs><clipPath id="{name}-clip-{index}"><rect x="{a["x"]}" y="{a["y"]}" width="{a["w"]}" height="{a["h"]}" rx="{a["r"]}"/></clipPath></defs><g clip-path="url(#{name}-clip-{index})">')
            elif kind == 'clip-end':
                out.append('</g>')
            elif kind == 'glow':
                index += 1
                left = a['side'] == 'left'
                x = a['x'] if left else a['x'] + a['w'] - 80
                out.append(f'<defs><linearGradient id="{name}-glow-{index}" x1="{0 if left else 1}" x2="{1 if left else 0}" y1="0" y2="0"><stop stop-color="{a["fill"]}" stop-opacity=".8"/><stop offset="1" stop-color="{a["fill"]}" stop-opacity="0"/></linearGradient></defs><rect x="{x}" y="{a["y"]}" width="80" height="{a["h"]}" fill="url(#{name}-glow-{index})"/>')
        out.append('</svg>')
        return ''.join(out)


boards = []
for key, (title, description, radius) in VARIANTS.items():
    for dark in (False, True):
        theme = 'dark' if dark else 'light'
        scene = Scene(1440, 2760, dark)
        scene.text(44, 32, title, 38, 600)
        scene.text(44, 86, description, 19)
        scene.text(1396, 45, theme.capitalize(), 20, align='right')
        for i, (state, label, note) in enumerate(STATES):
            y = 155 + i * 357
            scene.text(44, y + 42, label, 23, 600)
            # Review annotations live outside the app crop.
            for j, text in enumerate(note.split('; ')):
                words = text.split()
                lines, line = [], ''
                for word in words:
                    if len(line + ' ' + word) > 22:
                        lines.append(line)
                        line = word
                    else:
                        line = (line + ' ' + word).strip()
                lines.append(line)
                for k, textline in enumerate(lines):
                    scene.text(44, y + 82 + (j * 2 + k) * 23, textline, 16)
            scene.component(244, y, 1152, key, state)
        scene.text(44, 2693, 'Review prototype · pt-sized geometry · SF Symbols Regular · no application changes', 17)
        name = f'{key}-{theme}'
        boards.append((key, theme, scene.save(name)))

# A small, readable comparison for the first review, in both appearances.
comparison = Scene(1440, 1470)
comparison.text(40, 26, 'Cut Tape — three directions', 38, 600)
comparison.text(40, 78, 'Same palette and behavior. Different hierarchy. A is recommended.', 20)
for i, key in enumerate(VARIANTS):
    yy = 132 + i * 436
    comparison.text(40, yy, VARIANTS[key][0], 26, 600)
    comparison.component(40, yy + 46, 1040, key, 'running')
    # A compact dark result at the right identifies the state of all three stars.
    comparison.rect(1120, yy + 46, 280, 342, '#000000', 24)
    comparison.text(1260, yy + 74, '100 %', 56, 600, '#FFFFFF', 'center')
    comparison.text(1260, yy + 145, 'Přesnost', 18, fill='#FFFFFF', align='center')
    comparison.add('group-start', cls='star-rules', label='Pravidla hvězd', role='button')
    for j in range(3):
        comparison.image(1186 + j * 48, yy + 182, 'star-fill-bright.png')
    comparison.add('group-end')
    comparison.image(1236, yy + 244, 'detail-white.png', 48)
    comparison.rect(1140, yy + 310, 240, 56, '#FFFFFF', 28)
    comparison.text(1260, yy + 325, 'Další lekce', 20, 600, '#000000', 'center')
comparison.text(40, 1440, 'Illustrative lesson, pad abbreviations and results. Full state boards in the HTML.', 16)
comparison.save('comparison')

# Explicit preservation sheet: tempo, Listen, loop continuity, and single-bar omission.
for dark in (False, True):
    theme = 'dark' if dark else 'light'
    s = Scene(1440, 1490, dark)
    s.text(44, 32, 'Signals that stay', 38, 600)
    s.text(44, 91, 'Functional edge light only. No decorative glow, texture, or surface gradient.', 20)
    signals = [('Tempo · 60 BPM', 60, False, 'idle', True),
               ('Tempo · 80 BPM', 80, False, 'idle', True),
               ('Tempo · 110 BPM', 110, False, 'idle', True),
               ('Listen · 80 BPM', 80, True, 'idle', True),
               ('Single-bar lesson', 80, False, 'idle', False),
               ('Loop seam · retained feedback', 80, False, 'running', True)]
    for i, (label, tempo, listen, state, progress) in enumerate(signals):
        y = 160 + i * 207
        s.text(44, y, label, 23, 600)
        s.band(416, y - 7, 980, 148, 'a', state, progress, tempo, listen)
    s.text(44, 1435, 'Loop: keep feedback by event identity; fade offscreen. Existing edge-side meanings remain unchanged.', 17)
    s.save(f'signals-{theme}')

for dark in (False, True):
    theme = 'dark' if dark else 'light'
    s = Scene(1440, 1480, dark)
    s.text(44, 32, '100 % must fit', 38, 600)
    s.text(44, 92, '696 pt content width · 744 pt viewport minus two 24 pt margins · full-size type', 20)
    for i, key in enumerate(VARIANTS):
        y = 165 + i * 270
        s.text(44, y + 32, VARIANTS[key][0], 23, 600)
        s.text(44, y + 74, 'Wrap the panel, never the value.', 17)
        s.compact_result(600, y, 696, key)
    s.text(44, 1055, 'A · 200% text', 23, 600)
    s.text(44, 1097, 'Give the number its own row.', 17)
    s.text(44, 1123, 'Keep the complete caption.', 17)
    s.compact_result(600, 1020, 696, 'a', large=True)
    s.text(44, 1430, 'Layout proofs, not raster scaling. All values use tabular numerals and a nonbreaking value/unit pair.', 17)
    s.save(f'fit-{theme}')

page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Smack-a-Pad · Cut Tape proposals</title><style>
*{box-sizing:border-box}body{margin:0;background:white;color:black;font:17px/1.5 -apple-system,BlinkMacSystemFont,Arial,sans-serif}
header,main,footer{max-width:1440px;margin:auto;padding:24px 32px}h1{font-size:32px;line-height:1.15;margin:0 0 14px}p{max-width:900px}
nav{display:flex;gap:12px;flex-wrap:wrap;align-items:center}button,select{font:inherit;min-height:44px;padding:8px 16px;border:1px solid currentColor;background:inherit;color:inherit;border-radius:0}
button{cursor:pointer}button[aria-pressed=true]{background:black;color:white}a{color:inherit}svg{width:100%;height:auto;display:block}article[hidden]{display:none}
body.dark{background:black;color:white}body.dark button[aria-pressed=true]{background:white;color:black}
g[role=button]{cursor:pointer}g[role=button]:focus-visible{outline:2px solid #D85D00;outline-offset:3px}
.animating .tape-motion{animation:scrollTape 12s linear infinite}.animating .new-star{transform-box:fill-box;transform-origin:center;animation:earn .48s ease-out 1}
@keyframes scrollTape{from{transform:translateX(0)}to{transform:translateX(-960px)}}
@keyframes earn{0%{transform:scale(.80);opacity:.5}40%{transform:scale(1);opacity:1}100%{transform:scale(.9259);opacity:1}}
@media(prefers-reduced-motion:reduce){.animating .tape-motion,.animating .new-star{animation:none}}
dialog{max-width:560px;background:inherit;color:inherit;border:1px solid currentColor;padding:28px}dialog::backdrop{background:#0009}
#notice{min-height:28px}footer{font-size:15px} main{padding-top:0}
</style><header><h1>Cut Tape · band, stars, Detail</h1>
<p>Review-only component crops, not a new practice-screen layout. Choose a direction and appearance. PNG boards freeze the same scenes. All captions outside the crops are review annotations.</p>
<nav aria-label="Review controls"><button data-v="a" aria-pressed="true">A · Open rail</button><button data-v="b" aria-pressed="false">B · Split tracks</button><button data-v="c" aria-pressed="false">C · Wide cut</button><button id="theme" aria-pressed="false">Dark appearance</button><button id="motion" aria-pressed="false">Play motion</button><button data-v="signals" aria-pressed="false">Preserved signals</button><button data-v="fit" aria-pressed="false">100 % · fit checks</button></nav>
<p id="notice" role="status">A is recommended: one lane keeps the pattern easiest to scan.</p></header><main>'''
for key, theme, svg in boards:
    page += f'<article data-variant="{key}" data-theme="{theme}" hidden>{svg}</article>'
for key in ('signals', 'fit'):
    for theme in ('light', 'dark'):
        svg = (ROOT / f'{key}-{theme}.svg').read_text()
        page += f'<article data-variant="{key}" data-theme="{theme}" hidden>{svg}</article>'
page += '''</main><footer>Static sample: a two-bar sixteenth-note lesson at 80 BPM. Results are illustrative, not new thresholds. Stars: tap or hold for existing rules. Detail only demonstrates its accessible hit area. Motion can be paused; system Reduce Motion is respected. Opening this file does not access the application.</footer>
<dialog id="rules"><h2>Pravidla hvězd</h2><p>★1 · Stávající pravidla pro první hvězdu.<br>★2 · Cílové tempo.<br>★3 · Z paměti.</p><p>Návrh mění vzhled, nikoli pravidla získání hvězd. Přesné znění zůstává podle aplikace.</p><button id="close">Zavřít</button></dialog>
<script>
let variant='a',dark=false,moving=false;
const $=s=>document.querySelector(s);
function show(){document.querySelectorAll('article').forEach(a=>a.hidden=a.dataset.variant!==variant||a.dataset.theme!==(dark?'dark':'light'));document.body.classList.toggle('dark',dark);document.body.classList.toggle('animating',moving);document.querySelectorAll('[data-v]').forEach(b=>b.setAttribute('aria-pressed',b.dataset.v===variant));$('#theme').setAttribute('aria-pressed',dark);$('#motion').setAttribute('aria-pressed',moving);$('#motion').textContent=moving?'Pause motion':'Play motion';}
document.querySelectorAll('[data-v]').forEach(b=>b.onclick=()=>{variant=b.dataset.v;show()});
$('#theme').onclick=()=>{dark=!dark;show()};$('#motion').onclick=()=>{moving=!moving;show()};
document.querySelectorAll('.star-rules').forEach(g=>{let hold;g.onclick=()=>$('#rules').showModal();g.onpointerdown=()=>{hold=setTimeout(()=>{if(!$('#rules').open)$('#rules').showModal()},500)};g.onpointerup=g.onpointercancel=g.onpointerleave=()=>clearTimeout(hold);g.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();$('#rules').showModal()}}});
document.querySelectorAll('.detail-button,.next-button').forEach(g=>{const act=()=>{$('#notice').textContent=g.getAttribute('aria-label')+' · visual proposal only; no app action.'};g.onclick=act;g.onkeydown=e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();act()}}});
$('#close').onclick=()=>$('#rules').close();show();
const started=performance.now();setInterval(()=>{if(moving)document.querySelectorAll('.count-number text').forEach(t=>t.textContent=4-Math.floor((performance.now()-started)/1000)%4)},100);
</script></html>'''
(ROOT / 'index.html').write_text(page, encoding='utf-8')
print('Generated 6 state boards, 2 signal boards, 2 fit boards, comparison, and standalone HTML.')
