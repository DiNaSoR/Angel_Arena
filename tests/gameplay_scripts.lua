local vscripts = "game/angel_arena/scripts/vscripts"

local function LoadScript(path, environment)
    local chunk = assert(loadfile(vscripts .. "/" .. path))
    setfenv(chunk, setmetatable(environment, { __index = _G }))
    chunk()
    return environment
end

local vector = {}
vector.__index = vector
local function Vector(x, y, z)
    return setmetatable({ x = x, y = y or 0, z = z or 0 }, vector)
end
function vector.__sub(a, b) return Vector(a.x - b.x, a.y - b.y, a.z - b.z) end
function vector.__add(a, b) return Vector(a.x + b.x, a.y + b.y, a.z + b.z) end
function vector.__mul(a, scale) return Vector(a.x * scale, a.y * scale, a.z * scale) end
function vector:Length2D() return math.sqrt(self.x * self.x + self.y * self.y) end
function vector:Normalized() return self * (1 / self:Length2D()) end

local function Ability(range, special_value, behavior)
    return {
        ready = true,
        level = 0,
        toggled = false,
        IsNull = function() return false end,
        GetLevel = function(self) return self.level end,
        SetLevel = function(self, level) self.level = level end,
        IsFullyCastable = function(self) return self.ready end,
        GetCastRange = function() return range or 0 end,
        GetSpecialValueFor = function(_, key)
            if key == "hook_speed" then return 600 end
            if key == "hook_width" then return 100 end
            return special_value or 0
        end,
        GetCastPoint = function() return 0.3 end,
        GetCursorTarget = function(self) return self.cursor_target end,
        GetAbilityTargetFlags = function() return 0 end,
        GetAbilityTargetTeam = function() return 1 end,
        GetAbilityTargetType = function() return 3 end,
        GetToggleState = function(self) return self.toggled end,
        GetBehaviorInt = function() return behavior or 0 end,
        GetCurrentCharges = function(self) return self.charges end,
        IsInAbilityPhase = function() return true end,
        EndCooldown = function(self) self.refreshed = true end,
    }
end

local function Unit(x)
    return {
        abilities = {},
        items = {},
        actions = {},
        warnings = {},
        time = 0,
        position = Vector(x),
        health = 100,
        alive = true,
        IsNull = function() return false end,
        IsAlive = function(self) return self.alive end,
        IsCommandRestricted = function(self) return self.restricted end,
        IsOutOfGame = function() return false end,
        IsMoving = function(self) return self.moving end,
        IsRealHero = function(self) return not self.creep end,
        IsIllusion = function(self) return self.illusion end,
        GetHullRadius = function() return 24 end,
        IsRooted = function(self) return self.rooted end,
        HasModifier = function(self, modifier) return self.modifier == modifier end,
        IsChanneling = function(self) return self.channeling end,
        IsStunned = function(self) return self.stunned end,
        IsHexed = function() return false end,
        IsSilenced = function(self) return self.silenced end,
        IsMuted = function() return false end,
        IsRooted = function() return false end,
        GetCurrentActiveAbility = function(self) return self.active_ability end,
        GetHealth = function(self) return self.health end,
        GetMaxHealth = function() return 100 end,
        GetAbsOrigin = function(self) return self.position end,
        GetTeamNumber = function(self) return self.team or 2 end,
        GetAttackTarget = function(self) return self.target end,
        Script_GetAttackRange = function() return 230 end,
        FindAbilityByName = function(self, name) return self.abilities[name] end,
        FindItemInInventory = function(self, name) return self.items[name] end,
        SetForwardVector = function(self, direction) self.facing = direction end,
        SetContextThink = function(self, name, think) self.think = think end,
        Stop = function(self) table.insert(self.actions, { "stop" }) end,
        MoveToPosition = function(self, position) table.insert(self.actions, { "move", position }) end,
        MoveToTargetToAttack = function(self, target)
            table.insert(self.actions, { "attack", target })
            self.target = target
        end,
        CastAbilityOnPosition = function(self, position, ability)
            table.insert(self.actions, { "cast_position", position, ability })
            ability.ready = false
        end,
        CastAbilityOnTarget = function(self, target, ability)
            table.insert(self.actions, { "cast_target", target, ability })
            ability.ready = false
        end,
        CastAbilityNoTarget = function(self, ability)
            table.insert(self.actions, { "cast_no_target", ability })
            ability.ready = false
        end,
        CastAbilityToggle = function(self, ability)
            table.insert(self.actions, { "toggle", ability })
            ability.toggled = not ability.toggled
        end,
    }
end

local function SpawnBoss(path, boss, enemies)
    boss.team = 4
    local environment = LoadScript("mechanics/ai/boss/" .. path, {
        thisEntity = boss,
        Vector = Vector,
        GetGroundPosition = function(position) return position end,
        GameRules = {
            GetGameTime = function() return boss.time end,
            IsGamePaused = function() return boss.paused end,
            State_Get = function() return boss.state or 5 end,
        },
        DOTA_GAMERULES_STATE_POST_GAME = 7,
        GridNav = {
            IsTraversable = function(_, point) return not boss.block_left or point.y < 0 end,
            IsBlocked = function() return false end,
            CanFindPath = function() return not boss.no_path end,
        },
        UnitFilter = function(target) return target.untargetable and 1 or 0 end,
        UF_SUCCESS = 0,
        FindUnitsInRadius = function(team, origin, _, radius, team_filter, _, flags)
            assert(team == 4 and flags == 7)
            local visible = {}
            for _, unit in ipairs(enemies) do
                if not unit.hidden and (origin - unit.position):Length2D() <= radius
                    and (team_filter == 3 or unit:GetTeamNumber() ~= team) then
                    table.insert(visible, unit)
                end
            end
            return visible
        end,
        ParticleManager = {
            CreateParticle = function(_, resource, attachment, owner)
                assert(resource == "particles/ui_mouseactions/range_finder_line.vpcf")
                assert(attachment == 8 and owner == boss)
                local warning = {}
                table.insert(boss.warnings, warning)
                return #boss.warnings
            end,
            SetParticleControl = function(_, index, point, position)
                boss.warnings[index][point] = position
            end,
            DestroyParticle = function(_, index, immediate)
                assert(immediate and not boss.warnings[index].destroyed)
                boss.warnings[index].destroyed = true
            end,
            ReleaseParticleIndex = function(_, index)
                assert(boss.warnings[index].destroyed and not boss.warnings[index].released)
                boss.warnings[index].released = true
            end,
        },
        EmitSoundOn = function(sound, source)
            assert(source == boss)
            boss.last_sound = sound
        end,
        bit = {
            band = function(value, flag)
                return math.floor(value / flag) % 2 * flag
            end,
        },
        DOTA_UNIT_TARGET_TEAM_ENEMY = 1,
        DOTA_UNIT_TARGET_TEAM_BOTH = 3,
        DOTA_UNIT_TARGET_HERO = 1,
        DOTA_UNIT_TARGET_BASIC = 2,
        DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES = 1,
        DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE = 2,
        DOTA_UNIT_TARGET_FLAG_NO_INVIS = 4,
        DOTA_ABILITY_BEHAVIOR_NO_TARGET = 4,
        PATTACH_WORLDORIGIN = 8,
        FIND_CLOSEST = 1,
    })
    environment.Spawn()
    assert(boss.think)
end

local function ExpectAction(boss, kind)
    assert(#boss.actions == 1, ("expected one %s action, got %d"):format(kind, #boss.actions))
    local action = table.remove(boss.actions)
    assert(action[1] == kind, ("expected %s, got %s"):format(kind, action[1]))
    return action
end

do
    local refresh = LoadScript("items/funcs/refresh.lua", {}).Refresh
    local source, ability = Ability(), Ability()
    refresh(nil)
    refresh({
        caster = {
            IsNull = function() return false end,
            GetAbilityCount = function() return 3 end,
            GetAbilityByIndex = function(_, index)
                return ({ [0] = source, [2] = ability })[index]
            end,
        },
        ability = source,
    })
    assert(ability.refreshed and not source.refreshed, "refresh must skip the source and empty slots")
end

do
    local boss, target = Unit(0), Unit(600)
    local hook, rot, dismember = Ability(700, 700), Ability(0, 250), Ability(220)
    local blade_mail, urn = Ability(), Ability(950)
    urn.charges = 10
    boss.abilities = { skill_pudge_meat_hook = hook, pudge_rot = rot, pudge_dismember = dismember }
    boss.items = { item_blade_mail = blade_mail, item_urn_of_shadows = urn }
    SpawnBoss("bador_pudge.lua", boss, { target })

    assert(hook.level == 1, "configured creature spells should be trained")
    assert(boss.think() == 0.03)
    ExpectAction(boss, "stop")
    assert(boss.last_sound and boss.facing.x == 1)
    local warning = boss.warnings[1]
    assert(warning[0].x == 0 and warning[1].x == 700 and not warning.released)

    target.position = Vector(725)
    boss.time = 0.74
    assert(boss.think() > 0 and #boss.actions == 0 and not warning.released)
    boss.time = 0.75
    boss.think()
    local launched = ExpectAction(boss, "cast_position")
    assert(launched[2].x == 600 and launched[3] == hook, "hook should use the telegraphed point")
    assert(warning.released, "release should clear the warning")

    boss.think()
    local urn_cast = ExpectAction(boss, "cast_target")
    assert(urn_cast[2] == target and urn_cast[3] == urn)

    target.position = Vector(150)
    boss.think()
    assert(ExpectAction(boss, "toggle")[2] == rot and rot.toggled)

    boss.think()
    local melee_cast = ExpectAction(boss, "cast_target")
    assert(melee_cast[2] == target and melee_cast[3] == dismember)

    boss.channeling = true
    boss.think()
    assert(#boss.actions == 0, "orders must not interrupt a channel")
    boss.channeling = false
    boss.active_ability = dismember
    boss.think()
    assert(#boss.actions == 0, "orders must not interrupt an ability phase")
    boss.active_ability = nil

    boss.health = 90
    boss.think()
    assert(ExpectAction(boss, "cast_no_target")[2] == blade_mail)

    boss.position = Vector(1600)
    boss.think()
    ExpectAction(boss, "toggle")
    assert(not rot.toggled)
    boss.think()
    assert(ExpectAction(boss, "move")[2].x == 0)
    boss.position = Vector(1200)
    boss.think()
    assert(ExpectAction(boss, "move")[2].x == 0, "leash must keep the boss returning to spawn")

    boss.alive = false
    assert(boss.think() == nil)
end

do
    local boss, target = Unit(0), Unit(800)
    boss.abilities.skill_pudge_meat_hook = Ability(700, 1000)
    SpawnBoss("bador_pudge.lua", boss, { target })

    boss.think()
    ExpectAction(boss, "attack")
    assert(not boss.last_sound, "hook must use the engine's cast range")

    target.position = Vector(700)
    assert(boss.think() == 0.03)
    ExpectAction(boss, "stop")
    boss.time = 0.09
    boss.stunned = true
    boss.think()
    assert(#boss.actions == 0 and boss.warnings[1].released, "wind-up stun must cancel the warning and the hook")

    boss.time = 0.75
    boss.stunned = false
    assert(boss.think() == 0.03)
    ExpectAction(boss, "stop")

    boss.position = Vector(30)
    boss.time = 0.78
    boss.think()
    assert(#boss.actions == 0 and boss.warnings[2].released, "moving the boss off the warning line must cancel the hook")

    assert(boss.think() == 0.03)
    ExpectAction(boss, "stop")
    boss.alive = false
    assert(boss.think() == nil and boss.warnings[3].released, "death must clear the pending warning")
end

-- Track visible movement, then fire at the exact line drawn during wind-up.
do
    local boss, runner = Unit(0), Unit(480)
    local hook = Ability(700, 700)
    boss.abilities.skill_pudge_meat_hook = hook
    hook.ready = false
    SpawnBoss("bador_pudge.lua", boss, { runner })
    boss.think()
    ExpectAction(boss, "attack")
    hook.ready = true
    runner.position = Vector(480, 24)
    boss.time = 0.25
    boss.think()
    ExpectAction(boss, "stop")
    local direction = boss.facing
    assert(direction.y > 0.15, "a lateral runner should be led")
    runner.position = Vector(480, -200)
    boss.time = 1
    boss.think()
    local aim = ExpectAction(boss, "cast_position")[2]
    assert(math.abs(aim.y / aim.x - direction.y / direction.x) < 0.0001 and aim.y > 24)
end

do
    local boss, target = Unit(0), Unit(480)
    target.moving = true
    boss.abilities.skill_pudge_meat_hook = Ability(700, 700)
    SpawnBoss("bador_pudge.lua", boss, { target })
    boss.think()
    ExpectAction(boss, "attack")
    assert(#boss.warnings == 0, "observe a new runner before committing")
    boss.time = 0.25
    target.position = Vector(480, 20)
    boss.think()
    ExpectAction(boss, "stop")
    boss.restricted = true
    boss.think()
    assert(#boss.actions == 0 and boss.warnings[1].released)
end

-- Neither hidden movement nor a blink is a reliable velocity sample.
for _, lost_vision in ipairs({ false, true }) do
    local boss, target = Unit(0), Unit(450)
    local hook = Ability(700, 700)
    hook.ready = false
    boss.abilities.skill_pudge_meat_hook = hook
    SpawnBoss("bador_pudge.lua", boss, { target })
    boss.think()
    ExpectAction(boss, "attack")
    if lost_vision then
        boss.time = 0.1
        target.hidden = true
        boss.think()
        ExpectAction(boss, "stop")
        target.hidden = false
    end
    boss.time = 0.25
    target.position = Vector(450, lost_vision and 25 or 250)
    hook.ready = true
    boss.think()
    ExpectAction(boss, "stop")
    local expected = target.position:Normalized()
    assert(math.abs(boss.facing.y - expected.y) < 0.0001)
end

-- A friendly neutral in the line forces a reachable side-step or a fallback.
for _, no_path in ipairs({ false, true }) do
    local boss, target, blocker = Unit(0), Unit(600), Unit(300)
    blocker.team, blocker.creep = 4, true
    boss.block_left, boss.no_path = true, no_path
    boss.abilities.skill_pudge_meat_hook = Ability(700, 700)
    SpawnBoss("bador_pudge.lua", boss, { target, blocker })
    boss.think()
    assert(#boss.warnings == 0)
    if no_path then
        assert(ExpectAction(boss, "attack")[2] == target)
    else
        local flank = ExpectAction(boss, "move")[2]
        assert(flank.y < 0, "skip the untraversable side")
        boss.time = 0.25
        boss.think()
        assert(#boss.actions == 0, "give the side-step time to complete")
        boss.position = flank
        boss.time = 0.5
        boss.think()
        ExpectAction(boss, "stop")
        assert(#boss.warnings == 1)
    end
end

do
    local boss, target, crossing = Unit(0), Unit(600), Unit(300)
    local hook = Ability(700, 700)
    hook.ready, crossing.team, boss.no_path = false, 4, true
    crossing.position = Vector(300, 205)
    boss.abilities.skill_pudge_meat_hook = hook
    SpawnBoss("bador_pudge.lua", boss, { target, crossing })
    boss.think()
    ExpectAction(boss, "attack")
    boss.time, hook.ready = 0.25, true
    crossing.position = Vector(300, 180)
    boss.think()
    assert(#boss.warnings == 0 and hook.ready, "wait for a blocker crossing into the lane")
end

do
    local boss, wounded, blocker, exposed = Unit(0), Unit(600), Unit(300), Unit(0)
    wounded.health = 10
    exposed.position = Vector(0, 550)
    blocker.team, blocker.creep = 4, true
    boss.abilities.skill_pudge_meat_hook = Ability(700, 700)
    SpawnBoss("bador_pudge.lua", boss, { wounded, blocker, exposed })
    boss.think()
    ExpectAction(boss, "stop")
    assert(boss.facing.y == 1, "take the clear hook on the other hero")
end

do
    local boss, near, wounded, decoy = Unit(0), Unit(300), Unit(450), Unit(50)
    wounded.health = 15
    decoy.illusion = true
    SpawnBoss("bador_pudge.lua", boss, { decoy, near, wounded })
    boss.think()
    assert(ExpectAction(boss, "attack")[2] == wounded, "prioritize a reachable finishing target")
    near.health = 10
    boss.time = 0.25
    boss.think()
    assert(#boss.actions == 0, "small changes should not cause target switching")
    near.target = boss
    boss.time = 0.5
    boss.think()
    assert(ExpectAction(boss, "attack")[2] == near, "reassess a new aggressor")
end

do
    local boss, near, caster = Unit(0), Unit(100), Unit(200)
    local rot, grab = Ability(0, 250), Ability(225)
    boss.abilities = { pudge_rot = rot, pudge_dismember = grab }
    caster.channeling = true
    SpawnBoss("bador_pudge.lua", boss, { near, caster })
    boss.think()
    local interrupt = ExpectAction(boss, "cast_target")
    assert(interrupt[2] == caster and interrupt[3] == grab, "interrupt before toggling Rot")
end

do
    local boss, first, second = Unit(0), Unit(440), Unit(460)
    local lotus, blade, shivas = Ability(), Ability(), Ability()
    boss.items = { item_lotus_orb = lotus, item_blade_mail = blade, item_shivas_guard = shivas }
    first.active_ability = Ability()
    first.active_ability.cursor_target = boss
    first.target, second.target = boss, boss
    SpawnBoss("bador_pudge.lua", boss, { first, second })
    boss.think()
    local reflection = ExpectAction(boss, "cast_target")
    assert(reflection[2] == boss and reflection[3] == lotus, "respond to a visible incoming cast")
    boss.think()
    assert(ExpectAction(boss, "cast_no_target")[2] == blade, "punish concentrated attacks")
    boss.think()
    assert(ExpectAction(boss, "cast_no_target")[2] == shivas, "use the area slow on clustered heroes")
end

do
    local boss, target = Unit(0), Unit(150)
    local grab = Ability(200)
    boss.abilities.pudge_dismember = grab
    target.modifier = "modifier_item_lotus_orb_active"
    SpawnBoss("bador_pudge.lua", boss, { target })
    boss.think()
    ExpectAction(boss, "attack")
    target.modifier, target.untargetable = nil, true
    boss.think()
    assert(#boss.actions == 0 and grab.ready, "avoid invalid targeted casts")
    target.untargetable = false
    boss.think()
    assert(ExpectAction(boss, "cast_target")[3] == grab)
end

do
    local boss = Unit(0)
    boss.abilities.skill_pudge_meat_hook = Ability(700, 700)
    SpawnBoss("bador_pudge.lua", boss, { Unit(500) })
    boss.think()
    ExpectAction(boss, "stop")
    boss.paused = true
    boss.think()
    assert(#boss.actions == 0 and not boss.warnings[1].released)
    boss.state = 7
    assert(boss.think() == nil and boss.warnings[1].released)
end

do
    local boss, target = Unit(0), Unit(510)
    local urn = Ability(950)
    urn.charges = 3
    boss.health = 65
    boss.items.item_urn_of_shadows = urn
    boss.abilities.skill_pudge_meat_hook = Ability(700, 700)
    target.creep = true
    local enemies = { target }
    SpawnBoss("bador_pudge.lua", boss, enemies)
    boss.think()
    assert(ExpectAction(boss, "attack")[2] == target and urn.ready, "save the hook and urn charges on ordinary creeps")
    enemies[1], boss.target = nil, nil
    boss.think()
    local heal = ExpectAction(boss, "cast_target")
    assert(heal[2] == boss and heal[3] == urn, "recover at home after combat")
    urn.ready, urn.charges = true, 1
    boss.think()
    assert(#boss.actions == 0, "reserve the last charge")
end

do
    local boss, target = Unit(0), Unit(180)
    local enemies = {}
    SpawnBoss("samurai.lua", boss, enemies)
    boss.think()
    assert(#boss.actions == 0, "Samurai should stay at spawn when idle")

    enemies[1] = target
    boss.think()
    assert(ExpectAction(boss, "attack")[2] == target, "missing spells must not break basic attacks")

    local strafe = Ability(nil, nil, 4)
    boss.abilities.clinkz_strafe = strafe
    boss.think()
    assert(ExpectAction(boss, "cast_no_target")[2] == strafe)

    boss.position = Vector(1500)
    boss.think()
    assert(ExpectAction(boss, "move")[2].x == 0)
end

print("Gameplay scripts passed cooldown refresh, Bador targeting, prediction, flanking, counterplay, and Samurai leash checks")
