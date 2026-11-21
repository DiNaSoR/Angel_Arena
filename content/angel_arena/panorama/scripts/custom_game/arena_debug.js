/* TEMPORARY development helper: console commands for inspecting the native HUD. */
(function () {
  // Console commands cannot be re-registered, so every load gets a fresh prefix.
  var container = $.GetContextPanel().GetParent();
  var kind = container ? container.id : '';
  var prefix = 'aa' + (Date.now() % 10000000) + '_';
  function root() {
    var p = $.GetContextPanel();
    while (p.GetParent()) { p = p.GetParent(); }
    return p;
  }
  function find(id) {
    if (id === 'CTX') { return $.GetContextPanel().GetParent(); }
    return id === 'ROOT' ? root() : root().FindChildTraverse(id);
  }
  function line(p, depth) {
    var txt = '';
    try { if (p.text) { txt = ' "' + String(p.text).slice(0, 30).replace(/\n/g, ' ') + '"'; } } catch (e) {}
    return new Array(depth + 1).join('  ') + p.paneltype + '#' + p.id +
      ' [' + Math.round(p.actualxoffset) + ',' + Math.round(p.actualyoffset) + ' ' +
      Math.round(p.actuallayoutwidth) + 'x' + Math.round(p.actuallayoutheight) + ']' + (p.visible ? '' : ' HIDDEN') + txt;
  }
  function dump(p, depth, max, visibleOnly, maxKids) {
    if (visibleOnly && !p.visible) { return; }
    $.Msg('AADUMP ' + line(p, depth));
    if (depth >= max) { return; }
    var n = p.GetChildCount();
    for (var i = 0; i < n; i++) {
      if (i >= maxKids) { $.Msg('AADUMP ' + new Array(depth + 2).join('  ') + '... +' + (n - i) + ' more'); break; }
      dump(p.GetChild(i), depth + 1, max, visibleOnly, maxKids);
    }
  }
  function add(name, fn) { Game.AddCommand(prefix + name, fn, '', 0); }
  add('dump', function (name, id, depth, visibleOnly, maxKids) {
    var p = find(id);
    if (!p) { $.Msg('AADUMP not found: ' + id); return; }
    dump(p, 0, Number(depth || 3), visibleOnly === '1', Number(maxKids || 40));
    $.Msg('AADUMP done');
  });
  add('path', function (name, id) {
    var p = find(id); var out = [];
    while (p) { out.push(p.paneltype + '#' + p.id); p = p.GetParent(); }
    $.Msg('AADUMP ' + out.join(' < '));
  });
  add('style', function (name, id, prop) {
    var p = find(id);
    if (!p) { $.Msg('AADUMP not found: ' + id); return; }
    var value = Array.prototype.slice.call(arguments, 3).join(' ');
    p.style[prop] = value;
    $.Msg('AADUMP set ' + id + ' ' + prop + ' = ' + value);
  });
  add('click', function (name, id) {
    var p = find(id);
    if (!p) { $.Msg('AADUMP not found: ' + id); return; }
    $.DispatchEvent('Activated', p, 'mouse');
    $.Msg('AADUMP clicked ' + id);
  });
  add('clickchild', function (name, id, index) {
    var p = find(id);
    var c = p && p.GetChild(Number(index || 0));
    if (!c) { $.Msg('AADUMP not found: ' + id + '[' + index + ']'); return; }
    $.DispatchEvent('Activated', c, 'mouse');
    $.Msg('AADUMP clicked child ' + index + ' of ' + id);
  });
  add('has', function (name, id, cls) {
    var p = find(id);
    $.Msg('AADUMP ' + id + ' has ' + cls + ' = ' + (p ? p.BHasClass(cls) : 'no panel'));
  });
  add('hold', function () {
    Game.SetAutoLaunchEnabled(false);
    Game.SetRemainingSetupTime(-1);
    $.Msg('AADUMP holding setup');
  });
  add('setup_time', function (name, seconds) {
    Game.SetRemainingSetupTime(Number(seconds));
    $.Msg('AADUMP setup time ' + seconds);
  });
  add('tip', function (name, id, ability) {
    var p = find(id);
    if (!p) { $.Msg('AADUMP not found: ' + id); return; }
    $.DispatchEvent('DOTAShowAbilityTooltip', p, ability);
    $.Msg('AADUMP tooltip ' + ability);
  });
  add('state', function () {
    $.Msg('AADUMP state=' + Game.GetState() + ' time=' + Game.GetGameTime() + ' local=' + Game.GetLocalPlayerID());
  });
  add('cam', function (name, x, y, dist, pitch, yaw, z) {
    GameUI.SetCameraTargetPosition([Number(x), Number(y), Number(z || 0)], 0.01);
    GameUI.SetCameraDistance(Number(dist || 1800));
    if (pitch) { GameUI.SetCameraPitchMin(Number(pitch)); GameUI.SetCameraPitchMax(Number(pitch)); }
    GameUI.SetCameraYaw(Number(yaw || 0));
    GameUI.SetCameraLookAtPositionHeightOffset(Number(z || 0));
    $.Msg('AADUMP cam ' + [x, y, dist, pitch, yaw, z].join(' '));
  });
  add('hud', function (name, on) {
    var root = $.GetContextPanel();
    while (root.GetParent()) { root = root.GetParent(); }
    var hud = root.FindChildTraverse('HUDElements');
    if (hud) { hud.style.opacity = on === '1' ? '1' : '0'; }
    var custom = root.FindChildTraverse('CustomUIRoot');
    if (custom) { custom.style.opacity = on === '1' ? '1' : '0'; }
    $.Msg('AADUMP hud ' + on);
  });
  $.Msg('AADUMP ready prefix=' + prefix + ' kind=' + kind);
}());
