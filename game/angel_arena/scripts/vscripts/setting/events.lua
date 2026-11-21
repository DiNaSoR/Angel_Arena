local ArenaScore = require('mechanics/match/score')

local function ResolveDeathEntity(index)
  local entityIndex = tonumber(index)
  if not entityIndex or entityIndex <= 0 then
    return nil
  end
  local entity = EntIndexToHScript(entityIndex)
  if entity and IsValidEntity(entity) then
    return entity
  end
end

--	This file contains all barebones-registered events and has already set up the passed-in parameters for your use.
--------------------------------------------------------------
--	On Hero Death
--------------------------------------------------------------
function GameMode:OnHeroDeath(hero)
    local player = hero:GetPlayerOwner()
    if player then
        Timers:CreateTimer(0.1, function()
            if IsValidEntity(player) then
                player:SetKillCamUnit(nil)
            end
        end)
    end
end
--------------------------------------------------------------
--	On Disconnect
--------------------------------------------------------------
local function ApplyDuelVisitorForPlayer(playerID)
  if playerID and PlayerResource:IsValidPlayerID(playerID) then
    Duel:SetUpVisitorsForHero(PlayerResource:GetSelectedHeroEntity(playerID))
  end
end

function GameMode:OnDisconnect(keys)
  ApplyDuelVisitorForPlayer(keys.PlayerID)
end
--------------------------------------------------------------
--	On Game Rules State Change
--	The overall game state has changed
--	game event object for OnGameRulesStateChange
--------------------------------------------------------------
function GameMode:OnGameRulesStateChange()
  local state = GameRules:State_Get()
  if state == DOTA_GAMERULES_STATE_STRATEGY_TIME then
    self:OnStrategyTime()
  elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
    self:OnPreGame()
  elseif state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
    self:OnGameInProgress()
  elseif state >= DOTA_GAMERULES_STATE_POST_GAME then
    ArenaScore.SetPhase(self, "finished")
    Duel:FinishMatch()
  end
end
--------------------------------------------------------------
--	OnNPCSpawned
--	An NPC has spawned somewhere in game.  This includes heroes
--	game event object for OnNPCSpawned
--------------------------------------------------------------
function GameMode:OnNPCSpawned(keys)
  local npc = keys.entindex and EntIndexToHScript(keys.entindex)
  if not npc or not IsValidEntity(npc) or not npc.IsHero or not npc:IsHero() then
    return
  end

  if npc:IsRealHero() and not npc.bFirstSpawned then
    self:OnHeroInGame(npc)
    npc.bFirstSpawned = true
  end

  local attemptsRemaining = 10
  Timers:CreateTimer(function()
    if not IsValidEntity(npc) or not npc:IsAlive() then
      return
    end

    local playerID = npc:GetPlayerOwnerID()
    local hasPlayerID = PlayerResource:IsValidPlayerID(playerID)
    local isTrueHero = npc:IsTrueHero()
    if isTrueHero and (not hasPlayerID or PlayerResource:GetSelectedHeroEntity(playerID) ~= npc) then
      -- Hero ownership and selection can arrive after npc_spawned.
      attemptsRemaining = attemptsRemaining - 1
      if attemptsRemaining > 0 then
        return 0.1
      end
      return
    end
    if not hasPlayerID and not npc:GetPlayerOwner() then
      return
    end

    Physics:Unit(npc)
    npc:SetAutoUnstuck(true)
    if npc.ModelOverride then
      npc:SetModel(npc.ModelOverride)
      npc:SetOriginalModel(npc.ModelOverride)
    end

    if isTrueHero then
      PlayerTables:SetTableValue("player_hero_indexes", playerID, npc:GetEntityIndex())
      Duel:SetUpVisitorsForHero(npc)
    end
  end)
end
--------------------------------------------------------------
--	OnEntityHurt
--	An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
--	operations here
--	game event object for OnEntityHurt
--------------------------------------------------------------
function GameMode:OnEntityHurt(keys)
  local victim = keys.entindex_killed and EntIndexToHScript(keys.entindex_killed)
  if victim and IsValidEntity(victim) and victim.hurtEvent then
    victim.hurtEvent.broadcast(keys)
  end
end

--------------------------------------------------------------
--	OnItemPickedUp
--	An item was picked up off the ground
--	game event object for OnItemPickedUp
--------------------------------------------------------------
function GameMode:OnItemPickedUp(keys)
  goldpickup(keys)
end
--------------------------------------------------------------
-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
-- state as necessary
-- game event object for OnPlayerReconnect
--------------------------------------------------------------
function GameMode:OnPlayerReconnect(keys)
  ApplyDuelVisitorForPlayer(keys.PlayerID)
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
  DebugPrint('[DEBUG] OnPlayerLevelUp')
  DebugPrintTable(keys)
	
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
function GameMode:OnEntityKilled(keys)
  local killedUnit = ResolveDeathEntity(keys.entindex_killed)
  if not killedUnit then
    return
  end
  local attacker = ResolveDeathEntity(keys.entindex_attacker)

  if killedUnit.deathEvent then
    killedUnit.deathEvent.broadcast(keys)
  end

  if killedUnit.IsTrueHero and killedUnit:IsTrueHero() and not killedUnit:IsIllusion()
    and not killedUnit:IsClone() and not killedUnit:IsReincarnating() then
    ArenaScore.RecordHeroKill(self, killedUnit, attacker)
    self:OnHeroDeath(killedUnit)
    killedUnit:SetTimeUntilRespawn(killedUnit:CalculateRespawnTime())

    if killedUnit.OnDuel and Duel:IsDuelOngoing() then
      killedUnit.OnDuel = nil
      killedUnit.ArenaBeforeTpLocation = nil
      if Duel:GetWinner() ~= nil then
        Duel:EndDuel()
      end
    end
  end

  if killedUnit.GetUnitName then
    checkminibosses(self, killedUnit, attacker)
    -- Biome camp monsters and bosses (arena/index.lua): respawn timers, loot and boss rewards.
    if ArenaWorld then
      ArenaWorld.OnEntityKilled(killedUnit, attacker)
    end
  end
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
  local playerID = keys.PlayerID
  local player
  if playerID and PlayerResource:IsValidPlayerID(playerID) then
    player = PlayerResource:GetPlayer(playerID)
  end
  if not player and keys.index and keys.index >= 0 then
    player = EntIndexToHScript(keys.index + 1)
  end
  if not player or not IsValidEntity(player) or not player.GetPlayerID then
    return
  end

  playerID = player:GetPlayerID()
  if not PlayerResource:IsValidPlayerID(playerID) then
    return
  end
  if keys.userid then
    self.vUserIds[keys.userid] = player
  end
  local steamID = PlayerResource:GetSteamAccountID(playerID)
  if steamID and steamID ~= 0 then
    self.vSteamIds[steamID] = player
  end

  if PlayerResource:IsBroadcaster(playerID) then
    if keys.userid then
      self.vBroadcasters[keys.userid] = 1
    end
    return
  end
  self.vPlayers[playerID] = player
  Duel:SetUpVisitorsForHero(PlayerResource:GetSelectedHeroEntity(playerID))
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
