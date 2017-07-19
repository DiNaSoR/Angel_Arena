modifier_spiked_armor_active = class({})
--------------------------------------------------------------------------------

function modifier_spiked_armor_active:IsHidden()
	return false
end

--------------------------------------------------------------------------------

function modifier_spiked_armor_active:IsPurgable()
	return false
end

--------------------------------------------------------------------------------

function modifier_spiked_armor_active:DestroyOnExpire()
	return true
end


function modifier_spiked_armor_active:GetEffectName()
    return "particles/items_fx/blademail_b.vpcf"
end

function modifier_spiked_armor_active:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

--------------------------------------------------------------------------------

function modifier_spiked_armor_active:OnCreated( kv )

end
--[[
function modifier_spiked_armor_active:GetAttributes() 
    return MODIFIER_ATTRIBUTE_MULTIPLE + MODIFIER_ATTRIBUTE_PERMANENT
end]]

--------------------------------------------------------------------------------

function modifier_spiked_armor_active:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}

	return funcs
end

--------------------------------------------------------------------------------

local return_damage = 200 / 100 -- 200%

function modifier_spiked_armor_active:OnTakeDamage( params )
	if IsServer() then
        if params.unit ~= self:GetParent() then
        	return
        end

        if testflag(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return end 

        ApplyDamage({
            victim = params.attacker,
            attacker = params.unit,
            damage = params.damage * return_damage,
            damage_type = params.damage_type,
            ability = self:GetAbility(),
            damage_flags = DOTA_DAMAGE_FLAG_REFLECTION,
        })

	end
	return 0
end

function testflag(set, flag)
  return set % (2*flag) >= flag
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------