local os__queshi = fk.CreateSkill{
  name = "os__queshi"
}

Fk:loadTranslationTable{
  ['os__queshi'] = '鹊拾',
  [':os__queshi'] = '游戏开始时，你将【银月枪】置入你的装备区。当你发动“扶汉”后，你从游戏外、场上、牌堆或弃牌堆中获得【银月枪】。',
}

os__queshi:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__queshi.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cardId = U.prepareDeriveCards(room, {{"moon_spear", Card.Diamond, 12}}, "os__queshi_spear")[1]
    if U.canMoveCardIntoEquip(player, cardId, true) then
      room:moveCardIntoEquip(player, cardId, os__queshi.name, true, player)
    end
  end,
})

os__queshi:addEffect(fk.BeforeCardsMove, {
  can_trigger = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local hold_areas = {Card.PlayerEquip, Card.Processing, Card.Void, Card.PlayerHand}
    local mirror_moves = {}
    local ids = {}
    for _, move in ipairs(data) do
      if not table.contains(hold_areas, move.toArea) then
        local move_info = {}
        local mirror_info = {}
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if Fk:getCardById(id).name == "moon_spear" then
            table.insert(mirror_info, info)
            table.insert(ids, id)
          else
            table.insert(move_info, info)
          end
        end
        if #mirror_info > 0 then
          move.moveInfo = move_info
          local mirror_move = table.clone(move)
          mirror_move.to = nil
          mirror_move.toArea = Card.Void
          mirror_move.moveInfo = mirror_info
          table.insert(mirror_moves, mirror_move)
        end
      end
    end
    if #ids > 0 then
      player.room:sendLog{
        type = "#destructDerivedCards",
        card = ids,
      }
    end
    table.insertTable(data, mirror_moves)
  end,
})

return os__queshi
