local os__fuzuan = fk.CreateSkill {
  name = "os__fuzuan"
}

Fk:loadTranslationTable{
  ['os__fuzuan'] = '复纂',
  ['#os__fuzuan_trg'] = '复纂',
  ['#os__fuzuan-trg'] = '你可对一名有转换技的角色发动“复纂”',
  [':os__fuzuan'] = '你可于以下时机点选择一名有转换技的角色，调整其一个转换技的阴阳状态：出牌阶段限一次，你对其他角色造成伤害后，受到伤害后。',
  ['$os__fuzuan1'] = '望陛下听臣忠言，勿信资等无知之论。',
  ['$os__fuzuan2'] = '前朝王莽之乱，可为今事之鉴。',
}

-- Active Skill Effect
os__fuzuan:addEffect('active', {
  can_use = function(self, player)
    return player:usedSkillTimes(os__fuzuan.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected ~= 0 then return false end
    for _, skill in ipairs(Fk:currentRoom():getPlayerById(to_select).player_skills) do
      if skill:isSwitchSkill() then
        return true
      end
    end
    return false
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    ChangeSwitchState(room, room:getPlayerById(effect.from), room:getPlayerById(effect.tos[1]), os__fuzuan.name)
  end,
})

-- Trigger Skill Effect
os__fuzuan:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__fuzuan) and (event == fk.Damaged or data.to ~= player) 
      and table.find(player.room.alive_players, function(p)
        return table.find(p.player_skills, function(s) return s:isSwitchSkill() end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return table.find(p.player_skills, function(s) return s:isSwitchSkill() end)
    end), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__fuzuan-trg",
      skill_name = os__fuzuan.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1].id)
      return true
    end 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self)
    room:doIndicate(player.id, {to})
    ChangeSwitchState(room, player, room:getPlayerById(to), os__fuzuan.name)
  end,
})

os__fuzuan:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__fuzuan) 
      and table.find(player.room.alive_players, function(p)
        return table.find(p.player_skills, function(s) return s:isSwitchSkill() end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return table.find(p.player_skills, function(s) return s:isSwitchSkill() end)
    end), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__fuzuan-trg",
      skill_name = os__fuzuan.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1].id)
      return true
    end 
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self)
    room:doIndicate(player.id, {to})
    ChangeSwitchState(room, player, room:getPlayerById(to), os__fuzuan.name)
  end,
})

return os__fuzuan
