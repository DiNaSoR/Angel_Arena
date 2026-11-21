-- Every particle, sound and model the ice biome's scripts use, so they can be precached and
-- checked (python tools/biomes/check_assets.py ice). Unit models and attack sounds are in the
-- unit file (npc/units/arena/arena_ice_units.txt) and are precached with the units.
-- Loaded on the client too: plain data only.
--
-- Control points the scripts set (only an in-game look confirms the effect reads them):
--   ArenaFxCore.Burst sets 0 = position, 1 = (radius, radius, radius).
--   blizzard      0 = centre, 1 and 5 = (radius, radius, radius)   (Ice Vortex reads 5)
--   whiteout_snow 0 follows the boss, 1 = (radius, radius, 1)      (Freezing Field's snow)
--   breath        a linear projectile: the engine sets its control points

local HERO = "particles/units/heroes/"

return {
    particles = {
        -- the cold every ice monster shares
        chilled = "particles/generic_gameplay/generic_slowed_cold.vpcf",
        chilled_status = "particles/status_fx/status_effect_frost.vpcf",
        frozen = HERO .. "hero_ancient_apparition/ancient_apparition_cold_feet_frozen.vpcf",
        frozen_status = "particles/status_fx/status_effect_frost_lich.vpcf",
        shatter = HERO .. "hero_crystalmaiden/maiden_freezing_field_explosion.vpcf",
        brittle = HERO .. "hero_ancient_apparition/ancient_apparition_ice_blast_debuff.vpcf",
        brittle_status = "particles/status_fx/status_effect_iceblast_half.vpcf",
        -- camp abilities
        rime_bolt = HERO .. "hero_ancient_apparition/ancient_apparition_chilling_touch_projectile.vpcf",
        blizzard = HERO .. "hero_ancient_apparition/ancient_ice_vortex.vpcf",
        rime_shell = HERO .. "hero_lich/lich_ice_age.vpcf",
        rime_shell_status = "particles/status_fx/status_effect_frost_armor.vpcf",
        nova = HERO .. "hero_lich/lich_frost_nova.vpcf",
        -- the boss
        breath = HERO .. "hero_jakiro/jakiro_dual_breath_ice.vpcf",
        icefall = HERO .. "hero_crystalmaiden/maiden_freezing_field_explosion.vpcf",
        whiteout_snow = HERO .. "hero_crystalmaiden/maiden_freezing_field_snow.vpcf",
        zero_channel = HERO .. "hero_crystalmaiden/maiden_freezing_field_caster.vpcf",
        pillar = HERO .. "hero_tusk/tusk_frozen_sigil.vpcf",
    },
    sounds = {
        chill_freeze = "Hero_Ancient_Apparition.ColdFeetFreeze",
        shatter = "Hero_Ancient_Apparition.IceBlast.Target",
        rime_bolt = "Hero_Ancient_Apparition.ChillingTouch.Cast",
        rime_bolt_hit = "Hero_Ancient_Apparition.ChillingTouch.Target",
        brittle = "Hero_Tusk.WalrusPunch.Target",
        blizzard = "Hero_Ancient_Apparition.IceVortexCast",
        rime_shell = "Hero_Lich.IceAge",
        rime_shell_hit = "Hero_Lich.IceAge.Tick",
        burst = "Hero_Crystal.CrystalNova",
        slam = "Hero_Tusk.IceShards",
        tomb_cast = "Hero_Ancient_Apparition.ColdFeetCast",
        tomb = "Hero_Ancient_Apparition.ColdFeetFreeze",
        breath = "Hero_Jakiro.DualBreath",
        icefall_cast = "Hero_Winter_Wyvern.SplinterBlast.Cast",
        icefall = "hero_Crystal.freezingField.explosion",
        zero_channel = "hero_Crystal.freezingField.wind",
        zero = "Hero_Ancient_Apparition.IceBlastRelease.Cast",
        pillar = "Hero_Lich.IceSpire",
        pillar_break = "Hero_Lich.IceSpire.Destroy",
        awaken = "Hero_Ancient_Apparition.IceBlastRelease.Cast",
        phase = "Hero_Lich.IceAge",
        death = "Hero_Tusk.Death",
    },
    soundfiles = {
        "soundevents/game_sounds_heroes/game_sounds_ancient_apparition.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_crystalmaiden.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_lich.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_tusk.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_jakiro.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_winter_wyvern.vsndevts",
    },
    models = {
        -- the ice pillars of Absolute Zero (npc_arena_ice_glacial_pillar)
        "models/heroes/lich/ice_spire.vmdl",
    },
}
