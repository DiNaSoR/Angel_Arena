--------------------------------------------------------------
-- Version
--------------------------------------------------------------

PUDGE_AI_VERSION = "0.2"

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
				
				hookskill 	= thisEntity:FindAbilityByName("skill_pudge_meat_hook")
				rot 		= thisEntity:FindAbilityByName("pudge_rot")
				dism 		= thisEntity:FindAbilityByName("pudge_dismember")
				thisEntity:SetContextThink("AIThinking", AIThinking, 0.5)

end
--------------------------------------------------------------
-- AI Behavior
--------------------------------------------------------------
local ai_points = 0

function AIThinking()
    if thisEntity:IsNull() or not thisEntity:IsAlive() then
        return nil
    end

    local point = Vector(-128, 256, 128)
    local units = FindEnemyUnits(thisEntity, 1300)

    -- Check if any enemies are nearby
    if #units > 0 then
        print("Found " .. #units .. " enemy units")
        local target = GetWeakestEnemy(units)
        if target then
            -- Calculate AI points
            ai_points = ai_points + CalculatePoints(target)
            print("AI points: " .. ai_points)

            -- Execute skill if not channeling or casting
            if not thisEntity:IsChanneling() and not thisEntity:IsCastingAbility() then
                local skill_choice = ChooseSkillBasedOnWeight(ai_points)
                ExecuteSkill(skill_choice, target)
            end
        else
            print("Target not found")
            MoveToPosition(point)
        end
    else
        MoveToPosition(point)
    end

    return 0.5
end

function CalculatePoints(target)
    local points = 0

    if HitNormalAttack(target) then
        points = points + 1
    end

    if HitCritAttack(target) then
        points = points + 2
    end

    if TargetRunsAway(target) then
        points = points + 3
    end

    return points
end

-------------------------------------------------------------------
-- ChooseSkillBasedOnWeight
-------------------------------------------------------------------
function ChooseSkillBasedOnWeight(points)
    local weights = {
        hook = 10,
        rot = 20,
        dismember = 30
    }

    local available_skills = {}

    for skill, weight in pairs(weights) do
        if points >= weight then
            table.insert(available_skills, skill)
        end
    end

    return available_skills[RandomInt(1, #available_skills)]
end

function ExecuteSkill(skill_choice, target)
    if skill_choice == "hook" and CanCastHook(target) then
        print("Casting Hook")
        CastHook(target)
        ai_points = ai_points - 10
    elseif skill_choice == "rot" and CanCastRot() then
        print("Casting Rot")
        CastRot()
        ai_points = ai_points - 20
    elseif skill_choice == "dismember" and CanCastDismember(target) then
        print("Casting Dismember")
        CastDismember(target)
        ai_points = ai_points - 30
    end
end
-------------------------------------------------------------------
-- FindEnemyUnits
-------------------------------------------------------------------
function FindEnemyUnits(pudgeEntity, searchRadius)
    local team = pudgeEntity:GetTeamNumber()
    local position = pudgeEntity:GetAbsOrigin()

    local enemies = {}

    for _, unit in ipairs(Entities:FindAllInSphere(position, searchRadius)) do
        if unit:GetTeamNumber() ~= team and unit:GetTeamNumber() ~= 4 and unit ~= pudgeEntity then
            if unit.GetUnitName and unit:IsAlive() and unit:IsHero() then  -- Add these checks
                table.insert(enemies, unit)
                --print("Found enemy: " .. unit:GetUnitName() .. ", Team: " .. unit:GetTeamNumber())
            end
        end
    end

    return enemies
end
-------------------------------------------------------------------
-- GetWeakestEnemy
-------------------------------------------------------------------
function GetWeakestEnemy(units)
    local weakest = nil
    local lowestHP = math.huge

    for _, unit in ipairs(units) do
        local health = unit:GetHealth()
        if health < lowestHP then
            weakest = unit
            lowestHP = health
        end
    end

    return weakest
end

-------------------------------------------------------------------
-- CanCastRot
-------------------------------------------------------------------
function CanCastRot()
    return rot:IsFullyCastable() and not thisEntity:HasModifier("modifier_pudge_rot")
end
-------------------------------------------------------------------
-- CastRot
-------------------------------------------------------------------
function CastRot()
    thisEntity:CastAbilityNoTarget(rot, -1)
end
-------------------------------------------------------------------
-- CanCastHook
-------------------------------------------------------------------
function CanCastHook(target)
    return hookskill:IsFullyCastable() and IsValidEntity(target) and (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() > 200
end
-------------------------------------------------------------------
-- CastHook
-------------------------------------------------------------------
function CastHook(target)
    thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), hookskill, -1)
    EmitSoundOn(HOOK_SOUNDBOX[RandomInt(1, 8)], target)
end
-------------------------------------------------------------------
-- CanCastDismember
-------------------------------------------------------------------
function CanCastDismember(target)
    return dism:IsFullyCastable() and IsValidEntity(target) and (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() <= 250
end
-------------------------------------------------------------------
-- CastDismember
-------------------------------------------------------------------
function CastDismember(target)
    thisEntity:CastAbilityOnTarget(target, dism, -1)
    EmitSoundOn(DISM_SOUNDBOX[RandomInt(1, 6)], target)
end
-------------------------------------------------------------------
-- CanUseItems
-------------------------------------------------------------------
function CanUseItems()
    return thisEntity:GetHealth() / thisEntity:GetMaxHealth() < 0.75
end
-------------------------------------------------------------------
-- UseItems
-------------------------------------------------------------------
function UseItems(target)
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
-------------------------------------------------------------------
-- MoveTowardsEnemy
-------------------------------------------------------------------
function MoveTowardsEnemy(target)
    local origin = Vector(-128, 256, 128)
    local max_distance = 1400  -- You can set the leash distance here
    local position = target:GetAbsOrigin()
    local direction = (position - thisEntity:GetAbsOrigin()):Normalized()
    local distance = (origin - thisEntity:GetAbsOrigin()):Length2D()
    local attackRange = thisEntity:Script_GetAttackRange()

    if target:IsAlive() then
        if (position - thisEntity:GetAbsOrigin()):Length2D() <= attackRange then
            thisEntity:MoveToTargetToAttack(target)
        else
            local newPosition = thisEntity:GetAbsOrigin() + direction * 150
            local newDistance = (origin - newPosition):Length2D()
            if newDistance > max_distance then
                thisEntity:MoveToPosition(origin)
            else
                MoveToPosition(origin)  -- If the AI is too far away, move it back to the origin
            end
        end
    else
        MoveToPosition(origin)  -- If the target hero is dead, move the AI back to the origin
    end
end

-------------------------------------------------------------------
-- MoveToPosition
-------------------------------------------------------------------
function MoveToPosition(position)
    local units = FindEnemyUnits(thisEntity, 1300)
    if #units == 0 then
        if (position - thisEntity:GetOrigin()):Length() > 1400 then
            thisEntity:MoveToPosition(position)
        end
    end
end
--------------------------------------------------------------
-- Bador Dialopudge
--------------------------------------------------------------
function dialogpudge()
--Msg("PUDGE_DIALOG")
--print("Bador")
end