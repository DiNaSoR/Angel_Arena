-- Angel Arena Blackstars / Chronophylos
Gold = Gold or class({})

local GOLD_CAP = 90000
local overflow = {}

local function GetPlayerID(unit)
  local playerID = UnitVarToPlayerID(unit)
  if playerID and PlayerResource:IsValidPlayerID(playerID) then
    return playerID
  end
end

local function PublishGold(playerID, total)
  local balances = PlayerTables:GetTableValue("gold", "gold")
  if balances[playerID] ~= total then
    balances[playerID] = total
    PlayerTables:SetTableValue("gold", "gold", balances)
  end
end

local function UpdateGold(playerID, native, total, reliable, reason)
  local desired = math.min(GOLD_CAP, total)
  if desired ~= native then
    PlayerResource:ModifyGold(playerID, desired - native, reliable == true, reason or DOTA_ModifyGold_Unspecified)
  end

  -- Keep only the portion above the engine-facing balance on the server.
  overflow[playerID] = math.max(0, total - GOLD_CAP)
  PublishGold(playerID, PlayerResource:GetGold(playerID) + overflow[playerID])
end

function Gold:Init()
  Timers:CreateTimer(1, Dynamic_Wrap(self, "Think"), self)
end

function Gold:Think()
  local state = GameRules:State_Get()
  if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS or state == DOTA_GAMERULES_STATE_PRE_GAME then
    for _, playerID in ipairs(PlayerResource:GetAllTeamPlayerIDs()) do
      if PlayerResource:IsValidPlayerID(playerID) then
        local native = PlayerResource:GetGold(playerID)
        UpdateGold(playerID, native, native + (overflow[playerID] or 0))
      end
    end
  end
  return 0.2
end

function Gold:ClearGold(unit)
  self:SetGold(unit, 0)
end

function Gold:SetGold(unit, total)
  local playerID = GetPlayerID(unit)
  if playerID then
    UpdateGold(playerID, PlayerResource:GetGold(playerID), math.max(0, math.floor(total)))
  end
end

function Gold:ModifyGold(unit, amount, reliable, reason)
  local playerID = GetPlayerID(unit)
  if playerID then
    local native = PlayerResource:GetGold(playerID)
    local total = math.max(0, native + (overflow[playerID] or 0) + math.floor(amount))
    UpdateGold(playerID, native, total, reliable, reason)
  end
end

function Gold:RemoveGold(unit, amount)
  self:ModifyGold(unit, -amount)
end

function Gold:AddGold(unit, amount)
  self:ModifyGold(unit, amount)
end

function Gold:AddGoldWithMessage(unit, amount, playerID)
  playerID = GetPlayerID(playerID or unit)
  if playerID then
    local player = PlayerResource:GetPlayer(playerID)
    SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, unit, math.floor(amount), player)
    self:AddGold(playerID, amount)
  end
end

function Gold:GetGold(unit)
  local playerID = GetPlayerID(unit)
  return playerID and PlayerResource:GetGold(playerID) + (overflow[playerID] or 0) or 0
end
