local ArenaScore = require('mechanics/match/score')

PAIMON_MINI_BOSS_RESPAWN_TIME = 300

function checkminibosses(gameMode, killedUnit, attacker)
    local unitName = killedUnit:GetUnitName()
    if unitName == "npc_paimon_mini_boss" then
        print("Paimon Mini Boss killed")
        paimonminiboss()
    elseif unitName == "npc_dota_bador_pudge" and attacker and attacker.GetTeamNumber then
        local team = attacker:GetTeamNumber()
        if team ~= killedUnit:GetTeamNumber() then
            ArenaScore.Finish(gameMode, team, "boss")
        end
    end
end

function paimonminiboss()
    print("Paimon Mini Boss respawns in 5 minutes")
    Timers:CreateTimer(PAIMON_MINI_BOSS_RESPAWN_TIME, function()
        local position = Vector(7168, -6912, 128)
        CreateUnitByName("npc_paimon_mini_boss", position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    end)
end
