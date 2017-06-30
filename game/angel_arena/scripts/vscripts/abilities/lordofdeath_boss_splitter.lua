CAST_SOUND_TABLE = {"nevermore_nev_anger_04", "nevermore_nev_anger_06", "nevermore_nev_anger_07", "nevermore_nev_arc_laugh_04", "nevermore_nev_arc_laugh_05", "nevermore_nev_arc_laugh_02"}

function begin_splitter(event)
	local caster = event.caster
	local ability = event.ability
	abilityLevel = ability:GetLevel()
	location = caster:GetOrigin()
	forwardVector = caster:GetForwardVector()
	local randInt = RandomInt(0, 2)
	for i = 0, 16, 1 do
		Timers:CreateTimer(i*0.2, -- Start this timer 10 game-time seconds later
	          function()
	    location = caster:GetOrigin()
		targetPoint = location + RandomVector(300)
		create_individual_explosion(abilityLevel, caster, targetPoint, location)
		end)
	end
	EmitSoundOn(CAST_SOUND_TABLE[RandomInt(1,6)], caster)
	--StartAnimation(caster, {duration=.5, activity=ACT_DOTA_CAST_ABILITY_3, rate=.8, translate="blood_chaser"}) 
	
end

function animation(keys) 
	print('animating')
	caster = keys.caster
	StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_6, rate=1, translate="arcana"})
end

function create_individual_explosion(abilityLevel, caster, targetPoint, casterOrigin)
	print("dummy firing spltter")
  	local dummy = CreateUnitByName("npc_dummy_unit", casterOrigin, true, caster, caster, caster:GetTeamNumber())
  	dummy.owner = "npc_lord_of_death_boss"

  	dummy:AddAbility("skill_lordofdeath_boss_splitter_dummy")
  	dummy:NoHealthBar()
  	dummy:AddAbility("dummy_unit")
  	dummy:FindAbilityByName("dummy_unit"):SetLevel(1)

  	local blast = dummy:FindAbilityByName("skill_lordofdeath_boss_splitter_dummy")
  	blast:SetLevel(abilityLevel)
	local order =
	{
		UnitIndex = dummy:GetEntityIndex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = blast:GetEntityIndex(),
		Position = targetPoint,
		Queue = true
	}

	ExecuteOrderFromTable(order)
	  Timers:CreateTimer(4, -- Start this timer 10 game-time seconds later
	  function()
		dummy:RemoveSelf() 
	  end)
end

function rotateVector(vector, radians)
   XX = vector.x	
   YY = vector.y
   
   Xprime = math.cos(radians)*XX -math.sin(radians)*YY
   Yprime = math.sin(radians)*XX +math.cos(radians)*YY

   vectorX = Vector(1,0,0)*Xprime
   vectorY = Vector(0,1,0)*Yprime
   rotatedVector = vectorX + vectorY
   return rotatedVector
   
end

function projectileHit(event)
	local caster = event.caster
	local target = event.target
	local point = target:GetAbsOrigin() + RandomVector(100)
	local ability = event.ability
	EmitSoundOn("Hero_Techies.LandMine.Detonate", target)
	local modifierKnockback =
	{
		center_x = point.x,
		center_y = point.y,
		center_z = point.z,
		duration = 0.2,
		knockback_duration = 0.2,
		knockback_distance = 150,
		knockback_height = 80,
	}
      --target:AddNewModifier( target, nil, "modifier_knockback", modifierKnockback )
end