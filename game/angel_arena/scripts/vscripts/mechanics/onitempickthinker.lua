function goldpickup(keys)
    if keys.itemname ~= "item_bag_of_gold" or not keys.ItemEntityIndex or not keys.HeroEntityIndex then
        return
    end

    local item = EntIndexToHScript(keys.ItemEntityIndex)
    local hero = EntIndexToHScript(keys.HeroEntityIndex)
    if not IsValidEntity(item) or item.arenaGoldClaimed or not IsValidEntity(hero) or not hero.GetPlayerOwnerID then
        return
    end

    local playerID = hero:GetPlayerOwnerID()
    if not PlayerResource:IsValidPlayerID(playerID) then
        return
    end

    item.arenaGoldClaimed = true
    local amount = RandomInt(150, 300)
    local player = PlayerResource:GetPlayer(playerID)
    Gold:ModifyGold(playerID, amount, true)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, amount, player)
    UTIL_Remove(item)
end
