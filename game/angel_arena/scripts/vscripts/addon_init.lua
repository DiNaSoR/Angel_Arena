-- Dota runs this file on the server and on every client before the game mode loads.
--
-- A Lua modifier only exists on a client once that client has run LinkLuaModifier for it. Modifiers
-- that belong to an ability or item get linked when the client loads that ability's script, but the
-- arena camp modifiers (monster brain, walking home, champions, bosses) are put on units directly,
-- so nothing would link them on the client and it would report "unknown modifier type".
local ok, err = pcall(require, "arena/core/modifiers")
if not ok then
    print("[Arena] addon_init could not load the shared modifiers: " .. tostring(err))
end
