local THINK_INTERVAL = 0.25
local HOOK_WINDUP = 0.75
local HOOK_WINDUP_INTERVAL = 0.03
local HOOK_WARNING = "particles/ui_mouseactions/range_finder_line.vpcf"
local HOOK_ORIGIN_TOLERANCE = 25
local ACQUISITION_RADIUS = 1300
local LEASH_RADIUS = 1400
local HOME_RADIUS = 50
local ROT_HYSTERESIS = 75
local MIN_HOOK_DISTANCE = 325
local MAX_LEAD_TIME = 1.8

local function IsValid(handle)
    return handle and not handle:IsNull()
end

local function IsReady(ability)
    return IsValid(ability) and ability:IsFullyCastable()
end

local function LearnAbility(boss, name)
    local ability = boss:FindAbilityByName(name)
    if IsValid(ability) and ability:GetLevel() == 0 then
        ability:SetLevel(1)
    end
    return ability
end

-- Each scan uses what Bador's team can see. Dropping an observation also
-- drops its velocity, so a hero emerging from fog gets a fresh first sample.
local function Survey(boss, home, origin, now, previous, focus, interrupt_range)
    local units = FindUnitsInRadius(boss:GetTeamNumber(), origin, nil, ACQUISITION_RADIUS,
        DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
            + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_CLOSEST, false)
    local scene = { seen = {}, close_heroes = 0, attackers = 0, nearest = math.huge, nearest_hero = math.huge }
    local best = -math.huge
    for _, unit in ipairs(units) do
        if unit ~= boss and IsValid(unit) and unit:IsAlive() then
            local position = unit:GetAbsOrigin()
            local contact = { position = position, time = now }
            local last = previous[unit]
            if last and now > last.time and now - last.time <= 0.6 and not unit:IsRooted() and not unit:IsStunned() then
                local velocity = (position - last.position) * (1 / (now - last.time))
                -- Discard jumps from blinks and forced movement.
                if velocity:Length2D() <= 700 then
                    contact.velocity = velocity
                end
            end
            scene.seen[unit] = contact

            if unit:GetTeamNumber() ~= boss:GetTeamNumber() and (position - home):Length2D() <= LEASH_RADIUS then
                local distance = (position - origin):Length2D()
                local score = -0.55 * distance
                scene.nearest = math.min(scene.nearest, distance)
                contact.hero = unit:IsRealHero() and not unit:IsIllusion()
                if contact.hero then
                    scene.nearest_hero = math.min(scene.nearest_hero, distance)
                    score = score + 1000 + 350 * (1 - unit:GetHealth() / unit:GetMaxHealth())
                    if distance <= 650 then
                        scene.close_heroes = scene.close_heroes + 1
                    end
                    if unit:IsChanneling() and distance <= interrupt_range then score = score + 700 end
                    if unit:GetAttackTarget() == boss then
                        scene.attackers = scene.attackers + 1
                        score = score + 160
                    end
                    local casting = unit:GetCurrentActiveAbility()
                    if IsValid(casting) and casting:IsInAbilityPhase() and casting:GetCursorTarget() == boss then
                        scene.incoming_spell = true
                    end
                end
                if unit == focus then score = score + 110 end
                contact.score = score
                if score > best then
                    best, scene.target = score, unit
                end
            end
        end
    end
    return scene
end

local function HookAim(flight, origin, contact)
    local position = contact.position
    if not contact.velocity then return position end

    if flight.speed <= 0 then return position end
    local aim = position
    for _ = 1, 2 do
        local travel = (aim - origin):Length2D() / flight.speed
        aim = position + contact.velocity * math.min(flight.delay + travel, MAX_LEAD_TIME)
    end
    return aim
end

local function HookLaneClear(origin, aim, target, seen, flight)
    local offset = aim - origin
    local length = offset:Length2D()
    if length == 0 then return false end
    local dx, dy = offset.x / length, offset.y / length
    for unit, contact in pairs(seen) do
        if unit ~= target then
            local relative = contact.position - origin
            local forward = relative.x * dx + relative.y * dy
            local lateral = relative.x * dy - relative.y * dx
            local clearance = flight.width + unit:GetHullRadius()
            if forward >= 0 and forward < length and math.abs(lateral) <= clearance then return false end

            -- A clear lane now can be occupied when the projectile arrives.
            local velocity = contact.velocity
            if velocity and flight.speed > 0 then
                local travel = math.max(0, math.min(length, forward)) / flight.speed
                local time = math.min(MAX_LEAD_TIME, flight.delay + travel)
                forward = forward + time * (velocity.x * dx + velocity.y * dy)
                lateral = lateral + time * (velocity.x * dy - velocity.y * dx)
                if forward >= 0 and forward < length and math.abs(lateral) <= clearance then return false end
            end
        end
    end
    return true
end

local function CanHook(hook, origin, position)
    if not IsReady(hook) then
        return false
    end
    local distance = (position - origin):Length2D()
    local range = hook:GetCastRange(origin, nil)
    local travel_distance = hook:GetSpecialValueFor("hook_distance")
    if travel_distance > 0 and (range <= 0 or travel_distance < range) then
        range = travel_distance
    end
    return distance >= MIN_HOOK_DISTANCE and distance <= range
end

local function ShowHookWarning(boss, origin, position, hook)
    local direction = Vector(position.x - origin.x, position.y - origin.y, 0):Normalized()
    local reach = hook:GetSpecialValueFor("hook_distance")
    if reach <= 0 then
        reach = hook:GetCastRange(origin, nil)
    end

    local warning = ParticleManager:CreateParticle(HOOK_WARNING, PATTACH_WORLDORIGIN, boss)
    local endpoint = GetGroundPosition(origin + direction * reach, boss)
    ParticleManager:SetParticleControl(warning, 0, origin)
    ParticleManager:SetParticleControl(warning, 1, endpoint)
    return warning, direction
end

local function FindHookAngle(boss, home, origin, aim, hook, scene, flight)
    local direction = (aim - origin):Normalized()
    local side = Vector(-direction.y, direction.x, 0)
    for _, step in ipairs({ 280, -280 }) do
        local position = GetGroundPosition(origin + direction * 100 + side * step, boss)
        if (position - home):Length2D() <= LEASH_RADIUS and CanHook(hook, position, aim)
            and HookLaneClear(position, aim, scene.target, scene.seen, flight)
            and GridNav:IsTraversable(position) and not GridNav:IsBlocked(position)
            and GridNav:CanFindPath(origin, position) then
            return position
        end
    end
end

local function CanTarget(boss, ability, target, origin)
    return IsReady(ability) and (target:GetAbsOrigin() - origin):Length2D() <= ability:GetCastRange(origin, target)
        and not target:HasModifier("modifier_item_lotus_orb_active")
        and UnitFilter(target, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(),
            ability:GetAbilityTargetFlags(), boss:GetTeamNumber()) == UF_SUCCESS
end

local function TryDefense(boss, scene)
    if boss:IsMuted() then return false end
    local health = boss:GetHealth() / boss:GetMaxHealth()
    local lotus = boss:FindItemInInventory("item_lotus_orb")
    if (scene.incoming_spell or boss:IsSilenced()) and IsReady(lotus)
        and not boss:HasModifier("modifier_item_lotus_orb_active") then
        boss:CastAbilityOnTarget(boss, lotus, -1)
        return true
    end

    local blade_mail = boss:FindItemInInventory("item_blade_mail")
    if (scene.attackers >= 2 or (health <= 0.95 and scene.nearest_hero <= 350)) and IsReady(blade_mail)
        and not boss:HasModifier("modifier_item_blade_mail_reflect") then
        boss:CastAbilityNoTarget(blade_mail, -1)
        return true
    end

    local shivas_guard = boss:FindItemInInventory("item_shivas_guard")
    if (scene.close_heroes >= 2 or (health <= 0.75 and scene.nearest_hero <= 650)) and IsReady(shivas_guard) then
        boss:CastAbilityNoTarget(shivas_guard, -1)
        return true
    end
    return false
end

function Spawn()
    local boss = thisEntity
    if not IsValid(boss) then
        return
    end

    local home = boss:GetAbsOrigin()
    local hook = LearnAbility(boss, "skill_pudge_meat_hook")
    local rot = LearnAbility(boss, "pudge_rot")
    local dismember = LearnAbility(boss, "pudge_dismember")
    local overpower = LearnAbility(boss, "ursa_overpower")
    local earthshock = LearnAbility(boss, "ursa_earthshock")
    local returning = false
    local pending_hook
    local previous = {}
    local focus
    local next_flank_time = 0
    local flank

    local function ClearHook()
        if pending_hook then
            ParticleManager:DestroyParticle(pending_hook.warning, true)
            ParticleManager:ReleaseParticleIndex(pending_hook.warning)
            pending_hook = nil
        end
    end

    local function TryHook(origin, scene, now, distance)
        if not IsReady(hook) or distance < MIN_HOOK_DISTANCE then return end

        local flight = {
            width = hook:GetSpecialValueFor("hook_width"),
            speed = hook:GetSpecialValueFor("hook_speed"),
            delay = HOOK_WINDUP + hook:GetCastPoint(),
        }
        local function AimFor(unit)
            -- Take a movement sample before committing to a newly spotted runner.
            if unit:IsMoving() and not scene.seen[unit].velocity and not unit:IsRooted() and not unit:IsStunned() then
                return
            end
            local aim = HookAim(flight, origin, scene.seen[unit])
            if CanHook(hook, origin, aim) and (aim - home):Length2D() <= LEASH_RADIUS then
                return aim
            end
        end

        local target = scene.target
        if not scene.seen[target].hero then return end
        local primary_aim = AimFor(target)
        local shot
        if primary_aim and HookLaneClear(origin, primary_aim, target, scene.seen, flight) then
            shot = primary_aim
        else
            -- A screened carry can still leave a second hero open to a pull.
            local best = -math.huge
            for unit, contact in pairs(scene.seen) do
                if unit ~= target and contact.hero and contact.score > best then
                    local aim = AimFor(unit)
                    if aim and HookLaneClear(origin, aim, unit, scene.seen, flight) then
                        best, shot = contact.score, aim
                    end
                end
            end
        end

        if shot then
            boss:Stop()
            local warning, direction = ShowHookWarning(boss, origin, shot, hook)
            pending_hook = { warning = warning, origin = origin, position = shot, release_time = now + HOOK_WINDUP }
            flank = nil
            boss:SetForwardVector(direction)
            EmitSoundOn("pudge_pud_ability_hook_01", boss)
            return HOOK_WINDUP_INTERVAL
        end

        if not primary_aim or scene.nearest <= boss:Script_GetAttackRange() or boss:IsRooted() then return end
        if flank and flank.target == target and now < flank.until_time
            and (origin - flank.position):Length2D() > HOME_RADIUS then
            return THINK_INTERVAL
        end
        if now < next_flank_time then return end

        next_flank_time = now + 1.25
        local position = FindHookAngle(boss, home, origin, primary_aim, hook, scene, flight)
        if position then
            flank = { target = target, position = position, until_time = now + 0.8 }
            boss:MoveToPosition(position)
            return THINK_INTERVAL
        end
    end

    boss:SetContextThink("BadorThink", function()
        if not IsValid(boss) or not boss:IsAlive() or GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
            ClearHook()
            return nil
        end
        if GameRules:IsGamePaused() then return THINK_INTERVAL end
        if boss:IsStunned() or boss:IsHexed() or boss:IsCommandRestricted() or boss:IsOutOfGame() then
            ClearHook()
            return THINK_INTERVAL
        end

        local active_ability = boss:GetCurrentActiveAbility()
        if boss:IsChanneling() or (IsValid(active_ability) and active_ability:IsInAbilityPhase()) then
            ClearHook()
            return THINK_INTERVAL
        end

        local origin = boss:GetAbsOrigin()
        local home_distance = (origin - home):Length2D()
        returning = home_distance > LEASH_RADIUS or (returning and home_distance > HOME_RADIUS)
        local can_cast = not boss:IsSilenced()

        if pending_hook then
            if returning or not can_cast or (origin - pending_hook.origin):Length2D() > HOOK_ORIGIN_TOLERANCE then
                ClearHook()
                return THINK_INTERVAL
            end

            local remaining = pending_hook.release_time - GameRules:GetGameTime()
            if remaining > 0.001 then
                return math.min(remaining, HOOK_WINDUP_INTERVAL)
            end

            local position = pending_hook.position
            ClearHook()
            if CanHook(hook, origin, position) then
                boss:CastAbilityOnPosition(position, hook, -1)
            end
            return THINK_INTERVAL
        end

        local now = GameRules:GetGameTime()
        local scene
        if not returning then
            local interrupt_range = 0
            if can_cast and IsReady(dismember) then interrupt_range = dismember:GetCastRange(origin, nil) end
            if can_cast and IsReady(hook) then interrupt_range = math.max(interrupt_range, hook:GetCastRange(origin, nil)) end
            scene = Survey(boss, home, origin, now, previous, focus, interrupt_range)
        end
        previous = scene and scene.seen or {}
        focus = scene and scene.target
        local target = focus
        local rot_active = IsValid(rot) and rot:GetToggleState()

        if not target then
            flank = nil
            if can_cast and rot_active then
                boss:CastAbilityToggle(rot, -1)
            elseif home_distance > HOME_RADIUS then
                returning = true
                boss:MoveToPosition(home)
            elseif IsValid(boss:GetAttackTarget()) then
                boss:Stop()
            elseif not returning and not boss:IsMuted() and boss:GetHealth() < 0.75 * boss:GetMaxHealth()
                and not boss:HasModifier("modifier_item_urn_heal") then
                local urn = boss:FindItemInInventory("item_urn_of_shadows")
                if IsReady(urn) and urn:GetCurrentCharges() > 1 then
                    boss:CastAbilityOnTarget(boss, urn, -1)
                end
            end
            return THINK_INTERVAL
        end

        local target_position = target:GetAbsOrigin()
        local distance = (target_position - origin):Length2D()
        local enemy_hero = scene.seen[target].hero
        local can_grab = can_cast and (enemy_hero or target:IsChanneling()) and CanTarget(boss, dismember, target, origin)
        if can_grab and target:IsChanneling() then
            boss:CastAbilityOnTarget(target, dismember, -1)
            return THINK_INTERVAL
        end
        if TryDefense(boss, scene) then return THINK_INTERVAL end

        if can_cast then
            local hook_interval = TryHook(origin, scene, now, distance)
            if hook_interval then return hook_interval end
        end
        flank = nil

        if can_cast and IsValid(rot) then
            local rot_radius = rot:GetSpecialValueFor("rot_radius")
            if rot_radius <= 0 then
                rot_radius = 250
            end
            if (rot_active and scene.nearest > rot_radius + ROT_HYSTERESIS)
                or (not rot_active and scene.nearest <= rot_radius and IsReady(rot)) then
                boss:CastAbilityToggle(rot, -1)
                return THINK_INTERVAL
            end
        end

        local urn = boss:FindItemInInventory("item_urn_of_shadows")
        if can_grab then
            boss:CastAbilityOnTarget(target, dismember, -1)
        elseif enemy_hero and not boss:IsMuted() and distance >= 500 and CanTarget(boss, urn, target, origin)
            and urn:GetCurrentCharges() > 0 and not target:HasModifier("modifier_item_urn_damage") then
            boss:CastAbilityOnTarget(target, urn, -1)
        elseif can_cast and distance <= 250 and not boss:IsRooted() and IsReady(earthshock)
            and bit.band(earthshock:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0 then
            boss:CastAbilityNoTarget(earthshock, -1)
        elseif can_cast and distance <= 250 and IsReady(overpower)
            and bit.band(overpower:GetBehaviorInt(), DOTA_ABILITY_BEHAVIOR_NO_TARGET) ~= 0 then
            boss:CastAbilityNoTarget(overpower, -1)
        elseif boss:GetAttackTarget() ~= target then
            boss:MoveToTargetToAttack(target)
        end
        return THINK_INTERVAL
    end, THINK_INTERVAL)
end
