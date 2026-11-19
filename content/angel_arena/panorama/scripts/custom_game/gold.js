/* global FindDotaHudElement, Game, PlayerTables, GameEvents, Players, Entities */
/*
  Author:
    Chronophylos
  Credits:
    Noya
    Angel Arena Blackstar
*/
'use strict';

// settings
var useFormatting = 'half';

(function () {
  PlayerTables.SubscribeNetTableListener('gold', onGoldChange);
  onGoldChange('gold', PlayerTables.GetAllTableValues('gold'));
}());

function onGoldChange (table, data) {
  var playerID = Game.GetLocalPlayerID();
  var gold = data && data.gold ? data.gold[playerID] : undefined;
  if (gold === undefined || gold === null) {
    return;
  }

  UpdateGoldHud(gold);
  UpdateGoldTooltip(gold);
}

function UpdateGoldHud (gold) {
  var shopButton = FindDotaHudElement('ShopButton');
  var goldLabel = shopButton && shopButton.FindChildTraverse('GoldLabel');
  if (!goldLabel) {
    return;
  }

  if (useFormatting === 'full') {
    goldLabel.text = FormatGold(gold);
  } else if (useFormatting === 'half') {
    goldLabel.text = FormatComma(gold);
  } else {
    goldLabel.text = gold;
  }
}

function UpdateGoldTooltip (gold) {
  var tooltip = FindDotaHudElement('DOTAHUDGoldTooltip');
  var contents = tooltip && tooltip.FindChildTraverse('Contents');
  if (!contents || contents.GetChildCount() < 2) {
    return;
  }

  var total = contents.GetChild(0);
  if (typeof total.text === 'string') {
    total.text = total.text.replace(/: [0-9]+/, ': ' + gold);
  }
  contents.GetChild(1).style.visibility = 'collapse';
}

/*
  Author:
    Noya
    Chronophylos
  Credits:
    Noya
  Description:
    Returns gold with commas and k
*/
function FormatGold (gold) {
  var formatted = FormatComma(gold);
  if (gold.toString().length > 6) {
    return FormatGold(gold.toString().substring(0, gold.toString().length - 5) / 10) + 'M';
  } else if (gold.toString().length > 4) {
    return FormatGold(gold.toString().substring(0, gold.toString().length - 3)) + 'k';
  } else {
    return formatted;
  }
}

/*
  Author:
    Noya
  Credits:
    Noya
  Description:
    Inserts Commas every 3 chars
    We use a whitespace because of some DIN
*/
function FormatComma (value) {
  try {
    return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
  } catch (e) {}
}
