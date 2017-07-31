---------------------------------------------------------------------------
-- Angel Arena Limit Speed Break
---------------------------------------------------------------------------
modifier_aa_speed_limit_break = class({})
function modifier_aa_speed_limit_break:GetModifierMoveSpeed_Max() return 1000 end
function modifier_aa_speed_limit_break:GetModifierMoveSpeed_Limit() return 1000 end
function modifier_aa_speed_limit_break:IsHidden() return false end

function modifier_aa_speed_limit_break:OnCreated()
		--self:StartIntervalThink(1.0)
end

function modifier_aa_speed_limit_break:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_MAX,
        MODIFIER_PROPERTY_MOVESPEED_LIMIT,
    }

    return funcs
end

function modifier_aa_speed_limit_break:OnIntervalThink()
--[[local caster = self:GetParent()
local hero = caster:GetUnitName()

	if 		hero == "npc_dota_hero_furion" and caster:HasModifier("modifier_invoker_ghost_walk_self")then
			print("its Furion and he has Ghost walk buff")
	elseif 	hero == "npc_dota_hero_furion" and not caster:HasModifier("modifier_invoker_ghost_walk_self") then
			print("its Furion but NO Ghost walk buff")
			self:Destroy()
	else
			print("its NOT Furion and has NO Ghost walk buff")
	end]]
end



