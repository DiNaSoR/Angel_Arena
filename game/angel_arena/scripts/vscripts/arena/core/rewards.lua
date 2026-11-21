-- What monsters and bosses give besides their normal gold and experience bounty.
--
-- Camp kills roll for an item from their tier's pool (plus any items the biome adds for that tier
-- in monsters.lua). The chance starts at the tier's drop_chance and grows by half of it after
-- every miss in the same camp, so a team clearing one camp is never dry for long. Champions always
-- drop, from the pool one tier higher. Bosses pay every hero on the killing team and drop items.
-- Items are dropped through the camps' existing drop code (CreepItemDrop in
-- mechanics/camps/item_drop.lua), which also removes unclaimed loot after a while.

require("arena/core/tiers")

if ArenaRewards then
    return ArenaRewards
end

ArenaRewards = {}

ArenaRewards.PITY = 0.5

-- Tier 5 is the "beyond elite" pool used by elite champions and bosses.
ArenaRewards.LOOT = {
    [1] = { "item_flask", "item_clarity", "item_enchanted_mango", "item_arena_angels_tear", "item_arena_starlight_phial" },
    [2] = { "item_arena_ember_flask", "item_arena_demons_blood", "item_arena_ironskin_elixir",
            "item_tome_str_3", "item_tome_agi_3", "item_tome_int_3" },
    [3] = { "item_arena_demon_horn", "item_arena_halo_shard", "item_arena_seraph_feather", "item_arena_gilded_buckle",
            "item_arena_whetstone", "item_arena_blessed_ingot", "item_tome_str_6", "item_tome_agi_6", "item_tome_int_6" },
    [4] = { "item_arena_tome_vitality", "item_arena_tome_stoneskin", "item_arena_tome_slaughter", "item_arena_champions_ring",
            "item_arena_gladius", "item_arena_mana_prism", "item_arena_wardens_buckler", "item_arena_obsidian_plate" },
    [5] = { "item_arena_tome_ascension", "item_arena_codex", "item_arena_prism_core", "item_arena_oracle_eye",
            "item_arena_titan_knuckle", "item_arena_executioner_axe" },
}

ArenaRewards.misses = {}

-- The team that earns a kill: the Angels or the Demons, never the neutrals.
function ArenaRewards.TeamOf(attacker)
    if not attacker or not IsValidEntity(attacker) or not attacker.GetTeamNumber then
        return nil
    end
    local team = attacker:GetTeamNumber()
    if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS then
        return team
    end
end

-- The item pool for a tier, with the biome's own additions (`loot` in monsters.lua or the boss's
-- reward.loot) appended.
function ArenaRewards.Pool(tier, extra)
    local pool = {}
    for _, item in ipairs(ArenaRewards.LOOT[math.min(tier, 5)] or {}) do
        pool[#pool + 1] = item
    end
    for _, item in ipairs(extra or {}) do
        pool[#pool + 1] = item
    end
    return pool
end

local function Drop(pool, position)
    if #pool == 0 then return end
    local item = pool[RandomInt(1, #pool)]
    if CreepItemDrop then
        CreepItemDrop:CreateDrop(item, position)
    end
    return item
end

-- Rolls the item drop for a camp monster killed by `attacker`. Returns the item name or nil.
function ArenaRewards.CampDrop(camp, position, attacker, champion)
    if not ArenaRewards.TeamOf(attacker) then
        return nil
    end
    local extra = camp.loot or {}
    if champion then
        return Drop(ArenaRewards.Pool(camp.tier + 1, extra[camp.tier + 1]), position)
    end
    local misses = ArenaRewards.misses[camp.id] or 0
    local chance = ArenaTiers.Profile(camp.tier).drop_chance * (1 + ArenaRewards.PITY * misses)
    if RandomFloat(0, 1) >= chance then
        ArenaRewards.misses[camp.id] = misses + 1
        return nil
    end
    ArenaRewards.misses[camp.id] = 0
    return Drop(ArenaRewards.Pool(camp.tier, extra[camp.tier]), position)
end

-- Gold and experience for every hero of `team`. Returns how many heroes were paid.
function ArenaRewards.Team(team, gold, xp)
    local paid = 0
    -- A plain loop: this addon's PlayerResource:GetAllTeamPlayerIDs() returns a luafun iterator,
    -- which ipairs cannot walk.
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetTeam(playerID) == team then
            local hero = PlayerResource:GetSelectedHeroEntity(playerID)
            if hero then
                Gold:AddGoldWithMessage(hero, gold, playerID)
                hero:AddExperience(xp, DOTA_ModifyXP_Unspecified, false, true)
            else
                Gold:AddGold(playerID, gold)
            end
            paid = paid + 1
        end
    end
    return paid
end

-- Drops `count` items from the boss pool (tier 5 plus the boss's own loot) around `position`.
function ArenaRewards.BossDrops(count, extra, position)
    local dropped = {}
    local pool = ArenaRewards.Pool(5, extra)
    for _ = 1, count or 0 do
        dropped[#dropped + 1] = Drop(pool, position)
    end
    return dropped
end

return ArenaRewards
