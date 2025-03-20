local os__congji = fk.CreateSkill {
  name = "os__congji"
}

Fk:loadTranslationTable{
  ['os__congji'] = '从击',
  ['#os__congji-ask'] = '从击：你可将弃置的牌中所有的红色牌交给一名其他角色',
  [':os__congji'] = '当你于回合外弃置牌后，你可将其中的所有红色牌交给一名其他角色。',
}

os__congji:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player.phase == Player.NotActive and player:hasSkill(os__congji.name) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.moveReason == fk.ReasonDiscard then
          for _, info in ipairs(move.moveInfo) do
            if Fk:getCardById(info.cardId).color == Card.Red then
              return true
            end
          end
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    target = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__congji-ask",
      skill_name = os__congji.name,
      cancelable = true
    })

    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cids = {}
    for _, move in ipairs(data) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId).color == Card.Red then
            table.insert(cids, info.cardId)
          end
        end
      end
    end
    room:moveCardTo(cids, Player.Hand, room:getPlayerById(event:getCostData(skill)), fk.ReasonGive, os__congji.name, nil, false)
  end,
})

return os__congji
