"""Verify mounted Panorama resources and deploy into a disposable Steam layout."""

import json
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

REPO = Path(__file__).resolve().parents[1]


def check_panorama(content, game):
    panorama = content / "panorama"
    layouts = panorama / "layout" / "custom_game"
    client_tokens = (game / "resource" / "addon_english.txt").read_text(encoding="utf-16")
    author_tokens = (content / "addon_english_utf8.txt").read_text(encoding="utf-8-sig")
    token_names = set(re.findall(r'^\s*"(arena_[^"]+)"\s+"[^"]+"', client_tokens, re.M))
    assert token_names == set(re.findall(r'^\s*"(arena_[^"]+)"\s+"[^"]+"', author_tokens, re.M))

    pending = [layouts / name for name in ("custom_ui_manifest.xml", "custom_loading_screen.xml")]
    visited = set()
    while pending:
        layout = pending.pop()
        if layout in visited:
            continue
        visited.add(layout)
        for node in ET.parse(layout).iter():
            for attribute in ("src", "layoutfile"):
                reference = node.get(attribute, "")
                if reference.startswith("file://{resources}/"):
                    target = panorama / reference.removeprefix("file://{resources}/")
                elif reference.startswith("file://{images}/"):
                    target = panorama / "images" / reference.removeprefix("file://{images}/")
                else:
                    continue
                assert target.is_file(), (layout, reference)
                if target.suffix == ".xml":
                    pending.append(target)
                if target.suffix == ".js":
                    for token in re.findall(r'["\']#(arena_[a-z_]+)["\']', target.read_text(encoding="utf-8-sig")):
                        assert token in token_names, (target, token)
            label = node.get("text", "")
            if label.startswith("#arena_"):
                assert label[1:] in token_names, (layout, label)
    assert layouts / "arena_match.xml" in visited


def deploy(root, *flags, success=True):
    result = subprocess.run(
        [sys.executable, REPO / "tools" / "deploy.py", root, *flags],
        capture_output=True,
        text=True,
    )
    assert (result.returncode == 0) == success, (result.stdout, result.stderr)
    return result


def main():
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory) / "Dota 2 Beta"
        game_info = root / "game" / "dota" / "gameinfo.gi"
        game_info.parent.mkdir(parents=True)
        game_info.touch()
        (root / "content").mkdir()
        content = root / "content" / "dota_addons" / "angel_arena"
        game = root / "game" / "dota_addons" / "angel_arena"

        deploy(root, "--dry-run")
        assert not content.exists() and not game.exists()
        game.mkdir(parents=True)
        assert "unmanaged" in deploy(root, success=False).stderr
        assert not content.exists()
        game.rmdir()

        deploy(root)
        assert (content / "maps" / "angel_arena.vmap").is_file()
        assert (game / "scripts" / "vscripts" / "addon_game_mode.lua").is_file()
        assert (game / "models" / "lavawaterfall.vmdl_c").is_file()
        icon = "imba_custom/imba_magic_stick.png"
        original = game / "resource" / "flash3" / "images" / "items" / icon
        assert (content / "panorama" / "images" / "items" / icon).read_bytes() == original.read_bytes()
        assert not list((game / "panorama").rglob("*.vxml_c"))
        check_panorama(content, game)

        compiled_map = game / "maps" / "angel_arena.vpk"
        compiled_map.parent.mkdir(parents=True)
        compiled_map.write_bytes(b"simulated Hammer output")
        again = deploy(root)
        assert again.stdout.count("0 copied, 0 removed") == 2
        assert compiled_map.read_bytes() == b"simulated Hammer output"

        marker = game / ".angel-arena-deploy.json"
        deployed = json.loads(marker.read_text(encoding="utf-8"))
        interrupted = deployed.copy()
        model = "models/lavawaterfall.vmdl_c"
        interrupted.pop(model)
        marker.write_text(json.dumps(interrupted), encoding="utf-8")
        deploy(root)
        assert json.loads(marker.read_text(encoding="utf-8"))[model] == deployed[model]

        edited_map = content / "maps" / "angel_arena.vmap"
        edited_map.write_bytes(b"uncommitted Hammer edit")
        assert "Local edits would be overwritten" in deploy(root, success=False).stderr
        assert edited_map.read_bytes() == b"uncommitted Hammer edit"
    print("Workshop layout, Panorama links and localization, and deploy safety checks passed")


if __name__ == "__main__":
    main()
