--[[
Ahmhedoq Boss AI
]]
-- "vscripts"			"ahmhedoq_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_dragon_slave_spell = thisEntity:FindAbilityByName("lina_dragon_slave")

	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_dragon_slave_spell:IsFullyCastable()  and healthRemaining <= 0.70 then
		print("Ahmhedoq can cast dragon_slave")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Ahmhedoq wants to cast dragon_slave, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition( target:GetAbsOrigin(), ABILILTY_dragon_slave_spell, -1 )
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.15 then -- last stand
		ABILILTY_dragon_slave_spell:EndCooldown()
	end

	return 1
end
