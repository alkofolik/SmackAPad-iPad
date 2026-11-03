"""Create standalone, offline design previews; no application integration."""
from pathlib import Path
import base64
import re

HERE = Path(__file__).resolve().parent
ROOT = Path.cwd()
font = base64.b64encode((ROOT / 'SmackAPad/Resources/Fonts/IBMPlexSans[wdth,wght].ttf').read_bytes()).decode()
concepts = [
    ('a-stack', 'A / Pad stack', 'Three pad rows; one shared time position.'),
    ('b-tape', 'B / Hit tape', 'The moving notation meets a fixed playhead.'),
    ('c-together', 'C / Together', 'HH and KD arrive together on the same beat.'),
]

TEMPLATE = r'''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>@@TITLE@@ — Smack-a-Pad launch proposal</title>
<style>
@font-face{font-family:Plex;src:url(data:font/ttf;base64,@@FONT@@) format('truetype');font-weight:100 700;font-stretch:75% 100%;font-display:block}
*{box-sizing:border-box}body{margin:0;background:#fff;color:#000;font:18px/1.5 Plex,sans-serif;font-synthesis:none}
main{max-width:1280px;margin:auto;padding:28px}h1{font-size:32px;line-height:1.1;margin:0 0 12px}p{margin:0 0 24px;max-width:72ch}
nav,.controls{display:flex;align-items:center;flex-wrap:wrap;gap:16px;margin-bottom:24px}a{color:inherit;text-underline-offset:4px}
button,select{font:inherit;min-height:48px;border:2px solid currentColor;background:#fff;color:#000;padding:8px 16px;border-radius:0;cursor:pointer}
button:hover{background:#000;color:#fff}button:focus-visible,select:focus-visible,input:focus-visible,a:focus-visible{outline:4px solid #ff6b00;outline-offset:4px}
label{display:inline-flex;align-items:center;gap:10px;min-height:48px}input{width:24px;height:24px;accent-color:#000}
.device{background:#000;padding:12px;border-radius:24px}.screen{position:relative;aspect-ratio:4/3;border-radius:14px;overflow:hidden;background:#fff;color:#000;container-type:inline-size}
.screen.dark{background:#000;color:#fff;outline:2px solid #fff;outline-offset:-2px}
.brand{position:absolute;left:50%;top:50%;width:60cqw;display:flex;align-items:center;gap:3cqw;transform:translate(-50%,-50%);transform-origin:0 0;z-index:2}
.mark{width:19cqw;height:19cqw;flex:none;overflow:hidden}.mark svg{display:block;width:100%;height:100%;overflow:hidden}
.wordmark{font-size:5cqw;line-height:1;font-weight:700;white-space:nowrap;letter-spacing:-.025em}
.library{position:absolute;inset:22% 5% 8%;opacity:0}.library h2{font-size:3.4cqw;line-height:1.1;margin:0 0 4cqw}
.row{display:flex;align-items:center;justify-content:space-between;gap:24px;padding:2.4cqw 0;border-top:2px solid currentColor;font-size:2.4cqw}.row strong{font-weight:700}.row span{font-size:1.8cqw}
.mini-band{display:flex;align-items:center;gap:1cqw;background:#ff6b00;padding:1cqw;color:#000}.mini-band b{background:#fff;padding:.2cqw .8cqw;font-size:1.8cqw}
.skip{position:absolute;bottom:4%;right:5%;z-index:3;background:inherit;color:inherit;font-size:max(14px,1.8cqw)}
.screen.done .skip{visibility:hidden}.caption{display:flex;justify-content:space-between;gap:16px;flex-wrap:wrap;margin-top:16px;font-size:16px}
details{margin-top:24px}summary{cursor:pointer;min-height:44px}table{border-collapse:collapse;margin-top:16px;width:100%;max-width:950px}td,th{text-align:left;padding:12px 16px 12px 0;vertical-align:top;border-bottom:2px solid #000}th{font-weight:700}
@media(max-width:600px){main{padding:16px}.controls{gap:12px}.device{padding:6px;border-radius:16px}h1{font-size:28px}.skip{min-height:40px;padding:4px 8px}.wordmark{font-size:5cqw}}
</style>
<main>
<h1>@@TITLE@@</h1><p>@@IDEA@@ A 1.8-second cold-start concept for Smack-a-Pad.</p>
<nav aria-label="Compare concepts">@@NAV@@</nav>
<div class="controls">
<button id="replay" type="button">Replay</button>
<label>Appearance <select id="appearance"><option value="light">Light</option><option value="dark">Dark</option></select></label>
<label><input id="reduce" type="checkbox">Reduce Motion</label>
<label><input id="loop" type="checkbox">Loop preview</label>
</div>
<div class="device"><div class="screen" id="screen" aria-label="iPad launch animation concept">
<div class="brand" id="brand"><div class="mark">@@SVG@@</div><div class="wordmark">Smack-a-Pad</div></div>
<section class="library" id="library" aria-label="Illustrative library destination" inert>
<h2>Library</h2><div class="row"><strong>Intro</strong><span>Start here</span></div>
<div class="row"><strong>Electronic</strong><div class="mini-band" aria-label="Illustrative HH, SN, KD notation"><b>HH</b><b>SN</b><b>KD</b></div></div>
<div class="row"><strong>Funk</strong><span>Browse lessons</span></div>
</section><button class="skip" id="skip" type="button">Skip animation</button>
</div></div>
<div class="caption"><span id="status" role="status" aria-live="polite">Ready</span><span>Silent · Tap the launch surface to skip</span></div>
<details><summary>Storyboard and first frame</summary>
<p>First frame: a static centred icon and IBM Plex Sans Bold wordmark. Light: white page, black wordmark. Dark: black page, white wordmark. The icon retains exactly its own orange, black and white geometry in both appearances. Controls and the iPad frame are preview-only.</p>
<table><thead><tr><th>Time</th><th>Action</th></tr></thead><tbody>@@STORY@@</tbody></table>
<p>Reduce Motion: the same wordmark stays still for 800 ms, followed by a 200 ms cross-fade to Library. No translation or scale. The icon stays static too. In the app the sequence belongs to the process cold start only; returning from the background must show the current screen. This file simulates a cold start when opened or replayed.</p>
<p>The Library is an illustrative destination, not a proposed navigation change. SwiftUI can use shapes, offsets, scale and opacity with the existing font. A later implementation must share launch-screen geometry and colours with this first frame, and render the destination before beginning the handoff.</p>
</details><noscript><p>Enable JavaScript to replay the animation. The static first frame is shown above.</p></noscript>
</main>
<script>
const concept = '@@ID@@';
const screen = document.getElementById('screen'), brand = document.getElementById('brand');
const library = document.getElementById('library'), status = document.getElementById('status');
const reduce = document.getElementById('reduce'), appearance = document.getElementById('appearance');
const replay = document.getElementById('replay'), skip = document.getElementById('skip'), loop = document.getElementById('loop');
const systemMotion = matchMedia('(prefers-reduced-motion: reduce)');
const systemDark = matchMedia('(prefers-color-scheme: dark)');
reduce.checked = systemMotion.matches; appearance.value = systemDark.matches ? 'dark' : 'light';
const destinationBrand=brand.cloneNode(true);destinationBrand.id='destination-brand';destinationBrand.setAttribute('aria-hidden','true');
Object.assign(destinationBrand.style,{left:'5%',top:'4%',transform:'translate(0,0) scale(.5)',opacity:'0'});
screen.append(destinationBrand);
let animations = [], timers = [], generation = 0, active = false;
function clearPlayback(){generation++;timers.forEach(clearTimeout);timers=[];animations.forEach(a=>a.cancel());animations=[];}
function later(fn,ms){timers.push(setTimeout(fn,ms));}
function animate(el,frames,options){const a=el.animate(frames,{fill:'both',...options});animations.push(a);return a;}
function finalState(){
  brand.style.opacity='0';destinationBrand.style.opacity='1';
  library.style.opacity='1';screen.classList.add('done');active=false;
}
function finish(skipped=false){
  const moveFocus=document.activeElement===skip;clearPlayback();finalState();
  status.textContent=skipped?'Skipped · Library':'Library · '+(reduce.checked?'1.0 s · Reduce Motion':'1.8 s');
  if(moveFocus)replay.focus();
  if(loop.checked)later(play,1200);
}
async function play(){
  clearPlayback();const run=generation;active=true;
  screen.classList.toggle('dark',appearance.value==='dark');screen.classList.remove('done');
  brand.removeAttribute('style');destinationBrand.style.opacity='0';library.style.opacity='0';status.textContent='Preparing first frame';
  await document.fonts.ready;if(run!==generation)return;
  // Start only after the exact static launch composition has been painted.
  requestAnimationFrame(()=>requestAnimationFrame(()=>{
    if(run!==generation)return;status.textContent=reduce.checked?'Static wordmark · Reduce Motion':'Playing · 1.8 s';
    if(reduce.checked){
      animate(brand,[{opacity:1},{opacity:0}],{delay:800,duration:200});
      animate(library,[{opacity:0},{opacity:1}],{delay:800,duration:200});
      animate(destinationBrand,[{opacity:0},{opacity:1}],{delay:800,duration:200});
      later(()=>finish(),1000);return;
    }
    const cursor=screen.querySelector('.cursor');
    if(concept==='b-tape'){
      animate(screen.querySelector('.notation'),[{transform:'translateX(90px)'},{transform:'translateX(0px)'}],{delay:240,duration:760,easing:'cubic-bezier(.2,0,.2,1)'});
    }else if(concept==='a-stack'){
      animate(cursor,[{transform:'translateX(-80px)'},{transform:'translateX(0px)'}],{delay:240,duration:760,easing:'cubic-bezier(.2,0,.2,1)'});
    }else{
      animate(screen.querySelector('.notation'),[{opacity:1},{opacity:.4},{opacity:1}],{delay:320,duration:640,easing:'ease-in-out'});
    }
    animate(brand,[{left:'50%',top:'50%',transform:'translate(-50%,-50%)'},{left:'5%',top:'4%',transform:'translate(0,0) scale(.5)'}],{delay:1200,duration:600,easing:'cubic-bezier(.2,0,.2,1)'});
    animate(library,[{opacity:0},{opacity:1}],{delay:1420,duration:380});
    later(()=>finish(),1800);
  }));
}
replay.addEventListener('click',play);skip.addEventListener('click',e=>{e.stopPropagation();finish(true);});
screen.addEventListener('click',()=>{if(active)finish(true);});
document.addEventListener('keydown',e=>{if(e.key==='Escape'&&active)finish(true);});
reduce.addEventListener('change',play);appearance.addEventListener('change',play);
loop.addEventListener('change',()=>{if(!loop.checked&&!active)clearPlayback();else if(loop.checked&&!active)play();});
systemMotion.addEventListener('change',e=>{reduce.checked=e.matches;play();});
document.addEventListener('visibilitychange',()=>{if(document.hidden&&active){const looping=loop.checked;loop.checked=false;finish(true);loop.checked=looping;}});
play();
</script></html>'''

for ident, title, idea in concepts:
    source = (HERE / f'{ident}.svg').read_text()
    paths = re.findall(r'<path [^>]+/>', source)
    svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" role="img" aria-label="' + title + '">'
    svg += paths[0] + '<g class="notation">' + ''.join(paths[1:-3]) + '</g><g class="cursor">' + ''.join(paths[-3:]) + '</g></svg>'
    action = {
        'a-stack': 'The playhead travels 80 icon units across the three aligned rows; the cells stay fixed.',
        'b-tape': 'The tape moves 90 icon units left into place; the playhead stays fixed.',
        'c-together': 'Both aligned HH and KD cells share one soft opacity dip and return together. No rhythmic flashing.',
    }[ident]
    story = '<tr><td>0–240 ms</td><td>Hold the exact static launch frame.</td></tr>'
    story += f'<tr><td>240–1000 ms</td><td>{action}</td></tr>' if ident != 'c-together' else f'<tr><td>320–960 ms</td><td>{action}</td></tr>'
    story += '<tr><td>1000–1200 ms</td><td>Rest on the resolved icon and wordmark.</td></tr><tr><td>1200–1800 ms</td><td>Move and scale the brand into the Library header. Library fades in during 1420–1800 ms.</td></tr>'
    nav = ' '.join(f'<a href="{i}.html"'+(' aria-current="page"' if i == ident else '')+f'>{t}</a>' for i, t, _ in concepts)
    replacements = {'TITLE': title, 'IDEA': idea, 'ID': ident, 'FONT': font, 'SVG': svg, 'NAV': nav, 'STORY': story}
    result = TEMPLATE
    for key, value in replacements.items():
        result = result.replace('@@'+key+'@@', value)
    license_text = (ROOT / 'SmackAPad/Resources/Fonts/ibmplexsans-OFL.txt').read_text()
    result = result.replace('<html lang="en">', '<!-- Embedded IBM Plex Sans font license:\n' + license_text + '\n-->\n<html lang="en">')
    (HERE / f'{ident}.html').write_text(result)

(HERE / 'ibmplexsans-OFL.txt').write_bytes((ROOT / 'SmackAPad/Resources/Fonts/ibmplexsans-OFL.txt').read_bytes())
print('Created three standalone HTML previews with embedded Plex and SVG; copied the complete OFL.')
