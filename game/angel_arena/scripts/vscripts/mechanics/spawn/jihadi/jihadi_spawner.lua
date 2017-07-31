--------------------------------------------------------------
-- Camp Counter and Vacated
--------------------------------------------------------------
local camp_counter = 0 
local vacated_time = 0

--------------------------------------------------------------
-- Think that checks if neutral creeps are close to spawner entities
--------------------------------------------------------------
function jihadi_thinker()
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
	if vacated_time > 0 and Time() > vacated_time + 1 and ALLOW_JIHADI then
		EmitGlobalSound("angel_arena.allahremix")
		jihadistsmsg()
		GameRules:GetGameModeEntity().GameMode:jihadicamp(thisEntity:GetName())
		ALLOW_JIHADI = false
		print("[Angel Arena] Jihadi Event Off")
		else
		ALLOW_JIHADI = true
		print("[Angel Arena] Jihadi Event On")
	end
	return 550
end
--------------------------------------------------------------
-- Thinker
--------------------------------------------------------------
thisEntity:SetThink( "jihadi_thinker", 3 )
--------------------------------------------------------------
-- Timer
--------------------------------------------------------------
function jihaditimer()
end