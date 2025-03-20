local os__kujian = fk.CreateSkill {
  name = "os__kujian"
}

Fk:loadTranslationTable{
  ['os__kujian'] = '苦谏',
  ['#os__kujian-active'] = '你可发动“苦谏”，将至多三张手牌标记为“谏”并交给一名其他角色',
  ['@@os__kujian'] = '谏',
  ['#os__kujian_judge'] = '苦谏',
  ['#os__kujian-discard'] = '苦谏：请弃置一张牌',
  [':os__kujian'] = '出牌阶段限一次，你可将至多三张手牌标记为“谏”并交给一名其他角色。当其他角色使用或打出“谏”牌时，你与其各摸一张牌。当其他角色非因使用或打出从手牌区失去“谏”牌后，你与其各弃置一张牌。',
  ['$os__kujian1'] = '吾之所言，皆为公之大业。',
  ['$os__kujian2'] = '公岂徒有纳谏之名乎！',
  ['$os__kujian3'] = '明公虽奕世克昌，未若有周之盛。',
}

-- 主动技能
os__kujian:addEffect('active', {
  anim_type = "support",
  prompt = "#os__kujian-active",
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(os__kujian.name, Player.HistoryPhase) == 0
  end,
  max_card_num = 3,
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and #selected < 3
  end,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player.id
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])
    local player = room:getPlayerById(effect.from)
    room:notifySkillInvoked(player, os__kujian.name, "support", effect.tos)
    player:broadcastSkillInvoke(os__kujian.name, 1)
    table.forEach(effect.cards, function(cid)
      room:setCardMark(Fk:getCardById(cid), "@@os__kujian", 1)
    end)
    room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, os__kujian.name, nil, false)
  end,
})

-- 触发技能
os__kujian:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__kujian.name) then return false end
    if player == target then return false end
    return table.find(Card:getIdList(data.card), function(id)
      return Fk:getCardById(id):getMark("@@os__kujian") > 0
    end)
  end,
  on_cost = Util.TrueFunc,
  on_trigger = function(self, event, target, player, data)
    local num = #table.filter(Card:getIdList(data.card), function(id)
      return Fk:getCardById(id):getMark("@@os__kujian") > 0
    end)
    for _ = 1, num, 1 do
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__kujian", "drawcard")
    player:broadcastSkillInvoke("os__kujian", 3)
    table.forEach(Card:getIdList(data.card), function(id)
      return room:setCardMark(Fk:getCardById(id), "@@os__kujian", 0)
    end)
    room:doIndicate(player.id, {target.id})
    player:drawCards(1, os__kujian.name)
    target:drawCards(1, os__kujian.name)
  end,
})

os__kujian:addEffect(fk.CardResponding, {
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__kujian.name) then return false end
    if player == target then return false end
    return table.find(Card:getIdList(data.card), function(id)
      return Fk:getCardById(id):getMark("@@os__kujian") > 0
    end)
  end,
  on_cost = Util.TrueFunc,
  on_trigger = function(self, event, target, player, data)
    local num = #table.filter(Card:getIdList(data.card), function(id)
      return Fk:getCardById(id):getMark("@@os__kujian") > 0
    end)
    for _ = 1, num, 1 do
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__kujian", "drawcard")
    player:broadcastSkillInvoke("os__kujian", 3)
    table.forEach(Card:getIdList(data.card), function(id)
      return room:setCardMark(Fk:getCardById(id), "@@os__kujian", 0)
    end)
    room:doIndicate(player.id, {target.id})
    player:drawCards(1, os__kujian.name)
    target:drawCards(1, os__kujian.name)
  end,
})

os__kujian:addEffect(fk.AfterCardsMove, {
  anim_type = "drawcard",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(os__kujian.name) then return false end
    for _, move in ipairs(data) do
      if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        if table.find(move.moveInfo, function(info)
          return Fk:getCardById(info.cardId):getMark("@@os__kujian") > 0 and info.fromArea == Card.PlayerHand
        end) then
          return true
        end
      end
    end
    return false
  end,
  on_cost = Util.TrueFunc,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    for _, move in ipairs(data) do
      if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          if Fk:getCardById(info.cardId):getMark("@@os__kujian") > 0 and info.fromArea == Card.PlayerHand then
            table.insert(targets, move.from)
          end
        end
      end
    end
    room:sortPlayersByAction(targets)
    for _, target_id in ipairs(targets) do
      if not player:hasSkill(os__kujian.name) then break end
      local skill_target = room:getPlayerById(target_id)
      if skill_target and not skill_target.dead and not player.dead and not (skill_target:isNude() and player:isNude()) then
        self:doCost(event, skill_target, player, data)
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, "os__kujian", "negative")
    player:broadcastSkillInvoke("os__kujian", 2)
    room:doIndicate(player.id, {target.id})
    for _, move in ipairs(data) do
      if move.from ~= player.id and move.moveReason ~= fk.ReasonUse and move.moveReason ~= fk.ReasonResonpse then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            room:setCardMark(Fk:getCardById(info.cardId), "@@os__kujian", 0)
          end
        end
      end
    end
    local discard_params = {min_num = 1, max_num = 1, include_equip = true, skill_name = os__kujian.name, cancelable = false, prompt = "#os__kujian-discard"}
    room:askToDiscard(player, discard_params)
    room:askToDiscard(target, discard_params)
  end,
})

return os__kujian
