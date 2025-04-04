local os__wushen = fk.CreateSkill {
  name = "os__wushen"
}

Fk:loadTranslationTable{
  ['os__wushen'] = '武神',
  ['#os__wushen_trg'] = '武神',
  ['@os__nightmare'] = '梦魇',
  [':os__wushen'] = '锁定技，①你的红桃手牌视为【杀】。②你使用红桃【杀】无距离和次数限制且额外选择所有有“梦魇”的角色为目标。③你于每个阶段内使用的第一张【杀】不能被响应。',
  ['$os__wushen1'] = '生当啖汝之肉！',
  ['$os__wushen2'] = '死当追汝之魂！'
}

-- ViewAsSkill
os__wushen:addEffect('viewas', {
  card_filter = function(self, player, to_select)
    return player:hasSkill(os__wushen.name) and to_select.suit == Card.Heart and table.contains(player.player_cards[Player.Hand], to_select.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard("slash", Card.Heart, to_select.number)
    card.skillName = os__wushen.name
    return card
  end,
})

-- TargetModSkill
os__wushen:addEffect('targetmod', {
  bypass_times = function(self, player, skill2, scope, card)
    return player:hasSkill(os__wushen.name) and card and card.trueName == "slash" and card.suit == Card.Heart and scope == Player.HistoryPhase
  end,
  bypass_distances = function(self, player, skill2, card)
    return player:hasSkill(os__wushen.name) and card and card.trueName == "slash" and card.suit == Card.Heart
  end,
})

-- TriggerSkill
os__wushen:addEffect(fk.CardUsing, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__wushen.name) and data.card.trueName == "slash" then
      local events = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.trueName == "slash"
      end, Player.HistoryPhase)
      return #events == 1 and events[1].id == player.room.logic:getCurrentEvent().id
    end
    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      table.insertIfNeed(data.disresponsiveList, p.id)
    end
  end,
})

os__wushen:addEffect(fk.AfterCardTargetDeclared, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(os__wushen.name) and data.card.trueName == "slash" then
      local targets = {}
      local availableTargets = player.room:getUseExtraTargets(data, true)
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if p:getMark("@os__nightmare") > 0 and not table.contains(TargetGroup:getRealTargets(data.tos), p.id) and table.contains(availableTargets, p.id) then
          table.insert(targets, p.id)
        end
      end
      if #targets > 0 then
        event:setCostData(skill, {tos = targets})
        return true
      end
    end
    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__wushen.name, "offensive")
    local targets = event:getCostData(skill).tos
    for _, pid in ipairs(targets) do
      table.insert(data.tos, {pid})
    end
    room:sendLog{
      type = "#AddTargetsBySkill",
      from = player.id,
      to = targets,
      arg = os__wushen.name,
      arg2 = data.card:toLogString()
    }
  end,
})

return os__wushen
