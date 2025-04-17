local osExEnyuan = fk.CreateSkill {
  name = "os_ex__enyuan"
}

Fk:loadTranslationTable{
  ["os_ex__enyuan"] = "恩怨",
  [":os_ex__enyuan"] = "当你获得一名其他角色至少两张牌后，你可令其摸一张牌。若其手牌区或装备区没有牌，你可改为令其回复1点体力；" ..
  "当你受到1点伤害后，你令伤害来源交给你一张手牌，否则失去1点体力。若其交给你的牌不是<font color=>♥</font>，则你摸一张牌。",

  ["os_ex__enyuan_draw"] = "摸一张牌",
  ["os_ex__enyuan_recover"] = "回复1点体力",
  ["#os_ex__enyuan-invoke"] = "恩怨：你可以令%dest摸牌或满足条件情况下改为回复体力",
  ["#os_ex__enyuan-ask"] = "恩怨：选择一项，令%src执行",
  ["#os_ex__enyuan-give"] = "恩怨：你需交给 %src 一张手牌，否则失去1点体力",

  ["$os_ex__enyuan1"] = "报之以李，还之以桃。",
  ["$os_ex__enyuan2"] = "伤了我，休想全身而退！",
}

osExEnyuan:addEffect(fk.AfterCardsMove, {
  mute = true,
  trigger_times = function(self, event, target, player, data)
    local osExEnyuanTargets = event:getSkillData(self, "os_ex__enyuan_" .. player.id)
    if osExEnyuanTargets then
      local unDoneTargets = table.simpleClone(osExEnyuanTargets.unDone)
      for _, to in ipairs(unDoneTargets) do
        if not to:isAlive() then
          table.remove(osExEnyuanTargets.unDone, 1)
        else
          break
        end
      end

      return #osExEnyuanTargets.unDone + #osExEnyuanTargets.done
    end

    local moveMap = {}
    for _, move in ipairs(data) do
      if
        move.from and
        move.from ~= player and
        move.to == player and
        move.toArea == Card.PlayerHand
      then
        local num = #table.filter(
          move.moveInfo,
          function(info) return table.contains({ Card.PlayerHand, Card.PlayerEquip }, info.fromArea) end
        )
        moveMap[move.from] = (moveMap[move.from] or 0) + num
      end
    end

    osExEnyuanTargets = { unDone = {}, done = {} }
    for to, cardsNum in pairs(moveMap) do
      if cardsNum > 1 then
        table.insert(osExEnyuanTargets.unDone, to)
      end
    end

    if #osExEnyuanTargets.unDone > 0 then
      player.room:sortByAction(osExEnyuanTargets.unDone)
      event:setSkillData(self, "os_ex__enyuan_" .. player.id, osExEnyuanTargets)
    end
    return #osExEnyuanTargets.unDone
  end,
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osExEnyuan.name)
  end,
  on_cost = function(self, event, target, player, data)
    local osExEnyuanTargets = event:getSkillData(self, "os_ex__enyuan_" .. player.id)
    local to = table.remove(osExEnyuanTargets.unDone, 1)
    table.insert(osExEnyuanTargets.done, to)
    event:setSkillData(self, "os_ex__enyuan_" .. player.id, osExEnyuanTargets)

    if
      player.room:askToSkillInvoke(
        player,
        {
          skill_name = osExEnyuan.name,
          prompt = "#os_ex__enyuan-invoke::" .. to.id
        }
      )
    then
      event:setCostData(self, to)
      return true
    end
  end,
  on_trigger = function(self, event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
    self:doCost(event, target, player, data)
    event:setSkillData(self, "cancel_cost", false)
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExEnyuan.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 1)
    room:notifySkillInvoked(player, skillName, "support")
    local targetPlayer = event:getCostData(self)

    if targetPlayer:isNude() and targetPlayer:isWounded() then
      local choice = room:askToChoice(
        player,
        {
          choices = { "os_ex__enyuan_draw", "os_ex__enyuan_recover" },
          skill_name = skillName,
          prompt = "#os_ex__enyuan-ask:" .. targetPlayer.id,
        }
      )
      if choice == "os_ex__enyuan_recover" then
        room:recover{ who = targetPlayer, num = 1, recoverBy = player, skillName = skillName }
      else
        targetPlayer:drawCards(1, skillName)
      end
    else
      targetPlayer:drawCards(1, skillName)
    end
  end,
})

osExEnyuan:addEffect(fk.Damaged, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osExEnyuan.name) and
      data.from and
      data.from ~= player and
      data.from:isAlive() and player:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExEnyuan.name
    local room = player.room
    player:broadcastSkillInvoke(skillName, 2)
    room:notifySkillInvoked(player, skillName)
    local cids = room:askToCards(
      data.from,
      {
        min_num = 1,
        max_num = 1,
        skill_name = skillName,
        prompt = "#os_ex__enyuan-give:" .. player.id,
      }
    )
    if #cids > 0 then
      room:moveCardTo(cids, Player.Hand, player, fk.ReasonGive, skillName, nil, false, data.from)
      if Fk:getCardById(cids[1]).suit ~= Card.Heart then
        player:drawCards(1, skillName)
      end
    else
      room:loseHp(data.from, 1, skillName)
    end
  end,
})

return osExEnyuan
