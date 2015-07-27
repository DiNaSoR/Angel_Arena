--------------------------------------------------------------
-- Duel 5 v 5 mass teleport
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
            SendToConsole("dota_camera_center")
            entHero:Stop()
            Healall()
        end
    end

    for nPlayerID = 0, DOTA_MAX_PLAYERS-1 do 
        if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
            local entHero = PlayerResource:GetSelectedHeroEntity( nPlayerID )
            FindClearSpaceForUnit(entHero, point, false)
            SendToConsole("dota_camera_center")
            entHero:Stop()
            Healall()
        end
    end

    -- Show Quest
    angelDeul = SpawnEntityFromTableSynchronous( "quest", { name = "angelDeul", title = "#angelDeulTimer" } )

    questTimeEnd = GameRules:GetGameTime() + 5 --Time to Finish the quest

    --bar system
    angeldeulKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    angelDeul:AddSubquest( angeldeulKillCountSubQuest )
    angelDeul:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 5 ) --text on the quest timer at start
    angelDeul:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 5 ) --text on the quest timer
    angeldeulKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 5 ) --value on the bar at start
    angeldeulKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 5 ) --value on the bar
    
    Timers:CreateTimer(0.9, function()
        angelDeul:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() )
        angeldeulKillCountSubQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() ) --update the bar with the time passed        
        if (questTimeEnd - GameRules:GetGameTime())<=0 and angelDeul ~= nil then --finish the quest
        	print("30 Sec finished")
            EmitGlobalSound("Tutorial.Quest.complete_01") --on game_sounds_music_tutorial, check others
            UTIL_RemoveImmediate( angelDeul )
            angelDeul = nil
            angeldeulKillCountSubQuest = nil
            --print("Dummy killed")
            chest_spot_arena = Vector(6720, 7104, 128)
    		local chestarena = CreateUnitByName("npc_chest_gold", chest_spot_arena, true, nil, nil, DOTA_TEAM_NOTEAM)
    		teleportoutsidethearena()


        end
        return 1        
    end
    )
    

    GameRules:SendCustomMessage("FIGHT FOR GLORY.", 0, 0)
end


--------------------------------------------------------------
-- Teleport outside the Arena [sub to Duel5v5]
--------------------------------------------------------------
function teleportoutsidethearena()
	
	DuelCounter = 15
    Timers:CreateTimer(function()
        if DuelCounter == 0 then
           print("teleport enabled")
    		teleportEnt = Entities:FindByName(nil, "arenateleporttrigger")
    		teleportEnt:Enable()
    		dueltimer()
            return nil
        else
            ShowCenterMessage(tostring(DuelCounter),1)
            DuelCounter = DuelCounter - 1
            return 1
        end
    end)
end