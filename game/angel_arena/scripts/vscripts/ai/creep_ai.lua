-- Roam AI
-- waypoint name format: unitName_waypoint

function Spawn( entityKeyValues )
	-- Don't roam specific units placed through hammer with the "guard" keyword
	local entName = thisEntity:GetName()
	if entName == "guard" then
		return
	end
	thisEntity:SetContextThink( "roam_ai_think", RoamThink , 5)
	print("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
	thisEntity.state = "roam"
	local unitName = thisEntity:GetUnitName()
	thisEntity.WP = CollectWaypoints( unitName )
end

function CollectWaypoints( unitName )
	local result = {}
	local i = 1
	local wp = nil
	local waypoint_name = unitName.."_waypoint"
	wp = Entities:FindAllByName( waypoint_name )
	for k,v in pairs(wp) do
		table.insert( result, v:GetOrigin() )
	end
	return result
end

function RoamThink()
	if thisEntity.currentWP == nil then 
		thisEntity.currentWP = thisEntity:GetOrigin()
	end

	local waypoint_name = thisEntity:GetUnitName().."_waypoint"
	local distance_to_wp = thisEntity:GetOrigin() - thisEntity.currentWP

	-- if the unit reached the waypoint, find a new one
	if distance_to_wp:Length2D() < 100 then
		local next_waypoint = thisEntity.WP[RandomInt(1, #thisEntity.WP)]+RandomVector(100)
		thisEntity:MoveToPositionAggressive(next_waypoint)
		thisEntity.currentWP = next_waypoint
	end
	
	return 5
end