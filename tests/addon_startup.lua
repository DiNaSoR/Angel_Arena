local vscripts = "game/angel_arena/scripts/vscripts"
package.path = vscripts .. "/?.lua;" .. package.path

DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS, DOTA_TEAM_NEUTRALS = 2, 3, 4
DOTA_MAX_TEAM_PLAYERS = 24
DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD = 1
DOTA_GAMERULES_STATE_HERO_SELECTION = 2
DOTA_GAMERULES_STATE_STRATEGY_TIME = 3
DOTA_GAMERULES_STATE_PRE_GAME = 4
DOTA_GAMERULES_STATE_GAME_IN_PROGRESS = 5
DOTA_GAMERULES_STATE_POST_GAME = 6
for n = 1, 8 do
    _G["DOTA_TEAM_CUSTOM_" .. n] = 5 + n
end
for n, rune in ipairs({ "DOUBLEDAMAGE", "HASTE", "ILLUSION", "INVISIBILITY", "REGENERATION", "BOUNTY", "ARCANE" }) do
    _G["DOTA_RUNE_" .. rune] = n - 1
end

function class(fields)
    return setmetatable(fields, { __call = function()
        return setmetatable({}, { __index = fields })
    end })
end

function Dynamic_Wrap(scope, name)
    assert(type(scope[name]) == "function", "Undefined callback: " .. name)
    return function(context, ...)
        return scope[name](context, ...)
    end
end

local vector = {}
vector.__index = vector
function Vector(x, y, z) return setmetatable({ x = x, y = y, z = z }, vector) end
function vector.__add(a, b) return Vector(a.x + b.x, a.y + b.y, a.z + b.z) end
function vector.__sub(a, b) return Vector(a.x - b.x, a.y - b.y, a.z - b.z) end
function vector.__mul(value, scale)
    if type(value) == "number" then value, scale = scale, value end
    return Vector(value.x * scale, value.y * scale, value.z * scale)
end
function vector.__div(value, scale) return value * (1 / scale) end
function vector:Normalized() return self / math.sqrt(self.x ^ 2 + self.y ^ 2 + self.z ^ 2) end
function GetSystemTimeMS() return 0 end
function GetMapName() return "angel_arena" end
function RandomInt(first) return first end
function IsServer() return true end
function IsValidEntity(entity) return entity ~= nil and not entity.removed end

local function Noop() end
local uniqueString = 0
function DoUniqueString(prefix)
    uniqueString = uniqueString + 1
    return prefix .. uniqueString
end

local modifiers = {}
function LinkLuaModifier(name, path)
    local script = assert(io.open(vscripts .. "/" .. path, "r"), "Missing modifier: " .. path)
    script:close()
    modifiers[name] = true
end

local precached = {}
function PrecacheUnitByNameSync(name) precached[name] = true end
function PrecacheResource(_, resource) precached[resource] = true end
function SpawnEntityFromTableSynchronous() return { SetThink = Noop } end
function SetTeamCustomHealthbarColor() end
function LoadKeyValues(path)
    assert(path ~= "addoninfo.txt", "LoadKeyValues cannot read the KV3 addon metadata")
    return {}
end

CEntityInstance, CDOTA_BaseNPC, CDOTA_BaseNPC_Hero, CDOTA_PlayerResource = {}, {}, {}, {}
CDOTA_Buff = {}
Convars = { RegisterConvar = Noop, RegisterCommand = Noop }
local customListeners, sentTables = {}, {}
CustomGameEventManager = {
    RegisterListener = function(_, name, callback) customListeners[name] = callback end,
    Send_ServerToPlayer = function(_, player, name, data)
        if name == "pt_fu" then
            sentTables[player] = sentTables[player] or {}
            sentTables[player][data.name] = true
        end
    end,
    Send_ServerToAllClients = Noop,
}

local playerID = 7
local player = { GetPlayerID = function() return playerID end }
local currentGold = 31500
local selectedHero
PlayerResource = setmetatable({
    GetPlayer = function(_, id) return id == playerID and player or nil end,
    IsValidPlayerID = function(_, id) return id == playerID end,
    GetSelectedHeroEntity = function(_, id) return id == playerID and selectedHero or nil end,
    GetSteamAccountID = function() return 1234 end,
    IsBroadcaster = function() return false end,
    GetPlayerCountForTeam = function() return 0 end,
    GetGold = function() return currentGold end,
    SetGold = function(_, _, amount, reliable)
        if not reliable then currentGold = amount end
    end,
}, { __index = CDOTA_PlayerResource })

local netTables = {}
CustomNetTables = {
    SetTableValue = function(_, name, key, value)
        netTables[name] = netTables[name] or {}
        netTables[name][key] = value
    end,
}
local listeners = {}
function ListenToGameEvent(name, callback, context)
    assert(not listeners[name], "Duplicate game listener: " .. name)
    listeners[name] = function(event) return callback(context, event) end
end

local function EngineSetters()
    return setmetatable({}, { __index = function(t, key)
        if key:match("^Set") then
            local setter = function(_, value) t[key .. "Value"] = value end
            rawset(t, key, setter)
            return setter
        end
    end })
end

local mode = EngineSetters()
local teamCapacity = {}
local state = DOTA_GAMERULES_STATE_WAIT_FOR_PLAYERS_TO_LOAD
local gameTime = 0
GameRules = EngineSetters()
function GameRules:GetGameModeEntity() return mode end
function GameRules:GetGameTime() return gameTime end
function GameRules:GetDOTATime() return 0 end
function GameRules:SendCustomMessage() end
function GameRules:LockCustomGameSetupTeamAssignment() end
function GameRules:EnableCustomGameSetupAutoLaunch() end
function GameRules:State_Get() return state end
function GameRules:SetCustomGameTeamMaxPlayers(team, capacity) teamCapacity[team] = capacity end

local mapMarkers = {
    target_mark_arena_blocker_1 = Vector(1, 2, 3),
    target_mark_arena_blocker_2 = Vector(4, 5, 6),
    target_mark_arena_team2 = Vector(2, 3, 4),
    target_mark_arena_team3 = Vector(3, 4, 5),
}
Entities = {
    FindByName = function(_, _, name)
        local position = mapMarkers[name]
        return position and { GetAbsOrigin = function() return position end }
    end,
    FindAllByName = function() return {} end,
}

local heroOwnerID = -1
local hero = setmetatable({
    IsHero = function() return true end,
    IsRealHero = function() return true end,
    IsAlive = function() return true end,
    IsTempestDouble = function() return false end,
    HasModifier = function() return false end,
    GetPlayerOwner = function() return nil end,
    GetPlayerOwnerID = function() return heroOwnerID end,
    GetEntityIndex = function() return 456 end,
    SetAutoUnstuck = function(self, enabled) self.autoUnstuck = enabled end,
}, {
    __index = function(_, key) return CDOTA_BaseNPC_Hero[key] or CDOTA_BaseNPC[key] end,
})
function EntIndexToHScript(index) return index == 456 and hero or nil end

require("addon_game_mode")
Precache({})
assert(precached.npc_lord_of_death_boss)
assert(modifiers.modifier_creep_loot)
Activate()
local arena = GameRules.GameMode
Activate()
assert(GameRules.GameMode == arena and mode.GameMode == arena)
assert(teamCapacity[DOTA_TEAM_GOODGUYS] == 5 and teamCapacity[DOTA_TEAM_BADGUYS] == 5)
assert(teamCapacity[DOTA_TEAM_CUSTOM_1] == 0)
assert(mode.SetTopBarTeamValuesOverrideValue == true)
assert(netTables.info.version.value == "v0.1")
assert(netTables.arena_match.state.phase == "setup")
assert(listeners.dota_player_pick_hero == nil, "Native hero pick should not run legacy bookkeeping")

listeners.player_connect_full({ PlayerID = playerID, userid = 1 })
listeners.player_connect_full({ PlayerID = playerID, userid = 2 })
assert(arena.vPlayers[playerID] == player and arena.vUserIds[2] == player)
assert(arena.vSteamIds[1234] == player)

sentTables[player] = nil
customListeners.PlayerTables_Connected(nil, { PlayerID = -1, pid = playerID })
assert(sentTables[player] == nil)
customListeners.PlayerTables_Connected(nil, { PlayerID = playerID })
assert(sentTables[player].gold and sentTables[player].arena and sentTables[player].teams)
listeners.npc_spawned({ entindex = 0 })
listeners.entity_hurt({ entindex_killed = 0 })
Physics.Unit = Noop
listeners.npc_spawned({ entindex = 456 })
Timers:Think()
assert(PlayerTables:GetTableValue("player_hero_indexes", playerID) == nil)
heroOwnerID = playerID
gameTime = 0.11
Timers:Think()
assert(PlayerTables:GetTableValue("player_hero_indexes", playerID) == nil)
selectedHero = hero
gameTime = 0.22
Timers:Think()
assert(hero.spellPower == 0 and hero.healingPower == 0 and hero.autoUnstuck)
assert(PlayerTables:GetTableValue("player_hero_indexes", playerID) == 456)
hero.spellPower = 12
listeners.npc_spawned({ entindex = 456, is_respawn = 1 })
assert(hero.spellPower == 12, "Respawn reset the player's hero progression")

local function TimerCount()
    local count = 0
    for _ in pairs(Timers.timers) do count = count + 1 end
    return count
end

state = DOTA_GAMERULES_STATE_PRE_GAME
listeners.game_rules_state_change({})
local pregameTimers = TimerCount()
listeners.game_rules_state_change({})
assert(TimerCount() == pregameTimers and pregameTimers > 0)
assert(netTables.arena_match.state.phase == "pre_game")
assert(netTables.arena_match.state.kill_limit == 10)
assert(Gold:Think() > 0 and Gold:GetGold(playerID) == currentGold)

state = DOTA_GAMERULES_STATE_GAME_IN_PROGRESS
listeners.game_rules_state_change({})
local matchTimers = TimerCount()
listeners.game_rules_state_change({})
assert(TimerCount() == matchTimers and matchTimers > pregameTimers)
assert(netTables.arena_match.state.phase == "in_progress")
assert(Duel.DuelStatus == DOTA_DUEL_STATUS_WATING)
print("Addon startup, reconnect, gold sync, and phase transition smoke test passed")
