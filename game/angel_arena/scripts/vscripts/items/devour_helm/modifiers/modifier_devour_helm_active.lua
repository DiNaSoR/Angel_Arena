modifier_devour_helm_active = class({})
--------------------------------------------------------------------------------

function modifier_devour_helm_active:IsHidden()
	return false
end

--------------------------------------------------------------------------------

function modifier_devour_helm_active:GetTexture()
	return "custom/devour_helm"
end

--------------------------------------------------------------------------------

function modifier_devour_helm_active:IsPurgable()
	return false
end


--------------------------------------------------------------------------------

function modifier_devour_helm_active:DestroyOnExpire()
	return true
end

--------------------------------------------------------------------------------

function modifier_devour_helm_active:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

--------------------------------------------------------------------------------

function modifier_devour_helm_active:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVISIBLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_FROZEN] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
 
	return state
end

--------------------------------------------------------------------------------

function modifier_devour_helm_active:OnCreated( kv )

	self.caster = self:GetCaster() 
	self.parent = self:GetParent()
	local ability = self:GetAbility()
	
	if ability then
		ability.target = self:GetParent()
	else
		self:Destroy() 
		return
	end

	if IsServer() then
		self.parent:AddNoDraw() 

		Timers:CreateTimer(0.1, function() 
			if not self or not self.caster or not self.parent or not self.caster:IsAlive() or not self:GetAbility() then 
				
				if self and not self:IsNull() then
					self:Destroy() 
				end

				return nil 
			end 

			local flag = false 

			for i = 0, 5 do
				if self.caster:GetItemInSlot(i) == self:GetAbility() then
					flag = true
				end
			end

			for i = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
				if self.caster:GetItemInSlot(i) == self:GetAbility() then
					flag = true
				end
			end

			if not flag then 
				if self then
					self:Destroy() 
				end
				return nil
			end

			self.parent:SetAbsOrigin(self.caster:GetAbsOrigin())

			return 0.1
		end)
	end
end

--------------------------------------------------------------------------------

function modifier_devour_helm_active:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ORDER ,
	}

	return funcs
end

---------------------------------------------------------------------------------

function modifier_devour_helm_active:OnOrder(kv)
	if IsServer() then
		if kv.unit ~= self:GetParent() then
        	return
        end

        local ability = self:GetAbility()

        if ability then
        	ability.target = nil
        end

        self:Destroy() 
	end
end

---------------------------------------------------------------------------------

function modifier_devour_helm_active:OnDestroy()
	if IsServer() then
		self.parent:RemoveNoDraw() 
	end

	local ability = self:GetAbility()

	if ability then
		ability.target = nil 
		if IsServer() then
			local cd = ability:GetCooldownTime()
			
			if cd == 0 then
				cd = ability:GetCooldown(ability:GetLevel() )
			end

			ability:StartCooldown(cd)
		end
	end

	self.caster = nil
	self.parent = nil
end