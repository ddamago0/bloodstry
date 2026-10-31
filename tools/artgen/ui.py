#!/usr/bin/env python3
"""HUD icons, limb pickups and the custom pixel cursor."""

from __future__ import annotations

from .common import (
    BLOOD, BLOOD_DARK, BLOOD_LIGHT, BONE, BONE_DARK, BONE_SHADOW,
    EYE_GHOST, EYE_RED, GOLD, GOLD_DARK, INK, LEATHER, LEATHER_DARK,
    SKIN, SKIN_BLOOD, SKIN_SHADOW, STEEL, STEEL_DARK, STEEL_LIGHT,
    STONE, STONE_DARK, canvas, draw, line, out_poly, out_rect, poly, px,
    rect, save,
)

ICON = 16
ICON_COLS = 8
ICON_ROWS = 3


def _outline(d, x, y, w, h, fill):
    out_rect(d, x, y, w, h, fill)


def icon_heart(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 8, y + 14), (x + 2, y + 8), (x + 2, y + 4), (x + 5, y + 2), (x + 7, y + 4), (x + 8, y + 6), (x + 9, y + 4), (x + 11, y + 2), (x + 14, y + 4), (x + 14, y + 8)], BLOOD_DARK)
    poly(d, [(x + 8, y + 12), (x + 3, y + 8), (x + 3, y + 4), (x + 5, y + 3), (x + 7, y + 5), (x + 8, y + 7), (x + 9, y + 5), (x + 11, y + 3), (x + 13, y + 4), (x + 13, y + 8)], BLOOD)
    px(d, x + 5, y + 5, BLOOD_LIGHT)
    px(d, x + 6, y + 4, BLOOD_LIGHT)
    px(d, x + 4, y + 6, (205, 78, 84, 255))


def icon_drop(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 8, y + 1), (x + 13, y + 8), (x + 12, y + 13), (x + 8, y + 15), (x + 4, y + 13), (x + 3, y + 8)], BLOOD_DARK)
    poly(d, [(x + 8, y + 3), (x + 12, y + 8), (x + 11, y + 12), (x + 8, y + 14), (x + 5, y + 12), (x + 4, y + 8)], BLOOD)
    px(d, x + 6, y + 7, BLOOD_LIGHT)
    px(d, x + 6, y + 8, BLOOD_LIGHT)
    px(d, x + 5, y + 9, (205, 78, 84, 255))


def icon_skull(d, ox, oy):
    x, y = ox, oy
    out_rect(d, x + 3, y + 2, 10, 9, BONE_SHADOW)
    out_rect(d, x + 5, y + 10, 6, 4, BONE_SHADOW)
    rect(d, x + 4, y + 3, 8, 8, BONE)
    rect(d, x + 5, y + 10, 6, 3, BONE_SHADOW)
    rect(d, x + 5, y + 5, 2, 2, INK)
    rect(d, x + 9, y + 5, 2, 2, INK)
    px(d, x + 6, y + 6, EYE_RED)
    px(d, x + 10, y + 6, EYE_RED)
    px(d, x + 8, y + 8, BONE_DARK)
    for tx in (6, 8, 10):
        px(d, x + tx, y + 11, BONE_DARK)
    px(d, x + 4, y + 4, (243, 238, 221, 255))


def icon_sword(d, ox, oy):
    x, y = ox, oy
    # blade
    out_poly(d, [(x + 11, y + 1), (x + 14, y + 2), (x + 6, y + 10), (x + 4, y + 9)], STEEL_DARK)
    poly(d, [(x + 11, y + 2), (x + 13, y + 2), (x + 6, y + 9), (x + 5, y + 9)], STEEL)
    line(d, (x + 11, y + 3), (x + 6, y + 8), STEEL_LIGHT)
    # guard
    out_rect(d, x + 3, y + 9, 6, 2, GOLD_DARK)
    rect(d, x + 3, y + 10, 6, 1, GOLD)
    # grip
    out_rect(d, x + 2, y + 11, 3, 3, LEATHER_DARK)
    rect(d, x + 2, y + 11, 2, 2, LEATHER)
    px(d, x + 1, y + 14, GOLD)


def icon_shield(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 8, y + 1), (x + 14, y + 4), (x + 13, y + 10), (x + 8, y + 15), (x + 3, y + 10), (x + 2, y + 4)], STEEL_DARK)
    poly(d, [(x + 8, y + 3), (x + 12, y + 5), (x + 11, y + 10), (x + 8, y + 13), (x + 5, y + 10), (x + 4, y + 5)], STEEL)
    line(d, (x + 6, y + 5), (x + 5, y + 9), STEEL_LIGHT)
    line(d, (x + 8, y + 4), (x + 8, y + 12), BONE_SHADOW)
    px(d, x + 8, y + 8, GOLD)


def icon_bone(d, ox, oy):
    x, y = ox, oy
    # diagonal bone
    line(d, (x + 4, y + 12), (x + 12, y + 4), BONE_SHADOW, 3)
    line(d, (x + 4, y + 12), (x + 12, y + 4), BONE, 1)
    for cx, cy in ((3, 11), (4, 14), (12, 2), (14, 4)):
        px(d, x + cx, y + cy, BONE)
        px(d, x + cx + 1, y + cy, BONE_SHADOW)
    px(d, x + 8, y + 8, BONE_DARK)


def icon_boot(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 5, y + 2), (x + 9, y + 2), (x + 9, y + 9), (x + 14, y + 10), (x + 14, y + 14), (x + 4, y + 14), (x + 4, y + 9), (x + 5, y + 6)], LEATHER_DARK)
    poly(d, [(x + 6, y + 3), (x + 8, y + 3), (x + 8, y + 9), (x + 13, y + 10), (x + 13, y + 12), (x + 5, y + 12), (x + 5, y + 9)], LEATHER)
    rect(d, x + 5, y + 12, 9, 2, (35, 31, 38, 255))
    px(d, x + 9, y + 5, GOLD_DARK)
    px(d, x + 10, y + 5, GOLD_DARK)


def icon_fist(d, ox, oy):
    x, y = ox, oy
    out_rect(d, x + 4, y + 5, 8, 7, SKIN_SHADOW)
    out_rect(d, x + 3, y + 7, 2, 4, SKIN_SHADOW)
    rect(d, x + 5, y + 6, 6, 5, SKIN)
    rect(d, x + 6, y + 5, 4, 2, SKIN)
    for fx in (6, 8, 10):
        px(d, x + fx, y + 6, SKIN_SHADOW)
    line(d, (x + 5, y + 9), (x + 10, y + 9), SKIN_BLOOD)
    # cuff
    rect(d, x + 5, y + 12, 6, 2, LEATHER)
    px(d, x + 10, y + 7, SKIN_BLOOD)


def icon_magnet(d, ox, oy):
    x, y = ox, oy
    # horseshoe
    d.arc((x + 3, y + 1, x + 13, y + 12), 180, 360, fill=STEEL_DARK, width=4)
    d.arc((x + 4, y + 2, x + 12, y + 11), 180, 360, fill=STEEL, width=2)
    out_rect(d, x + 2, y + 7, 4, 7, BLOOD_DARK)
    out_rect(d, x + 10, y + 7, 4, 7, BLOOD_DARK)
    rect(d, x + 3, y + 7, 2, 5, BLOOD)
    rect(d, x + 11, y + 7, 2, 5, BLOOD)
    px(d, x + 6, y + 4, STEEL_LIGHT)


def icon_hourglass(d, ox, oy):
    x, y = ox, oy
    out_rect(d, x + 4, y + 1, 8, 2, GOLD_DARK)
    out_rect(d, x + 4, y + 13, 8, 2, GOLD_DARK)
    poly(d, [(x + 5, y + 3), (x + 11, y + 3), (x + 8, y + 8)], (119, 93, 60, 255))
    poly(d, [(x + 5, y + 13), (x + 11, y + 13), (x + 8, y + 8)], (119, 93, 60, 255))
    poly(d, [(x + 6, y + 3), (x + 10, y + 3), (x + 8, y + 6)], (194, 158, 98, 255))
    poly(d, [(x + 7, y + 12), (x + 9, y + 12), (x + 8, y + 9)], (194, 158, 98, 255))
    px(d, x + 8, y + 7, GOLD)
    line(d, (x + 5, y + 3), (x + 8, y + 7), GOLD_DARK)
    line(d, (x + 11, y + 3), (x + 8, y + 7), GOLD_DARK)


def icon_level(d, ox, oy):
    x, y = ox, oy
    # five-point bone star / sigil
    pts = [(8, 1), (10, 6), (15, 6), (11, 9), (13, 14), (8, 11), (3, 14), (5, 9), (1, 6), (6, 6)]
    poly(d, [(x + p[0], y + p[1]) for p in pts], GOLD_DARK)
    inner = [(8, 3), (9, 7), (13, 7), (10, 9), (11, 12), (8, 10), (5, 12), (6, 9), (3, 7), (7, 7)]
    poly(d, [(x + p[0], y + p[1]) for p in inner], GOLD)
    px(d, x + 8, y + 8, (246, 221, 148, 255))


def icon_reroll(d, ox, oy):
    x, y = ox, oy
    d.arc((x + 2, y + 2, x + 14, y + 14), 200, 340, fill=STEEL_DARK, width=2)
    d.arc((x + 2, y + 2, x + 14, y + 14), 20, 160, fill=STEEL, width=2)
    # arrows
    poly(d, [(x + 12, y + 1), (x + 15, y + 5), (x + 10, y + 4)], STEEL_LIGHT)
    poly(d, [(x + 4, y + 15), (x + 1, y + 11), (x + 6, y + 12)], STEEL_LIGHT)
    px(d, x + 4, y + 4, GOLD)


def icon_cross(d, ox, oy):
    x, y = ox, oy
    out_rect(d, x + 6, y + 1, 4, 14, STONE_DARK)
    out_rect(d, x + 2, y + 5, 12, 4, STONE_DARK)
    rect(d, x + 7, y + 2, 2, 12, STONE)
    rect(d, x + 3, y + 6, 10, 2, STONE)
    line(d, (x + 7, y + 2), (x + 7, y + 13), (124, 132, 153, 255))
    px(d, x + 11, y + 7, (124, 132, 153, 255))


def icon_eye(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 1, y + 8), (x + 5, y + 4), (x + 11, y + 4), (x + 15, y + 8), (x + 11, y + 12), (x + 5, y + 12)], (70, 60, 66, 255))
    poly(d, [(x + 2, y + 8), (x + 6, y + 5), (x + 10, y + 5), (x + 14, y + 8), (x + 10, y + 11), (x + 6, y + 11)], (198, 190, 171, 255))
    out_rect(d, x + 6, y + 6, 4, 4, BLOOD_DARK)
    rect(d, x + 7, y + 7, 2, 2, EYE_RED)
    px(d, x + 8, y + 8, INK)
    px(d, x + 6, y + 6, (255, 165, 160, 255))


def icon_flame(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 8, y + 1), (x + 13, y + 8), (x + 12, y + 13), (x + 8, y + 15), (x + 4, y + 13), (x + 3, y + 8), (x + 6, y + 5)], BLOOD_DARK)
    poly(d, [(x + 8, y + 3), (x + 12, y + 8), (x + 11, y + 12), (x + 8, y + 14), (x + 5, y + 12), (x + 4, y + 8), (x + 7, y + 6)], (208, 96, 51, 255))
    poly(d, [(x + 8, y + 6), (x + 10, y + 9), (x + 9, y + 12), (x + 7, y + 12), (x + 6, y + 9)], (245, 181, 86, 255))
    px(d, x + 8, y + 11, (252, 232, 162, 255))


def icon_claw(d, ox, oy):
    x, y = ox, oy
    for i, dx in enumerate((4, 8, 12)):
        line(d, (x + dx, y + 2), (x + dx - 2, y + 8), BONE_SHADOW, 2)
        line(d, (x + dx - 2, y + 8), (x + dx - 3 + i, y + 14), BONE, 1)
        px(d, x + dx - 3 + i, y + 13, BONE)
    line(d, (x + 3, y + 7), (x + 13, y + 6), BONE_DARK)
    px(d, x + 5, y + 4, BLOOD)
    px(d, x + 9, y + 3, BLOOD_DARK)


def icon_boss(d, ox, oy):
    x, y = ox, oy
    # horned skull
    out_poly(d, [(x + 3, y + 2), (x + 1, y + 5), (x + 3, y + 6), (x + 4, y + 4), (x + 7, y + 3), (x + 9, y + 3), (x + 12, y + 4), (x + 13, y + 6), (x + 15, y + 5), (x + 13, y + 2)], BONE_SHADOW)
    out_rect(d, x + 4, y + 2, 8, 8, BONE_SHADOW)
    out_rect(d, x + 5, y + 9, 6, 4, BONE_SHADOW)
    rect(d, x + 5, y + 3, 6, 7, BONE)
    rect(d, x + 6, y + 10, 4, 2, BONE_SHADOW)
    rect(d, x + 5, y + 5, 2, 2, INK)
    rect(d, x + 9, y + 5, 2, 2, INK)
    px(d, x + 6, y + 6, EYE_GHOST)
    px(d, x + 10, y + 6, EYE_GHOST)
    px(d, x + 8, y + 8, BONE_DARK)
    px(d, x + 6, y + 10, BONE_DARK)
    px(d, x + 9, y + 10, BONE_DARK)


def icon_pause(d, ox, oy):
    x, y = ox, oy
    out_rect(d, x + 4, y + 2, 3, 12, STEEL_DARK)
    out_rect(d, x + 9, y + 2, 3, 12, STEEL_DARK)
    rect(d, x + 5, y + 3, 1, 10, STEEL_LIGHT)
    rect(d, x + 10, y + 3, 1, 10, STEEL_LIGHT)


ICONS = [
    ("heart", icon_heart), ("blood_drop", icon_drop), ("skull", icon_skull),
    ("sword", icon_sword), ("shield", icon_shield), ("bone", icon_bone),
    ("boot", icon_boot), ("fist", icon_fist), ("magnet", icon_magnet),
    ("hourglass", icon_hourglass), ("level", icon_level), ("reroll", icon_reroll),
    ("cross", icon_cross), ("eye", icon_eye), ("flame", icon_flame),
    ("claw", icon_claw), ("boss", icon_boss), ("pause", icon_pause),
]


def draw_head(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 7, y + 17), (x + 12, y + 19), (x + 14, y + 16), (x + 13, y + 9), (x + 10, y + 4), (x + 6, y + 5), (x + 4, y + 10), (x + 5, y + 15)], (46, 35, 34, 255))
    out_rect(d, x + 6, y + 4, 8, 8, SKIN_SHADOW)
    rect(d, x + 7, y + 5, 6, 6, SKIN)
    rect(d, x + 7, y + 4, 6, 2, (56, 42, 39, 255))
    rect(d, x + 8, y + 12, 4, 2, BLOOD_DARK)
    px(d, x + 9, y + 13, BLOOD)
    px(d, x + 8, y + 15, BLOOD_DARK)
    px(d, x + 11, y + 15, BLOOD)
    # eyes
    rect(d, x + 8, y + 7, 2, 2, INK)
    rect(d, x + 11, y + 7, 2, 2, INK)
    px(d, x + 9, y + 8, EYE_RED)
    px(d, x + 12, y + 8, EYE_RED)
    px(d, x + 7, y + 9, SKIN_BLOOD)
    px(d, x + 10, y + 10, SKIN_SHADOW)


def draw_skeleton_arm(d, ox, oy):
    x, y = ox, oy
    line(d, (x + 4, y + 3), (x + 9, y + 9), BONE_SHADOW, 3)
    line(d, (x + 4, y + 3), (x + 9, y + 9), BONE, 1)
    line(d, (x + 9, y + 9), (x + 14, y + 15), BONE_SHADOW, 3)
    line(d, (x + 9, y + 9), (x + 14, y + 15), BONE, 1)
    for bx, by in ((3, 2), (4, 4), (15, 15), (14, 17), (16, 16)):
        px(d, x + bx, y + by, BONE)
        px(d, x + bx + 1, y + by, BONE_SHADOW)
    px(d, x + 9, y + 9, BONE_DARK)
    px(d, x + 10, y + 10, BONE_DARK)
    # splinter
    line(d, (x + 12, y + 6), (x + 14, y + 9), BONE_SHADOW)


def draw_zombie_arm(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 3, y + 3), (x + 7, y + 2), (x + 13, y + 8), (x + 15, y + 12), (x + 12, y + 16), (x + 8, y + 12), (x + 6, y + 8)], (56, 76, 51, 255))
    poly(d, [(x + 4, y + 4), (x + 7, y + 4), (x + 12, y + 9), (x + 13, y + 11), (x + 11, y + 14), (x + 9, y + 11), (x + 6, y + 8)], (94, 123, 78, 255))
    px(d, x + 6, y + 5, (126, 154, 99, 255))
    px(d, x + 11, y + 10, BLOOD_DARK)
    px(d, x + 12, y + 11, BLOOD)
    # ragged sleeve
    out_poly(d, [(x + 2, y + 2), (x + 5, y + 1), (x + 6, y + 6), (x + 3, y + 7)], (74, 60, 50, 255))
    # exposed bone at elbow
    px(d, x + 9, y + 8, BONE_SHADOW)
    px(d, x + 10, y + 8, BONE_DARK)


def draw_blood_pool(d, ox, oy):
    x, y = ox, oy
    for cx, cy, rx, ry in ((10, 13, 7, 3), (6, 12, 4, 2), (14, 14, 3, 2), (9, 10, 3, 2)):
        d.ellipse((x + cx - rx, y + cy - ry, x + cx + rx, y + cy + ry), fill=BLOOD_DARK)
    for cx, cy, rx, ry in ((10, 12, 5, 2), (6, 11, 3, 1), (13, 13, 2, 1)):
        d.ellipse((x + cx - rx, y + cy - ry, x + cx + rx, y + cy + ry), fill=BLOOD)
    px(d, x + 7, y + 11, BLOOD_LIGHT)
    px(d, x + 8, y + 12, (173, 48, 59, 255))
    # droplets
    for dx, dy in ((3, 7), (16, 9), (14, 17), (5, 16)):
        px(d, x + dx, y + dy, BLOOD_DARK)
        px(d, x + dx + 1, y + dy, BLOOD)


def draw_bone_shard(d, ox, oy):
    x, y = ox, oy
    out_poly(d, [(x + 3, y + 14), (x + 7, y + 4), (x + 12, y + 6), (x + 15, y + 14), (x + 9, y + 16)], (109, 102, 89, 255))
    poly(d, [(x + 5, y + 13), (x + 8, y + 6), (x + 11, y + 7), (x + 13, y + 13), (x + 9, y + 14)], BONE)
    line(d, (x + 8, y + 7), (x + 7, y + 12), BONE_SHADOW)
    px(d, x + 10, y + 9, BONE_DARK)


LIMBS = [
    ("head", draw_head), ("skeleton_arm", draw_skeleton_arm),
    ("zombie_arm", draw_zombie_arm), ("blood_pool", draw_blood_pool),
    ("bone_shard", draw_bone_shard),
]


def draw_cursor() -> Image.Image:
    img = canvas(16, 16)
    d = draw(img)
    # Four bone shards pointing at the centre.
    line(d, (8, 0), (7, 4), BONE_SHADOW)
    line(d, (8, 15), (7, 11), BONE_SHADOW)
    line(d, (0, 8), (4, 7), BONE_SHADOW)
    line(d, (15, 8), (11, 7), BONE_SHADOW)
    # bone cross
    out_rect(d, 6, 0, 3, 5, BONE_SHADOW)
    rect(d, 7, 0, 1, 4, BONE)
    out_rect(d, 6, 11, 3, 5, BONE_SHADOW)
    rect(d, 7, 12, 1, 4, BONE)
    out_rect(d, 0, 6, 5, 3, BONE_SHADOW)
    rect(d, 0, 7, 4, 1, BONE)
    out_rect(d, 11, 6, 5, 3, BONE_SHADOW)
    rect(d, 12, 7, 4, 1, BONE)
    # red gem centre
    out_rect(d, 6, 6, 4, 4, BLOOD_DARK)
    rect(d, 7, 7, 2, 2, EYE_RED)
    px(d, 7, 7, (255, 180, 170, 255))
    return img


def build_all():
    print("UI:")
    sheet = canvas(ICON * ICON_COLS, ICON * ICON_ROWS)
    for i, (name, painter) in enumerate(ICONS):
        cell = canvas(ICON, ICON)
        painter(draw(cell), 0, 0)
        sheet.alpha_composite(cell, ((i % ICON_COLS) * ICON, (i // ICON_COLS) * ICON))
    save(sheet, "ui_icons.png")

    sheet = canvas(20 * len(LIMBS), 20)
    for i, (name, painter) in enumerate(LIMBS):
        cell = canvas(20, 20)
        painter(draw(cell), 0, 0)
        sheet.alpha_composite(cell, (i * 20, 0))
    save(sheet, "limbs_and_blood.png")

    save(draw_cursor(), "cursor.png")
