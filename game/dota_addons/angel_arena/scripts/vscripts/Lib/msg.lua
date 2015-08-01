function aastartpop()
	ShowGenericPopup( "#aarena_instructions_title", "#aarena_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
end

function welcomemsg()
	GameRules:SendCustomMessage("#aa_welcome_msg", 0, 0)
	GameRules:SendCustomMessage("#aa_duel_5v5", 0, 0)
	
end

function duelmsgwelcome()
	Notifications:Top(PlayerResource:GetPlayer(0), {text="FIGHT FOR GLORY", duration=5, style={color="red", ["font-size"]="110px"}})
end

