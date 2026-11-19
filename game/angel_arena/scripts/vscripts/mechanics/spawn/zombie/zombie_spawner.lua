local StartRaid = require("mechanics/spawn/raid")

StartRaid(thisEntity, {
    name = "AngelArenaZombieRaid",
    interval = 420,
    unit = "npc_dota_creature_basic_zombie",
    enabled = function() return ALLOW_ZOMBI end,
    unit_count = function() return MIN_SPAWN_ZOMBI, MAX_SPAWN_ZOMBI end,
    message = "Zombie raid approaching!",
    sound = "angel_arena.zombiesiren",
})
