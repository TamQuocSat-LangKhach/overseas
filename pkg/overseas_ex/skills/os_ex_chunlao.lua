local osExChunlao = fk.CreateSkill{
  name = "os_ex__chunlao",
}

Fk:loadTranslationTable{
  ["os_ex__chunlao"] = "醇醪",
  [":os_ex__chunlao"] = "准备阶段开始时，若场上没有“醇”，你可选择一名角色，将其区域内的一张牌置于其武将牌上，" ..
  "称为“醇”。有“醇”的角色使用【杀】时，｛若其为其他角色，其可交给你一张牌；若其为你，你可选择你的一张牌，若为装备区内的牌则获得之｝，" ..
  "令此【杀】伤害值基数+1；其进入濒死状态时，你可将一张“醇”置入弃牌堆并摸一张牌，然后其回复1点体力。",

  ["os__dense_alcohol"] = "醇",
  ["#os_ex__chunlao-ask"] = "醇醪：你可选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”",
  ["#os_ex__chunlao_do"] = "醇醪",
  ["#os_ex__chunlao-get"] = "醇醪：你可获得你一张牌，令此【杀】伤害值基数+1",
  ["#os_ex__chunlao-give"] = "醇醪：你可交给 %src 一张牌，令此【杀】伤害值基数+1",
  ["#os_ex__chunlao-choose_give"] = "醇醪：你可交给一名有“醇醪”的角色一张牌，令此【杀】伤害值基数+1",

  ["$os_ex__chunlao1"] = "唉，帐中不可无酒啊！",
  ["$os_ex__chunlao2"] = "无碍（wài），且饮一杯！",
}

osExChunlao:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(osExChunlao.name) and
      player.phase == Player.Start and
      table.every(player.room.alive_players, function(p)
        return #p:getPile("os__dense_alcohol") == 0
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local availableTargets = table.filter(room.alive_players, function(p)
      return not p:isAllNude()
    end)
    if #availableTargets == 0 then
      return false
    end

    local tos = room:askToChoosePlayers(
      player,
      {
        targets = availableTargets,
        min_num = 1,
        max_num = 1,
        prompt = "#os_ex__chunlao-ask",
        skill_name = osExChunlao.name,
      }
    )
    if #tos > 0 then
      event:setCostData(self, { tos = tos })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExChunlao.name
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:isAllNude() then
      return false
    end

    local cid = room:askToChooseCard(
      player,
      {
        target = to,
        flag = "hej",
        skill_name = skillName,
      }
    )
    to:addToPile("os__dense_alcohol", cid, true, skillName)
  end,
})

osExChunlao:addEffect(fk.CardUsing, {
  is_delay_effect = true,
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      #player:getPile("os__dense_alcohol") > 0 and
      data.card.trueName == "slash" and
      table.find(player.room.alive_players, function(p)
        return p:hasSkill(osExChunlao.name)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    ---@type string
    local skillName = osExChunlao.name
    local room = player.room
    local availableTargets = table.filter(room.alive_players, function(p)
      return p:hasSkill(skillName)
    end)
    if #availableTargets == 0 then
      return false
    elseif #availableTargets == 1 then
      local prompt = availableTargets[1] == player and
        "#os_ex__chunlao-get" or
        "#os_ex__chunlao-give:" .. availableTargets[1].id
      local cid = room:askToCards(
        player,
        {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = skillName,
          cancelable = true,
          prompt = prompt,
        }
      )
      if #cid > 0 then
        event:setCostData(self, { availableTargets[1], cid[1] })
        return true
      end
    else
      local plist, cid = room:askToChooseCardsAndPlayers(
        player,
        {
          min_card_num = 1,
          max_card_num = 1,
          targets = availableTargets,
          min_num = 1,
          max_num = 1,
          prompt = "#os_ex__chunlao-choose_give",
          skill_name = skillName,
        }
      )
      if #plist > 0 then
        event:setCostData(self, { plist[1], cid })
        return true
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room

    local chengpu = event:getCostData(self)[1]
    local cid = event:getCostData(self)[2]
    room:moveCardTo(cid, Player.Hand, chengpu, fk.ReasonGive, osExChunlao.name, nil, false, player) -- 什么傻逼技能真受不了了就这样吧
    data.additionalDamage = (data.additionalDamage or 0) + 1
  end,
})

osExChunlao:addEffect(fk.EnterDying, {
  is_delay_effect = true,
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(osExChunlao.name) and #target:getPile("os__dense_alcohol") > 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(
      player,
      {
        skill_name = osExChunlao.name,
      }
    )
  end,
  on_use = function(self, event, target, player, data)
    ---@type string
    local skillName = osExChunlao.name
    local room = player.room
    room:moveCards{
      ids = target:getPile("os__dense_alcohol"),
      from = target,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      proposer = player,
      skillName = skillName,
    }
    if player:isAlive() then
      player:drawCards(1, skillName)
    end
    if target:isAlive() then
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = skillName,
      }
    end
  end,
})

return osExChunlao
