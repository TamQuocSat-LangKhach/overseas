local os__jiaohua = fk.CreateSkill {
  name = "os__jiaohua"
}

Fk:loadTranslationTable{
  ['os__jiaohua'] = '教化',
  ['#os__jiaohua'] = '你想对 %dest 发动技能“教化”吗？',
  ['#os__jiaohua-ask'] = '教化：选择一种类别，令 %dest 从牌堆中或弃牌堆中获得一张该类别的牌',
  [':os__jiaohua'] = '当你或体力值最小的角色摸牌后，你可选择一种其本次摸牌未获得的类别（每种类别每回合限一次），令其从牌堆中或弃牌堆中获得一张该类别的牌。',
  ['$os__jiaohua1'] = '教民崇化，以定南疆。',
  ['$os__jiaohua2'] = '知礼数，崇王化，则民不复叛矣。',
}

os__jiaohua:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__jiaohua.name) then return false end
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil --moveData没有target
      if target and (move.to == player.id or table.every(player.room.alive_players, function(p)
        return p.hp >= target.hp
      end)) and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        local cardType = {"basic", "trick", "equip"}
        if type(player:getMark("_os__jiaohua-turn")) == "table" then
          table.forEach(player:getMark("_os__jiaohua-turn"), function(name)
            table.removeOne(cardType, name)
          end)
        end
        if #cardType == 0 then return false end
        for _, info in ipairs(move.moveInfo) do
          table.removeOne(cardType, Fk:getCardById(info.cardId):getTypeString())
        end
        if #cardType > 0 then
          return true
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      local target = move.to and player.room:getPlayerById(move.to) or nil --moveData没有target
      if target and (move.to == player.id or table.every(player.room.alive_players, function(p)
        return p.hp >= target.hp
      end)) and move.moveReason == fk.ReasonDraw and move.toArea == Card.PlayerHand then
        local cardType = {"basic", "trick", "equip"}
        if type(player:getMark("_os__jiaohua-turn")) == "table" then
          table.forEach(player:getMark("_os__jiaohua-turn"), function(name)
            table.removeOne(cardType, name)
          end)
        end
        if #cardType == 0 then return false end
        for _, info in ipairs(move.moveInfo) do
          table.removeOne(cardType, Fk:getCardById(info.cardId):getTypeString())
        end
        if #cardType > 0 then
          event:setCostData(self, {target.id, table.concat(cardType, ",")})
          return player.room:askToSkillInvoke(player, {
            skill_name = os__jiaohua.name,
            prompt = "#os__jiaohua::" .. target.id
          }, data)
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = string.split(event:getCostData(self)[2], ",")
    local choice = room:askToChoice(player, {
      choices = types,
      skill_name = os__jiaohua.name,
      prompt = "#os__jiaohua-ask::" .. event:getCostData(self)[1]
    })
    local id = room:getCardsFromPileByRule(".|.|.|.|.|" .. choice, 1, "allPiles")
    if #id > 0 then
      room:addTableMark(player, "_os__jiaohua-turn", Fk:getCardById(id[1]):getTypeString())
      room:obtainCard(event:getCostData(self)[1], id[1], false, fk.ReasonPrey)
    end
  end,
})

return os__jiaohua
