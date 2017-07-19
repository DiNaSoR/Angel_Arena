---------------------------------------------------------------------------
-- On any Item Picked Up by Heroes
---------------------------------------------------------------------------

---------------------------------------------------------------------------
-- When Gold Bag picked up
---------------------------------------------------------------------------
function goldpickup(keys)
		--[[local item 		= EntIndexToHScript( event.ItemEntityIndex )
		local owner 	= EntIndexToHScript( event.HeroEntityIndex )
		

	if event.itemname == "item_clarity" then
		
		print ("picker: " .. owner:GetName() .. " -- " .. item:GetName())
		r = RandomInt(150, 300)

				--print("Bag of gold picked up")
				PlayerResource:ModifyGold( owner:GetPlayerOwnerID(), r, true, 0 )
				SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
				UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	else
	print("nothero")	
	end]]

	local item = EntIndexToHScript(keys.ItemEntityIndex)

	if keys.HeroEntityIndex ~= nil then
		local owner = EntIndexToHScript(keys.HeroEntityIndex) 
		if keys.itemname == "item_bag_of_gold" then			
			--print ("picker: " .. owner:GetName() .. " -- " .. item:GetName())
			r = RandomInt(150, 300)
			--print("Bag of gold picked up")
			PlayerResource:ModifyGold( owner:GetPlayerOwnerID(), r, true, 0 )
			SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, r, nil )
			UTIL_Remove( item ) -- otherwise it pollutes the player inventory
		else	
		end
	end
end