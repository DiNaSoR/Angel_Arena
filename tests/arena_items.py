"""Check the generated Angel Arena item set against its source, its icons and the shop."""

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GAME = REPO / "game" / "angel_arena"
sys.path.insert(0, str(REPO / "tools" / "items"))
from arena_items import ITEMS  # noqa: E402
import build_arena_items as build  # noqa: E402

VALVE_ID_CEILING = 9999  # Dota's own registry uses every id range up to here


def main():
    # The generated files match tools/items/arena_items.py.
    check = subprocess.run([sys.executable, REPO / "tools" / "items" / "build_arena_items.py", "--check"],
                           capture_output=True, text=True)
    assert check.returncode == 0, check.stdout + check.stderr

    kv = build.KV_PATH.read_text(encoding="utf-8")
    names = re.findall(r'^\t"(item_[a-z_]+)"', kv, re.M)
    ids = [int(value) for value in re.findall(r'^\t\t"ID"\t\t"(\d+)"', kv, re.M)]
    assert len(names) == len(ids) == len(set(names)) == len(set(ids))
    assert min(ids) > VALVE_ID_CEILING, "item ids must stay clear of Dota's own"
    assert sum(1 for name in names if name.startswith("item_arena_")) == 99

    # No clash with the ids of the hand-written items that are loaded alongside.
    root = GAME / "scripts" / "npc" / "npc_items_custom.txt"
    others = []
    for include in re.findall(r'^#base\s+"([^"]+)"', root.read_text(encoding="utf-8-sig"), re.M):
        path = root.parent / include
        if path != build.KV_PATH:
            others += [int(value) for value in re.findall(r'"ID"\s+"(\d+)"', path.read_text(encoding="utf-8-sig"))]
    assert not set(ids) & set(others), sorted(set(ids) & set(others))
    assert build.KV_PATH in [root.parent / include for include in
                             re.findall(r'^#base\s+"([^"]+)"', root.read_text(encoding="utf-8-sig"), re.M)]

    scripts = "".join((GAME / "scripts" / "vscripts" / "items" / "arena" / name).read_text(encoding="utf-8")
                      for name in ("arena_items.lua", "arena_modifiers.lua"))
    shop = build.SHOP_PATH.read_text(encoding="utf-8")
    tokens = (GAME / "resource" / "addon_english.txt").read_text(encoding="utf-16")
    mirror = (REPO / "content" / "angel_arena" / "addon_english_utf8.txt").read_text(encoding="utf-8-sig")
    icons = GAME / "resource" / "flash3" / "images" / "items" / "arena"
    builder = Path(build.__file__).read_text(encoding="utf-8")
    keys = {entry["key"] for entry in ITEMS}

    for entry in build.priced(ITEMS):
        name = "item_arena_" + entry["key"]
        assert (icons / (entry["key"] + ".png")).is_file(), "missing icon for " + name
        assert shop.count('"%s"' % name) == 1, name + " must be listed in the shop exactly once"

        # Every number a tooltip quotes is a value the item really has.
        text = build.description(entry, ITEMS)
        assert text, name + " needs a description"
        for placeholder in re.findall(r"%([a-z_]+)%", text):
            assert placeholder in entry["values"], (name, placeholder)
        for line in ("", "_Lore") + (("_Description",) if text else ()):
            token = '"DOTA_Tooltip_ability_%s%s"' % (name, line)
            assert token in tokens and token in mirror, token

        # Every effect an item names is implemented.
        for mechanic in entry["mech"]:
            assert re.search(r'\("%s"' % mechanic, scripts), (name, mechanic)
        if entry["active"]:
            assert "function actives.%s(" % entry["active"][0] in scripts, (name, entry["active"])
        if entry["consume"]:
            assert "function consumables.%s(" % entry["consume"] in scripts, (name, entry["consume"])

        # Values are either plain stats or belong to an effect the item has.
        effects = entry["mech"] + ([entry["active"][0]] if entry["active"] else []) + \
            ([entry["consume"]] if entry["consume"] else [])
        for value in entry["values"]:
            if value not in build.STAT_LINES:
                used = re.search(r"\.%s\b" % value, scripts)
                assert used or 'values["%s"]' % value in builder, (name, value)  # the builder reads cast range
                assert effects, (name, value)

        if entry["recipe"]:
            components, scroll = entry["recipe"]
            assert scroll >= 0 and len(components) >= 2
            for component in components:
                assert component in keys or component.startswith("item_"), (name, component)
            assert entry["cost"] > scroll

    print("Checked 99 Angel Arena items: ids, icons, shop entries, tooltips and effects")


if __name__ == "__main__":
    main()
