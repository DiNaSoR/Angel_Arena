--------------------------------------------------------------
-- Camp Setting
--------------------------------------------------------------
jihadicamp = {}
		do
			local campname = "camp_path_customspawn"
			jihadicamp[campname] =
			{
				NumberToSpawnJihadi = RandomInt(MIN_SPAWN_JIHADI,MAX_SPAWN_JIHADI),
				WaypointName = "camp_path_wp1"
			}
		end
--------------------------------------------------------------
-- Spawning individual camps
--------------------------------------------------------------
function GameMode:jihadicamp(campname)
	spawnunitsjihadi(campname)
end
--------------------------------------------------------------
-- Simple Custom Spawn
--------------------------------------------------------------
function spawnunitsjihadi(campname)
	local spawndata = jihadicamp[campname]
	local NumberToSpawnJihadi = spawndata.NumberToSpawnJihadi --How many to spawn
    local SpawnLocation = Entities:FindByName( nil, campname )
    local waypointlocation = Entities:FindByName ( nil, spawndata.WaypointName )
	if SpawnLocation == nil then
		return
	end

    local randomCreature = 
    	{
			"jihade"
	    }
	local r = randomCreature[RandomInt(1,#randomCreature)]
	--print(r)
    for i = 1, NumberToSpawnJihadi do
        local creature = CreateUnitByName( "npc_dota_creature_" ..r , SpawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
		creature:SetRenderColor(75,0,30)
        creature:SetInitialGoalEntity( waypointlocation )
    end
	
end