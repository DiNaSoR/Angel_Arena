package.path = "game/angel_arena/scripts/vscripts/?.lua;" .. package.path

DOTA_TEAM_GOODGUYS = 2
DOTA_TEAM_BADGUYS = 3
DOTA_CONNECTION_STATE_CONNECTED = 2
DOTA_GAMERULES_STATE_GAME_IN_PROGRESS = 7
DOTA_GAMERULES_STATE_POST_GAME = 8
DOTA_MAX_TEAM_PLAYERS = 4

class = function(object)
    return object
end
Vector = function(x, y, z)
    return {x = x, y = y, z = z}
end
RandomInt = function(_, maximum)
    return maximum
end
IsValidEntity = function(entity)
    return entity ~= nil
end
local connections = {}
GetConnectionState = function(playerID)
    return connections[playerID] or DOTA_CONNECTION_STATE_CONNECTED
end
GetDOTATimeInMinutesFull = function()
    return 0
end
CreateSimpleBox = function()
    return {}
end
EmitAnnouncerSound = function() end
EmitGlobalSound = function() end

local now = 42
local gameState = DOTA_GAMERULES_STATE_GAME_IN_PROGRESS
GameRules = {
    GetGameTime = function()
        return now
    end,
    State_Get = function()
        return gameState
    end,
}

local timerCallbacks = {}
Timers = {
    CreateTimer = function(_, delay, callback)
        timerCallbacks[#timerCallbacks + 1] = callback or delay
    end,
}

local markers = {}
Entities = {
    FindByName = function(_, _, name)
        return markers[name]
    end,
}
Physics = {
    AddCollider = function(_, _, collider) return collider end,
    ColliderFromProfile = function() return {} end,
}

local duelEnd
local duelState
local duelUpdates = 0
local prizes = {}
PlayerTables = {
    SetTableValue = function(_, tableName, key, value)
        assert(tableName == "arena" and key == "duel_end_time")
        duelEnd = value
    end,
}
CustomNetTables = {
    SetTableValue = function(_, tableName, key, value)
        assert(tableName == "arena_match" and key == "duel")
        duelState = value
        duelUpdates = duelUpdates + 1
    end,
}

Notifications = {TopToAll = function() end}
CustomGameEventManager = {Send_ServerToAllClients = function() end}
ProjectileManager = {ProjectileDodge = function() end}
Events = {Emit = function() end}
CreateTeamNotificationSettings = function() return {} end
CreateGoldNotificationSettings = function() return {}, {} end
Gold = {
    ModifyGold = function(_, playerID, amount)
        prizes[playerID] = amount
    end,
}

local function Hero(team, playerID)
    local origin = Vector(1, 0, 0)
    return {
        health = 10,
        mana = 20,
        team = team,
        alive = true,
        position = origin,
        GetUnitName = function() return "hero" end,
        GetPlayerOwnerID = function() return playerID end,
        IsAlive = function(self) return self.alive end,
        IsReincarnating = function(self) return self.reincarnating end,
        GetHealth = function(self) return self.health end,
        GetMana = function(self) return self.mana end,
        GetMaxHealth = function() return 100 end,
        GetMaxMana = function() return 200 end,
        GetAbsOrigin = function(self) return self.position end,
        GetAbilityCount = function() return 0 end,
        GetItemInSlot = function() return nil end,
        HasAbility = function() return false end,
        HasModifier = function(self) return self.visitor end,
        SetHealth = function(self, health) self.health = health end,
        SetMana = function(self, mana) self.mana = mana end,
        AddNewModifier = function(self) self.visitor = true end,
        RemoveModifierByName = function(self) self.visitor = nil end,
        FindClearSpaceForUnitAndSetCamera = function(self, position) self.position = position end,
        ModifyPlayerStat = function() end,
    }, origin
end
FindClearSpaceForUnit = function(unit, position)
    unit.position = position
end

local heroes = {}
PlayerResource = {
    IsValidPlayerID = function(_, id)
        return heroes[id] ~= nil
    end,
    GetTeam = function(_, id)
        return heroes[id].team
    end,
    GetSelectedHeroEntity = function(_, id)
        return heroes[id]
    end,
}

require("libraries/data/table")
require("mechanics/duel/duel")
GameMode = {}
require("setting/events")

Duel:CreateGlobalTimer()
assert(#timerCallbacks == 0)
local angels = Vector(2, 0, 0)
local demons = Vector(3, 0, 0)
markers.target_mark_arena_blocker_1 = {GetAbsOrigin = function() return Vector(-1, -1, 0) end}
markers.target_mark_arena_blocker_2 = {GetAbsOrigin = function() return Vector(1, 1, 0) end}
markers.target_mark_arena_team2 = {GetAbsOrigin = function() return angels end}
markers.target_mark_arena_team3 = {GetAbsOrigin = function() return demons end}
Duel:CreateGlobalTimer()
assert(#timerCallbacks == 1)
assert(timerCallbacks[1]() == 0.2)
assert(duelEnd == now + 300 and not Duel:IsDuelOngoing())
assert(duelState.phase == "waiting" and duelState.deadline == duelEnd)
now = duelEnd
assert(timerCallbacks[1]() == 0.2)
assert(duelEnd == now + DUEL_SETTINGS.DelaysFromLast[0])

local angel, angelOrigin = Hero(DOTA_TEAM_GOODGUYS, 0)
local demon, demonOrigin = Hero(DOTA_TEAM_BADGUYS, 1)
local reserve = Hero(DOTA_TEAM_GOODGUYS, 2)
heroes[0] = angel
heroes[1] = demon
heroes[2] = reserve
connections[2] = 3
now = duelEnd
timerCallbacks[1]()
assert(Duel:IsDuelOngoing())
assert(angel.position == angels and demon.position == demons and reserve.visitor)
assert(angel.health == angel:GetMaxHealth() and angel.mana == angel:GetMaxMana())
assert(duelEnd == now + DUEL_SETTINGS.DurationBase + DUEL_SETTINGS.DurationForPlayer)
assert(duelState.phase == "active" and duelState.deadline == duelEnd)

local lateHero = Hero(DOTA_TEAM_GOODGUYS, 3)
heroes[3] = lateHero
GameMode:OnPlayerReconnect({PlayerID = 3})
GameMode:OnPlayerReconnect({PlayerID = 0})
assert(lateHero.visitor and not angel.visitor and angel.OnDuel)

demon.alive = false
demon.reincarnating = true
assert(Duel:GetWinner() == nil)
demon.reincarnating = false
Duel:EndDuel()
assert(not Duel:IsDuelOngoing() and angel.position == angelOrigin and not reserve.visitor and not lateHero.visitor)
assert(prizes[0] == DUEL_SETTINGS.WinGold_Base and not prizes[1] and not prizes[2])
for index = 3, #timerCallbacks do
    timerCallbacks[index]()
end
assert(angel.health == 10 and angel.mana == 20)
assert(duelEnd == now + DUEL_SETTINGS.DelaysFromLast[0])
assert(duelState.phase == "waiting" and duelState.deadline == duelEnd)

demon.alive = true
demon.position = demonOrigin
now = duelEnd
timerCallbacks[1]()
assert(Duel:IsDuelOngoing() and demon.position == demons)
demon.alive = false
demon.reincarnating = true
now = duelEnd
local previousTimerCount = #timerCallbacks
timerCallbacks[1]()
assert(not Duel:IsDuelOngoing() and not demon.OnDuel)
local returnAfterReincarnation
for index = previousTimerCount + 1, #timerCallbacks do
    if timerCallbacks[index]() == 0.2 then
        returnAfterReincarnation = timerCallbacks[index]
    end
end
assert(returnAfterReincarnation)
demon.alive = true
demon.reincarnating = false
assert(returnAfterReincarnation() == nil and demon.position == demonOrigin)

now = duelEnd
timerCallbacks[1]()
assert(Duel:IsDuelOngoing() and lateHero.visitor)
gameState = DOTA_GAMERULES_STATE_POST_GAME
assert(timerCallbacks[1]() == nil)
assert(not lateHero.visitor and not Duel:IsDuelOngoing())
assert(angel.position == angelOrigin and angel.health == 10 and angel.mana == 20)
assert(duelState.phase == "finished" and duelState.deadline == 0 and duelEnd == 0)
local finalUpdateCount = duelUpdates
Duel:FinishMatch()
assert(duelUpdates == finalUpdateCount)

print("Duel scheduling, teams, and restoration checks passed")
