function PowerAmuletStart( event )
	local caster = event.caster
	local ability = event.ability
	local damage_const = event.Dmg
	local stun_per_charge = event.StunPerCharge
	local heal = event.Heal
	local heal_pct = event.heal_pct_per_charge/100
	local charges = ability:GetCurrentCharges() 
	local radius = event.Radius
	local enemies = FindUnitsInRadius(caster:GetTeamNumber() , caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NO_INVIS, 0, false) 
	ability:SetCurrentCharges(ability:GetCurrentCharges() + 1)
	caster:Heal(heal+caster:GetMaxHealth()*heal_pct*charges, ability) 
	ParticleManager:CreateParticle("particles/econ/items/invoker/invoker_apex/invoker_sun_strike_warp_blast_immortal1.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	caster:EmitSound("DOTA_Item.UrnOfShadows.Activate")
	
	if enemies then 
		for _, target in pairs(enemies) do
			ability:ApplyDataDrivenModifier(caster, target, "modifier_power_amulet_stun", { duration = charges*stun_per_charge })
			ApplyDamage({ victim = target, attacker = caster, damage= damage_const, damage_type = DAMAGE_TYPE_MAGICAL })
		end
	end
	
end

function OnAttack(event)
	local target = event.target
	local caster = event.caster
	local ability = event.ability
	local charges = ability:GetCurrentCharges()
	local duration = event.duration

	if caster:IsIllusion() then return end
	
	if charges == 0 then 
		caster:RemoveModifierByName("modifier_power_amulet_disarmor") 
		return 
	end

	if not target:HasModifier("modifier_power_amulet_disarmor") then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_power_amulet_disarmor", {duration = duration})
	end


	target:SetModifierStackCount("modifier_power_amulet_disarmor", ability, charges)
end

function CheckCharges(event)
	local caster = event.caster
	local ability = event.ability
	local charges = ability:GetCurrentCharges()
	local damage_per_charge = event.DmgCharge
	if charges == 0 then 
		caster:RemoveModifierByName("modifier_power_amulet_damage")
		return
	end
	if not caster:HasModifier("modifier_power_amulet_damage") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_power_amulet_damage", {})
	end
	caster:SetModifierStackCount("modifier_power_amulet_damage", ability, charges*damage_per_charge)
end
