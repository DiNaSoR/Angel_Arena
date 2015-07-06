--GoodGuys out and in + jail zone in good guy area to tele out the bad guys out



--Todo
-- Use towers to protect the teleporters
-- Use large trigger to teleport the badguys players outside the start area
-- Put the shops all of them with new modiles
-- try to run puge boss in the middle
-- spawn area for creeps

-- SALAH PUT AURA ATTACK SPEED FOR THE TOWERS TO SUPPOER UR ALLY ON BASE FIGHT
-- inner beast, feral impulse, Degen aura


function telegoodout(trigger)

		if 		trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then
        -- Get the position of the "point_teleport_spot"-entity we put in our map
		
        local point =  Entities:FindByName( nil, "teleport_good_out" ):GetAbsOrigin()

        -- Find a spot for the hero around 'point' and teleports to it
        FindClearSpaceForUnit(trigger.activator, point, false)
        -- Stop the hero, so he doesn't move

        trigger.activator:Stop()
        -- Refocus the camera of said player to the position of the teleported hero.

        SendToConsole("dota_camera_center")
	
	end	
return nil

end

function telegoodin(trigger)

	if 		trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
        -- Get the position of the "point_teleport_spot"-entity we put in our map
        local point =  Entities:FindByName( nil, "teleport_good_in" ):GetAbsOrigin()

        -- Find a spot for the hero around 'point' and teleports to it
        FindClearSpaceForUnit(trigger.activator, point, false)
        -- Stop the hero, so he doesn't move

        trigger.activator:Stop()
        -- Refocus the camera of said player to the position of the teleported hero.

        SendToConsole("dota_camera_center")
	end	
return nil		

end