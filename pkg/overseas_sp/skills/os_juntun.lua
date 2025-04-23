local osJuntun = fk.CreateSkill {
  name = "os__juntun"
}

Fk:loadTranslationTable{
  ["os__juntun"] = "军屯",
  [":os__juntun"] = "游戏开始时或当其他角色死亡后，你可令一名没有〖凶军〗的角色获得〖凶军〗；" ..
  "当拥有〖凶军〗的其他角色造成伤害后，你获得等量<a href='os__baonue_href'>暴虐值</a>。",

  ["os__xiongjun"] = "凶军",
  ["#os__juntun-ask"] = "军屯：你可令一名没有〖凶军〗的角色获得〖凶军〗",

  ["$os__juntun1"] = "屯安邑之地，慑山东之贼。",
  ["$os__juntun2"] = "长安丰饶，当以军养军。",
}

osJuntun:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    return player:hasSkill(osJuntun.name)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:hasSkill("os__xiongjun", true)
    end)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__juntun-ask",
        skill_name = osJuntun.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    player.room:handleAddLoseSkills(event:getCostData(self), "os__xiongjun")
  end,
})

osJuntun:addEffect(fk.Deathed, {
  can_trigger = function(self, event, target, player)
    return target ~= player and player:hasSkill(osJuntun.name)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:hasSkill("os__xiongjun", true)
    end)
    if #targets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#os__juntun-ask",
        skill_name = osJuntun.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    player.room:handleAddLoseSkills(event:getCostData(self), "os__xiongjun")
  end,
})

osJuntun:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    return target ~= player and target:hasSkill("os__xiongjun", true) and player:hasSkill(osJuntun.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local num = 5 - data.damage
    if num > 0 then
      player.room:addPlayerMark(player, "@os__baonue", math.min(num, data.damage))
    end
  end,
})

osJuntun:addAcquireEffect(function(self, player)
  for _, effect in ipairs(Fk.skills["#os__baonue_mark"]:getSkeleton().effects) do
    player.room.logic:addTriggerSkill(effect)
  end
end)

return osJuntun
