-- Reads the Angel Arena item definitions once and answers questions about them.
--
-- Both arena_items.lua and arena_modifiers.lua need this, and the client may load either one
-- first (it loads a modifier's script on its own when it first sees the modifier), so the
-- data lives here and each of them requires it.

if ArenaItems then
    return ArenaItems
end

local DEFINITIONS_FILE = "scripts/npc/items/arena/arena_items.txt"
local SCRIPT = "items/arena/arena_items.lua"
local NONE = {}

ArenaItems = { definitions = {} }

local values = {}
local mechanics = {}

for name, definition in pairs(LoadKeyValues(DEFINITIONS_FILE) or {}) do
    -- Recipes share the file but are plain data-driven items with nothing to script.
    if type(definition) == "table" and definition.ScriptFile == SCRIPT then
        ArenaItems.definitions[name] = definition
        values[name] = {}
        for key, value in pairs(definition.AbilityValues or {}) do
            values[name][key] = tonumber(value)
        end
        mechanics[name] = {}
        for mechanic in string.gmatch(definition.ArenaMechanics or "", "%S+") do
            table.insert(mechanics[name], mechanic)
        end
    end
end

-- The AbilityValues of an item, as numbers. Safe to call with nil.
function ArenaItems.Values(ability)
    return ability and values[ability:GetAbilityName()] or NONE
end

-- The passive mechanics an item names in "ArenaMechanics".
function ArenaItems.Mechanics(ability)
    return ability and mechanics[ability:GetAbilityName()] or NONE
end

return ArenaItems
