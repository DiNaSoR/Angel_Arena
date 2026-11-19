LinkLuaModifier("modifier_aa_magic_stick_aura", "items/imba/item_stick", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_aa_magic_stick_charge", "items/imba/item_stick", LUA_MODIFIER_MOTION_NONE)

item_imba_magic_stick = class({})

function item_imba_magic_stick:GetIntrinsicModifierName()
    return "modifier_aa_magic_stick_aura"
end

function item_imba_magic_stick:OnSpellStart()
    if not IsServer() then return end

    local charges = self:GetCurrentCharges()
    if charges <= 0 then return end

    local caster = self:GetCaster()
    local restore = charges * self:GetSpecialValueFor("restore_per_charge")
    self:SetCurrentCharges(0)
    caster:Heal(restore, self)
    caster:GiveMana(restore)
    caster:EmitSound("DOTA_Item.MagicStick.Activate")
    local effect = ParticleManager:CreateParticle("particles/items2_fx/magic_stick.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:ReleaseParticleIndex(effect)
end

modifier_aa_magic_stick_aura = class({})

function modifier_aa_magic_stick_aura:IsHidden() return true end
function modifier_aa_magic_stick_aura:IsPurgable() return false end
function modifier_aa_magic_stick_aura:IsAura() return true end
function modifier_aa_magic_stick_aura:GetModifierAura() return "modifier_aa_magic_stick_charge" end
function modifier_aa_magic_stick_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_aa_magic_stick_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_aa_magic_stick_aura:GetAuraSearchFlags()
    return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_aa_magic_stick_aura:GetAuraRadius()
    local item = self:GetAbility()
    return item and item:GetSpecialValueFor("charge_radius") or 0
end

modifier_aa_magic_stick_charge = class({})

function modifier_aa_magic_stick_charge:IsHidden() return true end
function modifier_aa_magic_stick_charge:IsDebuff() return true end
function modifier_aa_magic_stick_charge:IsPurgable() return false end
function modifier_aa_magic_stick_charge:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_aa_magic_stick_charge:DeclareFunctions()
    return { MODIFIER_EVENT_ON_SPENT_MANA }
end

function modifier_aa_magic_stick_charge:OnSpentMana(event)
    if not IsServer() or event.unit ~= self:GetParent() or not event.ability then return end

    local mana = event.cost or event.ability:GetManaCost(-1)
    if mana <= 0 then return end

    local item = self:GetAbility()
    local holder = self:GetCaster()
    if not item or item:IsNull() or item:IsInBackpack() or not holder or not holder:IsAlive() then return end

    -- The aura can linger briefly after a unit leaves its range.
    local caster = event.unit
    if caster:GetTeamNumber() == holder:GetTeamNumber() then return end
    local distance = (holder:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
    if distance > item:GetSpecialValueFor("charge_radius") then return end

    local charges = item:GetCurrentCharges()
    local limit = item:GetSpecialValueFor("max_charges")
    if charges < limit then
        item:SetCurrentCharges(charges + 1)
    end
end
