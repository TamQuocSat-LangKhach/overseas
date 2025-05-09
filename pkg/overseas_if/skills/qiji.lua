local qiji = fk.CreateSkill {
  name = "os__qiji",
}

Fk:loadTranslationTable{
  ["os__qiji"] = "奇击",
  [":os__qiji"] = "出牌阶段开始时，你可以视为对一名其他角色使用X张无距离限制且不计入次数的【杀】，此【杀】指定目标时，其可以选择一名本回合"..
  "未以此法选择过的其他角色，被选择的角色摸一张牌，然后其可以将此【杀】的目标转移给自己（X为出牌阶段开始时你手牌的类别数）。",

  ["#os__qiji-invoke"] = "奇击：你可以视为对一名其他角色使用%arg张【杀】！",
  ["#os__qiji-choose"] = "奇击：你可以令一名角色摸一张牌，其可以将此【杀】转移给其",
  ["#os__qiji-ask"] = "奇击：是否将对 %src 使用的【杀】转移给你？",

  ["$os__qiji1"] = "久攻不克？待吾奇兵灭敌！",
  ["$os__qiji2"] = "依我此计，魏都不日可下！",
}

qiji:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qiji.name) and player.phase == Player.Play and
      not player:isKongcheng() and table.find(player.room:getOtherPlayers(player, false), function (p)
        return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local types = {}
    for _, id in ipairs(player:getCardIds("h")) do
      table.insertIfNeed(types, Fk:getCardById(id).type)
    end
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return player:canUseTo(Fk:cloneCard("slash"), p, {bypass_distances = true, bypass_times = true})
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__qiji-invoke:::"..#types,
      skill_name = qiji.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to, choice = #types})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = event:getCostData(self).choice
    for _ = 1, n do
      if to.dead then break end
      room:useVirtualCard("slash", nil, player, to, qiji.name, true)
    end
  end,
})

qiji:addEffect(fk.TargetSpecifying, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target:usedSkillTimes(qiji.name, Player.HistoryPhase) > 0 and data.to == player and
      table.contains(data.card.skillNames, qiji.name) and
      not (data.extra_data and data.extra_data.os__qiji) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return target ~= p and not table.contains(player:getTableMark("os__qiji-turn"), p.id)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return target ~= p and not table.contains(player:getTableMark("os__qiji-turn"), p.id)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__qiji-choose",
      skill_name = qiji.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {extra_data = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.extra_data = data.extra_data or {}
    data.extra_data.os__qiji = true
    local to = event:getCostData(self).extra_data[1]
    room:addTableMark(player, "os__qiji-turn", to.id)
    to:drawCards(1, "os__qiji-turn")
    if not to.dead and table.contains(data:getExtraTargets({bypass_distances = true}), to) and
      room:askToSkillInvoke(to, {
        skill_name = qiji.name,
        prompt = "#os__qiji-ask:"..player.id,
      }) then
      data:cancelTarget(player)
      data:addTarget(to)
    end
  end,
})

return qiji
