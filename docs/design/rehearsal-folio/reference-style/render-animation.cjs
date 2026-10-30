// Render a standalone concept animation. This does not modify the iPad app.
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const runtimeRequire = createRequire('/Users/kju/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas/package.json');
const { createCanvas, loadImage, GifEncoder } = runtimeRequire('@napi-rs/canvas');
const sharp = runtimeRequire('sharp');
const dir = __dirname;
const sourceWidth = 1449;
const sourceHeight = 1086;
const bars = [
  { edges: [218,289,360,430,498,569,640,711,783,854,924,995,1067,1139,1211,1283,1354], rows: [284,356,429,501], bracket: [235,503], kick: [0,8] },
  { edges: [218,289,359,429,499,570,641,712,783,854,925,996,1067,1139,1211,1283,1354], rows: [579,653,726,798], bracket: [531,801], kick: [0,8,10] },
];
function drawOverlay(ctx, seconds) {
  const loopTime = ((seconds % 6) + 6) % 6;
  const barIndex = Math.floor(loopTime / 3);
  const barTime = loopTime - barIndex * 3;
  const step = Math.min(15, Math.floor((barTime + 1e-8) / 0.1875));
  const phase = barTime - step * 0.1875;
  const bar = bars[barIndex];
  const x = bar.edges[step];
  const right = bar.edges[step + 1];
  const activeRows = [];
  if (step % 2 === 0) activeRows.push(0);
  if (step === 4 || step === 12) activeRows.push(1);
  if (bar.kick.includes(step)) activeRows.push(2);
  ctx.save();
  ctx.lineJoin = 'miter';
  ctx.lineCap = 'butt';
  // The bracket changes bars without moving any content.
  ctx.strokeStyle = '#000000';
  ctx.lineWidth = 3;
  ctx.beginPath();
  ctx.moveTo(76, bar.bracket[0]);
  ctx.lineTo(68, bar.bracket[0]);
  ctx.lineTo(68, bar.bracket[1]);
  ctx.lineTo(76, bar.bracket[1]);
  ctx.stroke();
  // A two-stroke outline leaves the glyph and hand unobscured.
  if (phase < 0.12) {
    for (const row of activeRows) {
      const y = bar.rows[row] + 4;
      const height = bar.rows[row + 1] - bar.rows[row] - 8;
      ctx.strokeStyle = '#FFFFFF';
      ctx.lineWidth = 6;
      ctx.strokeRect(x + 5, y, right - x - 10, height);
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 2;
      ctx.strokeRect(x + 5, y, right - x - 10, height);
    }
    if (activeRows.length) {
      ctx.strokeStyle = '#000000';
      ctx.lineWidth = 4;
      ctx.beginPath();
      ctx.arc(724, 850, 13, 0, Math.PI * 2);
      ctx.stroke();
    }
  }
  // The time cursor steps at subdivision boundaries so it never crosses letters.
  ctx.beginPath();
  ctx.moveTo(x, bar.rows[0]);
  ctx.lineTo(x, bar.rows[3]);
  ctx.strokeStyle = '#FFFFFF';
  ctx.lineWidth = 7;
  ctx.stroke();
  ctx.strokeStyle = '#000000';
  ctx.lineWidth = 3;
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(x - 9, bar.rows[0] - 19);
  ctx.lineTo(x + 9, bar.rows[0] - 19);
  ctx.lineTo(x, bar.rows[0] - 3);
  ctx.closePath();
  ctx.strokeStyle = '#FFFFFF';
  ctx.lineWidth = 3;
  ctx.stroke();
  ctx.fillStyle = '#000000';
  ctx.fill();
  ctx.restore();
}
async function main() {
  const plate = await loadImage(path.join(dir, 'A1-clean-plate.png'));
  function render(canvas, time) {
    const ctx = canvas.getContext('2d');
    ctx.resetTransform();
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.scale(canvas.width / sourceWidth, canvas.height / sourceHeight);
    ctx.drawImage(plate, 0, 0, sourceWidth, sourceHeight);
    drawOverlay(ctx, time);
  }
  // Export the requested current position: bar 2, step 5, at 3.75 seconds.
  const still = createCanvas(2732, 2048);
  render(still, 3.75);
  fs.writeFileSync(path.join(dir, 'A1-reference-style.png'), still.toBuffer('image/png'));
  const width = 1200;
  const height = 900;
  const preview = createCanvas(width, height);
  const encoder = new GifEncoder(width, height, { repeat: 0, quality: 10 });
  let elapsedMs = 0;
  for (let frame = 0; frame < 96; frame++) {
    render(preview, elapsedMs / 1000);
    const rgba = preview.getContext('2d').getImageData(0, 0, width, height).data;
    const delay = [60,60,60,70][frame % 4];
    encoder.addFrame(new Uint8Array(rgba.buffer, rgba.byteOffset, rgba.byteLength), width, height, { delay });
    elapsedMs += delay;
  }
  const gifPath = path.join(dir, 'A1-reference-style-motion.gif');
  const gifBuffer = encoder.finish();
  encoder.dispose();
  await sharp(gifBuffer, { animated: true }).gif({
    colours: 64, dither: 0, effort: 7,
    interFrameMaxError: 1, interPaletteMaxError: 1,
  }).toFile(gifPath);
  // Output inspection reports file dimensions and the encoded loop duration.
  const meta = await sharp(gifPath, { animated: true }).metadata();
  console.log(JSON.stringify({
    still: { width: 2732, height: 2048, baseRaster: [sourceWidth, sourceHeight] },
    animation: {
      width: meta.width, height: meta.pageHeight, frames: meta.pages,
      durationMs: meta.delay.reduce((sum, delay) => sum + delay, 0), loop: meta.loop,
      bytes: fs.statSync(gifPath).size
    }
  }));
}
main().catch(error => { console.error(error); process.exitCode = 1; });

