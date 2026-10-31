#!/usr/bin/env python3
"""Shared palette and tiny pixel-art drawing helpers for the Bloodsty assets."""

from __future__ import annotations

import os
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SPRITES = os.path.join(ROOT, "assets", "sprites")

# ---------------------------------------------------------------------------
# Palette
# ---------------------------------------------------------------------------
INK = (10, 9, 15, 255)
INK_SOFT = (20, 18, 28, 255)
SHADOW = (12, 11, 18, 190)

SKIN = (203, 184, 160, 255)
SKIN_SHADOW = (162, 139, 118, 255)
SKIN_BLOOD = (151, 79, 72, 255)
HAIR = (48, 36, 35, 255)
BEARD = (72, 52, 42, 255)

STEEL = (104, 113, 136, 255)
STEEL_DARK = (62, 68, 88, 255)
STEEL_LIGHT = (151, 160, 181, 255)
STEEL_RUST = (121, 84, 62, 255)

LEATHER = (78, 56, 39, 255)
LEATHER_LIGHT = (112, 82, 56, 255)
LEATHER_DARK = (48, 34, 26, 255)

TABARD = (124, 41, 54, 255)
TABARD_DARK = (82, 25, 38, 255)
BLOOD = (126, 26, 42, 255)
BLOOD_DARK = (74, 16, 29, 255)
BLOOD_LIGHT = (173, 48, 59, 255)

BONE = (216, 209, 190, 255)
BONE_SHADOW = (166, 158, 139, 255)
BONE_DARK = (115, 108, 94, 255)

STONE = (82, 89, 110, 255)
STONE_DARK = (49, 54, 71, 255)
STONE_LIGHT = (120, 128, 150, 255)
STONE_MOSS = (63, 83, 64, 255)

PURPLE = (84, 42, 92, 255)
PURPLE_DARK = (46, 24, 57, 255)
PURPLE_LIGHT = (126, 72, 126, 255)

ZOMBIE = (94, 123, 78, 255)
ZOMBIE_DARK = (62, 84, 55, 255)
ZOMBIE_LIGHT = (126, 154, 99, 255)

GOLD = (186, 150, 78, 255)
GOLD_DARK = (113, 86, 43, 255)

EYE_RED = (244, 70, 73, 255)
EYE_GHOST = (233, 218, 116, 255)


def canvas(w: int, h: int) -> Image.Image:
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def draw(img: Image.Image) -> ImageDraw.ImageDraw:
    return ImageDraw.Draw(img)


def save(img: Image.Image, name: str) -> None:
    path = os.path.join(SPRITES, name)
    img.save(path, "PNG")
    print(f"  wrote {os.path.relpath(path, ROOT)} ({img.width}x{img.height})")


def rect(d, x, y, w, h, fill):
    if w <= 0 or h <= 0:
        return
    d.rectangle([x, y, x + w - 1, y + h - 1], fill=fill)


def out_rect(d, x, y, w, h, fill, outline=INK):
    """Rectangle with a one-pixel dark outline."""
    rect(d, x - 1, y - 1, w + 2, h + 2, outline)
    rect(d, x, y, w, h, fill)


def poly(d, points, fill):
    d.polygon(points, fill=fill)


def out_poly(d, points, fill, outline=INK):
    """Polygon outline by drawing an expanded fan-shaped dark copy first."""
    cx = sum(p[0] for p in points) / len(points)
    cy = sum(p[1] for p in points) / len(points)
    expanded = []
    for x, y in points:
        dx, dy = x - cx, y - cy
        length = max(0.001, (dx * dx + dy * dy) ** 0.5)
        expanded.append((x + dx / length, y + dy / length))
    d.polygon(expanded, fill=outline)
    d.polygon(points, fill=fill)


def px(d, x, y, color):
    d.point((x, y), fill=color)


def line(d, p1, p2, fill, width=1):
    d.line((p1, p2), fill=fill, width=width)


def ellipse(d, box, fill):
    d.ellipse(box, fill=fill)


def text(d, xy, string, fill):
    # Default bitmap font is fine for the tiny tool-only generators.
    d.text(xy, string, fill=fill)


def dither_rect(d, x, y, w, h, color, step=2, offset=0):
    for yy in range(y, y + h):
        for xx in range(x + ((yy + offset) % step), x + w, step):
            px(d, xx, yy, color)


def specks(d, x, y, w, h, rng, colors, chance=0.12):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            if rng.random() < chance:
                px(d, xx, yy, rng.choice(colors))


def blur_rgba(img: Image.Image, radius: float) -> Image.Image:
    return img.filter(ImageFilter.GaussianBlur(radius))


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(round(lerp(c1[i], c2[i], t))) for i in range(len(c1)))


def rng_for(name: str, seed: int = 0xC0FFEE) -> random.Random:
    return random.Random(f"{name}:{seed}")
