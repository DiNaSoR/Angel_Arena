local non_change_ability_heroes_table = {
	["npc_dota_hero_elder_titan"] = 1,
}

function ChangeTeam( event )
	local hero 		= event.caster
	local player 	= hero:GetPlayerOwner() 
	local playerid 	= hero:GetPlayerOwnerID() 

	if hero:HasModifier("modifier_arc_warden_tempest_double") then return end
	
	CustomGameEventManager:Send_ServerToAllClients("custom_player_change_team", { playerid = playerid})
	ChangeHeroTeam(playerid, player, hero)

end

function ChangeHeroTeam(playerid, player, hero)

	if not hero then return end

	local radiant_heroes, dire_heroes = GetPlayersCount()
	local old_hero = nil
	
	if _G.nCOUNTDOWNTIMER < 10 then return end

	local gold = hero:GetGold()

	if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
		if dire_heroes >= radiant_heroes then return end
		hero:RemoveModifierByName("modifier_rubick_spell_steal")
		player:SetTeam(DOTA_TEAM_BADGUYS)
		hero:SetTeam(DOTA_TEAM_BADGUYS)
		SetPlayerGold(playerid, gold)
		local point = Entities:FindByName( nil, "DIRE_BASE")
		TeleportUnitToEntity(hero, point , true, true)
		PlayerResource:UpdateTeamSlot(playerid, DOTA_TEAM_BADGUYS, 1)
		PlayerResource:SetCustomTeamAssignment(playerid, DOTA_TEAM_BADGUYS)
		
		if hero:GetUnitName() == "npc_dota_hero_lone_druid" then
			local bear = Entities:FindAllByName("npc_dota_lone_druid_bear")
			if bear then
				for i,x in pairs(bear) do
					x:SetTeam(DOTA_TEAM_BADGUYS)
					TeleportUnitToEntity(x, point , true, true)
				end
			end
		end

		if hero:GetUnitName() == "npc_dota_hero_broodmother" then
			local webs = Entities:FindAllByName("npc_dota_broodmother_web")
			if webs then 
				for i = 1, #webs do
					if webs[i] then webs[i]:SetTeam(DOTA_TEAM_BADGUYS) end

				end
			end
		end

		if non_change_ability_heroes_table[hero:GetUnitName()] then
			for i = 0, hero:GetAbilityCount() - 1 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then
					local ability_name = ability:GetName() 
					local ability_level = ability:GetLevel() 
					
					hero:RemoveAbility(ability_name)
					ability = hero:AddAbility(ability_name)
					ability:SetLevel(ability_level)
				end
			end
		end

		print("SET TO BADGUY")
		local cour = Entities:FindAllByName("npc_dota_courier") 
		if cour then
			for i,x in pairs(cour) do
				--print("COUR:",x:GetUnitName(),"TEAM:", x:GetTeamNumber())
				if x and x:GetTeamNumber() == DOTA_TEAM_BADGUYS then
					print("SetControl to", x:GetUnitName())
					x:SetControllableByPlayer(playerid, true)
				end
			end
		end
	elseif hero:GetTeamNumber() == DOTA_TEAM_BADGUYS then 
		if dire_heroes <= radiant_heroes then return end
		hero:RemoveModifierByName("modifier_rubick_spell_steal")
		player:SetTeam(DOTA_TEAM_GOODGUYS)
		hero:SetTeam(DOTA_TEAM_GOODGUYS)
		SetPlayerGold(playerid, gold)
		local point = Entities:FindByName( nil, "RADIANT_BASE") 
		TeleportUnitToEntity(hero, point , true, true)
		print("SET TO GOODGUY")
		PlayerResource:UpdateTeamSlot(playerid, DOTA_TEAM_GOODGUYS, 1)
		PlayerResource:SetCustomTeamAssignment(playerid, DOTA_TEAM_GOODGUYS)
		
		if hero:GetUnitName() == "npc_dota_hero_lone_druid" then
			local bear = Entities:FindAllByName("npc_dota_lone_druid_bear")
			if bear then
				for i,x in pairs(bear) do
					x:SetTeam(DOTA_TEAM_GOODGUYS)
					TeleportUnitToEntity(x, point , true, true)
				end
			end
		end

		if hero:GetUnitName() == "npc_dota_hero_broodmother" then
			local webs = Entities:FindAllByName("npc_dota_broodmother_web")
			if webs then 
				for i = 1, #webs do
					if webs[i] then webs[i]:SetTeam(DOTA_TEAM_BADGUYS) end

				end
			end
		end

		if non_change_ability_heroes_table[hero:GetUnitName()] then
			for i = 0, hero:GetAbilityCount() - 1 do
				local ability = hero:GetAbilityByIndex(i)
				if ability then
					local ability_name = ability:GetName() 
					local ability_level = ability:GetLevel() 
					
					hero:RemoveAbility(ability_name)
					ability = hero:AddAbility(ability_name)
					ability:SetLevel(ability_level)
				end
			end
		end

		local cour = Entities:FindAllByName("npc_dota_courier") 
		if cour then
			for i,x in pairs(cour) do
				--print("COUR:",x:GetUnitName(),"TEAM:", x:GetTeamNumber())
				if x and x:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
					print("SetControl to", x:GetUnitName())
					x:SetControllableByPlayer(playerid, true)
				end
			end
		end
	end


	for i,x in pairs(tHeroesRadiant) do
		if x == hero then
			table.insert(tHeroesDire, x)
			table.remove(tHeroesRadiant, i)
			return
		end
	end

	if old_hero == nil then
		for i,x in pairs(tHeroesDire) do
			if x == hero then
				table.insert(tHeroesRadiant, x)
				table.remove(tHeroesDire, i)
				return
			end
		end
	end
end

function UpdateAllTeamSlots()
	for i = 0, 23 do
		PlayerResource:UpdateTeamSlot(i, DOTA_TEAM_GOODGUYS, true)
		PlayerResource:UpdateTeamSlot(i, DOTA_TEAM_BADGUYS)
	end
end

function SetPlayerGold(playerid, gold)
	if IsServer() then
		PlayerResource:SetGold(playerid, 0, false)
		PlayerResource:SetGold(playerid, 0, true)

		PlayerResource:ModifyGold( playerid, gold, false, 0 )
	end
end


function IsConnected(unit)
    return not IsDisconnected(unit)
end

function IsDisconnected(unit)
    if not unit or not IsValidEntity(unit) then
        return false
    end

    local playerid = unit:GetPlayerOwnerID()
    if not playerid then 
        return false
    end

    local connection_state = PlayerResource:GetConnectionState(playerid) 
    if connection_state == DOTA_CONNECTION_STATE_ABANDONED or connection_state == DOTA_CONNECTION_STATE_DISCONNECTED then
        return true
    else
        return false
    end
end

function IsAbadoned(unit)
    if not unit or not IsValidEntity(unit) then
    	return false 
    end

    local playerid = unit:GetPlayerOwnerID()
    if not playerid then 
    	return false 
    end

    local connection_state = PlayerResource:GetConnectionState(playerid) 

    if connection_state == DOTA_CONNECTION_STATE_ABANDONED then 
        return true 
    else 
        return false
    end
end