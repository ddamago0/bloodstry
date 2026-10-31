#!/usr/bin/env python3
"""Player, enemy and boss sprite sheets (4 animation frames each)."""

from __future__ import annotations

from .common import (
    BEARD, BLOOD, BLOOD_DARK, BLOOD_LIGHT, BONE, BONE_DARK, BONE_SHADOW,
    EYE_GHOST, EYE_RED, GOLD, GOLD_DARK, HAIR, INK, INK_SOFT, LEATHER,
    LEATHER_DARK, LEATHER_LIGHT, PURPLE, PURPLE_DARK, PURPLE_LIGHT, SKIN,
    SKIN_BLOOD, SKIN_SHADOW, STEEL, STEEL_DARK, STEEL_LIGHT, STEEL_RUST,
    STONE, TABARD, TABARD_DARK, ZOMBIE, ZOMBIE_DARK, ZOMBIE_LIGHT,
    canvas, draw, line, out_poly, out_rect, poly, px, rect, save,
)

FRAME_W, FRAME_H = 32, 40
BOSS_W, BOSS_H = 48, 64

STEP = [-2, 0, 2, 0]
BOB = [0, -1, 0, -1]


def _eye(d, x, y, color=EYE_RED):
    px(d, x, y, color)
    px(d, x + 1, y, color)


def _boot(d, x, y, color=LEATHER_DARK):
    out_rect(d, x, y, 4, 3, color)
    px(d, x, y + 2, INK)
    px(d, x + 3, y + 2, INK)


# ---------------------------------------------------------------------------
# Players
# ---------------------------------------------------------------------------
def draw_guerrero(d, f):
    bob = BOB[f]
    off = STEP[f]
    # Back arm
    out_rect(d, 8, 19 + bob, 3, 8, STEEL_DARK)
    out_rect(d, 7, 26 + bob, 3, 3, SKIN_SHADOW)
    # Back leg
    out_rect(d, 12 + off // 2, 29, 4, 8, LEATHER_DARK)
    _boot(d, 11 + off // 2, 37)
    # Torso silhouette
    out_poly(d, [(11, 16 + bob), (20, 16 + bob), (21, 28), (10, 28)], STEEL_DARK)
    # Chainmail skirt
    rect(d, 11, 25 + bob, 10, 4, LEATHER)
    deco = [(12, 27), (15, 29), (18, 28), (20, 26)]
    for x, y in deco:
        px(d, x, y + bob, LEATHER_LIGHT)
    # Tabard
    poly(d, [(13, 18 + bob), (19, 18 + bob), (20, 29), (12, 29)], TABARD)
    rect(d, 15, 19 + bob, 2, 8, TABARD_DARK)
    px(d, 16, 23 + bob, BLOOD_LIGHT)
    px(d, 15, 24 + bob, BLOOD)
    # Chest plate
    out_rect(d, 12, 16 + bob, 9, 4, STEEL)
    rect(d, 13, 17 + bob, 3, 1, STEEL_LIGHT)
    px(d, 19, 19 + bob, STEEL_DARK)
    # Pauldrons
    out_poly(d, [(8, 16 + bob), (14, 15 + bob), (14, 20 + bob), (9, 21 + bob)], STEEL)
    out_poly(d, [(19, 15 + bob), (24, 16 + bob), (23, 21 + bob), (18, 20 + bob)], STEEL)
    px(d, 10, 17 + bob, STEEL_LIGHT)
    px(d, 22, 17 + bob, STEEL_LIGHT)
    # Belt + buckle
    rect(d, 10, 27 + bob, 11, 2, LEATHER_DARK)
    px(d, 16, 27 + bob, GOLD)
    px(d, 16, 28 + bob, GOLD_DARK)
    # Front leg
    out_rect(d, 17 - off // 2, 29, 4, 8, LEATHER_DARK)
    _boot(d, 17 - off // 2, 37)
    # Front arm
    out_rect(d, 21, 19 + bob, 3, 6, STEEL)
    out_rect(d, 21, 24 + bob, 3, 4, SKIN_SHADOW)
    px(d, 22, 26 + bob, BLOOD)
    # Neck & head
    rect(d, 15, 14 + bob, 3, 2, SKIN_SHADOW)
    out_rect(d, 13, 8 + bob, 7, 7, SKIN)
    # Hair
    rect(d, 13, 7 + bob, 7, 2, HAIR)
    rect(d, 12, 8 + bob, 2, 3, HAIR)
    rect(d, 13, 14 + bob, 7, 1, SKIN_SHADOW)
    # Bloodied face / eyes
    px(d, 16, 10 + bob, SKIN_BLOOD)
    _eye(d, 16, 11 + bob)
    px(d, 14, 12 + bob, BLOOD_DARK)
    # Stubble
    px(d, 18, 14 + bob, HAIR)
    px(d, 19, 13 + bob, HAIR)
    # Scabbard
    line(d, (10, 29), (7, 36), LEATHER_LIGHT)
    px(d, 7, 36, GOLD_DARK)


def draw_barbaro(d, f):
    bob = BOB[f]
    off = STEP[f]
    # Back arm (bare, muscular)
    out_poly(d, [(7, 18 + bob), (10, 17 + bob), (11, 27 + bob), (8, 28 + bob)], SKIN_SHADOW)
    px(d, 8, 25 + bob, SKIN_BLOOD)
    # Back leg
    out_rect(d, 12 + off // 2, 29, 5, 8, LEATHER)
    _boot(d, 11 + off // 2, 37, LEATHER_DARK)
    # Big torso
    out_poly(d, [(10, 15 + bob), (22, 15 + bob), (23, 29), (9, 29)], SKIN_SHADOW)
    # Fur vest
    out_poly(d, [(8, 15 + bob), (24, 15 + bob), (24, 21 + bob), (22, 23 + bob), (10, 23 + bob), (8, 21 + bob)], BEARD)
    for x, y in [(9, 17), (12, 16), (15, 18), (18, 16), (21, 17), (23, 19)]:
        px(d, x, y + bob, (112, 87, 66, 255))
    # Tunic / bloody apron
    rect(d, 12, 22 + bob, 9, 6, LEATHER_DARK)
    poly(d, [(13, 23 + bob), (20, 23 + bob), (21, 30), (12, 30)], TABARD_DARK)
    px(d, 16, 25 + bob, BLOOD)
    px(d, 17, 27 + bob, BLOOD_LIGHT)
    rect(d, 10, 28, 13, 2, LEATHER)
    px(d, 16, 28, GOLD)
    # Front leg
    out_rect(d, 17 - off // 2, 29, 5, 8, LEATHER)
    _boot(d, 17 - off // 2, 37, LEATHER_DARK)
    # Front arm
    out_poly(d, [(22, 17 + bob), (26, 18 + bob), (25, 27 + bob), (21, 27 + bob)], SKIN)
    px(d, 24, 20 + bob, SKIN_SHADOW)
    px(d, 23, 25 + bob, BLOOD_DARK)
    # Neck / bald head
    rect(d, 14, 13 + bob, 5, 2, SKIN_SHADOW)
    out_rect(d, 12, 6 + bob, 9, 8, SKIN)
    rect(d, 12, 5 + bob, 8, 2, HAIR)
    px(d, 11, 7 + bob, HAIR)
    # Beard
    out_poly(d, [(12, 12 + bob), (21, 12 + bob), (20, 16 + bob), (16, 17 + bob), (12, 15 + bob)], BEARD)
    px(d, 14, 14 + bob, (94, 70, 55, 255))
    # Scar + eyes
    line(d, (13, 8 + bob), (15, 11 + bob), SKIN_BLOOD)
    _eye(d, 17, 9 + bob, (244, 151, 96, 255))
    px(d, 20, 10 + bob, SKIN_SHADOW)
    # Bone trophy necklace
    for x in (14, 16, 18):
        px(d, x, 18 + bob, BONE_SHADOW)


def draw_asesino(d, f):
    bob = BOB[f]
    off = STEP[f]
    # Back arm
    out_rect(d, 8, 19 + bob, 3, 7, (34, 48, 54, 255))
    out_rect(d, 8, 25 + bob, 2, 2, SKIN_SHADOW)
    # Back leg
    out_rect(d, 13 + off // 2, 29, 3, 8, (36, 40, 49, 255))
    rect(d, 13 + off // 2, 35, 3, 2, LEATHER_DARK)
    _boot(d, 12 + off // 2, 37)
    # Cloak tails
    out_poly(d, [(11, 20 + bob), (15, 20 + bob), (14, 35), (9, 32)], (31, 44, 51, 255))
    out_poly(d, [(19, 20 + bob), (22, 22 + bob), (23, 33), (19, 35)], (31, 44, 51, 255))
    # Torso
    out_poly(d, [(12, 17 + bob), (20, 17 + bob), (21, 29), (11, 29)], (38, 52, 58, 255))
    # Chest straps
    line(d, (12, 18 + bob), (20, 27 + bob), LEATHER_LIGHT)
    line(d, (20, 18 + bob), (13, 26 + bob), LEATHER_DARK)
    rect(d, 10, 27, 12, 2, LEATHER_DARK)
    px(d, 16, 27, STEEL_LIGHT)
    # Pouch
    out_rect(d, 18, 24 + bob, 4, 4, LEATHER)
    px(d, 19, 25 + bob, GOLD_DARK)
    # Front leg
    out_rect(d, 17 - off // 2, 29, 3, 8, (36, 40, 49, 255))
    line(d, (17 - off // 2, 32), (19 - off // 2, 32), LEATHER_LIGHT)
    _boot(d, 16 - off // 2, 37)
    # Front arm
    out_rect(d, 21, 19 + bob, 3, 6, (34, 48, 54, 255))
    out_rect(d, 21, 24 + bob, 2, 3, SKIN_SHADOW)
    # Hooded head
    out_poly(d, [(12, 16 + bob), (12, 9 + bob), (16, 4 + bob), (20, 8 + bob), (21, 16 + bob)], (34, 50, 55, 255))
    rect(d, 13, 14 + bob, 7, 2, (34, 50, 55, 255))
    # Hood trim
    line(d, (13, 15 + bob), (13, 9 + bob), (65, 102, 99, 255))
    line(d, (14, 8 + bob), (16, 5 + bob), (65, 102, 99, 255))
    # Face void
    out_rect(d, 14, 9 + bob, 6, 6, (23, 28, 33, 255))
    _eye(d, 15, 11 + bob)
    px(d, 19, 12 + bob, BLOOD_DARK)
    # Scarf
    out_poly(d, [(12, 16 + bob), (21, 16 + bob), (22, 19 + bob), (17, 18 + bob), (11, 20 + bob), (11, 17 + bob)], TABARD_DARK)
    px(d, 13, 18 + bob, TABARD)
    # Belt knives
    line(d, (20, 26), (23, 24), STEEL_LIGHT)
    line(d, (11, 26), (8, 24), STEEL)
    px(d, 8, 24, GOLD)


PLAYERS = {
    "player_guerrero.png": draw_guerrero,
    "player_barbaro.png": draw_barbaro,
    "player_asesino.png": draw_asesino,
}


# ---------------------------------------------------------------------------
# Enemies
# ---------------------------------------------------------------------------
def draw_skeleton_common(d, f):
    bob = BOB[f]
    off = STEP[f]
    # Back arm
    line(d, (11, 16 + bob), (8, 23 + bob), BONE_SHADOW)
    px(d, 8, 24 + bob, BONE_SHADOW)
    # Back leg
    line(d, (15 + off // 2, 28), (13 + off // 2, 38), BONE_SHADOW, 2)
    px(d, 12 + off // 2, 38, BONE_DARK)
    # Tattered waist cloth
    out_poly(d, [(12, 25 + bob), (21, 25 + bob), (22, 30), (17, 28), (14, 31), (11, 29)], (67, 49, 40, 255))
    # Ribcage
    rect(d, 15, 15 + bob, 2, 12, BONE_SHADOW)
    for y in (17, 20, 23):
        line(d, (12, y + bob), (19, y + bob), BONE, 1)
        px(d, 12, y + bob, BONE_SHADOW)
        px(d, 19, y + bob, BONE_SHADOW)
        px(d, 15, y + bob, BONE_DARK)
    # Pelvis
    out_poly(d, [(12, 26 + bob), (20, 26 + bob), (19, 29 + bob), (16, 28 + bob), (12, 29 + bob)], BONE)
    # Front leg
    line(d, (18 - off // 2, 28), (19 - off // 2, 38), BONE, 2)
    px(d, 19 - off // 2, 38, BONE_SHADOW)
    # Shoulders / collarbone
    line(d, (10, 15 + bob), (21, 15 + bob), BONE_SHADOW)
    px(d, 10, 16 + bob, BONE)
    px(d, 21, 16 + bob, BONE)
    # Front arm
    line(d, (21, 16 + bob), (23, 22 + bob), BONE)
    line(d, (23, 22 + bob), (22, 25 + bob), BONE_SHADOW)
    px(d, 22, 26 + bob, BONE)
    # Neck + skull
    rect(d, 15, 13 + bob, 2, 2, BONE_SHADOW)
    out_rect(d, 12, 7 + bob, 8, 7, BONE)
    rect(d, 13, 13 + bob, 6, 1, BONE_SHADOW)
    # Eye sockets
    rect(d, 13, 9 + bob, 2, 2, INK)
    rect(d, 17, 9 + bob, 2, 2, INK)
    px(d, 14, 10 + bob, EYE_RED)
    px(d, 18, 10 + bob, EYE_RED)
    # Nose + jaw gaps
    px(d, 16, 12 + bob, BONE_DARK)
    for x in (14, 16, 18):
        px(d, x, 13 + bob, INK_SOFT)
    # Crack
    line(d, (12, 8 + bob), (14, 10 + bob), BONE_SHADOW)


def draw_skeleton_tall(d, f):
    bob = BOB[f]
    off = STEP[f]
    # Back arm
    line(d, (10, 16 + bob), (6, 27 + bob), BONE_SHADOW, 2)
    px(d, 6, 28 + bob, BONE_DARK)
    # Back leg
    line(d, (15 + off // 2, 27), (12 + off // 2, 39), BONE_SHADOW, 2)
    # Spine
    line(d, (16, 13 + bob), (16, 27 + bob), BONE_SHADOW, 2)
    # Long ribcage
    for y in range(15, 25, 2):
        line(d, (11, y + bob), (20, y + bob), BONE)
        px(d, 11, y + bob, BONE_SHADOW)
        px(d, 20, y + bob, BONE_DARK)
    # Bone shoulder spikes
    out_poly(d, [(8, 15 + bob), (12, 14 + bob), (10, 12 + bob), (12, 17 + bob)], BONE)
    out_poly(d, [(20, 14 + bob), (24, 15 + bob), (20, 17 + bob), (22, 12 + bob)], BONE)
    # Pelvis
    out_poly(d, [(12, 25 + bob), (20, 25 + bob), (19, 29 + bob), (16, 27 + bob), (12, 29 + bob)], BONE)
    # Front leg
    line(d, (18 - off // 2, 28), (20 - off // 2, 39), BONE, 2)
    px(d, 21 - off // 2, 39, BONE_SHADOW)
    # Front arm long
    line(d, (21, 16 + bob), (25, 25 + bob), BONE, 2)
    line(d, (25, 25 + bob), (23, 31 + bob), BONE_SHADOW, 2)
    # Neck and elongated skull
    rect(d, 15, 11 + bob, 2, 2, BONE_SHADOW)
    out_rect(d, 12, 4 + bob, 8, 8, BONE)
    rect(d, 13, 11 + bob, 6, 1, BONE_SHADOW)
    # Horns
    px(d, 11, 3 + bob, BONE)
    px(d, 10, 2 + bob, BONE_SHADOW)
    px(d, 20, 3 + bob, BONE)
    px(d, 21, 2 + bob, BONE_SHADOW)
    # Eyes
    rect(d, 13, 6 + bob, 2, 2, INK)
    rect(d, 17, 6 + bob, 2, 2, INK)
    px(d, 14, 7 + bob, EYE_RED)
    px(d, 18, 7 + bob, EYE_RED)
    # Ribs glow rune
    px(d, 16, 19 + bob, (163, 49, 58, 255))


def draw_skeleton_robed(d, f):
    bob = BOB[f]
    sway = [-1, 0, 1, 0][f]
    # Back sleeve
    out_poly(d, [(10, 20 + bob), (13, 20 + bob), (11, 31), (7, 28)], PURPLE_DARK)
    # Robe
    out_poly(d, [(13, 12 + bob), (20, 12 + bob), (25 + sway, 38), (18, 36), (16, 39), (12 - sway, 36), (8 + sway, 38)], PURPLE_DARK)
    # Robe highlight
    poly(d, [(14, 14 + bob), (19, 14 + bob), (22 + sway, 35), (18, 33), (16, 37), (12 - sway, 34)], PURPLE)
    line(d, (16, 15 + bob), (16, 35), PURPLE_LIGHT)
    # Tattered hem
    for x, y in [(10, 37), (13, 36), (19, 36), (22, 37)]:
        px(d, x, y, (25, 14, 33, 255))
    # Gold trim
    line(d, (13, 13 + bob), (20, 13 + bob), GOLD_DARK)
    line(d, (10, 25), (11, 31), GOLD_DARK)
    # Front sleeve / bone hand
    out_poly(d, [(20, 20 + bob), (24, 20 + bob), (26, 29), (22, 31)], PURPLE)
    line(d, (24, 29), (26, 32), BONE)
    px(d, 27, 32, BONE_SHADOW)
    # Hood
    out_poly(d, [(13, 13 + bob), (13, 8 + bob), (16, 4 + bob), (20, 7 + bob), (21, 14 + bob), (17, 15 + bob)], PURPLE)
    poly(d, [(14, 13 + bob), (14, 9 + bob), (17, 6 + bob), (19, 8 + bob), (20, 14 + bob)], (34, 20, 43, 255))
    # Skull face
    rect(d, 15, 9 + bob, 4, 3, BONE)
    px(d, 15, 9 + bob, INK)
    px(d, 18, 9 + bob, INK)
    px(d, 16, 10 + bob, EYE_RED)
    px(d, 18, 10 + bob, EYE_RED)
    px(d, 17, 11 + bob, BONE_SHADOW)
    # Chest sigil
    line(d, (16, 18 + bob), (16, 23), GOLD_DARK)
    px(d, 15, 20 + bob, GOLD)
    px(d, 17, 20 + bob, GOLD)


def draw_zombie(d, f):
    bob = BOB[f]
    off = STEP[f]
    # Back arm hanging
    out_poly(d, [(9, 18 + bob), (12, 18 + bob), (11, 28 + bob), (8, 27 + bob)], ZOMBIE_DARK)
    px(d, 9, 28 + bob, BLOOD_DARK)
    # Back leg
    out_rect(d, 12 + off // 2, 29, 5, 8, (57, 50, 41, 255))
    rect(d, 11 + off // 2, 36, 5, 3, ZOMBIE_DARK)
    # Hunched torso
    out_poly(d, [(10, 17 + bob), (21, 16 + bob), (23, 28), (9, 29)], ZOMBIE_DARK)
    # Torn shirt
    poly(d, [(11, 17 + bob), (20, 16 + bob), (21, 23 + bob), (17, 22 + bob), (15, 25 + bob), (12, 22 + bob), (9, 23 + bob)], (72, 60, 50, 255))
    # Exposed ribs / wound
    rect(d, 14, 22 + bob, 5, 3, BLOOD_DARK)
    px(d, 15, 22 + bob, BONE_SHADOW)
    px(d, 17, 23 + bob, BONE_SHADOW)
    px(d, 16, 24 + bob, BLOOD_LIGHT)
    # Belt / rags
    rect(d, 10, 27, 12, 2, (47, 37, 30, 255))
    # Front leg dragging
    out_rect(d, 17 - off // 2, 29, 5, 8, (57, 50, 41, 255))
    rect(d, 17 - off // 2, 36, 6, 3, ZOMBIE_DARK)
    # Front arm reaching
    out_poly(d, [(21, 18 + bob), (26, 19 + bob), (27, 22 + bob), (23, 24 + bob)], ZOMBIE)
    px(d, 27, 22 + bob, ZOMBIE_LIGHT)
    px(d, 27, 23 + bob, BLOOD)
    # Neck / head
    rect(d, 15, 15 + bob, 4, 2, ZOMBIE_DARK)
    out_rect(d, 13, 9 + bob, 8, 7, ZOMBIE)
    # Hair patch
    rect(d, 13, 8 + bob, 6, 2, (41, 36, 30, 255))
    px(d, 12, 10 + bob, ZOMBIE_DARK)
    # Eyes
    _eye(d, 15, 11 + bob, (245, 196, 86, 255))
    px(d, 19, 12 + bob, ZOMBIE_DARK)
    # Mouth blood
    rect(d, 15, 14 + bob, 4, 1, BLOOD_DARK)
    px(d, 18, 15 + bob, BLOOD)
    # Stitches / scars
    px(d, 14, 20 + bob, ZOMBIE_LIGHT)
    px(d, 19, 18 + bob, ZOMBIE_LIGHT)


ENEMY_DRAWERS = [
    ("skeleton_common", draw_skeleton_common),
    ("skeleton_tall", draw_skeleton_tall),
    ("skeleton_robed", draw_skeleton_robed),
    ("zombie", draw_zombie),
]


# ---------------------------------------------------------------------------
# Boss
# ---------------------------------------------------------------------------
def draw_la_parca(d, f):
    sway = [-2, 0, 2, 0][f]
    hem = [0, 1, 0, 2][f]
    # Outer cloak
    out_poly(d, [
        (24, 9), (13 + sway, 24), (8 + sway, 59 - hem), (14, 62), (19, 57),
        (24, 61), (29, 56), (34, 62), (40 + sway, 59 - hem), (35 + sway, 24),
    ], (38, 25, 49, 255))
    # Cloak body
    poly(d, [
        (24, 12), (16 + sway, 26), (12 + sway, 56), (18, 58), (22, 54),
        (24, 58), (27, 53), (31, 58), (37 + sway, 57), (32 + sway, 26),
    ], PURPLE_DARK)
    # Violet rim / folds
    line(d, (14 + sway, 30), (12 + sway, 55), PURPLE)
    line(d, (30, 30), (35 + sway, 54), PURPLE)
    line(d, (20, 24), (17, 51), (57, 33, 66, 255))
    line(d, (29, 23), (32, 52), (57, 33, 66, 255))
    # Tattered hem strips
    for i, x in enumerate((11, 15, 19, 24, 29, 33, 38)):
        drop = 3 + (i % 3) + hem
        line(d, (x + sway // 2, 54), (x + (i % 2), 54 + drop), (28, 18, 37, 255))
    # Rune trim
    for y in (37, 43, 49):
        px(d, 17, y, (112, 62, 119, 255))
        px(d, 31, y + 1, (112, 62, 119, 255))
    # Shoulder bone spikes
    out_poly(d, [(14, 23), (9, 20), (12, 28), (18, 27)], BONE_DARK)
    out_poly(d, [(34, 23), (39, 20), (36, 28), (30, 27)], BONE_DARK)
    px(d, 10, 21, BONE_SHADOW)
    px(d, 38, 21, BONE_SHADOW)
    # Arms / sleeves
    out_poly(d, [(11, 28), (15, 30), (12, 43), (8, 41)], (46, 30, 58, 255))
    out_poly(d, [(33, 28), (37, 31), (41, 42), (36, 43)], (46, 30, 58, 255))
    # Skeletal hands
    for hx, hy in ((9, 44), (39, 44)):
        for i in range(3):
            line(d, (hx, hy), (hx + (i - 1) * 2, hy + 6), BONE_SHADOW)
        px(d, hx, hy, BONE)
    # Rope belt with skulls
    line(d, (14, 40), (34, 40), (98, 70, 52, 255))
    for sx in (17, 23, 29):
        out_rect(d, sx, 39, 3, 3, BONE_SHADOW)
        px(d, sx, 40, INK)
        px(d, sx + 2, 40, INK)
    # Hood
    out_poly(d, [(16, 20), (16, 12), (21, 5), (24, 3), (30, 8), (32, 20), (26, 22), (21, 22)], (49, 31, 62, 255))
    poly(d, [(18, 19), (18, 13), (22, 7), (24, 6), (28, 10), (30, 19), (26, 20), (21, 20)], (27, 18, 37, 255))
    # Void face
    out_poly(d, [(19, 19), (20, 12), (24, 9), (28, 12), (29, 19), (24, 21)], (12, 9, 18, 255))
    # Glowing eyes
    _eye(d, 21, 13, EYE_GHOST)
    _eye(d, 26, 13, EYE_GHOST)
    px(d, 22, 15, (195, 187, 116, 255))
    px(d, 25, 15, (195, 187, 116, 255))
    # Hood highlight
    line(d, (20, 11), (23, 6), (78, 51, 91, 255))
    line(d, (25, 6), (29, 11), (78, 51, 91, 255))
    # Crown / bone halo
    px(d, 24, 2, GOLD_DARK)
    px(d, 20, 4, GOLD_DARK)
    px(d, 28, 4, GOLD_DARK)


def build_all():
    print("Characters:")
    for filename, painter in PLAYERS.items():
        sheet = canvas(FRAME_W * 4, FRAME_H)
        for f in range(4):
            frame = canvas(FRAME_W, FRAME_H)
            fd = draw(frame)
            painter(fd, f)
            sheet.alpha_composite(frame, (f * FRAME_W, 0))
        save(sheet, filename)

    sheet = canvas(FRAME_W * 4, FRAME_H * len(ENEMY_DRAWERS))
    for row, (_, painter) in enumerate(ENEMY_DRAWERS):
        for f in range(4):
            frame = canvas(FRAME_W, FRAME_H)
            fd = draw(frame)
            painter(fd, f)
            sheet.alpha_composite(frame, (f * FRAME_W, row * FRAME_H))
    save(sheet, "enemy_skeleton.png")

    sheet = canvas(BOSS_W * 4, BOSS_H)
    for f in range(4):
        frame = canvas(BOSS_W, BOSS_H)
        fd = draw(frame)
        draw_la_parca(fd, f)
        sheet.alpha_composite(frame, (f * BOSS_W, 0))
    save(sheet, "boss_la_parca.png")
