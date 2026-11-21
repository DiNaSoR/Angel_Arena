-- The green biome's boss: the Elder Grovewarden. Copy this file for a new biome's boss.
-- The shared rules (spawning, phases, leash, rewards, announcements) are in
-- arena/core/bosses.lua; this file is only what makes this boss different.

return {
    unit = "npc_arena_green_boss",
    color = "#8be06b",            -- colour of its announcements

    first_spawn = 600,            -- seconds on the match clock before it first appears
    warning = 60,                 -- announce it this many seconds before it appears
    respawn = 480,                -- seconds after a kill before it returns
    leash = 1400,                 -- pulled further than this from its marker, it goes home and resets
    aggro = 700,                  -- attacks heroes this close on sight

    -- Stats on its first appearance; each return adds `growth` x (times killed).
    stats = { health = 42000, damage = 240, armor = 16, gold = 0, xp = 0 },
    growth = { health = 0.5, damage = 0.25, armor = 0.15, reward = 0.25 },

    -- Health fractions where each phase begins. Every phase after the first is announced
    -- (token arena_green_boss_phase_<n>), adds a stack of rage and raises its abilities' level.
    phases = {
        { health = 1.0 },
        { health = 0.6 },
        { health = 0.25 },
    },

    -- In priority order. `phase` is the first phase that uses the ability; the rest are hints for
    -- the shared brain (arena/core/monster_ai.lua). `lock` keeps it from starting another move
    -- while a telegraph is still on the ground.
    abilities = {
        { name = "arena_green_boss_thorn_nova", phase = 1, radius = 450, lock = 0.5 },
        { name = "arena_green_boss_root_eruption", phase = 1, radius = 1100, lock = 1.6 },
        { name = "arena_green_boss_falling_timber", phase = 2, target = "point", lock = 1.4 },
        { name = "arena_green_boss_call_of_the_grove", phase = 2, radius = 1100 },
    },
    summons = { "npc_arena_green_sproutling" },

    -- Paid to every hero on the killing team; `items` items drop from the boss pool plus `loot`.
    reward = {
        gold = 1500,
        xp = 2500,
        items = 2,
        loot = { "item_arena_trollheart_locket", "item_arena_pilgrims_lantern" },
    },

    sounds = { awaken = "Hero_Treant.Overgrowth.Cast", phase = "Hero_Furion.TreantRoar", death = "Hero_Treant.Death" },
    effects = { phase = "particles/units/heroes/hero_treant/treant_overgrowth_cast.vpcf" },
}
