--require('Lib/aa')
--------------------------------------------------------------
-- Starting the Duel for first time
--------------------------------------------------------------
function firedueltimer()
--Create Time for Duel after 10 sec from the GameModeTime
    Timers:CreateTimer(10, 
        function()
            Notifications:TopToAll({text="EVERY BREATH YOU TAKE IS A ", duration=9.0})
            Notifications:Top(0, {text="STEP ", duration=9, style={color="black"}, continue=true})
            Notifications:Top(0, {text="TOWARDS ", duration=9, continue=true})
            Notifications:Top(0, {text="DEATH!", duration=9, style={color="red"}, continue=true})
        duelstarted()
    end)
end

--------------------------------------------------------------
-- Duel 5 v 5 Start Timer
--------------------------------------------------------------
function duelstarted()
    dueltimerQuest = SpawnEntityFromTableSynchronous( "quest", { name = "DueltimerQuest", title = "#dueltimerQuest" } )

    questDuelTimeEnd = GameRules:GetGameTime() + 600 --Time to Finish the quest

    --bar system
    dueltimerQuestKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    dueltimerQuest:AddSubquest( dueltimerQuestKillCountSubQuest )
    dueltimerQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 600 ) --text on the quest timer at start
    dueltimerQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 600 ) --text on the quest timer
    dueltimerQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 600 ) --value on the bar at start
    dueltimerQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 600 ) --value on the bar

    Timers:CreateTimer(0.9, function()
            dueltimerQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questDuelTimeEnd - GameRules:GetGameTime() )
            dueltimerQuestKillCountSubQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questDuelTimeEnd - GameRules:GetGameTime() ) --update the bar with the time passed        
            if (questDuelTimeEnd - GameRules:GetGameTime())<=0 and dueltimerQuest ~= nil then --finish the quest
                print("30 Sec finished")
                EmitGlobalSound("Tutorial.Quest.complete_01") --on game_sounds_music_tutorial, check others
                UTIL_RemoveImmediate( dueltimerQuest )
                dueltimerQuest = nil
                dueltimerQuestKillCountSubQuest = nil
                print("Run script now")
                Duel5v5()
                teleportEnt = Entities:FindByName(nil, "arenateleporttrigger")
                teleportEnt:Disable()
                
            end
            return 1        
        end)
end

--[[--------------------------------------------------------------

    Timers:CreateTimer({
    endTime = 600, -- when this timer should first execute, you can omit this if you want it to run first on the next frame
    callback = function() Duel5v5()
    --callback = function StartDuels()
      print ("Hello. Duel after 25sec")
      print ("teleport disabled")
            teleportEnt = Entities:FindByName(nil, "arenateleporttrigger")
            teleportEnt:Disable()
      return 600
    end
    })
--------------------------------------------------------------]]


--------------------------------------------------------------
-- Duel 5 v 5 mass teleport + Healall +Ability resetCooldown
--------------------------------------------------------------
function Duel5v5()
    local point =  Vector(6720, 7104, 128)
    --local player = EntIndexToHScript(player)
    --local playerID = player:GetPlayerID()
    --local hero = EntIndexToHScript(heroindex)

    --local player = PlayerResource:GetPlayer(hero:GetPlayerID())
    --local hero = player:GetAssignedHero()
	--local player = EntIndexToHScript(keys.player)
	--local level = keys.level


	--get the player's ID
    --local pID = player:GetPlayerID()

    --get the hero handle
    --local hero = player:GetAssignedHero()
    
    --get the players current stat points
    --local statsUnspent = hero:GetAbilityPoints()

    --spot_heaven = Vector(5897.54, 3904, 17.3543)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_NOTEAM)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_BADGUYS)
    print("Duel 5v5")
    EmitGlobalSound("angel_arena.duelstartmusic")

    --hero:SetHealth(hero:GetMaxHealth())
	--hero:SetMana(hero:GetMaxMana())
	--ResetAllAbilitiesCooldown(hero)
	--hero:ability:EndCooldown()

    --mass teleport
    for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_BADGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
            FindClearSpaceForUnit(entHero, point, false)
            PlayerResource:SetCameraTarget(nPlayerID, entHero)
            Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(nPlayerID, nil)
                    end)
            entHero:Stop()
            Healall()
        end
    end

    for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
            FindClearSpaceForUnit(entHero, point, false)
            PlayerResource:SetCameraTarget(nPlayerID, entHero)
            Timers:CreateTimer(1, function()
                    PlayerResource:SetCameraTarget(nPlayerID, nil)
                    end)
            entHero:Stop()
            Healall()
        end
    end

    -- Show Quest
    angeldeulQuest = SpawnEntityFromTableSynchronous( "quest", { name = "AngeldeulQuest", title = "#angeldeultimer" } )

    questTimeEnd = GameRules:GetGameTime() + 30 --Time to Finish the quest

    --bar system
    angeldeulQuestKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    angeldeulQuest:AddSubquest( angeldeulQuestKillCountSubQuest )
    angeldeulQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 30 ) --text on the quest timer at start
    angeldeulQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 30 ) --text on the quest timer
    angeldeulQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 30 ) --value on the bar at start
    angeldeulQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 30 ) --value on the bar
    
    Timers:CreateTimer(0.9, function()
        angeldeulQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() )
        angeldeulQuestKillCountSubQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() ) --update the bar with the time passed        
        if (questTimeEnd - GameRules:GetGameTime())<=0 and angeldeulQuest ~= nil then --finish the quest
        	print("30 Sec finished")
            EmitGlobalSound("Tutorial.Quest.complete_01") --on game_sounds_music_tutorial, check others
            UTIL_RemoveImmediate( angeldeulQuest )
            angeldeulQuest = nil
            angeldeulQuestKillCountSubQuest = nil
            --print("Dummy killed")
            drop = Vector(6861.27, 7211.82, 192.884)
    		local item = CreateUnitByName("npc_chest_gold", drop, true, nil, nil, DOTA_TEAM_NOTEAM)
    		teleportoutsidethearena()
            SendToConsole("stopsound")


        end
        return 1        
    end
    )


    duelmsgwelcome()
end


--------------------------------------------------------------
-- Teleport outside the Arena [sub to Duel5v5]
--------------------------------------------------------------
function teleportoutsidethearena()
	
	DuelCounter = 1
    Timers:CreateTimer(function()
        if DuelCounter == 0 then
           print("teleport enabled")
    		teleportEnt = Entities:FindByName(nil, "arenateleporttrigger")
            Healall()
    		teleportEnt:Enable()
    		duelstarted()
            return nil
        else
            ShowCenterMessage(tostring(DuelCounter),1)
            DuelCounter = DuelCounter - 1
            return 1
        end
    end)
end