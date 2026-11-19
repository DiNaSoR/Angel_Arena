function ArenaBossCastAnimation(event)
    local caster = event.caster
    if not caster or caster:IsNull() or not caster:IsAlive() then return end

    StartAnimation(caster, {
        duration = 2,
        activity = ACT_DOTA_CAST_ABILITY_6,
        rate = 1,
        translate = "arcana",
    })
end
