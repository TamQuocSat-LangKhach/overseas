local gundam__gongxin = fk.CreateSkill {
  name = "gundam__gongxin"
}

Fk:loadTranslationTable{
  ['gundam__gongxin'] = '攻心',
  ['gundam__gongxin_discard'] = '弃置所选牌',
  ['gundam__gongxin_put'] = '将所选牌置于牌堆顶',
  ['#gundam__gongxin-ask'] = '攻心：观看%dest的手牌，可展示其中一张牌并选择一项',
  ['#gundam__gongxin-dis'] = '攻心：你可令 %dest 本回合无法使用或打出一种颜色的牌',
  ['@gundam__gongxin-turn'] = '攻心',
  [':gundam__gongxin'] = '出牌阶段限一次，你可观看一名其他角色的手牌，然后你可展示其中一张牌并选择一项：1. 你弃置其此牌；2. 将此牌置于牌堆顶。然后若其手牌中花色数因此减少，你可令其本回合无法使用或打出一种颜色的牌。',
  ['$gundam__gongxin1'] = '敌将虽有破军之勇，然未必有弑神之心。',
  ['$gundam__gongxin2'] = '知敌所欲为，则此战已尽在掌握。',
}

gundam__gongxin:addEffect('active', {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(gundam__gongxin.name, Player.HistoryPhase) < 1
  end,
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cids = target:getCardIds(Player.Hand)
    local card_suits = {}
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num = #card_suits
    local cards, choice = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = { target },
      pattern = "",
      prompt = "#gundam__gongxin-ask::" .. target.id,
      choices = {"gundam__gongxin_discard", "gundam__gongxin_put"},
    })
    if #cards == 0 then return end
    target:showCards(cards)
    if choice == "gundam__gongxin_discard" then
      room:throwCard(cards, gundam__gongxin.name, target, player)
    else
      room:moveCardTo(cards, Card.DrawPile, nil, fk.ReasonPut, gundam__gongxin.name, nil, false)
    end
    card_suits = {}
    cids = target:getCardIds(Player.Hand)
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num2 = #card_suits
    if num > num2 and not player.dead and not target.dead then
      choice = room:askToChoice(player, {
        choices = {"red", "black"},
        skill_name = gundam__gongxin.name,
        prompt = "#gundam__gongxin-dis::" .. target.id,
      })
      if choice ~= "Cancel" then
        room:addTableMarkIfNeed(target, "@gundam__gongxin-turn", choice)
      end
    end
  end,
})

gundam__gongxin:addEffect('prohibit', {
  name = "#gundam__gongxin_prohibit",
  prohibit_use = function(self, player, card)
    if player:getMark("@gundam__gongxin-turn") ~= 0 then
      return table.contains(player:getMark("@gundam__gongxin-turn"), card:getColorString())
    end
  end,
  prohibit_response = function(self, player, card)
    if player:getMark("@gundam__gongxin-turn") ~= 0 then
      return table.contains(player:getMark("@gundam__gongxin-turn"), card:getColorString())
    end
  end,
})

return gundam__gongxin
