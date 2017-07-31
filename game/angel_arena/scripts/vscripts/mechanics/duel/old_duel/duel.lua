--------------------------------------------------------------
-- Duel System Setting
--------------------------------------------------------------
FIRE_DUEL_SYSYEM_TIMER      = 10
DUEL_SYSTEM_TIMER_STARTED   = 300
DUEL_TIMER_INSIDE_ARENA     = 25
DUEL_TIMER_PRE_ARENA        = 5
DUEL_TIMER_AFTER_ARENA      = 10

--------------------------------------------------------------
-- Starting the Duel for first time
--------------------------------------------------------------
function firedueltimer()
    --Create Time for Duel after 10 sec from the GameModeTime
    Timers:CreateTimer(FIRE_DUEL_SYSYEM_TIMER, 
        function()
            Notifications:TopToAll({text="EVERY BREATH YOU TAKE IS A ", duration=9.0})
            Notifications:Top(0, {text="STEP ", duration=9, style={color="yellow"}, continue=true})
            Notifications:Top(0, {text="TOWARDS ", duration=9, continue=true})
            Notifications:Top(0, {text="DEATH!", duration=9, style={color="red"}, continue=true})
        duelstarted()
    end)
end

--------------------------------------------------------------
-- Duel 5 v 5 Start Timer
--------------------------------------------------------------
function duelstarted(event)
    dueltimerQuest = SpawnEntityFromTableSynchronous( "quest", { name = "DueltimerQuest", title = "#dueltimerQuest" } )

    questDuelTimeEnd = GameRules:GetGameTime() + DUEL_SYSTEM_TIMER_STARTED --Time to Finish the quest

    --bar system
    dueltimerQuestKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    dueltimerQuest:AddSubquest( dueltimerQuestKillCountSubQuest )
    dueltimerQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, DUEL_SYSTEM_TIMER_STARTED ) --text on the quest timer at start
    dueltimerQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, DUEL_SYSTEM_TIMER_STARTED ) --text on the quest timer
    dueltimerQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, DUEL_SYSTEM_TIMER_STARTED ) --value on the bar at start
    dueltimerQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, DUEL_SYSTEM_TIMER_STARTED ) --value on the bar

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
                arenawall()
                teleportEnt = Entities:FindByName(nil, "arenateleporttrigger")
                teleportEnt:Disable()
                
            end
            return 1        
        end)
end


--------------------------------------------------------------
-- Duel 5 v 5 Arena Wall
--------------------------------------------------------------
function arenawall()

    local goodpoint =  Vector(6029.61, 7127.88, 201)
    local badpoint = Vector(7616, 7127.88, 201)

    --local player = EntIndexToHScript(player)
    --local playerID = player:GetPlayerID()
    --local hero = EntIndexToHScript(heroindex)

    --local player = PlayerResource:GetPlayer(hero:GetPlayerID())
    --local hero = player:GetAssignedHero()
    --local player = EntIndexToHScript(keys.player)
    --local level = keys.level
    EmitGlobalSound("angel_arena.arenawelcome")
    wallenable()
    --get the player's ID
    --local pID = player:GetPlayerID()

    --get the hero handle
    --local hero = player:GetAssignedHero()
    
    --get the players current stat points
    --local statsUnspent = hero:GetAbilityPoints()

    --spot_heaven = Vector(5897.54, 3904, 17.3543)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_NOTEAM)
    --local dummy = CreateUnitByName("npc_vision_dummy", spot_heaven, true, nil, nil, DOTA_TEAM_BADGUYS)
    --print("Duel 5v5")
    --EmitGlobalSound("angel_arena.duelstartmusic")

    --hero:SetHealth(hero:GetMaxHealth())
    --hero:SetMana(hero:GetMaxMana())
    --ResetAllAbilitiesCooldown(hero)
    --hero:ability:EndCooldown()

    --mass teleport
    for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_BADGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
            FindClearSpaceForUnit(entHero, badpoint, false)
            PlayerResource:SetCameraTarget(nPlayerID, entHero)
            Timers:CreateTimer(0.2, function()
                    PlayerResource:SetCameraTarget(nPlayerID, nil)
                    end)
            entHero:AddNewModifier(entHero, nil, "modifier_stun_lua", {duration = 5})
            entHero:Stop()
            Healall()
        end
    end

    for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
            FindClearSpaceForUnit(entHero, goodpoint, false)
            PlayerResource:SetCameraTarget(nPlayerID, entHero)
            Timers:CreateTimer(0.2, function()
                    PlayerResource:SetCameraTarget(nPlayerID, nil)
                    end)
            entHero:AddNewModifier(entHero, nil, "modifier_stun_lua", {duration = 5})
            entHero:Stop()
            Healall()
        end
    end



    -- Show Quest
    arenawallQuest = SpawnEntityFromTableSynchronous( "quest", { name = "arenawallQuest", title = "#arenawallQuest" } )

    arenawallQuestTimeEnd = GameRules:GetGameTime() + DUEL_TIMER_PRE_ARENA --Time to Finish the quest

    --bar system
    arenawallQuestKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    arenawallQuest:AddSubquest( arenawallQuestKillCountSubQuest )
    arenawallQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, DUEL_TIMER_PRE_ARENA ) --text on the quest timer at start
    arenawallQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, DUEL_TIMER_PRE_ARENA ) --text on the quest timer
    arenawallQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, DUEL_TIMER_PRE_ARENA ) --value on the bar at start
    arenawallQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, DUEL_TIMER_PRE_ARENA ) --value on the bar
    
    Timers:CreateTimer(0.9, function()
        arenawallQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, arenawallQuestTimeEnd - GameRules:GetGameTime() )
        arenawallQuestKillCountSubQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, arenawallQuestTimeEnd - GameRules:GetGameTime() ) --update the bar with the time passed        
        if (arenawallQuestTimeEnd - GameRules:GetGameTime())<=0 and arenawallQuest ~= nil then --finish the quest
            print("30 Sec finished")
            EmitGlobalSound("Tutorial.Quest.complete_01") --on game_sounds_music_tutorial, check others
            UTIL_RemoveImmediate( arenawallQuest )
            arenawallQuest = nil
            arenawallQuestKillCountSubQuest = nil
            Duel5v5()



        end
        return 1        
    end
    )
end
--------------------------------------------------------------
-- Duel 5 v 5 Started Disabling wall
--------------------------------------------------------------
function Duel5v5()

    walldisable()

    print("Duel 5v5")
    EmitGlobalSound("angel_arena.duelstartmusic")

    

    -- Show Quest
    angeldeulQuest = SpawnEntityFromTableSynchronous( "quest", { name = "AngeldeulQuest", title = "#angeldeultimer" } )

    questTimeEnd = GameRules:GetGameTime() + DUEL_TIMER_INSIDE_ARENA --Time to Finish the quest

    --bar system
    angeldeulQuestKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    angeldeulQuest:AddSubquest( angeldeulQuestKillCountSubQuest )
    angeldeulQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, DUEL_TIMER_INSIDE_ARENA ) --text on the quest timer at start
    angeldeulQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, DUEL_TIMER_INSIDE_ARENA ) --text on the quest timer
    angeldeulQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, DUEL_TIMER_INSIDE_ARENA ) --value on the bar at start
    angeldeulQuestKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, DUEL_TIMER_INSIDE_ARENA ) --value on the bar
    
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
            --StopSound("angel_arena.duelstartmusic")
            --SendToConsole("stopsound")


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
	
	DuelCounter = DUEL_TIMER_AFTER_ARENA
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


--------------------------------------------------------------
-- Duel 5 v 5 Wall Disable
--------------------------------------------------------------
function walldisable()
    ObsEnt = Entities:FindByName(nil, "arenawall_1")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_2")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_3")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_4")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_5")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_6")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_7")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_8")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_9")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_10")
    ObsEnt:SetEnabled(false,false)
    ObsEnt = Entities:FindByName(nil, "arenawall_11")
    ObsEnt:SetEnabled(false,false)
    print("Wall Disable")
end


--------------------------------------------------------------
-- Duel 5 v 5 Wall Enable
--------------------------------------------------------------
function wallenable()
    ObsEnt = Entities:FindByName(nil, "arenawall_1")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_2")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_3")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_4")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_5")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_6")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_7")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_8")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_9")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_10")
    ObsEnt:SetEnabled(true,true)
    ObsEnt = Entities:FindByName(nil, "arenawall_11")
    ObsEnt:SetEnabled(true,true)
    print("Wall Enable")
end