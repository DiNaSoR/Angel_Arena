-- The wilds: the unthemed camps in the middle of the map, using Dota's own neutral creeps.
-- Tiers 1 to 3 come from the original camp table (mechanics/camps/creep_types.lua); the ancient
-- creeps moved up to the new elite tier 4.
--
-- Stats are at minute 0 and grow with the match clock (arena/core/tiers.lua).
-- In a group, list the leader first and minions after: late in the match a camp gets one more
-- copy of the LAST monster in its group.

return {
    biome = "wilds",

    monsters = {
        -- easy
        npc_dota_neutral_kobold =                     { health = 280, damage = 10, armor = 0.5, gold = 10, xp = 40 },
        npc_dota_neutral_kobold_tunneler =            { health = 480, damage = 12, armor = 1, gold = 10, xp = 50 },
        npc_dota_neutral_kobold_taskmaster =          { health = 560, damage = 16, armor = 1, gold = 10, xp = 55 },
        npc_dota_neutral_ghost =                      { health = 480, damage = 12, armor = 1, gold = 10, xp = 60 },
        -- medium
        npc_dota_neutral_harpy_storm =                { health = 560, damage = 24, armor = 2, gold = 50, xp = 71 },
        npc_dota_neutral_harpy_scout =                { health = 440, damage = 40, armor = 1, gold = 50, xp = 30 },
        npc_dota_neutral_polar_furbolg_champion =     { health = 640, damage = 28, armor = 2, gold = 50, xp = 63 },
        npc_dota_neutral_alpha_wolf =                 { health = 700, damage = 30, armor = 2, gold = 55, xp = 70 },
        npc_dota_neutral_giant_wolf =                 { health = 560, damage = 26, armor = 1, gold = 45, xp = 60 },
        -- hard
        npc_dota_neutral_gnoll_assassin =             { health = 1200, damage = 50, armor = 4, gold = 100, xp = 45 },
        npc_dota_neutral_centaur_khan =               { health = 1640, damage = 40, armor = 3, gold = 100, xp = 50 },
        npc_dota_neutral_centaur_outrunner =          { health = 1200, damage = 56, armor = 5, gold = 100, xp = 50 },
        npc_dota_neutral_dark_troll_warlord =         { health = 1840, damage = 80, armor = 3, gold = 100, xp = 98 },
        npc_dota_neutral_dark_troll =                 { health = 1000, damage = 40, armor = 2, gold = 90, xp = 60 },
        npc_dota_neutral_satyr_hellcaller =           { health = 1500, damage = 50, armor = 3, gold = 100, xp = 80 },
        npc_dota_neutral_satyr_soulstealer =          { health = 1000, damage = 40, armor = 2, gold = 90, xp = 60 },
        npc_dota_neutral_polar_furbolg_ursa_warrior = { health = 1600, damage = 60, armor = 4, gold = 110, xp = 80 },
        -- elite
        npc_dota_neutral_black_dragon =               { health = 3600, damage = 110, armor = 6, gold = 220, xp = 200 },
        npc_dota_neutral_black_drake =                { health = 2000, damage = 60, armor = 4, gold = 160, xp = 120 },
        npc_dota_neutral_big_thunder_lizard =         { health = 3400, damage = 100, armor = 6, gold = 220, xp = 200 },
        npc_dota_neutral_small_thunder_lizard =       { health = 1900, damage = 60, armor = 4, gold = 150, xp = 120 },
        npc_dota_neutral_granite_golem =              { health = 4000, damage = 100, armor = 8, gold = 230, xp = 210 },
        npc_dota_neutral_rock_golem =                 { health = 2200, damage = 60, armor = 5, gold = 150, xp = 120 },
        npc_dota_neutral_prowler_shaman =             { health = 3200, damage = 110, armor = 6, gold = 220, xp = 200 },
        npc_dota_neutral_prowler_acolyte =            { health = 1900, damage = 60, armor = 4, gold = 150, xp = 120 },
        npc_dota_neutral_elder_jungle_stalker =       { health = 3800, damage = 120, armor = 6, gold = 240, xp = 220 },
        npc_dota_neutral_jungle_stalker =             { health = 2400, damage = 70, armor = 5, gold = 160, xp = 130 },
    },

    tiers = {
        [1] = {
            { "npc_dota_neutral_kobold_tunneler", "npc_dota_neutral_kobold" },
            { "npc_dota_neutral_kobold_taskmaster", "npc_dota_neutral_kobold" },
            { "npc_dota_neutral_ghost", "npc_dota_neutral_ghost" },
        },
        [2] = {
            { "npc_dota_neutral_harpy_storm", "npc_dota_neutral_harpy_storm", "npc_dota_neutral_harpy_scout" },
            { "npc_dota_neutral_polar_furbolg_champion", "npc_dota_neutral_polar_furbolg_champion" },
            { "npc_dota_neutral_alpha_wolf", "npc_dota_neutral_giant_wolf" },
        },
        [3] = {
            { "npc_dota_neutral_centaur_khan", "npc_dota_neutral_centaur_outrunner" },
            { "npc_dota_neutral_gnoll_assassin", "npc_dota_neutral_gnoll_assassin" },
            { "npc_dota_neutral_dark_troll_warlord", "npc_dota_neutral_dark_troll" },
            { "npc_dota_neutral_satyr_hellcaller", "npc_dota_neutral_satyr_soulstealer" },
            { "npc_dota_neutral_polar_furbolg_ursa_warrior", "npc_dota_neutral_polar_furbolg_champion" },
        },
        [4] = {
            { "npc_dota_neutral_black_dragon", "npc_dota_neutral_black_drake", "npc_dota_neutral_black_drake" },
            { "npc_dota_neutral_big_thunder_lizard", "npc_dota_neutral_small_thunder_lizard", "npc_dota_neutral_small_thunder_lizard" },
            { "npc_dota_neutral_granite_golem", "npc_dota_neutral_rock_golem", "npc_dota_neutral_rock_golem" },
            { "npc_dota_neutral_prowler_shaman", "npc_dota_neutral_prowler_acolyte", "npc_dota_neutral_prowler_acolyte" },
            { "npc_dota_neutral_elder_jungle_stalker", "npc_dota_neutral_jungle_stalker" },
        },
    },
}
