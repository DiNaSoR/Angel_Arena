-- Every particle, sound and model the desert biome's scripts use, so they can be precached and
-- checked (python tools/biomes/check_assets.py desert). Unit models and attack sounds are in
-- the unit file (npc/units/arena/arena_desert_units.txt) and are precached with the units.
-- Loaded on the client too: plain data only.

local HERO = "particles/units/heroes/"

return {
    particles = {
        -- burrowing (Oasis Lurker's Ambush, the boss's Undermine)
        burrow = HERO .. "hero_nyx_assassin/nyx_assassin_burrow.vpcf",
        emerge = HERO .. "hero_nyx_assassin/nyx_assassin_burrow_exit.vpcf",
        -- sand in the eyes (Dust Kick, Sandstorm, Sirocco)
        dust_kick = "particles/neutral_fx/neutral_centaur_khan_war_stomp.vpcf",
        blinded = HERO .. "hero_keeper_of_the_light/keeper_of_the_light_blinding_light_debuff.vpcf",
        sandstorm = HERO .. "hero_sandking/sandking_sandstorm.vpcf",
        gust = HERO .. "hero_sandking/sandking_burrowstrike.vpcf",
        -- venom (Withering Venom, Caustic Venom)
        venom = HERO .. "hero_sandking/sandking_caustic_finale_debuff.vpcf",
        venom_burst = HERO .. "hero_sandking/sandking_caustic_finale_explode.vpcf",
        -- the sun (Sun Brand, Heat Shimmer)
        brand_mark = HERO .. "hero_sniper/sniper_crosshair.vpcf",
        danger_ring = "particles/ui_mouseactions/range_display.vpcf",
        brand_blast = HERO .. "hero_invoker/invoker_sun_strike.vpcf",
        shimmer = HERO .. "hero_windrunner/windrunner_windrun.vpcf",
        -- the ground giving way (Quicksand, Dune Slam, Dune Collapse)
        sunk = "particles/neutral_fx/dark_troll_ensnare.vpcf",
        slam = "particles/neutral_fx/roshan_slam.vpcf",
        collapse = HERO .. "hero_sandking/sandking_sandstorm_burrowstrike_field_explosion.vpcf",
        boss_cast = HERO .. "hero_sandking/sandking_epicenter_tell.vpcf",
    },
    sounds = {
        burrow_in = "Hero_NyxAssassin.Burrow.In",
        burrow_out = "Hero_NyxAssassin.Burrow.Out",
        dust_kick = "n_creep_Centaur.Stomp",
        venom_burst = "Ability.SandKing_CausticFinale",
        brand_cast = "Hero_Invoker.SunStrike.Charge",
        brand_blast = "Hero_Invoker.SunStrike.Ignite",
        shimmer = "Hero_PhantomAssassin.Blur",
        quicksand = "Ability.SandKing_SandStorm.start",
        slam = "n_creep_Thunderlizard_Big.Stomp",
        sandstorm = "Ability.SandKing_SandStorm.start",
        sandstorm_loop = "Ability.SandKing_SandStorm.loop",
        gust = "Ability.SandKing_BurrowStrike",
        collapse_cast = "Ability.SandKing_Epicenter.spell",
        collapse = "Hero_Sandking.EpiPulse",
        awaken = "Ability.SandKing_SandStorm.start",
        phase = "Ability.SandKing_Epicenter",
        death = "Hero_SandKing.Death",
    },
    soundfiles = {
        "soundevents/game_sounds_heroes/game_sounds_sandking.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_nyx_assassin.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_phantom_assassin.vsndevts",
    },
    models = {
        "models/heroes/sand_king/sand_king_head.vmdl",
        "models/heroes/sand_king/sand_king_shoulder.vmdl",
        "models/heroes/sand_king/sand_king_arms.vmdl",
        "models/heroes/sand_king/sand_king_legs.vmdl",
        "models/heroes/sand_king/sand_king_tail.vmdl",
    },
}
