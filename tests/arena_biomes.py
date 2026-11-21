"""Static checks for the arena biomes: generated tooltips are current, every biome's files agree
with each other, and the checker itself catches a broken biome. Also checks Dota's archive for
every asset when a Dota install is found (skipped otherwise).

Run from the repository root: python tests/arena_biomes.py
"""
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True  # no __pycache__ beside the tools
sys.path.insert(0, str(REPO / "tools" / "biomes"))
import biomelib  # noqa: E402


def check_generated():
    run = subprocess.run([sys.executable, REPO / "tools" / "biomes" / "build_biomes.py", "--check"],
                         capture_output=True, text=True)
    assert run.returncode == 0, run.stdout + run.stderr


def check_shipped_biomes():
    names = biomelib.biome_names()
    assert names == ["wilds", "green", "desert", "ice", "lava"], names
    tokens = dict(biomelib.all_tokens()[0])
    for biome in names:
        problems = biomelib.biome_problems(biome, tokens)
        assert not problems, "%s:\n  %s" % (biome, "\n  ".join(problems))
    # Every themed biome has its KV stubs included from the shared roots, and nothing else does.
    for root, kind in (("npc_units_custom.txt", "units"), ("npc_abilities_custom.txt", "abilities")):
        included = [path.name for path in biomelib.included_files(biomelib.NPC / root)]
        for biome in names[1:]:
            assert "arena_%s_%s.txt" % (biome, kind) in included, (root, biome)
    # The green reference biome is complete: four tiers, abilities on the tougher monsters, a boss.
    green = biomelib.load_lua("green")
    tiers = biomelib.tiers_of(green["monsters"])
    assert sorted(tiers) == [1, 2, 3, 4] and all(tiers[tier] for tier in tiers)
    units, _ = biomelib.kv_blocks(biomelib.files("green")["units_kv"])
    for tier in (2, 3, 4):
        for group in tiers[tier]:
            for unit in group:
                assert any(key.startswith("Ability") and value for key, value in units[unit]) or tier == 2, unit
    for tier in (3, 4):
        for group in tiers[tier]:
            leader = group[0]
            assert any(key.startswith("Ability") and value for key, value in units[leader]), leader + " needs an ability"
    assert green["boss"]["unit"] in units and len(green["boss"]["phases"]) >= 2


def check_checker_catches_mistakes():
    """A deliberately broken biome must produce a problem for each mistake."""
    original_files, original_load, original_tooltips = biomelib.files, biomelib.load_lua, biomelib.TOOLTIPS
    with tempfile.TemporaryDirectory() as folder:
        folder = Path(folder)
        (folder / "units.txt").write_text('''"DOTAUnits"
{
    "npc_arena_test_ok"     { "BaseClass" "npc_dota_creature" "Model" "models/x.vmdl" "TeamName" "DOTA_TEAM_NEUTRALS" "Ability1" "arena_test_missing" }
    "npc_wrong_name"        { "BaseClass" "npc_dota_creature" "Model" "models/x.vmdl" "TeamName" "DOTA_TEAM_NEUTRALS" }
    "npc_arena_test_boss"   { "BaseClass" "npc_dota_creature" "Model" "models/x.vmdl" "TeamName" "DOTA_TEAM_NEUTRALS" "Ability1" "arena_test_smash" }
}''', encoding="utf-8")
        (folder / "abilities.txt").write_text('''"DOTAAbilities"
{
    "arena_test_smash" { "BaseClass" "ability_lua" "ScriptFile" "arena/biomes/test/abilities.lua" "MaxLevel" "4"
        "AbilityValues" { "damage" "10" } }
    "arena_test_orphan" { "BaseClass" "ability_lua" "ScriptFile" "somewhere/else.lua" }
}''', encoding="utf-8")
        (folder / "abilities.lua").write_text("arena_test_other = class({})\n", encoding="utf-8")
        tips = folder / "tips"
        tips.mkdir()
        (tips / "shared.txt").write_text("", encoding="utf-8")
        (tips / "test.txt").write_text('''"npc_arena_test_ok"  "Okay"
"DOTA_Tooltip_ability_arena_test_smash"  "Smash"
"DOTA_Tooltip_ability_arena_test_smash_Description"  "Hits for %damage% and %missing%."
"DOTA_Tooltip_ability_arena_test_smash_speed"  "SPEED:"
"npc_arena_green_sproutling"  "Not my unit"
this line is not a token
''', encoding="utf-8")

        def fake_files(biome):
            paths = original_files(biome)
            if biome == "test":
                paths.update(units_kv=folder / "units.txt", abilities_kv=folder / "abilities.txt",
                             abilities=folder / "abilities.lua", tooltips=tips / "test.txt")
            return paths

        def fake_load(biome):
            if biome != "test":
                return original_load(biome)
            return {"errors": {"fx": "fx.lua:3: unexpected symbol"},
                    "monsters": {"biome": "test", "monsters": {"npc_arena_test_ghost": {"health": 1, "damage": 1, "armor": 0,
                                                                                        "gold": 1, "xp": 1, "ai": {"arena_test_nope": {}}}},
                                 "tiers": [[["npc_arena_test_ghost"]]], "loot": {"1": ["item_arena_does_not_exist"]}},
                    "boss": {"unit": "npc_arena_test_boss", "phases": [{"health": 1}, {"health": 0.5}],
                             "abilities": [{"name": "arena_test_smash", "phase": 1}, {"name": "arena_test_absent", "phase": 2}],
                             "summons": ["npc_arena_test_nobody"], "reward": {"gold": 1, "xp": 1, "loot": []}}}

        biomelib.files, biomelib.load_lua, biomelib.TOOLTIPS = fake_files, fake_load, tips
        original_names = biomelib.biome_names
        biomelib.biome_names = lambda: ["test"]
        try:
            tokens, token_problems = biomelib.all_tokens()
            problems = biomelib.biome_problems("test", dict(tokens))
        finally:
            biomelib.files, biomelib.load_lua, biomelib.TOOLTIPS = original_files, original_load, original_tooltips
            biomelib.biome_names = original_names

    text = "\n".join(problems + token_problems)
    expected = [
        "fx.lua does not load",
        "unit npc_wrong_name must be named npc_arena_test_<name>",
        "unit npc_arena_test_ok uses arena_test_missing",
        "unit npc_wrong_name has no name tooltip",
        "ability arena_test_orphan is not given to any unit",
        "ability arena_test_orphan: ScriptFile must be arena/biomes/test/abilities.lua",
        "does not define arena_test_smash = class({})",
        "uses %missing%, which is not one of its AbilityValues",
        "labels a value speed",
        "monster npc_arena_test_ghost is in monsters.lua but not in",
        "ai names arena_test_nope",
        "loot item item_arena_does_not_exist does not exist",
        "boss ability arena_test_absent is not on npc_arena_test_boss",
        "MaxLevel must equal the number of phases (2)",
        "boss summon npc_arena_test_nobody",
        "arena_test_boss_soon has no tooltip",
        "arena_test_boss_phase_2 has no tooltip",
        "npc_arena_green_sproutling must start with one of",
        'expected "token"  "text"',
    ]
    for fragment in expected:
        assert fragment in text, "the checker missed: %s\n--- it reported:\n%s" % (fragment, text)


def check_assets_when_available():
    run = subprocess.run([sys.executable, REPO / "tools" / "biomes" / "check_assets.py"], capture_output=True, text=True)
    if run.returncode == 2:
        print("skipped the Dota asset check: " + run.stdout.strip())
        return
    assert run.returncode == 0, run.stdout + run.stderr
    print(run.stdout.strip().splitlines()[-1])


def main():
    check_generated()
    check_shipped_biomes()
    check_checker_catches_mistakes()
    check_assets_when_available()
    print("Checked the arena biomes: tooltips, cross-file references, the green reference biome and the checker itself")


if __name__ == "__main__":
    main()
