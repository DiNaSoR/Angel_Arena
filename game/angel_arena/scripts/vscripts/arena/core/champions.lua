-- Champions: now and then one monster in a fresh camp is a champion. It is bigger, wears a
-- golden ring, has a coloured label over its health bar naming its gift, hits harder, has far
-- more health, and always drops an item from the next tier's loot. The chance grows with the
-- camp's tier and the match clock (see ArenaTiers).
--
-- Each champion has one gift (affix). Keep the list short and each gift obvious in play.

require("arena/core/tiers")
require("arena/core/modifiers")

if ArenaChampions then
    return ArenaChampions
end

ArenaChampions = {}

ArenaChampions.AFFIXES = {
    { name = "mighty", modifier = "modifier_arena_champion_mighty", label = "Mighty Champion", color = { 255, 80, 60 } },
    { name = "swift", modifier = "modifier_arena_champion_swift", label = "Swift Champion", color = { 90, 200, 255 } },
    { name = "vampiric", modifier = "modifier_arena_champion_vampiric", label = "Vampiric Champion", color = { 200, 60, 200 } },
    { name = "stoneskin", modifier = "modifier_arena_champion_stoneskin", label = "Stoneskin Champion", color = { 255, 210, 80 } },
}

function ArenaChampions.Affix(name)
    for _, affix in ipairs(ArenaChampions.AFFIXES) do
        if affix.name == name then
            return affix
        end
    end
end

-- Decides whether a fresh camp gets a champion. Returns the slot (1..size) and the affix, or nil.
function ArenaChampions.Roll(tier, minute, size)
    if size < 1 or RandomFloat(0, 1) >= ArenaTiers.ChampionChance(tier, minute) then
        return nil
    end
    return RandomInt(1, size), ArenaChampions.AFFIXES[RandomInt(1, #ArenaChampions.AFFIXES)]
end

-- Marks a unit as a champion. Its stats were already raised when it spawned (ArenaTiers.Stats).
function ArenaChampions.Apply(unit, affix)
    unit:AddNewModifier(unit, nil, "modifier_arena_champion", {})
    unit:AddNewModifier(unit, nil, affix.modifier, {})
    unit:SetCustomHealthLabel(affix.label, affix.color[1], affix.color[2], affix.color[3])
    unit:EmitSound(ArenaFxCore.SOUNDS.champion_spawn)
end

return ArenaChampions
