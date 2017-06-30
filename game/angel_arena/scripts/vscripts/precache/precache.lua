if PrecacheManager == nil then PrecacheManager = class({}) end

function PrecacheManager:StartPrecache( context )
	print("Angel Arena Loading precache")

	--Precache things we know we'll use.  Possible file types include (but not limited to):
	--PrecacheResource( "model", "*.vmdl", context )
	--PrecacheResource( "soundfile", "*.vsndevts", context )
	--PrecacheResource( "particle", "*.vpcf", context )
	--PrecacheResource( "particle_folder", "particles/folder", context )
	-- These units could be on Async if we just waited a bit more to spawn them
	PrecacheUnitByNameSync("npc_lord_of_death_boss", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_rattletrap.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_nevermore.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/voscripts/game_sounds_vo_pudge.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_chen.vsndevts", context)
	
	
	
	-- Precache sounds
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_dragon_knight.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_abaddon.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_sven.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_lina.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_ancient_apparition.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_obsidian_destroyer.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_necrolyte.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_crystalmaiden.vsndevts", context)
	PrecacheResource( "soundfile", "soundevents/music/valve_dota_001/stingers/game_sounds_stingers.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_stingers_diretide.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_creeps.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/custom_sounds.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_items.vsndevts", context )
	

	-- Precache particles required by various world effects

	PrecacheResource( "particle", "particles/items_fx/aegis_respawn_aegis_starfall.vpcf", context )
	PrecacheResource( "particle", "particles/neutral_fx/roshan_death_aegis_trail.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_chen/chen_holy_persuasion_a.vpcf", context )
	PrecacheResource( "particle", "particles/items_fx/aegis_respawn.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_faceless_void/faceless_void_time_walk.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_clinkz/clinkz_strafe.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/kunkka/kunkka_tidebringer_base/kunkka_spell_tidebringer.vpcf", context )

	PrecacheResource( "particle", "particles/units/heroes/hero_chen/chen_hand_of_god.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_chen/chen_cast_4.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", context )

	PrecacheResource( "particle", "particles/generic_gameplay/generic_stunned_old.vpcf", context )
	PrecacheResource( "particle", "particles/items_fx/chain_lightning.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", context )
	PrecacheResource( "particle", "particles/generic_gameplay/generic_stunned_old.vpcf", context )
	

	
	
	
	--Hero shadow demon
	PrecacheResource( "particle", "particles/units/heroes/hero_shadow_demon/sd_w.vpcf", context )
	--tombAgiPreach
	PrecacheResource( "particle", "particles/econ/courier/courier_trail_international_2013/courier_international_2013.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_green.vpcf", context )
	PrecacheResource( "particle", "particles/sweep_generic/sweep_1.vpcf", context )
	--tombStrPreach
	PrecacheResource( "particle", "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_red.vpcf", context )
	PrecacheResource( "particle", "particles/sweep_generic/sweep_2.vpcf", context )
	PrecacheResource( "particle", "particles/econ/courier/courier_greevil_orange/courier_greevil_orange_ambient_3.vpcf", context )
	--tombIntPreach
	PrecacheResource( "particle", "particles/units/heroes/hero_dragon_knight/dragon_knight_transform_blue.vpcf", context )
	PrecacheResource( "particle", "particles/items2_fx/shivas_guard_impact.vpcf", context )
	PrecacheResource( "particle", "particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf", context )

	--Tower auras
	PrecacheResource( "particle", "particles/units/heroes/hero_skeletonking/wraith_king_vampiric_aura_lifesteal.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_omniknight/omniknight_degen_aura.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_essence_effect.vpcf", context )
	PrecacheResource( "particle", "particles/econ/items/spirit_breaker/spirit_breaker_weapon_empowering_elements/spirit_breaker_ambient_flame_empowering_elements.vpcf", context )
	
	--Heroes paricles
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_pudge", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_spirit_breaker", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_obsidian_destroyer", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_omniknight", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_necrolyte", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_skeletonking", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_beastmaster", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_ursa", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_slark", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_warlock", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_invoker", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_warlock", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_invoker", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_slark", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_bloodseeker", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_queenofpain", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_undying", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_juggernaut", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_clinkz", context)
	PrecacheResource( "particle_folder", "particles/econ/items/kunkka/", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_kunkka/", context)
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_faceless_void/", context)
	PrecacheResource( "particle_folder", "particles/econ/items/faceless_void/", context)

	
	--Units Hero Spirit
	PrecacheResource( "model_folder", "models/heroes/ember_spirit/", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_ember_spirit/", context)
	PrecacheResource( "model", "models/items/ember_spirit/crimson_guard_of_prosperity/crimson_guard_of_prosperity.vmdl", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_ember_spirit.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/voscripts/game_sounds_vo_ember_spirit.vsndevts", context )
	PrecacheResource( "particle", "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf", context )
	PrecacheResource( "particle", "particles/econ/courier/courier_drodo/courier_drodo_ambient_death_b.vpcf", context )
	PrecacheResource( "particle", "particles/items2_fx/shadow_amulet_activate_runes.vpcf", context )
	PrecacheResource( "model", "models/items/ember_spirit/blazearmor_head/blazearmor_head.vmdl", context )

	PrecacheResource( "particle", "particles/econ/items/mirana/mirana_crescent_arrow/mirana_spell_crescent_arrow.vpcf", context )
	--PrecacheResource( "particle", "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf", context )
	
	


	
	
	
	
	
	
	
	
	


	-- Cosmetic item particles, should precache them individually
	--PrecacheResource( "particle_folder", "particles/econ/items", context )


	-- Precache world models
	PrecacheResource( "model", "models/props_debris/merchant_debris_book001.vmdl", context )
	PrecacheResource( "model", "models/props_gameplay/gold_coin001.vmdl", context )
	PrecacheResource( "model", "models/heroes/broodmother/spiderling.vmdl", context )
	PrecacheResource( "model_folder", "models/heroes/invoker/", context )
	PrecacheResource( "model_folder", "models/heroes/slark/", context)
	PrecacheResource( "model_folder", "models/items/slark/", context)
	PrecacheResource( "model_folder", "models/heroes/pudge/", context)
	PrecacheResource( "model_folder", "models/heroes/undying/", context)
	PrecacheResource( "model_folder", "models/heroes/juggernaut/", context)
	PrecacheResource( "model_folder", "models/items/juggernaut/", context)


	--PrecacheResource( "model_folder", "models/items/warlock/warlock_fourleg_demon.vmdl", context)
	PrecacheResource( "model_folder", "models/heroes/shadow_fiend/", context)
	PrecacheResource( "model", "models/props_structures/gravestone005.vmdl", context)


	print("Angel Arena Loading precache End")
end