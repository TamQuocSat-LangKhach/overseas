local os__chenshi = fk.CreateSkill {
  name = "os__chenshi"
}

Fk:loadTranslationTable{
  ['os__chenshi'] = '陈势',
  ['#os__chenshi-give1'] = '陈势：你可交给 %src 一张牌，将牌堆顶三张牌中不为【杀】的牌置入弃牌堆',
  ['#os__chenshi-give2'] = '陈势：你可交给 %src 一张牌，将牌堆顶三张牌中的【杀】置入弃牌堆',
  [':os__chenshi'] = '当其他角色使用<a href=>【兵临城下】</a>指定目标后，可交给你一张牌，然后将牌堆顶三张牌中不为【杀】的牌置入弃牌堆；当其他角色成为<a href=>【兵临城下】</a>的目标后，可交给你一张牌，然后将牌堆顶三张牌中的【杀】置入弃牌堆。',
  ['$os__chenshi1'] = '将军已为此二者所围，形势实不容乐观。',
  ['$os__chenshi2'] = '此二人若合力攻之，则将军危矣。',
}

os__chenshi:addEffect(fk.TargetSpecified, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and data.card.name == "enemy_at_the_gates" and player ~= target
  end,
  on_cost = function(self, event, target, player, data)
    local id = player.room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      skill_name = skill.name,
      prompt = "#os__chenshi-give1:" .. player.id
    })
    if #id > 0 then
      event:setCostData(skill, id[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(skill), Player.Hand, player, fk.ReasonGive, skill.name, nil, false)
    local cids = {}
    for i = 1, math.min(3, #room.draw_pile), 1 do
      table.insert(cids, room.draw_pile[i])
    end
    local throw = {}
    for i, id in ipairs(cids) do
      if Fk:getCardById(id).trueName ~= "slash" then
        table.insert(throw, id)
      end
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = skill.name,
      })
    end
    room:delay(1000)
  end,
})

os__chenshi:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(skill.name) and data.card.name == "enemy_at_the_gates" and player ~= target
  end,
  on_cost = function(self, event, target, player, data)
    local id = player.room:askToCards(target, {
      min_num = 1,
      max_num = 1,
      skill_name = skill.name,
      prompt = "#os__chenshi-give2:" .. player.id
    })
    if #id > 0 then
      event:setCostData(skill, id[1])
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCardTo(event:getCostData(skill), Player.Hand, player, fk.ReasonGive, skill.name, nil, false)
    local cids = {}
    for i = 1, math.min(3, #room.draw_pile), 1 do
      table.insert(cids, room.draw_pile[i])
    end
    local throw = {}
    for i, id in ipairs(cids) do
      if Fk:getCardById(id).trueName == "slash" then
        table.insert(throw, id)
      end
    end
    if #throw > 0 then
      room:moveCards({
        ids = throw,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = skill.name,
      })
    end
    room:delay(1000)
  end,
})

return os__chenshi
