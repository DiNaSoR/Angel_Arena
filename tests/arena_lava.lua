-- The lava biome against a stubbed engine: its data files validate, every ability behaves as its
-- tooltip says (Heat, Melting Armor, burning ground, death blasts, telegraphs, the boss's moves),
-- the shared brain picks the boss's moves in the intended order, and the ability script loads on
-- the client by itself with every lava modifier linked from it.
-- Run from the repository root: lua5.1 tests/arena_lava.lua
--
-- Self-contained: it only loads lava files and the shared core, never another biome's files.
-- What it cannot prove: that the engine behaves like these stubs (particles, sounds, orders).

local VSCRIPTS = "game/angel_arena/scripts/vscripts/"
package.path = VSCRIPTS .. "?.lua;" .. package.path

------------------------------------------------------------------------------- constants

local CONSTANTS = {
    DOTA_TEAM_GOODGUYS = 2, DOTA_TEAM_BADGUYS = 3, DOTA_TEAM_NEUTRALS = 4,
    DOTA_ABILITY_BEHAVIOR_HIDDEN = 1, DOTA_ABILITY_BEHAVIOR_PASSIVE = 2, DOTA_ABILITY_BEHAVIOR_NO_TARGET = 4,
    DOTA_ABILITY_BEHAVIOR_UNIT_TARGET = 8, DOTA_ABILITY_BEHAVIOR_POINT = 16, DOTA_ABILITY_BEHAVIOR_AOE = 32,
    DOTA_ABILITY_BEHAVIOR_CHANNELLED = 128, DOTA_ABILITY_BEHAVIOR_TOGGLE = 512,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY = 1, DOTA_UNIT_TARGET_TEAM_ENEMY = 2, DOTA_UNIT_TARGET_TEAM_BOTH = 3,
    DOTA_UNIT_TARGET_HERO = 1, DOTA_UNIT_TARGET_BASIC = 18, UF_SUCCESS = 0,
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

local function Near(a, b) return math.abs(a - b) < 1e-6 end

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

local UNIT_KV = ReadKV("game/angel_arena/scripts/npc/units/arena/arena_lava_units.txt")
local ABILITY_KV = ReadKV("game/angel_arena/scripts/npc/abilities/arena/arena_lava_abilities.txt")

local function Flags(text)
    local total = 0
    for name in tostring(text or ""):gmatch("[%w_]+") do
        total = total + (_G[name] or 0)
    end
    return total
end

------------------------------------------------------------------------------ the world

local now = 0
local world = {}
local damage = {}
local particles = {}
local controls = {}
local destroyed = {}
local projectiles = {}
local orders = {}
local summons = {}
local adds = 0
local nextIndex = 100

function IsServer() return true end
function class(definition) return definition end
function UTIL_Remove(entity)
    entity.removed = true
    entity.alive = false
    world[entity] = nil
end
function GetGroundPosition(position) return position end
function EmitSoundOnLocationWithCaster() end
function ApplyDamage(info) damage[#damage + 1] = info end
function UnitFilter() return UF_SUCCESS end
function RandomFloat(low) return low end

local linked = {}
function LinkLuaModifier(name, path)
    local file = io.open(VSCRIPTS .. path, "r")
    assert(file, "LinkLuaModifier points at a missing file: " .. path)
    file:close()
    linked[name] = path
end

local particleId = 0
ParticleManager = {
    CreateParticle = function(_, name)
        particleId = particleId + 1
        particles[#particles + 1] = name
        return particleId
    end,
    SetParticleControl = function(_, index, point, value) controls[index] = controls[index] or {}; controls[index][point] = value end,
    ReleaseParticleIndex = function() end,
    DestroyParticle = function(_, index) destroyed[index] = true end,
}
local function Created(name)
    local count = 0
    for _, particle in ipairs(particles) do
        if particle == name then count = count + 1 end
    end
    return count
end

ProjectileManager = { CreateTrackingProjectile = function(_, info) projectiles[#projectiles + 1] = info end }
GameRules = { GetGameTime = function() return now end }
ArenaBosses = {
    CountAdds = function() return adds end,
    Summon = function(caster, name, position, duration)
        summons[#summons + 1] = { caster = caster, name = name, position = position, duration = duration }
    end,
}

local function Reset()
    damage, particles, projectiles, orders, summons = {}, {}, {}, {}, {}
end

-------------------------------------------------------------------------------- modifiers

local Modifier = {}
function Modifier:GetParent() return self.parent end
function Modifier:GetCaster() return self.caster end
function Modifier:GetAbility() return self.ability end
function Modifier:GetDuration() return self.duration or -1 end
function Modifier:GetRemainingTime() return self.duration and (self.started + self.duration - now) or -1 end
function Modifier:SetDuration(duration) self.duration, self.started = duration, now end
function Modifier:GetStackCount() return self.stacks or 0 end
function Modifier:SetStackCount(count) self.stacks = count end
function Modifier:IsNull() return self.destroyed == true end
function Modifier:StartIntervalThink(interval) self.interval = interval end
function Modifier:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    self.parent.modifiers[self.name] = nil
    if self.OnDestroy then self:OnDestroy() end
end

local function MakeModifier(parent, caster, ability, name, data)
    local definition = rawget(_G, name)
    assert(definition, "no modifier " .. name)
    return setmetatable({ name = name, parent = parent, caster = caster, ability = ability,
        duration = data and data.duration, started = now }, { __index = function(_, key)
            if definition[key] ~= nil then return definition[key] end
            return Modifier[key]
        end })
end

-- Runs a timed modifier out: the clock reaches its end and it is destroyed.
local function Expire(modifier)
    now = modifier.started + (modifier.duration or 0)
    modifier:Destroy()
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
function Ability:IsNull() return self.removed == true end
function Ability:GetCaster() return self.unit end
function Ability:IsFullyCastable() return self.level > 0 and now >= (self.readyAt or 0) end
function Ability:IsCooldownReady() return now >= (self.readyAt or 0) end
function Ability:GetCastRange() return tonumber(self.kv.AbilityCastRange or 0) end
function Ability:GetCastPoint() return tonumber(self.kv.AbilityCastPoint or 0) end
function Ability:GetChannelTime() return PerLevel(self.kv.AbilityChannelTime or 0, self.level) end
function Ability:GetSpecialValueFor(key)
    local values = self.kv.AbilityValues or {}
    if values[key] == nil then return 0 end
    return PerLevel(values[key], self.level)
end
function Ability:GetCursorTarget() return self.cursorTarget end
function Ability:GetCursorPosition() return self.cursorPosition end

local function MakeAbility(unit, name, level)
    local definition = rawget(_G, name)
    assert(ABILITY_KV[name], "no KV for " .. name)
    return setmetatable({ name = name, unit = unit, level = level or 0, kv = ABILITY_KV[name] },
        { __index = function(_, key)
            if Ability[key] ~= nil then return Ability[key] end
            return definition and definition[key]
        end })
end

------------------------------------------------------------------------------------ units

local Unit = {}
function Unit:GetUnitName() return self.name end
function Unit:GetAbsOrigin() return self.origin end
function Unit:GetTeamNumber() return self.team end
function Unit:IsAlive() return self.alive end
function Unit:IsNull() return self.removed == true end
function Unit:GetHealth() return self.health end
function Unit:GetMaxHealth() return self.maxHealth end
function Unit:IsBuilding() return false end
function Unit:IsSilenced() return false end
function Unit:IsMuted() return false end
function Unit:TriggerSpellAbsorb() return self.linkens == true end
function Unit:PassivesDisabled() return self.broken == true end
function Unit:GetForwardVector() return Vector(1, 0, 0) end
function Unit:EmitSound() end
function Unit:StopSound() end
function Unit:GetAbilityCount() return 16 end
function Unit:GetAbilityByIndex(index) return self.abilities[index + 1] end
function Unit:FindAbilityByName(name)
    for _, ability in ipairs(self.abilities) do
        if ability.name == name then return ability end
    end
end
function Unit:AddNewModifier(caster, ability, name, data)
    local old = self.modifiers[name]
    if old and not old.destroyed then
        old.duration, old.started = data and data.duration or old.duration, now
        if old.OnRefresh then old:OnRefresh(data or {}) end
        return old
    end
    local modifier = MakeModifier(self, caster, ability, name, data)
    self.modifiers[name] = modifier
    if modifier.OnCreated then modifier:OnCreated(data or {}) end
    return modifier
end
function Unit:FindModifierByName(name) return self.modifiers[name] end
function Unit:HasModifier(name) return self.modifiers[name] ~= nil end
function Unit:RemoveModifierByName(name)
    local modifier = self.modifiers[name]
    if modifier then modifier:Destroy() end
end
local function Cast(unit, kind, ability, target)
    ability.readyAt = now + 5
    orders[#orders + 1] = { unit = unit, kind = kind, ability = ability:GetAbilityName(), target = target }
end
function Unit:CastAbilityNoTarget(ability) Cast(self, "cast", ability) end
function Unit:CastAbilityOnTarget(target, ability) Cast(self, "cast_target", ability, target) end
function Unit:CastAbilityOnPosition(position, ability) Cast(self, "cast_point", ability, position) end

local function MakeUnit(name, position, team, options)
    options = options or {}
    nextIndex = nextIndex + 1
    local unit = setmetatable({ name = name, origin = position, team = team, alive = true, index = nextIndex,
        health = options.health or 1000, maxHealth = options.maxHealth or options.health or 1000, hero = options.hero,
        modifiers = {}, abilities = {}, thinker = options.thinker }, { __index = Unit })
    world[unit] = true
    return unit
end

local function Hero(team, position)
    return MakeUnit("npc_dota_hero_axe", position, team, { hero = true, health = 3000 })
end

-- A lava monster with its unit file's abilities at `level`.
local function Monster(name, position, level)
    local kv = assert(UNIT_KV[name], "no unit " .. name)
    local unit = MakeUnit(name, position, DOTA_TEAM_NEUTRALS)
    for slot = 1, 8 do
        local ability = kv["Ability" .. slot]
        if ability and ability ~= "" then
            unit.abilities[#unit.abilities + 1] = MakeAbility(unit, ability, level)
        end
    end
    for _, ability in ipairs(unit.abilities) do
        if ability.GetIntrinsicModifierName then
            unit:AddNewModifier(unit, ability, ability:GetIntrinsicModifierName(), {})
        end
    end
    return unit
end

local thinkers = {}
function CreateModifierThinker(caster, ability, name, data, position, team)
    local thinker = MakeUnit("npc_dota_thinker", position, team, { thinker = true })
    thinker:AddNewModifier(caster, ability, name, data)
    thinkers[#thinkers + 1] = thinker
    return thinker
end
local function Thinkers(name)
    local list = {}
    for _, thinker in ipairs(thinkers) do
        local modifier = thinker.modifiers[name]
        if modifier and not thinker.removed then list[#list + 1] = modifier end
    end
    return list
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
    table.sort(found, function(a, b) return a.index < b.index end)
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

local function DamageTo(victim)
    local total = 0
    for _, info in ipairs(damage) do
        if info.victim == victim then total = total + info.damage end
    end
    return total
end

-- Clears the board between scenarios.
local function Clear()
    for unit in pairs(world) do world[unit] = nil end
    thinkers = {}
    Reset()
    now = 0
end

------------------------------------------------------------------------ load the scripts

require("arena/core/biomes")
require("arena/core/monster_ai")
dofile(VSCRIPTS .. "arena/biomes/lava/abilities.lua")
local FX = dofile(VSCRIPTS .. "arena/biomes/lava/fx.lua")
local MONSTERS = dofile(VSCRIPTS .. "arena/biomes/lava/monsters.lua")
local BOSS = dofile(VSCRIPTS .. "arena/biomes/lava/boss.lua")
local P = FX.particles

------------------------------------------------------------------------ data and wiring

local function Problems(list) return table.concat(list, "; ") end
local problems = ArenaBiomes.ValidateMonsters("lava", MONSTERS)
check(#problems == 0, "lava monsters.lua validates: " .. Problems(problems))
problems = ArenaBiomes.ValidateBoss("lava", BOSS)
check(#problems == 0, "lava boss.lua validates: " .. Problems(problems))
problems = ArenaBiomes.ValidateFx("lava", FX)
check(#problems == 0, "lava fx.lua validates: " .. Problems(problems))

for tier = 1, 4 do
    check(#MONSTERS.tiers[tier] >= 3, "tier " .. tier .. " has at least three groups")
end
for tier = 3, 4 do
    for _, group in ipairs(MONSTERS.tiers[tier]) do
        check(UNIT_KV[group[1]].Ability1, group[1] .. " leads a tier " .. tier .. " camp and has an ability")
    end
end
for name, stats in pairs(MONSTERS.monsters) do
    check(UNIT_KV[name], name .. " is in the lava unit file")
    for ability in pairs(stats.ai or {}) do
        local has = false
        for slot = 1, 8 do has = has or UNIT_KV[name]["Ability" .. slot] == ability end
        check(has, name .. " has the ability its ai hint names: " .. ability)
    end
end
-- Lava is the late-game region: each of its tiers is tougher than the green tier of the same rank.
local GREEN = dofile(VSCRIPTS .. "arena/biomes/green/monsters.lua")
-- Compared camp by camp: the weakest lava camp of a tier has more health than the weakest green one.
local function Weakest(data, tier)
    local lowest
    for _, group in ipairs(data.tiers[tier]) do
        local total = 0
        for _, name in ipairs(group) do total = total + data.monsters[name].health end
        lowest = lowest and math.min(lowest, total) or total
    end
    return lowest
end
for tier = 1, 4 do
    check(Weakest(MONSTERS, tier) > Weakest(GREEN, tier), "lava tier " .. tier .. " camps are tougher than green tier " .. tier)
end
check(BOSS.stats.health > dofile(VSCRIPTS .. "arena/biomes/green/boss.lua").stats.health, "the Tyrant outlasts the Grovewarden")

-- The boss: slot order is boss.lua's priority order, MaxLevel is the number of phases.
local bossKV = UNIT_KV[BOSS.unit]
for index, spec in ipairs(BOSS.abilities) do
    check(bossKV["Ability" .. index] == spec.name, "boss slot " .. index .. " holds " .. spec.name .. " (the brain's priority order)")
    check(tonumber(ABILITY_KV[spec.name].MaxLevel) == #BOSS.phases, spec.name .. " has one level per phase")
end
for _, summon in ipairs(BOSS.summons) do
    check(MONSTERS.monsters[summon], "boss summon " .. summon .. " has stats in monsters.lua")
end

-- Every lava ability is a class in the script; every KV value it reads exists.
for name, definition in pairs(ABILITY_KV) do
    check(type(rawget(_G, name)) == "table", name .. " is defined in abilities.lua")
    check(definition.ScriptFile == "arena/biomes/lava/abilities.lua", name .. " names the lava script")
    if tonumber(definition.MaxLevel) == 4 then
        for key, values in pairs(definition.AbilityValues or {}) do
            local count = 0
            for _ in tostring(values):gmatch("%S+") do count = count + 1 end
            check(count == 1 or count == 4, name .. "." .. key .. " has one value or four")
        end
    end
end

-- Every lava modifier links to the lava file (the client only links what an ability script links).
local lavaModifiers = 0
for name, path in pairs(linked) do
    if name:find("^modifier_arena_lava_") then
        lavaModifiers = lavaModifiers + 1
        check(path == "arena/biomes/lava/abilities.lua", name .. " links to the lava ability file")
    end
end
check(lavaModifiers >= 14, "the lava modifiers are linked (" .. lavaModifiers .. ")")

-- Visible modifiers have tooltips in the lava fragment.
local fragment = assert(io.open("tools/biomes/tooltips/lava.txt", "rb"))
local tooltips = fragment:read("*a")
fragment:close()
for name in pairs(linked) do
    if name:find("^modifier_arena_lava_") then
        local definition = rawget(_G, name)
        if not definition.IsHidden(definition) then
            check(tooltips:find('"DOTA_Tooltip_' .. name .. '"', 1, true) and tooltips:find('"DOTA_Tooltip_' .. name .. '_Description"', 1, true),
                name .. " is visible and has a tooltip in tools/biomes/tooltips/lava.txt")
        end
    end
end

-------------------------------------------------------------------- Heat (ashen satyr)

local satyr = Monster("npc_arena_lava_ashen_satyr", At(0, 0), 2)
local hero = Hero(DOTA_TEAM_GOODGUYS, At(100, 0))
local blows = satyr.modifiers.modifier_arena_lava_smouldering_blows
blows:OnAttackLanded({ attacker = satyr, target = hero })
local heat = hero.modifiers.modifier_arena_lava_heat
check(heat and heat:GetStackCount() == 1 and heat.duration == 4, "a satyr blow adds one stack of heat for 4 seconds")
heat:OnIntervalThink()
check(#damage == 1 and damage[1].damage == 8 and damage[1].attacker == satyr, "each stack burns for heat_dps (level 2: 8)")
for _ = 1, 20 do blows:OnAttackLanded({ attacker = satyr, target = hero }) end
check(heat:GetStackCount() == 10, "heat stops at 10 stacks")
Reset()
heat:OnIntervalThink()
check(damage[1].damage == 80, "ten stacks burn ten times as hard")
blows:OnAttackLanded({ attacker = satyr, target = satyr })
check(not satyr.modifiers.modifier_arena_lava_heat, "no heat on its own side")
satyr.broken = true
local before = heat:GetStackCount()
heat:SetStackCount(1)
blows:OnAttackLanded({ attacker = satyr, target = hero })
check(heat:GetStackCount() == 1, "break stops smouldering blows")
satyr.broken = false
heat:SetStackCount(before)
-- A stronger source raises the burn of every stack.
local drake = Monster("npc_arena_lava_magma_drake", At(0, 300), 4)
local spit = drake:FindAbilityByName("arena_lava_cinder_spit")
spit.cursorTarget = hero
spit:OnSpellStart()
check(#projectiles == 1 and projectiles[1].EffectName == P.spit and projectiles[1].Target == hero, "cinder spit throws a tracking cinder")
Reset()
spit:OnProjectileHit(hero)
check(damage[1].damage == 220 and heat.dps == 18 and heat:GetStackCount() == 10, "spit: damage, and heat now burns at the stronger rate")
heat:SetStackCount(2)
spit:OnProjectileHit(hero)
check(heat:GetStackCount() == 5, "spit adds heat_stacks (level 4: 3)")
-- Heat whose source is gone stops.
satyr.removed = true
heat.caster = satyr
heat:OnIntervalThink()
check(heat.destroyed, "heat from a removed monster goes out")

--------------------------------------------------------- Melting Armor (flame brawler)

Clear()
local brawler = Monster("npc_arena_lava_flame_brawler", At(0, 0), 3)
hero = Hero(DOTA_TEAM_GOODGUYS, At(100, 0))
local strikes = brawler.modifiers.modifier_arena_lava_melting_strikes
strikes:OnAttackLanded({ attacker = brawler, target = hero })
local melt = hero.modifiers.modifier_arena_lava_melting
check(melt and melt:GetModifierPhysicalArmorBonus() == -2 and melt.duration == 5, "a brawler blow melts 2 armor (level 3) for 5 seconds")
for _ = 1, 20 do strikes:OnAttackLanded({ attacker = brawler, target = hero }) end
check(melt:GetStackCount() == 8 and melt:GetModifierPhysicalArmorBonus() == -16, "melting stops at max_stacks (level 3: 8)")
strikes:OnAttackLanded({ attacker = hero, target = brawler })
check(not brawler.modifiers.modifier_arena_lava_melting, "only the brawler's own attacks melt")

------------------------------------------------ Volatile Core and burning ground (sprite)

Clear()
local sprite = Monster("npc_arena_lava_ember_sprite", At(0, 0), 1)
hero = Hero(DOTA_TEAM_GOODGUYS, At(200, 0))
local far = Hero(DOTA_TEAM_GOODGUYS, At(600, 0))
local core = sprite.modifiers.modifier_arena_lava_volatile_core
sprite.alive = false
core:OnDeath({ unit = sprite, attacker = sprite })
core:OnDeath({ unit = sprite, attacker = Monster("npc_arena_lava_ashen_satyr", At(0, 0), 1) })
check(#Thinkers("modifier_arena_lava_death_blast") == 0, "no blast when it expires or its own side kills it")
sprite.broken = true
core:OnDeath({ unit = sprite, attacker = hero })
check(#Thinkers("modifier_arena_lava_death_blast") == 0, "break stops the blast")
sprite.broken = false
core:OnDeath({ unit = hero, attacker = sprite })
check(#Thinkers("modifier_arena_lava_death_blast") == 0, "another unit's death does nothing")
core:OnDeath({ unit = sprite, attacker = hero })
local blasts = Thinkers("modifier_arena_lava_death_blast")
check(#blasts == 1 and blasts[1].duration == 1 and Created(ArenaFxCore.PARTICLES.circle) == 1,
    "killed by an enemy, it leaves a ring that closes for 1 second")
sprite.removed = true  -- the corpse may be gone before the blast
Expire(blasts[1])
check(DamageTo(hero) == 90 and DamageTo(far) == 0, "the blast hits inside its radius only, even with the sprite gone")
check(damage[1].attacker == blasts[1].parent, "with the sprite gone, the blast itself deals the damage")
local fires = Thinkers("modifier_arena_lava_burning_ground")
check(#fires == 1 and fires[1].duration == 3 and fires[1].radius == 250 and Created(P.burning_ground) == 1,
    "the blast leaves burning ground for fire_duration")
check(controls[fires[1].fire][1].x == 250, "the fire's size goes to control point 1")
Reset()
fires[1]:OnIntervalThink()
check(DamageTo(hero) == 10 and DamageTo(far) == 0 and hero.modifiers.modifier_arena_lava_burning,
    "burning ground burns fire_dps per second in half-second ticks and marks who stands in it")
local fireEffect = fires[1].fire
fires[1]:Destroy()
check(fires[1].parent.removed and destroyed[fireEffect], "burning ground cleans up its thinker and effect")

-------------------------------------------------------------- Eruption Slam (slag golem)

Clear()
local golem = Monster("npc_arena_lava_slag_golem", At(0, 0), 2)
hero = Hero(DOTA_TEAM_GOODGUYS, At(250, 0))
far = Hero(DOTA_TEAM_GOODGUYS, At(500, 0))
local slam = golem:FindAbilityByName("arena_lava_eruption_slam")
check(slam:OnAbilityPhaseStart() == true and Created(ArenaFxCore.PARTICLES.circle) == 1, "the slam shows its ring during the wind-up")
local ring = slam.warning
slam:OnAbilityPhaseInterrupted()
check(destroyed[ring] and slam.warning == nil, "an interrupted slam removes its ring")
slam:OnAbilityPhaseStart()
slam:OnSpellStart()
check(DamageTo(hero) == 220 and DamageTo(far) == 0, "the slam hits inside its radius")
fires = Thinkers("modifier_arena_lava_burning_ground")
check(#fires == 1 and fires[1].dps == 55 and fires[1].duration == 4, "the slam leaves the ground burning")

-------------------------------------------------- Searing Brand and Kindle (cinder hexer)

Clear()
local hexer = Monster("npc_arena_lava_cinder_hexer", At(0, 0), 1)
hero = Hero(DOTA_TEAM_GOODGUYS, At(500, 0))
local friend = Hero(DOTA_TEAM_GOODGUYS, At(700, 0))
far = Hero(DOTA_TEAM_GOODGUYS, At(1200, 0))
local brandAbility = hexer:FindAbilityByName("arena_lava_searing_brand")
brandAbility.cursorTarget = hero
brandAbility:OnSpellStart()
local brand = hero.modifiers.modifier_arena_lava_searing_brand
check(brand and brand.duration == 3, "the brand burns for 3 seconds")
Expire(brand)
check(DamageTo(hero) == 160 and DamageTo(friend) == 160 and DamageTo(far) == 0, "the brand explodes on its bearer and allies beside it")
Reset()
brandAbility:OnSpellStart()
brand = hero.modifiers.modifier_arena_lava_searing_brand
now = now + 1
brand:Destroy()
check(#damage == 0, "a brand dispelled early does not explode")
brandAbility:OnSpellStart()
hero.alive = false
Expire(hero.modifiers.modifier_arena_lava_searing_brand)
check(#damage == 0, "a brand on a dead hero does not explode")
hero.alive = true
hero.linkens = true
brandAbility:OnSpellStart()
check(not hero.modifiers.modifier_arena_lava_searing_brand, "Linken's blocks the brand")
hero.linkens = false

local kindle = hexer:FindAbilityByName("arena_lava_kindle")
local ally = Monster("npc_arena_lava_flame_brawler", At(100, 0), 1)
kindle.cursorTarget = ally
kindle:OnSpellStart()
local kindled = ally.modifiers.modifier_arena_lava_kindled
check(kindled and kindled:GetModifierAttackSpeedBonus_Constant() == 30 and kindled.duration == 6, "kindle quickens an ally")
kindled:OnAttackLanded({ attacker = ally, target = hero })
check(hero.modifiers.modifier_arena_lava_heat and hero.modifiers.modifier_arena_lava_heat.dps == 6, "kindled attacks add heat")

------------------------------------------------- Hellfire Aura and Death Throes (infernal)

Clear()
local infernal = Monster("npc_arena_lava_infernal_golem", At(0, 0), 3)
hero = Hero(DOTA_TEAM_GOODGUYS, At(300, 0))
far = Hero(DOTA_TEAM_GOODGUYS, At(400, 0))
local aura = infernal.modifiers.modifier_arena_lava_hellfire_aura
check(aura.interval == 1, "the aura ticks every second")
aura:OnIntervalThink()
check(DamageTo(hero) == 45 and DamageTo(far) == 0 and hero.modifiers.modifier_arena_lava_heat:GetStackCount() == 1,
    "the aura burns and heats enemies inside its radius")
aura:OnIntervalThink()
check(hero.modifiers.modifier_arena_lava_heat:GetStackCount() == 2, "standing next to it keeps stacking heat")
infernal.broken = true
Reset()
aura:OnIntervalThink()
check(#damage == 0, "break silences the aura")
infernal.broken = false
local throes = infernal.modifiers.modifier_arena_lava_death_throes
infernal.alive = false
throes:OnDeath({ unit = infernal, attacker = hero })
blasts = Thinkers("modifier_arena_lava_death_blast")
check(#blasts == 1 and blasts[1].duration == 1.5 and blasts[1].data.big == 1, "the golem's death leaves a 1.5 second ring")
Reset()
Expire(blasts[1])
check(DamageTo(hero) == 650 and DamageTo(far) == 650, "death throes hit everything within 425 (level 3: 650)")
check(#Thinkers("modifier_arena_lava_burning_ground") == 1, "and leave a fire")

-------------------------------------------------- Lava Bomb and Searing Breath (wyrm)

Clear()
local wyrm = Monster("npc_arena_lava_magma_wyrm", At(0, 0), 1)
hero = Hero(DOTA_TEAM_GOODGUYS, At(600, 0))
local side = Hero(DOTA_TEAM_GOODGUYS, At(600, 400))
local bomb = wyrm:FindAbilityByName("arena_lava_lava_bomb")
check(bomb:GetAOERadius() == 250, "the bomb shows its area")
bomb.cursorPosition = At(600, 0)
bomb:OnSpellStart()
local pending = Thinkers("modifier_arena_delayed_strike")
check(#pending == 1 and pending[1].duration == 1.1 and pending[1].data.radius == 250, "a ring marks where the bomb lands")
Expire(pending[1])
check(DamageTo(hero) == 180 and DamageTo(side) == 0 and #Thinkers("modifier_arena_lava_burning_ground") == 1,
    "the bomb lands, hits the ring and leaves fire")
Reset()
local breath = wyrm:FindAbilityByName("arena_lava_searing_breath")
breath.cursorPosition = At(300, 0)
breath:OnSpellStart()
pending = Thinkers("modifier_arena_delayed_strike")
check(#pending == 1 and pending[1].data.shape == "line" and Near(pending[1].data.x2, 800) and pending[1].duration == 0.9,
    "a line marks the breath, its full length toward the target")
Expire(pending[1])
check(DamageTo(hero) == 160 and DamageTo(side) == 0 and hero.modifiers.modifier_arena_lava_melting:GetStackCount() == 3,
    "the breath burns and melts everything on the line")
wyrm.alive = false
breath:OnSpellStart()
Reset()
Expire(Thinkers("modifier_arena_delayed_strike")[1])
check(#damage == 0, "a dead wyrm's breath fizzles (shared delayed strike)")

-------------------------------------------------------------------------- the boss

local function Boss(phase)
    local boss = MakeUnit(BOSS.unit, At(0, 0), DOTA_TEAM_NEUTRALS, { health = 60000 })
    for slot = 1, 6 do
        boss.abilities[slot] = MakeAbility(boss, bossKV["Ability" .. slot], 0)
    end
    for _, spec in ipairs(BOSS.abilities) do
        boss:FindAbilityByName(spec.name):SetLevel(spec.phase <= phase and phase or 0)
    end
    for _, ability in ipairs(boss.abilities) do
        if ability.GetIntrinsicModifierName then
            boss:AddNewModifier(boss, ability, ability:GetIntrinsicModifierName(), {})
        end
    end
    return boss
end

-- Caldera Wake: waves of circles with gaps, each wave later than the one before.
Clear()
local tyrant = Boss(1)
local caldera = tyrant:FindAbilityByName("arena_lava_boss_caldera_wake")
caldera:OnSpellStart()
pending = Thinkers("modifier_arena_delayed_strike")
local byWave = {}
for _, strike in ipairs(pending) do
    local wave = math.floor(Distance(strike.parent.origin, At(0, 0)) / 325 + 0.5)
    byWave[wave] = byWave[wave] or {}
    table.insert(byWave[wave], strike)
end
check(#byWave[1] == 4 and #byWave[2] == 8 and byWave[3] == nil, "phase 1: two waves, 4 and 8 circles")
check(Near(byWave[1][1].duration, 1.2) and Near(byWave[2][1].duration, 1.8), "the second wave lands 0.6 seconds after the first")
-- Neighbouring circles of a wave leave a gap a hero can stand in.
for wave, strikes in pairs(byWave) do
    local gap = 2 * 325 * wave * math.sin(math.pi / #strikes) - 2 * 175
    check(gap >= 100, "wave " .. wave .. " leaves a gap of at least 100 between circles (" .. math.floor(gap) .. ")")
end
local eye = Hero(DOTA_TEAM_GOODGUYS, At(100, 0))
local onCircle = Hero(DOTA_TEAM_GOODGUYS, byWave[1][1].parent.origin + At(50, 0))
for _, strike in ipairs(pending) do Expire(strike) end
check(DamageTo(onCircle) == 380 and DamageTo(eye) == 0, "the circles erupt; the eye at its feet is safe")
check(#Thinkers("modifier_arena_lava_burning_ground") == 0, "phase 1 eruptions leave no fire")
check(BOSS.abilities[2].lock >= 1.2 + 0.6, "the brain waits for phase 1's last wave before its next move")

Clear()
tyrant = Boss(3)
caldera = tyrant:FindAbilityByName("arena_lava_boss_caldera_wake")
caldera:OnSpellStart()
pending = Thinkers("modifier_arena_delayed_strike")
check(#pending == 4 + 8 + 13, "phase 3: three waves")
local latest = 0
for _, strike in ipairs(pending) do latest = math.max(latest, strike.duration) end
check(latest <= BOSS.abilities[2].lock, "the brain waits for the last wave before its next move")
Expire(pending[1])
check(#Thinkers("modifier_arena_lava_burning_ground") == 1, "from phase 2 the eruptions leave fire")
check(BOSS.abilities[2].lock >= 1.2 + 2 * 0.5, "the lock covers phase 2's slowest last wave too")

-- Pyroclast Barrage: meteors follow one hero until they run out.
Clear()
tyrant = Boss(2)
hero = Hero(DOTA_TEAM_GOODGUYS, At(800, 0))
local barrageAbility = tyrant:FindAbilityByName("arena_lava_boss_pyroclast_barrage")
barrageAbility.cursorTarget = hero
barrageAbility:OnSpellStart()
local barrage = tyrant.modifiers.modifier_arena_lava_barrage
check(#Thinkers("modifier_arena_delayed_strike") == 1 and barrage and barrage.target == hero and barrage.left == 3,
    "the first meteor is marked at once; three more follow")
hero.origin = At(1100, 0)
barrage:OnIntervalThink()
pending = Thinkers("modifier_arena_delayed_strike")
check(#pending == 2 and Distance(pending[2].parent.origin, At(1100, 0)) == 0, "the next meteor is marked where the hero is now")
Expire(pending[1])
check(DamageTo(hero) == 0, "a hero who moved on is missed")
Expire(pending[2])
check(DamageTo(hero) == 300 and hero.modifiers.modifier_arena_lava_heat and #Thinkers("modifier_arena_lava_burning_ground") == 2,
    "a hero still standing there is hit, heated, and the ground burns")
barrage:OnIntervalThink()
barrage:OnIntervalThink()
check(barrage.left == 0 and not barrage.destroyed, "four meteors in all at phase 2")
barrage:OnIntervalThink()
check(barrage.destroyed, "then the barrage ends")
barrageAbility:OnSpellStart()
barrage = tyrant.modifiers.modifier_arena_lava_barrage
hero.alive = false
local count = #Thinkers("modifier_arena_delayed_strike")
barrage:OnIntervalThink()
check(barrage.destroyed and #Thinkers("modifier_arena_delayed_strike") == count, "the barrage stops when its target dies")

-- Heart of the Volcano: everything in the great ring burns except the small ring at its feet.
Clear()
tyrant = Boss(3)
local heart = tyrant:FindAbilityByName("arena_lava_boss_heart_of_the_volcano")
local inside = Hero(DOTA_TEAM_GOODGUYS, At(200, 0))
local middle = Hero(DOTA_TEAM_GOODGUYS, At(600, 0))
local outside = Hero(DOTA_TEAM_GOODGUYS, At(1100, 0))
heart:OnSpellStart()
check(#heart.warning == 2 and Created(ArenaFxCore.PARTICLES.circle) == 2, "two rings: the great one and the safe one at its feet")
local rings = heart.warning
heart:OnChannelFinish(true)
check(#damage == 0 and destroyed[rings[1]] and destroyed[rings[2]] and heart.warning == nil, "a stunned channel only clears its rings")
heart:OnSpellStart()
heart:OnChannelFinish(false)
check(DamageTo(middle) == 1400 and DamageTo(inside) == 0 and DamageTo(outside) == 0, "only the ground between the rings burns")
check(middle.modifiers.modifier_arena_lava_heat:GetStackCount() == 4, "and it leaves 4 stacks of heat")
check(heart:GetChannelTime() == 2.6, "phase 3 channel time")

-- Brood of Cinders: sprites, capped by how many are alive.
Clear()
tyrant = Boss(2)
local brood = tyrant:FindAbilityByName("arena_lava_boss_brood_of_cinders")
adds = 0
brood:OnSpellStart()
check(#summons == 3 and summons[1].name == "npc_arena_lava_ember_sprite" and summons[1].duration == 25, "phase 2 calls three sprites")
Reset()
adds = 5
brood:OnSpellStart()
check(#summons == 1, "never more than max_alive at once")

-- Searing Presence and Infernal Brand: passives from phase 1.
Clear()
tyrant = Boss(1)
hero = Hero(DOTA_TEAM_GOODGUYS, At(600, 0))
far = Hero(DOTA_TEAM_GOODGUYS, At(700, 0))
tyrant.modifiers.modifier_arena_lava_searing_presence:OnIntervalThink()
check(hero.modifiers.modifier_arena_lava_heat and hero.modifiers.modifier_arena_lava_heat.dps == 12 and not far.modifiers.modifier_arena_lava_heat,
    "heroes within 650 heat up every second")
check(#damage == 0, "the presence itself deals no direct damage")
tyrant.modifiers.modifier_arena_lava_infernal_brand:OnAttackLanded({ attacker = tyrant, target = hero })
check(hero.modifiers.modifier_arena_lava_melting:GetModifierPhysicalArmorBonus() == -1, "its blows melt armor")
local unlearned = Boss(1)
unlearned:FindAbilityByName("arena_lava_boss_searing_presence"):SetLevel(0)
unlearned.modifiers.modifier_arena_lava_searing_presence:OnIntervalThink()
check(hero.modifiers.modifier_arena_lava_heat:GetStackCount() == 1, "an unlearned presence does nothing")

------------------------------------------------------------- the brain's choices

local function Brain(unit, hints)
    return { unit = unit, hints = hints, lockUntil = 0, retryAt = {} }
end
local bossHints = {}
for _, spec in ipairs(BOSS.abilities) do bossHints[spec.name] = spec end

Clear()
tyrant = Boss(1)
hero = Hero(DOTA_TEAM_GOODGUYS, At(500, 0))
check(ArenaMonsterAI.TryCast(Brain(tyrant, bossHints), hero, tyrant.origin, now) and orders[1].ability == "arena_lava_boss_caldera_wake",
    "phase 1: a hero in reach gets a caldera wake")
Reset()
hero.origin = At(1000, 0)
check(not ArenaMonsterAI.TryCast(Brain(tyrant, bossHints), hero, tyrant.origin, now), "phase 1: nothing to cast at a hero 1000 away")
Clear()
tyrant = Boss(2)
hero = Hero(DOTA_TEAM_GOODGUYS, At(1000, 0))
ArenaMonsterAI.TryCast(Brain(tyrant, bossHints), hero, tyrant.origin, now)
check(orders[1].ability == "arena_lava_boss_pyroclast_barrage" and orders[1].target == hero, "phase 2: a distant hero draws a barrage")
Clear()
tyrant = Boss(3)
hero = Hero(DOTA_TEAM_GOODGUYS, At(500, 0))
local brain = Brain(tyrant, bossHints)
ArenaMonsterAI.TryCast(brain, hero, tyrant.origin, now)
check(orders[1].ability == "arena_lava_boss_heart_of_the_volcano" and brain.lockUntil == now + 0.5, "phase 3: heart of the volcano comes first")

Clear()
hexer = Monster("npc_arena_lava_cinder_hexer", At(0, 0), 1)
local scratched = Monster("npc_arena_lava_flame_brawler", At(100, 0), 1)
scratched.health = 990
hero = Hero(DOTA_TEAM_GOODGUYS, At(500, 0))
hexer:FindAbilityByName("arena_lava_searing_brand").readyAt = 100
ArenaMonsterAI.TryCast(Brain(hexer, MONSTERS.monsters.npc_arena_lava_cinder_hexer.ai), hero, hexer.origin, now)
check(orders[1].ability == "arena_lava_kindle" and orders[1].target == scratched, "the hexer kindles any touched ally")

-------------------------------------------- the client loads the lava script on its own

local env = { links = {} }
env._G = env
for _, name in ipairs({ "pairs", "ipairs", "type", "tostring", "tonumber", "math", "string", "table", "error",
    "assert", "select", "setmetatable", "getmetatable", "rawget", "rawset", "next", "pcall", "unpack", "bit", "print", "Vector" }) do
    env[name] = _G[name]
end
env.class = function(definition) return definition end
env.IsServer = function() return false end
env.LinkLuaModifier = function(name, path) env.links[name] = path end
env.ParticleManager = ParticleManager
setmetatable(env, { __index = function(globals, key)
    if type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
        rawset(globals, key, 7)
        return 7
    end
end })
local loaded = {}
env.require = function(name)
    if loaded[name] == nil then
        local chunk = assert(loadfile(VSCRIPTS .. name .. ".lua"))
        setfenv(chunk, env)
        loaded[name] = chunk() or true
    end
    return loaded[name]
end
local chunk = assert(loadfile(VSCRIPTS .. "arena/biomes/lava/abilities.lua"))
setfenv(chunk, env)
local ok, message = pcall(chunk)
check(ok, "lava abilities.lua loads on the client by itself: " .. tostring(message))
local clientCount = 0
for name, path in pairs(env.links) do
    if path == "arena/biomes/lava/abilities.lua" then
        clientCount = clientCount + 1
        local definition = rawget(env, name)
        check(type(definition) == "table", name .. " exists on the client")
        local fakeAbility = { IsNull = function() return false end, GetSpecialValueFor = function() return 3 end }
        local instance = setmetatable({ GetAbility = function() return fakeAbility end, GetStackCount = function() return 2 end,
            GetParent = function() return {} end }, { __index = definition })
        for _, method in ipairs({ "OnCreated", "OnRefresh", "IsHidden", "IsDebuff", "IsPurgable", "DeclareFunctions", "CheckState",
            "GetEffectName", "GetEffectAttachType", "GetModifierPhysicalArmorBonus", "GetModifierAttackSpeedBonus_Constant",
            "OnTooltip", "OnAttackLanded", "OnDeath", "OnDestroy" }) do
            if definition[method] then
                local called, failure = pcall(definition[method], instance, {})
                check(called, name .. ":" .. method .. " runs on the client: " .. tostring(failure))
            end
        end
    end
end
check(clientCount == lavaModifiers, "the client links every lava modifier from the lava script (" .. clientCount .. ")")
check(env.links.modifier_arena_delayed_strike == "arena/core/modifiers.lua", "the shared delayed strike is linked through the lava script's require")

print(string.format("Lava biome data, abilities, boss, brain and client loading: %d checks passed", passed))
