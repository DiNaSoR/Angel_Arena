--------------------------------------------------------------
-- Camp Setting
--------------------------------------------------------------
boombercamp = {}
		do
			local campname = "camp_path_customspawn"
			boombercamp[campname] =
			{
				NumberToSpawnboomber = RandomInt(MIN_SPAWN_boomber,MAX_SPAWN_boomber),
				WaypointName = "camp_path_wp1"
			}
		end
--------------------------------------------------------------
-- Spawning individual camps
--------------------------------------------------------------
function GameMode:boombercamp(campname)
	spawnunitsboomber(campname)
end
--------------------------------------------------------------
-- Simple Custom Spawn
--------------------------------------------------------------
function spawnunitsboomber(campname)
	local spawndata = boombercamp[campname]
	local NumberToSpawnboomber = spawndata.NumberToSpawnboomber --How many to spawn
    local SpawnLocation = Entities:FindByName( nil, campname )
    local waypointlocation = Entities:FindByName ( nil, spawndata.WaypointName )
	if SpawnLocation == nil then
		return
	end

    local randomCreature = 
    	{
			"boomber"
	    }
	local r = randomCreature[RandomInt(1,#randomCreature)]
	--print(r)
    for i = 1, NumberToSpawnboomber do
        local creature = CreateUnitByName( "npc_dota_creature_" ..r , SpawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
		creature:SetRenderColor(75,0,30)
        creature:SetInitialGoalEntity( waypointlocation )
    end
	
end