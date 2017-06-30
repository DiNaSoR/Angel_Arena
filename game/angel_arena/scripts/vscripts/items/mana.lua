function GiveMana( event )
	local caster = event.caster
	local mana_amount = event.mana_amount
	caster:GiveMana(mana_amount)
	PopupMana(caster,mana_amount)
end