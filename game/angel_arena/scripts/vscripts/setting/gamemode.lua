--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------
function 	GameMode:InitGameMode()
		GameMode = self	
		print( "[Angel Arena] InitGameMode Started." )
				
		--self:ReadGameConfiguration()

		
	-- Setup Rules
		GameRules:GetGameModeEntity().GameMode = self
		GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
		GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
		GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
		GameRules:SetCustomGameSetupTimeout( CUSTOM_GAME_SETUP_TIME )
		GameRules:SetHeroSelectionTime( HERO_SELECTION_TIME )
		GameRules:SetPreGameTime( PRE_GAME_TIME)
		GameRules:SetPostGameTime( POST_GAME_TIME )
		GameRules:SetTreeRegrowTime( TREE_REGROW_TIME )
		GameRules:SetUseCustomHeroXPValues ( USE_CUSTOM_XP_VALUES )
		GameRules:SetGoldPerTick(GOLD_PER_TICK)
		GameRules:SetGoldTickTime(GOLD_TICK_TIME)
		GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
		GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
		GameRules:SetHeroMinimapIconScale( MINIMAP_ICON_SIZE )
		GameRules:SetCreepMinimapIconScale( MINIMAP_CREEP_ICON_SIZE )
		GameRules:SetRuneMinimapIconScale( MINIMAP_RUNE_ICON_SIZE )

		GameRules:SetFirstBloodActive( ENABLE_FIRST_BLOOD )
  		GameRules:SetHideKillMessageHeaders( HIDE_KILL_BANNERS )

		GameRules:SetCustomGameEndDelay( GAME_END_DELAY )
		GameRules:SetCustomVictoryMessageDuration( VICTORY_MESSAGE_DURATION )
		GameRules:SetStartingGold( STARTING_GOLD )
				
	if SKIP_TEAM_SETUP then
    	GameRules:SetCustomGameSetupAutoLaunchDelay( 0 )
    	GameRules:LockCustomGameSetupTeamAssignment( true )
    	GameRules:EnableCustomGameSetupAutoLaunch( true )
    	GameRules:SetStrategyTime( 0 )
    	GameRules:SetShowcaseTime( 0 )
  		else
    	GameRules:SetCustomGameSetupAutoLaunchDelay( AUTO_LAUNCH_DELAY )
    	GameRules:LockCustomGameSetupTeamAssignment( LOCK_TEAM_SETUP )
    	GameRules:EnableCustomGameSetupAutoLaunch( ENABLE_AUTO_LAUNCH )
	end


  	--This is multiteam configuration stuff
	if USE_AUTOMATIC_PLAYERS_PER_TEAM then
		local num = math.floor(10 / MAX_NUMBER_OF_TEAMS)
		local count = 0
		for team,number in pairs(TEAM_COLORS) do
			if count >= MAX_NUMBER_OF_TEAMS then
				GameRules:SetCustomGameTeamMaxPlayers(team, 0)
			else
				GameRules:SetCustomGameTeamMaxPlayers(team, num)
			end
			count = count + 1
		end
	else
		local count = 0
		for team,number in pairs(CUSTOM_TEAM_PLAYER_COUNT) do
		if count >= MAX_NUMBER_OF_TEAMS then
			GameRules:SetCustomGameTeamMaxPlayers(team, 0)
		else
			GameRules:SetCustomGameTeamMaxPlayers(team, number)
		end
		count = count + 1
		end
	end

	if USE_CUSTOM_TEAM_COLORS then
		for team,color in pairs(TEAM_COLORS) do
		SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
		end
	end
		
		-- OTHERS
		--InitLogFile( "log/AngelArena.txt","")
		
				
		-- All Listen
		ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(GameMode, 'OnPlayerLevelUp'), self)
		ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(GameMode, 'OnPlayerLearnedAbility'), self)
		ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap( GameMode, 'OnPlayerPickHero' ), self )
		ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(GameMode, 'OnPlayerTakeTowerDamage'), self)
		ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
		ListenToGameEvent('dota_player_begin_cast', Dynamic_Wrap(GameMode, 'OnAbilityCastBegins'), self)
		ListenToGameEvent('dota_player_selected_custom_team', Dynamic_Wrap(GameMode, 'OnPlayerSelectedCustomTeam'), self)
		--ListenToGameEvent('dota_player_killed', Dynamic_Wrap(GameMode, 'OnHeroKilled'), self)
  
		ListenToGameEvent("dota_illusions_created", Dynamic_Wrap(GameMode, 'OnIllusionsCreated'), self)
  		ListenToGameEvent("dota_item_combined", Dynamic_Wrap(GameMode, 'OnItemCombined'), self)
  		ListenToGameEvent("dota_tower_kill", Dynamic_Wrap(GameMode, 'OnTowerKill'), self)
		ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(GameMode, 'OnNonPlayerUsedAbility'), self)
		ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
		ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(GameMode, 'OnAbilityChannelFinished'), self)
		ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(GameMode, 'OnTeamKillCredit'), self)
		ListenToGameEvent("dota_npc_goal_reached", Dynamic_Wrap(GameMode, 'OnNPCGoalReached'), self)
		
		ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
		ListenToGameEvent('player_changename', Dynamic_Wrap(GameMode, 'OnPlayerChangedName'), self)
		ListenToGameEvent('player_disconnect', Dynamic_Wrap(GameMode, 'OnDisconnect'), self)
		ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
		ListenToGameEvent("player_reconnected", Dynamic_Wrap(GameMode, 'OnPlayerReconnect'), self)

		ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
		ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
		
		ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
		ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)
		ListenToGameEvent('last_hit', Dynamic_Wrap(GameMode, 'OnLastHit'), self)

		ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
		ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
		ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, 'OnPlayerChat'), self)
		ListenToGameEvent('tree_cut', Dynamic_Wrap(GameMode, 'OnTreeCut'), self)

		
		-- Change random seed
		local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
		math.randomseed(tonumber(timeTxt))

		-- Initialized tables for tracking state
		self.spellList = {"skill_bag_of_gold"}
		self.vUserIds = {}
		self.vSteamIds = {}

		self.vPlayers = {}
		self.vRadiant = {}
		self.vDire = {}

		self.nRadiantKills = 0
		self.nDireKills = 0

		GameRules.CURRENT_SOUNDTRACK = 0

		self.bSeenWaitForPlayers = false

		self.PLAYER_COLOR_BY_ID = {
			[0] = "#3375FF",
			[1] = "#66FFBF",
			[2] = "#BF00BF",
			[3] = "#F3F00B",
			[4] = "#FF6B00",
			[5] = "#FE86C2",
			[6] = "#A1B447",
			[7] = "#65D9F7",
			[8] = "#008321",
			[9] = "#A46900"
		}
		
		-- Barebones_spew
			local spew = 0
			if BAREBONES_DEBUG_SPEW then
				spew = 1
			end
			Convars:RegisterConvar('barebones_spew', tostring(spew), 'Set to 1 to start spewing barebones debug info.  Set to 0 to disable.', 0)
		
		-- Store and update selected units of each pID
			--GameRules.SELECTED_UNITS = {}

		-- Spawn Locations and Area Activations

		-- Make separate lists based on creepName to randomize spawn locations later
		-- These lists store the entity handles of every spawn location on the map (actual location is accessed via :GetOrigin())
		-- Spawn name entity format guide: creepName_spawner
		-- Dont repeat creepNames, just make new copies of the unit if thats the case

		-- Spawner entities named: creepName_spawner
		-- Also, they are fricking Satyrs, not golins, what the hell :D

			-- Demon Area
		--GameMode.demon_imp_spawnLocations = Entities:FindAllByName("npc_demon_imp_spawner")
		--GameMode.DemonAreaCreeps = {} -- Keep a list of all creeps in the area

		Teams:Initialize()
		PlayerTables:CreateTable("arena", {}, AllPlayersInterval)
		PlayerTables:CreateTable("player_hero_indexes", {}, AllPlayersInterval)
		PlayerTables:CreateTable("players_abandoned", {}, AllPlayersInterval)
		PlayerTables:CreateTable("gold", {}, AllPlayersInterval)
		PlayerTables:CreateTable("disable_help_data", {[0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}, [7] = {}, [8] = {}, [9] = {}, [10] = {}, [11] = {}, [12] = {}, [13] = {}, [14] = {}, [15] = {}, [16] = {}, [17] = {}, [18] = {}, [19] = {}, [20] = {}, [21] = {}, [22] = {}, [23] = {}}, AllPlayersInterval)



		print('[Angel Arena] InitGameMode Ended.')
end


--------------------------------------------------------------
-- CaptureGameMode
-- This function is called as the first player loads and sets up the GameMode parameters
--------------------------------------------------------------
mode = nil
function GameMode:CaptureGameMode()
	if mode == nil then
	print('[Angel Arena] CaptureGameMode Started.')

				-- Set GameMode parameters
				mode = GameRules:GetGameModeEntity()        
				mode:SetRecommendedItemsDisabled( RECOMMENDED_BUILDS_DISABLED )
				mode:SetCameraDistanceOverride( CAMERA_DISTANCE_OVERRIDE )
				mode:SetCustomBuybackCostEnabled( CUSTOM_BUYBACK_COST_ENABLED )
				mode:SetCustomBuybackCooldownEnabled( CUSTOM_BUYBACK_COOLDOWN_ENABLED )
				mode:SetBuybackEnabled( BUYBACK_ENABLED )
				mode:SetTopBarTeamValuesOverride ( USE_CUSTOM_TOP_BAR_VALUES )
				mode:SetTopBarTeamValuesVisible( TOP_BAR_VISIBLE )
				mode:SetUseCustomHeroLevels ( USE_CUSTOM_HERO_LEVELS )
				mode:SetCustomHeroMaxLevel ( MAX_LEVEL )
				mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )
				mode:SetUnseenFogOfWarEnabled( USE_UNSEEN_FOG_OF_WAR )
				--mode:SetFountainConstantManaRegen( FOUNTAIN_CONSTANT_MANA_REGEN )
    			--mode:SetFountainPercentageHealthRegen( FOUNTAIN_PERCENTAGE_HEALTH_REGEN )
    			--mode:SetFountainPercentageManaRegen( FOUNTAIN_PERCENTAGE_MANA_REGEN )
				
				mode:SetAlwaysShowPlayerInventory( SHOW_ONLY_PLAYER_INVENTORY )
    			mode:SetAnnouncerDisabled( DISABLE_ANNOUNCER )

				mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
				mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

				mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
				mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
				mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )

			if FORCE_PICKED_HERO ~= nil then
      			mode:SetCustomGameForceHero( FORCE_PICKED_HERO )
    		end
				mode:SetFixedRespawnTime( FIXED_RESPAWN_TIME )
				mode:SetLoseGoldOnDeath( LOSE_GOLD_ON_DEATH )
				mode:SetMaximumAttackSpeed( MAXIMUM_ATTACK_SPEED )
				mode:SetMinimumAttackSpeed( MINIMUM_ATTACK_SPEED )
				mode:SetStashPurchasingDisabled ( DISABLE_STASH_PURCHASING )

    		for rune, spawn in pairs(ENABLED_RUNES) do
      			mode:SetRuneEnabled(rune, spawn)
    		end

				mode:SetDaynightCycleDisabled( DISABLE_DAY_NIGHT_CYCLE )
				mode:SetKillingSpreeAnnouncerDisabled( DISABLE_KILLING_SPREE_ANNOUNCER )
				mode:SetStickyItemDisabled( DISABLE_STICKY_ITEM )

				--self:OnFirstPlayerLoaded()
	print('[Angel Arena] CaptureGameMode Ended.')
	end 
end
--------------------------------------------------------------
-- Apocalypse GameMode
--------------------------------------------------------------
require('mechanics/spawn/zombie/spawner')
require('mechanics/spawn/boomber/spawner')