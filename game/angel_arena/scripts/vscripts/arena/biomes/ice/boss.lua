-- The ice biome's boss: Hoarfrost, the Glacier Giant. The shared rules (spawning, phases,
-- leash, rewards, announcements) are in arena/core/bosses.lua; this file is only what makes
-- this boss different.
--
-- The fight, phase by phase (each move is telegraphed; see arena/biomes/ice/abilities.lua):
--   1 (100%)  Frigid Fists crack the tank's armour; Frost Breath (three lines mark a cone during
--             a one-second wind-up); Icefall (rings of icicles fall outward from the giant, inner
--             ring first: its feet and fallen rings are safe).
--   2 (65%)   Whiteout: a blizzard follows the giant and chills every hero that stands still.
--             Everything hits harder and Icefall gains a third ring.
--   3 (30%)   Absolute Zero: the giant channels while a vast ring closes and three ice pillars
--             rise. Shelter beside a pillar, leave the ring, or stun it to cancel; whoever is
--             caught is frozen and takes heavy damage, and the Icefall that follows shatters them.

return {
    unit = "npc_arena_ice_boss",
    color = "#9fd8ff",            -- colour of its announcements

    first_spawn = 780,            -- seconds on the match clock before it first appears
    warning = 60,                 -- announce it this many seconds before it appears
    respawn = 480,                -- seconds after a kill before it returns
    leash = 1400,                 -- pulled further than this from its marker, it goes home and resets
    aggro = 700,                  -- attacks heroes this close on sight

    -- Stats on its first appearance; each return adds `growth` x (times killed).
    stats = { health = 46000, damage = 220, armor = 14, gold = 0, xp = 0 },
    growth = { health = 0.5, damage = 0.25, armor = 0.15, reward = 0.25 },

    phases = {
        { health = 1.0 },
        { health = 0.65 },
        { health = 0.3 },
    },

    -- `phase` is the first phase that uses the ability; the rest are hints for the shared brain.
    -- The brain tries abilities in the unit's slot order (Ability1 first), which matches this list.
    abilities = {
        { name = "arena_ice_boss_absolute_zero", phase = 3, radius = 900, lock = 1.0 },
        -- `radius` 900: the KV "radius" is one icicle's, not how close the target must be.
        { name = "arena_ice_boss_icefall", phase = 1, radius = 900, lock = 1.5 },
        { name = "arena_ice_boss_frost_breath", phase = 1, target = "point", range = 850, lock = 1.2 },
        { name = "arena_ice_boss_frigid_fists", phase = 1 },
        { name = "arena_ice_boss_whiteout", phase = 2 },
    },

    -- Absolute Zero creates its pillars itself (not through ArenaBosses.Summon); listing the unit
    -- here is how it gets precached.
    summons = { "npc_arena_ice_glacial_pillar" },

    -- Paid to every hero on the killing team; `items` items drop from the boss pool plus `loot`.
    reward = {
        gold = 1600,
        xp = 2600,
        items = 2,
        loot = { "item_arena_rimeglass_orb", "item_arena_titan_knuckle" },
    },

    sounds = {
        awaken = "Hero_Ancient_Apparition.IceBlastRelease.Cast",
        phase = "Hero_Lich.IceAge",
        death = "Hero_Tusk.Death",
    },
    effects = { phase = "particles/units/heroes/hero_lich/lich_frost_nova.vpcf" },
}
