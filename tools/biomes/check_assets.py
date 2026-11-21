#!/usr/bin/env python3
"""Check that every Dota asset a biome names really exists in the Dota install.

    python tools/biomes/check_assets.py [biome ...] [--dota "<...>/dota 2 beta/game/dota"]

With no biome, checks the shared effects and every biome. Looks inside Dota's pak01 archive for:
  * unit Models, ProjectileModels, GameSoundsFiles and "precache" entries (unit KV)
  * ability icons (AbilityTextureName -> panorama/images/spellicons/<name>_png)
  * every particle, model and soundevents file in fx.lua and boss.lua
  * every sound event name in fx.lua / boss.lua, inside the biome's soundevents files
  * every loot item that is not one of the addon's own items, in Dota's items.txt
and reports unit SoundSets that no loaded soundevents file mentions (a warning: Dota preloads
some sets itself). Compiled files in the archive end in "_c"; this script adds that itself.

The Dota folder defaults to the DOTA_GAME_DIR environment variable, then the usual Steam path.
"""
import os
import re
import struct
import sys
from pathlib import Path

sys.dont_write_bytecode = True  # no __pycache__ beside the tools
sys.path.insert(0, str(Path(__file__).resolve().parent))
import biomelib  # noqa: E402

DEFAULT_DOTA = r"D:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota"


class Archive:
    """Read-only view of Dota's pak01_dir.vpk."""

    def __init__(self, folder):
        self.folder = Path(folder)
        with open(self.folder / "pak01_dir.vpk", "rb") as handle:
            signature, version, tree_size = struct.unpack("<III", handle.read(12))
            if signature != 0x55AA1234:
                raise SystemExit("not a VPK directory file: " + str(self.folder / "pak01_dir.vpk"))
            self.header = 12
            if version == 2:
                handle.read(16)
                self.header = 28
            tree = handle.read(tree_size)
        self.tree_size = tree_size
        self.entries = {}
        position = 0

        def text():
            nonlocal position
            end = tree.index(b"\0", position)
            value = tree[position:end].decode("utf-8", "replace")
            position = end + 1
            return value

        while True:
            extension = text()
            if not extension:
                break
            while True:
                directory = text()
                if not directory:
                    break
                while True:
                    name = text()
                    if not name:
                        break
                    _, preload, archive, offset, length, _ = struct.unpack_from("<IHHIIH", tree, position)
                    position += 18
                    data = tree[position:position + preload]
                    position += preload
                    path = (directory + "/" if directory.strip() else "") + name + "." + extension
                    self.entries[path.lower()] = (archive, offset, length, data)

    def has(self, path):
        return path.lower() in self.entries

    def read(self, path):
        archive, offset, length, data = self.entries[path.lower()]
        if archive == 0x7FFF:
            with open(self.folder / "pak01_dir.vpk", "rb") as handle:
                handle.seek(self.header + self.tree_size + offset)
                return data + handle.read(length)
        with open(self.folder / ("pak01_%03d.vpk" % archive), "rb") as handle:
            handle.seek(offset)
            return data + handle.read(length)


def lz4_block(source, size):
    try:
        import lz4.block
        return lz4.block.decompress(source, uncompressed_size=size)
    except ImportError:
        pass
    out, index = bytearray(), 0
    while index < len(source):
        token = source[index]
        index += 1
        literal = token >> 4
        if literal == 15:
            while True:
                extra = source[index]
                index += 1
                literal += extra
                if extra != 255:
                    break
        out += source[index:index + literal]
        index += literal
        if index >= len(source):
            break
        back = source[index] | (source[index + 1] << 8)
        index += 2
        match = token & 15
        if match == 15:
            while True:
                extra = source[index]
                index += 1
                match += extra
                if extra != 255:
                    break
        start = len(out) - back
        for step in range(match + 4):
            out.append(out[start + step])
    return bytes(out)


def resource_strings(blob):
    """Printable strings inside a compiled resource's DATA block (KV3 version 5 is unpacked)."""
    block_offset, block_count = struct.unpack_from("<II", blob, 8)
    data = blob
    for index in range(block_count):
        entry = 8 + block_offset + index * 12
        if blob[entry:entry + 4] == b"DATA":
            offset, size = struct.unpack_from("<II", blob, entry + 4)
            data = blob[entry + 4 + offset:entry + 4 + offset + size]
    buffers = [data]
    if data[1:4] == b"3VK" and data[0] >= 5:
        method = struct.unpack_from("<I", data, 20)[0]
        sizes = struct.unpack_from("<" + "I" * 12, data, 20 + 4 + 2 + 2 + 16 + 4 + 24)
        start = 20 + 4 + 2 + 2 + 16 + 4 + 24 + 48
        first_size, first_packed, second_size, second_packed = sizes[:4]
        if method == 1:
            buffers = [lz4_block(data[start:start + first_packed], first_size),
                       lz4_block(data[start + first_packed:start + first_packed + second_packed], second_size)]
        else:
            buffers = [data[start:start + first_size], data[start + first_size:start + first_size + second_size]]
    found = set()
    for buffer in buffers:
        found.update(match.decode("ascii") for match in re.findall(rb"[\x20-\x7e]{3,}", buffer))
    return found


class Checker:
    def __init__(self, archive):
        self.archive = archive
        self.events = {}
        self.problems, self.warnings = [], []

    def asset(self, path, where):
        if not path:
            return
        compiled = path if path.endswith("_c") else path + "_c"
        if not self.archive.has(compiled):
            self.problems.append("%s: %s is not in Dota's archive" % (where, path))

    def sound_events(self, soundfile):
        if soundfile not in self.events:
            compiled = soundfile + "_c"
            self.events[soundfile] = resource_strings(self.archive.read(compiled)) if self.archive.has(compiled) else set()
        return self.events[soundfile]

    def stock_items(self):
        if not self.archive.has("scripts/npc/items.txt"):
            return None
        text = self.archive.read("scripts/npc/items.txt").decode("utf-8", "replace")
        return set(re.findall(r'^\t"(item_[A-Za-z0-9_]+)"', text, re.M))

    def fx(self, fx, where, soundfiles):
        for key, path in (fx.get("particles") or {}).items():
            self.asset(path, "%s particle %s" % (where, key))
        for path in biomelib.as_list(fx.get("models")):
            self.asset(path, "%s model" % where)
        for path in biomelib.as_list(fx.get("soundfiles")):
            self.asset(path, "%s soundfile" % where)
        events = set()
        for path in soundfiles:
            events |= self.sound_events(path)
        for key, event in (fx.get("sounds") or {}).items():
            if event not in events:
                self.problems.append("%s sound %s: event %s is in none of %s" % (where, key, event, ", ".join(soundfiles)))

    def biome(self, name, core_soundfiles):
        paths = biomelib.files(name)
        data = biomelib.load_lua(name)
        fx = data.get("fx") or {}
        soundfiles = list(core_soundfiles) + biomelib.as_list(fx.get("soundfiles"))
        units, _ = biomelib.kv_blocks(paths["units_kv"]) if paths["units_kv"].is_file() else ({}, [])
        for unit, pairs in units.items():
            sound_file = biomelib.first(pairs, "GameSoundsFile")
            if sound_file and sound_file not in soundfiles:
                soundfiles.append(sound_file)
        self.fx(fx, name + " fx.lua", soundfiles)
        boss = data.get("boss") or {}
        if boss:
            self.fx({"particles": boss.get("effects") or {}, "sounds": boss.get("sounds") or {}}, name + " boss.lua", soundfiles)
        for unit, pairs in units.items():
            where = "%s unit %s" % (name, unit)
            for key in ("Model", "ProjectileModel", "GameSoundsFile"):
                self.asset(biomelib.first(pairs, key), "%s %s" % (where, key))
            for kind, path in biomelib.first(pairs, "precache", []) or []:
                self.asset(path, "%s precache %s" % (where, kind))
            sound_set = biomelib.first(pairs, "SoundSet")
            if sound_set and not any(event.startswith(sound_set + ".") for path in soundfiles for event in self.sound_events(path)):
                self.warnings.append("%s SoundSet %s is in none of %s" % (where, sound_set, ", ".join(soundfiles)))
        abilities, _ = biomelib.kv_blocks(paths["abilities_kv"]) if paths["abilities_kv"].is_file() else ({}, [])
        for ability, pairs in abilities.items():
            icon = biomelib.first(pairs, "AbilityTextureName")
            if icon and not self.archive.has("panorama/images/spellicons/%s_png.vtex_c" % icon):
                self.problems.append("%s ability %s: icon %s is not one of Dota's spell icons" % (name, ability, icon))
        stock = self.stock_items()
        custom = biomelib.custom_item_names()
        for item in biomelib.loot_items(data.get("monsters"), boss):
            if item not in custom and stock is not None and item not in stock:
                self.problems.append("%s loot item %s is neither an addon item nor a Dota item" % (name, item))
        if name == "wilds" and stock is not None:
            # Wilds uses Dota's own units: they must exist in Dota's unit list.
            text = self.archive.read("scripts/npc/npc_units.txt").decode("utf-8", "replace")
            known = set(re.findall(r'^\t"(npc_dota_[A-Za-z0-9_]+)"', text, re.M))
            for unit in ((data.get("monsters") or {}).get("monsters") or {}):
                if unit not in known:
                    self.problems.append("wilds unit %s is not one of Dota's units" % unit)


def main():
    args = sys.argv[1:]
    dota = os.environ.get("DOTA_GAME_DIR", DEFAULT_DOTA)
    if "--dota" in args:
        index = args.index("--dota")
        dota = args[index + 1]
        del args[index:index + 2]
    if not (Path(dota) / "pak01_dir.vpk").is_file():
        print("Dota's archive was not found at %s; pass --dota <...>/game/dota or set DOTA_GAME_DIR" % dota)
        return 2
    biomes = args or biomelib.biome_names()
    checker = Checker(Archive(dota))
    core = biomelib.load_lua("core").get("fx") or {}
    core_soundfiles = biomelib.as_list(core.get("soundfiles"))
    checker.fx(core, "arena/core/fx.lua", core_soundfiles)
    stock = checker.stock_items()
    custom = biomelib.custom_item_names()
    for item in biomelib.shared_loot():
        if item not in custom and stock is not None and item not in stock:
            checker.problems.append("arena/core/rewards.lua loot item %s is neither an addon item nor a Dota item" % item)
    for name in biomes:
        checker.biome(name, core_soundfiles)
    for warning in checker.warnings:
        print("warning: " + warning)
    for problem in checker.problems:
        print("missing: " + problem)
    print("checked %s: %d missing, %d warnings" % (", ".join(biomes), len(checker.problems), len(checker.warnings)))
    return 1 if checker.problems else 0


if __name__ == "__main__":
    sys.exit(main())
