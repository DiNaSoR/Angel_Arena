function Refresh(event)
    local caster = event and event.caster
    if not caster or caster:IsNull() then
        return
    end

    for i = 0, caster:GetAbilityCount() - 1 do
        local ability = caster:GetAbilityByIndex(i)
        if ability and not ability:IsNull() and ability ~= event.ability then
            ability:EndCooldown()
        end
    end
end
