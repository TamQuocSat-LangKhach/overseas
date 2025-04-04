local lingyin = fk.CreateSkill {
  name = "os__lingyin"
}

Fk:loadTranslationTable{
  ['os__lingyin'] = '灵隐',
  [':os__lingyin'] = '当你成为普通锦囊牌的目标后，你可以亮出牌堆顶的一张牌，若此牌与此普通锦囊牌颜色相同，你获得亮出的牌，若花色也相同，此普通锦囊牌对此目标无效。',
  ['$os__lingyin1'] = '我自逍遥天地，何拘凡尘俗法？',
  ['$os__lingyin2'] = '朝沐露霞寤，夜枕溪潺眠。',
}

lingyin:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(lingyin.name) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = room:getNCards(1)
    local card = Fk:getCardById(cards[1])
    room:moveCardTo(card, Card.Processing, nil, fk.ReasonJustMove, lingyin.name, nil, true, player.id)
    --理论上牌堆里的牌不会没有花色、颜色的，故不做无色判定
    if data.card.color == card.color then
      room:setCardEmotion(card.id, "judgegood")
      room:delay(1000)
      room:obtainCard(player, card, true, fk.ReasonJustMove, player.id, lingyin.name)
      if data.card.suit == card.suit then
        table.insertIfNeed(data.nullifiedTargets, player.id)
      end
    else
      room:setCardEmotion(card.id, "judgebad")
      room:cleanProcessingArea(cards, lingyin.name)
    end
  end,
})

return lingyin
