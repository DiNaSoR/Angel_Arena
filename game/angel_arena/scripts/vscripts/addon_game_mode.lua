require('modifier/aa_modifier')
require('precache/precache')
require('setting/settings')
require('setting/aa')
require('setting/gamemode')
require('internal/util')
require('internal/eventtest')

require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/notifications')
require('libraries/animations')
require('libraries/playertables')
require('libraries/playerresource')
require('libraries/selection')
require('libraries/popups')
require('libraries/data/globals')
require('libraries/data/table')
require('libraries/data/units')
require('libraries/oaa/functional')
require('libraries/oaa/basehero')
require('libraries/oaa/fun')()

require('mechanics/onitempickthinker')
require('mechanics/drops/dropsys')
require('mechanics/spawn/spawn')
require('mechanics/spawn/miniboss')
require('mechanics/duel/duel')
require('mechanics/triggers/lavatrigger')
require('mechanics/triggers/triggers')
require('mechanics/teleport/teleports')
require('mechanics/camps/index')
require('mechanics/gold/gold')
require('mechanics/msg/msg')
require('mechanics/kills/kills')
require('mechanics/kills/data')
require('mechanics/herovoice/herovoice')
require('mechanics/teams/teams')
require('mechanics/events_helper/events_helper')
require('mechanics/abilityused/abilityused')
require('setting/events')

function Precache(context)
    PrecacheManager:StartPrecache(context)
end

function Activate()
    if GameRules.GameMode then
        return
    end

    local arena = GameMode()
    GameRules.GameMode = arena
    arena:InitGameMode()
end
