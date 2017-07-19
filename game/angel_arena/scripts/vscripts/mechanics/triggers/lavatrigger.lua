--------------------------------------------------------------
-- lavatrigger
-- By: DiNaSoR
--------------------------------------------------------------
local LAVA_DAMAGE_TICK_RATE = 1
local LAVA_DAMAGE_AMOUNT = 200


function OnLavaTick(trigger)

        local ent = trigger.activator
        local hp = ent:GetHealth()

        if not ent then
        return
        end

        if hp >= LAVA_DAMAGE_AMOUNT then
           ent:SetHealth(hp - LAVA_DAMAGE_AMOUNT)
        else
          ent:ForceKill(true)
        end

    return LAVA_DAMAGE_TICK_RATE
end