--[[
Wraith Frost King Boss AI
]]
-- "vscripts"			"beastmaster_ai.lua"

function Spawn( entityKeyValues )
	ABILILTY_hellfire_blast_spell = thisEntity:FindAbilityByName("skeleton_king_hellfire_blast")

	thisEntity:AddItemByName("item_aegis")

	thisEntity:SetContextThink( "SteamtankThink", SteamtankThink , 1)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function SteamtankThink()
	-- Move to the next waypoint after taking enough damage
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	--Cast Spawn whenever we're able to do so.
	if ABILILTY_hellfire_blast_spell:IsFullyCastable() then
		print("Wraith Frost King can cast hellfire_blast")
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 525, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				print("Wraith Frost King wants to cast hellfire_blast, ".. #units .." enemy near.")
				local index = RandomInt( 1, #units )
				local target = units[index]

				thisEntity:CastAbilityOnTarget(target, ABILILTY_hellfire_blast_spell, -1)
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
