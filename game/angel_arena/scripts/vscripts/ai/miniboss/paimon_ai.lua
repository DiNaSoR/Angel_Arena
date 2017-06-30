PAIMON_AI_VERSION = "1.1"
--------------------------------------------------------------
-- Setting
--------------------------------------------------------------


--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------
function 	Spawn( entityKeyValues )
	print("Starting AI for "..thisEntity:GetUnitName().." "..PAIMON_AI_VERSION)		
	thisEntity:SetContextThink( "AIThinking", AIThinking , 0.5)

end

--------------------------------------------------------------
-- AI Behavior
--------------------------------------------------------------
function AIThinking()

    local point = Vector(-2752, -1280, 129.354)
    local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
    
    if thisEntity:IsNull() or not thisEntity:IsAlive() then
        return nil
    end 

    if #units <= 0 then
        thisEntity:MoveToPosition(point)
    end

    if (point - thisEntity:GetOrigin()):Length() > 1200 then
        thisEntity:MoveToPosition(point)
        dialogpudge()
    end
 
    return 0.5;
end
