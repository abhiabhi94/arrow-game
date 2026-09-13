#!/usr/bin/env python3
"""Synthesises the game's sound effects into assets/audio/ (pure Python, no
deps). Run once after tweaking a sound; the WAVs are committed.

  python3 tool/make_sfx.py

zip.wav — the "zup" of an arrow sliding off the board: a short rising chirp
with a breath of low-passed noise, quick attack, exponential tail. WAV
(16-bit mono, 22.05 kHz) plays everywhere audioplayers does, iOS included.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22_050


def zip_sound(seconds=0.19, f0=420.0, f1=1_500.0):
    random.seed(7)
    n = int(RATE * seconds)
    out = []
    phase = 0.0
    lp = 0.0
    for i in range(n):
        t = i / n
        # Rising chirp: the pitch sweeps up as the arrow "leaves".
        freq = f0 * (f1 / f0) ** (t ** 0.8)
        phase += 2 * math.pi * freq / RATE
        tone = math.sin(phase) + 0.25 * math.sin(2 * phase)
        # A little air: white noise through a one-pole low-pass.
        lp += 0.12 * (random.uniform(-1, 1) - lp)
        env = min(1.0, i / (RATE * 0.006)) * math.exp(-t * 5.5)
        out.append(env * (0.75 * tone + 0.6 * lp))
    peak = max(abs(s) for s in out)
    return [s / peak * 0.9 for s in out]


def write(path, samples):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s * 32_767)) for s in samples))
    print(f"wrote {path} ({path.stat().st_size} bytes)")


if __name__ == "__main__":
    root = Path(__file__).resolve().parent.parent
    write(root / "assets" / "audio" / "zip.wav", zip_sound())
