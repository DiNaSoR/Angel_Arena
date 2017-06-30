--[[
Year Beast (CNY) Boss AI
]]
-- "vscripts"			"cny_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_liquid_fire_spell = thisEntity:FindAbilityByName("jakiro_liquid_fire")
	ABILILTY_thunder_clap_image = thisEntity:FindAbilityByName("brewmaster_thunder_clap")
	ABILILTY_acid_spray_spell = thisEntity:FindAbilityByName("alchemist_acid_spray")
	ABILILTY_dual_breath_spell = thisEntity:FindAbilityByName("jakiro_dual_breath")
	ABILILTY_macropyre_spell = thisEntity:FindAbilityByName("jakiro_macropyre")

	thisEntity:AddItemByName("item_gem")
	
	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_liquid_fire_spell:IsFullyCastable() then
		print("Year Beast can cast Liquid Fire")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Year Beast wants to cast Liquid Fire, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), ABILILTY_liquid_fire_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end 
	end

	if ABILILTY_thunder_clap_image:IsFullyCastable() and healthRemaining <= 0.50 then
		print("Year Beast wants to cast Thunder Clap")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 380, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Terroblade wants to cast Thunder Clap, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(),ABILILTY_thunder_clap_image, -1)
			else
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_acid_spray_spell:IsFullyCastable()  and healthRemaining <= 0.75 then
		print("Year Beast can cast Acid Spray")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Year Beast wants to cast Acid Spray, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), ABILILTY_acid_spray_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_dual_breath_spell:IsFullyCastable()  and healthRemaining <= 0.50 then
		print("Year Beast can cast dual_breath")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Year Beast wants to cast dual_breath, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), ABILILTY_dual_breath_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_macropyre_spell:IsFullyCastable()  and healthRemaining <= 0.30 then
		print("Year Beast can cast macropyre")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 750, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Year Beast wants to cast macropyre, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), ABILILTY_macropyre_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.10 then -- last stand
		ABILILTY_liquid_fire_spell:EndCooldown()
		print("Cooldown")
	end
	return 1
end
