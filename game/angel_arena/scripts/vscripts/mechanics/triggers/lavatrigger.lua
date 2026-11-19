local LAVA_DAMAGE_TICK_RATE = 1
local LAVA_DAMAGE_AMOUNT = 200

function OnLavaTick(trigger)
    local unit = trigger and trigger.activator
    if not IsValidEntity(unit) or not unit:IsBaseNPC() or not unit:IsAlive() then
        return LAVA_DAMAGE_TICK_RATE
    end

    local health = unit:GetHealth()
    if health > LAVA_DAMAGE_AMOUNT then
        unit:SetHealth(health - LAVA_DAMAGE_AMOUNT)
    else
        unit:ForceKill(true)
    end

    return LAVA_DAMAGE_TICK_RATE
end
