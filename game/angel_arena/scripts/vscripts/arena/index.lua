-- Entry point of the arena world: biome camps, biome bosses and the shared monster brain.
-- Required once from addon_game_mode.lua. See tools/biomes/README.md for how biomes are built.
--
-- Hooks into the rest of the game mode (each one line in a shared file):
--   precache/precache.lua   ArenaBiomes.Precache(context)
--   setting/aa.lua          InitModule(ArenaWorld) when the match starts
--   setting/events.lua      ArenaWorld.OnEntityKilled(unit, attacker) for every death

require("arena/core/fx")
require("arena/core/modifiers")
require("arena/core/tiers")
require("arena/core/biomes")
require("arena/core/markers")
require("arena/core/monster_ai")
require("arena/core/champions")
require("arena/core/rewards")
require("arena/core/camps")
require("arena/core/bosses")

if ArenaWorld then
    return ArenaWorld
end

ArenaWorld = {}

function ArenaWorld:Init()
    ArenaCamps:Init()
    ArenaBosses:Init()
end

function ArenaWorld.OnEntityKilled(unit, attacker)
    if not unit or not unit.GetTeamNumber then
        return
    end
    if not ArenaCamps:OnUnitKilled(unit, attacker) then
        ArenaBosses:OnUnitKilled(unit, attacker)
    end
end

-- Console helpers for testing on a live map.
--   arena_camps             lists every camp and its state
--   arena_boss_spawn green  brings a biome's boss in now (cheat lobbies only)
if Convars and Convars.RegisterCommand then
    Convars:RegisterCommand("arena_camps", function()
        for _, line in ipairs(ArenaCamps:Describe()) do
            print(line)
        end
    end, "List the arena monster camps", 0)
    Convars:RegisterCommand("arena_boss_spawn", function(_, biome)
        if GameRules:IsCheatMode() then
            ArenaBosses:ForceSpawn(biome or "green")
        end
    end, "Spawn a biome boss now (cheats only)", 0)
end

return ArenaWorld
