modifier_devour_helm_dominated = class({})
--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:IsHidden()
	return false
end

--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:IsPurgable()
	return false
end


--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:GetTexture()
	return "custom/devour_helm"
end

--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:DestroyOnExpire()
	return true
end

--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:CheckState()
	local state = {
		[MODIFIER_STATE_DOMINATED] = true,
	}

	return state
end

------------------------------------------------------------------------------

function modifier_devour_helm_dominated:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
	}

	return funcs 
end

--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:GetModifierExtraHealthBonus()
	return self:GetAbility():GetSpecialValueFor("health_min") - self.base_hp
end

--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:GetModifierMoveSpeedOverride()
	return self:GetAbility():GetSpecialValueFor("speed_base")
end

--------------------------------------------------------------------------------

function modifier_devour_helm_dominated:OnCreated( kv )
	self.base_hp = kv.base_hp
end

---------------------------------------------------------------------------------

function modifier_devour_helm_dominated:OnDestroy()
	if IsServer() then
		if (self:GetAbility()) then
			self:GetAbility().dominated_creep = nil 
		end
	end
end