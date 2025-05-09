local longjin = fk.CreateSkill {
  name = "os__longjin",
  tags = { Skill.Wake },
}

Fk:loadTranslationTable{
  ["os__longjin"] = "龙烬",
  [":os__longjin"] = "觉醒技，当你进入濒死状态时，你将体力回复至2点，然后于此回合与之后的五个回合内，你视为拥有〖龙胆〗和〖冲阵〗，"..
  "且你至其他角色的距离视为1。",

  ["$os__longjin1"] = "龙烬沙场，以全大汉荣光！",
  ["$os__longjin2"] = "长坂龙魂犹在，咆哮万里长安！",
}

longjin:addEffect(fk.EnterDying, {
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(longjin.name) and
      player:usedSkillTimes(longjin.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player.hp < 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{
      num = 2 - player.hp,
      who = player,
      recoverBy = player,
      skillName = longjin.name,
    }
    if not player.dead then
      room:setPlayerMark(player, longjin.name, 6)
      local skills = table.filter({"longdan", "chongzhen"}, function (s)
        return not player:hasSkill(s, true)
      end)
      if #skills > 0 then
        room:setPlayerMark(player, "os__longjin_skills", skills)
        room:handleAddLoseSkills(player, skills, nil, false, true)
      end
    end
  end,
})

longjin:addEffect(fk.TurnEnd, {
  can_refresh = function (self, event, player)
    return player:getMark(longjin.name) > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark(longjin.name)
    room:setPlayerMark(player, longjin.name, mark - 1)
    if mark == 1 then
      local skills = player:getMark("os__longjin_skills")
      if skills ~= 0 then
        room:setPlayerMark(player, "os__longjin_skills", 0)
        room:handleAddLoseSkills(player, "-"..table.concat(skills, "|-"), nil, false, true)
      end
    end
  end,
})

longjin:addEffect("distance", {
  fixed_func = function (self, from, to)
    if from:getMark(longjin.name) > 0 then
      return 1
    end
  end
})

return longjin
