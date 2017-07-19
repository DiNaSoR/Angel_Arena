if CreepPower == nil then
  --DebugPrint ( 'Creating new CreepPower object...' )
  CreepPower = class({})
end


function CreepPower:GetPowerForMinute (minute)
  local multFactor = 1



  if minute == 0 then
    return {   0,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0 * self.numPlayersXPFactor}
  end

--local GameLength = CustomNetTables:GetTableValue('team_scores', 'limit').name
--print(minute)
--print(CREEP_GROWTH)
  if minute > CREEP_GROWTH then
    multFactor = 1 ^ (minute - CREEP_GROWTH)
  end

  return {
    minute,                                   -- minute
    (15 * ((minute / 100) ^ 4) - 45 * ((minute/100) ^ 3) + 25 * ((minute/100) ^ 2) - 0 * (minute/100)) + 1,   -- hp
    (15 * ((minute / 100) ^ 4) - 45 * ((minute/100) ^ 3) + 25 * ((minute/100) ^ 2) - 0 * (minute/100)) + 1,   -- mana
    (80 * ((minute / 100) ^ 4) - 180 * ((minute/100) ^ 3) + 100 * ((minute/100) ^ 2) - 0 * (minute/100)) + 1,     -- damage
    (minute / 54) ^ 2 + minute / 20 + 1,       -- armor
    (13 * minute^2 + 375 * minute + 7116)/7116,                         -- gold
    ((25 * minute^2 + 67 * minute + 2500) / 2500) * self.numPlayersXPFactor * multFactor -- xp
  }
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10 -- TODO: Make maxTeamPlayerCount based on values set in settings.lua (?)
  self.numPlayersXPFactor = 1 -- PlayerResource:GetTeamPlayerCount() / maxTeamPlayerCount
end
