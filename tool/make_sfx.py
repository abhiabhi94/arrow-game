#!/usr/bin/env python3
"""Synthesises the game's sound effects into assets/audio/ (pure Python, no
deps). Run once after tweaking a sound; the WAVs are committed.

  python3 tool/make_sfx.py

whoosh.wav — the whoosh of an arrow sliding off the board. A whoosh is air,
not a note: white noise pushed through a resonant band-pass filter whose
centre frequency sweeps upward as the arrow "leaves", under a quick swell and
a soft tail. No tonal component at all — a sine chirp reads as a laser
bleep.

bump.wav — the crash of an arrow running into another: a sharp crack of
noise over a heavy thump whose pitch sags as it dies, then a lighter second
knock as the arrow springs back, all with a touch of saturation for crunch.

WAV (16-bit mono, 44.1 kHz) plays everywhere audioplayers does, iOS included.
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44_100


class BandPass:
    """Chamberlin state-variable filter; `tick` returns the band-pass output."""

    def __init__(self, q=2.6):
        self.low = 0.0
        self.band = 0.0
        self.damp = 1.0 / q

    def tick(self, x, fc):
        f = 2.0 * math.sin(math.pi * fc / RATE)
        self.low += f * self.band
        high = x - self.low - self.damp * self.band
        self.band += f * high
        return self.band


def whoosh_sound(seconds=0.26, f0=320.0, f1=2_400.0):
    random.seed(7)
    n = int(RATE * seconds)
    body = BandPass(q=2.4)
    air = BandPass(q=1.8)
    out = []
    for i in range(n):
        t = i / RATE
        u = i / n
        # The sweep: most of the rise happens early, then it eases out.
        fc = f0 * (f1 / f0) ** (u ** 0.65)
        # Swell in over ~35 ms, hold a moment, then a soft tail.
        attack = min(1.0, t / 0.035) ** 1.6
        decay = math.exp(-max(0.0, t - 0.05) * 13.0)
        env = attack * decay
        noise = random.uniform(-1.0, 1.0)
        s = body.tick(noise, fc) + 0.35 * air.tick(noise, fc * 2.3)
        out.append(env * s)
    peak = max(abs(s) for s in out)
    return [s / peak * 0.85 for s in out]


def bump_sound(seconds=0.34):
    """Two hits: the arrow slams into its neighbour (a sharp crack over a
    heavy thump) and, as it springs back, a lighter second knock."""
    random.seed(11)
    n = int(RATE * seconds)
    crack = BandPass(q=1.2)
    body = BandPass(q=2.0)
    out = []
    phase = 0.0
    second = 0.11  # seconds after the first hit
    for i in range(n):
        t = i / RATE
        # The thump: a sine that starts around 170 Hz and sags to 40 Hz,
        # with a fast, loud attack.
        freq = 40.0 + 130.0 * math.exp(-t * 32.0)
        phase += 2 * math.pi * freq / RATE
        thump = math.sin(phase) * math.exp(-t * 14.0)
        noise = random.uniform(-1.0, 1.0)
        # The crack: a wide splash of noise around 2.2 kHz, gone in ~15 ms,
        # and a woodier body around 500 Hz that rings ~60 ms.
        hit = 1.2 * crack.tick(noise, 2200.0) * math.exp(-t * 110.0) \
            + 0.9 * body.tick(noise, 500.0) * math.exp(-t * 32.0)
        # The rebound knock: the same body, quieter, a beat later.
        t2 = t - second
        rebound = 0.0
        if t2 >= 0:
            rebound = 0.5 * body.tick(noise, 650.0) * math.exp(-t2 * 45.0)
        s = 1.3 * thump + hit + rebound
        out.append(math.tanh(1.9 * s))
    peak = max(abs(s) for s in out)
    return [s / peak * 0.92 for s in out]


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
    write(root / "assets" / "audio" / "whoosh.wav", whoosh_sound())
    write(root / "assets" / "audio" / "bump.wav", bump_sound())
