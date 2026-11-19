package.path = "game/angel_arena/scripts/vscripts/?.lua;" .. package.path

class = function(object) return object end
IsServer = function() return true end
IsValidEntity = function(entity) return entity and not entity.removed end
UTIL_Remove = function(entity) entity.removed = true end

SKIP_TEAM_SETUP = false
INITIAL_CREEP_DELAY = 5
CREEP_SPAWN_INTERVAL = 5
CAMP_LOOT_DESPAWN_TIME = 60
DOTA_TEAM_GOODGUYS = 2
DOTA_TEAM_BADGUYS = 3
DOTA_TEAM_NEUTRALS = 4
DOTA_GAMERULES_STATE_GAME_IN_PROGRESS = 7
DOTA_GAMERULES_STATE_POST_GAME = 8

local time = INITIAL_CREEP_DELAY
local state = DOTA_GAMERULES_STATE_GAME_IN_PROGRESS
GameRules = {
    State_Get = function() return state end,
    GetDOTATime = function(_, includePreGame, includeNegativeTime)
        assert(not includePreGame and not includeNegativeTime)
        return time
    end,
}

local nextFloat = 0
RandomInt = function(minimum) return minimum end
RandomFloat = function(minimum, maximum)
    return minimum + nextFloat * (maximum - minimum)
end
RandomVector = function(distance) return distance end

local function CampMarker(id, difficulty, capacity)
    return {
        GetEntityIndex = function() return id end,
        GetAbsOrigin = function() return id end,
        GetIntAttr = function(_, name)
            if name == "CreepType" then return difficulty end
            return capacity
        end,
    }
end

local markers = { CampMarker(10, 0, 1), CampMarker(20, 1, 0), CampMarker(30, 2, 1) }
Entities = {
    FindAllByName = function(_, name)
        assert(name == "creep_camp")
        return markers
    end,
}

local spawned = {}
CreateUnitByName = function(name, location, _, _, _, team)
    assert(name == "npc_dota_neutral_harpy_storm" and location == 30 and team == DOTA_TEAM_NEUTRALS)
    local unit = {
        health = 1,
        maxHealth = 100,
        mana = 20,
        maxMana = 80,
        alive = true,
        team = team,
        writes = 0,
        IsAlive = function(self) return self.alive end,
        GetAbsOrigin = function() return 30 end,
        GetTeamNumber = function(self) return self.team end,
        GetHealth = function(self) return self.health end,
        GetMaxHealth = function(self) return self.maxHealth end,
        GetMana = function(self) return self.mana end,
        GetMaxMana = function(self) return self.maxMana end,
        SetHealth = function(self, health) self.health = health end,
        SetBaseMaxHealth = function(self, health) self.baseMaxHealth = health end,
        SetMaxHealth = function(self, health)
            self.maxHealth = health
            self.writes = self.writes + 1
        end,
        SetMaxMana = function(self, mana) self.maxMana = mana end,
        SetMana = function(self, mana) self.mana = mana end,
        SetBaseDamageMin = function(self, damage) self.damage = damage end,
        SetBaseDamageMax = function() end,
        SetPhysicalArmorBaseValue = function() end,
        SetMinimumGoldBounty = function(self, gold) self.gold = gold end,
        SetMaximumGoldBounty = function() end,
        SetDeathXP = function(self, xp) self.xp = xp end,
        AddNewModifier = function(self, _, _, modifier, values)
            assert(modifier == "modifier_creep_loot" and values.campID == 30 and values.difficulty == 2)
            self.loot = setmetatable({
                GetParent = function() return self end,
                Destroy = function(loot) loot.destroyed = true end,
            }, { __index = modifier_creep_loot })
            self.loot:OnCreated(values)
        end,
    }
    spawned[#spawned + 1] = unit
    return unit
end

local timers = {}
Timers = {
    CreateTimer = function(_, delay, callback)
        timers[#timers + 1] = { delay = delay, callback = callback }
    end,
}

require("mechanics/camps/index")
require("modifier/modifier_creep_loot")
CreepCamps:Init()
assert(#timers == 1 and timers[1].delay == INITIAL_CREEP_DELAY)

local tick = timers[1].callback
assert(tick() == CREEP_SPAWN_INTERVAL and #spawned == 1)
local creep = spawned[1]
assert(creep.health == 560 and creep.mana == 320 and creep.gold == 50 and creep.xp == 71)

time = 55
assert(tick() == CREEP_SPAWN_INTERVAL and #spawned == 1 and creep.writes == 1)
creep.health = creep.maxHealth - 100
creep.mana = creep.maxMana - 60
time = 60
assert(tick() == CREEP_SPAWN_INTERVAL and #spawned == 1)
assert(creep.maxHealth == 588 and creep.health == 488 and creep.mana == 267)
assert(creep.xp == 84 and creep.gold == 54)
assert(tick() == CREEP_SPAWN_INTERVAL and creep.writes == 2)

time = 3600
assert(tick() == CREEP_SPAWN_INTERVAL and creep.maxHealth == 1400 and creep.xp == 455)
time = 7200
assert(tick() == CREEP_SPAWN_INTERVAL and creep.writes == 3)
creep.team = DOTA_TEAM_GOODGUYS
creep.loot:OnDominated({ unit = creep })
assert(creep.loot.destroyed)
assert(tick() == CREEP_SPAWN_INTERVAL and #spawned == 2 and spawned[2].health == 1400)

time = 0
nextFloat = 1
assert(CreepItemDrop:RandomDropItemName(30, 2) == nil)
assert(CreepCamps.CampPRDCounters[30] == 2)
nextFloat = 0
assert(CreepItemDrop:RandomDropItemName(31, 1) == "item_flask")
assert(CreepItemDrop:RandomDropItemName(30, 2) == "item_boots_of_elves")
assert(CreepItemDrop:RandomDropItemName(32, 3) == "item_javelin")
assert(CreepCamps.CampPRDCounters[30] == 1)
time = 600
assert(CreepItemDrop:RandomDropItemName(32, 3) == "item_tome_str_6")
assert(CreepItemDrop:RandomDropItemName(33, 99) == nil)

local items = {}
CreateItem = function(name)
    if name == "missing_item" then return end
    local item = {
        name = name,
        SetPurchaseTime = function(_, purchaseTime) assert(purchaseTime == 0) end,
        GetContainer = function(self) return self.container end,
        LaunchLootInitialHeight = function(self) self.launched = true end,
    }
    items[#items + 1] = item
    return item
end
CreateItemOnPositionSync = function(_, item)
    item.container = {}
    return item.container
end

local victim = spawned[2]
victim.loot:OnDeath({ unit = victim })
victim.loot:OnDeath({ unit = victim, attacker = victim })
assert(#items == 0)
victim.loot:OnDeath({ unit = victim, attacker = creep })
victim.loot:OnDeath({ unit = victim, attacker = creep })
assert(#items == 1 and items[1].name == "item_scroll_of_the_beast" and items[1].launched)
assert(timers[2].delay == CAMP_LOOT_DESPAWN_TIME)
timers[2].callback()
assert(items[1].removed and items[1].container.removed)

CreepItemDrop:CreateDrop("item_flask", 0)
local pickedUp = items[2]
local originalContainer = pickedUp.container
pickedUp.container = {}
timers[3].callback()
assert(not pickedUp.removed and not pickedUp.container.removed and not originalContainer.removed)
CreepItemDrop:CreateDrop("missing_item", 0)
assert(#items == 2)

state = DOTA_GAMERULES_STATE_POST_GAME
assert(tick() == nil)
print("Camp growth, population, loot tiers, and drop expiration checks passed")
