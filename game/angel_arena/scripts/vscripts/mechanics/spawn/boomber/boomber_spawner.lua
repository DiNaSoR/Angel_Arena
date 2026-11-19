local StartRaid = require("mechanics/spawn/raid")

StartRaid(thisEntity, {
    name = "AngelArenaBoomberRaid",
    interval = 550,
    unit = "npc_dota_creature_boomber",
    enabled = function() return ALLOW_boomber end,
    unit_count = function() return MIN_SPAWN_boomber, MAX_SPAWN_boomber end,
    message = "Boomber outbreak!",
})
