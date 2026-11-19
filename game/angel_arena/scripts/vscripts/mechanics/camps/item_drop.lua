CreepItemDrop = CreepItemDrop or {}

-- Per-camp pseudo-random distribution for a 25% average drop chance.
local DROP_CHANCE_PER_ATTEMPT = 0.084744091852317
local BONUS_LOOT_MINUTE = 10

local lootByDifficulty = {
    {
        regular = {
            "item_flask", "item_clarity", "item_enchanted_mango",
            "item_ring_of_protection", "item_circlet", "item_quelling_blade",
        },
        bonus = { "item_potion_of_super_mana", "item_potion_of_super_healing", "item_scroll_of_speed" },
    },
    {
        regular = {
            "item_boots_of_elves", "item_blades_of_attack", "item_quarterstaff",
            "item_tome_str_3", "item_tome_agi_3", "item_tome_int_3",
        },
        bonus = { "item_scroll_of_the_beast", "item_staff_of_wizardry", "item_blade_of_alacrity", "item_ogre_axe" },
    },
    {
        regular = { "item_javelin", "item_mithril_hammer", "item_broadsword", "item_claymore" },
        bonus = { "item_tome_str_6", "item_tome_agi_6", "item_tome_int_6" },
    },
}

function CreepItemDrop:RandomDropItemName(campID, difficulty)
    local loot = lootByDifficulty[difficulty]
    local attempts = CreepCamps.CampPRDCounters
    if not campID or not loot or not attempts then return end

    local count = attempts[campID] or 1
    if RandomFloat(0, 1) > math.min(1, DROP_CHANCE_PER_ATTEMPT * count) then
        attempts[campID] = count + 1
        return
    end

    attempts[campID] = 1
    local pool = loot.regular
    if CreepPower:GetElapsedMinute() >= BONUS_LOOT_MINUTE and RandomInt(1, 3) == 1 then
        pool = loot.bonus
    end
    return pool[RandomInt(1, #pool)]
end

function CreepItemDrop:CreateDrop(itemName, position)
    local item = CreateItem(itemName, nil, nil)
    if not item then return end

    item:SetPurchaseTime(0)
    local container = CreateItemOnPositionSync(position, item)
    if not container then
        UTIL_Remove(item)
        return
    end
    item:LaunchLootInitialHeight(false, 0, 300, 0.75, position + RandomVector(RandomFloat(50, 150)))

    Timers:CreateTimer(CAMP_LOOT_DESPAWN_TIME, function()
        if IsValidEntity(item) and IsValidEntity(container) and item:GetContainer() == container then
            UTIL_Remove(container)
            if IsValidEntity(item) then UTIL_Remove(item) end
        end
    end)
end
