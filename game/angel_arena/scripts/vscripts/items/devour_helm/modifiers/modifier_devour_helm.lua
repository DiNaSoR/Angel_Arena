modifier_devour_helm = class({})
--------------------------------------------------------------------------------

function modifier_devour_helm:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetTexture()
	return "custom/devour_helm"
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetModifierAura()
	return "modifier_devour_helm_aura"
end

--------------------------------------------------------------------------------

function modifier_devour_helm:IsAura()
	return true
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("aura_radius")
end

--------------------------------------------------------------------------------

function modifier_devour_helm:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_devour_helm:DestroyOnExpire()
	return false
end

--------------------------------------------------------------------------------

function modifier_devour_helm:OnCreated( kv )

end

--------------------------------------------------------------------------------

function modifier_devour_helm:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_devour_helm:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetModifierPreAttack_BonusDamage( params )
	return self:GetAbility():GetSpecialValueFor("damage") or 0
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetModifierAttackSpeedBonus_Constant( params )
	return self:GetAbility():GetSpecialValueFor("attack_speed") or 0
end


--------------------------------------------------------------------------------

function modifier_devour_helm:GetModifierBonusStats_Strength( params )
	return self:GetAbility():GetSpecialValueFor("bonus_stats") or 0
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetModifierBonusStats_Agility( params )
	return self:GetAbility():GetSpecialValueFor("bonus_stats") or 0
end

--------------------------------------------------------------------------------

function modifier_devour_helm:GetModifierBonusStats_Intellect( params )
	return self:GetAbility():GetSpecialValueFor("bonus_stats") or 0
end

--------------------------------------------------------------------------------
