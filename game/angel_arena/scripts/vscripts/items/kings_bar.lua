function KingsBar_purge(keys)
	local ability = keys.ability
	local caster = keys.caster
	
	caster:Purge(false, true, false, true, false )
	caster:RemoveModifierByName("modifier_heavens_halberd_debuff")
	
end