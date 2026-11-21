# Angel Arena

Angels and Demons compete in a two-team Dota 2 custom game. Clear camps, gear up, and fight to reach the enemy hero kill target. Defeating Bador is another way to win. The kill target scales with the lobby size.

The game uses Lua for match rules and Panorama for the loading screen and HUD. The native Dota controls remain available alongside the arena score, kill target, duel countdown, and victory result. The first duel starts five minutes into the match. Camps scale by elapsed match time and have separate loot pools by difficulty.

## Build and play in Workshop Tools

Use a Windows installation of Steam, Dota 2, the **Dota 2 Workshop Tools** DLC, and Python 3.9 or later. From the repository root, deploy to the **Dota 2 Beta** folder that contains both `content` and `game`.

```powershell
py -3 tools/deploy.py "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta" --dry-run
py -3 tools/deploy.py "C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta"
```

| Repository | Installed addon |
| --- | --- |
| `content/angel_arena` | `content/dota_addons/angel_arena` |
| `game/angel_arena` | `game/dota_addons/angel_arena` |

Back up and move any previous unmanaged `angel_arena` directories before the first deployment. Subsequent deployments update files installed by the script and leave Workshop-generated files in place. If you edit an installed source file in Hammer, copy it back to the repository before deploying again.

1. Launch **Dota 2 Workshop Tools** from Steam and select **angel_arena**.
2. Open `maps/angel_arena.vmap` in Hammer. Build the map and run it from Hammer. The repository ships the editable map, Lua, and Panorama sources, and the build produces the map package and compiled resources for your installation.
3. After the build, use `dota_launch_custom_game angel_arena angel_arena` in the Dota developer console to launch another local lobby. Rebuild after changing the map or Panorama assets.

Before publishing to the Workshop, play a 2v2 match to verify hero selection, opening camps, and a shop purchase immediately followed by a gold reward. Check the first duel countdown, a reconnect during the duel, and score credit for an enemy hero who has Aegis or Reincarnation. Play both victory paths in separate lobbies and check Bador's hook warning and the victory HUD in the Dota client.

## Validate outside the game

Run these commands from the repository root with Lua 5.1, Node.js and Python installed. In the Codex cloud environment, the onboarding script places the Lua binaries under `/workspace/angel-arena-tools/lua51/usr/bin`.

```bash
find game/angel_arena/scripts/vscripts -name '*.lua' -print0 | xargs -0 -n1 luac5.1 -p
find content/angel_arena/panorama/scripts -name '*.js' -print0 | xargs -0 -n1 node --check
# includes tests/arena_biomes.lua and the biome tests arena_ice.lua, arena_desert.lua, arena_lava.lua
for test in tests/*.lua; do lua5.1 "$test" || exit; done
node tests/panorama_match.js
node tests/panorama_setup.js
python3 tests/npc_references.py
python3 tests/arena_items.py
python3 tests/arena_biomes.py
python3 tests/arena_map.py
python3 tests/workshop_deploy.py
```

Monster camps and biome bosses are built from per-biome files; see `tools/biomes/README.md`. The standalone checks exercise repository code with mocked Dota APIs and deploy into a temporary Steam-style directory. Hammer still needs to compile the shipped map and resolve its legacy prefab dependencies.

## References

- [Valve Dota 2 Workshop Tools](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools)
- [Valve Dota 2 Workshop Tools on Steam](https://store.steampowered.com/app/313250/Dota_2_Workshop_Tools_DLC/)
- [ModDota addon template](https://github.com/ModDota/TypeScriptAddonTemplate)
- [ModDota game API declarations](https://github.com/ModDota/TypeScriptDeclarations)

Original project credits include DiNaSoR, Noya, Aleteh, and BMD.
