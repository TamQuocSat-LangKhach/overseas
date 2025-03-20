local os__xingwu_damage = fk.CreateSkill {
  name = "#os__xingwu_damage",
}

Fk:loadTranslationTable{
  ['#os__xingwu_damage'] = '星舞',
  ['os__dance'] = '星舞',
}

os__xingwu_damage:addEffect('active', {
  anim_type = "offensive",
  can_use = Util.FalseFunc,
  target_num = 1,
  card_num = 3,
  expand_pile = "os__dance",
  target_filter = function(self, player, to_select, selected, cards)
    return to_select ~= player.id and #cards == 3
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 3 and player:getPileNameOfId(to_select) == "os__dance"
  end,
})

return os__xingwu_damage
