local ArenaScore = {}

local scoreKeys = {
    [DOTA_TEAM_GOODGUYS] = "angels",
    [DOTA_TEAM_BADGUYS] = "demons",
}

local function GetKillLimit()
    if not END_GAME_ON_KILLS then
        return 0
    end
    if KILLS_TO_END_GAME_FOR_TEAM > 0 then
        return KILLS_TO_END_GAME_FOR_TEAM
    end
    return 10
end

local function Publish(state)
    CustomNetTables:SetTableValue("arena_match", "state", state)
end

function ArenaScore.Initialize(gameMode)
    gameMode.arenaScore = {
        angels = 0,
        demons = 0,
        kill_limit = GetKillLimit(),
        phase = "setup",
        winner = 0,
        victory_reason = "",
    }
    Publish(gameMode.arenaScore)
end

function ArenaScore.SetPhase(gameMode, phase)
    local state = gameMode.arenaScore
    if state.phase == "finished" then
        return
    end

    state.phase = phase
    state.kill_limit = GetKillLimit()
    Publish(state)
end

function ArenaScore.Finish(gameMode, team, reason)
    local state = gameMode.arenaScore
    if state.phase ~= "in_progress" or not scoreKeys[team] then
        return
    end

    state.winner = team
    state.victory_reason = reason
    state.phase = "finished"
    Publish(state)

    GameRules:SetSafeToLeave(true)
    GameRules:SetGameWinner(team)
    if Duel then
        Duel:FinishMatch()
    end
end

function ArenaScore.RecordHeroKill(gameMode, victim, attacker)
    local state = gameMode.arenaScore
    if state.phase ~= "in_progress" or not attacker or not attacker.GetTeamNumber then
        return
    end

    local attackerTeam = attacker:GetTeamNumber()
    local victimTeam = victim:GetTeamNumber()
    local scoreKey = scoreKeys[attackerTeam]
    if not scoreKey or not scoreKeys[victimTeam] or attackerTeam == victimTeam then
        return
    end

    local score = state[scoreKey] + 1
    state[scoreKey] = score
    if USE_CUSTOM_TOP_BAR_VALUES and SHOW_KILLS_ON_TOPBAR then
        GameRules:GetGameModeEntity():SetTopBarTeamValue(attackerTeam, score)
    end

    if state.kill_limit > 0 and score >= state.kill_limit then
        ArenaScore.Finish(gameMode, attackerTeam, "kills")
    else
        Publish(state)
    end
end

return ArenaScore
