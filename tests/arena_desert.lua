-- The desert biome against a stubbed engine: its data files, every desert ability and modifier,
-- the boss's phases and moves, the shared brain using desert abilities, and loading the desert
-- ability script on its own the way the Dota client does.
-- Run from the repository root: lua5.1 tests/arena_desert.lua
--
-- What this proves: the desert's Lua, KV and data agree, and each move hits who it should and
-- spares who dodged. What it cannot prove: that the engine behaves like these stubs (particles,
-- knockback, burrowing visuals, sounds). See tools/biomes/README.md for in-game checks.

local VSCRIPTS = "game/angel_arena/scripts/vscripts/"
package.path = VSCRIPTS .. "?.lua;" .. package.path

------------------------------------------------------------------------------- constants

local CONSTANTS = {
    DOTA_TEAM_GOODGUYS = 2, DOTA_TEAM_BADGUYS = 3, DOTA_TEAM_NEUTRALS = 4,
    DOTA_GAMERULES_STATE_GAME_IN_PROGRESS = 5, DOTA_GAMERULES_STATE_POST_GAME = 6,
    DOTA_ABILITY_BEHAVIOR_HIDDEN = 1, DOTA_ABILITY_BEHAVIOR_PASSIVE = 2, DOTA_ABILITY_BEHAVIOR_NO_TARGET = 4,
    DOTA_ABILITY_BEHAVIOR_UNIT_TARGET = 8, DOTA_ABILITY_BEHAVIOR_POINT = 16, DOTA_ABILITY_BEHAVIOR_AOE = 32,
    DOTA_ABILITY_BEHAVIOR_CHANNELLED = 128, DOTA_ABILITY_BEHAVIOR_TOGGLE = 512,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY = 1, DOTA_UNIT_TARGET_TEAM_ENEMY = 2, DOTA_UNIT_TARGET_TEAM_BOTH = 3,
    DOTA_UNIT_TARGET_HERO = 1, DOTA_UNIT_TARGET_BASIC = 18, UF_SUCCESS = 0, DOTA_MAX_TEAM_PLAYERS = 24,
}
for key, value in pairs(CONSTANTS) do
    _G[key] = value
end
local nextConstant = 1000000
setmetatable(_G, { __index = function(globals, key)
    if type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
        nextConstant = nextConstant + 1
        rawset(globals, key, nextConstant)
        return nextConstant
    end
end })

bit = { band = function(a, b)
    local result, place = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then result = result + place end
        a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
    end
    return result
end }

local passed = 0
local function check(condition, message)
    if not condition then
        error("FAILED: " .. message, 2)
    end
    passed = passed + 1
end

local realPrint = print
function print() end

---------------------------------------------------------------------------------- vectors

local vector = {}
vector.__index = vector
function Vector(x, y, z) return setmetatable({ x = x or 0, y = y or 0, z = z or 0 }, vector) end
function vector.__add(a, b) return Vector(a.x + b.x, a.y + b.y, a.z + b.z) end
function vector.__sub(a, b) return Vector(a.x - b.x, a.y - b.y, a.z - b.z) end
function vector.__mul(a, b)
    if type(a) == "number" then a, b = b, a end
    return Vector(a.x * b, a.y * b, a.z * b)
end
function vector.__div(a, b) return Vector(a.x / b, a.y / b, a.z / b) end
function vector:Length2D() return math.sqrt(self.x * self.x + self.y * self.y) end
local function At(x, y) return Vector(x, y, 0) end
local function Distance(a, b) return (a - b):Length2D() end

------------------------------------------------------------------------------ KV reading

local function ReadKV(path)
    local file = assert(io.open(path, "rb"), "missing " .. path)
    local text = file:read("*a"):gsub("//[^\n]*", "")
    file:close()
    local position = 1
    local function token()
        local start, finish, quoted = text:find('^%s*"([^"]*)"', position)
        if start then
            position = finish + 1
            return quoted
        end
        start, finish, quoted = text:find("^%s*([{}])", position)
        if start then
            position = finish + 1
            return quoted, true
        end
    end
    local function block()
        local result = {}
        while true do
            local key, brace = token()
            if not key or (brace and key == "}") then return result end
            local value, opens = token()
            if opens then value = block() end
            if result[key] == nil then result[key] = value end
        end
    end
    token()
    token()
    return block()
end

local UNIT_KV = ReadKV("game/angel_arena/scripts/npc/units/arena/arena_desert_units.txt")
local ABILITY_KV = ReadKV("game/angel_arena/scripts/npc/abilities/arena/arena_desert_abilities.txt")

local function Flags(text)
    local total = 0
    for name in tostring(text or ""):gmatch("[%w_]+") do
        total = total + (_G[name] or 0)
    end
    return total
end

------------------------------------------------------------------------------ the world

local now = 0
local server = true
local world = {}
local created = {}
local orders = {}
local damage = {}
local particles = {}
local controls = {}
local destroyed = {}
local notifications = {}

function IsServer() return server end
function class(definition) return definition end
function IsValidEntity(entity) return entity ~= nil and not entity.removed end
function UTIL_Remove(entity)
    entity.removed = true
    entity.alive = false
    world[entity] = nil
end
function RandomInt(low) return low end
function RandomFloat(low, high) return high end
function RandomVector(length) return Vector(length, 0, 0) end
function GetGroundPosition(position) return position end
function EmitGlobalSound() end
function EmitSoundOnLocationWithCaster() end
function AddFOWViewer() end
function ApplyDamage(info) damage[#damage + 1] = info end
function UnitFilter() return UF_SUCCESS end
function FindClearSpaceForUnit(unit, position) unit.origin = position end
Notifications = { TopToAll = function(_, data) notifications[#notifications + 1] = data end }
Timers = { CreateTimer = function() end }

local linked = {}
function LinkLuaModifier(name, path) linked[name] = path end

local particleId = 0
ParticleManager = {
    CreateParticle = function(_, name)
        particleId = particleId + 1
        particles[particleId] = name
        return particleId
    end,
    SetParticleControl = function(_, index, point, value) controls[index] = controls[index] or {}; controls[index][point] = value end,
    ReleaseParticleIndex = function() end,
    DestroyParticle = function(_, index) destroyed[index] = true end,
}
local function Count(name)
    local count = 0
    for _, particle in pairs(particles) do
        if particle == name then count = count + 1 end
    end
    return count
end
local function Last(name)
    local found
    for index, particle in pairs(particles) do
        if particle == name and (not found or index > found) then found = index end
    end
    return found
end

GameRules = {
    State_Get = function() return DOTA_GAMERULES_STATE_GAME_IN_PROGRESS end,
    GetDOTATime = function() return now end,
    GetGameTime = function() return now end,
    IsGamePaused = function() return false end,
}

-------------------------------------------------------------------------------- modifiers

local Modifier = {}
function Modifier:GetParent() return self.parent end
function Modifier:GetCaster() return self.caster end
function Modifier:GetAbility() return self.ability end
function Modifier:GetDuration() return self.duration or -1 end
function Modifier:GetStackCount() return self.stacks or 0 end
function Modifier:SetStackCount(count) self.stacks = count end
function Modifier:IsNull() return self.destroyed == true end
function Modifier:StartIntervalThink(interval) self.interval = interval end
function Modifier:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    if self.parent.modifiers[self.name] == self then self.parent.modifiers[self.name] = nil end
    if self.OnDestroy then self:OnDestroy() end
end

local function MakeModifier(parent, caster, ability, name, data)
    local definition = rawget(_G, name)
    return setmetatable({ name = name, parent = parent, caster = caster, ability = ability, data = data,
        duration = data and data.duration }, { __index = function(_, key)
            if definition and definition[key] ~= nil then return definition[key] end
            return Modifier[key]
        end })
end

-------------------------------------------------------------------------------- abilities

local Ability = {}
local function PerLevel(text, level)
    local values = {}
    for number in tostring(text):gmatch("%S+") do values[#values + 1] = tonumber(number) end
    return values[math.min(math.max(level, 1), #values)] or 0
end
function Ability:GetAbilityName() return self.name end
function Ability:GetLevel() return self.level end
function Ability:SetLevel(level) self.level = level end
function Ability:GetMaxLevel() return tonumber(self.kv.MaxLevel or 1) end
function Ability:GetBehaviorInt() return Flags(self.kv.AbilityBehavior) end
function Ability:GetAbilityTargetTeam() return Flags(self.kv.AbilityUnitTargetTeam) end
function Ability:GetAbilityTargetType() return Flags(self.kv.AbilityUnitTargetType) end
function Ability:GetAbilityTargetFlags() return 0 end
function Ability:IsHidden() return false end
function Ability:IsNull() return false end
function Ability:GetCaster() return self.unit end
function Ability:IsFullyCastable() return self.level > 0 and now >= (self.readyAt or 0) end
function Ability:IsCooldownReady() return now >= (self.readyAt or 0) end
function Ability:IsInAbilityPhase() return false end
function Ability:GetCastRange() return tonumber(self.kv.AbilityCastRange or 0) end
function Ability:GetCastPoint() return tonumber(self.kv.AbilityCastPoint or 0) end
function Ability:GetSpecialValueFor(key)
    local values = self.kv.AbilityValues or {}
    if values[key] == nil then return 0 end
    return PerLevel(values[key], self.level)
end
function Ability:GetCursorTarget() return self.cursorTarget end
function Ability:GetCursorPosition() return self.cursorPosition end

local function MakeAbility(unit, name)
    local definition = rawget(_G, name)
    return setmetatable({ name = name, unit = unit, level = 0, kv = assert(ABILITY_KV[name], name) },
        { __index = function(_, key)
            if Ability[key] ~= nil then return Ability[key] end
            return definition and definition[key]
        end })
end

------------------------------------------------------------------------------------ units

local Unit = {}
local nextIndex = 100
function Unit:GetUnitName() return self.name end
function Unit:GetAbsOrigin() return self.origin end
function Unit:SetAbsOrigin(position) self.origin = position end
function Unit:GetTeamNumber() return self.team end
function Unit:IsAlive() return self.alive end
function Unit:IsNull() return self.removed == true end
function Unit:GetHealth() return self.health end
function Unit:GetMaxHealth() return self.maxHealth end
function Unit:SetHealth(value) self.health = math.min(value, self.maxHealth) end
function Unit:SetMaxHealth(value) self.maxHealth = value end
function Unit:SetBaseMaxHealth() end
function Unit:SetBaseDamageMin(value) self.damage = value end
function Unit:SetBaseDamageMax() end
function Unit:SetPhysicalArmorBaseValue(value) self.armor = value end
function Unit:SetMinimumGoldBounty() end
function Unit:SetMaximumGoldBounty() end
function Unit:SetDeathXP() end
function Unit:IsBuilding() return false end
function Unit:TriggerSpellAbsorb() return false end
function Unit:PassivesDisabled() return false end
function Unit:IsStunned() return self.modifiers.modifier_stunned ~= nil end
function Unit:IsHexed() return false end
function Unit:IsCommandRestricted()
    for _, modifier in pairs(self.modifiers) do
        if modifier.CheckState and modifier:CheckState()[MODIFIER_STATE_COMMAND_RESTRICTED] then return true end
    end
    return false
end
function Unit:IsChanneling() return false end
function Unit:IsSilenced() return false end
function Unit:IsMuted() return false end
function Unit:GetCurrentActiveAbility() return nil end
function Unit:CanEntityBeSeenByMyTeam() return true end
function Unit:GetForwardVector() return Vector(1, 0, 0) end
function Unit:EmitSound() end
function Unit:StopSound(name) self.stopped = name end
function Unit:AddNoDraw() self.hidden = true end
function Unit:RemoveNoDraw() self.hidden = false end
function Unit:GetAttackTarget() return self.attackTarget end
function Unit:SetContextThink(name, callback) self.thinks[name] = callback end
function Unit:ForceKill() self.alive = false; world[self] = nil end
function Unit:Stop() orders[#orders + 1] = { unit = self, kind = "stop" } end
function Unit:MoveToPosition(position) orders[#orders + 1] = { unit = self, kind = "move", target = position } end
function Unit:MoveToTargetToAttack(target)
    self.attackTarget = target
    orders[#orders + 1] = { unit = self, kind = "attack", target = target }
end
local function Cast(unit, kind, ability, target)
    ability.readyAt = now + 5
    orders[#orders + 1] = { unit = unit, kind = kind, ability = ability:GetAbilityName(), target = target }
end
function Unit:CastAbilityNoTarget(ability) Cast(self, "cast", ability) end
function Unit:CastAbilityOnTarget(target, ability) Cast(self, "cast_target", ability, target) end
function Unit:CastAbilityOnPosition(position, ability) Cast(self, "cast_point", ability, position) end
function Unit:GetAbilityCount() return 16 end
function Unit:GetAbilityByIndex(index) return self.abilities[index + 1] end
function Unit:FindAbilityByName(name)
    for _, ability in ipairs(self.abilities) do
        if ability.name == name then return ability end
    end
end
function Unit:RemoveAbility() end
function Unit:AddNewModifier(caster, ability, name, data)
    local old = self.modifiers[name]
    if old and not old.destroyed then
        old.duration = data and data.duration or old.duration
        old.data = data
        if old.OnRefresh then old:OnRefresh(data or {}) end
        return old
    end
    local modifier = MakeModifier(self, caster, ability, name, data)
    self.modifiers[name] = modifier
    if modifier.OnCreated then modifier:OnCreated(data or {}) end
    return modifier
end
function Unit:HasModifier(name) return self.modifiers[name] ~= nil end
function Unit:FindModifierByName(name) return self.modifiers[name] end
function Unit:RemoveModifierByName(name)
    local modifier = self.modifiers[name]
    if modifier then modifier:Destroy() end
end

local function MakeUnit(name, position, team, options)
    options = options or {}
    nextIndex = nextIndex + 1
    local unit = setmetatable({ name = name, origin = position, team = team, alive = true, index = nextIndex,
        health = options.health or 1000, maxHealth = options.health or 1000, hero = options.hero,
        modifiers = {}, abilities = {}, thinks = {}, thinker = options.thinker }, { __index = Unit })
    world[unit] = true
    return unit
end

local function Hero(team, position)
    return MakeUnit("npc_dota_hero_axe", position, team, { hero = true, health = 2000 })
end

function CreateUnitByName(name, position, _, _, _, team)
    local kv = UNIT_KV[name]
    if not kv then return nil end
    local unit = MakeUnit(name, position, team)
    for slot = 1, 8 do
        local ability = kv["Ability" .. slot]
        if ability then unit.abilities[#unit.abilities + 1] = MakeAbility(unit, ability) end
    end
    for _, ability in ipairs(unit.abilities) do
        if ability.GetIntrinsicModifierName then
            unit:AddNewModifier(unit, ability, ability:GetIntrinsicModifierName(), {})
        end
    end
    created[#created + 1] = unit
    return unit
end

function CreateModifierThinker(caster, ability, name, data, position, team)
    local thinker = MakeUnit("npc_dota_thinker", position, team, { thinker = true })
    thinker:AddNewModifier(caster, ability, name, data)
    return thinker
end

local function Matches(unit, team, filter, types)
    if unit.thinker or not unit.alive then return false end
    if filter == DOTA_UNIT_TARGET_TEAM_ENEMY and unit.team == team then return false end
    if filter == DOTA_UNIT_TARGET_TEAM_FRIENDLY and unit.team ~= team then return false end
    if unit.hero then return bit.band(types, DOTA_UNIT_TARGET_HERO) ~= 0 end
    return bit.band(types, DOTA_UNIT_TARGET_BASIC) ~= 0
end

function FindUnitsInRadius(team, origin, _, radius, filter, types)
    local found = {}
    for unit in pairs(world) do
        if Matches(unit, team, filter, types) and Distance(unit.origin, origin) <= radius then
            found[#found + 1] = unit
        end
    end
    table.sort(found, function(a, b) return Distance(a.origin, origin) < Distance(b.origin, origin) end)
    return found
end

function FindUnitsInLine(team, from, to, _, width, filter, types)
    local found = {}
    local line = to - from
    local length = line:Length2D()
    for unit in pairs(world) do
        if Matches(unit, team, filter, types) then
            local offset = unit.origin - from
            local along = (offset.x * line.x + offset.y * line.y) / length
            local across = math.abs(offset.x * line.y - offset.y * line.x) / length
            if along >= 0 and along <= length and across <= width then
                found[#found + 1] = unit
            end
        end
    end
    return found
end

local function Strikes()
    local list = {}
    for unit in pairs(world) do
        if unit.thinker and unit.modifiers.modifier_arena_delayed_strike then list[#list + 1] = unit end
    end
    table.sort(list, function(a, b) return a.index < b.index end)
    return list
end
local function ClearStrikes()
    for _, thinker in ipairs(Strikes()) do UTIL_Remove(thinker) end
end
local function Land(thinker) thinker.modifiers.modifier_arena_delayed_strike:Destroy() end
local function Hits(victim)
    local list = {}
    for _, info in ipairs(damage) do
        if info.victim == victim then list[#list + 1] = info.damage end
    end
    return list
end
local function Clear(unit)
    for name, modifier in pairs(unit.modifiers) do
        if not name:find("^modifier_arena_desert_withering_venom") and not name:find("caustic_sting") then
            unit.modifiers[name] = nil
            modifier.destroyed = true
        end
    end
end

local function Spawn(name, position, level)
    local unit = CreateUnitByName(name, position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    for _, ability in ipairs(unit.abilities) do ability:SetLevel(level or 1) end
    return unit
end

------------------------------------------------------------------------ load the scripts

require("arena/index")
dofile(VSCRIPTS .. "arena/biomes/desert/abilities.lua")

-------------------------------------------------------------------- data files agree

local biomes = ArenaBiomes.Load()
local desert = biomes.desert
check(#desert.problems == 0, "desert files pass validation: " .. table.concat(desert.problems, "; "))
check(desert.monsters and desert.boss and desert.fx, "desert has monsters, a boss and effects")
for name, definition in pairs(ABILITY_KV) do
    check(type(rawget(_G, name)) == "table", name .. " is defined in the desert ability script")
    check(definition.ScriptFile == "arena/biomes/desert/abilities.lua", name .. " points at the desert ability script")
end
for name, stats in pairs(desert.monsters.monsters) do
    local kv = UNIT_KV[name]
    check(kv ~= nil, name .. " has a unit definition")
    for ability in pairs(stats.ai or {}) do
        local has = false
        for slot = 1, 8 do has = has or kv["Ability" .. slot] == ability end
        check(has, name .. " has the ability its ai hint names: " .. ability)
    end
end
for tier = 1, 4 do
    check(#desert.monsters.tiers[tier] >= 3, "tier " .. tier .. " has at least three groups")
    for _, group in ipairs(desert.monsters.tiers[tier]) do
        local leader = UNIT_KV[group[1]]
        check(tier < 3 or leader.Ability1 ~= nil, "tier " .. tier .. " leader " .. group[1] .. " has an ability")
    end
end
for _, group in ipairs(desert.monsters.tiers[1]) do
    for _, name in ipairs(group) do check(UNIT_KV[name].Ability1 == nil, "easy monsters have no abilities: " .. name) end
end
local bossKV = UNIT_KV[desert.boss.unit]
for index, spec in ipairs(desert.boss.abilities) do
    check(bossKV["Ability" .. index] == spec.name, "boss.lua lists " .. spec.name .. " in the unit's slot order")
    check(tonumber(ABILITY_KV[spec.name].MaxLevel) == #desert.boss.phases, spec.name .. " has one level per phase")
end
for _, name in ipairs({ "modifier_arena_desert_blinded", "modifier_arena_desert_sunk", "modifier_arena_desert_burrowed",
    "modifier_arena_desert_withering", "modifier_arena_desert_sun_brand", "modifier_arena_desert_heat_shimmer",
    "modifier_arena_desert_quicksand", "modifier_arena_desert_sinking", "modifier_arena_desert_sandstorm",
    "modifier_arena_desert_caustic", "modifier_arena_desert_caustic_sting", "modifier_arena_desert_withering_venom" }) do
    check(linked[name] == "arena/biomes/desert/abilities.lua", name .. " is linked from the desert ability script")
end

-------------------------------------------------------------------------- monster moves

now = 100
local FX = desert.fx

-- Ambush: burrows, rings the prey's spot, bursts up there.
local lurker = Spawn("npc_arena_desert_oasis_lurker", At(0, 0), 2)
local prey = Hero(DOTA_TEAM_GOODGUYS, At(500, 0))
local ambush = lurker:FindAbilityByName("arena_desert_ambush")
ambush.cursorTarget = prey
ambush:OnSpellStart()
check(lurker.hidden and lurker:HasModifier("modifier_arena_desert_burrowed") and lurker:IsCommandRestricted(),
    "ambush: the lurker vanishes under the sand and takes no orders")
check(lurker.modifiers.modifier_arena_desert_burrowed:CheckState()[MODIFIER_STATE_INVULNERABLE], "ambush: it cannot be hit while under")
local strike = Strikes()[1]
check(strike and Distance(strike.origin, At(500, 0)) == 0 and strike.modifiers.modifier_arena_delayed_strike.duration == 1.0
    and strike.modifiers.modifier_arena_delayed_strike.data.radius == 225, "ambush: a 225 ring marks the prey's spot for 1 second")
damage = {}
Land(strike)
check(Distance(lurker.origin, At(500, 0)) == 0 and not lurker.hidden and not lurker:HasModifier("modifier_arena_desert_burrowed"),
    "ambush: the lurker bursts up on the marked spot")
check(Hits(prey)[1] == 130 and prey.modifiers.modifier_stunned.duration == 0.6, "ambush: whoever stayed is hurt and stunned")
Clear(prey)
lurker.origin = At(0, 0)
ambush:OnSpellStart()
prey.origin = At(500, 300)
damage = {}
Land(Strikes()[1])
check(#Hits(prey) == 0 and not prey:HasModifier("modifier_stunned"), "ambush: stepping out of the ring dodges it")

-- Dust Kick: a line during the wind-up, then damage and blindness on it.
local outrider = Spawn("npc_arena_desert_dust_outrider", At(0, 2000), 3)
local kick = outrider:FindAbilityByName("arena_desert_dust_kick")
local onLine, offLine = Hero(DOTA_TEAM_GOODGUYS, At(400, 2000)), Hero(DOTA_TEAM_GOODGUYS, At(400, 2400))
kick.cursorPosition = At(300, 2000)
local lines = Count(ArenaFxCore.PARTICLES.line)
check(kick:OnAbilityPhaseStart() == true and Count(ArenaFxCore.PARTICLES.line) == lines + 1, "dust kick: the wind-up draws its line")
local warning = kick.warning
kick:OnAbilityPhaseInterrupted()
check(destroyed[warning] and kick.warning == nil, "dust kick: an interrupted kick removes its line")
kick:OnAbilityPhaseStart()
warning = kick.warning
damage = {}
kick:OnSpellStart()
check(destroyed[warning], "dust kick: the line goes when the kick lands")
check(Hits(onLine)[1] == 125 and onLine.modifiers.modifier_arena_desert_blinded:GetModifierMiss_Percentage() == 40
    and onLine.modifiers.modifier_arena_desert_blinded.duration == 3, "dust kick: the line is hurt and blinded")
check(#Hits(offLine) == 0 and not offLine:HasModifier("modifier_arena_desert_blinded"), "dust kick: off the line is safe")

-- Withering Venom: stacking doses that burn and slow.
local basilisk = Spawn("npc_arena_desert_sandscale_basilisk", At(0, 4000), 2)
local fangs = basilisk.modifiers.modifier_arena_desert_withering_venom
check(fangs and fangs:IsHidden(), "withering venom works through a hidden intrinsic modifier")
local bitten = Hero(DOTA_TEAM_GOODGUYS, At(100, 4000))
for _ = 1, 7 do fangs:OnAttackLanded({ attacker = basilisk, target = bitten }) end
local venom = bitten.modifiers.modifier_arena_desert_withering
check(venom:GetStackCount() == 5 and venom.duration == 4, "withering venom: doses stack up to the level's maximum")
check(venom:GetModifierMoveSpeedBonus_Percentage() == -20 and venom:OnTooltip() == 45, "withering venom: each dose slows and burns more")
damage = {}
venom:OnIntervalThink()
check(Hits(bitten)[1] == 45, "withering venom: it burns every second for each dose")
fangs:OnAttackLanded({ attacker = basilisk, target = basilisk })
check(not basilisk:HasModifier("modifier_arena_desert_withering"), "withering venom: never on its own side")

-- Sun Brand: the bearer's ring is the blast; friends nearby are hit too, far ones are not.
local priest = Spawn("npc_arena_desert_sun_priest", At(0, 6000), 1)
local brandAbility = priest:FindAbilityByName("arena_desert_sun_brand")
local bearer, friend, apart = Hero(DOTA_TEAM_GOODGUYS, At(500, 6000)), Hero(DOTA_TEAM_GOODGUYS, At(700, 6000)), Hero(DOTA_TEAM_GOODGUYS, At(900, 6000))
brandAbility.cursorTarget = bearer
local rings = Count(FX.particles.danger_ring)
brandAbility:OnSpellStart()
local mark = bearer.modifiers.modifier_arena_desert_sun_brand
check(mark and mark.duration == 2.5 and Count(FX.particles.danger_ring) == rings + 1, "sun brand: a 2.5 second brand with a ring around the bearer")
check(controls[Last(FX.particles.danger_ring)][1].x == 300 and mark:OnTooltip() == 300, "sun brand: the ring is the blast radius")
bearer.origin = At(550, 6000)
damage = {}
mark:Destroy()
check(Hits(bearer)[1] == 110 and Hits(friend)[1] == 110 and #Hits(apart) == 0, "sun brand: it strikes around where the bearer ends up")
brandAbility:OnSpellStart()
priest.alive = false
damage = {}
bearer.modifiers.modifier_arena_desert_sun_brand:Destroy()
check(#damage == 0, "sun brand: a dead priest's brand fizzles")
priest.alive = true

-- Heat Shimmer: allies around the priest become hard to hit.
local shimmerAbility = priest:FindAbilityByName("arena_desert_heat_shimmer")
shimmerAbility:SetLevel(2)
local escort = Spawn("npc_arena_desert_dust_outrider", At(300, 6000), 1)
shimmerAbility:OnSpellStart()
check(escort.modifiers.modifier_arena_desert_heat_shimmer:GetModifierEvasion_Constant() == 30
    and priest:HasModifier("modifier_arena_desert_heat_shimmer") and not bearer:HasModifier("modifier_arena_desert_heat_shimmer"),
    "heat shimmer: the priest and its allies gain evasion, enemies do not")

-- Quicksand: sinking stacks, then held fast; leaving early is safe.
local behemoth = Spawn("npc_arena_desert_dune_behemoth", At(0, 8000), 3)
local quicksand = behemoth:FindAbilityByName("arena_desert_quicksand")
quicksand.cursorPosition = At(400, 8000)
quicksand:OnSpellStart()
local pitThinker
for unit in pairs(world) do
    if unit.thinker and unit.modifiers.modifier_arena_desert_quicksand then pitThinker = unit end
end
local pit = pitThinker.modifiers.modifier_arena_desert_quicksand
check(pit.interval == 0.5 and pit.duration == 6, "quicksand: a six second pit that works every half second")
local stuck = Hero(DOTA_TEAM_GOODGUYS, At(450, 8000))
damage = {}
for _ = 1, 4 do pit:OnIntervalThink() end
check(stuck.modifiers.modifier_arena_desert_sinking:GetStackCount() == 4
    and stuck.modifiers.modifier_arena_desert_sinking:GetModifierMoveSpeedBonus_Percentage() == -40, "quicksand: each half second sinks deeper")
check(Hits(stuck)[1] == 32.5, "quicksand: the pit burns half its damage per second each half second")
pit:OnIntervalThink()
check(stuck:HasModifier("modifier_arena_desert_sunk") and stuck.modifiers.modifier_arena_desert_sunk.duration == 1.2
    and not stuck:HasModifier("modifier_arena_desert_sinking"), "quicksand: sunk all the way, the sand holds the hero")
check(stuck.modifiers.modifier_arena_desert_sunk:CheckState()[MODIFIER_STATE_ROOTED], "quicksand: held means rooted")
pit:OnIntervalThink()
check(not stuck:HasModifier("modifier_arena_desert_sinking"), "quicksand: no new sinking while held")
stuck.origin = At(900, 8000)
Clear(stuck)
pit:OnIntervalThink()
check(not stuck:HasModifier("modifier_arena_desert_sinking"), "quicksand: outside the pit nothing happens")
pit:Destroy()
check(pitThinker.removed, "quicksand: the pit cleans up after itself")

-- Dune Slam: a ring during the wind-up, then damage and a throw outward.
local slam = behemoth:FindAbilityByName("arena_desert_dune_slam")
local circles = Count(ArenaFxCore.PARTICLES.circle)
check(slam:OnAbilityPhaseStart() == true and Count(ArenaFxCore.PARTICLES.circle) == circles + 1, "dune slam: the wind-up draws its ring")
local near = Hero(DOTA_TEAM_GOODGUYS, At(200, 8000))
stuck.origin = At(600, 8000)
damage = {}
slam:OnSpellStart()
local throw = near.modifiers.modifier_knockback
check(Hits(near)[1] == 300 and throw and throw.data.center_x == 0 and throw.data.knockback_distance == 250 and throw.data.should_stun == 1,
    "dune slam: those inside are hurt and thrown away from the behemoth")
check(#Hits(stuck) == 0, "dune slam: those outside the ring are safe")

-- Sandstorm: scours and blinds around the khan while it lasts.
local khan = Spawn("npc_arena_desert_storm_khan", At(0, 10000), 3)
local stormAbility = khan:FindAbilityByName("arena_desert_sandstorm")
stormAbility:OnSpellStart()
local storm = khan.modifiers.modifier_arena_desert_sandstorm
check(storm and storm.duration == 5 and storm.interval == 0.5 and storm:OnTooltip() == 450, "sandstorm: a five second storm around the khan")
local caught, clear = Hero(DOTA_TEAM_GOODGUYS, At(300, 10000)), Hero(DOTA_TEAM_GOODGUYS, At(600, 10000))
damage = {}
storm:OnIntervalThink()
check(Hits(caught)[1] == 40 and caught.modifiers.modifier_arena_desert_blinded:GetModifierMiss_Percentage() == 35
    and #Hits(clear) == 0, "sandstorm: inside is hurt and blinded, outside is not")
storm:Destroy()
check(khan.stopped == FX.sounds.sandstorm_loop, "sandstorm: the storm's sound stops with it")

-- Sirocco Gust: the line is drawn first, then everyone on it is hurt and thrown back.
local gust = khan:FindAbilityByName("arena_desert_sirocco_gust")
gust.cursorPosition = At(0, 10500)
gust:OnAbilityPhaseStart()
local onGust = Hero(DOTA_TEAM_GOODGUYS, At(0, 10600))
Clear(caught)
damage = {}
gust:OnSpellStart()
check(Hits(onGust)[1] == 240 and onGust.modifiers.modifier_knockback.data.knockback_distance == 350 and #Hits(caught) == 0,
    "sirocco gust: the line is hurt and thrown, the side is not")

------------------------------------------------------------------------------ the boss

ArenaBosses.states = {}
local state = { biome = "desert", def = desert.boss, origin = At(20000, 0), generation = 0, nextSpawn = 0, adds = {} }
local boss = ArenaBosses:Spawn(state, now)
check(boss and boss.name == "npc_arena_desert_boss" and boss.maxHealth == 52000, "the Sunken King rises with its stats")
local function Level(name) return boss:FindAbilityByName(name):GetLevel() end
check(Level("arena_desert_boss_caustic_venom") == 1 and Level("arena_desert_boss_undermine") == 1 and Level("arena_desert_boss_sirocco") == 1
    and Level("arena_desert_boss_sun_brand") == 0 and Level("arena_desert_boss_dune_collapse") == 0, "phase 1: venom, undermine and sirocco")

-- The brain: sirocco on a hero in reach, then (locked) attacks, then undermine.
local tank = Hero(DOTA_TEAM_GOODGUYS, At(20200, 0))
state.brain.provoker, state.brain.provokedAt = tank, now
boss.thinks.ArenaMonsterAI()
local order = orders[#orders]
check(order.unit == boss and order.kind == "cast_point" and order.ability == "arena_desert_boss_undermine"
    and Distance(order.target, tank.origin) == 0, "the brain sends Undermine at the hero's spot")
check(state.brain.lockUntil == now + 2.0, "undermine locks the next cast while its ring is on the ground")
now = now + 2.1
boss.thinks.ArenaMonsterAI()
order = orders[#orders]
check(order.kind == "cast" and order.ability == "arena_desert_boss_sirocco", "then Sirocco once the lock is over")

boss.health = boss.maxHealth * 0.6
now = now + 3
boss.thinks.ArenaMonsterAI()
check(state.phase == 2 and Level("arena_desert_boss_sun_brand") == 2 and Level("arena_desert_boss_sirocco") == 2
    and Level("arena_desert_boss_dune_collapse") == 0, "phase 2 below 65%: the brand joins, sirocco grows")
check(orders[#orders].ability == "arena_desert_boss_sun_brand", "phase 2 opens with the brand")
boss.health = boss.maxHealth * 0.25
now = now + 3
boss.thinks.ArenaMonsterAI()
check(state.phase == 3 and Level("arena_desert_boss_dune_collapse") == 3, "phase 3 below 30%: the temple collapses")
check(orders[#orders].ability == "arena_desert_boss_dune_collapse", "phase 3 opens with the collapse")

-- Caustic Venom: a ring one dose early, then a burst over the tank's neighbours.
local sting = boss.modifiers.modifier_arena_desert_caustic_sting
local neighbour, loner = Hero(DOTA_TEAM_GOODGUYS, At(20400, 0)), Hero(DOTA_TEAM_GOODGUYS, At(20900, 0))
rings = Count(FX.particles.danger_ring)
for _ = 1, 3 do sting:OnAttackLanded({ attacker = boss, target = tank }) end
local dose = tank.modifiers.modifier_arena_desert_caustic
check(dose:GetStackCount() == 3 and dose.ring and Count(FX.particles.danger_ring) == rings + 1,
    "caustic venom: one dose short of bursting, a ring warns everyone near the tank")
local doseRing = dose.ring
damage = {}
dose:OnIntervalThink()
check(Hits(tank)[1] == 105, "caustic venom: each dose burns every second")
damage = {}
sting:OnAttackLanded({ attacker = boss, target = tank })
check(Hits(tank)[1] == 600 and Hits(neighbour)[1] == 600 and #Hits(loner) == 0 and not tank:HasModifier("modifier_arena_desert_caustic")
    and destroyed[doseRing], "caustic venom: the burst hits the tank and whoever stood in the ring")

-- Undermine: burrow, ring, erupt where the hero stood.
local undermine = boss:FindAbilityByName("arena_desert_boss_undermine")
local wearable = { effects = 0, IsNull = function() return false end, GetClassname = function() return "dota_item_wearable" end }
function wearable:AddEffects(flag) self.effects = self.effects + flag end
function wearable:RemoveEffects(flag) self.effects = self.effects - flag end
boss.GetChildren = function() return { wearable } end
ClearStrikes()
undermine.cursorPosition = At(20600, 0)
undermine:OnSpellStart()
check(boss.hidden and boss.modifiers.modifier_arena_desert_burrowed, "undermine: the king sinks out of reach")
check(wearable.effects == 32, "undermine: its head, claws and tail sink with it")
strike = Strikes()[1]
check(strike.modifiers.modifier_arena_delayed_strike.duration == 1.4 and strike.modifiers.modifier_arena_delayed_strike.data.radius == 325,
    "undermine: a phase 3 ring of 325 for 1.4 seconds")
neighbour.origin = At(20650, 0)
Clear(neighbour)
damage = {}
Land(strike)
check(Distance(boss.origin, At(20600, 0)) == 0 and not boss.hidden and Hits(neighbour)[1] == 800
    and neighbour.modifiers.modifier_stunned.duration == 1.4, "undermine: it erupts on the ring, hurting and stunning")
check(wearable.effects == 0, "undermine: its wearables come back up with it")

-- Sirocco: one line per nearby hero up to the phase's count; on it you are shoved and blinded.
ClearStrikes()
local sirocco = boss:FindAbilityByName("arena_desert_boss_sirocco")
for unit in pairs(world) do
    if unit.hero then unit.origin = At(-50000, 0) end
end
local runnerA, runnerB = Hero(DOTA_TEAM_GOODGUYS, At(20600 + 400, 0)), Hero(DOTA_TEAM_GOODGUYS, At(20600, 500))
local bystander = Hero(DOTA_TEAM_GOODGUYS, At(20600 - 450, -450))
sirocco:SetLevel(2)
sirocco:OnSpellStart()
local gusts = Strikes()
check(#gusts == 2 and gusts[1].modifiers.modifier_arena_delayed_strike.data.shape == "line"
    and gusts[1].modifiers.modifier_arena_delayed_strike.duration == 1.3, "sirocco: two lines in phase 2, one toward each of the nearest heroes")
damage = {}
for _, thinker in ipairs(gusts) do Land(thinker) end
check(Hits(runnerA)[1] == 450 and Hits(runnerB)[1] == 450 and #Hits(bystander) == 0, "sirocco: the lines hit only who stayed on them")
check(runnerA.modifiers.modifier_knockback.data.center_x == 20600 and runnerA.modifiers.modifier_arena_desert_blinded:GetModifierMiss_Percentage() == 50,
    "sirocco: they are thrown away from the king and blinded")

-- Brand of the Sun: every hero nearby is branded at once.
local bossBrand = boss:FindAbilityByName("arena_desert_boss_sun_brand")
Clear(runnerA); Clear(runnerB); Clear(bystander)
runnerA.origin, runnerB.origin, bystander.origin = At(20900, 0), At(20900, 100), At(20600, -700)
bossBrand:OnSpellStart()
check(runnerA:HasModifier("modifier_arena_desert_sun_brand") and runnerB:HasModifier("modifier_arena_desert_sun_brand")
    and bystander:HasModifier("modifier_arena_desert_sun_brand") and runnerA.modifiers.modifier_arena_desert_sun_brand.duration == 2.6,
    "brand of the sun: every hero nearby is branded")
damage = {}
for _, hero in ipairs({ runnerA, runnerB, bystander }) do hero.modifiers.modifier_arena_desert_sun_brand:Destroy() end
check(#Hits(runnerA) == 2 and #Hits(runnerB) == 2 and #Hits(bystander) == 1 and Hits(bystander)[1] == 550,
    "brand of the sun: heroes standing together take each other's blasts; one apart takes only its own")

-- Dune Collapse: rings under every hero plus scattered ones; the sand holds whoever stays.
ClearStrikes()
local collapse = boss:FindAbilityByName("arena_desert_boss_dune_collapse")
collapse:OnSpellStart()
local falls = Strikes()
check(#falls == 3 + 8 and falls[1].modifiers.modifier_arena_delayed_strike.duration == 2, "dune collapse: a ring under each hero and eight around the lair")
Clear(runnerA)
damage = {}
for _, thinker in ipairs(falls) do Land(thinker) end
check(Hits(runnerA)[1] == 650 and runnerA.modifiers.modifier_arena_desert_sunk.duration == 1.5, "dune collapse: the sand crushes and holds")
ClearStrikes()
collapse:OnSpellStart()
boss.alive = false
damage = {}
for _, thinker in ipairs(Strikes()) do Land(thinker) end
check(#damage == 0, "dune collapse: a dead king's collapse fizzles")
boss.alive = true

-- The lurker's brain dives only at heroes that keep their distance.
now = now + 100
local hunter = Spawn("npc_arena_desert_oasis_lurker", At(-30000, 0), 1)
ArenaCamps:SetupMonster(hunter, nil, desert.monsters.monsters.npc_arena_desert_oasis_lurker, 0, 1, nil, { tier = 2 })
local close = Hero(DOTA_TEAM_BADGUYS, At(-30000 + 150, 0))
hunter.arenaBrain.provoker, hunter.arenaBrain.provokedAt = close, now
ArenaMonsterAI.Think(hunter.arenaBrain)
check(orders[#orders].kind == "attack", "the lurker bites a hero in reach instead of diving")
close.origin = At(-30000 + 500, 0)
hunter.attackTarget = nil
ArenaMonsterAI.Think(hunter.arenaBrain)
check(orders[#orders].kind == "cast_target" and orders[#orders].ability == "arena_desert_ambush", "...and ambushes one that keeps away")

-------------------------------------------- the client loads the ability script on its own

local function ClientSandbox()
    local env = { links = {} }
    local loaded = {}
    env._G = env
    for _, name in ipairs({ "pairs", "ipairs", "type", "tostring", "tonumber", "math", "string", "table", "error",
        "assert", "select", "setmetatable", "getmetatable", "rawget", "rawset", "next", "pcall", "unpack", "bit", "print", "Vector" }) do
        env[name] = _G[name]
    end
    env.class = function(definition) return definition end
    env.IsServer = function() return false end
    env.LinkLuaModifier = function(name, path) env.links[name] = path end
    setmetatable(env, { __index = function(globals, key)
        if type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
            rawset(globals, key, 7)
            return 7
        end
    end })
    env.require = function(name)
        if loaded[name] == nil then
            local chunk = assert(loadfile(VSCRIPTS .. name .. ".lua"))
            setfenv(chunk, env)
            loaded[name] = chunk() or true
        end
        return loaded[name]
    end
    return env
end

local env = ClientSandbox()
local chunk = assert(loadfile(VSCRIPTS .. "arena/biomes/desert/abilities.lua"))
setfenv(chunk, env)
local ok, message = pcall(chunk)
check(ok, "the desert ability script loads on the client by itself: " .. tostring(message))
local clientCount = 0
for name, path in pairs(env.links) do
    if path == "arena/biomes/desert/abilities.lua" then
        clientCount = clientCount + 1
        local definition = rawget(env, name)
        local fakeAbility = { IsNull = function() return false end, GetSpecialValueFor = function() return 3 end }
        local instance = setmetatable({ GetAbility = function() return fakeAbility end, GetStackCount = function() return 1 end,
            GetParent = function() return {} end }, { __index = definition })
        for _, method in ipairs({ "OnCreated", "OnRefresh", "IsHidden", "IsPurgable", "IsDebuff", "DeclareFunctions", "CheckState",
            "GetEffectName", "GetEffectAttachType", "GetModifierMoveSpeedBonus_Percentage", "GetModifierMiss_Percentage",
            "GetModifierEvasion_Constant", "OnTooltip", "OnAttackLanded", "OnDestroy" }) do
            if definition[method] then
                local called, failure = pcall(definition[method], instance, {})
                check(called, name .. ":" .. method .. " runs on the client: " .. tostring(failure))
            end
        end
    end
end
check(clientCount == 12, "all twelve desert modifiers are linked on the client (" .. clientCount .. ")")

print = realPrint
print(string.format("Desert biome data, monster moves, the Sunken King and client loading: %d checks passed", passed))
