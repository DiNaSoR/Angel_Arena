/* global $, Game, DOTA_GameState */
'use strict';

// Swaps the loading art for the team select backdrop once the setup phase begins. The backdrop
// sits in the loading screen layer because that layer is drawn under the chat box.
(function () {
  var root = $.GetContextPanel();

  function inTeamSelect() {
    try {
      return Game.GameStateIs(DOTA_GameState.DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP);
    } catch (e) {
      return false; // The game API is not available until the client has connected.
    }
  }

  function watch() {
    if (inTeamSelect()) {
      root.AddClass('TeamSelect');
    } else {
      $.Schedule(0.2, watch);
    }
  }

  watch();
}());
