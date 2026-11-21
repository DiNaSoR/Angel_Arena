/* global $, Game, CustomNetTables, DOTATeam_t, ArenaSkin */
'use strict';

// Shows the arena match state inside Dota's own top bar instead of a second scoreboard.
// The bar already carries both kill counts and the clock. This adds the kill target beside
// the Angels' portraits and the duel timer beside the Demons', and gives the counts their
// team colours. See arena_skin.js for how native panels are restyled.

// What the two captions should say for a given match state. Kept free of panels so it can be
// tested on its own (tests/panorama_match.js).
var ArenaMatchView = {
  clock: function (seconds) {
    var rest = seconds % 60;
    return Math.floor(seconds / 60) + ':' + (rest < 10 ? '0' : '') + rest;
  },

  // state: the 'state' key of the arena_match net table; duel: its 'duel' key; now: game time.
  describe: function (state, duel, now) {
    if (!state) {
      return null;
    }
    var target = Math.max(0, Math.floor(Number(state.kill_limit) || 0));
    var winner = Number(state.winner);
    var angelsWin = winner === DOTATeam_t.DOTA_TEAM_GOODGUYS;
    var finished = angelsWin || winner === DOTATeam_t.DOTA_TEAM_BADGUYS;
    var view = {
      // Left of the Angels: what it takes to win.
      goalCaption: target > 0 ? '#arena_kill_target' : '#arena_boss_only_objective',
      goalValue: target > 0 ? String(target) : '',
      // Right of the Demons: what the arena is doing now.
      phaseCaption: state.phase === 'in_progress' ? '#arena_match_live' : '#arena_match_waiting',
      phaseValue: '',
      duelActive: false,
      finished: finished,
      ticking: false
    };
    if (finished) {
      view.goalCaption = angelsWin ? '#arena_match_angels_win' : '#arena_match_demons_win';
      view.goalValue = '';
      view.phaseCaption = { boss: '#arena_match_boss_defeated', kills: '#arena_match_target_reached' }[state.victory_reason] || '';
      return view;
    }
    var phase = duel && duel.phase;
    var deadline = duel && Number(duel.deadline);
    if (state.phase === 'in_progress' && (phase === 'active' || phase === 'waiting') && isFinite(deadline) && deadline > 0) {
      view.duelActive = phase === 'active';
      view.phaseCaption = view.duelActive ? '#arena_duel_active' : '#arena_duel_waiting';
      view.phaseValue = ArenaMatchView.clock(Math.max(0, Math.ceil(deadline - now)));
      view.ticking = true;
    }
    return view;
  }
};

(function () {
  var TABLE = 'arena_match';
  var skin = ArenaSkin;
  var GAP = 14;            // between the outermost portrait and the caption beside it
  var TICK_SECONDS = 0.25;
  var topbar = skin.hudRoot().FindChildTraverse('topbar');
  var state = null;
  var duel = null;
  var timer = null;
  var shown = {};
  skin.restamp();

  // How far `panel`'s left edge is from `ancestor`'s, in screen pixels.
  function offsetWithin(panel, ancestor) {
    var offset = 0;
    while (panel && panel !== ancestor) {
      offset += panel.actualxoffset;
      panel = panel.GetParent();
    }
    return offset;
  }

  // One caption block: a small label over a larger value, set against the outer end of a
  // team's row of portraits.
  function block(team, id, align) {
    var container = topbar.FindChildTraverse(team === 'Radiant' ? 'TopBarRadiantTeamContainer' : 'TopBarDireTeamContainer');
    var players = topbar.FindChildTraverse(team + 'TeamScorePlayers');
    if (!container || !players || !players.actuallayoutwidth) {
      return null;
    }
    // Each row grows outward from the clock, so its outer edge moves with the number of
    // players. Measurements are in screen pixels; margins are in layout pixels.
    var left = offsetWithin(players, container);
    var outer = align === 'right' ? container.actuallayoutwidth - left : left + players.actuallayoutwidth;
    var inset = Math.round(outer / players.actualuiscale_x) + GAP;
    var panel = skin.make('Panel', container, id, {
      'horizontal-align': align,
      'margin-right': align === 'right' ? inset + 'px' : '0px',
      'margin-left': align === 'left' ? inset + 'px' : '0px',
      'margin-top': '2px',
      'flow-children': 'down'
    });
    skin.label(panel, id + 'Caption', '', {
      'horizontal-align': align,
      'font-family': 'Radiance',
      'font-size': '13px',
      color: '#d8ccb4',
      'text-shadow': '0px 1px 2px 2.0 #000000cc'
    });
    skin.label(panel, id + 'Value', '', skin.serif('21px', skin.GOLD, {
      'horizontal-align': align,
      'margin-top': '-5px',
      'text-shadow': '0px 1px 2px 2.0 #000000cc'
    }));
    return panel;
  }

  // Writes a label only when its text changes.
  function say(parent, id, text) {
    if (shown[id] !== text) {
      shown[id] = text;
      parent.FindChild(id).text = text;
    }
  }

  function render() {
    timer = null;
    if (!topbar) {
      return;
    }
    skin.paintOnce(topbar.FindChildTraverse('TopBarRadiantScore'), skin.serif('24px', skin.TEAL, { 'margin-top': '3px' }));
    skin.paintOnce(topbar.FindChildTraverse('TopBarDireScore'), skin.serif('24px', skin.EMBER, { 'margin-top': '3px' }));

    var goal = block('Radiant', 'ArenaGoal', 'right');
    var phase = block('Dire', 'ArenaPhase', 'left');
    var view = ArenaMatchView.describe(state, duel, Game.GetGameTime());
    if (goal && phase) {
      say(goal, 'ArenaGoalCaption', view ? $.Localize(view.goalCaption) : '');
      say(goal, 'ArenaGoalValue', view ? view.goalValue : '');
      say(phase, 'ArenaPhaseCaption', view && view.phaseCaption ? $.Localize(view.phaseCaption) : '');
      say(phase, 'ArenaPhaseValue', view ? view.phaseValue : '');
      var color = view && view.duelActive ? skin.EMBER : skin.GOLD;
      if (shown.phaseColor !== color) {
        shown.phaseColor = color;
        skin.paint(phase.FindChild('ArenaPhaseValue'), { color: color });
      }
    }
    // Keep going while a duel clock is running, or until the bar has been laid out.
    if ((view && view.ticking) || !goal || !phase) {
      timer = $.Schedule(TICK_SECONDS, render);
    }
  }

  function refresh() {
    if (timer !== null) {
      $.CancelScheduled(timer);
    }
    render();
  }

  CustomNetTables.SubscribeNetTableListener(TABLE, function (name, key, value) {
    if (key === 'state') {
      state = value;
    } else if (key === 'duel') {
      duel = value;
    } else {
      return;
    }
    refresh();
  });
  state = CustomNetTables.GetTableValue(TABLE, 'state');
  duel = CustomNetTables.GetTableValue(TABLE, 'duel');
  refresh();
}());
