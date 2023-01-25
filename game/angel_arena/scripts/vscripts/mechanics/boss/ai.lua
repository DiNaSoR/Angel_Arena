-- OPENAI CHATGPT
--This code appears to define a class called BossAI which handles the behavior of a boss in a game. It has four states: IDLE, AGRO, LEASHING, and DEAD.
--
--The Create function is used to create an instance of BossAI and assign it to a unit. It takes in a unit and an optional options table as arguments. The options table can contain the following values:
--
--tier: the tier of the boss (defaults to 1)
--leash: the size of the leash around the origin of the boss (defaults to BOSS_LEASH_SIZE)
--agroDamage: the amount of damage that the boss needs to take in order to become aggressive (defaults to BOSS_AGRO_FACTOR * options.tier)
--customAgro: a boolean indicating whether the boss should use custom agro logic (defaults to false)
--owner: the owner of the boss (not specified in the default case)
--isProtected: a boolean indicating whether the boss is protected (defaults to false)
--The onDeath function of the returned object can be used to listen to the death event of the boss.
--
--The HurtHandler function is called when the boss takes damage and handles the boss's behavior based on its current state. If the boss is in the IDLE state, it checks whether the amount of damage it has taken so far is greater than the agro damage. If so, it calls the Agro function and sets the current damage to 0. If the boss is in the AGRO state, no action is taken.
--
--The DeathHandler function is called when the boss dies and handles the boss's death event. It broadcasts the death event, adds points to the team of the killer, and gives items to players on the killer's team. If the boss is protected, the points are given to the owner's team instead.
--
--The GiveItemToWholeTeam function is used to give an item to all players on a given team.
--
--The BossAI.hasFarmingCore and BossAI.hasReflexCore tables store whether the good and bad teams have the farming and reflex cores, respectively.
--
--The BossSpawner table appears to store information about boss spawners, and the disable function is used to disable them. The hasFarmingCore and hasReflexCore properties of heroes are used to track whether they have these cores.

-- Taken from bb template
if BossAI == nil then
  DebugPrint ( 'creating new BossAI object' )
  BossAI = class({})
  BossAI.hasFarmingCore = {}
  BossAI.hasReflexCore = {}

  Debug.EnabledModules['boss:ai'] = false
end

BossAI.IDLE = 1
BossAI.AGRO = 2
BossAI.LEASHING = 3
BossAI.DEAD = 4

function BossAI:Create (unit, options)
  options = options or {}
  options.tier = options.tier or 1

  local state = {
    handle = unit,
    origin = unit:GetAbsOrigin(),
    leash = options.leash or BOSS_LEASH_SIZE,
    agroDamage = options.agroDamage or BOSS_AGRO_FACTOR * options.tier,
    tier = options.tier,
    currentDamage = 0,
    state = BossAI.IDLE,
    customAgro = options.customAgro or false,

    owner = options.owner,
    isProtected = options.isProtected,

    deathEvent = Event()
  }

  unit:OnHurt(function (keys)
    BossAI:HurtHandler(state, keys)
  end)
  unit:OnDeath(function (keys)
    BossAI:DeathHandler(state, keys)
  end)

  unit:SetIdleAcquire(false)
  unit:SetAcquisitionRange(0)

  return {
    onDeath = state.deathEvent.listen
  }
end

function BossAI:HurtHandler (state, keys)
  if state.state == BossAI.IDLE then
    DebugPrint('Checking boss agro...')
    DebugPrintTable(keys)

    state.currentDamage = state.currentDamage + keys.damage

    if state.currentDamage > state.agroDamage then
      BossAI:Agro(state, EntIndexToHScript(keys.entindex_attacker))
      state.currentDamage = 0
    end
  elseif state.state == BossAI.AGRO then --luacheck: ignore
  end
end

function BossAI:GiveItemToWholeTeam (item, teamId)
  for playerId = 0,19 do
    if PlayerResource:GetTeam(playerId) == teamId and PlayerResource:GetPlayer(playerId) ~= nil then
      local player = PlayerResource:GetPlayer(playerId)
      local hero = player:GetAssignedHero()

      hero:AddItemByName(item)
    end
  end
end

function BossAI:DeathHandler (state, keys)
  DebugPrint('Handling death of boss ' .. state.tier)
  state.state = BossAI.DEAD

  state.handle = nil
  local killer = EntIndexToHScript(keys.entindex_attacker)
  local teamId = killer:GetTeam()
  local team = nil

  state.deathEvent.broadcast(keys)

  if state.isProtected then
    teamId = state.owner
  end
  if teamId == 2 then
    team = 'good'
  elseif teamId == 3 then
    team = 'bad'
  else
    return
  end

  PointsManager:AddPoints(teamId)

  if state.tier == 1 then
    BossAI:GiveItemToWholeTeam("item_upgrade_core", teamId)

    if not BossAI.hasFarmingCore[team] then
      BossAI.hasFarmingCore[team] = true
    elseif not BossAI.hasReflexCore[team] then
      BossAI.hasReflexCore[team] = true

      BossSpawner[team .. "Zone1"].disable()
      BossSpawner[team .. "Zone2"].disable()
    end

    for playerId = 0,19 do
      if PlayerResource:GetTeam(playerId) == teamId and PlayerResource:GetPlayer(playerId) ~= nil then
        local player = PlayerResource:GetPlayer(playerId)
        local hero = player:GetAssignedHero()

        if hero then
          if BossAI.hasFarmingCore[team] and not hero.hasFarmingCore then
            hero:AddItemByName("item_farming_core")
            hero.hasFarmingCore = true
          elseif BossAI.hasReflexCore[team] and not hero.hasReflexCore then
            hero:AddItemByName("item_reflex_core")
            hero.hasReflexCore = true
          end
        end
      end
    end

  elseif state.tier == 2 then
    NGP:GiveItemToTeam(BossItems["item_upgrade_core_2"], team)
    NGP:GiveItemToTeam(BossItems["item_upgrade_core"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_2", teamId)

  elseif state.tier == 3 then
    NGP:GiveItemToTeam(BossItems["item_upgrade_core_3"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_3", teamId)
  elseif state.tier == 4 then

    NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  elseif state.tier == 5 then

    NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  elseif state.tier == 6 then
    NGP:GiveItemToTeam(BossItems["item_upgrade_core_4"], team)
    BossAI:GiveItemToWholeTeam("item_upgrade_core_4", teamId)
  end
end

function BossAI:Agro (state, target)
  if state.customAgro then
    DebugPrint('Running custom agro ai')
    return
  end

  Timers:CreateTimer(1, function ()
    if state.state == BossAI.DEAD then
      return
    end

    if not BossAI:Think(state) or state.state == BossAI.IDLE then
      DebugPrint('Stopping think timer')
      return
    end
    return 1
  end)
  state.state = BossAI.AGRO
  state.agroTarget = target

  state.handle:SetIdleAcquire(true)
  state.handle:SetAcquisitionRange(128)

  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = target:GetAbsOrigin(),
    Queue = 0,
  })
  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = state.origin,
    Queue = 1,
  })
end

function BossAI:Think (state)
  if state.handle:IsNull() then
    -- this shouldn't happen, but sometimes other bugs can cause it
    -- try to keep the bugged game running
    return false
  end

  local distance = (state.handle:GetAbsOrigin() - state.origin):Length()
  DebugPrint(distance)

  if distance > state.leash then
    BossAI:Leash(state)
  elseif distance < state.leash / 2 and state.state == BossAI.LEASHING then
    state.state = BossAI.IDLE
    return false
  elseif distance == 0 and state.state == BossAI.AGRO then
    state.state = BossAI.IDLE
    return false
  end

  return true
end

function BossAI:Leash (state)
  local difference = state.handle:GetAbsOrigin() - state.origin
  local location = state.origin + (difference / 8)

  state.state = BossAI.LEASHING

  state.handle:SetIdleAcquire(false)
  state.handle:SetAcquisitionRange(0)

  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
    Position = location,
    Queue = 0,
  })
  ExecuteOrderFromTable({
    UnitIndex = state.handle:entindex(),
    -- OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
    OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
    Position = state.origin,
    Queue = 1,
  })
end
