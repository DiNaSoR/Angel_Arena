-- Biome bosses: everything they have in common. A biome's boss.lua is just numbers, its phase
-- thresholds and the list of its abilities (which live in the biome's abilities.lua).
--
-- Life of a boss:
--   * `warning` seconds before `first_spawn` (game clock) the match is told it is coming;
--   * it appears at the map's arena_boss_<biome> marker, announced to everyone and briefly
--     revealed to both teams;
--   * it fights with the shared monster brain (arena/core/monster_ai.lua). Its abilities are
--     learned per phase: an ability listed with phase = 2 is unlearned until the boss drops to
--     that phase's health, and every learned ability is set to the current phase's level, so the
--     KV values of level 2 and 3 are the phase 2 and 3 versions of the move;
--   * each new phase is announced and adds a stack of modifier_arena_boss_enraged;
--   * pulled further than `leash` from its marker it walks home, heals fully and starts over at
--     phase 1;
--   * when it dies, every hero on the killing team is paid `reward.gold` and `reward.xp`,
--     `reward.items` items drop, and it returns `respawn` seconds later, stronger by `growth`
--     for every time it has been killed.
-- Localization tokens it uses (tools/biomes/tooltips/<biome>.txt): arena_<biome>_boss_soon,
-- arena_<biome>_boss_awakens, arena_<biome>_boss_phase_<n> for every phase after the first,
-- arena_<biome>_boss_slain (shown after the killing team's name).

require("arena/core/biomes")
require("arena/core/markers")
require("arena/core/monster_ai")
require("arena/core/rewards")
require("arena/core/camps")

if ArenaBosses then
    return ArenaBosses
end

ArenaBosses = { states = {} }

ArenaBosses.THINK_INTERVAL = 1
ArenaBosses.BRAIN_INTERVAL = 0.25
ArenaBosses.DEFAULT_WARNING = 60
ArenaBosses.DEFAULT_AGGRO = 700
ArenaBosses.ANNOUNCE_SECONDS = 6
ArenaBosses.REVEAL_SECONDS = 6
ArenaBosses.REVEAL_RADIUS = 900
ArenaBosses.TEAM_TOKENS = { [DOTA_TEAM_GOODGUYS or 2] = "#arena_team_angels", [DOTA_TEAM_BADGUYS or 3] = "#arena_team_demons" }

local function Now()
    return GameRules:GetDOTATime(false, false)
end

local function Announce(state, key, prefix)
    local style = { color = state.def.color or "#ffd36b" }
    if prefix then
        Notifications:TopToAll({ text = prefix, duration = ArenaBosses.ANNOUNCE_SECONDS, style = style })
        Notifications:TopToAll({ text = "#arena_" .. state.biome .. "_boss_" .. key, duration = ArenaBosses.ANNOUNCE_SECONDS, continue = true })
    else
        Notifications:TopToAll({ text = "#arena_" .. state.biome .. "_boss_" .. key, duration = ArenaBosses.ANNOUNCE_SECONDS, style = style })
    end
end

local function Sound(state, key)
    local sounds = state.def.sounds or {}
    EmitGlobalSound(sounds[key] or ArenaFxCore.SOUNDS.phase)
end

function ArenaBosses:Init()
    if self.started then
        return
    end
    self.started = true
    ArenaBiomes.Load()
    self.states = {}
    for _, biome in ipairs(ArenaBiomes.NAMES) do
        local def = ArenaBiomes.Get(biome).boss
        if def then
            local marker = ArenaMarkers.FindBoss(biome)
            if marker then
                self.states[#self.states + 1] = {
                    biome = biome, def = def, origin = marker:GetAbsOrigin(),
                    generation = 0, nextSpawn = def.first_spawn, warned = false, adds = {},
                }
            else
                print("[Arena] no " .. ArenaMarkers.BossName(biome) .. " marker on this map; the " .. biome .. " boss stays away")
            end
        end
    end
    Timers:CreateTimer(self.THINK_INTERVAL, function()
        return self:Think()
    end)
end

function ArenaBosses:Think()
    local state = GameRules:State_Get()
    if state >= DOTA_GAMERULES_STATE_POST_GAME then
        return nil
    end
    if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        local now = Now()
        for _, boss in ipairs(self.states) do
            -- One failing boss must not stop the timer (Timers drops a callback that errors).
            local ok, failure = pcall(self.Update, self, boss, now)
            if not ok then
                print("[Arena] " .. boss.biome .. " boss failed: " .. tostring(failure))
            end
        end
    end
    return self.THINK_INTERVAL
end

function ArenaBosses:Update(state, now)
    if state.unit then
        if IsValidEntity(state.unit) and state.unit:IsAlive() then
            return
        end
        -- Gone without a death event (removed by something else): no reward, but it comes back.
        state.unit, state.brain = nil, nil
        self:ClearAdds(state)
        state.nextSpawn = now + state.def.respawn
    end
    local warning = state.def.warning or self.DEFAULT_WARNING
    if not state.warned and warning > 0 and now >= state.nextSpawn - warning and now < state.nextSpawn then
        state.warned = true
        Announce(state, "soon")
    end
    if now >= state.nextSpawn then
        self:Spawn(state, now)
    end
end

-- Final stats for the boss's current generation (1 = first appearance).
function ArenaBosses.Stats(def, generation)
    local growth = def.growth or {}
    local extra = math.max(0, generation - 1)
    local base = def.stats
    return {
        health = math.ceil(base.health * (1 + (growth.health or 0) * extra)),
        damage = math.ceil(base.damage * (1 + (growth.damage or 0) * extra)),
        armor = base.armor * (1 + (growth.armor or 0) * extra),
        gold = base.gold or 0,
        xp = base.xp or 0,
    }
end

-- What the killing team earns for the boss's current generation.
function ArenaBosses.Reward(def, generation)
    local scale = 1 + ((def.growth or {}).reward or 0) * math.max(0, generation - 1)
    return math.ceil(def.reward.gold * scale), math.ceil(def.reward.xp * scale)
end

function ArenaBosses:Spawn(state, now)
    local def = state.def
    local unit = CreateUnitByName(def.unit, state.origin, true, nil, nil, DOTA_TEAM_NEUTRALS)
    if not unit then
        state.nextSpawn = now + 30
        return
    end
    state.generation = state.generation + 1
    state.unit = unit
    state.warned = false
    unit.arenaBoss = state
    ArenaCamps.ApplyStats(unit, ArenaBosses.Stats(def, state.generation), true)
    local mark = unit:AddNewModifier(unit, nil, "modifier_arena_boss", {})
    if mark then
        mark:SetStackCount(state.generation)
    end
    self:SetPhase(state, 1)

    local hints = {}
    for _, spec in ipairs(def.abilities) do
        hints[spec.name] = spec
    end
    state.brain = ArenaMonsterAI.Attach(unit, {
        home = unit:GetAbsOrigin(),
        leash = def.leash,
        aggro = def.aggro or self.DEFAULT_AGGRO,
        hints = hints,
        interval = self.BRAIN_INTERVAL,
        group = {},
        onThink = function()
            self:CheckPhase(state)
        end,
        onHome = function()
            self:Reset(state)
        end,
    })

    Announce(state, "awakens")
    Sound(state, "awaken")
    ArenaFxCore.Burst(ArenaFxCore.PARTICLES.boss_arrival, state.origin)
    AddFOWViewer(DOTA_TEAM_GOODGUYS, state.origin, self.REVEAL_RADIUS, self.REVEAL_SECONDS, false)
    AddFOWViewer(DOTA_TEAM_BADGUYS, state.origin, self.REVEAL_RADIUS, self.REVEAL_SECONDS, false)
    return unit
end

-- Learns or unlearns the boss's abilities for `phase` and sets its rage stacks.
function ArenaBosses:SetPhase(state, phase)
    local unit = state.unit
    state.phase = phase
    for _, spec in ipairs(state.def.abilities) do
        local ability = unit:FindAbilityByName(spec.name)
        if ability then
            if spec.phase <= phase then
                ability:SetLevel(math.min(phase, ability:GetMaxLevel()))
            else
                ability:SetLevel(0)
            end
        end
    end
    if phase > 1 then
        local rage = unit:FindModifierByName("modifier_arena_boss_enraged")
            or unit:AddNewModifier(unit, nil, "modifier_arena_boss_enraged", {})
        if rage then
            rage:SetStackCount(phase - 1)
        end
    else
        unit:RemoveModifierByName("modifier_arena_boss_enraged")
    end
end

function ArenaBosses:CheckPhase(state)
    local unit = state.unit
    local phases = state.def.phases
    local fraction = unit:GetHealth() / math.max(1, unit:GetMaxHealth())
    local entered = false
    while state.phase < #phases and fraction <= phases[state.phase + 1].health do
        self:SetPhase(state, state.phase + 1)
        entered = true
    end
    if entered then
        Announce(state, "phase_" .. state.phase)
        Sound(state, "phase")
        local effect = (state.def.effects or {}).phase
        if effect then
            ArenaFxCore.On(effect, unit)
        end
    end
end

-- The boss was dragged out of its lair and walked home: it heals and starts the fight over.
function ArenaBosses:Reset(state)
    local unit = state.unit
    if not unit or not IsValidEntity(unit) or not unit:IsAlive() then
        return
    end
    unit:SetHealth(unit:GetMaxHealth())
    self:SetPhase(state, 1)
    self:ClearAdds(state)
end

-- Spawns a helper for a boss ability (for example a summon). `caster` is the boss. The helper
-- uses the stats of the monster of the same name in the biome files, grown to the match clock,
-- fights with the shared brain around the boss's lair and dies with the boss.
function ArenaBosses.Summon(caster, unitName, position, duration)
    local state = caster.arenaBoss
    local base = ArenaBiomes.Monster(unitName)
    if not state or not base then
        return nil
    end
    local unit = CreateUnitByName(unitName, position, true, nil, nil, DOTA_TEAM_NEUTRALS)
    if not unit then
        return nil
    end
    local minute = Now() / 60
    ArenaCamps:SetupMonster(unit, nil, base, ArenaTiers.Level(minute), state.phase or 1, nil, {
        home = state.origin, leash = state.def.leash, aggro = ArenaBosses.DEFAULT_AGGRO, group = state.brain and state.brain.group,
    })
    unit.arenaSummon = state
    if duration and duration > 0 then
        unit:AddNewModifier(caster, nil, "modifier_kill", { duration = duration })
    end
    state.adds[unit] = true
    return unit
end

-- How many of a boss's helpers are alive.
function ArenaBosses.CountAdds(caster)
    local state = caster.arenaBoss
    local count = 0
    for unit in pairs(state and state.adds or {}) do
        if IsValidEntity(unit) and unit:IsAlive() then
            count = count + 1
        else
            state.adds[unit] = nil
        end
    end
    return count
end

function ArenaBosses:ClearAdds(state)
    for unit in pairs(state.adds) do
        if IsValidEntity(unit) and unit:IsAlive() then
            unit:ForceKill(false)
        end
    end
    state.adds = {}
end

-- Called from GameMode:OnEntityKilled for every death. Returns true for biome bosses.
function ArenaBosses:OnUnitKilled(unit, attacker)
    local state = unit.arenaBoss
    if not state or state.unit ~= unit then
        return false
    end
    state.unit = nil
    state.brain = nil
    self:ClearAdds(state)
    local now = Now()
    state.nextSpawn = now + state.def.respawn
    local team = ArenaRewards.TeamOf(attacker)
    if team then
        local gold, xp = ArenaBosses.Reward(state.def, state.generation)
        ArenaRewards.Team(team, gold, xp)
        ArenaRewards.BossDrops(state.def.reward.items or 0, state.def.reward.loot, unit:GetAbsOrigin())
        Announce(state, "slain", self.TEAM_TOKENS[team])
    end
    Sound(state, "death")
    return true
end

-- Brings a biome's boss in now (the arena_boss_spawn cheat command).
function ArenaBosses:ForceSpawn(biome)
    for _, state in ipairs(self.states) do
        if state.biome == biome and not state.unit then
            return self:Spawn(state, Now())
        end
    end
end

return ArenaBosses
