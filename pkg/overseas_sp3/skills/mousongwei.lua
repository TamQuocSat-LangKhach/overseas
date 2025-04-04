local mousongwei = fk.CreateSkill{
  name = "os_mou__songwei$"
}

Fk:loadTranslationTable{
  ['#os_mou__songwei'] = '颂威：你可以让一名其他魏国角色失去技能',
  ['@@os_mou__songwei_target'] = '已颂威',
  ['@os_mou__xingshang_song'] = '颂',
}

mousongwei:addEffect('active', {
  anim_type = "control",
  prompt = "#os_mou__songwei",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return
      player:usedSkillTimes(mousongwei.name, Player.HistoryGame) == 0 and
      table.find(Fk:currentRoom().alive_players, function(p) return p.kingdom == "wei" end)
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select).kingdom == "wei"
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local skills = Fk.generals[target.general]:getSkillNameList(true)
    if target.deputyGeneral ~= "" then
      table.insertTableIfNeed(skills, Fk.generals[target.deputyGeneral]:getSkillNameList(true))
    end
    if #skills > 0 then
      skills = table.map(skills, function(skillName) return "-" .. skillName end)
      room:handleAddLoseSkills(target, table.concat(skills, "|"), nil, true, false)
    end

    room:setPlayerMark(target, "@@os_mou__songwei_target", 1)
  end,
})

mousongwei:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return
      target == player and
      player.phase == Player.Play and
      player:hasSkill(mousongwei.name) and
      player:hasSkill("mouxingshang", true) and
      player:getMark("@os_mou__xingshang_song") < 9 and
      table.find(player.room.alive_players, function(p) return p.kingdom == "wei" and p ~= player end)
  end,
  on_trigger = function(self, event, target, player)
    local room = player.room
    local weiNum = #table.filter(room.alive_players, function(p) return p.kingdom == "wei" and p ~= player end)
    room:addPlayerMark(player, "@os_mou__xingshang_song", math.min(weiNum * 2, 9 - player:getMark("@os_mou__xingshang_song")))
  end,
})

return mousongwei
