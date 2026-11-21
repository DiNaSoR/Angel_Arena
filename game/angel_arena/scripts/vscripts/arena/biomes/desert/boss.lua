-- The desert biome's boss: Ankharos, the Sunken King, a scorpion lord under the buried temple.
-- The shared rules (spawning, phases, leash, rewards, announcements) are in arena/core/bosses.lua;
-- this file is only what makes this boss different. Its abilities are in abilities.lua.
--
-- The fight, phase by phase (every dangerous move shows on the ground before it lands):
--   1  Caustic Venom on every blow (a ring warns one blow before it bursts on the tank's
--      neighbours), Undermine (sinks and erupts under a hero inside a closing ring) and Sirocco
--      (a line toward the nearest hero; whoever stays on it is shoved and blinded).
--   2  Brand of the Sun on every hero nearby (each brand bursts around its bearer: spread out),
--      two Sirocco lines, quicker Undermine, venom bursts sooner.
--   3  Dune Collapse (rings under every hero and all around the lair), three Sirocco lines.

return {
    unit = "npc_arena_desert_boss",
    color = "#f2c46b",            -- colour of its announcements

    first_spawn = 900,            -- the desert is a mid-game region: it rises at 15 minutes
    warning = 60,
    respawn = 540,
    leash = 1400,
    aggro = 700,

    stats = { health = 52000, damage = 280, armor = 18, gold = 0, xp = 0 },
    growth = { health = 0.5, damage = 0.25, armor = 0.15, reward = 0.25 },

    phases = {
        { health = 1.0 },
        { health = 0.65 },
        { health = 0.3 },
    },

    -- Same order as the unit's ability slots, which is the order the shared brain tries them in.
    abilities = {
        { name = "arena_desert_boss_caustic_venom", phase = 1 },
        { name = "arena_desert_boss_dune_collapse", phase = 3, radius = 1200, lock = 2.4 },
        { name = "arena_desert_boss_sun_brand", phase = 2, radius = 1100, lock = 1.0 },
        { name = "arena_desert_boss_undermine", phase = 1, target = "point", range = 1100, lock = 2.0 },
        { name = "arena_desert_boss_sirocco", phase = 1, radius = 1000, lock = 1.6 },
    },

    reward = {
        gold = 1800,
        xp = 3000,
        items = 2,
        loot = { "item_arena_hourglass", "item_arena_barbed_hide" },
    },

    sounds = { awaken = "Ability.SandKing_SandStorm.start", phase = "Ability.SandKing_Epicenter", death = "Hero_SandKing.Death" },
    effects = { phase = "particles/units/heroes/hero_sandking/sandking_epicenter_tell.vpcf" },
}
