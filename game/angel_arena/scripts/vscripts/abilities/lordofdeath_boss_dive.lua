CAST_SOUND_TABLE = {"nevermore_nev_anger_06", "nevermore_nev_anger_07", "nevermore_nev_anger_08", "nevermore_nev_arc_laugh_09", "nevermore_nev_arc_ability_shadow_10", "nevermore_nev_arc_ability_requiem_03"}

function begin_dive(event)
	local caster = event.caster
	local ability = event.ability
	abilityLevel = ability:GetLevel()
	location = caster:GetOrigin()
	StartAnimation(caster, {duration=1, activity=ACT_DOTA_FLAIL, rate=0.5, translate="forcestaff_friendly"})
	EmitSoundOn(CAST_SOUND_TABLE[RandomInt(1,6)], caster)
end

function slide_think(keys)
	local ability = keys.ability
	local caster = keys.caster
	local modifier = caster:FindModifierByName("modifier_holy_blink_slide")
	local origin = caster:GetAbsOrigin()
	ability.forwardVector = caster:GetForwardVector()
	
	caster.holy_slide_velocity = 15
	local newPosition = origin+ability.forwardVector*caster.holy_slide_velocity
	caster.holy_slide_velocity = math.max(caster.holy_slide_velocity - 1, 0)
	groundPosition = GetGroundPosition( newPosition, caster )
	caster:SetAbsOrigin(groundPosition)

end

function slide_end(keys)
	local caster = keys.caster
	local location = caster:GetAbsOrigin()
	local newLoc = GetGroundPosition(location, caster)
	caster:SetOrigin(newLoc)
	FindClearSpaceForUnit(caster, newLoc, true)
	StartAnimation(caster, {duration=0.6, activity=ACT_DOTA_FORCESTAFF_END, rate=0.5})
end