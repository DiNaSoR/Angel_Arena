local function GetTriggerUnit(trigger)
	local unit = trigger and trigger.activator
	if IsValidEntity(unit) and unit:IsBaseNPC() then
		return unit
	end
end

local function IsDuelOngoing()
	return Duel and Duel.IsDuelOngoing and Duel:IsDuelOngoing()
end

function ArenaZoneOnStartTouch(trigger)
	local unit = GetTriggerUnit(trigger)
	if unit and Heroes_In_Arena_Zone and IsDuelOngoing() then
		Heroes_In_Arena_Zone[unit] = true
	end
end

function ArenaZoneOnEndTouch(trigger)
	local unit = GetTriggerUnit(trigger)
	if not unit or not Heroes_In_Arena_Zone then
		return
	end
	Heroes_In_Arena_Zone[unit] = nil
	if not IsDuelOngoing() or not unit.OnDuel then
		return
	end
	if unit.IsWukongsSummon and unit:IsWukongsSummon() then
		return
	end

	Timers:CreateTimer(function()
		if not IsValidEntity(unit) or not unit:IsAlive() or not IsDuelOngoing()
			or not unit.OnDuel or Heroes_In_Arena_Zone[unit] then
			return
		end
		local destination = Duel.SpawnPositions and Duel.SpawnPositions[unit:GetTeamNumber()]
		if destination then
			unit:InterruptMotionControllers(true)
			FindClearSpaceForUnit(unit, destination, false)
			if unit:HasModifier("modifier_spirits_spirit_aghanims") then
				return 1 / 30
			end
		end
	end)
end

local OUT_OF_GAME_UNITS = {
	[""] = true,
	npc_dota_thinker = true,
	npc_dummy_unit = true,
	npc_dota_looping_sound = true,
	npc_dota_invisible_vision_source = true,
}

function FountainOnStartTouch(trigger, team)
	local unit = GetTriggerUnit(trigger)
	if not unit then
		return
	end
	if unit:GetTeamNumber() == team then
		unit:AddNewModifier(unit, nil, "modifier_fountain_aura_arena", {})
	elseif not unit:IsBoss() and not OUT_OF_GAME_UNITS[unit:GetUnitName()] then
		unit:AddNewModifier(unit, nil, "modifier_fountain_aura_enemy", {team = team})
	end
end

function Fountain2OnStartTouch(trigger)
	FountainOnStartTouch(trigger, DOTA_TEAM_GOODGUYS)
end

function Fountain3OnStartTouch(trigger)
	FountainOnStartTouch(trigger, DOTA_TEAM_BADGUYS)
end

function Fountain6OnStartTouch(trigger)
	FountainOnStartTouch(trigger, DOTA_TEAM_CUSTOM_1)
end

function Fountain7OnStartTouch(trigger)
	FountainOnStartTouch(trigger, DOTA_TEAM_CUSTOM_2)
end

local function FountainOnEndTouch(trigger)
	local unit = GetTriggerUnit(trigger)
	if unit then
		unit:RemoveModifierByName("modifier_fountain_aura_arena")
		unit:RemoveModifierByName("modifier_fountain_aura_enemy")
	end
end

Fountain2OnEndTouch = FountainOnEndTouch
Fountain3OnEndTouch = FountainOnEndTouch
Fountain6OnEndTouch = FountainOnEndTouch
Fountain7OnEndTouch = FountainOnEndTouch
