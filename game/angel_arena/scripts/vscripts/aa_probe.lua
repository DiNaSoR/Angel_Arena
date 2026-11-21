-- TEMPORARY probe (map work): reachability between regions and the state of the arena modifiers.
local function q(label, x1, y1, x2, y2)
    local a = GetGroundPosition(Vector(x1, y1, 0), nil)
    local b = GetGroundPosition(Vector(x2, y2, 0), nil)
    print("NAVQ " .. label .. " " .. tostring(GridNav:CanFindPath(a, b)) .. " z1=" .. math.floor(a.z) .. " z2=" .. math.floor(b.z))
end
q("plateau-northstrip", -6784, 6592, -2000, 6400)
q("plateau-nwcamp", -6784, 6592, -6774, 3713)
q("nwcamp-plain", -6774, 3713, -2000, 3000)
q("plain-northstrip", -2000, 3000, -2000, 6400)
q("plain-pocket", -2000, 3000, -4480, 4480)
q("plain-eastplateau", -2000, 3000, 3682, 4561)
q("plain-nesea", -2000, 3000, 6000, 3000)
q("plain-lavaplain", -2000, 3000, 2500, -3000)
q("plain-nsea", -2000, 3000, 1500, 6700)
q("base-plain", -6592, 384, -2000, 3000)
q("plain-arena", -2000, 3000, 6800, 7000)
q("nesea-demonbase", 6000, 3000, 6400, 320)
q("plain-swstrip", -2000, 3000, -6600, 2450)
q("plain-southband", -2000, 3000, 0, -6400)
print("NAVQ server class modifier_arena_monster = " .. tostring(_G.modifier_arena_monster ~= nil))
local with, without = 0, 0
for _, u in ipairs(FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, 30000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
    if u:HasModifier("modifier_arena_monster") then with = with + 1 else without = without + 1 end
end
print("NAVQ neutral units with monster modifier " .. with .. " without " .. without)
