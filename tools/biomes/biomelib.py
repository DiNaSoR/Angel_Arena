"""Shared helpers for the biome tools and tests: paths, a KeyValues reader, the biome list,
the tooltip fragments and the cross-file checks every biome must pass.

Used by tools/biomes/build_biomes.py, tools/biomes/check_assets.py and tests/arena_biomes.py.
"""
import json
import re
import shutil
import subprocess
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
GAME = REPO / "game" / "angel_arena"
SCRIPTS = GAME / "scripts"
NPC = SCRIPTS / "npc"
VSCRIPTS = SCRIPTS / "vscripts"
TOOLS = REPO / "tools" / "biomes"
TOOLTIPS = TOOLS / "tooltips"
LOC_PATHS = [(GAME / "resource" / "addon_english.txt", "utf-16"),
             (REPO / "content" / "angel_arena" / "addon_english_utf8.txt", "utf-8-sig")]
BIOMES_LUA = VSCRIPTS / "arena" / "core" / "biomes.lua"
SHARED = "shared"


def biome_names():
    """The biome list, read from ArenaBiomes.NAMES so Lua stays the one place it is written."""
    text = BIOMES_LUA.read_text(encoding="utf-8")
    match = re.search(r"ArenaBiomes\.NAMES\s*=\s*\{([^}]*)\}", text)
    assert match, "ArenaBiomes.NAMES not found in " + str(BIOMES_LUA)
    return re.findall(r'"([a-z]+)"', match.group(1))


def files(biome):
    """Every file a biome owns. Only `wilds` may skip the KV files (it uses Dota's own units)."""
    return {
        "monsters": VSCRIPTS / "arena" / "biomes" / biome / "monsters.lua",
        "boss": VSCRIPTS / "arena" / "biomes" / biome / "boss.lua",
        "fx": VSCRIPTS / "arena" / "biomes" / biome / "fx.lua",
        "abilities": VSCRIPTS / "arena" / "biomes" / biome / "abilities.lua",
        "units_kv": NPC / "units" / "arena" / ("arena_%s_units.txt" % biome),
        "abilities_kv": NPC / "abilities" / "arena" / ("arena_%s_abilities.txt" % biome),
        "tooltips": TOOLTIPS / ("%s.txt" % biome),
    }


def read_text(path):
    data = Path(path).read_bytes()
    if data.startswith((b"\xff\xfe", b"\xfe\xff")):
        return data.decode("utf-16")
    return data.decode("utf-8-sig")


# ----------------------------------------------------------------------------- KeyValues

_TOKEN = re.compile(r'\s*(?://[^\n]*\n?|"((?:[^"\\]|\\.)*)"|([{}])|#base[^\n]*\n?|([^\s{}"]+))', re.S)


def parse_kv(text):
    """Reads KeyValues text into (root name, [(key, value), ...]); a value is a string or a
    nested list of pairs. Repeated keys are kept in order."""
    tokens = []
    position = 0
    while position < len(text):
        match = _TOKEN.match(text, position)
        if not match or match.end() == position:
            if text[position:].strip() == "":
                break
            raise ValueError("cannot read KeyValues near: %r" % text[position:position + 40])
        position = match.end()
        quoted, brace, bare = match.groups()
        if quoted is not None:
            tokens.append(("s", quoted))
        elif brace:
            tokens.append(("b", brace))
        elif bare:
            tokens.append(("s", bare))
    index = 0

    def block():
        nonlocal index
        pairs = []
        while index < len(tokens):
            kind, value = tokens[index]
            index += 1
            if kind == "b" and value == "}":
                return pairs
            if kind != "s":
                raise ValueError("unexpected brace in KeyValues")
            if index >= len(tokens):
                raise ValueError("key %s has no value" % value)
            next_kind, next_value = tokens[index]
            index += 1
            if next_kind == "b" and next_value == "{":
                pairs.append((value, block()))
            elif next_kind == "s":
                pairs.append((value, next_value))
            else:
                raise ValueError("unexpected } after key %s" % value)
        return pairs

    if not tokens:
        return None, []
    root = tokens[0][1]
    if len(tokens) < 2 or tokens[1] != ("b", "{"):
        raise ValueError("KeyValues root must be followed by {")
    index = 2
    return root, block()


def first(pairs, key, default=None):
    for name, value in pairs:
        if name == key:
            return value
    return default


def every(pairs, key):
    return [value for name, value in pairs if name == key]


def kv_blocks(path):
    """The top-level definitions of a KV file as {name: pairs}, with duplicates reported."""
    if not Path(path).is_file():
        return {}, ["missing file " + rel(path)]
    try:
        _, pairs = parse_kv(read_text(path))
    except ValueError as error:
        return {}, ["%s: %s" % (rel(path), error)]
    blocks, problems = {}, []
    for name, value in pairs:
        if name in blocks:
            problems.append("%s defines %s twice" % (rel(path), name))
        if isinstance(value, list):
            blocks[name] = value
    return blocks, problems


def rel(path):
    try:
        return str(Path(path).resolve().relative_to(REPO)).replace("\\", "/")
    except ValueError:
        return str(path)


def included_files(root):
    """Every file a KV root pulls in with #base, recursively, root first."""
    seen, pending = [], [Path(root)]
    while pending:
        path = pending.pop(0)
        if path in seen or not path.is_file():
            continue
        seen.append(path)
        for include in re.findall(r'^[ \t]*#base[ \t]+"([^"]+)"', read_text(path), re.M):
            pending.append(path.parent / include)
    return seen


def custom_item_names():
    names = set()
    for path in included_files(NPC / "npc_items_custom.txt"):
        names.update(re.findall(r'^\s*"(item_[A-Za-z0-9_]+)"\s*$', read_text(path), re.M))
    return names


def shared_loot():
    """Item names in the shared loot pools (ArenaRewards.LOOT in arena/core/rewards.lua)."""
    text = (VSCRIPTS / "arena" / "core" / "rewards.lua").read_text(encoding="utf-8")
    match = re.search(r"ArenaRewards\.LOOT\s*=\s*\{(.*?)\n\}", text, re.S)
    assert match, "ArenaRewards.LOOT not found"
    return re.findall(r'"(item_[A-Za-z0-9_]+)"', match.group(1))


# ------------------------------------------------------------------------------- Lua data

def lua_command():
    for name in ("lua5.1", "lua"):
        found = shutil.which(name)
        if found:
            return found
    raise SystemExit("Lua 5.1 is needed (lua5.1 or lua on PATH)")


def load_lua(biome):
    """The biome's monsters.lua, boss.lua and fx.lua as plain data, through tools/biomes/dump_biome.lua."""
    run = subprocess.run([lua_command(), str(TOOLS / "dump_biome.lua"), biome], cwd=REPO,
                         capture_output=True, text=True)
    if run.returncode != 0:
        return {"errors": {"lua": run.stderr.strip() or run.stdout.strip()}}
    return json.loads(run.stdout)


def tiers_of(monsters):
    """monsters.tiers as {tier: [group, ...]} whatever shape the JSON took."""
    tiers = monsters.get("tiers") or {}
    if isinstance(tiers, list):
        return {index + 1: groups or [] for index, groups in enumerate(tiers)}
    return {int(key): (groups or []) for key, groups in tiers.items()}


def as_list(value):
    if isinstance(value, dict):
        return [value[key] for key in sorted(value, key=lambda k: int(k) if str(k).isdigit() else k)]
    return value or []


# ------------------------------------------------------------------------------- tooltips

_FRAGMENT_LINE = re.compile(r'^\s*"([^"]+)"\s+"((?:[^"\\]|\\.)*)"\s*(?://.*)?$')


def read_fragment(path):
    """[(token, text, line)] from a tooltip fragment, plus format problems."""
    entries, problems = [], []
    if not Path(path).is_file():
        return entries, problems
    for number, line in enumerate(read_text(path).splitlines(), 1):
        stripped = line.strip()
        if not stripped or stripped.startswith("//"):
            continue
        match = _FRAGMENT_LINE.match(line)
        if not match:
            problems.append('%s:%d: expected "token"  "text"' % (rel(path), number))
            continue
        entries.append((match.group(1), match.group(2), number))
    return entries, problems


def allowed_prefixes(biome):
    return ("npc_arena_%s_" % biome, "DOTA_Tooltip_ability_arena_%s_" % biome,
            "DOTA_Tooltip_modifier_arena_%s_" % biome, "arena_%s_" % biome)


def all_tokens():
    """Every fragment's tokens in build order (shared, then the biomes), with problems."""
    order = [SHARED] + biome_names()
    tokens, problems, seen = [], [], {}
    for name in order:
        path = TOOLTIPS / ("%s.txt" % name)
        entries, fragment_problems = read_fragment(path)
        problems += fragment_problems
        for token, text, line in entries:
            where = "%s:%d" % (rel(path), line)
            if name != SHARED and not token.startswith(allowed_prefixes(name)):
                problems.append("%s: %s must start with one of %s" % (where, token, ", ".join(allowed_prefixes(name))))
            if name == SHARED and not token.startswith(("DOTA_Tooltip_modifier_arena_", "arena_")):
                problems.append("%s: shared tokens are for arena modifiers and announcements" % where)
            if token in seen:
                problems.append("%s: %s is already defined at %s" % (where, token, seen[token]))
                continue
            seen[token] = where
            tokens.append((token, text))
    return tokens, problems


# ------------------------------------------------------------------------- static checks

def ability_values(pairs):
    values = first(pairs, "AbilityValues", []) or []
    return {key for key, _ in values} if isinstance(values, list) else set()


def biome_problems(biome, tokens=None, stock_items=None):
    """Cross-file checks for one biome. `tokens` is {token: text} from all fragments."""
    if tokens is None:
        tokens = dict(all_tokens()[0])
    paths = files(biome)
    problems = []
    data = load_lua(biome)
    for part, message in (data.get("errors") or {}).items():
        problems.append("%s.lua does not load: %s" % (part, message))
    monsters = data.get("monsters")
    boss = data.get("boss")

    themed = biome != "wilds"
    units, unit_problems = kv_blocks(paths["units_kv"]) if themed else ({}, [])
    abilities, ability_problems = kv_blocks(paths["abilities_kv"]) if themed else ({}, [])
    problems += unit_problems + ability_problems
    script = paths["abilities"]
    script_text = script.read_text(encoding="utf-8") if script.is_file() else ""

    for name, pairs in units.items():
        if not name.startswith("npc_arena_%s_" % biome):
            problems.append("unit %s must be named npc_arena_%s_<name>" % (name, biome))
        if first(pairs, "BaseClass") != "npc_dota_creature":
            problems.append("unit %s: BaseClass must be npc_dota_creature" % name)
        if first(pairs, "TeamName") != "DOTA_TEAM_NEUTRALS":
            problems.append("unit %s: TeamName must be DOTA_TEAM_NEUTRALS" % name)
        if not first(pairs, "Model"):
            problems.append("unit %s has no Model" % name)
        for key, ability in pairs:
            if re.match(r"Ability\d+$", key) and ability and ability not in abilities:
                problems.append("unit %s uses %s, which is not in %s" % (name, ability, rel(paths["abilities_kv"])))
        if name not in tokens:
            problems.append("unit %s has no name tooltip (\"%s\" in tools/biomes/tooltips/%s.txt)" % (name, name, biome))

    used = {ability for pairs in units.values() for key, ability in pairs if re.match(r"Ability\d+$", key)}
    for name, pairs in abilities.items():
        if not name.startswith("arena_%s_" % biome):
            problems.append("ability %s must be named arena_%s_<name>" % (name, biome))
        if name not in used:
            problems.append("ability %s is not given to any unit" % name)
        if first(pairs, "BaseClass") == "ability_lua":
            expected = "arena/biomes/%s/abilities.lua" % biome
            if first(pairs, "ScriptFile") != expected:
                problems.append("ability %s: ScriptFile must be %s" % (name, expected))
            elif not re.search(r"^%s\s*=\s*class\(" % re.escape(name), script_text, re.M):
                problems.append("ability %s: %s does not define %s = class({})" % (name, expected, name))
        values = ability_values(pairs)
        for suffix in ("", "_Description"):
            if "DOTA_Tooltip_ability_" + name + suffix not in tokens:
                problems.append("ability %s has no DOTA_Tooltip_ability_%s%s tooltip" % (name, name, suffix))
        for placeholder in re.findall(r"%([a-z_]+)%", tokens.get("DOTA_Tooltip_ability_%s_Description" % name, "")):
            if placeholder not in values:
                problems.append("ability %s tooltip uses %%%s%%, which is not one of its AbilityValues" % (name, placeholder))
        for token in tokens:
            prefix = "DOTA_Tooltip_ability_%s_" % name
            if token.startswith(prefix):
                key = token[len(prefix):]
                if key not in ("Description", "Lore", "Note0", "Note1") and key not in values \
                        and not any(other != name and token.startswith("DOTA_Tooltip_ability_%s_" % other) for other in abilities):
                    problems.append("tooltip %s labels a value %s that %s does not have" % (token, key, name))

    if monsters:
        for unit, stats in (monsters.get("monsters") or {}).items():
            if themed and unit not in units:
                problems.append("monster %s is in monsters.lua but not in %s" % (unit, rel(paths["units_kv"])))
            hints = stats.get("ai") or {}
            for ability in hints:
                if themed and ability not in abilities:
                    problems.append("monster %s: ai names %s, which is not a %s ability" % (unit, ability, biome))
                elif themed and unit in units and ability not in [v for k, v in units[unit] if re.match(r"Ability\d+$", k)]:
                    problems.append("monster %s: ai names %s, which the unit does not have" % (unit, ability))
        known_items = custom_item_names()
        loot = monsters.get("loot") or {}
        for items in (loot.values() if isinstance(loot, dict) else loot):
            for item in items or []:
                if item not in known_items and (stock_items is None or item not in stock_items) \
                        and (item.startswith("item_arena_") or stock_items is not None):
                    problems.append("loot item %s does not exist" % item)

    if boss:
        unit = boss.get("unit")
        if unit not in units:
            problems.append("boss unit %s is not in %s" % (unit, rel(paths["units_kv"])))
        else:
            has = [v for k, v in units[unit] if re.match(r"Ability\d+$", k)]
            for spec in as_list(boss.get("abilities")):
                if spec.get("name") not in has:
                    problems.append("boss ability %s is not on %s in the unit file" % (spec.get("name"), unit))
                elif first(abilities.get(spec["name"], []), "MaxLevel") not in (None, str(len(as_list(boss.get("phases"))))):
                    problems.append("boss ability %s: MaxLevel must equal the number of phases (%d)"
                                    % (spec["name"], len(as_list(boss.get("phases")))))
        for summon in as_list(boss.get("summons")):
            if summon not in units:
                problems.append("boss summon %s is not in %s" % (summon, rel(paths["units_kv"])))
            elif summon not in ((monsters or {}).get("monsters") or {}):
                problems.append("boss summon %s needs stats in monsters.lua" % summon)
        phases = len(as_list(boss.get("phases")))
        wanted = ["soon", "awakens", "slain"] + ["phase_%d" % n for n in range(2, phases + 1)]
        for key in wanted:
            if "arena_%s_boss_%s" % (biome, key) not in tokens:
                problems.append("boss announcement arena_%s_boss_%s has no tooltip" % (biome, key))
        known_items = custom_item_names()
        for item in as_list((boss.get("reward") or {}).get("loot")):
            if item not in known_items and (stock_items is None or item not in stock_items) \
                    and (item.startswith("item_arena_") or stock_items is not None):
                problems.append("boss loot item %s does not exist" % item)

    # Visible modifiers need tooltips too; tests/arena_biomes.lua checks those, as it can ask IsHidden().
    for path in (paths["units_kv"], paths["abilities_kv"]):
        if themed and not path.is_file():
            problems.append("missing %s (keep the empty stub until the biome has units)" % rel(path))
    return problems
