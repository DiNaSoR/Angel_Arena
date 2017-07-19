function MysticAmuletStart( event )
	local caster = event.caster
	local ability = event.ability
	local damage_const = event.Dmg
	local charges = ability:GetCurrentCharges() 
	local radius = event.Radius
	local damage_per_charge = event.DmgPerCharge / 100
	local enemies = FindUnitsInRadius(caster:GetTeamNumber() , caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NO_INVIS, 0, false) 
	local max_stack = event.max_stack_dmg or 10000
	
	if charges > max_stack then
		charges = max_stack - 1
	end

	ability:SetCurrentCharges(ability:GetCurrentCharges() + 1)

	if enemies then 
		caster:EmitSound("DOTA_Item.Dagon.Activate")
	end

	local damage_int_pct_add = 1
	if caster:IsRealHero() then
		damage_int_pct_add = caster:GetIntellect()
		damage_int_pct_add = damage_int_pct_add / 16 / 100 + 1
	end 

	if enemies then 
		for _, target in pairs(enemies) do
			local total_damage = damage_const + (damage_per_charge*charges*target:GetMaxHealth()) / damage_int_pct_add

			if IsUnitBossGlobal(target) then
				total_damage = total_damage / 4
			end

			ApplyDamage({ victim = target, attacker = caster, damage = total_damage, damage_type = DAMAGE_TYPE_MAGICAL })
			
			local dagon_particle = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf",  PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(dagon_particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), false)
			local particle_effect_intensity = 900 
			ParticleManager:SetParticleControl(dagon_particle, 2, Vector(particle_effect_intensity))
		end
	end
	
end

function CheckCharges(event)
	local caster = event.caster
	local ability = event.ability
	local charges = ability:GetCurrentCharges()

	if charges == 0 then 
		caster:RemoveModifierByName("modifier_mystic_amulet_bonus")
		return
	end

	if not caster:HasModifier("modifier_mystic_amulet_bonus") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_mystic_amulet_bonus", {})
	end
	caster:SetModifierStackCount("modifier_mystic_amulet_bonus", ability, charges)
	
end
