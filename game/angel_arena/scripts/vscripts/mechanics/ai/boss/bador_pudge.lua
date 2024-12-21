--------------------------------------------------------------
-- Version
--------------------------------------------------------------
PUDGE_AI_VERSION = "0.5"  -- Updated version

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

-- NOTE: These text lines are NOT actual sound events. If you want Pudge
-- to say these lines, either use in-game chat or replace them with valid sound events.
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

    -- Ability cooldown counters (manual tracking to reduce spamming)
    thisEntity.globalCooldown = 0
    thisEntity.hookCooldown = 0
    thisEntity.dismemberCooldown = 0
    thisEntity.rotCooldown = 0

    thisEntity.thinkInterval = 0.5

    -- Optional: Start idle gesture
    thisEntity:StartGesture(ACT_DOTA_IDLE)

    -- Set context think
    thisEntity:SetContextThink("AIThinking", AIThinking, thisEntity.thinkInterval)
end

--------------------------------------------------------------
-- Main Thinker
--------------------------------------------------------------
function AIThinking()
    if not thisEntity:IsAlive() then
        return nil
    end

    -- Decrement manual cooldowns
    DecrementCooldowns()

    -- Handle state transitions (e.g., if out of range, return to spawn)
    HandleStateTransitions()

    -- Execute behavior based on state
    if thisEntity.state == "idle" then
        IdleBehavior()
    elseif thisEntity.state == "engaging" then
        EngagingBehavior()
    elseif thisEntity.state == "returning" then
        ReturningBehavior()
    elseif thisEntity.state == "casting" then
        -- Let the cast finish; do not interrupt
        return thisEntity.thinkInterval
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
        thisEntity.globalCooldown = math.max(0, thisEntity.globalCooldown - thisEntity.thinkInterval)
    end
    if thisEntity.hookCooldown > 0 then
        thisEntity.hookCooldown = math.max(0, thisEntity.hookCooldown - thisEntity.thinkInterval)
    end
    if thisEntity.dismemberCooldown > 0 then
        thisEntity.dismemberCooldown = math.max(0, thisEntity.dismemberCooldown - thisEntity.thinkInterval)
    end
    if thisEntity.rotCooldown > 0 then
        thisEntity.rotCooldown = math.max(0, thisEntity.rotCooldown - thisEntity.thinkInterval)
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
        thisEntity:Stop()  -- Stop any ongoing movement or attack
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
    if #units == 0 then
        -- No enemies in range -> optional idle/wander
        return
    end

    local target = GetBestTarget(units)
    if target then
        -- If we have a valid target, possibly cast abilities
        if not thisEntity:IsChanneling() and not IsCastingAbility() and 
           not thisEntity.isCasting and thisEntity.globalCooldown <= 0 then
            ExecuteSkillDecision(target)
        end

        -- Move toward target
        thisEntity.state = "engaging"
        MoveTowardsEnemy(target)
    else
        MoveToPosition(thisEntity.original_position)  -- Fallback
    end
end

--------------------------------------------------------------
-- Engaging Behavior
--------------------------------------------------------------
function EngagingBehavior()
    local target = FindClosestEnemy(thisEntity, 1300)
    if target and target:IsAlive() then
        -- Consider casting if not channeling or already casting
        if not thisEntity:IsChanneling() and not IsCastingAbility() and 
           not thisEntity.isCasting and thisEntity.globalCooldown <= 0 then
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
    if not target or not target:IsAlive() then return end

    -- Try hooking first if target is outside short range
    if CanCastHook(target) then
        ExecuteSkill("hook", target)
        return
    end

    -- Then try dismember if target is close
    if CanCastDismember(target) then
        ExecuteSkill("dismember", target)
        return
    end

    -- Finally, consider toggling Rot
    if CanCastRot() then
        ExecuteSkill("rot", target)
        return
    end
end

--------------------------------------------------------------
-- Execute Skill
--------------------------------------------------------------
function ExecuteSkill(skill_choice, target)
    if skill_choice == nil then return end

    thisEntity.state = "casting"
    thisEntity.isCasting = true

    -- Short global cooldown to prevent spamming
    thisEntity.globalCooldown = 1.0

    if skill_choice == "hook" and hookskill then
        if CastHook(target) then
            local success = HookHit(target)  -- Placeholder random check
            if success then
                thisEntity.memory.hook_success = thisEntity.memory.hook_success + 1
                PlayDialog()
            else
                thisEntity.memory.hook_failure = thisEntity.memory.hook_failure + 1
            end
            thisEntity.hookCooldown = hookskill:GetCooldown(-1)
        end

    elseif skill_choice == "rot" and rot then
        if CastRot() then
            local success = RotHit(target)   -- Placeholder random check
            if success then
                thisEntity.memory.rot_success = thisEntity.memory.rot_success + 1
                PlayDialog()
            else
                thisEntity.memory.rot_failure = thisEntity.memory.rot_failure + 1
            end
            thisEntity.rotCooldown = rot:GetCooldown(-1)
        end

    elseif skill_choice == "dismember" and dism then
        if CastDismember(target) then
            local success = DismemberHit(target) -- Placeholder random check
            if success then
                thisEntity.memory.dismember_success = thisEntity.memory.dismember_success + 1
                PlayDialog()
            else
                thisEntity.memory.dismember_failure = thisEntity.memory.dismember_failure + 1
            end
            thisEntity.dismemberCooldown = dism:GetCooldown(-1)
        end
    end

    -- Release casting
    thisEntity.isCasting = false
    thisEntity.state = "engaging"
end

--------------------------------------------------------------
-- Ability Casting Checks & Functions
--------------------------------------------------------------
function CanCastHook(target)
    if not hookskill or thisEntity.hookCooldown > 0 or not hookskill:IsFullyCastable() then
        return false
    end
    local manaCost = hookskill:GetManaCost(-1) or 0
    if thisEntity:GetMana() < manaCost then
        return false
    end
    local distance = (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
    return (distance >= 200 and distance <= 1300)
end

function CastHook(target)
    if not target or not hookskill then return false end
    -- You can remove randomness if you want a more accurate hook.
    local cast_position = target:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
    thisEntity:CastAbilityOnPosition(cast_position, hookskill, -1)
    EmitSoundOn( HOOK_SOUNDBOX[RandomInt(1, #HOOK_SOUNDBOX)], thisEntity )
    return true
end

function CanCastDismember(target)
    if not dism or thisEntity.dismemberCooldown > 0 or not dism:IsFullyCastable() then
        return false
    end
    local manaCost = dism:GetManaCost(-1) or 0
    if thisEntity:GetMana() < manaCost then
        return false
    end
    local distance = (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
    -- For melee range: typically ~160 or so. Give some buffer.
    return (distance <= 250)
end

function CastDismember(target)
    if not target or not dism then return false end
    thisEntity:CastAbilityOnTarget(target, dism, -1)
    EmitSoundOn( DISM_SOUNDBOX[RandomInt(1, #DISM_SOUNDBOX)], thisEntity )
    return true
end

function CanCastRot()
    if not rot or thisEntity.rotCooldown > 0 or not rot:IsFullyCastable() then
        return false
    end
    local manaCost = rot:GetManaCost(-1) or 0
    if thisEntity:GetMana() < manaCost then
        return false
    end
    -- If Pudge already has Rot turned on, no need to cast again
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
    -- If we don’t really need items, go back to idle
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
            if itemName == "item_urn_of_shadows" and target then
                -- Use urn on an enemy if they're fairly distant
                if (target:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() > 700 then
                    thisEntity:CastAbilityOnTarget(target, item, -1)
                end

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
    -- Pudge uses items if his health is below 95%
    return (thisEntity:GetHealth() / thisEntity:GetMaxHealth()) < 0.95
end

--------------------------------------------------------------
-- Movement & Positioning
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

    -- If too far from spawn, force returning
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
        -- Move incrementally closer
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
-- Target Selection
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

-- Return the "best" target from a table of enemies
function GetBestTarget(units)
    if #units == 0 then return nil end

    -- Example logic: Sort by lowest health, then by closest distance
    table.sort(units, function(a, b)
        if a:GetHealth() == b:GetHealth() then
            return (a:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D() < 
                   (b:GetAbsOrigin() - thisEntity:GetAbsOrigin()):Length2D()
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
    return enemies[1]  -- Because they are sorted by FIND_CLOSEST
end

--------------------------------------------------------------
-- Placeholder "Hit" Detection
-- In a real scenario, you'd use OnProjectileHitUnit or
-- other game events to see if Meat Hook actually hit a target.
--------------------------------------------------------------
function HookHit(target)
    -- 50% random chance
    return (RandomInt(0,1) == 1)
end

function RotHit(target)
    -- 50% random chance
    return (RandomInt(0,1) == 1)
end

function DismemberHit(target)
    -- 50% random chance
    return (RandomInt(0,1) == 1)
end

--------------------------------------------------------------
-- Casting Check
--------------------------------------------------------------
function IsCastingAbility()
    -- If current active ability is channeling or in an ability phase
    local currentOrder = thisEntity:GetCurrentActiveAbility()
    if currentOrder then
        return (currentOrder:IsChanneling() or currentOrder:IsInAbilityPhase())
    end
    return false
end

--------------------------------------------------------------
-- Dialog / "Taunt" Lines
--------------------------------------------------------------
function PlayDialog()
    local dialog = PUDGE_DIALOG[RandomInt(1, #PUDGE_DIALOG)]
    -- If you have a valid sound event, use:
    -- thisEntity:EmitSound("<sound_event>")
    -- For actual text lines, you could do:
    -- GameRules:SendCustomMessage(dialog, 0, 0)
    -- Here, we just attempt to call it as a sound event:
    EmitSoundOn(dialog, thisEntity)
end
