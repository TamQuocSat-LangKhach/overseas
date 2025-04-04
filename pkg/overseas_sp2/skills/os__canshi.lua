local os__canshi = fk.CreateSkill {
  name = "os__canshi"
}

Fk:loadTranslationTable{
  ['os__canshi'] = '蚕食',
  ['@@os__puppet'] = '傀',
  ['#os__canshi'] = '蚕食：你可取消【%arg】的目标，然后 %dest 弃“傀”',
  ['#os__canshi-targets'] = '蚕食：你可令任意名有“傀”的角色也成为目标，然后这些角色弃“傀”',
  [':os__canshi'] = '①当一名角色使用基本牌或普通锦囊牌指定你为唯一目标时，若其有“傀”，你可取消之，然后其弃1枚“傀”。②你使用基本牌或普通锦囊牌仅选择一名角色为目标时，你可令任意名带有“傀”的角色也成为目标，然后这些角色弃1枚“傀”。',
  ['$os__canshi1'] = '此患不足为惧，可蚕食而尽。',
  ['$os__canshi2'] = '小则蚕食，大则溃坝。',
}

os__canshi:addEffect(fk.TargetConfirming, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__canshi.name) and 
      #AimGroup:getAllTargets(data.tos) == 1 and 
      player.room:getPlayerById(data.from):getMark("@@os__puppet") > 0 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = os__canshi.name,
      prompt = "#os__canshi::" .. data.from .. ":" .. data.card.name
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os__canshi.name, 1)
    room:notifySkillInvoked(player, os__canshi.name, "defensive")
    AimGroup:cancelTarget(data, data.to)
    room:removePlayerMark(room:getPlayerById(data.from), "@@os__puppet")
  end,
})

os__canshi:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__canshi.name) and 
      data.tos and #data.tos == 1 and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick())
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p)
      return p:getMark("@@os__puppet") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and
        not player:isProhibited(p, data.card)
    end)

    if #targets == 0 then return false end

    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = #targets,
      prompt = "#os__canshi-targets",
      skill_name = os__canshi.name
    })

    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(os__canshi.name, 2)
    room:notifySkillInvoked(player, os__canshi.name, "special")
    local tos = event:getCostData(self)
    room:doIndicate(player.id, tos)
    for _, pid in ipairs(tos) do
      table.insert(data.tos, {pid})
      room:removePlayerMark(room:getPlayerById(pid), "@@os__puppet")
    end

    room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = tos,
      arg = os__canshi.name,
      arg2 = data.card:toLogString()
    }
  end
})

return os__canshi
