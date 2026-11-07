#!/usr/bin/env python3
"""Player, enemy and boss sprite sheets (4 animation frames each)."""

from __future__ import annotations

from .common import (
    BEARD, BLOOD, BLOOD_DARK, BLOOD_LIGHT, BONE, BONE_DARK, BONE_SHADOW,
    EYE_GHOST, EYE_RED, GOLD, GOLD_DARK, INK, INK_SOFT,
    PURPLE, PURPLE_DARK, PURPLE_LIGHT, ZOMBIE, ZOMBIE_DARK, ZOMBIE_LIGHT,
    canvas, draw, line, out_poly, out_rect, poly, px, rect, save,
)

FRAME_W, FRAME_H = 32, 40
BOSS_W, BOSS_H = 48, 64

STEP = [-2, 0, 2, 0]
BOB = [0, -1, 0, -1]

# ---------------------------------------------------------------------------
# Player palette
# ---------------------------------------------------------------------------
# The survivors use the same ash / bone / dried-blood register as the imported
# bestiary instead of the old saturated "adventure" colours, so they sit in the
# same world as the mobs.
ASH_HI = (198, 191, 183, 255)
ASH = (150, 143, 137, 255)
ASH_MID = (104, 99, 100, 255)
ASH_DARK = (66, 63, 71, 255)
VOID = (22, 20, 29, 255)

SKIN_M = (170, 152, 134, 255)
SKIN_M_SH = (126, 110, 100, 255)
SKIN_M_BL = (146, 92, 86, 255)

BONE_M = (190, 184, 174, 255)
BONE_M_SH = (146, 140, 132, 255)

STEEL_M = (110, 113, 122, 255)
STEEL_M_D = (70, 72, 82, 255)
STEEL_M_H = (148, 150, 158, 255)

LEATH_M = (92, 74, 60, 255)
LEATH_M_D = (56, 45, 39, 255)
LEATH_M_L = (120, 99, 80, 255)

CLOTH_M = (102, 72, 76, 255)
CLOTH_M_D = (68, 46, 53, 255)
BLOOD_M = (118, 40, 45, 255)
BLOOD_M_D = (74, 27, 33, 255)

# Cool grey hair and beard keep the Bárbaro's face readable against the warm
# brown fur pelt draped over his shoulders.
HAIR_GRAY = (84, 76, 72, 255)
BEARD_GRAY = (108, 96, 88, 255)
BEARD_GRAY_D = (76, 66, 62, 255)

# Four-step walk: contact / passing / contact / passing. Frame 1 is grounded so
# the idle pose never floats. `stance` deepens the forward foot and `lift`
# raises the swinging one; the swinging leg also closes toward the centre line.
NEAR_STANCE = [0, 0, -1, 0]
FAR_STANCE = [-1, 0, 0, 0]
NEAR_LIFT = [0, 0, 0, 3]
FAR_LIFT = [0, 3, 0, 0]
ARM_SWING = [-2, 0, 2, 0]
SWAY = [1, 0, -1, 0]


def _eye(d, x, y, color=EYE_RED):
    px(d, x, y, color)
    px(d, x + 1, y, color)


# ---------------------------------------------------------------------------
# Players
# ---------------------------------------------------------------------------
def _player_leg(d, x, stance, lift, cloth, shade, boot):
    """One leg. `stance` moves the foot forward/back, `lift` raises it."""
    by = 36 + stance - lift
    out_rect(d, x, 27, 4, by - 27, cloth)
    rect(d, x + 1, 29, 1, max(1, by - 31), shade)
    out_rect(d, x, by, 4, 3, boot)
    px(d, x + 1, by + 2, VOID)


def draw_guerrero(d, f):
    bob = BOB[f]
    swing = ARM_SWING[f]
    # Back leg / arm.
    _player_leg(d, 12 if FAR_LIFT[f] else 11, FAR_STANCE[f], FAR_LIFT[f], LEATH_M_D, VOID, LEATH_M_D)
    out_poly(d, [
        (8, 14 + bob), (11, 13 + bob),
        (11, 22 + bob - swing), (8, 23 + bob - swing),
    ], STEEL_M_D)
    # Torso: mail hauberk under a bloodied tabard.
    out_poly(d, [
        (9, 13 + bob), (22, 13 + bob), (22, 24 + bob),
        (20, 28), (11, 28), (9, 24 + bob),
    ], STEEL_M_D)
    poly(d, [
        (10, 15 + bob), (21, 15 + bob), (21, 23 + bob),
        (19, 26), (12, 26), (10, 23 + bob),
    ], STEEL_M)
    poly(d, [(14, 16 + bob), (18, 16 + bob), (19, 27), (13, 27)], CLOTH_M)
    rect(d, 15, 17 + bob, 1, 10, CLOTH_M_D)
    px(d, 17, 22 + bob, BLOOD_M)
    px(d, 18, 23, BLOOD_M_D)
    line(d, (10, 19 + bob), (12, 20 + bob), STEEL_M_H)
    rect(d, 11, 25 + bob, 9, 2, LEATH_M_D)
    px(d, 15, 25 + bob, ASH)
    # Pauldrons.
    out_poly(d, [(7, 14 + bob), (12, 12 + bob), (13, 17 + bob), (8, 18 + bob)], STEEL_M)
    poly(d, [(8, 14 + bob), (12, 13 + bob), (12, 16 + bob), (8, 17 + bob)], STEEL_M_H)
    out_poly(d, [(19, 12 + bob), (24, 14 + bob), (23, 18 + bob), (18, 17 + bob)], STEEL_M)
    poly(d, [(20, 13 + bob), (23, 14 + bob), (22, 16 + bob), (19, 16 + bob)], STEEL_M_H)
    # Front leg and sword arm.
    _player_leg(d, 17 if NEAR_LIFT[f] else 18, NEAR_STANCE[f], NEAR_LIFT[f], LEATH_M, VOID, LEATH_M_D)
    out_poly(d, [
        (20, 14 + bob), (23, 15 + bob),
        (24 + swing, 22 + bob), (21 + swing, 24 + bob),
    ], STEEL_M_D)
    rect(d, 21 + swing, 16 + bob, 3, 4, STEEL_M)
    rect(d, 21 + swing, 20 + bob, 3, 3, LEATH_M)
    px(d, 21 + swing, 23 + bob, SKIN_M_SH)
    # Neck and great helm.
    rect(d, 15, 11 + bob, 2, 2, SKIN_M_SH)
    out_poly(d, [
        (12, 12 + bob), (12, 6 + bob), (16, 3 + bob),
        (20, 6 + bob), (20, 12 + bob),
    ], STEEL_M)
    # Closed great helm: a dark visor slit with two dim eye glints.
    rect(d, 13, 8 + bob, 6, 4, ASH_DARK)
    rect(d, 13, 9 + bob, 6, 1, VOID)
    px(d, 14, 9 + bob, ASH)
    px(d, 18, 9 + bob, ASH)
    rect(d, 16, 8 + bob, 1, 5, STEEL_M_H)
    rect(d, 13, 11 + bob, 6, 1, VOID)
    px(d, 15, 12 + bob, ASH_MID)
    px(d, 17, 12 + bob, ASH_MID)
    line(d, (14, 5 + bob), (17, 4 + bob), STEEL_M_H)
    rect(d, 15, 2 + bob, 2, 2, CLOTH_M_D)
    # Scabbard.
    line(d, (11, 26), (7, 34), LEATH_M_L)
    px(d, 7, 34, ASH)


def draw_barbaro(d, f):
    bob = BOB[f]
    swing = ARM_SWING[f]
    sway = [1, 0, -1, 0][f]
    # Back leg / bare arm.
    _player_leg(d, 12 if FAR_LIFT[f] else 11, FAR_STANCE[f], FAR_LIFT[f], LEATH_M, VOID, LEATH_M_D)
    out_poly(d, [
        (7, 14 + bob), (11, 13 + bob),
        (11, 22 + bob - swing), (7, 24 + bob - swing),
    ], SKIN_M_SH)
    # Heavy bare torso.
    out_poly(d, [
        (9, 13 + bob), (23, 13 + bob), (23, 23 + bob),
        (21, 27), (11, 27), (9, 23 + bob),
    ], SKIN_M_SH)
    poly(d, [
        (10, 15 + bob), (22, 15 + bob), (22, 22 + bob),
        (20, 25), (12, 25), (10, 22 + bob),
    ], SKIN_M)
    # Left-side shadow, sternum, pecs and an old wound keep the torso from
    # reading as a flat slab.
    rect(d, 10, 16 + bob, 2, 7, SKIN_M_SH)
    rect(d, 16, 16 + bob, 1, 4, SKIN_M_SH)
    line(d, (12, 18 + bob), (14, 19 + bob), SKIN_M_SH)
    line(d, (19, 18 + bob), (21, 19 + bob), SKIN_M_SH)
    px(d, 14, 21 + bob, SKIN_M_BL)
    px(d, 13, 22 + bob, SKIN_M_BL)
    # Fur pelt over the shoulders, open at the chest.
    out_poly(d, [
        (6, 16 + bob), (10, 13 + bob), (16, 16 + bob), (21, 13 + bob), (25, 16 + bob),
        (23, 19 + bob), (20, 17 + bob), (16, 19 + bob), (12, 17 + bob), (8, 19 + bob),
    ], BEARD)
    for x, y in [(8, 16), (11, 14), (21, 14), (23, 16), (9, 18), (21, 18)]:
        px(d, x, y + bob, (112, 87, 66, 255))
    # A single bone charm hanging from the pelt.
    px(d, 16, 19 + bob, BONE_M_SH)
    px(d, 16, 20 + bob, BONE_M)
    # Ragged apron.
    rect(d, 11, 22 + bob, 10, 5, LEATH_M_D)
    poly(d, [(13, 22 + bob), (19, 22 + bob), (20 + sway, 28), (12 + sway, 28)], CLOTH_M_D)
    px(d, 16, 24 + bob, BLOOD_M)
    px(d, 17, 26 + bob, BLOOD_M_D)
    rect(d, 10, 26, 12, 2, LEATH_M)
    px(d, 15, 26, ASH_MID)
    # Front leg and arm.
    _player_leg(d, 17 if NEAR_LIFT[f] else 18, NEAR_STANCE[f], NEAR_LIFT[f], LEATH_M, VOID, LEATH_M_D)
    out_poly(d, [
        (21, 13 + bob), (26, 15 + bob),
        (25 + swing, 24 + bob), (21 + swing, 24 + bob),
    ], SKIN_M)
    rect(d, 22 + swing, 16 + bob, 1, 5, SKIN_M_SH)
    rect(d, 22 + swing, 22 + bob, 3, 2, LEATH_M)
    px(d, 22 + swing, 24 + bob, SKIN_M_BL)
    # Neck and shaved head.
    rect(d, 14, 11 + bob, 5, 2, SKIN_M_SH)
    out_poly(d, [(12, 11 + bob), (12, 6 + bob), (16, 4 + bob), (20, 6 + bob), (20, 11 + bob)], SKIN_M)
    rect(d, 12, 5 + bob, 8, 2, HAIR_GRAY)
    px(d, 11, 8 + bob, HAIR_GRAY)
    rect(d, 13, 7 + bob, 6, 1, SKIN_M_SH)
    # Grey beard: a different value from the pelt, so the face stays readable.
    out_poly(d, [
        (12, 10 + bob), (20, 10 + bob), (19, 12 + bob),
        (16, 13 + bob), (13, 12 + bob),
    ], BEARD_GRAY)
    rect(d, 13, 10 + bob, 6, 1, BEARD_GRAY)
    px(d, 14, 12 + bob, BEARD_GRAY_D)
    px(d, 18, 12 + bob, HAIR_GRAY)
    # Scar and eyes under a heavy brow.
    line(d, (12, 7 + bob), (14, 10 + bob), SKIN_M_BL)
    px(d, 14, 9 + bob, VOID)
    px(d, 17, 9 + bob, VOID)
    px(d, 16, 9 + bob, SKIN_M_SH)


def draw_asesino(d, f):
    bob = BOB[f]
    swing = ARM_SWING[f]
    sway = [1, 0, -1, 0][f]
    # Back leg / arm.
    _player_leg(d, 12 if FAR_LIFT[f] else 11, FAR_STANCE[f], FAR_LIFT[f], ASH_DARK, VOID, LEATH_M_D)
    out_poly(d, [
        (9, 15 + bob), (11, 14 + bob),
        (11, 22 + bob - swing), (9, 23 + bob - swing),
    ], ASH_DARK)
    # Cloak tails behind the hips: narrow strips so the silhouette stays lean.
    out_poly(d, [(10, 21 + bob), (13, 20 + bob), (12 + sway, 32), (8 + sway, 29)], ASH_DARK)
    out_poly(d, [(18, 21 + bob), (21, 23 + bob), (22 + sway, 29), (18 + sway, 32)], ASH_DARK)
    # Lean torso.
    out_poly(d, [
        (11, 14 + bob), (20, 14 + bob), (21, 24 + bob),
        (19, 28), (12, 28), (10, 24 + bob),
    ], ASH_DARK)
    poly(d, [
        (12, 16 + bob), (19, 16 + bob), (20, 23 + bob),
        (18, 26), (13, 26), (11, 23 + bob),
    ], ASH_MID)
    # Harness straps.
    line(d, (12, 16 + bob), (19, 25 + bob), LEATH_M_L)
    line(d, (19, 16 + bob), (13, 25 + bob), LEATH_M_D)
    rect(d, 11, 25 + bob, 9, 2, LEATH_M_D)
    px(d, 15, 25 + bob, ASH)
    # Pouch.
    out_rect(d, 17, 22 + bob, 4, 4, LEATH_M)
    px(d, 18, 23 + bob, ASH_MID)
    # Front leg and arm.
    _player_leg(d, 17 if NEAR_LIFT[f] else 18, NEAR_STANCE[f], NEAR_LIFT[f], ASH_DARK, VOID, LEATH_M_D)
    out_poly(d, [
        (19, 15 + bob), (22, 16 + bob),
        (23 + swing, 22 + bob), (20 + swing, 23 + bob),
    ], ASH_MID)
    rect(d, 20 + swing, 17 + bob, 2, 4, ASH_DARK)
    px(d, 21 + swing, 23 + bob, SKIN_M_SH)
    # Hood.
    out_poly(d, [
        (11, 15 + bob), (11, 8 + bob), (16, 3 + bob),
        (20, 8 + bob), (21, 16 + bob),
    ], ASH_DARK)
    poly(d, [(13, 14 + bob), (13, 9 + bob), (16, 5 + bob), (19, 9 + bob), (19, 14 + bob)], VOID)
    # Only a strip of eyes shows above the cloth mask.
    rect(d, 14, 9 + bob, 4, 3, SKIN_M_SH)
    rect(d, 14, 9 + bob, 4, 1, SKIN_M_BL)
    px(d, 14, 10 + bob, VOID)
    px(d, 17, 10 + bob, VOID)
    rect(d, 14, 12 + bob, 4, 2, CLOTH_M_D)
    px(d, 15, 13 + bob, CLOTH_M)
    line(d, (13, 10 + bob), (13, 8 + bob), ASH_MID)
    # Scarf.
    out_poly(d, [
        (11, 14 + bob), (20, 14 + bob), (21, 17 + bob),
        (16, 16 + bob), (10 + sway, 18 + bob), (10, 15 + bob),
    ], CLOTH_M_D)
    px(d, 13, 16 + bob, CLOTH_M)
    # Belt knives.
    line(d, (19, 25), (22, 23), STEEL_M_H)
    line(d, (11, 25), (8, 23), STEEL_M)
    px(d, 8, 23, ASH_MID)


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
