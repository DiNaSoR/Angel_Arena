-- Every particle, sound and model the green biome's scripts use, so they can be precached and
-- checked (python tools/biomes/check_assets.py green). Unit models and attack sounds are in
-- the unit file (npc/units/arena/arena_green_units.txt) and are precached with the units.
-- Loaded on the client too: plain data only.

local HERO = "particles/units/heroes/"

return {
    particles = {
        thorn_shot = "particles/neutral_fx/pine_cone_seed_shot_tracking.vpcf",
        thorned = HERO .. "hero_treant/treant_leech_seed.vpcf",
        rooted = HERO .. "hero_treant/treant_overgrowth_vines.vpcf",
        root_burst = HERO .. "hero_treant/treant_bramble_root.vpcf",
        slam = HERO .. "hero_centaur/centaur_warstomp.vpcf",
        spore_cloud = HERO .. "hero_alchemist/alchemist_acid_spray.vpcf",
        sickness = HERO .. "hero_venomancer/venomancer_gale_poison_debuff.vpcf",
        sap = "particles/neutral_fx/troll_heal.vpcf",
        bark = HERO .. "hero_treant/treant_livingarmor.vpcf",
        venom_spit = HERO .. "hero_venomancer/venomancer_base_attack.vpcf",
        venom = HERO .. "hero_venomancer/venomancer_poison_debuff.vpcf",
        boss_cast = HERO .. "hero_treant/treant_overgrowth_cast.vpcf",
        summon = HERO .. "hero_furion/furion_force_of_nature_cast.vpcf",
        sprout = HERO .. "hero_furion/furion_sprout.vpcf",
    },
    sounds = {
        thorn_shot = "Hero_Windrunner.ShackleshotCast",
        thorn_hit = "Hero_Windrunner.ProjectileImpact",
        bite = "LoneDruid_SpiritBear.Entangle",
        slam = "Hero_Centaur.HoofStomp",
        spore_cloud = "Hero_Alchemist.AcidSpray",
        sap = "Hero_Treant.LeechSeed.Cast",
        root = "Hero_Treant.Overgrowth.Target",
        bark = "Hero_Treant.LivingArmor.Cast",
        venom_spit = "Hero_Venomancer.VenomousGale",
        venom_hit = "Hero_Venomancer.VenomousGaleImpact",
        eruption_cast = "Hero_Treant.Overgrowth.CastAnim",
        eruption = "Hero_Treant.NaturesGrasp.Spawn",
        nova_channel = "Hero_ElderTitan.EchoStomp.Channel",
        nova = "Hero_Treant.NaturesGrasp.Damage",
        timber_cast = "Hero_Tiny.Tree.Throw",
        timber = "Hero_Tiny_Tree.Impact",
        summon = "Hero_Furion.ForceOfNature",
        awaken = "Hero_Treant.Overgrowth.Cast",
        phase = "Hero_Furion.TreantRoar",
        death = "Hero_Treant.Death",
    },
    soundfiles = {
        "soundevents/game_sounds_heroes/game_sounds_treant.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_furion.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_lone_druid.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_centaur.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_alchemist.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_venomancer.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_windrunner.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_elder_titan.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_tiny.vsndevts",
    },
    models = {
        "models/heroes/treant_protector/head.vmdl",
        "models/heroes/treant_protector/foliage.vmdl",
        "models/heroes/treant_protector/hands.vmdl",
        "models/heroes/treant_protector/legs.vmdl",
    },
}
