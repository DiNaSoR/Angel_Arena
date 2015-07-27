function RollDrops(unit)
    local DropInfo = GameRules.DropTable[unit:GetUnitName()]
    if DropInfo then
        for item_name,chance in pairs(DropInfo) do
            if RollPercentage(chance) then
                -- Create the item
                local item = CreateItem(item_name, nil, nil)
                local pos = unit:GetAbsOrigin()
                local drop = CreateItemOnPositionSync( pos, item )
                local pos_launch = pos+RandomVector(RandomFloat(150,200))
                item:LaunchLoot(false, 200, 0.75, pos_launch)
                item:SetContextThink( "KillLoot", function() return KillLoot( item, drop ) end, 20 )
            end
        end
    end
end

function KillLoot( item, drop )

    if drop:IsNull() then
        return
    end

    local nFXIndex = ParticleManager:CreateParticle( "particles/items2_fx/veil_of_discord.vpcf", PATTACH_CUSTOMORIGIN, drop )
    ParticleManager:SetParticleControl( nFXIndex, 0, drop:GetOrigin() )
    ParticleManager:SetParticleControl( nFXIndex, 1, Vector( 35, 35, 25 ) )
    ParticleManager:ReleaseParticleIndex( nFXIndex )
    --EmitGlobalSound("Item.PickUpWorld")

    UTIL_Remove( item )
    UTIL_Remove( drop )
end