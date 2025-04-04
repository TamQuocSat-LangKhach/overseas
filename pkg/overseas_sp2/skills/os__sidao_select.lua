local os__sidao_select = fk.CreateSkill {
  name = "os__sidao_select"
}

Fk:loadTranslationTable{
  ['os__sidao_select'] = '司道',
}

os__sidao_select:addEffect('active', {
  card_num = 1,
  target_num = 0,
  expand_pile = function (self, player)
    return player:getTableMark("os__sidao_cards")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getTableMark("os__sidao_cards"), to_select)
      and player:canUseTo(Fk:getCardById(to_select), player)
  end,
})

return os__sidao_select
