local RAID_CAMP_RADIUS = 1000
local RAID_SPAWN_RADIUS = 200
local INITIAL_CHECK_INTERVAL = 3

local function IsCampOccupied(origin)
    for _, unit in pairs(Entities:FindAllByClassnameWithin("npc_dota_creature", origin, RAID_CAMP_RADIUS)) do
        if IsValidEntity(unit) and unit:IsAlive() and (unit:IsNeutralUnitType() or unit:IsCreature()) then
            return true
        end
    end
    return false
end

return function(spawner, config)
    if not IsValidEntity(spawner) then
        return
    end

    local match_started = false

    spawner:SetContextThink(config.name, function()
        if not IsValidEntity(spawner) then
            return
        end

        local state = GameRules:State_Get()
        if state >= DOTA_GAMERULES_STATE_POST_GAME then
            return
        end
        if state ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
            return INITIAL_CHECK_INTERVAL
        end
        if not match_started then
            match_started = true
            return config.interval
        end

        local origin = spawner:GetAbsOrigin()
        if not config.enabled() or IsCampOccupied(origin) then
            return config.interval
        end

        local waypoint = Entities:FindByName(nil, "camp_path_wp1")
        if not IsValidEntity(waypoint) then
            return config.interval
        end

        local min_units, max_units = config.unit_count()
        local spawned = false
        for i = 1, RandomInt(min_units, max_units) do
            local unit = CreateUnitByName(config.unit, origin + RandomVector(RandomFloat(0, RAID_SPAWN_RADIUS)),
                true, nil, nil, DOTA_TEAM_NEUTRALS)
            if IsValidEntity(unit) then
                unit:SetRenderColor(75, 0, 30)
                unit:SetInitialGoalEntity(waypoint)
                spawned = true
            end
        end

        if spawned then
            if config.sound then
                EmitGlobalSound(config.sound)
            end
            Notifications:TopToAll({ text = config.message, duration = 5 })
        end

        return config.interval
    end, INITIAL_CHECK_INTERVAL)
end
