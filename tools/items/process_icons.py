#!/usr/bin/env python3
"""Turn raw item icon renders into the icons the game loads.

    python tools/items/process_icons.py <raw dir>

<raw dir> is the --out folder of
    python tools/ui_art/generate_ui_art.py --out <raw dir> --jobs tools/items/icon_prompts.json

Dota item icons are 88x64 and are drawn at that size without scaling, so a larger file shows
only its top-left corner. The renders are 3:2: each is cropped at the sides, scaled down and written to
game/angel_arena/resource/flash3/images/items/arena/<key>.png (AbilityTextureName "arena/<key>").
"""
import sys
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
from arena_items import ITEMS  # noqa: E402

REPO = Path(__file__).resolve().parents[2]
OUT = REPO / "game" / "angel_arena" / "resource" / "flash3" / "images" / "items" / "arena"
SIZE = (88, 64)


def main():
    raw = Path(sys.argv[1])
    OUT.mkdir(parents=True, exist_ok=True)
    missing = []
    for entry in ITEMS:
        source = raw / (entry["key"] + ".png")
        if not source.exists():
            missing.append(entry["key"])
            continue
        image = Image.open(source).convert("RGB")
        width = round(image.height * SIZE[0] / SIZE[1])
        left = (image.width - width) // 2
        image.crop((left, 0, left + width, image.height)).resize(SIZE, Image.LANCZOS).save(OUT / (entry["key"] + ".png"))
    print("%d icons written to %s" % (len(ITEMS) - len(missing), OUT.relative_to(REPO)))
    if missing:
        print("missing renders: " + ", ".join(missing))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
