if CreepPower == nil then
  CreepPower = class({})
end

function CreepPower:GetPowerForMinute (minute)
  local multFactor = 1
                        --HP        MANA      DMG       ARM       GOLD      EXP
  if minute == 0 then
    return {    1,        1.0,      1.0,      1.0,      1.0,      1.0,      1.0 * self.numPlayersXPFactor}
  end

  if minute > CREEP_GROWTH then
    multFactor = 1.5 ^ (minute - CREEP_GROWTH)
  end

  return {
    minute,                                   -- minute
    (15 * ((minute / 100) ^ 4) - 45 * ((minute/100) ^ 3) + 25 * ((minute/100) ^ 2) - 0 * (minute/100)) + 0.5,   -- hp
    (15 * ((minute / 100) ^ 4) - 45 * ((minute/100) ^ 3) + 25 * ((minute/100) ^ 2) - 0 * (minute/100)) + 0.5,   -- mana
    (80 * ((minute / 100) ^ 4) - 180 * ((minute/100) ^ 3) + 100 * ((minute/100) ^ 2) - 0 * (minute/100)) + 0.5,     -- damage
    (minute / 54) ^ 2 + minute / 20 + 0.5,       -- armor
    (13 * minute^2 + 375 * minute + 7116)/7116,                         -- gold
    ((25 * minute^2 + 67 * minute + 2500) / 2500) * self.numPlayersXPFactor * multFactor -- xp
  }
end

function CreepPower:Init ()
  local maxTeamPlayerCount = 10
  self.numPlayersXPFactor = 1
end
