local beiding = fk.CreateSkill {
  name = "os_huan__beiding",
}

Fk:loadTranslationTable{
  ["os_huan__beiding"] = "北定",
  [":os_huan__beiding"] = "你使用〖北定〗记录的牌无距离限制且不计入次数；当你使用〖北定〗记录牌名的牌结算结束后，" ..
  "你摸一张牌，然后移除〖北定〗记录中的此牌名。",

  ["@@os__beiding_card-inhand"] = "北定",

  ["$os_huan__beiding1"] = "内外不懈如斯，长安不日可下！",
  ["$os_huan__beiding2"] = "先帝英灵冥鉴，此番定成夙愿！",

  -- 牌特殊语音
  ["$os_huan__beiding_names1"] = "炎龙归汉，燎尽不臣之贼！", -- 火攻
  ["$os_huan__beiding_names2"] = "天火离离，复光炎汉国祚！", -- 火杀
  ["$os_huan__beiding_names3"] = "亮善以谋制人，不为人谋所制！", -- 无懈
}

beiding:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(beiding.name) and
      table.contains(player:getTableMark("@$os__beiding_names"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, beiding.name, "drawcard")
    -- 牌名彩蛋
    local names = {"fire_attack", "fire__slash", "nullification"}
    if table.contains(names, data.card.name) then
      player:broadcastSkillInvoke("os_huan__beiding_names", table.indexOf(names, data.card.name))
    else
      player:broadcastSkillInvoke(beiding.name)
    end
    room:removeTableMark(player, "@$os__beiding_names", data.card.trueName)
    player:drawCards(1, beiding.name)
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.trueName == data.card.trueName and card:getMark("@@os__beiding_card-inhand") == 1 then
        room:setCardMark(card, "@@os__beiding_card-inhand", 0)
      end
    end
  end,
})

beiding:addEffect(fk.AfterCardsMove, {
  can_refresh = function (self, event, target, player, data)
    return player:getMark("@$os__beiding_names") ~= 0
  end,
  on_refresh = function (self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.to == player and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          local card = Fk:getCardById(info.cardId)
          if table.contains(player:getTableMark("@$os__beiding_names"), card.trueName) and
            table.contains(player:getCardIds("h"), info.cardId) then
            player.room:setCardMark(card, "@@os__beiding_card-inhand", 1)
          end
        end
      end
    end
  end,
})

beiding:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(beiding.name) and
      table.contains(player:getTableMark("@$os__beiding_names"), data.card.trueName)
  end,
  on_refresh = function (self, event, target, player, data)
    data.extraUse = true
  end,
})

beiding:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if table.contains(player:getTableMark("@$os__beiding_names"), card.trueName) then
        player.room:setCardMark(card, "@@os__beiding_card-inhand", 1)
      end
    end
  end
end)

beiding:addLoseEffect(function (self, player, is_death)
  for _, id in ipairs(player:getCardIds("h")) do
    player.room:setCardMark(Fk:getCardById(id), "@@os__beiding_card-inhand", 0)
  end
end)

beiding:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card, to)
    return card and player:hasSkill(beiding.name) and card:getMark("@@os__beiding_card-inhand") == 1
  end,
})

return beiding
