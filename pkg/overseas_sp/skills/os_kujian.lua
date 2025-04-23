local osKujian = fk.CreateSkill {
  name = "os__kujian"
}

Fk:loadTranslationTable{
  ["os__kujian"] = "苦谏",
  [":os__kujian"] = "出牌阶段限一次，你可将至多三张手牌标记为“谏”并交给一名其他角色。当其他角色使用或打出“谏”牌时，" ..
  "你与其各摸一张牌。当其他角色非因使用或打出从手牌区失去“谏”牌后，你与其各弃置一张牌。",

  ["#os__kujian-active"] = "你可发动“苦谏”，将至多三张手牌标记为“谏”并交给一名其他角色",
  ["@@os__kujian-inhand"] = "谏",
  ["#os__kujian-discard"] = "苦谏：请弃置一张牌",

  ["$os__kujian1"] = "吾之所言，皆为公之大业。",
  ["$os__kujian2"] = "公岂徒有纳谏之名乎！",
  ["$os__kujian3"] = "明公虽奕世克昌，未若有周之盛。",
}

-- 主动技能
osKujian:addEffect("active", {
  prompt = "#os__kujian-active",
  mute = true,
  can_use = function(self, player)
    return player:usedSkillTimes(osKujian.name, Player.HistoryPhase) == 0
  end,
  max_card_num = 3,
  min_card_num = 1,
  card_filter = function(self, player, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Card.PlayerHand and #selected < 3
  end,
  target_filter = function(self, player, to_select, selected)
    return to_select ~= player
  end,
  target_num = 1,
  on_use = function(self, room, effect)
     ---@type string
     local skillName = osKujian.name
     local target = effect.tos[1]
     local player = effect.from
     room:notifySkillInvoked(player, skillName, "support", effect.tos)
     player:broadcastSkillInvoke(skillName, 1)
     room:moveCardTo(effect.cards, Player.Hand, target, fk.ReasonGive, skillName, nil, false, player, "@@os__kujian-inhand")
  end,
})

-- 触发技能
local osKujianUseOrResponseRecordSpec = {
  can_refresh = function(self, event, target, player, data)
    return
      not (data.extra_data or {}).osKujianIds and
      table.find(Card:getIdList(data.card), function(id)
        return Fk:getCardById(id):getMark("@@os__kujian-inhand") > 0
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.osKujianIds = table.filter(Card:getIdList(data.card), function(id)
      return Fk:getCardById(id):getMark("@@os__kujian-inhand") > 0
    end)
  end,
}

osKujian:addEffect(fk.PreCardUse, osKujianUseOrResponseRecordSpec)

osKujian:addEffect(fk.PreCardRespond, osKujianUseOrResponseRecordSpec)

local osKujianUseOrResponseSpec = {
  mute = true,
  trigger_times = function(self, event, target, player, data)
    return
      type((data.extra_data or {}).osKujianIds) == "table" and
      #table.filter(Card:getIdList(data.card), function(id)
        return table.contains(data.extra_data.osKujianIds, id)
      end) or
      0
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osKujian.name) and player ~= target
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osKujian.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "drawcard")
    player:broadcastSkillInvoke(skillName, 3)
    room:doIndicate(player, { target })

    local targets = { player, target }
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      p:drawCards(1, skillName)
    end
  end,
}

osKujian:addEffect(fk.CardUsing, osKujianUseOrResponseSpec)

osKujian:addEffect(fk.CardResponding, osKujianUseOrResponseSpec)

osKujian:addEffect(fk.BeforeCardsMove, {
  can_refresh = function(self, event, target, player, data)
    return
      not (data.extra_data or {}).osKujianIds and
      table.find(data, function(move)
        return table.find(move.moveInfo, function(info)
          return Fk:getCardById(info.cardId):getMark("@@os__kujian-inhand") > 0
        end)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    local osKujianIds = {}
    for _, move in ipairs(data) do
      for _, info in ipairs(move.moveInfo) do
        if Fk:getCardById(info.cardId):getMark("@@os__kujian-inhand") > 0 then
          table.insert(osKujianIds, info.cardId)
        end
      end
    end

    data.extra_data = data.extra_data or {}
    data.extra_data.osKujianIds = osKujianIds
  end,
})

osKujian:addEffect(fk.AfterCardsMove, {
  mute = true,
  trigger_times = function(self, event, target, player, data)
    if type((data.extra_data or {}).osKujianIds) ~= "table" then
      return 0
    end

    local osKujianTargets = event:getSkillData(self, "os__kujian_" .. player.id)
    if osKujianTargets then
      local unDoneTargets = table.simpleClone(osKujianTargets.unDone)
      for _, to in ipairs(unDoneTargets) do
        if not to:isAlive() and not (player:isNude() and to:isNude()) then
          table.remove(osKujianTargets.unDone, 1)
        else
          break
        end
      end

      return #osKujianTargets.unDone + #osKujianTargets.done
    end

    osKujianTargets = { unDone = {}, done = {} }
    for _, move in ipairs(data) do
      if
        move.from and
        move.from ~= player and
        move.moveReason ~= fk.ReasonUse and
        move.moveReason ~= fk.ReasonResponse
      then
        for _, info in ipairs(move.moveInfo) do
          if table.contains(data.extra_data.osKujianIds, info.cardId) and info.fromArea == Card.PlayerHand then
            table.insert(osKujianTargets.unDone, move.from)
          end
        end
      end
    end

    if #osKujianTargets.unDone > 0 then
      player.room:sortByAction(osKujianTargets.unDone)
      event:setSkillData(self, "os__kujian_" .. player.id, osKujianTargets)
    end
    return #osKujianTargets.unDone
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osKujian.name)
  end,
  on_cost = function(self, event, target, player, data)
    local osKujianTargets = event:getSkillData(self, "os__kujian_" .. player.id)
    local to = table.remove(osKujianTargets.unDone, 1)
    table.insert(osKujianTargets.done, to)
    event:setSkillData(self, "kujian_" .. player.id, osKujianTargets)

    event:setCostData(self, to)
    return true
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osKujian.name
    local room = player.room
    room:notifySkillInvoked(player, skillName, "negative")
    player:broadcastSkillInvoke(skillName, 2)
    local to = event:getCostData(self)
    room:doIndicate(player, { to })

    local targets = { player, to }
    room:sortByAction(targets)
    for _, p in ipairs(targets) do
      room:askToDiscard(
        p,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
          prompt = "#os__kujian-discard",
        }
      )
    end
  end,
})

return osKujian
