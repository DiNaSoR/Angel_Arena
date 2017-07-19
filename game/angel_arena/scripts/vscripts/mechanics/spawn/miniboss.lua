-- By: DiNaSoR
--------------------------------------------------------------
-- Mini Bosses respawn time table.
--------------------------------------------------------------
PAIMON_MINI_BOSS_RESPAWN_TIME = 300


--------------------------------------------------------------
-- Checking minibosses if they got killed.
--------------------------------------------------------------
function checkminibosses(keys)
	-- Check what kind of Unit got killed
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	local killerEntity = EntIndexToHScript( keys.entindex_attacker )
	-- Get Unit Name that was Killed
	local unitName = killedUnit:GetUnitName()
	if unitName == "npc_paimon_mini_boss" then
	   	print("Paimon Mini Boss killed")
	   	paimonminiboss()    

    elseif unitName == "npc_dota_bador_pudge" and killerEntity:GetTeam() == DOTA_TEAM_GOODGUYS then
    	GameRules:SetSafeToLeave( true )
		GameRules:SetGameWinner( DOTA_TEAM_GOODGUYS )

	elseif unitName == "npc_dota_bador_pudge" and killerEntity:GetTeam() == DOTA_TEAM_BADGUYS then
    	GameRules:SetSafeToLeave( true )
		GameRules:SetGameWinner( DOTA_TEAM_BADGUYS )
	else
   		--print("Not Demon Mini Boss")
    end

end


--------------------------------------------------------------
-- Mini Bosses respawns
--------------------------------------------------------------
function paimonminiboss()
	print("Paimon Mini Boss respawn in 5 min")
    Timers:CreateTimer(PAIMON_MINI_BOSS_RESPAWN_TIME, 
        function()
            drop = Vector(7168, -6912, 128)
    		local spawn = CreateUnitByName("npc_paimon_mini_boss", drop, true, nil, nil, DOTA_TEAM_NEUTRALS)
    end)
end