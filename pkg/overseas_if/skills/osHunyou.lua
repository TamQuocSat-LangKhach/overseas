local osHunyou = fk.CreateSkill {
  name = "os__hunyou"
}

Fk:loadTranslationTable{
  ['os__hunyou'] = '魂游',
  ['@@os__hunyou_prevent-turn'] = '魂游',
  ['#os__hunyou_buff'] = '魂游',
  ['os_if__zhugeliang'] = '幻诸葛亮',
  ['os_if_huan__zhugeliang'] = '幻诸葛亮',
  [':os__hunyou'] = '限定技，当你处于濒死状态时，你可以将体力回复至1点，本回合防止你受到的伤害和失去体力。此回合结束时，你<a href=>“入幻”</a>并获得一个额外的回合。',
  ['$os__hunyou1'] = '扶汉兴刘，夙夜沥血，忽入草堂梦中。',
  ['$os__hunyou2'] = '一整河山，以明己志，昔日言犹记否？',
}

osHunyou:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  frequency = Skill.Limited,
  can_trigger = function (skill, event, target, player, data)
    return
      target == player and
      player:hasSkill(skill.name) and
      player.hp < 1 and
      player:usedSkillTimes(osHunyou.name, Player.HistoryGame) == 0
  end,
  on_use = function (skill, event, target, player, data)
    local room = player.room
    if player.hp < 1 then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = osHunyou.name,
      }
    end

    room:setPlayerMark(player, "@@os__hunyou_prevent-turn", 1)
  end
})

osHunyou:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  can_trigger = function (skill, event, target, player, data)
    return player:getMark("@@os__hunyou_prevent-turn") > 0 and (event == fk.AfterTurnEnd or target == player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (skill, event, target, player, data)
    if event == fk.AfterTurnEnd then
      local room = player.room
      room:handleAddLoseSkills(player, "-os__beiding|-os__jielv|-os__hunyou|os_huan__beiding|os_huan__jielv|os__huanji|os__changgui", nil, true, false)
      if player.general == "os_if__zhugeliang" then
        room:setPlayerProperty(player, "general", "os_if_huan__zhugeliang")
      end
      if player.deputyGeneral == "os_if__zhugeliang" then
        room:setPlayerProperty(player, "deputyGeneral", "os_if_huan__zhugeliang")
      end
      player:gainAnExtraTurn(true, osHunyou.name)
    else
      return true
    end
  end
})

osHunyou:addEffect(fk.PreHpLost, {
  anim_type = "defensive",
  can_trigger = function (skill, event, target, player, data)
    return player:getMark("@@os__hunyou_prevent-turn") > 0 and (event == fk.AfterTurnEnd or target == player)
  end,
})

osHunyou:addEffect(fk.AfterTurnEnd, {
  anim_type = "defensive",
  can_trigger = function (skill, event, target, player, data)
    return player:getMark("@@os__hunyou_prevent-turn") > 0 and (event == fk.AfterTurnEnd or target == player)
  end,
  on_cost = Util.TrueFunc,
  on_use = function (skill, event, target, player, data)
    if event == fk.AfterTurnEnd then
      local room = player.room
      room:handleAddLoseSkills(player, "-os__beiding|-os__jielv|-os__hunyou|os_huan__beiding|os_huan__jielv|os__huanji|os__changgui", nil, true, false)
      if player.general == "os_if__zhugeliang" then
        room:setPlayerProperty(player, "general", "os_if_huan__zhugeliang")
      end
      if player.deputyGeneral == "os_if__zhugeliang" then
        room:setPlayerProperty(player, "deputyGeneral", "os_if_huan__zhugeliang")
      end
      player:gainAnExtraTurn(true, osHunyou.name)
    else
      return true
    end
  end
})

return osHunyou
