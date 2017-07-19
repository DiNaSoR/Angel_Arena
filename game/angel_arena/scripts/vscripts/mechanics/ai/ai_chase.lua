function log_npc( event )
	local index = event.entindex
	local unit = EntIndexToHScript(index)
	if Convars:GetBool("developer") == true then
		print("Index: "..index.." Name: "..unit:GetUnitName().." Created time: "..GameRules:GetGameTime().." at x= "..unit:GetOrigin().x.." y= "..unit:GetOrigin().y)
	end

	-- Wait 1 frame else they'll want to move to 0 0 0 if spawned through lua.
	Timers:CreateTimer(function() 
		if unit:GetTeam() == DOTA_TEAM_NEUTRALS and unit.AddAbility ~= nil and unit.GetInvulnCount == nil then
			if unit.initial_neutral_position == nil then
				unit.initial_neutral_position = unit:GetAbsOrigin()
			end
			unit:SetContextThink("chase_distance_function", 
				function ()
					if unit:GetTeam() == DOTA_TEAM_NEUTRALS then
						if (unit.initial_neutral_position - unit:GetAbsOrigin()):Length2D() > 900 then
							unit:MoveToPosition(unit.initial_neutral_position) 
						end

						return math.random(2,6)
					else
						return nil
					end
				end
				, 5) 
		end
	end)
end

if log_npc_loaded == nil then
	ListenToGameEvent( "npc_spawned", log_npc, nil )
	log_npc_loaded = true
end