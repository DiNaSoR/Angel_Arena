-- Passive effects for the Angel Arena item set (see arena_items.lua).
--
-- modifier_arena_item is the intrinsic modifier of every item: it grants the plain stats and
-- adds one modifier_arena_<mechanic> per entry in the item's "ArenaMechanics" key. Every number
-- comes from the item's AbilityValues through ArenaItems.Values(), so the definitions in
-- scripts/npc/items/arena/arena_items.txt are the only place values live. What each effect
-- looks and sounds like is in arena_fx.lua.

require("items/arena/arena_data")
require("items/arena/arena_fx")

local FILE = "items/arena/arena_modifiers"

local function Values(modifier)
    return ArenaItems.Values(modifier:GetAbility())
end

local function IsEnemyUnit(parent, unit)
    return unit and not unit:IsNull() and unit.GetTeamNumber and unit:GetTeamNumber() ~= parent:GetTeamNumber()
        and not unit:IsBuilding() and not unit:IsOther()
end

local function Deal(victim, attacker, ability, amount, damageType, flags)
    ApplyDamage({
        victim = victim,
        attacker = attacker,
        ability = ability,
        damage = amount,
        damage_type = damageType,
        damage_flags = flags or DOTA_DAMAGE_FLAG_NONE,
    })
end

-- Declares a modifier class and links it. `hidden` and `multiple` cover the two things that
-- differ between them; everything else is added by the caller.
local function Define(name, hidden, multiple)
    local modifier = class({})
    function modifier:IsHidden() return hidden end
    function modifier:IsPurgable() return false end
    if multiple then
        function modifier:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
        function modifier:RemoveOnDeath() return false end
    end
    function modifier:OnCreated() self.values = Values(self) end
    _G["modifier_arena_" .. name] = modifier
    LinkLuaModifier("modifier_arena_" .. name, FILE, LUA_MODIFIER_MOTION_NONE)
    return modifier
end

---------------------------------------------------------------------------------- plain stats

local STATS = {
    "bonus_strength", "bonus_agility", "bonus_intellect", "bonus_all_stats", "bonus_damage",
    "bonus_attack_speed", "bonus_armor", "bonus_health", "bonus_mana", "bonus_health_regen",
    "bonus_mana_regen", "bonus_movement_speed", "bonus_magic_resistance", "bonus_evasion",
    "bonus_spell_amp", "bonus_status_resistance", "bonus_cooldown_reduction", "bonus_cast_range",
    "bonus_health_regen_pct",
}

local item = Define("item", true, true)

function item:OnCreated()
    local values = Values(self)
    self.stats = {}
    for _, name in ipairs(STATS) do
        self.stats[name] = values[name] or 0
    end
    if not IsServer() then
        return
    end
    self.mechanics = {}
    local parent = self:GetParent()
    local ability = self:GetAbility()
    for _, mechanic in ipairs(ArenaItems.Mechanics(ability)) do
        local added = parent:AddNewModifier(parent, ability, "modifier_arena_" .. mechanic, {})
        if added then
            table.insert(self.mechanics, added)
        end
    end
end

function item:OnDestroy()
    if not IsServer() then
        return
    end
    for _, mechanic in ipairs(self.mechanics or {}) do
        if not mechanic:IsNull() then
            mechanic:Destroy()
        end
    end
end

function item:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
        MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
        MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
        MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_BONUS,
        MODIFIER_PROPERTY_MANA_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
        MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
        MODIFIER_PROPERTY_EVASION_CONSTANT,
        MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING,
        MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
        MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
    }
end

function item:GetModifierBonusStats_Strength() return self.stats.bonus_strength + self.stats.bonus_all_stats end
function item:GetModifierBonusStats_Agility() return self.stats.bonus_agility + self.stats.bonus_all_stats end
function item:GetModifierBonusStats_Intellect() return self.stats.bonus_intellect + self.stats.bonus_all_stats end
function item:GetModifierPreAttack_BonusDamage() return self.stats.bonus_damage end
function item:GetModifierAttackSpeedBonus_Constant() return self.stats.bonus_attack_speed end
function item:GetModifierPhysicalArmorBonus() return self.stats.bonus_armor end
function item:GetModifierHealthBonus() return self.stats.bonus_health end
function item:GetModifierManaBonus() return self.stats.bonus_mana end
function item:GetModifierConstantHealthRegen() return self.stats.bonus_health_regen end
function item:GetModifierConstantManaRegen() return self.stats.bonus_mana_regen end
function item:GetModifierMoveSpeedBonus_Constant() return self.stats.bonus_movement_speed end
function item:GetModifierMagicalResistanceBonus() return self.stats.bonus_magic_resistance end
function item:GetModifierEvasion_Constant() return self.stats.bonus_evasion end
function item:GetModifierSpellAmplify_Percentage() return self.stats.bonus_spell_amp end
function item:GetModifierStatusResistanceStacking() return self.stats.bonus_status_resistance end
function item:GetModifierPercentageCooldown() return self.stats.bonus_cooldown_reduction end
function item:GetModifierCastRangeBonusStacking() return self.stats.bonus_cast_range end
function item:GetModifierHealthRegenPercentage() return self.stats.bonus_health_regen_pct end

------------------------------------------------------------------------- healing from damage

local function StealOnDamage(name, valueName, category)
    local modifier = Define(name, true, true)

    function modifier:DeclareFunctions()
        return { MODIFIER_EVENT_ON_TAKEDAMAGE }
    end

    function modifier:OnTakeDamage(event)
        local parent = self:GetParent()
        if event.attacker ~= parent or event.damage_category ~= category or not IsEnemyUnit(parent, event.unit) then
            return
        end
        local flags = event.damage_flags or 0
        if bit.band(flags, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 or bit.band(flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL) ~= 0 then
            return
        end
        local share = self.values[valueName] / 100
        if category == DOTA_DAMAGE_CATEGORY_SPELL and not event.unit:IsHero() then
            share = share / 5 -- spells hit whole creep waves
        end
        parent:Heal(event.damage * share, self:GetAbility())
        ArenaFx.Lifesteal(parent)
    end
end

StealOnDamage("lifesteal", "lifesteal_pct", DOTA_DAMAGE_CATEGORY_ATTACK)
StealOnDamage("spell_lifesteal", "spell_lifesteal_pct", DOTA_DAMAGE_CATEGORY_SPELL)

------------------------------------------------------------------------------ on-attack effects

-- Runs `effect(self, parent, target, event)` whenever the wearer lands an attack on an enemy unit.
local function OnAttack(name, effect)
    local modifier = Define(name, true, true)

    function modifier:DeclareFunctions()
        return { MODIFIER_EVENT_ON_ATTACK_LANDED }
    end

    function modifier:OnAttackLanded(event)
        local parent = self:GetParent()
        if event.attacker == parent and IsEnemyUnit(parent, event.target) and not parent:IsIllusion() then
            effect(self, parent, event.target, event)
        end
    end

    return modifier
end

OnAttack("cleave", function(self, parent, target, event)
    if parent:IsRangedAttacker() then
        return
    end
    local radius = self.values.cleave_radius
    DoCleaveAttack(parent, target, self:GetAbility(), event.damage * self.values.cleave_pct / 100, 150, radius, radius,
        ArenaFx.CleaveParticle(true))
end)

OnAttack("smite", function(self, parent, target)
    self.attacks = (self.attacks or 0) + 1
    if self.attacks < self.values.smite_attacks then
        return
    end
    self.attacks = 0
    ArenaFx.Smite(target, self.values.smite_damage)
    Deal(target, parent, self:GetAbility(), self.values.smite_damage, DAMAGE_TYPE_MAGICAL)
end)

OnAttack("burn", function(self, parent, target)
    ArenaFx.Scorch(target)
    target:AddNewModifier(parent, self:GetAbility(), "modifier_arena_burning",
        { duration = self.values.burn_duration, dps = self.values.burn_dps })
end)

OnAttack("slow", function(self, parent, target)
    target:AddNewModifier(parent, self:GetAbility(), "modifier_arena_chilled",
        { duration = self.values.slow_duration * (1 - target:GetStatusResistance()), slow = self.values.slow_pct })
end)

OnAttack("mana_burn", function(self, parent, target)
    local burned = math.min(target:GetMana(), self.values.mana_burn)
    if burned <= 0 then
        return
    end
    target:Script_ReduceMana(burned, self:GetAbility())
    ArenaFx.ManaBurn(target)
    Deal(target, parent, self:GetAbility(), burned, DAMAGE_TYPE_PHYSICAL)
end)

OnAttack("chain", function(self, parent, target)
    if not RollPercentage(self.values.chain_chance) then
        return
    end
    local ability = self:GetAbility()
    local enemies = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, 650,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
        DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
    local from = parent
    for index = 1, math.min(#enemies, self.values.chain_targets) do
        local enemy = enemies[index]
        ArenaFx.Chain(from, enemy)
        Deal(enemy, parent, ability, self.values.chain_damage, DAMAGE_TYPE_MAGICAL)
        from = enemy
    end
end)

local BASH_INTERVAL = 2.5 -- seconds between bashes from one item, so fast attackers cannot stun-lock

OnAttack("bash", function(self, parent, target)
    local now = GameRules:GetGameTime()
    if now < (self.nextBash or 0) or not RollPercentage(self.values.bash_chance) then
        return
    end
    self.nextBash = now + BASH_INTERVAL
    local ability = self:GetAbility()
    target:AddNewModifier(parent, ability, "modifier_bashed",
        { duration = self.values.bash_duration * (1 - target:GetStatusResistance()) })
    ArenaFx.Bash(target)
    Deal(target, parent, ability, self.values.bash_damage, DAMAGE_TYPE_MAGICAL)
end)

-------------------------------------------------------------------------------- critical strike

local crit = Define("crit", true, true)

function crit:DeclareFunctions()
    return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function crit:GetModifierPreAttack_CriticalStrike(event)
    if IsServer() and IsEnemyUnit(self:GetParent(), event.target) and RollPercentage(self.values.crit_chance) then
        self.critical = event.record -- remembered so the hit that lands can be dressed up
        return self.values.crit_multiplier
    end
    return 0
end

function crit:OnAttackLanded(event)
    if event.attacker == self:GetParent() and self.critical ~= nil and event.record == self.critical then
        self.critical = nil
        ArenaFx.Crit(event.attacker, event.target)
    end
end

------------------------------------------------------------------------------------- defences

local block = Define("block", true, true)

function block:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_CONSTANT_BLOCK }
end

function block:GetModifierPhysical_ConstantBlock()
    if IsServer() and RollPercentage(self.values.block_chance) then
        return self.values.block_amount
    end
    return 0
end

local thorns = Define("thorns", true, true)

function thorns:DeclareFunctions()
    return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function thorns:OnTakeDamage(event)
    local parent = self:GetParent()
    if event.unit ~= parent or event.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK
        or not IsEnemyUnit(parent, event.attacker) or not event.attacker:IsAlive() then
        return
    end
    if bit.band(event.damage_flags or 0, DOTA_DAMAGE_FLAG_REFLECTION) ~= 0 then
        return
    end
    ArenaFx.Thorns(parent, event.attacker)
    Deal(event.attacker, parent, self:GetAbility(), event.damage * self.values.thorns_pct / 100, DAMAGE_TYPE_PURE,
        DOTA_DAMAGE_FLAG_REFLECTION + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
end

-- Survives one killing blow, then goes on cooldown. The item's own cooldown is the timer, so
-- the player can see when it is ready again.
local guardian = Define("guardian", true, true)

function guardian:Ready()
    local ability = self:GetAbility()
    return ability and ability:IsCooldownReady() and not self:GetParent():IsIllusion()
end

function guardian:DeclareFunctions()
    return { MODIFIER_PROPERTY_MIN_HEALTH, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function guardian:GetMinHealth()
    return self:Ready() and 1 or 0
end

function guardian:OnTakeDamage(event)
    local parent = self:GetParent()
    if event.unit ~= parent or parent:GetHealth() > 1 or not self:Ready() then
        return
    end
    self:GetAbility():StartCooldown(self.values.guardian_cooldown)
    parent:Purge(false, true, false, true, true)
    parent:SetHealth(math.max(1, parent:GetMaxHealth() * self.values.guardian_heal_pct / 100))
    ArenaFx.Guardian(parent)
end

------------------------------------------------------------------------------ conditional power

local BERSERK_CHECK = 0.25

local berserk = Define("berserk", true, true)

function berserk:OnCreated()
    self.values = Values(self)
    if IsServer() then
        self:StartIntervalThink(BERSERK_CHECK)
    end
end

function berserk:Active()
    return self:GetParent():GetHealthPercent() < self.values.berserk_threshold
end

-- The red haze is on only while the bonus is.
function berserk:OnIntervalThink()
    local active = self:Active() and self:GetParent():IsAlive()
    if active and not self.haze then
        self.haze = ParticleManager:CreateParticle(ArenaFx.BUFF.berserk, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    elseif not active and self.haze then
        ArenaFx.Stop(self.haze)
        self.haze = nil
    end
end

function berserk:OnDestroy()
    if IsServer() then
        ArenaFx.Stop(self.haze)
    end
end

function berserk:DeclareFunctions()
    return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function berserk:GetModifierPreAttack_BonusDamage() return self:Active() and self.values.berserk_damage or 0 end
function berserk:GetModifierAttackSpeedBonus_Constant() return self:Active() and self.values.berserk_attack_speed or 0 end

local SOULS_PER_HERO = 3

-- The stack count is the number of souls held. It is shown on the buff bar.
local souls = Define("souls", false, true)

function souls:DeclareFunctions()
    return { MODIFIER_EVENT_ON_DEATH, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function souls:OnDeath(event)
    if not IsServer() then
        return
    end
    local parent = self:GetParent()
    if event.unit == parent then
        self:SetStackCount(math.floor(self:GetStackCount() / 2))
    elseif event.attacker == parent and IsEnemyUnit(parent, event.unit) then
        local gained = event.unit:IsRealHero() and SOULS_PER_HERO or 1
        self:SetStackCount(math.min(self.values.soul_max, self:GetStackCount() + gained))
        ArenaFx.SoulClaim(event.unit, parent, self:GetAbility())
    end
end

function souls:GetModifierPreAttack_BonusDamage()
    return self:GetStackCount() * self.values.soul_damage
end

local COIN_SHOWER_EVERY = 10 -- seconds between the little coin bursts

local gold = Define("gold", true, true)

function gold:OnCreated()
    self.values = Values(self)
    if IsServer() then
        self.seconds = 0
        self:StartIntervalThink(1)
    end
end

function gold:OnIntervalThink()
    local parent = self:GetParent()
    if not parent:IsRealHero() or not parent:IsAlive() then
        return
    end
    if Gold and Gold.AddGold then
        Gold:AddGold(parent, self.values.gold_per_second) -- the arena keeps its own gold ledger
    else
        parent:ModifyGold(self.values.gold_per_second, false, DOTA_ModifyGold_Unspecified)
    end
    self.seconds = self.seconds + 1
    if self.seconds % COIN_SHOWER_EVERY == 0 then
        ArenaFx.Coins(parent)
    end
end

---------------------------------------------------------------------------------------- auras

local function Aura(name, effect, team)
    local modifier = Define(name, true, true)
    function modifier:IsAura() return true end
    function modifier:GetModifierAura() return effect end
    function modifier:GetAuraRadius() return self.values.aura_radius end
    function modifier:GetAuraSearchTeam() return team end
    function modifier:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
    function modifier:GetAuraDuration() return 0.5 end
    return modifier
end

local blessed = Aura("aura_ally", "modifier_arena_blessing", DOTA_UNIT_TARGET_TEAM_FRIENDLY)

function blessed:GetEffectName() return ArenaFx.BUFF.aura end

-- The hellfire aura scorches the ground under its bearer, out to the aura's edge.
local infernal = Aura("aura_enemy", "modifier_arena_brimstone", DOTA_UNIT_TARGET_TEAM_ENEMY)

function infernal:OnCreated()
    self.values = Values(self)
    if IsServer() then
        self.ground = ArenaFx.Scorched(self:GetParent(), self.values.aura_radius)
    end
end

function infernal:OnDestroy()
    if IsServer() then
        ArenaFx.Stop(self.ground)
    end
end

local blessing = Define("blessing", false, true)

function blessing:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
        MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
        MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
    }
end

function blessing:GetModifierPhysicalArmorBonus() return self.values.aura_armor or 0 end
function blessing:GetModifierConstantHealthRegen() return self.values.aura_health_regen or 0 end
function blessing:GetModifierAttackSpeedBonus_Constant() return self.values.aura_attack_speed or 0 end
function blessing:GetModifierBaseDamageOutgoing_Percentage() return self.values.aura_damage_pct or 0 end

local brimstone = Define("brimstone", false, true)

function brimstone:IsDebuff() return true end

function brimstone:OnCreated()
    self.values = Values(self)
    if IsServer() then
        self:StartIntervalThink(1)
    end
end

function brimstone:OnIntervalThink()
    local caster = self:GetCaster()
    if caster and not caster:IsNull() then
        Deal(self:GetParent(), caster, self:GetAbility(), self.values.aura_burn_dps, DAMAGE_TYPE_MAGICAL)
    end
end

function brimstone:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function brimstone:GetModifierPhysicalArmorBonus() return -(self.values.aura_armor_reduction or 0) end
function brimstone:GetEffectName() return ArenaFx.BUFF.brimstone end

------------------------------------------------------------------------------ timed debuffs

-- Damage over time. The damage per second arrives in the creation table and is kept as the
-- stack count so a stronger source overwrites a weaker one.
local burning = Define("burning", false, false)

function burning:IsDebuff() return true end
function burning:IsPurgable() return true end

function burning:OnCreated(data)
    if IsServer() then
        self:SetStackCount(math.max(self:GetStackCount(), data.dps or 0))
        self:StartIntervalThink(1)
    end
end

burning.OnRefresh = burning.OnCreated

function burning:OnIntervalThink()
    local caster = self:GetCaster()
    if caster and not caster:IsNull() then
        Deal(self:GetParent(), caster, self:GetAbility(), self:GetStackCount(), DAMAGE_TYPE_MAGICAL)
    end
end

function burning:GetEffectName() return ArenaFx.BUFF.burning end

-- Movement slow. The percentage is the stack count, which the client needs to show the slow.
local chilled = Define("chilled", false, false)

function chilled:IsDebuff() return true end
function chilled:IsPurgable() return true end

function chilled:OnCreated(data)
    if IsServer() then
        self:SetStackCount(math.max(self:GetStackCount(), data.slow or 0))
    end
end

chilled.OnRefresh = chilled.OnCreated

function chilled:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function chilled:GetModifierMoveSpeedBonus_Percentage() return -self:GetStackCount() end
function chilled:GetEffectName() return ArenaFx.BUFF.chilled end
function chilled:GetStatusEffectName() return ArenaFx.BUFF.chilled_status end
