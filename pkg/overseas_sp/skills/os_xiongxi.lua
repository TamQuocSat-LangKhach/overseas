local osXiongxi = fk.CreateSkill {
  name = "os__xiongxi"
}

Fk:loadTranslationTable{
  ["os__xiongxi"] = "凶袭",
  [":os__xiongxi"] = "出牌阶段限一次，你可弃置X张牌对一名其他角色造成1点伤害。（X=5-<a href='os__baonue_href'>暴虐值</a>，且可为0）",

  ["$os__xiongxi1"] = "凶兵厉袭，片瓦不存！",
  ["$os__xiongxi2"] = "尽起西凉狼兵，袭掠中原之地！",
}

osXiongxi:addEffect("active", {
  anim_type = "offensive",
  can_use = function(self, player)
    return player:usedSkillTimes(osXiongxi.name, Player.HistoryPhase) < 1
  end,
  card_num = function(self, player)
    return 5 - player:getMark("@os__baonue")
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 5 - player:getMark("@os__baonue") and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected_cards == 5 - player:getMark("@os__baonue") and to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    ---@type string
    local skillName = osXiongxi.name
    local player = effect.from
    local target = effect.tos[1]
    room:throwCard(effect.cards, skillName, player, player)
    room:damage{
      from = player,
      to = target,
      damage = 1,
      skillName = skillName,
    }
  end,
})

osXiongxi:addAcquireEffect(function(self, player)
  for _, effect in ipairs(Fk.skills["#os__baonue_mark"]:getSkeleton().effects) do
    player.room.logic:addTriggerSkill(effect)
  end
end)

return osXiongxi
