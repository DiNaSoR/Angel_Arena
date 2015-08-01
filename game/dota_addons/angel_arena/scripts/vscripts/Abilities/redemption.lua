function redemption(event)
	if event.target:GetUnitName() == "player_gravestone" then
		local target_hero = event.target:GetOwnerEntity()
		local location = Vector(event.target:GetAbsOrigin().x, event.target:GetAbsOrigin().y, event.target:GetAbsOrigin().z+100)
		local health_difference = target_hero:GetMaxHealth() * ( (event.ability:GetLevelSpecialValueFor("hp", event.ability:GetLevel()-1) / 100))
		local mana_difference = target_hero:GetMaxMana() * (1 - (event.ability:GetLevelSpecialValueFor("mana", event.ability:GetLevel()-1) / 100))
		local hero = event.caster

		if target_hero:UnitCanRespawn() then
			--target_hero:RespawnUnit() --doesn't actually respawn heroes, the 'Killed by' still remains.
			target_hero:SetTimeUntilRespawn(0)


			--need to wait a bit for the hero to respawn	   
			Timers:CreateTimer({
		    	endTime = 0.1,
		    	callback = function()
		    		FindClearSpaceForUnit(target_hero, location, true)
		    		EmitSoundOn("Hero_Chen.HandOfGodHealHero", target_hero)
		    		target_hero:ModifyHealth(health_difference, nil, false, 0)
					target_hero:ReduceMana(mana_difference)
    				particle = ParticleManager:CreateParticle("particles/neutral_fx/roshan_death_aegis_trail.vpcf", PATTACH_OVERHEAD_FOLLOW, target_hero)
    				ParticleManager:SetParticleControl(particle, 0, target_hero:GetAbsOrigin())
    				particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_aegis_starfall.vpcf", PATTACH_ABSORIGIN_FOLLOW, target_hero)
    				ParticleManager:SetParticleControl(particle, 0, target_hero:GetAbsOrigin())
    				particle = ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_holy_persuasion_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, target_hero)
    				ParticleManager:SetParticleControl(particle, 0, target_hero:GetAbsOrigin())
    				ParticleManager:SetParticleControl(particle, 1, target_hero:GetAbsOrigin())
    				particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target_hero)
    				ParticleManager:SetParticleControl(particle, 0, target_hero:GetAbsOrigin())

    				

    		 	end
		  	})
			
		end
	else
		event.ability:RefundManaCost()
		event.ability:EndCooldown()
		EmitSoundOnClient("General.CastFail_InvalidTarget_Hero", event.caster:GetPlayerOwner())
		FireGameEvent( 'custom_error_show', { player_ID = pID, _error = "Ability Must Target Tombstones" } )
	end
end