-- Abilities and modifiers of the green biome (the Verdant Wilds). Every ability in
-- npc/abilities/arena/arena_green_abilities.txt names this file as its ScriptFile; the class
-- name of each ability is its KV name. Numbers come from the KV AbilityValues, effects from
-- fx.lua next to this file.
--
-- The client loads this file on its own when it first sees one of the modifiers below, so it
-- requires what it uses and keeps server work behind IsServer(). Telegraphed boss moves use the
-- shared modifier_arena_delayed_strike: create it as a thinker where the hit will land, and the
-- ability's OnArenaStrike(position, data) runs when the warning runs out.

require("arena/core/fx")
require("arena/core/modifiers")
local FX = require("arena/biomes/green/fx")

local FILE = "arena/biomes/green/abilities.lua"
local P, S = FX.particles, FX.sounds

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

local function Enemies(caster, position, radius)
    return FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
end

local function Hit(victim, caster, ability, damage)
    ApplyDamage({ victim = victim, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
end

local function Projectile(ability, target, effect)
    ProjectileManager:CreateTrackingProjectile({
        Target = target,
        Source = ability:GetCaster(),
        Ability = ability,
        EffectName = effect,
        iMoveSpeed = ability:GetSpecialValueFor("projectile_speed"),
        bDodgeable = true,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
    })
end

------------------------------------------------------------------------- shared debuffs

-- Held fast by roots. `dps` (optional) burns each second while it lasts.
local rooted = Define("modifier_arena_green_rooted", { debuff = true })

function rooted:OnCreated(data)
    if not IsServer() then return end
    self.dps = data and data.dps or 0
    if self.dps > 0 then
        self:StartIntervalThink(0.5)
    end
end
function rooted:OnRefresh(data)
    if not IsServer() then return end
    local dps = data and data.dps or 0
    if dps > (self.dps or 0) then
        self.dps = dps
        self:StartIntervalThink(0.5)
    end
end
function rooted:OnIntervalThink()
    Hit(self:GetParent(), self:GetCaster(), self:GetAbility(), self.dps * 0.5)
end
function rooted:CheckState() return { [MODIFIER_STATE_ROOTED] = true } end
function rooted:GetEffectName() return P.rooted end
function rooted:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Slowed by thorns; the slow is the ability's "slow" value.
local thorned = Define("modifier_arena_green_thorned", { debuff = true })

function thorned:OnCreated() self.slow = Value(self, "slow") end
function thorned:OnRefresh() self.slow = Value(self, "slow") end
function thorned:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function thorned:GetModifierMoveSpeedBonus_Percentage() return -self.slow end
function thorned:GetEffectName() return P.thorned end
function thorned:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

--------------------------------------------------------------- Thorn Shot (thorn archer)

arena_green_thorn_shot = class({})

function arena_green_thorn_shot:OnSpellStart()
    Projectile(self, self:GetCursorTarget(), P.thorn_shot)
    self:GetCaster():EmitSound(S.thorn_shot)
end

function arena_green_thorn_shot:OnProjectileHit(target)
    if not target or target:TriggerSpellAbsorb(self) then return true end
    local caster = self:GetCaster()
    Hit(target, caster, self, self:GetSpecialValueFor("damage"))
    target:AddNewModifier(caster, self, "modifier_arena_green_thorned", { duration = self:GetSpecialValueFor("slow_duration") })
    target:EmitSound(S.thorn_hit)
    return true
end

------------------------------------------------------------- Entangling Bite (vine wolf)

arena_green_entangling_bite = class({})

function arena_green_entangling_bite:GetIntrinsicModifierName()
    return "modifier_arena_green_entangling_bite"
end

local bite = Define("modifier_arena_green_entangling_bite", { hidden = true, purgable = false })

function bite:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end

function bite:OnAttackLanded(event)
    if not IsServer() then return end
    local parent, target = self:GetParent(), event.target
    if event.attacker ~= parent or parent:PassivesDisabled() or not target or target:IsBuilding()
        or target:GetTeamNumber() == parent:GetTeamNumber() then
        return
    end
    if self.target ~= target then
        self.target, self.count = target, 0
    end
    self.count = (self.count or 0) + 1
    if self.count < Value(self, "attacks") then return end
    self.count = 0
    local ability = self:GetAbility()
    Hit(target, parent, ability, Value(self, "bonus_damage"))
    target:AddNewModifier(parent, ability, "modifier_arena_green_rooted", { duration = Value(self, "root_duration") })
    target:EmitSound(S.bite)
end

----------------------------------------------------------- Bramble Slam (thicket bear)
-- The ring on the ground during the wind-up is the warning: step out before it closes.

arena_green_bramble_slam = class({})

function arena_green_bramble_slam:OnAbilityPhaseStart()
    if IsServer() then
        self.warning = ArenaFxCore.Circle(self:GetCaster():GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint())
    end
    return true
end

function arena_green_bramble_slam:OnAbilityPhaseInterrupted()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
end

function arena_green_bramble_slam:OnSpellStart()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    ArenaFxCore.Burst(P.slam, origin, radius)
    caster:EmitSound(S.slam)
    for _, enemy in ipairs(Enemies(caster, origin, radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_arena_green_thorned", { duration = self:GetSpecialValueFor("slow_duration") })
    end
end

------------------------------------------------------------- Spore Cloud (spore shaman)

arena_green_spore_cloud = class({})

function arena_green_spore_cloud:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function arena_green_spore_cloud:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    CreateModifierThinker(caster, self, "modifier_arena_green_spore_cloud", { duration = self:GetSpecialValueFor("duration") },
        point, caster:GetTeamNumber(), false)
    EmitSoundOnLocationWithCaster(point, S.spore_cloud, caster)
end

local cloud = Define("modifier_arena_green_spore_cloud", { hidden = true, purgable = false })

function cloud:OnCreated()
    if not IsServer() then return end
    self.radius = Value(self, "radius")
    self.cloud = ParticleManager:CreateParticle(P.spore_cloud, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(self.cloud, 0, self:GetParent():GetAbsOrigin())
    ParticleManager:SetParticleControl(self.cloud, 1, Vector(self.radius, 1, 1))
    self:StartIntervalThink(0.5)
end

function cloud:OnIntervalThink()
    local caster = self:GetCaster()
    if not caster or caster:IsNull() then return end
    local ability = self:GetAbility()
    for _, enemy in ipairs(Enemies(caster, self:GetParent():GetAbsOrigin(), self.radius)) do
        Hit(enemy, caster, ability, Value(self, "damage_per_second") * 0.5)
        enemy:AddNewModifier(caster, ability, "modifier_arena_green_spore_sickness", { duration = 0.75 })
    end
end

function cloud:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.cloud)
    UTIL_Remove(self:GetParent())
end

local sickness = Define("modifier_arena_green_spore_sickness", { debuff = true })

function sickness:OnCreated() self.miss = Value(self, "miss_chance") end
function sickness:OnRefresh() self.miss = Value(self, "miss_chance") end
function sickness:DeclareFunctions() return { MODIFIER_PROPERTY_MISS_PERCENTAGE } end
function sickness:GetModifierMiss_Percentage() return self.miss end
function sickness:GetEffectName() return P.sickness end
function sickness:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

----------------------------------------------------------- Mending Sap (spore shaman)

arena_green_mending_sap = class({})

function arena_green_mending_sap:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    target:Heal(self:GetSpecialValueFor("heal"), self)
    target:AddNewModifier(caster, self, "modifier_arena_green_mending_sap", { duration = self:GetSpecialValueFor("duration") })
    ArenaFxCore.On(P.sap, target)
    target:EmitSound(S.sap)
end

local sap = Define("modifier_arena_green_mending_sap")

function sap:OnCreated() self.regen = Value(self, "regen") end
function sap:OnRefresh() self.regen = Value(self, "regen") end
function sap:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT } end
function sap:GetModifierConstantHealthRegen() return self.regen end

-------------------------------------------------------------- Root Grasp (grove hulk)

arena_green_root_grasp = class({})

function arena_green_root_grasp:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    if target:TriggerSpellAbsorb(self) then return end
    target:AddNewModifier(caster, self, "modifier_arena_green_rooted", {
        duration = self:GetSpecialValueFor("duration"),
        dps = self:GetSpecialValueFor("damage_per_second"),
    })
    ArenaFxCore.Burst(P.root_burst, target:GetAbsOrigin())
    target:EmitSound(S.root)
end

--------------------------------------------------------------- Bark Skin (grove hulk)

arena_green_bark_skin = class({})

function arena_green_bark_skin:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_arena_green_bark_skin", { duration = self:GetSpecialValueFor("duration") })
    caster:EmitSound(S.bark)
end

local bark = Define("modifier_arena_green_bark_skin")

function bark:OnCreated()
    self.armor = Value(self, "armor")
    self.regen = Value(self, "regen")
end
bark.OnRefresh = bark.OnCreated
function bark:DeclareFunctions()
    return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT }
end
function bark:GetModifierPhysicalArmorBonus() return self.armor end
function bark:GetModifierConstantHealthRegen() return self.regen end
function bark:GetEffectName() return P.bark end
function bark:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

--------------------------------------------------------- Venom Spit (strangler bloom)

arena_green_venom_spit = class({})

function arena_green_venom_spit:OnSpellStart()
    Projectile(self, self:GetCursorTarget(), P.venom_spit)
    self:GetCaster():EmitSound(S.venom_spit)
end

function arena_green_venom_spit:OnProjectileHit(target)
    if not target or target:TriggerSpellAbsorb(self) then return true end
    local caster = self:GetCaster()
    Hit(target, caster, self, self:GetSpecialValueFor("damage"))
    target:AddNewModifier(caster, self, "modifier_arena_green_venom", { duration = self:GetSpecialValueFor("duration") })
    target:EmitSound(S.venom_hit)
    return true
end

local venom = Define("modifier_arena_green_venom", { debuff = true })

function venom:OnCreated()
    self.slow = Value(self, "slow")
    if IsServer() then
        self:StartIntervalThink(1)
    end
end
function venom:OnRefresh() self.slow = Value(self, "slow") end
function venom:OnIntervalThink()
    Hit(self:GetParent(), self:GetCaster(), self:GetAbility(), Value(self, "poison_dps"))
end
function venom:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function venom:GetModifierMoveSpeedBonus_Percentage() return -self.slow end
function venom:GetEffectName() return P.venom end
function venom:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

--------------------------------------------------------------------------------- the boss
-- Ability levels are the boss's phase: level 2 and 3 values are its phase 2 and 3 versions.

-- Root Eruption: a closing ring under every hero near the boss; roots burst out when it closes.
arena_green_boss_root_eruption = class({})

function arena_green_boss_root_eruption:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local targets = FindUnitsInRadius(caster:GetTeamNumber(), origin, nil, self:GetSpecialValueFor("search_radius"),
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_ANY_ORDER, false)
    if #targets == 0 and caster:GetAttackTarget() then
        targets = { caster:GetAttackTarget() }
    end
    for _, target in ipairs(targets) do
        CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
            duration = self:GetSpecialValueFor("delay"),
            shape = "circle",
            radius = self:GetSpecialValueFor("radius"),
        }, target:GetAbsOrigin(), caster:GetTeamNumber(), false)
    end
    ArenaFxCore.On(P.boss_cast, caster)
    caster:EmitSound(S.eruption_cast)
end

function arena_green_boss_root_eruption:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    ArenaFxCore.Burst(P.root_burst, position, data.radius)
    EmitSoundOnLocationWithCaster(position, S.eruption, caster)
    for _, enemy in ipairs(Enemies(caster, position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_arena_green_rooted", { duration = self:GetSpecialValueFor("root_duration") })
    end
end

-- Thorn Nova: the boss roots itself and channels while a ring closes around it, then thorns burst
-- out to the ring's edge. Walk out of the ring, or stun the boss to cancel it.
arena_green_boss_thorn_nova = class({})

function arena_green_boss_thorn_nova:OnSpellStart()
    local caster = self:GetCaster()
    self.warning = ArenaFxCore.Circle(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetChannelTime())
    ArenaFxCore.On(P.boss_cast, caster)
    caster:EmitSound(S.nova_channel)
end

function arena_green_boss_thorn_nova:OnChannelFinish(interrupted)
    local caster = self:GetCaster()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    caster:StopSound(S.nova_channel)
    if interrupted then return end
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    ArenaFxCore.Burst(P.slam, origin, radius)
    caster:EmitSound(S.nova)
    for _, enemy in ipairs(Enemies(caster, origin, radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_arena_green_thorned", { duration = self:GetSpecialValueFor("slow_duration") })
    end
end

-- Falling Timber: a line marks where a great tree will fall; whoever is still on it is crushed.
arena_green_boss_falling_timber = class({})

function arena_green_boss_falling_timber:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local point = self:GetCursorPosition()
    local dx, dy = point.x - origin.x, point.y - origin.y
    local length = math.sqrt(dx * dx + dy * dy)
    local direction = length > 1 and Vector(dx / length, dy / length, 0) or caster:GetForwardVector()
    local far = origin + direction * self:GetSpecialValueFor("length")
    CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
        duration = self:GetSpecialValueFor("delay"),
        shape = "line",
        x2 = far.x,
        y2 = far.y,
        width = self:GetSpecialValueFor("width"),
    }, origin, caster:GetTeamNumber(), false)
    caster:EmitSound(S.timber_cast)
end

function arena_green_boss_falling_timber:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    local far = Vector(data.x2, data.y2, position.z)
    local enemies = FindUnitsInLine(caster:GetTeamNumber(), position, far, nil, data.width, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)
    for _, enemy in ipairs(enemies) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
    end
    local steps = math.max(1, math.floor(self:GetSpecialValueFor("length") / 250))
    for step = 0, steps do
        ArenaFxCore.Burst(P.slam, position + (far - position) * (step / steps), data.width)
    end
    EmitSoundOnLocationWithCaster(far, S.timber, caster)
end

-- Call of the Grove: sproutlings rise around the boss and fight beside it for a while.
arena_green_boss_call_of_the_grove = class({})

function arena_green_boss_call_of_the_grove:OnSpellStart()
    if not IsServer() or not ArenaBosses then return end
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local count = math.min(self:GetSpecialValueFor("count"), self:GetSpecialValueFor("max_alive") - ArenaBosses.CountAdds(caster))
    for index = 1, count do
        local angle = 2 * math.pi * index / math.max(1, count)
        local position = origin + Vector(math.cos(angle) * 260, math.sin(angle) * 260, 0)
        ArenaFxCore.Burst(P.sprout, position)
        ArenaBosses.Summon(caster, "npc_arena_green_sproutling", position, self:GetSpecialValueFor("duration"))
    end
    ArenaFxCore.On(P.summon, caster)
    caster:EmitSound(S.summon)
end
