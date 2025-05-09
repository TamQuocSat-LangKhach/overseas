local renxian = fk.CreateSkill {
  name = "os__renxian",
}

Fk:loadTranslationTable{
  ["os__renxian"] = "任贤",
  [":os__renxian"] = "出牌阶段限一次，你可以将除【闪】以外的所有基本牌交给一名其他角色，此回合结束后，其执行一个只有出牌阶段的额外回合，"..
  "该回合内其只能使用或打出你以此法交给其的牌且使用【杀】无次数限制。",

  ["#os__renxian"] = "任贤：将所有非【闪】基本牌交给一名角色，其执行一个只能使用这些牌的额外回合",
  ["@@os__renxian-inhand"] = "任贤",

  ["$os__renxian1"] = "朕虽驽钝，幸有众爱卿襄助！",
  ["$os__renxian2"] = "知人善用，任人唯贤！",
}

renxian:addEffect("active", {
  anim_type = "support",
  prompt = "#os__renxian",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(renxian.name, Player.HistoryPhase) == 0 and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).type == Card.TypeBasic and Fk:getCardById(id).trueName ~= "jink"
      end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local cards = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id).type == Card.TypeBasic and Fk:getCardById(id).trueName ~= "jink"
    end)
    room:moveCardTo(cards, Card.PlayerHand, target, fk.ReasonGive, renxian.name, nil, false, player, "@@os__renxian-inhand")
    if not target.dead then
      target:gainAnExtraTurn(true, renxian.name, {phase_table = {Player.Play}})
    end
  end,
})

renxian:addEffect(fk.TurnStart, {
  can_refresh = Util.TrueFunc,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if target ~= player or data.reason ~= renxian.name then
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@os__renxian-inhand", 0)
      end
    else
      room:setPlayerMark(player, "os__renxian-turn", 1)
    end
  end,
})

renxian:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope)
    return skill.trueName == "slash_skill" and player:getMark("os__renxian-turn") > 0
  end,
})

renxian:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card and player:getMark("os__renxian-turn") > 0 and card:getMark("@@os__renxian-inhand") == 0
  end,
  prohibit_response = function(self, player, card)
    return card and player:getMark("os__renxian-turn") > 0 and card:getMark("@@os__renxian-inhand") == 0
  end,
})

return renxian
