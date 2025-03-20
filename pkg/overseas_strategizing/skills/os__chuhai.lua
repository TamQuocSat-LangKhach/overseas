local os__chuhai = fk.CreateSkill {
  name = "os__chuhai"
}

Fk:loadTranslationTable{
  ['os__chuhai'] = '除害',
  ['@os__chuhai'] = '除害',
  ['#os__chuhai-ask'] = '除害：交给 %src 一张牌',
  ['#os__chuhai-discard'] = '除害：将一张交给你的牌置入弃牌堆',
  [':os__chuhai'] = '<a href=>使命技</a>，令两名其他角色进入濒死状态。成功：当前回合结束时，废除你的判定区，然后每名其他角色依次交给你一张牌。完成前：其他角色交给你牌后，你将其中一张置入弃牌堆。',
  ['$os__chuhai1'] = '快快闪开，伤到你们可就不好了，哈哈哈！',
  ['$os__chuhai2'] = '你自己撞上来的，这可怪不得小爷我！',
  ['$os__chuhai3'] = '小小孽畜，还不伏诛？',
  ['$os__chuhai4'] = '有我在此，安敢为害！',
  ['$os__chuhai5'] = '此番不成，明日再战！',
}

os__chuhai:addEffect(fk.TurnEnd, {
  frequency = Skill.Quest,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getQuestSkillState(os__chuhai.name) == "succeed" and player:getMark("@os__chuhai") >= 2
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__chuhai.name, "control")
    player:broadcastSkillInvoke(os__chuhai.name, math.random(3, 4))
    room:abortPlayerArea(player, {Player.JudgeSlot})
    local targets = room:getOtherPlayers(player)
    local prompt = "#os__chuhai-ask:" .. player.id
    for _, p in ipairs(targets) do
      if player.dead then return end
      if not p.dead and not p:isNude() then
        local card = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = os__chuhai.name,
          cancelable = false,
          prompt = prompt,
        })
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, os__chuhai.name, nil, false, player.id)
        end
      end
    end
    room:setPlayerMark(player, "@os__chuhai", 0)
  end,
})

os__chuhai:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Quest,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(os__chuhai) and player:getQuestSkillState(os__chuhai.name) ~= "succeed" then
      for _, move in ipairs(data) do
        if move.to == player.id and move.moveReason == fk.ReasonGive then
          return true
        end
      end
      return false
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__chuhai.name, "negative")
    player:broadcastSkillInvoke(os__chuhai.name, 5)
    room:updateQuestSkillState(player, os__chuhai.name, true)
    local cards = table.filter(table.map(data, function(info) return info.cardId end), function(id) return room:getCardArea(id) == Card.PlayerHand end)
    if #cards > 0 then
      local c = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = os__chuhai.name,
        cancelable = false,
        pattern = ".|.|.|.|.|." .. table.concat(cards, ","),
        prompt = "#os__chuhai-discard",
      })
      room:moveCardTo(c, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, os__chuhai.name, nil, true, player.id)
    end
  end,
})

os__chuhai:addEffect(fk.EnterDying, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(os__chuhai) and data.damage and data.damage.from == player and
      player:getQuestSkillState(os__chuhai.name) ~= "succeed" and target ~= player and not table.contains(player:getTableMark("_os__chuhai"), target.id)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, os__chuhai.name, "offensive")
    player:broadcastSkillInvoke(os__chuhai.name, math.random(2))
    room:addTableMark(player, "_os__chuhai", target.id)
    room:addPlayerMark(player, "@os__chuhai")
    if player:getMark("@os__chuhai") > 1 then
      room:updateQuestSkillState(player, os__chuhai.name, true) -- ……
      room:updateQuestSkillState(player, os__chuhai.name, false)
    end
  end,
})

return os__chuhai
