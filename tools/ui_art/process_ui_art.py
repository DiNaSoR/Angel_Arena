#!/usr/bin/env python3
"""Turn raw gpt-image output into the UI art shipped with the addon.

    python tools/ui_art/process_ui_art.py <raw dir>

<raw dir> is the --out folder of generate_ui_art.py. Results are written to
content/angel_arena/panorama/images/custom_game/arena_ui/.
"""
import sys
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "content" / "angel_arena" / "panorama" / "images" / "custom_game" / "arena_ui"
PANEL_DARK = (6, 8, 13)


def trim(image, pad=6, threshold=8):
    """Crop a transparent image to its visible pixels, leaving a small margin."""
    alpha = image.getchannel("A").point(lambda value: 255 if value > threshold else 0)
    left, top, right, bottom = alpha.getbbox()
    return image.crop((max(0, left - pad), max(0, top - pad),
                       min(image.width, right + pad), min(image.height, bottom + pad)))


def main():
    raw = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)

    # Backdrops are generated at 1920x1088 (sizes must divide by 16) and cropped to 16:9.
    for name in ("pledge_backdrop", "hall_backdrop"):
        Image.open(raw / f"{name}.png").convert("RGB").crop((0, 4, 1920, 1084)).save(OUT / f"{name}.png")

    for name, size in (("sigil_angels", 512), ("sigil_demons", 512), ("frame_corner", 384)):
        image = trim(Image.open(raw / f"{name}.png").convert("RGBA"))
        image.thumbnail((size, size), Image.LANCZOS)
        image.save(OUT / f"{name}.png")

    divider = trim(Image.open(raw / "divider.png").convert("RGBA"))
    divider.resize((1024, round(divider.height * 1024 / divider.width)), Image.LANCZOS).save(OUT / "divider.png")

    # The shop's recipe area is about 512x98 on screen. Take the band of the armoury painting
    # with the shelves and the weapon rack, darken it so the recipe tree stays readable on top,
    # and fade its top edge into the panel colour.
    band = Image.open(raw / "armory_header.png").convert("RGB").crop((0, 196, 1536, 490))
    band = band.resize((1024, 196), Image.LANCZOS)
    dark = Image.new("RGB", band.size, PANEL_DARK)
    band = Image.blend(band, dark, 0.38)
    fade = Image.new("L", band.size, 255)
    draw = ImageDraw.Draw(fade)
    for y in range(40):
        draw.line([(0, y), (band.width, y)], fill=int(255 * y / 40))
    Image.composite(band, dark, fade).save(OUT / "armory_strip.png")

    for path in sorted(OUT.glob("*.png")):
        print(path.name, Image.open(path).size)


if __name__ == "__main__":
    main()
