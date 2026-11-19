package.path = "game/angel_arena/scripts/vscripts/?.lua;" .. package.path

DOTA_TEAM_GOODGUYS = 2
DOTA_TEAM_BADGUYS = 3
DOTA_TEAM_NEUTRALS = 4
DOTA_GAMERULES_STATE_POST_GAME = 8
END_GAME_ON_KILLS = true
KILLS_TO_END_GAME_FOR_TEAM = 0
USE_CUSTOM_TOP_BAR_VALUES = true
SHOW_KILLS_ON_TOPBAR = true

local leaders = {}
local winners = {}
local finishedDuels = 0
Duel = {
    FinishMatch = function()
        finishedDuels = finishedDuels + 1
    end,
}
local snapshot
local nativeTopBar = {
    SetTopBarTeamValue = function(_, team, score)
        leaders[team] = score
    end,
}

CustomNetTables = {
    SetTableValue = function(_, name, key, value)
        assert(name == "arena_match" and key == "state")
        snapshot = {}
        for field, item in pairs(value) do
            snapshot[field] = item
        end
    end,
}

GameRules = {
    State_Get = function()
        return DOTA_GAMERULES_STATE_POST_GAME
    end,
    GetGameModeEntity = function()
        return nativeTopBar
    end,
    SetSafeToLeave = function(_, safe)
        assert(safe)
    end,
    SetGameWinner = function(_, winner)
        assert(snapshot.winner == winner and snapshot.phase == "finished")
        winners[#winners + 1] = winner
    end,
}

local entities = {}
local function NewEntity(team, name, heroKind)
    local unit = {
        GetTeamNumber = function()
            return team
        end,
        GetUnitName = function()
            return name
        end,
        IsTrueHero = function()
            return heroKind == "hero" or heroKind == "clone" or heroKind == "illusion"
        end,
        IsIllusion = function()
            return heroKind == "illusion"
        end,
        IsClone = function()
            return heroKind == "clone"
        end,
        IsReincarnating = function(self)
            return self.reincarnating
        end,
        GetPlayerOwner = function()
            return nil
        end,
        CalculateRespawnTime = function()
            return 8
        end,
        SetTimeUntilRespawn = function(self, respawnTime)
            self.respawnTime = respawnTime
        end,
    }
    local index = #entities + 1
    entities[index] = unit
    return index, unit
end

EntIndexToHScript = function(index)
    return entities[index]
end

IsValidEntity = function(entity)
    return not entity.removed
end

GameMode = {}
local ArenaScore = require('mechanics/match/score')
require('mechanics/spawn/miniboss')
require('setting/events')

local angel = NewEntity(DOTA_TEAM_GOODGUYS, "angel", "hero")
local demon, demonUnit = NewEntity(DOTA_TEAM_BADGUYS, "demon", "hero")
local allied = NewEntity(DOTA_TEAM_BADGUYS, "demon ally", "hero")
local neutral = NewEntity(DOTA_TEAM_NEUTRALS, "neutral")
local illusion = NewEntity(DOTA_TEAM_BADGUYS, "demon illusion", "illusion")
local clone = NewEntity(DOTA_TEAM_BADGUYS, "demon clone", "clone")
local boss = NewEntity(DOTA_TEAM_NEUTRALS, "npc_dota_bador_pudge")

local function EntityKilled(victim, attacker)
    GameMode:OnEntityKilled({ entindex_killed = victim, entindex_attacker = attacker })
end

ArenaScore.Initialize(GameMode)
assert(snapshot.angels == 0 and snapshot.demons == 0 and snapshot.winner == 0)
assert(snapshot.phase == "setup" and snapshot.kill_limit == 10)

KILLS_TO_END_GAME_FOR_TEAM = 2
ArenaScore.SetPhase(GameMode, "pre_game")
assert(snapshot.phase == "pre_game" and snapshot.kill_limit == 2)
EntityKilled(demon, angel)
assert(snapshot.angels == 0)
assert(demonUnit.respawnTime == 8)

ArenaScore.SetPhase(GameMode, "in_progress")
demonUnit.reincarnating = true
demonUnit.respawnTime = nil
demonUnit.OnDuel = true
EntityKilled(demon, angel)
assert(snapshot.angels == 0 and not demonUnit.respawnTime and demonUnit.OnDuel)
demonUnit.reincarnating = nil
demonUnit.OnDuel = nil

EntityKilled(nil, angel)
EntityKilled(demon, nil)
EntityKilled(demon, demon)
EntityKilled(demon, allied)
EntityKilled(demon, neutral)
EntityKilled(illusion, angel)
EntityKilled(clone, angel)
EntityKilled(boss, nil)
EntityKilled(boss, neutral)
assert(snapshot.angels == 0 and snapshot.demons == 0 and #winners == 0)

EntityKilled(demon, angel)
assert(snapshot.angels == 1 and snapshot.winner == 0)
assert(leaders[DOTA_TEAM_GOODGUYS] == 1)
EntityKilled(angel, demon)
assert(snapshot.demons == 1 and leaders[DOTA_TEAM_BADGUYS] == 1)
EntityKilled(demon, angel)
assert(snapshot.winner == DOTA_TEAM_GOODGUYS and snapshot.victory_reason == "kills")
assert(snapshot.angels == 2 and #winners == 1)

EntityKilled(angel, demon)
EntityKilled(boss, demon)
ArenaScore.SetPhase(GameMode, "in_progress")
assert(snapshot.demons == 1 and #winners == 1 and snapshot.phase == "finished" and finishedDuels == 1)

END_GAME_ON_KILLS = false
ArenaScore.Initialize(GameMode)
ArenaScore.SetPhase(GameMode, "in_progress")
EntityKilled(demon, angel)
EntityKilled(demon, angel)
assert(snapshot.kill_limit == 0 and snapshot.angels == 2 and snapshot.winner == 0)
EntityKilled(boss, demon)
assert(snapshot.winner == DOTA_TEAM_BADGUYS and snapshot.victory_reason == "boss")
assert(#winners == 2 and winners[2] == DOTA_TEAM_BADGUYS and finishedDuels == 2)

ArenaScore.Initialize(GameMode)
ArenaScore.SetPhase(GameMode, "in_progress")
GameMode:OnGameRulesStateChange()
ArenaScore.SetPhase(GameMode, "in_progress")
EntityKilled(demon, angel)
EntityKilled(boss, angel)
assert(snapshot.phase == "finished" and snapshot.angels == 0 and #winners == 2)

print("Arena score and victory checks passed")
