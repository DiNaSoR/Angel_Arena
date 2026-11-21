-- The ice biome (the Frostfang Reach): snow forest, the high frozen plateau, ice spires, a
-- Tuskarr camp and a whale graveyard in the north-west. Reached early to mid game: tier 1 is
-- farmable by a fresh hero, tier 4 wants a group or a strong carry.
--
-- What sets it apart is the cold (arena/biomes/ice/abilities.lua): monsters stack Chill (slower
-- movement and attacks) until a hero is Frozen for a moment, the brutes crack armour (Brittle)
-- and shatter frozen heroes, and the shaman's Blizzard punishes anyone who stands still in it.
-- Tier 1 has no abilities, so a new hero meets the cold only from tier 2 on.
--
-- monsters  stats at minute 0 by unit name (the units are in npc/units/arena/arena_ice_units.txt)
--           and `ai` hints where the brain's default use of an ability is wrong.
-- tiers     groups per tier, leader first: late in the match a camp gets one more copy of the
--           LAST monster in its group.
-- loot      extra items for a tier's drop pool.

return {
    biome = "ice",

    monsters = {
        -- easy: no abilities
        npc_arena_ice_frost_kobold = { health = 340, damage = 15, armor = 1, gold = 13, xp = 42 },
        npc_arena_ice_snow_gnoll = { health = 300, damage = 17, armor = 0, gold = 14, xp = 45 },
        npc_arena_ice_frostbitten_thrall = { health = 420, damage = 13, armor = 1.5, gold = 14, xp = 45 },
        -- medium: the first taste of the cold (Chill from the wraith, Brittle from the raider)
        npc_arena_ice_rime_wraith = { health = 600, damage = 28, armor = 1, gold = 50, xp = 70 },
        npc_arena_ice_tuskarr_raider = { health = 780, damage = 32, armor = 2.5, gold = 55, xp = 75 },
        -- hard
        npc_arena_ice_frostbitten_shaman = {
            health = 1150, damage = 42, armor = 2, gold = 100, xp = 90,
            -- Coat an ally before it is badly hurt: the shell is armour, not healing.
            ai = { arena_ice_rime_shell = { ally_health_below = 0.85 } },
        },
        npc_arena_ice_rimebloat = { health = 1700, damage = 55, armor = 3, gold = 105, xp = 95 },
        -- elite
        npc_arena_ice_ogreseal_brute = {
            health = 4000, damage = 115, armor = 7, gold = 240, xp = 220,
            -- Slam only when the target is well inside the 350 ring, so stepping out is possible.
            ai = { arena_ice_shatter_slam = { radius = 275 } },
        },
        npc_arena_ice_rime_revenant = { health = 2600, damage = 85, armor = 5, gold = 180, xp = 150 },
        -- Not a camp monster: the boss's Absolute Zero raises these pillars itself. Listed here
        -- (and in boss.lua `summons`) only so the unit is precached; it is in no group.
        npc_arena_ice_glacial_pillar = { health = 1000, damage = 0, armor = 0, gold = 0, xp = 0 },
    },

    tiers = {
        [1] = {
            { "npc_arena_ice_frost_kobold", "npc_arena_ice_frost_kobold", "npc_arena_ice_frostbitten_thrall" },
            { "npc_arena_ice_snow_gnoll", "npc_arena_ice_snow_gnoll", "npc_arena_ice_frost_kobold" },
            { "npc_arena_ice_frostbitten_thrall", "npc_arena_ice_frostbitten_thrall", "npc_arena_ice_snow_gnoll" },
        },
        [2] = {
            { "npc_arena_ice_tuskarr_raider", "npc_arena_ice_frost_kobold", "npc_arena_ice_frost_kobold" },
            { "npc_arena_ice_rime_wraith", "npc_arena_ice_rime_wraith", "npc_arena_ice_snow_gnoll" },
            { "npc_arena_ice_tuskarr_raider", "npc_arena_ice_rime_wraith" },
        },
        [3] = {
            { "npc_arena_ice_rimebloat", "npc_arena_ice_rime_wraith", "npc_arena_ice_rime_wraith" },
            { "npc_arena_ice_frostbitten_shaman", "npc_arena_ice_tuskarr_raider", "npc_arena_ice_tuskarr_raider" },
            { "npc_arena_ice_frostbitten_shaman", "npc_arena_ice_rimebloat" },
        },
        [4] = {
            -- the shatter pack: the wraith and shaman chill, the ogre-seal breaks the ice
            { "npc_arena_ice_ogreseal_brute", "npc_arena_ice_frostbitten_shaman", "npc_arena_ice_rime_wraith" },
            { "npc_arena_ice_rime_revenant", "npc_arena_ice_rimebloat", "npc_arena_ice_rimebloat" },
            { "npc_arena_ice_ogreseal_brute", "npc_arena_ice_rime_revenant" },
        },
    },

    loot = {
        [3] = { "item_arena_cinder_heart" },
        [4] = { "item_arena_runed_mantle" },
    },
}
