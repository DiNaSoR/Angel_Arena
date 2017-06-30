--------------------------------------------------------------
-- Angel Arena Rules
--------------------------------------------------------------
ENABLE_HERO_RESPAWN = true              	-- Should the heroes automatically respawn on a timer or stay dead until manually respawned
UNIVERSAL_SHOP_MODE = true             		-- Should the main shop contain Secret Shop items as well as regular items
ALLOW_SAME_HERO_SELECTION = false        	-- Should we let people select the same hero as each other

HERO_SELECTION_TIME = 25                	-- How long should we let people select their hero?
PRE_GAME_TIME = 5                       	-- How long after people select their heroes should the horn blow and the game start?
POST_GAME_TIME = 60.0                   	-- How long should we let people look at the scoreboard before closing the server automatically?
TREE_REGROW_TIME = 60.0                 	-- How long should it take individual trees to respawn after being cut down/destroyed?

GOLD_PER_TICK = 1                    		-- How much gold should players get per tick?
GOLD_TICK_TIME = 0.1                     		-- How long should we wait in seconds between gold ticks?

RECOMMENDED_BUILDS_DISABLED = false     	-- Should we disable the recommened builds for heroes (Note: this is not working currently I believe)
CAMERA_DISTANCE_OVERRIDE = 1400         	-- How far out should we allow the camera to go?  1134 is the default in Dota

MINIMAP_ICON_SIZE = 1                 		-- What icon size should we use for our heroes?
MINIMAP_CREEP_ICON_SIZE = 1             	-- What icon size should we use for creeps?
MINIMAP_RUNE_ICON_SIZE = 1            		-- What icon size should we use for runes?

RUNE_SPAWN_TIME = 60                   		-- How long in seconds should we wait between rune spawns?
CUSTOM_BUYBACK_COST_ENABLED = false      	-- Should we use a custom buyback cost setting?
CUSTOM_BUYBACK_COOLDOWN_ENABLED = false  	-- Should we use a custom buyback time?
BUYBACK_ENABLED = false                 	-- Should we allow people to buyback when they die?

ENABLED_FOG_OF_WAR_ENTIRELY = true
DISABLE_FOG_OF_WAR_ENTIRELY = false			-- Should we disable fog of war entirely for both teams?
--USE_STANDARD_DOTA_BOT_THINKING = false		-- Should we have bots act like they would in Dota? (This requires 3 lanes, normal items, etc)
USE_STANDARD_HERO_GOLD_BOUNTY = true		-- Should we give gold for hero kills the same as in Dota, or allow those values to be changed?

USE_CUSTOM_TOP_BAR_VALUES = false			-- Should we do customized top bar values or use the default kill count per team?
TOP_BAR_VISIBLE = true						-- Should we display the top bar score/count at all?
SHOW_KILLS_ON_TOPBAR = true					-- Should we display kills only on the top bar? (No denies, suicides, kills by neutrals)  Requires USE_CUSTOM_TOP_BAR_VALUES

ENABLE_TOWER_BACKDOOR_PROTECTION = false	-- Should we enable backdoor protection for our towers?
REMOVE_ILLUSIONS_ON_DEATH = true			-- Should we remove all illusions if the main hero dies?
DISABLE_GOLD_SOUNDS = false					-- Should we disable the gold sound when players get gold?

END_GAME_ON_KILLS = true					-- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 0				-- How many kills for a team should signify an end of game?
PLAYER_COUNT_BADGUYS = 0 					-- How many badguys in the map ?
PLAYER_COUNT_GOODGUYS = 0 					-- How many goodguys in the map ?

USE_CUSTOM_HERO_LEVELS = false				-- Should we allow heroes to have custom levels?
MAX_LEVEL = 25								-- What level should we let heroes get to?
USE_CUSTOM_XP_VALUES = false				-- Should we use custom XP values to level up heroes, or the default Dota numbers?

FOUNTAIN_CONSTANT_MANA_REGEN = -1       	-- What should we use for the constant fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_MANA_REGEN = 20     	-- What should we use for the percentage fountain mana regen?  Use -1 to keep the default dota behavior.
FOUNTAIN_PERCENTAGE_HEALTH_REGEN = 20   	-- What should we use for the percentage fountain health regen?  Use -1 to keep the default dota behavior.

tHeroes 		= {}						-- Heros Table.
tPlayers 		= {}						-- Players Table.
nPlayers 		= 0							-- Number of players Table.

Dialog0 = false 							-- Dialog 0.
Dialog1 = false 							-- Dialog 1.
Dialog2 = false 							-- Dialog 2.
Dialog3 = false 							-- Dialog 3.



--[[Future 1v1 duel test system
--nHeroCount    	= 0
nPlayers 		= 0
nHeroCount    	= 0
nDeathHeroes  	= 0
nDeathCreeps  	= 0
tPlayers 		= {}
tHeroes 		= {}

PRE_DUEL_TIME = 5
IsDuelOccured = false
IsDuel        = false

ARENA_TELEPORT_COORD_TOP = Vector(5897.54, 4892.11, 17.3543)
ARENA_TELEPORT_COORD_BOT = Vector(5897.54, 2880, 17.3543)
ARENA_CENTER_COORD       = Vector(5897.54, 3904, 17.3543)]]


FACING_DOWN 	= Vector(0, -1, -0)			--Facing Forward direction
FACING_RIGHT 	= Vector(1, 0, -0)			--Facing Forward direction
