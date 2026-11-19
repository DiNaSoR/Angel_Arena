'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const panorama = path.join(__dirname, '../content/angel_arena/panorama');
const layout = fs.readFileSync(path.join(panorama, 'layout/custom_game/arena_match.xml'), 'utf8');
const script = fs.readFileSync(path.join(panorama, 'scripts/custom_game/arena_match.js'), 'utf8');
const panelIds = Array.from(layout.matchAll(/\bid="([^"]+)"/g), ([, id]) => id);

function panel() {
  return {
    classes: {},
    style: {},
    SetHasClass(name, active) {
      this.classes[name] = active;
    }
  };
}

function mount(initialState, initialDuel, initialTime = 0) {
  const root = panel();
  const panels = Object.fromEntries(panelIds.map((id) => [id, panel()]));
  const $ = (selector) => panels[selector.slice(1)];
  $.GetContextPanel = () => root;
  $.Localize = (token) => token;
  let time = initialTime;
  let lastScheduleId = 0;
  const scheduled = new Map();
  $.Schedule = (_, callback) => {
    const id = ++lastScheduleId;
    scheduled.set(id, callback);
    return id;
  };
  $.CancelScheduled = (id) => assert(scheduled.delete(id));
  function runScheduled() {
    const [id, callback] = scheduled.entries().next().value;
    scheduled.delete(id);
    callback();
  }
  let listener;
  const CustomNetTables = {
    SubscribeNetTableListener(table, callback) {
      assert.equal(table, 'arena_match');
      listener = callback;
    },
    GetTableValue(table, key) {
      assert.equal(table, 'arena_match');
      if (key === 'state') {
        return initialState;
      }
      assert.equal(key, 'duel');
      return initialDuel;
    }
  };

  vm.runInNewContext(script, {
    $,
    CustomNetTables,
    Game: { GetGameTime: () => time },
    DOTATeam_t: { DOTA_TEAM_GOODGUYS: 2, DOTA_TEAM_BADGUYS: 3 }
  });
  runScheduled();
  return {
    root,
    panels,
    scheduled,
    advance(now) {
      time = now;
      runScheduled();
    },
    update(state, key = 'state') {
      listener('arena_match', key, state);
    }
  };
}

const client = mount(null);
assert.equal(client.root.classes.MatchReady, false);

client.update({ angels: 0, demons: 0, kill_limit: 10, phase: 'pre_game' });
assert.equal(client.root.classes.MatchReady, true);
assert.equal(client.panels.KillTarget.text, '10');
assert.equal(client.panels.MatchPhase.text, '#arena_match_waiting');

client.update({ angels: 3, demons: 5, kill_limit: 10, phase: 'in_progress' });
assert.equal(client.panels.AngelsScore.text, '3');
assert.equal(client.panels.DemonsScore.text, '5');
assert.equal(client.panels.AngelsFill.style.width, '30%');
assert.equal(client.panels.DemonsFill.style.width, '50%');
assert.equal(client.panels.Demons.classes.Leading, true);
assert.equal(client.panels.MatchPhase.text, '#arena_match_live');

client.update({ phase: 'waiting', deadline: 300 }, 'duel');
assert.equal(client.panels.MatchPhase.text, '#arena_duel_waiting 5:00');
assert.equal(client.root.classes.DuelActive, false);
client.advance(27.5);
assert.equal(client.panels.MatchPhase.text, '#arena_duel_waiting 4:33');
client.update({ phase: 'active', deadline: 99 }, 'duel');
assert.equal(client.panels.MatchPhase.text, '#arena_duel_active 1:12');
assert.equal(client.root.classes.DuelActive, true);
assert.equal(client.scheduled.size, 1);

client.update({ angels: 99, kill_limit: 10 }, 'other');
assert.equal(client.panels.AngelsScore.text, '3');

client.update({ angels: 4, demons: 6, kill_limit: 10, winner: 2, victory_reason: 'boss' });
assert.equal(client.root.classes.MatchFinished, true);
assert.equal(client.panels.Angels.classes.Leading, true);
assert.equal(client.panels.Winner.text, '#arena_match_angels_win');
assert.equal(client.panels.VictoryReason.text, '#arena_match_boss_defeated');
assert.equal(client.root.classes.DuelActive, false);
assert.equal(client.scheduled.size, 0);

const reconnect = mount({ angels: 2, demons: '12', kill_limit: '10', winner: '3', victory_reason: 'kills' });
assert.equal(reconnect.root.classes.DemonsWin, true);
assert.equal(reconnect.panels.DemonsFill.style.width, '100%');
assert.equal(reconnect.panels.Winner.text, '#arena_match_demons_win');
assert.equal(reconnect.panels.VictoryReason.text, '#arena_match_target_reached');

reconnect.update(null);
assert.equal(reconnect.root.classes.MatchReady, false);

const bossOnly = mount(
  { angels: 10, demons: 4, kill_limit: 0, phase: 'in_progress' },
  { phase: 'active', deadline: 420 },
  380
);
assert.equal(bossOnly.root.classes.MatchReady, true);
assert.equal(bossOnly.root.classes.BossOnly, true);
assert.equal(bossOnly.panels.AngelsFill.style.width, '0%');
assert.equal(bossOnly.panels.MatchPhase.text, '#arena_duel_active 0:40');
bossOnly.update({ phase: 'finished', deadline: 0 }, 'duel');
assert.equal(bossOnly.scheduled.size, 0);
assert.equal(bossOnly.panels.MatchPhase.text, '#arena_match_live');
bossOnly.update({ angels: 10, demons: 4, kill_limit: 0, winner: 3, victory_reason: 'boss' });
assert.equal(bossOnly.root.classes.MatchReady, true);
assert.equal(bossOnly.root.classes.MatchFinished, true);
assert.equal(bossOnly.panels.VictoryReason.text, '#arena_match_boss_defeated');
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
