local ArenaScore = require('mechanics/match/score')

local gameEvents = {
    dota_player_gained_level = 'OnPlayerLevelUp',
    dota_player_learned_ability = 'OnPlayerLearnedAbility',
    dota_player_take_tower_damage = 'OnPlayerTakeTowerDamage',
    dota_player_used_ability = 'OnAbilityUsed',
    dota_player_begin_cast = 'OnAbilityCastBegins',
    dota_player_selected_custom_team = 'OnPlayerSelectedCustomTeam',
    dota_illusions_created = 'OnIllusionsCreated',
    dota_item_combined = 'OnItemCombined',
    dota_tower_kill = 'OnTowerKill',
    dota_non_player_used_ability = 'OnNonPlayerUsedAbility',
    dota_rune_activated_server = 'OnRuneActivated',
    dota_ability_channel_finished = 'OnAbilityChannelFinished',
    dota_team_kill_credit = 'OnTeamKillCredit',
    dota_npc_goal_reached = 'OnNPCGoalReached',
    player_connect_full = 'OnConnectFull',
    player_changename = 'OnPlayerChangedName',
    player_disconnect = 'OnDisconnect',
    player_connect = 'PlayerConnect',
    player_reconnected = 'OnPlayerReconnect',
    entity_killed = 'OnEntityKilled',
    entity_hurt = 'OnEntityHurt',
    dota_item_purchased = 'OnItemPurchased',
    dota_item_picked_up = 'OnItemPickedUp',
    last_hit = 'OnLastHit',
    npc_spawned = 'OnNPCSpawned',
    game_rules_state_change = 'OnGameRulesStateChange',
    player_chat = 'OnPlayerChat',
    tree_cut = 'OnTreeCut',
}

function GameMode:InitGameMode()
    -- Legacy map callbacks access the active instance as GameMode.
    GameMode = self
    GameRules:GetGameModeEntity().GameMode = self

    GameRules:SetHeroRespawnEnabled(ENABLE_HERO_RESPAWN)
    GameRules:SetUseUniversalShopMode(UNIVERSAL_SHOP_MODE)
    GameRules:SetSameHeroSelectionEnabled(ALLOW_SAME_HERO_SELECTION)
    GameRules:SetCustomGameSetupTimeout(CUSTOM_GAME_SETUP_TIME)
    GameRules:SetHeroSelectionTime(HERO_SELECTION_TIME)
    GameRules:SetPreGameTime(PRE_GAME_TIME)
    GameRules:SetPostGameTime(POST_GAME_TIME)
    GameRules:SetTreeRegrowTime(TREE_REGROW_TIME)
    GameRules:SetUseCustomHeroXPValues(USE_CUSTOM_XP_VALUES)
    GameRules:SetGoldPerTick(GOLD_PER_TICK)
    GameRules:SetGoldTickTime(GOLD_TICK_TIME)
    GameRules:SetRuneSpawnTime(RUNE_SPAWN_TIME)
    GameRules:SetUseBaseGoldBountyOnHeroes(USE_STANDARD_HERO_GOLD_BOUNTY)
    GameRules:SetHeroMinimapIconScale(MINIMAP_ICON_SIZE)
    GameRules:SetCreepMinimapIconScale(MINIMAP_CREEP_ICON_SIZE)
    GameRules:SetRuneMinimapIconScale(MINIMAP_RUNE_ICON_SIZE)
    GameRules:SetFirstBloodActive(ENABLE_FIRST_BLOOD)
    GameRules:SetHideKillMessageHeaders(HIDE_KILL_BANNERS)
    GameRules:SetCustomGameEndDelay(GAME_END_DELAY)
    GameRules:SetCustomVictoryMessageDuration(VICTORY_MESSAGE_DURATION)
    GameRules:SetStartingGold(STARTING_GOLD)

    if SKIP_TEAM_SETUP then
        GameRules:SetCustomGameSetupAutoLaunchDelay(0)
        GameRules:LockCustomGameSetupTeamAssignment(true)
        GameRules:EnableCustomGameSetupAutoLaunch(true)
        GameRules:SetStrategyTime(0)
        GameRules:SetShowcaseTime(0)
    else
        GameRules:SetCustomGameSetupAutoLaunchDelay(AUTO_LAUNCH_DELAY)
        GameRules:LockCustomGameSetupTeamAssignment(LOCK_TEAM_SETUP)
        GameRules:EnableCustomGameSetupAutoLaunch(ENABLE_AUTO_LAUNCH)
    end

    math.randomseed(GetSystemTimeMS())

    self.spellList = {"skill_bag_of_gold"}
    self.vUserIds = {}
    self.vSteamIds = {}
    self.vPlayers = {}
    self.vBroadcasters = {}
    GameRules.CURRENT_SOUNDTRACK = 0

    local spew = BAREBONES_DEBUG_SPEW and "1" or "0"
    Convars:RegisterConvar("barebones_spew", spew, "Enable Angel Arena debug logging.", 0)

    Teams:Initialize()
    PlayerTables:CreateTable("arena", {}, true)
    PlayerTables:CreateTable("player_hero_indexes", {}, true)
    PlayerTables:CreateTable("players_abandoned", {}, true)
    PlayerTables:CreateTable("gold", { gold = {} }, true)

    local disableHelp = {}
    for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
        disableHelp[playerID] = {}
    end
    PlayerTables:CreateTable("disable_help_data", disableHelp, true)
    CustomNetTables:SetTableValue("info", "version", { value = AA_VERSION })

    self:CaptureGameMode()
    ArenaScore.Initialize(self)

    for event, callback in pairs(gameEvents) do
        ListenToGameEvent(event, Dynamic_Wrap(self, callback), self)
    end
    print("[Angel Arena] Game mode initialized")
end

function GameMode:CaptureGameMode()
    if self.mode then
        return
    end

    local mode = GameRules:GetGameModeEntity()
    mode:SetRecommendedItemsDisabled(RECOMMENDED_BUILDS_DISABLED)
    mode:SetCameraDistanceOverride(CAMERA_DISTANCE_OVERRIDE)
    mode:SetCustomBuybackCostEnabled(CUSTOM_BUYBACK_COST_ENABLED)
    mode:SetCustomBuybackCooldownEnabled(CUSTOM_BUYBACK_COOLDOWN_ENABLED)
    mode:SetBuybackEnabled(BUYBACK_ENABLED)
    mode:SetTopBarTeamValuesOverride(USE_CUSTOM_TOP_BAR_VALUES)
    mode:SetTopBarTeamValuesVisible(TOP_BAR_VISIBLE)
    mode:SetUseCustomHeroLevels(USE_CUSTOM_HERO_LEVELS)
    mode:SetCustomHeroMaxLevel(MAX_LEVEL)
    mode:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)
    mode:SetUnseenFogOfWarEnabled(USE_UNSEEN_FOG_OF_WAR)
    mode:SetAlwaysShowPlayerInventory(SHOW_ONLY_PLAYER_INVENTORY)
    mode:SetAnnouncerDisabled(DISABLE_ANNOUNCER)
    mode:SetBotThinkingEnabled(USE_STANDARD_DOTA_BOT_THINKING)
    mode:SetTowerBackdoorProtectionEnabled(ENABLE_TOWER_BACKDOOR_PROTECTION)
    mode:SetFogOfWarDisabled(DISABLE_FOG_OF_WAR_ENTIRELY)
    mode:SetGoldSoundDisabled(DISABLE_GOLD_SOUNDS)
    mode:SetRemoveIllusionsOnDeath(REMOVE_ILLUSIONS_ON_DEATH)

    if FORCE_PICKED_HERO then
        mode:SetCustomGameForceHero(FORCE_PICKED_HERO)
    end

    mode:SetFixedRespawnTime(FIXED_RESPAWN_TIME)
    mode:SetLoseGoldOnDeath(LOSE_GOLD_ON_DEATH)
    mode:SetMaximumAttackSpeed(MAXIMUM_ATTACK_SPEED)
    mode:SetMinimumAttackSpeed(MINIMUM_ATTACK_SPEED)
    mode:SetStashPurchasingDisabled(DISABLE_STASH_PURCHASING)

    for rune, spawn in pairs(ENABLED_RUNES) do
        mode:SetRuneEnabled(rune, spawn)
    end

    mode:SetDaynightCycleDisabled(DISABLE_DAY_NIGHT_CYCLE)
    mode:SetKillingSpreeAnnouncerDisabled(DISABLE_KILLING_SPREE_ANNOUNCER)
    mode:SetStickyItemDisabled(DISABLE_STICKY_ITEM)
    self.mode = mode
end
