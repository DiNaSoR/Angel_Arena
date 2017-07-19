--[[
	Function examples:

	CleaveDD({ caster = hero_attacker, target = hero_target, damage = 500, damage_pct = 35, radius = 200, range_hero_allowed = false})

	CleaveLua({ caster = hero_attacker, target = hero_target, damage = 500, damage_pct = 35, radius = 250, damage_type = DAMAGE_TYPE_MAGICAL, range_hero_allowed = true, particle_name = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"})

	CreateParticleForCleave("particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf", 200, hero_target)
]]

local illusion_damage_decrease = 5

function CleaveDD(event) -- Datadriven cleave
	local caster = event.caster -- attacker
	local target = event.target -- target of attack
	local damage = event.damage -- dealed damage from caster to target
	local damage_pct = event.dmg_pct/100 -- percent of cleave
	local radius = event.radius -- radius of cleave
	local range_hero_allowed = event.range_flag -- is cleave allow for ranged heroes? (not bool!)
	if not range_hero_allowed and caster:IsRangedAttacker() then return end
	if caster and caster:IsIllusion() then return end
	if not caster or not target or not damage or not damage_pct or not radius then return end -- null trash
	if not IsValidEntity(caster) or not IsValidEntity(target) then return end -- not valid entity trash
	if not target:IsCreep() and not target:IsHero() then return end 
	
	local team = caster:GetTeamNumber() -- attacker team number
	local position = target:GetAbsOrigin() -- position
	local units_in_radius = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)  --finds units

	if not units_in_radius then return end -- nobody here :c

	local damage_int_pct_add = 1

	if caster:IsRealHero() then
		damage_int_pct_add = caster:GetIntellect()
		damage_int_pct_add = damage_int_pct_add / 16 / 100 + 1
	end 

	damage = damage / damage_int_pct_add

	--CreateParticleForCleave("particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf", radius, target)
	for i,x in pairs(units_in_radius) do
		if x ~= target then
			if x:GetUnitName() == "npc_dota_hero_meepo" then damage = damage / illusion_damage_decrease end
			
			if target:IsIllusion() or x:IsIllusion() then 
				ApplyDamage({ victim = x, attacker = caster, damage = damage*damage_pct/illusion_damage_decrease,	damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, ability = event.ability }) --deal damage
			else
				ApplyDamage({ victim = x, attacker = caster, damage = damage*damage_pct, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, ability = event.ability}) --deal damage	
			end
		end
	end
end

function CleaveLua(event)
	local caster = event.caster -- attacker
	local target = event.target -- target of attack
	local damage = event.damage -- dealed damage from caster to target
	local damage_pct = event.damage_pct/100 -- percent of cleave
	local damage_type = event.damage_type -- is damage type set.
	local radius = event.radius -- radius of cleave
	local range_hero_allowed = event.range_flag -- is cleave allow for ranged heroes? (not bool!)
	local particle_name = event.particle_name
	if not range_hero_allowed and caster:IsRangedAttacker() then return end

	if not radius then radius = 200 end -- default radius is 200
	if not damage_type then damage_type = DAMAGE_TYPE_PURE end -- default damage is pure damage
	if not caster or not target or not damage or not damage_pct or not IsValidEntity(caster) or not IsValidEntity(target) then return end

	local team = caster:GetTeamNumber() -- attacker team number
	local position = target:GetAbsOrigin() -- position
	local units_in_radius = FindUnitsInRadius(team, position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)  --finds units

	if not units_in_radius then return end -- nobody here :c

	for i,x in pairs(units_in_radius) do
		if x ~= target then
			if target:IsIllusion() or x:IsIllusion() then 
				ApplyDamage({ victim = x, attacker = caster, damage = damage*damage_pct/illusion_damage_decrease,	damage_type = damage_type, ability = event.ability }) --deal damage
			else
				ApplyDamage({ victim = x, attacker = caster, damage = damage*damage_pct,	damage_type = damage_type, ability = event.ability }) --deal damage	
			end
		end
	end
end

function CreateParticleForCleave(particle_name, radius, target)
	local particle
	particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius/2,radius/2,radius/2))
	particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius/2,radius/2,radius/2))
	particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius/2,radius/2,radius/2))
	particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius/2,radius/2,radius/2))
	particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius/2,radius/2,radius/2))
end