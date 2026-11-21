'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const panorama = path.join(__dirname, '../content/angel_arena/panorama');
const read = (file) => fs.readFileSync(path.join(panorama, file), 'utf8');
const skinScript = read('scripts/custom_game/arena_skin.js');
const matchScript = read('scripts/custom_game/arena_match.js');
const TEAMS = { DOTA_TEAM_GOODGUYS: 2, DOTA_TEAM_BADGUYS: 3 };

// A stand-in for a Panorama panel: enough of the tree API for the skin helpers.
function panel(id, parent) {
  const node = {
    id,
    text: '',
    style: {},
    attributes: {},
    children: [],
    actuallayoutwidth: 0,
    actualxoffset: 0,
    actualuiscale_x: 1,
    GetParent: () => parent || null,
    GetChildCount: () => node.children.length,
    GetChild: (index) => node.children[index],
    FindChild: (childId) => node.children.find((child) => child.id === childId) || null,
    FindChildTraverse(childId) {
      for (const child of node.children) {
        const found = child.id === childId ? child : child.FindChildTraverse(childId);
        if (found) {
          return found;
        }
      }
      return null;
    },
    GetAttributeInt: (name, fallback) => (name in node.attributes ? node.attributes[name] : fallback),
    SetAttributeInt(name, value) {
      node.attributes[name] = value;
    }
  };
  if (parent) {
    parent.children.push(node);
  }
  return node;
}

// Dota's top bar, reduced to the panels the script looks for, at a UI scale of 2. Each team
// has a 1000 pixel container; its row of portraits is 480 wide and stops 20 short of the clock.
function hud(withTopBar = true) {
  const root = panel('DotaHud');
  const context = panel('ArenaMatch', panel('CustomUIContainer_Hud', root));
  if (withTopBar) {
    const bar = panel('topbar', root);
    for (const team of ['Radiant', 'Dire']) {
      const container = panel(`TopBar${team}TeamContainer`, bar);
      container.actuallayoutwidth = 1000;
      const row = panel(`TopBar${team}Players`, container);
      row.actualxoffset = team === 'Radiant' ? 480 : 0;
      const players = panel(`${team}TeamScorePlayers`, row);
      players.actualxoffset = 20;
      players.actuallayoutwidth = 480;
      players.actualuiscale_x = 2;
      panel(`TopBar${team}Score`, players);
    }
  }
  return { root, context };
}

function mount(initialState, initialDuel, initialTime = 0, withTopBar = true) {
  const tree = hud(withTopBar);
  let time = initialTime;
  let lastScheduleId = 0;
  const scheduled = new Map();
  const $ = () => null;
  $.GetContextPanel = () => tree.context;
  $.Localize = (token) => token;
  $.Msg = () => {};
  $.CreatePanel = (type, parent, id) => panel(id, parent);
  $.Schedule = (_, callback) => {
    const id = ++lastScheduleId;
    scheduled.set(id, callback);
    return id;
  };
  $.CancelScheduled = (id) => assert(scheduled.delete(id));
  let listener;
  const CustomNetTables = {
    SubscribeNetTableListener(table, callback) {
      assert.equal(table, 'arena_match');
      listener = callback;
    },
    GetTableValue(table, key) {
      assert.equal(table, 'arena_match');
      return key === 'state' ? initialState : initialDuel;
    }
  };
  const context = vm.createContext({
    $,
    CustomNetTables,
    Game: { GetGameTime: () => time },
    DOTATeam_t: TEAMS
  });
  vm.runInContext(skinScript, context);
  vm.runInContext(matchScript, context);
  const text = (id) => tree.root.FindChildTraverse(id).text;
  return {
    root: tree.root,
    scheduled,
    view: vm.runInContext('ArenaMatchView', context),
    goal: () => [text('ArenaGoalCaption'), text('ArenaGoalValue')],
    phase: () => [text('ArenaPhaseCaption'), text('ArenaPhaseValue')],
    advance(now) {
      time = now;
      const [id, callback] = scheduled.entries().next().value;
      scheduled.delete(id);
      callback();
    },
    update(state, key = 'state') {
      listener('arena_match', key, state);
    }
  };
}

// The captions sit inside Dota's top bar, pushed clear of the portraits.
const client = mount(null);
const goalBlock = client.root.FindChildTraverse('ArenaGoal');
assert.equal(goalBlock.GetParent().id, 'TopBarRadiantTeamContainer');
assert.equal(goalBlock.style.marginRight, '264px');
assert.equal(client.root.FindChildTraverse('ArenaPhase').style.marginLeft, '264px');
assert.equal(client.root.FindChildTraverse('TopBarRadiantScore').style.fontFamily, 'Grenze');
assert.deepEqual(client.goal(), ['', '']);
assert.equal(client.scheduled.size, 0);

client.update({ angels: 0, demons: 0, kill_limit: 10, phase: 'pre_game' });
assert.deepEqual(client.goal(), ['#arena_kill_target', '10']);
assert.deepEqual(client.phase(), ['#arena_match_waiting', '']);

client.update({ angels: 3, demons: 5, kill_limit: 10, phase: 'in_progress' });
assert.deepEqual(client.phase(), ['#arena_match_live', '']);
assert.equal(client.scheduled.size, 0);

// A duel clock counts down and keeps the script ticking only while it runs.
client.update({ phase: 'waiting', deadline: 300 }, 'duel');
assert.deepEqual(client.phase(), ['#arena_duel_waiting', '5:00']);
assert.equal(client.scheduled.size, 1);
client.advance(27.5);
assert.deepEqual(client.phase(), ['#arena_duel_waiting', '4:33']);
client.update({ phase: 'active', deadline: 99 }, 'duel');
assert.deepEqual(client.phase(), ['#arena_duel_active', '1:12']);
assert.equal(client.root.FindChildTraverse('ArenaPhaseValue').style.color, '#ffc8a8');
assert.equal(client.scheduled.size, 1);

client.update({ angels: 99, kill_limit: 10 }, 'other');
assert.deepEqual(client.goal(), ['#arena_kill_target', '10']);

client.update({ angels: 4, demons: 6, kill_limit: 10, winner: 2, victory_reason: 'boss' });
assert.deepEqual(client.goal(), ['#arena_match_angels_win', '']);
assert.deepEqual(client.phase(), ['#arena_match_boss_defeated', '']);
assert.equal(client.scheduled.size, 0);

const reconnect = mount({ angels: 2, demons: '12', kill_limit: '10', winner: '3', victory_reason: 'kills' });
assert.deepEqual(reconnect.goal(), ['#arena_match_demons_win', '']);
assert.deepEqual(reconnect.phase(), ['#arena_match_target_reached', '']);
reconnect.update(null);
assert.deepEqual(reconnect.goal(), ['', '']);

// With no kill target the goal is the boss.
const bossOnly = mount(
  { angels: 10, demons: 4, kill_limit: 0, phase: 'in_progress' },
  { phase: 'active', deadline: 420 },
  380
);
assert.deepEqual(bossOnly.goal(), ['#arena_boss_only_objective', '']);
assert.deepEqual(bossOnly.phase(), ['#arena_duel_active', '0:40']);
bossOnly.update({ phase: 'finished', deadline: 0 }, 'duel');
assert.equal(bossOnly.scheduled.size, 0);
assert.deepEqual(bossOnly.phase(), ['#arena_match_live', '']);

// A HUD without the expected top bar is left alone rather than raising errors.
const bare = mount({ angels: 0, demons: 0, kill_limit: 10, phase: 'in_progress' }, null, 0, false);
assert.equal(bare.scheduled.size, 0);
assert.equal(bare.view.describe(null), null);
assert.equal(bare.view.clock(125), '2:05');
console.log('Panorama match tests passed');

const notificationScript = fs.readFileSync(path.join(panorama, 'scripts/barebones_notifications.js'), 'utf8');
const top = { GetChildCount: () => 0, GetChild: () => null };
const events = {};
const labels = [];
const $ = () => top;
$.CreatePanel = (type) => {
  const result = { AddClass() {} };
  if (type === 'Label') {
    labels.push(result);
  }
  return result;
};
$.Localize = (token) => {
  assert.equal(token, '#notifications_gold');
  return ' Gold';
};
$.Schedule = () => {};
vm.runInNewContext(notificationScript, {
  $,
  GameEvents: { Subscribe(name, listener) { events[name] = listener; } }
});
events.top_notification({ text: 12000 });
events.top_notification({ text: '#notifications_gold' });
assert.equal(labels[0].text, '12000');
assert.equal(labels[1].text, ' Gold');
console.log('Panorama notification tests passed');
