#!/usr/bin/env python3
"""Synthesize the 30-second ambient soundtrack for the Bloodsty trailer.

Usage:
    python3 tools/make_trailer_audio.py /tmp/opencode/bloodsty_trailer_audio.wav
"""

from __future__ import annotations

import os
import sys
import wave

import numpy as np

SR = 44100
DURATION = 30.0


def boom(track, start, amp=0.55, length=1.6, freq=48.0):
    n0 = int(start * SR)
    n1 = min(track.shape[0], n0 + int(length * SR))
    if n1 <= n0:
        return
    tt = np.arange(n1 - n0) / SR
    env = np.exp(-tt * 4.2)
    wave_ = (np.sin(2 * np.pi * freq * tt)
             + 0.5 * np.sin(2 * np.pi * (freq * 1.5) * tt))
    track[n0:n1] += amp * env * wave_


def whoosh(track, start, amp=0.18, length=0.65):
    n0 = max(0, int((start - 0.35) * SR))
    n1 = min(track.shape[0], int((start - 0.35 + length) * SR))
    if n1 <= n0:
        return
    rng = np.random.default_rng(int(start * 1000) + 11)
    tt = np.arange(n1 - n0) / SR
    noise = rng.standard_normal(n1 - n0)
    # Differentiate for an airy high-frequency hiss.
    noise = np.diff(noise, prepend=noise[0])
    peak = start - n0 / SR
    env = np.exp(-((tt - peak) ** 2) / 0.012)
    track[n0:n1] += amp * env * noise


def bell(track, start, amp=0.10, freq=196.0, length=2.2):
    n0 = int(start * SR)
    n1 = min(track.shape[0], n0 + int(length * SR))
    if n1 <= n0:
        return
    tt = np.arange(n1 - n0) / SR
    env = np.exp(-tt * 2.0)
    tone = (np.sin(2 * np.pi * freq * tt)
            + 0.45 * np.sin(2 * np.pi * freq * 1.5 * tt)
            + 0.2 * np.sin(2 * np.pi * freq * 2.01 * tt))
    track[n0:n1] += amp * env * tone


def heartbeat(track, start, amp=0.45):
    for offset, gain in ((0.0, 1.0), (0.17, 0.6)):
        n0 = int((start + offset) * SR)
        n1 = min(track.shape[0], n0 + int(0.22 * SR))
        if n1 <= n0:
            continue
        tt = np.arange(n1 - n0) / SR
        env = np.exp(-tt * 22)
        pulse = (0.7 * np.sin(2 * np.pi * 46 * tt)
                 + 0.3 * np.sin(2 * np.pi * 68 * tt))
        track[n0:n1] += amp * gain * env * pulse


def main(path: str) -> None:
    n = int(SR * DURATION)
    t = np.arange(n) / SR
    rng = np.random.default_rng(7)

    # Slow, detuned low drone.
    bend = 1.0 + 0.0025 * np.sin(2 * np.pi * 0.05 * t)
    lfo = 0.72 + 0.28 * np.sin(2 * np.pi * 0.075 * t + 1.1)
    drone = (
        0.50 * np.sin(2 * np.pi * 55.0 * bend * t)
        + 0.26 * np.sin(2 * np.pi * 82.41 * t + 0.4)
        + 0.15 * np.sin(2 * np.pi * 110.0 * t + 1.1)
        + 0.07 * np.sin(2 * np.pi * 164.81 * t + 2.0)
        + 0.035 * np.sin(2 * np.pi * 220.0 * t + 0.2)
    ) * lfo

    # Brown-noise bed, loudest during the horde and boss.
    brown = np.cumsum(rng.standard_normal(n))
    brown /= np.max(np.abs(brown)) + 1e-9
    bed_env = 0.55 + 0.45 * np.clip((t - 5.0) / 4.0, 0, 1)
    bed_env *= np.clip((23.0 - t) / 2.0, 0.15, 1.0)
    noise = 0.10 * brown * bed_env

    music = drone + noise

    # Impacts and transitions.
    for at in (0.0, 5.0, 13.6, 17.0, 21.0, 23.2, 25.2, 27.2):
        whoosh(music, at)
    boom(music, 0.0, amp=0.5, length=2.0)
    boom(music, 17.0, amp=0.75, length=2.2)
    boom(music, 21.0, amp=0.85, length=2.4)
    for at in (23.2, 25.2, 27.2, 29.0):
        bell(music, at, amp=0.09 if at < 29.0 else 0.12)

    # Heartbeats: brief intro pulse, then the boss fight.
    for at in np.arange(0.55, 2.2, 0.85):
        heartbeat(music, float(at), amp=0.30)
    for at in np.arange(17.1, 21.05, 0.62):
        heartbeat(music, float(at), amp=0.50)

    # Global fades and gentle saturation.
    fade = np.ones(n)
    fade_in = int(0.5 * SR)
    fade[:fade_in] = np.linspace(0, 1, fade_in)
    fade_out_start = int(28.7 * SR)
    fade[fade_out_start:] = np.linspace(1, 0, n - fade_out_start) ** 1.5
    music *= fade

    music = np.tanh(music * 1.15)
    music *= 0.82 / (np.max(np.abs(music)) + 1e-9)

    # A touch of stereo width without phase trouble.
    delay = int(0.008 * SR)
    right = np.copy(music)
    right[delay:] = 0.82 * right[delay:] + 0.18 * music[:-delay]
    left = music
    stereo = np.stack([left, right], axis=1)

    pcm = np.clip(stereo * 32767.0, -32768, 32767).astype("<i2")
    with wave.open(path, "wb") as fh:
        fh.setnchannels(2)
        fh.setsampwidth(2)
        fh.setframerate(SR)
        fh.writeframes(pcm.tobytes())

    print(f"wrote {path} ({DURATION:.0f}s, {SR} Hz stereo)")


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "/tmp/opencode/bloodsty_trailer_audio.wav"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    main(out)
