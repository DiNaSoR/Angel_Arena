local ArenaScore = require('mechanics/match/score')

--------------------------------------------------------------
-- Angel Arena GameMode Class
--------------------------------------------------------------
	GameMode = class({})
	print("[Angel Arena] ALPHA-"..AA_VERSION)
--------------------------------------------------------------
-- PostLoadPrecache
-- Triggered in Events.lua in Events.lua inside internal
--------------------------------------------------------------
function GameMode:PostLoadPrecache()
	print("[Angel Arena] Performing Post-Load precache")
end
--------------------------------------------------------------
-- BGM - CHECK GameRules.CURRENT_SOUNDTRACK Value if possible to go to global
-- Need to trigger GameMode:SoundThink() check it first
-- Use this in Game in Prograss GameRules:GetGameModeEntity():SetThink("SoundThink", self)
--------------------------------------------------------------
function GameMode:SoundThink()
	print("[Angel Arena] Music Box Started")
	local soundTrack = RandomInt(1, 6)
	local soundString = nil

	if GameRules.CURRENT_SOUNDTRACK == 0 then
		soundTrack = 0
		soundString = "valve_dota_001.music.ui_world_map" --first track
		EmitGlobalSound(soundString)
		soundTimer = 170
		GameRules.CURRENT_SOUNDTRACK = 1
	else
		if soundTrack == 1 then
			if RollPercentage(80) then 
				soundString = "valve_dota_001.music.ui_world_map" --"Warchasers.HumanX1"
				EmitGlobalSound(soundString)
				soundTimer = 170 --284
			else --rare
				--soundString = "Warchasers.PowerOfTheHorde"
				--EmitGlobalSound(soundString)
				--soundTimer = 281
			end
		elseif soundTrack == 2 then
			soundString = "valve_dota_001.music.laning_03_layer_01"
			EmitGlobalSound(soundString)
			soundTimer = 100
		--elseif soundTrack == 3 then
			--soundString = "Warchasers.ti4_laning_03_layer_01"
			--EmitGlobalSound(soundString)
			--soundTimer = 113
		elseif soundTrack == 4 then
			soundString = "valve_dota_001.music.laning_01_layer_01"
			EmitGlobalSound(soundString)
			soundTimer = 161
		elseif soundTrack == 5 then
			soundString = "valve_dota_001.music.ui_main"
			EmitGlobalSound(soundString)
			soundTimer = 111
		elseif soundTrack == 6 then
			soundString = "valve_dota_001.music.ui_world_map"
			EmitGlobalSound(soundString)
			soundTimer = 170
		else 
			return 5
		end
		GameRules.CURRENT_SOUNDTRACK = soundTrack
	end

	print("Playing soundtrack number " .. soundTrack .. " named " .. soundString)
	return soundTimer
end
--------------------------------------------------------------
--OnFirstPlayerLoaded
--This function is called once and only once as soon as the first player (almost certain to be the server in local lobbies) loads in.
--------------------------------------------------------------
function GameMode:OnFirstPlayerLoaded()
	print("[Angel Arena] First Player has loaded")
end
--------------------------------------------------------------
--This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
--It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
--Called from Event in internal
--------------------------------------------------------------
function GameMode:OnAllPlayersLoaded()
	print("[Angel Arena] All players loaded")
end
--------------------------------------------------------------
--This function is called once and only once for every player when they spawn into the game for the first time.  It is also called
--if the player's hero is replaced with a new hero for any reason.  This function is useful for initializing heroes, such as adding
--levels, changing the starting gold, removing/adding abilities, adding physics, etc.
--The hero parameter is the hero entity that just spawned in
--------------------------------------------------------------
function GameMode:OnHeroInGame(hero)
    hero.spellPower = 0
    hero.healingPower = 0
end
--------------------------------------------------------------
--On Strategy Time
--Called from GameMode:OnGameRulesStateChange(keys
--------------------------------------------------------------
function GameMode:OnStrategyTime()
	print ('[Angel Arena] Now Strategy Time')
end
--------------------------------------------------------------
--On Pre Game
--------------------------------------------------------------
function GameMode:OnPreGame()
    if self.preGameStarted then
        return
    end
    self.preGameStarted = true

    InitModule(Gold)

    PLAYER_COUNT_GOODGUYS = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
    PLAYER_COUNT_BADGUYS = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)
    if KILLS_TO_END_GAME_FOR_TEAM <= 0 then
        KILLS_TO_END_GAME_FOR_TEAM = math.max(1, PLAYER_COUNT_GOODGUYS + PLAYER_COUNT_BADGUYS) * 10
    end
    ArenaScore.SetPhase(self, 'pre_game')

    self:PostLoadPrecache()
    self:OnAllPlayersLoaded()
end

function GameMode:OnGameInProgress()
    if self.gameInProgress then
        return
    end
    self:OnPreGame()
    self.gameInProgress = true
    ArenaScore.SetPhase(self, 'in_progress')

    print("[Angel Arena] The game has officially begun")
    -- Biome camps and bosses (arena/index.lua). They replace the CreepCamps spawner in mechanics/camps.
    InitModule(ArenaWorld)
    welcomemsg()
    Duel:CreateGlobalTimer()
end
--------------------------------------------------------------
-- Modules
--------------------------------------------------------------
function InitModule(myModule)
  if myModule ~= nil then
    myModule:Init()
  end
end
