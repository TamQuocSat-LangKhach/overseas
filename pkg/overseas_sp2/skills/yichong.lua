local yichong = fk.CreateSkill {
  name = "os__yichong"
}

Fk:loadTranslationTable{
  ['os__yichong'] = '易宠',
  ['@os__yichong'] = '易宠',
  ['#os__yichong-choose'] = '你可以发动 易宠，选择一名其他角色，获得其一种花色的所有牌',
  [':os__yichong'] = '准备阶段，你可选择一名其他角色并选择一种花色，获得其所有该花色的牌，并令其获得“雀”标记直到你下个回合开始（若场上已有“雀”标记则转移给该角色）。拥有“雀”标记的角色获得下一张你指定花色的牌时，你获得之。',
  ['$os__yichong1'] = '弱水三千，唯妾独讨陛下之心。',
  ['$os__yichong2'] = '陛下恩宠如此，妾自堪当此位。',
}

yichong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local to = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), function (p) return p end),
      min_num = 1,
      max_num = 1,
      prompt = "#os__yichong-choose",
      skill_name = yichong.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("yichong")
    local to = room:getPlayerById(event:getCostData(self))
    local suits = {"log_spade", "log_club", "log_heart", "log_diamond"}
    local choice = room:askToChoice(player, {
      choices = suits,
      skill_name = yichong.name
    })
    local cards = table.filter(to:getCardIds{Player.Equip, Player.Hand}, function (id) return Fk:getCardById(id):getSuitString(true) == choice end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, yichong.name, nil, true, player.id)
    end
    if not (player.dead or to.dead) then
      local mark = player:getMark("yichong_target")
      if type(mark) == "table" then
        local orig_to = room:getPlayerById(mark[1])
        local mark2 = orig_to:getMark("@yichong_que")
        if type(mark2) == "table" then
          table.removeOne(mark2, mark[2])
          room:setPlayerMark(orig_to, "@yichong_que", #mark2 > 0 and mark2 or 0)
        end
      end
      room:addTableMark(to, "@yichong_que", choice)
      room:setPlayerMark(player, "yichong_target", {event:getCostData(self), choice})
      room:setPlayerMark(player, "@os__yichong", {0})
    end
  end,
})

yichong:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    local mark = player:getMark("@os__yichong")
    if type(mark) ~= "table" or mark[1] > 0 then return false end
    mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local room = player.room
    local to = room:getPlayerById(mark[1])
    if to == nil or to.dead then return false end
    for _, move in ipairs(event.data.moves) do
      if move.to == mark[1] and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == to and Fk:getCardById(id):getSuitString(true) == mark[2] then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player)
    local mark = player:getMark("@os__yichong")
    if type(mark) ~= "table" or mark[1] > 0 then return false end
    local x = 1 - mark[1]
    mark = player:getMark("yichong_target")
    if type(mark) ~= "table" then return false end
    local to = player.room:getPlayerById(mark[1])
    if to == nil or to.dead then return false end
    local cards = {}
    for _, move in ipairs(event.data.moves) do
      if move.to == mark[1] and move.toArea == Card.PlayerHand then
        for _, info in ipairs(move.moveInfo) do
          local id = info.cardId
          if player.room:getCardArea(id) == Card.PlayerHand and player.room:getCardOwner(id) == to and Fk:getCardById(id):getSuitString(true) == mark[2] then
            table.insert(cards, id)
          end
        end
      end
    end
    if #cards == 0 then return false elseif #cards > x then cards = table.random(cards, x) end
    player.room:setPlayerMark(player, "@os__yichong", {1-x+#cards})
    player.room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, yichong.name, nil, true, player.id)
  end,
})

yichong:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player) return type(player:getMark("yichong_target")) == "table" end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local mark = player:getMark("yichong_target")
    local to = room:getPlayerById(mark[1])
    local mark2 = to:getMark("@yichong_que")
    if type(mark2) == "table" then
      table.removeOne(mark2, mark[2])
      room:setPlayerMark(to, "@yichong_que", #mark2 > 0 and mark2 or 0)
    end
    room:setPlayerMark(player, "yichong_target", 0)
    room:setPlayerMark(player, "@os__yichong", 0)
  end,
})

return yichong
