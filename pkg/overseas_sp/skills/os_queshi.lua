local osQueshi = fk.CreateSkill{
  name = "os__queshi"
}

Fk:loadTranslationTable{
  ["os__queshi"] = "鹊拾",
  [":os__queshi"] = "游戏开始时，你将【银月枪】置入你的装备区。当你发动“扶汉”后，你从游戏外、场上、牌堆或弃牌堆中获得【银月枪】。",
}

local U = require "packages/utility/utility"

osQueshi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osQueshi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardId = U.prepareDeriveCards(room, { { "moon_spear", Card.Diamond, 12 } }, "os__queshi_spear")[1]
    if U.canMoveCardIntoEquip(player, cardId, true) then
      room:moveCardIntoEquip(player, cardId, osQueshi.name, true, player)
    end
  end,
})

osQueshi:addEffect(fk.AfterSkillEffect, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osQueshi.name) and data.skill.name == "os__fuhan"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardId = U.prepareDeriveCards(room, { { "moon_spear", Card.Diamond, 12 } }, "os__queshi_spear")[1]
    if table.contains({Card.PlayerEquip, Card.PlayerJudge, Card.DiscardPile, Card.DrawPile, Card.Void}, room:getCardArea(cardId)) then
      room:obtainCard(player, cardId, true, fk.ReasonPrey, player, osQueshi.name)
    end
  end,
})

return osQueshi
