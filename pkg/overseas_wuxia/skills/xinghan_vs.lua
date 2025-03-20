local xinghan = fk.CreateSkill {
  name = "xinghan"
}

Fk:loadTranslationTable{
  ['os__xinghan_viewas'] = '兴汉',
  ['os__chivalry'] = '侠义',
}

xinghan:addEffect('viewas', {
  expand_pile = "os__chivalry",
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 then
      return player:getMark("os__xinghan_card") == to_select
    end
  end,
  view_as = function(self, player, cards)
    if #cards == 1 then
      return Fk:getCardById(cards[1])
    end
  end,
})

return xinghan
  ``` 

