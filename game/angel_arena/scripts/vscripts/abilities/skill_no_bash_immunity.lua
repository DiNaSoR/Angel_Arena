-- In a file named "skill_no_bash_immunity.lua"
skill_no_bash_immunity = class({})
LinkLuaModifier("modifier_no_bash_immunity", "abilities/skill_no_bash_immunity", LUA_MODIFIER_MOTION_NONE)

function skill_no_bash_immunity:GetIntrinsicModifierName()
    return "modifier_no_bash_immunity"
end

modifier_no_bash_immunity = class({})

function modifier_no_bash_immunity:IsHidden()
    return true
end

function modifier_no_bash_immunity:IsDebuff()
    return false
end

function modifier_no_bash_immunity:IsPurgable()
    return false
end

function modifier_no_bash_immunity:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
        MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING
    }

    return funcs
end

function modifier_no_bash_immunity:GetAbsoluteNoDamagePhysical(params)
    if IsServer() then
        if params.inflictor then
            if params.inflictor:GetAbilityName() == "spirit_breaker_greater_bash" or params.inflictor:GetAbilityName() == "faceless_void_time_lock" or params.inflictor:GetAbilityName() == "slardar_bash" then
                return 1
            end
        end
    end

    return 0
end

function modifier_no_bash_immunity:GetAbsoluteNoDamageMagical(params)
    return self:GetAbsoluteNoDamagePhysical(params)
end

function modifier_no_bash_immunity:GetAbsoluteNoDamagePure(params)
    return self:GetAbsoluteNoDamagePhysical(params)
end

function modifier_no_bash_immunity:GetModifierStatusResistanceStacking(params)
    return 100
end
