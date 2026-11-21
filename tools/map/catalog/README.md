# Angel Arena theme asset catalogue

A list of Dota 2 assets that ship with the game and can be placed in the map or used as monster
models, grouped for the four new regions (ice, desert, lava, green) plus `common.json` for the
team bases, the central arena, roads, graveyards, treasure, banners, statues, bridges, fences
and lights.

Every `path` in the five JSON files exists in Dota's `pak01_dir.vpk` (as `path` + `_c`).
`verify_catalog.py` checks this again:

```
python tools/map/catalog/verify_catalog.py            # uses the Steam path on this PC
python tools/map/catalog/verify_catalog.py <pak01_dir.vpk>
```

It exits 0 when every path exists and the entries are well formed, and 1 with a list of
offenders otherwise. Last run: `OK: all 1004 catalogue paths exist in pak01_dir.vpk`.

## File format

Each file is one object with the keys `trees`, `rocks`, `structures`, `clutter`, `lights`,
`water_lava`, `ambient_particles`, `creatures`, `sounds`. Each value is a list of
`{"path", "note", "size", "size_verified"}`. The first five entries of each list are the
recommended picks. Model paths are written the way `.vmap` files and unit KV files use them
(`models/...vmdl` or `maps/<terrain>_assets/...vmdl`). `ambient_particles` entries are
`.vpcf` paths for `info_particle_system` (Valve's tilesets use `dota_world_particle_system`
for the same thing).

| file | trees | rocks | structures | clutter | lights | water_lava | ambient_particles | creatures | sounds |
|---|---|---|---|---|---|---|---|---|---|
| ice | 27 | 33 | 24 | 37 | 14 | 8 | 27 | 29 | 0 |
| desert | 28 | 28 | 43 | 33 | 12 | 6 | 18 | 25 | 0 |
| lava | 25 | 30 | 36 | 30 | 14 | 4 | 28 | 30 | 0 |
| green | 32 | 24 | 33 | 41 | 14 | 18 | 27 | 33 | 0 |
| common | 10 | 8 | 70 | 46 | 18 | 6 | 18 | 17 | 0 |

## How it was built

1. Listed every compiled model (`.vmdl_c`), particle (`.vpcf_c`) and material in `pak01` with
   the VPK directory reader. There are 18,091 models under `models/` and 527 under `maps/`.
2. Checked the terrain map VPKs (`game/dota/maps/dota_desert.vpk`, `dota_winter.vpk`,
   `dota_jungle.vpk`, `dota_cavern.vpk`, `dota_reef.vpk`, `dota_journey.vpk`, `dota_ti10.vpk`,
   `dota_crownfall.vpk`, and others). They contain only baked world geometry
   (`maps/dota/worldnodes/...`) and entity lumps. Every prop those terrains use is in `pak01`,
   including the terrain-specific folders `maps/cavern_assets`, `maps/jungle_assets`,
   `maps/journey_assets`, `maps/reef_assets`, `maps/ti10_assets`, `maps/summer_assets` and
   `maps/crownfall_assets`. A custom game can load these like any other `pak01` asset.
3. Converted the 30 tileset maps in `content/dota/maps/tilesets/*.vmap` to text with
   `dmxconvert -oe keyvalues2`. From each one I pulled the tile-set groups, the tile property
   values, the model on every `ent_dota_tree`, and every `.vmdl`/`.vpcf` reference. A note that
   says "used in radiant_snow_basic" (or similar) comes from this data.
4. Chose entries by name and by Valve's own use of them, then wrote them out and ran the
   verifier until it passed.
5. For every `creatures` entry (134 models), extracted the compiled model and confirmed that it
   has an animation-group block (`AGRP`/`ANIM`/`ASEQ`). One earlier candidate,
   `n_creep_gnoll_spear`, had no animation data (probably a weapon or attachment model), so I
   replaced it with `n_creep_kobold_b`.

## What was and was not verified

Checked against the archive:
- Every path exists (`verify_catalog.py`).
- Every creature model contains animation data.
- "Used in <tileset>" notes match the converted tileset files.
- These terrain materials exist: `materials/blends/dire_lava`, `dire_lava_ice`,
  `dire_lava_green`, `mod_dire_lava_000`, `mod_riverbed_ice_000`, `snowstrips_blend_000`, the
  desert blends (`radiant_desert_000`, `dire_desert_000`, ...), and the ice variants
  `materials/models/effects/waterfall_00_ice` and `water_edges_00_ice`.

Not verified (inferred from names, or unknown):
- **Sizes.** All `size` values are estimates from the names. Every entry has
  `size_verified: false`, because reading bounds from compiled models was not cheap.
- **Appearance.** Nothing was looked at in Hammer or in game. That includes colours, skins (for
  example, which skin of `effects/waterfall_00` uses the ice material), and whether event assets
  render correctly outside their event.
- **Animation sequence names.** A model having animation data does not guarantee it has
  attack, run or death sequences that Dota's unit code will pick up. Monster Hunter, Crownfall
  "survivors", Frostivus and cavern "mushling" models come from events or minigames, so test
  their scale and sequences first.
- **Hero models.** These are bare bodies. The weapons, armour, wings and similar pieces are
  separate wearable models in the same folder (the notes say which). Without them some heroes
  look unfinished. Neutral creeps, Labyrinth creeps, Monster Hunter monsters and Roshan
  variants are complete models.
- **Particles.** I did not check which ones loop. Entries marked "debut scene", "background
  scene", "screen-space" or "gameplay" come from hero showcases, dashboard backgrounds, minigames
  or abilities. They may be one-shot, attached to the camera, or need control points. Prefer the
  "World", "Weather" and "Terrain ambience" entries.
- **Sounds.** None are listed. The compiled `soundevents/*.vsndevts_c` files are KV3 v5 with
  chunked LZ4 compression, and I could not decode the event names cheaply. Following the brief, I
  skipped them rather than guess.
- `n_creep_beast` exists and is animated, but I don't know which creature it is.

## Asset families that do not exist (or barely exist)

- **Aghanim's Labyrinth.** Only the ice-biome creeps (`models/creeps/ice_biome/*`) and one hut
  (`models/props/ice_biome/buildings/tuskhouse01`) remain. There is no `models/props_aghanim`,
  no Labyrinth tile kit, and no desert/lava/forest biome props.
- **Siltbreaker / "journey" desert.** Not present. `maps/journey_assets` is the New Bloom
  "Journey" terrain (Chinese-style walls, maples, armand pines, stone-forest pillars), not
  Siltbreaker.
- **Lava.** There is no lava-surface, lava-river or lava-fall mesh family. Valve's lava is a
  terrain material (`materials/blends/dire_lava*`) with particles on top (`dire_fx/dire_lava_*`,
  `addons_gameplay/pit_lava_*`). Lava models amount to four small FX meshes
  (`effects/ground_crack_molten`, `props_destruction/lava_flow_clump`, ...). There are no
  burnt-tree models either. The lava theme has to use Dire trees, Dire rocks and Dire
  architecture, tinted. This is the weakest theme.
- **Winter and desert terrains** have no `maps/*_assets` folder. Their tilesets use the generic
  `models/props_*` set plus `_snow` variants and `props_nature/desert/*`.
- **Nemestice, Dark Moon and Diretide** left little usable environment content: crystal lane
  creeps, a few dashboard/background models, `props_diretide/*` (5 props), and Dark Moon lamp
  particles.

## Themes

### Ice
Hero pieces:
- `props_bones/whale_skeleton` (a frozen whale grave)
- the snow-village set (`props_structures/snow_village_building_1/_2`, `snow_village_tower_1`)
- `props/ice_biome/buildings/tuskhouse01` and `props_frostivus/frostivus_ancient/frostivus_igloo` for a Tuskarr camp
- `props_frostivus/frostivus_ancient/frostivus_ancient_snow` as the boss-arena centrepiece
- `props_winter/ice_spike_*` and `props_structures/crystal00X_refract` for ice shards

Trees: `tree_pine_0X_heavysnow` and `tree_oak_snow_*`. Ground: the `cliff_wall00X_snow` walls
with `props_winter/snowdrift_*` and `props_nature/drift_snow*`. Weather: `rain_fx/snow` and
`winter_fx/weather_frostivus_snow`, plus `rain_fx/econ_weather_aurora` at night. The bestiary is
strong: Aghanim's Labyrinth ice biome (`ice_giant01` boss, `ogreseal`, frostbitten, tuskfolk,
undead tusk skeletons) plus Monster Hunter's Barioth.

Tilesets: **radiant_snow_basic** and **dire_snow_basic**.
- radiant_snow_basic trees: `tree_pine_01_heavysnow`, `tree_pine_02_heavysnow`,
  `tree_oak_snow_01/01b/02` (skins 7-11), `tree_bamboo_snow_01/02`, `dire_tree007` (skin 1),
  `tree_cine_00_low`, `tree_cine_02_low`. Extra tile type: `snow_drifts`.
- dire_snow_basic trees: `tree_oak_snow_01/01b/02`, `dire_tree004` and `dire_tree004b` with
  skin `0_snow`, `dire_tree007`, `dire_tree008`.

### Desert
Hero pieces:
- `props_structures/ancient_giant_skeleton` (giant bones)
- the stone-forest pillars `props/stoneforest/stoneforest01-04` (and `journey_stoneforest01-04`) as mesas/hoodoos
- `props_structures/obelisk001/001b`
- the temple set from the temple tilesets (`column_temple_dire_00-05`, `temple_statue001/002`, `ancient_wall_statue001`, `props/statues/priest/statue_priest`, `props_structures/midas_throne/midas_throne`, `ancient_caldron001`)
- `spring_ruins_main_l/_r` arches
- `ship_broken001` as a stranded wreck

Trees: palms (`palm_02e`, `palm_03a`, ...), `desert_cactus01-03` and `desert_baobab*`. Weather:
`rain_fx/econ_weather_sirocco*` (sandstorm), `rain_fx/desert_sand_drift`, and
`maps/summer_assets/particles/summer_terrain_heat` (heat shimmer). Monsters: Sand King (boss,
needs his wearables), Seregios, thunder lizards, centaurs, vultures, crocodilian lane creeps,
and Crownfall skeletons and golems.

Tilesets: **radiant_desert_basic** and **dire_desert_basic**, plus **radiant_temple** and
**dire_temple** for temple interiors.
- radiant_desert_basic trees: `palm_02b/02d/02e/03/03a`, `desert_cactus01-03`,
  `desert_baobab/02`, `tree_cine_02_low`. Extra tile types: `ruins`, `sand_drift`.
- dire_desert_basic trees: `desert_baobab/02/03`, `desert_cactus01`, `dire_tree004_tint`,
  `dire_tree007_tintable`. Extra tile types: `ruins`, `bones`, `fortifications`.
- Temple tilesets: trees `palm_02b/02d/03/03a` (dire_temple) and `temple_tree001`. Tile types:
  `doors`, `columns`, `thrones`, `pottery`, `wall`, `candles`.

### Lava
Hero pieces:
- `props_structures/bad_ancient002` (the Dire Ancient; its own pit particles `dire_fx/bad_ancient002_pit_lava_*` match it)
- `props_magic/bad_magic_tower001`
- `props_structures/dark_statue/dark_statue`
- `props_structures/dragon_statue001` / `statue_dragon00X`
- `props_bones/skull_dragon001`

Lava ground: paint `materials/blends/dire_lava` and dress it with `effects/ground_crack_molten`
plus the particles `dire_fx/dire_lava_gloops_*`, `addons_gameplay/pit_lava_glow/smoke/sparks` and
`rain_fx/econ_weather_ash`. Rocks: `badside_rocks00X`, `bad_crystals`, the TI10 Dire rocks and
the Dark Reef Dire cliffs. Trees: Dire trees, tinted dark. Monsters: Rathalos, Underlord, the
black dragon, Warlock's golem, forged spirits, the Dragon Knight dragon, Doom, the Terrorblade
demon, the Diretide Roshan, and the Dire rock-golem tower model (it is animated; sequences
unchecked).

Tilesets: no Valve tileset is lava-themed. **dire_basic** is the closest. Its trees are
`dire_tree004/004b/007/008` plus `tree_oak_01/01b/02`, and its extra tile type is `bat_swarm`.
**dire_temple** places `props_destruction/lava_flow_clump`. Dota's main map (not a tileset) is
where the Dire lava material lives.

### Green (lush forest / jungle)
Hero pieces:
- the kapok trees `maps/jungle_assets/trees/kapok/export/kapok_001-004` (huge)
- `jungle_pitcher_tree` and `jungle_flytrap01`
- the jungle temple kit (`jungle_temple_01`, `temple_entrance_01`, `temple_statue_01`, `temple_stair_column_serpent`, `temple_spout` with the `dynamic_water_temple_spout` particle)
- the serpent wall statues
- giant cavern mushrooms (`maps/cavern_assets/models/mushrooms/mushroom_cavern_01-03`) for a mushroom grove

Water: waterfall models with the riverflow/waterfall particles. Ambience: fireflies, butterflies
and swamp bugs. Monsters: the deepest pool in the game, including Rathian and Gore Magala
bosses, the jungle stalker, ancient frogs and froglets, forest trolls, satyrs, hellbears,
harpies, wolves, animated mushlings, Treant Protector, Lone Druid's bear, and Ursa.

Tilesets: **radiant_jungle_basic** and **dire_jungle_basic**, plus **radiant_cavern_basic** and
**dire_cavern_basic** for a mushroom/crystal grove.
- radiant_jungle_basic trees: `kapok_001-004`, `palm_02b/02e`, `journey_maple02`,
  `tree_cine_00_low`, `tree_cine_02_low`.
- dire_jungle_basic trees: `kapok_001-004`, `palm_02b/02e`.
- Cavern tilesets: `mushroom_cavern_01/02`, `mushroom_inkycap_01`, `spores_cavern_01/04`,
  `crystal03`, `crystal05`, `crystal_chunk002/004`, mixed with oaks, pines and bamboo on the
  Radiant side.
- **radiant_spring_basic** (`tree_oak_spring_01/01b/02`) and **radiant_summer_basic** suit
  gentler forest edges.

### Common (bases, arena, roads, graveyard, treasure)
- Central arena: the colosseum wall and column set (`props_stone/colosseum_wall/*`,
  `props_stone/column/colosseum_column*`).
- Bases: the Radiant/Dire fountains, shops, Ancients and walls.
- Graveyard: `gravestone001-007`, `graveyard_fence001-007`, `coffin001/002`, the
  `architecture/crypt` set, `props_structures/cathedral001`, and `props_diretide/gravehands`.
- Treasure: `props_gameplay/treasure_chest*`, `props_generic/chest_treasure_*`,
  `coins_tileable`, `morokai_treasure`.
- Lights: `torch001`, `roshan_torch`, `sconce_coloseum_000`, and the Crownfall brazier. Pair
  each with `world_environmental_fx/fire_torch` or `addons_gameplay/lamp_flame_tintable` (the
  flame every Valve tileset uses).
- Tilesets: **radiant_coloseum_basic** / **dire_coloseum_basic** (trees `tree_cypress008-010`,
  `topiary001/002`, `tree_oldolive/2`). **mines_tileset** has `wagons`, `bracings`,
  `retaining_walls` and `lanterns` tile types for mine roads.

### Tile structure shared by the `*_basic` tilesets
Every `*_basic` tileset defines these tile-set groups: `Riverbed`, `Waterfall_details`,
`Ground`, `Trees`, `Props`, `details`, `Plants`. Spring and summer add `RiverStairs`.

The `type` property offers `camp_neutral`, `banners`, `statues`, `light sources`,
`logo_ground`, `path_overlays`, `overlays`, `bases_static`, `grass clumps`,
`grass clumps thin`, `tree_details_static` and `ambient_creatures`. Each Radiant tileset also
has the tree groups `pine_summer`, `deciduous_spring` and `bamboo`, and the density options
`sparse`, `moderate` and `thick`. Each Dire tileset has `bat_swarm`.

Other properties: `height` (0-768 in 128 steps), `water`, `path`, `destruction`, `shape`
(cliff and waterfall pieces), and `size` (`small`/`medium`/`large`).
