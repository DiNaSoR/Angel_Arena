CreepPower = CreepPower or {}

local MAX_GROWTH_MINUTE = 30

function CreepPower:GetElapsedMinute()
    return math.floor(math.max(0, GameRules:GetDOTATime(false, false)) / 60)
end

function CreepPower:GetPowerForMinute(minute)
    local growth = math.min(math.max(0, minute), MAX_GROWTH_MINUTE)
    return {
        growth,
        1 + growth * 0.05, -- Health
        1 + growth * 0.02, -- Mana
        1 + growth * 0.04, -- Damage
        1 + growth * 0.02, -- Armor
        1 + growth * 0.08, -- Gold
        1 + growth * 0.18, -- Experience
    }
end
