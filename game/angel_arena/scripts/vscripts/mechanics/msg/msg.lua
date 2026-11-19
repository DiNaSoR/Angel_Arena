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
    GameRules:SendCustomMessage("Welcome to Angel Arena", 0, 0)
end
---------------------------------------------------------------------------
-- Duel Message Welcome
---------------------------------------------------------------------------
function duelmsgwelcome()
    Notifications:TopToAll({ text = "A duel is about to begin", duration = 5 })
end
---------------------------------------------------------------------------
-- Zombie Raid Welcome
---------------------------------------------------------------------------
function apocalypse()
	Notifications:Top(PlayerResource:GetPlayer(0), {text="Apocalypse", duration=5, style={color="red", ["font-size"]="110px"}})
end
---------------------------------------------------------------------------
-- boombersts Outbreak Welcome
---------------------------------------------------------------------------
function boomberstsmsg()
	Notifications:Top(PlayerResource:GetPlayer(0), {text="boombersts Outbreak", duration=5, style={color="black", ["font-size"]="100px"}})
end
