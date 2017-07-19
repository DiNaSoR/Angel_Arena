HP_AI_VERSION = "0.1"
--------------------------------------------------------------
-- Setting
--------------------------------------------------------------
HEROSP_DIALOG = {	"DIIIIIIIIIIEEEEEEEEEEE NOW!!!!!!",
					"YOU ALL BURN!!!",
					"DRAGONS BREATH!",
					"TASTE MY WRATH!" 
				}
				
HEROSP_SOUNDBOX = {	"angel_arena.behold", 
					"angel_arena.blazeofglory", 
					"angel_arena.fireskill"
					}				
--------------------------------------------------------------
-- InitGameMode
--------------------------------------------------------------
function Spawn( entityKeyValues )
	soundburn = true
	hpdialog = true
	print("[Angel Arena] Starting AI for "..thisEntity:GetUnitName().." "..HP_AI_VERSION)

	spirit_searing_chains 		= thisEntity:FindAbilityByName("ember_spirit_searing_chains")
	herospirit_skill 			= thisEntity:FindAbilityByName("skill_herospirit_mini_boss_skill")

	thisEntity:SetContextThink( "Fightingskills", Fightingskills , 1)
	thisEntity:SetContextThink( "AIThinking", AIThinking , 0.5)
	thisEntity:SetContextThink("CastItemName", CastItemName, 0.5)


end

--------------------------------------------------------------
-- AI Behavior
--------------------------------------------------------------
function AIThinking()

	local point = Vector(-6976, -6821.66, -768)
	local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
    
    if thisEntity:IsNull() or not thisEntity:IsAlive() then
        return nil
    end	

    if #units <= 0 then
    	thisEntity:MoveToPosition(point)

    	if (point - thisEntity:GetOrigin()):Length2D() <= 1 then
    		thisEntity:SetForwardVector(FACING_RIGHT)
    	end
    end

    if (point - thisEntity:GetOrigin()):Length2D() > 1400 then
        thisEntity:MoveToPosition(point)
    end
 
    return 0.5;
end

--//--------------------------------------------------------------------------------------
--//	cast Urn
--//--------------------------------------------------------------------------------------
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
		        --if item and item:GetAbilityName() == "item_urn_of_shadows" and (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() > 700 then
		        	--print("casting urn")
		            --thisEntity:CastAbilityOnTarget(target, item, -1)

				if item and item:GetAbilityName() == "item_shivas_guard" and healthRemaining <= 0.75 then
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

--------------------------------------------------------------
-- AI Fighting Skills
--------------------------------------------------------------

function Fightingskills()
	local healthRemaining = thisEntity:GetHealth() / thisEntity:GetMaxHealth()

	if spirit_searing_chains:IsFullyCastable()  and healthRemaining <= 0.75 then
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, FIND_FARTHEST, false )

		if units ~= nil then
			if #units >= 1 then
				thisEntity:CastAbilityNoTarget( spirit_searing_chains, -1)
			else 
				
			end
		end
	end

	
    	
			if herospirit_skill:IsFullyCastable() and healthRemaining <= 0.50 then
				local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)

				if units ~= nil then
					if #units >= 1 then
						if soundburn == true and thisEntity:IsAlive() then
						EmitGlobalSound(HEROSP_SOUNDBOX[RandomInt(1,3)])
						dialogherospirit()
						soundburn = false
						else
						end
						Timers:CreateTimer(5, function()
							soundburn = true
						end)
						local index = RandomInt( 1, #units )
						local target = units[index]

						thisEntity:CastAbilityNoTarget(herospirit_skill, -1)
						dialogherospirit()

					else
						
					end
				end
			end


	--Refresh the cooldown of the other spells

	
	return 1
end


--------------------------------------------------------------
-- Hero Spirit Dialog
--------------------------------------------------------------
function dialogherospirit()
end
