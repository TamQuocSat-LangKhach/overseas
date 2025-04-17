local osExPaoxiao = fk.CreateSkill {
  name = "os_ex__paoxiao",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["os_ex__paoxiao"] = "咆哮",
  [":os_ex__paoxiao"] = "锁定技，①你使用【杀】无次数限制。②若你于当前阶段使用过【杀】，则你于此阶段使用【杀】无距离限制。",

  ["$os_ex__paoxiao1"] = "喝啊~",
  ["$os_ex__paoxiao2"] = "今，必斩汝马下！",
}

osExPaoxiao:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return
      player:hasSkill(osExPaoxiao.name) and
      card and
      skill.trueName == "slash_skill" and
      scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill, card)
    return
      player:hasSkill(osExPaoxiao.name) and
      card and
      skill.trueName == "slash_skill" and
      player:getMark("os_ex__paoxiao_slash-phase") > 0
  end,
})

osExPaoxiao:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osExPaoxiao.name, true) and
      data.card.trueName == "slash" and
      player:getMark("os_ex__paoxiao_slash-phase") == 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "os_ex__paoxiao_slash-phase", 1)
  end,
})

osExPaoxiao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osExPaoxiao.name) and
      data.card.trueName == "slash" and
      player:usedCardTimes("slash") > 1
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke(osExPaoxiao.name)
    player.room:doAnimate("InvokeSkill", {
      name = osExPaoxiao.name,
      player = player.id,
      skill_type = "offensive",
    })
  end,
})

return osExPaoxiao
