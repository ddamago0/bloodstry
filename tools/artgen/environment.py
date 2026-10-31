#!/usr/bin/env python3
"""Cemetery tiles, props, menu backdrop and atmospheric textures."""

from __future__ import annotations

import math
import random

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from .common import (
    BEARD, BLOOD, BLOOD_DARK, BLOOD_LIGHT, BONE, BONE_DARK, BONE_SHADOW,
    GOLD_DARK, INK, INK_SOFT, LEATHER_DARK, STONE, STONE_DARK, STONE_LIGHT,
    STONE_MOSS, canvas, draw, ellipse, line, out_poly, out_rect, poly, px,
    rect, rng_for, save, specks,
)

TILE = 32
SHEET_W, SHEET_H = 256, 256


# ---------------------------------------------------------------------------
# Ground
# ---------------------------------------------------------------------------
GROUND_BASE = [
    ((26, 29, 43, 255), (34, 38, 55, 255), (20, 22, 33, 255)),
    ((25, 28, 40, 255), (38, 40, 52, 255), (18, 20, 30, 255)),
    ((24, 28, 38, 255), (32, 39, 43, 255), (18, 21, 29, 255)),
    ((29, 29, 38, 255), (43, 40, 45, 255), (21, 20, 28, 255)),
    ((27, 30, 42, 255), (46, 47, 58, 255), (19, 21, 31, 255)),
    ((31, 33, 45, 255), (49, 52, 64, 255), (21, 23, 33, 255)),
]


def ground_tile(index: int) -> Image.Image:
    img = canvas(TILE, TILE)
    d = draw(img)
    rng = rng_for(f"ground{index}", 177 + index)
    base, hi, lo = GROUND_BASE[index % len(GROUND_BASE)]
    rect(d, 0, 0, TILE, TILE, base)

    # Very low-contrast mottling so sprites stay readable.
    for _ in range(90):
        x = rng.randrange(TILE)
        y = rng.randrange(TILE)
        c = hi if rng.random() < 0.45 else lo
        px(d, x, y, c)

    # Pebbles / clumps.
    for _ in range(4):
        x = rng.randrange(2, TILE - 4)
        y = rng.randrange(2, TILE - 3)
        px(d, x, y, hi)
        px(d, x + 1, y, lo)
        px(d, x, y + 1, lo)

    if index == 2:  # mossy patch
        for _ in range(16):
            x = rng.randrange(4, TILE - 4)
            y = rng.randrange(16, TILE - 3)
            px(d, x, y, (40, 54, 42, 255))
            if rng.random() < 0.5:
                px(d, x + 1, y, (48, 64, 48, 255))
    elif index == 3:  # grave dirt, warmer
        for _ in range(7):
            x = rng.randrange(3, TILE - 3)
            y = rng.randrange(7, TILE - 3)
            px(d, x, y, (57, 50, 50, 255))
            px(d, x + 1, y + 1, (53, 47, 48, 255))
    elif index == 4:  # cracked earth
        x = rng.randrange(5, 20)
        for i in range(7):
            px(d, x + (i // 3), 6 + i * 3, lo)
        px(d, 7, 21, (58, 59, 70, 255))
    elif index == 5:  # bone fragment
        px(d, 19, 9, BONE_DARK)
        px(d, 20, 9, BONE_SHADOW)
        px(d, 20, 10, BONE_DARK)
        px(d, 12, 23, (52, 52, 62, 255))
        px(d, 13, 23, (58, 58, 68, 255))

    # Single subtle highlight line breaks up repetition.
    if index % 2 == 0:
        y = 3 + (index * 5) % 22
        for x in range(index * 3 % 8, TILE, 13):
            px(d, x, y, lo)

    return img


# ---------------------------------------------------------------------------
# Props
# ---------------------------------------------------------------------------
def tombstone_a(d, ox=0, oy=0):
    x, y = ox, oy
    # plinth
    out_rect(d, x + 7, y + 27, 18, 4, STONE_DARK)
    rect(d, x + 9, y + 26, 14, 2, STONE)
    # slab
    out_poly(d, [(x + 10, y + 28), (x + 10, y + 9), (x + 13, y + 4), (x + 19, y + 4), (x + 22, y + 9), (x + 22, y + 28)], STONE)
    poly(d, [(x + 11, y + 9), (x + 13, y + 5), (x + 19, y + 5), (x + 21, y + 9), (x + 21, y + 27), (x + 11, y + 27)], STONE)
    # highlight / shade
    line(d, (x + 12, y + 9), (x + 12, y + 26), STONE_LIGHT)
    line(d, (x + 20, y + 9), (x + 20, y + 26), STONE_DARK)
    # engraved cross
    rect(d, x + 15, y + 10, 2, 12, (30, 33, 44, 255))
    rect(d, x + 12, y + 14, 8, 2, (30, 33, 44, 255))
    # crack + moss
    line(d, (x + 18, y + 7), (x + 17, y + 12), STONE_DARK)
    px(d, x + 17, y + 13, STONE_DARK)
    for mx, my in ((11, 24), (12, 25), (13, 24), (18, 26), (19, 25), (20, 26)):
        px(d, x + mx, y + my, STONE_MOSS)
    # grass at base
    for gx in (8, 10, 21, 24):
        px(d, x + gx, y + 30, (44, 61, 45, 255))


def tombstone_b(d, ox=0, oy=0):
    x, y = ox, oy
    out_rect(d, x + 6, y + 27, 20, 4, STONE_DARK)
    # wide rounded stone
    out_poly(d, [(x + 8, y + 27), (x + 8, y + 10), (x + 12, y + 5), (x + 20, y + 5), (x + 24, y + 10), (x + 24, y + 27)], STONE_DARK)
    poly(d, [(x + 9, y + 26), (x + 9, y + 10), (x + 12, y + 6), (x + 20, y + 6), (x + 23, y + 10), (x + 23, y + 26)], STONE)
    # rounded top highlight
    rect(d, x + 12, y + 6, 8, 1, STONE_LIGHT)
    line(d, (x + 10, y + 11), (x + 10, y + 25), STONE_LIGHT)
    line(d, (x + 22, y + 11), (x + 22, y + 25), STONE_DARK)
    # shield engraving
    out_poly(d, [(x + 16, y + 9), (x + 21, y + 11), (x + 20, y + 18), (x + 16, y + 22), (x + 12, y + 18), (x + 11, y + 11)], (56, 61, 78, 255))
    px(d, x + 16, y + 14, GOLD_DARK)
    line(d, (x + 16, y + 11), (x + 16, y + 19), (78, 73, 62, 255))
    # chipped corner
    px(d, x + 22, y + 7, (0, 0, 0, 0))
    px(d, x + 23, y + 8, (0, 0, 0, 0))
    line(d, (x + 19, y + 7), (x + 18, y + 10), STONE_DARK)
    for gx, gy in ((9, 29), (11, 30), (23, 29)):
        px(d, x + gx, y + gy, STONE_MOSS)


def tombstone_c(d, ox=0, oy=0):
    x, y = ox, oy
    # leaning, broken slab
    out_rect(d, x + 8, y + 27, 16, 4, STONE_DARK)
    out_poly(d, [(x + 10, y + 27), (x + 12, y + 11), (x + 17, y + 5), (x + 23, y + 10), (x + 20, y + 27)], STONE_DARK)
    poly(d, [(x + 11, y + 26), (x + 13, y + 11), (x + 17, y + 6), (x + 22, y + 11), (x + 19, y + 26)], STONE)
    # broken top notch
    poly(d, [(x + 17, y + 6), (x + 19, y + 8), (x + 17, y + 10), (x + 15, y + 8)], (35, 39, 52, 255))
    line(d, (x + 14, y + 11), (x + 13, y + 25), STONE_LIGHT)
    line(d, (x + 21, y + 11), (x + 20, y + 25), STONE_DARK)
    # diagonal crack
    line(d, (x + 16, y + 12), (x + 14, y + 18), STONE_DARK)
    line(d, (x + 14, y + 18), (x + 16, y + 21), STONE_DARK)
    # moss footprint
    for mx, my in ((12, 23), (13, 24), (19, 25), (20, 24)):
        px(d, x + mx, y + my, STONE_MOSS)


def cross_marker(d, ox=0, oy=0):
    x, y = ox, oy
    # wooden cross with iron bands
    out_rect(d, x + 8, y + 27, 17, 4, STONE_DARK)
    out_rect(d, x + 14, y + 5, 5, 23, LEATHER_DARK)
    rect(d, x + 15, y + 6, 3, 21, (82, 61, 44, 255))
    rect(d, x + 15, y + 6, 1, 21, (117, 88, 62, 255))
    out_rect(d, x + 7, y + 11, 19, 5, LEATHER_DARK)
    rect(d, x + 8, y + 12, 17, 3, (82, 61, 44, 255))
    rect(d, x + 8, y + 12, 17, 1, (117, 88, 62, 255))
    # iron nails
    for nx, ny in ((9, 13), (16, 13), (23, 13), (16, 23)):
        px(d, x + nx, y + ny, (59, 62, 72, 255))
    # hanging dried flowers
    for i, (fx, fy) in enumerate(((10, 16), (11, 18), (12, 19), (13, 21))):
        px(d, x + fx, y + fy, (94, 66, 53, 255))
        px(d, x + fx + 1, y + fy + 1, (118, 83, 61, 255))
    # grass
    for gx in (7, 9, 23, 25):
        px(d, x + gx, y + 29, (53, 70, 51, 255))
        px(d, x + gx, y + 28, (68, 84, 59, 255))


def obelisk(d, ox=0, oy=0):
    x, y = ox, oy
    out_rect(d, x + 8, y + 26, 17, 5, STONE_DARK)
    out_poly(d, [(x + 11, y + 25), (x + 12, y + 8), (x + 16, y + 5), (x + 20, y + 8), (x + 21, y + 25)], STONE_DARK)
    poly(d, [(x + 12, y + 24), (x + 13, y + 9), (x + 16, y + 6), (x + 19, y + 9), (x + 20, y + 24)], STONE)
    line(d, (x + 14, y + 9), (x + 13, y + 23), STONE_LIGHT)
    line(d, (x + 19, y + 9), (x + 19, y + 23), STONE_DARK)
    # rune
    rect(d, x + 15, y + 12, 2, 6, (39, 42, 56, 255))
    px(d, x + 14, y + 13, (39, 42, 56, 255))
    px(d, x + 17, y + 15, (39, 42, 56, 255))
    for mx, my in ((11, 23), (12, 24), (20, 23)):
        px(d, x + mx, y + my, STONE_MOSS)


def urn(d, ox=0, oy=0):
    x, y = ox, oy
    out_rect(d, x + 10, y + 25, 13, 5, STONE_DARK)
    # vase body
    out_poly(d, [(x + 12, y + 25), (x + 11, y + 18), (x + 13, y + 15), (x + 12, y + 11), (x + 15, y + 9), (x + 19, y + 9), (x + 22, y + 11), (x + 21, y + 15), (x + 23, y + 18), (x + 22, y + 25)], STONE_DARK)
    poly(d, [(x + 13, y + 24), (x + 12, y + 18), (x + 14, y + 15), (x + 13, y + 11), (x + 16, y + 10), (x + 19, y + 10), (x + 21, y + 11), (x + 20, y + 15), (x + 22, y + 18), (x + 21, y + 24)], STONE)
    rect(d, x + 14, y + 10, 6, 1, STONE_LIGHT)
    line(d, (x + 15, y + 12), (x + 14, y + 23), STONE_LIGHT)
    line(d, (x + 20, y + 12), (x + 21, y + 23), STONE_DARK)
    # dead stems
    line(d, (x + 18, y + 9), (x + 20, y + 4), (86, 71, 50, 255))
    line(d, (x + 20, y + 4), (x + 23, y + 2), (86, 71, 50, 255))
    line(d, (x + 17, y + 9), (x + 15, y + 5), (86, 71, 50, 255))
    px(d, x + 15, y + 4, (111, 84, 58, 255))


def bone_pile(d, ox=0, oy=0):
    x, y = ox, oy
    # scattered long bones
    for bx, by, ang in ((8, 24, 0), (13, 27, 1), (18, 23, 2), (21, 27, 0)):
        if ang == 0:
            out_rect(d, x + bx, y + by, 8, 2, BONE_SHADOW)
            px(d, x + bx, y + by - 1, BONE)
            px(d, x + bx + 7, y + by - 1, BONE)
        elif ang == 1:
            out_rect(d, x + bx, y + by, 2, 6, BONE_SHADOW)
            px(d, x + bx - 1, y + by, BONE)
            px(d, x + bx - 1, y + by + 5, BONE)
        else:
            out_rect(d, x + bx, y + by, 6, 2, BONE_DARK)
    # small skull
    out_rect(d, x + 11, y + 17, 6, 5, BONE_SHADOW)
    rect(d, x + 12, y + 17, 4, 3, BONE)
    px(d, x + 12, y + 18, INK)
    px(d, x + 15, y + 18, INK)
    px(d, x + 13, y + 20, BONE_DARK)
    # dark soil under pile
    for gx in (9, 11, 16, 22):
        px(d, x + gx, y + 29, (27, 27, 38, 255))


def skull_pile(d, ox=0, oy=0):
    x, y = ox, oy
    # pile base
    out_rect(d, x + 6, y + 25, 21, 4, (43, 38, 37, 255))
    rect(d, x + 7, y + 24, 19, 2, (66, 55, 48, 255))
    # several skulls
    for sx, sy in ((9, 17), (16, 19), (20, 15), (13, 12), (22, 21)):
        out_rect(d, x + sx, y + sy, 6, 5, BONE_DARK)
        rect(d, x + sx + 1, y + sy, 4, 3, BONE)
        px(d, x + sx + 1, y + sy + 1, INK)
        px(d, x + sx + 4, y + sy + 1, INK)
        px(d, x + sx + 2, y + sy + 3, BONE_SHADOW)
    # candles / offerings
    px(d, x + 8, y + 22, GOLD_DARK)
    px(d, x + 8, y + 23, (172, 117, 51, 255))
    px(d, x + 8, y + 21, (230, 174, 75, 255))


def dead_tree_a(d, ox=0, oy=0):
    x, y = ox, oy
    # roots
    line(d, (x + 16, y + 47), (x + 9, y + 44), (38, 31, 38, 255), 2)
    line(d, (x + 16, y + 47), (x + 24, y + 44), (38, 31, 38, 255), 2)
    # trunk
    out_poly(d, [(x + 13, y + 46), (x + 15, y + 20), (x + 14, y + 12), (x + 17, y + 7), (x + 20, y + 14), (x + 18, y + 22), (x + 20, y + 46)], (28, 23, 31, 255))
    poly(d, [(x + 14, y + 45), (x + 16, y + 21), (x + 15, y + 13), (x + 17, y + 9), (x + 19, y + 14), (x + 17, y + 22), (x + 19, y + 45)], (47, 37, 47, 255))
    line(d, (x + 16, y + 44), (x + 17, y + 12), (63, 50, 60, 255))
    # branches
    branches = [
        ((16, 20), (9, 15), (6, 8)),
        ((17, 17), (24, 12), (28, 5)),
        ((16, 15), (11, 9), (8, 4)),
        ((18, 23), (25, 19), (27, 14)),
    ]
    for (a, b, c) in branches:
        line(d, (x + a[0], y + a[1]), (x + b[0], y + b[1]), (37, 29, 38, 255), 2)
        line(d, (x + b[0], y + b[1]), (x + c[0], y + c[1]), (37, 29, 38, 255))
        px(d, x + c[0], y + c[1] - 1, (55, 43, 54, 255))
    # twigs
    for tx, ty, dx, dy in ((8, 14, -2, -4), (24, 14, 3, -3), (12, 9, -3, -3), (25, 20, 2, -3)):
        line(d, (x + tx, y + ty), (x + tx + dx, y + ty + dy), (46, 36, 47, 255))
    # crow
    out_rect(d, x + 24, y + 4, 3, 2, (12, 11, 17, 255))
    px(d, x + 26, y + 3, (12, 11, 17, 255))
    px(d, x + 27, y + 5, (12, 11, 17, 255))
    # hollow knot
    px(d, x + 16, y + 29, (18, 15, 22, 255))
    px(d, x + 17, y + 30, (18, 15, 22, 255))
    # hanging moss
    for mx, my in ((12, 17), (12, 18), (24, 16), (24, 17), (8, 10)):
        px(d, x + mx, y + my, (56, 70, 55, 255))


def dead_tree_b(d, ox=0, oy=0):
    x, y = ox, oy
    # thicker gnarled trunk
    line(d, (x + 16, y + 47), (x + 8, y + 46), (35, 28, 35, 255), 2)
    line(d, (x + 16, y + 47), (x + 25, y + 45), (35, 28, 35, 255), 2)
    out_poly(d, [(x + 12, y + 46), (x + 14, y + 28), (x + 11, y + 19), (x + 15, y + 10), (x + 21, y + 17), (x + 19, y + 27), (x + 21, y + 46)], (27, 22, 30, 255))
    poly(d, [(x + 13, y + 45), (x + 15, y + 28), (x + 12, y + 20), (x + 16, y + 12), (x + 20, y + 18), (x + 18, y + 27), (x + 20, y + 45)], (49, 38, 47, 255))
    line(d, (x + 15, y + 44), (x + 16, y + 14), (66, 51, 61, 255))
    # thick branches with forks
    for a, b, c in (((14, 22), (7, 17), (4, 10)), ((19, 18), (26, 12), (29, 4)), ((18, 26), (26, 24), (29, 19))):
        line(d, (x + a[0], y + a[1]), (x + b[0], y + b[1]), (38, 29, 38, 255), 2)
        line(d, (x + b[0], y + b[1]), (x + c[0], y + c[1]), (38, 29, 38, 255), 2)
    # noose
    line(d, (x + 28, y + 6), (x + 28, y + 14), (92, 76, 55, 255))
    ellipse(d, (x + 26, y + 13, x + 30, y + 18), None)
    d.ellipse((x + 26, y + 13, x + 30, y + 18), outline=(103, 84, 60, 255))
    # bone charm
    px(d, x + 28, y + 19, BONE_SHADOW)
    px(d, x + 29, y + 20, BONE_DARK)
    # mushrooms at roots
    for mx in (10, 22):
        px(d, x + mx, y + 44, (105, 81, 75, 255))
        px(d, x + mx, y + 43, (139, 104, 95, 255))


def statue(d, ox=0, oy=0):
    x, y = ox, oy
    # pedestal
    out_rect(d, x + 8, y + 39, 17, 8, STONE_DARK)
    rect(d, x + 10, y + 38, 13, 2, STONE)
    out_rect(d, x + 11, y + 34, 10, 5, STONE_DARK)
    rect(d, x + 12, y + 34, 8, 3, STONE)
    # mourning angel
    out_poly(d, [(x + 16, y + 19), (x + 12, y + 25), (x + 13, y + 35), (x + 19, y + 35), (x + 20, y + 25)], STONE_DARK)
    poly(d, [(x + 16, y + 20), (x + 13, y + 26), (x + 14, y + 34), (x + 18, y + 34), (x + 19, y + 26)], STONE)
    # wings folded
    out_poly(d, [(x + 13, y + 25), (x + 7, y + 18), (x + 6, y + 28), (x + 9, y + 35), (x + 13, y + 33)], STONE_DARK)
    poly(d, [(x + 12, y + 25), (x + 8, y + 20), (x + 8, y + 28), (x + 10, y + 34), (x + 12, y + 32)], (72, 77, 96, 255))
    out_poly(d, [(x + 20, y + 25), (x + 26, y + 18), (x + 27, y + 29), (x + 23, y + 35), (x + 20, y + 33)], STONE_DARK)
    poly(d, [(x + 21, y + 25), (x + 25, y + 20), (x + 25, y + 29), (x + 22, y + 34), (x + 21, y + 32)], (76, 82, 101, 255))
    # head bowed, hands
    out_rect(d, x + 14, y + 16, 5, 5, STONE_DARK)
    rect(d, x + 15, y + 16, 3, 4, STONE_LIGHT)
    px(d, x + 15, y + 18, STONE_DARK)
    px(d, x + 17, y + 18, STONE_DARK)
    line(d, (x + 14, y + 24), (x + 12, y + 30), STONE_LIGHT)
    line(d, (x + 18, y + 24), (x + 20, y + 30), STONE_LIGHT)
    # moss / weathering
    for mx, my in ((9, 36), (10, 37), (22, 32), (15, 30), (16, 31)):
        px(d, x + mx, y + my, STONE_MOSS)
    line(d, (x + 19, y + 22), (x + 19, y + 29), STONE_DARK)


def fence(d, ox=0, oy=0):
    x, y = ox, oy
    # rails
    out_rect(d, x + 1, y + 22, 62, 3, (34, 31, 40, 255))
    out_rect(d, x + 1, y + 9, 62, 2, (46, 41, 50, 255))
    # posts
    for px0 in (2, 30, 58):
        out_rect(d, x + px0, y + 4, 3, 27, (48, 44, 55, 255))
        poly(d, [(x + px0 - 1, y + 4), (x + px0 + 1, y + 1), (x + px0 + 3, y + 4)], (113, 100, 94, 255))
        px(d, x + px0, y + 5, (84, 76, 80, 255))
    # vertical bars
    for bx in range(7, 59, 6):
        out_rect(d, x + bx, y + 6, 2, 22, (40, 37, 47, 255))
        px(d, x + bx, y + 5, (110, 101, 96, 255))
        px(d, x + bx - 1, y + 10, (72, 65, 69, 255))
    # rust
    for rx, ry in ((8, 15), (21, 25), (39, 12), (52, 23)):
        px(d, x + rx, y + ry, (119, 79, 57, 255))
    # broken gap
    for bx in range(31, 35):
        for by in range(12, 26):
            px(d, x + bx, y + by, (0, 0, 0, 0))


def brazier(d, ox=0, oy=0):
    x, y = ox, oy
    # legs
    line(d, (x + 10, y + 22), (x + 7, y + 29), (38, 32, 41, 255), 2)
    line(d, (x + 14, y + 22), (x + 17, y + 29), (38, 32, 41, 255), 2)
    # bowl
    out_poly(d, [(x + 6, y + 14), (x + 18, y + 14), (x + 16, y + 22), (x + 8, y + 22)], (45, 40, 50, 255))
    poly(d, [(x + 7, y + 15), (x + 17, y + 15), (x + 15, y + 21), (x + 9, y + 21)], (76, 71, 77, 255))
    line(d, (x + 8, y + 15), (x + 16, y + 15), (112, 100, 92, 255))
    # coals
    for cx in (9, 11, 13, 15):
        px(d, x + cx, y + 14, (173, 84, 49, 255))
    # flame
    poly(d, [(x + 12, y + 4), (x + 16, y + 10), (x + 14, y + 14), (x + 10, y + 13), (x + 8, y + 9)], (205, 98, 47, 255))
    poly(d, [(x + 12, y + 7), (x + 14, y + 11), (x + 12, y + 13), (x + 10, y + 11)], (238, 174, 80, 255))
    px(d, x + 12, y + 10, (251, 224, 140, 255))


def broken_column(d, ox=0, oy=0):
    x, y = ox, oy
    # fallen drum
    out_rect(d, x + 4, y + 34, 17, 6, STONE_DARK)
    rect(d, x + 5, y + 33, 15, 4, STONE)
    for cx in (7, 10, 13, 16):
        line(d, (x + cx, y + 34), (x + cx, y + 36), STONE_DARK)
    # standing broken column
    out_rect(d, x + 21, y + 20, 6, 18, STONE_DARK)
    rect(d, x + 22, y + 21, 4, 16, STONE)
    line(d, (x + 22, y + 21), (x + 22, y + 36), STONE_LIGHT)
    line(d, (x + 25, y + 21), (x + 25, y + 36), STONE_DARK)
    # jagged top
    poly(d, [(x + 21, y + 20), (x + 23, y + 17), (x + 24, y + 20), (x + 26, y + 18), (x + 27, y + 22)], STONE)
    # pedestal
    out_rect(d, x + 19, y + 36, 10, 4, STONE_DARK)
    # moss
    for mx, my in ((23, 28), (24, 29), (8, 35), (14, 35)):
        px(d, x + mx, y + my, STONE_MOSS)


def grave_mound(d, ox=0, oy=0):
    x, y = ox, oy
    # raised dirt mound
    out_poly(d, [(x + 3, y + 30), (x + 6, y + 23), (x + 16, y + 19), (x + 26, y + 23), (x + 29, y + 30)], (27, 24, 31, 255))
    poly(d, [(x + 4, y + 29), (x + 7, y + 24), (x + 16, y + 20), (x + 25, y + 24), (x + 28, y + 29)], (41, 34, 38, 255))
    # little wooden marker
    out_rect(d, x + 15, y + 13, 4, 12, LEATHER_DARK)
    rect(d, x + 16, y + 14, 2, 10, (88, 66, 48, 255))
    line(d, (x + 12, y + 16), (x + 21, y + 16), (88, 66, 48, 255))
    # wilted flowers
    for fx, fy, col in ((10, 25, (130, 85, 92, 255)), (20, 27, (130, 85, 92, 255)), (12, 27, (89, 104, 74, 255))):
        px(d, x + fx, y + fy, col)
        px(d, x + fx, y + fy + 1, (55, 65, 49, 255))
    # stones
    for sx, sy in ((7, 28), (24, 28), (17, 30)):
        px(d, x + sx, y + sy, (66, 64, 72, 255))


PROPS = {
    "tombstone_a": (0, 32, 32, 32, tombstone_a),
    "tombstone_b": (32, 32, 32, 32, tombstone_b),
    "tombstone_c": (64, 32, 32, 32, tombstone_c),
    "cross": (96, 32, 32, 32, cross_marker),
    "obelisk": (128, 32, 32, 32, obelisk),
    "urn": (160, 32, 32, 32, urn),
    "bone_pile": (192, 32, 32, 32, bone_pile),
    "skull_pile": (224, 32, 32, 32, skull_pile),
    "dead_tree_a": (0, 64, 32, 48, dead_tree_a),
    "dead_tree_b": (32, 64, 32, 48, dead_tree_b),
    "statue": (64, 64, 32, 48, statue),
    "fence": (96, 64, 64, 32, fence),
    "brazier": (160, 64, 32, 32, brazier),
    "broken_column": (192, 64, 32, 48, broken_column),
    "grave_mound": (224, 64, 32, 32, grave_mound),
}


# ---------------------------------------------------------------------------
# Menu backdrop
# ---------------------------------------------------------------------------
def _soft_circle(size, color, alpha=255, blur=0):
    img = canvas(size, size)
    d = draw(img)
    d.ellipse((2, 2, size - 3, size - 3), fill=color + (alpha,))
    if blur:
        img = img.filter(ImageFilter.GaussianBlur(blur))
    return img


def menu_background() -> Image.Image:
    W, H = 480, 270
    img = canvas(W, H)
    d = draw(img)

    # Sky gradient.
    sky_top = (6, 7, 13)
    sky_bottom = (21, 25, 40)
    for y in range(0, 202):
        t = y / 202
        c = tuple(int(sky_top[i] + (sky_bottom[i] - sky_top[i]) * t) for i in range(3)) + (255,)
        d.line((0, y, W, y), fill=c)

    # Stars.
    rng = random.Random(411)
    for _ in range(90):
        x, y = rng.randrange(W), rng.randrange(4, 134)
        if 330 < x < 440 and 18 < y < 100:
            continue
        v = rng.choice([(105, 108, 126), (72, 76, 95), (138, 137, 146)])
        px(d, x, y, v + (255,))
    for _ in range(10):
        px(d, rng.randrange(W), rng.randrange(6, 90), (180, 177, 168, 255))

    # Moon halo + moon.
    halo = canvas(W, H)
    hd = draw(halo)
    hd.ellipse((326, 1, 438, 113), fill=(164, 169, 183, 26))
    hd.ellipse((340, 15, 424, 99), fill=(190, 192, 197, 24))
    halo = halo.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(halo)
    d = draw(img)
    d.ellipse((355, 25, 409, 79), fill=(183, 181, 166, 255))
    d.ellipse((359, 29, 405, 75), fill=(213, 208, 188, 255))
    # Craters.
    for cx, cy, r in ((368, 42, 4), (389, 54, 6), (380, 34, 3), (398, 41, 2)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(191, 186, 169, 255))
        d.ellipse((cx - r, cy - r, cx - r + 2, cy - r + 2), fill=(220, 214, 193, 255))
    # Moon glow mist.
    glow = canvas(W, H)
    gd = draw(glow)
    gd.ellipse((315, 8, 450, 140), fill=(151, 158, 176, 20))
    glow = glow.filter(ImageFilter.GaussianBlur(18))
    img.alpha_composite(glow)
    d = draw(img)

    # Distant hills.
    d.polygon([(0, 198), (48, 178), (96, 190), (150, 172), (205, 192), (260, 176), (320, 190), (390, 174), (440, 188), (480, 180), (480, 210), (0, 210)], fill=(12, 14, 24, 255))
    d.polygon([(0, 207), (70, 194), (130, 202), (190, 190), (250, 200), (310, 191), (380, 202), (430, 194), (480, 200), (480, 220), (0, 220)], fill=(9, 10, 18, 255))

    # Dead trees on the horizon.
    def silhouette_tree(tx, ty, scale=1.0):
        trunk = [(tx - 2, ty), (tx + 2, ty), (tx + 1, ty - 45 * scale), (tx - 1, ty - 45 * scale)]
        d.polygon(trunk, fill=(7, 8, 14, 255))
        for ex, ey, dx, dy in ((-1, 38, -14, -10), (1, 32, 15, -12), (0, 25, -10, -12), (1, 20, 11, -10)):
            x1 = tx + ex * scale
            y1 = ty - ey * scale
            x2 = x1 + dx * scale
            y2 = y1 + dy * scale
            d.line((x1, y1, x2, y2), fill=(7, 8, 14, 255), width=max(1, int(scale)))
            d.line((x2, y2, x2 + dx * 0.5 * scale, y2 + dy * 0.5 * scale), fill=(7, 8, 14, 255), width=1)

    silhouette_tree(42, 206, 1.15)
    silhouette_tree(320, 202, 0.9)
    silhouette_tree(462, 208, 1.25)

    # Foreground graves silhouettes.
    def tomb_sil(x, y, w, h):
        d.rectangle((x - 1, y - h, x + w + 1, y), fill=(8, 9, 15, 255))
        d.ellipse((x - 1, y - h - w * 0.5, x + w + 1, y - h + w * 0.5), fill=(8, 9, 15, 255))
        d.rectangle((x - 2, y - 1, x + w + 2, y + 2), fill=(8, 9, 15, 255))

    tomb_sil(20, 222, 16, 25)
    tomb_sil(61, 218, 12, 19)
    tomb_sil(398, 218, 14, 22)
    tomb_sil(432, 224, 18, 28)
    # Cross silhouette.
    d.rectangle((188, 170, 193, 205), fill=(8, 9, 15, 255))
    d.rectangle((179, 181, 202, 186), fill=(8, 9, 15, 255))
    d.rectangle((236, 187, 240, 211), fill=(8, 9, 15, 255))
    d.rectangle((230, 194, 247, 198), fill=(8, 9, 15, 255))

    # Central mausoleum.
    d.rectangle((202, 142, 278, 213), fill=(10, 11, 18, 255))
    d.polygon([(195, 143), (240, 113), (285, 143)], fill=(9, 10, 17, 255))
    d.polygon([(203, 142), (240, 119), (277, 142)], fill=(16, 18, 28, 255))
    # Columns.
    for cx in (208, 225, 252, 269):
        d.rectangle((cx, 154, cx + 6, 209), fill=(15, 17, 26, 255))
        d.rectangle((cx - 1, 152, cx + 7, 155), fill=(19, 21, 31, 255))
    # Door.
    d.rectangle((233, 166, 249, 211), fill=(5, 6, 10, 255))
    d.ellipse((233, 157, 249, 177), fill=(5, 6, 10, 255))
    # Broken seal glow.
    seal = canvas(W, H)
    sd = draw(seal)
    sd.ellipse((227, 170, 255, 198), fill=(134, 24, 42, 90))
    seal = seal.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(seal)
    d = draw(img)
    d.ellipse((232, 176, 250, 194), outline=(153, 36, 53, 220), width=1)
    d.ellipse((237, 181, 245, 189), outline=(104, 24, 39, 220), width=1)

    # Ground.
    d.rectangle((0, 205, W, H), fill=(10, 11, 17, 255))
    d.rectangle((0, 208, W, H), fill=(13, 14, 21, 255))
    for _ in range(260):
        x, y = rng.randrange(W), rng.randrange(211, H)
        v = rng.choice([(20, 21, 31), (17, 18, 27), (24, 24, 33), (14, 15, 23)])
        px(d, x, y, v + (255,))
    # Gravel path to crypt.
    d.polygon([(232, 270), (248, 270), (250, 208), (238, 208)], fill=(18, 18, 27, 255))
    for _ in range(70):
        x = rng.randrange(233, 250)
        y = rng.randrange(210, 270)
        px(d, x, y, rng.choice([(28, 28, 38), (24, 23, 33), (32, 31, 40)]) + (255,))

    # Grass tufts.
    for _ in range(110):
        x = rng.randrange(W)
        y = rng.randrange(212, 268)
        d.line((x, y, x - 1, y - 2), fill=(26, 34, 29, 255))
        d.line((x + 1, y, x + 2, y - 3), fill=(21, 29, 25, 255))

    # Low fog bands.
    fog = canvas(W, H)
    fd = draw(fog)
    for (fx, fy, fw, fh, a) in ((20, 154, 240, 28, 34), (230, 166, 260, 30, 30), (120, 190, 300, 22, 26)):
        fd.ellipse((fx, fy, fx + fw, fy + fh), fill=(154, 166, 183, a))
    fog = fog.filter(ImageFilter.GaussianBlur(12))
    img.alpha_composite(fog)
    d = draw(img)

    # Embers near the crypt.
    for _ in range(24):
        x = rng.randrange(210, 275)
        y = rng.randrange(130, 220)
        a = rng.randrange(70, 190)
        px(d, x, y, (190, 76, 57, a))

    # Crows.
    for cx, cy in ((286, 62), (305, 48), (121, 84)):
        line(d, (cx - 3, cy), (cx, cy - 2), (13, 14, 21, 255))
        line(d, (cx, cy - 2), (cx + 3, cy), (13, 14, 21, 255))

    # Vignette baked in.
    v = make_vignette(W, H, strength=150, inner=0.2, power=1.6)
    img.alpha_composite(v)
    return img


# ---------------------------------------------------------------------------
# Atmospheric textures
# ---------------------------------------------------------------------------
def make_fog() -> Image.Image:
    W, H = 256, 128
    rng = np.random.default_rng(8104)

    # Periodic smoothed noise => seamless when tiled.
    base = rng.random((16, 32))
    pad = np.pad(base, ((1, 1), (1, 1)), mode="wrap")
    smooth = (
        pad[1:-1, 1:-1] * 4
        + pad[:-2, 1:-1] + pad[2:, 1:-1]
        + pad[1:-1, :-2] + pad[1:-1, 2:]
        + pad[:-2, :-2] + pad[:-2, 2:] + pad[2:, :-2] + pad[2:, 2:]
    ) / 12.0
    smooth = (smooth - smooth.min()) / (smooth.max() - smooth.min())
    noise = np.array(Image.fromarray((smooth * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC), dtype=np.float32) / 255.0
    alpha = np.clip((noise - 0.38) / 0.62, 0, 1)
    alpha = (alpha ** 1.5 * 150).astype(np.uint8)
    rgba = np.zeros((H, W, 4), dtype=np.uint8)
    rgba[..., :3] = 235
    rgba[..., 3] = alpha
    return Image.fromarray(rgba, "RGBA")


def make_vignette(w=480, h=270, strength=180, inner=0.24, power=1.8) -> Image.Image:
    yy, xx = np.ogrid[:h, :w]
    cx, cy = w / 2, h / 2
    dx = (xx - cx) / (w * 0.5)
    dy = (yy - cy) / (h * 0.5)
    d = np.sqrt(dx * dx + dy * dy) / math.sqrt(2)
    t = np.clip((d - inner) / (1 - inner), 0, 1) ** power
    alpha = (t * strength).astype(np.uint8)
    rgba = np.zeros((h, w, 4), dtype=np.uint8)
    rgba[..., 3] = alpha
    return Image.fromarray(rgba, "RGBA")


def make_glow() -> Image.Image:
    W = H = 128
    yy, xx = np.ogrid[:H, :W]
    cx = cy = (W - 1) / 2
    d = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2) / (W / 2)
    alpha = np.clip(1 - d, 0, 1) ** 2.4
    rgba = np.zeros((H, W, 4), dtype=np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = (alpha * 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def make_splats() -> Image.Image:
    W = 32
    sheet = canvas(W * 4, W)
    for v in range(4):
        rng = random.Random(900 + v)
        img = canvas(W, W)
        d = draw(img)
        # main irregular pool
        cx, cy = 15 + rng.randint(-2, 2), 16 + rng.randint(-2, 2)
        for i in range(9):
            ang = rng.random() * math.tau
            dist = rng.random() * 5.5
            rx = 3 + rng.random() * 4
            ry = 2 + rng.random() * 3
            x = cx + math.cos(ang) * dist
            y = cy + math.sin(ang) * dist
            d.ellipse((x - rx, y - ry, x + rx, y + ry), fill=(255, 255, 255, rng.randint(190, 255)))
        # satellite droplets
        for _ in range(15):
            ang = rng.random() * math.tau
            dist = 7 + rng.random() * 8
            x = cx + math.cos(ang) * dist
            y = cy + math.sin(ang) * dist
            r = 1 if rng.random() < 0.7 else 2
            d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 255, 255, rng.randint(130, 235)))
        # directional streak for variant 1 and 3
        if v in (1, 3):
            for i in range(5):
                x = cx + 6 + i * 2
                y = cy - 2 + i
                px(d, x, y, (255, 255, 255, 200 - i * 30))
        sheet.alpha_composite(img, (v * W, 0))
    return sheet


# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
def build_all():
    print("Environment:")
    sheet = canvas(SHEET_W, SHEET_H)
    for i in range(6):
        sheet.alpha_composite(ground_tile(i), (i * TILE, 0))
    for name, (x, y, w, h, painter) in PROPS.items():
        tile = canvas(w, h)
        painter(draw(tile))
        sheet.alpha_composite(tile, (x, y))
    save(sheet, "cemetery_tiles.png")

    save(menu_background(), "menu_bg.png")
    save(make_fog(), "fog.png")
    save(make_vignette(), "vignette.png")
    save(make_glow(), "glow.png")
    save(make_splats(), "blood_splats.png")
