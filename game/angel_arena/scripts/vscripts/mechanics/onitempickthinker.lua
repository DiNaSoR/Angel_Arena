function goldpickup(event)
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

		local item = EntIndexToHScript(event.ItemEntityIndex)
	if event.HeroEntityIndex ~= nil then
		local owner = EntIndexToHScript(event.HeroEntityIndex) 
					if event.itemname == "item_bag_of_gold" then
					
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