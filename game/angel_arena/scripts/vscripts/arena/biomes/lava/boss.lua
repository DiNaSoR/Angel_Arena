-- The lava biome's boss: the Cinder Tyrant (Doom's body in his own armor). The shared rules
-- (spawning, phases, leash, rewards, announcements) are in arena/core/bosses.lua; this file is
-- only what makes this boss different. The hardest fight in the camp system: it comes late,
-- punishes standing next to it (Searing Presence stacks Heat, Infernal Brand melts armor) and
-- in its last phase forces the opposite: the only safe ground from Heart of the Volcano is at
-- its feet.

return {
    unit = "npc_arena_lava_boss",
    color = "#ff6a2a",            -- colour of its announcements

    first_spawn = 1200,           -- seconds on the match clock before it first appears
    warning = 60,                 -- announce it this many seconds before it appears
    respawn = 600,                -- seconds after a kill before it returns
    leash = 900,                  -- pulled further than this from its marker, it goes home and resets
    aggro = 600,                  -- attacks heroes this close on sight

    -- Stats on its first appearance; each return adds `growth` x (times killed).
    stats = { health = 60000, damage = 300, armor = 20, gold = 0, xp = 0 },
    growth = { health = 0.5, damage = 0.25, armor = 0.15, reward = 0.25 },

    -- Phase 1: Caldera Wake, Searing Presence, Infernal Brand.
    -- Phase 2 (60%): + Pyroclast Barrage and Brood of Cinders; eruptions leave fire.
    -- Phase 3 (30%): + Heart of the Volcano; everything faster and harder.
    phases = {
        { health = 1.0 },
        { health = 0.6 },
        { health = 0.3 },
    },

    -- In priority order, the same order as the unit's Ability slots (the brain tries slot 1
    -- first). `lock` keeps it from starting another move while a telegraph is still on the
    -- ground: Caldera Wake's last wave lands 2.2 s after the cast at most.
    abilities = {
        { name = "arena_lava_boss_heart_of_the_volcano", phase = 3, radius = 900, lock = 0.5 },
        { name = "arena_lava_boss_caldera_wake", phase = 1, radius = 800, lock = 2.4 },
        { name = "arena_lava_boss_pyroclast_barrage", phase = 2, target = "enemy", range = 1200, lock = 1.0 },
        { name = "arena_lava_boss_brood_of_cinders", phase = 2, radius = 1100 },
        { name = "arena_lava_boss_searing_presence", phase = 1 },
        { name = "arena_lava_boss_infernal_brand", phase = 1 },
    },
    summons = { "npc_arena_lava_ember_sprite" },

    -- Paid to every hero on the killing team; `items` items drop from the boss pool plus `loot`.
    reward = {
        gold = 2500,
        xp = 4000,
        items = 3,
        loot = { "item_arena_heart_of_the_inferno", "item_arena_abyssal_heart", "item_arena_hellfire_brazier", "item_arena_dragon_scale" },
    },

    sounds = { awaken = "Hero_Warlock.RainOfChaos", phase = "Hero_Invoker.Cataclysm.Ignite", death = "Hero_DoomBringer.Death" },
    effects = { phase = "particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf" },
}
