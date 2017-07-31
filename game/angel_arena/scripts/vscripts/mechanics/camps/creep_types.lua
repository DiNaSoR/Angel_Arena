---------------------------------------------------------------------------
-- Settings
-- "creep name", Health, Mana, Damage, Armor, Gold Bounty, Exp Bounty
---------------------------------------------------------------------------
CreepTypes = {
-------------------------------1 "easy camp"-------------------------------
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   10,  40},
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    10,  50}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    10,  55},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   10,  40}
    },
    {
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   10,  40},
      {"npc_dota_neutral_kobold_tunneler",          480,    0,  12,    1,    10,  50}
    },
    {
      {"npc_dota_neutral_kobold_taskmaster",        560,    0,  16,    1,    10,  55},
      {"npc_dota_neutral_kobold",                   280,    0,  10,   0.5,   10,  40}
    },
    {
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    10,  60},
      {"npc_dota_neutral_ghost",                    480,    0,  12,    1,    10,  60}
    }
  },
-------------------------------2 "medium camp-------------------------------
  {
    {                                              --HP   MANA  DMG   ARM   GOLD  EXP
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,   50,   71},
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,   50,   71},
      {"npc_dota_neutral_harpy_scout",              440,    0,  40,    1,   50,   30}
    },
    {
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,   50,   71},
      {"npc_dota_neutral_harpy_storm",              560,  320,  24,    2,   50,   71}
    },
    {
      {"npc_dota_neutral_polar_furbolg_champion",   480,    0,  28,    2,    50,   63},
      {"npc_dota_neutral_polar_furbolg_champion",   800,    0,  28,    2,    50,   63}
    }
  },
-------------------------------3 "hard camp"---------------------------------
  {
    {                                               --HP   MANA   DMG   ARM  GOLD   EXP
      {"npc_dota_neutral_granite_golem",            1600, 400,   44,   3,   100,    49},
      {"npc_dota_neutral_rock_golem",               1200, 240,   28,   2,   100,    49}
    },
    {
      {"npc_dota_neutral_prowler_acolyte",          1600, 400,   44,   3,   100,    49},
      {"npc_dota_neutral_prowler_shaman",           1200, 240,   28,   2,   100,    49}
    },
    {
      {"npc_dota_neutral_rock_golem",               1600, 400,   44,   3,   100,    49},
      {"npc_dota_neutral_small_thunder_lizard",     1200, 240,   28,   2,   100,    49}
    },
    {
      {"npc_dota_neutral_jungle_stalker",           1600, 400,   44,   3,   100,    49},
      {"npc_dota_neutral_big_thunder_lizard",       1200, 240,   28,   2,   100,    49}
    },
    {
      {"npc_dota_neutral_black_drake",              1240, 160,   24,   3,   100,    36},
      {"npc_dota_neutral_black_dragon",             1240, 160,   24,   3,   100,    36},
      {"npc_dota_neutral_gnoll_assassin",           1200, 480,   56,   5,   100,    50}
    },
    {
      {"npc_dota_neutral_gnoll_assassin",           1240, 160,   24,   3,   100,    36},
      {"npc_dota_neutral_gnoll_assassin",           1200, 480,   56,   5,   100,    50}
    },
    {
      {"npc_dota_neutral_centaur_khan",             1640, 160,   24,   3,   100,    36},
      {"npc_dota_neutral_centaur_outrunner",        1200, 480,   56,   5,   100,    50}
    },
    {
      {"npc_dota_neutral_dark_troll_warlord",       1840,   0,   80,   3,   100,    98},
    }
  }
}
