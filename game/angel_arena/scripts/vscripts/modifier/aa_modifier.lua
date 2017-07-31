---------------------------------------------------------------------------
-- Angel Arena Modifiers
---------------------------------------------------------------------------
function aa_modifier(context)
print('[Angel Arena] Modifiers Started')
    --Angel Arena Modifiers-------------------------------------------------------------------------------------------------------------------------------------------
	LinkLuaModifier("modifier_stun_lua", "modifier/modifier_stun_lua.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("modifier_aa_speed_limit_break", "modifier/modifier_aa_speed_limit_break.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("modifier_creep_loot", "modifier/modifier_creep_loot.lua", LUA_MODIFIER_MOTION_NONE)
	
	--AABS Modifiers-------------------------------------------------------------------------------------------------------------------------------------------
	--LinkLuaModifier("modifier_arena_hero", "modifier/duel/modifier_arena_hero.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("modifier_hero_out_of_game", "modifier/duel/modifier_hero_out_of_game.lua", LUA_MODIFIER_MOTION_NONE )

	--IMBA Modifiers-------------------------------------------------------------------------------------------------------------------------------------------
	--LinkLuaModifier("modifier_imba_contributor_statue", "modifier/imba/modifier_imba_contributor_statue.lua", LUA_MODIFIER_MOTION_NONE )
	--LinkLuaModifier("modifier_imba_haste_rune_speed_limit_break", "modifier/imba/modifier_imba_haste_rune_speed_limit_break.lua", LUA_MODIFIER_MOTION_NONE )
	--LinkLuaModifier("modifier_imba_haste_boots_speed_break", "modifier/imba/modifier_imba_haste_boots_speed_break.lua", LUA_MODIFIER_MOTION_NONE )
	--LinkLuaModifier("modifier_imba_chronosphere_ally_slow", "modifier/imba/modifier_imba_chronosphere_ally_slow.lua", LUA_MODIFIER_MOTION_NONE )
	--LinkLuaModifier("modifier_imba_prevent_actions_game_start", "modifier/imba/modifier_imba_prevent_actions_game_start.lua", LUA_MODIFIER_MOTION_NONE )
	--LinkLuaModifier("modifier_imba_arena_passive_gold_thinker", "modifier/imba/modifier_imba_arena_passive_gold_thinker.lua", LUA_MODIFIER_MOTION_NONE )
	--LinkLuaModifier("modifier_imba_range_indicator", "modifier/imba/modifier_imba_range_indicator.lua", LUA_MODIFIER_MOTION_NONE )
	--LinkLuaModifier("modifier_imba_war_veteran", "modifier/imba/modifier_imba_war_veteran.lua", LUA_MODIFIER_MOTION_NONE )
	
print('[Angel Arena] Modifiers Ended')
end