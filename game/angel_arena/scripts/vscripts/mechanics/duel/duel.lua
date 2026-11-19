--------------------------------------------------------------
--	Duel Globals
--------------------------------------------------------------
DUEL_SETTINGS = {
	OpeningDelay = 300,
	DelaysFromLast = {
		[0] = 300,
		[30] = 240,
		[60] = 180,
	},
	DurationBase = 60,
	DurationForPlayer = 20,
	Duel1x1Duration = 90,
	WinGold_Base = 100,
	WinGold_PerDuel = 400
}

DOTA_DUEL_STATUS_NONE = 0
DOTA_DUEL_STATUS_WATING = 1
DOTA_DUEL_STATUS_IN_PROGRESS = 2
local DOTA_DUEL_STATUS_FINISHED = 3

local duelPhases = {
	[DOTA_DUEL_STATUS_WATING] = "waiting",
	[DOTA_DUEL_STATUS_IN_PROGRESS] = "active",
	[DOTA_DUEL_STATUS_FINISHED] = "finished",
}
--------------------------------------------------------------
--	Duel Class
--------------------------------------------------------------
if Duel == nil then
	_G.Duel = class({})
	Duel.TimeUntilDuel = 0
	Duel.DuelTimerEndTime = 0
	Duel.DuelStatus = DOTA_DUEL_STATUS_NONE
	Duel.EntIndexer = {}
	Duel.TimesTeamWins = {}
	Duel.AnnouncerCountdownCooldowns = {}
	Duel.DuelCounter = 0
	Duel.PreparedUnits = {}
	Duel.DuelBox1 = Vector(0,0,0)
	Duel.DuelBox2 = Vector(0,0,0)
end
--------------------------------------------------------------
--	Duel Timer from Globals table
--------------------------------------------------------------
function Duel:SetDuelTimer(duration)
	Duel.DuelTimerEndTime = duration and GameRules:GetGameTime() + duration or 0
	PlayerTables:SetTableValue("arena", "duel_end_time", Duel.DuelTimerEndTime)
	CustomNetTables:SetTableValue("arena_match", "duel", {
		phase = duelPhases[Duel.DuelStatus],
		deadline = Duel.DuelTimerEndTime,
	})
end
--------------------------------------------------------------
--	Duel Timer for Global Timer
--	Create Physics Collider
--------------------------------------------------------------
function Duel:CreateGlobalTimer()
	local corner1 = Entities:FindByName(nil, "target_mark_arena_blocker_1")
	local corner2 = Entities:FindByName(nil, "target_mark_arena_blocker_2")
	local angels = Entities:FindByName(nil, "target_mark_arena_team" .. DOTA_TEAM_GOODGUYS)
	local demons = Entities:FindByName(nil, "target_mark_arena_team" .. DOTA_TEAM_BADGUYS)
	if not (corner1 and corner2 and angels and demons) then
		print("[Angel Arena] Duel requires two arena corners and both team destinations")
		return
	end

	Duel.SpawnPositions = {
		[DOTA_TEAM_GOODGUYS] = angels:GetAbsOrigin(),
		[DOTA_TEAM_BADGUYS] = demons:GetAbsOrigin(),
	}
	Duel.DuelBox1 = corner1:GetAbsOrigin()
	Duel.DuelBox2 = corner2:GetAbsOrigin()
	local collider = Physics:AddCollider("collider_box_blocker_arena", Physics:ColliderFromProfile("boxblocker"))
	collider.box = CreateSimpleBox(Duel.DuelBox2, Duel.DuelBox1)
	collider.findClearSpace = true
	collider.test = function(_, unit)
		if not IsPhysicsUnit(unit) and unit.IsConsideredHero and unit:IsConsideredHero() then
			Physics:Unit(unit)
		end
		return IsPhysicsUnit(unit) and Duel.DuelStatus == DOTA_DUEL_STATUS_WATING and not unit.OnDuel
	end

	Duel.DuelStatus = DOTA_DUEL_STATUS_WATING
	Duel:SetDuelTimer(DUEL_SETTINGS.OpeningDelay)
	Timers:CreateTimer(function()
		return Duel:GlobalThink()
	end)
end
--------------------------------------------------------------
--	Duel Global Thinker
--	Announce duel Timer 10 sec
--	Start and End trigger for duel
--------------------------------------------------------------
function Duel:GlobalThink()
	if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		Duel:FinishMatch()
	end
	if Duel.DuelStatus == DOTA_DUEL_STATUS_FINISHED then
		return
	end

	local now = GameRules:GetGameTime()
	for i = 1, 10 do
		local diff = now + i - Duel.DuelTimerEndTime
		if diff < 0.3 and diff > 0 and (not Duel.AnnouncerCountdownCooldowns[i] or now > Duel.AnnouncerCountdownCooldowns[i]) then
			Duel.AnnouncerCountdownCooldowns[i] = now + 1
			if i < 10 then i = "0" .. i end
			EmitAnnouncerSound("announcer_ann_custom_countdown_" .. i)
		end
	end
	if now >= Duel.DuelTimerEndTime then
		if Duel.DuelStatus == DOTA_DUEL_STATUS_IN_PROGRESS then
			Duel:EndDuel()
		elseif Duel.DuelStatus == DOTA_DUEL_STATUS_WATING then
			Duel:StartDuel()
		end
	end
	return 0.2
end
--------------------------------------------------------------
--	Statring the Duel find heroes and count them
--	Teleport them to mark points in Map
--------------------------------------------------------------
local function DuelUnitsForHero(hero)
	local units = {hero}
	if hero:GetUnitName() == "npc_dota_hero_meepo" then
		for _, unit in ipairs(HeroList:GetAllHeroes()) do
			if unit:IsClone() and unit:GetCloneSource() == hero then
				units[#units + 1] = unit
			end
		end
	end
	return units
end

function Duel:StartDuel()
	local heroesByTeam = {
		[DOTA_TEAM_GOODGUYS] = {},
		[DOTA_TEAM_BADGUYS] = {},
	}
	local visitors = {}
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(playerID) then
			local team = PlayerResource:GetTeam(playerID)
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)
			if heroesByTeam[team] and IsValidEntity(hero) then
				if GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED then
					table.insert(heroesByTeam[team], hero)
				else
					visitors[#visitors + 1] = hero
				end
			end
		end
	end

	local fightersPerTeam = math.min(#heroesByTeam[DOTA_TEAM_GOODGUYS], #heroesByTeam[DOTA_TEAM_BADGUYS])
	if fightersPerTeam == 0 then
		Duel:EndDuelLogic(false, true)
		Notifications:TopToAll({text = "#duel_no_heroes", duration = 5})
		return
	end

	Duel.heroes_teams_for_duel = {}
	Duel.PreparedUnits = {}
	Duel.IsFirstDuel = Duel.DuelCounter == 0
	Duel.DuelStatus = DOTA_DUEL_STATUS_IN_PROGRESS
	Duel:SetDuelTimer(DUEL_SETTINGS.DurationBase + DUEL_SETTINGS.DurationForPlayer * fightersPerTeam)

	for team, heroes in pairs(heroesByTeam) do
		table.shuffle(heroes)
		local fighters = {}
		Duel.heroes_teams_for_duel[team] = fighters
		for index, hero in ipairs(heroes) do
			if index <= fightersPerTeam then
				fighters[#fighters + 1] = hero
				hero.OnDuel = true
				if not hero:IsAlive() then
					hero:RespawnHero(false, false)
				end

				for _, unit in ipairs(DuelUnitsForHero(hero)) do
					if unit:IsAlive() then
						unit.OnDuel = true
						unit.ArenaBeforeTpLocation = unit:GetAbsOrigin()
						Duel:FillPreduelUnitData(unit)
						local health = unit:GetMaxHealth()
						unit:SetHealth(unit:HasAbility("shinobu_vampire_blood") and health * 0.5 or health)
						unit:SetMana(unit:GetMaxMana())
						if unit.PocketItem then
							UTIL_Remove(unit.PocketItem)
						end
						ProjectileManager:ProjectileDodge(unit)
						unit:FindClearSpaceForUnitAndSetCamera(Duel.SpawnPositions[team])
					end
				end
			else
				visitors[#visitors + 1] = hero
			end
		end
	end
	for _, hero in ipairs(visitors) do
		Duel:SetUpVisitorsForHero(hero)
	end

	EmitAnnouncerSound("announcer_ann_custom_mode_20")
	EmitGlobalSound("angel_arena.duelstartmusic")
	CustomGameEventManager:Send_ServerToAllClients("create_custom_toast", {
		type = "generic",
		text = "#custom_toast_DuelStarted",
		variables = {["{duel_index}"] = Duel.DuelCounter + 1},
	})
end
--------------------------------------------------------------
--	Duel Endding
--------------------------------------------------------------
function Duel:EndDuel()
	local winner = Duel:GetWinner()
	if winner then
		if winner == DOTA_TEAM_GOODGUYS then
			EmitAnnouncerSound("announcer_announcer_victory_rad")
		elseif winner == DOTA_TEAM_BADGUYS then
			EmitAnnouncerSound("announcer_announcer_victory_dire")
		end
		Notifications:TopToAll({text="#duel_over_winner_p1", duration=6})
		Notifications:TopToAll(CreateTeamNotificationSettings(winner, false))
		Notifications:TopToAll({text="#duel_over_winner_p2", continue=true})
		local goldAmount = DUEL_SETTINGS.WinGold_Base + (DUEL_SETTINGS.WinGold_PerDuel * Duel.DuelCounter)
		local g1,g2 = CreateGoldNotificationSettings(goldAmount)
		Notifications:TopToAll(g1)
		Notifications:TopToAll(g2)
		for _,t in pairs(Duel.heroes_teams_for_duel) do
			for _,v in ipairs(t) do
				if IsValidEntity(v) then
					v:ModifyPlayerStat("Duels_Played", 1)
				end
			end
		end
		for _,v in ipairs(Duel.heroes_teams_for_duel[winner]) do
			if IsValidEntity(v) then
				Gold:ModifyGold(v:GetPlayerOwnerID(), goldAmount)
				v:ModifyPlayerStat("Duels_Won", 1)
			end
		end
		Duel.TimesTeamWins[winner] = (Duel.TimesTeamWins[winner] or 0) + 1
	else
		Notifications:TopToAll({text="#duel_over_winner_none", duration=5})
	end
	Duel.DuelCounter = Duel.DuelCounter + 1
	Duel:EndDuelLogic(true, true)
end
--------------------------------------------------------------
--	Duel Getting who is the winnder
--------------------------------------------------------------
function Duel:GetWinner()
	local teams = {}
	for team,tab in pairs(Duel.heroes_teams_for_duel) do
		for _,unit in pairs(tab) do
			if IsValidEntity(unit) and (unit:IsAlive() or unit:IsReincarnating()) then
				if not table.contains(teams, team) and unit.OnDuel then
					table.insert(teams, team)
				end
			end
		end
	end
	return #teams == 1 and teams[1] or nil
end
--------------------------------------------------------------
--	Duel setup the visitor
--------------------------------------------------------------
function Duel:SetUpVisitor(unit)
	local fountain = unit:GetUnitName() == FORCE_PICKED_HERO and FindFountain(unit:GetTeamNumber())
	unit.ArenaBeforeTpLocation = unit.ArenaBeforeTpLocation or (fountain and fountain:GetAbsOrigin()) or unit:GetAbsOrigin()
	Duel:FillPreduelUnitData(unit)
	ProjectileManager:ProjectileDodge(unit)
	unit:AddNewModifier(unit, nil, "modifier_hero_out_of_game", {})
end

function Duel:SetUpVisitorsForHero(hero)
	if not Duel:IsDuelOngoing() or not hero or not IsValidEntity(hero) or hero.OnDuel then
		return
	end
	for _, unit in ipairs(DuelUnitsForHero(hero)) do
		if unit:IsAlive() and not unit:HasModifier("modifier_hero_out_of_game") then
			Duel:SetUpVisitor(unit)
		end
	end
end
--------------------------------------------------------------
--	Endding Duel Logic ???
--------------------------------------------------------------
function Duel:EndDuelLogic(restoreUnits, updateTimer)
	Duel.EntIndexer = {}
	Duel.DuelStatus = updateTimer and DOTA_DUEL_STATUS_WATING or DOTA_DUEL_STATUS_FINISHED
	Duel.heroes_teams_for_duel = {}
	if restoreUnits then
		for unit in pairs(Duel.PreparedUnits) do
			if IsValidEntity(unit) then
				Duel:EndDuelForUnit(unit)
			end
		end
	end
	Duel.PreparedUnits = {}
	Heroes_In_Arena_Zone = {}

	if restoreUnits or updateTimer then
		Events:Emit("Duel/end")
	end
	if updateTimer then
		local minute = math.max(0, GetDOTATimeInMinutesFull())
		local delay = table.nearestOrLowerKey(DUEL_SETTINGS.DelaysFromLast, minute)
		Timers:CreateTimer(2, function()
			EmitAnnouncerSound("announcer_ann_custom_timer_0" .. delay / 60)
		end)
		Duel:SetDuelTimer(delay)
	else
		Duel:SetDuelTimer()
	end
end

function Duel:FinishMatch()
	if Duel.DuelStatus ~= DOTA_DUEL_STATUS_FINISHED then
		Duel:EndDuelLogic(Duel:IsDuelOngoing(), false)
	end
end
--------------------------------------------------------------
--	Endding Duel For Units
--	Remove hero out of game modifier
--	Refresh mana/hp/abilities
--	Teleport out of arena for last position
--------------------------------------------------------------
function Duel:EndDuelForUnit(unit)
	unit:RemoveModifierByName("modifier_hero_out_of_game")
	local previous = unit.StatusBeforeArena
	unit.StatusBeforeArena = nil
	local matchFinished = Duel.DuelStatus == DOTA_DUEL_STATUS_FINISHED
	if previous and unit:IsAlive() then
		local function RestoreStats()
			if not IsValidEntity(unit) or not unit:IsAlive() then
				return
			end
			unit:SetHealth(previous.Health)
			unit:SetMana(previous.Mana)
			for ability, cooldown in pairs(previous.AbilityCooldowns) do
				if IsValidEntity(ability) and unit:HasAbility(ability:GetAbilityName()) then
					ability:EndCooldown()
					ability:StartCooldown(cooldown)
				end
			end
			for item, cooldown in pairs(previous.ItemCooldowns) do
				if IsValidEntity(item) then
					item:EndCooldown()
					item:StartCooldown(cooldown)
				end
			end
		end
		if matchFinished then
			RestoreStats()
		else
			Timers:CreateTimer(0.1, RestoreStats)
		end
	end

	local position = unit.ArenaBeforeTpLocation
	if not position then
		local fountain = FindFountain(unit:GetTeamNumber())
		position = fountain and fountain:GetAbsOrigin()
	end
	if position and unit:IsAlive() then
		ProjectileManager:ProjectileDodge(unit)
		if matchFinished then
			FindClearSpaceForUnit(unit, position, true)
		else
			unit:FindClearSpaceForUnitAndSetCamera(position)
		end
	elseif position and not matchFinished and unit:IsReincarnating() then
		Timers:CreateTimer(function()
			if not IsValidEntity(unit) or Duel.DuelStatus == DOTA_DUEL_STATUS_FINISHED or unit.OnDuel then
				return
			end
			if unit:IsAlive() then
				ProjectileManager:ProjectileDodge(unit)
				unit:FindClearSpaceForUnitAndSetCamera(position)
			elseif unit:IsReincarnating() then
				return 0.2
			end
		end)
	end
	unit.OnDuel = nil
	unit.ArenaBeforeTpLocation = nil
end
--------------------------------------------------------------
--	Pre Duel Units Data
--	Reset Mana/hp/abilities
--	Check if we can reset item cooldown
--------------------------------------------------------------
function Duel:FillPreduelUnitData(unit)
	if Duel.PreparedUnits[unit] then
		return
	end
	Duel.PreparedUnits[unit] = true
	unit.StatusBeforeArena = {
		Health = unit:GetHealth(),
		Mana = unit:GetMana(),
		AbilityCooldowns = {},
		ItemCooldowns = {},
	}
	for i = 0, unit:GetAbilityCount() - 1 do
		local ability = unit:GetAbilityByIndex(i)
		if ability and ability:GetCooldown(ability:GetLevel()) > 0 then
			unit.StatusBeforeArena.AbilityCooldowns[ability] = ability:GetCooldownTimeRemaining()
			ability:EndCooldown()
		end
	end
	for i = 0, 5 do
		local item = unit:GetItemInSlot(i)
		if item and item:GetAbilityName() ~= "item_aegis_arena" then
			unit.StatusBeforeArena.ItemCooldowns[item] = item:GetCooldownTimeRemaining()
			item:EndCooldown()
		end
	end
end
--------------------------------------------------------------
--	Check if Duel On Going status
--------------------------------------------------------------
function Duel:IsDuelOngoing()
	return Duel.DuelStatus == DOTA_DUEL_STATUS_IN_PROGRESS
end
