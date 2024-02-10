---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
--NUMBERS_OF_FORGED_SPIRIT = 5

---------------------------------------------------------------------------
-- Ability used Index
---------------------------------------------------------------------------
function abilityusedindex(player, hero, heroname, abilityname, herolevel)
    furionforge(player, hero, heroname, abilityname, herolevel)
end

---------------------------------------------------------------------------
-- Ability Furion Forge
---------------------------------------------------------------------------
function furionforge(player, hero, heroname, abilityname, herolevel)
    if heroname == "npc_dota_hero_furion" and abilityname == "skill_aa_invoker_forge_spirit" then
        local ability = hero:FindAbilityByName(abilityname)
        if not ability then
            return
        end

        local ability_level = ability:GetLevel()
        local NUMBERS_OF_FORGED_SPIRIT = ability_level

        for i = 1, NUMBERS_OF_FORGED_SPIRIT do
            local summon_point = RotatePosition(hero:GetAbsOrigin(), QAngle(0, (i - 1) * 360 / 10, 0), hero:GetAbsOrigin() + hero:GetForwardVector() * 80)
            local mobs = CreateUnitByName("npc_dota_creature_boomber", summon_point, true, hero, hero, hero:GetTeamNumber())

            -- Prevent nearby units from getting stuck
            Timers:CreateTimer(FrameTime(), function()
                ResolveNPCPositions(summon_point, 128)    
            end)

            mobs:SetControllableByPlayer(hero:GetPlayerID(), true)
            mobs:SetRenderColor(75, 0, 30)
            mobs:SetBaseMaxHealth(500)
            mobs:SetMaxHealth(500)
            mobs:SetHealth(500)
            mobs:SetBaseDamageMin(100)
            mobs:SetBaseDamageMax(200)
            local mod_kill = mobs:AddNewModifier(mobs, nil, "modifier_kill", {duration = 10})
        end
    end
end


---------------------------------------------------------------------------
-- Ability Test
---------------------------------------------------------------------------
function furionstupid(player, hero, heroname, abilityname, herolevel)
end
