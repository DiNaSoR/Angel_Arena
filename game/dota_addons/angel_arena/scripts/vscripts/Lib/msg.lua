function aastartpop()
	ShowGenericPopup( "#aarena_instructions_title", "#aarena_instructions_body", "", "", DOTA_SHOWGENERICPOPUP_TINT_SCREEN )
end

function welcomemsg()
	GameRules:SendCustomMessage("#aa_welcome_msg", 0, 0)
	GameRules:SendCustomMessage("#aa_Duel_5v5", 0, 0)
end
