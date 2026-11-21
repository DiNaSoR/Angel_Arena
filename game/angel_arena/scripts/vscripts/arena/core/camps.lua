-- Monster camps: spawning, respawning and growth.
--
-- A camp is one marker (see arena/core/markers.lua). When it is empty, its respawn time has
-- passed and no enemy hero stands within BLOCK_RADIUS, it fills with one group picked at random
-- from its biome's tier pool (arena/biomes/<biome>/monsters.lua). A camp never refills while any
-- of its monsters lives, so players are not buried mid-fight, and a hero standing in an empty
-- camp holds it empty. Monster stats come from the biome file and grow with the match clock
-- (arena/core/tiers.lua); a camp nobody is fighting catches up with the clock on its own.

require("arena/core/biomes")
require("arena/core/tiers")
require("arena/core/markers")
require("arena/core/monster_ai")
require("arena/core/champions")
require("arena/core/rewards")

if ArenaCamps then
    return ArenaCamps
end

ArenaCamps = { camps = {} }

ArenaCamps.THINK_INTERVAL = 1
ArenaCamps.BLOCK_RADIUS = 700   -- an enemy hero this close to an empty camp keeps it empty
ArenaCamps.SPAWN_SPREAD = 140   -- monsters after the first stand on a ring this wide
ArenaCamps.EMPTY_RETRY = 30     -- a camp with no monsters to spawn looks again after this long

local function Now()
    return GameRules:GetDOTATime(false, false)
end

function ArenaCamps:Init()
    if self.started then
        return
    end
    self.started = true
    ArenaBiomes.Load()
    local camps, source = ArenaMarkers.FindCamps(ArenaBiomes.NAMES, ArenaBiomes.TIERS)
    self.camps = {}
    self.source = source
    for _, camp in ipairs(camps) do
        camp.units = {}
        camp.group = {}
        camp.respawnAt = 0
        self.camps[#self.camps + 1] = camp
    end
    print(string.format("[Arena] %d camps from %s markers", #self.camps, source))
    local delay = SKIP_TEAM_SETUP and 0 or (INITIAL_CREEP_DELAY or 5)
    Timers:CreateTimer(delay, function()
        return self:Think()
    end)
end

function ArenaCamps:Think()
    local state = GameRules:State_Get()
    if state >= DOTA_GAMERULES_STATE_POST_GAME then
        return nil
    end
    if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        local now = Now()
        for _, camp in ipairs(self.camps) do
            -- One failing camp must not stop the timer (Timers drops a callback that errors).
            local ok, failure = pcall(self.UpdateCamp, self, camp, now)
            if not ok then
                print("[Arena] camp " .. tostring(camp.name) .. " #" .. tostring(camp.id) .. " failed: " .. tostring(failure))
            end
        end
    end
    return self.THINK_INTERVAL
end

-- Forgets dead, removed and dominated monsters. Returns how many still stand for the camp.
function ArenaCamps:CountAlive(camp)
    local count = 0
    for unit in pairs(camp.units) do
        if IsValidEntity(unit) and unit:IsAlive() and unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
            count = count + 1
        else
            camp.units[unit] = nil
        end
    end
    return count
end

function ArenaCamps:IsContested(camp)
    local heroes = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, camp.origin, nil, self.BLOCK_RADIUS,
        DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO,
        DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
        FIND_ANY_ORDER, false)
    return #heroes > 0
end

function ArenaCamps:UpdateCamp(camp, now)
    if self:CountAlive(camp) > 0 then
        self:Regrow(camp, now)
        return
    end
    if not camp.respawnAt then
        camp.respawnAt = now + ArenaTiers.Profile(camp.tier).respawn
    end
    if now < camp.respawnAt then
        return
    end
    if self:IsContested(camp) then
        camp.blocked = true
        return
    end
    camp.blocked = false
    self:Spawn(camp, now)
end

-- Where the slot-th of `count` monsters stands: the first on the marker, the rest on a ring.
function ArenaCamps:SlotPosition(camp, slot, count)
    if slot == 1 or count < 2 then
        return camp.origin
    end
    local angle = 2 * math.pi * (slot - 2) / (count - 1)
    return camp.origin + Vector(math.cos(angle) * self.SPAWN_SPREAD, math.sin(angle) * self.SPAWN_SPREAD, 0)
end

function ArenaCamps:Spawn(camp, now)
    local minute = now / 60
    local groups, pool = ArenaBiomes.Pool(camp.biome, camp.tier)
    if not groups then
        camp.respawnAt = now + self.EMPTY_RETRY
        return
    end
    local group = groups[RandomInt(1, #groups)]
    local names = ArenaTiers.Composition(group, camp.tier, minute)
    local level = ArenaTiers.Level(minute)
    local abilityLevel = ArenaTiers.AbilityLevel(camp.tier, minute)
    local championSlot, affix = ArenaChampions.Roll(camp.tier, minute, #names)

    camp.level = level
    camp.loot = pool.loot
    camp.group = {}
    camp.respawnAt = nil
    for slot, name in ipairs(names) do
        local home = self:SlotPosition(camp, slot, #names)
        local unit = CreateUnitByName(name, home, true, nil, nil, DOTA_TEAM_NEUTRALS)
        if unit then
            self:SetupMonster(unit, camp, pool.monsters[name], level, abilityLevel, slot == championSlot and affix or nil)
            camp.units[unit] = true
        end
    end
    if self:CountAlive(camp) == 0 then
        -- Nothing could be created (a missing unit definition): try again later, quietly.
        camp.respawnAt = now + self.EMPTY_RETRY
    end
end

-- Writes final stats onto a unit. A fresh unit spawns at full health; a living one keeps the
-- share of health it had.
function ArenaCamps.ApplyStats(unit, stats, fresh)
    local fraction = fresh and 1 or unit:GetHealth() / math.max(1, unit:GetMaxHealth())
    unit:SetBaseMaxHealth(stats.health)
    unit:SetMaxHealth(stats.health)
    unit:SetHealth(math.max(1, math.ceil(stats.health * fraction)))
    unit:SetBaseDamageMin(stats.damage)
    unit:SetBaseDamageMax(stats.damage)
    unit:SetPhysicalArmorBaseValue(stats.armor)
    unit:SetMinimumGoldBounty(stats.gold)
    unit:SetMaximumGoldBounty(stats.gold)
    unit:SetDeathXP(stats.xp)
end

-- Sets every ability to `level` (or its maximum). Stock neutrals lose Dota's own neutral_upgrade,
-- which would grow them a second time on top of the arena's growth.
function ArenaCamps.LevelAbilities(unit, level)
    local strip = {}
    for index = 0, unit:GetAbilityCount() - 1 do
        local ability = unit:GetAbilityByIndex(index)
        if ability then
            if ability:GetAbilityName() == "neutral_upgrade" then
                strip[#strip + 1] = "neutral_upgrade"
            else
                ability:SetLevel(math.min(level, ability:GetMaxLevel()))
            end
        end
    end
    for _, name in ipairs(strip) do
        unit:RemoveAbility(name)
    end
end

-- Sets up one camp monster (or a boss summon, which passes camp = nil and its own options).
function ArenaCamps:SetupMonster(unit, camp, base, level, abilityLevel, affix, options)
    options = options or {}
    unit.arenaCamp = camp
    unit.arenaMonster = { base = base, champion = affix and affix.name or nil }
    ArenaCamps.ApplyStats(unit, ArenaTiers.Stats(base, level, affix ~= nil), true)
    ArenaCamps.LevelAbilities(unit, abilityLevel)
    local profile = ArenaTiers.Profile(camp and camp.tier or options.tier or 1)
    ArenaMonsterAI.Attach(unit, {
        home = options.home or unit:GetAbsOrigin(),
        leash = options.leash or profile.leash,
        aggro = options.aggro or profile.aggro,
        hints = base.ai,
        group = camp and camp.group or options.group,
    })
    if affix then
        ArenaChampions.Apply(unit, affix)
    end
end

-- A camp nobody is fighting catches up with the match clock.
function ArenaCamps:Regrow(camp, now)
    local level = ArenaTiers.Level(now / 60)
    if camp.level == level or self:IsContested(camp) then
        return
    end
    for unit in pairs(camp.units) do
        local brain = unit.arenaBrain
        if (brain and brain.returning) or unit:GetAttackTarget() then
            return
        end
    end
    camp.level = level
    local abilityLevel = ArenaTiers.AbilityLevel(camp.tier, now / 60)
    for unit in pairs(camp.units) do
        local info = unit.arenaMonster
        ArenaCamps.ApplyStats(unit, ArenaTiers.Stats(info.base, level, info.champion ~= nil), false)
        ArenaCamps.LevelAbilities(unit, abilityLevel)
    end
end

-- Called from GameMode:OnEntityKilled for every death. Returns true for camp monsters.
function ArenaCamps:OnUnitKilled(unit, attacker)
    local camp = unit.arenaCamp
    if not camp or unit:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS then
        return false
    end
    camp.units[unit] = nil
    local info = unit.arenaMonster or {}
    ArenaRewards.CampDrop(camp, unit:GetAbsOrigin(), attacker, info.champion ~= nil)
    if self:CountAlive(camp) == 0 then
        camp.respawnAt = Now() + ArenaTiers.Profile(camp.tier).respawn
    end
    return true
end

-- One line per camp, for the arena_camps console command.
function ArenaCamps:Describe()
    local now = Now()
    local lines = {}
    for _, camp in ipairs(self.camps) do
        local wait = camp.respawnAt and math.max(0, math.floor(camp.respawnAt - now)) or 0
        lines[#lines + 1] = string.format("%s #%d tier %d: %d alive%s%s", camp.name, camp.id, camp.tier,
            self:CountAlive(camp), camp.respawnAt and (", respawn in " .. wait .. "s") or "",
            camp.blocked and ", blocked by heroes" or "")
    end
    return lines
end

return ArenaCamps
