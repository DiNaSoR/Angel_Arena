function DealPercentDamage( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local int_pct = event.int_pct / 100
	local damage = caster:GetIntellect()*int_pct;
	local dagon_level = 6

	local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(dagon_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
	local particle_effect_intensity = 300 + (100 * dagon_level)  --Control Point 2 in Dagon's particle effect takes a number between 400 and 800, depending on its level.
	ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
	
	caster:EmitSound("DOTA_Item.Dagon.Activate")
	target:EmitSound("DOTA_Item.Dagon5.Target")
	
	ApplyDamage({ victim = target, attacker = caster, damage = damage,	damage_type = DAMAGE_TYPE_MAGICAL })
end