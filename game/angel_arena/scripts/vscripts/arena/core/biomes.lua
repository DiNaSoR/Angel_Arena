-- The list of biomes and the loader for their files.
--
-- Each biome lives in arena/biomes/<biome>/ and may provide:
--   monsters.lua   the camp pool: monster stats, the groups for each tier, extra loot
--   boss.lua       the biome boss: when it comes, its phases, abilities and rewards
--   fx.lua         every particle, sound and model the biome's scripts use (for precaching)
--   abilities.lua  the Lua abilities and modifiers named in the biome's KV files
-- A missing file just means the biome does not have that part yet. A file that fails to load
-- or does not pass Validate is reported in the console and that part of the biome is switched
-- off; the rest of the game keeps running. tests/arena_biomes.lua fails on the same problems.

require("arena/core/tiers")
require("arena/core/fx")

if ArenaBiomes then
    return ArenaBiomes
end

ArenaBiomes = {}

-- The one shared list of biomes. "wilds" is the unthemed pool for the middle of the map.
ArenaBiomes.NAMES = { "wilds", "green", "desert", "ice", "lava" }
ArenaBiomes.TIERS = 4
ArenaBiomes.MAX_GROUP_SIZE = 6
ArenaBiomes.AI_TARGETS = { enemy = true, point = true, self = true, ally = true }

ArenaBiomes.list = {}
local loaded = false
local warned = {}

local function Log(message)
    print("[Arena] " .. message)
end

-- Loads one biome file. Returns its table, or nil and a message when it is broken. An absent
-- file returns nil and no message. `fresh` forgets the cached copy first, so an edited file is
-- read again (ArenaBiomes.Load(true), for example after script_reload).
local function Load(path, fresh)
    if fresh then
        package.loaded[path] = nil
    end
    local ok, result = pcall(require, path)
    if not ok then
        local message = tostring(result)
        -- Only the file itself being absent is quiet; a missing file it requires is a problem.
        if message:find(path, 1, true) and message:find("not found", 1, true)
            and not message:find(path .. ".lua:", 1, true) then
            return nil
        end
        return nil, "does not load: " .. message
    end
    if type(result) ~= "table" then
        return nil, "must return a table"
    end
    return result
end

local function StartsWith(text, prefix)
    return type(text) == "string" and text:sub(1, #prefix) == prefix
end

local function IsNumber(value, minimum)
    return type(value) == "number" and value == value and value >= (minimum or -math.huge)
end

------------------------------------------------------------------------------- validation

local function ValidateHints(problems, biome, where, hints)
    if hints == nil then return end
    if type(hints) ~= "table" then
        problems[#problems + 1] = where .. ": ai must be a table"
        return
    end
    for ability, hint in pairs(hints) do
        if type(ability) ~= "string" or type(hint) ~= "table" then
            problems[#problems + 1] = where .. ": ai entries are ability_name = { ... }"
        else
            if biome ~= "wilds" and not StartsWith(ability, "arena_" .. biome .. "_") then
                problems[#problems + 1] = where .. ": ability " .. ability .. " must be named arena_" .. biome .. "_<name>"
            end
            if hint.target ~= nil and not ArenaBiomes.AI_TARGETS[hint.target] then
                problems[#problems + 1] = where .. ": ability " .. ability .. " has unknown ai target " .. tostring(hint.target)
            end
            for _, key in ipairs({ "radius", "range", "min_range", "health_below", "ally_health_below", "lock" }) do
                if hint[key] ~= nil and not IsNumber(hint[key], 0) then
                    problems[#problems + 1] = where .. ": ability " .. ability .. " ai." .. key .. " must be a number"
                end
            end
        end
    end
end

local function ValidateLoot(problems, where, loot)
    if loot == nil then return end
    if type(loot) ~= "table" then
        problems[#problems + 1] = where .. " must be a list of item names"
        return
    end
    for _, item in ipairs(loot) do
        if not StartsWith(item, "item_") then
            problems[#problems + 1] = where .. ": " .. tostring(item) .. " is not an item name"
        end
    end
end

function ArenaBiomes.ValidateMonsters(biome, data)
    local problems = {}
    if type(data) ~= "table" then
        return { "monsters.lua must return a table" }
    end
    if data.biome ~= biome then
        problems[#problems + 1] = "monsters.lua: biome must be \"" .. biome .. "\""
    end
    local monsters = data.monsters
    if type(monsters) ~= "table" then
        problems[#problems + 1] = "monsters.lua: monsters must be a table"
        monsters = {}
    end
    for name, stats in pairs(monsters) do
        local where = "monster " .. tostring(name)
        if type(name) ~= "string" or type(stats) ~= "table" then
            problems[#problems + 1] = "monsters.lua: entries are unit_name = { health = ..., ... }"
        else
            if biome ~= "wilds" and not StartsWith(name, "npc_arena_" .. biome .. "_") then
                problems[#problems + 1] = where .. " must be named npc_arena_" .. biome .. "_<name>"
            end
            if not IsNumber(stats.health, 1) then problems[#problems + 1] = where .. ": health must be a number above 0" end
            for _, key in ipairs({ "damage", "gold", "xp" }) do
                if not IsNumber(stats[key], 0) then problems[#problems + 1] = where .. ": " .. key .. " must be a number" end
            end
            if not IsNumber(stats.armor) then problems[#problems + 1] = where .. ": armor must be a number" end
            ValidateHints(problems, biome, where, stats.ai)
        end
    end
    local tiers = data.tiers
    if type(tiers) ~= "table" then
        problems[#problems + 1] = "monsters.lua: tiers must be a table with entries 1 to 4"
        tiers = {}
    end
    for key in pairs(tiers) do
        if type(key) ~= "number" or key < 1 or key > ArenaBiomes.TIERS or key % 1 ~= 0 then
            problems[#problems + 1] = "monsters.lua: tiers has an entry " .. tostring(key) .. "; tiers are 1 to 4"
        end
    end
    for tier = 1, ArenaBiomes.TIERS do
        local groups = tiers[tier] or {}
        if type(groups) ~= "table" then
            problems[#problems + 1] = "tier " .. tier .. " must be a list of groups"
            groups = {}
        end
        for index, group in ipairs(groups) do
            local where = "tier " .. tier .. " group " .. index
            if type(group) ~= "table" or #group == 0 then
                problems[#problems + 1] = where .. " must list at least one monster"
            elseif #group > ArenaBiomes.MAX_GROUP_SIZE then
                problems[#problems + 1] = where .. " has more than " .. ArenaBiomes.MAX_GROUP_SIZE .. " monsters"
            else
                for _, name in ipairs(group) do
                    if not monsters[name] then
                        problems[#problems + 1] = where .. ": " .. tostring(name) .. " is not in monsters"
                    end
                end
            end
        end
    end
    if data.loot ~= nil then
        if type(data.loot) ~= "table" then
            problems[#problems + 1] = "monsters.lua: loot must be a table of tier = { items }"
        else
            for tier, items in pairs(data.loot) do
                ValidateLoot(problems, "loot[" .. tostring(tier) .. "]", items)
            end
        end
    end
    return problems
end

function ArenaBiomes.ValidateBoss(biome, data)
    local problems = {}
    if type(data) ~= "table" then
        return { "boss.lua must return a table" }
    end
    local prefix = "npc_arena_" .. biome .. "_"
    if not StartsWith(data.unit, prefix) then
        problems[#problems + 1] = "boss.lua: unit must be named " .. prefix .. "<name>"
    end
    for _, key in ipairs({ "first_spawn", "respawn", "leash" }) do
        if not IsNumber(data[key], 1) then problems[#problems + 1] = "boss.lua: " .. key .. " must be a number above 0" end
    end
    if data.warning ~= nil and not IsNumber(data.warning, 0) then
        problems[#problems + 1] = "boss.lua: warning must be a number"
    end
    local stats = data.stats
    if type(stats) ~= "table" or not IsNumber(stats.health, 1) or not IsNumber(stats.damage, 0) or not IsNumber(stats.armor) then
        problems[#problems + 1] = "boss.lua: stats needs health, damage and armor"
    end
    if data.growth ~= nil and type(data.growth) ~= "table" then
        problems[#problems + 1] = "boss.lua: growth must be a table"
    end
    local phases = data.phases
    if type(phases) ~= "table" or #phases < 2 then
        problems[#problems + 1] = "boss.lua: phases needs at least two entries"
        phases = {}
    else
        local last = math.huge
        for index, phase in ipairs(phases) do
            if type(phase) ~= "table" or not IsNumber(phase.health, 0) or phase.health >= last or phase.health > 1 then
                problems[#problems + 1] = "boss.lua: phase " .. index .. " needs a health fraction below the previous phase's"
            else
                last = phase.health
            end
        end
        if type(phases[1]) == "table" and phases[1].health ~= 1 then
            problems[#problems + 1] = "boss.lua: the first phase starts at health = 1"
        end
    end
    if type(data.abilities) ~= "table" or #data.abilities == 0 then
        problems[#problems + 1] = "boss.lua: abilities must list the boss's abilities"
    else
        local hints = {}
        for index, spec in ipairs(data.abilities) do
            if type(spec) ~= "table" or type(spec.name) ~= "string" then
                problems[#problems + 1] = "boss.lua: abilities[" .. index .. "] needs a name"
            else
                if not IsNumber(spec.phase, 1) or spec.phase > math.max(1, #phases) or spec.phase % 1 ~= 0 then
                    problems[#problems + 1] = "boss.lua: ability " .. spec.name .. " needs a phase between 1 and " .. #phases
                end
                hints[spec.name] = spec
            end
        end
        ValidateHints(problems, biome, "boss.lua", hints)
    end
    local reward = data.reward
    if type(reward) ~= "table" or not IsNumber(reward.gold, 0) or not IsNumber(reward.xp, 0) then
        problems[#problems + 1] = "boss.lua: reward needs gold and xp"
    else
        if reward.items ~= nil and not IsNumber(reward.items, 0) then
            problems[#problems + 1] = "boss.lua: reward.items must be a number"
        end
        ValidateLoot(problems, "boss.lua reward.loot", reward.loot)
    end
    for _, key in ipairs({ "summons", "extra_units" }) do
        if data[key] ~= nil then
            if type(data[key]) ~= "table" then
                problems[#problems + 1] = "boss.lua: " .. key .. " must be a list of unit names"
            else
                for _, unit in ipairs(data[key]) do
                    if type(unit) ~= "string" then problems[#problems + 1] = "boss.lua: " .. key .. " must be unit names" end
                end
            end
        end
    end
    return problems
end

function ArenaBiomes.ValidateFx(biome, data)
    local problems = {}
    if type(data) ~= "table" then
        return { "fx.lua must return a table" }
    end
    local function Each(key, suffix)
        local list = data[key]
        if list == nil then return end
        if type(list) ~= "table" then
            problems[#problems + 1] = "fx.lua: " .. key .. " must be a table"
            return
        end
        for _, path in pairs(list) do
            if type(path) ~= "string" or (suffix and path:sub(-#suffix) ~= suffix) then
                problems[#problems + 1] = "fx.lua: " .. key .. " entry " .. tostring(path) .. (suffix and (" must end in " .. suffix) or " must be a string")
            end
        end
    end
    Each("particles", ".vpcf")
    Each("soundfiles", ".vsndevts")
    Each("models", ".vmdl")
    Each("sounds")
    return problems
end

------------------------------------------------------------------------------------- loading

function ArenaBiomes.Load(force)
    if loaded and not force then
        return ArenaBiomes.list
    end
    loaded = true
    ArenaBiomes.list = {}
    for _, name in ipairs(ArenaBiomes.NAMES) do
        local base = "arena/biomes/" .. name .. "/"
        local entry = { name = name, problems = {} }
        local parts = {
            { key = "monsters", check = ArenaBiomes.ValidateMonsters },
            { key = "boss", check = ArenaBiomes.ValidateBoss },
            { key = "fx", check = ArenaBiomes.ValidateFx },
        }
        for _, part in ipairs(parts) do
            local data, failure = Load(base .. part.key, force)
            local problems = failure and { failure } or (data and part.check(name, data)) or {}
            if data or failure then
                if #problems > 0 then
                    for _, problem in ipairs(problems) do
                        Log(name .. " " .. part.key .. " switched off: " .. problem)
                        entry.problems[#entry.problems + 1] = part.key .. ": " .. problem
                    end
                else
                    entry[part.key] = data
                end
            end
        end
        ArenaBiomes.list[name] = entry
    end
    return ArenaBiomes.list
end

function ArenaBiomes.Get(name)
    return ArenaBiomes.Load()[name]
end

-- The groups for a camp of `tier` in `biome`, and the biome whose monster stats they use. A
-- biome with no groups for that tier yet borrows the wilds groups, so a marker placed before
-- its monsters exist still has something to fight.
function ArenaBiomes.Pool(name, tier)
    local entry = ArenaBiomes.Get(name)
    local monsters = entry and entry.monsters
    local groups = monsters and monsters.tiers[tier]
    if groups and #groups > 0 then
        return groups, monsters
    end
    if name ~= "wilds" then
        if not warned[name .. tier] then
            warned[name .. tier] = true
            Log(name .. " has no tier " .. tier .. " monsters yet; its camps use the wilds pool")
        end
        return ArenaBiomes.Pool("wilds", tier)
    end
end

-- The stats and AI hints of a monster by unit name, from whichever biome defines it.
function ArenaBiomes.Monster(unitName)
    for _, name in ipairs(ArenaBiomes.NAMES) do
        local entry = ArenaBiomes.Get(name)
        local monsters = entry and entry.monsters
        if monsters and monsters.monsters[unitName] then
            return monsters.monsters[unitName], name
        end
    end
end

-- Every unit the biomes can spawn, for precaching.
function ArenaBiomes.Units()
    local units, seen = {}, {}
    local function Add(name)
        if name and not seen[name] then
            seen[name] = true
            units[#units + 1] = name
        end
    end
    for _, name in ipairs(ArenaBiomes.NAMES) do
        local entry = ArenaBiomes.Get(name)
        if entry.monsters then
            local names = {}
            for unit in pairs(entry.monsters.monsters) do names[#names + 1] = unit end
            table.sort(names)
            for _, unit in ipairs(names) do Add(unit) end
        end
        if entry.boss then
            Add(entry.boss.unit)
            for _, unit in ipairs(entry.boss.summons or {}) do Add(unit) end
            for _, unit in ipairs(entry.boss.extra_units or {}) do Add(unit) end
        end
    end
    return units
end

-- Called from Precache in addon_game_mode.lua (through precache/precache.lua).
function ArenaBiomes.Precache(context)
    ArenaBiomes.Load()
    ArenaFxCore.Precache(context)
    for _, unit in ipairs(ArenaBiomes.Units()) do
        PrecacheUnitByNameSync(unit, context)
    end
    for _, name in ipairs(ArenaBiomes.NAMES) do
        local boss = ArenaBiomes.Get(name).boss
        for _, particle in pairs(boss and boss.effects or {}) do
            PrecacheResource("particle", particle, context)
        end
        local fx = ArenaBiomes.Get(name).fx
        if fx then
            for _, particle in pairs(fx.particles or {}) do PrecacheResource("particle", particle, context) end
            for _, file in ipairs(fx.soundfiles or {}) do PrecacheResource("soundfile", file, context) end
            for _, model in ipairs(fx.models or {}) do PrecacheResource("model", model, context) end
        end
    end
end

return ArenaBiomes
