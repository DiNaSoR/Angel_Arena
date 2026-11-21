# Angel Arena map tools

The map (`content/angel_arena/maps/angel_arena.vmap`) is generated: `build_map.py` takes the
hand-made base map and adds the four themed regions, the camp and boss markers and the dressing.

```
python tools/map/build_map.py                 # regenerate the map and tools/map/layout.json
python tools/map/build_map.py --name aa_lab   # write a scratch copy to try something
python tools/map/build_map.py --check         # is layout.json what the script produces?
python tests/arena_map.py                     # markers present, named as the game scripts expect
```

Close Hammer first. After generating, build the map in Hammer as usual (or open it there to look
around; everything the script adds is ordinary tile-grid data and entities).

**If you edit the map by hand in Hammer, the next run of `build_map.py` overwrites it.** Either make
hand edits to the base map (`base/angel_arena_v1.vmap`: copy it into `content/angel_arena/maps/`,
edit, copy back) and regenerate, or stop using the generator and treat the generated map as the
new hand-made one.

| File | What it is |
|---|---|
| `base/angel_arena_v1.vmap` | the map before the regions were added |
| `build_map.py` | the layout: regions, lakes, lava pools, camps, bosses, dressing |
| `aamap.py` | the library that edits a map as text |
| `layout.json` | where the generator put every marker and landmark (read by `tests/arena_map.py`) |
| `catalog/` | Dota models and particles that were checked to exist, by theme |

## The regions

| Region | Where | How it is made |
|---|---|---|
| Ice | north-west, including the high plateau | `radiant_snow_basic` tileset, ice spikes and crystals |
| Green | north centre | the base tileset, a lake, new jungle on drained sea, giant trees and mushrooms |
| Desert | north-east | `radiant_desert_basic` tileset on drained sea, oasis, obelisks, ruins |
| Lava | south-east plain | the Dire tileset with sunken lava pools, fire and Dire ruins |
| Wilds | everything else | the base map with light dressing |

Camps are entities named `arena_camp_<region>_<tier>`, bosses `arena_boss_<region>`; the game
side is described in `tools/biomes/README.md`. The old `creep_camp` triggers are renamed in place.

## What the map file stores (learned the hard way)

The tile grid is a 64 x 64 grid of 256-unit cells. Its arrays, in `CDmeDotaTileGrid`:

- `cellsTileSet`, `objectsTileSet`: which of the grid's tileset slots a cell or object uses. **There
  are exactly four slots.** Declaring a fifth is accepted but the compiler crashes as soon as a cell
  uses it. The base map used two of its four, so two were retargeted to snow and desert.
- `verticesHeight` (65 x 65): terrain level; world z is `128 + 128 * level`.
- `verticesWater` (65 x 65): shallow water. The two "seas" were this flag, not a height.
- `cellsOrientation`: rotation of the cell's tile. It is fixed by the cell's corner heights for
  every shape except flat; a cell whose shape changes needs it recomputed or its cliff faces
  point the wrong way (`VMap.fix_orientation`).
- `cellConfiguration` / `objectConfiguration`: per cell or object slot, a length followed by that
  many ints: the tile and the random variants Hammer picked. After a shape change the record must
  be emptied so the compiler chooses again; a *flat* cell with an empty record comes out as a
  hole, so flat cells get the plain land record (`VMap.make_land`).
- Node ids in those records are shared between the Radiant-family `*_basic` tilesets but not
  between Radiant and Dire. A Dire cell moved to a Radiant tileset must have its record replaced.
  Hand-picked tiles (`cellsVariationId` 3 and up: stairs) reach into their neighbours and are
  left in their original tileset.
- `cellsVariationId`, `edgesPath`, `edgesDestruction`, `cellsHidden`: not edited.
- `objectsTreeType/Size/Rotation/Pitch/VariationId`, `objectsPropType`, `objectsPlantType`
  (257 x 257, 64 units apart): trees and the tileset's own props. The type is an index into the
  slot's `treeTypes` / `propTypes` list in `tileSetMapInfo`.
- `blendOpacity` (513 x 513): three painted ground layers over the tileset's base ground. The sea
  bed was painted with layer 2; drained cells are reset to bare ground.
- `gridnavFlags` (256 x 256, 64 units): 1 blocks walking. Used under large models, which have
  no collision of their own.

Things that went wrong while building this, so they are not repeated:

- A model with a walking block placed on the foot of a ramp cut the plateau off. Ramps and
  stairs are now reserved (`WALKWAYS` and every cell with a hand-picked tile).
- The ground looks like water under the map's blue fog from above; check `verticesWater`.
- `prop_static` models do not block movement; trees do.

## Checking a build in the game

Compile from the command line the way Hammer does:

```
resourcecompiler.exe -threads 8 -fshallow -maxtextureres 256 -dxlevel 110 -quiet -unbufferedio -noassert \
  -i "<dota>/content/dota_addons/angel_arena/maps/angel_arena.vmap" -world -phys -vis -gridnav -breakpad -nompi -nop4 \
  -outroot "<temp>/hammermapbuild/game"
```

then copy `<outroot>/dota_addons/angel_arena/maps/angel_arena.vpk` to `game/angel_arena/maps/`.
In a cheat lobby, `GridNav:CanFindPath(fountain, marker)` for every entry of `layout.json` tells
whether a camp can be reached; the last build had all 38 reachable.
