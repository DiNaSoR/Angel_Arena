-- The brain every arena monster and boss runs on. Written once; biomes only describe their
-- abilities (and, where the defaults are wrong, how to use them).
--
-- Each think the brain:
--   1. walks home if it was pulled more than `leash` from its post, healing on the way and
--      ignoring everything until it arrives (so monsters cannot be kited across the map);
--   2. picks a target: whatever hit it or its group recently, else the nearest visible enemy
--      within `aggro`, but never one standing outside the leash;
--   3. uses the first ready ability whose conditions hold, else attacks. Abilities are tried in
--      `order` when one is given (a boss: the order of boss.lua's `abilities` list), then any
--      others in unit slot order (camp monsters: the order of Ability1, Ability2... in the unit KV).
--
-- How an ability is used comes from its KV behaviour, so most abilities need no hints at all:
--   unit target, enemy team   -> cast on the target              ("enemy")
--   unit target, friendly team-> cast on a wounded ally in range ("ally")
--   point target              -> cast at the target's position   ("point")
--   no target                 -> cast when the target is within the ability's "radius" ("self")
-- Hints (in the biome's monsters.lua `ai` table or boss.lua `abilities`) can override this:
--   target = "enemy" | "ally" | "point" | "self"
--   radius, range, min_range      distances in units
--   health_below = 0.6            only while the caster's health is below 60%
--   ally_health_below = 0.7       how hurt an ally must be for an "ally" cast (default 0.7)
--   lock = 1.5                    seconds after the cast before the brain casts again (bosses use
--                                 this so two telegraphs never land on top of each other)

require("arena/core/modifiers")

if ArenaMonsterAI then
    return ArenaMonsterAI
end

ArenaMonsterAI = {}

ArenaMonsterAI.THINK_INTERVAL = 0.5
ArenaMonsterAI.HOME_RADIUS = 100        -- close enough to count as home
ArenaMonsterAI.DRIFT = 250              -- an idle monster further than this from home walks back
ArenaMonsterAI.GROUP_MEMORY = 4         -- seconds a group remembers who attacked one of its members
ArenaMonsterAI.DEFAULT_RANGE = 600
ArenaMonsterAI.DEFAULT_RADIUS = 300
ArenaMonsterAI.TURN_TIME = 0.5          -- time allowed for turning to face a target before a cast
ArenaMonsterAI.RETRY = 1.5              -- an ability just ordered is not ordered again for this long
                                        -- (a refused order, e.g. on a spell-immune hero, must not
                                        -- keep the monster from attacking)

local function Has(flags, flag)
    return bit.band(flags or 0, flag) ~= 0
end

local function Distance(a, b)
    return (a - b):Length2D()
end

function ArenaMonsterAI.Attach(unit, options)
    options = options or {}
    local brain = {
        unit = unit,
        home = options.home or unit:GetAbsOrigin(),
        leash = options.leash or 900,
        aggro = options.aggro or 0,
        hints = options.hints or {},
        order = options.order,
        group = options.group,
        interval = options.interval or ArenaMonsterAI.THINK_INTERVAL,
        onThink = options.onThink,
        onHome = options.onHome,
        lockUntil = 0,
        retryAt = {},
        returning = false,
    }
    unit.arenaBrain = brain
    if not unit:HasModifier("modifier_arena_monster") then
        unit:AddNewModifier(unit, nil, "modifier_arena_monster", {})
    end
    unit:SetContextThink("ArenaMonsterAI", function()
        local ok, wait = pcall(ArenaMonsterAI.Think, brain)
        if ok then
            return wait
        end
        if not brain.failed then
            brain.failed = true
            print("[Arena] brain of " .. tostring(unit:GetUnitName()) .. " failed: " .. tostring(wait))
        end
        return brain.interval
    end, options.delay or RandomFloat(0.1, brain.interval))
    return brain
end

-- How the brain would use an ability with no hints, from its KV behaviour. nil for passives.
function ArenaMonsterAI.Infer(ability)
    local behavior = ability:GetBehaviorInt()
    -- Passives work on their own; toggles (a harpy taking off) would flicker if spammed.
    if Has(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE) or Has(behavior, DOTA_ABILITY_BEHAVIOR_TOGGLE) then
        return nil
    end
    if Has(behavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
        local team = ability:GetAbilityTargetTeam()
        if Has(team, DOTA_UNIT_TARGET_TEAM_FRIENDLY) and not Has(team, DOTA_UNIT_TARGET_TEAM_ENEMY) then
            return "ally"
        end
        return "enemy"
    end
    if Has(behavior, DOTA_ABILITY_BEHAVIOR_POINT) then
        return "point"
    end
    if Has(behavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
        return "self"
    end
end

-- A target the brain may fight: an alive, visible enemy standing inside the leash.
function ArenaMonsterAI.CanFight(brain, target)
    local unit = brain.unit
    return target ~= nil and IsValidEntity(target) and target:IsAlive()
        and target:GetTeamNumber() ~= unit:GetTeamNumber()
        and unit:CanEntityBeSeenByMyTeam(target)
        and Distance(target:GetAbsOrigin(), brain.home) <= brain.leash
end

function ArenaMonsterAI.PickTarget(brain, origin, now)
    local unit = brain.unit
    local current = unit:GetAttackTarget()
    if ArenaMonsterAI.CanFight(brain, current) then
        return current
    end
    if brain.provoker and now - (brain.provokedAt or 0) <= ArenaMonsterAI.GROUP_MEMORY
        and ArenaMonsterAI.CanFight(brain, brain.provoker) then
        return brain.provoker
    end
    local group = brain.group
    if group and group.target and now - (group.targetAt or 0) <= ArenaMonsterAI.GROUP_MEMORY
        and ArenaMonsterAI.CanFight(brain, group.target) then
        return group.target
    end
    if brain.aggro > 0 then
        local enemies = FindUnitsInRadius(unit:GetTeamNumber(), origin, nil, brain.aggro,
            DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
            DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_CLOSEST, false)
        for _, enemy in ipairs(enemies) do
            if ArenaMonsterAI.CanFight(brain, enemy) then
                return enemy
            end
        end
    end
end

function ArenaMonsterAI.WoundedAlly(unit, origin, range, below)
    local allies = FindUnitsInRadius(unit:GetTeamNumber(), origin, nil, range,
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    local best, lowest
    for _, ally in ipairs(allies) do
        local fraction = ally:GetHealth() / math.max(1, ally:GetMaxHealth())
        if ally:IsAlive() and fraction < below and (not lowest or fraction < lowest) then
            best, lowest = ally, fraction
        end
    end
    return best
end

-- Whether the engine would let `ability` target `target` (team, type, flags, spell immunity).
function ArenaMonsterAI.Allowed(unit, ability, target)
    return UnitFilter(target, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(),
        ability:GetAbilityTargetFlags(), unit:GetTeamNumber()) == UF_SUCCESS
end

-- Tries to use one ability on `target`. Returns true when an order was issued.
function ArenaMonsterAI.Use(brain, ability, hint, target, origin, now)
    local mode = hint.target or ArenaMonsterAI.Infer(ability)
    if not mode then
        return false
    end
    local unit = brain.unit
    if hint.health_below and unit:GetHealth() > hint.health_below * unit:GetMaxHealth() then
        return false
    end
    local position = target:GetAbsOrigin()
    local distance = Distance(position, origin)
    local range = hint.range or ability:GetCastRange(origin, nil)
    if not range or range <= 0 then
        range = ArenaMonsterAI.DEFAULT_RANGE
    end
    if mode == "self" then
        local radius = hint.radius or ability:GetSpecialValueFor("radius")
        if not radius or radius <= 0 then
            radius = ArenaMonsterAI.DEFAULT_RADIUS
        end
        if distance > radius then return false end
        unit:CastAbilityNoTarget(ability, -1)
    elseif mode == "ally" then
        local ally = ArenaMonsterAI.WoundedAlly(unit, origin, range, hint.ally_health_below or 0.7)
        if not ally or not ArenaMonsterAI.Allowed(unit, ability, ally) then return false end
        unit:CastAbilityOnTarget(ally, ability, -1)
    else
        if distance > range or distance < (hint.min_range or 0) then return false end
        if mode == "point" then
            unit:CastAbilityOnPosition(position, ability, -1)
        else
            if not ArenaMonsterAI.Allowed(unit, ability, target) then return false end
            unit:CastAbilityOnTarget(target, ability, -1)
        end
    end
    brain.lockUntil = now + (hint.lock or 0)
    brain.retryAt[ability:GetAbilityName()] = now + ArenaMonsterAI.RETRY
    -- Give the order time to turn into a cast before anything replaces it.
    brain.pending = { ability = ability, untilTime = now + ability:GetCastPoint() + ArenaMonsterAI.TURN_TIME }
    return true
end

function ArenaMonsterAI.TryCast(brain, target, origin, now)
    local unit = brain.unit
    if now < brain.lockUntil or unit:IsSilenced() or unit:IsMuted() then
        return false
    end
    for _, ability in ipairs(ArenaMonsterAI.Abilities(brain)) do
        if ability:GetLevel() > 0 and not ability:IsHidden() and ability:IsFullyCastable()
            and now >= (brain.retryAt[ability:GetAbilityName()] or 0) then
            local hint = brain.hints[ability:GetAbilityName()] or {}
            if ArenaMonsterAI.Use(brain, ability, hint, target, origin, now) then
                return true
            end
        end
    end
    return false
end

-- The unit's abilities in the order the brain tries them: the names in `brain.order` first, then
-- every other ability in slot order.
function ArenaMonsterAI.Abilities(brain)
    local unit = brain.unit
    local list, seen = {}, {}
    for _, name in ipairs(brain.order or {}) do
        local ability = unit:FindAbilityByName(name)
        if ability and not seen[name] then
            seen[name] = true
            list[#list + 1] = ability
        end
    end
    for index = 0, unit:GetAbilityCount() - 1 do
        local ability = unit:GetAbilityByIndex(index)
        if ability and not seen[ability:GetAbilityName()] then
            seen[ability:GetAbilityName()] = true
            list[#list + 1] = ability
        end
    end
    return list
end

function ArenaMonsterAI.ReturnHome(brain)
    local unit = brain.unit
    brain.returning = true
    brain.provoker = nil
    unit:AddNewModifier(unit, nil, "modifier_arena_monster_returning", {})
    unit:MoveToPosition(brain.home)
end

function ArenaMonsterAI.ArriveHome(brain)
    local unit = brain.unit
    brain.returning = false
    unit:RemoveModifierByName("modifier_arena_monster_returning")
    unit:Stop()
    if brain.onHome then
        brain.onHome(brain)
    end
end

function ArenaMonsterAI.Think(brain)
    local unit = brain.unit
    if not IsValidEntity(unit) or not unit:IsAlive() then
        return nil
    end
    -- A dominated or converted monster belongs to its new owner now.
    if unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
        unit:RemoveModifierByName("modifier_arena_monster_returning")
        return nil
    end
    if GameRules:IsGamePaused() then
        return brain.interval
    end
    local now = GameRules:GetGameTime()
    if brain.onThink then
        local wait = brain.onThink(brain, now)
        if wait then return wait end
    end
    if unit:IsStunned() or unit:IsHexed() or unit:IsCommandRestricted() or unit:IsChanneling() then
        return brain.interval
    end
    local active = unit:GetCurrentActiveAbility()
    if active and active:IsInAbilityPhase() then
        return brain.interval
    end
    -- A cast was just ordered and has not started (still turning or walking into range): wait for it
    -- instead of replacing the order with an attack.
    local pending = brain.pending
    if pending then
        if now < pending.untilTime and not pending.ability:IsNull() and pending.ability:IsCooldownReady() then
            return brain.interval
        end
        brain.pending = nil
    end

    local origin = unit:GetAbsOrigin()
    local fromHome = Distance(origin, brain.home)
    if brain.returning then
        if fromHome <= ArenaMonsterAI.HOME_RADIUS then
            ArenaMonsterAI.ArriveHome(brain)
        else
            unit:MoveToPosition(brain.home)
        end
        return brain.interval
    end
    if fromHome > brain.leash then
        ArenaMonsterAI.ReturnHome(brain)
        return brain.interval
    end

    local target = ArenaMonsterAI.PickTarget(brain, origin, now)
    if not target then
        if fromHome > ArenaMonsterAI.DRIFT then
            unit:MoveToPosition(brain.home)
        end
        return brain.interval
    end
    if brain.group then
        brain.group.target, brain.group.targetAt = target, now
    end
    if ArenaMonsterAI.TryCast(brain, target, origin, now) then
        return brain.interval
    end
    if unit:GetAttackTarget() ~= target then
        unit:MoveToTargetToAttack(target)
    end
    return brain.interval
end

return ArenaMonsterAI
