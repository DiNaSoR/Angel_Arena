
function firedueltimer()
--Create Time for Duel after 10 sec from the GameModeTime----
	Timers:CreateTimer(5, 
		function()
			Notifications:TopToAll({text="EVERY BREATH YOU TAKE IS A ", duration=9.0})
			Notifications:Top(0, {text="STEP ", duration=9, style={color="black"}, continue=true})
			Notifications:Top(0, {text="TOWARDS ", duration=9, continue=true})
			Notifications:Top(0, {text="DEATH!", duration=9, style={color="red"}, continue=true})
		dueltimer()
	end)
end

	
function dueltimer()
	dueltimer = SpawnEntityFromTableSynchronous( "quest", { name = "dueltimer", title = "#dueltimer" } )

    questTimeEnd = GameRules:GetGameTime() + 5 --Time to Finish the quest

    --bar system
    dueltimerKillCountSubQuest = SpawnEntityFromTableSynchronous( "subquest_base", {
        show_progress_bar = true,
        progress_bar_hue_shift = -119
    } )
    dueltimer:AddSubquest( dueltimerKillCountSubQuest )
    dueltimer:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 5 ) --text on the quest timer at start
    dueltimer:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 5 ) --text on the quest timer
    dueltimerKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, 5 ) --value on the bar at start
    dueltimerKillCountSubQuest:SetTextReplaceValue( SUBQUEST_TEXT_REPLACE_VALUE_TARGET_VALUE, 5 ) --value on the bar

	Timers:CreateTimer(0.9, function()
	        dueltimer:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() )
	        dueltimerKillCountSubQuest:SetTextReplaceValue( QUEST_TEXT_REPLACE_VALUE_CURRENT_VALUE, questTimeEnd - GameRules:GetGameTime() ) --update the bar with the time passed        
	        if (questTimeEnd - GameRules:GetGameTime())<=0 and dueltimer ~= nil then --finish the quest
	        	print("30 Sec finished")
	            EmitGlobalSound("Tutorial.Quest.complete_01") --on game_sounds_music_tutorial, check others
	            UTIL_RemoveImmediate( dueltimer )
	            dueltimer = nil
	            dueltimerKillCountSubQuest = nil
	            print("Run script now")
	            Duel5v5()
	            teleportEnt = Entities:FindByName(nil, "arenateleporttrigger")
    			teleportEnt:Disable()
	            
	        end
	        return 1        
	    end)
end

--[[-----------------------------------------------------------------------------------------

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
-------------------------------------------------------------------------------------------]]