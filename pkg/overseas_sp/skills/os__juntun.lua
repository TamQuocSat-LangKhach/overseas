local os__juntun = fk.CreateSkill {
  name = "os__juntun"
}

Fk:loadTranslationTable{
  ['os__juntun'] = '军屯',
  ['os__xiongjun'] = '凶军',
  ['#os__juntun-ask'] = '军屯：你可令一名没有〖凶军〗的角色获得〖凶军〗',
  [':os__juntun'] = '游戏开始时或当其他角色死亡后，你可令一名没有〖凶军〗的角色获得〖凶军〗。当拥有〖凶军〗的其他角色造成伤害后，你获得等量<a href=>暴虐值</a>。',
  ['$os__juntun1'] = '屯安邑之地，慑山东之贼。',
  ['$os__juntun2'] = '长安丰饶，当以军养军。',
}

os__juntun:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__juntun.name)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(
      table.filter(room.alive_players, function(p)
        return (not p:hasSkill("os__xiongjun"))
      end),
      Util.IdMapper
    )
    if #targets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__juntun-ask",
      skill_name = os__juntun.name,
      cancelable = true,
    })
    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:handleAddLoseSkills(room:getPlayerById(event:getCostData(skill)), "os__xiongjun", nil)
  end,
})

os__juntun:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__juntun.name)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.map(
      table.filter(room.alive_players, function(p)
        return (not p:hasSkill("os__xiongjun"))
      end),
      Util.IdMapper
    )
    if #targets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__juntun-ask",
      skill_name = os__juntun.name,
      cancelable = true,
    })
    if #target > 0 then
      event:setCostData(skill, target[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:handleAddLoseSkills(room:getPlayerById(event:getCostData(skill)), "os__xiongjun", nil)
  end,
})

os__juntun:addEffect(fk.Damage, {
  can_refresh = function(self, event, target, player)
    return target and player:hasSkill(os__juntun.name) and
      (target == player or (event == fk.Damage and target:hasSkill("os__xiongjun"))) and canBaonue(player, data, event)
  end,
  on_refresh = function(self, event, target, player)
    addBaonue(player.room, player, data, event)
  end,
})

os__juntun:addEffect(fk.Damaged, {
  can_refresh = function(self, event, target, player)
    return target and player:hasSkill(os__juntun.name) and
      (target == player or (event == fk.Damage and target:hasSkill("os__xiongjun"))) and canBaonue(player, data, event)
  end,
  on_refresh = function(self, event, target, player)
    addBaonue(player.room, player, data, event)
  end,
})

return os__juntun
