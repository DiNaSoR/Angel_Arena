"""Check that every asset path in the theme catalogue exists in Dota 2's main archive.

Usage:
    python verify_catalog.py [path/to/pak01_dir.vpk]

Reads ice/desert/lava/green/common.json next to this script, and for every entry
looks up `path + "_c"` (e.g. models/x.vmdl -> models/x.vmdl_c) in the pak01 directory
tree. Also checks the JSON shape. Exits 1 and lists the offenders if anything is
missing or malformed, 0 otherwise.

The VPK location defaults to the Steam install used on this machine; pass another
pak01_dir.vpk as the first argument or set DOTA_PAK01 to override.
"""
import json
import os
import struct
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FILES = ["ice", "desert", "lava", "green", "common"]
CATEGORIES = ["trees", "rocks", "structures", "clutter", "lights", "water_lava",
              "ambient_particles", "creatures", "sounds"]
SIZES = {"small", "medium", "large", "huge"}
DEFAULT_VPK = r"D:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\pak01_dir.vpk"


def vpk_paths(vpk_file):
    """Return the set of all file paths in a VPK v1/v2 directory file."""
    with open(vpk_file, "rb") as f:
        sig, ver, tree_size = struct.unpack("<III", f.read(12))
        if sig != 0x55AA1234:
            raise SystemExit("not a VPK directory file: %s" % vpk_file)
        if ver == 2:
            f.read(16)
        data = f.read(tree_size)
    pos = 0
    paths = set()

    def read_str():
        nonlocal pos
        end = data.index(b"\0", pos)
        s = data[pos:end].decode("utf8", "replace")
        pos = end + 1
        return s

    while True:
        ext = read_str()
        if not ext:
            break
        while True:
            directory = read_str()
            if not directory:
                break
            while True:
                name = read_str()
                if not name:
                    break
                preload = struct.unpack_from("<H", data, pos + 4)[0]
                pos += 18 + preload
                full = (directory + "/" if directory.strip() else "") + name + "." + ext
                paths.add(full.lower())
    return paths


def main():
    vpk = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("DOTA_PAK01", DEFAULT_VPK)
    if not os.path.isfile(vpk):
        print("pak01_dir.vpk not found: %s" % vpk)
        return 2
    archive = vpk_paths(vpk)
    problems = []
    total = 0
    for name in FILES:
        fn = os.path.join(HERE, name + ".json")
        try:
            with open(fn, encoding="utf8") as f:
                doc = json.load(f)
        except (OSError, ValueError) as e:
            problems.append("%s.json: cannot read (%s)" % (name, e))
            continue
        for cat in CATEGORIES:
            if cat not in doc or not isinstance(doc[cat], list):
                problems.append("%s.json: missing list '%s'" % (name, cat))
        for cat, entries in doc.items():
            if cat not in CATEGORIES:
                problems.append("%s.json: unexpected key '%s'" % (name, cat))
                continue
            for i, e in enumerate(entries):
                where = "%s.json %s[%d]" % (name, cat, i)
                if not isinstance(e, dict) or not isinstance(e.get("path"), str):
                    problems.append("%s: entry has no path" % where)
                    continue
                total += 1
                p = e["path"]
                if e.get("size") not in SIZES:
                    problems.append("%s: bad size %r (%s)" % (where, e.get("size"), p))
                if not isinstance(e.get("size_verified"), bool):
                    problems.append("%s: size_verified must be a bool (%s)" % (where, p))
                if not e.get("note"):
                    problems.append("%s: empty note (%s)" % (where, p))
                want = ".vpcf" if cat == "ambient_particles" else (".vsndevts" if cat == "sounds" else ".vmdl")
                if cat == "sounds":
                    continue  # sound entries are event names, checked by hand
                if not p.endswith(want):
                    problems.append("%s: expected a %s path: %s" % (where, want, p))
                if (p + "_c").lower() not in archive:
                    problems.append("%s: NOT IN ARCHIVE: %s" % (where, p))
    if problems:
        print("FAILED: %d problem(s) in %d entries" % (len(problems), total))
        for line in problems:
            print("  " + line)
        return 1
    print("OK: all %d catalogue paths exist in %s" % (total, os.path.basename(vpk)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
