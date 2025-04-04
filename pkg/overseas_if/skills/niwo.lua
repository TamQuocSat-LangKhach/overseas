local niwo = fk.CreateSkill{
  name = "os__niwo"
}

Fk:loadTranslationTable{
  ['os__niwo'] = '逆涡',
  ['#os__niwo-choose'] = '逆涡：你可以选择一名角色，选择双方等量的手牌本回合无法使用或打出',
  ['@@os__niwo-inhand-turn'] = '逆涡',
  [':os__niwo'] = '出牌阶段开始时，你可以选择一名其他角色，选择你与其等量的手牌，本回合你与其不能使用或打出这些牌。',
  ['$os__niwo1'] = '疲敌而取之以逸，其势易也！',
  ['$os__niwo2'] = '调其心疲其士，则可以静制动，以弱胜强！',
}

niwo:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(niwo.name) and player.phase == Player.Play
      and not player:isKongcheng() 
      and table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#os__niwo-choose",
      skill_name = niwo.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local data = event:getCostData(self)
    local to = room:getPlayerById(data.tos[1])
    local extra_data = {}
    local visible_data = {}
    for _, id in ipairs(player:getCardIds("h")) do
      if not player:cardVisible(id) then
        visible_data[tostring(id)] = false
      end
    end
    for _, id in ipairs(to:getCardIds("h")) do
      if not player:cardVisible(id) then
        visible_data[tostring(id)] = false
      end
    end
    if next(visible_data) == nil then visible_data = nil end
    extra_data.visible_data = visible_data
    local cards = room:askToPoxi(player, {
      poxi_type = "os__niwo",
      data = {
        { player.general, player:getCardIds("h") },
        { to.general, to:getCardIds("h") },
      },
      extra_data = extra_data,
      cancelable = true
    })
    if #cards > 0 then
      for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@@os__niwo-inhand-turn", 1)
      end
    end
  end,
})

local niwo_prohibit = fk.CreateSkill{
  name = "#os__niwo_prohibit"
}

niwo_prohibit:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return card:getMark("@@os__niwo-inhand-turn") > 0
  end,
  prohibit_response = function(self, player, card)
    return card:getMark("@@os__niwo-inhand-turn") > 0
  end,
})

niwo:addRelatedSkill(niwo_prohibit)

return niwo
