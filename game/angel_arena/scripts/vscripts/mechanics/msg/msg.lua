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
	duelmsgwelcome()
	GameRules:SendCustomMessage(killtowin, 0, 0)
	GameRules:SendCustomMessage(aa_welcome_msg, 0, 0)
	GameRules:SendCustomMessage("#aa_duel_5v5", 0, 0)
	
end
---------------------------------------------------------------------------
-- Duel Message Welcome
---------------------------------------------------------------------------
function duelmsgwelcome()
	Notifications:Top(PlayerResource:GetPlayer(0), {text="BLOODSHEDS", duration=5, style={color="red", ["font-size"]="110px"}})
end
---------------------------------------------------------------------------
-- Zombie Raid Welcome
---------------------------------------------------------------------------
function apocalypse()
	Notifications:Top(PlayerResource:GetPlayer(0), {text="Apocalypse", duration=5, style={color="red", ["font-size"]="110px"}})
end
---------------------------------------------------------------------------
-- Jihadists Outbreak Welcome
---------------------------------------------------------------------------
function jihadistsmsg()
	Notifications:Top(PlayerResource:GetPlayer(0), {text="Jihadists Outbreak", duration=5, style={color="black", ["font-size"]="100px"}})
end
