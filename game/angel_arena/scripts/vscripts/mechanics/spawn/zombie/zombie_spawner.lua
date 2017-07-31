--------------------------------------------------------------
-- Camp Counter and Vacated
--------------------------------------------------------------
local camp_counter = 0 
local vacated_time = 0

--------------------------------------------------------------
-- Think that checks if neutral creeps are close to spawner entities
--------------------------------------------------------------
function OnTriggerThink_Timer()
	camp_counter = 0
	local count = Entities:FindAllByClassnameWithin( "npc_dota_creature", thisEntity:GetAbsOrigin(), 1000 )
	for _,entity in pairs(count) do
		if entity:IsNeutralUnitType() or entity:IsCreature() then
			camp_counter = camp_counter + 1
		end
		--print(entity:GetClassname())
	end
	if camp_counter == 0 then
		if vacated_time == 0 then
			vacated_time = Time()
		end
		--print("camp_counter is"..camp_counter)
	else
		vacated_time = 0
	end
	if vacated_time > 0 and Time() > vacated_time + 1 and ALLOW_ZOMBI then
		--print("vacated_time is"..vacated_time)
		--print("Time to respawn")
		EmitGlobalSound("angel_arena.zombiesiren")
		apocalypse()
		GameRules:GetGameModeEntity().GameMode:spawncamp(thisEntity:GetName())
		ALLOW_ZOMBI = false
		print("[Angel Arena] Zombie Event Off")
		else
		ALLOW_ZOMBI = true
		print("[Angel Arena] Zombie Event On")
	end
	return 420
end
--------------------------------------------------------------
-- Thinker
--------------------------------------------------------------
thisEntity:SetThink( "OnTriggerThink_Timer", 3 )
--------------------------------------------------------------
-- Timer
--------------------------------------------------------------
function timerzombie()
end