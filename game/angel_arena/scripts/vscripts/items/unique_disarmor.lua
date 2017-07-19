local unique_modifier_list = {}

function ApplyDisarmorModifier( keys )
	local ability 		= keys.ability
	local caster 		= keys.caster
	local target 		= keys.target
	local modifier_name = keys.ModifierName
	local is_datadriven = keys.is_datadriven
	local duration 		= keys.Duration
	
	if(not unique_modifier_list[modifier_name]) then
		table.insert(unique_modifier_list, modifier_name)
	end

	for _, sModifier in pairs(unique_modifier_list) do
		if target:HasModifier(sModifier) and sModifier ~= modifier_name then
			return
		end
	end

	if(is_datadriven) then
		ability:ApplyDataDrivenModifier(caster, target, modifier_name, {duration = duration})
	else
		target:AddNewModifier(caster, ability, modifier_name, duration)
	end

end