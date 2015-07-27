--------------------------------------------------------------
-- Bador AI Class
--------------------------------------------------------------
if 	Bador == nil then
	Bador = class({})
end

--------------------------------------------------------------
--	Precache - Load required assets
--------------------------------------------------------------
function Precache( context )
			--print( "[Bador] precache start." )
			PrecacheUnitByNameSync("npc_dota_hero_pudge",context)
			--print( "[Bador] precache end." )
end

--------------------------------------------------------------
-- Activate
--------------------------------------------------------------
function Activate()
			GameRules.Bador = Bador()
			GameRules.Bador:InitGameMode()
end
--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------
function 	Bador:InitGameMode()
				--print( "[Bador] InitGameMode is start." )
				--print( "[Bador] hook." )
				hook 	= thisEntity:FindAbilityByName("skill_pudge_meat_hook")
				rot 	= thisEntity:FindAbilityByName("pudge_rot")
				dism 	= thisEntity:FindAbilityByName("pudge_dismember")


	
				--thisEntity:SetContextThink("Hold", Hold, 0.2)
				thisEntity:SetContextThink("HookDem", HookDem, 1)
				thisEntity:SetContextThink("RotDem", RotDem, 0)
				thisEntity:SetContextThink("Dism", Dism, 2)
				--thisEntity:SetContextThink("Urn", Urn, 0)
				--thisEntity:SetContextThink("goback", goback, 0)
				

				--print( "[Bador] InitGameMode is end." )
end
--------------------------------------------------------------
-- Bador AI Go Back
--------------------------------------------------------------
--[[function goback()

		local unit = Entities:FindByName(nil,"npc_dota_bador_pudge")
		--local unit = EntIndexToHScript(index)
		local position = Vector (-128,256,128)
		--local initial_neutral_position = position

		--local waypoint = Entities:FindByNameNearest( "path_1", thisEntity:GetOrigin(), 0 )
				--waypoint = unit:GetAbsOrigin()

				if unit:entindex:Length2D() > 900 then
					print("[Bador] Ok i cant chase this dude")
							unit:MoveToPosition(position) 
				
					return math.random(2,6)
				--[[if unit:GetAttackTarget() == nil then
					print("I am running back sorry")
					thisEntity:SetInitialGoalEntity( waypoint )
					thisEntity:MoveToPositionAggressive( waypoint:GetOrigin() )
				else
							print("[Bador] I can get them dont worry")
					return nil
				end
	--return 1	
end]]

--//--------------------------------------------------------------------------------------
--//	Hook
--//--------------------------------------------------------------------------------------
function HookDem()

	--print( "[Bador] Hook Start" )
	if hook:IsFullyCastable() then
		--print("[Bador] Hook ready")
		--print("[Bador] Hook searching units")
		local allEnemies = FindUnitsInRadius( DOTA_TEAM_NOTEAM, thisEntity:GetOrigin(), nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)

			if #allEnemies > 1 then
				local index = RandomInt( 1, #allEnemies )
			
				target = allEnemies[index]
				--print("[Bador] Hook found units cast NOW")
				order =
				{
					OrderType 		= DOTA_UNIT_ORDER_CAST_POSITION,
					UnitIndex 		= thisEntity:entindex(),
					Position 		= target:GetOrigin(),
					Target 			= target:entindex(),
					AbilityIndex 	= hook:entindex(),
				}
				ExecuteOrderFromTable( order )
			else 
				--print("[Bador] Hook No units found to cast the spell on")
				--return 2
			end
	else
		--print("[Bador] Hook no ready")	
	end
	return 1
end


--//--------------------------------------------------------------------------------------
--//	Dismember
--//--------------------------------------------------------------------------------------
function Dism()

	--print( "[Bador] Dism Start" )
	if dism and dism:IsFullyCastable() then
		--print("[Bador] Dism ready")
		--print("[Bador] Dism searching units")
		local allEnemies = FindUnitsInRadius( DOTA_TEAM_NOTEAM, thisEntity:GetOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)

		if #allEnemies > 1 then
			local index = RandomInt( 1, #allEnemies )
			
			target = allEnemies[index]
	
			--print("[Bador] Dism found units cast NOW")
			order =
			{
				OrderType 		= DOTA_UNIT_ORDER_CAST_TARGET,
				UnitIndex 		= thisEntity:entindex(),
				Targetindex 	= target:entindex(),
				AbilityIndex 	= dism:entindex(),
			}
			ExecuteOrderFromTable( order )
		else 
			--print("[Bador] Dism No units found to cast the spell on")
			--return 2
		end
	end
	return 1
end


--//--------------------------------------------------------------------------------------
--//	Rot
--//--------------------------------------------------------------------------------------
function RotDem()
local allEnemies = FindUnitsInRadius( DOTA_TEAM_NOTEAM, thisEntity:GetOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)

			--print( "[Bador] Rot Start" )
		if #allEnemies > 1 and rot:IsFullyCastable() then
				--print("[Bador] Rot and Dism ready")
				--print("[Bador] Rot searching units")
			--local allEnemies = FindUnitsInRadius( DOTA_TEAM_NOTEAM, thisEntity:GetOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false)

				--if #allEnemies > 1 then
					--print("[Bador] Rot found units cast NOW")
					order =
					{
						OrderType 		= DOTA_UNIT_ORDER_CAST_TOGGLE,
						UnitIndex 		= thisEntity:entindex(),
						--Position 		= allEnemies[1]:GetAbsOrigin(),
						--Target 			= allEnemies[1]:GetAbsOrigin(),
						AbilityIndex 	= rot:entindex(),
					}
					ExecuteOrderFromTable( order )
				elseif rot:GetToggleState() == true then
						rot:ToggleAbility()
					--print("Rot Toggle off")
					

					--print("[Bador] Rot No units found to cast the spell on")
					--return 2
				--end
			else

		--else


			--print( "[Bador] no enemis around" )
		end	
	return 3
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
