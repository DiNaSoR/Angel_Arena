/* global $, Game, DOTATeam_t, DOTA_GameState, ArenaSkin */
'use strict';

// Reskins Dota's hero selection and strategy screens: the hall backdrop, the banner row with
// both sides' crests, the gilded inspector, and a "how to win" briefing in place of the
// lane map. See arena_skin.js for how native panels are restyled.
(function () {
  var skin = ArenaSkin;
  var paint = skin.paint;
  var once = skin.once;
  var paintOnce = skin.paintOnce;
  var make = skin.make;
  var image = skin.image;
  var label = skin.label;
  var serif = skin.serif;
  var GOLD = skin.GOLD;
  var GOLD_DEEP = skin.GOLD_DEEP;
  // Dota shrinks hero names to fit boxes measured for its own typeface, which makes Grenze come
  // out at a different size for every hero. The longest name fits at the sizes used here.
  var FIXED_SIZE = { 'text-overflow': 'clip' };
  var WATCH_SECONDS = 0.5;
  var FOLLOW_SECONDS = 0.15;

  var pregame = skin.hudRoot().FindChildTraverse('PreGame');
  if (!pregame) {
    return;
  }
  skin.restamp();

  function find(id) {
    return pregame.FindChildTraverse(id);
  }

  function localTeam() {
    var info = Game.GetLocalPlayerInfo();
    return info ? info.player_team_id : -1;
  }

  // ------------------------------------------------------------------ backdrop

  function backdrop() {
    var contents = pregame.FindChild('MainContents');
    if (!contents || pregame.FindChild('ArenaHall')) {
      return;
    }
    var art = image(pregame, 'ArenaHall', 'hall_backdrop.png', { width: '100%', height: '100%' },
      'stretch-to-cover-preserve-aspect');
    var shade = make('Panel', pregame, 'ArenaHallShade', {
      width: '100%',
      height: '100%',
      'background-color': 'gradient( linear, 0% 0%, 0% 100%, from( #070a10d9 ), color-stop( 0.22, #070a108c ), color-stop( 0.8, #070a10a6 ), to( #070a10f2 ) )'
    });
    // Above Dota's own pregame background, below everything the player interacts with.
    pregame.MoveChildBefore(shade, contents);
    pregame.MoveChildBefore(art, shade);
  }

  // ---------------------------------------------------------------- banner row

  function side(row, id, file, name, color, align, mine) {
    var group = make('Panel', row, id, {
      'horizontal-align': align,
      'vertical-align': 'center',
      // Lines the crests up with the hero grid on the left and the inspector on the right.
      'margin-left': align === 'left' ? '126px' : '0px',
      'margin-right': align === 'right' ? '200px' : '0px',
      'flow-children': 'right',
      opacity: mine ? '1' : '0.55',
      saturation: mine ? '1' : '0.6'
    });
    var crest = function () {
      image(group, id + 'Sigil', file, { width: '74px', height: '74px', 'vertical-align': 'center' });
    };
    var text = function () {
      label(group, id + 'Name', name, serif('44px', color, {
        'vertical-align': 'center',
        'margin-left': '10px',
        'margin-right': '10px',
        'text-shadow': skin.SHADOW
      }));
    };
    if (align === 'left') {
      crest();
      text();
    } else {
      text();
      crest();
    }
  }

  function bannerRow() {
    var titles = find('TitlesContainer');
    if (!titles || titles.FindChild('ArenaBannerRow')) {
      return;
    }
    paint(find('HeroSelectionText'), { visibility: 'collapse' });
    var row = make('Panel', titles, 'ArenaBannerRow', { width: '100%', height: '86px', 'margin-top': '-8px' });
    var team = localTeam();
    side(row, 'ArenaAngels', 'sigil_angels.png', $.Localize('#arena_team_angels'), skin.TEAL, 'left',
      team === DOTATeam_t.DOTA_TEAM_GOODGUYS);
    side(row, 'ArenaDemons', 'sigil_demons.png', $.Localize('#arena_team_demons'), skin.EMBER, 'right',
      team === DOTATeam_t.DOTA_TEAM_BADGUYS);
    label(row, 'ArenaTitle', $.Localize('#arena_pick_title'), serif('54px', skin.VELLUM, {
      'horizontal-align': 'center',
      'vertical-align': 'center',
      'text-shadow': skin.SHADOW
    }));
  }

  // ---------------------------------------------------------------- hero grid

  function grid() {
    // GridCategories > column > header > CategoryDragTarget > HeroCategoryName
    skin.findAll('HeroCategoryName', find('GridCategories'), 4).forEach(function (name) {
      paintOnce(name, serif('22px', GOLD, { 'margin-top': '-6px', height: '30px', 'text-shadow': skin.SHADOW }));
    });
  }

  // --------------------------------------------------------- hero inspector

  function corner(parent, id, horizontal, vertical, flipX, flipY) {
    image(parent, id, 'frame_corner.png', {
      width: '120px',
      height: '118px',
      'horizontal-align': horizontal,
      'vertical-align': vertical,
      'margin-top': vertical === 'top' ? '-9px' : '0px',
      // Stops above the lock-in row at the foot of the column.
      'margin-bottom': vertical === 'bottom' ? '83px' : '0px',
      'margin-left': horizontal === 'left' ? '-9px' : '0px',
      'margin-right': horizontal === 'right' ? '-9px' : '0px',
      transform: 'scale3d( ' + flipX + ', ' + flipY + ', 1 )'
    });
  }

  function inspector() {
    paintOnce(find('HeroInspect'), {
      'background-color': skin.INK,
      border: '1px solid ' + GOLD_DEEP + '99',
      'box-shadow': '#00000099 0px 6px 18px 0px'
    });
    paintOnce(find('HeroInspectHeroName'), serif('30px', skin.VELLUM, FIXED_SIZE));
    paintOnce(find('PickDescription'), serif('34px', GOLD));
    paintOnce(find('RandomButton'), { 'background-color': skin.INK, border: '1px solid ' + GOLD_DEEP + '99' });

    var column = find('HeroPickRightColumn');
    if (column && !column.FindChild('ArenaCornerTL')) {
      corner(column, 'ArenaCornerTL', 'left', 'top', '1', '1');
      corner(column, 'ArenaCornerTR', 'right', 'top', '-1', '1');
      corner(column, 'ArenaCornerBL', 'left', 'bottom', '1', '-1');
      corner(column, 'ArenaCornerBR', 'right', 'bottom', '-1', '-1');
    }

    var lock = find('LockInButton');
    once(lock, function () {
      var title = skin.firstOfType(lock, 'Label');
      if (title) {
        title.text = $.Localize('#arena_pick_lock');
      }
      for (var i = 0; i < lock.GetChildCount(); i++) {
        paint(lock.GetChild(i), serif(i === 2 ? '18px' : '30px', '#8d8676', { 'text-shadow': 'none' }));
      }
      // Dota greys this button out with a filter until a hero can be locked in. The filter is
      // switched off here and lockState() swaps the fill instead.
      paint(lock, { saturation: '1', brightness: '1' });
      lockReady = null;
    });
  }

  // The gilded fill only reads as "ready" when a hero can actually be locked in, so the colours
  // follow the same state classes Dota uses for its own disabled look.
  var lockReady = null;

  function lockState() {
    var lock = find('LockInButton');
    var ready = pregame.BHasClass('LocalPlayerInControl') && pregame.BHasClass('InspectingHero') &&
      pregame.BHasClass('InspectedHeroAvailableToPick');
    if (!lock || ready === lockReady) {
      return;
    }
    lockReady = ready;
    paint(lock, {
      'background-color': ready ? skin.GILT : skin.INK,
      border: '1px solid ' + (ready ? '#fff0c8' : GOLD_DEEP + '66')
    });
    for (var i = 0; i < lock.GetChildCount(); i++) {
      paint(lock.GetChild(i), { color: ready ? '#241503' : '#8d8676' });
    }
  }

  // ------------------------------------------------------------------- header

  function header() {
    paintOnce(find('ClockLabel'), serif('54px', GOLD, { 'margin-top': '-7px', 'text-shadow': skin.SHADOW }));
  }

  // --------------------------------------------------------- how to win plate

  function rule(parent, id, token, color) {
    var line = make('Panel', parent, id, { width: '100%', 'margin-top': '8px', 'flow-children': 'right' });
    make('Panel', line, id + 'Pip', {
      width: '9px',
      height: '9px',
      'margin-top': '9px',
      'margin-right': '14px',
      'background-color': color,
      transform: 'rotateZ( 45deg )'
    });
    label(line, id + 'Text', $.Localize(token), {
      width: 'fill-parent-flow( 1 )',
      'white-space': 'normal',
      'font-family': 'Radiance',
      'font-size': '19px',
      'line-height': '26px',
      color: '#e6dcc8'
    });
  }

  function rules(parent, prefix) {
    rule(parent, prefix + 'Kills', '#arena_loading_kills', '#80dadb');
    rule(parent, prefix + 'Boss', '#arena_loading_boss', '#ff9c76');
  }

  function bottomRow() {
    // The Dota Plus advert and the three-lane minimap say nothing about this arena.
    paintOnce(find('FriendsAndFoes'), { visibility: 'collapse' });
    paintOnce(find('StrategyFriendsAndFoes'), { visibility: 'collapse' });
    paintOnce(find('HeroPickMinimap'), { visibility: 'collapse' });

    var bottom = find('BottomPanelsContainer');
    if (!bottom || bottom.FindChild('ArenaRules')) {
      return;
    }
    var plate = make('Panel', bottom, 'ArenaRules', {
      width: '470px',
      'horizontal-align': 'left',
      'vertical-align': 'bottom',
      'margin-left': '126px',
      'margin-bottom': '34px',
      padding: '14px 22px 18px 22px',
      'flow-children': 'down',
      'background-color': '#080b12d9',
      'border-top': '1px solid ' + GOLD_DEEP + '99',
      'border-bottom': '1px solid ' + GOLD_DEEP + '33'
    });
    label(plate, 'ArenaRulesTitle', $.Localize('#arena_setup_objectives'), serif('28px', GOLD));
    rules(plate, 'ArenaRule');
    strategyVisible = null;
  }

  // The strategy screen stands the hero model where the plate is, so the plate steps aside.
  var strategyVisible = null;

  function strategyState() {
    var visible = pregame.BHasClass('StrategyVisible');
    var plate = find('ArenaRules');
    if (!plate || visible === strategyVisible) {
      return;
    }
    strategyVisible = visible;
    paint(plate, { visibility: visible ? 'collapse' : 'visible' });
  }

  // ----------------------------------------------------------- strategy screen

  function sectionHeader(section, token) {
    var bar = skin.firstOfType(section, 'Panel');
    once(bar, function () {
      paint(bar, { 'background-color': skin.BAR, 'border-bottom': '1px solid ' + GOLD_DEEP + '80' });
      var title = skin.firstOfType(bar, 'Label');
      if (title) {
        title.text = $.Localize(token);
        paint(title, serif('25px', GOLD, { 'margin-top': '-1px' }));
      }
    });
  }

  function briefing() {
    var map = find('StrategyMap');
    if (!map || map.FindChild('ArenaBriefing')) {
      return;
    }
    // Lanes and ward spots belong to the standard Dota map, not to the arena.
    paint(find('StrategyMapContents'), { visibility: 'collapse' });

    var angels = localTeam() !== DOTATeam_t.DOTA_TEAM_BADGUYS;
    var panel = make('Panel', map, 'ArenaBriefing', {
      width: '100%',
      'margin-top': '8px',
      'margin-left': '14px',
      'margin-right': '20px',
      'flow-children': 'right'
    });
    image(panel, 'ArenaBriefingSigil', angels ? 'sigil_angels.png' : 'sigil_demons.png', {
      width: '210px',
      height: '210px',
      'margin-top': '16px',
      'margin-right': '26px'
    });
    var text = make('Panel', panel, 'ArenaBriefingText', {
      width: 'fill-parent-flow( 1 )',
      'margin-top': '18px',
      'flow-children': 'down'
    });
    label(text, 'ArenaBriefingSide',
      $.Localize(angels ? '#arena_strategy_side_angels' : '#arena_strategy_side_demons'),
      serif('40px', angels ? skin.TEAL : skin.EMBER));
    label(text, 'ArenaBriefingPremise', $.Localize('#arena_loading_premise'), {
      width: '100%',
      'margin-top': '4px',
      'margin-bottom': '8px',
      'white-space': 'normal',
      'font-family': 'Radiance',
      'font-size': '19px',
      'line-height': '26px',
      color: '#b9ad98'
    });
    rules(text, 'ArenaBriefingRule');
  }

  function strategy() {
    paintOnce(find('SelectedHeroName'), serif('44px', skin.VELLUM, FIXED_SIZE));
    paintOnce(find('EnterBattle'), { color: GOLD_DEEP });
    sectionHeader(find('StrategyMap'), '#arena_setup_objectives');
    sectionHeader(find('StartingItems'), '#arena_strategy_items');
    briefing();
  }

  // ---------------------------------------------------------------- scheduling

  var steps = [backdrop, bannerRow, grid, inspector, header, bottomRow, strategy];

  function over() {
    return Game.GameStateIsAfter(DOTA_GameState.DOTA_GAMERULES_STATE_TEAM_SHOWCASE);
  }

  // Dota builds parts of these screens late (the hero grid, the strategy tabs), so the tree is
  // checked on a slow timer. A step that finds nothing new to paint writes nothing.
  function watch() {
    if (over()) {
      return;
    }
    steps.forEach(function (step) {
      try {
        step();
      } catch (error) {
        $.Msg('[arena_pregame] ' + error);
      }
    });
    $.Schedule(WATCH_SECONDS, watch);
  }

  // Pieces that depend on what the player is doing follow more closely, and write on change only.
  function follow() {
    if (over()) {
      return;
    }
    lockState();
    strategyState();
    $.Schedule(FOLLOW_SECONDS, follow);
  }

  watch();
  follow();
}());
