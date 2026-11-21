# Angel Arena item set

The 99 `item_arena_*` items are defined in one place, `arena_items.py`, and everything the game
reads is generated from it.

```
python tools/items/build_arena_items.py          # write the generated files
python tools/items/build_arena_items.py --check  # fail if they are out of date
```

| Generated file | What it holds |
|---|---|
| `game/angel_arena/scripts/npc/items/arena/arena_items.txt` | item and recipe definitions |
| `game/angel_arena/scripts/shops/angel_arena_shops.txt` | shop entries, in a marked block per section |
| `game/angel_arena/resource/addon_english.txt` and `content/angel_arena/addon_english_utf8.txt` | tooltips, in a marked block |
| `tools/items/icon_prompts.json` | one icon job per item |

The items share three scripts under `game/angel_arena/scripts/vscripts/items/arena/`:
`arena_items.lua` (item classes, actives, consumables), `arena_modifiers.lua` (passive effects)
and `arena_fx.lua` (particles and sounds). An item gets its behaviour from the `mech`, `active`
and `consume` fields of its entry, so a new item is a new entry and no new Lua.

## Adding or changing an item

1. Edit `arena_items.py`. Ids follow list order, so add new items at the end of a section only
   if you accept that later ids shift; published games should append at the end of the list.
2. Run `build_arena_items.py`.
3. Give it an icon (below).
4. Run `python tests/arena_items.py` and `lua5.1 tests/arena_items.lua`.

## Icons

Icons were generated with Azure `gpt-image-2.5-flare`. Dota draws item icons at 88x64 without
scaling, so the renders are cropped and scaled to exactly that size.

```
python tools/ui_art/generate_ui_art.py --out <raw dir> --jobs tools/items/icon_prompts.json [key ...]
python tools/items/process_icons.py <raw dir>
```

Icons are written to `game/angel_arena/resource/flash3/images/items/arena/`.
