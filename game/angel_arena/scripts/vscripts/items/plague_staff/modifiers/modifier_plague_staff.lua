modifier_plague_staff = class({})
--------------------------------------------------------------------------------

function modifier_plague_staff:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_plague_staff:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_plague_staff:DestroyOnExpire()
	return false
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetAttributes() 
	return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT
end

--------------------------------------------------------------------------------

function modifier_plague_staff:OnCreated( kv )

end

--------------------------------------------------------------------------------

function modifier_plague_staff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

	return funcs
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierConstantHealthRegen( params )
	return self:GetAbility():GetSpecialValueFor("bonus_hpregen") or 0
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierBonusStats_Strength( params )
	return self:GetAbility():GetSpecialValueFor("bonus_str") or 0
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierBonusStats_Agility( params )
	return self:GetAbility():GetSpecialValueFor("bonus_agi") or 0
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierBonusStats_Intellect( params )
	return self:GetAbility():GetSpecialValueFor("bonus_int") or 0
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierPreAttack_BonusDamage( params )
	return self:GetAbility():GetSpecialValueFor("bonus_damage") or 0
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierSpellAmplify_Percentage( params )
	return self:GetAbility():GetSpecialValueFor("bonus_spellamp") or 0
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierPhysicalArmorBonus( params )
	return self:GetAbility():GetSpecialValueFor("bonus_armor") or 0
end

--------------------------------------------------------------------------------

function modifier_plague_staff:GetModifierManaBonus( params )
	return self:GetAbility():GetSpecialValueFor("bonus_mana") or 0
end

--------------------------------------------------------------------------------
local exception_list = {
	"item_slice_amulet",
	"item_static_amulet",
	"zuus_static_field",
	"item_plague_staff",
	"warlock_fatal_bonds",
	"item_bfury",
	"item_bfury_2",
	"item_demons_fury",
	"item_holy_book",
	"item_holy_book_2",
	"item_burning_book",
}

function modifier_plague_staff:OnTakeDamage( params )
	  if IsServer() then
        if params.attacker ~= self:GetParent() then
        	return
        end

        if params.damage_type ~= DAMAGE_TYPE_MAGICAL and params.damage_type ~= DAMAGE_TYPE_PURE and params.inflictor == nil then return end

        if params.damage_flags == DOTA_DAMAGE_FLAG_REFLECTION then
			return 
		end

        if not RollPercentage(self:GetAbility():GetSpecialValueFor("chance")) then return end
		
		if params.inflictor then
			for _, x in pairs(exception_list) do
				if x == params.inflictor:GetName() then
					print("EROR CRIT STUFF")
					return
				end
			end
		end


   		ApplyDamage({
   			victim = params.unit,
   			attacker = params.attacker,
   			damage = (((self:GetAbility():GetSpecialValueFor("magical_crit") or 0) - 100) / 100) * params.damage,
   			damage_type = params.damage_type,
   			ability = self:GetAbility(),
   			damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
   		})
   		print("deal damage = ", (((self:GetAbility():GetSpecialValueFor("magical_crit") or 0) - 100) / 100) * params.damage)
   		SendOverheadEventMessage( params.unit, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE , params.attacker, (((self:GetAbility():GetSpecialValueFor("magical_crit") or 0) - 100) / 100) * params.damage, nil )
	end
	return 0
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------