--[[
Beastmaster Boss AI
]]
-- "vscripts"			"beastmaster_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_wild_axe_spell = thisEntity:FindAbilityByName("beastmaster_wild_axes")
	ABILILTY_roar_spell = thisEntity:FindAbilityByName("beastmaster_primal_roar")
	ABILILTY_call_boar_spell = thisEntity:FindAbilityByName("beastmaster_call_of_the_wild_boar")
	ABILILTY_call_turbo_spell = thisEntity:FindAbilityByName("faster_modifier")

	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
	toggled = false
end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_wild_axe_spell:IsFullyCastable() then
		--print("Beastmaster can cast Wild Axe")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Beastmaster wants to cast Wild Axe, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), ABILILTY_wild_axe_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_call_boar_spell:IsFullyCastable() then
		--print("Beastmaster wants to cast call Boar")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Beastmaster wants to cast call Boar, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
local target = units[index]

				thisEntity:CastAbilityNoTarget(ABILILTY_call_boar_spell, -1)
			else
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_roar_spell:IsFullyCastable()  and healthRemaining <= 0.75 then
		--print("Beastmaster can cast Primal Roar")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Beastmaster wants to cast Primal Roar, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), ABILILTY_roar_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_call_turbo_spell:IsFullyCastable() and healthRemaining <= 0.3 then
		print("Beastmaster can cast turbo")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )
		if toggled == false then
			print("Beastmaster Turbo !!")
			thisEntity:CastAbilityToggle(ABILILTY_call_turbo_spell, -1)
			toggled = true
		end
	end
	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.10 then -- last stand
		ABILILTY_wild_axe_spell:EndCooldown()
	end

	--print("-------")
	return 1
end
