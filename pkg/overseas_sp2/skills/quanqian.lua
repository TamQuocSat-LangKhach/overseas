local quanqian = fk.CreateSkill {
  name = "os__quanqian"
}

Fk:loadTranslationTable{
  ['os__quanqian'] = '劝迁',
  ['@os__quanqian'] = '劝迁',
  ['os__quanqian_draw'] = '手牌摸至%arg张',
  ['os__quanqian_get'] = '观看%dest手牌并选择一种花色，获得其中所有此花色的牌',
  ['#os__quanqian-choose'] = '劝迁：选择一种花色，获得%dest手牌中所有此花色的牌',
  [':os__quanqian'] = '<a href=>昂扬技</a>，出牌阶段限一次，你可以将至多四张花色不同的手牌交给一名其他角色，若你以此法给出了不少于两张牌，你从牌堆中获得一张装备牌。然后你选择一项：1.将手牌摸至与其手牌数相同；2.观看其手牌并选择一种花色，然后获得其手牌中所有此花色的牌。<a href=>激昂</a>：你弃置六张手牌。',
  ['$os__quanqian1'] = '欲承奕世之基，当迁龙兴之地。',
  ['$os__quanqian2'] = '吴郡僻远，宜迁都秣陵，以承王业。',
}

quanqian:addEffect('active', {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(quanqian.name, Player.HistoryPhase) == 0 and player:getMark("@os__quanqian") == 0
  end,
  target_num = 1,
  min_card_num = 1,
  max_card_num = 4,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return table.every(selected, function (id) return card:compareSuitWith(Fk:getCardById(id), true) end)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@os__quanqian", 6)
    local cards = effect.cards
    room:moveCardTo(cards, Player.Hand, target, fk.ReasonGive, quanqian.name, nil, false, player.id)
    if player.dead then return false end
    if #cards > 1 then
      local cids = room:getCardsFromPileByRule(".|.|.|.|.|equip")
      if #cids > 0 then
        room:obtainCard(player, cids[1], false, fk.ReasonPrey, player.id, quanqian.name)
        if player.dead then return false end
      end
    end
    local choices = {"os__quanqian_draw:::" .. target:getHandcardNum(), "os__quanqian_get::" .. target.id}
    if target:isKongcheng() then table.remove(choices) end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = quanqian.name
    })
    if choice:startsWith("os__quanqian_draw") then
      local num = target:getHandcardNum() - player:getHandcardNum()
      if num > 0 then player:drawCards(num, quanqian.name) end
    else
      cards = target:getCardIds(Player.Hand)
      local listNames = {"log_spade", "log_club", "log_heart", "log_diamond"}
      local listCards = { {}, {}, {}, {} }
      local can_get = false
      for _, id in ipairs(cards) do
        local suit = Fk:getCardById(id).suit
        if suit ~= Card.NoSuit then
          table.insertIfNeed(listCards[suit], id)
          can_get = true
        end
      end
      if can_get then
        local choice = U.askForChooseCardList(room, player, listNames, listCards, 1, 1, quanqian.name,
          "#os__quanqian-choose::" .. target.id, false, false)
        room:obtainCard(player, table.filter(cards, function(cid)
          return Fk:getCardById(cid):getSuitString(true) == choice[1]
        end), false, fk.ReasonPrey, player.id, quanqian.name)
      end
    end
  end,
})

quanqian:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark("@os__quanqian") > 0 and table.find(data, function(move) return move.from == player.id and move.toArea == Card.DiscardPile end)
  end,
  on_refresh = function(self, event, target, player, data)
    local num = player:getMark("@os__quanqian")
    for _, move in ipairs(data) do
      if move.toArea == Card.DiscardPile and move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            num = num - 1
          end
        end
      end
      if num <= 0 then
        player.room:setPlayerMark(player, "@os__quanqian", 0)
        return false
      end
    end
    player.room:setPlayerMark(player, "@os__quanqian", num)
  end,
})

return quanqian
