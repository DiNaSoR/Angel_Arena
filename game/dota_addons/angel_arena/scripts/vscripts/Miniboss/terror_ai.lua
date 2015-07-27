--[[
Terrorblade Boss AI
]]
-- "vscripts"			"beastmaster_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_reflection_spell = thisEntity:FindAbilityByName("terrorblade_reflection")
	ABILILTY_conjure_image = thisEntity:FindAbilityByName("terrorblade_conjure_image")
	ABILILTY_sunder_spell = thisEntity:FindAbilityByName("terrorblade_sunder")

	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_reflection_spell:IsFullyCastable() then
		print("Terroblade can cast Reflection Image")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Terroblade wants to cast Reflection Image, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnTarget(target, ABILILTY_reflection_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_conjure_image:IsFullyCastable() then
		print("Terroblade wants to cast conjure_image")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Terroblade wants to cast conjure_image, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityNoTarget(ABILILTY_conjure_image, -1)
			else
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_sunder_spell:IsFullyCastable()  and healthRemaining <= 0.20 then
		print("Terroblade can cast sunder")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Terroblade wants to cast sunder, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnTarget(target, ABILILTY_sunder_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.10 then -- last stand
		--ABILILTY_sunder_spell:EndCooldown()
		print("Cooldown")
	end

	print("-------")
	return 1
end
