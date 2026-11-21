/* global $ */
'use strict';

// Shared helpers for reskinning Dota's own HUD panels (hero selection, strategy, shop).
//
// Those panels belong to the HUD, so this addon's stylesheets cannot reach them. A skin is a
// set of inline styles on existing panels, plus new panels parented into the native tree.
// Panels are looked up by id and a missing id is skipped, so a Dota update that renames a
// panel loses one piece of decoration instead of breaking the screen.
//
// Inline styles are written once per panel. The skins re-check these trees on a timer for
// panels Dota creates late, and a pass that finds nothing new must not write anything.
var ArenaSkin = (function () {
  var IMAGES = 'file://{images}/custom_game/arena_ui/';
  // Marks panels painted by the current load of a skin, so a reload repaints and a refresh
  // does not. Each skin script calls restamp() as it starts.
  var stamp = 0;

  function restamp() {
    stamp = Math.floor(Date.now() % 1000000000);
  }
  var reported = {};

  function camel(name) {
    return name.replace(/-([a-z0-9])/g, function (match, letter) { return letter.toUpperCase(); });
  }

  // Panorama throws on a style value it cannot parse. One bad value must not stop the rest of
  // the skin, so each property is applied on its own and a failure is reported once.
  function paint(panel, styles) {
    if (!panel) {
      return;
    }
    for (var name in styles) {
      try {
        panel.style[camel(name)] = styles[name];
      } catch (error) {
        if (!reported[name]) {
          reported[name] = true;
          $.Msg('[arena_skin] could not set ' + name + ': ' + styles[name] + ' (' + error + ')');
        }
      }
    }
  }

  // Runs `apply` the first time this panel is seen. Returns true when it ran.
  function once(panel, apply) {
    if (!panel || panel.GetAttributeInt('arena_skin', 0) === stamp) {
      return false;
    }
    panel.SetAttributeInt('arena_skin', stamp);
    apply(panel);
    return true;
  }

  // True for a panel last painted by an earlier load of the script. Anything it holds, such
  // as click handlers, belongs to code that is no longer running.
  function stale(panel) {
    return !!panel && panel.GetAttributeInt('arena_skin', 0) !== stamp;
  }

  function paintOnce(panel, styles) {
    return once(panel, function () { paint(panel, styles); });
  }

  // Descendants with this id, no deeper than `depth` levels. Several native panels repeat an
  // id once per column, and the depth limit keeps the search out of long item and hero lists.
  function findAll(id, scope, depth, found) {
    found = found || [];
    if (!scope || depth <= 0) {
      return found;
    }
    var count = scope.GetChildCount();
    for (var i = 0; i < count; i++) {
      var child = scope.GetChild(i);
      if (child.id === id) {
        found.push(child);
      } else {
        findAll(id, child, depth - 1, found);
      }
    }
    return found;
  }

  function firstOfType(panel, type) {
    for (var i = 0; panel && i < panel.GetChildCount(); i++) {
      var child = panel.GetChild(i);
      if (child.paneltype === type) {
        return child;
      }
    }
    return null;
  }

  // Finds or creates a decoration. Its styles are written only when it is new to this load.
  function make(type, parent, id, styles) {
    if (!parent) {
      return null;
    }
    var panel = parent.FindChild(id);
    if (!panel) {
      panel = $.CreatePanel(type, parent, id);
      panel.hittest = false;
    }
    paintOnce(panel, styles);
    return panel;
  }

  function image(parent, id, file, styles, scaling) {
    var existed = parent && parent.FindChild(id);
    var panel = make('Image', parent, id, styles);
    if (panel && !existed) {
      panel.SetImage(IMAGES + file);
      panel.SetScaling(scaling || 'stretch-to-fit-preserve-aspect');
    }
    return panel;
  }

  function label(parent, id, text, styles) {
    var existed = parent && parent.FindChild(id);
    var panel = make('Label', parent, id, styles);
    if (panel && !existed) {
      panel.text = text;
    }
    return panel;
  }

  // Inscription style: Grenze, the display face used across the Angel Arena screens.
  function serif(size, color, extra) {
    var styles = {
      'font-family': 'Grenze',
      'font-weight': 'bold',
      'font-size': size,
      'letter-spacing': '0px',
      'text-transform': 'none',
      color: color
    };
    for (var name in extra || {}) {
      styles[name] = extra[name];
    }
    return styles;
  }

  // Dota writes many headings in capitals. Grenze is drawn for mixed case, so "STARTING ITEMS"
  // becomes "Starting items". Text with any lower-case letter is left alone.
  function sentenceCase(text) {
    if (!text || text !== text.toUpperCase() || text === text.toLowerCase()) {
      return text;
    }
    return text.charAt(0) + text.slice(1).toLowerCase();
  }

  function hudRoot() {
    var panel = $.GetContextPanel();
    while (panel.GetParent()) {
      panel = panel.GetParent();
    }
    return panel;
  }

  return {
    GOLD: '#ffe2a0',
    GOLD_DEEP: '#d9a85b',
    VELLUM: '#fbefd6',
    TEAL: '#c9f6f4',
    EMBER: '#ffc8a8',
    INK: 'gradient( linear, 0% 0%, 0% 100%, from( #141c29f5 ), to( #0a0e16fa ) )',
    GILT: 'gradient( linear, 0% 0%, 0% 100%, from( #ffd98f ), to( #c98a2e ) )',
    BAR: 'gradient( linear, 0% 0%, 100% 0%, from( #2a1d0af2 ), color-stop( 0.6, #120e0ad9 ), to( #0b101966 ) )',
    SHADOW: '0px 2px 6px 3.0 #05070bf2',
    IMAGES: IMAGES,
    restamp: restamp,
    paint: paint,
    once: once,
    paintOnce: paintOnce,
    stale: stale,
    findAll: findAll,
    firstOfType: firstOfType,
    make: make,
    image: image,
    label: label,
    serif: serif,
    sentenceCase: sentenceCase,
    hudRoot: hudRoot
  };
}());
