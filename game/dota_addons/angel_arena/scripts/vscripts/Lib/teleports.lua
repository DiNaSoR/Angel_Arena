function Healall()
        local allHeroes = HeroList:GetAllHeroes()
        for _,hero in pairs(allHeroes) do 
                hero:SetMana(hero:GetMaxMana()) 
                hero:SetHealth(hero:GetMaxHealth())
                
                for i=0,15 do 
                        local ability = hero:GetAbilityByIndex(i)
                        if ability then 
                                        ability:EndCooldown() 
                        end 
                end
        end
end

function Basetonorthport(trigger)

        if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "Northportbase" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
                
        end
        
        if trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then 
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()

        local   point =  Entities:FindByName( nil, "Northportbase" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        end
        return nil 
end

function Northporttobase(trigger)

        if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "teleport_good_out" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        end
        
        if trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then 
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()

        local   point =  Entities:FindByName( nil, "teleport_good_in" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        end
        return nil 
end

function Basetosouthport(trigger)

        if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "Southportbase" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        end
        
        if trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then 
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()

        local   point =  Entities:FindByName( nil, "Southportbase" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        end
        return nil 
end

function Southporttobase(trigger)

        if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "teleport_good_out" ):GetAbsOrigin()


                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        end
        
        if trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then 
            local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()

        local   point =  Entities:FindByName( nil, "teleport_good_in" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        end
        return nil 
end

function arenateleport(trigger)


        if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS or trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then
                -- activator = eaither hero or npc entity
                local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()

                local   point =  Entities:FindByName( nil, "arenaoutside" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move
                trigger.activator:Stop()
        end     
        
        return nil              

end

function telegoodout(trigger)

	if trigger.activator:GetTeamNumber() == DOTA_TEAM_BADGUYS then
                local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()
                -- Get the position of the "point_teleport_spot"-entity we put in our map
                local   point =  Entities:FindByName( nil, "teleport_good_out" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

                
        	
	end	
        return nil

end

function telegoodin(trigger)

	if trigger.activator:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
        local   activator   = trigger.activator
                -- playerID = get the hero which is the player real ID
                local   playerID    = activator:GetPlayerID()
                -- Get the position of the "point_teleport_spot"-entity we put in our map
        local   point =  Entities:FindByName( nil, "teleport_good_in" ):GetAbsOrigin()

                -- Find a spot for the hero around 'point' and teleports to it
                FindClearSpaceForUnit(trigger.activator, point, false)
                PlayerResource:SetCameraTarget(playerID, activator)
                Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(playerID, nil)
                    end)
                -- Stop the hero, so he doesn't move

                trigger.activator:Stop()
                -- Refocus the camera of said player to the position of the teleported hero.

               
	end	
        return nil		

end

--[[

          for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_BADGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
           -- PlayerResource:SetCameraTarget(entHero, nil)
            
            entHero.original_position = entHero:GetAbsOrigin()

            FindClearSpaceForUnit(entHero, point, false)
            --SendToConsole("dota_camera_center")
            GameMode:RepositionPlayerCamera(event)
            entHero:Stop()
            Healall()
            --Timers:CreateTimer(3, function()
          -- FindClearSpaceForUnit(entHero, entHero.original_position, false)
     -- return 1.0
  --  end
  --)
            

        end
    end

]]