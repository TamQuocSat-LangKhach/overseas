local os__baijia = fk.CreateSkill {
  name = "os__baijia"
}

Fk:loadTranslationTable{
  ['os__baijia'] = '拜假',
  ['@os__guju'] = '骨疽',
  ['@@os__puppet'] = '傀',
  [':os__baijia'] = '觉醒技，准备阶段开始时，若你因〖骨疽〗获得牌不小于7张，则你加1点体力上限，回复1点体力，然后令所有未拥有“傀”的其他角色获得一枚“傀”，最后失去〖骨疽〗，并获得〖蚕食〗。',
  ['$os__baijia1'] = '没有人能阻止我的觉醒。',
  ['$os__baijia2'] = '哼哼哼……这才是我的真面目。',
}

os__baijia:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__baijia.name) and
      player.phase == Player.Start and
      player:usedSkillTimes(os__baijia.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:getMark("@os__guju") > 6
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@os__guju", 0)
    room:changeMaxHp(player, 1)
    room:recover({
      who = player,
      num = 1,
      recoverBy = player,
      skillName = os__baijia.name,
    })
    table.forEach(table.filter(room:getOtherPlayers(player, false), function(p)
      return p:getMark("@@os__puppet") == 0
    end), function(p)
        room:addPlayerMark(p, "@@os__puppet")
      end)
    room:handleAddLoseSkills(player, "os__canshi|-os__guju", nil)
  end,
})

return os__baijia
