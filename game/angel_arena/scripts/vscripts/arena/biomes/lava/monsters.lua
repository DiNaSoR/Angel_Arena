-- The lava biome (the Scorched Reach): black Dire ground split by sunken lava pools, south-east of
-- the map beside the Lord of Death's pit. The late-game region: tier 1 already hurts, and its
-- elites are the hardest camps in the game.
--
-- What sets it apart (see abilities.lua): Heat that stacks the longer a fight lasts, armor that
-- melts, ground left burning, and monsters that burst when they die (a ring marks each blast).
--
-- monsters  every monster the camps can spawn, by unit name, with its stats at minute 0. The
--           unit itself (model, abilities, attack) is in npc/units/arena/arena_lava_units.txt.
-- tiers     for each tier the groups a camp can hold, leader first. Late in the match a camp
--           gets one more copy of the LAST monster in its group.
-- loot      extra items for a tier's drop pool. [5] is the pool an elite champion drops from.

return {
    biome = "lava",

    monsters = {
        -- easy: one simple trait each, already hitting like a green medium
        npc_arena_lava_ember_sprite = { health = 520, damage = 32, armor = 1, gold = 32, xp = 60 },
        npc_arena_lava_ashen_satyr = { health = 700, damage = 34, armor = 2, gold = 30, xp = 60 },
        npc_arena_lava_cinder_acolyte = { health = 560, damage = 40, armor = 1, gold = 30, xp = 60 },
        -- medium
        npc_arena_lava_flame_brawler = { health = 1300, damage = 58, armor = 3, gold = 80, xp = 100 },
        npc_arena_lava_magma_drake = { health = 1100, damage = 54, armor = 2, gold = 80, xp = 100 },
        -- hard
        npc_arena_lava_slag_golem = {
            health = 3000, damage = 95, armor = 6, gold = 170, xp = 150,
            ai = { arena_lava_eruption_slam = { radius = 250 } },
        },
        npc_arena_lava_cinder_hexer = {
            health = 1900, damage = 70, armor = 3, gold = 160, xp = 140,
            -- Kindle any ally that has been touched at all, not only badly hurt ones.
            ai = { arena_lava_kindle = { ally_health_below = 1 } },
        },
        -- elite
        npc_arena_lava_infernal_golem = { health = 6200, damage = 170, armor = 10, gold = 360, xp = 300 },
        npc_arena_lava_magma_wyrm = {
            health = 4200, damage = 135, armor = 6, gold = 320, xp = 260,
            ai = {
                arena_lava_searing_breath = { range = 650, lock = 1 },
                arena_lava_lava_bomb = { lock = 1 },
            },
        },
    },

    tiers = {
        [1] = {
            { "npc_arena_lava_ashen_satyr", "npc_arena_lava_ashen_satyr", "npc_arena_lava_ember_sprite" },
            { "npc_arena_lava_cinder_acolyte", "npc_arena_lava_ember_sprite", "npc_arena_lava_ember_sprite" },
            { "npc_arena_lava_ashen_satyr", "npc_arena_lava_cinder_acolyte", "npc_arena_lava_cinder_acolyte" },
        },
        [2] = {
            { "npc_arena_lava_flame_brawler", "npc_arena_lava_ashen_satyr", "npc_arena_lava_ember_sprite" },
            { "npc_arena_lava_magma_drake", "npc_arena_lava_cinder_acolyte", "npc_arena_lava_cinder_acolyte" },
            { "npc_arena_lava_flame_brawler", "npc_arena_lava_magma_drake" },
        },
        [3] = {
            { "npc_arena_lava_slag_golem", "npc_arena_lava_ember_sprite", "npc_arena_lava_ember_sprite", "npc_arena_lava_ember_sprite" },
            { "npc_arena_lava_cinder_hexer", "npc_arena_lava_flame_brawler", "npc_arena_lava_flame_brawler" },
            { "npc_arena_lava_slag_golem", "npc_arena_lava_magma_drake", "npc_arena_lava_magma_drake" },
        },
        [4] = {
            { "npc_arena_lava_infernal_golem", "npc_arena_lava_cinder_hexer", "npc_arena_lava_magma_drake" },
            { "npc_arena_lava_magma_wyrm", "npc_arena_lava_flame_brawler", "npc_arena_lava_flame_brawler" },
            { "npc_arena_lava_infernal_golem", "npc_arena_lava_magma_wyrm" },
        },
    },

    loot = {
        [1] = { "item_arena_ember_flask" },
        [2] = { "item_arena_cinder_heart", "item_arena_hellforged_ingot" },
        [3] = { "item_arena_brimstone_censer", "item_arena_obsidian_plate" },
        [4] = { "item_arena_dragon_scale", "item_arena_titan_core" },
        [5] = { "item_arena_hellfire_brazier", "item_arena_abyssal_heart" },
    },
}
