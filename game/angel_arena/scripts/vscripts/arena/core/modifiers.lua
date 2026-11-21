-- Modifiers shared by every arena biome: the monster brain hook, walking home, champions and
-- bosses, plus the generic delayed strike that biome abilities use for telegraphed attacks.
--
-- The client loads this file on its own the first time it sees one of these modifiers, so it
-- requires everything it needs itself and keeps server-only work behind IsServer().

require("arena/core/fx")

if ArenaModifiers then
    return ArenaModifiers
end

ArenaModifiers = {}

local FILE = "arena/core/modifiers.lua"

-- Numbers the champion affixes use. arena/core/champions.lua reads them from here so the
-- tooltip, the client and the server agree.
ArenaModifiers.CHAMPION = {
    model_scale = 25,           -- percent larger
    mighty_damage = 35,         -- percent more attack damage
    swift_move = 30,            -- percent movement speed
    swift_attack = 70,          -- attack speed
    vampiric_lifesteal = 40,    -- percent of attack damage healed
    stoneskin_armor = 10,
    stoneskin_magic = 30,       -- percent magic resistance
}
ArenaModifiers.RETURNING = { move = 50, regen = 8 }  -- percent speed, percent max health per second
ArenaModifiers.ENRAGED = { attack = 35, move = 8, damage = 15 }  -- per stack (one stack per phase after the first)
ArenaModifiers.BOSS = { status_resistance = 25 }

-- addon_init.lua requires this file before the game mode loads, on the server and on every client,
-- so the shared modifiers are linked everywhere. Nothing here may need game-mode globals at load
-- time, and `class` may not exist yet that early: a plain table is a valid modifier class too.
local function Define(name, hidden)
    local modifier = class and class({}) or {}
    function modifier:IsHidden() return hidden end
    function modifier:IsPurgable() return false end
    _G[name] = modifier
    LinkLuaModifier(name, FILE, LUA_MODIFIER_MOTION_NONE)
    return modifier
end

local function IsEnemy(parent, unit)
    return unit and not unit:IsNull() and unit.GetTeamNumber and unit:GetTeamNumber() ~= parent:GetTeamNumber()
end

------------------------------------------------------------------------------- monster brain

-- Every camp monster, summon and boss carries this. It tells the brain (arena/core/monster_ai.lua)
-- who hit it, so the whole group answers an attack on any one of its members.
local monster = Define("modifier_arena_monster", true)

function monster:RemoveOnDeath() return true end

function monster:DeclareFunctions()
    return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function monster:OnTakeDamage(event)
    if not IsServer() then return end
    local parent = self:GetParent()
    if event.unit ~= parent or not IsEnemy(parent, event.attacker) then return end
    local brain = parent.arenaBrain
    if brain then
        brain.provoker = event.attacker
        brain.provokedAt = GameRules:GetGameTime()
        if brain.group then
            brain.group.target = event.attacker
            brain.group.targetAt = brain.provokedAt
        end
    end
end

-- Shown while a monster walks back to its post: it moves faster, ignores collisions and heals.
local returning = Define("modifier_arena_monster_returning", false)

function returning:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE }
end
function returning:GetModifierMoveSpeedBonus_Percentage() return ArenaModifiers.RETURNING.move end
function returning:GetModifierHealthRegenPercentage() return ArenaModifiers.RETURNING.regen end
function returning:CheckState()
    return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end

------------------------------------------------------------------------------------ champions

-- Every champion has this mark plus exactly one affix modifier below.
local champion = Define("modifier_arena_champion", false)

function champion:DeclareFunctions()
    return { MODIFIER_PROPERTY_MODEL_SCALE }
end
function champion:GetModifierModelScale() return ArenaModifiers.CHAMPION.model_scale end
function champion:GetEffectName() return ArenaFxCore.PARTICLES.champion end
function champion:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

local mighty = Define("modifier_arena_champion_mighty", false)
function mighty:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function mighty:GetModifierBaseDamageOutgoing_Percentage() return ArenaModifiers.CHAMPION.mighty_damage end
function mighty:GetStatusEffectName() return ArenaFxCore.STATUS.mighty end
function mighty:StatusEffectPriority() return 10 end

local swift = Define("modifier_arena_champion_swift", false)
function swift:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function swift:GetModifierMoveSpeedBonus_Percentage() return ArenaModifiers.CHAMPION.swift_move end
function swift:GetModifierAttackSpeedBonus_Constant() return ArenaModifiers.CHAMPION.swift_attack end
function swift:GetEffectName() return ArenaFxCore.PARTICLES.returning end
function swift:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

local vampiric = Define("modifier_arena_champion_vampiric", false)
function vampiric:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_PROPERTY_TOOLTIP } end
function vampiric:OnTooltip() return ArenaModifiers.CHAMPION.vampiric_lifesteal end
function vampiric:OnAttackLanded(event)
    if not IsServer() then return end
    local parent = self:GetParent()
    if event.attacker ~= parent or not IsEnemy(parent, event.target) or not event.damage then return end
    parent:Heal(event.damage * ArenaModifiers.CHAMPION.vampiric_lifesteal / 100, nil)
    ArenaFxCore.On(ArenaFxCore.PARTICLES.lifesteal, parent)
end

local stoneskin = Define("modifier_arena_champion_stoneskin", false)
function stoneskin:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS }
end
function stoneskin:GetModifierPhysicalArmorBonus() return ArenaModifiers.CHAMPION.stoneskin_armor end
function stoneskin:GetModifierMagicalResistanceBonus() return ArenaModifiers.CHAMPION.stoneskin_magic end
function stoneskin:GetStatusEffectName() return ArenaFxCore.STATUS.stoneskin end
function stoneskin:StatusEffectPriority() return 10 end

--------------------------------------------------------------------------------------- bosses

-- Every biome boss has this. Its stack count is how many times the boss has come back.
local boss = Define("modifier_arena_boss", false)

function boss:DeclareFunctions()
    return { MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING, MODIFIER_PROPERTY_TOOLTIP }
end
function boss:GetModifierStatusResistanceStacking() return ArenaModifiers.BOSS.status_resistance end
function boss:OnTooltip() return self:GetStackCount() end

-- Added when a boss enters its second phase; one stack per phase after the first.
local enraged = Define("modifier_arena_boss_enraged", false)

function enraged:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    }
end
function enraged:GetModifierAttackSpeedBonus_Constant() return ArenaModifiers.ENRAGED.attack * self:GetStackCount() end
function enraged:GetModifierMoveSpeedBonus_Percentage() return ArenaModifiers.ENRAGED.move * self:GetStackCount() end
function enraged:GetModifierBaseDamageOutgoing_Percentage() return ArenaModifiers.ENRAGED.damage * self:GetStackCount() end
function enraged:GetEffectName() return ArenaFxCore.PARTICLES.enraged end
function enraged:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

------------------------------------------------------------------------------ delayed strike

-- A telegraphed hit. A biome ability creates it with CreateModifierThinker at the spot that
-- will be struck; players see the warning for the thinker's duration, then the ability's
-- OnArenaStrike(position, data) runs and decides what the hit does.
--   shape "circle": data.radius
--   shape "line":   data.x2, data.y2 (far end), data.width (both edges of the strip are drawn)
-- ArenaModifiers.CancelStrikes(caster) removes a caster's pending strikes without hitting (a boss
-- that resets does this).
-- Any other numbers passed in the table reach OnArenaStrike unchanged.
local strike = Define("modifier_arena_delayed_strike", true)

function strike:IsAura() return false end

function strike:OnCreated(data)
    if not IsServer() then return end
    self.data = data or {}
    local origin = self:GetParent():GetAbsOrigin()
    if self.data.shape == "line" then
        local far = Vector(self.data.x2 or origin.x, self.data.y2 or origin.y, origin.z)
        self.warning = ArenaFxCore.Line(origin, GetGroundPosition(far, nil), self.data.width)
    else
        self.warning = ArenaFxCore.Circle(origin, self.data.radius or 200, self:GetDuration())
    end
    local caster = self:GetCaster()
    if caster then
        caster.arenaStrikes = caster.arenaStrikes or {}
        caster.arenaStrikes[self] = true
    end
end

function strike:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    local parent = self:GetParent()
    local ability = self:GetAbility()
    local caster = self:GetCaster()
    if caster and caster.arenaStrikes then
        caster.arenaStrikes[self] = nil
    end
    -- A dead caster's pending strikes fizzle, so killing a boss mid-cast is always safe.
    if not self.cancelled and ability and not ability:IsNull() and ability.OnArenaStrike
        and caster and not caster:IsNull() and caster:IsAlive() then
        ability:OnArenaStrike(parent:GetAbsOrigin(), self.data)
    end
    UTIL_Remove(parent)
end

function ArenaModifiers.CancelStrikes(caster)
    local pending = {}
    for modifier in pairs(caster and caster.arenaStrikes or {}) do
        pending[#pending + 1] = modifier
    end
    for _, modifier in ipairs(pending) do
        modifier.cancelled = true
        if not modifier:IsNull() then
            modifier:Destroy()
        end
    end
end

return ArenaModifiers
