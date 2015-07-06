
if 	Bador == nil then
	_G.Bador = class({})
end

--//--------------------------------------------------------------------------------------
--//	Precache - Load required assets
--//--------------------------------------------------------------------------------------
function Precache( context )
	PrecacheUnitByNameSync("npc_dota_hero_pudge",context)
end

--//--------------------------------------------------------------------------------------
--//	Activate
--//--------------------------------------------------------------------------------------
-- Create the game mode when we activate
function Activate()
				GameRules.Bador = Bador()
				GameRules.Bador:InitGameMode()
				
	
	
	-- I dont know how to make Pudge think if he away from a point must come back to it


end

--ListenToGameEvent("player_connect", mapgo, nil)
--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------
function 	Bador:InitGameMode()
				
				print( "[Bador] BADOR-InitGameMode is loaded." )
				hook = thisEntity:FindAbilityByName("skill_pudge_meat_hook")
				rot = thisEntity:FindAbilityByName("pudge_rot")
				dism = thisEntity:FindAbilityByName("pudge_dismember")
	
				
				
				thisEntity:SetContextThink("HookDem", HookDem, 0.2)
				thisEntity:SetContextThink("RotDem", RotDem, 0.5)
				thisEntity:SetContextThink("Dism", Dism, 0.4)

				
				-- This Line will checks everything that dies and calls Badorkilled
				--ListenToGameEvent('entity_killed', Dynamic_Wrap(Bador, 'Badorkilled'), self)
				
				
			
end


--//--------------------------------------------------------------------------------------
--//	Hold position
--//--------------------------------------------------------------------------------------
function Hold()
	order =
	{
		OrderType = DOTA_UNIT_ORDER_HOLD_POSITION,
		UnitIndex = thisEntity:entindex(),
	}
	ExecuteOrderFromTable( order )
end


--//--------------------------------------------------------------------------------------
--//	Hook
--//--------------------------------------------------------------------------------------
function HookDem()

	local target
	if hook and hook:IsFullyCastable() then

		local allEnemies = FindUnitsInRadius( DOTA_TEAM_NOTEAM, thisEntity:GetOrigin(), nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )

		if #allEnemies > 0 then
		


			local index = RandomInt( 1, #allEnemies )

			target = allEnemies[index]
		end
			
	
	end

	if target then
		order =
		{

			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,

			UnitIndex = thisEntity:entindex(),

			Position = target:GetOrigin(),

			TargetIndex = target:entindex(),

			AbilityIndex = hook:entindex(),

		}
		ExecuteOrderFromTable( order )

		return RandomInt(3,8)
		
	else
		return 3
		
	end
end


--//--------------------------------------------------------------------------------------
--//	Dismember
--//--------------------------------------------------------------------------------------
function Dism()

	local target

	
		if dism and dism:IsFullyCastable() then
	
		local allEnemies = FindUnitsInRadius( DOTA_TEAM_NOTEAM, thisEntity:GetOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
		
		if #allEnemies > 0 then
		
			local index = RandomInt( 1, #allEnemies )
			
			target = allEnemies[index]
	
		end
	end

		if target then
		order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			
			UnitIndex = thisEntity:entindex(),
			Position = target:GetOrigin(),
			TargetIndex = target:entindex(),
			
			AbilityIndex = dism:entindex(),
			
		}
		ExecuteOrderFromTable( order )
		return RandomInt(3,8)
	else
		
		return 3
	end
	
end


--//--------------------------------------------------------------------------------------
--//	Rot
--//--------------------------------------------------------------------------------------
function RotDem()


	local target

	
	
		order =
		{
			OrderType = DOTA_UNIT_ORDER_CAST_TOGGLE,
			UnitIndex = thisEntity:entindex(),
			AbilityIndex = rot:entindex(),
			
		}
		ExecuteOrderFromTable( order )

		
		return RandomInt(3,8)
		
end




--//--------------------------------------------------------------------------------------
--//	Drop loot
--//--------------------------------------------------------------------------------------
--[[NumberOfBlinkDagger = 5
function Bador:Badorkilled(keys)
	local unit = EntIndexToHScript(keys.entindex_killed)
	if string.find(unit:GetUnitName(),"npc_dota_bador_pudge") then
		local i = 1
		while NumberOfBlinkDagger>=i do
	        print ("We found Bador GOT KILLED LETS CALL SPAWNUNITS FUNCTION")
	        local 	badordrop = CreateItem( "generic_gold_bag_fountain_15", nil, nil )
			--badordrop:SetPurchaseTime( 0 )
			CreateItemOnPositionSync( unit:GetAbsOrigin() + RandomVector(200), badordrop )
			print ("ITEM DROPPED FROM BADOR")	
			i = i + 1
		end		
	end
end]]
-------------------------------------------------------------------------------------------------------------------------------------------------------
