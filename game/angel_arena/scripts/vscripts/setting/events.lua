--	This file contains all barebones-registered events and has already set up the passed-in parameters for your use.
--------------------------------------------------------------
--	On Hero Death
--------------------------------------------------------------
function GameMode:OnHeroDeath(keys)
    --PrintTable("GameMode:OnHeroDeath",keys)
    --DebugPrintTable("GameMode:OnHeroDeath",keys)
    local ent = EntIndexToHScript(keys.entindex_killed)
    local hero = ent:GetPlayerOwner()
    local attacker = EntIndexToHScript(keys.entindex_attacker)
    if hero then
        Timers:CreateTimer(0.1,function() hero:SetKillCamUnit(nil) end) 
    end
    --print("Hero [" .. ent:GetUnitName() .. "] killed by [" .. attacker:GetUnitName() .. "]")
end
--------------------------------------------------------------
--	On Disconnect
--------------------------------------------------------------
function GameMode:OnDisconnect(keys)
  --DebugPrint('[DEBUG] Player Disconnected ' .. tostring(keys.userid))
  --DebugPrintTable(keys)

  local name = keys.name
  local networkid = keys.networkid
  local reason = keys.reason
  local userid = keys.userid
end
--------------------------------------------------------------
--	On Game Rules State Change
--	The overall game state has changed
--	game event object for OnGameRulesStateChange
--------------------------------------------------------------
function GameMode:OnGameRulesStateChange(keys)
  --print("Angel Arena GameRules State Changed")
  --DebugPrint("[DEBUG] GameRules State Changed")
  --DebugPrintTable(keys)

  local newState = GameRules:State_Get()
  -- Waiting for players to load
  if newState == DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD then
  
  print("[Angel Arena] Game Change to waiting for players to load")
  -- Hero selection
  elseif  newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
  print("[Angel Arena] Game Change to hero selection")
  --EmitGlobalSound("angel_arena.allahremix")
  -- Strategy time started
  elseif  newState == DOTA_GAMERULES_STATE_STRATEGY_TIME then
  print("[Angel Arena] Game Change to strategy time")
    GameMode:OnStrategyTime()
  -- Pre-Game started
  elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
  print("[Angel Arena] Game Change to pre game")
    GameMode:OnPreGame()
  --Game in progress
  elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
  print("[Angel Arena] Game Change to game in progress")
    GameMode:OnGameInProgress()

  -- Hero Selection
  --[[elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
    for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS-1 do
				local playerHandle = PlayerResource:GetPlayer(nPlayerID)
				PlayerResource:SetHasRandomed(nPlayerID)
				PlayerResource:SetHasRepicked(nPlayerID)
				playerHandle:MakeRandomHeroSelection()
		end]]
  end
end
--------------------------------------------------------------
--	OnNPCSpawned
--	An NPC has spawned somewhere in game.  This includes heroes
--	game event object for OnNPCSpawned
--------------------------------------------------------------
function GameMode:OnNPCSpawned(keys)
	--print("[Angel Arena] NPC Spawned")
  local npc = EntIndexToHScript(keys.entindex)

	-- Replace hero corpse with grave so they can rez him again.
  if npc:IsRealHero() and npc.bFirstSpawned == nil then
			npc.bFirstSpawned = true
			GameMode:OnHeroInGame(npc)
	else--if --npc:IsRealHero() and npc.grave then
		-- remove the player grave
		  --UTIL_Remove(npc.grave)
	end


  --Check if its hero then if its truehero to apply Visitor for Duel
  if npc:IsHero() then
		--HeroVoice:OnNPCSpawned(npc)
		Timers:CreateTimer(function()
			if IsValidEntity(npc) and npc:IsAlive() and npc:IsHero() and npc:GetPlayerOwner() then
				Physics:Unit(npc)
				npc:SetAutoUnstuck(true)
				if npc.ModelOverride then
					npc:SetModel(npc.ModelOverride)
					npc:SetOriginalModel(npc.ModelOverride)
				end
				--if not npc:IsWukongsSummon() then
					if npc:IsTrueHero() then
						  PlayerTables:SetTableValue("player_hero_indexes", npc:GetPlayerID(), npc:GetEntityIndex())
						  --[[if IsValidEntity(npc.BloodstoneDummies) then
							    UTIL_Remove(npc.BloodstoneDummies)
							    npc.BloodstoneDummies = nil
						  end]]
						  if not npc.OnDuel and Duel:IsDuelOngoing() then
							  Duel:SetUpVisitor(npc)
						  end
					end
				--end
			end
		end)
	end
end
--------------------------------------------------------------
--	OnEntityHurt
--	An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
--	operations here
--	game event object for OnEntityHurt
--------------------------------------------------------------
function GameMode:OnEntityHurt(keys)
  --DebugPrint("[DEBUG] Entity Hurt")
  --DebugPrintTable(keys)

  local damagebits = keys.damagebits -- This might always be 0 and therefore useless
  if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
    local entCause = EntIndexToHScript(keys.entindex_attacker)
    local entVictim = EntIndexToHScript(keys.entindex_killed)

    -- The ability/item used to damage, or nil if not damaged by an item/ability
    local damagingAbility = nil

    if keys.entindex_inflictor ~= nil then
      damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
    end

    if entVictim.hurtEvent then
      entVictim.hurtEvent.broadcast(keys)
    end
  end
end
--------------------------------------------------------------
--	OnItemPickedUp
--	An item was picked up off the ground
--	game event object for OnItemPickedUp
--------------------------------------------------------------
function GameMode:OnItemPickedUp(keys)
  --DebugPrint( '[DEBUG] OnItemPickedUp' )
  --DebugPrintTable(keys)

  local unitEntity = nil
  if keys.UnitEntitIndex then
    unitEntity = EntIndexToHScript(keys.UnitEntitIndex)
  elseif keys.HeroEntityIndex then
    unitEntity = EntIndexToHScript(keys.HeroEntityIndex)
  end

  local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local itemname = keys.itemname
  
  goldpickup(keys)
end
--------------------------------------------------------------
-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
-- game event object for OnPlayerReconnect
--------------------------------------------------------------
function GameMode:OnPlayerReconnect(keys)
  --DebugPrint( '[DEBUG] OnPlayerReconnect' )
  --DebugPrintTable(keys)

  local playID = keys.PlayerID
  if not playID then
    return
  end

end
--------------------------------------------------------------
--	On Item Purchased
--	An item was purchased by a player
--	game event object for OnItemPurchased
--------------------------------------------------------------
function GameMode:OnItemPurchased( keys )
  --DebugPrint( '[DEBUG] OnItemPurchased' )
  --DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end

  -- The name of the item purchased
  local itemName = keys.itemname

  -- The cost of the item purchased
  local itemcost = keys.itemcost

end
--------------------------------------------------------------
--	On Ability Used
--	An ability was used by a player
--	game event object for OnAbilityUsed
--------------------------------------------------------------
function GameMode:OnAbilityUsed(keys)
  --DebugPrint('[DEBUG] AbilityUsed')
  --DebugPrintTable(keys)
  
	local player          = PlayerResource:GetPlayer(keys.PlayerID)
  local hero            = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
  local heroname        = PlayerResource:GetSelectedHeroName(keys.PlayerID)
	local abilityname     = keys.abilityname
  local herolevel       = hero:GetLevel()

  abilityusedindex(player,hero,heroname,abilityname,herolevel)

  
end
--------------------------------------------------------------
-- On NonPlayer Used Ability
-- A non-player entity (necro-book, chen creep, etc) used an ability
-- game event object for OnNonPlayerUsedAbility
--------------------------------------------------------------
function GameMode:OnNonPlayerUsedAbility(keys)
  --DebugPrint('[DEBUG] OnNonPlayerUsedAbility')
  --DebugPrintTable(keys)

  local abilityname=  keys.abilityname
end
--------------------------------------------------------------
-- OnPlayerChangedName
-- A player changed their name
-- game event object for OnPlayerChangedName  
-- A player changed their name
--------------------------------------------------------------
function GameMode:OnPlayerChangedName(keys)
  --DebugPrint('[DEBUG] OnPlayerChangedName')
  --DebugPrintTable(keys)

  local newName = keys.newname
  local oldName = keys.oldName
end
--------------------------------------------------------------
-- A player leveled up an ability
-- game event object for OnPlayerLearnedAbility
--------------------------------------------------------------
function GameMode:OnPlayerLearnedAbility( keys)
  --DebugPrint('[DEBUG] OnPlayerLearnedAbility')
  --DebugPrintTable(keys)

  local player = EntIndexToHScript(keys.player)
  local abilityname = keys.abilityname
end
--------------------------------------------------------------
-- A channelled ability finished by either completing or being interrupted
-- game event object for OnAbilityChannelFinished
--------------------------------------------------------------
function GameMode:OnAbilityChannelFinished(keys)
  --DebugPrint('[DEBUG] OnAbilityChannelFinished')
  --DebugPrintTable(keys)

  local abilityname = keys.abilityname
  local interrupted = keys.interrupted == 1
end
--------------------------------------------------------------
-- A player leveled up
-- game event object for OnPlayerLevelUp
--------------------------------------------------------------
function GameMode:OnPlayerLevelUp(keys)
  --DebugPrint('[DEBUG] OnPlayerLevelUp')
  --DebugPrintTable(keys)
	
	local player = EntIndexToHScript(keys.player)
	local level = keys.level
	--get the player's ID
    local pID = player:GetPlayerID()
    --get the hero handle
    local hero = player:GetAssignedHero()
	--Fully heal Health & Mana of the player when level up
	hero:SetHealth(hero:GetMaxHealth())
	hero:SetMana(hero:GetMaxMana())
	
	--[[Test for levels after level 25
	local herolevel = hero.GetLevel()
		if herolevel >= 25 then
			player:ModifyAgility(3)
      agilevel = player:GetBaseAgility()
      Print("AGI +"..agilevel)
    end]]
	
	--get the players current stat points
    --local statsUnspent = hero:GetAbilityPoints()

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
	--statsUnspent = hero:GetAbilityPoints()

    --[[Fire Game Event to our UI
    print("Got " .. statsUnspent .. " Ability Points to spend! Firing game event")
	FireGameEvent('cgm_player_stat_points_changed', { player_ID = pID, stat_points = statsUnspent })

	--Fire Game Event for Unlocking Journeyman and Ultimate abilities
	if heroLevel==15 then --and not yet used/unlocked
		FireGameEvent('ability_5_unlocked', { player_ID = pID })
	elseif heroLevel==30 then
		FireGameEvent('ability_6_unlocked', { player_ID = pID })		
	end]]
end
--------------------------------------------------------------
-- OnLastHit
-- A player last hit a creep, a tower, or a hero
-- game event object for OnLastHit
--------------------------------------------------------------
function GameMode:OnLastHit(keys)
  --DebugPrint('[DEBUG] OnLastHit')
  --DebugPrintTable(keys)

  local isFirstBlood = keys.FirstBlood == 1
  local isHeroKill = keys.HeroKill == 1
  local isTowerKill = keys.TowerKill == 1
  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local killedEnt = EntIndexToHScript(keys.EntKilled)
end
--------------------------------------------------------------
-- A tree was cut down by tango, quelling blade, etc
-- game event object for OnTreeCut
--------------------------------------------------------------
function GameMode:OnTreeCut(keys)
  --DebugPrint('[DEBUG] OnTreeCut')
  --DebugPrintTable(keys)
  --print("TREE IS DOWN!")

  local treeX = keys.tree_x
  local treeY = keys.tree_y
end
--------------------------------------------------------------
-- A rune was activated by a player
-- game event object for OnRuneActivated
--------------------------------------------------------------
function GameMode:OnRuneActivated (keys)
  --DebugPrint('[DEBUG] OnRuneActivated')
  --DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local rune = keys.rune

end
--------------------------------------------------------------
-- A player took damage from a tower
-- game event object for OnPlayerTakeTowerDamage
--------------------------------------------------------------
function GameMode:OnPlayerTakeTowerDamage(keys)
  --DebugPrint('[DEBUG] OnPlayerTakeTowerDamage')
  --DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local damage = keys.damage
end

--------------------------------------------------------------
--OnPlayerPickHero
--A player picked a hero
--game event object for OnPlayerPickHero
--------------------------------------------------------------
function GameMode:OnPlayerPickHero(keys)
	--PrintTable("OnPlayerPickHero",keys)
	--DebugPrint('[DEBUG] OnPlayerPickHero')
	--DebugPrintTable(keys)

  local heroClass 	= keys.hero
  local heroEntity 	= EntIndexToHScript(keys.heroindex)
  local player 		  = EntIndexToHScript(keys.player)
  local playerID 	  = player:GetPlayerID()
   

    --drop = Vector(-2752, -1280, 129.354)
    --local unit = CreateUnitByName("npc_lord_of_death_boss", drop, true, nil, nil, DOTA_TEAM_NEUTRALS)
 	
    --hero.creeps = 0
    --hero.bosses = 0
    --hero.deaths = 0
    --hero.rating = 0
   -- hero.lumber = 3
   -- FireGameEvent('cgm_player_lumber_changed', { player_ID = playerID, lumber = hero.lumber })
    
    table.insert(tHeroes, hero)
    --print(table.insert(tHeroes, hero))
    
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

end
--------------------------------------------------------------
-- A player killed another player in a multi-team context
-- game event object for OnTeamKillCredit
--------------------------------------------------------------
function GameMode:OnTeamKillCredit(keys)
  --DebugPrint('[DEBUG] OnTeamKillCredit')
  --DebugPrintTable(keys)

  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
  local numKills = keys.herokills
  local killerTeamNumber = keys.teamnumber
end
--------------------------------------------------------------
--[[ game event object for OnTeamKillCredit
--------------------------------------------------------------
local OnHeroKilledEvent = CreateGameEvent('OnHeroKilled')
function GameMode:OnHeroKilled (keys)
  OnHeroKilledEvent(keys)
end]]
--------------------------------------------------------------
-- OnEntityKilled
-- An entity died
-- game event object for keys
--------------------------------------------------------------
function GameMode:OnEntityKilled( keys )

	-- The Unit that was Killed
	local killedUnit = EntIndexToHScript( keys.entindex_killed )
	-- The Killing entity
	local killerEntity = nil
	-- Get Unit Name that was Killed
	local unitName = killedUnit:GetUnitName()
	-- The Unit that was Attacked
	local attacker = EntIndexToHScript(keys.entindex_attacker)
	--local ownedHeroAtt = PlayerResource:GetSelectedHeroEntity(attacker:GetPlayerOwnerID())

  if keys.entindex_attacker ~= nil then
    killerEntity = EntIndexToHScript( keys.entindex_attacker )
  end

  -- The ability/item used to kill, or nil if not killed by an item/ability
  local killerAbility = nil

  if keys.entindex_inflictor ~= nil then
    killerAbility = EntIndexToHScript( keys.entindex_inflictor )
  end
  
	-- Player owner of the unit
	local player = killedUnit:GetPlayerOwner()

  local damagebits = keys.damagebits -- This might always be 0 and therefore useless

	
  -- Fire ent killed event
  if killedUnit.deathEvent then
      killedUnit.deathEvent.broadcast(keys)
  end

  if killedUnit.IsRealHero and killedUnit:IsRealHero() then
    --OnHeroDiedEvent(killedUnit)
  end
  
	--This code just checking is it creature or creep ?
	if killedUnit:IsCreature() or killedUnit:IsCreep() then
	    --print("[Angel Arena] Creature/Creep Killed: ["..killedUnit:GetUnitName().."] Killer: [".. killerEntity:GetUnitName().."]")
	 	--DebugPrint("KILLED, KILLER: " .. killedUnit:GetUnitName() .. " -- " .. killerEntity:GetUnitName())
     -- RollDrops(killedUnit)
        
  end
	
	--This code to check if this is real hero when they die place grave in hero place then add point to the team
	if killedUnit and killedUnit:IsRealHero() then 
		  --print("[Angel Arena] HERO Killed: [".. killedUnit:GetUnitName() .."] killer: [".. killerEntity:GetUnitName().."]")
		  --local grave = CreateUnitByName("player_gravestone", killedUnit:GetAbsOrigin(), true, killedUnit, killedUnit, killedUnit:GetTeamNumber())
		  --killedUnit.grave = grave

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
		    --print("On Hero Death key started")
		    GameMode:OnHeroDeath(keys)
	end




  if killedUnit then
      if killedUnit:IsHero() then
        --killedUnit:RemoveModifierByName("modifier_shard_of_true_sight") -- For some reason simple KV modifier not removes on death without this
        if killedUnit:IsRealHero() then
          local respawnTime = killedUnit:CalculateRespawnTime()
          killedUnit:SetTimeUntilRespawn(respawnTime)
          --MeepoFixes:ShareRespawnTime(killedUnit, respawnTime)
          --killedUnit.RespawnTimeModifierBloodstone = nil
          --killedUnit.RespawnTimeModifierSaiReleaseOfForge = nil

          if killedUnit.OnDuel and Duel:IsDuelOngoing() then
            --print(" I AM IN DUEL AND I DIDED")
            killedUnit:SetTimeUntilRespawn(respawnTime)
            killedUnit.OnDuel = nil
            killedUnit.ArenaBeforeTpLocation = nil
            if Duel:GetWinner() ~= nil then
              Duel:EndDuel()
            end
          end
          --[[if not IsValidEntity(killerEntity) or not killerEntity.GetPlayerOwner or not IsValidEntity(killerEntity:GetPlayerOwner()) then
            Kills:OnEntityKilled(killedUnit:GetPlayerOwner(), nil)
          elseif killerEntity == killedUnit then
            local player = killedUnit:GetPlayerOwner()
            Kills:OnEntityKilled(player, player)
          end]]
        end
      end

      --if killedUnit:IsRealCreep() then
        --Spawner.Creeps[killedUnit.SSpawner] = Spawner.Creeps[killedUnit.SSpawner] - 1
      --end

      --[[if killerEntity then
        for _, individual_hero in ipairs(HeroList:GetAllHeroes()) do
          if individual_hero:IsAlive() and individual_hero:HasModifier("modifier_shinobu_hide_in_shadows_invisibility") then
            local shinobu_hide_in_shadows = individual_hero:FindAbilityByName("shinobu_hide_in_shadows")
            if individual_hero:GetTeam() == killedUnit:GetTeam() and individual_hero:GetRangeToUnit(killedUnit) <= shinobu_hide_in_shadows:GetAbilitySpecial("ally_radius") then
              individual_hero:SetHealth(individual_hero:GetMaxHealth())
              shinobu_hide_in_shadows:ApplyDataDrivenModifier(individual_hero, individual_hero, "modifier_shinobu_hide_in_shadows_rage", nil)
            end
          end
        end]]

        --[[if killerEntity:GetTeamNumber() ~= killedUnit:GetTeamNumber() and (killerEntity.GetPlayerID or killerEntity.GetPlayerOwnerID) then
          local plId = killerEntity.GetPlayerID ~= nil and killerEntity:GetPlayerID() or killerEntity:GetPlayerOwnerID()
          if plId > -1 and not (killerEntity.HasModifier and killerEntity:HasModifier("modifier_item_golden_eagle_relic_enabled")) then
            local gold = RandomInt(killedUnit:GetMinimumGoldBounty(), killedUnit:GetMaximumGoldBounty())
            --Gold:ModifyGold(plId, gold)
            SendOverheadEventMessage(killerEntity:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, killedUnit, gold, killerEntity:GetPlayerOwner())
          end
        end
      end]]
  end

	-- MiniBosses Check
	checkminibosses(keys)
end

--------------------------------------------------------------
-- This function is called 1 to 2 times as the player connects initially but before they
-- have completely connected
--------------------------------------------------------------
function GameMode:PlayerConnect(keys)
  --DebugPrint('[DEBUG] PlayerConnect')
  --DebugPrintTable(keys)
end
--------------------------------------------------------------
-- OnConnectFull
-- This function is called once when the player fully connects and becomes "Ready" during Loading
-- game event object for OnConnectFull
--------------------------------------------------------------
function GameMode:OnConnectFull(keys)
  --DebugPrint('[DEBUG] OnConnectFull')
  --DebugPrintTable(keys)
  
  GameMode:CaptureGameMode()
  local entIndex = keys.index+1
  -- The Player entity of the joining user
  local player = EntIndexToHScript(entIndex)
  local ply = EntIndexToHScript(entIndex)
  
  -- Check if the player variable is not nil before using it
  if player ~= nil then
    -- The Player ID of the joining player
    local playerID = player:GetPlayerID()
    
    -- Update the user ID table with this user
    self.vUserIds[keys.userid] = player
    self.vUserIds[keys.userid] = ply
  
    -- Update the Steam ID table
    self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = player
    self.vSteamIds[PlayerResource:GetSteamAccountID(playerID)] = ply
    
    -- If the player is a broadcaster flag it in the Broadcasters table
    if PlayerResource:IsBroadcaster(playerID) then
      self.vBroadcasters[keys.userid] = 1
      return
    end
  
    table.insert(tPlayers,player)
    nPlayers = nPlayers + 1
  else
    print("Error: Player entity not found.")
  end
end


function GameMode:OnPlayerConnect(keys)
  DebugPrint('[DEBUG] OnPlayerConnect')
  DebugPrintTable(keys)
end
--------------------------------------------------------------
-- This function is called whenever illusions are created and tells you which was/is the original entity
-- game event object for OnIllusionsCreated
--------------------------------------------------------------
function GameMode:OnIllusionsCreated(keys)
  --DebugPrint('[DEBUG] OnIllusionsCreated')
  --DebugPrintTable(keys)

  local originalEntity = EntIndexToHScript(keys.original_entindex)
end
--------------------------------------------------------------
-- This function is called whenever an item is combined to create a new item
-- game event object for OnItemCombined
--------------------------------------------------------------
function GameMode:OnItemCombined(keys)
  --DebugPrint('[DEBUG] OnItemCombined')
  --DebugPrintTable(keys)

  -- The playerID of the hero who is buying something
  local plyID = keys.PlayerID
  if not plyID then return end
  local player = PlayerResource:GetPlayer(plyID)

  -- The name of the item purchased
  local itemName = keys.itemname

  -- The cost of the item purchased
  local itemcost = keys.itemcost
end
--------------------------------------------------------------
-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
-- game event object for OnAbilityCastBegins
--------------------------------------------------------------
function GameMode:OnAbilityCastBegins(keys)
  --DebugPrint('[DEBUG] OnAbilityCastBegins')
  --DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.PlayerID)
  local abilityName = keys.abilityname
end
--------------------------------------------------------------
-- This function is called whenever a tower is killed
-- game event object for OnTowerKill
--------------------------------------------------------------
function GameMode:OnTowerKill(keys)
  --DebugPrint('[DEBUG] OnTowerKill')
  --DebugPrintTable(keys)

  local gold = keys.gold
  local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
  local team = keys.teamnumber
end
--------------------------------------------------------------
-- This function is called whenever a player changes there custom team selection during Game Setup
-- game event object for OnPlayerSelectedCustomTeam
--------------------------------------------------------------
function GameMode:OnPlayerSelectedCustomTeam(keys)
  --DebugPrint('[DEBUG] OnPlayerSelectedCustomTeam')
  --DebugPrintTable(keys)

  local player = PlayerResource:GetPlayer(keys.player_id)
  local success = (keys.success == 1)
  local team = keys.team_id
end
--------------------------------------------------------------
-- This function is called whenever an NPC reaches its goal position/target
-- game event object for OnNPCGoalReached
--------------------------------------------------------------
function GameMode:OnNPCGoalReached(keys)
  --DebugPrint('[DEBUG] OnNPCGoalReached')
  --DebugPrintTable(keys)

  local goalEntity = EntIndexToHScript(keys.goal_entindex)
  local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
  local npc = EntIndexToHScript(keys.npc_entindex)
end
--------------------------------------------------------------
-- This function is called whenever any player sends a chat message to team or All
-- game event object for OnPlayerChat
--------------------------------------------------------------
function GameMode:OnPlayerChat(keys)
  --DebugPrint('[DEBUG] OnNPCGoalReached')
  --DebugPrintTable(keys)
end
--------------------------------------------------------------
--------------------------------------------------------------