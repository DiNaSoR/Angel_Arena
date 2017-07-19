local personal_cour_ids = {
	[73911256	] = 1, -- cry
	[112315140	] = 1, -- aleshka
	[136098003	] = 1, -- homie
	[126897357	] = 1, -- alky
	[104356809	] = 1, -- Sheodar (za kloziki)
	[191556216  ] = 1, -- #SUPREME poka shto ostav
	--[259404667	] = 1, -- na 3 mesaca s 04.12.16 (end = 04.03.17)
	--[347133312  ] = 1, -- gish 2mesaca s 17.12 (end = 17.02.17)
}

function OnSpellStart(keys)
	local hero = keys.caster
	local player = hero:GetPlayerOwner()
	local pid = player:GetPlayerID()
	local steam_account_id = PlayerResource:GetSteamAccountID( player:GetPlayerID() )
	_G.pers_cour = _G.pers_cour or {}

	UTIL_Remove(keys.ability);
	if(not hero:IsRealHero() ) then return end
	
	if(not _G.pers_cour[pid] and personal_cour_ids[steam_account_id] ) then
		local has_cour = false;
		local couriers = Entities:FindAllByName("npc_dota_courier") 
		
		for _, x in pairs(couriers) do
			if x and IsValidEntity(x) and x:GetTeamNumber() == hero:GetTeamNumber() then has_cour = true; end
		end

		if not has_cour then 
			print("creating private courier")
			local cr = CreateUnitByName("npc_dota_courier", hero:GetAbsOrigin() + RandomVector(RandomFloat(100, 100)), true, nil, nil, hero:GetTeamNumber())
			for i = 0, 20 do
  			local temp_ply = PlayerResource:GetPlayer(i)
  			if(temp_ply and IsValidEntity(temp_ply)) then
  				Timers:CreateTimer(.1, function()
  					if(temp_ply:GetTeamNumber() == cr:GetTeamNumber() ) then
  						cr:SetControllableByPlayer(i, true)
  					end
  				end)		
  			end
  		end
			return 
		end

		local cr = CreateUnitByName("npc_dota_courier", hero:GetAbsOrigin() + RandomVector(RandomFloat(100, 100)), true, nil, nil, hero:GetTeamNumber())

		Timers:CreateTimer(.1, function()
			print("creating private courier")
     		cr:SetControllableByPlayer(hero:GetPlayerID(), true)
     		cr.personal = pid;
     		
  			_G.pers_cour[pid] = cr;
  		end)	
  		
  	else 
  		local cr = CreateUnitByName("npc_dota_courier", hero:GetAbsOrigin() + RandomVector(RandomFloat(100, 100)), true, nil, nil, hero:GetTeamNumber())

  		for i = 0, 20 do
  			local temp_ply = PlayerResource:GetPlayer(i)
  			if(temp_ply and IsValidEntity(temp_ply)) then
  				Timers:CreateTimer(.1, function()
  					if(temp_ply:GetTeamNumber() == cr:GetTeamNumber() ) then
  						cr:SetControllableByPlayer(i, true)
  					end
  				end)		
  			end
  		end
	end
end
