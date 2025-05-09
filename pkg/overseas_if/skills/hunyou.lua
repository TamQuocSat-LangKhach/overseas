local hunyou = fk.CreateSkill {
  name = "os__hunyou",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["os__hunyou"] = "魂游",
  [":os__hunyou"] = "限定技，当你处于濒死状态时，你可以将体力回复至1点，本回合防止你受到的伤害和失去体力。" ..
  "此回合结束时，你<a href='os_ruhuan_zhugeliang'>“入幻”</a>并获得一个额外的回合。",

  ["os_ruhuan_zhugeliang"] = "变身为幻形态：<br>" ..
  "<b>北定</b>：你使用〖北定〗记录的牌无距离限制且不计入次数；当你使用〖北定〗记录牌名的牌结算结束后，" ..
  "你摸一张牌，然后移除〖北定〗记录中的此牌名。<br>" ..
  "<b>竭虑</b>：锁定技，当你减1点体力上限后，你回复1点体力。<br>" ..
  "<b>幻计</b>：出牌阶段限一次，你可以减1点体力上限，在〖北定〗记录中增加X种牌名（X为你的体力值）。<br>" ..
  "<b>怅归</b>：锁定技，结束阶段，若你的体力值为全场最低，则你<a href='os_tuihuan_zhugeliang'>“退幻”</a>并将体力上限调整至体力值。",
  ["@@os__hunyou_prevent-turn"] = "魂游",

  ["$os__hunyou1"] = "扶汉兴刘，夙夜沥血，忽入草堂梦中。",
  ["$os__hunyou2"] = "一整河山，以明己志，昔日言犹记否？",
}

hunyou:addEffect(fk.AskForPeaches, {
  anim_type = "defensive",
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(hunyou.name) and
      player.dying and player:usedSkillTimes(hunyou.name, Player.HistoryGame) == 0
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    if player.hp < 1 then
      room:recover{
        who = player,
        num = 1 - player.hp,
        recoverBy = player,
        skillName = hunyou.name,
      }
      if player.dead then return end
    end
    player:gainAnExtraTurn(true, hunyou.name)
    room.logic:getCurrentEvent():findParent(GameEvent.Turn):addCleaner(function()
      room:handleAddLoseSkills(player, "-os__beiding|-os__jielv|-os__hunyou|os_huan__beiding|os_huan__jielv|os__huanji|os__changgui",
        nil, true, false)
      if player.general == "os_if__zhugeliang" then
        room:setPlayerProperty(player, "general", "os_if_huan__zhugeliang")
      end
      if player.deputyGeneral == "os_if__zhugeliang" then
        room:setPlayerProperty(player, "deputyGeneral", "os_if_huan__zhugeliang")
      end
    end)
  end
})

hunyou:addEffect(fk.DamageInflicted, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:usedSkillTimes(hunyou.name, Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    data:preventDamage()
  end,
})

hunyou:addEffect(fk.PreHpLost, {
  anim_type = "defensive",
  is_delay_effect = true,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:usedSkillTimes(hunyou.name, Player.HistoryTurn) > 0
  end,
  on_use = function (self, event, target, player, data)
    data:preventHpLost()
  end,
})

return hunyou
