-- Prints one biome's Lua data files as JSON so the Python tools can check them.
-- Run from the repository root: lua tools/biomes/dump_biome.lua <biome>   ("core" for arena/core/fx.lua)
-- Output: {"monsters": ..., "boss": ..., "fx": ..., "errors": {"<part>": "<message>"}}
-- A part that has no file is left out; a file that fails to load is reported under "errors".

local biome = assert(arg[1], "usage: lua tools/biomes/dump_biome.lua <biome>")
local ROOT = "game/angel_arena/scripts/vscripts/"
package.path = ROOT .. "?.lua;" .. package.path

local function Encode(value, out)
    local kind = type(value)
    if kind == "table" then
        local count = 0
        for _ in pairs(value) do count = count + 1 end
        if count > 0 and count == #value then
            out[#out + 1] = "["
            for index, item in ipairs(value) do
                if index > 1 then out[#out + 1] = "," end
                Encode(item, out)
            end
            out[#out + 1] = "]"
        else
            out[#out + 1] = "{"
            local keys = {}
            for key in pairs(value) do keys[#keys + 1] = key end
            table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
            for index, key in ipairs(keys) do
                if index > 1 then out[#out + 1] = "," end
                Encode(tostring(key), out)
                out[#out + 1] = ":"
                Encode(value[key], out)
            end
            out[#out + 1] = "}"
        end
    elseif kind == "string" then
        out[#out + 1] = '"' .. value:gsub('[%c"\\]', function(c)
            return string.format("\\u%04x", c:byte())
        end) .. '"'
    elseif kind == "number" then
        out[#out + 1] = string.format("%.14g", value)
    elseif kind == "boolean" then
        out[#out + 1] = tostring(value)
    else
        out[#out + 1] = '"<' .. kind .. '>"'
    end
end

local result, errors = {}, {}
if biome == "core" then
    -- The shared effects in arena/core/fx.lua, in the same shape as a biome's fx.lua.
    local ok, core = pcall(dofile, ROOT .. "arena/core/fx.lua")
    if ok then
        local particles = {}
        for key, path in pairs(core.PARTICLES) do particles[key] = path end
        for key, path in pairs(core.STATUS) do particles["status_" .. key] = path end
        result.fx = { particles = particles, sounds = core.SOUNDS, soundfiles = core.SOUND_FILES }
    else
        errors.fx = tostring(core)
    end
end
for _, part in ipairs(biome == "core" and {} or { "monsters", "boss", "fx" }) do
    local path = ROOT .. "arena/biomes/" .. biome .. "/" .. part .. ".lua"
    local file = io.open(path, "r")
    if file then
        file:close()
        local ok, data = pcall(dofile, path)
        if not ok then
            errors[part] = tostring(data)
        elseif type(data) ~= "table" then
            errors[part] = part .. ".lua must return a table"
        else
            result[part] = data
        end
    end
end
result.errors = errors

local out = {}
Encode(result, out)
io.write(table.concat(out), "\n")
