-- Superseded: the match now starts arena/index.lua (ArenaWorld) instead of CreepCamps, and the
-- creep_camp markers are used through arena/core/markers.lua. Kept for tests/camps.lua and for
-- item_drop.lua (CreepItemDrop), which the arena camps still use to drop loot.
CreepCamps = CreepCamps or class({})

-- Fields in each creep definition.
local NAME = 1
local HEALTH = 2
local MANA = 3
local DAMAGE = 4
local ARMOR = 5
local GOLD = 6
local EXPERIENCE = 7

function CreepCamps:Init()
    self.camps = {}
    self.CampPRDCounters = {}
    local delay = SKIP_TEAM_SETUP and 0 or INITIAL_CREEP_DELAY
    Timers:CreateTimer(delay, function()
        return self:CreepSpawnTimer()
    end)
end

function CreepCamps:CreepSpawnTimer()
    if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then return end

    local minute = CreepPower:GetElapsedMinute()
    local power = CreepPower:GetPowerForMinute(minute)
    for _, marker in ipairs(Entities:FindAllByName("creep_camp")) do
        self:DoSpawn(marker, power)
    end
    return CREEP_SPAWN_INTERVAL
end

function CreepCamps:DoSpawn(marker, power)
    local difficulty = marker:GetIntAttr("CreepType")
    local capacity = marker:GetIntAttr("CreepMax")
    local groups = CreepTypes[difficulty]
    if not groups or #groups == 0 or not capacity or capacity < 1 then return end

    local campID = marker:GetEntityIndex()
    local camp = self.camps[campID]
    if not camp then
        camp = { creeps = {} }
        self.camps[campID] = camp
    end

    local count = 0
    for unit, definition in pairs(camp.creeps) do
        if IsValidEntity(unit) and unit:IsAlive() and unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
            count = count + 1
            if camp.growth ~= power[1] then
                self:SetCreepPropertiesOnHandle(unit, definition, power, false)
            end
        else
            camp.creeps[unit] = nil
        end
    end
    camp.growth = power[1]

    local openSlots = capacity - count
    if openSlots <= 0 then return end

    local location = marker:GetAbsOrigin()
    local group = groups[RandomInt(1, #groups)]
    for _, definition in ipairs(group) do
        local unit = CreateUnitByName(definition[NAME], location, true, nil, nil, DOTA_TEAM_NEUTRALS)
        if unit then
            camp.creeps[unit] = definition
            self:SetCreepPropertiesOnHandle(unit, definition, power, true)
            unit:AddNewModifier(nil, nil, "modifier_creep_loot", { campID = campID, difficulty = difficulty })
            openSlots = openSlots - 1
            if openSlots == 0 then break end
        end
    end
end

function CreepCamps:SetCreepPropertiesOnHandle(unit, definition, power, isNew)
    local healthMissing = isNew and 0 or math.max(0, unit:GetMaxHealth() - unit:GetHealth())
    local manaMissing = isNew and 0 or math.max(0, unit:GetMaxMana() - unit:GetMana())
    local maxHealth = math.ceil(definition[HEALTH] * power[HEALTH])
    local maxMana = math.ceil(definition[MANA] * power[MANA])

    unit:SetBaseMaxHealth(maxHealth)
    unit:SetMaxHealth(maxHealth)
    unit:SetHealth(math.max(1, maxHealth - healthMissing))
    unit:SetMaxMana(maxMana)
    unit:SetMana(math.max(0, maxMana - manaMissing))

    local damage = math.ceil(definition[DAMAGE] * power[DAMAGE])
    local gold = math.ceil(definition[GOLD] * power[GOLD])
    unit:SetBaseDamageMin(damage)
    unit:SetBaseDamageMax(damage)
    unit:SetPhysicalArmorBaseValue(definition[ARMOR] * power[ARMOR])
    unit:SetMinimumGoldBounty(gold)
    unit:SetMaximumGoldBounty(gold)
    unit:SetDeathXP(math.ceil(definition[EXPERIENCE] * power[EXPERIENCE]))
end
