local non_refreshable = {
	--["omniknight_protection_of_god"] 	= 1,
	["item_refresher"] 					= 1,
	["angel_arena_transmute"]			= 1,
	["item_recovery_orb"]				= 1,
	["item_pet_hulk"] 					= 1,
	["item_pet_mage"] 					= 1,
	["item_pet_wolf"] 					= 1,
	["spike_conclusion"] 				= 1,

}

function Refresh(keys)
	local caster 	= keys.caster
	local ability 	= keys.ability

	for i = 0, caster:GetAbilityCount() - 1 do
		local refresh_ability = caster:GetAbilityByIndex(i)
		
		if refresh_ability and not non_refreshable[refresh_ability:GetName()] then
			refresh_ability:EndCooldown()
		end

	end

	for i = 0, 11 do
		local refresh_item = caster:GetItemInSlot(i)
		
		if refresh_item and not non_refreshable[refresh_item:GetName()] then
			refresh_item:EndCooldown()
		end

	end
end