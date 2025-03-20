local os_ex__bingyi = fk.CreateSkill {
  name = "os_ex__bingyi"
}

Fk:loadTranslationTable{
  ['os_ex__bingyi'] = '秉壹',
  ['@os_ex__shenxing'] = '慎行',
  [':os_ex__bingyi'] = '结束阶段开始时，你可展示所有手牌，若颜色均相同或类型均相同，你令至多X名角色各摸一张牌（X为你的手牌数）。若你展示的牌数大于1且这些牌颜色和类型均相同，则〖慎行〗的X修改为0。',
  ['$os_ex__bingyi1'] = '秉持吾志，一心为公。',
  ['$os_ex__bingyi2'] = '志爱公利，道德纯备。',
}

os_ex__bingyi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os_ex__bingyi.name) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = player.player_cards[Player.Hand]
    player:showCards(cards)
    local invoke = false
    if #cards > 1 then invoke = true end
    local card = Fk:getCardById(cards[1])
    local color, cardType = true, true
    for _, id in ipairs(cards) do
      local c = Fk:getCardById(id)
      if not c:compareColorWith(card, true) then
        color = false
        break
      end
    end
    for _, id in ipairs(cards) do
      local c = Fk:getCardById(id)
      if c.type ~= card.type then
        cardType = false
        break
      end
    end
    if not color and not cardType then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = #cards,
      skill_name = os_ex__bingyi.name,
      prompt = "#bingyi-choose:::"..#cards
    })
    room:sortPlayersByAction(tos)
    for _, pid in ipairs(tos) do
      local p = room:getPlayerById(pid)
      if p:isAlive() then p:drawCards(1, os_ex__bingyi.name) end
    end
    if invoke and color and cardType then
      room:setPlayerMark(player, "@os_ex__shenxing", 0)
    end
  end,
})

return os_ex__bingyi
