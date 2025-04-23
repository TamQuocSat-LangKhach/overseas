local osXingbu = fk.CreateSkill {
  name = "os__xingbu"
}

Fk:loadTranslationTable{
  ["os__xingbu"] = "星卜",
  [":os__xingbu"] = "结束阶段开始时，你可亮出牌堆顶的三张牌，然后你可选择一名其他角色，令其根据其中红色牌的数量获得以下效果之一：<br/>" ..
  "为3：<font color='#CC3131'>«五星连珠»</font>，其下个回合摸牌阶段额定摸牌数+2、使用【杀】的次数上限+1、跳过弃牌阶段；<br/>" ..
  "为2：«白虹贯日»，其下个回合出牌阶段使用第一张牌结算结束后，弃置一张牌，摸两张牌；<br/>" ..
  "不大于1：<font color='grey'>«荧惑守心»</font>，其下个回合使用【杀】的次数上限-1。",

  ["_os__xingbu_1"] = "<font color='grey'>荧惑守心</font>",
  ["#os__xingbu-target"] = "星卜：你可选择一名其他角色，令其获得“%arg”",
  ["@os__xingbu"] = "星卜",
  ["@os__xingbu-turn"] = "星卜",
  ["_os__xingbu_2"] = "白虹贯日",
  ["_os__xingbu_3"] = "<font color='#CC3131'>五星连珠</font>",
  ["#os__xingbu-discard"] = "星卜：弃置一张牌，然后摸两张牌",

  ["$os__xingbu1"] = "天现祥瑞，此乃大吉之兆。",
  ["$os__xingbu2"] = "天象显异，北伐万不可期。",
}

osXingbu:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  mute = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(osXingbu.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osXingbu.name
    local room = player.room
    local cids = room:getNCards(3)
    local num = 0
    for _, cid in ipairs(cids) do
      if Fk:getCardById(cid).color == Card.Red then
        num = num + 1
      end
    end
    local result
    if num > 1 then
      result = "_os__xingbu_" .. tostring(num)
      player:broadcastSkillInvoke(skillName, 1)
      room:notifySkillInvoked(player, skillName)
    else
      result = "_os__xingbu_1"
      player:broadcastSkillInvoke(skillName, 2)
      room:notifySkillInvoked(player, skillName, "negative")
    end
    room:moveCards{
      ids = cids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      skillName = skillName,
      proposer = player,
    }
    local tos = room:askToChoosePlayers(
      player,
      {
        targets = room:getOtherPlayers(player, false),
        min_num = 1,
        max_num = 1,
        prompt = "#os__xingbu-target:::" .. result,
        skill_name = skillName,
      }
    )
    if #tos > 0 then
      room:setPlayerMark(tos[1], "@os__xingbu", result)
    end
    room:moveCardTo(cids, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, skillName, nil, true, player)
  end,
})

osXingbu:addEffect(fk.CardUseFinished, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player)
    if target ~= player or player:getMark("@os__xingbu-turn") == 0 then
      return false
    end
    return player:getMark("@os__xingbu-turn") == "_os__xingbu_2" and player:getMark("_os__xingbu_2-phase") == 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    ---@type string
    local skillName = osXingbu.name
    local room = player.room

    if
      #room:askToDiscard(
        player,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          cancelable = false,
          prompt = "#os__xingbu-discard"
        }
      ) > 0
    then
      player:drawCards(2, skillName)
    end
    room:addPlayerMark(player, "_os__xingbu_2-phase")
  end,
})

osXingbu:addEffect(fk.DrawNCards, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player)
    return target == player and player:getMark("@os__xingbu-turn") ~= 0
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("@os__xingbu-turn") == "_os__xingbu_3" then
      data.n = data.n + 2
    end
  end,
})

osXingbu:addEffect(fk.EventPhaseChanging, {
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target ~= player or player:getMark("@os__xingbu-turn") == 0 then
      return false
    end

    return
      player:getMark("@os__xingbu-turn") == "_os__xingbu_3" and
      data.phase == Player.Discard and
      not data.skipped
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.skipped = true
  end,
})

osXingbu:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player)
    return target == player and player:getMark("@os__xingbu") ~= 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    room:setPlayerMark(player, "@os__xingbu-turn", player:getMark("@os__xingbu"))
    room:setPlayerMark(player, "@os__xingbu", 0)
  end,
})

osXingbu:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if player:getMark("@os__xingbu-turn") ~= 0 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
      if player:getMark("@os__xingbu-turn") == "_os__xingbu_3" then
        return 1
      elseif player:getMark("@os__xingbu-turn") == "_os__xingbu_1" then
        return -1
      end
    end
  end,
})

return osXingbu
