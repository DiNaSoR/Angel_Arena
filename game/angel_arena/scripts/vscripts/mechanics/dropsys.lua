--DropSys
function RollDrops(unit)
    local DropInfo = GameRules.DropTable[unit:GetUnitName()]
    if DropInfo then
        print("Rolling Drops for "..unit:GetUnitName())
        for k,ItemTable in pairs(DropInfo) do
            -- If its an ItemSet entry, decide which item to drop
            local item_name
            if ItemTable.ItemSets then
                -- Count how many there are to choose from
                local count = 0
                for i,v in pairs(ItemTable.ItemSets) do
                    count = count+1
                end
                local random_i = RandomInt(1,count)
                item_name = ItemTable.ItemSets[tostring(random_i)]
            else
                item_name = ItemTable.Item
            end
            local chance = ItemTable.Chance or 100
            local max_drops = ItemTable.Multiple or 1
            for i=1,max_drops do
                print("Rolling chance "..chance)
                if RollPercentage(chance) then
                    print("Creating "..item_name)
                    local item = CreateItem(item_name, nil, nil)
                    item:SetPurchaseTime(0)
                    local pos = unit:GetAbsOrigin()
                    local drop = CreateItemOnPositionSync( pos, item )
                    local pos_launch = pos+RandomVector(RandomFloat(150,200))
                    item:LaunchLoot(false, 200, 0.75, pos_launch)
                    item:SetContextThink( "KillLoot", function() return KillLoot( item, drop ) end, 40 )
                end
            end
        end
    end
end

--KillLoot
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