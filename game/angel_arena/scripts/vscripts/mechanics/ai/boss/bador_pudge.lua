--------------------------------------------------------------
-- Version
--------------------------------------------------------------

PUDGE_AI_VERSION = "0.1"

--------------------------------------------------------------
-- Setting
--------------------------------------------------------------

HOOK_SOUNDBOX = 	{	"pudge_pud_ability_hook_01",
						"pudge_pud_ability_hook_02",
						"pudge_pud_ability_hook_03",
						"pudge_pud_ability_hook_04", 
						"pudge_pud_ability_hook_05", 
						"pudge_pud_ability_hook_06", 
						"pudge_pud_ability_hook_07", 
						"pudge_pud_ability_hook_08"
					}
DISM_SOUNDBOX = 	{	"pudge_pud_attack_08",
						"pudge_pud_attack_09",
						"pudge_pud_attack_10",
						"pudge_pud_attack_11", 
						"pudge_pud_attack_12", 
						"pudge_pud_attack_13"
					}
RUNNING_SOUNDBOX = 	{	"pudge_pud_laugh_01",
						"pudge_pud_laugh_02", 
						"pudge_pud_laugh_03",
						"pudge_pud_laugh_04", 
						"pudge_pud_laugh_05", 
						"pudge_pud_laugh_06", 
						"pudge_pud_laugh_07"
					}
PUDGE_DIALOG =	 	{	"YEAH RUN AWAY LITTLE GIRL!",
						"slag!.Slag!.SLAG!",
						"WHAT A WANKER!",
						"HAHA YOU THOUGHT YOU CAN TAKE ME?", 
						"JUST AS I THOUGHT!", 
						"TURN YOUR FACE AND NEVER COME BACK!", 
						"I WILL STEP ON YOUR FACE IF YOU STEP HERE AGAIN!"
					}											
--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------

function 	Spawn( entityKeyValues )
				--Pudgespeech = true
				
				print("[Angel Arena] Starting AI for "..thisEntity:GetUnitName().." "..PUDGE_AI_VERSION)
				
				hookskill 	= thisEntity:FindAbilityByName( "skill_pudge_meat_hook" )
				rot 		= thisEntity:FindAbilityByName("pudge_rot")
				dism 		= thisEntity:FindAbilityByName("pudge_dismember")

				--thisEntity:SetContextThink("Hook", Hook, 1)
				--thisEntity:SetContextThink("Dism", Dism, 1)
				thisEntity:SetContextThink("AIThinking", AIThinking, 0.5)
				--thisEntity:SetContextThink("CastItemName", CastItemName, 0.5)
end
--------------------------------------------------------------
-- AI Behavior
--------------------------------------------------------------

function AIThinking()
--print("I am searching")
--print(hookskill)
	local point = Vector(-128, 256, 128)
	local units = FindUnitsInRadius(
									thisEntity:GetTeamNumber(), 
									thisEntity:GetAbsOrigin(), 
									nil, 
									130000, 
									DOTA_UNIT_TARGET_TEAM_ENEMY, 
									DOTA_UNIT_TARGET_HERO, 
									DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, 
									FIND_CLOSEST, 
									false)
    
	for _,unit in pairs(units)  do
		  print(unit:GetName())
		  print("found one")
	  end

    if thisEntity:IsNull() or not thisEntity:IsAlive() then
		print("I am searching2")
        return nil
    end	

    if (point - thisEntity:GetOrigin()):Length() > 1400 then
        thisEntity:MoveToPosition(point)
        print("traget flee")
    end
 
    return 0.5;
end

--------------------------------------------------------------
-- Bador Dialopudge
--------------------------------------------------------------
function dialogpudge()
--Msg("PUDGE_DIALOG")
--print("Bador")
end

--------------------------------------------------------------------------------------
--	Hook
--------------------------------------------------------------------------------------
function Hook()
	print("I am searching hook")

	if hookskill:IsFullyCastable() then

		local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
		
		for i,unit in ipairs(units) do
			if i > 1 then -- Skip the closest one, which is the unit itself
			  print(unit:GetName())
			end
		  end

		if units ~= nil then
			if #units >= 1 then
				local index = RandomInt( 1, #units )
				local target = units[index]
				
				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), hookskill, -1)
				print("Pudge Hook")
				EmitSoundOn(HOOK_SOUNDBOX[RandomInt(1,8)], target)
				


			else 

			end
		end	
	else
		print("[Bador] Hook no ready")	
	end
	return 1
end

--------------------------------------------------------------------------------------
--	cast Urn
--------------------------------------------------------------------------------------
function CastItemName()
	--print("CastItemNmae run")
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
	local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 950, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
	local index = RandomInt( 1, #units )
	local target = units[index]
	if units ~= nil then
		if #units >= 1 then
		    for i=0,5 do
		        local item = thisEntity:GetItemInSlot(i)
		        if item and item:GetAbilityName() == "item_urn_of_shadows" and (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() > 700 then
		        	--print("casting urn")
		            thisEntity:CastAbilityOnTarget(target, item, -1)

				--[[elseif item and item:GetAbilityName() == "item_force_staff" and (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() > 300 then
		        	thisEntity:CastAbilityOnTarget(target, item, -1)]]

				elseif item and item:GetAbilityName() == "item_shivas_guard" and healthRemaining <= 0.75 then
		        	--print("casting Shiva Guard")
		            thisEntity:CastAbilityNoTarget(item, -1)

		        elseif item and item:GetAbilityName() == "item_lotus_orb" and healthRemaining <= 0.85 then
		        	--print("casting Lotus Orb")
		            thisEntity:CastAbilityOnTarget(thisEntity, item, -1)

		        elseif item and item:GetAbilityName() == "item_blade_mail" and healthRemaining <= 0.95 then
		        	--print("casting Blade Mail")
		            thisEntity:CastAbilityNoTarget(item, -1)
				else

		        end
		    end
		end
	end
	return 1
end




--------------------------------------------------------------------------------------
--	Dismember
--------------------------------------------------------------------------------------
function Dism()


	if dism:IsFullyCastable() then

		local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 250, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

		if units ~= nil then
			if #units >= 1 then
				local index = RandomInt( 1, #units )
				local target = units[index]
				
				thisEntity:CastAbilityOnTarget(target, dism, -1)
				thisEntity:CastAbilityToggle(rot, -1)
				EmitSoundOn(DISM_SOUNDBOX[RandomInt(1,6)], target)

			end
		end	
	end

	local cooldown = math.floor(dism:GetCooldownTimeRemaining())

	if cooldown == 20 and rot:GetToggleState() == true then
		--print(rot:GetToggleState())
		thisEntity:CastAbilityToggle(rot, -1)
		--print(rot:GetToggleState())
	else
		--print(cooldown)
	end

	return 1
end

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