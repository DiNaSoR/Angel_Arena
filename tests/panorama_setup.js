'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const panorama = path.join(__dirname, '../content/angel_arena/panorama');
const layout = fs.readFileSync(path.join(panorama, 'layout/custom_game/arena_setup.xml'), 'utf8');
const script = fs.readFileSync(path.join(panorama, 'scripts/custom_game/arena_setup.js'), 'utf8');
const panelIds = Array.from(layout.matchAll(/\bid="([^"]+)"/g), ([, id]) => id);
const ANGELS = 2;
const DEMONS = 3;

function panel(id = '') {
  const children = [];
  return {
    id,
    text: '',
    classes: {},
    variables: {},
    style: {},
    events: {},
    children,
    SetHasClass(name, active) {
      this.classes[name] = active;
    },
    SetDialogVariableInt(name, value) {
      this.variables[name] = value;
    },
    SetPanelEvent(name, handler) {
      this.events[name] = handler;
    },
    SetAcceptsFocus() {},
    GetParent() {
      return this.parent || null;
    },
    GetChild(index) {
      return children[index];
    },
    GetChildCount() {
      return children.length;
    },
    FindChildTraverse(childId) {
      // Seats are built from a snippet, so each one owns its avatar, name and tag.
      this.parts = this.parts || {};
      this.parts[childId] = this.parts[childId] || panel(childId);
      return this.parts[childId];
    },
    BLoadLayoutSnippet() {},
    DeleteAsync() {
      children.splice(0, children.length);
      this.parent.children.splice(this.parent.children.indexOf(this), 1);
    }
  };
}

// A two-team lobby driven the way the engine drives it: joins are applied to `teams`, then the
// team list event fires.
function mount({ players, teams, seats = 5, host = 0, local = 0, transition = 30 }) {
  const root = panel();
  root.parent = panel('CustomUIContainer');
  const panels = Object.fromEntries(panelIds.map((id) => [id, panel(id)]));
  const state = { locked: false, autoLaunch: true, transition, time: 0, sounds: [], autoAssigns: 0 };
  const events = {};
  const scheduled = [];

  const teamOf = (playerId) => {
    const entry = Object.entries(teams).find(([, ids]) => ids.includes(playerId));
    return entry ? Number(entry[0]) : 5;
  };
  const unassigned = () => players.filter((id) => teamOf(id) === 5);
  const info = (id) => ({
    player_id: id,
    player_name: 'Player ' + id,
    player_steamid: 'steam' + id,
    player_is_local: id === local,
    player_has_host_privileges: id === host,
    player_team_id: teamOf(id)
  });
  const move = (playerId, teamId) => {
    const full = teams[teamId].length >= seats;
    if (!full) {
      Object.values(teams).forEach((ids) => {
        if (ids.includes(playerId)) {
          ids.splice(ids.indexOf(playerId), 1);
        }
      });
      teams[teamId].push(playerId);
      events.DOTAGame_TeamPlayerListChanged();
    }
    events.DOTAGame_PlayerSelectedCustomTeam(playerId, teamId, !full);
  };

  const $ = (selector) => panels[selector.slice(1)];
  $.GetContextPanel = () => root;
  $.Localize = (token) => token;
  $.CreatePanel = (type, parent) => {
    const created = panel();
    created.parent = parent;
    parent.children.push(created);
    return created;
  };
  $.Schedule = (delay, callback) => scheduled.push(callback);
  $.CancelScheduled = () => {};
  $.RegisterForUnhandledEvent = (name, callback) => {
    events[name] = callback;
  };

  const Game = {
    GetLocalPlayerInfo: () => info(local),
    GetPlayerInfo: info,
    GetPlayerIDsOnTeam: (teamId) => teams[teamId].slice(),
    GetTeamDetails: () => ({ team_max_players: seats }),
    GetUnassignedPlayerIDs: unassigned,
    GetTeamSelectionLocked: () => state.locked,
    SetTeamSelectionLocked: (locked) => {
      state.locked = locked;
    },
    SetAutoLaunchEnabled: (enabled) => {
      state.autoLaunch = enabled;
    },
    SetRemainingSetupTime: (seconds) => {
      state.transition = seconds < 0 ? -1 : state.time + seconds;
    },
    GetStateTransitionTime: () => state.transition,
    GetGameTime: () => state.time,
    PlayerJoinTeam: (teamId) => move(local, teamId),
    AutoAssignPlayersToTeams: () => {
      state.autoAssigns += 1;
      unassigned().forEach((id) => {
        const open = [ANGELS, DEMONS].filter((teamId) => teams[teamId].length < seats);
        if (open.length) {
          open.sort((a, b) => teams[a].length - teams[b].length);
          teams[open[0]].push(id);
        }
      });
      if (events.DOTAGame_TeamPlayerListChanged) {
        events.DOTAGame_TeamPlayerListChanged();
      }
    },
    ShufflePlayerTeamAssignments: () => {},
    EmitSound: (name) => state.sounds.push(name)
  };

  vm.runInNewContext(script, {
    $,
    Game,
    DOTATeam_t: { DOTA_TEAM_GOODGUYS: ANGELS, DOTA_TEAM_BADGUYS: DEMONS }
  });

  return {
    root,
    panels,
    state,
    teams,
    click(id) {
      panels[id].events.onactivate();
    },
    // Runs everything scheduled so far: the countdown tick and any delayed follow-up.
    advance(now) {
      state.time = now;
      scheduled.splice(0).forEach((callback) => callback());
    },
    seat(side, index) {
      const seat = panels[side + 'Seats'].children[index];
      return { classes: seat.classes, name: seat.parts.SeatName.text, tag: seat.parts.SeatTag.text };
    }
  };
}

// Everyone is seated on load, and each side shows one seat per slot.
const lobby = mount({ players: [0, 1, 2], teams: { [ANGELS]: [], [DEMONS]: [] } });
assert.equal(lobby.root.parent.style.marginLeft, '0px');
assert.deepEqual(lobby.teams, { [ANGELS]: [0, 2], [DEMONS]: [1] });
assert.equal(lobby.panels.AngelsSeats.children.length, 5);
assert.deepEqual(lobby.panels.AngelsCount.variables, { seated: 2, seats: 5 });
assert.equal(lobby.seat('Angels', 0).name, 'Player 0');
assert.equal(lobby.seat('Angels', 0).tag, '#arena_setup_you');
assert.equal(lobby.seat('Angels', 0).classes.Local, true);
assert.equal(lobby.seat('Angels', 2).classes.Taken, false);
assert.equal(lobby.seat('Angels', 2).name, '#arena_setup_open_seat');
assert.equal(lobby.panels.Angels.classes.Mine, true);
assert.equal(lobby.panels.Demons.classes.Mine, false);
assert.equal(lobby.panels.Wanderers.classes.Shown, false);
assert.equal(lobby.root.classes.IsHost, true);
assert.equal(lobby.panels.CountdownValue.text, '30');
assert.equal(lobby.panels.CountdownLabel.text, '#arena_setup_countdown_auto');

// Clicking the other banner switches sides; clicking your own does nothing.
lobby.click('Demons');
assert.deepEqual(lobby.teams, { [ANGELS]: [2], [DEMONS]: [1, 0] });
assert.equal(lobby.panels.Demons.classes.Mine, true);
assert.equal(lobby.seat('Demons', 1).name, 'Player 0');
assert.equal(lobby.seat('Angels', 1).classes.Taken, false);
assert.deepEqual(lobby.state.sounds, ['ui_team_select_pick_team']);
lobby.click('Demons');
assert.deepEqual(lobby.state.sounds, ['ui_team_select_pick_team']);

// Lock and start: sides lock, the short start countdown replaces auto-launch, and it can be undone.
lobby.click('StartButton');
assert.equal(lobby.state.locked, true);
assert.equal(lobby.state.autoLaunch, false);
lobby.advance(1);
assert.equal(lobby.root.classes.Locked, true);
assert.equal(lobby.panels.CountdownValue.text, '3');
assert.equal(lobby.panels.CountdownLabel.text, '#arena_setup_countdown_start');
assert.equal(lobby.panels.Countdown.classes.Final, true);
lobby.click('Angels');
assert.deepEqual(lobby.teams, { [ANGELS]: [2], [DEMONS]: [1, 0] });
assert.equal(lobby.panels.SetupHint.text, '#arena_setup_hint_locked');
lobby.click('StartButton');
assert.equal(lobby.state.locked, false);
lobby.advance(2);
assert.equal(lobby.panels.Countdown.classes.Counting, false);
assert.equal(lobby.panels.CountdownLabel.text, '#arena_setup_countdown_idle');

// A full side refuses the join and says why.
const crowded = mount({ players: [0, 1, 2], teams: { [ANGELS]: [0], [DEMONS]: [1, 2] }, seats: 2 });
assert.equal(crowded.panels.Demons.classes.Full, true);
crowded.click('Demons');
assert.deepEqual(crowded.teams, { [ANGELS]: [0], [DEMONS]: [1, 2] });
assert.equal(crowded.panels.SetupHint.text, '#arena_setup_hint_full');
assert.deepEqual(crowded.state.sounds, ['ui_team_select_pick_team_failed']);

// More players than seats: the extras are listed, and the host cannot start without them.
const overflow = mount({ players: [0, 1, 2], teams: { [ANGELS]: [], [DEMONS]: [] }, seats: 1 });
assert.equal(overflow.panels.Wanderers.classes.Shown, true);
assert.equal(overflow.panels.WanderersList.children.length, 1);
overflow.click('StartButton');
overflow.advance(0.5);
assert.equal(overflow.state.locked, false);
assert.equal(overflow.panels.SetupHint.text, '#arena_setup_hint_unassigned');

// A player who joins late is seated by the host before the timer runs out.
const late = mount({ players: [0, 1], teams: { [ANGELS]: [], [DEMONS]: [] }, transition: 3 });
late.teams[ANGELS].splice(late.teams[ANGELS].indexOf(0), 1);
const before = late.state.autoAssigns;
late.advance(1);
assert.equal(late.state.autoAssigns, before);
late.advance(2.5);
assert.equal(late.state.autoAssigns, before + 1);
assert.deepEqual(late.teams, { [ANGELS]: [0], [DEMONS]: [1] });

// Long timers switch to minutes and seconds so they still fit the medallion.
const patient = mount({ players: [0], teams: { [ANGELS]: [], [DEMONS]: [] }, transition: 150 });
assert.equal(patient.panels.CountdownValue.text, '2:30');
assert.equal(patient.panels.Countdown.classes.Long, true);

console.log('Panorama setup tests passed');
