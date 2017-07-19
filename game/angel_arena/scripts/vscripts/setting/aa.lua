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
  	print("[Angel Arena] Hero spawned in game for first time")

	local player 	= PlayerResource:GetPlayer(hero:GetPlayerID())
	local pID 		= hero:GetPlayerOwnerID()
	local pOID 		= hero:GetPlayerID()
	local heroName 	= hero:GetUnitName()

	-- Initialize custom stats this is global values for spellpower/healingpower
	hero.spellPower = 0
	hero.healingPower = 0

	
	
	--[[ Initialize stat allocation
	hero.STR = 0
	hero.AGI = 0
	hero.INT = 0]]

	-- Give Item
	--local item = CreateItem("item_searing_flame_of_prometheus", hero, hero)
	--hero:AddItem(item)

	--print("give ability")
	--hero:AddAbility("crystal_maiden_brilliance_aura")
	--hero:FindAbilityByName("crystal_maiden_brilliance_aura"):SetLevel(1)

	--[[Abilities
	local abil1 = hero:GetAbilityByIndex(0)
	local abil2 = hero:GetAbilityByIndex(1)
	local abil3 = hero:GetAbilityByIndex(2)
	local abil4 = hero:GetAbilityByIndex(3)
	local abil5 = hero:GetAbilityByIndex(4)
	local abil6 = hero:GetAbilityByIndex(5)
	if abil1 ~= nil then abil1:SetLevel(1) end
	if abil2 ~= nil then abil2:SetLevel(1) end
	if abil3 ~= nil then abil3:SetLevel(1) end
	if abil4 ~= nil then abil4:SetLevel(1) end
	if abil5 ~= nil then abil5:SetLevel(1) end
	if abil6 ~= nil then abil6:SetLevel(1) end
	--hero:AddAbility("example_ability")

	-- Give 2 extra stat points to spend
	hero:SetAbilityPoints(3)]]	
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
	--[[ initialize modules
	InitModule(PointsManager)
	InitModule(Gold)
	InitModule(BlinkBlock)
	InitModule(ZoneControl)
	InitModule(AbilityLevels)
	InitModule(HeroProgression)
	InitModule(SellBlackList)
	InitModule(Glyph)
	InitModule(BubbleOrbFilter)
	InitModule(ReactiveFilter)
	InitModule(NGP)
	InitModule(Doors)
	InitModule(HeroKillGold)]]

	GameMode:PostLoadPrecache()
	GameMode:OnAllPlayersLoaded()
end

--------------------------------------------------------------
--This function is called once and only once when the game completely begins (about 0:00 on the clock).  At this point,
--gold will begin to go up in ticks if configured, creeps will spawn, towers will become damageable etc.  This function
--is useful for starting any game logic timers/thinkers, beginning the first round, etc.
--------------------------------------------------------------
function GameMode:OnGameInProgress()
	print("[Angel Arena] The game has officially begun")

	--This code will calculate how many players in each team adds them and muli it by 10 to give final score to win the game.
	PLAYER_COUNT_GOODGUYS 		= PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_GOODGUYS)
	PLAYER_COUNT_BADGUYS 		= PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_BADGUYS)
	KILLS_TO_END_GAME_FOR_TEAM 	= math.floor(PLAYER_COUNT_GOODGUYS + PLAYER_COUNT_BADGUYS) * 10

	-- initialize modules
	InitModule(CreepPower)
	InitModule(CreepCamps)
	InitModule(CreepItemDrop)
	--[[InitModule(CaveHandler)
	InitModule(Duels)
	InitModule(BossSpawner)
	InitModule(BottleCounter)
	InitModule(DuelRunes)
	InitModule(FinalDuel)
	InitModule(PlayerConnection)]]
  
	welcomemsg()
	--firedueltimer()
end
--------------------------------------------------------------
-- Modules
--------------------------------------------------------------
function InitModule(myModule)
  if myModule ~= nil then
    myModule:Init()
  end
end
-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later