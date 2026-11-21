-- Every particle, sound and model the lava biome's scripts use, so they can be precached and
-- checked (python tools/biomes/check_assets.py lava). Unit models, attack projectiles and attack
-- sounds are in the unit file (npc/units/arena/arena_lava_units.txt) and are precached with the
-- units. Loaded on the client too: plain data only.
--
-- Control points: effects passed to ArenaFxCore.Burst with a radius get it on CP1;
-- burning_ground is attached to its thinker with CP1 = (radius, 0, 0) like Doom's Scorched Earth.

local HERO = "particles/units/heroes/"

return {
    particles = {
        heat = HERO .. "hero_huskar/huskar_burning_spear_debuff.vpcf",
        melting = HERO .. "hero_doom_bringer/doom_infernal_blade_debuff.vpcf",
        burning = HERO .. "hero_doom_bringer/doom_bringer_scorched_earth_debuff.vpcf",
        burning_ground = HERO .. "hero_doom_bringer/doom_scorched_earth.vpcf",
        eruption = HERO .. "hero_lina/lina_spell_light_strike_array.vpcf",
        meteor = HERO .. "hero_invoker/invoker_sun_strike.vpcf",
        blast = HERO .. "hero_techies/techies_land_mine_explode.vpcf",
        spit = HERO .. "hero_ogre_magi/ogre_magi_ignite.vpcf",
        brand = HERO .. "hero_doom_bringer/doom_bringer_doom.vpcf",
        kindle = HERO .. "hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf",
        golem_aura = HERO .. "hero_warlock/golem_ambient.vpcf",
        presence = "particles/items2_fx/radiance_owner.vpcf",
        boss_cast = HERO .. "hero_warlock/warlock_rain_of_chaos_start.vpcf",
        heart_blast = HERO .. "hero_phoenix/phoenix_supernova_reborn.vpcf",
    },
    sounds = {
        sprite_blast = "Warlock_Imp.Explode",
        golem_blast = "Hero_Techies.Suicide",
        melting = "Hero_DoomBringer.InfernalBlade.Target",
        spit = "Hero_OgreMagi.Ignite.Cast",
        spit_hit = "Hero_OgreMagi.Ignite.Target",
        slam_charge = "Ability.PreLightStrikeArray",
        eruption = "Ability.LightStrikeArray",
        brand = "Hero_DoomBringer.Doom",
        brand_blast = "Hero_OgreMagi.Fireblast.Target",
        kindle = "Hero_OgreMagi.Bloodlust.Target",
        bomb_cast = "n_black_dragon.Fireball.Cast",
        bomb = "n_black_dragon.Fireball.Target",
        breath = "Hero_DragonKnight.BreathFire",
        caldera_cast = "Hero_Warlock.RainOfChaos_buildup",
        barrage_cast = "Hero_Invoker.ChaosMeteor.Cast",
        meteor = "Hero_Invoker.ChaosMeteor.Impact",
        heart_channel = "Hero_Phoenix.SuperNova.Begin",
        heart_blast = "Hero_Phoenix.SuperNova.Explode",
        summon = "Hero_Invoker.ForgeSpirit",
        awaken = "Hero_Warlock.RainOfChaos",
        phase = "Hero_Invoker.Cataclysm.Ignite",
        death = "Hero_DoomBringer.Death",
    },
    soundfiles = {
        "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_warlock.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_lina.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_huskar.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_phoenix.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts",
        "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts",
    },
    models = {
        "models/heroes/doom/doom_sword.vmdl",
        "models/heroes/doom/doom_helm.vmdl",
        "models/heroes/doom/shoulders.vmdl",
        "models/heroes/doom/bracer.vmdl",
        "models/heroes/doom/belt.vmdl",
        "models/heroes/doom/wings.vmdl",
        "models/heroes/doom/tail.vmdl",
    },
}
