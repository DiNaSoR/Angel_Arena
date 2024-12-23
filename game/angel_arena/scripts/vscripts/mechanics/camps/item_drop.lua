
-- Taken from bb template
if CreepItemDrop == nil then
    --DebugPrint ( '[creeps/item_drop] creating new CreepItemDrop object' )
    CreepItemDrop = class({})
end

--item power level defines what items drop at given time
local ItemPowerLevel = 1.0

--define how often items drop from creeps. min = 0 (0%), max = 1 (100%)
--local DROP_CHANCE = 0.25

-- The C initial chance parameter for the pseudo-random distribution function
-- Set for average chance of 25%. Functions for calculation and a bunch of pre-calculated values can be found here:
-- https://gaming.stackexchange.com/questions/161430/calculating-the-constant-c-in-dota-2-pseudo-random-distribution
PRD_C = 0.084744091852316990275274806

--creep properties enumerations
local NAME_ENUM = 1
local FROM_ENUM = 2
local TO_ENUM = 3
local RARITY_ENUM = 4

--defines items drop levels.
--item will start dropping, between FROM and TO itemPowerLevel.
-- RARITY is used to define how likely the item is to drop in comparison with other items.
-- the higher the value, the less likely the item is to drop
--for negative values:
--  *FROM -> any level smaller or equal than TO will have a chance to drop the item.
--  *TO   -> any level larger or equal than FROM will have  a chance to drop the item.
--  *FROM and TO -> item will drop at any level.
--  *RARITY -> item will not drop.
--it is possible to define the same item twice, for maximum flexibility
ItemPowerTable = {
  --NAME                             FROM       TO        RARITY
  {"item_potion_of_super_mana",      1,       -1,      1},
  {"item_scroll_of_the_beast",       1,         -1,      1},
  {"item_tome_int_3",                1,       -1,      1},
  {"item_boots_of_elves",            1,       -1,      1},
  {"item_javelin",            1,       -1,      1},
  {"item_mithril_hammer",            1,       -1,      1},
  {"item_quarterstaff",            1,       -1,      1},
  {"item_blades_of_attack",            1,       -1,      1},
  {"item_ring_of_protection",            1,       -1,      1},
  {"item_smoke_of_deceit",            1,       -1,      1},
  {"item_staff_of_wizardry",            1,       -1,      1},
  {"item_blade_of_alacrity",            1,       -1,      1},
  {"item_ogre_axe",            1,       -1,      1},
	{"item_slippers",            1,       -1,      1},
  {"item_mantle",            1,       -1,      1},
  {"item_circlet",            1,       -1,      1},
  {"item_quelling_blade",            1,       -1,      1},
  {"item_stout_shield",            1,       -1,      1},
  {"item_boots_of_elves",            1,       -1,      1},
}

function CreepItemDrop:Init ()
  --DebugPrint ( '[creeps/item_drop] Initialize' )
  CreepItemDrop = self

  --ListenToGameEvent("entity_killed", CreepItemDrop.OnEntityKilled, self)
  Timers:CreateTimer(Dynamic_Wrap(self, 'ItemDropUpgradeTimer'), self)
end

function CreepItemDrop:SetPowerLevel (powerLevel)
  ItemPowerLevel = powerLevel
end

function CreepItemDrop:ItemDropUpgradeTimer ()
  -- upgrade creeps power level every time it triggers
  self:SetPowerLevel(ItemPowerLevel + 1)

  return 10.0
end

function CreepItemDrop:CreateDrop (itemName, pos)
  local newItem = CreateItem(itemName, nil, nil)

  newItem:SetPurchaseTime(0)
  newItem.firstPickedUp = false

  CreateItemOnPositionSync(pos, newItem)
  newItem:LaunchLootInitialHeight(false, 0, 300, 0.75, pos + RandomVector(RandomFloat(50, 150)))
  
  Timers:CreateTimer(BOTTLE_DESPAWN_TIME, function ()
    -- check if safe to destroy
    if IsValidEntity(newItem) then
      if newItem:GetContainer() ~= nil then
        newItem:GetContainer():RemoveSelf()
      end
    end
  end)
end

-- function CreepItemDrop:OnEntityKilled (event)
--   local killedEntity = EntIndexToHScript(event.entindex_killed)

--   if killedEntity ~= nil then
--     if killedEntity.Is_ItemDropEnabled then
--       local itemToDrop = CreepItemDrop:RandomDropItemName()
--       if itemToDrop ~= "" and itemToDrop ~= nil then
--         CreepItemDrop:CreateDrop(itemToDrop, killedEntity:GetAbsOrigin())
--       end
--     end
--   end
-- end

function CreepItemDrop:RandomDropItemName(campLocationString)
  local CampPRDCounters = CreepCamps.CampPRDCounters

  --first we need to check against the drop percentage.
  if RandomFloat(0, 1) > math.min(1, PRD_C * CampPRDCounters[campLocationString]) then
    -- Increment PRD counter if nothing was dropped
    CampPRDCounters[campLocationString] = CampPRDCounters[campLocationString] + 1
    return ""
  end

  --now iterate through item power table and see which items qualify for
  local totalChancePool = 0.0
  local filteredItemTable = {}

  for i=1, #ItemPowerTable do
    local from = ItemPowerTable[i][FROM_ENUM]
    local to = ItemPowerTable[i][TO_ENUM]
    local rarity = ItemPowerTable[i][RARITY_ENUM]

    if (from < 0 or (from >= 0 and ItemPowerLevel >= from)) and (to < 0 or (to >= 0 and ItemPowerLevel <= to)) and rarity > 0 then
      totalChancePool = totalChancePool + 1.0 / rarity
      filteredItemTable[#filteredItemTable + 1] = ItemPowerTable[i]
    end
  end

  local passedItemsCumulativeChance = 0.0
  local dropChance = RandomFloat(0, 1) * totalChancePool

  for i=1, #filteredItemTable do
    passedItemsCumulativeChance = passedItemsCumulativeChance + 1.0 / filteredItemTable[i][RARITY_ENUM]
    if passedItemsCumulativeChance >= dropChance then
      -- Reset PRD counter on successful drop roll
      CampPRDCounters[campLocationString] = 1
      return filteredItemTable[i][NAME_ENUM]
    end
  end

  --in case some configuration was done wrong, return empty, itherwise this point should not be reached normally.
  return ""
end
