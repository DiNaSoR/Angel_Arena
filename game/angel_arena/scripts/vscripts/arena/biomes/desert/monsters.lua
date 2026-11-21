-- The desert biome (the Sunken Dunes): the sun-bleached north-east, reached mid game.
-- Same shape as the green reference (arena/biomes/green/monsters.lua); see that file and
-- tools/biomes/README.md for what each part means.
--
-- What sets the desert apart: monsters that burrow and strike from below (Oasis Lurker), sand
-- that blinds and shoves (Dust Outrider, Sirocco Khan), venom that wears fighters down
-- (Sandscale Basilisk), the sun punishing heroes who bunch up and mirages that blows pass through
-- (Sun Priest), and ground that swallows whoever stands still (Dune Behemoth).

return {
    biome = "desert",

    monsters = {
        -- easy: no abilities
        npc_arena_desert_dune_kobold = { health = 420, damage = 16, armor = 1, gold = 15, xp = 48 },
        npc_arena_desert_skitterer = { health = 300, damage = 18, armor = 0, gold = 13, xp = 42 },
        npc_arena_desert_ridge_slinger = { health = 340, damage = 20, armor = 0, gold = 15, xp = 48 },
        -- medium
        npc_arena_desert_oasis_lurker = {
            health = 820, damage = 34, armor = 2.5, gold = 55, xp = 75,
            -- a gap closer: it dives for heroes that keep their distance, not the one it is biting
            ai = { arena_desert_ambush = { min_range = 250 } },
        },
        npc_arena_desert_dust_outrider = { health = 700, damage = 32, armor = 2, gold = 52, xp = 72 },
        -- hard
        npc_arena_desert_sandscale_basilisk = { health = 2000, damage = 58, armor = 4, gold = 110, xp = 100 },
        npc_arena_desert_sun_priest = {
            health = 1250, damage = 44, armor = 2, gold = 100, xp = 90,
            ai = { arena_desert_heat_shimmer = { radius = 700 } },
        },
        -- elite
        npc_arena_desert_dune_behemoth = {
            health = 4400, damage = 120, armor = 8, gold = 240, xp = 220,
            ai = { arena_desert_dune_slam = { radius = 300 } },
        },
        npc_arena_desert_storm_khan = {
            health = 3200, damage = 95, armor = 5, gold = 200, xp = 170,
            ai = { arena_desert_sandstorm = { radius = 350 } },
        },
    },

    tiers = {
        [1] = {
            { "npc_arena_desert_dune_kobold", "npc_arena_desert_dune_kobold", "npc_arena_desert_skitterer" },
            { "npc_arena_desert_ridge_slinger", "npc_arena_desert_skitterer", "npc_arena_desert_skitterer" },
            { "npc_arena_desert_dune_kobold", "npc_arena_desert_ridge_slinger", "npc_arena_desert_ridge_slinger" },
        },
        [2] = {
            { "npc_arena_desert_oasis_lurker", "npc_arena_desert_dune_kobold", "npc_arena_desert_dune_kobold" },
            { "npc_arena_desert_dust_outrider", "npc_arena_desert_ridge_slinger", "npc_arena_desert_ridge_slinger" },
            { "npc_arena_desert_dust_outrider", "npc_arena_desert_oasis_lurker" },
        },
        [3] = {
            { "npc_arena_desert_sandscale_basilisk", "npc_arena_desert_oasis_lurker", "npc_arena_desert_oasis_lurker" },
            { "npc_arena_desert_sun_priest", "npc_arena_desert_sandscale_basilisk" },
            { "npc_arena_desert_sun_priest", "npc_arena_desert_dust_outrider", "npc_arena_desert_dust_outrider" },
        },
        [4] = {
            { "npc_arena_desert_dune_behemoth", "npc_arena_desert_sun_priest", "npc_arena_desert_oasis_lurker" },
            { "npc_arena_desert_storm_khan", "npc_arena_desert_dust_outrider", "npc_arena_desert_dust_outrider" },
            { "npc_arena_desert_dune_behemoth", "npc_arena_desert_sandscale_basilisk" },
            { "npc_arena_desert_storm_khan", "npc_arena_desert_sun_priest" },
        },
    },

    -- Mirage cloaks in the hard camps, buried coins in the elite ones.
    loot = {
        [3] = { "item_arena_mist_cloak" },
        [4] = { "item_arena_lucky_coin" },
    },
}
