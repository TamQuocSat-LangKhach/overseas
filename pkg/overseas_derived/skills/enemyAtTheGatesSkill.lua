local enemyAtTheGatesSkill = fk.CreateSkill {
  name = "enemy_at_the_gates_skill"
}

Fk:loadTranslationTable{
  ['enemy_at_the_gates_skill'] = '兵临城下',
  [':enemy_at_the_gates_skill'] = '选择一名其他角色，你依次亮出牌堆顶四张牌，若为【杀】，你对其使用之；若不为【杀】，将此牌置入弃牌堆',
}

enemyAtTheGatesSkill:addEffect('cardskill', {
  target_num = 1,
  mod_target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_filter = Util.CardTargetFilter,
  on_effect = function(self, room, cardEffectEvent)
    local player = cardEffectEvent.from
    local to = cardEffectEvent.tos[1]
    local cards = {}
    for _ = 1, 4 do
      local id = room:getNCards(1)[1]
      table.insert(cards, id)
      room:moveCardTo(id, Card.Processing, nil, fk.ReasonJustMove, enemyAtTheGatesSkill.name, nil, true, player)
      local card = Fk:getCardById(id)
      if card.trueName == "slash" and player:canUseTo(card, to) then
        room:useCard({
          card = card,
          from = player.id,
          tos = {to.id},
          extra_use = true,
        })
      end
    end
    room:cleanProcessingArea(cards, enemyAtTheGatesSkill.name)
  end,
})

return enemyAtTheGatesSkill
