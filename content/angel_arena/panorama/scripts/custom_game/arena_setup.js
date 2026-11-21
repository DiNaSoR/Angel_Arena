/* global $, Game, DOTATeam_t */
'use strict';

// Team select for the custom game setup phase: Angels on the left, Demons on the right.
// Players are seated automatically and switch sides by clicking the other banner.
// The painted backdrop is drawn by the loading screen underneath (custom_loading_screen.js).
(function () {
  var ANGELS = DOTATeam_t.DOTA_TEAM_GOODGUYS;
  var DEMONS = DOTATeam_t.DOTA_TEAM_BADGUYS;
  var START_DELAY = 4;
  var SEATING_DELAY = 0.5;
  var root = $.GetContextPanel();
  var sides = {};
  sides[ANGELS] = { panel: $('#Angels'), seats: $('#AngelsSeats'), count: $('#AngelsCount') };
  sides[DEMONS] = { panel: $('#Demons'), seats: $('#DemonsSeats'), count: $('#DemonsCount') };
  var wanderers = $('#Wanderers');
  var wanderersList = $('#WanderersList');
  var countdown = $('#Countdown');
  var countdownValue = $('#CountdownValue');
  var countdownLabel = $('#CountdownLabel');
  var hint = $('#SetupHint');
  var hintTimer = null;
  var lastSeconds = -1;

  function localInfo() {
    return Game.GetLocalPlayerInfo() || {};
  }

  function isHost() {
    return !!localInfo().player_has_host_privileges;
  }

  // Two digits fill the medallion; anything longer switches to minutes and seconds.
  function formatCountdown(seconds) {
    if (seconds < 100) {
      return String(seconds);
    }
    var rest = seconds % 60;
    return Math.floor(seconds / 60) + ':' + (rest < 10 ? '0' : '') + rest;
  }

  function showHint(token) {
    hint.text = $.Localize(token);
    hint.SetHasClass('Shown', true);
    if (hintTimer !== null) {
      $.CancelScheduled(hintTimer);
    }
    hintTimer = $.Schedule(4, function () {
      hintTimer = null;
      hint.SetHasClass('Shown', false);
    });
  }

  // Reuses child panels by index so re-rendering never rebuilds the whole list.
  function child(parent, index, snippet) {
    var panel = parent.GetChild(index);
    if (!panel) {
      panel = $.CreatePanel('Panel', parent, '');
      panel.BLoadLayoutSnippet(snippet);
    }
    return panel;
  }

  function trim(parent, count) {
    for (var i = parent.GetChildCount() - 1; i >= count; i--) {
      parent.GetChild(i).DeleteAsync(0);
    }
  }

  function fillSeat(seat, playerId) {
    var info = playerId === undefined ? null : Game.GetPlayerInfo(playerId);
    var name = seat.FindChildTraverse('SeatName');
    var tag = seat.FindChildTraverse('SeatTag');
    seat.SetHasClass('Taken', !!info);
    seat.SetHasClass('Local', !!info && !!info.player_is_local);
    seat.SetHasClass('Host', !!info && !!info.player_has_host_privileges);
    if (!info) {
      name.text = $.Localize('#arena_setup_open_seat');
      if (tag) {
        tag.text = '';
      }
      return;
    }
    name.text = info.player_name;
    seat.FindChildTraverse('SeatAvatar').steamid = info.player_steamid;
    if (tag) {
      tag.text = info.player_is_local ? $.Localize('#arena_setup_you')
        : info.player_has_host_privileges ? $.Localize('#arena_setup_host') : '';
    }
  }

  function renderSide(teamId) {
    var side = sides[teamId];
    var players = Game.GetPlayerIDsOnTeam(teamId);
    var details = Game.GetTeamDetails(teamId) || {};
    var seats = Math.max(Number(details.team_max_players) || 0, players.length);
    for (var i = 0; i < seats; i++) {
      fillSeat(child(side.seats, i, 'Seat'), players[i]);
    }
    trim(side.seats, seats);
    side.count.SetDialogVariableInt('seated', players.length);
    side.count.SetDialogVariableInt('seats', seats);
    side.panel.SetHasClass('Full', players.length >= seats);
    side.panel.SetHasClass('Mine', localInfo().player_team_id === teamId);
  }

  function render() {
    renderSide(ANGELS);
    renderSide(DEMONS);
    var waiting = Game.GetUnassignedPlayerIDs();
    for (var i = 0; i < waiting.length; i++) {
      fillSeat(child(wanderersList, i, 'Wanderer'), waiting[i]);
    }
    trim(wanderersList, waiting.length);
    wanderers.SetHasClass('Shown', waiting.length > 0);
    root.SetHasClass('HasUnassigned', waiting.length > 0);
  }

  function join(teamId) {
    if (Game.GetTeamSelectionLocked()) {
      showHint('#arena_setup_hint_locked');
      Game.EmitSound('ui_team_select_pick_team_failed');
    } else if (localInfo().player_team_id !== teamId) {
      Game.PlayerJoinTeam(teamId);
    }
  }

  function lockAndStart() {
    Game.SetTeamSelectionLocked(true);
    Game.SetAutoLaunchEnabled(false);
    Game.SetRemainingSetupTime(START_DELAY);
  }

  function startOrCancel() {
    if (Game.GetTeamSelectionLocked()) {
      Game.SetTeamSelectionLocked(false);
      Game.SetRemainingSetupTime(-1);
      return;
    }
    if (Game.GetUnassignedPlayerIDs().length === 0) {
      lockAndStart();
      return;
    }
    // Nobody may enter the arena without a side. The server confirms each seat, so the lock
    // waits a moment for the stragglers to be placed.
    Game.AutoAssignPlayersToTeams();
    $.Schedule(SEATING_DELAY, function () {
      if (Game.GetUnassignedPlayerIDs().length === 0) {
        lockAndStart();
      } else {
        showHint('#arena_setup_hint_unassigned');
      }
    });
  }

  function tick() {
    var transition = Game.GetStateTransitionTime();
    var counting = transition >= 0;
    var seconds = counting ? Math.max(0, Math.ceil(transition - Game.GetGameTime())) : -1;
    var locked = Game.GetTeamSelectionLocked();
    var host = isHost();

    root.SetHasClass('IsHost', host);
    root.SetHasClass('Locked', locked);
    countdown.SetHasClass('Counting', counting);
    countdown.SetHasClass('Final', counting && seconds <= 5);
    if (seconds !== lastSeconds) {
      countdownValue.text = formatCountdown(Math.max(seconds, 0));
      countdown.SetHasClass('Long', seconds >= 100);
      countdownLabel.text = $.Localize(!counting ? '#arena_setup_countdown_idle'
        : locked ? '#arena_setup_countdown_start' : '#arena_setup_countdown_auto');
      // The engine does not seat stragglers when the timer runs out, so the host does.
      if (host && counting && seconds <= 1 && Game.GetUnassignedPlayerIDs().length > 0) {
        Game.AutoAssignPlayersToTeams();
      }
      lastSeconds = seconds;
    }
    $.Schedule(0.1, tick);
  }

  sides[ANGELS].panel.SetPanelEvent('onactivate', function () { join(ANGELS); });
  sides[DEMONS].panel.SetPanelEvent('onactivate', function () { join(DEMONS); });
  $('#AssignButton').SetPanelEvent('onactivate', function () { Game.AutoAssignPlayersToTeams(); });
  $('#ShuffleButton').SetPanelEvent('onactivate', function () { Game.ShufflePlayerTeamAssignments(); });
  $('#StartButton').SetPanelEvent('onactivate', startOrCancel);

  // Dota insets custom setup screens by 42px to clear its dashboard button. The layout is
  // symmetrical about the pillar of light, so the inset is removed and the frame pads itself.
  var container = root.GetParent();
  if (container && container.id === 'CustomUIContainer') {
    container.style.marginLeft = '0px';
  }

  // Keeps the chat box from stealing keyboard focus while the setup screen is open.
  $('#SetupFrame').SetAcceptsFocus(true);

  $.RegisterForUnhandledEvent('DOTAGame_TeamPlayerListChanged', render);
  $.RegisterForUnhandledEvent('DOTAGame_PlayerDetailsChanged', render);
  $.RegisterForUnhandledEvent('DOTAGame_PlayerSelectedCustomTeam', function (playerId, teamId, success) {
    if (playerId === localInfo().player_id) {
      Game.EmitSound(success ? 'ui_team_select_pick_team' : 'ui_team_select_pick_team_failed');
      if (!success) {
        showHint('#arena_setup_hint_full');
      }
    }
  });

  Game.AutoAssignPlayersToTeams();
  render();
  tick();
}());
