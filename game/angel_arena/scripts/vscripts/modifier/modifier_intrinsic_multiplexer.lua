require('libraries/fun')()

modifier_intrinsic_multiplexer = class(ModifierBaseClass)

function modifier_intrinsic_multiplexer:IsHidden()
  return true
end

function modifier_intrinsic_multiplexer:IsPurgable()
  return false
end

function modifier_intrinsic_multiplexer:GetAttributes()
  return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_intrinsic_multiplexer:OnCreated()
  self.modifiers = {}
  if IsServer() then
    Timers:CreateTimer(0.1, function ()
      self:CreateModifiers()
    end)
  end
end

function modifier_intrinsic_multiplexer:OnRefresh()
  self:DestroyModifiers()
  self:CreateModifiers()
end

function modifier_intrinsic_multiplexer:OnDestroy()
  self:DestroyModifiers()
end

function modifier_intrinsic_multiplexer:CreateModifiers()
  -- Exit if self has been deleted because for some reason this happens with Tempest Double
  if self:IsNull() then
    return
  end

  local hero = self:GetParent()
  if not hero or not hero.AddNewModifier then
    return
  end
  local caster = self:GetCaster()
  local ability = self:GetAbility()
  if not ability.GetIntrinsicModifierNames then
    print('Ability does not have a GetIntrinsicModifierNames method')
    return
  end
  local modifiers = ability:GetIntrinsicModifierNames(self)
  iter(modifiers):each(function (modifierName)
    self.modifiers[modifierName] = hero:AddNewModifier(caster, ability, modifierName, {})
  end)
end

function modifier_intrinsic_multiplexer:DestroyModifiers()
  iter(self.modifiers):each(function (name, mod)
    if mod and not mod:IsNull() then
      mod:Destroy()
    end
  end)
  self.modifiers = {}
end
