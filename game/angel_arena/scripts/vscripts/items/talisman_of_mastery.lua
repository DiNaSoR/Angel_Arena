gun_joe_rapid = class({})
LinkLuaModifier( "modifier_gun_joe_rapid", 'heroes/gun_joe/modifiers/modifier_gun_joe_rapid', LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------

local talent_name = "gun_joe_special_bonus_rapid_cd"

function gun_joe_rapid:GetIntrinsicModifierName()
	return "modifier_gun_joe_rapid"
end


function gun_joe_rapid:GetCooldown( nLevel )
	if IsServer() then
		local cd = self:GetSpecialValueFor("cooldown")

		if self:GetCaster():HasAbility(talent_name) then
			local talent_ability = self:GetCaster():FindAbilityByName(talent_name)
			
			cd = cd + talent_ability:GetSpecialValueFor("value")

			CustomNetTables:SetTableValue( "heroes", "gun_joe_rapid", {cooldown = cd } )

			return cd
		end
		return cd
	else
		local net_table = CustomNetTables:GetTableValue( "heroes", "gun_joe_rapid" )

		if(net_table) then
			return net_table.cooldown
		else
			return self.BaseClass.GetCooldown(self, nLevel)
		end
	end
end
