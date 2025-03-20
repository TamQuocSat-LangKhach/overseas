local os__shangyi = fk.CreateSkill {
  name = "os__shangyi"
}

Fk:loadTranslationTable{
  ['os__shangyi'] = '尚义',
  ['#os__shangyi-active'] = '发动 尚义，弃置一张牌，与一名有手牌的其他角色互相观看手牌',
  ['#os__shangyi_view'] = '尚义：观看 %src 的手牌',
  ['os__shangyi_discard'] = '弃置此牌',
  ['os__shangyi_exchange'] = '与其交换此牌',
  ['#os__shangyi-ask'] = '尚义：观看 %dest 的手牌，选择一张牌并选择一项',
  ['#os__shangyi-exchange'] = '尚义：选择一张手牌，与 %src 交换其%arg',
  [':os__shangyi'] = '出牌阶段限一次，你可弃置一张牌并令一名有手牌的其他角色观看你的手牌，然后你观看其手牌并选择一项：1. 弃置其中一张牌；2. 与其交换一张手牌。若弃置的为黑色牌或交换的两张均为红色牌，则你摸一张牌。',
  ['$os__shangyi1'] = '国士，当以义为先！',
  ['$os__shangyi2'] = '豪侠尚义，何拘俗礼！',
}

os__shangyi:addEffect('active', {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(os__shangyi.name, Player.HistoryPhase) < 1
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player.id and #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, os__shangyi.name, player, player)
    if not player:isKongcheng() then
      U.viewCards(target, player:getCardIds(Player.Hand), os__shangyi.name, "#os__shangyi_view:" .. player.id)
    end
    local choiceList = {"os__shangyi_discard"}
    if not player:isKongcheng() then table.insert(choiceList, "os__shangyi_exchange") end

    local cards, choice = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = {target},
      min_target_num = 0,
      max_target_num = 0,
      pattern = ".",
      prompt = "#os__shangyi-ask::" .. target.id,
      cancelable = false
    })

    local card = Fk:getCardById(cards[1])
    if choice == "os__shangyi_discard" then
      room:throwCard(cards, os__shangyi.name, target, player)
      if card.color == Card.Black and not player.dead then player:drawCards(1, os__shangyi.name) end
    else
      local cids = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        pattern = ".",
        prompt = "#os__shangyi-exchange:" .. target.id .. "::" .. card:toLogString(),
        cancelable = false
      })
      U.swapCards(room, player, player, target, cids, {card.id}, os__shangyi.name)
      if card.color == Card.Red and Fk:getCardById(cids[1]).color == Card.Red and not player.dead then player:drawCards(1, os__shangyi.name) end
    end
  end,
})

return os__shangyi
