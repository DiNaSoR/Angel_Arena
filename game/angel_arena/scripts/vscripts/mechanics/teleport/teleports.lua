local CAMERA_TIMER_FOLLOW = 0.2

function Healall()
    for _, hero in pairs(HeroList:GetAllHeroes()) do
        hero:SetMana(hero:GetMaxMana())
        hero:SetHealth(hero:GetMaxHealth())

        for i = 0, hero:GetAbilityCount() - 1 do
            local ability = hero:GetAbilityByIndex(i)
            if ability then
                ability:EndCooldown()
            end
        end
    end
end

local function Teleport(trigger, radiant_destination, dire_destination)
    local unit = trigger and trigger.activator
    if not IsValidEntity(unit) or not unit:IsBaseNPC() or not unit:IsAlive() then
        return
    end

    local team = unit:GetTeamNumber()
    local destination
    if team == DOTA_TEAM_GOODGUYS then
        destination = radiant_destination
    elseif team == DOTA_TEAM_BADGUYS then
        destination = dire_destination
    end
    if not destination then
        return
    end

    local marker = Entities:FindByName(nil, destination)
    if not IsValidEntity(marker) then
        return
    end

    FindClearSpaceForUnit(unit, marker:GetAbsOrigin(), false)
    unit:Stop()
    if unit:IsRealHero() then
        local player_id = unit:GetPlayerOwnerID()
        if PlayerResource:IsValidPlayerID(player_id) then
            PlayerResource:SetCameraTarget(player_id, unit)
            Timers:CreateTimer(CAMERA_TIMER_FOLLOW, function()
                PlayerResource:SetCameraTarget(player_id, nil)
            end)
        end
    end
end

function Basetonorthport(trigger)
    Teleport(trigger, "Northportbase", "Northportbase")
end

function Northporttobase(trigger)
    Teleport(trigger, "teleport_good_out", "teleport_good_in")
end

function Basetosouthport(trigger)
    Teleport(trigger, "Southportbase", "Southportbase")
end

function Southporttobase(trigger)
    Teleport(trigger, "teleport_good_out", "teleport_good_in")
end

function arenateleport(trigger)
    Teleport(trigger, "arenaoutside", "arenaoutside")
end

function telegoodout(trigger)
    Teleport(trigger, nil, "teleport_good_out")
end

function telegoodin(trigger)
    Teleport(trigger, "teleport_good_in")
end
