local osHuanBeiding = fk.CreateSkill {
  name = "os_huan__beiding"
}

Fk:loadTranslationTable{
  ['os_huan__beiding'] = '北定',
  ['@$os__beiding_names'] = '北定',
  ['@@os__beiding_card-inhand'] = '北定',
  [':os_huan__beiding'] = '你使用〖北定〗记录的牌无距离限制且不计入次数；当你使用〖北定〗记录牌名的牌结算结束后，你摸一张牌，然后移除〖北定〗记录中的此牌名。',
  ['$os_huan__beiding1'] = '内外不懈如斯，长安不日可下！',
  ['$os_huan__beiding2'] = '先帝英灵冥鉴，此番定成夙愿！',
}

osHuanBeiding:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  mute = true,
  can_trigger = function (self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osHuanBeiding) and
      table.contains(player:getTableMark("@$os__beiding_names"), data.card.trueName)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, osHuanBeiding.name)
    -- 牌名彩蛋
    local names = {"fire_attack", "fire__slash", "nullification"}
    if table.contains(names, data.card.name) then
      player:broadcastSkillInvoke("os_huan__beiding_names", table.indexOf(names, data.card.name))
    else
      player:broadcastSkillInvoke(osHuanBeiding.name)
    end
    player:drawCards(1, osHuanBeiding.name)
    room:removeTableMark(player, "@$os__beiding_names", data.card.trueName)
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card.trueName == data.card.trueName and card:getMark("@@os__beiding_card-inhand") == 1 then
        room:setCardMark(card, "@@os__beiding_card-inhand", 0)
      end
    end
  end,
})

osHuanBeiding:addEffect({fk.PreCardUse, fk.AfterCardsMove}, {
  can_refresh = function (self, event, target, player, data)
    if event == fk.PreCardUse then
      return
        target == player and
        player:hasSkill(osHuanBeiding) and
        table.contains(player:getTableMark("@$os__beiding_names"), data.card.trueName)
    elseif event == fk.AfterCardsMove then
      return table.find(data, function(move)
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return
          table.find(
            move.moveInfo,
            function(moveInfo)
              return table.contains(player:getTableMark("@$os__beiding_names"), Fk:getCardById(moveInfo.cardId).trueName)
            end
          )
        end
      end)
    end
  end,
  on_refresh = function (self, event, target, player, data)
    if event == fk.PreCardUse then
      data.extraUse = true
    elseif event == fk.AfterCardsMove then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          for _, moveInfo in ipairs(move.moveInfo) do
            local card = Fk:getCardById(moveInfo.cardId)
            if table.contains(player:getTableMark("@$os__beiding_names"), card.trueName) then
              player.room:setCardMark(card, "@@os__beiding_card-inhand", 1)
            end
          end
        end
      end
    end
  end,
})

osHuanBeiding:addEffect('on_acquire', {
  on_acquire = function (self, player)
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if table.contains(player:getTableMark("@$os__beiding_names"), card.trueName) then
        player.room:setCardMark(card, "@@os__beiding_card-inhand", 1)
      end
    end
  end,
})

osHuanBeiding:addEffect('on_lose', {
  on_lose = function (self, player)
    for _, id in ipairs(player:getCardIds("h")) do
      local card = Fk:getCardById(id)
      if card:getMark("@@os__beiding_card-inhand") ~= 0 then
        player.room:setCardMark(card, "@@os__beiding_card-inhand", 0)
      end
    end
  end,
})

local osHuanBeidingBuff = fk.CreateSkill {
  name = "#os_huan__beiding_buff"
}

osHuanBeidingBuff:addEffect('targetmod', {
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(osHuanBeiding) and card:getMark("@@os__beiding_card-inhand") == 1
  end,
})

return osHuanBeiding, osHuanBeidingBuff
