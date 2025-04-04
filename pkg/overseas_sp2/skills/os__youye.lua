local os__youye = fk.CreateSkill {
  name = "os__youye"
}

Fk:loadTranslationTable{
  ['os__youye'] = '攸业',
  ['os__poise'] = '蓄',
  ['#os__youye-give'] = '定镇：将至少一张“蓄”分配给 %dest，点击“确定”后再将剩余牌分配给任意角色',
  ['#os__youye-give2'] = '定镇：分配任意张“蓄”给任意角色，直到所有“蓄”分配完毕',
  [':os__youye'] = '锁定技，其他角色的结束阶段开始时，若其本回合没有对你造成过伤害，则你将牌堆顶的一张牌置于你的武将牌上，称为“蓄”（至多5张）。当你造成或受到伤害后，你将所有“蓄”分配给任意角色，若当前回合角色存活，其至少须获得一张。',
  ['$os__youye1'] = '筑城西疆，开万代太平。',
  ['$os__youye2'] = '镇边戍卫，许万民攸业。',
}

os__youye:addEffect(fk.EventPhaseEnd, {
  global = false,
  can_trigger = function(self, event, target, player)
    return target.phase == Player.Finish and player:hasSkill(os__youye.name) and target ~= player and #player:getPile("os__poise") < 5
      and #player.room.logic:getActualDamageEvents(1, function(e) return e.data[1].to == player end) == 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__youye.name)
    room:notifySkillInvoked(player, os__youye.name, "drawcard")
    player:addToPile("os__poise", room:getNCards(1)[1], true, os__youye.name)
  end,
})

os__youye:addEffect(fk.Damage, {
  global = false,
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__youye.name) and #player:getPile("os__poise") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__youye.name)
    room:notifySkillInvoked(player, os__youye.name, "support")
    local cards = player:getPile("os__poise")
    local current = room.current
    local toCurrent = {}
    if not current.dead then
      if #cards == 1 then
        toCurrent = cards
      else
        toCurrent = room:askToCards(player, {
          min_num = 1,
          max_num = #cards,
          pattern = ".|.|.|os__poise",
          prompt = "#os__youye-give::" .. current.id,
          expand_pile = "os__poise"
        })
      end
    end
    local residue = table.filter(cards, function(id) return not table.contains(toCurrent, id) end)
    if #residue == 0 then
      room:obtainCard(current, toCurrent, true, fk.ReasonGive, player.id, os__youye.name)
    else
      local move = room:askToYiji(player, {
        cards = residue,
        targets = room.alive_players,
        min_num = #residue,
        max_num = #residue,
        prompt = "#os__youye-give2",
        expand_pile = "os__poise",
        skip = true
      })
      move[current.id] = move[current.id] or {}
      table.insertTable(move[current.id], toCurrent)
      room:doYiji(move, player.id, os__youye.name)
    end
  end,
})

os__youye:addEffect(fk.Damaged, {
  global = false,
  can_trigger = function(self, event, target, player)
    return player == target and player:hasSkill(os__youye.name) and #player:getPile("os__poise") > 0
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os__youye.name)
    room:notifySkillInvoked(player, os__youye.name, "support")
    local cards = player:getPile("os__poise")
    local current = room.current
    local toCurrent = {}
    if not current.dead then
      if #cards == 1 then
        toCurrent = cards
      else
        toCurrent = room:askToCards(player, {
          min_num = 1,
          max_num = #cards,
          pattern = ".|.|.|os__poise",
          prompt = "#os__youye-give::" .. current.id,
          expand_pile = "os__poise"
        })
      end
    end
    local residue = table.filter(cards, function(id) return not table.contains(toCurrent, id) end)
    if #residue == 0 then
      room:obtainCard(current, toCurrent, true, fk.ReasonGive, player.id, os__youye.name)
    else
      local move = room:askToYiji(player, {
        cards = residue,
        targets = room.alive_players,
        min_num = #residue,
        max_num = #residue,
        prompt = "#os__youye-give2",
        expand_pile = "os__poise",
        skip = true
      })
      move[current.id] = move[current.id] or {}
      table.insertTable(move[current.id], toCurrent)
      room:doYiji(move, player.id, os__youye.name)
    end
  end,
})

return os__youye
