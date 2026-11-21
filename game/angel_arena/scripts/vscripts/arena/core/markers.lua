-- Finding the camp and boss markers on the map.
--
-- The map contract: camp markers are point entities named exactly arena_camp_<biome>_<tier>
-- (biome one of ArenaBiomes.NAMES, tier 1 to 4); many markers may share a name. Each biome
-- boss stands at the single marker arena_boss_<biome>. Everything else about a camp comes from
-- Lua. Markers are looked up by exact name for every biome and tier pair.
--
-- Older maps only have markers named creep_camp. They are used only when the map has no
-- arena_camp_* marker at all, and become wilds camps: a marker whose CreepType keyvalue is set
-- to 1..4 keeps that tier; otherwise markers are ranked by distance to the nearest team base and
-- the nearest 30% are easy, the next 30% medium, the next 25% hard and the farthest 15% elite.
-- A base is the first of LEGACY_BASE_CLASSES the map has (fountains, then hero spawn points);
-- with none of them, the edge of the map counts as home and its middle as the wild.

if ArenaMarkers then
    return ArenaMarkers
end

ArenaMarkers = {}

ArenaMarkers.LEGACY_NAME = "creep_camp"
ArenaMarkers.LEGACY_BIOME = "wilds"
ArenaMarkers.LEGACY_TIER_SHARE = { 0.30, 0.30, 0.25, 0.15 }
ArenaMarkers.LEGACY_BASE_CLASSES = { "ent_dota_fountain", "info_player_start_goodguys", "info_player_start_badguys" }

function ArenaMarkers.CampName(biome, tier)
    return "arena_camp_" .. biome .. "_" .. tier
end

function ArenaMarkers.BossName(biome)
    return "arena_boss_" .. biome
end

local function Camp(marker, biome, tier, name, legacy)
    return {
        marker = marker,
        id = marker:GetEntityIndex(),
        origin = marker:GetAbsOrigin(),
        biome = biome,
        tier = tier,
        name = name,
        legacy = legacy or false,
    }
end

-- All camps on the map, and "arena" or "legacy" for which kind of marker they came from.
function ArenaMarkers.FindCamps(biomes, tiers)
    local camps = {}
    for _, biome in ipairs(biomes) do
        for tier = 1, tiers do
            local name = ArenaMarkers.CampName(biome, tier)
            for _, marker in ipairs(Entities:FindAllByName(name) or {}) do
                camps[#camps + 1] = Camp(marker, biome, tier, name)
            end
        end
    end
    if #camps > 0 then
        return camps, "arena"
    end
    return ArenaMarkers.LegacyCamps(), "legacy"
end

-- The tier for the rank-th of `count` legacy markers sorted from nearest to farthest.
function ArenaMarkers.LegacyTier(rank, count)
    local cumulative = 0
    for tier, share in ipairs(ArenaMarkers.LEGACY_TIER_SHARE) do
        cumulative = cumulative + share
        if rank <= math.floor(count * cumulative + 0.5) then
            return tier
        end
    end
    return #ArenaMarkers.LEGACY_TIER_SHARE
end

local function DesignerTier(marker)
    local ok, value = pcall(marker.GetIntAttr, marker, "CreepType")
    value = ok and tonumber(value) or nil
    if value and value >= 1 and value <= #ArenaMarkers.LEGACY_TIER_SHARE and value % 1 == 0 then
        return value
    end
end

function ArenaMarkers.LegacyCamps()
    local markers = Entities:FindAllByName(ArenaMarkers.LEGACY_NAME) or {}
    if #markers == 0 then
        return {}
    end
    local bases, anchor = {}, "the map edge"
    for _, classname in ipairs(ArenaMarkers.LEGACY_BASE_CLASSES) do
        for _, base in ipairs(Entities:FindAllByClassname(classname) or {}) do
            bases[#bases + 1] = base
            anchor = classname
        end
        if classname == "ent_dota_fountain" and #bases > 0 then break end
    end
    print(string.format("[Arena] %d legacy creep_camp markers ranked by distance to %s", #markers, anchor))
    local ranked = {}
    for _, marker in ipairs(markers) do
        local origin = marker:GetAbsOrigin()
        local distance = math.huge
        for _, base in ipairs(bases) do
            distance = math.min(distance, (base:GetAbsOrigin() - origin):Length2D())
        end
        if distance == math.huge then
            -- No base found: treat the edge of the map as home and its middle as the wild.
            distance = -origin:Length2D()
        end
        ranked[#ranked + 1] = { marker = marker, origin = origin, distance = distance }
    end
    table.sort(ranked, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        if a.origin.x ~= b.origin.x then return a.origin.x < b.origin.x end
        return a.origin.y < b.origin.y
    end)
    local camps = {}
    for rank, entry in ipairs(ranked) do
        local tier = DesignerTier(entry.marker) or ArenaMarkers.LegacyTier(rank, #ranked)
        camps[#camps + 1] = Camp(entry.marker, ArenaMarkers.LEGACY_BIOME, tier, ArenaMarkers.LEGACY_NAME, true)
    end
    return camps
end

function ArenaMarkers.FindBoss(biome)
    return Entities:FindByName(nil, ArenaMarkers.BossName(biome))
end

return ArenaMarkers
