-- Abilities and modifiers of the desert biome (the Sunken Dunes). Every ability in
-- npc/abilities/arena/arena_desert_abilities.txt names this file as its ScriptFile; the class
-- name of each ability is its KV name. Numbers come from the KV AbilityValues, effects from
-- fx.lua next to this file.
--
-- The desert's identity: things that burrow and strike from below, sand that blinds and shoves,
-- venom that wears a fighter down, the sun that punishes heroes who bunch up, and ground that
-- swallows whoever stands still.
--
-- The client loads this file on its own when it first sees one of the modifiers below, so it
-- requires what it uses, keeps server work behind IsServer(), and defines and links every desert
-- modifier itself (the client links a modifier only from the script that calls LinkLuaModifier).
-- Every desert modifier is added with a desert ability behind it. Telegraphed moves use the
-- shared modifier_arena_delayed_strike: create it as a thinker where the hit will land, and the
-- ability's OnArenaStrike(position, data) runs when the warning runs out.

require("arena/core/fx")
require("arena/core/modifiers")
local FX = require("arena/biomes/desert/fx")

local FILE = "arena/biomes/desert/abilities.lua"
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

-- Visible enemy heroes near `position`, nearest first.
local function Heroes(caster, position, radius)
    return FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE, FIND_CLOSEST, false)
end

local function EnemiesInLine(caster, from, to, width)
    return FindUnitsInLine(caster:GetTeamNumber(), from, to, nil, width, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)
end

local function Hit(victim, caster, ability, damage)
    ApplyDamage({ victim = victim, attacker = caster, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
end

local function Alive(unit)
    return unit ~= nil and not unit:IsNull() and unit:IsAlive()
end

-- Unit vector on the ground from `from` toward `to`; the unit's facing when the two coincide.
local function Direction(from, to, unit)
    local dx, dy = to.x - from.x, to.y - from.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length > 1 then
        return Vector(dx / length, dy / length, 0)
    end
    return unit:GetForwardVector()
end

-- Shoves `victim` away from `center` with Dota's own knockback (it briefly stuns while airborne).
local function Knockback(victim, caster, ability, center, distance, duration, height)
    victim:AddNewModifier(caster, ability, "modifier_knockback", {
        center_x = center.x, center_y = center.y, center_z = center.z,
        knockback_distance = distance, knockback_height = height or 60,
        knockback_duration = duration, duration = duration, should_stun = 1,
    })
end

-- A ring on the ground that follows `unit`, showing a danger radius (Sun Brand, Caustic Venom).
local function Ring(unit, radius)
    local index = ParticleManager:CreateParticle(P.danger_ring, PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControl(index, 1, Vector(radius, 0, 0))
    return index
end

-- Adds one stack of a stacking debuff (up to `maximum`) and refreshes it. Returns the modifier.
local function AddStack(target, caster, ability, name, duration, maximum)
    local modifier = target:AddNewModifier(caster, ability, name, { duration = duration })
    if modifier then
        modifier:SetStackCount(math.min(maximum, modifier:GetStackCount() + 1))
    end
    return modifier
end

---------------------------------------------------------------------------- shared debuffs

-- Sand in the eyes: attacks miss. The chance is the ability's "miss_chance" value.
local blinded = Define("modifier_arena_desert_blinded", { debuff = true })

function blinded:OnCreated() self.miss = Value(self, "miss_chance") end
function blinded:OnRefresh() self.miss = math.max(self.miss or 0, Value(self, "miss_chance")) end
function blinded:DeclareFunctions() return { MODIFIER_PROPERTY_MISS_PERCENTAGE } end
function blinded:GetModifierMiss_Percentage() return self.miss end
function blinded:GetEffectName() return P.blinded end
function blinded:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Swallowed to the knees by the sand: cannot move.
local sunk = Define("modifier_arena_desert_sunk", { debuff = true })

function sunk:CheckState() return { [MODIFIER_STATE_ROOTED] = true } end
function sunk:GetEffectName() return P.sunk end
function sunk:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Under the sand (Ambush, Undermine): unseen, untouchable and taking no orders until it bursts
-- out. Whoever burrows always comes back up when this ends, wherever it was left.
local burrowed = Define("modifier_arena_desert_burrowed", { hidden = true, purgable = false })

-- Wearables (the boss's head, claws and tail) are separate entities: hide them with the body.
local NODRAW = 32   -- EF_NODRAW
local function ShowWearables(parent, show)
    if not parent.GetChildren then return end
    for _, child in pairs(parent:GetChildren() or {}) do
        if child and not child:IsNull() and child.GetClassname and child:GetClassname() == "dota_item_wearable" then
            if show then child:RemoveEffects(NODRAW) else child:AddEffects(NODRAW) end
        end
    end
end

function burrowed:OnCreated()
    if not IsServer() then return end
    local parent = self:GetParent()
    ArenaFxCore.Burst(P.burrow, parent:GetAbsOrigin())
    parent:EmitSound(S.burrow_in)
    parent:AddNoDraw()
    ShowWearables(parent, false)
end
function burrowed:OnDestroy()
    if not IsServer() then return end
    local parent = self:GetParent()
    if parent:IsNull() then return end
    parent:RemoveNoDraw()
    ShowWearables(parent, true)
    FindClearSpaceForUnit(parent, parent:GetAbsOrigin(), true)
end
function burrowed:CheckState()
    return {
        [MODIFIER_STATE_INVULNERABLE] = true,
        [MODIFIER_STATE_NO_HEALTH_BAR] = true,
        [MODIFIER_STATE_UNSELECTABLE] = true,
        [MODIFIER_STATE_NOT_ON_MINIMAP] = true,
        [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
        [MODIFIER_STATE_COMMAND_RESTRICTED] = true,
        [MODIFIER_STATE_ROOTED] = true,
        [MODIFIER_STATE_DISARMED] = true,
    }
end

local function Burrow(caster, ability, duration)
    caster:AddNewModifier(caster, ability, "modifier_arena_desert_burrowed", { duration = duration })
end

-- Moves a burrowed caster to `position` and brings it up.
local function Emerge(caster, position)
    caster:SetAbsOrigin(position)
    FindClearSpaceForUnit(caster, position, true)
    caster:RemoveModifierByName("modifier_arena_desert_burrowed")
    ArenaFxCore.Burst(P.emerge, position)
    EmitSoundOnLocationWithCaster(position, S.burrow_out, caster)
end

-- A line in front of the caster toward the cast point, `length` long. Used by the line moves,
-- which draw it during their cast point so it can be sidestepped.
local function CastLine(ability, length)
    local caster = ability:GetCaster()
    local origin = caster:GetAbsOrigin()
    local direction = Direction(origin, ability:GetCursorPosition(), caster)
    return origin, origin + direction * length
end

local function WarnLine(ability)
    if IsServer() then
        local from, to = CastLine(ability, ability:GetSpecialValueFor("length"))
        ability.warning = ArenaFxCore.Line(from, GetGroundPosition(to, nil))
    end
    return true
end

local function ClearWarning(ability)
    ArenaFxCore.Stop(ability.warning)
    ability.warning = nil
end

-------------------------------------------------------------------- Ambush (oasis lurker)
-- Dives into the sand and bursts up under its prey a moment later. The ring marks the spot.

arena_desert_ambush = class({})

function arena_desert_ambush:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    if not target or target:TriggerSpellAbsorb(self) then return end
    local delay = self:GetSpecialValueFor("delay")
    Burrow(caster, self, delay + 0.5)
    CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
        duration = delay, shape = "circle", radius = self:GetSpecialValueFor("radius"),
    }, target:GetAbsOrigin(), caster:GetTeamNumber(), false)
end

function arena_desert_ambush:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    Emerge(caster, position)
    for _, enemy in ipairs(Enemies(caster, position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
    end
end

---------------------------------------------------------------- Dust Kick (dust outrider)
-- Rears and kicks a spray of sand down a line: damage and blindness. The line shows first.

arena_desert_dust_kick = class({})

arena_desert_dust_kick.OnAbilityPhaseStart = WarnLine
arena_desert_dust_kick.OnAbilityPhaseInterrupted = ClearWarning

function arena_desert_dust_kick:OnSpellStart()
    ClearWarning(self)
    local caster = self:GetCaster()
    local from, to = CastLine(self, self:GetSpecialValueFor("length"))
    local width = self:GetSpecialValueFor("width")
    for _, enemy in ipairs(EnemiesInLine(caster, from, to, width)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_arena_desert_blinded", { duration = self:GetSpecialValueFor("blind_duration") })
    end
    for step = 1, 3 do
        ArenaFxCore.Burst(P.dust_kick, from + (to - from) * (step / 3), width)
    end
    caster:EmitSound(S.dust_kick)
end

--------------------------------------------------- Withering Venom (sandscale basilisk)
-- Every bite adds a dose of venom; each dose burns and slows a little more. Back off and let it fade.

arena_desert_withering_venom = class({})

function arena_desert_withering_venom:GetIntrinsicModifierName()
    return "modifier_arena_desert_withering_venom"
end

local fangs = Define("modifier_arena_desert_withering_venom", { hidden = true, purgable = false })

function fangs:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end

function fangs:OnAttackLanded(event)
    if not IsServer() then return end
    local parent, target = self:GetParent(), event.target
    local ability = self:GetAbility()
    if event.attacker ~= parent or parent:PassivesDisabled() or not target or target:IsBuilding()
        or target:GetTeamNumber() == parent:GetTeamNumber() or not ability or ability:GetLevel() < 1 then
        return
    end
    AddStack(target, parent, ability, "modifier_arena_desert_withering", Value(self, "duration"), Value(self, "max_stacks"))
end

local withering = Define("modifier_arena_desert_withering", { debuff = true })

function withering:OnCreated()
    if IsServer() then
        self:StartIntervalThink(1)
    end
end
function withering:OnIntervalThink()
    Hit(self:GetParent(), self:GetCaster(), self:GetAbility(), Value(self, "damage_per_stack") * self:GetStackCount())
end
function withering:DeclareFunctions()
    return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_TOOLTIP }
end
function withering:GetModifierMoveSpeedBonus_Percentage() return -Value(self, "slow_per_stack") * self:GetStackCount() end
function withering:OnTooltip() return Value(self, "damage_per_stack") * self:GetStackCount() end
function withering:GetEffectName() return P.venom end
function withering:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

----------------------------------------------------- Sun Brand (sun priest, and the boss)
-- Brands a hero. The ring that follows the bearer is the blast: when the brand runs out the sun
-- strikes everyone inside it. Bearers should walk away from their friends.

local brand = Define("modifier_arena_desert_sun_brand", { debuff = true, purgable = false })

function brand:OnCreated()
    self.radius = Value(self, "radius")
    if not IsServer() then return end
    self.damage = Value(self, "damage")
    local parent = self:GetParent()
    self.effects = { ParticleManager:CreateParticle(P.brand_mark, PATTACH_OVERHEAD_FOLLOW, parent), Ring(parent, self.radius) }
    parent:EmitSound(S.brand_cast)
end
function brand:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.effects)
    self.effects = nil
    local caster, ability, parent = self:GetCaster(), self:GetAbility(), self:GetParent()
    -- A dead caster's brands fizzle, like every other pending strike.
    if not Alive(caster) or not ability or ability:IsNull() or parent:IsNull() then return end
    local position = parent:GetAbsOrigin()
    ArenaFxCore.Burst(P.brand_blast, position, self.radius)
    EmitSoundOnLocationWithCaster(position, S.brand_blast, caster)
    for _, enemy in ipairs(Enemies(caster, position, self.radius)) do
        Hit(enemy, caster, ability, self.damage)
    end
end
function brand:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function brand:OnTooltip() return self.radius end

local function Brand(ability, target)
    local caster = ability:GetCaster()
    target:AddNewModifier(caster, ability, "modifier_arena_desert_sun_brand", { duration = ability:GetSpecialValueFor("delay") })
end

arena_desert_sun_brand = class({})

function arena_desert_sun_brand:OnSpellStart()
    local target = self:GetCursorTarget()
    if not target or target:TriggerSpellAbsorb(self) then return end
    Brand(self, target)
end

------------------------------------------------------------ Heat Shimmer (sun priest)
-- The air ripples around the priest's camp: its allies become mirages that blows pass through.

arena_desert_heat_shimmer = class({})

function arena_desert_heat_shimmer:OnSpellStart()
    local caster = self:GetCaster()
    local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"),
        DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
    for _, ally in ipairs(allies) do
        ally:AddNewModifier(caster, self, "modifier_arena_desert_heat_shimmer", { duration = self:GetSpecialValueFor("duration") })
    end
    caster:EmitSound(S.shimmer)
end

local shimmer = Define("modifier_arena_desert_heat_shimmer")

function shimmer:OnCreated() self.evasion = Value(self, "evasion") end
function shimmer:OnRefresh() self.evasion = Value(self, "evasion") end
function shimmer:DeclareFunctions() return { MODIFIER_PROPERTY_EVASION_CONSTANT } end
function shimmer:GetModifierEvasion_Constant() return self.evasion end
function shimmer:GetEffectName() return P.shimmer end
function shimmer:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

--------------------------------------------------------------- Quicksand (dune behemoth)
-- Turns a patch of ground to quicksand. Each half second inside sinks a hero deeper (slower);
-- sink all the way and the sand holds it fast. Get out early.

arena_desert_quicksand = class({})

function arena_desert_quicksand:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function arena_desert_quicksand:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()
    CreateModifierThinker(caster, self, "modifier_arena_desert_quicksand", { duration = self:GetSpecialValueFor("duration") },
        point, caster:GetTeamNumber(), false)
    EmitSoundOnLocationWithCaster(point, S.quicksand, caster)
end

local pit = Define("modifier_arena_desert_quicksand", { hidden = true, purgable = false })

function pit:OnCreated()
    if not IsServer() then return end
    self.radius = Value(self, "radius")
    local parent = self:GetParent()
    local cloud = ParticleManager:CreateParticle(P.sandstorm, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(cloud, 0, parent:GetAbsOrigin())
    ParticleManager:SetParticleControl(cloud, 1, Vector(self.radius, self.radius, 0))
    self.effects = { cloud, Ring(parent, self.radius) }
    self:StartIntervalThink(0.5)
end

function pit:OnIntervalThink()
    local caster, ability = self:GetCaster(), self:GetAbility()
    if not Alive(caster) or not ability or ability:IsNull() then return end
    for _, enemy in ipairs(Enemies(caster, self:GetParent():GetAbsOrigin(), self.radius)) do
        Hit(enemy, caster, ability, Value(self, "damage_per_second") * 0.5)
        if not enemy:HasModifier("modifier_arena_desert_sunk") then
            local sinking = AddStack(enemy, caster, ability, "modifier_arena_desert_sinking", 1, Value(self, "max_stacks"))
            if sinking and sinking:GetStackCount() >= Value(self, "max_stacks") then
                enemy:RemoveModifierByName("modifier_arena_desert_sinking")
                enemy:AddNewModifier(caster, ability, "modifier_arena_desert_sunk", { duration = Value(self, "root_duration") })
            end
        end
    end
end

function pit:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.effects)
    self.effects = nil
    UTIL_Remove(self:GetParent())
end

local sinking = Define("modifier_arena_desert_sinking", { debuff = true })

function sinking:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function sinking:GetModifierMoveSpeedBonus_Percentage() return -Value(self, "slow_per_stack") * self:GetStackCount() end

--------------------------------------------------------------- Dune Slam (dune behemoth)
-- Rears up while a ring closes around it, then slams: everyone inside is hurt and thrown out.

arena_desert_dune_slam = class({})

function arena_desert_dune_slam:OnAbilityPhaseStart()
    if IsServer() then
        self.warning = ArenaFxCore.Circle(self:GetCaster():GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint())
    end
    return true
end

arena_desert_dune_slam.OnAbilityPhaseInterrupted = ClearWarning

function arena_desert_dune_slam:OnSpellStart()
    ClearWarning(self)
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    ArenaFxCore.Burst(P.slam, origin, radius)
    caster:EmitSound(S.slam)
    for _, enemy in ipairs(Enemies(caster, origin, radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        Knockback(enemy, caster, self, origin, self:GetSpecialValueFor("knockback"), 0.4, 80)
    end
end

-------------------------------------------------------------- Sandstorm (sirocco khan)
-- Wraps itself in a storm for a few seconds: everyone close is scoured and half blind.

arena_desert_sandstorm = class({})

function arena_desert_sandstorm:OnSpellStart()
    local caster = self:GetCaster()
    caster:AddNewModifier(caster, self, "modifier_arena_desert_sandstorm", { duration = self:GetSpecialValueFor("duration") })
end

local storm = Define("modifier_arena_desert_sandstorm", { purgable = false })

function storm:OnCreated()
    self.radius = Value(self, "radius")
    if not IsServer() then return end
    local parent = self:GetParent()
    self.cloud = ParticleManager:CreateParticle(P.sandstorm, PATTACH_ABSORIGIN_FOLLOW, parent)
    ParticleManager:SetParticleControl(self.cloud, 1, Vector(self.radius, self.radius, 0))
    parent:EmitSound(S.sandstorm)
    parent:EmitSound(S.sandstorm_loop)
    self:StartIntervalThink(0.5)
end

function storm:OnIntervalThink()
    local parent, ability = self:GetParent(), self:GetAbility()
    if not ability or ability:IsNull() then return end
    for _, enemy in ipairs(Enemies(parent, parent:GetAbsOrigin(), self.radius)) do
        Hit(enemy, parent, ability, Value(self, "damage_per_second") * 0.5)
        enemy:AddNewModifier(parent, ability, "modifier_arena_desert_blinded", { duration = 1 })
    end
end

function storm:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.cloud)
    self.cloud = nil
    self:GetParent():StopSound(S.sandstorm_loop)
end

function storm:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function storm:OnTooltip() return self.radius end

---------------------------------------------------------- Sirocco Gust (sirocco khan)
-- A blast of hot wind down a line: damage, and everyone on it is thrown back.

arena_desert_sirocco_gust = class({})

arena_desert_sirocco_gust.OnAbilityPhaseStart = WarnLine
arena_desert_sirocco_gust.OnAbilityPhaseInterrupted = ClearWarning

function arena_desert_sirocco_gust:OnSpellStart()
    ClearWarning(self)
    local caster = self:GetCaster()
    local from, to = CastLine(self, self:GetSpecialValueFor("length"))
    for _, enemy in ipairs(EnemiesInLine(caster, from, to, self:GetSpecialValueFor("width"))) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        Knockback(enemy, caster, self, from, self:GetSpecialValueFor("knockback"), 0.5, 50)
    end
    local effect = ParticleManager:CreateParticle(P.gust, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(effect, 0, from)
    ParticleManager:SetParticleControl(effect, 1, GetGroundPosition(to, nil))
    ParticleManager:ReleaseParticleIndex(effect)
    caster:EmitSound(S.gust)
end

--------------------------------------------------------------------------------- the boss
-- Ability levels are the boss's phase: level 2 and 3 values are its phase 2 and 3 versions.

-- Caustic Venom: every blow adds a dose. One dose short of bursting, a ring shows around the
-- victim; the next blow bursts the venom over everyone inside it. The tank should stand alone.
arena_desert_boss_caustic_venom = class({})

function arena_desert_boss_caustic_venom:GetIntrinsicModifierName()
    return "modifier_arena_desert_caustic_sting"
end

function arena_desert_boss_caustic_venom:Burst(target)
    local caster = self:GetCaster()
    local position = target:GetAbsOrigin()
    target:RemoveModifierByName("modifier_arena_desert_caustic")
    ArenaFxCore.Burst(P.venom_burst, position, self:GetSpecialValueFor("burst_radius"))
    EmitSoundOnLocationWithCaster(position, S.venom_burst, caster)
    for _, enemy in ipairs(Enemies(caster, position, self:GetSpecialValueFor("burst_radius"))) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("burst_damage"))
    end
end

local sting = Define("modifier_arena_desert_caustic_sting", { hidden = true, purgable = false })

function sting:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end

function sting:OnAttackLanded(event)
    if not IsServer() then return end
    local parent, target = self:GetParent(), event.target
    local ability = self:GetAbility()
    if event.attacker ~= parent or parent:PassivesDisabled() or not target or target:IsBuilding()
        or target:GetTeamNumber() == parent:GetTeamNumber() or not ability or ability:GetLevel() < 1 then
        return
    end
    local maximum = Value(self, "max_stacks")
    local dose = AddStack(target, parent, ability, "modifier_arena_desert_caustic", Value(self, "duration"), maximum)
    if not dose then return end
    if dose:GetStackCount() >= maximum then
        ability:Burst(target)
    elseif dose:GetStackCount() == maximum - 1 and not dose.ring then
        dose.ring = Ring(target, Value(self, "burst_radius"))
    end
end

local caustic = Define("modifier_arena_desert_caustic", { debuff = true, purgable = false })

function caustic:OnCreated()
    if IsServer() then
        self:StartIntervalThink(1)
    end
end
function caustic:OnIntervalThink()
    Hit(self:GetParent(), self:GetCaster(), self:GetAbility(), Value(self, "damage_per_stack") * self:GetStackCount())
end
function caustic:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.ring)
    self.ring = nil
end
function caustic:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function caustic:OnTooltip() return Value(self, "max_stacks") end
function caustic:GetEffectName() return P.venom end
function caustic:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Undermine: the king sinks into the dunes and erupts under a hero a moment later, wherever that
-- hero stood when the ring appeared.
arena_desert_boss_undermine = class({})

function arena_desert_boss_undermine:OnSpellStart()
    local caster = self:GetCaster()
    local delay = self:GetSpecialValueFor("delay")
    ArenaFxCore.On(P.boss_cast, caster)
    Burrow(caster, self, delay + 0.5)
    CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
        duration = delay, shape = "circle", radius = self:GetSpecialValueFor("radius"),
    }, GetGroundPosition(self:GetCursorPosition(), nil), caster:GetTeamNumber(), false)
end

function arena_desert_boss_undermine:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    Emerge(caster, position)
    ArenaFxCore.Burst(P.slam, position, data.radius)
    for _, enemy in ipairs(Enemies(caster, position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
    end
end

-- Sirocco: lines open from the king toward the nearest heroes (one, then two, then three); when
-- they run out a scouring wind tears down each line, hurting, blinding and throwing back.
arena_desert_boss_sirocco = class({})

function arena_desert_boss_sirocco:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local targets = Heroes(caster, origin, self:GetSpecialValueFor("search_radius"))
    if #targets == 0 and caster:GetAttackTarget() then
        targets = { caster:GetAttackTarget() }
    end
    local length = self:GetSpecialValueFor("length")
    for index = 1, math.min(#targets, self:GetSpecialValueFor("lines")) do
        local far = origin + Direction(origin, targets[index]:GetAbsOrigin(), caster) * length
        CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
            duration = self:GetSpecialValueFor("delay"), shape = "line",
            x2 = far.x, y2 = far.y, width = self:GetSpecialValueFor("width"),
        }, origin, caster:GetTeamNumber(), false)
    end
    ArenaFxCore.On(P.boss_cast, caster)
end

function arena_desert_boss_sirocco:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    local far = Vector(data.x2, data.y2, position.z)
    for _, enemy in ipairs(EnemiesInLine(caster, position, far, data.width)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_arena_desert_blinded", { duration = self:GetSpecialValueFor("blind_duration") })
        Knockback(enemy, caster, self, position, self:GetSpecialValueFor("knockback"), 0.5, 60)
    end
    local effect = ParticleManager:CreateParticle(P.gust, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(effect, 0, position)
    ParticleManager:SetParticleControl(effect, 1, GetGroundPosition(far, nil))
    ParticleManager:ReleaseParticleIndex(effect)
    EmitSoundOnLocationWithCaster(position, S.gust, caster)
end

-- Sun Brand (boss): brands every hero nearby at once. Each brand bursts around its own bearer,
-- so heroes standing together take every blast; spread out and each takes only their own.
arena_desert_boss_sun_brand = class({})

function arena_desert_boss_sun_brand:OnSpellStart()
    local caster = self:GetCaster()
    local targets = Heroes(caster, caster:GetAbsOrigin(), self:GetSpecialValueFor("search_radius"))
    if #targets == 0 and caster:GetAttackTarget() then
        targets = { caster:GetAttackTarget() }
    end
    for _, target in ipairs(targets) do
        Brand(self, target)
    end
    ArenaFxCore.On(P.boss_cast, caster)
end

-- Dune Collapse: the buried temple gives way. Rings open under every hero nearby and at random
-- spots around the king; when they close the sand falls in, crushing and holding whoever is inside.
arena_desert_boss_dune_collapse = class({})

function arena_desert_boss_dune_collapse:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local points = {}
    for _, hero in ipairs(Heroes(caster, origin, self:GetSpecialValueFor("search_radius"))) do
        points[#points + 1] = hero:GetAbsOrigin()
    end
    local scatter = self:GetSpecialValueFor("scatter")
    for _ = 1, self:GetSpecialValueFor("count") do
        points[#points + 1] = GetGroundPosition(origin + RandomVector(RandomFloat(scatter * 0.25, scatter)), nil)
    end
    for _, point in ipairs(points) do
        CreateModifierThinker(caster, self, "modifier_arena_delayed_strike", {
            duration = self:GetSpecialValueFor("delay"), shape = "circle", radius = self:GetSpecialValueFor("radius"),
        }, point, caster:GetTeamNumber(), false)
    end
    ArenaFxCore.On(P.boss_cast, caster)
    caster:EmitSound(S.collapse_cast)
end

function arena_desert_boss_dune_collapse:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    ArenaFxCore.Burst(P.collapse, position, data.radius)
    EmitSoundOnLocationWithCaster(position, S.collapse, caster)
    for _, enemy in ipairs(Enemies(caster, position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        enemy:AddNewModifier(caster, self, "modifier_arena_desert_sunk", { duration = self:GetSpecialValueFor("root_duration") })
    end
end
