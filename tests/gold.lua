local balance, reliable, updates = 500, 0, 0
local published = {}
local player, hero, item = {}, { GetPlayerOwnerID = function() return 0 end }, {}

class = function(fields) return fields end
UnitVarToPlayerID = function(unit) return unit end
DOTA_ModifyGold_Unspecified = 0
DOTA_GAMERULES_STATE_GAME_IN_PROGRESS = 6
GameRules = { State_Get = function() return DOTA_GAMERULES_STATE_GAME_IN_PROGRESS end }
PlayerTables = {
    GetTableValue = function() return published end,
    SetTableValue = function(_, _, _, values) published = values end,
}
PlayerResource = {
    IsValidPlayerID = function(_, id) return id == 0 end,
    GetGold = function() return balance end,
    GetAllTeamPlayerIDs = function() return { 0 } end,
    GetPlayer = function() return player end,
    ModifyGold = function(_, id, amount, isReliable)
        assert(id == 0)
        balance = balance + amount
        if isReliable then reliable = reliable + amount end
        updates = updates + 1
    end,
}

dofile("game/angel_arena/scripts/vscripts/mechanics/gold/gold.lua")
Gold:Think()
assert(published[0] == 500 and updates == 0)
balance = balance - 150 -- Native purchase between HUD updates.
Gold:ModifyGold(0, 100, true)
assert(balance == 450 and published[0] == 450 and reliable == 100)
balance = balance + 30 -- Native bounty before a scripted deduction.
Gold:RemoveGold(0, 20)
assert(balance == 460 and published[0] == 460 and reliable == 100)

Gold:SetGold(0, 92000)
assert(balance == 90000 and Gold:GetGold(0) == 92000)
balance = balance - 500
Gold:AddGold(0, 100)
assert(balance == 90000 and Gold:GetGold(0) == 91600 and published[0] == 91600)
balance = balance - 1700
Gold:Think()
assert(balance == 89900 and Gold:GetGold(0) == 89900 and published[0] == 89900)
Gold:ClearGold(0)
assert(balance == 0 and published[0] == 0)

local lookups = 0
EntIndexToHScript = function(index)
    lookups = lookups + 1
    return ({item, hero})[index]
end
IsValidEntity = function(entity) return entity ~= nil end
RandomInt = function(low) return low end
UTIL_Remove = function(entity) assert(entity == item) end
SendOverheadEventMessage = function(recipient, _, target, amount)
    assert(recipient == player and target == hero and amount == 150)
end
dofile("game/angel_arena/scripts/vscripts/mechanics/onitempickthinker.lua")
goldpickup({itemname = "item_clarity"})
assert(lookups == 0)
goldpickup({itemname = "item_bag_of_gold", ItemEntityIndex = 0, HeroEntityIndex = 2})
local pickup = {itemname = "item_bag_of_gold", ItemEntityIndex = 1, HeroEntityIndex = 2}
goldpickup(pickup)
goldpickup(pickup)
assert(balance == 150 and reliable == 250)
print("Gold timing, overflow, and single bag pickup checks passed")
