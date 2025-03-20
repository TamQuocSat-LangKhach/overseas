local os__jieyu = fk.CreateSkill {
  name = "os__jieyu"
}

Fk:loadTranslationTable{
  ['os__jieyu'] = '竭御',
  [':os__jieyu'] = '每轮限一次，结束阶段开始时或每轮第一次受到伤害后，你可弃置所有手牌，然后从弃牌堆中获得不同牌名的基本牌各一张。',
  ['$os__jieyu1'] = '葭萌，蜀之咽喉，峻必竭力守之。',
  ['$os__jieyu2'] = '吾头可得，城不可得。',
}

os__jieyu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if target ~= player or not player:hasSkill(os__jieyu) or player:usedSkillTimes(os__jieyu.name, Player.HistoryRound) > 0 or player:isKongcheng() then
      return false
    end
    return player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:throwAllCards("h")
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and card.type == Card.TypeBasic then
        table.insert(allCardNames, card.name)
      end
    end
    if #allCardNames == 0 then return false end
    local cards = {}
    table.forEach(allCardNames, function(name)
      table.insert(cards, room:getCardsFromPileByRule(name, 1, "discardPile"))
    end)
    room:obtainCard(player, cards, false, fk.ReasonPrey)
  end,
})

os__jieyu:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player)
    if target ~= player or not player:hasSkill(os__jieyu) or player:usedSkillTimes(os__jieyu.name, Player.HistoryRound) > 0 or player:isKongcheng() then
      return false
    end
    local events = player.room.logic:getEventsOfScope(GameEvent.Damage, 1, function(e)
      return e.data[1].to == player
    end, Player.HistoryRound)
    return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:throwAllCards("h")
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if not table.contains(allCardNames, card.name) and card.type == Card.TypeBasic then
        table.insert(allCardNames, card.name)
      end
    end
    if #allCardNames == 0 then return false end
    local cards = {}
    table.forEach(allCardNames, function(name)
      table.insert(cards, room:getCardsFromPileByRule(name, 1, "discardPile"))
    end)
    room:obtainCard(player, cards, false, fk.ReasonPrey)
  end,
})

return os__jieyu
