function OnAttack( keys )
	local caster 	= keys.caster
	local ability 	= keys.ability
	local target 	= keys.target
	local cooldown 	= ability:GetCooldown(ability:GetLevel())

	if caster:GetUnitName() == "npc_dota_hero_weaver" then return end

	if not caster:IsRangedAttacker() then return end
	if caster:IsIllusion() then return end

	if ability:GetCooldownTimeRemaining() ~= 0 then return end

	if (caster:GetAbsOrigin() - target:GetAbsOrigin() ):Length2D() > 1300 then return end


	ability:StartCooldown(cooldown)

	caster:PerformAttack(target, true, true, true, true, true, false, false) 
end
