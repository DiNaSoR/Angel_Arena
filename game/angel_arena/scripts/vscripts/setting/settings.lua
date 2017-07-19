BAREBONES_DEBUG_SPEW = false
--------------------------------------------------------------
-- All KeyValues[KV] Files Global value
--------------------------------------------------------------
AA_VERSION                                   = LoadKeyValues("addoninfo.txt").version
DROPS_TABLE                                  = LoadKeyValues("scripts/npc/kv/item_test.kv")
--SPAWN_INFO_KV                               = LoadKeyValues("scripts/npc/kv/spawn_info.kv")

--IMBA KV------------------------------------------------------
--HERO_ABILITY_LIST                           = LoadKeyValues("scripts/npc/kv/imba/nonhidden_ability_list.kv")
--TOWER_ABILITIES                             = LoadKeyValues("scripts/npc/kv/imba/tower_abilities.kv")
--PURGE_BUFF_LIST                             = LoadKeyValues("scripts/npc/kv/imba/purge_buffs_list.kv")
--IMBA_GENERIC_TALENT_LIST                    = LoadKeyValues("scripts/npc/kv/imba/imba_generic_talent_list.kv")
--IMBA_HERO_TALENTS_LIST                      = LoadKeyValues("scripts/npc/kv/imba/imba_hero_talents_list.kv")
--DISPELLABLE_DEBUFF_LIST                     = LoadKeyValues("scripts/npc/kv/imba/dispellable_debuffs_list.kv")]]
--------------------------------------------------------------
-- Angel Arena Rules
--------------------------------------------------------------
ENABLE_HERO_RESPAWN                         = true              	-- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE                         = true             		-- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION                   = false        	        -- Should we let people select the same hero as each other
END_GAME_ON_KILLS                           = true					-- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM                  = 0				        -- How many kills for a team should signify an end of game?
PLAYER_COUNT_BADGUYS                        = 0 					-- How many badguys in the map ?
PLAYER_COUNT_GOODGUYS                       = 0 					-- How many goodguys in the map ?
FORCE_PICKED_HERO                           = nil                   -- What hero should we force all players to spawn as? (e.g. "npc_dota_hero_axe").  Use nil to allow players to pick their own hero.
--------------------------------------------------------------
CUSTOM_GAME_SETUP_TIME                      = 30.0                  -- How long to show custom game setup? 0 disables
HERO_SELECTION_TIME                         = 25                	-- How long should we let people select their hero?
PRE_GAME_TIME                               = 5                     -- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME                              = 60.0                  -- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME                            = 60.0                 	-- How long should it take individual trees to respawn after being cut down/destroyed?
--------------------------------------------------------------
GOLD_PER_TICK                               = 1                    	-- How much gold should players get per tick?
GOLD_TICK_TIME                              = 0.1                   -- How long should we wait in seconds between gold ticks?
DISABLE_GOLD_SOUNDS                         = false					-- Should we disable the gold sound when players get gold?
LOSE_GOLD_ON_DEATH                          = true                  -- Should we have players lose the normal amount of dota gold on death?
STARTING_GOLD                               = 625                   -- How much starting gold should we give to each player?
--------------------------------------------------------------
RECOMMENDED_BUILDS_DISABLED                 = false     	        -- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
--------------------------------------------------------------
CAMERA_DISTANCE_OVERRIDE                    = 1134         	        -- How far out should we allow the camera to go?  1134 is the default in Dota
--------------------------------------------------------------
MINIMAP_ICON_SIZE                           = 1                 	-- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE                     = 1             	    -- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE                      = 1            		    -- What icon size should we use for runes?
--------------------------------------------------------------
RUNE_SPAWN_TIME                             = 30                   	-- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED                 = false      	        -- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED             = false  	            -- Should we use a custom buyback time?
BUYBACK_ENABLED                             = false                 -- Should we allow people to buyback when they die?
--------------------------------------------------------------
DISABLE_FOG_OF_WAR_ENTIRELY                 = true			        -- Should we disable fog of war entirely for both teams?
USE_UNSEEN_FOG_OF_WAR                       = false                 -- Should we make unseen and fogged areas of the map completely black until uncovered by each team?
                                                                        -- Note: DISABLE_FOG_OF_WAR_ENTIRELY must be false for USE_UNSEEN_FOG_OF_WAR to work
--------------------------------------------------------------
USE_STANDARD_DOTA_BOT_THINKING              = true		            -- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY               = true		            -- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?
--------------------------------------------------------------
USE_CUSTOM_TOP_BAR_VALUES                   = false			        -- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE                             = true					-- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR                        = true					-- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES
--------------------------------------------------------------
ENABLE_TOWER_BACKDOOR_PROTECTION            = false	                -- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH                   = false			        -- Should we remove all illusions if the main hero dies?
--------------------------------------------------------------
USE_CUSTOM_HERO_LEVELS                      = true				    -- Should we allow heroes to have custom levels?
MAX_LEVEL                                   = 150								-- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES                        = true				    -- Should we use custom XP values to level up heroes, or the default Dota numbers?
XP_PER_LEVEL_TABLE                          = {}
XP_PER_LEVEL_TABLE[1]                       = 0                     -- Fill this table up with the required XP per level if you want to change it
for i = 2, MAX_LEVEL do
  	XP_PER_LEVEL_TABLE[i] = XP_PER_LEVEL_TABLE[i-1] + i*100
end
--------------------------------------------------------------
FOUNTAIN_CONSTANT_MANA_REGEN                = -1       	            -- What should we use for the constant fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_MANA_REGEN              = -1     	            -- What should we use for the percentage fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_HEALTH_REGEN            = -1   	                -- What should we use for the percentage fountain health regen?  Use -1 to keep the default dota behavior.
--------------------------------------------------------------
ENABLE_FIRST_BLOOD                          = true                  -- Should we enable first blood for the first kill in this game?
HIDE_KILL_BANNERS                           = false                 -- Should we hide the kill banners that show when a player is killed?
--------------------------------------------------------------
SHOW_ONLY_PLAYER_INVENTORY                  = false                 -- Should we only allow players to see their own inventory even when selecting other units?
DISABLE_STASH_PURCHASING                    = false                 -- Should we prevent players from being able to buy items into their stash when not at a shop?
--------------------------------------------------------------
DISABLE_ANNOUNCER                           = false                 -- Should we disable the announcer from working in the game?
--------------------------------------------------------------
FIXED_RESPAWN_TIME                          = 5                     -- What time should we use for a fixed respawn timer?  Use -1 to keep the default dota behavior.

MAXIMUM_ATTACK_SPEED                        = 3000                  -- What should we use for the maximum attack speed?
MINIMUM_ATTACK_SPEED                        = 20                    -- What should we use for the minimum attack speed?
--------------------------------------------------------------
GAME_END_DELAY                              = -1                    -- How long should we wait after the game winner is set to display the victory banner and End Screen?  Use -1 to keep the default (about 10 seconds)
VICTORY_MESSAGE_DURATION                    = 5                     -- How long should we wait after the victory message displays to show the End Screen?  Use
--------------------------------------------------------------
DISABLE_DAY_NIGHT_CYCLE                     = false                 -- Should we disable the day night cycle from naturally occurring? (Manual adjustment still possible)
DISABLE_KILLING_SPREE_ANNOUNCER             = false                 -- Shuold we disable the killing spree announcer?
DISABLE_STICKY_ITEM                         = false                 -- Should we disable the sticky item button in the quick buy area?
SKIP_TEAM_SETUP                             = false                 -- Should we skip the team setup entirely?
ENABLE_AUTO_LAUNCH                          = true                  -- Should we automatically have the game complete team setup after AUTO_LAUNCH_DELAY seconds?
AUTO_LAUNCH_DELAY                           = 30                    -- How long should the default team selection launch timer be?  The default for custom games is 30.  Setting to 0 will skip team selection.
LOCK_TEAM_SETUP                             = false                 -- Should we lock the teams initially?  Note that the host can still unlock the teams
--------------------------------------------------------------
tHeroes 		                            = {}				    -- Heros Table.
tPlayers 		                            = {}					-- Players Table.
nPlayers 		                            = 0						-- Number of players Table.
--------------------------------------------------------------
Dialog0                                     = false 				-- Dialog 0.
Dialog1                                     = false 				-- Dialog 1.
Dialog2                                     = false 				-- Dialog 2.
Dialog3                                     = false 				-- Dialog 3.
--------------------------------------------------------------
-- Creeps
CREEP_SPAWN_INTERVAL                        = 60                    -- number of seconds between each creep spawn
INITIAL_CREEP_DELAY                         = 10                    -- number of seconds to wait before spawning the first wave of creeps
BOTTLE_DESPAWN_TIME                         = 60                    -- Time until Bottles despawn
CREEP_GROWTH                                = 100
--------------------------------------------------------------
FACING_DOWN 	                            = Vector(0, -1, -0)		--Facing Forward direction
FACING_RIGHT 	                            = Vector(1, 0, -0)		--Facing Forward direction
------------------------------------------------------------------------------------------------------------------------------------------------
-- NOTE: You always need at least 2 non-bounty type runes to be able to spawn or your game will crash!
------------------------------------------------------------------------------------------------------------------------------------------------
ENABLED_RUNES                               = {}                    -- Which runes should be enabled to spawn in our game mode?
ENABLED_RUNES[DOTA_RUNE_DOUBLEDAMAGE]       = true
ENABLED_RUNES[DOTA_RUNE_HASTE]              = true
ENABLED_RUNES[DOTA_RUNE_ILLUSION]           = true
ENABLED_RUNES[DOTA_RUNE_INVISIBILITY]       = true
ENABLED_RUNES[DOTA_RUNE_REGENERATION]       = true
ENABLED_RUNES[DOTA_RUNE_BOUNTY]             = true
ENABLED_RUNES[DOTA_RUNE_ARCANE]             = true
------------------------------------------------------------------------------------------------------------------------------------------------
MAX_NUMBER_OF_TEAMS                         = 2                     -- How many potential teams can be in this game mode?
USE_CUSTOM_TEAM_COLORS                      = false                 -- Should we use custom team colors?
USE_CUSTOM_TEAM_COLORS_FOR_PLAYERS          = true                  -- Should we use custom team colors to color the players/minimap?
TEAM_COLORS                                 = {}                    -- If USE_CUSTOM_TEAM_COLORS is set, use these colors.
TEAM_COLORS[DOTA_TEAM_GOODGUYS]             = { 61, 210, 150 }      --    Teal
TEAM_COLORS[DOTA_TEAM_BADGUYS]              = { 243, 201, 9 }       --    Yellow
TEAM_COLORS[DOTA_TEAM_CUSTOM_1]             = { 197, 77, 168 }      --    Pink
TEAM_COLORS[DOTA_TEAM_CUSTOM_2]             = { 255, 108, 0 }       --    Orange
TEAM_COLORS[DOTA_TEAM_CUSTOM_3]             = { 52, 85, 255 }       --    Blue
TEAM_COLORS[DOTA_TEAM_CUSTOM_4]             = { 101, 212, 19 }      --    Green
TEAM_COLORS[DOTA_TEAM_CUSTOM_5]             = { 129, 83, 54 }       --    Brown
TEAM_COLORS[DOTA_TEAM_CUSTOM_6]             = { 27, 192, 216 }      --    Cyan
TEAM_COLORS[DOTA_TEAM_CUSTOM_7]             = { 199, 228, 13 }      --    Olive
TEAM_COLORS[DOTA_TEAM_CUSTOM_8]             = { 140, 42, 244 }      --    Purple
--------------------------------------------------------------
USE_AUTOMATIC_PLAYERS_PER_TEAM              = false                 -- Should we set the number of players to 10 / MAX_NUMBER_OF_TEAMS?
CUSTOM_TEAM_PLAYER_COUNT                    = {}                    -- If we're not automatically setting the number of players per team, use this table
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 5
CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 5
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_1] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_2] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_3] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_4] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_5] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_6] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_7] = 1
-- CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_CUSTOM_8] = 1
------------------------------------------------------------------------------------------------------------------------------------------------
--[[Future 1v1 duel test system
--nHeroCount    	= 0
nPlayers 		= 0
nHeroCount    	= 0
nDeathHeroes  	= 0
nDeathCreeps  	= 0
tPlayers 		= {}
tHeroes 		= {}
--------------------------------------------------------------
PRE_DUEL_TIME = 5
IsDuelOccured = false
IsDuel        = false
--------------------------------------------------------------
ARENA_TELEPORT_COORD_TOP = Vector(5897.54, 4892.11, 17.3543)
ARENA_TELEPORT_COORD_BOT = Vector(5897.54, 2880, 17.3543)
ARENA_CENTER_COORD       = Vector(5897.54, 3904, 17.3543)]]