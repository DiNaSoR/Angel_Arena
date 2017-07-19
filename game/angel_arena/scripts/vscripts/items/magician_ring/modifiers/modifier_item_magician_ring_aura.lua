modifier_item_magician_ring_aura = class({})
--------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:IsDebuff()
	return true
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:DestroyOnExpire()
	return true
end
--------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:GetTexture()
	return "custom/magician_ring"
end

------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
	}

	return funcs 
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:OnDeath( keys )
	if IsServer() then
		local dead_hero = keys.unit 

		if dead_hero ~= self:GetParent() then return end
		if not dead_hero:IsRealHero() then return end 

		local killer = keys.attacker 
		local caster = self:GetCaster()
		local ability = self:GetAbility()

		local max_stacks = ability:GetSpecialValueFor("max_stacks") or 0

		local bonus_stack = 0

		if killer == caster then
			return
		else 
			bonus_stack = ability:GetSpecialValueFor("stack_per_assist") or 0
		end

		local cur_stack = caster:GetModifierStackCount("modifier_item_magician_ring_buff", caster) or 0
		cur_stack = cur_stack + bonus_stack
        print("[hkilled] cur_stack = ", cur_stack, bonus_stack)
        if cur_stack > max_stacks then
           cur_stack = max_stacks
        end

        caster:RemoveModifierByName("modifier_item_magician_ring_buff")

        caster:AddNewModifier(caster, ability, "modifier_item_magician_ring_buff", {}) 
        caster:SetModifierStackCount("modifier_item_magician_ring_buff", caster, cur_stack)

	end
end


--------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:OnCreated( kv )

end

---------------------------------------------------------------------------------

function modifier_item_magician_ring_aura:OnDestroy()

end