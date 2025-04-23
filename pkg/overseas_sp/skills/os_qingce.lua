local osQingce = fk.CreateSkill {
  name = "os__qingce"
}

Fk:loadTranslationTable{
  ["os__qingce"] = "清侧",
  [":os__qingce"] = "出牌阶段，你可将一张“荣”置入弃牌堆，然后弃置其他角色区域内的一张牌。",

  ["$os__glory"] = "荣",
  ["#os__qingce"] = "可将一张“荣”置入弃牌堆，弃置其他角色区域内的一张牌",

  ["$os__qingce1"] = "陛下身陷囹圄，臣唯勤王救之！",
  ["$os__qingce2"] = "今，天不得时，地不得利，需谨慎用兵。",
}

osQingce:addEffect("active", {
  anim_type = "control",
  target_num = 1,
  card_num = 1,
  expand_pile = "$os__glory",
  prompt = "#os__qingce",
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player and not to_select:isAllNude()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and player:getPileNameOfId(to_select) == "$os__glory"
  end,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osQingce.name
    local player = effect.from
    local target = effect.tos[1]

    room:moveCardTo(effect.cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, "$os__glory", true, player)
    local card = room:askToChooseCard(
      player,
      {
        target = target,
        flag = "hej",
        skill_name = skillName,
      }
    )
    room:throwCard(card, skillName, target, player)
  end,
})

return osQingce
