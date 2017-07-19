item_polar_spear = item_polar_spear or class({}) 
LinkLuaModifier( "modifier_polar_spear", 'items/polar_spear/modifiers/modifier_polar_spear', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_polar_spear_active", 'items/polar_spear/modifiers/modifier_polar_spear_active', LUA_MODIFIER_MOTION_HORIZONTAL )
--------------------------------------------------------------------------------

function item_polar_spear:GetIntrinsicModifierName()
	return "modifier_polar_spear"
end

function item_polar_spear:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function item_polar_spear:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end

	return ""
end

function item_polar_spear:OnSpellStart()
	local caster 			= self:GetCaster() 
	local original_target	= self:GetCursorTarget()
	
	if caster:GetTeamNumber() ~= original_target:GetTeamNumber() then
		if original_target:TriggerSpellAbsorb( self ) then
			return
		end
	else 
		if PlayerResource:IsDisableHelpSetForPlayerID(caster:GetPlayerOwnerID(), original_target:GetPlayerOwnerID() ) then
			return 
		end
	end

	original_target:AddNewModifier(caster, self, "modifier_polar_spear_active", { speed = 40 })
end
