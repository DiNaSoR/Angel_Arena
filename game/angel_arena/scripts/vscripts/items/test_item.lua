function TestDOING( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	--caster:AddExperience(1000, 0, true, true)

	--[[
	local spawn_table = {
		origin = caster:GetAbsOrigin(),
	}

	local rune = SpawnEntityFromTableSynchronous("dota_item_rune", spawn_table )
   	if rune then
   		rune:SetModel("models/props_gameplay/rune_goldxp.vmdl")
   		print(rune:GetEntityHandle())

   		local tOrder = {
			UnitIndex = caster:GetEntityIndex(), 
			OrderType = DOTA_UNIT_ORDER_PICKUP_RUNE,
			TargetIndex = rune:entindex() ,
		}
		ExecuteOrderFromTable(tOrder)

   	else 
   		print('not valid')
   	end
]]

	print_d("target '" .. target:GetUnitName() .. "'' modifiers:")
	for i = 0, target:GetModifierCount()-1 do
		print_d(" |-> " .. target:GetModifierNameByIndex(i))
	end
end