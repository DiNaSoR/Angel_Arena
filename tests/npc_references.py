"""Check active NPC includes and Lua references from the addon's KeyValues roots."""

import re
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "game" / "angel_arena" / "scripts"
BASE_INCLUDE = re.compile(r'^[ \t]*#base[ \t]+"([^"]+)"', re.MULTILINE)
SCRIPT_REFERENCE = re.compile(r'^[ \t]*"(ScriptFile|vscripts)"[ \t]+"([^"]+)"', re.MULTILINE | re.IGNORECASE)
SCRIPT_CALLBACK = re.compile(r'^[ \t]*"ScriptFile"[ \t]+"([^"]+)"\s*"Function"[ \t]+"([^"]+)"', re.MULTILINE)
LUA_FUNCTION = re.compile(r"^\s*function\s+(\w+)\s*\(", re.MULTILINE)


def read_source(path):
    contents = path.read_bytes()
    encoding = "utf-16" if contents.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig"
    return contents.decode(encoding)


def main():
    pending = list(sorted((SCRIPTS / "npc").glob("npc_*.txt")))
    if not pending:
        raise SystemExit("No NPC KeyValues roots found")

    seen = set()
    callbacks = 0
    script_references = 0
    failures = []
    while pending:
        path = pending.pop()
        if path in seen:
            continue
        seen.add(path)

        contents = read_source(path)
        label = path.relative_to(SCRIPTS)
        for reference in BASE_INCLUDE.findall(contents):
            included = path.parent / reference
            if included.is_file():
                pending.append(included)
            else:
                failures.append(f"{label} includes missing file {reference}")

        for kind, references in SCRIPT_REFERENCE.findall(contents):
            scripts = references.split() if kind.lower() == "vscripts" else [references]
            for reference in scripts:
                script_references += 1
                if not (SCRIPTS / "vscripts" / reference).is_file():
                    failures.append(f"{label} references missing script {reference}")

        for reference, function in SCRIPT_CALLBACK.findall(contents):
            script = SCRIPTS / "vscripts" / reference
            if script.is_file():
                callbacks += 1
                if function not in LUA_FUNCTION.findall(read_source(script)):
                    failures.append(f"{label} calls missing Lua function {function} in {reference}")

    if failures:
        raise SystemExit("\n".join(failures))
    print(f"Checked {len(seen)} NPC KeyValues files, {script_references} Lua references, and {callbacks} callbacks")


if __name__ == "__main__":
    main()
