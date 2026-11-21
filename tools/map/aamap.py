"""Edit a Dota 2 Hammer map (.vmap) as text.

Hammer saves maps as binary DMX. `dmxconvert.exe` (shipped with the Dota workshop tools) converts
that losslessly to the `keyvalues2` text encoding and back, so this module works on the text form:
it can read and rewrite the tile grid arrays (heights, tilesets, trees) and add point entities.

    m = VMap.load("angel_arena.kv2.vmap")
    m.add_entity("prop_static", (0, 0, 128), {"model": "models/props_tree/tree_pine_01.vmdl"})
    m.save("out.kv2.vmap")
"""
import random
import re
import subprocess
import uuid

DOTA = "D:/Program Files (x86)/Steam/steamapps/common/dota 2 beta"
DMXCONVERT = DOTA + "/game/bin/win64/dmxconvert.exe"

GRID_ARRAYS = [
    "cellConfiguration", "cellConfigurationByName", "cellsTileSet", "cellsOrientation", "cellsMaterialSet",
    "verticesHeight", "objectConfiguration", "objectConfigurationByName", "objectsTileSet", "objectsPropType",
    "objectsPlantType", "objectsTreeType",
]
CELLS = 64          # tiles per side, 256 units each
VERTS = CELLS + 1   # height samples per side
OBJS = CELLS * 4 + 1  # tree/prop slots per side, 64 units apart
HALF = 8192


def to_text(binary_path, text_path):
    subprocess.run([DMXCONVERT, "-i", binary_path, "-o", text_path, "-oe", "keyvalues2"], check=True,
                   stdout=subprocess.DEVNULL)


def to_binary(text_path, binary_path):
    subprocess.run([DMXCONVERT, "-i", text_path, "-o", binary_path, "-oe", "binary"], check=True,
                   stdout=subprocess.DEVNULL)


def fmt(v):
    if isinstance(v, (tuple, list)):
        return " ".join(fmt(x) for x in v)
    if isinstance(v, float):
        s = ("%.4f" % v).rstrip("0").rstrip(".")
        return s if s not in ("", "-0") else "0"
    return str(v)


ENTITY = '''			"CMapEntity"
			{
				"id" "elementid" "%(id)s"
				"nodeID" "int" "%(node)d"
				"referenceID" "uint64" "0x%(ref)016x"
				"children" "element_array"
				[
				]
				"variableTargetKeys" "string_array"
				[
				]
				"variableNames" "string_array"
				[
				]
				"relayPlugData" "DmePlugList"
				{
					"id" "elementid" "%(plug)s"
					"names" "string_array"
					[
					]
					"dataTypes" "int_array"
					[
					]
					"plugTypes" "int_array"
					[
					]
					"descriptions" "string_array"
					[
					]
				}

				"connectionsData" "element_array"
				[
				]
				"entity_properties" "EditGameClassProps"
				{
					"id" "elementid" "%(props_id)s"
					"classname" "string" "%(classname)s"
%(props)s				}

				"hitNormal" "vector3" "0 0 1"
				"isProceduralEntity" "bool" "0"
				"origin" "vector3" "%(origin)s"
				"angles" "qangle" "%(angles)s"
				"scales" "vector3" "%(scales)s"
				"transformLocked" "bool" "0"
				"force_hidden" "bool" "0"
				"editorOnly" "bool" "0"
			},
'''

DEFAULTS = {
    "prop_static": [
        ("model", ""), ("solid", "6"), ("disableshadows", "0"), ("screenspacefade", "0"), ("skin", "0"),
        ("fademindist", "-1"), ("fademaxdist", "0"), ("fadescale", "1"), ("detailgeometry", "0"),
        ("baketoworld", "0"), ("renderamt", "255"), ("rendercolor", "255 255 255"), ("cubemap", ""),
        ("materialoverride", ""), ("disableinlowquality", "0"), ("lightingorigin", ""), ("lightgroup", ""),
        ("precomputelightprobes", "1"), ("bakelightoutput", "-1"), ("grass_exclusion_radius", "0"),
        ("rendertocubemaps", "1"), ("visoccluder", "0"), ("lightmapscalebias", "0"), ("lodlevel", "-1"),
        ("disablemerging", "0"), ("bakelightdoublesided", "0"), ("bakelighting", "-1"),
        ("renderwithdynamic", "0"), ("emissive", "1"), ("emissive_lighting_boost", "1.0"),
    ],
    "info_target": [("targetname", ""), ("vscripts", ""), ("parentname", ""), ("spawnflags", "0")],
    "info_particle_system": [
        ("targetname", ""), ("effect_name", ""), ("start_active", "1"), ("snapshot_file", ""),
        ("parentname", ""), ("cpoint1", ""), ("cpoint2", ""), ("cpoint3", ""),
    ],
    "npc_dota_base": [
        ("vscripts", ""), ("targetname", ""), ("rendercolor", "255 255 255"), ("MapUnitName", ""),
        ("m_iTeamNum", "4"), ("initial_waypoint", ""), ("UseNeutralCreepBehavior", "1"), ("EnableAutoStyles", "0"),
    ],
}


class VMap:
    def __init__(self, text):
        self.text = text
        self._pending = []
        self._rng = random.Random(20261121)
        self._next_node = max(int(n) for n in re.findall(r'"nodeID" "int" "(\d+)"', text)) + 1
        self._grid = {}
        self._dirty = set()

    @classmethod
    def load(cls, path):
        with open(path, encoding="utf-8") as fh:
            return cls(fh.read())

    # ---- tile grid -------------------------------------------------------------------------
    def _array_span(self, name):
        m = re.search(r'"%s" "(?:int|bool|uint8)_array" \n\s*\[\n' % name, self.text)
        if not m:
            raise KeyError(name)
        end = self.text.index("]", m.end())
        return m.end(), end

    def grid(self, name):
        if name not in self._grid:
            a, b = self._array_span(name)
            self._grid[name] = [int(x.strip().strip('",')) for x in self.text[a:b].split("\n") if x.strip()]
        return self._grid[name]

    def touch(self, name):
        self._dirty.add(name)

    def _write_grid(self, name):
        a, b = self._array_span(name)
        indent = re.search(r"\n(\s*)\]", self.text[b - 40:b + 1]).group(1) + "\t"
        nl = "\n"
        vals = self._grid[name]
        body = ("," + nl).join('%s"%d"' % (indent, v) for v in vals) + nl + indent[:-1]
        self.text = self.text[:a] + body + self.text[b:]

    # world <-> grid helpers
    @staticmethod
    def cell_of(x, y):
        return int((x + HALF) // 256), int((y + HALF) // 256)

    @staticmethod
    def obj_of(x, y):
        return int(round((x + HALF) / 64.0)), int(round((y + HALF) / 64.0))

    def ground(self, x, y):
        """World z of the tile grid under a point (bilinear between the four height samples)."""
        H = self.grid("verticesHeight")
        fx = min(max((x + HALF) / 256.0, 0), CELLS - 1e-6)
        fy = min(max((y + HALF) / 256.0, 0), CELLS - 1e-6)
        cx, cy = int(fx), int(fy)
        tx, ty = fx - cx, fy - cy
        h00 = H[cy * VERTS + cx]
        h10 = H[cy * VERTS + cx + 1]
        h01 = H[(cy + 1) * VERTS + cx]
        h11 = H[(cy + 1) * VERTS + cx + 1]
        h = (h00 * (1 - tx) + h10 * tx) * (1 - ty) + (h01 * (1 - tx) + h11 * tx) * ty
        return 128.0 + 128.0 * h

    def flat(self, x, y, radius=0):
        """True when every height sample within `radius` of the point's cell is equal."""
        H = self.grid("verticesHeight")
        cx, cy = self.cell_of(x, y)
        r = int(radius // 256) + 0
        vals = set()
        for j in range(max(0, cy - r), min(VERTS, cy + r + 2)):
            for i in range(max(0, cx - r), min(VERTS, cx + r + 2)):
                vals.add(H[j * VERTS + i])
        return len(vals) == 1

    # ---- tilesets --------------------------------------------------------------------------
    def tilesets(self):
        return re.findall(r'\n\t{6}"targetMapPath" "string" "(maps/tilesets/[^"]+)"', self.text)

    def set_tileset(self, index, path, prop_types, tree_types, plant_types=("none", "sparse", "moderate", "thick")):
        """Point one of the tile grid's four tileset slots at another Valve tileset.

        The grid has exactly four slots (`targetMapPath`, `targetMapPath1..3`); the compiler crashes
        when a cell refers to a fifth."""
        old = self.tilesets()[index]
        blocks = list(re.finditer(r'\n\t{5}"CMapTileObject"\n\t{5}\{\n.*?\n\t{5}\}', self.text, re.S))
        for b in blocks:
            if '"tileSetMapIndex" "int" "%d"' % index in b.group(0):
                block = b.group(0).replace('"targetMapPath" "string" "%s"' % old, '"targetMapPath" "string" "%s"' % path)
                self.text = self.text[:b.start()] + block + self.text[b.end():]
                break
        else:
            raise KeyError(index)
        key = "targetMapPath%d" % index if index else "targetMapPath"
        self.text, n = re.subn(r'(\n\t{4}"%s" "string" )"[^"]+"' % key, lambda m: m.group(1) + '"%s"' % path, self.text, count=1)
        assert n == 1

        def arr(name, values):
            body = ",\n".join('\t\t\t\t\t\t\t\t\t"%s"' % v for v in values)
            return '\t\t\t\t\t\t\t\t"%s" "string_array" \n\t\t\t\t\t\t\t\t[\n%s\n\t\t\t\t\t\t\t\t]\n' % (name, body)

        infos = list(re.finditer(r'\t{7}"CDmeTileSetMapInfo"\n\t{7}\{\n\t{8}"id" "elementid" "[0-9a-f-]+"\n(.*?)\t{7}\}', self.text, re.S))
        m = infos[index]
        body = arr("propTypes", prop_types) + arr("treeTypes", tree_types) + arr("plantTypes", plant_types)
        self.text = self.text[:m.start(1)] + body + self.text[m.end(1):]

    def add_tileset(self, path, prop_types, tree_types, plant_types=("none", "sparse", "moderate", "thick")):
        """Reference another Valve tileset from the tile grid and return its index."""
        have = self.tilesets()
        if path in have:
            return have.index(path)
        index = len(have)
        blocks = list(re.finditer(r'\n\t{5}"CMapTileObject"\n\t{5}\{\n.*?\n\t{5}\}', self.text, re.S))
        last = blocks[-1]
        block = last.group(0)
        block = re.sub(r'"elementid" "[0-9a-f-]+"', lambda m: '"elementid" "%s"' % self._uuid(), block)
        block = re.sub(r'"nodeID" "int" "\d+"', '"nodeID" "int" "%d"' % self._next_node, block, count=1)
        self._next_node += 1
        block = re.sub(r'"referenceID" "uint64" "0x[0-9a-f]+"',
                       '"referenceID" "uint64" "0x%016x"' % self._rng.getrandbits(64), block, count=1)
        block = re.sub(r'"tileSetMapIndex" "int" "\d+"', '"tileSetMapIndex" "int" "%d"' % index, block)
        block = re.sub(r'"targetMapPath" "string" "[^"]+"', '"targetMapPath" "string" "%s"' % path, block)
        self.text = self.text[:last.end()] + "," + block + self.text[last.end():]

        # the grid node lists every tileset path again
        key = '"targetMapPath%d" "string"' % (index - 1) if index > 1 else '"targetMapPath" "string"'
        m = re.search(r'\n\t{4}%s "[^"]+"' % re.escape(key), self.text)
        self.text = self.text[:m.end()] + '\n\t\t\t\t"targetMapPath%d" "string" "%s"' % (index, path) + self.text[m.end():]
        m = re.search(r'\n\t{4}"skyboxMapPath%d" "string" "[^"]*"' % (index - 1), self.text)
        self.text = self.text[:m.end()] + '\n\t\t\t\t"skyboxMapPath%d" "string" ""' % index + self.text[m.end():]

        def arr(name, values):
            body = ",\n".join('\t\t\t\t\t\t\t\t\t"%s"' % v for v in values)
            return '\t\t\t\t\t\t\t\t"%s" "string_array" \n\t\t\t\t\t\t\t\t[\n%s\n\t\t\t\t\t\t\t\t]\n' % (name, body)

        info = ('\t\t\t\t\t\t\t"CDmeTileSetMapInfo"\n\t\t\t\t\t\t\t{\n\t\t\t\t\t\t\t\t"id" "elementid" "%s"\n' % self._uuid()
                + arr("propTypes", prop_types) + arr("treeTypes", tree_types) + arr("plantTypes", plant_types)
                + "\t\t\t\t\t\t\t}")
        m = re.search(r'"tileSetMapInfo" "element_array" \n\t{6}\[\n.*?\n\t{7}\}(?=\n\t{6}\])', self.text, re.S)
        self.text = self.text[:m.end()] + ",\n" + info + self.text[m.end():]
        return index

    # ---- terrain shape ---------------------------------------------------------------------
    def _pattern(self, cx, cy):
        """Corner heights of a cell as (sw, se, nw, ne), relative to its lowest corner."""
        H = self.grid("verticesHeight")
        hs = (H[cy * VERTS + cx], H[cy * VERTS + cx + 1], H[(cy + 1) * VERTS + cx], H[(cy + 1) * VERTS + cx + 1])
        low = min(hs)
        return tuple(h - low for h in hs)

    def learn_orientations(self):
        """Corner patterns the map stores with orientation 0: the unrotated form of each tile shape."""
        O = self.grid("cellsOrientation")
        canon = set()
        for cy in range(CELLS):
            for cx in range(CELLS):
                p = self._pattern(cx, cy)
                if max(p) and O[cy * CELLS + cx] == 0:
                    canon.add(p)
        for k in range(1, 7):
            canon.update({(0, 0, k, k), (0, 0, k, 0), (k, 0, k, k)})
        self._canon = canon
        return canon

    def orientation_for(self, p):
        """Stored orientation for a corner pattern, or None when the shape is unknown or ambiguous.

        Orientation r means the unrotated tile turned r quarter turns counter-clockwise."""
        if not max(p):
            return None
        q = p
        hits = []
        for r in range(4):
            if q in self._canon:
                hits.append(r)
            sw, se, nw, ne = q   # undo one counter-clockwise quarter turn
            q = (se, ne, sw, nw)
        return hits[0] if len(hits) == 1 else None

    def fix_orientation(self, cells):
        """Recompute orientation for the given (cx, cy) cells; returns the cells whose shape is unknown."""
        O = self.grid("cellsOrientation")
        unknown = []
        for cx, cy in cells:
            p = self._pattern(cx, cy)
            if not max(p):
                continue
            r = self.orientation_for(p)
            if r is None:
                unknown.append((cx, cy, p))
            else:
                O[cy * CELLS + cx] = r
        self.touch("cellsOrientation")
        return unknown

    def set_height(self, x0, y0, x1, y1, level=None, delta=None):
        """Set or shift the height samples inside a world rectangle; fixes orientation of touched cells."""
        H = self.grid("verticesHeight")
        touched = set()
        for vy in range(VERTS):
            for vx in range(VERTS):
                x = -HALF + vx * 256
                y = -HALF + vy * 256
                if x0 <= x <= x1 and y0 <= y <= y1:
                    H[vy * VERTS + vx] = level if level is not None else H[vy * VERTS + vx] + delta
                    for cx in (vx - 1, vx):
                        for cy in (vy - 1, vy):
                            if 0 <= cx < CELLS and 0 <= cy < CELLS:
                                touched.add((cx, cy))
        self.touch("verticesHeight")
        self.clear_cell_choice(sorted(touched))
        self.make_land(sorted(touched))
        return self.fix_orientation(sorted(touched))

    # ---- stored tile choices --------------------------------------------------------------
    # cellConfiguration / objectConfiguration hold, per cell or per object slot, the tile and the
    # random variants Hammer picked: a length followed by that many ints. An empty record (a lone 0)
    # makes the compiler choose again, which is what a cell needs after its shape changes.
    def _records(self, name):
        key = "_rec_" + name
        if key not in self._grid:
            flat = self.grid(name)
            out = []
            i = 0
            while i < len(flat):
                n = flat[i]
                out.append(flat[i + 1:i + 1 + n])
                i += 1 + n
            self._grid[key] = out
        return self._grid[key]

    def _flush_records(self, name):
        key = "_rec_" + name
        if key in self._grid:
            flat = []
            for rec in self._grid[key]:
                flat.append(len(rec))
                flat.extend(rec)
            self._grid[name] = flat
            self._dirty.add(name)

    # A flat cell stores which flat tile it uses; that choice is also what makes it land or shallow
    # water. These are the records Hammer wrote for plain land in a Radiant-family and a Dire-family
    # tileset (the *_basic tilesets share node ids within a family).
    LAND_RADIANT = [5292, -1, 18757, 18780, -1]
    LAND_DIRE = [5292, -1, 16361, 16370, -1]
    WATER_CHOICE = 18790

    def is_flat(self, cx, cy):
        return not max(self._pattern(cx, cy))

    def is_water(self, cx, cy):
        return self.WATER_CHOICE in self._records("cellConfiguration")[cy * CELLS + cx]

    def make_land(self, cells, dire=None):
        """Give flat cells the plain land tile. `dire` picks the family; default follows the cell's tileset."""
        rec = self._records("cellConfiguration")
        ts = self.grid("cellsTileSet")
        names = self.tilesets()
        for cx, cy in cells:
            if not self.is_flat(cx, cy):
                continue
            fam = dire if dire is not None else "/dire_" in names[ts[cy * CELLS + cx]]
            rec[cy * CELLS + cx] = list(self.LAND_DIRE if fam else self.LAND_RADIANT)
        self._flush_records("cellConfiguration")

    def cells_in(self, x0, y0, x1, y1):
        out = []
        for cy in range(CELLS):
            for cx in range(CELLS):
                x = -HALF + cx * 256
                y = -HALF + cy * 256
                if x0 <= x and x + 256 <= x1 and y0 <= y and y + 256 <= y1:
                    out.append((cx, cy))
        return out

    def clear_cell_choice(self, cells):
        rec = self._records("cellConfiguration")
        assert len(rec) == CELLS * CELLS, len(rec)
        for cx, cy in cells:
            rec[cy * CELLS + cx] = []
        self._flush_records("cellConfiguration")

    def clear_object_choice(self, slots):
        rec = self._records("objectConfiguration")
        assert len(rec) == OBJS * OBJS, len(rec)
        for i, j in slots:
            rec[j * OBJS + i] = []
        self._flush_records("objectConfiguration")

    # ---- paint layers ----------------------------------------------------------------------
    # 513 x 513 samples, 32 units apart. blendOpacity holds three material layers over the tileset's
    # base ground in its first three channels.
    def colors(self, name):
        key = "_col_" + name
        if key not in self._grid:
            m = re.search(r'"%s" "color_array" \n\s*\[\n' % name, self.text)
            end = self.text.index("]", m.end())
            self._grid[key] = [[int(v) for v in row.strip().strip('",').split()]
                               for row in self.text[m.end():end].split("\n") if row.strip()]
            self._colspan = getattr(self, "_colspan", {})
        return self._grid[key]

    def touch_colors(self, name):
        self._dirty.add("_col_" + name)

    def _write_colors(self, name):
        m = re.search(r'"%s" "color_array" \n(\s*)\[\n' % name, self.text)
        end = self.text.index("]", m.end())
        indent = m.group(1) + "\t"
        rows = self._grid["_col_" + name]
        body = ",\n".join('%s"%d %d %d %d"' % (indent, r[0], r[1], r[2], r[3]) for r in rows) + "\n" + indent[:-1]
        self.text = self.text[:m.end()] + body + self.text[end:]

    # ---- water ----------------------------------------------------------------------------
    def set_water(self, x0, y0, x1, y1, wet):
        """Mark the height samples in a world rectangle as water or dry land (verticesWater)."""
        W = self.grid("verticesWater")
        touched = set()
        for vy in range(VERTS):
            for vx in range(VERTS):
                x = -HALF + vx * 256
                y = -HALF + vy * 256
                if x0 <= x <= x1 and y0 <= y <= y1 and W[vy * VERTS + vx] != int(wet):
                    W[vy * VERTS + vx] = int(wet)
                    for cx in (vx - 1, vx):
                        for cy in (vy - 1, vy):
                            if 0 <= cx < CELLS and 0 <= cy < CELLS:
                                touched.add((cx, cy))
        self.touch("verticesWater")
        self.clear_cell_choice(sorted(touched))
        return touched

    def wet(self, x, y):
        W = self.grid("verticesWater")
        vx = int(round((x + HALF) / 256.0))
        vy = int(round((y + HALF) / 256.0))
        return bool(W[vy * VERTS + vx])

    # ---- trees and tileset dressing --------------------------------------------------------
    def tree_at(self, i, j):
        return self.grid("objectsTreeType")[j * OBJS + i]

    def paint_tree(self, i, j, tree_type, tileset=None, size=2):
        """Put a tree (or remove it with type 0) on object slot (i, j); slots are 64 units apart."""
        k = j * OBJS + i
        self.grid("objectsTreeType")[k] = tree_type
        self.grid("objectsTreeSize")[k] = size if tree_type else 0
        self.grid("objectsRotation")[k] = self._rng.randrange(144) if tree_type else 0
        self.grid("objectsPitch")[k] = self._rng.randrange(19) if tree_type else 0
        self.grid("objectsVariationId")[k] = self._rng.choice((0, 0, 0, 1, 2)) if tree_type else 255
        if tileset is not None:
            self.grid("objectsTileSet")[k] = tileset
        self._records("objectConfiguration")[k] = []
        self._obj_dirty = True

    def paint_prop(self, i, j, prop_type=0, plant_type=0, tileset=None):
        """Ask the tileset for one of its own props or plants on object slot (i, j)."""
        k = j * OBJS + i
        self.grid("objectsPropType")[k] = prop_type
        self.grid("objectsPlantType")[k] = plant_type
        if prop_type or plant_type:
            self.grid("objectsRotation")[k] = self._rng.randrange(144)
        if tileset is not None:
            self.grid("objectsTileSet")[k] = tileset
        self._records("objectConfiguration")[k] = []
        self._obj_dirty = True

    def _flush_objects(self):
        if getattr(self, "_obj_dirty", False):
            for name in ("objectsTreeType", "objectsTreeSize", "objectsRotation", "objectsPitch",
                         "objectsVariationId", "objectsPropType", "objectsPlantType", "objectsTileSet"):
                self.touch(name)
            self._flush_records("objectConfiguration")
            self._obj_dirty = False

    # ---- brush meshes ----------------------------------------------------------------------
    def add_plane(self, material_like, x0, y0, x1, y1, z, thickness=8.0):
        """Add a flat slab by cloning an existing box mesh that uses `material_like`."""
        blocks = [b for b in re.finditer(r'\n(\t*)"CMapMesh"\n\1\{\n.*?\n\1\}', self.text, re.S)
                  if material_like in b.group(0) and b.group(0).count('"vector3_array"') and
                  len(re.findall(r'"position:0".*?"data" "vector3_array" \n\s*\[\n(.*?)\n\s*\]', b.group(0), re.S)[0].split("\n")) == 8]
        if not blocks:
            raise KeyError(material_like)
        src = blocks[0]
        block = src.group(0)
        indent = src.group(1)
        m = re.search(r'("position:0".*?"data" "vector3_array" \n\s*\[\n)(.*?)(\n\s*\])', block, re.S)
        rows = [[float(v) for v in r.strip().strip('",').split()] for r in m.group(2).split("\n")]
        hx = max(abs(r[0]) for r in rows)
        hy = max(abs(r[1]) for r in rows)
        hz = max(abs(r[2]) for r in rows)
        sx, sy, sz = (x1 - x0) / 2.0 / hx, (y1 - y0) / 2.0 / hy, thickness / 2.0 / hz
        pad = re.match(r"\s*", m.group(2)).group(0)
        body = ",\n".join('%s"%s"' % (pad, fmt((r[0] * sx, r[1] * sy, r[2] * sz))) for r in rows)
        block = block[:m.start(2)] + body + block[m.end(2):]
        block = re.sub(r'"elementid" "[0-9a-f-]+"', lambda mm: '"elementid" "%s"' % self._uuid(), block)
        block = re.sub(r'"nodeID" "int" "\d+"', '"nodeID" "int" "%d"' % self._next_node, block, count=1)
        self._next_node += 1
        block = re.sub(r'"referenceID" "uint64" "0x[0-9a-f]+"',
                       '"referenceID" "uint64" "0x%016x"' % self._rng.getrandbits(64), block, count=1)
        block = re.sub(r'(\n%s\t"origin" "vector3" )"[^"]*"' % indent,
                       lambda mm: mm.group(1) + '"%s"' % fmt(((x0 + x1) / 2.0, (y0 + y1) / 2.0, float(z))), block, count=1)
        # re-indent to the world's child level and queue with the entities
        lines = block.lstrip("\n").split("\n")
        cut = len(indent)
        lines = ["\t\t\t" + l[cut:] for l in lines]
        self._pending.append("\n".join(lines) + ",\n")

    # ---- entities --------------------------------------------------------------------------
    def add_entity(self, classname, origin, props=None, angles=(0, 0, 0), scales=(1, 1, 1)):
        props = dict(props or {})
        rows = []
        for key, default in DEFAULTS.get(classname, []):
            rows.append((key, props.pop(key, default)))
        rows += sorted(props.items())
        body = "".join('\t\t\t\t\t"%s" "string" "%s"\n' % (k, fmt(v)) for k, v in rows)
        block = ENTITY % {
            "id": self._uuid(), "plug": self._uuid(), "props_id": self._uuid(),
            "node": self._next_node, "ref": self._rng.getrandbits(64),
            "classname": classname, "props": body,
            "origin": fmt(tuple(float(v) for v in origin)), "angles": fmt(tuple(float(v) for v in angles)),
            "scales": fmt(tuple(float(v) for v in scales)),
        }
        self._next_node += 1
        self._pending.append(block)

    def _uuid(self):
        return str(uuid.UUID(int=self._rng.getrandbits(128), version=4))

    # ---- output ----------------------------------------------------------------------------
    def render(self):
        self._flush_objects()
        for name in sorted(self._dirty):
            if name.startswith("_col_"):
                self._write_colors(name[5:])
            else:
                self._write_grid(name)
        self._dirty.clear()
        if self._pending:
            m = re.search(r'"world" "CMapWorld"\s*\{.*?"children" "element_array" \r?\n\s*\[\r?\n', self.text, re.S)
            blocks = "".join(self._pending)
            self.text = self.text[:m.end()] + blocks + self.text[m.end():]
            self._pending = []
        return self.text

    def save(self, path):
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(self.render())
