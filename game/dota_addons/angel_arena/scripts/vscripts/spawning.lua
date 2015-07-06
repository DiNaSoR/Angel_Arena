require('timers')
if 		spawnbases == nil then
        spawnbases = class({})
end

NUMBERTOSPAWN 			= 4

--//--------------------------------------------------------------------------------------
--//	Precache
--//--------------------------------------------------------------------------------------
function Precache( context )
        --Cache the Gnoll Assassin model
        PrecacheUnitByNameSync( "npc_dota_npc_base", context )
        PrecacheModel( "npc_dota_npc_base", context )
end

--//--------------------------------------------------------------------------------------
--//	Activate
--//--------------------------------------------------------------------------------------
function Activate()
				GameRules.spawnbases = spawnbases()
				GameRules.spawnbases:InitGameMode()
end

--//--------------------------------------------------------------------------------------
--//	InitGameMode
--//--------------------------------------------------------------------------------------
function spawnbases:InitGameMode()
				self.spawnunits_leftdown()
				self.spawnunits_middownleft()
				self.spawnunits_middownright()
				self.spawnunits_rightdown()
end


--//--------------------------------------------------------------------------------------
--//	Left Down Creep Spawn
--//--------------------------------------------------------------------------------------
SPAWNLOCATION_LEFTDOWN 	= "leftdowncreepspawn"
WAYPOINTNAME_POINT_01 	= "creep_path_1"
function spawnbases:spawnunits_leftdown()

				local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_LEFTDOWN )
				local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_01)
				local i = 1
        while NUMBERTOSPAWN>=i do
				local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[LEFT DOWN] Create unit has run")
                creature:SetInitialGoalEntity( waypointlocation )
				i = i + 1
		end
end

function spawnbases:spawnunits_leftdown_1()

		local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_LEFTDOWN )
		local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_01)
		local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[LEFT DOWN] TIMER --Spawning 1 creep--")
                creature:SetInitialGoalEntity( waypointlocation )

 
end

Timers:CreateTimer("leftdownspawn", {
	endTime = 60,
	callback = function () -- timer to force move 
		
        --do
        spawnbases:spawnunits_leftdown_1()

		return 3
	end})


--//--------------------------------------------------------------------------------------
--//	MID DOWN LEFT Creep Spawn
--//--------------------------------------------------------------------------------------
SPAWNLOCATION_MIDDOWNLEFT 	= "middownleftcreepspawn"
WAYPOINTNAME_POINT_02 		= "creep_path_5"
function spawnbases:spawnunits_middownleft()

				local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_MIDDOWNLEFT )
				local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_02)
				local i = 1
        while NUMBERTOSPAWN>=i do
				local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[MID DOWN LEFT] Create unit has run")
                creature:SetInitialGoalEntity( waypointlocation )
				i = i + 1
		end
end

function spawnbases:spawnunits_middownleft_1()

		local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_MIDDOWNLEFT )
		local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_02)
		local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[MID DOWN LEFT] TIMER --Spawning 1 creep--")
                creature:SetInitialGoalEntity( waypointlocation )

 
end

Timers:CreateTimer("middownleftspawn", {
	--endTime = 10,
	callback = function () -- timer to force move 
		
        --do
        spawnbases:spawnunits_middownleft_1()

		return 60
	end})
	
--//--------------------------------------------------------------------------------------
--//	MID DOWN RIGHT Creep Spawn
--//--------------------------------------------------------------------------------------
SPAWNLOCATION_MIDDOWNRIGHT 	= "middownrightcreepspawn"
WAYPOINTNAME_POINT_03 		= "mid_right_creep_path_1"
function spawnbases:spawnunits_middownright()

				local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_MIDDOWNRIGHT )
				local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_03)
				local i = 1
        while NUMBERTOSPAWN>=i do
				local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[MID DOWN RIGHT] Create unit has run")
                creature:SetInitialGoalEntity( waypointlocation )
				i = i + 1
		end
end

function spawnbases:spawnunits_middownright_1()

		local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_MIDDOWNRIGHT )
		local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_03)
		local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[MID DOWN RIGHT] TIMER --Spawning 1 creep--")
                creature:SetInitialGoalEntity( waypointlocation )

 
end

Timers:CreateTimer("middownrightspawn", {
	--endTime = 10,
	callback = function () -- timer to force move 
		
        --do
        spawnbases:spawnunits_middownright_1()

		return 60
	end})
	
--//--------------------------------------------------------------------------------------
--//	Right Down Creep Spawn
--//--------------------------------------------------------------------------------------
SPAWNLOCATION_RIGHTDOWN 	= "rightdowncreepspawn"
WAYPOINTNAME_POINT_04 		= "right_creep_path_1"
function spawnbases:spawnunits_rightdown()

				local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_RIGHTDOWN )
				local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_04)
				local i = 1
        while NUMBERTOSPAWN>=i do
				local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[MID DOWN LEFT] Create unit has run")
                creature:SetInitialGoalEntity( waypointlocation )
				i = i + 1
		end
end

function spawnbases:spawnunits_rightdown_1()

		local spawnLocation = Entities:FindByName( nil, SPAWNLOCATION_RIGHTDOWN )
		local waypointlocation = Entities:FindByName ( nil, WAYPOINTNAME_POINT_04)
		local creature = CreateUnitByName( "npc_dota_npc_base" , spawnLocation:GetAbsOrigin() + RandomVector( RandomFloat( 0, 200 ) ), true, nil, nil, DOTA_TEAM_NEUTRALS )
                print ("[MID DOWN LEFT] TIMER --Spawning 1 creep--")
                creature:SetInitialGoalEntity( waypointlocation )

 
end

Timers:CreateTimer("rightdownspawn", {
	--endTime = 10,
	callback = function () -- timer to force move 
		
        --do
        spawnbases:spawnunits_rightdown_1()

		return 60
	end})
	



 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
--[[function spawnbases:ourcreepskilled( keys )
  local unit = EntIndexToHScript( keys.entindex_killed )
  if string.find(unit:GetUnitName(),"npc_dota_npc_base") then
		print ("We found NPC_DoTA_NPC_BASE GOT KILLED LETS CALL SPAWNUNITS FUNCTION")
		return spawnbases:spawnunits()
		end		
end]]