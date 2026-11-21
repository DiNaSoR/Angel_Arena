-- Abilities and modifiers of the lava biome (the Scorched Reach). Every ability in
-- npc/abilities/arena/arena_lava_abilities.txt names this file as its ScriptFile; the class name
-- of each ability is its KV name. Numbers come from the KV AbilityValues, effects from fx.lua
-- next to this file.
--
-- What makes lava different:
--   Heat     a stacking burn (modifier_arena_lava_heat). Many lava attacks and auras add a stack;
--            every stack burns each second; it all cools off HEAT_DURATION seconds after the last
--            new stack. The longer a fight runs next to these monsters, the more it hurts.
--   Melting  stacking armor loss (modifier_arena_lava_melting) from lava strikes and breath.
--   Fire     burning ground (a thinker) left behind by eruptions, bombs, meteors and deaths.
--   Death    some monsters burst when they are killed: a ring marks the blast before it goes off.
--
-- The client loads this file on its own when it first sees one of the modifiers below, so it
-- requires what it uses and keeps server work behind IsServer(). Every lava modifier is defined
-- and linked here (the client links nothing else for us) and is always applied together with a
-- lava ability. Telegraphed moves use the shared modifier_arena_delayed_strike thinker; death
-- blasts use their own thinker (modifier_arena_lava_death_blast) because the shared one fizzles
-- when its caster is dead, which is exactly when a death blast goes off.

require("arena/core/fx")
require("arena/core/modifiers")
local FX = require("arena/biomes/lava/fx")

local FILE = "arena/biomes/lava/abilities.lua"
local P, S = FX.particles, FX.sounds

local HEAT = "modifier_arena_lava_heat"
local MELTING = "modifier_arena_lava_melting"
local BURNING = "modifier_arena_lava_burning"
local GROUND = "modifier_arena_lava_burning_ground"
local BLAST = "modifier_arena_lava_death_blast"
local STRIKE = "modifier_arena_delayed_strike"

local HEAT_MAX = 10          -- stacks
local HEAT_DURATION = 4      -- seconds without a new stack before heat cools off
local MELT_MAX = 10          -- fallback when the applying ability names no max_stacks

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

local function Usable(ability)
    if ability and not ability:IsNull() then return ability end
end

local function Value(modifier, key)
    local ability = Usable(modifier:GetAbility())
    return ability and ability:GetSpecialValueFor(key) or 0
end

local function Valid(unit)
    return unit ~= nil and not unit:IsNull()
end

local function Alive(unit)
    return Valid(unit) and unit:IsAlive()
end

-- Who deals a modifier's damage: its caster while that entity exists, else the modifier's own
-- parent (a thinker), so fire left by a dead monster still burns.
local function Source(modifier)
    local caster = modifier:GetCaster()
    if Valid(caster) then return caster end
    return modifier:GetParent()
end

local function Enemies(team, position, radius)
    return FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
end

local function Hit(victim, attacker, ability, damage)
    if not damage or damage <= 0 then return end
    ApplyDamage({ victim = victim, attacker = attacker, ability = Usable(ability), damage = damage, damage_type = DAMAGE_TYPE_MAGICAL })
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

-- Adds `stacks` of heat. Each stack burns for the strongest heat_dps any source has applied.
local function AddHeat(target, caster, ability, stacks)
    if not Alive(target) then return end
    local dps = ability:GetSpecialValueFor("heat_dps")
    local heat = target:FindModifierByName(HEAT)
    if heat then
        heat.dps = math.max(heat.dps or 0, dps)
        heat:SetDuration(HEAT_DURATION, true)
    else
        heat = target:AddNewModifier(caster, ability, HEAT, { duration = HEAT_DURATION, dps = dps })
    end
    if heat then
        heat:SetStackCount(math.min(HEAT_MAX, heat:GetStackCount() + (stacks or 1)))
    end
    return heat
end

-- Adds `stacks` of melting armor (armor_per_stack, max_stacks and melt_duration from the ability).
local function AddMelt(target, caster, ability, stacks)
    if not Alive(target) then return end
    local duration = ability:GetSpecialValueFor("melt_duration")
    local melt = target:FindModifierByName(MELTING)
    if melt then
        melt:SetDuration(duration, true)
    else
        melt = target:AddNewModifier(caster, ability, MELTING, { duration = duration })
    end
    if melt then
        local max = Value(melt, "max_stacks")
        melt:SetStackCount(math.min(max > 0 and max or MELT_MAX, melt:GetStackCount() + (stacks or 1)))
    end
    return melt
end

-- Leaves burning ground at `position` for `duration` seconds.
local function Fire(caster, ability, position, radius, dps, duration)
    if not duration or duration <= 0 or not dps or dps <= 0 or not Valid(caster) then return end
    return CreateModifierThinker(caster, ability, GROUND, { duration = duration, radius = radius, dps = dps },
        position, caster:GetTeamNumber(), false)
end

----------------------------------------------------------------------- shared debuffs

-- Heat: a stacking burn. Stack count = heat; refreshed by every new stack.
local heat = Define(HEAT, { debuff = true })

function heat:OnCreated(data)
    if not IsServer() then return end
    self.dps = data and data.dps or 0
    self:StartIntervalThink(1)
end
function heat:OnIntervalThink()
    local caster = self:GetCaster()
    if not Valid(caster) then
        self:Destroy()
        return
    end
    Hit(self:GetParent(), caster, self:GetAbility(), (self.dps or 0) * self:GetStackCount())
end
function heat:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP } end
function heat:OnTooltip() return self:GetStackCount() end
function heat:GetEffectName() return P.heat end
function heat:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Melting armor: -armor_per_stack armor for each stack.
local melting = Define(MELTING, { debuff = true })

function melting:OnCreated() self.armor = Value(self, "armor_per_stack") end
function melting:OnRefresh() self.armor = Value(self, "armor_per_stack") end
function melting:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function melting:GetModifierPhysicalArmorBonus() return -(self.armor or 0) * self:GetStackCount() end
function melting:GetEffectName() return P.melting end
function melting:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Standing in fire: shown while burning ground is hurting the unit.
local burning = Define(BURNING, { debuff = true, purgable = false })

function burning:GetEffectName() return P.burning end
function burning:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

-- Burning ground (a thinker). Numbers come in with the thinker: radius, dps.
local ground = Define(GROUND, { hidden = true, purgable = false })

function ground:OnCreated(data)
    if not IsServer() then return end
    data = data or {}
    self.radius = data.radius or 200
    self.dps = data.dps or 0
    self.fire = ParticleManager:CreateParticle(P.burning_ground, PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
    ParticleManager:SetParticleControl(self.fire, 1, Vector(self.radius, 0, 0))
    self:StartIntervalThink(0.5)
end

function ground:OnIntervalThink()
    local parent = self:GetParent()
    local attacker = Source(self)
    local ability = Usable(self:GetAbility())
    for _, enemy in ipairs(Enemies(parent:GetTeamNumber(), parent:GetAbsOrigin(), self.radius)) do
        Hit(enemy, attacker, ability, self.dps * 0.5)
        if ability then
            enemy:AddNewModifier(attacker, ability, BURNING, { duration = 0.75 })
        end
    end
end

function ground:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.fire)
    self.fire = nil
    UTIL_Remove(self:GetParent())
end

-- A death blast (a thinker): a ring closes over its duration, then it explodes. Numbers come in
-- with the thinker (radius, damage, fire_dps, fire_duration, big) because the monster that left it
-- may be gone by then. Unlike the shared delayed strike it goes off although its caster is dead.
local blast = Define(BLAST, { hidden = true, purgable = false })

function blast:OnCreated(data)
    if not IsServer() then return end
    self.data = data or {}
    self.warning = ArenaFxCore.Circle(self:GetParent():GetAbsOrigin(), self.data.radius or 200, self:GetDuration())
end

function blast:OnDestroy()
    if not IsServer() then return end
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    local parent = self:GetParent()
    local data = self.data or {}
    local origin = parent:GetAbsOrigin()
    local radius = data.radius or 200
    local attacker = Source(self)
    local ability = Usable(self:GetAbility())
    ArenaFxCore.Burst(P.eruption, origin, radius)
    ArenaFxCore.Burst(P.blast, origin)
    EmitSoundOnLocationWithCaster(origin, data.big == 1 and S.golem_blast or S.sprite_blast, attacker)
    for _, enemy in ipairs(Enemies(parent:GetTeamNumber(), origin, radius)) do
        Hit(enemy, attacker, ability, data.damage)
    end
    Fire(attacker, ability, origin, radius, data.fire_dps, data.fire_duration)
    UTIL_Remove(parent)
end

------------------------------------------------------------------ modifier factories

-- A passive that bursts when its owner is killed by an enemy (not when it expires, is killed by
-- its own side or is removed with its boss). Break stops it.
local function DeathBurst(name, big)
    local modifier = Define(name, { hidden = true, purgable = false })
    function modifier:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
    function modifier:OnDeath(event)
        if not IsServer() then return end
        local parent = self:GetParent()
        if event.unit ~= parent or parent:PassivesDisabled() then return end
        local killer = event.attacker
        if not Valid(killer) or killer == parent or killer:GetTeamNumber() == parent:GetTeamNumber() then return end
        local ability = Usable(self:GetAbility())
        if not ability or ability:GetLevel() < 1 then return end
        CreateModifierThinker(parent, ability, BLAST, {
            duration = ability:GetSpecialValueFor("delay"),
            radius = ability:GetSpecialValueFor("radius"),
            damage = ability:GetSpecialValueFor("damage"),
            fire_dps = ability:GetSpecialValueFor("fire_dps"),
            fire_duration = ability:GetSpecialValueFor("fire_duration"),
            big = big and 1 or 0,
        }, parent:GetAbsOrigin(), parent:GetTeamNumber(), false)
    end
    return modifier
end

-- A passive that does something to every enemy its owner's attacks land on.
local function OnHit(name, handler)
    local modifier = Define(name, { hidden = true, purgable = false })
    function modifier:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
    function modifier:OnAttackLanded(event)
        if not IsServer() then return end
        local parent, target = self:GetParent(), event.target
        if event.attacker ~= parent or parent:PassivesDisabled() or not Alive(target) or target:IsBuilding()
            or target:GetTeamNumber() == parent:GetTeamNumber() then
            return
        end
        local ability = Usable(self:GetAbility())
        if not ability or ability:GetLevel() < 1 then return end
        handler(parent, target, ability)
    end
    return modifier
end

-- A passive that adds a stack of heat (and burn_damage, if any) each second to every enemy within
-- the ability's radius.
local function HeatAura(name, effect)
    local modifier = Define(name, { hidden = true, purgable = false })
    function modifier:OnCreated()
        if not IsServer() then return end
        self:StartIntervalThink(1)
    end
    function modifier:OnIntervalThink()
        local parent = self:GetParent()
        local ability = Usable(self:GetAbility())
        if not ability or ability:GetLevel() < 1 or not parent:IsAlive() or parent:PassivesDisabled() then return end
        for _, enemy in ipairs(Enemies(parent:GetTeamNumber(), parent:GetAbsOrigin(), ability:GetSpecialValueFor("radius"))) do
            AddHeat(enemy, parent, ability, 1)
            Hit(enemy, parent, ability, ability:GetSpecialValueFor("burn_damage"))
        end
    end
    function modifier:GetEffectName() return effect end
    function modifier:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
    return modifier
end

----------------------------------------------------------- Volatile Core (ember sprite)

arena_lava_volatile_core = class({})
function arena_lava_volatile_core:GetIntrinsicModifierName() return "modifier_arena_lava_volatile_core" end
DeathBurst("modifier_arena_lava_volatile_core", false)

------------------------------------------------------ Smouldering Blows (ashen satyr)

arena_lava_smouldering_blows = class({})
function arena_lava_smouldering_blows:GetIntrinsicModifierName() return "modifier_arena_lava_smouldering_blows" end
OnHit("modifier_arena_lava_smouldering_blows", function(parent, target, ability)
    AddHeat(target, parent, ability, ability:GetSpecialValueFor("heat_stacks"))
end)

------------------------------------------------------- Melting Strikes (flame brawler)

arena_lava_melting_strikes = class({})
function arena_lava_melting_strikes:GetIntrinsicModifierName() return "modifier_arena_lava_melting_strikes" end
OnHit("modifier_arena_lava_melting_strikes", function(parent, target, ability)
    AddMelt(target, parent, ability, ability:GetSpecialValueFor("melt_stacks"))
end)

------------------------------------------------------------ Cinder Spit (magma drake)

arena_lava_cinder_spit = class({})

function arena_lava_cinder_spit:OnSpellStart()
    Projectile(self, self:GetCursorTarget(), P.spit)
    self:GetCaster():EmitSound(S.spit)
end

function arena_lava_cinder_spit:OnProjectileHit(target)
    if not target or target:TriggerSpellAbsorb(self) then return true end
    local caster = self:GetCaster()
    Hit(target, caster, self, self:GetSpecialValueFor("damage"))
    AddHeat(target, caster, self, self:GetSpecialValueFor("heat_stacks"))
    target:EmitSound(S.spit_hit)
    return true
end

---------------------------------------------------------- Eruption Slam (slag golem)
-- The ring during the wind-up is the warning; the ground it covers keeps burning afterwards.

arena_lava_eruption_slam = class({})

function arena_lava_eruption_slam:OnAbilityPhaseStart()
    if IsServer() then
        local caster = self:GetCaster()
        self.warning = ArenaFxCore.Circle(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint())
        caster:EmitSound(S.slam_charge)
    end
    return true
end

function arena_lava_eruption_slam:OnAbilityPhaseInterrupted()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
end

function arena_lava_eruption_slam:OnSpellStart()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    ArenaFxCore.Burst(P.eruption, origin, radius)
    caster:EmitSound(S.eruption)
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), origin, radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
    end
    Fire(caster, self, origin, radius, self:GetSpecialValueFor("fire_dps"), self:GetSpecialValueFor("fire_duration"))
end

---------------------------------------------------------- Searing Brand (cinder hexer)
-- A doom mark on one enemy. When it runs out it explodes on that enemy and everyone beside it:
-- step away from your allies, or dispel it.

arena_lava_searing_brand = class({})

function arena_lava_searing_brand:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    if target:TriggerSpellAbsorb(self) then return end
    target:AddNewModifier(caster, self, "modifier_arena_lava_searing_brand", { duration = self:GetSpecialValueFor("delay") })
    target:EmitSound(S.brand)
end

local brand = Define("modifier_arena_lava_searing_brand", { debuff = true })

function brand:OnDestroy()
    if not IsServer() then return end
    local parent, caster = self:GetParent(), self:GetCaster()
    -- Dispelled, or the bearer died: no blast.
    if not Alive(parent) or not Valid(caster) or self:GetRemainingTime() > 0.1 then return end
    local origin = parent:GetAbsOrigin()
    local radius = Value(self, "radius")
    ArenaFxCore.Burst(P.eruption, origin, radius)
    ArenaFxCore.Burst(P.blast, origin)
    EmitSoundOnLocationWithCaster(origin, S.brand_blast, caster)
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), origin, radius)) do
        Hit(enemy, caster, self:GetAbility(), Value(self, "damage"))
    end
end
function brand:GetEffectName() return P.brand end
function brand:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

---------------------------------------------------------------- Kindle (cinder hexer)

arena_lava_kindle = class({})

function arena_lava_kindle:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    target:AddNewModifier(caster, self, "modifier_arena_lava_kindled", { duration = self:GetSpecialValueFor("duration") })
    target:EmitSound(S.kindle)
end

local kindled = Define("modifier_arena_lava_kindled")

function kindled:OnCreated() self.speed = Value(self, "attack_speed") end
function kindled:OnRefresh() self.speed = Value(self, "attack_speed") end
function kindled:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function kindled:GetModifierAttackSpeedBonus_Constant() return self.speed or 0 end
function kindled:OnAttackLanded(event)
    if not IsServer() then return end
    local parent, target = self:GetParent(), event.target
    if event.attacker ~= parent or not Alive(target) or target:IsBuilding() or target:GetTeamNumber() == parent:GetTeamNumber() then
        return
    end
    local ability = Usable(self:GetAbility())
    if ability then
        AddHeat(target, parent, ability, 1)
    end
end
function kindled:GetEffectName() return P.kindle end
function kindled:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

--------------------------------------------------------- Hellfire Aura (infernal golem)

arena_lava_hellfire_aura = class({})
function arena_lava_hellfire_aura:GetIntrinsicModifierName() return "modifier_arena_lava_hellfire_aura" end
HeatAura("modifier_arena_lava_hellfire_aura", P.golem_aura)

---------------------------------------------------------- Death Throes (infernal golem)

arena_lava_death_throes = class({})
function arena_lava_death_throes:GetIntrinsicModifierName() return "modifier_arena_lava_death_throes" end
DeathBurst("modifier_arena_lava_death_throes", true)

---------------------------------------------------------------- Lava Bomb (magma wyrm)

arena_lava_lava_bomb = class({})

function arena_lava_lava_bomb:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function arena_lava_lava_bomb:OnSpellStart()
    local caster = self:GetCaster()
    CreateModifierThinker(caster, self, STRIKE, {
        duration = self:GetSpecialValueFor("delay"),
        shape = "circle",
        radius = self:GetSpecialValueFor("radius"),
    }, self:GetCursorPosition(), caster:GetTeamNumber(), false)
    caster:EmitSound(S.bomb_cast)
end

function arena_lava_lava_bomb:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    ArenaFxCore.Burst(P.eruption, position, data.radius)
    EmitSoundOnLocationWithCaster(position, S.bomb, caster)
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
    end
    Fire(caster, self, position, data.radius, self:GetSpecialValueFor("fire_dps"), self:GetSpecialValueFor("fire_duration"))
end

----------------------------------------------------------- Searing Breath (magma wyrm)
-- A line marks the breath; whoever is still on it when it comes takes damage and melts.

arena_lava_searing_breath = class({})

function arena_lava_searing_breath:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local point = self:GetCursorPosition()
    local dx, dy = point.x - origin.x, point.y - origin.y
    local length = math.sqrt(dx * dx + dy * dy)
    local direction = length > 1 and Vector(dx / length, dy / length, 0) or caster:GetForwardVector()
    local far = origin + direction * self:GetSpecialValueFor("length")
    CreateModifierThinker(caster, self, STRIKE, {
        duration = self:GetSpecialValueFor("delay"),
        shape = "line",
        x2 = far.x,
        y2 = far.y,
        width = self:GetSpecialValueFor("width"),
    }, origin, caster:GetTeamNumber(), false)
end

function arena_lava_searing_breath:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    local far = Vector(data.x2, data.y2, position.z)
    local enemies = FindUnitsInLine(caster:GetTeamNumber(), position, far, nil, data.width, DOTA_UNIT_TARGET_TEAM_ENEMY,
        DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)
    for _, enemy in ipairs(enemies) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        AddMelt(enemy, caster, self, self:GetSpecialValueFor("melt_stacks"))
    end
    local steps = math.max(1, math.floor(self:GetSpecialValueFor("length") / 200))
    for step = 1, steps do
        ArenaFxCore.Burst(P.eruption, position + (far - position) * (step / steps), data.width)
    end
    caster:EmitSound(S.breath)
end

--------------------------------------------------------------------------------- the boss
-- Ability levels are the boss's phase: level 2 and 3 values are its phase 2 and 3 versions.

-- Heart of the Volcano (phase 3): the Tyrant plants itself and channels while a huge ring closes
-- around it. When it finishes, everything inside the ring burns EXCEPT the small ring at its feet:
-- run to it, not away. A stun cancels it.
arena_lava_boss_heart_of_the_volcano = class({})

function arena_lava_boss_heart_of_the_volcano:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local channel = self:GetChannelTime()
    self.warning = {
        ArenaFxCore.Circle(origin, self:GetSpecialValueFor("radius"), channel),
        ArenaFxCore.Circle(origin, self:GetSpecialValueFor("safe_radius"), channel),
    }
    ArenaFxCore.On(P.boss_cast, caster)
    caster:EmitSound(S.heart_channel)
end

function arena_lava_boss_heart_of_the_volcano:OnChannelFinish(interrupted)
    local caster = self:GetCaster()
    ArenaFxCore.Stop(self.warning)
    self.warning = nil
    caster:StopSound(S.heart_channel)
    if interrupted then return end
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    local safe = self:GetSpecialValueFor("safe_radius")
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), origin, radius)) do
        if (enemy:GetAbsOrigin() - origin):Length2D() > safe then
            Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
            AddHeat(enemy, caster, self, self:GetSpecialValueFor("heat_stacks"))
        end
    end
    ArenaFxCore.On(P.heart_blast, caster)
    for ring = 1, 2 do
        local distance = safe + (radius - safe) * ring / 3
        local count = 6 * ring
        for index = 1, count do
            local angle = 2 * math.pi * index / count
            ArenaFxCore.Burst(P.eruption, origin + Vector(math.cos(angle) * distance, math.sin(angle) * distance, 0), 200)
        end
    end
    caster:EmitSound(S.heart_blast)
end

-- Caldera Wake: rings of eruptions spread out from the Tyrant one wave after another. Each wave's
-- circles leave gaps, and the gaps of one wave sit behind the circles of the next. From phase 2
-- every eruption leaves burning ground.
arena_lava_boss_caldera_wake = class({})

function arena_lava_boss_caldera_wake:OnSpellStart()
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local radius = self:GetSpecialValueFor("radius")
    local spacing = self:GetSpecialValueFor("spacing")
    local first = self:GetSpecialValueFor("first_delay")
    local step = self:GetSpecialValueFor("wave_delay")
    for wave = 1, self:GetSpecialValueFor("waves") do
        local distance = spacing * wave
        local count = math.max(3, math.floor(2 * math.pi * distance / (radius * 2.6)))
        local offset = wave % 2 == 0 and math.pi / count or 0
        for index = 1, count do
            local angle = offset + 2 * math.pi * (index - 1) / count
            local position = GetGroundPosition(origin + Vector(math.cos(angle) * distance, math.sin(angle) * distance, 0), nil)
            CreateModifierThinker(caster, self, STRIKE, {
                duration = first + step * (wave - 1),
                shape = "circle",
                radius = radius,
                lead = index == 1 and 1 or 0,
            }, position, caster:GetTeamNumber(), false)
        end
    end
    ArenaFxCore.On(P.boss_cast, caster)
    caster:EmitSound(S.caldera_cast)
end

function arena_lava_boss_caldera_wake:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    ArenaFxCore.Burst(P.eruption, position, data.radius)
    if data.lead == 1 then
        EmitSoundOnLocationWithCaster(position, S.eruption, caster)
    end
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
    end
    Fire(caster, self, position, data.radius, self:GetSpecialValueFor("fire_dps"), self:GetSpecialValueFor("fire_duration"))
end

-- Pyroclast Barrage (phase 2): meteors chase one hero. Each lands where the hero stood a moment
-- before, after its own ring closes: keep moving and they miss.
arena_lava_boss_pyroclast_barrage = class({})

function arena_lava_boss_pyroclast_barrage:OnSpellStart()
    local caster, target = self:GetCaster(), self:GetCursorTarget()
    if target:TriggerSpellAbsorb(self) then return end
    local meteors = self:GetSpecialValueFor("meteors")
    local barrage = caster:AddNewModifier(caster, self, "modifier_arena_lava_barrage",
        { duration = meteors * self:GetSpecialValueFor("interval") + 0.1 })
    if barrage then
        barrage.target = target
    end
    self:Meteor(target)
    caster:EmitSound(S.barrage_cast)
end

function arena_lava_boss_pyroclast_barrage:Meteor(target)
    local caster = self:GetCaster()
    CreateModifierThinker(caster, self, STRIKE, {
        duration = self:GetSpecialValueFor("delay"),
        shape = "circle",
        radius = self:GetSpecialValueFor("radius"),
    }, target:GetAbsOrigin(), caster:GetTeamNumber(), false)
end

function arena_lava_boss_pyroclast_barrage:OnArenaStrike(position, data)
    local caster = self:GetCaster()
    ArenaFxCore.Burst(P.meteor, position, data.radius)
    EmitSoundOnLocationWithCaster(position, S.meteor, caster)
    for _, enemy in ipairs(Enemies(caster:GetTeamNumber(), position, data.radius)) do
        Hit(enemy, caster, self, self:GetSpecialValueFor("damage"))
        AddHeat(enemy, caster, self, self:GetSpecialValueFor("heat_stacks"))
    end
    Fire(caster, self, position, data.radius, self:GetSpecialValueFor("fire_dps"), self:GetSpecialValueFor("fire_duration"))
end

-- On the boss while a barrage is falling: drops the remaining meteors one interval apart.
local barrage = Define("modifier_arena_lava_barrage", { hidden = true, purgable = false })

function barrage:OnCreated()
    if not IsServer() then return end
    self.left = Value(self, "meteors") - 1
    self:StartIntervalThink(math.max(0.1, Value(self, "interval")))
end

function barrage:OnIntervalThink()
    local ability = Usable(self:GetAbility())
    if not ability or (self.left or 0) <= 0 or not Alive(self.target) then
        self:Destroy()
        return
    end
    self.left = self.left - 1
    ability:Meteor(self.target)
end

-- Brood of Cinders (phase 2): ember sprites burst out of the ground and fight beside the Tyrant.
-- Like their camp cousins they explode when killed.
arena_lava_boss_brood_of_cinders = class({})

function arena_lava_boss_brood_of_cinders:OnSpellStart()
    if not IsServer() or not ArenaBosses then return end
    local caster = self:GetCaster()
    local origin = caster:GetAbsOrigin()
    local count = math.min(self:GetSpecialValueFor("count"), self:GetSpecialValueFor("max_alive") - ArenaBosses.CountAdds(caster))
    for index = 1, count do
        local angle = 2 * math.pi * index / math.max(1, count)
        local position = origin + Vector(math.cos(angle) * 280, math.sin(angle) * 280, 0)
        ArenaFxCore.Burst(P.boss_cast, position)
        ArenaBosses.Summon(caster, "npc_arena_lava_ember_sprite", position, self:GetSpecialValueFor("duration"))
    end
    caster:EmitSound(S.summon)
end

-- Searing Presence (phase 1, passive): heroes near the Tyrant gain a stack of heat every second.
arena_lava_boss_searing_presence = class({})
function arena_lava_boss_searing_presence:GetIntrinsicModifierName() return "modifier_arena_lava_searing_presence" end
HeatAura("modifier_arena_lava_searing_presence", P.presence)

-- Infernal Brand (phase 1, passive): the Tyrant's blows melt armor.
arena_lava_boss_infernal_brand = class({})
function arena_lava_boss_infernal_brand:GetIntrinsicModifierName() return "modifier_arena_lava_infernal_brand" end
OnHit("modifier_arena_lava_infernal_brand", function(parent, target, ability)
    AddMelt(target, parent, ability, ability:GetSpecialValueFor("melt_stacks"))
end)
