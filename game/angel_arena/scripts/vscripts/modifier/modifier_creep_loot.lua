modifier_creep_loot = class({})

function modifier_creep_loot:IsHidden() return true end
function modifier_creep_loot:IsPurgable() return false end

function modifier_creep_loot:OnCreated(keys)
    if IsServer() then
        self.campID = tonumber(keys.campID)
        self.difficulty = tonumber(keys.difficulty)
    end
end

function modifier_creep_loot:DeclareFunctions()
    return { MODIFIER_EVENT_ON_DEATH, MODIFIER_EVENT_ON_DOMINATED }
end

function modifier_creep_loot:OnDeath(event)
    if not IsServer() or self.dropRolled or GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
        return
    end
    local parent = self:GetParent()
    local attacker = event.attacker
    if event.unit ~= parent or parent:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS
        or not attacker or not IsValidEntity(attacker) or not attacker.GetTeamNumber then
        return
    end

    local team = attacker:GetTeamNumber()
    if team ~= DOTA_TEAM_GOODGUYS and team ~= DOTA_TEAM_BADGUYS then return end

    self.dropRolled = true
    local item = CreepItemDrop:RandomDropItemName(self.campID, self.difficulty)
    if item then
        CreepItemDrop:CreateDrop(item, parent:GetAbsOrigin())
    end
end

function modifier_creep_loot:OnDominated(event)
    if IsServer() and event.unit == self:GetParent() then
        self:Destroy()
    end
end
