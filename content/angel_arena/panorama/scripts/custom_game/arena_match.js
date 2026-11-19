$.Schedule(0, function () {
  'use strict';

  var tableName = 'arena_match';
  var stateKey = 'state';
  var duelKey = 'duel';
  var victoryTokens = {
    boss: '#arena_match_boss_defeated',
    kills: '#arena_match_target_reached'
  };
  var root = $.GetContextPanel();
  var angels = $('#Angels');
  var demons = $('#Demons');
  var angelsScore = $('#AngelsScore');
  var demonsScore = $('#DemonsScore');
  var angelsFill = $('#AngelsFill');
  var demonsFill = $('#DemonsFill');
  var killTarget = $('#KillTarget');
  var matchPhase = $('#MatchPhase');
  var winnerLabel = $('#Winner');
  var victoryReason = $('#VictoryReason');
  var matchLive = false;
  var duel;
  var duelTimer = null;

  function toCount(value) {
    var count = Number(value);
    return isFinite(count) && count > 0 ? Math.floor(count) : 0;
  }

  function progress(kills, target) {
    return (target > 0 ? Math.min(100, 100 * kills / target) : 0) + '%';
  }

  function formatClock(seconds) {
    var remainder = seconds % 60;
    return Math.floor(seconds / 60) + ':' + (remainder < 10 ? '0' : '') + remainder;
  }

  function renderPhase() {
    duelTimer = null;
    var phase = duel && duel.phase;
    var deadline = duel && Number(duel.deadline);
    var active = phase === 'active';
    var showClock = matchLive && (active || phase === 'waiting') && isFinite(deadline) && deadline > 0;
    root.SetHasClass('DuelActive', showClock && active);

    if (showClock) {
      var seconds = Math.max(0, Math.ceil(deadline - Game.GetGameTime()));
      var label = $.Localize(active ? '#arena_duel_active' : '#arena_duel_waiting');
      matchPhase.text = label + ' ' + formatClock(seconds);
      duelTimer = $.Schedule(0.25, renderPhase);
    } else {
      matchPhase.text = $.Localize(matchLive ? '#arena_match_live' : '#arena_match_waiting');
    }
  }

  function refreshPhase() {
    if (duelTimer !== null) {
      $.CancelScheduled(duelTimer);
    }
    renderPhase();
  }

  function renderMatch(state) {
    root.SetHasClass('MatchReady', !!state);
    if (!state) {
      matchLive = false;
      refreshPhase();
      return;
    }

    var target = toCount(state.kill_limit);
    var angelsKills = toCount(state.angels);
    var demonsKills = toCount(state.demons);
    var winner = Number(state.winner);
    var angelsWin = winner === DOTATeam_t.DOTA_TEAM_GOODGUYS;
    var demonsWin = winner === DOTATeam_t.DOTA_TEAM_BADGUYS;
    var finished = angelsWin || demonsWin;

    angelsScore.text = String(angelsKills);
    demonsScore.text = String(demonsKills);
    angelsFill.style.width = progress(angelsKills, target);
    demonsFill.style.width = progress(demonsKills, target);
    killTarget.text = String(target);
    root.SetHasClass('BossOnly', target === 0);
    root.SetHasClass('MatchFinished', finished);
    root.SetHasClass('AngelsWin', angelsWin);
    root.SetHasClass('DemonsWin', demonsWin);
    angels.SetHasClass('Leading', finished ? angelsWin : angelsKills > demonsKills);
    demons.SetHasClass('Leading', finished ? demonsWin : demonsKills > angelsKills);
    matchLive = state.phase === 'in_progress' && !finished;
    refreshPhase();

    if (finished) {
      winnerLabel.text = $.Localize(angelsWin ? '#arena_match_angels_win' : '#arena_match_demons_win');
      var reason = victoryTokens[state.victory_reason];
      victoryReason.text = reason ? $.Localize(reason) : '';
    }
  }

  CustomNetTables.SubscribeNetTableListener(tableName, function (name, key, state) {
    if (key === stateKey) {
      renderMatch(state);
    } else if (key === duelKey) {
      duel = state;
      refreshPhase();
    }
  });
  duel = CustomNetTables.GetTableValue(tableName, duelKey);
  renderMatch(CustomNetTables.GetTableValue(tableName, stateKey));
});
