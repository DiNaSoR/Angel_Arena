local vscripts = "game/angel_arena/scripts/vscripts/"

local function LoadScript(path, environment)
    local chunk = assert(loadfile(vscripts .. path))
    setfenv(chunk, setmetatable(environment, { __index = _G }))
    return chunk(), environment
end

local function IsValidEntity(unit)
    return unit ~= nil and not unit.invalid
end

local function Unit(team, health)
    return {
        OnDuel = true,
        IsBaseNPC = function() return true end,
        IsAlive = function(self) return self.health > 0 end,
        IsRealHero = function() return true end,
        GetPlayerOwnerID = function() return 0 end,
        GetTeamNumber = function() return team end,
        GetHealth = function(self) return self.health end,
        SetHealth = function(self, value) self.health = value end,
        ForceKill = function(self) self.killed = true; self.health = 0 end,
        Stop = function(self) self.stopped = true end,
        InterruptMotionControllers = function(self) self.interrupted = true end,
        HasModifier = function() return false end,
        health = health,
    }
end

do
    local _, trigger = LoadScript("mechanics/triggers/lavatrigger.lua", { IsValidEntity = IsValidEntity })
    assert(trigger.OnLavaTick(nil) == 1)

    local hero = Unit(2, 400)
    assert(trigger.OnLavaTick({ activator = hero }) == 1 and hero.health == 200 and not hero.killed)
    assert(trigger.OnLavaTick({ activator = hero }) == 1 and hero.killed, "equal damage should kill the unit")
end

do
    local destinations, camera, timers = {}, {}, {}
    local _, triggers = LoadScript("mechanics/teleport/teleports.lua", {
        IsValidEntity = IsValidEntity,
        DOTA_TEAM_GOODGUYS = 2,
        DOTA_TEAM_BADGUYS = 3,
        Entities = {
            FindByName = function(_, _, name)
                if destinations[name] then
                    return { GetAbsOrigin = function() return destinations[name] end }
                end
            end,
        },
        FindClearSpaceForUnit = function(unit, position) unit.position = position end,
        PlayerResource = {
            IsValidPlayerID = function(_, id) return id >= 0 end,
            SetCameraTarget = function(_, id, unit) camera[id] = unit end,
        },
        Timers = {
            CreateTimer = function(_, delay, callback)
                assert(delay == 0.2)
                table.insert(timers, callback)
            end,
        },
    })
    local radiant, dire = Unit(2, 300), Unit(3, 300)
    triggers.Northporttobase(nil)
    triggers.Northporttobase({ activator = radiant })
    assert(not radiant.position, "missing marker should leave the unit in place")

    destinations.teleport_good_out = "radiant exit"
    destinations.teleport_good_in = "dire exit"
    triggers.Northporttobase({ activator = radiant })
    assert(radiant.position == "radiant exit" and radiant.stopped and camera[0] == radiant)
    timers[1]()
    assert(camera[0] == nil)
    triggers.Southporttobase({ activator = dire })
    assert(dire.position == "dire exit" and dire.stopped)

    triggers.telegoodin({ activator = dire })
    assert(dire.position == "dire exit" and #timers == 2, "wrong team should not use the portal")
end

do
    local _, environment = LoadScript("mechanics/triggers/triggers.lua", {
        IsValidEntity = IsValidEntity,
        Heroes_In_Arena_Zone = {},
        FindClearSpaceForUnit = function(unit, position) unit.position = position end,
        Timers = { CreateTimer = function(_, callback) callback() end },
    })
    local hero = Unit(2, 300)
    local trigger = { activator = hero }
    environment.ArenaZoneOnEndTouch(nil)
    environment.ArenaZoneOnStartTouch(trigger)
    assert(not next(environment.Heroes_In_Arena_Zone), "trigger can fire before duel initialization")

    environment.Duel = { IsDuelOngoing = function() return true end }
    environment.ArenaZoneOnStartTouch(trigger)
    environment.ArenaZoneOnStartTouch(trigger)
    assert(environment.Heroes_In_Arena_Zone[hero], "trigger must add the hero to the arena")

    environment.ArenaZoneOnEndTouch(trigger)
    assert(not next(environment.Heroes_In_Arena_Zone) and not hero.interrupted)
    environment.Duel.SpawnPositions = { [2] = "duel spawn" }
    environment.ArenaZoneOnEndTouch(trigger)
    assert(hero.interrupted and hero.position == "duel spawn")
end

do
    local state, notices, sounds = 4, 0, 0
    local spawns, occupants, thinkers = {}, {}, {}
    local waypoint
    local spawner = {
        GetAbsOrigin = function() return 1000 end,
        SetContextThink = function(_, name, callback, delay)
            assert(delay == 3)
            thinkers[name] = callback
        end,
    }
    local start_raid = LoadScript("mechanics/spawn/raid.lua", {
        IsValidEntity = IsValidEntity,
        GameRules = { State_Get = function() return state end },
        DOTA_GAMERULES_STATE_GAME_IN_PROGRESS = 5,
        DOTA_GAMERULES_STATE_POST_GAME = 6,
        DOTA_TEAM_NEUTRALS = 4,
        Entities = {
            FindAllByClassnameWithin = function(_, classname, origin, radius)
                assert(classname == "npc_dota_creature" and origin == 1000 and radius == 1000)
                return occupants
            end,
            FindByName = function(_, _, name)
                assert(name == "camp_path_wp1")
                return waypoint
            end,
        },
        RandomFloat = function(min_value) return min_value end,
        RandomInt = function(min_value, max_value)
            assert(min_value <= max_value)
            return min_value
        end,
        RandomVector = function(magnitude) return magnitude end,
        CreateUnitByName = function(name, origin, _, _, _, team)
            assert(origin == 1000 and team == 4)
            local unit = {
                name = name,
                IsAlive = function() return true end,
                IsNeutralUnitType = function() return true end,
                SetRenderColor = function() end,
                SetInitialGoalEntity = function(self, target)
                    assert(target == waypoint)
                    self.goal = target
                end,
            }
            table.insert(spawns, unit)
            return unit
        end,
        EmitGlobalSound = function(sound)
            assert(sound == "angel_arena.zombiesiren")
            sounds = sounds + 1
        end,
        Notifications = {
            TopToAll = function(_, notice)
                assert(notice.duration == 5)
                notices = notices + 1
            end,
        },
    })
    local function WrapperEnvironment()
        return {
            thisEntity = spawner,
            require = function(name)
                assert(name == "mechanics/spawn/raid")
                return start_raid
            end,
        }
    end

    local zombie = WrapperEnvironment()
    zombie.MIN_SPAWN_ZOMBI, zombie.MAX_SPAWN_ZOMBI = 5, 20
    LoadScript("mechanics/spawn/zombie/zombie_spawner.lua", zombie)

    local boomber = WrapperEnvironment()
    boomber.MIN_SPAWN_boomber, boomber.MAX_SPAWN_boomber = 5, 10
    LoadScript("mechanics/spawn/boomber/boomber_spawner.lua", boomber)

    local zombie_think, boomber_think = thinkers.AngelArenaZombieRaid, thinkers.AngelArenaBoomberRaid
    assert(zombie_think() == 3 and boomber_think() == 3)
    state = 5
    assert(zombie_think() == 420 and boomber_think() == 550)

    waypoint = {}
    assert(zombie_think() == 420 and boomber_think() == 550 and #spawns == 0, "disabled raids do not spawn")
    zombie.ALLOW_ZOMBI = true
    waypoint = nil
    zombie_think()
    assert(#spawns == 0, "raids must find their waypoint before spawning")

    waypoint = {}
    assert(zombie_think() == 420 and #spawns == 5 and notices == 1 and sounds == 1)
    assert(spawns[1].name == "npc_dota_creature_basic_zombie" and spawns[1].goal == waypoint)
    occupants[1] = spawns[1]
    boomber.ALLOW_boomber = true
    assert(boomber_think() == 550 and #spawns == 5, "live occupants block another wave")
    occupants[1] = nil
    assert(boomber_think() == 550 and #spawns == 10 and notices == 2 and sounds == 1)
    assert(spawns[6].name == "npc_dota_creature_boomber" and spawns[6].goal == waypoint)
    assert(zombie_think() == 420 and #spawns == 15, "empty camps can spawn again")
    state = 6
    assert(zombie_think() == nil and boomber_think() == nil)
end

print("Map triggers passed lava, portals, duel boundaries, and raid spawn checks")
