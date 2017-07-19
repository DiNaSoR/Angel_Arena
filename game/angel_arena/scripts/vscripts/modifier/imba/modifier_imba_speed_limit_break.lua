--[[	Author: Firetoad
		Date: 29.09.2015	]]

--[[if modifier_imba_speed_limit_break == nil then
	modifier_imba_speed_limit_break = class({})
	print(modifier_imba_speed_limit_break)
end

function modifier_imba_speed_limit_break:OnCreated(kv)	
print("OnCreated")
	--if IsServer() then
	--print("server is")
	--end
	print("not server")
end

function modifier_imba_speed_limit_break:DeclareFunctions()
print("DeclareFunctions")
	local funcs = {
	MODIFIER_PROPERTY_MOVESPEED_MAX
	}
	print(MODIFIER_PROPERTY_MOVESPEED_MAX)
 
	return funcs
end

function modifier_imba_speed_limit_break:GetModifierMoveSpeed_Max()
print("GetModifierMoveSpeed_Max")
	return 1200
end
function modifier_imba_speed_limit_break:GetPriority()
print("GetPriority")
    return MODIFIER_PRIORITY_HIGH end
	print(MODIFIER_PRIORITY_HIGH)
   
function modifier_imba_speed_limit_break:IsHidden()
print(IsHidden)
	return true
end]]

----------------------------------------------------------------

-------------------
modifier_imba_speed_limit_break = class({})

function modifier_imba_speed_limit_break:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_MAX,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }
	print(MODIFIER_PROPERTY_MOVESPEED_MAX)

    return funcs
end

function modifier_imba_speed_limit_break:GetModifierMoveSpeed_Max( params )
    return 1000
end

function modifier_imba_speed_limit_break:GetModifierMoveSpeed_Limit( params )
    return 1000
end

function modifier_imba_speed_limit_break:IsHidden()
    return false
end
