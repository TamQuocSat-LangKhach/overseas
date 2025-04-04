local os__fenxian_vs = fk.CreateSkill {
  name = "os__fenxian_vs"
}

Fk:loadTranslationTable{
  ['os__fenxian_vs'] = '焚险',
}

os__fenxian_vs:addEffect('active', {
  mute = true,
  card_num = 1,
  target_num = 1,
  expand_pile = function (self)
    return self.cards
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and (table.contains(self.cards, to_select) or table.contains(player:getCardIds("e"), to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected_cards == 0 or #selected > 0 then return false end
    local card = Fk:cloneCard("duel")
    card.skillName = skill.name
    card:addSubcard(selected_cards[1])
    local target = Fk:currentRoom():getPlayerById(to_select)
    return not player:isProhibited(target, card) and card.skill:modTargetFilter(player, to_select, {}, card, false) and to_select ~= self.from
  end,
})

return os__fenxian_vs
