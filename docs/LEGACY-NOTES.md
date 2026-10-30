# Legacy prototype notes
> Source: `2026-10-28-Smack-a-Pad-ipad` snapshot (read-only, never modified).
> Carry the knowledge and data forward; copy zero production code.

---

## 1. Stack

The prototype is a **vanilla-JS PWA** wrapped in a native iOS shell — not a SwiftUI app.

| Layer | Technology |
|---|---|
| App logic | Vanilla ES-module JavaScript (no build framework) |
| Styling | Plain CSS, bundled into one `studio.css` |
| Audio | Web Audio API (`AudioContext`, `latencyHint:'interactive'`) |
| MIDI (browser) | Web MIDI API (`navigator.requestMIDIAccess`) — Chrome/Edge/Chromium only |
| MIDI (iOS) | CoreMIDI via Capacitor native plugin `MidiBridge`; polyfilled with `ios-shim.js` |
| iOS wrapper | **Capacitor 8** (`@capacitor/core ^8.0.0`, `@capacitor/ios ^8.0.0`) |
| Swift version | **Swift 5.0** |
| Min iPadOS | **iPadOS 15.0** (`IPHONEOS_DEPLOYMENT_TARGET = 15.0`) |
| Target device family | iPad only (`TARGETED_DEVICE_FAMILY = 2`) |
| Offline | Service-worker PWA precache |
| Storage | `localStorage` (progress/settings) + IndexedDB (user audio kits) |

---

## 2. Proven MIDI input path and latency approach

### Input routing
`navigator.requestMIDIAccess()` → `MIDIAccess.inputs` → `input.onmidimessage = onMidi`.  
On iOS/Capacitor, `ios-shim.js` polyfills the whole Web MIDI interface; CoreMIDI delivers raw bytes through `window.webkit.messageHandlers.bridge`, converted to `{data: Uint8Array, timeStamp, seq, ageMs}` events that look identical to real Web MIDI events.

### Timestamp strategy (proven to work, tricky to get right)
The prototype uses **three clock sources** chosen per-device at runtime:

| Source | When used |
|---|---|
| `event` | Default: use `e.timeStamp` (set by the browser at USB-class-compliant devices) |
| `receipt-bluetooth` | BLE controllers whose `timeStamp` is > 250 ms old or > 50 ms in the future — fall back to `performance.now()` at message receipt |
| `receipt-controller` | Manual per-device override stored in `localStorage('midiReceiptOverrides')` |

```js
// Core clock selection (proven pattern — document, do not copy wholesale)
function midiScoreTime(e, receivedAt) {
  const gap = receivedAt - e.timeStamp;        // delivery delay
  const wireless = /bluetooth|\bble\b/i.test(currentInput?.name || '');
  const usesReceipt = wireless && (gap > 250 || gap < -50);
  return { time: usesReceipt ? receivedAt : e.timeStamp, source: ... };
}
```

On iOS via CoreMIDI, the shim syncs to Mach clock using `bridge.getClock()` (NTP-style RTT probe) and sets `timeStamp = msg.machNs / 1e6 + clockOffsetMs` — converting the native nanosecond timestamp into the `performance.now()` domain. This gave accurate timestamps even when the JS bridge itself had variable delivery delay.

### User calibration
10-click guided calibration (`startTimingCalibration`): plays 10 metronome clicks at 1 s apart using `AudioContext.getOutputTimestamp()` as the ground-truth clock; user taps along; median-with-MAD-outlier-rejection gives a per-device signed offset (capped ±200 ms), stored as `localStorage('timingProfiles')` keyed by `midi:<deviceId>:<clockMode>:<clockSource>`.

### Timing center (adaptive drift correction)
A `createTimingCenter` rolling-median corrector (window of 8 samples, gated to ±100–110 ms) shifts the scoring window at runtime to follow a player's systematic early/late tendency without widening the windows.

---

## 3. Data: lessons and patterns

### Location
`app/v21/src/data/lessons-core.json` — **547 lessons**, IDs 1–547.  
Additional content: `src/data/intro.json` (24 guided intro exercises), `src/data/electronic-path.json`, `src/data/genre-extensions.json`.  
Sample-kit manifest: `app/v21/src/data/sample-kits.json` (keys: `acoustic`, `808`, `jazz`, `world`, `rock`, `brush`, `worldperc`, `house`, `virtuosity`).

### Lesson schema (all fields)

```json
{
  "id": 1,
  "cat": "starter",
  "title": "Four on the floor",
  "genre": "Dance",
  "tags": [],
  "text": "Left hand: kick.",
  "division": 16,
  "bars": 1,
  "startBpm": 65,
  "targetBpm": 100,
  "level": 1,
  "score": 3.6,
  "src": "Standard pattern",
  "hits": [[step, padIndex, "L"|"R", velocity], ...]
}
```

- `division`: subdivisions per bar (always 16 = sixteenth-note grid).
- `bars`: 1, 2, or 3.
- `hits`: array of `[step, padIndex, hand, velocity]`. `step` is 0-based sixteenth index within `bars × division`. `padIndex` is 0–15 (16-pad layout). `hand` is "L" or "R". `velocity` is 0–127.
- `level`: 1–5 (used to select hit windows; see §4).
- `src`: attribution string ("Groove MIDI Dataset", "Standard pattern", etc.).

**Categories**: starter, eighth, sixteenth, electronic, ghost, swing, world, fills.

### Sample kits schema

```json
{ "acoustic": { "name": "Acoustic", "license": "...",
    "voices": { "kick": [{ "url": "samples/acoustic/kick-1.wav",
                           "variants": ["...1.wav", "...2.wav"] }] } } }
```

WAV files are in `app/v21/assets/samples/<kitId>/` and `ios-wrapper/www/samples/<kitId>/`. License files per kit are worth porting.

### Files worth porting as data
- `app/v21/src/data/lessons-core.json` — the full 547-lesson library
- `app/v21/src/data/intro.json` — 24 guided exercises
- `app/v21/src/data/electronic-path.json` — electronic genre progression
- `app/v21/src/data/genre-extensions.json` — additional genre patterns
- `app/v21/src/data/sample-kits.json` — kit manifest and voice structure
- `app/v21/i18n/cs.tsv` — Czech localisation strings

---

## 4. Hit windows and scoring rules (exact numbers)

### Timing windows — level-dependent

| Level | Perfect (ms) | Good (ms) | Max/miss (ms) |
|---|---|---|---|
| 1–2 | ±45 | ±100 | ±200 |
| 3–4 | ±38 | ±85 | ±175 |
| 5 | ±30 | ±70 | ±150 |

A hit outside `max` is a miss. A hit within `max` but outside `good` scores as "off". The scoring window is symmetric around the expected note time, shifted by the adaptive timing center value.

### Mastery error limits (for automatic BPM increase)

| Total expected hits | Allowed errors for clean run |
|---|---|
| ≤ 15 | 0 |
| 16–32 | 1 |
| > 32 | 2 |

Intro lessons always require 0 errors for the mastery goal.

### Pass threshold
- Score ≥ 70% → lesson passed (non-intro).
- Score ≥ 80% → intro lesson passed.
- Mastery = clean run (within error limit) at or above `targetBpm`.

### Double-hit guard
A second hit on the same pad within **30 ms** of a previously matched hit counts as a wrong pad, not a second match.

### BPM auto-progression
After a clean run below `targetBpm`, tempo increases by `practiceStep()` (user-selectable: 1, 2, or 5 BPM).

---

## 5. Known bugs, hacks, and dead ends — do NOT repeat

1. **Web MIDI does not work on Safari/WebKit** — the app requires Chrome/Edge/Chromium in a browser context. The iOS wrapper works around this with the CoreMIDI native bridge + `ios-shim.js`. **Do not attempt Web MIDI directly in WKWebView without a native bridge.**

2. **BLE controller timestamps are unreliable** — Bluetooth MIDI controllers often deliver `e.timeStamp` values that are 250+ ms stale (iOS CoreBluetooth batching) or occasionally negative. The "receipt-bluetooth" fallback exists because of this. Do not trust `e.timeStamp` for BLE.

3. **iOS Safari / `navigator.standalone` hack** — `ios-shim.js` force-overrides `navigator.standalone = true` to bypass the PWA install gate inside Capacitor's WKWebView. This is a workaround for WKWebView not returning `true` naturally.

4. **`AudioContext.getOutputTimestamp()` warmup** — The calibration code waits for 3 stable consecutive samples with `< 1 ms` spread before trusting `getOutputTimestamp()`. On cold start it can take several seconds. Do not use `outputTimestamp` immediately on context creation.

5. **IndexedDB for user audio kits is unreliable across origins/ports** — The prototype stores user kits per origin+port. Changing ports loses kit data silently. Plan for this in any native Swift replacement.

6. **`localStorage` namespace collision** — The full edition still carries the key prefix `padofill.full.course.` from an earlier brand name, intentionally preserved for backward compatibility. A new native app should start with a clean keyspace.

7. **Single-file JS bundle** — The source is concatenated by a custom Node.js build script (`app/build-v21.mjs`) in strict module order (`module-order.json`). There is no tree-shaking, typing, or module bundler. This is a known technical debt — do not carry this pattern into Swift.

8. **`ctx.resume()` must be triggered by user gesture** — Standard Web Audio policy. Every audio path is gated behind a user tap. Not a bug, but a hard constraint that must be wired identically in a native Swift `AVAudioEngine` setup.

9. **Safari audio latency was never measured** — The REVIEW.md explicitly states "Safari audio latency … unverified". Physical iPad acoustic latency is unknown; all timing data is from Windows/Chrome with a USB controller.

10. **Section-loop scoring does not mark lesson passed** — This was an intentional design rule but required careful guarding. A section-only result must never update `progress[lessonId].passed`.

---

## 6. Open questions we could not determine

- **Exact acoustic latency on iPad** — never measured; only synthetic and Chrome-on-Windows data exist.
- **CoreMIDI bridge Swift implementation** — `ios-wrapper/ios/` contains the Xcode project and `MidiBridge` Swift plugin, but the Swift source was not fully read (binary artifacts excluded). The bridge protocol (mach timestamp → JS clock offset sync) is documented in `ios-shim.js` but the native side should be verified against the actual `.swift` files.
- **License status for commercial redistribution of sample kits** — roadmap states "Additional commercial 909 content still requires a suitable redistribution agreement; no purchase or vendor contact has been made." The existing kits (AVL Acoustic, Fischer 808, Groove MIDI Dataset patterns) each have `LICENSE.txt` files that must be reviewed before App Store distribution.
- **Whether `TARGETED_DEVICE_FAMILY = 2` (iPad-only) is intentional** — the wrapper was set up for iPad only, but it is not documented whether iPhone support was intentionally excluded or simply never added.
- **Actual Swift source for `MidiBridge`** — source files inside the `ios-wrapper/ios/` Xcode project were excluded from this analysis (build output boundary). Read those `.swift` files before reimplementing.
