local lingyin = fk.CreateSkill {
  name = "os__lingyin",
}

Fk:loadTranslationTable{
  ["os__lingyin"] = "灵隐",
  [":os__lingyin"] = "当你成为普通锦囊牌的目标后，你可以亮出牌堆顶的一张牌，若此牌与此普通锦囊牌颜色相同，你获得亮出的牌，若花色也相同，"..
  "此牌对你无效。",

  ["$os__lingyin1"] = "我自逍遥天地，何拘凡尘俗法？",
  ["$os__lingyin2"] = "朝沐露霞寤，夜枕溪潺眠。",
}

lingyin:addEffect(fk.TargetConfirmed, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lingyin.name) and data.card:isCommonTrick()
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(1)
    local card = Fk:getCardById(cards[1])
    room:turnOverCardsFromDrawPile(player, cards, lingyin.name, true)
    if data.card:compareColorWith(card) then
      room:setCardEmotion(cards[1], "judgegood")
      room:delay(1000)
      room:obtainCard(player, card, true, fk.ReasonJustMove, player, lingyin.name)
      if data.card:compareSuitWith(card) then
        data.use.nullifiedTargets = data.use.nullifiedTargets or {}
        table.insertIfNeed(data.use.nullifiedTargets, player)
      end
    else
      room:setCardEmotion(card.id, "judgebad")
    end
      room:cleanProcessingArea(cards)
  end,
})

return lingyin
