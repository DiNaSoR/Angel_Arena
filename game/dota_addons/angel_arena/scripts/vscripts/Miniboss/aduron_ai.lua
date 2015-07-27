--[[
Aduron Boss AI
]]
-- "vscripts"			"aduron_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_spirit_searing_chains_spell = thisEntity:FindAbilityByName("ember_spirit_searing_chains")

	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_spirit_searing_chains_spell:IsFullyCastable()  and healthRemaining <= 0.75 then
		print("Aduron can cast spirit_searing_chains")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Aduron wants to cast spirit_searing_chains, ".. #units .." enemy near.")

				thisEntity:CastAbilityNoTarget( ABILILTY_spirit_searing_chains_spell, -1)
			else 
				print("No units found to cast the spell on")
			end
		end
	end

	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.10 then -- last stand
		ABILILTY_spirit_searing_chains_spell:EndCooldown()
	end
	
	return 1
end
