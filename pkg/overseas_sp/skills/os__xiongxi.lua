local os__xiongxi = fk.CreateSkill {
  name = "os__xiongxi"
}

Fk:loadTranslationTable{
  ['os__xiongxi'] = '凶袭',
  ['@os__baonue'] = '暴虐值',
  [':os__xiongxi'] = '出牌阶段限一次，你可弃置X张牌对一名其他角色造成1点伤害。（X=5-<a href=>暴虐值</a>，且可为0）',
  ['$os__xiongxi1'] = '凶兵厉袭，片瓦不存！',
  ['$os__xiongxi2'] = '尽起西凉狼兵，袭掠中原之地！',
}

os__xiongxi:addEffect('active', {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(os__xiongxi.name, Player.HistoryPhase) < 1
  end,
  card_num = function(player) 
    return 5 - player:getMark("@os__baonue") 
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 5 - player:getMark("@os__baonue") and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards == 5 - player:getMark("@os__baonue") and to_select ~= player.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:throwCard(effect.cards, os__xiongxi.name, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = os__xiongxi.name,
    }
  end,
})

os__xiongxi:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__xiongxi) and canBaonue(player, data, event)
  end,
  on_refresh = function(self, event, target, player, data)
    addBaonue(player.room, player, data, event)
  end,
})

os__xiongxi:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__xiongxi) and canBaonue(player, data, event)
  end,
  on_refresh = function(self, event, target, player, data)
    addBaonue(player.room, player, data, event)
  end,
})

return os__xiongxi
