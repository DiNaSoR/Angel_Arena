print("Angel Arena aa.lua")
--------------------------------------------------------------
-- Angel Arena Rules
--------------------------------------------------------------
ENABLE_HERO_RESPAWN = true              	-- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = false             	-- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = true        	-- Should we let people select the same hero as each other

HERO_SELECTION_TIME = 15                	-- How long should we let people select their hero?
PRE_GAME_TIME = 5                       	-- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0                   	-- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0                 	-- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_PER_TICK = 10                    		-- How much gold should players get per tick?
GOLD_TICK_TIME = 1                     		-- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = false     	-- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1500         	-- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 1                 		-- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             	-- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1            		-- What icon size should we use for runes?

RUNE_SPAWN_TIME = 120                   	-- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = false      	-- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = false  	-- Should we use a custom buyback time?
BUYBACK_ENABLED = false                 	-- Should we allow people to buyback when they die?

ENABLED_FOG_OF_WAR_ENTIRELY = false
DISABLE_FOG_OF_WAR_ENTIRELY = true			-- Should we disable fog of war entirely for both teams?
--USE_STANDARD_DOTA_BOT_THINKING = false		-- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true		-- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = false			-- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true						-- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true					-- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = false	-- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = true			-- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false					-- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = true					-- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 50				-- How many kills for a team should signify an end of game?

USE_CUSTOM_HERO_LEVELS = false				-- Should we allow heroes to have custom levels?
MAX_LEVEL = 25								-- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = false				-- Should we use custom XP values to level up heroes, or the default Dota numbers?

FOUNTAIN_CONSTANT_MANA_REGEN = -1       	-- What should we use for the constant fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_MANA_REGEN = 20     	-- What should we use for the percentage fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_HEALTH_REGEN = 20   	-- What should we use for the percentage fountain health regen?  Use -1 to keep the default dota behavior.

tHeroes 		= {}
tPlayers 		= {}
nPlayers 		= 0
--[[Future 1v1 duel test system
nPlayers 		= 0
nHeroCount    	= 0
nDeathHeroes  	= 0
nDeathCreeps  	= 0
tPlayers 		= {}
tHeroes 		= {}

PRE_DUEL_TIME = 5
IsDuelOccured = false
IsDuel        = false

ARENA_TELEPORT_COORD_TOP = Vector(5897.54, 4892.11, 17.3543)
ARENA_TELEPORT_COORD_BOT = Vector(5897.54, 2880, 17.3543)
ARENA_CENTER_COORD       = Vector(5897.54, 3904, 17.3543)]]

--------------------------------------------------------------
-- Angel Arena Class
--------------------------------------------------------------
if	GameMode == nil then
	GameMode = class({})
	print("Angel Arena 0.9")
end

--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------
function 	GameMode:InitGameMode()
				GameMode = self
				
				print( "[Main] Angel Arena GameMode is loaded." )
				
				self:ReadGameConfiguration()
				
				--GameRules:SetThink("thinking", self)
				--GameRules:SetThink( "OnThink", self )
				GameRules:SetHeroRespawnEnabled( ENABLE_HERO_RESPAWN )
				GameRules:SetUseUniversalShopMode( UNIVERSAL_SHOP_MODE )
				GameRules:SetSameHeroSelectionEnabled( ALLOW_SAME_HERO_SELECTION )
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
				
				
				InitLogFile( "log/AngelArena.txt","")
				-- OTHERS
				
				-- ALL GAMERULES
				--GameRules:GetGameModeEntity():SetThink( "PopUpThink", self, "PopUpTimer", 2 )
				--GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 )
				
				self.spellList = {"skill_bag_of_gold"}
				
				
				-- ALL LISTEN
				ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(GameMode, 'OnPlayerLevelUp'), self)
				ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
				ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
				ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
				ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)
				ListenToGameEvent('last_hit', Dynamic_Wrap(GameMode, 'OnLastHit'), self)
				ListenToGameEvent('player_changename', Dynamic_Wrap(GameMode, 'OnPlayerChangedName'), self)
				ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
				ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
				--ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(GameMode, 'OnPlayerLearnedAbility'), self)
				ListenToGameEvent( 'dota_player_pick_hero', Dynamic_Wrap( GameMode, 'OnPlayerPickHero' ), self )
				--ListenToGameEvent('player_disconnect', Dynamic_Wrap(GameMode, 'OnDisconnect'), self)
				
				--[[ Possible Use	
				ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
				ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
				ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
				ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(GameMode, 'OnNonPlayerUsedAbility'), self)
				ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(GameMode, 'OnPlayerTakeTowerDamage'), self)
				ListenToGameEvent("player_reconnected", Dynamic_Wrap(GameMode, 'OnPlayerReconnect'), self)
				ListenToGameEvent('tree_cut', Dynamic_Wrap(GameMode, 'OnTreeCut'), self)
				ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
				ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(GameMode, 'OnAbilityChannelFinished'), self)
				]]
				
				-- Change random seed
				local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
				math.randomseed(tonumber(timeTxt))

				-- Initialized tables for tracking state
				self.vUserIds = {}
				self.vSteamIds = {}

				self.vPlayers = {}
				self.vRadiant = {}
				self.vDire = {}

				self.nRadiantKills = 0
				self.nDireKills = 0

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
				
				
				-- Spawn Locations and Area Activations

				-- Make separate lists based on creepName to randomize spawn locations later
				-- These lists store the entity handles of every spawn location on the map (actual location is accessed via :GetOrigin())
				-- Spawn name entity format guide: creepName_spawner
				-- Dont repeat creepNames, just make new copies of the unit if thats the case

				-- Spawner entities named: creepName_spawner
				-- Also, they are fricking Satyrs, not golins, what the hell :D

				 -- Demon Area
				GameMode.demon_imp_spawnLocations = Entities:FindAllByName("npc_demon_imp_spawner")

				GameMode.DemonAreaCreeps = {} -- Keep a list of all creeps in the area


				print('Angel Arena Done loading the gamemode!\n\n')
				
				
			
end

mode = nil
--------------------------------------------------------------
-- CaptureGameMode
-- This function is called as the first player loads and sets up the GameMode parameters
--------------------------------------------------------------
function GameMode:CaptureGameMode()
	if mode == nil then
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
				mode:SetUnseenFogOfWarEnabled( ENABLED_FOG_OF_WAR_ENTIRELY )
				mode:SetFountainConstantManaRegen( FOUNTAIN_CONSTANT_MANA_REGEN )
    			mode:SetFountainPercentageHealthRegen( FOUNTAIN_PERCENTAGE_HEALTH_REGEN )
    			mode:SetFountainPercentageManaRegen( FOUNTAIN_PERCENTAGE_MANA_REGEN )

				---------------------------NEW FOR DUEL 1v1---------------------
				--mode:SetThink("onThink", self)

				
				
				mode:SetAnnouncerDisabled(false)
				mode:SetBuybackEnabled(true)
				mode:SetFixedRespawnTime(20)

				--mode:SetBotThinkingEnabled( USE_STANDARD_DOTA_BOT_THINKING )
				mode:SetTowerBackdoorProtectionEnabled( ENABLE_TOWER_BACKDOOR_PROTECTION )

				mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
				mode:SetGoldSoundDisabled( DISABLE_GOLD_SOUNDS )
				mode:SetRemoveIllusionsOnDeath( REMOVE_ILLUSIONS_ON_DEATH )

				--GameRules:GetGameModeEntity():SetThink( "Think", self, "GlobalThink", 2 )

				--self:SetupMultiTeams()
				self:OnFirstPlayerLoaded()
	end 
end
--------------------------------------------------------------
-- PostLoadPrecache
--------------------------------------------------------------
function GameMode:PostLoadPrecache()
	print("Angel Arena Performing Post-Load precache")
	print("Angel Arena Performing Post-Load precache")
end

--------------------------------------------------------------
-- Thinking
--------------------------------------------------------------
--[[function GameMode:onThink()
    for i = 1, #tHeroes do
        local hero = tHeroes[i]
        --hero.rating = hero.creeps * 2 + hero.bosses * 20 + hero.deaths * -15 + hero:GetLevel() * 30
        --print(hero.rating,PlayerResource:GetPlayerName(hero:GetPlayerID()))       
    end 
    --table.sort(tHeroes,function(a,b) return a.rating > b.rating end)
end]]
-------------------------------------------------------------------
function PrintTable(title,table)
	print(title)
	for k,v in pairs(table) do
		print(k,v)
	end
	print("--------------------End of table--------------------------")
end

function OnHeroDeath(keys)
    PrintTable("OnHeroDeath",keys)
    local hero = EntIndexToHScript(keys.entindex_killed)
    local ownerHero = hero:GetPlayerOwner()
    local attacker = EntIndexToHScript(keys.entindex_attacker)
    if ownerHero then
        Timers:CreateTimer(0.1,function() ownerHero:SetKillCamUnit(nil) end) 
    end
end
--------------------------------------------------------------
-- OnPlayerPickHero
--------------------------------------------------------------
function GameMode:OnPlayerPickHero(keys)
    PrintTable("OnPlayerPickHero",keys)
    local player = EntIndexToHScript(keys.player)
    local playerID = player:GetPlayerID()
    local hero = EntIndexToHScript(keys.heroindex)

    --hero.creeps = 0
    --hero.bosses = 0
    --hero.deaths = 0
    --hero.rating = 0
   -- hero.lumber = 3
   -- FireGameEvent('cgm_player_lumber_changed', { player_ID = playerID, lumber = hero.lumber })
    
    table.insert(tHeroes, hero)
    
    --nHeroCount = nHeroCount + 1
    
   -- player:SetTeam(DOTA_TEAM_GOODGUYS)
   -- PlayerResource:UpdateTeamSlot(playerID, DOTA_TEAM_GOODGUYS,true)
    --hero:SetTeam(DOTA_TEAM_GOODGUYS)
    

end
--------------------------------------------------------------
-- ReadGameConfiguration
-- Read and assign configurable keyvalues if applicable
--------------------------------------------------------------
function GameMode:ReadGameConfiguration()
	self.SpawnInfoKV = LoadKeyValues( "scripts/kv/spawn_info.kv" )
	
	--self.ItemInfoKV = LoadKeyValues( "scripts/kv/item_info.kv" )
	--GameRules.DropTable = LoadKeyValues("scripts/kv/item_drops.kv")
	--GameRules.DemonWaves = LoadKeyValues("scripts/kv/demon_waves.kv")

	--GameRules.ItemKV = LoadKeyValues("scripts/npc/npc_items_custom.txt")
	--GameRules.Tooltips = LoadKeyValues("resource/addon_english.txt") --VOLVO WHY

	--DeepPrintTable(GameRules.DropTable)

	-- separate in different lists to make it more manageable (not needed)
	--[[self:ReadGoblinAreaSpawnConfiguration( self.SpawnInfoKV["GoblinArea"] )]]
end


--------------------------------------------------------------
-- OnNPCSpawned
--------------------------------------------------------------
function GameMode:OnNPCSpawned(keys)
	--print("Angel Arena NPC Spawned")
	--[[local index = keys.entindex
	local unit = EntIndexToHScript(index)
	local npc = EntIndexToHScript(keys.entindex)
	
	-- Print a message every time an NPC spawns
	if Convars:GetBool("developer") then
		--print("Index: "..index.." Name: "..unit:GetName().." Created time: "..GameRules:GetGameTime().." at x= "..unit:GetOrigin().x.." y= "..unit:GetOrigin().y)
	end

	if npc:IsHero() then
		npc.strBonus = 0
        npc.intBonus = 0
        npc.agilityBonus = 0
    end

	if npc:IsRealHero() and npc.bFirstSpawned == nil then
			npc.bFirstSpawned = true
			GameMode:OnHeroInGame(npc)
	elseif npc:IsRealHero() and npc.grave then
		-- remove the player grave
		UTIL_Remove(npc.grave)
	end]]
end

--------------------------------------------------------------
-- OnHeroInGame
--This function is called once and only once for every player when they spawn into the game for the first time.
-------------------------------------------------------------- 
function GameMode:OnHeroInGame(hero)
	print("Angel Arena Hero spawned in game for first time -- " .. hero:GetUnitName())

	local player = PlayerResource:GetPlayer(hero:GetPlayerID())

	--[[ Starting Gold
	hero:SetGold(0, false)]]

	-- Initialize custom stats
	hero.spellPower = 0
	hero.healingPower = 0

	--[[ Initialize stat allocation
	hero.STR = 0
	hero.AGI = 0
	hero.INT = 0]]


	-- Give Item
	--local item = CreateItem("item_searing_flame_of_prometheus", hero, hero)
	--hero:AddItem(item)

	--[[Abilities
	local abil1 = hero:GetAbilityByIndex(0)
	local abil2 = hero:GetAbilityByIndex(1)
	local abil3 = hero:GetAbilityByIndex(2)
	local abil4 = hero:GetAbilityByIndex(3)
	local abil5 = hero:GetAbilityByIndex(4)
	local abil6 = hero:GetAbilityByIndex(5)
	if abil1 ~= nil then abil1:SetLevel(1) end
	if abil2 ~= nil then abil2:SetLevel(1) end
	if abil3 ~= nil then abil3:SetLevel(1) end
	if abil4 ~= nil then abil4:SetLevel(1) end
	if abil5 ~= nil then abil5:SetLevel(1) end
	if abil6 ~= nil then abil6:SetLevel(1) end
	--hero:AddAbility("example_ability")

	-- Give 2 extra stat points to spend
	hero:SetAbilityPoints(3)]]

	local heroName = hero:GetUnitName()

end

--------------------------------------------------------------
-- OnEntityHurt
-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive operations here
--------------------------------------------------------------
function GameMode:OnEntityHurt(keys)
	print("Angel Arena Entity Hurt")
	--DeepPrintTable(keys)
	local entCause = EntIndexToHScript(keys.entindex_attacker)
	local entVictim = EntIndexToHScript(keys.entindex_killed)
end

--------------------------------------------------------------
-- OnItemPickedUp
-- An item was picked up off the ground
--------------------------------------------------------------
function GameMode:OnItemPickedUp(keys)
	print ( 'Angel Arena OnItemPickedUp' )
	--DeepPrintTable(keys)	
end


--------------------------------------------------------------
-- OnItemPurchased
-- An item was purchased by a player
--------------------------------------------------------------
function GameMode:OnItemPurchased(keys)
	--print ( 'Angel Arena OnItemPurchased' )
	--DeepPrintTable(keys)

	-- The playerID of the hero who is buying something
	local playerID = keys.PlayerID
	if not playerID then return end

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
	
end

--------------------------------------------------------------
-- OnAbilityUsed
-- An ability was used by a player
--------------------------------------------------------------
function GameMode:OnAbilityUsed(keys)
	--print('Angel Arena AbilityUsed')
	--DeepPrintTable(keys)

	local player = EntIndexToHScript(keys.PlayerID)
	local abilityname = keys.abilityname
end

--------------------------------------------------------------
-- OnNonPlayerUsedAbility
-- A non-player entity (necro-book, chen creep, etc) used an ability
--------------------------------------------------------------
function GameMode:OnNonPlayerUsedAbility(keys)
	--print('Angel Arena OnNonPlayerUsedAbility')
	--DeepPrintTable(keys)

	local abilityname=  keys.abilityname
end

--------------------------------------------------------------
-- OnPlayerChangedName
-- A player changed their name
--------------------------------------------------------------
function GameMode:OnPlayerChangedName(keys)
	--print('Angel Arena OnPlayerChangedName')
	--DeepPrintTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end


--------------------------------------------------------------
-- OnPlayerLevelUp
-- A player leveled up
--------------------------------------------------------------
function GameMode:OnPlayerLevelUp(keys)
	--print ('Angel Arena OnPlayerLevelUp')
	--DeepPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local level = keys.level


	--get the player's ID
    local pID = player:GetPlayerID()

    --get the hero handle
    local hero = player:GetAssignedHero()
    
    --get the players current stat points
    local statsUnspent = hero:GetAbilityPoints()

    --[[ Rules to assign stat points:
		1-19 = 3
		20-39 = 4
		40-59 = 5
		60-79 = 6
		80-99 = 7
		100-119 = 8
		120-139 = 9
		140-159 = 10
		160-179 = 11
		180-199 = 12
		200 = 13 (Maybe more for the last level)
	]]

	-- check the current Level of the hero and assign points accordingly
	--[[ we do 1 less than what we want, because the game automatically gives 1
	local heroLevel = hero:GetLevel()
	if heroLevel <= 19 then
		hero:SetAbilityPoints(statsUnspent+2)
	elseif heroLevel <= 39 then
		hero:SetAbilityPoints(statsUnspent+3)
	elseif heroLevel <= 59 then
		hero:SetAbilityPoints(statsUnspent+4)
    elseif heroLevel <= 79 then
		hero:SetAbilityPoints(statsUnspent+5)
	elseif heroLevel <= 99 then
		hero:SetAbilityPoints(statsUnspent+6)
	elseif heroLevel <= 119 then
		hero:SetAbilityPoints(statsUnspent+7)
	elseif heroLevel <= 139 then
		hero:SetAbilityPoints(statsUnspent+8)
	elseif heroLevel <= 159 then
		hero:SetAbilityPoints(statsUnspent+9)
	elseif heroLevel <= 179 then
		hero:SetAbilityPoints(statsUnspent+10)
	elseif heroLevel <= 199 then
		hero:SetAbilityPoints(statsUnspent+11)
	elseif heroLevel == 200 then
		hero:SetAbilityPoints(statsUnspent+12)
	end]]

	--update the statsUnspent variable to send
	statsUnspent = hero:GetAbilityPoints()

    --[[Fire Game Event to our UI
    print("Got " .. statsUnspent .. " Ability Points to spend! Firing game event")
	FireGameEvent('cgm_player_stat_points_changed', { player_ID = pID, stat_points = statsUnspent })

	--Fire Game Event for Unlocking Journeyman and Ultimate abilities
	if heroLevel==15 then --and not yet used/unlocked
		FireGameEvent('ability_5_unlocked', { player_ID = pID })
	elseif heroLevel==30 then
		FireGameEvent('ability_6_unlocked', { player_ID = pID })		
	end]]

	--Fully heal Health & Mana of the player
	hero:SetHealth(hero:GetMaxHealth())
	hero:SetMana(hero:GetMaxMana())

end

--------------------------------------------------------------
-- OnLastHit
-- A player last hit a creep, a tower, or a hero
--------------------------------------------------------------
function GameMode:OnLastHit(keys)
	--print ('Angel Arena OnLastHit')
	--DeepPrintTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
end

--------------------------------------------------------------
-- OnFirstPlayerLoaded
--This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
--------------------------------------------------------------
function GameMode:OnFirstPlayerLoaded()
	print("Angel Arena First Player has loaded")


end

--------------------------------------------------------------
-- OnAllPlayersLoaded
--This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
--------------------------------------------------------------
function GameMode:OnAllPlayersLoaded()


end

--------------------------------------------------------------
-- OnGameRulesStateChange
-- The overall game state has changed
--------------------------------------------------------------
function GameMode:OnGameRulesStateChange(keys)
	print("Angel Arena GameRules State Changed")
	--DeepPrintTable(keys)

	local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
		self.bSeenWaitForPlayers = true
	elseif newState == DOTA_GAMERULES_STATE_INIT then
		Timers:RemoveTimer("alljointimer")
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local et = 1
		if self.bSeenWaitForPlayers then
			et = .01
		end
		Timers:CreateTimer("alljointimer", {
			useGameTime = true,
			endTime = et,
			callback = function()
				if PlayerResource:HaveAllPlayersJoined() then
					GameMode:PostLoadPrecache()
					GameMode:OnAllPlayersLoaded()
					return 
				end
				return 0.5
			end
		})
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameMode:OnGameInProgress()
	end
end


--------------------------------------------------------------
-- OnGameInProgress
-- This function is called once and only once when the game completely begins (about 0:00 on the clock).
-- This function is useful for starting any game logic timers/thinkers, beginning the first round, etc.
--------------------------------------------------------------
function GameMode:OnGameInProgress()
	GameRules:SendCustomMessage("#aa_welcome_msg", 0, 0)
	GameRules:SendCustomMessage("#aa_Duel_5v5", 0, 0)
	print("Angel Arena The game has officially begun")
	print("Angel Arena popupStart working calling Pop-up MSG to Players")
	ShowGenericPopup( "#aarena_instructions_title", "#aarena_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )

	--Timers:CreateTimer(30, -- Start this timer 30 game-time seconds later
	--	function()
	--	print("This function is called 30 seconds after the game begins, and every 30 seconds thereafter")
	--	return 30.0 -- Rerun this timer every 30 game-time seconds 
	--end)
-------------------------------------------------------------------------------------------
	Timers:CreateTimer({
    endTime = 10, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
    callback = function() Duel5v5()
    --callback = function StartDuels()
      print ("Hello. Duel after 25sec")
      print ("teleport disabled")
            teleportEnt = Entities:FindByName(nil, "arenateleport")
    		teleportEnt:Disable()
      return 1
    end
    })
-------------------------------------------------------------------------------------------
end

--------------------------------------------------------------
-- OnConnectFull
-- This function is called once when the player fully connects and becomes "Ready" during Loading
--------------------------------------------------------------
function GameMode:OnConnectFull(event)
	print ('Angel Arena OnConnectFull')
	PrintTable("OnConnectFull",event)
	local entIndex = event.index+1
	local player = EntIndexToHScript(entIndex)
	local playerID = player:GetPlayerID()
	

	-- Update the user ID table with this user
	self.vUserIds[event.userid] = player
	
	table.insert(tPlayers,player)
    nPlayers = nPlayers + 1  
	-- Update the Steam ID table
	--self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = player
	GameMode:CaptureGameMode()
end

--------------------------------------------------------------
-- OnEntityKilled
--------------------------------------------------------------
function GameMode:OnEntityKilled(keys)
	--print( '[BAREBONES] OnEntityKilled Called' )
	--DeepPrintTable( keys )
	
	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	--local unitName = killedUnit:GetUnitName()
	local attacker = EntIndexToHScript(keys.entindex_attacker)
	--local ownedHeroAtt = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerOwnerID())
	
	-- The Killing entity
	local killerEntity = nil

	if keys.entindex_attacker ~= nil then
		killerEntity = EntIndexToHScript( keys.entindex_attacker )
	end

	--if killedUnit:IsRealHero() then
	--	OnHeroDeath(keys)
	--end


	-- dont delete this salah keep it for the future


	-- Adding point to Heroes
	--[[if string.match(unitName, "_creep") then
	   	print("Its a Creep who died")
        nDeathCreeps = nDeathCreeps + 1
        if ownedHeroAtt then
        	print("Adding 1 point to player - ".. ownedHeroAtt:GetName())
            ownedHeroAtt.creeps = ownedHeroAtt.creeps + 1
        end
    elseif string.match(unitName, "_boss") then
        nDeathCreeps = nDeathCreeps + 1
        if ownedHeroAtt then
            ownedHeroAtt.bosses = ownedHeroAtt.bosses + 1
            ownedHeroAtt.lumber = ownedHeroAtt.lumber + 3
            FireGameEvent('cgm_player_lumber_changed', { player_ID = attacker:GetPlayerOwnerID(), lumber = ownedHeroAtt.lumber })
            if attacker:GetPlayerOwner() then
                PopupNumbers(attacker:GetPlayerOwner() ,killedUnit, "gold", Vector(0,180,0), 3, 3, POPUP_SYMBOL_PRE_PLUS, nil)
            end
        end
    else
   		print("No adding point its not creep or boss ")
    end ]]

	--if killedUnit and ( killedUnit:GetTeamNumber()==DOTA_TEAM_NEUTRALS or killedUnit:GetTeamNumber()==DOTA_TEAM_BADGUYS ) and killedUnit:IsCreature() then
		-- Item Drops
		

		--local level = killedUnit:GetLevel()
		-- Increase by 10% for each party member
		--local party_bonus = 1 + ( GameRules.PLAYER_COUNT * 0.1 )
		--local xp = ( 20 + level * 5 ) * party_bonus

		--Popup XP
		--PopupExperience(killedUnit,math.floor(xp))

		--Popup Gold
		--PopupGoldGain(killedUnit,GameMode:GetBountyFor(unitName))

		--print("Killed Creature, XP gain: "..xp)

		-- Grant XP in AoE
		--local heroesNearby = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, killedUnit:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,false)
		--for _,hero in pairs(heroesNearby) do
		--	if hero:IsRealHero() then
		--		hero:AddExperience(math.floor(xp), false, true)
		--	end
		--end

	if killedUnit and killedUnit:IsRealHero() then 

		print ("KILLEDKILLER: " .. killedUnit:GetName() .. " -- " .. killerEntity:GetName())
		local grave = CreateUnitByName("player_gravestone", killedUnit:GetAbsOrigin(), true, killedUnit, killedUnit, killedUnit:GetTeamNumber())
		killedUnit.grave = grave

		if killedUnit:GetTeam() == DOTA_TEAM_BADGUYS and killerEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
			self.nRadiantKills = self.nRadiantKills + 1
			if END_GAME_ON_KILLS and self.nRadiantKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )
			end
		elseif killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
			self.nDireKills = self.nDireKills + 1
			if END_GAME_ON_KILLS and self.nDireKills >= KILLS_TO_END_GAME_FOR_TEAM then
				GameRules:SetSafeToLeave( true )
				GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
			end
		end

		if SHOW_KILLS_ON_TOPBAR then
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_BADGUYS, self.nDireKills )
			GameRules:GetGameModeEntity():SetTopBarTeamValue ( DOTA_TEAM_GOODGUYS, self.nRadiantKills )
		end
		print("On Hero Death key started")
		OnHeroDeath(keys)
	end

end





--------------------------------------------------------------
-- Duel 5 v 5 mass teleport
--------------------------------------------------------------
function Duel5v5()
    local point =  Vector(6720, 7104, 128)
    --local player = EntIndexToHScript(player)
    --local playerID = player:GetPlayerID()
    --local hero = EntIndexToHScript(heroindex)

    --local player = PlayerResource:GetPlayer(hero:GetPlayerID())
    --local hero = player:GetAssignedHero()
	--local player = EntIndexToHScript(keys.player)
	--local level = keys.level


	--get the player's ID
    --local pID = player:GetPlayerID()

    --get the hero handle
    --local hero = player:GetAssignedHero()
    
    --get the players current stat points
    --local statsUnspent = hero:GetAbilityPoints()

    --spot_heaven = Vector(5897.54, 3904, 17.3543)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_NOTEAM)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_BADGUYS)
    print("Duel 5v5")
    EmitGlobalSound("angel_arena.duelstartmusic")
    --healus(keys)
    Healus( keys )

    --hero:SetHealth(hero:GetMaxHealth())
	--hero:SetMana(hero:GetMaxMana())
	--ResetAllAbilitiesCooldown(hero)
	--hero:ability:EndCooldown()

    --mass teleport
    for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_BADGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
            FindClearSpaceForUnit(entHero, point, false)
            SendToConsole("dota_camera_center")
            entHero:Stop()
        end
    end

    for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
            FindClearSpaceForUnit(entHero, point, false)
            SendToConsole("dota_camera_center")
            entHero:Stop()
        end
    end

    -- Show Quest
    angelDeul = SpawnEntityFromTableSynchronous( "quest", { name = "angelDeul", title = "#angelDeulTimer" } )

    questTimeEnd = GameRules:GetGameTime() + 5 --Time to Finish the quest

    --bar system
    angeldeulKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    angelDeul:AddSubquest( angeldeulKillCountSubQuest )
    angelDeul:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 30 ) --text on the quest timer at start
    angelDeul:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 30 ) --text on the quest timer
    angeldeulKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 30 ) --value on the bar at start
    angeldeulKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 30 ) --value on the bar
    
    Timers:CreateTimer(0.9, function()
        angelDeul:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() )
        angeldeulKillCountSubQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() ) --update the bar with the time passed        
        if (questTimeEnd - GameRules:GetGameTime())<=0 and angelDeul ~= nil then --finish the quest
        	print("30 Sec finished")
            EmitGlobalSound("Tutorial.Quest.complete_01") --on game_sounds_music_tutorial, check others
            UTIL_RemoveImmediate( angelDeul )
            angelDeul = nil
            angeldeulKillCountSubQuest = nil
            --print("Dummy killed")
            chest_spot_arena = Vector(6720, 7104, 128)
    		local chestarena = CreateUnitByName("npc_chest_gold", chest_spot_arena, true, nil, nil, DOTA_TEAM_NOTEAM)
    		teleportoutsidethearena()

        end
        return 1        
    end
    )
    

    GameRules:SendCustomMessage("FIGHT FOR GLORY.", 0, 0)
end


--------------------------------------------------------------
-- Teleport outside the Arena [sub to Duel5v5]
--------------------------------------------------------------
function teleportoutsidethearena()
	
	DuelCounter = 15
    Timers:CreateTimer(function()
        if DuelCounter == 0 then
           print("teleport enabled")
    		teleportEnt = Entities:FindByName(nil, "arenateleport")
    		teleportEnt:Enable()
            return nil
        else
            ShowCenterMessage(tostring(DuelCounter),1)
            DuelCounter = DuelCounter - 1
            return 1
        end
    end)
end


function Healus(keys)
	--PrintTable("healus",keys)
    --local point =  Vector(6720, 7104, 128)
    --local player = EntIndexToHScript(player)
    --local playerID = player:GetPlayerID()
    --local hero = EntIndexToHScript(heroindex)

    --local player = PlayerResource:GetPlayer(hero:GetPlayerID())
    --local hero = player:GetAssignedHero()
	local player = EntIndexToHScript(keys.player)
	--local level = keys.level


	--get the player's ID
    --local pID = player:GetPlayerID()

    --get the hero handle
    local hero = player:GetAssignedHero()
    
    --get the players current stat points
    --local statsUnspent = hero:GetAbilityPoints()

    --spot_heaven = Vector(5897.54, 3904, 17.3543)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_NOTEAM)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_BADGUYS)
    print("Heal us")
    --EmitGlobalSound("angel_arena.duelstartmusic")

    hero:SetHealth(hero:GetMaxHealth())
	hero:SetMana(hero:GetMaxMana())
	ResetAllAbilitiesCooldown(hero)
end