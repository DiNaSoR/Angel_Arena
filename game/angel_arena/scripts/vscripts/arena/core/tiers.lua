-- What separates an easy camp from an elite one, and how every camp grows over the match.
-- Pure data and arithmetic: no engine calls, so tests and tools can read it directly.
--
-- A biome decides which monsters stand in a camp of each tier (arena/biomes/<biome>/monsters.lua);
-- everything here applies to every biome alike.

if ArenaTiers then
    return ArenaTiers
end

ArenaTiers = {}

ArenaTiers.NAMES = { "easy", "medium", "hard", "elite" }

ArenaTiers.PROFILES = {
    [1] = {
        respawn = 40,           -- seconds after the camp is cleared
        leash = 750,            -- how far a monster follows a target from its post
        aggro = 0,              -- monsters attack heroes this close on sight (0: only when hit)
        ability_level = 1,      -- level of the monsters' abilities at minute 0
        champion_chance = 0.04, -- chance that one monster in a new camp is a champion
        drop_chance = 0.05,     -- chance a kill drops an item (rises after each miss, see rewards)
        extra_unit_minute = 10, -- from this minute camps get one more copy of the last monster
    },
    [2] = {
        respawn = 55, leash = 850, aggro = 250, ability_level = 1,
        champion_chance = 0.06, drop_chance = 0.08, extra_unit_minute = 15,
    },
    [3] = {
        respawn = 75, leash = 950, aggro = 350, ability_level = 2,
        champion_chance = 0.08, drop_chance = 0.12, extra_unit_minute = 20,
    },
    [4] = {
        respawn = 110, leash = 1050, aggro = 450, ability_level = 3,
        champion_chance = 0.12, drop_chance = 0.25, extra_unit_minute = 25,
    },
}

-- Growth over the match. Every camp monster's base stats (from its biome file) are multiplied by
-- 1 + rate * minute, up to MAX_GROWTH_MINUTE. These are the rates the original camps used.
ArenaTiers.MAX_GROWTH_MINUTE = 30
ArenaTiers.GROWTH = { health = 0.05, damage = 0.04, armor = 0.02, gold = 0.08, xp = 0.18 }
ArenaTiers.ABILITY_LEVEL_EVERY = 20   -- abilities gain a level every this many minutes...
ArenaTiers.MAX_ABILITY_LEVEL = 4      -- ...up to this level (monster abilities have four levels)
ArenaTiers.CHAMPION_CHANCE_PER_MINUTE = 0.002
ArenaTiers.MAX_CHAMPION_BONUS = 0.06

-- What a champion is worth compared with an ordinary monster of its kind.
ArenaTiers.CHAMPION = { health = 2.5, damage = 1.3, gold = 3, xp = 2 }

function ArenaTiers.Profile(tier)
    return ArenaTiers.PROFILES[tier]
end

-- The growth step for an elapsed match minute.
function ArenaTiers.Level(minute)
    return math.min(math.max(0, math.floor(minute or 0)), ArenaTiers.MAX_GROWTH_MINUTE)
end

function ArenaTiers.Multipliers(level)
    local result = {}
    for stat, rate in pairs(ArenaTiers.GROWTH) do
        result[stat] = 1 + rate * level
    end
    return result
end

-- Final stats of one monster: base stats x growth x champion bonus. Health, damage, gold and
-- experience are whole numbers; armor keeps its fraction.
function ArenaTiers.Stats(base, level, champion)
    local growth = ArenaTiers.Multipliers(level)
    local bonus = champion and ArenaTiers.CHAMPION or {}
    return {
        health = math.ceil(base.health * growth.health * (bonus.health or 1)),
        damage = math.ceil(base.damage * growth.damage * (bonus.damage or 1)),
        armor = base.armor * growth.armor,
        gold = math.ceil(base.gold * growth.gold * (bonus.gold or 1)),
        xp = math.ceil(base.xp * growth.xp * (bonus.xp or 1)),
    }
end

function ArenaTiers.AbilityLevel(tier, minute)
    local profile = ArenaTiers.PROFILES[tier]
    local bonus = math.floor(math.max(0, minute or 0) / ArenaTiers.ABILITY_LEVEL_EVERY)
    return math.min(ArenaTiers.MAX_ABILITY_LEVEL, profile.ability_level + bonus)
end

function ArenaTiers.ChampionChance(tier, minute)
    local bonus = math.min(ArenaTiers.MAX_CHAMPION_BONUS, math.max(0, minute or 0) * ArenaTiers.CHAMPION_CHANCE_PER_MINUTE)
    return ArenaTiers.PROFILES[tier].champion_chance + bonus
end

-- The monsters for one spawn of a group: the group itself, plus a copy of its last monster once
-- the tier's extra-unit minute has passed.
function ArenaTiers.Composition(group, tier, minute)
    local result = {}
    for index, name in ipairs(group) do
        result[index] = name
    end
    if (minute or 0) >= ArenaTiers.PROFILES[tier].extra_unit_minute then
        result[#result + 1] = group[#group]
    end
    return result
end

return ArenaTiers
