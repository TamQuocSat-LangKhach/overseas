local os__boming = fk.CreateSkill {
  name = "os__boming"
}

Fk:loadTranslationTable{
  ['os__boming'] = '博名',
  ['#os__boming_draw'] = '博名',
  [':os__boming'] = '出牌阶段限两次，你可以将一张牌交给一名其他角色。结束阶段开始时，若其他角色于此回合内获得的牌数大于1，你摸两张牌。',
  ['$os__boming1'] = '先载附从，吾后行即可。',
  ['$os__boming2'] = '诸位速速上船，靖随后便至。',
}

os__boming:addEffect('active', {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(os__boming.name, Player.HistoryPhase) < 2
  end,
  card_filter = Util.TrueFunc,
  card_num = 1,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    room:moveCardTo(effect.cards, Player.Hand, room:getPlayerById(effect.tos[1]), fk.ReasonGive, os__boming.name, nil, false)
  end,
})

os__boming:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__boming) and player.phase == Player.Finish and player:getMark("_os__boming_card-turn") > 1
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, os__boming.name)
  end,

  can_refresh = function(self, event, target, player, data)
    if player.phase == Player.NotActive then return false end
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      if target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        return true
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local num = 0
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil
      if target and move.to ~= player.id and move.toArea == Card.PlayerHand then
        num = num + #move.moveInfo
      end
    end
    player.room:addPlayerMark(player, "_os__boming_card-turn", num)
  end,
})

return os__boming
