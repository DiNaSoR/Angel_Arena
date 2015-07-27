--[[
Elder Titan Boss AI
]]
-- "vscripts"			"tian_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_echo_stomp_spell = thisEntity:FindAbilityByName("elder_titan_echo_stomp")
	ABILILTY_earth_splitter_spell = thisEntity:FindAbilityByName("elder_titan_earth_splitter")

	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_echo_stomp_spell:IsFullyCastable() then
		--print("Elder Titan can cast echo_stomp")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Elder Titan wants to cast call echo_stomp, ".. #units .." enemy near.")
				thisEntity:CastAbilityNoTarget(ABILILTY_echo_stomp_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	if ABILILTY_earth_splitter_spell:IsFullyCastable() and healthRemaining <= 0.60 then
		--print("Elder Titan wants to cast call earth_splitter")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Elder Titan wants to cast call earth_splitter, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnPosition( target:GetAbsOrigin(), ABILILTY_earth_splitter_spell, -1 )
			else
				print("No units found to cast the spell on")
			end
		end
	end

	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.10 then -- last stand
		--ABILILTY_wild_axe_spell:EndCooldown()
	end

	--print("-------")
	return 1
end
