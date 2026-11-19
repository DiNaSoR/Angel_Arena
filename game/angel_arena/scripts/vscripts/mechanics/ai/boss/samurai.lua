local THINK_INTERVAL = 0.5
local ACQUISITION_RADIUS = 1300
local LEASH_RADIUS = 1400
local HOME_RADIUS = 50

local function FindTarget(boss, home, origin)
    local enemies = FindUnitsInRadius(
        boss:GetTeamNumber(), origin, nil, ACQUISITION_RADIUS,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
            + DOTA_UNIT_TARGET_FLAG_NO_INVIS,
        FIND_CLOSEST, false
    )

    for _, enemy in ipairs(enemies) do
        if not enemy:IsNull() and enemy:IsAlive()
            and (enemy:GetAbsOrigin() - home):Length2D() <= LEASH_RADIUS then
            return enemy
        end
    end
end

function Spawn()
    local boss = thisEntity
    if not boss or boss:IsNull() then
        return
    end

    local home = boss:GetAbsOrigin()
    local returning = false

    boss:SetContextThink("SamuraiThink", function()
        if boss:IsNull() or not boss:IsAlive() then
            return nil
        end
        if boss:IsStunned() or boss:IsHexed() then
            return THINK_INTERVAL
        end

        local origin = boss:GetAbsOrigin()
        local home_distance = (origin - home):Length2D()
        returning = home_distance > LEASH_RADIUS or (returning and home_distance > HOME_RADIUS)
        local target = not returning and FindTarget(boss, home, origin)
        if not target then
            if home_distance > HOME_RADIUS then
                returning = true
                boss:MoveToPosition(home)
            elseif boss:GetAttackTarget() then
                boss:Stop()
            end
            return THINK_INTERVAL
        end

        local strafe = boss:FindAbilityByName("clinkz_strafe")
        local distance = (target:GetAbsOrigin() - origin):Length2D()
        if distance <= boss:Script_GetAttackRange() and not boss:IsSilenced()
            and strafe and not strafe:IsNull() and strafe:IsFullyCastable()
            and bit.band(strafe:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0 then
            boss:CastAbilityNoTarget(strafe, -1)
        elseif boss:GetAttackTarget() ~= target then
            boss:MoveToTargetToAttack(target)
        end
        return THINK_INTERVAL
    end, THINK_INTERVAL)
end
