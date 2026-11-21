-- The ice biome against a stubbed engine: its data files, its KV, and every ice ability and
-- modifier (Chill, Frozen, Thawing, Brittle, Shatter, the camp abilities and the boss's kit),
-- plus loading abilities.lua the way the Dota client does.
-- Run from the repository root: lua5.1 tests/arena_ice.lua
--
-- What this proves: the scripts do what their tooltips say against stubs of the engine calls they
-- make. What it cannot prove: how the engine, the particles and the models behave in game (see
-- the list in tools/biomes/README.md and the ice report).

local VSCRIPTS = "game/angel_arena/scripts/vscripts/"
package.path = VSCRIPTS .. "?.lua;" .. package.path

local passed = 0
local function check(condition, message)
    if not condition then error("FAILED: " .. message, 2) end
    passed = passed + 1
end

------------------------------------------------------------------------------ constants

for key, value in pairs({
    DOTA_TEAM_GOODGUYS = 2, DOTA_TEAM_BADGUYS = 3, DOTA_TEAM_NEUTRALS = 4,
    DOTA_UNIT_TARGET_TEAM_FRIENDLY = 1, DOTA_UNIT_TARGET_TEAM_ENEMY = 2,
    DOTA_UNIT_TARGET_HERO = 1, DOTA_UNIT_TARGET_BASIC = 18,
}) do _G[key] = value end
local nextConstant = 1000000
setmetatable(_G, { __index = function(globals, key)
    if type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
        nextConstant = nextConstant + 1
        rawset(globals, key, nextConstant)
        return nextConstant
    end
end })

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
function vector:Length2D() return math.sqrt(self.x * self.x + self.y * self.y) end
local function At(x, y) return Vector(x, y, 0) end

------------------------------------------------------------------------------ KV reading

local function ReadKV(path)
    local file = assert(io.open(path, "rb"), "missing " .. path)
    local text = file:read("*a"):gsub("//[^\n]*", "")
    file:close()
    local position = 1
    local function token()
        local start, finish, quoted = text:find('^%s*"([^"]*)"', position)
        if start then position = finish + 1 return quoted end
        start, finish, quoted = text:find("^%s*([{}])", position)
        if start then position = finish + 1 return quoted, true end
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

local UNITS = ReadKV("game/angel_arena/scripts/npc/units/arena/arena_ice_units.txt")
local ABILITIES = ReadKV("game/angel_arena/scripts/npc/abilities/arena/arena_ice_abilities.txt")

------------------------------------------------------------------------------ the engine

local server = true
local damage, particles, stopped, projectiles, linked, sounds = {}, {}, 0, {}, {}, {}
local world = {}
local nextIndex = 100

function IsServer() return server end
function class(definition) return definition end
function LinkLuaModifier(name, path) linked[name] = path end
function GetGroundPosition(position) return position end
function RandomFloat(low) return low end
function EmitSoundOnLocationWithCaster(_, name) sounds[#sounds + 1] = name end
function ApplyDamage(info) damage[#damage + 1] = info end
function UTIL_Remove(entity) entity.removed = true entity.alive = false world[entity] = nil end
ParticleManager = {
    CreateParticle = function(_, name) particles[#particles + 1] = name return #particles end,
    SetParticleControl = function() end,
    ReleaseParticleIndex = function() end,
    DestroyParticle = function() stopped = stopped + 1 end,
}
ProjectileManager = {
    CreateTrackingProjectile = function(_, info) projectiles[#projectiles + 1] = info end,
    CreateLinearProjectile = function(_, info) projectiles[#projectiles + 1] = info end,
}
local function Created(name)
    local count = 0
    for _, particle in ipairs(particles) do if particle == name then count = count + 1 end end
    return count
end

local Modifier = {}
function Modifier:GetParent() return self.parent end
function Modifier:GetCaster() return self.caster end
function Modifier:GetAbility() return self.ability end
function Modifier:GetDuration() return self.duration or -1 end
function Modifier:SetDuration(duration) self.duration = duration end
function Modifier:GetStackCount() return self.stacks or 0 end
function Modifier:SetStackCount(count) self.stacks = count end
function Modifier:StartIntervalThink(interval) self.interval = interval end
function Modifier:IsNull() return self.destroyed == true end
function Modifier:Destroy()
    if self.destroyed then return end
    self.destroyed = true
    if self.parent.modifiers[self.name] == self then self.parent.modifiers[self.name] = nil end
    if self.OnDestroy then self:OnDestroy() end
end

local Unit = {}
Unit.__index = Unit
function Unit:GetUnitName() return self.name end
function Unit:GetAbsOrigin() return self.origin end
function Unit:GetTeamNumber() return self.team end
function Unit:GetEntityIndex() return self.index end
function Unit:IsAlive() return self.alive end
function Unit:IsNull() return self.removed == true end
function Unit:IsMagicImmune() return self.immune == true end
function Unit:IsBuilding() return false end
function Unit:IsRangedAttacker() return self.ranged == true end
function Unit:PassivesDisabled() return false end
function Unit:TriggerSpellAbsorb() return false end
function Unit:GetForwardVector() return Vector(1, 0, 0) end
function Unit:EmitSound(name) sounds[#sounds + 1] = name end
function Unit:StopSound() end
function Unit:HasModifier(name) return self.modifiers[name] ~= nil end
function Unit:FindModifierByName(name) return self.modifiers[name] end
function Unit:RemoveModifierByName(name)
    if self.modifiers[name] then self.modifiers[name]:Destroy() end
end
function Unit:AddNewModifier(caster, ability, name, data)
    local old = self.modifiers[name]
    if old then
        old.duration = data and data.duration or old.duration
        if old.OnRefresh then old:OnRefresh(data or {}) end
        return old
    end
    local definition = assert(rawget(_G, name), "unknown modifier " .. name)
    local modifier = setmetatable({ name = name, parent = self, caster = caster, ability = ability,
        duration = data and data.duration }, { __index = function(_, key)
            if definition[key] ~= nil then return definition[key] end
            return Modifier[key]
        end })
    self.modifiers[name] = modifier
    if modifier.OnCreated then modifier:OnCreated(data or {}) end
    return modifier
end
function Unit:Stacks(name) return self.modifiers[name] and self.modifiers[name]:GetStackCount() or 0 end

local function MakeUnit(name, position, team, options)
    options = options or {}
    nextIndex = nextIndex + 1
    local unit = setmetatable({ name = name, origin = position, team = team, alive = true, index = nextIndex,
        modifiers = {}, hero = options.hero, thinker = options.thinker, ranged = options.ranged, immune = options.immune }, Unit)
    world[unit] = true
    return unit
end
local function Hero(x, y, options)
    options = options or {}
    options.hero = true
    return MakeUnit("npc_dota_hero_axe", At(x, y), DOTA_TEAM_GOODGUYS, options)
end

function CreateUnitByName(name, position, _, _, _, team)
    assert(UNITS[name], "CreateUnitByName: no unit " .. name)
    return MakeUnit(name, position, team)
end
function CreateModifierThinker(caster, ability, name, data, position, team)
    local thinker = MakeUnit("npc_dota_thinker", position, team, { thinker = true })
    thinker:AddNewModifier(caster, ability, name, data)
    return thinker
end
function FindUnitsInRadius(team, origin, _, radius, filter, types)
    local found = {}
    for unit in pairs(world) do
        local teamOk = (filter == DOTA_UNIT_TARGET_TEAM_ENEMY and unit.team ~= team)
            or (filter == DOTA_UNIT_TARGET_TEAM_FRIENDLY and unit.team == team)
        local typeOk = unit.hero or types ~= DOTA_UNIT_TARGET_HERO
        if teamOk and typeOk and unit.alive and not unit.thinker and (unit.origin - origin):Length2D() <= radius then
            found[#found + 1] = unit
        end
    end
    table.sort(found, function(a, b) return a.index < b.index end)
    return found
end

local Ability = {}
function Ability:GetAbilityName() return self.name end
function Ability:GetLevel() return self.level end
function Ability:IsNull() return false end
function Ability:GetCaster() return self.unit end
function Ability:GetCursorTarget() return self.cursorTarget end
function Ability:GetCursorPosition() return self.cursorPosition end
local function PerLevel(text, level)
    local values = {}
    for number in tostring(text):gmatch("%S+") do values[#values + 1] = tonumber(number) end
    return values[math.min(math.max(level, 1), #values)] or 0
end
function Ability:GetSpecialValueFor(key)
    local values = self.kv.AbilityValues or {}
    return values[key] and PerLevel(values[key], self.level) or 0
end
function Ability:GetCastPoint() return PerLevel(self.kv.AbilityCastPoint or 0, self.level) end
function Ability:GetChannelTime() return PerLevel(self.kv.AbilityChannelTime or 0, self.level) end

-- A unit from the ice KV with its abilities at `level`; intrinsic modifiers are added like the engine does.
local function Spawn(name, position, level)
    local unit = CreateUnitByName(name, position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    unit.abilities = {}
    for slot = 1, 8 do
        local abilityName = UNITS[name]["Ability" .. slot]
        if abilityName then
            local definition = assert(rawget(_G, abilityName), abilityName .. " has no class")
            local ability = setmetatable({ name = abilityName, unit = unit, level = level or 1, kv = ABILITIES[abilityName] },
                { __index = function(_, key) return Ability[key] or definition[key] end })
            unit.abilities[abilityName] = ability
            if ability.GetIntrinsicModifierName then
                unit:AddNewModifier(unit, ability, ability:GetIntrinsicModifierName(), {})
            end
        end
    end
    return unit
end

local function Reset()
    damage, particles, stopped, projectiles, sounds = {}, {}, 0, {}, {}
    world = {}
end
local function DamageTo(unit)
    local total = 0
    for _, hit in ipairs(damage) do if hit.victim == unit then total = total + hit.damage end end
    return total
end
local function Thinkers(name)
    local list = {}
    for unit in pairs(world) do
        if unit.thinker and unit.modifiers[name] then list[#list + 1] = unit end
    end
    table.sort(list, function(a, b) return a.index < b.index end)
    return list
end

------------------------------------------------------------------------ load the scripts

require("arena/core/biomes")
dofile(VSCRIPTS .. "arena/biomes/ice/abilities.lua")
local FX = require("arena/biomes/ice/fx")
local P = FX.particles
local COLD = ArenaIce.COLD
local monsters = require("arena/biomes/ice/monsters")
local boss = require("arena/biomes/ice/boss")

--------------------------------------------------------------------------------- data

check(#ArenaBiomes.ValidateMonsters("ice", monsters) == 0, "ice monsters.lua passes validation: "
    .. table.concat(ArenaBiomes.ValidateMonsters("ice", monsters), "; "))
check(#ArenaBiomes.ValidateBoss("ice", boss) == 0, "ice boss.lua passes validation: " .. table.concat(ArenaBiomes.ValidateBoss("ice", boss), "; "))
check(#ArenaBiomes.ValidateFx("ice", FX) == 0, "ice fx.lua passes validation")

for tier = 1, 4 do
    check(#monsters.tiers[tier] >= 3, "tier " .. tier .. " has three groups")
    for _, group in ipairs(monsters.tiers[tier]) do
        for _, name in ipairs(group) do
            check(UNITS[name], name .. " is in the ice unit file")
            if tier == 1 then
                check(UNITS[name].Ability1 == nil, name .. " (tier 1) has no abilities: a fresh hero can farm it")
            end
        end
        if tier > 1 then
            check(UNITS[group[1]].Ability1 ~= nil, "tier " .. tier .. " leader " .. group[1] .. " has an ability")
        end
    end
end
for name in pairs(UNITS) do
    check(monsters.monsters[name] or name == boss.unit, name .. " has stats in monsters.lua or is the boss (and so is precached)")
end

-- The brain tries abilities in slot order: the boss's slots must follow boss.lua's priority list.
for index, spec in ipairs(boss.abilities) do
    check(UNITS[boss.unit]["Ability" .. index] == spec.name, "boss slot " .. index .. " is " .. spec.name)
    check(tonumber(ABILITIES[spec.name].MaxLevel) == #boss.phases, spec.name .. " has one level per phase")
end
check(boss.summons[1] == "npc_arena_ice_glacial_pillar", "the pillar is listed for precaching")

-- Every cast animation is one the model was found to have (activities read from the compiled
-- models in Dota's archive). A missing activity would leave the monster frozen mid-cast.
local ACTIVITIES = {
    ["models/creeps/neutral_creeps/n_creep_ghost_b/n_creep_ghost_frost.vmdl"] = { "ACT_DOTA_ATTACK" },
    ["models/creeps/ice_biome/tuskfolk/tuskfolk001a_f.vmdl"] = { "ACT_DOTA_ATTACK", "ACT_DOTA_CAST_ABILITY_1", "ACT_DOTA_CAST_ABILITY_3", "ACT_DOTA_CAST_ABILITY_4", "ACT_DOTA_CAST_ABILITY_5" },
    ["models/creeps/ice_biome/frostbitten/n_creep_frostbitten_shaman01.vmdl"] = { "ACT_DOTA_ATTACK", "ACT_DOTA_CAST_ABILITY_1", "ACT_DOTA_CAST_ABILITY_3", "ACT_DOTA_CAST_ABILITY_4" },
    ["models/creeps/ice_biome/frostbitten/n_creep_frostbitten_swollen01.vmdl"] = { "ACT_DOTA_ATTACK", "ACT_DOTA_CAST_ABILITY_1", "ACT_DOTA_CAST_ABILITY_2", "ACT_DOTA_CAST_ABILITY_3" },
    ["models/creeps/ice_biome/ogreseal/ogreseal.vmdl"] = { "ACT_DOTA_ATTACK", "ACT_DOTA_CAST_ABILITY_2" },
    ["models/creeps/ice_biome/undeadtusk/undead_tuskskeleton_armor01.vmdl"] = { "ACT_DOTA_ATTACK", "ACT_DOTA_CAST_ABILITY_1", "ACT_DOTA_CAST_ABILITY_3", "ACT_DOTA_CAST_ABILITY_4", "ACT_DOTA_CAST_ABILITY_5" },
    ["models/creeps/ice_biome/giant/ice_giant01.vmdl"] = { "ACT_DOTA_ATTACK", "ACT_DOTA_CAST_ABILITY_1", "ACT_DOTA_CAST_ABILITY_3", "ACT_DOTA_CAST_ABILITY_4" },
}
for name, unit in pairs(UNITS) do
    for slot = 1, 8 do
        local ability = unit["Ability" .. slot] and ABILITIES[unit["Ability" .. slot]]
        if ability and ability.AbilityCastAnimation then
            local known = ACTIVITIES[unit.Model]
            check(known, name .. " has a cast animation, so its model's activities must be listed here")
            local found = false
            for _, activity in ipairs(known) do found = found or activity == ability.AbilityCastAnimation end
            check(found, name .. ": " .. ability.AbilityCastAnimation .. " is an activity of " .. unit.Model)
        end
    end
end

-- The tooltips write the cold's numbers out; they must match COLD.
local tips = assert(io.open("tools/biomes/tooltips/ice.txt", "rb")):read("*a")
check(tips:find("At " .. COLD.freeze_at .. " stacks", 1, true), "tooltips name the freeze threshold COLD.freeze_at")
for name, path in pairs(linked) do
    if path == "arena/biomes/ice/abilities.lua" and not rawget(_G, name).IsHidden({}) then
        check(tips:find('"DOTA_Tooltip_' .. name .. '"', 1, true) and tips:find('"DOTA_Tooltip_' .. name .. '_Description"', 1, true),
            name .. " is visible and has a tooltip in ice.txt")
    end
end

----------------------------------------------------------------------------- the cold

Reset()
local source = MakeUnit("npc_arena_ice_rime_wraith", At(0, 0), DOTA_TEAM_NEUTRALS)
local hero = Hero(100, 0)
ArenaIce.Chill(hero, source, 2)
local chill = hero.modifiers.modifier_arena_ice_chill
check(chill and chill:GetStackCount() == 2 and chill:GetDuration() == COLD.duration, "Chill stacks and lasts COLD.duration")
check(chill:GetModifierMoveSpeedBonus_Percentage() == -2 * COLD.move_per_stack
    and chill:GetModifierAttackSpeedBonus_Constant() == -2 * COLD.attack_per_stack, "each Chill stack slows movement and attacks")
ArenaIce.Chill(hero, source, COLD.freeze_at - 2)
check(hero:HasModifier("modifier_arena_ice_frozen") and not hero:HasModifier("modifier_arena_ice_chill"),
    "reaching COLD.freeze_at stacks freezes and clears the Chill")
check(hero.modifiers.modifier_arena_ice_frozen:GetDuration() == COLD.freeze_duration, "a Chill freeze lasts COLD.freeze_duration")
local state = hero.modifiers.modifier_arena_ice_frozen:CheckState()
check(state[MODIFIER_STATE_STUNNED] and state[MODIFIER_STATE_FROZEN], "Frozen stuns")
ArenaIce.Chill(hero, source, 1)
check(not hero:HasModifier("modifier_arena_ice_chill"), "a frozen hero gains no Chill")
hero.modifiers.modifier_arena_ice_frozen:Destroy()
check(hero:HasModifier("modifier_arena_ice_thawing") and hero.modifiers.modifier_arena_ice_thawing:GetDuration() == COLD.thaw_duration,
    "a thawed hero is Thawing")
ArenaIce.Chill(hero, source, 3)
check(not hero:HasModifier("modifier_arena_ice_chill"), "Thawing keeps Chill off")
check(not ArenaIce.Freeze(hero, source, 1, false) and ArenaIce.Freeze(hero, source, 1, true), "only a forced freeze goes through Thawing")
check(ArenaIce.Shatter(hero, source, nil, 250) and DamageTo(hero) == 250 and not hero:HasModifier("modifier_arena_ice_frozen"),
    "Shatter deals its bonus and breaks the ice")
check(not ArenaIce.Shatter(hero, source, nil, 250), "Shatter does nothing to a hero that is not frozen")
local immune = Hero(0, 100, { immune = true })
ArenaIce.Chill(immune, source, 9)
check(not immune:HasModifier("modifier_arena_ice_chill") and not immune:HasModifier("modifier_arena_ice_frozen"), "spell immunity keeps the cold out")

------------------------------------------------------------------------ camp abilities

-- Rime Bolt
Reset()
local wraith = Spawn("npc_arena_ice_rime_wraith", At(0, 0), 2)
hero = Hero(400, 0)
local bolt = wraith.abilities.arena_ice_rime_bolt
bolt.cursorTarget = hero
bolt:OnSpellStart()
check(#projectiles == 1 and projectiles[1].Target == hero and projectiles[1].EffectName == P.rime_bolt, "Rime Bolt launches a projectile")
check(bolt:OnProjectileHit(hero) and DamageTo(hero) == 80 and hero:Stacks("modifier_arena_ice_chill") == 2, "Rime Bolt hits and chills")

-- Brittle Blows
Reset()
local raider = Spawn("npc_arena_ice_tuskarr_raider", At(0, 0), 1)
hero = Hero(100, 0)
local blows = raider.modifiers.modifier_arena_ice_brittle_blows
check(blows and blows:IsHidden(), "Brittle Blows is a hidden intrinsic")
for _ = 1, 7 do blows:OnAttackLanded({ attacker = raider, target = hero }) end
local brittle = hero.modifiers.modifier_arena_ice_brittle
check(brittle:GetStackCount() == 5 and brittle:GetModifierPhysicalArmorBonus() == -5, "Brittle stacks to max_stacks, -1 armor each")
blows:OnAttackLanded({ attacker = hero, target = raider })
check(not raider:HasModifier("modifier_arena_ice_brittle"), "only the raider's own attacks crack armour")

-- Blizzard
Reset()
local shaman = Spawn("npc_arena_ice_frostbitten_shaman", At(0, 0), 1)
local still, moving = Hero(500, 0), Hero(560, 60)
local blizzard = shaman.abilities.arena_ice_blizzard
blizzard.cursorPosition = At(520, 0)
blizzard:OnSpellStart()
local storm = Thinkers("modifier_arena_ice_blizzard")[1].modifiers.modifier_arena_ice_blizzard
check(storm and storm.interval == 0.5 and Created(P.blizzard) == 1, "Blizzard leaves a storm that ticks every half second")
storm:OnIntervalThink()
check(DamageTo(still) == 12.5 and still:Stacks("modifier_arena_ice_chill") == 0, "the first tick only hurts")
moving.origin = At(560, -60)
storm:OnIntervalThink()
check(still:Stacks("modifier_arena_ice_chill") == 1 and not moving:HasModifier("modifier_arena_ice_chill"),
    "standing still in the storm chills; moving does not")
for _ = 1, COLD.freeze_at - 1 do storm:OnIntervalThink() end
check(still:HasModifier("modifier_arena_ice_frozen"), "standing in the storm long enough freezes")
storm:Destroy()
check(stopped == 1, "the storm's effect ends with it")

-- Rime Shell
Reset()
shaman = Spawn("npc_arena_ice_frostbitten_shaman", At(0, 0), 2)
local ally = Spawn("npc_arena_ice_frost_kobold", At(100, 0), 1)
local shell = shaman.abilities.arena_ice_rime_shell
shell.cursorTarget = ally
shell:OnSpellStart()
local coat = ally.modifiers.modifier_arena_ice_rime_shell
check(coat and coat:GetModifierPhysicalArmorBonus() == 6 and coat:GetDuration() == 6, "Rime Shell gives armour")
local melee, ranged = Hero(150, 0), Hero(500, 0, { ranged = true })
coat:OnAttackLanded({ attacker = melee, target = ally })
coat:OnAttackLanded({ attacker = ranged, target = ally })
check(melee:Stacks("modifier_arena_ice_chill") == 1 and not ranged:HasModifier("modifier_arena_ice_chill"), "only melee attackers are chilled")

-- Rime Burst
Reset()
local bloat = Spawn("npc_arena_ice_rimebloat", At(0, 0), 2)
local near, far = Hero(200, 0), Hero(600, 0)
bloat.alive = false
bloat.modifiers.modifier_arena_ice_rime_burst_passive:OnDeath({ unit = bloat })
local burst = Thinkers("modifier_arena_ice_rime_burst")[1]
check(burst and burst.modifiers.modifier_arena_ice_rime_burst:GetDuration() == 1.2 and Created(ArenaFxCore.PARTICLES.circle) == 1,
    "a dying rimebloat leaves a closing ring")
check(DamageTo(near) == 0, "nothing happens before the ring closes")
burst.modifiers.modifier_arena_ice_rime_burst:Destroy()
check(DamageTo(near) == 190 and near:Stacks("modifier_arena_ice_chill") == 3 and DamageTo(far) == 0, "the burst hurts and chills within its radius")
check(burst.removed and damage[1].attacker == burst, "the burst is its own attacker, so the dead monster does not matter")
bloat.modifiers.modifier_arena_ice_rime_burst_passive:OnDeath({ unit = near })
check(#Thinkers("modifier_arena_ice_rime_burst") == 0, "other deaths do not trigger it")

-- Shatter Slam
Reset()
local seal = Spawn("npc_arena_ice_ogreseal_brute", At(0, 0), 3)
local plain, iced, outside = Hero(200, 0), Hero(0, 200), Hero(500, 0)
ArenaIce.Freeze(iced, seal, 2, true)
local slam = seal.abilities.arena_ice_shatter_slam
check(slam:OnAbilityPhaseStart() and Created(ArenaFxCore.PARTICLES.circle) == 1, "the slam's wind-up draws its ring")
slam:OnSpellStart()
check(stopped == 1, "the ring goes when the slam lands")
check(DamageTo(plain) == 340 and plain:Stacks("modifier_arena_ice_chill") == 2, "the slam hurts and chills")
check(DamageTo(iced) == 680 and not iced:HasModifier("modifier_arena_ice_frozen"), "a frozen hero shatters for shatter_pct more")
check(DamageTo(outside) == 0, "stepping out of the ring is safe")
slam:OnAbilityPhaseStart()
slam:OnAbilityPhaseInterrupted()
check(stopped == 2, "an interrupted wind-up removes its ring")

-- Glacial Tomb
Reset()
local revenant = Spawn("npc_arena_ice_rime_revenant", At(0, 0), 1)
hero = Hero(400, 0)
hero:AddNewModifier(hero, nil, "modifier_arena_ice_thawing", { duration = 3 })
local tomb = revenant.abilities.arena_ice_glacial_tomb
tomb.cursorTarget = hero
tomb:OnSpellStart()
local mark = Thinkers("modifier_arena_delayed_strike")[1]
check(mark and mark.origin == hero.origin and mark.modifiers.modifier_arena_delayed_strike:GetDuration() == 1.3,
    "Glacial Tomb marks the target's spot")
mark.modifiers.modifier_arena_delayed_strike:Destroy()
check(DamageTo(hero) == 100 and hero.modifiers.modifier_arena_ice_frozen:GetDuration() == 1.2, "standing in the tomb freezes, even when thawing")
Reset()
hero = Hero(400, 0)
tomb:OnSpellStart()
hero.origin = At(700, 0)
Thinkers("modifier_arena_delayed_strike")[1].modifiers.modifier_arena_delayed_strike:Destroy()
check(DamageTo(hero) == 0 and not hero:HasModifier("modifier_arena_ice_frozen"), "walking out of the tomb dodges it")

-- Cold Grasp
local grasp = revenant.modifiers.modifier_arena_ice_cold_grasp
grasp:OnAttackLanded({ attacker = revenant, target = hero })
check(hero:Stacks("modifier_arena_ice_chill") == 1, "Cold Grasp chills on every attack")

--------------------------------------------------------------------------------- the boss

-- Frigid Fists
Reset()
local giant = Spawn("npc_arena_ice_boss", At(0, 0), 1)
local tank = Hero(150, 0)
for _ = 1, 10 do giant.modifiers.modifier_arena_ice_boss_frigid_fists:OnAttackLanded({ attacker = giant, target = tank }) end
check(tank.modifiers.modifier_arena_ice_brittle:GetModifierPhysicalArmorBonus() == -12, "Frigid Fists: 8 stacks of -1.5 armor at phase 1")

-- Frost Breath
Reset()
giant = Spawn("npc_arena_ice_boss", At(0, 0), 1)
local front, edge, beside, behind = Hero(500, 0), Hero(500, 300), Hero(300, 400), Hero(-300, 0)
local frozenFront = Hero(700, 50)
ArenaIce.Freeze(frozenFront, giant, 2, true)
local breath = giant.abilities.arena_ice_boss_frost_breath
breath.cursorPosition = At(800, 0)
breath:OnAbilityPhaseStart()
check(Created(ArenaFxCore.PARTICLES.line) == 3, "three lines mark the cone during the wind-up")
breath:OnSpellStart()
check(stopped == 3, "the lines go when the breath comes")
check(DamageTo(front) == 300 and front:Stacks("modifier_arena_ice_chill") == 3, "the breath hurts and chills in the cone")
check(DamageTo(edge) == 300, "the cone is 70 degrees wide (31 degrees off-centre is inside)")
check(DamageTo(beside) == 0 and DamageTo(behind) == 0, "outside the cone and behind the giant are safe")
check(DamageTo(frozenFront) == 450, "frozen heroes in the cone shatter for 50% more")
check(projectiles[1].EffectName == P.breath and projectiles[1].iUnitTargetTeam == DOTA_UNIT_TARGET_TEAM_NONE,
    "the breath's projectile is only the picture")

-- Icefall
Reset()
giant = Spawn("npc_arena_ice_boss", At(0, 0), 1)
local icefall = giant.abilities.arena_ice_boss_icefall
icefall:OnSpellStart()
local marks = Thinkers("modifier_arena_delayed_strike")
check(#marks == 6 + 9, "phase 1 Icefall drops two rings of 6 and 9 icicles")
local nearest, delayAt = math.huge, {}
for _, thinker in ipairs(marks) do
    local distance = math.floor(thinker.origin:Length2D() + 0.5)
    nearest = math.min(nearest, distance)
    delayAt[distance] = thinker.modifiers.modifier_arena_delayed_strike:GetDuration()
end
check(nearest - icefall:GetSpecialValueFor("radius") >= 140, "the giant's feet are outside every icicle")
check(delayAt[320] == 1.4 and math.abs(delayAt[600] - 2.1) < 1e-9, "the outer ring falls wave_delay after the inner one")
icefall.level = 3
Reset()
icefall:OnSpellStart()
check(#Thinkers("modifier_arena_delayed_strike") == 6 + 9 + 12, "phase 3 Icefall adds a third ring")
hero = Hero(320, 0)
icefall:OnArenaStrike(At(320, 0), { radius = 175, loud = 1 })
check(DamageTo(hero) == 440 and hero:Stacks("modifier_arena_ice_chill") == 2, "an icicle hurts and chills")
ArenaIce.Freeze(hero, giant, 2, true)
icefall:OnArenaStrike(At(320, 0), { radius = 175, loud = 0 })
check(DamageTo(hero) == 440 + 880, "an icicle shatters a frozen hero for double")

-- Whiteout
Reset()
giant = Spawn("npc_arena_ice_boss", At(0, 0), 0)
local whiteout = giant.modifiers.modifier_arena_ice_boss_whiteout_storm
local camper, runner = Hero(400, 0), Hero(-400, 0)
whiteout:OnIntervalThink()
whiteout:OnIntervalThink()
check(not camper:HasModifier("modifier_arena_ice_whiteout") and #particles == 0, "no Whiteout before phase 2 (level 0)")
for _, ability in pairs(giant.abilities) do ability.level = 2 end
whiteout:OnIntervalThink()
check(camper:HasModifier("modifier_arena_ice_whiteout") and Created(P.whiteout_snow) == 1, "phase 2 brings the Whiteout")
runner.origin = At(-400, 200)
whiteout:OnIntervalThink()
check(camper:Stacks("modifier_arena_ice_chill") == 1 and not runner:HasModifier("modifier_arena_ice_chill"),
    "standing still in the Whiteout chills, moving does not")
check(camper.modifiers.modifier_arena_ice_whiteout:OnTooltip() == 60, "the Whiteout debuff shows how far to move")
for _, ability in pairs(giant.abilities) do ability.level = 0 end
whiteout:OnIntervalThink()
check(stopped == 1, "the Whiteout calms when the boss resets to phase 1")

-- Absolute Zero
Reset()
giant = Spawn("npc_arena_ice_boss", At(0, 0), 3)
local zero = giant.abilities.arena_ice_boss_absolute_zero
zero:OnSpellStart()
check(#zero.pillars == 3 and zero.pillars[1].name == "npc_arena_ice_glacial_pillar", "three pillars rise")
check(Created(ArenaFxCore.PARTICLES.circle) == 1, "a ring closes over the channel")
local pillarState = zero.pillars[1].modifiers.modifier_arena_ice_glacial_pillar:CheckState()
check(pillarState[MODIFIER_STATE_INVULNERABLE] and zero.pillars[1].modifiers.modifier_arena_ice_glacial_pillar:GetDuration() == 4.5,
    "the pillars are untouchable and outlast the channel")
local shelter = zero.pillars[1].origin
local sheltered = Hero(shelter.x + 100, shelter.y)
local exposed = Hero(0, -200)
local away = Hero(1500, 0)
local placed = zero.pillars
zero:OnChannelFinish(false)
check(DamageTo(exposed) == 900 and exposed.modifiers.modifier_arena_ice_frozen:GetDuration() == 2.5, "anyone caught is frozen and hurt")
check(DamageTo(sheltered) == 0 and not sheltered:HasModifier("modifier_arena_ice_frozen"), "a hero beside a pillar is safe")
check(DamageTo(away) == 0, "a hero outside the ring is safe")
check(zero.pillars == nil and placed[1].removed and placed[3].removed and stopped >= 2, "the ring and the pillars go when it ends")
Reset()
exposed = Hero(0, -200)
zero:OnSpellStart()
local pillars = zero.pillars
zero:OnChannelFinish(true)
check(DamageTo(exposed) == 0 and pillars[1].removed, "a stunned giant's Absolute Zero fizzles and its pillars break")

----------------------------------------------------- the client loads the script on its own

local env = { links = {} }
env._G = env
for _, name in ipairs({ "pairs", "ipairs", "type", "tostring", "tonumber", "math", "string", "table", "error",
    "assert", "select", "setmetatable", "getmetatable", "rawget", "rawset", "next", "pcall", "unpack", "print", "Vector" }) do
    env[name] = _G[name]
end
env.class = function(definition) return definition end
env.IsServer = function() return false end
env.LinkLuaModifier = function(name, path) env.links[name] = path end
setmetatable(env, { __index = function(globals, key)
    if type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then rawset(globals, key, 7) return 7 end
end })
local loadedModules = {}
env.require = function(name)
    if loadedModules[name] == nil then
        local chunk = assert(loadfile(VSCRIPTS .. name .. ".lua"))
        setfenv(chunk, env)
        loadedModules[name] = chunk() or true
    end
    return loadedModules[name]
end
local chunk = assert(loadfile(VSCRIPTS .. "arena/biomes/ice/abilities.lua"))
setfenv(chunk, env)
local ok, failure = pcall(chunk)
check(ok, "ice abilities.lua loads on the client by itself: " .. tostring(failure))
local count = 0
for name, path in pairs(linked) do
    if path == "arena/biomes/ice/abilities.lua" then
        count = count + 1
        check(env.links[name] == path, name .. " is linked on the client by the ice ability file")
        local definition = rawget(env, name)
        local fakeAbility = { IsNull = function() return false end, GetSpecialValueFor = function() return 3 end, GetLevel = function() return 1 end }
        local instance = setmetatable({ GetAbility = function() return fakeAbility end, GetStackCount = function() return 1 end,
            GetParent = function() return {} end, GetCaster = function() return {} end }, { __index = definition })
        for _, method in ipairs({ "OnCreated", "OnRefresh", "IsHidden", "IsDebuff", "IsPurgable", "DeclareFunctions", "CheckState",
            "GetEffectName", "GetStatusEffectName", "GetModifierMoveSpeedBonus_Percentage", "GetModifierAttackSpeedBonus_Constant",
            "GetModifierPhysicalArmorBonus", "OnTooltip", "OnAttackLanded", "OnDeath", "OnDestroy" }) do
            if definition[method] then
                local called, problem = pcall(definition[method], instance, {})
                check(called, name .. ":" .. method .. " runs on the client: " .. tostring(problem))
            end
        end
    end
end
check(count == 14, "the ice ability file links all 14 ice modifiers (found " .. count .. ")")

print(string.format("Ice biome data, cold, camp abilities, boss and client loading: %d checks passed", passed))
