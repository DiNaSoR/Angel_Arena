--------------------------------------------------------------
-- Camp Counter and Vacated
--------------------------------------------------------------
local camp_counter = 0 
local vacated_time = 0

--------------------------------------------------------------
-- Think that checks if neutral creeps are close to spawner entities
--------------------------------------------------------------
function boomber_thinker()
	camp_counter = 0
	local count = Entities:FindAllByClassnameWithin( "npc_dota_creature", thisEntity:GetAbsOrigin(), 1000 )
	for _,entity in pairs(count) do
		if entity:IsNeutralUnitType() or entity:IsCreature() then
			camp_counter = camp_counter + 1
		end
	end
	if camp_counter == 0 then
		if vacated_time == 0 then
			vacated_time = Time()
		end
	else
		vacated_time = 0
	end
	if vacated_time > 0 and Time() > vacated_time + 1 and ALLOW_boomber then
		--EmitGlobalSound("angel_arena.allahremix")
		boomberstsmsg()
		GameRules:GetGameModeEntity().GameMode:boombercamp(thisEntity:GetName())
		ALLOW_boomber = false
		print("[Angel Arena] boomber Event Off")
		else
		ALLOW_boomber = true
		print("[Angel Arena] boomber Event On")
	end
	return 550
end
--------------------------------------------------------------
-- Thinker
--------------------------------------------------------------
thisEntity:SetThink( "boomber_thinker", 3 )
--------------------------------------------------------------
-- Timer
--------------------------------------------------------------
function boombertimer()
end