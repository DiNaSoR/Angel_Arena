#!/usr/bin/env python3
"""Deploy Angel Arena source and runtime files into a Dota 2 installation."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import tempfile

ADDON = "angel_arena"
REPO = Path(__file__).resolve().parents[1]
MANIFEST = ".angel-arena-deploy.json"
OLD_PANORAMA_EXTENSIONS = {".vcss_c", ".vjs_c", ".vxml_c"}


def digest(path):
    with path.open("rb") as stream:
        checksum = hashlib.sha256()
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            checksum.update(chunk)
        return checksum.hexdigest()


def source_files(source, bucket):
    for path in sorted(source.rglob("*")):
        relative = path.relative_to(source)
        if not path.is_file() or path.name == "sync.ffs_db" or ".vscode" in relative.parts:
            continue
        if bucket == "game" and relative.parts[0] == "panorama" and path.suffix in OLD_PANORAMA_EXTENSIONS:
            continue
        yield relative.as_posix(), path

    if bucket == "content":
        legacy_items = REPO / "game" / ADDON / "resource" / "flash3" / "images" / "items"
        panorama_items = Path("panorama") / "images" / "items"
        for icon in sorted(legacy_items.rglob("*.png")):
            destination = panorama_items / icon.relative_to(legacy_items)
            if icon.is_file() and not (source / destination).exists():
                yield destination.as_posix(), icon


def safe_target(root, name):
    relative = Path(name)
    if relative.is_absolute() or relative.anchor or ".." in relative.parts or not relative.parts:
        raise ValueError(f"Invalid deployed file path: {name}")
    target = root / relative
    if target.resolve() != target:
        raise ValueError(f"Refusing to modify a symbolic link: {target}")
    return target


def plan(source, destination, bucket):
    if not source.is_dir():
        raise ValueError(f"Missing addon source: {source}")
    if destination.resolve() != destination:
        raise ValueError(f"Refusing to deploy through a symbolic link: {destination}")
    marker = destination / MANIFEST
    previous = {}
    if destination.exists():
        if not marker.is_file() or marker.is_symlink():
            raise ValueError(f"Existing addon is unmanaged. Move it somewhere safe first: {destination}")
        previous = json.loads(marker.read_text(encoding="utf-8"))
        if not isinstance(previous, dict):
            raise ValueError(f"Invalid deployment manifest: {marker}")

    sources = dict(source_files(source, bucket))
    current = {name: digest(path) for name, path in sources.items()}
    updates, removals = [], []
    for name in sorted(previous.keys() | current.keys()):
        target = safe_target(destination, name)
        installed = digest(target) if target.exists() else None
        if installed == current.get(name):
            continue
        if installed is not None and installed != previous.get(name):
            raise ValueError(f"Local edits would be overwritten. Save them back to the repo first: {target}")
        if name in current:
            updates.append((sources[name], target))
        else:
            removals.append(target)
    return destination, current, updates, removals, current != previous


def write_manifest(destination, files):
    with tempfile.NamedTemporaryFile(
        dir=destination, mode="w", encoding="utf-8", delete=False
    ) as temporary:
        temporary_path = Path(temporary.name)
        json.dump(files, temporary, indent=2, sort_keys=True)
        temporary.write("\n")
    try:
        temporary_path.replace(destination / MANIFEST)
    finally:
        temporary_path.unlink(missing_ok=True)


def apply(destination, current, updates, removals):
    destination.mkdir(parents=True, exist_ok=True)
    if not (destination / MANIFEST).exists():
        write_manifest(destination, {})
    for source, target in updates:
        target.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as temporary:
            temporary_path = Path(temporary.name)
        try:
            shutil.copyfile(source, temporary_path)
            temporary_path.replace(target)
        finally:
            temporary_path.unlink(missing_ok=True)
    for target in removals:
        target.unlink()
    write_manifest(destination, current)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("dota_root", type=Path, help="Dota 2 Beta folder containing game and content")
    parser.add_argument("--dry-run", action="store_true", help="Inspect destinations without writing files")
    args = parser.parse_args()
    dota_root = args.dota_root.resolve()
    if not (dota_root / "game" / "dota" / "gameinfo.gi").is_file():
        parser.error(f"No Dota 2 installation found at {dota_root}")

    try:
        plans = [
            plan(REPO / bucket / ADDON, dota_root / bucket / "dota_addons" / ADDON, bucket)
            for bucket in ("content", "game")
        ]
        for destination, current, updates, removals, manifest_changed in plans:
            if not args.dry_run and (updates or removals or manifest_changed):
                apply(destination, current, updates, removals)
            if args.dry_run:
                print(f"{destination}: {len(updates)} to copy, {len(removals)} to remove")
            else:
                print(f"{destination}: {len(updates)} copied, {len(removals)} removed")
    except (OSError, ValueError) as error:
        parser.exit(1, f"Deployment stopped: {error}\n")


if __name__ == "__main__":
    main()
