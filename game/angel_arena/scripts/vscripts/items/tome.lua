function Agi3(keys)
	local Caster = keys.caster
	local agility = Caster:GetBaseAgility()
	print("PreAgility: " .. agility)
	 Caster:ModifyAgility(3)
	agility = Caster:GetBaseAgility()
	print("ProAgility: " .. agility)
end

function Agi6(keys)
	local Caster = keys.caster
	local agility = Caster:GetBaseAgility()
	print("PreAgility: " .. agility)
	 Caster:ModifyAgility(6)
	agility = Caster:GetBaseAgility()
	print("ProAgility: " .. agility)
end

function Int3(keys)
	local Caster = keys.caster
	local intellect = Caster:GetBaseIntellect()
	print("PreIntellect: " .. intellect)
	Caster:ModifyIntellect(3)
	intellect = Caster:GetBaseIntellect()
	print("ProIntellect: " .. intellect)
end

function Int6(keys)
    local Caster = keys.caster
    local intellect = Caster:GetBaseIntellect()
    print("PreIntellect: " .. intellect)
    Caster:ModifyIntellect(6)
    intellect = Caster:GetBaseIntellect()
    print("ProIntellect: " .. intellect)

    -- Enhanced Particle Effect for Intellect Gain
    local particleName = "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_essence_effect_spiral.vpcf"
    local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, Caster)
    ParticleManager:SetParticleControl(particle, 0, Caster:GetAbsOrigin()) -- Position at caster
    ParticleManager:ReleaseParticleIndex(particle)
end

function Str3(keys)
	local Caster = keys.caster
	local strength = Caster:GetBaseStrength()
	print("PreStrength: " .. strength)
	Caster:ModifyStrength(3)
	strength = Caster:GetBaseStrength()
	print("ProStrength: " .. strength)
end

function Str6(keys)
	local Caster = keys.caster
	local strength = Caster:GetBaseStrength()
	print("PreStrength: " .. strength)
	Caster:ModifyStrength(6)
	strength = Caster:GetBaseStrength()
	print("ProStrength: " .. strength)
end