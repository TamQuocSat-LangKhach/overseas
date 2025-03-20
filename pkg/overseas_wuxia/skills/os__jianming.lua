local os__jianming = fk.CreateSkill {
  name = "os__jianming"
}

Fk:loadTranslationTable{
  ['os__jianming'] = '剑鸣',
  ['@os__jianming-turn'] = '剑鸣',
  [':os__jianming'] = '锁定技，每回合每花色限一次，当你使用或打出一种花色的【杀】时，你摸一张牌。',
  ['$os__jianming1'] = '弹剑作谱，鸣之铮铮。',
  ['$os__jianming2'] = '剑鸣凄凄，穿心刺骨。',
}

os__jianming:addEffect(fk.AfterCardUseDeclared, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__jianming.name) and data.card.trueName == "slash" and data.card.suit ~= Card.NoSuit then
      local suitsRecorded = player:getTableMark("@os__jianming-turn")
      return not table.contains(suitsRecorded, "log_" .. data.card:getSuitString())
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, os__jianming.name)
    local suitsRecorded = player:getTableMark("@os__jianming-turn")
    table.insert(suitsRecorded, "log_" .. data.card:getSuitString())
    player.room:setPlayerMark(player, "@os__jianming-turn", suitsRecorded)
  end,
})

os__jianming:addEffect(fk.CardResponding, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__jianming.name) and data.card.trueName == "slash" and data.card.suit ~= Card.NoSuit then
      local suitsRecorded = player:getTableMark("@os__jianming-turn")
      return not table.contains(suitsRecorded, "log_" .. data.card:getSuitString())
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, os__jianming.name)
    local suitsRecorded = player:getTableMark("@os__jianming-turn")
    table.insert(suitsRecorded, "log_" .. data.card:getSuitString())
    player.room:setPlayerMark(player, "@os__jianming-turn", suitsRecorded)
  end,
})

return os__jianming
