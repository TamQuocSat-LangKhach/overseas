local os__longjin = fk.CreateSkill {
  name = "os__longjin"
}

Fk:loadTranslationTable{
  ['os__longjin'] = '龙烬',
  [':os__longjin'] = '觉醒技，当你进入濒死状态时，你将体力回复至2点，然后于此回合与之后的五个回合内，你视为拥有〖龙胆〗和〖冲阵〗，且你至其他角色的距离视为1。',
  ['$os__longjin1'] = '龙烬沙场，以全大汉荣光！',
  ['$os__longjin2'] = '长坂龙魂犹在，咆哮万里长安！',
}

os__longjin:addEffect(fk.EnterDying, {
  frequency = Skill.Wake,
  can_trigger = function (self, event, target, player, data)
    return target == player and player:hasSkill(os__longjin.name) and player:usedSkillTimes(os__longjin.name, Player.HistoryGame) == 0
  end,
  can_wake = function (self, event, target, player, data)
    return player.hp < 1
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    room:recover{num = 2 - player.hp, who = player, recoverBy = player, skillName = os__longjin.name}
    if not player.dead then
      room:setPlayerMark(player, "_os__longjin", 6)
      room:handleAddLoseSkills(player, "longdan|chongzhen", nil, false, true)
    end
  end,
})

os__longjin:addEffect(fk.TurnEnd, {
  can_refresh = function (self, event, player)
    return player:getMark("_os__longjin") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("_os__longjin")
    room:setPlayerMark(player, "_os__longjin", mark - 1)
    if mark == 1 then
      room:handleAddLoseSkills(player, "-longdan|-chongzhen", nil, false, true)
    end
  end,
})

local os__longjin_distance = fk.CreateSkill {
  name = "#os__longjin_distance"
}

os__longjin_distance:addEffect('distance', {
  fixed_func = function (self, from, to)
    return (from:getMark("_os__longjin") > 0 and to ~= from) and 1 or nil
  end
})

return os__longjin
