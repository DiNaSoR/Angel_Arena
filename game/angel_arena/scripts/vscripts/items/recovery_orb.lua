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

local passive_used = {}

local DOTA_ABILITY_TYPE_ULTIMATE = 1

function Refresh( keys )
	local caster 	= keys.caster

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

function PassiveRefresh( keys )
	local caster 			= keys.caster
	local chance_ability 	= keys.ChanceAbility 
	local chance_ultimate 	= keys.ChanceUltimate 
	local ability 			= keys.event_ability

	if not ability then return end
	
	if ability == keys.ability then return end 

	local ability_type = ability:GetAbilityType()

	if ability_type == DOTA_ABILITY_TYPE_ULTIMATE then
		chance_ability = chance_ultimate
	end
	
	passive_used[ability] = passive_used[ability] or 0

	passive_used[ability] = passive_used[ability] - 1

	if RollPercentage(chance_ability) then
		if passive_used[ability] <= 0 then
			ability:EndCooldown() 
			passive_used[ability] = 2
		end
	end
	
end
