local os__jianwei = fk.CreateSkill {
  name = "os__jianwei"
}

Fk:loadTranslationTable{
  ['os__jianwei'] = '剑威',
  ['#os__jianwei_pd'] = '剑威',
  ['#os__jianwei-target'] = '剑威：你可与一名攻击范围内的角色拼点：若你赢，你获得其每个区域各一张牌；若你没赢，其获得你装备区里的武器牌',
  ['#os__jianwei-ask'] = '剑威：你可与 %src 拼点：若其没赢，你获得其装备区里的武器牌；若其赢，其获得你每个区域各一张牌',
  [':os__jianwei'] = '若你装备区里有武器牌，你的【杀】无视防具，你拼点的点数+X（X为你的攻击范围），其他角色的准备阶段开始时，其可与你拼点；你的准备阶段开始时，你可与攻击范围内的一名角色拼点：若你赢，你获得其每个区域各一张牌；若你没赢，其获得你装备区里的武器牌。',
  ['$os__jianwei1'] = '小小匹夫，可否闻长坂剑神之名号？',
  ['$os__jianwei2'] = '此剑吹毛得过，削铁如泥。',
}

-- 触发技效果
os__jianwei:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__jianwei) or not player:getEquipment(Card.SubtypeWeapon) then return false end
    return target == player and player.room.data.card.trueName == "slash"
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified)
    data.extra_data = data.extra_data or {}
    data.extra_data.os__jianweiNullified = data.extra_data.os__jianweiNullified or {}
    data.extra_data.os__jianweiNullified[tostring(data.to)] = (data.extra_data.os__jianweiNullified[tostring(data.to)] or 0) + 1
  end,
})

os__jianwei:addEffect(fk.PindianCardsDisplayed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__jianwei) or not player:getEquipment(Card.SubtypeWeapon) then return false end
    local data = player.room.data
    return (data.from == player or table.contains(data.tos, player)) and player:getAttackRange() > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player)
    local room = player.room
    local data = player.room.data
    room:changePindianNumber(data, player, player:getAttackRange(), os__jianwei.name)
  end,
})

-- 刷新效果
os__jianwei:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return data.extra_data and data.extra_data.os__jianweiNullified
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for key, num in pairs(data.extra_data.os__jianweiNullified) do
      local p = room:getPlayerById(tonumber(key))
      if p:getMark(fk.MarkArmorNullified) > 0 then
        room:removePlayerMark(p, fk.MarkArmorNullified, num)
      end
    end
    data.os__jianweiNullified = nil
  end,
})

-- 拼点技能效果
os__jianwei:addEffect(fk.EventPhaseStart, {
  name = "#os__jianwei_pd",
  mute = true,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player)
    if not player:hasSkill(os__jianwei) or target.phase ~= Player.Start or target:isKongcheng() or not player:getEquipment(Card.SubtypeWeapon) then return false end
    if target == player then
      return table.find(player.room.alive_players, function(p)
        return player:canPindian(p) and player:inMyAttackRange(p)
      end)
    else
      return not player:isKongcheng()
    end
  end,
  on_cost = function(self, event, target, player)
    local room = target.room
    if target == player then
      local availableTargets = table.map(
        table.filter(room.alive_players, function(p)
          return player:canPindian(p) and player:inMyAttackRange(p)
        end),
        Util.IdMapper
      )
      if #availableTargets == 0 then return false end
      local targets = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        prompt = "#os__jianwei-target",
        skill_name = os__jianwei.name,
        cancelable = true,
      })
      if #targets > 0 then
        event:setCostData(self, targets[1])
        return true
      end
    else
      return room:askToSkillInvoke(target, {
        skill_name = os__jianwei.name,
        prompt = "#os__jianwei-ask:" .. player.id
      })
    end
  end,
  on_use = function(self, event, target, player)
    local room = target.room
    room:notifySkillInvoked(player, os__jianwei.name, "special")
    player:broadcastSkillInvoke(os__jianwei.name)
    local to, pd, pd_target
    if target == player then
      to = room:getPlayerById(event:getCostData(self))
      pd_target = to
      pd = player:pindian({pd_target}, os__jianwei.name)
    else
      to = target
      pd_target = player
      pd = target:pindian({pd_target}, os__jianwei.name)
    end
    if pd.results[pd_target.id].winner == player then
      if player.dead or to:isAllNude() then return end
      local cards = U.askforCardsChosenFromAreas(player, to, "hej", os__jianwei.name, nil, nil, false)
      if #cards > 0 then
        room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, os__jianwei.name, nil, false, player.id)
      end
    else
      if #player:getEquipments(Card.SubtypeWeapon) > 0 then
        room:obtainCard(to, player:getEquipments(Card.SubtypeWeapon), false, fk.ReasonPrey)
      end
    end
  end,
})

return os__jianwei
