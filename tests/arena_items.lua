-- Loads the Angel Arena item scripts against the generated definitions with a stubbed engine.
-- Run from the repository root: lua5.1 tests/arena_items.lua

local server = true
local now = 0
local roll = true
local damage_log = {}

-- Engine constants (MODIFIER_*, DOTA_*, ...) only need to be distinct numbers here.
local next_constant = 1000
setmetatable(_G, {
    __index = function(globals, key)
        if type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
            next_constant = next_constant + 1
            rawset(globals, key, next_constant)
            return next_constant
        end
    end,
})
DOTA_DAMAGE_FLAG_NONE = 0
DOTA_DAMAGE_FLAG_REFLECTION = 16
DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL = 32
DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION = 64

bit = { band = function(a, b)
    local result, place = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then result = result + place end
        a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
    end
    return result
end }

function class(definition) return definition end
function IsServer() return server end
function LinkLuaModifier() end
function PrecacheResource() end
function RollPercentage() return roll end
function ApplyDamage(event) table.insert(damage_log, event) end
function FindClearSpaceForUnit() end
function DoCleaveAttack() end
function FindUnitsInRadius() return {} end
local vector = {}
vector.__unm = function(v) return setmetatable({ x = -v.x, y = -v.y, z = -v.z }, vector) end
function Vector(x, y, z) return setmetatable({ x = x, y = y, z = z }, vector) end
function ScreenShake() end
GameRules = { GetGameTime = function() return now end }

-- Effects are not checked here beyond being callable: every particle call is accepted and counted.
local effects = 0
ParticleManager = setmetatable({}, { __index = function()
    return function()
        effects = effects + 1
        return effects
    end
end })
ProjectileManager = { CreateTrackingProjectile = function() effects = effects + 1 end }
Timers = { CreateTimer = function(_, _, callback) callback() end }

-- A small KeyValues reader, enough for the generated item file.
function LoadKeyValues(path)
    local file = assert(io.open("game/angel_arena/" .. path, "rb"))
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
            if not key or (brace and key == "}") then
                return result
            end
            local value, opens = token()
            result[key] = opens and block() or value
        end
    end
    token() -- root name
    token() -- opening brace
    return block()
end

package.path = "game/angel_arena/scripts/vscripts/?.lua;" .. package.path

-- The client can load the modifier script before any item script, so it must stand alone.
dofile("game/angel_arena/scripts/vscripts/items/arena/arena_modifiers.lua")
assert(ArenaItems and modifier_arena_item, "arena_modifiers.lua must load without arena_items.lua")
dofile("game/angel_arena/scripts/vscripts/items/arena/arena_items.lua")

local definitions = LoadKeyValues("scripts/npc/items/arena/arena_items.txt")

--------------------------------------------------------------------------------- test doubles

local function unit(team, hero)
    local modifiers = {}
    local self = {
        team = team, health = 1000, max_health = 1000, mana = 500, alive = true, healed = 0,
        modifiers = modifiers,
    }
    function self:GetTeamNumber() return self.team end
    function self:IsNull() return false end
    function self:IsBuilding() return false end
    function self:IsOther() return false end
    function self:IsIllusion() return false end
    function self:IsRealHero() return hero end
    function self:IsHero() return hero end
    function self:IsAlive() return self.alive end
    function self:IsRangedAttacker() return false end
    function self:GetStatusResistance() return 0 end
    function self:GetHealth() return self.health end
    function self:SetHealth(value) self.health = value end
    function self:GetMaxHealth() return self.max_health end
    function self:GetHealthPercent() return 100 * self.health / self.max_health end
    function self:GetMana() return self.mana end
    function self:Script_ReduceMana(amount) self.mana = self.mana - amount end
    function self:Heal(amount) self.healed = self.healed + amount end
    function self:EmitSound() end
    function self:Purge() end
    function self:CalculateStatBonus() end
    function self:GetAbsOrigin() return Vector(0, 0, 0) end
    function self:GetForwardVector() return Vector(1, 0, 0) end
    function self:FindModifierByName(name) return modifiers[name] end
    function self:AddNewModifier(caster, ability, name, data)
        local class_table = assert(_G[name], "modifier is not defined: " .. name)
        local stacks = 0
        local modifier = setmetatable({}, { __index = class_table })
        function modifier:GetParent() return self.parent end
        function modifier:GetCaster() return caster end
        function modifier:GetAbility() return ability end
        function modifier:GetStackCount() return stacks end
        function modifier:SetStackCount(count) stacks = count end
        function modifier:StartIntervalThink() end
        function modifier:SetHasCustomTransmitterData() end
        function modifier:IsNull() return self.destroyed == true end
        function modifier:Destroy()
            self.destroyed = true
            if self.OnDestroy then self:OnDestroy() end
        end
        modifier.parent = self
        modifiers[name] = modifier
        if modifier.OnCreated then modifier:OnCreated(data or {}) end
        return modifier
    end
    return self
end

local function ability(name, holder)
    local self = { charges = 1, cooldown = 0 }
    function self:GetAbilityName() return name end
    function self:GetCaster() return holder end
    function self:GetAbilityTextureName() return "arena/" .. name end
    function self:GetCurrentCharges() return self.charges end
    function self:SetCurrentCharges(count) self.charges = count end
    function self:IsCooldownReady() return self.cooldown <= now end
    function self:StartCooldown(seconds) self.cooldown = now + seconds end
    return setmetatable(self, { __index = assert(_G[name], "item class is not defined: " .. name) })
end

local function equip(name, holder)
    local item = ability(name, holder)
    return item, holder:AddNewModifier(holder, item, item:GetIntrinsicModifierName(), {})
end

-------------------------------------------------------------------------------------- checks

-- Every generated item has a class, and every mechanic, active and consumable it names exists.
local items = 0
for name, definition in pairs(definitions) do
    if definition.BaseClass == "item_lua" then
        items = items + 1
        local item = assert(_G[name], name .. " has no Lua class")
        for mechanic in string.gmatch(definition.ArenaMechanics or "", "%S+") do
            assert(_G["modifier_arena_" .. mechanic], name .. " names unknown mechanic " .. mechanic)
        end
        if definition.ArenaConsume or definition.ArenaActive then
            assert(item.OnSpellStart, name .. " cannot be used")
        end
        assert((item.GetIntrinsicModifierName ~= nil) == (definition.ArenaConsume == nil), name)
    end
end
assert(items == 99, "expected 99 items, found " .. items)

-- Plain stats: all-stats is added to each attribute, and unused stats are zero.
local hero = unit(2, true)
local _, stats = equip("item_arena_spellward_shroud", hero)
assert(stats:GetModifierBonusStats_Strength() == 8)
assert(stats:GetModifierMagicalResistanceBonus() == 30)
assert(stats:GetModifierPreAttack_BonusDamage() == 0)

-- Mechanics are added with the item and removed with it.
local reaver_owner = unit(2, true)
local _, reaver = equip("item_arena_soul_reaver", reaver_owner)
assert(reaver_owner.modifiers.modifier_arena_souls and reaver_owner.modifiers.modifier_arena_crit)
local souls = reaver_owner.modifiers.modifier_arena_souls
local creep, enemy_hero = unit(3, false), unit(3, true)
souls:OnDeath({ unit = creep, attacker = reaver_owner })
souls:OnDeath({ unit = enemy_hero, attacker = reaver_owner })
assert(souls:GetStackCount() == 4)
assert(souls:GetModifierPreAttack_BonusDamage() == 20)
for _ = 1, 20 do souls:OnDeath({ unit = enemy_hero, attacker = reaver_owner }) end
assert(souls:GetStackCount() == 30, "souls are capped")
souls:OnDeath({ unit = reaver_owner, attacker = creep })
assert(souls:GetStackCount() == 15, "half the souls are lost on death")
souls:OnDeath({ unit = unit(2, true), attacker = reaver_owner })
assert(souls:GetStackCount() == 15, "allies are not harvested")
local crit = reaver_owner.modifiers.modifier_arena_crit
assert(crit:GetModifierPreAttack_CriticalStrike({ target = creep, record = 7 }) == 180)
local before = effects
crit:OnAttackLanded({ attacker = reaver_owner, target = creep, record = 8 })
assert(effects == before, "another swing landing is not the critical one")
crit:OnAttackLanded({ attacker = reaver_owner, target = creep, record = 7 })
assert(effects > before)
before = effects
crit:OnAttackLanded({ attacker = reaver_owner, target = creep, record = 7 })
assert(effects == before, "one critical hit, one flourish")
reaver:Destroy()
assert(souls.destroyed and crit.destroyed)

-- Lifesteal heals from attack damage dealt to enemies only.
local vampire = unit(2, true)
equip("item_arena_blood_vial", vampire)
local steal = vampire.modifiers.modifier_arena_lifesteal
steal:OnTakeDamage({ attacker = vampire, unit = creep, damage = 200, damage_category = DOTA_DAMAGE_CATEGORY_ATTACK })
assert(vampire.healed == 24)
steal:OnTakeDamage({ attacker = vampire, unit = creep, damage = 200, damage_category = DOTA_DAMAGE_CATEGORY_SPELL })
steal:OnTakeDamage({ attacker = creep, unit = vampire, damage = 200, damage_category = DOTA_DAMAGE_CATEGORY_ATTACK })
assert(vampire.healed == 24)

-- Bash cannot trigger again until its interval has passed.
local judge = unit(2, true)
equip("item_arena_judges_gavel", judge)
local bash = judge.modifiers.modifier_arena_bash
modifier_bashed = {}
damage_log = {}
bash:OnAttackLanded({ attacker = judge, target = creep })
bash:OnAttackLanded({ attacker = judge, target = creep })
assert(#damage_log == 1 and damage_log[1].damage == 60)
now = 3
bash:OnAttackLanded({ attacker = judge, target = creep })
assert(#damage_log == 2)
roll = false
now = 10
bash:OnAttackLanded({ attacker = judge, target = creep })
assert(#damage_log == 2, "a failed roll does not bash")
roll = true

-- Thorns returns a share of attack damage, and never answers reflected damage.
local spiked = unit(2, true)
equip("item_arena_abyssal_thornmail", spiked)
local thorns = spiked.modifiers.modifier_arena_thorns
damage_log = {}
thorns:OnTakeDamage({ unit = spiked, attacker = creep, damage = 100, damage_category = DOTA_DAMAGE_CATEGORY_ATTACK })
assert(#damage_log == 1 and damage_log[1].damage == 50 and damage_log[1].victim == creep)
thorns:OnTakeDamage({ unit = spiked, attacker = creep, damage = 100, damage_category = DOTA_DAMAGE_CATEGORY_ATTACK,
    damage_flags = DOTA_DAMAGE_FLAG_REFLECTION })
assert(#damage_log == 1)

-- Guardian angel saves its wearer once, then waits out the item's cooldown.
local saved = unit(2, true)
local bulwark = equip("item_arena_bulwark_of_heaven", saved)
local guardian = saved.modifiers.modifier_arena_guardian
assert(guardian:GetMinHealth() == 1)
saved.health = 1
guardian:OnTakeDamage({ unit = saved, attacker = creep, damage = 999 })
assert(saved.health == 400 and guardian:GetMinHealth() == 0)
saved.health = 1
guardian:OnTakeDamage({ unit = saved, attacker = creep, damage = 999 })
assert(saved.health == 1, "no second save while on cooldown")
now = now + 150
assert(bulwark:IsCooldownReady() and guardian:GetMinHealth() == 1)

-- Berserk only applies below its health threshold.
local cornered = unit(2, true)
equip("item_arena_imp_horns", cornered)
local berserk = cornered.modifiers.modifier_arena_berserk
assert(berserk:GetModifierPreAttack_BonusDamage() == 0)
cornered.health = 390
assert(berserk:GetModifierPreAttack_BonusDamage() == 40 and berserk:GetModifierAttackSpeedBonus_Constant() == 40)

-- The void shell absorbs exactly its pool and then ends.
local warded = unit(2, true)
local mantle = equip("item_arena_mantle_of_the_void", warded)
mantle:OnSpellStart()
local shell = warded.modifiers.modifier_arena_void_shell
assert(shell:GetModifierTotal_ConstantBlock({ damage = 600 }) == 600)
assert(shell:GetModifierTotal_ConstantBlock({ damage = 600 }) == 300 and shell.destroyed)

-- Tomes add to a permanent total and use up one charge each.
local student = unit(2, true)
local removed
function student:RemoveItem(item) removed = item end
local tome = ability("item_arena_tome_stoneskin", student)
tome.charges = 2
tome:OnSpellStart()
assert(tome.charges == 1 and removed == nil)
tome:OnSpellStart()
assert(removed == tome)
assert(student.modifiers.modifier_arena_tome_armor:GetModifierPhysicalArmorBonus() == 3)

-- Only real heroes can study.
local courier = unit(2, false)
function courier:RemoveItem() error("a courier must not consume a tome") end
ability("item_arena_tome_vitality", courier):OnSpellStart()
assert(courier.modifiers.modifier_arena_tome_health == nil)

-- A potion's numbers survive the item: they are carried by the buff itself.
local drinker = unit(2, true)
function drinker:RemoveItem() end
ability("item_arena_demons_blood", drinker):OnSpellStart()
local potion = drinker.modifiers.modifier_arena_potion
assert(potion:GetModifierPreAttack_BonusDamage() == 60 and potion:GetModifierPhysicalArmorBonus() == -6)
assert(potion:AddCustomTransmitterData().texture == "arena/item_arena_demons_blood")

print("Angel Arena item classes, mechanics, actives and consumables passed")
