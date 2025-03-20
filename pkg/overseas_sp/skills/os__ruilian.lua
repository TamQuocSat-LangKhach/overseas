local os__ruilian = fk.CreateSkill {
  name = "os__ruilian"
}

Fk:loadTranslationTable{
  ['os__ruilian'] = '睿敛',
  ['@os__ruilian-turn'] = '睿敛',
  ['#os__ruilian-ask'] = '你可对一名角色发动“睿敛”',
  ['#os__ruilian-type'] = '睿敛：你可选择 %src 此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌',
  ['@@os__ruilian'] = '睿敛',
  [':os__ruilian'] = '每轮开始时，你可选择一名角色，其下个回合结束前，若其此回合弃置的牌数不小于2，你可选择其此回合弃置过的牌中的一种类别，你与其各从弃牌堆中获得一张此类别的牌。',
  ['$os__ruilian1'] = '公若擅进庸肆，必失民心！',
  ['$os__ruilian2'] = '外敛虚进之势，内减弊民之政。',
}

os__ruilian:addEffect(fk.RoundStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__ruilian) and (event == fk.RoundStart or (tonumber(target:getMark("@os__ruilian-turn")) > 1 and table.contains(target:getMark("_os__ruilianGiver"), player.id)))
  end,
  on_cost = function(self, event, target, player)
    if event == fk.RoundStart then
      local target = player.room:askToChoosePlayers(player, {
        targets = table.map(player.room.alive_players, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        prompt = "#os__ruilian-ask",
        skill_name = os__ruilian.name,
        cancelable = true
      })
      if #target > 0 then
        event:setCostData(skill, target[1])
        return true
      end
    else
      local cids = target:getMark("_os__ruilianCids-turn")
      local cardType = {}
      table.forEach(cids, function(cid)
        table.insertIfNeed(cardType, Fk:getCardById(cid):getTypeString())
      end)
      table.insert(cardType, "Cancel")
      local choice = player.room:askToChoice(player, {
        choices = cardType,
        skill_name = os__ruilian.name,
        prompt = "#os__ruilian-type:" .. target.id
      })
      if choice ~= "Cancel" then
        event:setCostData(skill, choice)
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.RoundStart then
      local target = room:getPlayerById(event:getCostData(skill))
      room:setPlayerMark(target, "@@os__ruilian", 1)
      room:addTableMarkIfNeed(target, "_os__ruilianGiver", player.id)
    else
      local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. event:getCostData(skill), 1, "discardPile")
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey)
      end
      id = room:getCardsFromPileByRule(".|.|.|.|.|" .. event:getCostData(skill), 1, "discardPile")
      if #id > 0 then
        room:obtainCard(target, id[1], false, fk.ReasonPrey)
      end
    end
  end,
})

os__ruilian:addEffect(fk.TurnEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(os__ruilian) and (event == fk.RoundStart or (tonumber(target:getMark("@os__ruilian-turn")) > 1 and table.contains(target:getMark("_os__ruilianGiver"), player.id)))
  end,
  on_cost = function(self, event, target, player)
    if event == fk.TurnEnd then
      local cids = target:getMark("_os__ruilianCids-turn")
      local cardType = {}
      table.forEach(cids, function(cid)
        table.insertIfNeed(cardType, Fk:getCardById(cid):getTypeString())
      end)
      table.insert(cardType, "Cancel")
      local choice = player.room:askToChoice(player, {
        choices = cardType,
        skill_name = os__ruilian.name,
        prompt = "#os__ruilian-type:" .. target.id
      })
      if choice ~= "Cancel" then
        event:setCostData(skill, choice)
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if event == fk.TurnEnd then
      local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. event:getCostData(skill), 1, "discardPile")
      if #id > 0 then
        room:obtainCard(player, id[1], false, fk.ReasonPrey)
      end
      id = room:getCardsFromPileByRule(".|.|.|.|.|" .. event:getCostData(skill), 1, "discardPile")
      if #id > 0 then
        room:obtainCard(target, id[1], false, fk.ReasonPrey)
      end
    end
  end,
})

os__ruilian:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player)
    if player ~= player.room.current then return false end
    local cids = {}
    for _, move in ipairs(player:getMark("last_move")) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(cids, info.cardId)
          end
        end
      end
    end
    if #cids > 0 then
      return true
    end
    return false
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local cids = player:getTableMark("_os__ruilianCids-turn")
    local otherCids = {}
    for _, move in ipairs(player:getMark("last_move")) do
      if move.from == player.id and move.moveReason == fk.ReasonDiscard then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
            table.insert(otherCids, info.cardId)
          end
        end
      end
    end
    table.insertTable(cids, otherCids)
    room:setPlayerMark(player, "_os__ruilianCids-turn", cids)
    room:setPlayerMark(player, "@os__ruilian-turn", #player:getMark("_os__ruilianCids-turn"))
  end,
})

os__ruilian:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@@os__ruilian") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@os__ruilian-turn", "0")
    room:setPlayerMark(player, "@@os__ruilian", 0)
  end,
})

return os__ruilian
