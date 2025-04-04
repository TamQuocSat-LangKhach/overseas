local os__gongxin = fk.CreateSkill {
  name = "os__gongxin"
}

Fk:loadTranslationTable{
  ['os__gongxin'] = '攻心',
  ['os__gongxin_discard'] = '弃置所选牌',
  ['os__gongxin_put'] = '将所选牌置于牌堆顶',
  ['#os__gongxin-ask'] = '攻心：观看%dest的手牌，可展示其中一张牌并选择一项',
  ['@@os__gongxin_dr-turn'] = '攻心',
  ['#os__gongxin_dr'] = '攻心',
  [':os__gongxin'] = '出牌阶段限一次，你可观看一名其他角色的手牌，然后你可展示其中一张牌并选择一项：1. 你弃置其此牌；2. 将此牌置于牌堆顶，然后若其手牌中花色数因此减少，其不能响应你本回合使用的下一张牌。',
  ['$os__gongxin1'] = '敌将虽有破军之勇，然未必有弑神之心。',
  ['$os__gongxin2'] = '知敌所欲为，则此战已尽在掌握。',
}

os__gongxin:addEffect('active', {
  anim_type = "control",
  can_use = function(self, player)
    return player:usedSkillTimes(os__gongxin.name, Player.HistoryPhase) < 1
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
      targets = {},
      min_target_num = 0,
      max_target_num = 0,
      pattern = "",
      prompt = "#os__gongxin-ask::" .. target.id,
      choices = {"os__gongxin_discard", "os__gongxin_put"},
      skill_name = os__gongxin.name
    })
    if #cards == 0 then return end
    target:showCards(cards)
    if choice == "os__gongxin_discard" then
      room:throwCard(cards, os__gongxin.name, target, player)
    else
      room:moveCardTo(cards, Card.DrawPile, nil, fk.ReasonPut, os__gongxin.name, nil, false)
    end
    card_suits = {}
    cids = target:getCardIds(Player.Hand)
    table.forEach(cids, function(id)
      table.insertIfNeed(card_suits, Fk:getCardById(id).suit)
    end)
    local num2 = #card_suits
    if num > num2 and not player.dead and not target.dead then
      room:setPlayerMark(target, "@@os__gongxin_dr-turn", 1)
      room:setPlayerMark(player, "_os__gongxin-turn", 1)
    end
  end,
})

os__gongxin:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("_os__gongxin-turn") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    local room = player.room
    for _, target in ipairs(room.alive_players) do
      if target:getMark("@@os__gongxin_dr-turn") > 0 then
        table.insertIfNeed(data.disresponsiveList, target.id)
        room:setPlayerMark(target, "@@os__gongxin_dr-turn", 0)
      end
    end
    room:setPlayerMark(player, "_os__gongxin-turn", 0)
  end,
})

return os__gongxin
