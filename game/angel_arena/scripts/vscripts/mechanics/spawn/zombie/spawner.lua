--------------------------------------------------------------
-- Camp Setting
--------------------------------------------------------------
spawncamps = {}
	do
		local campname = "camp_path_customspawn"
		spawncamps[campname] =
		{
			NumberToSpawn = RandomInt(MIN_SPAWN_ZOMBI,MAX_SPAWN_ZOMBI),
			WaypointName = "camp_path_wp1"
		}
	end
--------------------------------------------------------------
-- Spawning individual camps
--------------------------------------------------------------
function GameMode:spawncamp(campname)
	spawnunits(campname)
	
end
--------------------------------------------------------------
-- Simple Custom Spawn
--------------------------------------------------------------
function spawnunits(campname)
	local spawndata = spawncamps[campname]
	local NumberToSpawn = spawndata.NumberToSpawn --How many to spawn
    local SpawnLocation = Entities:FindByName( nil, campname )
    local waypointlocation = Entities:FindByName ( nil, spawndata.WaypointName )
	if SpawnLocation == nil then
		return
	end

    local randomCreature = 
    	{
			"basic_zombie"
	    }
	local r = randomCreature[RandomInt(1,#randomCreature)]
	--print(r)
    for i = 1, NumberToSpawn do
        local creature = CreateUnitByName( "npc_dota_creature_" ..r , SpawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
        creature:SetRenderColor(75,0,30)
        creature:SetInitialGoalEntity( waypointlocation )
    end
	
end