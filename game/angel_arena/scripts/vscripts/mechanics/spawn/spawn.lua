
-- called when 1 hero enters an area

function SpawnArea( trigger )
	local areaName = trigger.caller:GetName()
	local caller = trigger.caller
	local activator = trigger.activator

	Timers:CreateTimer(1, function() 
		if caller:IsTouching(activator) and not IsAreaActive( areaName ) then
			SetAreaActive( areaName, true )
			
			print("\n Spawning units of "..areaName.. "\n")
			
			-- initialize the table to store all the creeps in the area
			InitializeCreepList( areaName )

			-- Spawn Initial Units
			local AreaInfoList = GameMode.SpawnInfoKV[ areaName ]
			DeepPrintTable(AreaInfoList)
			for k,v in pairs( AreaInfoList ) do
				--v.Name is the unit to spawn
				--v.MaxSpawn is how many
				print("Spawning",v.MaxSpawn,k)
				for i=1,v.MaxSpawn do
					-- Get a spawn location for a particular unit
					local spawnLocation = GetFreePositionInAreaFor(areaName,k)

					if spawnLocation ~= nil then	
						local unit = CreateUnitByName(k, spawnLocation:GetOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
						unit:SetForwardVector(RandomVector(5000)) -- variate facing of the unit
						unit.area = areaName -- set the area to respawn easier
						table.insert( GetAreaCreepList(areaName) ,unit) -- store the unit in the area table
					else
						print("No spawn location found")
					end
				end	
			end		
		end
	end)
end

-- called after all the heroes leave the area
function DespawnArea( trigger )
	print("DespawnArea called")

	local areaName = trigger.caller:GetName()
	local caller = trigger.caller
	local activator = trigger.activator

	if not caller:IsTouching(activator) and IsAreaActive( areaName ) then
		SetAreaActive( areaName, false )
		print("\n Despawning units of "..areaName.. " \n")

		local creepsDeleted = 0
		local creep_list = GetAreaCreepList( areaName )
		for _,creep in pairs(creep_list) do
			if IsValidEntity(creep) and creep:IsAlive() then 
				creep:RemoveSelf()
				creepsDeleted = creepsDeleted+1
			else print("Creep is not alive or has not respawned yet, ignoring.") end
		end
		print("Deleted ",creepsDeleted," creeps")
	end
end

-- called after a unit dies, starts a timer to spawn a new unit near the original spawn location
function RespawnCreep( event )
	local unit = event.caster
	if not unit or unit:IsNull() then return end

	local unit_area = unit.area
	local area_table = GameMode and GameMode.SpawnInfoKV and GameMode.SpawnInfoKV[unit_area]
	if not area_table then return end -- Camp-managed creeps have their own respawn timer.

	local unit_name = unit:GetUnitName()
	local unit_config = area_table[unit_name]
	local respawn_time = unit_config and tonumber(unit_config.RespawnTime)
	if not respawn_time then return end

	Timers:CreateTimer(respawn_time, function()
		if not IsAreaActive(unit_area) then return end
		local creep_list = GetAreaCreepList(unit_area)
		if not creep_list then return end
		local index = getIndex(creep_list, unit)
		if index < 1 then return end

		local position = GetFreePositionInAreaFor(unit_area, unit_name)
		if not position then return end
		local replacement = CreateUnitByName(unit_name, position:GetOrigin(), true, nil, nil, DOTA_TEAM_NEUTRALS)
		if not replacement then return end

		replacement:SetForwardVector(RandomVector(5000))
		replacement.area = unit_area
		creep_list[index] = replacement
	end)
end

------------------
-- Area Methods --
------------------

-- returns whether the area is activate or not, that is, there are still players inside the area
function IsAreaActive( areaName )
	if areaName == "DemonArea" then
		return GameMode.DemonAreaActive
	elseif areaName == "GoblinArea" then
		return GameMode.GoblinAreaActive
	elseif areaName == "BlackGoblinArea" then
		return GameMode.BlackGoblinAreaActive
	elseif areaName == "BanditArea" then
		return GameMode.BanditAreaActive
	elseif areaName == "SpiderArea" then
		return GameMode.BanditAreaActive
	elseif areaName == "SeaServantArea" then
		return GameMode.BanditAreaActive
	elseif areaName == "MountainWolfArea" then
		return GameMode.BanditAreaActive
	end
end

-- sets the area active or inactive
function SetAreaActive( areaName, bool )
	if areaName == "DemonArea" then
		GameMode.DemonAreaActive = bool
	elseif areaName == "GoblinArea" then
		GameMode.GoblinAreaActive = bool
	elseif areaName == "BlackGoblinArea" then
		GameMode.BlackGoblinAreaActive = bool
	elseif areaName == "BanditArea" then
		GameMode.BanditAreaActive = bool
	elseif areaName == "SpiderArea" then
		GameMode.BanditAreaActive = bool
	elseif areaName == "SeaServantArea" then
		GameMode.BanditAreaActive = bool
	elseif areaName == "MountainWolfArea" then
		GameMode.BanditAreaActive = bool
	end
end

function InitializeCreepList( areaName )
	if areaName == "DemonArea" then
		GameMode.DemonAreaCreeps = {}
	elseif areaName == "GoblinArea" then
		GameMode.GoblinAreaCreeps = {}
	elseif areaName == "BlackGoblinArea" then
		GameMode.BlackGoblinAreaCreeps = {}
	elseif areaName == "BanditArea" then
		GameMode.BanditAreaCreeps = {}
	elseif areaName == "SpiderArea" then
		GameMode.BanditAreaCreeps = {}
	elseif areaName == "SeaServantArea" then
		GameMode.BanditAreaCreeps = {}
	elseif areaName == "MountainWolfArea" then
		GameMode.BanditAreaCreeps = {}
	end
end

-- returns the list in which the creeps of the area are stored
function GetAreaCreepList( areaName )
	if areaName == "DemonArea" then
		return GameMode.DemonAreaCreeps
	elseif areaName == "GoblinArea" then
		return GameMode.GoblinAreaCreeps
	elseif areaName == "BlackGoblinArea" then
		return GameMode.BlackGoblinAreaCreeps
	elseif areaName == "BanditArea" then
		return GameMode.BanditAreaCreeps
	elseif areaName == "SpiderArea" then
		return GameMode.BanditAreaCreeps
	elseif areaName == "SeaServantArea" then
		return GameMode.BanditAreaCreeps
	elseif areaName == "MountainWolfArea" then
		return GameMode.BanditAreaCreeps
	end
end

-- Gives a new position from the available for that type of creature
function GetFreePositionInAreaFor( areaName, unitName )
	print("Finding free position in ",areaName," for ",unitName)
	if areaName == "DemonArea" then
		if unitName == "npc_demon_imp" then
			return GetEmptyPosition(GameMode.demon_imp_spawnLocations)
		elseif unitName == "npc_dota_necronomicon_archer_2" then
			return GetEmptyPosition(GameMode.demon_imp_spawnLocations)
		elseif unitName == "npc_dota_broodmother_spiderling" then
			return GetEmptyPosition(GameMode.demon_imp_spawnLocations)
		elseif unitName == "npc_forest_bear" then
			return GetEmptyPosition(GameMode.forest_bear_spawnLocations)
		end
	elseif areaName == "GoblinArea" then
		if unitName == "npc_goblin" then
			return GetEmptyPosition(GameMode.goblin_spawnLocations)
		elseif unitName == "npc_shaman" then
			return GetEmptyPosition(GameMode.shaman_spawnLocations)
		end
	elseif areaName == "BlackGoblinArea" then
		if unitName == "npc_black_goblin" then
			return GetEmptyPosition(GameMode.black_goblin_spawnLocations)
		elseif unitName == "npc_black_shaman" then
			return GetEmptyPosition(GameMode.black_shaman_spawnLocations)
		elseif unitName == "npc_ogre" then
			return GetEmptyPosition(GameMode.ogre_spawnLocations)
		end
	elseif areaName == "BanditArea" then
		if unitName == "npc_bandit" then
			return GetEmptyPosition(GameMode.bandit_spawnLocations)
		end
	elseif areaName == "SpiderArea" then
		if unitName == "npc_forest_spider" then
			return GetEmptyPosition(GameMode.forest_spider_spawnLocations)
		elseif unitName == "npc_forest_lurker" then
			return GetEmptyPosition(GameMode.forest_lurker_spawnLocations)
		elseif unitName == "npc_giant_spider" then
			return GetEmptyPosition(GameMode.giant_spider_spawnLocations)
		end
	elseif areaName == "SeaServantArea" then
		if unitName == "npc_sea_servant_huntsman" then
			return GetEmptyPosition(GameMode.sea_servant_huntsman_spawnLocations)
		elseif unitName == "npc_sea_servant_wavecaller" then
			return GetEmptyPosition(GameMode.sea_servant_wavecaller_spawnLocations)
		end
	elseif areaName == "MountainWolfArea" then
		if unitName == "npc_mountain_wolf" then
			return GetEmptyPosition(GameMode.mountain_wolf_spawnLocations)
		end
	end
end

function GetEmptyPosition( list )
	if not list or #list == 0 then return end
	print("Finding empty location")
	local counter = 0
	position = list[RandomInt(1, #list)]
	local nearbyUnits = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, position:GetOrigin(),nil, 100, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,	DOTA_UNIT_TARGET_FLAG_NONE,	FIND_ANY_ORDER,false)
	
	-- find until theres an empty position
	while #nearbyUnits > 0 do
		-- care of infinite loop
		if counter <= #list then
			counter = counter+1
			position = list[RandomInt(1, #list)]
			nearbyUnits = FindUnitsInRadius( DOTA_TEAM_NEUTRALS, position:GetOrigin(),nil, 100, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL,DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER,false)
			--print(nearbyUnits)
		else
			nearbyUnits = 0
			print("Couldn't find empty position, returning random instead")
		end
	end

	return position
end
