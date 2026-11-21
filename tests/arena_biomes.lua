-- Arena biomes against a stubbed engine: markers, tiers and growth, camp respawning, the shared
-- monster brain (abilities and leash), champions, drops, bosses (spawn, phases, reset, reward,
-- respawn), the legacy creep_camp fallback, every green ability script, and loading the modifier
-- scripts on their own the way the Dota client does.
-- Run from the repository root: lua5.1 tests/arena_biomes.lua
--
-- What this proves: the Lua logic, the data files and the scripts agree with each other and call
-- the engine the way they are written to. What it cannot prove: that the engine behaves like these
-- stubs (orders, particles, sounds, KV parsing). See tools/biomes/README.md for in-game checks.

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
    DOTA_UNIT_TARGET_HERO = 1, DOTA_UNIT_TARGET_BASIC = 18,
    SKIP_TEAM_SETUP = false, INITIAL_CREEP_DELAY = 5, DOTA_MAX_TEAM_PLAYERS = 24, UF_SUCCESS = 0,
}
for key, value in pairs(CONSTANTS) do
    _G[key] = value
end
-- Any other engine constant only needs to be a distinct number.
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

local logged = {}
local realPrint = print
function print(...)
    local parts = {}
    for index = 1, select("#", ...) do parts[#parts + 1] = tostring(select(index, ...)) end
    logged[#logged + 1] = table.concat(parts, " ")
end
local function Logged(text)
    for _, line in ipairs(logged) do
        if line:find(text, 1, true) then return true end
    end
    return false
end

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
function vector:Normalized()
    local length = math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
    return length > 0 and self / length or Vector(0, 0, 0)
end
local function At(x, y) return Vector(x, y, 0) end

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

local UNIT_KV = ReadKV("game/angel_arena/scripts/npc/units/arena/arena_green_units.txt")
local ABILITY_KV = ReadKV("game/angel_arena/scripts/npc/abilities/arena/arena_green_abilities.txt")

local function Flags(text)
    local total = 0
    for name in tostring(text or ""):gmatch("[%w_]+") do
        total = total + (_G[name] or 0)
    end
    return total
end

------------------------------------------------------------------------------ the world

local now = 0
local state = DOTA_GAMERULES_STATE_GAME_IN_PROGRESS
local server = true
local world = {}          -- every live unit and thinker
local created = {}        -- every unit CreateUnitByName returned, in order
local orders = {}         -- every order given: { unit, kind, target }
local damage = {}         -- every ApplyDamage call
local particles = {}      -- name of every particle created
local notifications = {}
local globalSounds = {}
local fowViewers = 0
local drops = {}
local goldPaid = {}
local labels = {}
local projectiles = {}
local nextIndex = 100
local rollFloat = 0.99    -- what RandomFloat returns, as a fraction of the range

function IsServer() return server end
function class(definition) return definition end
function IsValidEntity(entity) return entity ~= nil and not entity.removed end
function UTIL_Remove(entity)
    entity.removed = true
    entity.alive = false
    world[entity] = nil
end
function RandomInt(low) return low end
function RandomFloat(low, high) return low + rollFloat * (high - low) end
function RandomVector(length) return Vector(length, 0, 0) end
function GetGroundPosition(position) return position end
function ScreenShake() end
function EmitGlobalSound(name) globalSounds[#globalSounds + 1] = name end
function EmitSoundOnLocationWithCaster() end
function AddFOWViewer() fowViewers = fowViewers + 1 end
function ApplyDamage(info) damage[#damage + 1] = info end
-- What the engine says about a cast target; tests set `immuneTo` to refuse one.
local immuneTo = {}
function UnitFilter(target) return immuneTo[target] and 15 or UF_SUCCESS end

local linked = {}
function LinkLuaModifier(name, path)
    local file = io.open(VSCRIPTS .. path, "r")
    assert(file, "LinkLuaModifier points at a missing file: " .. path)
    file:close()
    linked[name] = path
end

local precached = { units = {}, resources = {} }
function PrecacheUnitByNameSync(name) precached.units[name] = true end
function PrecacheResource(kind, path) precached.resources[path] = kind end

local particleId = 0
ParticleManager = {
    CreateParticle = function(_, name)
        particleId = particleId + 1
        particles[#particles + 1] = name
        return particleId
    end,
    SetParticleControl = function() end,
    SetParticleControlEnt = function() end,
    ReleaseParticleIndex = function() end,
    DestroyParticle = function(_, index) particles.destroyed = (particles.destroyed or 0) + 1 end,
}
local function Created(name)
    local count = 0
    for _, particle in ipairs(particles) do
        if particle == name then count = count + 1 end
    end
    return count
end

ProjectileManager = { CreateTrackingProjectile = function(_, info) projectiles[#projectiles + 1] = info end }

GameRules = {
    State_Get = function() return state end,
    GetDOTATime = function(_, pregame, negative)
        assert(pregame == false and negative == false, "match clock must exclude pregame")
        return now
    end,
    GetGameTime = function() return now end,
    IsGamePaused = function() return false end,
    IsCheatMode = function() return true end,
}

local timers = {}
Timers = { CreateTimer = function(_, delay, callback)
    timers[#timers + 1] = { delay = delay, callback = callback }
end }

Notifications = { TopToAll = function(_, data) notifications[#notifications + 1] = data end }
local function Announced(text)
    for _, note in ipairs(notifications) do
        if note.text == text then return note end
    end
end

CreepItemDrop = { CreateDrop = function(_, item, position) drops[#drops + 1] = { item = item, position = position } end }

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
    self.parent.modifiers[self.name] = nil
    if self.OnDestroy then self:OnDestroy() end
end

local function MakeModifier(parent, caster, ability, name, data)
    local definition = rawget(_G, name)
    local modifier = setmetatable({ name = name, parent = parent, caster = caster, ability = ability,
        duration = data and data.duration }, { __index = function(_, key)
            if definition and definition[key] ~= nil then return definition[key] end
            return Modifier[key]
        end })
    return modifier
end

-------------------------------------------------------------------------------- abilities

local Ability = {}
function Ability:GetAbilityName() return self.name end
function Ability:GetLevel() return self.level end
function Ability:SetLevel(level) self.level = level end
function Ability:GetMaxLevel() return tonumber(self.kv.MaxLevel or 1) end
function Ability:GetBehaviorInt() return Flags(self.kv.AbilityBehavior) end
function Ability:GetAbilityTargetTeam() return Flags(self.kv.AbilityUnitTargetTeam) end
function Ability:IsHidden() return false end
function Ability:IsNull() return false end
function Ability:GetCaster() return self.unit end
function Ability:IsFullyCastable() return self.level > 0 and now >= (self.readyAt or 0) end
function Ability:IsCooldownReady() return now >= (self.readyAt or 0) end
function Ability:GetAbilityTargetType() return Flags(self.kv.AbilityUnitTargetType) end
function Ability:GetAbilityTargetFlags() return 0 end
function Ability:GetCastRange() return tonumber(self.kv.AbilityCastRange or 0) end
function Ability:GetCastPoint() return tonumber(self.kv.AbilityCastPoint or 0) end
local function PerLevel(text, level)
    local values = {}
    for number in tostring(text):gmatch("%S+") do values[#values + 1] = tonumber(number) end
    return values[math.min(math.max(level, 1), #values)] or 0
end
function Ability:GetChannelTime() return PerLevel(self.kv.AbilityChannelTime or 0, self.level) end
function Ability:GetSpecialValueFor(key)
    local values = self.kv.AbilityValues or {}
    if values[key] == nil then return 0 end
    return PerLevel(values[key], self.level)
end
function Ability:GetCursorTarget() return self.cursorTarget end
function Ability:GetCursorPosition() return self.cursorPosition end

local function MakeAbility(unit, name)
    local definition = rawget(_G, name)
    return setmetatable({ name = name, unit = unit, level = 0, kv = ABILITY_KV[name] or { AbilityBehavior = "DOTA_ABILITY_BEHAVIOR_PASSIVE" } },
        { __index = function(_, key)
            if Ability[key] ~= nil then return Ability[key] end
            return definition and definition[key]
        end })
end

------------------------------------------------------------------------------------ units

local Unit = {}
function Unit:GetUnitName() return self.name end
function Unit:GetAbsOrigin() return self.origin end
function Unit:SetAbsOrigin(position) self.origin = position end
function Unit:GetTeamNumber() return self.team end
function Unit:GetTeam() return self.team end
function Unit:IsAlive() return self.alive end
function Unit:IsNull() return self.removed == true end
function Unit:GetEntityIndex() return self.index end
function Unit:GetHealth() return self.health end
function Unit:GetMaxHealth() return self.maxHealth end
function Unit:SetHealth(value) self.health = math.min(value, self.maxHealth) end
function Unit:SetMaxHealth(value) self.maxHealth = value end
function Unit:SetBaseMaxHealth(value) self.baseMaxHealth = value end
function Unit:SetBaseDamageMin(value) self.damage = value end
function Unit:SetBaseDamageMax() end
function Unit:SetPhysicalArmorBaseValue(value) self.armor = value end
function Unit:SetMinimumGoldBounty(value) self.gold = value end
function Unit:SetMaximumGoldBounty() end
function Unit:SetDeathXP(value) self.xp = value end
function Unit:Heal(amount) self.health = math.min(self.maxHealth, self.health + amount); self.healed = (self.healed or 0) + amount end
function Unit:IsRealHero() return self.hero == true end
function Unit:IsBuilding() return false end
function Unit:IsMagicImmune() return false end
function Unit:TriggerSpellAbsorb() return false end
function Unit:PassivesDisabled() return false end
function Unit:IsStunned() return self.modifiers.modifier_stunned ~= nil end
function Unit:IsHexed() return false end
function Unit:IsCommandRestricted() return false end
function Unit:IsChanneling() return false end
function Unit:IsSilenced() return false end
function Unit:IsMuted() return false end
function Unit:GetCurrentActiveAbility() return nil end
function Unit:CanEntityBeSeenByMyTeam() return true end
function Unit:GetForwardVector() return Vector(1, 0, 0) end
function Unit:EmitSound() end
function Unit:StopSound() end
function Unit:GetAttackTarget() return self.attackTarget end
function Unit:SetCustomHealthLabel(text, r, g, b) labels[self] = text end
function Unit:AddExperience(amount) self.experience = (self.experience or 0) + amount end
function Unit:SetContextThink(name, callback) self.thinks[name] = callback end
function Unit:ForceKill() self.alive = false; world[self] = nil end
function Unit:Stop()
    self.attackTarget = nil
    orders[#orders + 1] = { unit = self, kind = "stop" }
end
function Unit:MoveToPosition(position)
    self.attackTarget = nil
    orders[#orders + 1] = { unit = self, kind = "move", target = position }
end
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
function Unit:RemoveAbility(name)
    for index, ability in ipairs(self.abilities) do
        if ability.name == name then table.remove(self.abilities, index) return end
    end
end
function Unit:AddNewModifier(caster, ability, name, data)
    local old = self.modifiers[name]
    if old and not old.destroyed then
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
    if not kv and not name:find("^npc_dota_neutral_") then
        return nil
    end
    local unit = MakeUnit(name, position, team)
    if kv then
        for slot = 1, 8 do
            local ability = kv["Ability" .. slot]
            if ability and ability ~= "" then
                unit.abilities[#unit.abilities + 1] = MakeAbility(unit, ability)
            end
        end
    else
        unit.abilities[1] = MakeAbility(unit, "neutral_upgrade")
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

local function Distance(a, b) return (a - b):Length2D() end

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

local markers = {}
local fountains = {}
local spawnPoints = {}
local queries = {}
local function Marker(x, y, attributes)
    nextIndex = nextIndex + 1
    local index = nextIndex
    return {
        GetEntityIndex = function() return index end,
        GetAbsOrigin = function() return At(x, y) end,
        GetIntAttr = function(_, name) return (attributes or {})[name] or 0 end,
    }
end
Entities = {
    FindAllByName = function(_, name)
        queries[#queries + 1] = name
        return markers[name] or {}
    end,
    FindByName = function(_, _, name)
        queries[#queries + 1] = name
        return markers[name] and markers[name][1]
    end,
    FindAllByClassname = function(_, classname)
        if classname == "ent_dota_fountain" then return fountains end
        if classname == "info_player_start_goodguys" then return spawnPoints end
        return {}
    end,
}

local heroes = {}
PlayerResource = {
    -- Like libraries/playerresource.lua: an iterator object that ipairs cannot walk.
    GetAllTeamPlayerIDs = function() return setmetatable({ gen = next }, {}) end,
    IsValidPlayerID = function(_, id) return id >= 0 and id <= 3 end,
    GetTeam = function(_, id) return id < 2 and DOTA_TEAM_GOODGUYS or DOTA_TEAM_BADGUYS end,
    GetSelectedHeroEntity = function(_, id) return heroes[id] end,
}
Gold = {
    AddGoldWithMessage = function(_, hero, amount, playerID)
        goldPaid[#goldPaid + 1] = { hero = hero, amount = amount, player = playerID }
    end,
    AddGold = function(_, playerID, amount) goldPaid[#goldPaid + 1] = { amount = amount, player = playerID } end,
}

local function Kill(unit, attacker)
    unit.alive = false
    world[unit] = nil
    ArenaWorld.OnEntityKilled(unit, attacker)
end

local function Think(unit)
    return unit.thinks.ArenaMonsterAI()
end

local function LastOrder(unit)
    for index = #orders, 1, -1 do
        if orders[index].unit == unit then return orders[index] end
    end
end

local function Spawned(from)
    local list = {}
    for index = from + 1, #created do list[#list + 1] = created[index] end
    return list
end

------------------------------------------------------------------------ load the scripts

require("arena/index")
-- Load every biome's ability script that exists, as the engine would from the KV ScriptFiles.
local function Exists(path)
    local file = io.open(path, "rb")
    if file then file:close() end
    return file ~= nil
end
local abilityScripts = {}
for _, biome in ipairs(ArenaBiomes.NAMES) do
    local script = "arena/biomes/" .. biome .. "/abilities"
    if Exists(VSCRIPTS .. script .. ".lua") then
        abilityScripts[#abilityScripts + 1] = script
        dofile(VSCRIPTS .. script .. ".lua")
    end
end
check(ArenaWorld and ArenaCamps and ArenaBosses and ArenaMonsterAI, "arena/index.lua loads every module")
check(linked.modifier_arena_monster == "arena/core/modifiers.lua", "shared modifiers link to their own file")
check(linked.modifier_arena_green_rooted == "arena/biomes/green/abilities.lua", "green modifiers link to the green ability file")

-------------------------------------------------------------------- biome files and checks

local biomes = ArenaBiomes.Load()
for _, name in ipairs(ArenaBiomes.NAMES) do
    check(#biomes[name].problems == 0, name .. " biome files pass validation: " .. table.concat(biomes[name].problems, "; "))
end
check(biomes.green.monsters and biomes.green.boss and biomes.green.fx, "green has monsters, a boss and effects")
check(biomes.wilds.monsters and #biomes.wilds.monsters.tiers[4] > 0, "wilds has an elite tier")
for _, name in ipairs({ "desert", "ice", "lava" }) do
    check(biomes[name].monsters == nil and biomes[name].boss == nil, name .. " has no files yet and that is harmless")
end
local groups, pool = ArenaBiomes.Pool("ice", 2)
check(pool == biomes.wilds.monsters and groups == biomes.wilds.monsters.tiers[2], "a biome without monsters borrows the wilds pool")
check(ArenaBiomes.Monster("npc_arena_green_thicket_bear").health == 1900, "monster stats are found by unit name")

-- Every scripted ability of every biome is a real class in its biome's script.
for _, biome in ipairs(ArenaBiomes.NAMES) do
    local path = "game/angel_arena/scripts/npc/abilities/arena/arena_" .. biome .. "_abilities.txt"
    if Exists(path) then
        for name, definition in pairs(ReadKV(path)) do
            if type(definition) == "table" and definition.BaseClass == "ability_lua" then
                check(type(rawget(_G, name)) == "table", name .. " is defined by " .. tostring(definition.ScriptFile))
            end
        end
    end
end

-- A biome file that throws, or whose data is wrong, switches off only that part and says why.
package.preload["arena/biomes/lava/monsters"] = function() error("broken on purpose") end
package.preload["arena/biomes/desert/monsters"] = function()
    return { biome = "desert", monsters = { npc_arena_desert_scarab = { health = 0, damage = 5, armor = 1, gold = 1, xp = 1 },
        desert_typo = { health = 10, damage = 1, armor = 0, gold = 1, xp = 1 } },
        tiers = { [1] = { { "npc_arena_desert_missing" } }, [5] = {} } }
end
package.preload["arena/biomes/ice/boss"] = function()
    return { unit = "npc_arena_ice_boss", first_spawn = 10, respawn = 10, leash = 10, stats = { health = 1, damage = 1, armor = 0 },
        phases = { { health = 1 }, { health = 0.7 }, { health = 0.8 } },
        abilities = { { name = "arena_ice_boss_x", phase = 4 } }, reward = { gold = 1, xp = 1 } }
end
biomes = ArenaBiomes.Load(true)
local function Mentions(list, text)
    for _, line in ipairs(list) do
        if line:find(text, 1, true) then return true end
    end
    return false
end
check(Mentions(biomes.lava.problems, "broken on purpose"), "a lava file that throws is reported")
check(Mentions(biomes.desert.problems, "health must be a number above 0"), "a zero-health monster is reported")
check(Mentions(biomes.desert.problems, "desert_typo must be named npc_arena_desert_"), "a badly named monster is reported")
check(Mentions(biomes.desert.problems, "npc_arena_desert_missing is not in monsters"), "a group naming an unknown monster is reported")
check(Mentions(biomes.desert.problems, "tiers are 1 to 4"), "a tier outside 1..4 is reported")
check(Mentions(biomes.ice.problems, "phase 3 needs a health fraction below"), "phases out of order are reported")
check(Mentions(biomes.ice.problems, "needs a phase between 1 and 3"), "an ability for a phase that does not exist is reported")
check(biomes.desert.monsters == nil and biomes.ice.boss == nil and biomes.green.monsters, "only the broken parts are switched off")
check(Logged("lava monsters switched off"), "switched-off parts are announced in the console")
for _, path in ipairs({ "arena/biomes/lava/monsters", "arena/biomes/desert/monsters", "arena/biomes/ice/boss" }) do
    package.preload[path] = nil
    package.loaded[path] = nil
end
biomes = ArenaBiomes.Load(true)
check(#biomes.desert.problems == 0 and #biomes.lava.problems == 0, "biomes load cleanly again")

------------------------------------------------------------------------ tiers and growth

local base = { health = 1000, damage = 100, armor = 10, gold = 50, xp = 100 }
local stats = ArenaTiers.Stats(base, ArenaTiers.Level(0))
check(stats.health == 1000 and stats.damage == 100 and stats.gold == 50 and stats.xp == 100, "minute 0 uses the base stats")
stats = ArenaTiers.Stats(base, ArenaTiers.Level(10.9))
check(stats.health == 1500 and stats.damage == 140 and stats.armor == 12 and stats.gold == 90 and stats.xp == 280,
    "minute 10: +5% health, +4% damage, +2% armor, +8% gold, +18% xp per minute")
stats = ArenaTiers.Stats(base, ArenaTiers.Level(90))
check(stats.health == 2500 and stats.xp == 640, "growth stops at minute 30")
stats = ArenaTiers.Stats(base, 0, true)
check(stats.health == 2500 and stats.damage == 130 and stats.gold == 150 and stats.xp == 200, "champions: x2.5 health, x1.3 damage, x3 gold, x2 xp")
check(ArenaTiers.AbilityLevel(1, 0) == 1 and ArenaTiers.AbilityLevel(3, 0) == 2 and ArenaTiers.AbilityLevel(4, 0) == 3,
    "ability level starts at 1/1/2/3 by tier")
check(ArenaTiers.AbilityLevel(3, 20) == 3 and ArenaTiers.AbilityLevel(4, 60) == 4, "abilities gain a level every 20 minutes up to 4")
check(#ArenaTiers.Composition({ "a", "b" }, 2, 14.9) == 2, "no extra monster before the tier's minute")
local extra = ArenaTiers.Composition({ "a", "b" }, 2, 15)
check(#extra == 3 and extra[3] == "b", "from the tier's minute the last monster is doubled")
check(math.abs(ArenaTiers.ChampionChance(4, 10) - 0.14) < 1e-9 and math.abs(ArenaTiers.ChampionChance(1, 100) - 0.10) < 1e-9,
    "champion chance grows with the clock, capped")
for tier = 2, 4 do
    local lower, higher = ArenaTiers.Profile(tier - 1), ArenaTiers.Profile(tier)
    check(higher.respawn > lower.respawn and higher.leash > lower.leash and higher.drop_chance > lower.drop_chance
        and higher.champion_chance > lower.champion_chance, "tier " .. tier .. " is harder and richer than tier " .. (tier - 1))
end

------------------------------------------------------------------------- marker lookup

markers = {
    arena_camp_green_3 = { Marker(0, 0) },
    arena_camp_wilds_1 = { Marker(3000, 0) },
    arena_camp_ice_2 = { Marker(-3000, 0) },
    arena_boss_green = { Marker(6000, 0) },
    creep_camp = { Marker(9000, 9000) },
}
ArenaWorld:Init()
local expected = {}
for _, biome in ipairs(ArenaBiomes.NAMES) do
    for tier = 1, 4 do expected["arena_camp_" .. biome .. "_" .. tier] = true end
end
local asked = {}
for _, name in ipairs(queries) do
    check(not name:find("*", 1, true), "markers are looked up by exact name, not wildcard: " .. name)
    asked[name] = true
end
for name in pairs(expected) do
    check(asked[name], "looked for marker " .. name)
end
check(not asked.creep_camp, "legacy markers are ignored when the map has arena markers")
check(#ArenaCamps.camps == 3 and ArenaCamps.source == "arena", "one camp per arena marker")
check(#ArenaBosses.states == 1 and ArenaBosses.states[1].biome == "green", "the green boss found its marker")
check(Logged("no arena_boss_wilds marker") == false and Logged("no arena_boss_desert") == false,
    "biomes without a boss do not look for a boss marker")
check(#timers == 2 and timers[1].delay == INITIAL_CREEP_DELAY, "camps start after the creep delay")
ArenaWorld:Init()
check(#timers == 2, "starting twice does nothing")

local campByName = {}
for _, camp in ipairs(ArenaCamps.camps) do campByName[camp.name] = camp end
local green, wilds, ice = campByName.arena_camp_green_3, campByName.arena_camp_wilds_1, campByName.arena_camp_ice_2

------------------------------------------------------------------------- first spawns

local campTick = timers[1].callback
check(campTick() == ArenaCamps.THINK_INTERVAL, "the camp timer keeps running")
local function Members(camp)
    local list = {}
    for unit in pairs(camp.units) do list[#list + 1] = unit end
    table.sort(list, function(a, b) return a.index < b.index end)
    return list
end
local greenUnits = Members(green)
check(#greenUnits == 3, "green tier 3 spawns its first group: a bear and two archers")
local bear, archerA, archerB = greenUnits[1], greenUnits[2], greenUnits[3]
check(bear.name == "npc_arena_green_thicket_bear" and archerA.name == "npc_arena_green_thorn_archer", "group leader first")
check(Distance(bear.origin, At(0, 0)) == 0 and math.abs(Distance(archerA.origin, At(0, 0)) - ArenaCamps.SPAWN_SPREAD) < 1e-6,
    "the leader stands on the marker, the rest on a ring")
check(bear.maxHealth == 1900 and bear.health == 1900 and bear.damage == 62 and bear.gold == 110 and bear.xp == 100,
    "stats come from monsters.lua")
check(bear:FindAbilityByName("arena_green_bramble_slam"):GetLevel() == 2, "tier 3 abilities start at level 2")
check(bear.thinks.ArenaMonsterAI and bear:HasModifier("modifier_arena_monster"), "every monster gets the shared brain")
check(bear.arenaBrain.leash == ArenaTiers.Profile(3).leash and bear.arenaBrain.group == archerA.arenaBrain.group,
    "monsters of one camp share a leash and a memory")
local wildsUnits = Members(wilds)
check(#wildsUnits == 2 and wildsUnits[1].name == "npc_dota_neutral_kobold_tunneler", "wilds tier 1 spawns kobolds")
check(wildsUnits[1]:FindAbilityByName("neutral_upgrade") == nil, "Dota's own neutral growth is removed from stock creeps")
local iceUnits = Members(ice)
check(#iceUnits == 3 and iceUnits[1].name == "npc_dota_neutral_harpy_storm", "an ice camp without ice monsters uses wilds tier 2")
check(Logged("ice has no tier 2 monsters yet"), "borrowing the wilds pool is announced once")

------------------------------------------------------------------- respawn gating

local before = #created
Kill(archerA, bear)  -- a neutral kill: no team, no drop
Kill(archerB, Hero(DOTA_TEAM_GOODGUYS, At(5000, 5000)))
campTick()
check(#created == before, "a camp with a monster still alive does not refill")
now = 10
local blocker = Hero(DOTA_TEAM_BADGUYS, At(300, 0))
Kill(bear, blocker)
check(green.respawnAt == 10 + ArenaTiers.Profile(3).respawn, "clearing a camp starts its respawn timer")
now = 80
campTick()
check(#created == before, "no respawn before the timer")
now = 90
campTick()
check(#created == before and green.blocked, "an enemy hero in the camp keeps it empty")
blocker.origin = At(ArenaCamps.BLOCK_RADIUS + 50, 0)
campTick()
local respawned = Spawned(before)
check(#respawned == 3 and not green.blocked, "the camp refills once the heroes step away")

---------------------------------------------------------------------------------- loot

drops = {}
ArenaRewards.misses = {}
local lootCamp = { id = 999, tier = 1, loot = {} }
local hero = Hero(DOTA_TEAM_GOODGUYS, At(9000, -9000))
rollFloat = 0.07  -- above the 5% tier 1 chance, below it after one miss (7.5%)
check(ArenaRewards.CampDrop(lootCamp, At(0, 0), hero, false) == nil and ArenaRewards.misses[999] == 1, "a miss raises the next chance")
check(ArenaRewards.CampDrop(lootCamp, At(0, 0), hero, false) == "item_flask" and ArenaRewards.misses[999] == 0, "...and the next kill drops")
check(ArenaRewards.CampDrop(lootCamp, At(0, 0), nil, false) == nil, "kills without a hero team drop nothing")
rollFloat = 0.99
local greenLoot = { id = 998, tier = 3, loot = biomes.green.monsters.loot }
check(ArenaRewards.CampDrop(greenLoot, At(0, 0), hero, true) == "item_arena_tome_vitality", "a champion always drops from the next tier")
local pool3 = ArenaRewards.Pool(3, biomes.green.monsters.loot[3])
check(pool3[#pool3] == "item_arena_wind_charm", "a biome's own loot joins its tier pool")
check(#drops == 2, "drops go through the camp drop code")

---------------------------------------------------------------------------------- brain

bear, archerA = respawned[1], respawned[2]
local brain = bear.arenaBrain
local fighter = Hero(DOTA_TEAM_GOODGUYS, At(ArenaTiers.Profile(3).aggro + 100, 0))
Think(bear)
check(LastOrder(bear) == nil, "a monster with nobody within its aggro range does nothing")
fighter.origin = At(200, 0)
bear.modifiers.modifier_arena_monster:OnTakeDamage({ unit = bear, attacker = fighter })
check(brain.provoker == fighter and brain.group.target == fighter, "a hit alerts the monster and its camp")
Think(bear)
local order = LastOrder(bear)
check(order.kind == "cast" and order.ability == "arena_green_bramble_slam", "the bear slams a hero inside the slam's radius")
Think(bear)
order = LastOrder(bear)
check(order.kind == "attack" and order.target == fighter, "with the slam on cooldown it attacks")
Think(archerA)
order = LastOrder(archerA)
check(order.kind == "cast_target" and order.ability == "arena_green_thorn_shot" and order.target == fighter,
    "a camp mate joins the fight and shoots the attacker")

-- Leash: dragged past it, the monster walks home healing and ignores everyone on the way.
bear.origin = At(ArenaTiers.Profile(3).leash + 50, 0)
Think(bear)
check(brain.returning and bear:HasModifier("modifier_arena_monster_returning"), "past the leash the monster turns home")
order = LastOrder(bear)
check(order.kind == "move" and Distance(order.target, brain.home) == 0, "...and walks to its post")
bear.attackTarget = fighter
Think(bear)
check(LastOrder(bear).kind == "move", "a returning monster keeps walking home")
bear.origin = brain.home
Think(bear)
check(not brain.returning and not bear:HasModifier("modifier_arena_monster_returning") and LastOrder(bear).kind == "stop",
    "back home it stops and loses the returning buff")
fighter.origin = At(ArenaTiers.Profile(3).leash + 200, 0)
brain.provoker, brain.provokedAt = fighter, now
brain.group.target = nil
local count = #orders
Think(bear)
check(#orders == count, "a target outside the leash is ignored")

-- Abilities chosen from their behaviour, with hints where needed.
local shaman = CreateUnitByName("npc_arena_green_spore_shaman", At(0, 2000), true, nil, nil, DOTA_TEAM_NEUTRALS)
ArenaCamps:SetupMonster(shaman, nil, biomes.green.monsters.monsters.npc_arena_green_spore_shaman, 0, 1, nil, { tier = 3 })
local wounded = CreateUnitByName("npc_arena_green_vine_wolf", At(100, 2000), true, nil, nil, DOTA_TEAM_NEUTRALS)
wounded.health = 400
local foe = Hero(DOTA_TEAM_BADGUYS, At(0, 2300))
shaman.arenaBrain.provoker, shaman.arenaBrain.provokedAt = foe, now
Think(shaman)
order = LastOrder(shaman)
check(order.kind == "cast_point" and order.ability == "arena_green_spore_cloud" and Distance(order.target, foe.origin) == 0,
    "point abilities are cast at the target")
Think(shaman)
order = LastOrder(shaman)
check(order.kind == "cast_target" and order.ability == "arena_green_mending_sap" and order.target == wounded,
    "friendly abilities go to a wounded ally")
local hulk = CreateUnitByName("npc_arena_green_grove_hulk", At(0, 4000), true, nil, nil, DOTA_TEAM_NEUTRALS)
ArenaCamps:SetupMonster(hulk, nil, biomes.green.monsters.monsters.npc_arena_green_grove_hulk, 0, 3, nil, { tier = 4 })
local hulkFoe = Hero(DOTA_TEAM_BADGUYS, At(0, 4300))
hulk.arenaBrain.provoker, hulk.arenaBrain.provokedAt = hulkFoe, now
hulk:FindAbilityByName("arena_green_root_grasp").readyAt = now + 100
Think(hulk)
check(LastOrder(hulk).kind == "attack", "bark skin waits while the hulk is healthy")
hulk.health = hulk.maxHealth * 0.5
Think(hulk)
order = LastOrder(hulk)
check(order.kind == "cast" and order.ability == "arena_green_bark_skin", "bark skin is used below 60% health")
local fakeToggle = { GetBehaviorInt = function() return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_TOGGLE end }
local fakePassive = { GetBehaviorInt = function() return DOTA_ABILITY_BEHAVIOR_PASSIVE end }
-- An order the engine refuses (the ability stays ready) is not repeated at once: the monster attacks.
local refuser = CreateUnitByName("npc_arena_green_thorn_archer", At(0, 6000), true, nil, nil, DOTA_TEAM_NEUTRALS)
ArenaCamps:SetupMonster(refuser, nil, biomes.green.monsters.monsters.npc_arena_green_thorn_archer, 0, 1, nil, { tier = 2 })
local immune = Hero(DOTA_TEAM_BADGUYS, At(0, 6300))
refuser.arenaBrain.provoker, refuser.arenaBrain.provokedAt = immune, now
local refused = refuser:FindAbilityByName("arena_green_thorn_shot")
refuser.CastAbilityOnTarget = function(self, target, ability) orders[#orders + 1] = { unit = self, kind = "cast_target", ability = ability.name } end
Think(refuser)
check(LastOrder(refuser).kind == "cast_target" and refused:IsFullyCastable(), "the brain orders the cast (which the engine refuses here)")
Think(refuser)
check(LastOrder(refuser).kind == "cast_target", "a fresh cast order is given time to start, not replaced by an attack")
now = now + ArenaMonsterAI.TURN_TIME + refused:GetCastPoint()
Think(refuser)
check(LastOrder(refuser).kind == "attack", "a refused cast is not spammed: the monster attacks instead")
now = now + ArenaMonsterAI.RETRY
Think(refuser)
check(LastOrder(refuser).kind == "cast_target", "...and tries the ability again a little later")
immuneTo[immune] = true
now = now + ArenaMonsterAI.RETRY
refuser.attackTarget = nil
Think(refuser)
check(LastOrder(refuser).kind == "attack", "a spell-immune target is attacked instead of cast at")
immuneTo[immune] = nil
check(ArenaMonsterAI.Infer(fakeToggle) == nil and ArenaMonsterAI.Infer(fakePassive) == nil, "toggles and passives are never cast")
-- A dominated monster is handed over: its brain stops.
wounded.team = DOTA_TEAM_GOODGUYS
wounded.arenaBrain = { unit = wounded }
check(ArenaMonsterAI.Think(wounded.arenaBrain) == nil, "a monster that changed team stops thinking")

------------------------------------------------------------------------------ champions

local championCamp = { id = 777, name = "arena_camp_green_3", biome = "green", tier = 3, origin = At(-6000, 0), units = {}, group = {} }
rollFloat = 0
before = #created
ArenaCamps:Spawn(championCamp, 0)
rollFloat = 0.99
local champion = created[before + 1]
check(champion:HasModifier("modifier_arena_champion") and champion:HasModifier("modifier_arena_champion_mighty"),
    "a champion wears the mark and one gift")
check(labels[champion] == "Mighty Champion", "a champion is named over its health bar")
check(champion.maxHealth == math.ceil(1900 * 2.5) and champion.gold == 330 and champion.xp == 200, "a champion is tougher and richer")
check(not created[before + 2]:HasModifier("modifier_arena_champion"), "only one champion per camp")
drops = {}
Kill(champion, Hero(DOTA_TEAM_GOODGUYS, At(-6000, 100)))
check(#drops == 1 and drops[1].item == "item_arena_tome_vitality", "killing a champion always drops a better item")
local mark = MakeModifier(champion, champion, nil, "modifier_arena_champion", {})
check(mark:GetModifierModelScale() == 25 and mark:GetEffectName() == ArenaFxCore.PARTICLES.champion, "the mark makes it bigger and golden")

------------------------------------------------------------------------------- regrowth

now = 120
for _, unit in ipairs(Members(green)) do unit.attackTarget = nil end
local regrown = Members(green)[1]
regrown.health = regrown.maxHealth / 2
fighter.origin = At(5000, 5000)
blocker.origin = At(5000, 5000)
hero.origin = At(5000, 5000)
campTick()
check(regrown.maxHealth == math.ceil(1900 * 1.1) and regrown.health == math.ceil(regrown.maxHealth / 2),
    "an idle camp catches up with the clock and keeps its share of health")

------------------------------------------------------------------------------- the boss

local bossTick = timers[2].callback
local bossState = ArenaBosses.states[1]
heroes = { [0] = Hero(DOTA_TEAM_GOODGUYS, At(-9000, 0)), [1] = Hero(DOTA_TEAM_GOODGUYS, At(-9000, 0)),
    [2] = Hero(DOTA_TEAM_BADGUYS, At(-9000, 0)), [3] = Hero(DOTA_TEAM_BADGUYS, At(-9000, 0)) }
notifications = {}
now = 539
bossTick()
check(#notifications == 0 and not bossState.unit, "nothing before the warning")
now = 540
bossTick()
check(Announced("#arena_green_boss_soon"), "the boss is announced a minute early")
now = 600
before = #created
check(bossTick() == ArenaBosses.THINK_INTERVAL, "the boss timer keeps running")
local boss = bossState.unit
check(boss and boss.name == "npc_arena_green_boss" and Distance(boss.origin, At(6000, 0)) == 0, "the boss appears at its marker")
check(Announced("#arena_green_boss_awakens") and globalSounds[#globalSounds] == "Hero_Treant.Overgrowth.Cast" and fowViewers == 2,
    "its arrival is announced, heard and shown to both teams")
check(boss.maxHealth == 42000 and boss.modifiers.modifier_arena_boss:GetStackCount() == 1, "first appearance at base strength")
local function Level(name) return boss:FindAbilityByName(name):GetLevel() end
check(Level("arena_green_boss_thorn_nova") == 1 and Level("arena_green_boss_root_eruption") == 1
    and Level("arena_green_boss_falling_timber") == 0 and Level("arena_green_boss_call_of_the_grove") == 0,
    "phase 1 knows only its phase 1 abilities")

local challenger = Hero(DOTA_TEAM_GOODGUYS, At(6200, 0))
Think(boss)
order = LastOrder(boss)
check(order.kind == "cast" and order.ability == "arena_green_boss_thorn_nova", "a hero in reach gets a thorn nova")
local lockedUntil = bossState.brain.lockUntil
check(lockedUntil > now, "a telegraphed move locks the next cast")
Think(boss)
check(LastOrder(boss).kind == "attack", "while locked the boss attacks")

boss.health = boss.maxHealth * 0.55
notifications = {}
Think(boss)
check(bossState.phase == 2 and Announced("#arena_green_boss_phase_2"), "below 60% the boss enters phase 2, announced")
check(Level("arena_green_boss_falling_timber") == 2 and Level("arena_green_boss_thorn_nova") == 2, "phase 2 unlocks moves and levels them")
check(boss.modifiers.modifier_arena_boss_enraged:GetStackCount() == 1, "phase 2 enrages it")
boss.health = boss.maxHealth * 0.2
Think(boss)
check(bossState.phase == 3 and Level("arena_green_boss_call_of_the_grove") == 3 and boss.modifiers.modifier_arena_boss_enraged:GetStackCount() == 2,
    "below 25% the boss enters phase 3")

-- Summons from Call of the Grove fight beside it and die with it.
local call = boss:FindAbilityByName("arena_green_boss_call_of_the_grove")
before = #created
call:OnSpellStart()
local sprouts = Spawned(before)
check(#sprouts == 4 and sprouts[1].name == "npc_arena_green_sproutling", "phase 3 calls four sproutlings")
check(sprouts[1].arenaBrain and Distance(sprouts[1].arenaBrain.home, At(6000, 0)) == 0 and sprouts[1].modifiers.modifier_kill,
    "summons use the shared brain around the lair and expire")
check(sprouts[1].arenaBrain.group == bossState.brain.group and bossState.brain.group ~= nil, "summons share the boss's aggro")
call:OnSpellStart()
check(ArenaBosses.CountAdds(boss) == 6, "never more than max_alive summons")

-- Leash: dragged out, it walks home, heals and starts over.
boss.origin = At(6000 + 1500, 0)
Think(boss)
check(bossState.brain.returning, "past its leash the boss turns home")
boss.origin = At(6000, 0)
Think(boss)
check(boss.health == boss.maxHealth and bossState.phase == 1 and not boss:HasModifier("modifier_arena_boss_enraged")
    and Level("arena_green_boss_falling_timber") == 0, "home again it heals and resets to phase 1")
check(ArenaBosses.CountAdds(boss) == 0, "a reset clears its summons")

-- Reward, announcement and return.
goldPaid, drops, notifications = {}, {}, {}
call:OnSpellStart()
local leftover = Spawned(#created - 1)[1]
Kill(boss, challenger)
check(#goldPaid == 2 and goldPaid[1].amount == 1500 and goldPaid[1].hero.team == DOTA_TEAM_GOODGUYS
    and goldPaid[2].hero.team == DOTA_TEAM_GOODGUYS, "every hero on the killing team is paid")
check(heroes[0].experience == 2500 and heroes[2].experience == nil, "...and gains experience; the other team gets nothing")
check(#drops == 2, "the boss drops its items")
check(notifications[1].text == "#arena_team_angels" and notifications[2].text == "#arena_green_boss_slain" and notifications[2].continue,
    "the kill is announced with the team's name")
check(not leftover.alive, "its summons die with it")
check(bossState.unit == nil and bossState.nextSpawn == now + 480, "it returns after the respawn time")
now = bossState.nextSpawn
bossTick()
boss = bossState.unit
check(boss.maxHealth == 63000 and boss.modifiers.modifier_arena_boss:GetStackCount() == 2, "each return is stronger")
goldPaid = {}
Kill(boss, heroes[2])
check(#goldPaid == 2 and goldPaid[1].amount == 1875 and goldPaid[1].hero.team == DOTA_TEAM_BADGUYS, "...and worth more")
now = bossState.nextSpawn
bossTick()
goldPaid = {}
Kill(bossState.unit, nil)
check(#goldPaid == 0 and bossState.nextSpawn == now + 480, "a boss that dies to no team pays nothing but still returns")
now = bossState.nextSpawn
bossTick()
local vanished = bossState.unit
UTIL_Remove(vanished)
now = now + 1
bossTick()
check(bossState.unit == nil and bossState.nextSpawn == now + 480, "a boss removed without a death event is noticed and returns later")

-------------------------------------------------------------------- green ability scripts

now = 2000
local caster = CreateUnitByName("npc_arena_green_thorn_archer", At(0, -5000), true, nil, nil, DOTA_TEAM_NEUTRALS)
local victim = Hero(DOTA_TEAM_GOODGUYS, At(0, -4800))
local shot = caster:FindAbilityByName("arena_green_thorn_shot")
shot:SetLevel(2)
shot.cursorTarget = victim
shot:OnSpellStart()
check(#projectiles == 1 and projectiles[#projectiles].EffectName == biomes.green.fx.particles.thorn_shot, "thorn shot fires a projectile")
damage = {}
shot:OnProjectileHit(victim)
check(damage[1].damage == 90 and victim.modifiers.modifier_arena_green_thorned:GetModifierMoveSpeedBonus_Percentage() == -25,
    "thorn shot hurts and slows by its level's values")

local wolf = CreateUnitByName("npc_arena_green_vine_wolf", At(0, -5000), true, nil, nil, DOTA_TEAM_NEUTRALS)
wolf:FindAbilityByName("arena_green_entangling_bite"):SetLevel(3)
local biteModifier = wolf.modifiers.modifier_arena_green_entangling_bite
check(biteModifier ~= nil and biteModifier:IsHidden(), "entangling bite works through its hidden intrinsic modifier")
damage = {}
victim.modifiers.modifier_arena_green_rooted = nil
for _ = 1, 2 do biteModifier:OnAttackLanded({ attacker = wolf, target = victim }) end
check(#damage == 0 and not victim:HasModifier("modifier_arena_green_rooted"), "no bite before the third attack at level 3")
biteModifier:OnAttackLanded({ attacker = wolf, target = victim })
check(damage[1].damage == 75 and victim.modifiers.modifier_arena_green_rooted.duration == 1.2, "the third attack bites and roots")

local bear2 = CreateUnitByName("npc_arena_green_thicket_bear", At(0, -5000), true, nil, nil, DOTA_TEAM_NEUTRALS)
local slam = bear2:FindAbilityByName("arena_green_bramble_slam")
slam:SetLevel(1)
local circles = Created(ArenaFxCore.PARTICLES.circle)
check(slam:OnAbilityPhaseStart() == true and Created(ArenaFxCore.PARTICLES.circle) == circles + 1, "the slam's wind-up draws its ring")
damage = {}
slam:OnSpellStart()
check(damage[1].victim == victim and damage[1].damage == 100, "the slam hits whoever stayed in the ring")
victim.origin = At(0, -5000 + 400)
damage = {}
slam:OnSpellStart()
check(#damage == 0, "stepping out of the ring dodges the slam")
victim.origin = At(0, -4800)

local shaman2 = CreateUnitByName("npc_arena_green_spore_shaman", At(0, -5000), true, nil, nil, DOTA_TEAM_NEUTRALS)
local spores = shaman2:FindAbilityByName("arena_green_spore_cloud")
spores:SetLevel(2)
spores.cursorPosition = At(0, -4800)
spores:OnSpellStart()
local cloudThinker
for unit in pairs(world) do
    if unit.thinker and unit.modifiers.modifier_arena_green_spore_cloud then cloudThinker = unit end
end
check(cloudThinker and cloudThinker.modifiers.modifier_arena_green_spore_cloud.interval == 0.5, "spore cloud lingers as a thinker")
damage = {}
cloudThinker.modifiers.modifier_arena_green_spore_cloud:OnIntervalThink()
check(damage[1].damage == 20 and victim.modifiers.modifier_arena_green_spore_sickness:GetModifierMiss_Percentage() == 25,
    "the cloud burns and blinds those inside")
cloudThinker.modifiers.modifier_arena_green_spore_cloud:Destroy()
check(cloudThinker.removed, "the cloud cleans up after itself")
local sapAbility = shaman2:FindAbilityByName("arena_green_mending_sap")
sapAbility:SetLevel(1)
local patient = CreateUnitByName("npc_arena_green_sproutling", At(0, -5000), true, nil, nil, DOTA_TEAM_NEUTRALS)
patient.health = 100
sapAbility.cursorTarget = patient
sapAbility:OnSpellStart()
check(patient.health == 250 and patient.modifiers.modifier_arena_green_mending_sap:GetModifierConstantHealthRegen() == 10, "sap heals and regenerates")

local hulk2 = CreateUnitByName("npc_arena_green_grove_hulk", At(0, -5000), true, nil, nil, DOTA_TEAM_NEUTRALS)
local grasp = hulk2:FindAbilityByName("arena_green_root_grasp")
grasp:SetLevel(4)
grasp.cursorTarget = victim
victim.modifiers.modifier_arena_green_rooted = nil
grasp:OnSpellStart()
local held = victim.modifiers.modifier_arena_green_rooted
check(held and held.duration == 2 and held.dps == 115 and held.interval == 0.5, "root grasp roots and burns")
victim.modifiers.modifier_arena_green_rooted = nil
victim:AddNewModifier(wolf, nil, "modifier_arena_green_rooted", { duration = 1 })
check(not victim.modifiers.modifier_arena_green_rooted.interval, "a bite root does not burn")
grasp:OnSpellStart()
held = victim.modifiers.modifier_arena_green_rooted
check(held.dps == 115 and held.interval == 0.5, "root grasp on an already rooted target still starts its burn")
damage = {}
held:OnIntervalThink()
check(damage[1].damage == 57.5, "the root burns half its damage per second every half second")
local barkAbility = hulk2:FindAbilityByName("arena_green_bark_skin")
barkAbility:SetLevel(2)
barkAbility:OnSpellStart()
check(hulk2.modifiers.modifier_arena_green_bark_skin:GetModifierPhysicalArmorBonus() == 12, "bark skin armours the hulk")

local bloom = CreateUnitByName("npc_arena_green_strangler_bloom", At(0, -5000), true, nil, nil, DOTA_TEAM_NEUTRALS)
local spit = bloom:FindAbilityByName("arena_green_venom_spit")
spit:SetLevel(1)
spit.cursorTarget = victim
spit:OnSpellStart()
damage = {}
spit:OnProjectileHit(victim)
local venomModifier = victim.modifiers.modifier_arena_green_venom
check(damage[1].damage == 40 and venomModifier.interval == 1 and venomModifier:GetModifierMoveSpeedBonus_Percentage() == -15, "venom spit poisons and slows")
venomModifier:OnIntervalThink()
check(damage[2].damage == 20, "the poison ticks each second")

-- Boss moves: each is dodgeable and each resolves through the shared delayed strike.
local warden = CreateUnitByName("npc_arena_green_boss", At(0, -8000), true, nil, nil, DOTA_TEAM_NEUTRALS)
local target = Hero(DOTA_TEAM_GOODGUYS, At(300, -8000))
local eruption = warden:FindAbilityByName("arena_green_boss_root_eruption")
eruption:SetLevel(1)
eruption:OnSpellStart()
local strikes = {}
for unit in pairs(world) do
    if unit.thinker and unit.modifiers.modifier_arena_delayed_strike then strikes[#strikes + 1] = unit end
end
check(#strikes == 1 and strikes[1].modifiers.modifier_arena_delayed_strike.duration == 1.6
    and Distance(strikes[1].origin, target.origin) == 0, "root eruption marks the hero's spot for 1.6 seconds")
damage = {}
strikes[1].modifiers.modifier_arena_delayed_strike:Destroy()
check(damage[1].victim == target and damage[1].damage == 350 and target:HasModifier("modifier_arena_green_rooted") and strikes[1].removed,
    "standing still gets you rooted")
eruption:OnSpellStart()
for unit in pairs(world) do
    if unit.thinker and unit.modifiers.modifier_arena_delayed_strike then strikes[1] = unit end
end
target.origin = At(300 + 400, -8000)
damage = {}
strikes[1].modifiers.modifier_arena_delayed_strike:Destroy()
check(#damage == 0, "walking out of the ring dodges the eruption")
eruption:OnSpellStart()
for unit in pairs(world) do
    if unit.thinker and unit.modifiers.modifier_arena_delayed_strike then strikes[1] = unit end
end
warden.alive = false
damage = {}
strikes[1].modifiers.modifier_arena_delayed_strike:Destroy()
check(#damage == 0 and strikes[1].removed, "a dead boss's pending strikes fizzle")
warden.alive = true

local nova = warden:FindAbilityByName("arena_green_boss_thorn_nova")
nova:SetLevel(2)
target.origin = At(200, -8000)
nova:OnSpellStart()
damage = {}
nova:OnChannelFinish(true)
check(#damage == 0, "stunning the boss during thorn nova cancels it")
nova:OnSpellStart()
nova:OnChannelFinish(false)
check(damage[1].damage == 700 and target:HasModifier("modifier_arena_green_thorned"), "a finished thorn nova hits the ring")

local timber = warden:FindAbilityByName("arena_green_boss_falling_timber")
timber:SetLevel(2)
timber.cursorPosition = At(1000, -8000)
target.origin = At(600, -8000 + 50)
timber:OnSpellStart()
for unit in pairs(world) do
    if unit.thinker and unit.modifiers.modifier_arena_delayed_strike then strikes[1] = unit end
end
local line = strikes[1].modifiers.modifier_arena_delayed_strike
check(line.data.shape == "line" and line.data.x2 == 1100 and line.duration == 1.2, "falling timber marks a line toward the target")
damage = {}
line:Destroy()
check(damage[1].victim == target and damage[1].damage == 600 and target.modifiers.modifier_stunned.duration == 1.2,
    "the falling tree crushes and stuns whoever stays on the line")

------------------------------------------------------------------------- legacy fallback

for unit in pairs(world) do world[unit] = nil end
ArenaCamps.started = false
ArenaCamps.camps = {}
queries = {}
markers = { creep_camp = {} }
fountains = { Marker(0, 0), Marker(10000, 10000) }
for index = 1, 20 do
    -- 20 legacy markers walking away from the first fountain; the sixth says tier 3 itself.
    markers.creep_camp[index] = Marker(index * 200, 0, index == 6 and { CreepType = 3 } or nil)
end
timers = {}
ArenaCamps:Init()
check(ArenaCamps.source == "legacy" and #ArenaCamps.camps == 20, "with no arena markers the creep_camp markers are used")
local tally = {}
for _, camp in ipairs(ArenaCamps.camps) do
    check(camp.biome == "wilds" and camp.legacy, "legacy camps are wilds camps")
    tally[camp.tier] = (tally[camp.tier] or 0) + 1
end
local nearest = ArenaCamps.camps[1]
check(nearest.tier == 1 and ArenaCamps.camps[20].tier == 4, "nearest the fountains is easy, farthest is elite")
check(ArenaCamps.camps[6].tier == 3, "a marker with CreepType set keeps that tier")
check(tally[1] == 5 and tally[2] == 6 and tally[3] == 6 and tally[4] == 3, "30/30/25/15 split of 20 markers (one overridden)")
check(ArenaMarkers.LegacyTier(1, 3) == 1 and ArenaMarkers.LegacyTier(3, 3) == 3, "small maps still rank sensibly")
now = 3000
before = #created
timers[1].callback()
check(#created > before, "legacy camps spawn monsters, so the current map is populated again")
check(Logged("ranked by distance to ent_dota_fountain"), "the console says what the legacy ranking measured from")
fountains = {}
spawnPoints = { Marker(4000, 0) }
local fromSpawn = ArenaMarkers.LegacyCamps()
check(fromSpawn[1].origin.x == 4000 and fromSpawn[1].tier == 1, "without fountains the hero spawn points count as bases")
spawnPoints = {}
local fallback = ArenaMarkers.LegacyCamps()
local byX = {}
for _, camp in ipairs(fallback) do byX[camp.origin.x] = camp.tier end
check(byX[4000] == 1 and byX[200] == 4, "without fountains the edge of the map counts as home")

---------------------------------------------------------------------- precache and wiring

precached = { units = {}, resources = {} }
ArenaBiomes.Precache({})
for name in pairs(UNIT_KV) do
    check(precached.units[name], name .. " is precached")
end
check(precached.units.npc_dota_neutral_black_dragon, "stock wilds creeps are precached")
check(precached.resources[biomes.green.fx.particles.root_burst] == "particle" and precached.resources[ArenaFxCore.PARTICLES.circle] == "particle",
    "biome and shared particles are precached")
check(precached.resources["soundevents/game_sounds_heroes/game_sounds_treant.vsndevts"] == "soundfile", "biome sound files are precached")

local function Contains(path, text)
    local file = assert(io.open(path, "rb"))
    local body = file:read("*a")
    file:close()
    return body:find(text, 1, true) ~= nil
end
check(Contains(VSCRIPTS .. "precache/precache.lua", 'require("arena/core/biomes").Precache(context)'), "precache.lua precaches the biomes")
check(Contains(VSCRIPTS .. "setting/aa.lua", "InitModule(ArenaWorld)"), "the match start starts the arena world")
check(not Contains(VSCRIPTS .. "setting/aa.lua", "InitModule(CreepCamps)"), "the old camp spawner no longer runs beside it")
check(Contains(VSCRIPTS .. "setting/events.lua", "ArenaWorld.OnEntityKilled(killedUnit, attacker)"), "deaths reach the arena world")
check(Contains(VSCRIPTS .. "addon_game_mode.lua", "require('arena/index')"), "the addon loads the arena world")
for _, biome in ipairs({ "green", "desert", "ice", "lava" }) do
    check(Contains("game/angel_arena/scripts/npc/npc_units_custom.txt", '#base "units/arena/arena_' .. biome .. '_units.txt"'),
        "npc_units_custom.txt includes the " .. biome .. " units")
    check(Contains("game/angel_arena/scripts/npc/npc_abilities_custom.txt", '#base "abilities/arena/arena_' .. biome .. '_abilities.txt"'),
        "npc_abilities_custom.txt includes the " .. biome .. " abilities")
end

------------------------------------------------------ tooltips for every visible modifier

local mirror = assert(io.open("content/angel_arena/addon_english_utf8.txt", "rb"))
local tokens = mirror:read("*a")
mirror:close()
local function Visible(name)
    local definition = rawget(_G, name)
    return definition and not definition.IsHidden(MakeModifier(MakeUnit("x", At(0, 0), 4), nil, nil, name, {}))
end
for name, path in pairs(linked) do
    if path:find("^arena/") and Visible(name) then
        check(tokens:find('"DOTA_Tooltip_' .. name .. '"', 1, true) and tokens:find('"DOTA_Tooltip_' .. name .. '_Description"', 1, true),
            name .. " is visible and has a tooltip (python tools/biomes/build_biomes.py)")
    end
end
for phase = 2, #biomes.green.boss.phases do
    check(tokens:find('"arena_green_boss_phase_' .. phase .. '"', 1, true), "phase " .. phase .. " has an announcement")
end

-------------------------------------------- the client loads modifier scripts on their own

-- A fresh environment with only what the client has: no Timers, Gold, GameMode, ArenaCamps...
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
    env.ParticleManager = ParticleManager
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

local clientScripts = { "arena/core/modifiers" }
for _, script in ipairs(abilityScripts) do clientScripts[#clientScripts + 1] = script end
check(#clientScripts >= 2, "the green ability script is among those loaded client-side")
for _, script in ipairs(clientScripts) do
    local env = ClientSandbox()
    local chunk = assert(loadfile(VSCRIPTS .. script .. ".lua"))
    setfenv(chunk, env)
    local ok, message = pcall(chunk)
    check(ok, script .. ".lua loads on the client by itself: " .. tostring(message))
    local count = 0
    for name, path in pairs(env.links) do
        if path == script .. ".lua" then
            count = count + 1
            local definition = rawget(env, name)
            check(type(definition) == "table", name .. " exists on the client")
            -- What the client asks a modifier: its properties, effects and visibility.
            local fakeAbility = { IsNull = function() return false end, GetSpecialValueFor = function() return 3 end }
            local instance = setmetatable({ GetAbility = function() return fakeAbility end, GetStackCount = function() return 1 end,
                GetParent = function() return {} end }, { __index = definition })
            for _, method in ipairs({ "OnCreated", "IsHidden", "IsPurgable", "DeclareFunctions", "CheckState", "GetEffectName",
                "GetStatusEffectName", "GetModifierMoveSpeedBonus_Percentage", "GetModifierModelScale", "GetModifierMiss_Percentage",
                "GetModifierPhysicalArmorBonus", "GetModifierConstantHealthRegen", "GetModifierAttackSpeedBonus_Constant",
                "OnTooltip", "OnAttackLanded", "OnTakeDamage" }) do
                if definition[method] then
                    local called, failure = pcall(definition[method], instance, {})
                    check(called, name .. ":" .. method .. " runs on the client: " .. tostring(failure))
                end
            end
        end
    end
    check(count > 0, script .. ".lua links its own modifiers")
end

print = realPrint
print(string.format("Arena biome camps, AI, champions, bosses, green abilities and client loading: %d checks passed", passed))
