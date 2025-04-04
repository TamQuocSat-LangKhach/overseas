local os_jichou_give = fk.CreateSkill {
  name = "os__jichou_give&" -- 乐
}

Fk:loadTranslationTable{
  ['os__jichou_give&'] = '<font color=>急筹[给牌]</font>',
  ['@$os__jichou'] = '急筹',
  [':os__jichou_give&'] = '<font color=>出牌阶段限一次，你可将手牌中“急筹”使用过的其牌名的一张牌交给一名角色。</font>',
}

os_jichou_give:addEffect('active', {
  anim_type = "support",
  can_use = function(self, player)
    return player:usedSkillTimes(os_jichou_give.name, Player.HistoryPhase) == 0
  end,
  card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getTableMark("@$os__jichou"), Fk:getCardById(to_select).name) and #selected == 0
  end,
  target_filter = function(self, player, to_select, selected)
    local targetPlayer = room:findPlayerByServerId(to_select)
    return targetPlayer ~= player
  end,
  target_num = 1,
  on_use = function(self, player, room, effect)
    room:moveCardTo(effect.cards[1], Player.Hand, room:getPlayerById(effect.tos[1]), fk.ReasonGive, os_jichou_give.name, nil, false)
  end,
})

return os_jichou_give
