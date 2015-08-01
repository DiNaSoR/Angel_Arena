---------------------------------------------------------------------------
-- Required .lua files
---------------------------------------------------------------------------
require('Spawn/spawn')
require('Spawn/miniboss')
--LIB
require('Lib/timers')
require('Lib/aa')
require('Lib/popups')
require('Lib/notifications')
require('Lib/luaCommand')
require('Lib/teleports')
require('Lib/utilities')
require('Lib/util')
require('Lib/msg')
--Mechanics
require('Mechanics/dropsys')
require('Mechanics/duel')
require('Mechanics/onItempickthinker')







--------------------------------------------------------------
-- Precache
--------------------------------------------------------------

function Precache( context )

	print("Loading precache")
			
	
	--Precache things we know we'll use.  Possible file types include (but not limited to):
	--PrecacheResource( "model", "*.vmdl", context )
	--PrecacheResource( "soundfile", "*.vsndevts", context )
	--PrecacheResource( "particle", "*.vpcf", context )
	--PrecacheResource( "particle_folder", "particles/folder", context )
	-- These units could be on Async if we just waited a bit more to spawn them
	

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


	-- Cosmetic item particles, should precache them individually
	--PrecacheResource( "particle_folder", "particles/econ/items", context )


	-- Precache world models
	PrecacheResource( "model", "models/props_debris/merchant_debris_book001.vmdl", context )
	PrecacheResource( "model", "models/props_gameplay/gold_coin001.vmdl", context )
	PrecacheResource( "model_folder", "models/heroes/invoker", context )
	PrecacheResource( "model_folder", "models/heroes/slark", context)
	PrecacheResource( "model_folder", "models/items/slark", context)
	PrecacheResource( "model_folder", "models/heroes/pudge", context)
	PrecacheResource( "model_folder", "models/heroes/undying", context)
	--PrecacheResource( "model_folder", "models/items/warlock/warlock_fourleg_demon.vmdl", context)
	PrecacheResource( "model_folder", "models/heroes/shadow_fiend", context)
	PrecacheResource( "model", "models/props_structures/gravestone005.vmdl", context)


	print("Loading precache End")
end
--------------------------------------------------------------
-- Activate
--------------------------------------------------------------
-- Create the game mode when we activate
function Activate()	
		GameRules.GameMode = GameMode()
		GameRules.GameMode:InitGameMode()
						
end

