-- Every visual and sound the Angel Arena items make, in one place.
--
-- The effects are assembled from Dota's own particle systems: a pillar of sunlight for the
-- angelic smite, Zeus' lightning for the storm blades, scorched earth for the hellfire auras,
-- and so on. Item code calls these by what happens ("Smite", "Chain"), never by particle
-- name, so an effect can be restaged here without touching the mechanics.

if ArenaFx then
    return ArenaFx
end

ArenaFx = {}

local HERO = "particles/units/heroes/"

local P = {
    lifesteal = "particles/generic_gameplay/generic_lifesteal.vpcf",
    manaburn = "particles/generic_gameplay/generic_manaburn.vpcf",
    coins = "particles/generic_gameplay/lasthit_coins.vpcf",
    bashed = "particles/generic_gameplay/generic_bashed.vpcf",
    levelup = "particles/generic_hero_status/hero_levelup.vpcf",
    flask = "particles/items_fx/healing_flask.vpcf",
    clarity = "particles/items_fx/healing_clarity.vpcf",
    cleave = HERO .. "hero_sven/sven_spell_great_cleave.vpcf",
    cleave_hell = HERO .. "hero_sven/sven_spell_great_cleave_gods_strength.vpcf",
    sunstrike = HERO .. "hero_invoker/invoker_sun_strike.vpcf",
    purify = HERO .. "hero_omniknight/omniknight_purification.vpcf",
    arc = HERO .. "hero_zuus/zuus_arc_lightning_.vpcf",
    bolt = HERO .. "hero_zuus/zuus_lightning_bolt.vpcf",
    hammer = HERO .. "hero_dawnbreaker/dawnbreaker_celestial_hammer_aoe_impact.vpcf",
    crit = HERO .. "hero_phantom_assassin/phantom_assassin_crit_impact.vpcf",
    soul = HERO .. "hero_nevermore/nevermore_necro_souls.vpcf",
    thorns = HERO .. "hero_centaur/centaur_return.vpcf",
    angel = HERO .. "hero_omniknight/omniknight_guardian_angel_omni.vpcf",
    angel_rays = HERO .. "hero_omniknight/omniknight_guardian_angel_wings_buff.vpcf",
    wings = HERO .. "hero_omniknight/omniknight_guardian_angel_wings.vpcf",
    blessing = HERO .. "hero_chen/chen_hand_of_god.vpcf",
    inferno = HERO .. "hero_warlock/warlock_rain_of_chaos_explosion.vpcf",
    fireburst = HERO .. "hero_jakiro/jakiro_liquid_fire_explosion.vpcf",
    laguna = HERO .. "hero_lina/lina_spell_laguna_blade.vpcf",
    shell = HERO .. "hero_abaddon/abaddon_aphotic_shield.vpcf",
    shell_break = HERO .. "hero_abaddon/abaddon_aphotic_shield_explosion.vpcf",
    scorched = HERO .. "hero_doom_bringer/doom_scorched_earth.vpcf",
    fire_ring = HERO .. "hero_ember_spirit/ember_spirit_flameguard.vpcf",
    rage_swirl = "particles/items2_fx/mask_of_madness.vpcf",
    infernal_hit = HERO .. "hero_doom_bringer/doom_infernal_blade_impact.vpcf",
}

-- Effects that last as long as a buff, returned from the modifier's GetEffectName.
ArenaFx.BUFF = {
    burning = HERO .. "hero_huskar/huskar_burning_spear_debuff.vpcf",
    brimstone = HERO .. "hero_phoenix/phoenix_fire_spirit_burn.vpcf",
    chilled = "particles/generic_gameplay/generic_slowed_cold.vpcf",
    chilled_status = "particles/status_fx/status_effect_frost.vpcf",
    rage = HERO .. "hero_bloodseeker/bloodseeker_bloodrage.vpcf",
    berserk = HERO .. "hero_bloodseeker/bloodseeker_thirst_owner.vpcf",
    aura = "particles/items2_fx/radiance_owner.vpcf",
}

local SOUND_FILES = {
    "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_omniknight.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_abaddon.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_bloodseeker.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_doombringer.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_chen.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_warlock.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_lina.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_phantom_assassin.vsndevts",
    "soundevents/game_sounds_heroes/game_sounds_sven.vsndevts",
}

function ArenaFx.Precache(context)
    for _, particle in pairs(P) do
        PrecacheResource("particle", particle, context)
    end
    for _, particle in pairs(ArenaFx.BUFF) do
        PrecacheResource("particle", particle, context)
    end
    for _, file in ipairs(SOUND_FILES) do
        PrecacheResource("soundfile", file, context)
    end
end

-------------------------------------------------------------------------------------- helpers

local function Release(index)
    ParticleManager:ReleaseParticleIndex(index)
end

-- A one-shot effect that follows a unit.
local function On(particle, unit, attach)
    Release(ParticleManager:CreateParticle(particle, attach or PATTACH_ABSORIGIN_FOLLOW, unit))
end

-- A one-shot effect at a point in the world. `size` goes to control point 1, where most of
-- Dota's area effects read their radius.
local function At(particle, position, size)
    local index = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(index, 0, position)
    if size then
        ParticleManager:SetParticleControl(index, 1, Vector(size, 0, 0))
    end
    Release(index)
end

local function Chest(unit)
    local origin = unit:GetAbsOrigin()
    return Vector(origin.x, origin.y, origin.z + 96)
end

-- A beam between two units, anchored where attacks leave and land.
local function Beam(particle, from, fromAttach, to)
    local index = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControlEnt(index, 0, from, PATTACH_POINT_FOLLOW, fromAttach, from:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(index, 1, to, PATTACH_POINT_FOLLOW, "attach_hitloc", to:GetAbsOrigin(), true)
    Release(index)
end

local function Shake(position, strength)
    ScreenShake(position, strength, 150, 0.4, 1200, 0, true)
end

------------------------------------------------------------------------------ attack effects

function ArenaFx.Lifesteal(unit)
    On(P.lifesteal, unit)
end

-- A pillar of sunlight on the target. `damage` sets how wide it lands.
function ArenaFx.Smite(target, damage)
    At(P.sunstrike, target:GetAbsOrigin(), 90 + math.min(160, damage / 4))
    target:EmitSound("Hero_Invoker.SunStrike.Ignite")
end

function ArenaFx.CleaveParticle(hellish)
    return hellish and P.cleave_hell or P.cleave
end

function ArenaFx.Scorch(target)
    On(P.infernal_hit, target)
end

-- One fork of lightning from a unit to the next.
function ArenaFx.Chain(from, to)
    local index = ParticleManager:CreateParticle(P.arc, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(index, 0, Chest(from))
    ParticleManager:SetParticleControl(index, 1, Chest(to))
    Release(index)
    to:EmitSound("Hero_Zuus.ArcLightning.Target")
end

function ArenaFx.Bash(target)
    On(P.bashed, target, PATTACH_OVERHEAD_FOLLOW)
    At(P.purify, target:GetAbsOrigin(), 120)
    target:EmitSound("DOTA_Item.SkullBasher")
end

function ArenaFx.ManaBurn(target)
    On(P.manaburn, target)
end

function ArenaFx.Crit(attacker, target)
    local index = ParticleManager:CreateParticle(P.crit, PATTACH_CUSTOMORIGIN, nil)
    ParticleManager:SetParticleControlEnt(index, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(index, 1, target:GetAbsOrigin())
    ParticleManager:SetParticleControlForward(index, 1, -attacker:GetForwardVector())
    ParticleManager:SetParticleControlEnt(index, 10, target, PATTACH_ABSORIGIN_FOLLOW, nil, target:GetAbsOrigin(), true)
    Release(index)
    target:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
end

-- A soul leaves the dead and flies to its new owner.
function ArenaFx.SoulClaim(victim, owner, ability)
    ProjectileManager:CreateTrackingProjectile({
        Target = owner,
        Source = victim,
        Ability = ability,
        EffectName = P.soul,
        iMoveSpeed = 900,
        vSourceLoc = victim:GetAbsOrigin(),
        bDodgeable = false,
        bProvidesVision = false,
    })
    owner:EmitSound("Hero_Nevermore.Necromastery")
end

function ArenaFx.Thorns(owner, attacker)
    Beam(P.thorns, owner, "attach_hitloc", attacker)
end

function ArenaFx.Coins(unit)
    On(P.coins, unit, PATTACH_OVERHEAD_FOLLOW)
end

-- Feathered wings on a unit's back for as long as the caller keeps the handle. The wings only
-- draw when their control points are pinned to the unit's body.
function ArenaFx.Wings(unit)
    local index = ParticleManager:CreateParticle(P.wings, PATTACH_ABSORIGIN_FOLLOW, unit)
    for _, point in ipairs({ 0, 1, 5 }) do
        ParticleManager:SetParticleControlEnt(index, point, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    end
    return index
end

-- A ring of light at a unit's feet with rays rising from it.
local function Rays(unit)
    local index = ParticleManager:CreateParticle(P.angel_rays, PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(index, 5, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    return index
end

--------------------------------------------------------------------------------- big moments

-- Death refused: light, wings and a hymn.
function ArenaFx.Guardian(unit)
    On(P.angel, unit)
    local blessing = { ArenaFx.Wings(unit), Rays(unit) }
    Timers:CreateTimer(3, function()
        ArenaFx.Stop(blessing)
    end)
    At(P.sunstrike, unit:GetAbsOrigin(), 250)
    unit:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
    Shake(unit:GetAbsOrigin(), 6)
end

function ArenaFx.Heal(caster, allies)
    At(P.purify, caster:GetAbsOrigin(), 260)
    caster:EmitSound("Hero_Chen.HandOfGodHealHero")
    for _, ally in ipairs(allies) do
        On(P.blessing, ally)
    end
end

function ArenaFx.Nova(caster, radius)
    local origin = caster:GetAbsOrigin()
    At(P.inferno, origin, radius)
    At(P.fireburst, origin, radius)
    caster:EmitSound("Hero_Warlock.RainOfChaos")
    Shake(origin, 10)
end

-- The staffs' Sunlance: a beam from the caster and a sun strike where it lands.
function ArenaFx.Sunlance(caster, target, damage)
    Beam(P.laguna, caster, "attach_attack1", target)
    At(P.sunstrike, target:GetAbsOrigin(), 100 + math.min(200, damage / 4))
    caster:EmitSound("Ability.LagunaBlade")
    target:EmitSound("Hero_Invoker.SunStrike.Ignite")
end

-- The war hammer's Final verdict: a bolt from the sky and a hammer blow where it lands.
function ArenaFx.Verdict(target)
    local origin = target:GetAbsOrigin()
    local index = ParticleManager:CreateParticle(P.bolt, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(index, 0, Vector(origin.x, origin.y, origin.z + 2000))
    ParticleManager:SetParticleControl(index, 1, origin)
    Release(index)
    At(P.hammer, origin, 300)
    target:EmitSound("Hero_Zuus.LightningBolt")
    Shake(origin, 12)
end

-- Persistent effects: the caller keeps the index and hands it back to Stop.

function ArenaFx.Shell(unit)
    local index = ParticleManager:CreateParticle(P.shell, PATTACH_ABSORIGIN_FOLLOW, unit)
    local size = Vector(110, 0, 110)
    ParticleManager:SetParticleControl(index, 1, size)
    ParticleManager:SetParticleControl(index, 2, size)
    ParticleManager:SetParticleControl(index, 4, size)
    ParticleManager:SetParticleControl(index, 5, Vector(110, 0, 0))
    ParticleManager:SetParticleControlEnt(index, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
    unit:EmitSound("Hero_Abaddon.AphoticShield.Cast")
    return index
end

function ArenaFx.ShellBreak(unit)
    On(P.shell_break, unit)
    unit:EmitSound("Hero_Abaddon.AphoticShield.Destroy")
end

-- Burning ground that follows a unit out to `radius`, with a ring of flame around the unit
-- itself. Returns both effects as one handle.
function ArenaFx.Scorched(unit, radius)
    local ground = ParticleManager:CreateParticle(P.scorched, PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControl(ground, 1, Vector(radius, 0, 0))
    local ring = ParticleManager:CreateParticle(P.fire_ring, PATTACH_ABSORIGIN_FOLLOW, unit)
    ParticleManager:SetParticleControlEnt(ring, 0, unit, PATTACH_ABSORIGIN_FOLLOW, nil, unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(ring, 1, unit, PATTACH_ABSORIGIN_FOLLOW, nil, unit:GetAbsOrigin(), true)
    ParticleManager:SetParticleControl(ring, 2, Vector(radius, 0, 0))
    return { ground, ring }
end

-- The red swirl of a hero in a blood rage.
function ArenaFx.Rage(unit)
    return ParticleManager:CreateParticle(P.rage_swirl, PATTACH_ABSORIGIN_FOLLOW, unit)
end

-- Ends a lasting effect. Takes one handle or a list of them.
function ArenaFx.Stop(handle)
    if type(handle) == "table" then
        for _, index in ipairs(handle) do
            ArenaFx.Stop(index)
        end
    elseif handle then
        ParticleManager:DestroyParticle(handle, false)
        Release(handle)
    end
end

--------------------------------------------------------------------------------- consumables

function ArenaFx.Tome(caster)
    On(P.levelup, caster)
    caster:EmitSound("Item.TomeOfKnowledge")
end

function ArenaFx.Potion(caster, mana)
    On(mana and P.clarity or P.flask, caster)
    caster:EmitSound(mana and "DOTA_Item.ClarityPotion.Activate" or "DOTA_Item.HealingSalve.Activate")
end

return ArenaFx
