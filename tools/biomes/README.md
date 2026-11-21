# Arena biomes

Monster camps and biome bosses for Angel Arena. The **green** biome is the finished reference;
**desert**, **ice** and **lava** are registered but empty, waiting for you. You can build a biome
without touching any shared file: everything you create has your biome's name in its path.

## How it works

* **Camps.** The map has point entities named `arena_camp_<biome>_<tier>` (tier 1 easy, 2 medium,
  3 hard, 4 elite). When a camp is empty, its respawn time has passed and no enemy hero stands
  within 700 units, it fills with one group picked from your biome's list for that tier. A camp
  never refills while one of its monsters lives. Monster stats grow with the match clock; abilities
  start at a level set by the tier and gain a level every 20 minutes.
  (`arena/core/camps.lua`, `arena/core/tiers.lua`)
* **Champions.** Now and then one monster in a fresh camp is a champion: bigger, a golden ring, a
  label over its health bar naming its gift (Mighty, Swift, Vampiric or Stoneskin), x2.5 health,
  and a guaranteed item from the next tier's pool. (`arena/core/champions.lua`)
* **The shared brain.** Every monster and boss runs `arena/core/monster_ai.lua`. It uses the
  monster's abilities by itself (read from each ability's KV behaviour), fights as a group when
  one member is hit, and walks home (faster, healing, ignoring everyone) when pulled past the
  tier's leash.
* **Bosses.** One per biome, at the map entity `arena_boss_<biome>`. It is announced a minute
  early, appears at `first_spawn`, fights in phases (each phase announced, enrages it, unlocks and
  levels its abilities), resets if dragged out of its lair, pays every hero of the killing team,
  drops items, and returns stronger after `respawn` seconds. (`arena/core/bosses.lua`)
* **Unfinished biomes are harmless.** A biome with no `monsters.lua` borrows the wilds monsters for
  its camps; no `boss.lua` means no boss. A file that fails to load or validate is switched off
  and reported in the console (`[Arena] ... switched off: ...`); the rest of the game keeps going.

Until the new map exists, the old map's `creep_camp` markers are used as **wilds** camps (only when
the map has no `arena_camp_*` marker at all): a marker with `CreepType` 1 to 4 keeps that tier,
the rest are ranked by distance to the nearest fountain (or hero spawn point): nearest 30% easy,
then 30% medium, 25% hard, farthest 15% elite.

## Files for a new biome

Replace `ice` with your biome. Copy the green file named on the right and edit it.

| File | What it is | Start from |
| --- | --- | --- |
| `game/angel_arena/scripts/vscripts/arena/biomes/ice/monsters.lua` | Camp pool: stats of each monster, groups per tier, extra loot | `.../biomes/green/monsters.lua` |
| `game/angel_arena/scripts/vscripts/arena/biomes/ice/boss.lua` | The boss: timing, stats, phases, abilities, reward, sounds | `.../biomes/green/boss.lua` |
| `game/angel_arena/scripts/vscripts/arena/biomes/ice/fx.lua` | Every particle, sound event, sound file and extra model your scripts use | `.../biomes/green/fx.lua` |
| `game/angel_arena/scripts/vscripts/arena/biomes/ice/abilities.lua` | Lua for every ability and modifier | `.../biomes/green/abilities.lua` |
| `game/angel_arena/scripts/npc/units/arena/arena_ice_units.txt` | Unit definitions (already exists as an empty stub: fill it, do not delete it) | `.../arena/arena_green_units.txt` |
| `game/angel_arena/scripts/npc/abilities/arena/arena_ice_abilities.txt` | Ability definitions (also an existing stub) | `.../arena/arena_green_abilities.txt` |
| `tools/biomes/tooltips/ice.txt` | Names, tooltips and boss announcements | `tools/biomes/tooltips/green.txt` |

The localization files are generated: never edit them by hand, run the build (below).

Already done for every biome, so you do not need to touch these: the biome list
(`ArenaBiomes.NAMES` in `arena/core/biomes.lua`), the `#base` lines in `npc_units_custom.txt` and
`npc_abilities_custom.txt`, precaching (every unit in your `monsters.lua` and `boss.lua` plus
everything in your `fx.lua` is precached automatically) and loading (the game loads your Lua files
by their paths). If you think a shared file (`arena/core/*`, anything outside your biome's paths)
needs a change, ask instead of editing it: three people are working in parallel.

## Naming

* Units: `npc_arena_ice_<name>`. Abilities: `arena_ice_<name>`. Modifiers: `modifier_arena_ice_<name>`.
* The Lua class of an ability is its KV name: `arena_ice_frost_bolt = class({})`.
* Every ability's `"ScriptFile"` is exactly `"arena/biomes/ice/abilities.lua"`.
* Tooltip tokens in `ice.txt` must start with `npc_arena_ice_`, `DOTA_Tooltip_ability_arena_ice_`,
  `DOTA_Tooltip_modifier_arena_ice_` or `arena_ice_`.

## Step by step

1. **Units** (`arena_ice_units.txt`). `BaseClass` `npc_dota_creature`, `TeamName`
   `DOTA_TEAM_NEUTRALS`, a Dota model, and `Ability1`... for its abilities. Health, damage, armor
   and bounty here are only defaults: the numbers in `monsters.lua` win. Give the boss `"AbilityN"`
   entries for every ability `boss.lua` lists.
2. **Abilities** (`arena_ice_abilities.txt` + `abilities.lua`). `BaseClass` `ability_lua`.
   Camp monster abilities have `"MaxLevel" "4"` (values for four levels). Boss abilities have
   `"MaxLevel"` equal to the number of boss phases: the level is the phase, so the level-2 values
   are the phase-2 version of the move. Read numbers with `self:GetSpecialValueFor(...)`.
3. **Monsters** (`monsters.lua`). Stats at minute 0 for each unit, then for tiers 1 to 4 a list of
   groups. In a group put the leader first and minions after: late in the match the camp gets one
   more copy of the **last** monster. Tougher tiers should differ in more than health: more
   monsters, abilities, ranged and melee mixes. `loot` adds items to a tier's drop pool:
   `[1]` to `[4]` are the camp tiers, and `[5]` is the pool beyond elite, which elite champions
   drop from (and which bosses draw on together with their own `reward.loot`).
4. **Boss** (`boss.lua`). `phases` are health fractions (first 1.0, then decreasing). List
   abilities in priority order with the first phase that uses them: the brain tries them in this
   order, whatever their slots in the unit file. Use `lock` on telegraphed moves so the boss does
   not stack two warnings at once. Units the boss fights beside go in `summons` (they need stats in
   `monsters.lua`, see Summons below); units an ability creates itself and only needs precached
   (a pillar, a wall, a dummy) go in `extra_units`, which needs no stats.
   Size the kit to the ground at the boss marker: a ring or wave that reaches past the clearing
   asks players to dodge into cliffs or lava. On the new map the boss markers are ice
   (-5888, 6656) on the high plateau, green (256, 6272), desert (3712, 6528) and lava (2048, -2944);
   the lava boss's clearing is only about 640 units in radius, with lava pools and columns beyond,
   on a plain of roughly 3500 x 1800.
5. **Effects** (`fx.lua`). Put every particle and sound your scripts use here and read them from
   `FX.particles.x` / `FX.sounds.x` in `abilities.lua`, so they are precached and checked.
6. **Tooltips** (`tools/biomes/tooltips/ice.txt`): a name for every unit; name and
   `_Description` for every ability (`%value%` is an AbilityValues entry, `%value%%%` adds a %);
   a name and `_Description` for every visible modifier (`%dMODIFIER_PROPERTY_...%` shows the
   modifier's own number); and the boss announcements `arena_ice_boss_soon`, `_awakens`,
   `_phase_2` (one per phase after the first) and `_slain` (shown after the team name, so it
   starts with a space).
7. Run the build and the checks below until they are clean.

### The AI hints

Most abilities need none. The brain decides from the KV behaviour: unit target on enemies is cast
at the target, unit target on allies at a wounded ally, point target at the target's position, no
target when the target is within the ability's `"radius"` value. When that is wrong, add a hint
in `monsters.lua` (`ai = { arena_ice_x = { ... } }`) or on the boss ability entry:

| Hint | Meaning |
| --- | --- |
| `target = "enemy" / "ally" / "point" / "self"` | override how it is cast |
| `radius = 400` | for `self`: cast when the target is this close |
| `range = 700`, `min_range = 300` | for `enemy` / `point`: only between these distances |
| `health_below = 0.6` | only while the caster is below 60% health |
| `ally_health_below = 0.5` | for `ally`: how hurt the ally must be (default 0.7) |
| `lock = 1.5` | after casting, wait this long before casting anything else |

Passive and toggle abilities are never cast by the brain. A camp monster tries its abilities in
unit KV slot order (`Ability1` first); a boss in the order of its `abilities` list in `boss.lua`.

### Writing abilities that load on the client

The Dota client loads a modifier's script on its own the first time it sees the modifier, without
whatever loaded it on the server. So `abilities.lua` must:

* `require` everything it uses at the top (`arena/core/fx`, `arena/core/modifiers`, your `fx`);
* touch nothing that only exists on the server (`Timers`, `Gold`, `GameMode`, `ArenaBosses`...)
  outside `IsServer()` checks or server-only callbacks such as `OnSpellStart`;
* link its modifiers to itself: `LinkLuaModifier(name, "arena/biomes/ice/abilities.lua", LUA_MODIFIER_MOTION_NONE)`.

`tests/arena_biomes.lua` loads every biome's `abilities.lua` this way (with no server globals) and
calls what the client calls on each modifier, so a mistake here fails the test, not the game. It
also requires a tooltip for every modifier whose `IsHidden()` is false.

To test your own abilities' behaviour, add `tests/arena_ice.lua` (it runs with the other
`tests/*.lua`); the green sections of `tests/arena_biomes.lua` show how to drive an ability
against the stubbed engine.

### Telegraphs

Dangerous moves must be dodgeable, and players must be able to see them coming:

* **During a cast point**: draw a ring in `OnAbilityPhaseStart` with
  `ArenaFxCore.Circle(position, radius, self:GetCastPoint())` and remove it with
  `ArenaFxCore.Stop(...)` in `OnAbilityPhaseInterrupted` and `OnSpellStart` (Bramble Slam).
* **Delayed hit somewhere else**: create the shared thinker
  `CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", { duration = delay, shape = "circle", radius = r }, point, caster:GetTeamNumber(), false)`
  (or `shape = "line", x2 = ..., y2 = ..., width = w` for a line; the line is drawn with both edges
  of its width). When the warning runs out your ability's `OnArenaStrike(position, data)` runs; it
  does nothing if the caster died meanwhile, and a boss that resets (dragged out of its lair)
  removes its strikes still on the ground. (Root Eruption, Falling Timber.) Lasting ground effects
  your ability makes with its own thinkers (burning ground, clouds) are not removed by a reset:
  keep them short, or remove them in your own code.
* **Channelled**: draw the ring in `OnSpellStart`, resolve in `OnChannelFinish(interrupted)`; a stun
  cancels it (Thorn Nova).
* **Summons**: `ArenaBosses.Summon(caster, "npc_arena_ice_x", position, duration)`; the unit needs
  stats in `monsters.lua` and must be listed in the boss's `summons`.
* **Shared modifiers on the client**: `addon_init.lua` requires `arena/core/modifiers` on the server
  and every client before the game mode loads, so the camp, champion and boss modifiers exist
  everywhere. Biome modifiers are linked when the client loads your `abilities.lua`; a modifier you
  put on units with no ability behind it would need the same early require, so ask first.

## Checking your work

From the repository root:

```bash
python tools/biomes/build_biomes.py            # merge tooltips into both localization files
python tools/biomes/build_biomes.py --check    # what the tests run: up to date and no problems
lua5.1 tests/arena_biomes.lua                  # camps, AI, bosses, scripts, client loading
python tests/arena_biomes.py                   # cross-file checks (+ the asset check below)
python tools/biomes/check_assets.py ice        # every model, particle, sound and icon exists in Dota
python tests/npc_references.py                 # KV includes and ScriptFiles resolve
```

The build refuses to write while any biome has a problem and prints each one, for example
`ice: unit npc_arena_ice_yeti uses arena_ice_frost_bolt, which is not in .../arena_ice_abilities.txt`.

`check_assets.py` reads Dota's `pak01_dir.vpk` (default
`D:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota`; set `DOTA_GAME_DIR` or pass
`--dota`). It checks models, particles, sound files, sound event names, ability icons and loot items.
To look for assets yourself, list the archive with a tight regex (compiled names end in `_c`):

```bash
python "C:/Users/user/AppData/Local/Temp/claude/aa_vpk/vpk.py" list "^models/creeps/neutral_creeps/n_creep_ice"
```

## Testing in game

In a lobby with cheats (`sv_cheats 1`):

* `arena_camps` prints every camp: tier, monsters alive, respawn countdown, blocked by heroes.
* `arena_boss_spawn ice` brings the ice boss in now.
* Watch for `[Arena]` lines in the console: they report switched-off files, missing boss markers
  and biomes borrowing the wilds pool.

Things only the game can show: that a model looks right at its scale, that particles sit where
expected (control points differ between effects), that sounds play, and that the numbers feel fair.
