"""Checks on the generated map: the camp and boss markers the game scripts look for are all there.

    python tests/arena_map.py           # fast: reads tools/map/layout.json and the map file
    python tests/arena_map.py --full    # also re-runs the generator (needs the Dota workshop tools)
"""
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYOUT = os.path.join(ROOT, "tools", "map", "layout.json")
MAP = os.path.join(ROOT, "content", "angel_arena", "maps", "angel_arena.vmap")
BASE = os.path.join(ROOT, "tools", "map", "base", "angel_arena_v1.vmap")
BIOMES = ("wilds", "green", "desert", "ice", "lava")
THEMED = BIOMES[1:]

failures = []


def check(ok, message):
    if not ok:
        failures.append(message)


layout = json.load(open(LAYOUT, encoding="utf-8"))
markers = layout["markers"]
names = {}
for m in markers:
    names[m["name"]] = names.get(m["name"], 0) + 1
    check(re.match(r"^arena_(camp_(%s)_[1-4]|boss_(%s))$" % ("|".join(BIOMES), "|".join(THEMED)), m["name"]),
          "marker name the scripts would not find: %s" % m["name"])
    check(abs(m["x"]) < 8192 and abs(m["y"]) < 8192, "marker outside the map: %r" % (m,))

for biome in THEMED:
    check(names.get("arena_boss_" + biome) == 1, "expected exactly one boss marker for %s" % biome)
for biome in BIOMES:
    for tier in range(1, 5):
        check(names.get("arena_camp_%s_%d" % (biome, tier), 0) >= 1, "no tier %d camp in %s" % (tier, biome))
    camps = sum(n for name, n in names.items() if name.startswith("arena_camp_%s_" % biome))
    check(camps >= 4, "%s has only %d camps" % (biome, camps))

# camps stand apart from each other and from the bosses
for i, a in enumerate(markers):
    for b in markers[i + 1:]:
        d = ((a["x"] - b["x"]) ** 2 + (a["y"] - b["y"]) ** 2) ** 0.5
        check(d >= 450, "markers too close together (%d units): %s and %s" % (d, a["name"], b["name"]))

# the map file itself carries every marker name and none of the old ones
data = open(MAP, "rb").read()
for name in names:
    check(name.encode() + b"\0" in data, "the map file does not contain %s" % name)
check(b"\0creep_camp\0" not in data, "the map still has old creep_camp markers")
check(b"maps/tilesets/radiant_snow_basic.vmap" in data, "the snow tileset is missing from the map")
check(b"maps/tilesets/radiant_desert_basic.vmap" in data, "the desert tileset is missing from the map")
check(os.path.exists(BASE), "the base map the generator starts from is missing")
check(b"Work in Progress" not in data, "a 'Work in Progress' sign is still on the map")

if "--full" in sys.argv:
    result = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "map", "build_map.py"), "--check"],
                            capture_output=True, text=True)
    check(result.returncode == 0, "build_map.py --check failed: " + (result.stdout + result.stderr).strip()[-300:])

if failures:
    for f in failures:
        print("FAILED:", f)
    sys.exit(1)
print("Map markers: %d markers in %d names checked" % (len(markers), len(names)))
