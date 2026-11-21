/* global GameUI, DOTATeam_t */
'use strict';

// Shared team colours. Angels and Demons are the two playable sides; the rest keep
// their Dota multi-team defaults so team-coloured panels never fall back to white.
(function () {
  var colors = {};
  colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = '#80dadb;';
  colors[DOTATeam_t.DOTA_TEAM_BADGUYS] = '#ff9c76;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_1] = '#c54da8;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_2] = '#ff6c00;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3] = '#3455FF;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4] = '#65d413;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_5] = '#815336;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_6] = '#1bc0d8;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_7] = '#c7e40d;';
  colors[DOTATeam_t.DOTA_TEAM_CUSTOM_8] = '#8c2af4;';
  GameUI.CustomUIConfig().team_colors = colors;
}());
