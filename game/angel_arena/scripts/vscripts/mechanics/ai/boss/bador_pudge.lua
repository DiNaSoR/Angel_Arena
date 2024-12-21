--------------------------------------------------------------
-- Version
--------------------------------------------------------------

PUDGE_AI_VERSION = "0.4"

--------------------------------------------------------------
-- Settings
--------------------------------------------------------------

HOOK_SOUNDBOX = {
    "pudge_pud_ability_hook_01",
    "pudge_pud_ability_hook_02",
    "pudge_pud_ability_hook_03",
    "pudge_pud_ability_hook_04",
    "pudge_pud_ability_hook_05",
    "pudge_pud_ability_hook_06",
    "pudge_pud_ability_hook_07",
    "pudge_pud_ability_hook_08"
}

DISM_SOUNDBOX = {
    "pudge_pud_attack_08",
    "pudge_pud_attack_09",
    "pudge_pud_attack_10",
    "pudge_pud_attack_11",
    "pudge_pud_attack_12",
    "pudge_pud_attack_13"
}

RUNNING_SOUNDBOX = {
    "pudge_pud_laugh_01",
    "pudge_pud_laugh_02",
    "pudge_pud_laugh_03",
    "pudge_pud_laugh_04",
    "pudge_pud_laugh_05",
    "pudge_pud_laugh_06",
    "pudge_pud_laugh_07"
}

PUDGE_DIALOG = {
    "YEAH RUN AWAY LITTLE GIRL!",
    "slag!.Slag!.SLAG!",
    "WHAT A WANKER!",
    "HAHA YOU THOUGHT YOU CAN TAKE ME?",
    "JUST AS I THOUGHT!",
    "TURN YOUR FACE AND NEVER COME BACK!",
    "I WILL STEP ON YOUR FACE IF YOU STEP HERE AGAIN!"
}

--------------------------------------------------------------
-- Initialization
--------------------------------------------------------------

function Spawn(entityKeyValues)
    if not thisEntity then return end

    -- Store the original position
    thisEntity.original_position = thisEntity:GetAbsOrigin()

    print("[Angel Arena] Starting AI for " .. thisEntity:GetUnitName() .. " " .. PUDGE_AI_VERSION)

    -- Initialize abilities
    hookskill = thisEntity:FindAbilityByName("skill_pudge_meat_hook")
    rot = thisEntity:FindAbilityByName("pudge_rot")
    dism = thisEntity:FindAbilityByName("pudge_dismember")

    -- Initialize items
    thisEntity.items = {
        urn = nil,
        shivas = nil,
        lotus_orb = nil,
        blade_mail = nil
    }
    for i = 0, 5 do
        local item = thisEntity:GetItemInSlot(i)
        if item then
            local name = item:GetAbilityName()
            if name == "item_urn_of_shadows" then
                thisEntity.items.urn = item
            elseif name == "item_shivas_guard" then
                thisEntity.items.shivas = item
            elseif name == "item_lotus_orb" then
                thisEntity.items.lotus_orb = item
            elseif name == "item_blade_mail" then
                thisEntity.items.blade_mail = item
            end
        end
    end

    -- Initialize memory
    thisEntity.memory = {
        hook_success = 0,
        rot_success = 0,
        dismember_success = 0,
        hook_failure = 0,
        rot_failure = 0,
        dismember_failure = 0
    }

    -- Initialize state
    thisEntity.state = "idle"
    thisEntity.isCasting = false
    thisEntity.globalCooldown = 0
    thisEntity.hookCooldown = 0
    thisEntity.dismemberCooldown = 0
    thisEntity.rotCooldown = 0

    -- Initialize other variables
    thisEntity.thinkInterval = 0.5
    thisEntity:StartGesture(ACT_DOTA_IDLE)

    -- Set context think
    thisEntity:SetContextThink("AIThinking", AIThinking, thisEntity.thinkInterval)
end

--------------------------------------------------------------
-- AI Behavior
--------------------------------------------------------------

function AIThinking()
    if thisEntity:IsNull() or not thisEntity:IsAlive() then
        return nil
    end

    -- Decrement cooldowns
    DecrementCooldowns()

    -- Handle state transitions
    HandleStateTransitions()

    -- Execute actions based on current state
    if thisEntity.state == "idle" then
        IdleBehavior()
    elseif thisEntity.state == "engaging" then
        EngagingBehavior()
    elseif thisEntity.state == "returning" then
        ReturningBehavior()
    elseif thisEntity.state == "casting" then
        -- Casting is handled within ExecuteSkill
    elseif thisEntity.state == "using_items" then
        UseItemsBehavior()
    end

    return thisEntity.thinkInterval
end

--------------------------------------------------------------
-- Cooldown Management
--------------------------------------------------------------

function DecrementCooldowns()
    if thisEntity.globalCooldown > 0 then
        thisEntity.globalCooldown = math.max(thisEntity.globalCooldown - thisEntity.thinkInterval, 0)
    end
    if thisEntity.hookCooldown > 0 then
        thisEntity.hookCooldown = math.max(thisEntity.hookCooldown - thisEntity.thinkInterval, 0)
    end
    if thisEntity.dismemberCooldown > 0 then
        thisEntity.dismemberCooldown = math.max(thisEntity.dismemberCooldown - thisEntity.thinkInterval, 0)
    end
    if thisEntity.rotCooldown > 0 then
        thisEntity.rotCooldown = math.max(thisEntity.rotCooldown - thisEntity.thinkInterval, 0)
    end
end

--------------------------------------------------------------
-- State Transitions
--------------------------------------------------------------

function HandleStateTransitions()
    local max_distance = 1400
    local origin = thisEntity.original_position
    local distance = (origin - thisEntity:GetAbsOrigin()):Length2D()

    if distance > max_distance then
        thisEntity.state = "returning"
        thisEntity:Stop()
    end

    if thisEntity.state == "returning" then
        if distance <= 10 then
            thisEntity.state = "idle"
            thisEntity:Stop()
        else
            MoveToPosition(origin)
        end
    end
end

--------------------------------------------------------------
-- Idle Behavior
--------------------------------------------------------------

function IdleBehavior()
    local units = FindEnemyUnits(thisEntity, 1300)

    if #units > 0 then
        local target = GetBestTarget(units)
        if target then
            if not thisEntity:IsChanneling() and not IsCastingAbility() and not thisEntity.isCasting and thisEntity.globalCooldown <= 0 then
                ExecuteSkillDecision(target)
            end
            thisEntity.state = "engaging"
            MoveTowardsEnemy(target)
        else
            MoveToPosition(thisEntity.original_position)
        end
    else
        -- Optional: Wander around original position
        -- Implement wander logic if desired
    end
end

--------------------------------------------------------------
-- Engaging Behavior
--------------------------------------------------------------

function EngagingBehavior()
    local target = FindClosestEnemy(thisEntity, 1300)
    if target and target:IsAlive() then
        if not thisEntity:IsChanneling() and not IsCastingAbility() and not thisEntity.isCasting and thisEntity.globalCooldown <= 0 then
            ExecuteSkillDecision(target)
        end
        MoveTowardsEnemy(target)
    else
        thisEntity.state = "idle"
    end
end

--------------------------------------------------------------
-- Returning Behavior
--------------------------------------------------------------

function ReturningBehavior()
    local origin = thisEntity.original_position
    local distance = (origin - thisEntity:GetAbsOrigin()):Length2D()

    if distance <= 10 then
        thisEntity.state = "idle"
        thisEntity:Stop()
    else
        MoveToPosition(origin)
    end
end

--------------------------------------------------------------
-- Skill Decision Making
--------------------------------------------------------------

function ExecuteSkillDecision(target)
    -- Prioritize skills based on current situation
    if CanCastHook(target) then
        ExecuteSkill("hook", target)
    elseif CanCastDismember(target) then
        ExecuteSkill("dismember", target)
    elseif CanCastRot() then
        ExecuteSkill("rot", target)
    end
end

--------------------------------------------------------------
-- Execute Skill
--------------------------------------------------------------

function ExecuteSkill(skill_choice, target)
    if skill_choice == nil then
        return
    end

    thisEntity.isCasting = true
    thisEntity.globalCooldown = 1  -- Short global cooldown to prevent spamming

    if skill_choice == "hook" then
        if CastHook(target) then
            if HookHit(target) then
                thisEntity.memory.hook_success = thisEntity.memory.hook_success + 1
                PlayDialog()
            else
                thisEntity.memory.hook_failure = thisEntity.memory.hook_failure + 1
            end
            thisEntity.hookCooldown = hookskill:GetCooldown(-1)
        end
    elseif skill_choice == "rot" then
        if CastRot() then
            if RotHit(target) then
                thisEntity.memory.rot_success = thisEntity.memory.rot_success + 1
                PlayDialog()
            else
                thisEntity.memory.rot_failure = thisEntity.memory.rot_failure + 1
            end
            thisEntity.rotCooldown = rot:GetCooldown(-1)
        end
    elseif skill_choice == "dismember" then
        if CastDismember(target) then
            if DismemberHit(target) then
                thisEntity.memory.dismember_success = thisEntity.memory.dismember_success + 1
                PlayDialog()
            else
                thisEntity.memory.dismember_failure = thisEntity.memory.dismember_failure + 1
            end
            thisEntity.dismemberCooldown = dism:GetCooldown(-1)
        end
    end

    thisEntity.isCasting = false
end

--------------------------------------------------------------
-- Ability Casting Functions
--------------------------------------------------------------

function CanCastHook(target)
    if thisEntity.hookCooldown > 0 or not hookskill:IsFullyCastable() or thisEntity:GetMana() < hookskill:GetManaCost(-1) then
        return false
    end
    if not IsValidEntity(target) then
        return false
    end
    local distance = (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
    return distance > 200 and distance <= 1200
end

function CastHook(target)
    local cast_position = target:GetAbsOrigin() + RandomVector(RandomFloat(100, 300))  -- Add some randomness to hook position
    thisEntity:CastAbilityOnPosition(cast_position, hookskill, -1)
    EmitSoundOn(HOOK_SOUNDBOX[RandomInt(1, #HOOK_SOUNDBOX)], thisEntity)
    return true
end

function CanCastDismember(target)
    if thisEntity.dismemberCooldown > 0 or not dism:IsFullyCastable() or thisEntity:GetMana() < dism:GetManaCost(-1) then
        return false
    end
    if not IsValidEntity(target) then
        return false
    end
    local distance = (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
    return distance <= 250 and distance >= 125
end

function CastDismember(target)
    thisEntity:CastAbilityOnTarget(target, dism, -1)
    EmitSoundOn(DISM_SOUNDBOX[RandomInt(1, #DISM_SOUNDBOX)], thisEntity)
    return true
end

function CanCastRot()
    if thisEntity.rotCooldown > 0 or not rot:IsFullyCastable() or thisEntity:GetMana() < rot:GetManaCost(-1) then
        return false
    end
    if thisEntity:HasModifier("modifier_pudge_rot") then
        return false
    end
    return true
end

function CastRot()
    thisEntity:CastAbilityNoTarget(rot, -1)
    EmitSoundOn(RUNNING_SOUNDBOX[RandomInt(1, #RUNNING_SOUNDBOX)], thisEntity)
    return true
end

--------------------------------------------------------------
-- Item Usage Behavior
--------------------------------------------------------------

function UseItemsBehavior()
    if not CanUseItems() then
        thisEntity.state = "idle"
        return
    end

    local healthPercentage = thisEntity:GetHealth() / thisEntity:GetMaxHealth()
    local enemies = FindEnemyUnits(thisEntity, 950)

    if #enemies < 1 then
        thisEntity.state = "idle"
        return
    end

    local target = GetBestTarget(enemies)

    for _, item in pairs(thisEntity.items) do
        if item and item:IsFullyCastable() then
            local itemName = item:GetAbilityName()
            if itemName == "item_urn_of_shadows" and target and (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() > 700 then
                thisEntity:CastAbilityOnTarget(target, item, -1)
            elseif itemName == "item_shivas_guard" and healthPercentage <= 0.75 then
                thisEntity:CastAbilityNoTarget(item, -1)
            elseif itemName == "item_lotus_orb" and healthPercentage <= 0.85 then
                thisEntity:CastAbilityOnTarget(thisEntity, item, -1)
            elseif itemName == "item_blade_mail" and healthPercentage <= 0.95 then
                thisEntity:CastAbilityNoTarget(item, -1)
            end
        end
    end

    thisEntity.state = "idle"
end

function CanUseItems()
    return thisEntity:GetHealth() / thisEntity:GetMaxHealth() < 0.95  -- Adjusted threshold for more proactive usage
end

--------------------------------------------------------------
-- Movement Functions
--------------------------------------------------------------

function MoveTowardsEnemy(target)
    if not target or not target:IsAlive() then
        thisEntity.state = "idle"
        return
    end

    local origin = thisEntity.original_position
    local max_distance = 1400
    local current_position = thisEntity:GetAbsOrigin()
    local target_position = target:GetAbsOrigin()
    local direction = (target_position - current_position):Normalized()
    local distance_from_origin = (origin - current_position):Length2D()
    local attackRange = thisEntity:Script_GetAttackRange()

    if distance_from_origin > max_distance then
        thisEntity.state = "returning"
        thisEntity:Stop()
        MoveToPosition(origin)
        return
    end

    local distance_to_target = (target_position - current_position):Length2D()

    if distance_to_target <= attackRange + 100 then
        thisEntity:MoveToTargetToAttack(target)
    else
        local newPosition = current_position + direction * 150
        thisEntity:MoveToPosition(newPosition)
    end
end

function MoveToPosition(position)
    local current_position = thisEntity:GetAbsOrigin()
    local distance_to_position = (position - current_position):Length2D()
    if distance_to_position > 10 then
        thisEntity:MoveToPosition(position)
    else
        thisEntity.state = "idle"
        thisEntity:Stop()
    end
end

--------------------------------------------------------------
-- Target Selection Functions
--------------------------------------------------------------

function FindEnemyUnits(pudgeEntity, searchRadius)
    local team = pudgeEntity:GetTeamNumber()
    local position = pudgeEntity:GetAbsOrigin()

    local enemies = FindUnitsInRadius(
        team,
        position,
        nil,
        searchRadius,
        DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE,
        FIND_CLOSEST,
        false
    )

    return enemies
end

function GetBestTarget(units)
    -- Prioritize based on lowest health and distance
    table.sort(units, function(a, b)
        if a:GetHealth() == b:GetHealth() then
            return (a:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() < (b:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
        else
            return a:GetHealth() < b:GetHealth()
        end
    end)
    return units[1]
end

function FindClosestEnemy(pudgeEntity, searchRadius)
    local enemies = FindEnemyUnits(pudgeEntity, searchRadius)
    if #enemies == 0 then
        return nil
    end
    return enemies[1]  -- Assuming enemies are sorted by closest
end

--------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------

function HitNormalAttack(target)
    -- Placeholder logic: Implement actual hit detection if possible
    return true
end

function HitCritAttack(target)
    -- Placeholder logic: Implement actual crit detection if possible
    return false
end

function TargetRunsAway(target)
    -- Placeholder logic: Implement actual movement prediction if possible
    local distance = (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
    return distance > 600
end

function HookHit(target)
    -- Placeholder logic: Determine if the hook hit the target
    -- Ideally, use actual game event hooks to confirm hits
    return RandomInt(0, 1) == 1
end

function RotHit(target)
    -- Placeholder logic: Determine if the rot hit the target
    -- Ideally, use actual game event hooks to confirm hits
    return RandomInt(0, 1) == 1
end

function DismemberHit(target)
    -- Placeholder logic: Determine if the dismember hit the target
    -- Ideally, use actual game event hooks to confirm hits
    return RandomInt(0, 1) == 1
end

function IsCastingAbility()
    local currentOrder = thisEntity:GetCurrentActiveAbility()
    return currentOrder ~= nil and (currentOrder:IsChanneling() or currentOrder:IsInAbilityPhase())
end

function PlayDialog()
    local dialog = PUDGE_DIALOG[RandomInt(1, #PUDGE_DIALOG)]
    EmitSoundOn(dialog, thisEntity)
end

--------------------------------------------------------------
-- Voice Line Enhancements (Optional)
--------------------------------------------------------------

-- You can expand this section to add more dynamic responses based on different actions or events.
-- For example, Pudge could have specific lines when initiating a hook, killing an enemy, etc.

--------------------------------------------------------------
-- Additional Improvements
--------------------------------------------------------------

-- Consider implementing a behavior tree or finite state machine for more complex behaviors.
-- Implement actual hit detection using game events for more accurate AI responses.
-- Add vision and map awareness to make the AI smarter in different scenarios.
-- Enhance item usage logic based on game state (e.g., pushing, defending, farming).

