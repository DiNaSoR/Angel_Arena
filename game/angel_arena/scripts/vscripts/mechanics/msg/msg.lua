---------------------------------------------------------------------------
-- This is very old msg and its not working after 7.0
---------------------------------------------------------------------------
function aastartpop()
	ShowGenericPopup( "#aarena_instructions_title", "#aarena_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
end
---------------------------------------------------------------------------
-- Welcome Message
---------------------------------------------------------------------------
function welcomemsg()
	local killtowin 		= "<font color='#FF8000' size='18'>You need to get "..KILLS_TO_END_GAME_FOR_TEAM.." kill point,To Win the game</font>"
	local aa_welcome_msg 	= "<font color='#E8D505' size='18'>Welcome to Angel Arena "..AA_VERSION.."</font>"
	GameRules:SendCustomMessage(killtowin, 0, 0)
	GameRules:SendCustomMessage(aa_welcome_msg, 0, 0)
	GameRules:SendCustomMessage("#aa_duel_5v5", 0, 0)
	
end
---------------------------------------------------------------------------
-- Duel Message Welcome
---------------------------------------------------------------------------
function duelmsgwelcome()
	Notifications:Top(PlayerResource:GetPlayer(0), {text="FIGHT FOR GLORY", duration=5, style={color="red", ["font-size"]="110px"}})
end
