modifier_item_magician_ring = class({})
--------------------------------------------------------------------------------

function modifier_item_magician_ring:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetModifierAura()
    return "modifier_item_magician_ring_aura"
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:IsAura()
    return true
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetAuraSearchTeam()
    return DOTA_UNIT_TARGET_TEAM_ENEMY
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetAuraSearchType()
    return DOTA_UNIT_TARGET_HERO
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetAuraRadius()
    return self:GetAbility():GetSpecialValueFor("aura_radius") or 0
end


--------------------------------------------------------------------------------

function modifier_item_magician_ring:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:DestroyOnExpire()
	return false
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:OnCreated( kv )

end

function modifier_item_magician_ring:OnDestroy( kv )
    self:GetCaster():RemoveModifierByName("modifier_item_magician_ring_buff")
end

function modifier_item_magician_ring:GetAttributes() 
    return MODIFIER_ATTRIBUTE_PERMANENT
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MANA_REGEN_PERCENTAGE,  -- GetModifierPercentageManaRegen
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,   -- GetModifierPhysicalArmorBonus
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
        MODIFIER_PROPERTY_CAST_RANGE_BONUS,       -- GetModifierCastRangeBonus
        MODIFIER_EVENT_ON_HERO_KILLED,
		--MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetModifierConstantHealthRegen( params )
	return self:GetAbility():GetSpecialValueFor("bonus_hp_regen") or 0
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetModifierPercentageManaRegen( params )
	return self:GetAbility():GetSpecialValueFor("bonus_manaregen") or 0
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetModifierPhysicalArmorBonus( params )
    return self:GetAbility():GetSpecialValueFor("bonus_armor") or 0
end

--------------------------------------------------------------------------------

function modifier_item_magician_ring:GetModifierCastRangeBonus( params )
    return self:GetAbility():GetSpecialValueFor("bonus_cast_range") or 0
end
--------------------------------------------------------------------------------

function modifier_item_magician_ring:OnHeroKilled( keys )
    if IsServer() then
        local dead_hero = keys.target 
        local killer = keys.attacker 
        local caster = self:GetCaster()
        local ability = self:GetAbility()

        if not dead_hero:IsRealHero() then return end 
        if killer ~= self:GetParent() then return end 

        local max_stacks = ability:GetSpecialValueFor("max_stacks") or 0

        local bonus_stack = ability:GetSpecialValueFor("stack_per_kill") or 0

        local cur_stack = caster:GetModifierStackCount("modifier_item_magician_ring_buff", caster) or 0

        cur_stack = cur_stack + bonus_stack
        print("[mekilled] cur_stack = ", cur_stack, bonus_stack)
        if cur_stack > max_stacks then
           cur_stack = max_stacks
        end

        caster:RemoveModifierByName("modifier_item_magician_ring_buff")

        caster:AddNewModifier(caster, ability, "modifier_item_magician_ring_buff", {}) 
        caster:SetModifierStackCount("modifier_item_magician_ring_buff", caster, cur_stack)
    end
end

--------------------------------------------------------------------------------
