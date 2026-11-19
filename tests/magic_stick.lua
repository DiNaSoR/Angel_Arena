local server = true

function class(definition) return definition end
function IsServer() return server end
function LinkLuaModifier() end

PATTACH_ABSORIGIN_FOLLOW = 1
MODIFIER_EVENT_ON_SPENT_MANA = 223
local effect_releases = 0
ParticleManager = {
    CreateParticle = function(_, effect)
        assert(effect == "particles/items2_fx/magic_stick.vpcf")
        return 1
    end,
    ReleaseParticleIndex = function(_, index)
        assert(index == 1)
        effect_releases = effect_releases + 1
    end,
}

dofile("game/angel_arena/scripts/vscripts/items/imba/item_stick.lua")

local vector_metatable = {}
local function position(x)
    return setmetatable({ x = x }, vector_metatable)
end
vector_metatable.__sub = function(a, b)
    return { Length2D = function() return math.abs(a.x - b.x) end }
end
local holder = {
    health_restored = 0,
    mana_restored = 0,
    alive = true,
    IsAlive = function(self) return self.alive end,
    GetTeamNumber = function() return 2 end,
    GetAbsOrigin = function() return position(0) end,
    Heal = function(self, amount) self.health_restored = self.health_restored + amount end,
    GiveMana = function(self, amount) self.mana_restored = self.mana_restored + amount end,
    EmitSound = function(_, sound) assert(sound == "DOTA_Item.MagicStick.Activate") end,
}
local enemy = {
    GetTeamNumber = function() return 3 end,
    x = 2400,
    GetAbsOrigin = function(self) return position(self.x) end,
}
local item = setmetatable({
    charges = 0,
    IsNull = function() return false end,
    IsInBackpack = function(self) return self.backpack end,
    GetCaster = function() return holder end,
    GetCurrentCharges = function(self) return self.charges end,
    SetCurrentCharges = function(self, charges) self.charges = charges end,
    GetSpecialValueFor = function(_, key)
        return assert(({ restore_per_charge = 15, charge_radius = 2400, max_charges = 12 })[key])
    end,
}, { __index = item_imba_magic_stick })
local modifier = setmetatable({
    GetParent = function() return enemy end,
    GetCaster = function() return holder end,
    GetAbility = function() return item end,
}, { __index = modifier_aa_magic_stick_charge })
local cast = {
    unit = enemy,
    ability = { GetManaCost = function(_, level)
        assert(level == -1)
        return 5
    end },
}

assert(modifier:DeclareFunctions()[1] == MODIFIER_EVENT_ON_SPENT_MANA)
item:OnSpellStart()
assert(effect_releases == 0)

modifier:OnSpentMana({ unit = holder, ability = cast.ability, cost = 5 })
modifier:OnSpentMana({ unit = enemy, ability = cast.ability, cost = 0 })
enemy.x = 2401
modifier:OnSpentMana(cast)
enemy.x = 2400
item.backpack = true
modifier:OnSpentMana(cast)
item.backpack = false
holder.alive = false
modifier:OnSpentMana(cast)
holder.alive = true
server = false
modifier:OnSpentMana(cast)
server = true
assert(item.charges == 0)

for _ = 1, 13 do
    modifier:OnSpentMana(cast)
end
assert(item.charges == 12)
item:OnSpellStart()
assert(item.charges == 0)
assert(holder.health_restored == 180 and holder.mana_restored == 180)
assert(effect_releases == 1)

print("Magic Stick charge, range, inventory and restoration checks passed")
