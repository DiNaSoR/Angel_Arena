HP_AI_VERSION = "1.1"
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
	print("Starting AI for "..thisEntity:GetUnitName().." "..HP_AI_VERSION)

	spirit_searing_chains 	= thisEntity:FindAbilityByName("ember_spirit_searing_chains")
	herospirit_skill 			= thisEntity:FindAbilityByName("skill_herospirit_mini_boss_skill")

	thisEntity:SetContextThink( "Fightingskills", Fightingskills , 1)
	thisEntity:SetContextThink( "AIThinking", AIThinking , 0.5)

end

--------------------------------------------------------------
-- AI Behavior
--------------------------------------------------------------
function AIThinking()

	local point = Vector(-6756.18, -6703.67, -768)
	local units = FindUnitsInRadius( thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
    
    if thisEntity:IsNull() or not thisEntity:IsAlive() then
        return nil
    end	

    if #units <= 0 then
    	thisEntity:MoveToPosition(point)
    end

    if (point - thisEntity:GetOrigin()):Length() > 1400 then
        thisEntity:MoveToPosition(point)
    end
 
    return 0.5;
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
						--dialogherospirit()

					else
						
					end
				end
			end


	--Refresh the cooldown of the other spells
	if healthRemaining <= 0.10 then -- last stand
		spirit_searing_chains:EndCooldown()
	end
	
	return 1
end


--------------------------------------------------------------
-- Hero Spirit Dialog
--------------------------------------------------------------
function dialogherospirit()
	local time = 5
	local speechSlot = findEmptyDialogSlot()
	if speechSlot < 4 --[[and hpdialog == true]] then
		--hpdialog = false
		thisEntity:AddSpeechBubble(speechSlot, HEROSP_DIALOG[RandomInt(1,4)], time, 0, -40)
		disableSpeech(thisEntity, time, speechSlot)
		--Timers:CreateTimer(5, function()
      	--hpdialog = true
    	--end)
	else

	end
end
