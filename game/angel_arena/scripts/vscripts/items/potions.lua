function RemoveRegeneration( event )
	local caster = event.caster
	caster:RemoveModifierByName("modifier_potion_of_lesser_regeneration")
	caster:RemoveModifierByName("modifier_potion_of_regeneration")
	caster:RemoveModifierByName("modifier_potion_of_greater_regeneration")
	caster:RemoveModifierByName("modifier_potion_of_super_regeneration")
	caster:RemoveModifierByName("modifier_potion_of_mega_regeneration")
	caster:RemoveModifierByName("modifier_scroll_of_lesser_regeneration")
	caster:RemoveModifierByName("modifier_scroll_of_regeneration")
	caster:RemoveModifierByName("modifier_scroll_of_greater_regeneration")
	caster:RemoveModifierByName("modifier_scroll_of_greater_regeneration")
end

-- Remove _regeneration based buffs on all passed targets
function RemoveRegenerationScroll( event )
	local targets = event.target_entities
	for _,target in pairs(targets) do
		target:RemoveModifierByName("modifier_potion_of_lesser_regeneration")
		target:RemoveModifierByName("modifier_potion_of_regeneration")
		target:RemoveModifierByName("modifier_potion_of_greater_regeneration")
		target:RemoveModifierByName("modifier_potion_of_super_regeneration")
		target:RemoveModifierByName("modifier_potion_of_mega_regeneration")
		target:RemoveModifierByName("modifier_scroll_of_lesser_regeneration")
		target:RemoveModifierByName("modifier_scroll_of_regeneration")
		target:RemoveModifierByName("modifier_scroll_of_greater_regeneration")
		target:RemoveModifierByName("modifier_scroll_of_super_regeneration")
	end
end

function RemoveElixir( event )
	local caster = event.caster
	-- Iterate over modifiers looking for "elixir_"
	local modCount = spawnedUnitIndex:GetModifierCount()
	for i = 0, modCount do
		local modifier_name = spawnedUnitIndex:GetModifierNameByIndex(i)
		if string.find(modifier_name, "elixir_") then
			caster:RemoveModifierByName(modifier_name)
			print("Removed "..modifier_name.." before applying the new elixir")
		end
	end
end