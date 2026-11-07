#!/usr/bin/env python3
"""Import the external horror packs into Bloodsty's bestiary atlas.

The two source packs are not laid out on a uniform grid:

  * scarymobs sheets contain loose clusters (idle poses, recolours, carcasses)
    floating on transparent canvases.
  * the DICE monsters ship one PNG per animation frame on a fixed 150x150
    canvas.

This tool therefore works in two modes:

  cluster mode  - flood-fill connected components, pick the requested ones,
                  crop them tight.
  animdir mode  - load one PNG per frame, crop every frame with a shared box so
                  the relative motion of the animation survives.

Everything then goes through ``horror_pass`` (desaturate, darken, cool the
shadows, add a 1px near-black rim) and is shelf-packed into a single atlas.
A Lua table with the quad rects is written next to the PNG so the game never
has to guess frame sizes.

Usage:
    python3 tools/import_external.py            # build atlas + lua
    python3 tools/import_external.py --preview  # also write a contact sheet
"""

import argparse
import io
import os
import re
import sys
import zipfile
from collections import deque

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXTERNAL = os.path.join(ROOT, "external_assets")
ATLAS_PATH = os.path.join(ROOT, "assets", "sprites", "horror_bestiary.png")
LUA_PATH = os.path.join(ROOT, "src", "core", "bestiary_atlas.lua")
PREVIEW_PATH = "/tmp/opencode/asset_inspect/bestiary_preview.png"

ZIPS = {
    "scarymobs": (os.path.join(EXTERNAL, "scarymobs.zip"), "scarymobs/"),
    "dice": (os.path.join(EXTERNAL, "Asset Pack.zip"), "Asset Pack/Monsters/"),
}

# --- animation definitions -------------------------------------------------
# scale bakes the final on-screen size into the atlas, so the renderer can
# always draw with scale 1.0. Radius in enemy.lua is tuned by hand per type.
ANIMS = [
    # name             source       file                      clusters  scale fps
    dict(name="skeleton_common", src="scarymobs", file="undead.png",
         clusters=[0, 1], scale=1.0, fps=5),
    dict(name="werewolf", src="scarymobs", file="werebeasts.png",
         clusters=[20, 21], scale=1.0, fps=4),
    dict(name="pallid", src="scarymobs", file="undead.png",
         clusters=[10], scale=1.25, fps=0, lift=0.86),
    dict(name="crawler", src="scarymobs", file="werebeasts.png",
         clusters=[23], scale=0.75, fps=0, lift=1.9),
    dict(name="hound", src="scarymobs", file="smallbeasts.png",
         clusters=[3], scale=0.9, fps=0, lift=1.35),
    dict(name="bone_golem", src="scarymobs", file="beasts.png",
         clusters=[8, 9], scale=1.0, fps=3),
    dict(name="lanker", src="scarymobs", file="cosmic_horror_dude.png",
         clusters=[0], scale=0.45, fps=0),
    # A weeping-angel headstone: a prop rather than a creature.
    dict(name="angel", src="scarymobs", file="smallbeasts.png",
         clusters=[4], scale=1.0, fps=0),
    dict(name="warden", src="dice", anim_dir="DICE 3/Walk",
         scale=0.5, fps=8, common_box=True),
    dict(name="weaver", src="dice", anim_dir="DICE 5/Walk",
         scale=0.42, fps=7, common_box=True),
]

MIN_CLUSTER_PX = 40  # matches the exploratory pass


# ---------------------------------------------------------------------------
# source access
# ---------------------------------------------------------------------------
_zip_cache = {}


def zip_for(key):
    if key not in _zip_cache:
        path, _prefix = ZIPS[key]
        if not os.path.exists(path):
            sys.exit("missing source archive: %s" % path)
        _zip_cache[key] = zipfile.ZipFile(path)
    return _zip_cache[key]


def load_png(src_key, member):
    zf = zip_for(src_key)
    with zf.open(member) as fh:
        return Image.open(io.BytesIO(fh.read())).convert("RGBA")


def list_anim_frames(src_key, anim_dir):
    _path, prefix = ZIPS[src_key]
    root = prefix + anim_dir + "/"

    def order(name):
        m = re.match(r"(\d+)", os.path.basename(name))
        return int(m.group(1)) if m else 0

    names = [n for n in zip_for(src_key).namelist()
             if n.startswith(root) and n.lower().endswith(".png")]
    return sorted(names, key=order)


# ---------------------------------------------------------------------------
# cluster extraction
# ---------------------------------------------------------------------------
def find_clusters(image, min_px=MIN_CLUSTER_PX):
    """8-connected components, returned sorted the same way every run."""
    alpha = np.array(image)[:, :, 3] > 8
    height, width = alpha.shape
    seen = np.zeros_like(alpha, dtype=bool)
    out = []
    for y in range(height):
        for x in range(width):
            if not alpha[y, x] or seen[y, x]:
                continue
            queue = deque([(y, x)])
            seen[y, x] = True
            minx = maxx = x
            miny = maxy = y
            count = 0
            while queue:
                cy, cx = queue.popleft()
                count += 1
                minx = min(minx, cx)
                maxx = max(maxx, cx)
                miny = min(miny, cy)
                maxy = max(maxy, cy)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < height and 0 <= nx < width \
                                and alpha[ny, nx] and not seen[ny, nx]:
                            seen[ny, nx] = True
                            queue.append((ny, nx))
            if count >= min_px:
                out.append((minx, miny, maxx - minx + 1, maxy - miny + 1, count))
    out.sort(key=lambda c: (c[1] // 8, c[0]))
    return out


# ---------------------------------------------------------------------------
# horror pass
# ---------------------------------------------------------------------------
def _dilate(mask):
    out = mask.copy()
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            shifted = np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
            out |= shifted
    return out


def horror_pass(image, saturation=0.60, value=0.94, shadow_tint=(0.055, 0.040, 0.095)):
    """Push any pack toward Bloodsty's ash/bone/blood palette.

    The pass is deliberately conservative: it keeps the artist's shading and
    silhouette but strips the saturated "adventure game" colours, cools the
    darks, and adds a near-black rim so sprites still read against the fog.
    """
    arr = np.asarray(image).astype(np.float32) / 255.0
    rgb, alpha = arr[:, :, :3], arr[:, :, 3]
    luma = rgb[:, :, 0] * 0.299 + rgb[:, :, 1] * 0.587 + rgb[:, :, 2] * 0.114
    rgb = luma[:, :, None] + (rgb - luma[:, :, None]) * saturation
    rgb = rgb * value
    # Tint only the shadows: highlights stay bone-coloured, darks go violet.
    shadow = np.clip(1.0 - luma * 2.1, 0.0, 1.0)[:, :, None]
    rgb = rgb + shadow * np.asarray(shadow_tint, dtype=np.float32)[None, None, :]
    rgb = np.clip(rgb, 0.0, 1.0)

    solid = alpha > 0.06
    rim = _dilate(solid) & ~solid
    # Drop the rim on the canvas border so neighbouring frames don't bleed.
    rim[0, :] = rim[-1, :] = rim[:, 0] = rim[:, -1] = False
    rgb[rim] = np.array([0.015, 0.010, 0.025], dtype=np.float32)

    out = np.dstack([rgb, np.where(solid | rim, 1.0, 0.0)])
    return Image.fromarray((out * 255.0 + 0.5).astype(np.uint8), "RGBA")


# ---------------------------------------------------------------------------
# frame preparation
# ---------------------------------------------------------------------------
def _resize(img, scale):
    w = max(1, int(round(img.width * scale)))
    h = max(1, int(round(img.height * scale)))
    if (w, h) == img.size:
        return img
    return img.resize((w, h), Image.NEAREST)


def prepare_cluster_frames(anim):
    prefix = ZIPS[anim["src"]][1]
    sheet = load_png(anim["src"], prefix + anim["file"])
    clusters = find_clusters(sheet)
    frames = []
    for index in anim["clusters"]:
        if index >= len(clusters):
            sys.exit("%s: cluster %d out of range (%d found)"
                     % (anim["name"], index, len(clusters)))
        x, y, w, h, _px = clusters[index]
        crop = sheet.crop((x, y, x + w, y + h))
        frames.append(_resize(crop, anim["scale"]))
    return frames


def prepare_animdir_frames(anim):
    names = list_anim_frames(anim["src"], anim["anim_dir"])
    if not names:
        sys.exit("%s: no frames under %s" % (anim["name"], anim["anim_dir"]))
    images = [load_png(anim["src"], n) for n in names]

    if anim.get("common_box"):
        # One crop box for the whole animation keeps the feet planted.
        boxes = []
        for img in images:
            a = np.array(img)[:, :, 3] > 8
            ys, xs = np.where(a)
            boxes.append((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
        x0 = min(b[0] for b in boxes)
        y0 = min(b[1] for b in boxes)
        x1 = max(b[2] for b in boxes)
        y1 = max(b[3] for b in boxes)
        images = [img.crop((x0, y0, x1, y1)) for img in images]

    return [_resize(img, anim["scale"]) for img in images]


def build_anim(anim):
    if "clusters" in anim:
        raw = prepare_cluster_frames(anim)
    else:
        raw = prepare_animdir_frames(anim)
    processed = [horror_pass(f, value=0.94 * anim.get("lift", 1.0)) for f in raw]
    return dict(name=anim["name"], fps=anim.get("fps", 0), frames=processed)


# ---------------------------------------------------------------------------
# packing
# ---------------------------------------------------------------------------
def pack(frames, atlas_width=256, pad=2):
    """Shelf pack. Returns (atlas, placements) where placements maps
    (anim_index, frame_index) -> (x, y)."""
    order = sorted(
        ((ai, fi, f) for ai, a in enumerate(frames) for fi, f in enumerate(a["frames"])),
        key=lambda t: (-t[2].height, -t[2].width),
    )
    placements = {}
    x = y = 0
    shelf_h = 0
    for ai, fi, img in order:
        if x + img.width + pad > atlas_width:
            x = 0
            y += shelf_h + pad
            shelf_h = 0
        placements[(ai, fi)] = (x, y)
        x += img.width + pad
        shelf_h = max(shelf_h, img.height)
    height = y + shelf_h
    atlas = Image.new("RGBA", (atlas_width, height), (0, 0, 0, 0))
    for (ai, fi), (px, py) in placements.items():
        atlas.alpha_composite(frames[ai]["frames"][fi], (px, py))
    return atlas, placements


# ---------------------------------------------------------------------------
# output
# ---------------------------------------------------------------------------
def write_lua(anims, placements):
    lines = [
        "-- Generated by tools/import_external.py. Do not edit by hand.",
        "-- Source packs: see CREDITS.md.",
        "return {",
        '    image = "assets/sprites/horror_bestiary.png",',
        "    anims = {",
    ]
    for ai, anim in enumerate(anims):
        lines.append("        %s = {" % anim["name"])
        lines.append("            fps = %d," % anim["fps"])
        lines.append("            frames = {")
        for fi, img in enumerate(anim["frames"]):
            px, py = placements[(ai, fi)]
            lines.append("                { x = %d, y = %d, w = %d, h = %d },"
                         % (px, py, img.width, img.height))
        lines.append("            }")
        lines.append("        },")
    lines += ["    }", "}", ""]
    with open(LUA_PATH, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines))


def write_preview(anims, placements):
    os.makedirs(os.path.dirname(PREVIEW_PATH), exist_ok=True)
    zoom = 3
    cell_w, cell_h = 120, 130
    cols = 4
    rows = (len(anims) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (18, 17, 23, 255))
    draw = ImageDraw.Draw(sheet)
    for ai, anim in enumerate(anims):
        cx = (ai % cols) * cell_w
        cy = (ai // cols) * cell_h
        draw.text((cx + 4, cy + 2), "%s (%d f)" % (anim["name"], len(anim["frames"])),
                  fill=(210, 200, 165, 255))
        # baseline where the feet should land
        base = cy + cell_h - 16
        draw.line([(cx + 4, base), (cx + cell_w - 4, base)], fill=(90, 70, 80, 255))
        x = cx + 6
        for fi, img in enumerate(anim["frames"]):
            big = img.resize((img.width * zoom, img.height * zoom), Image.NEAREST)
            if x + big.width > cx + cell_w - 4:
                break
            sheet.alpha_composite(big, (x, base - big.height))
            x += big.width + 3
    sheet.save(PREVIEW_PATH)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--preview", action="store_true")
    args = parser.parse_args()

    anims = [build_anim(a) for a in ANIMS]
    atlas, placements = pack(anims)

    os.makedirs(os.path.dirname(ATLAS_PATH), exist_ok=True)
    atlas.save(ATLAS_PATH)
    write_lua(anims, placements)

    total = sum(len(a["frames"]) for a in anims)
    print("atlas  %s  %dx%d  (%d anims, %d frames)"
          % (os.path.relpath(ATLAS_PATH, ROOT), atlas.width, atlas.height,
             len(anims), total))
    for anim in anims:
        sizes = {(f.width, f.height) for f in anim["frames"]}
        print("  %-16s %d frame(s) %s fps=%d"
              % (anim["name"], len(anim["frames"]),
                 "/".join("%dx%d" % s for s in sorted(sizes)), anim["fps"]))

    if args.preview:
        write_preview(anims, placements)
        print("preview %s" % PREVIEW_PATH)


if __name__ == "__main__":
    main()
