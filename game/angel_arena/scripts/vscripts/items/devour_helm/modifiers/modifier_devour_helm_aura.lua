modifier_devour_helm_aura = class({})
--------------------------------------------------------------------------------

function modifier_devour_helm_aura:IsHidden()
	return false
end

--------------------------------------------------------------------------------

function modifier_devour_helm_aura:IsDebuff()
	return false
end

--------------------------------------------------------------------------------

function modifier_devour_helm_aura:GetTexture()
	return "custom/devour_helm"
end

--------------------------------------------------------------------------------

function modifier_devour_helm_aura:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_devour_helm_aura:DestroyOnExpire()
	return true
end

------------------------------------------------------------------------------

function modifier_devour_helm_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}

	return funcs 
end

--------------------------------------------------------------------------------

function modifier_devour_helm_aura:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("attack_speed_aura")
end

--------------------------------------------------------------------------------

function modifier_devour_helm_aura:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("hp_regen_aura")
end

--------------------------------------------------------------------------------

function modifier_devour_helm_aura:OnCreated( kv )

end

---------------------------------------------------------------------------------

function modifier_devour_helm_aura:OnDestroy()

end