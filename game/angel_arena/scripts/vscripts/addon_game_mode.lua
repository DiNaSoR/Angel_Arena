---------------------------------------------------------------------------
-- Required .lua files
---------------------------------------------------------------------------
--Spawn
require('Spawn/spawn')
require('Spawn/miniboss')
--Precache
require('Precache/precache')
--Setting
require('Setting/aa')
require('Setting/msg')
require('Setting/settings')
--libraries
require('libraries/timers')
require('libraries/popups')
require('libraries/notifications')
require('libraries/teleports')
require('libraries/utilities')
require('libraries/util')
require('libraries/animations')
require('libraries/physics')
--Mechanics
require('Mechanics/dropsys')
require('Mechanics/duel')
require('Mechanics/onItempickthinker')
--AI


--------------------------------------------------------------
-- Precache
--------------------------------------------------------------
function Precache( context )
	PrecacheManager:StartPrecache(context)
end


--------------------------------------------------------------
-- Activate
--------------------------------------------------------------
-- Create the game mode when we activate
function Activate()	
		GameRules.GameMode = GameMode()
		GameRules.GameMode:InitGameMode()
						
end

