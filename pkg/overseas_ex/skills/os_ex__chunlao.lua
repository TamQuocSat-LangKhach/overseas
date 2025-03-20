local os_ex__chunlao = fk.CreateSkill { name = "os_ex__chunlao" }

Fk:loadTranslationTable{
  ['os_ex__chunlao'] = '醇醪',
  ['os__dense_alcohol'] = '醇',
  ['#os_ex__chunlao-ask'] = '醇醪：你可选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”',
  ['#os_ex__chunlao_do'] = '醇醪',
  ['#os_ex__chunlao-get'] = '醇醪：你可获得你一张牌，令此【杀】伤害值基数+1',
  ['#os_ex__chunlao-give'] = '醇醪：你可交给 %src 一张牌，令此【杀】伤害值基数+1',
  ['#os_ex__chunlao-choose_give'] = '醇醪：你可交给一名有“醇醪”的角色一张牌，令此【杀】伤害值基数+1',
  [':os_ex__chunlao'] = '准备阶段开始时，若场上没有“醇”，你可选择一名角色，将其区域内的一张牌置于其武将牌上，称为“醇”。有“醇”的角色使用【杀】时，｛若其为其他角色，其可交给你一张牌；若其为你，你可选择你的一张牌，若为装备区内的牌则获得之｝，令此【杀】伤害值基数+1；其进入濒死状态时，你可将一张“醇”置入弃牌堆并摸一张牌，然后其回复1点体力。',
  ['$os_ex__chunlao1'] = '唉，帐中不可无酒啊！',
  ['$os_ex__chunlao2'] = '无碍（wài），且饮一杯！',
}

os_ex__chunlao:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(os_ex__chunlao.name) and
      player.phase == Player.Start and table.every(player.room.alive_players, function(p)
        return #p:getPile("os__dense_alcohol") == 0
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local availableTargets = table.map(
      table.filter(room.alive_players, function(p)
        return not p:isAllNude()
      end),
      Util.IdMapper
    )
    if #availableTargets == 0 then return false end
    local target = room:askToChoosePlayers(player, {
      targets = availableTargets,
      min_num = 1,
      max_num = 1,
      prompt = "#os_ex__chunlao-ask",
      skill_name = os_ex__chunlao.name,
      cancelable = true
    })
    if #target > 0 then
      event:setCostData(self, { tos = target })
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    target = room:getPlayerById(event:getCostData(self)[1])
    if target:isAllNude() then return false end
    local cid = room:askToChooseCard(player, {
      target = target,
      flag = "hej",
      skill_name = os_ex__chunlao.name
    })
    target:addToPile("os__dense_alcohol", cid, true, os_ex__chunlao.name)
  end,
})

os_ex__chunlao:addEffect({fk.CardUsing, fk.EnterDying}, {
  name = "#os_ex__chunlao_do",
  anim_type = "offensive",
  mute = true,
  can_trigger = function(self, event, target, player)
    if event == fk.CardUsing then return target == player and #player:getPile("os__dense_alcohol") > 0 and data.card.trueName == "slash"
    else return player:hasSkill(os_ex__chunlao.name) and #target:getPile("os__dense_alcohol") > 0 end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    if event == fk.CardUsing then
      local availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return p:hasSkill(os_ex__chunlao.name)
        end),
        Util.IdMapper
      )
      if #availableTargets == 0 then return false
      elseif #availableTargets == 1 then
        local prompt = availableTargets[1] == player.id and "#os_ex__chunlao-get" or "#os_ex__chunlao-give:" .. availableTargets[1]
        local cid = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = os_ex__chunlao.name,
          cancelable = true,
          prompt = prompt
        })
        if #cid > 0 then
          event:setCostData(self, {availableTargets[1], cid[1]})
          return true
        end
      else
        local plist, cid = room:askToChooseCardsAndPlayers(player, {
          min_card_num = 1,
          max_card_num = 1,
          targets = availableTargets,
          min_target_num = 1,
          max_target_num = 1,
          prompt = "#os_ex__chunlao-choose_give",
          skill_name = os_ex__chunlao.name,
          cancelable = true
        })
        if #plist > 0 then
          event:setCostData(self, {plist[1], cid})
          return true
        end
      end
    else
      return room:askToSkillInvoke(player, {
        skill_name = os_ex__chunlao.name,
        data = data
      })
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke(os_ex__chunlao.name)
    if event == fk.CardUsing then
      local chengpu = room:getPlayerById(event:getCostData(self)[1])
      room:notifySkillInvoked(chengpu, os_ex__chunlao.name)
      local cid = event:getCostData(self)[2]
      room:moveCardTo(cid, Player.Hand, chengpu, fk.ReasonGive, os_ex__chunlao.name, nil, false) -- 什么傻逼技能真受不了了就这样吧
      data.additionalDamage = (data.additionalDamage or 0) + 1
    else
      room:notifySkillInvoked(player, os_ex__chunlao.name)
      room:moveCards({
        ids = target:getPile("os__dense_alcohol"),
        from = target.id,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        proposer = player.id,
        skillName = os_ex__chunlao.name,
      })
      if not player.dead then player:drawCards(1, os_ex__chunlao.name) end
      if not target.dead then
        room:recover{
          who = target,
          num = 1,
          recoverBy = player,
          skillName = os_ex__chunlao.name,
        }
      end
    end
  end,
})

return os_ex__chunlao
