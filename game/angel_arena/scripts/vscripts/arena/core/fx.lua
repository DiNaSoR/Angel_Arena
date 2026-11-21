-- Shared visuals for the arena monsters and bosses: danger telegraphs, champion marks and the
-- effects every biome uses. Biome-specific effects live in arena/biomes/<biome>/fx.lua.
--
-- This file is loaded on the client as well as the server (modifier scripts require it), so it
-- must not touch anything that only exists on the server (Timers, Gold, GameMode, ...).

if ArenaFxCore then
    return ArenaFxCore
end

ArenaFxCore = {}

ArenaFxCore.PARTICLES = {
    -- A shrinking ring on the ground that closes when the hit lands. Control points:
    -- 0 = centre, 1 = (radius, 0, -radius), 2 = (seconds until impact, 0, 0).
    circle = "particles/units/heroes/hero_snapfire/hero_snapfire_ultimate_calldown.vpcf",
    -- A line on the ground from control point 0 to control point 1 (Bador's hook warning).
    line = "particles/ui_mouseactions/range_finder_line.vpcf",
    -- Marks.
    champion = "particles/neutral_fx/neutral_gold_upgrade.vpcf",
    returning = "particles/generic_gameplay/rune_haste_owner.vpcf",
    enraged = "particles/items2_fx/mask_of_madness.vpcf",
    lifesteal = "particles/generic_gameplay/generic_lifesteal.vpcf",
    boss_arrival = "particles/items_fx/aegis_respawn.vpcf",
}

ArenaFxCore.STATUS = {
    mighty = "particles/status_fx/status_effect_bloodrage.vpcf",
    stoneskin = "particles/status_fx/status_effect_avatar.vpcf",
}

ArenaFxCore.SOUNDS = {
    champion_spawn = "DOTA_Item.Hand_Of_Midas",
    phase = "Roshan.RevengeRoar",
}

ArenaFxCore.SOUND_FILES = {
    "soundevents/game_sounds_creeps.vsndevts",
    "soundevents/game_sounds_items.vsndevts",
}

function ArenaFxCore.Precache(context)
    for _, particle in pairs(ArenaFxCore.PARTICLES) do
        PrecacheResource("particle", particle, context)
    end
    for _, particle in pairs(ArenaFxCore.STATUS) do
        PrecacheResource("particle", particle, context)
    end
    for _, file in ipairs(ArenaFxCore.SOUND_FILES) do
        PrecacheResource("soundfile", file, context)
    end
end

-- A ring on the ground at `position` that closes over `delay` seconds. Returns the particle so
-- the caller can remove it early with ArenaFxCore.Stop (when the cast is interrupted).
function ArenaFxCore.Circle(position, radius, delay)
    local index = ParticleManager:CreateParticle(ArenaFxCore.PARTICLES.circle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(index, 0, position)
    ParticleManager:SetParticleControl(index, 1, Vector(radius, 0, -radius))
    ParticleManager:SetParticleControl(index, 2, Vector(delay, 0, 0))
    return index
end

local function Segment(from, to)
    local index = ParticleManager:CreateParticle(ArenaFxCore.PARTICLES.line, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(index, 0, from)
    ParticleManager:SetParticleControl(index, 1, to)
    return index
end

-- A warning line on the ground between two points. With a `width`, two more lines mark the edges
-- of the strip that will be hit (the line particle itself has no width). Returns what Stop takes.
function ArenaFxCore.Line(from, to, width)
    local center = Segment(from, to)
    local dx, dy = to.x - from.x, to.y - from.y
    local length = math.sqrt(dx * dx + dy * dy)
    if not width or width <= 0 or length < 1 then
        return center
    end
    local side = Vector(-dy / length * width / 2, dx / length * width / 2, 0)
    return { center, Segment(from + side, to + side), Segment(from - side, to - side) }
end

-- A one-shot effect at a point. `radius`, when given, goes to control point 1, where most of
-- Dota's area effects read their size.
function ArenaFxCore.Burst(particle, position, radius)
    local index = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(index, 0, position)
    if radius then
        ParticleManager:SetParticleControl(index, 1, Vector(radius, radius, radius))
    end
    ParticleManager:ReleaseParticleIndex(index)
end

-- A one-shot effect that follows a unit.
function ArenaFxCore.On(particle, unit)
    ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, unit))
end

-- Ends a lasting effect started by Circle or Line. Takes nil, one index or a list of them.
function ArenaFxCore.Stop(handle)
    if type(handle) == "table" then
        for _, index in ipairs(handle) do
            ArenaFxCore.Stop(index)
        end
    elseif handle then
        ParticleManager:DestroyParticle(handle, false)
        ParticleManager:ReleaseParticleIndex(handle)
    end
end

return ArenaFxCore
