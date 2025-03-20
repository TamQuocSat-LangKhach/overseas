local biyue = fk.CreateSkill {
  name = "os_ex__paoxiao"
}

Fk:loadTranslationTable{
  ['os_ex__paoxiao'] = '咆哮',
  [':os_ex__paoxiao'] = '锁定技，①你使用【杀】无次数限制。②若你于当前阶段使用过【杀】，则你于此阶段使用【杀】无距离限制。',
  ['$os_ex__paoxiao1'] = '喝啊~',
  ['$os_ex__paoxiao2'] = '今，必斩汝马下！',
}

biyue:addEffect('targetmod', {
  bypass_times = function (skill, player, skill_, scope, card, to)
    return player:hasSkill(skill.name) and skill_.trueName == "slash_skill" and scope == Player.HistoryPhase and card
  end,
  bypass_distances = function(self, player, skill_, card)
    return player:hasSkill(skill.name) and skill_.trueName == "slash_skill" and player:usedCardTimes("slash", Player.HistoryPhase) > 0 and card
  end,
})

biyue:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(biyue.name) and
      data.card.trueName == "slash" and
      player:usedCardTimes("slash") > 1
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(biyue.name)
    player.room:doAnimate("InvokeSkill", {
      name = biyue.name,
      player = player.id,
      skill_type = "offensive",
    })
  end,
})

return biyue
