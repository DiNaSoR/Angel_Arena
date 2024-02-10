---------------------------------------------------------------------------
-- Required .lua files
---------------------------------------------------------------------------
--Precache--------------------------------------------------
require('modifier/aa_modifier')
require('precache/precache')
require('setting/settings')
require('setting/aa')
require('setting/gamemode')

--internal-------------------------------------------------
require('internal/util')
--require('internal/events')
require('internal/eventtest')

--libraries-------------------------------------------------
require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/notifications')
require('libraries/animations')
--require('libraries/attachments')
require('libraries/playertables')--Done installing it to Panorama
require('libraries/playerresource')
--require('libraries/containers')
--require('libraries/modmaker')
--require('libraries/pathgraph')
require('libraries/selection')
require('libraries/popups')

	--AABS Libraries
	require('libraries/data/globals')
	require('libraries/data/table')
	require('libraries/data/units')

	--OAA Libraries(Testing)
	require('libraries/oaa/functional')
	--require('libraries/oaa/chatcommand')
	--require('libraries/oaa/basenpc')
	require('libraries/oaa/basehero')
	--require('libraries/oaa/gamerules')
	require('libraries/oaa/fun')()
	--require('libraries/oaa/event')
	--require('libraries/oaa/math')

	--Imba files
	--require('libraries/imba/imba_addon')
	--require('libraries/imba/imba_client_util')
	--require('libraries/imba/funcs')
	--require('libraries/imba/util')
	--require('libraries/imba/imba_talent_events')

--Mechanics-------------------------------------------------
	--Others
		require('mechanics/onItempickthinker')
	--Drops
		require('mechanics/drops/dropsys')
		--require('mechanics/duel/duel')
	--Spawn
		require('mechanics/spawn/spawn')
		require('mechanics/spawn/miniboss')
	--Duel
		require('mechanics/duel/duel')
	--Triggers
		require('mechanics/triggers/lavatrigger')
		require('mechanics/triggers/triggers')
	--Teleport
		require('mechanics/teleport/teleports')
	--Camps
		require('mechanics/camps/index')
	--Gold
		require('mechanics/gold/gold')
	--Message
		require('mechanics/msg/msg')
	--AI
		-- Ai folder aleardy linked in Units files/NPC
	--kills
		require('mechanics/kills/kills')
		require('mechanics/kills/data')
	--Hero Voice
		require('mechanics/herovoice/herovoice')
	--Duel
		require('mechanics/duel/duel')
	--Gold
		require('mechanics/gold/gold')
	--hero progression
		--require('mechanics/progression/hero_progression')
	--Teams
		require('mechanics/teams/teams')
	--Event helper
		require('mechanics/events_helper/events_helper')
	--Ability used
		require('mechanics/abilityused/abilityused')

--Setting--------------------------------------------------
require('setting/events')
require('mechanics/teams/teams')




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
		GameRules.GameMode:CaptureGameMode()
end
