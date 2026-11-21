"""Build the Angel Arena map from its base map.

    python tools/map/build_map.py                 # writes content/angel_arena/maps/angel_arena.vmap
    python tools/map/build_map.py --name aa_lab   # writes a scratch copy instead
    python tools/map/build_map.py --check         # fail if layout.json is not what the script produces

The base (`tools/map/base/angel_arena_v1.vmap`) is the hand-made map as it stood before the themed
regions were added. Everything this script adds is derived from it with a fixed random seed, so the
same inputs always give the same map. Close Hammer before running it: Hammer keeps the map in memory
and will write its own copy back over the result.

What it does, in order: swaps two of the tile grid's tileset slots for snow and desert, assigns
each region its tileset, drains the two shallow seas into new land (keeping a jungle lake and a
desert oasis), sinks lava pools, places camp and boss markers, then dresses every region with
trees, tileset props, models and ambient particles.
"""
import argparse
import json
import math
import os
import random
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
from aamap import VMap, to_binary, to_text, CELLS, OBJS, VERTS, HALF  # noqa: E402

BASE = os.path.join(HERE, "base", "angel_arena_v1.vmap")
CATALOG = os.path.join(HERE, "catalog")
LAYOUT = os.path.join(HERE, "layout.json")
SEED = 20261121

RADIANT_PROPS = ["none", "camp_neutral", "banners", "statues", "light sources", "logo_ground", "path_overlays",
                 "overlays", "bases_static", "grass clumps", "grass clumps thin", "tree_details_static",
                 "ambient_creatures"]
RADIANT_TREES = ["none", "pine_summer", "deciduous_summer", "deciduous_spring", "deciduous_autumn", "bamboo"]
GREEN, DIRE, DESERT, SNOW = 0, 1, 2, 3          # tileset slots after the swap
PROP = {name: i for i, name in enumerate(RADIANT_PROPS + ["extra1", "extra2"])}

# Lakes that stay wet: (x0, y0, x1, y1) in height-sample coordinates.
LAKES = {"green": (1024, 6400, 2048, 6912), "desert": (5632, 3328, 6400, 4096)}
# Where each boss should stand if there is room: the open spot nearest to this point is used.
BOSS_ANCHOR = {"ice": (-6200, 6700), "green": (300, 6500), "desert": (3700, 6500), "lava": (2300, -2700)}
# Walkways that must stay clear: (x, y, radius). The first is the long ramp up to the frozen plateau.
WALKWAYS = [(-2600, 7000, 520), (-3300, 7000, 420), (-4000, 7000, 420), (-4700, 7000, 420)]
REGION_TITLES = {"Work in Progress": ["Emerald Wilds", "Frozen Crown"]}


def biome_of(x, y):
    """Which themed region a point belongs to."""
    if y >= 2304:
        if x >= 4864 and y >= 5632:
            return "arena"
        if x < -5376 and y < 2816:
            return "wilds"      # a strip behind the Angel base wall that cannot be walked to
        if x < -3328 or (x < -2816 and y >= 5376):
            return "ice"
        if x < 2560:
            return "green"
        return "desert"
    if x >= 0 and -5376 <= y < -1536:
        return "lava"
    return "wilds"


TILESET = {"ice": SNOW, "desert": DESERT}


class Catalog:
    """Verified model and particle paths, looked up by the end of their name."""

    def __init__(self):
        self.paths = []
        for name in ("ice", "desert", "lava", "green", "common"):
            data = json.load(open(os.path.join(CATALOG, name + ".json"), encoding="utf-8"))
            for entries in data.values():
                for e in entries:
                    self.paths.append(e["path"])

    def __call__(self, tail):
        for ext in (".vmdl", ".vpcf"):
            for p in self.paths:
                if p.endswith("/" + tail + ext) or p == tail + ext:
                    return p
        raise KeyError("not in the asset catalogue: " + tail)


class Builder:
    def __init__(self, m):
        self.m = m
        self.rng = random.Random(SEED)
        self.cat = Catalog()
        self.reserved = []          # (x, y, r): clearings; no trees, camps or landmarks inside
        self.cores = []             # (x, y, r): the middle of each clearing, kept free of everything
        self.props = []             # (x, y, r) of placed models, for spacing
        self.markers = []           # {"name", "x", "y"}
        self.landmarks = []         # {"model", "x", "y"}
        self.counts = {}
        self.dried = set()
        self._noise = {}

    # ---- terrain queries -------------------------------------------------------------------
    def flat_at(self, x, y, r=0):
        """True when every cell touched by the disc is level, dry and inside the playable grid."""
        m = self.m
        if abs(x) > HALF - 320 or abs(y) > HALF - 320:
            return False
        cx0, cy0 = m.cell_of(x - r, y - r)
        cx1, cy1 = m.cell_of(x + r, y + r)
        level = None
        W = m.grid("verticesWater")
        H = m.grid("verticesHeight")
        for cy in range(cy0, cy1 + 1):
            for cx in range(cx0, cx1 + 1):
                if not m.is_flat(cx, cy):
                    return False
                h = H[cy * VERTS + cx]
                if level is None:
                    level = h
                elif h != level:
                    return False
                if W[cy * VERTS + cx] or W[cy * VERTS + cx + 1] or W[(cy + 1) * VERTS + cx] or W[(cy + 1) * VERTS + cx + 1]:
                    return False
        return True

    def trees_near(self, x, y, r):
        m = self.m
        i0, j0 = m.obj_of(x - r, y - r)
        i1, j1 = m.obj_of(x + r, y + r)
        T = m.grid("objectsTreeType")
        n = 0
        for j in range(max(0, j0), min(OBJS, j1 + 1)):
            for i in range(max(0, i0), min(OBJS, i1 + 1)):
                if T[j * OBJS + i]:
                    dx = -HALF + i * 64 - x
                    dy = -HALF + j * 64 - y
                    if dx * dx + dy * dy <= r * r:
                        n += 1
        return n

    def near(self, things, x, y, pad=0):
        for tx, ty, tr in things:
            d = tr + pad
            if abs(tx - x) < d and abs(ty - y) < d and (tx - x) ** 2 + (ty - y) ** 2 < d * d:
                return True
        return False

    def open_spot(self, x, y, r, tree_r=None, loose=False):
        """A place where a model of radius r fits: level ground, no trees, nothing reserved or placed.

        `loose` is for small dressing, which may sit in the outer part of a clearing."""
        return (self.flat_at(x, y, r) and not self.trees_near(x, y, tree_r if tree_r is not None else r + 64)
                and not self.near(self.cores if loose else self.reserved, x, y, r * 0.5 if loose else r)
                and not self.near(self.props, x, y, r * 0.6 if loose else r))

    def reserve(self, x, y, r, core=None):
        self.reserved.append((x, y, r))
        self.cores.append((x, y, core if core is not None else r * 0.55))

    def noise(self, key, x, y, scale):
        """Smooth value noise in 0..1."""
        table = self._noise.setdefault(key, {})

        def corner(ix, iy):
            if (ix, iy) not in table:
                table[(ix, iy)] = random.Random("%d/%s/%d/%d" % (SEED, key, ix, iy)).random()
            return table[(ix, iy)]

        fx, fy = x / scale, y / scale
        ix, iy = math.floor(fx), math.floor(fy)
        tx, ty = fx - ix, fy - iy
        tx = tx * tx * (3 - 2 * tx)
        ty = ty * ty * (3 - 2 * ty)
        a = corner(ix, iy) * (1 - tx) + corner(ix + 1, iy) * tx
        b = corner(ix, iy + 1) * (1 - tx) + corner(ix + 1, iy + 1) * tx
        return a * (1 - ty) + b * ty

    def candidates(self, biome, step=128):
        for y in range(-HALF + 384, HALF - 383, step):
            for x in range(-HALF + 384, HALF - 383, step):
                # stay on the two walkable base levels: not in the pits, not on the high plateaus
                # (the high frozen plateau is the exception: it can be walked to)
                if biome_of(x, y) == biome and 64 <= self.m.ground(x, y) <= (1000 if biome == "ice" else 300):
                    yield x, y

    # ---- placing things --------------------------------------------------------------------
    def model(self, tail, x, y, yaw=None, scale=1.0, dz=0.0, radius=0, block=False, pitch=0.0, tint=None, landmark=False):
        m = self.m
        props = {"model": self.cat(tail)}
        if tint:
            props["rendercolor"] = tint
        yaw = self.rng.uniform(0, 360) if yaw is None else yaw
        m.add_entity("prop_static", (x, y, m.ground(x, y) + dz), props, angles=(pitch, yaw, 0),
                     scales=(scale, scale, scale))
        if radius:
            self.props.append((x, y, radius))
        if block:
            self.block_nav(x, y, radius)
        if landmark:
            self.landmarks.append({"model": tail, "x": round(x), "y": round(y)})
        self.counts["models"] = self.counts.get("models", 0) + 1

    def block_nav(self, x, y, r):
        G = self.m.grid("gridnavFlags")
        for gy in range(int((y - r + HALF) // 64), int((y + r + HALF) // 64) + 1):
            for gx in range(int((x - r + HALF) // 64), int((x + r + HALF) // 64) + 1):
                cx = -HALF + gx * 64 + 32
                cy = -HALF + gy * 64 + 32
                if 0 <= gx < 256 and 0 <= gy < 256 and (cx - x) ** 2 + (cy - y) ** 2 <= r * r:
                    G[gy * 256 + gx] = 1
        self.m.touch("gridnavFlags")

    def particle(self, tail, x, y, dz=0.0):
        self.m.add_entity("info_particle_system", (x, y, self.m.ground(x, y) + dz),
                          {"effect_name": self.cat(tail), "start_active": "1"})
        self.counts["particles"] = self.counts.get("particles", 0) + 1

    def marker(self, name, x, y):
        self.m.add_entity("info_target", (x, y, self.m.ground(x, y)), {"targetname": name})
        self.markers.append({"name": name, "x": round(x), "y": round(y)})

    def ring(self, tail, x, y, radius, count, scale=1.0, face_in=True, r=96, block=False, start=0.0, jitter=0.0):
        for k in range(count):
            a = start + 2 * math.pi * k / count
            px = x + math.cos(a) * radius + self.rng.uniform(-jitter, jitter)
            py = y + math.sin(a) * radius + self.rng.uniform(-jitter, jitter)
            if self.flat_at(px, py, 64):
                self.model(tail, px, py, yaw=math.degrees(a) + (180 if face_in else 0), scale=scale, radius=r, block=block)

    def scatter(self, biome, tails, count, radius, scale=(0.8, 1.25), key=None, where=None, clear_trees=64, dz=0.0):
        """Drop `count` models from `tails` on open ground of a region, spaced by `radius`."""
        spots = [p for p in self.candidates(biome, 96) if where is None or where(*p)]
        self.rng.shuffle(spots)
        placed = 0
        for x, y in spots:
            if placed >= count:
                break
            x += self.rng.uniform(-40, 40)
            y += self.rng.uniform(-40, 40)
            if key and self.noise(key, x, y, 900) < 0.42:
                continue
            if not self.open_spot(x, y, radius, clear_trees, loose=True):
                continue
            self.model(self.rng.choice(tails), x, y, scale=self.rng.uniform(*scale), radius=radius, dz=dz)
            placed += 1
        return placed

    def best_spot(self, biome, radius, avoid=(), prefer=None, tree_r=None):
        """The open spot in a region farthest from the points in `avoid` (or best by `prefer`)."""
        best = None
        for x, y in self.candidates(biome, 128):
            if not self.open_spot(x, y, radius, tree_r):
                continue
            if prefer:
                score = prefer(x, y)
            else:
                score = min([math.hypot(x - ax, y - ay) for ax, ay in avoid] or [0])
            if best is None or score > best[0]:
                best = (score, x, y)
        return (best[1], best[2]) if best else None

    def place_spot(self, biome, radius, avoid=(), prefer=None):
        """Room for a landmark: open ground if there is any, otherwise level ground with its trees removed."""
        p = self.best_spot(biome, radius, avoid=avoid, prefer=prefer, tree_r=radius - 100)
        if not p:
            p = self.best_spot(biome, radius, avoid=avoid, prefer=prefer, tree_r=0)
            if p:
                self.clear_trees(p[0], p[1], radius - 40)
        return p

    def thin_forest(self, biome, key, keep):
        """Open clearings in a region's forest: trees go where smooth noise is above `keep`."""
        m = self.m
        removed = 0
        for j in range(OBJS):
            for i in range(OBJS):
                if not m.tree_at(i, j):
                    continue
                x, y = -HALF + i * 64, -HALF + j * 64
                if biome_of(x, y) == biome and self.noise(key, x, y, 800) > keep:
                    m.paint_tree(i, j, 0)
                    removed += 1
        self.counts[biome + " trees cleared"] = removed

    # ---- steps -----------------------------------------------------------------------------
    def tilesets(self):
        m = self.m
        m.set_tileset(DESERT, "maps/tilesets/radiant_desert_basic.vmap", RADIANT_PROPS + ["ruins", "sand_drift"], RADIANT_TREES)
        m.set_tileset(SNOW, "maps/tilesets/radiant_snow_basic.vmap", RADIANT_PROPS + ["snow_drifts"], RADIANT_TREES)
        ts = m.grid("cellsTileSet")
        ots = m.grid("objectsTileSet")
        crossed = []

        def shape(cx, cy):
            p = m._pattern(cx, cy)
            turns = [p]
            for _ in range(3):
                sw, se, nw, ne = turns[-1]
                turns.append((nw, sw, ne, se))
            return min(turns)

        # cliff shapes the base map already shows in a Radiant tileset
        known = set(shape(cx, cy) for cy in range(CELLS) for cx in range(CELLS) if ts[cy * CELLS + cx] == GREEN)
        # Hand-picked Dire tiles (stairs) and the cells around them stay as they are: the stair tile
        # reaches into its neighbour, and a Radiant tileset left a hole there.
        var = m.grid("cellsVariationId")
        stairs = set()
        for cy in range(CELLS):
            for cx in range(CELLS):
                if var[cy * CELLS + cx] >= 3 and ts[cy * CELLS + cx] == DIRE:
                    stairs.update((cx + dx, cy + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1))
        kept = 0
        for cy in range(CELLS):
            for cx in range(CELLS):
                b = biome_of(-HALF + cx * 256 + 128, -HALF + cy * 256 + 128)
                if b in TILESET:
                    if ts[cy * CELLS + cx] == DIRE:
                        if shape(cx, cy) not in known or (cx, cy) in stairs:
                            kept += 1       # an unusual corner: it came out as a hole in sand, so it stays Dire rock
                            continue
                        crossed.append((cx, cy))
                    ts[cy * CELLS + cx] = TILESET[b]
        self.counts["odd cliff cells left in the Dire tileset"] = kept
        # The stored tile choice of a Dire cell names nodes that mean something else in a Radiant-family
        # tileset (a stair tile came out as a hole). Flat cells get the plain land tile, the rest are
        # left for the compiler to choose again.
        m.clear_cell_choice(crossed)
        m.make_land(crossed, dire=False)
        self.counts["cells moved from Dire to a Radiant tileset"] = len(crossed)
        for j in range(OBJS):
            for i in range(OBJS):
                k = j * OBJS + i
                b = biome_of(-HALF + i * 64, -HALF + j * 64)
                if b in TILESET:
                    if (min(CELLS - 1, i // 4), min(CELLS - 1, j // 4)) in stairs and ots[k] == DIRE:
                        continue
                    ots[k] = TILESET[b]
                elif ots[k] in (DESERT, SNOW):
                    ots[k] = GREEN      # the few objects that used the two replaced tilesets
        m.touch("cellsTileSet")
        m.touch("objectsTileSet")

    def drain(self):
        """Turn the two shallow seas in the north into land, except for the lakes."""
        m = self.m
        W = m.grid("verticesWater")
        wet_before = set(k for k, v in enumerate(W) if v)
        dried = m.set_water(-HALF, 2304, HALF, HALF, False)
        for x0, y0, x1, y1 in LAKES.values():
            m.set_water(x0, y0, x1, y1, True)
        m.make_land([c for c in dried if m.is_flat(*c)])
        self.dried = set(c for c in dried if self.flat_at(-HALF + c[0] * 256 + 128, -HALF + c[1] * 256 + 128))
        # bare ground instead of the dark seabed material the sea was painted with
        op = m.colors("blendOpacity")
        col = m.colors("blendColor")
        tr = m.colors("blendTransitionAndPath")
        touched = set(dried)
        for j in range(513):
            cy = min(CELLS - 1, j // 8)
            for i in range(513):
                if (min(CELLS - 1, i // 8), cy) in touched:
                    k = j * 513 + i
                    op[k] = [0, 0, 0, 128]
                    col[k][3] = 7
                    tr[k] = [0, 0, 0, 0]
        m.touch_colors("blendOpacity")
        m.touch_colors("blendColor")
        m.touch_colors("blendTransitionAndPath")
        self.counts["sea cells drained"] = len(self.dried)
        self.counts["water samples before"] = len(wet_before)

    def lava_pools(self):
        """Sink pools one level into the lava plain and fill them with lava."""
        m = self.m
        self.pools = []
        hold = BOSS_ANCHOR["lava"] + (760,)     # leave the boss its clearing
        self.reserved.append(hold)
        for size in ((512, 256), (256, 256), (256, 512), (256, 256), (512, 256), (256, 256), (256, 256)):
            half = max(size) / 2.0 + 300
            p = self.best_spot("lava", half, avoid=[(x, y) for x, y, _ in self.pools] + [(0, -1536)], tree_r=0)
            if not p:
                continue
            x0 = round((p[0] - size[0] / 2.0) / 256.0) * 256
            y0 = round((p[1] - size[1] / 2.0) / 256.0) * 256
            x1, y1 = x0 + size[0], y0 + size[1]
            cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
            if not self.flat_at(cx, cy, half - 60) or self.near(self.reserved, cx, cy, half - 60):
                continue
            self.clear_trees(cx, cy, half)
            unknown = m.set_height(x0, y0, x1, y1, delta=-1)
            if unknown:
                raise RuntimeError("lava pool made a shape the tileset has no tile for: %r" % (unknown,))
            floor = m.ground(cx, cy)
            m.add_plane("blends/dire_lava", x0 - 236, y0 - 236, x1 + 236, y1 + 236, floor + 44)
            self.reserve(cx, cy, half)
            self.pools.append((cx, cy, half))
            self.particle("pit_lava_glow", cx, cy, 60)
            self.particle("dire_lava_gloops_10sec", cx - 60, cy + 40, 50)
            self.particle("dire_lava_gloops_7sec", cx + 80, cy - 60, 50)
            self.landmarks.append({"model": "lava pool", "x": round(cx), "y": round(cy)})
        self.reserved.remove(hold)
        self.counts["lava pools"] = len(self.pools)

    def clear_trees(self, x, y, r):
        m = self.m
        i0, j0 = m.obj_of(x - r, y - r)
        i1, j1 = m.obj_of(x + r, y + r)
        for j in range(max(0, j0), min(OBJS, j1 + 1)):
            for i in range(max(0, i0), min(OBJS, i1 + 1)):
                if m.tree_at(i, j) and (-HALF + i * 64 - x) ** 2 + (-HALF + j * 64 - y) ** 2 <= r * r:
                    m.paint_tree(i, j, 0)

    def existing_entities(self):
        """Keep clear of everything the base map already has."""
        # ramps and stairs: a blocked ramp cuts a whole area off (the first build put a tree on the
        # foot of the ramp to the frozen plateau)
        for x, y, r in WALKWAYS:
            self.reserve(x, y, r, core=r)
        var = self.m.grid("cellsVariationId")
        for cy in range(CELLS):
            for cx in range(CELLS):
                if var[cy * CELLS + cx] >= 3:       # hand-picked tiles: stairs
                    self.reserve(-HALF + cx * 256 + 128, -HALF + cy * 256 + 128, 460, core=460)
        text = self.m.text
        for m in re.finditer(r'"classname" "string" "([^"]+)"(.*?)"origin" "vector3" "([^"]+)"', text, re.S):
            cls, body, origin = m.group(1), m.group(2), m.group(3)
            if len(body) > 6000 or cls in ("worldspawn",):
                continue
            x, y, _ = [float(v) for v in origin.split()]
            if cls == "prop_static":
                if "goldcoins" in body:
                    continue
                self.props.append((x, y, 160))
            else:
                self.reserve(x, y, 260 if cls not in ("npc_dota_base", "npc_dota_tower", "ent_dota_shop") else 420)

    def camps(self):
        """Rename the old camp triggers by region and difficulty, add camps on the new land, place bosses."""
        m = self.m
        centre = {"ice": (-3328, 2304), "green": (-512, 2304), "desert": (2560, 2304), "lava": (1280, -1536)}
        found = []
        for mm in re.finditer(r'"targetname" "string" "creep_camp"(.*?)"origin" "vector3" "([^"]+)"', m.text, re.S):
            x, y, _ = [float(v) for v in mm.group(2).split()]
            found.append((mm.start(), x, y))
        want = {"ice": 6, "green": 7, "desert": 7, "lava": 6}
        spots = {b: [(x, y, None) for _, x, y in found if biome_of(x, y) == b] for b in list(want) + ["wilds"]}
        # one boss per themed region, in the widest clearing away from the camps that already exist;
        # placed before the new camps because it needs the most room
        self.boss = {}
        for _, x, y in found:
            self.reserve(x, y, 430)
        for b in want:
            taken = [(x, y) for x, y, _ in spots[b]]
            p = None
            ax, ay = BOSS_ANCHOR[b]
            # the roomiest clearing that is still close to the anchor
            p = None
            for radius in (640, 540, 460, 400):
                q = self.best_spot(b, radius, tree_r=0, prefer=lambda x, y: -math.hypot(x - ax, y - ay))
                if q and (p is None or math.hypot(q[0] - ax, q[1] - ay) < math.hypot(p[0] - ax, p[1] - ay) - 500):
                    p = q
            if not p:
                raise RuntimeError("no room for the %s boss" % b)
            self.marker("arena_boss_" + b, p[0], p[1])
            self.boss[b] = p
            self.reserve(p[0], p[1], 520)
            self.clear_trees(p[0], p[1], 560)
        for b, total in want.items():
            while len(spots[b]) < total:
                taken = [(x, y) for x, y, _ in spots[b]]
                p = self.best_spot(b, 360, avoid=taken + [centre[b]], tree_r=300)
                if not p or min([math.hypot(p[0] - ax, p[1] - ay) for ax, ay in taken] or [9e9]) < 800:
                    # nowhere open enough: take level ground under trees and clear it
                    p = self.best_spot(b, 360, avoid=taken + [centre[b]], tree_r=0)
                    if not p or min([math.hypot(p[0] - ax, p[1] - ay) for ax, ay in taken] or [9e9]) < 800:
                        break
                    self.clear_trees(p[0], p[1], 380)
                spots[b].append((p[0], p[1], "new"))
                self.reserve(p[0], p[1], 430)
        names = {}
        for b, pts in spots.items():
            if b == "wilds":
                home = [(-6592, 384), (6592, 320)]
                ranked = sorted(pts, key=lambda p: min(math.hypot(p[0] - hx, p[1] - hy) for hx, hy in home))
                shares = (0.3, 0.3, 0.25, 0.15)
            else:
                ranked = sorted(pts, key=lambda p: math.hypot(p[0] - centre[b][0], p[1] - centre[b][1]))
                shares = (0.3, 0.3, 0.25, 0.15)
            n = len(ranked)
            edges = [round(n * sum(shares[:t + 1])) for t in range(4)]
            for rank, (x, y, kind) in enumerate(ranked):
                tier = next(t for t in range(4) if rank < edges[t] or t == 3) + 1
                name = "arena_camp_%s_%d" % (b, tier)
                if kind == "new":
                    self.marker(name, x, y)
                else:
                    names[(x, y)] = name
                    self.markers.append({"name": name, "x": round(x), "y": round(y)})
                    self.reserve(x, y, 430)
        # rename the old triggers in place, last first so earlier offsets stay valid
        text = m.text
        for start, x, y in sorted(found, reverse=True):
            name = names[(x, y)]
            old = '"targetname" "string" "creep_camp"'
            assert text[start:start + len(old)] == old
            text = text[:start] + '"targetname" "string" "%s"' % name + text[start + len(old):]
        m.text = text

    def forests(self):
        """Grow trees on the drained land so it is not one open field."""
        m = self.m
        planted = 0
        for cx, cy in sorted(self.dried):
            for dj in range(4):
                for di in range(4):
                    i, j = cx * 4 + di, cy * 4 + dj
                    x, y = -HALF + i * 64, -HALF + j * 64
                    b = biome_of(x, y)
                    if b not in ("green", "desert") or m.tree_at(i, j):
                        continue
                    if self.near(self.reserved, x, y, 40) or self.near(self.props, x, y, 60):
                        continue
                    if not self.flat_at(x, y, 40):
                        continue
                    if b == "green":
                        n = self.noise("jungle", x, y, 700)
                        lake = LAKES["green"]
                        shore = max(lake[0] - x, x - lake[2], lake[1] - y, y - lake[3], 0)
                        dense = n > 0.34 or shore < 260
                        if dense and (i + j) % 2 == 0:
                            kind = 5 if shore < 330 and self.rng.random() < 0.6 else self.rng.choice((2, 2, 3, 3, 3, 1))
                            m.paint_tree(i, j, kind, tileset=GREEN, size=self.rng.choice((1, 2, 2)))
                            planted += 1
                    else:
                        n = self.noise("palms", x, y, 620)
                        lake = LAKES["desert"]
                        shore = max(lake[0] - x, x - lake[2], lake[1] - y, y - lake[3], 0)
                        if (n > 0.47 and (i + j) % 2 == 0 and self.rng.random() < 0.85) or \
                                (shore < 300 and (i + j) % 2 == 0 and self.rng.random() < 0.55):
                            m.paint_tree(i, j, self.rng.choice((1, 2, 3, 4, 5)), tileset=DESERT, size=self.rng.choice((1, 2, 2)))
                            planted += 1
        self.counts["trees planted"] = planted

    def tileset_dressing(self):
        """Let each tileset scatter its own ruins, drifts, statues and plants."""
        m = self.m
        plan = {
            "desert": [(13, 0.035), (14, 0.07), (3, 0.012)],      # ruins, sand drifts, statues
            "ice": [(13, 0.10), (3, 0.008)],                       # snow drifts, statues
            "green": [(9, 0.06), (6, 0.006)],                      # grass clumps, statues (base map's own order)
        }
        plants = {"desert": 0.08, "ice": 0.0, "green": 0.14}
        n = 0
        for j in range(2, OBJS - 2):
            for i in range(2, OBJS - 2):
                x, y = -HALF + i * 64, -HALF + j * 64
                b = biome_of(x, y)
                if b not in plan or m.tree_at(i, j):
                    continue
                roll = self.rng.random()
                acc = 0.0
                choice = None
                for prop_type, chance in plan[b]:
                    acc += chance
                    if roll < acc:
                        choice = (prop_type, 0)
                        break
                if choice is None and roll < acc + plants[b]:
                    choice = (0, self.rng.choice((1, 2, 3)))
                if choice is None or choice == (0, 0):
                    continue
                if not self.flat_at(x, y, 96) or self.near(self.cores, x, y, 60) or self.near(self.props, x, y, 100):
                    continue
                if choice[0] and self.trees_near(x, y, 160):
                    continue
                m.paint_prop(i, j, prop_type=choice[0], plant_type=choice[1], tileset=TILESET.get(b, GREEN))
                if choice[0]:
                    self.props.append((x, y, 150))
                n += 1
        self.counts["tileset props and plants"] = n

    def fire(self, tail, x, y, yaw=None, scale=1.0, flame="fire_torch", flame_z=150, radius=70):
        self.model(tail, x, y, yaw=yaw, scale=scale, radius=radius)
        self.particle(flame, x, y, flame_z * scale)

    # ---- the five regions ------------------------------------------------------------------
    def ice(self):
        bx, by = self.boss["ice"]
        self.ring("ice_spike_lrg", bx, by, 600, 7, scale=1.5, r=120, block=True, start=0.3)
        self.ring("crystal001_refract", bx, by, 690, 7, scale=1.3, r=90, start=0.75)
        p = self.place_spot("ice", 300, avoid=[(bx, by)])
        if p:
            self.model("frostivus_ancient_snow", p[0], p[1], scale=0.6, radius=230, block=True, landmark=True)
            self.reserve(p[0], p[1], 300)
        p = self.place_spot("ice", 300, avoid=[(bx, by)] + [(l["x"], l["y"]) for l in self.landmarks])
        if p:
            self.model("whale_skeleton", p[0], p[1], scale=0.8, radius=230, block=True, landmark=True)
            self.reserve(p[0], p[1], 300)
        # a Tuskarr camp beside the easiest ice camp
        easy = [mk for mk in self.markers if mk["name"] == "arena_camp_ice_1"]
        p = self.place_spot("ice", 330, prefer=lambda x, y: -min([math.hypot(x - e["x"], y - e["y"]) for e in easy] or [0]))
        if p:
            x, y = p
            self.model("tuskhouse01", x - 150, y + 110, yaw=300, scale=0.9, radius=170, block=True, landmark=True)
            self.model("frostivus_igloo", x + 170, y + 60, yaw=210, scale=0.9, radius=150, block=True)
            self.model("leanto_fur", x + 40, y - 200, yaw=90, radius=90)
            self.fire("camp_fire001", x, y - 20, flame="fire_camp_01", flame_z=14, radius=60)
            self.model("elon_sled", x - 190, y - 150, radius=80)
            self.model("frostivus_snowman", x + 200, y - 150, yaw=250, radius=50)
            self.reserve(x, y, 360)
        n = self.scatter("ice", ["ice_spike_med", "ice_spike_sml", "ice_spike_lrg", "crystal002_refract",
                                 "crystal003_refract", "crystal004_refract"], 60, 150, scale=(0.9, 1.6), key="ice_rocks")
        n += self.scatter("ice", ["snowdrift_001", "snowdrift_002", "snowdrift_003", "snowdrift_004", "drift_snow01a",
                                  "log001_snow"], 90, 110, scale=(0.9, 1.5))
        self.counts["ice scatter"] = n
        for x, y in self.grid_points("ice", 1400):
            self.particle("snow_drift", x, y, 200)

    def desert(self):
        bx, by = self.boss["desert"]
        self.model("ancient_giant_skeleton", bx + 520, by + 330, yaw=215, scale=0.9, radius=300, block=True, landmark=True)
        self.ring("obelisk001", bx, by, 640, 6, scale=1.2, r=100, block=True, start=1.1)
        self.ring("column001c", bx, by, 560, 6, scale=1.1, r=80, start=1.62)
        for a in (0.4, 2.5, 4.6):
            self.fire("cf_palace_brazier", bx + math.cos(a) * 470, by + math.sin(a) * 470, flame="lamp_flame_braser", flame_z=80)
        # hoodoo clusters
        made = 0
        for _ in range(3):
            p = self.best_spot("desert", 420, avoid=[(bx, by)] + [(l["x"], l["y"]) for l in self.landmarks], tree_r=260)
            if not p:
                break
            x, y = p
            for k, tail in enumerate(("stoneforest01", "stoneforest02", "stoneforest03", "stoneforest04")):
                a = k * 1.7 + made
                self.model(tail, x + math.cos(a) * 190, y + math.sin(a) * 190, scale=self.rng.uniform(0.55, 0.85),
                           radius=150, block=True, landmark=(k == 0))
            self.reserve(x, y, 440)
            made += 1
        # a buried temple with treasure
        p = self.best_spot("desert", 400, avoid=[(bx, by)] + [(l["x"], l["y"]) for l in self.landmarks], tree_r=260)
        if p:
            x, y = p
            self.model("midas_throne", x, y + 150, yaw=270, radius=170, block=True, landmark=True)
            self.model("temple_statue001", x - 260, y + 60, yaw=315, radius=110, block=True)
            self.model("temple_statue002", x + 260, y + 60, yaw=225, radius=110, block=True)
            for dx in (-170, 170):
                self.model("column_temple_dire_00", x + dx, y - 150, yaw=0, radius=80, block=True)
            for k in range(7):
                self.model("goldcoins_01", x + self.rng.uniform(-150, 150), y + self.rng.uniform(-120, 60), radius=0)
            self.model("treasure_chest_gold", x - 60, y - 30, yaw=280, radius=40)
            self.model("chest_treasure_02_open", x + 80, y - 10, yaw=250, radius=40)
            self.reserve(x, y, 430)
        # the oasis
        n = self.scatter("desert", ["bones004_set_tintable", "bones001_set_tintable", "bones002_set_tintable",
                                    "succulent_fat", "succulent_fat", "desert_thorns01", "desert_thorns01"], 70, 130, scale=(0.9, 1.5))
        n += self.scatter("desert", ["rock_ground001", "land_rock001a", "cliff_rock001"], 70, 170, scale=(0.6, 1.2), key="dunes")
        self.counts["desert scatter"] = n
        for x, y in self.grid_points("desert", 1500):
            self.particle("desert_sand_drift", x, y, 60)

    def lava(self):
        bx, by = self.boss["lava"]
        self.ring("bad_column001", bx, by, 610, 8, scale=1.1, r=90, block=True, start=0.2)
        for a in (0.6, 2.2, 3.75, 5.3):
            self.fire("bad_column_torch", bx + math.cos(a) * 500, by + math.sin(a) * 500, flame="fire_torch", flame_z=250, radius=80)
        p = self.place_spot("lava", 430, avoid=[(bx, by)])
        if p:
            self.model("dragon_statue001", p[0], p[1], scale=1.3, radius=250, block=True, landmark=True)
            self.reserve(p[0], p[1], 430)
        n = self.scatter("lava", ["bad_crystals001", "badside_rocks001", "badside_rocks002", "badside_rocks003",
                                  "badside_rocks004", "stalagmite_cluster_01"], 55, 160, scale=(0.8, 1.5), key="lava_rocks")
        n += self.scatter("lava", ["ground_crack_molten", "ground_crack_molten", "lava_flow_clump"], 60, 150, scale=(1.6, 3.0), dz=2)
        torches = 0
        for x, y in self.candidates("lava", 512):
            if torches < 14 and self.open_spot(x, y, 110, 64, loose=True):
                self.fire("bad_column_torch", x, y, flame="fire_torch", flame_z=250, radius=110)
                torches += 1
        n += self.scatter("lava", ["badside_bones001", "badside_bones002", "badside_bones003", "dead_head001a",
                                   "battle_debris1", "badside_hands001", "spike_fence001a", "bad_standard001",
                                   "bad_column001_broken001", "bad_column001_broken002"], 80, 120, scale=(0.9, 1.3))
        self.counts["lava scatter"] = n
        for x, y in self.grid_points("lava", 1100):
            self.particle("bad_ancient_embers", x, y, 40)
        for x, y in self.grid_points("lava", 1700):
            self.particle("dire_lava_gloops_embers_10sec", x + 200, y + 150, 30)

    def green(self):
        bx, by = self.boss["green"]
        self.model("jungle_temple_01", bx, by + 620, yaw=270, scale=0.8, radius=330, block=True, landmark=True)
        self.model("temple_statue_01", bx - 430, by + 330, yaw=300, radius=110, block=True)
        self.model("temple_statue_01", bx + 430, by + 330, yaw=240, radius=110, block=True)
        self.ring("temple_column_01", bx, by, 600, 8, scale=1.0, r=80, block=True, start=math.pi + 0.4)
        for a in (3.6, 5.8):
            self.fire("temple_bowl_coals_01", bx + math.cos(a) * 470, by + math.sin(a) * 470, flame="lamp_flame_braser", flame_z=60)
        # giants of the new jungle
        made = 0
        for _ in range(7):
            p = self.best_spot("green", 300, avoid=[(bx, by)] + [(l["x"], l["y"]) for l in self.landmarks], tree_r=120)
            if not p:
                break
            tail = ("kapok_002", "kapok_004", "kapok_001", "jungle_pitcher_tree", "mushroom_cavern_01", "kapok_002", "mushroom_cavern_01")[made]
            self.model(tail, p[0], p[1], scale=self.rng.uniform(0.8, 1.1), radius=190, block=True, landmark=True)
            self.reserve(p[0], p[1], 300)
            made += 1
        n = self.scatter("green", ["bush_jungle_00", "bush_jungle_01", "bush_palm_01", "fern001", "flower_jungle_01",
                                   "flower_jungle_02", "flower_jungle_03", "mushroom_wild001", "glowing_fungus"],
                         170, 100, scale=(0.9, 1.5))
        n += self.scatter("green", ["roots_bottom_01", "small_rock_cluster_01", "river_rocks004", "river_rocks005"], 35, 150, key="roots")
        self.counts["green scatter"] = n
        for x, y in self.grid_points("green", 1000):
            self.particle(self.rng.choice(("fireflies", "butterflies_512", "fireflies_large_w_light", "dragonflies_group")), x, y, 60)
        for x, y in self.grid_points("green", 1900):
            self.particle("fog_lowpatch", x + 300, y + 200, 10)

    def wilds(self):
        """The untouched middle of the map: light dressing only."""
        graves = lambda x, y: y < -5500 and -4200 < x < 3600
        n = self.scatter("wilds", ["gravestone001", "gravestone002", "gravestone003", "gravestone004", "gravestone005",
                                   "coffin001", "graveyard_fence001", "graveyard_fence003", "crypt_tomb_01", "gravehands"], 70, 120, where=graves, key="graves")
        forest = lambda x, y: x < -1500 and -1700 < y < 2200
        n += self.scatter("wilds", ["flower_jungle_01", "flower_jungle_02", "fern001", "mushroom_wild001",
                                    "small_rock_cluster_01"], 70, 100, where=forest)
        waste = lambda x, y: not graves(x, y) and not forest(x, y) and x > -1500
        n += self.scatter("wilds", ["badside_bones001", "badside_bones002", "dead_head001a", "battle_debris1",
                                    "badside_rocks001", "bad_crystals001"], 60, 130, where=waste, key="waste")
        self.counts["wilds scatter"] = n
        for x, y in self.grid_points("wilds", 1800):
            if graves(x, y):
                self.particle("fog_lowpatch6_dark", x, y, 10)
            elif forest(x, y):
                self.particle("radiant_wisps_stationary", x, y, 80)
        # torches at both mouths of the two bridges into the central pit
        for x, y in ((-1900, 520), (-1900, 200), (1640, 420), (1640, 100)):
            if self.flat_at(x, y, 64):
                self.fire("roshan_torch", x, y, flame="fire_torch", flame_z=210)

    def grid_points(self, biome, step):
        for y in range(-HALF + step // 2, HALF, step):
            for x in range(-HALF + step // 2, HALF, step):
                if biome_of(x, y) == biome and abs(x) < HALF - 500 and abs(y) < HALF - 500:
                    yield x, y

    def titles(self):
        text = self.m.text
        for old, new_list in REGION_TITLES.items():
            for new in new_list:
                key = '"message" "string" "%s"' % old
                if key in text:
                    text = text.replace(key, '"message" "string" "%s"' % new, 1)
        self.m.text = text

    def run(self):
        self.m.learn_orientations()
        self.tilesets()
        self.drain()
        self.existing_entities()
        self.thin_forest("lava", "lava_clearings", 0.42)
        self.thin_forest("ice", "ice_clearings", 0.62)
        self.lava_pools()
        self.camps()
        self.ice()
        self.desert()
        self.lava()
        self.green()
        self.forests()
        self.tileset_dressing()
        self.wilds()
        self.titles()
        return {"markers": sorted(self.markers, key=lambda p: (p["name"], p["x"], p["y"])),
                "landmarks": self.landmarks, "lakes": LAKES, "counts": self.counts}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--name", default="angel_arena", help="map name to write under content/angel_arena/maps")
    ap.add_argument("--check", action="store_true", help="only verify that layout.json is up to date")
    args = ap.parse_args()
    work = tempfile.mkdtemp(prefix="aa_map_")
    src = os.path.join(work, "base.kv2.vmap")
    to_text(BASE, src)
    builder = Builder(VMap.load(src))
    layout = builder.run()
    text = json.dumps(layout, indent=1, sort_keys=True) + "\n"
    if args.check:
        old = open(LAYOUT, encoding="utf-8").read().replace("\r\n", "\n") if os.path.exists(LAYOUT) else ""
        if old != text:
            print("tools/map/layout.json is out of date: run python tools/map/build_map.py")
            return 1
        print("layout.json is up to date")
        return 0
    out_text = os.path.join(work, "out.kv2.vmap")
    builder.m.save(out_text)
    out = os.path.join(ROOT, "content", "angel_arena", "maps", args.name + ".vmap")
    to_binary(out_text, out)
    layout_path = LAYOUT if args.name == "angel_arena" else os.path.join(tempfile.gettempdir(), "aa_layout_%s.json" % args.name)
    open(layout_path, "w", encoding="utf-8", newline="\n").write(text)
    for k, v in sorted(layout["counts"].items()):
        print("%-28s %s" % (k, v))
    print("markers:", len(layout["markers"]), "landmarks:", len(layout["landmarks"]))
    print("wrote", out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
