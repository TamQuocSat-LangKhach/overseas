local os__lvren = fk.CreateSkill {
  name = "os__lvren"
}

Fk:loadTranslationTable{
  ['os__lvren'] = '履刃',
  ['@@os__blade'] = '刃',
  ['#os__lvren-targets'] = '履刃：你可令一有“刃”的角色也成为目标，然后其弃“刃”',
  [':os__lvren'] = '①当你对其他角色造成伤害时，若其没有“刃”，你令其获得1枚“刃”。②当你使用伤害牌选择目标后，可令一名有“刃”的角色也成为目标，然后其弃1枚“刃”。③你拼点时，每有一名角色，你的拼点牌点数+2。',
  ['$os__lvren1'] = '坚甲利刃，破之如鲁缟！',
  ['$os__lvren2'] = '攻城破阵，如履平地！'
}

os__lvren:addEffect(fk.AfterCardTargetDeclared, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__lvren) and data.card.is_damage_card
  end,
  on_cost = function(self, event, target, player, data)
    local availableTargets = table.map(table.filter(player.room.alive_players, function(p)
      return p:getMark("@@os__blade") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id)
    end), Util.IdMapper)
    if #availableTargets == 0 then return false end
    local targets = player.room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = "#os__lvren-targets",
      skill_name = os__lvren.name,
      cancelable = true,
    })
    if #targets > 0 then
      event:setCostData(self, targets)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, event:getCostData(self))
    table.insert(data.tos, event:getCostData(self)[1])
    room:removePlayerMark(room:getPlayerById(event:getCostData(self)[1]), "@@os__blade")
  end,
})

os__lvren:addEffect(fk.DamageCaused, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(os__lvren) and data.to:getMark("@@os__blade") == 0 and data.to ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__lvren.name)
    player:broadcastSkillInvoke(os__lvren.name)
    room:addPlayerMark(data.to, "@@os__blade")
  end,
})

os__lvren:addEffect(fk.PindianCardsDisplayed, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__lvren) and (data.from == player or table.contains(data.tos, player))
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__lvren.name)
    player:broadcastSkillInvoke(os__lvren.name)
    room:changePindianNumber(data, player, 2 * (#data.tos + 1), os__lvren.name)
  end,
})

return os__lvren
