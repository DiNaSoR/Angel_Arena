---------------------------------------------------------------------------
-- Angel Arena Limit Speed Break
---------------------------------------------------------------------------
modifier_test_anim = modifier_test_anim or class({})

function modifier_test_anim:IsHidden() return false end
function modifier_test_anim:IsPurgeException() return true end
--function modifier_test_anim:IsStunDebuff() return true end

function modifier_test_anim:CheckState()
   --local state = {[MODIFIER_STATE_STUNNED] = true} 

   --return state 
end

function modifier_test_anim:GetEffectName()
    --return "particles/generic_gameplay/generic_stunned.vpcf"
end

function modifier_test_anim:GetEffectAttachType()
    --return PATTACH_OVERHEAD_FOLLOW
end

function modifier_test_anim:DeclareFunctions()
    local decFuncs = {MODIFIER_PROPERTY_OVERRIDE_ANIMATION}

    return decFuncs
end

function modifier_test_anim:GetOverrideAnimation()
print("shadow dance")
    return ACT_DOTA_SHADOW_DANCE
end
