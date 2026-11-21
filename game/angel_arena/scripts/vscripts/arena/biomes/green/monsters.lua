-- The green biome (the Verdant Wilds): the reference biome. Copy this file for a new biome.
--
-- monsters  every monster the camps can spawn, by unit name, with its stats at minute 0. The
--           unit itself (model, abilities, attack) is in npc/units/arena/arena_green_units.txt.
--           Stats here win over the unit file and grow with the match (arena/core/tiers.lua).
--           `ai` tells the shared brain how to use an ability when the default (taken from the
--           ability's behaviour) is wrong; see arena/core/monster_ai.lua for the keys.
-- tiers     for each tier (1 easy, 2 medium, 3 hard, 4 elite) the groups a camp can hold.
--           Leader first, minions after: late in the match a camp gets one more copy of the
--           LAST monster in its group.
-- loot      optional extra items for a tier's drop pool (added to arena/core/rewards.lua's).

return {
    biome = "green",

    monsters = {
        -- easy: no abilities
        npc_arena_green_sproutling = { health = 380, damage = 14, armor = 1, gold = 14, xp = 45 },
        npc_arena_green_bramble_pup = { health = 320, damage = 16, armor = 0.5, gold = 12, xp = 40 },
        npc_arena_green_sporecap = { health = 300, damage = 18, armor = 0, gold = 14, xp = 45 },
        -- medium
        npc_arena_green_thorn_archer = { health = 620, damage = 30, armor = 1.5, gold = 50, xp = 70 },
        npc_arena_green_vine_wolf = { health = 760, damage = 34, armor = 2.5, gold = 55, xp = 75 },
        -- hard
        npc_arena_green_thicket_bear = {
            health = 1900, damage = 62, armor = 4, gold = 110, xp = 100,
            ai = { arena_green_bramble_slam = { radius = 275 } },
        },
        npc_arena_green_spore_shaman = {
            health = 1200, damage = 44, armor = 2, gold = 100, xp = 90,
            ai = { arena_green_mending_sap = { ally_health_below = 0.75 } },
        },
        -- elite
        npc_arena_green_grove_hulk = {
            health = 4200, damage = 120, armor = 8, gold = 240, xp = 220,
            ai = { arena_green_bark_skin = { health_below = 0.6, radius = 900 } },
        },
        npc_arena_green_strangler_bloom = { health = 2200, damage = 80, armor = 3, gold = 170, xp = 140 },
    },

    tiers = {
        [1] = {
            { "npc_arena_green_sproutling", "npc_arena_green_sproutling", "npc_arena_green_bramble_pup" },
            { "npc_arena_green_bramble_pup", "npc_arena_green_bramble_pup", "npc_arena_green_sporecap" },
            { "npc_arena_green_sporecap", "npc_arena_green_sporecap", "npc_arena_green_sproutling" },
        },
        [2] = {
            { "npc_arena_green_vine_wolf", "npc_arena_green_bramble_pup", "npc_arena_green_bramble_pup" },
            { "npc_arena_green_thorn_archer", "npc_arena_green_thorn_archer", "npc_arena_green_sproutling" },
            { "npc_arena_green_vine_wolf", "npc_arena_green_thorn_archer" },
        },
        [3] = {
            { "npc_arena_green_thicket_bear", "npc_arena_green_thorn_archer", "npc_arena_green_thorn_archer" },
            { "npc_arena_green_spore_shaman", "npc_arena_green_thicket_bear" },
            { "npc_arena_green_spore_shaman", "npc_arena_green_vine_wolf", "npc_arena_green_vine_wolf" },
        },
        [4] = {
            { "npc_arena_green_grove_hulk", "npc_arena_green_spore_shaman", "npc_arena_green_thorn_archer" },
            { "npc_arena_green_thicket_bear", "npc_arena_green_strangler_bloom", "npc_arena_green_strangler_bloom" },
            { "npc_arena_green_grove_hulk", "npc_arena_green_strangler_bloom" },
        },
    },

    loot = {
        [3] = { "item_arena_wind_charm" },
        [4] = { "item_arena_trollheart_locket" },
    },
}
