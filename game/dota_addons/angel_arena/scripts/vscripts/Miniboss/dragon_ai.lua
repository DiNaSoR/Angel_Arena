--[[
Dragon Knight Boss AI
]]
-- "vscripts"			"beastmaster_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_breathe_fire_spell = thisEntity:FindAbilityByName("dragon_knight_breathe_fire")
	ABILILTY_dragon_tail_spell = thisEntity:FindAbilityByName("dragon_knight_dragon_tail")
	ABILILTY_elder_dragon_form_spell = thisEntity:FindAbilityByName("dragon_knight_elder_dragon_form")

	thisEntity:AddItemByName("item_aegis")

	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_breathe_fire_spell:IsFullyCastable() then
		print("Dragon Knight can cast hellfire_blast")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 495, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Dragon Knight wants to cast hellfire_blast, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(),ABILILTY_breathe_fire_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_dragon_tail_spell:IsFullyCastable() then
		print("Dragon Knight can cast dragon_tail")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 120, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Dragon Knight wants to cast dragon_tail, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnTarget(target, ABILILTY_dragon_tail_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_elder_dragon_form_spell:IsFullyCastable() then
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 495, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		print("Dragon Knight wants to cast elder_dragon_form, ".. #units .." enemy near.")
		thisEntity:CastAbilityNoTarget( ABILILTY_elder_dragon_form_spell, -1 )
	end

	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.10 then -- last stand
		--ABILILTY_sunder_spell:EndCooldown()
		print("Cooldown")
	end

	print("-------")
	return 1
end
