function 	Spawn( entityKeyValues )
				
	faceless_ability = thisEntity:FindAbilityByName("faceless_void_time_walk")
	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	thisEntity:SetContextThink( "AIOther", AIOther , 0.5)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end
-------

function AIOther()

    if thisEntity:IsNull() or not thisEntity:IsAlive() then
        return nil
    end


    local point = Vector(-2752, -1280, 129.354)

    if (point - thisEntity:GetOrigin()):Length() > 1200 then
        thisEntity:MoveToPosition(point)
    end
 
    return 0.5;
end


function SteamtankThink()


	if faceless_ability:IsFullyCastable() then
		local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

		if units ~= nil then
			if #units >= 1 then
				
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(),faceless_ability, -1)
				print("Elder Titan wants to cast call earth_splitter, ".. #units .." enemy near.")
			else
				--print("No units found to cast the spell on")
			end
		end
	end
	return 1
end
