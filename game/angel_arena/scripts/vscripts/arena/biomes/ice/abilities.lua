-- Abilities and modifiers of the ice biome (the Frostfang Reach). Every ability in
-- npc/abilities/arena/arena_ice_abilities.txt names this file as its ScriptFile; the class name
-- of each ability is its KV name. Numbers come from the KV AbilityValues, effects from fx.lua
-- next to this file.
--
-- The cold, the identity of this biome:
--   Chill   a stacking debuff (slower movement and attacks). At COLD.freeze_at stacks the target
--           is Frozen. Most ice monsters add Chill; Blizzard and the boss's Whiteout add it to
--           anyone who stands still.
--   Frozen  stunned in a block of ice for a moment. Afterwards the target is Thawing: Chill
--           cannot take hold for a few seconds, so a fight never becomes a frozen lock.
--   Shatter some moves hit a Frozen target harder and break the ice (Shatter Slam, Frost Breath,
--           Icefall).
--   Brittle armour the cold has cracked: stacking armour loss from the ice brutes' blows.
--
-- The Dota client loads this file on its own when it first sees one of its modifiers, so every
-- ice modifier (including the ones applied with no ability, such as Chill and Frozen) is
-- defined and linked here, the file requires what it uses, and server work stays behind
-- IsServer() or in server-only callbacks.

require("arena/core/fx")
require("arena/core/modifiers")
local FX = require("arena/biomes/ice/fx")

local FILE = "arena/biomes/ice/abilities.lua"
local P, S = FX.particles, FX.sounds

-- Numbers of the shared cold. The tooltips show the live values through the modifiers.
local COLD = {
    move_per_stack = 8,     -- percent movement speed lost per Chill stack
    attack_per_stack = 10,  -- attack speed lost per Chill stack
    duration = 4,           -- seconds; every new stack refreshes it
    freeze_at = 5,          -- stacks that turn into Frozen
    freeze_duration = 1.0,  -- seconds frozen when Chill builds up
    thaw_duration = 3,      -- seconds a thawed unit cannot be chilled
}

local CHILL, FROZEN, THAWING = "modifier_arena_ice_chill", "modifier_arena_ice_frozen", "modifier_arena_ice_thawing"
local BRITTLE = "modifier_arena_ice_brittle"

local function Define(name, options)
    options = options or {}
    local modifier = class({})
    function modifier:IsHidden() return options.hidden == true end
    function modifier:IsDebuff() return options.debuff == true end
    function modifier:IsPurgable() return options.purgable ~= false end
    _G[name] = modifier
    LinkLuaModifier(name, FILE, LUA_MODIFIER_MOTION_NONE)
    return modifier
end

local function Value(modifier, key)
    local ability = modifier:GetAbility()
    return ability and not ability:IsNull() and ability:GetSpecialValueFor(key) or 0
end

local function Valid(entity)
    return entity ~= nil and not entity:IsNull()
end

local function Alive(unit)
    return Valid(unit) and unit:IsAlive()
end

local function Enemies(team, position, radius, types)
    return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
        types or (DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC), DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
end

local function Hit(victim, attacker, ability, damage)
    if damage <= 0 then return end
    ApplyDamage({ victim = victim, attacker = attacker, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
end

local function IsFoe(unit, other)
    return Valid(other) and other.GetTeamNumber ~= nil and other:GetTeamNumber() ~= unit:GetTeamNumber()
end

-- A direction on the ground from `from` towards `to`, or `fallback` when they are too close.
local function Direction(from, to, fallback)
    local dx, dy = to.x - from.x, to.y - from.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length < 1 then
        return fallback
    end
    return Vector(dx / length, dy / length, 0)
end

local function Rotate(direction, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return Vector(direction.x * c - direction.y * s, direction.x * s + direction.y * c, 0)
end

---------------------------------------------------------------------------- the shared cold

-- Freezes `target` for `duration` seconds. A Thawing target is spared unless `force` is set
-- (forced freezes come from telegraphed moves the target failed to dodge). Returns true when it froze.
local function Freeze(target, source, duration, force)
    if not Alive(target) or target:IsMagicImmune() then return false end
    if not force and target:HasModifier(THAWING) then return false end
    target:RemoveModifierByName(CHILL)
    target:AddNewModifier(Alive(source) and source or target, nil, FROZEN, { duration = duration })
    target:EmitSound(S.chill_freeze)
    return true
end

-- Adds `stacks` of Chill to `target`; at COLD.freeze_at stacks it becomes Frozen instead.
local function Chill(target, source, stacks)
    if not Alive(target) or target:IsMagicImmune() or (stacks or 0) <= 0 then return end
    if target:HasModifier(FROZEN) or target:HasModifier(THAWING) then return end
    local chill = target:FindModifierByName(CHILL)
        or target:AddNewModifier(Alive(source) and source or target, nil, CHILL, { duration = COLD.duration })
    if not chill then return end
    local count = chill:GetStackCount() + stacks
    if count >= COLD.freeze_at then
        Freeze(target, source, COLD.freeze_duration, false)
        return
    end
    chill:SetStackCount(count)
    chill:SetDuration(COLD.duration, true)
end

-- Breaks the ice around a Frozen target: `bonus` extra magic damage and the freeze ends (the
-- target thaws). Returns true when the target was frozen.
local function Shatter(target, attacker, ability, bonus)
    if not Alive(target) or not target:HasModifier(FROZEN) then return false end
    target:RemoveModifierByName(FROZEN)
    Hit(target, attacker, ability, bonus)
    ArenaFxCore.Burst(P.shatter, target:GetAbsOrigin())
    target:EmitSound(S.shatter)
    return true
end

-- One more stack of Brittle from `ability` (its armor_per_stack, max_stacks and duration).
local function Crack(target, caster, ability)
    if not Alive(target) or target:IsBuilding() then return end
    local duration = ability:GetSpecialValueFor("duration")
    local brittle = target:FindModifierByName(BRITTLE)
        or target:AddNewModifier(caster, ability, BRITTLE, { duration = duration })
    if not brittle then return end
    brittle:SetStackCount(math.min(ability:GetSpecialValueFor("max_stacks"), brittle:GetStackCount() + 1))
    brittle:SetDuration(duration, true)
end

-- For the tests: the numbers and helpers above.
ArenaIce = { COLD = COLD, Chill = Chill, Freeze = Freeze, Shatter = Shatter, Crack = Crack }

local chill = Define(CHILL, { debuff = true })

function chill:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function chill:GetModifierMoveSpeedBonus_Percentage() return -COLD.move_per_stack * self:GetStackCount() end
function chill:GetModifierAttackSpeedBonus_Constant() return -COLD.attack_per_stack * self:GetStackCount() end
function chill:GetEffectName() return P.chilled end
function chill:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function chill:GetStatusEffectName() return P.chilled_status end
function chill:StatusEffectPriority() return 5 end

local frozen = Define(FROZEN, { debuff = true, purgable = false })

function frozen:IsStunDebuff() return true end
function frozen:IsPurgeException() return true end
function frozen:CheckState()
    return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_FROZEN] = true }
end
function frozen:GetEffectName() return P.frozen end
function frozen:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function frozen:GetStatusEffectName() return P.frozen_status end
function frozen:StatusEffectPriority() return 20 end
function frozen:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    if Alive(parent) then
        parent:AddNewModifier(parent, nil, THAWING, { duration = COLD.thaw_duration })
    end
end

local thawing = Define(THAWING, { purgable = false })

function thawing:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function thawing:OnTooltip() return COLD.thaw_duration end

local brittle = Define(BRITTLE, { debuff = true })

function brittle:OnCreated() self.per_stack = Value(self, "armor_per_stack") end
function brittle:OnRefresh() self.per_stack = Value(self, "armor_per_stack") end
function brittle:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function brittle:GetModifierPhysicalArmorBonus() return -(self.per_stack or 0) * self:GetStackCount() end
function brittle:GetEffectName() return P.brittle end
function brittle:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function brittle:GetStatusEffectName() return P.brittle_status end
function brittle:StatusEffectPriority() return 4 end

-- A passive that cracks armour on every landed attack (Brittle Blows, Frigid Fists).
local function BrittleOnHit(name)
    local passive = Define(name, { hidden = true, purgable = false })
    function passive:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
    function passive:OnAttackLanded(event)
        if not IsServer() then return end
        local parent, ability = self:GetParent(), self:GetAbility()
        if event.attacker ~= parent or parent:PassivesDisabled() or not ability or ability:IsNull()
            or ability:GetLevel() < 1 or not IsFoe(parent, event.target) then
            return
        end
        Crack(event.target, parent, ability)
        if event.target:GetModifierStackCount(BRITTLE, parent) == 1 then
            event.target:EmitSound(S.brittle)
        end
    end
    return passive
end

---------------------------------------------------------------- Rime Bolt (rime wraith)

arena_ice_rime_bolt = class({})

function arena_ice_rime_bolt:OnSpellStart()
    local caster = self:GetCaster()
    ProjectileManager:CreateTrackingProjectile({
        Target = self:GetCursorTarget(),
        Source = caster,
        Ability = self,
        EffectName = P.rime_bolt,
        iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
        bDodgeable = true,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    })
    caster:EmitSound(S.rime_bolt)
end

function arena_ice_rime_bolt:OnProjectileHit(target)
    if not target or target:TriggerSpellAbsorb(self) then return true end
    local caster = self:GetCaster()
    Hit(target, caster, self, self:GetSpecialValueFor("damage"))
    Chill(target, caster, self:GetSpecialValueFor("chill_stacks"))
    target:EmitSound(S.rime_bolt_hit)
    return true
end

----------------------------------------------------- Brittle Blows (tuskarr raider, ogre-seal)

arena_ice_brittle_blows = class({})

function arena_ice_brittle_blows:GetIntrinsicModifierName()
    return "modifier_arena_ice_brittle_blows"
end

BrittleOnHit("modifier_arena_ice_brittle_blows")

----------------------------------------------------------- Blizzard (frostbitten shaman)
-- A storm that lingers where it lands. It hurts everyone inside, and anyone who stands still in
-- it (moves less than still_distance in half a second) gains a stack of Chill every half second.

arena_ice_blizzard = class({})

function arena_ice_blizzard:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function arena_ice_blizzard:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    CreateModifierThinker(caster, self, "modifier_arena_ice_blizzard", {
        duration = self:GetSpecialValueFor("duration"),
        radius = self:GetSpecialValueFor("radius"),
        dps = self:GetSpecialValueFor("damage_per_second"),
        still = self:GetSpecialValueFor("still_distance"),
    }, point, caster:GetTeamNumber(), false)
    EmitSoundOnLocationWithCaster(point, S.blizzard, caster)
end

local blizzard = Define("modifier_arena_ice_blizzard", { hidden = true, purgable = false })

blizzard.TICK = 0.5

function blizzard:OnCreated(data)
    if not IsServer() then return end
    data = data or {}
    self.radius = data.radius or 0
    self.dps = data.dps or 0
    self.still = data.still or 0
    self.seen = {}
    local centre = self:GetParent():GetAbsOrigin()
    self.storm = ParticleManager:CreateParticle(P.blizzard, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.storm, 0, centre)
    ParticleManager:SetParticleControl(self.storm, 1, Vector(self.radius, self.radius, self.radius))
    ParticleManager:SetParticleControl(self.storm, 5, Vector(self.radius, self.radius, self.radius))
    self:StartIntervalThink(blizzard.TICK)
end

function blizzard:OnIntervalThink()
    local thinker = self:GetParent()
    local caster = self:GetCaster()
    local attacker = Alive(caster) and caster or thinker
    local ability = self:GetAbility()
    local seen = {}
    for _, enemy in ipairs(Enemies(thinker:GetTeamNumber(), thinker:GetAbsOrigin(), self.radius)) do
        Hit(enemy, attacker, ability, self.dps * blizzard.TICK)
        local index = enemy:GetEntityIndex()
        local position = enemy:GetAbsOrigin()
        local before = self.seen[index]
        if before and (position - before):Length2D() <= self.still then
            Chill(enemy, attacker, 1)
        end
        seen[index] = position
    end
    self.seen = seen
end

function blizzard:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.storm)
    self.storm = nil
    UTIL_Remove(self:GetParent())
end

--------------------------------------------------------- Rime Shell (frostbitten shaman)
-- An ally coated in ice: more armour, and melee attackers that strike it gain Chill.

arena_ice_rime_shell = class({})

function arena_ice_rime_shell:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    target:AddNewModifier(caster, self, "modifier_arena_ice_rime_shell", { duration = self:GetSpecialValueFor("duration") })
    target:EmitSound(S.rime_shell)
end

local shell = Define("modifier_arena_ice_rime_shell")

function shell:OnCreated() self.armor = Value(self, "armor") end
function shell:OnRefresh() self.armor = Value(self, "armor") end
function shell:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function shell:GetModifierPhysicalArmorBonus() return self.armor end
function shell:OnAttackLanded(event)
    if not IsServer() then return end
    local parent, attacker = self:GetParent(), event.attacker
    if event.target ~= parent or not IsFoe(parent, attacker) or attacker:IsRangedAttacker() then return end
    Chill(attacker, parent, Value(self, "chill_stacks"))
end
function shell:GetEffectName() return P.rime_shell end
function shell:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function shell:GetStatusEffectName() return P.rime_shell_status end
function shell:StatusEffectPriority() return 6 end

------------------------------------------------------------------ Rime Burst (rimebloat)
-- When the rimebloat dies, a ring closes over its body and then it bursts. The burst is its own
-- thinker, so it goes off even though the monster is dead; its numbers are copied when it starts.

arena_ice_rime_burst = class({})

function arena_ice_rime_burst:GetIntrinsicModifierName()
    return "modifier_arena_ice_rime_burst_passive"
end

local burstPassive = Define("modifier_arena_ice_rime_burst_passive", { hidden = true, purgable = false })

function burstPassive:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end

function burstPassive:OnDeath(event)
    if not IsServer() then return end
    local parent, ability = self:GetParent(), self:GetAbility()
    if event.unit ~= parent or parent:PassivesDisabled() or not ability or ability:IsNull() or ability:GetLevel() < 1 then
        return
    end
    CreateModifierThinker(parent, ability, "modifier_arena_ice_rime_burst", {
        duration = ability:GetSpecialValueFor("delay"),
        radius = ability:GetSpecialValueFor("radius"),
        damage = ability:GetSpecialValueFor("damage"),
        stacks = ability:GetSpecialValueFor("chill_stacks"),
    }, parent:GetAbsOrigin(), parent:GetTeamNumber(), false)
end

local burst = Define("modifier_arena_ice_rime_burst", { hidden = true, purgable = false })

function burst:OnCreated(data)
    if not IsServer() then return end
    data = data or {}
    self.radius, self.damage, self.stacks = data.radius or 0, data.damage or 0, data.stacks or 0
    self.warning = ArenaFxCore.Circle(self:GetParent():GetAbsOrigin(), self.radius, self:GetDuration())
end

function burst:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    local thinker = self:GetParent()
    local origin = thinker:GetAbsOrigin()
    ArenaFxCore.Burst(P.nova, origin, self.radius)
    EmitSoundOnLocationWithCaster(origin, S.burst, thinker)
    for _, enemy in ipairs(Enemies(thinker:GetTeamNumber(), origin, self.radius)) do
        Hit(enemy, thinker, nil, self.damage)
        Chill(enemy, thinker, self.stacks)
    end
    UTIL_Remove(thinker)
end

--------------------------------------------------------------- Shatter Slam (ogre-seal)
-- The ring on the ground during the wind-up is the warning. Frozen enemies caught in it shatter.

arena_ice_shatter_slam = class({})

function arena_ice_shatter_slam:OnAbilityPhaseStart()
    if IsServer() then
        self.warning = ArenaFxCore.Circle(self:GetCaster():GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint())
    end
    return true
end

function arena_ice_shatter_slam:OnAbilityPhaseInterrupted()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
end

function arena_ice_shatter_slam:OnSpellStart()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    local damage = self:GetSpecialValueFor("damage")
    ArenaFxCore.Burst(P.nova, origin, radius)
    caster:EmitSound(S.slam)
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), origin, radius)) do
        Hit(enemy, caster, self, damage)
        if not Shatter(enemy, caster, self, damage * self:GetSpecialValueFor("shatter_pct") / 100) then
            Chill(enemy, caster, self:GetSpecialValueFor("chill_stacks"))
        end
    end
end

----------------------------------------------------------- Glacial Tomb (rime revenant)
-- A ring closes under the target; whoever is still inside when it closes is frozen solid.

arena_ice_glacial_tomb = class({})

function arena_ice_glacial_tomb:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    if target:TriggerSpellAbsorb(self) then return end
    CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
        duration = self:GetSpecialValueFor("delay"),
        shape = "circle",
        radius = self:GetSpecialValueFor("radius"),
    }, target:GetAbsOrigin(), caster:GetTeamNumber(), false)
    caster:EmitSound(S.tomb_cast)
end

function arena_ice_glacial_tomb:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    ArenaFxCore.Burst(P.nova, position, data.radius)
    EmitSoundOnLocationWithCaster(position, S.tomb, caster)
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        Freeze(enemy, caster, self:GetSpecialValueFor("freeze_duration"), true)
    end
end

------------------------------------------------------------ Cold Grasp (rime revenant)

arena_ice_cold_grasp = class({})

function arena_ice_cold_grasp:GetIntrinsicModifierName()
    return "modifier_arena_ice_cold_grasp"
end

local grasp = Define("modifier_arena_ice_cold_grasp", { hidden = true, purgable = false })

function grasp:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end

function grasp:OnAttackLanded(event)
    if not IsServer() then return end
    local parent = self:GetParent()
    if event.attacker ~= parent or parent:PassivesDisabled() or not IsFoe(parent, event.target) or event.target:IsBuilding() then
        return
    end
    Chill(event.target, parent, Value(self, "chill_stacks"))
end

--------------------------------------------------------------------------------- the boss
-- Ability levels are the boss's phase: level 2 and 3 values are its phase 2 and 3 versions.

-- Frigid Fists: every blow of the giant cracks its target's armour.
arena_ice_boss_frigid_fists = class({})

function arena_ice_boss_frigid_fists:GetIntrinsicModifierName()
    return "modifier_arena_ice_boss_frigid_fists"
end

BrittleOnHit("modifier_arena_ice_boss_frigid_fists")

-- Frost Breath: three lines on the ground mark a cone during the wind-up; then the giant
-- breathes down it. Everyone in the cone is hurt and chilled; anyone frozen there shatters.
arena_ice_boss_frost_breath = class({})

function arena_ice_boss_frost_breath:Cone()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local direction = Direction(origin, self:GetCursorPosition(), caster:GetForwardVector())
    return origin, direction, self:GetSpecialValueFor("length"), math.rad(self:GetSpecialValueFor("angle") / 2)
end

function arena_ice_boss_frost_breath:OnAbilityPhaseStart()
    if IsServer() then
        local origin, direction, length, half = self:Cone()
        self.warning = {}
        for _, angle in ipairs({ -half, 0, half }) do
            local far = GetGroundPosition(origin + Rotate(direction, angle) * length, nil)
            self.warning[#self.warning + 1] = ArenaFxCore.Line(origin, far)
        end
    end
    return true
end

function arena_ice_boss_frost_breath:OnAbilityPhaseInterrupted()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
end

function arena_ice_boss_frost_breath:OnSpellStart()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    local caster = self:GetCaster()
    local origin, direction, length, half = self:Cone()
    local damage = self:GetSpecialValueFor("damage")
    local cosine = math.cos(half)
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), origin, length)) do
        local offset = enemy:GetAbsOrigin() - origin
        local distance = offset:Length2D()
        if distance < 1 or (offset.x * direction.x + offset.y * direction.y) / distance >= cosine then
            Hit(enemy, caster, self, damage)
            if not Shatter(enemy, caster, self, damage * self:GetSpecialValueFor("shatter_pct") / 100) then
                Chill(enemy, caster, self:GetSpecialValueFor("chill_stacks"))
            end
        end
    end
    -- Only the picture: the damage above is already done. The projectile hits nothing.
    local speed = self:GetSpecialValueFor("visual_speed")
    ProjectileManager:CreateLinearProjectile({
        Ability = self,
        EffectName = P.breath,
        vSpawnOrigin = origin,
        fDistance = length,
        fStartRadius = 120,
        fEndRadius = length * math.tan(half),
        Source = caster,
        bHasFrontalCone = true,
        iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_NONE,
        iUnitTargetType = DOTA_UNIT_TARGET_NONE,
        vVelocity = direction * speed,
    })
    caster:EmitSound(S.breath)
end

function arena_ice_boss_frost_breath:OnProjectileHit()
    return true
end

-- Icefall: icicles fall in rings around the giant, the inner ring first and each further ring
-- a moment later. Its feet are safe, and so is a ring that has already fallen.
arena_ice_boss_icefall = class({})

function arena_ice_boss_icefall:Points()
    local origin = self:GetCaster():GetAbsOrigin()
    local points = {}
    local turn = RandomFloat(0, 2 * math.pi)
    for wave = 1, self:GetSpecialValueFor("waves") do
        local count = self:GetSpecialValueFor("per_wave") + 3 * (wave - 1)
        local distance = self:GetSpecialValueFor("first_distance") + (wave - 1) * self:GetSpecialValueFor("wave_gap")
        local delay = self:GetSpecialValueFor("first_delay") + (wave - 1) * self:GetSpecialValueFor("wave_delay")
        for index = 1, count do
            -- Every other ring is turned half a step, so the gaps do not line up.
            local angle = turn + 2 * math.pi * (index - 1 + (wave % 2) * 0.5) / count
            points[#points + 1] = {
                position = GetGroundPosition(origin + Vector(math.cos(angle), math.sin(angle), 0) * distance, nil),
                delay = delay,
                loud = index % 3 == 1 and 1 or 0,
            }
        end
    end
    return points
end

function arena_ice_boss_icefall:OnSpellStart()
    local caster = self:GetCaster()
    local radius = self:GetSpecialValueFor("radius")
    for _, point in ipairs(self:Points()) do
        CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
            duration = point.delay,
            shape = "circle",
            radius = radius,
            loud = point.loud,
        }, point.position, caster:GetTeamNumber(), false)
    end
    caster:EmitSound(S.icefall_cast)
end

function arena_ice_boss_icefall:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    local damage = self:GetSpecialValueFor("damage")
    ArenaFxCore.Burst(P.icefall, position, data.radius)
    if data.loud == 1 then
        EmitSoundOnLocationWithCaster(position, S.icefall, caster)
    end
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), position, data.radius)) do
        Hit(enemy, caster, self, damage)
        if not Shatter(enemy, caster, self, damage * self:GetSpecialValueFor("shatter_pct") / 100) then
            Chill(enemy, caster, self:GetSpecialValueFor("chill_stacks"))
        end
    end
end

-- Whiteout (from phase 2): a blizzard follows the giant. Every second, each enemy hero near it
-- that has not moved still_distance since the last second gains Chill. Keep moving.
arena_ice_boss_whiteout = class({})

function arena_ice_boss_whiteout:GetIntrinsicModifierName()
    return "modifier_arena_ice_boss_whiteout_storm"
end

local storm = Define("modifier_arena_ice_boss_whiteout_storm", { hidden = true, purgable = false })

storm.TICK = 1

function storm:OnCreated()
    if not IsServer() then return end
    self.seen = {}
    self:StartIntervalThink(storm.TICK)
end

function storm:Calm()
    ArenaFxCore.Stop(self.snow)
    self.snow = nil
    self.seen = {}
end

function storm:OnIntervalThink()
    local parent, ability = self:GetParent(), self:GetAbility()
    -- The ability is unlearned (level 0) before phase 2 and after the boss resets.
    if not ability or ability:IsNull() or ability:GetLevel() < 1 or not parent:IsAlive() or parent:PassivesDisabled() then
        self:Calm()
        return
    end
    local radius = ability:GetSpecialValueFor("radius")
    if not self.snow then
        self.snow = ParticleManager:CreateParticle(P.whiteout_snow, PATTACH_ABSORIGIN_FOLLOW, parent)
        ParticleManager:SetParticleControl(self.snow, 1, Vector(radius, radius, 1))
    end
    local still = ability:GetSpecialValueFor("still_distance")
    local stacks = ability:GetSpecialValueFor("chill_stacks")
    local seen = {}
    for _, hero in ipairs(Enemies(parent:GetTeamNumber(), parent:GetAbsOrigin(), radius, DOTA_UNIT_TARGET_HERO)) do
        hero:AddNewModifier(parent, ability, "modifier_arena_ice_whiteout", { duration = storm.TICK + 0.2 })
        local index = hero:GetEntityIndex()
        local position = hero:GetAbsOrigin()
        local before = self.seen[index]
        if before and (position - before):Length2D() <= still then
            Chill(hero, parent, stacks)
        end
        seen[index] = position
    end
    self.seen = seen
end

function storm:OnDestroy()
    if not IsServer() then return end
    self:Calm()
end

-- What heroes inside the Whiteout see on their buff bar.
local whiteout = Define("modifier_arena_ice_whiteout", { debuff = true, purgable = false })

function whiteout:OnCreated() self.still = Value(self, "still_distance") end
function whiteout:OnRefresh() self.still = Value(self, "still_distance") end
function whiteout:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function whiteout:OnTooltip() return self.still end

-- Absolute Zero (phase 3): the giant channels while a vast ring closes around it and ice pillars
-- rise nearby. When the channel ends, every enemy inside the ring that is not sheltering beside a
-- pillar is frozen solid and badly hurt. Stand by a pillar, leave the ring, or stun the giant.
arena_ice_boss_absolute_zero = class({})

function arena_ice_boss_absolute_zero:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local channel = self:GetChannelTime()
    self.warning = ArenaFxCore.Circle(origin, self:GetSpecialValueFor("radius"), channel)
    self.aura = ParticleManager:CreateParticle(P.zero_channel, PATTACH_ABSORIGIN_FOLLOW, caster)
    caster:EmitSound(S.zero_channel)
    self.pillars = {}
    local count = self:GetSpecialValueFor("pillar_count")
    local turn = RandomFloat(0, 2 * math.pi)
    for index = 1, count do
        local angle = turn + 2 * math.pi * index / math.max(1, count)
        local distance = RandomFloat(self:GetSpecialValueFor("pillar_min_distance"), self:GetSpecialValueFor("pillar_max_distance"))
        local position = GetGroundPosition(origin + Vector(math.cos(angle), math.sin(angle), 0) * distance, nil)
        local pillar = CreateUnitByName("npc_arena_ice_glacial_pillar", position, false, nil, nil, caster:GetTeamNumber())
        if pillar then
            pillar:AddNewModifier(caster, self, "modifier_arena_ice_glacial_pillar", { duration = channel + 1 })
            self.pillars[#self.pillars + 1] = pillar
            EmitSoundOnLocationWithCaster(position, S.pillar, caster)
        end
    end
end

-- Whether `position` is within the shelter radius of a standing pillar.
function arena_ice_boss_absolute_zero:Sheltered(position)
    local reach = self:GetSpecialValueFor("pillar_radius")
    for _, pillar in ipairs(self.pillars or {}) do
        if Valid(pillar) and (pillar:GetAbsOrigin() - position):Length2D() <= reach then
            return true
        end
    end
    return false
end

function arena_ice_boss_absolute_zero:Clear()
    for _, pillar in ipairs(self.pillars or {}) do
        if Valid(pillar) then
            pillar:RemoveModifierByName("modifier_arena_ice_glacial_pillar")
        end
    end
    self.pillars = nil
end

function arena_ice_boss_absolute_zero:OnChannelFinish(interrupted)
    local caster = self:GetCaster()
    ArenaFxCore.Stop(self.warning)
    ArenaFxCore.Stop(self.aura)
    self.warning, self.aura = nil, nil
    caster:StopSound(S.zero_channel)
    if not interrupted then
        local origin = caster:GetAbsOrigin()
        local radius = self:GetSpecialValueFor("radius")
        local damage = self:GetSpecialValueFor("damage")
        local freeze = self:GetSpecialValueFor("freeze_duration")
        for step = 1, 3 do
            ArenaFxCore.Burst(P.nova, origin, radius * step / 3)
        end
        caster:EmitSound(S.zero)
        for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), origin, radius)) do
            if not self:Sheltered(enemy:GetAbsOrigin()) then
                Hit(enemy, caster, self, damage)
                Freeze(enemy, caster, freeze, true)
            end
        end
    end
    self:Clear()
end

-- An ice pillar of Absolute Zero: untouchable scenery that breaks when its time is up.
local pillar = Define("modifier_arena_ice_glacial_pillar", { hidden = true, purgable = false })

function pillar:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
    }
end
function pillar:GetEffectName() return P.pillar end
function pillar:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function pillar:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    if Valid(parent) then
        ArenaFxCore.Burst(P.shatter, parent:GetAbsOrigin())
        EmitSoundOnLocationWithCaster(parent:GetAbsOrigin(), S.pillar_break, parent)
        UTIL_Remove(parent)
    end
end
