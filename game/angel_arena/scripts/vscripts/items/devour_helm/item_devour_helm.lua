item_devour_helm = class({})
LinkLuaModifier( "modifier_devour_helm", 			'items/devour_helm/modifiers/modifier_devour_helm', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_devour_helm_aura", 		'items/devour_helm/modifiers/modifier_devour_helm_aura', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_devour_helm_active", 	'items/devour_helm/modifiers/modifier_devour_helm_active', LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_devour_helm_dominated", 	'items/devour_helm/modifiers/modifier_devour_helm_dominated', LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------

function item_devour_helm:GetIntrinsicModifierName()
	return "modifier_devour_helm"
end

function item_devour_helm:GetTexture()
	if self.target then
		return"custom/devour_helm_active"
	else 
		return "custom/devour_helm"
	end
end

function item_devour_helm:CastFilterResultTarget( hTarget )
	if self:GetCaster() == hTarget then
		return UF_FAIL_CUSTOM
	end

	if self:GetCaster():GetTeamNumber() ~= hTarget:GetTeamNumber() and hTarget:IsHero() then
		return UF_FAIL_CUSTOM
	end

	return UF_SUCCESS
end

function item_devour_helm:GetBehavior()
	if self.target then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
	end
end

function item_devour_helm:GetCustomCastErrorTarget( hTarget )
	if self:GetCaster() == hTarget then
		return "#dota_hud_error_cant_cast_on_self"
	end

	if not hTarget:IsCreep() and not hTarget:IsHero() then
		return "#dota_hud_error_cant_cast_on_other"
	end

	if self:GetCaster():GetTeamNumber() ~= hTarget:GetTeamNumber() then
		return "#dota_hud_error_cant_cast_enemy_hero"
	end

	return ""
end

function item_devour_helm:OnSpellStart()
	local caster 			= self:GetCaster() 
	local original_target	= self:GetCursorTarget()

	local caster_id = caster:GetPlayerOwnerID() 
	local target_id 

	if original_target then
		target_id = original_target:GetPlayerOwnerID() 
	end

	if self.target == nil then
		if (original_target:GetTeamNumber() ~= caster:GetTeamNumber() ) then
			if original_target:IsOwnedByAnyPlayer() then 
				return 
			end

			if self.dominated_creep and not self.dominated_creep:IsNull() then
				self.dominated_creep:Kill(self, caster)
			end

			self.dominated_creep = original_target

			original_target:AddNewModifier(caster, self, "modifier_devour_helm_dominated", { base_hp = original_target:GetBaseMaxHealth() })
			original_target:SetTeam(caster:GetTeamNumber() )
			original_target:SetOwner(caster)
			original_target:SetControllableByPlayer(caster:GetPlayerOwnerID() , true)
			original_target:Heal(original_target:GetMaxHealth(), self)
			original_target:GiveMana(original_target:GetMaxMana())

			self:StartCooldown(self:GetCooldownTime() )
			return 
		end

		if PlayerResource:IsDisableHelpSetForPlayerID(caster_id, target_id ) then
			return 
		end

		original_target:AddNewModifier(caster, self, "modifier_devour_helm_active", {})
		self:EndCooldown() 
	else
		self.target:RemoveModifierByName("modifier_devour_helm_active")
		--self:StartCooldown(self:GetCooldownTime() )
		self.target = nil
	end
end
