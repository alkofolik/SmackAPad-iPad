#!/usr/bin/env python3
"""Measure sample loudness and write per-file playback gains (ticket 166).

Run from the project root, no third-party packages needed:

    python3 tools/measure-sample-loudness.py            # write the JSON
    python3 tools/measure-sample-loudness.py --report   # print the table only

Measure
-------
K-weighted RMS (ITU-R BS.1770 pre-filter + RLB high-pass) over the first
300 ms of each hit, in dB. Short percussive hits are too brief for LUFS
gating, but the K-weighting still matches how loud they sound (it lifts the
highs and cuts the lows, so a bright crash is not under-measured and a deep
kick is not over-measured). Sample peak is checked with 4x oversampling to
estimate the true peak.

Gain model
----------
* Gains are per kit and voice (kit ids and voices as in sample-kits.json),
  because some kits share WAV files. Velocity layers of one voice share ONE
  gain, taken from that voice's loudest layer. Giving each layer its own gain would flatten the
  soft-to-loud dynamics inside a voice.
* Per kit, the reference level is the median of all voices' loudest layer.
  Each voice is moved to reference + FAMILY_OFFSET_DB[voice].
* The player node cannot go above unity, so gains are capped at
  MAX_BOOST_DB (0 by default): loud voices are turned down, quiet voices stay.
* Gain is also capped so the true peak never exceeds -1 dBFS.

Edit FAMILY_OFFSET_DB below to move an instrument family forward or back.
"""
import argparse
import json
import math
import os
import statistics
import sys
import wave
from array import array

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAMPLES = os.path.join(ROOT, "SmackAPad", "Resources", "Samples")
KITS = os.path.join(ROOT, "SmackAPad", "Resources", "Data", "sample-kits.json")
OUT = os.path.join(ROOT, "SmackAPad", "Resources", "Data", "sample-gains.json")

WINDOW_SECONDS = 0.3
PEAK_CEILING_DB = -1.0
MAX_BOOST_DB = 0.0

# One table, easy to change. Positive = more forward, negative = further back.
FAMILY_OFFSET_DB = {
    "kick": 1.5, "snare": 1.5, "rim": 0.0, "clap": 0.0,
    "tomHi": 0.0, "tomLo": 0.0,
    "hat": -2.0, "openHat": -2.5,
    "crash": -3.5, "ride": -3.0,
    "shaker": -1.0, "wood": 0.0, "cowbell": -1.0,
}


def read_wav(path):
    """Return (sample_rate, mono floats of the first channel mix)."""
    with wave.open(path, "rb") as w:
        assert w.getsampwidth() == 2, path
        channels, rate, frames = w.getnchannels(), w.getframerate(), w.getnframes()
        raw = array("h")
        raw.frombytes(w.readframes(frames))
    if sys.byteorder == "big":
        raw.byteswap()
    if channels == 1:
        return rate, [s / 32768 for s in raw]
    # Stereo: BS.1770 sums channel powers; for a mono-compatible figure
    # average the powers by returning interleaved-channel RMS-equivalent.
    left = [raw[i] / 32768 for i in range(0, len(raw), channels)]
    right = [raw[i + 1] / 32768 for i in range(0, len(raw), channels)]
    return rate, (left, right)


def biquad(x, b, a):
    y, x1, x2, y1, y2 = [], 0.0, 0.0, 0.0, 0.0
    for s in x:
        v = b[0] * s + b[1] * x1 + b[2] * x2 - a[1] * y1 - a[2] * y2
        y.append(v)
        x2, x1, y2, y1 = x1, s, y1, v
    return y


def k_filters(rate):
    """BS.1770 stage-1 shelf and stage-2 RLB high-pass, any sample rate."""
    # Stage 1: high shelf (+4 dB at ~1.68 kHz).
    f0, g, q = 1681.974450955533, 3.999843853973347, 0.7071752369554196
    k = math.tan(math.pi * f0 / rate)
    vh = 10 ** (g / 20)
    vb = vh ** 0.4996667741545416
    a0 = 1 + k / q + k * k
    shelf_b = [(vh + vb * k / q + k * k) / a0, 2 * (k * k - vh) / a0,
               (vh - vb * k / q + k * k) / a0]
    shelf_a = [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
    # Stage 2: high-pass at ~38 Hz.
    f0, q = 38.13547087602444, 0.5003270373238773
    k = math.tan(math.pi * f0 / rate)
    a0 = 1 + k / q + k * k
    hp_a = [1, 2 * (k * k - 1) / a0, (1 - k / q + k * k) / a0]
    return (shelf_b, shelf_a), ([1, -2, 1], hp_a)


def channel_k_ms(x, rate):
    n = int(WINDOW_SECONDS * rate)
    (sb, sa), (hb, ha) = k_filters(rate)
    y = biquad(biquad(x[:n], sb, sa), hb, ha)
    return sum(v * v for v in y) / max(1, n)


def k_rms_db(path):
    rate, data = read_wav(path)
    chans = data if isinstance(data, tuple) else (data,)
    ms = sum(channel_k_ms(c, rate) for c in chans)  # BS.1770: sum channel power
    return 10 * math.log10(ms) if ms > 0 else -120.0


def true_peak_db(path):
    rate, data = read_wav(path)
    chans = data if isinstance(data, tuple) else (data,)
    peak = 0.0
    for x in chans:
        peak = max(peak, max((abs(v) for v in x), default=0.0))
        # 4x oversampling with a 4-point Catmull-Rom spline between samples.
        for i in range(1, len(x) - 2):
            p0, p1, p2, p3 = x[i - 1], x[i], x[i + 1], x[i + 2]
            if max(abs(p1), abs(p2)) < peak * 0.7:
                continue
            for t in (0.25, 0.5, 0.75):
                v = 0.5 * ((2 * p1) + (-p0 + p2) * t
                           + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
                           + (-p0 + 3 * p1 - 3 * p2 + p3) * t ** 3)
                peak = max(peak, abs(v))
    return 20 * math.log10(peak) if peak > 0 else -120.0


def measure():
    """Measure every WAV used by every kit in sample-kits.json.

    A WAV can be shared by several kits (e.g. "world" reuses "acoustic"
    files), so results are grouped per kit and voice, not per folder.
    """
    with open(KITS) as f:
        kits = json.load(f)
    cache, result = {}, {}
    for kit_id, kit in kits.items():
        for voice, layers in kit["voices"].items():
            files = {}
            for layer in layers:
                rel = layer["url"].split("/", 1)[1]  # drop "samples/"
                if rel not in cache:
                    path = os.path.join(SAMPLES, rel)
                    cache[rel] = (k_rms_db(path), true_peak_db(path))
                files[rel] = cache[rel]
            result.setdefault(kit_id, {})[voice] = files
    return result


def build(kits):
    gains, rows = {}, []
    for kit_id, voices in kits.items():
        top = {v: max(m[0] for m in files.values()) for v, files in voices.items()}
        reference = statistics.median(top.values())
        gains[kit_id] = {}
        for voice, files in voices.items():
            want = reference + FAMILY_OFFSET_DB.get(voice, 0.0) - top[voice]
            worst_peak = max(m[1] for m in files.values())
            gain = round(min(want, MAX_BOOST_DB, PEAK_CEILING_DB - worst_peak), 1)
            # Rounding must never push the peak back over the ceiling.
            gain = min(gain, math.floor((PEAK_CEILING_DB - worst_peak) * 10) / 10)
            gains[kit_id][voice] = gain
            rows.append((kit_id, voice, top[voice], worst_peak, gain))
    return gains, rows


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--report", action="store_true", help="print only, do not write")
    args = parser.parse_args()
    gains, rows = build(measure())
    for set_id, voice, level, peak, gain in rows:
        print(f"{set_id:10s} {voice:8s} K-RMS {level:7.1f} dB  peak {peak:6.1f} dBTP  gain {gain:+5.1f} dB")
    if not args.report:
        with open(OUT, "w") as f:
            json.dump({"version": 1, "unit": "dB", "kits": gains}, f, indent=1, sort_keys=True)
            f.write("\n")
        print(f"wrote gains for {len(gains)} kits to {os.path.relpath(OUT, ROOT)}")


if __name__ == "__main__":
    main()
