function arenateleport(trigger)

        if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS or trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "arenaoutside" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                SendToConsole("dota_camera_center")
        end     
        
        return nil              

end

function telegoodout(trigger)

	if trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "teleport_good_out" ):GetAbsOrigin()

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

	if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "teleport_good_in" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                SendToConsole("dota_camera_center")
	end	
        return nil		

end