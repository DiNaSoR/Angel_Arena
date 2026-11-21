/* global $, ArenaSkin */
'use strict';

// Rebuilds Dota's in-game shop as the arena armoury: a side menu with one entry per category
// on the left, and that category's items, drawn large, on the right.
//
// The items themselves stay Dota's own shop panels, so buying, quick-buy, recipes, stock and
// tooltips all keep working. This script only rearranges them: it hides the tab row and every
// category but the chosen one, and widens what is left. See arena_skin.js for how native
// panels are restyled.
(function () {
  var skin = ArenaSkin;
  var paint = skin.paint;
  var paintOnce = skin.paintOnce;
  var once = skin.once;
  var make = skin.make;
  var serif = skin.serif;
  var GOLD = skin.GOLD;
  var GOLD_DEEP = skin.GOLD_DEEP;
  var SLATE = 'gradient( linear, 0% 0%, 0% 100%, from( #161e2bfa ), to( #0a0e16fc ) )';
  var MENU_WIDTH = 164;
  var ITEM_SCALE = '135%';
  var WATCH_SECONDS = 1;

  // One page per shop category, in menu order. `grid` and `index` locate Dota's category panel,
  // `tab` is the native tab it lives under, `icon` is an item that stands for the category.
  var PAGES = [
    { tab: 'GridBasicsTab', grid: 'GridBasicItems', index: 0, icon: 'item_arena_angels_tear', note: '#arena_shop_consumables' },
    { tab: 'GridBasicsTab', grid: 'GridBasicItems', index: 1, icon: 'item_arena_prism_core', note: '#arena_shop_attributes' },
    { tab: 'GridBasicsTab', grid: 'GridBasicItems', index: 2, icon: 'item_arena_gladius', note: '#arena_shop_equipment' },
    { tab: 'GridBasicsTab', grid: 'GridBasicItems', index: 3, icon: 'item_arena_lucky_coin', note: '#arena_shop_miscellaneous' },
    { tab: 'GridBasicsTab', grid: 'GridBasicItems', index: 4, icon: 'item_arena_fallen_star', note: '#arena_shop_secret' },
    { tab: 'GridUpgradesTab', grid: 'GridUpgradeItems', index: 0, icon: 'item_arena_legion_greaves', note: '#arena_shop_accessories' },
    { tab: 'GridUpgradesTab', grid: 'GridUpgradeItems', index: 1, icon: 'item_arena_beacon_of_hope', note: '#arena_shop_support' },
    { tab: 'GridUpgradesTab', grid: 'GridUpgradeItems', index: 2, icon: 'item_arena_staff_of_sunfire', note: '#arena_shop_magical' },
    { tab: 'GridUpgradesTab', grid: 'GridUpgradeItems', index: 3, icon: 'item_arena_paladin_plate', note: '#arena_shop_armor' },
    { tab: 'GridUpgradesTab', grid: 'GridUpgradeItems', index: 4, icon: 'item_arena_seraph_blade', note: '#arena_shop_weapons' },
    { tab: 'GridUpgradesTab', grid: 'GridUpgradeItems', index: 5, icon: 'item_arena_archangel_wings', note: '#arena_shop_artifacts' }
  ];
  var FIRST_UPGRADE = 5;

  var hud = skin.hudRoot();
  var shop = null;
  var selected = 0;
  var activeTab = null;
  skin.restamp();

  function find(id) {
    return shop.FindChildTraverse(id);
  }

  function category(page) {
    var grid = find(page.grid);
    return grid ? grid.GetChild(page.index) : null;
  }

  // Restyles a heading and rewrites capitals as sentence case to suit the serif.
  function heading(panel, size, color, extra) {
    once(panel, function () {
      panel.text = skin.sentenceCase(panel.text);
      paint(panel, serif(size, color, extra));
    });
  }

  // Shows or hides a panel, writing the style only when the answer changes.
  function show(panel, visible) {
    var wanted = visible ? 1 : 2;
    if (panel && panel.GetAttributeInt('arena_shown', 0) !== wanted) {
      panel.SetAttributeInt('arena_shown', wanted);
      paint(panel, { visibility: visible ? 'visible' : 'collapse' });
    }
  }

  // ------------------------------------------------------------------- frame

  function frame() {
    paintOnce(find('Main'), {
      'background-color': SLATE,
      'border-left': '1px solid ' + GOLD_DEEP + '99',
      'border-top': '1px solid ' + GOLD_DEEP + '99',
      'box-shadow': '#000000b3 -6px 0px 22px 0px'
    });
    paintOnce(find('GridMainShop'), { 'background-color': 'none' });
    paintOnce(find('SearchAndButtonsContainer'), {
      'background-color': 'gradient( linear, 0% 0%, 100% 0%, from( #2a1d0af2 ), color-stop( 0.7, #120e0ae6 ), to( #0b1019cc ) )',
      'border-bottom': '1px solid ' + GOLD_DEEP + '66'
    });
    paintOnce(find('SearchBox'), { 'background-color': '#05070bcc', border: '1px solid ' + GOLD_DEEP + '80' });
    paintOnce(find('GuideFlyout'), {
      'background-color': 'gradient( linear, 0% 0%, 0% 100%, from( #131a26f0 ), to( #0a0e16f5 ) )',
      'border-top': '1px solid ' + GOLD_DEEP + '66'
    });
    // The side menu takes over from the tab row, and the page needs the team-items column's width.
    paintOnce(find('GridShopHeaders'), { visibility: 'collapse' });
    paintOnce(find('FilterContainer'), { visibility: 'collapse' });
    // Dota lays this row out right to left, so the menu, added last, sits on the left and the
    // item pages take whatever width remains.
    var contents = find('GridMainShopContents');
    paintOnce(contents, { 'background-color': '#0c111acc', width: 'fill-parent-flow( 1 )', height: '100%' });
    // The last, unnamed child is Dota's "right-click for options" hint. It floats over the
    // bottom row of a page that scrolls.
    var hint = contents && contents.GetChild(contents.GetChildCount() - 1);
    if (hint && !hint.id) {
      paintOnce(hint, { visibility: 'collapse' });
    }
    // Each page is given the full height of the shop, all the way down from the tab panels,
    // so that it has something to scroll within.
    ['GridBasicItemsCategory', 'GridUpgradesCategory', 'GridBasicItems', 'GridUpgradeItems'].forEach(function (id) {
      paintOnce(find(id), { width: '100%', height: '100%' });
    });
    skin.findAll('CategoryName', find('Categories'), 3).forEach(function (title) {
      heading(title, '17px', GOLD, { height: '22px', 'margin-top': '1px', 'margin-bottom': '1px', 'text-overflow': 'clip' });
    });
    heading(find('PinnedLabel'), '17px', GOLD);
  }

  // The recipe area is empty until an item is selected. The armoury painting fills it and
  // sits behind the recipe tree once there is one.
  function recipeArea() {
    paintOnce(find('ItemCombinesAndBasicItemsContainer'), {
      'background-color': '#080b12f2',
      'border-top': '1px solid ' + GOLD_DEEP + '66'
    });
    paintOnce(find('ItemCombines'), {
      'background-image': 'url("' + skin.IMAGES + 'armory_strip.png")',
      'background-size': '100% 100%',
      'background-repeat': 'no-repeat'
    });
  }

  // --------------------------------------------------------------- side menu

  function entryStyle(active, hover) {
    return {
      'background-color': active ? 'gradient( linear, 0% 0%, 100% 0%, from( #3a2a10f2 ), to( #1a140a66 ) )'
        : hover ? '#ffffff12' : 'none',
      'border-left': '3px solid ' + (active ? GOLD : '#00000000')
    };
  }

  function entry(menu, index) {
    var page = PAGES[index];
    var source = category(page);
    var title = source && source.FindChild('ShopItemsHeader');
    if (!title || menu.FindChild('ArenaShopPage' + index)) {
      return;
    }
    if (index === FIRST_UPGRADE) {
      make('Panel', menu, 'ArenaShopDivider', {
        width: '100%',
        height: '1px',
        'margin-top': '6px',
        'margin-bottom': '6px',
        'background-color': 'gradient( linear, 0% 0%, 100% 0%, from( ' + GOLD_DEEP + '00 ), color-stop( 0.5, ' + GOLD_DEEP + 'aa ), to( ' + GOLD_DEEP + '00 ) )'
      });
    }
    var button = $.CreatePanel('Button', menu, 'ArenaShopPage' + index);
    paint(button, { width: '100%', height: '40px', 'flow-children': 'right' });
    paint(button, entryStyle(index === selected, false));
    var icon = $.CreatePanel('DOTAItemImage', button, 'ArenaShopPageIcon' + index);
    icon.itemname = page.icon;
    icon.SetScaling('stretch-to-fit-preserve-aspect');
    icon.hittest = false;
    paint(icon, {
      width: '41px',
      height: '30px',
      'margin-left': '8px',
      'vertical-align': 'center',
      border: '1px solid ' + GOLD_DEEP + '80'
    });
    var name = skin.label(button, 'ArenaShopPageName' + index, skin.sentenceCase(title.text), serif('16px', skin.VELLUM, {
      'vertical-align': 'center',
      'margin-left': '9px'
    }));
    name.hittest = false;
    button.SetPanelEvent('onactivate', function () { select(index); });
    button.SetPanelEvent('onmouseover', function () { paint(button, entryStyle(index === selected, true)); });
    button.SetPanelEvent('onmouseout', function () { paint(button, entryStyle(index === selected, false)); });
  }

  function menu() {
    var parent = find('MainShopContentsVersionContainer');
    if (!parent) {
      return null;
    }
    var existing = parent.FindChild('ArenaShopMenu');
    if (skin.stale(existing)) {
      existing.RemoveAndDeleteChildren();
    }
    var panel = make('Panel', parent, 'ArenaShopMenu', {
      width: MENU_WIDTH + 'px',
      height: '100%',
      'padding-top': '8px',
      'flow-children': 'down',
      'background-color': '#080b12e6',
      'border-right': '1px solid ' + GOLD_DEEP + '55'
    });
    panel.hittest = true;
    for (var index = 0; index < PAGES.length; index++) {
      entry(panel, index);
    }
    return panel;
  }

  // -------------------------------------------------------------------- pages

  function page(index) {
    var definition = PAGES[index];
    var panel = category(definition);
    if (!panel) {
      return;
    }
    show(panel, index === selected);
    // A page is as tall as the shop and scrolls when a category has more items than fit.
    paintOnce(panel, {
      width: '100%',
      height: '100%',
      'padding-left': '14px',
      'padding-top': '8px',
      'padding-bottom': '12px',
      overflow: 'squish scroll'
    });
    var title = panel.FindChild('ShopItemsHeader');
    heading(title, '30px', GOLD, { height: '40px', padding: '0px', 'text-shadow': skin.SHADOW });
    if (title && !panel.FindChild('ArenaShopNote')) {
      var note = skin.label(panel, 'ArenaShopNote', $.Localize(definition.note), {
        width: '100%',
        'margin-bottom': '10px',
        'white-space': 'normal',
        'font-family': 'Radiance',
        'font-size': '15px',
        color: '#b9ad98'
      });
      panel.MoveChildAfter(note, title);
    }
    // Dota's grid is four small icons wide. Scaled up, five fit across the page.
    paintOnce(panel.FindChild('ShopItemsContainer'), { 'ui-scale': ITEM_SCALE, width: '100%', 'horizontal-align': 'left' });
  }

  function pages() {
    var definition = PAGES[selected];
    var tab = find(definition.tab);
    if (tab && activeTab !== definition.tab) {
      activeTab = definition.tab;
      $.DispatchEvent('Activated', tab, 'mouse');
    }
    for (var index = 0; index < PAGES.length; index++) {
      page(index);
    }
  }

  function select(index) {
    var panel = find('ArenaShopMenu');
    var previous = panel && panel.FindChild('ArenaShopPage' + selected);
    selected = index;
    paint(previous, entryStyle(false, false));
    paint(panel && panel.FindChild('ArenaShopPage' + index), entryStyle(true, true));
    pages();
  }

  var steps = [frame, recipeArea, menu, pages];

  // The shop builds its categories after the HUD loads and rebuilds them when the item list
  // changes, so the tree is checked on a slow timer. Panels already arranged are skipped
  // without a write.
  function watch() {
    shop = shop || hud.FindChildTraverse('shop');
    if (shop) {
      steps.forEach(function (step) {
        try {
          step();
        } catch (error) {
          $.Msg('[arena_shop] ' + error);
        }
      });
    }
    $.Schedule(WATCH_SECONDS, watch);
  }

  watch();
}());
